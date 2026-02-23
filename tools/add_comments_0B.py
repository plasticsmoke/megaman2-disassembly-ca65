#!/usr/bin/env python3
"""
add_comments_0B.py — Add block headers and inline comments to bank0B_game_logic.asm

This script:
  1. Reads bank0B_game_logic.asm
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

ASM_FILE = os.path.join(os.path.dirname(__file__), '..', 'src', 'bank0B_game_logic.asm')

# --- Block headers: label_name -> (description, address) ---
BLOCK_HEADERS = {
    # Boss init entry
    "boss_init": (
        "Boss Initialization — load boss properties from indexed tables",
        "$A451"
    ),

    # Enemy AI dispatch
    # Already has block header from phase 3

    # Boss AI routines — Robot Masters
    "bubbleman_spawn_projectile_loop": (
        "Boss AI: Bubbleman — projectile spawning and movement patterns",
        "$8194"
    ),
    "woodman_spawn_leaf_loop": (
        "Boss AI: Woodman — Leaf Shield creation and leaf projectile spawning",
        "$833C"
    ),
    "airman_check_phase": (
        "Boss AI: Airman — tornado spawning and wind patterns",
        "$851E"
    ),
    "crashman_aim_check_dist": (
        "Boss AI: Crashman — Crash Bomber aiming and movement",
        "$8686"
    ),
    "quickman_check_anim": (
        "Boss AI: Quickman — fast movement and boomerang attacks",
        "$8826"
    ),
    "heatman_frame_update": (
        "Boss AI: Heatman — flame charge and projectile patterns",
        "$8A08"
    ),
    "metalman_fire_blade": (
        "Boss AI: Metalman — Metal Blade throws and jump patterns",
        "$8B74"
    ),
    "metalman_palette_flash": (
        "Metalman Palette Flash — stage lightning effect timer",
        "$8C3E"
    ),
    "flashman_setup_velocity": (
        "Boss AI: Flashman — Time Stopper freeze and movement",
        "$8D36"
    ),

    # Wily fortress bosses
    "dragon_fill_column_loop": (
        "Boss AI: Wily 1 — Mecha Dragon nametable setup and column fill",
        "$8E59"
    ),
    "dragon_sprite_collision_loop": (
        "Boss AI: Wily 1 — Mecha Dragon battle and collision",
        "$8F90"
    ),
    "dragon_update_position": (
        "Mecha Dragon Movement — position update and scroll tracking",
        "$9165"
    ),
    "guts_tank_copy_data_loop": (
        "Boss AI: Wily 2 — Guts Tank entity spawning and setup",
        "$925D"
    ),
    "guts_tank_palette_flash": (
        "Guts Tank Palette — flash effect on hit",
        "$9382"
    ),
    "buebeam_advance_phase": (
        "Boss AI: Wily 3 — Buebeam Trap nametable and column setup",
        "$93E7"
    ),
    "buebeam_spawn_turret": (
        "Buebeam Battle — turret spawning and phase management",
        "$94D2"
    ),
    "buebeam_spawn_tick": (
        "Buebeam Projectile — spawn timing and aim calculation",
        "$9563"
    ),
    "gutsdozer_spawn_part_loop": (
        "Boss AI: Guts Dozer — part spawning and position tables",
        "$968B"
    ),
    "boobeam_fill_palette_loop": (
        "Boss AI: Wily 4 — Boobeam Trap palette and nametable setup",
        "$96F6"
    ),
    "boobeam_palette_blend": (
        "Boobeam Palette Blend — smooth color transition for trap room",
        "$979B"
    ),
    "wily_machine_apply_facing": (
        "Boss AI: Wily 5 — Wily Machine movement and attack patterns",
        "$981F"
    ),
    "wily_machine_hit_check": (
        "Wily Machine Damage — weapon invincibility and hit detection",
        "$9A10"
    ),
    "alien_jmp_dispatch": (
        "Boss AI: Wily 6 — Alien hologram movement and attack",
        "$9B35"
    ),
    "alien_movement_pattern": (
        "Alien Movement Pattern — sinusoidal path from velocity tables",
        "$9CE3"
    ),
    "alien_scroll_update": (
        "Alien Scroll — stage background scrolling during battle",
        "$9DAC"
    ),
    "alien_scroll_setup_entities": (
        "Alien Stage Setup — entity spawn and palette initialization",
        "$9DC7"
    ),

    # Fortress enemy fallback
    "enemy_ai_fallback": (
        "Fortress Enemy Fallback — generic AI for non-boss fortress enemies",
        "$9FD3"
    ),
    "fortress_post_defeat": (
        "Fortress Post-Defeat — cleanup after fortress boss defeated",
        "$A08B"
    ),

    # Common routines
    "play_sound_and_reset_anim": (
        "Play Sound & Reset — queue sound effect, clear anim/hit state",
        "$A10C"
    ),
    "boss_health_bar_tick": (
        "Boss Health Bar — increment health bar fill during intro",
        "$A118"
    ),
    "boss_apply_movement_physics": (
        "Boss Movement Physics — apply velocity to position with clamping",
        "$A14F"
    ),
    "calc_player_boss_distance": (
        "Player-Boss Distance — calculate X distance for aim/facing",
        "$A209"
    ),
    "find_entity_by_type": (
        "Find Entity by Type — scan entity slots for matching type ID",
        "$A22D"
    ),
    "boss_floor_collision_check": (
        "Boss Floor Collision — check tiles below boss for solid ground",
        "$A249"
    ),
    "boss_wall_collision_check": (
        "Boss Wall Collision — check tiles ahead of boss for walls",
        "$A2D4"
    ),
    "spawn_entity_from_boss": (
        "Spawn Entity from Boss — find free slot and initialize projectile",
        "$A352"
    ),
    "calc_velocity_toward_player": (
        "Velocity Toward Player — calculate X/Y velocity to aim at player",
        "$A38C"
    ),
    "setup_ppu_normal": (
        "Setup PPU Normal — check player-boss proximity for contact damage",
        "$A52D"
    ),
    "weapon_boss_collision_check": (
        "Weapon-Boss Collision — check if player weapon hits boss",
        "$A59D"
    ),
    "weapon_boss_hit_dispatch": (
        "Weapon Hit Dispatch — route to weapon-specific damage handler",
        "$A5EE"
    ),
    "buster_apply_damage": (
        "Weapon Damage: Mega Buster — standard pellet damage to boss",
        "$A61B"
    ),
    "metal_blade_store_damage": (
        "Weapon Damage: Metal Blade — variable damage based on boss",
        "$A68D"
    ),
    "weapon_force_kill_boss": (
        "Force Kill Boss — instant-kill for weakness weapons (max HP loss)",
        "$A91B"
    ),
    "weapon_handler_ptr_lo": (
        "Weapon Damage Tables — per-weapon and per-boss damage values",
        "$A930"
    ),
    "boss_contact_damage_table": (
        "Boss Contact Damage — damage dealt to player on touch per boss",
        "$A9B2"
    ),
    "buebeam_nt_addr_hi_table": (
        "Buebeam Nametable Data — PPU addresses and tile data for trap room",
        "$A9C0"
    ),
}

# --- Inline comments: (label_or_address, substring_match, comment) ---
# These are added to lines that contain the substring, within the context of the label
INLINE_COMMENTS = {
    # Boss init
    "boss_init:  ldx     $B3": "X = boss stage ID",
    "sta     $0421": "",  # too generic, skip
    "lda     boss_ai_flags,x": "load AI behavior flags for this boss",
    "lda     boss_movement_mode,x": "load default X position",
    "lda     boss_x_position,x": "load Y position",
    "lda     boss_type_table,x": "load boss entity type",
    "sta     $B1": "",  # too generic

    # Sound helper
    "play_sound_and_reset_anim:  sta     $0401": "queue sound effect ID",

    # Health bar
    "boss_health_bar_tick:  lda     $1C": "frame counter for timing",
    "inc     $06C1": "increment health bar fill",

    # Distance calc
    "calc_player_boss_distance:  lda     $0421": "boss entity flags",

    # Entity search
    "find_entity_by_type:  sta     zp_temp_00": "store target type ID",

    # Spawn helper
    "spawn_entity_from_boss:  pha": "save entity type on stack",
    "jsr     fixed_DA43": "find empty entity slot",
    "spawn_entity_init_type:  jsr     fixed_D77C": "initialize entity from type table",

    # Velocity calc
    "calc_velocity_toward_player:  ldy     #$40": "default: face right",
    "jsr     divide_16bit": "divide for velocity ratio",

    # Weapon collision
    "weapon_boss_collision_check:  ldx     #$09": "start scanning from slot 9",
    "weapon_boss_hit_dispatch:  lda     $B4": "check already-hit flag",
    "weapon_force_kill_boss:  lda     #$1C": "set HP to max (instant kill)",
    "weapon_difficulty_scale:  lda     $CB": "check difficulty flag",
    "asl     zp_temp_00": "double damage on normal mode",
}

def add_block_headers(lines):
    """Add block comment headers before major routine labels."""
    output = []
    added = 0

    for i, line in enumerate(lines):
        # Check if this line defines a label that needs a block header
        for label, (desc, addr) in BLOCK_HEADERS.items():
            # Match "label:" at the start of the line (with optional whitespace)
            if re.match(r'^' + re.escape(label) + r':', line):
                # Check if there's already a block header within 3 lines above
                has_header = False
                for j in range(max(0, len(output) - 3), len(output)):
                    if '; =====' in output[j]:
                        has_header = True
                        break

                if not has_header:
                    # Add blank line before header if previous line isn't blank
                    if output and output[-1].strip():
                        output.append('\n')
                    output.append(f'\n; =============================================================================\n')
                    output.append(f'; {desc} ({addr})\n')
                    output.append(f'; =============================================================================\n')
                    added += 1
                break

        output.append(line)

    print(f"Added {added} block headers")
    return output


def add_inline_comments(lines):
    """Add inline comments to key instruction lines."""
    added = 0

    for i, line in enumerate(lines):
        # Skip lines that already have comments
        if ';' in line:
            continue

        stripped = line.rstrip('\n')

        for pattern, comment in INLINE_COMMENTS.items():
            if not comment:  # skip empty comments
                continue
            if pattern in stripped:
                # Pad to column 40 minimum
                padded = stripped.ljust(40)
                lines[i] = padded + '; ' + comment + '\n'
                added += 1
                break

    print(f"Added {added} inline comments")
    return lines


def main():
    if not os.path.isfile(ASM_FILE):
        print(f"ERROR: {ASM_FILE} not found", file=sys.stderr)
        sys.exit(1)

    with open(ASM_FILE, 'r') as f:
        lines = f.readlines()

    print(f"Read {len(lines)} lines from {ASM_FILE}")

    # Add block headers first
    lines = add_block_headers(lines)

    # Then add inline comments
    lines = add_inline_comments(lines)

    with open(ASM_FILE, 'w') as f:
        f.writelines(lines)

    print(f"Wrote {len(lines)} lines back to {ASM_FILE}")


if __name__ == '__main__':
    main()
