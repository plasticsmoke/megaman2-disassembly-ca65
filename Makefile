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

.PHONY: all verify clean

all: verify

$(ROM_OUT): $(ALL_OBJS) $(CFG)
	@mkdir -p $(dir $@)
	$(LD65) -C $(CFG) -o $@ $(ALL_OBJS)

# Pattern rule: assemble .asm -> .o
build/%.o: %.asm
	@mkdir -p $(dir $@)
	$(CA65) -o $@ $<

verify: $(ROM_OUT)
	@cmp $(ROM_OUT) $(ROM_REF) && echo "BUILD VERIFIED: byte-perfect match!" || (echo "BUILD FAILED: ROM mismatch"; exit 1)

clean:
	rm -rf build/src build/mm2_built.nes
