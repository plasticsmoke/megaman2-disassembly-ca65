# Mega Man 2 (U) — ca65 Disassembly

A byte-perfect disassembly of **Mega Man 2** (NES, US release, PRG1) targeting the [ca65](https://cc65.github.io/doc/ca65.html) assembler. Engine banks ($0B-$0F) have descriptive labels, named constants, block headers, algorithm-level inline comments, and architecture overview diagrams. Stage/data banks ($00-$0A) have section headers and entity name annotations.

Built with [Claude Code](https://claude.com/claude-code) — starting from raw da65 output through label renaming, constant extraction, code/data verification, and annotation.

Anyone familiar with Mega Man 2's internals, NES development, or MMC1 mapper conventions is welcome to double-check the annotations and file corrections or improvements.

For a detailed walkthrough of the game engine — boot sequence, entity system, AI dispatch, physics, collision, scrolling, boss AI, and more — see **[ENGINE.md](ENGINE.md)**. For data tables, addresses, and ROM hacking reference — see **[DATA_REFERENCE.md](DATA_REFERENCE.md)**.

## Building

Requires ca65/ld65 (from [cc65](https://cc65.github.io/)) and GNU Make.

```
make
```

Produces `build/mm2_built.nes` (verified byte-perfect against the original ROM) and `build/mm2.nsfe` (NSFe soundtrack).

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
| $0C | `bank0C_weapons_ui.asm` | Weapon system, UI rendering, sound engine |
| $0D | `bank0D_stage_engine.asm` | Stage engine, player control, OAM |
| $0E | `bank0E_game_engine.asm` | Main game engine, entity AI dispatch |
| $0F | `bank0F_fixed.asm` | **Fixed bank** ($C000-$FFFF): bank switch, NMI, PPU, controllers |

Banks $00-$0A are primarily data (tile maps, entity spawn tables, music). Each of banks $00-$07 contains tile data for one stage and entity spawn data for a different stage (see [Dual Bank Mapping](#dual-bank-mapping)). Banks $0B-$0F are the engine code banks.

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
  bank0C_weapons_ui.asm       Weapon system, UI rendering, sound engine
  bank0D_stage_engine.asm     Stage engine, player control, OAM
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
| $00-$0A | Stage data + sound (11 banks, 571 BRK artifacts) | Done |
| $0B | Boss AI, enemy AI, collision | Done |
| $0C | Weapon system, UI rendering | Done |
| $0D | Stage engine, player control, OAM | Done |
| $0E | Main game engine, entity AI dispatch | Done |
| $0F | Fixed bank: NMI, PPU, bank switch | Done |

Types of fixes applied: code-as-`.byte` (instruction sequences stored as raw data), data-as-instruction (table bytes decoded as opcodes), skip-byte tricks (intentional instruction overlaps), code/data overlaps (dual-purpose bytes), and instruction sync errors (da65 decoding at wrong byte boundary). Bank $09 contains the only executable code in the data banks (scroll update routines at $860C-$86FF).

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
- Stage data format and dual bank mapping
- Password and difficulty systems
- 6502 tricks (self-modifying code, skip-byte, sub-pixel math)

## Dual Bank Mapping

Stage data banks $00-$07 each contain data for **two different stages**, accessed through different bank-selection methods:

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

## NSFe Soundtrack

`make` also builds `build/mm2.nsfe`, an [NSFe](https://www.nesdev.org/wiki/NSFe) soundtrack file with track names, per-track durations, fade-out times, and composer credits. Playable in any NSFe-compatible player (NSFPlay, Mesen, etc.).

Bank $0C contains the complete sound engine and all music data — no other ROM banks are needed for music playback. The build uses a two-pass ca65/ld65 pipeline (same approach as [MM3](https://github.com/megamanforever/megaman3-disassembly-ca65)):

1. **Pass 1:** Assemble bank $0C + NSF init/play shim (`nsfe_shim.asm`) into a raw PRG binary
2. **Pass 2:** Assemble the NSFe container (`nsfe.asm`), which `.incbin`s the PRG and wraps it with metadata chunks

24 tracks covering all music — Opening through Ending, including the Dr. Wily UFO jingle. Track names, durations, and composer attributions are defined in `src/nsfe.asm`.

## License

MIT License. See [LICENSE](LICENSE) for details.

This is a disassembly — the original game is copyrighted by Capcom. This project provides only the annotated assembly source. No ROM data is included.
