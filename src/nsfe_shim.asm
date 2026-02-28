; =============================================================================
; NSFe Shim — Mega Man 2 NSF Init/Play Driver
; =============================================================================
; Bridges the NSFe container to the bank $0C sound engine.
; Reverse-engineered from the 336-byte shim at $C000-$C14F in mm2.nsf,
; rewritten as clean labeled ca65 assembly.
;
; Bank $0C entry points used by this shim:
;   $8000 = JMP sound_update_main    — per-frame sound driver tick
;   $8003 = bank dispatch entry      — A = sound/weapon ID, falls through
;                                      to weapon_select_handler for IDs $00-$EB
;   $8015 = reset path 1             — sound_busy_flag=1, sound_slot_lo=0,
;                                      JMP weapon_secondary_init
;   $8024 = reset path 2             — sound_busy_flag=1, sound_slot_lo=0,
;                                      JMP weapon_clear_display
;
; Sound slot RAM ($0500-$057F) holds per-channel stream state.  The trigger
; routine writes initial channel pointers for sound IDs that need extra setup
; beyond what the weapon_select_handler provides.
; =============================================================================

.segment "NSF_SHIM"

; ─── Engine entry points (bank $0C, $8000-$BFFF) ─────────────────────────────
SOUND_UPDATE        = $8000     ; JMP sound_update_main
SOUND_DISPATCH      = $8003     ; bank dispatch — A = sound/weapon ID
ENGINE_RESET_1      = $8015     ; reset path 1 (weapon_secondary_init)
ENGINE_RESET_2      = $8024     ; reset path 2 (weapon_clear_display)

; ─── RAM addresses used by shim ──────────────────────────────────────────────
NSF_TRIGGER_FLAG    = $040F     ; first-frame trigger flag (0 = not yet triggered)
NSF_SOUND_ID        = $0580     ; current sound ID for trigger dispatch

; =============================================================================
; nsf_init ($C000) — Called once per track selection
; =============================================================================
; Input: A = NSFe track number (0-based)
;
; 1. Reset the sound engine (clear channels, stop all sound)
; 2. Map track number through nsf_track_table → engine sound ID
; 3. Store sound ID for first-frame trigger
; 4. Dispatch through engine's weapon_select_handler to load music data
; =============================================================================
nsf_init:
        pha
        jsr     ENGINE_RESET_2          ; weapon_clear_display — wipe display slots
        jsr     ENGINE_RESET_1          ; weapon_secondary_init — reinit weapon state
        pla
        pha
        tax
        lda     nsf_track_table,x       ; map track# → engine sound ID
        sta     NSF_SOUND_ID            ; save for trigger dispatch
        jsr     SOUND_DISPATCH          ; weapon_select_handler loads music streams
        pla
        nop                             ; (padding — matches original shim layout)
        nop
        nop
        rts

        .res    8                       ; pad to $C020 (nsf_init = 24 bytes)

; =============================================================================
; nsf_play ($C020) — Called once per frame by NSF player
; =============================================================================
; 1. Tick the sound engine (process all channels)
; 2. On first frame, trigger per-track channel init
; =============================================================================
nsf_play:
        jsr     SOUND_UPDATE            ; sound_update_main — per-frame driver tick
        jsr     nsf_trigger             ; first-frame channel setup (if needed)
        rts

; =============================================================================
; nsf_trigger ($C040) — First-frame channel initialization
; =============================================================================
; Some sound IDs need extra channel pointer writes after the first
; sound_update_main tick.  This runs once (flag-gated) and dispatches
; to per-ID init blocks that write stream pointers into sound slot RAM.
;
; Sound ID groups:
;   $00-$02,$04-$09 → channel_init_standard (most stage music)
;   $03             → channel_init_03       (Password — extra DPCM setup)
;   $0B             → channel_init_0b       (Wily 3-5 — minimal setup)
;   $0A             → loops to nsf_play     (Wily Map — no extra init needed)
;   all others      → no extra init (RTS)
; =============================================================================
nsf_trigger:
        lda     NSF_TRIGGER_FLAG
        beq     @do_trigger             ; first frame: flag is 0
        rts                             ; already triggered: skip
@do_trigger:
        inc     NSF_TRIGGER_FLAG        ; set flag so we only run once
        lda     NSF_SOUND_ID
        nop                             ; (padding — matches original layout)
        nop
        nop
        nop
        cmp     #$00
        beq     channel_init_standard
        cmp     #$01
        beq     channel_init_standard
        cmp     #$02
        beq     channel_init_standard
        cmp     #$04
        beq     channel_init_standard
        cmp     #$05
        beq     channel_init_standard
        cmp     #$06
        beq     channel_init_standard
        cmp     #$07
        beq     channel_init_standard
        cmp     #$08
        beq     channel_init_standard
        cmp     #$09
        beq     channel_init_standard
        cmp     #$03
        beq     channel_init_03
        cmp     #$0B
        beq     channel_init_0b
        cmp     #$0A
        beq     nsf_play                ; sound $0A: extra update tick, no channel init
        rts                             ; all other IDs: no extra init needed

; =============================================================================
; Channel init blocks — write stream pointers to sound slot RAM
; =============================================================================
; These set initial channel state that the weapon_select_handler doesn't
; fully configure.  Addresses are raw sound slot offsets ($0500-$057F).
; =============================================================================

; ─── Standard music init (IDs $00-$02, $04-$09) ─────────────────────────────
; Most stage themes and jingles.
channel_init_standard:
        lda     #$0D
        sta     $0530
        lda     #$FF
        sta     $0532
        lda     #$80
        sta     $0535
        sta     $0573
        rts

; ─── Password music init (ID $03) ────────────────────────────────────────────
; Extra channel pointers for DPCM and noise channels.
channel_init_03:
        lda     #$0D
        sta     $0530
        lda     #$FF
        sta     $0532
        lda     #$0F
        sta     $0533
        sta     $0571
        lda     #$A3
        sta     $0534
        sta     $0572
        lda     #$96
        sta     $0535
        sta     $0573
        lda     #$CF
        sta     $0536
        rts

; ─── Wily 3-5 init (ID $0B) ──────────────────────────────────────────────────
channel_init_0b:
        lda     #$80
        sta     $0535
        rts

; =============================================================================
; Track-to-sound-ID mapping table
; =============================================================================
; Maps NSFe track number (0-based index) to bank $0C engine sound ID.
; 24 entries matching the original mm2.nsf track order.
; =============================================================================
nsf_track_table:
        .byte   $0E                     ;  0: Opening
        .byte   $0D                     ;  1: Title Screen
        .byte   $00                     ;  2: Password
        .byte   $01                     ;  3: Stage Select
        .byte   $02                     ;  4: Game Start
        .byte   $03                     ;  5: Metal Man Stage
        .byte   $04                     ;  6: Air Man Stage
        .byte   $05                     ;  7: Bubble Man Stage
        .byte   $06                     ;  8: Quick Man Stage
        .byte   $07                     ;  9: Crash Man Stage
        .byte   $08                     ; 10: Flash Man Stage
        .byte   $09                     ; 11: Heat Man Stage
        .byte   $17                     ; 12: Wood Man Stage
        .byte   $10                     ; 13: Stage Clear
        .byte   $0C                     ; 14: Get Weapon
        .byte   $0A                     ; 15: Dr. Wily Map
        .byte   $11                     ; 16: Dr. Wily Stage 1-2
        .byte   $0B                     ; 17: Dr. Wily Stage 3-5
        .byte   $15                     ; 18: Boss Battle
        .byte   $0F                     ; 19: Game Over
        .byte   $16                     ; 20: Ending
        .byte   $13                     ; 21: Credits
        .byte   $0D                     ; 22: All Clear
        .byte   $14                     ; 23: Dr. Wily UFO
