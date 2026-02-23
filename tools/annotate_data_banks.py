#!/usr/bin/env python3
"""
Annotate data banks ($00-$0A) with file headers, section markers, and
descriptive labels for bank $09 (which has real code) and bank $0A (sound data).
"""

import os
import sys

# Add parent tools dir to path
sys.path.insert(0, os.path.dirname(__file__))
from annotate_engine_banks import annotate_bank


# ─── Bank $09: Stage Data 10 (Wily Stage — has real code) ────────────────────

BANK09_RENAMES = {
    # External references (data values, not real calls)
    'L0119': 'ram_0119',
    'L0504': 'ram_0504',
    'L050D': 'ram_050D',

    # Scroll/PPU update code
    'L8621': 'copy_sprite_block',
    'L8625': 'copy_sprite_loop',
    'L8677': 'scroll_update_done',
    'L865E': 'advance_scroll_section',
    'L86AE': 'check_scroll_boundary',
    'L86D0': 'copy_column_data',
    'L86EA': 'column_copy_done',
    'L86EB': 'calc_nametable_addr',

    # Data tables for scroll routines
    'L8700': 'sprite_data_ptr_lo',
    'L8708': 'sprite_data_ptr_hi',
    'L8AC8': 'scroll_increment_table',
    'L8AD8': 'scroll_boundary_table',
    'L8AE8': 'column_tile_index',
    'L8BE0': 'section_scroll_triggers',
    'L8C1D': 'section_ppu_buffer_hi',
    'L8C59': 'section_column_count',
}

BANK09_SECTIONS = {
    'copy_sprite_block:': (
        '; =============================================================================\n'
        '; Stage Scroll / Column Update Routines\n'
        '; Handles vertical scrolling nametable updates for Wily stages.\n'
        '; =============================================================================\n'
    ),
    'sprite_data_ptr_lo:': (
        '; =============================================================================\n'
        '; Stage Scroll Data Tables\n'
        '; =============================================================================\n'
    ),
}

BANK09_COMMENTS = {
    'copy_sprite_block:': '; Copy 4-byte sprite entries to OAM',
    'scroll_update_done:': '; Return from scroll update',
    'advance_scroll_section:': '; Move to next scroll section',
    'check_scroll_boundary:': '; Check if scroll reached section boundary',
    'copy_column_data:': '; Copy nametable column data to PPU buffer',
    'calc_nametable_addr:': '; Calculate nametable address from scroll position',
}


# ─── Bank $0A: Sound/Music Data ──────────────────────────────────────────────
# This bank is 100% data — all "code" instructions are data byte artifacts.
# The sound engine code lives in the fixed bank; this bank contains:
#   - Note frequency tables
#   - Duty/volume envelope tables
#   - Music sequence data for all stages
#   - Sound effect data
#
# We add section headers but minimal label renames since the data format
# is complex and label names from da65 are mostly just offset markers.

BANK0A_RENAMES = {
    'L8050': 'freq_table_base',
    'L8143': 'freq_table_extended',
    'L8B9E': 'envelope_data',
    'L8BC2': 'drum_pattern_data',
    'L8BEA': 'music_sequence_headers',
    'L9455': 'music_data_start',
    'L9D00': 'music_data_mid',
    'LA27A': 'music_data_patterns',
    'LAC9D': 'sfx_data_start',
    'LB100': 'sfx_data_section_2',
    'LB474': 'sfx_sprite_frame_data',
}

BANK0A_SECTIONS = {
    'freq_table_base:': (
        '; =============================================================================\n'
        '; Note Frequency Tables\n'
        '; APU timer values indexed by musical note number.\n'
        '; =============================================================================\n'
    ),
    'envelope_data:': (
        '; =============================================================================\n'
        '; Envelope / Instrument Data\n'
        '; Duty cycle, volume, and timing data for each instrument voice.\n'
        '; =============================================================================\n'
    ),
    'music_data_start:': (
        '; =============================================================================\n'
        '; Music Sequence Data\n'
        '; Stage BGM data: note sequences, durations, and channel assignments\n'
        '; for all stages (Robot Master stages, Wily fortress, title, etc.)\n'
        '; =============================================================================\n'
    ),
    'sfx_data_start:': (
        '; =============================================================================\n'
        '; Sound Effect Data\n'
        '; Waveform, pitch, and timing data for gameplay sound effects.\n'
        '; =============================================================================\n'
    ),
}

BANK0A_COMMENTS = {}


# ─── File headers for all data banks ─────────────────────────────────────────

FILE_HEADERS = {
    'src/bank00_stage_data_1.asm': (
        '; =============================================================================\n'
        '; Bank $00 — Stage Data 1\n'
        '; CHR tile patterns and level layout data.\n'
        '; This bank contains no executable code — all bytes are data.\n'
        '; =============================================================================\n'
    ),
    'src/bank01_stage_data_2.asm': (
        '; =============================================================================\n'
        '; Bank $01 — Stage Data 2\n'
        '; CHR tile patterns and level layout data.\n'
        '; This bank contains no executable code — all bytes are data.\n'
        '; =============================================================================\n'
    ),
    'src/bank02_stage_data_3.asm': (
        '; =============================================================================\n'
        '; Bank $02 — Stage Data 3\n'
        '; CHR tile patterns and level layout data.\n'
        '; This bank contains no executable code — all bytes are data.\n'
        '; =============================================================================\n'
    ),
    'src/bank03_stage_data_4.asm': (
        '; =============================================================================\n'
        '; Bank $03 — Stage Data 4\n'
        '; CHR tile patterns and level layout data.\n'
        '; This bank contains no executable code — all bytes are data.\n'
        '; =============================================================================\n'
    ),
    'src/bank04_stage_data_5.asm': (
        '; =============================================================================\n'
        '; Bank $04 — Stage Data 5\n'
        '; CHR tile patterns and level layout data.\n'
        '; This bank contains no executable code — all bytes are data.\n'
        '; =============================================================================\n'
    ),
    'src/bank05_stage_data_6.asm': (
        '; =============================================================================\n'
        '; Bank $05 — Stage Data 6\n'
        '; CHR tile patterns and level layout data.\n'
        '; This bank contains no executable code — all bytes are data.\n'
        '; =============================================================================\n'
    ),
    'src/bank06_stage_data_7.asm': (
        '; =============================================================================\n'
        '; Bank $06 — Stage Data 7\n'
        '; CHR tile patterns and level layout data.\n'
        '; This bank contains no executable code — all bytes are data.\n'
        '; =============================================================================\n'
    ),
    'src/bank07_stage_data_8.asm': (
        '; =============================================================================\n'
        '; Bank $07 — Stage Data 8\n'
        '; CHR tile patterns and level layout data.\n'
        '; This bank contains no executable code — all bytes are data.\n'
        '; =============================================================================\n'
    ),
    'src/bank08_stage_data_9.asm': (
        '; =============================================================================\n'
        '; Bank $08 — Stage Data 9\n'
        '; CHR tile patterns and level layout data.\n'
        '; This bank contains no executable code — all bytes are data.\n'
        '; =============================================================================\n'
    ),
    'src/bank09_stage_data_10.asm': (
        '; =============================================================================\n'
        '; Bank $09 — Stage Data 10 (Wily Fortress)\n'
        '; CHR tile patterns, level layout data, and stage-specific scroll\n'
        '; update routines for vertical-scrolling Wily fortress sections.\n'
        '; =============================================================================\n'
    ),
    'src/bank0A_sound_data.asm': (
        '; =============================================================================\n'
        '; Bank $0A — Sound / Music Data\n'
        '; Contains all music and sound effect data for the game.\n'
        '; The sound driver code lives in the fixed bank ($0F) — this bank\n'
        '; provides only data: note frequency tables, instrument envelopes,\n'
        '; music sequence data for all stages, and sound effect definitions.\n'
        '; NOTE: All "instructions" in this file are data bytes that da65\n'
        '; interpreted as opcodes. No executable code exists in this bank.\n'
        '; =============================================================================\n'
    ),
}


def add_file_header(asm_path, header):
    """Insert a file header comment after the .segment directive."""
    with open(asm_path, 'r') as f:
        lines = f.readlines()

    # Find the .segment line and insert header after it
    output = []
    header_inserted = False
    for line in lines:
        output.append(line)
        if not header_inserted and line.strip().startswith('.segment'):
            output.append('\n')
            output.append(header)
            header_inserted = True

    if header_inserted:
        with open(asm_path, 'w') as f:
            f.writelines(output)
        print(f'  {os.path.basename(asm_path)}: file header added')
    else:
        print(f'  {os.path.basename(asm_path)}: WARNING — no .segment found')


def main():
    print('Annotating data banks ($00-$0A)...')
    print()

    # Step 1: Add file headers to all data banks
    print('Adding file headers:')
    for asm_path, header in FILE_HEADERS.items():
        if not os.path.exists(asm_path):
            print(f'  SKIP: {asm_path} not found')
            continue
        # Check if header already exists (avoid double-insertion)
        with open(asm_path, 'r') as f:
            content = f.read()
        if 'Bank $0' in content and '========' in content.split('\n')[3] if len(content.split('\n')) > 3 else False:
            print(f'  {os.path.basename(asm_path)}: header already present, skipping')
            continue
        add_file_header(asm_path, header)
    print()

    # Step 2: Annotate bank $09 (has real code)
    print('Annotating bank $09 (stage scroll code):')
    if os.path.exists('src/bank09_stage_data_10.asm'):
        annotate_bank(
            'src/bank09_stage_data_10.asm',
            BANK09_RENAMES, BANK09_SECTIONS, BANK09_COMMENTS
        )
    print()

    # Step 3: Annotate bank $0A (sound data)
    print('Annotating bank $0A (sound data):')
    if os.path.exists('src/bank0A_sound_data.asm'):
        annotate_bank(
            'src/bank0A_sound_data.asm',
            BANK0A_RENAMES, BANK0A_SECTIONS, BANK0A_COMMENTS
        )
    print()

    print('Done.')


if __name__ == '__main__':
    main()
