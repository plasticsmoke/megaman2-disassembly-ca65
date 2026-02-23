#!/usr/bin/env python3
"""
add_comments_0D.py — Add block headers and inline comments to bank0D_stage_engine.asm

This script:
  1. Reads bank0D_stage_engine.asm
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

ASM_FILE = "src/bank0D_stage_engine.asm"

# --- Block headers: label_name -> (description, address) ---
BLOCK_HEADERS = {
    # Stage initialization
    "stage_init_clear_loop": (
        "Stage Select Initialization — clear boss portraits and set up OAM",
        "$802F"
    ),

    # Stage main loop (already has a header — skip)
    # "stage_main_loop": already has ===== header

    # Stage pause / select
    "stage_paused_handler": (
        "Stage Paused Handler — check if all bosses beaten or pause menu",
        "$80BA"
    ),
    "stage_select_handler": (
        "Stage Select Handler — load boss entities and run intro sequence",
        "$80C4"
    ),
    "intro_palette_blink_loop": (
        "Intro Palette Blink — animate stage select palette cycling",
        "$80F8"
    ),
    "intro_finish_palette": (
        "Intro Finish Palette — load weapon and stage palettes for drop",
        "$8159"
    ),
    "intro_blank_frames": (
        "Intro Blank Frames — wait before player drop animation",
        "$8199"
    ),
    "intro_player_drop_loop": (
        "Intro Player Drop — drop Mega Man into stage with gravity",
        "$81AE"
    ),
    "intro_player_landed": (
        "Intro Player Landed — begin weapon flash after landing",
        "$81C6"
    ),
    "intro_weapon_flash_loop": (
        "Intro Weapon Flash — cycle weapon palette colors",
        "$81D4"
    ),
    "intro_weapon_show_hold": (
        "Intro Weapon Show — hold weapon color then scroll health bar",
        "$81EE"
    ),
    "intro_cleanup": (
        "Intro Cleanup — disable NMI/rendering and return",
        "$820B"
    ),

    # Scroll / palette utilities
    "load_scroll_palette": (
        "Load Scroll Palette — copy 32-byte palette from stage_palette_data",
        "$820E"
    ),
    "check_stage_transition": (
        "Check Stage Transition — look up next stage from D-pad input",
        "$8216"
    ),

    # Player rendering & collision (already has header)
    # "player_render_collision": already has ===== header

    "render_player_sprites": (
        "Render Player Sprites — draw 3 sprite layers for Mega Man",
        "$82DC"
    ),
    "write_sprite_to_oam": (
        "Write Sprite to OAM — copy one sprite set to $0200 buffer",
        "$8312"
    ),
    "update_projectile_anim": (
        "Update Projectile Animation — advance frame counter, load sprite data",
        "$8328"
    ),
    "load_stage_nametable": (
        "Load Stage Nametable — load CHR data and fill nametable columns",
        "$837A"
    ),
    "clear_projectile_positions": (
        "Clear Projectile Positions — zero out entity sub-pixel positions",
        "$8396"
    ),

    # OAM buffer management (already has header)
    # "clear_oam_buffer": already has ===== header

    "reset_scroll_state": (
        "Reset Scroll State — zero all scroll/nametable variables",
        "$83AD"
    ),

    # Data tables
    "stage_palette_data": (
        "Stage Palette Data — 32-byte palettes for each stage select screen",
        "$83C1"
    ),
    "weapon_palette_base": (
        "Weapon/Boss Palette Tables — flash colors and per-boss palettes",
        "$8401"
    ),
    "boss_portrait_oam_data": (
        "Boss Portrait OAM Data — sprite data for stage select boss icons",
        "$8544"
    ),
    "boss_oam_offset_table": (
        "Boss OAM Layout Tables — offsets, sizes, collision boxes",
        "$85FC"
    ),
    "nametable_fill_table": (
        "Nametable Fill Table — tile pattern for stage select background",
        "$8639"
    ),
    "stage_select_index_table": (
        "Stage Select Index/Entity Tables — mapping and entity data per boss",
        "$865F"
    ),
    "player_sprite_y_table": (
        "Player Sprite Layout Tables — Y/X positions for intro sprites",
        "$872E"
    ),
    "projectile_anim_base_idx": (
        "Projectile Animation Tables — base index, max frame, duration",
        "$8781"
    ),
    "projectile_sprite_ptr_lo": (
        "Projectile Sprite Pointer Tables — lo/hi address for each frame",
        "$87F5"
    ),
    "sprite_def_data_8831": (
        "Sprite Definition Data — raw OAM data for projectile/weapon sprites",
        "$8831"
    ),

    # Weapon select screen
    "wselect_save_palette_loop": (
        "Weapon Select Screen — save state, calculate scroll, draw columns",
        "$90E9"
    ),
    "wselect_check_boss_stage": (
        "Weapon Select — Boss Stage Palette Override",
        "$9126"
    ),
    "wselect_calc_scroll_pos": (
        "Weapon Select — Calculate Scroll Position and Render Columns",
        "$914E"
    ),
    "wselect_input_loop": (
        "Weapon Select — Input Loop (D-pad / Start / weapon switching)",
        "$919F"
    ),
    "wselect_start_pressed": (
        "Weapon Select — Start Pressed (toggle page or select weapon)",
        "$9208"
    ),
    "wselect_weapon_selected": (
        "Weapon Select — Weapon Selected (store weapon, re-render columns)",
        "$9232"
    ),
    "wselect_render_oam": (
        "Weapon Select — Render OAM (header, boss icons, HP bars, cursor)",
        "$9361"
    ),
    "hp_bar_draw_weapon": (
        "HP Bar Drawing — render weapon energy bar to OAM",
        "$9488"
    ),
    "wselect_column_type": (
        "Weapon Select Layout Tables — column types, offsets, tile data",
        "$94A2"
    ),
    "wselect_header_oam": (
        "Weapon Select OAM Data — header, icon tiles, label OAM",
        "$9524"
    ),

    # Boss get screen
    "boss_get_init_ppu": (
        "Boss Get Screen — PPU init, nametable fill, palette setup",
        "$9678"
    ),
    "boss_get_normal_init": (
        "Boss Get — Normal Init (walk-in, idle, jump, shimmer, land)",
        "$96B0"
    ),
    "boss_get_walk_loop": (
        "Boss Get — Walk-In Loop (both entities walk toward center)",
        "$96D8"
    ),
    "boss_get_idle_loop": (
        "Boss Get — Idle Loop (wait before jump)",
        "$970C"
    ),
    "boss_get_jump_up_loop": (
        "Boss Get — Jump Up Loop (player rises with weapon shimmer)",
        "$973B"
    ),
    "boss_get_shimmer_loop": (
        "Boss Get — Shimmer Loop (weapon color cycling)",
        "$975B"
    ),
    "boss_get_land_loop": (
        "Boss Get — Land Loop (player descends back to ground)",
        "$9784"
    ),
    "boss_get_bounce_main": (
        "Boss Get — Bounce Main (weapon orb bouncing physics)",
        "$97AD"
    ),
    "boss_get_fall_init": (
        "Boss Get — Fall Init (orb falls off screen)",
        "$9836"
    ),
    "boss_get_flash_palette": (
        "Boss Get — Flash Palette and Title Scroll",
        "$986C"
    ),
    "boss_get_title_scroll_loop": (
        "Boss Get — Title Scroll Loop (letter-by-letter reveal)",
        "$9898"
    ),

    # Entity update & physics (already has header)
    # "update_animation_frame": already has ===== header

    "update_all_entities": (
        "Update All Entities — loop over 3 entity slots, call handler",
        "$99C8"
    ),
    "apply_gravity": (
        "Apply Gravity — downward acceleration with terminal velocity",
        "$99DA"
    ),
    "render_stars_overlay": (
        "Render Stars Overlay — draw background star sprites",
        "$99FA"
    ),
    "boss_get_title_render": (
        "Boss Get Title Render — draw header OAM and letter sprites",
        "$9A2D"
    ),
    "entity_update_handler": (
        "Entity Update Handler — load sprite data from ptr table, write OAM",
        "$9A65"
    ),

    # Wily intro
    "wily_intro_init": (
        "Wily Intro Init — fade in palette, play sound, wait",
        "$9B27"
    ),
    "wily_nametable_fill_tiles": (
        "Wily Intro Data — nametable fill tiles and palette data",
        "$9B7E"
    ),
    "entity_sprite_ptr_lo": (
        "Entity Sprite Pointer Tables — lo/hi pointers for get screen sprites",
        "$9BAC"
    ),

    # Credits / ending sequence
    "credits_ppu_write_loop": (
        "Credits Screen — PPU clear, tile layout, fade sequence",
        "$9EE7"
    ),
    "credits_scroll_right_loop": (
        "Credits — Scroll Right and Render Metatile Columns",
        "$9F56"
    ),
    "credits_scroll_advance": (
        "Credits — Scroll Advance with PPU Buffer Update",
        "$9F6D"
    ),
    "ending_fade_speed": (
        "Ending Fade — palette fade in with entity initialization",
        "$A004"
    ),
    "ending_column_init": (
        "Ending — Column Data Loading and Text Fade",
        "$A029"
    ),
    "ending_fall_accel": (
        "Ending — Fall Acceleration (Wily castle crumbles)",
        "$A067"
    ),
    "ending_fall_decel_init": (
        "Ending — Fall Deceleration and Landing Init",
        "$A086"
    ),
    "ending_landing_init": (
        "Ending — Landing (scroll down to ground level)",
        "$A0A6"
    ),
    "ending_scroll_columns": (
        "Ending — Scroll Columns (grass fills from bottom)",
        "$A0D1"
    ),
    "ending_main_loop_init": (
        "Ending — Main Loop (timer, cursor, boss walk away)",
        "$A0F8"
    ),
    "ending_teleport_loop": (
        "Ending — Teleport Animation (Mega Man beams away)",
        "$A140"
    ),
    "ending_fly_away": (
        "Ending — Fly Away (Mega Man rises off screen)",
        "$A15A"
    ),

    # Ending helper routines
    "ending_column_data_load": (
        "Ending Column Data Load — read credit text into PPU buffer",
        "$A1A5"
    ),
    "ending_attr_or_column": (
        "Ending Attr or Column — write attribute or nametable column data",
        "$A1C7"
    ),
    "ending_advance_anim": (
        "Ending Advance Animation — tick boss walk animation counter",
        "$A213"
    ),
    "ending_update_entities": (
        "Ending Update Entities — move all entities, apply gravity, spawn",
        "$A234"
    ),
    "ending_spawn_entity": (
        "Ending Spawn Entity — find empty slot and init new entity",
        "$A29D"
    ),
    "ending_render_all_sprites": (
        "Ending Render All Sprites — clear OAM, draw all entity sprites",
        "$A2B6"
    ),
    "ending_render_boss_sprite": (
        "Ending Render Boss Sprite — draw Wily's machine from sprite defs",
        "$A2FA"
    ),
    "credits_skip_init": (
        "Credits Skip Init — fast-forward to ending walk scene",
        "$A338"
    ),

    # Metatile / palette utility routines
    "metatile_column_render_loop": (
        "Metatile Column Render Loop — render full screen of metatile columns",
        "$A3AC"
    ),
    "palette_fade_out": (
        "Palette Fade Out — gradually darken all palette entries",
        "$A3C1"
    ),
    "palette_fade_in": (
        "Palette Fade In — gradually brighten palette to target",
        "$A3EA"
    ),
    "password_render_sprites": (
        "Password Render Sprites — draw cursor and dot grid OAM",
        "$A406"
    ),
    "ppu_column_data_upload": (
        "PPU Column Data Upload — load indexed PPU column data for transfer",
        "$A440"
    ),
    "init_scroll_and_palette": (
        "Init Scroll and Palette — set nametable, load default palette, enable",
        "$A454"
    ),
    "scroll_right_until_wrap": (
        "Scroll Right Until Wrap — scroll X in 8px steps until wrap",
        "$A469"
    ),
    "metatile_full_screen_render": (
        "Metatile Full Screen Render — render all columns with vblank sync",
        "$A47C"
    ),
    "scroll_left_until_zero": (
        "Scroll Left Until Zero — scroll X left in 8px steps",
        "$A48C"
    ),
    "password_init_dot_oam": (
        "Password Init Dot OAM — set up grid dot sprite positions",
        "$A4A1"
    ),

    # Password screen
    "password_screen_init": (
        "Password Screen — metatile render, tile upload, grid init",
        "$A2C6"
    ),
    "password_grid_init": (
        "Password Grid Init — reset cursor and enter selection loop",
        "$A311"
    ),
    "password_enter_mode": (
        "Password Enter Mode — fade, draw grid OAM, enter dot placement",
        "$A337"
    ),
    "password_entry_loop": (
        "Password Entry Loop — D-pad movement, dot placement, A/B input",
        "$A35A"
    ),
    "password_all_dots_placed": (
        "Password All Dots Placed — decode and validate password",
        "$A3B2"
    ),
    "password_invalid": (
        "Password Invalid — show error, return to grid",
        "$A3D2"
    ),
    "password_valid": (
        "Password Valid — decode stage data, show beaten bosses",
        "$A3FA"
    ),

    # NMI / rendering control
    "enable_nmi_and_rendering": (
        "Enable NMI and Rendering — set ppuctrl + ppumask bits",
        "$A519"
    ),
    "disable_nmi_and_rendering": (
        "Disable NMI and Rendering — clear ppuctrl + ppumask bits",
        "$A526"
    ),
    "ppu_buffer_and_increment": (
        "PPU Buffer and Increment — transfer buffer then advance pointer",
        "$A530"
    ),

    # Ending data tables
    "ending_fade_pal_frames": (
        "Ending Fade Palette Frames — 3 fade-in steps for ending scene",
        "$A4C0"
    ),
    "credits_skip_palette": (
        "Credits Skip / Ending Palette Data Tables",
        "$A500"
    ),
    "entity_sprite_y_offset": (
        "Entity Sprite Offset Tables — Y/tile/attr/X for ending entities",
        "$A545"
    ),
    "boss_sprite_def_ptr_lo": (
        "Boss Sprite Definition Pointers — lo/hi for Wily machine frames",
        "$AB1F"
    ),
    "boss_sprite_data_ACE0": (
        "Boss Sprite Data — raw OAM for each Wily machine animation frame",
        "$ACE0"
    ),
    "credits_text_data": (
        "Credits Text Data — ASCII text for ending credit screens",
        "$AD4B"
    ),

    # Wily castle / ending tilemap
    "wily_castle_attr_data": (
        "Wily Castle Attribute Data — attribute table for castle tilemap",
        "$B265"
    ),

    # Ending walk sequence
    "ending_clear_pal_loop": (
        "Ending Walk Scene — init scroll, CHR, palette, wait, then walk",
        "$B6F1"
    ),
    "ending_scene_fade_loop": (
        "Ending Scene Fade — palette fade loop with sprite rendering",
        "$B725"
    ),
    "ending_scene_next": (
        "Ending Scene Sequence — timer-based scene progression",
        "$B73B"
    ),
    "ending_health_bar_loop": (
        "Ending Health Bar — draw health meter tiles during walk",
        "$B7BF"
    ),
    "ending_walk_main_init": (
        "Ending Walk Main — scroll columns while Mega Man walks right",
        "$B7D8"
    ),
    "ending_final_walk_loop": (
        "Ending Final Walk — last walking segment before wait for Start",
        "$B824"
    ),
    "ending_scene_sprite_render": (
        "Ending Scene Sprite Render — draw scene-specific sprites",
        "$B83F"
    ),
    "ending_set_sky_palette": (
        "Ending Set Sky Palette — sky color based on scene index",
        "$B8C5"
    ),
    "ending_set_ground_palette": (
        "Ending Set Ground Palette — ground palette per scene",
        "$B8DF"
    ),
    "ppu_fill_column_with_tile": (
        "PPU Fill Column with Tile — fill 32-tile column for PPU upload",
        "$B8FE"
    ),
    "ending_palette_per_scene": (
        "Ending Palette Per Scene — 12-byte palette sets for each scene",
        "$B90F"
    ),
    "ending_sky_color_table": (
        "Ending Sky Color Table — 2-byte sky color for each scene/phase",
        "$B96F"
    ),

    # Stage intro / weapon get
    "stage_intro_clear_pal": (
        "Stage Intro — CHR load, metatile render, palette fade, name draw",
        "$BAE0"
    ),
    "stage_intro_draw_name": (
        "Stage Intro — Draw Stage Name Letter by Letter",
        "$BB1F"
    ),
    "stage_intro_blink_loop": (
        "Stage Intro — Blink Name in Stage Colors",
        "$BB53"
    ),
    "stage_intro_cursor_init": (
        "Stage Intro — Cursor Init and Select Loop",
        "$BB79"
    ),
    "stage_intro_save_pal": (
        "Stage Intro — Save Palette and Show Password Grid",
        "$BB9D"
    ),
    "stage_intro_exit": (
        "Stage Intro Exit — disable rendering and return",
        "$BBD5"
    ),

    # Weapon get sequence
    "weapon_get_init": (
        "Weapon Get Init — blink animation, draw name, draw weapon icon",
        "$BBD8"
    ),
    "weapon_get_draw_marker": (
        "Weapon Get Draw Marker — write arrow tile to PPU buffer",
        "$BC60"
    ),
    "weapon_get_wait_frame": (
        "Weapon Get Wait Frame — sync to frame counter mod 8",
        "$BC6D"
    ),
    "weapon_get_text_upload": (
        "Weapon Get Text Upload — read text table and upload letter by letter",
        "$BC75"
    ),
    "weapon_get_long_wait": (
        "Weapon Get Long Wait — 125-frame delay",
        "$BCB6"
    ),
    "weapon_get_clear_nt": (
        "Weapon Get Clear Nametable — zero out text area columns",
        "$BCBF"
    ),
    "weapon_get_draw_weapon": (
        "Weapon Get Draw Weapon — show weapon icon with marker",
        "$BCE0"
    ),
    "weapon_name_data": (
        "Weapon Name Data — text tables for stage/weapon names",
        "$BD03"
    ),
    "stage_intro_pal_lo": (
        "Stage Intro Palette Data — per-stage blink colors",
        "$BF67"
    ),

    # Game over / credits select
    "credits_init_scroll": (
        "Credits / Game Over — init scroll, render tiles, menu select loop",
        "$B101"
    ),
    "credits_select_loop_start": (
        "Credits Select Loop — continue/password/stage select menu",
        "$B146"
    ),
    "password_show_grid": (
        "Password Show Grid — encode current progress and display grid",
        "$B1C2"
    ),

    # Padding
    "bank_0D_padding": (
        "Bank $0D Padding — unused space filled with $FF",
        "$BF94"
    ),
}

# --- Inline comments: (label_name, instruction_fragment) -> comment ---
# These are added to lines matching BOTH the label context and instruction text.
INLINE_COMMENTS = {
    # Stage init
    ("stage_init_clear_loop", "stx     $00"): "Save boss index",
    ("stage_init_clear_loop", "lsr     $01"): "Shift out boss beaten flag",
    ("stage_init_ppu_fill", "sta     $2006"): "Set PPU write address",
    ("stage_init_ppu_byte", "sta     $2007"): "Clear boss portrait tile",
    ("stage_init_oam_loop", "stx     $01"): "Save boss index",
    ("stage_init_oam_copy", "sta     $0200,y"): "Copy to OAM buffer",
    ("enable_nmi_and_rendering", "jsr     enable_nmi_and_rendering"): "Turn on NMI + sprites + BG",

    # Stage main loop
    ("stage_main_loop", "and     #$08"): "Check Start button (pause)",
    ("stage_main_loop", "and     #$F0"): "Check D-pad for stage transition",
    ("stage_loop_render", "jsr     player_render_collision"): "Render player & update collision",
    ("stage_loop_render", "jsr     wait_for_vblank_0D"): "Wait for next frame",

    # Intro sequence
    ("intro_palette_blink_loop", "and     #$04"): "Toggle palette every 4 frames",
    ("intro_player_drop_loop", "adc     #$08"): "Drop 8 pixels per frame",
    ("intro_player_drop_loop", "cmp     #$78"): "Reached ground Y=$78?",
    ("intro_player_landed", "and     #$01"): "Facing direction from controller",
    ("intro_weapon_flash_loop", "cpx     #$10"): "All 8 color pairs shown?",
    ("intro_health_fill_loop", "and     #$03"): "Add health every 4 frames",

    # Weapon select
    ("wselect_check_start", "and     #$08"): "Start button pressed?",
    ("wselect_check_dpad", "and     #$30"): "D-pad up/down new press?",
    ("wselect_check_dpad", "cmp     #$18"): "Auto-repeat delay (24 frames)",
    ("wselect_move_right", "inc     $FD"): "Move cursor right",
    ("wselect_move_left", "dec     $FD"): "Move cursor left",
    ("wselect_etank_fill_loop", "cmp     #$1C"): "Full health = 28 units",
    ("wselect_weapon_selected", "cmp     #$07"): "E-Tank slot?",
    ("wselect_cursor_blink", "and     #$08"): "Blink every 8 frames",

    # Boss get screen
    ("boss_get_walk_loop", "adc     #$40"): "Walk sub-pixel increment",
    ("boss_get_walk_loop", "cmp     #$68"): "Reached center X=$68?",
    ("boss_get_jump_up_loop", "sbc     #$80"): "Rise velocity sub-pixel",
    ("boss_get_shimmer_loop", "cmp     #$08"): "Shimmer frame duration",
    ("boss_get_shimmer_loop", "cmp     #$06"): "Shimmer anim frame count",
    ("boss_get_land_loop", "adc     #$80"): "Descend velocity sub-pixel",
    ("boss_get_bounce_main", "cmp     #$68"): "Center Y position check",
    ("boss_get_bounce_reverse", "eor     #$01"): "Toggle bounce direction",
    ("boss_get_flash_loop", "and     #$08"): "Flash every 8 frames",
    ("boss_get_title_scroll_loop", "and     #$03"): "Scroll every 4 frames",
    ("boss_get_title_scroll_loop", "adc     #$04"): "Advance 4 pixels per step",

    # Entity update
    ("update_animation_frame", "cmp     #$06"): "6-tick animation speed",
    ("update_animation_frame", "cmp     #$04"): "4 walk frames total",
    ("apply_gravity", "adc     #$80"): "Gravity sub-pixel acceleration",
    ("apply_gravity", "cmp     #$F0"): "Terminal velocity check",

    # Credits / ending
    ("credits_fade_outer", "sta     $0357"): "Set background brightness",
    ("credits_fade_next", "and     #$08"): "Start pressed? Skip credits",
    ("ending_landing_scroll", "sbc     #$02"): "Scroll down 2px per frame",
    ("ending_main_loop", "and     #$08"): "Start button = skip",
    ("ending_teleport_loop", "and     #$01"): "Animate every other frame",
    ("ending_fly_away", "sbc     #$08"): "Rise 8 pixels per frame",

    # Password screen
    ("password_check_input", "and     #$3C"): "Any D-pad or Start/Select?",
    ("password_check_input", "and     #$08"): "Start button?",
    ("password_entry_loop", "and     #$F0"): "D-pad new press?",
    ("password_entry_loop", "cmp     #$18"): "Auto-repeat delay (24 frames)",
    ("password_all_dots_placed", "cmp     #$FF"): "All bits set = valid password",

    # Palette utilities
    ("palette_dec_loop", "sbc     #$10"): "Darken by one NES shade step",
    ("palette_inc_loop", "cmp     #$0F"): "Is color black ($0F)?",
    ("palette_inc_add", "adc     #$10"): "Brighten by one NES shade step",

    # Stage intro / weapon get
    ("stage_intro_blink_loop", "and     #$01"): "Odd/even frame for blink",
    ("weapon_get_blink_loop", "and     #$08"): "Blink every 8 frames",
    ("weapon_get_text_inner", "cpy     #$F7"): "Special marker: use item tile",
}


def add_block_headers(lines):
    """Add block headers above major routine labels."""
    new_lines = []
    added = 0

    for i, line in enumerate(lines):
        stripped = line.rstrip()

        # Check if this line starts with a label we want to annotate
        for label, (desc, addr) in BLOCK_HEADERS.items():
            # Match "label:" at start of line (with or without instruction after)
            if re.match(rf'^{re.escape(label)}\s*:', stripped):
                # Check if there's already a ===== header within 3 lines above
                has_header = False
                start = max(0, len(new_lines) - 3)
                for prev in new_lines[start:]:
                    if '; =====' in prev:
                        has_header = True
                        break

                if not has_header:
                    # Add blank line if the previous line isn't blank
                    if new_lines and new_lines[-1].strip():
                        new_lines.append("")
                    new_lines.append(f"; {'=' * 77}")
                    new_lines.append(f"; {desc}")
                    new_lines.append(f"; {'=' * 77}")
                    added += 1
                break

        new_lines.append(line)

    return new_lines, added


def add_inline_comments(lines):
    """Add inline comments to key instructions."""
    new_lines = []
    added = 0
    current_label = ""

    for line in lines:
        stripped = line.rstrip()

        # Track current label context
        label_match = re.match(r'^(\w+)\s*:', stripped)
        if label_match:
            current_label = label_match.group(1)

        # Only add comments to lines that don't already have one
        if ';' not in stripped:
            for (lbl, instr_frag), comment in INLINE_COMMENTS.items():
                if current_label == lbl and instr_frag in stripped:
                    # Pad to column 40 minimum
                    padded = stripped.ljust(39)
                    stripped = f"{padded} ; {comment}"
                    added += 1
                    break

        new_lines.append(stripped)

    return new_lines, added


def main():
    with open(ASM_FILE, "r") as f:
        lines = [l.rstrip("\n") for l in f.readlines()]

    original_count = len(lines)

    lines, headers_added = add_block_headers(lines)
    lines, comments_added = add_inline_comments(lines)

    with open(ASM_FILE, "w") as f:
        for line in lines:
            f.write(line + "\n")

    print(f"Added {headers_added} block headers and {comments_added} inline comments")
    print(f"Lines: {original_count} -> {len(lines)}")


if __name__ == "__main__":
    main()
