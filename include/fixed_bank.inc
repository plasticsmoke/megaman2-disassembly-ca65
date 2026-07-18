; =============================================================================
; Mega Man 2 — Fixed Bank ($0F) External Declarations
; =============================================================================
; Routines in the fixed bank ($C000-$FFFF) called from multiple switchable banks.
; Included by banks 0B, 0D, and 0E to avoid duplicated := declarations.

; ─── Sound ──────────────────────────────────────────────────────────────────
sound_queue_push           = $C051   ; A = SFX/music ID; drained by bank $0C sound engine

; ─── Player death ───────────────────────────────────────────────────────────
player_death_sequence           = $C10B

; ─── Math routines ──────────────────────────────────────────────────────────
divide_8bit                   = $C84E
divide_16bit                  = $C874

; ─── Scroll / metatile rendering ────────────────────────────────────────────
metatile_render               = $C8EF
metatile_column_render        = $CA0B
scroll_column_render          = $CB0C

; ─── PPU helpers ────────────────────────────────────────────────────────────
ppu_buffer_transfer           = $D11B

; ─── Weapon system ──────────────────────────────────────────────────────────
weapon_palette_copy           = $D2ED
weapon_spawn_projectile       = $D3E0
