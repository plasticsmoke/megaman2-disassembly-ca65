; =============================================================================
; Mega Man 2 — Zero Page Variable Definitions
; =============================================================================
; Confirmed from fixed bank (bank0F) analysis and Mesen tracing.
; High-confidence names only — uncertain addresses left as raw hex.

; ─── General purpose temporaries ────────────────────────────────────────────
temp_00               = $00    ; general scratch ($00)
temp_01               = $01    ; general scratch ($01)
temp_02               = $02    ; general scratch ($02)
temp_03               = $03    ; general scratch ($03)
temp_04               = $04    ; general scratch / game state index ($04)
temp_05               = $05    ; general scratch ($05)
temp_06               = $06    ; general scratch ($06)
temp_07               = $07    ; general scratch ($07)

; ─── Indirect jump pointer ──────────────────────────────────────────────────
jump_ptr              = $08    ; jump table pointer low ($08) — jmp ($0008)
jump_ptr_hi           = $09    ; jump table pointer high ($09)

; ─── PPU / Rendering ────────────────────────────────────────────────────────
ppu_buffer_count      = $1B    ; PPU buffer entry count ($1B)
frame_counter         = $1C    ; frame counter, incremented every NMI ($1C)
vblank_done           = $1D    ; VBLANK completion flag ($1D)
scroll_x              = $1F    ; horizontal scroll position ($1F)
nametable_select      = $20    ; active nametable, bit 0 ($20)
scroll_y              = $22    ; vertical scroll position ($22)

; ─── Controller Input ───────────────────────────────────────────────────────
controller_1          = $23    ; P1 buttons ($23) — A=$80 B=$40 Sel=$20 Start=$10 U=$08 D=$04 L=$02 R=$01
controller_2          = $24    ; P2 buttons ($24)
p1_prev_buttons       = $25    ; P1 previous frame buttons ($25)
p2_prev_buttons       = $26    ; P2 previous frame buttons ($26)
p1_new_presses        = $27    ; P1 newly pressed this frame ($27)
p2_new_presses        = $28    ; P2 newly pressed this frame ($28)

; ─── Game State ─────────────────────────────────────────────────────────────
current_bank          = $29    ; currently switched PRG bank ($29)
current_stage         = $2A    ; stage index 0-13 ($2A)
current_entity_slot   = $2B    ; entity slot being processed ($2B)
game_substate         = $2C    ; game sub-state / weapon select state ($2C)

; ─── Misc ───────────────────────────────────────────────────────────────────
rng_seed              = $4A    ; random number generator ($4A)
invincibility_timer   = $4B    ; player i-frames countdown ($4B)

; ─── Player State ───────────────────────────────────────────────────────────
current_etanks        = $A7    ; E-tank count ($A7)
current_lives         = $A8    ; lives remaining ($A8)
current_weapon        = $A9    ; selected weapon ID ($A9)

; ─── PPU Control Shadows ────────────────────────────────────────────────────
ppuctrl_shadow        = $F7    ; PPUCTRL mirror ($F7)
ppumask_shadow        = $F8    ; PPUMASK mirror ($F8)
