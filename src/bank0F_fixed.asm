.segment "FIXED"

; =============================================================================
; Bank $0F — Fixed Bank ($C000-$FFFF)
; Always mapped. Bank switching (MMC1 serial writes), NMI handler,
; PPU update routines, controller input, palette upload, and
; interrupt vectors. All banks call into this bank for shared services.
; =============================================================================

; da65 V2.18 - Ubuntu 2.19-1
; Created:    2026-02-23 18:17:35
; Input file: build/bank0F.bin
; Page:       1


        .setcpu "6502"

jump_ptr           := $0008
L2020           := $2020
banked_entry           := $8000
banked_entry_alt           := $8003
L800C           := $800C
L800F           := $800F
L8012           := $8012
L8072           := $8072
L8076           := $8076
L8079           := $8079
L8088           := $8088
L80AB           := $80AB
L84EE           := $84EE
L8600           := $8600
L9115           := $9115
L925B           := $925B
LAF4C           := $AF4C

; =============================================================================
; Bank Switching (MMC1)
; MMC1 requires 5 serial writes to set a register. Each write sends bit 0.
; Writing to $E000-$FFFF sets the PRG bank register.
; =============================================================================
bank_switch:                            ; PRG bank switch — A = bank number ($00-$0E)
        sta     $29                     ; Save requested bank number
        sta     $69                     ; Backup for later restore
        inc     $68                     ; Set "bank switch in progress" flag
        sta     mmc1_scratch            ; MMC1 serial write: bit 0
        lsr     a
        sta     mmc1_scratch            ; bit 1
        lsr     a
        sta     mmc1_scratch            ; bit 2
        lsr     a
        sta     mmc1_scratch            ; bit 3
        lsr     a
        sta     mmc1_scratch            ; bit 4 (5th write commits)
        lda     #$00
        sta     $68                     ; Clear "in progress" flag
        lda     $67                     ; Check if callback pending
        bne     bank_switch_with_callback
        rts

bank_switch_with_callback:  lda     #$0C; Switch to bank $0C (CHR upload?), call banked_entry
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        jsr     banked_entry
bank_switch_process_queue:  ldx     $66 ; Process queued bank switch requests
        beq     bank_switch_queue_done
        lda     $057F,x
        jsr     banked_entry_alt
        dec     $66
        bne     bank_switch_process_queue
bank_switch_queue_done:  lda     #$00   ; Queue empty — restore original bank
        sta     $67
        lda     $69
        jmp     bank_switch

bank_switch_enqueue:  ldy     $66       ; Enqueue a bank switch request (A = bank number)
        cpy     #$10
        bcs     bank_switch_enqueue_rts
        sta     $0580,y
        inc     $66
bank_switch_enqueue_rts:  rts

        .byte   $8D,$FF,$9F,$4A,$8D,$FF,$9F,$4A
        .byte   $8D,$FF,$9F,$4A,$8D,$FF,$9F,$4A
        .byte   $8D,$FF,$9F,$60,$A9,$0D,$20,$00
        .byte   $C0,$20,$06,$80,$A9,$0E,$20,$00
        .byte   $C0,$60
LC07F:  lda     $23
        sta     $25
        lda     $24
        sta     $26
        jsr     LC427
        lda     #$00
        sta     $1D
LC08E:  lda     $1D
        beq     LC08E
        jsr     read_controllers
        lda     $23
        eor     $25
        and     $23
        sta     $27
        lda     $24
        eor     $26
        and     $24
        sta     $28
        lda     #$0E
        jsr     bank_switch
        rts

        .byte   $A5,$23,$85,$25,$A5,$24,$85,$26
        .byte   $20,$27,$C4,$A9,$00,$85,$1D
LC0BA:  lda     $1D
        beq     LC0BA
        jsr     read_controllers
        lda     $23
        eor     $25
        and     $23
        sta     $27
        lda     $24
        eor     $26
        and     $24
        sta     $28
        lda     #$0D
        jsr     bank_switch
        rts

LC0D7:  lda     $23
        pha
        lda     $24
        pha
        lda     $27
        pha
        lda     #$1E
        ora     $F8
        sta     $F8
        sta     $2001
        lda     #$00
        sta     $1D
LC0ED:  lda     $1D
        beq     LC0ED
        pla
        sta     $27
        pla
        sta     $24
        pla
        sta     $23
        lda     #$0E
        jsr     bank_switch
        rts

LC100:  pha
        jsr     LC07F
        pla
        sec
        sbc     #$01
        bne     LC100
        rts

LC10B:  lda     #$41
        jsr     bank_switch_enqueue
        lda     #$FF
        jsr     bank_switch_enqueue
        lda     $2C
        bne     LC17E
        sta     $36
LC11B:  and     #$01
        bne     LC166
        lda     $36
        and     #$07
        tax
        ldy     #$01
LC126:  lda     #$25
        sta     $040E,y
        lda     #$80
        sta     $042E,y
        clc
        lda     $0460
        adc     LC1E0,x
        sta     $046E,y
        lda     $0440
        adc     LC1E8,x
        sta     $044E,y
        lda     $04A0
        adc     LC1D8,x
        sta     $04AE,y
        lda     #$01
        sta     $06AE,y
        lda     #$00
        sta     $062E,y
        sta     $060E,y
        sta     $066E,y
        sta     $064E,y
        sta     $068E,y
        inx
        dey
        bpl     LC126
LC166:  jsr     LC352
        inc     $36
        lda     $36
        cmp     #$10
        bcc     LC11B
        lsr     $042E
        lsr     $042F
        jsr     LC393
        lda     #$A0
        bne     LC180
LC17E:  lda     #$E0
LC180:  sta     $36
LC182:  lsr     $0420
        jsr     LC352
        dec     $36
        bne     LC182
        lda     #$10
        sta     $2000
        lda     #$06
        sta     $2001
        lda     $2A
        and     #$07
        jsr     bank_switch
        ldx     #$00
        lda     $0440
LC1A2:  cmp     $BB07,x
        bcc     LC1AC
        inx
        cpx     #$05
        bne     LC1A2
LC1AC:  stx     $B0
        ldx     #$FF
        txs
        lda     #$0E
        jsr     bank_switch
        dec     $A8
        bne     LC1D5
        lda     #$00
        sta     $A7
        lda     #$0D
        jsr     bank_switch
        jsr     L800C
        lda     #$0E
        jsr     bank_switch
        lda     $FD
        bne     LC1D2
        jmp     L8088

LC1D2:  jmp     L8072

LC1D5:  jmp     L80AB

LC1D8:  .byte   $F8,$08,$FB,$05,$00,$00,$05,$FB
LC1E0:  .byte   $00,$00,$FB,$05,$FB,$08,$FB,$05
LC1E8:  .byte   $00,$00,$FF,$00,$FF,$00,$FF,$00
LC1F0:  jsr     LC289
        inc     $BD
LC1F5:  jsr     LC819
        lda     $2A
        cmp     #$08
        bne     LC20F
        lda     $37
        cmp     #$03
        bne     LC20F
        lda     #$00
        sta     $BD
        lda     #$01
        sta     $2C
        jmp     LC10B

LC20F:  lda     $B1
        cmp     #$FF
        bne     LC1F5
        lda     #$00
        sta     $BD
        lda     #$10
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001
        lda     #$00
        sta     $B0
        ldx     #$FF
        txs
        lda     #$0E
        jsr     bank_switch
        ldx     $2A
        cpx     #$08
        bcs     LC261
        lda     LC279,x
        ora     $9A
        sta     $9A
        lda     LC281,x
        ora     $9B
        sta     $9B
        lda     #$0D
        jsr     bank_switch
        jsr     L8012
        lda     #$0E
        jsr     bank_switch
        lda     $9A
        cmp     #$FF
        beq     LC25D
        jmp     L8076

LC25D:  lda     #$07
        sta     $2A
LC261:  inc     $2A
        lda     $2A
        cmp     #$0E
        bne     LC276
        lda     #$0D
        jsr     bank_switch
        jsr     L800F
        lda     #$0E
        jmp     cold_boot_init

LC276:  jmp     L8079

LC279:  .byte   $01,$02,$04,$08,$10,$20,$40,$80
LC281:  .byte   $01,$02,$00,$00,$00,$04,$00,$00
LC289:  lda     #$00
        sta     $05AA
        sta     $05A7
        sta     $05A9
        sta     $05A8
        sta     $AA
        lda     #$FE
        sta     $B1
        rts

        .byte   $A9,$00,$85,$FD,$A9,$02,$8D,$54
        .byte   $03,$A9,$04,$8D,$55,$03,$A9,$BB
        .byte   $85,$FD
LC2B0:  jsr     LC386
        dec     $FD
        bne     LC2B0
        lda     #$00
        sta     $0355
        sta     $0354
        ldx     #$02
LC2C1:  lda     LC321,x
        sta     $0357,x
        dex
        bpl     LC2C1
        lda     #$86
        sta     $FF
        lda     #$00
        sta     $FE
LC2D2:  lda     #$09
        jsr     bank_switch
        lda     $FD
        lsr     a
        tax
        lda     LC324,x
        sta     $03B6
        lda     LC33B,x
        sta     $03B7
        lda     $FD
        and     #$01
        beq     LC2F5
        lda     $03B7
        ora     #$20
        sta     $03B7
LC2F5:  ldy     #$20
LC2F7:  lda     ($FE),y
        sta     $03B8,y
        dey
        bpl     LC2F7
        lda     #$20
        sta     $47
        clc
        lda     $FE
        adc     #$20
        sta     $FE
        lda     $FF
        adc     #$00
        sta     $FF
        jsr     LC386
        inc     $FD
        lda     $FD
        cmp     #$2E
        bne     LC2D2
        lda     #$0E
        jsr     bank_switch
        rts

LC321:  .byte   $28,$18,$2C
LC324:  .byte   $10,$1A,$1A,$1B,$1B,$1B,$1B,$1C
        .byte   $1C,$1C,$1C,$1D,$1D,$1D,$1D,$1E
        .byte   $1E,$1E,$1E,$1F,$1F,$1F,$1F
LC33B:  .byte   $00,$80,$C0,$00,$40,$80,$C0,$00
        .byte   $40,$80,$C0,$00,$40,$80,$C0,$00
        .byte   $40,$80,$C0,$00,$40,$80,$C0
LC352:  lda     #$0E
        jsr     bank_switch
        lda     #$00
        sta     $0680
        lda     #$01
        sta     $4B
        jsr     LDCD0
        jsr     LD658
        jsr     LC5A9
        jsr     L925B
LC36C:  jsr     LCC77
        lda     $FB
        beq     LC382
        inc     $FC
        cmp     $FC
        beq     LC37B
        bcs     LC382
LC37B:  jsr     LC0D7
        lda     #$00
        sta     $FC
LC382:  jsr     LC07F
        rts

LC386:  ldx     #$1F
        lda     #$00
LC38A:  sta     $0680,x
        dex
        bpl     LC38A
        jmp     LC36C

LC393:  lda     $0440
        sta     $09
        lda     $0460
        sta     jump_ptr
        lda     $04A0
        sta     $0A
        lda     #$25
        sta     $0B
        ldx     #$0D
        ldy     #$0B
LC3AA:  lda     #$80
        ora     LC41B,y
        sta     $0420,x
        lda     $0B
        sta     $0400,x
        lda     $09
        sta     $0440,x
        lda     jump_ptr
        sta     $0460,x
        lda     $0A
        sta     $04A0,x
        lda     LC3EB,y
        sta     $0620,x
        lda     LC3F7,y
        sta     $0600,x
        lda     LC403,y
        sta     $0660,x
        lda     LC40F,y
        sta     $0640,x
        lda     #$00
        sta     $0680,x
        sta     $06A0,x
        dex
        dey
        bpl     LC3AA
        rts

LC3EB:  .byte   $00,$00,$00,$00,$60,$60,$60,$60
        .byte   $00,$C0,$00,$E0
LC3F7:  .byte   $00,$02,$00,$02,$01,$01,$01,$01
        .byte   $00,$00,$00,$00
LC403:  .byte   $00,$00,$00,$00,$60,$A0,$A0,$60
        .byte   $C0,$00,$40,$00
LC40F:  .byte   $02,$00,$FE,$00,$01,$FE,$FE,$01
        .byte   $00,$00,$FF,$00
LC41B:  .byte   $00,$40,$00,$00,$40,$40,$00,$00
        .byte   $00,$40,$00,$00
LC427:  lda     $AA
        bne     LC45C
        lda     $0355
        beq     LC45C
        inc     $44
        cmp     $44
        bcs     LC45C
        lda     #$00
        sta     $44
        inc     $43
        lda     $43
        cmp     $0354
        bcc     LC447
        lda     #$00
        sta     $43
LC447:  asl     a
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
LC44E:  lda     $0376,x
        sta     $0356,y
        inx
        iny
        cpy     #$10
        bne     LC44E
        inc     $3A
LC45C:  rts

        .byte   $A5,$2A,$29,$07,$20,$00,$C0,$A9
        .byte   $00,$85,$0A,$A9,$BC,$85,$0B,$A5
        .byte   $2A,$29,$08,$F0,$02,$E6,$0B
        ldy     #$00
        lda     ($0A),y
        sta     $00
        lda     #$00
        sta     $2006
        sta     $2006
        sta     jump_ptr
        iny
        sty     $01
LC487:  ldy     $01
        lda     ($0A),y
        sta     $09
        iny
        lda     ($0A),y
        sta     $02
        iny
        lda     ($0A),y
        iny
        sty     $01
        jsr     bank_switch
LC49B:  ldy     #$00
LC49D:  lda     (jump_ptr),y
        sta     $2007
        iny
        bne     LC49D
        inc     $09
        dec     $02
        bne     LC49B
        lda     $2A
        and     #$07
        jsr     bank_switch
        dec     $00
        bne     LC487
        inc     $0B
        inc     $0B
        ldy     #$61
LC4BC:  lda     ($0A),y
        sta     $0354,y
        dey
        bpl     LC4BC
        jsr     upload_palette
        lda     #$0E
        jsr     bank_switch
        rts

        .byte   $A5,$2A,$29,$07,$20,$00,$C0,$A4
        .byte   $B0,$B9,$06,$BB,$85,$20,$8D,$40
        .byte   $04,$B9,$0C,$BB,$85,$48,$85,$49
        .byte   $B9,$12,$BB,$85,$4C,$85,$4D,$B9
        .byte   $18,$BB,$85,$17,$B9,$1E,$BB,$85
        .byte   $16,$B9,$24,$BB,$85,$19,$B9,$2A
        .byte   $BB,$85,$18,$B9,$30,$BB,$85,$38
        .byte   $B9,$36,$BB,$85,$14,$B9,$3C,$BB
        .byte   $85,$15,$A6,$38,$20,$64,$CB,$98
        .byte   $18,$69,$0B,$A8,$A2,$0C
LC51B:  lda     $B460,y
        pha
        dey
        dex
        bne     LC51B
        lda     #$0A
        sta     $2006
        lda     #$00
        sta     $2006
        sta     jump_ptr
        lda     #$06
        sta     $00
LC533:  pla
        sta     $09
        pla
        jsr     bank_switch
        ldy     #$00
LC53C:  lda     (jump_ptr),y
        sta     $2007
        iny
        bne     LC53C
        dec     $00
        bne     LC533
        lda     #$0E
        jsr     bank_switch
        lda     $B0
        cmp     #$02
        bne     LC556
        jsr     L9115
LC556:  rts

        .byte   $A9,$0D,$20,$00,$C0,$20,$09,$80
        .byte   $A9,$0E,$20,$00,$C0,$60,$A9,$0D
        .byte   $20,$00,$C0,$20,$00,$80,$A9,$0E
        .byte   $20,$00,$C0,$60,$A2,$0F
LC575:  lda     $0420,x
        bmi     LC5A8
        dex
        cpx     #$01
        bne     LC575
        lda     $47
        beq     LC586
        jsr     LC07F
LC586:  lda     $03B6
        pha
        lda     $03B7
        pha
        lda     #$32
        jsr     bank_switch_enqueue
        lda     #$0D
        jsr     bank_switch
        jsr     banked_entry_alt
        pla
        sta     $03B7
        pla
        sta     $03B6
        lda     #$0E
        jsr     bank_switch
LC5A8:  rts

LC5A9:  lda     $B1
        beq     LC5F0
        lda     #$0B
        jsr     bank_switch
        jsr     banked_entry_alt
        lda     #$0E
        jsr     bank_switch
        lda     $05AA
        beq     LC5F0
        lda     $2A
        cmp     #$0C
        bne     LC5ED
        lda     $BC
        cmp     #$FF
        beq     LC5ED
        ldx     #$0F
LC5CD:  lsr     $0430,x
        dex
        bpl     LC5CD
        jsr     LC289
        lda     #$00
        sta     $2B
        lda     #$7D
        ldx     #$0F
        jsr     LF160
        lda     #$20
        sta     $047F
        lda     #$AB
        sta     $04BF
        bne     LC5F0
LC5ED:  jmp     LC1F0

LC5F0:  rts

        .byte   $48,$AD,$A7,$05,$85,$09,$AD,$A9
        .byte   $05,$85,$08
        pla
        jsr     LC70C
        clc
        lda     $03B7
        adc     #$20
        sta     $03B7
        lda     $03B6
        adc     #$00
        sta     $03B6
        clc
        lda     $05A9
        adc     #$20
        sta     $05A9
        lda     $05A7
        adc     #$00
        sta     $05A7
        lda     #$0B
        jsr     bank_switch
        rts

        .byte   $20,$00,$C0,$A9,$00,$85,$08,$A2
        .byte   $04
LC631:  lda     (jump_ptr),y
        sta     $2007
        iny
        bne     LC631
        inc     $09
        dex
        bne     LC631
        lda     #$0D
        jsr     bank_switch
        rts

        .byte   $85,$00,$AA,$BD,$89,$C6,$85,$01
        .byte   $BD,$90,$C6,$85,$02,$A9,$00,$85
        .byte   $08,$8D,$06,$20,$8D,$06,$20
LC65B:  .byte   $A6
LC65C:  .byte   $02
        lda     LC6BE,x
        sta     $09
        lda     LC6E5,x
        sta     $03
        lda     LC697,x
        jsr     bank_switch
        ldy     #$00
LC66F:  lda     (jump_ptr),y
        sta     $2007
        iny
        bne     LC66F
        inc     $09
        dec     $03
        bne     LC66F
        inc     $02
        dec     $01
        bne     LC65B
        lda     #$0D
        jsr     bank_switch
        rts

        .byte   $02,$02,$03,$06,$0E,$04,$08,$00
        .byte   $02,$04,$07,$0D,$1B,$1F
LC697:  .byte   $05,$08,$06,$09,$06,$00,$09,$00
        .byte   $09,$08,$09,$08,$09,$03,$03,$04
        .byte   $04,$06,$04,$05,$05,$05,$07,$07
        .byte   $02,$08,$07,$05,$08,$09,$08,$00
        .byte   $06,$07,$07,$07,$02,$02,$09
LC6BE:  .byte   $90,$88,$90,$90
        bcc     LC65C
        ldy     #$98
        ldy     $AC80
        sty     $9F
        sta     $9D9C,y
        .byte   $9B,$B2,$97,$93,$96,$9C,$9D,$9F
        .byte   $95,$A4,$B2,$90,$88,$9F,$8C,$98
        .byte   $B2,$9D,$9F,$AE,$96,$94,$AC
LC6E5:  .byte   $10,$10,$10,$10,$08,$08,$10,$0E
        .byte   $02,$04,$02,$04,$06,$02,$01,$01
        .byte   $01,$02,$01,$01,$02,$01
        ora     ($01,x)
        .byte   $02,$0C,$02,$10,$03,$01,$0C,$08
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        .byte   $02
LC70C:  jsr     bank_switch
        ldy     #$1F
LC711:  lda     (jump_ptr),y
        sta     $03B8,y
        dey
        bpl     LC711
        lda     #$20
        sta     $47
        lda     #$0D
        jsr     bank_switch
        rts

        .byte   $A9,$01,$20,$00,$C0,$A2,$1F
LC72A:  lda     $9CD0,x
        sta     $03B8,x
        dex
        bpl     LC72A
        lda     #$08
        sta     $03B6
        lda     #$00
        sta     $03B7
        lda     #$20
        sta     $47
        lda     #$0D
        jsr     bank_switch
        rts

        .byte   $A9,$09,$20,$00,$C0,$A0,$1F
LC74E:  lda     ($FE),y
        sta     $03B8,y
        dey
        bpl     LC74E
        lda     #$20
        sta     $47
        lda     #$0D
        jsr     bank_switch
        rts

        .byte   $A5,$FD,$85,$09,$A9,$00,$46,$09
        .byte   $6A,$46,$09,$6A,$46,$09,$6A,$8D
        .byte   $B7,$03,$85,$08,$A5,$FD,$C9,$08
        .byte   $90,$05,$A5,$09,$4C,$83,$C7
        lda     $09
        adc     #$09
        sta     $03B6
        clc
        tya
        adc     $09
        sta     $09
        txa
        jsr     bank_switch
        ldy     #$1F
LC792:  lda     (jump_ptr),y
        sta     $03B8,y
        dey
        bpl     LC792
        lda     #$20
        sta     $47
        lda     #$0D
        jsr     bank_switch
        rts

        .byte   $A5,$2A,$29,$07,$20,$00,$C0,$B9
        .byte   $00,$B4,$A8,$A9,$0E,$20,$00,$C0
        .byte   $60,$A9,$C0,$8D,$20,$04,$A9,$80
        .byte   $8D,$60,$04,$A9,$14,$8D,$A0,$04
        .byte   $A9,$1A,$8D,$00,$04
LC7C9:  lda     $2A
        and     #$07
        jsr     bank_switch
        lda     #$00
        sta     $0680
        sta     $06A0
        clc
        lda     $04A0
        adc     #$10
        sta     $04A0
        ldx     $B0
        cmp     $BB00,x
        beq     LC7F1
        jsr     LCC77
        jsr     LC07F
        jmp     LC7C9

LC7F1:  lda     #$30
        jsr     bank_switch_enqueue
        lda     #$00
        sta     $2C
        sta     $3E
        sta     $3F
        lda     #$40
        sta     $42
        lda     #$0E
        jsr     bank_switch
        rts

        lda     $2A
        sta     $B3
        lda     #$0B
        jsr     bank_switch
        jsr     banked_entry
        lda     #$0E
        jsr     bank_switch
LC819:  lda     #$00
        sta     $23
        sta     $27
        jsr     L84EE
        jsr     LDCD0
        jsr     LD658
        jsr     LC5A9
        jsr     L925B
        jsr     LCC77
        lda     $FB
        beq     LC844
        inc     $FC
        cmp     $FC
        beq     LC83D
        bcs     LC844
LC83D:  jsr     LC0D7
        lda     #$00
        sta     $FC
LC844:  jsr     LC07F
        lda     $B1
        cmp     #$02
        bcc     LC819
        rts

LC84E:  lda     #$00
        sta     $03
        sta     $04
        lda     $01
        ora     $02
        bne     LC85D
        sta     $03
        rts

LC85D:  ldy     #$08
LC85F:  asl     $03
        rol     $01
        rol     $04
        sec
        lda     $04
        sbc     $02
        bcc     LC870
        sta     $04
        inc     $03
LC870:  dey
        bne     LC85F
        rts

LC874:  lda     #$00
        sta     $11
        sta     $10
        lda     $0B
        ora     $0A
        ora     $0D
        ora     $0C
        bne     LC889
        sta     $0F
        sta     $0E
        rts

LC889:  ldy     #$10
LC88B:  asl     $10
        rol     $0A
        rol     $0B
        rol     $11
        sec
        lda     $0B
        sbc     $0C
        tax
        lda     $11
        sbc     $0D
        bcc     LC8A5
        stx     $09
        sta     $11
        inc     $10
LC8A5:  dey
        bne     LC88B
        lda     $0A
        sta     $0F
        lda     $10
        sta     $0E
        rts

        .byte   $A6,$1B,$A0,$20,$A5,$09,$29,$01
        .byte   $F0,$02,$A0,$24
        sty     $0B
        lda     jump_ptr
        lsr     a
        lsr     a
        pha
        lsr     a
        and     #$03
        ora     $0B
        sta     $0300,x
        pla
        pha
        ror     a
        and     #$FC
        sta     $0304,x
        lda     $0B
        ora     #$03
        sta     $0308,x
        pla
        sta     $0A
        lsr     a
        lsr     a
        lsr     a
        asl     $0A
        asl     $0A
        asl     $0A
        ora     $0A
        ora     #$C0
        sta     $030C,x
        rts

        .byte   $A6,$51,$A0,$08,$A5,$09,$29,$01
        .byte   $F0,$02,$A0,$09
        sty     $0B
        lda     $0A
        and     #$F8
        asl     a
        rol     $0B
        asl     a
        rol     $0B
        sta     $03BC,x
        lda     jump_ptr
        lsr     a
        lsr     a
        lsr     a
        ora     $03BC,x
        sta     $03BC,x
        lda     $0B
        sta     $03B6,x
        rts

        .byte   $48,$A5,$08,$48,$A6,$51,$A5,$0A
        .byte   $29,$E0,$4A,$4A,$85,$0B,$06,$08
        rol     a
        asl     jump_ptr
        rol     a
        asl     jump_ptr
        rol     a
        ora     $0B
        ora     #$C0
        sta     $03C8,x
        ldy     #$23
        lda     $09
        and     #$01
        beq     LC943
        ldy     #$27
LC943:  tya
        sta     $03C2,x
        ldy     #$00
        pla
        and     #$10
        beq     LC94F
        iny
LC94F:  lda     $0A
        and     #$10
        beq     LC957
        iny
        iny
LC957:  pla
        and     LC967,y
        sta     $03CE,x
        lda     LC967,y
        eor     #$FF
        sta     $03D4,x
        rts

LC967:  .byte   $03,$0C,$30,$C0
        lda     $2A
        and     #$07
        jsr     bank_switch
        lda     #$20
        sta     $0B
        ldy     #$00
        lda     (jump_ptr),y
        tax
        tay
        lda     $8400,y
        pha
        txa
        asl     a
        rol     $0B
        asl     a
        rol     $0B
        sta     $0A
        lda     $1B
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        pha
        ldy     #$00
LC993:  clc
        pla
        pha
        adc     LCA07,y
        tax
        lda     ($0A),y
        asl     a
        asl     a
        clc
        sta     $0310,x
        adc     #$01
        sta     $0314,x
        adc     #$01
        sta     $0311,x
        adc     #$01
        sta     $0315,x
        iny
        cpy     #$04
        bne     LC993
        pla
        ldy     #$20
        lda     jump_ptr
        and     #$40
        beq     LC9C1
        ldy     #$24
LC9C1:  sty     $0D
        lda     $1A
        sta     $0C
        lsr     a
        ror     $0C
        lda     $0C
        pha
        and     #$03
        ora     $0D
        sta     $0D
        pla
        and     #$FC
        ldx     $1B
        sta     $0304,x
        lda     $0D
        sta     $0300,x
        lda     $0D
        ora     #$03
        sta     $0308,x
        lda     $1A
        sta     $0C
        lsr     a
        lsr     a
        lsr     a
        asl     $0C
        asl     $0C
        asl     $0C
        ora     #$C0
        ora     $0C
        sta     $030C,x
        pla
        sta     $0350,x
        inc     $1B
        lda     #$0E
        jsr     bank_switch
        rts

LCA07:  .byte   $00,$08,$02,$0A,$A5,$29,$48,$20
        .byte   $6B,$C9,$68,$20,$00,$C0,$60,$A5
        .byte   $2A,$29,$07,$20,$00,$C0,$A5,$39
        .byte   $4A,$4A,$4A,$4A,$8D,$00,$03,$A5
        .byte   $39,$0A,$0A,$0A,$48,$29,$18,$8D
        .byte   $01,$03,$68,$0A,$29,$C0,$0D,$01
        .byte   $03,$8D,$01,$03,$A5,$39,$29,$F8
        .byte   $09,$C0,$8D,$13,$03,$A5,$39,$29
        .byte   $03,$0A,$0D,$13,$03,$8D,$13,$03
        .byte   $A2,$20,$A5,$20,$29,$01,$F0,$02
        .byte   $A2,$24
        txa
        ora     $0300
        sta     $0300
        txa
        ora     #$03
        sta     $0312
        lda     #$00
        sta     $00
        lda     $39
        and     #$3B
        lsr     a
        ror     $00
        lsr     a
        ror     $00
        lsr     a
        ror     $00
        lsr     $00
        ora     $00
        sta     $00
        lda     $0440
        ldx     #$00
        stx     jump_ptr
        lsr     a
        ror     jump_ptr
        lsr     a
        ror     jump_ptr
        clc
        adc     #$85
        sta     $09
        stx     $01
LCA91:  ldy     $00
        lda     (jump_ptr),y
        sta     $03
        sta     $0A
        lda     #$20
        asl     $0A
        rol     a
        asl     $0A
        rol     a
        sta     $0B
        ldy     #$00
        lda     $39
        and     #$04
        beq     LCAAC
        iny
LCAAC:  lda     #$02
        sta     $02
LCAB0:  lda     ($0A),y
        asl     a
        asl     a
        clc
        sta     $0302,x
        adc     #$01
        sta     $030A,x
        adc     #$01
        sta     $0303,x
        adc     #$01
        sta     $030B,x
        inx
        inx
        iny
        iny
        dec     $02
        bne     LCAB0
        lda     $39
        ldy     #$0F
        and     #$04
        beq     LCAD9
        ldy     #$F0
LCAD9:  sty     $0314
        ldy     $03
        lda     $8400,y
        and     $0314
        ldy     $01
        sta     $0315,y
        lda     $00
        ora     #$08
        sta     $00
        inc     $01
        lda     $01
        cmp     #$02
        beq     LCAFA
        jmp     LCA91

LCAFA:  lda     #$80
        sta     $1B
        lda     #$FF
        eor     $0314
        sta     $0314
        lda     #$0E
        jsr     bank_switch
        rts

        .byte   $A5,$FD,$C9,$60,$90,$01,$60
        lda     $29
        pha
        lda     $FD
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        pha
        lsr     a
        clc
        adc     #$0A
        sta     $03B6
        lda     $FD
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $03B7
        sta     jump_ptr
        lda     $2A
        and     #$07
        jsr     bank_switch
        ldx     $FE
        jsr     LCB64
        clc
        pla
        adc     $B42C,x
        tax
        lda     $B460,x
        sta     $09
        lda     $B461,x
        jsr     bank_switch
        ldy     #$1F
LCB4F:  lda     (jump_ptr),y
        sta     $03B8,y
        dey
        bpl     LCB4F
        lda     #$20
        sta     $47
        inc     $FD
        inc     $FD
        pla
        jsr     bank_switch
        rts

LCB64:  ldy     $B42C,x
        lda     $B46C,y
        sta     $036F
        lda     $B46D,y
        sta     $0370
        lda     $B46E,y
        sta     $0371
        lda     $B46F,y
        sta     $0373
        lda     $B470,y
        sta     $0374
        lda     $B471,y
        sta     $0375
        rts

        .byte   $A2,$0F,$A0,$00
LCB90:  lda     $0430,x
        bpl     LCB9C
        and     #$10
        beq     LCB9C
        stx     $56,y
        iny
LCB9C:  dex
        bpl     LCB90
        sty     $55
        rts

LCBA2:  ldy     $55
LCBA4:  dey
        bmi     LCBC3
        ldx     $56,y
        lda     jump_ptr
        and     $0610,x
        cmp     $0650,x
        bne     LCBA4
        lda     $0A
        and     $0630,x
        cmp     $0670,x
        bne     LCBA4
        lda     $04F0,x
        sta     $00
        rts

LCBC3:  lda     $2A
        and     #$07
        jsr     bank_switch
        lda     #$00
        sta     $00
        lda     $0B
        beq     LCBDB
        bmi     LCBD7
        jmp     LCC41

LCBD7:  lda     #$00
        sta     $0A
LCBDB:  lda     jump_ptr
        lsr     a
        lsr     a
        and     #$38
        sta     $00
        lda     $0A
        asl     a
        rol     a
        rol     a
        rol     a
        and     #$07
        ora     $00
        sta     $00
        lda     #$00
        sta     $0C
        lda     $09
        lsr     a
        ror     $0C
        lsr     a
        ror     $0C
        clc
        adc     #$85
        sta     $0D
        ldy     $00
        lda     ($0C),y
        sta     $0C
        lda     #$20
        asl     $0C
        rol     a
        asl     $0C
        rol     a
        sta     $0D
        ldy     #$00
        lda     jump_ptr
        and     #$10
        beq     LCC1A
        iny
        iny
LCC1A:  lda     $0A
        and     #$10
        beq     LCC21
        iny
LCC21:  lda     ($0C),y
        sta     $00
        asl     $00
        rol     a
        asl     $00
        rol     a
        and     #$03
        sta     $00
        lsr     a
        beq     LCC41
        dec     $00
        dec     $00
        lda     $2A
        asl     a
        adc     $00
        tax
        lda     LCC47,x
        sta     $00
LCC41:  lda     #$0E
        jsr     bank_switch
        rts

LCC47:  .byte   $02,$03,$02,$03,$02,$00,$04,$03
        .byte   $00,$03,$02,$07,$05,$06,$02,$03
        .byte   $02,$00,$02,$03,$04,$03,$02,$03
        .byte   $00,$00,$00,$00,$20,$A2,$CB,$A9
        .byte   $0B,$20,$00,$C0,$60
LCC6C:  lda     #$F8
        ldx     #$00
LCC70:  sta     $0200,x
        inx
        bne     LCC70
        rts

LCC77:  lda     #$0A
        jsr     bank_switch
        jsr     LCC6C
        lda     #$00
        sta     $06
        sta     $0D
        sta     $0C
        lda     $AA
        beq     LCC8E
        jmp     LCD05

LCC8E:  lda     $1C
        and     #$01
        bne     LCCC0
        lda     #$FF
        sta     $0C
        lda     #$00
        sta     $2B
LCC9C:  jsr     LCDE7
        bcs     LCCBD
        inc     $2B
        lda     $2B
        cmp     #$10
        bne     LCC9C
LCCA9:  jsr     LCEF9
        bcs     LCCBD
        inc     $2B
        lda     $2B
        cmp     #$20
        bne     LCCA9
        lda     $06
        sta     $0C
        jsr     LCF5D
LCCBD:  jmp     LCCE5

LCCC0:  jsr     LCF5D
        lda     $06
        sta     $0D
        lda     #$1F
        sta     $2B
LCCCB:  jsr     LCEF9
        bcs     LCCE5
        dec     $2B
        lda     $2B
        cmp     #$0F
        bne     LCCCB
LCCD8:  jsr     LCDE7
        bcs     LCCE5
        dec     $2B
        bpl     LCCD8
        lda     $06
        sta     $0C
LCCE5:  lda     $2A
        cmp     #$01
        bne     LCCFF
        ldx     $0D
LCCED:  cpx     $0C
        beq     LCCFF
        lda     $0202,x
        ora     #$20
        sta     $0202,x
        inx
        inx
        inx
        inx
        bne     LCCED
LCCFF:  lda     #$0E
        jsr     bank_switch
        rts

LCD05:  lda     $1C
        and     #$01
        bne     LCD54
        lda     #$FF
        sta     $0C
        lda     #$00
        sta     $2B
        lda     $AA
        and     #$04
        beq     LCD1F
        jsr     LCD97
        jmp     LCD22

LCD1F:  jsr     LCDE7
LCD22:  inc     $2B
LCD24:  lda     $AA
        and     #$02
        bne     LCD30
        jsr     LCDE7
        jmp     LCD33

LCD30:  jsr     LCD97
LCD33:  bcs     LCD51
        inc     $2B
        lda     $2B
        cmp     #$10
        bne     LCD24
LCD3D:  jsr     LCDBF
        bcs     LCD51
        inc     $2B
        lda     $2B
        cmp     #$20
        bne     LCD3D
        lda     $06
        sta     $0C
        jsr     LCF5D
LCD51:  jmp     LCCE5

LCD54:  jsr     LCF5D
        lda     $06
        sta     $0D
        lda     #$1F
        sta     $2B
LCD5F:  jsr     LCDBF
        bcs     LCD94
        dec     $2B
        lda     $2B
        cmp     #$0F
        bne     LCD5F
LCD6C:  lda     $AA
        and     #$02
        bne     LCD78
        jsr     LCDE7
        jmp     LCD7B

LCD78:  jsr     LCD97
LCD7B:  bcs     LCD94
        dec     $2B
        bne     LCD6C
        lda     $AA
        and     #$04
        beq     LCD8D
        jsr     LCD97
        jmp     LCD90

LCD8D:  jsr     LCDE7
LCD90:  lda     $06
        sta     $0C
LCD94:  jmp     LCCE5

LCD97:  ldx     $2B
        lda     $0420,x
        bmi     LCDA0
        clc
        rts

LCDA0:  ldy     $0400,x
        lda     LF900,y
        sta     jump_ptr
        lda     LFA00,y
        sta     $09
        lda     $06A0,x
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        beq     LCDBB
        jmp     LCE2F

LCDBB:  lsr     $0420,x
        rts

LCDBF:  ldx     $2B
        lda     $0420,x
        bmi     LCDC8
        clc
        rts

LCDC8:  ldy     $0400,x
        lda     LF980,y
        sta     jump_ptr
        lda     LFA80,y
        sta     $09
        lda     $06A0,x
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        beq     LCDE3
        jmp     LCF41

LCDE3:  lsr     $0420,x
        rts

LCDE7:  ldx     $2B
        lda     $0420,x
        bmi     LCDF0
        clc
        rts

LCDF0:  ldy     $0400,x
        lda     LF900,y
        sta     jump_ptr
        lda     LFA00,y
        sta     $09
        lda     $06A0,x
        pha
        inc     $0680,x
        ldy     #$01
        lda     (jump_ptr),y
        cmp     $0680,x
        bcs     LCE22
        lda     #$00
        sta     $0680,x
        inc     $06A0,x
        dey
        lda     (jump_ptr),y
        cmp     $06A0,x
        bcs     LCE22
        lda     #$00
        sta     $06A0,x
LCE22:  pla
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        bne     LCE2F
        lsr     $0420,x
        rts

LCE2F:  tay
        cpx     #$01
        bcs     LCE49
        lda     $4B
        beq     LCE43
        dec     $4B
        lda     $1C
        and     #$02
        beq     LCE43
LCE40:  jmp     LCEF5

LCE43:  lda     $F9
        bne     LCE40
        beq     LCE5B
LCE49:  bne     LCE5B
        lda     $05A8
        beq     LCE5B
        lda     $1C
        and     #$02
        bne     LCE58
        ldy     #$18
LCE58:  dec     $05A8
LCE5B:  lda     banked_entry,y
        sta     jump_ptr
        lda     $8200,y
        sta     $09
        lda     #$00
        sta     $03
LCE69:  ldy     #$00
        lda     (jump_ptr),y
        sta     $04
        iny
        lda     (jump_ptr),y
        tay
        lda     $8400,y
        sta     $0A
        lda     $8500,y
        sta     $0B
        sec
        lda     $0460,x
        sbc     $1F
        sta     $00
        lda     $0440,x
        sbc     $20
        lda     $04A0,x
        sta     $01
        lda     $0420,x
        and     #$40
        sta     $02
        lda     #$02
        sta     $07
LCE9A:  ldx     $06
        ldy     $07
        lda     (jump_ptr),y
        sta     $0201,x
        clc
        lda     ($0A),y
        adc     $01
        sta     $0200,x
        iny
        lda     $03
        beq     LCEB8
        lda     (jump_ptr),y
        and     #$F0
        ora     $03
        bne     LCEBA
LCEB8:  lda     (jump_ptr),y
LCEBA:  eor     $02
        sta     $0202,x
        lda     $02
        beq     LCECC
        lda     ($0A),y
        tay
        lda     L8600,y
        jmp     LCECE

LCECC:  lda     ($0A),y
LCECE:  clc
        bmi     LCED7
        adc     $00
        bcc     LCEE2
        bcs     LCEDB
LCED7:  adc     $00
        bcs     LCEE2
LCEDB:  lda     #$F8
        sta     $0200,x
        bne     LCEED
LCEE2:  sta     $0203,x
        clc
        txa
        adc     #$04
        sta     $06
        beq     LCEF7
LCEED:  inc     $07
        inc     $07
        dec     $04
        bne     LCE9A
LCEF5:  clc
        rts

LCEF7:  sec
        rts

LCEF9:  ldx     $2B
        lda     $0420,x
        bmi     LCF02
        clc
        rts

LCF02:  ldy     $0400,x
        lda     LF980,y
        sta     jump_ptr
        lda     LFA80,y
        sta     $09
        lda     $06A0,x
        pha
        inc     $0680,x
        ldy     #$01
        lda     (jump_ptr),y
        cmp     $0680,x
        bcs     LCF34
        lda     #$00
        sta     $0680,x
        inc     $06A0,x
        dey
        lda     (jump_ptr),y
        cmp     $06A0,x
        bcs     LCF34
        lda     #$00
        sta     $06A0,x
LCF34:  pla
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        bne     LCF41
        lsr     $0420,x
        rts

LCF41:  tay
        lda     $0420,x
        and     #$20
        bne     LCF5B
        lda     $8100,y
        sta     jump_ptr
        lda     $8300,y
        sta     $09
        lda     $0100,x
        sta     $03
        jmp     LCE69

LCF5B:  clc
        rts

LCF5D:  lda     $06C0
        sta     $00
        ldx     $06
        lda     #$01
        sta     $02
        lda     #$18
        sta     $01
        jsr     LCFA8
        bcs     LCFA7
        ldy     $A9
        beq     LCF87
        lda     $9B,y
        sta     $00
        lda     #$00
        sta     $02
        lda     #$10
        sta     $01
        jsr     LCFA8
        bcs     LCFA7
LCF87:  lda     $B1
        beq     LCFA7
        lda     $06C1
        sta     $00
        lda     #$03
        ldy     $B3
        cpy     #$08
        beq     LCF9C
        cpy     #$0D
        bne     LCF9E
LCF9C:  lda     #$01
LCF9E:  sta     $02
        lda     #$28
        sta     $01
        jsr     LCFA8
LCFA7:  rts

LCFA8:  ldy     #$06
LCFAA:  lda     LCFE5,y
        sta     $0200,x
        sec
        lda     $00
        sbc     #$04
        bcs     LCFC5
        ldx     $00
        lda     #$00
        sta     $00
        lda     LCFEC,x
        ldx     $06
        jmp     LCFC9

LCFC5:  sta     $00
        lda     #$87
LCFC9:  sta     $0201,x
        lda     $02
        sta     $0202,x
        lda     $01
        sta     $0203,x
        inx
        inx
        inx
        inx
        stx     $06
        beq     LCFE3
        dey
        bpl     LCFAA
        clc
        rts

LCFE3:  sec
        rts

LCFE5:  .byte   $18,$20,$28,$30,$38,$40,$48
LCFEC:  .byte   $8B,$8A,$89,$88

; =============================================================================
; NMI Handler (VBLANK)
; Called every frame during vertical blanking interval.
; Handles: OAM DMA, palette upload, PPU buffer transfer, scroll setup.
; =============================================================================
nmi_handler:  pha                       ; NMI handler — called every VBLANK
        php
        txa
        pha
        tya
        pha
        lda     $1D
        beq     nmi_do_vblank
        jmp     nmi_tail

nmi_do_vblank:                          ; Main VBLANK processing path
        lda     $F7                     ; PPUCTRL shadow
        and     #$7C                    ; Disable NMI, clear nametable select
        sta     $F7
        sta     $2000                   ; Apply to PPUCTRL
        lda     $F8                     ; PPUMASK shadow
        and     #$E7                    ; Disable sprite/bg rendering
        sta     $F8
        sta     $2001                   ; Apply to PPUMASK (rendering off)
        lda     $2002                   ; Read PPUSTATUS (reset addr latch)
        lda     #$00
        sta     $2003                   ; OAMADDR = 0
        lda     #$02
        sta     $4014                   ; OAM DMA from $0200
        lda     $1B                     ; PPU buffer transfer count
        beq     nmi_update_palette      ; Skip if no buffer data
        jsr     ppu_buffer_transfer
nmi_update_palette:  jsr     upload_palette
        lda     $47
        beq     nmi_check_scroll_update
        jsr     ppu_scroll_column_update
nmi_check_scroll_update:  lda     $51
        beq     nmi_check_ppu_update
        jsr     ppu_attribute_update
nmi_check_ppu_update:                   ; Set scroll position
        lda     $2002                   ; Reset PPUADDR latch
        lda     #$00
        sta     $01                     ; Scroll X high byte (nametable bit)
        lda     $1F                     ; Scroll X position
        sta     $00
        lda     $B8                     ; Camera X offset (shake/split)
        beq     nmi_set_scroll_x        ; Skip if no offset
        sec
        lda     $00
        sbc     $B8
        sta     $00
        lda     #$00
        sbc     $B9
        and     #$01
        sta     $01
nmi_set_scroll_x:
        lda     $00
        sta     $2005                   ; PPUSCROLL X
        lda     $22                     ; Scroll Y position
        sta     $00
        lda     $B6                     ; Camera Y offset (shake/split)
        beq     nmi_set_scroll_y
        sec
        lda     $00
        sbc     $B6
        sta     $00
nmi_set_scroll_y:
        lda     $00
        sta     $2005                   ; PPUSCROLL Y
        lda     $F8                     ; PPUMASK shadow
        ora     #$1E                    ; Enable sprites + background
        sta     $F8
        sta     $2001                   ; Re-enable rendering
        lda     $F7                     ; PPUCTRL shadow
        ora     #$80                    ; Re-enable NMI
        sta     $F7
        lda     $20                     ; Base nametable select
        eor     $01                     ; XOR with scroll high bit
        and     #$01                    ; Keep bit 0 only
        ora     $F7
        ora     $AE                     ; OR with sprite size flag
        sta     $F7
        sta     $2000                   ; Write final PPUCTRL
        sta     $1D                     ; Set "VBLANK done" flag (nonzero)
        inc     $1C                     ; Increment frame counter
nmi_tail:  lda     $68                  ; NMI exit path (also handles interrupted bank switches)
        beq     nmi_restore_bank
        inc     $67
        bne     nmi_rng_and_exit
nmi_restore_bank:  lda     #$0C         ; Restore bank that was active when NMI fired
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        jsr     banked_entry
nmi_process_queue:  ldx     $66
        beq     nmi_queue_done
        lda     $057F,x
        cmp     #$FD
        bne     nmi_queue_call
        ldy     #$A0
nmi_queue_call:  jsr     banked_entry_alt
        dec     $66
        bne     nmi_process_queue
nmi_queue_done:  lda     $29
        jsr     bank_switch
nmi_rng_and_exit:                       ; Update RNG seed and return from interrupt
        lda     $0480                   ; Entropy source
        eor     $4A                     ; XOR with current RNG state
        adc     $1C                     ; Add frame counter
        lsr     a
        sta     $4A                     ; Store new RNG value
        pla                             ; Restore Y
        tay
        pla                             ; Restore X
        tax
        plp                             ; Restore flags
        pla                             ; Restore A
        rti


; =============================================================================
; Controller Input
; =============================================================================
read_controllers:  ldx     #$01         ; Read both controllers into $23 (P1) and $24 (P2)
        stx     $4016
        dex
        stx     $4016
        inx
read_controller_loop:  ldy     #$08     ; Read 8 bits from controller X
read_controller_bits:  lda     $4016,x  ; Shift in one button bit
        sta     $27
        lsr     a
        ora     $27
        lsr     a
        ror     $23,x
        dey
        bne     read_controller_bits
        dex
        bpl     read_controller_loop
        rts


; =============================================================================
; PPU Update Routines
; =============================================================================
upload_palette:  ldy     #$3F           ; Upload 32-byte palette from $0356 to PPU $3F00
        sty     $2006
        ldx     #$00
        stx     $2006
upload_palette_loop:  lda     $0356,x   ; Copy palette bytes to PPUDATA
        sta     $2007
        inx
        cpx     #$20
        bne     upload_palette_loop
        sty     $2006
        lda     #$00
        sta     $2006
        sta     $2006
        sta     $2006
        sta     $3A
        rts

ppu_buffer_transfer:  bpl     ppu_buffer_transfer_main; Transfer PPU update buffer to VRAM
        jmp     ppu_buffer_transfer_alt

ppu_buffer_transfer_main:  ldy     #$00
ppu_buffer_entry_loop:  sty     $00
        tya
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        lda     #$04
        sta     $01
        lda     $0300,y
        sta     $0B
        lda     $0304,y
        sta     $0A
        cmp     #$80
        bcc     ppu_buffer_write_entry
        lda     $0B
        and     #$03
        cmp     #$03
        bne     ppu_buffer_write_entry
        lda     #$02
        sta     $01
ppu_buffer_write_entry:  lda     $0308,y
        sta     $2006
        lda     $030C,y
        sta     $2006
        lda     $0350,y
        sta     $2007
ppu_buffer_write_row:  lda     $0B
        sta     $2006
        clc
        lda     $0A
        sta     $2006
        adc     #$20
        sta     $0A
        ldy     #$04
ppu_buffer_write_bytes:  lda     $0310,x
        sta     $2007
        inx
        dey
        bne     ppu_buffer_write_bytes
        dec     $01
        bne     ppu_buffer_write_row
        ldy     $00
        iny
        dec     $1B
        bne     ppu_buffer_entry_loop
        rts

ppu_buffer_transfer_alt:  ldx     #$00
        stx     $1B
LD185:  lda     $0300
        sta     $2006
        lda     $0301
        sta     $2006
LD191:  lda     $0302,x
        sta     $2007
        inx
        txa
        and     #$07
        bne     LD191
        clc
        lda     $0301
        adc     #$20
        sta     $0301
        lda     $0312
        sta     $2006
        lda     $0313
        sta     $2006
        lda     $2007
        lda     $2007
        ldy     $1B
        and     $0314
        ora     $0315,y
        pha
        lda     $0312
        sta     $2006
        lda     $0313
        sta     $2006
        pla
        sta     $2007
        inc     $1B
        inc     $0313
        cpx     #$10
        bne     LD185
        lda     #$00
        sta     $1B
        rts

ppu_scroll_column_update:  lda     $03B6; Update nametable column during scroll
        sta     $2006
        lda     $03B7
        sta     $2006
        ldx     #$00
LD1ED:  lda     $03B8,x
        sta     $2007
        inx
        dec     $47
        bne     LD1ED
        rts

ppu_attribute_update:  lda     $F7      ; Update attribute table during scroll
        ora     #$04
        sta     $2000
        lda     $54
        bne     LD269
        ldy     $51
        bmi     LD22D
LD208:  lda     $03B5,y
        sta     $2006
        lda     $03BB,y
        sta     $2006
        lda     $03C1,y
        sta     $2007
        clc
        adc     #$01
        sta     $2007
        dey
        bne     LD208
LD223:  sty     $51
        lda     $F7
        and     #$FB
        sta     $2000
        rts

LD22D:  tya
        and     #$7F
        tay
LD231:  lda     #$02
        sta     $00
        lda     #$E4
        sta     $01
LD239:  lda     $03B5,y
        sta     $2006
        lda     $03BB,y
        sta     $2006
        lda     #$02
        sta     $02
LD249:  lda     $01
        sta     $2007
        inc     $01
        dec     $02
        bne     LD249
        dec     $00
        beq     LD264
        clc
        lda     $03BB,y
        adc     #$01
        sta     $03BB,y
        jmp     LD239

LD264:  dey
        bne     LD231
        beq     LD223
LD269:  bpl     LD283
        lda     $03B6
        sta     $2006
        ldx     $03BC
        dex
        dex
        stx     $2006
        lda     $2007
        lda     $2007
        tax
        jmp     LD285

LD283:  ldx     #$20
LD285:  ldy     #$02
LD287:  lda     $03B6
        sta     $2006
        lda     $03BC
        sta     $2006
        stx     $2007
        inx
        stx     $2007
        inx
        inc     $03BC
        dey
        bne     LD287
        lda     $03C2
        sta     $2006
        lda     $03C8
        sta     $2006
        lda     $54
        bpl     LD2CC
        lda     $2007
        lda     $2007
        sta     $00
        lda     $03D4
        eor     #$FF
        lsr     a
        lsr     a
        and     $00
        asl     a
        asl     a
        sta     $03CE
        lda     $00
        jmp     LD2D2

LD2CC:  lda     $2007
        lda     $2007
LD2D2:  and     $03D4
        ora     $03CE
        tax
        lda     $03C2
        sta     $2006
        lda     $03C8
        sta     $2006
        stx     $2007
        sty     $54
        jmp     LD223

        .byte   $A5,$A9,$0A,$0A,$AA,$E8,$A0,$01
LD2F5:  lda     LD302,x
        sta     $0366,y
        iny
        inx
        cpy     #$04
        bne     LD2F5
        rts

LD302:  .byte   $0F,$0F,$2C,$11,$0F,$0F,$28,$15
        .byte   $0F,$0F,$30,$11,$0F,$0F,$30,$19
        .byte   $0F,$0F,$30,$00,$0F,$0F,$34,$25
        .byte   $0F,$0F,$34,$14,$0F,$0F,$37,$18
        .byte   $0F,$0F,$30,$26,$0F,$0F,$30,$16
        .byte   $0F,$0F,$30,$16,$0F,$0F,$30,$16
LD332:  lda     #$26
        jsr     bank_switch_enqueue
        lda     #$00
        sta     $3D
        sta     $36
        lda     #$02
        sta     $2C
        jsr     LD3A8
        lda     #$01
        sta     $06A0
        lda     #$6F
        sta     $4B
        lda     #$01
        sta     $0640
        lda     #$40
        sta     $0660
        lda     #$00
        sta     $0600
        lda     #$90
        sta     $0620
        lsr     $042F
        lda     #$00
        sta     $AA
        ldx     #$0E
LD36A:  lda     $0420,x
        bpl     LD375
        dex
        cpx     #$01
        bne     LD36A
        rts

LD375:  lda     #$80
        sta     $0420,x
        lda     #$24
        sta     $0400,x
        lda     $0440
        sta     $0440,x
        lda     $0460
        sta     $0460,x
        lda     $04A0
        sta     $04A0,x
        lda     #$08
        sta     $0660,x
        lda     #$00
        sta     $0640,x
        sta     $0620,x
        sta     $0600,x
        sta     $0680,x
        sta     $06A0,x
        rts

LD3A8:  ldx     $2C
        clc
        lda     LD3D4,x
        adc     $3D
        cmp     $0400
        beq     LD3BD
        ldx     #$00
        stx     $06A0
        stx     $0680
LD3BD:  sta     $0400
        lda     $36
        beq     LD3C7
        dec     $36
        rts

LD3C7:  lda     #$00
        sta     $3D
        ldx     $2C
        lda     LD3D4,x
        sta     $0400
        rts

LD3D4:  .byte   $1A,$19,$18,$00,$04,$08,$0C,$10
        .byte   $14,$1B,$1F,$26
LD3E0:  lda     LD44F,y
        sta     $0400,x
        lda     $0420
        and     #$40
        php
        ora     LD461,y
        sta     $0420,x
        plp
        bne     LD40A
        sec
        lda     $0460
        sbc     LD473,y
        sta     $0460,x
        lda     $0440
        sbc     #$00
        sta     $0440,x
        jmp     LD41C

LD40A:  clc
        lda     $0460
        adc     LD473,y
        sta     $0460,x
        lda     $0440
        adc     #$00
        sta     $0440,x
LD41C:  lda     $04A0
        sta     $04A0,x
        lda     LD485,y
        sta     $0620,x
        lda     LD497,y
        sta     $0600,x
        lda     LD4A9,y
        sta     $0660,x
        lda     LD4BB,y
        sta     $0640,x
        lda     LD4CD,y
        sta     $0590,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        sta     $04E0,x
        sta     $06C0,x
        rts

LD44F:  .byte   $23,$30,$31,$32,$33,$34,$35,$36
        .byte   $37,$38,$39,$3A,$2F,$3E,$3F,$74
        .byte   $79,$7C
LD461:  .byte   $81,$83,$83,$82,$87,$83,$83,$81
        .byte   $82,$82,$82,$86,$81,$82,$80,$80
        .byte   $80,$80
LD473:  .byte   $10,$00
        bpl     LD477
LD477:  bpl     LD489
        bpl     LD47B
LD47B:  brk
        .byte   $20,$20,$00,$00,$00,$00,$00,$00
        .byte   $00
LD485:  .byte   $00,$00,$00,$00
LD489:  .byte   $00,$71,$00,$00,$0F,$00,$00,$27
        .byte   $00,$00,$00,$00,$00,$00
LD497:  .byte   $04,$00,$00,$00,$01,$04,$04,$00
        .byte   $00,$00,$00,$01,$00,$00,$00,$00
        .byte   $00,$00
LD4A9:  .byte   $00,$00,$40,$00,$00,$AA,$00,$00
        .byte   $00,$41,$00,$76,$00,$00,$00,$C0
        .byte   $00,$00
LD4BB:  .byte   $00,$00,$00,$00,$02,$02,$00,$00
        .byte   $00,$00,$00,$03,$00,$00,$00,$FE
        .byte   $00,$00
LD4CD:  .byte   $01,$01,$02,$04,$02,$01,$02,$02
        .byte   $00,$00,$00,$00,$02,$00,$00,$00
        .byte   $00,$00
LD4DF:  .byte   $00,$20,$40,$60,$80
LD4E4:  .byte   $0E,$12,$12,$12,$0A,$16,$2E,$0E
        .byte   $12,$16,$09,$2E,$0A,$16,$0E,$0C
        .byte   $0A,$1E,$1E,$26,$46,$02,$06,$06
        .byte   $06,$06,$06,$06,$06,$06,$06,$06
        .byte   $0C,$10,$10,$10,$08,$14,$2C,$0C
        .byte   $10,$14,$04,$2C,$08,$14,$0C,$0A
        .byte   $08,$1C,$1C
        bit     $44
        .byte   $02,$04,$04,$04,$04,$04,$04,$04
        .byte   $04,$04,$04,$10,$14,$14,$14,$0C
        .byte   $18,$30,$10,$14,$18,$08,$30,$0C
        .byte   $18,$10,$0E,$0A,$20,$20,$28,$48
        .byte   $02
        php
        php
        php
        php
        php
        php
        php
        php
        php
        php
        .byte   $14,$18,$18,$18,$10,$1C,$34,$14
        .byte   $18,$1C,$0C,$34,$10,$1C,$14,$12
        .byte   $10,$24,$24,$2C,$4C,$02,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $18,$1C,$1C,$1C,$14,$20,$38,$18
        .byte   $1C,$20
        bpl     LD5A8
        .byte   $14,$20,$18,$16,$14,$28,$28,$30
        .byte   $50,$02
        bpl     LD58C
        bpl     LD58E
        bpl     LD590
        bpl     LD592
        bpl     LD594
LD584:  clc
        .byte   $14,$10,$0C,$0C,$10,$28,$10
LD58C:  .byte   $1E
        clc
LD58E:  plp
        .byte   $30
LD590:  .byte   $14
        .byte   $24
LD592:  .byte   $0C
        .byte   $10
LD594:  clc
        bpl     LD5B7
        sec
        clc
        clc
        php
        php
        php
        php
        php
        php
        php
        php
        php
        php
        .byte   $14
        bpl     LD5B3
        php
LD5A8:  php
        .byte   $0C,$24,$0C,$1A,$14,$24,$2C,$10
        .byte   $20,$08
LD5B3:  .byte   $0C,$14,$0C,$1C
LD5B7:  .byte   $34,$14,$14,$04,$04,$04,$04,$04
        .byte   $04,$04,$04,$04,$04,$18,$14,$10
        .byte   $0C,$0C
        bpl     LD5F3
        bpl     LD5EB
        clc
        plp
        bmi     LD5E5
        bit     $0C
        bpl     LD5ED
        bpl     LD5F7
        sec
        clc
        clc
        php
        php
        php
        php
        php
        php
        php
        php
        php
        php
        .byte   $1C
LD5E5:  .byte   $18,$14,$10,$10,$14,$2C
LD5EB:  .byte   $14,$22
LD5ED:  .byte   $1C,$2C,$34,$18,$28,$10
LD5F3:  .byte   $14,$1C,$14,$24
LD5F7:  .byte   $3C,$1C,$1C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$20,$1C,$18
        .byte   $14,$14,$18,$30,$18,$26,$20,$30
        .byte   $38,$1C,$2C,$14,$18,$20,$18,$28
        .byte   $40,$20,$20,$10,$10,$10,$10,$10
        .byte   $10,$10,$10,$10,$10
        ldy     $0400
        sty     $01
        lda     #$09
        jsr     bank_switch
        jsr     L8600
LD631:  lda     #$0D
        jsr     bank_switch
        rts

        .byte   $A9,$09,$20,$00,$C0,$20,$03,$86
        .byte   $4C,$31,$D6,$A9,$09,$20,$00,$C0
        .byte   $20
        asl     $86
        jmp     LD631

        .byte   $A9,$09,$20,$00,$C0,$20,$09,$86
        .byte   $4C,$31,$D6
LD658:  lda     $2A
        and     #$07
        jsr     bank_switch
        clc
        lda     $1F
        sta     $0A
        adc     #$FF
        sta     jump_ptr
        lda     $20
        sta     $0B
        adc     #$00
        sta     $09
        lda     $42
        and     #$40
        bne     LD6E8
LD676:  ldy     $48
        beq     LD692
        lda     $B5FF,y
        cmp     $0B
        bcc     LD692
        bne     LD68A
        lda     $B6FF,y
        cmp     $0A
        bcc     LD692
LD68A:  dey
        jsr     LD753
        dec     $48
        bne     LD676
LD692:  ldy     $49
        beq     LD6A9
LD696:  lda     $B5FF,y
        cmp     $09
        bcc     LD6A9
        bne     LD6A6
        lda     $B6FF,y
        cmp     jump_ptr
        bcc     LD6A9
LD6A6:  dey
        bne     LD696
LD6A9:  sty     $49
LD6AB:  ldy     $4C
        beq     LD6CC
        lda     $B9FF,y
        cmp     $0B
        bcc     LD6CC
        bne     LD6BF
        lda     $BA3F,y
        cmp     $0A
        bcc     LD6CC
LD6BF:  lda     $013F,y
        beq     LD6C8
        dey
        jsr     LD7CC
LD6C8:  dec     $4C
        bne     LD6AB
LD6CC:  ldy     $4D
        beq     LD6E3
LD6D0:  lda     $B9FF,y
        cmp     $09
        bcc     LD6E3
        bne     LD6E0
        lda     $BA3F,y
        cmp     jump_ptr
        bcc     LD6E3
LD6E0:  dey
        bne     LD6D0
LD6E3:  sty     $4D
        jmp     LD74D

LD6E8:  ldy     $49
        lda     $09
        cmp     $B600,y
        bcc     LD701
        bne     LD6FA
        lda     jump_ptr
        cmp     $B700,y
        bcc     LD701
LD6FA:  jsr     LD753
        inc     $49
        bne     LD6E8
LD701:  ldy     $48
LD703:  lda     $0B
        cmp     $B600,y
        bcc     LD716
        bne     LD713
        lda     $0A
        cmp     $B700,y
        bcc     LD716
LD713:  iny
        bne     LD703
LD716:  sty     $48
LD718:  ldy     $4D
        lda     $09
        cmp     $BA00,y
        bcc     LD736
        bne     LD72A
        lda     jump_ptr
        cmp     $BA40,y
        bcc     LD736
LD72A:  lda     $0140,y
        beq     LD732
        jsr     LD7CC
LD732:  inc     $4D
        bne     LD718
LD736:  ldy     $4C
LD738:  lda     $0B
        cmp     $BA00,y
        bcc     LD74B
        bne     LD748
        lda     $0A
        cmp     $BA40,y
        bcc     LD74B
LD748:  iny
        bne     LD738
LD74B:  sty     $4C
LD74D:  lda     #$0E
        jsr     bank_switch
        rts

LD753:  tya
        ldx     #$0F
LD756:  cmp     $0100,x
        beq     LD7CB
        dex
        bpl     LD756
        jsr     LDA43
        bcs     LD7CB
        tya
        sta     $0100,x
        lda     $B600,y
        sta     $0450,x
        lda     $B700,y
        sta     $0470,x
        lda     $B800,y
        sta     $04B0,x
        lda     $B900,y
LD77C:  sta     $0410,x
        tay
        pha
        lda     LD805,y
        sta     $0430,x
        lda     LD981,y
        sta     $06F0,x
        lda     #$14
        sta     $06D0,x
        lda     LD885,y
        tay
        lda     LDA01,y
        sta     $0610,x
        lda     LDA02,y
        sta     $0630,x
        pla
        tay
        lda     LD901,y
        tay
        lda     LDA21,y
        sta     $0650,x
        lda     LDA22,y
        sta     $0670,x
        lda     #$00
        sta     $06B0,x
        sta     $0690,x
        sta     $04F0,x
        sta     $0120,x
        sta     $0490,x
        sta     $04D0,x
        sta     $0110,x
LD7CB:  rts

LD7CC:  tya
        ldx     #$0F
LD7CF:  cmp     $0130,x
        beq     LD7CB
        dex
        bpl     LD7CF
        jsr     LDA43
        bcs     LD7CB
        tya
        pha
        sta     $0130,x
        lda     $BA00,y
        sta     $0450,x
        lda     $BA40,y
        sta     $0470,x
        lda     $BA80,y
        sta     $04B0,x
        lda     $BAC0,y
        jsr     LD77C
        pla
        sta     $0120,x
        tay
        lda     $0140,y
        sta     $06D0,x
        rts

LD805:  .byte   $83,$83,$A0,$A0,$83,$A0,$80,$A0
        .byte   $83,$A0,$83,$83,$83,$87,$80,$83
        .byte   $83,$A0,$80,$80,$A0,$A0,$8B,$87
        .byte   $81,$83,$80,$81,$A0,$A3,$A0,$87
        .byte   $A0,$A0,$83,$83,$85,$A0,$A0,$A0
        .byte   $A0,$83,$87,$A0,$87,$92,$B0,$B0
        .byte   $83,$87,$AB,$87,$8F,$81,$83,$A0
        .byte   $83,$A0,$80,$84,$83,$83,$80,$85
        .byte   $A0,$A0,$A0,$A0,$8B,$83,$83,$A0
        .byte   $83,$83,$A0,$83,$C3,$85,$83,$8F
        .byte   $83,$83,$A1,$A0,$A0,$A0,$A0,$92
        .byte   $81,$81,$81,$85,$81,$8B,$81,$81
        .byte   $80,$8B,$81,$80,$A0,$8B,$8B,$80
        .byte   $81,$8B,$87,$81,$80,$83,$81,$81
        .byte   $80,$A3,$81,$81,$85,$00,$81,$81
        .byte   $81,$81,$81,$81,$81,$81,$81,$00
LD885:  .byte   $00,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$04,$06,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$08,$02,$02
        .byte   $02,$02,$02,$0A,$02,$02,$02,$0C
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$1C,$0E,$0E
        .byte   $02,$10,$02,$02,$02,$02,$02,$02
        .byte   $12,$02,$02,$14,$02,$02,$02,$16
        .byte   $02,$02,$02,$02,$02,$18,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$1A,$1A,$1A,$02,$0E
        .byte   $02,$02,$08,$14,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$08,$1E,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02
LD901:  .byte   $00,$02,$02,$02,$04,$02,$04,$04
        .byte   $06,$04,$02,$08,$02,$08,$0A,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$01,$02,$0E,$0C,$02,$02,$02
        .byte   $02,$02,$02,$02,$10,$02,$02,$02
        .byte   $02,$02,$02,$02,$04,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$0A,$10,$02,$02,$02
        bpl     LD944
        .byte   $02,$02
LD944:  .byte   $02,$20,$02,$02,$02,$14,$16,$02
        .byte   $02,$02,$02,$02,$18,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $1C,$02,$02,$02,$02,$02,$02,$10
        .byte   $02,$02,$02,$02,$14,$02,$02,$02
        .byte   $1E,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02
LD981:  .byte   $00,$00,$00,$01,$01,$01,$01,$01
        .byte   $02,$02,$01,$01,$01,$04,$00,$05
        .byte   $06,$01,$01,$01,$07,$07,$02,$01
        .byte   $04,$08,$02,$04,$08,$09,$00,$00
        .byte   $00,$00,$07,$09,$07,$00,$00,$00
        .byte   $00,$09,$00,$00,$00,$10,$00,$00
        .byte   $05,$07,$0A,$07,$07,$04,$09,$00
        .byte   $07,$00,$07,$04,$04,$01,$03,$07
        .byte   $0B,$0B,$00,$00,$07,$07,$07,$00
        .byte   $0C,$0C,$00,$01,$01,$04,$0D,$01
        asl     $0A0F
        brk
        .byte   $00,$00,$13,$10,$04,$04,$0E,$07
        .byte   $07,$07,$07,$07,$00,$12,$07,$00
        .byte   $00,$13,$00,$00,$02,$00,$07,$09
        .byte   $00,$04,$04,$04,$00,$0D,$04,$04
        .byte   $04,$00,$07,$04,$07,$04,$07,$07
        .byte   $15,$15,$15,$00
LDA01:  .byte   $01
LDA02:  .byte   $E3,$00,$00,$00,$83,$00,$C4,$04
        .byte   $40,$03,$80,$01,$A9,$F0,$E0,$00
        .byte   $41,$02,$0C,$01,$00,$01,$40,$00
        .byte   $6C,$F0,$F0,$F0,$C0,$01,$77
LDA21:  .byte   $00
LDA22:  .byte   $C7,$00,$00,$FF,$5D,$FE,$98,$04
        .byte   $E6,$01,$00,$F8,$00,$FC,$00,$04
        .byte   $00,$01,$47,$08,$00,$F8,$00,$02
        .byte   $D4,$02,$00,$03,$76,$FC,$8A,$00
        .byte   $20
LDA43:  ldx     #$0F
LDA45:  lda     $0430,x
        bpl     LDA4F
        dex
        bpl     LDA45
        sec
        rts

LDA4F:  clc
        rts

        .byte   $A5,$F9,$D0,$15,$A6,$A9,$F0,$04
        .byte   $B5,$9B,$F0,$0D
        lda     LDCB8,x
        sta     jump_ptr
        lda     LDCC4,x
        sta     $09
        jmp     (jump_ptr)

        sec
        rts

        .byte   $A5,$27,$29,$02,$F0,$2B,$A2,$04
LDA74:  lda     $0420,x
        bpl     LDA80
        dex
        cpx     #$01
        bne     LDA74
        beq     LDA9D
LDA80:  lda     #$24
        jsr     bank_switch_enqueue
        ldy     #$00
        jsr     LD3E0
LDA8A:  lda     #$0F
        sta     $36
        lda     #$01
LDA90:  sta     $3D
        ldx     $2C
        clc
        adc     LD3D4,x
        sta     $0400
        clc
        rts

LDA9D:  sec
        rts

        .byte   $A5,$27,$29,$02,$F0,$0C,$A2,$02
        .byte   $A0,$01,$20,$E0,$D3,$A9,$82,$9D
        .byte   $20,$04
        sec
        rts

        .byte   $A5,$27,$29,$02,$F0,$2B,$A2,$04
LDABB:  lda     $0420,x
        bmi     LDAE4
        dex
        cpx     #$01
        bne     LDABB
        ldx     #$04
LDAC7:  stx     $01
        ldy     #$02
        jsr     LD3E0
        ldx     $01
        dex
        cpx     #$01
        bne     LDAC7
        lda     #$3F
        jsr     bank_switch_enqueue
        sec
        lda     $9D
        sbc     #$02
        sta     $9D
        jmp     LDA8A

LDAE4:  sec
        rts

        .byte   $A5,$27,$29,$02,$F0,$1C,$AD,$22
        .byte   $04,$30,$17,$38,$A5,$9E,$E9,$03
        .byte   $90,$10,$A2,$05
LDAFA:  stx     $02
        ldy     #$03
        jsr     LD3E0
        ldx     $02
        dex
        cpx     #$01
        bne     LDAFA
        sec
        rts

        .byte   $A5,$27,$29,$02,$F0,$29,$A2,$03
LDB12:  lda     $0420,x
        bpl     LDB1E
        dex
        cpx     #$01
        bne     LDB12
        beq     LDB39
LDB1E:  ldy     #$04
        jsr     LD3E0
        lda     #$24
        jsr     bank_switch_enqueue
        inc     $AC
        lda     $AC
        cmp     #$02
        bne     LDB36
        lda     #$00
        sta     $AC
        dec     $9F
LDB36:  jmp     LDA8A

LDB39:  sec
        rts

        .byte   $A5,$27,$29,$02,$D0,$0A,$A5,$AB
        .byte   $C9,$0B,$F0,$04,$E6,$AB,$18,$60
        ldx     #$05
LDB4D:  lda     $0420,x
        bpl     LDB59
        dex
        cpx     #$01
        bne     LDB4D
        beq     LDB78
LDB59:  ldy     #$05
        jsr     LD3E0
        lda     #$24
        jsr     bank_switch_enqueue
        inc     $AC
        lda     $AC
        cmp     #$08
        bne     LDB71
        lda     #$00
        sta     $AC
        dec     $A0
LDB71:  lda     #$00
        sta     $AB
        jmp     LDA8A

LDB78:  sec
        rts

        .byte   $A5,$27,$29,$02,$F0,$1D,$AD,$22
        .byte   $04,$30,$18,$38,$A5,$A3,$E9,$04
        .byte   $90,$11,$85,$A3,$A2,$02,$A0,$06
        .byte   $20,$E0,$D3,$A9,$24,$20,$51,$C0
        .byte   $4C,$8A,$DA
        sec
        rts

        .byte   $A5,$27,$29,$02,$F0,$4A,$A2,$04
LDBA7:  lda     $0420,x
        bpl     LDBB3
        dex
        cpx     #$01
        bne     LDBA7
        beq     LDBEF
LDBB3:  ldy     #$07
        jsr     LD3E0
        lda     #$23
        jsr     bank_switch_enqueue
        inc     $AC
        lda     $AC
        cmp     #$04
        bne     LDBCB
        lda     #$00
        sta     $AC
        dec     $A2
LDBCB:  lda     $23
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     LDBF1,y
        sta     $0660,x
        lda     LDC01,y
        sta     $0640,x
        lda     LDC11,y
        sta     $0620,x
        lda     LDC21,y
        sta     $0600,x
        jmp     LDC4D

LDBEF:  sec
        rts

LDBF1:  .byte   $00,$00,$00,$00,$00,$D4,$2C,$00
        .byte   $00,$D4,$2C,$00,$00,$00,$00,$00
LDC01:  .byte   $00,$04,$FC,$00,$00,$02,$FD,$00
        .byte   $00,$02,$FD,$00,$00,$00,$00,$00
LDC11:  .byte   $00,$00,$00,$00,$00,$D4,$D4,$00
        .byte   $00,$D4,$D4,$00,$00,$00,$00,$00
LDC21:  .byte   $04,$00,$00,$00,$04,$02,$02,$00
        .byte   $04,$02,$02,$00,$00,$00,$00,$00
        .byte   $A5,$27,$29,$02,$F0,$1F,$A2,$02
        .byte   $AD,$22,$04,$30,$18,$A0,$08,$20
        .byte   $E0,$D3,$A9,$01,$8D,$A6,$05,$A9
        .byte   $21,$20,$51,$C0
LDC4D:  lda     #$0F
        sta     $36
        lda     #$03
        jmp     LDA90

        sec
        rts

        .byte   $A5,$27,$29,$02,$F0,$F8,$A2,$04
LDC60:  lda     $0420,x
        bpl     LDC6C
        dex
        cpx     #$01
        bne     LDC60
        beq     LDC7B
LDC6C:  ldy     #$09
        jsr     LD3E0
        sec
        lda     $A4
        sbc     #$02
        sta     $A4
        jmp     LDC4D

LDC7B:  sec
        rts

        .byte   $A5,$27,$29,$02,$F0,$19,$AD,$22
        .byte   $04,$30,$14,$A2,$02,$A0,$0A,$20
        .byte   $E0,$D3,$A9,$3E,$8D,$E2,$04,$A9
        .byte   $13,$8D,$C2,$06,$4C,$4D,$DC,$60
        .byte   $A5,$27,$29,$02,$F0,$14,$AD,$22
        .byte   $04,$30,$0F,$A2,$02,$A0,$0B,$20
        .byte   $E0,$D3,$A9,$1F,$8D,$C2,$06,$4C
        .byte   $4D,$DC,$60
LDCB8:  .byte   $6C,$9F,$B3,$E6,$0A,$3B,$31,$9F
        .byte   $7A,$58,$7D,$9D
LDCC4:  .byte   $DA,$DA,$DA,$DA,$DB,$DB,$DC,$DB
        .byte   $DB,$DC,$DC,$DC
LDCD0:  ldx     #$0F
LDCD2:  stx     $2B
        lda     $0420,x
        bpl     LDCE9
        and     #$02
        bne     LDCF1
        sec
        lda     $0460,x
        sbc     $1F
        sta     $06E0,x
        jsr     LEEEF
LDCE9:  ldx     $2B
        dex
        cpx     #$01
        bne     LDCD2
        rts

LDCF1:  lda     #$DC
        pha
        lda     #$E8
        pha
        sec
        lda     $0460,x
        sbc     $1F
        sta     $06E0,x
        sec
        lda     $0400,x
        sbc     #$2F
        tay
        lda     LDD14,y
        sta     jump_ptr
        lda     LDD24,y
        sta     $09
        jmp     (jump_ptr)

LDD14:  .byte   $34,$34,$48,$74,$6F,$CE,$16,$58
        .byte   $58,$90,$10,$DD,$71,$E4,$E4,$E8
LDD24:  .byte   $DD,$DD,$DE,$DE,$DF,$DF,$E0,$E1
        .byte   $E1,$E1,$E2,$E2,$E4,$E4,$E4,$E4
        .byte   $BD,$E0,$04,$F0,$03,$4C,$EC,$DD
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        lda     $AC
        cmp     #$FF
        beq     LDD4C
        inc     $AC
LDD4C:  ldy     #$02
        lda     $AC
        cmp     #$7D
        bcc     LDD5C
        iny
        iny
        cmp     #$BB
        bcc     LDD5C
        iny
        iny
LDD5C:  sty     $00
        lda     $1C
        and     #$04
        bne     LDD66
        ldy     #$00
LDD66:  jsr     LDE18
        lda     $04A0
        sta     $04A0,x
        lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $00
        lsr     a
        tay
        lda     LDE44,y
        cmp     $9C
        bcc     LDD93
        beq     LDD93
        ldy     #$00
        sty     $AC
        jsr     LDE18
        lsr     $0420,x
        rts

LDD93:  lda     $23
        and     #$02
        beq     LDD9A
        rts

LDD9A:  ldy     #$00
        sty     $AC
        jsr     LDE18
        lsr     $0422
        ldx     #$04
LDDA6:  lda     $0420,x
        bpl     LDDB1
        dex
        cpx     #$02
        bne     LDDA6
LDDB0:  rts

LDDB1:  lda     $F9
        bne     LDDD3
        ldy     #$01
        jsr     LD3E0
        lda     $00
        lsr     a
        sta     $04E0,x
        sta     $0590,x
        tay
        lda     LDE41,y
        sta     $06A0,x
        sec
        lda     $0460,x
        sbc     $1F
        sta     $06E0,x
LDDD3:  sec
        lda     $9C
        sbc     LDE44,y
        sta     $9C
        lda     #$38
        jsr     bank_switch_enqueue
        lda     #$04
        sta     $0600,x
        lda     $2C
        beq     LDDB0
        jmp     LDA8A

        cmp     #$02
        bcs     LDDFB
        lda     $06A0,x
        cmp     #$03
        bne     LDE14
        lda     #$01
        bne     LDE11
LDDFB:  bne     LDE08
        lda     $06A0,x
        cmp     #$06
        bne     LDE14
        lda     #$04
        bne     LDE11
LDE08:  lda     $06A0,x
        cmp     #$09
        bne     LDE14
        lda     #$07
LDE11:  sta     $06A0,x
LDE14:  jsr     LEEEF
        rts

LDE18:  lda     LDE39,y
        sta     $0367
        lda     LDE3A,y
        sta     $0369
        lda     $1C
        and     #$07
        bne     LDE34
        lda     $00
        lsr     a
        tay
        lda     LDE35,y
        jsr     bank_switch_enqueue
LDE34:  rts

LDE35:  .byte   $35,$35,$36,$37
LDE39:  .byte   $0F
LDE3A:  .byte   $15,$31,$15,$35,$2C,$30,$30
LDE41:  .byte   $00,$01,$04
LDE44:  .byte   $07,$01,$06,$0A,$8A,$38,$E9,$02
        .byte   $A8,$B9,$6E,$DE,$9D,$20,$06,$B9
        .byte   $71,$DE,$9D,$00,$06,$18,$BD,$60
        .byte   $06,$69,$10,$9D,$60,$06,$BD,$40
        .byte   $06,$69,$00,$9D,$40,$06,$20,$EF
        .byte   $EE,$60,$19,$99,$33,$01,$01,$02
        .byte   $BD,$E0,$04,$D0,$74,$A9,$00,$9D
        .byte   $80,$06,$BD,$C0,$06,$85,$01,$8A
        .byte   $38,$E9,$02,$85,$00,$29,$01,$D0
        .byte   $11,$38,$AD,$60,$04,$E5,$01,$9D
        .byte   $60,$04,$AD,$40,$04,$E9,$00,$4C
        .byte   $AC,$DE
        clc
        lda     $0460
        adc     $01
        sta     $0460,x
        lda     $0440
        adc     #$00
        sta     $0440,x
        lda     $00
        and     #$02
        bne     LDEBE
        sec
        lda     $04A0
        sbc     $01
        jmp     LDEC4

LDEBE:  clc
        lda     $04A0
        adc     $01
LDEC4:  sta     $04A0,x
        lda     $01
        cmp     #$0C
        beq     LDED4
        clc
        adc     #$02
        sta     $06C0,x
        rts

LDED4:  lsr     $0423
        lsr     $0424
        lsr     $0425
        lda     #$83
        sta     $0422
        lda     #$01
        sta     $04E2
        lda     #$01
        sta     $06A2
        rts

        lda     $F9
        beq     LDEF5
        lda     #$06
        bne     LDEFE
LDEF5:  lda     $06A0,x
        cmp     #$05
        bcc     LDF01
        lda     #$01
LDEFE:  sta     $06A0,x
LDF01:  lda     $04E0,x
        cmp     #$01
        bne     LDF69
        lda     $1C
        and     #$07
        bne     LDF13
        lda     #$31
        jsr     bank_switch_enqueue
LDF13:  lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04A0
        sta     $04A0,x
        lda     $F9
        beq     LDF2E
        lda     #$00
        sta     $04A0,x
LDF2E:  lda     $23
        and     #$F0
        beq     LDF68
        ldy     $F9
        beq     LDF3C
        lsr     $0420,x
        rts

LDF3C:  and     #$C0
        beq     LDF4F
        lsr     a
        and     #$40
        ora     #$83
        sta     $0420,x
        lda     #$04
        sta     $0600,x
        bne     LDF5E
LDF4F:  ldy     #$00
        lda     $23
        and     #$10
        bne     LDF58
        iny
LDF58:  lda     LDF6D,y
        sta     $0640,x
LDF5E:  sec
        lda     $9E
        sbc     #$03
        sta     $9E
        inc     $04E0,x
LDF68:  rts

LDF69:  jsr     LEEEF
        rts

LDF6D:  .byte   $04,$FC,$A9,$07,$85,$01,$A9,$07
        .byte   $85,$02,$20,$CF,$F0,$BD,$E0,$04
        .byte   $D0,$20,$A5,$00,$F0,$47,$FE,$E0
        .byte   $04,$BD,$20,$04,$29,$FB,$9D,$20
        .byte   $04
LDF8E:  lda     #$C0
        sta     $0660,x
        lda     #$FF
        sta     $0640,x
        lda     #$02
        sta     $0600,x
        bne     LDFCA
        cmp     #$01
        bne     LDFC1
        lda     $03
        beq     LDFAB
        lsr     $0420,x
        rts

LDFAB:  lda     $00
        bne     LDFCA
        lda     #$00
        sta     $0600,x
        sta     $0660,x
        lda     #$FE
        sta     $0640,x
        inc     $04E0,x
        bne     LDFCA
LDFC1:  lda     $00
        beq     LDFCA
        dec     $04E0,x
        bne     LDF8E
LDFCA:  jsr     LEEEF
        rts

        .byte   $BD,$E0,$04,$C9,$12,$B0,$14,$38
        .byte   $BD,$60,$06,$E9,$4B,$9D,$60,$06
        .byte   $BD
        rti

        asl     $E9
        brk
        .byte   $9D,$40,$06,$4C,$0F,$E0
        bne     LDFF3
        lda     $0420,x
        eor     #$40
        sta     $0420,x
LDFF3:  lda     $04E0,x
        cmp     #$23
        bne     LDFFE
        lsr     $0420,x
        rts

LDFFE:  clc
        lda     $0660,x
        adc     #$4B
        sta     $0660,x
        lda     $0640,x
        adc     #$00
        sta     $0640,x
        inc     $04E0,x
        jsr     LEEEF
        rts

        .byte   $BD,$E0,$04,$D0,$77,$A9,$00,$9D
        .byte   $A0,$06,$9D,$80,$06,$38,$BD,$A0
        .byte   $04,$E9,$08,$85,$0A,$A9,$00,$85
        .byte   $0B,$BD,$20,$04,$29,$40,$D0,$10
        .byte   $38,$BD,$60,$04,$E9,$06,$85,$08
        .byte   $BD,$40,$04,$E9,$00,$4C,$53,$E0
        clc
        lda     $0460,x
        adc     #$06
        sta     jump_ptr
        lda     $0440,x
        adc     #$00
        sta     $09
        jsr     LCBA2
        ldy     $00
        ldx     $2B
        lda     LE14F,y
        bne     LE078
        clc
        lda     $0A
        adc     #$10
        sta     $0A
        jsr     LCBA2
        ldy     $00
        ldx     $2B
        lda     LE14F,y
        bne     LE078
        jsr     LEEEF
        rts

LE078:  lda     #$2E
        jsr     bank_switch_enqueue
        lda     $0420,x
        and     #$FE
        sta     $0420,x
        inc     $06A0,x
        inc     $04E0,x
        lda     #$7E
        sta     $06C0,x
        bne     LE0B9
        cmp     #$01
        bne     LE0BD
        lda     $06A0,x
        cmp     #$04
        bne     LE0A2
        lda     #$02
        sta     $06A0,x
LE0A2:  dec     $06C0,x
        bne     LE0B9
        lda     #$05
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        lda     #$38
        sta     $06C0,x
        inc     $04E0,x
LE0B9:  jsr     LE4E9
        rts

LE0BD:  lda     #$00
        sta     $0680,x
        lda     $06C0,x
        and     #$07
        bne     LE110
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     $06C0,x
        lsr     a
        and     #$0C
        sta     $02
        lda     #$06
        sta     $01
LE0DA:  lda     $01
        cmp     #$02
        beq     LE110
        sta     $00
        ldy     #$0C
        jsr     LE4FF
        ldy     $00
        ldx     $02
        clc
        lda     $04A0,y
        adc     LE11F,x
        sta     $04A0,y
        clc
        lda     $0460,y
        adc     LE12F,x
        sta     $0460,y
        lda     $0440,y
        adc     LE13F,x
        sta     $0440,y
        ldx     $2B
        inc     $02
        dec     $01
        bne     LE0DA
LE110:  ldx     $2B
        dec     $06C0,x
        bpl     LE11B
        lsr     $0420,x
        rts

LE11B:  jsr     LE4E9
        rts

LE11F:  .byte   $F8,$F0,$08,$00,$F8,$F8
LE125:  php
        brk
        .byte   $F0,$00
        bpl     LE13B
        beq     LE125
        php
        php
LE12F:  sed
        php
        brk
        .byte   $10,$F8,$10,$F0,$08,$00,$00,$F8
        .byte   $10
LE13B:  beq     LE14D
        beq     LE147
LE13F:  .byte   $FF,$00,$00,$00,$FF,$00,$FF,$00
LE147:  .byte   $00,$00,$FF,$00,$FF,$00
LE14D:  .byte   $FF,$00
LE14F:  .byte   $00,$01,$00,$00,$00,$01,$01,$01
        .byte   $01,$DE,$20,$06,$D0,$15,$A9,$0F
        .byte   $9D,$20,$06,$C6,$A1,$D0,$0C,$5E
        .byte   $20,$04,$A9,$00,$85,$AA,$A9,$01
        .byte   $85,$50,$60
        lda     #$01
        sta     $AA
        lda     #$00
        sta     $50
        sta     $4F
        lda     #$80
        sta     $04A0,x
        clc
        adc     $1F
        sta     $0460,x
        lda     $0440
        adc     #$00
        sta     $0440,x
        rts

        .byte   $BD,$E0,$04,$D0,$23,$FE,$C0,$06
        .byte   $BD,$C0,$06,$C9,$BB,$F0,$0F,$BD
        .byte   $A0,$06,$C9,$02,$D0,$05,$A9,$00
        .byte   $9D,$A0,$06
        jmp     LE1CD

        lda     #$3E
        sta     $06C0,x
        inc     $04E0,x
        bne     LE1CD
        cmp     #$01
        bne     LE205
        lda     $06A0,x
        cmp     #$07
        bne     LE1C8
        lda     #$03
        sta     $06A0,x
LE1C8:  dec     $06C0,x
        beq     LE1F3
LE1CD:  sec
        lda     $04A0,x
        sbc     #$04
        sta     $05A1,x
        lda     #$14
        sta     $059E,x
        lda     #$0B
        sta     $01
        lda     #$1D
        sta     $02
        lda     #$04
        sta     $03
        jsr     LE3ED
        lda     $00
        beq     LE205
        lda     #$00
        sta     $0660,x
LE1F3:  lda     #$02
        sta     $04E0,x
        lda     #$08
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        sta     $059E,x
LE205:  jsr     LEEEF
        bcc     LE20F
        lda     #$00
        sta     $059E,x
LE20F:  rts

        .byte   $BD,$E0,$04,$F0,$05,$DE,$E0,$04
        .byte   $D0,$4C
        dec     $06C0,x
        bne     LE245
        lda     #$13
        sta     $06C0,x
        dec     $A5
        bne     LE245
LE228:  lda     #$05
        sta     $06A0,x
        lda     #$00
        sta     $05A0
        sta     $0600,x
        sta     $0620,x
        sta     $0680,x
        lda     #$80
        sta     $0420,x
        beq     LE245
        jmp     LE2D2

LE245:  lda     $0600,x
        cmp     #$02
        beq     LE266
        clc
        lda     $0620,x
        adc     #$08
        sta     $0620,x
        lda     $0600,x
        adc     #$00
        sta     $0600,x
        cmp     #$02
        bne     LE266
        lda     #$00
        sta     $0620,x
LE266:  lda     #$0F
        sta     $01
        lda     #$08
        sta     $02
        jsr     LF0CF
        lda     $03
        bne     LE228
        sec
        lda     $04A0,x
        sbc     #$20
        sta     $0A
        lda     #$00
        sta     $0B
        sec
        lda     $0460,x
        sbc     #$10
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
        sta     $09
        jsr     LCBA2
        ldx     $2B
        ldy     $00
        lda     LE14F,y
        bne     LE2B5
        clc
        lda     jump_ptr
        adc     #$20
        sta     jump_ptr
        lda     $09
        adc     #$00
        sta     $09
        jsr     LCBA2
        ldx     $2B
        ldy     $00
        lda     LE14F,y
        beq     LE2B8
LE2B5:  jmp     LE228

LE2B8:  sec
        lda     $04A0,x
        sbc     #$04
        sta     $05A1,x
        lda     #$18
        sta     $059E,x
        lda     $06A0,x
        cmp     #$04
        bne     LE2D2
        lda     #$00
        sta     $06A0,x
LE2D2:  jsr     LEEEF
        bcc     LE2DC
        lda     #$00
        sta     $059E,x
LE2DC:  rts

        .byte   $BD,$E0,$04,$D0
        adc     $BD
        rti

        asl     $85
        .byte   $04
        lda     #$0A
        sta     $01
        lda     #$08
        sta     $02
        jsr     LF0CF
        lda     $03
        beq     LE313
        lda     #$62
        sta     $0660,x
        lda     #$00
        sta     $0640,x
        sta     $0620,x
        sta     $0600,x
        lda     $0420,x
        and     #$FB
        sta     $0420,x
        inc     $04E0,x
        bne     LE325
LE313:  lda     $04
        bpl     LE325
        lda     $00
        beq     LE325
        lda     #$03
        sta     $0640,x
        lda     #$76
        sta     $0660,x
LE325:  lda     #$00
        sta     $0590,x
        lda     $06A0,x
        cmp     #$04
        bne     LE336
        lda     #$00
        sta     $06A0,x
LE336:  dec     $06C0,x
        bne     LE344
        lda     #$1F
        sta     $06C0,x
        dec     $A6
        beq     LE39D
LE344:  jmp     LE3E2

        sec
        lda     $04A0,x
        sbc     #$08
        sta     $05A1,x
        lda     #$14
        sta     $059E,x
        lda     #$0C
        sta     $01
        lda     #$21
        sta     $02
        lda     #$08
        sta     $03
        jsr     LE3ED
        lda     $04E0,x
        and     #$0F
        cmp     #$02
        bcs     LE3B6
        lda     $04E0,x
        bpl     LE377
        inc     $04E0,x
        bne     LE377
LE377:  lda     $00
        bne     LE39D
        lda     $03
        bne     LE325
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        lda     $06A0,x
        cmp     #$09
        bne     LE393
        lda     #$05
        sta     $06A0,x
LE393:  inc     $0590,x
        lda     $0590,x
        cmp     #$3E
        bcc     LE336
LE39D:  lda     #$0A
        sta     $06A0,x
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        sta     $0680,x
        sta     $059E,x
        lda     #$80
        sta     $0420,x
        rts

LE3B6:  lda     $04E0,x
        bpl     LE3CC
        and     #$0F
        sta     $04E0,x
        lda     #$62
        sta     $0660,x
        lda     #$00
        sta     $0640,x
        beq     LE377
LE3CC:  lda     $0640,x
        bpl     LE3D5
        lda     $00
        bne     LE39D
LE3D5:  lda     #$9E
        sta     $0660,x
        lda     #$FF
        sta     $0640,x
        jmp     LE377

LE3E2:  jsr     LEEEF
        bcc     LE3EC
        lda     #$00
        sta     $059E,x
LE3EC:  rts

LE3ED:  lda     $0420,x
        and     #$40
        bne     LE404
        sec
        lda     $0460,x
        sbc     $01
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
        jmp     LE411

LE404:  clc
        lda     $0460,x
        adc     $01
        sta     jump_ptr
        lda     $0440,x
        adc     #$00
LE411:  sta     $09
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $0A
        lda     #$00
        sbc     #$00
        sta     $0B
        jsr     LCBA2
        ldx     $2B
        ldy     $00
        lda     LE468,y
        pha
        lda     $0640,x
        bpl     LE440
        clc
        lda     $04A0,x
        adc     $03
        sta     $0A
        lda     #$00
        adc     #$00
        jmp     LE44C

LE440:  sec
        lda     $04A0,x
        sbc     $02
        sta     $0A
        lda     #$00
        sbc     #$00
LE44C:  sta     $0B
        lda     $0460,x
        sta     jump_ptr
        lda     $0440,x
        sta     $09
        jsr     LCBA2
        ldx     $2B
        ldy     $00
        lda     LE468,y
        sta     $00
        pla
        sta     $03
        rts

LE468:  .byte   $00,$01,$00,$01,$00,$01,$01,$01
        .byte   $01
        lda     #$00
        sta     $0680,x
        lda     $04E0,x
        bne     LE4AE
        lda     $06C0,x
        bne     LE4DD
        lda     $0420,x
        eor     #$40
        sta     $0420,x
        inc     $06A0,x
        and     #$40
        beq     LE492
        inc     $06A0,x
LE492:  lda     #$00
        sta     $0620,x
        sta     $0660,x
        lda     #$FE
        sta     $0640,x
        lda     #$01
        sta     $0600,x
        lda     #$10
        sta     $06C0,x
        inc     $04E0,x
        bne     LE4DD
LE4AE:  clc
        lda     $0620,x
        adc     #$40
        sta     $0620,x
        lda     $0600,x
        adc     #$00
        sta     $0600,x
        lda     $06C0,x
        bne     LE4DD
        lda     #$00
        sta     $06A0,x
        sta     $0620,x
        sta     $0600,x
        sta     $0660,x
        sta     $0640,x
        lda     #$02
        sta     $06C0,x
        dec     $04E0,x
LE4DD:  dec     $06C0,x
        jsr     LEEEF
        rts

        jsr     LE4E9
        rts

        .byte   $60
LE4E9:  sec
        lda     $0460,x
        sbc     $1F
        lda     $0440,x
        sbc     $20
        bcc     LE4FA
        bne     LE4FA
        clc
        rts

LE4FA:  lsr     $0420,x
        sec
        rts

LE4FF:  lda     $0460,x
        sta     jump_ptr
        lda     $0440,x
        sta     $09
        lda     $04A0,x
        sta     $0A
        ldx     $00
        lda     LD44F,y
        sta     $0400,x
        lda     LD461,y
        sta     $0420,x
        lda     jump_ptr
        sta     $0460,x
        lda     $09
        sta     $0440,x
        lda     $0A
        sta     $04A0,x
        lda     LD485,y
        sta     $0620,x
        lda     LD497,y
        sta     $0600,x
        lda     LD4A9,y
        sta     $0660,x
        lda     LD4BB,y
        sta     $0640,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        sta     $04E0,x
        sec
        lda     $0460,x
        sbc     $1F
        sta     $06E0,x
        ldx     $2B
        rts

LE55A:  lda     #$00
        sta     $01
        lda     $2C
        beq     LE5CC
        lda     $BD
        bne     LE5CC
        lda     $F9
        bne     LE5CC
        sec
        lda     $2D
        sbc     $2E
        bcs     LE575
        eor     #$FF
        adc     #$01
LE575:  ldy     $06E0,x
        cmp     LD4E4,y
        bcs     LE5CC
        sec
        lda     $04A0
        sbc     $04A0,x
        bcs     LE58A
        eor     #$FF
        adc     #$01
LE58A:  cmp     LD584,y
        bcs     LE5CC
        ldy     $0400,x
        cpy     #$76
        bcs     LE5CD
        lda     $4B
        bne     LE5CC
        sec
        lda     $06C0
        sbc     LED5C,y
        sta     $06C0
        beq     LE5A8
        bcs     LE5B2
LE5A8:  lda     #$00
        sta     $2C
        sta     $06C0
        jmp     LC10B

LE5B2:  lda     $0420
        and     #$BF
        sta     $0420
        lda     $0420,x
        and     #$40
        eor     #$40
        ora     $0420
        sta     $0420
        jsr     LD332
        inc     $01
LE5CC:  rts

LE5CD:  lda     $AD
        bne     LE5EB
        lsr     $0420,x
        sty     $AD
        inc     $01
        lda     $04E0,x
        bne     LE5EB
        lda     #$FF
        sta     $0120,x
        lda     $0110,x
        tay
        lda     #$00
        sta     $0140,y
LE5EB:  rts

LE5EC:  lda     $04A0,x
        sta     $00
        lda     $06E0,x
        sta     jump_ptr
        ldx     #$09
        lda     $1C
        and     #$01
        bne     LE5FF
        dex
LE5FF:  lda     $0420,x
        bpl     LE634
        and     #$01
        beq     LE634
        clc
        ldy     $0590,x
        lda     LD4DF,y
        adc     jump_ptr
        tay
        sec
        lda     $2E
        sbc     $06E0,x
        bcs     LE61E
        eor     #$FF
        adc     #$01
LE61E:  cmp     LD4E4,y
        bcs     LE634
        sec
        lda     $00
        sbc     $04A0,x
        bcs     LE62F
        eor     #$FF
        adc     #$01
LE62F:  cmp     LD584,y
        bcc     LE643
LE634:  dex
        dex
        cpx     #$02
        bcs     LE5FF
        ldx     $2B
        lda     #$00
        sta     $0100,x
        clc
        rts

LE643:  ldy     $A9
        lda     LE986,y
        sta     jump_ptr
        lda     LE98F,y
        sta     $09
        jmp     (jump_ptr)

        .byte   $A4,$2B,$B9,$20,$04,$29,$08,$D0
        .byte   $34,$B9,$00,$04,$A8,$B9,$98,$E9
        .byte   $85,$00,$F0,$29,$20,$7F,$E9,$5E
        .byte   $20,$04,$A9,$2B,$20,$51,$C0,$A6
        .byte   $2B,$BD,$00,$01,$D0,$30,$FE,$00
        .byte   $01,$38,$BD,$C0,$06,$E5,$00,$9D
        .byte   $C0,$06,$F0,$02,$B0,$20
        lda     #$00
        sta     $06C0,x
        sec
        rts

        lda     $0420,x
        eor     #$40
        and     #$FE
        sta     $0420,x
        lda     #$05
        sta     $0640,x
        sta     $0600,x
        lda     #$2D
        jsr     bank_switch_enqueue
        ldx     $2B
        clc
        rts

        .byte   $A4,$2B,$B9,$20,$04,$29,$08,$D0
        .byte   $4F,$B9,$00,$04,$A8,$BD,$E0,$04
        .byte   $C9,$02,$90,$13,$F0,$06,$B9,$14
        .byte   $EA,$4C,$D4,$E6
        clc
        lda     LE998,y
        asl     a
        adc     LE998,y
        jmp     LE6D4

        lda     LE998,y
LE6D4:  sta     $00
        beq     LE702
        jsr     LE97F
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     LE712
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     LE6FB
        bcs     LE70D
LE6FB:  lda     #$00
        sta     $06C0,x
        sec
        rts

LE702:  lda     #$2D
        jsr     bank_switch_enqueue
        lsr     $0420,x
        jmp     LE712

LE70D:  lda     #$00
        sta     $0420,y
LE712:  ldx     $2B
        clc
        rts

        .byte   $A4,$2B,$B9,$20,$04,$29,$08,$D0
        .byte   $35,$B9,$00,$04,$A8,$B9,$8C,$EA
        .byte   $85,$00,$F0
        rol     a
        jsr     LE97F
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     LE770
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     LE74D
        bcs     LE70D
LE74D:  lda     #$00
        sta     $06C0,x
        sec
        rts

        lda     #$2D
        jsr     bank_switch_enqueue
        lda     $0420,x
        and     #$FE
        sta     $0420,x
        lda     #$3D
        sta     $0400,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        ldx     $2B
LE770:  clc
        rts

        .byte   $A4,$2B,$B9,$20,$04,$29,$08,$D0
        .byte   $35,$B9,$00,$04,$A8,$B9,$04,$EB
        .byte   $85,$00,$F0,$2A,$20,$7F,$E9,$8A
        .byte   $48,$A9,$2B,$20,$51,$C0,$68,$A8
        .byte   $A6,$2B,$BD,$00,$01,$D0,$39,$FE
        .byte   $00,$01,$38,$BD,$C0,$06,$E5,$00
        .byte   $9D,$C0,$06,$F0,$02,$B0,$2B
        lda     #$00
        sta     $06C0,x
        sec
        rts

        lda     #$2D
        jsr     bank_switch_enqueue
        lda     $0420,x
        and     #$F2
        sta     $0420,x
        lda     #$3B
        sta     $0400,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        sta     $04E0,x
        sta     $06C0,x
LE7D0:  ldx     $2B
        clc
        rts

LE7D4:  lda     #$00
        sta     $0420,y
        beq     LE7D0
        ldy     $2B
        lda     $0420,y
        and     #$08
        bne     LE819
        lda     $0400,y
        tay
        lda     LEB7C,y
        sta     $00
        beq     LE819
        jsr     LE97F
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     LE835
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     LE812
        bcs     LE7D4
LE812:  lda     #$00
        sta     $06C0,x
        sec
        rts

LE819:  lda     #$00
        sta     $0600,x
        sta     $0620,x
        sta     $0660,x
        lda     #$04
        sta     $0640,x
        lda     #$80
        sta     $0420,x
        lda     #$2D
        jsr     bank_switch_enqueue
        ldx     $2B
LE835:  clc
        rts

        .byte   $A4,$2B,$B9,$20,$04,$29,$08,$D0
        .byte   $35,$B9,$00,$04,$A8,$B9,$F4,$EB
        .byte   $85,$00,$F0,$2A,$20,$7F,$E9,$8A
        .byte   $48,$A9,$2B,$20,$51,$C0,$68,$A8
        .byte   $A6,$2B,$BD,$00,$01,$D0,$47,$FE
        .byte   $00,$01,$38,$BD,$C0,$06,$E5,$00
        .byte   $9D,$C0,$06,$F0,$02,$B0,$39
        lda     #$00
        sta     $06C0,x
        sec
        rts

        lda     #$3C
        sta     $0400,x
        lda     $0420,x
        and     #$C0
        eor     #$40
        ora     #$04
        sta     $0420,x
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
LE8A3:  ldx     $2B
        clc
        rts

LE8A7:  lda     #$00
        sta     $0420,y
        beq     LE8A3
        ldy     $2B
        lda     $0420,y
        and     #$08
        bne     LE8EC
        lda     $0400,y
        tay
        lda     LEC6C,y
        sta     $00
        beq     LE8EC
        jsr     LE97F
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     LE911
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     LE8E5
        bcs     LE8A7
LE8E5:  lda     #$00
        sta     $06C0,x
        sec
        rts

LE8EC:  lda     $0400,x
        cmp     #$2F
        beq     LE911
        lda     $04E0,x
        cmp     #$02
        beq     LE911
        lda     #$05
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        lda     #$38
        sta     $06C0,x
        inc     $04E0,x
        lda     #$2D
        jsr     bank_switch_enqueue
LE911:  ldx     $2B
        clc
        rts

        .byte   $A4,$2B,$B9,$20,$04,$29,$08,$D0
        .byte   $35,$B9,$00,$04,$A8,$B9,$E4,$EC
        .byte   $85,$00,$F0,$2A,$20,$7F,$E9,$8A
        .byte   $48,$A9,$2B,$20,$51,$C0,$68,$A8
        .byte   $A6,$2B,$BD,$00,$01,$D0,$3A,$FE
        .byte   $00,$01,$38,$BD,$C0,$06,$E5,$00
        .byte   $9D,$C0,$06,$F0,$02,$B0,$2C
        lda     #$00
        sta     $06C0,x
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
        lda     $0420,x
        and     #$F0
        sta     $0420,x
        lda     #$2D
        jsr     bank_switch_enqueue
LE974:  ldx     $2B
        clc
        rts

        lda     #$00
        sta     $0420,y
        beq     LE974
LE97F:  lda     $CB
        bne     LE985
        asl     $00
LE985:  rts

LE986:  .byte   $52,$AA,$16,$72,$DB,$37,$7F,$15
        .byte   $AE
LE98F:  .byte   $E6,$E6,$E7,$E7,$E7,$E8,$E9,$E9
        .byte   $E8
LE998:  .byte   $07,$07,$14,$14,$14,$14,$14,$14
        .byte   $14,$14,$0A,$0A,$02,$14,$14,$02
        .byte   $00,$00,$00,$00,$00,$00,$0A,$02
        .byte   $00,$01,$00,$00,$00,$07,$00,$02
        .byte   $00,$00,$14,$02,$00,$00,$00,$00
        .byte   $00,$06,$14,$00,$04,$00,$00,$00
        .byte   $00,$0A,$00,$00,$14,$00,$04,$00
        .byte   $14,$00,$14,$00,$14,$07,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$00,$00
        .byte   $04,$04,$00,$04,$04,$00,$01,$02
        .byte   $04,$04,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$07,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$14,$14,$00,$00
        .byte   $14,$00,$14,$00,$14,$00,$14,$14
        .byte   $14,$14,$00,$14,$00,$00,$00,$00
        .byte   $00,$00,$14,$14,$00,$14,$00,$00
        .byte   $00,$14,$00,$14,$00,$00,$14,$00
        .byte   $00,$00,$00,$00,$00,$14,$14,$00
        .byte   $14,$00,$00,$00,$00,$14,$00,$00
        .byte   $14,$14,$00,$00,$14,$00,$14,$14
        .byte   $14,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$14,$14,$00,$14,$14,$00,$14
        .byte   $14,$00,$14,$14,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$14,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $14,$00,$14,$00,$14,$00,$00,$14
        .byte   $00,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$14,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$14,$14
        .byte   $00,$00,$00,$00,$00,$00,$14,$00
        .byte   $14,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$14,$00,$07,$00
        .byte   $14,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$14,$00,$00,$07,$07,$00,$07
        .byte   $07,$00,$07,$04,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$14,$14,$00,$00
        .byte   $14,$00,$14,$00,$14,$00,$14,$14
        .byte   $00,$14,$00,$07,$00,$00,$00,$00
        .byte   $00,$00,$14,$14,$00,$14,$00,$00
        .byte   $00,$14,$00,$14,$00,$00,$14,$07
        .byte   $00,$00,$00,$00,$00,$07,$14,$00
        .byte   $07,$00,$00,$00,$00,$00,$00,$00
        .byte   $14,$00,$07,$00,$14,$00,$14,$00
        .byte   $14,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$14,$14,$00,$14,$14,$00,$14
        .byte   $14,$00,$07,$07,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00
LEB7C:  .byte   $14,$14,$00,$00,$00,$00,$14,$00
        .byte   $14,$00,$00,$14,$04,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$07
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$07,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$14,$00,$07,$00
        .byte   $00,$00,$00,$00,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$07,$00
        .byte   $00,$00,$00,$02,$02,$00,$00,$04
        .byte   $07,$07,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$14,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $07,$07,$00,$00,$14,$00,$14,$00
        .byte   $07,$00,$04,$14,$04,$14,$00,$02
        .byte   $00,$00,$00,$00,$00,$00,$0A,$04
        .byte   $00,$02,$00,$00,$00,$07,$00,$02
        .byte   $00,$00,$14,$02,$00,$00,$00,$00
        .byte   $00,$07,$07,$00,$04,$00,$00,$00
        .byte   $00,$0A,$00,$00,$14,$00,$04,$00
        .byte   $14,$00,$00,$00,$14,$07,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$07,$00
        .byte   $04,$04,$00,$04,$04,$00,$04,$04
        .byte   $04,$04,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$07,$00,$00,$00,$00,$00
        .byte   $00,$14,$00,$00,$00,$00,$00,$00
LEC6C:  .byte   $14,$14,$00,$00,$14,$00,$14,$00
        .byte   $14,$00,$14,$14,$00,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$14,$14
        .byte   $00,$00,$00,$00,$00,$14,$00,$14
        .byte   $00,$00,$14,$00,$00,$00,$00,$00
        .byte   $00,$14,$14,$00,$14,$0A,$00,$00
        .byte   $00,$14,$00,$00,$14,$00,$07,$00
        .byte   $14,$00,$14,$00,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$07,$00
        .byte   $04,$04,$00,$04,$04,$00,$04,$02
        .byte   $04,$04,$00,$00,$00,$00,$00,$0A
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$00,$00
        .byte   $00,$14,$00,$00,$00,$00,$00,$00
        .byte   $14,$14,$00,$00,$14,$00,$14,$00
        .byte   $14,$00,$04,$14,$02,$14,$00,$04
        .byte   $00,$00,$00,$00,$00,$00,$14,$04
        .byte   $00,$02,$00,$00,$00,$07,$00,$00
        .byte   $00,$00,$14,$04,$00,$00,$00,$00
        .byte   $00,$00,$14,$00,$14,$00,$00,$00
        .byte   $00,$0A,$00,$00,$14,$00,$04,$00
        .byte   $14,$00,$14,$00,$14,$07,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$00,$00
        .byte   $07,$07,$00,$04,$04,$00,$00,$02
        .byte   $14,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$07,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
LED5C:  .byte   $02,$02,$02,$02,$02,$02,$04,$04
        .byte   $04,$04,$04,$04,$04,$01,$00,$0C
        .byte   $0C,$00,$00,$00,$00,$1C,$04,$04
        .byte   $02,$08,$08,$04,$00,$04,$00,$04
        .byte   $00,$00,$02,$08,$03,$00,$00,$00
        .byte   $00,$04,$04,$00,$04,$00,$00,$00
        .byte   $08,$08,$08,$04,$04,$02,$06,$00
        .byte   $04,$00,$04,$00,$02,$04,$00,$02
        .byte   $00,$00,$00,$00,$02,$02,$04,$00
        .byte   $04,$04,$00,$04,$04,$02,$08,$04
        .byte   $02,$02,$08,$00,$00,$00,$0A,$00
        .byte   $04,$04,$02,$04,$03,$04,$04,$04
        .byte   $00,$08,$04,$04,$00,$1C,$1C,$04
        .byte   $06,$04,$08,$06,$00,$04,$04,$06
        .byte   $00,$0A,$0A,$0A,$0A,$00,$00,$00
        .byte   $00,$00,$00,$00,$A9,$14,$9D,$50
        .byte   $01,$20,$B3,$EF,$90,$05,$A9,$00
        .byte   $9D
LEDE5:  .byte   $50,$01
        sec
        lda     $04A0,x
        sbc     #$04
        sta     $0160,x
        rts

        .byte   $A9,$18,$9D,$50,$01,$20,$B3,$EF
        .byte   $90,$05,$A9,$00,$9D,$50,$01
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $0160,x
        rts

        .byte   $A9,$18,$9D,$50,$01,$20,$B3,$EF
        .byte   $90,$05,$A9,$00,$9D,$50,$01
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $0160,x
        rts

        .byte   $20,$EE,$EF,$38,$BD,$00,$04,$E9
        .byte   $40,$A8,$B9,$79,$AF,$85,$01,$BD
        .byte   $20,$04,$29,$20,$F0,$1B,$A4,$01
        .byte   $A9,$15,$D9,$58,$03,$D0,$07,$A9
        .byte   $04,$9D,$20,$06,$D0,$06
        lda     $00
        cmp     #$60
        bcs     LEE78
        lda     #$82
        sta     $0420,x
        lda     $0620,x
        cmp     #$04
        bcs     LEE78
        lda     $04E0,x
        and     #$03
        bne     LEE75
        sta     $04E0,x
        lda     $0620,x
        inc     $0620,x
        asl     a
        asl     a
        tay
        ldx     $01
        jsr     LAF4C
        ldx     $2B
LEE75:  inc     $04E0,x
LEE78:  jsr     LEFB3
        rts

        .byte   $BD,$20,$06,$D0,$22,$A9,$6E,$9D
        .byte   $E0,$04,$FE,$20,$06,$A9,$00,$9D
        .byte   $20,$04,$A9,$01,$85,$01,$A9,$23
        .byte   $20,$CF,$96,$A9,$83,$9D,$20,$04
        .byte   $B0,$05,$A9,$26,$20,$59,$F1
        jsr     LEFB3
        bcc     LEEB4
        lda     #$23
        jsr     LF010
        bcc     LEEB4
        lda     #$28
        jsr     LF159
LEEB4:  rts

        .byte   $60,$A9,$01,$D0,$02,$A9,$00
        sta     $4E
        lda     $0420,x
        and     #$03
        beq     LEEEF
        pha
        and     #$01
        beq     LEECD
        jsr     LE55A
LEECD:  pla
        and     #$02
        beq     LEEEF
        jsr     LE5EC
        bcc     LEEEF
        jsr     LF25A
        lda     #$06
        sta     $0400,x
        lda     #$80
        sta     $0420,x
        lda     #$00
        sta     $0680,x
        sta     $06A0,x
        jmp     LEF8F

LEEEF:  sec
        lda     $04C0,x
        sbc     $0660,x
        sta     $04C0,x
        lda     $04A0,x
        sbc     $0640,x
        sta     $04A0,x
        cmp     #$F0
        bcc     LEF09
        jmp     LEF8C

LEF09:  lda     $0420,x
        and     #$04
        beq     LEF21
        clc
        lda     $0660,x
        sbc     $30
        sta     $0660,x
        lda     $0640,x
        sbc     $31
        sta     $0640,x
LEF21:  lda     $0420,x
        and     #$40
        bne     LEF5A
        sec
        lda     $0480,x
        sbc     $0620,x
        sta     $0480,x
        lda     $0460,x
        sbc     $0600,x
        sta     $0460,x
        lda     $0440,x
        sbc     #$00
        sta     $0440,x
        sec
        lda     $0460,x
        sbc     $1F
        sta     jump_ptr
        lda     $0440,x
        sbc     $20
        bne     LEF8C
        lda     jump_ptr
        cmp     #$08
        bcc     LEF8C
        bcs     LEF8A
LEF5A:  clc
        lda     $0480,x
        adc     $0620,x
        sta     $0480,x
        lda     $0460,x
        adc     $0600,x
        sta     $0460,x
        lda     $0440,x
        adc     #$00
        sta     $0440,x
        sec
        lda     $0460,x
        sbc     $1F
        sta     jump_ptr
        lda     $0440,x
        sbc     $20
        bne     LEF8C
        lda     jump_ptr
        cmp     #$F8
        bcs     LEF8C
LEF8A:  clc
        rts

LEF8C:  lsr     $0420,x
LEF8F:  cpx     #$10
        bcc     LEF9C
        lda     $4E
        bne     LEF9E
        lda     #$FF
        sta     a:$F0,x
LEF9C:  sec
        rts

LEF9E:  lda     #$FF
        sta     $0120,x
        lda     $0110,x
        tay
        lda     $06C0,x
        sta     $0140,y
        sec
        rts

        .byte   $A9,$01,$D0,$02
LEFB3:  lda     #$00
        sta     $4E
        lda     $0420,x
        and     #$03
        beq     LEFE8
        pha
        and     #$01
        beq     LEFC6
        jsr     LE55A
LEFC6:  pla
        and     #$02
        beq     LEFE8
        jsr     LE5EC
        bcc     LEFE8
        jsr     LF25A
        lda     #$06
        sta     $0400,x
        lda     #$80
        sta     $0420,x
        lda     #$00
        sta     $0680,x
        sta     $06A0,x
        jmp     LEF8F

LEFE8:  lda     $2F
        bne     LEF8C
        clc
        rts

        lda     $0420,x
        and     #$BF
        sta     $0420,x
        sec
        lda     $2E
        sbc     $2D
        sta     $00
        bcs     LF00F
        lda     $00
        eor     #$FF
        adc     #$01
        sta     $00
        lda     #$40
        ora     $0420,x
        sta     $0420,x
LF00F:  rts

LF010:  sta     $00
        ldy     #$0F
LF014:  lda     $00
LF016:  cmp     $0410,y
        beq     LF020
        dey
        bpl     LF016
        sec
        rts

LF020:  lda     $0430,y
        bmi     LF02A
        dey
        bpl     LF014
        sec
        rts

LF02A:  clc
        rts

LF02C:  lda     #$00
        sta     $0B
        lda     $0640,x
        php
        bpl     LF03F
        clc
        lda     $04A0,x
        adc     $02
        jmp     LF045

LF03F:  sec
        lda     $04A0,x
        sbc     $02
LF045:  sta     $0A
        clc
        lda     $0460,x
        adc     $01
        sta     jump_ptr
        lda     $0440,x
        adc     #$00
        sta     $09
        cpx     #$0F
        bcs     LF060
        jsr     LCBA2
        jmp     LF063

LF060:  jsr     LCBC3
LF063:  ldy     $00
        lda     LF150,y
        sta     $02
        ldx     $2B
        sec
        lda     $0460,x
        sbc     $01
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
        sta     $09
        cpx     #$0F
        bcs     LF085
        jsr     LCBA2
        jmp     LF088

LF085:  jsr     LCBC3
LF088:  ldx     $2B
        ldy     $00
        lda     LF150,y
        ora     $02
        sta     $00
        beq     LF0CD
        plp
        bmi     LF0A5
        lda     $0A
        and     #$0F
        eor     #$0F
        sec
        adc     $04A0,x
        jmp     LF0B3

LF0A5:  lda     $04A0,x
        pha
        lda     $0A
        and     #$0F
        sta     $02
        pla
        sec
        sbc     $02
LF0B3:  sta     $04A0,x
        lda     #$00
        sta     $04C0,x
        lda     $0420,x
        and     #$04
        beq     LF0CC
        lda     #$C0
        sta     $0660,x
        lda     #$FF
        sta     $0640,x
LF0CC:  rts

LF0CD:  plp
        rts

LF0CF:  lda     $04A0,x
        sta     $0A
        lda     #$00
        sta     $0B
        lda     $0420,x
        and     #$40
        php
        beq     LF0F0
        sec
        lda     $0460,x
        adc     $01
        sta     jump_ptr
        lda     $0440,x
        adc     #$00
        jmp     LF0FD

LF0F0:  clc
        lda     $0460,x
        sbc     $01
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
LF0FD:  sta     $09
        cpx     #$0F
        bcs     LF109
        jsr     LCBA2
        jmp     LF10C

LF109:  jsr     LCBC3
LF10C:  ldx     $2B
        ldy     $00
        lda     LF150,y
        sta     $03
        beq     LF14C
        plp
        beq     LF134
        lda     jump_ptr
        and     #$0F
        sta     $00
        sec
        lda     $0460,x
        sbc     $00
        sta     $0460,x
        lda     $0440,x
        sbc     #$00
        sta     $0440,x
        jmp     LF02C

LF134:  lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     $0460,x
        sta     $0460,x
        lda     $0440,x
        adc     #$00
        sta     $0440,x
        jmp     LF02C

LF14C:  plp
        jmp     LF02C

LF150:  .byte   $00,$01,$00,$01,$00,$01,$01,$01
        .byte   $01
LF159:  pha
        jsr     LDA43
        bcs     LF192
        pla
LF160:  jsr     LD77C
        txa
        tay
        ldx     $2B
        lda     $0420,x
        and     #$40
        ora     $0430,y
        sta     $0430,y
        lda     $0480,x
        sta     $0490,y
        lda     $0460,x
        sta     $0470,y
        lda     $0440,x
        sta     $0450,y
        lda     $04C0,x
        sta     $04D0,y
        lda     $04A0,x
        sta     $04B0,y
        clc
        rts

LF192:  pla
        ldx     $2B
        sec
        rts

        .byte   $A0,$40,$38,$A5,$2D,$E5,$2E,$85
        .byte   $00,$B0,$0A,$A5,$00,$49,$FF,$69
        .byte   $01,$A0,$00,$85,$00
        lda     $0420,x
        and     #$BF
        sta     $0420,x
        tya
        ora     $0420,x
        sta     $0420,x
        sec
        lda     $04A0
        sbc     $04A0,x
        php
        bcs     LF1C9
        eor     #$FF
        adc     #$01
LF1C9:  sta     $01
        cmp     $00
        bcs     LF20A
        lda     $09
        sta     $0D
        sta     $0600,x
        lda     jump_ptr
        sta     $0C
        sta     $0620,x
        lda     $00
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
        jmp     LF242

LF20A:  lda     $09
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
        lda     $00
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     LC874
        ldx     $2B
        lda     $0F
        sta     $0600,x
        lda     $0E
        sta     $0620,x
LF242:  plp
        bcc     LF259
        lda     $0660,x
        eor     #$FF
        adc     #$01
        sta     $0660,x
        lda     $0640,x
        eor     #$FF
        adc     #$00
        sta     $0640,x
LF259:  rts

LF25A:  lda     $B1
        beq     LF25F
        rts

LF25F:  lda     $4A
        sta     $01
        lda     #$64
        sta     $02
        jsr     LC84E
        lda     $CB
        beq     LF2B6
        lda     $04
        cmp     #$30
        bcc     LF288
        cmp     #$49
        bcc     LF289
        cmp     #$58
        bcc     LF28D
        cmp     #$5D
        bcc     LF291
        cmp     #$61
        bcc     LF295
        cmp     #$62
        beq     LF299
LF288:  rts

LF289:  lda     #$79
        bne     LF2A1
LF28D:  lda     #$77
        bne     LF2A1
LF291:  lda     #$78
        bne     LF2A1
LF295:  lda     #$76
        bne     LF2A1
LF299:  lda     #$7B
        bne     LF2A1
        lda     #$7A
        bne     LF2A1
LF2A1:  jsr     LF159
        bcs     LF2B5
        lda     #$84
        sta     $0430,y
        lda     #$02
        sta     $0650,y
        lda     #$01
        sta     $04F0,y
LF2B5:  rts

LF2B6:  lda     $04
        cmp     #$1C
        bcc     LF288
        cmp     #$26
        bcc     LF289
        cmp     #$30
        bcc     LF28D
        cmp     #$4E
        bcc     LF291
        cmp     #$62
        bcc     LF295
        cmp     #$63
        beq     LF299
        rts


; =============================================================================
; Initialization
; =============================================================================
cold_boot_init:                         ; Cold boot: init PPU, switch to bank $0E, start game
        lda     #$10                    ; NMI enable, bg pattern $1000
        sta     $2000                   ; PPUCTRL
        lda     #$06                    ; Show bg+sprites on left edge
        sta     $2001                   ; PPUMASK
        lda     #$0E                    ; Switch to bank $0E (game engine)
        jsr     bank_switch
        jmp     banked_entry            ; Jump to $8000 in bank $0E

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
        .byte   $FF,$FF,$FF,$FF,$FF
LF900:  .byte   $00,$0D,$1A,$27,$34,$38,$3C,$40
        .byte   $44,$4A,$50,$56,$5C,$5F,$62,$65
        .byte   $68,$6D,$72,$77,$7C,$81,$86,$8B
        .byte   $90,$9C,$A4,$AB,$AF,$B3,$B3,$B7
        .byte   $BB,$BF,$BF,$C3,$C6,$CC,$D2,$D8
        .byte   $D8,$D8,$D8,$D8,$D8
        cld
        cld
        cld
        .byte   $DF,$EB,$F0,$F9,$FE,$04,$0C,$10
        .byte   $1B,$2A,$36,$47,$4C,$4F,$56,$56
        .byte   $5E,$5E,$5E,$5E,$5E,$5E,$5E,$5E
        .byte   $5E,$5E,$5E,$5E,$5E,$5E,$5E,$5E
        .byte   $5E,$70,$76,$86
        txa
        stx     $9A,y
        .byte   $9E,$A2,$A8,$AC,$B6,$BB,$BF,$C2
        .byte   $C6,$D1,$D9
        cmp     LEDE5,x
        .byte   $F3,$F8,$0A,$10,$13,$19,$1F,$24
        .byte   $32,$36,$3D,$43,$47,$4B,$4F,$53
        .byte   $58,$5C,$62,$66,$69,$6D,$70,$74
        sei
        sei
        sei
LF980:  sei
        .byte   $82,$8C,$8C,$8C,$90,$90,$97,$97
        .byte   $9B,$9B,$A3,$A6,$B5,$B9,$BD,$C1
        .byte   $C8,$C8,$CC,$CF,$CF,$D2,$DD,$E3
        .byte   $E6,$F1,$FA,$FE,$04,$10,$10,$16
        .byte   $16,$16,$1E,$26,$26,$26,$26,$26
        .byte   $2A,$2E,$32,$32,$40,$40,$40,$43
        .byte   $46,$58,$58,$5B,$63,$66
        adc     $7979,y
        .byte   $7F,$82,$85,$89,$90,$94,$97,$97
        .byte   $97,$97,$9B,$9E,$A3,$AB,$AB,$B0
        .byte   $B5,$B5,$B5,$63,$C2,$C8,$CC,$CF
        .byte   $CC,$E1,$E1,$E1,$E9,$40,$E9,$EE
        .byte   $F4,$F9,$FD,$01,$06,$0D,$14,$1A
        .byte   $20,$27,$27,$2A,$2E,$FE,$32,$36
        .byte   $39,$42,$46,$49,$52,$63
        eor     $59,x
        eor     $675D,x
        adc     $716D
        adc     $79,x
        adc     $8481,x
        sty     $84
        .byte   $87
LFA00:  .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
LFA80:  .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FD
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $0A,$08,$04,$04,$04,$04,$04,$04
        .byte   $04,$04,$04,$04,$05,$0A,$08,$09
        .byte   $09,$09,$09,$09,$09,$09,$09,$09
        .byte   $09,$09,$0A,$08,$10,$10,$10,$10
        .byte   $10,$10,$10,$10,$10,$10,$11,$0A
        .byte   $08,$20,$20,$20,$20,$20
        jsr     L2020
        jsr     L2020
        ora     ($05,x)
        asl     $06
        ora     ($05,x)
        ora     #$09
        ora     ($05,x)
        .byte   $12
        .byte   $12,$01,$05,$20,$20,$03,$06,$01
        .byte   $03,$02,$03,$03,$06,$0A,$0C,$0B
        .byte   $0C,$03,$06,$0D,$0F,$0E,$0F,$03
        .byte   $06,$20,$20,$20,$20,$00,$00,$08
        .byte   $00,$00,$14,$00,$00,$13,$00,$00
        .byte   $1E,$02,$03,$06,$06,$06,$02,$03
        .byte   $09,$09,$09,$02,$03,$12,$12,$12
        .byte   $02,$06,$20,$20,$20,$02,$01,$02
        .byte   $04,$04,$02,$01,$0B,$09,$09,$02
        .byte   $01,$0E,$10,$10,$02,$01,$20,$20
        .byte   $20,$09,$02,$18,$07,$07,$18,$07
        .byte   $07,$18,$07,$07
        clc
        ora     $07
        .byte   $1A,$1A,$1A,$1A,$1A,$1A,$04,$02
        .byte   $1B,$1C,$1D,$1B,$1B,$01,$08,$15
        .byte   $16,$01,$08,$19,$19,$01,$08,$1F
        .byte   $1F,$01,$0A,$17,$21,$01,$0A,$19
        .byte   $19,$01,$0A,$1F,$1F,$00,$00,$22
        .byte   $03,$08,$23,$24,$25,$00,$03,$01
        .byte   $26,$27,$28,$29,$03,$02,$1B,$1D
        .byte   $1C,$1B,$04,$02,$39,$3A,$3B,$3C
        .byte   $00,$09,$03,$2F,$4D,$4E,$4D,$4F
        .byte   $50,$4F,$51,$52,$51,$02,$01,$3D
        .byte   $3E,$3F,$06,$03,$53,$56,$58,$57
        .byte   $59,$56,$2E,$02,$05
        pha
        eor     #$4A
        .byte   $03,$03,$44,$45,$46,$47,$05,$06
        .byte   $2A,$2B,$2C,$2D,$2C,$2E,$01,$04
        .byte   $4B,$4C,$08,$06,$30,$31,$32,$33
        .byte   $34,$35,$36,$37,$38,$0C,$02,$5A
        .byte   $5B,$5A,$5A,$2E,$5B,$2E,$5A,$39
        .byte   $3A,$3B,$3C,$00,$09,$02,$5C,$5C
        .byte   $5D,$5D,$5C,$39,$3A,$3B,$3C,$00
        .byte   $0E,$02,$5E,$5E,$5F,$5F,$5E,$5E
        .byte   $2E,$5F,$2E,$5E,$39,$3A,$3B,$3C
        .byte   $00,$02,$03,$57,$54,$55,$00,$00
        .byte   $44,$04,$03,$40,$41,$42,$43,$00
        .byte   $05,$04,$C3,$C4,$C5,$C6,$C6,$00
        .byte   $0F,$02,$65,$62,$62,$61,$61,$60
        .byte   $63,$64,$63,$64,$63,$64,$63,$64
        .byte   $63,$60,$03,$06,$60,$66,$67,$67
        .byte   $0D,$02,$63,$64,$63,$68,$69,$6A
        .byte   $6B,$6C,$6D,$6B,$6A,$69,$68,$62
        .byte   $01,$12,$62,$62,$09,$05,$7C,$6E
        .byte   $6F,$70,$71,$72,$73,$74,$75,$70
        .byte   $01,$06,$7C,$7B,$01,$10,$76,$76
        .byte   $01,$7E,$77,$77,$03,$05,$78,$7A
        .byte   $79,$7A,$01,$24,$7C,$7C,$07,$06
        .byte   $84,$7D,$7E,$7F,$80,$81,$82,$7F
        .byte   $02,$10,$7D,$83,$83,$01,$08,$86
        .byte   $87,$00,$00,$84,$01,$12,$85,$85
        .byte   $08,$06,$88,$89,$8A,$8B,$8C,$8D
        .byte   $8E,$8F,$90,$05,$08,$91,$91,$91
        .byte   $91,$92,$93,$01,$08
        sta     ($96),y
        ora     $05
        sty     $95,x
        sty     $97,x
        tya
        .byte   $97,$05,$08,$9C,$99,$99,$99,$9A
        .byte   $9B,$03,$06,$9F,$A0,$A1,$A0,$02
        .byte   $08,$9C
        sta     $0F9E,x
        .byte   $03,$A5
        ldx     #$A3
        ldy     $A3
        ldy     $A2
        .byte   $A3,$A4,$A3,$A4,$A2,$A3,$A4,$A3
        .byte   $A2,$03,$03,$A6,$A3,$A4,$A3,$00
        .byte   $00,$A5,$03,$08,$AA,$A7,$A8,$A9
        .byte   $03,$06,$AD,$AE,$AF,$AE,$02,$06
        .byte   $AA,$AB,$AC,$0B,$06,$B4,$B3,$B0
        .byte   $B1,$B2,$B1,$B2,$B1,$B2,$B1,$B2
        .byte   $B0,$01,$06
        lda     ($B2),y
        .byte   $04,$06,$B0,$B3,$B4,$B3,$B0,$03
        .byte   $08,$B0,$B5
        ldx     $B0,y
        ora     ($18,x)
        .byte   $B7,$B8,$01,$08,$B9,$BA,$01,$02
        .byte   $BC,$BD,$01,$04,$BE,$BF,$02,$06
        .byte   $C0,$C1,$C2,$01,$04,$C7,$C8,$03
        .byte   $1C,$C9,$CA,$CB,$CC,$01,$05,$CC
        .byte   $CD,$00,$00,$BB,$01,$06,$CE,$CF
        .byte   $00,$00,$D0,$01,$0C,$D2,$D1,$01
        .byte   $08,$D3,$D4,$07,$02,$45,$45,$46
        .byte   $46,$45,$47,$45,$48,$07,$02,$45
        .byte   $45,$46,$46,$45,$47,$45,$48,$01
        .byte   $05,$39,$3A,$04,$02,$79,$7A,$7B
        .byte   $7C,$00,$01,$06,$69,$6A,$05,$05
        .byte   $61,$62,$61,$63,$64,$63,$00,$00
        .byte   $7D,$0C,$06,$3E,$3F,$3E,$3F,$3E
        .byte   $3F,$3E,$40,$3E,$41,$42,$42,$41
        .byte   $01,$02,$44,$43,$01,$04,$7E,$7F
        .byte   $01,$08,$80,$81,$04,$08,$82,$83
        .byte   $82,$83,$82,$01,$06,$84,$85,$00
        .byte   $00,$86,$00,$00,$87,$08,$04,$2C
        .byte   $2C,$2D,$2E,$2F,$30,$31,$32,$30
        .byte   $03,$04,$3B,$3C
        and     a:$3C,x
        brk
        .byte   $88,$08,$06,$89,$8A,$89,$8B,$8C
        .byte   $89,$8B,$8C,$89,$06,$04,$8D,$8E
        .byte   $8D,$8E,$8D,$8E,$8D,$01,$04,$8F
        bcc     LFE02
        brk
        .byte   $91,$92
LFE02:  .byte   $93,$93,$09,$0A,$22,$20,$20,$1F
        .byte   $1E,$1D,$1E,$1F,$21,$22,$03,$04
        .byte   $01,$02,$03,$02,$05,$06,$04,$05
        .byte   $06,$07,$08,$09,$05,$06,$71,$72
        .byte   $71,$74,$73,$73,$01,$04,$75,$76
        .byte   $01,$06,$13,$14,$01,$08,$11,$12
        .byte   $0B,$04,$0D,$0E,$0F,$0D,$0E,$0F
        .byte   $0D,$0E,$0F,$10,$0F,$10,$00,$00
        .byte   $94,$00,$00,$65,$0F,$06,$6B,$6C
        .byte   $6B,$6D,$6B,$6C,$6B,$6D,$6E,$6C
        .byte   $6B,$6D,$6D,$6F,$66,$66,$00,$00
        .byte   $70,$05,$06,$5D,$5E,$5E,$5F,$60
        .byte   $5F,$00,$00,$95,$10,$03,$29,$2A
        .byte   $2B,$2A,$2B,$2A,$2B,$2A,$2B,$2A
        .byte   $2B,$2A,$2B,$2A,$2B,$2A,$2B,$03
        .byte   $04,$15,$16,$15,$17,$00,$00,$18
        .byte   $00,$00,$19,$01,$04,$1B,$1C,$04
        .byte   $08,$23,$24,$23,$25,$25,$01,$03
        .byte   $27,$28,$00,$00,$26,$01,$08,$96
        .byte   $97,$00,$00,$98,$02,$08,$0A,$0B
        .byte   $0C,$05,$04,$99,$9A,$9B,$9C,$9D
        .byte   $9A,$02,$0A,$49,$4A,$4B,$02,$0A
        .byte   $4C,$4D,$4E,$0A,$04,$57,$58,$59
        .byte   $5A,$5B,$5C,$5B,$5A,$59,$58,$57
        .byte   $03,$08,$52,$53,$54,$53,$01,$04
        .byte   $55,$56,$00,$00,$9E,$0F,$02,$9F
        .byte   $9F,$A0,$A0,$A2,$A2,$A1,$A1,$A3
        .byte   $A3,$A1,$79,$7A,$7B,$7C,$00,$05
        .byte   $06,$A4,$A5,$A6,$A7,$A8,$A5,$02
        .byte   $04,$B4,$B5,$B6,$03,$03,$B7,$B8
        .byte   $B9,$BA,$02,$04,$BB,$BC
        lda     $0401,x
        ldx     $01BF,y
        .byte   $03
        cpy     #$C1
        .byte   $02
        ora     ($C2,x)
        .byte   $C3,$C4,$06,$04
        cmp     $C6
        .byte   $C7,$C8,$C7,$04,$00,$79,$7A,$7B
        .byte   $7C,$00,$03,$01,$79,$7A,$7B,$7C
        .byte   $03,$03,$C9,$CA,$CB,$CC,$04,$02
        .byte   $CD,$CE,$CF,$D0,$D1,$00,$00,$D2
        .byte   $01,$02,$D3,$D4,$01,$05,$D6,$D5
        .byte   $01,$03,$D7,$D8,$00,$00,$D9,$06
        .byte   $04,$33,$34,$35,$36,$37,$38,$37
        .byte   $01,$02,$7A,$79,$00,$00,$68,$06
        .byte   $04,$4F,$50,$51,$DA,$DA,$DB,$DA
        .byte   $00,$00,$DC,$01,$04,$DD,$DE,$01
        .byte   $08,$77,$78,$07,$04,$DF,$E0,$DF
        .byte   $E1,$E2,$E2,$E3,$E1,$03,$05,$E6
        .byte   $E4,$E5,$00,$01,$04,$A9,$AA,$01
        .byte   $04,$AB,$AC,$01,$04,$AD,$AE,$01
        .byte   $04,$AF,$B0,$01,$04
        lda     ($B2),y
        brk
        .byte   $00,$B3,$00,$00,$67,$FF,$FF,$FF
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
        .byte   $FF,$FF,$FF,$FF,$FF,$FF

; =============================================================================
; Reset Handler & Vectors
; =============================================================================
reset_handler:                          ; Reset vector entry point
        sei                             ; Disable interrupts
LFFE1:  inc     LFFE1                   ; Self-modifying: resets MMC1 shift register
        jmp     cold_boot_init          ; Jump to initialization

        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF                     ; Padding
mmc1_scratch:                           ; $FFF0: MMC1 write target (any ROM addr works)
        .byte   $78,$E9,$00,$00,$48,$04,$00,$00
        .byte   $08,$AC
; Interrupt vectors
        .addr   nmi_handler             ; $FFFA: NMI vector
        .addr   reset_handler           ; $FFFC: Reset vector
        .addr   reset_handler           ; $FFFE: IRQ vector (same as reset)
