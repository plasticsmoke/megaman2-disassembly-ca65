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
	src/bank00_stage_data_1.asm \
	src/bank01_stage_data_2.asm \
	src/bank02_stage_data_3.asm \
	src/bank03_stage_data_4.asm \
	src/bank04_stage_data_5.asm \
	src/bank05_stage_data_6.asm \
	src/bank06_stage_data_7.asm \
	src/bank07_stage_data_8.asm \
	src/bank08_stage_data_9.asm \
	src/bank09_stage_data_10.asm \
	src/bank0A_sound_data.asm \
	src/bank0B_game_logic.asm \
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
