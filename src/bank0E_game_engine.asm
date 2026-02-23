.segment "BANK0E"

; =============================================================================
; Bank $0E — Main Game Engine
; Cold boot entry point, hardware initialization, main game loop,
; and game state dispatch table. Bank $0E is switched in first by
; cold_boot_init in the fixed bank after reset.
; =============================================================================

; da65 V2.18 - Ubuntu 2.19-1
; Created:    2026-02-23 18:17:35
; Input file: build/bank0E.bin
; Page:       1


        .setcpu "6502"

jump_ptr           := $0008
L0F15           := $0F15
L0F20           := $0F20
L1D06           := $1D06
L2020           := $2020
L4802           := $4802
L5060           := $5060
bank_switch_enqueue           := $C051
LC05D           := $C05D
LC071           := $C071
LC07F           := $C07F
LC0D7           := $C0D7
LC10B           := $C10B
LC45D           := $C45D
LC4CD           := $C4CD
LC557           := $C557
LC565           := $C565
LC573           := $C573
LC5A9           := $C5A9
LC7A4           := $C7A4
LC7B5           := $C7B5
LC808           := $C808
LC80C           := $C80C
LC84E           := $C84E
LC874           := $C874
LC8EF           := $C8EF
LC91B           := $C91B
LC96B           := $C96B
LCA16           := $CA16
LCB0C           := $CB0C
LCB8C           := $CB8C
LCBA2           := $CBA2
LCBC3           := $CBC3
LCC6C           := $CC6C
LCC77           := $CC77
ppu_buffer_transfer           := $D11B
fixed_D2ED           := $D2ED
LD3A8           := $D3A8
LD3E0           := $D3E0
LD658           := $D658
LDA51           := $DA51
LDCD0           := $DCD0
LEEBA           := $EEBA
LEEDA           := $EEDA
LEFAF           := $EFAF
LEFB3           := $EFB3
LEFEE           := $EFEE
LF010           := $F010
LF014           := $F014
LF02C           := $F02C
LF0CF           := $F0CF
LF159           := $F159
LF160           := $F160
LF197           := $F197
        .byte   $78
        ldx     #$FF
        txs
        ldx     #$01
L8006:  lda     $2002
        bpl     L8006
L800B:  lda     $2002
        bmi     L800B
        dex
        bpl     L8006
        lda     #$00
        sta     $00
        sta     $01
        ldy     #$00
L801B:  sta     ($00),y
        iny
        bne     L801B
        inc     $01
        ldx     $01
        cpx     #$08
        bne     L801B
        lda     #$0E
        jsr     LC05D
        lda     #$01
        sta     LBFFF
        lsr     a
        sta     LBFFF
        lsr     a
        sta     LBFFF
        lsr     a
        sta     LBFFF
        lsr     a
        sta     LBFFF
        lda     #$1F
        sta     $DFFF
        lsr     a
        sta     $DFFF
        lsr     a
        sta     $DFFF
        lsr     a
        sta     $DFFF
        lsr     a
        sta     $DFFF
        lda     #$03
        sta     $A8
        lda     #$00
        sta     $A7
L805F:  jsr     LC557
        lda     $BE
        bne     L805F
        lda     $9A
        cmp     #$FF
        bne     L8072
        lda     #$08
        sta     $2A
        bne     L8079
L8072:  lda     #$03
        sta     $A8
        jsr     LC565
L8079:  lda     $2A
        cmp     #$08
        bcc     L8088
        jsr     LC071
        lda     $2A
        cmp     #$09
        bcs     L8091
L8088:  ldx     #$0A
        lda     #$1C
L808C:  sta     $9C,x
        dex
        bpl     L808C
L8091:  ldx     #$00
        lda     $2A
        and     #$08
        beq     L809B
        ldx     #$03
L809B:  stx     $B0
        lda     #$14
        ldx     #$1F
L80A1:  sta     $0140,x
        dex
        bpl     L80A1
        lda     #$00
        sta     $BC
        lda     #$00
        sta     $46
        lda     #$40
        sta     $45
        lda     #$10
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001
        jsr     LC45D
        lda     #$1C
        sta     $06C0
        lda     #$00
        sta     $AA
        sta     $A9
        jsr     fixed_D2ED
        jsr     LC4CD
        lda     #$00
        sta     $1F
        sta     $1E
        sta     $22
        sta     $B5
        sta     $B6
        sta     $B7
        sta     $B8
        sta     $B9
        sta     $0460
        sta     $0480
        sta     $43
        sta     $44
        sta     $B1
        lda     $20
        jsr     L907D
        clc
        lda     $20
        adc     #$01
        jsr     L907D
        lda     #$20
        sta     $1A
        jsr     LCC6C
        lda     $F8
        ora     #$1E
        sta     $F8
        sta     $2001
        lda     $F7
        ora     #$80
        sta     $F7
        sta     $2000
        sta     $1D
        lda     #$40
        sta     $30
        lda     #$00
        sta     $31
        ldx     $2A
        lda     L81D0,x
        jsr     bank_switch_enqueue
        ldx     #$13
L812D:  lda     L81BC,x
        sta     $0200,x
        dex
        bpl     L812D
        lda     #$C0
        sta     $FD
L813A:  ldy     #$60
        ldx     #$10
        lda     $FD
        and     #$08
        bne     L8146
        ldy     #$F8
L8146:  tya
        sta     $0200,x
        dex
        dex
        dex
        dex
        bpl     L8146
        jsr     LC07F
        dec     $FD
        bne     L813A
        jsr     LCC6C
        lda     #$DF
        sta     $3B
        lda     #$04
        sta     $3C
        jsr     L9220
        jsr     LC7B5
        lda     $2A
        cmp     #$0C
        bne     L8171
        jmp     L8223

L8171:  lda     $AD
        beq     L8178
        jsr     L82D5
L8178:  lda     $27
        and     #$08
        beq     L8181
        jsr     LC573
L8181:  jsr     LCB8C
        jsr     L84EE
        jsr     LDCD0
        jsr     LD658
        jsr     LC5A9
        jsr     L925B
        jsr     LCC77
        lda     $37
        beq     L819D
        jsr     L8278
L819D:  lda     $FB
        beq     L81B0
        inc     $FC
        cmp     $FC
        beq     L81A9
        bcs     L81B0
L81A9:  jsr     LC0D7
        lda     #$00
        sta     $FC
L81B0:  jsr     LC07F
        jmp     L8171

        .byte   $10,$10,$10,$15,$15,$10
L81BC:  .byte   $60,$96,$01,$6C,$60,$97,$01,$74
        .byte   $60,$98,$01,$7C,$60,$99,$01,$84
        .byte   $60,$9A,$01
        .byte   $8C
L81D0:  .byte   $03
        .byte   $04
        ora     ($07,x)
        asl     $00
        ora     $02
        php
        php
        ora     #$09
        ora     #$FF
L81DE:  lda     $BC
        cmp     #$FF
        bne     L81F9
        ldx     #$00
        stx     $2B
        lda     #$7E
        ldx     #$0E
        jsr     LF160
        lda     #$3B
        sta     $04BE
        lda     #$80
        sta     $047E
L81F9:  lda     #$00
        sta     $2B
        sta     $02
        lda     $BC
        sta     $03
L8203:  lsr     $03
L8205:  bcs     L821A
        lda     #$7C
        ldx     $02
        jsr     LF160
        lda     L8268,y
        sta     $04B0,y
        lda     L8270,y
        sta     $0470,y
L821A:  inc     $02
        lda     $02
        cmp     #$08
        bne     L8203
        rts

L8223:  jsr     L81DE
L8226:  lda     $AD
        beq     L822D
        jsr     L82D5
L822D:  lda     $27
        and     #$08
        beq     L8236
        jsr     LC573
L8236:  jsr     LCB8C
        jsr     L84EE
        jsr     LDCD0
        jsr     LC5A9
        jsr     L925B
        jsr     LCC77
        lda     $37
        beq     L824F
        jsr     L8278
L824F:  lda     $FB
        beq     L8262
        inc     $FC
        cmp     $FC
        beq     L825B
        bcs     L8262
L825B:  jsr     LC0D7
        lda     #$00
        sta     $FC
L8262:  jsr     LC07F
        jmp     L8226

L8268:  .byte   $3B,$7B,$BB,$BB,$BB,$3B,$7B,$BB
L8270:  jsr     L2020
        bvs     L8205
        cpx     #$E0
        .byte   $E0
L8278:  ldx     $1F
        bne     L82BB
        ldx     $20
        beq     L8298
        cpx     $14
        bne     L8298
        ldy     $38
        dey
        jsr     LC7A4
        tya
        ldy     $37
        and     L82CC,y
        beq     L8298
        jsr     L8EDD
        jmp     L82C8

L8298:  cpx     $15
        bne     L82BB
        ldy     $38
        jsr     LC7A4
        tya
        ldy     $37
        and     L82D0,y
        beq     L82BB
        jsr     L8F39
        ldx     $2A
        lda     $20
        cmp     L906F,x
        bne     L82B8
        jsr     LC808
L82B8:  jmp     L82C8

L82BB:  lda     $37
        cmp     #$03
        bne     L82C8
        lda     #$01
        sta     $2C
        jmp     LC10B

L82C8:  lda     #$00
        sta     $37
L82CC:  rts

        .byte   $40,$00,$80
L82D0:  .byte   $20,$80,$20,$40,$00
L82D5:  sec
        lda     $AD
        sbc     #$76
        tay
        lda     #$00
        sta     $AD
        lda     L84DC,y
        sta     jump_ptr
        lda     L84E5,y
        sta     $09
        jmp     (jump_ptr)

        .byte   $A9,$0A,$D0,$02,$A9,$02
        sta     $FD
        lda     $06C0
        cmp     #$1C
        bcs     L8326
        lda     #$07
        sta     $AA
L82FF:  ldx     $A9
        lda     $06C0
        cmp     #$1C
        bcs     L8323
        lda     $1C
        and     #$07
        bne     L831A
        dec     $FD
        bmi     L8323
        inc     $06C0
        lda     #$28
        jsr     bank_switch_enqueue
L831A:  jsr     LCC77
        jsr     LC07F
        jmp     L82FF

L8323:  jmp     L8361

L8326:  rts

        .byte   $A9,$0A,$D0,$02,$A9,$02
        sta     $FD
        lda     $A9
        beq     L836E
        ldx     $A9
        lda     $9B,x
        cmp     #$1C
        beq     L836E
        lda     #$07
        sta     $AA
L833F:  ldx     $A9
        lda     $9B,x
        cmp     #$1C
        bcs     L8361
        lda     $1C
        and     #$07
        bne     L8358
        dec     $FD
        bmi     L8361
        inc     $9B,x
        lda     #$28
        jsr     bank_switch_enqueue
L8358:  jsr     LCC77
        jsr     LC07F
        jmp     L833F

L8361:  lda     #$00
        sta     $FD
        sta     $AA
        lda     #$03
        sta     $2C
        jsr     LD3A8
L836E:  rts

        .byte   $A5,$A7,$C9,$04,$B0,$02,$E6,$A7
        lda     #$42
        jsr     bank_switch_enqueue
        rts

        .byte   $A5,$A8,$C9,$63,$B0,$07
        inc     $A8
        lda     #$42
        jsr     bank_switch_enqueue
        rts

        jsr     L83DF
        lda     #$00
        sta     $FD
        ldx     $BA
        lda     L83D6,x
        sta     $FE
        dex
        stx     $2A
        jsr     L8416
        lda     #$0C
        sta     $2A
        ldx     #$05
        lda     $BA
        cmp     #$04
        bne     L83AD
        ldx     #$02
L83AD:  jsr     L8481
        inc     $20
        inc     $0440
        inc     $38
        inc     $14
        inc     $15
        lda     #$20
        sta     $0460
        lda     #$B4
        sta     $04A0
        jsr     L8407
        lda     #$0B
        jsr     bank_switch_enqueue
        lda     $BA
        sta     $B3
        dec     $B3
        jsr     LC80C
L83D6:  rts

        .byte   $06,$04,$0D,$07,$11,$09,$04,$10
L83DF:  lda     #$30
        jsr     bank_switch_enqueue
        lda     #$0B
        sta     $2C
        jsr     LD3A8
        jsr     L9220
L83EE:  lda     $06A0
        cmp     #$03
        beq     L83FE
        jsr     LCC77
        jsr     LC07F
        jmp     L83EE

L83FE:  lda     #$00
        sta     $0420
        jsr     LCC77
        rts

L8407:  lda     #$C0
        sta     $0420
        lda     #$00
        sta     $36
        sta     $2C
        jsr     LD3A8
        rts

L8416:  jsr     LCB0C
        jsr     LC07F
        lda     $FD
        cmp     #$60
        bne     L8416
        rts

        .byte   $20,$DF,$83,$A6,$B3,$A5,$BC,$1D
        .byte   $79,$C2,$85,$BC,$C9,$FF,$D0,$1D
        .byte   $A9,$00,$85,$FD,$A9,$14,$85,$FE
        .byte   $20,$16,$84,$A9,$28,$20,$7D,$90
        .byte   $A9,$28,$85,$20,$8D,$40,$04,$85
        .byte   $14,$85,$15,$D0,$0B
        dec     $20
        dec     $0440
        dec     $38
        dec     $14
        dec     $15
        ldx     #$08
        jsr     L8481
        lda     #$00
        sta     $B1
        ldx     $B3
        clc
        lda     L8268,x
        adc     #$07
        sta     $04A0
        lda     L8270,x
        sta     $0460
        jsr     L8407
        lda     #$09
        jsr     bank_switch_enqueue
        jsr     L81DE
        rts

L8481:  ldy     #$02
L8483:  lda     L849A,x
        sta     $035F,y
        sta     $037F,y
        sta     $038F,y
        sta     $039F,y
        sta     $03AF,y
        dex
        dey
        bpl     L8483
        rts

L849A:  and     ($11,x)
        ora     ($19,x)
        ora     #$0A
        ora     $2109,y
        jsr     L83DF
        lda     #$29
        jsr     L907D
        lda     #$29
        sta     $20
        sta     $0440
        sta     $14
        sta     $15
        lda     #$00
        sta     $FD
        lda     #$15
        sta     $FE
        jsr     L8416
        lda     #$2A
        jsr     L907D
        lda     #$B4
        sta     $04A0
        lda     #$28
        sta     $0460
        jsr     L8407
        lda     #$0B
        jsr     bank_switch_enqueue
        jsr     LC808
        rts

L84DC:  cpx     $27F0
        .byte   $2B,$6F,$7D,$8B,$23,$A3
L84E5:  .byte   $82,$82,$83,$83,$83,$83,$83,$84
        .byte   $84
L84EE:  lda     $AA
        and     #$04
        beq     L84F5
        rts

L84F5:  lda     #$00
        sta     $37
        ldx     $2C
        lda     L8783,x
        sta     jump_ptr
        lda     L878F,x
        sta     $09
        jmp     (jump_ptr)

        lda     $06A0
        cmp     #$04
        bne     L8544
        lda     #$C0
        sta     $0660
        lda     #$FF
        sta     $0640
        lda     #$00
        sta     $AA
        lda     #$03
        sta     $2C
        jsr     LD3A8
        lda     $0460
        sta     jump_ptr
        lda     $0440
        sta     $09
        lda     $04A0
        sta     $0A
        lda     #$00
        sta     $0B
        jsr     LCBC3
        lda     $00
        cmp     #$04
        bne     L8544
        lda     #$04
        sta     $FB
L8544:  rts

        .byte   $60,$AD,$20,$04,$29,$40,$49,$40
        .byte   $85,$42,$20,$22,$89,$20,$83,$8B
        .byte   $AD,$A0,$06,$F0,$04,$20,$A8,$D3
        .byte   $60
        ldy     #$06
        lda     $00
        beq     L8566
        ldy     #$03
L8566:  sty     $2C
        rts

        .byte   $20,$9B,$87,$A5,$23,$29,$C0,$F0
        .byte   $07,$A9,$04,$85,$2C
        jsr     L87F2
        jsr     L880D
        jsr     L8922
        jsr     L8B83
        lda     $00
        bne     L858E
        lda     #$06
        sta     $2C
        jsr     LD3A8
        rts

L858E:  lda     $27
        and     #$01
        beq     L85A2
        lda     $3B
        sta     $0660
        lda     $3C
        sta     $0640
        lda     #$06
        sta     $2C
L85A2:  jsr     LD3A8
        rts

        .byte   $20,$9B,$87,$20,$F2,$87,$20,$0D
        .byte   $88,$20,$22,$89
        jsr     L8B83
        lda     $00
        beq     L85E6
        lda     $23
        and     #$C0
        bne     L85C5
        lda     #$03
        sta     $2C
        bne     L85D0
L85C5:  lda     $06A0
        cmp     #$01
        bne     L85D0
        lda     #$05
        sta     $2C
L85D0:  jmp     L858E

        .byte   $20,$9B,$87,$20,$F2,$87,$20,$0D
        .byte   $88,$20,$22,$89,$20,$83,$8B,$A5
        .byte   $00,$D0,$08
L85E6:  lda     #$06
        sta     $2C
        jsr     LD3A8
        rts

        lda     $23
        and     #$C0
        bne     L85F8
        lda     #$07
        sta     $2C
L85F8:  jmp     L858E

        jsr     L879B
        .byte   $A9,$00,$8D
        jsr     L8D06
        brk
        asl     $A5
        .byte   $23
        and     #$C0
        bne     L863C
        lda     $3E
        ora     $3F
        bne     L861E
        lda     $40
        and     #$0F
        beq     L8642
        jsr     L889E
        jmp     L8642

L861E:  sec
        lda     $3E
        sbc     #$80
        sta     $3E
        tax
        lda     $3F
        sbc     #$00
        sta     $3F
        bmi     L8634
        bne     L8642
        cpx     #$80
        bcs     L8642
L8634:  lda     #$00
        sta     $3E
        sta     $3F
        beq     L8642
L863C:  jsr     L87F2
        jsr     L880D
L8642:  jsr     L8922
        lda     $0640
        bmi     L866D
        jsr     L8B83
        lda     $00
        bne     L866C
        lda     $23
        and     #$01
        bne     L866C
        lda     $0640
        bmi     L866C
        cmp     #$01
        bcc     L866C
        beq     L866C
        lda     #$01
        sta     $0640
        lda     #$00
        sta     $0660
L866C:  rts

L866D:  jsr     L8B83
        lda     $00
        beq     L8688
        lda     #$29
        jsr     bank_switch_enqueue
        ldx     #$05
        lda     $25
        and     #$C0
        bne     L8683
        ldx     #$08
L8683:  stx     $2C
        jmp     L858E

L8688:  jsr     LD3A8
        rts

        .byte   $20,$9B,$87,$20,$F2,$87,$20,$0D
        .byte   $88,$20,$22,$89,$20,$83,$8B,$A5
        .byte   $00,$D0,$03,$4C,$E6,$85
        lda     $23
        and     #$C0
        bne     L86B5
        lda     $06A0
        cmp     #$02
        bne     L86B9
        lda     #$03
        sta     $2C
        bne     L86B9
L86B5:  lda     #$04
        sta     $2C
L86B9:  jmp     L858E

L86BC:  lda     #$09
        sta     $2C
        lda     $23
        and     #$02
        beq     L86C9
        jmp     L8768

L86C9:  lda     #$00
        sta     $AB
L86CD:  lda     $23
        and     #$31
        bne     L86D6
        jmp     L875F

L86D6:  and     #$30
        beq     L874B
        and     #$10
        beq     L8708
        ldy     #$00
        ldx     #$C0
        lda     $35
        and     #$0C
        bne     L86FE
        lda     $04A0
        and     #$F0
        sec
        sbc     #$0C
        sta     $04A0
        lda     $F9
        sbc     #$00
        sta     $F9
        ldx     #$03
        jmp     L874D

L86FE:  and     #$08
        bne     L872B
        lda     #$0A
        sta     $2C
        bne     L872B
L8708:  lda     $35
        cmp     #$01
        bne     L871D
        lda     $04A0
        clc
        adc     #$0C
        sta     $04A0
        lda     $F9
        adc     #$00
        sta     $F9
L871D:  ldy     #$FF
        ldx     #$40
        lda     $35
        and     #$0C
        bne     L872B
        lda     #$0A
        sta     $2C
L872B:  lda     $3D
        beq     L8733
        ldy     #$00
        ldx     #$00
L8733:  sty     $0640
        stx     $0660
        jsr     L8A84
        lda     $35
        beq     L874B
        jsr     L8B83
        lda     $00
        beq     L8764
        ldx     #$03
        bne     L874D
L874B:  ldx     #$06
L874D:  stx     $2C
        lda     #$00
        sta     $35
        lda     #$C0
        sta     $0660
        lda     #$FF
        sta     $0640
        bne     L8764
L875F:  lda     #$00
        sta     $0680
L8764:  jsr     LD3A8
        rts

L8768:  jsr     L87F2
        jsr     LDA51
        bcc     L8773
        jmp     L86CD

L8773:  jmp     L875F

        .byte   $AD,$A0,$06,$C9,$03,$D0,$05,$A9
        .byte   $00,$8D,$80,$06
        rts

L8783:  php
        eor     $46
        adc     #$A6
        .byte   $D3
        .byte   $FB,$8C,$8C,$BC,$BC,$76
L878F:  .byte   $85,$85,$85,$85,$85,$85,$85,$86
        .byte   $86,$86,$86,$87
L879B:  lda     $23
        and     #$02
        bne     L87A7
        lda     #$00
        sta     $AB
        beq     L87AA
L87A7:  jsr     LDA51
L87AA:  lda     $35
        bne     L87AF
L87AE:  rts

L87AF:  lda     $23
        and     #$30
        beq     L87AE
        ora     $35
        cmp     #$11
        beq     L87AE
        cmp     #$2E
        beq     L87AE
        lda     $0460
        sta     $2E
        and     #$F0
        ora     #$08
        sec
        sta     $0460
        sbc     $2E
        bcc     L87D8
        sta     $00
        jsr     L8DF5
        jmp     L87E2

L87D8:  eor     #$FF
        clc
        adc     #$01
        sta     $00
        jsr     L8E65
L87E2:  lda     $0420
        eor     #$40
        sta     $0420
        jsr     LD3A8
        pla
        pla
        jmp     L86BC

L87F2:  lda     $23
        and     #$C0
        beq     L880C
        lda     $0420
        and     #$BF
        sta     $0420
        lda     $23
        and     #$40
        eor     #$40
        ora     $0420
        sta     $0420
L880C:  rts

L880D:  ldx     $2C
        lda     L890C,x
        sta     $0600
        lda     L8917,x
        sta     $0620
        lda     $3D
        cmp     #$03
        bne     L882F
        lda     $2C
        cmp     #$06
        beq     L882F
        lda     #$00
        sta     $0620
        sta     $0600
L882F:  lda     $40
        bmi     L883B
        lda     $3E
        ora     $3F
        beq     L889E
        bne     L8844
L883B:  lda     $0420
        and     #$40
        cmp     $42
        beq     L8880
L8844:  ldx     #$00
        lda     $2C
        cmp     #$06
        beq     L8854
        inx
        lda     $23
        and     #$C0
        beq     L8854
        inx
L8854:  sec
        lda     $3E
        sbc     L8909,x
        sta     $3E
        tax
        lda     $3F
        sbc     #$00
        sta     $3F
        bmi     L886B
        bne     L8873
        cpx     #$80
        bcs     L8873
L886B:  lda     #$00
        sta     $3E
        sta     $3F
        beq     L8897
L8873:  lda     $3E
        sta     $0620
        lda     $3F
        sta     $0600
        jmp     L889E

L8880:  sec
        lda     $0620
        sbc     $3E
        lda     $0600
        sbc     $3F
        bcc     L8844
        lda     $0620
        sta     $3E
        lda     $0600
        sta     $3F
L8897:  lda     $0420
        and     #$40
        sta     $42
L889E:  lda     $40
        bpl     L88A3
        rts

L88A3:  and     #$0F
        beq     L88FA
        lda     $0420
        and     #$40
        cmp     $AF
        beq     L88E4
        sec
        lda     $0620
        sbc     $4F
        sta     $0620
        lda     $0600
        sbc     $50
        sta     $0600
        bcc     L88CB
        lda     $0420
        and     #$40
        sta     $42
        rts

L88CB:  lda     $0620
        eor     #$FF
        adc     #$01
        sta     $0620
        lda     $0600
        eor     #$FF
        adc     #$00
        sta     $0600
        lda     $AF
        sta     $42
        rts

L88E4:  clc
        lda     $0620
        adc     $4F
        sta     $0620
        lda     $0600
        adc     $50
        sta     $0600
        lda     $AF
        sta     $42
        rts

L88FA:  lda     $3F
        ora     $3E
        beq     L8901
        rts

L8901:  lda     $0420
        and     #$40
        sta     $42
        rts

L8909:  .byte   $80,$02,$04
L890C:  .byte   $00,$00,$00,$00,$00,$01,$01,$00
        .byte   $00,$00,$00
L8917:  .byte   $00,$00,$90,$00
        jsr     L5060
        .byte   $80,$00,$00,$00
L8922:  ldx     $0440
        stx     $2D
        ldy     $0460
        sty     $2E
        lda     $0480
        sta     $2F
        lda     #$00
        sta     $00
        lda     $42
        and     #$40
        beq     L89AB
        cpx     $15
        bne     L894A
        cpy     #$EC
        bcc     L894A
        lda     #$02
        sta     $37
        jmp     L8A12

L894A:  clc
        lda     $0480
        adc     $0620
        sta     $0480
        lda     $0460
        adc     $0600
        sta     $0460
        lda     $0440
        adc     #$00
        sta     $0440
        clc
        lda     $0460
        adc     #$08
        sta     jump_ptr
        lda     $0440
        adc     #$00
        sta     $09
        jsr     L8A20
        lda     $00
        beq     L8997
        lda     #$00
        sta     $0480
        lda     jump_ptr
        and     #$0F
        sta     $00
        sec
        lda     $0460
        sbc     $00
        sta     $0460
        lda     $0440
        sbc     #$00
        sta     $0440
L8997:  sec
        lda     $0460
        sbc     $2E
        sta     $00
        bpl     L8A12
        clc
        eor     #$FF
        adc     #$01
        sta     $00
        jmp     L8A19

L89AB:  cpx     $14
        bne     L89B6
        cpy     #$14
        bcs     L89B6
        jmp     L8A19

L89B6:  sec
        lda     $0480
        sbc     $0620
        sta     $0480
        lda     $0460
        sbc     $0600
        sta     $0460
        lda     $0440
        sbc     #$00
        sta     $0440
        sec
        lda     $0460
        sbc     #$08
        sta     jump_ptr
        lda     $0440
        sbc     #$00
        sta     $09
        jsr     L8A20
        lda     $00
        beq     L8A01
        lda     #$00
        sta     $0480
        lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     $0460
        sta     $0460
        lda     $0440
        adc     #$00
        sta     $0440
L8A01:  sec
        lda     $2E
        sbc     $0460
        sta     $00
        bpl     L8A19
        eor     #$FF
        clc
        adc     #$01
        sta     $00
L8A12:  jsr     L8DF5
        jsr     L8A84
        rts

L8A19:  jsr     L8E65
        jsr     L8A84
        rts

L8A20:  lda     #$02
        sta     $01
L8A24:  ldx     $01
        clc
        lda     $04A0
        adc     L8A7E,x
        sta     $0A
        lda     $F9
        adc     L8A81,x
        sta     $0B
        jsr     LCBA2
        ldx     $01
        lda     $00
        sta     $32,x
        dec     $01
        bpl     L8A24
        lda     #$00
        sta     $00
        ldx     #$02
L8A49:  ldy     $32,x
        lda     L8A75,y
        bpl     L8A56
        ldy     #$02
        sty     $37
        bne     L8A65
L8A56:  cmp     #$03
        bne     L8A65
        ldy     $4B
        bne     L8A65
        lda     #$00
        sta     $2C
        jmp     LC10B

L8A65:  ora     $00
        sta     $00
        dex
        bpl     L8A49
        rts

L8A6D:  .byte   $40,$1E
L8A6F:  .byte   $00,$04
L8A71:  .byte   $04,$05
L8A73:  .byte   $DF,$80
L8A75:  .byte   $00,$01,$00,$03,$00,$01,$01,$01
        .byte   $81
L8A7E:  .byte   $F4,$FC,$0B
L8A81:  .byte   $FF,$FF,$00
L8A84:  lda     $0460
        sta     jump_ptr
        lda     $0440
        sta     $09
        lda     #$02
        sta     $01
L8A92:  ldx     $01
        clc
        lda     $04A0
        adc     L8A7E,x
        sta     $0A
        lda     $F9
        adc     L8A81,x
        sta     $0B
        jsr     LCBC3
        ldx     $01
        lda     $00
        sta     $32,x
        dec     $01
        bpl     L8A92
        ldx     #$00
        lda     $B1
        beq     L8ABD
        lda     $B3
        cmp     #$03
        beq     L8AE8
L8ABD:  lda     $33
        cmp     #$04
        bne     L8B12
        lda     $FB
        bne     L8AE8
        lda     $0640
        bpl     L8AE8
        lda     #$3B
        jsr     bank_switch_enqueue
        lda     $042E
        bmi     L8AE8
        ldy     #$0E
        ldx     #$0E
        jsr     LD3E0
        sec
        lda     $04AE
        sbc     #$04
        and     #$F0
        sta     $04AE
L8AE8:  inc     $39
        lda     $39
        cmp     #$60
        bcc     L8B0F
        beq     L8AFA
        cmp     #$80
        bcc     L8B0F
        lda     #$00
        sta     $39
L8AFA:  lda     $F9
        bne     L8B0F
        stx     $2B
        lda     #$0E
        jsr     LF159
        bcs     L8B0F
        lda     $0430,y
        and     #$F0
        sta     $0430,y
L8B0F:  ldx     #$00
        inx
L8B12:  lda     L8A6D,x
        sta     $30
        lda     L8A6F,x
        sta     $FB
        lda     L8A71,x
        sta     $3C
        lda     L8A73,x
        sta     $3B
        lda     #$00
        sta     $35
        lda     #$02
        sta     $01
        ldx     #$02
L8B30:  lda     $32,x
        cmp     #$02
        bne     L8B3C
        lda     $01
        ora     $35
        sta     $35
L8B3C:  asl     $01
        dex
        bpl     L8B30
        sec
        lda     $04C0
        sbc     $0660
        lda     $04A0
        sbc     $0640
        ldx     $0640
        bmi     L8B5F
        sec
        sbc     #$0C
        sta     $0A
        lda     $F9
        sbc     #$00
        jmp     L8B68

L8B5F:  clc
        adc     #$0C
        sta     $0A
        lda     $F9
        adc     #$00
L8B68:  sta     $0B
        jsr     LCBC3
        lda     $00
        cmp     #$02
        bne     L8B82
        lda     $0640
        bmi     L8B7C
        lda     #$10
        bne     L8B7E
L8B7C:  lda     #$01
L8B7E:  ora     $35
        sta     $35
L8B82:  rts

L8B83:  lda     $04A0
        sta     $2E
        lda     $04C0
        sta     $2F
        lda     #$00
        sta     $00
        lda     $0640
        bpl     L8B98
        dec     $00
L8B98:  sec
        lda     $04C0
        sbc     $0660
        sta     $04C0
        lda     $04A0
        sbc     $0640
        sta     $04A0
        tax
        lda     $F9
        sbc     $00
        sta     $F9
        cpx     #$04
        bcs     L8BC6
        lda     $2C
        cmp     #$09
        beq     L8BC0
        cmp     #$0A
        bne     L8BD2
L8BC0:  lda     #$01
        sta     $37
        bne     L8BD2
L8BC6:  cpx     #$E8
        bcc     L8BD2
        lda     $F9
        bmi     L8BD2
        lda     #$03
        sta     $37
L8BD2:  lda     $0640
        bmi     L8C28
        sec
        lda     $04A0
        sbc     #$0C
        sta     $0A
        lda     $F9
        sbc     #$00
        sta     $0B
        jsr     L8C6A
        lda     $00
        beq     L8C06
        lda     #$00
        sta     $04C0
        lda     $0A
        and     #$0F
        eor     #$0F
        sec
        adc     $04A0
        sta     $04A0
L8BFE:  lda     #$00
        sta     $0660
        sta     $0640
L8C06:  sec
        lda     $0660
        sbc     $30
        sta     $0660
        lda     $0640
        sbc     $31
        sta     $0640
        bpl     L8C27
        cmp     #$F4
        bcs     L8C27
        lda     #$00
        sta     $0660
        lda     #$F4
        sta     $0640
L8C27:  rts

L8C28:  clc
        lda     $04A0
        adc     #$0C
        sta     $0A
        lda     $F9
        adc     #$00
        sta     $0B
        jsr     L8C6A
        jsr     L8CF4
        lda     $00
        bne     L8C44
        bcs     L8C65
        bcc     L8C06
L8C44:  lda     #$00
        sta     $04C0
        lda     $04A0
        pha
        lda     $0A
        and     #$0F
        sta     $04A0
        pla
        sec
        sbc     $04A0
        sta     $04A0
        lda     $F9
        sbc     #$00
        sta     $F9
        jmp     L8BFE

L8C65:  lda     #$01
        sta     $00
        rts

L8C6A:  lda     #$01
        sta     $01
L8C6E:  ldx     $01
        clc
        lda     $0460
        adc     L8CED,x
        sta     jump_ptr
        lda     $0440
        adc     L8CEF,x
        sta     $09
        jsr     LCBA2
        ldx     $01
        lda     $00
        sta     $32,x
        dec     $01
        bpl     L8C6E
        lda     #$00
        sta     $40
        ldx     #$01
L8C94:  lda     $32,x
        cmp     #$08
        bcs     L8CBA
        cmp     #$05
        bcc     L8CBA
        sbc     #$05
        tay
        lda     L8CF1,y
        sta     $40
        bmi     L8CB6
        tay
        lda     $44,y
        sta     $AF
        lda     #$01
        sta     $50
        lda     #$00
        sta     $4F
L8CB6:  lda     #$01
        bne     L8CD2
L8CBA:  cmp     #$03
        bne     L8CC9
        ldy     $4B
        bne     L8CC9
        lda     #$00
        sta     $2C
        jmp     LC10B

L8CC9:  dex
        bpl     L8C94
        lda     $32
        ora     $33
        and     #$01
L8CD2:  sta     $00
        lda     $35
        beq     L8CEC
        cmp     #$01
        beq     L8CEA
        ldx     $F9
        bpl     L8CEC
        lda     $23
        and     #$30
        beq     L8CEC
        ldx     #$01
        stx     $37
L8CEA:  sta     $00
L8CEC:  rts

L8CED:  .byte   $07,$F9
L8CEF:  .byte   $00,$FF
L8CF1:  .byte   $01,$02,$80
L8CF4:  sec
        lda     $0460
        sbc     $1F
        sta     jump_ptr
        clc
        lda     $2E
        adc     #$0C
        sta     $09
        lda     $A9
        .byte   $C9
L8D06:  ora     #$90
        asl     a
        ldx     #$02
L8D0B:  lda     $05A0,x
        bne     L8D86
L8D10:  dex
        bpl     L8D0B
        ldx     #$0F
L8D15:  lda     $0160,x
        bne     L8D1F
L8D1A:  dex
        bpl     L8D15
        clc
        rts

L8D1F:  lda     $F9
        bne     L8D1A
        sec
        lda     $0470,x
        sbc     $1F
        sta     $0C
        sec
        sbc     jump_ptr
        bcs     L8D34
        eor     #$FF
        adc     #$01
L8D34:  cmp     $0160,x
        bcs     L8D1A
        lda     $04B0,x
        cmp     $09
        bcc     L8D1A
        lda     $0170,x
        cmp     $0A
        beq     L8D49
        bcs     L8D1A
L8D49:  lda     $0410,x
        cmp     #$13
        bne     L8D53
        inc     $04F0,x
L8D53:  sec
        lda     $0170,x
        sbc     #$0C
        sta     $04A0
        lda     $F9
        sbc     #$00
        sta     $F9
        lda     #$00
        sta     $04C0
        sta     $0660
        lda     #$FF
        sta     $0640
        lda     #$01
        sta     $40
        lda     $0430,x
        and     #$40
        sta     $AF
        lda     $0630,x
        sta     $4F
        lda     $0610,x
        sta     $50
        sec
        rts

L8D86:  lda     $F9
        bne     L8DF2
        sec
        lda     $0462,x
        sbc     $1F
        sta     $0C
        sec
        sbc     jump_ptr
        bcs     L8D9B
        eor     #$FF
        adc     #$01
L8D9B:  cmp     $05A0,x
        bcs     L8DF2
        lda     $04A2,x
        cmp     $09
        bcc     L8DF2
        lda     $05A3,x
        cmp     $0A
        beq     L8DB0
        bcs     L8DF2
L8DB0:  lda     $0402,x
        cmp     #$3A
        bne     L8DBF
        lda     $04E2,x
        ora     #$80
        sta     $04E2,x
L8DBF:  sec
        lda     $05A3,x
        sbc     #$0C
        sta     $04A0
        lda     $F9
        sbc     #$00
        sta     $F9
        lda     #$00
        sta     $04C0
        sta     $0660
        lda     #$FF
        sta     $0640
        lda     #$01
        sta     $40
        lda     $0422,x
        and     #$40
        sta     $AF
        lda     $0622,x
        sta     $4F
        lda     $0602,x
        sta     $50
        sec
        rts

L8DF2:  jmp     L8D10

L8DF5:  sec
        lda     $0460
        sbc     $1F
        cmp     #$80
        bcs     L8E00
        rts

L8E00:  clc
        lda     $1F
        pha
        adc     $00
        sta     $1F
        lda     $20
        adc     #$00
        sta     $20
        cmp     $15
        bne     L8E1F
        sec
        lda     $00
        sbc     $1F
        sta     $00
        lda     #$00
        sta     $1F
        sta     $1E
L8E1F:  pla
        and     #$03
        adc     $00
        lsr     a
        lsr     a
        sta     $01
        beq     L8E64
        clc
        lda     $18
        sta     jump_ptr
        adc     $01
        sta     $18
        lda     $19
        sta     $09
        adc     #$00
        sta     $19
        clc
        lda     $16
        adc     $01
        sta     $16
        lda     $17
        adc     #$00
        sta     $17
L8E48:  jsr     LC96B
        inc     $1A
        lda     $1A
        and     #$3F
        sta     $1A
        clc
        lda     jump_ptr
        adc     #$01
        sta     jump_ptr
        lda     $09
        adc     #$00
        sta     $09
        dec     $01
        bne     L8E48
L8E64:  rts

L8E65:  sec
        lda     $0460
        sbc     $1F
        cmp     #$80
        bcc     L8E70
        rts

L8E70:  sec
        lda     $1F
        pha
        sbc     $00
        sta     $1F
        lda     $20
        sbc     #$00
        sta     $20
        ldx     $14
        dex
        cpx     $20
        bne     L8E94
        inc     $20
        clc
        lda     $00
        adc     $1F
        sta     $00
        lda     #$00
        sta     $1F
        sta     $1E
L8E94:  clc
        pla
        eor     #$FF
        and     #$03
        adc     $00
        lsr     a
        lsr     a
        sta     $01
        beq     L8EDC
        sec
        lda     $16
        sta     jump_ptr
        sbc     $01
        sta     $16
        lda     $17
        sta     $09
        sbc     #$00
        sta     $17
        sec
        lda     $18
        sbc     $01
        sta     $18
        lda     $19
        sbc     #$00
        sta     $19
L8EC0:  jsr     LC96B
        dec     $1A
        lda     $1A
        and     #$3F
        sta     $1A
        sec
        lda     jump_ptr
        sbc     #$01
        sta     jump_ptr
        lda     $09
        sbc     #$00
        sta     $09
        dec     $01
        bne     L8EC0
L8EDC:  rts

L8EDD:  jsr     L9220
        ldx     $14
        dex
        stx     $15
        dec     $38
        ldy     $38
        jsr     LC7A4
        tya
        and     #$1F
        sta     $14
        txa
        sec
        sbc     $14
        sta     $14
        lda     $15
        jsr     L907D
        dec     $0440
        lda     $38
        sta     $FE
        jsr     L90C9
        dec     $20
        sec
        lda     $16
        sbc     #$40
        sta     $16
        lda     $17
        sbc     #$00
        sta     $17
        sec
        lda     $18
        sbc     #$40
        sta     $18
        lda     $19
        sbc     #$00
        sta     $19
        jsr     LC07F
        sec
        lda     $15
        sbc     #$01
        jsr     L907D
        lda     #$00
        sta     $F9
        lda     #$00
        sta     $42
        jsr     LD658
        rts

L8F39:  jsr     L9220
        ldx     $15
        inx
        txa
        pha
        jsr     L907D
        inc     $0440
        lda     $37
        and     #$01
        bne     L8F91
        lda     #$18
        sta     $FD
        lda     #$00
        sta     $FE
L8F55:  ldx     $2A
        lda     $20
        cmp     L9061,x
        bcc     L8F91
        lda     $FD
        and     #$07
        bne     L8F85
        lda     #$34
        jsr     bank_switch_enqueue
        lda     $20
        sta     $09
        lda     #$F0
        sta     jump_ptr
        lda     $FD
        asl     a
        adc     L9045,x
        sta     $0A
        jsr     LC8EF
        jsr     LC91B
        lda     #$80
        sta     $54
        inc     $51
L8F85:  jsr     LC07F
        dec     $FD
        bpl     L8F55
        lda     #$FE
        jsr     bank_switch_enqueue
L8F91:  lda     $38
        sta     $FE
        inc     $FE
        jsr     L90C9
        inc     $20
        jsr     LC07F
        clc
        lda     $15
        adc     #$02
        jsr     L907D
        inc     $38
        ldy     $38
        jsr     LC7A4
        tya
        and     #$1F
        sta     $14
        pla
        tax
        clc
        adc     $14
        sta     $15
        stx     $14
        clc
        lda     $18
        adc     #$40
        sta     $18
        lda     $19
        adc     #$00
        sta     $19
        clc
        lda     $16
        adc     #$40
        sta     $16
        lda     $17
        adc     #$00
        sta     $17
        lda     #$00
        sta     $F9
        lda     $37
        and     #$01
        bne     L903D
        lda     #$00
        sta     $FD
        sta     $FE
L8FE6:  ldx     $2A
        lda     $20
        cmp     L9061,x
        bcc     L903D
        cmp     L906F,x
        bne     L9003
        lda     #$0B
        jsr     bank_switch_enqueue
        lda     $2A
        cmp     #$0B
        beq     L9003
        cmp     #$08
        bcs     L903D
L9003:  lda     $FD
        and     #$07
        bne     L902D
        lda     #$34
        jsr     bank_switch_enqueue
        lda     $20
        sta     $09
        lda     #$00
        sta     jump_ptr
        lda     $FD
        asl     a
        adc     L9045,x
        sta     $0A
        jsr     LC8EF
        ldx     $2A
        lda     L9053,x
        jsr     LC91B
        inc     $54
        inc     $51
L902D:  jsr     LC07F
        inc     $FD
        lda     $FD
        cmp     #$19
        bne     L8FE6
        lda     #$FE
        jsr     bank_switch_enqueue
L903D:  lda     #$40
        sta     $42
        jsr     LD658
        rts

L9045:  .byte   $60,$40,$40,$40,$40,$40,$40,$40
        .byte   $00,$00,$80,$80,$00,$80
L9053:  .byte   $00,$55,$AA,$00,$00,$55,$00,$AA
        .byte   $00,$00,$00,$00,$00,$00
L9061:  .byte   $15,$13,$15,$13,$15,$11,$13,$11
        .byte   $00,$00,$26,$25,$00,$1E
L906F:  .byte   $17,$15,$17,$15,$17,$13,$15,$13
        .byte   $00,$27,$27,$26,$00,$1F
L907D:  ldx     #$00
        stx     jump_ptr
        lsr     a
        ror     jump_ptr
        lsr     a
        ror     jump_ptr
        clc
        adc     #$85
        sta     $09
        lda     $1A
        pha
        lda     #$00
        sta     $1A
L9093:  jsr     LC96B
        inc     jump_ptr
        inc     $1A
        jsr     LC96B
        lda     jump_ptr
        pha
        lda     $09
        pha
        lda     $F7
        and     #$80
        beq     L90AF
        jsr     LC07F
        jmp     L90B4

L90AF:  lda     $1B
        jsr     ppu_buffer_transfer
L90B4:  clc
        pla
        sta     $09
        pla
        sta     jump_ptr
        inc     jump_ptr
        inc     $1A
        lda     jump_ptr
        and     #$3F
        bne     L9093
        pla
        sta     $1A
        rts

L90C9:  lda     $37
        and     #$01
        beq     L90D2
        jmp     L9185

L90D2:  jsr     L9115
        lda     #$00
        sta     $3E
        sta     $3F
        sta     $FD
        ldy     #$3F
L90DF:  tya
        pha
        lda     #$01
        clc
        lda     $1F
        adc     #$04
        sta     $1F
        clc
        lda     $0480
        adc     #$C0
        sta     $0480
        lda     $0460
        adc     #$00
        sta     $0460
        lda     $A9
        cmp     #$01
        bne     L9104
        jsr     L91FA
L9104:  jsr     LCC77
        jsr     LCB0C
        jsr     LC07F
        pla
        tay
        dey
        bne     L90DF
        sty     $1F
        rts

L9115:  ldx     $2A
        cpx     #$03
        bne     L9121
        ldy     $38
        cpy     #$04
        beq     L9147
L9121:  ldy     L9148,x
        beq     L9147
        lda     L9164,x
        sta     $FD
        lda     L9156,x
        tax
L912F:  lda     L9172,x
        sta     $0356,y
        sta     $0376,y
        sta     $0386,y
        sta     $0396,y
        sta     $03A6,y
        dex
        dey
        dec     $FD
        bne     L912F
L9147:  rts

L9148:  .byte   $00,$0B,$00,$0B,$00,$00,$00,$0F
        .byte   $00,$00,$03,$00,$00,$0B
L9156:  .byte   $00,$02,$00,$05,$00,$00,$00,$0C
        .byte   $00,$00,$0F,$00,$00,$12
L9164:  .byte   $00,$03,$00,$03,$00,$00,$00,$07
        .byte   $00,$00,$03,$00,$00,$03
L9172:  .byte   $2B,$1B,$0B,$21,$01,$0F,$39,$18
        .byte   $01,$0F,$39,$18,$0F,$27,$37,$30
        .byte   $0F,$0F,$0F
L9185:  lda     $37
        lsr     a
        bne     L9193
        ldx     #$09
        stx     $2C
        pha
        jsr     LD3A8
        pla
L9193:  tax
        lda     L9212,x
        sta     $39
        lda     L921C,x
        sta     $22
        lda     #$00
        sta     $FD
L91A2:  txa
        pha
        jsr     LCC77
        jsr     LCA16
        jsr     LCB0C
        jsr     LC07F
        pla
        tax
        lda     $A9
        cmp     #$01
        bne     L91BB
        jsr     L91FA
L91BB:  clc
        lda     $04C0
        adc     L9216,x
        sta     $04C0
        lda     $04A0
        adc     L9218,x
        sta     $04A0
        lda     $F9
        adc     L921E,x
        sta     $F9
        clc
        lda     $22
        adc     L921A,x
        sta     $22
        clc
        lda     $39
        adc     L9214,x
        sta     $39
        bmi     L91ED
        cmp     #$3C
        beq     L91ED
        bne     L91A2
L91ED:  lda     #$00
        sta     $21
        sta     $22
        sta     $04C0
        jsr     LCC77
        rts

L91FA:  lda     $0460
        sta     $0462
        lda     $0440
        sta     $0442
        lda     $04A0
        sta     $04A2
        lda     #$00
        sta     $0682
        rts

L9212:  .byte   $3B,$00
L9214:  .byte   $FF,$01
L9216:  .byte   $BF,$41
L9218:  .byte   $03,$FC
L921A:  .byte   $FC,$04
L921C:  .byte   $EF,$00
L921E:  .byte   $00,$FF
L9220:  ldx     #$00
        lda     $A9
        cmp     #$06
        beq     L922C
        cmp     #$01
        bne     L922F
L922C:  ldx     $0422
L922F:  txa
        pha
        lda     #$00
        ldx     #$1F
L9235:  sta     $0420,x
        dex
        bne     L9235
        sta     $05A0
        sta     $05A1
        sta     $05A2
        pla
        sta     $0422
        ldx     #$0F
L924A:  lda     #$FF
        sta     $0100,x
        sta     $0130,x
        lda     #$00
        sta     $0160,x
        dex
        bpl     L924A
        rts

L925B:  sec
        lda     $0460
        sbc     $1F
        sta     $2D
        lda     $AA
        beq     L926B
        cmp     #$04
        bne     L92A2
L926B:  ldx     #$10
        stx     $2B
L926F:  lda     $0420,x
        bpl     L9299
        sec
        lda     $0460,x
        sbc     $1F
        sta     $2E
        lda     $0440,x
        sbc     $20
        sta     $2F
        ldy     $0400,x
        lda     L92F0,y
        sta     jump_ptr
        lda     L9370,y
        sta     $09
        lda     #$92
        pha
        lda     #$98
        pha
        jmp     (jump_ptr)

L9299:  inc     $2B
        ldx     $2B
        cpx     #$20
        bne     L926F
        rts

L92A2:  ldx     #$10
        stx     $2B
L92A6:  lda     $0420,x
        bpl     L92E7
        sec
        lda     $0460,x
        sbc     $1F
        sta     $2E
        lda     $0440,x
        sbc     $20
        sta     $2F
        lda     #$92
        pha
        lda     #$E6
        pha
        ldy     $0400,x
        lda     L93F0,y
        bne     L92D8
        ldy     $0400,x
        lda     L92F0,y
        sta     jump_ptr
        lda     L9370,y
        sta     $09
        jmp     (jump_ptr)

L92D8:  tay
        dey
        lda     L9470,y
        sta     jump_ptr
        lda     L947F,y
        sta     $09
        jmp     (jump_ptr)

L92E7:  inc     $2B
        ldx     $2B
        cpx     #$20
        bne     L92A6
        rts

L92F0:  .byte   $8D,$8D,$23,$55,$D7,$4E,$71,$75
        .byte   $E5,$6F,$76,$2B,$2F,$8F,$2B,$E3
        .byte   $43,$65,$73,$5B,$90,$CE,$81,$22
        .byte   $2B,$D1,$36,$54,$69,$F4,$ED,$46
        .byte   $7E,$85,$A6,$C2,$2B,$5A,$AB,$B8
        .byte   $C5,$2A,$F1,$0D,$2E,$D7,$D7,$D3
        .byte   $F2,$EA,$C3,$EC,$4E,$2B,$89,$A4
        .byte   $12,$8F,$96,$2B,$30,$4C,$A3,$2B
        .byte   $49,$49,$81,$81,$A1,$E0,$1B,$FA
        .byte   $8A,$97,$0B,$12,$12,$2B,$F0,$21
        .byte   $96,$D0,$5C,$69,$6D,$71,$E5,$D7
        .byte   $41,$E3,$2B,$20,$2B,$4B,$67,$2B
        .byte   $2B,$2B,$18,$55,$91,$7A,$B7,$CE
        .byte   $2B,$FE,$32,$EF,$2B,$25,$2B,$2B
        .byte   $98
        lda     $3030
        adc     LA9A9,y
        lda     ($A9),y
        lda     ($A9),y
        lda     #$08
        php
        php
        .byte   $24
L9370:  sty     $94,x
        sta     $95,x
        sta     $96,x
        stx     $96,y
        stx     $97,y
        .byte   $97,$98,$98,$98,$98,$98,$9A,$9A
        .byte   $9A,$9C,$9C,$9D,$9E,$9F,$98,$9F
        .byte   $A1,$A1,$A1,$A2,$A3,$A4,$A4
        ldy     $A4
        ldy     $98
        lda     $A5
        lda     $A5
        ldx     $A6
        .byte   $A7,$A7,$A7,$A7,$A7,$A7,$A8,$A9
        .byte   $A9,$AA,$98,$AB,$AB,$AC,$AC,$AC
        .byte   $98,$AD,$AD,$AD,$98,$AE,$AE,$AF
        .byte   $AF,$AF,$AF,$B0,$B0,$B1,$B1,$B2
        .byte   $B2,$B2,$98,$B2,$B4,$B4,$B4,$B5
        .byte   $B5,$B5,$B5,$B5,$A7,$B6,$B6,$98
        .byte   $B7,$98,$B7,$B7,$98,$98,$98,$B8
        .byte   $B8,$B8,$B9,$B9,$B9,$98,$B9,$BA
        .byte   $BA,$98,$BB,$98,$98,$BB,$BB,$BC
        .byte   $BC,$BC,$BC,$BC,$BC,$BC,$BC,$BC
        .byte   $BC,$BD,$BD,$BD,$BD
L93F0:  .byte   $01,$02,$01,$00,$01,$00,$01,$00
        .byte   $01,$00,$01,$01,$01,$01,$00,$02
        .byte   $02,$02,$03,$04,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$00,$01
        .byte   $00,$01,$01,$08,$01,$00,$00,$00
        .byte   $00,$01,$01,$01,$01,$00,$02,$00
        .byte   $01,$01,$01,$01,$01,$01,$01,$00
        .byte   $01,$00,$01,$01,$01,$01,$05,$01
        .byte   $06,$07,$00,$00,$01,$01,$01,$00
        .byte   $01,$01,$00,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$00,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$00,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$00,$00,$00
        .byte   $00,$01,$01,$01,$01,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
L9470:  .byte   $B3,$AF,$D8,$F1,$0A,$23,$23,$7C
        .byte   $B5,$B5,$B5,$B5,$B5,$B5,$B5
L947F:  .byte   $EF,$EF,$ED,$ED,$EE,$EE,$EE,$EE
        .byte   $EE,$EE,$E6,$EE,$EE,$EE,$BD,$E0
        .byte   $04,$D0,$6F,$9D,$80
        asl     $BD
        bpl     L9499
        .byte   $D0
L9499:  .byte   $42
        lda     #$01
        sta     $0110,x
        lda     #$14
        sta     $04E0,x
        lda     #$05
        sta     $06A0,x
        lda     $4A
        and     #$03
        beq     L94BF
        lda     #$02
        sta     $09
        lda     #$0C
        sta     jump_ptr
        jsr     LF197
        ldx     $2B
        jmp     L9501

L94BF:  jsr     LEFEE
        lda     $DA01
        sta     $0600,x
        lda     $DA02
        sta     $0620,x
        lda     $DA21
        sta     $0640,x
        lda     $DA22
        sta     $0660,x
        bne     L9501
        lda     #$00
        sta     $06A0,x
        sta     $0110,x
        lda     $4A
        and     #$01
        tay
        lda     L9521,y
        sta     $04E0,x
        lda     #$00
        sta     $0620,x
        sta     $0600,x
        lda     #$3C
        sta     $0660,x
        lda     #$FF
        sta     $0640,x
L9501:  dec     $04E0,x
        lda     $06A0,x
        cmp     #$04
        bcc     L951D
        bne     L9514
        lda     #$00
        sta     $06A0,x
        beq     L951D
L9514:  cmp     #$07
        bne     L951D
        lda     #$00
        sta     $0680,x
L951D:  jsr     LEEBA
        rts

L9521:  .byte   $19,$4A,$BD,$E0,$04,$D0,$26,$A0
        .byte   $0F,$A9,$02,$85,$01,$A9,$01,$85
        .byte   $00
L9532:  jsr     LF014
        bcs     L9540
        dec     $01
        beq     L9549
        dey
        bne     L9532
        bne     L9549
L9540:  lda     #$01
        jsr     LF159
        lda     #$31
        bne     L954B
L9549:  lda     #$62
L954B:  sta     $04E0,x
        dec     $04E0,x
        jsr     LEFAF
        rts

        .byte   $BD,$20,$06,$D0,$08,$A9,$03,$20
        .byte   $B5,$95,$90,$01,$60
        lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04E0,x
        bne     L95A8
        lda     #$03
        sta     $01
        lda     #$04
        jsr     L96CF
        bcs     L95A3
        lda     #$04
        jsr     LF159
        bcs     L95A3
        lda     $0110,x
        and     #$01
        tax
        clc
        lda     $0470,y
        adc     L95B1,x
        sta     $0470,y
        lda     $0450,y
        adc     L95B3,x
        sta     $0450,y
        ldx     $2B
        inc     $0110,x
L95A3:  lda     #$4B
        sta     $04E0,x
L95A8:  dec     $04E0,x
        ldy     #$17
        jsr     L998D
        rts

L95B1:  .byte   $50,$C8
L95B3:  .byte   $00,$FF
L95B5:  sta     $00
        ldy     #$0F
L95B9:  jsr     LF014
        bcs     L95D0
        lda     $0630,y
        beq     L95CD
        lsr     $0420,x
        lda     #$00
        sta     a:$F0,x
        sec
        rts

L95CD:  dey
        bne     L95B9
L95D0:  lda     #$01
        sta     $0620,x
        clc
        rts

        .byte   $BD,$20,$06,$D0,$12,$38,$AD,$A0
        .byte   $04,$FD,$A0,$04,$C9,$03,$90,$04
        .byte   $C9,$FE,$90,$4F
        jsr     LEFEE
        lda     $04E0,x
        bne     L9637
        lda     #$0B
        sta     $04E0,x
        lda     $0110,x
        pha
        and     #$07
        tay
        lda     #$00
        sta     $0600,x
        sta     $0640,x
        lda     L963E,y
        sta     $0620,x
        lda     L9646,y
        sta     $0660,x
        pla
        pha
        cmp     #$04
        bcc     L962E
        cmp     #$0C
        bcs     L962E
        lda     $0660,x
        eor     #$FF
        adc     #$01
        sta     $0660,x
        lda     #$FF
        adc     #$00
        sta     $0640,x
L962E:  pla
        clc
        adc     #$01
        and     #$0F
        sta     $0110,x
L9637:  dec     $04E0,x
        jsr     LEEBA
        rts

L963E:  .byte   $17,$5E,$AD,$E3,$E3,$AD,$5E,$17
L9646:  .byte   $F5,$E3,$AD,$5E,$5E,$AD,$E3,$F5
        .byte   $A9,$03,$85,$00
        ldy     #$0F
L9654:  jsr     LF014
        bcs     L9666
        lda     #$00
        sta     $0430,y
        lda     #$FF
        sta     $0100,y
        dey
        bpl     L9654
L9666:  lda     #$00
        sta     $0420,x
        lda     #$FF
        sta     a:$F0,x
        rts

        .byte   $20,$B3,$EF,$60,$BD,$20,$06,$D0
        .byte   $08,$A9,$07,$20,$B5,$95,$90,$01
        .byte   $60
        lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04E0,x
        bne     L96C7
        lda     #$02
        sta     $01
        lda     #$08
        jsr     L96CF
        bcs     L96C2
        lda     #$08
        jsr     LF159
        bcs     L96C2
        lda     $0110,x
        and     #$01
        tax
        lda     $0470,y
        adc     L96CB,x
        sta     $0470,y
        lda     $0450,y
        adc     L96CD,x
        sta     $0450,y
        ldx     $2B
        inc     $0110,x
L96C2:  lda     #$5D
        sta     $04E0,x
L96C7:  dec     $04E0,x
        rts

L96CB:  .byte   $30,$E0
L96CD:  .byte   $00,$FF
L96CF:  sta     $00
        ldy     #$0F
L96D3:  jsr     LF014
        bcs     L96E1
        dec     $01
        beq     L96E3
        dey
        bne     L96D3
        beq     L96E3
L96E1:  clc
        rts

L96E3:  sec
        rts

        .byte   $A9,$0B,$85,$01,$A9,$08,$85,$02
        .byte   $20,$2C,$F0,$BD,$E0,$04,$D0,$1E
        .byte   $A5,$00,$F0,$72,$FE,$E0,$04,$A9
        .byte   $76,$9D,$60,$06,$A9,$03,$9D,$40
        .byte   $06,$BD,$20,$04,$09,$04,$9D,$20
        .byte   $04,$20,$EE,$EF,$D0,$58
        cmp     #$03
        beq     L9752
        lda     $00
        beq     L976B
        lda     $04E0,x
        cmp     #$02
        beq     L9731
        lda     #$00
        sta     $0660,x
        lda     #$02
        sta     $0640,x
        inc     $04E0,x
        bne     L976B
L9731:  lda     #$C0
        sta     $0660,x
        lda     #$FF
        sta     $0640,x
        lda     #$00
        sta     $0600,x
        lda     #$A3
        sta     $0620,x
        inc     $04E0,x
        lda     $0420,x
        and     #$FB
        sta     $0420,x
        bne     L976B
L9752:  lda     #$0C
        lda     $00
        bne     L976B
        lda     #$00
        sta     $04E0,x
        sta     $0620,x
        sta     $0600,x
        lda     $0420,x
        ora     #$04
        sta     $0420,x
L976B:  jsr     LEEBA
        rts

        .byte   $A9,$07,$85,$00,$4C,$52,$96,$BD
        .byte   $E0,$04,$D0,$48,$A9,$0C,$85,$02
        .byte   $BD,$A0,$06,$C9,$02,$90,$05,$A9
        .byte   $00,$9D,$A0,$06
        lda     $06C0,x
        cmp     #$14
        beq     L97D3
        lda     #$0B
        jsr     LF159
        lda     $0430,y
        ora     #$04
        eor     #$40
        sta     $0430,y
        clc
        lda     $04A0,x
        adc     #$08
        sta     $04A0,x
        lda     #$01
        sta     $0600,x
        lda     #$47
        sta     $0620,x
        lda     #$03
        sta     $06E0,x
        lda     #$03
        sta     $06A0,x
        inc     $04E0,x
        bne     L97D3
        lda     #$04
        sta     $02
        lda     $06A0,x
        cmp     #$05
        bcc     L97D3
        lda     #$03
        sta     $06A0,x
L97D3:  lda     $0420,x
        and     #$40
        beq     L97EA
        clc
        lda     $0460,x
        adc     #$0C
        sta     jump_ptr
        lda     $0440,x
        adc     #$00
        jmp     L97F7

L97EA:  sec
        lda     $0460,x
        sbc     #$0C
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
L97F7:  sta     $09
        lda     $04A0,x
        sta     $0A
        lda     #$00
        sta     $0B
        jsr     LCBC3
        ldx     $2B
        lda     $00
        and     #$01
        bne     L981F
        clc
        lda     $0A
        adc     $02
        sta     $0A
        jsr     LCBC3
        ldx     $2B
        lda     $00
        and     #$01
        bne     L9827
L981F:  lda     $0420,x
        eor     #$40
        sta     $0420,x
L9827:  jsr     LEEBA
        rts

        .byte   $20,$BA,$EE,$60,$BD,$A0,$06,$C9
        .byte   $09,$B0,$18,$A9,$01,$85,$01,$A9
        .byte   $0D,$20,$CF,$96
        bcs     L9876
        lda     #$09
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        jsr     L9882
        cmp     #$0A
        bne     L9882
        lda     $0680,x
        bne     L9882
        lda     #$02
        sta     $01
L985B:  lda     #$0D
        jsr     LF159
        bcs     L9876
        ldx     $01
        lda     L9889,x
        sta     $0630,y
        lda     L988C,x
        sta     $0610,y
        ldx     $2B
        dec     $01
        bpl     L985B
L9876:  lda     $06A0,x
        cmp     #$08
        bne     L9882
        lda     #$00
        sta     $06A0,x
L9882:  jsr     LEFEE
        jsr     LEFB3
        rts

L9889:  .byte   $15,$8D,$A2
L988C:  .byte   $04,$02,$01,$A9,$00,$9D,$80,$06
        .byte   $A9,$03,$85
        ora     ($A9,x)
        .byte   $04
        sta     $02
        jsr     LF0CF
        lda     $0110,x
        bne     L98BD
        lda     $00
        beq     L98DF
        lda     #$3E
        sta     $04E0,x
        inc     $06A0,x
        lda     #$00
        sta     $0620,x
        sta     $0600,x
        inc     $0110,x
        bne     L98DF
L98BD:  dec     $04E0,x
        bne     L98DF
        dec     $06A0,x
        dec     $0110,x
        jsr     LEFEE
        lda     #$A2
        sta     $0620,x
        lda     #$01
        sta     $0600,x
        lda     #$E6
        sta     $0620,x
        lda     #$04
        sta     $0640,x
L98DF:  jsr     LEEBA
        rts

        .byte   $BD,$20,$06,$D0,$68,$BD,$E0,$04
        .byte   $F0,$0C,$A0,$02,$DD,$C0,$06,$F0
        .byte   $02,$A0,$05
        jsr     L998D
        lda     $06C0,x
        sta     $04E0,x
        lda     $0440,x
        sta     $0660,x
        jsr     LEFAF
        lda     $06C0,x
        bne     L994F
        lda     #$A0
        sta     $0420,x
        lda     #$0F
        sta     $0400,x
        ldx     #$01
L9919:  stx     $01
        lda     L99FF,x
        jsr     LF010
        bcs     L992D
        lda     #$00
        sta     $0430,y
        lda     #$FF
        sta     $0120,y
L992D:  ldx     $01
        dex
        bpl     L9919
        ldx     $2B
        ldy     $0110,x
        lda     #$00
        sta     $013F,y
        sta     $0141,y
        sta     $013E,y
        sta     $0142,y
        lda     #$0E
        sta     $0620,x
        lda     #$06
        sta     $0600,x
L994F:  rts

        dec     $0600,x
        php
        lda     $0620,x
        cmp     #$05
        bcc     L9968
        ldy     #$02
        plp
        beq     L9964
        jsr     L998D
        rts

L9964:  ldy     #$05
        bne     L9972
L9968:  plp
        bne     L998C
        ldy     $0620,x
        lda     L9A00,y
        tay
L9972:  lda     #$09
        sta     $0600,x
        jsr     L998D
        lda     $0620,x
        cmp     #$06
        bcs     L9984
        jsr     L99A5
L9984:  dec     $0620,x
        bne     L998C
        lsr     $0420,x
L998C:  rts

L998D:  ldx     #$02
L998F:  lda     L99F9,y
        sta     $035F,x
        sta     $037F,x
        sta     $038F,x
        sta     $039F,x
        dey
        dex
        bpl     L998F
        ldx     $2B
        rts

L99A5:  lda     #$04
        sta     $01
        lda     $0620,x
        asl     a
        asl     a
        adc     $0620,x
        sta     $02
        lda     $0660,x
        sta     $03
L99B8:  lda     #$06
        jsr     LF159
        bcs     L99F1
        ldx     $02
        lda     L9A25,x
        sta     $04B0,y
        lda     $03
        sta     $0450,y
        cmp     #$09
        php
        lda     L9A0C,x
        plp
        beq     L99D8
        sec
        sbc     #$20
L99D8:  sta     $0470,y
        sec
        sbc     $1F
        lda     $03
        sbc     $20
        beq     L99E9
        lda     #$00
        sta     $0430,y
L99E9:  ldx     $2B
        inc     $02
        dec     $01
        bpl     L99B8
L99F1:  ldx     $2B
        lda     #$2B
        jsr     bank_switch_enqueue
        rts

L99F9:  jsr     L0F15
        jsr     L0F20
L99FF:  .byte   $10
L9A00:  .byte   $02
        .byte   $17,$14
        ora     ($0E),y
        and     ($14),y
        .byte   $0F,$21,$13,$01,$11
L9A0C:  .byte   $11,$01,$11,$11,$11,$68,$78,$88
        .byte   $88,$A8,$68,$78,$98,$98,$B8,$68
        .byte   $78,$98,$98,$A8,$58,$68,$88,$A8
        .byte   $B8
L9A25:  pla
        sei
        sei
        dey
        tay
        clv
        tay
        dey
        clv
        clv
        tay
        clv
        tya
        clv
        tay
        tya
        clv
        tya
        clv
        tay
        clv
        dey
        tya
        dey
        clv
        clv
        dey
        tay
        tay
        tya
        lda     $04E0,x
        bne     L9A52
        lda     #$01
        sta     $06A0,x
        lda     #$70
        sta     $04E0,x
L9A52:  lda     $06A0,x
        cmp     #$04
        bcc     L9A5E
        lda     #$00
        sta     $0680,x
L9A5E:  dec     $04E0,x
        jsr     LEFAF
        rts

        .byte   $A0,$02,$20,$8D,$99,$A9,$FF,$9D
        .byte   $20,$01,$5E,$20,$04,$60,$A9,$14
        .byte   $9D,$50,$01,$38,$BD,$40,$04,$E9
        .byte   $04,$A4,$2A,$C0,$07,$F0,$06,$38
        .byte   $BD,$40,$04,$E9,$1B
        sta     $00
        tay
        lda     L9B25,y
        sta     $01
        clc
        adc     $04E0,x
        tay
        lda     $00
        cmp     #$03
        bcs     L9AA8
        lda     L9B43,y
        sta     $02
        lda     L9B44,y
        jmp     L9AB0

L9AA8:  lda     L9BBB,y
        sta     $02
        lda     L9BBC,y
L9AB0:  and     #$01
        bne     L9ABD
        lda     $04A0,x
        cmp     $02
        beq     L9AC4
        bne     L9AE7
L9ABD:  lda     $0460,x
        cmp     $02
        bne     L9AE7
L9AC4:  lda     #$00
        sta     $0480,x
        sta     $04C0,x
        iny
        iny
        inc     $04E0,x
        inc     $04E0,x
        lda     $04E0,x
        ldx     $00
        cmp     L9B3C,x
        bne     L9AE7
        ldx     $2B
        lda     #$00
        sta     $04E0,x
        ldy     $01
L9AE7:  ldx     $00
        cpx     #$03
        bcs     L9AF3
        lda     L9B44,y
        jmp     L9AF6

L9AF3:  lda     L9BBC,y
L9AF6:  ldx     $2B
        tay
        lda     L9B2C,y
        sta     $0660,x
        lda     L9B30,y
        sta     $0640,x
        lda     L9B34,y
        sta     $0620,x
        lda     L9B38,y
        sta     $0420,x
        jsr     LEEBA
        bcc     L9B1B
        lda     #$00
        sta     $0150,x
L9B1B:  sec
        lda     $04A0,x
        sbc     #$04
        sta     $0160,x
        rts

L9B25:  .byte   $00,$08,$24,$00,$44,$5C,$8C
L9B2C:  .byte   $1B,$00,$E5,$00
L9B30:  .byte   $FF,$00,$00,$00
L9B34:  .byte   $00,$E5,$00,$E5
L9B38:  .byte   $80,$80,$C0,$C0
L9B3C:  .byte   $08,$1C,$54,$44,$18,$30,$14
L9B43:  .byte   $A0
L9B44:  brk
        plp
        ora     ($40,x)
        .byte   $02,$D8,$03,$A0,$00,$68,$01,$80
        .byte   $02,$98,$03,$60,$02,$B8,$03,$40
        .byte   $02,$88,$01,$60,$00,$28,$01,$40
        .byte   $02,$68,$03,$20,$02,$D8,$03,$A0
        .byte   $00,$28,$01,$90,$02,$C8,$03,$30
        .byte   $02,$A8,$01,$40,$00,$B8,$03,$50
        .byte   $00
        tay
        ora     ($60,x)
        brk
        .byte   $B8,$03,$70,$00
        tay
        ora     ($80,x)
        brk
        .byte   $88,$01,$70,$02,$98,$03,$60,$02
        .byte   $88,$01,$50,$02,$98,$03,$40,$02
        .byte   $88,$01,$30,$02
        sei
        ora     ($80,x)
        brk
        .byte   $38,$01,$70,$02,$68,$03,$60,$02
        .byte   $38,$01,$50,$02,$68,$03,$40,$02
        .byte   $28,$01,$70,$00,$18,$01,$30,$02
        .byte   $68,$03,$20,$02,$D8,$03
L9BBB:  .byte   $A0
L9BBC:  .byte   $00,$B8,$01,$50,$02,$E8,$03,$40
        .byte   $02,$C8,$01,$20,$02,$88,$01,$30
        .byte   $00,$A8,$03,$60,$00,$88,$01,$70
        .byte   $00,$A8,$03,$B0,$00
        sei
        ora     ($50,x)
        .byte   $02,$98,$03,$40,$02,$58,$01,$30
        .byte   $02,$78,$03,$20,$02,$38,$01,$60
        .byte   $00,$48,$03,$50,$02,$68,$03
        bvs     L9BF5
L9BF5:  pha
        ora     ($C0,x)
        brk
        .byte   $C8,$03,$80,$02,$D8,$03,$C0,$00
        .byte   $18,$01,$90,$02,$38,$03,$B0,$00
        .byte   $58,$03,$C0,$00,$C8,$03,$70,$02
        .byte   $88,$01
        jsr     L4802
        ora     ($90,x)
        brk
        .byte   $18,$01,$60,$02,$28,$03,$B0,$00
        .byte   $B8,$03,$C0,$00,$E8,$03,$40,$02
        .byte   $C8,$01,$30,$02,$98,$01,$40,$00
        .byte   $B8,$03,$50,$00,$D8,$03,$B0,$00
        iny
        ora     ($60,x)
        .byte   $02,$58,$01,$30,$02,$28,$01,$40
        .byte   $00,$38,$03,$80,$00,$38,$01,$60
        .byte   $02,$48,$03,$A0,$00,$88,$03,$C0
        .byte   $00,$D8,$03,$50,$02,$58,$01
        lda     #$18
        sta     $0150,x
        lda     $0420,x
        and     #$04
        bne     L9C74
        lda     $04E0,x
        cmp     #$06
        bcs     L9C74
        jsr     LEFB3
        jmp     L9C7F

L9C74:  lda     $0420,x
        ora     #$04
        sta     $0420,x
        jsr     LEEBA
L9C7F:  bcc     L9C86
        lda     #$00
        sta     $0150,x
L9C86:  sec
        lda     $04A0,x
        sbc     #$08
        sta     $0160,x
        rts

        .byte   $38,$BD,$40,$04,$E9,$03,$A8,$B9
        .byte   $DE,$9C
        sta     $02
        lda     L9CEE,y
        sta     $01
L9CA1:  lda     #$15
        jsr     LF159
        ldx     $01
        lda     L9CFE,x
        sta     $0430,y
        and     #$40
        bne     L9CB6
        lda     #$FC
        bne     L9CB8
L9CB6:  lda     #$04
L9CB8:  sta     $0470,y
        lda     L9D32,x
        sta     $04B0,y
        lda     L9D66,x
        sta     $0120,y
        lda     L9D9A,x
        sta     $04F0,y
        ldx     $2B
        inc     $01
        dec     $02
        bne     L9CA1
        lsr     $0420,x
        lda     #$00
        sta     a:$F0,x
        rts

        .byte   $02,$03,$04,$00,$00,$00,$00,$00
        .byte   $00,$0C,$0A,$05,$05,$02,$05,$04
L9CEE:  .byte   $00,$02,$05,$09,$09,$09,$09,$09
        .byte   $09,$09,$15,$1F,$24,$29,$2B,$30
L9CFE:  .byte   $E1,$A1
        sbc     ($A1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($E1,x)
        lda     ($A1,x)
        lda     ($A1,x)
        sbc     ($E1,x)
        lda     ($A1,x)
        lda     ($A1,x)
        lda     ($A1,x)
        lda     ($E1,x)
        lda     ($A1,x)
        sbc     ($A1,x)
L9D32:  .byte   $47
        .byte   $77,$57,$87,$C7,$47,$67,$87,$C7
        .byte   $17,$17,$37,$37,$57,$57,$77,$77
        .byte   $A7,$A7,$B7,$B7,$37,$37,$57,$57
        .byte   $77,$77,$97,$97,$B7,$B7,$17,$17
        .byte   $27,$27,$A7,$17,$37,$67,$87,$A7
        .byte   $67,$B7,$27,$47,$67,$77,$A7,$17
        .byte   $27,$67,$A7
L9D66:  .byte   $FF,$00,$FF,$00,$00,$FF,$A0,$60
        .byte   $60,$80,$80,$80,$80,$80,$80,$80
        .byte   $80,$80,$80,$80,$80,$80,$80,$80
        .byte   $80,$60
        ldy     #$80
        .byte   $80,$80,$80,$80,$80,$80,$80,$00
        .byte   $00,$00,$FF,$FF,$00,$00,$00,$00
        .byte   $00,$80,$00,$70,$00,$00,$FF,$20
L9D9A:  .byte   $01,$1F
        ora     ($1F,x)
        rol     $1F01,x
        rol     $015D,x
        ora     ($1F,x)
        .byte   $1F,$3E,$3E,$5D,$5D,$7C,$7C,$9D
        .byte   $9D,$01,$01,$1F,$1F,$3E,$3E,$5D
        .byte   $5D,$7C,$7C,$01,$01,$1F,$1F,$3E
        .byte   $01,$1F,$3E,$5D,$7C,$01,$1F,$01
        .byte   $1F,$3E,$5D,$7C,$01,$1F,$3E,$5D
        .byte   $BD,$E0,$04,$F0,$13,$DE,$E0,$04
        .byte   $F0,$01,$60
        lda     $0420,x
        and     #$DF
        sta     $0420,x
        lda     #$27
        jsr     bank_switch_enqueue
        lda     $0420,x
        and     #$20
        bne     L9E4B
        lda     $0420,x
        and     #$40
        bne     L9DFE
        lda     $0460,x
        cmp     $0110,x
        bcs     L9E16
        bcc     L9E06
L9DFE:  lda     $0460,x
        cmp     $0110,x
        bcc     L9E16
L9E06:  lda     $0110,x
        sta     $0460,x
        lda     $0420,x
        ora     #$20
        sta     $0420,x
        bne     L9E4B
L9E16:  lda     $0440,x
        sta     $09
        lda     $0460,x
        sta     jump_ptr
        lda     $04A0,x
        and     #$F0
        sta     $0A
        jsr     LC8EF
        ldy     #$74
        lda     $03BC,x
        and     #$01
        beq     L9E35
        ldy     #$76
L9E35:  tya
        sta     $03C2,x
        inc     $51
        ldx     $2B
        jsr     LEEBA
        bcc     L9E4B
        lda     $0420,x
        asl     a
        ora     #$20
        sta     $0420,x
L9E4B:  lda     $4B
        bne     L9E80
        sec
        lda     $04A0,x
        sbc     $04A0
        bcs     L9E5C
        eor     #$FF
        adc     #$01
L9E5C:  cmp     #$10
        bcs     L9E80
        lda     $0420,x
        and     #$40
        bne     L9E71
        lda     $0460,x
        cmp     $0460
        bcs     L9E80
        bcc     L9E79
L9E71:  lda     $0460,x
        cmp     $0460
        bcc     L9E80
L9E79:  lda     #$00
        sta     $2C
        jmp     LC10B

L9E80:  rts

        .byte   $BD,$E0,$04,$D0,$16,$A5,$4A,$49
        .byte   $01,$85,$4A,$29,$01,$A8,$B9,$20
        .byte   $9F,$9D,$E0,$04,$A9,$8B,$9D,$20
        .byte   $04,$D0,$13
        cmp     #$01
        beq     L9EB3
        cmp     #$FF
        beq     L9EEF
        dec     $04E0,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        jsr     LEFB3
        rts

L9EB3:  lda     $0420,x
        and     #$F7
        sta     $0420,x
        lda     $06A0,x
        cmp     #$08
        bne     L9ED2
        lda     #$05
        sta     $06A0,x
        lda     #$00
        sta     $09
        lda     #$83
        sta     jump_ptr
        jsr     LF197
L9ED2:  jsr     LEEBA
        lda     $01
        beq     L9EEE
        lda     #$00
        sta     $0600,x
        sta     $0620,x
        sta     $0660,x
        lda     #$02
        sta     $0640,x
        lda     #$FF
        sta     $04E0,x
L9EEE:  rts

L9EEF:  lda     $06A0,x
        cmp     #$08
        bne     L9EFB
        lda     #$05
        sta     $06A0,x
L9EFB:  lda     #$04
        sta     $01
        lda     #$08
        sta     $02
        jsr     LF02C
        lda     $00
        beq     L9F1C
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        lda     #$8B
        sta     $0420,x
        lda     #$3E
        sta     $04E0,x
L9F1C:  jsr     LEEBA
        rts

        .byte   $3E,$9C,$BD,$40,$06,$85,$04,$A9
        .byte   $0C,$85,$01,$A9,$10,$85,$02,$20
        .byte   $CF,$F0,$BD,$10,$01,$D0,$1F,$BD
        .byte   $E0,$04,$D0,$79,$A9,$C0,$9D,$20
        .byte   $06,$9D,$60,$06,$A9,$04,$9D,$40
        .byte   $06,$85,$04,$20,$EE,$EF,$FE,$10
        .byte   $01,$A9,$01,$9D,$A0,$06
        lda     $0110,x
        cmp     #$01
        bne     L9F79
        lda     $04
        bpl     L9FB5
        lda     $00
        beq     L9FB5
        lda     #$00
        sta     $0620,x
        inc     $0110,x
        lda     #$3E
        sta     $04E0,x
        lda     #$03
        sta     $06A0,x
        bne     L9FB5
L9F79:  lda     $04E0,x
        bne     L9FB5
        jsr     LEFEE
        lda     #$18
        jsr     LF159
        bcs     L9FA1
        lda     $2B
        pha
        tya
        clc
        adc     #$10
        tax
        stx     $2B
        lda     #$02
        sta     $09
        lda     #$0C
        sta     jump_ptr
        jsr     LF197
        pla
        sta     $2B
        tax
L9FA1:  lda     #$3E
        sta     $04E0,x
        inc     $0110,x
        lda     $0110,x
        cmp     #$05
        bne     L9FB5
        lda     #$00
        sta     $0110,x
L9FB5:  dec     $04E0,x
        ldy     $0110,x
        lda     $06A0,x
        cmp     L9FCC,y
        bne     L9FC8
        lda     #$00
        sta     $0680,x
L9FC8:  jsr     LEEBA
        rts

L9FCC:  .byte   $00,$02,$00,$00,$00,$A0,$02,$BD
        .byte   $C0,$06,$D0,$03,$4C,$6B,$A0
        cmp     $0660,x
        beq     L9FE2
        ldy     #$05
L9FE2:  sta     $0660,x
        ldx     #$0F
L9FE7:  lda     LA108,y
        sta     $0356,x
        dey
        dex
        cpx     #$0C
        bne     L9FE7
        ldx     $2B
        lda     $0620,x
        bne     LA02B
        lda     #$01
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        lda     $04E0,x
        bne     LA028
        lda     #$1B
        jsr     LF159
        bcs     LA019
        clc
        lda     $04B0,y
        adc     #$0C
        sta     $04B0,y
LA019:  lda     #$02
        sta     $04E0,x
        dec     $0600,x
        bne     LA050
        inc     $0620,x
        bne     LA050
LA028:  dec     $04E0,x
LA02B:  lda     $06A0,x
        bne     LA050
        lda     #$00
        sta     $0620,x
        lda     #$03
        sta     $0600,x
        lda     $4A
        and     #$03
        beq     LA050
        asl     $0600,x
        and     #$01
        bne     LA050
        clc
        lda     $0600,x
        adc     #$03
        sta     $0600,x
LA050:  jsr     LEFB3
        bcc     LA06A
        lda     #$80
        sta     $0420,x
        lda     #$19
        sta     $0400,x
        lda     #$00
        sta     $04E0,x
        sta     $0620,x
        sta     $0100,x
LA06A:  rts

        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        lda     $0620,x
        beq     LA07B
        jmp     LA104

LA07B:  lda     $04E0,x
        and     #$03
        sta     $00
        asl     a
        asl     a
        adc     $00
        sta     $01
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$05
        sta     $02
LA091:  lda     #$06
        jsr     LF159
        bcs     LA0B4
        ldx     $01
        clc
        lda     $0470,y
        adc     LA10E,y
        sta     $0470,y
        clc
        lda     $04B0,y
        adc     LA122,y
        sta     $04B0,y
        .byte   $E6
LA0AF:  ora     ($C6,x)
        .byte   $02
        bne     LA091
LA0B4:  ldx     $2B
        inc     $04E0,x
        lda     $04E0,x
        cmp     #$08
        bne     LA0FF
        lda     #$1A
        jsr     LF010
        bcs     LA0D1
        lda     #$00
        sta     $0430,y
        lda     #$FF
        sta     $0100,y
LA0D1:  lda     #$1C
        jsr     LF010
        bcs     LA0DD
        lda     #$FF
        sta     $04F0,y
LA0DD:  lda     #$2E
        jsr     LF010
        bcs     LA0F9
        lda     #$00
        sta     $0430,y
        lda     #$FF
        sta     $0130,y
        lda     $0120,y
        tay
        lda     #$00
        sta     $0140,y
        beq     LA0DD
LA0F9:  sta     a:$F0,x
        asl     $0420,x
LA0FF:  lda     #$08
        sta     $0620,x
LA104:  dec     $0620,x
        rts

LA108:  php
        bit     $0812
        .byte   $20
        .byte   $20
LA10E:  .byte   $FC
        .byte   $FC,$14,$1C,$2C,$F4,$04,$0C,$14
        .byte   $24,$F4,$04,$14,$2C,$2C,$04,$0C
LA11F:  .byte   $14,$24,$24
LA122:  .byte   $F8
        bpl     LA12D
        beq     LA11F
        brk
        .byte   $E8,$10,$F8,$08,$08
LA12D:  sed
        brk
        .byte   $E8,$08,$00,$E8,$F8,$F0,$08,$BD
        .byte   $E0,$04,$D0,$0A,$A9,$6E,$9D
        cpx     #$04
        lda     #$01
        sta     $06A0,x
        lda     $06A0,x
        bne     LA14D
        sta     $0680,x
LA14D:  dec     $04E0,x
        jsr     LEFB3
        rts

        .byte   $18,$BD,$60,$06,$69,$40,$9D,$60
        .byte   $06,$BD,$40,$06,$69,$00,$9D,$40
        .byte   $06,$20,$BA,$EE,$60,$38,$BD,$40
        .byte   $04,$E9,$06,$A8,$B9,$69,$A2,$DD
        .byte   $A0,$04,$F0,$14,$BD,$20,$04,$29
        .byte   $DF,$9D,$20,$04,$A9,$00,$9D,$A0
        .byte   $06,$9D,$80,$06,$20,$BA,$EE,$60
        lda     #$00
        sta     $0640,x
        jsr     LEFB3
        lda     $06A0,x
        pha
        tay
        clc
        lda     $04A0,x
        adc     LA26C,y
        and     #$E0
        sta     $0A
        clc
        lda     $0460,x
        adc     LA270,y
        and     #$E0
        sta     jump_ptr
        lda     $0440,x
        sta     $09
        jsr     LC8EF
        jsr     LC91B
        ldy     $1B
        lda     $03B6
        sta     $0300,y
        lda     $03BC
        sta     $0304,y
        lda     $03C2
        sta     $0308,y
        lda     $03C8
        sta     $030C,y
        lda     #$FF
        sta     $0350,y
        tya
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        pla
        sta     $00
        ldx     $2B
        lda     $04E0,x
        cmp     #$FF
        bne     LA1F2
        clc
        lda     $00
        adc     #$04
        sta     $00
LA1F2:  lda     $00
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        lda     #$10
        sta     $00
LA1FD:  lda     LA274,x
        sta     $0310,y
        inx
        iny
        dec     $00
        bne     LA1FD
        inc     $1B
        ldx     $2B
        lda     $06A0,x
        cmp     #$03
        bne     LA268
        lda     $04E0,x
        bne     LA268
        lda     #$19
        jsr     LF159
        lda     #$08
        sta     $04F0,y
        lda     #$03
        sta     $0610,y
        lda     #$14
        sta     $04C0,x
        lda     $4A
        and     #$03
        beq     LA249
        pha
        lda     $0610,y
        asl     a
        sta     $0610,y
        pla
        and     #$01
        bne     LA249
        clc
        lda     $0610,y
        adc     #$03
        sta     $0610,y
LA249:  lda     #$1A
        jsr     LF159
        clc
        lda     $0470,y
        adc     #$2F
        sta     $0470,y
        sec
        lda     $04B0,y
        sbc     #$0C
        sta     $04B0,y
        inc     $04E0,x
        lda     #$A0
        sta     $0420,x
LA268:  rts

        .byte   $88,$68,$48
LA26C:  .byte   $F0,$00
        beq     LA270
LA270:  brk
        .byte   $00,$20,$20
LA274:  dey
        txa
        sty     $86
        .byte   $89,$8B,$85,$87,$84,$86,$8C,$8E
        .byte   $85,$87,$8D,$8F,$84,$86,$74,$76
        .byte   $85,$87,$75,$77,$90,$92,$94,$96
        .byte   $91,$93,$95,$97,$84,$86,$84,$86
        .byte   $85,$87,$85,$87,$6C,$6E,$70,$72
        .byte   $6D,$6F,$71,$73,$78,$7A,$7C,$7E
        adc     $7D7B,y
        .byte   $7F,$98,$9A,$9C,$9E,$99,$9B,$9D
        .byte   $9F,$88,$8A,$84,$86,$89,$8B,$85
        .byte   $87,$84,$86,$84,$86
        sta     $87
        sta     $87
        sty     $86
        sty     $86
        sta     $87
        sta     $87
        sty     $86
        sty     $86
        sta     $87
        sta     $87
        sty     $86
        sty     $86
        sta     $87
        sta     $87
        sty     $86
        sty     $86
        sta     $87
        sta     $87
        sty     $86
        sty     $86
        sta     $87
        sta     $87
        sty     $86
        sty     $86
        sta     $87
        sta     $87
        jsr     LEFEE
        lda     $0420,x
        and     #$20
        beq     LA31D
        lda     $00
        cmp     #$50
        bcc     LA308
        jsr     LEFB3
        rts

LA308:  lda     #$00
        sta     $06A0,x
        sta     $0680,x
        lda     $0420,x
        and     #$DF
        sta     $0420,x
        lda     #$04
        sta     $0640,x
LA31D:  lda     $06A0,x
        bne     LA344
        lda     #$00
        sta     $0680,x
        lda     #$07
        sta     $01
        lda     #$01
        sta     $02
        jsr     LF02C
        lda     $00
        bne     LA339
        jmp     LA3E9

LA339:  lda     #$00
        sta     $0640,x
        inc     $06A0,x
        jmp     LA3E9

LA344:  lda     $06A0,x
        cmp     #$02
        bne     LA357
        clc
        lda     $04A0,x
        adc     #$05
        sta     $04A0,x
        inc     $06A0,x
LA357:  lda     $06A0,x
        cmp     #$08
        bcs     LA39E
        lda     $00
        cmp     #$20
        bcc     LA37C
        inc     $04E0,x
        lda     $04E0,x
        cmp     #$7D
        beq     LA37C
        lda     $06A0,x
        cmp     #$07
        bne     LA3E9
        lda     #$03
        sta     $06A0,x
        bne     LA3E9
LA37C:  sec
        lda     $04A0,x
        sbc     #$20
        sta     $04A0,x
        lda     $0420,x
        ora     #$04
        sta     $0420,x
        lda     #$02
        sta     $04E0,x
        lda     #$08
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        bne     LA3E9
LA39E:  lda     #$08
        sta     $01
        lda     #$10
        sta     $02
        jsr     LF02C
        lda     #$00
        sta     $0680,x
        lda     $06A0,x
        cmp     #$09
        beq     LA3D3
        dec     $04E0,x
        bne     LA3E9
        lda     #$03
        sta     $0640,x
        lda     #$76
        sta     $0660,x
        lda     #$01
        sta     $0600,x
        lda     #$7B
        sta     $0620,x
        inc     $06A0,x
        bne     LA3E9
LA3D3:  lda     $00
        beq     LA3E9
        lda     #$08
        sta     $06A0,x
        lda     #$32
        sta     $04E0,x
        lda     #$00
        sta     $0620,x
        sta     $0600,x
LA3E9:  jsr     LEEBA
        rts

        .byte   $BD,$20,$06,$D0,$08,$A9,$1E,$20
        .byte   $B5,$95,$90,$01,$60
        lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04E0,x
        bne     LA442
        lda     #$01
        sta     $01
        lda     #$1F
        jsr     L96CF
        bcs     LA43D
        lda     #$1F
        jsr     LF159
        bcs     LA43D
        clc
        lda     $0470,y
        adc     #$78
        sta     $0470,y
        lda     $0450,y
        adc     #$00
        sta     $0450,y
        sec
        lda     $04A0
        sbc     #$2C
        bcs     LA438
        lda     #$08
LA438:  sta     $04B0,y
        ldx     $2B
LA43D:  lda     #$1F
        sta     $04E0,x
LA442:  dec     $04E0,x
        rts

        .byte   $A9,$08,$85,$01,$A9,$14,$85,$02
        .byte   $20,$2C,$F0,$A5,$00,$F0,$1B,$BD
        .byte   $E0,$04,$C9,$13,$D0,$0F,$A9,$04
        .byte   $9D,$40,$06,$A9,$78,$9D,$60,$06
        .byte   $A9,$00,$9D,$E0,$04
        inc     $04E0,x
        bne     LA47A
        lda     #$02
        sta     $06A0,x
        lda     #$03
        sta     $0680,x
LA47A:  jsr     LEEBA
        rts

        .byte   $A9,$1E,$85,$00,$4C,$52,$96,$BD
        .byte   $E0,$04,$D0,$15,$A9,$03,$85,$01
        .byte   $A9,$22,$20,$CF,$96,$B0,$05,$A9
        .byte   $22,$20,$59,$F1
        lda     #$DA
        sta     $04E0,x
        dec     $04E0,x
        jsr     LEFB3
        rts

        lda     $04E0,x
        bne     LA4BB
        lda     #$00
        sta     $09
        lda     #$42
        sta     jump_ptr
        jsr     LF197
        lda     #$10
        sta     $04E0,x
LA4BB:  dec     $04E0,x
        jsr     LEEBA
        rts

        .byte   $BD,$20,$06,$D0,$25,$A9,$6E,$9D
        .byte   $E0,$04,$FE,$20,$06,$A9,$00,$9D
        .byte   $20,$04,$A9,$01,$85,$01,$A9,$23
        .byte   $20,$CF,$96,$A9,$83,$9D,$20,$04
        .byte   $B0,$5D,$A9,$26,$20,$59,$F1,$4C
        .byte   $41,$A5
        lda     $04E0,x
        beq     LA4FF
        lda     $06A0,x
        cmp     #$02
        bne     LA541
        lda     #$00
        sta     $06A0,x
        beq     LA541
LA4FF:  lda     $06A0,x
        cmp     #$04
        bne     LA544
        lda     $0680,x
        bne     LA544
        jsr     LEFEE
        lda     #$24
        jsr     LF159
        bcs     LA536
        sec
        lda     $4A
        and     #$1F
        sta     $4A
        sec
        lda     $00
        sbc     $4A
        sta     $00
        lda     #$00
        asl     $00
        rol     a
        asl     $00
        rol     a
        asl     $00
        rol     a
        sta     $0610,y
        lda     $00
        sta     $0630,y
LA536:  lda     $4A
        and     #$03
        tay
        lda     LA556,y
        sta     $04E0,x
LA541:  dec     $04E0,x
LA544:  jsr     LEFB3
        bcc     LA555
        lda     #$23
        jsr     LF010
        bcc     LA555
        lda     #$28
        jsr     LF159
LA555:  rts

LA556:  .byte   $12,$1F,$1F,$3D,$AD,$57,$03,$C9
        .byte   $0F,$F0,$37,$A9,$23,$20,$10,$F0
        .byte   $90,$30,$A9,$26,$20,$10,$F0,$90
        .byte   $29,$BD,$E0,$04,$D0,$33,$BD,$20
        .byte   $06
LA577:  asl     a
        asl     a
        sta     $00
        asl     a
        clc
        adc     $00
        tax
        ldy     #$00
LA582:  lda     LA5D6,x
        sta     $0356,y
        inx
        iny
        cpy     #$0C
        bne     LA582
        ldx     $2B
        inc     $0620,x
        lda     $0620,x
        cmp     #$04
        bne     LA5A2
        lsr     $0420,x
        lda     #$FF
        sta     a:$F0,x
LA5A2:  lda     #$08
        sta     $04E0,x
LA5A7:  dec     $04E0,x
        rts

        lda     $04E0,x
        bne     LA5A7
        clc
        lda     $0620,x
        adc     #$03
        bne     LA577
        lda     $04E0,x
        bne     LA5A7
        lda     $0620,x
        eor     #$03
        jmp     LA577

        .byte   $BD,$E0,$04,$D0,$DD,$38,$BD,$20
        .byte   $06,$49,$03,$18,$69,$03,$4C,$77
        .byte   $A5
LA5D6:  .byte   $0F,$2C,$10,$1C,$0F,$37,$27,$07
        .byte   $0F,$28,$16,$07,$0F,$1C,$00,$0C
        .byte   $0F,$37,$27,$08,$0F,$17,$06,$08
        .byte   $0F,$0C,$0C,$0F,$0F,$37,$27,$08
        .byte   $0F,$07,$07,$08,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$16,$07,$08,$0F,$37,$27,$08
        .byte   $0F,$07,$07,$08,$0F,$26,$16,$06
        .byte   $0F,$37,$27,$08,$0F,$17,$06,$08
        .byte   $0F,$36,$26,$16,$0F,$37,$27,$07
        .byte   $0F,$27,$16,$07,$BD,$10,$01,$D0
        .byte   $28,$FE,$E0,$04
        lda     $04E0,x
        cmp     #$3E
        bne     LA653
        lda     #$2A
        jsr     LF159
        bcs     LA653
        lda     #$08
        sta     $04B0,y
        lda     $2B
        sta     $0120,y
        tya
        sta     $0110,x
        lda     #$00
        sta     $04E0,x
LA653:  jsr     LEFB3
        rts

        ldy     $0110,x
        cpy     #$FF
        beq     LA6A3
        lda     $04E0,x
        cmp     #$04
        bcs     LA689
        sec
        lda     $04A0,x
        sbc     $04B0,y
        cmp     #$20
        bcs     LA653
        lda     #$D4
        sta     $0670,y
        lda     #$02
        sta     $0650,y
        inc     $04E0,x
        lda     $04E0,x
        cmp     #$04
        bne     LA653
        lda     #$87
        sta     $0420,x
LA689:  sec
        lda     $04A0,x
        sbc     #$20
        sta     $04B0,y
        lda     $0460,x
        sta     $0470,y
        lda     $0440,x
        sta     $0450,y
        lda     #$00
        sta     $0650,y
LA6A3:  lda     #$0F
        sta     $01
        lda     #$0E
        sta     $02
        jsr     LF0CF
        lda     $04E0,x
        cmp     #$04
        bne     LA6C9
        lda     $00
        beq     LA6C9
        jsr     LEFEE
        lda     #$47
        sta     $0620,x
        lda     #$01
        sta     $0600,x
        inc     $04E0,x
LA6C9:  lda     $03
        beq     LA6D5
        lda     $0420,x
        eor     #$40
        sta     $0420,x
LA6D5:  jsr     LEEBA
        bcc     LA6F0
        ldy     $0110,x
        cpy     #$FF
        beq     LA6F0
        lda     #$FF
        sta     $0120,y
        lda     #$D4
        sta     $0670,y
        lda     #$02
        sta     $0650,y
LA6F0:  rts

        .byte   $20,$BA,$EE,$90,$16,$BC,$10,$01
        .byte   $C0,$FF,$F0,$0F,$A9,$00,$99,$00
        .byte   $06,$A9,$A3,$99,$20,$06,$A9,$FF
        .byte   $99,$10,$01,$60,$BD,$E0,$04,$D0
        .byte   $15,$A9,$02,$85,$01,$A9,$2C,$20
        .byte   $CF,$96,$B0,$05,$A9,$2C,$20,$59
        .byte   $F1
        lda     #$7D
        sta     $04E0,x
        dec     $04E0,x
        jsr     LEFB3
        rts

        .byte   $BD,$10,$01,$D0,$03,$FE,$10,$01
        lda     $0110,x
        cmp     #$02
        bcs     LA779
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        lda     #$08
        sta     $01
        lda     #$14
        sta     $02
        lda     $0640,x
        php
        jsr     LF0CF
        plp
        bpl     LA7CF
        lda     $00
        beq     LA7CF
        lda     #$39
        jsr     bank_switch_enqueue
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        sta     $0600,x
        sta     $0620,x
        lda     $0420,x
        and     #$FB
        sta     $0420,x
        inc     $0110,x
LA779:  lda     $0110,x
        cmp     #$02
        bne     LA794
        lda     $06A0,x
        cmp     #$09
        bne     LA7CF
        lda     #$E5
        sta     $0660,x
        lda     #$47
        sta     $04E0,x
        inc     $0110,x
LA794:  lda     $06A0,x
        cmp     #$0B
        bne     LA7A0
        lda     #$09
        sta     $06A0,x
LA7A0:  dec     $04E0,x
        bne     LA7CF
        lda     #$87
        sta     $0420,x
        jsr     LEFEE
        lda     #$00
        asl     $00
        rol     a
        asl     $00
        rol     a
        asl     $00
        rol     a
        sta     $0600,x
        lda     $00
        sta     $0620,x
        lda     #$03
        sta     $0640,x
        lda     #$76
        sta     $0660,x
        lda     #$01
        sta     $0110,x
LA7CF:  jsr     LEEBA
        rts

        .byte   $A9,$08,$D0,$02,$A9,$01
        sta     $04E0,x
        lda     $0460,x
        and     $0600,x
        sta     $0640,x
        lda     $04A0,x
        and     $0620,x
        sta     $0660,x
        jsr     LEFAF
        rts

        .byte   $BD,$10,$01,$D0,$1F,$20,$EE,$EF
        .byte   $A5,$00,$C9,$28,$B0,$12
        lda     #$87
        sta     $0420,x
        lda     #$FF
        sta     $0640,x
        lda     #$C0
        sta     $0660,x
        inc     $0110,x
        jsr     LEFB3
        rts

        lda     #$08
        sta     $01
        sta     $02
        jsr     LF02C
        lda     $0110,x
        cmp     #$02
        bcs     LA84C
        lda     $00
        beq     LA873
        lda     #$21
        jsr     bank_switch_enqueue
        lda     #$2B
        sta     $04E0,x
        inc     $0110,x
        lda     #$52
        jsr     LF159
        sec
        lda     $04B0,y
        sbc     #$28
        sta     $04B0,y
        lda     #$2B
        sta     $04F0,y
        bne     LA873
LA84C:  lda     $04E0,x
        beq     LA867
        dec     $04E0,x
        bne     LA873
        lda     #$00
        sta     $0640,x
        lda     #$62
        sta     $0660,x
        lda     #$83
        sta     $0420,x
        bne     LA873
LA867:  lda     $00
        beq     LA873
        lda     #$00
        sta     $0660,x
        sta     $0110,x
LA873:  jsr     LEEBA
        rts

LA877:  lda     #$07
        sta     $01
        lda     #$08
        sta     $02
        jsr     LF0CF
        lda     $06A0,x
        cmp     #$0F
        bne     LA88E
        lda     #$0E
        sta     $06A0,x
LA88E:  lda     $04E0,x
        beq     LA8C1
        dec     $04E0,x
        bne     LA8C1
        lda     #$02
        sta     $01
LA89C:  lda     #$33
        jsr     LF159
        bcs     LA8BF
        lda     #$E0
        sta     $04B0,y
        lda     #$A8
        sta     $0430,y
        ldx     $01
        lda     LA9C0,x
        sta     $04F0,y
        ldx     $2B
        txa
        sta     $0120,y
        dec     $01
        bpl     LA89C
LA8BF:  ldx     $2B
LA8C1:  lda     $0110,x
        cmp     #$04
        bne     LA8E6
        sec
        lda     $04A0,x
        sbc     #$20
        sta     $04A0,x
        lda     #$87
        sta     $0420,x
        lda     #$41
        sta     $0620,x
        lda     #$00
        sta     $0680,x
        sta     $06A0,x
        sta     $0110,x
LA8E6:  jsr     LEEBA
        rts

        .byte   $BD,$10,$01,$D0,$0C,$A9,$32,$20
        .byte   $59,$F1,$8A,$99,$F0,$04,$FE,$10
        .byte   $01
        lda     $0420,x
        and     #$08
        beq     LA905
        jmp     LA877

LA905:  lda     #$07
        sta     $01
        lda     #$28
        sta     $02
        sec
        lda     $0460,x
        sbc     #$07
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
        sta     $09
        clc
        lda     #$00
        sta     $0B
        lda     $04A0,x
        adc     #$20
        sta     $0A
        jsr     LCBC3
        ldx     $2B
        ldy     $00
        beq     LA946
        lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     $0460,x
        sta     $0460,x
LA93E:  lda     $0440,x
        adc     #$00
        sta     $0440,x
LA946:  jsr     LF02C
        lda     $06A0,x
        cmp     #$0C
        bne     LA955
        lda     #$00
        sta     $06A0,x
LA955:  jsr     LEEBA
        bcs     LA9B6
        lda     $0100,x
        beq     LA9B6
        lda     #$0D
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        sta     $0620,x
        sta     $0600,x
        lda     #$7E
        sta     $04E0,x
        jsr     LEFEE
        lda     #$02
        sta     $01
LA97B:  lda     #$33
        jsr     LF159
        bcs     LA9AF
        ldx     $01
        clc
        lda     $04B0,y
        adc     LA9B7,x
        sta     $04B0,y
        lda     LA9BA,x
        sta     $0610,y
        lda     LA9BD,x
        sta     $0630,y
        lda     #$04
        sta     $0650,y
        lda     #$00
        sta     $0670,y
        lda     #$FF
        sta     $0120,y
LA9A9:  ldx     $2B
        dec     $01
        bpl     LA97B
LA9AF:  ldx     $2B
        lda     #$8F
        sta     $0420,x
LA9B6:  rts

LA9B7:  .byte   $F0,$10,$20
LA9BA:  .byte   $03,$02
        .byte   $01
LA9BD:  brk
        rti

        .byte   $00
LA9C0:  ora     ($06,x)
        .byte   $0B,$BC
        cpx     #$04
        lda     $0420,y
        bpl     LA9CF
        and     #$08
        beq     LA9D3
LA9CF:  lsr     $0420,x
        rts

LA9D3:  lda     $0460,y
        sta     $0460,x
        lda     $0440,y
        sta     $0440,x
        clc
        lda     $04A0,y
        adc     #$08
        sta     $04A0,x
        jsr     LEFB3
        rts

        .byte   $BC,$10,$01
        bpl     LAA21
        lda     #$07
        sta     $01
        lda     #$08
        sta     $02
        jsr     LF0CF
        lda     $00
        beq     LAA4A
        lda     $04E0,x
        beq     LAA0C
        lda     #$00
        sta     $4E
        jmp     LEEDA

LAA0C:  lda     #$00
        sta     $0620,x
        sta     $0600,x
        sta     $0660,x
        lda     #$02
        sta     $0640,x
        inc     $04E0,x
        bne     LAA4A
LAA21:  lda     $04E0,x
        beq     LAA35
        dec     $04E0,x
        bne     LAA4A
        lda     #$8B
        sta     $0420,x
        lda     #$04
        sta     $0640,x
LAA35:  lda     $04A0,x
        cmp     $04A0,y
        bcs     LAA4A
        clc
        lda     $0110,y
        adc     #$01
        sta     $0110,y
        lsr     $0420,x
        rts

LAA4A:  jsr     LEEBA
        rts

        .byte   $A5,$2A,$C9,$0A,$D0,$03,$4C,$44
        .byte   $AB
        ldy     #$08
        lda     $06A0,x
        cmp     #$03
        bcc     LAA62
        ldy     #$10
LAA62:  sty     $02
        lda     #$07
        sta     $01
        jsr     LF0CF
        lda     $0110,x
        bne     LAAA1
        jsr     LEFEE
        lda     $00
        cmp     #$40
        bcs     LAA96
        lda     $04E0,x
        bne     LAA93
        inc     $06A0,x
        inc     $0110,x
        lda     $0420,x
        and     #$F7
        sta     $0420,x
        lda     #$3E
        sta     $04E0,x
        bne     LAA9E
LAA93:  dec     $04E0,x
LAA96:  lda     #$00
        sta     $0680,x
        sta     $06A0,x
LAA9E:  jmp     LAB30

LAAA1:  cmp     #$02
        bcs     LAB01
        lda     $06A0,x
        cmp     #$02
        bne     LAAEA
        lda     #$25
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $01
LAAB5:  lda     #$35
        jsr     LF159
        bcs     LAADC
        ldx     $01
        lda     LAB38,x
        sta     $0670,y
        lda     LAB3B,x
        sta     $0650,y
        lda     LAB3E,x
        sta     $0630,y
        lda     LAB41,x
        sta     $0610,y
        ldx     $2B
        dec     $01
        bpl     LAAB5
LAADC:  lda     #$03
        sta     $06A0,x
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $04A0,x
LAAEA:  dec     $04E0,x
        bne     LAB24
        jsr     LEFEE
        lda     #$02
        sta     $0600,x
        lda     #$14
        sta     $04E0,x
        inc     $0110,x
        bne     LAB24
LAB01:  dec     $04E0,x
        bne     LAB24
        lda     #$00
        sta     $0600,x
        sta     $06A0,x
        sta     $0110,x
        lda     $4A
        and     #$03
        tay
        lda     LAB34,y
        sta     $04E0,x
        lda     $0420,x
        ora     #$08
        sta     $0420,x
LAB24:  lda     $06A0,x
        cmp     #$05
        bne     LAB30
        lda     #$03
        sta     $06A0,x
LAB30:  jsr     LEEBA
        rts

LAB34:  .byte   $1F,$3E,$9B,$1F
LAB38:  .byte   $25,$00,$DB
LAB3B:  .byte   $01,$00,$FE
LAB3E:  .byte   $A3,$00,$A3
LAB41:  .byte   $01,$02,$01
        lda     $04E0,x
        bne     LAB58
        lda     $04A0,x
        cmp     #$80
        bcc     LAB79
        inc     $04E0,x
        lda     #$03
        sta     $0640,x
LAB58:  lda     #$08
        sta     $01
        lda     #$10
        sta     $02
        jsr     LF02C
        lda     $00
        beq     LAB79
        lda     #$FF
        sta     $0640,x
        lda     #$01
        sta     $0600,x
        lda     #$00
        sta     $0660,x
        sta     $0620,x
LAB79:  lda     $06A0,x
        cmp     #$05
        bne     LAB85
        lda     #$03
        sta     $06A0,x
LAB85:  jsr     LEEBA
        rts

        .byte   $38,$A5,$2D,$E5,$2E,$B0,$10,$A9
        .byte   $01,$85,$40,$A9,$00,$85,$AF,$A9
        .byte   $A3,$85,$4F,$A9,$00,$85,$50
        jsr     LEFB3
        rts

        .byte   $BD,$20,$06,$D0,$08,$A9,$37
        jsr     L95B5
        bcc     LABB1
        rts

LABB1:  lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04E0,x
        bne     LAC04
        lda     #$BB
        sta     $04E0,x
        lda     #$01
        sta     $01
        lda     #$38
        jsr     L96CF
        bcs     LAC04
        lda     #$02
        sta     $01
        lda     #$3C
        jsr     L96CF
        bcs     LAC04
        lda     #$38
        jsr     LF159
        bcs     LAC04
        ldx     #$00
        lda     $0420
        and     #$40
        bne     LABEE
        inx
LABEE:  lda     LAC0C,x
        sta     $0430,y
        clc
        lda     $1F
        adc     LAC0A,x
        sta     $0470,y
        lda     $20
        adc     #$00
        sta     $0450,y
LAC04:  ldx     $2B
        dec     $04E0,x
        rts

LAC0A:  .byte   $F8,$08
LAC0C:  .byte   $83,$C3
        lsr     $0420,x
        rts

        .byte   $BD,$10,$01,$D0,$10,$A9,$3A,$20
        .byte   $59,$F1,$B0,$F0,$8A,$99,$20,$01
        .byte   $C8,$98,$9D,$10,$01
        lda     $04E0,x
        bne     LAC74
        lda     $0420,x
        pha
        jsr     LEFEE
        pla
        sta     $0420,x
        ldy     $0110,x
        dey
        clc
        lda     $04A0,x
        adc     #$10
        sta     $04B0,y
        lda     $0460,x
        sta     $0470,y
        lda     $0440,x
        sta     $0450,y
        lda     $00
        cmp     #$30
        bcc     LAC64
        lda     $06A0,x
        cmp     #$02
        bne     LAC80
        lda     #$00
        sta     $06A0,x
        beq     LAC80
LAC64:  lda     #$87
        sta     $0430,y
        inc     $04E0,x
        lda     #$02
        sta     $06A0,x
        sta     $0680,x
LAC74:  lda     $06A0,x
        cmp     #$03
        bne     LAC80
        lda     #$00
        sta     $0680,x
LAC80:  jsr     LEEBA
        bcc     LAC8E
        ldy     $0110,x
        dey
        lda     #$00
        sta     $0430,y
LAC8E:  rts

        .byte   $A9,$37,$85,$00,$4C,$52,$96,$BD
        .byte   $20,$04,$29,$04,$D0,$04,$20,$B3
        .byte   $EF,$60
        lda     #$07
        sta     $01
        sta     $02
        jsr     LF02C
        lda     $00
        bne     LACB6
        jsr     LEEBA
        lda     $01
        bne     LACB6
        rts

LACB6:  lda     #$3B
        jsr     LF159
        lda     #$3B
        jsr     LF159
        lda     #$C4
        sta     $0430,y
        lda     #$07
        sta     $01
LACC9:  lda     #$3C
        jsr     LF159
        bcs     LACFC
        ldx     $01
        lda     LAD00,x
        sta     $0430,y
        lda     LAD08,x
        sta     $0670,y
        lda     LAD10,x
        sta     $0650,y
        lda     LAD18,x
        sta     $0630,y
        lda     LAD20,x
        sta     $0610,y
        lda     LAD28,x
        sta     $04F0,y
        ldx     $2B
        dec     $01
        bpl     LACC9
LACFC:  lsr     $0420,x
        rts

LAD00:  .byte   $C3,$C3,$C3,$C3,$C3,$83,$83,$83
LAD08:  .byte   $96,$7B,$1E,$6A,$F0,$00,$E6,$9E
LAD10:  .byte   $FE,$00,$01,$01,$01,$02,$01,$00
LAD18:  .byte   $6A,$F0,$A8,$6A,$7B,$00,$9E,$E6
LAD20:  .byte   $01,$01,$01,$01,$00,$00,$00,$01
LAD28:  .byte   $0B,$21,$1C,$0B,$21,$10,$19,$19
        .byte   $BD,$10,$01,$D0,$13,$DE,$E0,$04
        .byte   $D0,$0E,$A9,$47,$85,$08,$A9,$01
        .byte   $85,$09,$20,$97,$F1,$FE,$10,$01
        jsr     LEEBA
        rts

        .byte   $BC,$10,$01,$B9,$20,$04,$10,$4B
        .byte   $B9,$00,$04,$C9,$3E,$D0,$44,$38
        .byte   $B9,$A0,$04,$E9,$14,$9D,$A0,$04
        .byte   $B9,$60,$04,$9D,$60,$04,$B9,$40
        .byte   $04,$9D,$40,$04,$20,$EE,$EF,$FE
        .byte   $E0,$04,$BD,$E0,$04,$C9,$9D,$D0
        .byte   $12,$A9,$3F,$20,$59,$F1,$A9,$03
        .byte   $9D,$A0,$06,$A9,$00,$9D,$80
        asl     $9D
        cpx     #$04
        lda     $06A0,x
        cmp     #$02
        bne     LAD9B
        lda     #$00
        sta     $06A0,x
LAD9B:  jsr     LEEBA
        rts

        lsr     $0420,x
        rts

        .byte   $A9,$18,$9D,$50,$01,$BD
        jsr     L1D06
        rts

        asl     $D0
        .byte   $14,$A9,$3D,$20,$59,$F1,$B0,$0D
        .byte   $8A,$99,$20,$01,$38,$BD,$A0,$04
        .byte   $E9,$14,$99,$B0,$04
        lda     $04E0,x
        bne     LADF2
        lda     $0110,x
        and     #$0F
        tay
        clc
        adc     #$01
        sta     $0110,x
        lda     LAE09,y
        sta     $0660,x
        lda     LAE19,y
        sta     $0640,x
        lda     LAE29,y
        sta     $0620,x
        lda     LAE39,y
        sta     $0420,x
        lda     #$2A
        sta     $04E0,x
LADF2:  dec     $04E0,x
        jsr     LEEBA
        bcc     LADFF
        lda     #$00
        sta     $0150,x
LADFF:  sec
        lda     $04A0,x
        sbc     #$08
        sta     $0160,x
        rts

LAE09:  .byte   $00,$CE,$A4,$87,$75,$87,$A4,$CE
        .byte   $00,$32,$5C,$79,$8B,$79,$5C,$32
LAE19:  .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
LAE29:  .byte   $8B,$79,$5C,$32,$00,$32,$5C,$79
        .byte   $8B,$79,$5C,$32,$00,$32,$5C,$79
LAE39:  .byte   $80,$80,$80,$80,$C0,$C0,$C0,$C0
        .byte   $C0,$C0,$C0,$C0,$80,$80,$80,$80
        .byte   $20,$EE,$EF,$38,$BD,$00,$04,$E9
        .byte   $40,$A8,$B9,$79,$AF,$85,$01,$BD
        .byte   $20,$04,$29,$20,$F0,$1B,$A4,$01
        .byte   $A9,$15,$D9,$58,$03,$D0,$07,$A9
        .byte   $04,$9D,$20,$06,$D0,$06
        lda     $00
        cmp     #$60
        bcs     LAE9B
        lda     #$82
        sta     $0420,x
        lda     $0620,x
        cmp     #$04
        bcs     LAE9E
        lda     $04E0,x
        and     #$03
        bne     LAE9B
        sta     $04E0,x
        lda     $0620,x
        inc     $0620,x
        asl     a
        asl     a
        tay
        ldx     $01
        jsr     LAF4C
        ldx     $2B
LAE9B:  jmp     LAF45

LAE9E:  lda     $00
        cmp     #$28
        bcs     LAEEF
        lda     $04E0,x
        and     #$3F
        bne     LAEEF
        lda     #$03
        sta     $01
        lda     #$45
        jsr     L96CF
        bcs     LAEEF
        lda     #$45
        jsr     LF159
        bcs     LAEEF
        lda     $0600,x
        and     #$01
        tax
        lda     LAF7B,x
        sta     $0430,y
        clc
        lda     $04B0,y
        adc     #$03
        sta     $04B0,y
        clc
        lda     $0470,y
        adc     LAF7D,x
        sta     $0470,y
        lda     $0450,y
        adc     LAF7F,x
        sta     $0450,y
        lda     #$3F
        sta     $04F0,y
        ldx     $2B
        inc     $0600,x
LAEEF:  lda     $0660,x
        ora     $0640,x
        bne     LAF34
        lda     #$01
        sta     $01
LAEFB:  lda     #$44
        jsr     LF159
        bcs     LAF2A
        lda     $04B0,y
        sbc     #$24
        sta     $04B0,y
        ldx     $01
        clc
        lda     $0470,y
        adc     LAF7D,x
        sta     $0470,y
        lda     $0450,y
        adc     LAF7F,x
        sta     $0450,y
        lda     #$78
        sta     $04F0,y
        ldx     $2B
        dec     $01
        bpl     LAEFB
LAF2A:  lda     #$48
        sta     $0660,x
        lda     #$01
        sta     $0640,x
LAF34:  sec
        lda     $0660,x
        sbc     #$01
        sta     $0660,x
        lda     $0640,x
        sbc     #$00
        sta     $0640,x
LAF45:  inc     $04E0,x
        jsr     LEFB3
        rts

LAF4C:  lda     #$03
        sta     $02
LAF50:  lda     LAF69,y
        sta     $0356,x
        sta     $0376,x
        sta     $0386,x
        sta     $0396,x
        sta     $03A6,x
        iny
        inx
        dec     $02
        bpl     LAF50
        rts

LAF69:  .byte   $0F,$21,$21,$21,$0F,$31,$35,$21
        .byte   $0F,$30,$25,$10,$0F,$30,$15,$0F
        .byte   $08,$0C
LAF7B:  .byte   $C3,$83
LAF7D:  .byte   $1D,$E3
LAF7F:  .byte   $00,$FF,$5E,$20,$04,$A9,$FF,$9D
        .byte   $20,$01,$BC,$10,$01,$A9,$00,$99
        .byte   $40,$01,$38,$BD,$00,$04,$E9,$42
        .byte   $A8,$BE
        adc     LA0AF,y
        brk
        .byte   $20,$4C,$AF,$60,$BD,$E0,$04,$D0
        .byte   $33,$BD,$10,$01,$C9,$01,$B0,$12
        .byte   $A9,$3E
        sta     $04E0,x
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        inc     $0110,x
        bne     LAFD9
        bne     LAFD5
        lda     #$C0
        sta     $0660,x
        lda     #$FE
        sta     $0640,x
        lda     #$0B
        sta     $04E0,x
        inc     $0110,x
        bne     LAFD9
LAFD5:  lsr     $0420,x
        rts

LAFD9:  dec     $04E0,x
        jsr     LEEBA
        rts

        .byte   $BD,$10,$01,$C9,$02,$D0,$03,$4C
        .byte   $A6,$A4
        lda     $04E0,x
        bne     LB014
        lda     $0110,x
        bne     LB010
        lda     #$1A
        sta     $04E0,x
        lda     #$00
        sta     $0600,x
        sta     $0620,x
        lda     #$03
        sta     $0640,x
        lda     #$33
        sta     $0660,x
        inc     $0110,x
        bne     LB014
LB010:  inc     $0110,x
        rts

LB014:  dec     $04E0,x
        jsr     LEEBA
        rts

        .byte   $BD
        bpl     LB01F
        .byte   $F0
LB01F:  .byte   $03
        jmp     LB0CB

        ldy     #$00
        sty     $0B
        lda     $0420,x
        and     #$40
        bne     LB02F
        iny
LB02F:  clc
        lda     $0460,x
        adc     LB0F6,y
        sta     jump_ptr
        lda     $0440,x
        adc     LB0F8,y
        sta     $09
        clc
        lda     $04A0,x
        adc     #$09
        sta     $0A
        jsr     LCBC3
        ldx     $2B
        lda     $00
        beq     LB05F
        lda     $04A0,x
        sta     $0A
        jsr     LCBC3
        ldx     $2B
        lda     $00
        beq     LB067
LB05F:  lda     $0420,x
        eor     #$40
        sta     $0420,x
LB067:  lda     #$00
        sta     $0600,x
        lda     #$41
        sta     $0620,x
        sec
        lda     $04A0
        sbc     $04A0,x
        bcs     LB07E
        eor     #$FF
        adc     #$01
LB07E:  cmp     #$05
        bcs     LB0BD
        lda     #$00
        sta     $0620,x
        lda     #$02
        sta     $0600,x
        lda     $0420,x
        pha
        jsr     LEFEE
        pla
        sta     $0420,x
        lda     $00
        cmp     #$11
        bcs     LB0BD
        lda     #$01
        sta     $06A0,x
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $04A0,x
        lda     #$70
        sta     $04E0,x
        lda     $0420,x
        and     #$F7
        sta     $0420,x
        inc     $0110,x
        bne     LB0CB
LB0BD:  lda     #$00
        sta     $06A0,x
        lda     #$07
        sta     $06E0,x
        jsr     LEEBA
        rts

LB0CB:  lda     $06A0,x
        cmp     #$05
        bne     LB0D7
        lda     #$01
        sta     $06A0,x
LB0D7:  lda     #$09
        sta     $06E0,x
        dec     $04E0,x
        bne     LB0F2
        dec     $0110,x
        lda     #$00
        sta     $06A0,x
        clc
        lda     $04A0,x
        adc     #$08
        sta     $04A0,x
LB0F2:  jsr     LEFB3
        rts

LB0F6:  .byte   $08,$F8
LB0F8:  .byte   $00,$FF,$BD,$20,$06,$D0,$08,$A9
        .byte   $47,$20,$B5,$95,$90,$01,$60
        lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04E0,x
        bne     LB172
        lda     #$3E
        sta     $04E0,x
        lda     #$06
        sta     $01
        lda     #$48
        jsr     L96CF
        lda     #$49
        jsr     L96CF
        bcs     LB172
        lda     $0600,x
        asl     a
        sta     $01
        lda     #$02
        sta     $02
LB137:  ldy     $01
        lda     LB178,y
        jsr     LF159
        bcs     LB172
        ldx     $01
        clc
        lda     $0470,y
        adc     LB17E,x
        sta     $0470,y
        lda     $0450,y
        adc     #$00
        sta     $0450,y
        .byte   $BD
LB156:  sty     $B1
LB158:  .byte   $99
        .byte   $B0
LB15A:  .byte   $04
        ldx     $2B
        inc     $01
        dec     $02
        bne     LB137
        inc     $0600,x
        lda     $0600,x
        cmp     #$03
        bne     LB172
        lda     #$00
        sta     $0600,x
LB172:  ldx     $2B
        dec     $04E0,x
        rts

LB178:  eor     #$48
        eor     #$48
        eor     #$48
LB17E:  clc
        cli
        bvc     LB1A2
        plp
        rts

LB184:  bpl     LB156
        bpl     LB158
        bpl     LB15A
        lda     #$00
        sta     $01
        sec
        lda     $04A0,x
        sbc     #$0C
        jmp     LB1A1

        lda     #$04
        sta     $01
        clc
        lda     $04A0,x
        adc     #$0C
LB1A1:  .byte   $85
LB1A2:  asl     a
        lda     #$00
        sta     $0B
        lda     $0460,x
        sta     jump_ptr
        lda     $0440,x
        sta     $09
        jsr     LCBC3
        ldx     $2B
        lda     $0110,x
        bne     LB1D7
        lda     $00
        bne     LB1FF
        ldy     $01
        lda     LB203,y
        sta     $0660,x
        lda     LB205,y
        sta     $0640,x
        inc     $0110,x
        lda     #$4B
        sta     $04E0,x
        bne     LB1FF
LB1D7:  ldy     $01
        lda     $04E0,x
        beq     LB1E3
        dec     $04E0,x
        bne     LB1EF
LB1E3:  lda     LB204,y
        sta     $0660,x
        lda     LB206,y
        sta     $0640,x
LB1EF:  lda     $00
        beq     LB1FF
        lda     LB203,y
        sta     $0660,x
        lda     LB205,y
        sta     $0640,x
LB1FF:  jsr     LEEBA
        rts

LB203:  .byte   $41
LB204:  .byte   $E5
LB205:  brk
LB206:  .byte   $00,$BF,$1B,$FF,$FF,$A9,$47,$85
        .byte   $00,$4C,$52,$96,$BD,$10,$01,$F0
        .byte   $2A,$BD,$A0,$06,$C9,$05,$D0,$20
        .byte   $A9,$00,$9D,$80,$06,$BD,$E0,$04
        .byte   $D0,$43,$A9,$00,$85,$01,$20,$72
        .byte   $B2,$DE,$20,$06,$F0,$07,$A9,$1F
        .byte   $9D,$E0,$04,$D0,$30
        dec     $0110,x
        jmp     LB26E

        lda     $06A0,x
        bne     LB26E
        lda     #$00
        sta     $0680,x
        lda     $04E0,x
        bne     LB26B
        lda     #$0A
        sta     $01
        jsr     LB272
        inc     $0620,x
        lda     $0620,x
        cmp     #$06
        bne     LB266
        inc     $0110,x
        bne     LB26E
LB266:  lda     #$1F
        sta     $04E0,x
LB26B:  dec     $04E0,x
LB26E:  jsr     LEFB3
        rts

LB272:  ldx     $01
        lda     $4A
        and     LB2DC,x
        clc
        adc     LB2DD,x
        sta     $0B
        lda     LB2DE,x
        sta     $0D
        lda     #$00
        sta     $0A
        sta     $0C
        jsr     LC874
        ldx     $2B
        lda     #$25
        jsr     bank_switch_enqueue
        lda     #$4D
        jsr     LF159
        bcs     LB2D9
        ldx     $01
        lda     LB2DF,x
        sta     $0670,y
        lda     LB2E0,x
        sta     $0650,y
        lda     $0E
        sta     $0630,y
        lda     $0F
        sta     $0610,y
        sec
        lda     $04B0,y
        sbc     LB2E1,x
        sta     $04B0,y
        lda     $0430,y
        and     #$40
        bne     LB2C6
        inx
        inx
LB2C6:  clc
        lda     $0470,y
        adc     LB2E2,x
        sta     $0470,y
        lda     $0450,y
        adc     LB2E3,x
        sta     $0450,y
LB2D9:  ldx     $2B
        rts

LB2DC:  .byte   $23
LB2DD:  .byte   $18
LB2DE:  .byte   $30
LB2DF:  .byte   $E6
LB2E0:  .byte   $04
LB2E1:  .byte   $0C
LB2E2:  .byte   $0C
LB2E3:  .byte   $00,$F4,$FF,$1F,$60,$18,$D4,$02
        .byte   $00,$08,$00,$F8,$FF,$BD,$10,$01
        .byte   $D0,$44,$BD,$E0,$04,$D0,$28,$BD
        .byte   $A0,$06,$C9,$02,$D0,$2C,$A9,$87
        .byte   $9D,$20,$04,$20,$EE,$EF,$A9,$78
        .byte   $9D,$60,$06,$A9,$04,$9D,$40,$06
        .byte   $A9,$C9,$9D,$20,$06,$A9,$01,$9D
        .byte   $00,$06,$FE,$10,$01
        bne     LB32D
        lda     $06A0,x
        bne     LB32A
        sta     $0680,x
LB32A:  dec     $04E0,x
LB32D:  jsr     LEFB3
        bcc     LB335
        jmp     LB3FB

LB335:  rts

LB336:  jmp     LB3F2

        cmp     #$01
        bne     LB39A
        lda     #$02
        sta     $06A0,x
        lda     $0640,x
        php
        lda     #$0F
        sta     $01
        lda     #$1C
        sta     $02
        jsr     LF0CF
        plp
        bpl     LB336
        lda     $00
        beq     LB336
        lda     #$21
        jsr     bank_switch_enqueue
        lda     #$03
        sta     $06A0,x
        lda     #$00
        sta     $0600,x
        sta     $0620,x
        sta     $0660,x
        sta     $0640,x
        sta     $0680,x
        lda     $0420,x
        and     #$FB
        sta     $0420,x
        lda     #$3E
        sta     $04E0,x
        dec     $0110,x
        sec
        lda     $04A0
        sbc     $04A0,x
        cmp     #$10
        bne     LB3EF
        lda     #$12
        sta     $04E0,x
        lda     #$02
        sta     $0110,x
        bne     LB3EF
LB39A:  lda     $06A0,x
        bne     LB3A4
        lda     #$00
        sta     $0680,x
LB3A4:  lda     $04E0,x
        bne     LB3EF
        lda     #$25
        jsr     bank_switch_enqueue
        jsr     LEFEE
        lda     #$35
        jsr     LF159
        bcs     LB3D4
        lda     $0110,x
        tax
        lda     LB40B,x
        sta     $0670,y
        lda     LB410,x
        sta     $0650,y
        lda     LB415,x
        sta     $0630,y
        lda     LB41A,x
        sta     $0610,y
LB3D4:  txa
        ldx     $2B
        cmp     #$06
        bne     LB3E7
        lda     #$00
        sta     $0110,x
        lda     #$3F
        sta     $04E0,x
        bne     LB3EF
LB3E7:  lda     #$12
        sta     $04E0,x
        inc     $0110,x
LB3EF:  dec     $04E0,x
LB3F2:  jsr     LEEBA
        bcc     LB3FA
        jmp     LB3FB

LB3FA:  rts

LB3FB:  lda     $06C0,x
        bne     LB3FA
        lda     #$4F
        jsr     LF159
        bcs     LB3FA
        lda     #$7E
        .byte   $99
        .byte   $F0
LB40B:  .byte   $04
        rts

        .byte   $6A,$A0,$88
LB410:  .byte   $12,$58,$FB,$FC,$FD
LB415:  .byte   $FE,$FF,$8C,$4E,$9A
LB41A:  .byte   $C2,$D2,$06,$07,$07,$07,$07,$20
        .byte   $EE,$EF,$A9,$00,$9D,$80,$06,$A9
        .byte   $0B,$85,$01,$A9,$0C,$85,$02,$20
        .byte   $CF,$F0,$BD,$A0,$06,$D0,$1A,$A9
        .byte   $00,$9D,$A0,$06,$BD,$E0,$04,$D0
        .byte   $4C,$FE,$A0,$06,$A9,$1F,$9D,$E0
        .byte   $04,$BD,$20,$04,$29,$F7,$9D,$20
        .byte   $04
        lda     $04E0,x
        bne     LB48F
        lda     #$25
        jsr     bank_switch_enqueue
        lda     #$35
        jsr     LF159
        bcs     LB469
        lda     #$02
        sta     $0610,y
LB469:  inc     $0110,x
        lda     $0110,x
        cmp     #$03
        bne     LB48A
        lda     #$00
        sta     $0110,x
        sta     $06A0,x
        lda     #$7E
        sta     $04E0,x
        lda     $0420,x
        ora     #$08
        sta     $0420,x
        bne     LB48F
LB48A:  lda     #$1F
        sta     $04E0,x
LB48F:  dec     $04E0,x
        jsr     LEEBA
        rts

        .byte   $BD,$E0,$04,$D0,$2E,$A9,$20,$9D
        .byte   $E0,$04,$A9,$03,$85,$01,$A9,$51
        .byte   $20,$CF,$96
        bcs     LB4C9
        jsr     LEFEE
        lda     $00
        cmp     #$48
        bcs     LB4C9
        lda     #$51
        jsr     LF159
        bcs     LB4C9
        sec
        lda     $04B0,y
        sbc     #$0C
        sta     $04B0,y
        lda     #$1F
        sta     $04F0,y
LB4C9:  dec     $04E0,x
        jsr     LEFB3
        rts

        .byte   $BD,$10,$01,$D0,$3B,$DE,$E0,$04
        .byte   $D0,$5A,$A9,$87,$9D,$20,$04,$20
        .byte   $EE,$EF,$A5,$4A,$29,$1F,$85,$01
        .byte   $38,$A5,$00,$E5,$01,$B0,$02,$A9
        .byte   $00
        sta     $00
        lda     #$00
        asl     $00
        rol     a
        asl     $00
        rol     a
        asl     $00
        rol     a
        sta     $0600,x
        lda     $00
        sta     $0620,x
        lda     #$04
        sta     $0640,x
        inc     $0110,x
        bne     LB534
        cmp     #$02
        bcs     LB544
        lda     $0640,x
        php
        lda     #$05
        sta     $01
        lda     #$08
        sta     $02
        jsr     LF0CF
        plp
        bpl     LB534
        lda     $00
        beq     LB534
        lda     #$5D
        sta     $04E0,x
        inc     $0110,x
        bne     LB544
LB534:  lda     $06A0,x
        cmp     #$0A
        bne     LB540
        lda     #$06
        sta     $06A0,x
LB540:  jsr     LEEBA
        rts

LB544:  lda     $04E0,x
        beq     LB558
        dec     $04E0,x
        lda     $06A0,x
        cmp     #$0A
        bne     LB558
        lda     #$06
        sta     $06A0,x
LB558:  jsr     LEFB3
        rts

        .byte   $DE,$E0,$04,$F0,$04,$20,$B3,$EF
        .byte   $60
        lsr     $0420,x
        rts

        .byte   $A9,$7D,$D0,$06,$A9,$BB,$D0,$02
        .byte   $A9,$FA
        sta     $00
        lda     $0110,x
        bne     LB584
        lda     $00
        sta     $0160,x
        inc     $0110,x
        bne     LB5DE
LB584:  cmp     #$01
        bne     LB5A9
        lda     $0160,x
        bne     LB5DE
        lda     #$90
        sta     $0420,x
        lda     #$3C
        jsr     bank_switch_enqueue
        lda     #$7D
        sta     $0160,x
        inc     $0110,x
        lda     #$00
        sta     $0680,x
        sta     $06A0,x
        beq     LB5DE
LB5A9:  lda     $06A0,x
        cmp     #$05
        bne     LB5B5
        lda     #$00
        sta     $0680,x
LB5B5:  lda     #$01
        sta     $04E0,x
        lda     $0460,x
        and     $0600,x
        sta     $0640,x
        lda     $04A0,x
        and     $0620,x
        sta     $0660,x
        lda     $0160,x
        bne     LB5DE
        lda     #$A0
        sta     $0420,x
        lda     #$7D
        sta     $0160,x
        dec     $0110,x
LB5DE:  dec     $0160,x
        jsr     LEFB3
        rts

        .byte   $A5,$2A,$C9,$0C,$F0,$33,$5E,$20
        .byte   $04,$A9,$FF,$9D,$F0,$00,$A5,$2A
        .byte   $C9,$0A,$F0,$19,$38,$BD,$40,$04
        .byte   $E9,$0A,$0A,$0A,$0A,$A8,$A2,$00
LB605:  lda     LB629,y
        sta     $035E,x
        iny
        inx
        cpx     #$08
        bne     LB605
        rts

        lda     #$0F
        sta     $0363
        sta     $0364
        sta     $0365
        rts

        lda     $AA
        beq     LB626
        jsr     LEFB3
        rts

LB626:  jmp     LB97A

LB629:  .byte   $0F,$39,$18,$12,$0F,$39,$18,$01
        .byte   $0F,$39,$18,$01,$0F,$39,$18,$01
        .byte   $0F,$39,$18,$01,$0F,$39,$18,$0F
        .byte   $BD,$10,$01,$D0,$5B,$A9,$03,$85
        .byte   $01,$A9,$04,$85,$02,$20,$CF,$F0
        .byte   $A5,$03,$F0,$04,$5E,$20,$04,$60
        lda     $00
        beq     LB6D5
        lda     #$04
        sta     $01
LB661:  lda     #$58
        jsr     LF159
        bcs     LB686
        ldx     $01
        lda     LB6D9,x
        sta     $0670,y
        lda     LB6DE,x
        sta     $0650,y
        lda     #$01
        sta     $0120,y
        lda     #$1F
        sta     $04F0,y
        ldx     $2B
        dec     $01
        bne     LB661
LB686:  lda     #$81
        sta     $0420,x
        lda     #$00
        sta     $0660,x
        sta     $0640,x
        sta     $0620,x
        sta     $0600,x
        lda     #$1F
        sta     $04E0,x
        inc     $0110,x
        lda     $0110,x
        cmp     #$01
        bne     LB6CC
        dec     $04E0,x
        bne     LB6D5
        clc
        lda     $0660,x
        eor     #$FF
        adc     #$01
        sta     $0660,x
        lda     $0640,x
        eor     #$FF
        adc     #$00
        sta     $0640,x
        inc     $0110,x
        lda     #$1F
        sta     $04E0,x
        bne     LB6D5
LB6CC:  dec     $04E0,x
        bne     LB6D5
        lsr     $0420,x
        rts

LB6D5:  jsr     LEEBA
        rts

LB6D9:  .byte   $00,$41,$82,$C4,$06
LB6DE:  .byte   $00,$00,$00,$00,$01,$BD,$10,$01
        .byte   $D0
        ora     $E0DE,x
        .byte   $04,$D0,$2F,$FE,$10,$01,$A9,$1F
        .byte   $9D,$E0,$04,$A9,$00,$9D,$00,$06
        .byte   $9D,$20,$06,$9D,$40,$06,$9D,$60
        .byte   $06,$F0,$17
        cmp     #$01
        bne     LB71C
        dec     $04E0,x
        bne     LB71C
        inc     $0110,x
        lda     #$00
        sta     jump_ptr
        lda     #$04
        sta     $09
        jsr     LF197
LB71C:  jsr     LEEBA
        rts

        .byte   $BD,$40,$06,$08,$A9,$07,$85,$00
        .byte   $A9,$08,$85,$02,$20,$CF,$F0,$28
        .byte   $10,$0E,$A5,$00,$F0,$0A,$A9,$03
        .byte   $9D,$40,$06,$A9,$76,$9D,$60,$06
        lda     $03
        beq     LB747
        lsr     $0420,x
LB747:  jsr     LEEBA
        rts

        .byte   $BD,$E0,$04,$F0,$13,$DE,$E0,$04
        .byte   $D0,$0E,$A9,$00,$9D,$00,$06,$9D
        .byte   $20,$06,$9D,$60,$06,$9D,$40,$06
        jsr     LEEBA
        rts

        .byte   $BD,$E0,$04,$D0,$3A,$A9,$00,$9D
        .byte   $A0,$06,$9D,$80,$06,$A9,$07,$85
        .byte   $01,$A9,$08,$85,$02,$20,$2C,$F0
        .byte   $A5,$00,$D0,$03,$4C,$08,$B8
        lda     #$00
        sta     $0620,x
        sta     $0600,x
        sta     $0660,x
        sta     $0640,x
        inc     $06A0,x
        lda     #$2E
        jsr     bank_switch_enqueue
        lda     #$1F
        sta     $0110,x
        inc     $04E0,x
        bne     LB808
        cmp     #$01
        bne     LB7B7
        dec     $0110,x
        bne     LB808
        inc     $04E0,x
        lda     #$38
        sta     $0110,x
LB7B7:  lda     $0110,x
        and     #$07
        bne     LB7FD
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     $0110,x
        lsr     a
        and     #$0C
        sta     $02
        ldx     #$04
        sta     $01
LB7CF:  lda     #$5F
        jsr     LF159
        bcs     LB7FD
        ldx     $02
        clc
        lda     $04B0,y
        adc     $E11F,x
        sta     $04B0,y
        clc
        lda     $0470,y
        adc     $E12F,x
        sta     $0470,y
        lda     $0450,y
        adc     $E13F,x
        sta     $0450,y
        ldx     $2B
        inc     $02
        dec     $01
        bne     LB7CF
LB7FD:  ldx     $2B
        dec     $0110,x
        bpl     LB808
        lsr     $0420,x
        rts

LB808:  lda     $06A0,x
        cmp     #$04
        bne     LB814
        lda     #$02
        sta     $06A0,x
LB814:  jsr     LEEBA
        rts

        .byte   $BD,$E0,$04,$D0,$09,$A9,$00,$9D
        .byte   $80,$06,$20,$BA,$EE,$60
        lda     $06A0,x
        ora     $0680,x
        bne     LB840
        lda     $0420,x
        eor     #$40
        sta     $0420,x
        lda     #$FE
        sta     $0640,x
        lda     #$00
        sta     $0660,x
LB840:  clc
        lda     $0660,x
        adc     #$20
        sta     $0660,x
        lda     $0640,x
        adc     #$00
        sta     $0640,x
        jsr     LEEBA
        rts

        .byte   $A5,$2A,$C9,$08,$F0,$15,$A9,$58
        .byte   $9D,$50,$01,$38,$BD,$A0,$04,$E9
        .byte   $18,$9D,$60,$01,$A5,$AA,$D0,$20
        .byte   $4C,$7A,$B9
        lda     #$10
        sta     $0150,x
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $0160,x
        lda     $AA
        bne     LB88D
        jsr     LEEBA
        bcc     LB88C
        lda     #$00
        sta     $0150,x
LB88C:  rts

LB88D:  jsr     LEFB3
        rts

        .byte   $BD,$E0,$04,$10,$01,$60
        bne     LB8F0
        lda     $15
        sta     $14
        inc     $38
        lda     #$07
        sta     $06C0,x
        lda     #$08
        sta     $B3
        lda     #$01
        sta     $B1
        lda     #$17
        sta     $03B6
        lda     #$E0
        sta     $03B7
        lda     #$00
        sta     $04E1
        sta     $06C1
        sta     $05A9
        sta     $B2
        lda     #$B8
        sta     $05A7
        lda     #$0F
        ldx     #$0F
LB8CC:  sta     $0356,x
        dex
        bpl     LB8CC
        ldx     $2B
        inc     $04E0,x
        lda     #$18
        sta     $0110,x
        lda     #$63
        sta     $00
        ldy     #$0F
LB8E2:  jsr     LF014
        bcs     LB8EF
        lda     #$01
        sta     $0610,y
        dey
        bpl     LB8E2
LB8EF:  rts

LB8F0:  lda     #$01
        sta     $40
        lda     #$00
        sta     $AF
        lda     #$00
        sta     $4F
        lda     #$01
        sta     $50
        lda     $04E0,x
        cmp     #$01
        bne     LB927
        dec     $0110,x
        bne     LB94E
        lda     #$40
        sta     $0110,x
        lda     #$63
        jsr     LF159
        lda     #$01
        sta     $0610,y
        sta     $04F0,y
        dec     $06C0,x
        bne     LB94E
        inc     $04E0,x
        rts

LB927:  dec     $0110,x
        bne     LB94E
        ldy     $06C0,x
        lda     LB971,y
        sta     $0110,x
        bmi     LB94F
        lda     LB976,y
        sta     $02
        lda     #$63
        jsr     LF159
        lda     $02
        sta     $04B0,y
        lda     #$01
        sta     $0610,y
        inc     $06C0,x
LB94E:  rts

LB94F:  lda     #$63
        sta     $00
        ldy     #$0F
LB955:  jsr     LF014
        bcs     LB962
        lda     #$00
        sta     $0610,y
        dey
        bpl     LB955
LB962:  ldx     $2B
        lda     #$FF
        sta     $04E0,x
        inc     $B1
        lda     #$0B
        jsr     bank_switch_enqueue
        rts

LB971:  .byte   $40,$01,$20,$28,$FF
LB976:  .byte   $98,$98,$48,$78
LB97A:  lda     $0641
        sta     $0640,x
        lda     $0661
        sta     $0660,x
LB986:  lda     $0601
        sta     $0600,x
        lda     $0621
        sta     $0620,x
        lda     $05A7
        sta     $0420,x
        jsr     LEEBA
        lda     $B3
        cmp     #$08
        beq     LB9B1
        lda     $0400,x
        cmp     #$69
        beq     LB9B1
        lda     $0420,x
        ora     #$23
        sta     $0420,x
        rts

LB9B1:  lda     #$8B
        sta     $0420,x
        rts

        .byte   $A9
        brk
        sta     $06A0,x
        lda     $05A7
        and     #$40
        beq     LB9C6
        inc     $06A0,x
LB9C6:  lda     #$00
        sta     $0680,x
        jmp     LB97A

        .byte   $A5,$2A,$C9,$08,$F0,$03,$4C,$7A
        .byte   $B9
        jsr     LEEBA
        lda     $04A0,x
        cmp     #$80
        bne     LB9F5
        lda     #$00
        sta     $0640,x
        lda     $06A0,x
        ora     $0680,x
        bne     LB9F4
        inc     $04E1
        lsr     $0420,x
LB9F4:  rts

LB9F5:  lda     #$00
        sta     $06A0,x
        sta     $0680,x
        rts

        .byte   $BD,$E0,$04,$D0,$13,$A9,$80,$9D
        .byte   $60,$06,$A9,$FF,$9D,$40,$06,$BD
        .byte   $A0,$04,$C9,$7F,$90,$1B,$B0,$11
        lda     #$80
        sta     $0660,x
        lda     #$00
        sta     $0640,x
        lda     $04A0,x
        cmp     #$68
        bcs     LBA2F
        lda     #$00
        sta     $0640,x
        sta     $0660,x
LBA2F:  jmp     LB986

        .byte   $BD,$A0,$06,$D0,$2F,$9D,$80,$06
        .byte   $DE,$10,$01,$D0,$23,$BD,$20,$04
        .byte   $29,$40,$D0,$04,$5E,$20,$04,$60
        clc
        lda     $0460,x
        adc     #$08
        sta     $0460,x
        inc     $06A0,x
        lda     #$01
        sta     $0160,x
        lda     #$0F
        sta     $0110,x
        bne     LBA66
        jsr     LEEBA
        rts

LBA66:  lda     $0160,x
        bne     LBA90
        dec     $0110,x
        beq     LBA86
        lda     $0460,x
        cmp     #$30
        bcc     LBA86
        cmp     #$D0
        bcs     LBA86
        lda     $04A0,x
        cmp     #$30
        bcc     LBA86
        cmp     #$C0
        bcc     LBAC8
LBA86:  lda     #$01
        sta     $0160,x
        lda     #$3E
        sta     $0110,x
LBA90:  lda     #$00
        sta     $0600,x
        sta     $0620,x
        sta     $0660,x
        sta     $0640,x
        dec     $0110,x
        bne     LBAC8
        lda     #$83
        sta     $0420,x
        lda     #$01
        sta     $06E0,x
        lda     #$00
        sta     $0160,x
        ldy     $04E0,x
        lda     LBAE3,y
        sta     $0110,x
        lda     LBAE7,y
        sta     jump_ptr
        lda     LBAEB,y
        sta     $09
        jsr     LF197
LBAC8:  lda     $06A0,x
        cmp     #$06
        bne     LBAD4
        lda     #$04
        sta     $06A0,x
LBAD4:  jsr     LEEBA
        bcc     LBAE2
        sec
        lda     $06C1
        sbc     #$02
        sta     $06C1
LBAE2:  rts

LBAE3:  .byte   $3E,$1F,$1F,$1F
LBAE7:  .byte   $00,$68,$00,$80
LBAEB:  .byte   $01,$01,$02,$02,$A5,$B1,$C9,$04
        .byte   $B0,$15,$18,$BD,$60,$06,$69,$40
        .byte   $9D,$60,$06,$BD,$40,$06,$69,$00
        .byte   $9D,$40,$06
LBB06:  jsr     LEEBA
        rts

        lda     #$07
        sta     $01
        lda     #$08
        sta     $02
        jsr     LF02C
        lda     $00
        beq     LBB06
        lda     #$04
        sta     $0640,x
        lda     #$78
        sta     $0660,x
        bne     LBB06
        sec
        lda     $0620,x
        sbc     #$01
        sta     $0620,x
        tay
        lda     $0600,x
        sbc     #$00
        sta     $0600,x
        bne     LBB76
        cpy     #$00
        beq     LBB4C
        cpy     #$3E
        bcs     LBB76
        lda     $06A0,x
        cmp     #$06
        bne     LBB82
        lda     #$04
        bne     LBB7F
LBB4C:  lda     #$77
        sta     $0620,x
        lda     #$01
        sta     $0600,x
        lda     #$6E
        ldx     #$01
        jsr     LF159
        bcs     LBB76
        txa
        pha
        tya
        adc     #$10
        tax
        stx     $2B
        lda     #$08
        sta     $09
        lda     #$00
        sta     jump_ptr
        jsr     LF197
        pla
        tax
        stx     $2B
LBB76:  lda     $06A0,x
        cmp     #$04
        bne     LBB82
        lda     #$00
LBB7F:  sta     $06A0,x
LBB82:  jsr     LEFB3
        bcc     LBB97
        sec
        lda     $06C1
        sbc     #$06
        sta     $06C1
        bcs     LBB97
        lda     #$00
        sta     $06C1
LBB97:  rts

        lda     #$00
        sta     $0680,x
        ldy     $06A0,x
        clc
        lda     $0460,x
        adc     LBBAB,y
        sta     $0460,x
        rts

LBBAB:  .byte   $03,$02,$20,$EE,$EF,$BD,$E0,$04
        .byte   $D0,$22,$A5,$00,$C9,$38
        bcs     LBBD3
        lda     $4A
        sta     $01
        lda     #$03
        sta     $02
        jsr     LC84E
        ldy     $04
        ldx     $2B
        lda     LBC2D,y
        sta     $0110,x
        inc     $04E0,x
LBBD3:  jsr     LEFB3
        rts

        cmp     #$02
        bcs     LBBFD
        lda     $00
        cmp     #$38
        bcc     LBBE6
        dec     $04E0,x
        beq     LBBD3
LBBE6:  dec     $0110,x
        bne     LBBD3
        lda     #$02
        sta     $0640,x
        lda     #$00
        sta     $0660,x
        lda     #$83
        sta     $0420,x
        inc     $04E0,x
LBBFD:  lda     $0640,x
        bpl     LBC15
        lda     $04A0,x
        cmp     #$E0
        bcc     LBC29
        lda     #$00
        sta     $04E0,x
        lda     #$A0
        sta     $0420,x
        bne     LBC29
LBC15:  lda     $04A0,x
        cmp     #$80
        bcs     LBC29
        lda     #$FF
        sta     $0660,x
        sta     $0640,x
        lda     #$87
        sta     $0420,x
LBC29:  jsr     LEEBA
        rts

LBC2D:  .byte   $1F,$2E,$7D,$BD,$E0,$04,$C9,$3E
LBC35:  .byte   $D0,$2F,$BD,$A0,$06,$C9,$05,$D0
        .byte   $37,$BD,$80,$06,$D0,$32,$A9,$74
        .byte   $20,$59,$F1,$B0,$17,$BD,$00,$04
        .byte   $99,$F0,$04,$18,$B9,$B0,$04,$69
        .byte   $04,$99,$B0,$04,$A9,$FF,$99,$50
        .byte   $06,$99,$70,$06
        lda     #$00
        sta     $04E0,x
        inc     $04E0,x
        lda     $06A0,x
        cmp     #$02
        bne     LBC75
        lda     #$00
        sta     $06A0,x
LBC75:  jsr     LEFB3
        rts

        .byte   $BD,$A0,$06,$F0,$04,$20,$B3,$EF
        .byte   $60
        lda     #$00
        sta     $0680,x
        lda     #$03
        sta     $01
        lda     #$04
        sta     $02
        jsr     LF02C
        lda     $00
        beq     LBCA3
        ldy     $04E0,x
        lda     LBC35,y
        jsr     bank_switch_enqueue
        inc     $06A0,x
        rts

LBCA3:  jsr     LEEBA
        rts

        and     LA93E,x
        .byte   $07
        sta     $01
        ldy     #$08
        bne     LBCB7
        lda     #$03
        sta     $01
        ldy     #$04
LBCB7:  lda     $0420,x
        cmp     #$81
        beq     LBCF2
        lda     $01
        pha
        tya
        pha
        jsr     LEEBA
        pla
        sta     $02
        pla
        sta     $01
        lda     $0420,x
        bpl     LBCF1
        lda     $0640,x
        php
        jsr     LF0CF
        plp
        bpl     LBCF1
        lda     $00
        beq     LBCF1
        lda     #$FA
        sta     $0110,x
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        lda     #$81
        sta     $0420,x
LBCF1:  rts

LBCF2:  lda     $04E0,x
        beq     LBD04
        dec     $0110,x
        bne     LBD00
        lsr     $0420,x
        rts

LBD00:  jsr     LEFB3
        rts

LBD04:  jsr     LEFAF
        rts

        ldy     #$25
        lda     $1C
        and     #$08
        bne     LBD12
        ldy     #$0F
LBD12:  sty     $0371
        jsr     LEFB3
        lda     $01
        beq     LBD23
        txa
        and     #$0F
        sta     $BA
        inc     $BA
LBD23:  rts

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
        .byte   $FF,$FF,$FF,$FF,$78,$EE,$E1,$BF
        .byte   $4C,$D1,$F2,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$F0,$CF
        .byte   $E0,$FF,$E0
LBFFF:  .byte   $FF
