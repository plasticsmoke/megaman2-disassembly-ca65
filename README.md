# Mega Man 2 (U) — ca65 Disassembly

A byte-perfect disassembly of **Mega Man 2** (NES, US release, PRG1) targeting the [ca65](https://cc65.github.io/doc/ca65.html) assembler. Engine banks ($0B-$0F) have descriptive labels, named constants, block headers, and inline comments. Stage/data banks ($00-$0A) have section headers and entity name annotations.

Built with [Claude Code](https://claude.com/claude-code) — starting from raw da65 output through label renaming, constant extraction, code/data verification, and annotation.

Anyone familiar with Mega Man 2's internals, NES development, or MMC1 mapper conventions is welcome to double-check the annotations and file corrections or improvements.

## Building

Requires ca65/ld65 (from [cc65](https://cc65.github.io/)) and GNU Make.

```
make
```

Produces `build/mm2_built.nes`, verified byte-perfect against the original ROM.

The reference ROM (`mm2.nes`) is **not included** — you must supply your own and place it in the project root. The build will assemble the source and verify a byte-perfect match automatically.

### Expected Checksums

| Algorithm | Value |
|-----------|-------|
| CRC32 | `A9BD44BC` |
| MD5 | `caaeb9ee3b52839de261fd16f93103e6` |
| SHA-1 | `6b5b9235c3f630486ed8f07a133b044eaa2e22b2` |
| SHA-256 | `27b5a635df33ed57ed339dfc7fd62fc603b39c1d1603adb5cdc3562a0b0d555b` |

## ROM Layout

Mapper 1 (MMC1), mode 3. 256 KB PRG (16 x 16 KB banks) + 8 KB CHR-RAM. Vertical mirroring. Bank $0F is fixed at $C000-$FFFF; banks $00-$0E are switchable at $8000-$BFFF.

| Bank | File | Contents |
|------|------|----------|
| $00 | `bank00_stage_flash.asm` | Flash Man stage data |
| $01 | `bank01_stage_wood.asm` | Wood Man stage data |
| $02 | `bank02_stage_crash.asm` | Crash Man stage data |
| $03 | `bank03_stage_heat.asm` | Heat Man stage data |
| $04 | `bank04_stage_air.asm` | Air Man stage data |
| $05 | `bank05_stage_metal.asm` | Metal Man stage data |
| $06 | `bank06_stage_quick.asm` | Quick Man stage data |
| $07 | `bank07_stage_bubble.asm` | Bubble Man stage data |
| $08 | `bank08_wily_1_2.asm` | Wily Stages 1-2 data |
| $09 | `bank09_wily_3_5.asm` | Wily Stages 3-5 data + scroll code |
| $0A | `bank0A_sound.asm` | Music and sound data |
| $0B | `bank0B_boss_ai.asm` | Boss AI, enemy AI, collision |
| $0C | `bank0C_weapons_ui.asm` | Weapon system, UI rendering |
| $0D | `bank0D_stage_engine.asm` | Stage engine, player control, OAM |
| $0E | `bank0E_game_engine.asm` | Main game engine, entity AI dispatch |
| $0F | `bank0F_fixed.asm` | **Fixed bank** ($C000-$FFFF): bank switch, NMI, PPU, controllers |

Banks $00-$0A are primarily data (tile maps, entity spawn tables, music). Each of banks $00-$07 contains tile data for one stage and entity spawn data for a different stage (see [Engine Notes](#engine-notes)). Banks $0B-$0F are the engine code banks.

## Project Structure

```
src/
  header.asm                  iNES header (Mapper 1 / MMC1)
  bank00_stage_flash.asm      Flash Man stage data
  bank01_stage_wood.asm       Wood Man stage data
  bank02_stage_crash.asm      Crash Man stage data
  bank03_stage_heat.asm       Heat Man stage data
  bank04_stage_air.asm        Air Man stage data
  bank05_stage_metal.asm      Metal Man stage data
  bank06_stage_quick.asm      Quick Man stage data
  bank07_stage_bubble.asm     Bubble Man stage data
  bank08_wily_1_2.asm         Wily Stages 1-2 data
  bank09_wily_3_5.asm         Wily Stages 3-5 data + scroll code
  bank0A_sound.asm            Music and sound data
  bank0B_boss_ai.asm          Boss AI, enemy AI, collision
  bank0C_weapons_ui.asm       Weapon system, UI rendering
  bank0D_stage_engine.asm     Stage engine, player control, OAM
  bank0E_game_engine.asm      Main game engine, entity AI dispatch
  bank0F_fixed.asm            Fixed bank — NMI, PPU, bank switching, controllers
include/
  zeropage.inc                Zero-page variable definitions
  ram.inc                     Entity array equates ($0400-$06C0) + RAM buffers
  constants.inc               Named constants (entity types, stage/weapon IDs, flags)
  hardware.inc                NES hardware registers (PPU, APU, controller, MMC1)
cfg/
  nes.cfg                     ld65 linker configuration
```

## Annotation

The raw da65 disassembly produced generic `L_XXXX` address labels and `code_XXXX` branch targets across all 16 banks. All labels in the 5 engine banks ($0B-$0F) have been replaced with descriptive names. Named constants cover entity arrays, stage/weapon/entity type IDs, player flags, button masks, and NES hardware registers.

### Label and Constant Work

- **2,663 label renames** across banks $0B-$0F — subroutine identification, AI routines, engine subsystems
- **462 block headers** and **366 inline comments** documenting code purpose
- **4,555 constant substitutions** — hardware registers, zero-page variables, RAM arrays, game constants
- **4 include files**: `hardware.inc` (PPU/APU/MMC1), `ram.inc` (entity arrays), `zeropage.inc` (zero-page vars), `constants.inc` (game constants and entity types)

### Code/Data Verification

The da65 disassembler frequently confuses code and data — bytes that happen to be valid 6502 opcodes get decoded as instructions when they are actually data table entries, and vice versa. All 16 banks have been verified and corrected:

| Banks | Description | Status |
|-------|-------------|--------|
| $00-$0A | Stage data + sound (11 banks, 571 BRK artifacts) | Done |
| $0B | Boss AI, enemy AI, collision | Done |
| $0C | Weapon system, UI rendering | Done |
| $0D | Stage engine, player control, OAM | Done |
| $0E | Main game engine, entity AI dispatch | Done |
| $0F | Fixed bank: NMI, PPU, bank switch | Done |

Types of fixes applied: code-as-`.byte` (instruction sequences stored as raw data), data-as-instruction (table bytes decoded as opcodes), skip-byte tricks (intentional instruction overlaps), code/data overlaps (dual-purpose bytes), and instruction sync errors (da65 decoding at wrong byte boundary). Bank $09 contains the only executable code in the data banks (scroll update routines at $860C-$86FF).

### Entity Name Verification

Entity type IDs verified against canonical Japanese names using Mesen debugger breakpoints on the entity spawn routine.

- Complete: Bubble Man, Crash Man, Flash Man, Heat Man, Wood Man
- Remaining: Air Man, Quick Man, Metal Man, Wily stages

## Engine Notes

**MMC1 bank switching.** Mode 3 keeps bank $0F permanently at $C000-$FFFF. The switchable window at $8000-$BFFF maps one of banks $00-$0E.

**Dual bank allocation.** Stage data banks $00-$07 each contain data for **two different stages**, accessed through different bank-selection methods:

- **Tile/map data** (CHR patterns, metatiles, screen layouts, room config) — selected via a `stage_bank_table` lookup in bank $0E. Each stage index maps to a non-obvious bank number.
- **Entity spawn tables and BG palettes** (at offsets $3600-$3A00 and $3E00 within each bank) — selected by masking the stage index directly (`current_stage AND #$07`). The spawn table has 4 sub-arrays at $B600/$B700/$B800/$B900: screen number, X position, Y position, and entity type ID.

For example, bank $00 contains Flash Man's tile data but Heat Man's entity spawn tables. The full mapping:

| Stage index | Stage | Tile bank | Entity bank |
|-------------|-------|-----------|-------------|
| $00 | Heat Man | $03 | $00 |
| $01 | Air Man | $04 | $01 |
| $02 | Wood Man | $01 | $02 |
| $03 | Bubble Man | $07 | $03 |
| $04 | Quick Man | $06 | $04 |
| $05 | Flash Man | $00 | $05 |
| $06 | Metal Man | $05 | $06 |
| $07 | Crash Man | $02 | $07 |
| $08 | Wily 1 | $08 | $00 (shared with Heat) |
| $09 | Wily 2 | $08 | $01 (shared with Air) |
| $0A | Wily 3 | $09 | $02 (shared with Wood) |
| $0B | Wily 4 | $09 | $03 (shared with Bubble) |
| $0C | Wily 5 | $09 | $04 (shared with Quick) |

Wily stages share entity spawn banks with Robot Master stages — both stages' entities coexist in one table, sorted by screen number. Banks $08-$09 contain only tile/layout data. Bank filenames follow the tile data mapping (primary content by volume).

**Entity system.** 32 entity slots using parallel arrays at $0400-$06C0 with $10 stride. Slots $00-$0F are player and weapons/projectiles; $10-$1F are enemies, items, and bosses. Key arrays: `$0400,x` = entity type, `$0410,x` = spawn type, `$0420,x` = flags, `$0430,x` = entity behavior flags. Entity AI is dispatched through a 128-entry pointer table at $92F0 in bank $0E, with each entry containing a low byte, high byte, and bank number.

**Entity AI dispatch.** The `$AA` variable selects the dispatch mode: when zero, the entity's type indexes the main AI pointer table directly (bank field in the table is ignored — AI runs in the currently loaded bank). When non-zero, special dispatch logic applies for cross-bank entity routines.

**Dynamic spawning.** Entities spawn through two paths: static spawns from per-stage entity tables (scanned by `entity_spawn_scan` at $C196), and dynamic child spawns via `spawn_entity_from_parent` ($D162 in the fixed bank). Some bosses self-convert by writing directly to the entity type array rather than spawning a new slot.

**Camera/scrolling system.** The scroll engine spans four banks:

- **Bank $0E** — main scroll logic: boundary checks, incremental scroll handlers, full room transitions, smooth scroll animations
- **Bank $0F** — NMI VBLANK handler: PPUSCROLL register writes, camera offset subtraction, nametable column/attribute PPU updates
- **Bank $0D** — stage initialization: sets up scroll pointers, screen boundaries, metatile column rendering
- **Bank $09** — Wily fortress vertical scroll routines (the only executable code in a data bank)

Horizontal scrolling works at two levels. **Incremental scrolling** runs each frame: when the player passes the viewport midpoint (player_x - scroll_x >= $80), the camera advances by the player's movement delta. A pixel-to-column conversion (`(low_2bits + delta) >> 2`) determines how many metatile columns to decode, since each column is 4 pixels wide in scroll units. The `column_index` counter wraps mod 64 across both nametables. **Full room transitions** occur when scroll reaches a boundary ($14/$15): entities are cleared, the destination nametable is rendered off-screen, a 63-frame smooth scroll animation plays (scroll_x += 4/frame), then pointers advance by $40 (64 bytes = one screen of column data) and `entity_spawn_scan` repopulates enemies.

Vertical transitions use direction-indexed data tables (index 0 = up, index 1 = down) that provide per-frame scroll_y deltas, player Y steps, and a frame counter that runs ~60 frames.

Screen shake is implemented via camera offsets (`camera_x_offset`/`camera_y_offset` at $B8/$B6) subtracted from the scroll position in the NMI handler before writing PPUSCROLL. The nametable select bit is computed as `nametable_select XOR scroll_x_carry` to ensure seamless horizontal scrolling across both nametables.

PPU updates are queued during gameplay and applied during VBLANK: `col_update_count` ($47) triggers vertical tile column writes, and `attr_update_count` ($51) triggers attribute table writes with three modes — normal overwrite, fill (bulk 2×2 metatile region), and read-modify-write (merge with existing attributes to avoid clobbering adjacent palettes).

Key scroll variables (all in zero page):

| Address | Name | Purpose |
|---------|------|---------|
| $14/$15 | `scroll_screen_lo/hi` | Left/right nametable boundary indices for current room |
| $16/$17 | `metatile_ptr_lo/hi` | 16-bit pointer into metatile column data |
| $18/$19 | `column_ptr_lo/hi` | 16-bit pointer into column tile buffer |
| $1A | `column_index` | Current tile column counter (wraps mod 64) |
| $1E | `scroll_subpixel` | Scroll sub-pixel accumulator |
| $1F | `scroll_x` | Horizontal scroll position (0-255) |
| $20 | `nametable_select` | Active nametable (bit 0) |
| $21 | `scroll_y_page` | Scroll Y page / nametable vertical bit |
| $22 | `scroll_y` | Vertical scroll position (0-239) |
| $37 | `transition_type` | Room transition request (0=none, bit0=vertical, $03=boss) |
| $38 | `current_screen` | Current room/screen index within stage |
| $47 | `col_update_count` | PPU column tile write pending count |
| $51 | `attr_update_count` | PPU attribute write pending count (bit 7 = fill mode) |
| $54 | `attr_update_mode` | Attribute merge mode (0=overwrite, nonzero=read-modify-write) |
| $B6 | `camera_y_offset` | Camera Y offset for screen shake |
| $B8/$B9 | `camera_x_offset/hi` | Camera X offset for screen shake (16-bit) |

**Skip-byte tricks.** The engine uses intentional instruction overlaps to save bytes. A `LDY #imm` ($A0) or `JMP abs` ($4C) opcode is placed so its operand bytes overlap the next instruction, creating two valid execution paths depending on the entry point. Example in bank $0C: `$A0` (LDY#) eats the next byte ($0A = ASL A opcode), so falling through executes `LDY #$0A` while jumping to the next label executes `ASL A`.

**Password system.** Passwords use a 5x5 grid with exactly 9 dots. The grid encodes two pieces of state:

- **E-tank count** (cells 0-3, row 0): The column containing a dot indicates E-tanks held (0-3). This also sets the starting offset for the data region.
- **Beaten boss flags** (cells 5-24, rows 1-4): 20 cells encode 16 meaningful bits via scrambled lookup tables (`password_bit_mask_table` and `password_byte_index_table`). 8 bits store the beaten boss bitfield (`$9A`), and 8 bits store its complement. 4 of the 20 positions are dummy (mask = $00).

Validation: the decoded data byte OR'd with the complement byte must equal $FF. Since any valid progress value and its inverse cover all 8 bits, this catches invalid dot placements. Cell 4 (row 0, column 5) is unused.

The password does **not** encode difficulty — only E-tanks and beaten bosses. Difficulty (`$CB`) persists in RAM and resets to Normal (0) on power cycle.

**Difficulty system.** RAM address `$CB` holds the difficulty flag: 0 = Normal, 1 = Difficult. Selected on the ending screen after completing the game (defaults to Normal on cold boot). Not stored in passwords. Affects exactly three systems:

- **Weapon damage to bosses** — `weapon_difficulty_scale` (bank $0B) doubles damage via ASL on Normal. Called from all 9 weapon-vs-boss handlers (Buster, Metal Blade, Quick Boomerang, Leaf Shield, Crash Bomb, Air Shooter, etc.). Bosses effectively have 2x HP on Difficult.
- **Enemy collision damage to player** — `apply_difficulty_modifier` (bank $0F) doubles damage via ASL on Normal. Called from 8 enemy collision handlers. Counter-intuitively, Normal mode doubles damage *dealt to enemies*, not damage taken.
- **Item drop rates** — `item_drop_calc` (bank $0F) uses completely different RNG threshold tables. Normal: 72% total drop rate (30% small health, 20% small weapon, 10% large health, 10% large weapon, 1% extra life). Difficult: 52% total drop rate (25% large weapon, 15% large health, 5% small health, 4% small weapon, 1% extra life).

## License

MIT License. See [LICENSE](LICENSE) for details.

This is a disassembly — the original game is copyrighted by Capcom. This project provides only the annotated assembly source. No ROM data is included.
