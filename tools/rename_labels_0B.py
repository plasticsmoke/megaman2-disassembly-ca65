#!/usr/bin/env python3
"""
Rename auto-generated LXXXX labels in bank0B_game_logic.asm to descriptive names.

This script replaces all occurrences of each label (both definitions like
"L8006:" and references like "jsr L8006") with human-readable names based
on the code's function in the Mega Man 2 NES ROM.

Bank $0B is the game logic bank, containing:
  - Boss AI routines (8 Robot Masters + 6 Wily fortress bosses)
  - Boss initialization and property tables
  - Enemy spawn timers and dispatch tables
  - Collision detection and response
  - Projectile behavior and velocity tables
  - Entity movement helpers (facing, velocity calc, division-based aim)
  - Player-boss damage handling
  - Weapon damage tables per boss
  - Nametable and palette manipulation for boss intros
  - CHR tile data (latter half of bank is graphics data)
"""

import re
import sys
import os

ASM_FILE = os.path.join(os.path.dirname(__file__), '..', 'src', 'bank0B_game_logic.asm')

# =============================================================================
# External label renames: LXXXX := $XXXX references to bank $0F routines
# =============================================================================
EXTERNAL_RENAMES = {
    # Already named in bank0F:
    'LC10B': 'boss_death_sequence',        # $C10B — boss defeat explosion sequence
    'LC3A8': 'explosion_array_setup_inner', # $C3A8 — inner loop of setup_explosion_array
    'LC5F1': 'sound_column_copy',          # $C5F1 — sound/column copy helper (data region)
    'LC84E': 'divide_8bit',                # $C84E — 8-bit division
    'LC874': 'divide_16bit',               # $C874 — 16-bit division
    'LC8EF': 'metatile_render',            # $C8EF — render metatile to PPU buffer
    'LCA0B': 'scroll_attr_update',         # $CA0B — scroll attribute table update
    'LCC63': 'tile_lookup',                # $CC63 — tile type lookup from map

    # Non-ROM / PPU address references used as data labels
    'L0420': 'entity_flags_base',          # $0420 entity flags array base
    'L0508': 'addr_0508',                  # $0508 (used in data)
    'L0917': 'addr_0917',                  # $0917 (used in data)
    'L2020': 'ppu_addr_2020',              # $2020 PPU nametable address
    'L2220': 'ppu_addr_2220',              # $2220 PPU nametable address
    'L2820': 'ppu_addr_2820',              # $2820 PPU nametable address
}

# =============================================================================
# Internal label renames: LXXXX labels within bank $0B ($8000-$BFFF)
# Organized by functional region
# =============================================================================
INTERNAL_RENAMES = {
    # =========================================================================
    # Boss Init Entry & Enemy Spawn ($8000-$80C4)
    # =========================================================================
    'L8086': 'boss_spawn_special_type',
    'L808D': 'boss_spawn_inc_timer',
    'L80AF': 'boss_spawn_deplete',
    'L80C1': 'boss_spawn_store_count',
    'L80C4': 'boss_spawn_done',

    # =========================================================================
    # Boss Setup Helpers ($80F3-$813D)
    # =========================================================================
    'L80F3': 'boss_frame_update_rts',
    'L811B': 'boss_activate_phase',
    'L812F': 'boss_palette_timer_tick',
    'L813D': 'boss_palette_tick_rts',

    # =========================================================================
    # Boss AI: Bubbleman ($8160-$828A)
    # =========================================================================
    'L818E': 'bubbleman_store_aim_low',
    'L8194': 'bubbleman_spawn_projectile_loop',
    'L81D3': 'bubbleman_frame_update',
    'L81EE': 'bubbleman_attack_rts',
    'L81F4': 'bubbleman_proj_hitbox_y',
    'L81F7': 'bubbleman_proj_hitbox_mask',
    'L81FA': 'bubbleman_proj_speed_table',
    'L8247': 'bubbleman_check_anim_state',
    'L8250': 'bubbleman_dec_timer',
    'L8258': 'bubbleman_phase3_reset',
    'L826F': 'bubbleman_check_death_anim',
    'L828A': 'bubbleman_jmp_frame_update',
    'L828D': 'bubbleman_random_delay_table',

    # =========================================================================
    # Boss AI: Woodman ($82E0-$8470)
    # =========================================================================
    'L833C': 'woodman_spawn_leaf_loop',
    'L837E': 'woodman_leaf_count_table',
    'L83B6': 'woodman_leaf_data_overflow',
    'L83CD': 'woodman_leaf_data_mid',
    'L841E': 'woodman_dec_leaf_count',
    'L8436': 'woodman_shield_active',
    'L8456': 'woodman_update_scroll_lock',
    'L845C': 'woodman_sprite_scan_loop',
    'L846E': 'woodman_check_anim_state',
    'L847A': 'woodman_frame_update',

    # =========================================================================
    # Boss Frame Update Helper ($84D9-$84F2)
    # =========================================================================
    'L84D9': 'boss_update_with_sound',
    'L84E4': 'boss_update_collision_check',
    'L84F2': 'boss_update_rts',

    # =========================================================================
    # Boss AI: Airman ($8500-$864D)
    # =========================================================================
    'L851E': 'airman_check_phase',
    'L8522': 'airman_inc_timer',
    'L8531': 'airman_spawn_tornado',
    'L8538': 'airman_jmp_frame_update',
    'L853B': 'airman_spawn_multi_tornado',
    'L8546': 'airman_tornado_loop',
    'L8574': 'airman_advance_phase',
    'L857B': 'airman_frame_update',
    'L857F': 'airman_tornado_x_offset',
    'L8596': 'airman_bcc_frame_update',
    'L859F': 'airman_data_byte',
    'L85B0': 'airman_phase3_sound',
    'L85B7': 'airman_jmp_frame_update_2',
    'L8635': 'airman_collision_rts',
    'L8636': 'airman_update_with_sound',
    'L863F': 'airman_collision_check',
    'L864D': 'airman_update_rts',

    # =========================================================================
    # Boss AI: Crashman ($8650-$894B)
    # =========================================================================
    'L8652': 'crashman_ai_table_hi',
    'L8686': 'crashman_aim_check_dist',
    'L86A0': 'crashman_dec_aim_timer',
    'L86E6': 'crashman_frame_update',
    'L8722': 'crashman_check_dist_2',
    'L872F': 'crashman_dec_shot_timer',
    'L8747': 'crashman_check_anim_reset',
    'L8753': 'crashman_anim_rts',
    'L8771': 'crashman_update_with_sound',
    'L877C': 'crashman_collision_check',
    'L878A': 'crashman_collision_params',

    # =========================================================================
    # Boss AI: Quickman ($8800-$8892)
    # =========================================================================
    'L8826': 'quickman_check_anim',
    'L882E': 'quickman_check_y_vel',
    'L8861': 'quickman_spawn_boomerang_loop',
    'L888E': 'quickman_restore_y',
    'L8892': 'quickman_frame_rts',
    'L8893': 'quickman_y_vel_table',
    'L8896': 'quickman_sec_flag',
    'L889E': 'quickman_phase_transition',
    'L88B4': 'quickman_phase_id_table',
    'L88B6': 'quickman_sound_table',

    # =========================================================================
    # Boss AI: Quickman continued ($88D0-$894B)
    # =========================================================================
    'L88E3': 'quickman_state2_frame_update',
    'L8903': 'quickman_hitbox_params',
    'L890E': 'quickman_update_with_sound',
    'L8919': 'quickman_collision_check',
    'L892B': 'quickman_hit_response',
    'L894B': 'quickman_update_rts',

    # =========================================================================
    # Boss AI: Heatman ($8950-$8B13)
    # =========================================================================
    'L89B5': 'heatman_rts',
    'L8A08': 'heatman_frame_update',
    'L8A16': 'heatman_data_overlap',
    'L8A83': 'heatman_aim_adjust_x',
    'L8A9A': 'heatman_restore_y_pos',
    'L8AA8': 'heatman_jmp_frame_update',
    'L8AAB': 'heatman_aim_offset_table',
    'L8ACF': 'heatman_collision_rts',
    'L8AD0': 'heatman_hit_response',
    'L8AE4': 'heatman_update_with_sound',
    'L8AEF': 'heatman_collision_check',
    'L8AFE': 'heatman_hitbox_params',
    'L8B13': 'heatman_no_hit',

    # =========================================================================
    # Boss AI: Metalman ($8B20-$8CB5)
    # =========================================================================
    'L8B66': 'metalman_aim_at_player',
    'L8B6E': 'metalman_inc_timer',
    'L8B74': 'metalman_fire_blade',
    'L8BA1': 'metalman_vel_y_sub_table',
    'L8BA5': 'metalman_vel_y_hi_table',
    'L8BA9': 'metalman_vel_x_sub_table',
    'L8BAD': 'metalman_vel_x_hi_table',
    'L8BB1': 'metalman_phase_table',
    'L8C06': 'metalman_check_anim',
    'L8C0E': 'metalman_check_anim_2',
    'L8C3D': 'metalman_frame_rts',

    # =========================================================================
    # Metalman Palette Flash / Thunder Timer ($8C3E-$8CB5)
    # =========================================================================
    'L8C3E': 'metalman_palette_flash',
    'L8C83': 'metalman_palette_copy_loop',
    'L8C90': 'metalman_update_with_sound',
    'L8C9B': 'metalman_collision_check',
    'L8CA9': 'metalman_hitbox_params',
    'L8CB5': 'metalman_palette_data',

    # =========================================================================
    # Boss AI: Flashman ($8CC0-$8E07)
    # =========================================================================
    'L8D34': 'flashman_aim_y_offset',
    'L8D36': 'flashman_setup_velocity',
    'L8D68': 'flashman_check_x_right',
    'L8D6C': 'flashman_check_facing_flip',
    'L8D7C': 'flashman_frame_update',
    'L8DA7': 'flashman_hit_response',
    'L8DB6': 'flashman_check_anim_fire',
    'L8DE4': 'flashman_check_anim_state',
    'L8DEC': 'flashman_jmp_aim',
    'L8DF0': 'flashman_update_with_sound',
    'L8DF9': 'flashman_collision_check',
    'L8E07': 'flashman_update_rts',
    'L8E0C': 'flashman_ai_table_hi',

    # =========================================================================
    # Boss AI: Wily 1 — Mecha Dragon ($8E10-$8F79)
    # =========================================================================
    'L8E59': 'dragon_fill_column_loop',
    'L8E76': 'dragon_phase2_check',
    'L8E8E': 'dragon_attr_copy_loop',
    'L8E9F': 'dragon_phase3_setup',
    'L8EB0': 'dragon_clear_attr_loop_outer',
    'L8EB4': 'dragon_clear_attr_loop_inner',
    'L8ED8': 'dragon_phase_rts',
    'L8ED9': 'dragon_column_addr_hi_table',
    'L8EE8': 'dragon_column_addr_lo_table',
    'L8EF7': 'dragon_column_length_table',
    'L8F06': 'dragon_attr_data',
    'L8F3A': 'dragon_phase2_entry',
    'L8F3E': 'dragon_load_palette',
    'L8F79': 'dragon_palette_done',
    'L8F7A': 'dragon_palette_data',

    # =========================================================================
    # Boss AI: Wily 1 — Mecha Dragon battle ($8F8A-$9120)
    # =========================================================================
    'L8F90': 'dragon_sprite_collision_loop',
    'L8FAF': 'dragon_sprite_next',
    'L8FB2': 'dragon_movement_update',
    'L8FBD': 'dragon_dec_phase_timer',
    'L8FC8': 'dragon_frame_rts',
    'L8FC9': 'dragon_y_bounds_check',
    'L8FD5': 'dragon_y_reset_velocity',
    'L8FE5': 'dragon_y_set_rising',
    'L9002': 'dragon_sprite_scan_2',
    'L901A': 'dragon_sprite_next_2',
    'L901D': 'dragon_movement_update_2',
    'L9034': 'dragon_health_check_rts',
    'L9035': 'dragon_fire_breath',
    'L9053': 'dragon_fire_setup_velocity',
    'L9063': 'dragon_fire_done',
    'L907D': 'dragon_phase3_reset',
    'L9084': 'dragon_velocity_check',
    'L908C': 'dragon_check_x_velocity',
    'L909A': 'dragon_check_y_lower_bound',
    'L90A1': 'dragon_reverse_velocity',
    'L90B6': 'dragon_apply_facing',
    'L9100': 'dragon_phase2_reset',
    'L9107': 'dragon_jmp_vel_check',
    'L910A': 'dragon_check_fire_range',
    'L9117': 'dragon_fire_range_check_2',
    'L9120': 'dragon_no_fire',

    # =========================================================================
    # Boss AI: Wily 1 — Dragon palette fade ($9122-$9164)
    # =========================================================================
    'L9139': 'dragon_palette_fade_loop',
    'L9143': 'dragon_palette_store',
    'L914B': 'dragon_palette_fade_2',
    'L9155': 'dragon_palette_store_2',
    'L9164': 'dragon_fade_rts',

    # =========================================================================
    # Dragon Boss Movement & Scroll ($9165-$9207)
    # =========================================================================
    'L9165': 'dragon_update_position',
    'L9174': 'dragon_update_palette_and_hit',
    'L9199': 'dragon_check_hit_flash',
    'L91A4': 'dragon_apply_movement',
    'L91C9': 'dragon_clamp_y_upper',
    'L91D2': 'dragon_check_facing_dir',
    'L91EF': 'dragon_move_facing_left',

    # =========================================================================
    # Boss AI: Wily 2 — Guts Tank ($9220-$92DC)
    # =========================================================================
    'L9241': 'guts_tank_phase_rts',
    'L925D': 'guts_tank_copy_data_loop',
    'L926F': 'guts_tank_spawn_entity_loop',
    'L92AE': 'guts_tank_attr_update_loop',
    'L92CE': 'guts_tank_advance_phase',
    'L92DC': 'guts_tank_rts',
    'L92EB': 'guts_tank_y_pos_table',
    'L9307': 'guts_tank_x_pos_table',
    'L9323': 'guts_tank_phase_id_table',
    'L933F': 'guts_tank_spawn_data',

    # =========================================================================
    # Boss AI: Wily 2 — Guts Tank Palette ($935B-$9391)
    # =========================================================================
    'L9382': 'guts_tank_palette_flash',
    'L9391': 'guts_tank_palette_store',

    # =========================================================================
    # Boss AI: Wily 3 — Buebeam Trap ($93A0-$949E)
    # =========================================================================
    'L93E7': 'buebeam_advance_phase',
    'L93F0': 'buebeam_phase2_check',
    'L940D': 'buebeam_fill_column_loop',
    'L941F': 'buebeam_column_done',
    'L9430': 'buebeam_phase3_check',
    'L9452': 'buebeam_tile_copy_loop',
    'L9461': 'buebeam_tile_done',
    'L9472': 'buebeam_attr_update',
    'L948F': 'buebeam_attr_copy_loop',
    'L949E': 'buebeam_setup_complete',

    # =========================================================================
    # Boss AI: Wily 3 — Buebeam Battle ($94B0-$9509)
    # =========================================================================
    'L94D2': 'buebeam_spawn_turret',
    'L94F8': 'buebeam_advance_turret',
    'L9509': 'buebeam_jmp_movement',
    'L950D': 'buebeam_spawn_screen_table',
    'L9511': 'buebeam_turret_type_table',
    'L9515': 'buebeam_turret_y_table',
    'L9519': 'buebeam_turret_ai_table',

    # =========================================================================
    # Boss AI: Wily 3 — Buebeam Scroll ($9520-$9563)
    # =========================================================================
    'L952B': 'buebeam_set_facing',
    'L954D': 'buebeam_dec_phase_timer',
    'L9557': 'buebeam_clear_velocity',
    'L9563': 'buebeam_spawn_tick',
    'L956B': 'buebeam_spawn_setup',

    # =========================================================================
    # Boss AI: Wily 3 — Buebeam Projectile ($958D-$9613)
    # =========================================================================
    'L958D': 'buebeam_sprite_scan_loop',
    'L9599': 'buebeam_spawn_shot',
    'L95C6': 'buebeam_calc_aim_angle',
    'L95CF': 'buebeam_aim_shift',
    'L9613': 'buebeam_check_anim_state',
    'L961B': 'buebeam_palette_and_hit',
    'L9625': 'buebeam_death_fade',
    'L9648': 'buebeam_check_hit_flash',
    'L9653': 'buebeam_apply_facing',

    # =========================================================================
    # Boss AI: Wily 3 — Guts Tank ($9660-$96B7)
    # =========================================================================
    'L9668': 'gutsdozer_ai_table_hi',
    'L968B': 'gutsdozer_spawn_part_loop',
    'L96AD': 'gutsdozer_part_x_table',
    'L96B2': 'gutsdozer_part_y_table',
    'L96B7': 'gutsdozer_part_flags_table',

    # =========================================================================
    # Boss AI: Wily 4 — Boobeam Trap ($96C0-$97F8)
    # =========================================================================
    'L96F6': 'boobeam_fill_palette_loop',
    'L971E': 'boobeam_advance_phase',
    'L9730': 'boobeam_phase2_check',
    'L973E': 'boobeam_phase2_done',
    'L974B': 'boobeam_phase3_entry',
    'L9755': 'boobeam_palette_anim_check',
    'L9774': 'boobeam_health_check',
    'L979A': 'boobeam_health_rts',
    'L979B': 'boobeam_palette_blend',
    'L979D': 'boobeam_palette_blend_loop',
    'L97AC': 'boobeam_palette_add',
    'L97B6': 'boobeam_palette_store',
    'L97B9': 'boobeam_palette_loop_end',
    'L97C0': 'boobeam_target_palette',
    'L97D4': 'boobeam_column_fill',
    'L97E7': 'boobeam_column_fill_loop',
    'L97F8': 'boobeam_tile_row_copy',
    'L97FA': 'boobeam_tile_row_loop',

    # =========================================================================
    # Boss AI: Wily 5 — Wily Machine ($9810-$9A88)
    # =========================================================================
    'L981F': 'wily_machine_apply_facing',
    'L989C': 'wily_machine_store_facing',
    'L991C': 'wily_machine_phase_check',
    'L992D': 'wily_machine_phase1_check',
    'L9939': 'wily_machine_phase2',
    'L9955': 'wily_machine_tile_copy_loop',
    'L9967': 'wily_machine_health_check',
    'L996F': 'wily_machine_advance_phase',
    'L998E': 'wily_machine_clear_flags',
    'L999B': 'wily_machine_scroll_rts',
    'L99BA': 'wily_machine_rng_spawn',
    'L99E4': 'wily_machine_inc_timer',
    'L99ED': 'wily_machine_palette_reset',
    'L99F1': 'wily_machine_palette_loop',
    'L9A10': 'wily_machine_hit_check',
    'L9A27': 'wily_machine_invincible_check',
    'L9A2D': 'wily_machine_set_invincible',
    'L9A35': 'wily_machine_collision_test',
    'L9A56': 'wily_machine_death_explosion',
    'L9A79': 'wily_machine_data_byte',
    'L9A7A': 'wily_machine_death_jmp',
    'L9A7D': 'wily_machine_check_flash',
    'L9A88': 'wily_machine_jmp_movement',

    # =========================================================================
    # Boss AI: Wily 6 — Alien ($9B00-$9FBC)
    # =========================================================================
    'L9AB9': 'wily_machine_proj_timing_data',
    'L9B35': 'alien_jmp_dispatch',
    'L9B7C': 'alien_descent_rts',
    'L9B7D': 'alien_dec_timer',
    'L9B83': 'alien_palette_copy',
    'L9B94': 'alien_palette_rts',
    'L9B95': 'alien_phase2_check',
    'L9B9A': 'alien_phase2_compare',
    'L9BAD': 'alien_palette_threshold',
    'L9BB8': 'alien_palette_anim_range',
    'L9BBA': 'alien_palette_copy_loop',
    'L9BD4': 'alien_palette_inc_rts',
    'L9BD5': 'alien_movement_update',
    'L9BED': 'alien_health_check',
    'L9C12': 'alien_spawn_part_loop',
    'L9C1B': 'alien_part_setup_loop',
    'L9C36': 'alien_part_y_table',
    'L9C43': 'alien_part_x_flags_table',
    'L9C50': 'alien_palette_table',
    'L9C67': 'alien_palette_block_2',
    'L9C88': 'alien_facing_store',
    'L9C8A': 'alien_palette_data_byte',
    'L9CB7': 'alien_frame_update',
    'L9CB8': 'alien_move_y_sub_table',
    'L9CC0': 'alien_move_y_hi_table',
    'L9CC8': 'alien_move_x_sub_table',
    'L9CD0': 'alien_move_x_hi_table',
    'L9CE3': 'alien_movement_pattern',
    'L9D0B': 'alien_facing_store_2',
    'L9D38': 'alien_phase_dispatch',
    'L9D46': 'alien_palette_flash_tick',
    'L9D51': 'alien_palette_set_colors',
    'L9D5D': 'alien_palette_alt_color',
    'L9D5E': 'alien_palette_fill_loop',
    'L9DAC': 'alien_scroll_update',
    'L9DC7': 'alien_scroll_setup_entities',
    'L9DDA': 'alien_load_palette_loop',
    'L9E30': 'alien_stage_palette',
    'L9E77': 'alien_sprite_flash_store',
    'L9E7B': 'alien_fade_palette_data',
    'L9EBA': 'alien_aim_rts',
    'L9EBB': 'alien_deactivate_sprites',
    'L9EDE': 'alien_deactivate_loop',
    'L9EEF': 'alien_vel_y_data',
    'L9EF1': 'alien_vel_y_hi_data',
    'L9F0C': 'alien_palette_flash_store',
    'L9F28': 'alien_fade_palette_loop',
    'L9F35': 'alien_advance_phase',
    'L9F7A': 'alien_facing_update',
    'L9FBC': 'alien_phase_rts',
    'L9FC0': 'alien_phase_ptr_lo',
    'L9FC8': 'alien_phase_ptr_hi_table',
    'L9FCB': 'alien_phase_dispatch_hi',

    # =========================================================================
    # Wily Fortress Enemy Fallback AI ($9FD3-$A0FF)
    # =========================================================================
    'L9FE8': 'fortress_enemy_no_boss',
    'L9FF7': 'fortress_spawn_check_odd',
    'LA004': 'fortress_spawn_entity_loop',
    'LA037': 'fortress_inc_spawn_timer',
    'LA08A': 'fortress_spawn_rts',
    'LA08B': 'fortress_post_defeat',
    'LA099': 'fortress_defeat_phase_2',
    'LA0A9': 'fortress_defeat_phase_3',
    'LA0BA': 'fortress_defeat_check_timer',
    'LA0DC': 'fortress_defeat_spawn_entity',
    'LA0F6': 'fortress_defeat_dec_timer',
    'LA0FF': 'fortress_defeat_done',
    'LA100': 'fortress_boss_ptr_lo',
    'LA106': 'fortress_boss_ptr_hi',

    # =========================================================================
    # Common Routines: Sound & Animation ($A10C-$A14F)
    # =========================================================================
    'LA10C': 'play_sound_and_reset_anim',
    'LA118': 'boss_health_bar_tick',
    'LA12D': 'boss_health_bar_rts',
    'LA12E': 'boss_flip_and_check_wall',
    'LA146': 'boss_check_weapon_hit',
    'LA14F': 'boss_apply_movement_physics',
    'LA154': 'boss_movement_physics_inner',

    # =========================================================================
    # Boss Movement Physics ($A154-$A207)
    # =========================================================================
    'LA173': 'boss_clamp_y_position',
    'LA18B': 'boss_check_facing_right',
    'LA1C1': 'boss_clamp_x_left',
    'LA1CD': 'boss_move_facing_right',
    'LA1FD': 'boss_clamp_x_right',
    'LA207': 'boss_movement_done',

    # =========================================================================
    # Player-Boss Distance Calc ($A209-$A22C)
    # =========================================================================
    'LA209': 'calc_player_boss_distance',
    'LA214': 'calc_distance_data_byte',
    'LA22C': 'calc_distance_done',

    # =========================================================================
    # Entity Collision Check ($A22D-$A247)
    # =========================================================================
    'LA22D': 'find_entity_by_type',
    'LA233': 'find_entity_scan_loop',
    'LA23D': 'find_entity_check_active',
    'LA247': 'find_entity_found',

    # =========================================================================
    # Floor Collision Check ($A249-$A2D2)
    # =========================================================================
    'LA249': 'boss_floor_collision_check',
    'LA25C': 'boss_floor_check_above',
    'LA262': 'boss_floor_store_y',
    'LA2AA': 'boss_floor_snap_down',
    'LA2B8': 'boss_floor_store_y_pos',
    'LA2D1': 'boss_floor_no_snap_rts',
    'LA2D2': 'boss_floor_rts',

    # =========================================================================
    # Wall Collision Check ($A2D4-$A349)
    # =========================================================================
    'LA2D4': 'boss_wall_collision_check',
    'LA2F5': 'boss_wall_check_left',
    'LA302': 'boss_wall_store_page',
    'LA32D': 'boss_wall_snap_left',
    'LA345': 'boss_wall_no_snap',
    'LA349': 'tile_solidity_table',

    # =========================================================================
    # Entity Spawn Helper ($A352-$A389)
    # =========================================================================
    'LA352': 'spawn_entity_from_boss',
    'LA359': 'spawn_entity_init_type',
    'LA389': 'spawn_entity_fail',

    # =========================================================================
    # Velocity Calc Toward Player ($A38C-$A450)
    # =========================================================================
    'LA38C': 'calc_velocity_toward_player',
    'LA3A3': 'calc_velocity_set_facing',
    'LA3C0': 'velocity_calc_y_major',
    'LA401': 'velocity_calc_x_major',
    'LA439': 'velocity_calc_negate_y',
    'LA450': 'velocity_calc_done',

    # =========================================================================
    # Boss Property Tables ($A451-$A51F)
    # =========================================================================
    'LA4F5': 'boss_x_velocity_table',
    'LA4F7': 'boss_x_vel_data',
    'LA511': 'boss_y_vel_sub_table',
    'LA51F': 'boss_y_vel_hi_table',

    # =========================================================================
    # Player-Boss Proximity Check ($A52D-$A59C)
    # =========================================================================
    'LA54A': 'proximity_calc_x_dist',
    'LA55F': 'proximity_check_y_dist',
    'LA578': 'proximity_boss_defeated',
    'LA582': 'proximity_flip_facing',
    'LA59C': 'proximity_check_rts',

    # =========================================================================
    # Weapon-Boss Collision ($A59D-$A658)
    # =========================================================================
    'LA59D': 'weapon_boss_collision_check',
    'LA5A6': 'weapon_boss_check_slot',
    'LA5C7': 'weapon_boss_check_x_range',
    'LA5D9': 'weapon_boss_check_y_range',
    'LA5DE': 'weapon_boss_next_slot',
    'LA5EC': 'weapon_boss_no_hit',
    'LA5EE': 'weapon_boss_hit_dispatch',

    # =========================================================================
    # Weapon Damage: Buster ($A600-$A658)
    # =========================================================================
    'LA61B': 'buster_apply_damage',
    'LA636': 'buster_boss_killed',
    'LA63D': 'buster_deflect',
    'LA658': 'buster_deflect_done',

    # =========================================================================
    # Weapon Damage: Metal Blade ($A660-$A6CC)
    # =========================================================================
    'LA67F': 'metal_blade_triple_damage',
    'LA68A': 'metal_blade_base_damage',
    'LA68D': 'metal_blade_store_damage',
    'LA696': 'metal_blade_apply',
    'LA6B1': 'metal_blade_killed',
    'LA6B8': 'metal_blade_deflect',
    'LA6C7': 'metal_blade_clear_hit',
    'LA6CC': 'metal_blade_done',

    # =========================================================================
    # Weapon Damage: Air Shooter ($A6CE-$A782)
    # =========================================================================
    'LA6FE': 'air_shooter_killed',
    'LA755': 'air_shooter_killed_2',
    'LA780': 'air_shooter_done',
    'LA782': 'air_shooter_clear_hit',

    # =========================================================================
    # Weapon Damage: Leaf Shield ($A784-$A7C0)
    # =========================================================================
    'LA79E': 'leaf_shield_apply',
    'LA7B9': 'leaf_shield_killed',
    'LA7C0': 'leaf_shield_deflect',

    # =========================================================================
    # Weapon Damage: Crash Bomber ($A7E0-$A84D)
    # =========================================================================
    'LA7F5': 'crash_bomber_apply',
    'LA810': 'crash_bomber_killed',
    'LA817': 'crash_bomber_deflect',
    'LA849': 'crash_bomber_restore_x',
    'LA84D': 'crash_bomber_clear_hit',

    # =========================================================================
    # Weapon Damage: Quick Boomerang ($A855-$A8B4)
    # =========================================================================
    'LA869': 'quick_boomerang_apply',
    'LA884': 'quick_boomerang_killed',
    'LA88B': 'quick_boomerang_deflect',
    'LA8B4': 'quick_boomerang_done',

    # =========================================================================
    # Weapon Damage: Atomic Fire ($A8B6-$A914)
    # =========================================================================
    'LA8E6': 'atomic_fire_killed',
    'LA912': 'atomic_fire_done',
    'LA914': 'atomic_fire_clear_hit',

    # =========================================================================
    # Weapon Damage: Common Kill / Invincible ($A91B-$A92F)
    # =========================================================================
    'LA91B': 'weapon_force_kill_boss',
    'LA929': 'weapon_difficulty_scale',
    'LA92F': 'weapon_difficulty_rts',

    # =========================================================================
    # Weapon Damage Tables ($A930-$A9B2)
    # =========================================================================
    'LA930': 'weapon_handler_ptr_lo',
    'LA939': 'weapon_handler_ptr_hi',
    'LA942': 'weapon_base_damage_table',
    'LA950': 'weapon_metal_damage_table',
    'LA97A': 'weapon_leaf_damage_table',
    'LA996': 'weapon_quick_damage_table',
    'LA9B2': 'boss_contact_damage_table',

    # =========================================================================
    # Boss Intro: Buebeam Nametable Data ($A9C0-$AA91+)
    # =========================================================================
    'LA9C0': 'buebeam_nt_addr_hi_table',
    'LA9CB': 'buebeam_nt_addr_lo_table',
    'LA9D6': 'buebeam_nt_length_table',
    'LA9E1': 'buebeam_nt_tile_data',
    'LAA91': 'buebeam_attr_data',

    # =========================================================================
    # CHR Tile Data ($B4BE-$BFFF)
    # These labels are in CHR/graphics data regions; keep them short.
    # =========================================================================
    'LB4BE': 'chr_data_B4BE',
    'LB805': 'chr_data_B805',
    'LB88B': 'chr_data_B88B',
    'LBA87': 'chr_data_BA87',
    'LBABD': 'chr_data_BABD',
    'LBBBA': 'chr_data_BBBA',
    'LBDCA': 'chr_data_BDCA',
    'LBEF1': 'chr_data_BEF1',
    'LBF01': 'chr_data_BF01',
    'LBFBE': 'chr_data_BFBE',
}

# =============================================================================
# Combine all renames
# =============================================================================
ALL_RENAMES = {}
ALL_RENAMES.update(EXTERNAL_RENAMES)
ALL_RENAMES.update(INTERNAL_RENAMES)

def main():
    if not os.path.isfile(ASM_FILE):
        print(f"ERROR: {ASM_FILE} not found", file=sys.stderr)
        sys.exit(1)

    with open(ASM_FILE, 'r') as f:
        content = f.read()

    count = 0
    skipped = 0

    for old_label, new_label in sorted(ALL_RENAMES.items()):
        # Use word-boundary matching to avoid partial matches
        pattern = re.compile(r'\b' + re.escape(old_label) + r'\b')

        matches = pattern.findall(content)
        if matches:
            content = pattern.sub(new_label, content)
            count += 1
        else:
            skipped += 1

    with open(ASM_FILE, 'w') as f:
        f.write(content)

    print(f"Renamed {count} labels ({skipped} not found in source)")

    # Count remaining LXXXX labels
    remaining = set(re.findall(r'\bL[0-9A-Fa-f]{4}\b', content))
    # Filter to only ones that look like code addresses ($8000-$BFFF or $C000-$FFFF)
    code_remaining = set()
    for label in remaining:
        addr = int(label[1:], 16)
        if 0x8000 <= addr <= 0xBFFE or 0xC000 <= addr <= 0xFFFE:
            code_remaining.add(label)
    if code_remaining:
        print(f"WARNING: {len(code_remaining)} LXXXX code labels still unrenamed:")
        for label in sorted(code_remaining)[:50]:
            print(f"  {label}")
    else:
        print("All code labels renamed successfully!")


if __name__ == '__main__':
    main()
