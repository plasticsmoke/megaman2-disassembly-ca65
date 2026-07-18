# Mega Man 2 — Data Reference

A lookup-oriented companion to [ENGINE.md](ENGINE.md). Use this file to find the exact table, address, or byte to edit for common ROM hacking tasks.

> All labels, line numbers, and addresses reference the annotated ca65 source in `src/`. Variable equates are in `include/zeropage.inc` and `include/ram.inc`; constants in `include/constants.inc`.

---

## Table of Contents

1. [Quick Reference](#1-quick-reference)
2. [Weapon Damage Tables](#2-weapon-damage-tables)
3. [Boss Data](#3-boss-data)
4. [Enemy Data](#4-enemy-data)
5. [Player Values](#5-player-values)
6. [Stage Data Format](#6-stage-data-format)
7. [Palette Data](#7-palette-data)
8. [CHR-RAM System](#8-chr-ram-system)
9. [Difficulty System](#9-difficulty-system)
10. [Music & Sound Effects](#10-music--sound-effects)
11. [Password System](#11-password-system)
12. [Named Constants](#12-named-constants)
13. [Sprite & Animation Data](#13-sprite--animation-data)
14. [Text & Screen Data](#14-text--screen-data)

---

## 1. Quick Reference

| I want to change... | Where to look |
|---|---|
| Boss HP | All bosses use `MAX_HP` ($1C = 28) — `include/constants.inc` |
| Weapon damage to bosses | `weapon_base_damage_table` + per-weapon tables — `bank0B:5103` |
| Boss contact damage | `boss_contact_damage_table` — `bank0B:5126` |
| Enemy contact damage | `contact_damage_to_player_tbl` — `bank0F:5558` |
| Enemy spawns per stage | Spawn tables at bank offsets $3600-$39FF — `bank00`–`bank09` |
| Player walk speed | `max_speed_sub` / `max_speed_hi` ($3E/$3F) — `include/zeropage.inc` |
| Gravity | `gravity_hi_table` — `bank0E:1478` |
| Item drop rates | `item_drop_calc` — `bank0F:6230` |
| Difficulty flag | `difficulty` ($CB) — `include/zeropage.inc` |
| Stage → data bank | `current_stage AND #$07`; music via `stage_music_table` — `bank0E:334` |
| Weapon palettes | `weapon_palette_data` — `bank0F:2842` |
| Stage BG palettes | Bank offset $3E00 in stage banks $00–$09 |
| Music triggers | `sound_queue_push` with sound ID — `bank0F:274` |
| Password encoding | `password_all_dots_placed` — `bank0D:3664` |
| Tile collision types | `stage_collision_table` — `bank0F:1915` |
| Entity AI handlers | `entity_ai_ptr_lo/hi/bank` — `bank0E:2656` |
| Entity flags/hitboxes | `entity_flags_table` — `bank0F:3371` |
| Entity AI behavior | `entity_ai_behavior_tbl` — `bank0F:3421` |
| Sprite definitions | `sprite_def_ptr_lo/hi` — `bank0F:6506` |
| Text tile encoding | CHR tile indices: $C1=A ... $DA=Z — `bank0D:4784` |

---

## 2. Weapon Damage Tables

### Overview

Weapon-to-boss damage is handled by per-weapon handlers dispatched through `weapon_handler_ptr_lo/hi` (bank0B:5076). Each handler loads damage from a per-boss table indexed by `boss_id` ($B3). A value of `$FF` triggers `boss_restore_full_hp` — it HEALS the boss to full HP (the Alien can only be damaged by Bubble Lead; everything else restores it).

On **Normal** difficulty, `weapon_difficulty_scale` (bank0B:5084) doubles all weapon damage to bosses via `ASL temp_00`. On **Difficult** mode, base values are used as-is.

### Boss Weakness Matrix — Base Damage (Difficult Mode)

Values are hex. `--` = 0 (immune/no effect). **kill** = $FF (instant kill). Normal mode doubles all values.

| Boss (ID) | Buster | Atomic Fire | Air Shooter | Leaf Shield | Bubble Lead | Quick Boom | Metal Blade | Crash Bomber |
|---|---|---|---|---|---|---|---|---|
| Heat Man (0) | 2 | **kill** | 2 | -- | 6 | 2 | 1 | **kill** |
| Air Man (1) | 2 | 6 | -- | 8 | -- | 2 | -- | -- |
| Wood Man (2) | 1 | $0E | 4 | **kill** | -- | -- | 2 | 2 |
| Bubble Man (3) | 1 | -- | -- | -- | **kill** | 2 | 4 | 2 |
| Quick Man (4) | 2 | $0A | 2 | -- | -- | -- | -- | 4 |
| Flash Man (5) | 2 | 6 | -- | -- | 2 | -- | 4 | 3 |
| Metal Man (6) | 1 | 4 | -- | -- | -- | 4 | $0E | -- |
| Crash Man (7) | 1 | 6 | $0A | -- | 1 | 1 | -- | -- |
| Mecha Dragon (8) | 1 | 8 | -- | -- | -- | 1 | -- | 1 |
| Picopico-kun (9) | -- | -- | -- | -- | -- | -- | -- | -- |
| Guts-Dozer (10) | 1 | 8 | -- | -- | 1 | 2 | -- | 1 |
| Boobeam Trap (11) | -- | -- | -- | -- | -- | -- | -- | -- |
| Wily Machine (12) | 1 | $0E | 1 | -- | -- | 1 | 1 | 4 |
| Alien (13) | **kill** | **kill** | **kill** | **kill** | 1 | **kill** | **kill** | **kill** |

Time Stopper is excluded — it uses frame-by-frame drain logic (not the weapon-boss collision system). The Atomic Fire column shows full-charge values; uncharged = buster damage, medium charge = 3x buster. Alien table values of $FF are unreachable in normal gameplay (only Bubble Lead can collide). Boobeam Trap uses custom collision handling (only Crash Bomber works, outside this table).

### Per-Weapon Damage Table Locations

All tables have 14 entries (one per `boss_id` 0–13). Tables are packed contiguously in ROM starting at $A942. The handler pointer table at `weapon_handler_ptr_lo/hi` (bank0B:5093) dispatches to per-weapon code that loads from the correct table via `LDA $xxxx,Y`.

| Weapon | Handler | Table | Label |
|---|---|---|---|
| Mega Buster (0) | `boss_hit_buster` ($A601) | $A942 | `weapon_base_damage_table` |
| Atomic Fire (1) | `boss_hit_atomic` ($A65A) | $A950 | `weapon_atomic_fire_damage_table` |
| Air Shooter (2) | `boss_hit_air` ($A6CE) | $A95E | `weapon_air_shooter_damage_table` |
| Leaf Shield (3) | `boss_hit_leaf` ($A725) | $A96C | `weapon_leaf_shield_damage_table` |
| Bubble Lead (4) | `boss_hit_bubble` ($A789) | $A97A | `weapon_bubble_lead_damage_table` |
| Quick Boomerang (5) | `boss_hit_quick` ($A7E0) | $A988 | `weapon_quick_boomerang_damage_table` |
| Time Stopper (6) | `boss_restore_full_hp` ($A91B) | — | (unreachable pointer) |
| Metal Blade (7) | `boss_hit_metal` ($A8B6) | $A9A4 | `weapon_metal_blade_damage_table` |
| Crash Bomber (8) | `boss_hit_crash` ($A854) | $A996 | `weapon_crash_bomber_damage_table` |

The Atomic Fire handler has multi-level charge logic: `ent_state < 2` → buster damage, `ent_state == 2` → 3x buster damage, `ent_state > 2` → full-charge table ($A950). A table entry of `$FF` does NOT damage the boss — it jumps to `boss_restore_full_hp`, which refills the boss's HP to maximum (e.g. the Alien vs anything but Bubble Lead, or Heat Man vs Atomic Fire).

Time Stopper has no per-hit damage table — its handler entry ($A91B) points directly to `boss_restore_full_hp`. Actual Time Stopper drain damage is applied frame-by-frame through separate logic, not through the weapon hit dispatch system.

### Weapon-to-Enemy Damage Summary (bank0F)

Each weapon has a per-entity-type damage table ($00–$7B; 124 entries for Buster, 120 for the rest — higher types are never checked). On **Normal** mode, `apply_difficulty_modifier` doubles all weapon-to-enemy values via `ASL temp_00`. All nine tables are labeled in bank0F:

| Table | Address | Weapon |
|---|---|---|
| `weapon_dmg_buster_tbl` | $E998 | Buster / Atomic Fire (uncharged; ×3 mid-charge) |
| `weapon_dmg_atomic_tbl` | $EA14 | Atomic Fire (full charge) |
| `weapon_dmg_air_tbl` | $EA8C | Air Shooter |
| `weapon_dmg_leaf_tbl` | $EB04 | Leaf Shield |
| `weapon_dmg_bubble_tbl` | $EB7C | Bubble Lead |
| `weapon_dmg_quick_tbl` | $EBF4 | Quick Boomerang |
| `weapon_dmg_crash_tbl` | $EC6C | Crash Bomber |
| `weapon_dmg_metal_tbl` | $ECE4 | Metal Blade |
| `contact_damage_to_player_tbl` | $ED5C | Enemy contact damage to player |

---

## 3. Boss Data

### Boss Init Tables (bank0B:4508)

All 14 bosses use `MAX_HP` ($1C = 28 HP). Health bar fills during the boss intro animation.

| Boss | ID | X Pos | Y Pos | Contact Dmg | AI Flags | Movement |
|---|---|---|---|---|---|---|
| Heat Man | 0 | $28 | $50 | 8 | $83 | $C8 |
| Air Man | 1 | $28 | $66 | 8 | $83 | $C8 |
| Wood Man | 2 | $30 | $6C | 8 | $83 | $C8 |
| Bubble Man | 3 | $28 | $60 | 4 | $83 | $C8 |
| Quick Man | 4 | $28 | $54 | 4 | $83 | $C8 |
| Flash Man | 5 | $28 | $5A | 4 | $83 | $C8 |
| Metal Man | 6 | $28 | $63 | 6 | $83 | $C8 |
| Crash Man | 7 | $28 | $69 | 4 | $83 | $C8 |
| Mecha Dragon | 8 | $6B | $70 | **28** | $8B | $70 |
| Picopico-kun | 9 | $10 | $50 | 8 | $00 | $C8 |
| Guts-Dozer | 10 | $4B | $71 | 4 | $00 | $FF |
| Boobeam Trap | 11 | $10 | $50 | 8 | $00 | $C8 |
| Wily Machine | 12 | $77 | $72 | 10 | $83 | $78 |
| Alien | 13 | $7C | $75 | **20** | $00 | $B4 |

Contact damage is a flat value subtracted from player HP — **not** affected by difficulty.

### Boss Init Table Labels

| Table | Location | Description |
|---|---|---|
| `boss_ai_flags` | bank0B:4508 | AI behavior flags per boss |
| `boss_default_x_px` | bank0B:4510 | Spawn X pixel |
| `boss_default_y_px` | bank0B:4512 | Spawn Y pixel |
| `boss_default_type` | bank0B:4520 | Boss sprite type (`boss_set_sprite` IDs $50-$7B) |
| `boss_default_screen` | bank0B:4522 | Spawn screen number |
| `boss_contact_damage_table` | bank0B:5126 | Contact damage to player |

### Boss State Variables

| Variable | Address | Description |
|---|---|---|
| `boss_hp` | $06C1 | Boss hit points (slot $01 of `ent_hp`) |
| `boss_ai_state` | $04E1 | AI sub-state counter |
| `boss_phase` | $B1 | Fight phase counter |
| `boss_action_timer` | $B2 | Attack timing countdown |
| `boss_id` | $B3 | Boss index (0–13) for table lookups |
| `boss_hit_flag` | $B4 | Weapon hit flag, incremented per hit |
| `boss_spawn_timer` | $05A6 | Boss spawn/intro countdown |
| `boss_work_var1` | $05A7 | General-purpose work variable 1 (aliased per-boss) |
| `boss_hit_timer` | $05A8 | Hit stun timer (set to $12, decrements) |
| `boss_work_var2` | $05A9 | General-purpose work variable 2 (aliased per-boss) |
| `boss_hit_count` | $05AA | Weapon hit counter |
| `player_y_screen` | $F9 | Boss fight active flag |
| `boss_state_flag` | $BD | Boss-specific state flag |
| `boss_mode_flag` | $BC | Boss mode / sound state flag |

### Boss AI Entry Points (bank0B)

Boss AI is dispatched through `enemy_ai_routine_lo/hi` (bank0B:93). Each boss's per-frame AI handler is in bank $0B:

| Boss | ID | AI Section | Description |
|---|---|---|---|
| Heat Man | 0 | bank0B:213 | Fire dash and 3-shot burst patterns |
| Air Man | 1 | bank0B:445 | Tornado pattern spawning and jump movement |
| Wood Man | 2 | bank0B:637 | Leaf Shield creation and leaf projectile toss |
| Bubble Man | 3 | bank0B:809 | Bubble shot aiming and ceiling bounce |
| Quick Man | 4 | bank0B:1008 | Fast movement and boomerang attacks |
| Flash Man | 5 | bank0B:1236 | Time Stopper activation and buster shot patterns |
| Metal Man | 6 | bank0B:1421 | Metal Blade throws and jump patterns |
| Crash Man | 7 | bank0B:1635 | Crash Bomber aiming and jump patterns |
| Mecha Dragon | 8 | bank0B:1919 | Battle collision and fire breath |
| Picopico-kun | 9 | bank0B:2275 | Entity spawning and block splitting |
| Guts-Dozer | 10 | bank0B:2458 | Nametable scrolling and turret control |
| Boobeam Trap | 11 | bank0B:2784 | Turret spawning and position tables |
| Wily Machine | 12 | bank0B:2989 | Movement and bouncing ball attacks |
| Alien | 13 | bank0B:3320 | Hologram movement and shot patterns |

Boss sub-entity AI for Wily bosses (dragon segments, turrets, etc.) is in bank0E:6827–7170.

---

## 4. Enemy Data

### HP System

All enemies have **HP = 20** ($14). This value comes from entity array aliasing: `entity_init_from_type` (bank0F:3305) writes `#$14` to `ent_timer,x` for the entity slot. Due to the 16-byte array layout, `ent_timer` for enemy init slots ($00-$0F) maps to the same physical RAM as `ent_hp` for enemy AI slots ($10-$1F): `$06D0+slot`.

The number of buster hits to kill depends on the per-type damage value in `weapon_dmg_buster_tbl` (bank0F:5437, 128 entries indexed by entity type). On **Normal** difficulty, `apply_difficulty_modifier` (bank0F:5419) doubles weapon damage via `ASL temp_00`, so enemies die in roughly half the hits.

Formula: **buster hits = ceil(20 / (base_damage x difficulty_multiplier))**

Where difficulty_multiplier = 2 (Normal) or 1 (Difficult). Enemies with base_damage = 0 are **immune to buster** but may be vulnerable to other weapons via separate collision handlers (9 weapon handlers dispatched via `weapon_collision_dispatch`, bank0F:4983).

Special cases:
- **Tanishi** ($0A): AI checks `ent_hp < $14` — any hit that reduces HP below 20 triggers shell-shed, spawning Tanishi Bare ($0B) as a new entity with fresh HP=20. On Normal, buster does 20 damage (instant kill, no shell-shed). On Difficult, buster does 10 (HP drops to 10, shell sheds, bare form needs 2 more hits).
- **Collision gating**: `ent_flags` bits 0-1 control collision eligibility (tested by `apply_entity_physics_alt`, $EFB3 in bank0F). Bit 0 = player contact, bit 1 = weapon collidable. Entities with both bits clear (e.g. flags $A0) skip all collision checks: Goblin ($40/$41), Laser Beam ($14), and controller-type entities ($1C/$47).
- **Multi-entity hitboxes**: Some large enemies render as background metatiles via a controller entity (flags $A0, immune) and spawn a child entity that serves as the hitbox. Examples: Friender ($1C controller → $19 hitbox, reuses ENTITY_FIRE_PROJ_A type), Mole ($47 controller → child hitbox). The child carries the actual HP and weapon damage values.
- **Neo Metall** ($34/$56): Switches between hittable ($34, helmet up) and invulnerable ($56, helmet down) entity types.

### Weapon Damage Tables

The weapon damage system uses multiple sub-tables in bank0F, all indexed by entity type ($00-$7F). Each weapon's collision handler references a specific table:

| Weapon | Table ($addr) | Handler |
|---|---|---|
| Buster (uncharged) | `weapon_dmg_buster_tbl` ($E998) | `weapon_hit_buster` |
| Atomic Fire (uncharged) | `weapon_dmg_buster_tbl` ($E998) | `weapon_hit_atomic` |
| Atomic Fire (mid-charge) | `weapon_dmg_buster_tbl` × 3 | `weapon_hit_atomic` |
| Atomic Fire (full) | `weapon_dmg_atomic_tbl` ($EA14) | `weapon_hit_atomic` |
| Air Shooter | `weapon_dmg_air_tbl` ($EA8C) | `weapon_hit_air` |
| Leaf Shield | `weapon_dmg_leaf_tbl` ($EB04) | `weapon_hit_leaf` |
| Bubble Lead | `weapon_dmg_bubble_tbl` ($EB7C) | `weapon_hit_bubble` |
| Quick Boomerang | `weapon_dmg_quick_tbl` ($EBF4) | `weapon_hit_quick` |
| Metal Blade | `weapon_dmg_metal_tbl` ($ECE4) | `weapon_hit_metal` |
| Crash Bomber | `weapon_dmg_crash_tbl` ($EC6C) | `weapon_hit_crash` |
| Time Stopper | — (no collision damage) | `apply_difficulty_modifier` (no-op) |

On Normal mode, `apply_difficulty_modifier` (bank0F:5419) doubles weapon damage via `ASL temp_00`.

### AI Dispatch

All entity AI is dispatched via `entity_ai_ptr_lo/hi/bank` (bank0E:2656) — 128 entries for types $00-$7F. Main AI code lives in bank $0E. NULL AI stub at `kerog_physics_rts` (bank0E:3183, just an RTS) is shared by entity types that need no per-frame update (projectiles using physics only).

For the complete entity type constant list, see `include/constants.inc`.

---

### Heat Man Stage

Stage $00 — entity bank $00 (shared with Wily 1)

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Telly (spawn) | $21 | -- | `telly_spawn_ai` (bank0E:4453) | Invisible spawner; creates Telly body |
| Telly (body) | $22 | 1/1 | `telly_ai` (bank0E:4472) | Homing movement toward player |
| Springer | $46 | -- | `springer_ai` (bank0E:5816) | Bouncing; immune to buster |
| Appear Block A | $53 | -- | `appear_block_a_ai` (bank0E:6451) | Yoku block, cycle timer $7D |
| Appear Block B | $54 | -- | `appear_block_b_ai` (bank0E:6454) | Yoku block, cycle timer $BB |
| Appear Block C | $55 | -- | `appear_block_c_ai` (bank0E:6457) | Yoku block, cycle timer $FA |

### Air Man Stage

Stage $01 — entity bank $01 (shared with Wily 2)

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Goblin A | $40 | -- | `goblin_ai_init` (bank0E:5594) | **Invulnerable** (no_collide) |
| Goblin B | $41 | -- | `goblin_ai_init` (bank0E:5594) | **Invulnerable** (no_collide) |
| Goblin Horn | $44 | -- | `goblin_horn_ai` (bank0E:5754) | Child of Goblin; **invulnerable**, contact dmg |
| Petit Goblin | $45 | 1/1 | `petit_goblin_ai` (bank0E:5785) | Child of Goblin; max 3 active |
| Kaminari Goro | $3E | -- | `kaminari_goro_ai` (bank0E:5540) | Spawner; immune to buster (dmg=$00). Spawns Cloud ($3D) + Bolt ($3F) |
| Kaminari Cloud | $3D | -- | `kaminari_cloud_ai` (bank0E:5498) | Body child; flags $83. Buster dmg=$07 but practically unreachable (cloud stays above player) |
| Kaminari Bolt | $3F | -- | NULL stub | Lightning projectile |
| Matasaburo | $36 | 3/5 | `matasaburo_wind_push` (bank0E:5282) | Wind-pushing fan |
| Pipi (spawn) | $37 | -- | `pipi_spawn_ai` (bank0E:5300) | Chain: $37 → $38 bird → $3A egg → $3C Copipi |
| Pipi (bird) | $38 | 1/1 | `pipi_ai` (bank0E:5358) | Dynamic child |
| Scworm Nest | $50 | 3/5 | `scworm_nest_ai` (bank0E:6343) | Spawns up to 3x Scworm ($51); dmg=$04 |
| Scworm | $51 | 3/5 | `scworm_worm_ai` (bank0E:6371) | Jumping worm child; dmg=$04 |
| Fly Boy (spawn) | $2B | -- | `fly_boy_spawn_ai` (bank0E:4752) | Invisible; spawns body ($2C) |
| Fly Boy (body) | $2C | 3/5 | `fly_boy_ai` (bank0E:4771) | Propeller enemy |
| Press | $30 | -- | `press_ai` (bank0E:4862) | Descending crusher; immune to buster |
| Crazy Cannon | $4B | 3/5 | `crazy_cannon_ai` (bank0E:6049) | Stationary cannon |
| Mole | $47 | 3/5 | bank0E:5911 (data overlap) | Controller (flags $A0, immune); in-game 3/5 via child hitbox. Spawns copies + shots ($48/$49) |

### Wood Man Stage

Stage $02 — entity bank $02 (shared with Wily 3)

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Robbit | $17 | 5/10 | bank0E:$9F22 | Jumping rabbit |
| Batton | $16 | 1/2 | bank0E:$9E81 | Bat; swoops from ceiling |
| Friender | $1C | 10/20 | `friender_ai` (bank0E:4115) | Fire dog; BG-tile controller (flags $A0). Invisible hitbox child reuses type $19 (ENTITY_FIRE_PROJ_A, dmg=$01). Spawns fire projectile $1A (ENTITY_FIRE_PROJ_B) |
| Monking | $1D | 2/3 | bank0E:$A2F4 | Monkey; throws projectiles |
| Kukku (spawn) | $1E | -- | `kukku_spawner_ai` (bank0E:4373) | Invisible; tracks player X, spawns body every 31 frames |
| Kukku (body) | $1F | 5/10 | `kukku_body_ai` (bank0E:4415) | Bouncing chicken |
| Kukku (despawn) | $20 | -- | `kukku_despawn_ai` (bank0E:4448) | Clears all $1E at screen transitions |
| Tanishi | $0A | 1/2 | `tanishi_ai_main` (bank0E:3099) | Shell-shed on damage; see HP System |
| Tanishi (bare) | $0B | 1/2 | NULL stub | Spawned after shell-shed |
| Pipi (spawn) | $37 | -- | `pipi_spawn_ai` (bank0E:5300) | Chain: $37 → $38 → $3A → $3C |

### Bubble Man Stage

Stage $03 — entity bank $03 (shared with Wily 4)

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Shrink | $00 | 2/3 | `shrink_ai_preamble` (bank0E:2713) | Shrimp enemy |
| Anko (body) | $01 | 2/3 | `shrink_ai_preamble` (bank0E:2713) | Multi-part anglerfish; dmg=$07. Wiki claims 5/10 — discrepancy unresolved (possible custom HP) |
| Anko (segment) | $03 | 1/1 | `anko_seg_entry` (bank0E:2819) | Body segment, tracks parent |
| M-445 | $04 | 1/1 | bank0E:$95D7 | Jellyfish |
| Claw | $07 | 1/1 | `claw_ai_entry` (bank0E:2969) | Crab enemy |
| Claw (variant) | $08 | 1/1 | `claw_var_ai_entry` (bank0E:3029) | Dropping crab variant |
| Kerog | $0C | 5/10 | `kerog_ai_entry` (bank0E:3190) | Large frog; spawns Petit Kerog ($0D) |
| Petit Kerog | $0D | 1/1 | bank0E:$988F | Small froglet child |
| Tanishi | $0A | 1/2 | `tanishi_ai_main` (bank0E:3099) | Shell-shed on damage |
| Crumble Block | $13 | -- | bank0E:$9C5B | Falls when stepped on; not hittable |

### Quick Man Stage

Stage $04 — entity bank $04 (shared with Wily 5)

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Springer | $46 | -- | `springer_ai` (bank0E:5816) | Bouncing; immune to buster |
| Changkey | $23 | 5/10 | `changkey_ai` (bank0E:4487) | Flame enemy; spawns projectile ($24) |
| Changkey Proj | $24 | -- | NULL stub | Fireball; physics-only movement |
| Laser Beam | $14 | -- | `laser_beam_ai` (bank0E:3607) | **Instant kill**; **invulnerable** (no_collide) |
| Sniper Armor | $4E | 10/20 | `sniper_armor_ai` (bank0E:6155) | Armored; converts to Joe ($4F) on armor break |
| Sniper Joe | $4F | 5/10 | `sniper_joe_ai` (bank0E:6288) | Unarmored; fires 3x Generic Proj ($35) |
| Blackout Trigger | $25 | -- | `blackout_trigger_ai` (bank0E:4558) | Screen darkening mechanic |
| Blackout End | $27 | -- | NULL stub | Permanent light restore marker |

### Flash Man Stage

Stage $05 — entity bank $05

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Sniper Armor | $4E | 10/20 | `sniper_armor_ai` (bank0E:6155) | Armored; converts to Joe ($4F) |
| Sniper Joe | $4F | 5/10 | `sniper_joe_ai` (bank0E:6288) | Unarmored; fires $35 projectiles |
| Crazy Cannon | $4B | 3/5 | `crazy_cannon_ai` (bank0E:6049) | Stationary cannon |
| Scworm Nest | $50 | 3/5 | `scworm_nest_ai` (bank0E:6343) | Spawns up to 3x Scworm ($51); dmg=$04 |
| Scworm | $51 | 3/5 | `scworm_worm_ai` (bank0E:6371) | Jumping worm child; dmg=$04 |
| Blocky | $31 | 1/2 | `blocky_ai` (bank0E:4978) | Block enemy; multi-phase ($32/$33) |
| Flash Hazard | $72/$73 | -- | `flash_hazard_ai` (bank0E:7283) | Stage-specific hazard entities |

### Metal Man Stage

Stage $06 — entity bank $06

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Press | $30 | -- | `press_ai` (bank0E:4862) | Descending crusher; immune to buster |
| Press (retract) | $52 | -- | `press_retract_ai` (bank0E:6441) | Ascending return phase |
| Mole | $47 | 3/5 | bank0E:5911 (data overlap) | Controller (flags $A0, immune); in-game 3/5 via child hitbox. Spawns copies + shots ($48/$49) |
| Mole (despawn) | $4A | -- | bank0E:$B20B | Clears all Mole entities on screen exit |
| Gear | $29 | 2/4 | `gear_ai` (bank0E:4640) | Rotating cog platform |
| Pierrobot | $2A | 1/1 | `pierrobot_ai` (bank0E:4736) | Rides Gear; child entity |
| Blocky | $31 | 1/2 | `blocky_ai` (bank0E:4978) | Block enemy |
| Springer | $46 | -- | `springer_ai` (bank0E:5816) | Bouncing; immune to buster |

### Crash Man Stage

Stage $07 — entity bank $07

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Telly (spawn) | $21 | -- | `telly_spawn_ai` (bank0E:4453) | Spawns Telly body ($22) |
| Telly (body) | $22 | 1/1 | `telly_ai` (bank0E:4472) | Homing movement |
| Neo Metall | $34 | 1/1 | bank0E:$AA4E | Hittable when helmet is up |
| Neo Metall (flip) | $56 | -- | `neo_metall_flip_ai` (bank0E:6507) | **Invulnerable** hiding phase (no_collide) |
| Rail Platform | $12 | -- | `rail_platform_ai` (bank0E:3446) | Moving platform |
| Blocky | $31 | 1/2 | `blocky_ai` (bank0E:4978) | Block enemy |
| Pipi (spawn) | $37 | -- | `pipi_spawn_ai` (bank0E:5300) | Chain: $37 → $38 → $3A → $3C |
| Crazy Cannon | $4B | 3/5 | `crazy_cannon_ai` (bank0E:6049) | Stationary cannon |
| Fly Boy (spawn) | $2B | -- | `fly_boy_spawn_ai` (bank0E:4752) | Spawns body ($2C) |
| Fly Boy (body) | $2C | 3/5 | `fly_boy_ai` (bank0E:4771) | Propeller enemy |

---

### Wily 1 — Mecha Dragon

Stage $08 — entity bank $00 (shared with Heat Man)

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Sniper Armor | $4E | 10/20 | `sniper_armor_ai` (bank0E:6155) | Armored |
| Sniper Joe | $4F | 5/10 | `sniper_joe_ai` (bank0E:6288) | Child of Sniper Armor |
| Pipi (spawn) | $37 | -- | `pipi_spawn_ai` (bank0E:5300) | Full chain: bird → egg → Copipi |
| Scworm Nest | $50 | 3/5 | `scworm_nest_ai` (bank0E:6343) | Spawns Scworm ($51); dmg=$04 |

Boss sub-entities: Mecha Dragon fireball ($33), body segments ($63/$64), body parts ($65/$66/$67), breath ($68).

### Wily 2 — Picopico-kun

Stage $09 — entity bank $01 (shared with Air Man)

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Mole | $47 | 3/5 | bank0E:5911 (data overlap) | Controller (flags $A0, immune); in-game 3/5 via child hitbox |
| Crazy Cannon | $4B | 3/5 | `crazy_cannon_ai` (bank0E:6049) | Stationary cannon |
| Crazy Cannon (flip) | $4C | 3/5 | `crazy_cannon_ai` (bank0E:6049) | Flipped variant; same AI |

Boss sub-entities: Picopico-kun block halves ($6A).

### Wily 3 — Guts-Dozer

Stage $0A — entity bank $02 (shared with Wood Man)

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Tanishi | $0A | 1/2 | `tanishi_ai_main` (bank0E:3099) | Shell-shed on damage |
| Big Fish | $71 | -- | `big_fish_ai_main` (bank0E:7223) | Gray fish; HP=1, immune to buster. Only Quick Boomerang + Crash Bomber work (1 hit) |
| Crazy Cannon | $4B | 3/5 | `crazy_cannon_ai` (bank0E:6049) | Stationary cannon |
| Neo Metall (flip) | $56 | -- | `neo_metall_flip_ai` (bank0E:6507) | **Invulnerable** hiding phase |

Boss sub-entities: Guts-Dozer body ($63), turret ($69).

### Wily 4 — Boobeam Trap

Stage $0B — entity bank $03 (shared with Bubble Man)

| Enemy | Type | Buster (N/D) | AI Routine | Notes |
|---|---|---|---|---|
| Neo Metall | $34 | 1/1 | bank0E:$AA4E | Hittable when helmet up |
| Telly (spawn) | $21 | -- | `telly_spawn_ai` (bank0E:4453) | Spawns body ($22) |
| Telly (body) | $22 | 1/1 | `telly_ai` (bank0E:4472) | Homing movement |
| Rail Platform | $12 | -- | `rail_platform_ai` (bank0E:3446) | Moving platform |
| Sniper Armor | $4E | 10/20 | `sniper_armor_ai` (bank0E:6155) | Armored |
| Sniper Joe | $4F | 5/10 | `sniper_joe_ai` (bank0E:6288) | Child of Sniper Armor |

Boss sub-entities: Boobeam turrets ($6D, 5 placed), Boobeam shots ($6E). Only vulnerable to Crash Bomber.

### Wily 5 — Wily Machine

Stage $0C — entity bank $04 (shared with Quick Man)

No regular stage enemies — **boss teleporter room** (Robot Master refights).

Boss sub-entities: Wily Machine bouncing ball ($6B), shot ($6C).

### Wily 6 — Alien

Stage $0D — entity bank $05 (shared with Flash Man)

No regular stage enemies — **final boss encounter only**.

Boss sub-entities: Alien shot ($6F), Alien body ($70), red liquid drip ($74). Only vulnerable to Bubble Lead.

### Entity Property Tables (bank0F:3371)

| Table | Location | Entries | Description |
|---|---|---|---|
| `entity_flags_table` | bank0F:3371 | 128 | Default spawn flags per entity type |
| `entity_hitbox_width_idx_tbl` | bank0F:3387 | 128 | Hitbox width lookup index |
| `entity_hitbox_height_idx_tbl` | bank0F:3403 | 128 | Hitbox height lookup index |
| `entity_ai_behavior_tbl` | bank0F:3421 | 128 | AI behavior mode index |

Entity flag bitmasks (`ent_spawn_flags` / `ent_flags`):

| Mask | Constant | Meaning |
|---|---|---|
| $80 | `ENT_FLAG_ACTIVE` | Entity is alive/spawned |
| $40 | `ENT_FLAG_FLIP_H` | Facing left (horizontally flipped) |
| $20 | `ENT_FLAG_NO_COLLIDE` | Skip collision checks |
| $02 | `ENT_FLAG_WEAPON_HIT` | Was hit by weapon this frame |
| $01 | `ENT_FLAG_CONTACT_DMG` | Deals contact damage |

### Spawn Table Format

Entity spawn data is stored in stage banks ($00–$09) as 4 parallel arrays at fixed bank offsets:

| Offset | Contents | Example address (bank $03) |
|---|---|---|
| $3600 | Screen number | $B600,y |
| $3700 | X position (pixels) | $B700,y |
| $3800 | Y position (pixels) | $B800,y |
| $3900 | Entity type ID | $B900,y |

Entries are sorted by screen number and 1-indexed. Secondary spawn tables (persistent objects) are 4 × 64-byte arrays at $3A00-$3AFF; stage palettes live in the $3E00/$3F00 blocks. See section 6 for the full entity-bank layout.

Banks $00–$04 share tables between the Robot Master stage and a Wily stage (using `AND #$07` to select entity data). Banks $05–$07 contain Robot Master data only.

### Dynamic Spawn Chains

Several enemy types use parent→child spawn relationships via `spawn_entity_from_parent` (bank0F:6071):

| System | Chain | Despawner |
|---|---|---|
| Kukku | $1E (invisible) → $1F (body) | $20 clears all $1E |
| Pipi | $37 → $38 (bird) → $3A (egg) → $3C (Copipi) | $39 clears all $37 |
| Mole | $47 (controller) → $47 copies + $48/$49 shots | $4A clears all $47 |
| Scworm | $50 (nest) → up to 3× $51 (worm) | — |
| Sniper Armor | $4E → $4F (unarmored Joe) on death | — |

### Contact Damage to Player

`contact_damage_to_player_tbl` (bank0F:5558) — 128 entries indexed by entity type ($00–$7F). Damage is subtracted directly from player HP in `check_player_collision` (bank0F:4847). **Not affected by difficulty** — values are the same on Normal and Difficult.

Boss contact damage uses a separate table: `boss_contact_damage_table` (bank0B:5126) — see Section 3.

#### Enemy Contact Damage

| Enemy | Type | Damage | Notes |
|---|---|---|---|
| Shrink | $00 | 2 | |
| Anko (body) | $01 | 2 | Head segments ($10) deal 12 |
| M-445 | $04 | 2 | |
| Claw / Claw variant | $07/$08 | 4 | |
| Tanishi / bare | $0A/$0B | 4 | Both forms same damage |
| Kerog | $0C | 4 | |
| Petit Kerog | $0D | 1 | Lowest contact damage |
| Laser Beam | $14 | 0 | Instant kill via separate handler |
| Batton | $16 | 4 | |
| Robbit | $17 | 4 | |
| Monking | $1D | 4 | |
| Kukku (body) | $1F | 4 | |
| Telly (body) | $22 | 2 | |
| Changkey | $23 | 8 | High contact damage |
| Gear | $29 | 4 | |
| Pierrobot | $2A | 4 | |
| Fly Boy (body) | $2C | 4 | |
| Press / retract | $30/$52 | 8 | |
| Blocky | $31 | 8 | All phases same |
| Neo Metall | $34 | 4 | |
| Neo Metall (flip) | $56 | 10 | Higher damage while hiding |
| Matasaburo | $36 | 6 | |
| Pipi (bird) | $38 | 4 | |
| Copipi | $3C | 2 | |
| Kaminari Cloud | $3D | 4 | |
| Petit Goblin | $45 | 2 | |
| Springer | $46 | 4 | |
| Crazy Cannon | $4B | 4 | |
| Sniper Armor | $4E | 8 | |
| Sniper Joe | $4F | 4 | |
| Scworm nest / worm | $50/$51 | 2 | |
| Big Fish | $71 | 10 | |
| Flash Hazard | $72/$73 | 10 | |

#### Projectile Damage to Player

Enemy and boss projectiles use the same `contact_damage_to_player_tbl`:

| Projectile | Type | Damage | Fired by |
|---|---|---|---|
| Changkey fireball | $24 | 3 | Changkey ($23) |
| Generic projectile | $35 | 2 | Neo Metall, Sniper Joe, Picopico-kun |
| Kaminari bolt | $3F | 2 | Kaminari Goro ($3E) |
| Goblin horn | $44 | 2 | Goblin ($40/$41) |
| Mole shot (up/down) | $48/$49 | 4 | Mole ($47) |
| Mecha Dragon fireball | $33 | 4 | Mecha Dragon |
| Heat Man fire | $58 | 4 | Heat Man |
| Quick Man boomerang | $59 | 4 | Quick Man |
| Bubble Man shot | $5B | 4 | Bubble Man |
| Air Man tornado | $5D | 4 | Air Man |
| Crash Bomb (boss) | $5E | 4 | Crash Man |
| Metal Blade (enemy) | $15 | 28 | Metal Man — **instant kill** |
| Picopico-kun halves | $6A | 8 | Picopico-kun |
| Wily Machine ball | $6B | 6 | Wily Machine |
| Boobeam shot | $6E | 4 | Boobeam Trap |
| Alien shot | $6F | 6 | Alien |
| Red liquid drip | $74 | 10 | Alien stage hazard |

---

## 5. Player Values

### Entity Slot Map

16 physical entity slots ($00–$0F). All spawned entities (enemies, projectiles, items) share slots $02–$0F. The renderer processes 32 virtual slots ($00–$1F) — slots $10–$1F alias to `ent_spawn_type` ($0410,x) via array overlap, so each spawned entity appears in the weapon renderer automatically.

| Slots | Purpose |
|---|---|
| $00 | Player (Mega Man) |
| $01 | Boss (during boss fights) |
| $02–$0F | All spawned entities (enemies, projectiles, items) |

Entity slot $01 is directly accessible via `boss_*` equates in `include/ram.inc` (e.g., `boss_hp` = `ent_hp + 1` = $06C1).

### Physics Constants

| Parameter | Value | Location |
|---|---|---|
| Gravity (normal) | $40 (sub-pixel accel) | `gravity_hi_table` bank0E:1478 |
| Gravity (water) | $1E | `gravity_hi_table+1` bank0E:1474 |
| Jump velocity | $04.DF (initial Y vel) | Set in player jump code |
| Terminal velocity | $F4 (max Y fall speed) | Clamped in physics |
| Knockback Y vel | $01.40 | `player_damage_knockback` bank0F:2852 |
| Knockback X vel | $00.90 | `player_damage_knockback` bank0F:2852 |
| I-frame duration | $6F (111 frames) | `player_damage_knockback` bank0F:2852 |
| Default entity timer | $14 (20 frames) | `entity_init_from_type` bank0F:3305 |

### Player State Variables

| Variable | Address | Description |
|---|---|---|
| `ent_hp` | $06C0 | Player hit points |
| `current_weapon` | $A9 | Selected weapon ID ($00–$0B) |
| `weapon_ammo` | $9C–$9F | Weapon ammo array |
| `weapon_energy` | $A0–$A6 | Weapon/item energy array |
| `current_lives` | $A8 | Lives remaining |
| `current_etanks` | $A7 | E-Tank count |
| `invincibility_timer` | $4B | I-frame countdown |
| `game_substate` | $2C | Game sub-state / weapon select |
| `beaten_bosses` | $9A | Boss beaten bitmask low |
| `beaten_bosses_hi` | $9B | Boss beaten bitmask high |

### Player State Base Sprites

`player_state_sprite_tbl` (bank0F:2934) — indexed by `game_substate` (player
state), gives Mega Man's base sprite type; `weapon_fire_dir` offsets it to
the gun-out variant while firing. (Long documented as a weapon → projectile
mapping — it is actually per player state.)

| State | Base Type | Meaning |
|---|---|---|
| $00 | $1A | Teleport beam |
| $01 | $19 | Teleport materialize |
| $02 | $18 | Damage / knockback |
| $03 | $00 | Standing |
| $04 | $04 | Running |
| $05 | $08 | Jumping / airborne |
| $06 | $0C | Climbing |
| $07 | $10 | Sliding |
| $08 | $14 | (reserved pose) |
| $09-$0B | $1B/$1F/$26 | Cutscene poses |

Actual projectile entity types are set per weapon by the `fire_weapon_*`
handlers via `projectile_type_tbl` (bank0F:2992, used by `weapon_spawn_projectile`).

### Weapon Fire Dispatch

`weapon_dispatch_lo/hi_tbl` (bank0F:3741) — 12 entries indexed by `current_weapon`. Each handler checks B button and spawns a projectile entity via `weapon_spawn_projectile` (bank0F:2944).

| Index | Weapon | Fire Handler | Spawn Y | Entity Type | Flags | Position Handler |
|---|---|---|---|---|---|---|
| 0 | Mega Buster | `fire_weapon_buster` | Y=0 | $23 | $81 | normal physics |
| 1 | Atomic Fire | `fire_weapon_atomic` | Y=1 | $30 | $83 | `atomic_fire_ai` |
| 2 | Air Shooter | `fire_weapon_air` | Y=2 | $31 | $83 | `air_shooter_ai` |
| 3 | Leaf Shield | `fire_weapon_leaf` | Y=3 | $32 | $82 | `leaf_shield_orbit_ai` |
| 4 | Bubble Lead | `fire_weapon_bubble` | Y=4 | $33 | $87 | `bubble_lead_ai` |
| 5 | Quick Boomerang | `fire_weapon_quick` | Y=5 | $34 | $83 | `quick_boomerang_ai` |
| 6 | Time Stopper | `fire_weapon_time_stopper` | Y=8 | $37 | $82 | `time_stopper_ai` |
| 7 | Metal Blade | `fire_weapon_metal` | Y=7 | $36 | $81 | normal physics |
| 8 | Crash Bomber | `fire_weapon_crash` | Y=6 | $35 | $83 | `crash_bomber_ai` |
| 9 | Item 1 | `fire_weapon_item1` | Y=9 | $38 | $82 | `item1_platform_ai` |
| 10 | Item 2 | `fire_weapon_item2` | Y=A | $39 | $82 | `item2_jet_ai` |
| 11 | Item 3 | `fire_weapon_item3` | Y=B | $3A | $86 | `item3_climber_ai` |

**Dual-purpose entity types**: Projectile entity types ($23, $2F–$3E) are reused IDs that also serve as enemy types (Changkey, Boss Door, Press, Blocky, etc.). When spawned as weapon projectiles they occupy weapon renderer slots ($10–$1F) and use separate AI via `entity_special_dispatch_lo/hi` (bank0F:3836) instead of the main entity AI table.

**Projectile flags bit 1**: Determines position update path. Set = special dispatch (`entity_special_dispatch_lo/hi`, custom handler). Clear = normal `apply_entity_physics`. Buster ($23) and Metal Blade ($36) use normal physics; all others use custom handlers.

---

## 6. Stage Data Format

### Stage → Bank Mapping

A stage's data bank is simply `current_stage AND #$07` — layouts, metatiles,
spawns, checkpoints, CHR lists and palettes for a Robot Master stage and its
paired Wily stage share one bank. CHR pattern data is pulled from explicit
(bank, page) reference lists and can live in any bank.

`stage_music_table` (bank0E:334) maps `current_stage` to the stage MUSIC
track. (It was long believed to be a "tile bank" table — the values only
resemble bank numbers because of the music track numbering.)

| Stage | Index | Data Bank (AND $07) | File | Boss |
|---|---|---|---|---|
| Heat Man | $00 | $00 | `bank00_heat_wily1.asm` | Heat Man |
| Air Man | $01 | $01 | `bank01_air_wily2.asm` | Air Man |
| Wood Man | $02 | $02 | `bank02_wood_wily3.asm` | Wood Man |
| Bubble Man | $03 | $03 | `bank03_bubble_wily4.asm` | Bubble Man |
| Quick Man | $04 | $04 | `bank04_quick_wily5.asm` | Quick Man |
| Flash Man | $05 | $05 | `bank05_flash_wily6.asm` | Flash Man |
| Metal Man | $06 | $06 | `bank06_metal.asm` | Metal Man |
| Crash Man | $07 | $07 | `bank07_crash.asm` | Crash Man |
| Wily 1 | $08 | $00 | `bank00_heat_wily1.asm` | Mecha Dragon |
| Wily 2 | $09 | $01 | `bank01_air_wily2.asm` | Picopico-kun |
| Wily 3 | $0A | $02 | `bank02_wood_wily3.asm` | Guts-Dozer |
| Wily 4 | $0B | $03 | `bank03_bubble_wily4.asm` | Boobeam Trap |
| Wily 5 | $0C | $04 | `bank04_quick_wily5.asm` | Wily Machine |
| Wily 6 | $0D | $05 | `bank05_flash_wily6.asm` | Alien |

Within a bank, the RM stage's rooms occupy low screen indices ($00+) and the
Wily stage's rooms start around $16-$18 (exact ranges in each bank file's
`screen_layouts` header). Banks $08/$09 are never stage banks: $08 holds
menu/cutscene CHR, $09 holds shared CHR + the ending engine and credits.

### Per-Bank Data Layout

Each stage bank (`current_stage AND #$07`) holds all of its stage pair's
data: layouts at $8000-$8FFF+ and gameplay tables at $B400-$BF61. CHR
pattern regions in between are shared property, referenced cross-bank.

**Layout region:**

| Address | Contents |
|---|---|
| $8000-$83FF | Metatile definitions — 256 entries × 4 quadrant bytes (order TL, BL, TR, BR via `metatile_offset_table`) |
| $8400-$84FF | Metatile attribute bytes — one palette byte per metatile (a 32×32 px metatile = exactly one NES attribute byte) |
| $8500+ | Screen layouts — 64 bytes per screen, column-major (index = col×8 + row), 8×8 metatiles = 256×256 px |
| varies | CHR tile pattern data — located per bank via the CHR upload lists ($BC00/$BD00), the fixed-bank group tables (`chr_bank_src_*`, bank0F:1101), and the per-screen overlay lists ($B460) |

Each quadrant byte = `[collision:2][tile group:6]` — bits 7-6 are the
collision class (see below), bits 5-0 select CHR tiles `G*4 .. G*4+3` as a
16×16 px 2×2 tile block (consecutive CHR indices). Loaders: `column_data_copy`
(bank0F:1473, rendering), `lookup_tile_from_map` (bank0F:1824, collision),
`render_full_nametable` (bank0E:2311, `ptr = $8500 + screen×$40`).

**Gameplay tables:**

| Address | Contents |
|---|---|
| $B400+ | Per-screen connectivity flags (`get_screen_boundary`, bank0F:1202) — masked by `scroll_left/right_mask_table` per `transition_type` to permit exits |
| $B42C+ | Per-screen index into the CHR overlay list and sprite palette sets |
| $B460+ | Enemy CHR overlay list — (src_page, src_bank) pairs; 6 pages (1.5 KB) per set → pattern table $0A00-$0FFF (`scroll_column_render`, `checkpoint_respawn`) |
| $B46C+ | Sprite palette sets — 6 bytes each (colors for sprite palettes 2-3), loaded per screen via `scroll_col_load_palette` (bank0F:1758) |
| $B600/$B700/$B800/$B900 | Primary spawn arrays: screen / X / Y / entity type — 1-indexed, sorted by screen (`entity_spawn_scan` bank0F:3159) |
| $BA00/$BA40/$BA80/$BAC0 | Secondary spawn arrays (max 64 entries): screen / X / Y / type for persistent objects — HP lives in RAM (`ent_child_hp`), so destroyed objects (e.g. Crash walls) stay destroyed across respawns |
| $BB00-$BB41 | Checkpoint tables — 11 arrays × 6 entries (below) |
| $BC00 / $BD00 | CHR upload list, RM / Wily stage: `[count, (src_page, page_count, src_bank) × count]` → CHR-RAM from $0000 (`chr_upload_init` bank0F:799) |
| $BE00-$BE61 / $BF00-$BF61 | Palette block, RM / Wily stage: anim_target, anim_counter, 32-byte palette, 4 × 16-byte palette animation frames — copied verbatim to $0354-$03B5 |

**Checkpoint tables** (index = `checkpoint_idx` $B0, 0-5; Wily stages use
slots 3-5 of the paired RM bank):

| Address | Restored to |
|---|---|
| $BB00 | Boss-entrance landing Y (`boss_entrance_scroll`) |
| $BB06 | `nametable_select` / `ent_x_screen` (checkpoint screen; also scanned as death thresholds via $BB07) |
| $BB0C | Primary spawn scan index (`spawn_scan_bwd/fwd`) |
| $BB12 | Secondary spawn scan index |
| $BB18 / $BB1E | `metatile_ptr_hi/lo` |
| $BB24 / $BB2A | `column_ptr_hi/lo` |
| $BB30 | `current_screen` |
| $BB36 / $BB3C | `scroll_screen_lo/hi` |

### Metatile Format

A metatile is 32×32 px = four 16×16 quadrants. The definition entry
($8000 + ID×4) holds one byte per quadrant: bits 7-6 = collision class,
bits 5-0 = tile group (× 4 = first of four consecutive CHR tile indices).
The screen layout supplies metatile IDs; the attribute byte comes from the
parallel $8400 table.

| Collision bits | Base meaning |
|---|---|
| 0 | Empty / passthrough |
| 1 | Solid |
| 2 | Stage-specific (see table below) |
| 3 | Stage-specific (see table below) |

### Stage Collision Type Table

`stage_collision_table` (bank0F:1915) — maps collision bits 2 and 3 to specific types per stage:

| Stage | Bit 2 → | Bit 3 → |
|---|---|---|
| Heat Man | Ladder | Spike |
| Air Man | Ladder | Spike |
| Wood Man | Ladder | Empty |
| Bubble Man | Water | Spike |
| Quick Man | Empty | Spike |
| Flash Man | Ladder | Ice |
| Metal Man | Conveyor L | Conveyor R |
| Crash Man | Ladder | Spike |
| Wily 1 | Ladder | Empty |
| Wily 2 | Ladder | Spike |
| Wily 3 | Water | Spike |
| Wily 4 | Ladder | Spike |
| Wily 5 | Empty | Empty |
| Wily 6 | Empty | Empty |

Collision type values: $00=empty, $01=solid, $02=ladder, $03=spike (instant death), $04=water, $05=conveyor left, $06=conveyor right, $07=ice.

---

## 7. Palette Data

### RAM Mirror Layout

| Address | Size | Contents |
|---|---|---|
| $0356–$0365 | 16 bytes | BG palettes (4 × 4 colors → PPU $3F00) |
| $0366–$0375 | 16 bytes | Sprite palettes (4 × 4 colors → PPU $3F10) |
| `palette_dirty` ($3A) | 1 byte | Nonzero triggers upload to PPU during NMI |

### Weapon Palette Table

`weapon_palette_data` (bank0F:2842) — 4 bytes per weapon. Bytes 1–3 are copied to `palette_sprite+1` ($0367–$0369). Byte 0 ($0F = black) is present in the table but skipped by the copy routine:

| Weapon | Byte 0 | Color 1 | Color 2 | Color 3 |
|---|---|---|---|---|
| Mega Buster | $0F | $0F | $2C | $11 |
| Atomic Fire | $0F | $0F | $28 | $15 |
| Air Shooter | $0F | $0F | $30 | $11 |
| Leaf Shield | $0F | $0F | $30 | $19 |
| Bubble Lead | $0F | $0F | $30 | $00 |
| Quick Boomerang | $0F | $0F | $34 | $25 |
| Time Stopper | $0F | $0F | $34 | $14 |
| Metal Blade | $0F | $0F | $37 | $18 |
| Crash Bomber | $0F | $0F | $30 | $26 |
| Item 1 | $0F | $0F | $30 | $16 |
| Item 2 | $0F | $0F | $30 | $16 |
| Item 3 | $0F | $0F | $30 | $16 |

### Stage BG Palettes

Per-stage background palettes are stored at offset $3E00 within each stage bank ($00–$09). Loaded via `current_stage AND #$07` mapping, so Wily stages share palettes with their paired Robot Master stage.

---

## 8. CHR-RAM System

Mega Man 2 uses **CHR-RAM** — all tile graphics are uploaded from PRG-ROM at runtime, not bank-switched from CHR-ROM. This means:

- 8 KB of CHR-RAM filled at stage load from (src_bank, src_page) record lists
- Pattern table $0000 = sprite tiles (Mega Man $0000-$08FF from bank00 $9000,
  per-screen enemy overlay $0A00-$0FFF), $1000 = background tiles (HUD/font
  $1000+ from bank09 $8000, stage BG from the stage's own bank)
- Dynamic CHR updates stream per screen (`chr_overlay_sets`) and per effect

Stage CHR is assembled from explicit (src_bank, src_page) record lists: the stage's `chr_upload_list_rm/wily` at $BC00/$BD00 of its data bank (see section 6); menu screens use the fixed-bank chr group tables (`chr_ram_bank_load`, bank0F:1068).

---

## 9. Difficulty System

### Flag

`difficulty` ($CB) — `0` = Normal, `1` = Difficult. Default is `0`. Selected with the NORMAL/DIFFICULT cursor on the TITLE screen (bank0D `title_menu_loop`).

### Three Scaling Points

| What scales | Routine | Location | Effect |
|---|---|---|---|
| Weapon damage to bosses | `weapon_difficulty_scale` | bank0B:5084 | `ASL temp_00` on Normal → 2× damage |
| Weapon damage to enemies | `apply_difficulty_modifier` | bank0F:5419 | `ASL temp_00` on Normal → 2× damage |
| Item drop rates | `item_drop_calc` | bank0F:6230 | Different RNG thresholds |

Note: On Normal mode, weapon damage (to both bosses and regular enemies) is **doubled** — enemies die faster. Contact damage from enemies/projectiles to the player is **not** affected by difficulty. Difficult mode uses base weapon damage values as-is.

### Item Drop Rate Comparison

`item_drop_calc` (bank0F:6230) uses `rng_seed MOD 100` against threshold tables:

| Item | Normal (71% total) | Difficult (50% total) |
|---|---|---|
| Nothing | 28% | 48% |
| Small weapon energy ($79) | 10% | 25% |
| Small health ($77) | 10% | 15% |
| Large weapon energy ($78) | 30% | 5% |
| Large health ($76) | 20% | 4% |
| Extra life ($7B) | 1% | 1% |
| Nothing (tail) | 1% | 2% |

Rolls 98/99 map to nothing/1-UP (Normal) and 1-UP/nothing (Difficult); the
E-Tank drop ($7A) exists in the spawn code but is never rolled.

---

## 10. Music & Sound Effects

### Sound Engine

**Source**: `src/bank0C_sound_engine.asm` — driver AND all music/SFX data; the bank is fully self-contained (the NSFe rip uses it alone)

The sound engine processes 4 APU channels (2 pulse, 1 triangle, 1 noise) each frame. The per-frame update entry point is `sound_update_main` (bank0C:467), called via the NMI bank callback system.

Music and SFX play concurrently. An SFX claims channels via a priority byte + channel mask; on claimed channels the music state keeps advancing silently and audio resumes when the SFX ends (`sound_channel_restore` reloads the music instrument). Current priorities live in `sound_priority` ($E0): lo nybble = music, hi nybble = SFX.

**Pointer table**: `sound_header_ptr_lo/hi` at bank0C:1722 — 67 interleaved lo/hi entries for sound IDs $00-$42: music $00-$17, unused slots $18-$20, SFX $21-$42. Every track and SFX has a named label (`music_*`, `sfx_*`).

**Header formats** (byte 0 = priority):
- Music (all tracks priority $0F): byte 0, then 4 × 2-byte pattern pointer (sq1, sq2, tri, noise), then a 2-byte instrument table pointer.
- SFX: byte 0 hi nybble = priority (a new SFX must be ≥ the current one), byte 1 lo nybble = channel mask, stream data from byte 2.

### Sound Channel Structure

Each channel uses a 31-byte slot (`SND_*` fields defined at bank0C:23-53):

| Offset | Field | Purpose |
|---|---|---|
| $00-$01 | `SND_PTN_PTR_LO/HI` | Music pattern read pointer (0 = channel off) |
| $02-$03 | `SND_NOTE_DUR_LO/HI` | Note duration counter |
| $04 | `SND_PERIOD` | Tempo — note length multiplier |
| $05 | `SND_FLAGS` | Bit 7 = speed-up flag, bits 0-6 = last pattern-jump ID |
| $06 | `SND_VOL_ENV` | Volume/sweep envelope |
| $07-$08 | `SND_FREQ_TBL_LO/HI` | Frequency table pointer |
| $0D | `SND_PORTA_RATE` | Portamento rate (signed) |
| $11-$12 | `SND_STREAM_LO/HI` | SFX note value (nonzero = SFX note active) |
| $14-$15 | `SND_VIB_AMP/PHASE` | Vibrato amplitude and phase |
| $16-$17 | `SND_SWEEP_CTRL/DELTA` | Sweep control and pitch delta |

### Sound Trigger Mechanism

All music and SFX are triggered via `sound_queue_push` (bank0F:274). Values are queued in `sound_queue` ($0580) and processed during NMI through `banked_entry_alt` ($8003) in bank $0C.

```
lda     #$XX        ; sound/music ID
jsr     sound_queue_push
```

The dispatch at $8003 (bank0C:56-93) routes by value:
- **$00-$FB** → `sound_play_cmd` — load music track or SFX by ID (priority-gated)
- **$FC** → `sound_cmd_speed` — set note ticks/frame = Y+1 (no in-game callers)
- **$FD** → `sound_cmd_fade` — start music fade-out (Y = fade params; only use is Y=$A0)
- **$FE** → `sound_cmd_sfx_off` — cancel SFX, return channels to music
- **$FF** → `sound_cmd_music_off` — stop music (SFX unaffected)

### Music Track IDs

Sound IDs $00-$17 are music tracks. IDs $00-$09 are the stage themes, queued from `stage_music_table`.

| ID | Track | Trigger context |
|---|---|---|
| $00 | Flash Man Stage | `stage_music_table[$05]` |
| $01 | Wood Man Stage | `stage_music_table[$02]` |
| $02 | Crash Man Stage | `stage_music_table[$07]` |
| $03 | Heat Man Stage | `stage_music_table[$00]` |
| $04 | Air Man Stage | `stage_music_table[$01]` |
| $05 | Metal Man Stage | `stage_music_table[$06]` |
| $06 | Quick Man Stage | `stage_music_table[$04]` |
| $07 | Bubble Man Stage | `stage_music_table[$03]` |
| $08 | Dr. Wily Stage 1-2 | `stage_music_table[$08/$09]` |
| $09 | Dr. Wily Stage 3-5 | `stage_music_table[$0A/$0B/$0C]` |
| $0A | Stage Intro | Boss intro screen (bank0D:271) |
| $0B | Boss Battle | Boss door (bank0E:624, 749), Picopico-kun (bank0B:2246), Wily 4 rematch (bank0E:6938) |
| $0C | Stage Select | Stage select screen (bank0D:130) |
| $0D | Title / Ending reprise | Title screen + ending (bank0D:3383, 5492) |
| $0E | Opening | Prologue text crawl (bank0D:3203) |
| $0F | Game Over | Game over screen (bank0D:5020); also the $18-$20 dummy-slot target |
| $10 | Password | Password screens (bank0D:3528, 5044) |
| $11 | Dr. Wily Map | Map/castle cinematics (bank0D:2458, 2817) |
| $12 | Boss Get scene | Robot Master walk-in/shimmer scene (bank0D:2239) |
| $13 | Epilogue | Ending start (bank0D:5400) |
| $14 | Credits | Ending walk scene (bank0D:5560) |
| $15 | Stage Clear | Fortress defeat transition (bank0B:3981) |
| $16 | Wily Defeated | Alien defeat scene (bank0B:3849) |
| $17 | Weapon Get | "GET EQUIPPED WITH" screen (bank0D:5843) |

### SFX IDs

SFX IDs $21-$42 have headers in the same pointer table (priority + channel
mask + stream data). Names are NSFe playback-verified; call sites from the
audited source:

| ID | Sound | Primary call sites |
|---|---|---|
| $21 | Time Stopper | `fire_weapon_time_stopper` (bank0F:3709), Flash Man (bank0B:1183), Press (bank0E:4890), Sniper Armor (bank0E:6209) |
| $22 | (unused) | — |
| $23 | Metal Blade fire | bank0F:3670, Metal Man (bank0B:1492) |
| $24 | Weapon fire | Buster/Bubble/Quick/Crash fire (bank0F:3491, 3584, 3618, 3648) |
| $25 | Enemy shot | Blocky (bank0E:5185), cannons (bank0E:6112), Sniper Joe (bank0E:6241, 6308) |
| $26 | Damage recoil | `player_damage_knockback` (bank0F:2852) |
| $27 | Quick Man laser | force beams (bank0E:3691) |
| $28 | Refill tick | health/ammo refill (bank0E:521, 555), boss HP fill (bank0B:206, 4051), E-Tank menu (bank0D:1760), map route (bank0D:2555) |
| $29 | Landing | ladder dismount/landing (bank0E:967) |
| $2A | Wily alarm | Alien reveal (bank0B:3687) |
| $2B | Damage hit | all weapon + boss hit handlers (bank0F, bank0B) |
| $2C | Dragon fire | Mecha Dragon (bank0B:1908, 2001) |
| $2D | Deflect | all weapon + boss deflect handlers (bank0F, bank0B) |
| $2E | Crash Bomb stick | bank0F:4265, bank0E:6713 |
| $2F | Menu cursor | menus (bank0D:147, 1694, 3414, 3558, 3613, 5058, 5961) |
| $30 | Teleport in | boss entrance (bank0F:1238), unpause (bank0D:1878), Wily teleporter (bank0E:633) |
| $31 | Leaf Shield orbit | `leaf_launch_check_state` (bank0F:4079) |
| $32 | (silent) channel mute | boss-corridor scroll (bank0F:970) |
| $33 | (unused) | — |
| $34 | (silent) channel mute | screen transitions (bank0E:2182, 2258) — cancelled by cmd $FE |
| $35-$37 | Skew 1-3 | no direct queue sites found (NSFe-audible) |
| $38 | Atomic Fire charge | bank0F:3932, Heat Man (bank0B:317, 383) |
| $39 | Enemy bounce | Fly Boy (bank0E:4793) |
| $3A | Teleport out | stage select confirm (bank0D:174), title (bank0D:3444), fortress defeat (bank0B:4004) |
| $3B | Water/lava splash | bank0E:1523 |
| $3C | Appear block | bank0E:6473 |
| $3D-$3E | Acid drip 1/2 | Flash stage hazard (`flash_hazard_ai`, bank0E) |
| $3F | Air Shooter | bank0F:3540, Air Man (bank0B:467) |
| $40 | (unused) | — |
| $41 | Death explosion | player death (bank0F:414), fortress (bank0B:3943) |
| $42 | Extra life | 1-UP/E-Tank pickup (bank0E:580, 587), password entry beep (bank0D:3648, 5210) |

The two silent SFX ($32/$34) claim channels at maximum-priority silence to
mute music channels during CPU-heavy scroll sequences; cmd $FE releases them.

### Stage-to-Music Mapping

Music is loaded by enqueuing `stage_music_table[current_stage]` (bank0E:250):

| Stage | Music ID | Track |
|---|---|---|
| $00 Heat Man | $03 | Heat Man Stage |
| $01 Air Man | $04 | Air Man Stage |
| $02 Wood Man | $01 | Wood Man Stage |
| $03 Bubble Man | $07 | Bubble Man Stage |
| $04 Quick Man | $06 | Quick Man Stage |
| $05 Flash Man | $00 | Flash Man Stage |
| $06 Metal Man | $05 | Metal Man Stage |
| $07 Crash Man | $02 | Crash Man Stage |
| $08 Wily 1 | $08 | Dr. Wily Stage 1-2 |
| $09 Wily 2 | $08 | Dr. Wily Stage 1-2 |
| $0A Wily 3 | $09 | Dr. Wily Stage 3-4 |
| $0B Wily 4 | $09 | Dr. Wily Stage 3-4 |
| $0C Wily 5 | $09 | Dr. Wily Stage 3-4 (overridden to $17) |

Wily 6 (stage $0D) has no `stage_music_table` entry — its rooms queue music directly (Wily theme $09 at bank0E:709, boss music $0B at the gates). ID $17 is the Weapon Get jingle, queued by `weapon_get_screen_init` (bank0D:5822).

### Boss Sprite Types

`boss_active_sprite_tbl` (bank0B:212) — per-boss SPRITE type written by
`boss_set_sprite` during the walk-in animation. IDs $50-$7B are entity
sprite types, not sound IDs (an old misreading corrected in Phase A4):

| Boss | Sprite | Boss | Sprite |
|---|---|---|---|
| Heat Man | $51 | Flash Man | $5C |
| Air Man | $67 | Metal Man | $64 |
| Wood Man | $6D | Crash Man | $6A |
| Bubble Man | $61 | Quick Man | $55 |

### Sound Control Variables

| Variable | Address | Description |
|---|---|---|
| `sound_pause_flag` | $41 | Bit 0 silences all channels |
| `sound_busy_flag` | $E4 | Locks sound engine while a sound is being loaded |
| `sound_frame_counter` | — | Frame timing for sound updates |
| `channel_active_flags` | — | 4-bit mask for active channels (1 per APU channel) |
| `sound_priority` | $E0 | Current priorities: lo nybble = music, hi = SFX |
| `sfx_channel_mask` | $E1 | Channels owned by SFX (bits 0-3) |
| `music_fade_ctrl` | $E8 | Music fade: bit 7 = active, bits 0-6 = frame period |
| `sound_data_ptr_lo` | $057C | Music instrument table pointer low |
| `sound_data_ptr_hi` | $057D | Music instrument table pointer high |
| `sound_queue` | $0580 | Command queue array (max 16 entries) |
| `sound_queue_count` | $66 | Queue entry count |

### Special Commands

| Value | Handler | Effect |
|---|---|---|
| $FC | `sound_cmd_speed` | Set playback speed (note ticks/frame = Y+1) |
| $FD | `sound_cmd_fade` | Start music fade-out (Y = fade params) |
| $FE | `sound_cmd_sfx_off` | Cancel SFX, return channels to music |
| $FF | `sound_cmd_music_off` | Stop music (SFX unaffected) |

---

## 11. Password System

Location: `password_screen_init` (bank0D:3497), `password_all_dots_placed` (bank0D:3664).

### Grid Layout

5×5 grid (25 cells, numbered 0–24). Player places 9 dots.

```
     Col0  Col1  Col2  Col3  Col4
Row0 [  0] [  1] [  2] [  3] [  4]
Row1 [  5] [  6] [  7] [  8] [  9]
Row2 [ 10] [ 11] [ 12] [ 13] [ 14]
Row3 [ 15] [ 16] [ 17] [ 18] [ 19]
Row4 [ 20] [ 21] [ 22] [ 23] [ 24]
```

### Encoding

**E-Tanks** (cells 0–3): The first dot found scanning cells 0→3 determines the E-Tank count. Dot in cell 0 = 0 E-Tanks, cell 1 = 1, cell 2 = 2, cell 3 = 3.

**Boss flags** (cells 5–24): Starting from cell `(E-Tanks + 5)`, 20 consecutive cells (wrapping from 24 back to 5) encode 16 meaningful bits via `password_bit_mask_table` and `password_byte_index_table`:
- 8 bits → `beaten_bosses` ($9A)
- 8 bits → complement byte

**Validation**: `beaten_bosses OR complement` must equal $FF. Invalid passwords show an error and return to the grid.

**Not encoded**: Difficulty flag ($CB) is NOT stored in passwords. Difficult mode is always lost on password continue.

---

## 12. Named Constants

### Stage Indices (`current_stage` / $2A)

```
STAGE_HEAT_MAN      = $00    STAGE_WILY_1        = $08
STAGE_AIR_MAN       = $01    STAGE_WILY_2        = $09
STAGE_WOOD_MAN      = $02    STAGE_WILY_3        = $0A
STAGE_BUBBLE_MAN    = $03    STAGE_WILY_4        = $0B
STAGE_QUICK_MAN     = $04    STAGE_WILY_5        = $0C
STAGE_FLASH_MAN     = $05    STAGE_WILY_6        = $0D
STAGE_METAL_MAN     = $06
STAGE_CRASH_MAN     = $07
WILY_STAGE_START    = $08    ; stages >= $08 are Wily fortress
```

### Weapon IDs (`current_weapon` / $A9)

```
WEAPON_BUSTER       = $00    WEAPON_QUICK_BOOM   = $05
WEAPON_ATOMIC_FIRE  = $01    WEAPON_TIME_STOPPER = $06
WEAPON_AIR_SHOOTER  = $02    WEAPON_METAL_BLADE  = $07
WEAPON_LEAF_SHIELD  = $03    WEAPON_CRASH_BOMBER = $08
WEAPON_BUBBLE_LEAD  = $04    WEAPON_ITEM_1/2/3   = $09/$0A/$0B
```

### Controller Buttons

```
BTN_A       = $80    BTN_START   = $10
BTN_B       = $40    BTN_UP      = $08
BTN_SELECT  = $20    BTN_DOWN    = $04
                     BTN_LEFT    = $02
                     BTN_RIGHT   = $01
```

### Entity Flags

```
ENT_FLAG_ACTIVE      = $80    ; bit 7: entity alive
ENT_FLAG_FLIP_H      = $40    ; bit 6: facing left
ENT_FLAG_NO_COLLIDE  = $20    ; bit 5: skip collision
ENT_FLAG_WEAPON_HIT  = $02    ; bit 1: hit by weapon
ENT_FLAG_CONTACT_DMG = $01    ; bit 0: deals contact damage
```

### Other Constants

```
MAX_HP               = $1C    ; 28 — max player/boss HP and weapon energy
BANK_GAME_ENGINE     = $0E    ; PRG bank switched to on cold boot
BANK_CHR_UPLOAD      = $0C    ; bank for CHR-RAM upload callback
PPUCTRL_NMI_ENABLE   = $80
PPUMASK_RENDERING    = $1E    ; all rendering on
```

### Entity Arrays (RAM)

```
ent_type        = $0400    ent_x_vel       = $0600
ent_spawn_type  = $0410    ent_x_vel_sub   = $0620
ent_flags       = $0420    ent_y_vel       = $0640
ent_spawn_flags = $0430    ent_y_vel_sub   = $0660
ent_x_screen    = $0440    ent_anim_frame  = $0680
ent_x_px        = $0460    ent_anim_id     = $06A0
ent_x_sub       = $0480    ent_misc        = $06B0
ent_y_px        = $04A0    ent_hp          = $06C0
ent_y_sub       = $04C0    ent_timer       = $06D0
ent_state       = $04E0    ent_screen_x    = $06E0
ent_drop_flag   = $04F0    ent_ai_behavior = $06F0
```

All arrays are indexed by entity slot ($00–$0F → addresses $0400–$040F, $0410–$041F, etc.).

---

## 13. Sprite & Animation Data

### OAM Buffer

The NES displays 64 hardware sprites (4 bytes each: Y, tile index, attributes, X). The OAM buffer at $0200–$02FF is DMA'd to PPU OAM via `$4014` write during NMI. Sprites are assembled from entity data each frame by the rendering pipeline in fixed bank $0F.

### Sprite Definition Pointer Tables

Four 128-byte pointer tables in fixed bank $0F map entity types ($00–$7F) to sprite definition data:

| Table | Location | Purpose |
|---|---|---|
| `sprite_def_ptr_lo` | bank0F:6506 | Sprite def pointer low byte (entity rendering) |
| `sprite_def_ptr_hi` | bank0F:6554 | Sprite def pointer high byte (entity rendering) |
| `sprite_def_ptr_lo_wpn` | bank0F:6531 | Sprite def pointer low byte (weapon rendering) |
| `sprite_def_ptr_hi_wpn` | bank0F:6570 | Sprite def pointer high byte (weapon rendering) |

All high bytes are in the $FB–$FF range, placing all sprite definition data in the fixed bank ($FB00–$FFEF region).

Entity rendering uses `sprite_def_ptr_lo/hi`. Weapon/projectile rendering uses `sprite_def_ptr_lo_wpn/hi_wpn`. The two sets allow the same entity type to have different sprites depending on rendering context (e.g., entity slot vs weapon slot).

### Animation Data Format

Each sprite definition block starts with a 2-byte header followed by per-sequence offsets:

| Offset | Field | Description |
|---|---|---|
| +0 | Max sequence index | Animation wraps to 0 after this value |
| +1 | Frame duration | Frames between animation steps |
| +2... | Frame IDs | One byte per sequence — index into bank $0A frame pointer tables |

A frame ID of `$00` signals **entity deactivation** (`LSR ent_flags` clears bit 7, marking the entity dead).

### Animation State Machine

`render_entity_normal` (bank0F:2128) runs each frame for active entities:

1. Load sprite def pointer from `sprite_def_ptr_lo/hi` using `ent_type`
2. Increment `ent_anim_frame` → compare against byte +1 (duration)
3. If exceeded: reset frame to 0, increment `ent_anim_id`
4. Compare `ent_anim_id` against byte +0 (max sequences) → wrap to 0
5. Read frame ID at index `[anim_id + 2]` → if $00, deactivate entity
6. Jump to `render_begin_oam_write` to assemble OAM entries

| Routine | Location | Purpose |
|---|---|---|
| `render_entity_normal` | bank0F:2128 | Main entity animation + OAM write |
| `render_entity_get_sprite_ptr` | bank0F:2086 | Special mode entity rendering (no animation advance) |
| `render_weapon_get_sprite_ptr` | bank0F:2109 | Weapon/projectile rendering via `_wpn` tables |
| `render_begin_oam_write` | bank0F:2164 | OAM assembly from bank $0A frame data |

### Flash Effects

- **Player i-frames**: When `invincibility_timer` > 0, sprite is hidden every other frame (`frame_counter AND #$02`). Timer decrements each render frame.
- **Boss hit flash**: When `boss_hit_timer` > 0, alternates between the normal frame and frame ID `$18` (white flash frame) every 2 frames. Timer decrements each render frame.

### Frame & OAM Layout Data (bank $0A)

`render_all_sprites` (bank0F:1939) switches to bank $0A each frame. Frame IDs index four 256-entry pointer tables there — `spr_frame_ptr_lo/hi` ($8000/$8200, entity slots $00-$0F) and `wpn_frame_ptr_lo/hi` ($8100/$8300, weapon slots $10-$1F). Frame data ($8700+): `[sprite_count, offset_idx, (tile, attr) × count]`. The `offset_idx` selects an OAM offset blob via `spr_offset_ptr_lo/hi` ($8400/$8500): `(y_off, x_off)` pixel-offset pairs read in lockstep with the tile/attr pairs. H-flipped entities map X offsets through `spr_flip_x_tbl` ($8600, `flip[x] = -(x+8)`). See `src/bank0A_sprites.asm`.

### Animation Variables

| Variable | Address | Description |
|---|---|---|
| `ent_anim_frame` | $0680,x | Current frame within animation step |
| `ent_anim_id` | $06A0,x | Current animation sequence index |
| `invincibility_timer` | $4B | Player i-frame countdown (flash duration) |
| `boss_hit_timer` | $05A8 | Boss hit stun / flash timer |

---

## 14. Text & Screen Data

### PPU Update Pipeline

All PPU writes occur during NMI (vertical blank) via a queued buffer system:

| Buffer | Address | Size | Purpose |
|---|---|---|---|
| OAM buffer | $0200–$02FF | 256 bytes | 64 sprites (4 bytes each), DMA'd via $4014 |
| PPU update buffer | $0300–$0353 | 84 bytes | Nametable tile update entries (code accesses up to `ppu_update_buf+$50`) |
| Palette animation | $0354–$0355 | 2 bytes | `palette_anim_target` + `palette_anim_counter` |
| Palette RAM | $0356–$0375 | 32 bytes | BG + sprite palettes (→ PPU $3F00) |
| Column update addr | $03B6–$03B7 | 2 bytes | VRAM target address (hi/lo) |
| Column update tiles | $03B8–$03D7 | 32 bytes | Tile column data (32 tiles vertical) |

`ppu_buffer_count` tracks the number of pending update entries. `ppu_buffer_transfer` (bank0F:2583) processes the queue during NMI in two modes:
- **Positive count**: Multi-entry structured writes (4×4 tile blocks per entry)
- **Negative count**: Alternate mode — 8-byte row writes with attribute table merge

### Column Update System

`ppu_scroll_column_update` (bank0F:2682) writes one 32-tile vertical column to the nametable during scrolling. The VRAM address is stored in `col_update_addr_lo/hi` ($03B6–$03B7), tile data in `col_update_tiles` ($03B8–$03D7). Also used for text rendering during stage intros.

### Text Encoding

Text is encoded as **CHR tile indices**, not ASCII. The font tiles in the CHR pattern table are arranged so that:

| Byte range | Characters | Encoding |
|---|---|---|
| $C1–$DA | A–Z (uppercase) | $C0 + letter position (A=1, B=2, ..., Z=26) |
| $00 | Space | Null byte = blank tile |
| $DC | Period (.) | Special punctuation tile |
| $DD | Comma/apostrophe | Special punctuation tile |

Example: `"MEGAMAN"` = `$CD,$C5,$C7,$C1,$CD,$C1,$CE`

### Credits Text

`prologue_text_data` (bank0D:4785) — prologue/story text in high-bit ASCII ($C1+ = A+); `$00` bytes are separators. The ending staff-roll credits live in bank $09 as `credits_text` (bank09 $8C95, letter tiles $01-$1A = A-Z), typed out by `ending_column_tick`.

Decoded excerpt:

```
$CE,$C1,$CD,$C5,$C4                = "NAMED"
$CD,$C5,$C7,$C1,$CD,$C1,$CE       = "MEGAMAN"
$D7,$C1,$D3                       = "WAS"
$C3,$D2,$C5,$C1,$D4,$C5,$C4       = "CREATED"
$C4,$D2,$DC                       = "DR."
$CC,$C9,$C7,$C8,$D4               = "LIGHT"
```

Title/prologue fades use the brightness ramp `title_fade_brightness` (bank0D:4819).

### Stage Intro Text

Weapon-name rendering on the GET EQUIPPED screen (`weapon_get_draw_name`, bank0D:5877) writes the name letter-by-letter via `col_update_tiles` with frame delays — a typewriter effect.

The `weapon_name_data` table (bank0D, indexed by `current_stage`) provides per-stage name tile data. After all letters are drawn, `weapon_get_name_blink` (bank0D:5905) alternates the text between white and weapon colors using the `weapon_get_pal_lo/hi` tables.

### Password Screen

`password_screen_init` (bank0D:3497) renders the password grid via direct PPU writes from `password_ppu_layout_data` tables. Grid tiles are written outside of NMI (during forced blank). The blinking cursor position is maintained in the OAM buffer at `oam_buffer` ($0200).

### Boss Get Screen

`wily_map_screen_init` (bank0D:2187) renders the weapon acquisition screen. The nametable is filled with `wily_nametable_fill_tiles` tile patterns, then boss/weapon name text is written via PPU buffer updates. Palette data loaded from `wily_map_palette_data` (bank0D:2835).
