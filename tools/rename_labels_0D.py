#!/usr/bin/env python3
"""
Rename auto-generated LXXXX labels in bank0D_stage_engine.asm to descriptive names.

This script replaces all occurrences of each label (both definitions like
"L802F:" and references like "jsr L802F") with human-readable names based
on the code's function in the Mega Man 2 NES ROM.

Bank $0D is the stage engine bank, containing stage initialization, main
stage loop, player rendering/collision, OAM sprite management, entity
update/physics, stage select/weapon get screens, credits, and ending
sequences.
"""

import re
import sys
import os

ASM_FILE = os.path.join(os.path.dirname(__file__), '..', 'src', 'bank0D_stage_engine.asm')

# =============================================================================
# External label renames: LXXXX := $XXXX references to bank $0F routines
# These are addresses in the fixed bank that bank $0D calls.
# =============================================================================
EXTERNAL_RENAMES = {
    # Fixed bank routines/tables (addresses in $C000-$FFFF range)
    'LC05D': 'banked_entry',              # $C05D — banked code entry point
    'LC0AB': 'wait_for_vblank_0D',        # $C0AB — wait VBLANK (returns to bank $0D)
    'LC628': 'ppu_fill_from_ptr',         # $C628 — fill PPU VRAM from pointer
    'LC644': 'chr_ram_bank_load',         # $C644 — load CHR bank data to CHR-RAM
    'LC70C': 'scroll_column_prep',        # $C70C — prepare scroll column data
    'LC723': 'ppu_set_scroll_state',      # $C723 — set PPU scroll registers
    'LC747': 'ppu_column_fill',           # $C747 — fill a PPU nametable column
    'LC760': 'metatile_render_column',    # $C760 — render metatile column to buffer
    'LC84E': 'divide_8bit',              # $C84E — 8-bit unsigned division
    'LC8B1': 'attr_table_write',          # $C8B1 — write attribute table entry
    'LCA0B': 'metatile_column_render',    # $CA0B — render metatile column to PPU
    'LCC6C': 'clear_oam_buffer_fixed',     # $CC6C — fill OAM with $F8 (fixed bank; local one exists at $8473)

    # Fixed bank routines ($D000+ range)
    'LD001': 'fixed_sprite_data_D001',    # $D001 — sprite data reference
    'LD624': 'ending_player_render',      # $D624 — ending/credits player render
    'LD627': 'ending_player_anim',        # $D627 — ending/credits player animation
    'LD637': 'ending_scroll_update',      # $D637 — ending scroll/camera update
    'LD642': 'ending_init_walk',          # $D642 — ending init walk sequence
    'LD64D': 'ending_walk_step',          # $D64D — ending walk per-frame step

    # Non-ROM / data-in-other-banks address references
    'L0010': 'addr_0010',
    'L0320': 'addr_0320',
    'L0508': 'addr_0508',
    'L0901': 'addr_0901',
    'L0D20': 'addr_0D20',
    'L0F06': 'addr_0F06',
    'L1003': 'addr_1003',
    'L1120': 'addr_1120',
    'L1121': 'addr_1121',
    'L1EA4': 'addr_1EA4',
    'L2008': 'addr_2008',
    'L2017': 'addr_2017',
    'L2020': 'addr_2020',
    'L2060': 'addr_2060',
    'L3800': 'addr_3800',
    'L5000': 'addr_5000',
    'L5E10': 'addr_5E10',
    'L72A0': 'addr_72A0',
    'L7484': 'addr_7484',
}

# =============================================================================
# Internal label renames: LXXXX labels within bank $0D ($8000-$BFFF)
# Organized by functional region
# =============================================================================
INTERNAL_RENAMES = {
    # =========================================================================
    # Stage select screen initialization ($8000-$80A6)
    # =========================================================================
    'L802F': 'stage_init_clear_loop',
    'L8043': 'stage_init_ppu_fill',
    'L8051': 'stage_init_ppu_byte',
    'L8061': 'stage_init_next_boss',
    'L8078': 'stage_init_oam_loop',
    'L8087': 'stage_init_oam_copy',
    'L8093': 'stage_init_oam_next',
    'L80BF': 'stage_loop_render',

    # =========================================================================
    # Stage select handler ($80C8-$811C)
    # =========================================================================
    'L80F5': 'stage_select_load_entity',

    # =========================================================================
    # Intro sequence — boss teleport / palette animation ($811D-$829A)
    # =========================================================================
    'L811D': 'intro_palette_blink_loop',
    'L8127': 'intro_load_palette',
    'L8149': 'intro_update_scroll_col',
    'L8170': 'intro_finish_palette',
    'L8181': 'intro_copy_weapon_palette',
    'L8192': 'intro_copy_stage_palette',
    'L81AE': 'intro_blank_frames',
    'L81CD': 'intro_player_drop_loop',
    'L81EE': 'intro_player_landed',
    'L8200': 'intro_weapon_flash_loop',
    'L8223': 'intro_weapon_flash_frame',
    'L8232': 'intro_weapon_show_hold',
    'L8236': 'intro_weapon_show_frame',
    'L825F': 'intro_health_fill_loop',
    'L8276': 'intro_health_fill_frame',
    'L828A': 'intro_health_hold_frame',
    'L829A': 'intro_cleanup',

    # =========================================================================
    # Palette loading ($829F-$82C9)
    # =========================================================================
    'L82A0': 'load_palette_byte',
    'L82AB': 'check_stage_transition',
    'L82C9': 'check_stage_transition_rts',
    'L82CA': 'stage_transition_table',

    # =========================================================================
    # Player rendering & collision ($8310-$8465)
    # =========================================================================
    'L8326': 'collision_box_loop',
    'L834D': 'collision_hide_sprites',
    'L8351': 'collision_hide_loop',
    'L8364': 'render_sprite_layer_loop',
    'L8379': 'render_sprite_load_data',
    'L83A3': 'sprite_count_table',
    'L83A6': 'sprite_xvel_sub_table',
    'L83A9': 'sprite_xvel_table',
    'L83C0': 'write_oam_attr_byte',
    'L83F5': 'projectile_anim_update',
    'L8413': 'projectile_oam_loop',
    'L8456': 'nametable_fill_loop',
    'L845B': 'nametable_fill_byte',
    'L8465': 'clear_projectile_positions',
    'L8469': 'clear_proj_pos_loop',
    'L8477': 'clear_oam_fill_loop',

    # =========================================================================
    # Stage palette data ($84A0-$8540)
    # =========================================================================
    'L84D9': 'weapon_palette_base',
    'L84E1': 'stage_palette_per_boss',
    'L8521': 'weapon_flash_tile_lo',
    'L8522': 'weapon_flash_tile_hi',
    'L852D': 'data_852D',
    'L8531': 'intro_ppu_addr_hi',
    'L8537': 'data_8537',
    'L8539': 'intro_ppu_addr_lo',
    'L853C': 'data_853C',
    'L8541': 'boss_portrait_oam_data',

    # =========================================================================
    # Sprite / OAM data tables ($8590-$86FF)
    # =========================================================================
    'L859C': 'data_859C',
    'L85DA': 'data_85DA',
    'L85DC': 'data_85DC',
    'L85EA': 'data_85EA',
    'L85EC': 'data_85EC',
    'L85FD': 'boss_oam_offset_table',
    'L8605': 'boss_oam_size_table',
    'L861B': 'data_861B',
    'L8658': 'data_8658',
    'L865E': 'data_865E',
    'L865F': 'stage_select_index_table',
    'L866E': 'data_866E',
    'L8671': 'stage_entity_x_table',
    'L8690': 'data_8690',
    'L86A1': 'stage_entity_bank_table',
    'L86D1': 'boss_bitmask_table',
    'L86D9': 'intro_health_tile_data',
    'L86E0': 'data_86E0',
    'L86F7': 'data_86F7',
    'L86FC': 'data_86FC',

    # =========================================================================
    # Player sprite data / animation tables ($8729-$87FF)
    # =========================================================================
    'L8729': 'player_sprite_y_table',
    'L872A': 'player_sprite_x_table',
    'L8731': 'data_8731',
    'L8757': 'data_8757',
    'L875C': 'data_875C',
    'L8769': 'data_8769',
    'L877C': 'data_877C',
    'L8781': 'projectile_anim_base_idx',
    'L8789': 'projectile_anim_max_frame',
    'L878F': 'data_878F',
    'L8791': 'projectile_frame_duration',
    'L8799': 'projectile_frame_index',
    'L879F': 'data_879F',
    'L87AA': 'data_87AA',
    'L87ED': 'projectile_sprite_ptr_lo',
    'L8816': 'projectile_sprite_ptr_hi',

    # =========================================================================
    # Sprite definition data (large block of OAM data $8831-$90FF)
    # =========================================================================
    'L8831': 'sprite_def_data_8831',
    'L88EE': 'sprite_def_data_88EE',
    'L894A': 'sprite_def_data_894A',
    'L8ABD': 'sprite_def_data_8ABD',
    'L8B36': 'sprite_def_data_8B36',
    'L8B54': 'sprite_def_data_8B54',
    'L8B9F': 'sprite_def_data_8B9F',
    'L8C7E': 'sprite_def_data_8C7E',
    'L8C86': 'sprite_def_data_8C86',
    'L8CAE': 'sprite_def_data_8CAE',
    'L8CB8': 'sprite_def_data_8CB8',
    'L8D16': 'sprite_def_data_8D16',
    'L8D8D': 'sprite_def_data_8D8D',
    'L8D98': 'sprite_def_data_8D98',
    'L8DAD': 'sprite_def_data_8DAD',
    'L8E81': 'sprite_def_data_8E81',
    'L8E8E': 'sprite_def_data_8E8E',
    'L8EA4': 'sprite_def_data_8EA4',
    'L8EBD': 'sprite_def_data_8EBD',
    'L8EDE': 'sprite_def_data_8EDE',
    'L8EF2': 'sprite_def_data_8EF2',
    'L8F73': 'sprite_def_data_8F73',
    'L8F8F': 'sprite_def_data_8F8F',
    'L8FC5': 'sprite_def_data_8FC5',
    'L9006': 'sprite_def_data_9006',
    'L9034': 'sprite_def_data_9034',
    'L9047': 'sprite_def_data_9047',
    'L9048': 'sprite_def_data_9048',
    'L9055': 'sprite_def_data_9055',
    'L9060': 'sprite_def_data_9060',
    'L9094': 'sprite_def_data_9094',

    # =========================================================================
    # Weapon select screen ($90E9-$93FF)
    # =========================================================================
    'L910B': 'wselect_save_palette_loop',
    'L9135': 'wselect_clear_palette_loop',
    'L913D': 'wselect_check_boss_stage',
    'L9155': 'wselect_check_wily_10',
    'L9163': 'wselect_wily10_palette_loop',
    'L9172': 'wselect_calc_scroll_pos',
    'L9185': 'wselect_column_loop',
    'L91A8': 'wselect_copy_tiles',
    'L91ED': 'wselect_set_weapon_index',
    'L91EF': 'wselect_input_loop',
    'L920B': 'wselect_check_start',
    'L9214': 'wselect_check_dpad',
    'L9236': 'wselect_dpad_pressed',
    'L923D': 'wselect_sound_and_move',
    'L924A': 'wselect_move_right',
    'L9254': 'wselect_check_valid',
    'L9261': 'wselect_move_left',
    'L9267': 'wselect_check_valid_left',
    'L9274': 'wselect_clear_repeat',
    'L9278': 'wselect_update_and_vblank',
    'L9281': 'wselect_start_pressed',
    'L928E': 'wselect_check_etank',
    'L9298': 'wselect_etank_fill_loop',
    'L92AD': 'wselect_etank_frame',
    'L92B6': 'wselect_weapon_selected',
    'L92C9': 'wselect_store_weapon',
    'L92D3': 'wselect_render_column',
    'L9313': 'wselect_render_weapon_col',
    'L9317': 'wselect_render_default_col',
    'L931B': 'wselect_render_col_call',
    'L9346': 'wselect_wily10_restore',
    'L9358': 'wselect_restore_palette',
    'L935A': 'wselect_restore_pal_loop',
    'L9393': 'wselect_wily10_pal_data',

    # =========================================================================
    # Weapon select OAM rendering ($9396-$9520)
    # =========================================================================
    'L9396': 'wselect_render_oam',
    'L93A4': 'wselect_load_header_oam',
    'L93D3': 'wselect_build_boss_icons',
    'L93DB': 'wselect_icon_oam_entry',
    'L93E7': 'wselect_icon_tile',
    'L940D': 'wselect_load_labels_p1',
    'L942E': 'wselect_draw_hp_bar_p1',
    'L9439': 'wselect_hp_bar_next_p1',
    'L944F': 'wselect_draw_etank_loop',
    'L9472': 'wselect_jump_to_cursor',
    'L9475': 'wselect_page2_labels',
    'L9477': 'wselect_load_labels_p2',
    'L948D': 'wselect_draw_hp_bar_p2',
    'L9498': 'wselect_hp_bar_next_p2',
    'L94DD': 'wselect_cursor_blink',
    'L94E7': 'wselect_cursor_offset',
    'L94F9': 'wselect_cursor_not_first',
    'L9507': 'wselect_adjust_positions',
    'L9509': 'wselect_adjust_x_loop',

    # =========================================================================
    # HP bar rendering helpers ($9519-$956F)
    # =========================================================================
    'L9529': 'hp_bar_draw_weapon',
    'L952B': 'hp_bar_draw_start',
    'L952F': 'hp_bar_draw_entry',
    'L9549': 'hp_bar_store_remaining',
    'L954D': 'hp_bar_write_oam',
    'L9565': 'hp_bar_x_positions',
    'L956C': 'hp_bar_empty_tiles',

    # =========================================================================
    # Weapon select data tables ($9570-$966F)
    # =========================================================================
    'L9570': 'wselect_column_type',
    'L957F': 'wselect_column_offset',
    'L958E': 'wselect_tile_data',
    'L961E': 'wselect_attr_per_stage',
    'L962C': 'wselect_header_oam',
    'L9640': 'wselect_icon_tile_ids',
    'L964C': 'wselect_label_oam_data',
    'L9664': 'wselect_weapon_pal_idx',
    'L9670': 'weapon_bitmask_table',

    # =========================================================================
    # Stage complete / boss get screen ($9678-$99C6)
    # =========================================================================
    'L9686': 'boss_get_init_ppu',
    'L969D': 'boss_get_fill_nt_loop',
    'L96A2': 'boss_get_fill_tile',
    'L96C2': 'boss_get_load_palette',
    'L96DA': 'boss_get_normal_init',
    'L9715': 'boss_get_walk_loop',
    'L973D': 'boss_get_walk_frame',
    'L9755': 'boss_get_walk_stop',
    'L9768': 'boss_get_idle_loop',
    'L9796': 'boss_get_jump_up_loop',
    'L97B8': 'boss_get_shimmer_loop',
    'L97D6': 'boss_get_shimmer_frame',
    'L97E7': 'boss_get_land_loop',
    'L9820': 'boss_get_bounce_main',
    'L982F': 'boss_get_bounce_down',
    'L985B': 'boss_get_bounce_up_entry',
    'L9865': 'boss_get_bounce_up',
    'L989C': 'boss_get_bounce_check',
    'L989E': 'boss_get_bounce_reverse',
    'L98BF': 'boss_get_bounce_render',
    'L98DC': 'boss_get_apply_gravity',
    'L98EE': 'boss_get_fall_init',
    'L98F3': 'boss_get_fall_loop',
    'L9931': 'boss_get_fall_done',
    'L993B': 'boss_get_wait_loop',
    'L9945': 'boss_get_flash_palette',
    'L9947': 'boss_get_flash_pal_load',
    'L9954': 'boss_get_flash_loop',
    'L995E': 'boss_get_flash_set_color',
    'L9973': 'boss_get_title_scroll_start',
    'L9981': 'boss_get_title_scroll_loop',
    'L999A': 'boss_get_title_frame',
    'L99A7': 'boss_get_title_hold_start',
    'L99AB': 'boss_get_title_hold_frame',

    # =========================================================================
    # Entity update / physics ($99C8-$9A62)
    # =========================================================================
    'L99E4': 'update_anim_frame_rts',
    'L99EC': 'update_all_entity_inner',
    'L9A01': 'gravity_accelerate',
    'L9A16': 'gravity_store',
    'L9A1C': 'gravity_rts',
    'L9A1D': 'render_stars_overlay',
    'L9A2F': 'stars_overlay_with_offset',
    'L9A33': 'stars_overlay_setup',
    'L9A39': 'stars_overlay_loop',
    'L9A5A': 'stars_overlay_next',

    # =========================================================================
    # Boss get title display ($9A63-$9AC7)
    # =========================================================================
    'L9A63': 'boss_get_title_render',
    'L9A68': 'boss_get_title_oam_load',
    'L9A77': 'boss_get_title_letter_loop',
    'L9AA1': 'boss_get_title_markers',
    'L9AC7': 'boss_get_title_rts',

    # =========================================================================
    # Entity update handler ($9AC8-$9B26)
    # =========================================================================
    'L9AED': 'entity_oam_loop',
    'L9B16': 'entity_oam_store_x',
    'L9B1F': 'entity_oam_next_sprite',

    # =========================================================================
    # Wily stage intro ($9B27-$9B82)
    # =========================================================================
    'L9B27': 'wily_intro_init',
    'L9B2B': 'wily_intro_clear_pal',
    'L9B43': 'wily_intro_fade_loop',
    'L9B4F': 'wily_intro_load_pal',
    'L9B61': 'wily_intro_vblank',
    'L9B67': 'wily_intro_sound',
    'L9B70': 'wily_intro_wait_outer',
    'L9B74': 'wily_intro_wait_inner',

    # =========================================================================
    # Data tables for boss get / wily intro ($9B83-$9BE9)
    # =========================================================================
    'L9B83': 'wily_nametable_fill_tiles',
    'L9B93': 'boss_get_palette_data',
    'L9B9A': 'boss_get_palette_data_2',
    'L9BB3': 'boss_get_flash_palette_data',
    'L9BD3': 'entity_sprite_ptr_lo',
    'L9BDE': 'entity_sprite_ptr_hi',

    # =========================================================================
    # Sprite definition data (entity OAM) ($9BEA-$9D6E)
    # =========================================================================
    'L9D19': 'sprite_data_9D19',

    # =========================================================================
    # Stars / bounce data ($9D6F-$9DAF)
    # =========================================================================
    'L9D6F': 'star_y_offset',
    'L9D70': 'star_tile_1',
    'L9D71': 'star_attr',
    'L9D72': 'star_x_offset',
    'L9D7D': 'data_9D7D',
    'L9D83': 'bounce_entity_type',
    'L9D88': 'bounce_accel_sub',
    'L9D8A': 'bounce_accel_whole',
    'L9D8C': 'boss_get_header_oam',
    'L9D9C': 'data_9D9C',
    'L9DA8': 'boss_get_scroll_start',
    'L9DA9': 'boss_get_scroll_end',
    'L9DB7': 'boss_get_letter_oam',
    'L9E11': 'data_9E11',
    'L9E2D': 'data_9E2D',
    'L9E5D': 'data_9E5D',

    # =========================================================================
    # Wily fade palette data ($9E87-$9EE6)
    # =========================================================================
    'L9E87': 'wily_fade_palette_data',

    # =========================================================================
    # Credits / password / ending ($9EE7-$9FFF)
    # =========================================================================
    'L9F13': 'credits_ppu_write_loop',
    'L9F20': 'credits_clear_palette',
    'L9F2C': 'credits_load_tiles_outer',
    'L9F3E': 'credits_load_tiles_inner',
    'L9F60': 'credits_fade_outer',
    'L9F64': 'credits_fade_inner',
    'L9F78': 'credits_fade_next',
    'L9F9D': 'credits_scroll_right_loop',
    'L9FBE': 'credits_scroll_advance',
    'L9FE0': 'credits_clear_pal_2',
    'L9FF0': 'credits_clear_entities',

    # =========================================================================
    # Ending sequence ($A049-$A2C0)
    # =========================================================================
    'LA049': 'ending_fade_speed',
    'LA04B': 'ending_fade_loop',
    'LA057': 'ending_fade_pal_load',
    'LA069': 'ending_fade_frame',
    'LA078': 'ending_column_init',
    'LA083': 'ending_column_main',
    'LA089': 'ending_column_load',
    'LA0A0': 'ending_column_skip',
    'LA0A2': 'ending_column_second',
    'LA0B7': 'ending_text_fade_loop',
    'LA0CB': 'ending_text_frame',
    'LA0D7': 'ending_column_check',
    'LA0E5': 'ending_fall_accel',
    'LA0FB': 'ending_fall_check_col',
    'LA10D': 'ending_fall_decel_init',
    'LA117': 'ending_fall_decel_loop',
    'LA13A': 'ending_landing_init',
    'LA13C': 'ending_landing_pal_load',
    'LA159': 'ending_landing_scroll',
    'LA17C': 'ending_scroll_columns',
    'LA190': 'ending_scroll_col_loop',
    'LA1C5': 'ending_scroll_idle_loop',
    'LA1D7': 'ending_load_ground_pal',
    'LA1E0': 'ending_main_loop_init',
    'LA1EF': 'ending_main_loop',
    'LA200': 'ending_draw_cursor',
    'LA216': 'ending_cursor_y',
    'LA231': 'ending_timer_tick',
    'LA245': 'ending_skip_pressed',
    'LA24E': 'ending_teleport_loop',
    'LA25F': 'ending_teleport_dec',
    'LA263': 'ending_teleport_frame',
    'LA277': 'ending_fly_away',
    'LA296': 'ending_fly_render',
    'LA2A2': 'ending_fly_done',
    'LA2A9': 'ending_fly_wait',
    'LA2C1': 'ending_cursor_oam_data',
    'LA2C4': 'ending_cursor_y_table',

    # =========================================================================
    # Password / stage setup ($A2C6-$A350)
    # =========================================================================
    'LA2C6': 'password_screen_init',
    'LA2E7': 'password_load_tiles',
    'LA2F9': 'password_tile_inner',
    'LA311': 'password_grid_init',
    'LA319': 'password_cursor_loop',
    'LA31B': 'password_load_cursor_oam',
    'LA332': 'password_cursor_x_pos',
    'LA335': 'password_check_input',
    'LA34A': 'password_no_input',
    'LA350': 'password_start_pressed',

    # =========================================================================
    # Password entry / validation ($A357-$A519)
    # =========================================================================
    'LA357': 'password_enter_mode',
    'LA362': 'password_draw_grid_oam',
    'LA36F': 'password_clear_dots',
    'LA389': 'password_entry_loop',
    'LA3A7': 'password_dpad_pressed',
    'LA3BF': 'password_move_left',
    'LA3C5': 'password_check_up',
    'LA3D1': 'password_move_down',
    'LA3D4': 'password_store_position',
    'LA3DA': 'password_clear_repeat',
    'LA3DE': 'password_check_ab',
    'LA3E8': 'password_dot_data',
    'LA40C': 'password_render_grid',
    'LA415': 'password_all_dots_placed',
    'LA41F': 'password_find_difficulty',
    'LA429': 'password_store_difficulty',
    'LA438': 'password_decode_loop',
    'LA44E': 'password_decode_next',
    'LA455': 'password_decode_inc',
    'LA468': 'password_invalid',
    'LA471': 'password_invalid_wait',
    'LA48D': 'password_invalid_wait_2',
    'LA4AD': 'password_valid',
    'LA4D3': 'password_valid_wait',
    'LA4EF': 'password_show_beaten',
    'LA4FB': 'password_beaten_sprite',
    'LA4FD': 'password_beaten_loop',
    'LA507': 'password_beaten_check',
    'LA512': 'password_beaten_wait',
    'LA519': 'password_exit',

    # =========================================================================
    # PPU control helpers ($A51D-$A53B)
    # =========================================================================
    'LA51D': 'enable_nmi_and_rendering',
    'LA52D': 'disable_nmi_and_rendering',
    'LA53C': 'ppu_buffer_and_increment',

    # =========================================================================
    # Ending column load ($A553-$A5F4)
    # =========================================================================
    'LA553': 'ending_column_data_load',
    'LA557': 'ending_column_inner',
    'LA57C': 'ending_attr_or_column',
    'LA5A8': 'ending_nametable_column',
    'LA5B0': 'ending_column_calc_addr',
    'LA5E8': 'ending_column_copy_loop',

    # =========================================================================
    # Ending sprite animation ($A5F5-$A60E)
    # =========================================================================
    'LA5F5': 'ending_advance_anim',
    'LA60E': 'ending_anim_rts',

    # =========================================================================
    # Ending entity / sprite data loading ($A611-$A7AF)
    # =========================================================================
    'LA611': 'ending_load_star_oam',
    'LA61B': 'ending_update_entities',
    'LA61D': 'ending_entity_loop',
    'LA64D': 'ending_entity_next',
    'LA65E': 'ending_player_gravity',
    'LA682': 'ending_player2_gravity',
    'LA6A6': 'ending_gravity_accel',
    'LA6C0': 'ending_boss_fall',
    'LA6D3': 'ending_spawn_entity',
    'LA6D7': 'ending_find_empty_slot',
    'LA6E2': 'ending_init_entity',
    'LA6F7': 'ending_render_all_sprites',
    'LA700': 'ending_entity_render_loop',
    'LA71D': 'ending_render_entry',
    'LA721': 'ending_oam_write_loop',
    'LA737': 'ending_oam_tile_write',
    'LA74D': 'ending_oam_next',
    'LA757': 'ending_entity_render_next',
    'LA75F': 'ending_render_boss_sprite',
    'LA777': 'ending_boss_oam_loop',
    'LA792': 'ending_boss_oam_write',
    'LA7A5': 'ending_boss_oam_next',
    'LA7AF': 'ending_boss_sprite_rts',

    # =========================================================================
    # Credits skip / wily castle scroll ($A7B0-$A87D)
    # =========================================================================
    'LA7B0': 'credits_skip_init',
    'LA7C7': 'credits_skip_scroll_loop',
    'LA803': 'credits_skip_nt_outer',
    'LA805': 'credits_skip_nt_inner',
    'LA821': 'credits_skip_attr_load',
    'LA82C': 'credits_skip_pal_load',
    'LA837': 'credits_skip_pal2_load',
    'LA844': 'credits_skip_clear_ents',
    'LA87E': 'metatile_column_render_loop',
    'LA884': 'metatile_col_pair_render',

    # =========================================================================
    # Palette fade in/out ($A898-$A926)
    # =========================================================================
    'LA898': 'palette_fade_out',
    'LA89C': 'palette_fade_out_loop',
    'LA8A9': 'palette_fade_out_frame',
    'LA8AF': 'palette_fade_out_rts',
    'LA8B0': 'palette_fade_out_step',
    'LA8BF': 'palette_dec_range',
    'LA8C1': 'palette_dec_loop',
    'LA8CB': 'palette_dec_store',
    'LA8D4': 'palette_fade_in',
    'LA8D8': 'palette_fade_in_loop',
    'LA8E5': 'palette_fade_in_frame',
    'LA8EB': 'palette_fade_in_rts',
    'LA8EC': 'palette_fade_in_step',
    'LA8FF': 'palette_inc_range',
    'LA901': 'palette_inc_loop',
    'LA910': 'palette_inc_add',
    'LA91D': 'palette_inc_store',
    'LA920': 'palette_inc_next',

    # =========================================================================
    # Password grid rendering ($A927-$A9E9)
    # =========================================================================
    'LA927': 'password_render_sprites',
    'LA936': 'password_sprite_loop',
    'LA973': 'password_dot_check_loop',
    'LA97C': 'password_dot_visible',
    'LA97E': 'password_dot_write_oam',
    'LA98B': 'ppu_column_data_upload',
    'LA9A5': 'ppu_column_data_inner',
    'LA9B2': 'init_scroll_and_palette',
    'LA9BC': 'init_scroll_pal_loop',
    'LA9CC': 'scroll_right_until_wrap',
    'LA9E9': 'scroll_right_rts',
    'LA9EA': 'metatile_full_screen_render',
    'LA9F0': 'metatile_render_loop',

    # =========================================================================
    # Scroll left ($AA09-$AA24)
    # =========================================================================
    'LAA09': 'scroll_left_until_zero',
    'LAA24': 'scroll_left_rts',

    # =========================================================================
    # Password dot grid setup ($AA25-$AA4E)
    # =========================================================================
    'LAA25': 'password_init_dot_oam',
    'LAA29': 'password_dot_oam_loop',

    # =========================================================================
    # Data: fade palettes, OAM data ($AA4F-$AB22)
    # =========================================================================
    'LAA4F': 'ending_fade_pal_frames',
    'LAA8F': 'credits_skip_palette',
    'LAAAF': 'ending_black_palette',
    'LAABF': 'ending_ground_palette',
    'LAACF': 'ending_star_oam_positions',
    'LAAE3': 'entity_sprite_y_offset',
    'LAAE4': 'entity_sprite_tile_id',
    'LAAE5': 'entity_sprite_attr',
    'LAAE6': 'entity_sprite_x_offset',
    'LAAF2': 'data_AAF2',

    # =========================================================================
    # Entity sprite data ($AB23-$AD4D)
    # =========================================================================
    'LAB23': 'boss_sprite_def_ptr_lo',
    'LAB29': 'data_AB29',
    'LAB30': 'boss_sprite_def_ptr_hi',
    'LAB66': 'boss_sprite_data_AB66',
    'LAB70': 'boss_sprite_data_AB70',
    'LAB93': 'boss_sprite_data_AB93',
    'LAB9D': 'boss_sprite_data_AB9D',
    'LABC9': 'boss_sprite_data_ABC9',
    'LABCD': 'boss_sprite_data_ABCD',
    'LABFA': 'boss_sprite_data_ABFA',
    'LABFE': 'boss_sprite_data_ABFE',
    'LAC2A': 'boss_sprite_data_AC2A',
    'LAC34': 'boss_sprite_data_AC34',
    'LAC59': 'boss_sprite_data_AC59',
    'LAC82': 'boss_sprite_data_AC82',
    'LACAB': 'boss_sprite_data_ACAB',
    'LACD4': 'boss_sprite_data_ACD4',
    'LACE0': 'boss_sprite_data_ACE0',
    'LACFD': 'boss_sprite_data_ACFD',

    # =========================================================================
    # Credits text data ($AD4E-$AE96)
    # =========================================================================
    'LAD6F': 'credits_text_data',
    'LADE8': 'credits_text_data_2',
    'LAE54': 'credits_fade_brightness',
    'LAE73': 'credits_fade_data_2',
    'LAE7A': 'credits_fade_data_3',
    'LAE7B': 'ending_teleport_anim_table',
    'LAE91': 'data_AE91',
    'LAE95': 'credits_tile_layout_data',
    'LAE97': 'data_AE97',
    'LAE99': 'data_AE99',
    'LAE9B': 'data_AE9B',
    'LAE9D': 'data_AE9D',
    'LAE9F': 'data_AE9F',

    # =========================================================================
    # Scroll/palette init data ($AEF7-$AFFC)
    # =========================================================================
    'LAEF7': 'init_scroll_palette_data',
    'LAEF9': 'password_target_palette',
    'LAF39': 'password_ppu_layout_data',
    'LAF3A': 'password_ppu_layout_data_2',
    'LAF94': 'data_AF94',
    'LAFBD': 'ppu_column_table_index',
    'LAFC7': 'password_cursor_oam',
    'LAFCB': 'password_grid_oam_data',
    'LAFE8': 'data_AFE8',

    # =========================================================================
    # Password lookup tables ($AFFB-$B0D0)
    # =========================================================================
    'LAFFB': 'password_grid_y_table',
    'LB000': 'data_B000',
    'LB014': 'password_grid_x_table',
    'LB02D': 'cursor_move_right_table',
    'LB046': 'cursor_move_left_table',
    'LB053': 'data_B053',
    'LB055': 'data_B055',
    'LB05F': 'cursor_move_up_table',
    'LB06A': 'data_B06A',
    'LB078': 'cursor_move_down_table',
    'LB07A': 'data_B07A',
    'LB091': 'password_blink_colors',
    'LB099': 'password_sprite_offsets',
    'LB0A9': 'password_bit_mask_table',
    'LB0AB': 'data_B0AB',
    'LB0BD': 'password_byte_index_table',
    'LB0D1': 'password_beaten_oam_data',

    # =========================================================================
    # Ending credits nametable ($B101-$B223)
    # =========================================================================
    'LB12D': 'credits_game_over_text',
    'LB158': 'credits_ppu_upload',
    'LB15A': 'credits_init_scroll',
    'LB175': 'credits_select_loop_start',
    'LB17C': 'credits_select_input',
    'LB19B': 'credits_select_next',
    'LB1A7': 'credits_select_draw',
    'LB1A9': 'credits_select_oam_load',
    'LB1C0': 'credits_select_vblank',
    'LB1C6': 'credits_start_pressed',
    'LB1CF': 'credits_continue',
    'LB1D5': 'credits_exit',
    'LB1E0': 'game_over_text_data',
    'LB1E9': 'credits_cursor_oam',
    'LB1ED': 'credits_cursor_y_table',
    'LB1F0': 'credits_header_oam',
    'LB1F4': 'credits_boss_icon_oam',

    # =========================================================================
    # Password validation / continue screen ($B224-$B2F0)
    # =========================================================================
    'LB224': 'password_show_grid',
    'LB231': 'password_clear_dots_loop',
    'LB24C': 'password_set_dots_loop',
    'LB25B': 'password_set_dot_entry',
    'LB265': 'password_set_dot_next',
    'LB282': 'password_copy_grid_oam',
    'LB28D': 'password_copy_header_oam',
    'LB2A8': 'password_boss_icon_loop',
    'LB2B0': 'password_boss_icon_copy',
    'LB2BC': 'password_boss_icon_skip',
    'LB2C0': 'password_boss_icon_next',
    'LB2CC': 'password_blink_loop',
    'LB2D6': 'password_blink_store',
    'LB2E0': 'password_blink_check',

    # =========================================================================
    # Wily castle map attr data ($B2F1-$B6FF)
    # =========================================================================
    'LB2F1': 'wily_castle_attr_data',
    'LB2F2': 'wily_castle_attr_data_2',

    # =========================================================================
    # Ending walk / credits sequence ($B6F1-$B8F8)
    # =========================================================================
    'LB72D': 'ending_clear_pal_loop',
    'LB742': 'ending_wait_loop',
    'LB756': 'ending_scene_fade_loop',
    'LB76B': 'ending_scene_render',
    'LB774': 'ending_scene_next',
    'LB785': 'ending_scene_timer',
    'LB78B': 'ending_scene_check_type',
    'LB79B': 'ending_scene_scroll_pal',
    'LB7A1': 'ending_scene_check_stars',
    'LB7B5': 'ending_scene_frame',
    'LB7EB': 'ending_nt_clear_outer',
    'LB7ED': 'ending_nt_clear_inner',
    'LB828': 'ending_health_bar_loop',
    'LB841': 'ending_health_bar_frame',
    'LB855': 'ending_walk_main_init',
    'LB86C': 'ending_walk_frame_loop',
    'LB89B': 'ending_walk_next_column',
    'LB8D5': 'ending_final_walk_loop',
    'LB8E9': 'ending_wait_for_start',
    'LB8F9': 'ending_scene_sprite_render',
    'LB911': 'ending_scene_helmet_off',
    'LB91E': 'ending_scene_normal',
    'LB949': 'ending_scene_check_phase',
    'LB95B': 'ending_scene_anim_call',
    'LB95F': 'ending_scene_walk_render',
    'LB98D': 'ending_scene_anim_frame',
    'LB9BA': 'ending_scene_oam_write',
    'LB9BE': 'ending_scene_oam_loop',

    # =========================================================================
    # Ending palette / scroll helpers ($B9E0-$BA32)
    # =========================================================================
    'LB9E0': 'ending_set_sky_palette',
    'LB9EA': 'ending_sky_pal_index',
    'LB9EF': 'ending_sky_pal_copy',
    'LB9FF': 'ending_set_ground_palette',
    'LBA0B': 'ending_ground_pal_index',
    'LBA17': 'ending_ground_pal_copy',
    'LBA23': 'ending_ground_pal_rts',
    'LBA24': 'ppu_fill_column_with_tile',
    'LBA29': 'ppu_fill_col_loop',

    # =========================================================================
    # Ending data tables ($BA33-$BAE0)
    # =========================================================================
    'LBA33': 'ending_palette_per_scene',
    'LBA6F': 'ending_sky_color_table',
    'LBA7B': 'ending_scene_timer_lo',
    'LBA81': 'ending_scene_timer_hi',
    'LBA85': 'data_BA85',
    'LBA87': 'ending_sprite_y_table',
    'LBA9D': 'ending_sprite_x_table',
    'LBAB3': 'ending_sprite_tile_table',
    'LBAC3': 'ending_sprite_fade_table',
    'LBAD3': 'ending_walk_vel_sub',
    'LBAD7': 'ending_walk_vel_whole',
    'LBADB': 'ending_health_tile_data',

    # =========================================================================
    # Stage intro / weapon get text ($BAE0-$BC61)
    # =========================================================================
    'LBB1A': 'stage_intro_clear_pal',
    'LBB2C': 'stage_intro_fade_loop',
    'LBB3F': 'stage_intro_vblank',
    'LBB45': 'stage_intro_draw_name',
    'LBB84': 'stage_intro_blink_loop',
    'LBB88': 'stage_intro_blink_frame',
    'LBB96': 'stage_intro_set_colors',
    'LBBB9': 'stage_intro_upload_cols',
    'LBBC9': 'stage_intro_cursor_init',
    'LBBCB': 'stage_intro_cursor_load',
    'LBBDD': 'stage_intro_select_loop',
    'LBBF0': 'stage_intro_check_input',
    'LBC05': 'stage_intro_no_input',
    'LBC0B': 'stage_intro_start',
    'LBC12': 'stage_intro_save_pal',
    'LBC14': 'stage_intro_save_pal_loop',
    'LBC27': 'stage_intro_restore_loop',
    'LBC2F': 'stage_intro_restore_inner',
    'LBC41': 'stage_intro_restore_add',
    'LBC4B': 'stage_intro_restore_store',
    'LBC4E': 'stage_intro_restore_next',
    'LBC55': 'stage_intro_restore_frame',
    'LBC5B': 'stage_intro_restore_done',
    'LBC5E': 'stage_intro_exit',

    # =========================================================================
    # Weapon get sub-screen ($BC62-$BDEA)
    # =========================================================================
    'LBC62': 'weapon_get_init',
    'LBC6C': 'weapon_get_load_pal',
    'LBC7F': 'weapon_get_blink_loop',
    'LBC89': 'weapon_get_set_blink',
    'LBCFA': 'weapon_get_show_loop',
    'LBD08': 'weapon_get_set_colors',
    'LBD22': 'weapon_get_draw_marker',
    'LBD34': 'weapon_get_wait_frame',
    'LBD3E': 'weapon_get_text_upload',
    'LBD7C': 'weapon_get_text_inner',
    'LBD8A': 'weapon_get_text_byte',
    'LBD8C': 'weapon_get_text_store',
    'LBDAB': 'weapon_get_long_wait',
    'LBDAF': 'weapon_get_wait_loop',
    'LBDB7': 'weapon_get_clear_nt',
    'LBDBB': 'weapon_get_clear_loop',
    'LBDCF': 'weapon_get_clear_cols',
    'LBDEC': 'weapon_get_draw_weapon',

    # =========================================================================
    # Text / layout data ($BE12-$BF93)
    # =========================================================================
    'LBE12': 'weapon_name_data',
    'LBF30': 'weapon_name_data_2',
    'LBF5A': 'stage_intro_pal_lo',
    'LBF5B': 'stage_intro_pal_hi',
    'LBF6E': 'stage_intro_cursor_y',
    'LBF70': 'stage_intro_cursor_oam',
    'LBF74': 'weapon_get_extra_pal',

    # =========================================================================
    # Padding / vectors ($BF94-$BFFF)
    # =========================================================================
    'LBF94': 'bank_0D_padding',
}

def main():
    with open(ASM_FILE, 'r') as f:
        text = f.read()

    all_renames = {}
    all_renames.update(EXTERNAL_RENAMES)
    all_renames.update(INTERNAL_RENAMES)

    count = 0
    for old, new in sorted(all_renames.items(), key=lambda x: -len(x[0])):
        # Use word-boundary regex to avoid partial matches
        pattern = re.compile(r'\b' + re.escape(old) + r'\b')
        new_text = pattern.sub(new, text)
        if new_text != text:
            count += 1
            text = new_text

    with open(ASM_FILE, 'w') as f:
        f.write(text)

    print(f"Renamed {count} labels in {ASM_FILE}")

    # Verify no LXXXX internal labels remain (L8xxx-LBxxx range)
    remaining = re.findall(r'\bL[89AB][0-9A-F]{3}\b', text)
    # Filter to only actual label definitions
    remaining_defs = re.findall(r'^L[89AB][0-9A-F]{3}:', text, re.MULTILINE)
    if remaining_defs:
        print(f"WARNING: {len(remaining_defs)} unrenamed internal labels remain:")
        for r in remaining_defs[:20]:
            print(f"  {r}")

    # Check external labels that still have LXXXX form
    remaining_ext = re.findall(r'^L[0-9A-F]{4}\b', text, re.MULTILINE)
    if remaining_ext:
        print(f"Note: {len(remaining_ext)} address-format external refs remain (expected for non-ROM addresses)")

if __name__ == '__main__':
    main()
