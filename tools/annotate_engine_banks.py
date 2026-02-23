#!/usr/bin/env python3
"""
Annotate game engine banks ($0B-$0E) with descriptive labels and comments.
"""

import re
import os

# ─── Generic annotation engine ───────────────────────────────────────────────

def annotate_bank(asm_path, label_renames, section_headers, inline_comments):
    """Apply label renames, section headers, and inline comments to a bank."""
    with open(asm_path, 'r') as f:
        lines = f.readlines()

    # Skip labels mapping to expressions with '+' etc.
    skip_labels = {k for k, v in label_renames.items() if '+' in v or '(' in v}

    output_lines = []
    rename_count = 0
    comment_count = 0

    for line in lines:
        modified_line = line

        # Apply label renames
        for old_label, new_label in label_renames.items():
            if old_label in skip_labels or old_label not in modified_line:
                continue
            stripped = modified_line.lstrip()

            # Label definition at start of line
            if re.match(rf'^{re.escape(old_label)}:', modified_line):
                modified_line = modified_line.replace(f'{old_label}:', f'{new_label}:', 1)
                # Also replace any remaining references on same line (e.g., self-branch)
                if old_label in modified_line:
                    modified_line = modified_line.replace(old_label, new_label)
                rename_count += 1
            # := definition
            elif re.match(rf'^{re.escape(old_label)}\s+:=', modified_line):
                modified_line = modified_line.replace(old_label, new_label, 1)
                rename_count += 1
            # References in code (not in .byte data or comments)
            elif not stripped.startswith('.byte') and not stripped.startswith(';'):
                modified_line = modified_line.replace(old_label, new_label)
                rename_count += 1

        # Add inline comments
        stripped = modified_line.strip()
        for pattern, comment in inline_comments.items():
            if stripped.startswith(pattern) and ';' not in modified_line:
                code_part = modified_line.rstrip('\n')
                if len(code_part) < 40:
                    code_part = code_part.ljust(40)
                modified_line = code_part + comment + '\n'
                comment_count += 1
                break

        output_lines.append(modified_line)

    # Insert section headers
    final_lines = []
    for line in output_lines:
        stripped = line.strip()
        for trigger, header in section_headers.items():
            if stripped.startswith(trigger):
                final_lines.append('\n' + header)
                break
        final_lines.append(line)

    with open(asm_path, 'w') as f:
        f.writelines(final_lines)

    bank_name = os.path.basename(asm_path)
    print(f'  {bank_name}: {rename_count} renames, {comment_count} comments, {len(section_headers)} sections')
    return rename_count, comment_count


# ─── Bank $0E: Game Engine ────────────────────────────────────────────────────

BANK0E_RENAMES = {
    # External references to fixed bank (rename for clarity)
    'LC051': 'bank_switch_enqueue',
    'LD11B': 'ppu_buffer_transfer',
    'LD2ED': 'fixed_D2ED',
    'L0008': 'jump_ptr',

    # Key routines
    'L8000': 'game_engine_entry',
    'L8035': 'hardware_init',
    'L80AF': 'clear_ram',
    'L80CA': 'init_mmc1',
    'L80E8': 'init_ppu',
    'L8112': 'main_loop',
    'L8118': 'wait_for_nmi',
    'L811E': 'main_dispatch',
    'L8128': 'game_state_table_lo',
    'L8139': 'game_state_table_hi',
}

BANK0E_SECTIONS = {
    'game_engine_entry:': (
        '; =============================================================================\n'
        '; Game Engine Entry & Hardware Init\n'
        '; Called from cold_boot_init in fixed bank after reset.\n'
        '; =============================================================================\n'
    ),
    'main_loop:': (
        '; =============================================================================\n'
        '; Main Game Loop\n'
        '; Waits for NMI (VBLANK), then dispatches based on game state.\n'
        '; =============================================================================\n'
    ),
}

BANK0E_COMMENTS = {
    'game_engine_entry:': '; Entry from cold_boot_init',
}

# ─── Bank $0D: Stage Engine ───────────────────────────────────────────────────

BANK0D_RENAMES = {
    'LC051': 'bank_switch_enqueue',
    'LD11B': 'ppu_buffer_transfer',
    'LD1DF': 'ppu_scroll_column_update',
    'LD2ED': 'fixed_D2ED',
    'LD2EF': 'fixed_D2EF',
    'L0006': 'zp_temp_06',

    # Entry point dispatch table (raw JMP bytes at $8000)
    'L8015': 'stage_init',
    'L80AB': 'stage_main_loop',
    'L80C8': 'stage_paused_handler',
    'L80D9': 'stage_select_handler',

    # Sprite / OAM
    'L8312': 'player_render_collision',
    'L8358': 'render_player_sprites',
    'L83AC': 'write_sprite_to_oam',
    'L83D5': 'update_projectile_anim',
    'L8473': 'clear_oam_buffer',

    # Stage setup
    'L829E': 'load_scroll_palette',
    'L843C': 'load_stage_nametable',
    'L847E': 'reset_scroll_state',
    'L8499': 'stage_palette_data',

    # Stage data tables
    'L861D': 'collision_x_offset_table',
    'L8626': 'collision_y_offset_table',
    'L860D': 'collision_box_table',
    'L863F': 'nametable_fill_table',

    # Physics
    'L99C6': 'update_animation_frame',
    'L99E5': 'update_all_entities',
    'L99F9': 'apply_gravity',
    'L9AC8': 'entity_update_handler',

    # Stage transition
    'L90EC': 'stage_midpoint_entry',
    'LB101': 'stage_routine_B1',
    'LB6F1': 'stage_routine_B6',
    'LBAE0': 'stage_routine_BA',
}

BANK0D_SECTIONS = {
    'stage_init:': (
        '; =============================================================================\n'
        '; Stage Initialization\n'
        '; Sets up PPU, loads stage palette/nametables, enters main loop.\n'
        '; =============================================================================\n'
    ),
    'stage_main_loop:': (
        '; =============================================================================\n'
        '; Stage Main Loop\n'
        '; Per-frame update: render player, check pause, sync PPU.\n'
        '; =============================================================================\n'
    ),
    'player_render_collision:': (
        '; =============================================================================\n'
        '; Player Rendering & Collision\n'
        '; =============================================================================\n'
    ),
    'clear_oam_buffer:': (
        '; =============================================================================\n'
        '; OAM Buffer Management\n'
        '; =============================================================================\n'
    ),
    'update_animation_frame:': (
        '; =============================================================================\n'
        '; Entity Update & Physics\n'
        '; =============================================================================\n'
    ),
}

BANK0D_COMMENTS = {
    'stage_init:': '; Stage init: setup PPU, load data, start loop',
    'stage_main_loop:': '; Main stage loop (called each frame)',
    'clear_oam_buffer:': '; Fill OAM with $F8 (sprites off-screen)',
    'apply_gravity:': '; Apply downward acceleration to entity',
    'update_all_entities:': '; Loop over all entities, call update handler',
}

# ─── Bank $0B: Game Logic / Enemy AI ─────────────────────────────────────────

BANK0B_RENAMES = {
    'LC051': 'bank_switch_enqueue',
    'LD0B0': 'fixed_D0B0',
    'LD332': 'fixed_D332',
    'LD3E0': 'fixed_D3E0',
    'LD77C': 'fixed_D77C',
    'LDA43': 'fixed_DA43',
    'L0008': 'jump_ptr',
    'L0000': 'zp_temp_00',

    # Entry points
    'LA451': 'boss_init',
    'L801E': 'enemy_ai_dispatch',
    'L9FD3': 'enemy_ai_fallback',

    # Tables
    'L802B': 'enemy_spawn_timer_table',
    'L8039': 'enemy_spawn_enable_table',
    'L8047': 'enemy_ai_routine_lo',
    'L8055': 'enemy_ai_routine_hi',
    'L814E': 'enemy_state_transition',
    'L8156': 'enemy_spawn_sound_ids',

    # Boss property tables
    'LA4AF': 'boss_ai_flags',
    'LA4BD': 'boss_movement_mode',
    'LA4CB': 'boss_x_position',
    'LA4D9': 'boss_y_position',
    'LA4E7': 'boss_type_table',
    'LA503': 'boss_palette_table',

    # Sprite / collision
    'L8383': 'enemy_sprite_ids',
    'L83A1': 'enemy_palette_data',
    'L83BF': 'enemy_x_offsets',
    'L83DD': 'enemy_collision_data',
    'L83FB': 'enemy_damage_values',
    'LA231': 'collision_check_sprite',
    'LA52D': 'setup_ppu_normal',
    'LA6F7': 'render_active_entities',
    'LA7B0': 'stage_transition_seq',

    # Projectile tables
    'L9A8C': 'projectile_x_velocity',
    'L9AA2': 'projectile_y_velocity',
    'L9AB8': 'projectile_timing',
    'L9ACE': 'projectile_anim_frames',
    'L9AF6': 'projectile_tile_ids',
}

BANK0B_SECTIONS = {
    'enemy_ai_dispatch:': (
        '; =============================================================================\n'
        '; Enemy AI Dispatch\n'
        '; Dispatches to enemy-specific AI routine based on Y index.\n'
        '; 14 entries: 8 Robot Masters + 6 Wily fortress enemies.\n'
        '; =============================================================================\n'
    ),
    'boss_init:': (
        '; =============================================================================\n'
        '; Boss Initialization\n'
        '; Sets up boss properties from indexed tables.\n'
        '; X = boss ID ($B3), loads AI flags, position, type, etc.\n'
        '; =============================================================================\n'
    ),
}

BANK0B_COMMENTS = {
    'enemy_ai_dispatch:': '; Dispatch to AI routine via pointer table',
    'boss_init:': '; Initialize boss from property tables (X = boss ID)',
    'collision_check_sprite:': '; Check collision between player and sprite',
}

# ─── Bank $0C: Weapons & UI ──────────────────────────────────────────────────

BANK0C_RENAMES = {
    'L0002': 'zp_temp_02',
    'L00F4': 'zp_F4',

    # Entry points
    'L8235': 'hud_update_main',
    'L812D': 'password_mode_init',
    'L813A': 'weapon_secondary_init',
    'L818C': 'weapon_clear_display',
    'L802F': 'weapon_select_handler',
    'L8011': 'weapon_dispatch_check_fd',
    'L8020': 'weapon_dispatch_check_ff',

    # HUD routines
    'L824C': 'hud_slot_loop',
    'L82B9': 'hud_lives_display',
    'L81B2': 'draw_energy_bar_template',
    'L8207': 'display_offset_next_slot',
    'L8222': 'apu_sound_control',

    # CHR-RAM upload
    'L807C': 'chr_ram_tile_copy',
    'L806D': 'chr_ram_data_transfer',

    # Weapon data
    'L8A50': 'weapon_data_ptr_lo',
    'L8A51': 'weapon_data_ptr_hi',
    'L8975': 'weapon_shift_table_1',
    'L897D': 'weapon_shift_table_2',
}

BANK0C_SECTIONS = {
    'hud_update_main:': (
        '; =============================================================================\n'
        '; HUD Update (Main)\n'
        '; Called each frame to update weapon energy bars and lives display.\n'
        '; =============================================================================\n'
    ),
    'weapon_select_handler:': (
        '; =============================================================================\n'
        '; Weapon Selection Handler\n'
        '; Processes weapon select from pause menu.\n'
        '; =============================================================================\n'
    ),
    'password_mode_init:': (
        '; =============================================================================\n'
        '; Password Screen\n'
        '; =============================================================================\n'
    ),
}

BANK0C_COMMENTS = {
    'hud_update_main:': '; Main HUD update (energy bars, lives)',
    'weapon_select_handler:': '; Handle weapon selection (A = weapon index)',
    'password_mode_init:': '; Enter password screen mode',
    'draw_energy_bar_template:': '; Draw empty 16-tile energy bar',
    'chr_ram_tile_copy:': '; Copy tile data to CHR-RAM shadow at $0500',
}


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    print('Annotating game engine banks...')
    print()

    banks = [
        ('src/bank0E_game_engine.asm', BANK0E_RENAMES, BANK0E_SECTIONS, BANK0E_COMMENTS),
        ('src/bank0D_stage_engine.asm', BANK0D_RENAMES, BANK0D_SECTIONS, BANK0D_COMMENTS),
        ('src/bank0B_game_logic.asm', BANK0B_RENAMES, BANK0B_SECTIONS, BANK0B_COMMENTS),
        ('src/bank0C_weapons_ui.asm', BANK0C_RENAMES, BANK0C_SECTIONS, BANK0C_COMMENTS),
    ]

    total_renames = 0
    total_comments = 0

    for asm_path, renames, sections, comments in banks:
        if not os.path.exists(asm_path):
            print(f'  SKIP: {asm_path} not found')
            continue
        r, c = annotate_bank(asm_path, renames, sections, comments)
        total_renames += r
        total_comments += c

    print()
    print(f'Total: {total_renames} renames, {total_comments} comments')


if __name__ == '__main__':
    main()
