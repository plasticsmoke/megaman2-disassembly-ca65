#!/usr/bin/env python3
"""Fix branch-to-literal-address instructions in da65 output.

da65 sometimes interprets data as branch instructions targeting absolute addresses
without labels. ca65 can't assemble these because the segment PC is relocatable
but the target is absolute. This script replaces such instructions with raw .byte data
read from the original binary.
"""

import re
import os
import sys

# 6502 branch mnemonics and their opcodes
BRANCH_OPS = {
    'bcc': 0x90, 'bcs': 0xB0, 'beq': 0xF0, 'bne': 0xD0,
    'bmi': 0x30, 'bpl': 0x10, 'bvc': 0x50, 'bvs': 0x70,
}

# Pattern: branch to bare hex address (not a label)
# Matches: "bcc $8EB9" but NOT "bcc L8EB9" or "bcc label"
BRANCH_LITERAL_RE = re.compile(
    r'^(\s*)(\w+:\s+)?(bcc|bcs|beq|bne|bmi|bpl|bvc|bvs)\s+\$([0-9A-Fa-f]{4})\s*$'
)

# Pattern: label at start of line
LABEL_RE = re.compile(r'^(L[0-9A-Fa-f]{4,}):')

# Instruction size determination from da65 output syntax
def instruction_size(line):
    """Determine the byte size of an instruction/directive from its assembly text."""
    stripped = line.strip()

    # Remove label prefix if present
    m = re.match(r'^L[0-9A-Fa-f]+:\s*(.*)', stripped)
    if m:
        stripped = m.group(1).strip()

    if not stripped or stripped.startswith(';'):
        return 0

    # Segment directive
    if stripped.startswith('.segment'):
        return 0

    # .byte directive: count comma-separated values
    if stripped.startswith('.byte'):
        data = stripped[5:].strip()
        if not data:
            return 0
        # Split by comma, but handle quoted strings
        values = data.split(',')
        total = 0
        for v in values:
            v = v.strip()
            if v.startswith('"'):
                # String literal: each char is 1 byte
                total += len(v.strip('"'))
            else:
                total += 1
        return total

    # .word / .addr directive: 2 bytes per value
    if stripped.startswith('.word') or stripped.startswith('.addr') or stripped.startswith('.dbyt'):
        data = stripped.split(None, 1)[1] if len(stripped.split(None, 1)) > 1 else ''
        return 2 * len(data.split(','))

    # .res directive
    if stripped.startswith('.res'):
        parts = stripped.split()
        if len(parts) >= 2:
            try:
                return int(parts[1].rstrip(','), 0)
            except ValueError:
                pass
        return 0

    # Must be a CPU instruction — determine addressing mode from syntax
    parts = stripped.split(None, 1)
    mnemonic = parts[0].lower()
    operand = parts[1].strip() if len(parts) > 1 else ''

    # Remove trailing comment
    if ';' in operand:
        operand = operand[:operand.index(';')].strip()

    if not operand:
        # Implied or accumulator
        if mnemonic in ('asl', 'lsr', 'rol', 'ror') and not operand:
            return 1  # Accumulator mode
        return 1  # Implied

    if operand.lower() == 'a':
        return 1  # Accumulator

    # Immediate: #$XX or #<expr or #>expr
    if operand.startswith('#'):
        return 2

    # Indirect: ($XXXX) or ($XX,x) or ($XX),y
    if operand.startswith('('):
        if operand.endswith(',x)'):
            return 2  # (zp,X)
        elif operand.endswith('),y'):
            return 2  # (zp),Y
        else:
            return 3  # (abs) — JMP indirect

    # Branch instructions are always 2 bytes
    if mnemonic in BRANCH_OPS:
        return 2

    # Check for zero page vs absolute
    # Zero page: $XX (2 hex digits)
    # Absolute: $XXXX (4 hex digits)
    zp_match = re.match(r'^\$[0-9A-Fa-f]{2}(?:,[xy])?$', operand)
    if zp_match:
        return 2  # Zero page (with optional ,x or ,y)

    # Check for label references (LXXXX or code_XXXX) — could be 2 or 3 bytes
    # For absolute addressing: 3 bytes
    abs_match = re.match(r'^\$[0-9A-Fa-f]{4}(?:,[xy])?$', operand)
    if abs_match:
        return 3  # Absolute (with optional ,x or ,y)

    # Label reference (could be zero page or absolute)
    label_match = re.match(r'^(L[0-9A-Fa-f]+)(?:,[xy])?$', operand)
    if label_match:
        addr_str = label_match.group(1)[1:]  # Remove 'L' prefix
        addr = int(addr_str, 16)
        if addr < 0x100:
            return 2  # Zero page
        return 3  # Absolute

    # Default: assume 3 bytes for absolute addressing
    return 3


def fix_bank(asm_path, bin_path, base_addr):
    """Fix branch-to-literal instructions in a single bank .asm file."""
    with open(bin_path, 'rb') as f:
        bin_data = f.read()

    with open(asm_path, 'r') as f:
        lines = f.readlines()

    current_addr = base_addr
    fixed_count = 0
    output_lines = []

    for i, line in enumerate(lines):
        # Check for label to sync address
        label_match = LABEL_RE.match(line)
        if label_match:
            label_addr = int(label_match.group(1)[1:], 16)
            current_addr = label_addr

        # Check for branch to literal address
        branch_match = BRANCH_LITERAL_RE.match(line)
        if branch_match:
            indent = branch_match.group(1)
            label_prefix = branch_match.group(2) or ''
            mnemonic = branch_match.group(3)
            target_str = branch_match.group(4)

            # Read the 2 bytes from the binary
            bin_offset = current_addr - base_addr
            if 0 <= bin_offset < len(bin_data) - 1:
                opcode_byte = bin_data[bin_offset]
                operand_byte = bin_data[bin_offset + 1]

                # Verify the opcode matches the branch mnemonic
                expected_opcode = BRANCH_OPS[mnemonic]
                if opcode_byte == expected_opcode:
                    output_lines.append(
                        f'{indent}{label_prefix}.byte   ${opcode_byte:02X},${operand_byte:02X}\n'
                    )
                    fixed_count += 1
                    current_addr += 2
                    continue
                else:
                    # Opcode mismatch — emit anyway using computed offset
                    target_addr = int(target_str, 16)
                    offset = (target_addr - (current_addr + 2)) & 0xFF
                    output_lines.append(
                        f'{indent}{label_prefix}.byte   ${expected_opcode:02X},${offset:02X}\n'
                    )
                    fixed_count += 1
                    current_addr += 2
                    continue

        output_lines.append(line)

        # Track address advancement
        size = instruction_size(line)
        current_addr += size

    if fixed_count > 0:
        with open(asm_path, 'w') as f:
            f.writelines(output_lines)
        print(f"  Fixed {fixed_count} branch-to-literal instructions in {asm_path}")

    return fixed_count


def main():
    banks = list(range(16))
    total_fixed = 0

    for bank_num in banks:
        hex_str = f'{bank_num:02X}'
        asm_path = f'src/bank{hex_str}.asm'
        bin_path = f'build/bank{hex_str}.bin'
        base_addr = 0xC000 if bank_num == 0x0F else 0x8000

        if not os.path.exists(asm_path) or not os.path.exists(bin_path):
            continue

        fixed = fix_bank(asm_path, bin_path, base_addr)
        total_fixed += fixed

    print(f"\nTotal fixed: {total_fixed} instructions across all banks")


if __name__ == '__main__':
    main()
