.segment "BANK0C"

; =============================================================================
; Bank $0C — Weapons & UI
; Weapon select handler, HUD energy bar rendering, lives display,
; password screen, and CHR-RAM tile upload routines.
; =============================================================================

; da65 V2.18 - Ubuntu 2.19-1
; Created:    2026-02-23 18:17:35
; Input file: build/bank0C.bin
; Page:       1


        .setcpu "6502"

zp_temp_02           := $0002
zp_F4           := $00F4
L0604           := $0604
L0660           := $0660
L1501           := $1501
L1F05           := $1F05
L2260           := $2260
L606C           := $606C
L608A           := $608A
L6868           := $6868
L6A60           := $6A60
L6A6C           := $6A6C
L6D80           := $6D80
L6F6C           := $6F6C
L7171           := $7171
LED06           := $ED06
        jmp     hud_update_main

        .byte   $C9,$FC,$D0,$03,$4C,$29,$81
        cmp     #$FD
        bne     weapon_dispatch_check_fd
        jmp     password_mode_init

weapon_dispatch_check_fd:  cmp     #$FE
        bne     weapon_dispatch_check_ff
        lda     #$01
        sta     $E4
        lda     #$00
        sta     $EC
        jmp     weapon_secondary_init

weapon_dispatch_check_ff:  cmp     #$FF
        bne     weapon_select_handler
        lda     #$01
        sta     $E4
        lda     #$00
        sta     $EC
        jmp     weapon_clear_display


; =============================================================================
; Weapon Selection Handler
; Processes weapon select from pause menu.
; =============================================================================
weapon_select_handler:  asl     a       ; Handle weapon selection (A = weapon index)
        tax
        lda     weapon_data_ptr_lo,x
        sta     $E2
        lda     weapon_data_ptr_hi,x
        sta     $E3
        ldy     #$00
        lda     ($E2),y
        tax
        and     #$0F
        beq     L80BB
        lda     $E0
        and     #$0F
        sta     $E5
        cpx     $E5
        bcs     L804F
        rts

L804F:  stx     $E5
        lda     $E0
        and     #$F0
        ora     $E5
        sta     $E0
        lda     #$01
        sta     $E4
        lda     #$00
        sta     $EC
        lda     #$00
        sta     $E7
        sta     $E8
        lda     #$04
        sta     $E5
        lda     #$01
chr_ram_data_transfer:  clc
        adc     $E2
        sta     $E2
        lda     #$00
        adc     $E3
        sta     $E3
        ldx     $EC
        ldy     #$00
chr_ram_tile_copy:  lda     ($E2),y     ; Copy tile data to CHR-RAM shadow at $0500
        sta     $0500,x
        inx
        iny
        cpy     #$02
L8085:  bne     chr_ram_tile_copy
        .byte   $A0
L8088:  asl     a:$A9
L808B:  sta     $0500,x
        inx
L808F:  dey
        bne     L808B
        lda     $E1
        lsr     a
        bcs     L809A
        jsr     draw_energy_bar_template
L809A:  jsr     display_offset_next_slot
L809D:  dec     $E5
        beq     L80A6
        lda     #$02
        jmp     chr_ram_data_transfer

L80A6:  ldy     #$02
        lda     ($E2),y
        sta     $057C
        iny
        lda     ($E2),y
        sta     $057D
        jsr     L8219
        lda     #$00
        sta     $E4
        rts

L80BB:  lda     $E0
        and     #$F0
        sta     $E5
        cpx     $E5
        bcs     L80C6
        rts

L80C6:  stx     $E5
        lda     $E0
        and     #$0F
        ora     $E5
        sta     $E0
        lda     #$01
        sta     $E4
        lda     #$00
        sta     $EC
        ldx     #$00
        lda     #$02
        clc
        adc     $E2
        sta     $F0
        txa
        adc     $E3
        sta     $F1
        stx     $F2
        stx     $F3
        ldy     #$01
        lda     ($E2),y
        and     #$0F
        tax
        ora     $E1
        pha
        stx     $E1
        lda     #$04
        sta     $E5
        lda     #$02
        sta     $E6
L80FE:  pla
        lsr     a
        pha
        bcc     L810E
        jsr     draw_energy_bar_template
        lda     $E1
        lsr     a
        bcs     L810E
        jsr     L816C
L810E:  jsr     display_offset_next_slot
        lda     #$04
        clc
        adc     $E6
        sta     $E6
        dec     $E5
        bne     L80FE
        jsr     L8219
        lda     $E1
        sta     $EF
        pla
        lda     #$00
        sta     $E4
        rts

        iny
        sty     $E7
        rts


; =============================================================================
; Password Screen
; =============================================================================
password_mode_init:  sty     $E8        ; Enter password screen mode
        lda     #$01
        sta     $E9
        lda     $EA
        and     #$01
        sta     $EA
        rts

weapon_secondary_init:  lda     $E0
        and     #$0F
        sta     $E0
        lda     #$04
        sta     $E5
        lda     #$02
        sta     $E6
L8148:  lda     $E1
        lsr     a
        bcc     L8153
        jsr     draw_energy_bar_template
        jsr     L816C
L8153:  jsr     display_offset_next_slot
        lda     #$04
        clc
        adc     $E6
        sta     $E6
        dec     $E5
        bne     L8148
        lda     #$00
        sta     $E1
        sta     $EF
        lda     #$00
        sta     $E4
        rts

L816C:  lda     $EC
        clc
        adc     #$0A
        tax
        lda     $0500,x
        ora     $0501,x
        bne     L81C4
        ldy     $E5
        ldx     $E6
        jsr     apu_sound_control
        ldx     $EC
        lda     $0500,x
        ora     $0501,x
        bne     L81C4
        rts

weapon_clear_display:  lda     $E0
        and     #$F0
        sta     $E0
        lda     #$00
        sta     $E7
        sta     $E8
        lda     #$04
        sta     $E5
L819C:  lda     #$00
        ldx     $EC
        sta     $0500,x
        sta     $0501,x
        jsr     L8211
        dec     $E5
        bne     L819C
        lda     #$00
        sta     $E4
        rts

draw_energy_bar_template:  ldy     #$0F ; Draw empty 16-tile energy bar
        lda     #$10
        clc
        adc     $EC
        tax
        lda     #$00
L81BC:  sta     $0500,x
        inx
        dey
        bne     L81BC
        rts

L81C4:  lda     $E5
        pha
        lda     $E6
        pha
        lda     $057C
        sta     $E5
        lda     $057D
        sta     $E6
        lda     $EC
        clc
        adc     #$06
        tax
        lda     $0500,x
        and     #$1F
        beq     L81EA
        tay
        lda     #$00
L81E4:  clc
        adc     #$04
        dey
        bne     L81E4
L81EA:  tay
        txa
        clc
        adc     #$0E
        tax
        lda     #$04
L81F2:  pha
        lda     ($E5),y
        sta     $0500,x
        iny
        inx
        pla
        sec
        sbc     #$01
        bne     L81F2
        pla
        sta     $E6
        pla
        sta     $E5
        rts

display_offset_next_slot:  lsr     $E1
        bcc     L8211
        lda     $E1
        ora     #$80
        sta     $E1
L8211:  lda     #$1F
        clc
        adc     $EC
        sta     $EC
        rts

L8219:  lsr     $E1
        lsr     $E1
        lsr     $E1
        lsr     $E1
        rts

apu_sound_control:  cpy     #$01
        beq     L822F
        lda     #$00
        sta     $4000,x
        sta     $4001,x
        rts

L822F:  lda     #$07
        sta     $4015
        rts


; =============================================================================
; HUD Update (Main)
; Called each frame to update weapon energy bars and lives display.
; =============================================================================
hud_update_main:  inc     $EA           ; Main HUD update (energy bars, lives)
        lda     $E4
        beq     L823C
        rts

L823C:  ldx     #$00
        ldy     #$05
        stx     $EC
        sty     $ED
        lda     #$00
        sta     $EB
        lda     #$04
        sta     $EE
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
        lda     $EF
        lsr     a
        bcc     L8266
        jsr     L856D
L8266:  lda     $41
        lsr     a
        bcc     L826E
        jmp     L8286

L826E:  ldy     #$00
        lda     ($EC),y
        iny
        ora     ($EC),y
        beq     L8286
        lda     #$01
        ldy     #$0E
        clc
        adc     ($EC),y
        sta     ($EC),y
        jsr     L86B4
        jmp     L8294

L8286:  lda     $EF
        lsr     a
        bcs     L8294
        ldx     $EB
        inx
        inx
        ldy     $EE
        jsr     apu_sound_control
L8294:  lsr     $EF
        bcc     L829E
        lda     $EF
        ora     #$80
        sta     $EF
L829E:  dec     $EE
        beq     hud_lives_display
        lda     #$04
        clc
        adc     $EB
        sta     $EB
        lda     #$1F
        clc
        adc     $EC
        sta     $EC
        lda     #$00
        adc     $ED
        sta     $ED
        jmp     hud_slot_loop

hud_lives_display:  lda     $E8
        and     #$7F
        beq     L82DD
        cmp     $EA
        bne     L82DD
        lda     $EA
        and     #$01
        sta     $EA
        inc     $E9
        lda     #$10
        cmp     $E9
        bne     L82DD
        lda     $E8
        bmi     L82D9
        lda     #$00
        sta     $E8
L82D9:  lda     #$0F
        sta     $E9
L82DD:  lda     $F2
        beq     L82E3
        dec     $F2
L82E3:  lsr     $EF
        lsr     $EF
        lsr     $EF
        lsr     $EF
        rts

L82EC:  ldy     #$0C
        lda     ($EC),y
        ldy     #$02
        cpy     $EE
        beq     L82F8
        and     #$0F
L82F8:  sta     zp_F4
        lda     $E8
        and     #$7F
        beq     L832B
        lda     $E9
        ldy     #$02
        cpy     $EE
        bne     L8310
        ldx     #$0C
L830A:  clc
        adc     $E9
        dex
        bne     L830A
L8310:  tay
        lda     $E8
        bmi     L8324
        ldx     #$FF
L8317:  inx
        cpx     zp_F4
        beq     L832B
        dey
        bne     L8317
        stx     zp_F4
        jmp     L832B

L8324:  dec     zp_F4
        beq     L832B
        dey
        bne     L8324
L832B:  lda     #$02
        cmp     $EE
        beq     L837C
        ldy     #$0D
        lda     ($EC),y
        tax
        and     #$7F
        beq     L837C
        iny
        cmp     ($EC),y
        beq     L8347
        iny
        lda     ($EC),y
        and     #$0F
        jmp     L836C

L8347:  lda     #$00
        sta     ($EC),y
        iny
        lda     ($EC),y
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     $F5
        txa
        bpl     L835E
        lda     #$00
        sec
        sbc     $F5
        sta     $F5
L835E:  lda     ($EC),y
        and     #$0F
        clc
        adc     $F5
        bpl     L836C
        lda     #$00
        jmp     L8372

L836C:  cmp     zp_F4
        bcc     L8372
        lda     zp_F4
L8372:  sta     zp_F4
        lda     ($EC),y
        and     #$F0
        ora     zp_F4
        sta     ($EC),y
L837C:  lda     $EF
        lsr     a
        bcs     L8388
        lda     #$0C
        sta     $F5
        jmp     L838F

L8388:  lda     #$09
        sta     $F5
        jmp     L83FE

L838F:  ldy     #$16
        lda     ($EC),y
        and     #$7F
        beq     L83D5
        ldy     #$1D
        cmp     ($EC),y
        beq     L83A0
        jmp     L83CB

L83A0:  lda     #$00
        sta     ($EC),y
        ldy     #$17
        lda     ($EC),y
        ldy     #$1E
        clc
        adc     ($EC),y
        beq     L83B1
        bpl     L83B8
L83B1:  lda     #$01
        sta     ($EC),y
        jmp     L83C2

L83B8:  sta     ($EC),y
        cmp     #$10
        bcc     L83CB
        lda     #$0F
        sta     ($EC),y
L83C2:  lda     #$00
        ldy     #$17
        sec
        sbc     ($EC),y
        sta     ($EC),y
L83CB:  ldy     #$1E
        lda     ($EC),y
        cmp     zp_F4
        bcs     L83D5
        sta     zp_F4
L83D5:  ldy     #$02
        cpy     $EE
        beq     L83E8
        lda     $F5
        and     #$7F
        tay
        lda     ($EC),y
        and     #$F0
        ora     zp_F4
        sta     zp_F4
L83E8:  ldx     $EB
        lda     zp_F4
        sta     $4000,x
        lda     $F5
        bpl     L83FA
        lda     #$90
        sta     $F5
        jmp     L83FE

L83FA:  lda     #$09
        sta     $F5
L83FE:  lda     $F5
        and     #$7F
        tay
        ldx     #$00
        lda     ($EC),y
        beq     L8418
        bpl     L840C
        dex
L840C:  iny
        clc
        adc     ($EC),y
        sta     ($EC),y
        txa
        iny
        adc     ($EC),y
        sta     ($EC),y
L8418:  lda     $F5
        bmi     L8422
        lda     $EF
        lsr     a
        bcc     L8422
        rts

L8422:  ldy     #$14
        lda     ($EC),y
        and     #$7F
        bne     L842D
        jmp     L84A9

L842D:  ldy     #$18
        cmp     ($EC),y
        beq     L8436
        jmp     L84A9

L8436:  lda     #$00
        sta     ($EC),y
        tax
        ldy     #$15
        lda     ($EC),y
        rol     a
        rol     a
        rol     a
        rol     a
        and     #$07
        sta     zp_F4
        ldy     #$19
        lda     ($EC),y
        asl     a
        bcc     L8456
        lda     #$00
        sec
        sbc     zp_F4
        sta     zp_F4
        dex
L8456:  lda     zp_F4
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
        sta     zp_F4
        ldy     #$19
        lda     ($EC),y
        clc
        adc     #$01
        sta     ($EC),y
        and     #$7F
        cmp     zp_F4
        bne     L84A9
        lda     ($EC),y
        and     #$80
        sta     ($EC),y
        ldy     #$14
        lda     ($EC),y
        asl     a
        bcs     L84A3
        lda     ($EC),y
        ora     #$80
        sta     ($EC),y
        ldy     #$19
        lda     ($EC),y
        bpl     L849C
        and     #$7F
        sta     ($EC),y
        jmp     L84A9

L849C:  ora     #$80
        sta     ($EC),y
        jmp     L84A9

L84A3:  lda     ($EC),y
        and     #$7F
        sta     ($EC),y
L84A9:  lda     $F5
        and     #$7F
        sta     $F5
        inc     $F5
        ldy     #$1A
        lda     ($EC),y
        ldy     $F5
        clc
        adc     ($EC),y
        tax
        ldy     #$1B
        lda     ($EC),y
        inc     $F5
        ldy     $F5
        adc     ($EC),y
        tay
        lda     #$01
        cmp     $EE
        bne     L84E5
        lda     #$0F
        sta     $4015
        txa
        and     #$0F
        tax
        inc     $F5
        ldy     $F5
        lda     ($EC),y
        and     #$80
        sta     zp_F4
        txa
        ora     zp_F4
        tax
        ldy     #$00
L84E5:  txa
        ldx     $EB
        inx
        inx
        sta     $4000,x
        tya
        ldy     #$1C
        cmp     ($EC),y
        bne     L84F5
        rts

L84F5:  sta     ($EC),y
        ora     #$08
        sta     $4001,x
        rts

L84FD:  ldy     #$01
        cpy     $EE
        bne     L8509
        lda     #$07
        sta     $4015
        rts

L8509:  lda     #$00
        ldx     $EB
        inx
        inx
        sta     $4000,x
        sta     $4001,x
        rts

L8516:  ldy     #$14
        lda     ($EC),y
        and     #$7F
        sta     ($EC),y
        ldy     #$16
        lda     ($EC),y
        asl     a
        bcc     L8535
        ldy     zp_F4
        lda     ($EC),y
        ldx     #$02
        cpx     $EE
        beq     L8531
        and     #$0F
L8531:  ldy     #$1E
        sta     ($EC),y
L8535:  ldx     #$06
        lda     #$00
        ldy     #$18
L853B:  sta     ($EC),y
        iny
        dex
        bne     L853B
        lda     #$FF
        ldy     #$1C
        sta     ($EC),y
        rts

L8548:  ldy     #$1C
        lda     ($EC),y
        pha
        jsr     L8516
        pla
        ldy     #$1C
        sta     ($EC),y
        rts

L8556:  txa
        asl     a
        tay
        iny
        pla
        sta     zp_F4
        pla
        sta     $F5
        lda     (zp_F4),y
        tax
        iny
        lda     (zp_F4),y
        sta     $F5
        stx     zp_F4
        jmp     (zp_F4)

L856D:  lda     $F2
        bne     L8574
        jmp     L8592

L8574:  ldy     #$11
        lda     ($EC),y
        iny
        ora     ($EC),y
        bne     L857E
        rts

L857E:  iny
        lda     ($EC),y
        ldy     #$02
        cpy     $EE
        beq     L8589
        and     #$0F
L8589:  sta     zp_F4
        lda     #$93
        sta     $F5
        jmp     L838F

L8592:  jsr     L86A0
        asl     a
        bcs     L859B
        jmp     L85C2

L859B:  txa
        and     #$0F
        cmp     #$0F
        bne     L85A8
        jsr     L86A0
        jmp     L8548

L85A8:  and     #$07
        sta     zp_F4
        jsr     L86A0
        ldy     #$11
        sta     ($EC),y
        iny
        lda     zp_F4
        sta     ($EC),y
        lda     #$13
        sta     zp_F4
        jsr     L8516
        jmp     L84FD

L85C2:  jsr     L8556
        .byte   $D3,$85,$DB,$85,$E5,$85,$F5,$85
        .byte   $0F
        stx     $40
        stx     $56
        stx     $20
        ldy     #$86
        sta     $F2
        jmp     L8592

        .byte   $20,$A0,$86,$A0,$10,$91
        cpx     L924C
        sta     $20
        ldy     #$86
        sta     zp_F4
        ldy     #$13
        lda     ($EC),y
        and     #$3F
        ora     zp_F4
        jmp     L8608

        jsr     L86A0
        ldy     #$02
        cpy     $EE
        beq     L8608
        sta     zp_F4
        ldy     #$13
        lda     ($EC),y
        and     #$C0
        ora     zp_F4
L8608:  ldy     #$13
        sta     ($EC),y
        jmp     L8592

        .byte   $20,$A0,$86,$8A,$F0,$06,$E4,$F3
        .byte   $F0,$13,$E6,$F3
        jsr     L86A0
        sta     zp_F4
        jsr     L86A0
        sta     $F1
        lda     zp_F4
        sta     $F0
        jmp     L8592

        lda     #$00
        sta     $F3
        lda     #$02
        clc
        adc     $F0
        sta     $F0
        lda     #$00
        adc     $F1
        sta     $F1
        jmp     L8592

        .byte   $A9,$14,$85,$F4
L8644:  jsr     L86A0
        ldy     zp_F4
        sta     ($EC),y
        inc     zp_F4
        ldy     zp_F4
        cpy     #$18
        bne     L8644
        jmp     L8592

        .byte   $A5,$F0,$38,$E9,$01,$85,$F0,$A5
        .byte   $F1,$E9,$00,$85,$F1,$A5,$E0,$29
        .byte   $0F,$85,$E0,$A9,$00,$85,$E1,$A5
        .byte   $EF,$29,$FE,$85,$EF,$A0,$0A,$B1
        .byte   $EC,$C8,$11,$EC,$D0,$13,$A6,$EB
        .byte   $E8,$E8
        ldy     $EE
        jsr     apu_sound_control
        ldy     #$00
        lda     ($EC),y
        iny
        ora     ($EC),y
        bne     L868F
        rts

L868F:  ldy     #$06
        lda     ($EC),y
        and     #$1F
        tax
        jsr     L88E1
        lda     #$0C
        sta     zp_F4
        jmp     L8516

L86A0:  ldy     #$00
        lda     ($F0),y
        tax
        lda     #$01
        clc
        adc     $F0
        sta     $F0
        lda     #$00
        adc     $F1
        sta     $F1
        txa
        rts

L86B4:  lda     $E7
        beq     L86C3
L86B8:  pha
        jsr     L86C3
        pla
        sec
        sbc     #$01
        bne     L86B8
        rts

L86C3:  ldy     #$05
        lda     ($EC),y
        asl     a
        bcc     L86D3
        lda     $EA
        and     #$01
        beq     L86D3
        jsr     L86D3
L86D3:  ldy     #$02
        lda     ($EC),y
        iny
        ora     ($EC),y
        beq     L86FE
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
        beq     L86FE
        ldy     #$0A
        lda     ($EC),y
        iny
        ora     ($EC),y
        bne     L86FB
        rts

L86FB:  jmp     L82EC

L86FE:  ldy     #$05
        lda     ($EC),y
        and     #$7F
        sta     ($EC),y
L8706:  jsr     L8935
        and     #$F0
        bne     L8710
        jmp     L87C0

L8710:  cmp     #$20
        bne     L871F
        txa
        and     #$07
        pha
        jsr     L8706
        pla
        jmp     L87A2

L871F:  cmp     #$30
        bne     L8726
        jmp     L87B5

L8726:  txa
        rol     a
        rol     a
        rol     a
        rol     a
        and     #$07
        tay
        lda     weapon_shift_table_1,y
        jsr     L8954
L8734:  ldy     #$06
        lda     ($EC),y
        and     #$E0
        beq     L8752
        sec
        sbc     #$20
        sta     zp_F4
        lda     ($EC),y
        and     #$1F
        ora     zp_F4
        sta     ($EC),y
        lda     $EF
        lsr     a
        bcc     L874F
        rts

L874F:  jmp     L8548

L8752:  txa
        and     #$1F
        bne     L875B
        tax
        jmp     L877D

L875B:  ldy     #$01
        cpy     $EE
        bne     L8766
        ldx     #$00
        jmp     L877D

L8766:  asl     a
        ldy     #$07
        clc
        adc     ($EC),y
        sta     zp_F4
        lda     #$00
        iny
        adc     ($EC),y
        sta     $F5
        ldy     #$01
        lda     (zp_F4),y
        tax
        dey
        lda     (zp_F4),y
L877D:  ldy     #$0A
        sta     ($EC),y
        iny
        txa
        sta     ($EC),y
        ldy     #$0D
        lda     ($EC),y
        sta     zp_F4
        and     #$7F
        beq     L8792
        jsr     L88A9
L8792:  lda     $EF
        lsr     a
        bcc     L8798
        rts

L8798:  lda     #$0C
        sta     zp_F4
        jsr     L8516
        jmp     L84FD

L87A2:  ror     a
        ror     a
        ror     a
        ror     a
        and     #$E0
        sta     zp_F4
        ldy     #$06
        lda     ($EC),y
        and     #$1F
        ora     zp_F4
        sta     ($EC),y
        rts

L87B5:  lda     #$80
        ldy     #$05
        ora     ($EC),y
        sta     ($EC),y
        jmp     L8706

L87C0:  jsr     L8556
        .byte   $D7,$87,$E1,$87,$EB,$87,$FB,$87
        .byte   $15,$88,$5D,$88,$7A,$88,$8D,$88
        .byte   $C7,$88,$17,$89,$20,$35,$89,$A0
        .byte   $04,$91,$EC,$4C,$06,$87,$20,$35
        .byte   $89,$A0,$09,$91,$EC,$4C,$06,$87
        .byte   $20,$35,$89,$85,$F4,$A0,$0C,$B1
        .byte   $EC,$29,$3F,$05,$F4,$4C,$0E,$88
        .byte   $20,$35,$89,$A0,$02
        cpy     $EE
        beq     L880E
        sta     zp_F4
        ldy     #$0C
        lda     ($EC),y
        and     #$C0
        ora     zp_F4
L880E:  ldy     #$0C
        sta     ($EC),y
        jmp     L8706

        .byte   $20,$35,$89,$8A,$F0,$16,$A0,$05
        .byte   $B1,$EC
        and     #$7F
        sta     zp_F4
        cpx     zp_F4
        beq     L8844
        inc     zp_F4
        lda     ($EC),y
        and     #$80
        ora     zp_F4
        sta     ($EC),y
        jsr     L8935
        pha
        jsr     L8935
        pla
        ldy     #$00
        sta     ($EC),y
        iny
        txa
        sta     ($EC),y
        jmp     L8706

L8844:  lda     ($EC),y
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
        jmp     L8706

        .byte   $20,$35,$89
        ldx     #$85
        ldy     #$89
        stx     zp_F4
        sty     $F5
        asl     a
        ldy     #$07
        clc
        adc     zp_F4
        sta     ($EC),y
        lda     #$00
        adc     $F5
        iny
        sta     ($EC),y
        jmp     L8706

        .byte   $20,$35,$89,$2A,$2A,$2A
L8880:  rol     a
        and     #$07
        tay
        .byte   $B9
L8885:  adc     $2089,x
        .byte   $54
        .byte   $89
L888A:  .byte   $4C
        .byte   $34
L888C:  .byte   $87
L888D:  jsr     L8935
        ldy     #$0D
        sta     ($EC),y
        pha
        jsr     L8935
        ldy     #$0F
        sta     ($EC),y
        pla
        sta     zp_F4
        and     #$7F
        beq     L88A6
        jsr     L88A9
L88A6:  jmp     L8706

L88A9:  lda     #$00
        ldy     #$0E
        sta     ($EC),y
        lda     zp_F4
        bpl     L88B8
        lda     #$0F
        jmp     L88BA

L88B8:  lda     #$00
L88BA:  sta     zp_F4
        ldy     #$0F
        lda     ($EC),y
        and     #$F0
        ora     zp_F4
        sta     ($EC),y
        rts

        .byte   $20
        and     $89,x
        sta     zp_F4
        ldy     #$06
        lda     ($EC),y
        and     #$E0
        ora     zp_F4
        sta     ($EC),y
        lda     $EF
        lsr     a
        bcs     L88DE
        jsr     L88E1
L88DE:  jmp     L8706

L88E1:  txa
        beq     L88EC
        lda     #$00
L88E6:  clc
        adc     #$04
        dex
        bne     L88E6
L88EC:  clc
        adc     $057C
        sta     zp_F4
        lda     #$00
        adc     $057D
        sta     $F5
        ldx     #$00
        ldy     #$14
L88FD:  lda     (zp_F4,x)
        sta     ($EC),y
        iny
        cpy     #$18
        bne     L8907
        rts

L8907:  lda     #$01
        clc
        adc     zp_F4
        sta     zp_F4
        lda     #$00
        adc     $F5
        sta     $F5
        jmp     L88FD

        .byte   $A0,$00,$A9,$00,$91,$EC,$C8,$91
        .byte   $EC,$A5,$E0,$29,$F0,$85,$E0,$A5
        .byte   $EF,$4A,$90,$01,$60
        ldx     $EB
        inx
        inx
        ldy     $EE
        jmp     apu_sound_control

L8935:  ldy     #$00
        lda     ($EC),y
        sta     zp_F4
        iny
        lda     ($EC),y
        sta     $F5
        dey
        lda     (zp_F4),y
        tax
        lda     #$01
        clc
        adc     zp_F4
        sta     ($EC),y
        lda     #$00
        adc     $F5
        iny
        sta     ($EC),y
        txa
        rts

L8954:  sta     zp_F4
        lda     #$00
        sta     $F5
        ldy     #$04
        lda     ($EC),y
        tay
        lda     #$00
L8961:  clc
        adc     zp_F4
        bcc     L8968
        inc     $F5
L8968:  dey
        bne     L8961
        ldy     #$02
        sta     ($EC),y
        iny
        lda     $F5
        sta     ($EC),y
        rts

weapon_shift_table_1:  .byte   $00,$00,$02,$04,$08,$10,$20,$40
weapon_shift_table_2:  .byte   $00,$00,$03,$06,$0C,$18,$30,$60
        .byte   $00,$00,$00,$00
        brk
        brk
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$F2,$07,$D6,$07
        .byte   $14,$07,$AE,$06,$4E
        asl     $F3
        ora     $94
        ora     $4D
        ora     $01
        ora     $BB
        .byte   $04,$75,$04,$36,$04,$F9,$03,$BF
        .byte   $03,$8A,$03,$57,$03,$27,$03,$FA
        .byte   $02,$CF,$02,$A7,$02,$81,$02,$5D
        .byte   $02,$3B,$02,$1A,$02,$FC,$01
        cpx     #$01
        cmp     $01
        .byte   $AB,$01,$93,$01,$7D,$01,$67,$01
        .byte   $53,$01,$40,$01,$2E,$01,$1D,$01
        .byte   $0D
        ora     ($FE,x)
        brk
        .byte   $F0,$00,$E2,$00
        cmp     $00,x
        cmp     #$00
        ldx     LB300,y
        brk
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
weapon_data_ptr_lo:  .byte   $D6
weapon_data_ptr_hi:  .byte   $8A,$1D,$8E,$C8,$90,$87,$94,$98
        .byte   $96,$42,$9A,$48,$9E,$91,$A1,$A8
        .byte   $A4,$60,$A9,$A0,$AB,$58,$AC,$14
        .byte   $AE,$F4,$AE,$B4,$B1,$57,$B3,$D5
        .byte   $B3,$A6,$B4,$53,$B5,$8E,$B5,$DC
        .byte   $B6,$EA,$B9,$52,$BA,$ED,$BA
L8A80:  .byte   $57,$B3,$57,$B3,$57,$B3,$57,$B3
        .byte   $57,$B3
L8A8A:  .byte   $57,$B3
L8A8C:  .byte   $57,$B3,$57,$B3,$57,$B3,$22,$BB
        .byte   $5B,$BB,$8E,$BB,$B6,$BB,$C8,$BB
        .byte   $D5,$BB,$03,$BC
        and     $4CBC
        ldy     LBC62,x
        .byte   $9B,$BC,$B5,$BC,$F1,$BC,$00,$BD
        .byte   $25,$BD,$3D,$BD,$5D,$BD,$78,$BD
        .byte   $8F,$BD,$98,$BD,$B7,$BD,$CC,$BD
        .byte   $E1,$BD,$F6,$BD,$15,$BE,$35
        ldx     LBE88,y
        ldy     $BE
        ldy     $F3BE,x
        ldx     LBF2A,y
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
        php
        ora     ($A5,x)
        php
        brk
        dey
        .byte   $87,$80,$87,$80
        dey
        txa
        .byte   $87,$21,$85,$21,$A5,$08,$01,$A5
        .byte   $08,$00,$80,$85,$88,$8C,$02,$C0
        .byte   $07,$A2,$10,$21,$CF,$08,$01,$CF
        .byte   $08,$00,$21,$AE,$08,$01,$AE
        php
        brk
        .byte   $21,$AD
        php
        ora     ($AD,x)
        php
        brk
        .byte   $02,$80,$88,$06,$A5,$80,$85,$88
        .byte   $8A,$8B,$8C,$8B,$8C,$8A,$88,$85
        .byte   $83,$02,$C0,$21,$CF,$08,$01,$CF
        .byte   $08,$00,$21,$AE,$08,$01,$AE,$08
        .byte   $00,$21,$AD,$08,$01,$AD,$08,$00
        .byte   $02,$80,$88,$06,$A5,$80,$85,$88
        .byte   $8A,$91,$8C,$8C,$8C,$90,$93
        stx     $98,y
        .byte   $04,$00,$4D,$8B,$00,$06,$02,$00
        .byte   $05,$17,$07,$E0,$10,$03,$38,$80
        .byte   $A5,$68
        rts

        jmp     (L0660)

        .byte   $8F,$06,$8E
        txa
        asl     $8D
        asl     $8C
        dey
        ror     a
        rts

        .byte   $68,$60
        adc     $63
        rts

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
L8C76:  sta     $63
        adc     $60
        adc     $60
        .byte   $63,$85,$04,$03
L8C80:  lsr     $028C,x
        cpy     #$03
        .byte   $3A,$07,$A2
        bpl     L8C76
L8C8A:  .byte   $CB,$CA,$07
L8C8D:  .byte   $86
L8C8E:  .byte   $10,$02
        brk
        .byte   $80
        dey
        txa
        dey
        sty     L8088
        dey
        txa
        dey
        sty     L8088
        dey
        .byte   $87,$88,$04,$01,$82,$8C,$04,$00
        .byte   $5C
        sty     $0600
        .byte   $03,$25,$05,$23,$03,$30
        lda     $68
        rts

        .byte   $6C,$60,$06,$8F,$06,$8E,$8A,$06
        .byte   $8D,$06,$8C,$88,$6A,$60,$68,$60
        .byte   $65,$63,$60,$85,$60,$85,$65,$60
        sta     $65
        rts

        .byte   $85,$65,$60,$85,$65,$60,$85,$67
        .byte   $60,$87,$68,$60,$6C,$60,$A3,$04
        .byte   $02,$B1,$8C,$A5,$68,$60,$6C,$60
        .byte   $06,$8F,$06,$8E,$8A,$06,$8D,$06
        .byte   $8C,$88,$6A,$60,$68,$60,$65,$63
        .byte   $60,$85,$60,$85,$65,$60,$85,$65
        .byte   $60
        sta     $65
        rts

        sta     $63
        .byte   $63
L8D06:  .byte   $60,$63,$60,$63,$60,$63,$65,$01
L8D0E:  bpl     L8D88
        sei
        .byte   $67,$66,$65,$64,$63,$05,$23,$03
        .byte   $30,$01,$00
        sta     $85
        .byte   $80,$85,$65
        pla
        rts

        .byte   $6C,$60,$68,$85,$85,$85,$80,$85
        .byte   $65,$68,$60,$6C,$60
        pla
        sta     $83
        .byte   $83,$80,$83,$63,$67,$60,$6A,$60
        .byte   $67,$83,$85,$85,$80,$85,$65,$68
        .byte   $60,$6C,$60,$68,$85,$04,$01,$16
        .byte   $8D,$01,$00,$05,$23,$68,$60,$88
        .byte   $68,$60,$88,$68,$60,$88,$68,$60
        .byte   $88,$67,$60,$87,$67,$60,$87,$66
        .byte   $60,$86,$66,$60,$86,$80,$85,$87
        .byte   $85,$88
L8D6D:  sta     $80
        sta     $01
        bpl     L8D0E
        .byte   $9B,$8B,$8B,$7D,$7D,$8B,$8A,$8A
        .byte   $04,$01,$4C,$8D,$04
L8D80:  .byte   $00,$16,$8D,$00,$06,$07,$84,$A0
L8D88:  .byte   $03,$3F
        ora     ($05,x)
L8D8C:  .byte   $66
L8D8D:  ora     ($00,x)
        .byte   $07,$82,$60,$03
        rol     $64,x
        .byte   $64,$64,$04,$3B,$85,$8D,$07,$81
        bpl     L8DA2
        and     $1201,y
L8DA2:  ror     $66
        rts

        .byte   $66,$60,$66,$60,$66,$63,$63,$64
        .byte   $64,$65
L8DAF:  .byte   $65
L8DB0:  .byte   $66
L8DB1:  ror     $03
        rol     $1001,x
        .byte   $07,$82,$A0,$A4,$07,$84,$60
L8DBD:  .byte   $06,$8D,$07,$82,$A0,$64,$64,$64
        .byte   $84,$07,$84,$60,$AD,$04,$07,$B2
        sta     display_offset_next_slot
        ldy     #$84
        sty     $04
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
        brk
        ora     $03
        and     $1905,x
        .byte   $02,$80
L8E30:  .byte   $07,$84,$70,$01,$30,$AB,$AB,$8B
        .byte   $8D,$AB,$8B,$8B,$80,$AB,$8B,$AB
        .byte   $04,$01,$35,$8E,$01,$00,$02,$C0
        .byte   $07,$88,$10,$77,$76,$75,$74,$73
        .byte   $72,$71,$70,$6F,$6E,$6D,$6C,$6B
        .byte   $6A,$96,$80,$96,$A0,$96,$80,$96
        .byte   $02,$80,$05,$25,$03,$3C,$22,$88
        .byte   $07,$90,$10,$A8,$08,$01,$A8,$08
        .byte   $00,$88,$87,$80,$88,$80,$85,$80
        .byte   $85,$88,$80
        ldy     LAA21
        php
        ora     ($AA,x)
        php
        brk
        .byte   $AA,$88,$8C,$80,$CA
        txa
        dey
        asl     $CA
        .byte   $80,$8A
        asl     $AC
        tax
        tay
        .byte   $A7,$87,$88,$87,$C5,$8A,$80,$8A
        .byte   $A0,$8A,$80,$8A,$21,$88,$04,$01
        .byte   $68,$8E,$21,$A8,$08,$01,$A8,$08
        .byte   $00,$88,$87,$80,$88,$80,$85,$80
        .byte   $85,$88,$80,$AC,$06,$CA,$80,$88
        .byte   $A3,$A5,$A7,$AA,$21,$AB,$08,$01
        .byte   $AB
        php
        brk
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
L8F46:  .byte   $80,$93,$A0,$93,$80,$93,$04,$01
        .byte   $19,$8F,$80,$05,$25,$03,$38,$02
        .byte   $80,$07,$92,$10,$08,$01,$21,$88
        .byte   $C8,$88,$87,$80,$88,$80,$85,$80
        .byte   $85,$88,$80,$AC,$06,$CA,$80,$88
        .byte   $A3,$A5,$A7,$AA,$CB,$8B,$8A,$80
        .byte   $8B,$80,$8B,$8B,$80,$A8,$8B,$08
        .byte   $00,$07
L8F80:  dey
        bpl     L8F86
        .byte   $3A,$73,$72
L8F86:  adc     ($70),y
        .byte   $6F,$6E,$6D,$6C
L8F8C:  .byte   $6B
L8F8D:  ror     a
        adc     #$68
        .byte   $67
        ror     $87
        .byte   $80,$87,$A0,$87,$80,$87,$04,$00
        .byte   $19,$8F
        brk
        ora     $03
        ora     $05,x
        and     ($01),y
        bpl     L8F46
        .byte   $A7
        .byte   $04,$05,$A5,$8F,$91
        adc     ($71),y
        stx     L8C8E
        sty     L8A8A
        ora     ($00,x)
        ora     $25
        adc     ($70),y
        .byte   $6F,$6E,$6D,$6C,$6B,$6A,$69,$68
        .byte   $67,$66,$65,$64,$83,$80,$83,$80
        .byte   $01,$10,$7D,$7D,$9D
        sta     $019D,x
        brk
        and     ($85,x)
        sta     $65
        adc     $04
        .byte   $07,$D5,$8F,$86,$66,$66,$04,$06
        .byte   $DC,$8F,$86,$21,$83,$83,$63,$63
        .byte   $04,$02,$E6,$8F,$83,$21,$84,$84
        .byte   $64,$64,$04,$03,$F0,$8F,$80,$85
        .byte   $87,$85,$88,$85,$80,$83,$80,$83
        .byte   $80,$63,$63,$83,$80
L9006:  .byte   $83
        and     ($85,x)
        sta     $65
        adc     $04
        .byte   $07,$09,$90,$86,$66,$66,$04,$06
        .byte   $10,$90
        stx     $21
        .byte   $83,$83,$63,$63,$04,$02,$1A,$90
        .byte   $83,$21,$84,$84,$64,$64,$04,$03
        .byte   $24,$90,$80,$85,$87,$85,$88
L9030:  sta     $80
        .byte   $83,$80,$83,$80,$63,$63,$83,$80
        .byte   $83,$21,$81,$81,$61,$61,$81,$81
        .byte   $04,$03,$3D,$90,$83,$63,$63,$83
        .byte   $83,$04,$03,$46,$90,$84,$64,$64
        .byte   $84,$84,$04,$03,$4F,$90,$65,$65
        .byte   $65,$60,$65,$60,$65,$65,$60,$65
        .byte   $65,$60,$65
        adc     $84
        .byte   $80,$84,$80,$01,$10,$7D,$7D,$9D
        .byte   $9D,$9D,$01,$00,$21,$85,$04,$00
        .byte   $D5,$8F,$00,$05,$01,$10,$07,$83
        .byte   $60,$03,$3D,$A0
L9083:  .byte   $AC,$04,$07,$82,$90,$07,$83,$60
        .byte   $01
        sbc     $0465,x
        .byte   $03
        sta     $6890
        .byte   $04,$03,$92,$90,$6A,$6A,$6A,$6C
        .byte   $6C,$6C,$01,$10,$8C,$80,$8C,$A0
        .byte   $8C,$80,$8C,$8C,$01,$10,$07,$82
        .byte   $A0,$84,$64,$64,$07,$84,$60,$8A
        .byte   $07,$82,$A0,$64,$64,$04,$2B,$A9
        .byte   $90,$04,$00
        dey
        bcc     L90C1
L90C1:  brk
        .byte   $80,$00,$02,$41,$80,$00,$0F,$D3
        .byte   $90,$70,$92,$91,$93,$30,$94,$7F
        .byte   $94,$00,$06,$03,$3C,$07,$8A,$10
        .byte   $02,$40,$05,$17,$88,$A0,$85,$A6
        .byte   $87,$60,$68,$60,$68,$68,$60,$88
        .byte   $85,$A6,$87,$88,$88,$A0,$85,$A6
        .byte   $87,$60,$68,$60,$68,$68,$60,$88
        .byte   $85
        stx     $05
        .byte   $23,$74,$60
        ldy     $05,x
        .byte   $17
        dey
        ldy     #$85
        ldx     $87
        rts

        .byte   $68,$60,$68,$68,$60
        dey
        sta     $05
        .byte   $23,$74,$74,$60,$74,$76,$77
        ror     $74,x
        ora     $17
        dey
        ldy     #$85
        ldx     $A7
        ora     $23
        .byte   $74,$60,$04,$04,$21,$91,$60,$74
        .byte   $76,$77,$76,$74,$07
        dey
        bpl     L91A2
        ldy     #$60
        .byte   $6F,$60,$B2,$91,$60,$6F,$60,$6F
        .byte   $6F,$60,$6F,$60,$6F,$60,$B2,$91
        .byte   $90,$6F,$A0,$60,$6F,$60,$B2,$91
        .byte   $60,$6F,$60,$6F,$6F,$60,$6F,$60
        .byte   $6F,$60,$80,$74,$60,$B4,$04,$01
        .byte   $2F,$91,$07,$90,$10,$03,$3D,$02
        .byte   $80,$8C,$80,$8C,$60,$6C,$6C,$60
        .byte   $6C,$60,$6C,$6A,$68
        asl     $8A
        tay
        ldy     #$88
        txa
        dey
        sty     L8C80
        rts

        .byte   $6C,$8D,$8C,$80,$22,$AF,$08,$01
        .byte   $AF,$01,$06
L9188:  .byte   $AF,$01,$00,$08,$00,$74,$60
L918F:  ldy     $8F,x
        .byte   $80,$8F,$60,$6F,$6F,$60,$6F,$60
        .byte   $6F,$6D,$6C,$06,$8D,$AC,$A0
        .byte   $8C
        .byte   $8D
L91A2:  sty     L808F
        .byte   $8F,$60,$6F,$91,$8F,$80,$22,$B2
        .byte   $08,$01,$B2,$01,$06,$B2,$01,$00
        .byte   $08,$00,$74,$60,$B4,$94,$80,$94
        .byte   $60,$74,$74,$60,$74,$60,$74,$71
        .byte   $6F,$06,$91,$AF,$A0,$8F,$91,$8F
        .byte   $94,$80,$94,$60,$74,$96
        sty     $80,x
        and     ($B7,x)
        .byte   $B7
        ora     ($06,x)
        .byte   $B7,$01,$00,$08,$00,$74,$60,$B4
        .byte   $05,$2F,$8C,$80,$8C,$60,$6C,$6C
        .byte   $60,$6C,$60,$6C,$6A,$68,$06,$8A
        .byte   $A8,$A0
        dey
        txa
        dey
        sty     L8C80
        rts

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
L924C:  .byte   $01,$AF,$08,$00,$6D,$60,$6D,$60
        .byte   $6D,$8F,$6F,$04,$02,$42,$92,$B1
        .byte   $91,$60,$71,$91,$B4,$91,$6F,$6F
        .byte   $60,$74,$74,$60,$78,$78,$C0,$04
        .byte   $00,$2F,$91,$09,$00,$06,$07,$8A
        .byte   $10,$02,$40,$03
        rol     $05,x
        .byte   $17,$60,$88,$A0,$85,$A6,$87,$60
        .byte   $68,$60,$68,$68,$60,$88,$85,$A6
        .byte   $87,$88,$88,$A0,$85,$A6,$87,$60
        .byte   $68,$60
        pla
        pla
        rts

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
        ror     a
        rts

        .byte   $6A,$8C,$6C,$04,$02,$67,$93,$AD
        .byte   $8D,$60,$6D
        sta     L8DB1
        jmp     (L606C)

        .byte   $6F,$6F,$60,$74,$74,$C0,$04,$00
        cpy     $0992
        brk
        asl     $03
        and     $05
        .byte   $23,$88,$80,$01,$10,$94,$01,$00
        .byte   $85,$A6,$87,$60,$68,$60,$68,$68
        .byte   $01,$10,$74,$94,$01,$00,$85,$86
        .byte   $92,$87,$93,$04,$02,$97,$93,$88
        .byte   $80,$01,$10,$94,$01,$00,$85,$A6
        .byte   $87,$88,$88,$88,$88,$88,$68,$01
        .byte   $10,$7D,$7D,$7D,$7A,$7A,$78,$78
        ora     ($00,x)
        dey
        .byte   $80,$01,$10,$94
        ora     ($00,x)
        sta     $A6
        .byte   $87,$60
        pla
        rts

        .byte   $68,$68,$01,$10,$74,$94,$01,$00
        .byte   $85,$86,$92,$87,$93,$04,$0F,$CE
        .byte   $93,$06,$86,$06,$8A,$8D,$60,$71
        .byte   $6D,$6A,$6D,$6A,$66,$65,$06,$88
        .byte   $06,$8C,$8F
        ror     $60
        ror     $60
        ror     $88
        pla
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
L9468:  .byte   $65,$04,$02,$5D,$94,$A0,$A5,$A0
        .byte   $A5,$63,$63,$60,$64,$64,$60,$65
        .byte   $65,$A0,$A5,$04,$00,$48,$94,$00
        .byte   $00,$80,$00,$01,$62,$80,$00,$0F
        .byte   $92,$94,$64,$95,$1C,$96,$71
        stx     $98,y
        stx     $00,y
        asl     zp_temp_02
        brk
        .byte   $03,$38
L9498:  ora     $15
        .byte   $07
        sty     $60
        adc     $65
        adc     ($65),y
        .byte   $6F,$70,$65,$71,$65,$6C,$65,$6B
        .byte   $65,$6A,$69,$68,$65,$65,$6F,$65
        .byte   $6D,$6E,$65,$6F,$65,$6A,$65,$69
        .byte   $65,$68,$67,$66,$04,$02,$9D,$94
        .byte   $65,$65,$71,$65,$6F,$70,$65,$71
        .byte   $65,$6C,$65,$6B,$65,$6A,$69,$68
        .byte   $6F,$6F,$60
        jmp     (L7171)

        .byte   $60,$6C,$6C,$6F,$6C,$71,$A0,$03
        .byte   $3A,$07,$02,$A0,$05,$21,$02,$40
        .byte   $21,$AC,$AC,$6C,$60,$6C,$60,$6C
        .byte   $6A,$68,$21,$AA,$AA,$6A,$6A,$60
        .byte   $6C,$60,$6A,$67,$60,$88,$02,$80
        .byte   $65,$68,$6C,$71,$60,$6C,$60,$6A
        .byte   $6C,$60
        ror     a
        rts

        .byte   $63,$65,$67,$71,$60,$71,$73,$74
        .byte   $78,$60,$71,$60,$6C,$6F,$71,$74
        .byte   $73,$71,$6F,$02,$40,$21,$AC,$AC
        .byte   $6C,$60,$6C,$60,$6C,$6A,$68,$21
        .byte   $AA,$AA
        ror     a
        ror     a
        rts

        jmp     (L6A60)

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
        ror     $6F65
        adc     $6A
        adc     $69
        adc     $68
        .byte   $67,$66,$04,$02,$22,$96,$65,$65
        .byte   $71,$65,$6F,$70,$65,$71,$65,$6C
        .byte   $65,$6B,$65,$6A,$69,$68,$6F,$6F
        .byte   $60,$6C,$71
        adc     ($60),y
        jmp     (L6F6C)

        .byte   $6C,$71,$01,$10,$60,$7D,$7A,$01
        .byte   $00,$21
        adc     $03
        bmi     L9672
        brk
        .byte   $22,$96
        brk
L9672:  asl     $03
        .byte   $3F,$07,$83,$A0,$62,$03,$3A,$07
        .byte   $82,$A0,$62,$62,$62,$04,$1B,$73
        .byte   $96,$07,$83
        ldy     #$6A
        txa
        ror     a
        ror     a
        txa
        ror     a
        ror     a
        ror     a
        ror     a
        txa
        ror     a
        txa
        .byte   $04,$00,$73,$96,$0F,$A3,$96,$CF
        .byte   $97,$F0,$98,$17,$9A,$3A,$9A,$00
        .byte   $05,$03,$3C,$02,$00,$05,$1D,$07
        .byte   $92,$10,$AC,$8F,$AE,$AD
        ldy     LAEAF
        lda     $2180
        ldy     $0108
        ldy     a:$08
        sty     L888A
        .byte   $A7,$88,$8A,$A3
        sta     $87
        sta     $A0
        .byte   $8F,$AE,$AD,$AC,$AF,$AE,$AD,$80
        .byte   $21,$AC,$08,$01,$AC,$08,$00,$8C
        .byte   $8A,$88,$A7,$88,$8A,$A3,$85,$87
        .byte   $85,$02,$80,$07,$84,$10,$80,$85
        .byte   $87,$85
L96EB:  dey
        sta     $8A
        sta     $07
        bcc     L9702
        .byte   $02,$C0,$05,$29,$87,$87,$87,$87
        .byte   $87,$87,$80,$05,$1D,$07,$92,$10
L9702:  and     ($B1,x)
        php
        ora     ($B1,x)
        php
        brk
        .byte   $8C,$8F,$91,$80,$91,$80,$B1,$8C
        .byte   $AF,$B0,$06,$B1,$AF,$06,$B1,$D8
        .byte   $91
        bcs     L96EB
        txa
        sty     L808F
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
        and     ($B6,x)
        stx     $96,y
        .byte   $93,$80,$22,$B8,$08,$01,$B8,$98
        .byte   $08,$00,$03,$3E,$02,$00,$8C,$A8
        .byte   $8A,$04,$00,$A5,$96,$00,$05,$03
        .byte   $3C,$02,$00,$05,$1D,$07,$92,$10
        .byte   $A8,$8C,$AB,$AA,$A8,$AC,$AB,$AA
        .byte   $80,$C8,$88,$87,$85,$A3,$85,$87
        .byte   $05,$11,$AC,$8C,$8F,$8C,$05,$1D
        .byte   $A0,$8C,$AB,$AA,$A8,$AC,$AB,$AA
        .byte   $80,$C8,$88,$87,$85,$A3
        sta     $87
        ora     $11
        ldy     L8F8C
        sty     $1D05
        .byte   $03,$38,$02,$80,$07,$84,$10,$60
        .byte   $80,$85,$87
L9815:  sta     $88
        sta     $8A
        adc     $07
        bcc     L982D
        .byte   $02,$C0,$03,$3C,$05,$29,$83,$83
        .byte   $83,$83,$83,$84,$80,$05,$1D,$07
L982D:  .byte   $92,$10,$03,$38,$80,$D1
        sty     L918F
        .byte   $80,$91,$80,$B1,$8C,$AF,$B0,$06
        .byte   $B1,$AF,$06,$B1,$D8,$91
        bcs     L9815
        txa
        sty     L808F
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
        adc     ($6F),y
        adc     ($73),y
        .byte   $74,$73,$74,$76,$78,$76,$78,$79
        .byte   $01,$01,$DE,$01,$00,$05,$1D
        sty     $93,x
        .byte   $07,$92,$10,$02,$80,$8D,$80,$8D
        .byte   $8D,$8C,$AD,$A0
        sta     L8D80
        sty     L8F8D
        .byte   $80,$94,$80,$02,$00,$80,$93,$93
        .byte   $93,$B4,$80
L98C7:  .byte   $02,$80,$06,$80,$BB,$B9,$06,$98
        .byte   $8D,$80,$8D,$8D,$8C,$AD,$A0,$8D
        .byte   $80
        sta     L8D8C
        .byte   $8F,$80,$94,$80,$93,$93,$93,$80
        .byte   $96,$93,$80,$D8,$03,$3E,$87,$A5
        .byte   $87,$04,$00,$D1,$97,$00,$05,$03
        .byte   $31,$05,$1D,$91,$80,$01,$10,$9D
        .byte   $01,$00,$8C
L98FE:  .byte   $8F,$91,$01,$10,$9D,$01,$00,$91
        .byte   $80,$91,$01,$10,$9D,$01,$00,$8C
        .byte   $83,$8F,$01,$10,$9D,$01,$00,$91
        .byte   $8D,$80,$01,$10,$9D,$01
L991C:  .byte   $00,$8D
        dey
        sta     $1001
        sta     a:$01,x
        ldy     $018C
        bpl     L98C7
        ora     ($00,x)
        .byte   $AF,$8F,$01,$10
        sta     a:$01,x
        and     ($91,x)
        .byte   $04
        ora     ($F6,x)
        tya
        sta     ($80),y
        ora     ($10,x)
        clv
        sta     ($81,x)
        clv
        ora     ($00,x)
        sta     L8D8D
        sta     L8F8D
        .byte   $80,$21,$91,$91,$80,$01,$10,$9D
        .byte   $01,$00,$8C,$8F,$91
L9956:  ora     ($10,x)
        sta     a:$01,x
        sta     ($80),y
        sta     ($01),y
        bpl     L98FE
        ora     ($00,x)
        sty     L9083
        ora     ($10,x)
        sta     a:$01,x
        bcc     L98FE
        .byte   $80,$01,$10,$9D,$01,$00,$8C,$8F
        .byte   $91,$01,$10,$9D,$01,$00,$91,$80
        .byte   $91,$01,$10,$9D
        ora     ($00,x)
        sty     L9083
        ora     ($10,x)
        sta     a:$01,x
        bcc     L991C
        .byte   $80,$01,$10,$9D,$01,$00,$8A,$8D
        .byte   $8F
L9996:  ora     ($10,x)
        .byte   $9D
L9999:  ora     ($00,x)
        .byte   $8F,$80,$8F,$01,$10
        sta     a:$01,x
        txa
        sta     ($8D,x)
        ora     ($10,x)
        sta     a:$01,x
        stx     L808F
        ora     ($10,x)
        sta     a:$01,x
        txa
        sta     $018F
        bpl     L9956
        ora     ($00,x)
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
        cmp     $08,x
        brk
        .byte   $65,$6C,$60,$6A,$60,$06,$88,$8A
        .byte   $68,$21,$65,$A5,$63,$63,$60,$22
        .byte   $65,$85,$08,$01,$A5,$08,$00,$67
        .byte   $60,$88,$60,$21,$65,$A5,$B4,$B6
        .byte   $74,$60,$74,$60,$B6,$04,$01,$4F
        .byte   $9A,$71,$71,$6F,$60,$71,$60,$6F
        .byte   $60,$B1,$8C,$8F,$80,$21,$B1
        php
        ora     ($B1,x)
        php
        brk
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
        asl     $8F
        lda     ($71),y
        asl     $98
        ldx     $B4,y
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
        adc     $60
        .byte   $A7,$05,$29,$03,$3A,$02,$00,$07
        .byte   $86,$10,$65,$68,$6C,$60,$65,$80
        .byte   $65,$67,$68,$67,$65,$60,$65,$63
        .byte   $21,$65,$04,$02,$5D,$9B,$03,$3C
        .byte   $02,$C0,$07,$8A,$10,$05,$1D,$A5
        .byte   $A7,$65,$60
        adc     $60
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
        adc     ($01),y
        bpl     L9D34
        .byte   $7A,$7A,$7A,$78,$78,$76,$76,$01
        .byte   $00,$05,$29,$6A,$6A
        pla
        rts

        .byte   $6A,$60,$68,$6A,$60,$6A,$8A,$8A
        .byte   $68,$67,$68,$60,$68,$60,$68,$67
        .byte   $60,$67,$88,$60,$68,$8A,$8C,$6A
        .byte   $6A,$68,$60,$6A,$60
        pla
        ror     a
        rts

        .byte   $6A,$8A,$8A,$68,$6C,$60,$8C,$6C
        .byte   $01,$10,$6B,$6B,$6B,$6B,$69,$69
        .byte   $69
        adc     #$67
        .byte   $67,$67,$67,$01,$00,$6A,$6A,$68
        .byte   $60,$6A,$60,$68,$6A,$60,$6A,$8A
        .byte   $8A,$68,$67,$68,$60,$68,$60,$68
        .byte   $67,$60,$67,$88,$60,$68
L9D34:  txa
        sty     $6A6A
        pla
        rts

        .byte   $6A,$60,$68
        ror     a
        rts

        .byte   $6A,$8A,$8A,$68,$6C,$05,$1D,$60
        .byte   $70,$70,$60,$70,$60,$70,$60,$70
        .byte   $80,$6C,$6C,$06,$8C,$04,$00,$60
        .byte   $9C,$00,$06,$07,$82,$90,$83,$83
        .byte   $07,$84,$50,$01,$FF,$8D,$01,$00
        .byte   $07,$82,$90,$63,$63,$63,$63,$83
        .byte   $07,$84,$50,$01,$FF,$8D,$01,$00
        .byte   $07,$82,$90,$63,$63,$04,$06,$5A
        .byte   $9D,$07,$84,$50,$01,$FF
        sta     L8D80
        .byte   $80,$6D,$60,$6D,$60
L9D8D:  lda     a:$01
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
        sta     a:$01
        .byte   $07,$82,$90,$63,$63,$63,$63,$83
        .byte   $07,$84,$50,$01,$FF,$8D,$01,$00
        .byte   $07,$82,$90,$63,$63,$04,$02,$D4
        .byte   $9D,$07,$84,$50,$01,$FF,$60,$8D
        .byte   $60,$AD,$C0
        ora     ($00,x)
        .byte   $07,$82,$90,$83,$83,$07,$84,$50
        .byte   $01,$FF,$8D,$01,$00,$07,$82,$90
        .byte   $63,$63,$63,$63,$83,$07,$84,$50
        .byte   $01,$FF,$8D,$01,$00,$07,$82,$90
        .byte   $63,$63,$04,$02,$06,$9E,$07,$84
        .byte   $50,$01,$FF,$60,$6D,$8D,$6D,$60
        adc     LAD60
        ldy     #$01
        brk
        .byte   $04,$00,$5A,$9D,$00,$00,$80,$00
        .byte   $01,$62,$80,$00,$0F,$53,$9E,$2B
        .byte   $9F,$1D,$A0,$14,$A1,$89,$A1,$00
        .byte   $06,$03,$3C,$02
        cpy     #$07
        txa
        jsr     L1F05
        sty     $6871
        rts

        .byte   $71,$60,$65,$60,$71,$60,$6C,$88
        .byte   $91,$04,$01,$5E,$9E,$8A,$6F,$67
        .byte   $60,$6F,$60,$63,$60,$6F,$60,$6A
        .byte   $87,$8F,$04,$01,$6F,$9E,$8C,$71
        .byte   $68,$60,$71,$60,$65,$60,$71,$60
        jmp     (L9188)

        .byte   $04,$01,$80,$9E,$8A,$6F,$67,$60
        .byte   $6F,$60,$63,$60,$6F,$60,$6A,$87
        .byte   $8F,$63,$65,$67,$6A,$60,$6F,$73
        .byte   $76,$A0,$07,$92,$10,$03,$3E,$83
        .byte   $84
        and     ($C5,x)
        php
        ora     ($E5,x)
        php
        brk
        .byte   $06,$87,$06,$88,$8A,$06,$87,$06
        .byte   $88,$87,$06,$A5,$85,$67
        adc     $06
        .byte   $A3,$A3,$A4,$21,$C5,$08,$01,$E5
        .byte   $08,$00
        asl     $87
        asl     $88
        txa
        and     ($AC,x)
        php
        ora     ($AC,x)
        php
        brk
        .byte   $78,$76,$74,$76,$74,$73,$74,$73
        .byte   $71,$73,$71,$6F,$71,$6F,$6D,$6F
        .byte   $6D,$6C,$6D,$6C,$6A,$6C,$6A,$68
        .byte   $07,$AF,$10,$CC,$06,$8C,$06,$8D
        .byte   $91,$CF,$AC,$AF,$D0,$06,$90,$06
        .byte   $93,$96,$D4,$94,$93,$91,$8F,$CD
        .byte   $8D,$8C,$AA,$CF,$8F,$8D,$AC
        adc     ($76),y
        adc     ($6D),y
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
        adc     ($68),y
        rts

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
        dey
        asl     $8A
        sty     LA7C7
        ldy     $06CC
        sty     L9006
        .byte   $93,$D1,$91,$60,$93,$91,$6F,$CA
        .byte   $8A,$88,$A6
        cpy     L8A8C
        tay
        adc     $6D71
        ror     a
        .byte   $04,$03,$04,$A0,$07,$87,$70
        lda     $608D
        adc     $6D60
        sta     $6C8D
        adc     a:$04
        and     a:$9F
        asl     $03
        plp
        ora     $1F
        sta     ($8C),y
        adc     ($60),y
        adc     ($71),y
        rts

        .byte   $91,$6C,$8C,$8F,$04,$01,$23,$A0
        .byte   $8F,$8A,$6F,$60,$6F,$6F,$60,$8F
        .byte   $6A,$8A,$8F,$04,$01,$32,$A0,$91
        .byte   $8C,$71,$60,$71,$71,$60,$91,$6C
        .byte   $8C,$8F,$04,$01,$41,$A0,$8F,$8A
        .byte   $6F,$60,$6F,$6F,$60,$8F,$6A,$8A
        .byte   $8F,$01,$12,$78,$78,$78,$78,$60
        .byte   $75,$75,$75,$60,$7D,$7D
        adc     $7B7B,x
        .byte   $7C,$7C,$01,$00
        sta     ($8C),y
        adc     ($60),y
        adc     ($71),y
        rts

        .byte   $91,$6C,$8C,$8F,$04,$01,$6F,$A0
        .byte   $8F,$8A,$6F,$60,$6F,$6F,$60,$8F
        ror     a
        txa
        .byte   $8F,$04
        ora     ($7E,x)
        ldy     #$91
        sty     $6071
        adc     ($71),y
        rts

        sta     ($6C),y
        sty     $048F
        ora     ($8D,x)
        ldy     #$8F
        txa
        .byte   $6F,$60,$6F,$6F,$60,$8F,$6A,$8A
        .byte   $8F,$04
        ora     ($9C,x)
        ldy     #$8D
        rts

        adc     $7491
        adc     ($60),y
        adc     $7174
        sta     $7174,y
        .byte   $8F,$60,$6F,$93,$76,$73,$60,$6F
        ror     $73,x
        .byte   $9B,$76,$73,$90,$60,$70,$93,$78
        .byte   $73,$60,$70,$78,$73,$9C,$78,$73
        .byte   $91,$60,$71,$94,$78,$74,$60,$71
        .byte   $78,$74,$9D,$78,$74,$86,$60,$66
        .byte   $8A
        adc     $606A
        adc     $666A
        .byte   $92,$6D,$6A
        dey
        rts

        .byte   $68
        sty     $6C6F
        rts

        .byte   $6F
        jmp     (L9468)

        .byte   $6F
        jmp     (L608A)

        .byte   $6A,$8D,$71,$6D,$60,$71,$6D,$6A
        .byte   $96,$71,$6D,$AA,$8A,$60,$6A,$60
        .byte   $6A,$8A,$8A,$6F,$70,$04,$00,$23
        .byte   $A0
        brk
        asl     $07
        sty     $A0
        .byte   $03,$3F,$02,$80,$03,$3A,$64,$64
        .byte   $60,$64,$02,$00,$01,$33,$03,$3F
        .byte   $88,$01,$00,$02,$80,$03,$3A,$64
        .byte   $64,$60,$64,$64,$02,$00,$01,$33
        .byte   $03,$3F,$68,$88,$01,$00,$02,$80
        .byte   $03,$3A,$64,$64,$04
        asl     $1D
        lda     ($E0,x)
        .byte   $03,$3A,$64,$64,$60,$64,$02,$00
        .byte   $01,$33,$03,$3F,$88,$01,$00,$02
        .byte   $80,$03,$3A,$64,$64,$60,$64,$64
        .byte   $02,$00,$01,$33,$03,$3F,$68,$88
        .byte   $01,$00,$02,$80,$03,$3A,$64,$64
        .byte   $04,$0E
        lsr     a
        lda     ($01,x)
        .byte   $33,$68,$60,$80,$88,$60,$68,$60
        .byte   $68,$68,$60,$68,$60,$80,$04,$00
        .byte   $1D
        lda     ($00,x)
        brk
        .byte   $80,$00,$01,$62,$80,$00,$0F,$9C
        .byte   $A1,$BA,$A2,$A7,$A3,$53,$A4,$A0
        .byte   $A4,$00,$05,$02,$00,$05,$13,$03
        .byte   $3D,$07,$92,$10,$CC,$AD,$8F,$EC
        .byte   $80,$CA,$AA
        sty     $0282
        cpy     #$05
        .byte   $1F,$98
        tya
        ora     ($25,x)
        stx     $80,y
        ora     ($00,x)
        tya
        tya
        ora     ($25,x)
        stx     $80,y
        ora     ($00,x)
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
        sta     a:$01,x
        .byte   $93,$80,$90,$01,$10
        sta     a:$01,x
        .byte   $93,$02,$C0,$03,$3D,$07,$92,$10
        .byte   $05,$1F,$21,$B4,$08,$01
        ldy     $08,x
        brk
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
        txa
        and     ($8A,x)
        php
        ora     ($AA,x)
        php
        brk
        .byte   $85,$88,$8A,$AC,$8A,$AF,$AD,$AC
        .byte   $B0,$B3,$B6,$98,$04,$00,$C8,$A1
        .byte   $00,$05,$03,$37,$02,$80,$05,$13
        .byte   $07,$92,$20,$60,$88,$98,$94,$88
        .byte   $98,$91,$94,$8D,$98,$94,$88,$94
        .byte   $98,$88,$94,$98,$87,$96,$93,$87
        .byte   $96,$8F,$93,$6C,$02,$C0,$03,$3D
        .byte   $05,$1F,$93,$93,$A0,$93,$93,$A0
        .byte   $04,$01
        ldy     $01A2,x
        brk
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
        stx     $80,y
        tya
        .byte   $80,$96,$80,$94,$80,$94,$B6,$93
        .byte   $94,$80,$93,$80,$91,$80,$21,$8F
        .byte   $AF,$80,$06,$BB,$B9,$D8,$98,$96
        .byte   $94,$9B,$80,$99,$80,$06,$B8,$9D
        .byte   $21,$9C,$DC,$05,$2B,$80,$8C,$70
        .byte   $F3,$05,$1F,$A8,$80,$87,$06,$A7
        .byte   $85,$80,$87,$06,$A7,$81,$85,$87
        .byte   $79,$74,$71,$7D,$79,$74
        adc     ($7D),y
        adc     $7174,y
        adc     $7479,x
        adc     ($7D),y
        sei
        .byte   $73,$70,$6C,$78,$73,$70,$6C,$78
        .byte   $73,$70,$6C,$78,$73,$70,$6C,$04
        .byte   $01,$70,$A3,$04
        brk
        inc     a:$A2
        ora     $03
        and     $05,x
        .byte   $1F,$88,$98,$94,$88,$98,$91,$94
        .byte   $8D,$98,$94,$88,$94,$98,$88,$94
        .byte   $98,$87,$96,$93,$87,$96,$8F,$93
        .byte   $8C,$96,$93,$87,$93,$96,$87,$93
        .byte   $96,$88,$98,$94,$88,$98,$91,$94
        .byte   $8D,$98,$94,$88,$94,$98,$88,$94
        .byte   $98,$87,$96,$93,$87
LA3E1:  stx     $8F,y
        .byte   $93,$8C,$96,$93,$87,$93,$01,$10
        .byte   $7D,$7D,$7D,$7D,$7A,$7A,$77,$77
        .byte   $01,$00,$88
        tya
        sty     $88,x
        tya
        sta     ($94),y
        sta     L9498
        dey
        sty     $98,x
        dey
        sty     $98,x
        .byte   $87,$96,$93,$87,$96,$8F,$93,$8C
        .byte   $96,$93,$87,$93,$96,$87,$93,$96
        .byte   $04,$03,$F5,$A3,$91,$94,$93,$91
        .byte   $AF,$80
        sta     L8F80
        .byte   $AF,$80,$8D,$91,$93,$8D,$04,$07
        .byte   $27,$A4,$90,$04,$07,$2C,$A4,$91
        .byte   $94,$93,$91,$AF,$80,$8D,$80,$8F
        .byte   $AF,$80,$8D,$91,$93,$8D,$91,$94
        .byte   $8D,$91,$94,$8D,$91,$93,$8C,$90
        .byte   $93,$8C,$90,$93,$98,$04,$00,$F5
        .byte   $A3,$00,$05,$07,$88,$10,$03,$38
        .byte   $07,$82
        bvs     LA3E1
        .byte   $04,$17,$5A,$A4,$07,$84,$40,$01
        .byte   $FF,$8B,$8B,$A0,$8B,$8B,$A0,$01
        .byte   $00,$07,$82,$70,$83,$04,$17,$6F
        .byte   $A4,$07,$84,$40,$01,$FF,$8B,$8B
        .byte   $A0,$6B,$6B,$6B,$6B,$6B,$6B,$6A
        ror     a
        ora     ($00,x)
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
        sty     L8A80
        .byte   $80,$88,$80,$87,$80,$85,$80,$85
        .byte   $8C,$8F,$06,$AE,$85,$80,$85,$8C
        .byte   $8F,$8E,$80,$93,$94,$80
        pla
        pla
        dey
        pla
        pla
        dey
        sta     $80
        adc     $65
        dey
        pla
        pla
        dey
        sta     $80
        sty     L8C8A
        .byte   $80,$68,$68,$88,$68,$68,$88,$85
        .byte   $80
        sty     L8A80
        .byte   $80,$88,$80,$8A,$A0,$80,$6A,$6A
        .byte   $8A,$6A,$6A,$8A,$87,$80,$8C,$80
        .byte   $8A,$80,$88,$80,$87,$80,$85,$80
        .byte   $85,$8C,$8F,$06
        ldx     L8085
        sta     $8C
        .byte   $8F,$8E,$80,$8F,$07,$90,$10,$02
        .byte   $80,$22,$91,$B1,$D1,$8F,$B4,$B1
        .byte   $AF,$B1,$80,$CF,$8F,$06,$B1
        sty     L8C8D
        dey
        .byte   $80,$88,$8C,$8F,$06,$D1,$8F,$B4
        .byte   $B1,$AF,$B1,$21,$8F,$CF,$8F,$8C
        .byte   $8F,$90,$80,$90,$90,$93,$D8,$07
        .byte   $95,$30,$02,$00,$03,$3F,$05,$14
        .byte   $08,$01,$06,$CC,$8A,$AF,$AD,$AC
        .byte   $AD,$22,$8C,$CC,$AC,$8A,$AF,$AD
        .byte   $AC,$AD,$21,$88,$C8,$88,$8A,$8C
        .byte   $E7
        php
        brk
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
        sta     L888C
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
        pla
        pla
        dey
        pla
        pla
        dey
        sta     $80
        adc     $65
        dey
        pla
        pla
        dey
        sta     $80
        sty     L8C8A
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
LA7C7:  .byte   $65,$65,$04,$07,$C6,$A7,$81,$61
        .byte   $61,$04,$07,$CD,$A7,$83,$63,$63
        .byte   $04,$07,$D4,$A7,$85,$65,$65,$04
        .byte   $06,$DB,$A7,$83,$21,$85,$85,$65
        .byte   $65,$04,$07,$E5,$A7,$81,$61,$61
        .byte   $04,$07,$EC,$A7,$83,$63,$63,$04
        .byte   $07,$F3,$A7,$85,$65,$65,$04,$06
        .byte   $FA,$A7,$83,$21,$85,$86,$66
        ror     $86
        ror     $66
        stx     $6D
        adc     $6A6A
        txa
        .byte   $80,$66,$66,$8A,$66,$66,$91,$6A
        .byte   $6A,$8D,$66,$66,$85,$65,$65,$85
        .byte   $65,$65,$85,$6C,$6C,$68,$68,$8F
        .byte   $80,$65,$65,$88,$65,$65,$8F,$68
        pla
        sty     $6565
        stx     $66
        ror     $86
        ror     $66
        stx     $6D
        adc     $6A6A
        txa
        .byte   $80,$66,$66,$8A,$66,$66,$91,$6A
        .byte   $6A,$8D,$66,$66,$83,$63,$63,$04
        .byte   $02,$4C,$A8,$83,$84,$80,$84,$84
        .byte   $84,$A4,$A0,$85,$65,$65,$04,$07
        .byte   $5B,$A8,$81,$61,$61,$04,$07,$62
        .byte   $A8,$83,$63,$63,$04,$07,$69,$A8
        .byte   $85,$65,$65,$04,$06,$70,$A8,$83
        .byte   $21,$85,$85,$65,$65,$04,$07,$7A
        tay
        sta     ($61,x)
        adc     ($04,x)
        .byte   $07,$81,$A8,$83,$63,$63,$04,$07
        .byte   $88,$A8,$85,$65,$65,$04,$06,$8F
        .byte   $A8,$83,$21,$85,$86,$66,$66,$86
        .byte   $66,$66,$86,$6D,$6D,$6A,$6A,$8A
        .byte   $80,$66,$66,$8A,$66
        ror     $91
        ror     a
        ror     a
        sta     $6666
        sta     $65
        adc     $85
        adc     $65
        sta     $6C
        jmp     (L6868)

        .byte   $8F,$80,$65,$65,$88,$65,$65,$8F
        .byte   $68,$68,$8C,$65,$65,$86,$66,$66
        .byte   $86,$66,$66,$86,$6D,$6D,$6A,$6A
        .byte   $8A,$80,$66,$66,$8A,$66,$66,$91
        .byte   $6A,$6A,$8D,$66,$66,$83,$63,$63
        .byte   $04,$02,$E1,$A8,$83,$84,$80,$84
        .byte   $84,$84,$A4,$80,$A1,$61,$61,$81
        .byte   $61,$61,$81,$61,$61,$81,$A3,$63
        .byte   $63,$83,$63,$63,$83,$63,$63,$83
        ora     $20
        lda     $91
        .byte   $87
        .byte   $93,$88
        sty     $87,x
        .byte   $04
        ora     ($04,x)
        lda     #$05
        bit     $61A1
        adc     ($81,x)
        adc     ($61,x)
        sta     ($61,x)
        adc     ($81,x)
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
        php
        brk
        .byte   $21,$C8
        php
        ora     ($C8,x)
        php
        brk
        .byte   $21,$C6,$08,$01,$C6,$08,$00,$21
        .byte   $CD,$08,$01,$CD,$08,$00,$21,$C8
        .byte   $08,$01,$C8,$08,$00,$21,$C9,$08
        .byte   $01
        cmp     #$08
        brk
        .byte   $21,$C7,$08,$01,$C7,$08,$00,$21
        .byte   $CE,$08,$01,$CE,$08,$00,$21,$C9
        .byte   $08,$01,$C9,$08,$00,$21,$CA,$08
        .byte   $01,$CA,$08,$00,$21,$C8,$08,$01
        .byte   $C8,$08,$00,$21,$CF,$08,$01,$CF
        .byte   $08,$00,$21,$CA,$08,$01,$CA,$08
        .byte   $00,$21,$CB,$08
        ora     ($CB,x)
        php
        brk
        and     ($C9,x)
        php
        ora     ($C9,x)
        php
        brk
        .byte   $21
        bne     LA9F6
        ora     ($D0,x)
        php
        brk
        .byte   $21,$CB
        php
        .byte   $01
LA9F6:  .byte   $CB
        php
        brk
        and     ($CC,x)
        php
        ora     ($CC,x)
        ora     $27
        php
        brk
        .byte   $04,$01,$76,$A9
LAA06:  ora     $22
        and     ($CF,x)
        php
        ora     ($CF,x)
        php
        brk
        .byte   $21,$D6,$08,$01,$D6,$08,$00,$21
        .byte   $D1,$08,$01,$D1,$08,$00,$21,$D2
        .byte   $08,$01
LAA21:  .byte   $D2,$08,$00,$21,$D0,$08,$01,$D0
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
        ora     ($C9,x)
        php
        brk
        .byte   $05,$27,$04,$01,$5E,$AA,$05,$22
        .byte   $EB,$F3,$EE,$D0,$08,$01,$01,$05
        .byte   $D0,$01,$00,$08,$00,$04,$00,$52
        .byte   $AA,$00,$06,$03,$35,$05,$22
        adc     $65
        rts

        .byte   $65,$65,$63,$65,$65,$80,$85,$88
        .byte   $8C,$04,$03,$AF,$AA,$66,$66,$60
        .byte   $66,$66,$64,$66,$66,$80,$86,$89
        sta     $0304
        .byte   $BF,$AA
LAACF:  .byte   $67,$67,$60,$67,$67,$65,$67,$67
        .byte   $80,$87,$8A,$8E,$04,$03,$CF,$AA
        .byte   $68,$68,$60
        pla
        pla
        ror     $68
        pla
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
        adc     $6D60
        adc     $6D6B
        adc     L8D80
        bcc     LAACF
        .byte   $04,$03,$2F,$AB,$6E,$6E,$60,$6E
        .byte   $6E,$6C,$6E,$6E,$80,$8E,$91,$95
        .byte   $04,$03,$3F,$AB,$6F,$6F,$60,$6F
        .byte   $6F,$6D,$6F,$6F,$80,$8F,$92,$96
        .byte   $04,$03,$4F,$AB,$70,$70,$60,$70
        .byte   $70,$6E,$70,$70,$80,$90,$93,$97
        .byte   $04,$02,$5F,$AB,$70,$70,$60,$70
        .byte   $70,$6E,$70,$70,$01,$10,$60,$7D
        .byte   $7D,$7C,$7C,$7A,$7A,$7A
        ora     ($00,x)
        .byte   $04,$00,$AF,$AA,$00,$06,$03,$3F
        .byte   $07,$83
        ldy     #$62
        .byte   $62,$07,$82,$20,$82,$04,$00,$8B
        .byte   $AB,$00,$00,$80,$00,$02,$62,$80
        .byte   $00,$0F,$AB,$AB,$ED,$AB,$20,$AC
        .byte   $00,$00,$50,$AC,$00,$06,$02,$00
        .byte   $03,$3A,$07,$02,$A0,$05,$23,$6D
        .byte   $6D,$6D,$60,$6D,$8B,$21,$6D,$CD
        .byte   $6F,$6F,$6F,$60,$6F,$8D,$21,$6F
        .byte   $CF,$70,$70,$60,$70,$A0,$73,$73
        .byte   $60,$73
        ldy     #$60
        .byte   $74,$60,$21,$72,$72,$70,$72,$73
        .byte   $07,$82,$80,$54,$55,$54
        eor     $54,x
        eor     $21,x
        .byte   $54
        php
        ora     ($07,x)
        .byte   $02,$A0,$B4,$09,$00,$06,$02,$40
        .byte   $03,$3A,$05,$17,$07,$02,$A0,$70
        .byte   $70,$70,$60,$70,$8F,$21,$70,$D0
        .byte   $72,$72,$72,$60,$72
        bcc     LAC29
        .byte   $72,$D2,$74,$74,$60,$74,$A0,$76
        .byte   $76,$60,$76,$A0,$60,$78,$60,$75
        .byte   $75,$74,$75,$75,$08,$01,$DB,$09
        .byte   $00
        asl     $03
        sta     ($05,x)
        .byte   $23,$CD,$60,$6D
LAC29:  adc     $6D6D
        asl     $8C
        .byte   $CB,$60,$6B,$6B,$6B,$6B,$06,$8A
        .byte   $69,$69,$60,$69
        ora     ($10,x)
        rts

        .byte   $7D,$9D,$01,$00,$6F,$6F,$60,$6F
        .byte   $01,$10,$60,$7D,$9D,$01,$00
        php
        ora     ($E8,x)
        ora     #$00
        brk
        .byte   $80,$00,$01,$62,$80,$00,$0F,$63
        .byte   $AC,$FA,$AC,$81,$AD,$C7,$AD,$0C
        .byte   $AE,$00,$06,$03,$3C,$02,$C0,$05
        .byte   $13,$07,$E0,$10,$08,$01,$E8,$EB
        .byte   $EE,$D1
        ror     $7471
        adc     ($74),y
        adc     ($74),y
        .byte   $77,$08,$00,$07,$86
        jsr     L1F05
        .byte   $02,$C0,$71,$71,$60,$71,$60
        adc     ($71),y
        .byte   $80
        adc     ($71),y
        rts

        .byte   $71,$60,$71,$71,$07,$83,$20,$91
        .byte   $60,$71,$A0,$98,$60
        sei
        stx     $98,y
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
        pla
        cmp     $A8
        rts

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
LAD60:  .byte   $74,$93,$94,$07,$86,$20,$67,$67
        .byte   $60,$67,$60,$67,$67,$80,$67,$67
        .byte   $60,$67,$60,$67
LAD74:  .byte   $67,$08,$01,$A7,$AC,$B0,$B3,$08
        .byte   $00,$04,$00,$1D,$AD,$00,$06,$03
        .byte   $30,$05,$1F,$71,$71,$71,$6F,$04
        .byte   $0D,$87,$AD,$03
        jsr     L1501
        jmp     (L6A6C)

        .byte   $6A,$68,$68,$66,$66,$03,$50,$01
        .byte   $00,$03,$40,$71,$71,$60,$71,$94
        .byte   $76,$71,$60,$6F,$71,$70,$8A,$6B
        jmp     (L0604)

        .byte   $9F,$AD,$6C,$6C,$78,$60,$76,$78
        .byte   $60,$6C,$60,$6C,$78,$60,$76,$78
        .byte   $74,$73,$04,$00,$9F,$AD,$00,$06
        .byte   $07,$88,$10,$03,$3F,$07,$82
        beq     LAD74
        ldx     #$A2
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
        ora     ($01),y
        ora     $9D,x
        txs
        .byte   $80,$97,$80,$74,$74,$94,$91,$05
        .byte   $1D,$01,$00,$03,$3B,$07,$86,$10
        .byte   $02,$00,$85,$88,$8C,$85,$88,$8F
        .byte   $85,$88
        stx     L8885
        sta     L8885
        .byte   $8B,$8C,$02,$40,$85,$88,$8C,$85
        .byte   $88,$8F,$85,$88,$8E,$85
        dey
        sta     L8885
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
        bcc     LAEB1
        .byte   $31
LAEAF:  sta     $83
LAEB1:  ora     ($10,x)
        txs
        ora     ($00,x)
        sta     $80
        dey
        ora     ($10,x)
        txs
        ora     $11
        ora     ($00,x)
        sta     ($8C),y
        tya
        ora     $1D
        ora     ($10,x)
        txs
        ora     ($00,x)
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
        adc     #$69
        .byte   $89,$86,$80
        stx     $80
        iny
        dey
        .byte   $89,$8B,$A0
        sta     $6D6D
        sta     $6D6D
        sta     L808F
        and     ($CB,x)
        php
        ora     ($CB,x)
        php
        brk
        .byte   $8B,$A9,$89,$8B,$80,$8B,$80
        and     ($8D,x)
        php
        ora     ($CD,x)
        php
        brk
LAF46:  .byte   $02,$80,$07,$83,$70,$05,$2F,$74
        .byte   $72,$70,$72
        bvs     LAFC2
        ror     $046D
        ora     ($01,x)
        .byte   $AF,$07,$84,$10,$05,$23,$02,$C0
        sta     L888D
        sta     $91
        sta     LB488
        .byte   $92,$91,$8F,$91,$AD,$80,$8B,$8B
        .byte   $8A,$86,$AF,$8B,$88,$6B,$6B,$66
        .byte   $6F,$6B,$72,$6F,$77,$92,$AB,$80
        .byte   $8A,$6A,$6D,$6A,$65,$81,$04,$01
        .byte   $81,$AF
        ror     a
        adc     $7675
        adc     $76,x
        adc     $76,x
        adc     ($6D),y
        .byte   $80
        .byte   $02
        cpy     #$AA
        .byte   $80,$30,$81,$30,$84,$30,$89,$30
        .byte   $84,$30,$89,$30,$8D,$30,$89,$30
        .byte   $8D,$30,$90,$30
        sta     L9030
        bmi     LAF46
        .byte   $89,$89,$89,$89,$80,$AB,$80,$07
        .byte   $9A,$10,$02,$00,$8D
        adc     L8D6D
        .byte   $6D
LAFC2:  adc     L8F8D
        .byte   $80
        and     ($CB,x)
        php
        ora     ($CB,x)
        php
        brk
        .byte   $8B,$89,$69,$69,$89,$86,$80,$86
        .byte   $80,$C8,$88,$89,$8B,$A0,$8D,$6D
        .byte   $6D,$8D,$6D,$6D,$8D,$8F,$80,$21
        .byte   $CB,$CB,$80,$88,$88,$8A,$8D,$80
        .byte   $88,$8A,$8D,$80,$88,$8A,$8D,$80
        .byte   $94,$96,$99,$09,$00,$05,$03,$3C
        .byte   $02,$00,$05,$23,$07,$9A,$10,$88
        .byte   $68
        pla
        dey
        pla
        pla
        dey
        dey
        .byte   $80,$E6,$88,$84,$64,$64,$84,$83
        .byte   $80,$83,$80,$C5,$85,$84
        stx     $A0
        dey
        pla
        pla
        dey
        pla
        pla
        dey
        dey
        .byte   $80
LB025:  inc     $88
        ldy     $84
        stx     $80
LB02B:  stx     $80
        and     ($88,x)
LB02F:  iny
LB030:  .byte   $02,$80,$03,$36
LB034:  ora     $2F
        .byte   $07,$83
LB038:  bvs     LB09A
        .byte   $74
LB03B:  .byte   $72,$70,$72,$70
LB03F:  .byte   $6F,$6E,$04,$01,$FB,$AF
LB045:  .byte   $07,$84,$10,$05,$23,$03,$3C,$02
        .byte   $C0,$88,$03,$37,$80,$8D,$88,$85
        .byte   $91,$8D,$88,$B4,$92,$91,$8F,$03
        .byte   $3C,$A8,$80,$86,$03,$37,$80,$8B
        .byte   $8A,$86,$AF,$8B,$88,$6B,$6B,$66
        .byte   $6F,$6B,$72,$6F,$77,$03,$3C,$A6
        .byte   $80,$85,$03,$37,$60,$6A,$6D,$6A
        .byte   $65,$81,$04,$01,$7A,$B0,$6A,$6D
        .byte   $75,$76
LB087:  .byte   $75,$76,$75,$76,$71,$6D,$60,$03
        .byte   $3C,$02,$C0,$A5,$80,$30,$84,$30
        .byte   $89,$30,$8D
LB09A:  bmi     LB025
        bmi     LB02B
        bmi     LB030
        bmi     LB02F
        bmi     LB034
        bmi     LB03B
        bmi     LB038
        bmi     LB03F
        bmi     LB045
        sty     $84
        sty     $84
        .byte   $80
        ldx     $80
        .byte   $07,$9A,$10,$02,$00,$88
        pla
        pla
        dey
        pla
        pla
        dey
        dey
        .byte   $80,$E6,$88,$84,$64,$64,$84,$83
        .byte   $80,$83,$80,$C5,$85,$84,$86,$A0
        .byte   $88,$68,$68,$88,$68,$68,$88,$88
        .byte   $80,$E6,$80,$85,$85,$86,$88,$80
        .byte   $85,$86,$88,$80,$85,$86,$88,$80
        .byte   $91,$92,$94,$09,$00,$05,$03,$30
        .byte   $05,$23,$8D,$6D
        adc     $1D04
        .byte   $F2
        bcs     LB087
        dey
        txa
        sta     $6D8D
        adc     $1D04
        sbc     L8DB0,x
        dey
        txa
        sta     $3003
        lda     $01
        .byte   $14
        sta     L8D80,x
        sta     L809D
        sta     L9D8D
        sta     $0180
        brk
        sta     $01
        .byte   $14,$9D
        sta     a:$01,x
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
        sta     L918F
        .byte   $80,$8D,$8F,$91,$80,$8D,$8F,$91
        .byte   $80,$8D,$8F,$91,$09,$00,$05,$07
        .byte   $82,$A0,$03,$3F,$82,$62,$62,$07
        .byte   $84,$80,$01,$FE
        sta     a:$01
        .byte   $07,$82,$A0,$62,$62,$04,$3B,$87
        .byte   $B1,$83,$83,$83,$83,$80,$83,$83
        .byte   $83,$80,$83,$83,$83,$80,$83,$83
        .byte   $83
        ora     #$00
        brk
        .byte   $80,$00,$02,$62,$80,$00,$0F
LB1B5:  .byte   $BF,$B1,$3D,$B2,$B9,$B2,$1D,$B3
        .byte   $53,$B3,$00,$08,$05,$20,$02,$80
        .byte   $03,$3E,$07,$DF,$40,$08,$00,$21
        .byte   $AE,$06,$CE,$21,$CF,$8F,$06,$B1
        .byte   $04,$01,$C1,$B1,$AE,$B1,$B8,$95
        .byte   $96,$A0,$80,$96,$95,$93,$91,$93
        .byte   $80,$8E,$8C,$8A,$80,$8A,$89,$8A
        .byte   $21,$B1,$06,$D1,$06,$B3,$06
LB1F4:  lda     ($AF),y
        asl     $B5
        asl     $B3
        lda     ($06),y
        .byte   $B5
LB1FD:  asl     $B3
        .byte   $B2,$06,$B6,$06,$B5,$B3,$00,$07
        .byte   $D6,$02,$C0,$80,$8D,$8F,$91,$21
        .byte   $B2,$B2,$92,$B1,$92,$22,$AF,$8F
        .byte   $AF,$8F,$8C,$8F,$B4,$B2,$B1,$AF
        .byte   $00
        asl     $B0
        .byte   $80
        bcc     LB1B5
        .byte   $AF,$90,$AD,$80,$8D,$8D,$AF,$90
        .byte   $F2,$05,$38,$01,$01,$02,$00,$03
        .byte   $3F,$07,$AF,$10,$21,$F9,$F9,$09
        .byte   $00,$08,$02,$C0,$03,$3A,$07,$8A
        .byte   $30,$05,$20,$80,$91,$96,$98,$DA
        .byte   $80,$92,$96,$98,$DB,$04,$01,$48
        .byte   $B2,$96,$91,$96,$9A,$95
        sta     ($95),y
        tya
        .byte   $93,$8E,$93,$96,$91,$8C,$91,$96
        bcc     LB1F4
        bcc     LB1FD
        .byte   $04,$01,$66,$B2,$D1,$91,$06,$B0
        .byte   $8F,$8A,$8F,$91,$D3,$91,$8C,$91
        .byte   $93,$D5,$92,$8E,$92,$93,$D5,$93
        .byte   $8E,$93,$95,$D6,$00,$07,$02,$80
        .byte   $07,$83,$30,$86,$8A,$8D,$82,$04
        .byte   $03,$8D,$B2,$88,$8C,$8F,$94,$04
        .byte   $03,$95,$B2,$00,$06,$89,$8D,$90
        .byte   $95,$04,$03,$9F,$B2
        cpx     #$05
        sec
        .byte   $02,$00,$03,$3F,$01,$01,$07,$AF
        .byte   $10
        and     (zp_F4,x)
        .byte   $F4,$01,$00,$09,$00,$08,$03,$81
        .byte   $05,$20,$06,$AA,$8A,$AA,$A0,$04
        .byte   $03,$BB,$B2,$CA,$C9,$C7,$C5,$C4
        .byte   $C7,$06,$A5,$85,$A5
        ldy     #$06
        .byte   $C3
        ldy     $E5
        asl     $C2
        ldx     $E7
        .byte   $03,$50,$00,$07,$86,$86,$80,$86
        .byte   $86,$81,$86,$8A,$04,$01,$DF,$B2
        .byte   $88,$88,$80,$88,$88,$83,$88,$8C
        .byte   $04,$01,$EB,$B2,$00,$06,$89,$89
        .byte   $80,$89,$89,$84,$89
LB300:  sta     $0104
        sbc     $01B2,y
        ora     $30,x
        sta     $0204,x
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
        brk
        asl     zp_temp_02
        rti

        .byte   $05,$27,$03,$3F,$07,$AF,$10,$69
LB38C:  adc     #$60
LB38E:  adc     #$60
LB390:  adc     #$60
        adc     #$A0
LB394:  ror     a
        jmp     (L2260)

        ror     $08AE
        brk
        .byte   $CE,$09
        brk
LB39F:  asl     $03
        bmi     LB3A8
        .byte   $27,$65,$65,$60
        .byte   $65
LB3A8:  rts

        adc     $60
        sta     $01
        .byte   $10
LB3AE:  adc     $0198,x
        brk
LB3B2:  ror     $88
        .byte   $03,$7F,$21,$6A
LB3B8:  and     ($8A,x)
        tax
        .byte   $03,$30
LB3BD:  ora     ($10,x)
        adc     LB77B,x
        ora     #$00
        asl     $07
        .byte   $83,$F0,$03,$3F,$80,$60,$82,$82
        .byte   $82,$E0,$09
        ora     ($62,x)
        .byte   $80,$00,$0F,$E0,$B3,$23,$B4,$4F
        .byte   $B4,$81,$B4,$9E
        ldy     $00,x
        asl     $03
        rol     $C002,x
        ora     $27
        .byte   $07,$01,$70,$B1,$B1,$30,$AF,$AF
        .byte   $30,$8F,$30,$AF,$30,$8F,$30,$A0
        .byte   $08,$01,$AD,$08,$00
        bmi     LB38C
        bmi     LB38E
        bmi     LB390
        bmi     LB394
        lda     ($B1),y
        bmi     LB3B8
        .byte   $AF,$30,$8F
LB40C:  bmi     LB3BD
LB40E:  bmi     LB39F
LB410:  bmi     LB3B2
        php
        ora     ($AE,x)
        php
        brk
        .byte   $30,$8E,$30
LB41A:  stx     L8E30
        bmi     LB3AE
        .byte   $04,$00,$E2,$B3,$00,$06,$02,$40
        .byte   $05,$27,$07,$01,$80
LB42C:  .byte   $03,$3A,$07,$01,$80,$AA,$AA,$30
        .byte   $A9,$A9,$30,$89,$30,$A8,$30,$88
        .byte   $30
        ldy     #$08
        ora     ($A5,x)
        php
        brk
        .byte   $30,$85,$30,$85,$30,$85,$30,$8C
        .byte   $04,$00,$25,$B4,$00,$06,$03,$55
        .byte   $05,$27,$30,$A6,$30,$86,$30,$86
        .byte   $30,$92,$30,$86,$04,$01,$55,$B4
        .byte   $30,$A5,$30,$85,$30,$85,$30,$91
        .byte   $30,$85,$30,$8A,$30,$96,$30,$8A
        .byte   $30,$8A,$01,$10,$30,$9D,$30,$9A
        .byte   $01,$00,$04,$00,$55
        ldy     $00,x
        asl     $03
        .byte   $3F,$07,$82,$80
LB488:  bmi     LB40C
        bmi     LB40E
        bmi     LB410
        .byte   $07
        sta     $40
        bmi     LB41A
        .byte   $07,$82,$80,$30,$82,$30,$82,$04
        .byte   $00,$88,$B4,$00,$00,$80,$00,$01
        .byte   $62,$80,$00,$0F,$B1
        ldy     $E0,x
        ldy     $08,x
        lda     $2A,x
        lda     $4B,x
        lda     $00,x
        asl     $03
        rol     $C002,x
        ora     $27
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
        sty     $09,x
        brk
        .byte   $06,$03,$50,$05,$27,$01,$10,$65
        .byte   $65
        lda     a:$01,x
        sta     $83
        sta     $83
        sta     $80
        sta     $82
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
        ora     $2F
        php
        ora     ($95,x)
        .byte   $04,$00,$60,$B5,$00,$08,$03,$3A
        .byte   $02,$40,$07,$FF,$10,$01,$FF
        ora     $2F
        php
        ora     ($96,x)
        .byte   $04,$00,$74,$B5,$00,$00,$80,$00
        .byte   $00,$22,$80,$00,$0F,$99,$B5,$36
        .byte   $B6,$48,$B6,$C4,$B6,$D8,$B6,$00
        .byte   $08,$05,$20,$02,$C0,$03,$3A,$07
        .byte   $DF,$40,$08,$00,$21,$CC,$8C,$85
        dey
        sty     L8DAF
        ldy     LAA06
        .byte   $04,$03,$A6,$B5,$02,$40
        cmp     L8D06
        asl     $8F
        sta     ($06),y
        ldy     L8D8C
        asl     $AF
        .byte   $D4,$94,$92,$91,$8F,$06,$AE,$8E
        .byte   $8F,$06,$B1,$8D,$8C,$8D,$8F,$A0
        .byte   $99,$98,$99,$9B,$A0,$06,$86,$06
        .byte   $8A,$8D,$D1,$06,$91,$06,$92,$91
        .byte   $CF,$8F,$06,$B1,$02,$00,$CD,$06
        .byte   $8C,$06,$8D,$8F,$CD,$06,$8C,$06
        .byte   $8D,$91,$21,$96,$D6,$91,$71,$6F
        .byte   $8D,$AF,$91,$06,$AA,$8A,$8C,$06
        .byte   $AD,$05,$14
        stx     $92,y
        sta     L9996
        sty     $B8,x
        ldx     LBB9D,y
        .byte   $07,$01,$40,$05,$20,$22,$ED,$CD
        .byte   $8D,$90,$8F,$21
        sta     $0104
        ora     $B6,x
        brk
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
LB67F:  .byte   $A3,$83,$C3,$06,$A8,$88,$88,$06
        .byte   $A9,$06,$AA,$8A,$CA,$06,$A9,$89
        .byte   $C9,$06,$A8,$88,$C8
        asl     $A7
        .byte   $87,$C7,$06,$A6,$86,$C6,$06,$A8
        .byte   $88,$C8,$06,$AB,$8B,$CB,$04,$01
        .byte   $A0,$B6,$06,$AA,$8A,$CA,$04,$01
        .byte   $A8,$B6,$00,$09,$06,$A9,$89,$C9
        .byte   $00,$0A
        asl     $A6
        stx     $00
        .byte   $0B,$86,$06,$A8,$21,$E1,$A1,$09
        .byte   $00,$08,$03,$3C,$07,$81,$10,$06
        .byte   $D0,$A8,$04,$19,$CB
        ldx     $00,y
        ora     #$06
        bne     LB67F
        ora     #$02
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
        adc     $6F90
        .byte   $6F,$8D,$6B,$6B,$8B,$6D,$6D,$80
        .byte   $6B,$6B,$8D,$80,$8B,$6D,$6D,$80
        .byte   $66,$66,$80,$66
        ror     $86
        .byte   $67,$67,$88,$6B,$6B,$04,$01,$25
        .byte   $B7,$05,$23,$02,$C0,$C9,$89,$8D
        .byte   $80,$8D,$70,$6D,$69,$6D,$70,$6D
        .byte   $70,$75,$D0,$CB,$8B,$8F,$80,$06
        .byte   $B7,$B5,$B4,$B2,$C9,$89,$8D,$80
        .byte   $8D,$70,$6D,$69,$6D
LB77B:  .byte   $70,$6D,$70,$75,$D0,$CB,$06,$8B
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
        sec
        asl     $80
        sty     $94,x
        .byte   $03,$35,$06,$80,$94
        sty     $03,x
        .byte   $33,$06,$80,$94,$94,$09,$00
        ora     $03
        .byte   $3C,$05,$23,$07,$9A,$10,$E0,$66
        .byte   $6B,$6F,$66,$6B,$6F,$72,$6B,$6F
        .byte   $72,$77,$6F,$72,$77,$7B
        ror     $E0A5,x
        cpy     #$91
        sta     ($E0),y
        cpy     #$85
        asl     $A4
        .byte   $A3
        cpx     #$A0
        .byte   $80,$8D,$8D,$8F,$E0,$C0,$A3,$A4
        .byte   $04
        ora     ($FF,x)
        .byte   $B7,$A5,$A0,$E0,$E0,$E0,$80,$86
        .byte   $87,$88,$8B
        adc     chr_ram_data_transfer
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
        sty     $83
        .byte   $80,$83,$80,$C5,$85,$84,$86,$A0
        .byte   $88,$68,$68,$88,$68,$68,$88,$88
        .byte   $80,$E6,$88,$88,$88
        txa
        sta     L8880
        txa
        sta     L8880
        txa
        sta     $0380
        .byte   $3F
        dey
        txa
        and     ($8D,x)
        sbc     L9999
        .byte   $03,$3C,$06,$80,$99,$99,$03,$38
        .byte   $06,$80,$99,$99,$03,$35,$06,$80
        .byte   $99,$99,$03,$32,$06,$80,$99,$99
        .byte   $09,$00,$05,$03,$30,$05,$23,$01
        .byte   $10,$A0,$9D,$9A,$80,$9A,$B8,$7D
        .byte   $7D,$7D,$60,$7A,$7A,$7A,$60,$77
        .byte   $77,$77,$60
        adc     $787A,x
        adc     $01,x
        brk
        .byte   $8B,$8D,$80,$8D
        ldy     #$8B
        sta     L8D80
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
        sta     L8D80,x
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
LB9DF:  .byte   $83,$83,$09,$00,$00,$80,$00,$01
        .byte   $62,$80,$00,$0F,$F5,$B9,$0E,$BA
        .byte   $27,$BA,$00,$00,$4E,$BA,$00,$06
        .byte   $03
LB9F8:  .byte   $3F,$05,$27,$07,$89
        bpl     LB9DF
        ror     a
        ror     a
        .byte   $80,$6C
LBA03:  jmp     (L6D80)

        .byte   $6D
LBA07:  .byte   $80,$6F,$6D,$6F,$06,$F1
LBA0D:  ora     #$00
        asl     $03
LBA11:  .byte   $3F,$05,$27,$07,$89
        bpl     LB9F8
        ror     $66
        .byte   $80
        pla
        pla
        .byte   $80,$6A,$6A,$80,$6C,$6A
        jmp     (LED06)

        .byte   $09,$00,$06,$03,$30,$05,$27,$01
        .byte   $10,$9D,$9D
        adc     $607A,x
        tya
        tya
        sei
        ror     $60,x
        .byte   $73,$60
        ora     ($00,x)
        .byte   $03,$81,$63,$63,$80,$65,$65,$80
        ror     $66
        .byte   $80
        pla
        ror     $68
        asl     $E8
        ora     #$00
        brk
        .byte   $80,$00,$0F,$5D,$BA,$90,$BA,$C3
        .byte   $BA,$DA,$BA,$E9,$BA,$00,$06,$03
        .byte   $3F,$02,$00,$05,$23,$07,$AF,$10
        .byte   $06,$CD,$30,$8D,$30,$8C,$30
        sta     $CF06
        bmi     LBA03
        bmi     LBA03
        bmi     LBA07
        asl     $D1
        bmi     LBA0D
        bmi     LBA0D
        bmi     LBA11
        .byte   $D2,$30,$92,$30,$91,$30,$92,$30
        .byte   $8F,$30,$92,$30,$96,$06,$F4,$09
        .byte   $00,$06,$02,$40,$05,$23,$03,$3F
        .byte   $07,$AF,$10,$06,$C8,$30,$88,$30
        .byte   $88,$30
        sta     ($06),y
        .byte   $D4,$30,$94,$30,$92,$30,$91,$06
        .byte   $CD,$30,$8D,$30,$8C,$30,$8D,$CF
        .byte   $30,$8F,$30,$8D,$30,$8F,$30,$8A
        .byte   $30,$8F,$30,$92,$06,$F1,$09,$00
        .byte   $06,$03,$50,$05,$2F,$81,$81,$81
        .byte   $61
        adc     ($60,x)
        sta     ($61,x)
        sta     ($81,x)
        .byte   $04,$03,$C9,$BA,$06,$E1,$09,$00
        .byte   $06,$07,$83,$F0,$03,$3F,$63,$63
        .byte   $83,$04,$0F,$DC,$BA,$09,$01,$62
        .byte   $80,$00,$0F,$00,$00,$00,$00,$F8
        .byte   $BA,$13,$BB,$22,$BB,$00,$05,$03
        .byte   $30,$05,$23,$01,$10,$8D,$80
        lda     L6D80,x
        adc     L8DBD
        .byte   $80,$BD,$6D,$6D,$6D,$6D,$BD,$04
        .byte   $00,$FE,$BA,$00,$05,$03,$3F,$07
        .byte   $82,$30,$01,$FF
        ldy     #$AB
        .byte   $04,$00,$1C,$BB
        bvc     LBB2E
        .byte   $02,$00,$03,$3F,$83,$8A,$00,$06
        .byte   $03,$3F
LBB2E:  .byte   $80,$0A,$80,$35,$00,$09,$02,$80
        .byte   $01,$FF,$80,$05,$03,$3F,$8F,$FF
        .byte   $00,$09,$03,$3A,$80,$05,$03,$3A
        .byte   $01,$00,$8F,$FF,$00,$09,$03,$36
        .byte   $80,$04,$03,$37,$8F,$FF,$00,$09
        .byte   $03,$33,$80,$03,$06
        ldy     #$0F
        .byte   $02,$80,$01,$20,$03,$3F,$80,$86
        .byte   $02,$00,$01,$20,$03,$3F,$81,$0D
        .byte   $03,$7F,$01,$20,$81,$AB,$00,$0A
        .byte   $03,$3A,$02,$80,$80,$0A,$01,$15
        .byte   $80,$64,$01,$15,$80,$C9,$01,$15
        .byte   $82,$FA,$00,$3A,$02,$00,$80,$08
        .byte   $06
        bmi     LBB9A
        .byte   $02,$00,$03,$3F,$81,$AB,$00,$03
        .byte   $02,$80
LBB9A:  .byte   $03,$3F,$80
LBB9D:  .byte   $0A,$04,$01,$90,$BB,$03,$38,$02
        .byte   $C0,$01,$FF,$80,$3F,$00,$10,$02
        .byte   $80,$05,$00,$00,$84,$01,$80,$07
        .byte   $06
        bmi     LBBBA
        brk
        .byte   $10
LBBBA:  .byte   $02,$40,$03,$3F,$05,$02,$44,$80
        .byte   $00,$01,$E0,$81,$0D,$06
        bvc     LBBCC
        brk
        .byte   $08
LBBCC:  .byte   $02,$40,$03,$3F,$01,$0F,$80,$64
        .byte   $06
        bne     LBBE1
        .byte   $02,$C0,$03,$3F,$05,$02,$A3,$80
        .byte   $07,$01
LBBE1:  .byte   $5F,$80,$71,$00,$05,$05,$01,$43
        .byte   $80,$07,$01,$5F,$03,$3F,$80,$0A
        .byte   $03,$38,$80,$64,$00,$0D,$05,$01
        .byte   $43,$80,$07,$01,$F1,$02,$80,$80
        .byte   $05,$06
        cpx     #$0A
        ora     ($35,x)
        .byte   $02,$00,$03,$3F,$80,$A9,$00,$06
        .byte   $03,$37,$80,$03,$01,$FC,$05,$01
        .byte   $42,$80,$00,$8F,$FF,$00,$20,$03
        .byte   $3A,$80,$04,$01,$F9,$8F,$FF,$00
        .byte   $20,$03,$3A,$80,$04,$06
        cpy     #$03
        ora     $01
        eor     ($80,x)
        brk
        .byte   $03,$3F,$02,$40,$80,$6A,$00,$04
        .byte   $02,$40,$05,$01,$41,$80,$00,$03
        .byte   $3F,$80,$54,$04,$02,$2F,$BC,$06
        jsr     zp_temp_02
        .byte   $04,$02,$40,$01,$8B,$03,$3F,$05
        .byte   $01,$46,$82,$01,$80,$3F,$04,$01
        .byte   $4E,$BC,$06
LBC62:  beq     LBC6F
        .byte   $03,$3F,$81,$AB,$02,$C0,$01,$F2
        .byte   $03,$3F,$87
LBC6F:  .byte   $F2,$00,$1F,$03,$3F,$02,$80,$80
        .byte   $04,$04,$0D,$64,$BC,$01,$01,$80
        .byte   $11,$02,$00,$01,$01,$80,$15,$00
        .byte   $7F,$02,$80,$03,$34,$80,$0A,$8F
        .byte   $FF,$8F,$FF,$00,$1F,$80,$0A,$04
        .byte   $0C,$8E,$BC,$06,$80,$0A,$02,$40
        .byte   $03,$3F,$05,$00,$05,$86,$07,$01
        .byte   $40,$80,$0E,$00,$15,$02,$80,$01
        .byte   $4F,$03,$3F,$80,$0F,$06
        cpy     #$0A
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
        bvs     LBD0C
        .byte   $02,$80,$03,$3F,$01,$EF,$80,$38
        .byte   $00,$04
LBD0C:  .byte   $02,$80,$03,$3F,$01,$FF,$80,$08
        .byte   $01,$F9,$80,$25,$00,$04,$80,$05
        .byte   $01,$EF,$80,$38,$00,$04,$80,$0A
        .byte   $06
        cpx     #$02
        brk
        .byte   $05,$03,$3F,$02,$C0,$80,$86,$00
        .byte   $08,$03,$3F,$05,$00,$E0,$80,$00
        .byte   $02,$40,$80,$C9,$06
        cpx     #$0A
        .byte   $02,$C0,$01,$25,$05,$01,$62,$82
        .byte   $04,$03,$3F,$80,$4D,$00,$04,$03
        .byte   $35,$80,$05,$01,$F0,$80,$4D,$00
        ora     $03
        .byte   $33,$80,$05,$06
        bmi     LBD69
        .byte   $02,$00,$03,$37,$01,$FF,$80,$8E
        .byte   $00,$02
LBD69:  .byte   $03,$3C,$80,$03,$03,$38,$80,$47
        .byte   $00,$06,$03,$3F,$80,$04,$06
        cpx     #$02
        brk
        .byte   $05,$03,$3F,$02,$80,$80,$FE,$00
        .byte   $05,$81,$53,$00,$05,$81,$93,$00
        .byte   $05,$80,$7F,$06
        cpx     #$08
        brk
        .byte   $07,$03,$3F,$80,$0F,$06,$80,$0A
        .byte   $02,$80,$03,$3F,$05,$03,$85,$81
        .byte   $02,$01,$B1,$80,$B3,$00,$06,$02
        .byte   $80,$05,$03,$85,$81,$02,$80,$09
        .byte   $04,$1E,$9A,$BD,$06
        bmi     LBDC3
        .byte   $02,$40,$03,$3F,$01,$F6,$80,$6A
        .byte   $00,$03
LBDC3:  .byte   $03,$34,$80,$08,$04,$02,$B9,$BD
        .byte   $06
        bmi     LBDD8
        .byte   $02,$40,$03,$3F,$01,$F6,$80,$64
        .byte   $00,$03
LBDD8:  .byte   $03,$38,$80,$0A,$04,$02,$CE,$BD
        .byte   $06
        bmi     LBDED
        .byte   $02,$40,$03,$3F,$01,$F1,$80,$5F
        .byte   $00,$03
LBDED:  .byte   $03,$38,$80,$0E,$04,$03,$E3,$BD
        .byte   $06
        bmi     LBE02
        .byte   $02,$C0,$03,$3F,$86,$4E,$00,$03
        .byte   $02,$80
LBE02:  .byte   $03,$3F,$80,$0B,$01,$02,$86,$4E
        .byte   $00,$04,$02,$00,$80,$0F,$04,$0A
        .byte   $06,$BE,$06,$60,$0E,$02,$C0,$01
        .byte   $B1,$03,$3F,$05,$02,$A7,$82,$05
        .byte   $81,$FC,$01,$81,$03,$81,$81,$AB
        .byte   $00,$04,$02,$80,$80,$0D,$04,$01
        .byte   $17,$BE,$06
        beq     LBE3A
        ora     ($C1,x)
        .byte   $03
LBE3A:  .byte   $3F,$80,$1A,$00,$03,$01,$C1,$03
        .byte   $3F,$80,$1E,$04,$01,$37,$BE,$02
        .byte   $80,$03,$3F,$81,$AB,$00,$08,$03
        .byte   $3F,$80,$F0,$03,$3C,$81,$AB,$00
        .byte   $08,$03,$3C,$80,$F0,$03,$39,$81
        .byte   $AB,$00,$08,$03,$39,$80,$F0,$03
        .byte   $36,$81,$AB,$00,$08,$03,$36,$80
        .byte   $F0,$03,$34,$81,$AB,$00,$08,$03
        .byte   $34,$80,$F0,$03,$32,$81,$AB,$00
        .byte   $08,$03,$33,$80,$F0,$06
LBE88:  .byte   $80,$0A,$01,$60,$05,$01
        and     ($82,x)
        ora     $03
        and     $FC81,y
        brk
        .byte   $06,$03,$3F,$80,$07,$01,$30,$80
        .byte   $38,$00,$17,$80,$03,$06,$60,$0A
        .byte   $02,$80,$03,$3F,$01,$FE,$81,$FC
        .byte   $00,$30,$03,$3F,$05,$04,$43,$80
        .byte   $00,$01
        inc     $0A80,x
        asl     $D0
        .byte   $02
        brk
        .byte   $03,$02,$80,$01,$C1,$03,$3F,$80
        .byte   $1F,$04,$01,$BE,$BE,$00,$08,$01
        .byte   $F8,$03,$3F,$80,$3F,$00,$08,$03
        .byte   $3C,$80,$3F,$00,$08,$03,$3A,$80
        .byte   $3F,$00,$08,$03,$36,$80,$3F,$00
        .byte   $08,$03,$34,$80,$3F,$00,$08,$03
        .byte   $33,$80,$3C,$06
        bne     LBEF6
        brk
LBEF6:  .byte   $03,$02,$80,$01,$C1,$03,$3F,$80
        .byte   $1F,$04,$01,$F5,$BE,$00,$08,$01
        .byte   $F8,$03,$3F,$80,$3F,$00,$08,$03
        .byte   $3C,$80,$3F,$00,$08,$03,$3A,$80
        .byte   $3F,$00,$08,$03,$36,$80,$3F,$00
        .byte   $08,$03,$34,$80,$3F,$00,$08,$03
        .byte   $33,$80,$3F,$06
LBF2A:  .byte   $40,$0A,$02,$00,$01,$F1,$03,$3E
        .byte   $81,$7D,$00,$1D,$03,$3A,$80,$06
        .byte   $06
        cpx     #$08
        brk
        .byte   $04,$03,$36,$80,$04,$04,$02,$3D
        .byte   $BF,$06
        beq     LBF4D
        .byte   $02,$80,$01
LBF4D:  .byte   $2F,$03,$3F,$80,$35,$00,$10,$02
        .byte   $00,$01,$2F,$03,$3F,$80,$3C,$03
        .byte   $3C,$80,$35,$00,$10,$03,$3C,$80
        .byte   $3C,$03,$39,$80,$35,$00,$10,$03
        .byte   $39,$80,$3C,$03,$36,$80,$35,$00
        .byte   $10,$03,$36,$80,$3C,$03,$34,$80
        .byte   $35,$00,$10,$03,$34,$80,$3C,$03
        .byte   $32,$80,$35,$00,$10,$03,$32,$80
        .byte   $3C
        asl     $F0
        .byte   $02
        brk
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
