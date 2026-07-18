.segment "BANK0C"

; =============================================================================
; Bank $0C — Sound Engine
; Complete sound driver + all music/SFX data (fully self-contained).
; Entry points: $8000 = per-frame update (4 APU channels), $8003 = command
; dispatch (play sound ID / speed / fade / SFX-off / music-off).
; Music and SFX play concurrently: an SFX claims channels via priority +
; channel mask; music state keeps advancing silently on claimed channels and
; resumes output when the SFX releases them.
; =============================================================================

        .setcpu "6502"

.include "include/hardware.inc"
.include "include/ram.inc"
.include "include/zeropage.inc"
.include "include/constants.inc"

sound_temp      := $00F4

; ─── Sound slot field offsets (31-byte per-channel structure) ──────────────
SND_PTN_PTR_LO       = $00    ; music pattern read pointer low (0 = channel off)
SND_PTN_PTR_HI       = $01    ; music pattern read pointer high
SND_NOTE_DUR_LO   = $02    ; note duration counter low
SND_NOTE_DUR_HI   = $03    ; note duration counter high
SND_PERIOD        = $04    ; tempo — note length multiplier
SND_FLAGS         = $05    ; bit7 = speed-up flag, bits 0-6 = last pattern-jump ID
SND_VOL_ENV       = $06    ; volume/sweep envelope byte
SND_FREQ_TBL_LO   = $07    ; frequency table pointer low
SND_FREQ_TBL_HI   = $08    ; frequency table pointer high
SND_NOISE_PER     = $09    ; noise channel period
SND_TARGET_LO     = $0A    ; target/portamento freq low
SND_TARGET_HI     = $0B    ; target/portamento freq high
SND_DUTY_CMD      = $0C    ; duty cycle / command byte
SND_PORTA_RATE    = $0D    ; portamento rate (signed)
SND_PORTA_ACC     = $0E    ; portamento accumulator
SND_PORTA_DIR     = $0F    ; portamento direction/params
SND_APU_OUT       = $10    ; APU output register shadow
SND_STREAM_LO     = $11    ; SFX note value low (from stream note event)
SND_STREAM_HI     = $12    ; SFX note value high (nonzero = SFX note active)
SND_DUTY_VOL      = $13    ; duty/volume register
SND_VIB_AMP       = $14    ; vibrato amplitude
SND_VIB_PHASE     = $15    ; vibrato phase accumulator
SND_SWEEP_CTRL    = $16    ; sweep control (bit7=active)
SND_SWEEP_DELTA   = $17    ; sweep pitch delta (signed)
SND_VIB_CTR       = $18    ; vibrato period counter
SND_VIB_DIR       = $19    ; vibrato direction flag
SND_FREQ_ACC_LO   = $1A    ; frequency accumulator low
SND_FREQ_ACC_HI   = $1B    ; frequency accumulator high
SND_PREV_FREQ     = $1C    ; previous frequency (for delta calc)
SND_SWEEP_CTR     = $1D    ; sweep timing counter
SND_SWEEP_ACC     = $1E    ; sweep accumulator
        jmp     sound_update_main       ; entry 0: per-frame sound update

; ─── Bank entry dispatch — A = command code on entry ───
; $00-$FB: sound ID → sound_play_cmd (music $00-$17, SFX $21-$42)
; $FC: set playback speed (Y+1 note ticks/frame) → sound_cmd_speed
; $FD: start music fade-out (Y = $A0 fade params) → sound_cmd_fade
; $FE: cancel SFX, return channels to music → sound_cmd_sfx_off
; $FF: stop music (SFX unaffected) → sound_cmd_music_off
        cmp     #$FC
        bne     :+
        jmp     sound_cmd_speed
:       cmp     #$FD
        bne     sound_cmd_check_fe
        jmp     sound_cmd_fade

sound_cmd_check_fe:  cmp     #$FE
        bne     sound_cmd_check_ff
        lda     #$01
        sta     sound_busy_flag         ; lock sound engine during init
        lda     #$00
        sta     sound_slot_lo
        jmp     sound_cmd_sfx_off

sound_cmd_check_ff:  cmp     #$FF
        bne     sound_play_cmd
        lda     #$01
        sta     sound_busy_flag
        lda     #$00
        sta     sound_slot_lo
        jmp     sound_cmd_music_off


; =============================================================================
; sound_play_cmd — Play Sound — load music track or SFX by ID
; A = sound ID → header via sound_header_ptr_lo/hi. Header byte 0 = priority:
;   lo nybble ≠ 0 → MUSIC (all tracks use $0F): 4 × 2-byte pattern pointer
;     (sq1,sq2,tri,noise) → each channel's pattern read ptr, then a 2-byte
;     instrument table pointer → sound_data_ptr.
;   lo nybble = 0 → SFX: hi nybble = priority (new must be ≥ current),
;     byte 1 lo nybble = channel mask, stream data starts at byte 2.
; sound_priority holds both current priorities (lo=music, hi=SFX).
; =============================================================================
sound_play_cmd:  asl     a       ; A = sound ID → X = table offset (×2)
        tax
        lda     sound_header_ptr_lo,x    ; load sound header pointer
        sta     sound_header_lo
        lda     sound_header_ptr_hi,x
        sta     sound_header_hi
        ldy     #$00
        lda     (sound_header_lo),y      ; byte 0: priority (music=lo, SFX=hi nybble)
        tax
        and     #$0F                    ; lo nybble ≠ 0 → music, = 0 → SFX
        beq     sfx_load_check
        lda     sound_priority
        and     #$0F
        sta     sound_count
        cpx     sound_count
        bcs     music_load
        rts

music_load:  stx     sound_count   ; adopt new music priority
        lda     sound_priority
        and     #$F0
        ora     sound_count
        sta     sound_priority
        lda     #$01
        sta     sound_busy_flag
        lda     #$00
        sta     sound_slot_lo
        lda     #$00
        sta     sound_speed
        sta     music_fade_ctrl
        lda     #$04
        sta     sound_count
        lda     #$01
music_advance_hdr:  clc              ; advance header ptr by A to next pattern pointer
        adc     sound_header_lo
        sta     sound_header_lo
        lda     #$00
        adc     sound_header_hi
        sta     sound_header_hi
        ldx     sound_slot_lo           ; X = channel slot base offset
        ldy     #$00
music_copy_ptr:  lda     (sound_header_lo),y ; pattern ptr → slot pattern read ptr ($00/$01)
        sta     sound_channel_ram,x
        inx
        iny
        cpy     #$02
music_copy_ptr_end:  bne     music_copy_ptr
        ldy     #$0E                    ; clear remaining 14 slot fields ($02-$0F)
        lda     #$00
music_clear_byte:  sta     sound_channel_ram,x
        inx
music_clear_loop:  dey
        bne     music_clear_byte
        lda     sfx_channel_mask     ; channel owned by an SFX?
        lsr     a
        bcs     music_next_channel ; yes — leave its modulation state
        jsr     sound_slot_clear_mod ; no — clear modulation fields too
music_next_channel:  jsr     sound_next_slot
music_dec_count:  dec     sound_count
        beq     music_set_instr_ptr
        lda     #$02
        jmp     music_advance_hdr

music_set_instr_ptr:  ldy     #$02 ; header bytes 9-10 (ptr already +7):
        lda     (sound_header_lo),y           ;   instrument table pointer
        sta     sound_data_ptr_lo
        iny
        lda     (sound_header_lo),y
        sta     sound_data_ptr_hi
        jsr     sfx_mask_restore
        lda     #$00
        sta     sound_busy_flag
        rts

sfx_load_check:  lda     sound_priority  ; SFX: check priority (hi nybble)
        and     #$F0
        sta     sound_count
        cpx     sound_count
        bcs     sfx_load
        rts

sfx_load:  stx     sound_count   ; adopt new SFX priority
        lda     sound_priority
        and     #$0F
        ora     sound_count
        sta     sound_priority
        lda     #$01
        sta     sound_busy_flag
        lda     #$00
        sta     sound_slot_lo
        ldx     #$00
        lda     #$02
        clc
        adc     sound_header_lo          ; SFX stream = header + 2
        sta     sound_stream_lo
        txa
        adc     sound_header_hi
        sta     sound_stream_hi
        stx     sfx_wait_timer         ; clear stream hold timer
        stx     sfx_loop_flag      ; clear conditional-jump flag
        ldy     #$01
        lda     (sound_header_lo),y      ; byte 1 lo nybble = channel mask
        and     #$0F
        tax
        ora     sfx_channel_mask     ; old mask | new mask → stack
        pha
        stx     sfx_channel_mask     ; new SFX channel mask
        lda     #$04
        sta     sound_count
        lda     #$02
        sta     sound_offset
sfx_channel_loop:  pla            ; channel touched by old or new SFX?
        lsr     a
        pha
        bcc     sfx_next_channel
        jsr     sound_slot_clear_mod ; clear its modulation state
        lda     sfx_channel_mask     ; still owned by the new SFX?
        lsr     a
        bcs     sfx_next_channel
        jsr     sound_channel_restore ; released — hand back to music
sfx_next_channel:  jsr     sound_next_slot
        lda     #$04
        clc
        adc     sound_offset
        sta     sound_offset
        dec     sound_count
        bne     sfx_channel_loop
        jsr     sfx_mask_restore
        lda     sfx_channel_mask     ; working copy for per-frame update
        sta     channel_active_flags
        pla
        lda     #$00
        sta     sound_busy_flag
        rts

; ─── cmd $FC: set playback speed — note ticks/frame = Y+1 (no in-game callers) ───
sound_cmd_speed:
        iny
        sty     sound_speed
        rts


; =============================================================================
; sound_cmd_fade — Music Fade-Out ($FD)
; Y = fade params: bit7 = fade-out active/looping, bits 0-6 = frame period.
; Only caller passes Y=$A0 (bank0F NMI queue): fade step every $20 frames.
; Queued by bank0D as Mega Man lands on a Wily map stage marker.
; =============================================================================
sound_cmd_fade:  sty     music_fade_ctrl        ; start music fade
        lda     #$01
        sta     music_fade_level
        lda     sound_frame_counter
        and     #$01
        sta     sound_frame_counter
        rts


; =============================================================================
; sound_cmd_sfx_off — Cancel SFX ($FE) — release SFX priority + channels ($813A)
; Queued by bank0E after screen transitions (paired with silent SFX $34 at
; transition start). Music channels resume via sound_channel_restore.
; =============================================================================
sound_cmd_sfx_off:  lda     sound_priority
        and     #$0F
        sta     sound_priority
        lda     #$04
        sta     sound_count
        lda     #$02
        sta     sound_offset
sfx_off_loop:  lda     sfx_channel_mask
        lsr     a
        bcc     sfx_off_advance
        jsr     sound_slot_clear_mod
        jsr     sound_channel_restore
sfx_off_advance:  jsr     sound_next_slot
        lda     #$04
        clc
        adc     sound_offset
        sta     sound_offset
        dec     sound_count
        bne     sfx_off_loop
        lda     #$00
        sta     sfx_channel_mask
        sta     channel_active_flags
        lda     #$00
        sta     sound_busy_flag
        rts


; =============================================================================
; sound_channel_restore — Restore Channel — return a channel to music ($816C)
; If the slot has a target/current note pending, reload its music instrument
; (sound_instr_load_abs); otherwise silence the APU channel.
; =============================================================================
sound_channel_restore:  lda     sound_slot_lo
        clc
        adc     #$0A
        tax
        lda     sound_channel_ram,x
        ora     sound_channel_ram + $01,x
        bne     sound_instr_load_abs
        ldy     sound_count
        ldx     sound_offset
        jsr     apu_sound_control
        ldx     sound_slot_lo
        lda     sound_channel_ram,x
        ora     sound_channel_ram + $01,x
        bne     sound_instr_load_abs
        rts


; =============================================================================
; sound_cmd_music_off — Stop Music ($FF) — zero pattern ptrs, release music priority ($818C)
; =============================================================================
sound_cmd_music_off:  lda     sound_priority       ; release music priority (lo)
        and     #$F0
        sta     sound_priority
        lda     #$00
        sta     sound_speed
        sta     music_fade_ctrl
        lda     #$04
        sta     sound_count
music_off_loop:  lda     #$00
        ldx     sound_slot_lo
        sta     sound_channel_ram,x
        sta     sound_channel_ram + $01,x
        jsr     sound_next_slot_norot
        dec     sound_count
        bne     music_off_loop
        lda     #$00
        sta     sound_busy_flag
        rts


; =============================================================================
; sound_slot_clear_mod — Clear Modulation State — zero slot fields $10-$1E ($81B2)
; =============================================================================
sound_slot_clear_mod:  ldy     #$0F ; clear 15 bytes: slot fields $10-$1E
        lda     #$10
        clc
        adc     sound_slot_lo
        tax
        lda     #$00
slot_clear_mod_loop:  sta     sound_channel_ram,x
        inx
        dey
        bne     slot_clear_mod_loop
        rts


; =============================================================================
; sound_instr_load_abs — Load Instrument (absolute addressing) ($81C4)
; Copies the 4-byte instrument record (vibrato/sweep params) from the music
; instrument table (sound_data_ptr) into slot fields $14-$17. Instrument
; index = slot VOL_ENV field ($06) & $1F. Absolute-addressed twin of
; sound_instrument_load for use while ($EC) points elsewhere.
; =============================================================================
sound_instr_load_abs:  lda     sound_count        ; save loop state (reused as ptr)
        pha
        lda     sound_offset
        pha
        lda     sound_data_ptr_lo       ; set up (sound_count) as source pointer
        sta     sound_count
        lda     sound_data_ptr_hi
        sta     sound_offset
        lda     sound_slot_lo
        clc
        adc     #$06
        tax
        lda     sound_channel_ram,x        ; instrument index = VOL_ENV & $1F
        and     #$1F
        beq     instr_abs_offset_done
        tay                             ; Y = instrument index
        lda     #$00
instr_abs_mul4:  clc         ; compute source offset: index × 4
        adc     #$04
        dey
        bne     instr_abs_mul4
instr_abs_offset_done:  tay            ; Y = source byte offset
        txa
        clc
        adc     #$0E                    ; X = dest offset (slot + $14)
        tax
        lda     #$04                    ; copy 4 bytes
instr_abs_copy_loop:  pha
        lda     (sound_count),y        ; read from sound_data_ptr + offset
        sta     sound_channel_ram,x
        iny
        inx
        pla
        sec
        sbc     #$01
        bne     instr_abs_copy_loop
        pla
        sta     sound_offset
        pla
        sta     sound_count
        rts


; =============================================================================
; sound_next_slot — Next Slot — rotate SFX channel mask, advance slot offset by $1F ($8207)
; =============================================================================
sound_next_slot:  lsr     sfx_channel_mask
        bcc     sound_next_slot_norot
        lda     sfx_channel_mask
        ora     #$80
        sta     sfx_channel_mask
sound_next_slot_norot:  lda     #$1F
        clc
        adc     sound_slot_lo
        sta     sound_slot_lo
        rts

; ─── finish mask rotation: 4 plain shifts return mask to home position ───
sfx_mask_restore:  lsr     sfx_channel_mask
        lsr     sfx_channel_mask
        lsr     sfx_channel_mask
        lsr     sfx_channel_mask
        rts


; =============================================================================
; apu_sound_control — APU Sound Control — silence or enable APU channel pair ($8222)
; =============================================================================
apu_sound_control:  cpy     #$01         ; Y=1: enable channels, else silence
        beq     apu_enable_channels
        lda     #$00
        sta     SQ1_VOL,x
        sta     SQ1_SWEEP,x
        rts

apu_enable_channels:  lda     #$07       ; enable pulse 1+2 + triangle
        sta     SND_CHN
        rts


; =============================================================================
; Sound Engine — Main Update Loop
; Called each frame to process all 4 sound channels and the music fade.
;
; Per-frame processing chain (4 channels: pulse1, pulse2, triangle, noise):
;
;   sound_update_main
;     └─ sound_channel_loop  ──── for each of 4 channels: ──────────────────
;          │
;          ├─ sound_stream_check         stream interpreter (if active)
;          │    ├─ stream_cmd_*          7 stream commands ($00-$06)
;          │    └─ sound_pattern_fetch   when stream loads sub-pattern
;          │
;          ├─ sound_note_process         note duration tick (repeat × tick)
;          │    └─ sound_note_done ───►  sound_pattern_fetch (when note ends)
;          │
;          │  sound_pattern_fetch        pattern byte dispatcher
;          │    ├─ sound_cmd_dispatch    10 pattern sub-commands ($0x range)
;          │    │    └─ pattern_cmd_*    set period/noise/duty/env/note/etc.
;          │    ├─ sound_pattern_set_vol_env  ($2x range: volume envelope)
;          │    ├─ sound_pattern_set_fast     ($3x range: loop flag)
;          │    └─ sound_note_len_calc   ($40+: note event, freq lookup)
;          │
;          ├─ sound_volume_update           volume/portamento processing
;          │    └─ sound_sweep_check_flag
;          │         ├─ sound_sweep_process    bidirectional sweep oscillator
;          │         │    └─ sound_volume_write → APU vol register
;          │         └─ sound_envelope_run     signed frequency envelope
;          │              └─ sound_vibrato_check
;          │                   └─ sound_frequency_calc → APU freq registers
;          │
;          └─ sound_channel_off          silence channel via APU
;     └─ music_fade_tick             music fade-out/in processing
; =============================================================================
sound_update_main:  inc     sound_frame_counter           ; Main sound engine update
        lda     sound_busy_flag         ; busy flag set while loading new song
        beq     sound_init_channels
        rts

sound_init_channels:  ldx     #$00        ; slot pointer ($EC/$ED) → $0500 (channel 0 data)
        ldy     #$05
        stx     sound_slot_lo
        sty     sound_slot_hi           ; each channel slot = $1F bytes
        lda     #$00
        sta     apu_channel_offset      ; APU register base ($4000 + offset)
        lda     #$04
        sta     active_channel_count    ; process 4 channels: sq1, sq2, tri, noise
sound_channel_loop:  lda     #$01        ; increment vibrato phase counter
        ldy     #SND_VIB_CTR
        clc
        adc     ($EC),y
        sta     ($EC),y
        lda     #$01                    ; increment sweep phase counter
        ldy     #SND_SWEEP_CTR
        clc
        adc     ($EC),y
        sta     ($EC),y
        lda     channel_active_flags    ; bit 0 = current channel has stream data
        lsr     a
        bcc     sound_check_pause       ; no stream → skip to pause check
        jsr     sound_stream_check      ; process stream commands for this channel
sound_check_pause:  lda     sound_pause_flag
        lsr     a                       ; bit 0 = sound paused (e.g. weapon select)
        bcc     sound_check_active
        jmp     sound_channel_silent    ; paused → silence channel

sound_check_active:  ldy     #SND_PTN_PTR_LO ; pattern read ptr nonzero = active
        lda     ($EC),y
        iny
        ora     ($EC),y                 ; freq_lo OR freq_hi
        beq     sound_channel_silent    ; zero frequency → channel is silent
        lda     #$01                    ; increment portamento accumulator
        ldy     #SND_PORTA_ACC          ; (drives pitch slide timing)
        clc
        adc     ($EC),y
        sta     ($EC),y
        jsr     sound_note_process      ; apply vibrato/sweep/envelope → APU regs
        jmp     sound_shift_active_flags

sound_channel_silent:  lda     channel_active_flags
        lsr     a                       ; bit 0 = channel has stream (already shifted once)
        bcs     sound_shift_active_flags ; has stream → don't write silence
        ldx     apu_channel_offset      ; no stream + no note → write silence to APU
        inx                             ; +2 → point to freq_lo register
        inx
        ldy     active_channel_count
        jsr     apu_sound_control       ; zero the APU freq register
sound_shift_active_flags:  lsr     channel_active_flags ; consume bit for current channel
        bcc     sound_next_channel
        lda     channel_active_flags    ; carry set → next bit was 1, restore it
        ora     #$80                    ; into bit 7 (right-rotating through 8 bits)
        sta     channel_active_flags
sound_next_channel:  dec     active_channel_count
        beq     music_fade_tick     ; all 4 channels done → post-processing
        lda     #$04                    ; advance APU offset to next channel (+4 regs)
        clc
        adc     apu_channel_offset
        sta     apu_channel_offset
        lda     #$1F                    ; advance slot pointer by $1F bytes
        clc
        adc     sound_slot_lo
        sta     sound_slot_lo
        lda     #$00
        adc     sound_slot_hi
        sta     sound_slot_hi
        jmp     sound_channel_loop

music_fade_tick:  lda     music_fade_ctrl          ; music fade processing
        and     #$7F                    ; bits 0-6 = fade frame period
        beq     sfx_wait_tick      ; zero → no fade active
        cmp     sound_frame_counter     ; fade step due this frame?
        bne     sfx_wait_tick
        lda     sound_frame_counter     ; toggle frame counter to bit 0 only
        and     #$01                    ; creates alternating 0/1 pattern
        sta     sound_frame_counter
        inc     music_fade_level     ; deepen fade one step
        lda     #$10                    ; 16 steps per fade cycle
        cmp     music_fade_level
        bne     sfx_wait_tick
        lda     music_fade_ctrl             ; fade cycle complete
        bmi     music_fade_reset ; bit 7 set → hold faded (loop)
        lda     #$00                    ; bit 7 clear → end fade
        sta     music_fade_ctrl
music_fade_reset:  lda     #$0F
        sta     music_fade_level     ; reset for next cycle (15 → counts to 16)
sfx_wait_tick:  lda     sfx_wait_timer     ; SFX stream hold timer
        beq     sound_final_shift_flags ; already zero → skip
        dec     sfx_wait_timer         ; count down each frame
sound_final_shift_flags:  lsr     channel_active_flags ; shift out remaining 4 consumed bits
        lsr     channel_active_flags    ; (channels used bits 0-3, stream used bits 4-7)
        lsr     channel_active_flags
        lsr     channel_active_flags
        rts


; =============================================================================
; sound_volume_update — Channel Volume, Fade & Portamento Processing ($82EC)
; Computes output volume from DUTY_CMD; while a music fade is active the
; fade level is subtracted (bit7 of music_fade_ctrl: fade-out) or used as a
; rising cap (fade-in). Triangle scales the level ×13. Then portamento.
; =============================================================================
sound_volume_update:  ldy     #SND_DUTY_CMD
        lda     ($EC),y
        ldy     #$02
        cpy     active_channel_count
        beq     sound_vol_store_temp
        and     #$0F
sound_vol_store_temp:  sta     sound_temp
        lda     music_fade_ctrl
        and     #$7F
        beq     sound_vol_porta
        lda     music_fade_level
        ldy     #$02
        cpy     active_channel_count
        bne     sound_vol_fade_dir
        ldx     #$0C
sound_vol_fade_scale:  clc
        adc     music_fade_level
        dex
        bne     sound_vol_fade_scale
sound_vol_fade_dir:  tay
        lda     music_fade_ctrl
        bmi     sound_vol_fade_out_loop
        ldx     #$FF
sound_vol_fade_in_loop:  inx
        cpx     sound_temp
        beq     sound_vol_porta
        dey
        bne     sound_vol_fade_in_loop
        stx     sound_temp
        jmp     sound_vol_porta

sound_vol_fade_out_loop:  dec     sound_temp
        beq     sound_vol_porta
        dey
        bne     sound_vol_fade_out_loop
sound_vol_porta:  lda     #$02
        cmp     active_channel_count
        beq     sound_sweep_check_flag
        ldy     #SND_PORTA_RATE
        lda     ($EC),y
        tax
        and     #$7F
        beq     sound_sweep_check_flag
        iny
        cmp     ($EC),y
        beq     sound_sweep_reset
        iny
        lda     ($EC),y
        and     #$0F
        jmp     sound_vol_clamp

sound_sweep_reset:  lda     #$00
        sta     ($EC),y
        iny
        lda     ($EC),y
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     freq_register_hi
        txa
        bpl     sound_envelope_delta
        lda     #$00
        sec
        sbc     freq_register_hi
        sta     freq_register_hi
sound_envelope_delta:  lda     ($EC),y
        and     #$0F
        clc
        adc     freq_register_hi
        bpl     sound_vol_clamp
        lda     #$00
        jmp     sound_vol_store

sound_vol_clamp:  cmp     sound_temp
        bcc     sound_vol_store
        lda     sound_temp
sound_vol_store:  sta     sound_temp
        lda     ($EC),y
        and     #$F0
        ora     sound_temp
        sta     ($EC),y
; ─── route to sweep or envelope based on channel active flag ───
; freq_register_hi is used as both a slot field selector (AND $7F → Y offset
; for envelope/freq calc) and a processing mode flag (bit7: 0=first pass
; through sweep+envelope, 1=second pass skips sweep). Two-pass processing
; allows each channel to run two independent envelope generators.
sound_sweep_check_flag:  lda     channel_active_flags
        lsr     a
        bcs     sound_sweep_init        ; bit0 set: skip sweep, run envelope only
        lda     #SND_DUTY_CMD           ; bit0 clear: use DUTY_CMD as base offset
        sta     freq_register_hi
        jmp     sound_sweep_process

sound_sweep_init:  lda     #SND_NOISE_PER  ; use NOISE_PER as base offset
        sta     freq_register_hi
        jmp     sound_envelope_run


; =============================================================================
; sound_sweep_process — Sound Sweep Engine — process pitch sweep and envelope for active channel ($838F)
; Bidirectional volume sweep oscillator. SWEEP_ACC bounces between 1 and 15;
; at each boundary, SWEEP_DELTA is negated to reverse direction. The result
; modulates the channel volume written to the APU.
; =============================================================================
sound_sweep_process:  ldy     #SND_SWEEP_CTRL
        lda     ($EC),y
        and     #$7F                    ; sweep period (0 = disabled)
        beq     sound_sweep_next_channel
        ldy     #SND_SWEEP_CTR
        cmp     ($EC),y                 ; has counter reached period?
        beq     sound_sweep_reset_ctr
        jmp     sound_sweep_read

sound_sweep_reset_ctr:  lda     #$00   ; reset counter, apply delta
        sta     ($EC),y
        ldy     #SND_SWEEP_DELTA
        lda     ($EC),y
        ldy     #SND_SWEEP_ACC
        clc
        adc     ($EC),y                 ; acc += delta
        beq     sound_sweep_clamp_low
        bpl     sound_sweep_store
sound_sweep_clamp_low:  lda     #$01   ; clamp to minimum 1
        sta     ($EC),y
        jmp     sound_sweep_negate      ; reverse direction

sound_sweep_store:  sta     ($EC),y
        cmp     #$10
        bcc     sound_sweep_read
        lda     #$0F                    ; clamp to maximum 15
        sta     ($EC),y
sound_sweep_negate:  lda     #$00       ; negate delta: delta = 0 - delta
        ldy     #SND_SWEEP_DELTA
        sec
        sbc     ($EC),y
        sta     ($EC),y
sound_sweep_read:  ldy     #SND_SWEEP_ACC
        lda     ($EC),y
        cmp     sound_temp
        bcs     sound_sweep_next_channel
        sta     sound_temp
sound_sweep_next_channel:  ldy     #$02 ; merge sweep volume with duty cycle
        cpy     active_channel_count
        beq     sound_volume_write      ; triangle: use sweep value directly
        lda     freq_register_hi        ; freq_register_hi AND $7F = slot offset
        and     #$7F                    ;   to SND_DUTY_CMD or SND_NOISE_PER
        tay
        lda     ($EC),y                 ; read duty/envelope upper nybble
        and     #$F0
        ora     sound_temp              ; merge with sweep volume (lower nybble)
        sta     sound_temp
sound_volume_write:  ldx     apu_channel_offset
        lda     sound_temp
        sta     SQ1_VOL,x              ; write volume to APU
        lda     freq_register_hi        ; bit7: 0 = first pass (do sweep_mode_b)
        bpl     sound_sweep_mode_b      ;        1 = second pass (skip to envelope)
        lda     #SND_APU_OUT | $80
        sta     freq_register_hi
        jmp     sound_envelope_run

sound_sweep_mode_b:  lda     #SND_NOISE_PER
        sta     freq_register_hi
; ─── frequency envelope generator ───
; freq_register_hi AND $7F selects the slot field containing a signed 8-bit
; rate. Adds rate to the following 16-bit value (slot[offset+1..+2]), which
; accumulates the pitch envelope delta applied during frequency calculation.
sound_envelope_run:  lda     freq_register_hi
        and     #$7F
        tay                             ; Y = envelope rate field offset
        ldx     #$00
        lda     ($EC),y                 ; rate: 0=skip, >0=positive, <0=negative
        beq     sound_envelope_mode
        bpl     sound_envelope_add
        dex                             ; X=$FF: sign-extend negative rate to hi byte
sound_envelope_add:  iny
        clc
        adc     ($EC),y                 ; slot[offset+1] += rate (lo)
        sta     ($EC),y
        txa
        iny
        adc     ($EC),y                 ; slot[offset+2] += carry + sign (hi)
        sta     ($EC),y
sound_envelope_mode:  lda     freq_register_hi
        bmi     sound_vibrato_check     ; bit7 set = second pass, continue to vibrato
        lda     channel_active_flags
        lsr     a
        bcc     sound_vibrato_check     ; bit0 clear = continue to vibrato
        rts                             ; bit0 set = done (refill mode)

; ─── vibrato modulation ───
; Phase-accumulator vibrato. VIB_AMP[6:0] = period, VIB_PHASE[7:5] = amplitude
; (0-7), VIB_PHASE[4:0] = step count per half-cycle. VIB_DIR[7] = direction
; (0=add, 1=subtract), VIB_DIR[6:0] = step counter. Each step adds/subtracts
; amplitude to FREQ_ACC. When step counter reaches step count, direction toggles.
; VIB_AMP[7] alternates between widening and narrowing the vibrato range.
sound_vibrato_check:  ldy     #SND_VIB_AMP
        lda     ($EC),y
        and     #$7F                    ; vibrato period (0 = disabled)
        bne     sound_vibrato_timer
        jmp     sound_frequency_calc

sound_vibrato_timer:  ldy     #SND_VIB_CTR
        cmp     ($EC),y                 ; has counter reached period?
        beq     sound_vibrato_reset
        jmp     sound_frequency_calc

sound_vibrato_reset:  lda     #$00     ; reset timing counter
        sta     ($EC),y
        tax                             ; X = 0 (sign extension for positive delta)
        ldy     #SND_VIB_PHASE
        lda     ($EC),y
        rol     a                       ; extract bits[7:5] → 3-bit amplitude
        rol     a
        rol     a
        rol     a
        and     #$07
        sta     sound_temp              ; sound_temp = amplitude delta
        ldy     #SND_VIB_DIR
        lda     ($EC),y
        asl     a                       ; bit7 → carry = direction
        bcc     sound_vibrato_apply     ; carry clear = add (positive)
        lda     #$00                    ; carry set = subtract (negative)
        sec
        sbc     sound_temp
        sta     sound_temp              ; sound_temp = -amplitude
        dex                             ; X = $FF (sign extension for negative)
sound_vibrato_apply:  lda     sound_temp ; apply delta to 16-bit freq accumulator
        clc
        ldy     #SND_FREQ_ACC_LO
        adc     ($EC),y
        sta     ($EC),y
        iny
        txa                             ; X = sign extension ($00 or $FF)
        adc     ($EC),y
        sta     ($EC),y
        ldy     #SND_VIB_PHASE          ; step count = VIB_PHASE[4:0]
        lda     ($EC),y
        and     #$1F
        sta     sound_temp
        ldy     #SND_VIB_DIR            ; increment step counter
        lda     ($EC),y
        clc
        adc     #$01
        sta     ($EC),y
        and     #$7F                    ; counter[6:0]
        cmp     sound_temp              ; reached step count?
        bne     sound_frequency_calc    ; no — continue to freq calc
        lda     ($EC),y                 ; yes — reset counter, toggle direction
        and     #$80
        sta     ($EC),y                 ; keep direction bit, zero counter
        ldy     #SND_VIB_AMP
        lda     ($EC),y
        asl     a                       ; bit7 → carry = half-period flag
        bcs     sound_vibrato_toggle    ; set: just clear the flag
        lda     ($EC),y                 ; clear: set flag and flip VIB_DIR direction
        ora     #$80
        sta     ($EC),y
        ldy     #SND_VIB_DIR
        lda     ($EC),y
        bpl     sound_vibrato_neg       ; toggle direction bit7
        and     #$7F
        sta     ($EC),y
        jmp     sound_frequency_calc

sound_vibrato_neg:  ora     #$80
        sta     ($EC),y
        jmp     sound_frequency_calc

sound_vibrato_toggle:  lda     ($EC),y  ; clear VIB_AMP half-period flag
        and     #$7F
        sta     ($EC),y

; =============================================================================
; sound_frequency_calc — Sound Frequency Calculator — compute and write APU frequency registers ($84A9)
; Computes final_freq = base_freq + freq_accumulator, where base_freq is at
; slot[offset+1..+2] and freq_acc holds accumulated envelope + vibrato deltas.
; freq_register_hi AND $7F selects the base offset (SND_DUTY_CMD or SND_NOISE_PER).
; Result is written to APU frequency registers. Noise channel has special handling.
; =============================================================================
sound_frequency_calc:  lda     freq_register_hi
        and     #$7F                    ; extract base slot offset
        sta     freq_register_hi
        inc     freq_register_hi        ; offset+1 = base freq lo field
        ldy     #SND_FREQ_ACC_LO
        lda     ($EC),y
        ldy     freq_register_hi
        clc
        adc     ($EC),y                 ; X = (base_freq_lo + acc_lo)
        tax
        ldy     #SND_FREQ_ACC_HI
        lda     ($EC),y
        inc     freq_register_hi        ; offset+2 = base freq hi field
        ldy     freq_register_hi
        adc     ($EC),y                 ; Y = (base_freq_hi + acc_hi + carry)
        tay
        lda     #$01                    ; noise channel? (channel 1 = noise)
        cmp     active_channel_count
        bne     sound_frequency_write
        lda     #$0F                    ; noise: enable all channels
        sta     SND_CHN
        txa
        and     #$0F                    ; noise period is 4-bit
        tax
        inc     freq_register_hi        ; offset+3 = noise mode flag field
        ldy     freq_register_hi
        lda     ($EC),y
        and     #$80                    ; bit7 = noise mode (short/long)
        sta     sound_temp
        txa
        ora     sound_temp
        tax
        ldy     #$00
sound_frequency_write:  txa             ; write freq lo to APU timer register
        ldx     apu_channel_offset
        inx
        inx
        sta     SQ1_VOL,x              ; APU $4002/$4006/$400A/$400E (freq lo)
        tya                             ; freq hi: only write if changed
        ldy     #SND_PREV_FREQ          ;   (avoids retriggering phase on NES APU)
        cmp     ($EC),y
        bne     sound_frequency_hi
        rts

sound_frequency_hi:  sta     ($EC),y
        ora     #$08
        sta     SQ1_SWEEP,x
        rts


; =============================================================================
; sound_channel_off — Sound Channel Off — disable APU channel if not noise channel ($84FD)
; =============================================================================
sound_channel_off:  ldy     #$01
        cpy     active_channel_count
        bne     sound_silence_pair
        lda     #$07
        sta     SND_CHN
        rts

sound_silence_pair:  lda     #$00
        ldx     apu_channel_offset
        inx
        inx
        sta     SQ1_VOL,x
        sta     SQ1_SWEEP,x
        rts


; =============================================================================
; sound_state_init_slot — Sound State Init Slot — reset envelope/sweep state for sound slot ($8516)
; =============================================================================
sound_state_init_slot:  ldy     #SND_VIB_AMP
        lda     ($EC),y
        and     #$7F
        sta     ($EC),y
        ldy     #SND_SWEEP_CTRL
        lda     ($EC),y
        asl     a
        bcc     sound_state_clear_regs
        ldy     sound_temp
        lda     ($EC),y
        ldx     #$02
        cpx     active_channel_count
        beq     sound_state_store_value
        and     #$0F
sound_state_store_value:  ldy     #SND_SWEEP_ACC
        sta     ($EC),y
sound_state_clear_regs:  ldx     #$06
        lda     #$00
        ldy     #SND_VIB_CTR
sound_state_clear_loop:  sta     ($EC),y
        iny
        dex
        bne     sound_state_clear_loop
        lda     #$FF
        ldy     #SND_PREV_FREQ
        sta     ($EC),y
        rts

; ─── save frequency, reinit slot, restore ───
sound_state_save_restore:  ldy     #SND_PREV_FREQ
        lda     ($EC),y
        pha
        jsr     sound_state_init_slot
        pla
        ldy     #SND_PREV_FREQ
        sta     ($EC),y
        rts


; =============================================================================
; sound_dispatch_table — Sound Dispatch Table — indirect jump via inline pointer table ($8556)
; =============================================================================
sound_dispatch_table:  txa
        asl     a
        tay
        iny
        pla
        sta     sound_temp
        pla
        sta     freq_register_hi
        lda     (sound_temp),y
        tax
        iny
        lda     (sound_temp),y
        sta     freq_register_hi
        stx     sound_temp
        jmp     (sound_temp)


; =============================================================================
; sound_stream_check — SFX Stream Interpreter ($856D)
;
; Reads command bytes from the SFX stream pointer ($F0/$F1). If the hold
; timer (sfx_wait_timer) is nonzero and this channel has an active SFX note
; (SND_STREAM_LO/HI), runs in hold mode — only processes the slot's
; volume/envelope via sound_sweep_process.
;
; Stream byte encoding (read from ($F0)):
;   $00-$06 : stream command — dispatched to one of 7 handlers
;   $80-$FE : note event (low nybble != $0F)
;             bits[2:0] = sub-stream pointer high byte
;             next byte = sub-stream pointer low byte
;             Sets SND_STREAM_LO/HI, reinitializes slot, silences channel
;   $xF     : envelope reload (low nybble = $0F)
;             next byte passed to sound_state_save_restore
;
; Stream commands (handler = byte value):
;   0 = hold output N frames      4 = set stream data pointer (cond. jump)
;   1 = set APU output register   5 = load vibrato/sweep params (4 bytes)
;   2 = set duty cycle bits       6 = end stream / loop back
;   3 = set volume bits
; =============================================================================
sound_stream_check:  lda     sfx_wait_timer
        bne     sound_stream_refill_check
        jmp     sound_stream_fetch

sound_stream_refill_check:  ldy     #SND_STREAM_LO
        lda     ($EC),y
        iny
        ora     ($EC),y
        bne     sound_stream_refill_read
        rts

sound_stream_refill_read:  iny
        lda     ($EC),y
        ldy     #$02
        cpy     active_channel_count
        beq     sound_stream_set_mode
        and     #$0F
sound_stream_set_mode:  sta     sound_temp
        lda     #SND_DUTY_VOL | $80
        sta     freq_register_hi
        jmp     sound_sweep_process

; ─── fetch and dispatch next stream command ───
; Stream byte format:
;   bit 7 clear → command index (dispatch to 7 handlers via table)
;   bit 7 set   → note event; low nibble $0F = envelope reload, else new note
sound_stream_fetch:  jsr     sound_data_read_byte ; fetch next stream byte → A (original), X (copy)
        asl     a                       ; bit 7 → carry
        bcs     sound_stream_cmd_check  ; carry set → note event ($80+)
        jmp     sound_stream_dispatch   ; carry clear → command ($00-$7F)

sound_stream_cmd_check:  txa           ; restore original byte from X
        and     #$0F
        cmp     #$0F                    ; low nibble = $F?
        bne     sound_stream_new_note   ; no → start new note
        jsr     sound_data_read_byte    ; $xF: reload envelope from next byte
        jmp     sound_state_save_restore

sound_stream_new_note:  and     #$07   ; bits 0-2 = note duration index
        sta     sound_temp
        jsr     sound_data_read_byte    ; read stream pointer (pattern address)
        ldy     #SND_STREAM_LO
        sta     ($EC),y                 ; store pattern pointer low
        iny
        lda     sound_temp
        sta     ($EC),y                 ; store pattern pointer high / duration
        lda     #SND_DUTY_VOL
        sta     sound_temp
        jsr     sound_state_init_slot   ; initialize slot registers from SND_DUTY_VOL onward
        jmp     sound_channel_off       ; silence channel before new note starts

sound_stream_dispatch:  jsr     sound_dispatch_table ; 7-entry jump table follows
        .addr   stream_cmd_wait, stream_cmd_set_apu_out
        .addr   stream_cmd_set_duty, stream_cmd_set_volume
        .addr   stream_cmd_set_pointer, stream_cmd_load_vibrato
        .addr   stream_cmd_loop_back
stream_cmd_wait:              ; handler 0: hold output N frames
        jsr     sound_data_read_byte
        sta     sfx_wait_timer
        jmp     sound_stream_fetch

stream_cmd_set_apu_out:                 ; handler 1: set APU output register
        jsr     sound_data_read_byte
        ldy     #SND_APU_OUT
        sta     ($EC),y
        jmp     sound_stream_fetch
stream_cmd_set_duty:                    ; handler 2: set duty cycle bits in SND_DUTY_VOL
        jsr     sound_data_read_byte
        sta     sound_temp              ; param has duty in bits 6-7
        ldy     #SND_DUTY_VOL
        lda     ($EC),y
        and     #$3F                    ; preserve volume (bits 0-5)
        ora     sound_temp              ; merge new duty bits
        jmp     sound_cmd_store_param

stream_cmd_set_volume:                  ; handler 3: set volume bits in SND_DUTY_VOL
        jsr     sound_data_read_byte
        ldy     #$02
        cpy     active_channel_count    ; triangle channel? (count=2)
        beq     sound_cmd_store_param   ; tri has no volume control, store raw
        sta     sound_temp              ; param has volume in bits 0-5
        ldy     #SND_DUTY_VOL
        lda     ($EC),y
        and     #$C0                    ; preserve duty (bits 6-7)
        ora     sound_temp              ; merge new volume bits
sound_cmd_store_param:  ldy     #SND_DUTY_VOL
        sta     ($EC),y
        jmp     sound_stream_fetch

stream_cmd_set_pointer:                 ; handler 4: set stream data pointer
        jsr     sound_data_read_byte    ; read conditional flag byte
        txa
        beq     :+                      ; flag=0 → unconditional load
        cpx     sfx_loop_flag      ; flag matches current? → skip (already loaded)
        beq     sound_stream_skip_update
        inc     sfx_loop_flag      ; first time seeing this flag → proceed
:       jsr     sound_data_read_byte    ; read pointer low byte
        sta     sound_temp
        jsr     sound_data_read_byte    ; read pointer high byte
        sta     sound_stream_hi
        lda     sound_temp
        sta     sound_stream_lo         ; set new stream data pointer
        jmp     sound_stream_fetch

sound_stream_skip_update:
        lda     #$00
        sta     sfx_loop_flag      ; reset flag for next encounter
        lda     #$02                    ; skip 2 bytes (the pointer we're not loading)
        clc
        adc     sound_stream_lo
        sta     sound_stream_lo
        lda     #$00
        adc     sound_stream_hi
        sta     sound_stream_hi
        jmp     sound_stream_fetch

stream_cmd_load_vibrato:                ; handler 5: load 4-byte vibrato/sweep params
        lda     #SND_VIB_AMP            ; copy 4 consecutive bytes from stream
        sta     sound_temp              ; into SND_VIB_AMP..SND_SWEEP_CTR-1
sound_cmd_load_regs:  jsr     sound_data_read_byte
        ldy     sound_temp
        sta     ($EC),y
        inc     sound_temp
        ldy     sound_temp
        cpy     #SND_VIB_CTR            ; loaded all 4 bytes?
        bne     sound_cmd_load_regs
        jmp     sound_stream_fetch

stream_cmd_loop_back:                   ; handler 6: end stream, loop back or stop channel
        lda     sound_stream_lo         ; back up stream pointer by 1
        sec                             ; (re-read the loop command byte)
        sbc     #$01
        sta     sound_stream_lo
        lda     sound_stream_hi
        sbc     #$00
        sta     sound_stream_hi
        lda     sound_priority     ; release SFX priority (hi nybble)
        and     #$0F
        sta     sound_priority
        lda     #$00
        sta     sfx_channel_mask
        lda     channel_active_flags
        and     #$FE
        sta     channel_active_flags
        ldy     #SND_TARGET_LO
        lda     ($EC),y
        iny
        ora     ($EC),y
        bne     sound_cmd_load_instrument
        ldx     apu_channel_offset
        inx
        inx
        ldy     active_channel_count
        jsr     apu_sound_control
        ldy     #SND_PTN_PTR_LO
        lda     ($EC),y
        iny
        ora     ($EC),y
        bne     sound_cmd_load_instrument
        rts

; ─── load instrument and reinit slot ───
sound_cmd_load_instrument:  ldy     #SND_VOL_ENV
        lda     ($EC),y
        and     #$1F
        tax
        jsr     sound_instrument_load
        lda     #SND_DUTY_CMD
        sta     sound_temp
        jmp     sound_state_init_slot


; =============================================================================
; sound_data_read_byte — Sound Data Read Byte — read next byte from ($F0) stream pointer ($86A0)
; =============================================================================
sound_data_read_byte:  ldy     #$00      ; read byte and advance pointer
        lda     ($F0),y
        tax
        lda     #$01
        clc
        adc     sound_stream_lo
        sta     sound_stream_lo
        lda     #$00
        adc     sound_stream_hi
        sta     sound_stream_hi
        txa
        rts


; =============================================================================
; sound_note_process — Sound Note Processing — advance note timing and trigger volume processing ($86B4)
; =============================================================================
sound_note_process:  lda     sound_speed         ; process note with repeat count
        beq     sound_note_tick
sound_note_repeat_loop:  pha
        jsr     sound_note_tick
        pla
        sec
        sbc     #$01
        bne     sound_note_repeat_loop
        rts

; ─── advance note timer one tick ───
sound_note_tick:  ldy     #SND_FLAGS           ; tick note timer, handle double-speed
        lda     ($EC),y
        asl     a
        bcc     sound_note_check_active
        lda     sound_frame_counter
        and     #$01
        beq     sound_note_check_active
        jsr     sound_note_check_active
sound_note_check_active:  ldy     #SND_NOTE_DUR_LO
        lda     ($EC),y
        iny
        ora     ($EC),y
        beq     sound_note_done
        ldx     #$FF
        dey
        lda     ($EC),y
        sec
        sbc     #$04
        sta     ($EC),y
        txa
        iny
        adc     ($EC),y
        sta     ($EC),y
        dey
        ora     ($EC),y
        beq     sound_note_done
        ldy     #SND_TARGET_LO
        lda     ($EC),y
        iny
        ora     ($EC),y
        bne     sound_note_goto_volume
        rts

sound_note_goto_volume:  jmp     sound_volume_update


; =============================================================================
; sound_note_done — Sound Note Done — instrument/pattern fetch after note completes ($86FE)
; =============================================================================
sound_note_done:  ldy     #SND_FLAGS           ; end of note — fetch instrument data
        lda     ($EC),y
        and     #$7F
        sta     ($EC),y

; =============================================================================
; sound_pattern_fetch — Sound Pattern Fetch — read and dispatch instrument pattern commands ($8706)
; =============================================================================
; Pattern byte format (high nibble routing):
;   $0x → command index (dispatch to 10 handlers)
;   $2x → set volume envelope + recurse (bits 0-2 = env index)
;   $3x → set speed-up flag (extra note tick on odd frames)
;   $4x+ → note: bits 4-6 = note length index, bits 0-4 = note index
sound_pattern_fetch:  jsr     sound_stream_read_next ; fetch pattern byte → A (masked), X (raw)
        and     #$F0                    ; isolate high nibble for routing
        bne     sound_pattern_cmd_20    ; non-zero → $2x/$3x/note
        jmp     sound_cmd_dispatch      ; $0x → pattern command dispatch

sound_pattern_cmd_20:  cmp     #$20    ; $2x: volume envelope + recursive fetch
        bne     sound_pattern_cmd_30
        txa
        and     #$07                    ; bits 0-2 = volume envelope index
        pha
        jsr     sound_pattern_fetch     ; recursive: process next pattern byte first
        pla
        jmp     sound_pattern_set_vol_env ; then apply volume envelope

sound_pattern_cmd_30:  cmp     #$30    ; $3x: set speed-up flag
        bne     sound_pattern_note_event
        jmp     sound_pattern_set_fast

sound_pattern_note_event:  txa           ; $4x+: note event
        rol     a                       ; rotate bits 4-6 into low position
        rol     a                       ; (4 rotates left through carry)
        rol     a
        rol     a
        and     #$07                    ; extract 3-bit note length index
        tay
        lda     note_len_table,y ; look up base note length
        jsr     sound_note_len_calc     ; duration = length × tempo
sound_pattern_volume_dec:  ldy     #SND_VOL_ENV
        lda     ($EC),y
        and     #$E0                    ; bits 5-7 = volume countdown
        beq     sound_pattern_lookup_freq ; zero → volume done, look up frequency
        sec
        sbc     #$20                    ; decrement volume countdown (step -1)
        sta     sound_temp
        lda     ($EC),y
        and     #$1F                    ; preserve envelope index (bits 0-4)
        ora     sound_temp              ; merge updated countdown
        sta     ($EC),y
        lda     channel_active_flags
        lsr     a                       ; channel active?
        bcc     sound_pattern_goto_save ; no → save state and return
        rts                             ; yes → return (note still decaying)

sound_pattern_goto_save:  jmp     sound_state_save_restore

sound_pattern_lookup_freq:  txa       ; volume done → resolve note frequency
        and     #$1F                    ; bits 0-4 = note index
        bne     sound_pattern_noise_check
        tax                             ; note 0 = rest (frequency = 0)
        jmp     sound_pattern_store_freq

sound_pattern_noise_check:  ldy     #$01
        cpy     active_channel_count    ; noise channel? (count=1)
        bne     sound_pattern_freq_table
        ldx     #$00                    ; noise: high byte always 0
        jmp     sound_pattern_store_freq

sound_pattern_freq_table:  asl     a   ; note_index * 2 (16-bit table entries)
        ldy     #SND_FREQ_TBL_LO       ; add to channel's frequency table base
        clc
        adc     ($EC),y
        sta     sound_temp              ; → indirect pointer low
        lda     #$00
        iny
        adc     ($EC),y
        sta     freq_register_hi        ; → indirect pointer high
        ldy     #$01                    ; read 16-bit frequency from table
        lda     (sound_temp),y          ; high byte
        tax
        dey
        lda     (sound_temp),y          ; low byte
sound_pattern_store_freq:  ldy     #SND_TARGET_LO ; store target frequency for portamento
        sta     ($EC),y
        iny
        txa
        sta     ($EC),y
        ldy     #SND_PORTA_RATE         ; check if portamento is active
        lda     ($EC),y
        sta     sound_temp
        and     #$7F                    ; mask direction bit
        beq     sound_pattern_check_sweep ; rate=0 → no portamento
        jsr     sound_portamento_init   ; initialize slide toward target
sound_pattern_check_sweep:  lda     channel_active_flags
        lsr     a
        bcc     sound_pattern_init_state
        rts

sound_pattern_init_state:  lda     #SND_DUTY_CMD
        sta     sound_temp
        jsr     sound_state_init_slot
        jmp     sound_channel_off

sound_pattern_set_vol_env:  ror     a
        ror     a
        ror     a
        ror     a
        and     #$E0
        sta     sound_temp
        ldy     #SND_VOL_ENV
        lda     ($EC),y
        and     #$1F
        ora     sound_temp
        sta     ($EC),y
        rts

sound_pattern_set_fast:  lda     #$80
        ldy     #SND_FLAGS
        ora     ($EC),y
        sta     ($EC),y
        jmp     sound_pattern_fetch


; =============================================================================
; sound_cmd_dispatch — Sound Command Dispatch ($87C0)
;
; Executes pattern sub-commands via a 10-entry inline jump table. Called when
; channel_active_flags bit0 is set (channel in active pattern mode). Each
; command reads 1-2 parameter bytes from the stream via sound_stream_read_next.
;
; Pattern commands (X = command index on entry):
;   0 = set tempo      : 1 byte → SND_PERIOD (note length multiplier)
;   1 = set noise      : 1 byte → SND_NOISE_PER (noise channel period)
;   2 = set duty       : 1 byte → SND_DUTY_CMD bits[7:6] (duty cycle select)
;   3 = set envelope   : 1 byte → SND_DUTY_CMD bits[5:0] (envelope type)
;                         triangle channel (ch 2) writes full byte instead
;   4 = pattern jump   : 1-3 bytes — conditional jump within pattern data
;                         byte 1 = jump ID; if it matches the last-taken ID
;                         (SND_FLAGS bits 0-6) skip, else bytes 2-3 → new
;                         pattern read pointer (used for loop alt endings)
;   5 = set freq table : 1 byte → SND_FREQ_TBL_LO/HI (base = $8985)
;                         param * 2 + base → frequency lookup table pointer
;   6 = dotted note    : 1 byte note event with 1.5× length table
;                         top 3 bits = note length index (dotted)
;   7 = set portamento : 2 bytes → SND_PORTA_RATE, SND_PORTA_DIR
;                         bit7 of rate = direction (0=up, 1=down)
;   8 = set sweep env  : 1 byte → SND_VOL_ENV bits[4:0] (sweep index)
;                         then loads 4-byte instrument data if ch not active
;   9 = stop note      : 0 bytes → zero SND_PTN_PTR_LO/HI, silence APU channel
; =============================================================================
sound_cmd_dispatch:  jsr     sound_dispatch_table ; 10-entry jump table follows
        .addr   pattern_cmd_set_period, pattern_cmd_set_noise
        .addr   pattern_cmd_set_duty, pattern_cmd_set_envelope
        .addr   pattern_cmd_jump, pattern_cmd_set_freq_table
        .addr   pattern_cmd_dotted_note, pattern_cmd_set_portamento
        .addr   pattern_cmd_set_sweep, pattern_cmd_stop_note
pattern_cmd_set_period:                 ; cmd 0: set tempo (note length multiplier)
        jsr     sound_stream_read_next
        ldy     #SND_PERIOD
        sta     ($EC),y
        jmp     sound_pattern_fetch
pattern_cmd_set_noise:                  ; cmd 1: set noise channel period
        jsr     sound_stream_read_next
        ldy     #SND_NOISE_PER
        sta     ($EC),y
        jmp     sound_pattern_fetch
pattern_cmd_set_duty:                   ; cmd 2: set duty cycle bits in SND_DUTY_CMD
        jsr     sound_stream_read_next
        sta     sound_temp
        ldy     #SND_DUTY_CMD
        lda     ($EC),y
        and     #$3F
        ora     sound_temp
        jmp     sound_cmd_store_duty
pattern_cmd_set_envelope:               ; cmd 3: set envelope type in SND_DUTY_CMD
        jsr     sound_stream_read_next
        ldy     #$02
        cpy     active_channel_count
        beq     sound_cmd_store_duty
        sta     sound_temp
        ldy     #SND_DUTY_CMD
        lda     ($EC),y
        and     #$C0
        ora     sound_temp
sound_cmd_store_duty:  ldy     #SND_DUTY_CMD
        sta     ($EC),y
        jmp     sound_pattern_fetch

pattern_cmd_jump:                   ; cmd 4: conditional pattern jump
        jsr     sound_stream_read_next  ; param byte = jump ID → X
        txa
        beq     pattern_jump_take ; ID=0 → unconditional jump
        ldy     #SND_FLAGS              ; compare with last-taken jump ID
        lda     ($EC),y
        and     #$7F                    ; (bits 0-6 of SND_FLAGS)
        sta     sound_temp
        cpx     sound_temp              ; same ID as last time?
        beq     pattern_jump_skip     ; yes → don't re-take (loop exit)
        inc     sound_temp              ; no → record new ID, take jump
        lda     ($EC),y
        and     #$80                    ; preserve speed-up flag (bit 7)
        ora     sound_temp
        sta     ($EC),y
pattern_jump_take:
        jsr     sound_stream_read_next  ; read target address low
        pha
        jsr     sound_stream_read_next  ; read target address high
        pla
        ldy     #SND_PTN_PTR_LO
        sta     ($EC),y                 ; pattern read ptr = jump target
        iny
        txa
        sta     ($EC),y
        jmp     sound_pattern_fetch

pattern_jump_skip:  lda     ($EC),y ; jump not taken → reset stored ID
        and     #$80
        sta     ($EC),y                 ; keep only speed-up flag
        ldy     #SND_PTN_PTR_LO            ; skip the 2 target-address bytes
        lda     #$02
        clc
        adc     ($EC),y
        sta     ($EC),y
        iny
        lda     #$00
        adc     ($EC),y
        sta     ($EC),y
        jmp     sound_pattern_fetch

pattern_cmd_set_freq_table:             ; cmd 5: set frequency lookup table pointer
        jsr     sound_stream_read_next  ; param = table index
        ldx     #$85                    ; base address of freq tables = $8985
        ldy     #$89
        stx     sound_temp
        sty     freq_register_hi
        asl     a                       ; index * 2 (each table entry = 2 bytes)
        ldy     #SND_FREQ_TBL_LO
        clc
        adc     sound_temp              ; $85 + index*2 → pointer low
        sta     ($EC),y
        lda     #$00
        adc     freq_register_hi        ; $89 + carry → pointer high
        iny
        sta     ($EC),y
        jmp     sound_pattern_fetch

pattern_cmd_dotted_note:                 ; cmd 6: dotted note (1.5× length)
        jsr     sound_stream_read_next  ; param: top 3 bits = note length index
        rol     a                       ; rotate bits 5-7 into bits 0-2
        rol     a                       ; (4 left rotates through carry)
        rol     a
        rol     a
        and     #$07                    ; isolate 3-bit index
        tay
        lda     note_len_dotted_table,y ; look up dotted note length (1.5×)
        jsr     sound_note_len_calc     ; duration = length × tempo
        jmp     sound_pattern_volume_dec ; continue to volume processing
pattern_cmd_set_portamento:              ; cmd 7: set portamento rate and direction
        jsr     sound_stream_read_next  ; byte 1: rate (bit 7 = direction)
        ldy     #SND_PORTA_RATE
        sta     ($EC),y
        pha
        jsr     sound_stream_read_next  ; byte 2: direction + initial phase
        ldy     #SND_PORTA_DIR
        sta     ($EC),y
        pla
        sta     sound_temp              ; save rate byte for direction check
        and     #$7F                    ; mask direction bit
        beq     sound_cmd_portamento_done ; rate=0 → no portamento
        jsr     sound_portamento_init
sound_cmd_portamento_done:  jmp     sound_pattern_fetch

; ─── initialize portamento pitch slide ───
sound_portamento_init:  lda     #$00  ; reset accumulator
        ldy     #SND_PORTA_ACC
        sta     ($EC),y
        lda     sound_temp              ; check rate bit 7 for direction
        bpl     sound_portamento_dir_up ; bit 7 clear → slide up
        lda     #$0F                    ; bit 7 set → slide down (init=$0F)
        jmp     sound_portamento_store

sound_portamento_dir_up:  lda     #$00 ; slide up (init=$00)
sound_portamento_store:  sta     sound_temp
        ldy     #SND_PORTA_DIR          ; merge direction nibble into low bits
        lda     ($EC),y
        and     #$F0                    ; preserve high nibble (slide target)
        ora     sound_temp              ; set low nibble (0=up, F=down)
        sta     ($EC),y
        rts

pattern_cmd_set_sweep:                  ; cmd 8: set sweep envelope
        jsr     sound_stream_read_next  ; param = sweep index (bits 0-4)
        sta     sound_temp
        ldy     #SND_VOL_ENV
        lda     ($EC),y
        and     #$E0                    ; preserve volume countdown (bits 5-7)
        ora     sound_temp              ; merge new sweep index
        sta     ($EC),y
        lda     channel_active_flags
        lsr     a                       ; channel active?
        bcs     sound_cmd_volume_done   ; yes → skip instrument reload
        jsr     sound_instrument_load   ; no → load instrument data for this sweep
sound_cmd_volume_done:  jmp     sound_pattern_fetch


; =============================================================================
; sound_instrument_load — Load Instrument Data ($88E1)
;
; Copies a 4-byte instrument definition into the current sound slot.
; Instrument data is stored sequentially at (sound_data_ptr), each entry 4 bytes:
;   byte 0 → SND_VIB_AMP   : vibrato amplitude + half-period flag (bit7)
;   byte 1 → SND_VIB_PHASE : vibrato phase (bits[7:5]=amplitude, bits[4:0]=step count)
;   byte 2 → SND_SWEEP_CTRL: sweep control (bit7=enable)
;   byte 3 → SND_SWEEP_DELTA: sweep pitch delta (signed)
; Entry: X = instrument index (0-based)
; =============================================================================
sound_instrument_load:  txa              ; X = instrument index
        beq     sound_instrument_copy
        lda     #$00
sound_instrument_offset:  clc
        adc     #$04
        dex
        bne     sound_instrument_offset
sound_instrument_copy:  clc
        adc     sound_data_ptr_lo
        sta     sound_temp
        lda     #$00
        adc     sound_data_ptr_hi
        sta     freq_register_hi
        ldx     #$00
        ldy     #SND_VIB_AMP
sound_instrument_byte:  lda     (sound_temp,x)
        sta     ($EC),y
        iny
        cpy     #SND_VIB_CTR
        bne     sound_instrument_next
        rts

sound_instrument_next:  lda     #$01
        clc
        adc     sound_temp
        sta     sound_temp
        lda     #$00
        adc     freq_register_hi
        sta     freq_register_hi
        jmp     sound_instrument_byte

pattern_cmd_stop_note:                  ; cmd 9: stop channel (music track end)
        ldy     #SND_PTN_PTR_LO            ; zero pattern read ptr → channel inactive
        lda     #$00
        sta     ($EC),y
        iny
        sta     ($EC),y
        lda     sound_priority     ; release music priority (lo nybble)
        and     #$F0
        sta     sound_priority
        lda     channel_active_flags
        lsr     a                       ; channel active?
        bcc     :+                      ; no → write silence to APU
        rts                             ; yes → just return (will be silenced next frame)
:       ldx     $EB                     ; APU channel offset
        inx                             ; +2 → freq register
        inx
        ldy     active_channel_count
        jmp     apu_sound_control       ; zero the APU freq register


; =============================================================================
; sound_stream_read_next — Sound Stream Read Next — read byte from current sound stream pointer ($8935)
; =============================================================================
sound_stream_read_next:  ldy     #SND_PTN_PTR_LO    ; read byte from ($EC) stream
        lda     ($EC),y
        sta     sound_temp
        iny
        lda     ($EC),y
        sta     freq_register_hi
        dey
        lda     (sound_temp),y
        tax
        lda     #$01
        clc
        adc     sound_temp
        sta     ($EC),y
        lda     #$00
        adc     freq_register_hi
        iny
        sta     ($EC),y
        txa
        rts


; =============================================================================
; sound_note_len_calc — Note Duration Calc — duration = base length × tempo ($8954)
; A = base note length (from note length tables); multiplied by SND_PERIOD
; (tempo) and stored to SND_NOTE_DUR (16-bit, in 1/4-tick units).
; =============================================================================
sound_note_len_calc:  sta     sound_temp      ; multiply note length by tempo
        lda     #SND_PTN_PTR_LO
        sta     freq_register_hi
        ldy     #SND_PERIOD
        lda     ($EC),y
        tay
        lda     #$00
note_len_mul_loop:  clc
        adc     sound_temp
        bcc     note_len_mul_dec
        inc     freq_register_hi
note_len_mul_dec:  dey
        bne     note_len_mul_loop
        ldy     #SND_NOTE_DUR_LO
        sta     ($EC),y
        iny
        lda     freq_register_hi
        sta     ($EC),y
        rts


; =============================================================================
; note_len_table — Sound Data Tables — Note Length & Note Frequency Tables ($8975)
; =============================================================================
note_len_table:  .byte   $00,$00,$02,$04,$08,$10,$20,$40
note_len_dotted_table:  .byte   $00,$00,$03,$06,$0C,$18,$30,$60
note_freq_table:                        ; 128-entry 16-bit note frequency lookup (base pointer $8985)
        .byte   $00,$00,$00,$00
        .byte   $00
        .byte   $00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$F2,$07,$D6,$07
        .byte   $14,$07,$AE,$06,$4E
        .byte   $06,$F3
        .byte   $05,$94
        .byte   $05,$4D
        .byte   $05,$01
        .byte   $05,$BB
        .byte   $04,$75,$04,$36,$04,$F9,$03,$BF
        .byte   $03,$8A,$03,$57,$03,$27,$03,$FA
        .byte   $02,$CF,$02,$A7,$02,$81,$02,$5D
        .byte   $02,$3B,$02,$1A,$02,$FC,$01
        .byte   $E0,$01
        .byte   $C5,$01
        .byte   $AB,$01,$93,$01,$7D,$01,$67,$01
        .byte   $53,$01,$40,$01,$2E,$01,$1D,$01
        .byte   $0D
        .byte   $01,$FE
        .byte   $00
        .byte   $F0,$00,$E2,$00
        .byte   $D5,$00
        .byte   $C9,$00
        .byte   $BE,$00,$B3
        .byte   $00
        .byte   $A9,$00,$A0,$00,$97,$00,$8E,$00
        .byte   $86,$00,$7F,$00,$78,$00,$71,$00
        .byte   $6A,$00,$64,$00,$5F,$00,$59,$00
        .byte   $54,$00,$50,$00,$4B,$00,$47,$00
        .byte   $43,$00,$3F,$00,$3C,$00,$38,$00
        .byte   $35,$00,$32,$00,$2F,$00,$2C,$00
        .byte   $2A,$00,$28,$00,$25,$00,$23,$00
        .byte   $21,$00,$1F,$00,$1E,$00,$1C,$00
        .byte   $1A,$00,$19,$00,$17,$00,$16,$00
        .byte   $15,$00,$14,$00,$12,$00,$11,$00
        .byte   $10,$00,$0F,$00,$0F,$00,$0E,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF

; =============================================================================
; sound_header_ptr_lo — Sound Header Pointer Table — 67 entries, IDs $00-$42 ($8A50)
; Interleaved lo/hi pairs (sound_header_ptr_hi = ptr_lo + 1), read by
; sound_play_cmd. Music IDs $00-$17; IDs $18-$20 are unused slots pointing
; at the Game Over header; SFX IDs $21-$42.
; =============================================================================
sound_header_ptr_lo:
sound_header_ptr_hi = sound_header_ptr_lo + 1
        .addr   music_flash_stage       ; $00 — Flash Man Stage
        .addr   music_wood_stage        ; $01 — Wood Man Stage
        .addr   music_crash_stage       ; $02 — Crash Man Stage
        .addr   music_heat_stage        ; $03 — Heat Man Stage
        .addr   music_air_stage         ; $04 — Air Man Stage
        .addr   music_metal_stage       ; $05 — Metal Man Stage
        .addr   music_quick_stage       ; $06 — Quick Man Stage
        .addr   music_bubble_stage      ; $07 — Bubble Man Stage
        .addr   music_wily_stage1       ; $08 — Dr. Wily Stage 1 (Wily 1-2)
        .addr   music_wily_stage2       ; $09 — Dr. Wily Stage 2 (Wily 3-5)
        .addr   music_stage_intro       ; $0A — Stage Intro
        .addr   music_boss              ; $0B — Boss Battle
        .addr   music_stage_select      ; $0C — Stage Select
        .addr   music_title             ; $0D — Title (also Ending reprise)
        .addr   music_opening           ; $0E — Opening
        .addr   music_game_over         ; $0F — Game Over
        .addr   music_password          ; $10 — Password
        .addr   music_wily_map          ; $11 — Dr. Wily Map
        .addr   music_boss_get          ; $12 — Boss Get scene
        .addr   music_epilogue          ; $13 — Epilogue
        .addr   music_credits           ; $14 — Credits
        .addr   music_stage_clear       ; $15 — Stage Clear
        .addr   music_wily_defeated     ; $16 — Wily Defeated
        .addr   music_weapon_get        ; $17 — Weapon Get
        .addr   music_game_over         ; $18 — (unused slot)
        .addr   music_game_over         ; $19 — (unused slot)
        .addr   music_game_over         ; $1A — (unused slot)
        .addr   music_game_over         ; $1B — (unused slot)
        .addr   music_game_over         ; $1C — (unused slot)
        .addr   music_game_over         ; $1D — (unused slot)
        .addr   music_game_over         ; $1E — (unused slot)
        .addr   music_game_over         ; $1F — (unused slot)
        .addr   music_game_over         ; $20 — (unused slot)
        .addr   sfx_time_stopper        ; $21 — Time Stopper
        .addr   sfx_22_unused           ; $22 — (unused)
        .addr   sfx_metal_blade         ; $23 — Metal Blade
        .addr   sfx_buster              ; $24 — Mega Buster
        .addr   sfx_enemy_shot          ; $25 — Enemy Shot
        .addr   sfx_damage_recoil       ; $26 — Damage Recoil
        .addr   sfx_quick_laser         ; $27 — Quick Man Laser
        .addr   sfx_health_tick         ; $28 — Health/Ammo Refill Tick
        .addr   sfx_landing             ; $29 — Landing
        .addr   sfx_wily_alarm          ; $2A — Wily Alarm
        .addr   sfx_damage_hit          ; $2B — Damage Hit
        .addr   sfx_dragon_fire         ; $2C — Dragon Fire
        .addr   sfx_deflect             ; $2D — Deflect
        .addr   sfx_crash_stick         ; $2E — Crash Bomb Stick
        .addr   sfx_menu_cursor         ; $2F — Menu Cursor
        .addr   sfx_teleport_in         ; $30 — Teleport In
        .addr   sfx_leaf_orbit          ; $31 — Leaf Shield Orbit
        .addr   sfx_32_mute             ; $32 — (silent — mutes ch 1 during scrolls)
        .addr   sfx_33_unused           ; $33 — (unused)
        .addr   sfx_34_mute             ; $34 — (silent — mutes ch 1+3 during screen transitions)
        .addr   sfx_skew1               ; $35 — Skew 1
        .addr   sfx_skew2               ; $36 — Skew 2
        .addr   sfx_skew3               ; $37 — Skew 3
        .addr   sfx_heat_charge         ; $38 — Atomic Fire Charge
        .addr   sfx_enemy_bounce        ; $39 — Enemy Bounce
        .addr   sfx_teleport_out        ; $3A — Teleport Out
        .addr   sfx_splash              ; $3B — Water Splash
        .addr   sfx_block_appear        ; $3C — Block Appear
        .addr   sfx_acid_drip1          ; $3D — Acid Drip 1
        .addr   sfx_acid_drip2          ; $3E — Acid Drip 2
        .addr   sfx_air_shooter         ; $3F — Air Shooter
        .addr   sfx_40_unused           ; $40 — (unused)
        .addr   sfx_death_explode       ; $41 — Death Explosion
        .addr   sfx_extra_life          ; $42 — Extra Life

; =============================================================================
; Music Track Data ($8AD6-$BB21)
; Per track: header (priority $0F, 4 × pattern pointer for sq1/sq2/tri/noise,
; instrument table pointer), followed by its pattern + instrument data.
; =============================================================================

music_flash_stage:                      ; $00 — Flash Man Stage ($8AD6)
        .byte   $0F,$E1,$8A,$F1,$8B,$A9,$8C,$83
        .byte   $8D,$15,$8E,$00,$06,$03,$3D,$07
        .byte   $86,$10,$05,$17,$02,$00,$A5,$68
        .byte   $60,$6C,$60,$06,$8F,$06,$8E,$8A
        .byte   $06,$8D,$06,$8C,$88,$6A,$60,$68
        .byte   $60,$65,$63,$60,$65,$80,$73,$73
        .byte   $73,$74,$80,$73,$73,$73,$74,$06
        .byte   $A0,$73,$73,$73,$74,$60,$78,$60
        .byte   $78,$76,$60,$74,$60,$93,$04,$02
        .byte   $EA,$8A,$A5,$68,$60,$6C,$60,$06
        .byte   $8F,$06,$8E,$8A,$06,$8D,$06,$8C
        .byte   $88,$6A,$60,$68,$60,$65,$63,$60
        .byte   $65,$80,$73,$73,$73,$74,$04,$01
        .byte   $37,$8B,$A0,$76,$76,$60,$76,$60
        .byte   $76,$60,$76,$B8,$A0,$05,$23,$02
        .byte   $40,$03,$3D,$07,$92,$10,$80,$85
        .byte   $8C,$8A,$AC,$8A,$88,$8A,$8C,$80
        .byte   $21,$A5,$08,$01,$A5,$08,$00,$88
        .byte   $87,$80,$87,$80,$87,$85,$83,$21
        .byte   $85,$C5,$80,$85,$88,$8A,$80,$85
        .byte   $8C,$8A,$AC,$8A,$88,$8A,$8C,$80
        .byte   $21,$A5,$08,$01,$A5,$08,$00,$88
        .byte   $87,$80,$87,$80,$88,$8A,$87,$21
        .byte   $85,$21,$A5,$08,$01,$A5,$08,$00
        .byte   $80,$85,$88,$8C,$02,$C0,$07,$A2
        .byte   $10,$21,$CF,$08,$01,$CF,$08,$00
        .byte   $21,$AE,$08,$01,$AE,$08,$00,$21
        .byte   $AD,$08,$01,$AD,$08,$00,$02,$80
        .byte   $88,$06,$A5,$80,$85,$88,$8A,$8B
        .byte   $8C,$8B,$8C,$8A,$88,$85,$83,$02
        .byte   $C0,$21,$CF,$08,$01,$CF,$08,$00
        .byte   $21,$AE,$08,$01,$AE,$08,$00,$21
        .byte   $AD,$08,$01,$AD,$08,$00,$02,$80
        .byte   $88,$06,$A5,$80,$85,$88,$8A,$91
        .byte   $8C,$8C,$8C,$90,$93,$96,$98,$04
        .byte   $00,$4D,$8B,$00,$06,$02,$00,$05
        .byte   $17,$07,$E0,$10,$03,$38,$80,$A5
        .byte   $68,$60,$6C,$60,$06,$8F,$06,$8E
        .byte   $8A,$06,$8D,$06,$8C,$88,$6A,$60
        .byte   $68,$60,$65,$63,$60,$65,$6F,$6F
        .byte   $6F,$71,$80,$6F,$6F,$6F,$71,$A0
        .byte   $80,$6F,$6F,$6F,$71,$60,$74,$60
        .byte   $74,$73,$60,$71,$60,$8F,$04,$02
        .byte   $F7,$8B,$80,$A5,$68,$60,$6C,$60
        .byte   $06,$8F,$06,$8E,$8A,$06,$8D,$06
        .byte   $8C,$88,$6A,$60,$68,$60,$65,$63
        .byte   $60,$65,$6F,$6F,$6F,$71,$80,$6F
        .byte   $6F,$6F,$71,$A0,$73,$73,$60,$73
        .byte   $60,$73,$60,$73,$B4,$A0,$05,$23
        .byte   $03,$37,$68,$6A,$60,$68,$60,$68
        .byte   $6A,$68,$67,$68,$60,$67,$60,$67
        .byte   $68,$67,$63,$65,$60,$65,$60,$63
        .byte   $85,$63,$65,$60,$65,$60,$63,$85
        .byte   $04,$03,$5E,$8C,$02,$C0,$03,$3A
        .byte   $07,$A2,$10,$EC,$CB,$CA,$07,$86
        .byte   $10,$02,$00,$80,$88,$8A,$88,$8C
        .byte   $88,$80,$88,$8A,$88,$8C,$88,$80
        .byte   $88,$87,$88,$04,$01,$82,$8C,$04
        .byte   $00,$5C,$8C,$00,$06,$03,$25,$05
        .byte   $23,$03,$30,$A5,$68,$60,$6C,$60
        .byte   $06,$8F,$06,$8E,$8A,$06,$8D,$06
        .byte   $8C,$88,$6A,$60,$68,$60,$65,$63
        .byte   $60,$85,$60,$85,$65,$60,$85,$65
        .byte   $60,$85,$65,$60,$85,$65,$60,$85
        .byte   $67,$60,$87,$68,$60,$6C,$60,$A3
        .byte   $04,$02,$B1,$8C,$A5,$68,$60,$6C
        .byte   $60,$06,$8F,$06,$8E,$8A,$06,$8D
        .byte   $06,$8C,$88,$6A,$60,$68,$60,$65
        .byte   $63,$60,$85,$60,$85,$65,$60,$85
        .byte   $65,$60,$85,$65,$60,$85,$63,$63
        .byte   $60,$63,$60,$63,$60,$63,$65,$01
        .byte   $10,$78,$78,$67,$66,$65,$64,$63
        .byte   $05,$23,$03,$30,$01,$00,$85,$85
        .byte   $80,$85,$65,$68,$60,$6C,$60,$68
        .byte   $85,$85,$85,$80,$85,$65,$68,$60
        .byte   $6C,$60,$68,$85,$83,$83,$80,$83
        .byte   $63,$67,$60,$6A,$60,$67,$83,$85
        .byte   $85,$80,$85,$65,$68,$60,$6C,$60
        .byte   $68,$85,$04,$01,$16,$8D,$01,$00
        .byte   $05,$23,$68,$60,$88,$68,$60,$88
        .byte   $68,$60,$88,$68,$60,$88,$67,$60
        .byte   $87,$67,$60,$87,$66,$60,$86,$66
        .byte   $60,$86,$80,$85,$87,$85,$88,$85
        .byte   $80,$85,$01,$10,$9B,$9B,$8B,$8B
        .byte   $7D,$7D,$8B,$8A,$8A,$04,$01,$4C
        .byte   $8D,$04,$00,$16,$8D,$00,$06,$07
        .byte   $84,$A0,$03,$3F,$01,$05,$66,$01
        .byte   $00,$07,$82,$60,$03,$36,$64,$64
        .byte   $64,$04,$3B,$85,$8D,$07,$81,$10
        .byte   $03,$39,$01,$12,$66,$66,$60,$66
        .byte   $60,$66,$60,$66,$63,$63,$64,$64
        .byte   $65,$65,$66,$66,$03,$3E,$01,$10
        .byte   $07,$82,$A0,$A4,$07,$84,$60,$06
        .byte   $8D,$07,$82,$A0,$64,$64,$64,$84
        .byte   $07,$84,$60,$AD,$04,$07,$B2,$8D
        .byte   $07,$82,$A0,$84,$84,$04,$02,$CE
        .byte   $8D,$07,$84,$60,$AD,$07,$82,$A0
        .byte   $64,$60,$84,$07,$84,$60,$AD,$04
        .byte   $05,$DB,$8D,$07,$82,$A0,$84,$84
        .byte   $04,$02,$E9,$8D,$07,$84,$60,$AD
        .byte   $07,$82,$A0,$84,$84,$07,$84,$60
        .byte   $AD,$04,$03,$F6,$8D,$07,$84,$A0
        .byte   $03,$38,$83,$83,$84,$84,$65,$65
        .byte   $85,$86,$86,$04,$00,$B2,$8D,$00
        .byte   $00,$80,$00,$02,$62,$80,$00

music_wood_stage:                       ; $01 — Wood Man Stage ($8E1D)
        .byte   $0F,$28,$8E,$E8,$8E,$9D,$8F,$79
        .byte   $90,$C0,$90,$00,$05,$03,$3D,$05
        .byte   $19,$02,$80,$07,$84,$70,$01,$30
        .byte   $AB,$AB,$8B,$8D,$AB,$8B,$8B,$80
        .byte   $AB,$8B,$AB,$04,$01,$35,$8E,$01
        .byte   $00,$02,$C0,$07,$88,$10,$77,$76
        .byte   $75,$74,$73,$72,$71,$70,$6F,$6E
        .byte   $6D,$6C,$6B,$6A,$96,$80,$96,$A0
        .byte   $96,$80,$96,$02,$80,$05,$25,$03
        .byte   $3C,$22,$88,$07,$90,$10,$A8,$08
        .byte   $01,$A8,$08,$00,$88,$87,$80,$88
        .byte   $80,$85,$80,$85,$88,$80,$AC,$21
        .byte   $AA,$08,$01,$AA,$08,$00,$AA,$88
        .byte   $8C,$80,$CA,$8A,$88,$06,$CA,$80
        .byte   $8A,$06,$AC,$AA,$A8,$A7,$87,$88
        .byte   $87,$C5,$8A,$80,$8A,$A0,$8A,$80
        .byte   $8A,$21,$88,$04,$01,$68,$8E,$21
        .byte   $A8,$08,$01,$A8,$08,$00,$88,$87
        .byte   $80,$88,$80,$85,$80,$85,$88,$80
        .byte   $AC,$06,$CA,$80,$88,$A3,$A5,$A7
        .byte   $AA,$21,$AB,$08,$01,$AB,$08,$00
        .byte   $8B,$8A,$80,$8B,$80,$8B,$8B,$80
        .byte   $A8,$AB,$7D,$7C,$7B,$7A,$79,$78
        .byte   $77,$76,$75,$74,$73,$72,$71,$70
        .byte   $8C,$80,$8C,$A0,$8C,$80,$8C,$04
        .byte   $00,$60,$8E,$00,$05,$03,$3A,$05
        .byte   $31,$02,$80,$07,$81,$20,$01,$10
        .byte   $A0,$A8,$04,$07,$F5,$8E,$01,$00
        .byte   $02,$C0,$05,$19,$07,$88,$10,$74
        .byte   $73,$72,$71,$70,$6F,$6E,$6D,$6C
        .byte   $6B,$6A,$69,$68,$67,$93,$80,$93
        .byte   $A0,$93,$80,$93,$07,$92,$20,$05
        .byte   $19,$03,$38,$02,$80,$21,$91,$D1
        .byte   $91,$8F,$80,$91,$80,$8C,$80,$8C
        .byte   $91,$80,$B4,$D2,$B2,$91,$94,$80
        .byte   $D2,$92,$91,$06,$D2,$80,$92,$06
        .byte   $B3,$B3,$AC,$AC,$C0,$93,$94,$93
        .byte   $93,$80,$93,$A0,$93,$80,$93,$04
        .byte   $01,$19,$8F,$80,$05,$25,$03,$38
        .byte   $02,$80,$07,$92,$10,$08,$01,$21
        .byte   $88,$C8,$88,$87,$80,$88,$80,$85
        .byte   $80,$85,$88,$80,$AC,$06,$CA,$80
        .byte   $88,$A3,$A5,$A7,$AA,$CB,$8B,$8A
        .byte   $80,$8B,$80,$8B,$8B,$80,$A8,$8B
        .byte   $08,$00,$07,$88,$10,$03,$3A,$73
        .byte   $72,$71,$70,$6F,$6E,$6D,$6C,$6B
        .byte   $6A,$69,$68,$67,$66,$87,$80,$87
        .byte   $A0,$87,$80,$87,$04,$00,$19,$8F
        .byte   $00,$05,$03,$15,$05,$31,$01,$10
        .byte   $A0,$A7,$04,$05,$A5,$8F,$91,$71
        .byte   $71,$8E,$8E,$8C,$8C,$8A,$8A,$01
        .byte   $00,$05,$25,$71,$70,$6F,$6E,$6D
        .byte   $6C,$6B,$6A,$69,$68,$67,$66,$65
        .byte   $64,$83,$80,$83,$80,$01,$10,$7D
        .byte   $7D,$9D,$9D,$9D,$01,$00,$21,$85
        .byte   $85,$65,$65,$04,$07,$D5,$8F,$86
        .byte   $66,$66,$04,$06,$DC,$8F,$86,$21
        .byte   $83,$83,$63,$63,$04,$02,$E6,$8F
        .byte   $83,$21,$84,$84,$64,$64,$04,$03
        .byte   $F0,$8F,$80,$85,$87,$85,$88,$85
        .byte   $80,$83,$80,$83,$80,$63,$63,$83
        .byte   $80,$83,$21,$85,$85,$65,$65,$04
        .byte   $07,$09,$90,$86,$66,$66,$04,$06
        .byte   $10,$90,$86,$21,$83,$83,$63,$63
        .byte   $04,$02,$1A,$90,$83,$21,$84,$84
        .byte   $64,$64,$04,$03,$24,$90,$80,$85
        .byte   $87,$85,$88,$85,$80,$83,$80,$83
        .byte   $80,$63,$63,$83,$80,$83,$21,$81
        .byte   $81,$61,$61,$81,$81,$04,$03,$3D
        .byte   $90,$83,$63,$63,$83,$83,$04,$03
        .byte   $46,$90,$84,$64,$64,$84,$84,$04
        .byte   $03,$4F,$90,$65,$65,$65,$60,$65
        .byte   $60,$65,$65,$60,$65,$65,$60,$65
        .byte   $65,$84,$80,$84,$80,$01,$10,$7D
        .byte   $7D,$9D,$9D,$9D,$01,$00,$21,$85
        .byte   $04,$00,$D5,$8F,$00,$05,$01,$10
        .byte   $07,$83,$60,$03,$3D,$A0,$AC,$04
        .byte   $07,$82,$90,$07,$83,$60,$01,$FD
        .byte   $65,$04,$03,$8D,$90,$68,$04,$03
        .byte   $92,$90,$6A,$6A,$6A,$6C,$6C,$6C
        .byte   $01,$10,$8C,$80,$8C,$A0,$8C,$80
        .byte   $8C,$8C,$01,$10,$07,$82,$A0,$84
        .byte   $64,$64,$07,$84,$60,$8A,$07,$82
        .byte   $A0,$64,$64,$04,$2B,$A9,$90,$04
        .byte   $00,$88,$90,$00,$00,$80,$00,$02
        .byte   $41,$80,$00

music_crash_stage:                      ; $02 — Crash Man Stage ($90C8)
        .byte   $0F,$D3,$90,$70,$92,$91,$93,$30
        .byte   $94,$7F,$94,$00,$06,$03,$3C,$07
        .byte   $8A,$10,$02,$40,$05,$17,$88,$A0
        .byte   $85,$A6,$87,$60,$68,$60,$68,$68
        .byte   $60,$88,$85,$A6,$87,$88,$88,$A0
        .byte   $85,$A6,$87,$60,$68,$60,$68,$68
        .byte   $60,$88,$85,$86,$05,$23,$74,$60
        .byte   $B4,$05,$17,$88,$A0,$85,$A6,$87
        .byte   $60,$68,$60,$68,$68,$60,$88,$85
        .byte   $05,$23,$74,$74,$60,$74,$76,$77
        .byte   $76,$74,$05,$17,$88,$A0,$85,$A6
        .byte   $A7,$05,$23,$74,$60,$04,$04,$21
        .byte   $91,$60,$74,$76,$77,$76,$74,$07
        .byte   $88,$10,$6F,$A0,$60,$6F,$60,$B2
        .byte   $91,$60,$6F,$60,$6F,$6F,$60,$6F
        .byte   $60,$6F,$60,$B2,$91,$90,$6F,$A0
        .byte   $60,$6F,$60,$B2,$91,$60,$6F,$60
        .byte   $6F,$6F,$60,$6F,$60,$6F,$60,$80
        .byte   $74,$60,$B4,$04,$01,$2F,$91,$07
        .byte   $90,$10,$03,$3D,$02,$80,$8C,$80
        .byte   $8C,$60,$6C,$6C,$60,$6C,$60,$6C
        .byte   $6A,$68,$06,$8A,$A8,$A0,$88,$8A
        .byte   $88,$8C,$80,$8C,$60,$6C,$8D,$8C
        .byte   $80,$22,$AF,$08,$01,$AF,$01,$06
        .byte   $AF,$01,$00,$08,$00,$74,$60,$B4
        .byte   $8F,$80,$8F,$60,$6F,$6F,$60,$6F
        .byte   $60,$6F,$6D,$6C,$06,$8D,$AC,$A0
        .byte   $8C,$8D,$8C,$8F,$80,$8F,$60,$6F
        .byte   $91,$8F,$80,$22,$B2,$08,$01,$B2
        .byte   $01,$06,$B2,$01,$00,$08,$00,$74
        .byte   $60,$B4,$94,$80,$94,$60,$74,$74
        .byte   $60,$74,$60,$74,$71,$6F,$06,$91
        .byte   $AF,$A0,$8F,$91,$8F,$94,$80,$94
        .byte   $60,$74,$96,$94,$80,$21,$B7,$B7
        .byte   $01,$06,$B7,$01,$00,$08,$00,$74
        .byte   $60,$B4,$05,$2F,$8C,$80,$8C,$60
        .byte   $6C,$6C,$60,$6C,$60,$6C,$6A,$68
        .byte   $06,$8A,$A8,$A0,$88,$8A,$88,$8C
        .byte   $80,$8C,$60,$6C,$8D,$8C,$80,$22
        .byte   $AF,$08,$01,$8F,$AF,$08,$00,$68
        .byte   $6C,$6F,$74,$6C,$6F,$74,$78,$05
        .byte   $23,$02,$40,$03,$3C,$6F,$A0,$60
        .byte   $6F,$60,$B2,$91,$60,$6F,$60,$6F
        .byte   $6F,$60,$6F,$60,$6F,$60,$B2,$91
        .byte   $90,$6F,$A0,$60,$6F,$60,$B2,$91
        .byte   $60,$6F,$60,$6F,$6F,$60,$6F,$60
        .byte   $6F,$60,$80,$74,$60,$B4,$04,$01
        .byte   $15,$92,$B1,$91,$60,$71,$91,$AD
        .byte   $91,$21,$AF,$08,$01,$AF,$08,$00
        .byte   $6D,$60,$6D,$60,$6D,$8F,$6F,$04
        .byte   $02,$42,$92,$B1,$91,$60,$71,$91
        .byte   $B4,$91,$6F,$6F,$60,$74,$74,$60
        .byte   $78,$78,$C0,$04,$00,$2F,$91,$09
        .byte   $00,$06,$07,$8A,$10,$02,$40,$03
        .byte   $36,$05,$17,$60,$88,$A0,$85,$A6
        .byte   $87,$60,$68,$60,$68,$68,$60,$88
        .byte   $85,$A6,$87,$88,$88,$A0,$85,$A6
        .byte   $87,$60,$68,$60,$68,$68,$60,$88
        .byte   $85,$66,$7B,$60,$BB,$60,$88,$A0
        .byte   $85,$A6,$87,$60,$68,$60,$68,$68
        .byte   $60,$88,$65,$05,$23,$6F,$6F,$60
        .byte   $6F,$73,$74,$73,$6F,$05,$17,$60
        .byte   $88,$A0,$85,$A6,$87,$60,$05,$23
        .byte   $6F,$60,$04,$04,$C0,$92,$60,$6F
        .byte   $73,$74,$73,$6F,$6C,$A0,$60,$6C
        .byte   $60,$AF,$8D,$60,$6C,$60,$6C,$6C
        .byte   $60,$6C,$60,$6C,$60,$AF,$8D,$8D
        .byte   $6C,$A0,$60,$6C,$60,$AF,$8D,$60
        .byte   $6C,$60,$6C,$6C,$60,$6C,$60,$6C
        .byte   $60,$80,$6F,$60,$AF,$04,$01,$CC
        .byte   $92,$03,$37,$07,$8D,$20,$02,$00
        .byte   $8F,$8C,$8F,$6C,$6F,$60,$94,$60
        .byte   $8F,$6C,$6F,$60,$6F,$8C,$8F,$6C
        .byte   $6F,$60,$74,$6F,$6C,$6F,$6C,$68
        .byte   $63,$8F,$8C,$8F,$6C,$6F,$60,$94
        .byte   $60,$8F,$6C,$6F,$60,$6F,$8C,$8F
        .byte   $6C,$6F,$60,$74,$07,$85,$10,$03
        .byte   $3A,$02,$40,$6F,$60,$AF,$04,$03
        .byte   $F9,$92,$6C,$A0,$60,$6C,$60,$AF
        .byte   $8D,$60,$6C,$60,$6C,$6C,$60,$6C
        .byte   $60,$6C,$60,$AF,$8D,$8D,$6C,$A0
        .byte   $60,$6C,$60,$AF,$8D,$60,$6C,$60
        .byte   $6C,$6C,$60,$6C,$60,$6C,$60,$80
        .byte   $6F,$60,$AF,$04,$01,$3A,$93,$AD
        .byte   $8D,$60,$6D,$8D,$AA,$8D,$21,$AC
        .byte   $AC,$6A,$60,$6A,$60,$6A,$8C,$6C
        .byte   $04,$02,$67,$93,$AD,$8D,$60,$6D
        .byte   $8D,$B1,$8D,$6C,$6C,$60,$6F,$6F
        .byte   $60,$74,$74,$C0,$04,$00,$CC,$92
        .byte   $09,$00,$06,$03,$25,$05,$23,$88
        .byte   $80,$01,$10,$94,$01,$00,$85,$A6
        .byte   $87,$60,$68,$60,$68,$68,$01,$10
        .byte   $74,$94,$01,$00,$85,$86,$92,$87
        .byte   $93,$04,$02,$97,$93,$88,$80,$01
        .byte   $10,$94,$01,$00,$85,$A6,$87,$88
        .byte   $88,$88,$88,$88,$68,$01,$10,$7D
        .byte   $7D,$7D,$7A,$7A,$78,$78,$01,$00
        .byte   $88,$80,$01,$10,$94,$01,$00,$85
        .byte   $A6,$87,$60,$68,$60,$68,$68,$01
        .byte   $10,$74,$94,$01,$00,$85,$86,$92
        .byte   $87,$93,$04,$0F,$CE,$93,$06,$86
        .byte   $06,$8A,$8D,$60,$71,$6D,$6A,$6D
        .byte   $6A,$66,$65,$06,$88,$06,$8C,$8F
        .byte   $66,$60,$66,$60,$66,$88,$68,$04
        .byte   $02,$EE,$93,$06,$86,$06,$8A,$8D
        .byte   $60,$71,$6D,$6A,$6D,$6A,$66,$65
        .byte   $68,$68,$60,$6C,$6C,$60,$6F,$6F
        .byte   $01,$10,$60,$7D,$7D,$7D,$7A,$7A
        .byte   $78,$78,$01,$00,$04,$00,$CE,$93
        .byte   $00,$06,$03,$3A,$07,$83,$F0,$A3
        .byte   $07,$83,$40,$A5,$04,$0D,$34,$94
        .byte   $85,$85,$85,$85,$01,$15,$A0,$A5
        .byte   $A0,$A5,$A0,$A5,$A0,$A5,$A0,$A5
        .byte   $A0,$A5,$A0,$A5,$A0,$A5,$80,$85
        .byte   $A5,$04,$07,$48,$94,$A0,$A5,$A0
        .byte   $A5,$A0,$A5,$85,$85,$65,$65,$60
        .byte   $65,$04,$02,$5D,$94,$A0,$A5,$A0
        .byte   $A5,$63,$63,$60,$64,$64,$60,$65
        .byte   $65,$A0,$A5,$04,$00,$48,$94,$00
        .byte   $00,$80,$00,$01,$62,$80,$00

music_heat_stage:                       ; $03 — Heat Man Stage ($9487)
        .byte   $0F,$92,$94,$64,$95,$1C,$96,$71
        .byte   $96,$98,$96,$00,$06,$02,$00,$03
        .byte   $38,$05,$15,$07,$84,$60,$65,$65
        .byte   $71,$65,$6F,$70,$65,$71,$65,$6C
        .byte   $65,$6B,$65,$6A,$69,$68,$65,$65
        .byte   $6F,$65,$6D,$6E,$65,$6F,$65,$6A
        .byte   $65,$69,$65,$68,$67,$66,$04,$02
        .byte   $9D,$94,$65,$65,$71,$65,$6F,$70
        .byte   $65,$71,$65,$6C,$65,$6B,$65,$6A
        .byte   $69,$68,$6F,$6F,$60,$6C,$71,$71
        .byte   $60,$6C,$6C,$6F,$6C,$71,$A0,$03
        .byte   $3A,$07,$02,$A0,$05,$21,$02,$40
        .byte   $21,$AC,$AC,$6C,$60,$6C,$60,$6C
        .byte   $6A,$68,$21,$AA,$AA,$6A,$6A,$60
        .byte   $6C,$60,$6A,$67,$60,$88,$02,$80
        .byte   $65,$68,$6C,$71,$60,$6C,$60,$6A
        .byte   $6C,$60,$6A,$60,$63,$65,$67,$71
        .byte   $60,$71,$73,$74,$78,$60,$71,$60
        .byte   $6C,$6F,$71,$74,$73,$71,$6F,$02
        .byte   $40,$21,$AC,$AC,$6C,$60,$6C,$60
        .byte   $6C,$6A,$68,$21,$AA,$AA,$6A,$6A
        .byte   $60,$6C,$60,$6A,$67,$60,$88,$02
        .byte   $80,$65,$68,$6C,$71,$60,$6C,$60
        .byte   $6A,$6C,$60,$6A,$60,$63,$65,$67
        .byte   $02,$80,$73,$73,$60,$71,$74,$74
        .byte   $60,$71,$71,$73,$71,$74,$80,$60
        .byte   $05,$15,$02,$00,$07,$84,$60,$21
        .byte   $6C,$04,$00,$94,$94,$00,$06,$07
        .byte   $84,$60,$02,$80,$03,$37,$05,$13
        .byte   $01,$25,$6C,$6C,$9D,$6C,$9D,$6C
        .byte   $60,$7D,$9A,$7D,$7C,$7A,$78,$04
        .byte   $06,$6F,$95,$7D,$7D,$60,$7C,$7C
        .byte   $7C,$60,$7A,$7D,$7C,$7A,$78,$60
        .byte   $7C,$7C,$60,$01,$00,$05,$21,$03
        .byte   $36,$07,$02,$A0,$02,$40,$21,$A8
        .byte   $A8,$68,$60,$68,$60,$68,$67,$65
        .byte   $21,$A7,$A7,$67,$67,$60,$68,$60
        .byte   $67,$63,$60,$85,$02,$80,$03,$36
        .byte   $60,$65,$68,$6C,$71,$60,$6C,$60
        .byte   $6A,$6C,$60,$6A,$60,$63,$65,$67
        .byte   $71,$60,$71,$73,$74,$78,$60,$71
        .byte   $60,$6C,$6F,$71,$74,$73,$71,$02
        .byte   $40,$21,$A8,$A8,$68,$60,$68,$60
        .byte   $68,$67,$65,$21,$A7,$A7,$67,$67
        .byte   $60,$68,$60,$67,$63,$60,$85,$02
        .byte   $80,$60,$03,$36,$65,$68,$6C,$71
        .byte   $60,$6C,$60,$6A,$6C,$60,$6A,$60
        .byte   $63,$65,$03,$3A,$02,$80,$6F,$6F
        .byte   $60,$6C,$71,$71,$60,$6C,$6C,$6F
        .byte   $6C,$71,$A0,$05,$15,$03,$38,$02
        .byte   $40,$04,$00,$66,$95,$00,$06,$03
        .byte   $1A,$05,$21,$65,$65,$71,$65,$6F
        .byte   $70,$65,$71,$65,$6C,$65,$6B,$65
        .byte   $6A,$69,$68,$65,$65,$6F,$65,$6D
        .byte   $6E,$65,$6F,$65,$6A,$65,$69,$65
        .byte   $68,$67,$66,$04,$02,$22,$96,$65
        .byte   $65,$71,$65,$6F,$70,$65,$71,$65
        .byte   $6C,$65,$6B,$65,$6A,$69,$68,$6F
        .byte   $6F,$60,$6C,$71,$71,$60,$6C,$6C
        .byte   $6F,$6C,$71,$01,$10,$60,$7D,$7A
        .byte   $01,$00,$21,$65,$03,$30,$04,$00
        .byte   $22,$96,$00,$06,$03,$3F,$07,$83
        .byte   $A0,$62,$03,$3A,$07,$82,$A0,$62
        .byte   $62,$62,$04,$1B,$73,$96,$07,$83
        .byte   $A0,$6A,$8A,$6A,$6A,$8A,$6A,$6A
        .byte   $6A,$6A,$8A,$6A,$8A,$04,$00,$73
        .byte   $96

music_air_stage:                        ; $04 — Air Man Stage ($9698)
        .byte   $0F,$A3,$96,$CF,$97,$F0,$98,$17
        .byte   $9A,$3A,$9A,$00,$05,$03,$3C,$02
        .byte   $00,$05,$1D,$07,$92,$10,$AC,$8F
        .byte   $AE,$AD,$AC,$AF,$AE,$AD,$80,$21
        .byte   $AC,$08,$01,$AC,$08,$00,$8C,$8A
        .byte   $88,$A7,$88,$8A,$A3,$85,$87,$85
        .byte   $A0,$8F,$AE,$AD,$AC,$AF,$AE,$AD
        .byte   $80,$21,$AC,$08,$01,$AC,$08,$00
        .byte   $8C,$8A,$88,$A7,$88,$8A,$A3,$85
        .byte   $87,$85,$02,$80,$07,$84,$10,$80
        .byte   $85,$87,$85,$88,$85,$8A,$85,$07
        .byte   $90,$10,$02,$C0,$05,$29,$87,$87
        .byte   $87,$87,$87,$87,$80,$05,$1D,$07
        .byte   $92,$10,$21,$B1,$08,$01,$B1,$08
        .byte   $00,$8C,$8F,$91,$80,$91,$80,$B1
        .byte   $8C,$AF,$B0,$06,$B1,$AF,$06,$B1
        .byte   $D8,$91,$B0,$CF,$8A,$8C,$8F,$80
        .byte   $8F,$80,$8F,$8D,$8F,$80,$93,$91
        .byte   $8F,$06,$AF,$AA,$06,$AC,$80,$8F
        .byte   $AF,$8F,$90,$80,$B1,$8F,$8C,$91
        .byte   $93,$91,$94,$96,$05,$29,$6B,$8C
        .byte   $8F,$6C,$6F,$70,$71,$74,$73,$71
        .byte   $6F,$70,$71,$6F,$06,$AC,$06,$AA
        .byte   $A8,$80,$06,$A7,$A5,$A3,$69,$21
        .byte   $6A,$AA,$6E,$21,$6F,$AF,$75,$22
        .byte   $76,$B6,$08,$01,$B6,$08,$00,$B3
        .byte   $92,$91,$8F,$6D,$6C,$6D,$6F,$71
        .byte   $6F,$71,$73,$74,$73,$74,$76,$78
        .byte   $76,$78,$79,$01,$01,$DE,$01,$00
        .byte   $05,$1D,$94,$93,$80,$07,$92,$10
        .byte   $02,$80,$91,$80,$91,$91,$8F,$B1
        .byte   $A0,$91,$80,$91,$8F,$91,$94,$80
        .byte   $98,$80,$21,$B6,$08,$01,$D6,$08
        .byte   $00,$80,$BB,$B9,$B8,$96,$91,$80
        .byte   $91,$91,$8F,$B1,$A0,$91,$80,$91
        .byte   $8F,$91,$94,$80,$98,$80,$21,$B6
        .byte   $96,$96,$93,$80,$22,$B8,$08,$01
        .byte   $B8,$98,$08,$00,$03,$3E,$02,$00
        .byte   $8C,$A8,$8A,$04,$00,$A5,$96,$00
        .byte   $05,$03,$3C,$02,$00,$05,$1D,$07
        .byte   $92,$10,$A8,$8C,$AB,$AA,$A8,$AC
        .byte   $AB,$AA,$80,$C8,$88,$87,$85,$A3
        .byte   $85,$87,$05,$11,$AC,$8C,$8F,$8C
        .byte   $05,$1D,$A0,$8C,$AB,$AA,$A8,$AC
        .byte   $AB,$AA,$80,$C8,$88,$87,$85,$A3
        .byte   $85,$87,$05,$11,$AC,$8C,$8F,$8C
        .byte   $05,$1D,$03,$38,$02,$80,$07,$84
        .byte   $10,$60,$80,$85,$87,$85,$88,$85
        .byte   $8A,$65,$07,$90,$10,$02,$C0,$03
        .byte   $3C,$05,$29,$83,$83,$83,$83,$83
        .byte   $84,$80,$05,$1D,$07,$92,$10,$03
        .byte   $38,$80,$D1,$8C,$8F,$91,$80,$91
        .byte   $80,$B1,$8C,$AF,$B0,$06,$B1,$AF
        .byte   $06,$B1,$D8,$91,$B0,$CF,$8A,$8C
        .byte   $8F,$80,$8F,$80,$8F,$8D,$8F,$80
        .byte   $93,$91,$8F,$06,$AF,$AA,$06,$AC
        .byte   $80,$8F,$8F,$93,$93,$80,$B4,$80
        .byte   $8F,$8C,$91,$93,$91,$94,$96,$05
        .byte   $29,$6B,$8C,$8F,$6C,$6F,$70,$71
        .byte   $74,$73,$71,$6F,$70,$71,$6F,$06
        .byte   $AC,$06,$AA,$A8,$80,$06,$A7,$A5
        .byte   $A3,$69,$21,$6A,$AA,$6E,$21,$6F
        .byte   $AF,$75,$22,$76,$D6,$B3,$92,$91
        .byte   $8F,$6D,$6C,$6D,$6F,$71,$6F,$71
        .byte   $73,$74,$73,$74,$76,$78,$76,$78
        .byte   $79,$01,$01,$DE,$01,$00,$05,$1D
        .byte   $94,$93,$07,$92,$10,$02,$80,$8D
        .byte   $80,$8D,$8D,$8C,$AD,$A0,$8D,$80
        .byte   $8D,$8C,$8D,$8F,$80,$94,$80,$02
        .byte   $00,$80,$93,$93,$93,$B4,$80,$02
        .byte   $80,$06,$80,$BB,$B9,$06,$98,$8D
        .byte   $80,$8D,$8D,$8C,$AD,$A0,$8D,$80
        .byte   $8D,$8C,$8D,$8F,$80,$94,$80,$93
        .byte   $93,$93,$80,$96,$93,$80,$D8,$03
        .byte   $3E,$87,$A5,$87,$04,$00,$D1,$97
        .byte   $00,$05,$03,$31,$05,$1D,$91,$80
        .byte   $01,$10,$9D,$01,$00,$8C,$8F,$91
        .byte   $01,$10,$9D,$01,$00,$91,$80,$91
        .byte   $01,$10,$9D,$01,$00,$8C,$83,$8F
        .byte   $01,$10,$9D,$01,$00,$91,$8D,$80
        .byte   $01,$10,$9D,$01,$00,$8D,$88,$8D
        .byte   $01,$10,$9D,$01,$00,$AC,$8C,$01
        .byte   $10,$9D,$01,$00,$AF,$8F,$01,$10
        .byte   $9D,$01,$00,$21,$91,$04,$01,$F6
        .byte   $98,$91,$80,$01,$10,$B8,$81,$81
        .byte   $B8,$01,$00,$8D,$8D,$8D,$8D,$8D
        .byte   $8F,$80,$21,$91,$91,$80,$01,$10
        .byte   $9D,$01,$00,$8C,$8F,$91,$01,$10
        .byte   $9D,$01,$00,$91,$80,$91,$01,$10
        .byte   $9D,$01,$00,$8C,$83,$90,$01,$10
        .byte   $9D,$01,$00,$90,$91,$80,$01,$10
        .byte   $9D,$01,$00,$8C,$8F,$91,$01,$10
        .byte   $9D,$01,$00,$91,$80,$91,$01,$10
        .byte   $9D,$01,$00,$8C,$83,$90,$01,$10
        .byte   $9D,$01,$00,$90,$8F,$80,$01,$10
        .byte   $9D,$01,$00,$8A,$8D,$8F,$01,$10
        .byte   $9D,$01,$00,$8F,$80,$8F,$01,$10
        .byte   $9D,$01,$00,$8A,$81,$8D,$01,$10
        .byte   $9D,$01,$00,$8E,$8F,$80,$01,$10
        .byte   $9D,$01,$00,$8A,$8D,$8F,$01,$10
        .byte   $9D,$01,$00,$8F,$80,$8F,$01,$10
        .byte   $9D,$01,$00,$8A,$01,$10,$9D,$BD
        .byte   $9D,$01,$00,$04,$01,$4C,$99,$80
        .byte   $8D,$01,$10,$9D,$01,$00,$94,$8D
        .byte   $01,$10,$7F,$7F,$BD,$01,$00,$8D
        .byte   $80,$01,$10,$9D,$01,$00,$88,$8D
        .byte   $91,$01,$10,$9D,$01,$00,$8F,$80
        .byte   $8F,$01,$10,$9D,$01,$00,$96,$8F
        .byte   $01,$10,$7F,$7F,$BD,$01,$00,$8F
        .byte   $8F,$01,$10,$9D,$01,$00,$8F,$80
        .byte   $8F,$01,$10,$9D,$01,$00,$8D,$04
        .byte   $01,$CF,$99,$04,$00,$F4,$98,$00
        .byte   $05,$07,$82,$60,$03,$38,$85,$85
        .byte   $07,$84,$40,$8A,$07,$82,$60,$03
        .byte   $36,$85,$85,$85,$07,$84,$40,$8A
        .byte   $03,$3D,$07,$83,$40,$85,$04,$00
        .byte   $19,$9A,$00,$00,$80,$00,$01,$82
        .byte   $80,$00

music_metal_stage:                      ; $05 — Metal Man Stage ($9A42)
        .byte   $0F,$4D,$9A,$2E,$9B,$5A,$9C,$58
        .byte   $9D,$40,$9E,$00,$06,$03,$3C,$02
        .byte   $C0,$07,$8A,$10,$05,$1D,$21,$A5
        .byte   $08,$01,$D5,$08,$00,$65,$6C,$60
        .byte   $6A,$60,$06,$88,$8A,$68,$21,$65
        .byte   $A5,$63,$63,$60,$22,$65,$85,$08
        .byte   $01,$A5,$08,$00,$67,$60,$88,$60
        .byte   $21,$65,$A5,$B4,$B6,$74,$60,$74
        .byte   $60,$B6,$04,$01,$4F,$9A,$71,$71
        .byte   $6F,$60,$71,$60,$6F,$60,$B1,$8C
        .byte   $8F,$80,$21,$B1,$08,$01,$B1,$08
        .byte   $00,$80,$71,$06,$98,$B6,$80,$94
        .byte   $93,$60,$21,$74,$94,$93,$21,$B1
        .byte   $08,$01,$B1,$08,$00,$80,$8C,$8F
        .byte   $90,$71,$71,$6F,$60,$71,$60,$6F
        .byte   $60,$B1,$8C,$8F,$80,$21,$B1,$08
        .byte   $01,$B1,$08,$00,$80,$71,$06,$98
        .byte   $B6,$80,$94,$93,$60,$21,$74,$94
        .byte   $93,$80,$74,$60,$93,$60,$74,$A0
        .byte   $71,$06,$98,$B6,$B4,$B3,$74,$06
        .byte   $96,$71,$60,$71,$60,$71,$06,$8F
        .byte   $B1,$71,$06,$98,$B6,$B4,$B3,$74
        .byte   $76,$60,$78,$60,$98,$60,$78,$76
        .byte   $74,$76,$74,$73,$74,$73,$71,$73
        .byte   $71,$6F,$B6,$B4,$B3,$74,$06,$96
        .byte   $71,$60,$71,$60,$71,$06,$8F,$B1
        .byte   $71,$06,$98,$B6,$B4,$B3,$74,$76
        .byte   $60,$78,$60,$78,$78,$60,$78,$60
        .byte   $78,$60,$06,$98,$6C,$6C,$06,$8F
        .byte   $04,$00,$4F,$9A,$00,$06,$03,$3A
        .byte   $05,$29,$02,$00,$07,$86,$10,$65
        .byte   $68,$6C,$60,$65,$80,$65,$67,$68
        .byte   $67,$65,$60,$65,$63,$21,$65,$04
        .byte   $02,$30,$9B,$03,$3C,$02,$C0,$07
        .byte   $8A,$10,$05,$1D,$A5,$A7,$65,$60
        .byte   $65,$60,$A7,$05,$29,$03,$3A,$02
        .byte   $00,$07,$86,$10,$65,$68,$6C,$60
        .byte   $65,$80,$65,$67,$68,$67,$65,$60
        .byte   $65,$63,$21,$65,$04,$02,$5D,$9B
        .byte   $03,$3C,$02,$C0,$07,$8A,$10,$05
        .byte   $1D,$A5,$A7,$65,$60,$65,$60,$A7
        .byte   $05,$29,$03,$38,$02,$00,$07,$86
        .byte   $10,$65,$65,$65,$60,$65,$80,$65
        .byte   $67,$68,$67,$65,$60,$65,$63,$21
        .byte   $65,$04,$01,$8A,$9B,$03,$3C,$02
        .byte   $C0,$07,$8A,$10,$05,$1D,$B1,$80
        .byte   $91,$8A,$60,$21,$8C,$6C,$8A,$B4
        .byte   $93,$60,$74,$60,$06,$94,$93,$93
        .byte   $05,$29,$03,$38,$02,$00,$07,$86
        .byte   $10,$65,$65,$65,$60,$65,$80,$65
        .byte   $67,$68,$67,$65,$60,$65,$63,$21
        .byte   $65,$04,$01,$C2,$9B,$03,$3C,$02
        .byte   $C0,$07,$8A,$10,$05,$1D,$B1,$80
        .byte   $91,$8A,$60,$21,$8C,$6C,$8A,$74
        .byte   $60,$74,$60,$83,$63,$02,$00,$01
        .byte   $44,$08,$01,$21,$7F,$DF,$01,$00
        .byte   $08,$00,$03,$39,$80,$B6,$B4,$B3
        .byte   $74,$76,$74,$60,$74,$60,$74,$06
        .byte   $93,$B4,$80,$71,$06,$98,$B6,$B4
        .byte   $B3,$74,$76,$60,$78,$60,$98,$60
        .byte   $78,$76,$74,$76,$74,$73,$74,$73
        .byte   $71,$73,$71,$6F,$B6,$B4,$B3,$74
        .byte   $76,$74,$60,$74,$60,$74,$06,$93
        .byte   $B4,$80,$71,$06,$98,$B6,$B4,$93
        .byte   $74,$76,$60,$73,$60,$73,$73,$60
        .byte   $73,$60,$73,$60,$06,$93,$6C,$6C
        .byte   $06,$8F,$08,$00,$04,$00,$30,$9B
        .byte   $00,$06,$03,$50,$05,$1D,$71,$60
        .byte   $71,$60,$AF,$91,$60,$71,$94,$98
        .byte   $71,$60,$71,$60,$AF,$91,$60,$71
        .byte   $91,$8F,$6D,$60,$6D,$60,$AC,$8D
        .byte   $60,$6D,$8D,$8C,$AD,$AF,$6D,$60
        .byte   $6D,$60,$AF,$04,$01,$60,$9C,$71
        .byte   $60,$71,$60,$AF,$91,$60,$71,$94
        .byte   $98,$76,$60,$76,$60,$B4,$96,$60
        .byte   $76,$91,$8F,$8D,$A0,$8D,$8F,$60
        .byte   $6F,$8F,$8F,$B1,$8F,$60,$71,$60
        .byte   $06,$91,$8F,$90,$71,$60,$71,$60
        .byte   $AF,$91,$60,$71,$94,$98,$76,$60
        .byte   $76,$60,$B4,$96,$60,$76,$91,$8F
        .byte   $8D,$A0,$8D,$8F,$60,$6F,$8F,$8F
        .byte   $71,$60,$71,$60,$8F,$6F,$71,$01
        .byte   $10,$60,$7A,$7A,$7A,$78,$78,$76
        .byte   $76,$01,$00,$05,$29,$6A,$6A,$68
        .byte   $60,$6A,$60,$68,$6A,$60,$6A,$8A
        .byte   $8A,$68,$67,$68,$60,$68,$60,$68
        .byte   $67,$60,$67,$88,$60,$68,$8A,$8C
        .byte   $6A,$6A,$68,$60,$6A,$60,$68,$6A
        .byte   $60,$6A,$8A,$8A,$68,$6C,$60,$8C
        .byte   $6C,$01,$10,$6B,$6B,$6B,$6B,$69
        .byte   $69,$69,$69,$67,$67,$67,$67,$01
        .byte   $00,$6A,$6A,$68,$60,$6A,$60,$68
        .byte   $6A,$60,$6A,$8A,$8A,$68,$67,$68
        .byte   $60,$68,$60,$68,$67,$60,$67,$88
        .byte   $60,$68,$8A,$8C,$6A,$6A,$68,$60
        .byte   $6A,$60,$68,$6A,$60,$6A,$8A,$8A
        .byte   $68,$6C,$05,$1D,$60,$70,$70,$60
        .byte   $70,$60,$70,$60,$70,$80,$6C,$6C
        .byte   $06,$8C,$04,$00,$60,$9C,$00,$06
        .byte   $07,$82,$90,$83,$83,$07,$84,$50
        .byte   $01,$FF,$8D,$01,$00,$07,$82,$90
        .byte   $63,$63,$63,$63,$83,$07,$84,$50
        .byte   $01,$FF,$8D,$01,$00,$07,$82,$90
        .byte   $63,$63,$04,$06,$5A,$9D,$07,$84
        .byte   $50,$01,$FF,$8D,$80,$8D,$80,$6D
        .byte   $60,$6D,$60,$AD,$01,$00,$07,$82
        .byte   $90,$83,$83,$07,$84,$50,$01,$FF
        .byte   $8D,$01,$00,$07,$82,$90,$63,$63
        .byte   $63,$63,$83,$07,$84,$50,$01,$FF
        .byte   $8D,$01,$00,$07,$82,$90,$63,$63
        .byte   $04,$06,$90,$9D,$07,$82,$90,$83
        .byte   $07,$84,$50,$01,$FF,$8D,$01,$00
        .byte   $07,$82,$90,$63,$63,$07,$84,$50
        .byte   $01,$FF,$6D,$01,$00,$07,$82,$90
        .byte   $63,$C0,$07,$82,$90,$83,$83,$07
        .byte   $84,$50,$01,$FF,$8D,$01,$00,$07
        .byte   $82,$90,$63,$63,$63,$63,$83,$07
        .byte   $84,$50,$01,$FF,$8D,$01,$00,$07
        .byte   $82,$90,$63,$63,$04,$02,$D4,$9D
        .byte   $07,$84,$50,$01,$FF,$60,$8D,$60
        .byte   $AD,$C0,$01,$00,$07,$82,$90,$83
        .byte   $83,$07,$84,$50,$01,$FF,$8D,$01
        .byte   $00,$07,$82,$90,$63,$63,$63,$63
        .byte   $83,$07,$84,$50,$01,$FF,$8D,$01
        .byte   $00,$07,$82,$90,$63,$63,$04,$02
        .byte   $06,$9E,$07,$84,$50,$01,$FF,$60
        .byte   $6D,$8D,$6D,$60,$6D,$60,$AD,$A0
        .byte   $01,$00,$04,$00,$5A,$9D,$00,$00
        .byte   $80,$00,$01,$62,$80,$00

music_quick_stage:                      ; $06 — Quick Man Stage ($9E48)
        .byte   $0F,$53,$9E,$2B,$9F,$1D,$A0,$14
        .byte   $A1,$89,$A1,$00,$06,$03,$3C,$02
        .byte   $C0,$07,$8A,$20,$05,$1F,$8C,$71
        .byte   $68,$60,$71,$60,$65,$60,$71,$60
        .byte   $6C,$88,$91,$04,$01,$5E,$9E,$8A
        .byte   $6F,$67,$60,$6F,$60,$63,$60,$6F
        .byte   $60,$6A,$87,$8F,$04,$01,$6F,$9E
        .byte   $8C,$71,$68,$60,$71,$60,$65,$60
        .byte   $71,$60,$6C,$88,$91,$04,$01,$80
        .byte   $9E,$8A,$6F,$67,$60,$6F,$60,$63
        .byte   $60,$6F,$60,$6A,$87,$8F,$63,$65
        .byte   $67,$6A,$60,$6F,$73,$76,$A0,$07
        .byte   $92,$10,$03,$3E,$83,$84,$21,$C5
        .byte   $08,$01,$E5,$08,$00,$06,$87,$06
        .byte   $88,$8A,$06,$87,$06,$88,$87,$06
        .byte   $A5,$85,$67,$65,$06,$A3,$A3,$A4
        .byte   $21,$C5,$08,$01,$E5,$08,$00,$06
        .byte   $87,$06,$88,$8A,$21,$AC,$08,$01
        .byte   $AC,$08,$00,$78,$76,$74,$76,$74
        .byte   $73,$74,$73,$71,$73,$71,$6F,$71
        .byte   $6F,$6D,$6F,$6D,$6C,$6D,$6C,$6A
        .byte   $6C,$6A,$68,$07,$AF,$10,$CC,$06
        .byte   $8C,$06,$8D,$91,$CF,$AC,$AF,$D0
        .byte   $06,$90,$06,$93,$96,$D4,$94,$93
        .byte   $91,$8F,$CD,$8D,$8C,$AA,$CF,$8F
        .byte   $8D,$AC,$71,$76,$71,$6D,$04,$03
        .byte   $12,$9F,$07,$87,$70,$B1,$91,$60
        .byte   $71,$60,$71,$91,$91,$74,$75,$04
        .byte   $00,$55,$9E,$00,$06,$03,$38,$02
        .byte   $C0,$06,$60,$05,$1F,$07,$90,$10
        .byte   $8C,$71,$68,$60,$71,$60,$65,$60
        .byte   $71,$60,$6C,$88,$91,$04,$01,$38
        .byte   $9F,$8A,$6F,$67,$60,$6F,$60,$63
        .byte   $60,$6F,$60,$6A,$87,$8F,$04,$01
        .byte   $49,$9F,$8C,$71,$68,$60,$71,$60
        .byte   $65,$60,$71,$60,$6C,$88,$91,$04
        .byte   $01,$5A,$9F,$8A,$6F,$67,$60,$6F
        .byte   $60,$63,$60,$6F,$60,$6A,$87,$8F
        .byte   $63,$65,$67,$6A,$60,$6F,$73,$76
        .byte   $A0,$80,$40,$03,$39,$07,$92,$10
        .byte   $02,$00,$8C,$71,$68,$60,$71,$60
        .byte   $65,$60,$71,$60,$6C,$88,$91,$04
        .byte   $01,$8A,$9F,$8A,$6F,$67,$60,$6F
        .byte   $60,$63,$60,$6F,$60,$6A,$87,$8F
        .byte   $04,$01,$9B,$9F,$8C,$71,$68,$60
        .byte   $71,$60,$65,$60,$71,$60,$6C,$88
        .byte   $91,$04,$01,$AC,$9F,$60,$6F,$60
        .byte   $6A,$87,$8F,$02,$C0,$07,$8F,$10
        .byte   $60,$78,$76,$74,$76,$74,$73,$74
        .byte   $73,$71,$73,$71,$6F,$71,$6F,$6D
        .byte   $6F,$6D,$6C,$6D,$6C,$6A,$6C,$6A
        .byte   $05,$1F,$07,$AF,$10,$03,$3A,$C8
        .byte   $06,$88,$06,$8A,$8C,$C7,$A7,$AC
        .byte   $CC,$06,$8C,$06,$90,$93,$D1,$91
        .byte   $60,$93,$91,$6F,$CA,$8A,$88,$A6
        .byte   $CC,$8C,$8A,$A8,$6D,$71,$6D,$6A
        .byte   $04,$03,$04,$A0,$07,$87,$70,$AD
        .byte   $8D,$60,$6D,$60,$6D,$8D,$8D,$6C
        .byte   $6D,$04,$00,$2D,$9F,$00,$06,$03
        .byte   $28,$05,$1F,$91,$8C,$71,$60,$71
        .byte   $71,$60,$91,$6C,$8C,$8F,$04,$01
        .byte   $23,$A0,$8F,$8A,$6F,$60,$6F,$6F
        .byte   $60,$8F,$6A,$8A,$8F,$04,$01,$32
        .byte   $A0,$91,$8C,$71,$60,$71,$71,$60
        .byte   $91,$6C,$8C,$8F,$04,$01,$41,$A0
        .byte   $8F,$8A,$6F,$60,$6F,$6F,$60,$8F
        .byte   $6A,$8A,$8F,$01,$12,$78,$78,$78
        .byte   $78,$60,$75,$75,$75,$60,$7D,$7D
        .byte   $7D,$7B,$7B,$7C,$7C,$01,$00,$91
        .byte   $8C,$71,$60,$71,$71,$60,$91,$6C
        .byte   $8C,$8F,$04,$01,$6F,$A0,$8F,$8A
        .byte   $6F,$60,$6F,$6F,$60,$8F,$6A,$8A
        .byte   $8F,$04,$01,$7E,$A0,$91,$8C,$71
        .byte   $60,$71,$71,$60,$91,$6C,$8C,$8F
        .byte   $04,$01,$8D,$A0,$8F,$8A,$6F,$60
        .byte   $6F,$6F,$60,$8F,$6A,$8A,$8F,$04
        .byte   $01,$9C,$A0,$8D,$60,$6D,$91,$74
        .byte   $71,$60,$6D,$74,$71,$99,$74,$71
        .byte   $8F,$60,$6F,$93,$76,$73,$60,$6F
        .byte   $76,$73,$9B,$76,$73,$90,$60,$70
        .byte   $93,$78,$73,$60,$70,$78,$73,$9C
        .byte   $78,$73,$91,$60,$71,$94,$78,$74
        .byte   $60,$71,$78,$74,$9D,$78,$74,$86
        .byte   $60,$66,$8A,$6D,$6A,$60,$6D,$6A
        .byte   $66,$92,$6D,$6A,$88,$60,$68,$8C
        .byte   $6F,$6C,$60,$6F,$6C,$68,$94,$6F
        .byte   $6C,$8A,$60,$6A,$8D,$71,$6D,$60
        .byte   $71,$6D,$6A,$96,$71,$6D,$AA,$8A
        .byte   $60,$6A,$60,$6A,$8A,$8A,$6F,$70
        .byte   $04,$00,$23,$A0,$00,$06,$07,$84
        .byte   $A0,$03,$3F,$02,$80,$03,$3A,$64
        .byte   $64,$60,$64,$02,$00,$01,$33,$03
        .byte   $3F,$88,$01,$00,$02,$80,$03,$3A
        .byte   $64,$64,$60,$64,$64,$02,$00,$01
        .byte   $33,$03,$3F,$68,$88,$01,$00,$02
        .byte   $80,$03,$3A,$64,$64,$04,$06,$1D
        .byte   $A1,$E0,$03,$3A,$64,$64,$60,$64
        .byte   $02,$00,$01,$33,$03,$3F,$88,$01
        .byte   $00,$02,$80,$03,$3A,$64,$64,$60
        .byte   $64,$64,$02,$00,$01,$33,$03,$3F
        .byte   $68,$88,$01,$00,$02,$80,$03,$3A
        .byte   $64,$64,$04,$0E,$4A,$A1,$01,$33
        .byte   $68,$60,$80,$88,$60,$68,$60,$68
        .byte   $68,$60,$68,$60,$80,$04,$00,$1D
        .byte   $A1,$00,$00,$80,$00,$01,$62,$80
        .byte   $00

music_bubble_stage:                     ; $07 — Bubble Man Stage ($A191)
        .byte   $0F,$9C,$A1,$BA,$A2,$A7,$A3,$53
        .byte   $A4,$A0,$A4,$00,$05,$02,$00,$05
        .byte   $13,$03,$3D,$07,$92,$10,$CC,$AD
        .byte   $8F,$EC,$80,$CA,$AA,$8C,$82,$02
        .byte   $C0,$05,$1F,$98,$98,$01,$25,$96
        .byte   $80,$01,$00,$98,$98,$01,$25,$96
        .byte   $80,$01,$00,$04,$01,$9E,$A1,$02
        .byte   $80,$05,$13,$B1,$01,$10,$9D,$01
        .byte   $00,$91,$80,$8F,$01,$10,$9D,$01
        .byte   $00,$91,$04,$01,$CA,$A1,$B3,$01
        .byte   $10,$9D,$01,$00,$93,$80,$91,$01
        .byte   $10,$9D,$01,$00,$93,$04,$01,$DF
        .byte   $A1,$B1,$01,$10,$9D,$01,$00,$91
        .byte   $80,$8F,$01,$10,$9D,$01,$00,$91
        .byte   $04,$01,$F2,$A1,$B3,$01,$10,$9D
        .byte   $01,$00,$93,$80,$91,$01,$10,$9D
        .byte   $01,$00,$93,$B0,$01,$10,$9D,$01
        .byte   $00,$93,$80,$90,$01,$10,$9D,$01
        .byte   $00,$93,$02,$C0,$03,$3D,$07,$92
        .byte   $10,$05,$1F,$21,$B4,$08,$01,$B4
        .byte   $08,$00,$94,$96,$80,$98,$80,$96
        .byte   $80,$94,$80,$94,$B6,$93,$94,$80
        .byte   $93,$80,$91,$80,$21,$8F,$08,$01
        .byte   $AF,$80,$06,$BB,$08,$00,$B9,$21
        .byte   $B8,$08,$01,$B8,$08,$00,$98,$96
        .byte   $94,$9B,$80,$99,$80,$06,$B8,$9D
        .byte   $21,$9C,$08,$01,$DC,$08,$00,$05
        .byte   $2B,$80,$8C,$90,$21,$93,$08,$01
        .byte   $F3,$08,$00,$05,$1F,$AC,$80,$8A
        .byte   $21,$8A,$08,$01,$AA,$08,$00,$88
        .byte   $80,$8A,$21,$8A,$08,$01,$AA,$08
        .byte   $00,$85,$88,$8A,$AC,$8A,$AF,$AD
        .byte   $AC,$AA,$A8,$A7,$80,$AC,$80,$8A
        .byte   $21,$8A,$08,$01,$AA,$08,$00,$88
        .byte   $80,$8A,$21,$8A,$08,$01,$AA,$08
        .byte   $00,$85,$88,$8A,$AC,$8A,$AF,$AD
        .byte   $AC,$B0,$B3,$B6,$98,$04,$00,$C8
        .byte   $A1,$00,$05,$03,$37,$02,$80,$05
        .byte   $13,$07,$92,$20,$60,$88,$98,$94
        .byte   $88,$98,$91,$94,$8D,$98,$94,$88
        .byte   $94,$98,$88,$94,$98,$87,$96,$93
        .byte   $87,$96,$8F,$93,$6C,$02,$C0,$03
        .byte   $3D,$05,$1F,$93,$93,$A0,$93,$93
        .byte   $A0,$04,$01,$BC,$A2,$01,$00,$03
        .byte   $38,$02,$80,$05,$13,$60,$88,$98
        .byte   $94,$88,$98,$91,$94,$8D,$98,$94
        .byte   $88,$94,$98,$88,$94,$98,$87,$96
        .byte   $93,$87,$96,$8F,$93,$8C,$96,$93
        .byte   $87,$93,$96,$87,$93,$96,$88,$98
        .byte   $94,$88,$98,$91,$94,$8D,$98,$94
        .byte   $88,$94,$98,$88,$94,$98,$87,$96
        .byte   $93,$87,$96,$8F,$93,$8C,$96,$93
        .byte   $87,$93,$96,$87,$93,$76,$02,$C0
        .byte   $03,$38,$07,$92,$10,$05,$1F,$06
        .byte   $80,$D4,$94,$96,$80,$98,$80,$96
        .byte   $80,$94,$80,$94,$B6,$93,$94,$80
        .byte   $93,$80,$91,$80,$21,$8F,$AF,$80
        .byte   $06,$BB,$B9,$D8,$98,$96,$94,$9B
        .byte   $80,$99,$80,$06,$B8,$9D,$21,$9C
        .byte   $DC,$05,$2B,$80,$8C,$70,$F3,$05
        .byte   $1F,$A8,$80,$87,$06,$A7,$85,$80
        .byte   $87,$06,$A7,$81,$85,$87,$79,$74
        .byte   $71,$7D,$79,$74,$71,$7D,$79,$74
        .byte   $71,$7D,$79,$74,$71,$7D,$78,$73
        .byte   $70,$6C,$78,$73,$70,$6C,$78,$73
        .byte   $70,$6C,$78,$73,$70,$6C,$04,$01
        .byte   $70,$A3,$04,$00,$EE,$A2,$00,$05
        .byte   $03,$35,$05,$1F,$88,$98,$94,$88
        .byte   $98,$91,$94,$8D,$98,$94,$88,$94
        .byte   $98,$88,$94,$98,$87,$96,$93,$87
        .byte   $96,$8F,$93,$8C,$96,$93,$87,$93
        .byte   $96,$87,$93,$96,$88,$98,$94,$88
        .byte   $98,$91,$94,$8D,$98,$94,$88,$94
        .byte   $98,$88,$94,$98,$87,$96,$93,$87
        .byte   $96,$8F,$93,$8C,$96,$93,$87,$93
        .byte   $01,$10,$7D,$7D,$7D,$7D,$7A,$7A
        .byte   $77,$77,$01,$00,$88,$98,$94,$88
        .byte   $98,$91,$94,$8D,$98,$94,$88,$94
        .byte   $98,$88,$94,$98,$87,$96,$93,$87
        .byte   $96,$8F,$93,$8C,$96,$93,$87,$93
        .byte   $96,$87,$93,$96,$04,$03,$F5,$A3
        .byte   $91,$94,$93,$91,$AF,$80,$8D,$80
        .byte   $8F,$AF,$80,$8D,$91,$93,$8D,$04
        .byte   $07,$27,$A4,$90,$04,$07,$2C,$A4
        .byte   $91,$94,$93,$91,$AF,$80,$8D,$80
        .byte   $8F,$AF,$80,$8D,$91,$93,$8D,$91
        .byte   $94,$8D,$91,$94,$8D,$91,$93,$8C
        .byte   $90,$93,$8C,$90,$93,$98,$04,$00
        .byte   $F5,$A3,$00,$05,$07,$88,$10,$03
        .byte   $38,$07,$82,$70,$83,$04,$17,$5A
        .byte   $A4,$07,$84,$40,$01,$FF,$8B,$8B
        .byte   $A0,$8B,$8B,$A0,$01,$00,$07,$82
        .byte   $70,$83,$04,$17,$6F,$A4,$07,$84
        .byte   $40,$01,$FF,$8B,$8B,$A0,$6B,$6B
        .byte   $6B,$6B,$6B,$6B,$6A,$6A,$01,$00
        .byte   $03,$3D,$07,$82,$70,$83,$83,$07
        .byte   $84,$40,$01,$FF,$8B,$01,$00,$07
        .byte   $82,$70,$83,$04,$00,$89,$A4,$00
        .byte   $00,$80,$00,$02,$62,$80,$00

music_wily_stage1:                      ; $08 — Dr. Wily Stage 1 (Wily 1-2) ($A4A8)
        .byte   $0F,$B3,$A4,$41,$A6,$C0,$A7,$40
        .byte   $A9,$58,$A9,$00,$05,$03,$3E,$02
        .byte   $40,$05,$20,$07,$84,$10,$85,$68
        .byte   $68,$88,$68,$68,$88,$85,$80,$65
        .byte   $65,$88,$68,$68,$88,$85,$80,$8C
        .byte   $8A,$8C,$80,$68,$68,$88,$68,$68
        .byte   $88,$85,$80,$8C,$80,$8A,$80,$88
        .byte   $80,$8A,$A0,$80,$6A,$6A,$8A,$6A
        .byte   $6A,$8A,$87,$80,$8C,$80,$8A,$80
        .byte   $88,$80,$87,$80,$85,$80,$85,$8C
        .byte   $8F,$06,$AE,$85,$80,$85,$8C,$8F
        .byte   $8E,$80,$93,$94,$80,$68,$68,$88
        .byte   $68,$68,$88,$85,$80,$65,$65,$88
        .byte   $68,$68,$88,$85,$80,$8C,$8A,$8C
        .byte   $80,$68,$68,$88,$68,$68,$88,$85
        .byte   $80,$8C,$80,$8A,$80,$88,$80,$8A
        .byte   $A0,$80,$6A,$6A,$8A,$6A,$6A,$8A
        .byte   $87,$80,$8C,$80,$8A,$80,$88,$80
        .byte   $87,$80,$85,$80,$85,$8C,$8F,$06
        .byte   $AE,$85,$80,$85,$8C,$8F,$8E,$80
        .byte   $8F,$07,$90,$10,$02,$80,$22,$91
        .byte   $B1,$D1,$8F,$B4,$B1,$AF,$B1,$80
        .byte   $CF,$8F,$06,$B1,$8C,$8D,$8C,$88
        .byte   $80,$88,$8C,$8F,$06,$D1,$8F,$B4
        .byte   $B1,$AF,$B1,$21,$8F,$CF,$8F,$8C
        .byte   $8F,$90,$80,$90,$90,$93,$D8,$07
        .byte   $95,$30,$02,$00,$03,$3F,$05,$14
        .byte   $08,$01,$06,$CC,$8A,$AF,$AD,$AC
        .byte   $AD,$22,$8C,$CC,$AC,$8A,$AF,$AD
        .byte   $AC,$AD,$21,$88,$C8,$88,$8A,$8C
        .byte   $E7,$08,$00,$05,$20,$02,$80,$85
        .byte   $80,$85,$8C,$8F,$06,$AE,$85,$80
        .byte   $85,$8C,$8F,$8E,$80,$8F,$08,$01
        .byte   $02,$C0,$21,$91,$D1,$B1,$8F,$91
        .byte   $80,$06,$B4,$98,$96,$94,$93,$D1
        .byte   $B1,$8F,$91,$80,$06,$B4,$94,$96
        .byte   $B4,$D3,$93,$91,$8F,$06,$B8,$B6
        .byte   $B4,$B3,$93,$94,$93,$D1,$85,$80
        .byte   $85,$8C,$8F,$8E,$80,$8F,$08,$00
        .byte   $02,$80,$22,$91,$B1,$D1,$8F,$B4
        .byte   $B1,$AF,$B1,$80,$CF,$8F,$06,$B1
        .byte   $8C,$8D,$8C,$88,$80,$88,$8C,$8F
        .byte   $06,$D1,$8F,$B4,$B1,$AF,$B1,$21
        .byte   $8F,$CF,$8F,$8C,$8F,$90,$80,$90
        .byte   $90,$93,$06,$B8,$05,$14,$02,$40
        .byte   $94,$80,$94,$94,$93,$B4,$9D,$BB
        .byte   $B9,$B8,$B6,$96,$80,$98,$98,$80
        .byte   $98,$A0,$96,$80,$98,$98,$80,$98
        .byte   $80,$96,$94,$80,$94,$94,$93,$B4
        .byte   $9D,$BB,$B9,$B8,$B6,$80,$93,$94
        .byte   $93,$21,$91,$D1,$E0,$04,$00,$B5
        .byte   $A4,$00,$05,$02,$40,$05,$14,$07
        .byte   $84,$10,$03,$3A,$80,$71,$71,$91
        .byte   $71,$71,$91,$8C,$80,$6C,$6C,$91
        .byte   $71,$71,$91,$8C,$80,$94,$93,$94
        .byte   $80,$71,$71,$91,$71,$71,$91,$8C
        .byte   $80,$94,$80,$93,$80,$91,$80,$93
        .byte   $A0,$80,$73,$73,$93,$73,$73,$93
        .byte   $8F,$80,$94,$80,$93,$80,$91,$80
        .byte   $8F,$05,$20,$A0,$85,$80,$85,$8C
        .byte   $8F,$06,$AE,$85,$80,$85,$8C,$8F
        .byte   $8E,$8F,$91,$04,$01,$43,$A6,$07
        .byte   $92,$10,$02,$80,$60,$22,$91,$B1
        .byte   $D1,$8F,$B4,$B1,$AF,$B1,$80,$CF
        .byte   $8F,$06,$B1,$8C,$8D,$8C,$88,$80
        .byte   $88,$8C,$8F,$06,$D1,$8F,$B4,$B1
        .byte   $AF,$B1,$21,$8F,$CF,$8F,$8C,$8F
        .byte   $90,$80,$90,$90,$93,$22,$B8,$68
        .byte   $02,$00,$85,$68,$68,$88,$68,$68
        .byte   $88,$85,$80,$65,$65,$88,$68,$68
        .byte   $88,$85,$80,$8C,$8A,$8C,$80,$68
        .byte   $68,$88,$68,$68,$88,$85,$80,$8C
        .byte   $80,$8A,$80,$88,$80,$8A,$A0,$80
        .byte   $6A,$6A,$8A,$6A,$6A,$8A,$87,$80
        .byte   $8C,$80,$8A,$80,$88,$80,$87,$02
        .byte   $80,$A0,$85,$80,$85,$8C,$8F,$06
        .byte   $AE,$85,$80,$85,$8C,$8F,$8E,$96
        .byte   $98,$02,$00,$80,$68,$68,$88,$68
        .byte   $68,$88,$85,$80,$65,$65,$88,$68
        .byte   $68,$88,$85,$80,$8C,$8A,$8C,$80
        .byte   $68,$68,$88,$68,$68,$88,$85,$80
        .byte   $8C,$80,$8A,$80,$88,$80,$8A,$A0
        .byte   $80,$6A,$6A,$8A,$6A,$6A,$8A,$87
        .byte   $80,$8C,$80,$8A,$80,$88,$80,$87
        .byte   $02,$80,$80,$85,$80,$85,$8C,$8F
        .byte   $CE,$85,$80,$85,$8C,$8F,$8E,$96
        .byte   $98,$07,$8A,$10,$60,$22,$91,$B1
        .byte   $D1,$8F,$B4,$B1,$AF,$B1,$80,$CF
        .byte   $8F,$06,$B1,$8C,$8D,$8C,$88,$80
        .byte   $88,$8C,$8F,$06,$D1,$8F,$B4,$B1
        .byte   $AF,$B1,$21,$8F,$CF,$8F,$8C,$8F
        .byte   $90,$80,$90,$90,$93,$06,$80,$05
        .byte   $14,$02,$40,$08,$01,$91,$80,$91
        .byte   $91,$8F,$B1,$99,$B6,$B6,$B4,$B3
        .byte   $93,$80,$94,$94,$80,$94,$A0,$93
        .byte   $80,$94,$94,$80,$94,$80,$93,$91
        .byte   $80,$91,$91,$8F,$B1,$99,$B6,$B6
        .byte   $B4,$B3,$80,$8F,$91,$8F,$21,$8C
        .byte   $CC,$E0,$08,$00,$04,$00,$43,$A6
        .byte   $00,$05,$03,$41,$05,$2C,$85,$65
        .byte   $65,$04,$07,$C6,$A7,$81,$61,$61
        .byte   $04,$07,$CD,$A7,$83,$63,$63,$04
        .byte   $07,$D4,$A7,$85,$65,$65,$04,$06
        .byte   $DB,$A7,$83,$21,$85,$85,$65,$65
        .byte   $04,$07,$E5,$A7,$81,$61,$61,$04
        .byte   $07,$EC,$A7,$83,$63,$63,$04,$07
        .byte   $F3,$A7,$85,$65,$65,$04,$06,$FA
        .byte   $A7,$83,$21,$85,$86,$66,$66,$86
        .byte   $66,$66,$86,$6D,$6D,$6A,$6A,$8A
        .byte   $80,$66,$66,$8A,$66,$66,$91,$6A
        .byte   $6A,$8D,$66,$66,$85,$65,$65,$85
        .byte   $65,$65,$85,$6C,$6C,$68,$68,$8F
        .byte   $80,$65,$65,$88,$65,$65,$8F,$68
        .byte   $68,$8C,$65,$65,$86,$66,$66,$86
        .byte   $66,$66,$86,$6D,$6D,$6A,$6A,$8A
        .byte   $80,$66,$66,$8A,$66,$66,$91,$6A
        .byte   $6A,$8D,$66,$66,$83,$63,$63,$04
        .byte   $02,$4C,$A8,$83,$84,$80,$84,$84
        .byte   $84,$A4,$A0,$85,$65,$65,$04,$07
        .byte   $5B,$A8,$81,$61,$61,$04,$07,$62
        .byte   $A8,$83,$63,$63,$04,$07,$69,$A8
        .byte   $85,$65,$65,$04,$06,$70,$A8,$83
        .byte   $21,$85,$85,$65,$65,$04,$07,$7A
        .byte   $A8,$81,$61,$61,$04,$07,$81,$A8
        .byte   $83,$63,$63,$04,$07,$88,$A8,$85
        .byte   $65,$65,$04,$06,$8F,$A8,$83,$21
        .byte   $85,$86,$66,$66,$86,$66,$66,$86
        .byte   $6D,$6D,$6A,$6A,$8A,$80,$66,$66
        .byte   $8A,$66,$66,$91,$6A,$6A,$8D,$66
        .byte   $66,$85,$65,$65,$85,$65,$65,$85
        .byte   $6C,$6C,$68,$68,$8F,$80,$65,$65
        .byte   $88,$65,$65,$8F,$68,$68,$8C,$65
        .byte   $65,$86,$66,$66,$86,$66,$66,$86
        .byte   $6D,$6D,$6A,$6A,$8A,$80,$66,$66
        .byte   $8A,$66,$66,$91,$6A,$6A,$8D,$66
        .byte   $66,$83,$63,$63,$04,$02,$E1,$A8
        .byte   $83,$84,$80,$84,$84,$84,$A4,$80
        .byte   $A1,$61,$61,$81,$61,$61,$81,$61
        .byte   $61,$81,$A3,$63,$63,$83,$63,$63
        .byte   $83,$63,$63,$83,$05,$20,$A5,$91
        .byte   $87,$93,$88,$94,$87,$04,$01,$04
        .byte   $A9,$05,$2C,$A1,$61,$61,$81,$61
        .byte   $61,$81,$61,$61,$81,$A3,$63,$63
        .byte   $83,$63,$63,$83,$63,$63,$A4,$A5
        .byte   $01,$10,$6D,$6D,$6C,$6C,$6A,$6A
        .byte   $68,$68,$01,$00,$83,$85,$80,$83
        .byte   $A5,$83,$84,$A5,$04,$00,$C4,$A7
        .byte   $00,$05,$03,$3F,$07,$82,$A0,$62
        .byte   $60,$62,$62,$07,$83,$40,$87,$07
        .byte   $82,$A0,$62,$62,$04,$00,$44,$A9
        .byte   $00,$00,$80,$00,$01,$41,$80,$00

music_wily_stage2:                      ; $09 — Dr. Wily Stage 2 (Wily 3-5) ($A960)
        .byte   $0F,$6B,$A9,$47,$AA,$A9,$AA,$87
        .byte   $AB,$98,$AB,$00,$06,$03,$3C,$02
        .byte   $00,$05,$22,$07,$A0,$10,$08,$01
        .byte   $E5,$08,$00,$21,$CC,$08,$01,$CC
        .byte   $08,$00,$21,$C7,$08,$01,$C7,$08
        .byte   $00,$21,$C8,$08,$01,$C8,$08,$00
        .byte   $21,$C6,$08,$01,$C6,$08,$00,$21
        .byte   $CD,$08,$01,$CD,$08,$00,$21,$C8
        .byte   $08,$01,$C8,$08,$00,$21,$C9,$08
        .byte   $01,$C9,$08,$00,$21,$C7,$08,$01
        .byte   $C7,$08,$00,$21,$CE,$08,$01,$CE
        .byte   $08,$00,$21,$C9,$08,$01,$C9,$08
        .byte   $00,$21,$CA,$08,$01,$CA,$08,$00
        .byte   $21,$C8,$08,$01,$C8,$08,$00,$21
        .byte   $CF,$08,$01,$CF,$08,$00,$21,$CA
        .byte   $08,$01,$CA,$08,$00,$21,$CB,$08
        .byte   $01,$CB,$08,$00,$21,$C9,$08,$01
        .byte   $C9,$08,$00,$21,$D0,$08,$01,$D0
        .byte   $08,$00,$21,$CB,$08,$01,$CB,$08
        .byte   $00,$21,$CC,$08,$01,$CC,$05,$27
        .byte   $08,$00,$04,$01,$76,$A9,$05,$22
        .byte   $21,$CF,$08,$01,$CF,$08,$00,$21
        .byte   $D6,$08,$01,$D6,$08,$00,$21,$D1
        .byte   $08,$01,$D1,$08,$00,$21,$D2,$08
        .byte   $01,$D2,$08,$00,$21,$D0,$08,$01
        .byte   $D0,$08,$00,$21,$D7,$08,$01,$D7
        .byte   $08,$00,$21,$D2,$08,$01,$D2,$08
        .byte   $00,$D3,$08,$01,$01,$05,$D3,$01
        .byte   $00,$08,$00,$04,$00,$76,$A9,$00
        .byte   $06,$07,$A0,$10,$02,$00,$05,$22
        .byte   $03,$39,$05,$22,$E5,$E8,$E3,$21
        .byte   $C5,$08,$01,$C5,$08,$00,$E1,$E9
        .byte   $E4,$21,$C6,$08,$01,$C6,$08,$00
        .byte   $E2,$EA,$E5,$21,$C7,$08,$01,$C7
        .byte   $08,$00,$E3,$EB,$E6,$21,$C8,$08
        .byte   $01,$C8,$08,$00,$E4,$EC,$E7,$21
        .byte   $C9,$08,$01,$C9,$08,$00,$E5,$ED
        .byte   $E8,$21,$CA,$08,$01,$C9,$08,$00
        .byte   $05,$27,$04,$01,$5E,$AA,$05,$22
        .byte   $EB,$F3,$EE,$D0,$08,$01,$01,$05
        .byte   $D0,$01,$00,$08,$00,$04,$00,$52
        .byte   $AA,$00,$06,$03,$35,$05,$22,$65
        .byte   $65,$60,$65,$65,$63,$65,$65,$80
        .byte   $85,$88,$8C,$04,$03,$AF,$AA,$66
        .byte   $66,$60,$66,$66,$64,$66,$66,$80
        .byte   $86,$89,$8D,$04,$03,$BF,$AA,$67
        .byte   $67,$60,$67,$67,$65,$67,$67,$80
        .byte   $87,$8A,$8E,$04,$03,$CF,$AA,$68
        .byte   $68,$60,$68,$68,$66,$68,$68,$80
        .byte   $88,$8B,$8F,$04,$03,$DF,$AA,$69
        .byte   $69,$60,$69,$69,$67,$69,$69,$80
        .byte   $89,$8C,$90,$04,$03,$EF,$AA,$6A
        .byte   $6A,$60,$6A,$6A,$68,$6A,$6A,$80
        .byte   $8A,$8D,$91,$04,$03,$FF,$AA,$6B
        .byte   $6B,$60,$6B,$6B,$69,$6B,$6B,$80
        .byte   $8B,$8E,$92,$04,$03,$0F,$AB,$6C
        .byte   $6C,$60,$6C,$6C,$6A,$6C,$6C,$80
        .byte   $8C,$8F,$93,$04,$03,$1F,$AB,$6D
        .byte   $6D,$60,$6D,$6D,$6B,$6D,$6D,$80
        .byte   $8D,$90,$94,$04,$03,$2F,$AB,$6E
        .byte   $6E,$60,$6E,$6E,$6C,$6E,$6E,$80
        .byte   $8E,$91,$95,$04,$03,$3F,$AB,$6F
        .byte   $6F,$60,$6F,$6F,$6D,$6F,$6F,$80
        .byte   $8F,$92,$96,$04,$03,$4F,$AB,$70
        .byte   $70,$60,$70,$70,$6E,$70,$70,$80
        .byte   $90,$93,$97,$04,$02,$5F,$AB,$70
        .byte   $70,$60,$70,$70,$6E,$70,$70,$01
        .byte   $10,$60,$7D,$7D,$7C,$7C,$7A,$7A
        .byte   $7A,$01,$00,$04,$00,$AF,$AA,$00
        .byte   $06,$03,$3F,$07,$83,$A0,$62,$62
        .byte   $07,$82,$20,$82,$04,$00,$8B,$AB
        .byte   $00,$00,$80,$00,$02,$62,$80,$00

music_stage_intro:                      ; $0A — Stage Intro ($ABA0)
        .byte   $0F,$AB,$AB,$ED,$AB,$20,$AC,$00
        .byte   $00,$50,$AC,$00,$06,$02,$00,$03
        .byte   $3A,$07,$02,$A0,$05,$23,$6D,$6D
        .byte   $6D,$60,$6D,$8B,$21,$6D,$CD,$6F
        .byte   $6F,$6F,$60,$6F,$8D,$21,$6F,$CF
        .byte   $70,$70,$60,$70,$A0,$73,$73,$60
        .byte   $73,$A0,$60,$74,$60,$21,$72,$72
        .byte   $70,$72,$73,$07,$82,$80,$54,$55
        .byte   $54,$55,$54,$55,$21,$54,$08,$01
        .byte   $07,$02,$A0,$B4,$09,$00,$06,$02
        .byte   $40,$03,$3A,$05,$17,$07,$02,$A0
        .byte   $70,$70,$70,$60,$70,$8F,$21,$70
        .byte   $D0,$72,$72,$72,$60,$72,$90,$21
        .byte   $72,$D2,$74,$74,$60,$74,$A0,$76
        .byte   $76,$60,$76,$A0,$60,$78,$60,$75
        .byte   $75,$74,$75,$75,$08,$01,$DB,$09
        .byte   $00,$06,$03,$81,$05,$23,$CD,$60
        .byte   $6D,$6D,$6D,$6D,$06,$8C,$CB,$60
        .byte   $6B,$6B,$6B,$6B,$06,$8A,$69,$69
        .byte   $60,$69,$01,$10,$60,$7D,$9D,$01
        .byte   $00,$6F,$6F,$60,$6F,$01,$10,$60
        .byte   $7D,$9D,$01,$00,$08,$01,$E8,$09
        .byte   $00,$00,$80,$00,$01,$62,$80,$00

music_boss:                             ; $0B — Boss Battle ($AC58)
        .byte   $0F,$63,$AC,$FA,$AC,$81,$AD,$C7
        .byte   $AD,$0C,$AE,$00,$06,$03,$3C,$02
        .byte   $C0,$05,$13,$07,$E0,$10,$08,$01
        .byte   $E8,$EB,$EE,$D1,$6E,$71,$74,$71
        .byte   $74,$71,$74,$77,$08,$00,$07,$86
        .byte   $20,$05,$1F,$02,$C0,$71,$71,$60
        .byte   $71,$60,$71,$71,$80,$71,$71,$60
        .byte   $71,$60,$71,$71,$07,$83,$20,$91
        .byte   $60,$71,$A0,$98,$60,$78,$96,$98
        .byte   $07,$86,$20,$6F,$6F,$60,$6F,$60
        .byte   $6F,$6F,$80,$6F,$6F,$60,$6F,$60
        .byte   $6F,$6F,$07,$83,$20,$8F,$60,$6F
        .byte   $A0,$98,$60,$78,$96,$98,$07,$86
        .byte   $20,$6E,$6E,$60,$6E,$60,$6E,$6E
        .byte   $80,$6E,$6E,$60,$6E,$60,$6E,$6E
        .byte   $07,$83,$20,$8E,$60,$6E,$A0,$98
        .byte   $60,$78,$96,$98,$07,$86,$20,$6A
        .byte   $6A,$60,$6A,$60,$6A,$6A,$80,$6A
        .byte   $6A,$60,$6A,$60,$6A,$6A,$08,$01
        .byte   $AC,$B0,$B3,$B8,$08,$00,$04,$00
        .byte   $7E,$AC,$00,$06,$03,$3B,$02,$00
        .byte   $07,$8A,$10,$05,$1F,$A5,$60,$6E
        .byte   $6B,$68,$C5,$A8,$60,$71,$6E,$6B
        .byte   $C8,$AB,$60,$74,$71,$6E,$CB,$AE
        .byte   $60,$77,$74,$6E,$D1,$05,$1F,$02
        .byte   $C0,$07,$86,$20,$6C,$6C,$60,$6C
        .byte   $60,$6C,$6C,$80,$6C,$6C,$60,$6C
        .byte   $60,$6C,$6C,$07,$83,$20,$8C,$60
        .byte   $6C,$A0,$94,$60,$74,$93,$94,$04
        .byte   $01,$1D,$AD,$02,$C0,$07,$86,$20
        .byte   $6A,$6A,$60,$6A,$60,$6A,$6A,$80
        .byte   $6A,$6A,$60,$6A,$60,$6A,$6A,$07
        .byte   $83,$20,$8A,$60,$6A,$A0,$94,$60
        .byte   $74,$93,$94,$07,$86,$20,$67,$67
        .byte   $60,$67,$60,$67,$67,$80,$67,$67
        .byte   $60,$67,$60,$67,$67,$08,$01,$A7
        .byte   $AC,$B0,$B3,$08,$00,$04,$00,$1D
        .byte   $AD,$00,$06,$03,$30,$05,$1F,$71
        .byte   $71,$71,$6F,$04,$0D,$87,$AD,$03
        .byte   $20,$01,$15,$6C,$6C,$6A,$6A,$68
        .byte   $68,$66,$66,$03,$50,$01,$00,$03
        .byte   $40,$71,$71,$60,$71,$94,$76,$71
        .byte   $60,$6F,$71,$70,$8A,$6B,$6C,$04
        .byte   $06,$9F,$AD,$6C,$6C,$78,$60,$76
        .byte   $78,$60,$6C,$60,$6C,$78,$60,$76
        .byte   $78,$74,$73,$04,$00,$9F,$AD,$00
        .byte   $06,$07,$88,$10,$03,$3F,$07,$82
        .byte   $F0,$A2,$A2,$A2,$07,$84,$10,$A7
        .byte   $04,$01,$CE,$AD,$07,$82,$A0,$83
        .byte   $83,$07,$84,$40,$87,$07,$82,$A0
        .byte   $83,$04,$02,$DC,$AD,$07,$84,$40
        .byte   $66,$66,$66,$66,$67,$67,$67,$67
        .byte   $07,$83,$D0,$62,$62,$60,$62,$07
        .byte   $84,$40,$87,$07,$82,$A0,$62,$62
        .byte   $04,$00,$F8,$AD,$00,$00,$80,$00
        .byte   $01,$62,$80,$00

music_stage_select:                     ; $0C — Stage Select ($AE14)
        .byte   $0F,$1F,$AE,$68,$AE,$9C,$AE,$D7
        .byte   $AE,$F4,$AE,$00,$05,$03,$39,$05
        .byte   $11,$07,$83,$50,$02,$80,$05,$11
        .byte   $01,$15,$9D,$9A,$80,$97,$80,$74
        .byte   $74,$94,$91,$05,$1D,$01,$00,$03
        .byte   $3B,$07,$86,$10,$02,$00,$85,$88
        .byte   $8C,$85,$88,$8F,$85,$88,$8E,$85
        .byte   $88,$8D,$85,$88,$8B,$8C,$02,$40
        .byte   $85,$88,$8C,$85,$88,$8F,$85,$88
        .byte   $8E,$85,$88,$8D,$85,$88,$8B,$8C
        .byte   $04,$00,$3B,$AE,$00,$05,$05,$1D
        .byte   $E0,$07,$86,$10,$03,$37,$02,$00
        .byte   $80,$85,$88,$8C,$85,$88,$8F,$85
        .byte   $88,$8E,$85,$88,$8D,$85,$88,$8B
        .byte   $02,$40,$03,$39,$88,$8C,$91,$88
        .byte   $8C,$93,$88,$8C,$92,$88,$8C,$91
        .byte   $88,$8C,$8E,$8F,$04,$00,$70,$AE
        .byte   $00,$05,$03,$30,$05,$1D,$01,$0F
        .byte   $9D,$9A,$80,$97,$80,$74,$74,$94
        .byte   $90,$03,$31,$85,$83,$01,$10,$9A
        .byte   $01,$00,$85,$80,$88,$01,$10,$9A
        .byte   $05,$11,$01,$00,$91,$8C,$98,$05
        .byte   $1D,$01,$10,$9A,$01,$00,$8B,$8A
        .byte   $88,$01,$10,$9A,$01,$00,$83,$04
        .byte   $00,$AD,$AE,$00,$05,$07,$83,$40
        .byte   $03,$3F,$C0,$A0,$87,$87,$07,$82
        .byte   $F0,$82,$82,$82,$82,$82,$82,$82
        .byte   $07,$84,$90,$82,$04,$00,$E2,$AE

music_title:                            ; $0D — Title (also Ending reprise) ($AEF4)
        .byte   $0F,$FF,$AE,$F9,$AF,$EC,$B0,$80
        .byte   $B1,$AC,$B1,$00,$05,$03,$3C,$02
        .byte   $00,$05,$23,$07,$9A,$10,$8D,$6D
        .byte   $6D,$8D,$6D,$6D,$8D,$8F,$80,$21
        .byte   $CB,$08,$01,$CB,$08,$00,$8B,$89
        .byte   $69,$69,$89,$86,$80,$86,$80,$C8
        .byte   $88,$89,$8B,$A0,$8D,$6D,$6D,$8D
        .byte   $6D,$6D,$8D,$8F,$80,$21,$CB,$08
        .byte   $01,$CB,$08,$00,$8B,$A9,$89,$8B
        .byte   $80,$8B,$80,$21,$8D,$08,$01,$CD
        .byte   $08,$00,$02,$80,$07,$83,$70,$05
        .byte   $2F,$74,$72,$70,$72,$70,$6F,$6E
        .byte   $6D,$04,$01,$01,$AF,$07,$84,$10
        .byte   $05,$23,$02,$C0,$8D,$8D,$88,$85
        .byte   $91,$8D,$88,$B4,$92,$91,$8F,$91
        .byte   $AD,$80,$8B,$8B,$8A,$86,$AF,$8B
        .byte   $88,$6B,$6B,$66,$6F,$6B,$72,$6F
        .byte   $77,$92,$AB,$80,$8A,$6A,$6D,$6A
        .byte   $65,$81,$04,$01,$81,$AF,$6A,$6D
        .byte   $75,$76,$75,$76,$75,$76,$71,$6D
        .byte   $80,$02,$C0,$AA,$80,$30,$81,$30
        .byte   $84,$30,$89,$30,$84,$30,$89,$30
        .byte   $8D,$30,$89,$30,$8D,$30,$90,$30
        .byte   $8D,$30,$90,$30,$95,$89,$89,$89
        .byte   $89,$80,$AB,$80,$07,$9A,$10,$02
        .byte   $00,$8D,$6D,$6D,$8D,$6D,$6D,$8D
        .byte   $8F,$80,$21,$CB,$08,$01,$CB,$08
        .byte   $00,$8B,$89,$69,$69,$89,$86,$80
        .byte   $86,$80,$C8,$88,$89,$8B,$A0,$8D
        .byte   $6D,$6D,$8D,$6D,$6D,$8D,$8F,$80
        .byte   $21,$CB,$CB,$80,$88,$88,$8A,$8D
        .byte   $80,$88,$8A,$8D,$80,$88,$8A,$8D
        .byte   $80,$94,$96,$99,$09,$00,$05,$03
        .byte   $3C,$02,$00,$05,$23,$07,$9A,$10
        .byte   $88,$68,$68,$88,$68,$68,$88,$88
        .byte   $80,$E6,$88,$84,$64,$64,$84,$83
        .byte   $80,$83,$80,$C5,$85,$84,$86,$A0
        .byte   $88,$68,$68,$88,$68,$68,$88,$88
        .byte   $80,$E6,$88,$A4,$84,$86,$80,$86
        .byte   $80,$21,$88,$C8,$02,$80,$03,$36
        .byte   $05,$2F,$07,$83,$70,$60,$74,$72
        .byte   $70,$72,$70,$6F,$6E,$04,$01,$FB
        .byte   $AF,$07,$84,$10,$05,$23,$03,$3C
        .byte   $02,$C0,$88,$03,$37,$80,$8D,$88
        .byte   $85,$91,$8D,$88,$B4,$92,$91,$8F
        .byte   $03,$3C,$A8,$80,$86,$03,$37,$80
        .byte   $8B,$8A,$86,$AF,$8B,$88,$6B,$6B
        .byte   $66,$6F,$6B,$72,$6F,$77,$03,$3C
        .byte   $A6,$80,$85,$03,$37,$60,$6A,$6D
        .byte   $6A,$65,$81,$04,$01,$7A,$B0,$6A
        .byte   $6D,$75,$76,$75,$76,$75,$76,$71
        .byte   $6D,$60,$03,$3C,$02,$C0,$A5,$80
        .byte   $30,$84,$30,$89,$30,$8D,$30,$89
        .byte   $30,$8D,$30,$90,$30,$8D,$30,$90
        .byte   $30,$95,$30,$90,$30,$95,$30,$99
        .byte   $84,$84,$84,$84,$80,$A6,$80,$07
        .byte   $9A,$10,$02,$00,$88,$68,$68,$88
        .byte   $68,$68,$88,$88,$80,$E6,$88,$84
        .byte   $64,$64,$84,$83,$80,$83,$80,$C5
        .byte   $85,$84,$86,$A0,$88,$68,$68,$88
        .byte   $68,$68,$88,$88,$80,$E6,$80,$85
        .byte   $85,$86,$88,$80,$85,$86,$88,$80
        .byte   $85,$86,$88,$80,$91,$92,$94,$09
        .byte   $00,$05,$03,$30,$05,$23,$8D,$6D
        .byte   $6D,$04,$1D,$F2,$B0,$8D,$88,$8A
        .byte   $8D,$8D,$6D,$6D,$04,$1D,$FD,$B0
        .byte   $8D,$88,$8A,$8D,$03,$30,$A5,$01
        .byte   $14,$9D,$80,$8D,$8D,$9D,$80,$8D
        .byte   $8D,$9D,$8D,$80,$01,$00,$85,$01
        .byte   $14,$9D,$9D,$01,$00,$A3,$01,$14
        .byte   $9D,$80,$8D,$8D,$9D,$80,$8D,$8D
        .byte   $9D,$8D,$80,$01,$00,$83,$01,$14
        .byte   $9D,$9D,$01,$00,$81,$80,$01,$14
        .byte   $9D,$80,$8D,$8D,$9D,$80,$8D,$8D
        .byte   $9D,$8D,$80,$01,$00,$81,$01,$14
        .byte   $9D,$9D,$01,$00,$81,$80,$01,$14
        .byte   $9D,$80,$87,$87,$BD,$7D,$7D,$9D
        .byte   $7B,$7B,$9B,$79,$79,$99,$7D,$7D
        .byte   $7B,$78,$01,$00,$8D,$6D,$6D,$04
        .byte   $17,$68,$B1,$8D,$8D,$8F,$91,$80
        .byte   $8D,$8F,$91,$80,$8D,$8F,$91,$80
        .byte   $8D,$8F,$91,$09,$00,$05,$07,$82
        .byte   $A0,$03,$3F,$82,$62,$62,$07,$84
        .byte   $80,$01,$FE,$8D,$01,$00,$07,$82
        .byte   $A0,$62,$62,$04,$3B,$87,$B1,$83
        .byte   $83,$83,$83,$80,$83,$83,$83,$80
        .byte   $83,$83,$83,$80,$83,$83,$83,$09
        .byte   $00,$00,$80,$00,$02,$62,$80,$00

music_opening:                          ; $0E — Opening ($B1B4)
        .byte   $0F,$BF,$B1,$3D,$B2,$B9,$B2,$1D
        .byte   $B3,$53,$B3,$00,$08,$05,$20,$02
        .byte   $80,$03,$3E,$07,$DF,$40,$08,$00
        .byte   $21,$AE,$06,$CE,$21,$CF,$8F,$06
        .byte   $B1,$04,$01,$C1,$B1,$AE,$B1,$B8
        .byte   $95,$96,$A0,$80,$96,$95,$93,$91
        .byte   $93,$80,$8E,$8C,$8A,$80,$8A,$89
        .byte   $8A,$21,$B1,$06,$D1,$06,$B3,$06
        .byte   $B1,$AF,$06,$B5,$06,$B3,$B1,$06
        .byte   $B5,$06,$B3,$B2,$06,$B6,$06,$B5
        .byte   $B3,$00,$07,$D6,$02,$C0,$80,$8D
        .byte   $8F,$91,$21,$B2,$B2,$92,$B1,$92
        .byte   $22,$AF,$8F,$AF,$8F,$8C,$8F,$B4
        .byte   $B2,$B1,$AF,$00,$06,$B0,$80,$90
        .byte   $90,$AF,$90,$AD,$80,$8D,$8D,$AF
        .byte   $90,$F2,$05,$38,$01,$01,$02,$00
        .byte   $03,$3F,$07,$AF,$10,$21,$F9,$F9
        .byte   $09,$00,$08,$02,$C0,$03,$3A,$07
        .byte   $8A,$30,$05,$20,$80,$91,$96,$98
        .byte   $DA,$80,$92,$96,$98,$DB,$04,$01
        .byte   $48,$B2,$96,$91,$96,$9A,$95,$91
        .byte   $95,$98,$93,$8E,$93,$96,$91,$8C
        .byte   $91,$96,$90,$8C,$90,$93,$04,$01
        .byte   $66,$B2,$D1,$91,$06,$B0,$8F,$8A
        .byte   $8F,$91,$D3,$91,$8C,$91,$93,$D5
        .byte   $92,$8E,$92,$93,$D5,$93,$8E,$93
        .byte   $95,$D6,$00,$07,$02,$80,$07,$83
        .byte   $30,$86,$8A,$8D,$82,$04,$03,$8D
        .byte   $B2,$88,$8C,$8F,$94,$04,$03,$95
        .byte   $B2,$00,$06,$89,$8D,$90,$95,$04
        .byte   $03,$9F,$B2,$E0,$05,$38,$02,$00
        .byte   $03,$3F,$01,$01,$07,$AF,$10,$21
        .byte   $F4,$F4,$01,$00,$09,$00,$08,$03
        .byte   $81,$05,$20,$06,$AA,$8A,$AA,$A0
        .byte   $04,$03,$BB,$B2,$CA,$C9,$C7,$C5
        .byte   $C4,$C7,$06,$A5,$85,$A5,$A0,$06
        .byte   $C3,$A4,$E5,$06,$C2,$A6,$E7,$03
        .byte   $50,$00,$07,$86,$86,$80,$86,$86
        .byte   $81,$86,$8A,$04,$01,$DF,$B2,$88
        .byte   $88,$80,$88,$88,$83,$88,$8C,$04
        .byte   $01,$EB,$B2,$00,$06,$89,$89,$80
        .byte   $89,$89,$84,$89,$8D,$04,$01,$F9
        .byte   $B2,$01,$15,$30,$9D,$04,$02,$07
        .byte   $B3,$30,$98,$04,$08,$0D,$B3,$03
        .byte   $8F,$05,$38,$01,$01,$21,$F5,$F5
        .byte   $09,$00,$08,$03,$3C,$07,$81,$10
        .byte   $06,$C0,$85,$80,$04,$0B,$24,$B3
        .byte   $00,$07,$07,$82,$C0,$82,$82,$82
        .byte   $82,$82,$82,$07,$83,$40,$A7,$04
        .byte   $03,$2E,$B3,$00,$06,$07,$82,$C0
        .byte   $82,$82,$82,$82,$82,$82,$07,$83
        .byte   $40,$A7,$04,$02,$41,$B3,$09,$02
        .byte   $22,$80,$00

music_game_over:                        ; $0F — Game Over ($B357)
        .byte   $0F,$62,$B3,$80,$B3,$9E,$B3,$C3
        .byte   $B3,$D1,$B3,$00,$06,$03,$3F,$02
        .byte   $00,$05,$27,$07,$AF,$10,$6C,$6C
        .byte   $60,$6C,$60,$6C,$60,$6C,$A0,$6D
        .byte   $6F,$60,$22,$71,$B1,$08,$00,$D1
        .byte   $09,$00,$06,$02,$40,$05,$27,$03
        .byte   $3F,$07,$AF,$10,$69,$69,$60,$69
        .byte   $60,$69,$60,$69,$A0,$6A,$6C,$60
        .byte   $22,$6E,$AE,$08,$00,$CE,$09,$00
        .byte   $06,$03,$30,$05,$27,$65,$65,$60
        .byte   $65,$60,$65,$60,$85,$01,$10,$7D
        .byte   $98,$01,$00,$66,$88,$03,$7F,$21
        .byte   $6A,$21,$8A,$AA,$03,$30,$01,$10
        .byte   $7D,$7B,$B7,$09,$00,$06,$07,$83
        .byte   $F0,$03,$3F,$80,$60,$82,$82,$82
        .byte   $E0,$09,$01,$62,$80,$00

music_password:                         ; $10 — Password ($B3D5)
        .byte   $0F,$E0,$B3,$23,$B4,$4F,$B4,$81
        .byte   $B4,$9E,$B4,$00,$06,$03,$3E,$02
        .byte   $C0,$05,$27,$07,$01,$70,$B1,$B1
        .byte   $30,$AF,$AF,$30,$8F,$30,$AF,$30
        .byte   $8F,$30,$A0,$08,$01,$AD,$08,$00
        .byte   $30,$8D,$30,$8D,$30,$8D,$30,$8F
        .byte   $B1,$B1,$30,$AF,$AF,$30,$8F,$30
        .byte   $AF,$30,$8F,$30,$A0,$08,$01,$AE
        .byte   $08,$00,$30,$8E,$30,$8E,$30,$8E
        .byte   $30,$8F,$04,$00,$E2,$B3,$00,$06
        .byte   $02,$40,$05,$27,$07,$01,$80,$03
        .byte   $3A,$07,$01,$80,$AA,$AA,$30,$A9
        .byte   $A9,$30,$89,$30,$A8,$30,$88,$30
        .byte   $A0,$08,$01,$A5,$08,$00,$30,$85
        .byte   $30,$85,$30,$85,$30,$8C,$04,$00
        .byte   $25,$B4,$00,$06,$03,$55,$05,$27
        .byte   $30,$A6,$30,$86,$30,$86,$30,$92
        .byte   $30,$86,$04,$01,$55,$B4,$30,$A5
        .byte   $30,$85,$30,$85,$30,$91,$30,$85
        .byte   $30,$8A,$30,$96,$30,$8A,$30,$8A
        .byte   $01,$10,$30,$9D,$30,$9A,$01,$00
        .byte   $04,$00,$55,$B4,$00,$06,$03,$3F
        .byte   $07,$82,$80,$30,$82,$30,$82,$30
        .byte   $82,$07,$85,$40,$30,$87,$07,$82
        .byte   $80,$30,$82,$30,$82,$04,$00,$88
        .byte   $B4,$00,$00,$80,$00,$01,$62,$80
        .byte   $00

music_wily_map:                         ; $11 — Dr. Wily Map ($B4A6)
        .byte   $0F,$B1,$B4,$E0,$B4,$08,$B5,$2A
        .byte   $B5,$4B,$B5,$00,$06,$03,$3E,$02
        .byte   $C0,$05,$27,$07,$A2,$20,$80,$A0
        .byte   $85,$8B,$8A,$88,$85,$80,$88,$83
        .byte   $80,$84,$80,$85,$80,$88,$87,$86
        .byte   $85,$8B,$8A,$88,$85,$88,$8B,$21
        .byte   $AE,$08,$01,$CE,$08,$00,$8A,$80
        .byte   $8C,$09,$00,$06,$06,$A0,$02,$80
        .byte   $05,$1B,$07,$01,$60,$03,$37,$01
        .byte   $FF,$B1,$AE,$B0,$AD,$AF,$AC,$AE
        .byte   $AB,$B1,$AE,$B0,$AD,$AF,$01,$00
        .byte   $08,$00,$02,$40,$A5,$80,$93,$80
        .byte   $94,$09,$00,$06,$03,$50,$05,$27
        .byte   $01,$10,$65,$65,$BD,$01,$00,$85
        .byte   $83,$85,$83,$85,$80,$85,$82,$80
        .byte   $82,$82,$82,$80,$83,$80,$85,$04
        .byte   $01,$15,$B5,$09,$00,$06,$03,$36
        .byte   $80,$A7,$03,$3A,$07,$82,$80,$83
        .byte   $83,$07,$84,$70,$87,$07,$82,$80
        .byte   $83,$04,$06,$30,$B5,$07,$84,$70
        .byte   $80,$87,$80,$87,$09,$00,$00,$80
        .byte   $00,$01,$62,$80,$00

music_boss_get:                         ; $12 — Boss Get scene (Robot Master walk-in, bank0D wily_map_normal_init) ($B553)
        .byte   $0F,$5E,$B5,$72,$B5,$00,$00,$00
        .byte   $00,$86,$B5,$00,$08,$03,$3F,$02
        .byte   $40,$07,$FF,$10,$01,$FF,$05,$2F
        .byte   $08,$01,$95,$04,$00,$60,$B5,$00
        .byte   $08,$03,$3A,$02,$40,$07,$FF,$10
        .byte   $01,$FF,$05,$2F,$08,$01,$96,$04
        .byte   $00,$74,$B5,$00,$00,$80,$00,$00
        .byte   $22,$80,$00

music_epilogue:                         ; $13 — Epilogue ($B58E)
        .byte   $0F,$99,$B5,$36,$B6,$48,$B6,$C4
        .byte   $B6,$D8,$B6,$00,$08,$05,$20,$02
        .byte   $C0,$03,$3A,$07,$DF,$40,$08,$00
        .byte   $21,$CC,$8C,$85,$88,$8C,$AF,$8D
        .byte   $AC,$06,$AA,$04,$03,$A6,$B5,$02
        .byte   $40,$CD,$06,$8D,$06,$8F,$91,$06
        .byte   $AC,$8C,$8D,$06,$AF,$D4,$94,$92
        .byte   $91,$8F,$06,$AE,$8E,$8F,$06,$B1
        .byte   $8D,$8C,$8D,$8F,$A0,$99,$98,$99
        .byte   $9B,$A0,$06,$86,$06,$8A,$8D,$D1
        .byte   $06,$91,$06,$92,$91,$CF,$8F,$06
        .byte   $B1,$02,$00,$CD,$06,$8C,$06,$8D
        .byte   $8F,$CD,$06,$8C,$06,$8D,$91,$21
        .byte   $96,$D6,$91,$71,$6F,$8D,$AF,$91
        .byte   $06,$AA,$8A,$8C,$06,$AD,$05,$14
        .byte   $96,$92,$8D,$96,$99,$94,$B8,$BE
        .byte   $9D,$BB,$07,$01,$40,$05,$20,$22
        .byte   $ED,$CD,$8D,$90,$8F,$21,$8D,$04
        .byte   $01,$15,$B6,$00,$09,$ED,$00,$0A
        .byte   $06,$A9,$89,$00,$0B,$89,$06,$AB
        .byte   $22,$E8,$07,$9F,$10,$E8,$E8,$09
        .byte   $00,$08,$02,$C0,$03,$35,$07,$DF
        .byte   $40,$05,$20,$06,$80,$04,$00,$A6
        .byte   $B5,$09,$00,$08,$03,$81,$05,$20
        .byte   $06,$AD,$8D,$CD,$06,$AD,$8D,$CD
        .byte   $04,$01,$4E,$B6,$06,$AA,$8A,$CA
        .byte   $06,$AA,$8A,$CA,$04,$01,$5A,$B6
        .byte   $06,$A6,$86,$C6,$06,$A8,$88,$C8
        .byte   $06,$A1,$81,$C1,$06,$AA,$8A,$CA
        .byte   $06,$A6,$86,$C6,$04,$01,$76,$B6
        .byte   $06,$A3,$83,$C3,$06,$A8,$88,$88
        .byte   $06,$A9,$06,$AA,$8A,$CA,$06,$A9
        .byte   $89,$C9,$06,$A8,$88,$C8,$06,$A7
        .byte   $87,$C7,$06,$A6,$86,$C6,$06,$A8
        .byte   $88,$C8,$06,$AB,$8B,$CB,$04,$01
        .byte   $A0,$B6,$06,$AA,$8A,$CA,$04,$01
        .byte   $A8,$B6,$00,$09,$06,$A9,$89,$C9
        .byte   $00,$0A,$06,$A6,$86,$00,$0B,$86
        .byte   $06,$A8,$21,$E1,$A1,$09,$00,$08
        .byte   $03,$3C,$07,$81,$10,$06,$D0,$A8
        .byte   $04,$19,$CB,$B6,$00,$09,$06,$D0
        .byte   $A8,$09,$02,$22,$80,$00

music_credits:                          ; $14 — Credits ($B6DC)
        .byte   $0F,$E7,$B6,$E5,$B7,$DE,$B8,$B6
        .byte   $B9,$E2,$B9,$00,$05,$03,$3C,$05
        .byte   $23,$07,$9A,$10,$E0,$63,$66,$6B
        .byte   $6F,$66,$6B,$6F,$72,$6B,$6F,$72
        .byte   $77,$6F,$72,$77,$7B,$A8,$E0,$C0
        .byte   $94,$94,$E0,$C0,$88,$06,$A7,$A6
        .byte   $E0,$A0,$80,$90,$90,$92,$E0,$C0
        .byte   $A6,$A7,$04,$01,$01,$B7,$A8,$A0
        .byte   $E0,$E0,$E0,$05,$17,$80,$86,$87
        .byte   $88,$8B,$6D,$6D,$80,$6B,$6B,$8D
        .byte   $80,$8B,$6D,$6D,$80,$68,$68,$8B
        .byte   $6D,$6D,$90,$6F,$6F,$8D,$6B,$6B
        .byte   $8B,$6D,$6D,$80,$6B,$6B,$8D,$80
        .byte   $8B,$6D,$6D,$80,$66,$66,$80,$66
        .byte   $66,$86,$67,$67,$88,$6B,$6B,$04
        .byte   $01,$25,$B7,$05,$23,$02,$C0,$C9
        .byte   $89,$8D,$80,$8D,$70,$6D,$69,$6D
        .byte   $70,$6D,$70,$75,$D0,$CB,$8B,$8F
        .byte   $80,$06,$B7,$B5,$B4,$B2,$C9,$89
        .byte   $8D,$80,$8D,$70,$6D,$69,$6D,$70
        .byte   $6D,$70,$75,$D0,$CB,$06,$8B,$06
        .byte   $88,$8B,$CC,$03,$38,$70,$73,$78
        .byte   $70,$73,$78,$7C,$78,$02,$00,$8D
        .byte   $6D,$6D,$8D,$6D,$6D,$8D,$8F,$80
        .byte   $EB,$8B,$89,$69,$69,$89,$86,$80
        .byte   $86,$80,$C8,$88,$89,$8B,$A0,$8D
        .byte   $6D,$6D,$8D,$6D,$6D,$8D,$8F,$80
        .byte   $EB,$8B,$85,$85,$86,$88,$80,$85
        .byte   $86,$88,$80,$85,$86,$88,$80,$03
        .byte   $3F,$85,$86,$21,$88,$E8,$94,$94
        .byte   $03,$3C,$06,$80,$94,$94,$03,$38
        .byte   $06,$80,$94,$94,$03,$35,$06,$80
        .byte   $94,$94,$03,$33,$06,$80,$94,$94
        .byte   $09,$00,$05,$03,$3C,$05,$23,$07
        .byte   $9A,$10,$E0,$66,$6B,$6F,$66,$6B
        .byte   $6F,$72,$6B,$6F,$72,$77,$6F,$72
        .byte   $77,$7B,$7E,$A5,$E0,$C0,$91,$91
        .byte   $E0,$C0,$85,$06,$A4,$A3,$E0,$A0
        .byte   $80,$8D,$8D,$8F,$E0,$C0,$A3,$A4
        .byte   $04,$01,$FF,$B7,$A5,$A0,$E0,$E0
        .byte   $E0,$80,$86,$87,$88,$8B,$6D,$6D
        .byte   $80,$6B,$6B,$8D,$80,$8B,$6D,$6D
        .byte   $80,$68,$68,$8B,$6D,$6D,$90,$6F
        .byte   $6F,$8D,$6B,$6B,$8B,$6D,$6D,$80
        .byte   $6B,$6B,$8D,$80,$8B,$6D,$6D,$80
        .byte   $66,$66,$80,$66,$66,$86,$67,$67
        .byte   $88,$6B,$6B,$04,$01,$21,$B8,$61
        .byte   $64,$69,$6D,$04,$07,$53,$B8,$63
        .byte   $66,$6B,$6F,$04,$07,$5B,$B8,$61
        .byte   $64,$69,$6D,$04,$07,$63,$B8,$63
        .byte   $66,$6B,$6F,$73,$6F,$6B,$66,$04
        .byte   $01,$6B,$B8,$64,$67,$6C,$70,$67
        .byte   $6C,$70,$73,$6C,$70,$73,$78,$70
        .byte   $73,$78,$7C,$02,$00,$07,$9A,$10
        .byte   $88,$68,$68,$88,$68,$68,$88,$88
        .byte   $80,$E6,$88,$84,$64,$64,$84,$83
        .byte   $80,$83,$80,$C5,$85,$84,$86,$A0
        .byte   $88,$68,$68,$88,$68,$68,$88,$88
        .byte   $80,$E6,$88,$88,$88,$8A,$8D,$80
        .byte   $88,$8A,$8D,$80,$88,$8A,$8D,$80
        .byte   $03,$3F,$88,$8A,$21,$8D,$ED,$99
        .byte   $99,$03,$3C,$06,$80,$99,$99,$03
        .byte   $38,$06,$80,$99,$99,$03,$35,$06
        .byte   $80,$99,$99,$03,$32,$06,$80,$99
        .byte   $99,$09,$00,$05,$03,$30,$05,$23
        .byte   $01,$10,$A0,$9D,$9A,$80,$9A,$B8
        .byte   $7D,$7D,$7D,$60,$7A,$7A,$7A,$60
        .byte   $77,$77,$77,$60,$7D,$7A,$78,$75
        .byte   $01,$00,$8B,$8D,$80,$8D,$A0,$8B
        .byte   $8D,$80,$8D,$80,$8B,$8D,$90,$01
        .byte   $10,$9D,$9D,$01,$00,$8B,$8D,$80
        .byte   $8D,$A0,$8B,$8D,$80,$8D,$80,$8B
        .byte   $8D,$90,$01,$10,$9D,$9D,$01,$00
        .byte   $86,$8B,$80,$8B,$A0,$86,$8B,$80
        .byte   $8B,$80,$86,$8B,$8F,$01,$10,$9D
        .byte   $9D,$01,$00,$86,$8B,$80,$8B,$A0
        .byte   $86,$8B,$80,$8B,$80,$86,$01,$10
        .byte   $BD,$BD,$04,$01,$FC,$B8,$8D,$80
        .byte   $9D,$8D,$80,$8D,$9D,$80,$8D,$80
        .byte   $9D,$8D,$6D,$6D,$6D,$6D,$9D,$8D
        .byte   $04,$05,$4A,$B9,$01,$00,$89,$69
        .byte   $69,$04,$07,$62,$B9,$8B,$6B,$6B
        .byte   $04,$07,$69,$B9,$89,$69,$69,$04
        .byte   $07,$70,$B9,$8B,$6B,$6B,$04,$03
        .byte   $77,$B9,$8C,$6C,$6C,$8C,$6C,$6C
        .byte   $01,$15,$7D,$7D,$7D,$7D,$7A,$7A
        .byte   $7A,$7A,$01,$00,$8D,$6D,$6D,$04
        .byte   $17,$90,$B9,$81,$81,$81,$85,$80
        .byte   $81,$81,$85,$80,$81,$81,$85,$80
        .byte   $81,$81,$85,$01,$10,$7D,$7A,$78
        .byte   $04,$04,$A7,$B9,$75,$01,$00,$85
        .byte   $85,$09,$00,$05,$07,$82,$A0,$03
        .byte   $3F,$82,$62,$62,$07,$84,$80,$01
        .byte   $FE,$8D,$01,$00,$07,$82,$A0,$62
        .byte   $62,$04,$57,$BD,$B9,$83,$83,$83
        .byte   $83,$80,$83,$83,$83,$80,$83,$83
        .byte   $83,$80,$83,$83,$83,$09,$00,$00
        .byte   $80,$00,$01,$62,$80,$00

music_stage_clear:                      ; $15 — Stage Clear ($B9EA)
        .byte   $0F,$F5,$B9,$0E,$BA,$27,$BA,$00
        .byte   $00,$4E,$BA,$00,$06,$03,$3F,$05
        .byte   $27,$07,$89,$10,$E0,$6A,$6A,$80
        .byte   $6C,$6C,$80,$6D,$6D,$80,$6F,$6D
        .byte   $6F,$06,$F1,$09,$00,$06,$03,$3F
        .byte   $05,$27,$07,$89,$10,$E0,$66,$66
        .byte   $80,$68,$68,$80,$6A,$6A,$80,$6C
        .byte   $6A,$6C,$06,$ED,$09,$00,$06,$03
        .byte   $30,$05,$27,$01,$10,$9D,$9D,$7D
        .byte   $7A,$60,$98,$98,$78,$76,$60,$73
        .byte   $60,$01,$00,$03,$81,$63,$63,$80
        .byte   $65,$65,$80,$66,$66,$80,$68,$66
        .byte   $68,$06,$E8,$09,$00,$00,$80,$00

music_wily_defeated:                    ; $16 — Wily Defeated ($BA52)
        .byte   $0F,$5D,$BA,$90,$BA,$C3,$BA,$DA
        .byte   $BA,$E9,$BA,$00,$06,$03,$3F,$02
        .byte   $00,$05,$23,$07,$AF,$10,$06,$CD
        .byte   $30,$8D,$30,$8C,$30,$8D,$06,$CF
        .byte   $30,$8F,$30,$8D,$30,$8F,$06,$D1
        .byte   $30,$91,$30,$8F,$30,$91,$D2,$30
        .byte   $92,$30,$91,$30,$92,$30,$8F,$30
        .byte   $92,$30,$96,$06,$F4,$09,$00,$06
        .byte   $02,$40,$05,$23,$03,$3F,$07,$AF
        .byte   $10,$06,$C8,$30,$88,$30,$88,$30
        .byte   $91,$06,$D4,$30,$94,$30,$92,$30
        .byte   $91,$06,$CD,$30,$8D,$30,$8C,$30
        .byte   $8D,$CF,$30,$8F,$30,$8D,$30,$8F
        .byte   $30,$8A,$30,$8F,$30,$92,$06,$F1
        .byte   $09,$00,$06,$03,$50,$05,$2F,$81
        .byte   $81,$81,$61,$61,$60,$81,$61,$81
        .byte   $81,$04,$03,$C9,$BA,$06,$E1,$09
        .byte   $00,$06,$07,$83,$F0,$03,$3F,$63
        .byte   $63,$83,$04,$0F,$DC,$BA,$09,$01
        .byte   $62,$80,$00

music_weapon_get:                       ; $17 — Weapon Get ($BAED)
        .byte   $0F,$00,$00,$00,$00,$F8,$BA,$13
        .byte   $BB,$22,$BB,$00,$05,$03,$30,$05
        .byte   $23,$01,$10,$8D,$80,$BD,$80,$6D
        .byte   $6D,$BD,$8D,$80,$BD,$6D,$6D,$6D
        .byte   $6D,$BD,$04,$00,$FE,$BA,$00,$05
        .byte   $03,$3F,$07,$82,$30,$01,$FF,$A0
        .byte   $AB,$04,$00,$1C,$BB

; =============================================================================
; SFX Data ($BB22-$BFDD)
; Per SFX: priority (hi nybble of byte 0), channel mask (lo nybble of
; byte 1), then stream data (interpreted by sound_stream_check).
; =============================================================================

sfx_time_stopper:                       ; $21 — Time Stopper ($BB22)
        .byte   $50,$0A,$02,$00,$03,$3F,$83,$8A
        .byte   $00,$06,$03,$3F,$80,$0A,$80,$35
        .byte   $00,$09,$02,$80,$01,$FF,$80,$05
        .byte   $03,$3F,$8F,$FF,$00,$09,$03,$3A
        .byte   $80,$05,$03,$3A,$01,$00,$8F,$FF
        .byte   $00,$09,$03,$36,$80,$04,$03,$37
        .byte   $8F,$FF,$00,$09,$03,$33,$80,$03
        .byte   $06

sfx_22_unused:                          ; $22 — (unused) ($BB5B)
        .byte   $A0,$0F,$02,$80,$01,$20,$03,$3F
        .byte   $80,$86,$02,$00,$01,$20,$03,$3F
        .byte   $81,$0D,$03,$7F,$01,$20,$81,$AB
        .byte   $00,$0A,$03,$3A,$02,$80,$80,$0A
        .byte   $01,$15,$80,$64,$01,$15,$80,$C9
        .byte   $01,$15,$82,$FA,$00,$3A,$02,$00
        .byte   $80,$08,$06

sfx_metal_blade:                        ; $23 — Metal Blade ($BB8E)
        .byte   $30,$0A,$02,$00,$03,$3F,$81,$AB
        .byte   $00,$03,$02,$80,$03,$3F,$80,$0A
        .byte   $04,$01,$90,$BB,$03,$38,$02,$C0
        .byte   $01,$FF,$80,$3F,$00,$10,$02,$80
        .byte   $05,$00,$00,$84,$01,$80,$07,$06

sfx_buster:                             ; $24 — Mega Buster ($BBB6)
        .byte   $30,$02,$00,$10,$02,$40,$03,$3F
        .byte   $05,$02,$44,$80,$00,$01,$E0,$81
        .byte   $0D,$06

sfx_enemy_shot:                         ; $25 — Enemy Shot ($BBC8)
        .byte   $50,$02,$00,$08,$02,$40,$03,$3F
        .byte   $01,$0F,$80,$64,$06

sfx_damage_recoil:                      ; $26 — Damage Recoil ($BBD5)
        .byte   $D0,$0A,$02,$C0,$03,$3F,$05,$02
        .byte   $A3,$80,$07,$01,$5F,$80,$71,$00
        .byte   $05,$05,$01,$43,$80,$07,$01,$5F
        .byte   $03,$3F,$80,$0A,$03,$38,$80,$64
        .byte   $00,$0D,$05,$01,$43,$80,$07,$01
        .byte   $F1,$02,$80,$80,$05,$06

sfx_quick_laser:                        ; $27 — Quick Man Laser ($BC03)
        .byte   $E0,$0A,$01,$35,$02,$00,$03,$3F
        .byte   $80,$A9,$00,$06,$03,$37,$80,$03
        .byte   $01,$FC,$05,$01,$42,$80,$00,$8F
        .byte   $FF,$00,$20,$03,$3A,$80,$04,$01
        .byte   $F9,$8F,$FF,$00,$20,$03,$3A,$80
        .byte   $04,$06

sfx_health_tick:                        ; $28 — Health/Ammo Refill Tick ($BC2D)
        .byte   $C0,$03,$05,$01,$41,$80,$00,$03
        .byte   $3F,$02,$40,$80,$6A,$00,$04,$02
        .byte   $40,$05,$01,$41,$80,$00,$03,$3F
        .byte   $80,$54,$04,$02,$2F,$BC,$06

sfx_landing:                            ; $29 — Landing ($BC4C)
        .byte   $20,$02,$00,$04,$02,$40,$01,$8B
        .byte   $03,$3F,$05,$01,$46,$82,$01,$80
        .byte   $3F,$04,$01,$4E,$BC,$06

sfx_wily_alarm:                         ; $2A — Wily Alarm ($BC62)
        .byte   $F0,$0B,$03,$3F,$81,$AB,$02,$C0
        .byte   $01,$F2,$03,$3F,$87,$F2,$00,$1F
        .byte   $03,$3F,$02,$80,$80,$04,$04,$0D
        .byte   $64,$BC,$01,$01,$80,$11,$02,$00
        .byte   $01,$01,$80,$15,$00,$7F,$02,$80
        .byte   $03,$34,$80,$0A,$8F,$FF,$8F,$FF
        .byte   $00,$1F,$80,$0A,$04,$0C,$8E,$BC
        .byte   $06

sfx_damage_hit:                         ; $2B — Damage Hit ($BC9B)
        .byte   $80,$0A,$02,$40,$03,$3F,$05,$00
        .byte   $05,$86,$07,$01,$40,$80,$0E,$00
        .byte   $15,$02,$80,$01,$4F,$03,$3F,$80
        .byte   $0F,$06

sfx_dragon_fire:                        ; $2C — Dragon Fire ($BCB5)
        .byte   $C0,$0A,$02,$C0,$01,$05,$03,$3F
        .byte   $83,$F9,$00,$02,$03,$3F,$80,$0E
        .byte   $04,$01,$B7,$BC,$02,$00,$05,$01
        .byte   $43,$80,$00,$01,$14,$82,$81,$00
        .byte   $03,$80,$0C,$01,$CA,$8F,$FF,$00
        .byte   $0C,$80,$0C,$01,$04,$8F,$FF,$00
        .byte   $12,$80,$0A,$01,$FE,$8F,$FF,$00
        .byte   $12,$80,$09,$06

sfx_deflect:                            ; $2D — Deflect ($BCF1)
        .byte   $80,$06,$03,$3F,$01,$81,$80,$1E
        .byte   $00,$04,$03,$3F,$80,$0F,$06

sfx_crash_stick:                        ; $2E — Crash Bomb Stick ($BD00)
        .byte   $70,$0A,$02,$80,$03,$3F,$01,$EF
        .byte   $80,$38,$00,$04,$02,$80,$03,$3F
        .byte   $01,$FF,$80,$08,$01,$F9,$80,$25
        .byte   $00,$04,$80,$05,$01,$EF,$80,$38
        .byte   $00,$04,$80,$0A,$06

sfx_menu_cursor:                        ; $2F — Menu Cursor ($BD25)
        .byte   $E0,$02,$00,$05,$03,$3F,$02,$C0
        .byte   $80,$86,$00,$08,$03,$3F,$05,$00
        .byte   $E0,$80,$00,$02,$40,$80,$C9,$06

sfx_teleport_in:                        ; $30 — Teleport In ($BD3D)
        .byte   $E0,$0A,$02,$C0,$01,$25,$05,$01
        .byte   $62,$82,$04,$03,$3F,$80,$4D,$00
        .byte   $04,$03,$35,$80,$05,$01,$F0,$80
        .byte   $4D,$00,$05,$03,$33,$80,$05,$06

sfx_leaf_orbit:                         ; $31 — Leaf Shield Orbit ($BD5D)
        .byte   $30,$0A,$02,$00,$03,$37,$01,$FF
        .byte   $80,$8E,$00,$02,$03,$3C,$80,$03
        .byte   $03,$38,$80,$47,$00,$06,$03,$3F
        .byte   $80,$04,$06

sfx_32_mute:                            ; $32 — silent — mutes ch 1 during boss-corridor scroll (bank0F scroll_column_setup) ($BD78)
        .byte   $E0,$02,$00,$05,$03,$3F,$02,$80
        .byte   $80,$FE,$00,$05,$81,$53,$00,$05
        .byte   $81,$93,$00,$05,$80,$7F,$06

sfx_33_unused:                          ; $33 — (unused) ($BD8F)
        .byte   $E0,$08,$00,$07,$03,$3F,$80,$0F
        .byte   $06

sfx_34_mute:                            ; $34 — (silent — mutes ch 1+3 during screen transitions) ($BD98)
        .byte   $80,$0A,$02,$80,$03,$3F,$05,$03
        .byte   $85,$81,$02,$01,$B1,$80,$B3,$00
        .byte   $06,$02,$80,$05,$03,$85,$81,$02
        .byte   $80,$09,$04,$1E,$9A,$BD,$06

sfx_skew1:                              ; $35 — Skew 1 ($BDB7)
        .byte   $30,$0A,$02,$40,$03,$3F,$01,$F6
        .byte   $80,$6A,$00,$03,$03,$34,$80,$08
        .byte   $04,$02,$B9,$BD,$06

sfx_skew2:                              ; $36 — Skew 2 ($BDCC)
        .byte   $30,$0A,$02,$40,$03,$3F,$01,$F6
        .byte   $80,$64,$00,$03,$03,$38,$80,$0A
        .byte   $04,$02,$CE,$BD,$06

sfx_skew3:                              ; $37 — Skew 3 ($BDE1)
        .byte   $30,$0A,$02,$40,$03,$3F,$01,$F1
        .byte   $80,$5F,$00,$03,$03,$38,$80,$0E
        .byte   $04,$03,$E3,$BD,$06

sfx_heat_charge:                        ; $38 — Atomic Fire Charge ($BDF6)
        .byte   $30,$0A,$02,$C0,$03,$3F,$86,$4E
        .byte   $00,$03,$02,$80,$03,$3F,$80,$0B
        .byte   $01,$02,$86,$4E,$00,$04,$02,$00
        .byte   $80,$0F,$04,$0A,$06,$BE,$06

sfx_enemy_bounce:                       ; $39 — Enemy Bounce ($BE15)
        .byte   $60,$0E,$02,$C0,$01,$B1,$03,$3F
        .byte   $05,$02,$A7,$82,$05,$81,$FC,$01
        .byte   $81,$03,$81,$81,$AB,$00,$04,$02
        .byte   $80,$80,$0D,$04,$01,$17,$BE,$06

sfx_teleport_out:                       ; $3A — Teleport Out ($BE35)
        .byte   $F0,$03,$01,$C1,$03,$3F,$80,$1A
        .byte   $00,$03,$01,$C1,$03,$3F,$80,$1E
        .byte   $04,$01,$37,$BE,$02,$80,$03,$3F
        .byte   $81,$AB,$00,$08,$03,$3F,$80,$F0
        .byte   $03,$3C,$81,$AB,$00,$08,$03,$3C
        .byte   $80,$F0,$03,$39,$81,$AB,$00,$08
        .byte   $03,$39,$80,$F0,$03,$36,$81,$AB
        .byte   $00,$08,$03,$36,$80,$F0,$03,$34
        .byte   $81,$AB,$00,$08,$03,$34,$80,$F0
        .byte   $03,$32,$81,$AB,$00,$08,$03,$33
        .byte   $80,$F0,$06

sfx_splash:                             ; $3B — Water Splash ($BE88)
        .byte   $80,$0A,$01,$60,$05,$01,$21,$82
        .byte   $05,$03,$39,$81,$FC,$00,$06,$03
        .byte   $3F,$80,$07,$01,$30,$80,$38,$00
        .byte   $17,$80,$03,$06

sfx_block_appear:                       ; $3C — Block Appear ($BEA4)
        .byte   $60,$0A,$02,$80,$03,$3F,$01,$FE
        .byte   $81,$FC,$00,$30,$03,$3F,$05,$04
        .byte   $43,$80,$00,$01,$FE,$80,$0A,$06

sfx_acid_drip1:                         ; $3D — Acid Drip 1 ($BEBC)
        .byte   $D0,$02,$00,$03,$02,$80,$01,$C1
        .byte   $03,$3F,$80,$1F,$04,$01,$BE,$BE
        .byte   $00,$08,$01,$F8,$03,$3F,$80,$3F
        .byte   $00,$08,$03,$3C,$80,$3F,$00,$08
        .byte   $03,$3A,$80,$3F,$00,$08,$03,$36
        .byte   $80,$3F,$00,$08,$03,$34,$80,$3F
        .byte   $00,$08,$03,$33,$80,$3C,$06

sfx_acid_drip2:                         ; $3E — Acid Drip 2 ($BEF3)
        .byte   $D0,$01,$00,$03,$02,$80,$01,$C1
        .byte   $03,$3F,$80,$1F,$04,$01,$F5,$BE
        .byte   $00,$08,$01,$F8,$03,$3F,$80,$3F
        .byte   $00,$08,$03,$3C,$80,$3F,$00,$08
        .byte   $03,$3A,$80,$3F,$00,$08,$03,$36
        .byte   $80,$3F,$00,$08,$03,$34,$80,$3F
        .byte   $00,$08,$03,$33,$80,$3F,$06

sfx_air_shooter:                        ; $3F — Air Shooter ($BF2A)
        .byte   $40,$0A,$02,$00,$01,$F1,$03,$3E
        .byte   $81,$7D,$00,$1D,$03,$3A,$80,$06
        .byte   $06

sfx_40_unused:                          ; $40 — (unused) ($BF3B)
        .byte   $E0,$08,$00,$04,$03,$36,$80,$04
        .byte   $04,$02,$3D,$BF,$06

sfx_death_explode:                      ; $41 — Death Explosion ($BF48)
        .byte   $F0,$03,$02,$80,$01,$2F,$03,$3F
        .byte   $80,$35,$00,$10,$02,$00,$01,$2F
        .byte   $03,$3F,$80,$3C,$03,$3C,$80,$35
        .byte   $00,$10,$03,$3C,$80,$3C,$03,$39
        .byte   $80,$35,$00,$10,$03,$39,$80,$3C
        .byte   $03,$36,$80,$35,$00,$10,$03,$36
        .byte   $80,$3C,$03,$34,$80,$35,$00,$10
        .byte   $03,$34,$80,$3C,$03,$32,$80,$35
        .byte   $00,$10,$03,$32,$80,$3C,$06

sfx_extra_life:                         ; $42 — Extra Life ($BF8F)
        .byte   $F0,$02,$00,$03,$02,$C0,$03,$3F
        .byte   $80,$64,$00,$03,$80,$59,$00,$03
        .byte   $80,$50,$00,$03,$80,$4B,$00,$03
        .byte   $80,$43,$00,$03,$80,$3C,$00,$03
        .byte   $80,$35,$00,$03,$80,$32,$00,$03
        .byte   $03,$38,$80,$64,$00,$03,$80,$59
        .byte   $00,$03,$80,$50,$00,$03,$80,$4B
        .byte   $00,$03,$80,$43,$00,$03,$80,$3C
        .byte   $00,$03,$80,$35,$00,$03,$80,$32
        .byte   $06,$00,$00,$00,$00,$00,$00,$00
        .byte   $00

; ─── padding, MMC1 reset stub ($BFE0: sei / inc $BFE1) and vectors ($BFFA) ───
        .byte   $78,$EE,$E1,$BF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$00,$00,$E0,$BF,$E0,$BF
