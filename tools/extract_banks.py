#!/usr/bin/env python3
"""Extract 16 x 16KB PRG banks from Mega Man 2 (U) and generate da65 info files."""

import os

ROM_PATH = "mm2.nes"
BUILD_DIR = "build"
HEADER_SIZE = 16
BANK_SIZE = 0x4000  # 16KB
NUM_BANKS = 16

os.makedirs(BUILD_DIR, exist_ok=True)

with open(ROM_PATH, "rb") as f:
    rom = f.read()

assert len(rom) == HEADER_SIZE + NUM_BANKS * BANK_SIZE, f"Unexpected ROM size: {len(rom)}"

for i in range(NUM_BANKS):
    offset = HEADER_SIZE + i * BANK_SIZE
    bank_data = rom[offset:offset + BANK_SIZE]

    # Write raw bank binary
    bin_path = os.path.join(BUILD_DIR, f"bank{i:02X}.bin")
    with open(bin_path, "wb") as f:
        f.write(bank_data)

    # Bank 0F (last bank) is fixed at $C000; all others at $8000
    start_addr = 0xC000 if i == 0x0F else 0x8000

    # Write da65 info file
    info_path = os.path.join(BUILD_DIR, f"bank{i:02X}.info")
    with open(info_path, "w") as f:
        f.write(f"GLOBAL {{\n")
        f.write(f"    STARTADDR ${start_addr:04X};\n")
        f.write(f"    INPUTOFFS 0;\n")
        f.write(f"    INPUTSIZE ${BANK_SIZE:04X};\n")
        f.write(f'    CPU "6502";\n')
        f.write(f"}};\n")

    print(f"Bank ${i:02X}: {bin_path} ({len(bank_data)} bytes, start=${start_addr:04X})")

print(f"\nExtracted {NUM_BANKS} banks to {BUILD_DIR}/")
