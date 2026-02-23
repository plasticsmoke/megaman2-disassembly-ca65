#!/usr/bin/env python3
"""
add_comments_0C.py — Add block headers and inline comments to bank0C_weapons_ui.asm

This script:
  1. Reads bank0C_weapons_ui.asm
  2. Adds block comment headers before major routine labels (if not already present)
  3. Adds inline comments to key instructions (column 40+)
  4. Writes the result back

RULES:
  - Never modify instruction bytes, operands, or .byte data
  - Never change existing comments — only ADD new ones
  - Never change label names
  - Comments go on the SAME LINE as the instruction (after ; at column 40+)
  - Block headers go on lines BEFORE the label definition
  - Only add a block header if there isn't a ; ===== within 3 lines above
"""

import re
import sys
import os

ASM_FILE = os.path.join(os.path.dirname(__file__), '..', 'src', 'bank0C_weapons_ui.asm')

# --- Block headers: label_name -> (description, address) ---
BLOCK_HEADERS = {
    "weapon_dispatch_check_fd": (
        "Weapon Dispatch — route weapon/UI commands by code ($FC/$FD/$FE/$FF)",
        "$8003"
    ),
    "weapon_secondary_init": (
        "Weapon Secondary Init — initialize weapon slots without CHR-RAM upload",
        "$8128"
    ),
    "weapon_check_sound_slot": (
        "Weapon Sound Slot Check — verify APU channel availability for weapon",
        "$816C"
    ),
    "weapon_clear_display": (
        "Weapon Clear Display — zero out all 4 weapon CHR-RAM slots",
        "$8190"
    ),
    "draw_energy_bar_template": (
        "Draw Energy Bar Template — fill 16 tiles with blank energy bar pattern",
        "$81B3"
    ),
    "weapon_sound_copy_data": (
        "Weapon Sound Data Copy — copy 4 bytes of instrument data to CHR buffer",
        "$81C4"
    ),
    "display_offset_next_slot": (
        "Display Offset Next Slot — advance $EC by $1F to next weapon display slot",
        "$8207"
    ),
    "apu_sound_control": (
        "APU Sound Control — silence or enable APU channel pair",
        "$8222"
    ),
    "hud_energy_bar_update": (
        "HUD Energy Bar Update — per-tick energy bar drain/fill animation",
        "$82EC"
    ),
    "hud_sound_sweep_check": (
        "Sound Sweep Engine — process pitch sweep and envelope for active channel",
        "$838F"
    ),
    "hud_frequency_calc": (
        "Sound Frequency Calculator — compute and write APU frequency registers",
        "$84A9"
    ),
    "hud_sound_channel_off": (
        "Sound Channel Off — disable APU channel if not noise channel",
        "$84FD"
    ),
    "sound_state_init_slot": (
        "Sound State Init Slot — reset envelope/sweep state for sound slot",
        "$8516"
    ),
    "sound_dispatch_table": (
        "Sound Dispatch Table — indirect jump via inline pointer table",
        "$8556"
    ),
    "sound_stream_check": (
        "Sound Data Stream Interpreter — fetch and execute sound stream commands",
        "$856D"
    ),
    "sound_data_read_byte": (
        "Sound Data Read Byte — read next byte from ($F0) stream pointer",
        "$86A0"
    ),
    "sound_note_process": (
        "Sound Note Processing — advance note timing and trigger bar updates",
        "$86B4"
    ),
    "sound_note_done": (
        "Sound Note Done — instrument/pattern fetch after note completes",
        "$86FE"
    ),
    "sound_pattern_fetch": (
        "Sound Pattern Fetch — read and dispatch instrument pattern commands",
        "$8706"
    ),
    "sound_cmd_dispatch": (
        "Sound Command Dispatch — execute pattern sub-commands via jump table",
        "$87C0"
    ),
    "sound_instrument_load": (
        "Sound Instrument Load — load 4-byte instrument data from pointer table",
        "$88E1"
    ),
    "sound_stream_read_next": (
        "Sound Stream Read Next — read byte from current sound stream pointer",
        "$8935"
    ),
    "sound_freq_multiply": (
        "Sound Frequency Multiply — multiply frequency by duty cycle period",
        "$8954"
    ),
    "weapon_shift_table_1": (
        "Sound/Weapon Data Tables — frequency tables, weapon data pointers",
        "$8978"
    ),
    "weapon_data_ptr_lo": (
        "Weapon Data Pointer Table — low/high bytes for each weapon's CHR data",
        "$8AD6"
    ),
    "weapon_data_unused_1": (
        "Music/Sound Pattern Data — encoded music sequences for all stages",
        "$8A80"
    ),
}

# --- Inline comments: (label_or_instruction_pattern, comment) ---
# These are added at column 40+ on lines that match.
INLINE_COMMENTS = {
    # Weapon select
    "weapon_select_store_type:  stx     $E5": "; store weapon type in temp",
    "weapon_select_high_nybble:  lda     $E0": "; check high nybble path",
    "weapon_select_high_store:  stx     $E5": "; store high nybble weapon type",

    # CHR-RAM
    "chr_ram_data_transfer:  clc": "; advance pointer to next tile data",
    "chr_ram_padding_fill:  asl     a:$A9": "; fill padding bytes in CHR shadow",

    # Password
    "password_mode_init:  sty     $E8": "; enter password screen mode",

    # Weapon clear
    "weapon_clear_display:  lda     $E0": "; clear weapon display slots",

    # HUD
    "hud_init_slot_vars:  ldx     #$00": "; initialize 4 HUD slot variables",
    "hud_lives_display:  lda     $E8": "; check lives counter display flag",
    "hud_check_refill_timer:  lda     $F2": "; check refill animation timer",

    # APU
    "apu_enable_channels:  lda     #$07": "; enable pulse 1+2 + triangle",
    "apu_sound_control:  cpy     #$01": "; Y=1: enable channels, else silence",

    # Sound engine
    "sound_stream_fetch:  jsr     sound_data_read_byte": "; fetch next sound command byte",
    "sound_stream_cmd_check:  txa": "; check for special command ($xF)",
    "sound_stream_new_note:  and     #$07": "; extract note duration bits",
    "sound_data_read_byte:  ldy     #$00": "; read byte and advance pointer",
    "sound_note_process:  lda     $E7": "; process note with repeat count",
    "sound_note_tick:  ldy     #$05": "; tick note timer, handle double-speed",
    "sound_note_done:  ldy     #$05": "; end of note — fetch instrument data",
    "sound_pattern_fetch:  jsr     sound_stream_read_next": "; fetch pattern byte from stream",
    "sound_instrument_load:  txa": "; X = instrument index",
    "sound_stream_read_next:  ldy     #$00": "; read byte from ($EC) stream",
    "sound_freq_multiply:  sta     zp_F4": "; multiply freq by period count",
}


def add_block_headers(lines):
    """Add block headers before major routine labels."""
    result = []
    for i, line in enumerate(lines):
        stripped = line.rstrip()
        # Check if this line starts with a label we want to annotate
        for label, (desc, addr) in BLOCK_HEADERS.items():
            if stripped.startswith(label + ':') or stripped.startswith(label + ' '):
                # Check if there's already a ===== header within 3 lines above
                has_header = False
                for j in range(max(0, len(result) - 3), len(result)):
                    if '=====' in result[j]:
                        has_header = True
                        break
                if not has_header:
                    result.append('')
                    result.append('; =============================================================================')
                    result.append(f'; {label} — {desc} ({addr})')
                    result.append('; =============================================================================')
                break
        result.append(line.rstrip('\n'))
    return result


def add_inline_comments(lines):
    """Add inline comments to key instructions."""
    result = []
    for line in lines:
        stripped = line.rstrip()
        # Skip lines that already have comments
        if ';' in stripped:
            result.append(stripped)
            continue
        # Check each inline comment pattern
        for pattern, comment in INLINE_COMMENTS.items():
            if stripped.startswith(pattern) or stripped.lstrip().startswith(pattern):
                # Pad to column 40 minimum
                if len(stripped) < 40:
                    stripped = stripped.ljust(40)
                stripped = stripped + ' ' + comment
                break
        result.append(stripped)
    return result


def main():
    if not os.path.exists(ASM_FILE):
        print(f"ERROR: {ASM_FILE} not found")
        sys.exit(1)

    with open(ASM_FILE, 'r') as f:
        lines = f.readlines()

    print(f"Read {len(lines)} lines from {ASM_FILE}")

    # Add block headers
    lines = add_block_headers(lines)
    print(f"After block headers: {len(lines)} lines")

    # Add inline comments
    lines = add_inline_comments(lines)

    # Count additions
    block_count = sum(1 for l in lines if '=====' in l and 'Bank $0C' not in l)
    # Subtract existing headers (the ones already in the file before our additions)
    # The file already had 3 ===== headers (bank header, weapon select, HUD)

    with open(ASM_FILE, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    print(f"Wrote {len(lines)} lines to {ASM_FILE}")
    print(f"Block header lines (=====): {block_count}")


if __name__ == '__main__':
    main()
