.segment "BANK0D"

; =============================================================================
; Bank $0D — Stage Engine
; Stage initialization, main stage loop, player rendering & collision,
; OAM sprite management, entity update/physics, and stage transitions.
; =============================================================================

; da65 V2.18 - Ubuntu 2.19-1
; Created:    2026-02-23 18:17:35
; Input file: build/bank0D.bin
; Page:       1


        .setcpu "6502"

zp_temp_06           := $0006
L0010           := $0010
L0320           := $0320
L0508           := $0508
L0901           := $0901
L0D20           := $0D20
L0F06           := $0F06
L1003           := $1003
L1120           := $1120
L1121           := $1121
L1EA4           := $1EA4
L2008           := $2008
L2017           := $2017
L2020           := $2020
L2060           := $2060
L3800           := $3800
L5000           := $5000
L5E10           := $5E10
L72A0           := $72A0
L7484           := $7484
bank_switch_enqueue           := $C051
LC05D           := $C05D
LC0AB           := $C0AB
LC628           := $C628
LC644           := $C644
LC70C           := $C70C
LC723           := $C723
LC747           := $C747
LC760           := $C760
LC84E           := $C84E
LC8B1           := $C8B1
LCA0B           := $CA0B
LCC6C           := $CC6C
LD001           := $D001
ppu_buffer_transfer           := $D11B
ppu_scroll_column_update           := $D1DF
fixed_D2ED           := $D2ED
fixed_D2EF           := $D2EF
LD624           := $D624
LD627           := $D627
LD637           := $D637
LD642           := $D642
LD64D           := $D64D
        .byte   $4C,$15,$80,$4C,$EC,$90,$4C,$78
        .byte   $96,$4C,$E7,$9E,$4C,$01,$B1,$4C
        .byte   $F1,$B6,$4C,$E0,$BA
        lda     #$10
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001
        jsr     reset_scroll_state
        jsr     load_stage_nametable
        ldx     #$00
        lda     $9A
        sta     $01
L802F:  stx     $00
        lsr     $01
        bcc     L8061
        lda     L8531,x
        sta     $09
        lda     L8539,x
        sta     $08
        ldx     #$04
        lda     #$00
L8043:  lda     $09
        sta     $2006
        lda     $08
        sta     $2006
        ldy     #$04
        lda     #$00
L8051:  sta     $2007
        dey
        bne     L8051
        clc
        lda     $08
        adc     #$20
        sta     $08
        dex
        bne     L8043
L8061:  ldx     $00
        inx
        cpx     #$08
        bne     L802F
        ldx     #$1F
        jsr     load_scroll_palette
        jsr     clear_oam_buffer
        ldx     #$00
        lda     $9A
        sta     $02
        ldy     #$00
L8078:  stx     $01
        lsr     $02
        bcs     L8093
        lda     L8605,x
        sta     $00
        lda     L85FD,x
        tax
L8087:  lda     L8541,x
        sta     $0200,y
        iny
        inx
        dec     $00
        bne     L8087
L8093:  ldx     $01
        inx
        cpx     #$08
        bne     L8078
        jsr     LA51D
        lda     #$0C
        jsr     bank_switch_enqueue
        lda     #$00
        sta     $2A
        sta     $FD
        jsr     LC0AB

; =============================================================================
; Stage Main Loop
; Per-frame update: render player, check pause, sync PPU.
; =============================================================================
stage_main_loop:  lda     $27           ; Main stage loop (called each frame)
        and     #$08
        bne     stage_paused_handler
        lda     $27
        and     #$F0
        beq     L80BF
        lda     #$2F
        jsr     bank_switch_enqueue
        jsr     L82AB
L80BF:  jsr     player_render_collision
        jsr     LC0AB
        jmp     stage_main_loop

stage_paused_handler:  ldx     $2A
        bne     stage_select_handler
        lda     $9A
        cmp     #$FF
        bne     L80BF
        lda     #$08
        sta     $2A
        jmp     L829A

stage_select_handler:  ldy     L865F,x
        lda     $9A
        and     L86D1,y
        bne     L80BF
        sty     $2A
        lda     #$3A
        jsr     bank_switch_enqueue
        lda     $2A
        asl     a
        sta     $00
        asl     a
        adc     $00
        tax
        ldy     #$00
L80F5:  lda     L8671,x
        sta     $0460,y
        lda     L86A1,x
        sta     $0440,y
        lda     #$00
        sta     $0480,y
        inx
        iny
        cpy     #$06
        bne     L80F5
        lda     #$0A
        sta     $04A0
        lda     #$00
        sta     $04C0
        sta     $0680
        lda     #$30
        sta     $FD
L811D:  ldx     #$3F
        lda     $FD
        and     #$04
        bne     L8127
        ldx     #$1F
L8127:  jsr     load_scroll_palette
        ldx     $0680
        clc
        lda     $0480,x
        sta     $08
        adc     #$20
        sta     $0480,x
        php
        lda     $0460,x
        sta     $09
        adc     #$00
        sta     $0460,x
        plp
        bne     L8149
        inc     $0680
L8149:  lda     $0440,x
        jsr     LC70C
        clc
        lda     $04C0
        sta     $03B7
        adc     #$20
        sta     $04C0
        lda     $04A0
        sta     $03B6
        adc     #$00
        sta     $04A0
        dec     $FD
        beq     L8170
        jsr     LC0AB
        jmp     L811D

L8170:  ldx     #$1F
        jsr     load_scroll_palette
        lda     #$2C
        sta     $0358
        lda     #$11
        sta     $0359
        ldy     #$07
L8181:  lda     L84D9,y
        sta     $0366,y
        dey
        bpl     L8181
        lda     $2A
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
L8192:  lda     L84E1,x
        sta     $036E,y
        inx
        iny
        cpy     #$08
        bne     L8192
        lda     #$01
        sta     $20
        jsr     LC723
        lda     #$18
        sta     $FD
        lda     #$0A
        jsr     bank_switch_enqueue
L81AE:  jsr     clear_oam_buffer
        jsr     LC0AB
        dec     $FD
        bne     L81AE
        jsr     L8465
        lda     #$80
        sta     $0460
        lda     #$20
        sta     $04A0
        lda     #$00
        sta     $0680
        sta     $06A0
L81CD:  lda     #$00
        sta     $0680
        clc
        lda     $04A0
        adc     #$08
        sta     $04A0
        cmp     #$78
        beq     L81EE
        jsr     clear_oam_buffer
        jsr     update_projectile_anim
        jsr     render_player_sprites
        jsr     LC0AB
        jmp     L81CD

L81EE:  inc     $06A0
        lda     $23
        and     #$01
        sta     $0420
        lda     #$00
        sta     $FD
        lda     #$08
        sta     $FE
L8200:  lda     #$00
        sta     $0680
        dec     $FE
        bne     L8223
        lda     #$08
        sta     $FE
        ldx     $FD
        lda     L8521,x
        sta     $0368
        lda     L8522,x
        sta     $0369
        inx
        inx
        cpx     #$10
        beq     L8232
        stx     $FD
L8223:  jsr     clear_oam_buffer
        jsr     update_projectile_anim
        jsr     render_player_sprites
        jsr     LC0AB
        jmp     L8200

L8232:  lda     #$50
        sta     $FD
L8236:  jsr     clear_oam_buffer
        jsr     update_projectile_anim
        jsr     render_player_sprites
        jsr     LC0AB
        dec     $FD
        bne     L8236
        lda     #$28
        sta     $FD
        lda     #$26
        sta     $03B6
        lda     #$0A
        sta     $03B7
        lda     $2A
        asl     a
        sta     $FE
        asl     a
        asl     a
        adc     $FE
        sta     $FE
L825F:  lda     $FD
        and     #$03
        bne     L8276
        ldx     $FE
        lda     L86D9,x
        sta     $03B8
        lda     #$01
        sta     $47
        inc     $FE
        inc     $03B7
L8276:  jsr     clear_oam_buffer
        jsr     update_projectile_anim
        jsr     render_player_sprites
        jsr     LC0AB
        dec     $FD
        bne     L825F
        lda     #$BB
        sta     $FD
L828A:  jsr     clear_oam_buffer
        jsr     update_projectile_anim
        jsr     render_player_sprites
        jsr     LC0AB
        dec     $FD
        bne     L828A
L829A:  jsr     LA52D
        rts

load_scroll_palette:  ldy     #$1F
L82A0:  lda     stage_palette_data,x
        sta     $0356,y
        dex
        dey
        bpl     L82A0
        rts

L82AB:  lda     $27
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        beq     L82C9
        cmp     #$09
        bcs     L82C9
        sta     $00
        dec     $00
        lda     $2A
        asl     a
        asl     a
        asl     a
        clc
        adc     $00
        tax
        lda     L82CA,x
        sta     $2A
L82C9:  rts

L82CA:  .byte   $02,$06,$00,$08,$00,$00,$00,$04
        .byte   $01,$08,$01,$01,$01,$01,$01,$02
        .byte   $02,$00,$02,$01,$02,$02,$02,$03
        .byte   $03,$04,$03,$02,$03,$03,$03,$03
        .byte   $03,$05,$04,$00,$04,$04,$04,$04
        .byte   $04,$05,$05,$06,$05,$05,$05,$05
        .byte   $00,$06,$06,$07,$06,$06,$06,$05
        .byte   $08,$07,$07,$07,$07,$07,$07,$06
        .byte   $01,$07,$08,$08,$08,$08,$08,$00

; =============================================================================
; Player Rendering & Collision
; =============================================================================
player_render_collision:  lda     $1C
        and     #$08
        bne     L834D
        ldy     $2A
        lda     collision_x_offset_table,y
        sta     $09
        lda     collision_y_offset_table,y
        sta     $08
        ldx     #$00
L8326:  clc
        lda     collision_box_table,x
        adc     $09
        sta     $02E0,x
        inx
        lda     collision_box_table,x
        sta     $02E0,x
        inx
        lda     collision_box_table,x
        sta     $02E0,x
        inx
        clc
        lda     collision_box_table,x
        adc     $08
        sta     $02E0,x
        inx
        cpx     #$10
        bne     L8326
        rts

L834D:  lda     #$F8
        ldx     #$0F
L8351:  sta     $02E0,x
        dex
        bpl     L8351
        rts

render_player_sprites:  ldy     #$50
        ldx     #$00
        lda     #$30
        sta     $00
        lda     #$02
        sta     $03
L8364:  sty     $04
        stx     $05
        lda     $0420
        beq     L8379
        lda     #$80
        sta     $00
        lda     $1C
        and     #$04
        bne     L8379
        inc     $00
L8379:  ldx     $03
        lda     L83A3,x
        sta     $01
        clc
        lda     $0481,x
        adc     L83A6,x
        sta     $0481,x
        lda     $0461,x
        adc     L83A9,x
        sta     $0461,x
        sta     $02
        ldx     $05
        ldy     $04
        jsr     write_sprite_to_oam
        inc     $00
        dec     $03
        bpl     L8364
        rts

L83A3:  .byte   $07,$0D,$15
L83A6:  .byte   $00,$47,$41
L83A9:  .byte   $04,$01,$00
write_sprite_to_oam:  lda     L8729,x
        sta     $0200,y
        iny
        lda     $00
        sta     $0200,y
        iny
        lda     $0420
        beq     L83C0
        lda     #$40
L83C0:  sta     $0200,y
        iny
        clc
        lda     L872A,x
        adc     $02
        sta     $0200,y
        iny
        inx
        inx
        dec     $01
        bne     write_sprite_to_oam
        rts

update_projectile_anim:  ldx     $2A
        inc     $0680
        lda     $0680
        cmp     L8791,x
        bcc     L83F5
        lda     #$00
        sta     $0680
        inc     $06A0
        lda     L8789,x
        cmp     $06A0
        bcs     L83F5
        sta     $06A0
L83F5:  lda     L8781,x
        clc
        adc     $06A0
        tax
        ldy     L8799,x
        lda     L87ED,y
        sta     $08
        lda     L8816,y
        sta     $09
        ldy     #$00
        lda     ($08),y
        sta     $00
        iny
        ldx     #$00
L8413:  clc
        lda     $04A0
        adc     ($08),y
        sta     $0200,x
        iny
        inx
        lda     ($08),y
        sta     $0200,x
        iny
        inx
        lda     ($08),y
        sta     $0200,x
        iny
        inx
        clc
        lda     $0460
        adc     ($08),y
        sta     $0200,x
        inx
        iny
        dec     $00
        bne     L8413
        rts

load_stage_nametable:  lda     #$00
        jsr     LC644
        lda     #$20
        sta     $2006
        ldy     #$00
        sty     $2006
        lda     #$AE
        sta     $09
        lda     #$0B
        jsr     LC628
        ldy     #$1F
L8456:  lda     nametable_fill_table,y
        ldx     #$20
L845B:  sta     $2007
        dex
        bne     L845B
        dey
        bpl     L8456
        rts

L8465:  ldx     #$02
        lda     #$00
L8469:  sta     $0461,x
        sta     $0481,x
        dex
        bpl     L8469
        rts


; =============================================================================
; OAM Buffer Management
; =============================================================================
clear_oam_buffer:  ldx     #$00         ; Fill OAM with $F8 (sprites off-screen)
        lda     #$F8
L8477:  sta     $0200,x
        inx
        bne     L8477
        rts

reset_scroll_state:  lda     #$00
        sta     $1F
        sta     $20
        sta     $22
        sta     $21
        sta     $B5
        sta     $B6
        sta     $B7
        sta     $B8
        sta     $B9
        sta     $0354
        sta     $0355
        rts

stage_palette_data:  .byte   $0F,$20,$11,$2C,$0F,$20,$29,$19
        .byte   $0F,$19,$37,$17,$0F,$28,$15,$05
        .byte   $0F,$30,$36,$26,$0F,$0F,$28,$05
        .byte   $0F,$30,$38,$26,$0F,$0F,$36,$26
        .byte   $20,$30,$10,$20,$0F,$30,$20,$10
        .byte   $0F,$10,$20,$10,$0F,$30,$20,$10
        .byte   $20,$30,$20,$10,$0F,$30,$20,$10
        .byte   $0F,$30,$20,$10,$0F,$30,$20,$10
L84D9:  .byte   $0F,$0F,$0F,$0F,$0F,$0F,$30,$38
L84E1:  .byte   $0F,$0F,$28
        ora     $0F,x
        .byte   $0F,$28
        ora     $0F,x
        .byte   $0F,$28
        ora     ($0F),y
        .byte   $0F,$28
        ora     ($0F),y
        .byte   $0F,$30
        and     #$0F
        .byte   $0F,$36,$17,$0F,$0F,$30,$19,$0F
        .byte   $0F,$30
        ora     $0F0F,y
        bmi     L852D
        .byte   $0F,$0F
        plp
        ora     $0F,x
        bmi     L853C
        plp
        .byte   $0F,$0F,$30,$12,$0F,$0F,$30,$15
        .byte   $0F,$0F,$28
        ora     $0F,x
        .byte   $0F,$30
        bmi     L852D
        .byte   $0F
        bmi     L8537
L8521:  brk
L8522:  brk
        .byte   $07,$10,$17,$20,$17,$20,$17
        jsr     L2017
L852D:  .byte   $17,$20,$17
        .byte   $20
L8531:  and     ($20,x)
        and     ($20,x)
        .byte   $20
        .byte   $22
L8537:  .byte   $22
        .byte   $22
L8539:  .byte   $86,$8E,$96
L853C:  stx     $96
        stx     L9686
L8541:  and     #$0A
        ora     ($31,x)
        plp
        .byte   $0B,$00,$3D,$28,$0C,$00,$45
        rol     $27
        .byte   $02
        sei
        rol     $0125
        ror     $2E,x
        rol     $01
        ror     $2336,x
        ora     ($70,x)
        rol     $24,x
        ora     ($83,x)
        .byte   $17,$2E,$01,$C8,$26,$28,$00
        cpy     #$2E
        and     #$00
        bcs     L859C
        rol     a
        brk
        .byte   $B8,$2E,$2B,$00,$C0,$36,$2C,$00
        .byte   $B8,$36,$2D,$00,$C0
        jmp     (zp_temp_06)

        .byte   $3B,$6C,$07,$00,$43,$74
        php
        brk
        .byte   $3B,$74
        ora     #$00
        .byte   $43,$5F
        ora     LB000
        .byte   $5F,$0E,$00,$B8,$5F,$0F,$00,$C0
        .byte   $67
        bpl     L859C
L859C:  bcs     L8605
        ora     ($00),y
        clv
        .byte   $67,$12,$00,$C0,$6F,$13,$00,$B7
        .byte   $6F,$14,$00,$BF,$77
        ora     $00,x
        .byte   $B7,$77,$16,$00,$BF,$9F,$1F,$00
        .byte   $38,$A7
        jsr     L3800
        .byte   $AF,$21,$00,$3B,$AF,$22,$00,$43
        .byte   $A7,$17,$01,$71,$A7,$18,$00,$79
        .byte   $A7,$19,$02,$81,$AF,$1A,$01,$71
        .byte   $AF,$1B,$00,$79,$AF
L85DA:  .byte   $1C,$00
L85DC:  sta     ($B7,x)
        ora     $7900,x
        .byte   $B7,$1E,$00,$81,$9D,$04,$00,$C0
        .byte   $A5
L85EA:  ora     $00
L85EC:  cpy     #$AD
        brk
        .byte   $00
        ldx     $AD,y
        ora     ($00,x)
        ldx     $02B5,y
        brk
        .byte   $B6,$B5,$03,$00,$BE
L85FD:  .byte   $3C,$0C,$4C
        brk
        jsr     L7484
        .byte   $A4
L8605:  bpl     L861B
        plp
        .byte   $0C,$1C,$20,$10,$18
collision_box_table:  .byte   $F8,$2F,$00,$F9,$F8,$2F,$00,$1F
        .byte   $1E,$2F,$00,$F9,$1E,$2F
L861B:  .byte   $00,$1F
collision_x_offset_table:  .byte   $60,$20,$20,$20,$60
        ldy     #$A0
        ldy     #$60
collision_y_offset_table:  bvs     L8658
        bvs     L85DA
        bcs     L85DC
        bvs     L865E
        bmi     L8690
        jsr     L2060
        jsr     LA0A0
        ldy     #$30
        bvs     L85EA
        bmi     L85EC
        bvs     L866E
        .byte   $B0
nametable_fill_table:  brk
        brk
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$2D,$20,$20,$20
        .byte   $20,$20,$20,$2C,$00,$00,$00
L8658:  .byte   $00,$00,$00,$00,$00,$00
L865E:  brk
L865F:  php
        .byte   $03,$01,$04,$02,$07,$05,$06,$00
        .byte   $00,$08,$02,$10,$04,$20
L866E:  .byte   $80,$40,$01
L8671:  tya
        sta     L9B9A,y
        .byte   $9C,$9D,$AB,$AC,$AD,$AA,$AB,$AC
        .byte   $AC,$AD,$AE,$AF,$B0,$B1,$98,$99
        .byte   $9A,$9B,$9C,$9D,$90,$91,$92,$93
        .byte   $94
        sta     $9E,x
L8690:  .byte   $9F,$96,$97,$9E,$9F,$B0,$B1,$B2
        .byte   $B3,$AA,$AB,$AE,$AF,$B0,$B1,$B2
        .byte   $B3
L86A1:  .byte   $06,$06,$06,$06,$06,$06,$05,$05
        .byte   $05,$06,$06,$06
        asl     zp_temp_06
        asl     zp_temp_06
        asl     zp_temp_06
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$06,$06,$07,$07
        .byte   $07,$07,$03,$03,$03,$03,$05,$05
        .byte   $05,$05,$05,$05,$05,$05
L86D1:  .byte   $01,$02,$04,$08
        bpl     L86F7
        rti

        .byte   $80
L86D9:  jsr     L0508
        ora     ($14,x)
        .byte   $0D
        .byte   $01
L86E0:  asl     L2020
        jsr     $0120
        ora     #$12
        ora     $0E01
        jsr     L2020
        .byte   $17,$0F,$0F,$04,$0D,$01,$0E,$20
        .byte   $20
L86F7:  .byte   $02,$15,$02,$02,$0C
L86FC:  ora     $0D
        ora     ($0E,x)
        jsr     L1120
        ora     $09,x
        .byte   $03
        .byte   $0B,$0D,$01,$0E,$20,$20,$06,$0C
        .byte   $01,$13,$08,$0D,$01,$0E
        jsr     L0D20
        ora     $14
        ora     ($0C,x)
        ora     $0E01
        jsr     L0320
        .byte   $12,$01,$13,$08,$0D,$01,$0E,$20
L8729:  .byte   $10
L872A:  .byte   $18,$10,$80,$10,$D0,$14,$40
L8731:  clc
        bcc     L875C
        sei
        bmi     L8757
        bmi     L8731
        sec
        bcs     L877C
        inx
        tya
        bcc     L86E0
        rti

        .byte   $A0,$E8,$B0,$90,$B8,$68,$C0,$18
        .byte   $C8,$70,$C8,$C0,$D0,$D8,$D8,$60
        .byte   $D8,$C8,$18,$50,$08,$50
L8757:  clc
        sed
        jsr     L2008
L875C:  tay
        bmi     L879F
        sec
        bne     L87AA
        bvc     L86FC
        clv
        tay
        sei
        bcs     L8769
L8769:  clv
        plp
        cpy     #$C8
        bne     L878F
        cpx     #$88
        bit     $D0
        .byte   $34,$88,$3C,$30,$9C,$20,$A4,$D0
        .byte   $B4
L877C:  .byte   $58,$D4,$E8,$D4,$A0
L8781:  .byte   $00,$18,$29,$32,$37,$41,$49,$4F
L8789:  .byte   $17,$10,$08,$04,$09,$07
L878F:  ora     $04
L8791:  .byte   $02,$03,$08
        php
        ora     zp_temp_06
        php
        php
L8799:  .byte   $03,$02,$02,$01,$01,$00
L879F:  .byte   $27,$28,$27,$28,$27,$28,$27,$28
        .byte   $27,$28,$27
L87AA:  .byte   $28,$27,$28,$27,$28,$27,$00,$1E
        .byte   $1B,$1B,$1C,$1D,$1C,$1D,$1C,$1D
        .byte   $1B,$1C,$1D,$1C,$1D,$1C,$1D,$1B
        .byte   $26,$23,$24,$25,$24,$25,$24,$25
        .byte   $23,$04,$04,$04
        ora     zp_temp_06
        .byte   $0F,$07,$08,$09,$0A,$0B,$0C,$0D
        .byte   $0E,$09,$16,$10,$11,$12,$13,$14
        .byte   $15,$12,$1A,$17,$17,$17,$18,$19
        .byte   $22,$1F,$1F,$20,$21
L87ED:  .byte   $3F,$78,$A9,$D2,$FF,$28,$59,$8A
        .byte   $BB,$EC,$1D,$4E,$83,$B8
        sbc     $4F1E
        sty     $BD
        .byte   $F2,$27,$5C,$91,$CA,$EF,$1C,$41
        .byte   $6A,$AF
        sed
        eor     ($8E,x)
        .byte   $BB,$F0,$25,$5E,$9F,$DC,$1D,$62
        .byte   $A7
L8816:  dey
        dey
        dey
        dey
        dey
        .byte   $89,$89,$89,$89,$89,$8A,$8A,$8A
        .byte   $8A,$8A,$8B,$8B,$8B,$8B,$8B,$8C
        .byte   $8C,$8C,$8C,$8C,$8D,$8D
L8831:  sta     L8D8D
        stx     L8E8E
        stx     L8F8F
        .byte   $8F,$8F,$90,$90,$90,$0E
        cpx     #$A0
        .byte   $03,$FA,$E8
        lda     ($03,x)
        beq     L8831
        ldx     #$03
        sed
        inx
        .byte   $A3,$03,$00,$E8,$A4,$03,$08,$F0
        .byte   $A5,$03,$F0,$F0,$A6,$03,$F8,$F0
        .byte   $A7,$03,$00,$F0,$A8,$03,$08,$F0
        cpy     #$01
        .byte   $FA,$F8,$A9,$03,$F0,$F8,$AA,$03
        .byte   $F8,$F8,$AB,$03,$00,$F8,$AC,$03
        .byte   $08,$0C
        cpx     #$AD
        .byte   $03,$FA,$E0,$AD,$03,$04,$E8,$AE
        .byte   $03,$F4,$E8,$AF,$03,$FC,$E8,$B0
        .byte   $03,$04,$F0,$B1,$03,$F4,$F0,$B2
        .byte   $03,$FC,$F0,$B3,$03,$04,$EF,$C0
        .byte   $01,$FA,$F8,$B4,$03,$F4,$F8,$B5
        .byte   $03,$FC,$F8,$B6,$03,$04,$0A,$E8
        .byte   $B7,$03,$F8,$E8,$B8,$03,$00,$F0
        .byte   $B9,$03,$F0,$F0,$BA,$03,$F8,$F0
        .byte   $BB,$03,$00,$F0,$B9,$43,$08,$F8
        .byte   $BC,$03,$F0,$F8,$BD,$03,$F8,$F8
        .byte   $BE,$03,$00,$F8,$BF,$03,$08,$0B
        .byte   $E0,$DC,$03,$F8,$E0,$DD,$03,$00
        .byte   $E8,$DE,$03,$F4,$E8,$E0,$03,$FC
        .byte   $E8,$E1,$03,$04,$E9,$C0,$01,$FA
        .byte   $F0,$E2,$03
L88EE:  .byte   $F4,$F0,$E3,$03,$FC,$F0,$E4,$03
        .byte   $04,$F8
        sbc     $03
        .byte   $F7,$F8,$E6,$03,$04,$0A,$E0
        ldy     #$03
        sed
        inx
        lda     ($03,x)
        .byte   $F7,$E8,$A2,$03,$FF,$F0,$A3,$03
        .byte   $F0,$F0,$A4,$03,$F8,$F0
        lda     $03
        brk
        .byte   $F8,$A6,$03,$F0,$F8,$A7,$03,$F8
        .byte   $F8,$A8,$03,$00,$F8,$A9,$03,$08
        .byte   $0C,$E0,$AA,$03,$F2,$E0,$AB,$03
        sed
        inx
        ldy     $F003
        inx
        lda     $F803
        inx
        ldx     a:$03
        beq     L88EE
        .byte   $03,$F0,$F0,$B0,$03,$F8,$F0
        lda     ($03),y
        brk
        .byte   $F8
L894A:  .byte   $B2,$03,$F0,$F8,$B3,$03,$F8,$F8
        .byte   $B4,$03,$00,$F8,$B5,$03,$08,$0C
        .byte   $E0,$B6,$03,$F8,$E8,$B7,$03,$F3
        .byte   $E8,$B8,$03,$FB,$E8,$B9,$03,$03
        .byte   $F0,$BA,$03,$F0,$F0,$BB,$03,$F8
        .byte   $F0,$BC,$03,$00,$F0,$BD,$03,$08
        .byte   $F8,$BE,$03,$F0,$F8,$BF,$03,$F8
        .byte   $F8,$C0,$03,$00,$F8,$C1,$03,$08
        .byte   $0C,$E0,$A0,$03,$F4
        cpx     #$A1
        .byte   $03,$04,$E8
        ldx     #$03
        .byte   $F4,$E8,$A3,$03,$FC,$E8,$A4,$03
        .byte   $04,$EC,$BF
        ora     ($FC,x)
        beq     L894A
        .byte   $03,$F4,$F0,$A6,$03,$FC,$F0,$A7
        .byte   $03,$04,$F8,$A8,$03,$F4,$F8,$A9
        .byte   $03,$FC
        sed
        tax
        .byte   $03,$04,$0C
        cpx     #$A0
        .byte   $03,$F0,$E0,$A1,$03,$00,$E8,$B6
        .byte   $03,$EC,$E8,$B7,$03,$F4,$E8,$B8
        .byte   $03,$FC,$EC,$BF,$01,$F8,$F0,$B9
        .byte   $03,$F4,$F0,$BA,$03,$FC,$F0,$BB
        .byte   $03,$04,$F8,$BC,$03,$F4,$F8,$BD
        .byte   $03,$FC
        sed
        ldx     $0403,y
        .byte   $0C
        cpx     #$AB
        .byte   $03,$04,$E8,$AC,$03,$F4,$E8,$AD
        .byte   $03,$FC,$E8,$AE,$03,$04,$EE,$BF
        .byte   $01,$FB,$F0,$AF,$03,$F4,$F0,$B0
        .byte   $03,$FC,$F0,$B1,$03,$04,$F8,$B2
        .byte   $03,$EC,$F8,$B3,$03,$F4,$F8,$B4
        .byte   $03,$FC,$F8,$B5,$03,$04,$0C,$E0
        .byte   $AB,$03,$04
        inx
        cpy     #$02
        .byte   $F4,$E8,$AD,$03,$FC,$E8,$AE,$03
        .byte   $04,$EE,$BF,$01,$FB,$F0,$AF,$03
        .byte   $F4,$F0,$B0,$03,$FC,$F0,$B1,$03
        .byte   $04,$F8,$B2,$03,$EC,$F8,$B3,$03
        .byte   $F4,$F8,$B4,$03,$FC,$F8,$B5,$03
        .byte   $04,$0D,$E0,$AB,$03,$04,$E8,$C1
        .byte   $03,$F4,$E8,$C2,$02,$FC,$E8,$C3
        .byte   $03,$FC,$E8,$AE,$03,$04,$EE,$BF
        .byte   $01,$FB,$F0,$AF,$03,$F4,$F0,$B0
        .byte   $03,$FC,$F0,$B1,$03,$04,$F8,$B2
        .byte   $03,$EC,$F8,$B3,$03,$F4,$F8,$B4
        .byte   $03,$FC,$F8,$B5,$03,$04,$0D,$E0
        .byte   $C5,$02,$04,$E8,$AC,$03,$F4
        inx
        cpy     $02
        .byte   $FC,$E8,$C3,$03,$FC,$E8,$AE,$03
        .byte   $04,$EE,$BF,$01,$FB,$F0,$AF,$03
        .byte   $F4,$F0,$B0,$03,$FC,$F0,$B1,$03
        .byte   $04,$F8,$B2,$03,$EC,$F8,$B3,$03
        .byte   $F4,$F8,$B4,$03,$FC,$F8,$B5,$03
        .byte   $04
        ora     $C6E0
        .byte   $02,$04
L8ABD:  inx
        ldy     $F403
        inx
        lda     $FC03
        inx
        ldx     $0403
        inx
        .byte   $C7,$02,$04,$EE,$BF,$01,$FB,$F0
        .byte   $AF,$03,$F4,$F0,$B0,$03,$FC,$F0
        .byte   $B1,$03,$04,$F8,$B2,$03,$EC,$F8
        .byte   $B3,$03,$F4,$F8,$B4,$03,$FC,$F8
        .byte   $B5,$03,$04,$0C,$E0,$C8,$02,$04
        .byte   $E8,$AC,$03,$F4,$E8,$AD,$03,$FC
        .byte   $E8,$AE,$03,$04,$EE,$BF,$01,$FB
        .byte   $F0,$AF,$03,$F4,$F0,$B0,$03,$FC
        beq     L8ABD
        .byte   $03,$04,$F8,$B2,$03,$EC,$F8,$B3
        .byte   $03,$F4,$F8,$B4,$03,$FC,$F8,$B5
        .byte   $03,$04,$0C,$E0
        ldy     #$03
        .byte   $F3,$E0,$A1,$03,$03,$E8,$F5,$03
        .byte   $F2,$E8,$F6,$03,$FA,$E8,$F7,$03
        .byte   $02,$EC,$BF,$01
L8B36:  .byte   $FB,$F0,$F8,$03,$F4
        beq     L8B36
        .byte   $03,$FC,$F0,$FA,$03,$04,$F8,$FB
        .byte   $03,$F4,$F8,$FC,$03,$FC,$00,$FD
        .byte   $03,$FD,$0D,$E0,$A0,$03,$FC
L8B54:  inx
        lda     ($03,x)
        inc     $E8,x
        ldx     #$03
        inc     LA3E8,x
        .byte   $03,$06,$EB,$F4,$01,$FB,$F0,$A4
        .byte   $03,$F0,$F0,$A5,$03,$F8,$F0,$A6
        .byte   $03,$00,$F0,$A7,$03,$08,$F8,$A8
        .byte   $03,$F0,$F8,$A9,$03,$F8,$F8,$AA
        .byte   $03,$00,$F8,$AB,$03,$08,$0E,$E0
        .byte   $AC,$03,$F1,$E0
        ldy     #$03
        inc     LADE8,x
        .byte   $03,$F0,$E8,$AE,$03,$F8,$E8,$AF
        .byte   $03,$00,$E8
        bcs     L8B9F
        php
        .byte   $EB,$F4
L8B9F:  ora     ($FD,x)
        beq     L8B54
        .byte   $03,$F8,$F0,$B2,$03,$00,$F0,$B3
        .byte   $03,$08,$F8,$B4,$03,$F0,$F8,$B5
        .byte   $03,$F8,$F8,$B6,$03,$00,$F8,$B7
        .byte   $03,$08,$0D,$E8,$B8,$03,$F0,$E8
        .byte   $B9,$03,$F8,$E8,$BA,$03,$00,$E8
        .byte   $BB,$03,$08,$ED,$F4,$01,$FD,$F0
        .byte   $BC,$03,$F0,$F0,$BD,$03,$F8,$F0
        .byte   $BE,$03,$00,$F0,$BF,$03,$08,$F8
        .byte   $C0,$03,$F0,$F8,$C1,$03,$F8,$F8
        .byte   $C2,$03,$00,$F8,$C3,$03,$08,$0D
        .byte   $E8,$B8,$03,$F0,$E8,$C4,$03,$F8
        .byte   $E8
        cmp     $03
        brk
        .byte   $E8,$BB,$03,$08,$ED,$F4,$01,$FD
        .byte   $F0,$BC,$03,$F0,$F0,$BD,$03,$F8
        .byte   $F0,$BE,$03,$00,$F0,$BF,$03,$08
        .byte   $F8,$C0,$03,$F0,$F8,$C1,$03,$F8
        .byte   $F8,$C2,$03,$00,$F8,$C3,$03,$08
        .byte   $0D,$E8,$B8,$03,$F0,$E8,$B9,$03
        .byte   $F8,$E8,$BA,$03,$00,$E8,$BB,$03
        .byte   $08,$ED,$F4,$01,$FD,$F0,$BC,$03
        .byte   $F0,$F0,$BD,$02,$F8,$F0,$BE,$02
        .byte   $00,$F0,$BF,$03,$08,$F8,$C0,$03
        .byte   $F0,$F8,$C6,$03,$F8,$F8,$C7,$03
        .byte   $00,$F8,$C3,$03,$08,$0D,$E8,$B8
        .byte   $02,$F0,$E8,$B9,$02,$F8,$E8,$BA
        .byte   $02,$00,$E8,$BB,$02,$08,$ED,$F4
        .byte   $01,$FD,$F0,$BC,$02,$F0,$F0,$BD
        .byte   $03,$F8,$F0,$BE,$03,$00,$F0
L8C7E:  .byte   $BF,$02,$08
        sed
        cpy     #$02
        beq     L8C7E
L8C86:  iny
        .byte   $02,$F8,$F8,$C9,$03,$00,$F8,$C3
        .byte   $02
        php
        asl     LACE0
        .byte   $03,$F1,$E0,$A0,$03,$FE,$E8,$AD
        .byte   $03,$F0,$E8,$AE,$03,$F8,$E8,$AF
        .byte   $03,$00,$E8,$B0,$03,$08,$EB,$F4
        ora     ($FD,x)
L8CAE:  beq     L8C86
        .byte   $03,$F8,$F0,$D7,$03,$00,$F0,$D8
L8CB8:  .byte   $03,$08,$F8,$D9,$03,$F8,$F8,$DA
        .byte   $03,$00,$00,$DB,$03,$F8,$00,$DC
        .byte   $03,$00,$09,$E8,$A1,$03,$F8,$E8
        .byte   $A2,$03,$00,$E9,$A0,$01,$F9,$F0
        .byte   $A3,$03,$F4,$F0,$A4,$03,$FC,$F0
        .byte   $A5,$03,$04,$F8,$A6,$03,$F4,$F8
        .byte   $A7,$03,$FC,$F8,$A8,$03,$04,$0B
        .byte   $E8,$A9,$03,$F4,$E8,$AA,$03,$FC
        .byte   $E8,$AB,$03,$04,$EA,$A0,$01,$F6
        beq     L8CAE
        .byte   $03
        sbc     ($F0),y
        lda     $F903
        beq     L8CB8
        .byte   $03
        ora     ($F8,x)
        .byte   $AF,$03,$EC
        sed
        bcs     L8D16
        .byte   $F4,$F8,$B1
L8D16:  .byte   $03,$FC,$F8,$B2,$03,$04,$09,$E8
        .byte   $B3,$03,$F4,$E8,$B4,$03,$FC,$E8
        .byte   $B5,$03,$04,$E9,$A0,$01,$FC,$F0
        .byte   $B6,$03,$F9,$F0,$B7,$03,$01
        sed
        clv
        .byte   $03,$F4,$F8,$B9,$03,$FC,$F8,$BA
        .byte   $03,$04,$0A,$E8,$A1,$03,$F8,$E8
        .byte   $BB,$03,$00,$E9,$A0,$01,$F9,$F0
        .byte   $BC,$03,$F4,$F0,$BD,$03,$FC,$F0
        .byte   $BE,$03,$04,$F8,$BF,$03,$F4,$F8
        .byte   $C0,$03,$FC,$F8,$C1,$03,$04,$00
        .byte   $C2,$03,$FA,$11,$E0,$A0,$03,$F0
        .byte   $E0,$A1,$03,$F8,$E0,$A2,$03,$00
        .byte   $E0,$A3,$03,$08,$E8,$A4,$03,$F0
        .byte   $E8
        lda     $03
        sed
        inx
        ldx     $03
        brk
        .byte   $E8,$A7,$03,$08,$F0,$A8
L8D8D:  .byte   $03,$F0,$F0,$A9,$03,$F8,$F0,$AA
        .byte   $03,$00,$F0
L8D98:  .byte   $AB,$03,$08,$F8,$AC,$03
        beq     L8D98
        lda     $F803
        sed
        ldx     a:$03
        sed
        .byte   $AF,$03,$08,$E2,$DE
L8DAD:  ora     ($FB,x)
        .byte   $12
        cpx     #$B0
        .byte   $03,$F6,$E0,$B1,$03,$FE,$E0,$B2
        .byte   $03,$06,$E0,$B3,$03,$0E
        inx
        ldy     $03,x
        beq     L8DAD
        lda     $03,x
        sed
        inx
        ldx     $03,y
        brk
        .byte   $E8,$B7,$03,$08,$E8,$B8,$03,$10
        .byte   $F0,$B9,$03,$F0,$F0,$BA,$03,$F8
        .byte   $F0,$BB,$03,$00,$F0
        ldy     $0803,x
        sed
        lda     $F003,x
        sed
        ldx     $F803,y
        sed
        .byte   $BF,$03,$00,$F8,$C0,$03,$08,$E4
        .byte   $DE
        ora     ($FB,x)
        .byte   $12,$E0,$B0,$03,$F6,$E0
        lda     ($03),y
        inc     LB2E0,x
        .byte   $03,$06,$E0,$B3,$03,$0E,$E8,$B4
        .byte   $03,$F0,$E8
        cmp     ($03,x)
        sed
        inx
        .byte   $C2,$03,$00,$E8,$B7,$03,$08,$E8
        .byte   $B8,$03,$10,$F0,$B9,$03,$F0,$F0
        .byte   $C3,$03,$F8,$F0,$C4,$03,$00,$F0
        .byte   $BC,$03,$08,$F8,$BD,$03,$F0,$F8
        .byte   $BE,$03,$F8,$F8,$BF,$03,$00,$F8
        .byte   $C0,$03
        php
        cpx     $DE
        ora     ($FB,x)
        .byte   $13,$E0,$B0,$03
        inc     $E0,x
        lda     ($03),y
        inc     LB2E0,x
        .byte   $03,$06,$E0,$B3,$03,$0A,$E8,$B4
        .byte   $03,$F0,$E8
        lda     $03,x
        sed
        inx
        ldx     $03,y
        brk
        .byte   $E8,$B7,$03,$08,$E8,$B8,$03,$10
        .byte   $F0,$C5,$03,$F0,$F0,$C6,$03,$F8
        .byte   $F0,$C7,$03,$00,$F0,$C8,$03,$08
        .byte   $F8,$C9,$03,$F5,$F8,$CA,$03,$FD
        .byte   $F8,$CB,$03
L8E81:  ora     $00
        cpy     $F503
        brk
        .byte   $CD,$03,$05,$E4
        dec     $FB01,x
L8E8E:  .byte   $0B,$E8,$A0,$03,$F8,$E8,$A1,$03
        .byte   $00,$F0,$A2,$03,$F0,$F0,$A3,$03
        .byte   $F8,$F0,$A4,$03,$00,$F0
L8EA4:  lda     $03
        php
        sed
        ldx     $03
        beq     L8EA4
        .byte   $A7,$03,$F8,$F8,$A8,$03,$00,$F8
        .byte   $A9,$03,$08,$ED,$F3,$01,$FA,$0D
        .byte   $E0
L8EBD:  .byte   $AA,$03,$F0,$E0,$AB,$03,$F8,$E8
        ldy     $F003
        inx
        lda     $F803
        inx
        ldx     a:$03
        beq     L8E81
        .byte   $03,$F0,$F0,$B0,$03,$F8,$F0
        lda     ($03),y
        brk
        .byte   $F8,$B2
L8EDE:  .byte   $03,$F0,$F8,$B3,$03,$F8,$F8,$B4
        .byte   $03,$00,$F8,$B5,$03,$08,$ED,$F3
        .byte   $01,$F9,$0D,$E8
L8EF2:  ldx     $03,y
        beq     L8EDE
        .byte   $B7,$03,$F8,$E8,$B8,$03,$00,$E8
        .byte   $B9,$03,$08
        beq     L8EBD
        .byte   $03,$F0,$F0,$BB,$03,$F8,$F0,$BC
        .byte   $03,$00,$F0,$BD,$03,$08,$F8,$BE
        .byte   $03,$F0,$F8,$BF,$03,$F8,$F8,$C0
        .byte   $03,$00,$F8,$C1,$03,$08,$ED,$F3
        .byte   $01,$FC,$0E,$E8,$B6,$03,$EE,$E8
        .byte   $B7,$03,$F6
        inx
        clv
        .byte   $03,$FE,$E8
        lda     $0603,y
        beq     L8EF2
        .byte   $03,$EE,$F0,$BB,$03,$F6,$F0,$BC
        .byte   $03,$FE,$F0,$BD,$03,$06,$F8,$C2
        .byte   $03,$F8,$F8,$C3,$03,$00,$F8,$C4
        .byte   $03,$08,$00,$C5,$03,$F8,$00,$C6
        .byte   $03,$00,$ED,$F3,$01,$FB,$10,$E0
        .byte   $A0,$03,$F8,$E0,$A1,$03,$00,$E0
        .byte   $A2,$03,$08,$E8,$A3,$03,$F0,$E8
        ldy     $03
        sed
L8F73:  inx
        lda     $03
        brk
        .byte   $E8,$A6,$03,$08,$F0,$A7,$03,$F0
        .byte   $F0,$A8,$03,$F8,$F0,$A9,$03,$00
        .byte   $F0,$AA,$03,$08,$F8,$AB,$03,$F0
L8F8F:  sed
        ldy     $F803
        sed
        ldy     a:$43
        sed
        lda     $0803
        .byte   $E7,$F4,$02,$FA,$0F,$E0,$AE,$03
        .byte   $F8,$E0,$AF,$03,$00,$E0,$B0,$03
        .byte   $08,$E8,$B1,$03,$F0,$E8,$B2,$03
        .byte   $F8,$E8,$B3,$03,$00,$E8,$B4,$03
        php
        beq     L8F73
        .byte   $03,$F5,$F0,$B6,$03,$FD,$F0
L8FC5:  .byte   $B7,$03,$05,$F8,$B8,$03,$F0,$F8
        .byte   $B9,$03,$F8,$F8,$BA,$03,$00,$F8
        .byte   $BB,$03,$08,$E8,$F4,$02,$FA,$10
        .byte   $E0,$AE,$03,$F8,$E0,$AF,$03,$00
        .byte   $E0,$B0,$03,$08,$E8,$BC,$03,$F0
        .byte   $E8
        lda     $F803,x
        inx
        ldx     a:$03,y
        inx
        .byte   $BF,$03,$08,$F0,$C0,$03,$F0,$F0
        .byte   $C1,$03,$F8
        beq     L8FC5
        .byte   $03,$00,$F0
L9006:  .byte   $C3,$03
        php
        sed
        clv
        .byte   $03
        beq     L9006
        lda     $F803,y
        sed
        tsx
        .byte   $03,$00,$F8,$BB,$03
        php
        inx
        .byte   $F4,$02,$FA,$11,$E0,$A0,$03,$F8
        .byte   $E0,$A1,$03,$00,$E0,$CC,$03,$08
        .byte   $E8,$CD,$03,$F0,$E8
        dec     $F803
        inx
        .byte   $A5
L9034:  .byte   $03
        brk
        .byte   $E8,$CF,$03,$08,$F0,$D0,$03,$F0
        .byte   $F0,$D1,$03,$F8,$F0,$D2,$03,$00
        .byte   $F0
L9047:  .byte   $D3
L9048:  .byte   $03,$08,$F8,$D4,$03
        beq     L9047
        cmp     $03,x
        sed
        sed
        cmp     $03,x
L9055:  brk
        .byte   $F8,$D6,$03,$08,$E7,$F4,$02,$FA
        .byte   $E0,$CB
L9060:  .byte   $03,$F0,$11,$E0,$C1,$03
        beq     L9048
        .byte   $C2,$03,$F8,$E0,$C3,$03,$00,$E0
        .byte   $C4,$03,$08,$E8
        cmp     $03
        beq     L9060
        ldx     #$03
        sed
        inx
        dec     $03
        brk
        .byte   $E8,$C7,$03,$08,$F0,$C8,$03,$F0
        .byte   $F0
        ldx     $03
        sed
        beq     L9034
        .byte   $03,$00,$F0
        cmp     #$03
        php
        .byte   $F0
L9094:  cpy     #$01
        .byte   $FA
        sed
        dex
        .byte   $03
        beq     L9094
        .byte   $CB,$03,$F8
        sed
        cpy     a:$03
        sed
        cmp     $0803
        ora     ($E0),y
        dec     $F003
        cpx     #$CF
        .byte   $03,$F8,$E0,$D0,$03,$00,$E0,$D1
        .byte   $03,$08,$E8,$D2,$03,$F0,$E8
        ldx     #$03
        sed
        inx
        .byte   $D3,$03,$00,$E8,$D4,$03,$08,$F0
        .byte   $D5,$03,$F0,$F0,$A6,$03,$F8,$F0
        .byte   $A7,$03,$00,$F0,$C9,$03,$08,$F0
        cpy     #$01
        .byte   $FA,$F8,$CA,$03,$F0,$F8,$CB,$03
        .byte   $F8,$F8,$CC,$03,$00,$F8,$CD,$03
        .byte   $08
        jsr     LCC6C
        lda     #$00
        jsr     fixed_D2EF
        lda     $B5
        pha
        lda     $B6
        pha
        lda     $B7
        pha
        lda     $B8
        pha
        lda     $B9
        pha
        lda     $20
        pha
        lda     $1F
        pha
        ldx     #$11
L910B:  lda     $0354,x
        sta     $0700,x
        dex
        bpl     L910B
        lda     #$00
        sta     $B8
        sta     $B7
        sta     $B5
        sta     $B6
        lda     $2A
        cmp     #$04
        bne     L913D
        lda     $38
        cmp     #$03
        bcc     L913D
        cmp     #$0F
        bcs     L913D
        cmp     #$07
        beq     L913D
        ldx     #$0F
        txa
L9135:  sta     $0356,x
        dex
        bpl     L9135
        inc     $20
L913D:  lda     $B1
        beq     L9155
        lda     $B3
        cmp     #$08
        bcc     L9155
        ldx     #$00
        stx     $1F
        cmp     #$0A
        beq     L9155
        cmp     #$0B
        beq     L9155
        inc     $20
L9155:  lda     #$0A
        cmp     $2A
        bne     L9172
        lda     $B1
        beq     L9172
        lda     #$0F
        ldx     #$02
L9163:  sta     $035B,x
        sta     $037B,x
        sta     $038B,x
        sta     $039B,x
        dex
        bpl     L9163
L9172:  clc
        lda     $1F
        adc     #$80
        and     #$E0
        ora     #$04
        sta     $52
        lda     $20
        adc     #$00
        sta     $53
        ldx     #$00
L9185:  stx     $FD
        clc
        lda     $52
        adc     L957F,x
        sta     $08
        lda     $53
        adc     #$00
        sta     $09
        lda     #$00
        sta     $1B
        jsr     LC8B1
        ldx     $FD
        lda     L9570,x
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
L91A8:  lda     L958E,x
        sta     $0310,y
        inx
        iny
        cpy     #$10
        bne     L91A8
        ldx     $2A
        lda     L961E,x
        sta     $0350
        lda     #$01
        sta     $1B
        ldy     #$99
        ldx     #$00
        jsr     LC760
        jsr     LC0AB
        ldx     $FD
        inx
        cpx     #$0F
        bne     L9185
        stx     $FD
        ldy     #$99
        ldx     #$00
        jsr     LC760
        lda     #$00
        sta     $FE
        sta     $FF
        ldx     $A9
        inx
        cpx     #$07
        bcc     L91ED
        txa
        sbc     #$06
        tax
        inc     $FE
L91ED:  stx     $FD
L91EF:  lda     $9A
        asl     a
        ora     #$41
        sta     $07
        lda     $FE
        beq     L920B
        lda     $9A
        sta     $07
        lda     $9B
        asl     $07
        rol     a
        asl     $07
        rol     a
        asl     $07
        rol     a
        sta     $07
L920B:  lda     $27
        and     #$08
        beq     L9214
        jmp     L9281

L9214:  lda     $27
        and     #$30
        bne     L9236
        lda     $23
        and     #$30
        beq     L9274
        sta     $00
        lda     $25
        and     #$30
        cmp     $00
        bne     L9274
        inc     $FF
        lda     $FF
        cmp     #$18
        bcc     L9278
        lda     #$08
        sta     $FF
L9236:  ldx     #$07
        lda     $FE
        beq     L923D
        dex
L923D:  lda     #$2F
        jsr     bank_switch_enqueue
        lda     $23
        and     #$30
        and     #$10
        bne     L9261
L924A:  inc     $FD
        cpx     $FD
        bcs     L9254
        lda     #$00
        sta     $FD
L9254:  ldy     $FD
        beq     L9278
        lda     L9670,y
        and     $07
        beq     L924A
        bne     L9278
L9261:  dec     $FD
        bpl     L9267
        stx     $FD
L9267:  ldy     $FD
        beq     L9278
        lda     L9670,y
        and     $07
        beq     L9261
        bne     L9278
L9274:  lda     #$00
        sta     $FF
L9278:  jsr     L9396
        jsr     LC0AB
        jmp     L91EF

L9281:  lda     $FD
        bne     L928E
        lda     $FE
        eor     #$01
        sta     $FE
        jmp     L9274

L928E:  cmp     #$07
        bne     L92B6
        lda     $A7
        beq     L9274
        dec     $A7
L9298:  lda     $06C0
        cmp     #$1C
        beq     L9274
        lda     $1C
        and     #$03
        bne     L92AD
        inc     $06C0
        lda     #$28
        jsr     bank_switch_enqueue
L92AD:  jsr     L9396
        jsr     LC0AB
        jmp     L9298

L92B6:  lda     $FD
        beq     L9274
        cmp     #$07
        beq     L9274
        tax
        dex
        lda     $FE
        beq     L92C9
        clc
        txa
        adc     #$06
        tax
L92C9:  stx     $A9
        jsr     LCC6C
        lda     $1A
        pha
        ldx     #$00
L92D3:  stx     $FD
        clc
        lda     $52
        adc     L957F,x
        sta     $08
        lda     $53
        adc     #$00
        sta     $09
        lda     $08
        lsr     $09
        ror     a
        lsr     $09
        ror     a
        sta     $08
        and     #$3F
        sta     $1A
        clc
        lda     $09
        adc     #$85
        sta     $09
        lda     #$00
        sta     $1B
        jsr     LCA0B
        lda     $FD
        cmp     #$08
        bcs     L9317
        ldx     $A9
        lda     L9664,x
        tay
        cpx     #$09
        bcc     L9313
        ldx     #$00
        beq     L931B
L9313:  ldx     #$05
        bne     L931B
L9317:  ldy     #$90
        ldx     #$00
L931B:  jsr     LC760
        jsr     LC0AB
        ldx     $FD
        inx
        cpx     #$0F
        bne     L92D3
        stx     $FD
        ldy     #$90
        ldx     #$00
        jsr     LC760
        jsr     fixed_D2ED
        jsr     LC0AB
        pla
        sta     $1A
        lda     $2A
        cmp     #$0A
        bne     L9358
        lda     $B1
        beq     L9358
        ldx     #$02
L9346:  lda     L9393,x
        sta     $035B,x
        sta     $037B,x
        sta     $038B,x
        sta     $039B,x
        dex
        bpl     L9346
L9358:  ldx     #$11
L935A:  lda     $0700,x
        sta     $0354,x
        dex
        bpl     L935A
        pla
        sta     $1F
        pla
        sta     $20
        pla
        sta     $B9
        pla
        sta     $B8
        pla
        sta     $B7
        pla
        sta     $B6
        pla
        sta     $B5
        lda     #$00
        sta     $AC
        sta     $2C
        sta     $0680
        sta     $06A0
        lda     #$1A
        sta     $0400
        lda     #$03
        sta     $AA
        lda     #$30
        jsr     bank_switch_enqueue
        rts

L9393:  .byte   $27,$11,$16
L9396:  jsr     LCC6C
        lda     $52
        and     #$E0
        sec
        sbc     $1F
        sta     $08
        ldy     #$00
L93A4:  lda     L962C,y
        sta     $0200,y
        iny
        cpy     #$14
        bne     L93A4
        lda     $9A
        asl     a
        ora     #$01
        sta     $07
        lda     #$05
        sta     $01
        ldx     #$00
        lda     $FE
        beq     L93D3
        ldx     #$06
        lda     $9A
        sta     $07
        lda     $9B
        asl     $07
        rol     a
        asl     $07
        rol     a
        asl     $07
        rol     a
        sta     $07
L93D3:  lda     $07
        sta     $02
        lda     #$44
        sta     $00
L93DB:  sta     $0200,y
        lsr     $02
        bcs     L93E7
        lda     #$F8
        sta     $0200,y
L93E7:  lda     L9640,x
        sta     $0201,y
        lda     #$01
        sta     $0202,y
        lda     #$0C
        sta     $0203,y
        clc
        lda     $00
        adc     #$10
        sta     $00
        iny
        iny
        iny
        iny
        inx
        dec     $01
        bpl     L93DB
        lda     $FE
        bne     L9475
        ldx     #$00
L940D:  lda     L964C,x
        sta     $0200,y
        iny
        inx
        cpx     #$04
        bne     L940D
        sty     $00
        lda     #$44
        sta     $02
        lda     $06C0
        jsr     L952B
        lda     $07
        lsr     a
        sta     $04
        ldx     #$00
        lda     #$54
L942E:  stx     $03
        sta     $02
        lsr     $04
        bcc     L9439
        jsr     L9529
L9439:  clc
        lda     $02
        adc     #$10
        ldx     $03
        inx
        cpx     #$05
        bne     L942E
        ldy     $00
        lda     $A7
        beq     L9472
        sta     $02
        lda     #$1C
L944F:  sta     $01
        lda     #$A4
        sta     $0200,y
        lda     #$13
        sta     $0201,y
        lda     #$00
        sta     $0202,y
        lda     $01
        sta     $0203,y
        iny
        iny
        iny
        iny
        clc
        lda     $01
        adc     #$10
        dec     $02
        bne     L944F
L9472:  jmp     L94DD

L9475:  ldx     #$04
L9477:  lda     L964C,x
        sta     $0200,y
        iny
        inx
        cpx     #$18
        bne     L9477
        sty     $00
        lda     $07
        sta     $04
        ldx     #$05
        lda     #$44
L948D:  stx     $03
        sta     $02
        lsr     $04
        bcc     L9498
        jsr     L9529
L9498:  clc
        lda     $02
        adc     #$10
        ldx     $03
        inx
        cpx     #$0B
        bne     L948D
        lda     $A8
        sta     $01
        dec     $01
        lda     #$0A
        sta     $02
        jsr     LC84E
        ldy     $00
        lda     #$A5
        sta     $0200,y
        sta     $0204,y
        clc
        lda     $03
        adc     #$14
        sta     $0201,y
        clc
        lda     $04
        adc     #$14
        sta     $0205,y
        lda     #$01
        sta     $0202,y
        sta     $0206,y
        lda     #$38
        sta     $0203,y
        lda     #$40
        sta     $0207,y
L94DD:  ldy     #$00
        lda     $1C
        and     #$08
        bne     L94E7
        ldy     #$20
L94E7:  sty     $00
        ldx     $FD
        bne     L94F9
        lda     $00
        beq     L9507
        lda     #$F8
        sta     $0200
        jmp     L9507

L94F9:  dex
        txa
        asl     a
        asl     a
        tay
        lda     $00
        beq     L9507
        lda     #$F8
        sta     $0214,y
L9507:  ldx     #$00
L9509:  clc
        lda     $0203,x
        adc     $08
        sta     $0203,x
        inx
        inx
        inx
        inx
        bne     L9509
        rts

        .byte   $2C,$3C,$4C,$5C,$6C,$7C,$8C,$9C
        .byte   $3C,$4C,$5C,$6C,$7C,$8C,$9C,$AC
L9529:  lda     $9C,x
L952B:  sta     $01
        ldx     #$06
L952F:  lda     $02
        sta     $0200,y
        sec
        lda     $01
        sbc     #$04
        bcs     L9549
        ldy     $01
        lda     #$00
        sta     $01
        lda     L956C,y
        ldy     $00
        jmp     L954D

L9549:  sta     $01
        lda     #$90
L954D:  sta     $0201,y
        lda     #$01
        sta     $0202,y
        lda     L9565,x
        sta     $0203,y
        iny
        iny
        iny
        iny
        sty     $00
        dex
        bpl     L952F
        rts

L9565:  .byte   $4C,$44,$3C,$34,$2C,$24,$1C
L956C:  sty     $93,x
        .byte   $92,$91
L9570:  .byte   $00,$01,$02,$03,$04,$05,$03,$04
        .byte   $05,$03,$04,$05,$06,$07,$08
L957F:  .byte   $00,$20,$40,$04,$24,$44,$08,$28
        .byte   $48,$0C,$2C,$4C,$10,$30,$50
L958E:  .byte   $40,$40,$40,$40,$40,$41,$41,$41
        .byte   $40,$41,$41,$41,$40,$41,$41,$41
        .byte   $40,$40,$40,$40,$41,$41,$41,$41
        .byte   $41,$41,$41,$41,$41,$41,$41,$41
        .byte   $40,$40,$40,$40,$41,$41,$41,$40
        .byte   $41,$41,$41,$40,$41,$41,$41,$40
        .byte   $40,$41,$41,$41,$40,$41,$41,$41
        .byte   $40,$41,$41,$41,$40,$41,$41,$41
        .byte   $41,$41,$41,$41,$41,$41,$41,$41
        .byte   $41,$41,$41,$41,$41,$41,$41,$41
        eor     ($41,x)
        eor     ($40,x)
        eor     ($41,x)
        eor     ($40,x)
        eor     ($41,x)
        eor     ($40,x)
        eor     ($41,x)
        eor     ($40,x)
        rti

        .byte   $41,$41,$41,$40,$41,$41,$41,$40
        .byte   $41,$41,$41,$40,$40,$40,$40,$41
        .byte   $41,$41,$41,$41,$41,$41,$41,$41
        .byte   $41,$41,$41,$40,$40,$40,$40,$41
        .byte   $41,$41,$40,$41,$41,$41,$40,$41
        .byte   $41,$41,$40,$40,$40,$40,$40
L961E:  .byte   $00,$55,$AA,$00,$AA,$00,$00,$00
        .byte   $00,$00,$55,$AA,$00,$00
L962C:  .byte   $34,$11,$01,$0C,$34,$95,$01,$1C
        .byte   $34,$96,$01,$24,$34,$97,$01,$2C
        .byte   $34,$98,$01,$34
L9640:  .byte   $1F,$9F,$9B,$99,$9D,$9C,$9A,$9E
        .byte   $10,$15,$16,$17
L964C:  ldy     $96
        ora     ($0C,x)
        ldy     #$8D
        brk
        .byte   $18,$A0,$8D,$40,$20,$A8,$8E,$01
        .byte   $18,$A8,$8E,$41
        jsr     L1EA4
        ora     ($2C,x)
L9664:  tya
        txs
        sta     L989C,y
        tya
        txs
        tya
        .byte   $9B,$9B,$9B,$9B
L9670:  .byte   $00,$01,$02,$04,$08,$10,$20,$40
        lda     #$10
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001
L9686:  lda     #$0F
        jsr     LC05D
        jsr     reset_scroll_state
        lda     #$01
        jsr     LC644
        lda     #$20
        sta     $2006
        ldy     #$00
        sty     $2006
L969D:  lda     L9B83,y
        ldx     #$40
L96A2:  sta     $2007
        dex
        bne     L96A2
        iny
        cpy     #$10
        bne     L969D
        lda     #$28
        sta     $2006
        ldy     #$00
        sty     $2006
        lda     #$AC
        sta     $09
        lda     #$03
        jsr     LC628
        ldx     #$1F
L96C2:  lda     L9B93,x
        sta     $0356,x
        dex
        bpl     L96C2
        jsr     clear_oam_buffer
        lda     $2A
        cmp     #$09
        bcc     L96DA
        jsr     L9B27
        jmp     L9945

L96DA:  lda     #$12
        jsr     bank_switch_enqueue
        jsr     LA51D
        lda     #$FF
        sta     $0440
        sta     $0441
        lda     #$D0
        sta     $0460
        sta     $0461
        lda     #$68
        sta     $04A0
        lda     #$80
        sta     $04A1
        lda     #$00
        sta     $0400
        sta     $0681
        sta     $0480
        sta     $0481
        sta     $04C0
        sta     $04C1
        lda     #$01
        sta     $0401
L9715:  clc
        lda     $0480
        adc     #$40
        sta     $0480
        lda     $0460
        adc     #$01
        sta     $0460
        sta     $0461
        lda     $0440
        adc     #$00
        sta     $0440
        sta     $0441
        bne     L973D
        lda     $0460
        cmp     #$68
        bcs     L9755
L973D:  jsr     update_animation_frame
        jsr     clear_oam_buffer
        ldx     #$00
        stx     $00
        jsr     entity_update_handler
        ldx     #$01
        jsr     entity_update_handler
        jsr     LC0AB
        jmp     L9715

L9755:  jsr     clear_oam_buffer
        ldx     #$00
        stx     $00
        jsr     entity_update_handler
        ldx     #$01
        jsr     entity_update_handler
        lda     #$3E
        sta     $FD
L9768:  jsr     update_animation_frame
        ldx     #$00
        stx     $00
        jsr     entity_update_handler
        ldx     #$01
        jsr     entity_update_handler
        jsr     LC0AB
        dec     $FD
        bne     L9768
        lda     #$04
        sta     $0402
        lda     #$6C
        sta     $0462
        lda     #$70
        sta     $04A2
        lda     #$00
        sta     $0442
        lda     #$50
        sta     $FD
L9796:  sec
        lda     $04C0
        sbc     #$80
        sta     $04C0
        lda     $04A0
        sbc     #$00
        sta     $04A0
        jsr     update_animation_frame
        jsr     update_all_entities
        jsr     LC0AB
        dec     $FD
        bne     L9796
        lda     #$FA
        sta     $FD
L97B8:  inc     $0682
        lda     $0682
        cmp     #$08
        bcc     L97D6
        lda     #$00
        sta     $0682
        inc     $0402
        lda     $0402
        cmp     #$06
        bcc     L97D6
        lda     #$04
        sta     $0402
L97D6:  jsr     update_animation_frame
        jsr     update_all_entities
        jsr     LC0AB
        dec     $FD
        bne     L97B8
        lda     #$50
        sta     $FD
L97E7:  clc
        lda     $04C0
        adc     #$80
        sta     $04C0
        lda     $04A0
        adc     #$00
        sta     $04A0
        jsr     update_animation_frame
        jsr     update_all_entities
        jsr     LC0AB
        dec     $FD
        bne     L97E7
        lda     #$FD
        jsr     bank_switch_enqueue
        lda     #$06
        sta     $0400
        lda     #$01
        sta     $06A0
        lda     #$00
        sta     $FD
        sta     $0620
        lda     #$04
        sta     $0600
L9820:  lda     $06A0
        bne     L985B
        ldx     #$00
        lda     $0460
        cmp     #$68
        bcs     L982F
        inx
L982F:  clc
        lda     $0620
        adc     L9D88,x
        sta     $0620
        lda     $0600
        adc     L9D8A,x
        sta     $0600
        sec
        lda     $0480
        sbc     $0620
        sta     $0480
        lda     $0460
        sbc     $0600
        sta     $0460
        cmp     #$18
        bcs     L98BF
        bcc     L989E
L985B:  ldx     #$00
        lda     $0460
        cmp     #$68
        bcc     L9865
        inx
L9865:  clc
        lda     $0620
        adc     L9D88,x
        sta     $0620
        lda     $0600
        adc     L9D8A,x
        sta     $0600
        clc
        lda     $0480
        adc     $0620
        sta     $0480
        lda     $0460
        adc     $0600
        sta     $0460
        cmp     #$68
        bcc     L98BF
        ldx     $FD
        lda     L9D83,x
        sta     $0400
        lda     $0460
        cmp     #$B8
L989C:  bcc     L98BF
L989E:  lda     #$00
        sta     $0600
        sta     $0620
        lda     $06A0
        php
        eor     #$01
        sta     $06A0
        plp
        beq     L98BF
        inc     $FD
        lda     $FD
        cmp     #$03
        bne     L98BF
        lda     #$11
        jsr     bank_switch_enqueue
L98BF:  jsr     clear_oam_buffer
        ldx     #$00
        stx     $00
        jsr     entity_update_handler
        lda     $0400
        bne     L98DC
        lda     $0460
        sta     $0461
        jsr     update_animation_frame
        ldx     #$01
        jsr     entity_update_handler
L98DC:  jsr     apply_gravity
        jsr     L9A1D
        jsr     LC0AB
        lda     $FD
        cmp     #$05
        beq     L98EE
        jmp     L9820

L98EE:  lda     #$0A
        sta     $0400
L98F3:  clc
        lda     $0620
        adc     #$18
        sta     $0620
        lda     $0600
        adc     #$00
        sta     $0600
        sec
        lda     $0480
        sbc     $0620
        sta     $0480
        lda     $0460
        sbc     $0600
        sta     $0460
        cmp     #$68
        bcc     L9931
        jsr     clear_oam_buffer
        ldx     #$00
        stx     $00
        jsr     entity_update_handler
        jsr     apply_gravity
        jsr     L9A1D
        jsr     LC0AB
        jmp     L98F3

L9931:  jsr     clear_oam_buffer
        jsr     L9A1D
        lda     #$3E
        sta     $FD
L993B:  jsr     LC0AB
        dec     $FD
        bne     L993B
        jsr     clear_oam_buffer
L9945:  ldx     #$1F
L9947:  lda     L9BB3,x
        sta     $0356,x
        dex
        bpl     L9947
        lda     #$37
        sta     $FD
L9954:  ldx     #$0F
        lda     $FD
        and     #$08
        beq     L995E
        ldx     #$30
L995E:  stx     $0366
        jsr     LC0AB
        dec     $FD
        bpl     L9954
        ldx     $2A
        lda     L9DA8,x
        sta     $FD
        lda     #$3E
        sta     $FE
L9973:  lda     $FD
        sta     $00
        jsr     L9A63
        jsr     LC0AB
        dec     $FE
        bne     L9973
L9981:  lda     $1C
        and     #$03
        bne     L999A
        lda     #$28
        jsr     bank_switch_enqueue
        clc
        lda     $FD
        adc     #$04
        sta     $FD
        ldx     $2A
        cmp     L9DA9,x
        beq     L99A7
L999A:  lda     $FD
        sta     $00
        jsr     L9A63
        jsr     LC0AB
        jmp     L9981

L99A7:  lda     #$7D
        sta     $FE
L99AB:  lda     $FD
        sta     $00
        jsr     L9A63
        jsr     LC0AB
        dec     $FE
        bne     L99AB
        jsr     LA52D
        lda     #$00
        sta     $AE
        lda     #$0E
        jsr     LC05D
        rts


; =============================================================================
; Entity Update & Physics
; =============================================================================
update_animation_frame:  inc     $0681
        lda     $0681
        cmp     #$06
        bcc     L99E4
        lda     #$00
        sta     $0681
        inc     $0401
        lda     $0401
        cmp     #$04
        bcc     L99E4
        lda     #$01
        sta     $0401
L99E4:  rts

update_all_entities:  jsr     clear_oam_buffer; Loop over all entities, call update handler
        ldx     #$00
        stx     $00
L99EC:  stx     $2B
        jsr     entity_update_handler
        ldx     $2B
        inx
        cpx     #$03
        bne     L99EC
        rts

apply_gravity:  lda     $22             ; Apply downward acceleration to entity
        bne     L9A01
        lda     $AE
        bne     L9A1C
L9A01:  clc
        lda     $21
        adc     #$80
        sta     $21
        lda     $22
        adc     #$00
        cmp     #$F0
        bne     L9A16
        lda     #$02
        sta     $AE
        lda     #$00
L9A16:  sta     $22
        lda     $22
        bne     L9A1C
L9A1C:  rts

L9A1D:  lda     $AE
        bne     L9A2F
        sec
        lda     #$5F
        sbc     $22
        sta     $01
        lda     #$01
        sbc     #$00
        beq     L9A33
        rts

L9A2F:  lda     #$6F
        sta     $01
L9A33:  lda     #$05
        sta     $02
        ldx     #$00
L9A39:  clc
        lda     L9D6F,x
        adc     $01
        bcs     L9A5A
        cmp     #$F0
        bcs     L9A5A
        sta     $02EC,x
        lda     L9D70,x
        sta     $02ED,x
        lda     L9D71,x
        sta     $02EE,x
        lda     L9D72,x
        sta     $02EF,x
L9A5A:  inx
        inx
        inx
        inx
        dec     $02
        bne     L9A39
        rts

L9A63:  jsr     clear_oam_buffer
        ldx     #$23
L9A68:  lda     L9D8C,x
        sta     $0200,x
        dex
        bpl     L9A68
        lda     $00
        beq     L9AC7
        ldy     #$00
L9A77:  lda     L9DB7,y
        sta     $0224,y
        iny
        inx
        dec     $00
        bne     L9A77
        lda     $1C
        and     #$08
        bne     L9AC7
        lda     $2A
        cmp     #$0C
        bcs     L9AA1
        sec
        lda     $2A
        sbc     #$07
        asl     a
        asl     a
        tax
        lda     #$73
        sta     $0201,x
        lda     #$03
        sta     $0202,x
L9AA1:  lda     #$77
        sta     $0215
        sta     $0219
        lda     #$78
        sta     $021D
        sta     $0221
        lda     $2A
        cmp     #$0D
        bne     L9AC7
        lda     #$77
        sta     $02F5
        sta     $02E9
        lda     #$78
        sta     $02ED
        sta     $02F1
L9AC7:  rts

entity_update_handler:  ldy     $0400,x
        lda     L9BD3,y
        sta     $08
        lda     L9BDE,y
        sta     $09
        lda     $0460,x
        sta     $0A
        lda     $0440,x
        sta     $0B
        lda     $04A0,x
        sta     $0C
        ldy     #$00
        lda     ($08),y
        iny
        sta     $0D
        ldx     $00
L9AED:  clc
        lda     ($08),y
        adc     $0C
        sta     $0200,x
        iny
        lda     ($08),y
        sta     $0201,x
        iny
        lda     ($08),y
        sta     $0202,x
        iny
        clc
        lda     ($08),y
        adc     $0A
        sta     $01
        lda     $0B
        adc     #$00
        beq     L9B16
        lda     #$F8
        sta     $0200,x
        bne     L9B1F
L9B16:  lda     $01
        sta     $0203,x
        inx
        inx
        inx
        inx
L9B1F:  iny
        dec     $0D
        bne     L9AED
        stx     $00
        rts

L9B27:  ldx     #$1F
        lda     #$0F
L9B2B:  sta     $0356,x
        dex
        bpl     L9B2B
        lda     #$02
        sta     $AE
        jsr     LA51D
        jsr     L9A1D
        ldx     #$00
        stx     $FD
        lda     #$08
        sta     $FE
L9B43:  dec     $FE
        bne     L9B61
        lda     #$08
        sta     $FE
        ldx     $FD
        ldy     #$00
L9B4F:  lda     L9E87,x
        sta     $0356,y
        inx
        iny
        cpy     #$20
        bne     L9B4F
        cpx     #$60
        beq     L9B67
        stx     $FD
L9B61:  jsr     LC0AB
        jmp     L9B43

L9B67:  lda     #$11
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $FE
L9B70:  lda     #$A0
        sta     $FD
L9B74:  jsr     LC0AB
        dec     $FD
        bne     L9B74
        dec     $FE
        bne     L9B70
        jsr     clear_oam_buffer
        rts

L9B83:  .byte   $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
        .byte   $E8,$E8,$E8,$E8,$E8,$E8,$E8,$00
L9B93:  .byte   $0F,$20,$21,$11,$0F,$20,$10
L9B9A:  .byte   $00,$0F,$20,$26,$15,$0F,$17,$21
        .byte   $07,$0F,$16,$29,$09,$0F,$0F,$30
        .byte   $38,$0F,$0F,$30,$28,$0F,$0F,$12
        .byte   $2C
L9BB3:  .byte   $0F,$11,$11,$11,$0F,$11,$11,$11
        .byte   $0F,$11,$11,$11,$0F,$17,$11,$07
        .byte   $0F,$16,$29,$09,$0F,$0F,$30,$38
        .byte   $0F,$0F,$28,$30,$0F,$0F,$12,$2C
L9BD3:  .byte   $E9,$2A,$5B,$8C
        lda     $0FE6,x
        .byte   $0F,$50,$61,$6A
L9BDE:  .byte   $9B,$9C,$9C,$9C,$9C,$9C,$9D,$9D
        .byte   $9D,$9D,$9D,$10,$00,$48,$03,$08
        .byte   $00,$49,$03,$10,$00
        eor     #$43
        clc
        brk
        .byte   $48,$43,$20,$08,$4A,$03,$00,$08
        .byte   $4B,$03,$08,$08
        jmp     L1003

        .byte   $08,$4C,$43,$18,$08,$4B,$43,$20
        .byte   $08,$4A,$43,$28,$10,$4D,$03,$00
        .byte   $10,$4E,$03,$08,$10,$4F,$03,$10
        .byte   $10,$4F,$43,$18,$10,$4E,$43,$20
        .byte   $10,$4D,$43,$28,$0C,$00,$50,$02
        .byte   $00
        brk
        eor     ($02),y
        php
        brk
        .byte   $52,$02,$10,$00,$52,$42,$18,$00
        .byte   $51,$42
        jsr     L5000
        .byte   $42,$28,$08,$53,$02,$00,$08,$54
        .byte   $02,$08,$08,$55,$02,$10,$08,$55
        .byte   $42,$18,$08,$54,$42,$20,$08,$53
        .byte   $42,$28,$0C,$00,$56,$02,$00,$00
        .byte   $57,$02,$08,$00,$58,$02,$10,$00
        eor     $1802,y
        brk
        .byte   $5A,$02,$20,$00,$5B,$02,$28,$08
        .byte   $53,$02,$00,$08,$54,$02,$08,$08
        .byte   $55,$02,$10,$08,$55,$42,$18,$08
        .byte   $54,$42,$20,$08,$53,$42,$28,$0C
        .byte   $00,$5B,$42,$00,$00,$5A,$42,$08
        .byte   $00,$59,$42,$10,$00,$58,$42
        clc
        brk
        .byte   $57,$42,$20,$00,$56,$42,$28,$08
        .byte   $53,$02,$00,$08,$54,$02,$08,$08
        .byte   $55,$02,$10,$08,$55,$42,$18,$08
        .byte   $54,$42,$20,$08,$53,$42,$28,$0A
        .byte   $00,$69,$03,$00,$00,$40,$01,$08
        .byte   $00,$41,$01,$10,$00,$42,$01,$18
        .byte   $00,$69,$43,$20,$08,$6A,$03,$00
        .byte   $08,$43,$01,$08,$08,$44,$01,$10
        .byte   $08,$45,$01,$18,$08,$6A,$43,$20
        .byte   $0A,$00,$69,$03,$00,$00,$46,$01
        .byte   $08,$00,$47,$01,$10,$00,$42,$01
        .byte   $18,$00,$69,$43,$20,$08,$6A,$03
        .byte   $00,$08,$43,$01
        php
        php
        .byte   $44,$01,$10,$08,$45,$01,$18,$08
        .byte   $6A,$43,$20
        bpl     L9D19
        .byte   $5C,$03,$08,$08,$5D,$03,$10
        php
L9D19:  eor     $1843,x
        php
        .byte   $5C,$43
        jsr     L5E10
        .byte   $03,$08,$10,$5F,$03,$10,$10,$5F
        .byte   $43,$18,$10,$5E,$43,$20,$18,$60
        .byte   $02,$08,$18,$61,$02,$10,$18
        adc     ($42,x)
        clc
        clc
        rts

        .byte   $42,$20,$20,$62,$02,$08,$20,$63
        .byte   $02,$10,$20,$63,$42,$18,$20,$62
        .byte   $42,$20,$04
        bpl     L9DB7
        .byte   $03,$10,$10,$64,$43,$18,$18,$65
        .byte   $02,$10,$18,$65,$42,$18,$02,$10
        .byte   $66,$03,$14,$18,$67,$02,$14,$01
        .byte   $14,$68,$03,$14
L9D6F:  .byte   $00
L9D70:  .byte   $6B
L9D71:  .byte   $00
L9D72:  .byte   $60,$00,$6C,$00
        pla
        brk
        adc     $7000
        php
        .byte   $6E
L9D7D:  brk
        rts

        php
        .byte   $6F,$00,$68
L9D83:  .byte   $00,$00,$07,$08,$09
L9D88:  .byte   $18,$E9
L9D8A:  .byte   $00,$FF
L9D8C:  cpy     #$73
        .byte   $02,$10,$88,$73,$02,$40,$A0,$73
        .byte   $02,$60,$A8,$73,$02,$88
L9D9C:  bvs     L9E11
        .byte   $02,$98,$8C,$75,$02,$B4,$8C,$75
        .byte   $42,$BC
L9DA8:  .byte   $94
L9DA9:  ror     $02,x
        .byte   $B4
        sty     $76,x
        .byte   $42,$BC,$00,$30,$48,$5C,$7C,$98
        .byte   $D0
L9DB7:  cpy     #$71
        .byte   $03
        clc
        cpy     #$70
        .byte   $C3,$20,$B8,$72,$03,$20,$B0,$72
        .byte   $03,$20,$A8,$72,$03
        jsr     L72A0
        .byte   $03,$20,$98,$70,$03,$20,$98,$71
        .byte   $03,$28,$98,$70,$C3,$30,$90,$72
        .byte   $03,$30,$88,$70,$03,$30,$88,$71
        .byte   $03,$38,$88
        bvs     L9E2D
        pha
        bcc     L9E5D
        .byte   $83,$48,$90,$70,$43,$50,$98,$72
        .byte   $03,$50,$A0
        bvs     L9D7D
        bvc     L9D9C
        adc     ($03),y
        cli
        ldy     #$71
        .byte   $03,$68,$A0,$70,$43,$70,$A8,$70
        .byte   $83,$70,$A8,$71,$03,$78,$A8,$71
L9E11:  .byte   $03,$80,$A8,$70,$C3,$90,$A0,$72
        .byte   $03,$90,$98,$72,$03,$90,$90,$72
        .byte   $03,$90,$88,$72,$03,$90,$80,$70
        .byte   $03,$90,$80,$70
L9E2D:  .byte   $C3,$98,$78,$72,$03,$98,$70,$71
        .byte   $03,$A0,$70,$70,$43,$A8,$78,$72
        .byte   $03,$A8,$80,$72,$03,$A8,$88,$72
        .byte   $03,$A8,$90,$70,$83,$A8,$90,$71
        .byte   $03,$B0,$98,$72,$03,$B8,$A0,$72
        .byte   $03,$B8,$A8,$72,$03,$B8,$B0,$72
L9E5D:  .byte   $03,$B8,$B8,$72,$03,$B8,$C0,$72
        .byte   $03,$B8,$C8,$70,$83,$B8,$C8,$71
        .byte   $03,$C0,$C8,$71,$03,$C8,$C8,$71
        .byte   $03,$D0,$C4,$75,$02,$D8,$C4,$75
        .byte   $42,$E0,$CC,$76,$02,$D8,$CC,$76
        .byte   $42,$E0
L9E87:  .byte   $0F,$00,$01,$0F,$0F,$00,$0F,$0F
        .byte   $0F,$00,$06,$0F,$0F,$00
        ora     ($0F,x)
        .byte   $0F,$0F,$09,$0F,$0F,$0F,$00,$08
        .byte   $0F,$0F,$08,$00,$0F,$0F,$00,$0C
        .byte   $0F,$10,$11,$11,$0F,$10,$00,$00
        .byte   $0F,$10,$16,$05,$0F,$07,$11,$00
        .byte   $0F,$06
        ora     $0F00,y
        .byte   $0F,$10,$18,$0F,$0F,$18,$10,$0F
        .byte   $0F,$02,$1C,$0F
        jsr     L1121
        .byte   $0F,$20,$10,$00,$0F,$20,$26,$15
        .byte   $0F,$17,$21,$07,$0F,$16,$29,$09
        .byte   $0F,$0F,$30,$38,$0F,$0F,$28,$30
        .byte   $0F,$0F,$12,$2C
        lda     #$10
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001
        lda     #$0F
        jsr     LC05D
        jsr     reset_scroll_state
        lda     #$00
        sta     $BE
        lda     #$02
        jsr     LC644
        lda     #$20
        sta     $2006
        ldx     #$00
        stx     $2006
        txa
        ldy     #$04
L9F13:  sta     $2007
        inx
        bne     L9F13
        dey
        bne     L9F13
        lda     #$0F
        ldx     #$1F
L9F20:  sta     $0356,x
        dex
        bpl     L9F20
        lda     #$04
        sta     $00
        ldx     #$00
L9F2C:  ldy     LAE95,x
        inx
        lda     LAE95,x
        sta     $2006
        inx
        lda     LAE95,x
        sta     $2006
        inx
L9F3E:  lda     LAE95,x
        sta     $2007
        inx
        dey
        bne     L9F3E
        dec     $00
        bne     L9F2C
        jsr     clear_oam_buffer
        jsr     LA51D
        lda     #$FE
        jsr     bank_switch_enqueue
        lda     #$FF
        jsr     bank_switch_enqueue
        lda     #$1F
        sta     $FE
L9F60:  lda     #$0A
        sta     $FF
L9F64:  ldx     $FE
        lda     LAE54,x
        sta     $0357
        jsr     LC0AB
        lda     $27
        and     #$08
        beq     L9F78
        jmp     LA7B0

L9F78:  dec     $FF
        bne     L9F64
        dec     $FE
        bpl     L9F60
        lda     #$00
        sta     $47
        jsr     LA52D
        lda     #$00
        sta     $AE
        lda     #$07
        sta     $2A
        lda     #$00
        sta     $08
        lda     #$8A
        sta     $09
        lda     #$00
        sta     $1A
        sta     $1B
L9F9D:  jsr     LCA0B
        inc     $08
        inc     $1A
        jsr     LCA0B
        jsr     LA53C
        lda     $08
        and     #$3F
        bne     L9F9D
        lda     #$40
        sta     $08
        lda     #$8A
        sta     $09
        lda     #$00
        sta     $1A
        sta     $1B
L9FBE:  jsr     LCA0B
        clc
        lda     $0300
        adc     #$04
        sta     $0300
        clc
        lda     $0308
        adc     #$04
        sta     $0308
        jsr     LA53C
        lda     $08
        and     #$3F
        bne     L9FBE
        ldx     #$1F
        lda     #$0F
L9FE0:  sta     $0356,x
        dex
        bpl     L9FE0
        jsr     clear_oam_buffer
        jsr     LA51D
        ldx     #$0F
        lda     #$00
L9FF0:  sta     $0440,x
        sta     $0400,x
        dex
        bpl     L9FF0
        lda     #$80
        sta     $04C0
        lda     #$00
        sta     $04A0
        lda     #$28
        sta     $04A1
        lda     #$00
        sta     $04C1
        lda     #$00
        sta     $04A2
        lda     #$47
        sta     $04A3
        lda     #$02
        sta     $0402
        sta     $0403
        lda     #$27
        sta     $04A5
        lda     #$6F
        sta     $04A6
        lda     #$01
        sta     $0405
        sta     $0406
        lda     #$80
        sta     $0660
        lda     #$00
        sta     $0640
        lda     #$00
        sta     $AE
        lda     #$00
        sta     $22
        lda     #$00
        sta     $FD
        lda     #$08
LA049:  sta     $FE
LA04B:  dec     $FE
        bne     LA069
        lda     #$08
        sta     $FE
        ldx     $FD
        ldy     #$00
LA057:  lda     LAA4F,x
        sta     $0356,y
        inx
        iny
        cpy     #$20
        bne     LA057
        cpx     #$60
        beq     LA078
        stx     $FD
LA069:  jsr     LA6F7
        jsr     LC0AB
        lda     $27
        and     #$08
        beq     LA04B
        jmp     LA7B0

LA078:  lda     #$0E
        jsr     bank_switch_enqueue
        lda     #$00
        sta     $FD
        sta     $C8
LA083:  lda     $FD
        cmp     #$36
        bne     LA089
LA089:  jsr     LA553
        lda     #$23
        sta     $03B6
        lda     #$03
        sta     $03B7
        jsr     LC0AB
        lda     $27
        and     #$08
        beq     LA0A2
        .byte   $4C
LA0A0:  bcs     LA049
LA0A2:  jsr     LA553
        lda     #$23
        sta     $03B6
        lda     #$43
        sta     $03B7
        lda     #$1F
        sta     $FE
        lda     #$0A
        sta     $FF
LA0B7:  dec     $FF
        bne     LA0CB
        lda     #$0A
        sta     $FF
        ldx     $FE
        lda     LAE54,x
        sta     $035B
        dec     $FE
        bmi     LA0D7
LA0CB:  jsr     LC0AB
        lda     $27
        and     #$08
        beq     LA0B7
        jmp     LA7B0

LA0D7:  lda     $FD
        cmp     #$0E
        bne     LA083
        lda     #$02
        sta     $AE
        lda     #$F0
        sta     $22
LA0E5:  sec
        lda     $21
        sbc     #$80
        sta     $21
        lda     $22
        sbc     #$00
        sta     $22
        bcc     LA10D
        cmp     #$40
        bcs     LA0FB
        jsr     LA57C
LA0FB:  jsr     LA61B
        jsr     LA6F7
        jsr     LC0AB
        lda     $27
        and     #$08
        beq     LA0E5
        jmp     LA7B0

LA10D:  lda     #$F0
        sta     $22
        lda     #$00
        sta     $21
        sta     $AE
LA117:  sec
        lda     $21
        sbc     #$80
        sta     $21
        lda     $22
        sbc     #$00
        sta     $22
        cmp     #$C0
        beq     LA13A
        jsr     LA61B
        jsr     LA6F7
        jsr     LC0AB
        lda     $27
        and     #$08
        beq     LA117
        jmp     LA7B0

LA13A:  ldx     #$0F
LA13C:  lda     LAAAF,x
        sta     $0356,x
        dex
        bpl     LA13C
        lda     #$00
        sta     $0410
        lda     #$08
        sta     $0690
        lda     #$FF
        sta     $0450
        lda     #$B7
        sta     $04B0
LA159:  sec
        lda     $22
        sbc     #$02
        sta     $22
        jsr     LA61B
        lda     $22
        beq     LA17C
        jsr     LA6F7
        jsr     LA5F5
        jsr     LA75F
        jsr     LC0AB
        lda     $27
        and     #$08
        beq     LA159
        jmp     LA7B0

LA17C:  lda     #$50
        sta     $FD
        lda     #$00
        sta     $03B7
        sta     $FE
        lda     #$10
        sta     $03B6
        lda     #$B0
        sta     $FF
LA190:  jsr     LA5F5
        jsr     LA6F7
        jsr     LA75F
        jsr     LC747
        jsr     LC0AB
        clc
        lda     $03B7
        adc     #$20
        sta     $03B7
        lda     $03B6
        adc     #$00
        sta     $03B6
        clc
        lda     $FE
        adc     #$20
        sta     $FE
        lda     $FF
        adc     #$00
        sta     $FF
        dec     $FD
        bne     LA190
        lda     #$20
        sta     $FD
LA1C5:  jsr     LA5F5
        jsr     LA6F7
        jsr     LA75F
        jsr     LC0AB
        dec     $FD
        bne     LA1C5
        ldx     #$0F
LA1D7:  lda     LAABF,x
        sta     $0356,x
        dex
        bpl     LA1D7
LA1E0:  lda     #$0D
        jsr     bank_switch_enqueue
        lda     #$0B
        sta     $C1
        lda     #$00
        sta     $C0
        sta     $CB
LA1EF:  lda     $27
        and     #$08
        bne     LA245
        jsr     LA6F7
        jsr     LA5F5
        jsr     LA75F
        ldx     #$02
LA200:  lda     LA2C1,x
        sta     $0281,x
        dex
        bpl     LA200
        ldx     $CB
        ldy     #$F8
        lda     $1C
        and     #$08
        beq     LA216
        ldy     LA2C4,x
LA216:  sty     $0280
        lda     $27
        and     #$34
        beq     LA231
        txa
        eor     #$01
        sta     $CB
        lda     #$2F
        jsr     bank_switch_enqueue
        lda     #$0B
        sta     $C1
        lda     #$00
        sta     $C0
LA231:  jsr     LC0AB
        sec
        lda     $C0
        sbc     #$01
        sta     $C0
        lda     $C1
        sbc     #$00
        sta     $C1
        bcs     LA1EF
        inc     $BE
LA245:  lda     #$FF
        jsr     bank_switch_enqueue
        lda     #$19
        sta     $FD
LA24E:  lda     $1C
        and     #$01
        bne     LA263
        lda     $FD
        cmp     #$04
        bne     LA25F
        lda     #$3A
        jsr     bank_switch_enqueue
LA25F:  dec     $FD
        bmi     LA277
LA263:  ldx     $FD
        lda     LAE7B,x
        sta     $0410
        jsr     LA6F7
        jsr     LA75F
        jsr     LC0AB
        jmp     LA24E

LA277:  lda     #$0A
        sta     $0410
        sec
        lda     $04B0
        sbc     #$08
        sta     $04B0
        lda     $0450
        sbc     #$00
        sta     $0450
        beq     LA296
        lda     $04B0
        cmp     #$F0
        bcc     LA2A2
LA296:  jsr     LA6F7
        jsr     LA75F
        jsr     LC0AB
        jmp     LA277

LA2A2:  jsr     LA6F7
        lda     #$3E
        sta     $FD
LA2A9:  jsr     LC0AB
        dec     $FD
        bne     LA2A9
        jsr     LA52D
        lda     #$00
        sta     $AE
        lda     #$0E
        jsr     LC05D
        lda     $BE
        beq     LA2C6
        rts

LA2C1:  .byte   $A2,$01,$30
LA2C4:  tya
        tay
LA2C6:  lda     #$03
        jsr     LC644
        lda     #$05
        sta     $2A
        lda     #$40
        sta     $08
        lda     #$8D
        sta     $09
        jsr     LA87E
        lda     #$80
        sta     $08
        lda     #$8D
        sta     $09
        jsr     LA87E
        ldx     #$00
LA2E7:  lda     LAF39,x
        sta     $2006
        lda     LAF3A,x
        sta     $2006
        inx
        inx
        ldy     LAF39,x
        inx
LA2F9:  lda     LAF39,x
        sta     $2007
        inx
        dey
        bne     LA2F9
        cpx     #$19
        bne     LA2E7
        lda     #$10
        jsr     bank_switch_enqueue
        lda     #$01
        jsr     LA9B2
LA311:  lda     #$00
        sta     $FD
        sta     $9A
        sta     $9B
LA319:  ldx     #$03
LA31B:  lda     LAFC7,x
        sta     $0200,x
        dex
        bpl     LA31B
        lda     $1C
        and     #$08
        bne     LA335
        ldx     #$60
        lda     $FD
        beq     LA332
        ldx     #$70
LA332:  stx     $0200
LA335:  lda     $27
        and     #$3C
        beq     LA34A
        and     #$08
        bne     LA350
        lda     #$2F
        jsr     bank_switch_enqueue
        lda     $FD
        eor     #$01
        sta     $FD
LA34A:  jsr     LC0AB
        jmp     LA319

LA350:  lda     $FD
        bne     LA357
        jmp     LA519

LA357:  jsr     LA898
        jsr     clear_oam_buffer
        jsr     LA9CC
        ldx     #$2F
LA362:  lda     LAFCB,x
        sta     $0200,x
        dex
        bpl     LA362
        lda     #$00
        ldx     #$18
LA36F:  sta     $0420,x
        dex
        bpl     LA36F
        jsr     LAA25
        jsr     LA8D4
        lda     #$00
        sta     $06A0
        lda     #$09
        sta     $0680
        lda     #$00
        sta     $FE
LA389:  lda     $27
        and     #$F0
        bne     LA3A7
        lda     $23
        and     #$F0
        beq     LA3DA
        lda     $25
        cmp     $23
        bne     LA3DA
        inc     $FE
        lda     $FE
        cmp     #$18
        bcc     LA3DE
        lda     #$08
        sta     $FE
LA3A7:  lda     #$2F
        jsr     bank_switch_enqueue
        ldx     $06A0
        lda     $23
        and     #$C0
        beq     LA3C5
        and     #$80
        beq     LA3BF
        lda     LB02D,x
        jmp     LA3D4

LA3BF:  lda     LB046,x
        jmp     LA3D4

LA3C5:  lda     $23
        and     #$10
        beq     LA3D1
        lda     LB05F,x
        jmp     LA3D4

LA3D1:  lda     LB078,x
LA3D4:  sta     $06A0
        jmp     LA3DE

LA3DA:  lda     #$00
        sta     $FE
LA3DE:  lda     $27
        and     #$03
        beq     LA40C
        lda     $27
        .byte   $AE
        .byte   $A0
LA3E8:  asl     $29
        ora     ($F0,x)
        .byte   $14
        lda     $0420,x
        bne     LA40C
        lda     #$42
        jsr     bank_switch_enqueue
        inc     $0420,x
        dec     $0680
        beq     LA415
        bne     LA40C
        lda     $0420,x
        beq     LA40C
        dec     $0420,x
        inc     $0680
LA40C:  jsr     LA927
        jsr     LC0AB
        jmp     LA389

LA415:  jsr     LA927
        lda     #$0F
        sta     $036C
        ldx     #$00
LA41F:  lda     $0420,x
        bne     LA429
        inx
        cpx     #$04
        bne     LA41F
LA429:  stx     $04
        txa
        clc
        adc     #$05
        tax
        lda     #$00
        sta     $01
        sta     $02
        sta     $03
LA438:  lda     $0420,x
        beq     LA44E
        ldy     $01
        lda     LB0A9,y
        pha
        lda     LB0BD,y
        tay
        pla
        ora     $02,y
        sta     $02,y
LA44E:  inx
        cpx     #$19
        bne     LA455
        ldx     #$05
LA455:  inc     $01
        lda     $01
        cmp     #$14
        bne     LA438
        lda     $02
        ora     $03
        cmp     #$FF
        bne     LA468
        jmp     LA4AD

LA468:  ldx     #$02
        jsr     LA98B
        lda     #$7D
        sta     $FD
LA471:  jsr     LC0AB
        dec     $FD
        bne     LA471
        ldx     #$03
        jsr     LA98B
        jsr     LA898
        jsr     clear_oam_buffer
        jsr     LAA09
        jsr     LA8D4
        lda     #$7D
        sta     $FD
LA48D:  jsr     LC0AB
        dec     $FD
        bne     LA48D
        jsr     LA898
        ldx     #$00
        jsr     LA98B
        jsr     LC0AB
        ldx     #$01
        jsr     LA98B
        jsr     LC0AB
        jsr     LA8D4
        jmp     LA311

LA4AD:  lda     $02
        sta     $9A
        and     #$03
        sta     $9B
        lda     $9A
        and     #$20
        lsr     a
        lsr     a
        lsr     a
        ora     $9B
        sta     $9B
        lda     $04
        sta     $A7
        lda     #$C0
        sta     $FD
        lda     #$8D
        sta     $FE
        jsr     LA9EA
        lda     #$3C
        sta     $FD
LA4D3:  jsr     LC0AB
        dec     $FD
        bne     LA4D3
        jsr     LA898
        jsr     clear_oam_buffer
        jsr     LA9CC
        lda     $9A
        sta     $01
        lda     $9B
        sta     $02
        ldx     #$00
        beq     LA4FB
LA4EF:  lsr     $02
        ror     $01
        bcs     LA4FB
        inx
        inx
        inx
        inx
        bne     LA507
LA4FB:  ldy     #$04
LA4FD:  lda     LB0D1,x
        sta     $0200,x
        inx
        dey
        bne     LA4FD
LA507:  cpx     #$30
        bne     LA4EF
        jsr     LA8D4
        lda     #$7D
        sta     $FD
LA512:  jsr     LC0AB
        dec     $FD
        bne     LA512
LA519:  jsr     LA52D
        rts

LA51D:  lda     $F8
        ora     #$18
        sta     $F8
        lda     $F7
        ora     #$80
        sta     $F7
        sta     $2000
        rts

LA52D:  lda     #$10
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001
        rts

LA53C:  lda     $08
        pha
        lda     $09
        pha
        lda     $1B
        jsr     ppu_buffer_transfer
        clc
        pla
        sta     $09
        pla
        sta     $08
        inc     $08
        inc     $1A
        rts

LA553:  ldy     $FD
        ldx     #$00
LA557:  lda     #$46
        sta     $C9
        lda     #$AD
        clc
        adc     $C8
        sta     $CA
        lda     ($C9),y
        sta     $03B8,x
        tya
        clc
        adc     #$01
        tay
        lda     $C8
        adc     #$00
        sta     $C8
        inx
        cpx     #$1B
        bne     LA557
        stx     $47
        sty     $FD
        rts

LA57C:  sta     $00
        lda     $00
        and     #$01
        beq     LA5A8
        lda     $00
        eor     #$3F
        tax
        lda     LB2F1,x
        sta     $03B9
        lda     LB2F2,x
        sta     $03B8
        lda     #$23
        sta     $03B6
        ldx     $00
        dex
        txa
        ora     #$C0
        sta     $03B7
        lda     #$02
        sta     $47
        rts

LA5A8:  lda     $00
        lsr     a
        cmp     #$1E
        bcc     LA5B0
        rts

LA5B0:  asl     a
        asl     a
        asl     a
        asl     a
        rol     $08
        asl     a
        rol     $08
        sta     $03B7
        lda     $08
        and     #$03
        ora     #$20
        sta     $03B6
        lda     $00
        lsr     a
        eor     #$1F
        sta     $09
        lda     #$00
        lsr     $09
        ror     a
        lsr     $09
        ror     a
        lsr     $09
        ror     a
        sta     $08
        clc
        lda     $08
        adc     #$F1
        sta     $08
        lda     $09
        adc     #$B2
        sta     $09
        ldy     #$1F
LA5E8:  lda     ($08),y
        sta     $03B8,y
        dey
        bpl     LA5E8
        lda     #$20
        sta     $47
        rts

LA5F5:  dec     $0690
        bne     LA60E
        lda     #$05
        sta     $0690
        inc     $0410
        lda     $0410
        cmp     #$02
        bne     LA60E
        lda     #$00
        sta     $0410
LA60E:  rts

        .byte   $A2,$14
LA611:  lda     LAACF,x
        sta     $02EC,x
        dex
        bpl     LA611
        rts

LA61B:  ldx     #$02
LA61D:  stx     $2B
        lda     $0400,x
        beq     LA64D
        clc
        lda     $04C0,x
        adc     $0660
        sta     $04C0,x
        lda     $04A0,x
        adc     $0640
        sta     $04A0,x
        lda     $0440,x
        adc     #$00
        sta     $0440,x
        bne     LA64D
        lda     $04A0,x
        cmp     #$E8
        bcc     LA64D
        lda     #$00
        sta     $0400,x
LA64D:  ldx     $2B
        inx
        cpx     #$0F
        bne     LA61D
        lda     $AE
        bne     LA65E
        lda     $22
        cmp     #$A8
        bcc     LA6A6
LA65E:  sec
        lda     $04C0
        sbc     $0660
        sta     $04C0
        lda     $04A0
        sbc     $0640
        sta     $04A0
        bcs     LA682
        lda     #$01
        jsr     LA6D3
        lda     #$00
        sta     $04C0
        lda     #$48
        sta     $04A0
LA682:  sec
        lda     $04C1
        sbc     $0660
        sta     $04C1
        lda     $04A1
        sbc     $0640
        sta     $04A1
        bcs     LA6A6
        lda     #$02
        jsr     LA6D3
        lda     #$00
        sta     $04C1
        lda     #$48
        sta     $04A1
LA6A6:  clc
        lda     $0660
        adc     #$02
        sta     $0660
        lda     $0640
        adc     #$00
        sta     $0640
        cmp     #$02
        bne     LA6C0
        lda     #$00
        sta     $0660
LA6C0:  clc
        lda     $04B0
        adc     $0640
        sta     $04B0
        lda     $0450
        adc     #$00
        sta     $0450
        rts

LA6D3:  sta     $00
        ldx     #$02
LA6D7:  lda     $0400,x
        beq     LA6E2
        inx
        cpx     #$0F
        bne     LA6D7
        rts

LA6E2:  lda     $00
        sta     $0400,x
        lda     #$FF
        sta     $0440,x
        lda     #$E0
        sta     $04A0,x
        lda     #$00
        sta     $04C0,x
        rts

LA6F7:  jsr     clear_oam_buffer
        lda     #$00
        sta     $00
        ldx     #$02
LA700:  stx     $2B
        lda     $0400,x
        beq     LA757
        ldy     $04A0,x
        sty     $08
        ldy     $0440,x
        sty     $09
        ldx     #$00
        ldy     #$0C
        cmp     #$01
        beq     LA71D
        ldy     #$04
        ldx     #$30
LA71D:  sty     $02
        ldy     $00
LA721:  clc
        lda     $08
        adc     LAAE3,x
        sta     $0200,y
        lda     $09
        adc     #$00
        beq     LA737
        lda     #$F8
        sta     $0200,y
        bne     LA74D
LA737:  lda     LAAE4,x
        sta     $0201,y
        lda     LAAE5,x
        sta     $0202,y
        lda     LAAE6,x
        sta     $0203,y
        iny
        iny
        iny
        iny
LA74D:  inx
        inx
        inx
        inx
        dec     $02
        bne     LA721
        sty     $00
LA757:  ldx     $2B
        inx
        cpx     #$0F
        bne     LA700
        rts

LA75F:  ldx     $0410
        lda     LAB23,x
        sta     $08
        lda     LAB30,x
        sta     $09
        ldy     #$00
        lda     ($08),y
        sta     $01
        ldx     $00
        beq     LA7AF
        iny
LA777:  clc
        lda     $04B0
        adc     ($08),y
        sta     $0200,x
        lda     $0450
        adc     #$00
        beq     LA792
        iny
        iny
        iny
        iny
        lda     #$F8
        sta     $0200,x
        bne     LA7A5
LA792:  iny
        lda     ($08),y
        sta     $0201,x
        iny
        lda     ($08),y
        sta     $0202,x
        iny
        lda     ($08),y
        sta     $0203,x
        iny
LA7A5:  inx
        inx
        inx
        inx
        beq     LA7AF
        dec     $01
        bne     LA777
LA7AF:  rts

LA7B0:  jsr     LA52D
        lda     #$50
        sta     $FD
        lda     #$00
        sta     $03B7
        sta     $FE
        lda     #$10
        sta     $03B6
        lda     #$B0
        sta     $FF
LA7C7:  jsr     LC747
        jsr     ppu_scroll_column_update
        clc
        lda     $03B7
        adc     #$20
        sta     $03B7
        lda     $03B6
        adc     #$00
        sta     $03B6
        clc
        lda     $FE
        adc     #$20
        sta     $FE
        lda     $FF
        adc     #$00
        sta     $FF
        dec     $FD
        bne     LA7C7
        lda     #$D1
        sta     $08
        lda     #$B6
        sta     $09
        lda     #$20
        sta     $2006
        ldy     #$00
        sty     $2006
        ldx     #$1E
LA803:  ldy     #$00
LA805:  lda     ($08),y
        sta     $2007
        iny
        cpy     #$20
        bne     LA805
        sec
        lda     $08
        sbc     #$20
        sta     $08
        lda     $09
        sbc     #$00
        sta     $09
        dex
        bne     LA803
        ldy     #$3F
LA821:  lda     LB2F1,y
        sta     $2007
        dey
        bpl     LA821
        ldx     #$1F
LA82C:  lda     LAA8F,x
        sta     $0356,x
        dex
        bpl     LA82C
        ldx     #$0F
LA837:  lda     LAABF,x
        sta     $0356,x
        dex
        bpl     LA837
        ldx     #$1F
        lda     #$00
LA844:  sta     $0440,x
        sta     $0400,x
        dex
        bpl     LA844
        lda     #$77
        sta     $04B0
        lda     #$00
        sta     $0410
        lda     #$08
        sta     $0690
        lda     #$01
        sta     $0402
        lda     #$CC
        sta     $04A2
        lda     #$02
        sta     $0403
        lda     #$A4
        sta     $04A3
        jsr     LA51D
        lda     #$00
        sta     $27
        sta     $22
        sta     $AE
        jmp     LA1E0

LA87E:  lda     #$00
        sta     $1A
        sta     $1B
LA884:  jsr     LCA0B
        inc     $08
        inc     $1A
        jsr     LCA0B
        jsr     LA53C
        lda     $08
        and     #$3F
        bne     LA884
        rts

LA898:  lda     #$04
        sta     $FD
LA89C:  lda     $1C
        and     #$03
        bne     LA8A9
        jsr     LA8B0
        dec     $FD
        bmi     LA8AF
LA8A9:  jsr     LC0AB
        jmp     LA89C

LA8AF:  rts

LA8B0:  ldx     #$07
        lda     #$04
        jsr     LA8BF
        ldx     #$1F
        lda     #$0F
        jsr     LA8BF
        rts

LA8BF:  sta     $00
LA8C1:  sec
        lda     $0356,x
        sbc     #$10
        bpl     LA8CB
        lda     #$0F
LA8CB:  sta     $0356,x
        dex
        cpx     $00
        bne     LA8C1
        rts

LA8D4:  lda     #$04
        sta     $FD
LA8D8:  lda     $1C
        and     #$03
        bne     LA8E5
        jsr     LA8EC
        dec     $FD
        bmi     LA8EB
LA8E5:  jsr     LC0AB
        jmp     LA8D8

LA8EB:  rts

LA8EC:  ldx     #$07
        ldy     #$07
        lda     #$04
        jsr     LA8FF
        ldx     #$1F
        ldy     #$1F
        lda     #$0F
        jsr     LA8FF
        rts

LA8FF:  sta     $01
LA901:  lda     $0356,x
        cmp     #$0F
        bne     LA910
        lda     LAEF9,y
        and     #$0F
        jmp     LA91D

LA910:  clc
        lda     $0356,x
        adc     #$10
        cmp     LAEF9,y
        beq     LA91D
        bcs     LA920
LA91D:  sta     $0356,x
LA920:  dey
        dex
        cpx     $01
        bne     LA901
        rts

LA927:  ldx     $06A0
        lda     LAFFB,x
        sta     $09
        lda     LB014,x
        sta     $08
        ldx     #$0F
LA936:  clc
        lda     LB099,x
        adc     $08
        sta     $0230,x
        dex
        lda     LB099,x
        sta     $0230,x
        dex
        lda     LB099,x
        sta     $0230,x
        dex
        clc
        lda     LB099,x
        adc     $09
        sta     $0230,x
        dex
        bpl     LA936
        lda     $1C
        lsr     a
        and     #$07
        tax
        lda     LB091,x
        sta     $036C
        clc
        lda     $0680
        adc     #$24
        sta     $022D
        ldx     #$00
        ldy     #$40
LA973:  lda     $0420,x
        bne     LA97C
        lda     #$F8
        bne     LA97E
LA97C:  lda     #$3F
LA97E:  sta     $0201,y
        iny
        iny
        iny
        iny
        inx
        cpx     #$19
        bne     LA973
        rts

LA98B:  lda     LAFBD,x
        tax
        lda     LAF39,x
        sta     $03B6
        inx
        lda     LAF39,x
        sta     $03B7
        inx
        lda     LAF39,x
        sta     $47
        inx
        ldy     #$00
LA9A5:  lda     LAF39,x
        sta     $03B8,y
        inx
        iny
        cpy     $47
        bne     LA9A5
        rts

LA9B2:  sta     $20
        lda     #$00
        sta     $1F
        sta     $22
        ldx     #$21
LA9BC:  lda     LAEF7,x
        sta     $0354,x
        dex
        bpl     LA9BC
        jsr     clear_oam_buffer
        jsr     LA51D
        rts

LA9CC:  clc
        lda     $1F
        adc     #$08
        sta     $1F
        php
        lda     $20
        adc     #$00
        sta     $20
        plp
        beq     LA9E9
        jsr     LC0AB
        jsr     LC0AB
        jsr     LC0AB
        jmp     LA9CC

LA9E9:  rts

LA9EA:  lda     #$00
        sta     $1B
        sta     $1A
LA9F0:  lda     $FD
        sta     $08
        lda     $FE
        sta     $09
        jsr     LCA0B
        inc     $FD
        inc     $1A
        jsr     LC0AB
        lda     $FD
        and     #$3F
        bne     LA9F0
        rts

LAA09:  sec
        lda     $1F
        sbc     #$08
        sta     $1F
        beq     LAA24
        lda     $20
        sbc     #$00
        sta     $20
        jsr     LC0AB
        jsr     LC0AB
        jsr     LC0AB
        jmp     LAA09

LAA24:  rts

LAA25:  ldx     #$00
        ldy     #$40
LAA29:  clc
        lda     LAFFB,x
        adc     #$04
        sta     $0200,y
        iny
        lda     #$0F
        sta     $0200,y
        iny
        lda     #$00
        sta     $0200,y
        iny
        clc
        lda     LB014,x
        adc     #$04
        sta     $0200,y
        iny
        inx
        cpx     #$19
        bne     LAA29
        rts

LAA4F:  .byte   $0F,$0F,$0F,$04,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$07,$0F,$0F,$0F,$00
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$30,$38
        .byte   $0F,$0F,$0C,$00,$0F,$0F,$0F,$00
        .byte   $0F,$00,$03,$14,$0F,$0F,$01,$00
        .byte   $0F,$00,$04,$17,$0F,$00,$00,$10
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$30,$38
        .byte   $0F,$10,$1C,$01,$0F,$00,$00,$10
LAA8F:  .byte   $0F,$03,$13,$24,$0F,$0F,$11,$0C
        .byte   $0F,$04,$14,$27,$0F,$00,$10,$30
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$30,$38
        .byte   $0F,$30,$2C
        ora     ($0F),y
        brk
        .byte   $10,$30
LAAAF:  .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0F,$00,$10,$30
LAABF:  rol     $15
        jsr     L0F06
        bmi     LAAF2
        ora     $26,x
        and     ($20,x)
        .byte   $0B,$0F,$00,$10,$30
LAACF:  .byte   $2F,$3C,$02,$C0,$37,$3D,$02
        cpy     #$3F
        .byte   $3B,$02,$C0,$3F,$3A,$02,$B8,$3F
        .byte   $39,$02,$B0
LAAE3:  .byte   $00
LAAE4:  .byte   $30
LAAE5:  .byte   $02
LAAE6:  .byte   $C0,$00
        and     ($02),y
        iny
        php
        .byte   $32,$02,$C0,$08,$33,$02
LAAF2:  iny
        bpl     LAB29
        .byte   $02,$C0,$10,$35,$02,$C8,$00,$30
        .byte   $02,$E0
        brk
        and     ($02),y
        inx
        php
        .byte   $32,$02,$E0,$08,$33,$02,$E8,$10
        .byte   $34,$02,$E0,$10,$35,$02,$E8,$00
        .byte   $36,$03,$98,$08,$37,$03,$98,$10
        .byte   $37,$03,$98,$18,$38,$03,$98
LAB23:  .byte   $3D,$6A,$97,$C8,$F9,$2E
LAB29:  .byte   $57,$80,$A9,$D2,$FB,$0C,$35
LAB30:  .byte   $AB,$AB,$AB,$AB,$AB,$AC,$AC,$AC
        .byte   $AC,$AC,$AC,$AD,$AD,$0B,$00,$00
        .byte   $01
        iny
        brk
        .byte   $01,$01,$D0,$00,$02,$01,$D8,$08
        .byte   $03,$00,$C8,$08,$04,$00,$D0,$08
        .byte   $05,$00,$D8,$08,$1F,$01,$C8,$08
        jsr     LD001
        bpl     LAB66
        brk
        .byte   $C8,$10,$07,$00,$D0
LAB66:  bpl     LAB70
        brk
        .byte   $D8,$0B,$00,$09,$01,$C8,$00
LAB70:  asl     a
        ora     ($D0,x)
        brk
        .byte   $0B,$01,$D8,$08,$03,$00,$C8,$08
        .byte   $04,$00,$D0,$08,$05,$00,$D8,$08
        .byte   $1F,$01,$C8,$08
        jsr     LD001
        bpl     LAB93
        brk
        .byte   $C8,$10,$07,$00,$D0
LAB93:  bpl     LAB9D
        brk
        .byte   $D8,$0C,$00,$0C,$01,$C8,$00
LAB9D:  ora     LD001
        brk
        .byte   $02,$01,$D8,$00,$21,$00,$D0,$08
        .byte   $03
        brk
        iny
        php
        .byte   $04,$00,$D0,$08
        ora     $00
        cld
        php
        .byte   $23,$01,$C8,$08
        bit     $01
        bne     LABCD
        asl     $00
        iny
        bpl     LABC9
        brk
        .byte   $D0,$10,$08,$00,$D8,$0C
LABC9:  .byte   $00,$0C,$01,$C8
LABCD:  .byte   $00,$0E,$01,$D0,$00,$02,$01,$D8
        .byte   $00,$22,$00,$D0,$08,$03,$00,$C8
        .byte   $08,$04,$00,$D0,$08
        ora     $00
        cld
        php
        .byte   $23,$01,$C8,$08
        bit     $01
        bne     LABFE
        asl     $00
        iny
        bpl     LABFA
        brk
        .byte   $D0,$10,$08,$00,$D8,$0D
LABFA:  .byte   $00,$0F,$01,$C8
LABFE:  .byte   $00,$10,$01,$D0
        brk
        ora     ($01),y
        cld
        brk
        .byte   $25,$00,$C8,$00,$26,$00,$D0,$08
        .byte   $03,$00,$C8,$08,$04,$00,$D0,$08
        ora     $00
        cld
        php
        .byte   $1F,$01,$C8,$08
        jsr     LD001
        bpl     LAC2A
        brk
        .byte   $C8,$10,$07,$00,$D0
LAC2A:  bpl     LAC34
        brk
        .byte   $D8,$0A,$00,$12,$00,$C8,$00
LAC34:  .byte   $13,$00,$D0,$00,$14,$00,$D8,$08
        .byte   $03,$00,$C8,$08,$15,$00,$D0,$08
        .byte   $05,$00,$D8,$10,$06,$00,$C8,$10
        .byte   $07,$00,$D0
        bpl     LAC59
        brk
        .byte   $D8,$06,$27,$01,$CF,$0A,$00
LAC59:  .byte   $12,$00,$C8,$00,$16,$00,$D0,$00
        .byte   $17,$00,$D8,$08,$03,$00,$C8,$08
        .byte   $18,$00,$D0,$08,$19,$00,$D8,$10
        .byte   $06,$00,$C8,$10,$07,$00,$D0
        bpl     LAC82
        brk
        .byte   $D8,$06
        plp
        ora     ($CF,x)
        asl     a
        brk
LAC82:  .byte   $12,$00,$C8,$00,$1A,$00,$D0,$00
        .byte   $17,$00,$D8,$08,$03,$00,$C8,$08
        .byte   $1B,$00,$D0,$08,$05,$00,$D8,$10
        .byte   $06,$00,$C8,$10,$07,$00,$D0
        bpl     LACAB
        brk
        .byte   $D8,$06
        plp
        ora     ($CF,x)
        asl     a
        brk
LACAB:  .byte   $1C,$00,$C8,$00,$1D,$00,$D0,$00
        .byte   $17,$00,$D8,$08,$03,$00,$C8,$08
        .byte   $18,$00,$D0,$08,$05,$00,$D8,$10
        .byte   $06,$00,$C8,$10,$07,$00,$D0
        bpl     LACD4
        brk
        .byte   $D8,$06
        plp
        ora     ($CF,x)
        asl     a
        brk
LACD4:  .byte   $1C,$00,$C8,$00,$1E,$00,$D0,$00
        .byte   $17,$00,$D8,$08
LACE0:  .byte   $03,$00,$C8,$08,$18,$00,$D0,$08
        .byte   $05,$00,$D8,$10,$06,$00,$C8,$10
        .byte   $07,$00,$D0
        bpl     LACFD
        brk
        .byte   $D8,$06
        plp
        ora     ($CF,x)
        .byte   $04,$F8
LACFD:  rol     a
        brk
        .byte   $D0
        brk
        rol     a
        brk
        .byte   $D0
        php
        rol     a
        brk
        .byte   $D0,$10,$2A,$00,$D0,$0A,$F8,$2F
        .byte   $00,$D0,$00
        bit     $C800
        brk
        .byte   $2D,$00,$D0,$00,$2C,$40,$D8,$08
        .byte   $2C,$00,$C8,$08,$2D,$00,$D0,$08
        .byte   $2C,$40,$D8,$10,$2B,$00,$C8,$10
        .byte   $2E,$00,$D0,$10,$2B,$40,$D8,$04
        .byte   $08,$2F,$00,$D0,$10,$2B,$00,$C8
        .byte   $10,$2E,$00,$D0
        bpl     LAD6F
        rti

        .byte   $D8,$00,$00,$00,$C9,$CE,$00,$D4
        .byte   $C8,$C5,$00,$D9,$C5,$C1,$D2,$00
        .byte   $CF
        dec     $00
        ldx     #$A0
        ldy     #$D8
        cmp     a:$00,x
        brk
        .byte   $00,$C1,$00,$D3,$D5,$D0,$C5,$D2
        .byte   $00,$D2,$CF,$C2,$CF,$D4
        brk
LAD6F:  dec     $CDC1
        cmp     $C4
        brk
        .byte   $CD,$C5,$C7,$C1,$CD,$C1,$CE,$00
        .byte   $00,$00,$00,$00,$00,$00,$D7,$C1
        .byte   $D3,$00,$C3,$D2,$C5,$C1,$D4,$C5
        .byte   $C4,$DC,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$C4,$D2,$DC,$CC,$C9
        .byte   $C7,$C8,$D4,$00,$C3,$D2,$C5,$C1
        .byte   $D4,$C5,$C4,$00,$CD,$C5,$C7
        cmp     ($CD,x)
        cmp     ($CE,x)
        brk
        .byte   $00,$00,$D4,$CF,$00,$D3,$D4,$CF
        .byte   $D0,$00,$D4,$C8,$C5,$00,$C5,$D6
        .byte   $C9,$CC,$00,$C4,$C5,$D3,$C9,$D2
        .byte   $C5,$D3,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$CF,$C6,$00,$C4
        .byte   $D2,$DC,$D7,$C9,$CC,$D9,$DC,$00
        .byte   $00,$00,$00,$00,$00,$00,$00
LADE8:  .byte   $00,$C8,$CF,$D7,$C5,$D6,$C5,$D2
        .byte   $DD,$C1,$C6,$D4,$C5,$D2,$00,$C8
        .byte   $C9,$D3,$00,$C4,$C5,$C6,$C5,$C1
        .byte   $D4,$DD,$00,$00,$00,$00,$C4,$D2
        .byte   $DC,$D7,$C9,$CC,$D9,$00,$C3,$D2
        .byte   $C5,$C1,$D4,$C5,$C4,$00,$C5,$C9
        .byte   $C7,$C8,$D4,$00,$00,$00,$00,$00
        .byte   $00,$00,$CF,$C6,$00,$C8,$C9,$D3
        .byte   $00,$CF,$D7,$CE,$00,$D2,$CF,$C2
        .byte   $CF,$D4,$D3,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$D4,$CF,$00,$C3
        .byte   $CF,$D5,$CE,$D4,$C5,$D2,$00,$CD
        .byte   $C5,$C7,$C1,$CD,$C1,$CE,$DC,$00
        .byte   $00,$00,$00,$00
LAE54:  .byte   $0F,$00,$10,$20,$30,$30,$30,$30
        .byte   $30,$30,$30,$30,$30,$30,$30,$30
        .byte   $30
        bmi     LAE97
        bmi     LAE99
        bmi     LAE9B
        bmi     LAE9D
        bmi     LAE9F
        bmi     LAE91
        bpl     LAE73
LAE73:  .byte   $0F,$30,$30,$30,$20
        bpl     LAE7A
LAE7A:  .byte   $0F
LAE7B:  .byte   $0C,$0B,$0A,$06,$06,$09,$09,$08
        .byte   $08,$07,$07,$06,$06,$06,$06
        asl     zp_temp_06
        ora     $05
        .byte   $04,$04,$03
LAE91:  .byte   $03,$02,$02
        .byte   $01
LAE95:  .byte   $13
        .byte   $21
LAE97:  .byte   $47
        .byte   $A3
LAE99:  .byte   $A7
        .byte   $A5
LAE9B:  lda     ($A1,x)
LAE9D:  brk
        .byte   $C3
LAE9F:  cmp     ($D0,x)
        .byte   $C3
        .byte   $CF,$CD,$00,$C3,$CF,$DC,$CC,$D4
        .byte   $C4,$1F,$21
        sta     ($D4,x)
        cmp     $C100
        dec     a:$C4
        .byte   $A3,$A7,$A5,$A1,$A5,$00,$C3,$C1
        .byte   $D0,$C3,$CF,$CD,$00,$D5,$DC,$D3
        .byte   $DC,$C1,$DC,$DD,$C9,$CE,$C3,$DC
        .byte   $0B,$21,$CB,$CC,$C9,$C3,$C5,$CE
        .byte   $D3,$C5,$C4,$00,$C2,$D9,$19,$22
        .byte   $04,$CE,$C9,$CE,$D4,$C5,$CE,$C4
        .byte   $CF,$00,$CF,$C6,$00,$C1,$CD,$C5
        .byte   $D2,$C9,$C3,$C1,$DC,$00,$C9,$CE
        .byte   $C3,$DC
LAEF7:  .byte   $00,$00
LAEF9:  .byte   $0F,$35,$21,$11,$0F,$30,$3C,$21
        .byte   $0F,$27,$17,$07,$0F,$30,$11,$0C
        .byte   $0F,$0F,$30,$16,$0F,$0F,$30,$0F
        .byte   $0F,$30,$30,$30,$0F,$0F,$0F,$0F
        .byte   $0F,$26,$26,$27,$0F,$17,$28
        ora     $0F
        .byte   $17,$27,$18,$0F,$19,$2A,$37,$0F
        .byte   $20,$2C,$11,$0F,$20,$26,$36,$0F
        .byte   $00,$2C,$11,$0F,$16,$35,$20
LAF39:  .byte   $25
LAF3A:  sty     $4009
        .byte   $53,$54,$41,$52,$54,$40,$40,$40
        .byte   $25,$CC,$0A,$40,$50,$41,$53,$53
        .byte   $57,$4F,$52,$44,$40,$25,$8C,$09
        .byte   $50,$41,$53,$53,$57,$4F,$52,$44
        .byte   $40,$25,$CC,$0A,$45,$52,$52,$4F
        .byte   $52,$40,$5F,$40,$40,$40,$25,$8B
        .byte   $08,$43,$4F,$4E,$54,$49,$4E
        eor     $45,x
        and     $CB
        .byte   $0C,$53,$54,$41,$47,$45,$40,$53
        .byte   $45,$4C,$45,$43,$54,$26,$0B,$09
        .byte   $50,$41,$53,$53,$57,$4F,$52,$44
        .byte   $40,$22,$66,$0E
LAF94:  bvc     LAFE8
        eor     $53
        .byte   $53,$40,$41,$94,$42,$55,$54,$54
        .byte   $4F,$4E,$26,$CA,$09,$50,$41,$53
        .byte   $53,$57,$4F,$52,$44,$40,$27,$0A
        .byte   $0C,$53,$54,$41,$47,$45,$40,$53
        .byte   $45,$4C,$45,$43,$54
LAFBD:  .byte   $00,$0C,$19,$25,$32,$3D,$4C,$58
        .byte   $69,$75
LAFC7:  .byte   $F8,$22,$00,$58
LAFCB:  .byte   $30,$25,$00,$44,$30,$26,$00,$54
        .byte   $30,$27,$00,$64,$30,$28,$00,$74
        .byte   $30,$29,$00,$84,$44,$E1,$02,$30
        .byte   $54,$E2,$02,$30,$64
LAFE8:  .byte   $E3,$02,$30,$74,$E4,$02,$30,$84
        .byte   $E5,$02
        bmi     LAF94
        .byte   $3F,$00,$D0
        ldy     $2D,x
        ora     ($D0,x)
LAFFB:  rti

        rti

        .byte   $40,$40,$40
LB000:  .byte   $50
        bvc     LB053
        bvc     LB055
        rts

        rts

        .byte   $60,$60,$60,$70,$70,$70,$70,$70
        .byte   $80,$80,$80,$80,$80
LB014:  eor     ($51,x)
        adc     ($71,x)
        sta     ($41,x)
        eor     ($61),y
        adc     ($81),y
        eor     ($51,x)
        adc     ($71,x)
        sta     ($41,x)
        eor     ($61),y
        adc     ($81),y
        eor     ($51,x)
        adc     ($71,x)
        .byte   $81
LB02D:  ora     ($02,x)
        .byte   $03,$04,$00,$06,$07,$08,$09,$05
        .byte   $0B,$0C,$0D,$0E,$0A,$10,$11,$12
        .byte   $13,$0F,$15,$16,$17,$18,$14
LB046:  .byte   $04,$00,$01,$02,$03,$09
        ora     zp_temp_06
        .byte   $07
        php
        asl     $0B0A
LB053:  .byte   $0C
        .byte   $0D
LB055:  .byte   $13
        .byte   $0F
        bpl     LB06A
        .byte   $12,$18,$14,$15,$16,$17
LB05F:  .byte   $14
        ora     $16,x
        .byte   $17,$18,$00,$01,$02,$03,$04,$05
LB06A:  asl     $07
        php
        ora     #$0A
        .byte   $0B,$0C,$0D,$0E,$0F,$10,$11,$12
        .byte   $13
LB078:  ora     zp_temp_06
LB07A:  .byte   $07,$08
        ora     #$0A
        .byte   $0B,$0C,$0D,$0E,$0F,$10,$11,$12
        .byte   $13,$14,$15,$16,$17,$18,$00,$01
        .byte   $02,$03,$04
LB091:  .byte   $0F,$00,$10,$20,$30
        jsr     L0010
LB099:  brk
        .byte   $3E,$01,$00,$00,$3E
        eor     ($08,x)
        php
        rol     a:$81,x
        php
        rol     $08C1,x
LB0A9:  brk
        .byte   $01
LB0AB:  .byte   $00,$10,$04,$20,$00,$08,$10,$80
        .byte   $08,$02,$04,$00
        ora     ($40,x)
        .byte   $80,$02,$20,$40
LB0BD:  .byte   $00,$00,$00,$00,$01,$00,$00,$01
        .byte   $01,$00,$00,$01,$00,$00,$01,$01
        .byte   $01,$00,$01,$00
LB0D1:  .byte   $60,$2F,$00,$60,$70,$1F,$00,$60
        .byte   $60,$1B,$00,$80,$70,$19,$00,$70
        .byte   $60,$1D,$00,$70,$60,$1C,$00
        bcc     LB15A
        .byte   $1A,$00,$90,$70,$1E,$00,$80,$80
        .byte   $20,$00,$60,$80
        and     $00
        bvs     LB07A
        rol     $00
        .byte   $80,$80,$27,$00
        bcc     LB0AB
        .byte   $03
        jsr     LC644
        lda     $2A
        pha
        lda     #$05
        sta     $2A
        lda     #$00
        sta     $08
        lda     #$8E
        sta     $09
        jsr     LA87E
        lda     #$40
        sta     $08
        lda     #$8E
        jsr     LA87E
        lda     #$21
        sta     $2006
        lda     #$CC
        sta     $2006
        ldx     #$00
LB12D:  lda     LB1E0,x
        sta     $2007
        inx
        cpx     #$09
        bne     LB12D
        lda     #$0F
        jsr     bank_switch_enqueue
        jsr     reset_scroll_state
        lda     #$00
        jsr     LA9B2
        lda     #$04
        sta     $FE
        lda     #$7D
        sta     $FD
        ldx     $FE
        cpx     #$07
        beq     LB158
        jsr     LA98B
        inc     $FE
LB158:  .byte   $20
        .byte   $AB
LB15A:  cpy     #$C6
        sbc     $EED0,x
        jsr     LA898
        jsr     LA9CC
        lda     #$80
        sta     $FD
        lda     #$8E
        sta     $FE
        jsr     LA9EA
        lda     #$10
        jsr     bank_switch_enqueue
LB175:  jsr     LA8D4
        lda     #$00
        sta     $FD
LB17C:  lda     $27
        and     #$3C
        beq     LB1A7
        and     #$08
        bne     LB1C6
        lda     #$2F
        jsr     bank_switch_enqueue
        lda     $27
        and     #$24
        bne     LB19B
        dec     $FD
        bpl     LB1A7
        lda     #$02
        sta     $FD
        bne     LB1A7
LB19B:  inc     $FD
        lda     $FD
        cmp     #$03
        bne     LB1A7
        lda     #$00
        sta     $FD
LB1A7:  ldx     #$03
LB1A9:  lda     LB1E9,x
        sta     $0200,x
        dex
        bpl     LB1A9
        lda     $1C
        and     #$08
        bne     LB1C0
        ldx     $FD
        lda     LB1ED,x
        sta     $0200
LB1C0:  jsr     LC0AB
        jmp     LB17C

LB1C6:  lda     $FD
        cmp     #$02
        beq     LB1CF
        jmp     LB1D5

LB1CF:  jsr     LB224
        jmp     LB175

LB1D5:  jsr     LA52D
        pla
        sta     $2A
        lda     #$03
        sta     $A8
        rts

LB1E0:  .byte   $47,$41,$4D,$45,$40,$4F,$56,$45
        .byte   $52
LB1E9:  .byte   $F8,$22,$00,$48
LB1ED:  .byte   $60,$70,$80
LB1F0:  .byte   $98,$22,$00,$28
LB1F4:  .byte   $68,$2F,$00,$C8,$88,$1F,$00,$C8
        .byte   $78,$1B,$00,$C8,$88,$19,$00,$D8
        .byte   $68,$1D,$00,$D8,$78,$1C,$00,$D8
        .byte   $98,$1A,$00,$D8,$98,$1E,$00,$C8
        .byte   $A8,$20,$00,$C8,$A8,$25,$00,$D8
        .byte   $B8,$26,$00,$C8,$B8,$27,$00,$D8
LB224:  jsr     LA898
        jsr     clear_oam_buffer
        jsr     LA9CC
        lda     #$00
        ldx     #$18
LB231:  sta     $0420,x
        dex
        bpl     LB231
        lda     $9A
        sta     $00
        eor     #$FF
        sta     $01
        clc
        lda     $A7
        tax
        adc     #$05
        sta     $03
        inc     $0420,x
        ldx     #$00
LB24C:  ldy     LB0BD,x
        lda     $00,y
        ldy     $03
        and     LB0A9,x
        beq     LB25B
        lda     #$01
LB25B:  sta     $0420,y
        iny
        cpy     #$19
        bne     LB265
        ldy     #$05
LB265:  sty     $03
        inx
        cpx     #$14
        bne     LB24C
        jsr     LAA25
        jsr     LA927
        lda     #$F8
        sta     $0230
        sta     $0234
        sta     $0238
        sta     $023C
        ldx     #$27
LB282:  lda     LAFCB,x
        sta     $0200,x
        dex
        bpl     LB282
        ldx     #$03
LB28D:  lda     LB1F0,x
        sta     $0228,x
        dex
        bpl     LB28D
        lda     $9A
        asl     a
        ora     #$01
        sta     $00
        lda     $9B
        rol     a
        sta     $01
        ldx     #$00
        lda     #$0C
        sta     $02
LB2A8:  lsr     $01
        ror     $00
        bcc     LB2BC
        ldy     #$04
LB2B0:  lda     LB1F4,x
        sta     $02A4,x
        inx
        dey
        bne     LB2B0
        beq     LB2C0
LB2BC:  inx
        inx
        inx
        inx
LB2C0:  dec     $02
        bne     LB2A8
        ldx     #$07
        jsr     LA98B
        jsr     LA8D4
LB2CC:  ldx     #$F8
        lda     $1C
        and     #$08
        bne     LB2D6
        ldx     #$98
LB2D6:  stx     $0228
        jsr     LC0AB
        lda     $27
        and     #$01
LB2E0:  beq     LB2CC
        lda     #$42
        jsr     bank_switch_enqueue
        jsr     LA898
        jsr     clear_oam_buffer
        jsr     LAA09
        rts

LB2F1:  .byte   $FF
LB2F2:  .byte   $FF,$FF,$55,$55,$55,$55,$55,$FF
        .byte   $FF,$FF,$55,$55,$55,$55,$55,$FF
        .byte   $FF,$FF,$55,$55,$55,$55,$55,$FF
        .byte   $FF,$F7,$50,$50,$55,$55,$55,$F5
        .byte   $F5,$55,$04,$01,$55,$55,$55,$55
        .byte   $A6,$AA,$AA,$AA,$AA,$A9,$55,$55
        .byte   $55,$A4,$A0,$A0,$A1,$55,$55,$55
        .byte   $55,$55,$55,$55,$55,$55,$55,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$E0,$E2,$E4,$E6,$E8
        .byte   $EA,$E4,$E6,$E8,$EA,$E4,$E6,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$E0,$E2,$E4,$E6,$E8
        .byte   $EA,$E4,$E6,$E8,$EA,$E4,$E6,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$E0,$E2,$E4,$E6,$E8
        .byte   $EA,$E4,$E6,$E8,$EA,$E4,$E6,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$E0,$E2,$E4,$E6,$E8
        .byte   $EA
        cpx     $E6
        inx
        nop
        cpx     $E6
        brk
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$E0,$E2,$E4,$E6,$E8
        .byte   $EA,$E4,$E6,$E8,$EA,$E4,$E6,$00
        .byte   $00,$00,$00,$00,$00,$D0,$D2,$C5
        .byte   $D3,$D3,$00,$D3,$D4,$C1,$D2,$D4
        .byte   $00,$00,$00,$E0,$E2,$E4,$E6,$E8
        .byte   $EA,$E4,$E6,$E8,$EA,$E4,$E6,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$E0,$E2,$E4,$E6,$E8
        .byte   $EA,$E4,$E6,$E8,$EA,$E4,$E6,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$E0,$E2,$E4,$E6,$E8
        .byte   $EA,$E4,$E6,$E8,$EA,$E4,$E6,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$C4
        .byte   $C9,$C6,$C6,$C9,$C3,$D5,$CC,$D4
        .byte   $00,$00,$00,$E0,$E2,$E4,$E6,$E8
        .byte   $EA,$E4,$E6,$E8,$EA,$E4,$E6,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$E0,$E2,$E4,$E6,$E8
        .byte   $EA,$E4,$E6,$E8,$EA,$E4,$E6,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$CE
        .byte   $CF,$D2,$CD,$C1,$CC,$00,$00,$00
        .byte   $00,$00,$00,$E0,$E2,$ED,$ED,$ED
        .byte   $ED,$ED,$ED,$ED,$ED,$ED,$ED,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$E0,$E2,$EC,$EC,$EC
        .byte   $EC,$EC,$EC,$EC,$EC,$EC,$EC,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$EE,$EF,$00,$00,$F1
        .byte   $F3,$F3,$F3,$F5,$F7,$F3,$F3,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$BA,$BB,$BB,$BB
        .byte   $BB,$BC,$00,$00,$00,$00,$00,$F1
        .byte   $F3,$F3,$F3,$F4,$F6,$F3,$F3,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$B4,$B5,$B6,$B7
        .byte   $B8,$B9,$00,$00,$00,$00,$00,$F1
        .byte   $F3,$F3,$F3,$F3,$F3,$F3,$F3,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$B0,$B1,$B2
        .byte   $B3,$00,$00,$00,$00,$00,$00,$F0
        .byte   $F2,$F2,$F2,$F2,$F2,$F2,$F2,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$AC,$AD,$AE
        .byte   $AF,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$66,$67,$68,$69,$6A
        .byte   $6B,$6C,$6D,$6E,$6F,$70,$71,$72
        .byte   $73,$74,$75
        ror     $77,x
        sei
        adc     $7B7A,y
        .byte   $7C,$7D,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$50,$51,$52,$53,$54
        .byte   $55,$56,$57,$58,$59,$5A,$5B,$5C
        .byte   $5D,$5E,$5F,$60,$61,$62,$63,$64
        .byte   $65,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$3C,$3D,$3E,$3F
        .byte   $40,$41,$42,$43,$44,$45,$46,$47
        .byte   $48,$49,$4A,$4B,$4C,$4D,$4E,$4F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$2A,$2B,$2C
        .byte   $2D,$2E,$2F,$30,$31,$32,$33,$34
        .byte   $35,$36,$37,$38,$39,$3A,$3B,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$1A,$1B
        .byte   $1C,$1D,$1E,$1F,$20,$21,$22,$23
        .byte   $24,$25,$26,$27,$28,$29,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$0C
        .byte   $0D,$0E,$0F,$10,$11,$12,$13,$14
        .byte   $15,$16,$17,$18,$19,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7E,$01,$02,$03,$04,$05,$06,$07
        .byte   $08,$09,$0A,$0B,$00,$00,$00,$00
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
        .byte   $00,$00,$00,$00,$00,$00
        jsr     reset_scroll_state
        inc     $20
        lda     #$04
        jsr     LC644
        lda     #$05
        sta     $2A
        lda     #$C0
        sta     $08
        lda     #$8E
        sta     $09
        jsr     LA87E
        lda     #$00
        sta     $08
        lda     #$8F
        sta     $09
        jsr     LA87E
        lda     #$00
        sta     $06A0
        sta     $0680
        sta     $0681
        sta     $0400
        sta     $0401
        sta     $04A1
        lda     #$0F
        ldx     #$1F
LB72D:  sta     $0356,x
        dex
        bpl     LB72D
        lda     #$FF
        jsr     bank_switch_enqueue
        jsr     clear_oam_buffer
        jsr     LA51D
        lda     #$BB
        sta     $FD
LB742:  jsr     LC0AB
        dec     $FD
        bne     LB742
        lda     #$13
        jsr     bank_switch_enqueue
        lda     #$04
        sta     $FD
        lda     #$3F
        sta     $FE
LB756:  dec     $FE
        bne     LB76B
        lda     #$3F
        sta     $FE
        ldx     #$1B
        ldy     #$3B
        lda     #$0F
        jsr     LA8FF
        dec     $FD
        beq     LB774
LB76B:  jsr     LB8F9
        jsr     LC0AB
        jmp     LB756

LB774:  ldx     $06A0
        lda     LBA7B,x
        sta     $FD
        lda     LBA81,x
        sta     $FE
        lda     #$3F
        sta     $FF
LB785:  lda     $FF
        beq     LB78B
        dec     $FF
LB78B:  lda     $06A0
        cmp     #$05
        bne     LB79B
        lda     $FF
        and     #$01
        sta     $20
        jmp     LB7A1

LB79B:  jsr     LB9E0
        jsr     LB9FF
LB7A1:  lda     $06A0
        bne     LB7B5
        lda     $1C
        and     #$07
        bne     LB7B5
        ldx     #$1F
        ldy     #$3F
        lda     #$FF
        jsr     LA8FF
LB7B5:  jsr     LB8F9
        jsr     LC0AB
        sec
        lda     $FD
        sbc     #$01
        sta     $FD
        lda     $FE
        sbc     #$00
        sta     $FE
        bcs     LB785
        inc     $06A0
        lda     $06A0
        cmp     #$06
        bne     LB774
        jsr     LA52D
        jsr     load_stage_nametable
        lda     #$05
        jsr     LC644
        lda     #$20
        sta     $2006
        lda     #$00
        sta     $2006
        ldy     #$04
LB7EB:  ldx     #$00
LB7ED:  sta     $2007
        inx
        bne     LB7ED
        dey
        bne     LB7EB
        sta     $0420
        ldx     #$1F
        jsr     load_scroll_palette
        inc     $20
        jsr     clear_oam_buffer
        lda     #$30
        sta     $0369
        lda     #$0D
        jsr     bank_switch_enqueue
        jsr     LA51D
        jsr     L8465
        lda     #$25
        sta     $03B6
        lda     #$AC
        sta     $03B7
        lda     #$A2
        sta     $FD
        lda     #$00
        sta     $FE
        sta     $06A0
LB828:  lda     $FD
        and     #$03
        bne     LB841
        ldx     $FE
        cpx     #$05
        beq     LB841
        lda     LBADB,x
        sta     $03B8
        inc     $47
        inc     $FE
        inc     $03B7
LB841:  jsr     render_player_sprites
        jsr     LC0AB
        dec     $FD
        bne     LB828
        lda     #$A0
        sta     $03B7
        lda     #$20
        jsr     LBA24
LB855:  lda     #$49
        sta     $FD
        lda     #$01
        sta     $FE
        lda     #$00
        sta     $0680
        lda     #$25
        sta     $03B6
        lda     #$83
        sta     $03B7
LB86C:  jsr     LD637
        jsr     render_player_sprites
        jsr     LC0AB
        sec
        lda     $FD
        sbc     #$01
        sta     $FD
        lda     $FE
        sbc     #$00
        sta     $FE
        bne     LB86C
        lda     $FD
        beq     LB89B
        cmp     #$D0
        bne     LB86C
        lda     $06A0
        cmp     #$0E
        bcc     LB86C
        lda     #$14
        jsr     bank_switch_enqueue
        jmp     LB86C

LB89B:  lda     #$25
        sta     $03B6
        lda     #$80
        sta     $03B7
        lda     #$20
        jsr     LBA24
        lda     #$25
        sta     $03B6
        lda     #$C0
        sta     $03B7
        lda     #$20
        jsr     LBA24
        inc     $06A0
        lda     $06A0
        cmp     #$10
        bne     LB855
        lda     #$0F
        sta     $0358
        sta     $0359
        lda     #$00
        sta     $06A0
        sta     $20
        jsr     LD642
LB8D5:  jsr     LD64D
        jsr     render_player_sprites
        jsr     LC0AB
        lda     $06A0
        cmp     #$3C
        bne     LB8D5
        lda     $22
        bne     LB8D5
LB8E9:  jsr     render_player_sprites
        jsr     LC0AB
        lda     $27
        and     #$08
        beq     LB8E9
        jsr     LA52D
        rts

LB8F9:  jsr     clear_oam_buffer
        lda     $06A0
        cmp     #$05
        bne     LB91E
        ldy     #$04
        ldx     #$30
        lda     $FF
        and     #$01
        bne     LB911
        ldy     #$05
        ldx     #$0F
LB911:  stx     $0367
        txa
        and     #$0F
        sta     $036F
        jsr     LD627
        rts

LB91E:  lda     #$00
        sta     $0460
        sta     $04A0
        sta     $0440
        sta     $00
        inc     $0680
        lda     $0680
        cmp     #$10
        bne     LB949
        lda     #$00
        sta     $0680
        inc     $0400
        lda     $0400
        cmp     #$04
        bne     LB949
        lda     #$00
        sta     $0400
LB949:  lda     $06A0
        cmp     #$04
        bcc     LB95F
        ldy     $0400
        lda     $FF
        and     #$01
        bne     LB95B
        ldy     #$04
LB95B:  jsr     LD627
        rts

LB95F:  jsr     LD624
        ldx     $06A0
        clc
        lda     $04C1
        adc     LBAD3,x
        sta     $04C1
        lda     $04A1
        adc     LBAD7,x
        sta     $04A1
        lda     $1C
        and     #$07
        bne     LB98D
        inc     $0681
        lda     $0681
        cmp     #$04
        bne     LB98D
        lda     #$00
        sta     $0681
LB98D:  lda     $06A0
        asl     a
        asl     a
        adc     $0681
        tax
        lda     LBAB3,x
        sta     $02
        lda     $FF
        beq     LB9BA
        ldx     $06A0
        beq     LB9BA
        dex
        lda     $FF
        beq     LB9BA
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     $02
        txa
        asl     a
        asl     a
        adc     $02
        tax
        lda     LBAC3,x
        sta     $02
LB9BA:  ldy     $00
        ldx     #$15
LB9BE:  clc
        lda     LBA87,x
        adc     $04A1
        sta     $0200,y
        iny
        lda     $02
        sta     $0200,y
        iny
        lda     #$03
        sta     $0200,y
        iny
        lda     LBA9D,x
        sta     $0200,y
        iny
        dex
        bpl     LB9BE
        rts

LB9E0:  ldx     $06A0
        lda     $FF
        and     #$01
        bne     LB9EA
        inx
LB9EA:  txa
        asl     a
        tax
        ldy     #$00
LB9EF:  lda     LBA6F,x
        sta     $0368,y
        sta     $0370,y
        inx
        iny
        cpy     #$02
        bne     LB9EF
        rts

LB9FF:  ldx     $06A0
        beq     LBA23
        lda     $FF
        and     #$01
        beq     LBA0B
        dex
LBA0B:  txa
        asl     a
        asl     a
        sta     $00
        clc
        asl     a
        adc     $00
        tax
        ldy     #$00
LBA17:  lda     LBA33,x
        sta     $0356,y
        inx
        iny
        cpy     #$0C
        bne     LBA17
LBA23:  rts

LBA24:  ldx     #$20
        stx     $47
        dex
LBA29:  sta     $03B8,x
        dex
        bpl     LBA29
        jsr     LC0AB
        rts

LBA33:  .byte   $0F,$26,$26,$27,$0F,$17,$28,$05
        .byte   $0F,$17,$27,$18,$0F,$11,$11,$20
        .byte   $0F,$10,$28,$20,$0F,$10,$20,$18
        .byte   $0F,$21,$21,$35,$0F,$25,$37,$16
        .byte   $0F,$25,$35,$17,$0F,$10,$10,$00
        .byte   $0F,$00,$18,$05,$0F,$00,$10,$00
        .byte   $0F,$30,$21,$1C,$0F,$19,$37
        asl     $0F,x
        ora     $182A,y
LBA6F:  bit     $2811
        ora     $30,x
        brk
        .byte   $34,$24,$30,$11,$2C,$11
LBA7B:  bit     $3232
        .byte   $32,$32,$90
LBA81:  .byte   $03,$02,$02,$02
LBA85:  .byte   $02,$02
LBA87:  .byte   $00,$08,$10,$20,$28,$30,$40,$48
        .byte   $50,$58,$68,$78,$80,$88,$90,$A8
        .byte   $B8,$C0,$D0,$D8,$E0,$E8
LBA9D:  .byte   $D8,$70,$18,$B0,$88,$40,$A0,$F8
        .byte   $20,$58,$C8,$08,$88,$38
        bcs     LBA85
        bvs     LBAD7
        clv
        php
        tya
        pha
LBAB3:  .byte   $0C,$0D,$0E,$0D,$1B,$1C,$1B,$1C
        .byte   $2C,$2D,$2E,$2D,$3B,$3B,$3B,$3B
LBAC3:  .byte   $1B,$1A,$19,$0F,$2C,$1F,$1E,$1D
        .byte   $3C,$3A,$39,$2F,$3D,$3D,$3D,$3C
LBAD3:  .byte   $80,$80,$E5,$00
LBAD7:  .byte   $00,$00,$00,$08
LBADB:  .byte   $13,$14,$01,$06,$06
        lda     #$03
        jsr     LC644
        lda     #$06
        jsr     LC644
        lda     $2A
        pha
        lda     #$05
        sta     $2A
        lda     #$40
        sta     $08
        lda     #$8F
        sta     $09
        jsr     LA87E
        lda     #$80
        sta     $08
        lda     #$8F
        sta     $09
        jsr     LA87E
        pla
        sta     $2A
        lda     #$17
        jsr     bank_switch_enqueue
        jsr     reset_scroll_state
        lda     #$01
        jsr     LA9B2
        ldx     #$0F
        txa
LBB1A:  sta     $0366,x
        dex
        bpl     LBB1A
        lda     #$06
        sta     $0400
        jsr     LD624
        lda     #$05
        sta     $FD
LBB2C:  lda     $1C
        and     #$07
        bne     LBB3F
        ldx     #$1B
        ldy     #$3B
        lda     #$0F
        jsr     LA8FF
        dec     $FD
        beq     LBB45
LBB3F:  jsr     LC0AB
        jmp     LBB2C

LBB45:  jsr     LBD34
        jsr     LBD22
        jsr     LBD34
        inc     $03B7
        ldx     $2A
        lda     LBE12,x
        sta     $03B8
        inc     $47
        jsr     LBD34
        jsr     LBD22
        inc     $03B7
        inc     $03B7
        jsr     LC0AB
        lda     #$08
        jsr     LBD3E
        lda     #$09
        jsr     LBD3E
        lda     $2A
        jsr     LBD3E
        lda     $2A
        cmp     #$04
        bne     LBB84
        lda     #$13
        jsr     LBD3E
LBB84:  lda     #$9C
        sta     $FD
LBB88:  ldx     #$00
        lda     $FD
        and     #$01
        beq     LBB96
        ldx     $2A
        inx
        txa
        asl     a
        tax
LBB96:  lda     LBF5A,x
        sta     $0368
        sta     $0370
        lda     LBF5B,x
        sta     $0369
        sta     $0371
        jsr     LC0AB
        dec     $FD
        bne     LBB88
        ldx     $2A
        lda     $C281,x
        beq     LBBB9
        jsr     LBC62
LBBB9:  ldx     #$08
        jsr     LA98B
        jsr     LC0AB
        ldx     #$09
        jsr     LA98B
        jsr     LC0AB
LBBC9:  ldx     #$03
LBBCB:  lda     LBF70,x
        sta     $02FC,x
        dex
        bpl     LBBCB
        lda     #$30
        sta     $0374
        lda     #$00
        sta     $FD
LBBDD:  ldx     $FD
        lda     LBF6E,x
        sta     $02FC
        lda     $1C
        and     #$08
        bne     LBBF0
        lda     #$F8
        sta     $02FC
LBBF0:  lda     $27
        and     #$3C
        beq     LBC05
        and     #$08
        bne     LBC0B
        lda     #$2F
        jsr     bank_switch_enqueue
        lda     $FD
        eor     #$01
        sta     $FD
LBC05:  jsr     LC0AB
        jmp     LBBDD

LBC0B:  lda     $FD
        beq     LBC12
        jmp     LBC5E

LBC12:  ldx     #$1F
LBC14:  lda     $0356,x
        sta     $0700,x
        dex
        bpl     LBC14
        jsr     LB224
        jsr     LD624
        lda     #$05
        sta     $FD
LBC27:  lda     $1C
        and     #$03
        bne     LBC55
        ldx     #$1F
LBC2F:  lda     $0356,x
        cmp     #$0F
        bne     LBC41
        lda     $0700,x
        and     #$0F
        sta     $0356,x
        jmp     LBC4E

LBC41:  clc
        adc     #$10
        cmp     $0700,x
        beq     LBC4B
        bcs     LBC4E
LBC4B:  sta     $0356,x
LBC4E:  dex
        bpl     LBC2F
        dec     $FD
        beq     LBC5B
LBC55:  jsr     LC0AB
        jmp     LBC27

LBC5B:  jmp     LBBC9

LBC5E:  jsr     LA52D
        rts

LBC62:  lda     #$0F
        sta     $035C
        sta     $035D
        ldx     #$02
LBC6C:  lda     LBF74,x
        sta     $0373,x
        dex
        bpl     LBC6C
        jsr     clear_oam_buffer
        jsr     LBDB7
        lda     #$7D
        sta     $FD
LBC7F:  ldx     #$0F
        lda     $FD
        and     #$08
        beq     LBC89
        ldx     #$15
LBC89:  stx     $0366
        jsr     LC0AB
        dec     $FD
        bne     LBC7F
        lda     #$07
        sta     $0400
        jsr     LD624
        lda     #$0A
        jsr     LBD3E
        lda     #$0B
        jsr     LBD3E
        jsr     LBDAB
        jsr     LBDB7
        ldx     $2A
        lda     $C281,x
        lsr     a
        ora     #$A0
        sta     $0420
        inc     $0420
        lda     #$0F
        jsr     LBD3E
        lda     #$0C
        jsr     LBD3E
        lda     #$0D
        jsr     LBD3E
        lda     #$0E
        jsr     LBD3E
        jsr     LBDAB
        jsr     LBDB7
        jsr     clear_oam_buffer
        lda     #$06
        sta     $0400
        jsr     LD624
        jsr     LBDEC
        lda     #$08
        jsr     LBD3E
        lda     #$09
        jsr     LBD3E
        lda     $0420
        and     #$0F
        clc
        adc     #$0F
        jsr     LBD3E
        lda     #$7D
        sta     $FD
LBCFA:  ldx     #$12
        lda     $FD
        and     #$01
        bne     LBD08
        ldx     $2A
        inx
        txa
        asl     a
        tax
LBD08:  lda     LBF5A,x
        sta     $0368
        sta     $0370
        lda     LBF5B,x
        sta     $0369
        sta     $0371
        jsr     LC0AB
        dec     $FD
        bne     LBCFA
        rts

LBD22:  lda     #$24
        sta     $03B6
        lda     #$CD
        sta     $03B7
        lda     #$94
        sta     $03B8
        inc     $47
        rts

LBD34:  jsr     LC0AB
        lda     $1C
        and     #$07
        bne     LBD34
        rts

LBD3E:  sty     $00
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        lda     #$00
        adc     #$00
        sta     $C8
        lda     #$1A
        sta     $C9
        lda     #$BE
        clc
        adc     $C8
        sta     $CA
        lda     ($C9),y
        sta     $03B6
        tya
        clc
        adc     #$01
        tay
        lda     $CA
        adc     #$00
        sta     $CA
        lda     ($C9),y
        sta     $03B7
        tya
        clc
        adc     #$01
        tay
        lda     $CA
        adc     #$00
        sta     $CA
        sty     $FE
        lda     #$0E
        sta     $FD
LBD7C:  jsr     LBD34
        ldy     $FE
        cpy     #$F7
        bne     LBD8A
        lda     $0420
        bne     LBD8C
LBD8A:  lda     ($C9),y
LBD8C:  sta     $03B8
        inc     $47
        inc     $03B7
        lda     $FE
        clc
        adc     #$01
        sta     $FE
        lda     $CA
        adc     #$00
        sta     $CA
        dec     $FD
        bne     LBD7C
        ldy     $00
        jsr     LC0AB
        rts

LBDAB:  lda     #$7D
        sta     $FD
LBDAF:  jsr     LC0AB
        dec     $FD
        bne     LBDAF
        rts

LBDB7:  ldx     #$1F
        lda     #$00
LBDBB:  sta     $03B8,x
        dex
        bpl     LBDBB
        lda     #$09
        sta     $FD
        lda     #$24
        sta     $03B6
        lda     #$AB
        sta     $03B7
LBDCF:  clc
        lda     $03B7
        adc     #$20
        sta     $03B7
        lda     $03B6
        adc     #$00
        sta     $03B6
        lda     #$0F
        sta     $47
        jsr     LC0AB
        dec     $FD
        bpl     LBDCF
        rts

LBDEC:  jsr     LBD34
        jsr     LBD22
        jsr     LBD34
        inc     $03B7
        ldx     $2A
        lda     $0420
        sta     $03B8
        inc     $47
        jsr     LBD34
        jsr     LBD22
        inc     $03B7
        inc     $03B7
        jsr     LC0AB
        rts

LBE12:  pha
        eor     ($57,x)
        .byte   $42,$51,$46,$4D,$43,$25,$8B,$40
        .byte   $40,$41,$54,$4F,$4D,$49,$43,$40
        .byte   $46,$49,$52,$45,$40,$25,$8B,$40
        .byte   $40,$41,$49,$52,$40,$53,$48,$4F
        .byte   $4F,$54,$45,$52,$40,$25,$8B,$40
        .byte   $40,$4C,$45,$41,$46,$40,$53,$48
        .byte   $49,$45,$4C,$44,$40,$25,$8B,$40
        .byte   $40,$42,$55,$42,$42,$4C,$45,$94
        .byte   $4C,$45,$41,$44,$40,$25,$8B,$40
        .byte   $40,$51,$55,$49,$43,$4B,$40,$40
        .byte   $40,$40,$40,$40,$40,$25,$8B,$40
        .byte   $40,$54,$49,$4D,$45,$94,$53,$54
        .byte   $4F,$50,$50,$45,$52,$25,$8B,$40
        .byte   $40,$4D,$45,$54,$41,$4C,$94,$42
        .byte   $4C,$41,$44,$45,$40,$25,$8B,$40
        .byte   $40,$43,$52,$41,$53,$48,$40,$42
        .byte   $4F,$4D,$42,$45,$52,$25,$0B,$40
        .byte   $40,$47,$45,$54,$40,$45,$51,$55
        .byte   $49,$50,$50,$45,$44,$25,$4B,$40
        .byte   $40,$57,$49,$54,$48,$40,$40,$40
        .byte   $40,$40,$40,$40,$40,$25,$2B,$40
        .byte   $4D,$45,$53,$53,$41,$47,$45,$40
        .byte   $46,$52,$4F
        eor     $2540
        .byte   $6B,$40,$44,$52,$5C,$4C,$49,$47
        .byte   $48,$54,$5C,$40,$40,$40,$40,$25
        .byte   $2B,$43,$4F,$4D,$50,$4C,$45,$54
        .byte   $45,$44,$5F,$40,$40,$40,$40,$25
        .byte   $6B,$47,$45,$54,$40,$59,$4F,$55
        .byte   $52,$40,$40,$40,$40,$40,$40,$25
        .byte   $AB,$57,$45,$41,$50,$4F,$4E,$53
        .byte   $40,$52,$45,$41,$44,$59,$5F,$24
        .byte   $EB,$49,$54,$45,$4D,$94,$40,$40
        .byte   $40,$40,$40,$40,$40,$40,$40,$25
        .byte   $8B,$40,$40,$49,$54
        eor     $4D
        sty     $A1,x
        rti

        .byte   $40,$40,$40,$40,$40,$25,$8B,$40
        .byte   $40,$49,$54
LBF30:  eor     $4D
        sty     $A2,x
        rti

        .byte   $40,$40,$40,$40,$40,$25,$8B,$40
        .byte   $40,$49,$54,$45,$4D,$94,$A3,$40
        .byte   $40,$40,$40,$40,$40,$25,$CB,$40
        .byte   $40,$94,$42,$4F,$4F,$4D,$45,$52
        .byte   $41,$4E,$47,$40,$40
LBF5A:  .byte   $2C
LBF5B:  .byte   $11,$28,$15,$20,$11,$20,$19,$20
        .byte   $00,$34,$25,$34,$14,$37,$18,$20
        .byte   $26,$20,$16
LBF6E:  bcs     LBF30
LBF70:  bcs     LBF94
        .byte   $03,$40
LBF74:  .byte   $20,$10,$36,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
LBF94:  .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$78,$EE,$E1,$BF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$F0,$CF
        .byte   $E0,$BF,$E0,$BF
