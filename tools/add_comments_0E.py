#!/usr/bin/env python3
"""
add_comments_0E.py — Add block headers and inline comments to bank0E_game_engine.asm

This script:
  1. Reads bank0E_game_engine.asm
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

ASM_FILE = "src/bank0E_game_engine.asm"

# --- Block headers: label_name -> (description, address) ---
BLOCK_HEADERS = {
    # Cold boot / hardware init
    "wait_ppu_warmup_1": (
        "Cold Boot Entry — wait for PPU warmup, clear RAM, init MMC1",
        "$8000"
    ),
    "game_init": (
        "Game Initialization — set up PPU, load stage data, fill palettes",
        "$805F"
    ),

    # Main game loops
    "main_game_loop": (
        "Main Game Loop — per-frame update for normal stages",
        "$8171"
    ),
    "wily_spawn_gate_entities": (
        "Wily Fortress Gate — spawn gate entities from bitmask",
        "$81DE"
    ),
    "wily_game_loop": (
        "Wily Fortress Main Loop — per-frame update with gate spawning",
        "$8223"
    ),

    # Screen transitions
    "check_screen_transition": (
        "Screen Transition Check — test scroll boundaries for room changes",
        "$8278"
    ),

    # Item collection
    "item_collection_handler": (
        "Item Collection Handler — dispatch item pickup via pointer table",
        "$82D5"
    ),

    # Player state machine
    "entity_update_dispatch": (
        "Entity Update / Player State Machine — dispatch based on $2C",
        "$84EE"
    ),
    "player_state_ptr_lo": (
        "Player State Dispatch Table — 12 states (idle, walk, jump, etc.)",
        "$8783"
    ),

    # Player movement / physics
    "player_check_fire_weapon": (
        "Player Weapon Fire — check A button, fire weapon, check ladder",
        "$879B"
    ),
    "player_update_facing": (
        "Player Facing Direction — update sprite flip from D-pad input",
        "$87F2"
    ),
    "player_set_max_speed": (
        "Player Speed Control — max speed, acceleration, deceleration",
        "$880D"
    ),
    "player_horiz_movement": (
        "Player Horizontal Movement — X position update with scroll",
        "$8922"
    ),
    "player_ground_collision": (
        "Player Ground Collision — scan tiles below for solid/lava/item",
        "$8A84"
    ),
    "player_vertical_physics": (
        "Player Vertical Physics — gravity, fall limit, ceiling snap",
        "$8B83"
    ),
    "player_floor_tile_check": (
        "Player Floor Tile Check — scan floor tiles for collision type",
        "$8C6A"
    ),
    "check_platform_collision": (
        "Platform Collision — scan entity list for rideable platforms",
        "$8CF4"
    ),

    # Scroll handlers
    "scroll_right_handler": (
        "Scroll Right Handler — shift viewport right, update columns",
        "$8DF5"
    ),
    "scroll_left_handler": (
        "Scroll Left Handler — shift viewport left, update columns",
        "$8E65"
    ),
    "transition_screen_left": (
        "Screen Transition Left — full room scroll to previous screen",
        "$8EDD"
    ),
    "transition_screen_right": (
        "Screen Transition Right — full room scroll to next screen",
        "$8F39"
    ),

    # Nametable rendering
    "render_full_nametable": (
        "Full-Screen Nametable Render — upload all 32 columns to PPU",
        "$907D"
    ),
    "transition_scroll_setup": (
        "Transition Scroll Setup — configure and execute scroll animation",
        "$90C9"
    ),
    "transition_scroll_vertical": (
        "Vertical Scroll Transition — smooth scroll up/down between rooms",
        "$9185"
    ),

    # Entity management
    "reset_entity_slots": (
        "Reset Entity Slots — clear all entity data, preserve boss if active",
        "$9220"
    ),
    "entity_ai_dispatch": (
        "Entity AI Dispatch — iterate entities, call AI via pointer table",
        "$925B"
    ),
    "entity_ai_ptr_lo": (
        "Entity AI Pointer Table — 128 entries, low/high/bank for each type",
        "$92F0"
    ),

    # Enemy AI routines
    "met_init_shoot": (
        "Enemy AI: Met (Hard Hat) — hide/shoot pattern",
        "$9499"
    ),
    "telly_scan_targets": (
        "Enemy AI: Telly — hover enemy, scan and shoot",
        "$9532"
    ),
    "check_entity_collision_scan": (
        "Entity Collision Scan — check overlap between entity pairs",
        "$95B5"
    ),
    "enemy_destroy_all": (
        "Enemy Destroy — deactivate all child entities and self",
        "$9654"
    ),
    "find_entity_count_check": (
        "Find Entity Count — scan for entity type, check population limit",
        "$96CF"
    ),

    # Boss AI routines
    "boss_set_palette": (
        "Boss Palette Setup — copy palette data for boss encounter",
        "$998D"
    ),
    "crashman_path_wily": (
        "Boss AI: Crashman — pathfinding with bounce patterns",
        "$9AA8"
    ),
    "metalman_set_throw_flag": (
        "Boss AI: Metalman — blade throw with pattern tables",
        "$9C74"
    ),
    "woodman_check_leaf_wall": (
        "Boss AI: Woodman — walk, leaf shield, contact check",
        "$9DFE"
    ),
    "bubbleman_state_swim": (
        "Boss AI: Bubbleman — swim/fall physics, bubble shot",
        "$9EB3"
    ),
    "quickman_check_timer": (
        "Boss AI: Quickman — timer-based movement, boomerang throw",
        "$9F79"
    ),
    "heatman_spawn_fire": (
        "Boss AI: Heatman — flame pattern, charge attack",
        "$A019"
    ),
    "airman_dec_timer": (
        "Boss AI: Airman — tornado spawn, tile pattern update",
        "$A14D"
    ),
    "flashman_stop_freeze": (
        "Boss AI: Flashman — time stopper, walk/jump/shoot",
        "$A308"
    ),

    # Boss common routines
    "boss_extra_physics": (
        "Boss Common — extra physics, random timer, palette flash",
        "$A47A"
    ),
    "boss_palette_flash": (
        "Boss Palette Flash — cycle palette during death/hit animation",
        "$A577"
    ),

    # Wily bosses
    "wily_machine_physics": (
        "Boss AI: Wily Machine — turret spawn, physics",
        "$A653"
    ),
    "wily_capsule_attack": (
        "Boss AI: Wily Capsule — attack, collision, bounce physics",
        "$A689"
    ),
    "mecha_dragon_fire": (
        "Boss AI: Mecha Dragon — fire breath, walk, debris spawn",
        "$A877"
    ),
    "picopico_stop_movement": (
        "Boss AI: Picopico-kun — bouncing block enemy, shot spawn",
        "$AA0C"
    ),
    "boobeam_init": (
        "Boss AI: Boobeam Trap — turret initialization and firing",
        "$ABB1"
    ),
    "boss_explode_start": (
        "Boss Explosion — spawn debris ring on boss death",
        "$ACB6"
    ),
    "alien_jump_physics": (
        "Boss AI: Alien Wily — final boss hover, shot pattern",
        "$AE9B"
    ),

    # Wall walker / Sniper Joe
    "wall_walker_init": (
        "Enemy AI: Wall Walker — wall-crawling enemy with tile check",
        "$B01F"
    ),
    "sniper_joe_spawn_shot": (
        "Enemy AI: Sniper Joe — shielded soldier, shoot and walk",
        "$B137"
    ),

    # Boss projectile patterns
    "boss_proj_mgr_set_timer": (
        "Boss Projectile Manager — timer-based firing with RNG",
        "$B266"
    ),
    "multi_boss_physics": (
        "Multi-Phase Boss — state machine with timer-based phase changes",
        "$B32D"
    ),
    "turret_boss_advance": (
        "Turret Boss — stationary shooter with timer",
        "$B469"
    ),

    # Wily stage specific
    "wily4_palette_loop": (
        "Wily Stage 4 Boss — multi-turret with entity spawning",
        "$B8CC"
    ),
    "wily_capsule_jmp_shared": (
        "Wily Capsule Teleport AI — teleportation and attack pattern",
        "$BA2F"
    ),
    "wily_final_physics": (
        "Wily Final Boss — gravity, movement, and multi-phase AI",
        "$BB06"
    ),

    # Generic walkers
    "walker_check_state": (
        "Generic Walker Enemy — simple walking AI with physics",
        "$BCB7"
    ),
    "boss_indicator_palette": (
        "Boss Room Indicator — palette flash to signal boss door",
        "$BD12"
    ),
}

# --- Inline comments: (label_context, max_lines_after, code_fragment, comment) ---
INLINE_COMMENTS = [
    # Cold boot
    ("wait_ppu_warmup_1", 0, "lda     $2002", "read PPUSTATUS to clear latch"),
    ("wait_ppu_warmup_2", 0, "lda     $2002", "wait for second VBLANK"),
    ("clear_ram_loop", 0, "sta     ($00),y", "zero out RAM page"),

    # Game init
    ("game_init", 1, "jsr     nametable_init", "initialize nametable data"),
    ("game_init_check_wily", 2, "cmp     #$08", "stages 8+ are Wily fortress"),
    ("game_init_fill_weapon_ammo", 1, "lda     #$1C", "$1C = full weapon energy (28)"),
    ("game_init_set_boss_offset", 5, "stx     $B0", "boss table offset (0=Robot Master, 3=Wily)"),

    # Main game loop
    ("main_game_loop", 1, "beq     main_loop_check_start", "skip item handler if no item"),
    ("main_loop_check_start", 2, "beq     main_loop_update_entities", "START not pressed"),
    ("main_loop_update_entities", 1, "jsr     build_active_list", "scan entities within screen range"),
    ("main_loop_update_entities", 2, "jsr     entity_update_dispatch", "run player state machine"),
    ("main_loop_update_entities", 3, "jsr     update_entity_positions", "move all entities"),
    ("main_loop_update_entities", 4, "jsr     entity_spawn_scan", "spawn/despawn by scroll"),
    ("main_loop_update_entities", 5, "jsr     process_sound_and_bosses", "sound engine + boss check"),
    ("main_loop_update_entities", 6, "jsr     entity_ai_dispatch", "run enemy AI for all entities"),
    ("main_loop_update_entities", 7, "jsr     render_all_sprites", "build OAM buffer"),
    ("main_loop_wait_frame", 1, "jsr     wait_for_vblank", "wait for NMI"),

    # Wily game loop
    ("wily_game_loop", 1, "jsr     wily_spawn_gate_entities", "spawn/update gate entities"),
    ("wily_loop_wait_frame", 1, "jsr     wait_for_vblank", "wait for NMI"),

    # Screen transitions
    ("check_screen_transition", 1, "bne     check_vertical_transition", "scroll_x == 0, skip left check"),
    ("check_vertical_transition", 2, "cmp     #$03", "transition type 3 = boss entrance"),

    # Item collection
    ("health_refill_loop", 3, "cmp     #$1C", "$1C = max HP (28)"),
    ("weapon_refill_loop", 3, "cmp     #$1C", "$1C = max energy (28)"),

    # Player state machine
    ("entity_update_dispatch", 2, "beq     entity_dispatch_setup", "check pause flag bit 2"),
    ("entity_dispatch_setup", 2, "ldx     $2C", "current player state index"),
    ("entity_dispatch_setup", 5, "jmp     (jump_ptr)", "indirect jump to state handler"),

    # Player fire weapon
    ("player_fire_weapon", 1, "jsr     fire_weapon_dispatch", "call weapon fire handler"),

    # Player speed
    ("player_set_max_speed", 1, "ldx     $2C", "player state index for speed table"),

    # Player horizontal movement
    ("player_horiz_movement", 4, "beq     player_move_left_check", "bit 6 clear = facing left"),
    ("player_move_right", 6, "adc     #$00", "carry into page byte"),
    ("player_move_left_check", 4, "and     #$40", "bit 6 = facing right"),

    # Player ground collision
    ("player_ground_collision", 4, "jsr     check_vert_tile_collision", "check tile below player"),
    ("ground_check_lava", 2, "cmp     #$03", "tile type 3 = lava/spike"),

    # Player vertical physics
    ("player_apply_gravity", 4, "adc     #$00", "add gravity to Y velocity"),
    ("player_ceiling_snap", 3, "and     #$F0", "snap to 16-pixel grid"),

    # Platform collision
    ("check_platform_collision", 3, "cmp     #$10", "entity type $10+ are platforms"),
    ("platform_land_on", 3, "sta     $44", "store platform entity index"),

    # Scroll handlers
    ("scroll_right_handler", 3, "cmp     #$80", "check if player past midpoint"),
    ("scroll_right_column_loop", 1, "jsr     column_data_copy", "copy column tile data to buffer"),
    ("scroll_left_column_loop", 1, "jsr     column_data_copy", "copy column tile data to buffer"),

    # Screen transitions
    ("transition_screen_left", 1, "jsr     reset_entity_slots", "clear all entities for new room"),
    ("transition_screen_right", 1, "jsr     reset_entity_slots", "clear all entities for new room"),

    # Full nametable render
    ("render_full_nametable", 3, "cmp     #$20", "32 columns per screen"),

    # Entity reset
    ("reset_entity_slots", 2, "cmp     #$06", "state 6 = boss fight active"),
    ("reset_entity_clear_loop", 1, "sta     $0420,x", "clear entity flags (deactivate)"),

    # Entity AI dispatch
    ("entity_ai_dispatch", 3, "beq     entity_ai_normal_loop", "AA=0: normal AI mode"),
    ("entity_ai_normal_loop", 1, "ldx     #$10", "entity slot 16 = first enemy slot"),
    ("entity_ai_normal_step", 1, "lda     $0420,x", "check entity active flag (bit 7)"),
    ("entity_ai_normal_step", 9, "jmp     (jump_ptr)", "indirect jump to AI routine"),
    ("entity_ai_special_step", 1, "lda     $0420,x", "check entity active flag"),

    # Met AI
    ("met_init_shoot", 5, "jsr     entity_face_player", "face toward player"),
    ("met_calc_aim", 3, "jsr     divide_8bit", "calculate shot angle"),

    # Friender AI
    ("friender_dec_timer", 1, "dec     $04E0,x", "decrement movement timer"),

    # Boss common
    ("boss_set_palette", 2, "sta     $0356,x", "write to palette RAM"),
    ("boss_palette_flash", 8, "cmp     #$04", "4 flash cycles = death"),

    # Crashman
    ("crashman_set_velocity", 3, "sta     $0620,x", "set X sub-pixel velocity"),

    # Wily capsule
    ("wily_capsule_collision", 3, "jsr     check_horiz_tile_collision", "check wall collision"),

    # Mecha dragon
    ("mecha_dragon_fire", 3, "jsr     spawn_entity_from_parent", "spawn fire breath entity"),
    ("mecha_dragon_collision", 3, "jsr     check_horiz_tile_collision", "check wall collision"),

    # Picopico-kun
    ("picopico_check_timer", 2, "dec     $04E0,x", "decrement AI timer"),
    ("picopico_spawn_shot", 3, "jsr     spawn_entity_from_parent", "spawn projectile"),

    # Boobeam
    ("boobeam_init", 3, "sta     $06C0,x", "set turret HP"),

    # Boss explosion
    ("boss_explode_start", 3, "lda     #$08", "8 debris entities"),
    ("boss_explode_spawn_loop", 3, "jsr     spawn_entity_from_parent", "spawn debris piece"),

    # Alien Wily
    ("alien_check_fire", 3, "jsr     spawn_entity_from_parent", "spawn alien shot"),
    ("alien_set_palette", 3, "sta     $0356,x", "write alien palette"),

    # Wall walker
    ("wall_walker_calc_tile", 5, "jsr     lookup_tile_from_map", "check tile ahead"),
    ("wall_walker_flip", 2, "eor     #$40", "flip facing direction"),

    # Sniper Joe
    ("sniper_joe_spawn_shot", 3, "jsr     spawn_entity_from_parent", "spawn bullet"),

    # Wily stage 4
    ("wily4_entity_init_loop", 1, "jsr     find_entity_scan", "find unused entity slot"),
    ("wily4_boss_phase_2", 3, "lda     wily4_timer_table,y", "look up spawn timing"),

    # Walker
    ("walker_check_state", 3, "jsr     apply_entity_physics", "apply standard physics"),
    ("walker_simple_physics", 1, "jsr     apply_simple_physics", "apply simple movement"),

    # Data table labels
    ("stage_bank_table", 0, ".byte", "bank index per stage (0-14)"),
    ("wily_gate_anim_table", 0, ".byte", "animation frame per gate position"),
    ("scroll_left_mask_table", 0, "rts", None),
    ("scroll_right_mask_table", 0, ".byte", "bitmask for right scroll boundary"),
    ("item_handler_ptr_lo", 0, "cpx", None),
    ("item_handler_ptr_hi", 0, ".byte", "item handler pointer table (high)"),
    ("player_state_ptr_lo", 0, "php", None),
    ("player_state_ptr_hi", 0, ".byte", "player state pointer table (high)"),
    ("decel_rate_table", 0, ".byte", "deceleration rate per state"),
    ("max_speed_hi_table", 0, ".byte", "max speed high byte per state"),
    ("max_speed_lo_table", 0, ".byte", "max speed low byte per state"),
    ("gravity_hi_table", 0, ".byte", "gravity acceleration per mode"),
    ("tile_type_flags", 0, ".byte", "tile type collision flags"),
    ("floor_conveyor_type_table", 0, ".byte", "conveyor belt direction per tile"),
    ("stage_attr_base_table", 0, ".byte", "attribute base offset per stage"),
    ("stage_attr_mode_table", 0, ".byte", "attribute mode per stage"),
    ("stage_min_screen_table", 0, ".byte", "minimum screen index per stage"),
    ("stage_max_screen_table", 0, ".byte", "maximum screen index per stage"),
    ("stage_palette_offset_table", 0, ".byte", "palette offset per stage"),
    ("stage_palette_data", 0, ".byte", "palette color entries for transitions"),
    ("vert_scroll_y_start", 0, ".byte", "vertical scroll start positions"),
    ("entity_ai_ptr_lo", 0, ".byte", "entity AI routine pointer (low bytes)"),
    ("entity_ai_ptr_hi", 0, ".byte", "entity AI routine pointer (high bytes)"),
    ("entity_ai_bank_table", 0, ".byte", "bank for each AI routine (0=local)"),
    ("entity_special_ai_ptr_lo", 0, ".byte", "special AI pointer (low bytes)"),
    ("entity_special_ai_ptr_hi", 0, ".byte", "special AI pointer (high bytes)"),
    ("met_delay_table", 0, ".byte", "Met hide/shoot delay timings"),
    ("friender_x_speed_table", 0, ".byte", "Friender X speed per animation frame"),
    ("friender_y_speed_table", 0, ".byte", "Friender Y speed per animation frame"),
    ("crashman_path_data", 0, ".byte", "Crashman movement path data"),
    ("crashman_wily_path_data", 0, ".byte", "Crashman Wily stage path data"),
    ("metalman_blade_src_table", 0, ".byte", "Metalman blade source position table"),
    ("metalman_blade_timer_table", 0, ".byte", "Metalman blade throw timing"),
    ("boss_palette_data", 0, ".byte", "boss palette colors per boss type"),
    ("boss_debris_anim_table", 0, ".byte", "boss debris animation frames"),
    ("boss_explode_flags_table", 0, ".byte", "explosion entity flags per slot"),
    ("boss_explode_vel_y_sub", 0, ".byte", "explosion Y velocity (sub-pixel)"),
    ("boss_explode_vel_x_sub", 0, ".byte", "explosion X velocity (sub-pixel)"),
    ("boss_palette_flash_data", 0, ".byte", "palette flash color cycle data"),
    ("heatman_palette_data", 0, ".byte", "Heatman palette animation data"),
    ("heatman_flame_x_offset", 0, ".byte", "Heatman flame X offset per slot"),
    ("heatman_flame_y_offset", 0, ".byte", "Heatman flame Y offset per slot"),
    ("airman_tile_data", 0, ".byte", "Airman tile pattern data"),
    ("quickman_anim_threshold", 0, ".byte", "Quickman animation speed thresholds"),
    ("quickman_state_table", 0, ".byte", "Quickman state lookup table"),
    ("boss_random_timer_table", 0, ".byte", "random timer values for boss AI"),
    ("picopico_shot_vel_y_sub", 0, ".byte", "Picopico shot Y velocity (sub-pixel)"),
    ("picopico_shot_vel_x_sub", 0, ".byte", "Picopico shot X velocity (sub-pixel)"),
    ("boobeam_x_offset_table", 0, ".byte", "Boobeam turret X offset per slot"),
    ("boobeam_dir_flags_table", 0, ".byte", "Boobeam shot direction flags"),
    ("boss_fire_rng_mask", 0, ".byte", "boss fire RNG bitmask"),
    ("multi_boss_shot_vel_y_sub", 0, ".byte", "multi-boss shot Y velocity table"),
    ("multi_boss_shot_vel_x_sub", 0, ".byte", "multi-boss shot X velocity table"),
    ("wily4_timer_table", 0, ".byte", "Wily stage 4 spawn timer table"),
    ("wily4_y_pos_table", 0, ".byte", "Wily stage 4 Y position table"),
    ("wily_teleport_timer_table", 0, ".byte", "Wily teleport timing table"),
    ("wily_final_timer_table", 0, ".byte", "Wily final boss timer table"),
    ("wily_final_bank_table", 0, ".byte", "Wily final boss bank switch table"),
    ("wall_walker_x_offset_table", 0, ".byte", "Wall walker X check offset"),
    ("sniper_joe_type_table", 0, ".byte", "Sniper Joe variant types"),
    ("sniper_joe_x_offset_table", 0, ".byte", "Sniper Joe shot X offset"),
    ("circular_vel_y_sub_table", 0, ".byte", "circular shot Y velocity table"),
    ("circular_vel_x_sub_table", 0, ".byte", "circular shot X velocity table"),
    ("circular_flags_table", 0, ".byte", "circular shot direction flags"),
    ("alien_shot_flags_table", 0, ".byte", "Alien Wily shot direction flags"),
    ("alien_palette_data", 0, ".byte", "Alien Wily palette cycle data"),
    ("wily_boss_vel_table", 0, ".byte", "Wily boss velocity table"),
    ("mecha_dragon_debris_y_off", 0, ".byte", "Mecha Dragon debris Y offset"),
    ("mecha_dragon_fire_timer", 0, ".byte", "Mecha Dragon fire timing table"),
    ("stage_palette_entries", 0, ".byte", "stage palette entries for boss rooms"),
    ("wily_door_bank_table", 0, "rts", None),
    ("sniper_x_offset_table", 0, ".byte", "sniper shot X offset per direction"),
    ("sniper_x_page_table", 0, ".byte", "sniper shot X page per direction"),
    ("springer_shot_vel_x_sub", 0, ".byte", "Springer shot X velocity table"),
    ("palette_color_data", 0, "and", None),
]


def add_comment_to_line(line, comment):
    """Add a trailing comment to a line at column 40+, preserving existing content.
    Only adds if the line doesn't already have a comment."""
    if ";" in line:
        return line

    stripped = line.rstrip()
    if not stripped:
        return line

    min_col = 40
    current_len = len(stripped)
    if current_len >= min_col:
        padded = stripped + " "
    else:
        padded = stripped + " " * (min_col - current_len)

    return padded + "; " + comment


def has_block_header_nearby(lines, label_line_idx):
    """Check if there's a ; ===== pattern within 3 lines above the label."""
    start = max(0, label_line_idx - 3)
    for i in range(start, label_line_idx):
        if "; =====" in lines[i]:
            return True
    return False


def make_block_header(label_name, description, address):
    """Create a block header string."""
    title = f"{label_name} -- {description} ({address})"
    return (
        f"; =============================================================================\n"
        f"; {title}\n"
        f"; =============================================================================\n"
    )


def find_label_line(lines, label_name):
    """Find the line index where a label is defined."""
    pattern = re.compile(rf'^{re.escape(label_name)}:')
    for i, line in enumerate(lines):
        if pattern.match(line.lstrip()):
            return i
    return None


def process_file():
    with open(ASM_FILE, "r") as f:
        lines = f.readlines()

    lines = [line.rstrip("\n") for line in lines]

    # Phase 1: Build label index
    label_positions = {}
    label_pattern = re.compile(r'^([a-z_][a-z0-9_]*):')
    for i, line in enumerate(lines):
        m = label_pattern.match(line)
        if m:
            label_positions[m.group(1)] = i

    # Phase 2: Add inline comments
    inline_count = 0
    for (label_ctx, max_offset, code_frag, comment) in INLINE_COMMENTS:
        if comment is None:
            continue
        if label_ctx not in label_positions:
            continue

        label_idx = label_positions[label_ctx]

        if max_offset == 0:
            line = lines[label_idx]
            if code_frag in line and ";" not in line:
                lines[label_idx] = add_comment_to_line(line, comment)
                inline_count += 1
            continue

        for i in range(label_idx, min(label_idx + max_offset + 1, len(lines))):
            line = lines[i]
            code_part = line.split(";")[0] if ";" in line else line
            if code_frag in code_part and ";" not in line:
                lines[i] = add_comment_to_line(line, comment)
                inline_count += 1
                break

    # Phase 3: Add block headers
    insertions = []

    for label_name, (description, address) in BLOCK_HEADERS.items():
        if label_name not in label_positions:
            continue
        label_idx = label_positions[label_name]
        if has_block_header_nearby(lines, label_idx):
            continue

        header = make_block_header(label_name, description, address)
        insertions.append((label_idx, header))

    insertions.sort(key=lambda x: x[0], reverse=True)

    for line_idx, header in insertions:
        header_lines = header.rstrip("\n").split("\n")
        if line_idx > 0 and lines[line_idx - 1].strip():
            header_lines.insert(0, "")
        for j, hl in enumerate(header_lines):
            lines.insert(line_idx + j, hl)

    # Phase 4: Write output
    with open(ASM_FILE, "w") as f:
        for line in lines:
            f.write(line + "\n")

    print(f"Done. Processed {ASM_FILE}")
    print(f"  Block headers added: {len(insertions)}")
    print(f"  Inline comments added: {inline_count}")


if __name__ == "__main__":
    process_file()
