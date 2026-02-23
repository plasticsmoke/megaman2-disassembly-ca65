#!/usr/bin/env python3
"""
Rename auto-generated LXXXX labels in bank0E_game_engine.asm to descriptive names.

This script replaces all occurrences of each label (both definitions like
"L8006:" and references like "jsr L8006") with human-readable names based
on the code's function in the Mega Man 2 NES ROM.

Bank $0E is the main game engine bank, containing cold boot entry, hardware
init, the main game loop, player physics, scroll management, entity AI
dispatch, and all enemy behavior routines.
"""

import re
import sys
import os

ASM_FILE = os.path.join(os.path.dirname(__file__), '..', 'src', 'bank0E_game_engine.asm')

# =============================================================================
# External label renames: LXXXX := $XXXX references to bank $0F routines
# These are addresses in the fixed bank that bank $0E calls.
# =============================================================================
EXTERNAL_RENAMES = {
    # Already partially named in the source:
    # bank_switch_enqueue := $C051  (already named)
    # ppu_buffer_transfer := $D11B  (already named)
    # fixed_D2ED := $D2ED           (partially named)

    # Routines already named in bank $0F (but bank0E still uses LXXXX form)
    'LC07F': 'wait_for_vblank',           # $C07F — wait for VBLANK (NMI)
    'LC0D7': 'wait_one_rendering_frame',  # $C0D7 — wait one rendering frame
    'LC10B': 'boss_death_sequence',       # $C10B — boss death explosion sequence
    'LC5A9': 'process_sound_and_bosses',  # $C5A9 — process sound engine + boss logic
    'LC84E': 'divide_8bit',              # $C84E — 8-bit division
    'LC874': 'divide_16bit',             # $C874 — 16-bit division
    'LCBA2': 'lookup_cached_tile',       # $CBA2 — look up cached tile
    'LCBC3': 'lookup_tile_from_map',     # $CBC3 — look up tile from map data
    'LCC6C': 'clear_oam_buffer',         # $CC6C — clear OAM buffer (all sprites off)
    'LCC77': 'render_all_sprites',       # $CC77 — render all sprites to OAM
    'LD3A8': 'weapon_set_base_type',     # $D3A8 — set weapon base sprite type
    'LD3E0': 'weapon_spawn_projectile',  # $D3E0 — spawn weapon projectile
    'LD658': 'entity_spawn_scan',        # $D658 — scan for entities to spawn/despawn
    'LDCD0': 'update_entity_positions',  # $DCD0 — update all entity positions
    'LEFB3': 'apply_entity_physics_alt', # $EFB3 — apply entity physics (alternate)
    'LF010': 'find_entity_by_type',      # $F010 — find entity by type ID
    'LF014': 'find_entity_scan',         # $F014 — entity scan inner loop
    'LF02C': 'check_vert_tile_collision',# $F02C — check vertical tile collision
    'LF0CF': 'check_horiz_tile_collision', # $F0CF — check horizontal tile collision
    'LF159': 'spawn_entity_from_parent', # $F159 — spawn entity from parent slot
    'LF160': 'spawn_entity_init',        # $F160 — initialize spawned entity

    # Data/code tables in bank $0F
    'LC05D': 'banked_entry',              # $C05D — banked entry point table (byte table)
    'LC071': 'boss_beaten_check',         # $C071 — check boss beaten flags
    'LC45D': 'chr_upload_init',           # $C45D — CHR-RAM upload initialization
    'LC4CD': 'chr_upload_run',            # $C4CD — CHR-RAM upload execution
    'LC557': 'nametable_init',            # $C557 — nametable initialization setup
    'LC565': 'nametable_stage_setup',     # $C565 — stage-specific nametable setup
    'LC573': 'palette_anim_run',          # $C573 — palette animation update tick
    'LC7A4': 'get_screen_boundary',       # $C7A4 — look up screen boundary for room
    'LC7B5': 'boss_entrance_setup',       # $C7B5 — boss entrance scroll/init
    'LC808': 'boss_trigger_entrance',     # $C808 — trigger boss entrance sequence
    'LC80C': 'boss_wily_entrance',        # $C80C — Wily fortress boss entrance
    'LC8EF': 'metatile_render',           # $C8EF — render metatile to PPU buffer
    'LC91B': 'metatile_attr_update',      # $C91B — update attribute table for metatile
    'LC96B': 'column_data_copy',          # $C96B — copy column data for scroll
    'LCA16': 'scroll_y_update',           # $CA16 — update vertical scroll position
    'LCB0C': 'scroll_column_render',      # $CB0C — render scroll column to nametable
    'LCB8C': 'build_active_list',         # $CB8C — build active entity list
    'LDA51': 'fire_weapon_dispatch',      # $DA51 — weapon fire dispatch handler
    'LEEBA': 'apply_entity_physics',      # $EEBA — apply entity physics (standard)
    'LEEDA': 'apply_collision_physics',   # $EEDA — apply physics with collision check
    'LEFAF': 'apply_simple_physics',      # $EFAF — apply simple entity physics
    'LEFEE': 'entity_face_player',        # $EFEE — make entity face toward player
    'LF197': 'calc_entity_velocity',      # $F197 — calculate entity velocity toward target

    # Also rename fixed_D2ED to something more descriptive
    'fixed_D2ED': 'weapon_palette_setup',  # $D2ED — weapon palette copy/setup

    # These are ZP / non-ROM addresses used as labels
    'L0F15': 'zp_0F15',
    'L0F20': 'zp_0F20',
    'L1D06': 'addr_1D06',
    'L2020': 'addr_2020',
    'L4802': 'addr_4802',
    'L5060': 'addr_5060',
}

# =============================================================================
# Internal label renames: LXXXX labels within bank $0E ($8000-$BFFF)
# Organized by functional region
# =============================================================================
INTERNAL_RENAMES = {
    # =========================================================================
    # Cold boot / hardware init ($8000-$805E)
    # =========================================================================
    'L8006': 'wait_ppu_warmup_1',
    'L800B': 'wait_ppu_warmup_2',
    'L801B': 'clear_ram_loop',

    # =========================================================================
    # Game initialization ($805F-$8170)
    # =========================================================================
    'L805F': 'game_init',
    'L8072': 'game_init_set_scroll_bank',
    'L8079': 'game_init_check_wily',
    'L8088': 'game_init_fill_weapon_ammo',
    'L808C': 'fill_weapon_ammo_loop',
    'L8091': 'game_init_set_boss_offset',
    'L809B': 'game_init_store_boss_offset',
    'L80A1': 'game_init_fill_timers',
    'L812D': 'game_init_copy_stage_sprites',
    'L813A': 'game_init_blink_loop',
    'L8146': 'blink_sprite_store',

    # =========================================================================
    # Main game loop — normal stages ($8171-$81B5)
    # =========================================================================
    'L8171': 'main_game_loop',
    'L8178': 'main_loop_check_start',
    'L8181': 'main_loop_update_entities',
    'L819D': 'main_loop_check_scroll',
    'L81A9': 'main_loop_frame_skip',
    'L81B0': 'main_loop_wait_frame',

    # =========================================================================
    # Stage initialization data ($81BC-$81DD)
    # =========================================================================
    'L81BC': 'stage_intro_oam_data',
    'L81D0': 'stage_bank_table',

    # =========================================================================
    # Wily fortress entity spawn ($81DE-$8222)
    # =========================================================================
    'L81DE': 'wily_spawn_gate_entities',
    'L81F9': 'wily_spawn_gate_loop',
    'L8203': 'wily_spawn_shift_flags',
    'L8205': 'wily_spawn_check_done',
    'L821A': 'wily_spawn_next_bit',

    # =========================================================================
    # Main game loop — Wily fortress ($8223-$8267)
    # =========================================================================
    'L8223': 'wily_game_loop',
    'L8226': 'wily_loop_main',
    'L822D': 'wily_loop_check_start',
    'L8236': 'wily_loop_update_entities',
    'L824F': 'wily_loop_check_scroll',
    'L825B': 'wily_loop_frame_skip',
    'L8262': 'wily_loop_wait_frame',

    # =========================================================================
    # Wily gate data tables ($8268-$8277)
    # =========================================================================
    'L8268': 'wily_gate_anim_table',
    'L8270': 'wily_gate_y_pos_table',

    # =========================================================================
    # Screen transition check ($8278-$82D4)
    # =========================================================================
    'L8278': 'check_screen_transition',
    'L8298': 'check_scroll_right',
    'L82B8': 'scroll_transition_done',
    'L82BB': 'check_vertical_transition',
    'L82C8': 'clear_scroll_request',
    'L82CC': 'scroll_left_mask_table',
    'L82D0': 'scroll_right_mask_table',

    # =========================================================================
    # Item collection handler ($82D5-$84DD)
    # =========================================================================
    'L82D5': 'item_collection_handler',
    'L82FF': 'health_refill_loop',
    'L831A': 'health_refill_render',
    'L8323': 'health_refill_done_jmp',
    'L8326': 'health_refill_full_rts',
    'L833F': 'weapon_refill_loop',
    'L8358': 'weapon_refill_render',
    'L8361': 'refill_complete',
    'L836E': 'refill_exit',
    'L83AD': 'wily_door_transition',
    'L83D6': 'wily_door_bank_table',
    'L83DF': 'wily_teleport_sequence',
    'L83EE': 'wily_teleport_wait',
    'L83FE': 'wily_teleport_done',
    'L8407': 'reset_player_state',
    'L8416': 'wait_screen_fade',
    'L8481': 'set_palette_colors',
    'L8483': 'set_palette_loop',
    'L849A': 'palette_color_data',

    # =========================================================================
    # Item collection dispatch tables ($84DC-$84ED)
    # =========================================================================
    'L84DC': 'item_handler_ptr_lo',
    'L84E5': 'item_handler_ptr_hi',

    # =========================================================================
    # Per-frame entity update / player state machine ($84EE-$8782)
    # =========================================================================
    'L84EE': 'entity_update_dispatch',
    'L84F5': 'entity_dispatch_setup',
    'L8544': 'player_state_rts',

    # =========================================================================
    # Player state — standing/landing check
    # =========================================================================
    'L8566': 'player_set_state',

    # =========================================================================
    # Player movement / physics ($879B-$88FF)
    # =========================================================================
    'L879B': 'player_check_fire_weapon',
    'L87A7': 'player_fire_weapon',
    'L87AE': 'player_fire_rts',
    'L87AF': 'player_check_ladder_snap',
    'L87D8': 'player_snap_left',
    'L87E2': 'player_snap_update_facing',
    'L87F2': 'player_update_facing',
    'L880C': 'player_facing_rts',
    'L880D': 'player_set_max_speed',
    'L882F': 'player_check_accel_start',
    'L883B': 'player_check_facing_change',
    'L8844': 'player_decelerate',
    'L8854': 'player_apply_decel',
    'L886B': 'player_speed_zero',
    'L8873': 'player_store_max_speed',
    'L8880': 'player_accelerate',
    'L8897': 'player_set_face_dir',
    'L889E': 'player_handle_conveyor',
    'L88A3': 'player_conveyor_check',
    'L88CB': 'player_conveyor_reverse',
    'L88E4': 'player_conveyor_forward',
    'L88FA': 'player_no_conveyor',
    'L8901': 'player_conveyor_idle',

    # =========================================================================
    # Player speed tables ($8909-$8920)
    # =========================================================================
    'L8909': 'decel_rate_table',
    'L890C': 'max_speed_hi_table',
    'L8917': 'max_speed_lo_table',

    # =========================================================================
    # Player horizontal movement / scroll ($8922-$8A83)
    # =========================================================================
    'L8922': 'player_horiz_movement',
    'L894A': 'player_move_right',
    'L8997': 'player_right_check_delta',
    'L89AB': 'player_move_left_check',
    'L89B6': 'player_move_left',
    'L8A01': 'player_left_check_delta',
    'L8A12': 'player_scroll_right',
    'L8A19': 'player_scroll_left',
    'L8A20': 'player_check_tile_ahead',
    'L8A24': 'tile_check_loop',
    'L8A49': 'tile_eval_loop',
    'L8A56': 'tile_check_spike',

    # =========================================================================
    # Player tile check data ($8A6D-$8A83)
    # =========================================================================
    'L8A6D': 'gravity_hi_table',
    'L8A6F': 'frame_skip_table',
    'L8A71': 'scroll_speed_table',
    'L8A73': 'player_bounds_table',
    'L8A75': 'tile_type_flags',
    'L8A7E': 'tile_y_offset_table',
    'L8A81': 'tile_y_page_table',

    # =========================================================================
    # Player ground collision / tile lookup ($8A84-$8B82)
    # =========================================================================
    'L8A84': 'player_ground_collision',
    'L8A92': 'ground_tile_loop',
    'L8ABD': 'ground_check_lava',
    'L8AE8': 'ground_spawn_item',
    'L8AFA': 'ground_spawn_random_item',
    'L8B0F': 'ground_set_params',
    'L8B12': 'ground_store_params',
    'L8B30': 'ground_calc_platform_dir',
    'L8B3C': 'ground_shift_platform',
    'L8B5F': 'ground_check_above',
    'L8B68': 'ground_store_above',
    'L8B7C': 'ground_above_left',
    'L8B7E': 'ground_store_dir',
    'L8B82': 'ground_collision_rts',

    # =========================================================================
    # Player vertical physics ($8B83-$8C69)
    # =========================================================================
    'L8B83': 'player_vertical_physics',
    'L8B98': 'player_apply_gravity',
    'L8BC0': 'player_set_scroll_trigger',
    'L8BC6': 'player_check_fall_limit',
    'L8BD2': 'player_gravity_falling',
    'L8BFE': 'player_gravity_stop',
    'L8C06': 'player_apply_gravity_sub',
    'L8C27': 'player_gravity_rts',
    'L8C28': 'player_gravity_rising',
    'L8C44': 'player_ceiling_snap',
    'L8C65': 'player_ceiling_set_flag',

    # =========================================================================
    # Player floor tile check ($8C6A-$8CF3)
    # =========================================================================
    'L8C6A': 'player_floor_tile_check',
    'L8C6E': 'floor_tile_loop',
    'L8C94': 'floor_tile_eval',
    'L8CBA': 'floor_check_spike',
    'L8CB6': 'floor_set_solid',
    'L8CC9': 'floor_check_done',
    'L8CD2': 'floor_store_result',
    'L8CEC': 'floor_tile_rts',
    'L8CED': 'floor_x_offset_table',
    'L8CEF': 'floor_x_page_table',
    'L8CF1': 'floor_conveyor_type_table',

    # =========================================================================
    # Platform collision ($8CF4-$8DF4)
    # =========================================================================
    'L8CF4': 'check_platform_collision',
    'L8D06': 'platform_scan_start',
    'L8D0B': 'platform_scan_secondary',
    'L8D10': 'platform_scan_next',
    'L8D15': 'platform_scan_primary',
    'L8D1A': 'platform_skip_primary',
    'L8D1F': 'platform_check_y',
    'L8D34': 'platform_check_range',
    'L8D49': 'platform_check_type',
    'L8D53': 'platform_land_on',
    'L8D86': 'platform_check_secondary',
    'L8D9B': 'platform_sec_check_range',
    'L8DB0': 'platform_sec_check_type',
    'L8DBF': 'platform_sec_land_on',
    'L8DF2': 'platform_not_found',

    # =========================================================================
    # Scroll right handler ($8DF5-$8E64)
    # =========================================================================
    'L8DF5': 'scroll_right_handler',
    'L8E00': 'scroll_right_exec',
    'L8E1F': 'scroll_right_clamp',
    'L8E48': 'scroll_right_column_loop',
    'L8E64': 'scroll_right_rts',

    # =========================================================================
    # Scroll left handler ($8E65-$8EDC)
    # =========================================================================
    'L8E65': 'scroll_left_handler',
    'L8E70': 'scroll_left_exec',
    'L8E94': 'scroll_left_calc_columns',
    'L8EC0': 'scroll_left_column_loop',
    'L8EDC': 'scroll_left_rts',

    # =========================================================================
    # Screen transition left ($8EDD-$8F38)
    # =========================================================================
    'L8EDD': 'transition_screen_left',

    # =========================================================================
    # Screen transition right ($8F39-$9044)
    # =========================================================================
    'L8F39': 'transition_screen_right',
    'L8F55': 'transition_right_attr_loop',
    'L8F85': 'transition_right_attr_step',
    'L8F91': 'transition_right_scroll',
    'L8FE6': 'transition_right_col_loop',
    'L9003': 'transition_right_col_step',
    'L902D': 'transition_right_wait_frame',
    'L903D': 'transition_right_done',

    # =========================================================================
    # Screen transition data tables ($9045-$907C)
    # =========================================================================
    'L9045': 'stage_attr_base_table',
    'L9053': 'stage_attr_mode_table',
    'L9061': 'stage_min_screen_table',
    'L906F': 'stage_max_screen_table',

    # =========================================================================
    # Full-screen nametable render ($907D-$90C8)
    # =========================================================================
    'L907D': 'render_full_nametable',
    'L9093': 'nametable_column_loop',
    'L90AF': 'nametable_direct_upload',
    'L90B4': 'nametable_advance_column',

    # =========================================================================
    # Screen transition scroll ($90C9-$9184)
    # =========================================================================
    'L90C9': 'transition_scroll_setup',
    'L90D2': 'transition_scroll_horizontal',
    'L90DF': 'transition_scroll_frame_loop',
    'L9104': 'transition_scroll_render',
    'L9115': 'transition_load_palette',
    'L9121': 'transition_palette_check',
    'L912F': 'transition_palette_copy',
    'L9147': 'transition_palette_rts',

    # =========================================================================
    # Transition palette data ($9148-$918A)
    # =========================================================================
    'L9148': 'stage_palette_offset_table',
    'L9156': 'stage_palette_src_index',
    'L9164': 'stage_palette_count',
    'L9172': 'stage_palette_data',

    # =========================================================================
    # Vertical scroll transition ($9185-$9211)
    # =========================================================================
    'L9185': 'transition_scroll_vertical',
    'L9193': 'vert_scroll_setup',
    'L91A2': 'vert_scroll_frame_loop',
    'L91BB': 'vert_scroll_update_pos',
    'L91ED': 'vert_scroll_finish',
    'L91FA': 'vert_scroll_update_entity',

    # =========================================================================
    # Vertical scroll data ($9212-$921F)
    # =========================================================================
    'L9212': 'vert_scroll_y_start',
    'L9214': 'vert_scroll_y_step',
    'L9216': 'vert_scroll_sub_step',
    'L9218': 'vert_scroll_pixel_step',
    'L921A': 'vert_scroll_y_delta',
    'L921C': 'vert_scroll_y_init',
    'L921E': 'vert_scroll_page_step',

    # =========================================================================
    # Reset entities ($9220-$925A)
    # =========================================================================
    'L9220': 'reset_entity_slots',
    'L922C': 'reset_entity_save_boss',
    'L922F': 'reset_entity_clear',
    'L9235': 'reset_entity_clear_loop',
    'L924A': 'reset_entity_clear_spawn',

    # =========================================================================
    # Entity AI dispatch ($925B-$92EF)
    # =========================================================================
    'L925B': 'entity_ai_dispatch',
    'L926B': 'entity_ai_normal_loop',
    'L926F': 'entity_ai_normal_step',
    'L9299': 'entity_ai_next_normal',
    'L92A2': 'entity_ai_special_loop',
    'L92A6': 'entity_ai_special_step',
    'L92D8': 'entity_ai_special_indirect',
    'L92E7': 'entity_ai_next_special',

    # =========================================================================
    # Entity AI dispatch tables ($92F0-$946E)
    # =========================================================================
    'L92F0': 'entity_ai_ptr_lo',
    'L9370': 'entity_ai_ptr_hi',
    'L93F0': 'entity_ai_bank_table',
    'L9470': 'entity_special_ai_ptr_lo',
    'L947F': 'entity_special_ai_ptr_hi',

    # =========================================================================
    # Enemy AI: Met (hard hat) ($9494-$9520)
    # =========================================================================
    'L9499': 'met_init_shoot',
    'L94BF': 'met_calc_aim',
    'L9501': 'met_update_timer',
    'L9521': 'met_delay_table',

    # =========================================================================
    # Enemy AI: Telly / hover enemy ($9532-$954A)
    # =========================================================================
    'L9532': 'telly_scan_targets',
    'L9540': 'telly_spawn_shot',
    'L9549': 'telly_set_timer',
    'L954B': 'telly_store_timer',

    # =========================================================================
    # Enemy AI: Scworm / conveyor ($95B5-$95CF)
    # =========================================================================
    'L95B5': 'check_entity_collision_scan',
    'L95B9': 'collision_scan_loop',
    'L95CD': 'collision_scan_next',
    'L95D0': 'collision_scan_set_active',

    # =========================================================================
    # Enemy AI: Pipi / bird ($95A8-$95B4)
    # =========================================================================
    'L95A3': 'pipi_set_timer',
    'L95A8': 'pipi_dec_timer',
    'L95B1': 'pipi_x_offset_table',
    'L95B3': 'pipi_x_page_table',

    # =========================================================================
    # Enemy AI: Friender / fire wolf ($9637-$9665)
    # =========================================================================
    'L9637': 'friender_dec_timer',
    'L963E': 'friender_x_speed_table',
    'L9646': 'friender_y_speed_table',
    'L9654': 'enemy_destroy_all',
    'L9666': 'enemy_deactivate_self',

    # =========================================================================
    # Enemy AI: Various small enemies
    # =========================================================================
    'L96C2': 'sniper_set_timer',
    'L96C7': 'sniper_dec_timer',
    'L96CB': 'sniper_x_offset_table',
    'L96CD': 'sniper_x_page_table',
    'L96CF': 'find_entity_count_check',
    'L96D3': 'find_entity_count_loop',
    'L96E1': 'find_entity_count_ok',
    'L96E3': 'find_entity_count_fail',

    # =========================================================================
    # Enemy AI: Blocky / block dropper
    # =========================================================================
    'L9731': 'blocky_set_fall_vel',
    'L9752': 'blocky_check_land',
    'L976B': 'blocky_apply_physics',

    # =========================================================================
    # Player state dispatch table ($8783-$879A)
    # =========================================================================
    'L8783': 'player_state_ptr_lo',
    'L878F': 'player_state_ptr_hi',

    # =========================================================================
    # Boss AI: Various
    # =========================================================================
    'L998D': 'boss_set_palette',
    'L998F': 'boss_palette_copy_loop',
    'L99A5': 'boss_spawn_debris',
    'L99B8': 'boss_debris_loop',
    'L99D8': 'boss_debris_set_pos',
    'L99E9': 'boss_debris_check_screen',
    'L99F1': 'boss_debris_done',
    'L99F9': 'boss_palette_data',
    'L99FF': 'boss_debris_type',
    'L9A00': 'boss_debris_anim_table',
    'L9A0C': 'boss_debris_x_table',
    'L9A25': 'boss_debris_y_table',

    # =========================================================================
    # Enemy AI: Atomic Fire enemy
    # =========================================================================
    'L9A52': 'atomic_fire_check_state',
    'L9A5E': 'atomic_fire_update',

    # =========================================================================
    # Enemy AI: Boss — Crashman
    # =========================================================================
    'L9AA8': 'crashman_path_wily',
    'L9AB0': 'crashman_check_axis',
    'L9ABD': 'crashman_check_x',
    'L9AC4': 'crashman_at_target',
    'L9AE7': 'crashman_get_direction',
    'L9AF3': 'crashman_get_direction_wily',
    'L9AF6': 'crashman_set_velocity',
    'L9B1B': 'crashman_set_hitbox',
    'L9B25': 'crashman_path_offset_table',
    'L9B2C': 'crashman_vel_y_sub_table',
    'L9B30': 'crashman_vel_y_table',
    'L9B34': 'crashman_vel_x_sub_table',
    'L9B38': 'crashman_flags_table',
    'L9B3C': 'crashman_path_len_table',
    'L9B43': 'crashman_path_data',
    'L9BBB': 'crashman_wily_path_data',
    'L9BBC': 'crashman_wily_path_entry',

    # =========================================================================
    # Enemy AI: Boss — Metalman
    # =========================================================================
    'L9C74': 'metalman_set_throw_flag',
    'L9C7F': 'metalman_physics',
    'L9CA1': 'metalman_spawn_blade',
    'L9CB6': 'metalman_blade_offset',
    'L9CB8': 'metalman_blade_set_x',
    'L9CEE': 'metalman_blade_src_table',
    'L9CFE': 'metalman_blade_flags',
    'L9D32': 'metalman_blade_y_table',
    'L9D66': 'metalman_blade_range',
    'L9D9A': 'metalman_blade_timer_table',

    # =========================================================================
    # Enemy AI: Boss — Woodman
    # =========================================================================
    'L9DFE': 'woodman_check_leaf_wall',
    'L9E06': 'woodman_at_target_x',
    'L9E16': 'woodman_walk_step',
    'L9E35': 'woodman_set_tile',
    'L9E4B': 'woodman_check_contact',
    'L9E5C': 'woodman_check_y_range',
    'L9E71': 'woodman_facing_left',
    'L9E79': 'woodman_trigger_shield',
    'L9E80': 'woodman_rts',

    # =========================================================================
    # Enemy AI: Boss — Bubbleman
    # =========================================================================
    'L9EB3': 'bubbleman_state_swim',
    'L9ED2': 'bubbleman_swim_physics',
    'L9EEE': 'bubbleman_swim_rts',
    'L9EEF': 'bubbleman_state_fall',
    'L9EFB': 'bubbleman_fall_setup',
    'L9F1C': 'bubbleman_fall_physics',

    # =========================================================================
    # Enemy AI: Boss — Quickman
    # =========================================================================
    'L9F79': 'quickman_check_timer',
    'L9FA1': 'quickman_set_timer',
    'L9FB5': 'quickman_dec_timer',
    'L9FCC': 'quickman_anim_threshold',
    'L9FE2': 'quickman_palette_set',
    'L9FE7': 'quickman_palette_loop',

    # =========================================================================
    # Enemy AI: Boss — Heatman
    # =========================================================================
    'LA019': 'heatman_spawn_fire',
    'LA028': 'heatman_dec_timer',
    'LA02B': 'heatman_check_state',
    'LA050': 'heatman_apply_physics',
    'LA06A': 'heatman_rts',
    'LA07B': 'heatman_flame_pattern',
    'LA091': 'heatman_flame_loop',
    'LA0AF': 'heatman_flame_inc',
    'LA0B4': 'heatman_flame_done',
    'LA0D1': 'heatman_deactivate_parts',
    'LA0DD': 'heatman_deactivate_more',
    'LA0F9': 'heatman_deactivate_final',
    'LA0FF': 'heatman_set_cooldown',
    'LA104': 'heatman_dec_cooldown',
    'LA108': 'heatman_palette_data',
    'LA10E': 'heatman_flame_x_offset',
    'LA11F': 'heatman_flame_data_end',
    'LA122': 'heatman_flame_y_offset',
    'LA12D': 'heatman_flame_y_data_2',

    # =========================================================================
    # Enemy AI: Boss — Airman
    # =========================================================================
    'LA14D': 'airman_dec_timer',
    'LA1F2': 'airman_set_tile_pattern',
    'LA1FD': 'airman_copy_tiles',
    'LA249': 'airman_spawn_tornado_2',
    'LA268': 'airman_rts',
    'LA26C': 'airman_y_offset_table',
    'LA270': 'airman_x_offset_table',
    'LA274': 'airman_tile_data',

    # =========================================================================
    # Enemy AI: Boss — Flashman
    # =========================================================================
    'LA308': 'flashman_stop_freeze',
    'LA31D': 'flashman_state_walk',
    'LA339': 'flashman_wall_stop',
    'LA344': 'flashman_check_shoot',
    'LA357': 'flashman_check_height',
    'LA37C': 'flashman_jump',
    'LA39E': 'flashman_state_air',
    'LA3D3': 'flashman_state_land',
    'LA3E9': 'flashman_physics',

    # =========================================================================
    # Enemy AI: Boss — various projectile spawners
    # =========================================================================
    'LA43D': 'item_2_set_timer',
    'LA442': 'item_2_dec_timer',

    # =========================================================================
    # Enemy AI: Boss — additional
    # =========================================================================
    'LA47A': 'boss_extra_physics',
    'LA4BB': 'boss_spawn_dec_timer',
    'LA4FF': 'boss_check_anim_state',
    'LA536': 'boss_random_timer',
    'LA541': 'boss_dec_timer',
    'LA544': 'boss_check_physics',
    'LA555': 'boss_misc_rts',
    'LA556': 'boss_random_timer_table',
    'LA577': 'boss_palette_flash',
    'LA582': 'boss_palette_flash_loop',
    'LA5A2': 'boss_palette_flash_timer',
    'LA5A7': 'boss_palette_flash_dec',
    'LA5D6': 'boss_palette_flash_data',

    # =========================================================================
    # Enemy AI: Boss — Wily Machine ($A630+)
    # =========================================================================
    'LA653': 'wily_machine_physics',

    # =========================================================================
    # Enemy AI: Wily capsule / dragon
    # =========================================================================
    'LA689': 'wily_capsule_attack',
    'LA6A3': 'wily_capsule_collision',
    'LA6C9': 'wily_capsule_check_bounce',
    'LA6D5': 'wily_capsule_physics',
    'LA6F0': 'wily_capsule_rts',

    # =========================================================================
    # Enemy AI: Big fish / Angler
    # =========================================================================
    'LA779': 'angler_check_bite_state',
    'LA794': 'angler_check_anim',
    'LA7A0': 'angler_dec_timer',
    'LA7CF': 'angler_physics',

    # =========================================================================
    # Enemy AI: Boss — Mecha Dragon
    # =========================================================================
    'LA877': 'mecha_dragon_fire',
    'LA88E': 'mecha_dragon_check_timer',
    'LA89C': 'mecha_dragon_spawn_fire',
    'LA8BF': 'mecha_dragon_fire_done',
    'LA8C1': 'mecha_dragon_check_state',
    'LA8E6': 'mecha_dragon_physics',
    'LA905': 'mecha_dragon_walk',
    'LA93E': 'mecha_dragon_store_screen',
    'LA946': 'mecha_dragon_collision',
    'LA955': 'mecha_dragon_check_hit',
    'LA97B': 'mecha_dragon_spawn_debris',
    'LA9A9': 'mecha_dragon_debris_loop_end',
    'LA9AF': 'mecha_dragon_debris_done',
    'LA9B6': 'mecha_dragon_rts',
    'LA9B7': 'mecha_dragon_debris_y_off',
    'LA9BA': 'mecha_dragon_debris_vel_hi',
    'LA9BD': 'mecha_dragon_debris_vel_lo',
    'LA9C0': 'mecha_dragon_fire_timer',

    # =========================================================================
    # Enemy AI: Guts Tank
    # =========================================================================
    'LA9CF': 'guts_tank_deactivate',
    'LA9D3': 'guts_tank_track_parent',

    # =========================================================================
    # Enemy AI: Picopico-kun (bouncing)
    # =========================================================================
    'LAA0C': 'picopico_stop_movement',
    'LAA21': 'picopico_check_timer',
    'LAA35': 'picopico_check_player',
    'LAA4A': 'picopico_physics',
    'LAAA1': 'picopico_state_1',
    'LAAB5': 'picopico_spawn_shot',
    'LAADC': 'picopico_advance_state',
    'LAAEA': 'picopico_dec_timer',
    'LAB01': 'picopico_state_2_timer',
    'LAB24': 'picopico_check_anim',
    'LAB30': 'picopico_apply_physics',
    'LAB34': 'picopico_random_timer',
    'LAB38': 'picopico_shot_vel_y_sub',
    'LAB3B': 'picopico_shot_vel_y_hi',
    'LAB3E': 'picopico_shot_vel_x_sub',
    'LAB41': 'picopico_shot_vel_x_hi',

    # =========================================================================
    # Enemy AI: Buebeam trap
    # =========================================================================
    'LAB58': 'buebeam_collision',
    'LAB79': 'buebeam_check_anim',
    'LAB85': 'buebeam_physics',

    # =========================================================================
    # Enemy AI: Boobeam trap turrets
    # =========================================================================
    'LABB1': 'boobeam_init',
    'LAC04': 'boobeam_dec_timer',
    'LAC0A': 'boobeam_x_offset_table',
    'LAC0C': 'boobeam_dir_flags_table',

    # =========================================================================
    # Enemy AI: Wily capsule missile
    # =========================================================================
    'LAC64': 'capsule_missile_move',
    'LAC74': 'capsule_missile_anim',
    'LAC80': 'capsule_missile_physics',
    'LAC8E': 'capsule_missile_rts',

    # =========================================================================
    # Enemy AI: Boss — explosion / self-destruct
    # =========================================================================
    'LACB6': 'boss_explode_start',
    'LACC9': 'boss_explode_spawn_loop',
    'LACFC': 'boss_explode_deactivate',
    'LAD00': 'boss_explode_flags_table',
    'LAD08': 'boss_explode_vel_y_sub',
    'LAD10': 'boss_explode_vel_y_hi',
    'LAD18': 'boss_explode_vel_x_sub',
    'LAD20': 'boss_explode_vel_x_hi',
    'LAD28': 'boss_explode_timer_table',

    # =========================================================================
    # Enemy AI: Boss projectile patterns
    # =========================================================================
    'LAD9B': 'boss_proj_physics',

    # =========================================================================
    # Enemy AI: Spinning shot / circular
    # =========================================================================
    'LADF2': 'circular_shot_dec_timer',
    'LAE09': 'circular_vel_y_sub_table',
    'LAE19': 'circular_vel_y_hi_table',
    'LAE29': 'circular_vel_x_sub_table',
    'LAE39': 'circular_flags_table',

    # =========================================================================
    # Enemy AI: Boss — phase-2 / Alien Wily
    # =========================================================================
    'LAE9B': 'alien_jump_physics',
    'LAE9E': 'alien_check_fire',
    'LAEEF': 'alien_check_descent',
    'LAEFB': 'alien_spawn_shot_loop',
    'LAF2A': 'alien_set_hover_timer',
    'LAF34': 'alien_hover_dec',
    'LAF45': 'alien_inc_timer',
    'LAF4C': 'alien_set_palette',
    'LAF50': 'alien_palette_copy_loop',
    'LAF69': 'alien_palette_data',
    'LAF7B': 'alien_shot_flags_table',
    'LAF7D': 'alien_shot_x_offset_lo',
    'LAF7F': 'alien_shot_x_offset_hi',

    # =========================================================================
    # Enemy AI: Wily machine turret
    # =========================================================================
    'LAFD5': 'turret_deactivate',
    'LAFD9': 'turret_dec_timer',

    # =========================================================================
    # Enemy AI: Boss — descent / drop
    # =========================================================================
    'LB010': 'drop_boss_advance',
    'LB014': 'drop_boss_dec_timer',
    'LB01F': 'wall_walker_init',
    'LB02F': 'wall_walker_calc_tile',
    'LB05F': 'wall_walker_flip',
    'LB067': 'wall_walker_set_speed',
    'LB07E': 'wall_walker_check_dist',
    'LB0BD': 'wall_walker_resume',
    'LB0CB': 'wall_walker_anim',
    'LB0D7': 'wall_walker_set_speed_val',
    'LB0F2': 'wall_walker_physics',
    'LB0F6': 'wall_walker_x_offset_table',

    # =========================================================================
    # Enemy AI: Sniper Joe variants
    # =========================================================================
    'LB137': 'sniper_joe_spawn_shot',
    'LB156': 'sniper_joe_store_y',
    'LB158': 'sniper_joe_store_val',
    'LB15A': 'sniper_joe_data',
    'LB172': 'sniper_joe_done',
    'LB178': 'sniper_joe_type_table',
    'LB17E': 'sniper_joe_x_offset_table',
    'LB184': 'sniper_joe_check_above',
    'LB1A1': 'sniper_joe_store_a',
    'LB1A2': 'sniper_joe_shift',
    'LB1D7': 'sniper_joe_timer_check',
    'LB1E3': 'sniper_joe_reverse',
    'LB1EF': 'sniper_joe_wall_check',
    'LB1FF': 'sniper_joe_physics',
    'LB203': 'sniper_joe_vel_fwd',
    'LB204': 'sniper_joe_vel_rev',
    'LB205': 'sniper_joe_vel_hi_fwd',
    'LB206': 'sniper_joe_vel_hi_rev',

    # =========================================================================
    # Enemy AI: Boss subunit / projectile manager
    # =========================================================================
    'LB266': 'boss_proj_mgr_set_timer',
    'LB26B': 'boss_proj_mgr_dec_timer',
    'LB26E': 'boss_proj_mgr_physics',
    'LB272': 'boss_proj_mgr_fire',
    'LB2DC': 'boss_fire_rng_mask',
    'LB2DD': 'boss_fire_rng_base',
    'LB2DE': 'boss_fire_rng_divisor',
    'LB2DF': 'boss_fire_vel_y_sub',
    'LB2E0': 'boss_fire_vel_y_hi',
    'LB2E1': 'boss_fire_y_offset',
    'LB2E2': 'boss_fire_x_offset',
    'LB2E3': 'boss_fire_x_offset_hi',
    'LB2D9': 'boss_fire_done',

    # =========================================================================
    # Enemy AI: Boss — multi-phase
    # =========================================================================
    'LB32D': 'multi_boss_physics',
    'LB335': 'multi_boss_rts',
    'LB336': 'multi_boss_fallthrough',
    'LB39A': 'multi_boss_state_2',
    'LB3A4': 'multi_boss_check_timer',
    'LB3D4': 'multi_boss_check_cycle',
    'LB3E7': 'multi_boss_set_short_timer',
    'LB3EF': 'multi_boss_dec_timer',
    'LB3F2': 'multi_boss_full_physics',
    'LB3FA': 'multi_boss_rts_2',
    'LB3FB': 'multi_boss_death_check',
    'LB40B': 'multi_boss_shot_vel_y_sub',
    'LB410': 'multi_boss_shot_vel_y_hi',
    'LB415': 'multi_boss_shot_vel_x_sub',
    'LB41A': 'multi_boss_shot_vel_x_hi',

    # =========================================================================
    # Enemy AI: Boss turret / stationary shooter
    # =========================================================================
    'LB469': 'turret_boss_advance',
    'LB48A': 'turret_boss_set_timer',
    'LB48F': 'turret_boss_dec_timer',
    'LB4C9': 'turret_boss_physics',

    # =========================================================================
    # Enemy AI: Boss — jump attack
    # =========================================================================
    'LB534': 'jump_boss_check_anim',
    'LB540': 'jump_boss_physics',
    'LB544': 'jump_boss_wall_timer',
    'LB558': 'jump_boss_wall_physics',
    'LB584': 'despawn_timer_phase_1',
    'LB5A9': 'despawn_timer_phase_2',
    'LB5B5': 'despawn_phase_3_setup',
    'LB5DE': 'despawn_timer_dec',
    'LB605': 'stage_palette_copy_loop',
    'LB626': 'stage_boss_jmp',
    'LB629': 'stage_palette_entries',

    # =========================================================================
    # Enemy AI: Boss — Wily stage specific
    # =========================================================================
    'LB661': 'wily_boss_spawn_loop',
    'LB686': 'wily_boss_setup_vel',
    'LB6CC': 'wily_boss_timer_check',
    'LB6D5': 'wily_boss_physics',
    'LB6D9': 'wily_boss_vel_table',
    'LB6DE': 'wily_boss_vel_hi_table',

    # =========================================================================
    # Enemy AI: Falling platform
    # =========================================================================
    'LB71C': 'falling_platform_physics',

    # =========================================================================
    # Enemy AI: Boss — beam weapon
    # =========================================================================
    'LB747': 'beam_boss_physics',
    'LB7B7': 'beam_pattern_check',
    'LB7CF': 'beam_pattern_spawn_loop',
    'LB7FD': 'beam_pattern_done',
    'LB808': 'beam_boss_check_anim',
    'LB814': 'beam_boss_apply_physics',

    # =========================================================================
    # Enemy AI: Boss — gravity shift
    # =========================================================================
    'LB840': 'gravity_boss_accel',
    'LB88C': 'shield_boss_rts',
    'LB88D': 'shield_boss_physics',

    # =========================================================================
    # Enemy AI: Wily Stage 4 boss setup ($B891+)
    # =========================================================================
    'LB8CC': 'wily4_palette_loop',
    'LB8E2': 'wily4_entity_init_loop',
    'LB8EF': 'wily4_entity_init_rts',
    'LB8F0': 'wily4_boss_active',
    'LB927': 'wily4_boss_phase_2',
    'LB94E': 'wily4_boss_rts',
    'LB94F': 'wily4_boss_despawn_all',
    'LB955': 'wily4_despawn_loop',
    'LB962': 'wily4_despawn_done',
    'LB971': 'wily4_timer_table',
    'LB976': 'wily4_y_pos_table',
    'LB97A': 'wily4_enemy_shared_ai',
    'LB986': 'wily4_shared_velocity',
    'LB9B1': 'wily4_shared_set_flags',
    'LB9C6': 'wily4_facing_setup',
    'LB9F4': 'wily4_pos_check_rts',
    'LB9F5': 'wily4_pos_reset_anim',

    # =========================================================================
    # Enemy AI: Wily capsule / teleporter ($BA2F+)
    # =========================================================================
    'LBA2F': 'wily_capsule_jmp_shared',
    'LBA66': 'wily_teleport_ai',
    'LBA86': 'wily_teleport_pause',
    'LBA90': 'wily_teleport_stop_vel',
    'LBAC8': 'wily_teleport_check_anim',
    'LBAD4': 'wily_teleport_set_anim',
    'LBAE2': 'wily_teleport_rts',
    'LBAE3': 'wily_teleport_timer_table',
    'LBAE7': 'wily_teleport_target_lo',
    'LBAEB': 'wily_teleport_target_hi',

    # =========================================================================
    # Enemy AI: Wily final / misc
    # =========================================================================
    'LBB06': 'wily_final_physics',
    'LBBAB': 'wily_final_x_adjust_table',
    'LBBD3': 'wily_final_apply_physics',
    'LBBE6': 'wily_final_timer_check',
    'LBBFD': 'wily_final_gravity',
    'LBC15': 'wily_final_rise_check',
    'LBC29': 'wily_final_physics_2',
    'LBC2D': 'wily_final_timer_table',
    'LBC35': 'wily_final_bank_table',
    'LBC75': 'wily_final_check_anim',
    'LBCA3': 'wily_final_check_physics',

    # =========================================================================
    # Enemy AI: Generic walkers
    # =========================================================================
    'LBCB7': 'walker_check_state',
    'LBCF1': 'walker_rts',
    'LBCF2': 'walker_stopped_state',
    'LBD00': 'walker_stopped_physics',
    'LBD04': 'walker_simple_physics',
    'LBD12': 'boss_indicator_palette',
    'LBD23': 'boss_indicator_rts',

    # =========================================================================
    # Player state subroutines ($858E-$8773)
    # =========================================================================
    'L858E': 'player_state_common_exit',
    'L85A2': 'player_state_set_weapon',
    'L85C5': 'player_state_check_land',
    'L85D0': 'player_state_jump_exit',
    'L85E6': 'player_state_to_idle',
    'L85F8': 'player_state_check_dir',
    'L861E': 'player_state_decel_speed',
    'L8634': 'player_state_speed_zero',
    'L863C': 'player_state_update_face',
    'L8642': 'player_state_run_movement',
    'L866C': 'player_state_on_ground_rts',
    'L866D': 'player_state_climbing',
    'L8683': 'player_state_climb_dir',
    'L8688': 'player_state_climb_set_weapon',
    'L86B5': 'player_ladder_state_jump',
    'L86B9': 'player_ladder_state_exit',
    'L86BC': 'player_state_ladder_idle',
    'L86C9': 'player_ladder_clear_ab',
    'L86CD': 'player_ladder_check_input',
    'L86D6': 'player_ladder_check_updown',
    'L86FE': 'player_ladder_check_left',
    'L8708': 'player_ladder_move_down',
    'L871D': 'player_ladder_set_vel',
    'L872B': 'player_ladder_check_solid',
    'L8733': 'player_ladder_store_vel',
    'L874B': 'player_ladder_to_idle',
    'L874D': 'player_ladder_set_state',
    'L875F': 'player_ladder_clear_vel',
    'L8764': 'player_ladder_exit',
    'L8768': 'player_ladder_fire_weapon',
    'L8773': 'player_ladder_fire_done',
    'L87AA': 'player_check_ladder_rts',

    # Additional tile collision
    'L8A65': 'tile_combine_result',
    'L8CEA': 'floor_set_scroll_trigger',

    # Met / enemy AI additional
    'L9514': 'met_check_state_4',
    'L951D': 'met_apply_physics',
    'L962E': 'friender_update_direction',
    'L97D3': 'shotman_check_facing',
    'L97EA': 'shotman_facing_left',
    'L97F7': 'shotman_store_position',
    'L981F': 'shotman_flip_facing',
    'L9827': 'shotman_apply_physics',
    'L985B': 'springer_spawn_shot_loop',
    'L9876': 'springer_check_anim',
    'L9882': 'springer_apply_physics',
    'L9889': 'springer_shot_vel_x_sub',
    'L988C': 'springer_shot_vel_x_hi',
    'L98BD': 'frog_dec_timer',
    'L98DF': 'frog_apply_physics',
    'L9919': 'die_spawn_part_loop',
    'L992D': 'die_spawn_part_next',
    'L994F': 'die_expand_phase',
    'L9964': 'die_expand_large',
    'L9968': 'die_expand_normal',
    'L9972': 'die_expand_set_timer',
    'L9984': 'die_expand_check_done',
    'L998C': 'die_expand_rts',

    # Crashman path data
    'L9B44': 'crashman_path_entry',
    'L9BF5': 'crashman_wily_path_mid',

    # Metalman
    'L9C86': 'metalman_hitbox_rts',

    # Boss common
    'L9FC8': 'quickman_state_table',
    'LA438': 'item_2_store_y',

    # Mecha dragon
    'LA84C': 'mecha_dragon_check_landed',
    'LA867': 'mecha_dragon_check_wall',
    'LA873': 'mecha_dragon_physics_2',
    'LAA62': 'picopico_set_hitbox',
    'LAA93': 'picopico_dec_main_timer',
    'LAA96': 'picopico_clear_anim',
    'LAA9E': 'picopico_jmp_physics',

    # Boobeam
    'LABEE': 'boobeam_set_direction',
    'LADFF': 'circular_shot_set_hitbox',

    # Wall walker additional
    'LB0F8': 'wall_walker_x_page_table',

    # Boss fire
    'LB2C6': 'boss_fire_adjust_x',

    # Multi-boss
    'LB32A': 'multi_boss_dec_main_timer',
    'LBB4C': 'beam_boss_reset_counter',
    'LBB76': 'beam_boss_check_state',
    'LBB7F': 'beam_boss_set_state',
    'LBB82': 'beam_boss_run_physics',
    'LBB97': 'beam_boss_rts',
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
        if old_label == 'LBFFF':
            continue  # Never rename LBFFF (MMC1 register target)

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

    # Count remaining LXXXX labels (excluding LBFFF and data addresses)
    remaining = set(re.findall(r'\bL[0-9A-Fa-f]{4}\b', content))
    remaining.discard('LBFFF')
    # Filter to only ones that look like bank $0E addresses ($8000-$BFFF)
    # or fixed bank addresses ($C000-$FFFF)
    code_remaining = set()
    for label in remaining:
        addr = int(label[1:], 16)
        if 0x8000 <= addr <= 0xBFFE or 0xC000 <= addr <= 0xFFFE:
            code_remaining.add(label)
    if code_remaining:
        print(f"WARNING: {len(code_remaining)} LXXXX code labels still unrenamed:")
        for label in sorted(code_remaining)[:50]:
            print(f"  {label}")


if __name__ == '__main__':
    main()
