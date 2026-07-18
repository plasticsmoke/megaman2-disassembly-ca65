# Mega Man 2 (U) — ca65 Disassembly

A byte-perfect disassembly of **Mega Man 2** (NES, US release, PRG1) targeting the [ca65](https://cc65.github.io/doc/ca65.html) assembler. Engine banks ($0B-$0F) have descriptive labels, named constants, block headers, algorithm-level inline comments, and architecture overview diagrams. Stage/data banks ($00-$0A) are fully structured: labeled metatile/screen/spawn/checkpoint/palette tables, per-room ownership comments, entity names in spawn lists, and CHR regions tagged with their consumers.

Built with [Claude Code](https://claude.com/claude-code) — starting from raw da65 output through label renaming, constant extraction, code/data verification, and annotation.

Anyone familiar with Mega Man 2's internals, NES development, or MMC1 mapper conventions is welcome to double-check the annotations and file corrections or improvements.

For a detailed walkthrough of the game engine — boot sequence, entity system, AI dispatch, physics, collision, scrolling, boss AI, and more — see **[ENGINE.md](ENGINE.md)**. For data tables, addresses, and ROM hacking reference — see **[DATA_REFERENCE.md](DATA_REFERENCE.md)**.

## Building

Requires ca65/ld65 (from [cc65](https://cc65.github.io/)) and GNU Make.

```
make
```

Produces:
- `build/mm2_built.nes` — byte-perfect ROM, verified against the original
- `build/mm2.nsfe` — NSFe soundtrack (built from source — see below)

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
| $00 | `bank00_heat_wily1.asm` | Heat Man + Wily 1 stage data |
| $01 | `bank01_air_wily2.asm` | Air Man + Wily 2 stage data |
| $02 | `bank02_wood_wily3.asm` | Wood Man + Wily 3 stage data |
| $03 | `bank03_bubble_wily4.asm` | Bubble Man + Wily 4 stage data |
| $04 | `bank04_quick_wily5.asm` | Quick Man + Wily 5 stage data |
| $05 | `bank05_flash_wily6.asm` | Flash Man + Wily 6 stage data |
| $06 | `bank06_metal.asm` | Metal Man stage data |
| $07 | `bank07_crash.asm` | Crash Man stage data |
| $08 | `bank08_menu_chr.asm` | Menu/cutscene CHR graphics |
| $09 | `bank09_cutscenes.asm` | Shared CHR + ending engine, credits |
| $0A | `bank0A_sprites.asm` | Sprite frame + OAM layout data |
| $0B | `bank0B_boss_ai.asm` | Boss AI, enemy AI, collision |
| $0C | `bank0C_sound_engine.asm` | Sound engine + all music/SFX data |
| $0D | `bank0D_menus.asm` | Menus, cutscenes & screens (title, password, stage select, weapon get, game over, ending) |
| $0E | `bank0E_game_engine.asm` | Main game engine, entity AI dispatch |
| $0F | `bank0F_fixed.asm` | **Fixed bank** ($C000-$FFFF): bank switch, NMI, PPU, controllers |

Banks $00-$0A are primarily data (stage data, graphics, sprite tables). Each of banks $00-$07 holds one Robot Master stage + its paired Wily stage (see [Stage Data Banks](#stage-data-banks)). Banks $0B-$0F are the engine code banks.

## Project Structure

```
src/
  header.asm                  iNES header (Mapper 1 / MMC1)
  bank00_heat_wily1.asm       Heat Man + Wily 1 stage data
  bank01_air_wily2.asm        Air Man + Wily 2 stage data
  bank02_wood_wily3.asm       Wood Man + Wily 3 stage data
  bank03_bubble_wily4.asm     Bubble Man + Wily 4 stage data
  bank04_quick_wily5.asm      Quick Man + Wily 5 stage data
  bank05_flash_wily6.asm      Flash Man + Wily 6 stage data
  bank06_metal.asm            Metal Man stage data
  bank07_crash.asm            Crash Man stage data
  bank08_menu_chr.asm         Menu/cutscene CHR graphics
  bank09_cutscenes.asm        Shared CHR + ending engine, credits
  bank0A_sprites.asm          Sprite frame + OAM layout data
  bank0B_boss_ai.asm          Boss AI, enemy AI, collision
  bank0C_sound_engine.asm     Sound engine + all music/SFX data
  bank0D_menus.asm            Menus, cutscenes & screens (title, password, ending)
  bank0E_game_engine.asm      Main game engine, entity AI dispatch
  bank0F_fixed.asm            Fixed bank — NMI, PPU, bank switching, controllers
  nsfe_shim.asm               NSFe init/play driver shim ($C000)
  nsfe.asm                    NSFe container with metadata
include/
  zeropage.inc                Zero-page variable definitions
  ram.inc                     Entity array equates ($0100-$06F0) + RAM buffers
  constants.inc               Named constants (entity types, stage/weapon IDs, flags)
  hardware.inc                NES hardware registers (PPU, APU, controller, MMC1)
  fixed_bank.inc              Cross-bank entry point declarations
cfg/
  nes.cfg                     ld65 linker configuration (ROM)
  nsfe_prg.cfg                ld65 linker configuration (NSFe PRG pass)
  nsfe.cfg                    ld65 linker configuration (NSFe container pass)
```

## Annotation

The raw da65 disassembly produced generic `L_XXXX` address labels and `code_XXXX` branch targets across all 16 banks. All labels in the 5 engine banks ($0B-$0F) have been replaced with descriptive names. Named constants cover entity arrays, stage/weapon/entity type IDs, player flags, button masks, and NES hardware registers.

### Label and Constant Work

- **2,663 label renames** across banks $0B-$0F — subroutine identification, AI routines, engine subsystems
- **462 block headers** and **366+ inline comments** documenting code purpose and algorithms
- **4,555+ constant substitutions** — hardware registers, zero-page variables, RAM arrays, game constants
- **5 include files**: `hardware.inc` (PPU/APU/MMC1), `ram.inc` (entity arrays), `zeropage.inc` (zero-page vars), `constants.inc` (game constants and entity types), `fixed_bank.inc` (cross-bank entry points)

### Code/Data Verification

The da65 disassembler frequently confuses code and data — bytes that happen to be valid 6502 opcodes get decoded as instructions when they are actually data table entries, and vice versa. All 16 banks have been verified and corrected:

| Banks | Description | Status |
|-------|-------------|--------|
| $00-$0A | Stage data, graphics, sprite tables (11 banks, 571 BRK artifacts) | Done |
| $0B | Boss AI, enemy AI, collision | Done |
| $0C | Sound engine + music/SFX data | Done |
| $0D | Menus, cutscenes & screens | Done |
| $0E | Main game engine, entity AI dispatch | Done |
| $0F | Fixed bank: NMI, PPU, bank switch | Done |

Types of fixes applied: code-as-`.byte` (instruction sequences stored as raw data), data-as-instruction (table bytes decoded as opcodes), skip-byte tricks (intentional instruction overlaps), code/data overlaps (dual-purpose bytes), and instruction sync errors (da65 decoding at wrong byte boundary). Bank $09 contains the only executable code in the data banks (the ending cutscene engine at $8600-$86FF).

### Entity Type Verification

All 128 entity type IDs ($00-$7F) have been identified and named using Mesen debugger breakpoints on the entity spawn routine (`entity_init_from_type` at $D77C), code tracing, and gameplay verification across all stages. Entity names use canonical Japanese names where applicable (e.g., Kukku, Kerog, Tanishi). The complete mapping is defined in `include/constants.inc`.

## Engine Overview

For a comprehensive guide to the engine internals, see **[ENGINE.md](ENGINE.md)**. It covers:

- Boot sequence and game state machine
- NMI / VBLANK pipeline (OAM DMA, palette, scroll, PPU writes)
- Entity system (32 slots, parallel arrays, lifecycle)
- Entity AI dispatch (128-entry pointer table, dual dispatch modes)
- Entity physics (sub-pixel movement, gravity, velocity)
- Collision detection (player contact, weapon hit, tile collision)
- Scrolling and camera (incremental, room transitions, screen shake)
- Player physics (jump, gravity, floor/ceiling snap)
- Weapon system (firing pipeline, per-weapon handlers)
- Boss AI (phase state machines, attack patterns, utilities)
- Stage data format and bank layout
- Password and difficulty systems
- 6502 tricks (self-modifying code, skip-byte, sub-pixel math)

## Stage Data Banks

A stage's data bank is `current_stage AND #$07` — a Robot Master stage and
its paired Wily stage (index +8) share one bank containing the pair's
metatiles, room layouts, spawns, checkpoints, CHR upload lists and palettes:

| Bank | Stages |
|------|--------|
| $00 | Heat Man + Wily 1 |
| $01 | Air Man + Wily 2 |
| $02 | Wood Man + Wily 3 |
| $03 | Bubble Man + Wily 4 |
| $04 | Quick Man + Wily 5 |
| $05 | Flash Man + Wily 6 |
| $06 | Metal Man |
| $07 | Crash Man |

CHR pattern data is cross-bank: each stage's graphics are assembled from
explicit (bank, page) reference lists (e.g. Mega Man's tiles come from bank
$00 $9000 for every stage). Banks $08/$09 hold menu/cutscene graphics, the
ending engine and the credits text — no stage data.

## NSFe Soundtrack

The NSFe file is built entirely from source — no ROM extraction, no external scripts. Bank $0C contains the complete sound engine and all music/instrument data, fully self-contained. A two-pass ca65/ld65 pipeline assembles bank $0C with the NSF init/play shim (`nsfe_shim.asm`) into a raw PRG binary, then wraps it by `src/nsfe.asm` into a complete NSFe container with chunk headers, track metadata, and the PRG payload via `.incbin`.

All metadata lives in `src/nsfe.asm` as assembly directives: track names, per-track durations, fade times, and composer credits. Chunk sizes auto-calculate via label math. To change a track title or timing, edit the file and rebuild.

53 tracks: 24 music (Opening through Credits, all 8 stage themes, Wily stages, boss battle, jingles) and 29 sound effects. Playable in any NSFe-compatible player (NSFPlay, Mesen, etc.).

## License

MIT License. See [LICENSE](LICENSE) for details.

This is a disassembly — the original game is copyrighted by Capcom. This project provides only the annotated assembly source. No ROM data is included.
