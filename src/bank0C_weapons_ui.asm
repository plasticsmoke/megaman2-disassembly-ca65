.segment "BANK0C"

; =============================================================================
; Bank $0C — Weapons & UI
; Weapon select handler, HUD energy bar rendering, lives display,
; password screen, and CHR-RAM tile upload routines.
; =============================================================================

        .setcpu "6502"

.include "include/hardware.inc"
.include "include/ram.inc"
.include "include/zeropage.inc"
.include "include/constants.inc"

sound_temp      := $00F4
        jmp     hud_update_main

        cmp     #$FC
        bne     :+
        jmp     weapon_cmd_fc_handler
:       cmp     #$FD
        bne     weapon_dispatch_check_fd
        jmp     password_mode_init


; =============================================================================
; weapon_dispatch_check_fd — Weapon Dispatch — route weapon/UI commands by code ($FC/$FD/$FE/$FF) ($8003)
; =============================================================================
weapon_dispatch_check_fd:  cmp     #$FE
        bne     weapon_dispatch_check_ff
        lda     #$01
        sta     hud_busy_flag
        lda     #$00
        sta     sound_slot_lo
        jmp     weapon_secondary_init

weapon_dispatch_check_ff:  cmp     #$FF
        bne     weapon_select_handler
        lda     #$01
        sta     hud_busy_flag
        lda     #$00
        sta     sound_slot_lo
        jmp     weapon_clear_display


; =============================================================================
; Weapon Selection Handler
; Processes weapon select from pause menu.
; =============================================================================
weapon_select_handler:  asl     a       ; Handle weapon selection (A = weapon index)
        tax
        lda     weapon_data_ptr_lo,x
        sta     weapon_data_lo
        lda     weapon_data_ptr_hi,x
        sta     weapon_data_hi
        ldy     #$00
        lda     ($E2),y
        tax
        and     #$0F
        beq     weapon_select_high_nybble
        lda     weapon_select_state
        and     #$0F
        sta     slot_counter
        cpx     slot_counter
        bcs     weapon_select_store_type
        rts

weapon_select_store_type:  stx     $E5   ; store weapon type in temp
        lda     weapon_select_state
        and     #$F0
        ora     slot_counter
        sta     weapon_select_state
        lda     #$01
        sta     hud_busy_flag
        lda     #$00
        sta     sound_slot_lo
        lda     #$00
        sta     frame_repeat_count
        sta     lives_timer
        lda     #$04
        sta     slot_counter
        lda     #$01
chr_ram_data_transfer:  clc              ; advance pointer to next tile data
        adc     weapon_data_lo
        sta     weapon_data_lo
        lda     #$00
        adc     weapon_data_hi
        sta     weapon_data_hi
        ldx     sound_slot_lo
        ldy     #$00
chr_ram_tile_copy:  lda     ($E2),y     ; Copy tile data to CHR-RAM shadow at $0500
        sta     chr_ram_shadow,x
        inx
        iny
        cpy     #$02
chr_ram_tile_copy_end:  bne     chr_ram_tile_copy
        .byte   $A0                     ; skip-byte: LDY# eats next byte ($0A=ASL A opcode)
chr_ram_padding_fill:  asl     a:current_weapon     ; fill padding bytes in CHR shadow
chr_ram_padding_byte:  sta     chr_ram_shadow,x
        inx
chr_ram_padding_loop:  dey
        bne     chr_ram_padding_byte
        lda     weapon_display_bits
        lsr     a
        bcs     weapon_select_advance_slot
        jsr     draw_energy_bar_template
weapon_select_advance_slot:  jsr     display_offset_next_slot
weapon_select_dec_count:  dec     $E5
        beq     weapon_select_store_palette
        lda     #$02
        jmp     chr_ram_data_transfer

weapon_select_store_palette:  ldy     #$02
        lda     ($E2),y
        sta     sound_data_ptr_lo
        iny
        lda     ($E2),y
        sta     sound_data_ptr_hi
        jsr     weapon_shift_e1_right4
        lda     #$00
        sta     hud_busy_flag
        rts

weapon_select_high_nybble:  lda     $E0  ; check high nybble path
        and     #$F0
        sta     slot_counter
        cpx     slot_counter
        bcs     weapon_select_high_store
        rts

weapon_select_high_store:  stx     $E5   ; store high nybble weapon type
        lda     weapon_select_state
        and     #$0F
        ora     slot_counter
        sta     weapon_select_state
        lda     #$01
        sta     hud_busy_flag
        lda     #$00
        sta     sound_slot_lo
        ldx     #$00
        lda     #$02
        clc
        adc     weapon_data_lo
        sta     sound_stream_lo
        txa
        adc     weapon_data_hi
        sta     sound_stream_hi
        stx     instrument_type
        stx     stream_update_flag
        ldy     #$01
        lda     ($E2),y
        and     #$0F
        tax
        ora     weapon_display_bits
        pha
        stx     weapon_display_bits
        lda     #$04
        sta     slot_counter
        lda     #$02
        sta     slot_tile_offset
weapon_select_bit_loop:  pla
        lsr     a
        pha
        bcc     weapon_bit_advance_slot
        jsr     draw_energy_bar_template
        lda     weapon_display_bits
        lsr     a
        bcs     weapon_bit_advance_slot
        jsr     weapon_check_sound_slot
weapon_bit_advance_slot:  jsr     display_offset_next_slot
        lda     #$04
        clc
        adc     slot_tile_offset
        sta     slot_tile_offset
        dec     slot_counter
        bne     weapon_select_bit_loop
        jsr     weapon_shift_e1_right4
        lda     weapon_display_bits
        sta     channel_active_flags
        pla
        lda     #$00
        sta     hud_busy_flag
        rts

weapon_cmd_fc_handler:
        iny
        sty     frame_repeat_count
        rts


; =============================================================================
; Password Screen
; =============================================================================
password_mode_init:  sty     $E8        ; Enter password screen mode
        lda     #$01
        sta     lives_animate_timer
        lda     hud_frame_counter
        and     #$01
        sta     hud_frame_counter
        rts


; =============================================================================
; weapon_secondary_init — Weapon Secondary Init — initialize weapon slots without CHR-RAM upload ($8128)
; =============================================================================
weapon_secondary_init:  lda     $E0
        and     #$0F
        sta     weapon_select_state
        lda     #$04
        sta     slot_counter
        lda     #$02
        sta     slot_tile_offset
weapon_secondary_loop:  lda     $E1
        lsr     a
        bcc     weapon_secondary_advance
        jsr     draw_energy_bar_template
        jsr     weapon_check_sound_slot
weapon_secondary_advance:  jsr     display_offset_next_slot
        lda     #$04
        clc
        adc     slot_tile_offset
        sta     slot_tile_offset
        dec     slot_counter
        bne     weapon_secondary_loop
        lda     #$00
        sta     weapon_display_bits
        sta     channel_active_flags
        lda     #$00
        sta     hud_busy_flag
        rts


; =============================================================================
; weapon_check_sound_slot — Weapon Sound Slot Check — verify APU channel availability for weapon ($816C)
; =============================================================================
weapon_check_sound_slot:  lda     $EC
        clc
        adc     #$0A
        tax
        lda     chr_ram_shadow,x
        ora     chr_ram_shadow + $01,x
        bne     weapon_sound_copy_data
        ldy     slot_counter
        ldx     slot_tile_offset
        jsr     apu_sound_control
        ldx     sound_slot_lo
        lda     chr_ram_shadow,x
        ora     chr_ram_shadow + $01,x
        bne     weapon_sound_copy_data
        rts


; =============================================================================
; weapon_clear_display — Weapon Clear Display — zero out all 4 weapon CHR-RAM slots ($8190)
; =============================================================================
weapon_clear_display:  lda     $E0       ; clear weapon display slots
        and     #$F0
        sta     weapon_select_state
        lda     #$00
        sta     frame_repeat_count
        sta     lives_timer
        lda     #$04
        sta     slot_counter
weapon_clear_loop:  lda     #$00
        ldx     sound_slot_lo
        sta     chr_ram_shadow,x
        sta     chr_ram_shadow + $01,x
        jsr     display_offset_skip
        dec     slot_counter
        bne     weapon_clear_loop
        lda     #$00
        sta     hud_busy_flag
        rts


; =============================================================================
; draw_energy_bar_template — Draw Energy Bar Template — fill 16 tiles with blank energy bar pattern ($81B3)
; =============================================================================
draw_energy_bar_template:  ldy     #$0F ; Draw empty 16-tile energy bar
        lda     #$10
        clc
        adc     sound_slot_lo
        tax
        lda     #$00
energy_bar_clear_loop:  sta     chr_ram_shadow,x
        inx
        dey
        bne     energy_bar_clear_loop
        rts


; =============================================================================
; weapon_sound_copy_data — Weapon Sound Data Copy — copy 4 bytes of instrument data to CHR buffer ($81C4)
; =============================================================================
weapon_sound_copy_data:  lda     $E5
        pha
        lda     slot_tile_offset
        pha
        lda     sound_data_ptr_lo
        sta     slot_counter
        lda     sound_data_ptr_hi
        sta     slot_tile_offset
        lda     sound_slot_lo
        clc
        adc     #$06
        tax
        lda     chr_ram_shadow,x
        and     #$1F
        beq     weapon_sound_calc_done
        tay
        lda     #$00
weapon_sound_calc_offset:  clc
        adc     #$04
        dey
        bne     weapon_sound_calc_offset
weapon_sound_calc_done:  tay
        txa
        clc
        adc     #$0E
        tax
        lda     #$04
weapon_sound_copy_loop:  pha
        lda     ($E5),y
        sta     chr_ram_shadow,x
        iny
        inx
        pla
        sec
        sbc     #$01
        bne     weapon_sound_copy_loop
        pla
        sta     slot_tile_offset
        pla
        sta     slot_counter
        rts


; =============================================================================
; display_offset_next_slot — Display Offset Next Slot — advance $EC by $1F to next weapon display slot ($8207)
; =============================================================================
display_offset_next_slot:  lsr     $E1
        bcc     display_offset_skip
        lda     weapon_display_bits
        ora     #$80
        sta     weapon_display_bits
display_offset_skip:  lda     #$1F
        clc
        adc     sound_slot_lo
        sta     sound_slot_lo
        rts

weapon_shift_e1_right4:  lsr     $E1
        lsr     weapon_display_bits
        lsr     weapon_display_bits
        lsr     weapon_display_bits
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
; HUD Update (Main)
; Called each frame to update weapon energy bars and lives display.
; =============================================================================
hud_update_main:  inc     $EA           ; Main HUD update (energy bars, lives)
        lda     hud_busy_flag
        beq     hud_init_slot_vars
        rts

hud_init_slot_vars:  ldx     #$00        ; initialize 4 HUD slot variables
        ldy     #$05
        stx     sound_slot_lo
        sty     sound_slot_hi
        lda     #$00
        sta     apu_channel_offset
        lda     #$04
        sta     active_channel_count
hud_slot_loop:  lda     #$01
        ldy     #$18
        clc
        adc     ($EC),y
        sta     ($EC),y
        lda     #$01
        ldy     #$1D
        clc
        adc     ($EC),y
        sta     ($EC),y
        lda     channel_active_flags
        lsr     a
        bcc     hud_check_pause_flag
        jsr     sound_stream_check
hud_check_pause_flag:  lda     $41
        lsr     a
        bcc     hud_check_slot_active
        jmp     hud_slot_silent_check

hud_check_slot_active:  ldy     #$00
        lda     ($EC),y
        iny
        ora     ($EC),y
        beq     hud_slot_silent_check
        lda     #$01
        ldy     #$0E
        clc
        adc     ($EC),y
        sta     ($EC),y
        jsr     sound_note_process
        jmp     hud_shift_ef_flag

hud_slot_silent_check:  lda     $EF
        lsr     a
        bcs     hud_shift_ef_flag
        ldx     apu_channel_offset
        inx
        inx
        ldy     active_channel_count
        jsr     apu_sound_control
hud_shift_ef_flag:  lsr     $EF
        bcc     hud_next_slot
        lda     channel_active_flags
        ora     #$80
        sta     channel_active_flags
hud_next_slot:  dec     $EE
        beq     hud_lives_display
        lda     #$04
        clc
        adc     apu_channel_offset
        sta     apu_channel_offset
        lda     #$1F
        clc
        adc     sound_slot_lo
        sta     sound_slot_lo
        lda     #$00
        adc     sound_slot_hi
        sta     sound_slot_hi
        jmp     hud_slot_loop

hud_lives_display:  lda     $E8          ; check lives counter display flag
        and     #$7F
        beq     hud_check_refill_timer
        cmp     hud_frame_counter
        bne     hud_check_refill_timer
        lda     hud_frame_counter
        and     #$01
        sta     hud_frame_counter
        inc     lives_animate_timer
        lda     #$10
        cmp     lives_animate_timer
        bne     hud_check_refill_timer
        lda     lives_timer
        bmi     hud_lives_reset_timer
        lda     #$00
        sta     lives_timer
hud_lives_reset_timer:  lda     #$0F
        sta     lives_animate_timer
hud_check_refill_timer:  lda     $F2     ; check refill animation timer
        beq     hud_final_shift_ef
        dec     instrument_type
hud_final_shift_ef:  lsr     $EF
        lsr     channel_active_flags
        lsr     channel_active_flags
        lsr     channel_active_flags
        rts


; =============================================================================
; hud_energy_bar_update — HUD Energy Bar Update — per-tick energy bar drain/fill animation ($82EC)
; =============================================================================
hud_energy_bar_update:  ldy     #$0C
        lda     ($EC),y
        ldy     #$02
        cpy     active_channel_count
        beq     hud_energy_store_f4
        and     #$0F
hud_energy_store_f4:  sta     sound_temp
        lda     lives_timer
        and     #$7F
        beq     hud_energy_clamp_check
        lda     lives_animate_timer
        ldy     #$02
        cpy     active_channel_count
        bne     hud_energy_check_drain
        ldx     #$0C
hud_energy_timer_add:  clc
        adc     lives_animate_timer
        dex
        bne     hud_energy_timer_add
hud_energy_check_drain:  tay
        lda     lives_timer
        bmi     hud_energy_refill_loop
        ldx     #$FF
hud_energy_drain_loop:  inx
        cpx     sound_temp
        beq     hud_energy_clamp_check
        dey
        bne     hud_energy_drain_loop
        stx     sound_temp
        jmp     hud_energy_clamp_check

hud_energy_refill_loop:  dec     sound_temp
        beq     hud_energy_clamp_check
        dey
        bne     hud_energy_refill_loop
hud_energy_clamp_check:  lda     #$02
        cmp     active_channel_count
        beq     hud_energy_check_sweep
        ldy     #$0D
        lda     ($EC),y
        tax
        and     #$7F
        beq     hud_energy_check_sweep
        iny
        cmp     ($EC),y
        beq     hud_energy_reset_counter
        iny
        lda     ($EC),y
        and     #$0F
        jmp     hud_energy_clamp_max

hud_energy_reset_counter:  lda     #$00
        sta     ($EC),y
        iny
        lda     ($EC),y
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     freq_register_hi
        txa
        bpl     hud_energy_delta_read
        lda     #$00
        sec
        sbc     freq_register_hi
        sta     freq_register_hi
hud_energy_delta_read:  lda     ($EC),y
        and     #$0F
        clc
        adc     freq_register_hi
        bpl     hud_energy_clamp_max
        lda     #$00
        jmp     hud_energy_store_result

hud_energy_clamp_max:  cmp     sound_temp
        bcc     hud_energy_store_result
        lda     sound_temp
hud_energy_store_result:  sta     sound_temp
        lda     ($EC),y
        and     #$F0
        ora     sound_temp
        sta     ($EC),y
hud_energy_check_sweep:  lda     $EF
        lsr     a
        bcs     hud_sound_sweep_init
        lda     #$0C
        sta     freq_register_hi
        jmp     hud_sound_sweep_check

hud_sound_sweep_init:  lda     #$09
        sta     freq_register_hi
        jmp     hud_sound_envelope_run


; =============================================================================
; hud_sound_sweep_check — Sound Sweep Engine — process pitch sweep and envelope for active channel ($838F)
; =============================================================================
hud_sound_sweep_check:  ldy     #$16
        lda     ($EC),y
        and     #$7F
        beq     hud_sweep_compare_slot
        ldy     #$1D
        cmp     ($EC),y
        beq     hud_sweep_reset_counter
        jmp     hud_sweep_read_current

hud_sweep_reset_counter:  lda     #$00
        sta     ($EC),y
        ldy     #$17
        lda     ($EC),y
        ldy     #$1E
        clc
        adc     ($EC),y
        beq     hud_sweep_clamp_low
        bpl     hud_sweep_store_value
hud_sweep_clamp_low:  lda     #$01
        sta     ($EC),y
        jmp     hud_sweep_negate_delta

hud_sweep_store_value:  sta     ($EC),y
        cmp     #$10
        bcc     hud_sweep_read_current
        lda     #$0F
        sta     ($EC),y
hud_sweep_negate_delta:  lda     #$00
        ldy     #$17
        sec
        sbc     ($EC),y
        sta     ($EC),y
hud_sweep_read_current:  ldy     #$1E
        lda     ($EC),y
        cmp     sound_temp
        bcs     hud_sweep_compare_slot
        sta     sound_temp
hud_sweep_compare_slot:  ldy     #$02
        cpy     active_channel_count
        beq     hud_sound_write_volume
        lda     freq_register_hi
        and     #$7F
        tay
        lda     ($EC),y
        and     #$F0
        ora     sound_temp
        sta     sound_temp
hud_sound_write_volume:  ldx     $EB
        lda     sound_temp
        sta     SQ1_VOL,x
        lda     freq_register_hi
        bpl     hud_sound_sweep_mode_b
        lda     #$90
        sta     freq_register_hi
        jmp     hud_sound_envelope_run

hud_sound_sweep_mode_b:  lda     #$09
        sta     freq_register_hi
hud_sound_envelope_run:  lda     $F5
        and     #$7F
        tay
        ldx     #$00
        lda     ($EC),y
        beq     hud_envelope_check_mode
        bpl     hud_envelope_add_delta
        dex
hud_envelope_add_delta:  iny
        clc
        adc     ($EC),y
        sta     ($EC),y
        txa
        iny
        adc     ($EC),y
        sta     ($EC),y
hud_envelope_check_mode:  lda     $F5
        bmi     hud_vibrato_check
        lda     channel_active_flags
        lsr     a
        bcc     hud_vibrato_check
        rts

hud_vibrato_check:  ldy     #$14
        lda     ($EC),y
        and     #$7F
        bne     hud_vibrato_timer_cmp
        jmp     hud_frequency_calc

hud_vibrato_timer_cmp:  ldy     #$18
        cmp     ($EC),y
        beq     hud_vibrato_reset
        jmp     hud_frequency_calc

hud_vibrato_reset:  lda     #$00
        sta     ($EC),y
        tax
        ldy     #$15
        lda     ($EC),y
        rol     a
        rol     a
        rol     a
        rol     a
        and     #$07
        sta     sound_temp
        ldy     #$19
        lda     ($EC),y
        asl     a
        bcc     hud_vibrato_apply_delta
        lda     #$00
        sec
        sbc     sound_temp
        sta     sound_temp
        dex
hud_vibrato_apply_delta:  lda     sound_temp
        clc
        ldy     #$1A
        adc     ($EC),y
        sta     ($EC),y
        iny
        txa
        adc     ($EC),y
        sta     ($EC),y
        ldy     #$15
        lda     ($EC),y
        and     #$1F
        sta     sound_temp
        ldy     #$19
        lda     ($EC),y
        clc
        adc     #$01
        sta     ($EC),y
        and     #$7F
        cmp     sound_temp
        bne     hud_frequency_calc
        lda     ($EC),y
        and     #$80
        sta     ($EC),y
        ldy     #$14
        lda     ($EC),y
        asl     a
        bcs     hud_vibrato_toggle_dir
        lda     ($EC),y
        ora     #$80
        sta     ($EC),y
        ldy     #$19
        lda     ($EC),y
        bpl     hud_vibrato_set_dir_neg
        and     #$7F
        sta     ($EC),y
        jmp     hud_frequency_calc

hud_vibrato_set_dir_neg:  ora     #$80
        sta     ($EC),y
        jmp     hud_frequency_calc

hud_vibrato_toggle_dir:  lda     ($EC),y
        and     #$7F
        sta     ($EC),y

; =============================================================================
; hud_frequency_calc — Sound Frequency Calculator — compute and write APU frequency registers ($84A9)
; =============================================================================
hud_frequency_calc:  lda     $F5
        and     #$7F
        sta     freq_register_hi
        inc     freq_register_hi
        ldy     #$1A
        lda     ($EC),y
        ldy     freq_register_hi
        clc
        adc     ($EC),y
        tax
        ldy     #$1B
        lda     ($EC),y
        inc     freq_register_hi
        ldy     freq_register_hi
        adc     ($EC),y
        tay
        lda     #$01
        cmp     active_channel_count
        bne     hud_frequency_write
        lda     #$0F
        sta     SND_CHN
        txa
        and     #$0F
        tax
        inc     freq_register_hi
        ldy     freq_register_hi
        lda     ($EC),y
        and     #$80
        sta     sound_temp
        txa
        ora     sound_temp
        tax
        ldy     #$00
hud_frequency_write:  txa
        ldx     apu_channel_offset
        inx
        inx
        sta     SQ1_VOL,x
        tya
        ldy     #$1C
        cmp     ($EC),y
        bne     hud_frequency_update_hi
        rts

hud_frequency_update_hi:  sta     ($EC),y
        ora     #$08
        sta     SQ1_SWEEP,x
        rts


; =============================================================================
; hud_sound_channel_off — Sound Channel Off — disable APU channel if not noise channel ($84FD)
; =============================================================================
hud_sound_channel_off:  ldy     #$01
        cpy     active_channel_count
        bne     hud_sound_silence_pair
        lda     #$07
        sta     SND_CHN
        rts

hud_sound_silence_pair:  lda     #$00
        ldx     apu_channel_offset
        inx
        inx
        sta     SQ1_VOL,x
        sta     SQ1_SWEEP,x
        rts


; =============================================================================
; sound_state_init_slot — Sound State Init Slot — reset envelope/sweep state for sound slot ($8516)
; =============================================================================
sound_state_init_slot:  ldy     #$14
        lda     ($EC),y
        and     #$7F
        sta     ($EC),y
        ldy     #$16
        lda     ($EC),y
        asl     a
        bcc     sound_state_clear_regs
        ldy     sound_temp
        lda     ($EC),y
        ldx     #$02
        cpx     active_channel_count
        beq     sound_state_store_value
        and     #$0F
sound_state_store_value:  ldy     #$1E
        sta     ($EC),y
sound_state_clear_regs:  ldx     #$06
        lda     #$00
        ldy     #$18
sound_state_clear_loop:  sta     ($EC),y
        iny
        dex
        bne     sound_state_clear_loop
        lda     #$FF
        ldy     #$1C
        sta     ($EC),y
        rts

sound_state_save_restore:  ldy     #$1C
        lda     ($EC),y
        pha
        jsr     sound_state_init_slot
        pla
        ldy     #$1C
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
; sound_stream_check — Sound Data Stream Interpreter — fetch and execute sound stream commands ($856D)
; =============================================================================
sound_stream_check:  lda     $F2
        bne     sound_stream_refill_check
        jmp     sound_stream_fetch

sound_stream_refill_check:  ldy     #$11
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
        lda     #$93
        sta     freq_register_hi
        jmp     hud_sound_sweep_check

sound_stream_fetch:  jsr     sound_data_read_byte ; fetch next sound command byte
        asl     a
        bcs     sound_stream_cmd_check
        jmp     sound_stream_dispatch

sound_stream_cmd_check:  txa             ; check for special command ($xF)
        and     #$0F
        cmp     #$0F
        bne     sound_stream_new_note
        jsr     sound_data_read_byte
        jmp     sound_state_save_restore

sound_stream_new_note:  and     #$07     ; extract note duration bits
        sta     sound_temp
        jsr     sound_data_read_byte
        ldy     #$11
        sta     ($EC),y
        iny
        lda     sound_temp
        sta     ($EC),y
        lda     #$13
        sta     sound_temp
        jsr     sound_state_init_slot
        jmp     hud_sound_channel_off

sound_stream_dispatch:  jsr     sound_dispatch_table
        .byte   $D3,$85,$DB,$85,$E5,$85,$F5,$85
        .byte   $0F,$86,$40,$86,$56,$86
        jsr     sound_data_read_byte    ; handler 0: set instrument type
        sta     instrument_type
        jmp     sound_stream_fetch

        jsr     sound_data_read_byte    ; handler 1: set channel output reg
        ldy     #$10
        sta     ($EC),y
        jmp     sound_stream_fetch
        jsr     sound_data_read_byte    ; handler 2: set duty/volume
        sta     sound_temp
        ldy     #$13
        lda     ($EC),y
        and     #$3F
        ora     sound_temp
        jmp     sound_cmd_store_param

        jsr     sound_data_read_byte
        ldy     #$02
        cpy     active_channel_count
        beq     sound_cmd_store_param
        sta     sound_temp
        ldy     #$13
        lda     ($EC),y
        and     #$C0
        ora     sound_temp
sound_cmd_store_param:  ldy     #$13
        sta     ($EC),y
        jmp     sound_stream_fetch

        jsr     sound_data_read_byte    ; handler 4: set stream pointer
        txa
        beq     :+
        cpx     stream_update_flag
        beq     sound_stream_skip_update
        inc     stream_update_flag
:       jsr     sound_data_read_byte
        sta     sound_temp
        jsr     sound_data_read_byte
        sta     sound_stream_hi
        lda     sound_temp
        sta     sound_stream_lo
        jmp     sound_stream_fetch

sound_stream_skip_update:
        lda     #$00
        sta     stream_update_flag
        lda     #$02
        clc
        adc     sound_stream_lo
        sta     sound_stream_lo
        lda     #$00
        adc     sound_stream_hi
        sta     sound_stream_hi
        jmp     sound_stream_fetch

        lda     #$14
        sta     sound_temp
sound_cmd_load_regs:  jsr     sound_data_read_byte
        ldy     sound_temp
        sta     ($EC),y
        inc     sound_temp
        ldy     sound_temp
        cpy     #$18
        bne     sound_cmd_load_regs
        jmp     sound_stream_fetch

        lda     sound_stream_lo
        sec
        sbc     #$01
        sta     sound_stream_lo
        lda     sound_stream_hi
        sbc     #$00
        sta     sound_stream_hi
        lda     weapon_select_state
        and     #$0F
        sta     weapon_select_state
        lda     #$00
        sta     weapon_display_bits
        lda     channel_active_flags
        and     #$FE
        sta     channel_active_flags
        ldy     #$0A
        lda     ($EC),y
        iny
        ora     ($EC),y
        bne     sound_cmd_load_instrument
        ldx     apu_channel_offset
        inx
        inx
        ldy     active_channel_count
        jsr     apu_sound_control
        ldy     #$00
        lda     ($EC),y
        iny
        ora     ($EC),y
        bne     sound_cmd_load_instrument
        rts

sound_cmd_load_instrument:  ldy     #$06
        lda     ($EC),y
        and     #$1F
        tax
        jsr     sound_instrument_load
        lda     #$0C
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
; sound_note_process — Sound Note Processing — advance note timing and trigger bar updates ($86B4)
; =============================================================================
sound_note_process:  lda     $E7         ; process note with repeat count
        beq     sound_note_tick
sound_note_repeat_loop:  pha
        jsr     sound_note_tick
        pla
        sec
        sbc     #$01
        bne     sound_note_repeat_loop
        rts

sound_note_tick:  ldy     #$05           ; tick note timer, handle double-speed
        lda     ($EC),y
        asl     a
        bcc     sound_note_check_active
        lda     hud_frame_counter
        and     #$01
        beq     sound_note_check_active
        jsr     sound_note_check_active
sound_note_check_active:  ldy     #$02
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
        ldy     #$0A
        lda     ($EC),y
        iny
        ora     ($EC),y
        bne     sound_note_goto_bar_update
        rts

sound_note_goto_bar_update:  jmp     hud_energy_bar_update


; =============================================================================
; sound_note_done — Sound Note Done — instrument/pattern fetch after note completes ($86FE)
; =============================================================================
sound_note_done:  ldy     #$05           ; end of note — fetch instrument data
        lda     ($EC),y
        and     #$7F
        sta     ($EC),y

; =============================================================================
; sound_pattern_fetch — Sound Pattern Fetch — read and dispatch instrument pattern commands ($8706)
; =============================================================================
sound_pattern_fetch:  jsr     sound_stream_read_next ; fetch pattern byte from stream
        and     #$F0
        bne     sound_pattern_cmd_20
        jmp     sound_cmd_dispatch

sound_pattern_cmd_20:  cmp     #$20
        bne     sound_pattern_cmd_30
        txa
        and     #$07
        pha
        jsr     sound_pattern_fetch
        pla
        jmp     sound_pattern_set_vol_env

sound_pattern_cmd_30:  cmp     #$30
        bne     sound_pattern_set_duty
        jmp     sound_pattern_set_loop

sound_pattern_set_duty:  txa
        rol     a
        rol     a
        rol     a
        rol     a
        and     #$07
        tay
        lda     weapon_shift_table_1,y
        jsr     sound_freq_multiply
sound_pattern_volume_dec:  ldy     #$06
        lda     ($EC),y
        and     #$E0
        beq     sound_pattern_lookup_freq
        sec
        sbc     #$20
        sta     sound_temp
        lda     ($EC),y
        and     #$1F
        ora     sound_temp
        sta     ($EC),y
        lda     channel_active_flags
        lsr     a
        bcc     sound_pattern_goto_save
        rts

sound_pattern_goto_save:  jmp     sound_state_save_restore

sound_pattern_lookup_freq:  txa
        and     #$1F
        bne     sound_pattern_noise_check
        tax
        jmp     sound_pattern_store_freq

sound_pattern_noise_check:  ldy     #$01
        cpy     active_channel_count
        bne     sound_pattern_freq_table
        ldx     #$00
        jmp     sound_pattern_store_freq

sound_pattern_freq_table:  asl     a
        ldy     #$07
        clc
        adc     ($EC),y
        sta     sound_temp
        lda     #$00
        iny
        adc     ($EC),y
        sta     freq_register_hi
        ldy     #$01
        lda     (sound_temp),y
        tax
        dey
        lda     (sound_temp),y
sound_pattern_store_freq:  ldy     #$0A
        sta     ($EC),y
        iny
        txa
        sta     ($EC),y
        ldy     #$0D
        lda     ($EC),y
        sta     sound_temp
        and     #$7F
        beq     sound_pattern_check_sweep
        jsr     sound_portamento_init
sound_pattern_check_sweep:  lda     $EF
        lsr     a
        bcc     sound_pattern_init_state
        rts

sound_pattern_init_state:  lda     #$0C
        sta     sound_temp
        jsr     sound_state_init_slot
        jmp     hud_sound_channel_off

sound_pattern_set_vol_env:  ror     a
        ror     a
        ror     a
        ror     a
        and     #$E0
        sta     sound_temp
        ldy     #$06
        lda     ($EC),y
        and     #$1F
        ora     sound_temp
        sta     ($EC),y
        rts

sound_pattern_set_loop:  lda     #$80
        ldy     #$05
        ora     ($EC),y
        sta     ($EC),y
        jmp     sound_pattern_fetch


; =============================================================================
; sound_cmd_dispatch — Sound Command Dispatch — execute pattern sub-commands via jump table ($87C0)
; =============================================================================
sound_cmd_dispatch:  jsr     sound_dispatch_table
        .byte   $D7,$87,$E1,$87,$EB,$87,$FB,$87  ; 10-entry dispatch table
        .byte   $15,$88,$5D,$88,$7A,$88,$8D,$88
        .byte   $C7,$88,$17,$89
        jsr     sound_stream_read_next  ; cmd 0: set envelope rate
        ldy     #$04
        sta     ($EC),y
        jmp     sound_pattern_fetch
        jsr     sound_stream_read_next  ; cmd 1: set noise period
        ldy     #$09
        sta     ($EC),y
        jmp     sound_pattern_fetch
        jsr     sound_stream_read_next  ; cmd 2: set duty cycle
        sta     sound_temp
        ldy     #$0C
        lda     ($EC),y
        and     #$3F
        ora     sound_temp
        jmp     sound_cmd_store_duty
        jsr     sound_stream_read_next  ; cmd 3: set envelope type
        ldy     #$02
        cpy     active_channel_count
        beq     sound_cmd_store_duty
        sta     sound_temp
        ldy     #$0C
        lda     ($EC),y
        and     #$C0
        ora     sound_temp
sound_cmd_store_duty:  ldy     #$0C
        sta     ($EC),y
        jmp     sound_pattern_fetch

        jsr     sound_stream_read_next
        txa
        beq     sound_cmd_read_note_data
        ldy     #$05
        lda     ($EC),y
        and     #$7F
        sta     sound_temp
        cpx     sound_temp
        beq     sound_cmd_skip_note
        inc     sound_temp
        lda     ($EC),y
        and     #$80
        ora     sound_temp
        sta     ($EC),y
sound_cmd_read_note_data:
        jsr     sound_stream_read_next
        pha
        jsr     sound_stream_read_next
        pla
        ldy     #$00
        sta     ($EC),y
        iny
        txa
        sta     ($EC),y
        jmp     sound_pattern_fetch

sound_cmd_skip_note:  lda     ($EC),y
        and     #$80
        sta     ($EC),y
        ldy     #$00
        lda     #$02
        clc
        adc     ($EC),y
        sta     ($EC),y
        iny
        lda     #$00
        adc     ($EC),y
        sta     ($EC),y
        jmp     sound_pattern_fetch

        jsr     sound_stream_read_next
        ldx     #$85
        ldy     #$89
        stx     sound_temp
        sty     freq_register_hi
        asl     a
        ldy     #$07
        clc
        adc     sound_temp
        sta     ($EC),y
        lda     #$00
        adc     freq_register_hi
        iny
        sta     ($EC),y
        jmp     sound_pattern_fetch

        jsr     sound_stream_read_next
        rol     a
        rol     a
        rol     a
sound_cmd_set_detune:  rol     a
        and     #$07
        tay
        .byte   $B9                     ; code/data overlap: LDA $897D,Y / JSR $8954 / JMP $8734
sound_cmd_detune_table_ref:  adc     $2089,x ; (assembled bytes reinterpreted as LDA detune_table,Y)
        .byte   $54
        .byte   $89
sound_cmd_jump_pattern:  .byte   $4C
        .byte   $34
sound_cmd_jump_target:  .byte   $87
sound_cmd_set_portamento:  jsr     sound_stream_read_next
        ldy     #$0D
        sta     ($EC),y
        pha
        jsr     sound_stream_read_next
        ldy     #$0F
        sta     ($EC),y
        pla
        sta     sound_temp
        and     #$7F
        beq     sound_cmd_portamento_done
        jsr     sound_portamento_init
sound_cmd_portamento_done:  jmp     sound_pattern_fetch

sound_portamento_init:  lda     #$00
        ldy     #$0E
        sta     ($EC),y
        lda     sound_temp
        bpl     sound_portamento_dir_up
        lda     #$0F
        jmp     sound_portamento_store

sound_portamento_dir_up:  lda     #$00
sound_portamento_store:  sta     sound_temp
        ldy     #$0F
        lda     ($EC),y
        and     #$F0
        ora     sound_temp
        sta     ($EC),y
        rts

        jsr     sound_stream_read_next  ; cmd 9: set sweep
        sta     sound_temp
        ldy     #$06
        lda     ($EC),y
        and     #$E0
        ora     sound_temp
        sta     ($EC),y
        lda     channel_active_flags
        lsr     a
        bcs     sound_cmd_volume_done
        jsr     sound_instrument_load
sound_cmd_volume_done:  jmp     sound_pattern_fetch


; =============================================================================
; sound_instrument_load — Sound Instrument Load — load 4-byte instrument data from pointer table ($88E1)
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
        ldy     #$14
sound_instrument_byte:  lda     (sound_temp,x)
        sta     ($EC),y
        iny
        cpy     #$18
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

        ldy     #$00
        lda     #$00
        sta     ($EC),y
        iny
        sta     ($EC),y
        lda     weapon_select_state
        and     #$F0
        sta     weapon_select_state
        lda     channel_active_flags
        lsr     a
        bcc     :+
        rts
:       ldx     $EB
        inx
        inx
        ldy     active_channel_count
        jmp     apu_sound_control


; =============================================================================
; sound_stream_read_next — Sound Stream Read Next — read byte from current sound stream pointer ($8935)
; =============================================================================
sound_stream_read_next:  ldy     #$00    ; read byte from ($EC) stream
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
; sound_freq_multiply — Sound Frequency Multiply — multiply frequency by duty cycle period ($8954)
; =============================================================================
sound_freq_multiply:  sta     sound_temp      ; multiply freq by period count
        lda     #$00
        sta     freq_register_hi
        ldy     #$04
        lda     ($EC),y
        tay
        lda     #$00
sound_freq_mult_loop:  clc
        adc     sound_temp
        bcc     sound_freq_mult_dec
        inc     freq_register_hi
sound_freq_mult_dec:  dey
        bne     sound_freq_mult_loop
        ldy     #$02
        sta     ($EC),y
        iny
        lda     freq_register_hi
        sta     ($EC),y
        rts


; =============================================================================
; weapon_shift_table_1 — Sound/Weapon Data Tables — frequency tables, weapon data pointers ($8978)
; =============================================================================
weapon_shift_table_1:  .byte   $00,$00,$02,$04,$08,$10,$20,$40
weapon_shift_table_2:  .byte   $00,$00,$03,$06,$0C,$18,$30,$60
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
; weapon_data_ptr_lo — Weapon Data Pointer Table — low/high bytes for each weapon's CHR data ($8AD6)
; =============================================================================
weapon_data_ptr_lo:  .byte   $D6
weapon_data_ptr_hi:  .byte   $8A,$1D,$8E,$C8,$90,$87,$94,$98
        .byte   $96,$42,$9A,$48,$9E,$91,$A1,$A8
        .byte   $A4,$60,$A9,$A0,$AB,$58,$AC,$14
        .byte   $AE,$F4,$AE,$B4,$B1,$57,$B3,$D5
        .byte   $B3,$A6,$B4,$53,$B5,$8E,$B5,$DC
        .byte   $B6,$EA,$B9,$52,$BA,$ED,$BA

; =============================================================================
; Music/Sound Pattern Data — encoded music sequences for all stages ($8A80)
; =============================================================================
        .byte   $57,$B3,$57,$B3,$57,$B3,$57,$B3
        .byte   $57,$B3
        .byte   $57,$B3
        .byte   $57,$B3,$57,$B3,$57,$B3,$22,$BB
        .byte   $5B,$BB,$8E,$BB,$B6,$BB,$C8,$BB
        .byte   $D5,$BB,$03,$BC
        .byte   $2D,$BC,$4C
        .byte   $BC,$62,$BC
        .byte   $9B,$BC,$B5,$BC,$F1,$BC,$00,$BD
        .byte   $25,$BD,$3D,$BD,$5D,$BD,$78,$BD
        .byte   $8F,$BD,$98,$BD,$B7,$BD,$CC,$BD
        .byte   $E1,$BD,$F6,$BD,$15,$BE,$35
        .byte   $BE,$88,$BE
        .byte   $A4,$BE
        .byte   $BC,$BE,$F3
        .byte   $BE,$2A,$BF
        .byte   $3B,$BF,$48,$BF,$8F,$BF,$0F,$E1
        .byte   $8A,$F1,$8B,$A9,$8C,$83,$8D,$15
        .byte   $8E,$00,$06,$03,$3D,$07,$86,$10
        .byte   $05,$17,$02,$00,$A5,$68,$60,$6C
        .byte   $60,$06,$8F,$06,$8E,$8A,$06,$8D
        .byte   $06,$8C,$88,$6A,$60,$68,$60,$65
        .byte   $63,$60,$65,$80,$73,$73,$73,$74
        .byte   $80,$73,$73,$73,$74,$06,$A0,$73
        .byte   $73,$73,$74,$60,$78,$60,$78,$76
        .byte   $60,$74,$60,$93,$04,$02,$EA,$8A
        .byte   $A5,$68,$60,$6C,$60,$06,$8F,$06
        .byte   $8E,$8A,$06,$8D,$06,$8C,$88,$6A
        .byte   $60,$68,$60,$65,$63,$60,$65,$80
        .byte   $73,$73,$73,$74,$04,$01,$37,$8B
        .byte   $A0,$76,$76,$60,$76,$60,$76,$60
        .byte   $76,$B8,$A0,$05,$23,$02,$40,$03
        .byte   $3D,$07,$92,$10,$80,$85,$8C,$8A
        .byte   $AC,$8A,$88,$8A,$8C,$80,$21,$A5
        .byte   $08,$01,$A5,$08,$00,$88,$87,$80
        .byte   $87,$80,$87,$85,$83,$21,$85,$C5
        .byte   $80,$85,$88,$8A,$80,$85,$8C,$8A
        .byte   $AC,$8A,$88,$8A,$8C,$80,$21,$A5
        .byte   $08
        .byte   $01,$A5
        .byte   $08
        .byte   $00
        .byte   $88
        .byte   $87,$80,$87,$80
        .byte   $88
        .byte   $8A
        .byte   $87,$21,$85,$21,$A5,$08,$01,$A5
        .byte   $08,$00,$80,$85,$88,$8C,$02,$C0
        .byte   $07,$A2,$10,$21,$CF,$08,$01,$CF
        .byte   $08,$00,$21,$AE,$08,$01,$AE
        .byte   $08
        .byte   $00
        .byte   $21,$AD
        .byte   $08
        .byte   $01,$AD
        .byte   $08
        .byte   $00
        .byte   $02,$80,$88,$06,$A5,$80,$85,$88
        .byte   $8A,$8B,$8C,$8B,$8C,$8A,$88,$85
        .byte   $83,$02,$C0,$21,$CF,$08,$01,$CF
        .byte   $08,$00,$21,$AE,$08,$01,$AE,$08
        .byte   $00,$21,$AD,$08,$01,$AD,$08,$00
        .byte   $02,$80,$88,$06,$A5,$80,$85,$88
        .byte   $8A,$91,$8C,$8C,$8C,$90,$93
        .byte   $96,$98
        .byte   $04,$00,$4D,$8B,$00,$06,$02,$00
        .byte   $05,$17,$07,$E0,$10,$03,$38,$80
        .byte   $A5,$68
        .byte   $60

        .byte   $6C,$60,$06

        .byte   $8F,$06,$8E
        .byte   $8A
        .byte   $06,$8D
        .byte   $06,$8C
        .byte   $88
        .byte   $6A
        .byte   $60

        .byte   $68,$60
        .byte   $65,$63
        .byte   $60

        .byte   $65,$6F,$6F,$6F,$71,$80,$6F,$6F
        .byte   $6F,$71,$A0,$80,$6F,$6F,$6F,$71
        .byte   $60,$74,$60,$74,$73,$60,$71,$60
        .byte   $8F,$04,$02,$F7,$8B,$80,$A5,$68
        .byte   $60,$6C,$60,$06,$8F,$06,$8E,$8A
        .byte   $06,$8D,$06,$8C,$88,$6A,$60,$68
        .byte   $60,$65,$63,$60,$65,$6F,$6F,$6F
        .byte   $71,$80,$6F,$6F,$6F,$71,$A0,$73
        .byte   $73,$60,$73,$60,$73,$60,$73,$B4
        .byte   $A0,$05,$23,$03,$37,$68,$6A,$60
        .byte   $68,$60,$68,$6A,$68,$67,$68,$60
        .byte   $67,$60,$67,$68,$67,$63,$65,$60
        .byte   $65,$60,$63
        .byte   $85,$63
        .byte   $65,$60
        .byte   $65,$60
        .byte   $63,$85,$04,$03
        .byte   $5E,$8C,$02
        .byte   $C0,$03
        .byte   $3A,$07,$A2
        .byte   $10,$EC
        .byte   $CB,$CA,$07
        .byte   $86
        .byte   $10,$02
        .byte   $00
        .byte   $80
        .byte   $88
        .byte   $8A
        .byte   $88
        .byte   $8C,$88,$80
        .byte   $88
        .byte   $8A
        .byte   $88
        .byte   $8C,$88,$80
        .byte   $88
        .byte   $87,$88,$04,$01,$82,$8C,$04,$00
        .byte   $5C
        .byte   $8C,$00,$06
        .byte   $03,$25,$05,$23,$03,$30
        .byte   $A5,$68
        .byte   $60

        .byte   $6C,$60,$06,$8F,$06,$8E,$8A,$06
        .byte   $8D,$06,$8C,$88,$6A,$60,$68,$60
        .byte   $65,$63,$60,$85,$60,$85,$65,$60
        .byte   $85,$65
        .byte   $60

        .byte   $85,$65,$60,$85,$65,$60,$85,$67
        .byte   $60,$87,$68,$60,$6C,$60,$A3,$04
        .byte   $02,$B1,$8C,$A5,$68,$60,$6C,$60
        .byte   $06,$8F,$06,$8E,$8A,$06,$8D,$06
        .byte   $8C,$88,$6A,$60,$68,$60,$65,$63
        .byte   $60,$85,$60,$85,$65,$60,$85,$65
        .byte   $60
        .byte   $85,$65
        .byte   $60

        .byte   $85,$63
        .byte   $63
        .byte   $60,$63,$60,$63,$60,$63,$65,$01
        .byte   $10,$78
        .byte   $78
        .byte   $67,$66,$65,$64,$63,$05,$23,$03
        .byte   $30,$01,$00
        .byte   $85,$85
        .byte   $80,$85,$65
        .byte   $68
        .byte   $60

        .byte   $6C,$60,$68,$85,$85,$85,$80,$85
        .byte   $65,$68,$60,$6C,$60
        .byte   $68
        .byte   $85,$83
        .byte   $83,$80,$83,$63,$67,$60,$6A,$60
        .byte   $67,$83,$85,$85,$80,$85,$65,$68
        .byte   $60,$6C,$60,$68,$85,$04,$01,$16
        .byte   $8D,$01,$00,$05,$23,$68,$60,$88
        .byte   $68,$60,$88,$68,$60,$88,$68,$60
        .byte   $88,$67,$60,$87,$67,$60,$87,$66
        .byte   $60,$86,$66,$60,$86,$80,$85,$87
        .byte   $85,$88
        .byte   $85,$80
        .byte   $85,$01
        .byte   $10,$9B
        .byte   $9B,$8B,$8B,$7D,$7D,$8B,$8A,$8A
        .byte   $04,$01,$4C,$8D,$04
        .byte   $00,$16,$8D,$00,$06,$07,$84,$A0
        .byte   $03,$3F
        .byte   $01,$05
        .byte   $66
        .byte   $01,$00
        .byte   $07,$82,$60,$03
        .byte   $36,$64
        .byte   $64,$64,$04,$3B,$85,$8D,$07,$81
        .byte   $10,$03
        .byte   $39,$01,$12
        .byte   $66,$66
        .byte   $60

        .byte   $66,$60,$66,$60,$66,$63,$63,$64
        .byte   $64,$65
        .byte   $65
        .byte   $66
        .byte   $66,$03
        .byte   $3E,$01,$10
        .byte   $07,$82,$A0,$A4,$07,$84,$60
        .byte   $06,$8D,$07,$82,$A0,$64,$64,$64
        .byte   $84,$07,$84,$60,$AD,$04,$07,$B2
        .byte   $8D,$07,$82
        .byte   $A0,$84
        .byte   $84,$04
        .byte   $02,$CE,$8D,$07,$84,$60,$AD,$07
        .byte   $82,$A0,$64,$60,$84,$07,$84,$60
        .byte   $AD,$04,$05,$DB,$8D,$07,$82,$A0
        .byte   $84,$84,$04,$02,$E9,$8D,$07,$84
        .byte   $60,$AD,$07,$82,$A0,$84,$84,$07
        .byte   $84,$60,$AD,$04,$03,$F6,$8D,$07
        .byte   $84,$A0,$03,$38,$83,$83,$84,$84
        .byte   $65,$65,$85,$86,$86,$04,$00,$B2
        .byte   $8D,$00,$00,$80,$00,$02,$62,$80
        .byte   $00,$0F,$28,$8E,$E8,$8E,$9D,$8F
        .byte   $79,$90,$C0,$90
        .byte   $00
        .byte   $05,$03
        .byte   $3D,$05,$19
        .byte   $02,$80
        .byte   $07,$84,$70,$01,$30,$AB,$AB,$8B
        .byte   $8D,$AB,$8B,$8B,$80,$AB,$8B,$AB
        .byte   $04,$01,$35,$8E,$01,$00,$02,$C0
        .byte   $07,$88,$10,$77,$76,$75,$74,$73
        .byte   $72,$71,$70,$6F,$6E,$6D,$6C,$6B
        .byte   $6A,$96,$80,$96,$A0,$96,$80,$96
        .byte   $02,$80,$05,$25,$03,$3C,$22,$88
        .byte   $07,$90,$10,$A8,$08,$01,$A8,$08
        .byte   $00,$88,$87,$80,$88,$80,$85,$80
        .byte   $85,$88,$80
        .byte   $AC,$21,$AA
        .byte   $08
        .byte   $01,$AA
        .byte   $08
        .byte   $00
        .byte   $AA,$88,$8C,$80,$CA
        .byte   $8A
        .byte   $88
        .byte   $06,$CA
        .byte   $80,$8A
        .byte   $06,$AC
        .byte   $AA
        .byte   $A8
        .byte   $A7,$87,$88,$87,$C5,$8A,$80,$8A
        .byte   $A0,$8A,$80,$8A,$21,$88,$04,$01
        .byte   $68,$8E,$21,$A8,$08,$01,$A8,$08
        .byte   $00,$88,$87,$80,$88,$80,$85,$80
        .byte   $85,$88,$80,$AC,$06,$CA,$80,$88
        .byte   $A3,$A5,$A7,$AA,$21,$AB,$08,$01
        .byte   $AB
        .byte   $08
        .byte   $00
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
        .byte   $93
        .byte   $80,$93,$A0,$93,$80,$93,$04,$01
        .byte   $19,$8F,$80,$05,$25,$03,$38,$02
        .byte   $80,$07,$92,$10,$08,$01,$21,$88
        .byte   $C8,$88,$87,$80,$88,$80,$85,$80
        .byte   $85,$88,$80,$AC,$06,$CA,$80,$88
        .byte   $A3,$A5,$A7,$AA,$CB,$8B,$8A,$80
        .byte   $8B,$80,$8B,$8B,$80,$A8,$8B,$08
        .byte   $00,$07
        .byte   $88
        .byte   $10,$03
        .byte   $3A,$73,$72
        .byte   $71,$70
        .byte   $6F,$6E,$6D,$6C
        .byte   $6B
        .byte   $6A
        .byte   $69,$68
        .byte   $67
        .byte   $66,$87
        .byte   $80,$87,$A0,$87,$80,$87,$04,$00
        .byte   $19,$8F
        .byte   $00
        .byte   $05,$03
        .byte   $15,$05
        .byte   $31,$01
        .byte   $10,$A0
        .byte   $A7
        .byte   $04,$05,$A5,$8F,$91
        .byte   $71,$71
        .byte   $8E,$8E,$8C
        .byte   $8C,$8A,$8A
        .byte   $01,$00
        .byte   $05,$25
        .byte   $71,$70
        .byte   $6F,$6E,$6D,$6C,$6B,$6A,$69,$68
        .byte   $67,$66,$65,$64,$83,$80,$83,$80
        .byte   $01,$10,$7D,$7D,$9D
        .byte   $9D,$9D,$01
        .byte   $00
        .byte   $21,$85
        .byte   $85,$65
        .byte   $65,$04
        .byte   $07,$D5,$8F,$86,$66,$66,$04,$06
        .byte   $DC,$8F,$86,$21,$83,$83,$63,$63
        .byte   $04,$02,$E6,$8F,$83,$21,$84,$84
        .byte   $64,$64,$04,$03,$F0,$8F,$80,$85
        .byte   $87,$85,$88,$85,$80,$83,$80,$83
        .byte   $80,$63,$63,$83,$80
        .byte   $83
        .byte   $21,$85
        .byte   $85,$65
        .byte   $65,$04
        .byte   $07,$09,$90,$86,$66,$66,$04,$06
        .byte   $10,$90
        .byte   $86,$21
        .byte   $83,$83,$63,$63,$04,$02,$1A,$90
        .byte   $83,$21,$84,$84,$64,$64,$04,$03
        .byte   $24,$90,$80,$85,$87,$85,$88
        .byte   $85,$80
        .byte   $83,$80,$83,$80,$63,$63,$83,$80
        .byte   $83,$21,$81,$81,$61,$61,$81,$81
        .byte   $04,$03,$3D,$90,$83,$63,$63,$83
        .byte   $83,$04,$03,$46,$90,$84,$64,$64
        .byte   $84,$84,$04,$03,$4F,$90,$65,$65
        .byte   $65,$60,$65,$60,$65,$65,$60,$65
        .byte   $65,$60,$65
        .byte   $65,$84
        .byte   $80,$84,$80,$01,$10,$7D,$7D,$9D
        .byte   $9D,$9D,$01,$00,$21,$85,$04,$00
        .byte   $D5,$8F,$00,$05,$01,$10,$07,$83
        .byte   $60,$03,$3D,$A0
        .byte   $AC,$04,$07,$82,$90,$07,$83,$60
        .byte   $01
        .byte   $FD,$65,$04
        .byte   $03
        .byte   $8D,$90,$68
        .byte   $04,$03,$92,$90,$6A,$6A,$6A,$6C
        .byte   $6C,$6C,$01,$10,$8C,$80,$8C,$A0
        .byte   $8C,$80,$8C,$8C,$01,$10,$07,$82
        .byte   $A0,$84,$64,$64,$07,$84,$60,$8A
        .byte   $07,$82,$A0,$64,$64,$04,$2B,$A9
        .byte   $90,$04,$00
        .byte   $88
        .byte   $90,$00
        .byte   $00
        .byte   $80,$00,$02,$41,$80,$00,$0F,$D3
        .byte   $90,$70,$92,$91,$93,$30,$94,$7F
        .byte   $94,$00,$06,$03,$3C,$07,$8A,$10
        .byte   $02,$40,$05,$17,$88,$A0,$85,$A6
        .byte   $87,$60,$68,$60,$68,$68,$60,$88
        .byte   $85,$A6,$87,$88,$88,$A0,$85,$A6
        .byte   $87,$60,$68,$60,$68,$68,$60,$88
        .byte   $85
        .byte   $86,$05
        .byte   $23,$74,$60
        .byte   $B4,$05
        .byte   $17
        .byte   $88
        .byte   $A0,$85
        .byte   $A6,$87
        .byte   $60

        .byte   $68,$60,$68,$68,$60
        .byte   $88
        .byte   $85,$05
        .byte   $23,$74,$74,$60,$74,$76,$77
        .byte   $76,$74
        .byte   $05,$17
        .byte   $88
        .byte   $A0,$85
        .byte   $A6,$A7
        .byte   $05,$23
        .byte   $74,$60,$04,$04,$21,$91,$60,$74
        .byte   $76,$77,$76,$74,$07
        .byte   $88
        .byte   $10,$6F
        .byte   $A0,$60
        .byte   $6F,$60,$B2,$91,$60,$6F,$60,$6F
        .byte   $6F,$60,$6F,$60,$6F,$60,$B2,$91
        .byte   $90,$6F,$A0,$60,$6F,$60,$B2,$91
        .byte   $60,$6F,$60,$6F,$6F,$60,$6F,$60
        .byte   $6F,$60,$80,$74,$60,$B4,$04,$01
        .byte   $2F,$91,$07,$90,$10,$03,$3D,$02
        .byte   $80,$8C,$80,$8C,$60,$6C,$6C,$60
        .byte   $6C,$60,$6C,$6A,$68
        .byte   $06,$8A
        .byte   $A8
        .byte   $A0,$88
        .byte   $8A
        .byte   $88
        .byte   $8C,$80,$8C
        .byte   $60

        .byte   $6C,$8D,$8C,$80,$22,$AF,$08,$01
        .byte   $AF,$01,$06
        .byte   $AF,$01,$00,$08,$00,$74,$60
        .byte   $B4,$8F
        .byte   $80,$8F,$60,$6F,$6F,$60,$6F,$60
        .byte   $6F,$6D,$6C,$06,$8D,$AC,$A0
        .byte   $8C
        .byte   $8D
        .byte   $8C,$8F,$80
        .byte   $8F,$60,$6F,$91,$8F,$80,$22,$B2
        .byte   $08,$01,$B2,$01,$06,$B2,$01,$00
        .byte   $08,$00,$74,$60,$B4,$94,$80,$94
        .byte   $60,$74,$74,$60,$74,$60,$74,$71
        .byte   $6F,$06,$91,$AF,$A0,$8F,$91,$8F
        .byte   $94,$80,$94,$60,$74,$96
        .byte   $94,$80
        .byte   $21,$B7
        .byte   $B7
        .byte   $01,$06
        .byte   $B7,$01,$00,$08,$00,$74,$60,$B4
        .byte   $05,$2F,$8C,$80,$8C,$60,$6C,$6C
        .byte   $60,$6C,$60,$6C,$6A,$68,$06,$8A
        .byte   $A8,$A0
        .byte   $88
        .byte   $8A
        .byte   $88
        .byte   $8C,$80,$8C
        .byte   $60

        .byte   $6C,$8D,$8C,$80,$22,$AF,$08,$01
        .byte   $8F,$AF,$08,$00,$68,$6C,$6F,$74
        .byte   $6C,$6F,$74,$78,$05,$23,$02,$40
        .byte   $03,$3C,$6F,$A0,$60,$6F,$60,$B2
        .byte   $91,$60,$6F,$60,$6F,$6F,$60,$6F
        .byte   $60,$6F,$60,$B2,$91,$90,$6F,$A0
        .byte   $60,$6F,$60,$B2,$91,$60,$6F,$60
        .byte   $6F,$6F,$60,$6F,$60,$6F,$60,$80
        .byte   $74,$60,$B4,$04,$01,$15,$92,$B1
        .byte   $91,$60,$71,$91,$AD,$91,$21,$AF
        .byte   $08
        .byte   $01,$AF,$08,$00,$6D,$60,$6D,$60
        .byte   $6D,$8F,$6F,$04,$02,$42,$92,$B1
        .byte   $91,$60,$71,$91,$B4,$91,$6F,$6F
        .byte   $60,$74,$74,$60,$78,$78,$C0,$04
        .byte   $00,$2F,$91,$09,$00,$06,$07,$8A
        .byte   $10,$02,$40,$03
        .byte   $36,$05
        .byte   $17,$60,$88,$A0,$85,$A6,$87,$60
        .byte   $68,$60,$68,$68,$60,$88,$85,$A6
        .byte   $87,$88,$88,$A0,$85,$A6,$87,$60
        .byte   $68,$60
        .byte   $68
        .byte   $68
        .byte   $60

        .byte   $88,$85,$66,$7B,$60,$BB,$60,$88
        .byte   $A0,$85,$A6,$87,$60,$68,$60,$68
        .byte   $68,$60,$88,$65,$05,$23,$6F,$6F
        .byte   $60,$6F,$73,$74,$73,$6F,$05,$17
        .byte   $60,$88,$A0,$85,$A6,$87,$60,$05
        .byte   $23,$6F,$60,$04,$04,$C0,$92,$60
        .byte   $6F,$73,$74,$73,$6F,$6C,$A0,$60
        .byte   $6C,$60,$AF,$8D,$60,$6C,$60,$6C
        .byte   $6C,$60,$6C,$60,$6C,$60,$AF,$8D
        .byte   $8D,$6C,$A0,$60,$6C,$60,$AF,$8D
        .byte   $60,$6C,$60,$6C,$6C,$60,$6C,$60
        .byte   $6C,$60,$80,$6F,$60,$AF,$04,$01
        .byte   $CC,$92,$03,$37,$07,$8D,$20,$02
        .byte   $00,$8F,$8C,$8F,$6C,$6F,$60,$94
        .byte   $60,$8F,$6C,$6F,$60,$6F,$8C,$8F
        .byte   $6C,$6F,$60,$74,$6F,$6C,$6F,$6C
        .byte   $68,$63,$8F,$8C,$8F,$6C,$6F,$60
        .byte   $94,$60,$8F,$6C,$6F,$60,$6F,$8C
        .byte   $8F,$6C,$6F,$60,$74,$07,$85,$10
        .byte   $03,$3A,$02,$40,$6F,$60,$AF,$04
        .byte   $03,$F9,$92,$6C,$A0,$60,$6C,$60
        .byte   $AF,$8D,$60,$6C,$60,$6C,$6C,$60
        .byte   $6C,$60,$6C,$60,$AF,$8D,$8D,$6C
        .byte   $A0,$60,$6C,$60,$AF,$8D,$60,$6C
        .byte   $60,$6C,$6C,$60,$6C,$60,$6C,$60
        .byte   $80,$6F,$60,$AF,$04,$01,$3A,$93
        .byte   $AD,$8D,$60,$6D,$8D,$AA,$8D,$21
        .byte   $AC,$AC,$6A,$60
        .byte   $6A
        .byte   $60

        .byte   $6A,$8C,$6C,$04,$02,$67,$93,$AD
        .byte   $8D,$60,$6D
        .byte   $8D,$B1,$8D
        .byte   $6C,$6C,$60

        .byte   $6F,$6F,$60,$74,$74,$C0,$04,$00
        .byte   $CC,$92,$09
        .byte   $00
        .byte   $06,$03
        .byte   $25,$05
        .byte   $23,$88,$80,$01,$10,$94,$01,$00
        .byte   $85,$A6,$87,$60,$68,$60,$68,$68
        .byte   $01,$10,$74,$94,$01,$00,$85,$86
        .byte   $92,$87,$93,$04,$02,$97,$93,$88
        .byte   $80,$01,$10,$94,$01,$00,$85,$A6
        .byte   $87,$88,$88,$88,$88,$88,$68,$01
        .byte   $10,$7D,$7D,$7D,$7A,$7A,$78,$78
        .byte   $01,$00
        .byte   $88
        .byte   $80,$01,$10,$94
        .byte   $01,$00
        .byte   $85,$A6
        .byte   $87,$60
        .byte   $68
        .byte   $60

        .byte   $68,$68,$01,$10,$74,$94,$01,$00
        .byte   $85,$86,$92,$87,$93,$04,$0F,$CE
        .byte   $93,$06,$86,$06,$8A,$8D,$60,$71
        .byte   $6D,$6A,$6D,$6A,$66,$65,$06,$88
        .byte   $06,$8C,$8F
        .byte   $66,$60
        .byte   $66,$60
        .byte   $66,$88
        .byte   $68
        .byte   $04,$02,$EE,$93,$06,$86,$06,$8A
        .byte   $8D,$60,$71,$6D,$6A,$6D,$6A,$66
        .byte   $65,$68,$68,$60,$6C,$6C,$60,$6F
        .byte   $6F,$01,$10,$60,$7D,$7D,$7D,$7A
        .byte   $7A,$78,$78,$01,$00,$04,$00,$CE
        .byte   $93,$00,$06,$03,$3A,$07,$83,$F0
        .byte   $A3,$07,$83,$40,$A5,$04,$0D,$34
        .byte   $94,$85,$85,$85,$85,$01,$15,$A0
        .byte   $A5,$A0,$A5,$A0,$A5,$A0,$A5,$A0
        .byte   $A5,$A0,$A5,$A0,$A5,$A0,$A5,$80
        .byte   $85,$A5,$04,$07,$48,$94,$A0,$A5
        .byte   $A0,$A5,$A0,$A5,$85,$85,$65,$65
        .byte   $60
        .byte   $65,$04,$02,$5D,$94,$A0,$A5,$A0
        .byte   $A5,$63,$63,$60,$64,$64,$60,$65
        .byte   $65,$A0,$A5,$04,$00,$48,$94,$00
        .byte   $00,$80,$00,$01,$62,$80,$00,$0F
        .byte   $92,$94,$64,$95,$1C,$96,$71
        .byte   $96,$98
        .byte   $96,$00
        .byte   $06,$02
        .byte   $00
        .byte   $03,$38
        .byte   $05,$15
        .byte   $07
        .byte   $84,$60
        .byte   $65,$65
        .byte   $71,$65
        .byte   $6F,$70,$65,$71,$65,$6C,$65,$6B
        .byte   $65,$6A,$69,$68,$65,$65,$6F,$65
        .byte   $6D,$6E,$65,$6F,$65,$6A,$65,$69
        .byte   $65,$68,$67,$66,$04,$02,$9D,$94
        .byte   $65,$65,$71,$65,$6F,$70,$65,$71
        .byte   $65,$6C,$65,$6B,$65,$6A,$69,$68
        .byte   $6F,$6F,$60
        .byte   $6C,$71,$71

        .byte   $60,$6C,$6C,$6F,$6C,$71,$A0,$03
        .byte   $3A,$07,$02,$A0,$05,$21,$02,$40
        .byte   $21,$AC,$AC,$6C,$60,$6C,$60,$6C
        .byte   $6A,$68,$21,$AA,$AA,$6A,$6A,$60
        .byte   $6C,$60,$6A,$67,$60,$88,$02,$80
        .byte   $65,$68,$6C,$71,$60,$6C,$60,$6A
        .byte   $6C,$60
        .byte   $6A
        .byte   $60

        .byte   $63,$65,$67,$71,$60,$71,$73,$74
        .byte   $78,$60,$71,$60,$6C,$6F,$71,$74
        .byte   $73,$71,$6F,$02,$40,$21,$AC,$AC
        .byte   $6C,$60,$6C,$60,$6C,$6A,$68,$21
        .byte   $AA,$AA
        .byte   $6A
        .byte   $6A
        .byte   $60

        .byte   $6C,$60,$6A

        .byte   $67,$60,$88,$02,$80,$65,$68,$6C
        .byte   $71,$60,$6C,$60,$6A,$6C,$60,$6A
        .byte   $60,$63,$65,$67,$02,$80,$73,$73
        .byte   $60,$71,$74,$74,$60,$71,$71,$73
        .byte   $71,$74,$80,$60,$05,$15,$02,$00
        .byte   $07,$84,$60,$21,$6C,$04,$00,$94
        .byte   $94,$00,$06,$07,$84,$60,$02,$80
        .byte   $03,$37,$05,$13,$01,$25,$6C,$6C
        .byte   $9D,$6C,$9D,$6C,$60,$7D,$9A,$7D
        .byte   $7C,$7A,$78,$04,$06,$6F,$95,$7D
        .byte   $7D,$60,$7C,$7C,$7C,$60,$7A,$7D
        .byte   $7C,$7A,$78,$60,$7C,$7C,$60,$01
        .byte   $00,$05,$21,$03,$36,$07,$02,$A0
        .byte   $02,$40,$21,$A8,$A8,$68,$60,$68
        .byte   $60,$68,$67,$65,$21,$A7,$A7,$67
        .byte   $67,$60,$68,$60,$67,$63,$60,$85
        .byte   $02,$80,$03,$36,$60,$65,$68,$6C
        .byte   $71,$60,$6C,$60,$6A,$6C,$60,$6A
        .byte   $60,$63,$65,$67,$71,$60,$71,$73
        .byte   $74,$78,$60,$71,$60,$6C,$6F,$71
        .byte   $74,$73,$71,$02,$40,$21,$A8,$A8
        .byte   $68,$60,$68,$60,$68,$67,$65,$21
        .byte   $A7,$A7,$67,$67,$60,$68,$60,$67
        .byte   $63,$60,$85,$02,$80,$60,$03,$36
        .byte   $65,$68,$6C,$71,$60,$6C,$60,$6A
        .byte   $6C,$60,$6A,$60,$63,$65,$03,$3A
        .byte   $02,$80,$6F,$6F,$60,$6C,$71,$71
        .byte   $60,$6C,$6C,$6F,$6C,$71,$A0,$05
        .byte   $15,$03,$38,$02,$40,$04,$00,$66
        .byte   $95,$00,$06,$03,$1A,$05,$21,$65
        .byte   $65,$71,$65,$6F,$70,$65,$71,$65
        .byte   $6C,$65,$6B,$65,$6A,$69,$68,$65
        .byte   $65,$6F,$65,$6D
        .byte   $6E,$65,$6F
        .byte   $65,$6A
        .byte   $65,$69
        .byte   $65,$68
        .byte   $67,$66,$04,$02,$22,$96,$65,$65
        .byte   $71,$65,$6F,$70,$65,$71,$65,$6C
        .byte   $65,$6B,$65,$6A,$69,$68,$6F,$6F
        .byte   $60,$6C,$71
        .byte   $71,$60
        .byte   $6C,$6C,$6F

        .byte   $6C,$71,$01,$10,$60,$7D,$7A,$01
        .byte   $00,$21
        .byte   $65,$03
        .byte   $30,$04
        .byte   $00
        .byte   $22,$96
        .byte   $00
        .byte   $06,$03
        .byte   $3F,$07,$83,$A0,$62,$03,$3A,$07
        .byte   $82,$A0,$62,$62,$62,$04,$1B,$73
        .byte   $96,$07,$83
        .byte   $A0,$6A
        .byte   $8A
        .byte   $6A
        .byte   $6A
        .byte   $8A
        .byte   $6A
        .byte   $6A
        .byte   $6A
        .byte   $6A
        .byte   $8A
        .byte   $6A
        .byte   $8A
        .byte   $04,$00,$73,$96,$0F,$A3,$96,$CF
        .byte   $97,$F0,$98,$17,$9A,$3A,$9A,$00
        .byte   $05,$03,$3C,$02,$00,$05,$1D,$07
        .byte   $92,$10,$AC,$8F,$AE,$AD
        .byte   $AC,$AF,$AE
        .byte   $AD,$80,$21
        .byte   $AC,$08,$01
        .byte   $AC,$08,$00
        .byte   $8C,$8A,$88
        .byte   $A7,$88,$8A,$A3
        .byte   $85,$87
        .byte   $85,$A0
        .byte   $8F,$AE,$AD,$AC,$AF,$AE,$AD,$80
        .byte   $21,$AC,$08,$01,$AC,$08,$00,$8C
        .byte   $8A,$88,$A7,$88,$8A,$A3,$85,$87
        .byte   $85,$02,$80,$07,$84,$10,$80,$85
        .byte   $87,$85
        .byte   $88
        .byte   $85,$8A
        .byte   $85,$07
        .byte   $90,$10
        .byte   $02,$C0,$05,$29,$87,$87,$87,$87
        .byte   $87,$87,$80,$05,$1D,$07,$92,$10
        .byte   $21,$B1
        .byte   $08
        .byte   $01,$B1
        .byte   $08
        .byte   $00
        .byte   $8C,$8F,$91,$80,$91,$80,$B1,$8C
        .byte   $AF,$B0,$06,$B1,$AF,$06,$B1,$D8
        .byte   $91
        .byte   $B0,$CF
        .byte   $8A
        .byte   $8C,$8F,$80
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
        .byte   $8F,$91,$94,$80,$98,$80
        .byte   $21,$B6
        .byte   $96,$96
        .byte   $93,$80,$22,$B8,$08,$01,$B8,$98
        .byte   $08,$00,$03,$3E,$02,$00,$8C,$A8
        .byte   $8A,$04,$00,$A5,$96,$00,$05,$03
        .byte   $3C,$02,$00,$05,$1D,$07,$92,$10
        .byte   $A8,$8C,$AB,$AA,$A8,$AC,$AB,$AA
        .byte   $80,$C8,$88,$87,$85,$A3,$85,$87
        .byte   $05,$11,$AC,$8C,$8F,$8C,$05,$1D
        .byte   $A0,$8C,$AB,$AA,$A8,$AC,$AB,$AA
        .byte   $80,$C8,$88,$87,$85,$A3
        .byte   $85,$87
        .byte   $05,$11
        .byte   $AC,$8C,$8F
        .byte   $8C,$05,$1D
        .byte   $03,$38,$02,$80,$07,$84,$10,$60
        .byte   $80,$85,$87
        .byte   $85,$88
        .byte   $85,$8A
        .byte   $65,$07
        .byte   $90,$10
        .byte   $02,$C0,$03,$3C,$05,$29,$83,$83
        .byte   $83,$83,$83,$84,$80,$05,$1D,$07
        .byte   $92,$10,$03,$38,$80,$D1
        .byte   $8C,$8F,$91
        .byte   $80,$91,$80,$B1,$8C,$AF,$B0,$06
        .byte   $B1,$AF,$06,$B1,$D8,$91
        .byte   $B0,$CF
        .byte   $8A
        .byte   $8C,$8F,$80
        .byte   $8F,$80,$8F,$8D,$8F,$80,$93,$91
        .byte   $8F,$06,$AF,$AA,$06,$AC,$80,$8F
        .byte   $8F,$93,$93,$80,$B4,$80,$8F,$8C
        .byte   $91,$93,$91,$94,$96,$05,$29,$6B
        .byte   $8C,$8F,$6C,$6F,$70,$71,$74,$73
        .byte   $71,$6F,$70,$71,$6F,$06,$AC,$06
        .byte   $AA,$A8,$80,$06,$A7,$A5,$A3,$69
        .byte   $21,$6A,$AA,$6E,$21,$6F,$AF,$75
        .byte   $22,$76,$D6,$B3,$92,$91,$8F,$6D
        .byte   $6C,$6D,$6F
        .byte   $71,$6F
        .byte   $71,$73
        .byte   $74,$73,$74,$76,$78,$76,$78,$79
        .byte   $01,$01,$DE,$01,$00,$05,$1D
        .byte   $94,$93
        .byte   $07,$92,$10,$02,$80,$8D,$80,$8D
        .byte   $8D,$8C,$AD,$A0
        .byte   $8D,$80,$8D
        .byte   $8C,$8D,$8F
        .byte   $80,$94,$80,$02,$00,$80,$93,$93
        .byte   $93,$B4,$80
        .byte   $02,$80,$06,$80,$BB,$B9,$06,$98
        .byte   $8D,$80,$8D,$8D,$8C,$AD,$A0,$8D
        .byte   $80
        .byte   $8D,$8C,$8D
        .byte   $8F,$80,$94,$80,$93,$93,$93,$80
        .byte   $96,$93,$80,$D8,$03,$3E,$87,$A5
        .byte   $87,$04,$00,$D1,$97,$00,$05,$03
        .byte   $31,$05,$1D,$91,$80,$01,$10,$9D
        .byte   $01,$00,$8C
        .byte   $8F,$91,$01,$10,$9D,$01,$00,$91
        .byte   $80,$91,$01,$10,$9D,$01,$00,$8C
        .byte   $83,$8F,$01,$10,$9D,$01,$00,$91
        .byte   $8D,$80,$01,$10,$9D,$01
        .byte   $00,$8D
        .byte   $88
        .byte   $8D,$01,$10
        .byte   $9D,$01,$00
        .byte   $AC,$8C,$01
        .byte   $10,$9D
        .byte   $01,$00
        .byte   $AF,$8F,$01,$10
        .byte   $9D,$01,$00
        .byte   $21,$91
        .byte   $04
        .byte   $01,$F6
        .byte   $98
        .byte   $91,$80
        .byte   $01,$10
        .byte   $B8
        .byte   $81,$81
        .byte   $B8
        .byte   $01,$00
        .byte   $8D,$8D,$8D
        .byte   $8D,$8D,$8F
        .byte   $80,$21,$91,$91,$80,$01,$10,$9D
        .byte   $01,$00,$8C,$8F,$91
        .byte   $01,$10
        .byte   $9D,$01,$00
        .byte   $91,$80
        .byte   $91,$01
        .byte   $10,$9D
        .byte   $01,$00
        .byte   $8C,$83,$90
        .byte   $01,$10
        .byte   $9D,$01,$00
        .byte   $90,$91
        .byte   $80,$01,$10,$9D,$01,$00,$8C,$8F
        .byte   $91,$01,$10,$9D,$01,$00,$91,$80
        .byte   $91,$01,$10,$9D
        .byte   $01,$00
        .byte   $8C,$83,$90
        .byte   $01,$10
        .byte   $9D,$01,$00
        .byte   $90,$8F
        .byte   $80,$01,$10,$9D,$01,$00,$8A,$8D
        .byte   $8F
        .byte   $01,$10
        .byte   $9D
        .byte   $01,$00
        .byte   $8F,$80,$8F,$01,$10
        .byte   $9D,$01,$00
        .byte   $8A
        .byte   $81,$8D
        .byte   $01,$10
        .byte   $9D,$01,$00
        .byte   $8E,$8F,$80
        .byte   $01,$10
        .byte   $9D,$01,$00
        .byte   $8A
        .byte   $8D,$8F,$01
        .byte   $10,$9D
        .byte   $01,$00
        .byte   $8F,$80,$8F,$01,$10,$9D,$01,$00
        .byte   $8A,$01,$10,$9D,$BD,$9D,$01,$00
        .byte   $04,$01,$4C,$99,$80,$8D,$01,$10
        .byte   $9D,$01,$00,$94,$8D,$01,$10,$7F
        .byte   $7F,$BD,$01,$00,$8D,$80,$01,$10
        .byte   $9D,$01,$00,$88,$8D,$91,$01,$10
        .byte   $9D,$01,$00,$8F,$80,$8F,$01,$10
        .byte   $9D,$01,$00,$96,$8F,$01,$10,$7F
        .byte   $7F,$BD,$01,$00,$8F,$8F,$01,$10
        .byte   $9D,$01,$00,$8F,$80,$8F,$01,$10
        .byte   $9D,$01,$00,$8D,$04,$01,$CF,$99
        .byte   $04,$00,$F4,$98,$00,$05,$07,$82
        .byte   $60,$03,$38,$85,$85,$07,$84,$40
        .byte   $8A,$07,$82,$60,$03,$36,$85,$85
        .byte   $85,$07,$84,$40,$8A,$03,$3D,$07
        .byte   $83,$40,$85,$04,$00,$19,$9A,$00
        .byte   $00,$80,$00,$01,$82,$80,$00,$0F
        .byte   $4D,$9A,$2E,$9B,$5A,$9C,$58,$9D
        .byte   $40,$9E,$00,$06,$03,$3C,$02,$C0
        .byte   $07,$8A,$10,$05,$1D,$21,$A5,$08
        .byte   $01
        .byte   $D5,$08
        .byte   $00
        .byte   $65,$6C,$60,$6A,$60,$06,$88,$8A
        .byte   $68,$21,$65,$A5,$63,$63,$60,$22
        .byte   $65,$85,$08,$01,$A5,$08,$00,$67
        .byte   $60,$88,$60,$21,$65,$A5,$B4,$B6
        .byte   $74,$60,$74,$60,$B6,$04,$01,$4F
        .byte   $9A,$71,$71,$6F,$60,$71,$60,$6F
        .byte   $60,$B1,$8C,$8F,$80,$21,$B1
        .byte   $08
        .byte   $01,$B1
        .byte   $08
        .byte   $00
        .byte   $80,$71,$06,$98,$B6,$80,$94,$93
        .byte   $60,$21,$74,$94,$93,$21,$B1,$08
        .byte   $01,$B1,$08,$00,$80,$8C,$8F,$90
        .byte   $71,$71,$6F,$60,$71,$60,$6F,$60
        .byte   $B1,$8C,$8F,$80,$21,$B1,$08,$01
        .byte   $B1,$08,$00,$80,$71,$06,$98,$B6
        .byte   $80,$94,$93,$60,$21,$74,$94,$93
        .byte   $80,$74,$60,$93,$60,$74,$A0,$71
        .byte   $06,$98,$B6,$B4,$B3,$74,$06,$96
        .byte   $71,$60,$71,$60,$71
        .byte   $06,$8F
        .byte   $B1,$71
        .byte   $06,$98
        .byte   $B6,$B4
        .byte   $B3,$74,$76,$60,$78,$60,$98,$60
        .byte   $78,$76,$74,$76,$74,$73,$74,$73
        .byte   $71,$73,$71,$6F,$B6,$B4,$B3,$74
        .byte   $06,$96,$71,$60,$71,$60,$71,$06
        .byte   $8F,$B1,$71,$06,$98,$B6,$B4,$B3
        .byte   $74,$76,$60,$78,$60,$78,$78,$60
        .byte   $78,$60,$78,$60,$06,$98,$6C,$6C
        .byte   $06,$8F,$04,$00,$4F,$9A,$00,$06
        .byte   $03,$3A,$05,$29,$02,$00,$07,$86
        .byte   $10,$65,$68,$6C,$60,$65,$80,$65
        .byte   $67,$68,$67,$65,$60,$65,$63,$21
        .byte   $65,$04,$02,$30,$9B,$03,$3C,$02
        .byte   $C0,$07,$8A,$10,$05,$1D,$A5,$A7
        .byte   $65,$60
        .byte   $65,$60
        .byte   $A7,$05,$29,$03,$3A,$02,$00,$07
        .byte   $86,$10,$65,$68,$6C,$60,$65,$80
        .byte   $65,$67,$68,$67,$65,$60,$65,$63
        .byte   $21,$65,$04,$02,$5D,$9B,$03,$3C
        .byte   $02,$C0,$07,$8A,$10,$05,$1D,$A5
        .byte   $A7,$65,$60
        .byte   $65,$60
        .byte   $A7,$05,$29,$03,$38,$02,$00,$07
        .byte   $86,$10,$65,$65,$65,$60,$65,$80
        .byte   $65,$67,$68,$67,$65,$60,$65,$63
        .byte   $21,$65,$04,$01,$8A,$9B,$03,$3C
        .byte   $02,$C0,$07,$8A,$10,$05,$1D,$B1
        .byte   $80,$91,$8A,$60,$21,$8C,$6C,$8A
        .byte   $B4,$93,$60,$74,$60,$06,$94,$93
        .byte   $93,$05,$29,$03,$38,$02,$00,$07
        .byte   $86,$10,$65,$65,$65,$60,$65,$80
        .byte   $65,$67,$68,$67,$65,$60,$65,$63
        .byte   $21,$65,$04,$01,$C2,$9B,$03,$3C
        .byte   $02,$C0,$07,$8A,$10,$05,$1D,$B1
        .byte   $80,$91,$8A,$60,$21,$8C,$6C,$8A
        .byte   $74,$60,$74,$60,$83,$63,$02,$00
        .byte   $01,$44,$08,$01,$21,$7F,$DF,$01
        .byte   $00,$08,$00,$03,$39,$80,$B6,$B4
        .byte   $B3,$74,$76,$74,$60,$74,$60,$74
        .byte   $06,$93,$B4,$80,$71,$06,$98,$B6
        .byte   $B4,$B3,$74,$76,$60,$78,$60,$98
        .byte   $60,$78,$76,$74,$76,$74,$73,$74
        .byte   $73,$71,$73,$71,$6F,$B6,$B4,$B3
        .byte   $74,$76,$74,$60,$74,$60,$74,$06
        .byte   $93,$B4,$80,$71,$06,$98,$B6,$B4
        .byte   $93,$74,$76,$60,$73,$60,$73,$73
        .byte   $60,$73,$60,$73,$60,$06,$93,$6C
        .byte   $6C,$06,$8F,$08,$00,$04,$00,$30
        .byte   $9B,$00,$06,$03,$50,$05,$1D,$71
        .byte   $60,$71,$60,$AF,$91,$60,$71,$94
        .byte   $98,$71,$60,$71,$60,$AF,$91,$60
        .byte   $71,$91,$8F,$6D,$60,$6D,$60,$AC
        .byte   $8D,$60,$6D,$8D,$8C,$AD,$AF,$6D
        .byte   $60,$6D,$60,$AF,$04,$01,$60,$9C
        .byte   $71,$60,$71,$60,$AF,$91,$60,$71
        .byte   $94,$98,$76,$60,$76,$60,$B4,$96
        .byte   $60,$76,$91,$8F,$8D,$A0,$8D,$8F
        .byte   $60,$6F,$8F,$8F,$B1,$8F,$60,$71
        .byte   $60,$06,$91,$8F,$90,$71,$60,$71
        .byte   $60,$AF,$91,$60,$71,$94,$98,$76
        .byte   $60,$76,$60,$B4,$96,$60,$76,$91
        .byte   $8F,$8D,$A0,$8D,$8F,$60,$6F,$8F
        .byte   $8F,$71,$60,$71,$60,$8F,$6F
        .byte   $71,$01
        .byte   $10,$60
        .byte   $7A,$7A,$7A,$78,$78,$76,$76,$01
        .byte   $00,$05,$29,$6A,$6A
        .byte   $68
        .byte   $60

        .byte   $6A,$60,$68,$6A,$60,$6A,$8A,$8A
        .byte   $68,$67,$68,$60,$68,$60,$68,$67
        .byte   $60,$67,$88,$60,$68,$8A,$8C,$6A
        .byte   $6A,$68,$60,$6A,$60
        .byte   $68
        .byte   $6A
        .byte   $60

        .byte   $6A,$8A,$8A,$68,$6C,$60,$8C,$6C
        .byte   $01,$10,$6B,$6B,$6B,$6B,$69,$69
        .byte   $69
        .byte   $69,$67
        .byte   $67,$67,$67,$01,$00,$6A,$6A,$68
        .byte   $60,$6A,$60,$68,$6A,$60,$6A,$8A
        .byte   $8A,$68,$67,$68,$60,$68,$60,$68
        .byte   $67,$60,$67,$88,$60,$68
        .byte   $8A
        .byte   $8C,$6A,$6A
        .byte   $68
        .byte   $60

        .byte   $6A,$60,$68
        .byte   $6A
        .byte   $60

        .byte   $6A,$8A,$8A,$68,$6C,$05,$1D,$60
        .byte   $70,$70,$60,$70,$60,$70,$60,$70
        .byte   $80,$6C,$6C,$06,$8C,$04,$00,$60
        .byte   $9C,$00,$06,$07,$82,$90,$83,$83
        .byte   $07,$84,$50,$01,$FF,$8D,$01,$00
        .byte   $07,$82,$90,$63,$63,$63,$63,$83
        .byte   $07,$84,$50,$01,$FF,$8D,$01,$00
        .byte   $07,$82,$90,$63,$63,$04,$06,$5A
        .byte   $9D,$07,$84,$50,$01,$FF
        .byte   $8D,$80,$8D
        .byte   $80,$6D,$60,$6D,$60
        .byte   $AD,$01,$00
        .byte   $07,$82,$90,$83,$83,$07,$84,$50
        .byte   $01,$FF,$8D,$01,$00,$07,$82,$90
        .byte   $63,$63,$63,$63,$83,$07,$84,$50
        .byte   $01,$FF,$8D,$01,$00,$07,$82,$90
        .byte   $63,$63,$04,$06,$90,$9D,$07,$82
        .byte   $90,$83,$07,$84,$50,$01,$FF,$8D
        .byte   $01,$00,$07,$82,$90,$63,$63,$07
        .byte   $84,$50,$01,$FF,$6D,$01,$00,$07
        .byte   $82,$90,$63,$C0,$07,$82,$90,$83
        .byte   $83,$07,$84,$50,$01,$FF
        .byte   $8D,$01,$00
        .byte   $07,$82,$90,$63,$63,$63,$63,$83
        .byte   $07,$84,$50,$01,$FF,$8D,$01,$00
        .byte   $07,$82,$90,$63,$63,$04,$02,$D4
        .byte   $9D,$07,$84,$50,$01,$FF,$60,$8D
        .byte   $60,$AD,$C0
        .byte   $01,$00
        .byte   $07,$82,$90,$83,$83,$07,$84,$50
        .byte   $01,$FF,$8D,$01,$00,$07,$82,$90
        .byte   $63,$63,$63,$63,$83,$07,$84,$50
        .byte   $01,$FF,$8D,$01,$00,$07,$82,$90
        .byte   $63,$63,$04,$02,$06,$9E,$07,$84
        .byte   $50,$01,$FF,$60,$6D,$8D,$6D,$60
        .byte   $6D,$60,$AD
        .byte   $A0,$01
        .byte   $00
        .byte   $04,$00,$5A,$9D,$00,$00,$80,$00
        .byte   $01,$62,$80,$00,$0F,$53,$9E,$2B
        .byte   $9F,$1D,$A0,$14,$A1,$89,$A1,$00
        .byte   $06,$03,$3C,$02
        .byte   $C0,$07
        .byte   $8A
        .byte   $20,$05,$1F
        .byte   $8C,$71,$68
        .byte   $60

        .byte   $71,$60,$65,$60,$71,$60,$6C,$88
        .byte   $91,$04,$01,$5E,$9E,$8A,$6F,$67
        .byte   $60,$6F,$60,$63,$60,$6F,$60,$6A
        .byte   $87,$8F,$04,$01,$6F,$9E,$8C,$71
        .byte   $68,$60,$71,$60,$65,$60,$71,$60
        .byte   $6C,$88,$91

        .byte   $04,$01,$80,$9E,$8A,$6F,$67,$60
        .byte   $6F,$60,$63,$60,$6F,$60,$6A,$87
        .byte   $8F,$63,$65,$67,$6A,$60,$6F,$73
        .byte   $76,$A0,$07,$92,$10,$03,$3E,$83
        .byte   $84
        .byte   $21,$C5
        .byte   $08
        .byte   $01,$E5
        .byte   $08
        .byte   $00
        .byte   $06,$87,$06,$88,$8A,$06,$87,$06
        .byte   $88,$87,$06,$A5,$85,$67
        .byte   $65,$06
        .byte   $A3,$A3,$A4,$21,$C5,$08,$01,$E5
        .byte   $08,$00
        .byte   $06,$87
        .byte   $06,$88
        .byte   $8A
        .byte   $21,$AC
        .byte   $08
        .byte   $01,$AC
        .byte   $08
        .byte   $00
        .byte   $78,$76,$74,$76,$74,$73,$74,$73
        .byte   $71,$73,$71,$6F,$71,$6F,$6D,$6F
        .byte   $6D,$6C,$6D,$6C,$6A,$6C,$6A,$68
        .byte   $07,$AF,$10,$CC,$06,$8C,$06,$8D
        .byte   $91,$CF,$AC,$AF,$D0,$06,$90,$06
        .byte   $93,$96,$D4,$94,$93,$91,$8F,$CD
        .byte   $8D,$8C,$AA,$CF,$8F,$8D,$AC
        .byte   $71,$76
        .byte   $71,$6D
        .byte   $04,$03,$12,$9F,$07,$87,$70,$B1
        .byte   $91,$60,$71,$60,$71,$91,$91,$74
        .byte   $75,$04,$00,$55,$9E,$00,$06,$03
        .byte   $38,$02,$C0,$06,$60,$05,$1F,$07
        .byte   $90,$10,$8C,$71,$68,$60,$71,$60
        .byte   $65,$60,$71,$60,$6C,$88,$91,$04
        .byte   $01,$38,$9F,$8A,$6F,$67,$60,$6F
        .byte   $60,$63,$60,$6F,$60,$6A,$87,$8F
        .byte   $04,$01,$49,$9F,$8C,$71,$68,$60
        .byte   $71,$60,$65,$60,$71,$60,$6C,$88
        .byte   $91,$04,$01,$5A,$9F,$8A,$6F,$67
        .byte   $60,$6F,$60,$63,$60,$6F,$60,$6A
        .byte   $87,$8F,$63,$65,$67,$6A,$60,$6F
        .byte   $73,$76,$A0,$80,$40,$03,$39,$07
        .byte   $92,$10,$02,$00,$8C
        .byte   $71,$68
        .byte   $60

        .byte   $71,$60,$65,$60,$71,$60,$6C,$88
        .byte   $91,$04,$01,$8A,$9F,$8A,$6F,$67
        .byte   $60,$6F,$60,$63,$60,$6F,$60,$6A
        .byte   $87,$8F,$04,$01,$9B,$9F,$8C,$71
        .byte   $68,$60,$71,$60,$65,$60,$71,$60
        .byte   $6C,$88,$91,$04,$01,$AC,$9F,$60
        .byte   $6F,$60,$6A,$87,$8F,$02,$C0,$07
        .byte   $8F,$10,$60,$78,$76,$74,$76,$74
        .byte   $73,$74,$73,$71,$73,$71,$6F,$71
        .byte   $6F,$6D,$6F,$6D,$6C,$6D,$6C,$6A
        .byte   $6C,$6A,$05,$1F,$07,$AF,$10,$03
        .byte   $3A,$C8,$06
        .byte   $88
        .byte   $06,$8A
        .byte   $8C,$C7,$A7
        .byte   $AC,$CC,$06
        .byte   $8C,$06,$90
        .byte   $93,$D1,$91,$60,$93,$91,$6F,$CA
        .byte   $8A,$88,$A6
        .byte   $CC,$8C,$8A
        .byte   $A8
        .byte   $6D,$71,$6D
        .byte   $6A
        .byte   $04,$03,$04,$A0,$07,$87,$70
        .byte   $AD,$8D,$60
        .byte   $6D,$60,$6D
        .byte   $8D,$8D,$6C
        .byte   $6D,$04,$00
        .byte   $2D,$9F,$00
        .byte   $06,$03
        .byte   $28
        .byte   $05,$1F
        .byte   $91,$8C
        .byte   $71,$60
        .byte   $71,$71
        .byte   $60

        .byte   $91,$6C,$8C,$8F,$04,$01,$23,$A0
        .byte   $8F,$8A,$6F,$60,$6F,$6F,$60,$8F
        .byte   $6A,$8A,$8F,$04,$01,$32,$A0,$91
        .byte   $8C,$71,$60,$71,$71,$60,$91,$6C
        .byte   $8C,$8F,$04,$01,$41,$A0,$8F,$8A
        .byte   $6F,$60,$6F,$6F,$60,$8F,$6A,$8A
        .byte   $8F,$01,$12,$78,$78,$78,$78,$60
        .byte   $75,$75,$75,$60,$7D,$7D
        .byte   $7D,$7B,$7B
        .byte   $7C,$7C,$01,$00
        .byte   $91,$8C
        .byte   $71,$60
        .byte   $71,$71
        .byte   $60

        .byte   $91,$6C,$8C,$8F,$04,$01,$6F,$A0
        .byte   $8F,$8A,$6F,$60,$6F,$6F,$60,$8F
        .byte   $6A
        .byte   $8A
        .byte   $8F,$04
        .byte   $01,$7E
        .byte   $A0,$91
        .byte   $8C,$71,$60
        .byte   $71,$71
        .byte   $60

        .byte   $91,$6C
        .byte   $8C,$8F,$04
        .byte   $01,$8D
        .byte   $A0,$8F
        .byte   $8A
        .byte   $6F,$60,$6F,$6F,$60,$8F,$6A,$8A
        .byte   $8F,$04
        .byte   $01,$9C
        .byte   $A0,$8D
        .byte   $60

        .byte   $6D,$91,$74
        .byte   $71,$60
        .byte   $6D,$74,$71
        .byte   $99,$74,$71
        .byte   $8F,$60,$6F,$93,$76,$73,$60,$6F
        .byte   $76,$73
        .byte   $9B,$76,$73,$90,$60,$70,$93,$78
        .byte   $73,$60,$70,$78,$73,$9C,$78,$73
        .byte   $91,$60,$71,$94,$78,$74,$60,$71
        .byte   $78,$74,$9D,$78,$74,$86,$60,$66
        .byte   $8A
        .byte   $6D,$6A,$60
        .byte   $6D,$6A,$66
        .byte   $92,$6D,$6A
        .byte   $88
        .byte   $60

        .byte   $68
        .byte   $8C,$6F,$6C
        .byte   $60

        .byte   $6F
        .byte   $6C,$68,$94

        .byte   $6F
        .byte   $6C,$8A,$60

        .byte   $6A,$8D,$71,$6D,$60,$71,$6D,$6A
        .byte   $96,$71,$6D,$AA,$8A,$60,$6A,$60
        .byte   $6A,$8A,$8A,$6F,$70,$04,$00,$23
        .byte   $A0
        .byte   $00
        .byte   $06,$07
        .byte   $84,$A0
        .byte   $03,$3F,$02,$80,$03,$3A,$64,$64
        .byte   $60,$64,$02,$00,$01,$33,$03,$3F
        .byte   $88,$01,$00,$02,$80,$03,$3A,$64
        .byte   $64,$60,$64,$64,$02,$00,$01,$33
        .byte   $03,$3F,$68,$88,$01,$00,$02,$80
        .byte   $03,$3A,$64,$64,$04
        .byte   $06,$1D
        .byte   $A1,$E0
        .byte   $03,$3A,$64,$64,$60,$64,$02,$00
        .byte   $01,$33,$03,$3F,$88,$01,$00,$02
        .byte   $80,$03,$3A,$64,$64,$60,$64,$64
        .byte   $02,$00,$01,$33,$03,$3F,$68,$88
        .byte   $01,$00,$02,$80,$03,$3A,$64,$64
        .byte   $04,$0E
        .byte   $4A
        .byte   $A1,$01
        .byte   $33,$68,$60,$80,$88,$60,$68,$60
        .byte   $68,$68,$60,$68,$60,$80,$04,$00
        .byte   $1D
        .byte   $A1,$00
        .byte   $00
        .byte   $80,$00,$01,$62,$80,$00,$0F,$9C
        .byte   $A1,$BA,$A2,$A7,$A3,$53,$A4,$A0
        .byte   $A4,$00,$05,$02,$00,$05,$13,$03
        .byte   $3D,$07,$92,$10,$CC,$AD,$8F,$EC
        .byte   $80,$CA,$AA
        .byte   $8C,$82,$02
        .byte   $C0,$05
        .byte   $1F,$98
        .byte   $98
        .byte   $01,$25
        .byte   $96,$80
        .byte   $01,$00
        .byte   $98
        .byte   $98
        .byte   $01,$25
        .byte   $96,$80
        .byte   $01,$00
        .byte   $04,$01,$9E,$A1,$02,$80,$05,$13
        .byte   $B1,$01,$10,$9D,$01,$00,$91,$80
        .byte   $8F,$01,$10,$9D,$01,$00,$91,$04
        .byte   $01,$CA,$A1,$B3,$01,$10,$9D,$01
        .byte   $00,$93,$80,$91,$01,$10,$9D,$01
        .byte   $00,$93,$04,$01,$DF,$A1,$B1,$01
        .byte   $10,$9D,$01,$00,$91,$80,$8F,$01
        .byte   $10,$9D,$01,$00,$91,$04,$01,$F2
        .byte   $A1,$B3,$01,$10,$9D,$01,$00,$93
        .byte   $80,$91,$01,$10,$9D,$01,$00,$93
        .byte   $B0,$01,$10
        .byte   $9D,$01,$00
        .byte   $93,$80,$90,$01,$10
        .byte   $9D,$01,$00
        .byte   $93,$02,$C0,$03,$3D,$07,$92,$10
        .byte   $05,$1F,$21,$B4,$08,$01
        .byte   $B4,$08
        .byte   $00
        .byte   $94,$96,$80,$98,$80,$96,$80,$94
        .byte   $80,$94,$B6,$93,$94,$80,$93,$80
        .byte   $91,$80,$21,$8F,$08,$01,$AF,$80
        .byte   $06,$BB,$08,$00,$B9,$21,$B8,$08
        .byte   $01,$B8,$08,$00,$98,$96,$94,$9B
        .byte   $80,$99,$80,$06,$B8,$9D,$21,$9C
        .byte   $08,$01,$DC,$08,$00,$05,$2B,$80
        .byte   $8C,$90,$21,$93,$08,$01,$F3,$08
        .byte   $00,$05,$1F,$AC,$80,$8A,$21,$8A
        .byte   $08,$01,$AA,$08,$00,$88,$80,$8A
        .byte   $21,$8A,$08,$01,$AA,$08,$00,$85
        .byte   $88,$8A,$AC,$8A,$AF,$AD,$AC,$AA
        .byte   $A8,$A7,$80,$AC,$80,$8A,$21,$8A
        .byte   $08,$01,$AA,$08,$00,$88,$80
        .byte   $8A
        .byte   $21,$8A
        .byte   $08
        .byte   $01,$AA
        .byte   $08
        .byte   $00
        .byte   $85,$88,$8A,$AC,$8A,$AF,$AD,$AC
        .byte   $B0,$B3,$B6,$98,$04,$00,$C8,$A1
        .byte   $00,$05,$03,$37,$02,$80,$05,$13
        .byte   $07,$92,$20,$60,$88,$98,$94,$88
        .byte   $98,$91,$94,$8D,$98,$94,$88,$94
        .byte   $98,$88,$94,$98,$87,$96,$93,$87
        .byte   $96,$8F,$93,$6C,$02,$C0,$03,$3D
        .byte   $05,$1F,$93,$93,$A0,$93,$93,$A0
        .byte   $04,$01
        .byte   $BC,$A2,$01
        .byte   $00
        .byte   $03,$38,$02,$80,$05,$13,$60,$88
        .byte   $98,$94,$88,$98,$91,$94,$8D,$98
        .byte   $94,$88,$94,$98,$88,$94,$98,$87
        .byte   $96,$93,$87,$96,$8F,$93,$8C,$96
        .byte   $93,$87,$93,$96,$87,$93,$96,$88
        .byte   $98,$94,$88,$98,$91,$94,$8D,$98
        .byte   $94,$88,$94,$98,$88,$94,$98,$87
        .byte   $96,$93,$87,$96,$8F,$93,$8C,$96
        .byte   $93,$87,$93,$96,$87,$93,$76,$02
        .byte   $C0,$03,$38,$07,$92,$10,$05,$1F
        .byte   $06,$80,$D4,$94
        .byte   $96,$80
        .byte   $98
        .byte   $80,$96,$80,$94,$80,$94,$B6,$93
        .byte   $94,$80,$93,$80,$91,$80,$21,$8F
        .byte   $AF,$80,$06,$BB,$B9,$D8,$98,$96
        .byte   $94,$9B,$80,$99,$80,$06,$B8,$9D
        .byte   $21,$9C,$DC,$05,$2B,$80,$8C,$70
        .byte   $F3,$05,$1F,$A8,$80,$87,$06,$A7
        .byte   $85,$80,$87,$06,$A7,$81,$85,$87
        .byte   $79,$74,$71,$7D,$79,$74
        .byte   $71,$7D
        .byte   $79,$74,$71
        .byte   $7D,$79,$74
        .byte   $71,$7D
        .byte   $78
        .byte   $73,$70,$6C,$78,$73,$70,$6C,$78
        .byte   $73,$70,$6C,$78,$73,$70,$6C,$04
        .byte   $01,$70,$A3,$04
        .byte   $00
        .byte   $EE,$A2,$00
        .byte   $05,$03
        .byte   $35,$05
        .byte   $1F,$88,$98,$94,$88,$98,$91,$94
        .byte   $8D,$98,$94,$88,$94,$98,$88,$94
        .byte   $98,$87,$96,$93,$87,$96,$8F,$93
        .byte   $8C,$96,$93,$87,$93,$96,$87,$93
        .byte   $96,$88,$98,$94,$88,$98,$91,$94
        .byte   $8D,$98,$94,$88,$94,$98,$88,$94
        .byte   $98,$87,$96,$93,$87
        .byte   $96,$8F
        .byte   $93,$8C,$96,$93,$87,$93,$01,$10
        .byte   $7D,$7D,$7D,$7D,$7A,$7A,$77,$77
        .byte   $01,$00,$88
        .byte   $98
        .byte   $94,$88
        .byte   $98
        .byte   $91,$94
        .byte   $8D,$98,$94
        .byte   $88
        .byte   $94,$98
        .byte   $88
        .byte   $94,$98
        .byte   $87,$96,$93,$87,$96,$8F,$93,$8C
        .byte   $96,$93,$87,$93,$96,$87,$93,$96
        .byte   $04,$03,$F5,$A3,$91,$94,$93,$91
        .byte   $AF,$80
        .byte   $8D,$80,$8F
        .byte   $AF,$80,$8D,$91,$93,$8D,$04,$07
        .byte   $27,$A4,$90,$04,$07,$2C,$A4,$91
        .byte   $94,$93,$91,$AF,$80,$8D,$80,$8F
        .byte   $AF,$80,$8D,$91,$93,$8D,$91,$94
        .byte   $8D,$91,$94,$8D,$91,$93,$8C,$90
        .byte   $93,$8C,$90,$93,$98,$04,$00,$F5
        .byte   $A3,$00,$05,$07,$88,$10,$03,$38
        .byte   $07,$82
        .byte   $70,$83
        .byte   $04,$17,$5A,$A4,$07,$84,$40,$01
        .byte   $FF,$8B,$8B,$A0,$8B,$8B,$A0,$01
        .byte   $00,$07,$82,$70,$83,$04,$17,$6F
        .byte   $A4,$07,$84,$40,$01,$FF,$8B,$8B
        .byte   $A0,$6B,$6B,$6B,$6B,$6B,$6B,$6A
        .byte   $6A
        .byte   $01,$00
        .byte   $03,$3D,$07,$82,$70,$83,$83,$07
        .byte   $84,$40,$01,$FF,$8B,$01,$00,$07
        .byte   $82,$70,$83,$04,$00,$89,$A4,$00
        .byte   $00,$80,$00,$02,$62,$80,$00,$0F
        .byte   $B3,$A4,$41,$A6,$C0,$A7,$40,$A9
        .byte   $58,$A9,$00,$05,$03,$3E,$02,$40
        .byte   $05,$20,$07,$84,$10,$85,$68,$68
        .byte   $88,$68,$68,$88,$85,$80,$65,$65
        .byte   $88,$68,$68,$88,$85,$80,$8C,$8A
        .byte   $8C,$80,$68,$68,$88,$68,$68,$88
        .byte   $85,$80,$8C,$80,$8A,$80,$88,$80
        .byte   $8A,$A0,$80,$6A,$6A,$8A,$6A,$6A
        .byte   $8A,$87,$80
        .byte   $8C,$80,$8A
        .byte   $80,$88,$80,$87,$80,$85,$80,$85
        .byte   $8C,$8F,$06,$AE,$85,$80,$85,$8C
        .byte   $8F,$8E,$80,$93,$94,$80
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $85,$80
        .byte   $65,$65
        .byte   $88
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $85,$80
        .byte   $8C,$8A,$8C
        .byte   $80,$68,$68,$88,$68,$68,$88,$85
        .byte   $80
        .byte   $8C,$80,$8A
        .byte   $80,$88,$80,$8A,$A0,$80,$6A,$6A
        .byte   $8A,$6A,$6A,$8A,$87,$80,$8C,$80
        .byte   $8A,$80,$88,$80,$87,$80,$85,$80
        .byte   $85,$8C,$8F,$06
        .byte   $AE,$85,$80
        .byte   $85,$8C
        .byte   $8F,$8E,$80,$8F,$07,$90,$10,$02
        .byte   $80,$22,$91,$B1,$D1,$8F,$B4,$B1
        .byte   $AF,$B1,$80,$CF,$8F,$06,$B1
        .byte   $8C,$8D,$8C
        .byte   $88
        .byte   $80,$88,$8C,$8F,$06,$D1,$8F,$B4
        .byte   $B1,$AF,$B1,$21,$8F,$CF,$8F,$8C
        .byte   $8F,$90,$80,$90,$90,$93,$D8,$07
        .byte   $95,$30,$02,$00,$03,$3F,$05,$14
        .byte   $08,$01,$06,$CC,$8A,$AF,$AD,$AC
        .byte   $AD,$22,$8C,$CC,$AC,$8A,$AF,$AD
        .byte   $AC,$AD,$21,$88,$C8,$88,$8A,$8C
        .byte   $E7
        .byte   $08
        .byte   $00
        .byte   $05,$20,$02,$80,$85,$80,$85,$8C
        .byte   $8F,$06,$AE,$85,$80,$85,$8C,$8F
        .byte   $8E,$80,$8F,$08,$01,$02,$C0,$21
        .byte   $91,$D1,$B1,$8F,$91,$80,$06,$B4
        .byte   $98,$96,$94,$93,$D1,$B1,$8F,$91
        .byte   $80,$06,$B4,$94,$96,$B4,$D3,$93
        .byte   $91,$8F,$06,$B8,$B6,$B4,$B3,$93
        .byte   $94,$93,$D1,$85,$80,$85,$8C,$8F
        .byte   $8E,$80,$8F,$08,$00,$02,$80,$22
        .byte   $91,$B1,$D1,$8F,$B4,$B1,$AF,$B1
        .byte   $80,$CF,$8F,$06,$B1,$8C
        .byte   $8D,$8C,$88
        .byte   $80,$88,$8C,$8F,$06,$D1,$8F,$B4
        .byte   $B1,$AF,$B1,$21,$8F,$CF,$8F,$8C
        .byte   $8F,$90,$80,$90,$90,$93,$06,$B8
        .byte   $05,$14,$02,$40,$94,$80,$94,$94
        .byte   $93,$B4,$9D,$BB,$B9,$B8,$B6,$96
        .byte   $80,$98,$98,$80,$98,$A0,$96,$80
        .byte   $98,$98,$80,$98,$80,$96,$94,$80
        .byte   $94,$94,$93,$B4,$9D,$BB,$B9,$B8
        .byte   $B6,$80,$93,$94,$93,$21,$91,$D1
        .byte   $E0,$04,$00,$B5,$A4,$00,$05,$02
        .byte   $40,$05,$14,$07,$84,$10,$03,$3A
        .byte   $80,$71,$71,$91,$71,$71,$91,$8C
        .byte   $80,$6C,$6C,$91,$71,$71,$91,$8C
        .byte   $80,$94,$93,$94,$80,$71,$71,$91
        .byte   $71,$71,$91,$8C,$80,$94,$80,$93
        .byte   $80,$91,$80,$93,$A0,$80,$73,$73
        .byte   $93,$73,$73,$93,$8F,$80,$94,$80
        .byte   $93,$80,$91,$80,$8F,$05,$20,$A0
        .byte   $85,$80,$85,$8C,$8F,$06,$AE,$85
        .byte   $80,$85,$8C,$8F,$8E,$8F,$91,$04
        .byte   $01,$43,$A6,$07,$92,$10,$02,$80
        .byte   $60,$22,$91,$B1,$D1,$8F,$B4,$B1
        .byte   $AF,$B1,$80,$CF,$8F,$06,$B1,$8C
        .byte   $8D,$8C,$88,$80,$88,$8C,$8F,$06
        .byte   $D1,$8F,$B4,$B1,$AF,$B1,$21,$8F
        .byte   $CF,$8F,$8C,$8F,$90,$80,$90,$90
        .byte   $93,$22,$B8,$68,$02,$00,$85,$68
        .byte   $68,$88,$68,$68,$88,$85,$80,$65
        .byte   $65,$88,$68,$68,$88,$85,$80,$8C
        .byte   $8A,$8C,$80,$68,$68,$88,$68,$68
        .byte   $88,$85,$80,$8C,$80,$8A,$80,$88
        .byte   $80,$8A,$A0,$80,$6A,$6A,$8A,$6A
        .byte   $6A,$8A,$87,$80,$8C,$80,$8A,$80
        .byte   $88,$80,$87,$02,$80,$A0,$85,$80
        .byte   $85,$8C,$8F,$06,$AE,$85,$80,$85
        .byte   $8C,$8F,$8E,$96,$98,$02,$00,$80
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $85,$80
        .byte   $65,$65
        .byte   $88
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $85,$80
        .byte   $8C,$8A,$8C
        .byte   $80,$68,$68,$88,$68,$68,$88,$85
        .byte   $80,$8C,$80,$8A,$80,$88,$80,$8A
        .byte   $A0,$80,$6A,$6A,$8A,$6A,$6A,$8A
        .byte   $87,$80,$8C,$80,$8A,$80,$88,$80
        .byte   $87,$02,$80,$80,$85,$80,$85,$8C
        .byte   $8F,$CE,$85,$80,$85,$8C,$8F,$8E
        .byte   $96,$98,$07,$8A,$10,$60,$22,$91
        .byte   $B1,$D1,$8F,$B4,$B1,$AF,$B1,$80
        .byte   $CF,$8F,$06,$B1,$8C,$8D,$8C,$88
        .byte   $80,$88,$8C,$8F,$06,$D1,$8F,$B4
        .byte   $B1,$AF,$B1,$21,$8F,$CF,$8F,$8C
        .byte   $8F,$90,$80,$90,$90,$93,$06,$80
        .byte   $05,$14,$02,$40,$08,$01,$91,$80
        .byte   $91,$91,$8F,$B1,$99,$B6,$B6,$B4
        .byte   $B3,$93,$80,$94,$94,$80,$94,$A0
        .byte   $93,$80,$94,$94,$80,$94,$80,$93
        .byte   $91,$80,$91,$91,$8F,$B1,$99,$B6
        .byte   $B6,$B4,$B3,$80,$8F,$91,$8F,$21
        .byte   $8C,$CC,$E0,$08,$00,$04,$00,$43
        .byte   $A6,$00,$05,$03,$41,$05,$2C,$85
        .byte   $65,$65,$04,$07,$C6,$A7,$81,$61
        .byte   $61,$04,$07,$CD,$A7,$83,$63,$63
        .byte   $04,$07,$D4,$A7,$85,$65,$65,$04
        .byte   $06,$DB,$A7,$83,$21,$85,$85,$65
        .byte   $65,$04,$07,$E5,$A7,$81,$61,$61
        .byte   $04,$07,$EC,$A7,$83,$63,$63,$04
        .byte   $07,$F3,$A7,$85,$65,$65,$04,$06
        .byte   $FA,$A7,$83,$21,$85,$86,$66
        .byte   $66,$86
        .byte   $66,$66
        .byte   $86,$6D
        .byte   $6D,$6A,$6A
        .byte   $8A
        .byte   $80,$66,$66,$8A,$66,$66,$91,$6A
        .byte   $6A,$8D,$66,$66,$85,$65,$65,$85
        .byte   $65,$65,$85,$6C,$6C,$68,$68,$8F
        .byte   $80,$65,$65,$88,$65,$65,$8F,$68
        .byte   $68
        .byte   $8C,$65,$65
        .byte   $86,$66
        .byte   $66,$86
        .byte   $66,$66
        .byte   $86,$6D
        .byte   $6D,$6A,$6A
        .byte   $8A
        .byte   $80,$66,$66,$8A,$66,$66,$91,$6A
        .byte   $6A,$8D,$66,$66,$83,$63,$63,$04
        .byte   $02,$4C,$A8,$83,$84,$80,$84,$84
        .byte   $84,$A4,$A0,$85,$65,$65,$04,$07
        .byte   $5B,$A8,$81,$61,$61,$04,$07,$62
        .byte   $A8,$83,$63,$63,$04,$07,$69,$A8
        .byte   $85,$65,$65,$04,$06,$70,$A8,$83
        .byte   $21,$85,$85,$65,$65,$04,$07,$7A
        .byte   $A8
        .byte   $81,$61
        .byte   $61,$04
        .byte   $07,$81,$A8,$83,$63,$63,$04,$07
        .byte   $88,$A8,$85,$65,$65,$04,$06,$8F
        .byte   $A8,$83,$21,$85,$86,$66,$66,$86
        .byte   $66,$66,$86,$6D,$6D,$6A,$6A,$8A
        .byte   $80,$66,$66,$8A,$66
        .byte   $66,$91
        .byte   $6A
        .byte   $6A
        .byte   $8D,$66,$66
        .byte   $85,$65
        .byte   $65,$85
        .byte   $65,$65
        .byte   $85,$6C
        .byte   $6C,$68,$68

        .byte   $8F,$80,$65,$65,$88,$65,$65,$8F
        .byte   $68,$68,$8C,$65,$65,$86,$66,$66
        .byte   $86,$66,$66,$86,$6D,$6D,$6A,$6A
        .byte   $8A,$80,$66,$66,$8A,$66,$66,$91
        .byte   $6A,$6A,$8D,$66,$66,$83,$63,$63
        .byte   $04,$02,$E1,$A8,$83,$84,$80,$84
        .byte   $84,$84,$A4,$80,$A1,$61,$61,$81
        .byte   $61,$61,$81,$61,$61,$81,$A3,$63
        .byte   $63,$83,$63,$63,$83,$63,$63,$83
        .byte   $05,$20
        .byte   $A5,$91
        .byte   $87
        .byte   $93,$88
        .byte   $94,$87
        .byte   $04
        .byte   $01,$04
        .byte   $A9,$05
        .byte   $2C,$A1,$61
        .byte   $61,$81
        .byte   $61,$61
        .byte   $81,$61
        .byte   $61,$81
        .byte   $A3,$63,$63,$83,$63,$63,$83,$63
        .byte   $63,$A4,$A5,$01,$10,$6D,$6D,$6C
        .byte   $6C,$6A,$6A,$68,$68,$01,$00,$83
        .byte   $85,$80,$83,$A5,$83,$84,$A5,$04
        .byte   $00,$C4,$A7,$00,$05,$03,$3F,$07
        .byte   $82,$A0,$62,$60,$62,$62,$07,$83
        .byte   $40,$87,$07,$82,$A0,$62,$62,$04
        .byte   $00,$44,$A9,$00,$00,$80,$00,$01
        .byte   $41,$80,$00,$0F,$6B,$A9,$47,$AA
        .byte   $A9,$AA,$87,$AB,$98,$AB,$00,$06
        .byte   $03,$3C,$02,$00,$05,$22,$07,$A0
        .byte   $10,$08,$01,$E5,$08,$00,$21,$CC
        .byte   $08,$01,$CC,$08,$00,$21,$C7,$08
        .byte   $01,$C7
        .byte   $08
        .byte   $00
        .byte   $21,$C8
        .byte   $08
        .byte   $01,$C8
        .byte   $08
        .byte   $00
        .byte   $21,$C6,$08,$01,$C6,$08,$00,$21
        .byte   $CD,$08,$01,$CD,$08,$00,$21,$C8
        .byte   $08,$01,$C8,$08,$00,$21,$C9,$08
        .byte   $01
        .byte   $C9,$08
        .byte   $00
        .byte   $21,$C7,$08,$01,$C7,$08,$00,$21
        .byte   $CE,$08,$01,$CE,$08,$00,$21,$C9
        .byte   $08,$01,$C9,$08,$00,$21,$CA,$08
        .byte   $01,$CA,$08,$00,$21,$C8,$08,$01
        .byte   $C8,$08,$00,$21,$CF,$08,$01,$CF
        .byte   $08,$00,$21,$CA,$08,$01,$CA,$08
        .byte   $00,$21,$CB,$08
        .byte   $01,$CB
        .byte   $08
        .byte   $00
        .byte   $21,$C9
        .byte   $08
        .byte   $01,$C9
        .byte   $08
        .byte   $00
        .byte   $21
        .byte   $D0,$08
        .byte   $01,$D0
        .byte   $08
        .byte   $00
        .byte   $21,$CB
        .byte   $08
        .byte   $01
        .byte   $CB
        .byte   $08
        .byte   $00
        .byte   $21,$CC
        .byte   $08
        .byte   $01,$CC
        .byte   $05,$27
        .byte   $08
        .byte   $00
        .byte   $04,$01,$76,$A9
        .byte   $05,$22
        .byte   $21,$CF
        .byte   $08
        .byte   $01,$CF
        .byte   $08
        .byte   $00
        .byte   $21,$D6,$08,$01,$D6,$08,$00,$21
        .byte   $D1,$08,$01,$D1,$08,$00,$21,$D2
        .byte   $08,$01
        .byte   $D2,$08,$00,$21,$D0,$08,$01,$D0
        .byte   $08,$00,$21,$D7,$08,$01,$D7,$08
        .byte   $00,$21,$D2,$08,$01,$D2,$08,$00
        .byte   $D3,$08,$01,$01,$05,$D3,$01,$00
        .byte   $08,$00,$04,$00,$76,$A9,$00,$06
        .byte   $07,$A0,$10,$02,$00,$05,$22,$03
        .byte   $39,$05,$22,$E5,$E8,$E3,$21,$C5
        .byte   $08,$01,$C5,$08,$00,$E1,$E9,$E4
        .byte   $21,$C6,$08,$01,$C6,$08,$00,$E2
        .byte   $EA,$E5,$21,$C7,$08,$01,$C7,$08
        .byte   $00,$E3,$EB,$E6,$21,$C8,$08,$01
        .byte   $C8,$08,$00,$E4,$EC,$E7,$21,$C9
        .byte   $08,$01,$C9,$08,$00,$E5,$ED,$E8
        .byte   $21,$CA,$08
        .byte   $01,$C9
        .byte   $08
        .byte   $00
        .byte   $05,$27,$04,$01,$5E,$AA,$05,$22
        .byte   $EB,$F3,$EE,$D0,$08,$01,$01,$05
        .byte   $D0,$01,$00,$08,$00,$04,$00,$52
        .byte   $AA,$00,$06,$03,$35,$05,$22
        .byte   $65,$65
        .byte   $60

        .byte   $65,$65,$63,$65,$65,$80,$85,$88
        .byte   $8C,$04,$03,$AF,$AA,$66,$66,$60
        .byte   $66,$66,$64,$66,$66,$80,$86,$89
        .byte   $8D,$04,$03
        .byte   $BF,$AA
        .byte   $67,$67,$60,$67,$67,$65,$67,$67
        .byte   $80,$87,$8A,$8E,$04,$03,$CF,$AA
        .byte   $68,$68,$60
        .byte   $68
        .byte   $68
        .byte   $66,$68
        .byte   $68
        .byte   $80,$88,$8B,$8F,$04,$03,$DF,$AA
        .byte   $69,$69,$60,$69,$69,$67,$69,$69
        .byte   $80,$89,$8C,$90,$04,$03,$EF,$AA
        .byte   $6A,$6A,$60,$6A,$6A,$68,$6A,$6A
        .byte   $80,$8A,$8D,$91,$04,$03,$FF,$AA
        .byte   $6B,$6B,$60,$6B,$6B,$69,$6B,$6B
        .byte   $80,$8B,$8E,$92,$04,$03,$0F,$AB
        .byte   $6C,$6C,$60,$6C,$6C,$6A,$6C,$6C
        .byte   $80,$8C,$8F,$93,$04,$03,$1F,$AB
        .byte   $6D
        .byte   $6D,$60,$6D
        .byte   $6D,$6B,$6D
        .byte   $6D,$80,$8D
        .byte   $90,$94
        .byte   $04,$03,$2F,$AB,$6E,$6E,$60,$6E
        .byte   $6E,$6C,$6E,$6E,$80,$8E,$91,$95
        .byte   $04,$03,$3F,$AB,$6F,$6F,$60,$6F
        .byte   $6F,$6D,$6F,$6F,$80,$8F,$92,$96
        .byte   $04,$03,$4F,$AB,$70,$70,$60,$70
        .byte   $70,$6E,$70,$70,$80,$90,$93,$97
        .byte   $04,$02,$5F,$AB,$70,$70,$60,$70
        .byte   $70,$6E,$70,$70,$01,$10,$60,$7D
        .byte   $7D,$7C,$7C,$7A,$7A,$7A
        .byte   $01,$00
        .byte   $04,$00,$AF,$AA,$00,$06,$03,$3F
        .byte   $07,$83
        .byte   $A0,$62
        .byte   $62,$07,$82,$20,$82,$04,$00,$8B
        .byte   $AB,$00,$00,$80,$00,$02,$62,$80
        .byte   $00,$0F,$AB,$AB,$ED,$AB,$20,$AC
        .byte   $00,$00,$50,$AC,$00,$06,$02,$00
        .byte   $03,$3A,$07,$02,$A0,$05,$23,$6D
        .byte   $6D,$6D,$60,$6D,$8B,$21,$6D,$CD
        .byte   $6F,$6F,$6F,$60,$6F,$8D,$21,$6F
        .byte   $CF,$70,$70,$60,$70,$A0,$73,$73
        .byte   $60,$73
        .byte   $A0,$60
        .byte   $74,$60,$21,$72,$72,$70,$72,$73
        .byte   $07,$82,$80,$54,$55,$54
        .byte   $55,$54
        .byte   $55,$21
        .byte   $54
        .byte   $08
        .byte   $01,$07
        .byte   $02,$A0,$B4,$09,$00,$06,$02,$40
        .byte   $03,$3A,$05,$17,$07,$02,$A0,$70
        .byte   $70,$70,$60,$70,$8F,$21,$70,$D0
        .byte   $72,$72,$72,$60,$72
        .byte   $90,$21
        .byte   $72,$D2,$74,$74,$60,$74,$A0,$76
        .byte   $76,$60,$76,$A0,$60,$78,$60,$75
        .byte   $75,$74,$75,$75,$08,$01,$DB,$09
        .byte   $00
        .byte   $06,$03
        .byte   $81,$05
        .byte   $23,$CD,$60,$6D
        .byte   $6D,$6D,$6D
        .byte   $06,$8C
        .byte   $CB,$60,$6B,$6B,$6B,$6B,$06,$8A
        .byte   $69,$69,$60,$69
        .byte   $01,$10
        .byte   $60

        .byte   $7D,$9D,$01,$00,$6F,$6F,$60,$6F
        .byte   $01,$10,$60,$7D,$9D,$01,$00
        .byte   $08
        .byte   $01,$E8
        .byte   $09,$00
        .byte   $00
        .byte   $80,$00,$01,$62,$80,$00,$0F,$63
        .byte   $AC,$FA,$AC,$81,$AD,$C7,$AD,$0C
        .byte   $AE,$00,$06,$03,$3C,$02,$C0,$05
        .byte   $13,$07,$E0,$10,$08,$01,$E8,$EB
        .byte   $EE,$D1
        .byte   $6E,$71,$74
        .byte   $71,$74
        .byte   $71,$74
        .byte   $77,$08,$00,$07,$86
        .byte   $20,$05,$1F
        .byte   $02,$C0,$71,$71,$60,$71,$60
        .byte   $71,$71
        .byte   $80
        .byte   $71,$71
        .byte   $60

        .byte   $71,$60,$71,$71,$07,$83,$20,$91
        .byte   $60,$71,$A0,$98,$60
        .byte   $78
        .byte   $96,$98
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
        .byte   $6B
        .byte   $68
        .byte   $C5,$A8
        .byte   $60

        .byte   $71,$6E,$6B,$C8,$AB,$60,$74,$71
        .byte   $6E,$CB,$AE,$60,$77,$74,$6E,$D1
        .byte   $05,$1F,$02,$C0,$07,$86,$20,$6C
        .byte   $6C,$60,$6C,$60,$6C,$6C,$80,$6C
        .byte   $6C,$60,$6C,$60,$6C,$6C,$07,$83
        .byte   $20,$8C,$60,$6C,$A0,$94,$60,$74
        .byte   $93,$94,$04,$01,$1D,$AD,$02,$C0
        .byte   $07,$86,$20,$6A,$6A,$60,$6A,$60
        .byte   $6A,$6A,$80,$6A,$6A,$60,$6A,$60
        .byte   $6A,$6A,$07,$83,$20,$8A,$60,$6A
        .byte   $A0,$94,$60
        .byte   $74,$93,$94,$07,$86,$20,$67,$67
        .byte   $60,$67,$60,$67,$67,$80,$67,$67
        .byte   $60,$67,$60,$67
        .byte   $67,$08,$01,$A7,$AC,$B0,$B3,$08
        .byte   $00,$04,$00,$1D,$AD,$00,$06,$03
        .byte   $30,$05,$1F,$71,$71,$71,$6F,$04
        .byte   $0D,$87,$AD,$03
        .byte   $20,$01,$15
        .byte   $6C,$6C,$6A

        .byte   $6A,$68,$68,$66,$66,$03,$50,$01
        .byte   $00,$03,$40,$71,$71,$60,$71,$94
        .byte   $76,$71,$60,$6F,$71,$70,$8A,$6B
        .byte   $6C,$04,$06

        .byte   $9F,$AD,$6C,$6C,$78,$60,$76,$78
        .byte   $60,$6C,$60,$6C,$78,$60,$76,$78
        .byte   $74,$73,$04,$00,$9F,$AD,$00,$06
        .byte   $07,$88,$10,$03,$3F,$07,$82
        .byte   $F0,$A2
        .byte   $A2,$A2
        .byte   $07,$84,$10,$A7,$04,$01,$CE,$AD
        .byte   $07,$82,$A0,$83,$83,$07,$84,$40
        .byte   $87,$07,$82,$A0,$83,$04,$02,$DC
        .byte   $AD,$07,$84,$40,$66,$66,$66,$66
        .byte   $67,$67,$67,$67,$07,$83,$D0,$62
        .byte   $62,$60,$62,$07,$84,$40,$87,$07
        .byte   $82,$A0,$62,$62,$04,$00,$F8,$AD
        .byte   $00,$00,$80,$00,$01,$62,$80,$00
        .byte   $0F,$1F,$AE,$68,$AE,$9C,$AE,$D7
        .byte   $AE,$F4,$AE,$00,$05,$03,$39,$05
        .byte   $11,$07,$83,$50,$02,$80,$05
        .byte   $11,$01
        .byte   $15,$9D
        .byte   $9A
        .byte   $80,$97,$80,$74,$74,$94,$91,$05
        .byte   $1D,$01,$00,$03,$3B,$07,$86,$10
        .byte   $02,$00,$85,$88,$8C,$85,$88,$8F
        .byte   $85,$88
        .byte   $8E,$85,$88
        .byte   $8D,$85,$88
        .byte   $8B,$8C,$02,$40,$85,$88,$8C,$85
        .byte   $88,$8F,$85,$88,$8E,$85
        .byte   $88
        .byte   $8D,$85,$88
        .byte   $8B,$8C,$04,$00,$3B,$AE,$00,$05
        .byte   $05,$1D,$E0,$07,$86,$10,$03,$37
        .byte   $02,$00,$80,$85,$88,$8C,$85,$88
        .byte   $8F,$85,$88,$8E,$85,$88,$8D,$85
        .byte   $88,$8B,$02,$40,$03,$39,$88,$8C
        .byte   $91,$88,$8C,$93,$88,$8C,$92,$88
        .byte   $8C,$91,$88,$8C,$8E,$8F,$04,$00
        .byte   $70,$AE,$00,$05,$03,$30,$05,$1D
        .byte   $01,$0F,$9D,$9A,$80,$97,$80,$74
        .byte   $74,$94
        .byte   $90,$03
        .byte   $31
        .byte   $85,$83
        .byte   $01,$10
        .byte   $9A
        .byte   $01,$00
        .byte   $85,$80
        .byte   $88
        .byte   $01,$10
        .byte   $9A
        .byte   $05,$11
        .byte   $01,$00
        .byte   $91,$8C
        .byte   $98
        .byte   $05,$1D
        .byte   $01,$10
        .byte   $9A
        .byte   $01,$00
        .byte   $8B,$8A,$88,$01,$10,$9A,$01,$00
        .byte   $83,$04,$00,$AD,$AE,$00,$05,$07
        .byte   $83,$40,$03,$3F,$C0,$A0,$87,$87
        .byte   $07,$82,$F0,$82,$82,$82,$82,$82
        .byte   $82,$82,$07,$84,$90,$82,$04,$00
        .byte   $E2,$AE,$0F,$FF,$AE,$F9,$AF,$EC
        .byte   $B0,$80,$B1,$AC,$B1,$00,$05,$03
        .byte   $3C,$02,$00,$05,$23,$07,$9A,$10
        .byte   $8D,$6D,$6D,$8D,$6D,$6D,$8D,$8F
        .byte   $80,$21,$CB,$08,$01,$CB,$08,$00
        .byte   $8B,$89
        .byte   $69,$69
        .byte   $89,$86,$80
        .byte   $86,$80
        .byte   $C8
        .byte   $88
        .byte   $89,$8B,$A0
        .byte   $8D,$6D,$6D
        .byte   $8D,$6D,$6D
        .byte   $8D,$8F,$80
        .byte   $21,$CB
        .byte   $08
        .byte   $01,$CB
        .byte   $08
        .byte   $00
        .byte   $8B,$A9,$89,$8B,$80,$8B,$80
        .byte   $21,$8D
        .byte   $08
        .byte   $01,$CD
        .byte   $08
        .byte   $00
        .byte   $02,$80,$07,$83,$70,$05,$2F,$74
        .byte   $72,$70,$72
        .byte   $70,$6F
        .byte   $6E,$6D,$04
        .byte   $01,$01
        .byte   $AF,$07,$84,$10,$05,$23,$02,$C0
        .byte   $8D,$8D,$88
        .byte   $85,$91
        .byte   $8D,$88,$B4
        .byte   $92,$91,$8F,$91,$AD,$80,$8B,$8B
        .byte   $8A,$86,$AF,$8B,$88,$6B,$6B,$66
        .byte   $6F,$6B,$72,$6F,$77,$92,$AB,$80
        .byte   $8A,$6A,$6D,$6A,$65,$81,$04,$01
        .byte   $81,$AF
        .byte   $6A
        .byte   $6D,$75,$76
        .byte   $75,$76
        .byte   $75,$76
        .byte   $71,$6D
        .byte   $80
        .byte   $02
        .byte   $C0,$AA
        .byte   $80,$30,$81,$30,$84,$30,$89,$30
        .byte   $84,$30,$89,$30,$8D,$30,$89,$30
        .byte   $8D,$30,$90,$30
        .byte   $8D,$30,$90
        .byte   $30,$95
        .byte   $89,$89,$89,$89,$80,$AB,$80,$07
        .byte   $9A,$10,$02,$00,$8D
        .byte   $6D,$6D,$8D
        .byte   $6D
        .byte   $6D,$8D,$8F
        .byte   $80
        .byte   $21,$CB
        .byte   $08
        .byte   $01,$CB
        .byte   $08
        .byte   $00
        .byte   $8B,$89,$69,$69,$89,$86,$80,$86
        .byte   $80,$C8,$88,$89,$8B,$A0,$8D,$6D
        .byte   $6D,$8D,$6D,$6D,$8D,$8F,$80,$21
        .byte   $CB,$CB,$80,$88,$88,$8A,$8D,$80
        .byte   $88,$8A,$8D,$80,$88,$8A,$8D,$80
        .byte   $94,$96,$99,$09,$00,$05,$03,$3C
        .byte   $02,$00,$05,$23,$07,$9A,$10,$88
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $88
        .byte   $80,$E6,$88,$84,$64,$64,$84,$83
        .byte   $80,$83,$80,$C5,$85,$84
        .byte   $86,$A0
        .byte   $88
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $88
        .byte   $80
        .byte   $E6,$88
        .byte   $A4,$84
        .byte   $86,$80
        .byte   $86,$80
        .byte   $21,$88
        .byte   $C8
        .byte   $02,$80,$03,$36
        .byte   $05,$2F
        .byte   $07,$83
        .byte   $70,$60
        .byte   $74
        .byte   $72,$70,$72,$70
        .byte   $6F,$6E,$04,$01,$FB,$AF
        .byte   $07,$84,$10,$05,$23,$03,$3C,$02
        .byte   $C0,$88,$03,$37,$80,$8D,$88,$85
        .byte   $91,$8D,$88,$B4,$92,$91,$8F,$03
        .byte   $3C,$A8,$80,$86,$03,$37,$80,$8B
        .byte   $8A,$86,$AF,$8B,$88,$6B,$6B,$66
        .byte   $6F,$6B,$72,$6F,$77,$03,$3C,$A6
        .byte   $80,$85,$03,$37,$60,$6A,$6D,$6A
        .byte   $65,$81,$04,$01,$7A,$B0,$6A,$6D
        .byte   $75,$76
        .byte   $75,$76,$75,$76,$71,$6D,$60,$03
        .byte   $3C,$02,$C0,$A5,$80,$30,$84,$30
        .byte   $89,$30,$8D
        .byte   $30,$89
        .byte   $30,$8D
        .byte   $30,$90
        .byte   $30,$8D
        .byte   $30,$90
        .byte   $30,$95
        .byte   $30,$90
        .byte   $30,$95
        .byte   $30,$99
        .byte   $84,$84
        .byte   $84,$84
        .byte   $80
        .byte   $A6,$80
        .byte   $07,$9A,$10,$02,$00,$88
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $68
        .byte   $68
        .byte   $88
        .byte   $88
        .byte   $80,$E6,$88,$84,$64,$64,$84,$83
        .byte   $80,$83,$80,$C5,$85,$84,$86,$A0
        .byte   $88,$68,$68,$88,$68,$68,$88,$88
        .byte   $80,$E6,$80,$85,$85,$86,$88,$80
        .byte   $85,$86,$88,$80,$85,$86,$88,$80
        .byte   $91,$92,$94,$09,$00,$05,$03,$30
        .byte   $05,$23,$8D,$6D
        .byte   $6D,$04,$1D
        .byte   $F2
        .byte   $B0,$8D
        .byte   $88
        .byte   $8A
        .byte   $8D,$8D,$6D
        .byte   $6D,$04,$1D
        .byte   $FD,$B0,$8D
        .byte   $88
        .byte   $8A
        .byte   $8D,$03,$30
        .byte   $A5,$01
        .byte   $14
        .byte   $9D,$80,$8D
        .byte   $8D,$9D,$80
        .byte   $8D,$8D,$9D
        .byte   $8D,$80,$01
        .byte   $00
        .byte   $85,$01
        .byte   $14,$9D
        .byte   $9D,$01,$00
        .byte   $A3,$01,$14,$9D,$80,$8D,$8D,$9D
        .byte   $80,$8D,$8D,$9D,$8D,$80,$01,$00
        .byte   $83,$01,$14,$9D,$9D,$01,$00,$81
        .byte   $80,$01,$14,$9D,$80,$8D,$8D,$9D
        .byte   $80,$8D,$8D,$9D,$8D,$80,$01,$00
        .byte   $81,$01,$14,$9D,$9D,$01,$00,$81
        .byte   $80,$01,$14,$9D,$80,$87,$87,$BD
        .byte   $7D,$7D,$9D,$7B,$7B,$9B,$79,$79
        .byte   $99,$7D,$7D,$7B,$78,$01,$00,$8D
        .byte   $6D,$6D,$04,$17,$68,$B1,$8D
        .byte   $8D,$8F,$91
        .byte   $80,$8D,$8F,$91,$80,$8D,$8F,$91
        .byte   $80,$8D,$8F,$91,$09,$00,$05,$07
        .byte   $82,$A0,$03,$3F,$82,$62,$62,$07
        .byte   $84,$80,$01,$FE
        .byte   $8D,$01,$00
        .byte   $07,$82,$A0,$62,$62,$04,$3B,$87
        .byte   $B1,$83,$83,$83,$83,$80,$83,$83
        .byte   $83,$80,$83,$83,$83,$80,$83,$83
        .byte   $83
        .byte   $09,$00
        .byte   $00
        .byte   $80,$00,$02,$62,$80,$00,$0F
        .byte   $BF,$B1,$3D,$B2,$B9,$B2,$1D,$B3
        .byte   $53,$B3,$00,$08,$05,$20,$02,$80
        .byte   $03,$3E,$07,$DF,$40,$08,$00,$21
        .byte   $AE,$06,$CE,$21,$CF,$8F,$06,$B1
        .byte   $04,$01,$C1,$B1,$AE,$B1,$B8,$95
        .byte   $96,$A0,$80,$96,$95,$93,$91,$93
        .byte   $80,$8E,$8C,$8A,$80,$8A,$89,$8A
        .byte   $21,$B1,$06,$D1,$06,$B3,$06
        .byte   $B1,$AF
        .byte   $06,$B5
        .byte   $06,$B3
        .byte   $B1,$06
        .byte   $B5
        .byte   $06,$B3
        .byte   $B2,$06,$B6,$06,$B5,$B3,$00,$07
        .byte   $D6,$02,$C0,$80,$8D,$8F,$91,$21
        .byte   $B2,$B2,$92,$B1,$92,$22,$AF,$8F
        .byte   $AF,$8F,$8C,$8F,$B4,$B2,$B1,$AF
        .byte   $00
        .byte   $06,$B0
        .byte   $80
        .byte   $90,$90
        .byte   $AF,$90,$AD,$80,$8D,$8D,$AF,$90
        .byte   $F2,$05,$38,$01,$01,$02,$00,$03
        .byte   $3F,$07,$AF,$10,$21,$F9,$F9,$09
        .byte   $00,$08,$02,$C0,$03,$3A,$07,$8A
        .byte   $30,$05,$20,$80,$91,$96,$98,$DA
        .byte   $80,$92,$96,$98,$DB,$04,$01,$48
        .byte   $B2,$96,$91,$96,$9A,$95
        .byte   $91,$95
        .byte   $98
        .byte   $93,$8E,$93,$96,$91,$8C,$91,$96
        .byte   $90,$8C
        .byte   $90,$93
        .byte   $04,$01,$66,$B2,$D1,$91,$06,$B0
        .byte   $8F,$8A,$8F,$91,$D3,$91,$8C,$91
        .byte   $93,$D5,$92,$8E,$92,$93,$D5,$93
        .byte   $8E,$93,$95,$D6,$00,$07,$02,$80
        .byte   $07,$83,$30,$86,$8A,$8D,$82,$04
        .byte   $03,$8D,$B2,$88,$8C,$8F,$94,$04
        .byte   $03,$95,$B2,$00,$06,$89,$8D,$90
        .byte   $95,$04,$03,$9F,$B2
        .byte   $E0,$05
        .byte   $38
        .byte   $02,$00,$03,$3F,$01,$01,$07,$AF
        .byte   $10
        .byte   $21,$F4
        .byte   $F4,$01,$00,$09,$00,$08,$03,$81
        .byte   $05,$20,$06,$AA,$8A,$AA,$A0,$04
        .byte   $03,$BB,$B2,$CA,$C9,$C7,$C5,$C4
        .byte   $C7,$06,$A5,$85,$A5
        .byte   $A0,$06
        .byte   $C3
        .byte   $A4,$E5
        .byte   $06,$C2
        .byte   $A6,$E7
        .byte   $03,$50,$00,$07,$86,$86,$80,$86
        .byte   $86,$81,$86,$8A,$04,$01,$DF,$B2
        .byte   $88,$88,$80,$88,$88,$83,$88,$8C
        .byte   $04,$01,$EB,$B2,$00,$06,$89,$89
        .byte   $80,$89,$89,$84,$89
        .byte   $8D,$04,$01
        .byte   $F9,$B2,$01
        .byte   $15,$30
        .byte   $9D,$04,$02
        .byte   $07,$B3,$30,$98,$04,$08,$0D,$B3
        .byte   $03,$8F,$05,$38,$01,$01,$21,$F5
        .byte   $F5,$09,$00,$08,$03,$3C,$07,$81
        .byte   $10,$06,$C0,$85,$80,$04,$0B,$24
        .byte   $B3,$00,$07,$07,$82,$C0,$82,$82
        .byte   $82,$82,$82,$82,$07,$83,$40,$A7
        .byte   $04,$03,$2E,$B3,$00,$06,$07,$82
        .byte   $C0,$82,$82,$82,$82,$82,$82,$07
        .byte   $83,$40,$A7,$04,$02,$41,$B3,$09
        .byte   $02,$22,$80,$00,$0F,$62,$B3,$80
        .byte   $B3,$9E,$B3,$C3,$B3,$D1,$B3,$00
        .byte   $06,$03,$3F,$02,$00,$05,$27,$07
        .byte   $AF,$10,$6C,$6C,$60,$6C,$60,$6C
        .byte   $60,$6C,$A0,$6D,$6F,$60,$22,$71
        .byte   $B1,$08,$00,$D1,$09
        .byte   $00
        .byte   $06,$02
        .byte   $40

        .byte   $05,$27,$03,$3F,$07,$AF,$10,$69
        .byte   $69,$60
        .byte   $69,$60
        .byte   $69,$60
        .byte   $69,$A0
        .byte   $6A
        .byte   $6C,$60,$22

        .byte   $6E,$AE,$08
        .byte   $00
        .byte   $CE,$09
        .byte   $00
        .byte   $06,$03
        .byte   $30,$05
        .byte   $27,$65,$65,$60
        .byte   $65
        .byte   $60

        .byte   $65,$60
        .byte   $85,$01
        .byte   $10
        .byte   $7D,$98,$01
        .byte   $00
        .byte   $66,$88
        .byte   $03,$7F,$21,$6A
        .byte   $21,$8A
        .byte   $AA
        .byte   $03,$30
        .byte   $01,$10
        .byte   $7D,$7B,$B7
        .byte   $09,$00
        .byte   $06,$07
        .byte   $83,$F0,$03,$3F,$80,$60,$82,$82
        .byte   $82,$E0,$09
        .byte   $01,$62
        .byte   $80,$00,$0F,$E0,$B3,$23,$B4,$4F
        .byte   $B4,$81,$B4,$9E
        .byte   $B4,$00
        .byte   $06,$03
        .byte   $3E,$02,$C0
        .byte   $05,$27
        .byte   $07,$01,$70,$B1,$B1,$30,$AF,$AF
        .byte   $30,$8F,$30,$AF,$30,$8F,$30,$A0
        .byte   $08,$01,$AD,$08,$00
        .byte   $30,$8D
        .byte   $30,$8D
        .byte   $30,$8D
        .byte   $30,$8F
        .byte   $B1,$B1
        .byte   $30,$AF
        .byte   $AF,$30,$8F
        .byte   $30,$AF
        .byte   $30,$8F
        .byte   $30,$A0
        .byte   $08
        .byte   $01,$AE
        .byte   $08
        .byte   $00
        .byte   $30,$8E,$30
        .byte   $8E,$30,$8E
        .byte   $30,$8F
        .byte   $04,$00,$E2,$B3,$00,$06,$02,$40
        .byte   $05,$27,$07,$01,$80
        .byte   $03,$3A,$07,$01,$80,$AA,$AA,$30
        .byte   $A9,$A9,$30,$89,$30,$A8,$30,$88
        .byte   $30
        .byte   $A0,$08
        .byte   $01,$A5
        .byte   $08
        .byte   $00
        .byte   $30,$85,$30,$85,$30,$85,$30,$8C
        .byte   $04,$00,$25,$B4,$00,$06,$03,$55
        .byte   $05,$27,$30,$A6,$30,$86,$30,$86
        .byte   $30,$92,$30,$86,$04,$01,$55,$B4
        .byte   $30,$A5,$30,$85,$30,$85,$30,$91
        .byte   $30,$85,$30,$8A,$30,$96,$30,$8A
        .byte   $30,$8A,$01,$10,$30,$9D,$30,$9A
        .byte   $01,$00,$04,$00,$55
        .byte   $B4,$00
        .byte   $06,$03
        .byte   $3F,$07,$82,$80
        .byte   $30,$82
        .byte   $30,$82
        .byte   $30,$82
        .byte   $07
        .byte   $85,$40
        .byte   $30,$87
        .byte   $07,$82,$80,$30,$82,$30,$82,$04
        .byte   $00,$88,$B4,$00,$00,$80,$00,$01
        .byte   $62,$80,$00,$0F,$B1
        .byte   $B4,$E0
        .byte   $B4,$08
        .byte   $B5,$2A
        .byte   $B5,$4B
        .byte   $B5,$00
        .byte   $06,$03
        .byte   $3E,$02,$C0
        .byte   $05,$27
        .byte   $07,$A2,$20,$80,$A0,$85,$8B,$8A
        .byte   $88,$85,$80,$88,$83,$80,$84,$80
        .byte   $85,$80,$88,$87,$86,$85,$8B,$8A
        .byte   $88,$85,$88,$8B,$21,$AE,$08,$01
        .byte   $CE,$08,$00,$8A,$80,$8C,$09,$00
        .byte   $06,$06,$A0,$02,$80,$05,$1B,$07
        .byte   $01,$60,$03,$37,$01,$FF,$B1,$AE
        .byte   $B0,$AD,$AF,$AC,$AE,$AB,$B1,$AE
        .byte   $B0,$AD,$AF,$01,$00,$08,$00,$02
        .byte   $40,$A5,$80,$93,$80
        .byte   $94,$09
        .byte   $00
        .byte   $06,$03,$50,$05,$27,$01,$10,$65
        .byte   $65
        .byte   $BD,$01,$00
        .byte   $85,$83
        .byte   $85,$83
        .byte   $85,$80
        .byte   $85,$82
        .byte   $80,$82,$82,$82,$80,$83,$80,$85
        .byte   $04,$01,$15,$B5,$09,$00,$06,$03
        .byte   $36,$80,$A7,$03,$3A,$07,$82,$80
        .byte   $83,$83,$07,$84,$70,$87,$07,$82
        .byte   $80,$83,$04,$06,$30,$B5,$07,$84
        .byte   $70,$80,$87,$80,$87,$09,$00,$00
        .byte   $80,$00,$01,$62,$80,$00,$0F,$5E
        .byte   $B5,$72,$B5,$00,$00,$00,$00,$86
        .byte   $B5,$00,$08,$03,$3F,$02,$40,$07
        .byte   $FF,$10,$01,$FF
        .byte   $05,$2F
        .byte   $08
        .byte   $01,$95
        .byte   $04,$00,$60,$B5,$00,$08,$03,$3A
        .byte   $02,$40,$07,$FF,$10,$01,$FF
        .byte   $05,$2F
        .byte   $08
        .byte   $01,$96
        .byte   $04,$00,$74,$B5,$00,$00,$80,$00
        .byte   $00,$22,$80,$00,$0F,$99,$B5,$36
        .byte   $B6,$48,$B6,$C4,$B6,$D8,$B6,$00
        .byte   $08,$05,$20,$02,$C0,$03,$3A,$07
        .byte   $DF,$40,$08,$00,$21,$CC,$8C,$85
        .byte   $88
        .byte   $8C,$AF,$8D
        .byte   $AC,$06,$AA
        .byte   $04,$03,$A6,$B5,$02,$40
        .byte   $CD,$06,$8D
        .byte   $06,$8F
        .byte   $91,$06
        .byte   $AC,$8C,$8D
        .byte   $06,$AF
        .byte   $D4,$94,$92,$91,$8F,$06,$AE,$8E
        .byte   $8F,$06,$B1,$8D,$8C,$8D,$8F,$A0
        .byte   $99,$98,$99,$9B,$A0,$06,$86,$06
        .byte   $8A,$8D,$D1,$06,$91,$06,$92,$91
        .byte   $CF,$8F,$06,$B1,$02,$00,$CD,$06
        .byte   $8C,$06,$8D,$8F,$CD,$06,$8C,$06
        .byte   $8D,$91,$21,$96,$D6,$91,$71,$6F
        .byte   $8D,$AF,$91,$06,$AA,$8A,$8C,$06
        .byte   $AD,$05,$14
        .byte   $96,$92
        .byte   $8D,$96,$99
        .byte   $94,$B8
        .byte   $BE,$9D,$BB
        .byte   $07,$01,$40,$05,$20,$22,$ED,$CD
        .byte   $8D,$90,$8F,$21
        .byte   $8D,$04,$01
        .byte   $15,$B6
        .byte   $00
        .byte   $09,$ED,$00,$0A,$06,$A9,$89,$00
        .byte   $0B,$89,$06,$AB,$22,$E8,$07,$9F
        .byte   $10,$E8,$E8,$09,$00,$08,$02,$C0
        .byte   $03,$35,$07,$DF,$40,$05,$20,$06
        .byte   $80,$04,$00,$A6,$B5,$09,$00,$08
        .byte   $03,$81,$05,$20,$06,$AD,$8D,$CD
        .byte   $06,$AD,$8D,$CD,$04,$01,$4E,$B6
        .byte   $06,$AA,$8A,$CA,$06,$AA,$8A,$CA
        .byte   $04,$01,$5A,$B6,$06,$A6,$86,$C6
        .byte   $06,$A8,$88,$C8,$06,$A1,$81,$C1
        .byte   $06,$AA,$8A,$CA,$06,$A6,$86,$C6
        .byte   $04,$01,$76,$B6,$06
        .byte   $A3,$83,$C3,$06,$A8,$88,$88,$06
        .byte   $A9,$06,$AA,$8A,$CA,$06,$A9,$89
        .byte   $C9,$06,$A8,$88,$C8
        .byte   $06,$A7
        .byte   $87,$C7,$06,$A6,$86,$C6,$06,$A8
        .byte   $88,$C8,$06,$AB,$8B,$CB,$04,$01
        .byte   $A0,$B6,$06,$AA,$8A,$CA,$04,$01
        .byte   $A8,$B6,$00,$09,$06,$A9,$89,$C9
        .byte   $00,$0A
        .byte   $06,$A6
        .byte   $86,$00
        .byte   $0B,$86,$06,$A8,$21,$E1,$A1,$09
        .byte   $00,$08,$03,$3C,$07,$81,$10,$06
        .byte   $D0,$A8,$04,$19,$CB
        .byte   $B6,$00
        .byte   $09,$06
        .byte   $D0,$A8
        .byte   $09,$02
        .byte   $22,$80,$00,$0F,$E7,$B6,$E5,$B7
        .byte   $DE,$B8,$B6,$B9,$E2,$B9,$00,$05
        .byte   $03,$3C,$05,$23,$07,$9A,$10,$E0
        .byte   $63,$66,$6B,$6F,$66,$6B,$6F,$72
        .byte   $6B,$6F,$72,$77,$6F,$72,$77,$7B
        .byte   $A8,$E0,$C0,$94,$94,$E0,$C0,$88
        .byte   $06,$A7,$A6,$E0,$A0,$80,$90,$90
        .byte   $92,$E0,$C0,$A6,$A7,$04,$01,$01
        .byte   $B7,$A8,$A0,$E0,$E0,$E0,$05,$17
        .byte   $80,$86,$87,$88,$8B,$6D,$6D,$80
        .byte   $6B,$6B,$8D,$80,$8B,$6D,$6D,$80
        .byte   $68,$68,$8B,$6D
        .byte   $6D,$90,$6F
        .byte   $6F,$8D,$6B,$6B,$8B,$6D,$6D,$80
        .byte   $6B,$6B,$8D,$80,$8B,$6D,$6D,$80
        .byte   $66,$66,$80,$66
        .byte   $66,$86
        .byte   $67,$67,$88,$6B,$6B,$04,$01,$25
        .byte   $B7,$05,$23,$02,$C0,$C9,$89,$8D
        .byte   $80,$8D,$70,$6D,$69,$6D,$70,$6D
        .byte   $70,$75,$D0,$CB,$8B,$8F,$80,$06
        .byte   $B7,$B5,$B4,$B2,$C9,$89,$8D,$80
        .byte   $8D,$70,$6D,$69,$6D
        .byte   $70,$6D,$70,$75,$D0,$CB,$06,$8B
        .byte   $06,$88,$8B,$CC,$03,$38,$70,$73
        .byte   $78,$70,$73,$78,$7C,$78,$02,$00
        .byte   $8D,$6D,$6D,$8D,$6D,$6D,$8D,$8F
        .byte   $80,$EB,$8B,$89,$69,$69,$89,$86
        .byte   $80,$86,$80,$C8,$88,$89,$8B,$A0
        .byte   $8D,$6D,$6D,$8D,$6D,$6D,$8D,$8F
        .byte   $80,$EB,$8B,$85,$85,$86,$88,$80
        .byte   $85,$86,$88,$80,$85,$86,$88,$80
        .byte   $03,$3F,$85,$86,$21,$88,$E8,$94
        .byte   $94,$03,$3C,$06,$80,$94,$94,$03
        .byte   $38
        .byte   $06,$80
        .byte   $94,$94
        .byte   $03,$35,$06,$80,$94
        .byte   $94,$03
        .byte   $33,$06,$80,$94,$94,$09,$00
        .byte   $05,$03
        .byte   $3C,$05,$23,$07,$9A,$10,$E0,$66
        .byte   $6B,$6F,$66,$6B,$6F,$72,$6B,$6F
        .byte   $72,$77,$6F,$72,$77,$7B
        .byte   $7E,$A5,$E0
        .byte   $C0,$91
        .byte   $91,$E0
        .byte   $C0,$85
        .byte   $06,$A4
        .byte   $A3
        .byte   $E0,$A0
        .byte   $80,$8D,$8D,$8F,$E0,$C0,$A3,$A4
        .byte   $04
        .byte   $01,$FF
        .byte   $B7,$A5,$A0,$E0,$E0,$E0,$80,$86
        .byte   $87,$88,$8B
        .byte   $6D,$6D,$80
        .byte   $6B,$6B,$8D,$80,$8B,$6D,$6D,$80
        .byte   $68,$68,$8B,$6D,$6D,$90,$6F,$6F
        .byte   $8D,$6B,$6B,$8B,$6D,$6D,$80,$6B
        .byte   $6B,$8D,$80,$8B,$6D,$6D,$80,$66
        .byte   $66,$80,$66,$66,$86,$67,$67,$88
        .byte   $6B,$6B,$04,$01,$21,$B8,$61,$64
        .byte   $69,$6D,$04,$07,$53,$B8,$63,$66
        .byte   $6B,$6F,$04,$07,$5B,$B8,$61,$64
        .byte   $69,$6D,$04,$07,$63,$B8,$63,$66
        .byte   $6B,$6F,$73,$6F,$6B,$66,$04,$01
        .byte   $6B,$B8,$64,$67,$6C,$70,$67,$6C
        .byte   $70,$73,$6C,$70,$73,$78,$70,$73
        .byte   $78,$7C,$02,$00,$07,$9A,$10,$88
        .byte   $68,$68,$88,$68,$68,$88,$88,$80
        .byte   $E6,$88,$84,$64,$64
        .byte   $84,$83
        .byte   $80,$83,$80,$C5,$85,$84,$86,$A0
        .byte   $88,$68,$68,$88,$68,$68,$88,$88
        .byte   $80,$E6,$88,$88,$88
        .byte   $8A
        .byte   $8D,$80,$88
        .byte   $8A
        .byte   $8D,$80,$88
        .byte   $8A
        .byte   $8D,$80,$03
        .byte   $3F
        .byte   $88
        .byte   $8A
        .byte   $21,$8D
        .byte   $ED,$99,$99
        .byte   $03,$3C,$06,$80,$99,$99,$03,$38
        .byte   $06,$80,$99,$99,$03,$35,$06,$80
        .byte   $99,$99,$03,$32,$06,$80,$99,$99
        .byte   $09,$00,$05,$03,$30,$05,$23,$01
        .byte   $10,$A0,$9D,$9A,$80,$9A,$B8,$7D
        .byte   $7D,$7D,$60,$7A,$7A,$7A,$60,$77
        .byte   $77,$77,$60
        .byte   $7D,$7A,$78
        .byte   $75,$01
        .byte   $00
        .byte   $8B,$8D,$80,$8D
        .byte   $A0,$8B
        .byte   $8D,$80,$8D
        .byte   $80,$8B,$8D,$90,$01,$10,$9D,$9D
        .byte   $01,$00,$8B,$8D,$80,$8D,$A0,$8B
        .byte   $8D,$80,$8D,$80,$8B,$8D,$90,$01
        .byte   $10,$9D,$9D,$01,$00,$86,$8B,$80
        .byte   $8B,$A0,$86,$8B,$80,$8B,$80,$86
        .byte   $8B,$8F,$01,$10,$9D,$9D,$01,$00
        .byte   $86,$8B,$80,$8B,$A0,$86,$8B,$80
        .byte   $8B,$80,$86,$01,$10,$BD,$BD,$04
        .byte   $01,$FC,$B8,$8D,$80,$9D,$8D,$80
        .byte   $8D
        .byte   $9D,$80,$8D
        .byte   $80,$9D,$8D,$6D,$6D,$6D,$6D,$9D
        .byte   $8D,$04,$05,$4A,$B9,$01,$00,$89
        .byte   $69,$69,$04,$07,$62,$B9,$8B,$6B
        .byte   $6B,$04,$07,$69,$B9,$89,$69,$69
        .byte   $04,$07,$70,$B9,$8B,$6B,$6B,$04
        .byte   $03,$77,$B9,$8C,$6C,$6C,$8C,$6C
        .byte   $6C,$01,$15,$7D,$7D,$7D,$7D,$7A
        .byte   $7A,$7A,$7A,$01,$00,$8D,$6D,$6D
        .byte   $04,$17,$90,$B9,$81,$81,$81,$85
        .byte   $80,$81,$81,$85,$80,$81,$81,$85
        .byte   $80,$81,$81,$85,$01,$10,$7D,$7A
        .byte   $78,$04,$04,$A7,$B9,$75,$01,$00
        .byte   $85,$85,$09,$00,$05,$07,$82,$A0
        .byte   $03,$3F,$82,$62,$62,$07,$84,$80
        .byte   $01,$FE,$8D,$01,$00,$07,$82,$A0
        .byte   $62,$62,$04,$57,$BD,$B9,$83,$83
        .byte   $83,$83,$80,$83,$83,$83,$80,$83
        .byte   $83,$83,$80,$83
        .byte   $83,$83,$09,$00,$00,$80,$00,$01
        .byte   $62,$80,$00,$0F,$F5,$B9,$0E,$BA
        .byte   $27,$BA,$00,$00,$4E,$BA,$00,$06
        .byte   $03
        .byte   $3F,$05,$27,$07,$89
        .byte   $10,$E0
        .byte   $6A
        .byte   $6A
        .byte   $80,$6C
        .byte   $6C,$80,$6D

        .byte   $6D
        .byte   $80,$6F,$6D,$6F,$06,$F1
        .byte   $09,$00
        .byte   $06,$03
        .byte   $3F,$05,$27,$07,$89
        .byte   $10,$E0
        .byte   $66,$66
        .byte   $80
        .byte   $68
        .byte   $68
        .byte   $80,$6A,$6A,$80,$6C,$6A
        .byte   $6C,$06,$ED

        .byte   $09,$00,$06,$03,$30,$05,$27,$01
        .byte   $10,$9D,$9D
        .byte   $7D,$7A,$60
        .byte   $98
        .byte   $98
        .byte   $78
        .byte   $76,$60
        .byte   $73,$60
        .byte   $01,$00
        .byte   $03,$81,$63,$63,$80,$65,$65,$80
        .byte   $66,$66
        .byte   $80
        .byte   $68
        .byte   $66,$68
        .byte   $06,$E8
        .byte   $09,$00
        .byte   $00
        .byte   $80,$00,$0F,$5D,$BA,$90,$BA,$C3
        .byte   $BA,$DA,$BA,$E9,$BA,$00,$06,$03
        .byte   $3F,$02,$00,$05,$23,$07,$AF,$10
        .byte   $06,$CD,$30,$8D,$30,$8C,$30
        .byte   $8D,$06,$CF
        .byte   $30,$8F
        .byte   $30,$8D
        .byte   $30,$8F
        .byte   $06,$D1
        .byte   $30,$91
        .byte   $30,$8F
        .byte   $30,$91
        .byte   $D2,$30,$92,$30,$91,$30,$92,$30
        .byte   $8F,$30,$92,$30,$96,$06,$F4,$09
        .byte   $00,$06,$02,$40,$05,$23,$03,$3F
        .byte   $07,$AF,$10,$06,$C8,$30,$88,$30
        .byte   $88,$30
        .byte   $91,$06
        .byte   $D4,$30,$94,$30,$92,$30,$91,$06
        .byte   $CD,$30,$8D,$30,$8C,$30,$8D,$CF
        .byte   $30,$8F,$30,$8D,$30,$8F,$30,$8A
        .byte   $30,$8F,$30,$92,$06,$F1,$09,$00
        .byte   $06,$03,$50,$05,$2F,$81,$81,$81
        .byte   $61
        .byte   $61,$60
        .byte   $81,$61
        .byte   $81,$81
        .byte   $04,$03,$C9,$BA,$06,$E1,$09,$00
        .byte   $06,$07,$83,$F0,$03,$3F,$63,$63
        .byte   $83,$04,$0F,$DC,$BA,$09,$01,$62
        .byte   $80,$00,$0F,$00,$00,$00,$00,$F8
        .byte   $BA,$13,$BB,$22,$BB,$00,$05,$03
        .byte   $30,$05,$23,$01,$10,$8D,$80
        .byte   $BD,$80,$6D
        .byte   $6D,$BD,$8D
        .byte   $80,$BD,$6D,$6D,$6D,$6D,$BD,$04
        .byte   $00,$FE,$BA,$00,$05,$03,$3F,$07
        .byte   $82,$30,$01,$FF
        .byte   $A0,$AB
        .byte   $04,$00,$1C,$BB
        .byte   $50,$0A
        .byte   $02,$00,$03,$3F,$83,$8A,$00,$06
        .byte   $03,$3F
        .byte   $80,$0A,$80,$35,$00,$09,$02,$80
        .byte   $01,$FF,$80,$05,$03,$3F,$8F,$FF
        .byte   $00,$09,$03,$3A,$80,$05,$03,$3A
        .byte   $01,$00,$8F,$FF,$00,$09,$03,$36
        .byte   $80,$04,$03,$37,$8F,$FF,$00,$09
        .byte   $03,$33,$80,$03,$06
        .byte   $A0,$0F
        .byte   $02,$80,$01,$20,$03,$3F,$80,$86
        .byte   $02,$00,$01,$20,$03,$3F,$81,$0D
        .byte   $03,$7F,$01,$20,$81,$AB,$00,$0A
        .byte   $03,$3A,$02,$80,$80,$0A,$01,$15
        .byte   $80,$64,$01,$15,$80,$C9,$01,$15
        .byte   $82,$FA,$00,$3A,$02,$00,$80,$08
        .byte   $06
        .byte   $30,$0A
        .byte   $02,$00,$03,$3F,$81,$AB,$00,$03
        .byte   $02,$80
        .byte   $03,$3F,$80
        .byte   $0A,$04,$01,$90,$BB,$03,$38,$02
        .byte   $C0,$01,$FF,$80,$3F,$00,$10,$02
        .byte   $80,$05,$00,$00,$84,$01,$80,$07
        .byte   $06
        .byte   $30,$02
        .byte   $00
        .byte   $10
        .byte   $02,$40,$03,$3F,$05,$02,$44,$80
        .byte   $00,$01,$E0,$81,$0D,$06
        .byte   $50,$02
        .byte   $00
        .byte   $08
        .byte   $02,$40,$03,$3F,$01,$0F,$80,$64
        .byte   $06
        .byte   $D0,$0A
        .byte   $02,$C0,$03,$3F,$05,$02,$A3,$80
        .byte   $07,$01
        .byte   $5F,$80,$71,$00,$05,$05,$01,$43
        .byte   $80,$07,$01,$5F,$03,$3F,$80,$0A
        .byte   $03,$38,$80,$64,$00,$0D,$05,$01
        .byte   $43,$80,$07,$01,$F1,$02,$80,$80
        .byte   $05,$06
        .byte   $E0,$0A
        .byte   $01,$35
        .byte   $02,$00,$03,$3F,$80,$A9,$00,$06
        .byte   $03,$37,$80,$03,$01,$FC,$05,$01
        .byte   $42,$80,$00,$8F,$FF,$00,$20,$03
        .byte   $3A,$80,$04,$01,$F9,$8F,$FF,$00
        .byte   $20,$03,$3A,$80,$04,$06
        .byte   $C0,$03
        .byte   $05,$01
        .byte   $41,$80
        .byte   $00
        .byte   $03,$3F,$02,$40,$80,$6A,$00,$04
        .byte   $02,$40,$05,$01,$41,$80,$00,$03
        .byte   $3F,$80,$54,$04,$02,$2F,$BC,$06
        .byte   $20,$02,$00
        .byte   $04,$02,$40,$01,$8B,$03,$3F,$05
        .byte   $01,$46,$82,$01,$80,$3F,$04,$01
        .byte   $4E,$BC,$06
        .byte   $F0,$0B
        .byte   $03,$3F,$81,$AB,$02,$C0,$01,$F2
        .byte   $03,$3F,$87
        .byte   $F2,$00,$1F,$03,$3F,$02,$80,$80
        .byte   $04,$04,$0D,$64,$BC,$01,$01,$80
        .byte   $11,$02,$00,$01,$01,$80,$15,$00
        .byte   $7F,$02,$80,$03,$34,$80,$0A,$8F
        .byte   $FF,$8F,$FF,$00,$1F,$80,$0A,$04
        .byte   $0C,$8E,$BC,$06,$80,$0A,$02,$40
        .byte   $03,$3F,$05,$00,$05,$86,$07,$01
        .byte   $40,$80,$0E,$00,$15,$02,$80,$01
        .byte   $4F,$03,$3F,$80,$0F,$06
        .byte   $C0,$0A
        .byte   $02,$C0,$01,$05,$03,$3F,$83,$F9
        .byte   $00,$02,$03,$3F,$80,$0E,$04,$01
        .byte   $B7,$BC,$02,$00,$05,$01,$43,$80
        .byte   $00,$01,$14,$82,$81,$00,$03,$80
        .byte   $0C,$01,$CA,$8F,$FF,$00,$0C,$80
        .byte   $0C,$01,$04,$8F,$FF,$00,$12,$80
        .byte   $0A,$01,$FE,$8F,$FF,$00,$12,$80
        .byte   $09,$06,$80,$06,$03,$3F,$01,$81
        .byte   $80,$1E,$00,$04,$03,$3F,$80,$0F
        .byte   $06
        .byte   $70,$0A
        .byte   $02,$80,$03,$3F,$01,$EF,$80,$38
        .byte   $00,$04
        .byte   $02,$80,$03,$3F,$01,$FF,$80,$08
        .byte   $01,$F9,$80,$25,$00,$04,$80,$05
        .byte   $01,$EF,$80,$38,$00,$04,$80,$0A
        .byte   $06
        .byte   $E0,$02
        .byte   $00
        .byte   $05,$03,$3F,$02,$C0,$80,$86,$00
        .byte   $08,$03,$3F,$05,$00,$E0,$80,$00
        .byte   $02,$40,$80,$C9,$06
        .byte   $E0,$0A
        .byte   $02,$C0,$01,$25,$05,$01,$62,$82
        .byte   $04,$03,$3F,$80,$4D,$00,$04,$03
        .byte   $35,$80,$05,$01,$F0,$80,$4D,$00
        .byte   $05,$03
        .byte   $33,$80,$05,$06
        .byte   $30,$0A
        .byte   $02,$00,$03,$37,$01,$FF,$80,$8E
        .byte   $00,$02
        .byte   $03,$3C,$80,$03,$03,$38,$80,$47
        .byte   $00,$06,$03,$3F,$80,$04,$06
        .byte   $E0,$02
        .byte   $00
        .byte   $05,$03,$3F,$02,$80,$80,$FE,$00
        .byte   $05,$81,$53,$00,$05,$81,$93,$00
        .byte   $05,$80,$7F,$06
        .byte   $E0,$08
        .byte   $00
        .byte   $07,$03,$3F,$80,$0F,$06,$80,$0A
        .byte   $02,$80,$03,$3F,$05,$03,$85,$81
        .byte   $02,$01,$B1,$80,$B3,$00,$06,$02
        .byte   $80,$05,$03,$85,$81,$02,$80,$09
        .byte   $04,$1E,$9A,$BD,$06
        .byte   $30,$0A
        .byte   $02,$40,$03,$3F,$01,$F6,$80,$6A
        .byte   $00,$03
        .byte   $03,$34,$80,$08,$04,$02,$B9,$BD
        .byte   $06
        .byte   $30,$0A
        .byte   $02,$40,$03,$3F,$01,$F6,$80,$64
        .byte   $00,$03
        .byte   $03,$38,$80,$0A,$04,$02,$CE,$BD
        .byte   $06
        .byte   $30,$0A
        .byte   $02,$40,$03,$3F,$01,$F1,$80,$5F
        .byte   $00,$03
        .byte   $03,$38,$80,$0E,$04,$03,$E3,$BD
        .byte   $06
        .byte   $30,$0A
        .byte   $02,$C0,$03,$3F,$86,$4E,$00,$03
        .byte   $02,$80
        .byte   $03,$3F,$80,$0B,$01,$02,$86,$4E
        .byte   $00,$04,$02,$00,$80,$0F,$04,$0A
        .byte   $06,$BE,$06,$60,$0E,$02,$C0,$01
        .byte   $B1,$03,$3F,$05,$02,$A7,$82,$05
        .byte   $81,$FC,$01,$81,$03,$81,$81,$AB
        .byte   $00,$04,$02,$80,$80,$0D,$04,$01
        .byte   $17,$BE,$06
        .byte   $F0,$03
        .byte   $01,$C1
        .byte   $03
        .byte   $3F,$80,$1A,$00,$03,$01,$C1,$03
        .byte   $3F,$80,$1E,$04,$01,$37,$BE,$02
        .byte   $80,$03,$3F,$81,$AB,$00,$08,$03
        .byte   $3F,$80,$F0,$03,$3C,$81,$AB,$00
        .byte   $08,$03,$3C,$80,$F0,$03,$39,$81
        .byte   $AB,$00,$08,$03,$39,$80,$F0,$03
        .byte   $36,$81,$AB,$00,$08,$03,$36,$80
        .byte   $F0,$03,$34,$81,$AB,$00,$08,$03
        .byte   $34,$80,$F0,$03,$32,$81,$AB,$00
        .byte   $08,$03,$33,$80,$F0,$06
        .byte   $80,$0A,$01,$60,$05,$01
        .byte   $21,$82
        .byte   $05,$03
        .byte   $39,$81,$FC
        .byte   $00
        .byte   $06,$03,$3F,$80,$07,$01,$30,$80
        .byte   $38,$00,$17,$80,$03,$06,$60,$0A
        .byte   $02,$80,$03,$3F,$01,$FE,$81,$FC
        .byte   $00,$30,$03,$3F,$05,$04,$43,$80
        .byte   $00,$01
        .byte   $FE,$80,$0A
        .byte   $06,$D0
        .byte   $02
        .byte   $00
        .byte   $03,$02,$80,$01,$C1,$03,$3F,$80
        .byte   $1F,$04,$01,$BE,$BE,$00,$08,$01
        .byte   $F8,$03,$3F,$80,$3F,$00,$08,$03
        .byte   $3C,$80,$3F,$00,$08,$03,$3A,$80
        .byte   $3F,$00,$08,$03,$36,$80,$3F,$00
        .byte   $08,$03,$34,$80,$3F,$00,$08,$03
        .byte   $33,$80,$3C,$06
        .byte   $D0,$01
        .byte   $00
        .byte   $03,$02,$80,$01,$C1,$03,$3F,$80
        .byte   $1F,$04,$01,$F5,$BE,$00,$08,$01
        .byte   $F8,$03,$3F,$80,$3F,$00,$08,$03
        .byte   $3C,$80,$3F,$00,$08,$03,$3A,$80
        .byte   $3F,$00,$08,$03,$36,$80,$3F,$00
        .byte   $08,$03,$34,$80,$3F,$00,$08,$03
        .byte   $33,$80,$3F,$06
        .byte   $40,$0A,$02,$00,$01,$F1,$03,$3E
        .byte   $81,$7D,$00,$1D,$03,$3A,$80,$06
        .byte   $06
        .byte   $E0,$08
        .byte   $00
        .byte   $04,$03,$36,$80,$04,$04,$02,$3D
        .byte   $BF,$06
        .byte   $F0,$03
        .byte   $02,$80,$01
        .byte   $2F,$03,$3F,$80,$35,$00,$10,$02
        .byte   $00,$01,$2F,$03,$3F,$80,$3C,$03
        .byte   $3C,$80,$35,$00,$10,$03,$3C,$80
        .byte   $3C,$03,$39,$80,$35,$00,$10,$03
        .byte   $39,$80,$3C,$03,$36,$80,$35,$00
        .byte   $10,$03,$36,$80,$3C,$03,$34,$80
        .byte   $35,$00,$10,$03,$34,$80,$3C,$03
        .byte   $32,$80,$35,$00,$10,$03,$32,$80
        .byte   $3C
        .byte   $06,$F0
        .byte   $02
        .byte   $00
        .byte   $03,$02,$C0,$03,$3F,$80,$64,$00
        .byte   $03,$80,$59,$00,$03,$80,$50,$00
        .byte   $03,$80,$4B,$00,$03,$80,$43,$00
        .byte   $03,$80,$3C,$00,$03,$80,$35,$00
        .byte   $03,$80,$32,$00,$03,$03,$38,$80
        .byte   $64,$00,$03,$80,$59,$00,$03,$80
        .byte   $50,$00,$03,$80,$4B,$00,$03,$80
        .byte   $43,$00,$03,$80,$3C,$00,$03,$80
        .byte   $35,$00,$03,$80,$32,$06,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$78,$EE
        .byte   $E1,$BF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$E0,$BF,$E0,$BF
