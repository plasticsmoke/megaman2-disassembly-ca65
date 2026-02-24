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

; ─── HP / Energy ───────────────────────────────────────────────────────────
MAX_HP              = $1C       ; 28 — max player/boss HP and weapon energy

; ─── Entity flag bitmasks ($0420,x / $0430,x) ─────────────────────────────
ENT_FLAG_ACTIVE     = $80       ; bit 7: entity is alive/spawned
ENT_FLAG_FLIP_H     = $40       ; bit 6: facing left (horizontally flipped)
ENT_FLAG_NO_COLLIDE = $20       ; bit 5: skip collision checks
ENT_FLAG_WEAPON_HIT = $02       ; bit 1: was hit by weapon this frame
ENT_FLAG_CONTACT_DMG = $01      ; bit 0: deals contact damage

; ─── Stage thresholds ──────────────────────────────────────────────────────
WILY_STAGE_START    = $08       ; stages $08+ are Wily fortress

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

; ─── Entity type IDs (confirmed from Mesen + code tracing) ─────────────────
; Enemy entities
ENTITY_SHRINK       = $00       ; Bubble Man — shrimp, spawned by Anko
ENTITY_KEROG        = $0C       ; Bubble Man — large frog
ENTITY_PETIT_KEROG  = $0D       ; spawned by Kerog
ENTITY_TANISHI      = $0A       ; Bubble Man/Wood Man — snail
ENTITY_TANISHI_BARE = $0B       ; Tanishi without shell (Difficult mode)
ENTITY_M445         = $04       ; Bubble Man — jellyfish
ENTITY_CLAW         = $07       ; Bubble Man — crab/snapper
ENTITY_BATTON       = $16       ; Wood Man — bat
ENTITY_ROBBIT       = $17       ; Wood Man — rabbit
ENTITY_MONKING      = $1D       ; Wood Man — monkey
ENTITY_KUKKU        = $1E       ; Wood Man — chicken
ENTITY_FRIENDER     = $1C       ; Wood Man — fire dog
ENTITY_MATASABURO   = $36       ; Air Man — fan fiend, wind push
ENTITY_FLY_BOY      = $2C       ; Crash Man/Heat Man — propeller enemy
ENTITY_NEO_METALL   = $34       ; Crash Man — advanced Met
ENTITY_NEO_METALL_FLIP = $56    ; Neo Metall flipped variant
ENTITY_SCWORM       = $50       ; Flash/Air/Quick Man — worm
ENTITY_SPRINGER     = $46       ; Heat/Quick/Metal Man — bouncing robot
ENTITY_SNIPER_ARMOR = $4E       ; Flash/Heat/Quick Man — mech suit
ENTITY_CRAZY_CANNON = $4B       ; Flash/Air/Crash Man — cannon enemy
ENTITY_BLOCKY       = $31       ; Metal/Crash/Flash Man — block enemy
ENTITY_PIPI_SPAWN   = $37       ; Crash/Air/Wood Man — bird spawn point
ENTITY_PIPI         = $38       ; flying bird
ENTITY_PIPI_EGG     = $3A       ; falling egg
ENTITY_EGG_HATCH    = $3B       ; Pipi egg hatch / boss explosion flash (shared type)
ENTITY_COPIPI       = $3C       ; Copipi from egg / boss explosion debris (shared type)
ENTITY_TELLY_SPAWN  = $21       ; Telly spawn point
ENTITY_TELLY        = $22       ; Telly body
; Boss projectiles
ENTITY_METAL_BLADE  = $15       ; Metal Man blade projectile
ENTITY_QUICK_BOOM   = $18       ; Quick Man boomerang projectile
ENTITY_AIR_TORNADO1 = $19       ; Air Man tornado / Heat Man fire (shared type)
ENTITY_AIR_TORNADO2 = $1A       ; Air Man tornado (secondary)
ENTITY_ATOMIC_FIRE  = $1B       ; Heat Man fire projectile
ENTITY_MECHA_FIRE   = $33       ; Mecha Dragon fireball
ENTITY_ALIEN_ORB    = $45       ; Alien Wily orb
ENTITY_ALIEN_SHOT   = $44       ; Alien Wily shot
ENTITY_JOE_BULLET_A = $49       ; Sniper Joe bullet (type A)
ENTITY_JOE_BULLET_B = $48       ; Sniper Joe bullet (type B)
; Pickups
ENTITY_LARGE_HEALTH = $76       ; Large health pickup
ENTITY_SMALL_HEALTH = $77       ; Small health pickup
ENTITY_LARGE_WEAPON = $78       ; Large weapon energy
ENTITY_SMALL_WEAPON = $79       ; Small weapon energy
ENTITY_ETANK        = $7A       ; E-Tank
ENTITY_EXTRA_LIFE   = $7B       ; Extra life (1-UP)
; Mechanics
ENTITY_BOSS_DOOR    = $2F       ; Boss room door
ENTITY_BOSS_DEATH   = $0F       ; Boss death effect (entity converted on death)
ENTITY_STAGE_TRANS  = $09       ; Horizontal stage transition
ENTITY_RAIL_PLAT    = $12       ; Moving platform on rail
ENTITY_CRUMBLE      = $13       ; Crumble block (falls when stepped on)
ENTITY_CRASH_WALL   = $57       ; Destructible wall (Crash Bomber)

; ─── Fixed bank entry points ─────────────────────────────────────────────────
; These are called by all banks via the fixed bank
BANK_SWITCH         = $C000     ; PRG bank switch (A = bank number)
; BANK_ENQUEUE      = $C051     ; Enqueue a bank switch request
; BANKED_ENTRY      = $8000     ; Standard entry point in switched bank
; BANKED_ENTRY_ALT  = $8003     ; Alternate entry point in switched bank
