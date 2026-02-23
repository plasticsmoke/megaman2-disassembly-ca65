#!/usr/bin/env python3
"""
Annotate bank0F.asm (fixed bank) with descriptive labels and comments.

Renames auto-generated LXXXX labels to descriptive names and adds
inline comments for key routines.
"""

import re

ASM_PATH = 'src/bank0F.asm'

# ─── Label renames ────────────────────────────────────────────────────────────
# Maps old label -> new label
LABEL_RENAMES = {
    # Entry points / vectors
    'LFFE0': 'reset_handler',
    'LFFE1': 'reset_handler+1',  # self-modifying code target, skip
    'LF2D1': 'cold_boot_init',
    'LCFF0': 'nmi_handler',
    'LFFF0': 'mmc1_scratch',     # MMC1 write target in ROM space

    # Bank switching
    'LC000': 'bank_switch',
    'LC022': 'bank_switch_with_callback',
    'LC03A': 'bank_switch_process_queue',
    'LC048': 'bank_switch_queue_done',
    'LC051': 'bank_switch_enqueue',
    'LC05C': 'bank_switch_enqueue_rts',

    # NMI handler internals
    'LCFFD': 'nmi_do_vblank',
    'LD023': 'nmi_update_palette',
    'LD02D': 'nmi_check_scroll_update',
    'LD034': 'nmi_check_ppu_update',
    'LD052': 'nmi_set_scroll_x',
    'LD066': 'nmi_set_scroll_y',
    'LD08D': 'nmi_tail',
    'LD095': 'nmi_restore_bank',
    'LD0AD': 'nmi_process_queue',
    'LD0BA': 'nmi_queue_call',
    'LD0C1': 'nmi_queue_done',
    'LD0C6': 'nmi_rng_and_exit',

    # Input / controllers
    'LD0D7': 'read_controllers',
    'LD0E1': 'read_controller_loop',
    'LD0E3': 'read_controller_bits',

    # PPU routines
    'LD0F5': 'upload_palette',
    'LD0FF': 'upload_palette_loop',
    'LD11B': 'ppu_buffer_transfer',
    'LD120': 'ppu_buffer_transfer_main',
    'LD122': 'ppu_buffer_entry_loop',
    'LD148': 'ppu_buffer_write_entry',
    'LD15A': 'ppu_buffer_write_row',
    'LD16B': 'ppu_buffer_write_bytes',
    'LD181': 'ppu_buffer_transfer_alt',
    'LD1DF': 'ppu_scroll_column_update',
    'LD1F9': 'ppu_attribute_update',

    # Common jump table pointer
    'L0008': 'jump_ptr',

    # Switchable bank entry points (called via bank switch)
    'L8000': 'banked_entry',
    'L8003': 'banked_entry_alt',
}

# ─── Inline comments ─────────────────────────────────────────────────────────
# Maps line content pattern -> comment to append (matched after stripping)
# These are matched against the FINAL (renamed) line content
# Format: (label_or_addr_pattern, comment)

COMMENTS_BY_LABEL = {
    # Bank switch routine
    'bank_switch:': '; PRG bank switch — A = bank number ($00-$0E)',
    'sta     $29': None,  # Will do context-sensitive comments instead
    'bank_switch_with_callback:': '; Switch to bank $0C (CHR upload?), call banked_entry',
    'bank_switch_process_queue:': '; Process queued bank switch requests',
    'bank_switch_queue_done:': '; Queue empty — restore original bank',
    'bank_switch_enqueue:': '; Enqueue a bank switch request (A = bank number)',

    # NMI handler
    'nmi_handler:': '; NMI handler — called every VBLANK',
    'nmi_do_vblank:': '; Main VBLANK processing path',
    'nmi_tail:': '; NMI exit path (also handles interrupted bank switches)',
    'nmi_restore_bank:': '; Restore bank that was active when NMI fired',
    'nmi_rng_and_exit:': '; Update RNG seed and return from interrupt',

    # Input
    'read_controllers:': '; Read both controllers into $23 (P1) and $24 (P2)',
    'read_controller_loop:': '; Read 8 bits from controller X',
    'read_controller_bits:': '; Shift in one button bit',

    # PPU routines
    'upload_palette:': '; Upload 32-byte palette from $0356 to PPU $3F00',
    'upload_palette_loop:': '; Copy palette bytes to PPUDATA',
    'ppu_buffer_transfer:': '; Transfer PPU update buffer to VRAM',
    'ppu_scroll_column_update:': '; Update nametable column during scroll',
    'ppu_attribute_update:': '; Update attribute table during scroll',

    # Reset / Init
    'reset_handler:': '; Reset vector entry point',
    'cold_boot_init:': '; Cold boot: init PPU, switch to bank $0E, start game',
}


def annotate():
    with open(ASM_PATH, 'r') as f:
        lines = f.readlines()

    # Build a set of all labels that need renaming (handle both definitions and references)
    # First, collect which old labels actually exist in the file
    old_labels_present = set()
    for line in lines:
        for old_label in LABEL_RENAMES:
            if old_label in line:
                old_labels_present.add(old_label)

    # Skip labels that map to expressions (like 'reset_handler+1')
    skip_labels = {k for k, v in LABEL_RENAMES.items() if '+' in v}

    output_lines = []
    rename_count = 0
    comment_count = 0

    for line_num, line in enumerate(lines):
        modified_line = line

        # Apply label renames
        for old_label, new_label in LABEL_RENAMES.items():
            if old_label in skip_labels:
                continue
            if old_label not in modified_line:
                continue

            # Handle label definitions: "LXXXX:" at start of line
            if re.match(rf'^{re.escape(old_label)}:', modified_line):
                modified_line = modified_line.replace(f'{old_label}:', f'{new_label}:', 1)
                rename_count += 1
            # Handle := definitions: "LXXXX := $XXXX"
            elif re.match(rf'^{re.escape(old_label)}\s+:=', modified_line):
                modified_line = modified_line.replace(old_label, new_label, 1)
                rename_count += 1
            # Handle references in instructions
            elif old_label in modified_line:
                # Don't rename inside .byte data or comments
                stripped = modified_line.lstrip()
                if not stripped.startswith('.byte') and not stripped.startswith(';'):
                    modified_line = modified_line.replace(old_label, new_label)
                    rename_count += 1

        # Add comments for labeled lines
        stripped = modified_line.strip()
        for pattern, comment in COMMENTS_BY_LABEL.items():
            if comment and stripped.startswith(pattern):
                # Check if there's already a comment
                if ';' not in modified_line:
                    # Pad to column 40 for alignment
                    code_part = modified_line.rstrip('\n')
                    if len(code_part) < 40:
                        code_part = code_part.ljust(40)
                    modified_line = code_part + comment + '\n'
                    comment_count += 1
                break

        output_lines.append(modified_line)

    # Add section headers for key routines
    final_lines = []
    section_headers = {
        'bank_switch:': (
            '; =============================================================================\n'
            '; Bank Switching (MMC1)\n'
            '; MMC1 requires 5 serial writes to set a register. Each write sends bit 0.\n'
            '; Writing to $E000-$FFFF sets the PRG bank register.\n'
            '; =============================================================================\n'
        ),
        'nmi_handler:': (
            '; =============================================================================\n'
            '; NMI Handler (VBLANK)\n'
            '; Called every frame during vertical blanking interval.\n'
            '; Handles: OAM DMA, palette upload, PPU buffer transfer, scroll setup.\n'
            '; =============================================================================\n'
        ),
        'read_controllers:': (
            '; =============================================================================\n'
            '; Controller Input\n'
            '; =============================================================================\n'
        ),
        'upload_palette:': (
            '; =============================================================================\n'
            '; PPU Update Routines\n'
            '; =============================================================================\n'
        ),
        'cold_boot_init:': (
            '; =============================================================================\n'
            '; Initialization\n'
            '; =============================================================================\n'
        ),
        'reset_handler:': (
            '; =============================================================================\n'
            '; Reset Handler & Vectors\n'
            '; =============================================================================\n'
        ),
    }

    for line in output_lines:
        stripped = line.strip()
        for pattern, header in section_headers.items():
            if stripped.startswith(pattern):
                final_lines.append('\n' + header)
                break
        final_lines.append(line)

    with open(ASM_PATH, 'w') as f:
        f.writelines(final_lines)

    print(f'Annotated {ASM_PATH}:')
    print(f'  {rename_count} label renames applied')
    print(f'  {comment_count} inline comments added')
    print(f'  {len(section_headers)} section headers inserted')


if __name__ == '__main__':
    annotate()
