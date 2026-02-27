# Mega Man 2 — Engine Architecture

A detailed walkthrough of how the Mega Man 2 NES engine works, from power-on to per-frame gameplay. Intended for anyone studying 6502/NES game design or hacking the disassembly.

> All routine names, variable names, and addresses reference the annotated ca65 source in `src/`. Zero-page and RAM equates are defined in `include/zeropage.inc` and `include/ram.inc`.

---

## Table of Contents

1. [Hardware Overview](#1-hardware-overview)
2. [Memory Map](#2-memory-map)
3. [Boot Sequence](#3-boot-sequence)
4. [Main Game Loop](#4-main-game-loop)
5. [NMI and the PPU Update Pipeline](#5-nmi-and-the-ppu-update-pipeline)
6. [Scrolling and Camera](#6-scrolling-and-camera)
7. [Entity System](#7-entity-system)
8. [Entity AI Dispatch](#8-entity-ai-dispatch)
9. [Entity Physics](#9-entity-physics)
10. [Collision Detection](#10-collision-detection)
11. [Tile Collision](#11-tile-collision)
12. [Sprite Rendering and OAM](#12-sprite-rendering-and-oam)
13. [Player Physics](#13-player-physics)
14. [Weapon System](#14-weapon-system)
15. [Boss AI](#15-boss-ai)
16. [Stage Data and Dual Bank Mapping](#16-stage-data-and-dual-bank-mapping)
17. [Entity Spawn Tables](#17-entity-spawn-tables)
18. [Sound Engine](#18-sound-engine)
19. [Password System](#19-password-system)
20. [Difficulty System](#20-difficulty-system)
21. [6502 Tricks](#21-6502-tricks)

---

## 1. Hardware Overview

| Property | Value |
|----------|-------|
| CPU | Ricoh 2A03 (MOS 6502 core, no BCD) |
| Mapper | MMC1 (iNES mapper 1), mode 3 |
| PRG ROM | 256 KB — 16 × 16 KB banks ($00-$0F) |
| CHR | 8 KB CHR-RAM (uploaded at runtime, not ROM) |
| Mirroring | Vertical (two horizontal nametables) |
| Fixed bank | $0F at $C000-$FFFF (always mapped) |
| Switchable | $00-$0E at $8000-$BFFF (one at a time) |
| Vectors | NMI = $CFF0, Reset = $FFE0, IRQ = $FFE0 |

MMC1 bank switching requires 5 serial writes (bit 0 of each byte) to any address in $8000-$FFFF. The 5th write latches the value and selects the bank. The fixed bank (`bank0F_fixed.asm`) handles all switching through a single `bank_switch` routine at $C000.

---

## 2. Memory Map

### CPU Address Space

| Address | Size | Contents |
|---------|------|----------|
| $0000-$00FF | 256 B | Zero page — temporaries, scroll state, controller input, game flags |
| $0100-$017F | 128 B | Entity arrays (page $01) — collision guards, parent refs, platform data |
| $0180-$01FF | 128 B | Hardware stack (very shallow — typically 6-8 bytes deep) |
| $0200-$02FF | 256 B | OAM shadow buffer (64 sprites × 4 bytes, DMA'd to PPU each NMI) |
| $0300-$0355 | 86 B | PPU write buffer (queued nametable/attribute updates) |
| $0356-$0375 | 32 B | Palette mirror (uploaded to PPU $3F00 every NMI) |
| $0376-$03FF | 138 B | Column/attribute update buffers, palette animation frames |
| $0400-$06FF | 768 B | Entity arrays (main) — type, position, velocity, AI state, HP |
| $0700-$07FF | 256 B | Palette save buffer (preserved during weapon select screen) |
| $8000-$BFFF | 16 KB | Switchable PRG bank window |
| $C000-$FFFF | 16 KB | Fixed PRG bank $0F (always mapped) |

### Zero Page Layout (highlights)

| Address | Name | Purpose |
|---------|------|---------|
| $00-$07 | `temp_00`-`temp_07` | Scratch registers (not preserved across calls) |
| $08-$09 | `jump_ptr` | Indirect jump vector — `JMP (jump_ptr)` |
| $0A-$11 | `temp_0A`-`temp_11` | Extended temps, division working registers |
| $14-$22 | Scroll state | Screen boundaries, metatile pointers, scroll X/Y |
| $23-$28 | Controller input | Current buttons, previous frame, new presses |
| $29 | `current_bank` | Currently loaded PRG bank number |
| $2A | `current_stage` | Stage index (0-13) |
| $2B | `current_entity_slot` | Entity slot being processed this iteration |
| $47 | `col_update_count` | Pending tile column updates for NMI |
| $51 | `attr_update_count` | Pending attribute updates for NMI |
| $AA | `game_mode` | Entity dispatch mode: 0=normal, bit 2=pause |
| $B1 | `boss_phase` | Boss AI state machine phase |
| $B3 | `boss_id` | Boss index (0-13) |
| $F7-$F8 | `ppuctrl_shadow`/`ppumask_shadow` | PPU register mirrors |

---

## 3. Boot Sequence

**File:** `bank0E_game_engine.asm` (cold boot entry)
**File:** `bank0F_fixed.asm` (reset vector at $FFE0)

Power-on sequence:

1. **Reset vector** ($FFE0) → `cold_boot_init` in bank $0F
2. **Disable interrupts** (`SEI`), initialize stack pointer
3. **Wait for PPU warmup** — two VBLANK polls reading `PPUSTATUS`
4. **Clear RAM** — zero pages $00-$07 ($0000-$07FF), clearing all entity state, scroll vars, and the OAM buffer
5. **Initialize MMC1** — write reset bit ($80) then configure mode 3 (fixed high bank)
6. **Switch to bank $0E** — the game engine bank
7. **Hardware init** — set PPU control registers, enable NMI
8. **Enter `main_game_loop`** — the permanent outer loop

The CPU never returns from `main_game_loop`. All game states (title, stage select, gameplay, ending) are sub-states within this loop.

---

## 4. Main Game Loop

**File:** `bank0E_game_engine.asm`

```
main_game_loop (runs forever):
  ├── Read game_state ($04)
  ├── If game_state = 0 → stage_frame_loop (in-stage gameplay)
  └── If game_state ≠ 0 → banked_dispatch (title, stage select, password, ending, etc.)
```

### Stage Frame Loop (game_state = 0)

This is the core gameplay loop. Every visible frame executes these steps in order:

```
stage_frame_loop:
  1. read_controllers         — Latch + shift 8 bits from $4016/$4017
  2. player_update            — Movement, jumping, ladder, weapon fire
  3. entity_update_loop       — For each slot $10-$1F:
     ├── apply_entity_physics — Move entity by velocity
     ├── entity_ai_dispatch   — Run type-specific AI handler
     └── collision checks     — Player contact + weapon hit
  4. entity_spawn_scan        — Activate entities entering screen
  5. sound_engine_update      — Process music + SFX channels
  6. render_all_sprites       — Build OAM buffer from entity positions
  7. wait_for_vblank          — Spin on vblank_done flag until NMI fires
```

`wait_for_vblank` at step 7 blocks until the NMI handler sets `vblank_done`. This synchronizes gameplay to 60 Hz (NTSC). All PPU writes happen inside NMI; the main loop only prepares data.

---

## 5. NMI and the PPU Update Pipeline

**File:** `bank0F_fixed.asm` (NMI handler)

The NMI fires once per frame during vertical blanking. The PPU can only be safely written during this ~2273-cycle window. The handler executes a strict pipeline:

```
NMI handler:
  1. OAM DMA          — Write $02 to OAMDMA ($4014), copies $0200-$02FF to PPU
  2. PPU buffer drain  — Flush queued VRAM writes (nametable patches, text)
  3. Palette upload    — Copy 32-byte palette mirror ($0356) → PPU $3F00
  4. Column update     — If col_update_count > 0: write vertical tile column to nametable
  5. Attribute update  — If attr_update_count > 0: write attribute table entries
  6. Scroll setup      — Compute final PPUSCROLL from scroll_x/y minus camera shake offsets
  7. RNG tick          — seed = (ent_x_sub[0] XOR seed + frame_counter) >> 1
  8. Bank callback     — Process queued cross-bank calls (CHR upload, sound)
```

**Step 1 (OAM DMA)** takes 513 CPU cycles. The OAM buffer at $0200 is pre-built by `render_all_sprites` during the main loop. A single write to $4014 triggers the hardware DMA.

**Step 3 (palette)** always runs — the 32-byte palette at $0356-$0375 covers all 4 BG palettes and 4 sprite palettes. Any palette change (weapon get, boss flash, stage transition) simply modifies this buffer and NMI uploads it.

**Step 4 (column update)** is the hot path for horizontal scrolling. When the camera moves far enough to reveal a new 16-pixel column, the main loop sets `col_update_count` and pre-computes 30 tile IDs in a buffer. NMI writes them as a vertical stripe to the correct nametable column (PPUADDR increments by 32 per write in vertical mode).

**Step 5 (attribute update)** supports three modes:
- **Overwrite** — write attribute byte directly
- **Fill** — bulk-fill a 2×2 metatile region
- **Read-modify-write** — merge new palette bits with existing attribute byte (EOR/AND mask formula) to avoid clobbering adjacent tiles' palette assignments

**Step 6 (scroll)** calculates the final scroll position:
```
final_x = scroll_x - camera_x_offset
final_y = scroll_y - camera_y_offset
nametable_bit = nametable_select XOR (borrow from X subtraction)
```
Camera offsets are normally zero. During boss fights, they're set to small oscillating values to create screen shake. The nametable XOR ensures the correct nametable is displayed as scroll_x wraps past 255.

---

## 6. Scrolling and Camera

**Files:** `bank0E_game_engine.asm` (main scroll logic), `bank0F_fixed.asm` (NMI writes), `bank0D_stage_engine.asm` (init + column render)

### Horizontal Scrolling

The camera tracks the player within a dead zone. When the player's screen-relative X position exceeds the dead zone boundary, the camera advances by the player's movement delta.

Each frame, the engine checks whether `scroll_x` has crossed a 16-pixel metatile boundary (4 pixels in scroll units → one column). When it does:
1. `metatile_render_column` decodes the next column of metatile data into individual tiles
2. The tile IDs are stored in a column buffer
3. `col_update_count` is set to signal NMI
4. NMI writes the vertical tile stripe to the off-screen nametable column
5. Attribute bytes for the new column are also queued

`column_index` ($1A) tracks the current column position, wrapping mod 64 across both nametables (32 columns each).

### Room Transitions

When `scroll_x` reaches a room boundary (`scroll_screen_lo`/`scroll_screen_hi`):
1. All entities are despawned
2. The destination room's nametable is fully rendered off-screen
3. A 63-frame smooth scroll animation plays (`scroll_x += 4` per frame)
4. Metatile pointers advance by $40 (one screen of column data)
5. `entity_spawn_scan` activates enemies for the new screen

Boss door transitions use a special shutter animation and scroll lock before entering the boss room.

### Vertical Transitions

Vertical scrolling uses direction-indexed tables (up = index 0, down = index 1) with per-frame scroll_y deltas, player Y steps, and a ~60-frame animation counter.

### Screen Shake

Camera shake is implemented by setting `camera_x_offset` ($B8) and `camera_y_offset` ($B6) to small oscillating values. The NMI handler subtracts these from `scroll_x`/`scroll_y` before writing PPUSCROLL. When the shake ends, offsets return to zero. No scroll state is modified — the shake is purely visual.

---

## 7. Entity System

**Files:** `include/ram.inc` (array definitions), `bank0F_fixed.asm` (spawn/init), `bank0E_game_engine.asm` (update loop)

### Slots

The game supports 32 entity slots indexed $00-$1F:

| Slots | Purpose |
|-------|---------|
| $00 | Player (Mega Man) |
| $01 | Boss (during boss fights) |
| $02-$09 | Player weapons / projectiles |
| $0A-$0F | Reserved (additional projectiles) |
| $10-$1F | Enemies, items, stage objects |

### Parallel Arrays

Entity state is stored in parallel arrays indexed by the X register. Each array has 32 entries at $10 stride (16 bytes apart). Key arrays:

| Array | Address | Purpose |
|-------|---------|---------|
| `ent_type` | $0400,x | Entity type ID ($00-$7F) — indexes AI table |
| `ent_flags` | $0420,x | Status bits: active ($80), facing ($40), no-collide ($20) |
| `ent_x_screen` | $0440,x | X position, screen/page byte |
| `ent_x_px` | $0460,x | X position, pixel byte |
| `ent_x_sub` | $0480,x | X position, sub-pixel (1/256th pixel) |
| `ent_y_px` | $04A0,x | Y position, pixel byte |
| `ent_y_sub` | $04C0,x | Y position, sub-pixel |
| `ent_state` | $04E0,x | AI state / phase counter |
| `ent_x_vel` | $0600,x | X velocity, signed whole pixel |
| `ent_x_vel_sub` | $0620,x | X velocity, sub-pixel |
| `ent_y_vel` | $0640,x | Y velocity, signed whole pixel |
| `ent_y_vel_sub` | $0660,x | Y velocity, sub-pixel |
| `ent_hp` | $06C0,x | Hit points (player at $06C0, boss at $06C1) |
| `ent_anim_frame` | $0680,x | Current animation frame |
| `ent_anim_id` | $06A0,x | Animation sequence index |
| `ent_timer` | $06D0,x | General-purpose countdown timer |

Page $01 arrays ($0100-$017F) share the 6502 stack page. This is safe because the game uses very shallow stack depth (6-8 bytes). These hold collision guards, parent references, and platform data.

### Position Format

Position is split into three components:
- **Screen** ($0440) — which 256-pixel screen/page the entity is on
- **Pixel** ($0460) — pixel offset within the screen (0-255)
- **Sub-pixel** ($0480) — fractional pixel (0-255, representing 0/256 to 255/256)

Full X position = screen × 256 + pixel + sub-pixel/256. This gives smooth sub-pixel movement using only integer arithmetic.

### Entity Lifecycle

1. **Spawn** — `entity_spawn_scan` (static) or `spawn_entity_from_parent` (dynamic)
2. **Init** — `entity_init_from_type` loads flags and behavior from lookup tables
3. **Active** — AI handler runs each frame, physics applied, collision checked
4. **Death** — HP reaches 0, entity converted to `ENTITY_DEATH_EXPLODE` ($06), item drop RNG runs
5. **Despawn** — Entity scrolls off-screen or `ent_despawn` set to $FF

---

## 8. Entity AI Dispatch

**File:** `bank0E_game_engine.asm` (dispatch routine + pointer table at $92F0)

### The Pointer Table

AI behavior is defined by a 128-entry pointer table at $92F0 in bank $0E. Each entry has three bytes:

| Offset | Table | Purpose |
|--------|-------|---------|
| +$00 | `entity_ai_ptr_lo` | AI routine address, low byte |
| +$80 | `entity_ai_ptr_hi` | AI routine address, high byte |
| +$100 | `entity_ai_bank_table` | Bank selector (0 = normal) |

### Dispatch Modes

The `game_mode` variable ($AA) controls how dispatch works:

| game_mode | Behavior |
|-----------|----------|
| 0 or 4 | **Normal** — Index into ptr_lo/ptr_hi, call in bank $0E. Bank field ignored. |
| Other | **Special** — If entity's bank field ≠ 0, use alternate pointer in bank $0F |

In normal gameplay (game_mode = 0), all 128 entity AI handlers live in bank $0E and the bank field is completely ignored. Special mode is used for cross-bank handlers during unusual game states.

### Dispatch Algorithm

```
entity_ai_dispatch:
  For each entity slot X = $10 to $1F:
    if ent_flags[X] bit 7 clear → skip (inactive)
    Y = ent_type[X]
    jump_ptr = ptr_lo[Y] : ptr_hi[Y]
    Push return stub address onto stack
    JMP (jump_ptr)
    ; AI handler executes, then RTS → return stub
    ; Stub advances to next slot
```

The return stub trick is a soft-interrupt pattern: pushing a return address then JMPing means the AI handler's RTS returns control to the dispatch stub, which advances X to the next slot and loops. This avoids the overhead of JSR/RTS pairs for each of 16 slots.

### NULL AI

17 entity types point to a NULL stub (`kerog_physics_rts` — a bare RTS instruction). These are entities that have no per-frame behavior (explosions, static objects, etc.).

---

## 9. Entity Physics

**File:** `bank0F_fixed.asm`

Two physics routines exist:

### apply_entity_physics (basic movement)

Moves the entity by its velocity without collision checks. Used by projectiles and simple moving objects.

```
Y movement:
  position.y = position.y - velocity.y    (subtract! positive Y_vel = upward)
  velocity.y = velocity.y - gravity        (gravity pulls velocity downward)

X movement:
  if facing_left:  position.x = position.x - velocity.x
  if facing_right: position.x = position.x + velocity.x

Bounds check:
  if off-screen by > 32px → despawn
```

Key detail: Y velocity is **subtracted** from Y position. This is because NES screen coordinates increase downward, so a positive Y velocity means upward movement. Gravity decreases Y velocity each frame, eventually making it negative (downward).

Sub-pixel accumulators provide smooth fractional movement. The carry/borrow from sub-pixel arithmetic propagates into the pixel byte.

### apply_entity_physics_alt (with collision)

Same movement as above, plus:
1. **Player contact collision** — bounding box test against player
2. **Weapon collision** — scan weapon slots for hits
3. **Offscreen despawn** — remove if scrolled out of view

Most enemy AI handlers call this variant. It's the standard "physics + collision" package.

---

## 10. Collision Detection

**File:** `bank0F_fixed.asm`

### Player-Entity Contact (check_player_collision)

Called when an entity's physics step overlaps the player's bounding box:

1. Compute distance: `|player_x - entity_x|` and `|player_y - entity_y|`
2. Compare against per-type hitbox dimensions from lookup tables
3. If overlap:
   - **Item pickup** (types $76+) — increment health/weapon/lives, despawn item
   - **Contact damage** — subtract damage from player HP, start invincibility timer ($4B)
   - **Knockback** — flip player's facing direction (`EOR #$40` on facing bit), apply recoil velocity
4. If player HP ≤ 0 → trigger death sequence

The facing direction flip uses a classic 6502 bit trick:
```asm
lda player_flags
and #$40          ; isolate facing bit
eor #$40          ; flip it — face AWAY from enemy
ora (other bits)  ; merge back
```

### Weapon-Entity Collision (check_weapon_collision)

Scans player weapon slots for overlap with the current enemy:

1. **Frame alternation** — split work across two frames to save cycles:
   - Even frames: scan slots 9, 7, 5, 3
   - Odd frames: scan slots 8, 6, 4, 2
2. For each active weapon slot, bounding box test against current enemy
3. On hit:
   - Call weapon-specific collision handler (pointer table dispatch)
   - Apply `weapon_difficulty_scale` (2× damage on Normal difficulty)
   - If enemy HP ≤ 0 → run `item_drop_rng`, convert to death explosion

Frame alternation means at most 4 weapon slots are tested per entity per frame. Since weapons are large and fast, the one-frame delay is imperceptible.

---

## 11. Tile Collision

**File:** `bank0F_fixed.asm` (`lookup_tile_from_map`)

Tile collision converts a pixel position to a collision type by walking the stage data hierarchy:

```
Pixel position
  → Screen index (which 256px room)
  → Metatile map (8×8 grid of 16×16 metatiles per screen)
  → Metatile ID
  → Quadrant (which 8×8 tile within the 16×16 metatile)
  → Collision type (2-bit value from tile's attribute byte)
```

### Algorithm Detail

1. **Row/column extraction** — bit shifts extract the 3-bit row and 3-bit column from the pixel Y and X positions
2. **Map index** — `column × 8 + row` (column-major layout, 64 entries per screen)
3. **Metatile pointer** — base address from screen number × 64
4. **Metatile ID** → data address at `$2000 + ID × 4` (each metatile = 4 bytes for 2×2 tiles)
5. **Quadrant select** — bit 4 of X and Y selects which of the 4 tiles in the metatile
6. **Collision bits** — top 2 bits of the tile byte encode collision type:
   - 0 = empty (passable)
   - 1 = solid
   - 2-3 = stage-specific (look up in `stage_collision_table`, 16 bytes per stage)

Types 2-3 are overloaded per-stage — they can mean ladder, spike, water, conveyor, or other stage-specific surfaces.

---

## 12. Sprite Rendering and OAM

**File:** `bank0F_fixed.asm` (`render_all_sprites`), `bank0D_stage_engine.asm` (player rendering)

### OAM Format

Each sprite occupies 4 bytes in the OAM buffer ($0200):

| Offset | Purpose |
|--------|---------|
| +0 | Y position (0-239, $F8 = off-screen / hidden) |
| +1 | Tile index (pattern table ID) |
| +2 | Attributes: palette (bits 0-1), priority (bit 5), flip H (bit 6), flip V (bit 7) |
| +3 | X position (0-255) |

64 sprites maximum. `clear_oam_buffer` sets all Y positions to $F8 (off-screen) before rendering begins each frame.

### Render Pipeline

1. Clear OAM buffer (all sprites hidden)
2. For each active entity slot:
   - Look up sprite definition for `ent_type[x]` and `ent_anim_frame[x]`
   - Sprite definition data lives in bank $0A (sound/sprite data bank)
   - Write 1-N sprite entries to OAM buffer
   - Apply facing direction flip (horizontal mirror via attribute bit 6)
   - Offset sprites relative to camera scroll position

### Player Sprite Rendering

The player uses a special 3-layer rendering system (`render_player_sprites` in bank $0D):
- **Base layer** — body pose (standing, running, jumping, climbing)
- **Weapon overlay** — current weapon's visual effect
- **Flash layer** — invincibility blink (toggle visibility every other frame during i-frames)

---

## 13. Player Physics

**File:** `bank0D_stage_engine.asm`

### Horizontal Movement

- Walk speed determined by D-pad left/right input
- Slide: higher speed, decaying over time
- Direction change: velocity reversed, entity facing bit flipped

### Vertical Movement

```
Each frame:
  y_velocity -= $40          ; gravity pulls downward
  if y_velocity < $F4:       ; terminal velocity cap
    y_velocity = $F4
  position.y -= y_velocity   ; apply (subtract because NES Y-axis is inverted)
```

- **Jump**: initial Y velocity = ~$04.80 (upward). Gravity decreases it ~$40/256 per frame.
- **Floor snap**: when tile collision detects ground, `Y &= $F0` (align to 16px grid) and velocity = 0.
- **Ceiling snap**: on upward collision, velocity set to 0 (fall immediately).
- **Gravity sub-pixel**: `gravity_sub_lo`/`gravity_sub_hi` ($30/$31) accumulate fractional gravity. The carry propagates into the velocity byte for smooth deceleration.

### Weapon Select (Pause Menu)

When Start is pressed during gameplay:

1. Set `game_mode |= $04` — pause all entity AI
2. Draw weapon select overlay
3. **D-pad input** with auto-repeat:
   - First press: immediate response
   - Hold: 24-frame delay before repeat starts
   - Repeat: every 8 frames
4. Cursor cycles through acquired weapons (skips locked slots)
5. Start or B: unpause, restore weapon palette, resume gameplay

---

## 14. Weapon System

**Files:** `bank0C_weapons_ui.asm` (weapon data, CHR upload), `bank0F_fixed.asm` (firing dispatch)

### Weapon IDs

| ID | Weapon | Source |
|----|--------|--------|
| $00 | Mega Buster | Default |
| $01 | Atomic Fire | Heat Man |
| $02 | Air Shooter | Air Man |
| $03 | Leaf Shield | Wood Man |
| $04 | Bubble Lead | Bubble Man |
| $05 | Quick Boomerang | Quick Man |
| $06 | Time Stopper | Flash Man |
| $07 | Metal Blade | Metal Man |
| $08 | Crash Bomber | Crash Man |
| $09-$0B | Items 1-3 | Special items |

### Firing Pipeline

```
Player presses B:
  1. fire_weapon_dispatch — branch by current_weapon ($A9)
  2. Check ammo (weapon_ammo array at $9C)
  3. Deduct ammo cost
  4. fire_find_slot_loop — scan slots $02-$0E for empty slot
  5. weapon_spawn_projectile:
     - Set ent_type to weapon's projectile entity type
     - Position: player position + directional offset
     - Velocity: from per-weapon speed tables, sign based on facing
     - Screen byte carry propagation for offsets crossing page boundary
```

Each weapon has its own handler with specific behavior — the Mega Buster scans for a free slot and limits to 3 on-screen shots, Metal Blade allows 8-directional aiming, Leaf Shield orbits the player until released, etc.

---

## 15. Boss AI

**File:** `bank0B_boss_ai.asm`

### Boss Slot

Bosses always occupy entity slot $01. Direct (non-indexed) aliases provide convenient access:
- `boss_type` = $0401, `boss_x_px` = $0461, `boss_hp` = $06C1, etc.
- Additional state: `boss_phase` ($B1), `boss_action_timer` ($B2), `boss_id` ($B3)
- Work variables: `boss_work_var1` ($05A7), aliased per-boss in bank $0B

### AI Dispatch

Bank $0B has its own 14-entry dispatch table (8 Robot Masters + 6 Wily bosses):

```
enemy_ai_dispatch:
  Y = boss_id
  jump_ptr = enemy_ai_routine_lo[Y] : enemy_ai_routine_hi[Y]
  JMP (jump_ptr)
```

### Phase State Machine

Every boss uses `boss_phase` ($B1) as its primary state machine:

| Phase | Typical meaning |
|-------|----------------|
| 0 | Entrance / idle animation |
| 1+ | Active attack patterns |
| N | Death sequence |

Phase transitions are triggered by timers, HP thresholds, or position checks. Each phase typically:
1. Decrements `boss_action_timer`
2. When timer expires, execute attack pattern
3. Increment `boss_phase` to advance state

### Attack Patterns

Boss attacks fall into several patterns:

- **Timer-driven** — decrement a countdown, fire on zero. Heat Man fires a 3-shot burst: a loop spawns 3 `ENTITY_HEATMAN_FIRE` projectiles with calculated Y velocities using `divide_16bit` for aiming.

- **Position-driven** — `calc_player_boss_distance` computes the signed distance between boss and player. The result drives aim calculations or triggers attacks when the player is in range.

- **Velocity table** — some bosses (notably Alien) index into pre-computed velocity tables by phase. The Alien's 8-step orbit uses sine/cosine-like X/Y velocity pairs.

- **Child spawning** — `spawn_entity_from_parent` creates projectile children at the boss's position with specified type and velocity.

### Boss Utilities

| Routine | Purpose |
|---------|---------|
| `calc_player_boss_distance` | Returns \|boss_x - player_x\| with sign. Uses self-modifying code (`.byte $AD,$61,$04` = runtime `LDA boss_x_px`) |
| `divide_16bit` | Binary long division. Input: temp_0A:0B ÷ temp_0C:0D → temp_0E:0F (quotient) |
| `weapon_difficulty_scale` | Doubles weapon damage on Normal difficulty (ASL temp_00) |
| `tile_lookup` | Floor collision for grounded bosses |

---

## 16. Stage Data and Dual Bank Mapping

**Files:** `bank00`-`bank09` (stage data banks), `bank0E_game_engine.asm` (bank table)

### Dual Mapping

Banks $00-$07 each serve **two different stages** through different access methods:

- **Tile data** (CHR patterns, metatiles, screen layouts) — bank selected via `stage_bank_table` in bank $0E. The mapping is scrambled (Heat Man's tiles are in bank $03, not bank $00).

- **Entity spawns + palettes** (at offsets $3600-$3A00 and $3E00) — bank selected by `current_stage AND #$07`. This direct masking means stage 0 and stage 8 share a bank for spawns.

| Stage | Robot Master | Tile bank | Entity bank |
|-------|-------------|-----------|-------------|
| $00 | Heat Man | $03 | $00 |
| $01 | Air Man | $04 | $01 |
| $02 | Wood Man | $01 | $02 |
| $03 | Bubble Man | $07 | $03 |
| $04 | Quick Man | $06 | $04 |
| $05 | Flash Man | $00 | $05 |
| $06 | Metal Man | $05 | $06 |
| $07 | Crash Man | $02 | $07 |
| $08 | Wily 1 | $08 | $00 (shared) |
| $09 | Wily 2 | $08 | $01 (shared) |
| $0A | Wily 3 | $09 | $02 (shared) |
| $0B | Wily 4 | $09 | $03 (shared) |
| $0C | Wily 5 | $09 | $04 (shared) |

Wily stages share entity banks with Robot Master stages. Both sets of spawn entries coexist in the same table, sorted by screen number.

### Stage Data Layout (per bank)

| Offset | Size | Contents |
|--------|------|----------|
| $0000-$1FFF | 8 KB | CHR tile patterns (uploaded to CHR-RAM) |
| $2000-$2FFF | 4 KB | Metatile definitions (4 bytes each: 2×2 tile IDs) |
| $3000-$35FF | 1.5 KB | Screen layouts (64 metatile indices per screen) |
| $3600-$36FF | 256 B | Entity spawn table: screen numbers |
| $3700-$37FF | 256 B | Entity spawn table: X positions |
| $3800-$38FF | 256 B | Entity spawn table: Y positions |
| $3900-$39FF | 256 B | Entity spawn table: entity type IDs |
| $3A00-$3DFF | 1 KB | Secondary spawn tables |
| $3E00-$3FFF | 512 B | Background palette data |

---

## 17. Entity Spawn Tables

**File:** `bank0F_fixed.asm` (`entity_spawn_scan`), stage data banks

### Static Spawns

Each stage bank contains 4 parallel arrays defining entity placements:

```
$B600,y = screen_number   — which room/screen the entity appears in
$B700,y = x_position      — pixel X within that screen
$B800,y = y_position      — pixel Y
$B900,y = entity_type     — ENTITY_* type ID
```

`entity_spawn_scan` runs each frame. It maintains forward and backward scan indices and activates entities whose screen number matches the current visible range. When an entity scrolls off-screen, it's despawned. Re-entering the screen re-spawns it (enemies respawn).

### Dynamic Spawns

`spawn_entity_from_parent` ($F159 in bank $0F) creates child entities at runtime:

1. Find an empty slot (scan $10-$1F for inactive)
2. Copy parent's position to child
3. Set child's type, velocity, and flags
4. Call `entity_init_from_type` to load behavior tables

Used by bosses (projectiles), enemy systems (Kukku spawner → Kukku body, Pipi → egg → Copipi), and multi-part enemies.

### Spawn Chains

Some enemies use multi-entity spawn chains:
- **Kukku**: $1E (invisible spawner, tracks player X) → $1F (visible body) + $20 (despawner)
- **Pipi**: $37 (spawn point) → $38 (bird) → $3A (egg) → $3C (Copipi baby birds)
- **Mole**: $47 (controller, spawns copies of itself + $48/$49 shots)

---

## 18. Sound Engine

**File:** `bank0C_weapons_ui.asm` (also `bank0A_sound.asm` for music data)

The sound engine processes 4 channels (2 pulse, 1 triangle, 1 noise) each frame:

1. For each active channel, read the sound stream pointer
2. Decode commands: note on, note off, instrument change, tempo, loop, detune
3. Write frequency and volume to APU registers ($4000-$400F)
4. Advance stream pointer

Music data lives in bank $0A. The engine switches to $0A during the sound update callback (queued through the NMI bank callback system), processes all channels, then restores the previous bank.

SFX can override music channels temporarily. Priority is handled by the `channel_active_flags` ($EF) bitmask.

---

## 19. Password System

**File:** `bank0D_stage_engine.asm`

Passwords encode game progress in a 5×5 grid with exactly 9 dots:

- **Cells 0-3** (row 0): E-tank count. The column containing a dot indicates how many E-tanks (0-3). This also sets the data region offset.
- **Cells 5-24** (rows 1-4): 20 cells encode 16 meaningful bits via scrambled lookup tables. 8 bits store the beaten boss bitfield (`beaten_bosses` at $9A), 8 bits store its bitwise complement. 4 cells are dummy (mask = $00).

**Validation**: `beaten_bosses OR complement` must equal $FF. Any valid progress value and its inverse cover all 8 bits, catching invalid dot placements.

The password does **not** encode difficulty. Difficulty (`$CB`) persists only in RAM and resets to Normal on power cycle.

---

## 20. Difficulty System

RAM address `difficulty` ($CB): 0 = Normal, 1 = Difficult. Set on the ending screen after completing the game. Not stored in passwords.

Three systems check difficulty:

| System | Routine | Effect |
|--------|---------|--------|
| Weapon damage to bosses | `weapon_difficulty_scale` (bank $0B) | ASL on Normal → 2× damage. Bosses effectively have 2× HP on Difficult. |
| Enemy contact damage | `apply_difficulty_modifier` (bank $0F) | ASL on Normal → 2× damage to enemies. |
| Item drop rates | `item_drop_calc` (bank $0F) | Different RNG threshold tables per difficulty. |

Drop rate comparison:

| Item | Normal | Difficult |
|------|--------|-----------|
| Total drop rate | 72% | 52% |
| Small health | 30% | 5% |
| Small weapon | 20% | 4% |
| Large health | 10% | 15% |
| Large weapon | 10% | 25% |
| Extra life | 1% | 1% |

---

## 21. 6502 Tricks

### Self-Modifying Code

`calc_player_boss_distance` in bank $0B patches its own instruction at runtime:

```asm
.byte $AD, $61, $04    ; encodes: LDA $0461 (boss_x_px)
```

By storing the raw bytes of an `LDA absolute` instruction as data, the routine can change which address it reads by modifying byte 2. This saves the overhead of an indirect pointer load.

### Skip-Byte Tricks

The engine places opcodes so their operand bytes overlap the next instruction, creating two execution paths:

```asm
.byte $A0       ; LDY #imm — the $A0 "eats" the next byte as its operand
some_label:
ASL A           ; $0A — this byte is LDY's operand when falling through,
                ;        but a real ASL when jumped to directly
```

Falling through executes `LDY #$0A`. Jumping to `some_label` executes `ASL A`. This saves one byte versus a branch instruction.

### Soft-Interrupt Dispatch

The AI dispatch loop pushes a return stub address onto the stack, then JMPs to the AI handler. The handler's RTS pops this address and returns to the stub, which advances to the next entity slot. This avoids JSR overhead and allows a single dispatch point to serve all 16 enemy slots.

### Sub-Pixel Arithmetic

All movement uses 16-bit fixed-point math: a whole byte and a sub-pixel byte. The sub-pixel byte accumulates fractional movement. When it overflows (carry set), the whole byte increments. This provides smooth movement at fractional speeds without floating point.

### Stack Page Entity Arrays

Entity arrays at $0100-$017F occupy the 6502 stack page. The hardware stack grows downward from $01FF and the game never nests calls deeply enough to collide with entity data at $0100. This reclaims 128 bytes that would otherwise be wasted.
