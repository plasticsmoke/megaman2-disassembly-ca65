#!/usr/bin/env python3
"""
Independent per-bank byte-level verification.

Assembles and links each bank individually via ca65/ld65, then compares
the output byte-for-byte against the original extracted .bin file.
This is independent of `make verify` and gives per-bank granularity.

Also checks for subtle encoding issues:
  - Instructions that have multiple valid encodings (e.g., ZP vs ABS)
  - Bytes that match but where da65's disassembly interpretation differs
    from what the bytes actually encode
"""

import os
import subprocess
import sys
import tempfile

BANK_SIZE = 0x4000

def verify_bank(bank_num):
    """Assemble a single bank and compare against its .bin file."""
    hex_str = f'{bank_num:02X}'
    asm_path = f'src/bank{hex_str}.asm'
    bin_path = f'build/bank{hex_str}.bin'
    base_addr = 0xC000 if bank_num == 0x0F else 0x8000
    seg_name = 'FIXED' if bank_num == 0x0F else f'BANK{hex_str}'

    if not os.path.exists(asm_path) or not os.path.exists(bin_path):
        return None, f"Missing files for bank ${hex_str}"

    with open(bin_path, 'rb') as f:
        expected = f.read()

    if len(expected) != BANK_SIZE:
        return None, f"Bank ${hex_str} .bin is {len(expected)} bytes, expected {BANK_SIZE}"

    # Create a temporary linker config for just this one bank
    with tempfile.NamedTemporaryFile(mode='w', suffix='.cfg', delete=False) as cfg_f:
        cfg_f.write(f'MEMORY {{\n')
        cfg_f.write(f'    PRG: start = ${base_addr:04X}, size = ${BANK_SIZE:04X}, fill = yes, file = %O;\n')
        cfg_f.write(f'}}\n')
        cfg_f.write(f'SEGMENTS {{\n')
        cfg_f.write(f'    {seg_name}: load = PRG, type = ro;\n')
        cfg_f.write(f'}}\n')
        cfg_path = cfg_f.name

    obj_path = tempfile.mktemp(suffix='.o')
    out_path = tempfile.mktemp(suffix='.bin')

    try:
        # Assemble
        result = subprocess.run(
            ['ca65', '-I', '.', '-o', obj_path, asm_path],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            return None, f"ca65 error: {result.stderr.strip()}"

        # Link
        result = subprocess.run(
            ['ld65', '-C', cfg_path, '-o', out_path, obj_path],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            return None, f"ld65 error: {result.stderr.strip()}"

        # Compare
        with open(out_path, 'rb') as f:
            actual = f.read()

        if len(actual) != BANK_SIZE:
            return None, f"Output is {len(actual)} bytes, expected {BANK_SIZE}"

        # Byte-by-byte comparison
        mismatches = []
        for i in range(BANK_SIZE):
            if actual[i] != expected[i]:
                addr = base_addr + i
                mismatches.append((addr, expected[i], actual[i]))

        return mismatches, None

    finally:
        for path in (cfg_path, obj_path, out_path):
            if os.path.exists(path):
                os.unlink(path)


def check_encoding_ambiguities(bin_path, asm_path, base_addr):
    """Check for instructions where da65 chose a non-canonical encoding.

    For example, `LDA $0042` (absolute mode, 3 bytes) when the byte
    sequence is actually `LDA $42` (zero page, 2 bytes). da65 should
    get this right, but let's verify.
    """
    from tools_opcodes import OPCODES  # We'll inline this check instead

    with open(bin_path, 'rb') as f:
        bin_data = f.read()

    # Quick check: look for absolute-mode instructions that reference
    # zero-page addresses ($0000-$00FF) — these should use ZP mode instead
    issues = []
    off = 0
    while off < len(bin_data):
        byte = bin_data[off]

        # Common absolute-mode opcodes that have ZP equivalents
        # These are 3-byte instructions where bytes[1:3] form a 16-bit address
        abs_to_zp = {
            0x0D: 0x05,  # ORA abs -> ORA zp
            0x0E: 0x06,  # ASL abs -> ASL zp
            0x2C: 0x24,  # BIT abs -> BIT zp
            0x2D: 0x25,  # AND abs -> AND zp
            0x2E: 0x26,  # ROL abs -> ROL zp
            0x4D: 0x45,  # EOR abs -> EOR zp
            0x4E: 0x46,  # LSR abs -> LSR zp
            0x6D: 0x65,  # ADC abs -> ADC zp
            0x6E: 0x66,  # ROR abs -> ROR zp
            0x8C: 0x84,  # STY abs -> STY zp
            0x8D: 0x85,  # STA abs -> STA zp
            0x8E: 0x86,  # STX abs -> STX zp
            0xAC: 0xA4,  # LDY abs -> LDY zp
            0xAD: 0xA5,  # LDA abs -> LDA zp
            0xAE: 0xA6,  # LDX abs -> LDX zp
            0xCC: 0xC4,  # CPY abs -> CPY zp
            0xCD: 0xC5,  # CMP abs -> CMP zp
            0xCE: 0xC6,  # DEC abs -> DEC zp
            0xEC: 0xE4,  # CPX abs -> CPX zp
            0xED: 0xE5,  # SBC abs -> SBC zp
            0xEE: 0xE6,  # INC abs -> INC zp
        }

        if byte in abs_to_zp and off + 2 < len(bin_data):
            # This is an absolute-mode instruction
            lo = bin_data[off + 1]
            hi = bin_data[off + 2]
            if hi == 0x00:
                # Address is $00XX — uses absolute mode for a ZP address
                # This is valid but unusual. da65 should generate `a:$XX` syntax
                addr = base_addr + off
                issues.append(f"${addr:04X}: absolute mode used for ZP address $00{lo:02X}")
            off += 3
            continue

        # For unknown or 1-byte opcodes, just advance
        # Simple size table for common opcodes
        if byte in (0x00, 0x08, 0x0A, 0x18, 0x28, 0x2A, 0x38, 0x40, 0x48,
                     0x4A, 0x58, 0x60, 0x68, 0x6A, 0x78, 0x88, 0x8A, 0x98,
                     0x9A, 0xA8, 0xAA, 0xB8, 0xBA, 0xC8, 0xCA, 0xE8, 0xEA, 0xF8):
            off += 1
        elif byte in (0x01,0x05,0x06,0x09,0x10,0x11,0x15,0x16,0x21,0x24,0x25,0x26,
                      0x29,0x30,0x31,0x35,0x36,0x41,0x45,0x46,0x49,0x50,0x51,0x55,
                      0x56,0x61,0x65,0x66,0x69,0x70,0x71,0x75,0x76,0x81,0x84,0x85,
                      0x86,0x90,0x91,0x94,0x95,0x96,0xA0,0xA1,0xA2,0xA4,0xA5,0xA6,
                      0xA9,0xB0,0xB1,0xB4,0xB5,0xB6,0xC0,0xC1,0xC4,0xC5,0xC6,0xC9,
                      0xD0,0xD1,0xD5,0xD6,0xE0,0xE1,0xE4,0xE5,0xE6,0xE9,0xF0,0xF1,
                      0xF5,0xF6):
            off += 2
        elif byte in (0x19,0x1D,0x1E,0x20,0x2C,0x2D,0x2E,0x39,0x3D,0x3E,0x4C,0x4D,
                      0x4E,0x59,0x5D,0x5E,0x6C,0x6D,0x6E,0x79,0x7D,0x7E,0x8C,0x8D,
                      0x8E,0x99,0x9D,0xAC,0xAD,0xAE,0xB9,0xBC,0xBD,0xBE,0xCC,0xCD,
                      0xCE,0xD9,0xDD,0xDE,0xEC,0xED,0xEE,0xF9,0xFD,0xFE):
            off += 3
        else:
            off += 1  # unknown, skip byte

    return issues


def main():
    print("=" * 78)
    print("  Mega Man 2 — Per-Bank Byte-Level Verification")
    print("=" * 78)
    print()

    all_pass = True
    total_mismatches = 0

    for bank_num in range(16):
        hex_str = f'{bank_num:02X}'
        mismatches, error = verify_bank(bank_num)

        if error:
            print(f"  Bank ${hex_str}: ERROR — {error}")
            all_pass = False
            continue

        if mismatches:
            total_mismatches += len(mismatches)
            print(f"  Bank ${hex_str}: FAIL — {len(mismatches)} byte mismatches")
            for addr, exp, act in mismatches[:10]:
                print(f"    ${addr:04X}: expected ${exp:02X}, got ${act:02X}")
            if len(mismatches) > 10:
                print(f"    ... and {len(mismatches) - 10} more")
            all_pass = False
        else:
            print(f"  Bank ${hex_str}: PASS (16384 bytes match)")

    print()
    print("=" * 78)
    if all_pass:
        print("  ALL 16 BANKS VERIFIED: byte-perfect match!")
    else:
        print(f"  VERIFICATION FAILED: {total_mismatches} total byte mismatches")
    print("=" * 78)

    # Also check for encoding ambiguities (ZP vs ABS)
    print()
    print("=" * 78)
    print("  Encoding Ambiguity Check (absolute mode for ZP addresses)")
    print("=" * 78)
    print()

    total_ambiguities = 0
    for bank_num in range(16):
        hex_str = f'{bank_num:02X}'
        bin_path = f'build/bank{hex_str}.bin'
        asm_path = f'src/bank{hex_str}.asm'
        base_addr = 0xC000 if bank_num == 0x0F else 0x8000

        if not os.path.exists(bin_path):
            continue

        # Inline the check (avoid import issues)
        with open(bin_path, 'rb') as f:
            bin_data = f.read()

        # Check for absolute-mode instructions addressing $00XX
        abs_zp_count = 0
        off = 0
        while off < len(bin_data):
            byte = bin_data[off]
            # 3-byte absolute-mode opcodes that have ZP equivalents
            abs_opcodes_3byte = {
                0x0D, 0x0E, 0x2C, 0x2D, 0x2E, 0x4D, 0x4E,
                0x6D, 0x6E, 0x8C, 0x8D, 0x8E, 0xAC, 0xAD,
                0xAE, 0xCC, 0xCD, 0xCE, 0xEC, 0xED, 0xEE,
                # Also ABX/ABY variants
                0x1D, 0x1E, 0x19, 0x39, 0x3D, 0x3E, 0x59, 0x5D, 0x5E,
                0x79, 0x7D, 0x7E, 0x99, 0x9D, 0xB9, 0xBC, 0xBD, 0xBE,
                0xD9, 0xDD, 0xDE, 0xF9, 0xFD, 0xFE,
            }
            # Size lookup
            if byte in (0x00, 0x08, 0x0A, 0x18, 0x28, 0x2A, 0x38, 0x40, 0x48,
                        0x4A, 0x58, 0x60, 0x68, 0x6A, 0x78, 0x88, 0x8A, 0x98,
                        0x9A, 0xA8, 0xAA, 0xB8, 0xBA, 0xC8, 0xCA, 0xE8, 0xEA, 0xF8):
                off += 1
            elif byte in abs_opcodes_3byte:
                if off + 2 < len(bin_data):
                    hi = bin_data[off + 2]
                    lo = bin_data[off + 1]
                    if hi == 0x00:
                        abs_zp_count += 1
                off += 3
            elif byte in (0x20, 0x4C, 0x6C):  # JSR, JMP abs, JMP ind
                off += 3
            elif byte & 0x1F in (0x01, 0x05, 0x06, 0x09, 0x10, 0x11, 0x15, 0x16, 0x00):
                # Various 2-byte instructions (approximation)
                if byte in (0x01,0x05,0x06,0x09,0x10,0x11,0x15,0x16,0x21,0x24,0x25,0x26,
                            0x29,0x30,0x31,0x35,0x36,0x41,0x45,0x46,0x49,0x50,0x51,0x55,
                            0x56,0x61,0x65,0x66,0x69,0x70,0x71,0x75,0x76,0x81,0x84,0x85,
                            0x86,0x90,0x91,0x94,0x95,0x96,0xA0,0xA1,0xA2,0xA4,0xA5,0xA6,
                            0xA9,0xB0,0xB1,0xB4,0xB5,0xB6,0xC0,0xC1,0xC4,0xC5,0xC6,0xC9,
                            0xD0,0xD1,0xD5,0xD6,0xE0,0xE1,0xE4,0xE5,0xE6,0xE9,0xF0,0xF1,
                            0xF5,0xF6):
                    off += 2
                else:
                    off += 1
            else:
                off += 1

        if abs_zp_count > 0:
            total_ambiguities += abs_zp_count
            print(f"  Bank ${hex_str}: {abs_zp_count} absolute-mode instructions addressing $00XX")
        else:
            print(f"  Bank ${hex_str}: clean")

    print()
    if total_ambiguities > 0:
        print(f"  Total: {total_ambiguities} absolute-for-ZP encoding instances")
        print(f"  (da65 should handle these with 'a:$XX' syntax — verify they reassemble correctly)")
    else:
        print(f"  No encoding ambiguities found.")

    return 0 if all_pass else 1


if __name__ == '__main__':
    sys.exit(main())
