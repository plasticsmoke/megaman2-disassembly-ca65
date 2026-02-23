.segment "BANK0B"

; =============================================================================
; Bank $0B — Game Logic & Enemy AI
; Enemy AI dispatch, boss initialization, collision detection, projectile
; management, and sprite handling for all enemy types.
; =============================================================================

; da65 V2.18 - Ubuntu 2.19-1
; Created:    2026-02-23 18:17:35
; Input file: build/bank0B.bin
; Page:       1


        .setcpu "6502"

zp_temp_00           := $0000
jump_ptr           := $0008
L0420           := $0420
L0508           := $0508
L0917           := $0917
L2020           := $2020
L2220           := $2220
L2820           := $2820
bank_switch_enqueue           := $C051
LC10B           := $C10B
LC3A8           := $C3A8
LC5F1           := $C5F1
LC84E           := $C84E
LC874           := $C874
LC8EF           := $C8EF
LCA0B           := $CA0B
LCC63           := $CC63
fixed_D0B0           := $D0B0
fixed_D332           := $D332
fixed_D3E0           := $D3E0
fixed_D77C           := $D77C
fixed_DA43           := $DA43
        jmp     boss_init

        .byte   $A9,$01,$85,$2B,$A4,$B3,$A5,$AA
        .byte   $29,$01,$F0,$08,$B9,$2B,$80,$F0
        .byte   $03,$4C,$63,$80
        ldx     $B1
        bpl     enemy_ai_dispatch
        jmp     enemy_ai_fallback


; =============================================================================
; Enemy AI Dispatch
; Dispatches to enemy-specific AI routine based on Y index.
; 14 entries: 8 Robot Masters + 6 Wily fortress enemies.
; =============================================================================
enemy_ai_dispatch:  lda     enemy_ai_routine_lo,y; Dispatch to AI routine via pointer table
        sta     jump_ptr
        lda     enemy_ai_routine_hi,y
        sta     $09
        jmp     (jump_ptr)

enemy_spawn_timer_table:  .byte   $0F,$0F,$0F,$0F,$1E,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0F,$0F
enemy_spawn_enable_table:  .byte   $00,$00,$00,$00,$01,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00
enemy_ai_routine_lo:  .byte   $C5,$E3,$FB,$56,$9E,$56,$20,$C3
        .byte   $10,$13,$9B,$6E,$C0,$2A
enemy_ai_routine_hi:  .byte   $80,$82,$84,$86,$87,$89,$8B,$8C
        .byte   $8E,$92,$93,$96,$96,$9B
        lda     #$00
        sta     $0681
        jsr     setup_ppu_normal
        lda     $A9
        cmp     #$06
        bne     L80C4
        lda     $0422
        bpl     L80C4
        lda     $B1
        cmp     #$02
        bcc     L80C4
        lda     $B3
        cmp     #$05
        beq     L8086
        cmp     #$0D
        bne     L808D
L8086:  lda     #$1C
        sta     $06C1
        bne     L80C4
L808D:  inc     $05A6
        ldx     $B3
        lda     $05A6
        cmp     enemy_spawn_timer_table,x
        bne     L80C4
        lda     #$00
        sta     $05A6
        lda     enemy_spawn_enable_table,x
        beq     L80C4
        sec
        lda     $06C1
        sbc     enemy_spawn_enable_table,x
        beq     L80AF
        bcs     L80C1
L80AF:  lda     #$00
        lsr     $0422
        lda     #$00
        sta     $AA
        lda     #$01
        sta     $50
        inc     $05AA
        lda     #$00
L80C1:  sta     $06C1
L80C4:  rts

        .byte   $CA,$BD,$D9,$82,$85,$08,$BD,$DE
        .byte   $82,$85,$09,$6C,$08,$00,$AD,$E1
        .byte   $04,$D0,$2A,$A4,$B3,$B9,$3E,$81
        .byte   $85,$01,$B9,$46,$81,$85,$02,$20
        .byte   $49,$A2,$A5,$00,$D0,$0C,$A9,$00
        .byte   $8D,$A1,$06,$8D,$81,$06
L80F3:  jsr     LA14F
        rts

        lda     #$00
        sta     $0641
        sta     $0661
        inc     $04E1
        lda     $06A1
        ldy     $B3
        cmp     enemy_state_transition,y
        bne     L80F3
        sta     $06A1
        lda     #$00
        sta     $0681
        lda     $06C1
        cmp     #$1C
        bne     L812F
L811B:  lda     #$02
        sta     $B1
        lda     #$00
        sta     $B2
        sta     $04E1
        ldy     $B3
        lda     enemy_spawn_sound_ids,y
        jsr     LA10C
        rts

L812F:  lda     $1C
        and     #$03
        bne     L813D
        inc     $06C1
        lda     #$28
        jsr     bank_switch_enqueue
L813D:  rts

        .byte   $09,$0C,$0F,$0A,$09,$09,$08,$08
        .byte   $0C,$10,$10,$0C,$0C,$0C,$0C,$0C
enemy_state_transition:  .byte   $0F,$0F,$0B,$05,$09,$07,$05,$03
enemy_spawn_sound_ids:  .byte   $51,$67,$6D
        adc     ($55,x)
        .byte   $5C,$64,$6A,$A9,$58,$20,$2D,$A2
        .byte   $B0,$0A,$AD,$A1,$06,$D0,$69,$8D
        .byte   $81,$06,$F0,$64
        lda     $0681
        bne     L81D3
        lda     $06A1
        cmp     #$02
        bne     L81D3
        jsr     LA209
        lda     zp_temp_00
        sta     $03
        clc
        adc     #$20
        sta     $02
        sec
        sbc     #$40
        bcs     L818E
        lda     #$00
L818E:  sta     $04
        lda     #$02
        sta     $01
L8194:  ldx     $01
        lda     #$00
        sta     $0A
        sta     $0C
        lda     $02,x
        sta     $0B
        lda     L81FA,x
        sta     $0D
        jsr     LC874
        ldx     #$01
        lda     #$58
        jsr     LA352
        ldx     $01
        lda     L81F4,x
        sta     $0670,y
        lda     L81F7,x
        sta     $0650,y
        lda     $0E
        sta     $0630,y
        lda     $0F
        sta     $0610,y
        lda     $0430,y
        ora     #$04
        sta     $0430,y
        dec     $01
        bpl     L8194
L81D3:  ldx     #$01
        jsr     LA146
        lda     $02
        cmp     #$01
        bne     L81EE
        bne     L81EE
        lda     #$04
        sta     $B1
        lda     #$12
        sta     $05A8
        lda     #$53
        jsr     LA10C
L81EE:  rts

        .byte   $0F,$15,$0F,$0F,$0F
L81F4:  rol     $A8,x
        .byte   $76
L81F7:  .byte   $07
        ora     $03
L81FA:  .byte   $3A,$2E,$1C,$AD,$E1,$04,$D0,$35
        .byte   $AD,$A1,$06,$C9,$02,$D0,$05,$A9
        .byte   $00,$8D,$A1,$06
        dec     $B2
        bne     L81D3
        lda     #$03
        sta     $06A1
        lda     #$00
        sta     $0681
        lda     #$11
        sta     $06E1
        jsr     LA209
        lda     zp_temp_00
        lsr     a
        lsr     a
        clc
        adc     #$0A
        sta     $B2
        lda     #$38
        jsr     bank_switch_enqueue
        inc     $04E1
        bne     L81D3
        cmp     #$01
        bne     L826F
        lda     $06A1
        cmp     #$06
        bcc     L8247
        ldy     #$04
        sty     $0601
L8247:  cmp     #$09
        bne     L8250
        lda     #$06
        sta     $06A1
L8250:  lda     $B2
        beq     L8258
        dec     $B2
        bne     L828A
L8258:  lda     #$00
        sta     $0601
        sta     $0681
        lda     #$01
        sta     $06E1
        lda     #$0A
        sta     $06A1
        inc     $04E1
        bne     L828A
L826F:  lda     $06A1
        cmp     #$0D
        bne     L828A
        lda     #$50
        jsr     LA10C
        lda     #$83
        sta     $0421
        jsr     LA209
        inc     $06A0,x
        lda     #$05
        sta     $B1
L828A:  jmp     L81D3

L828D:  .byte   $1F,$3E,$5D,$AD,$A1,$06,$F0,$33
        .byte   $C6,$B1,$A9,$8B,$AE,$61,$04,$E0
        .byte   $80,$B0,$02,$A9,$CB
        sta     $0421
        lda     #$00
        sta     $04E1
        sta     $B4
        lda     $4A
        sta     $01
        lda     #$03
        sta     $02
        jsr     LC84E
        ldx     $04
        lda     L828D,x
        sta     $B2
        lda     #$52
        jsr     LA10C
        lda     #$38
        jsr     bank_switch_enqueue
        jsr     LA14F
        rts

        .byte   $AD,$A1,$06,$C9,$04,$F0,$03,$4C
        .byte   $D3,$81
        jmp     L811B

        .byte   $D3,$5E,$FD,$90,$CC,$80,$81,$81
        .byte   $82,$82,$CA,$BD,$F3,$84,$85,$08
        .byte   $BD,$F7,$84,$85,$09,$6C,$08,$00
        .byte   $A9,$00,$85,$40,$85,$4F,$85,$50
        .byte   $A5,$B2,$C9,$03,$D0,$1C,$A9,$00
        .byte   $85,$B2,$A9,$68,$20,$0C,$A1,$AD
        .byte   $21,$04,$09,$04,$8D,$21,$04,$A9
        .byte   $04,$85,$B1,$A9,$FF,$8D,$41,$06
        .byte   $D0,$5F
        lda     $4A
        sta     $01
        lda     #$05
        sta     $02
        jsr     LC84E
        ldx     $04
        lda     L837E,x
        sta     $04E1
        lda     $04
        asl     a
        sta     $01
        asl     a
        adc     $01
        sta     $01
        lda     #$06
        sta     $02
L833C:  lda     #$5D
        ldx     #$01
        jsr     LA352
        ldx     $01
        lda     enemy_sprite_ids,x
        sta     $0670,y
        lda     enemy_palette_data,x
        sta     $0650,y
        lda     enemy_x_offsets,x
        sta     $0630,y
        lda     enemy_collision_data,x
        sta     $0610,y
        lda     enemy_damage_values,x
        sta     $04F0,y
        inc     $01
        dec     $02
        bne     L833C
        lda     #$3F
        jsr     bank_switch_enqueue
        inc     $B2
        inc     $B1
        lda     #$00
        sta     $06A1
        sta     $0681
        jsr     L84D9
        rts

L837E:  .byte   $44,$4A,$42,$43,$43
enemy_sprite_ids:  .byte   $00,$F0,$50,$3C,$00,$00,$D3,$CD
        .byte   $68,$0F,$1A,$00,$A7,$68,$00,$7F
        .byte   $B1,$A7,$88,$50,$D4,$D0,$D0,$B9
        .byte   $98,$50,$3C,$1A,$7C,$35
enemy_palette_data:  .byte   $04,$03,$03,$02,$02,$00,$03,$03
        .byte   $02,$02,$01,$00,$03,$02,$02,$01
        .byte   $00,$FF,$03,$03,$02
L83B6:  ora     ($01,x)
        .byte   $FF,$03,$03,$02,$01,$00,$00
enemy_x_offsets:  .byte   $00,$B1,$3C,$50,$76,$00,$2B,$3C
        .byte   $31,$6B,$DB,$00,$A0,$31
L83CD:  ror     $B5,x
        beq     L83CD
        cpx     #$3C
        .byte   $D4,$90,$90
        sbc     $3CC0,x
        bvc     L83B6
        sed
        .byte   $FE
enemy_collision_data:  brk
        brk
        .byte   $02,$03,$03,$04,$01,$01,$03,$03
        .byte   $03,$04,$01,$03,$03,$03,$03,$03
        .byte   $01,$02,$02,$03,$03,$03,$01,$02
        .byte   $03,$03,$03,$03
enemy_damage_values:  .byte   $0C,$16,$24,$0E,$24,$18,$1B,$0E
        .byte   $1E,$2A,$1D,$0C,$0D,$0A,$20,$15
        .byte   $22,$18,$21,$15,$05,$0D,$23,$1C
        .byte   $1A,$0E,$1C,$1D,$10,$24,$AD,$E1
        .byte   $04,$F0,$0C
L841E:  lda     #$00
        sta     $0681
        dec     $04E1
        jsr     L84D9
        rts

        lda     #$5D
        jsr     LA22D
        bcc     L8436
        dec     $B1
        jmp     L841E

L8436:  lda     #$01
        sta     $40
        lda     $0421
        and     #$40
        sta     $AF
        clc
        lda     $4F
        adc     #$10
        sta     $4F
        lda     $50
        adc     #$00
        sta     $50
        cmp     #$04
        bne     L8456
        lda     #$00
        sta     $4F
L8456:  ldy     #$0F
        lda     #$5D
        sta     zp_temp_00
L845C:  jsr     collision_check_sprite
        bcs     L846E
        lda     $4F
        sta     $0630,y
        lda     $50
        sta     $0610,y
        dey
        bpl     L845C
L846E:  lda     $06A1
        cmp     #$03
        bne     L847A
        lda     #$01
        sta     $06A1
L847A:  ldx     #$01
        jsr     L84D9
        rts

        .byte   $20,$D9
        sty     $A9
        .byte   $0B,$85,$01,$A9,$10,$85,$02,$20
        .byte   $D4,$A2,$A5,$00,$F0,$3A,$A6,$B2
        .byte   $BD,$CD,$84,$8D,$61,$06,$BD,$D0
        .byte   $84,$8D,$41,$06,$BD,$D3,$84,$8D
        .byte   $21,$06,$BD,$D6,$84,$8D,$01,$06
        .byte   $E6,$B2,$A5,$B2,$C9,$03,$D0,$18
        .byte   $A9,$02,$85,$B1,$AD,$21,$04,$29
        .byte   $FB,$49,$40,$8D,$21,$04,$A9,$00
        .byte   $85,$B2,$A9,$67,$20,$0C,$A1,$60
        .byte   $60,$E6,$76,$00,$04,$07,$00,$39
        .byte   $9A,$00,$01,$01,$00
L84D9:  lda     $05A8
        beq     L84E4
        jsr     LA14F
        jmp     L84F2

L84E4:  jsr     LA146
        lda     $02
        cmp     #$01
        bne     L84F2
        lda     #$12
        sta     $05A8
L84F2:  rts

        .byte   $D3,$F1,$19,$80,$80,$82,$84,$84
        .byte   $CA,$BD,$4E,$86,$85
        php
        lda     L8652,x
        sta     $09
        jmp     (jump_ptr)

        jsr     LA209
        lda     $04E1
        bne     L851E
        lda     #$61
        ldx     #$01
        jsr     LA352
        inc     $04E1
        jmp     L857B

L851E:  cmp     #$04
        bcs     L853B
L8522:  inc     $B2
        lda     $B2
        cmp     #$12
        bne     L8538
        lda     #$00
        sta     $B2
        inc     $04E1
L8531:  lda     #$62
        ldx     #$01
        jsr     LA352
L8538:  jmp     L857B

L853B:  lda     #$62
        jsr     LA22D
        bcc     L857B
        lda     #$03
        sta     $02
L8546:  lda     #$62
        ldx     #$01
        jsr     LA352
        bcs     L8574
        ldx     $02
        lda     #$C1
        sta     $0430,y
        lda     #$20
        sta     $04B0,y
        lda     #$01
        sta     $04F0,y
        lda     #$FE
        sta     $0650,y
        lda     #$02
        sta     $0610,y
        lda     L857F,x
        sta     $0470,y
        dec     $02
        bpl     L8546
L8574:  inc     $B1
        lda     #$6F
        jsr     LA10C
L857B:  jsr     L8636
        rts

L857F:  .byte   $40
        bvs     L8522
        bne     L8531
        lda     ($06,x)
        cmp     #$02
        bcc     L85B7
        bne     L85B0
        lda     $0681
        bne     L85B7
        lda     #$61
        jsr     LA22D
L8596:  bcs     L85B7
        lda     #$04
        sta     $0610,y
        .byte   $B9
        .byte   $30
L859F:  .byte   $04
        and     #$BF
        sta     zp_temp_00
        lda     $0421
        and     #$40
        ora     zp_temp_00
        sta     $0430,y
        bne     L85B7
L85B0:  lda     #$6E
        jsr     LA10C
        inc     $B1
L85B7:  jsr     L8636
        rts

        .byte   $20,$36,$86,$AD,$A1,$06,$C9,$02
        .byte   $90
        bvs     L8596
        .byte   $52,$AD,$81,$06,$D0,$12,$A9,$04
        .byte   $8D,$41,$06,$A9,$01,$8D,$01,$06
        .byte   $AD,$21,$04,$09,$04,$8D,$21,$04
        lda     #$01
        sta     $0681
        lda     $0641
        php
        lda     #$0F
        sta     $01
        lda     #$10
        sta     $02
        jsr     LA2D4
        plp
        bpl     L8635
        lda     zp_temp_00
        beq     L8635
        lda     #$03
        sta     $06A1
        lda     #$00
        sta     $0641
        sta     $0661
        sta     $0601
        sta     $0681
        sta     $04E1
        sta     $B2
        lda     $0421
        and     #$FB
        sta     $0421
        lda     $06A1
        cmp     #$04
        bne     L8635
        lda     #$00
        sta     $0681
        lda     #$62
        jsr     LA22D
        bcc     L8635
        lda     #$02
        sta     $B1
        lda     #$6D
        jsr     LA10C
L8635:  rts

L8636:  lda     $05A8
        beq     L863F
        jsr     LA14F
        rts

L863F:  jsr     LA146
        lda     $02
        cmp     #$01
        bne     L864D
        lda     #$12
        sta     $05A8
L864D:  rts

        .byte   $D3,$09,$83,$BB
L8652:  .byte   $80,$85,$85,$85,$CA,$BD,$96,$87
        .byte   $85,$08,$BD,$9A,$87,$85,$09,$6C
        .byte   $08,$00,$A9,$83,$8D,$21,$04,$20
        .byte   $09,$A2,$BD,$A0,$06,$D0,$03,$8D
        .byte   $81,$06
        lda     $04E1
        bne     L86A0
        sec
        lda     $04A1
        sbc     $04A0
        bcs     L8686
        eor     #$FF
        adc     #$01
L8686:  cmp     #$03
        bcs     L86E6
        lda     $4A
        sta     $01
        lda     #$03
        sta     $02
        jsr     LC84E
        inc     $04
        lda     $04
        sta     $04E1
        lda     #$01
        sta     $B2
L86A0:  dec     $B2
        bne     L86E6
        lda     #$1F
        sta     $B2
        lda     #$5B
        ldx     #$01
        jsr     LA352
        lda     #$01
        sta     $06A1
        dec     $04E1
        bne     L86E6
        lda     $04A0
        pha
        lda     #$50
        sta     $04A0
        lda     #$01
        sta     $09
        lda     #$60
        sta     jump_ptr
        ldx     #$01
        stx     $2B
        jsr     LA38C
        pla
        sta     $04A0
        lda     #$00
        sta     $B2
        lda     $0421
        sta     $04E1
        inc     $B1
        lda     #$62
        jsr     LA10C
L86E6:  jsr     L8771
        rts

        .byte   $AD,$E1,$04,$8D,$21,$04,$20,$71
        .byte   $87,$AD,$A1,$04,$C9,$50,$B0,$14
        .byte   $A9,$FF,$8D,$41,$06,$A9,$00,$8D
        .byte   $61,$06,$8D,$01,$06,$8D,$21,$06
        .byte   $A9,$04,$85,$B1
        jsr     LA209
        lda     $B2
        bne     L872F
        sec
        lda     $04A1
        sbc     $04A0
        bcs     L8722
        eor     #$FF
        adc     #$01
L8722:  cmp     #$03
        bcs     L8747
        lda     #$01
        sta     $05A7
        lda     #$04
        sta     $B2
L872F:  dec     $05A7
        bne     L8747
        lda     #$12
        sta     $05A7
        lda     #$03
        sta     $06A1
        lda     #$5A
        ldx     #$01
        jsr     LA352
        dec     $B2
L8747:  lda     $06A1
        cmp     #$02
        bne     L8753
        lda     #$00
        sta     $06A1
L8753:  rts

        .byte   $20,$71,$87,$A5,$00,$F0,$B3,$A9
        .byte   $02,$85,$B1,$A9,$00,$8D,$41,$06
        .byte   $8D,$E1,$04,$85,$B2,$A9,$61,$20
        .byte   $0C,$A1,$4C,$47,$87
L8771:  lda     $05A8
        beq     L877C
        jsr     LA14F
        jmp     L878A

L877C:  jsr     LA146
        lda     $02
        cmp     #$01
        bne     L878A
        lda     #$12
        sta     $05A8
L878A:  lda     #$09
        sta     $01
        lda     #$0C
        sta     $02
        jsr     LA2D4
        rts

        .byte   $D3,$64,$EA,$54,$80,$86,$86,$87
        .byte   $CA,$BD,$4C,$89,$85,$08,$BD,$51
        .byte   $89,$85,$09
        jmp     (jump_ptr)

        .byte   $AD,$E1,$04,$D0,$51,$A9,$87,$8D
        .byte   $21,$04,$20,$09,$A2,$A5,$4A,$85
        .byte   $01,$A9,$03,$85,$02,$20,$4E,$C8
        .byte   $A6,$04,$A5,$00,$18,$69,$20,$85
        .byte   $01,$38,$E9,$40,$B0,$02,$A9,$00
        sta     $02
        lda     #$00
        sta     $0661
        lda     L8893,x
        sta     $0641
        lda     zp_temp_00,x
        sta     $0B
        lda     L8896,x
        sta     $0D
        lda     #$00
        sta     $0A
        sta     $0C
        jsr     LC874
        lda     $0F
        sta     $0601
        lda     $0E
        sta     $0621
        inc     $04E1
        inc     $B2
        lda     #$08
        sta     $01
        lda     #$0C
        sta     $02
        lda     $0641
        php
        jsr     LA2D4
        plp
        bpl     L8826
        lda     zp_temp_00
        beq     L8826
        dec     $04E1
        lda     $B2
        cmp     #$03
        bne     L8826
        ldx     #$01
        jmp     L889E

L8826:  lda     $06A1
        bne     L882E
        sta     $0681
L882E:  lda     $0641
        php
        jsr     L890E
        plp
        bmi     L8892
        lda     $0641
        bpl     L8892
        lda     $B2
        cmp     #$02
        bne     L8892
        lda     $B1
        cmp     #$02
        bne     L8892
        lda     #$00
        sta     $0681
        lda     #$01
        sta     $06A1
        lda     $04A0
        pha
        sec
        sbc     #$18
        sta     $04A0
        lda     #$03
        sta     $02
L8861:  lda     #$59
        ldx     #$01
        jsr     LA352
        bcs     L888E
        tya
        clc
        adc     #$10
        tax
        sta     $2B
        lda     #$25
        sta     $04E0,x
        lda     #$04
        sta     $09
        lda     #$00
        sta     jump_ptr
        jsr     LA38C
        clc
        lda     $04A0
        adc     #$18
        sta     $04A0
        dec     $02
        bne     L8861
L888E:  pla
        sta     $04A0
L8892:  rts

L8893:  .byte   $07,$08,$04
L8896:  sec
        rti

        .byte   $20,$20,$09,$A2,$A2,$00
L889E:  lda     #$00
        sta     $04E1
        sta     $B2
        lda     L88B4,x
        sta     $B1
        lda     L88B6,x
        jsr     LA10C
        jsr     L8903
        rts

L88B4:  .byte   $02,$05
L88B6:  .byte   $55,$58,$CE,$E1,$04,$F0,$2A,$20
        .byte   $03,$89,$60,$AD,$E1,$04,$D0,$14
        .byte   $A9,$87,$8D,$21,$04,$20,$09,$A2
        .byte   $A9,$02,$8D,$01,$06,$A9,$3E,$85
        .byte   $B2,$EE,$E1,$04
        dec     $B2
        bne     L88E3
        ldx     #$00
        jsr     L889E
L88E3:  jsr     L8903
        rts

        lda     #$00
        sta     $04E1
        sta     $B2
        lda     #$03
        sta     $B1
        lda     #$56
        jsr     LA10C
        lda     #$0B
        sta     $01
        lda     #$0C
        sta     $02
        jsr     LA12E
        rts

L8903:  lda     #$08
        sta     $01
        lda     #$0C
        sta     $02
        jsr     LA2D4
L890E:  lda     $05A8
        beq     L8919
        jsr     LA14F
        jmp     L894B

L8919:  jsr     LA146
        lda     $02
        beq     L894B
        cmp     #$01
        bne     L892B
        lda     #$12
        sta     $05A8
        bne     L894B
L892B:  lda     #$00
        sta     $0601
        sta     $0621
        lda     #$FF
        sta     $0641
        lda     #$C0
        sta     $0661
        lda     #$57
        jsr     LA10C
        lda     #$04
        sta     $B1
        lda     #$3E
        sta     $04E1
L894B:  rts

        .byte   $D3,$AC,$99,$B8,$C1,$80,$87,$88
        .byte   $88,$88,$CA,$BD,$16,$8B,$85,$08
        .byte   $BD,$1B,$8B,$85,$09,$6C,$08,$00
        .byte   $AD,$21,$04,$09,$04,$8D,$21,$04
        .byte   $A9,$06,$8D,$21,$06,$A9,$01,$8D
        .byte   $01,$06,$E6,$B2,$A5,$B2,$C9,$BB
        .byte   $90,$1C,$A9,$00,$8D,$E1,$04,$A9
        .byte   $03,$85,$B1,$A9,$5A
        jsr     LA10C
        lda     #$03
        sta     $06A1
        jsr     L8AE4
        lda     #$21
        jsr     bank_switch_enqueue
        rts

        jsr     L8AE4
        lda     $03
        beq     L89B5
        lda     $B1
        cmp     #$06
        beq     L89B5
        lda     #$00
        sta     $04E1
        lda     #$05
        sta     $B1
        lda     #$5D
        jsr     LA10C
L89B5:  rts

        .byte   $A9,$00,$8D,$21,$06,$8D,$01,$06
        .byte   $AD,$A1,$06,$C9,$07,$D0,$43,$A9
        .byte   $5F,$8D,$0F,$04,$A9,$80,$8D,$2F
        .byte   $04,$8D,$6F,$04,$8D,$AF,$04,$AD
        .byte   $41,$04,$8D,$4F,$04,$A9,$00,$8D
        .byte   $6F,$06,$8D,$4F,$06,$8D,$0F,$06
        .byte   $8D,$2F,$06,$8D,$8F,$06,$8D,$AF
        .byte   $06,$A9,$04,$85,$AA,$A9,$20,$8D
        .byte   $66,$03,$A9,$06,$8D,$E1,$04,$A9
        .byte   $1F,$85,$B2,$E6,$B1,$A9,$5B,$20
        .byte   $0C,$A1
L8A08:  jsr     L8AE4
        rts

        .byte   $A9,$0F,$8D,$66,$03,$AD,$A1,$06
        .byte   $F0,$F2
L8A16:  .byte   $C9,$02,$D0,$1B,$A9,$02,$85,$B1
        .byte   $A9,$00,$85,$AA,$85,$B2,$8D,$E1
        .byte   $04,$4E,$2F,$04,$A9,$5C,$20,$0C
        .byte   $A1,$20,$09,$A2,$4C,$08,$8A
        jsr     LA209
        lda     #$00
        sta     $0681
        dec     $B2
        bne     L8A08
        lda     #$06
        sta     $B2
        lda     $04A0
        pha
        lda     $4A
        sta     $01
        lda     #$50
        sta     $02
        jsr     LC84E
        sec
        lda     $04A1
        sbc     #$28
        clc
        adc     $04
        sta     $04A0
        lda     #$35
        ldx     #$01
        jsr     LA352
        bcs     L8A9A
        clc
        tya
        adc     #$10
        tax
        stx     $2B
        lda     #$08
        sta     $09
        lda     #$00
        sta     jump_ptr
        ldy     #$00
        lda     $0421
        and     #$40
        pha
        bne     L8A83
        iny
L8A83:  clc
        lda     $0460,x
        adc     L8AAB,y
        sta     $0460,x
        pla
        tay
        lda     #$60
        sta     zp_temp_00
        jsr     LA3A3
        lda     #$01
        sta     $2B
L8A9A:  pla
        sta     $04A0
        ldx     #$01
        dec     $04E1
        bne     L8AA8
        inc     $06A1
L8AA8:  jmp     L8A08

L8AAB:  .byte   $08,$F8,$AD,$E1,$04,$D0,$18,$20
        .byte   $09,$A2,$A9,$00,$8D,$61,$06,$8D
        .byte   $01,$06,$A9,$04,$8D,$41,$06,$A9
        .byte   $80,$8D,$21,$06,$EE,$E1,$04
        jsr     L8AE4
        bne     L8AD0
L8ACF:  rts

L8AD0:  lda     $B1
        cmp     #$06
        beq     L8ACF
        lda     #$00
        sta     $04E1
        lda     #$02
        sta     $B1
        lda     #$5C
        jsr     LA10C
L8AE4:  lda     $05A8
        beq     L8AEF
        jsr     LA14F
        jmp     L8AFE

L8AEF:  jsr     LA146
        lda     $02
        cmp     #$01
        bne     L8AFE
        lda     #$12
        sta     $05A8
        rts

L8AFE:  lda     #$08
        sta     $01
        lda     #$0C
        sta     $02
        lda     $0641
        php
        jsr     LA2D4
        plp
        bpl     L8B13
        lda     zp_temp_00
        rts

L8B13:  lda     #$00
        rts

        .byte   $D3,$64,$B6,$0C,$AD,$80,$89,$89
        .byte   $8A,$8A,$CA,$BD,$BB,$8C,$85,$08
        .byte   $BD,$BF,$8C,$85,$09,$6C,$08,$00
        .byte   $A9,$87,$8D,$21,$04,$20,$09,$A2
        .byte   $A5,$27,$29,$02,$D0,$06,$A5,$B2
        .byte   $C9,$BB,$D0,$13
        lda     $4A
        sta     $01
        lda     #$03
        sta     $02
        jsr     LC84E
        ldx     $04
        jsr     L8B74
        jmp     L8B6E

        lda     zp_temp_00
        cmp     #$48
        bcs     L8B6E
        lda     #$87
        ldy     $0461
        cpy     #$80
        bcs     L8B66
        ora     #$40
L8B66:  sta     $0421
        ldx     #$03
        jsr     L8B74
L8B6E:  inc     $B2
        jsr     L8C3E
        rts

L8B74:  lda     #$65
        jsr     LA10C
        lda     #$01
        sta     $B2
        lda     L8BA1,x
        sta     $0661
        lda     L8BA5,x
        sta     $0641
        lda     L8BA9,x
        sta     $0621
        lda     L8BAD,x
        sta     $0601
        lda     L8BB1,x
        sta     $B1
        lda     $0421
        sta     $04E1
        rts

L8BA1:  sbc     a:$A8
        brk
L8BA5:  .byte   $06,$05,$04,$08
L8BA9:  .byte   $00,$00,$00,$20
L8BAD:  .byte   $00,$00,$00,$02
L8BB1:  .byte   $03,$03,$03,$04,$AD,$E1,$04,$8D
        .byte   $21,$04,$20,$3E,$8C,$A5,$00,$48
        .byte   $20,$09,$A2,$68,$85,$00,$AD,$41
        .byte   $06,$10,$3A,$C6,$B2,$D0,$21,$A0
        .byte   $12,$A5,$B1,$C9,$04,$D0,$02,$A0
        .byte   $40
        sty     $B2
        lda     #$00
        sta     $0641
        sta     $0661
        lda     $0421
        and     #$FB
        sta     $0421
        lda     #$01
        sta     $06A1
        lda     zp_temp_00
        beq     L8C06
        lda     #$00
        sta     $B2
        dec     $B1
        sta     $0601
        sta     $0621
        lda     #$64
        jsr     LA10C
L8C06:  lda     $06A1
        bne     L8C0E
        sta     $0681
L8C0E:  cmp     #$02
        bne     L8C3D
        lda     $0681
        bne     L8C3D
        lda     #$23
        jsr     bank_switch_enqueue
        lda     #$5C
        ldx     #$01
        jsr     LA352
        clc
        tya
        adc     #$10
        tax
        stx     $2B
        lda     #$00
        sta     jump_ptr
        lda     #$04
        sta     $09
        jsr     LA38C
        lda     $0421
        ora     #$04
        sta     $0421
L8C3D:  rts

L8C3E:  lda     #$0F
        sta     $0366
        clc
        lda     $05A7
        adc     #$01
        sta     $05A7
        lda     $05A9
        adc     #$00
        sta     $05A9
        beq     L8C90
        lda     $05A7
        cmp     #$77
        bne     L8C90
        lda     #$00
        sta     $05A7
        sta     $05A9
        lda     $2A
        cmp     #$0C
        beq     L8C90
        lda     #$30
        sta     $0366
        ldx     #$00
        ldy     #$00
        lda     $45
        eor     #$40
        sta     $45
        lda     $46
        eor     #$40
        sta     $46
        beq     L8C83
        inx
L8C83:  lda     L8CB5,x
        sta     $037B,y
        inx
        inx
        iny
        cpy     #$03
        bne     L8C83
L8C90:  lda     $05A8
        beq     L8C9B
        jsr     LA14F
        jmp     L8CA9

L8C9B:  jsr     LA146
        lda     $02
        cmp     #$01
        bne     L8CA9
        lda     #$12
        sta     $05A8
L8CA9:  lda     #$07
        sta     $01
        lda     #$0C
        sta     $02
        jsr     LA2D4
        rts

L8CB5:  .byte   $10,$10,$10,$15,$15,$10,$D3,$2E
        .byte   $B5,$B5,$80,$8B,$8B,$8B,$CA,$BD
        .byte   $08,$8E
        sta     jump_ptr
        lda     L8E0C,x
        sta     $09
        jmp     (jump_ptr)

        .byte   $AD,$E1,$04,$09,$83,$8D,$21,$04
        .byte   $A9,$00,$8D,$61,$06,$8D,$41,$06
        .byte   $A9,$47,$8D,$21,$06,$A9,$01,$8D
        .byte   $01,$06,$A9,$6A,$20,$0C,$A1,$E6
        .byte   $B1,$20,$F0,$8D,$60,$A5,$27,$29
        .byte   $02,$D0,$0A,$AD,$A7,$05,$F0,$57
        .byte   $CE,$A7
        ora     $D0
        .byte   $52
        lda     #$87
        sta     $0421
        jsr     LA209
        lda     $0421
        sta     $05A9
        lda     #$ED
        sta     $0661
        lda     #$06
        sta     $0641
        clc
        lda     zp_temp_00
        adc     #$20
        sta     $0B
        lda     $4A
        and     #$01
        beq     L8D36
        sec
        lda     $0B
        sbc     #$40
        bcs     L8D34
        lda     #$00
L8D34:  sta     $0B
L8D36:  lda     #$37
        sta     $0D
        lda     #$00
        sta     $0A
        sta     $0C
        jsr     LC874
        lda     $0F
        sta     $0601
        lda     $0E
        sta     $0621
        lda     #$6B
        jsr     LA10C
        lda     #$04
        sta     $B1
        bne     L8D7C
        ldx     $0461
        lda     $0421
        and     #$40
        bne     L8D68
        cpx     #$38
        bcs     L8D7C
        bcc     L8D6C
L8D68:  cpx     #$C8
        bcc     L8D7C
L8D6C:  lda     $04E1
        eor     #$40
        sta     $04E1
        lda     $0421
        eor     #$40
        sta     $0421
L8D7C:  jsr     L8DF0
        rts

        lda     $05A9
        sta     $0421
        lda     $0641
        php
        jsr     L8DF0
        lda     #$0B
        sta     $01
        lda     #$0C
        sta     $02
        jsr     LA2D4
        plp
        bmi     L8DA7
        lda     $0641
        bpl     L8DE4
        lda     #$01
        sta     $06A1
        bne     L8DE4
L8DA7:  lda     zp_temp_00
        beq     L8DB6
        lda     #$02
        sta     $B1
        lda     #$9C
        sta     $05A7
        bne     L8DE4
L8DB6:  lda     $06A1
        cmp     #$02
        bne     L8DE4
        lda     $0681
        bne     L8DE4
        lda     #$5E
        jsr     LA22D
        bcc     L8DE4
        lda     #$5E
        ldx     #$01
        jsr     LA352
        bcs     L8DE4
        clc
        tya
        adc     #$10
        tax
        stx     $2B
        lda     #$24
        sta     jump_ptr
        lda     #$06
        sta     $09
        jsr     LA38C
L8DE4:  lda     $06A1
        bne     L8DEC
        sta     $0681
L8DEC:  jsr     LA209
        rts

L8DF0:  lda     $05A8
        beq     L8DF9
        jsr     LA14F
        rts

L8DF9:  jsr     LA146
        lda     $02
        cmp     #$01
        bne     L8E07
        lda     #$12
        sta     $05A8
L8E07:  rts

        .byte   $D3,$D1,$F6,$80
L8E0C:  .byte   $80,$8C,$8C,$8D,$CA,$BD,$05,$92
        .byte   $85,$08,$BD,$0C,$92,$85,$09,$6C
        .byte   $08,$00,$AD,$E1,$04,$D0,$1B,$A9
        .byte   $09,$20,$F1,$C5,$E6,$B2,$A5,$B2
        .byte   $C9,$40,$F0,$01,$60
        inc     $04E1
        lda     #$00
        sta     $B2
        lda     #$80
        sta     $05A7
        rts

        cmp     #$01
        bne     L8E76
        ldx     $B2
        lda     L8ED9,x
        sta     $03B6
        lda     L8EE8,x
        sta     $03B7
        lda     L8EF7,x
        sta     $47
        sta     zp_temp_00
        ldy     #$00
L8E59:  lda     $05A7
        sta     $03B8,y
        iny
        inc     $05A7
        dec     zp_temp_00
        bne     L8E59
        inx
        stx     $B2
        cpx     #$0F
        bne     L8ED8
        inc     $04E1
        lda     #$00
        sta     $B2
        rts

L8E76:  cmp     #$02
        bne     L8EB0
        ldx     $B2
        cpx     #$10
        beq     L8E9F
        lda     #$23
        sta     $03B6
        txa
        asl     a
        adc     #$D0
        sta     $03B7
        ldy     #$00
L8E8E:  lda     L8F06,x
        sta     $03B8,y
        inx
        iny
        cpy     #$04
        bne     L8E8E
        sty     $47
        stx     $B2
        rts

L8E9F:  inc     $04E1
        lda     #$23
        sta     $03B6
        lda     #$E0
        sta     $03B7
        lda     #$1E
        sta     $B2
L8EB0:  lda     #$00
        ldx     #$1F
L8EB4:  sta     $03B8,x
        dex
        bpl     L8EB4
        clc
        lda     #$20
        sta     $47
        adc     $03B7
        sta     $03B7
        lda     $03B6
        adc     #$00
        sta     $03B6
        dec     $B2
        bne     L8ED8
        inc     $B1
        lda     #$00
        sta     $04E1
L8ED8:  rts

L8ED9:  .byte   $21,$21,$21,$21,$21,$21,$21,$22
        .byte   $22,$22,$22,$22,$22,$22,$22
L8EE8:  .byte   $4B,$69,$87,$A6,$C5,$E5,$EE,$04
        .byte   $24,$44,$64,$84,$A4,$C5,$E6
L8EF7:  .byte   $03,$06,$08,$0A,$0B,$05,$02,$07
        .byte   $07
        php
        php
        php
        php
        .byte   $07,$03
L8F06:  .byte   $FF,$FF,$FF,$FF,$FF,$5F,$FF,$F3
        .byte   $FF,$55,$7F,$FF,$FF,$FF,$FF,$FF
        .byte   $AD,$E1,$04,$D0,$1A,$A9,$67,$A2
        .byte   $01,$20,$52,$A3,$A5,$20,$99,$50
        .byte   $04,$A9,$30,$99,$70,$04,$A9,$E0
        .byte   $99,$B0,$04,$EE,$E1,$04,$60
        cmp     #$02
        bcs     L8F3A
        rts

L8F3A:  bne     L8F79
        ldx     #$0F
L8F3E:  lda     L8F7A,x
        sta     $0356,x
        dex
        bpl     L8F3E
        jsr     boss_init
        lda     #$03
        sta     $B1
        lda     #$5D
        sta     $B2
        lda     #$65
        ldx     #$01
        jsr     LA352
        lda     #$40
        sta     $0470,y
        lda     #$87
        sta     $04B0,y
        lda     #$66
        ldx     #$01
        jsr     LA352
        lda     #$38
        sta     $0470,y
        lda     #$BF
        sta     $04B0,y
        lda     #$2C
        jsr     bank_switch_enqueue
L8F79:  rts

L8F7A:  .byte   $0F,$30,$29,$19,$0F,$27,$11,$19
        .byte   $0F,$11,$29,$19,$0F,$27,$29,$19
        .byte   $A9,$63,$85,$00
        ldy     #$0F
L8F90:  jsr     collision_check_sprite
        bcs     L8FB2
        lda     $0430,y
        and     #$04
        bne     L8FAF
        lda     $0470,y
        cmp     #$60
        bcs     L8FAF
        lda     #$C4
        sta     $0430,y
        lda     $4A
        and     #$03
        sta     $0610,y
L8FAF:  dey
        bpl     L8F90
L8FB2:  jsr     L8FC9
        dec     $B2
        bne     L8FBD
        lda     #$5D
        sta     $B2
L8FBD:  jsr     L9165
        lda     $06A1
        bne     L8FC8
        sta     $0681
L8FC8:  rts

L8FC9:  lda     $04E1
        bne     L8FE5
        lda     $04A1
        cmp     #$53
        bcc     L8FE5
L8FD5:  lda     #$00
        sta     $04E1
        lda     #$00
        sta     $0641
        lda     #$80
        sta     $0661
        rts

L8FE5:  lda     $04A1
        cmp     #$73
        bcs     L8FD5
        lda     #$01
        sta     $04E1
        lda     #$FF
        sta     $0641
        lda     #$80
        sta     $0661
        rts

        .byte   $A9,$63,$85,$00,$A0,$0F
L9002:  jsr     collision_check_sprite
        bcs     L901D
        lda     $0430,y
        and     #$04
        bne     L901A
        lda     $0470,y
        cmp     #$90
        bcs     L901A
        lda     #$C4
        sta     $0430,y
L901A:  dey
        bpl     L9002
L901D:  jsr     L8FC9
        jsr     L9165
        jsr     LA118
        lda     $06C1
        cmp     #$1C
        bne     L9034
        lda     #$00
        sta     $04E1
        inc     $B1
L9034:  rts

L9035:  lda     #$2C
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $06A1
        lda     #$68
        ldx     #$01
        jsr     LA352
        bcs     L9063
        clc
        lda     $04B0,y
        adc     #$10
        sta     $04B0,y
        lda     #$02
L9053:  sta     $09
        lda     #$00
        sta     jump_ptr
        tya
        clc
        adc     #$10
        tax
        stx     $2B
        jsr     LA38C
L9063:  rts

        .byte   $AD,$E1,$04,$D0,$08,$A0,$A0,$20
        .byte   $C5,$90,$EE,$E1,$04
        jsr     L910A
        bcs     L907D
        lda     $0461
        cmp     #$A0
        bcc     L9084
L907D:  lda     #$00
        sta     $04E1
        inc     $B1
L9084:  lda     $06A1
        bne     L908C
        sta     $0681
L908C:  lda     $0641
        bpl     L909A
        lda     $04A1
        cmp     #$A0
        bcc     L90B6
        bcs     L90A1
L909A:  lda     $04A1
        cmp     #$20
        bcs     L90B6
L90A1:  clc
        lda     $0661
        eor     #$FF
        adc     #$01
        sta     $0661
        lda     $0641
        eor     #$FF
        adc     #$00
        sta     $0641
L90B6:  lda     $05A7
        sta     $0421
        jsr     L9165
        lda     #$83
        sta     $0421
        rts

        lda     #$00
        sta     $09
        lda     #$C4
        sta     jump_ptr
        ldx     #$01
        stx     $2B
        lda     $0460
        pha
        sty     $0460
        jsr     LA38C
        lda     #$C3
        sta     $05A7
        pla
        sta     $0460
        rts

        .byte   $AD,$E1,$04,$D0,$0D,$A0,$58,$20
        .byte   $C5,$90,$A9,$83,$8D,$A7,$05,$EE
        .byte   $E1,$04
        lda     $0461
        cmp     #$58
        beq     L9100
        bcs     L9107
L9100:  lda     #$00
        sta     $04E1
        dec     $B1
L9107:  jmp     L9084

L910A:  sec
        lda     $04A0
        sbc     $04A1
        bcs     L9117
        eor     #$FF
        adc     #$01
L9117:  cmp     #$04
        bcs     L9120
        jsr     L9035
        sec
        rts

L9120:  clc
        rts

        .byte   $A5,$B2,$D0,$08,$A9,$0F,$8D,$66
        .byte   $03,$4C,$8B,$A0
        jsr     L9382
        lda     $1C
        and     #$0F
        bne     L9164
        ldx     #$0F
L9139:  sec
        lda     $0356,x
        sbc     #$10
        bpl     L9143
        lda     #$0F
L9143:  sta     $0356,x
        dex
        bpl     L9139
        ldx     #$07
L914B:  sec
        lda     $036E,x
        sbc     #$10
        bpl     L9155
        lda     #$0F
L9155:  sta     $036E,x
        dex
        bpl     L914B
        dec     $B2
        bne     L9164
        lda     #$70
        sta     $05A7
L9164:  rts

L9165:  lda     $04A0
        cmp     #$B0
        bcc     L9174
        lda     #$00
        sta     $0661
        sta     $0641
L9174:  lda     #$0F
        sta     $0366
        jsr     LA59D
        bcc     L9199
        lda     #$0D
        sta     $B2
        lda     #$00
        sta     $0661
        sta     $0641
        sta     $0621
        sta     $0601
        inc     $05AA
        lda     #$07
        sta     $B1
        bne     L91A4
L9199:  lda     $02
        cmp     #$01
        bne     L91A4
        lda     #$30
        sta     $0366
L91A4:  jsr     LA14F
        sec
        lda     $B5
        sbc     $0661
        sta     $B5
        lda     $B6
        sbc     $0641
        sta     $B6
        beq     L91D2
        ldy     $0641
        bpl     L91C9
        cmp     #$10
        bcs     L91D2
        clc
        adc     #$10
        sta     $B6
        jmp     L91D2

L91C9:  cmp     #$11
        bcs     L91D2
        sec
        sbc     #$10
        sta     $B6
L91D2:  lda     $0421
        and     #$40
        beq     L91EF
        clc
        lda     $B7
        adc     $0621
        sta     $B7
        lda     $B8
        adc     $0601
        sta     $B8
        lda     $B9
        adc     #$00
        sta     $B9
        rts

L91EF:  sec
        lda     $B7
        sbc     $0621
        sta     $B7
        lda     $B8
        sbc     $0601
        sta     $B8
        lda     $B9
        sbc     #$00
        sta     $B9
        rts

        asl     L8A16,x
        .byte   $FC,$64,$E5,$22,$8E,$8F,$8F,$8F
        .byte   $90,$90,$91,$CA,$BD,$95,$93,$85
        .byte   $08,$BD,$98,$93,$85,$09,$6C,$08
        .byte   $00,$A5,$B2,$D0,$07,$E6,$B2,$A9
        .byte   $0B,$20,$51,$C0
        jsr     LA118
        lda     $06C1
        cmp     #$1C
        bne     L9241
        lda     #$6F
        sta     $04E1
        inc     $B1
        lda     #$00
        sta     $B2
L9241:  rts

        jmp     L92DC

        .byte   $CE,$E1,$04,$D0,$F8,$A9,$1F,$8D
        .byte   $E1,$04,$A9,$6A,$20,$2D,$A2,$90
        .byte   $EC,$A6,$B2,$BC,$DD,$92,$A2,$00
L925D:  lda     L933F,y
        sta     jump_ptr,x
        iny
        inx
        cpx     #$08
        bne     L925D
        lda     $B2
        asl     a
        sta     $01
        ldx     #$00
L926F:  stx     $02
        lda     #$6A
        ldx     #$01
        jsr     LA352
        ldx     $01
        lda     L92EB,x
        sta     $04B0,y
        lda     L9307,x
        sta     $0470,y
        lda     L9323,x
        sta     $04F0,y
        ldx     $02
        lda     jump_ptr,x
        sta     $0650,y
        lda     $0A,x
        sta     $0610,y
        lda     $0C,x
        sta     $0430,y
        lda     $0E,x
        sta     $0120,y
        inc     $01
        inx
        cpx     #$02
        bne     L926F
        lda     $B2
        asl     a
        sta     $0C
L92AE:  ldx     $0C
        lda     $0440
        sta     $09
        lda     L9307,x
        and     #$F0
        sta     jump_ptr
        lda     L92EB,x
        sta     $0A
        jsr     LC8EF
        lda     $51
        bne     L92CE
        inc     $51
        inc     $0C
        bne     L92AE
L92CE:  lda     #$82
        sta     $51
        inc     $B2
        lda     $B2
        cmp     #$0E
        bne     L92DC
        inc     $B1
L92DC:  rts

        .byte   $00,$00,$00,$08,$10,$00,$00,$10
        .byte   $08,$00,$10,$10,$00,$10
L92EB:  .byte   $57,$57,$87,$87,$B7,$B7,$27,$C7
        .byte   $27,$C7,$77,$77,$37,$37,$27,$C7
        .byte   $27,$C7,$A7,$A7,$27,$C7,$27,$C7
        .byte   $97,$97,$27,$C7
L9307:  plp
        cld
        plp
        cld
        plp
        cld
        cli
        pla
        clv
        tay
        plp
        cld
        plp
        cld
        tay
        tya
        sec
        pha
        plp
        cld
        pla
        cli
        iny
        clv
        plp
        cld
        pha
        sec
L9323:  brk
        .byte   $00,$00,$00,$00,$00,$00,$00,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$03
        .byte   $03,$03,$03
L933F:  .byte   $00,$00,$01,$01,$CB,$8B,$50,$50
        .byte   $FF,$01,$00,$00,$CB,$8B,$50,$50
        .byte   $FF,$01,$00,$00,$8B,$CB,$50,$50
        .byte   $AD,$C1,$06,$D0,$0C,$A9,$BB,$85
        .byte   $B2,$EE,$AA,$05,$A9,$FF,$20,$51
        .byte   $C0,$60,$A5,$B2,$F0,$0D,$C6,$B2
        .byte   $F0,$04,$20,$82,$93,$60
        lda     #$80
        sta     $05A7
        lda     #$0F
        sta     $0366
        jmp     LA08B

L9382:  ldx     #$0F
        lda     $1C
        and     #$07
        bne     L9391
        lda     #$2B
        jsr     bank_switch_enqueue
        ldx     #$30
L9391:  stx     $0366
        rts

        .byte   $21
        eor     $57
        .byte   $92,$92,$93,$CA,$BD,$62,$96
        sta     jump_ptr
        lda     L9668,x
        sta     $09
        jmp     (jump_ptr)

        .byte   $20,$18,$A1,$AD,$E1,$04,$D0,$25
        .byte   $A9,$02,$8D,$54,$03,$A9,$04,$8D
        .byte   $55,$03,$A9,$B2,$8D,$A7,$05,$A9
        .byte   $00,$8D,$A9,$05,$A9,$10,$8D,$B6
        .byte   $03,$A9,$E0,$8D,$B7,$03,$A9,$69
        .byte   $85,$B2,$EE,$E1,$04
        lda     $04E1
        cmp     #$01
        bne     L93F0
        lda     #$0B
        jsr     LC5F1
        dec     $B2
        beq     L93E7
        rts

L93E7:  inc     $04E1
        lda     #$10
        sta     $05A7
        rts

L93F0:  cmp     #$02
        bne     L9430
        ldx     $B2
        cpx     #$0B
        beq     L941F
        lda     LA9C0,x
        sta     $03B6
        lda     LA9CB,x
        sta     $03B7
        lda     LA9D6,x
        sta     $47
        ldy     #$00
L940D:  lda     $05A7
        sta     $03B8,y
        inc     $05A7
        iny
        cpy     $47
        bne     L940D
        inx
        stx     $B2
        rts

L941F:  lda     #$21
        sta     $03B6
        lda     #$E0
        sta     $03B7
        lda     #$00
        sta     $B2
        inc     $04E1
L9430:  lda     $04E1
        cmp     #$03
        bne     L9472
        clc
        lda     #$20
        sta     $47
        adc     $03B7
        sta     $03B7
        lda     $03B6
        adc     #$00
        sta     $03B6
        ldx     $B2
        cpx     #$B0
        beq     L9461
        ldy     #$00
L9452:  lda     LA9E1,x
        sta     $03B8,y
        inx
        iny
        cpy     #$16
        bne     L9452
        stx     $B2
        rts

L9461:  lda     #$23
        sta     $03B6
        lda     #$C0
        sta     $03B7
        lda     #$00
        sta     $B2
        inc     $04E1
L9472:  clc
        lda     $03B7
        adc     #$08
        sta     $03B7
        lda     $03B6
        adc     #$00
        sta     $03B6
        lda     #$06
        sta     $47
        ldx     $B2
        cpx     #$1E
        beq     L949E
        ldy     #$00
L948F:  lda     LAA91,x
        sta     $03B8,y
        inx
        iny
        cpy     #$06
        bne     L948F
        stx     $B2
        rts

L949E:  lda     #$00
        sta     $47
        sta     $04E1
        lda     #$8B
        sta     $05A7
        inc     $B1
        rts

        .byte   $AD,$21,$04,$30,$05,$A9,$FF,$8D
        .byte   $61,$04
        ldx     $04E1
        lda     $B8
        cmp     L950D,x
        bne     L9509
        cpx     #$01
        bne     L94D2
        lda     #$8B
        sta     $0421
        lda     $B7
        sta     $0481
        jmp     L94F8

L94D2:  lda     L9515,x
        sta     $01
        lda     L9519,x
        sta     $02
        lda     L9511,x
        ldx     #$01
        jsr     LA352
        lda     $01
        sta     $04B0,y
        lda     #$FF
        sta     $0470,y
        lda     $B7
        sta     $0490,y
        lda     $02
        sta     $06F0,y
L94F8:  inc     $04E1
        lda     $04E1
        cmp     #$04
        bne     L9509
        lda     #$3F
        sta     $04E1
        inc     $B1
L9509:  jsr     L91A4
        rts

L950D:  .byte   $D7,$C7,$A7,$8C
L9511:  .byte   $69,$00,$63,$67
L9515:  .byte   $7F,$00,$A8,$68
L9519:  ora     #$00
        .byte   $14,$06,$A5,$B8,$C9,$30,$D0,$06
        .byte   $A9,$7D,$85,$B2,$E6,$B1
        lda     #$8B
L952B:  sta     $05A7
        lda     #$60
        sta     $0621
        jsr     L9563
        rts

        .byte   $A5,$B8,$C9,$80,$D0,$06,$A9,$7D
        .byte   $85,$B2,$E6,$B1
        lda     #$CB
        bne     L952B
        lda     #$05
        bne     L954D
        lda     #$03
L954D:  sta     zp_temp_00
        dec     $B2
        bne     L9557
        lda     zp_temp_00
        sta     $B1
L9557:  lda     #$00
        sta     $0601
        sta     $0621
        jsr     L9563
        rts

L9563:  dec     $04E1
        beq     L956B
        jmp     L9613

L956B:  lda     #$3F
        sta     $04E1
        jsr     LA209
        lda     zp_temp_00
        cmp     #$38
        bcc     L95C6
        lda     #$69
        jsr     LA22D
        lda     #$01
        sta     $04F0,y
        lda     #$02
        sta     $02
        lda     #$34
        sta     zp_temp_00
        ldy     #$0F
L958D:  jsr     collision_check_sprite
        bcs     L9599
        dec     $02
        beq     L9613
        dey
        bpl     L958D
L9599:  lda     #$34
        ldx     #$01
        jsr     LA352
        bcs     L9613
        lda     #$87
        sta     $0430,y
        clc
        lda     $04B0,y
        adc     #$30
        sta     $04B0,y
        lda     #$C4
        sta     $0630,y
        lda     #$01
        sta     $0610,y
        lda     #$02
        sta     $0650,y
        lda     #$D4
        sta     $0670,y
        bne     L9613
L95C6:  sec
        lda     zp_temp_00
        sbc     #$10
        bcs     L95CF
        lda     #$00
L95CF:  sta     jump_ptr
        lda     #$00
        asl     jump_ptr
        rol     a
        asl     jump_ptr
        rol     a
        asl     jump_ptr
        rol     a
        sta     $09
        lda     #$69
        jsr     LA22D
        lda     #$00
        sta     $04F0,y
        lda     #$35
        ldx     #$01
        jsr     LA352
        bcs     L9613
        lda     #$85
        sta     $0430,y
        clc
        lda     $04B0,y
        adc     #$10
        sta     $04B0,y
        lda     #$04
        sta     $0650,y
        lda     $09
        sta     $0610,y
        lda     jump_ptr
        sta     $0630,y
        lda     #$01
        sta     $06A1
L9613:  lda     $06A1
        bne     L961B
        sta     $0681
L961B:  lda     #$0F
        sta     $0366
        jsr     LA59D
        bcc     L9648
L9625:  lda     #$00
        sta     $0354
        sta     $0355
        lda     #$0D
        sta     $B2
        lda     #$00
        sta     $0661
        sta     $0641
        sta     $0621
        sta     $0601
        inc     $05AA
        lda     #$07
        sta     $B1
        bne     L9653
L9648:  lda     $02
        cmp     #$01
        bne     L9653
        lda     #$30
        sta     $0366
L9653:  lda     $05A7
        sta     $0421
        jsr     L91A4
        lda     #$83
        sta     $0421
        rts

        .byte   $A9,$AD,$1D,$47,$37,$4B
L9668:  .byte   $93,$94,$95,$95,$95,$95,$CA,$BD
        .byte   $BC,$96,$85,$08,$BD,$BE,$96,$85
        .byte   $09,$6C,$08,$00,$20,$18,$A1,$AD
        .byte   $C1,$06,$C9,$1C,$F0,$01,$60
        lda     #$04
        sta     $02
L968B:  lda     #$6D
        ldx     #$01
        jsr     LA352
        ldx     $02
        lda     L96AD,x
        sta     $0470,y
        lda     L96B2,x
        sta     $04B0,y
        lda     L96B7,x
        sta     $0430,y
        dec     $02
        bpl     L968B
        inc     $B1
        rts

L96AD:  .byte   $14,$44,$AC,$EC,$EC
L96B2:  .byte   $60,$30,$40,$70,$B0
L96B7:  .byte   $C3,$C3,$83,$83,$83,$7C,$57,$96
        .byte   $93,$CA,$BD,$1C,$9B,$85,$08,$BD
        .byte   $23,$9B,$85,$09,$6C,$08,$00,$A9
        .byte   $00,$8D,$81,$06,$AD,$E1,$04,$D0
        .byte   $35,$A9,$02,$8D,$54,$03,$A9,$04
        .byte   $8D,$55,$03,$A9,$B0,$8D,$A7,$05
        .byte   $A9,$00,$8D,$A9,$05,$8D,$54,$03
        .byte   $8D,$55,$03,$A9,$0F,$A2,$0B
L96F6:  sta     $035A,x
        dex
        bpl     L96F6
        lda     #$15
        sta     $03B6
        lda     #$A0
        sta     $03B7
        lda     #$52
        sta     $B2
        inc     $04E1
        lda     $04E1
        cmp     #$01
        bne     L9730
        lda     #$08
        jsr     LC5F1
        dec     $B2
        beq     L971E
        rts

L971E:  inc     $04E1
        lda     #$00
        sta     $B2
        lda     #$27
        sta     $03B6
        lda     #$CB
        sta     $03B7
        rts

L9730:  cmp     #$02
        bne     L974B
        ldx     $B2
        cpx     #$14
        beq     L973E
        jsr     L97F8
        rts

L973E:  inc     $04E1
        lda     #$00
        sta     $B2
        lda     #$5C
        sta     $05A7
        rts

L974B:  ldx     $B2
        cpx     #$0E
        bcs     L9755
        jsr     L97D4
        rts

L9755:  cpx     #$13
        bcs     L9774
        lda     $1C
        and     #$03
        bne     L9774
        lda     #$04
        ldy     #$0B
        ldx     #$0F
        jsr     L979B
        lda     #$18
        ldy     #$13
        ldx     #$1F
        jsr     L979B
        inc     $B2
        rts

L9774:  jsr     LA118
        lda     $06C1
        cmp     #$1C
        bne     L979A
        inc     $B1
        lda     #$56
        ldx     #$01
        jsr     LA352
        lda     #$AB
        sta     $0430,y
        lda     #$B0
        sta     $0470,y
        lda     #$80
        sta     $04B0,y
        lda     #$3E
        sta     $B2
L979A:  rts

L979B:  sta     zp_temp_00
L979D:  lda     $0356,x
        cmp     #$0F
        bne     L97AC
        lda     L97C0,y
        and     #$0F
        jmp     L97B6

L97AC:  clc
        adc     #$10
        cmp     L97C0,y
        beq     L97B6
        bcs     L97B9
L97B6:  sta     $0356,x
L97B9:  dex
        dey
        cpx     zp_temp_00
        bne     L979D
        rts

L97C0:  .byte   $0F,$15,$17,$35,$0F,$27,$17,$07
        .byte   $0F,$15,$17,$07,$0F,$0F,$11,$2C
        .byte   $0F,$0F,$25,$15
L97D4:  lda     projectile_x_velocity,x
        sta     $03B6
        lda     projectile_y_velocity,x
        sta     $03B7
        lda     projectile_timing,x
        sta     $47
        ldy     #$00
L97E7:  lda     $05A7
        sta     $03B8,y
        inc     $05A7
        iny
        cpy     $47
        bne     L97E7
        inc     $B2
        rts

L97F8:  ldy     #$00
L97FA:  lda     projectile_anim_frames,x
        sta     $03B8,y
        inx
        iny
        cpy     #$05
        bne     L97FA
        sty     $47
        stx     $B2
        clc
        lda     $03B7
        adc     #$08
        sta     $03B7
        rts

        .byte   $AD,$61,$04,$C9,$38,$B0,$02,$E6
        .byte   $B1
        lda     #$83
L981F:  sta     $0421
        sta     $05A7
        jsr     L9A10
        lda     #$83
        sta     $0421
        dec     $B2
        bne     L989C
        lda     #$3E
        sta     $B2
        lda     $0461
        pha
        clc
        adc     #$28
        sta     $0461
        jsr     LA209
        pla
        sta     $0461
        lda     zp_temp_00
        sta     $0B
        lda     #$1A
        sta     $0D
        lda     #$00
        sta     $0A
        sta     $0C
        jsr     LC874
        lda     #$6B
        ldx     #$01
        jsr     LA352
        bcs     L989C
        clc
        lda     $0461
        adc     #$28
        sta     $0470,y
        clc
        lda     $04A1
        adc     #$36
        sta     $04B0,y
        lda     $0F
        sta     $0610,y
        lda     $0E
        sta     $0630,y
        lda     $B1
        cmp     #$04
        bcc     L989C
        lda     $0430,y
        ora     #$04
        sta     $0430,y
        lda     #$00
        sta     $0650,y
        sta     $0670,y
        lda     #$01
        sta     $0610,y
        lda     #$1E
        sta     $0630,y
L989C:  lda     #$83
        sta     $0421
        rts

        .byte   $AD,$61,$04,$C9,$98,$90,$02,$C6
        .byte   $B1
        lda     #$C3
        jmp     L981F

        .byte   $20,$18,$A1,$A9,$00,$8D,$81,$06
        .byte   $8D,$A1,$06,$CE,$AB,$05,$D0,$41
        .byte   $A9,$0C,$8D,$AB,$05,$A5,$4A,$85
        .byte   $01,$A9,$18,$85,$02,$20,$4E,$C8
        .byte   $A5,$04,$85,$08,$A5,$4A,$85,$01
        .byte   $A9,$30,$85,$02,$20,$4E,$C8,$A5
        .byte   $04,$85,$09,$A9,$6C,$A2,$01,$20
        .byte   $52,$A3,$B0,$15,$38,$AD,$A1,$04
        .byte   $E9,$18,$18,$65,$09,$99,$B0,$04
        .byte   $18,$AD,$61,$04,$65,$08,$99,$70
        .byte   $04
        lda     $04E1
        bne     L991C
        lda     #$73
        sta     $0401
        lda     #$27
        sta     $03B6
        lda     #$CB
        sta     $03B7
        lda     #$14
        sta     $B2
        inc     $04E1
L991C:  lda     $04E1
        cmp     #$02
        bcs     L9939
        ldx     $B2
        cpx     #$28
        beq     L992D
        jsr     L97F8
        rts

L992D:  lda     #$0E
        sta     $B2
        lda     #$00
        sta     $05A9
        inc     $04E1
L9939:  ldx     $B2
        cpx     #$16
        bcs     L9967
        lda     projectile_x_velocity,x
        sta     $03B6
        lda     projectile_y_velocity,x
        sta     $03B7
        lda     projectile_timing,x
        sta     $47
        ldy     #$00
        ldx     $05A9
L9955:  lda     projectile_tile_ids,x
        sta     $03B8,y
        inx
        iny
        cpy     $47
        bne     L9955
        stx     $05A9
        inc     $B2
        rts

L9967:  lda     $06C1
        cmp     #$1C
        beq     L996F
        rts

L996F:  inc     $B1
        lda     #$3E
        sta     $B2
        lda     #$A3
        sta     $0621
        rts

        .byte   $AD,$E1,$04,$F0,$1C,$AD,$A0,$04
        .byte   $C9,$E0
        bcs     L998E
        inc     $04A0
        inc     $04A0
        rts

L998E:  lda     #$00
        sta     L0420
        dec     $B2
        bne     L999B
        lda     #$FF
        sta     $B1
L999B:  rts

        jsr     L9382
        lda     $04A1
        beq     L99BA
        sec
        lda     $04C1
        sbc     #$80
        sta     $04C1
        lda     $04A1
        sbc     #$00
        sta     $04A1
        bne     L99BA
        sta     $0421
L99BA:  lda     $4A
        sta     $01
        lda     #$20
        sta     $02
        jsr     LC84E
        lda     #$06
        ldx     #$01
        jsr     LA352
        bcs     L99E4
        lda     $4A
        asl     a
        lda     $4A
        rol     a
        rol     a
        rol     a
        rol     a
        ora     #$08
        sta     $0470,y
        clc
        lda     $04
        adc     #$C8
        sta     $04B0,y
L99E4:  inc     $B2
        lda     $B2
        cmp     #$FD
        beq     L99ED
        rts

L99ED:  lda     #$0F
        ldx     #$10
L99F1:  sta     $0356,x
        dex
        bpl     L99F1
        inc     $04E1
        lda     #$0B
        sta     $2C
        lda     #$00
        sta     $06A0
        sta     $0680
        lda     #$0C
        sta     $0400
        lda     #$3E
        sta     $B2
        rts

L9A10:  lda     #$0F
        sta     $0366
        lda     $B1
        cmp     #$04
        bcs     L9A27
        lda     $A9
        cmp     #$02
        beq     L9A2D
        cmp     #$05
        beq     L9A2D
        bne     L9A35
L9A27:  lda     $A9
        cmp     #$01
        bne     L9A35
L9A2D:  lda     $0421
        ora     #$08
        sta     $0421
L9A35:  jsr     LA59D
        bcc     L9A7D
        lda     $B1
        cmp     #$04
        bcs     L9A56
        lda     #$04
        sta     $B1
        lda     #$0C
        sta     $05AB
        lda     #$00
        sta     $0601
        sta     $0621
        sta     $04E1
        beq     L9A88
L9A56:  lda     #$74
        jsr     LA10C
        clc
        lda     $0461
        adc     #$28
        sta     $0461
        lda     #$57
        sta     $04A1
        lda     #$00
        sta     $04E1
        lda     #$56
        jsr     LA22D
        bcs     L9A7A
        lda     #$00
        .byte   $99
        .byte   $30
L9A79:  .byte   $04
L9A7A:  jmp     L9625

L9A7D:  lda     $02
        cmp     #$01
        bne     L9A88
        lda     #$30
        sta     $0366
L9A88:  jsr     L91A4
        rts

projectile_x_velocity:  and     $25
        and     $25
        and     $25
        and     $25
        rol     $26
        rol     $26
        rol     $26
        and     $25
        and     $25
        rol     $26
        rol     $26
projectile_y_velocity:  .byte   $17
        rol     $56,x
        adc     ($90),y
        bcs     L9A79
        beq     L9AB9
        rol     $6E4E
        .byte   $93,$B4,$90,$B0,$D0,$F0,$0E,$2E
        .byte   $4E,$6E
projectile_timing:  .byte   $04
L9AB9:  ora     $06
        .byte   $0B,$0D,$0D,$0D,$0D,$0F,$0E,$0D
        .byte   $0C,$04,$02,$04,$04,$04,$04,$06
        .byte   $07,$05,$04
projectile_anim_frames:  .byte   $FF,$AF,$FF,$BF,$FF,$FF,$FD,$FF
        .byte   $FA,$EE,$F7,$BF,$AF,$FF,$FF,$FF
        .byte   $FB,$FA,$FF,$FF,$FF,$AF,$FF,$BF
        .byte   $FF,$FF,$EE,$FF,$FA,$EE,$FB,$BE
        .byte   $AF,$FF,$FF,$FF,$FB,$FA,$FF,$FF
projectile_tile_ids:  .byte   $00,$E6,$E7,$E8,$00,$00,$E9,$EA
        .byte   $00,$00,$EB,$EC,$ED,$EE,$EF,$F0
        .byte   $00,$00,$F1,$F2,$F3,$F4,$F5,$F6
        .byte   $F7,$F8,$F9,$FA,$FB,$00,$00,$00
        .byte   $00,$FC,$00,$00,$00,$00
        dec     LA214
        bcs     L9B35
        ldx     #$7B
        stx     $98,y
        tya
        tya
        tya
        tya
        sta     LBDCA,y
        lda     L859F,x
        php
        lda     L9FC8,x
        sta     $09
L9B35:  jmp     (jump_ptr)

        .byte   $AD,$E1,$04,$D0,$20,$A0,$0F,$A2
        .byte   $0E,$20,$E0,$D3,$A9,$08,$8D,$AE
        .byte   $04,$A9,$B4,$8D,$6E,$04,$A9,$7D
        .byte   $85,$B2,$A9,$00,$8D,$54,$03,$8D
        .byte   $55,$03,$EE,$E1,$04
        lda     $04E1
        cmp     #$02
        bcs     L9B95
        lda     $042E
        bpl     L9B7D
        lda     $04AE
        cmp     #$90
        bcc     L9B7C
        ldx     #$83
        stx     $0421
        cmp     #$E0
        bcc     L9B7C
        lsr     $042E
L9B7C:  rts

L9B7D:  dec     $B2
        bne     L9B7C
        ldx     #$02
L9B83:  lda     L9C50,x
        sta     $036F,x
        dex
        bpl     L9B83
        inc     $04E1
        lda     #$76
        jsr     LA10C
L9B94:  rts

L9B95:  bne     L9BD5
        lda     $06A1
L9B9A:  cmp     #$03
        bne     L9B94
        lda     #$00
        sta     $0681
        ldx     #$0A
        lda     $B2
        cmp     #$7D
        bcc     L9BAD
        ldx     #$12
L9BAD:  lda     $B2
        and     #$04
        beq     L9BB8
        txa
        clc
        adc     #$08
        tax
L9BB8:  ldy     #$07
L9BBA:  lda     L9C50,x
        sta     $036E,y
        dex
        dey
        bpl     L9BBA
        inc     $B2
        lda     $B2
        cmp     #$FD
        bne     L9BD4
        inc     $04E1
        lda     #$77
        jsr     LA10C
L9BD4:  rts

L9BD5:  lda     $0461
        cmp     #$D8
        beq     L9BED
        clc
        lda     $0481
        adc     #$80
        sta     $0481
        lda     $0461
        adc     #$00
        sta     $0461
L9BED:  jsr     LA118
        lda     $06C1
        cmp     #$1C
        bne     L9BD4
        inc     $B1
        lda     #$0E
        sta     $B2
        lda     #$3E
        sta     $05A7
        lda     #$00
        sta     $05A9
        lda     #$30
        sta     $035F
        lda     #$01
        sta     $2B
        ldx     #$0C
L9C12:  stx     $02
        lda     #$70
        jsr     LA359
        ldx     $02
L9C1B:  lda     L9C36,x
        sta     $04B0,x
        lda     L9C43,x
        pha
        and     #$F0
        ora     #$04
        sta     $0470,x
        pla
        and     #$0F
        sta     $06B0,x
        dex
        bpl     L9C12
        rts

L9C36:  .byte   $34,$34,$64,$94,$B4,$D4,$24,$44
        .byte   $54,$74,$84,$B4,$C4
L9C43:  jsr     fixed_D0B0
        bvs     L9C88
        beq     L9C1B
        eor     ($01),y
        lda     ($31,x)
        sbc     ($11,x)
L9C50:  bmi     L9C8A
        asl     $0F,x
        asl     $30,x
        bmi     L9C67
        asl     $38,x
        sec
        .byte   $0F,$16,$38,$29,$0F,$16,$38,$29
        .byte   $0F,$16,$29,$19
L9C67:  .byte   $0F,$16,$29,$19,$20,$D8,$9C,$20
        .byte   $46,$A1,$A2,$0F,$A5,$02,$C9,$01
        .byte   $D0,$0F,$AD,$AA,$05,$F0,$08,$A9
        .byte   $00,$8D,$E1,$04,$E6,$B1,$60
        ldx     #$30
L9C88:  .byte   $8E
        .byte   $66
L9C8A:  .byte   $03
        clc
        lda     $B7
        adc     #$60
        sta     $B7
        lda     $B8
        adc     #$01
        sta     $B8
        lda     $B9
        adc     #$00
        sta     $B9
        jsr     LA209
        dec     $05A7
        bne     L9CB7
        lda     #$3E
        sta     $05A7
        lda     #$6F
        jsr     LA352
        bcs     L9CB7
        lda     #$04
        jsr     L9053
L9CB7:  rts

L9CB8:  .byte   $B9,$19,$00,$E7,$47,$E7,$00,$19
L9CC0:  .byte   $FE,$FF,$00,$00,$01,$00,$00,$FF
L9CC8:  .byte   $00,$E7,$47,$E7,$00,$E7,$47,$E7
L9CD0:  .byte   $00,$00,$01,$00,$00,$00,$01,$00
        dec     $B2
        bne     L9CE3
        inc     $05A9
        lda     #$1C
        sta     $B2
L9CE3:  lda     $05A9
        pha
        and     #$07
        tax
        lda     L9CB8,x
        sta     $0661
        lda     L9CC0,x
        sta     $0641
        lda     L9CC8,x
        sta     $0621
        lda     L9CD0,x
        sta     $0601
        ldx     #$83
        pla
        and     #$08
        beq     L9D0B
        ldx     #$C3
L9D0B:  stx     $0421
        rts

        ldx     $04E1
        bne     L9D38
        lda     #$E0
        sta     $03B7
        lda     #$0F
        sta     $03B6
        lda     #$00
        sta     $05A9
        lda     #$94
        sta     $05A7
        lda     #$80
        sta     $B2
        inc     $04E1
        inx
        lda     #$FF
        jsr     bank_switch_enqueue
        lsr     $0421
L9D38:  dex
        lda     L9FCB,x
        sta     $09
        lda     L9FC0,x
        sta     jump_ptr
        jmp     (jump_ptr)

L9D46:  lda     $1C
        and     #$0F
        bne     L9D51
        lda     #$2B
        jsr     bank_switch_enqueue
L9D51:  ldx     #$10
        ldy     #$0F
        lda     $1C
        and     #$04
        bne     L9D5D
        ldy     #$30
L9D5D:  tya
L9D5E:  sta     $0356,x
        dex
        bpl     L9D5E
        rts

        .byte   $20,$46,$9D,$A5,$B2,$F0,$08,$A9
        .byte   $08,$20,$F1,$C5,$C6,$B2,$60
        inc     $04E1
        lda     #$00
        sta     $FD
        lda     #$0F
        sta     $FE
        rts

        .byte   $20,$46,$9D,$A5,$FD,$C9,$60,$B0
        .byte   $04,$20,$0C,$CB,$60
        inc     $04E1
        lda     #$00
        sta     $05A7
        lda     #$8D
        sta     $05A9
        lda     #$00
        sta     $1A
        sta     $1B
        beq     L9DAC
        jsr     L9D46
        lda     $05A7
        and     #$3F
        beq     L9DC7
L9DAC:  lda     #$0C
        sta     $2A
        lda     $05A7
        sta     jump_ptr
        lda     $05A9
        sta     $09
        jsr     LCA0B
        lda     #$0D
        sta     $2A
        inc     $05A7
        inc     $1A
        rts

L9DC7:  inc     $04E1
        inc     $20
        inc     $0440
        inc     $0441
        lda     #$00
        sta     $B8
        sta     $B9
        ldx     #$10
L9DDA:  lda     L9E30,x
        sta     $0356,x
        dex
        bpl     L9DDA
        ldy     #$10
        ldx     #$0E
        jsr     fixed_D3E0
        lda     #$80
        sta     $042E
        lda     #$A7
        sta     $04AE
        lda     #$E0
        sta     $046E
        ldy     #$11
        ldx     #$0D
        jsr     fixed_D3E0
        lda     #$80
        sta     $046D
        lda     #$37
        sta     $04AD
        lda     #$80
        sta     $0421
        lda     #$80
        sta     $04A1
        lda     #$D8
        sta     $0461
        lda     #$0E
        sta     $B2
        lda     #$00
        sta     $05A9
        sta     $05AB
        lda     #$78
        jsr     LA10C
        lda     #$2A
        jsr     bank_switch_enqueue
        rts

L9E30:  .byte   $0F,$20,$11,$01,$0F,$20,$2C,$1C
        .byte   $0F,$20,$23,$13,$0F,$20,$0F,$0F
        .byte   $0F,$20,$6D,$9E,$AD,$A9,$05,$C9
        .byte   $24,$F0,$09,$20,$D8,$9C,$86,$03
        .byte   $20,$57,$A1,$60
        lda     #$84
        sta     $0421
        lda     #$00
        sta     $B2
        sta     $0601
        sta     $0621
        sta     $0641
        sta     $0661
        inc     $04E1
        rts

        ldx     #$2C
        lda     $1C
        and     #$04
        bne     L9E77
        ldx     #$00
L9E77:  stx     $0370
        rts

L9E7B:  .byte   $0F,$20,$0F,$0F,$0F,$20,$0C,$0F
        .byte   $0F,$20,$1C,$0C,$0F,$20,$11,$0C
        .byte   $0F,$20,$11,$01,$20,$6D,$9E,$A9
        .byte   $80,$85,$03,$20,$57,$A1,$A9,$04
        .byte   $85,$01
        sta     $02
        jsr     LA249
        lda     zp_temp_00
        beq     L9EBA
        ldx     $B2
        cpx     #$02
        beq     L9EBB
        lda     L9EEF,x
        sta     $0661
        lda     L9EF1,x
        sta     $0641
        inc     $B2
L9EBA:  rts

L9EBB:  lsr     $042E
        lda     #$79
        jsr     LA10C
        lda     #$A7
        sta     $04A1
        lda     #$E0
        sta     $0461
        lda     #$3E
        sta     $B2
        lda     #$00
        sta     $05A7
        inc     $04E1
        lsr     $042D
        ldx     #$0F
L9EDE:  lsr     $0430,x
        dex
        bpl     L9EDE
        lda     #$30
        sta     $0374
        lda     #$15
        sta     $0375
        rts

L9EEF:  .byte   $76,$00
L9EF1:  .byte   $03,$02,$A5,$B2,$F0,$1B,$A5,$1C
        .byte   $29,$07,$D0,$05,$A9,$2B,$20,$51
        .byte   $C0
        ldx     #$0F
        lda     $1C
        and     #$04
        bne     L9F0C
        ldx     #$30
L9F0C:  stx     $0366
        dec     $B2
        rts

        lda     #$0F
        sta     $0366
        inc     $05A7
        lda     $05A7
        cmp     #$41
        beq     L9F35
        lsr     a
        lsr     a
        and     #$1C
        tax
        ldy     #$00
L9F28:  lda     L9E7B,x
        sta     $0362,y
        inx
        iny
        cpy     #$04
        bne     L9F28
        rts

L9F35:  inc     $04E1
        lda     #$7A
        jsr     LA10C
        lda     #$84
        sta     $0421
        lda     #$50
        sta     $0621
        lda     #$00
        sta     $0601
        lda     #$53
        sta     $0661
        lda     #$06
        sta     $0641
        rts

        .byte   $A9,$84,$85,$03,$20,$57,$A1,$A9
        .byte   $0C,$85,$01,$85,$02,$20,$49,$A2
        .byte   $A5,$00,$D0,$01,$60
        lda     L0420
        and     #$BF
        ldx     $0460
        cpx     #$B0
        bcs     L9F7A
        ora     #$40
L9F7A:  sta     L0420
        lda     #$7B
        jsr     LA10C
        inc     $04E1
        lda     #$FD
        sta     $05A7
        lda     #$80
        sta     $05A9
        lda     #$02
        sta     $05AB
        lda     #$16
        jsr     bank_switch_enqueue
        rts

        .byte   $20,$09,$A2,$AD,$A7,$05,$F0,$04
        .byte   $CE,$A7,$05,$60
        lda     #$00
        sta     $06A1
        sta     $0681
        dec     $05A9
        bne     L9FBC
        dec     $05AB
        bne     L9FBC
        lda     #$FF
        sta     $B1
L9FBC:  rts

        sec
        .byte   $6B,$0F
L9FC0:  .byte   $65,$80,$A2,$41,$8F,$F3,$57,$9A
L9FC8:  .byte   $9B,$9C,$9D
L9FCB:  .byte   $9D,$9D,$9D,$9E,$9E,$9E,$9F,$9F
enemy_ai_fallback:  sec
        lda     $B3
        sbc     #$08
        bcc     L9FE8
        tax
        lda     LA100,x
        sta     jump_ptr
        lda     LA106,x
        sta     $09
        jmp     (jump_ptr)

L9FE8:  lda     #$00
        sta     $0681
        lda     $05A7
        cmp     #$10
        bcc     L9FF7
        jmp     LA08B

L9FF7:  and     #$01
        bne     LA037
        lda     $05A7
        and     #$07
        sta     $02
        ldx     #$01
LA004:  stx     $01
        lda     #$60
        jsr     LA359
        ldx     $02
        clc
        lda     $0461
        adc     $C1E0,x
        sta     $0470,y
        lda     $0441
        adc     $C1E8,x
        sta     $0450,y
        clc
        lda     $04A1
        adc     $C1D8,x
        sta     $04B0,y
        lda     #$01
        sta     $06B0,y
        inx
        stx     $02
        ldx     $01
        dex
        bpl     LA004
LA037:  inc     $05A7
        lda     $05A7
        cmp     #$10
        bne     LA08A
        ldx     #$1B
        lda     $0461
        sta     jump_ptr
        lda     $0441
        sta     $09
        lda     $04A1
        sta     $0A
        lda     #$60
        sta     $0B
        jsr     LC3A8
        lda     #$41
        jsr     bank_switch_enqueue
        lda     #$FF
        jsr     bank_switch_enqueue
        lda     $2A
        cmp     #$0C
        bne     LA08A
        lda     #$76
        ldx     #$0E
        jsr     LA359
        lda     #$02
        sta     $065E
        lda     #$85
        sta     $043E
        inc     $04FE
        lda     $BC
        cmp     #$FF
        beq     LA08A
        lsr     $0421
        lda     #$00
        sta     $B1
LA08A:  rts

LA08B:  lsr     $0421
        lda     $05A7
        cmp     #$FD
        bcs     LA099
        inc     $05A7
        rts

LA099:  bne     LA0A9
        inc     $05A7
        lda     #$FD
        sta     $05A9
        lda     #$15
        jsr     bank_switch_enqueue
        rts

LA0A9:  cmp     #$FE
        bne     LA0BA
        dec     $05A9
        bne     LA0FF
        inc     $05A7
        lda     #$D0
        sta     $05A9
LA0BA:  lda     $05A9
        cmp     #$40
        bcc     LA0DC
        bne     LA0F6
        dec     $05A9
        lda     #$26
        sta     $0400
        lda     #$00
        sta     $06A0
        sta     $0680
        lda     #$0B
        sta     $2C
        lda     #$3A
        jsr     bank_switch_enqueue
LA0DC:  lda     $06A0
        cmp     #$03
        bne     LA0FF
        lda     L0420
        bpl     LA0F6
        sec
        lda     $04A0
        sbc     #$08
        sta     $04A0
        bcs     LA0FF
        lsr     L0420
LA0F6:  dec     $05A9
        bne     LA0FF
        lda     #$FF
        sta     $B1
LA0FF:  rts

LA100:  .byte   $22,$69,$22,$69,$7B,$0F
LA106:  .byte   $91,$93,$91,$93,$99,$9D
LA10C:  sta     $0401
        lda     #$00
        sta     $0681
        sta     $06A1
        rts

LA118:  lda     $1C
        and     #$03
        bne     LA12D
        lda     $06C1
        cmp     #$1C
        beq     LA12D
        inc     $06C1
        lda     #$28
        jsr     bank_switch_enqueue
LA12D:  rts

LA12E:  lda     $0421
        eor     #$40
        sta     $0421
        jsr     LA2D4
        lda     $0421
        sta     $03
        eor     #$40
        sta     $0421
        jmp     LA154

LA146:  jsr     LA59D
        bcc     LA14F
        inc     $05AA
        rts

LA14F:  lda     $0421
        sta     $03
LA154:  jsr     setup_ppu_normal
        sec
        lda     $04C1
        sbc     $0661
        sta     $04C1
        lda     $04A1
        sbc     $0641
        sta     $04A1
        cmp     #$F0
        bcc     LA173
        lda     #$F0
        sta     $04A1
LA173:  lda     $0421
        and     #$04
        beq     LA18B
        clc
        lda     $0661
        sbc     $30
        sta     $0661
        lda     $0641
        sbc     $31
        sta     $0641
LA18B:  lda     $03
        and     #$40
        bne     LA1CD
        sec
        lda     $0481
        sbc     $0621
        sta     $0481
        lda     $0461
        sbc     $0601
        sta     $0461
        lda     $0441
        sbc     #$00
        sta     $0441
        sec
        lda     $0461
        sbc     $1F
        sta     jump_ptr
        lda     $0441
        sbc     $20
        bne     LA1C1
        lda     jump_ptr
        cmp     #$08
        bcs     LA207
LA1C1:  lda     $20
        sta     $0440
        lda     #$08
        sta     $0461
        bne     LA207
LA1CD:  clc
        lda     $0481
        adc     $0621
        sta     $0481
        lda     $0461
        adc     $0601
        sta     $0461
        lda     $0441
        adc     #$00
        sta     $0441
        sec
        lda     $0461
        sbc     $1F
        sta     jump_ptr
        lda     $0441
        sbc     $20
        bne     LA1FD
        lda     jump_ptr
        cmp     #$F8
        bcc     LA207
LA1FD:  lda     $20
        sta     $0441
        lda     #$F8
        sta     $0461
LA207:  clc
        rts

LA209:  lda     $0421
        and     #$BF
        sta     $0421
        sec
        .byte   $AD
        .byte   $61
LA214:  .byte   $04
        sbc     $0460
        sta     zp_temp_00
        bcs     LA22C
        lda     zp_temp_00
        eor     #$FF
        adc     #$01
        sta     zp_temp_00
        lda     #$40
        ora     $0421
        sta     $0421
LA22C:  rts

LA22D:  sta     zp_temp_00
        ldy     #$0F
collision_check_sprite:  lda     zp_temp_00; Check collision between player and sprite
LA233:  cmp     $0410,y
        beq     LA23D
        dey
        bpl     LA233
        sec
        rts

LA23D:  lda     $0430,y
        bmi     LA247
        dey
        bpl     collision_check_sprite
        sec
        rts

LA247:  clc
        rts

LA249:  lda     #$00
        sta     $0B
        lda     $0641
        php
        bpl     LA25C
        clc
        lda     $04A1
        adc     $02
        jmp     LA262

LA25C:  sec
        lda     $04A1
        sbc     $02
LA262:  sta     $0A
        clc
        lda     $0461
        adc     $01
        sta     jump_ptr
        lda     $0441
        adc     #$00
        sta     $09
        jsr     LCC63
        ldy     zp_temp_00
        lda     LA349,y
        sta     $02
        sec
        lda     $0461
        sbc     $01
        sta     jump_ptr
        lda     $0441
        sbc     #$00
        sta     $09
        jsr     LCC63
        ldy     zp_temp_00
        lda     LA349,y
        ora     $02
        sta     zp_temp_00
        beq     LA2D2
        plp
        bmi     LA2AA
        lda     $0A
        and     #$0F
        eor     #$0F
        sec
        adc     $04A1
        jmp     LA2B8

LA2AA:  lda     $04A1
        pha
        lda     $0A
        and     #$0F
        sta     $02
        pla
        sec
        sbc     $02
LA2B8:  sta     $04A1
        lda     #$00
        sta     $04C1
        lda     $0421
        and     #$04
        beq     LA2D1
        lda     #$C0
        sta     $0661
        lda     #$FF
        sta     $0641
LA2D1:  rts

LA2D2:  plp
        rts

LA2D4:  lda     $04A1
        sta     $0A
        lda     #$00
        sta     $0B
        lda     $0421
        and     #$40
        php
        beq     LA2F5
        sec
        lda     $0461
        adc     $01
        sta     jump_ptr
        lda     $0441
        adc     #$00
        jmp     LA302

LA2F5:  clc
        lda     $0461
        sbc     $01
        sta     jump_ptr
        lda     $0441
        sbc     #$00
LA302:  sta     $09
        jsr     LCC63
        ldy     zp_temp_00
        lda     LA349,y
        sta     $03
        beq     LA345
        plp
        beq     LA32D
        lda     jump_ptr
        and     #$0F
        sta     zp_temp_00
        sec
        lda     $0461
        sbc     zp_temp_00
        sta     $0461
        lda     $0441
        sbc     #$00
        sta     $0441
        jmp     LA249

LA32D:  lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     $0461
        sta     $0461
        lda     $0441
        adc     #$00
        sta     $0441
        jmp     LA249

LA345:  plp
        jmp     LA249

LA349:  brk
        .byte   $01,$00,$01,$00,$01,$01,$01,$01
LA352:  pha
        jsr     fixed_DA43
        bcs     LA389
        pla
LA359:  jsr     fixed_D77C
        txa
        tay
        lda     $0421
        and     #$40
        ora     $0430,y
        sta     $0430,y
        lda     $0481
        sta     $0490,y
        lda     $0461
        sta     $0470,y
        lda     $0441
        sta     $0450,y
        lda     $04C1
        sta     $04D0,y
        lda     $04A1
        sta     $04B0,y
        clc
        rts

LA389:  pla
        sec
        rts

LA38C:  ldy     #$40
        sec
        lda     $0460
        sbc     $0460,x
        sta     zp_temp_00
        bcs     LA3A3
        lda     zp_temp_00
        eor     #$FF
        adc     #$01
        ldy     #$00
        sta     zp_temp_00
LA3A3:  lda     L0420,x
        and     #$BF
        sta     L0420,x
        tya
        ora     L0420,x
        sta     L0420,x
        sec
        lda     $04A0
        sbc     $04A0,x
        php
        bcs     LA3C0
        eor     #$FF
        adc     #$01
LA3C0:  sta     $01
        cmp     zp_temp_00
        bcs     LA401
        lda     $09
        sta     $0D
        sta     $0600,x
        lda     jump_ptr
        sta     $0C
        sta     $0620,x
        lda     zp_temp_00
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     LC874
        lda     $0F
        sta     $0D
        lda     $0E
        sta     $0C
        lda     $01
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     LC874
        ldx     $2B
        lda     $0F
        sta     $0640,x
        lda     $0E
        sta     $0660,x
        jmp     LA439

LA401:  lda     $09
        sta     $0D
        sta     $0640,x
        lda     jump_ptr
        sta     $0C
        sta     $0660,x
        lda     $01
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     LC874
        lda     $0F
        sta     $0D
        lda     $0E
        sta     $0C
        lda     zp_temp_00
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     LC874
        ldx     $2B
        lda     $0F
        sta     $0600,x
        lda     $0E
        sta     $0620,x
LA439:  plp
        bcc     LA450
        lda     $0660,x
        eor     #$FF
        adc     #$01
        sta     $0660,x
        lda     $0640,x
        eor     #$FF
        adc     #$00
        sta     $0640,x
LA450:  rts


; =============================================================================
; Boss Initialization
; Sets up boss properties from indexed tables.
; X = boss ID ($B3), loads AI flags, position, type, etc.
; =============================================================================
boss_init:  ldx     $B3                 ; Initialize boss from property tables (X = boss ID)
        lda     $20
        sta     $0441
        lda     boss_ai_flags,x
        sta     $0421
        lda     boss_movement_mode,x
        sta     $0461
        lda     boss_x_position,x
        sta     $04A1
        lda     boss_y_position,x
        sta     $0401
        lda     boss_type_table,x
        sta     $06E1
        lda     LA4F5,x
        sta     $0621
        lda     boss_palette_table,x
        sta     $0601
        lda     LA511,x
        sta     $0661
        lda     LA51F,x
        sta     $0641
        lda     #$00
        sta     $04C1
        sta     $0481
        sta     $0681
        sta     $06A1
        sta     $04E1
        sta     $06C1
        sta     $05A8
        sta     $05AA
        sta     $B2
        lda     #$01
        sta     $B1
        rts

boss_ai_flags:  .byte   $83,$83,$83,$83,$83,$83,$83,$83
        .byte   $8B,$00,$00,$00,$83,$00
boss_movement_mode:  .byte   $C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8
        .byte   $70,$C8,$FF,$C8,$78,$B4
boss_x_position:  .byte   $28
        plp
        bmi     LA4F7
        plp
        plp
        plp
        plp
        .byte   $6B,$10,$4B,$10,$77,$7C
boss_y_position:  .byte   $50,$66,$6C,$60,$54,$5A,$63,$69
        .byte   $70,$50,$71,$50,$72,$75
boss_type_table:  .byte   $01,$09,$09,$01,$01,$01,$01,$01
        .byte   $0D,$01,$01,$01,$00,$01
LA4F5:  .byte   $00,$00
LA4F7:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $60,$00
        cpy     zp_temp_00
boss_palette_table:  brk
        brk
        brk
        brk
        .byte   $00,$00,$00,$00,$00
        brk
        brk
        .byte   $00,$00,$00
LA511:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00
LA51F:  .byte   $F8,$F8
        sed
        sed
        sed
        sed
        sed
        sed
        brk
        .byte   $00,$00,$00,$00,$00
setup_ppu_normal:  lda     #$00
        sta     $01
        lda     $2C
        beq     LA59C
        lda     $BD
        bne     LA59C
        lda     $F9
        bne     LA59C
        sec
        lda     $0460
        sbc     $0461
        bcs     LA54A
        eor     #$FF
        adc     #$01
LA54A:  ldy     $06E1
        cmp     $D4E4,y
        bcs     LA59C
        sec
        lda     $04A0
        sbc     $04A1
        bcs     LA55F
        eor     #$FF
        adc     #$01
LA55F:  cmp     $D584,y
        bcs     LA59C
        lda     $4B
        bne     LA59C
        ldy     $B3
        sec
        lda     $06C0
        sbc     LA9B2,y
        sta     $06C0
        beq     LA578
        bcs     LA582
LA578:  lda     #$00
        sta     $2C
        sta     $06C0
        jmp     LC10B

LA582:  lda     L0420
        and     #$BF
        sta     L0420
        lda     $0421
        and     #$40
        eor     #$40
        ora     L0420
        sta     L0420
        jsr     fixed_D332
        inc     $01
LA59C:  rts

LA59D:  ldx     #$09
        lda     $1C
        and     #$01
        bne     LA5A6
        dex
LA5A6:  lda     L0420,x
        bpl     LA5DE
        and     #$01
        beq     LA5DE
        clc
        ldy     $0590,x
        lda     $D4DF,y
        adc     $06E1
        tay
        sec
        lda     $0461
        sbc     $06E0,x
        bcs     LA5C7
        eor     #$FF
        adc     #$01
LA5C7:  cmp     $D4E4,y
        bcs     LA5DE
        sec
        lda     $04A1
        sbc     $04A0,x
        bcs     LA5D9
        eor     #$FF
        adc     #$01
LA5D9:  cmp     $D584,y
        bcc     LA5EE
LA5DE:  dex
        dex
        cpx     #$02
        bcs     LA5A6
        ldx     $2B
        lda     #$00
        sta     $B4
        sta     $02
LA5EC:  clc
        rts

LA5EE:  lda     $B4
        bne     LA5EC
        ldy     $A9
        lda     LA930,y
        sta     jump_ptr
        lda     LA939,y
        sta     $09
        jmp     (jump_ptr)

        .byte   $AD
        and     ($04,x)
        and     #$08
        bne     LA63D
        ldy     $B3
        lda     LA942,y
        sta     zp_temp_00
        beq     LA63D
        php
        lsr     L0420,x
        plp
        bpl     LA61B
        jmp     LA91B

LA61B:  jsr     LA929
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $02
        inc     $B4
        sec
        lda     $06C1
        sbc     zp_temp_00
        sta     $06C1
        beq     LA636
        bcs     LA658
LA636:  lda     #$00
        sta     $06C1
        sec
        rts

LA63D:  lda     L0420,x
        eor     #$40
        and     #$FE
        sta     L0420,x
        lda     #$05
        sta     $0640,x
        sta     $0600,x
        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $02
LA658:  clc
        rts

        .byte   $A5,$B3,$C9,$00,$D0,$03
        jmp     LA91B

        lda     $0421
        and     #$08
        bne     LA6B8
        ldy     $B3
        lda     LA950,y
        beq     LA6B8
        lda     $04E0,x
        cmp     #$02
        bcc     LA68A
        beq     LA67F
        lda     LA950,y
        bne     LA68D
LA67F:  clc
        lda     LA942,y
        asl     a
        adc     LA942,y
        jmp     LA68D

LA68A:  lda     LA942,y
LA68D:  sta     zp_temp_00
        beq     LA6B8
        bpl     LA696
        jmp     LA91B

LA696:  jsr     LA929
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $02
        inc     $B4
        sec
        lda     $06C1
        sbc     zp_temp_00
        sta     $06C1
        beq     LA6B1
        bcs     LA6C7
LA6B1:  lda     #$00
        sta     $06C1
        sec
        rts

LA6B8:  lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $02
        lsr     L0420,x
        jmp     LA6CC

LA6C7:  lda     #$00
        sta     L0420,x
LA6CC:  clc
        rts

        .byte   $AD,$21,$04,$29,$08,$D0,$30,$A4
        .byte   $B3,$B9,$5E,$A9,$85,$00,$F0,$27
        .byte   $10,$03,$4C,$1B,$A9
        jsr     LA929
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $02
        inc     $B4
        sec
        lda     $06C1
        sbc     zp_temp_00
        sta     $06C1
        beq     LA6FE
        bcs     LA6C7
LA6FE:  lda     #$00
        sta     $06C1
        sec
        rts

        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $02
        lda     L0420,x
        and     #$FE
        sta     L0420,x
        lda     #$3D
        sta     $0400,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        clc
        rts

        .byte   $AD,$21,$04,$29,$08,$D0,$30,$A4
        .byte   $B3,$B9,$6C,$A9,$85,$00,$F0,$27
        .byte   $10,$03,$4C,$1B,$A9
        jsr     LA929
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $02
        inc     $B4
        sec
        lda     $06C1
        sbc     zp_temp_00
        sta     $06C1
        beq     LA755
        bcs     LA782
LA755:  lda     #$00
        sta     $06C1
        sec
        rts

        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $02
        lda     L0420,x
        and     #$F2
        sta     L0420,x
        lda     #$3B
        sta     $0400,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        sta     $04E0,x
        sta     $06C0,x
LA780:  clc
        rts

LA782:  lda     #$00
        sta     L0420,x
        beq     LA780
        lda     $0421
        and     #$08
        bne     LA7C0
        ldy     $B3
        lda     LA97A,y
        sta     zp_temp_00
        beq     LA7C0
        bpl     LA79E
        jmp     LA91B

LA79E:  jsr     LA929
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $02
        inc     $B4
        sec
        lda     $06C1
        sbc     zp_temp_00
        sta     $06C1
        beq     LA7B9
        bcs     LA782
LA7B9:  lda     #$00
        sta     $06C1
        sec
        rts

LA7C0:  lda     #$00
        sta     $0600,x
        sta     $0620,x
        sta     $0660,x
        lda     #$04
        sta     $0640,x
        lda     #$80
        sta     L0420,x
        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $02
        clc
        rts

        .byte   $AD,$21,$04,$29,$08,$D0,$30,$A4
        .byte   $B3,$B9,$88,$A9,$85,$00
        beq     LA817
        bpl     LA7F5
        jmp     LA91B

LA7F5:  jsr     LA929
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $02
        inc     $B4
        sec
        lda     $06C1
        sbc     zp_temp_00
        sta     $06C1
        beq     LA810
        bcs     LA84D
LA810:  lda     #$00
        sta     $06C1
        sec
        rts

LA817:  lda     #$3C
        sta     $0400,x
        lda     L0420,x
        and     #$C0
        eor     #$40
        ora     #$04
        sta     L0420,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        sta     $0600,x
        sta     $0660,x
        lda     #$C0
        sta     $0620,x
        lda     #$04
        sta     $0640,x
        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $02
LA849:  ldx     $2B
        clc
        rts

LA84D:  lda     #$00
        sta     L0420,x
        beq     LA849
        lda     $0421
        and     #$08
        bne     LA88B
        ldy     $B3
        lda     LA996,y
        sta     zp_temp_00
        beq     LA88B
        bpl     LA869
        jmp     LA91B

LA869:  jsr     LA929
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $02
        inc     $B4
        sec
        lda     $06C1
        sbc     zp_temp_00
        sta     $06C1
        beq     LA884
        bcs     LA84D
LA884:  lda     #$00
        sta     $06C1
        sec
        rts

LA88B:  lda     $0400,x
        cmp     #$2F
        beq     LA8B4
        lda     $04E0,x
        cmp     #$02
        beq     LA8B4
        lda     #$05
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        lda     #$38
        sta     $06C0,x
        inc     $04E0,x
        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $02
LA8B4:  clc
        rts

        .byte   $AD,$21,$04,$29,$08,$D0,$30,$A4
        .byte   $B3,$B9,$A4,$A9,$85,$00,$F0,$27
        .byte   $10,$03,$4C,$1B,$A9
        jsr     LA929
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $02
        inc     $B4
        sec
        lda     $06C1
        sbc     zp_temp_00
        sta     $06C1
        beq     LA8E6
        bcs     LA914
LA8E6:  lda     #$00
        sta     $06C1
        sec
        rts

        lda     #$03
        sta     $0640,x
        lda     #$B2
        sta     $0660,x
        lda     #$01
        sta     $0600,x
        lda     #$87
        sta     $0620,x
        lda     L0420,x
        and     #$F0
        sta     L0420,x
        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $02
LA912:  clc
        rts

LA914:  lda     #$00
        sta     L0420,x
        beq     LA912
LA91B:  lda     #$1C
        sta     $06C1
        lda     #$00
        sta     $02
        lsr     L0420,x
        clc
        rts

LA929:  lda     $CB
        bne     LA92F
        asl     zp_temp_00
LA92F:  rts

LA930:  .byte   $01,$5A,$CE,$25,$89,$E0,$1B,$B6
        .byte   $54
LA939:  ldx     $A6
        ldx     $A7
        .byte   $A7,$A7,$A9,$A8,$A8
LA942:  .byte   $02,$02,$01,$01,$02,$02,$01,$01
        .byte   $01,$00,$01,$00,$01,$FF
LA950:  .byte   $FF,$06,$0E,$00,$0A,$06,$04,$06
        .byte   $08,$00,$08,$00,$0E,$FF,$02,$00
        .byte   $04,$00,$02,$00,$00,$0A,$00,$00
        .byte   $00,$00,$01,$FF,$00,$08,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF
LA97A:  .byte   $06,$00,$00,$FF,$00,$02,$00,$01
        .byte   $00,$00
        ora     (zp_temp_00,x)
        brk
        .byte   $01,$02,$02,$00,$02,$00,$00,$04
        .byte   $01,$01,$00,$02,$00,$01,$FF
LA996:  .byte   $FF,$00,$02,$02,$04,$03,$00,$00
        .byte   $01,$00,$01,$00,$04,$FF
        ora     (zp_temp_00,x)
        .byte   $02,$04,$00,$04
        asl     a:zp_temp_00
        brk
        brk
        .byte   $00,$01,$FF
LA9B2:  php
        php
        php
        .byte   $04,$04,$04,$06,$04,$1C,$08,$04
        .byte   $08,$0A,$14
LA9C0:  jsr     L2020
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
LA9CB:  .byte   $C7,$E6,$EE,$06,$26,$44,$64,$85
        .byte   $A5,$C5,$E6
LA9D6:  .byte   $03,$05,$02,$0A,$0A,$0D,$0F,$0E
        .byte   $0E,$0F,$0E
LA9E1:  .byte   $00,$00,$00,$00,$00,$00,$83,$84
        .byte   $85,$86,$87,$88,$89,$8A,$8B,$8C
        .byte   $8D,$8D,$8D,$8E,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$8F,$90,$91,$92
        .byte   $93,$94,$95,$96,$97,$98
        tya
        sta     L9B9A,y
        brk
        .byte   $00,$9C,$9D,$9E,$9F,$A0,$A1,$A2
        .byte   $A3,$A2,$A3,$A2,$A3,$A2,$A3,$A2
        .byte   $A3,$A2,$A4,$A5,$A6,$A7,$00,$A8
        .byte   $A9,$AA,$AB,$AC,$AD,$AE,$AF,$AE
        .byte   $AF,$AE,$AF,$AE,$AF,$AE,$AF,$AE
        .byte   $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7
        .byte   $B8
        lda     LBBBA,y
        ldy     LBABD,x
        .byte   $BB
        ldy     LBABD,x
        .byte   $BB
        ldy     LBABD,x
        .byte   $BB
        ldy     LBFBE,x
        cpy     #$C1
        .byte   $C2,$C3,$C4,$C5,$C6,$C7,$C8,$C5
        .byte   $C6,$C7,$C8,$C5,$C6,$C7,$C8,$C5
        .byte   $C6,$C7,$C9,$CA,$CB,$CC,$CD,$CE
        .byte   $CF,$D0,$D1,$D2,$D3,$D0,$D1,$D2
        .byte   $D3,$D0,$D1,$D2,$D3,$D0,$D1,$D2
        .byte   $D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB
        .byte   $DC,$DD,$DE,$DF,$DC,$DD,$DE,$DF
        .byte   $DC,$DD,$DE,$DF,$DC,$DD,$E0,$E1
LAA91:  .byte   $FF,$3F,$0F,$FF,$FF,$FF,$FF,$33
        .byte   $44,$FD,$FF,$FF,$FF,$7F,$D0,$FF
        .byte   $FF,$FF,$FF,$F7,$F5,$FF,$FF,$FF
        .byte   $AF
        tax
        tax
        tax
        tax
        tax
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$21,$21,$21,$21,$21,$21,$21
        .byte   $21,$21,$20,$10,$12,$05,$13,$13
        .byte   $20,$20,$13,$14,$01,$12,$14,$20
        .byte   $21,$21,$21,$21,$21,$21,$21
        and     ($21,x)
        jsr     L2020
        jsr     L2220
        .byte   $23,$23,$23,$23,$24,$20,$20,$22
        .byte   $23,$23,$23,$23,$24,$20,$20,$22
        .byte   $23,$23,$23,$23,$24,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$25
        .byte   $30,$31,$32,$33,$2B,$20,$20
        and     $40
        eor     ($42,x)
        .byte   $43,$2B,$20,$20,$25,$50,$51,$52
        .byte   $53,$2B,$20,$20,$20,$20,$20,$2C
        .byte   $2C,$2C,$2C,$2C,$26,$34,$35,$36
        .byte   $37,$2B,$2C,$2C
        rol     $44
        eor     $46
        .byte   $47,$2B,$2C,$2C,$26,$54,$55,$56
        .byte   $57,$2B,$2C,$2C,$2C,$2C,$2C,$2D
        .byte   $2D,$2D,$2D,$2D,$27,$38,$39,$3A
        .byte   $3B,$2B,$2D,$2D,$27,$48,$49,$4A
        .byte   $4B,$2B,$2D,$2D,$27,$58,$59,$5A
        .byte   $5B,$2B,$2D,$2D,$2D,$2D,$2D,$20
        .byte   $20,$20,$20,$20,$25,$3C,$3D,$3E
        .byte   $3F,$2B,$20,$20,$25,$4C,$4D,$4E
        .byte   $4F,$2B,$20,$20,$25,$5C,$5D,$5E
        .byte   $5F,$2B,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$28,$29,$29,$29
        .byte   $29,$2A,$20,$20,$28,$29,$29,$29
        .byte   $29,$2A,$20,$20,$28,$29,$29,$29
        .byte   $29,$2A,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$02,$15,$02,$02
        .byte   $0C,$05,$20,$20,$20,$01,$09,$12
        .byte   $20,$20,$20,$20,$11,$15,$09,$03
        .byte   $0B,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$0D
        .byte   $01,$0E,$20,$20,$20,$20,$20,$0D
        .byte   $01,$0E,$20,$20,$20,$20,$20,$0D
        .byte   $01,$0E,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$22,$23,$23,$23
        .byte   $23,$24,$20,$20,$22,$23,$23,$23
        .byte   $23,$24,$20,$20,$22,$23,$23,$23
        .byte   $23,$24,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$25,$60,$61,$62
        .byte   $63,$2B,$20,$20
        and     $70
        adc     ($72),y
        .byte   $73,$2B,$20,$20,$25,$80,$81,$82
        .byte   $83,$2B,$20,$20,$20,$20,$20,$2C
        .byte   $2C,$2C,$2C,$2C,$26,$64,$65,$66
        .byte   $67,$2B,$2C,$2C,$26,$74,$75,$76
        .byte   $77,$2B,$2C,$2C,$26,$84,$85,$86
        .byte   $87,$2B,$2C,$2C,$2C,$2C,$2C,$2D
        .byte   $2D,$2D,$2D,$2D,$27,$68,$69,$6A
        .byte   $6B,$2B,$2D,$2D,$27,$78,$79,$7A
        .byte   $7B,$2B,$2D,$2D,$27,$88,$89,$8A
        .byte   $8B,$2B,$2D,$2D,$2D,$2D,$2D,$20
        .byte   $20,$20,$20,$20,$25,$6C,$6D,$6E
        .byte   $6F,$2B,$20,$20,$25,$7C,$7D,$7E
        .byte   $7F,$2B,$20,$20,$25,$8C,$8D,$8E
        .byte   $8F,$2B,$20,$20,$20,$20
        jsr     L2020
        jsr     L2020
        plp
        and     #$29
        and     #$29
        rol     a
        jsr     L2820
        and     #$29
        and     #$29
        rol     a
        jsr     L2820
        and     #$29
        and     #$29
        rol     a
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L0508
        ora     ($14,x)
        jsr     L2020
        jsr     L0420
        .byte   $1B,$20,$20,$20,$20,$20,$17,$0F
        .byte   $0F,$04,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20
        ora     $0E01
        jsr     L2020
        jsr     L0917
        .byte   $0C,$19,$20,$20,$20,$20,$20,$0D
        .byte   $01,$0E,$20,$20,$20,$20,$20
        jsr     L2020
        jsr     L2220
        .byte   $23,$23,$23,$23,$24,$20,$20,$22
        .byte   $23,$23,$23,$23,$24,$20,$20,$22
        .byte   $23,$23,$23,$23,$24,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$25
        .byte   $90,$91,$92,$93,$2B,$20,$20,$25
        .byte   $A0,$A1
        ldx     #$A3
        .byte   $2B,$20,$20,$25,$B0,$B1,$B2,$B3
        .byte   $2B,$20,$20
        jsr     L2020
        bit     $2C2C
        bit     $262C
        sty     $95,x
        stx     $97,y
        .byte   $2B,$2C,$2C,$26,$A4,$A5,$A6,$A7
        .byte   $2B,$2C,$2C,$26,$B4,$B5,$B6,$B7
        .byte   $2B,$2C,$2C,$2C,$2C,$2C,$2D,$2D
        .byte   $2D,$2D,$2D,$27,$98,$99,$9A,$9B
        .byte   $2B,$2D,$2D,$27,$A8,$A9,$AA,$AB
        .byte   $2B,$2D,$2D,$27,$B8,$B9,$BA,$BB
        .byte   $2B,$2D,$2D,$2D,$2D,$2D,$20,$20
        .byte   $20,$20,$20,$25,$9C,$9D,$9E,$9F
        .byte   $2B,$20,$20,$25,$AC,$AD,$AE,$AF
        .byte   $2B,$20,$20,$25,$BC,$BD,$BE,$BF
        .byte   $2B,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$28,$29,$29,$29,$29
        .byte   $2A,$20,$20,$28,$29,$29,$29,$29
        .byte   $2A,$20,$20,$28,$29,$29,$29,$29
        .byte   $2A,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$0D,$05,$14,$01,$0C
        .byte   $20,$20,$20,$06,$0C,$01,$13,$08
        .byte   $20,$20,$20,$03,$12,$01,$13,$08
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$0D,$01
        .byte   $0E,$20,$20,$20,$20,$20,$0D,$01
        .byte   $0E,$20,$20,$20,$20,$20,$0D,$01
        .byte   $0E,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$21,$21
        .byte   $21,$21,$21
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($21,x)
        and     ($20,x)
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     zp_temp_00
        brk
        .byte   $00,$00,$00,$00,$00,$00,$44,$11
        .byte   $00,$00,$CC,$33,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$CC,$33
        .byte   $00,$00,$88,$22,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$CC,$30
        .byte   $00,$00,$00,$33,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$03,$03,$00,$00,$00
        .byte   $00,$00,$03,$04,$04,$00,$00,$00
        .byte   $01,$01,$02,$02,$04,$00,$00,$07
        .byte   $38,$C0,$01,$01,$03,$00,$00,$00
        .byte   $20,$10,$08,$04,$02,$00,$00,$80
        .byte   $C0,$E0,$F0,$F8,$FC,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$07,$06,$0C
        .byte   $00,$03,$1F,$FC,$F1,$08,$08,$10
        .byte   $10,$20,$40,$03,$0E,$04,$00,$0E
        .byte   $7F,$FF,$1F,$7E,$F0,$03,$01,$00
        .byte   $00,$00,$E0,$80,$00,$02,$01,$01
        .byte   $C0,$F0,$80,$01,$1E,$FC,$FE,$3E
        .byte   $0F,$07,$03,$00,$00,$00,$00,$00
        .byte   $80,$80,$C0,$C0,$C0,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00
        ora     ($01,x)
        .byte   $03
        brk
        .byte   $00,$00,$00,$00,$01,$01,$03,$00
        .byte   $00,$40,$C0,$C0,$C0,$C0,$C0,$00
        .byte   $00,$40,$E0,$E0,$E0,$E0,$E0,$03
        .byte   $07,$0F,$0F,$1F,$1F,$3F,$3F,$00
        .byte   $00,$00,$00,$01,$03,$07,$07,$E1
        .byte   $C3,$80,$00,$80,$C1,$C2,$D1,$1E
        .byte   $3C,$7C,$F8,$B8,$D8,$DD,$CE,$C0
        .byte   $03,$0F,$3F,$FF,$FF,$70,$C0,$00
        .byte   $00,$00,$00,$00,$00,$80,$00,$FF
        .byte   $FF,$FF,$FE,$FD,$FB,$FB,$36,$00
        .byte   $00,$00,$00,$01,$03,$03,$06,$60
        .byte   $20,$8E,$07,$C3,$E1,$60,$30
        brk
        brk
        .byte   $00,$00,$C0,$E0,$20,$10,$00,$00
        .byte   $00,$80,$E0,$E0,$F0,$F0,$00,$00
        .byte   $00,$80,$60,$20,$37,$13,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$80,$F0,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$03,$07
        .byte   $07,$0F,$0F,$1F,$1F,$3F,$03,$07
        .byte   $07,$0F,$0F,$1F,$1F,$3F,$C0,$C0
        .byte   $C0,$C0,$80,$80,$80,$80,$F0,$F0
        .byte   $F0,$F0,$F0,$F0,$F8,$F8,$6F,$4F
        .byte   $4F,$FF,$7E,$7F,$3F,$3E,$07,$07
        .byte   $07,$03,$80,$80,$C0,$C0,$D1,$D6
        .byte   $A4,$A8,$59,$F3,$E7,$E7,$CE,$C8
        .byte   $98,$90,$21,$03,$07,$07,$0E,$3F
        .byte   $7F,$FF,$FF,$FF,$FF,$FE,$0E,$3F
        .byte   $7F,$FF,$FF,$FF,$FF,$FE,$16,$16
        .byte   $86,$A6,$B6,$73,$6B,$ED,$06,$06
        .byte   $86,$86,$86,$03,$03,$01,$30,$30
        .byte   $30,$31,$31,$61,$E3,$C3,$10,$10
        .byte   $10,$10,$10,$20,$E0,$C0,$F8,$F8
        .byte   $FC,$FC,$FC,$FC,$FC,$F8,$19,$18
        .byte   $1C,$1C,$1C,$3C,$3C,$39,$00,$00
        .byte   $00,$20,$00,$00,$01,$83,$FE,$FF
        .byte   $FF,$CE,$CC,$FC
        sbc     $33,y
        brk
        asl     $1E
        .byte   $7F
        .byte   $FF
        .byte   $FF,$FF,$00,$80,$C6,$1E,$71,$C0
        .byte   $80,$80,$3F,$1F,$8F,$86,$40
        ldy     #$D8
        cpx     #$3F
        .byte   $3F,$BF,$DF,$67,$B0,$DF,$E7,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$F8
        .byte   $F8,$F8,$F0,$E8,$1C,$FA,$F6,$00
        .byte   $00,$00,$00,$00,$06,$07,$07,$00
        .byte   $00,$00,$00,$00,$06,$07,$07,$00
        .byte   $00,$00,$00,$00,$00,$00,$C0,$00
        .byte   $00,$00,$00,$00,$00,$00,$C0,$0E
        .byte   $02,$00,$38,$3C,$3E,$38,$18,$70
        .byte   $44,$02,$38,$3C,$3E,$38,$18,$CF
        .byte   $CF,$0F,$1F,$11,$10,$10,$40,$0F
        .byte   $0F,$0F,$1F,$11,$10,$10,$00
        inc     $FDFD,x
        .byte   $FB,$F7,$EA,$D0,$20,$FE,$FC,$FC
        .byte   $F8,$F0,$E4,$CC,$18,$C0,$C0,$80
        .byte   $80,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$07,$07,$0F
        .byte   $0F,$1F,$1F,$3F,$3F,$00,$00,$00
        .byte   $01,$01,$03,$03,$07,$F8,$F8,$F0
        .byte   $F2,$E0,$C0,$80,$00
        adc     $F2FB,y
        .byte   $F4,$E4,$CF,$8F,$1F,$07,$07,$2F
        .byte   $0F,$5F,$1F,$3F,$3F,$07,$06,$2E
        .byte   $0C,$5C,$1C,$3C,$3F,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$01,$07,$0F
        .byte   $1F,$3F,$7F,$FF,$FF,$F8,$FC,$FC
        .byte   $FC,$FC,$F8,$F8,$F8,$F8,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$C0,$E0
        .byte   $E0,$E0,$C0,$00,$00,$0F,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$80
        .byte   $80,$C0,$C0,$C0,$C0,$03,$03,$03
        .byte   $03,$01,$01,$01,$01,$03,$03,$03
        .byte   $03,$01,$01
LB4BE:  ora     ($01,x)
        beq     LB4BE
        inc     $F6F9,x
        inx
        .byte   $DC,$BE,$F0,$FC,$FE,$F8,$F0,$E0
        .byte   $C4,$8E,$18,$0C,$00,$C3,$00,$00
        .byte   $00,$00,$18,$0C,$00,$1C,$1F,$0F
        .byte   $03,$00,$70,$5F,$8E,$00,$01,$04
        .byte   $10,$00,$00,$20,$71,$FF,$FE,$F8
        .byte   $E0,$00,$C0,$80,$00,$00,$00,$00
        .byte   $00,$00,$30,$60,$C0,$80,$00,$00
        .byte   $00,$00,$00,$00,$01,$03,$07,$00
        .byte   $03,$0F,$00,$00,$00,$00,$01,$00
        .byte   $00,$00,$7E,$FC,$F8,$F0,$C0,$03
        .byte   $C7,$F7,$0E,$1C,$38,$F1,$C0,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$E0
        .byte   $F0,$F8,$3E,$7E,$FC,$FC,$18,$00
        .byte   $00,$00,$1F,$1F,$1F,$0F,$0F,$07
        .byte   $03,$01,$3F,$7F,$7F,$7F,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$F8,$F0,$F0,$E0,$C0,$80
        .byte   $00,$03,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FC,$F3,$00,$00,$00,$00,$00,$00
        .byte   $FE,$FF,$FF,$FF,$FF,$FF,$FF,$01
        .byte   $FE,$FF,$1E,$1E,$1E,$1C,$19,$01
        .byte   $00,$00,$C1,$C3,$D7,$DF,$9F,$9F
        .byte   $01,$00,$80,$E0,$F0,$F0,$F2,$F3
        .byte   $67,$0F,$00,$00,$00,$1C,$BC,$FC
        .byte   $F8,$7C,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $80,$C0,$BF,$7F,$7E,$FE,$FE,$FC
        .byte   $FC,$F8,$9F,$1F,$0E,$0E,$1E,$3C
        .byte   $7C,$78,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$1E,$38,$30,$71,$63,$67
        .byte   $2F,$3E,$01,$07,$0F,$0E,$1C,$18
        .byte   $10,$01,$39,$0C,$07,$F7,$FF,$9F
        .byte   $0F,$3F,$C0,$F0,$F8,$08,$00,$60
        .byte   $F0,$C0,$FC,$FE,$FE,$FF,$FF,$FF
        .byte   $FF,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$3C,$1F,$8F
        .byte   $8F,$87,$FF,$FF,$03,$7C,$3F,$3F
        .byte   $1F,$1F,$38,$00,$00,$00,$C1,$F9
        .byte   $FE,$FE,$FF,$FF,$FF,$3E,$C5,$F9
        .byte   $FE,$FF,$0E,$39,$67,$DF,$BF,$7F
        .byte   $FF,$3F,$CE,$B8,$60,$C0,$80,$00
        .byte   $00,$00,$01,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$01,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$80,$80,$C0,$C0
        .byte   $C0,$E0,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$1F,$0E,$01,$07,$07,$07
        .byte   $03,$00,$3F,$1F,$0E,$0C,$0E,$0F
        .byte   $0F,$0F,$00,$40,$E0,$E0,$E0,$C0
        .byte   $00,$40,$C0,$A0,$00,$00,$00,$A0
        .byte   $E0,$A0,$F8,$F8,$F8,$F8,$FC,$7C
        .byte   $7E,$7F,$F8,$F8,$F8,$F8,$FC,$7C
        .byte   $7E,$7F,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$01,$03,$02,$02,$03
        .byte   $01,$01,$00,$00,$00,$01,$01,$00
        .byte   $00,$00,$9C,$DC,$7C,$7C,$7D,$7D
        .byte   $3D,$BD,$03,$03,$83,$83,$82,$82
        .byte   $C2,$42,$3F,$7F,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$C0,$80,$00,$00,$00,$00
        .byte   $00,$00,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$87,$87,$87,$87,$83,$03
        .byte   $01,$00,$1F,$1F,$1F,$1F,$1F,$1F
        .byte   $1F,$3F,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$8F,$C3,$F1,$F0,$F8,$FC
        .byte   $FE,$FF,$C0,$F0,$FC,$FE,$FE,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$7F,$3F
        .byte   $1F,$1F,$00,$00,$00,$00,$00,$00
        .byte   $80,$C0,$E0,$E0,$F0,$F0,$F0,$F0
        .byte   $F0,$F0,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$07,$0F,$0F,$07,$20,$38
        .byte   $7E,$3C,$0C,$1C
        asl     $7F3F,x
        .byte   $77,$F0,$FA,$C0,$C0,$80,$00,$00
        .byte   $00,$00,$00,$00,$00,$40,$80,$80
        .byte   $00,$00,$00,$3F,$3F,$1F,$0F,$07
        .byte   $03,$00,$00,$3F,$3F,$1F,$0F,$07
        .byte   $03,$00,$00,$00,$80,$80,$80,$80
        .byte   $81,$86,$0C,$00,$8C,$8F,$9F,$9F
        .byte   $BF,$BE,$3C,$00,$00,$00,$03,$3C
        .byte   $C0,$00,$00,$00,$03,$0F,$FF,$FC
        cpy     #$00
        brk
        .byte   $00,$01,$01,$F1,$00,$00,$00,$00
        .byte   $E0,$F0,$F0,$F8,$08,$08,$0C,$0E
        .byte   $FF,$7F,$FF,$FF,$FF,$FF,$7F,$3F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FE,$FE,$FE,$FC,$FC,$F8,$F8,$F0
        .byte   $00,$00,$00,$00,$00,$00,$00,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$01
        .byte   $3F,$3F,$7F,$7F,$7F,$FF,$FF,$FF
        .byte   $1F,$01,$01,$3C,$0E,$E7,$31,$85
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FC,$E0,$7C,$FE,$FF,$FE
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $0F,$87,$07,$03,$03
LB805:  sta     ($81,x)
        ora     ($C0,x)
        cpx     #$F0
        beq     LB805
        sed
        sed
        .byte   $FC,$F0,$F0,$F0,$F0,$F0,$E0,$E0
        .byte   $E0,$07,$07,$07,$07,$07,$0F,$0F
        .byte   $0F,$00,$00,$00,$31,$36,$76,$71
        .byte   $17,$00,$FF,$FF,$71,$76,$76,$71
        .byte   $17,$00,$00,$00,$DF,$84,$D7,$D7
        .byte   $D4,$FF,$FF,$F3,$DF
        sty     $D7
        .byte   $D7,$D4,$00,$00,$00,$C0,$20,$B0
        .byte   $78,$B8,$C0,$E0,$F0,$F0,$38,$B8
        .byte   $7C,$BC,$0C,$18,$18,$18,$18,$18
        .byte   $18,$18,$7C,$78,$78,$F8,$F8,$F8
        .byte   $F8,$F8,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$0F,$0F,$0F,$07,$07,$07
        .byte   $07,$03,$1F,$0F,$03,$00,$00,$00
        .byte   $00,$00,$00,$00,$80
LB88B:  cpy     #$E0
        beq     LB88B
        .byte   $FF,$FF,$FF,$FF,$7E,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$E0,$C0,$80,$00,$03,$7F,$7F
        .byte   $7F,$01,$03,$07,$0F,$3F,$7F,$7F
        .byte   $7F,$00,$00,$00,$01,$03,$01,$00
        .byte   $80,$F3,$E0,$E0,$C0,$C0,$80,$80
        cpx     #$FC
        ror     $010F,x
        cpy     #$F0
        .byte   $7C,$1E,$FF,$FF,$7F,$1F,$07,$01
        .byte   $00,$00,$F0,$00,$80,$FC,$8A,$00
        .byte   $00,$20,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $7F,$3F,$01,$01,$01,$01,$01,$03
        .byte   $02,$04,$FC,$FC,$FC,$F8,$F8,$F0
        .byte   $F0,$E0,$C1,$C1,$C3,$83,$07,$0F
        .byte   $1F,$3F,$1F,$1E,$1C,$3C,$78,$FF
        .byte   $F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$00,$00,$00,$FF
        .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$00,$00,$00,$FF
        .byte   $00,$FF,$F8,$F8,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FE,$0E,$06,$07,$07,$FF
        .byte   $07,$FF,$18,$0C,$0C,$06,$06,$03
        .byte   $01,$00,$F8,$FC,$FC,$FE,$7E,$7F
        .byte   $3F,$3F,$00,$00,$00,$00,$00,$00
        .byte   $80,$FF,$00,$00,$00,$00,$00,$00
        .byte   $80,$FF,$00,$00,$00,$00,$01,$07
        .byte   $7F,$F8,$03,$03,$01,$00
        ora     ($07,x)
        .byte   $7F,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FC,$F0,$00,$00,$00,$03,$07,$0F
        .byte   $1F,$3F,$F8,$F8,$F0,$E0,$80,$00
        .byte   $00,$00,$3F,$1F,$0F,$03,$80,$C0
        .byte   $E0,$E8,$3F,$1F,$0F,$03,$00,$00
        .byte   $00,$08,$C8,$F6,$F7,$F9,$FC,$00
        .byte   $00,$00,$F8,$FE,$FF,$FF,$FF,$3F
        .byte   $03,$00,$06,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$80,$F0,$FF,$FF
        .byte   $FE,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$3F,$7F,$7F,$FF,$FC,$E0
        .byte   $00,$01,$00,$00,$01,$07,$0F,$1F
        .byte   $3F,$FF,$E1,$C3,$87,$0F,$1F,$3F
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FC,$F8,$F8,$F8,$F8,$F0
        .byte   $E0,$80,$FF,$0F,$FF,$FF,$FF,$FF
        .byte   $FE,$FE,$00,$00,$00,$00,$00,$01
        .byte   $00,$00,$1F,$0F,$07,$01,$00,$00
        .byte   $00,$00,$7F,$00,$00,$00,$00,$C0
        .byte   $FF,$00,$FF,$FF,$FF,$FF,$00,$00
        .byte   $00,$00,$80,$00,$00,$00,$01,$0F
        .byte   $FF,$00,$FF,$FE,$F0,$00,$00,$00
        .byte   $00,$00,$00,$01,$07,$3F,$FF,$FF
        .byte   $FF,$00,$C0,$00,$00,$00,$00,$00
        .byte   $00,$00,$FF,$FF,$FF,$FE,$FC,$F8
        .byte   $F0,$00,$00,$00,$00,$00,$00,$00
        .byte   $02,$00,$C0,$90,$00,$18,$C0,$1A
        .byte   $00,$00,$02,$10,$01,$00
        cpy     #$02
        .byte   $80,$00,$00,$00,$10,$00
        and     $3802,y
        brk
        .byte   $0C,$00,$7A,$00,$29,$82,$A9,$00
        .byte   $00,$00,$98,$90,$00
        bmi     LBA87
        brk
        .byte   $00,$00,$C6,$CA,$80,$0C,$94,$00
        .byte   $00,$1F,$1F,$00,$00,$00,$00,$00
        .byte   $07,$1F,$1F,$3F,$3F,$7F,$FF,$00
        .byte   $00,$FF,$FF,$00,$00,$00,$00
LBA87:  .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$FF,$FF,$00,$00,$00,$01
        .byte   $07,$FF,$FF,$FF,$FF,$FC,$F1,$C7
        .byte   $3F,$01,$DC,$9F,$3F,$77,$E7,$FF
        .byte   $FF,$E1,$DC,$BF,$7F,$E7,$E7,$FF
        .byte   $FF,$00,$00,$80,$E0,$B8,$3C,$FE
        .byte   $FF,$FE,$7C,$9C,$E0,$38
LBABD:  .byte   $3C,$FE,$FF,$00,$00,$7F,$00,$0F
        .byte   $08,$08,$08,$7F,$FF,$FF,$7F,$3F
        .byte   $1E,$1E,$1E,$00,$00,$FF,$00,$FF
        .byte   $61,$61,$61,$FF,$FF,$FF,$FF,$FF
        .byte   $79,$79,$79,$00,$00,$FF,$00,$FF
        .byte   $86,$86,$86,$FF,$FF,$FF,$FF,$FF
        .byte   $E7,$E7,$E7,$00,$00,$FF,$00,$FF
        .byte   $18,$18,$18,$FF,$FF,$FF,$FF,$FF
        .byte   $9E,$9E,$9E,$00,$00,$80,$00,$F0
        .byte   $78,$78,$78,$FF,$FF,$FF,$FF,$FF
        .byte   $7F,$7F,$7F,$00,$00,$FF,$FF,$FF
        .byte   $E7,$F3,$E3,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$E7,$E7,$00,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$00,$FF,$FF,$FF
        .byte   $E7,$F3,$E3,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$E7,$E7,$1E,$70,$C1,$8F,$3F
        .byte   $7F,$3F,$0F,$FE,$F1,$CF,$BF,$7E
        .byte   $7F,$7F,$3F,$00,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$FF,$FF,$01,$03
        .byte   $FF,$FF,$FF,$00,$00,$FE,$FE,$FF
        .byte   $FF,$FF,$FF,$00,$FE,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$00,$78,$7C,$3E
        .byte   $3E,$3F,$3F,$00,$F8,$04,$02,$81
        .byte   $81,$80,$80,$0F,$0F,$00,$00,$1F
        .byte   $3F,$00,$7F,$1F,$1F,$1F,$00,$3F
        .byte   $7F,$7F,$FF,$FF,$FF,$00,$00,$FF
        .byte   $FF,$1F,$81,$FF,$FF,$FF,$00,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$00,$FF
        .byte   $FF,$E0,$CF,$FF,$FF,$FF,$00,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$00,$FF
        .byte   $FF,$00,$FC,$FF,$FF
LBBBA:  .byte   $FF,$00,$FF,$FF,$FF,$FF,$F8,$F8
        .byte   $00,$00,$FF,$E0,$00,$00,$FF,$FF
        .byte   $FF,$07,$FF,$FF,$FF,$FF,$E7,$FF
        .byte   $FF,$00,$FF,$00,$00,$00,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$00,$FF,$00,$00,$00,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$E7,$FF
        .byte   $FF,$00,$FF,$00,$00,$00,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$01,$00
        .byte   $00,$00,$C0,$00,$00,$00,$4F,$31
        .byte   $8E,$C1,$F0,$FE,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $00,$FF,$00,$00,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $00,$FF,$00,$00,$FF,$FF,$3E,$00
        .byte   $7C,$00,$01,$03,$0F,$07,$81,$BF
        .byte   $03,$7E,$FD,$03,$FF,$FF,$80,$80
        .byte   $C0
        cpy     #$C0
        cpx     #$E0
        cpx     #$80
        .byte   $80,$C0,$C0,$C0,$E0,$E0,$E0,$7F
        .byte   $67,$73,$73,$43,$67,$7F,$7F,$FF
        .byte   $FF,$C7,$C7,$C7,$FF,$FF,$FF,$00
        .byte   $00,$04,$0E,$0E,$04,$00,$80,$C3
        .byte   $81,$00,$00,$00,$00,$81,$C3,$DF
        .byte   $5C,$5E,$5E,$78,$7C,$7F,$FF,$FF
        .byte   $FF,$F8,$F8,$F8,$FF,$FF,$FF,$FC
        .byte   $FC,$7C,$7C,$7C,$FC,$FC,$FC,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$03,$07,$02,$01,$00,$00
        .byte   $00,$00,$00,$00,$0C,$0C,$1B,$00
        .byte   $3F,$F0,$8F,$7F,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$06,$00
        .byte   $E0,$18,$C6,$E1,$F8,$FC,$F8,$00
        .byte   $00,$00,$00,$05,$85,$80,$45,$00
        .byte   $00,$00,$00,$05,$05,$00,$05,$03
        .byte   $01,$00,$00,$00,$80,$80,$40,$03
        .byte   $01,$00,$00,$00,$00,$00,$00,$E0
        .byte   $F0,$F0,$70,$38,$38,$18,$18,$E0
        .byte   $F0,$F0,$70,$38,$38,$18,$18,$7F
        ora     (zp_temp_00,x)
        brk
        brk
        brk
        brk
        .byte   $00,$FF,$FF,$7F,$03,$01,$01,$01
        .byte   $01,$C1,$FF,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$FF,$C0,$C0,$80,$80
        .byte   $80,$FC,$00,$00,$00,$00,$00,$00
        .byte   $00,$FE,$FE,$FC,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$37
        .byte   $37,$1B,$37,$37,$37,$37,$37,$00
        .byte   $00,$7F,$38,$13,$06,$04,$05,$ED
        .byte   $EC,$80,$C0,$E0,$F0
        inx
        sbc     #$01
        brk
        .byte   $0E,$1F,$0F,$27,$17,$97,$80,$00
        .byte   $F0,$00
        cpy     #$00
        brk
        .byte   $80,$97,$17,$40,$25,$20,$20,$20
        .byte   $20,$00,$00,$00,$05,$00,$00,$00
        .byte   $00,$20,$20,$40,$20,$20,$20,$21
        .byte   $21,$01,$01,$00,$01,$01,$01,$00
        .byte   $00,$20,$20,$18,$18,$18,$18,$90
        .byte   $90,$90,$80,$18,$18,$98,$98,$10
        .byte   $10,$10,$00,$40,$2A,$7F,$7F,$00
        .byte   $00,$00,$3F,$00,$00,$00,$00,$7F
        .byte   $3F,$3F,$00,$FE,$FE,$7E,$7E,$7E
        .byte   $7E,$7E,$BE,$FE,$FE
LBDCA:  ror     $7E7E,x
        ror     $3E7E,x
        rol     a
        .byte   $3F,$3F,$3F,$00,$00,$00,$1F,$00
        .byte   $00,$00,$00,$3F,$3F,$3F,$00,$AA
        .byte   $FF,$FF,$FF,$00,$00,$00,$FF,$00
        .byte   $00,$00,$00,$FF,$FF,$FF,$00,$A0
        .byte   $E0,$E0,$E0,$0C,$0C,$0E,$EC,$0C
        .byte   $0C,$0C,$0C,$E0,$E0,$E0,$02,$37
        .byte   $37,$37,$1B,$1B,$0D,$0E,$04,$00
        .byte   $00,$00,$00,$00,$00,$00,$03,$F2
        .byte   $F1,$E0,$C0,$80,$00,$00,$00,$04
        .byte   $02,$18,$3F,$7F,$FF,$FF,$7F,$20
        .byte   $C0,$10,$F8,$FC,$FC,$F9,$E1,$07
        .byte   $0F,$0F,$06,$02,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$20
        .byte   $20,$20,$40,$40,$80,$80,$00,$00
        .byte   $00,$00,$00,$01,$01,$01,$00,$21
        .byte   $21,$21,$41,$40,$80,$80,$01,$00
        .byte   $00,$00,$00,$80,$80,$80,$00,$80
        .byte   $80,$80,$80,$00,$00,$00,$00,$1F
        .byte   $1F,$00,$00,$00,$01,$00,$00,$00
        .byte   $00,$0F,$07,$03,$00,$00,$00,$BF
        .byte   $DF,$1F,$0F,$07,$FB,$7C,$1F,$3F
        .byte   $1F,$DF,$EF,$F7,$03,$00,$00,$1F
        .byte   $1F,$00,$80,$80,$C3,$F1,$00,$00
        .byte   $00,$0F,$8F,$87,$C0,$F0,$00,$FF
        .byte   $FF,$00,$00,$00,$FF,$FF,$FF,$00
        .byte   $00,$FF,$FF,$FF,$00,$00,$00,$F0
        .byte   $F0,$00,$03,$01,$FE,$FF,$FF,$06
        .byte   $06,$F3,$F8,$FC,$00,$00,$00,$00
        .byte   $00,$00,$80,$80,$80,$0F,$DF,$03
        .byte   $00,$00,$00,$40,$70,$30,$00,$00
        .byte   $00,$00,$00,$00,$00,$0F,$0F,$8F
        .byte   $F0,$3F,$00,$00,$00,$F0,$F0
        dec     $18
        cpx     #$00
        brk
        .byte   $00,$0F,$0F,$00,$00,$00,$00,$00
        .byte   $00,$F0,$F0,$00,$88,$00,$00,$00
        .byte   $00,$0F,$0F,$00,$88,$00,$00,$00
        .byte   $00,$F0
        beq     LBEF1
LBEF1:  .byte   $80,$00,$00,$00,$00,$0F,$0F,$03
        .byte   $80,$00,$00,$00,$00,$F0
        beq     LBF01
LBF01:  brk
        .byte   $00,$0E,$1C,$08,$00,$00,$03,$03
        asl     zp_temp_00
        brk
        .byte   $30,$F0,$C0,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00
LBFBE:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$78,$EE,$E1,$BF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$00,$00,$E0,$BF
        .byte   $E0,$BF
