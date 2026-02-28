# =============================================================================
# Mega Man 2 (U) — ca65 Disassembly Build System
# =============================================================================

CA65    = ca65 -I .
LD65    = ld65
CFG     = cfg/nes.cfg
ROM_OUT = build/mm2_built.nes
ROM_REF = mm2.nes

# Source files
HEADER_SRC = src/header.asm

# Switchable bank sources ($00-$0E)
BANK_SRCS = \
	src/bank00_stage_flash.asm \
	src/bank01_stage_wood.asm \
	src/bank02_stage_crash.asm \
	src/bank03_stage_heat.asm \
	src/bank04_stage_air.asm \
	src/bank05_stage_metal.asm \
	src/bank06_stage_quick.asm \
	src/bank07_stage_bubble.asm \
	src/bank08_wily_1_2.asm \
	src/bank09_wily_3_5.asm \
	src/bank0A_sound.asm \
	src/bank0B_boss_ai.asm \
	src/bank0C_weapons_ui.asm \
	src/bank0D_stage_engine.asm \
	src/bank0E_game_engine.asm

# Fixed bank source ($0F, $C000-$FFFF)
FIXED_SRC = src/bank0F_fixed.asm

ALL_SRCS = $(HEADER_SRC) $(BANK_SRCS) $(FIXED_SRC)
ALL_OBJS = $(ALL_SRCS:%.asm=build/%.o)

.PHONY: all verify nsfe clean

all: verify nsfe

$(ROM_OUT): $(ALL_OBJS) $(CFG)
	@mkdir -p $(dir $@)
	$(LD65) -C $(CFG) -o $@ $(ALL_OBJS)

# Pattern rule: assemble .asm -> .o
build/%.o: %.asm
	@mkdir -p $(dir $@)
	$(CA65) -o $@ $<

verify: $(ROM_OUT)
	@cmp $(ROM_OUT) $(ROM_REF) && echo "BUILD VERIFIED: byte-perfect match!" || (echo "BUILD FAILED: ROM mismatch"; exit 1)

# =============================================================================
# NSFe build: two-pass ca65/ld65 pipeline (no Python, no ROM extraction)
# =============================================================================
# Pass 1: assemble bank $0C + NSF shim → raw PRG binary
# Pass 2: assemble NSFe wrapper (incbins the PRG) → final .nsfe container

nsfe: build/mm2.nsfe

build/nsfe/bank0C.o: src/bank0C_weapons_ui.asm
	@mkdir -p $(dir $@)
	$(CA65) -o $@ $<

build/nsfe/shim.o: src/nsfe_shim.asm
	@mkdir -p $(dir $@)
	$(CA65) -o $@ $<

build/nsfe_prg.bin: build/nsfe/bank0C.o build/nsfe/shim.o cfg/nsfe_prg.cfg
	@mkdir -p $(dir $@)
	$(LD65) -C cfg/nsfe_prg.cfg -o $@ build/nsfe/bank0C.o build/nsfe/shim.o

build/nsfe/nsfe.o: src/nsfe.asm build/nsfe_prg.bin
	@mkdir -p $(dir $@)
	$(CA65) -o $@ $<

build/mm2.nsfe: build/nsfe/nsfe.o cfg/nsfe.cfg
	@mkdir -p $(dir $@)
	$(LD65) -C cfg/nsfe.cfg -o $@ $<

clean:
	rm -rf build/src build/nsfe build/mm2_built.nes build/mm2.nsfe build/nsfe_prg.bin
