#!/usr/bin/env python3
"""
Rename auto-generated LXXXX labels in bank0F_fixed.asm to descriptive names.

This script replaces all occurrences of each label (both definitions like
"LC07F:" and references like "jsr LC07F") with human-readable names based
on the code's function in the Mega Man 2 NES ROM.

Bank $0F is the fixed bank ($C000-$FFFF), always mapped in memory.
"""

import re
import sys
import os

ASM_FILE = os.path.join(os.path.dirname(__file__), '..', 'src', 'bank0F_fixed.asm')

# =============================================================================
# Label rename dictionary: old_label -> new_label
# Organized by functional region in the ROM
# =============================================================================
RENAMES = {
    # =========================================================================
    # Wait-for-VBLANK routines ($C07F-$C109)
    # =========================================================================
    'LC07F': 'wait_for_vblank',
    'LC08E': 'wait_vblank_loop',
    'LC0BA': 'wait_vblank_loop_0D',
    'LC0D7': 'wait_one_rendering_frame',
    'LC0ED': 'wait_frame_loop',
    'LC100': 'wait_multiple_frames',

    # =========================================================================
    # Boss death sequence ($C10B-$C1EF)
    # =========================================================================
    'LC10B': 'boss_death_sequence',
    'LC11B': 'boss_death_check_type',
    'LC126': 'boss_death_setup_slot',
    'LC166': 'boss_death_run_frame',
    'LC17E': 'boss_death_delay_start',
    'LC180': 'boss_death_delay_loop',
    'LC182': 'boss_death_delay_step',
    'LC1A2': 'boss_death_calc_score',
    'LC1AC': 'boss_death_finish',
    'LC1D2': 'boss_death_to_0E_1',
    'LC1D5': 'boss_death_to_0E_2',
    'LC1D8': 'explosion_offset_y_tbl',
    'LC1E0': 'explosion_offset_x_lo_tbl',
    'LC1E8': 'explosion_offset_x_hi_tbl',

    # =========================================================================
    # Boss intro sequence ($C1F0-$C288)
    # =========================================================================
    'LC1F0': 'boss_intro_sequence',
    'LC1F5': 'boss_intro_loop',
    'LC20F': 'boss_intro_done',
    'LC25D': 'all_bosses_defeated',
    'LC261': 'advance_to_next_stage',
    'LC276': 'next_stage_continue',
    'LC279': 'boss_beaten_mask_lo',
    'LC281': 'boss_beaten_mask_hi',

    # =========================================================================
    # Sound/boss reset ($C289-$C2AF)
    # =========================================================================
    'LC289': 'reset_sound_state',

    # =========================================================================
    # Nametable initialization ($C2B0-$C351)
    # =========================================================================
    'LC2B0': 'nametable_init_loop',
    'LC2C1': 'nametable_copy_initial',
    'LC2D2': 'nametable_column_upload',
    'LC2F5': 'nametable_col_copy_inner',
    'LC2F7': 'nametable_col_copy_byte',
    'LC321': 'nametable_init_data',
    'LC324': 'nametable_bank_table',
    'LC33B': 'nametable_addr_table',

    # =========================================================================
    # Game frame / main loop ($C352-$C3EA)
    # =========================================================================
    'LC352': 'run_one_game_frame',
    'LC36C': 'run_sound_and_scroll',
    'LC37B': 'game_frame_wait_render',
    'LC382': 'game_frame_done',
    'LC386': 'clear_entities_and_run',
    'LC38A': 'clear_entities_loop',
    'LC393': 'setup_explosion_array',
    'LC3AA': 'explosion_setup_loop',

    # =========================================================================
    # Explosion data tables ($C3EB-$C426)
    # =========================================================================
    'LC3EB': 'explosion_xvel_sub_tbl',
    'LC3F7': 'explosion_xvel_tbl',
    'LC403': 'explosion_yvel_sub_tbl',
    'LC40F': 'explosion_yvel_tbl',
    'LC41B': 'explosion_flags_tbl',

    # =========================================================================
    # Palette animation ($C427-$C45C)
    # =========================================================================
    'LC427': 'palette_anim_update',
    'LC447': 'palette_anim_advance',
    'LC44E': 'palette_anim_copy_loop',
    'LC45C': 'palette_anim_done',

    # =========================================================================
    # CHR-RAM upload ($C487-$C556)
    # =========================================================================
    'LC487': 'chr_upload_entry',
    'LC49B': 'chr_upload_page_loop',
    'LC49D': 'chr_upload_byte_loop',
    'LC4BC': 'chr_upload_palette_copy',
    'LC51B': 'chr_upload_sound_bank',
    'LC533': 'chr_sound_page_loop',
    'LC53C': 'chr_sound_byte_loop',
    'LC556': 'chr_upload_wily_check',

    # =========================================================================
    # Entity slot finding / sound dispatch ($C575-$C630)
    # =========================================================================
    'LC575': 'find_active_entity_slot',
    'LC586': 'scroll_column_setup',
    'LC5A8': 'find_entity_done',
    'LC5A9': 'process_sound_and_bosses',
    'LC5CD': 'clear_boss_entities',
    'LC5ED': 'process_sound_jump_intro',
    'LC5F0': 'process_sound_done',

    # =========================================================================
    # CHR bank copy / switch helpers ($C631-$C70B)
    # =========================================================================
    'LC631': 'chr_copy_ppu_loop',
    'LC65B': 'chr_bank_load_ptr_lo',
    'LC65C': 'chr_bank_load_ptr_hi',
    'LC66F': 'chr_copy_loop',
    'LC697': 'chr_bank_src_bank_tbl',
    'LC6BE': 'chr_bank_src_addr_lo_tbl',
    'LC6E5': 'chr_bank_page_count_tbl',

    # =========================================================================
    # Column data copy ($C70C-$C7C8)
    # =========================================================================
    'LC70C': 'column_copy_to_buffer',
    'LC711': 'column_copy_loop',
    'LC72A': 'column_copy_from_ram',
    'LC74E': 'column_copy_from_ptr',
    'LC792': 'column_copy_from_bank',

    # =========================================================================
    # Boss entrance ($C7C9-$C818)
    # =========================================================================
    'LC7C9': 'boss_entrance_scroll',
    'LC7F1': 'boss_entrance_done',

    # =========================================================================
    # Boss fight frame loop ($C819-$C84D)
    # =========================================================================
    'LC819': 'boss_fight_frame',
    'LC83D': 'boss_fight_wait_render',
    'LC844': 'boss_fight_wait_vblank',

    # =========================================================================
    # Division routines ($C84E-$C8AC)
    # =========================================================================
    'LC84E': 'divide_8bit',
    'LC85D': 'div8_setup',
    'LC85F': 'div8_loop',
    'LC870': 'div8_next',
    'LC874': 'divide_16bit',
    'LC889': 'div16_setup',
    'LC88B': 'div16_loop',
    'LC8A5': 'div16_next',

    # =========================================================================
    # Attribute table update helpers ($C943-$C967)
    # =========================================================================
    'LC943': 'attr_set_nametable',
    'LC94F': 'attr_check_row',
    'LC957': 'attr_calc_mask',
    'LC967': 'attr_mask_table',

    # =========================================================================
    # Metatile rendering ($C993-$CA06)
    # =========================================================================
    'LC993': 'metatile_render_loop',
    'LC9C1': 'metatile_set_base_nt',

    # =========================================================================
    # Metatile/attribute data ($CA07-$CB63)
    # =========================================================================
    'LCA07': 'metatile_offset_table',
    'LCA91': 'metatile_attr_loop',
    'LCAAC': 'metatile_attr_count',
    'LCAB0': 'metatile_attr_inner',
    'LCAD9': 'metatile_attr_mask_setup',
    'LCAFA': 'metatile_attr_done',
    'LCB4F': 'scroll_col_copy_loop',
    'LCB64': 'scroll_col_load_palette',

    # =========================================================================
    # Entity active list ($CB90-$CBA1)
    # =========================================================================
    'LCB90': 'build_active_entity_list',
    'LCB9C': 'active_entity_next',

    # =========================================================================
    # Tile collision lookup ($CBA2-$CC46)
    # =========================================================================
    'LCBA2': 'lookup_cached_tile',
    'LCBA4': 'cached_tile_scan_loop',
    'LCBC3': 'lookup_tile_from_map',
    'LCBD7': 'tile_lookup_clear_y',
    'LCBDB': 'tile_lookup_calc_index',
    'LCC1A': 'tile_check_vert',
    'LCC21': 'tile_get_collision_type',
    'LCC41': 'tile_lookup_done',
    'LCC47': 'stage_collision_table',

    # =========================================================================
    # OAM / Sprite rendering ($CC6C-$CF5C)
    # =========================================================================
    'LCC6C': 'clear_oam_buffer',
    'LCC70': 'clear_oam_loop',
    'LCC77': 'render_all_sprites',
    'LCC8E': 'render_even_frame',
    'LCC9C': 'render_entity_forward',
    'LCCA9': 'render_weapon_forward',
    'LCCBD': 'render_even_done',
    'LCCC0': 'render_odd_frame',
    'LCCCB': 'render_weapon_reverse',
    'LCCD8': 'render_entity_reverse',
    'LCCE5': 'render_priority_fix',
    'LCCED': 'render_priority_loop',
    'LCCFF': 'render_sprites_done',
    'LCD05': 'render_special_mode',
    'LCD1F': 'render_special_check_entity',
    'LCD22': 'render_special_entity_loop',
    'LCD24': 'render_special_entity_inner',
    'LCD30': 'render_special_jump_1',
    'LCD33': 'render_special_carry',
    'LCD3D': 'render_special_weapon',
    'LCD51': 'render_special_done',
    'LCD54': 'render_special_odd',
    'LCD5F': 'render_special_weapon_rev',
    'LCD6C': 'render_special_entity_rev',
    'LCD78': 'render_special_entity_inner_2',
    'LCD7B': 'render_special_carry_2',
    'LCD8D': 'render_special_check_2',
    'LCD90': 'render_special_jump_2',
    'LCD94': 'render_special_jump_end',
    'LCD97': 'render_entity_special',
    'LCDA0': 'render_entity_get_sprite_ptr',
    'LCDBB': 'render_entity_deactivate',
    'LCDBF': 'render_weapon_special',
    'LCDC8': 'render_weapon_get_sprite_ptr',
    'LCDE3': 'render_weapon_deactivate',
    'LCDE7': 'render_entity_normal',
    'LCDF0': 'render_entity_get_ptr',
    'LCE22': 'render_entity_check_frame',
    'LCE2F': 'render_begin_oam_write',
    'LCE40': 'render_flash_jump',
    'LCE43': 'render_check_flash',
    'LCE49': 'render_skip_flash',
    'LCE58': 'render_dec_extra_timer',
    'LCE5B': 'render_load_sprite_data',
    'LCE69': 'render_sprite_loop',
    'LCE9A': 'render_sprite_oam_entry',
    'LCEB8': 'render_sprite_load_tile',
    'LCEBA': 'render_sprite_apply_flip',
    'LCECC': 'render_sprite_no_flip_x',
    'LCECE': 'render_sprite_write_x',
    'LCED7': 'render_sprite_neg_x',
    'LCEDB': 'render_sprite_offscreen',
    'LCEE2': 'render_sprite_store_x',
    'LCEED': 'render_sprite_next',
    'LCEF5': 'render_ok_return',
    'LCEF7': 'render_full_return',
    'LCEF9': 'render_weapon_normal',
    'LCF02': 'render_weapon_get_ptr',
    'LCF34': 'render_weapon_check_frame',
    'LCF41': 'render_weapon_begin_write',
    'LCF5B': 'render_weapon_skip',

    # =========================================================================
    # HP bar rendering ($CF5D-$CFEF)
    # =========================================================================
    'LCF5D': 'render_hp_bars',
    'LCF87': 'render_weapon_hp',
    'LCF9C': 'render_boss_hp_start',
    'LCF9E': 'render_boss_hp_setup',
    'LCFA7': 'render_hp_done',
    'LCFA8': 'render_hp_bar_loop',
    'LCFAA': 'render_hp_entry',
    'LCFC5': 'render_hp_empty_check',
    'LCFC9': 'render_hp_set_tile',
    'LCFE3': 'render_hp_overflow',
    'LCFE5': 'hp_y_positions_tbl',
    'LCFEC': 'hp_tile_ids_tbl',

    # =========================================================================
    # PPU buffer alt transfer ($D185-$D1EC)
    # =========================================================================
    'LD185': 'ppu_buffer_alt_row',
    'LD191': 'ppu_buffer_alt_byte',

    # =========================================================================
    # PPU scroll column update ($D1ED)
    # =========================================================================
    'LD1ED': 'ppu_col_write_loop',

    # =========================================================================
    # PPU attribute update ($D208-$D2F4)
    # =========================================================================
    'LD208': 'attr_update_loop',
    'LD223': 'attr_update_done',
    'LD22D': 'attr_update_fill_mode',
    'LD231': 'attr_fill_outer',
    'LD239': 'attr_fill_write_addr',
    'LD249': 'attr_fill_write_byte',
    'LD264': 'attr_fill_next',
    'LD269': 'attr_update_special',
    'LD283': 'attr_special_default',
    'LD285': 'attr_special_setup',
    'LD287': 'attr_special_write_loop',
    'LD2CC': 'attr_special_read_current',
    'LD2D2': 'attr_special_merge',

    # =========================================================================
    # Weapon palette / colors ($D2F5-$D331)
    # =========================================================================
    'LD2F5': 'weapon_palette_copy_loop',
    'LD302': 'weapon_palette_data',

    # =========================================================================
    # Weapon firing ($D332-$D4DE)
    # =========================================================================
    'LD332': 'fire_weapon_buster',
    'LD36A': 'fire_find_slot_loop',
    'LD375': 'fire_setup_projectile',
    'LD3A8': 'weapon_set_base_type',
    'LD3BD': 'weapon_store_type',
    'LD3C7': 'weapon_reset_direction',
    'LD3D4': 'weapon_base_type_tbl',
    'LD3E0': 'weapon_spawn_projectile',
    'LD40A': 'weapon_spawn_facing_right',
    'LD41C': 'weapon_spawn_set_y',
    'LD44F': 'projectile_type_tbl',
    'LD461': 'projectile_flags_tbl',
    'LD473': 'projectile_x_offset_tbl',
    'LD477': 'projectile_x_offset_2',
    'LD47B': 'projectile_x_offset_3',
    'LD485': 'projectile_xvel_sub_tbl',
    'LD489': 'projectile_xvel_sub_2',
    'LD497': 'projectile_xvel_tbl',
    'LD4A9': 'projectile_yvel_sub_tbl',
    'LD4BB': 'projectile_yvel_tbl',
    'LD4CD': 'projectile_damage_type_tbl',
    'LD4DF': 'weapon_range_offset_tbl',
    'LD4E4': 'contact_damage_range_x_tbl',

    # =========================================================================
    # Contact damage range Y ($D584-$D5F6)
    # =========================================================================
    'LD584': 'contact_damage_range_y_tbl',
    'LD58C': 'contact_range_y_data_1',
    'LD58E': 'contact_range_y_data_2',
    'LD590': 'contact_range_y_data_3',
    'LD592': 'contact_range_y_data_4',
    'LD594': 'contact_range_y_data_5',
    'LD5A8': 'contact_range_y_data_6',
    'LD5B3': 'contact_range_y_data_7',
    'LD5B7': 'contact_range_y_data_8',
    'LD5E5': 'contact_range_y_data_9',
    'LD5EB': 'contact_range_y_data_10',
    'LD5ED': 'contact_range_y_data_11',
    'LD5F3': 'contact_range_y_data_12',
    'LD5F7': 'contact_range_y_data_13',

    # =========================================================================
    # Scroll code dispatch ($D631)
    # =========================================================================
    'LD631': 'switch_to_bank_0D',

    # =========================================================================
    # Entity spawn/despawn scan ($D658-$D752)
    # =========================================================================
    'LD658': 'entity_spawn_scan',
    'LD676': 'spawn_scan_backward',
    'LD68A': 'spawn_backward_despawn',
    'LD692': 'spawn_scan_forward',
    'LD696': 'spawn_forward_check',
    'LD6A6': 'spawn_forward_skip',
    'LD6A9': 'spawn_forward_done',
    'LD6AB': 'spawn_secondary_backward',
    'LD6BF': 'spawn_sec_check_active',
    'LD6C8': 'spawn_sec_backward_next',
    'LD6CC': 'spawn_secondary_forward',
    'LD6D0': 'spawn_sec_forward_check',
    'LD6E0': 'spawn_sec_forward_skip',
    'LD6E3': 'spawn_sec_forward_done',
    'LD6E8': 'spawn_scan_right_scroll',
    'LD6FA': 'spawn_right_activate',
    'LD701': 'spawn_right_backward',
    'LD703': 'spawn_right_back_check',
    'LD713': 'spawn_right_back_skip',
    'LD716': 'spawn_right_back_done',
    'LD718': 'spawn_right_sec_forward',
    'LD72A': 'spawn_right_sec_check',
    'LD732': 'spawn_right_sec_next',
    'LD736': 'spawn_right_sec_backward',
    'LD738': 'spawn_right_sec_back_chk',
    'LD748': 'spawn_right_sec_back_skip',
    'LD74B': 'spawn_right_sec_back_done',
    'LD74D': 'spawn_scan_done',

    # =========================================================================
    # Entity activation / spawning ($D753-$D804)
    # =========================================================================
    'LD753': 'activate_primary_entity',
    'LD756': 'activate_check_dup',
    'LD77C': 'entity_init_from_type',
    'LD7CB': 'entity_activate_done',
    'LD7CC': 'activate_secondary_entity',
    'LD7CF': 'activate_sec_check_dup',

    # =========================================================================
    # Entity data tables ($D805-$DA00)
    # =========================================================================
    'LD805': 'entity_flags_table',
    'LD885': 'entity_hitbox_width_idx_tbl',
    'LD901': 'entity_hitbox_height_idx_tbl',
    'LD944': 'entity_hitbox_height_idx_2',
    'LD981': 'entity_ai_behavior_tbl',
    'LDA01': 'hitbox_width_lo_tbl',
    'LDA02': 'hitbox_width_hi_tbl',
    'LDA21': 'hitbox_height_lo_tbl',
    'LDA22': 'hitbox_height_hi_tbl',

    # =========================================================================
    # Find empty entity slot ($DA43-$DA4F)
    # =========================================================================
    'LDA43': 'find_empty_entity_slot',
    'LDA45': 'find_slot_loop',
    'LDA4F': 'find_slot_found',

    # =========================================================================
    # Weapon fire dispatch ($DA74-$DAE4)
    # =========================================================================
    'LDA74': 'fire_weapon_scan_slot',
    'LDA80': 'fire_weapon_found_slot',
    'LDA8A': 'fire_weapon_set_timer',
    'LDA90': 'fire_weapon_set_dir',
    'LDA9D': 'fire_weapon_no_slot',
    'LDABB': 'fire_weapon_multi_scan',
    'LDAC7': 'fire_weapon_multi_loop',
    'LDAE4': 'fire_weapon_multi_fail',

    # =========================================================================
    # More weapon fire variants ($DAFA-$DC4C)
    # =========================================================================
    'LDAFA': 'fire_weapon_spread_loop',
    'LDB12': 'fire_weapon_bubble_scan',
    'LDB1E': 'fire_weapon_bubble_fire',
    'LDB36': 'fire_weapon_bubble_done',
    'LDB39': 'fire_weapon_bubble_fail',
    'LDB4D': 'fire_weapon_leaf_scan',
    'LDB59': 'fire_weapon_leaf_fire',
    'LDB71': 'fire_weapon_leaf_reset',
    'LDB78': 'fire_weapon_leaf_fail',
    'LDBA7': 'fire_weapon_crash_scan',
    'LDBB3': 'fire_weapon_crash_fire',
    'LDBCB': 'fire_weapon_crash_aim',
    'LDBEF': 'fire_weapon_crash_fail',
    'LDBF1': 'crash_yvel_sub_tbl',
    'LDC01': 'crash_yvel_tbl',
    'LDC11': 'crash_xvel_sub_tbl',
    'LDC21': 'crash_xvel_tbl',
    'LDC4D': 'fire_weapon_finish',
    'LDC60': 'fire_weapon_star_scan',
    'LDC6C': 'fire_weapon_star_fire',
    'LDC7B': 'fire_weapon_star_fail',

    # =========================================================================
    # Weapon dispatch table ($DCB8-$DCCF)
    # =========================================================================
    'LDCB8': 'weapon_dispatch_lo_tbl',
    'LDCC4': 'weapon_dispatch_hi_tbl',

    # =========================================================================
    # Entity position update ($DCD0-$DD13)
    # =========================================================================
    'LDCD0': 'update_entity_positions',
    'LDCD2': 'update_entity_loop',
    'LDCE9': 'update_entity_next',
    'LDCF1': 'update_entity_special',

    # =========================================================================
    # Special entity dispatch ($DD14-$DD33)
    # =========================================================================
    'LDD14': 'entity_special_dispatch_lo',
    'LDD24': 'entity_special_dispatch_hi',

    # =========================================================================
    # E-tank / health pickup ($DD4C-$DDB0)
    # =========================================================================
    'LDD4C': 'etank_check_threshold',
    'LDD5C': 'etank_set_anim',
    'LDD66': 'etank_animate',
    'LDD93': 'etank_check_fire',
    'LDD9A': 'etank_reset_counter',
    'LDDA6': 'etank_find_projectile',
    'LDDB0': 'etank_done',
    'LDDB1': 'etank_spawn_projectile',
    'LDDD3': 'etank_deduct_ammo',

    # =========================================================================
    # E-tank weapon selection ($DDFB-$DE17)
    # =========================================================================
    'LDDFB': 'etank_weapon_mid',
    'LDE08': 'etank_weapon_high',
    'LDE11': 'etank_weapon_set_anim',
    'LDE14': 'etank_apply_physics',

    # =========================================================================
    # E-tank palette/sound ($DE18-$DE48)
    # =========================================================================
    'LDE18': 'etank_update_palette',
    'LDE34': 'etank_palette_done',
    'LDE35': 'etank_sound_bank_tbl',
    'LDE39': 'etank_palette_lo_tbl',
    'LDE3A': 'etank_palette_hi_tbl',
    'LDE41': 'etank_anim_frame_tbl',
    'LDE44': 'etank_cost_tbl',

    # =========================================================================
    # Crash bomb wall ($DEBE-$DED3)
    # =========================================================================
    'LDEBE': 'crash_bomb_add_y',
    'LDEC4': 'crash_bomb_store_y',
    'LDED4': 'crash_bomb_explode',

    # =========================================================================
    # Bubble lead / weapon behavior ($DEF5-$DF6C)
    # =========================================================================
    'LDEF5': 'bubble_check_anim',
    'LDEFE': 'bubble_set_anim',
    'LDF01': 'bubble_check_state',
    'LDF13': 'bubble_track_player',
    'LDF2E': 'bubble_check_input',
    'LDF3C': 'bubble_check_direction',
    'LDF4F': 'bubble_check_up_down',
    'LDF58': 'bubble_set_yvel',
    'LDF5E': 'bubble_deduct_ammo',
    'LDF68': 'bubble_done',
    'LDF69': 'bubble_apply_physics',
    'LDF6D': 'bubble_yvel_tbl',

    # =========================================================================
    # Metal blade behavior ($DF8E-$DFFD)
    # =========================================================================
    'LDF8E': 'metal_blade_launch',
    'LDFAB': 'metal_blade_check_wall',
    'LDFC1': 'metal_blade_check_stop',
    'LDFCA': 'metal_blade_physics',
    'LDFF3': 'metal_blade_check_despawn',
    'LDFFE': 'metal_blade_accelerate',

    # =========================================================================
    # Quick boomerang behavior ($E078-$E11E)
    # =========================================================================
    'LE078': 'quick_boomerang_hit',
    'LE0A2': 'quick_boomerang_phase1',
    'LE0B9': 'quick_boomerang_bounds',
    'LE0BD': 'quick_boomerang_phase2',
    'LE0DA': 'quick_boomerang_scatter',
    'LE110': 'quick_boomerang_dec_hp',
    'LE11B': 'quick_boomerang_check',

    # =========================================================================
    # Quick boomerang scatter tables ($E11F-$E14E)
    # =========================================================================
    'LE11F': 'scatter_offset_y_tbl',
    'LE125': 'scatter_offset_y_2',
    'LE12F': 'scatter_offset_x_lo_tbl',
    'LE13B': 'scatter_offset_x_lo_2',
    'LE13F': 'scatter_offset_x_hi_tbl',
    'LE147': 'scatter_offset_x_hi_2',
    'LE14D': 'scatter_offset_x_hi_3',
    'LE14F': 'tile_solid_flag_tbl',

    # =========================================================================
    # Air shooter behavior ($E1C8-$E20F)
    # =========================================================================
    'LE1C8': 'air_shooter_dec_timer',
    'LE1CD': 'air_shooter_collision',
    'LE1F3': 'air_shooter_end_phase',
    'LE205': 'air_shooter_physics',
    'LE20F': 'air_shooter_done',

    # =========================================================================
    # Leaf shield behavior ($E228-$E2DC)
    # =========================================================================
    'LE228': 'leaf_shield_deactivate',
    'LE245': 'leaf_shield_accel',
    'LE266': 'leaf_shield_wall_check',
    'LE2B5': 'leaf_shield_fail',
    'LE2B8': 'leaf_shield_hitbox',
    'LE2D2': 'leaf_shield_physics',
    'LE2DC': 'leaf_shield_done',

    # =========================================================================
    # Time stopper behavior ($E313-$E3EC)
    # =========================================================================
    'LE313': 'time_stopper_check_down',
    'LE325': 'time_stopper_clear_dmg',
    'LE336': 'time_stopper_dec_timer',
    'LE344': 'time_stopper_physics_jmp',
    'LE377': 'time_stopper_check_done',
    'LE393': 'time_stopper_inc_dmg',
    'LE39D': 'time_stopper_finish',
    'LE3B6': 'time_stopper_alt_state',
    'LE3CC': 'time_stopper_check_fall',
    'LE3D5': 'time_stopper_set_vel',
    'LE3E2': 'time_stopper_physics',
    'LE3EC': 'time_stopper_done',

    # =========================================================================
    # Wall collision helper ($E3ED-$E467)
    # =========================================================================
    'LE3ED': 'check_wall_collision',
    'LE404': 'wall_coll_facing_right',
    'LE411': 'wall_coll_store_screen',
    'LE440': 'wall_coll_check_below',
    'LE44C': 'wall_coll_store_y',
    'LE468': 'wall_solid_flag_tbl',

    # =========================================================================
    # Crash bomb entity behavior ($E492-$E4E8)
    # =========================================================================
    'LE492': 'crash_entity_reset_vel',
    'LE4AE': 'crash_entity_accelerate',
    'LE4DD': 'crash_entity_dec_timer',

    # =========================================================================
    # Bounds check / spawn helper ($E4E9-$E558)
    # =========================================================================
    'LE4E9': 'check_entity_on_screen',
    'LE4FA': 'entity_off_screen_deactivate',
    'LE4FF': 'spawn_weapon_from_entity',

    # =========================================================================
    # Player-entity collision ($E55A-$E5EB)
    # =========================================================================
    'LE55A': 'check_player_collision',
    'LE575': 'player_coll_check_range',
    'LE58A': 'player_coll_check_y',
    'LE5A8': 'player_coll_kill',
    'LE5B2': 'player_coll_knockback',
    'LE5CC': 'player_collision_done',
    'LE5CD': 'player_collision_item',
    'LE5EB': 'player_collision_return',

    # =========================================================================
    # Weapon-entity collision ($E5EC-$E712)
    # =========================================================================
    'LE5EC': 'check_weapon_collision',
    'LE5FF': 'weapon_coll_check_slot',
    'LE61E': 'weapon_coll_check_range_x',
    'LE62F': 'weapon_coll_check_range_y',
    'LE634': 'weapon_coll_next_slot',
    'LE643': 'weapon_collision_dispatch',
    'LE6D4': 'weapon_damage_apply',
    'LE6FB': 'weapon_damage_killed',
    'LE702': 'weapon_damage_zero',
    'LE70D': 'weapon_damage_deactivate_wpn',
    'LE712': 'weapon_damage_done',
    'LE74D': 'weapon_damage_killed_alt',
    'LE770': 'weapon_damage_return',

    # =========================================================================
    # Weapon-specific collision handlers ($E7D0-$E911)
    # =========================================================================
    'LE7D0': 'weapon_coll_handler_done',
    'LE7D4': 'weapon_coll_deactivate',
    'LE812': 'weapon_coll_hp_zero',
    'LE819': 'weapon_coll_rebound',
    'LE835': 'weapon_coll_rebound_done',
    'LE8A3': 'weapon_coll_handler_2_done',
    'LE8A7': 'weapon_coll_deactivate_2',
    'LE8E5': 'weapon_coll_hp_zero_2',
    'LE8EC': 'weapon_coll_stun',
    'LE911': 'weapon_coll_stun_done',
    'LE974': 'weapon_coll_handler_3_done',
    'LE97F': 'apply_difficulty_modifier',
    'LE985': 'difficulty_done',

    # =========================================================================
    # Weapon damage tables ($E986-$ED5B)
    # =========================================================================
    'LE986': 'weapon_handler_ptr_lo',
    'LE98F': 'weapon_handler_ptr_hi',
    'LE998': 'weapon_damage_table',
    'LEB7C': 'weapon_damage_table_2',
    'LEC6C': 'weapon_damage_table_3',
    'LED5C': 'contact_damage_to_player_tbl',
    'LEDE5': 'hitbox_y_offset_data',

    # =========================================================================
    # Entity collision dispatch helpers ($EE75-$EEB3)
    # =========================================================================
    'LEE75': 'collision_inc_state',
    'LEE78': 'collision_apply_physics',
    'LEEB4': 'collision_done',
    'LEECD': 'collision_check_contact',
    'LEEEF': 'apply_entity_physics',

    # =========================================================================
    # Entity physics engine ($EEEF-$EFB2)
    # =========================================================================
    'LEF09': 'physics_check_gravity',
    'LEF21': 'physics_move_left',
    'LEF5A': 'physics_move_right',
    'LEF8A': 'physics_in_bounds',
    'LEF8C': 'physics_out_of_bounds',
    'LEF8F': 'physics_despawn_check',
    'LEF9C': 'physics_despawn_return',
    'LEF9E': 'physics_despawn_secondary',
    'LEFB3': 'apply_entity_physics_alt',
    'LEFC6': 'physics_alt_check_contact',
    'LEFE8': 'physics_alt_check_offscreen',

    # =========================================================================
    # Entity facing direction ($F00F-$F02B)
    # =========================================================================
    'LF00F': 'entity_face_player_done',
    'LF010': 'find_entity_by_type',
    'LF014': 'find_entity_scan',
    'LF016': 'find_entity_compare',
    'LF020': 'find_entity_check_active',
    'LF02A': 'find_entity_not_found',

    # =========================================================================
    # Vertical tile collision ($F02C-$F0CE)
    # =========================================================================
    'LF02C': 'check_vert_tile_collision',
    'LF03F': 'vert_coll_falling',
    'LF045': 'vert_coll_store_pos',
    'LF060': 'vert_coll_lookup_uncached',
    'LF063': 'vert_coll_process',
    'LF085': 'vert_coll_left_uncached',
    'LF088': 'vert_coll_left_process',
    'LF0A5': 'vert_coll_snap_up',
    'LF0B3': 'vert_coll_store_y',
    'LF0CC': 'vert_coll_done',
    'LF0CD': 'vert_coll_no_hit',

    # =========================================================================
    # Horizontal tile collision ($F0CF-$F14F)
    # =========================================================================
    'LF0CF': 'check_horiz_tile_collision',
    'LF0F0': 'horiz_coll_left',
    'LF0FD': 'horiz_coll_store_screen',
    'LF109': 'horiz_coll_lookup_uncached',
    'LF10C': 'horiz_coll_process',
    'LF134': 'horiz_coll_snap_right',
    'LF14C': 'horiz_coll_no_hit',
    'LF150': 'tile_solid_lookup_tbl',

    # =========================================================================
    # Entity spawning from parent ($F159-$F259)
    # =========================================================================
    'LF159': 'spawn_entity_from_parent',
    'LF160': 'spawn_entity_init',
    'LF192': 'spawn_entity_no_slot',

    # =========================================================================
    # Entity velocity calculation ($F1C9-$F259)
    # =========================================================================
    'LF1C9': 'calc_entity_velocity',
    'LF20A': 'calc_vel_y_greater',
    'LF242': 'calc_vel_negate_y',
    'LF259': 'calc_vel_done',

    # =========================================================================
    # Item drop RNG ($F25A-$F2D0)
    # =========================================================================
    'LF25A': 'item_drop_rng',
    'LF25F': 'item_drop_calc',
    'LF288': 'item_drop_nothing',
    'LF289': 'item_drop_large_weapon',
    'LF28D': 'item_drop_large_health',
    'LF291': 'item_drop_small_health',
    'LF295': 'item_drop_small_weapon',
    'LF299': 'item_drop_extra_life',
    'LF2A1': 'item_drop_spawn',
    'LF2B5': 'item_drop_failed',
    'LF2B6': 'item_drop_normal_mode',

    # =========================================================================
    # Sprite definition pointer tables ($F900-$FAFF)
    # =========================================================================
    'LF900': 'sprite_def_ptr_lo',
    'LF980': 'sprite_def_ptr_lo_wpn',
    'LFA00': 'sprite_def_ptr_hi',
    'LFA80': 'sprite_def_ptr_hi_wpn',

    # =========================================================================
    # Sprite data in-stream label ($FE02)
    # =========================================================================
    'LFE02': 'sprite_data_FE02',

    # Note: LFFE1 is intentionally NOT renamed (self-modifying reset code)
}


def main():
    with open(ASM_FILE, 'r') as f:
        content = f.read()

    count = 0
    for old_label, new_label in RENAMES.items():
        # Use word-boundary matching to avoid partial replacements.
        # Match the label when it appears as:
        #   - a definition: "old_label:" at start of line (possibly with leading whitespace)
        #   - a reference: after whitespace, comma, or open paren
        # We use \b (word boundary) which works since labels are alphanumeric+underscore.
        pattern = re.compile(r'\b' + re.escape(old_label) + r'\b')
        new_content = pattern.sub(new_label, content)
        if new_content != content:
            count += 1
            content = new_content

    with open(ASM_FILE, 'w') as f:
        f.write(content)

    print(f"Renamed {count} labels in {ASM_FILE}")


if __name__ == '__main__':
    main()
