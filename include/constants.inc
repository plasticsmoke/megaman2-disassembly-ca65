; =============================================================================
; Mega Man 2 — Game Constants
; =============================================================================
; Confirmed from code analysis.

; ─── PRG Bank assignments ────────────────────────────────────────────────────
; Banks $00-$09: Stage/graphics data banks (CHR tile data, level layouts)
; Bank $0A:      Music/sound data
; Bank $0B:      Game logic and enemy AI
; Bank $0C:      Weapon system and UI
; Bank $0D:      Stage engine and player control
; Bank $0E:      Main game engine (cold boot jumps here)
; Bank $0F:      Fixed bank (always mapped at $C000-$FFFF)

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

; ─── Fixed bank entry points ─────────────────────────────────────────────────
; These are called by all banks via the fixed bank
BANK_SWITCH         = $C000     ; PRG bank switch (A = bank number)
; BANK_ENQUEUE      = $C051     ; Enqueue a bank switch request
; BANKED_ENTRY      = $8000     ; Standard entry point in switched bank
; BANKED_ENTRY_ALT  = $8003     ; Alternate entry point in switched bank
