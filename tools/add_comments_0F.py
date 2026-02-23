#!/usr/bin/env python3
"""
add_comments_0F.py — Add block headers and inline comments to bank0F_fixed.asm

This script:
  1. Reads bank0F_fixed.asm
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

ASM_FILE = "src/bank0F_fixed.asm"

# ─── Block headers: label_name → (description, address) ─────────────────────
BLOCK_HEADERS = {
    "wait_multiple_frames": ("Wait A frames calling wait_for_vblank in a loop", "$C100"),
    "boss_death_sequence": ("Boss defeat sequence — explosions, score, screen fade", "$C10B"),
    "boss_intro_sequence": ("Boss intro — health bar fill and Wily fortress check", "$C1F0"),
    "reset_sound_state": ("Reset all sound/music state variables", "$C289"),
    "nametable_column_upload": ("Upload nametable columns from stage bank to PPU", "$C2D2"),
    "run_one_game_frame": ("Execute one frame: entities, sound, rendering, scroll", "$C352"),
    "clear_entities_and_run": ("Clear entity slots 0-31, then run sound and scroll", "$C386"),
    "setup_explosion_array": ("Set up 12 explosion entities around boss position", "$C393"),
    "palette_anim_update": ("Update palette animation cycling", "$C427"),
    "chr_upload_entry": ("Upload CHR tile data from stage banks to CHR-RAM", "$C487"),
    "find_active_entity_slot": ("Scan entity slots for an unused one", "$C575"),
    "process_sound_and_bosses": ("Process sound engine and check boss encounter", "$C5A9"),
    "entity_spawn_scan": ("Scan stage data and spawn/despawn entities based on scroll", "$C658"),
    "entity_activate": ("Activate an enemy entity from stage spawn data", "$C753"),
    "entity_activate_secondary": ("Activate a secondary entity from spawn data", "$C7CC"),
    "activate_primary_entity": ("Activate an enemy entity from stage spawn data", "$C753"),
    "activate_secondary_entity": ("Activate a secondary entity from spawn data", "$C7CC"),
    "divide_8bit": ("8-bit unsigned division: $01/$02 -> quotient $03", "$C84E"),
    "divide_16bit": ("16-bit unsigned division: $0A:$0B / $0C:$0D -> $0E:$0F", "$C874"),
    "lookup_cached_tile": ("Look up tile collision from cached active entity list", "$CBA2"),
    "lookup_tile_from_map": ("Look up tile collision type from stage metatile map", "$CBC3"),
    "clear_oam_buffer": ("Fill OAM buffer with $F8 (hide all sprites)", "$CC6C"),
    "render_all_sprites": ("Main sprite rendering — build OAM buffer from entity data", "$CC77"),
    "render_entity_normal": ("Render a normal entity's sprites to OAM", "$CDE7"),
    "render_weapon_normal": ("Render a weapon entity's sprites to OAM", "$CEF9"),
    "render_hp_bars": ("Render player and boss HP bars", "$CF5D"),
    "update_entity_positions": ("Update screen-relative positions for all active entities", "$DCD0"),
    "fire_weapon_buster": ("Fire Mega Buster — create bullet projectile", "$D332"),
    "weapon_set_base_type": ("Set weapon's base entity type from current weapon ID", "$D3A8"),
    "weapon_spawn_projectile": ("Spawn a projectile entity at player position", "$D3E0"),
    "check_player_collision": ("Check if an enemy entity touches the player (contact damage)", "$E55A"),
    "check_weapon_collision": ("Check if a weapon projectile hits an enemy entity", "$E5EC"),
    "apply_entity_physics": ("Apply velocity to entity position, handle bounds checking", "$EEEF"),
    "apply_entity_physics_alt": ("Alternate physics — used for weapons/projectiles", "$EFB3"),
    "check_vert_tile_collision": ("Check vertical tile collision and snap to surface", "$F02C"),
    "check_horiz_tile_collision": ("Check horizontal tile collision and snap to surface", "$F0CF"),
    "item_drop_rng": ("Random item drop on enemy death", "$F25A"),
    "cold_boot_init": ("Cold boot initialization — set up PPU and jump to game engine", "$F2D1"),
}

# ─── Inline comments: (label_name or "line_number", pattern) → comment ──────
# These match specific instruction lines and add a trailing comment.
# We use a list of (label_context, offset_from_label, comment) or
# direct (line_match_pattern, comment) approaches.
#
# Strategy: we match lines by their content (after stripping existing comments).
# Each rule: (label_context, instruction_fragment, comment)
# label_context: if set, only apply within ~60 lines after this label
# instruction_fragment: must appear in the code portion of the line
# comment: the text to add

# For inline comments, we'll use a targeted approach:
# (label_name, max_lines_after, code_fragment, comment)
# where code_fragment must appear in the instruction part (before any ;)
INLINE_COMMENTS = [
    # --- wait_multiple_frames ---
    # (already well-commented)

    # --- boss_death_sequence ---
    ("boss_death_sequence", 2, "jsr     bank_switch_enqueue", "queue sound effect"),
    ("boss_death_sequence", 10, "sta     $36", None),  # skip, context-dependent
    ("boss_death_run_frame", 5, "cmp     #$10", "16 frames of explosions"),
    ("boss_death_run_frame", 8, "jsr     setup_explosion_array", "spawn final explosion ring"),
    ("boss_death_delay_step", 2, "jsr     run_one_game_frame", "run game frame during delay"),
    ("boss_death_finish", 5, "jsr     bank_switch", "switch to game engine bank"),
    ("boss_death_finish", 3, "lda     #$0E", "switch to game engine bank"),

    # --- boss_intro_sequence ---
    ("boss_intro_sequence", 1, "jsr     reset_sound_state", "silence music for intro"),
    ("boss_intro_done", 5, "sta     $2000", "write PPUCTRL"),
    ("boss_intro_done", 8, "sta     $2001", "write PPUMASK"),
    ("boss_intro_done", 12, "lda     boss_beaten_mask_lo,x", "mark this boss as beaten"),

    # --- reset_sound_state ---
    ("reset_sound_state", 3, "sta     $05AA", "clear sound channel state"),
    ("reset_sound_state", 7, "lda     #$FE", "set boss HP to pre-intro value"),

    # --- nametable_column_upload ---
    ("nametable_column_upload", 1, "lda     #$09", "switch to bank $09 (scroll data)"),

    # --- run_one_game_frame ---
    ("run_one_game_frame", 1, "lda     #$0E", "switch to game engine bank"),
    ("run_one_game_frame", 5, "sta     $4B", "set invincibility frame"),
    ("run_one_game_frame", 6, "jsr     update_entity_positions", "move all entities"),
    ("run_one_game_frame", 7, "jsr     entity_spawn_scan", "spawn/despawn entities"),
    ("run_one_game_frame", 8, "jsr     process_sound_and_bosses", "process sound + boss check"),
    ("run_one_game_frame", 9, "jsr     banked_sound_process", "run sound driver"),
    ("run_sound_and_scroll", 1, "jsr     render_all_sprites", "build OAM buffer"),
    ("game_frame_done", 1, "jsr     wait_for_vblank", "wait for NMI and read input"),

    # --- setup_explosion_array ---
    ("setup_explosion_array", 7, "lda     #$25", "explosion entity type"),
    ("explosion_setup_loop", 2, "sta     $0420,x", "set entity flags (active)"),

    # --- palette_anim_update ---
    ("palette_anim_update", 1, "lda     $AA", "check special mode flag"),
    ("palette_anim_update", 3, "lda     $0355", "check palette anim frame count"),
    ("palette_anim_copy_loop", 1, "lda     $0376,x", "copy from palette animation frames"),
    ("palette_anim_copy_loop", 2, "sta     $0356,y", "write to active palette RAM"),

    # --- chr_upload_entry ---
    ("chr_upload_byte_loop", 1, "lda     (jump_ptr),y", "read CHR byte from bank"),
    ("chr_upload_byte_loop", 2, "sta     $2007", "write to CHR-RAM via PPUDATA"),

    # --- find_active_entity_slot ---
    ("find_active_entity_slot", 1, "lda     $0420,x", "check entity flags (bit 7=active)"),

    # --- process_sound_and_bosses ---
    ("process_sound_and_bosses", 1, "lda     $B1", "check boss HP / intro state"),
    ("process_sound_and_bosses", 3, "lda     #$0B", "switch to game logic bank"),
    ("process_sound_and_bosses", 4, "jsr     banked_entry_alt", "call entity AI update"),
    ("process_sound_and_bosses", 5, "lda     #$0E", "switch back to game engine"),
    ("process_sound_and_bosses", 7, "lda     $05AA", "check sound trigger flag"),
    ("process_sound_and_bosses", 9, "lda     $2A", "check current stage index"),
    ("process_sound_jump_intro", 1, "jmp     boss_intro_sequence", "start boss intro"),

    # --- entity_spawn_scan ---
    ("entity_spawn_scan", 2, "and     #$07", "mask to stage bank index 0-7"),
    ("entity_spawn_scan", 3, "jsr     bank_switch", "switch to current stage bank"),
    ("spawn_scan_done", 1, "lda     #$0E", "switch back to game engine"),

    # --- activate_primary_entity ---
    ("activate_primary_entity", 3, "cmp     $0100,x", "check for duplicate spawn"),
    ("activate_primary_entity", 5, "jsr     find_empty_entity_slot", "find free entity slot"),
    ("entity_init_from_type", 1, "sta     $0410,x", "store enemy type ID"),
    ("entity_init_from_type", 4, "lda     entity_flags_table,y", "look up default entity flags"),
    ("entity_init_from_type", 5, "sta     $0430,x", "store entity spawn flags"),
    ("entity_init_from_type", 6, "lda     entity_ai_behavior_tbl,y", "look up AI behavior index"),
    ("entity_init_from_type", 7, "sta     $06F0,x", "store entity AI behavior"),
    ("entity_init_from_type", 8, "lda     #$14", "default entity timer (20 frames)"),

    # --- divide_8bit ---
    ("divide_8bit", 3, "sta     $04", "clear remainder high"),
    ("div8_setup", 1, "ldy     #$08", "8 bits to process"),

    # --- divide_16bit ---
    ("div16_setup", 1, "ldy     #$10", "16 bits to process"),

    # --- lookup_tile_from_map ---
    ("lookup_tile_from_map", 2, "and     #$07", "stage bank = stage index & 7"),
    ("lookup_tile_from_map", 3, "jsr     bank_switch", "switch to stage data bank"),
    ("tile_lookup_done", 1, "lda     #$0E", "switch back to game engine"),

    # --- clear_oam_buffer ---
    ("clear_oam_buffer", 1, "lda     #$F8", "$F8 = off-screen Y (hide sprite)"),
    ("clear_oam_loop", 1, "sta     $0200,x", "write $F8 to OAM Y position"),

    # --- render_all_sprites ---
    ("render_all_sprites", 1, "lda     #$0A", "switch to sound data bank"),
    ("render_all_sprites", 2, "jsr     bank_switch", "bank $0A has sprite def ptrs"),
    ("render_all_sprites", 3, "jsr     clear_oam_buffer", "clear all sprites first"),
    ("render_even_frame", 1, "lda     $1C", "frame counter (odd/even toggle)"),
    ("render_sprites_done", 1, "lda     #$0E", "switch back to game engine"),

    # --- render_entity_normal ---
    ("render_entity_normal", 2, "lda     $0420,x", "check entity active flag"),

    # --- render_hp_bars ---
    ("render_hp_bars", 1, "lda     $06C0", "player HP (entity slot 0)"),

    # --- update_entity_positions ---
    ("update_entity_positions", 1, "ldx     #$0F", "start at entity slot 15"),
    ("update_entity_loop", 2, "lda     $0420,x", "check if entity is active"),
    ("update_entity_loop", 8, "sbc     $1F", "subtract scroll X for screen pos"),
    ("update_entity_loop", 9, "sta     $06E0,x", "store screen-relative X"),
    ("update_entity_loop", 10, "jsr     apply_entity_physics", "apply velocity and gravity"),

    # --- fire_weapon_buster ---
    ("fire_weapon_buster", 1, "lda     #$26", "sound effect: buster shot"),
    ("fire_weapon_buster", 2, "jsr     bank_switch_enqueue", "queue buster sound"),
    ("fire_weapon_buster", 7, "jsr     weapon_set_base_type", "set player animation type"),
    ("fire_weapon_buster", 10, "lda     #$6F", "invincibility timer duration"),
    ("fire_weapon_buster", 11, "sta     $4B", "set invincibility timer"),
    ("fire_setup_projectile", 1, "lda     #$80", "active flag"),
    ("fire_setup_projectile", 2, "sta     $0420,x", "activate projectile entity"),
    ("fire_setup_projectile", 3, "lda     #$24", "buster projectile entity type"),

    # --- weapon_set_base_type ---
    ("weapon_set_base_type", 1, "ldx     $2C", "current weapon select index"),
    ("weapon_set_base_type", 3, "lda     weapon_base_type_tbl,x", "look up base sprite type"),

    # --- weapon_spawn_projectile ---
    ("weapon_spawn_projectile", 1, "lda     projectile_type_tbl,y", "entity type for this weapon"),
    ("weapon_spawn_projectile", 6, "ora     projectile_flags_tbl,y", "merge weapon entity flags"),
    ("weapon_spawn_set_y", 1, "lda     $04A0", "copy player Y position"),

    # --- check_player_collision ---
    ("check_player_collision", 3, "lda     $2C", "weapon select (0=no weapon out)"),
    ("check_player_collision", 7, "lda     $F9", "boss fight active flag"),
    ("player_coll_check_range", 1, "ldy     $06E0,x", "entity screen-relative X"),
    ("player_coll_check_range", 2, "cmp     contact_damage_range_x_tbl,y", "compare to hitbox width"),
    ("player_coll_check_y", 1, "cmp     contact_damage_range_y_tbl,y", "compare to hitbox height"),
    ("player_coll_kill", 3, "jmp     boss_death_sequence", "player died — run death seq"),
    ("player_coll_knockback", 5, "jsr     fire_weapon_buster", "knockback: reset weapon state"),

    # --- check_weapon_collision ---
    ("check_weapon_collision", 5, "ldx     #$09", "start scanning from weapon slot 9"),
    ("weapon_coll_check_range_x", 1, "cmp     contact_damage_range_x_tbl,y", "compare X distance to hitbox"),
    ("weapon_coll_check_range_y", 1, "cmp     contact_damage_range_y_tbl,y", "compare Y distance to hitbox"),
    ("weapon_collision_dispatch", 1, "ldy     $A9", "current weapon ID for handler"),
    ("weapon_collision_dispatch", 2, "lda     weapon_handler_ptr_lo,y", "dispatch to weapon handler"),
    ("weapon_collision_dispatch", 5, "jmp     (jump_ptr)", "indirect jump to handler"),

    # --- apply_entity_physics ---
    ("apply_entity_physics", 2, "lda     $04C0,x", "Y sub-pixel position"),
    ("apply_entity_physics", 3, "sbc     $0660,x", "subtract Y velocity (sub-pixel)"),
    ("apply_entity_physics", 5, "lda     $04A0,x", "Y pixel position"),
    ("apply_entity_physics", 6, "sbc     $0640,x", "subtract Y velocity (whole)"),
    ("physics_check_gravity", 1, "lda     $0420,x", "check entity flags"),
    ("physics_check_gravity", 2, "and     #$04", "bit 2 = gravity enabled"),
    ("physics_move_left", 1, "lda     $0420,x", "check facing direction"),
    ("physics_move_left", 2, "and     #$40", "bit 6 = facing right"),
    ("physics_out_of_bounds", 1, "lsr     $0420,x", "deactivate entity (clear bit 7)"),

    # --- apply_entity_physics_alt ---
    ("apply_entity_physics_alt", 4, "and     #$03", "check contact/weapon bits"),
    ("apply_entity_physics_alt", 7, "and     #$01", "bit 0 = contact damage"),
    ("apply_entity_physics_alt", 9, "jsr     check_player_collision", "test player contact"),
    ("apply_entity_physics_alt", 12, "and     #$02", "bit 1 = weapon collidable"),
    ("apply_entity_physics_alt", 14, "jsr     check_weapon_collision", "test weapon hits"),
    ("apply_entity_physics_alt", 16, "jsr     item_drop_rng", "roll for item drop"),

    # --- check_vert_tile_collision ---
    ("check_vert_tile_collision", 3, "lda     $0640,x", "Y velocity (direction)"),
    ("vert_coll_process", 2, "lda     tile_solid_lookup_tbl,y", "check if tile is solid"),
    ("vert_coll_snap_up", 1, "lda     $04A0,x", "get entity Y position"),

    # --- check_horiz_tile_collision ---
    ("check_horiz_tile_collision", 1, "lda     $04A0,x", "entity Y position"),
    ("check_horiz_tile_collision", 5, "lda     $0420,x", "check facing direction"),
    ("check_horiz_tile_collision", 6, "and     #$40", "bit 6 = facing right"),
    ("horiz_coll_process", 2, "lda     tile_solid_lookup_tbl,y", "check if tile is solid"),

    # --- item_drop_rng ---
    ("item_drop_rng", 1, "lda     $B1", "check boss state (no drops during boss)"),
    ("item_drop_calc", 1, "lda     $4A", "read RNG seed"),
    ("item_drop_calc", 4, "jsr     divide_8bit", "divide RNG by 100"),
    ("item_drop_calc", 5, "lda     $CB", "check difficulty flag"),

    # --- Data table comments ---
    ("boss_beaten_mask_lo", 0, ".byte", "bitmask for each boss (low byte)"),
    ("boss_beaten_mask_hi", 0, ".byte", "bitmask for each boss (high byte)"),
    ("entity_flags_table", 0, ".byte", "default flags per entity type"),
    ("entity_hitbox_width_idx_tbl", 0, ".byte", "hitbox width table index per type"),
    ("entity_hitbox_height_idx_tbl", 0, ".byte", "hitbox height table index per type"),
    ("entity_ai_behavior_tbl", 0, ".byte", "AI behavior index per entity type"),
    ("weapon_base_type_tbl", 0, ".byte", "base sprite type per weapon ID"),
    ("projectile_type_tbl", 0, ".byte", "entity type for each projectile"),
    ("projectile_flags_tbl", 0, ".byte", "entity flags for each projectile"),
    ("projectile_xvel_tbl", 0, ".byte", "X velocity per projectile type"),
    ("projectile_yvel_tbl", 0, ".byte", "Y velocity per projectile type"),
    ("projectile_damage_type_tbl", 0, ".byte", "damage type per projectile"),
    ("contact_damage_range_x_tbl", 0, ".byte", "hitbox X range per entity type"),
    ("contact_damage_to_player_tbl", 0, ".byte", "damage to player per entity type"),
    ("weapon_damage_table", 0, ".byte", "weapon damage values (normal)"),
    ("weapon_dispatch_lo_tbl", 0, ".byte", "weapon handler ptr low bytes"),
    ("weapon_dispatch_hi_tbl", 0, ".byte", "weapon handler ptr high bytes"),
    ("weapon_handler_ptr_lo", 0, ".byte", "collision handler ptr low bytes"),
    ("weapon_handler_ptr_hi", 0, ".byte", "collision handler ptr high bytes"),
    ("stage_collision_table", 0, ".byte", "tile collision types per stage"),
    ("tile_solid_flag_tbl", 0, ".byte", "solid flag per collision type"),
    ("tile_solid_lookup_tbl", 0, ".byte", "solid flag lookup per tile type"),
    ("explosion_offset_y_tbl", 0, ".byte", "Y offsets for boss explosion pattern"),
    ("explosion_offset_x_lo_tbl", 0, ".byte", "X offsets (low) for explosion pattern"),
    ("explosion_offset_x_hi_tbl", 0, ".byte", "X offsets (high) for explosion pattern"),
    ("explosion_xvel_sub_tbl", 0, ".byte", "explosion X velocity (sub-pixel)"),
    ("explosion_xvel_tbl", 0, ".byte", "explosion X velocity (whole pixel)"),
    ("explosion_yvel_sub_tbl", 0, ".byte", "explosion Y velocity (sub-pixel)"),
    ("explosion_yvel_tbl", 0, ".byte", "explosion Y velocity (whole pixel)"),
    ("explosion_flags_tbl", 0, ".byte", "explosion facing/flip flags"),
    ("nametable_init_data", 0, ".byte", "initial nametable setup params"),
    ("nametable_bank_table", 0, ".byte", "column data VRAM addr high per index"),
    ("nametable_addr_table", 0, ".byte", "column data VRAM addr low per index"),
    ("hp_y_positions_tbl", 0, ".byte", "Y positions for HP bar sprites"),
    ("hp_tile_ids_tbl", 0, ".byte", "tile IDs for HP bar fill levels"),
    ("weapon_palette_data", 0, ".byte", "palette entries per weapon type"),
    ("sprite_def_ptr_lo", 0, ".byte", "sprite def pointer table (low bytes)"),
    ("sprite_def_ptr_hi", 0, ".byte", "sprite def pointer table (high bytes)"),
    ("wall_solid_flag_tbl", 0, ".byte", "wall collision solid flags"),
    ("weapon_range_offset_tbl", 0, ".byte", "hitbox table offset per damage type"),
    ("entity_special_dispatch_lo", 0, ".byte", "weapon entity dispatch (low bytes)"),
    ("entity_special_dispatch_hi", 0, ".byte", "weapon entity dispatch (high bytes)"),
]


def add_comment_to_line(line, comment):
    """Add a trailing comment to a line at column 40+, preserving existing content.
    Only adds if the line doesn't already have a comment."""
    # Don't add if line already has a comment
    if ";" in line:
        return line

    # Don't add to empty/blank lines or lines that are just labels with nothing else
    stripped = line.rstrip()
    if not stripped:
        return line

    # Calculate padding to reach column 40
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
    title = f"{label_name} — {description} ({address})"
    return (
        f"; =============================================================================\n"
        f"; {title}\n"
        f"; =============================================================================\n"
    )


def find_label_line(lines, label_name):
    """Find the line index where a label is defined."""
    # Match label at start of line, possibly with whitespace before
    pattern = re.compile(rf'^{re.escape(label_name)}:')
    for i, line in enumerate(lines):
        if pattern.match(line.lstrip()):
            return i
    return None


def process_file():
    with open(ASM_FILE, "r") as f:
        lines = f.readlines()

    # Strip trailing newlines for processing, re-add at the end
    lines = [line.rstrip("\n") for line in lines]

    # ─── Phase 1: Build label index ──────────────────────────────────────────
    label_positions = {}
    label_pattern = re.compile(r'^([a-z_][a-z0-9_]*):')
    for i, line in enumerate(lines):
        m = label_pattern.match(line)
        if m:
            label_positions[m.group(1)] = i

    # ─── Phase 2: Add inline comments ────────────────────────────────────────
    # Process inline comments. For each rule, find the label, then scan
    # forward up to max_lines_after for the instruction fragment.
    for (label_ctx, max_offset, code_frag, comment) in INLINE_COMMENTS:
        if comment is None:
            continue
        if label_ctx not in label_positions:
            continue

        label_idx = label_positions[label_ctx]

        # For offset 0, apply to the label line itself
        if max_offset == 0:
            line = lines[label_idx]
            if code_frag in line and ";" not in line:
                lines[label_idx] = add_comment_to_line(line, comment)
            continue

        # Scan forward from label for the code fragment
        found = False
        # Scan from label_idx through label_idx + max_offset
        for i in range(label_idx, min(label_idx + max_offset + 1, len(lines))):
            line = lines[i]
            # Check if code fragment appears in the instruction part (before any ;)
            code_part = line.split(";")[0] if ";" in line else line
            if code_frag in code_part and ";" not in line:
                lines[i] = add_comment_to_line(line, comment)
                found = True
                break

    # ─── Phase 3: Add block headers ──────────────────────────────────────────
    # We need to re-build the label index since inline comments may have
    # changed content but not positions.
    # Block headers INSERT lines, so process from bottom to top.
    insertions = []  # (line_idx, header_text)

    for label_name, (description, address) in BLOCK_HEADERS.items():
        if label_name not in label_positions:
            continue
        label_idx = label_positions[label_name]
        if has_block_header_nearby(lines, label_idx):
            continue

        header = make_block_header(label_name, description, address)
        insertions.append((label_idx, header))

    # Sort by line index descending so insertions don't shift earlier indices
    insertions.sort(key=lambda x: x[0], reverse=True)

    for line_idx, header in insertions:
        header_lines = header.rstrip("\n").split("\n")
        # Insert a blank line before header if previous line is not blank
        if line_idx > 0 and lines[line_idx - 1].strip():
            header_lines.insert(0, "")
        for j, hl in enumerate(header_lines):
            lines.insert(line_idx + j, hl)

    # ─── Phase 4: Write output ───────────────────────────────────────────────
    with open(ASM_FILE, "w") as f:
        for line in lines:
            f.write(line + "\n")

    print(f"Done. Processed {ASM_FILE}")
    print(f"  Block headers added: {len(insertions)}")


if __name__ == "__main__":
    process_file()
