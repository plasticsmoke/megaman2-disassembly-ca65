# Mega Man 2 (U) — ca65 Disassembly

Byte-perfect ca65 disassembly of **Mega Man 2** (USA, NES, PRG1).

## Build

```
make          # assemble + link + verify byte-perfect match
make clean    # remove build artifacts
```

Requires: [ca65/ld65](https://cc65.github.io/) (cc65 toolchain).
Reference ROM `mm2.nes` must be present in the project root.

## ROM Details

| Property | Value |
|---|---|
| Mapper | 1 (MMC1), mode 3 |
| PRG ROM | 256 KB (16 x 16 KB banks) |
| CHR | RAM (8 KB) |
| Mirroring | Vertical |
| Vectors | NMI=$CFF0, Reset=$FFE0, IRQ=$FFE0 |

## Bank Map

| Bank | File | Contents |
|---|---|---|
| $00 | `bank00_stage_data_1.asm` | Flash Man stage data |
| $01 | `bank01_stage_data_2.asm` | Wood Man stage data |
| $02 | `bank02_stage_data_3.asm` | Crash Man stage data |
| $03 | `bank03_stage_data_4.asm` | Heat Man stage data |
| $04 | `bank04_stage_data_5.asm` | Air Man stage data |
| $05 | `bank05_stage_data_6.asm` | Metal Man stage data |
| $06 | `bank06_stage_data_7.asm` | Quick Man stage data |
| $07 | `bank07_stage_data_8.asm` | Bubble Man stage data |
| $08 | `bank08_stage_data_9.asm` | Wily Stages 1-2 data |
| $09 | `bank09_stage_data_10.asm` | Wily Stages 3-5 data + scroll code |
| $0A | `bank0A_sound_data.asm` | Music and sound data |
| $0B | `bank0B_game_logic.asm` | Boss AI, enemy AI, collision |
| $0C | `bank0C_weapons_ui.asm` | Weapon system, UI rendering |
| $0D | `bank0D_stage_engine.asm` | Stage engine, player control, OAM |
| $0E | `bank0E_game_engine.asm` | Main game engine, entity AI dispatch |
| $0F | `bank0F_fixed.asm` | Fixed bank ($C000-$FFFF): bank switch, NMI, PPU, controllers |

Banks $00-$0A are pure data (tile maps, entity spawn tables, music).
Banks $0B-$0F are the engine code banks.

## Annotation Progress

### Phase 1-3: Initial Disassembly + Structure (COMPLETE)

- Byte-perfect ca65 reassembly from da65 output
- All 16 banks split into individual source files
- Label renaming and block headers for all 5 engine banks
- `include/constants.inc` with stage, weapon, entity, and PPU constants

### Phase 4: Deep Annotation (COMPLETE)

- 2,663 label renames across banks $0B-$0F
- 462 block headers and 366 inline comments
- Full subroutine identification for fixed bank routines

### Phase 5: Code/Data Verification (IN PROGRESS)

The da65 disassembler frequently confuses code and data — bytes that happen
to be valid 6502 opcodes get decoded as instructions when they are actually
data table entries, and vice versa. Phase 5 fixes these misidentifications.

#### Code/Data Fix Status by Bank

| Bank | Description | .byte % | BRK | Status | Est. |
|---|---|---|---|---|---|
| $0E | Game engine, entity AI dispatch | 6% | 0 | **DONE** | 100% |
| $0D | Stage engine, player control, OAM | 29% | 0 | **DONE** | 100% |
| $0C | Weapon system, UI rendering | 42% | 68 | Pending | 0% |
| $0B | Boss AI, enemy AI, collision | 21% | 33 | Pending | 0% |
| $0F | Fixed bank: NMI, PPU, bank switch | 17% | 8 | Pending | 0% |

**.byte %** = proportion of lines that are `.byte` directives (lower = more code decoded).
**BRK** = `brk` instructions remaining — almost always da65 artifacts (NES code never
uses BRK). Higher counts indicate more code/data boundary errors to fix.
**Est.** = estimated completion of code/data verification for that bank.

#### Types of Fixes Applied (bank $0E)

1. **Code-as-.byte**: Instruction sequences stored as `.byte` data because da65
   lost sync at a data/code boundary. Fixed by decoding ROM bytes and replacing
   with proper 6502 instructions.

2. **Data-as-instruction**: Data table bytes that happen to be valid opcodes
   (e.g., $A9=LDA#, $94=STY zpg,X) decoded as instructions. Fixed by
   converting to `.byte` directives.

3. **Skip-byte tricks**: Intentional overlaps where a 2-byte instruction
   (CMP#, BIT zpg, STA zpg) "eats" the next byte to skip it. Documented
   with comments.

4. **Code/data overlaps**: Bytes that serve dual purpose as both executable
   code (when reached via fall-through) and data table entries (when indexed
   by LDA table,Y). Documented with comments.

5. **Instruction sync errors**: da65 starting decode at wrong byte boundary,
   producing garbled multi-byte instructions (e.g., `ora $E0DE,x` from a
   split `DEC $04E0,X`). Fixed by re-syncing to correct boundaries.

### Phase 5: Entity Name Verification (IN PROGRESS)

Using Mesen debugger to confirm entity type IDs against canonical Japanese
names from official sources.

- Mesen-complete: Bubble Man, Crash Man, Flash Man, Heat Man, Wood Man
- Remaining: Air Man, Quick Man, Metal Man, Wily stages
