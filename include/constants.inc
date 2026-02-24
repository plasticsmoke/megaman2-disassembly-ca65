; =============================================================================
; Mega Man 2 — Game Constants
; =============================================================================
; Confirmed from code analysis.

; ─── PRG Bank assignments ────────────────────────────────────────────────────
; Bank $00: Flash Man stage data     Bank $05: Metal Man stage data
; Bank $01: Wood Man stage data      Bank $06: Quick Man stage data
; Bank $02: Crash Man stage data     Bank $07: Bubble Man stage data
; Bank $03: Heat Man stage data      Bank $08: Wily Stages 1-2 data
; Bank $04: Air Man stage data       Bank $09: Wily Stages 3-5 data
; Bank $0A: Music/sound data
; Bank $0B: Game logic and enemy AI
; Bank $0C: Weapon system and UI
; Bank $0D: Stage engine and player control
; Bank $0E: Main game engine (cold boot jumps here)
; Bank $0F: Fixed bank (always mapped at $C000-$FFFF)

BANK_GAME_ENGINE    = $0E       ; Bank switched to on cold boot
BANK_CHR_UPLOAD     = $0C       ; Bank used for CHR-RAM upload callback

; ─── Controller button masks ─────────────────────────────────────────────────
; Button bit positions in controller byte ($23/$24)
; (standard NES controller bit order from read_controllers)
BTN_A               = $80
BTN_B               = $40
BTN_SELECT          = $20
BTN_START           = $10
BTN_UP              = $08
BTN_DOWN            = $04
BTN_LEFT            = $02
BTN_RIGHT           = $01

; ─── PPU constants ───────────────────────────────────────────────────────────
PPUCTRL_NMI_ENABLE  = $80       ; Enable NMI on VBLANK
PPUCTRL_SPR_8X16    = $20       ; 8x16 sprite mode
PPUCTRL_BG_1000     = $10       ; Background pattern table $1000
PPUCTRL_SPR_1000    = $08       ; Sprite pattern table $1000

PPUMASK_SHOW_BG     = $08       ; Show background
PPUMASK_SHOW_SPR    = $10       ; Show sprites
PPUMASK_BG_LEFT8    = $02       ; Show bg in leftmost 8px
PPUMASK_SPR_LEFT8   = $04       ; Show sprites in leftmost 8px
PPUMASK_RENDERING   = $1E       ; All rendering on

; ─── Stage indices ($2A) ────────────────────────────────────────────────────
; Stage select cursor → stage index mapping (from stage_select_index_table)
STAGE_HEAT_MAN      = $00       ; Bank $03
STAGE_AIR_MAN       = $01       ; Bank $04
STAGE_WOOD_MAN      = $02       ; Bank $01
STAGE_BUBBLE_MAN    = $03       ; Bank $07
STAGE_QUICK_MAN     = $04       ; Bank $06
STAGE_FLASH_MAN     = $05       ; Bank $00
STAGE_METAL_MAN     = $06       ; Bank $05
STAGE_CRASH_MAN     = $07       ; Bank $02
STAGE_WILY_1        = $08       ; Bank $08 — Mecha Dragon
STAGE_WILY_2        = $09       ; Bank $08 — Picopico-kun
STAGE_WILY_3        = $0A       ; Bank $09 — Guts-Dozer
STAGE_WILY_4        = $0B       ; Bank $09 — Boobeam Trap
STAGE_WILY_5        = $0C       ; Bank $09 — Wily Machine
STAGE_WILY_6        = $0D       ; (special)  — Alien

; ─── Weapon IDs ($A9) ──────────────────────────────────────────────────────
WEAPON_BUSTER       = $00       ; Mega Buster (default)
WEAPON_ATOMIC_FIRE  = $01       ; Heat Man's weapon
WEAPON_AIR_SHOOTER  = $02       ; Air Man's weapon
WEAPON_LEAF_SHIELD  = $03       ; Wood Man's weapon
WEAPON_BUBBLE_LEAD  = $04       ; Bubble Man's weapon
WEAPON_QUICK_BOOM   = $05       ; Quick Man's weapon
WEAPON_TIME_STOPPER = $06       ; Flash Man's weapon
WEAPON_METAL_BLADE  = $07       ; Metal Man's weapon
WEAPON_CRASH_BOMBER = $08       ; Crash Man's weapon
WEAPON_ITEM_1       = $09       ; Magnet Beam platform
WEAPON_ITEM_2       = $0A       ; Jet sled
WEAPON_ITEM_3       = $0B       ; Climbing platform

; ─── Fixed bank entry points ─────────────────────────────────────────────────
; These are called by all banks via the fixed bank
BANK_SWITCH         = $C000     ; PRG bank switch (A = bank number)
; BANK_ENQUEUE      = $C051     ; Enqueue a bank switch request
; BANKED_ENTRY      = $8000     ; Standard entry point in switched bank
; BANKED_ENTRY_ALT  = $8003     ; Alternate entry point in switched bank
