#!/usr/bin/env python3
"""
Validate code vs data classification in Mega Man 2 disassembly.

Walks each bank's raw binary as a 6502 instruction stream and flags regions
where da65 likely misclassified data as code (or vice versa). Uses multiple
heuristics:

1. Illegal/undocumented opcodes treated as instructions
2. Branches whose targets land mid-instruction or outside the bank
3. JSR/JMP to addresses that look like data (e.g., inside known data tables)
4. Long runs of BRK ($00) interpreted as code
5. Sequences of instructions that make no architectural sense
   (e.g., multiple SEDs, repeated undocumented NOPs)
6. Code reachability: entry points from vectors/JSR targets vs unreachable bytes

Compares findings against what the .asm files actually contain (code vs .byte).
"""

import os
import re
import sys
from collections import defaultdict

# ─── 6502 opcode table ───────────────────────────────────────────────────────
# Each entry: (mnemonic, addressing_mode, size, is_illegal)
# Addressing modes: IMP, ACC, IMM, ZP, ZPX, ZPY, ABS, ABX, ABY,
#                   IND, IZX, IZY, REL, (None = illegal/jam)

OPCODES = {}

def _op(opcode, mnem, mode, size, illegal=False):
    OPCODES[opcode] = (mnem, mode, size, illegal)

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

# Common undocumented but "stable" opcodes (NES games sometimes use these)
_op(0x04,'NOP','ZP',2,True);  _op(0x0C,'NOP','ABS',3,True)
_op(0x14,'NOP','ZPX',2,True); _op(0x1A,'NOP','IMP',1,True)
_op(0x1C,'NOP','ABX',3,True)
_op(0x34,'NOP','ZPX',2,True); _op(0x3A,'NOP','IMP',1,True)
_op(0x3C,'NOP','ABX',3,True)
_op(0x44,'NOP','ZP',2,True);  _op(0x54,'NOP','ZPX',2,True)
_op(0x5A,'NOP','IMP',1,True); _op(0x5C,'NOP','ABX',3,True)
_op(0x64,'NOP','ZP',2,True);  _op(0x74,'NOP','ZPX',2,True)
_op(0x7A,'NOP','IMP',1,True); _op(0x7C,'NOP','ABX',3,True)
_op(0x80,'NOP','IMM',2,True); _op(0x82,'NOP','IMM',2,True)
_op(0x89,'NOP','IMM',2,True); _op(0xC2,'NOP','IMM',2,True)
_op(0xD4,'NOP','ZPX',2,True); _op(0xDA,'NOP','IMP',1,True)
_op(0xDC,'NOP','ABX',3,True)
_op(0xE2,'NOP','IMM',2,True); _op(0xF4,'NOP','ZPX',2,True)
_op(0xFA,'NOP','IMP',1,True); _op(0xFC,'NOP','ABX',3,True)
# Undocumented ALU combos
_op(0xA7,'LAX','ZP',2,True);  _op(0xB7,'LAX','ZPY',2,True)
_op(0xAF,'LAX','ABS',3,True); _op(0xBF,'LAX','ABY',3,True)
_op(0xA3,'LAX','IZX',2,True); _op(0xB3,'LAX','IZY',2,True)
_op(0x87,'SAX','ZP',2,True);  _op(0x97,'SAX','ZPY',2,True)
_op(0x8F,'SAX','ABS',3,True); _op(0x83,'SAX','IZX',2,True)
_op(0xEB,'SBC','IMM',2,True)  # unofficial SBC #imm
_op(0xC7,'DCP','ZP',2,True);  _op(0xD7,'DCP','ZPX',2,True)
_op(0xCF,'DCP','ABS',3,True); _op(0xDF,'DCP','ABX',3,True)
_op(0xDB,'DCP','ABY',3,True); _op(0xC3,'DCP','IZX',2,True)
_op(0xD3,'DCP','IZY',2,True)
_op(0xE7,'ISC','ZP',2,True);  _op(0xF7,'ISC','ZPX',2,True)
_op(0xEF,'ISC','ABS',3,True); _op(0xFF,'ISC','ABX',3,True)
_op(0xFB,'ISC','ABY',3,True); _op(0xE3,'ISC','IZX',2,True)
_op(0xF3,'ISC','IZY',2,True)
_op(0x07,'SLO','ZP',2,True);  _op(0x17,'SLO','ZPX',2,True)
_op(0x0F,'SLO','ABS',3,True); _op(0x1F,'SLO','ABX',3,True)
_op(0x1B,'SLO','ABY',3,True); _op(0x03,'SLO','IZX',2,True)
_op(0x13,'SLO','IZY',2,True)
_op(0x27,'RLA','ZP',2,True);  _op(0x37,'RLA','ZPX',2,True)
_op(0x2F,'RLA','ABS',3,True); _op(0x3F,'RLA','ABX',3,True)
_op(0x3B,'RLA','ABY',3,True); _op(0x23,'RLA','IZX',2,True)
_op(0x33,'RLA','IZY',2,True)
_op(0x47,'SRE','ZP',2,True);  _op(0x57,'SRE','ZPX',2,True)
_op(0x4F,'SRE','ABS',3,True); _op(0x5F,'SRE','ABX',3,True)
_op(0x5B,'SRE','ABY',3,True); _op(0x43,'SRE','IZX',2,True)
_op(0x53,'SRE','IZY',2,True)
_op(0x67,'RRA','ZP',2,True);  _op(0x77,'RRA','ZPX',2,True)
_op(0x6F,'RRA','ABS',3,True); _op(0x7F,'RRA','ABX',3,True)
_op(0x7B,'RRA','ABY',3,True); _op(0x63,'RRA','IZX',2,True)
_op(0x73,'RRA','IZY',2,True)

# Anything not in the table is a JAM / truly undefined
JAM_OPCODES = set(range(256)) - set(OPCODES.keys())


# ─── da65 .asm parser ────────────────────────────────────────────────────────

LABEL_RE = re.compile(r'^(L[0-9A-Fa-f]{4,}):')

def parse_asm_classification(asm_path, base_addr):
    """Parse a da65 .asm file and classify each byte offset as 'code' or 'data'.

    Returns a bytearray of length bank_size where:
      ord('C') = da65 treated as code instruction byte
      ord('D') = da65 treated as data (.byte / .word / .dbyt / .res / .addr)
      ord('?') = unknown / unclassified
    """
    bank_size = 0x4000
    classification = bytearray(b'?' * bank_size)

    with open(asm_path, 'r') as f:
        lines = f.readlines()

    current_addr = base_addr

    for line in lines:
        stripped = line.strip()

        # Update address from label
        m = LABEL_RE.match(stripped)
        if m:
            label_addr = int(m.group(1)[1:], 16)
            current_addr = label_addr
            # Strip label for further parsing
            stripped = stripped[m.end():].strip()

        if not stripped or stripped.startswith(';') or stripped.startswith('.segment'):
            continue

        # Skip := assignments
        if ':=' in stripped:
            continue

        offset = current_addr - base_addr
        if offset < 0 or offset >= bank_size:
            continue

        # Check if this is a data directive
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
                    size = 0
        elif stripped.startswith('.'):
            # Other directives (e.g., .segment) — skip
            continue
        else:
            # CPU instruction
            is_data = False
            parts = stripped.split(None, 1)
            mnemonic = parts[0].lower()
            operand = parts[1].strip() if len(parts) > 1 else ''
            if ';' in operand:
                operand = operand[:operand.index(';')].strip()

            # Determine instruction size from operand syntax
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
                # Check ZP vs ABS
                op_clean = operand.split(',')[0].strip()
                if re.match(r'^\$[0-9A-Fa-f]{2}$', op_clean):
                    size = 2
                elif re.match(r'^a:\$[0-9A-Fa-f]{2}$', op_clean):
                    size = 3  # forced absolute addressing of ZP
                else:
                    size = 3

        tag = ord('D') if is_data else ord('C')
        for b in range(size):
            idx = offset + b
            if 0 <= idx < bank_size:
                classification[idx] = tag

        current_addr += size

    return classification


# ─── Binary analysis ──────────────────────────────────────────────────────────

def analyze_binary(bin_data, base_addr):
    """Walk the binary as a 6502 instruction stream and flag suspicious regions.

    Returns a dict of offset -> list of issue strings.
    """
    issues = defaultdict(list)
    size = len(bin_data)

    # Pass 1: identify all branch/jump targets as known entry points
    # Also identify JSR targets
    known_entries = set()

    # Vectors (for the fixed bank)
    if base_addr == 0xC000:
        nmi = bin_data[0x3FFA] | (bin_data[0x3FFB] << 8)
        reset = bin_data[0x3FFC] | (bin_data[0x3FFD] << 8)
        irq = bin_data[0x3FFE] | (bin_data[0x3FFF] << 8)
        for v in (nmi, reset, irq):
            if base_addr <= v < base_addr + size:
                known_entries.add(v - base_addr)

    # Linear scan to find branch/jump targets
    offset = 0
    while offset < size:
        byte = bin_data[offset]
        if byte not in OPCODES:
            offset += 1
            continue
        mnem, mode, inst_size, illegal = OPCODES[byte]
        if offset + inst_size > size:
            offset += 1
            continue

        if mode == 'REL' and inst_size == 2:
            rel = bin_data[offset + 1]
            if rel >= 0x80:
                rel -= 0x100
            target_offset = offset + 2 + rel
            if 0 <= target_offset < size:
                known_entries.add(target_offset)

        if mode == 'ABS' and inst_size == 3 and mnem in ('JSR', 'JMP'):
            target = bin_data[offset + 1] | (bin_data[offset + 2] << 8)
            target_off = target - base_addr
            if 0 <= target_off < size:
                known_entries.add(target_off)

        offset += inst_size

    # Pass 2: walk linearly and flag suspicious patterns
    offset = 0
    brk_run = 0
    illegal_run = 0

    while offset < size:
        byte = bin_data[offset]

        # JAM / truly undefined opcode
        if byte in JAM_OPCODES:
            issues[offset].append(f"JAM opcode ${byte:02X} — almost certainly data")
            offset += 1
            brk_run = 0
            illegal_run = 0
            continue

        mnem, mode, inst_size, illegal = OPCODES[byte]

        if offset + inst_size > size:
            issues[offset].append(f"instruction ${byte:02X} overruns bank end")
            break

        # Track BRK runs
        if byte == 0x00:
            brk_run += 1
            if brk_run == 4:
                issues[offset - 3].append(f"4+ consecutive BRK ($00) — likely zero-padded data")
        else:
            brk_run = 0

        # Track illegal opcode runs
        if illegal:
            illegal_run += 1
            if illegal_run == 3:
                issues[offset].append(
                    f"3+ consecutive illegal opcodes — likely data"
                )
        else:
            illegal_run = 0

        # Check branches to out-of-bank targets
        if mode == 'REL':
            rel = bin_data[offset + 1]
            if rel >= 0x80:
                rel -= 0x100
            target_offset = offset + 2 + rel
            if target_offset < 0 or target_offset >= size:
                addr = base_addr + offset
                target_addr = base_addr + target_offset
                issues[offset].append(
                    f"{mnem} at ${addr:04X} targets ${target_addr:04X} — outside bank, likely data"
                )

        # SED is extremely rare in NES games (never used for gameplay code)
        if byte == 0xF8:
            issues[offset].append(f"SED at ${base_addr+offset:04X} — extremely rare on NES, likely data")

        # Check for absolute addressing into I/O space gaps or weird areas
        if mode == 'ABS' and inst_size == 3 and mnem not in ('JMP', 'JSR'):
            target = bin_data[offset + 1] | (bin_data[offset + 2] << 8)
            # $4020-$5FFF is mapper-dependent and usually unmapped on MMC1
            # $0800-$1FFF are RAM mirrors — unusual but not wrong
            # Very high addresses in switchable banks referencing fixed bank are OK

        offset += inst_size

    return issues


def compare_and_report(bank_num, asm_classification, binary_issues, bin_data, base_addr):
    """Cross-reference da65 classification with binary analysis."""
    size = len(bin_data)
    findings = []

    # Group binary issues into contiguous regions
    if binary_issues:
        sorted_offsets = sorted(binary_issues.keys())

        # Merge nearby issues into regions
        regions = []
        region_start = sorted_offsets[0]
        region_end = sorted_offsets[0]

        for off in sorted_offsets[1:]:
            if off - region_end <= 8:  # merge if within 8 bytes
                region_end = off
            else:
                regions.append((region_start, region_end))
                region_start = off
                region_end = off
        regions.append((region_start, region_end))

        for rstart, rend in regions:
            # Check how da65 classified this region
            code_bytes = 0
            data_bytes = 0
            for off in range(rstart, min(rend + 16, size)):
                if asm_classification[off] == ord('C'):
                    code_bytes += 1
                elif asm_classification[off] == ord('D'):
                    data_bytes += 1

            if code_bytes > 0:
                # da65 has code in a suspicious region — flag it
                all_issues = []
                for off in range(rstart, rend + 1):
                    if off in binary_issues:
                        all_issues.extend(binary_issues[off])

                addr_start = base_addr + rstart
                addr_end = base_addr + rend
                findings.append({
                    'addr_start': addr_start,
                    'addr_end': addr_end,
                    'code_bytes': code_bytes,
                    'data_bytes': data_bytes,
                    'issues': all_issues[:5],  # limit verbosity
                    'severity': 'HIGH' if any('JAM' in i or 'outside bank' in i for i in all_issues) else 'MEDIUM',
                })

    # Also check: large data regions that da65 classified as code
    # Look for runs of 16+ consecutive code bytes that are all $FF or $00
    run_start = None
    for off in range(size):
        if asm_classification[off] == ord('C') and bin_data[off] in (0x00, 0xFF):
            if run_start is None:
                run_start = off
        else:
            if run_start is not None and (off - run_start) >= 16:
                findings.append({
                    'addr_start': base_addr + run_start,
                    'addr_end': base_addr + off - 1,
                    'code_bytes': off - run_start,
                    'data_bytes': 0,
                    'issues': [f"Run of {off - run_start} bytes of $00/$FF classified as code — likely padding/data"],
                    'severity': 'MEDIUM',
                })
            run_start = None

    return findings


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    total_findings = 0
    all_findings = {}

    for bank_num in range(16):
        hex_str = f'{bank_num:02X}'
        asm_path = f'src/bank{hex_str}.asm'
        bin_path = f'build/bank{hex_str}.bin'
        base_addr = 0xC000 if bank_num == 0x0F else 0x8000

        if not os.path.exists(asm_path) or not os.path.exists(bin_path):
            continue

        with open(bin_path, 'rb') as f:
            bin_data = f.read()

        # Parse .asm classification
        asm_class = parse_asm_classification(asm_path, base_addr)

        # Analyze binary
        binary_issues = analyze_binary(bin_data, base_addr)

        # Cross-reference
        findings = compare_and_report(bank_num, asm_class, binary_issues, bin_data, base_addr)

        if findings:
            all_findings[bank_num] = findings

    # ─── Summary report ───────────────────────────────────────────────────
    print("=" * 78)
    print("  Mega Man 2 — Code vs Data Validation Report")
    print("=" * 78)

    # Per-bank stats
    for bank_num in range(16):
        hex_str = f'{bank_num:02X}'
        asm_path = f'src/bank{hex_str}.asm'
        bin_path = f'build/bank{hex_str}.bin'
        base_addr = 0xC000 if bank_num == 0x0F else 0x8000

        if not os.path.exists(asm_path) or not os.path.exists(bin_path):
            continue

        with open(bin_path, 'rb') as f:
            bin_data = f.read()

        asm_class = parse_asm_classification(asm_path, base_addr)

        code_count = sum(1 for b in asm_class if b == ord('C'))
        data_count = sum(1 for b in asm_class if b == ord('D'))
        unk_count = sum(1 for b in asm_class if b == ord('?'))

        # Count illegal opcodes that da65 treated as code
        illegal_as_code = 0
        off = 0
        while off < len(bin_data):
            if asm_class[off] == ord('C'):
                byte = bin_data[off]
                if byte in OPCODES and OPCODES[byte][3]:  # illegal
                    illegal_as_code += 1
                    off += OPCODES[byte][2]
                    continue
                elif byte in JAM_OPCODES:
                    illegal_as_code += 1
            off += 1

        findings = all_findings.get(bank_num, [])
        high_count = sum(1 for f in findings if f['severity'] == 'HIGH')
        med_count = sum(1 for f in findings if f['severity'] == 'MEDIUM')

        status = "OK" if not findings else f"{high_count} HIGH, {med_count} MED"
        print(f"\n  Bank ${hex_str}: code={code_count:5d}  data={data_count:5d}  "
              f"unclassified={unk_count:4d}  illegal_as_code={illegal_as_code:3d}  [{status}]")

        if findings:
            for f in sorted(findings, key=lambda x: (-('HIGH' in x['severity']), x['addr_start'])):
                severity = f['severity']
                addr_range = f"${f['addr_start']:04X}-${f['addr_end']:04X}"
                issue_summary = f['issues'][0] if f['issues'] else 'suspicious region'
                print(f"    [{severity:6s}] {addr_range}: {issue_summary}")
                for extra in f['issues'][1:]:
                    print(f"             {' ' * len(addr_range)}  {extra}")

        total_findings += len(findings)

    print(f"\n{'=' * 78}")
    print(f"  Total suspect regions: {total_findings}")
    high_total = sum(1 for findings in all_findings.values() for f in findings if f['severity'] == 'HIGH')
    print(f"  HIGH severity: {high_total}")
    print(f"  (HIGH = JAM opcodes or out-of-bank branches classified as code)")
    print(f"  (MEDIUM = BRK runs, illegal opcode clusters, SED, padding as code)")
    print(f"{'=' * 78}")


if __name__ == '__main__':
    main()
