#!/usr/bin/env python3
"""
Mega Man 2 — Reachability-based code/data analysis.

Traces execution flow from known entry points through the binary, following
branches, jumps, JSRs, and fall-through paths. Every byte touched by this
trace is REACHABLE CODE; everything else is DATA (or unreachable dead code).

Also compares the reachability map against what da65 classified, to find:
  1. Data misclassified as code (da65 says code, tracer says unreachable)
  2. Code misclassified as data (da65 says data, tracer says reachable) — rare
"""

import os
import re
import sys
from collections import defaultdict, deque

# ─── 6502 opcode table ───────────────────────────────────────────────────────
# (mnemonic, mode, size, is_illegal, is_branch, is_jump, terminates)
# terminates = this instruction doesn't fall through (RTS, RTI, JMP abs)

OPCODES = {}

def _op(opc, mn, mode, sz, illegal=False):
    is_branch = (mode == 'REL')
    is_jmp = (mn == 'JMP')
    is_jsr = (mn == 'JSR')
    terminates = mn in ('RTS', 'RTI') or (mn == 'JMP')
    OPCODES[opc] = {
        'mnem': mn, 'mode': mode, 'size': sz, 'illegal': illegal,
        'is_branch': is_branch, 'is_jmp': is_jmp, 'is_jsr': is_jsr,
        'terminates': terminates,
    }

# Official opcodes
_op(0x00,'BRK','IMP',1); _op(0x01,'ORA','IZX',2); _op(0x05,'ORA','ZP',2)
_op(0x06,'ASL','ZP',2);  _op(0x08,'PHP','IMP',1); _op(0x09,'ORA','IMM',2)
_op(0x0A,'ASL','ACC',1); _op(0x0D,'ORA','ABS',3); _op(0x0E,'ASL','ABS',3)
_op(0x10,'BPL','REL',2); _op(0x11,'ORA','IZY',2); _op(0x15,'ORA','ZPX',2)
_op(0x16,'ASL','ZPX',2); _op(0x18,'CLC','IMP',1); _op(0x19,'ORA','ABY',3)
_op(0x1D,'ORA','ABX',3); _op(0x1E,'ASL','ABX',3)
_op(0x20,'JSR','ABS',3); _op(0x21,'AND','IZX',2); _op(0x24,'BIT','ZP',2)
_op(0x25,'AND','ZP',2);  _op(0x26,'ROL','ZP',2);  _op(0x28,'PLP','IMP',1)
_op(0x29,'AND','IMM',2); _op(0x2A,'ROL','ACC',1); _op(0x2C,'BIT','ABS',3)
_op(0x2D,'AND','ABS',3); _op(0x2E,'ROL','ABS',3)
_op(0x30,'BMI','REL',2); _op(0x31,'AND','IZY',2); _op(0x35,'AND','ZPX',2)
_op(0x36,'ROL','ZPX',2); _op(0x38,'SEC','IMP',1); _op(0x39,'AND','ABY',3)
_op(0x3D,'AND','ABX',3); _op(0x3E,'ROL','ABX',3)
_op(0x40,'RTI','IMP',1); _op(0x41,'EOR','IZX',2); _op(0x45,'EOR','ZP',2)
_op(0x46,'LSR','ZP',2);  _op(0x48,'PHA','IMP',1); _op(0x49,'EOR','IMM',2)
_op(0x4A,'LSR','ACC',1); _op(0x4C,'JMP','ABS',3); _op(0x4D,'EOR','ABS',3)
_op(0x4E,'LSR','ABS',3)
_op(0x50,'BVC','REL',2); _op(0x51,'EOR','IZY',2); _op(0x55,'EOR','ZPX',2)
_op(0x56,'LSR','ZPX',2); _op(0x58,'CLI','IMP',1); _op(0x59,'EOR','ABY',3)
_op(0x5D,'EOR','ABX',3); _op(0x5E,'LSR','ABX',3)
_op(0x60,'RTS','IMP',1); _op(0x61,'ADC','IZX',2); _op(0x65,'ADC','ZP',2)
_op(0x66,'ROR','ZP',2);  _op(0x68,'PLA','IMP',1); _op(0x69,'ADC','IMM',2)
_op(0x6A,'ROR','ACC',1); _op(0x6C,'JMP','IND',3); _op(0x6D,'ADC','ABS',3)
_op(0x6E,'ROR','ABS',3)
_op(0x70,'BVS','REL',2); _op(0x71,'ADC','IZY',2); _op(0x75,'ADC','ZPX',2)
_op(0x76,'ROR','ZPX',2); _op(0x78,'SEI','IMP',1); _op(0x79,'ADC','ABY',3)
_op(0x7D,'ADC','ABX',3); _op(0x7E,'ROR','ABX',3)
_op(0x81,'STA','IZX',2); _op(0x84,'STY','ZP',2);  _op(0x85,'STA','ZP',2)
_op(0x86,'STX','ZP',2);  _op(0x88,'DEY','IMP',1); _op(0x8A,'TXA','IMP',1)
_op(0x8C,'STY','ABS',3); _op(0x8D,'STA','ABS',3); _op(0x8E,'STX','ABS',3)
_op(0x90,'BCC','REL',2); _op(0x91,'STA','IZY',2); _op(0x94,'STY','ZPX',2)
_op(0x95,'STA','ZPX',2); _op(0x96,'STX','ZPY',2); _op(0x98,'TYA','IMP',1)
_op(0x99,'STA','ABY',3); _op(0x9A,'TXS','IMP',1); _op(0x9D,'STA','ABX',3)
_op(0xA0,'LDY','IMM',2); _op(0xA1,'LDA','IZX',2); _op(0xA2,'LDX','IMM',2)
_op(0xA4,'LDY','ZP',2);  _op(0xA5,'LDA','ZP',2);  _op(0xA6,'LDX','ZP',2)
_op(0xA8,'TAY','IMP',1); _op(0xA9,'LDA','IMM',2); _op(0xAA,'TAX','IMP',1)
_op(0xAC,'LDY','ABS',3); _op(0xAD,'LDA','ABS',3); _op(0xAE,'LDX','ABS',3)
_op(0xB0,'BCS','REL',2); _op(0xB1,'LDA','IZY',2); _op(0xB4,'LDY','ZPX',2)
_op(0xB5,'LDA','ZPX',2); _op(0xB6,'LDX','ZPY',2); _op(0xB8,'CLV','IMP',1)
_op(0xB9,'LDA','ABY',3); _op(0xBA,'TSX','IMP',1); _op(0xBC,'LDY','ABX',3)
_op(0xBD,'LDA','ABX',3); _op(0xBE,'LDX','ABY',3)
_op(0xC0,'CPY','IMM',2); _op(0xC1,'CMP','IZX',2); _op(0xC4,'CPY','ZP',2)
_op(0xC5,'CMP','ZP',2);  _op(0xC6,'DEC','ZP',2);  _op(0xC8,'INY','IMP',1)
_op(0xC9,'CMP','IMM',2); _op(0xCA,'DEX','IMP',1); _op(0xCC,'CPY','ABS',3)
_op(0xCD,'CMP','ABS',3); _op(0xCE,'DEC','ABS',3)
_op(0xD0,'BNE','REL',2); _op(0xD1,'CMP','IZY',2); _op(0xD5,'CMP','ZPX',2)
_op(0xD6,'DEC','ZPX',2); _op(0xD8,'CLD','IMP',1); _op(0xD9,'CMP','ABY',3)
_op(0xDD,'CMP','ABX',3); _op(0xDE,'DEC','ABX',3)
_op(0xE0,'CPX','IMM',2); _op(0xE1,'SBC','IZX',2); _op(0xE4,'CPX','ZP',2)
_op(0xE5,'SBC','ZP',2);  _op(0xE6,'INC','ZP',2);  _op(0xE8,'INX','IMP',1)
_op(0xE9,'SBC','IMM',2); _op(0xEA,'NOP','IMP',1); _op(0xEC,'CPX','ABS',3)
_op(0xED,'SBC','ABS',3); _op(0xEE,'INC','ABS',3)
_op(0xF0,'BEQ','REL',2); _op(0xF1,'SBC','IZY',2); _op(0xF5,'SBC','ZPX',2)
_op(0xF6,'INC','ZPX',2); _op(0xF8,'SED','IMP',1); _op(0xF9,'SBC','ABY',3)
_op(0xFD,'SBC','ABX',3); _op(0xFE,'INC','ABX',3)


# ─── da65 .asm parser ────────────────────────────────────────────────────────

LABEL_RE = re.compile(r'^(L[0-9A-Fa-f]{4,}):')

def parse_asm_classification(asm_path, base_addr):
    """Parse .asm and classify each byte offset as 'C'ode or 'D'ata."""
    bank_size = 0x4000
    classification = bytearray(b'?' * bank_size)

    with open(asm_path, 'r') as f:
        lines = f.readlines()

    current_addr = base_addr

    for line in lines:
        stripped = line.strip()
        m = LABEL_RE.match(stripped)
        if m:
            current_addr = int(m.group(1)[1:], 16)
            stripped = stripped[m.end():].strip()

        if not stripped or stripped.startswith(';') or stripped.startswith('.segment'):
            continue
        if ':=' in stripped:
            continue

        offset = current_addr - base_addr
        if offset < 0 or offset >= bank_size:
            continue

        is_data = False
        size = 0

        if stripped.startswith('.byte'):
            is_data = True
            data = stripped[5:].strip()
            if data:
                values = data.split(',')
                for v in values:
                    v = v.strip()
                    if v.startswith('"'):
                        size += len(v.strip('"'))
                    else:
                        size += 1
        elif stripped.startswith('.word') or stripped.startswith('.addr') or stripped.startswith('.dbyt'):
            is_data = True
            data = stripped.split(None, 1)[1] if len(stripped.split(None, 1)) > 1 else ''
            size = 2 * len(data.split(','))
        elif stripped.startswith('.res'):
            is_data = True
            parts = stripped.split()
            if len(parts) >= 2:
                try:
                    size = int(parts[1].rstrip(','), 0)
                except ValueError:
                    pass
        elif stripped.startswith('.'):
            continue
        else:
            is_data = False
            parts = stripped.split(None, 1)
            mnemonic = parts[0].lower()
            operand = parts[1].strip() if len(parts) > 1 else ''
            if ';' in operand:
                operand = operand[:operand.index(';')].strip()
            if not operand or operand.lower() == 'a':
                size = 1
            elif operand.startswith('#'):
                size = 2
            elif operand.startswith('('):
                if operand.endswith(',x)') or operand.endswith('),y'):
                    size = 2
                else:
                    size = 3
            elif mnemonic in ('bcc','bcs','beq','bne','bmi','bpl','bvc','bvs'):
                size = 2
            else:
                op_clean = operand.split(',')[0].strip()
                if re.match(r'^\$[0-9A-Fa-f]{2}$', op_clean):
                    size = 2
                elif re.match(r'^a:\$[0-9A-Fa-f]{2}$', op_clean):
                    size = 3
                else:
                    size = 3

        tag = ord('D') if is_data else ord('C')
        for b in range(size):
            idx = offset + b
            if 0 <= idx < bank_size:
                classification[idx] = tag

        current_addr += size

    return classification


# ─── Reachability tracer ──────────────────────────────────────────────────────

def trace_reachability(bin_data, base_addr, extra_entries=None):
    """Trace code reachability from entry points.

    Returns a bytearray where each byte is:
      'C' = reachable code
      '.' = not reached (presumed data or dead code)
    """
    size = len(bin_data)
    reached = bytearray(b'.' * size)
    visited = set()  # visited instruction offsets
    worklist = deque()

    def addr_to_off(addr):
        off = addr - base_addr
        if 0 <= off < size:
            return off
        return None

    def enqueue(off):
        if off is not None and 0 <= off < size and off not in visited:
            worklist.append(off)

    # ─── Seed entry points ────────────────────────────────────────────

    # For the fixed bank: vectors at $FFFA-$FFFF
    if base_addr == 0xC000:
        for vec_off in (0x3FFA, 0x3FFC, 0x3FFE):
            if vec_off + 1 < size:
                addr = bin_data[vec_off] | (bin_data[vec_off + 1] << 8)
                off = addr_to_off(addr)
                if off is not None:
                    enqueue(off)

    # Scan the ENTIRE ROM (all banks) for JSR/JMP targets within this bank
    # For switchable banks: the fixed bank might call into them
    # We'll do a two-pass approach: first trace within the bank's own
    # branch/jump targets, then look for word-table patterns
    #
    # First pass: linear scan for JSR abs / JMP abs within this bank
    off = 0
    while off < size:
        byte = bin_data[off]
        if byte not in OPCODES:
            off += 1
            continue
        info = OPCODES[byte]
        inst_size = info['size']
        if off + inst_size > size:
            off += 1
            continue

        # JSR/JMP absolute to within this bank
        if info['mode'] == 'ABS' and inst_size == 3 and (info['is_jsr'] or info['is_jmp']):
            target = bin_data[off + 1] | (bin_data[off + 2] << 8)
            target_off = addr_to_off(target)
            if target_off is not None:
                enqueue(target_off)

        # Branches within this bank
        if info['is_branch']:
            rel = bin_data[off + 1]
            if rel >= 0x80:
                rel -= 0x100
            target_off = off + 2 + rel
            if 0 <= target_off < size:
                enqueue(target_off)

        off += inst_size

    # Also try to identify word tables (consecutive addresses pointing into bank)
    # Common pattern: series of 2-byte addresses all within the bank range
    for off in range(0, size - 5, 2):
        addr0 = bin_data[off] | (bin_data[off + 1] << 8)
        addr1 = bin_data[off + 2] | (bin_data[off + 3] << 8)
        addr2 = bin_data[off + 4] | (bin_data[off + 5] << 8)
        # If 3 consecutive words all point within the bank, likely a jump table
        if (base_addr <= addr0 < base_addr + size and
            base_addr <= addr1 < base_addr + size and
            base_addr <= addr2 < base_addr + size):
            for a in (addr0, addr1, addr2):
                target_off = addr_to_off(a)
                if target_off is not None:
                    enqueue(target_off)

    if extra_entries:
        for addr in extra_entries:
            off = addr_to_off(addr)
            if off is not None:
                enqueue(off)

    # ─── Trace execution ──────────────────────────────────────────────

    while worklist:
        off = worklist.popleft()
        if off in visited:
            continue
        if off < 0 or off >= size:
            continue

        byte = bin_data[off]
        if byte not in OPCODES:
            # Hit an undefined opcode — stop tracing this path
            continue

        info = OPCODES[byte]
        inst_size = info['size']
        if off + inst_size > size:
            continue

        # Mark as visited and tag bytes as code
        visited.add(off)
        for b in range(inst_size):
            if off + b < size:
                reached[off + b] = ord('C')

        # Follow branches
        if info['is_branch']:
            rel = bin_data[off + 1]
            if rel >= 0x80:
                rel -= 0x100
            target_off = off + 2 + rel
            if 0 <= target_off < size:
                enqueue(target_off)
            # Branches also fall through
            enqueue(off + inst_size)
            continue

        # Follow JMP absolute
        if info['is_jmp'] and info['mode'] == 'ABS':
            target = bin_data[off + 1] | (bin_data[off + 2] << 8)
            target_off = addr_to_off(target)
            if target_off is not None:
                enqueue(target_off)
            # JMP does not fall through
            continue

        # JMP indirect — can't statically resolve, stop this path
        if info['is_jmp'] and info['mode'] == 'IND':
            # Try to resolve if the pointer is within this bank
            ptr_addr = bin_data[off + 1] | (bin_data[off + 2] << 8)
            ptr_off = addr_to_off(ptr_addr)
            if ptr_off is not None and ptr_off + 1 < size:
                target = bin_data[ptr_off] | (bin_data[ptr_off + 1] << 8)
                target_off = addr_to_off(target)
                if target_off is not None:
                    enqueue(target_off)
            continue

        # JSR — target is traced, and execution continues after JSR
        if info['is_jsr']:
            target = bin_data[off + 1] | (bin_data[off + 2] << 8)
            target_off = addr_to_off(target)
            if target_off is not None:
                enqueue(target_off)
            enqueue(off + inst_size)
            continue

        # RTS / RTI — stop this path
        if info['terminates']:
            continue

        # BRK — technically transfers to IRQ vector, but in NES games
        # BRK in a code region usually means we're in data territory.
        # Stop tracing.
        if byte == 0x00:
            continue

        # Normal instruction — fall through
        enqueue(off + inst_size)

    return reached


# ─── Comparison and reporting ─────────────────────────────────────────────────

def find_contiguous_regions(mask, target_val, min_size=1):
    """Find contiguous runs of target_val in mask. Returns [(start, end), ...]."""
    regions = []
    start = None
    for i, b in enumerate(mask):
        if b == target_val:
            if start is None:
                start = i
        else:
            if start is not None:
                if i - start >= min_size:
                    regions.append((start, i - 1))
                start = None
    if start is not None and len(mask) - start >= min_size:
        regions.append((start, len(mask) - 1))
    return regions


def analyze_bank(bank_num, verbose=False):
    """Full analysis of one bank."""
    hex_str = f'{bank_num:02X}'
    asm_path = f'src/bank{hex_str}.asm'
    bin_path = f'build/bank{hex_str}.bin'
    base_addr = 0xC000 if bank_num == 0x0F else 0x8000

    if not os.path.exists(asm_path) or not os.path.exists(bin_path):
        return None

    with open(bin_path, 'rb') as f:
        bin_data = f.read()

    # Get da65 classification
    da65_class = parse_asm_classification(asm_path, base_addr)

    # Get reachability classification
    reach_class = trace_reachability(bin_data, base_addr)

    bank_size = len(bin_data)

    # Stats
    da65_code = sum(1 for b in da65_class if b == ord('C'))
    da65_data = sum(1 for b in da65_class if b == ord('D'))
    reach_code = sum(1 for b in reach_class if b == ord('C'))
    reach_data = bank_size - reach_code

    # Cross-reference: find disagreements
    # "da65 says code, tracer says data" = likely misclassified data
    misclassified_data = bytearray(bank_size)
    for i in range(bank_size):
        if da65_class[i] == ord('C') and reach_class[i] == ord('.'):
            misclassified_data[i] = 1

    misclass_count = sum(misclassified_data)
    misclass_regions = find_contiguous_regions(misclassified_data, 1, min_size=4)

    # "da65 says data, tracer says code" = rare, but possible
    missed_code = bytearray(bank_size)
    for i in range(bank_size):
        if da65_class[i] == ord('D') and reach_class[i] == ord('C'):
            missed_code[i] = 1
    missed_count = sum(missed_code)

    # Check for illegal opcodes in reachable code
    illegal_in_reachable = 0
    off = 0
    while off < bank_size:
        if reach_class[off] == ord('C'):
            byte = bin_data[off]
            if byte in OPCODES:
                info = OPCODES[byte]
                if info['illegal']:
                    illegal_in_reachable += 1
                off += info['size']
                continue
        off += 1

    # Find $FF-padded regions classified as code by da65
    ff_padding_as_code = 0
    for i in range(bank_size):
        if da65_class[i] == ord('C') and bin_data[i] == 0xFF:
            ff_padding_as_code += 1

    result = {
        'bank_num': bank_num,
        'da65_code': da65_code,
        'da65_data': da65_data,
        'reach_code': reach_code,
        'reach_data': reach_data,
        'misclass_count': misclass_count,
        'misclass_regions': misclass_regions,
        'missed_code': missed_count,
        'illegal_in_reachable': illegal_in_reachable,
        'ff_padding_as_code': ff_padding_as_code,
        'base_addr': base_addr,
    }

    return result


def main():
    verbose = '--verbose' in sys.argv or '-v' in sys.argv

    print("=" * 78)
    print("  Mega Man 2 — Reachability-Based Code vs Data Analysis")
    print("=" * 78)
    print()
    print(f"  {'Bank':>6s}  {'da65_code':>9s}  {'da65_data':>9s}  {'reach_code':>10s}  "
          f"{'reach_data':>10s}  {'misclass':>8s}  {'missed':>6s}  {'illegal':>7s}")
    print(f"  {'----':>6s}  {'---------':>9s}  {'---------':>9s}  {'----------':>10s}  "
          f"{'----------':>10s}  {'--------':>8s}  {'------':>6s}  {'-------':>7s}")

    total_misclass = 0
    total_missed = 0
    all_results = []

    for bank_num in range(16):
        result = analyze_bank(bank_num, verbose)
        if result is None:
            continue
        all_results.append(result)

        r = result
        total_misclass += r['misclass_count']
        total_missed += r['missed_code']

        flag = ""
        if r['misclass_count'] > 1000:
            flag = " <<<< HEAVY"
        elif r['misclass_count'] > 500:
            flag = " << MODERATE"

        print(f"  ${r['bank_num']:02X}     {r['da65_code']:9d}  {r['da65_data']:9d}  "
              f"{r['reach_code']:10d}  {r['reach_data']:10d}  "
              f"{r['misclass_count']:8d}  {r['missed_code']:6d}  "
              f"{r['illegal_in_reachable']:7d}{flag}")

    print()
    print(f"  Total bytes da65 calls code but tracer says unreachable: {total_misclass}")
    print(f"  Total bytes da65 calls data but tracer says reachable:   {total_missed}")
    print()

    # Detailed misclassification regions
    print("=" * 78)
    print("  Suspect data-as-code regions (contiguous, >= 4 bytes)")
    print("=" * 78)

    for r in all_results:
        if not r['misclass_regions']:
            continue
        bank_num = r['bank_num']
        base = r['base_addr']
        hex_str = f'{bank_num:02X}'

        # Group into large and small regions
        large = [(s, e) for s, e in r['misclass_regions'] if e - s + 1 >= 32]
        small = [(s, e) for s, e in r['misclass_regions'] if 4 <= e - s + 1 < 32]

        if large:
            print(f"\n  Bank ${hex_str} — LARGE suspect regions (>= 32 bytes):")
            for s, e in large:
                size = e - s + 1
                addr_s = base + s
                addr_e = base + e
                print(f"    ${addr_s:04X}-${addr_e:04X}  ({size:5d} bytes)")

        if small and verbose:
            print(f"\n  Bank ${hex_str} — small suspect regions (4-31 bytes):")
            for s, e in small[:20]:  # limit output
                size = e - s + 1
                addr_s = base + s
                addr_e = base + e
                print(f"    ${addr_s:04X}-${addr_e:04X}  ({size:5d} bytes)")
            if len(small) > 20:
                print(f"    ... and {len(small) - 20} more")

    # Summary
    print()
    print("=" * 78)
    print("  RECOMMENDATION")
    print("=" * 78)
    print()
    if total_misclass > 0:
        pct = total_misclass / (16 * 0x4000) * 100
        print(f"  {total_misclass} bytes ({pct:.1f}% of ROM) are classified as code by da65")
        print(f"  but not reachable by the instruction tracer.")
        print(f"  These are very likely data tables (level data, CHR tiles, music,")
        print(f"  sprite data, etc.) that should be marked as ByteTable in the")
        print(f"  da65 info files and re-disassembled.")
    if total_missed > 0:
        print(f"\n  {total_missed} bytes are marked as data by da65 but appear reachable.")
        print(f"  This may indicate jump tables or self-modifying code patterns")
        print(f"  that the tracer partially resolved.")
    print()


if __name__ == '__main__':
    main()
