.segment "BANK05"

; =============================================================================
; Bank $05 — Flash Man (stage $05) + Wily 6 (stage $0D) Stage Data
; Selected via current_stage AND #$07. Holds this stage pair's metatiles,
; screen layouts, spawns, checkpoints, CHR upload lists and palettes
; (format: DATA_REFERENCE §6). CHR pattern data regions in this bank are
; shared across stages via explicit (bank, page) reference lists.
; =============================================================================

        .setcpu "6502"

; =============================================================================
; metatile_defs — 256 metatiles × 4 quadrant bytes (TL, BL, TR, BR) ($8000)
; Quadrant byte = [collision:2][tile group:6]; group G → CHR tiles G*4..G*4+3.
; Collision: 0=empty, 1=solid, 2/3=stage-specific (stage_collision_table).
; =============================================================================
metatile_defs:
        .byte   $00,$00,$00,$00 ; metatile $00
        .byte   $19,$1A,$1A,$19 ; metatile $01
        .byte   $18,$1A,$18,$19 ; metatile $02
        .byte   $18,$19,$18,$19 ; metatile $03
        .byte   $19,$1A,$18,$19 ; metatile $04
        .byte   $18,$1A,$1A,$19 ; metatile $05
        .byte   $19,$19,$18,$19 ; metatile $06
        .byte   $18,$19,$19,$19 ; metatile $07
        .byte   $19,$DF,$19,$E2 ; metatile $08
        .byte   $19,$E4,$19,$DF ; metatile $09
        .byte   $19,$E2,$19,$E4 ; metatile $0A
        .byte   $19,$E2,$19,$E3 ; metatile $0B
        .byte   $19,$E3,$19,$E3 ; metatile $0C
        .byte   $19,$E3,$19,$E4 ; metatile $0D
        .byte   $19,$DF,$19,$DF ; metatile $0E
        .byte   $19,$19,$19,$19 ; metatile $0F
        .byte   $19,$DF,$19,$E2 ; metatile $10
        .byte   $19,$E4,$19,$DF ; metatile $11
        .byte   $19,$E2,$19,$E4 ; metatile $12
        .byte   $19,$E2,$19,$E3 ; metatile $13
        .byte   $19,$E3,$19,$E3 ; metatile $14
        .byte   $19,$E3,$19,$E4 ; metatile $15
        .byte   $19,$DF,$19,$DF ; metatile $16
        .byte   $19,$19,$DF,$18 ; metatile $17
        .byte   $19,$DF,$19,$E2 ; metatile $18
        .byte   $19,$E4,$19,$DF ; metatile $19
        .byte   $19,$E2,$19,$E4 ; metatile $1A
        .byte   $19,$E2,$19,$E3 ; metatile $1B
        .byte   $19,$E3,$19,$E3 ; metatile $1C
        .byte   $19,$E3,$19,$E4 ; metatile $1D
        .byte   $19,$DF,$19,$DF ; metatile $1E
        .byte   $DF,$18,$19,$19 ; metatile $1F
        .byte   $DF,$18,$E2,$18 ; metatile $20
        .byte   $E4,$18,$DF,$18 ; metatile $21
        .byte   $E2,$18,$E4,$18 ; metatile $22
        .byte   $E2,$18,$E3,$18 ; metatile $23
        .byte   $E3,$18,$E3,$18 ; metatile $24
        .byte   $E3,$18,$E4,$18 ; metatile $25
        .byte   $DF,$18,$DF,$18 ; metatile $26
        .byte   $19,$19,$19,$DF ; metatile $27
        .byte   $DF,$18,$E2,$18 ; metatile $28
        .byte   $E4,$18,$DF,$18 ; metatile $29
        .byte   $E2,$18,$E4,$18 ; metatile $2A
        .byte   $E2,$18,$E3,$18 ; metatile $2B
        .byte   $E3,$18,$E3,$18 ; metatile $2C
        .byte   $E3,$18,$E4,$18 ; metatile $2D
        .byte   $DF,$18,$DF,$18 ; metatile $2E
        .byte   $19,$19,$19,$DF ; metatile $2F
        .byte   $DF,$18,$E2,$18 ; metatile $30
        .byte   $E4,$18,$DF,$18 ; metatile $31
        .byte   $E2,$18,$E4,$18 ; metatile $32
        .byte   $E2,$18,$E3,$18 ; metatile $33
        .byte   $E3,$18,$E3,$18 ; metatile $34
        .byte   $E3,$18,$E4,$18 ; metatile $35
        .byte   $DF,$18,$DF,$18 ; metatile $36
        .byte   $19,$DF,$19,$19 ; metatile $37
        .byte   $EA,$EC,$18,$19 ; metatile $38
        .byte   $18,$19,$EA,$EC ; metatile $39
        .byte   $E2,$18,$E4,$DF ; metatile $3A
        .byte   $DF,$18,$EA,$EC ; metatile $3B
        .byte   $E2,$DF,$E4,$18 ; metatile $3C
        .byte   $EA,$EC,$DF,$18 ; metatile $3D
        .byte   $19,$DF,$19,$19 ; metatile $3E
        .byte   $19,$19,$DF,$18 ; metatile $3F
        .byte   $19,$19,$49,$4A ; metatile $40
        .byte   $18,$19,$08,$08 ; metatile $41
        .byte   $19,$19,$DF,$EA ; metatile $42
        .byte   $19,$19,$DF,$EA ; metatile $43
        .byte   $19,$19,$DF,$EA ; metatile $44
        .byte   $DF,$EA,$19,$19 ; metatile $45
        .byte   $DF,$EA,$19,$19 ; metatile $46
        .byte   $DF,$EA,$19,$19 ; metatile $47
        .byte   $19,$19,$49,$49 ; metatile $48
        .byte   $47,$4C,$47,$4D ; metatile $49
        .byte   $19,$19,$EC,$DF ; metatile $4A
        .byte   $19,$19,$EC,$DF ; metatile $4B
        .byte   $19,$19,$EC,$DF ; metatile $4C
        .byte   $EC,$DF,$19,$19 ; metatile $4D
        .byte   $EC,$DF,$19,$19 ; metatile $4E
        .byte   $EC,$DF,$19,$19 ; metatile $4F
        .byte   $4E,$4B,$4F,$4B ; metatile $50
        .byte   $19,$19,$08,$08 ; metatile $51
        .byte   $19,$19,$EA,$EC ; metatile $52
        .byte   $19,$19,$EA,$EC ; metatile $53
        .byte   $19,$19,$EA,$EC ; metatile $54
        .byte   $EA,$EC,$19,$19 ; metatile $55
        .byte   $EA,$EC,$19,$19 ; metatile $56
        .byte   $EA,$EC,$19,$19 ; metatile $57
        .byte   $E2,$18,$E4,$1B ; metatile $58
        .byte   $19,$19,$1C,$1C ; metatile $59
        .byte   $19,$19,$EA,$EB ; metatile $5A
        .byte   $19,$19,$EA,$EB ; metatile $5B
        .byte   $19,$19,$EA,$EB ; metatile $5C
        .byte   $EA,$EB,$19,$19 ; metatile $5D
        .byte   $EA,$EB,$19,$19 ; metatile $5E
        .byte   $EA,$EB,$19,$19 ; metatile $5F
        .byte   $E4,$1B,$DF,$18 ; metatile $60
        .byte   $1C,$1C,$19,$19 ; metatile $61
        .byte   $19,$19,$EB,$EB ; metatile $62
        .byte   $19,$19,$EB,$EB ; metatile $63
        .byte   $19,$19,$EB,$EB ; metatile $64
        .byte   $EB,$EB,$19,$19 ; metatile $65
        .byte   $EB,$EB,$19,$19 ; metatile $66
        .byte   $EB,$EB,$19,$19 ; metatile $67
        .byte   $19,$E4,$1C,$DF ; metatile $68
        .byte   $18,$19,$1B,$1C ; metatile $69
        .byte   $19,$19,$EB,$EC ; metatile $6A
        .byte   $19,$19,$EB,$EC ; metatile $6B
        .byte   $19,$19,$EB,$EC ; metatile $6C
        .byte   $EB,$EC,$19,$19 ; metatile $6D
        .byte   $EB,$EC,$19,$19 ; metatile $6E
        .byte   $EB,$EC,$19,$19 ; metatile $6F
        .byte   $1C,$E2,$1C,$E4 ; metatile $70
        .byte   $1B,$1C,$18,$19 ; metatile $71
        .byte   $19,$19,$DF,$DF ; metatile $72
        .byte   $19,$19,$DF,$DF ; metatile $73
        .byte   $19,$19,$DF,$DF ; metatile $74
        .byte   $DF,$DF,$19,$19 ; metatile $75
        .byte   $DF,$DF,$19,$19 ; metatile $76
        .byte   $DF,$DF,$19,$19 ; metatile $77
        .byte   $DF,$E2,$19,$E3 ; metatile $78
        .byte   $19,$DF,$EA,$EC ; metatile $79
        .byte   $18,$19,$DF,$19 ; metatile $7A
        .byte   $DF,$19,$18,$19 ; metatile $7B
        .byte   $EA,$EC,$19,$DF ; metatile $7C
        .byte   $18,$1E,$18,$1E ; metatile $7D
        .byte   $EB,$EC,$19,$DF ; metatile $7E
        .byte   $19,$DF,$EB,$EC ; metatile $7F
        .byte   $00,$40,$00,$40 ; metatile $80
        .byte   $64,$66,$65,$67 ; metatile $81
        .byte   $64,$67,$65,$66 ; metatile $82
        .byte   $64,$67,$61,$63 ; metatile $83
        .byte   $60,$62,$65,$66 ; metatile $84
        .byte   $64,$66,$61,$63 ; metatile $85
        .byte   $60,$62,$65,$67 ; metatile $86
        .byte   $28,$28,$28,$28 ; metatile $87
        .byte   $2A,$2A,$2A,$2A ; metatile $88
        .byte   $29,$2A,$29,$2A ; metatile $89
        .byte   $2A,$2A,$2A,$65 ; metatile $8A
        .byte   $2A,$64,$2A,$65 ; metatile $8B
        .byte   $66,$29,$67,$29 ; metatile $8C
        .byte   $29,$2A,$67,$29 ; metatile $8D
        .byte   $29,$2A,$08,$08 ; metatile $8E
        .byte   $2A,$2A,$08,$08 ; metatile $8F
        .byte   $2A,$66,$65,$67 ; metatile $90
        .byte   $64,$29,$65,$29 ; metatile $91
        .byte   $6B,$00,$6B,$00 ; metatile $92
        .byte   $61,$63,$64,$67 ; metatile $93
        .byte   $65,$66,$60,$62 ; metatile $94
        .byte   $00,$00,$2C,$00 ; metatile $95
        .byte   $00,$6C,$00,$40 ; metatile $96
        .byte   $2C,$40,$00,$40 ; metatile $97
        .byte   $C5,$4E,$17,$4E ; metatile $98
        .byte   $17,$4E,$17,$4E ; metatile $99
        .byte   $17,$4E,$17,$C5 ; metatile $9A
        .byte   $16,$17,$C5,$C5 ; metatile $9B
        .byte   $17,$4E,$C5,$4E ; metatile $9C
        .byte   $17,$C5,$17,$4E ; metatile $9D
        .byte   $38,$3A,$39,$3B ; metatile $9E
        .byte   $17,$AE,$17,$AE ; metatile $9F
        .byte   $19,$E0,$19,$E3 ; metatile $A0
        .byte   $E8,$19,$E4,$19 ; metatile $A1
        .byte   $DF,$1B,$E2,$1B ; metatile $A2
        .byte   $1C,$1C,$1C,$1C ; metatile $A3
        .byte   $00,$06,$09,$07 ; metatile $A4
        .byte   $17,$17,$48,$50 ; metatile $A5
        .byte   $00,$00,$00,$00 ; metatile $A6
        .byte   $01,$01,$05,$01 ; metatile $A7
        .byte   $01,$01,$01,$01 ; metatile $A8
        .byte   $01,$01,$01,$02 ; metatile $A9
        .byte   $01,$03,$01,$03 ; metatile $AA
        .byte   $01,$04,$01,$01 ; metatile $AB
        .byte   $01,$01,$08,$08 ; metatile $AC
        .byte   $09,$09,$01,$01 ; metatile $AD
        .byte   $01,$01,$08,$05 ; metatile $AE
        .byte   $00,$06,$00,$06 ; metatile $AF
        .byte   $09,$07,$01,$01 ; metatile $B0
        .byte   $02,$08,$03,$00 ; metatile $B1
        .byte   $03,$00,$03,$00 ; metatile $B2
        .byte   $04,$09,$01,$01 ; metatile $B3
        .byte   $08,$08,$00,$00 ; metatile $B4
        .byte   $05,$01,$06,$01 ; metatile $B5
        .byte   $06,$01,$06,$01 ; metatile $B6
        .byte   $07,$01,$01,$01 ; metatile $B7
        .byte   $0A,$0A,$0A,$0A ; metatile $B8
        .byte   $0A,$0A,$0C,$0C ; metatile $B9
        .byte   $0A,$0B,$0A,$0B ; metatile $BA
        .byte   $0A,$0B,$0C,$0D ; metatile $BB
        .byte   $01,$02,$01,$03 ; metatile $BC
        .byte   $01,$03,$01,$04 ; metatile $BD
        .byte   $00,$00,$09,$09 ; metatile $BE
        .byte   $06,$01,$07,$01 ; metatile $BF
        .byte   $01,$01,$01,$01 ; metatile $C0
        .byte   $03,$04,$01,$05 ; metatile $C1
        .byte   $01,$06,$01,$07 ; metatile $C2
        .byte   $08,$09,$0A,$0B ; metatile $C3
        .byte   $16,$18,$17,$0F ; metatile $C4
        .byte   $10,$0C,$11,$0D ; metatile $C5
        .byte   $12,$0E,$13,$0F ; metatile $C6
        .byte   $14,$0D,$15,$0D ; metatile $C7
        .byte   $19,$20,$19,$21 ; metatile $C8
        .byte   $1A,$22,$1B,$23 ; metatile $C9
        .byte   $1C,$1F,$1D,$1F ; metatile $CA
        .byte   $1F,$24,$1F,$25 ; metatile $CB
        .byte   $1F,$26,$1F,$24 ; metatile $CC
        .byte   $1F,$24,$1F,$24 ; metatile $CD
        .byte   $27,$2E,$28,$2F ; metatile $CE
        .byte   $29,$31,$2A,$31 ; metatile $CF
        .byte   $25,$26,$2D,$27 ; metatile $D0
        .byte   $26,$26,$27,$27 ; metatile $D1
        .byte   $25,$26,$08,$08 ; metatile $D2
        .byte   $26,$26,$08,$08 ; metatile $D3
        .byte   $EA,$EC,$2D,$27 ; metatile $D4
        .byte   $25,$26,$27,$27 ; metatile $D5
        .byte   $DF,$EA,$27,$27 ; metatile $D6
        .byte   $EC,$DF,$27,$27 ; metatile $D7
        .byte   $25,$26,$EA,$EC ; metatile $D8
        .byte   $26,$26,$EA,$EB ; metatile $D9
        .byte   $26,$26,$EC,$DF ; metatile $DA
        .byte   $26,$E3,$DF,$E4 ; metatile $DB
        .byte   $26,$26,$EB,$EC ; metatile $DC
        .byte   $26,$26,$27,$E2 ; metatile $DD
        .byte   $26,$E4,$27,$27 ; metatile $DE
        .byte   $26,$26,$27,$E2 ; metatile $DF
        .byte   $26,$E4,$E2,$DF ; metatile $E0
        .byte   $E4,$1B,$DF,$1B ; metatile $E1
        .byte   $EA,$EB,$27,$E2 ; metatile $E2
        .byte   $26,$E4,$E2,$DF ; metatile $E3
        .byte   $E4,$18,$EA,$EC ; metatile $E4
        .byte   $19,$E4,$EA,$EB ; metatile $E5
        .byte   $18,$1A,$EB,$EC ; metatile $E6
        .byte   $EB,$EC,$18,$E2 ; metatile $E7
        .byte   $18,$E3,$18,$E3 ; metatile $E8
        .byte   $01,$01,$02,$08 ; metatile $E9
        .byte   $03,$00,$04,$09 ; metatile $EA
        .byte   $08,$05,$00,$06 ; metatile $EB
        .byte   $00,$00,$00,$00 ; metatile $EC
        .byte   $00,$2C,$00,$00 ; metatile $ED
        .byte   $2C,$00,$00,$00 ; metatile $EE
        .byte   $00,$00,$00,$2C ; metatile $EF
        .byte   $2B,$31,$2C,$31 ; metatile $F0
        .byte   $32,$31,$32,$31 ; metatile $F1
        .byte   $32,$31,$32,$34 ; metatile $F2
        .byte   $35,$30,$35,$24 ; metatile $F3
        .byte   $35,$2E,$36,$2F ; metatile $F4
        .byte   $37,$31,$2F,$31 ; metatile $F5
        .byte   $31,$34,$31,$31 ; metatile $F6
        .byte   $31,$33,$34,$31 ; metatile $F7
        .byte   $31,$34,$34,$33 ; metatile $F8
        .byte   $33,$34,$31,$34 ; metatile $F9
        .byte   $2E,$31,$2F,$31 ; metatile $FA
        .byte   $1E,$21,$29,$1F ; metatile $FB
        .byte   $01,$01,$01,$02 ; metatile $FC
        .byte   $34,$31,$33,$31 ; metatile $FD
        .byte   $1E,$20,$29,$21 ; metatile $FE
        .byte   $19,$20,$19,$20 ; metatile $FF

; =============================================================================
; metatile_attrs — palette attribute byte per metatile ($8400)
; =============================================================================
metatile_attrs:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; $00-$07
        .byte   $90,$E0,$50,$50,$50,$50,$90,$00 ; $08-$0F
        .byte   $70,$90,$F0,$F0,$F0,$F0,$70,$0C ; $10-$17
        .byte   $E0,$70,$A0,$A0,$A0,$A0,$E0,$02 ; $18-$1F
        .byte   $09,$0E,$05,$05,$05,$05,$09,$80 ; $20-$27
        .byte   $07,$09,$0F,$0F,$0F,$0F,$07,$C0 ; $28-$2F
        .byte   $0E,$07,$0A,$0A,$0A,$0A,$0E,$10 ; $30-$37
        .byte   $33,$88,$CA,$CE,$25,$3B,$30,$04 ; $38-$3F
        .byte   $44,$44,$C8,$84,$4C,$32,$21,$13 ; $40-$47
        .byte   $44,$55,$4C,$C8,$84,$13,$32,$21 ; $48-$4F
        .byte   $55,$44,$88,$44,$CC,$22,$11,$33 ; $50-$57
        .byte   $05,$00,$88,$44,$CC,$22,$11,$33 ; $58-$5F
        .byte   $0E,$00,$88,$44,$CC,$22,$11,$33 ; $60-$67
        .byte   $E0,$00,$88,$44,$CC,$22,$11,$33 ; $68-$6F
        .byte   $F0,$00,$C8,$84,$4C,$32,$21,$13 ; $70-$77
        .byte   $A1,$64,$08,$03,$E2,$00,$E2,$DC ; $78-$7F
        .byte   $00,$00,$00,$00,$00,$00,$00,$FF ; $80-$87
        .byte   $55,$55,$15,$05,$50,$51,$99,$99 ; $88-$8F
        .byte   $01,$50,$0A,$00,$00,$08,$20,$02 ; $90-$97
        .byte   $F8,$FA,$3A,$22,$F2,$CA,$00,$0A ; $98-$9F
        .byte   $50,$05,$0E,$00,$01,$EE,$55,$00 ; $A0-$A7
        .byte   $00,$00,$00,$00,$00,$00,$00,$05 ; $A8-$AF
        .byte   $00,$40,$50,$00,$44,$00,$00,$00 ; $B0-$B7
        .byte   $55,$55,$55,$55,$00,$00,$11,$00 ; $B8-$BF
        .byte   $00,$00,$00,$00,$90,$90,$A0,$A0 ; $C0-$C7
        .byte   $AA,$A5,$AA,$6A,$9A,$AA,$AA,$AA ; $C8-$CF
        .byte   $00,$00,$44,$44,$33,$00,$21,$32 ; $D0-$D7
        .byte   $88,$44,$84,$5C,$44,$40,$10,$80 ; $D8-$DF
        .byte   $6C,$0B,$B3,$6C,$8B,$DC,$CC,$73 ; $E0-$E7
        .byte   $50,$00,$10,$04,$00,$20,$02,$80 ; $E8-$EF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $F0-$F7
        .byte   $FF,$FF,$AA,$FF,$00,$FF,$AA,$AA ; $F8-$FF

; =============================================================================
; screen_layouts — 64-byte rooms, column-major 8×8 metatile IDs ($8500)
; ptr = $8500 + screen × $40. Rooms are consumed in virtual-screen order;
; checkpoint tables give each stage's range:
;   Flash Man rooms $00-$12+, Wily 6 rooms $16-$16+
; Each row below = one 8-metatile column (left to right).
; =============================================================================
screen_layouts:
; ─── screen $00 ($8500) — Flash Man rooms ───
        .byte   $08,$38,$5E,$4F,$57,$23,$21,$0F
        .byte   $1D,$02,$01,$01,$01,$25,$58,$59
        .byte   $70,$02,$01,$01,$01,$30,$3A,$53
        .byte   $0A,$02,$01,$01,$01,$2D,$28,$0F
        .byte   $18,$02,$01,$01,$01,$58,$25,$0F
        .byte   $14,$02,$01,$01,$01,$33,$3B,$52
        .byte   $19,$02,$01,$01,$01,$60,$58,$59
        .byte   $1A,$02,$01,$01,$01,$20,$36,$0F
; ─── screen $01 ($8540) — Flash Man rooms ───
        .byte   $3E,$3C,$3D,$78,$02,$35,$58,$59
        .byte   $59,$2B,$58,$68,$02,$22,$3B,$5A
        .byte   $52,$31,$2B,$0B,$02,$2B,$23,$0F
        .byte   $0F,$33,$31,$11,$02,$31,$25,$0F
        .byte   $0F,$21,$3A,$79,$02,$32,$36,$0F
        .byte   $59,$23,$26,$1B,$02,$28,$3A,$5B
        .byte   $54,$24,$58,$68,$02,$25,$2B,$0F
        .byte   $61,$29,$3A,$79,$02,$36,$2D,$0F
; ─── screen $02 ($8580) — Flash Man rooms ───
        .byte   $59,$2A,$28,$01,$01,$23,$58,$59
        .byte   $6B,$33,$25,$1B,$03,$25,$45,$67
        .byte   $59,$60,$30,$09,$03,$75,$78,$03
        .byte   $59,$23,$2D,$10,$03,$17,$09,$71
        .byte   $61,$29,$22,$0D,$03,$33,$0B,$03
        .byte   $0F,$2B,$30,$1A,$03,$21,$0D,$38
        .byte   $0F,$31,$2C,$10,$03,$22,$18,$69
        .byte   $2F,$3A,$31,$0C,$03,$30,$14,$69
; ─── screen $03 ($85C0) — Flash Man rooms ───
        .byte   $0B,$03,$0F,$11,$03,$2C,$19,$39
        .byte   $11,$03,$22,$13,$03,$31,$18,$03
        .byte   $12,$03,$30,$19,$03,$32,$14,$71
        .byte   $08,$03,$2D,$3E,$07,$23,$19,$03
        .byte   $1C,$03,$3A,$53,$06,$24,$1A,$69
        .byte   $09,$03,$30,$12,$03,$29,$16,$39
        .byte   $0B,$03,$2D,$08,$03,$30,$12,$03
        .byte   $0D,$03,$58,$68,$03,$2C,$08,$03
; ─── screen $04 ($8600) — Flash Man rooms ───
        .byte   $1B,$03,$36,$0A,$03,$31,$1D,$03
        .byte   $68,$03,$46,$6D,$07,$30,$0B,$71
        .byte   $0B,$39,$5B,$6B,$06,$2D,$11,$38
        .byte   $11,$03,$0F,$0F,$0F,$0F,$12,$71
        .byte   $70,$03,$30,$0F,$0F,$2B,$08,$69
        .byte   $0B,$03,$2D,$0F,$0F,$31,$1D,$71
        .byte   $0D,$03,$20,$0F,$0F,$33,$10,$39
        .byte   $18,$03,$21,$08,$38,$35,$0D,$03
; ─── screen $05 ($8640) — Flash Man rooms ───
        .byte   $14,$03,$28,$1D,$69,$3C,$57,$07
        .byte   $19,$03,$24,$10,$69,$3B,$5A,$62
        .byte   $70,$03,$29,$0D,$39,$5C,$6C,$06
        .byte   $08,$03,$2A,$0F,$0F,$0F,$08,$71
        .byte   $1C,$03,$5E,$4F,$3C,$2A,$1D,$38
        .byte   $68,$39,$74,$06,$36,$33,$10,$69
        .byte   $0F,$0F,$1A,$03,$58,$21,$0C,$39
        .byte   $08,$38,$56,$07,$3A,$22,$11,$71
; ─── screen $06 ($8680) — Flash Man rooms ───
        .byte   $1C,$03,$0F,$0F,$0F,$0F,$18,$03
        .byte   $09,$03,$3D,$46,$6D,$28,$14,$03
        .byte   $10,$03,$2B,$2F,$06,$25,$19,$69
        .byte   $11,$03,$2D,$0B,$03,$1F,$12,$03
        .byte   $70,$03,$20,$11,$39,$73,$79,$7A
        .byte   $0B,$03,$35,$0F,$0F,$0F,$0F,$0F
        .byte   $11,$03,$47,$66,$4F,$57,$5D,$65
        .byte   $70,$39,$53,$72,$5B,$4C,$5C,$4A
; ─── screen $07 ($86C0) — Flash Man rooms ───
        .byte   $0D,$38,$5E,$4F,$5F,$6F,$46,$65
        .byte   $1B,$03,$01,$01,$01,$17,$27,$53
        .byte   $68,$03,$01,$01,$01,$33,$0F,$0F
        .byte   $0A,$03,$01,$01,$01,$21,$0E,$38
        .byte   $79,$03,$01,$01,$01,$30,$0A,$03
        .byte   $01,$01,$01,$01,$01,$2D,$10,$03
        .byte   $4E,$5E,$4F,$47,$6E,$1F,$0D,$03
        .byte   $5A,$4B,$5B,$6B,$42,$6C,$79,$03
; ─── screen $08 ($8700) — Flash Man rooms ───
        .byte   $6D,$5E,$4F,$57,$7C,$7D,$2A,$0F
        .byte   $63,$6B,$17,$0F,$37,$57,$78,$39
        .byte   $0F,$0F,$26,$0F,$2F,$06,$1D,$03
        .byte   $7C,$03,$28,$0F,$0A,$03,$37,$5F
        .byte   $1B,$03,$25,$2F,$79,$39,$5C,$4A
        .byte   $1D,$03,$36,$0F,$0F,$0F,$0F,$0F
        .byte   $13,$03,$56,$5D,$4E,$5E,$6E,$55
        .byte   $19,$39,$5C,$6C,$43,$6A,$74,$52
; ─── screen $09 ($8740) — Flash Man rooms ───
        .byte   $0F,$3C,$57,$46,$6D,$5E,$6E,$45
        .byte   $6A,$30,$2F,$53,$42,$64,$4A,$5C
        .byte   $01,$2D,$08,$03,$0F,$0F,$0F,$0F
        .byte   $4D,$1F,$1D,$03,$3C,$47,$66,$4F
        .byte   $53,$42,$7F,$03,$3B,$5B,$4C,$44
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $4E,$56,$1F,$0F,$3D,$55,$3C,$47
        .byte   $62,$4B,$5B,$6B,$2B,$0F,$32,$0F
; ─── screen $0A ($8780) — Flash Man rooms ───
        .byte   $5D,$4E,$5E,$6E,$75,$56,$45,$67
        .byte   $64,$6C,$43,$6A,$06,$44,$63,$4C
        .byte   $0F,$0F,$2A,$0F,$0F,$22,$0F,$0F
        .byte   $7C,$03,$1F,$12,$03,$1F,$08,$7B
        .byte   $79,$39,$5C,$7F,$39,$3F,$08,$7A
        .byte   $0F,$0F,$22,$0F,$0F,$2A,$0F,$0F
        .byte   $7C,$03,$0F,$1A,$03,$0F,$0A,$7B
        .byte   $37,$5F,$4D,$5F,$6F,$5D,$6D,$07
; ─── screen $0B ($87C0) — Flash Man rooms ───
        .byte   $6F,$56,$45,$67,$4D,$55,$78,$03
        .byte   $5C,$6C,$3F,$0F,$0F,$0F,$1D,$69
        .byte   $0F,$0F,$32,$0F,$0F,$0F,$10,$03
        .byte   $7C,$03,$46,$7E,$03,$0F,$0D,$69
        .byte   $79,$39,$3F,$0A,$03,$0F,$1E,$7A
        .byte   $0F,$0F,$2A,$0F,$0F,$0F,$0F,$0F
        .byte   $78,$03,$5E,$4F,$5F,$6F,$46,$65
        .byte   $09,$39,$43,$62,$4B,$42,$64,$64
; ─── screen $0C ($8800) — Flash Man rooms ───
        .byte   $1B,$38,$5E,$4F,$5F,$6F,$46,$65
        .byte   $68,$03,$0F,$0F,$2F,$5B,$4C,$53
        .byte   $1B,$03,$0F,$1F,$0F,$0F,$0F,$0F
        .byte   $68,$02,$0F,$17,$0F,$0F,$A0,$A1
        .byte   $79,$03,$0F,$0F,$0F,$0F,$11,$28
        .byte   $0F,$0F,$0F,$26,$0F,$0F,$13,$25
        .byte   $6D,$07,$5E,$4F,$57,$1F,$15,$33
        .byte   $4A,$5A,$6A,$44,$4C,$5C,$6C,$35
; ─── screen $0D ($8840) — Flash Man rooms ───
        .byte   $6D,$47,$66,$4F,$47,$6E,$7C,$03
        .byte   $4C,$54,$3F,$0F,$0F,$0F,$0B,$69
        .byte   $0F,$0F,$33,$01,$01,$01,$0D,$71
        .byte   $03,$0F,$21,$0F,$0F,$0F,$18,$03
        .byte   $03,$0F,$22,$01,$01,$01,$15,$71
        .byte   $03,$0F,$30,$0F,$0F,$0F,$0E,$69
        .byte   $03,$0F,$2D,$01,$01,$01,$13,$03
        .byte   $03,$0F,$26,$0F,$0F,$0F,$19,$69
; ─── screen $0E ($8880) — Flash Man rooms ───
        .byte   $0F,$0F,$23,$01,$01,$01,$1B,$03
        .byte   $0F,$0F,$29,$0F,$0F,$0F,$1D,$69
        .byte   $0F,$0F,$2A,$01,$01,$01,$10,$71
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0C,$03
        .byte   $0F,$0F,$3F,$0F,$0F,$0F,$11,$71
        .byte   $01,$01,$01,$01,$01,$01,$10,$69
        .byte   $0F,$0F,$17,$0F,$0F,$0F,$11,$03
        .byte   $01,$01,$01,$01,$01,$01,$13,$71
; ─── screen $0F ($88C0) — Flash Man rooms ───
        .byte   $0F,$0F,$1F,$0F,$0F,$0F,$19,$03
        .byte   $01,$01,$3F,$01,$01,$01,$1B,$69
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$09,$71
        .byte   $01,$01,$1F,$01,$01,$01,$0E,$03
        .byte   $0F,$0F,$17,$0F,$0F,$0F,$0B,$69
        .byte   $01,$01,$01,$01,$01,$01,$11,$71
        .byte   $0F,$0F,$3F,$0F,$0F,$0F,$12,$03
        .byte   $01,$01,$01,$01,$01,$01,$08,$71
; ─── screen $10 ($8900) — Flash Man rooms ───
        .byte   $0F,$0F,$28,$0F,$0F,$0F,$1D,$03
        .byte   $01,$01,$25,$01,$01,$01,$16,$69
        .byte   $0F,$0F,$36,$0F,$0F,$3F,$13,$71
        .byte   $01,$01,$33,$01,$01,$28,$15,$03
        .byte   $0F,$0F,$21,$0F,$0F,$29,$08,$71
        .byte   $01,$01,$23,$01,$01,$2B,$1D,$69
        .byte   $0F,$0F,$29,$0F,$0F,$2D,$10,$03
        .byte   $01,$01,$2B,$01,$01,$20,$0D,$69
; ─── screen $11 ($8940) — Flash Man rooms ───
        .byte   $0F,$0F,$31,$0F,$0F,$21,$16,$03
        .byte   $01,$01,$32,$01,$01,$22,$1B,$71
        .byte   $0F,$0F,$22,$0F,$0F,$0F,$09,$69
        .byte   $01,$01,$30,$01,$3F,$01,$0E,$03
        .byte   $6B,$06,$2D,$0F,$32,$0F,$13,$69
        .byte   $01,$01,$01,$01,$2A,$01,$19,$71
        .byte   $48,$40,$06,$0F,$0F,$0F,$1A,$69
        .byte   $49,$50,$41,$51,$3C,$3D,$3C,$07
; ─── screen $12 ($8980) — Flash Man rooms ───
        .byte   $0F,$1B,$02,$01,$A2,$58,$2E,$0F
        .byte   $59,$68,$02,$01,$2D,$33,$3B,$53
        .byte   $0F,$0B,$02,$01,$20,$60,$58,$59
        .byte   $0F,$11,$02,$01,$60,$23,$32,$0F
        .byte   $A3,$70,$02,$01,$58,$29,$3C,$57
        .byte   $0F,$08,$02,$01,$A2,$58,$2E,$0F
        .byte   $59,$68,$02,$01,$2D,$30,$3D,$56
        .byte   $0F,$0E,$41,$51,$58,$2D,$26,$0F
; ─── screen $13 ($89C0) — Flash Man boss corridor ───
        .byte   $1B,$D4,$D5,$D1,$D6,$D7,$58,$59
        .byte   $68,$D0,$D1,$D1,$D1,$DF,$3B,$5B
        .byte   $10,$D0,$D1,$D1,$D1,$E0,$02,$01
        .byte   $0D,$D0,$D1,$D1,$DD,$E1,$A3,$A3
        .byte   $70,$D0,$D1,$D1,$DE,$E2,$E7,$02
        .byte   $1E,$D0,$D1,$D1,$D1,$E3,$E8,$02
        .byte   $1B,$D0,$D1,$D1,$DD,$E4,$E5,$E6
        .byte   $68,$D8,$D9,$DA,$DB,$02,$22,$01
; ─── screen $14 ($8A00) ───
        .byte   $00,$08,$10,$0F,$08,$00,$00,$00
        .byte   $00,$08,$10,$0F,$08,$00,$00,$00
        .byte   $00,$08,$10,$0F,$08,$00,$00,$00
        .byte   $00,$08,$10,$0F,$08,$00,$00,$00
        .byte   $00,$08,$10,$0F,$08,$00,$00,$00
        .byte   $00,$08,$10,$0F,$08,$00,$00,$00
        .byte   $00,$08,$10,$0F,$08,$00,$00,$00
        .byte   $00,$08,$09,$0A,$08,$00,$00,$00
; ─── screen $15 ($8A40) ───
        .byte   $08,$0B,$55,$0F,$0C,$0C,$08,$08
        .byte   $08,$10,$0F,$0F,$0F,$0F,$08,$08
        .byte   $08,$10,$0F,$0F,$0F,$0F,$08,$08
        .byte   $08,$10,$0F,$0F,$0F,$0F,$08,$08
        .byte   $08,$10,$0F,$0F,$0F,$0F,$08,$08
        .byte   $08,$10,$0F,$0F,$0F,$0F,$08,$08
        .byte   $08,$10,$0F,$0F,$0F,$0F,$08,$08
        .byte   $08,$0D,$0E,$0E,$0E,$0E,$08,$08
; ─── screen $16 ($8A80) — Wily 6 rooms ───
        .byte   $81,$83,$82,$85,$86,$82,$83,$81
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $81,$86,$82,$81,$93,$94,$83,$81
; ─── screen $17 ($8AC0) — Wily 6 boss corridor ───
        .byte   $81,$83,$82,$85,$86,$82,$83,$81
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $81,$86,$82,$81,$93,$94,$83,$81
; ─── screen $18 ($8B00) ───
        .byte   $81,$83,$82,$85,$86,$82,$83,$81
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $88,$88,$88,$88,$88,$88,$88,$88
        .byte   $81,$86,$82,$81,$93,$94,$83,$81
; ─── screen $19 ($8B40) ───
        .byte   $82,$81,$84,$85,$81,$85,$82,$81
        .byte   $88,$88,$88,$88,$88,$88,$83,$86
        .byte   $88,$88,$88,$88,$88,$88,$81,$93
        .byte   $88,$88,$88,$88,$88,$88,$94,$81
        .byte   $88,$88,$88,$88,$88,$88,$81,$83
        .byte   $88,$88,$88,$88,$88,$88,$81,$82
        .byte   $88,$88,$88,$88,$88,$8A,$81,$84
        .byte   $81,$89,$88,$88,$88,$8B,$82,$84
; ─── screen $1A ($8B80) ───
        .byte   $81,$8C,$88,$88,$88,$8B,$81,$93
        .byte   $84,$89,$88,$88,$88,$8B,$86,$81
        .byte   $85,$82,$89,$88,$88,$82,$93,$94
        .byte   $81,$81,$89,$88,$88,$81,$81,$82
        .byte   $86,$8C,$88,$88,$88,$93,$83,$85
        .byte   $81,$89,$88,$88,$88,$85,$82,$94
        .byte   $82,$81,$89,$88,$8B,$81,$82,$85
        .byte   $86,$8C,$88,$88,$8B,$82,$83,$81
; ─── screen $1B ($8BC0) ───
        .byte   $81,$89,$88,$88,$8B,$81,$85,$83
        .byte   $86,$89,$88,$88,$8B,$84,$82,$83
        .byte   $82,$8C,$88,$88,$90,$81,$82,$86
        .byte   $82,$81,$89,$88,$82,$86,$93,$82
        .byte   $86,$89,$88,$88,$81,$93,$82,$85
        .byte   $81,$8C,$88,$88,$86,$82,$94,$82
        .byte   $81,$81,$8D,$88,$84,$81,$81,$85
        .byte   $84,$82,$8C,$88,$82,$86,$93,$83
; ─── screen $1C ($8C00) ───
        .byte   $83,$84,$81,$89,$81,$93,$81,$84
        .byte   $82,$86,$94,$89,$93,$81,$82,$81
        .byte   $94,$81,$82,$89,$81,$84,$82,$81
        .byte   $86,$84,$93,$89,$82,$86,$81,$83
        .byte   $93,$85,$81,$89,$93,$85,$84,$85
        .byte   $81,$82,$82,$89,$83,$81,$85,$82
        .byte   $81,$83,$82,$89,$82,$82,$81,$83
        .byte   $86,$81,$84,$89,$84,$81,$84,$81
; ─── screen $1D ($8C40) ───
        .byte   $94,$85,$82,$89,$81,$84,$81,$93
        .byte   $81,$83,$94,$89,$81,$93,$83,$81
        .byte   $82,$85,$82,$89,$85,$82,$82,$93
        .byte   $86,$82,$84,$89,$82,$83,$93,$81
        .byte   $81,$85,$81,$89,$86,$94,$81,$85
        .byte   $82,$84,$93,$89,$81,$82,$86,$86
        .byte   $86,$81,$83,$89,$81,$83,$84,$81
        .byte   $82,$81,$81,$89,$85,$81,$82,$82
; ─── screen $1E ($8C80) ───
        .byte   $81,$85,$93,$89,$93,$81,$86,$81
        .byte   $85,$94,$81,$89,$83,$85,$81,$81
        .byte   $83,$82,$89,$88,$81,$84,$82,$85
        .byte   $81,$81,$89,$81,$94,$81,$86,$81
        .byte   $84,$86,$89,$82,$85,$82,$82,$83
        .byte   $84,$81,$89,$88,$88,$88,$82,$82
        .byte   $82,$85,$83,$81,$89,$88,$81,$81
        .byte   $94,$93,$81,$84,$8E,$8F,$82,$81
; ─── screen $1F ($8CC0) ───
        .byte   $00,$00,$00,$80,$ED,$00,$80,$80
        .byte   $00,$00,$00,$EE,$00,$EF,$80,$80
        .byte   $00,$00,$00,$00,$00,$00,$80,$80
        .byte   $ED,$00,$00,$00,$95,$00,$96,$80
        .byte   $00,$00,$ED,$00,$00,$00,$80,$80
        .byte   $00,$EE,$00,$00,$00,$00,$80,$80
        .byte   $00,$00,$00,$00,$00,$00,$97,$80
        .byte   $00,$ED,$00,$EF,$00,$EE,$80,$80
; ─── screen $20 ($8D00) ───
        .byte   $00,$00,$00,$80,$ED,$00,$80,$80
        .byte   $00,$00,$00,$EE,$00,$EF,$80,$80
        .byte   $00,$00,$00,$00,$00,$00,$80,$80
        .byte   $ED,$00,$00,$00,$95,$00,$96,$80
        .byte   $00,$00,$ED,$00,$00,$00,$80,$80
        .byte   $00,$EE,$00,$00,$00,$00,$80,$80
        .byte   $00,$00,$00,$00,$00,$00,$97,$80
        .byte   $00,$ED,$00,$EF,$00,$EE,$80,$80
; ─── screen $21 ($8D40) ───
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A9,$AC,$A7,$A8,$A8,$A8
        .byte   $A8,$A8,$AA,$A6,$B6,$A8,$A8,$A8
        .byte   $A8,$A8,$AA,$A6,$B6,$A8,$A8,$A8
        .byte   $A8,$A8,$BD,$BE,$BF,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
; ─── screen $22 ($8D80) ───
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$B1,$B4,$B4,$B4,$B5,$A8,$A8
        .byte   $A8,$B2,$B8,$B8,$BA,$B6,$A8,$A8
        .byte   $A8,$B2,$B8,$B8,$BA,$B6,$A8,$A8
        .byte   $A8,$B2,$B9,$B9,$BB,$B6,$A8,$A8
        .byte   $A8,$B3,$AD,$AD,$AD,$B7,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$BC,$B4,$B5,$A8
        .byte   $A8,$A8,$A8,$A8,$AB,$AD,$B7,$A8
; ─── screen $23 ($8DC0) ───
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A9,$AC,$AE,$A8,$A8,$A8
        .byte   $A8,$A8,$AA,$A6,$AF,$A8,$A8,$A8
        .byte   $A8,$A8,$AA,$A6,$AF,$A8,$A8,$A8
        .byte   $A8,$A8,$AB,$AD,$B0,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
; ─── screen $24 ($8E00) ───
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$E9,$A7,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$B2,$B6,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$B2,$B6,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$EA,$BF,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
; ─── screen $25 ($8E40) ───
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$BC,$B4,$EB,$A8,$A8,$A8
        .byte   $A8,$A8,$AA,$A6,$AF,$A8,$A8,$A8
        .byte   $A8,$A8,$AA,$A6,$AF,$A8,$A8,$A8
        .byte   $A8,$A8,$AA,$A6,$AF,$A8,$A8,$A8
        .byte   $A8,$A8,$AB,$AD,$B0,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
; ─── screen $26 ($8E80) ───
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$B1,$B4,$B4,$B4,$B5,$A8,$A8
        .byte   $A8,$B2,$B8,$B8,$BA,$B6,$A8,$A8
        .byte   $A8,$B2,$B8,$B8,$BA,$B6,$A8,$A8
        .byte   $A8,$B2,$B9,$B9,$BB,$B6,$A8,$A8
        .byte   $A8,$B3,$AD,$AD,$AD,$B7,$A8,$A8
        .byte   $A8,$A8,$A8,$B1,$B4,$B4,$B5,$A8
        .byte   $A8,$A8,$A8,$B3,$AD,$AD,$B7,$A8
; ─── screen $27 ($8EC0) ───
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$C1,$C5,$C8,$00,$00,$00
        .byte   $00,$00,$C0,$C6,$C9,$00,$00,$00
        .byte   $00,$00,$C2,$C7,$CA,$00,$00,$00
        .byte   $00,$00,$C3,$C4,$FF,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
; ─── screen $28 ($8F00) ───
        .byte   $C0,$FC,$C3,$C4,$FE,$CB,$F3,$FA
        .byte   $C0,$C0,$C1,$C5,$C8,$CC,$F4,$F6
        .byte   $C0,$C0,$C0,$C6,$C9,$CD,$F5,$F7
        .byte   $C0,$C0,$C2,$C7,$CA,$CE,$F6,$F7
        .byte   $C0,$FC,$C3,$C4,$FF,$CF,$F7,$FD
        .byte   $C0,$C0,$C1,$C5,$FB,$F0,$F8,$F8
        .byte   $C0,$C0,$C0,$C6,$C9,$F1,$F7,$FD
        .byte   $C0,$C0,$C2,$C7,$CA,$F2,$F8,$FD
; ─── screen $29 ($8F40) ───
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$B1,$B4,$B4,$B5,$B1,$EB,$A8
        .byte   $A8,$B2,$A6,$A6,$B6,$B2,$AF,$A8
        .byte   $A8,$B2,$A6,$A6,$B6,$B2,$AF,$A8
        .byte   $A8,$B2,$A6,$A6,$B6,$B2,$AF,$A8
        .byte   $A8,$B2,$A6,$A6,$B6,$B2,$AF,$A8
        .byte   $A8,$EA,$BE,$BE,$BF,$EA,$A4,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
; ─── screen $2A ($8F80) ───
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$B1,$B4,$B4,$B4,$B5,$A8,$A8
        .byte   $A8,$B2,$B8,$B8,$BA,$B6,$A8,$A8
        .byte   $A8,$B2,$B8,$B8,$BA,$B6,$A8,$A8
        .byte   $A8,$B2,$B9,$B9,$BB,$B6,$A8,$A8
        .byte   $A8,$B3,$AD,$AD,$AD,$B7,$A8,$A8
        .byte   $A8,$A8,$A8,$B1,$B4,$B4,$B5,$A8
        .byte   $A8,$A8,$A8,$B3,$AD,$AD,$B7,$A8
; ─── screen $2B ($8FC0) ───
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$B1,$B4,$B4,$B5,$B1,$EB,$A8
        .byte   $A8,$B2,$A6,$A6,$B6,$B2,$AF,$A8
        .byte   $A8,$B2,$A6,$A6,$B6,$B2,$AF,$A8
        .byte   $A8,$B2,$A6,$A6,$B6,$B2,$AF,$A8
        .byte   $A8,$B2,$A6,$A6,$B6,$B2,$AF,$A8
        .byte   $A8,$EA,$BE,$BE,$BF,$EA,$A4,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$A8,$A8

; =============================================================================
; CHR pattern data $9000-$B3FF (36 pages)
; Referenced by: Flash Man CHR list, bank01 overlay sets, bank04 overlay sets, bank05 overlay sets, bank06 overlay sets, bank07 overlay sets, group 0 (stage select), group 4 (ending), group 5 (ending)
; =============================================================================
        .byte   $00,$00,$00,$06,$26,$63,$79,$81,$00,$00,$00,$04,$04,$04,$46,$FF
        .byte   $7F,$FF,$7F,$7F,$7E,$FE,$FC,$F8,$03,$03,$03,$07,$06,$0E,$1C,$F8
        .byte   $88,$30,$00,$80,$00,$41,$23,$08,$CF,$FF,$FF,$FC,$7D,$7B,$3F,$0F
        .byte   $38,$10,$00,$00,$00,$80,$10,$00,$F8,$F0,$30,$30,$F0,$F0,$F0,$C0
        .byte   $00,$00,$00,$00,$80,$80,$C0,$C0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $C0,$C0,$C0,$C0,$80,$00,$38,$7C,$00,$00,$00,$00,$00,$00,$38,$0C
        .byte   $3C,$7E,$FF,$FF,$FC,$FC,$7F,$3F,$3C,$7E,$FF,$FF,$00,$00,$00,$01
        .byte   $1C,$3E,$7F,$7F,$4F,$4F,$FF,$FE,$1C,$3E,$7F,$7F,$00,$00,$80,$C0
        .byte   $7E,$E0,$C1,$C2,$C2,$62,$31,$1C,$7F,$FF,$FF,$FE,$FE,$7E,$3F,$1F
        .byte   $3C,$04,$02,$02,$02,$42,$84,$08,$FC,$FC,$3E,$3E,$3E,$7E,$FC,$F8
        .byte   $00,$00,$00,$08,$18,$10,$00,$00,$1C,$36,$26,$4E,$5E,$5C,$78,$30
        .byte   $00,$00,$F0,$78,$3C,$1C,$04,$00,$00,$00,$F0,$78,$3C,$1C,$04,$00
        .byte   $00,$00,$00,$00,$00,$00,$70,$E8,$00,$00,$00,$00,$00,$00,$70,$E8
        .byte   $00,$00,$00,$00,$01,$00,$01,$02,$00,$00,$00,$00,$01,$03,$07,$0F
        .byte   $00,$03,$18,$4F,$30,$CF,$10,$27,$00,$03,$1F,$7F,$FF,$FF,$FF,$FF
        .byte   $00,$18,$FA,$05,$C4,$18,$E0,$00,$00,$F8,$FE,$FF,$FF,$FE,$F8,$E0
        .byte   $02,$01,$00,$00,$00,$00,$00,$03,$0F,$0F,$03,$00,$00,$00,$00,$03
        .byte   $18,$C0,$00,$00,$00,$00,$01,$03,$FF,$FC,$E0,$00,$00,$00,$01,$03
        .byte   $00,$00,$00,$00,$78,$EC,$DC,$BE,$00,$00,$00,$00,$78,$E4,$C4,$86
        .byte   $C1,$23,$96,$C0,$C1,$70,$00,$80,$C1,$23,$16,$04,$0E,$8F,$FF,$FC
        .byte   $BF,$7F,$7F,$77,$E3,$02,$06,$04,$83,$07,$07,$0F,$1F,$FE,$06,$E4
        .byte   $80,$01,$03,$00,$00,$00,$00,$00,$FB,$67,$3F,$1F,$00,$00,$00,$00
        .byte   $08,$80,$00,$00,$00,$00,$00,$00,$F8,$F0,$C0,$80,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$10,$10,$00,$00,$60,$F0,$D8,$88,$98,$98
        .byte   $00,$00,$C0,$E0,$F0,$F8,$E4,$E6,$00,$00,$80,$80,$80,$80,$80,$C0
        .byte   $00,$00,$00,$30,$11,$01,$03,$03,$00,$00,$30,$48,$68,$30,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$C8,$78,$30,$00,$00,$00,$00,$00
        .byte   $E7,$FF,$7F,$7F,$3F,$38,$18,$08,$C0,$E0,$70,$78,$3F,$3F,$1F,$0F
        .byte   $03,$87,$FF,$DE,$0C,$00,$00,$00,$00,$00,$31,$F3,$FF,$FF,$FF,$0F
        .byte   $04,$00,$00,$00,$00,$00,$00,$00,$06,$01,$00,$00,$00,$00,$00,$00
        .byte   $60,$30,$80,$00,$00,$00,$00,$00,$63,$FF,$80,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$01,$03,$01,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $03,$03,$00,$01,$0D,$1E,$1F,$1F,$00,$00,$00,$00,$0C,$18,$10,$10
        .byte   $E6,$E7,$E7,$7F,$3E,$10,$18,$00,$80,$C0,$C0,$60,$31,$1F,$1C,$00
        .byte   $4D,$02,$8C,$1C,$06,$02,$00,$00,$00,$02,$00,$E4,$C6,$02,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$0E,$1C,$18,$30,$30,$60,$60,$60
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$78,$1C,$0C,$0E,$06,$03,$03,$03
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0F,$7F,$E0
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F0,$FE,$0F
        .byte   $00,$0C,$08,$00,$00,$00,$00,$00,$0E,$13,$17,$1F,$0E,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $02,$02,$03,$03,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$03,$E1,$DC,$26,$00,$00,$00,$00,$00,$00,$1C,$3E
        .byte   $0E,$3E,$3C,$3C,$38,$F0,$E0,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $43,$01,$04,$98,$00,$42,$20,$13,$7F,$FF,$E7,$FE,$78,$63,$3F,$1F
        .byte   $F8,$D8,$98,$30,$F0,$60,$C0,$00,$F8,$D8,$98,$30,$F0,$E0,$C0,$00
        .byte   $02,$05,$05,$09,$0A,$12,$12,$24,$00,$02,$02,$06,$04,$0C,$0C,$18
        .byte   $00,$00,$3C,$3C,$3C,$3C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$10,$00,$00,$00,$00,$00,$00,$00,$10,$00,$00,$00
        .byte   $00,$00,$00,$18,$18,$00,$00,$00,$00,$00,$00,$18,$18,$00,$00,$00
        .byte   $00,$00,$18,$3C,$3C,$18,$00,$00,$00,$00,$18,$3C,$3C,$18,$00,$00
        .byte   $FC,$F8,$70,$78,$D8,$C8,$70,$00,$FC,$F8,$F0,$F8,$D8,$C8,$71,$01
        .byte   $70,$7F,$1F,$0F,$07,$03,$00,$00,$70,$7F,$1F,$4F,$F7,$FB,$FC,$1E
        .byte   $07,$FF,$FE,$F8,$F0,$C0,$00,$00,$07,$FF,$FE,$F9,$F7,$CF,$1F,$7F
        .byte   $00,$01,$01,$03,$03,$02,$02,$02,$00,$01,$01,$03,$03,$03,$03,$03
        .byte   $E0,$F0,$F0,$78,$3C,$7C,$7C,$FE,$EC,$F4,$F0,$F8,$FC,$FC,$FC,$FE
        .byte   $00,$00,$00,$00,$03,$3E,$3F,$7F,$7F,$3F,$3F,$1C,$03,$3F,$3F,$7F
        .byte   $00,$00,$00,$80,$C0,$C0,$40,$40,$80,$80,$00,$80,$C0,$C0,$C0,$C0
        .byte   $02,$02,$03,$00,$03,$02,$04,$05,$03,$03,$03,$00,$03,$03,$07,$07
        .byte   $FE,$FE,$FE,$7E,$9E,$FC,$FC,$F8,$FE,$FE,$FE,$7E,$9E,$FC,$FC,$F8
        .byte   $7F,$7F,$7E,$7E,$FF,$FD,$FF,$F0,$7F,$7F,$7F,$7F,$FF,$FF,$FF,$F0
        .byte   $40,$40,$C0,$C0,$80,$80,$80,$00,$C0,$C0,$C0,$C0,$80,$80,$80,$00
        .byte   $15,$77,$F7,$03,$FC,$7F,$1F,$00,$07,$07,$07,$03,$00,$00,$00,$00
        .byte   $FA,$F7,$EF,$C0,$3F,$FF,$FF,$00,$F8,$F0,$E0,$C0,$00,$00,$00,$00
        .byte   $00,$00,$00,$03,$07,$0F,$1F,$1F,$00,$07,$1F,$3F,$3F,$7F,$7F,$7F
        .byte   $00,$00,$00,$C0,$E0,$E0,$C0,$00,$00,$E0,$F8,$FC,$FC,$FE,$FE,$FE
        .byte   $1E,$1E,$1E,$0C,$00,$00,$00,$00,$7F,$7F,$7F,$3F,$3F,$1F,$07,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FE,$FE,$FE,$FC,$FC,$F8,$E0,$00
        .byte   $00,$07,$1F,$3C,$38,$70,$60,$60,$00,$07,$1F,$3F,$3F,$7F,$7F,$7F
        .byte   $00,$E0,$F8,$3C,$1C,$1E,$3E,$FE,$00,$E0,$F8,$FC,$FC,$FE,$FE,$FE
        .byte   $61,$61,$61,$33,$3F,$1F,$07,$00,$7F,$7F,$7F,$3F,$3F,$1F,$07,$00
        .byte   $FE,$FE,$FE,$FC,$FC,$F8,$E0,$00,$FE,$FE,$FE,$FC,$FC,$F8,$E0,$00
        .byte   $00,$00,$78,$3C,$00,$00,$00,$00,$00,$FC,$FE,$FF,$FF,$FE,$FC,$00
        .byte   $18,$18,$18,$10,$10,$10,$10,$10,$38,$38,$18,$18,$10,$10,$10,$10
        .byte   $00,$00,$00,$10,$18,$18,$18,$18,$00,$10,$38,$38,$38,$38,$38,$38
        .byte   $70,$70,$A0,$A0,$00,$00,$00,$00,$F0,$70,$A0,$A0,$00,$00,$00,$00
        .byte   $0D,$0D,$0C,$0C,$0D,$0F,$0E,$00,$0D,$0D,$0C,$0C,$0D,$0F,$0E,$00
        .byte   $83,$A6,$0C,$98,$B0,$E0,$C0,$80,$83,$A6,$0C,$98,$B0,$E0,$C0,$80
        .byte   $00,$00,$00,$00,$00,$01,$02,$04,$00,$00,$00,$00,$00,$01,$02,$04
        .byte   $00,$03,$1C,$60,$80,$1E,$7E,$7C,$00,$03,$1C,$60,$80,$1E,$7E,$7C
        .byte   $04,$09,$09,$11,$11,$11,$10,$20,$04,$09,$09,$11,$11,$11,$10,$20
        .byte   $F8,$F0,$F0,$E0,$C0,$80,$00,$00,$F8,$F0,$F0,$E0,$C0,$80,$00,$00
        .byte   $20,$20,$20,$20,$20,$20,$20,$10,$20,$20,$20,$20,$20,$20,$20,$10
        .byte   $10,$10,$08,$04,$04,$02,$00,$00,$10,$10,$08,$04,$04,$02,$00,$00
        .byte   $00,$03,$01,$00,$02,$03,$01,$00,$03,$03,$05,$06,$07,$03,$01,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$C0,$E0,$70,$B8,$DC,$EE
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$77,$3B,$1C,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$02,$04,$08,$00,$00,$00,$00,$01,$02,$04,$08
        .byte   $00,$0F,$30,$C0,$00,$00,$00,$00,$00,$0F,$30,$C0,$00,$00,$00,$00
        .byte   $08,$10,$10,$23,$27,$27,$4F,$4E,$08,$10,$10,$23,$27,$27,$4F,$4E
        .byte   $00,$01,$01,$03,$03,$03,$03,$07,$01,$06,$0F,$05,$1C,$0C,$1D,$0B
        .byte   $FC,$FE,$FC,$FC,$FD,$FD,$FF,$FF,$7D,$FF,$FF,$FF,$C2,$8E,$C7,$7F
        .byte   $00,$00,$00,$00,$80,$C0,$C0,$C0,$C0,$F0,$FC,$F0,$7C,$BE,$B0,$BC
        .byte   $46,$46,$40,$40,$40,$40,$40,$20,$46,$46,$40,$40,$40,$40,$40,$20
        .byte   $03,$02,$01,$03,$0F,$1D,$1C,$00,$04,$01,$00,$01,$0D,$1C,$1D,$01
        .byte   $1F,$0F,$EF,$FE,$FC,$FF,$7E,$3E,$EE,$F6,$14,$E9,$63,$0C,$9D,$DD
        .byte   $80,$C0,$30,$08,$88,$84,$04,$04,$78,$10,$C0,$F0,$70,$78,$F8,$F8
        .byte   $20,$20,$10,$10,$08,$08,$04,$02,$20,$20,$10,$10,$08,$08,$04,$02
        .byte   $01,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$03,$03,$07,$03,$07,$07,$0F,$02,$0D,$1F,$09,$3D,$19,$3B,$16
        .byte   $F8,$FC,$F8,$F8,$FB,$FB,$FF,$FF,$FB,$FF,$FF,$C7,$0C,$9D,$8F,$FF
        .byte   $00,$00,$00,$00,$00,$80,$80,$80,$80,$E0,$F8,$E0,$F8,$7C,$60,$78
        .byte   $06,$04,$03,$07,$3F,$63,$E0,$E0,$09,$03,$00,$03,$02,$60,$E8,$EC
        .byte   $3F,$1F,$DE,$FC,$F8,$E0,$70,$70,$DC,$EC,$29,$D3,$87,$6F,$77,$77
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$30,$00,$80,$C0,$E0,$E0,$F0,$F0
        .byte   $00,$0E,$1F,$37,$20,$30,$63,$67,$00,$0E,$1F,$3F,$3F,$3F,$7F,$7F
        .byte   $0E,$3E,$FE,$FE,$3E,$FF,$FF,$FE,$0E,$3E,$FE,$FE,$FE,$FF,$FF,$FE
        .byte   $6F,$DF,$DD,$8D,$FE,$7E,$06,$00,$7F,$FF,$FD,$FD,$FE,$7E,$06,$00
        .byte   $FC,$F0,$F0,$F8,$F8,$78,$70,$60,$FC,$F0,$F0,$F8,$F8,$F8,$F0,$60
        .byte   $EC,$7F,$7F,$3F,$C0,$FF,$FF,$00,$EF,$7F,$7F,$3F,$00,$00,$00,$00
        .byte   $98,$6E,$EF,$E0,$1F,$FE,$F8,$00,$80,$E0,$E0,$E0,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$1C,$3E,$31,$00,$00,$00,$00,$38,$20,$40,$49
        .byte   $31,$31,$31,$3E,$3F,$1C,$07,$01,$41,$01,$29,$3F,$3F,$1C,$0F,$03
        .byte   $8C,$8C,$8C,$7C,$FC,$38,$E0,$80,$82,$80,$94,$7C,$FC,$38,$F0,$C0
        .byte   $19,$79,$00,$FA,$F4,$6B,$0F,$07,$01,$01,$00,$03,$07,$0F,$0F,$07
        .byte   $FF,$03,$FC,$1F,$7F,$FF,$FF,$FE,$FF,$03,$FC,$FF,$FF,$FF,$FF,$FE
        .byte   $DF,$C0,$E0,$6F,$CF,$DF,$80,$7F,$DF,$C0,$E0,$60,$C0,$C0,$80,$00
        .byte   $78,$FE,$00,$FF,$FF,$FE,$00,$80,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $19,$06,$F7,$F7,$F8,$00,$1F,$01,$01,$07,$07,$07,$00,$00,$00,$00
        .byte   $37,$FE,$FE,$FD,$03,$00,$FF,$FF,$F7,$FE,$FE,$FC,$00,$00,$00,$00
        .byte   $5F,$0F,$F7,$FB,$FC,$00,$FF,$FF,$1F,$0F,$07,$03,$00,$00,$00,$00
        .byte   $A8,$E0,$EF,$CF,$3F,$00,$F8,$80,$E0,$E0,$E0,$C0,$00,$00,$00,$00
        .byte   $00,$05,$08,$18,$78,$4F,$7F,$FF,$01,$66,$48,$58,$7D,$7C,$FF,$FF
        .byte   $E0,$F0,$F8,$F8,$F8,$F8,$F8,$F0,$F0,$38,$1C,$1C,$1C,$3C,$FC,$F8
        .byte   $C3,$7B,$7F,$3F,$06,$00,$00,$00,$C7,$FF,$7F,$3F,$0F,$00,$00,$00
        .byte   $F0,$E0,$C0,$80,$00,$00,$00,$00,$F8,$F0,$E0,$C0,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$07,$18,$30,$20,$41,$42,$44,$07,$1F,$38,$77,$6F,$DF,$DE,$DC
        .byte   $00,$E0,$18,$0C,$04,$02,$02,$02,$E0,$F8,$1C,$0E,$06,$03,$03,$03
        .byte   $00,$00,$07,$08,$10,$20,$20,$21,$00,$07,$1F,$38,$30,$63,$67,$67
        .byte   $00,$00,$E0,$10,$08,$04,$84,$04,$00,$E0,$F8,$1C,$0C,$86,$86,$06
        .byte   $22,$20,$20,$10,$08,$07,$00,$00,$66,$60,$60,$30,$38,$1F,$07,$00
        .byte   $04,$04,$04,$08,$10,$E0,$00,$00,$06,$06,$06,$0C,$1C,$F8,$E0,$00
        .byte   $00,$00,$00,$07,$0C,$18,$10,$10,$00,$00,$07,$0F,$1C,$38,$31,$33
        .byte   $00,$00,$00,$E0,$30,$18,$48,$C8,$00,$00,$E0,$F0,$38,$1C,$CC,$CC
        .byte   $11,$13,$18,$0C,$07,$00,$00,$00,$33,$33,$38,$1C,$0F,$07,$00,$00
        .byte   $08,$08,$18,$30,$E0,$00,$00,$00,$0C,$0C,$1C,$38,$F0,$E0,$00,$00
        .byte   $00,$00,$00,$00,$3C,$42,$81,$00,$00,$18,$3C,$7E,$C3,$81,$00,$00
        .byte   $40,$20,$10,$10,$10,$10,$20,$40,$30,$18,$0C,$0E,$0E,$0C,$18,$30
        .byte   $07,$1A,$28,$20,$43,$85,$C8,$8D,$00,$05,$17,$1F,$3C,$7A,$37,$72
        .byte   $E0,$58,$14,$02,$C6,$A1,$13,$B1,$00,$A0,$E8,$FC,$38,$5E,$EC,$4E
        .byte   $02,$0D,$14,$30,$53,$46,$8E,$49,$00,$02,$0B,$0F,$2C,$39,$71,$36
        .byte   $40,$B0,$08,$1C,$C2,$66,$71,$92,$00,$40,$F0,$E0,$3C,$98,$8E,$6C
        .byte   $00,$0F,$0F,$19,$1B,$24,$13,$09,$00,$0F,$1F,$3F,$3F,$3F,$1F,$0F
        .byte   $00,$80,$E0,$F8,$FC,$7C,$FC,$FC,$00,$80,$E0,$F8,$FC,$FC,$FC,$FC
        .byte   $2F,$10,$0F,$13,$0F,$07,$18,$10,$3F,$3F,$1F,$1F,$1F,$0F,$18,$10
        .byte   $F8,$E0,$F0,$F0,$C0,$80,$00,$00,$F8,$E0,$F0,$F0,$C0,$80,$00,$00
        .byte   $04,$0B,$1E,$3F,$1F,$0B,$14,$1E,$07,$0F,$1F,$3F,$1F,$0F,$17,$1F
        .byte   $00,$F0,$2C,$77,$E7,$8F,$1E,$7E,$F0,$FC,$FE,$FF,$FF,$FF,$FE,$FE
        .byte   $08,$0F,$08,$1D,$1E,$18,$10,$20,$0F,$0F,$0F,$1F,$1F,$1E,$18,$20
        .byte   $0C,$78,$60,$E0,$C0,$00,$00,$00,$FC,$F8,$E0,$E0,$C0,$00,$00,$00
        .byte   $00,$01,$03,$07,$07,$07,$07,$03,$00,$01,$03,$07,$07,$07,$07,$03
        .byte   $70,$F8,$FC,$FC,$FA,$FA,$E2,$8C,$70,$F8,$FC,$FE,$FF,$FF,$FF,$FF
        .byte   $0F,$0F,$07,$07,$07,$07,$04,$0C,$0F,$0F,$07,$07,$07,$07,$07,$0C
        .byte   $F0,$C4,$F8,$80,$E0,$00,$00,$00,$FE,$FC,$FC,$F8,$E0,$C0,$00,$00
        .byte   $00,$00,$00,$00,$00,$03,$07,$03,$00,$06,$0F,$1D,$18,$23,$37,$13
        .byte   $00,$00,$03,$00,$07,$0E,$2C,$05,$00,$1C,$33,$4F,$5F,$5E,$2F,$27
        .byte   $00,$00,$00,$0C,$10,$08,$08,$11,$08,$22,$4C,$1C,$B0,$0E,$48,$31
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$38,$20,$88,$10,$90,$00,$00,$00
        .byte   $00,$03,$0F,$1C,$38,$30,$60,$60,$00,$03,$0F,$1F,$3F,$3F,$7E,$7C
        .byte   $FF,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$00,$00,$7E
        .byte   $C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$F8,$F9,$F9,$F9,$F9,$F9,$F9,$F8
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$81,$00,$00,$00,$00,$00,$00,$81
        .byte   $00,$00,$00,$01,$07,$0E,$0C,$18,$00,$00,$00,$01,$07,$0F,$0F,$1F
        .byte   $00,$00,$7E,$FF,$C3,$00,$00,$00,$00,$00,$7E,$FF,$FF,$FF,$FF,$C3
        .byte   $18,$38,$30,$30,$30,$30,$38,$18,$1F,$3F,$3E,$3E,$3E,$3E,$3F,$1F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$80,$3C,$42,$42,$42,$42,$3C,$00
        .byte   $07,$1F,$38,$70,$60,$C0,$C0,$C0,$07,$1F,$3F,$7F,$7C,$FB,$F4,$F4
        .byte   $00,$00,$07,$0F,$18,$30,$30,$30,$00,$00,$07,$0F,$1F,$3E,$3C,$39
        .byte   $3C,$42,$81,$81,$81,$81,$42,$3C,$3C,$7E,$E7,$C3,$C3,$E7,$7E,$3C
        .byte   $00,$3C,$66,$42,$42,$66,$3C,$00,$00,$3C,$7E,$66,$66,$7E,$3C,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$10,$10,$10,$38,$FF,$38,$10,$10
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$38,$10,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$10,$10,$10,$10,$10,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$1E,$31,$7C,$E6,$CE,$00,$00,$00,$00,$1E,$3F,$7F,$7F
        .byte   $00,$00,$00,$00,$C0,$F0,$7C,$42,$00,$00,$00,$00,$00,$40,$B0,$BC
        .byte   $DE,$FE,$FE,$7C,$31,$1E,$00,$00,$7F,$7F,$7F,$3F,$1E,$00,$00,$00
        .byte   $7F,$42,$7C,$F0,$C0,$00,$00,$00,$80,$BC,$B0,$40,$00,$00,$00,$00
        .byte   $00,$00,$00,$01,$03,$07,$0E,$0C,$00,$00,$00,$00,$01,$03,$07,$07
        .byte   $00,$0F,$1C,$FB,$1A,$CA,$66,$E4,$00,$00,$0F,$0C,$E4,$F4,$F8,$F8
        .byte   $0D,$0F,$0F,$07,$03,$01,$00,$00,$07,$07,$07,$03,$01,$00,$00,$00
        .byte   $E4,$E4,$E6,$CA,$1A,$FB,$1C,$0F,$F8,$F8,$F8,$F4,$E4,$0C,$0F,$00
        .byte   $00,$00,$00,$03,$06,$0F,$1C,$19,$00,$00,$00,$00,$03,$07,$0F,$0F
        .byte   $00,$00,$0E,$DD,$3B,$9A,$CC,$C8,$00,$00,$00,$0E,$CC,$EC,$F0,$F0
        .byte   $1B,$1F,$1F,$0F,$06,$03,$00,$00,$0F,$0F,$0F,$07,$03,$00,$00,$00
        .byte   $C8,$C8,$CC,$9A,$3B,$DD,$0E,$00,$F0,$F0,$F0,$EC,$CC,$0E,$00,$00
        .byte   $00,$00,$00,$03,$04,$08,$10,$10,$00,$00,$00,$00,$03,$07,$0F,$0F
        .byte   $00,$00,$0E,$DD,$3B,$1A,$0C,$08,$00,$00,$00,$0E,$CC,$EC,$F0,$F0
        .byte   $10,$10,$10,$08,$04,$03,$00,$00,$0F,$0F,$0F,$07,$03,$00,$00,$00
        .byte   $08,$08,$0C,$1A,$3B,$DD,$0E,$00,$F0,$F0,$F0,$EC,$CC,$0E,$00,$00
        .byte   $03,$1F,$3F,$7F,$7F,$FE,$FC,$F0,$01,$02,$18,$36,$2E,$5C,$70,$00
        .byte   $00,$00,$00,$00,$00,$01,$03,$01,$00,$00,$00,$00,$00,$00,$01,$00
        .byte   $00,$03,$1F,$7E,$FE,$FE,$FC,$F0,$00,$00,$02,$1C,$64,$9C,$F0,$00
        .byte   $03,$0F,$0F,$07,$03,$00,$00,$00,$00,$03,$07,$03,$00,$00,$00,$00
        .byte   $E0,$F8,$FC,$FE,$FE,$F8,$00,$00,$00,$E0,$18,$E4,$F8,$00,$00,$00
        .byte   $00,$00,$00,$0E,$39,$79,$C3,$C7,$00,$00,$01,$0E,$25,$45,$FB,$C7
        .byte   $00,$00,$D0,$3C,$FF,$FF,$FF,$FF,$00,$00,$30,$3C,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$80,$80,$C0,$00,$00,$00,$00,$00,$80,$80,$C0
        .byte   $01,$01,$01,$01,$00,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$00
        .byte   $FC,$30,$20,$00,$00,$00,$00,$00,$FC,$30,$20,$00,$00,$00,$00,$00
        .byte   $1F,$0F,$07,$07,$07,$07,$04,$08,$1F,$0F,$07,$07,$07,$07,$07,$0F
        .byte   $C0,$E0,$E0,$E0,$E0,$E0,$40,$00,$C0,$E0,$E0,$E0,$E0,$E0,$C0,$C0
        .byte   $00,$10,$30,$78,$F0,$00,$00,$00,$0E,$1C,$3D,$7F,$F0,$0F,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$40,$C0,$80,$00,$00,$00,$80,$C0
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F0,$FF,$FF
        .byte   $7F,$FF,$C0,$D2,$C0,$FF,$C0,$C9,$00,$00,$3F,$24,$24,$3F,$00,$09
        .byte   $FE,$FF,$0B,$4B,$0B,$FB,$03,$23,$00,$03,$FB,$9B,$9B,$FB,$03,$23
        .byte   $FF,$C0,$C0,$FF,$C0,$FF,$7F,$00,$00,$3F,$3F,$3F,$00,$7F,$7F,$00
        .byte   $F3,$0B,$0B,$FB,$03,$FF,$FE,$00,$0B,$FB,$FB,$FB,$03,$FF,$FE,$00
        .byte   $00,$00,$00,$00,$00,$3F,$7F,$60,$00,$00,$00,$00,$00,$00,$00,$1F
        .byte   $00,$00,$00,$00,$00,$FF,$FF,$01,$00,$00,$00,$00,$00,$00,$01,$FD
        .byte   $00,$00,$00,$00,$00,$FF,$FF,$80,$00,$00,$00,$00,$00,$00,$00,$7F
        .byte   $00,$00,$00,$00,$00,$FC,$FE,$06,$00,$00,$00,$00,$00,$00,$06,$F6
        .byte   $69,$60,$7F,$60,$60,$02,$00,$00,$12,$12,$1F,$00,$00,$02,$00,$00
        .byte   $21,$01,$FD,$01,$00,$59,$19,$D9,$4D,$4D,$FD,$01,$00,$5E,$1E,$DE
        .byte   $A4,$80,$FF,$80,$00,$99,$98,$9B,$49,$49,$7F,$00,$00,$79,$78,$7B
        .byte   $86,$06,$F6,$06,$06,$20,$00,$00,$36,$36,$F6,$06,$06,$20,$00,$00
        .byte   $00,$7F,$60,$60,$7F,$60,$7F,$3F,$00,$00,$1F,$1F,$1F,$00,$3F,$3F
        .byte   $00,$F9,$05,$05,$FD,$01,$FF,$FF,$00,$05,$FD,$FD,$FD,$01,$FF,$FF
        .byte   $00,$FF,$80,$80,$FF,$80,$FF,$FF,$00,$00,$7F,$7F,$7F,$00,$7F,$FF
        .byte   $00,$E6,$16,$16,$F6,$06,$FE,$FC,$00,$16,$F6,$F6,$F6,$06,$FE,$FC
        .byte   $00,$00,$00,$00,$3F,$7F,$60,$69,$00,$00,$00,$00,$00,$00,$1F,$12
        .byte   $00,$00,$00,$00,$FF,$FF,$01,$21,$00,$00,$00,$00,$00,$01,$FD,$4D
        .byte   $00,$00,$00,$00,$FF,$FF,$80,$A4,$00,$00,$00,$00,$00,$00,$7F,$49
        .byte   $00,$00,$00,$00,$FC,$FE,$06,$86,$00,$00,$00,$00,$00,$06,$F6,$36
        .byte   $60,$7F,$60,$60,$02,$00,$00,$00,$12,$1F,$00,$00,$02,$00,$00,$00
        .byte   $01,$FD,$00,$00,$5E,$19,$59,$39,$4D,$FD,$00,$00,$5F,$1E,$5E,$3E
        .byte   $80,$FF,$00,$00,$79,$98,$9A,$9C,$49,$7F,$00,$00,$F9,$78,$7A,$7C
        .byte   $06,$F6,$06,$06,$20,$00,$00,$00,$36,$F6,$06,$06,$20,$00,$00,$00
        .byte   $00,$1F,$1F,$13,$13,$1F,$0F,$0F,$00,$00,$00,$08,$00,$00,$01,$0F
        .byte   $00,$00,$08,$04,$04,$00,$FC,$F8,$00,$60,$78,$7C,$7C,$00,$FC,$F8
        .byte   $00,$00,$00,$20,$20,$00,$3F,$1F,$00,$06,$1E,$3E,$3E,$00,$3F,$1F
        .byte   $00,$F8,$F8,$C8,$C8,$F8,$F0,$E0,$00,$F8,$F8,$E8,$C8,$F8,$F0,$E0
        .byte   $00,$01,$03,$07,$0E,$1C,$38,$72,$00,$00,$00,$00,$01,$03,$07,$0C
        .byte   $F0,$F8,$9C,$0C,$45,$00,$00,$00,$30,$38,$7C,$FC,$9D,$90,$E3,$C6
        .byte   $0F,$1F,$39,$30,$A2,$00,$C0,$60,$01,$03,$07,$0F,$99,$09,$C7,$63
        .byte   $00,$80,$C0,$E0,$70,$38,$1C,$4E,$00,$80,$C0,$E0,$F0,$F8,$FC,$3E
        .byte   $E0,$C0,$90,$C0,$60,$30,$18,$00,$1C,$3F,$66,$24,$1C,$08,$00,$00
        .byte   $00,$00,$02,$00,$5E,$99,$59,$19,$84,$04,$02,$00,$5F,$9E,$5E,$1E
        .byte   $20,$20,$40,$00,$7A,$99,$9A,$98,$21,$20,$40,$00,$FA,$79,$7A,$78
        .byte   $07,$03,$09,$03,$06,$0C,$18,$00,$3F,$FF,$67,$27,$3E,$1C,$18,$00
        .byte   $00,$02,$02,$22,$02,$02,$06,$7C,$00,$FE,$FE,$CE,$CE,$FE,$FE,$7C
        .byte   $00,$01,$01,$11,$01,$01,$03,$3E,$00,$7F,$7F,$67,$67,$7F,$7F,$3E
        .byte   $1F,$3C,$30,$34,$30,$30,$30,$34,$00,$03,$0F,$09,$09,$0F,$0F,$09
        .byte   $00,$81,$3C,$00,$3C,$00,$00,$00,$81,$81,$3C,$3C,$3C,$00,$3C,$66
        .byte   $30,$30,$30,$34,$30,$30,$30,$1F,$09,$0F,$0F,$09,$09,$0F,$20,$1F
        .byte   $00,$00,$24,$00,$66,$5A,$5A,$5A,$42,$42,$24,$00,$7E,$66,$66,$66
        .byte   $00,$00,$0F,$02,$00,$00,$00,$07,$00,$00,$0F,$0C,$0C,$0F,$0F,$07
        .byte   $00,$E7,$E7,$24,$24,$24,$66,$C3,$00,$E7,$E7,$E7,$E7,$E7,$E7,$C3
        .byte   $3E,$79,$60,$68,$60,$60,$60,$68,$01,$07,$1E,$12,$12,$1E,$1E,$12
        .byte   $00,$00,$3C,$00,$3C,$00,$00,$00,$00,$00,$3C,$3C,$3C,$00,$3C,$66
        .byte   $60,$60,$60,$68,$60,$60,$60,$3E,$12,$1E,$1E,$12,$12,$1E,$40,$3E
        .byte   $00,$00,$00,$18,$24,$2C,$18,$00,$00,$00,$00,$18,$3C,$3C,$18,$00
        .byte   $00,$00,$00,$00,$00,$00,$FD,$FA,$00,$00,$00,$00,$00,$00,$FD,$FB
        .byte   $00,$0A,$FF,$FF,$FF,$14,$E0,$FF,$01,$FE,$FF,$FF,$FF,$1F,$E0,$FF
        .byte   $00,$00,$00,$00,$00,$9F,$7F,$FF,$00,$00,$00,$00,$00,$FF,$FF,$FF
        .byte   $F8,$00,$CC,$E1,$D5,$20,$0F,$DF,$FF,$00,$EF,$F7,$F7,$E0,$0F,$DF
        .byte   $80,$43,$BF,$BF,$5D,$80,$FD,$FA,$80,$7F,$FF,$FF,$7F,$80,$FD,$FB
        .byte   $00,$0A,$FF,$FF,$FF,$14,$E0,$FF,$01,$FE,$FF,$FF,$FF,$1F,$E0,$FF
        .byte   $CF,$01,$FA,$F8,$40,$01,$3F,$FF,$DF,$01,$FE,$FE,$FC,$01,$FF,$FF
        .byte   $FF,$00,$CC,$E1,$95,$20,$01,$CF,$FF,$00,$EF,$F7,$F7,$E0,$0F,$DF
        .byte   $81,$46,$BD,$BD,$FD,$50,$A2,$C1,$81,$7E,$FF,$FF,$FF,$7C,$BB,$C3
        .byte   $BB,$4C,$5F,$BE,$3C,$3C,$48,$80,$BB,$7C,$7F,$FF,$7F,$7F,$7E,$9C
        .byte   $BE,$3E,$38,$01,$4D,$3E,$BE,$BC,$BF,$7F,$3E,$01,$7D,$7E,$BE,$BE
        .byte   $3C,$58,$01,$01,$06,$3F,$3F,$BF,$BE,$7E,$3D,$01,$3E,$7F,$7F,$BF
        .byte   $00,$00,$00,$00,$00,$C0,$F8,$F8,$00,$00,$00,$03,$03,$C3,$FB,$FB
        .byte   $00,$08,$F8,$F8,$F8,$F8,$00,$F8,$03,$FB,$FB,$FB,$FB,$FB,$03,$FB
        .byte   $00,$00,$00,$C0,$C0,$C7,$C3,$CF,$00,$00,$00,$C0,$C0,$C7,$CF,$CF
        .byte   $CF,$C0,$CC,$C1,$C5,$C3,$CC,$CF,$CF,$C0,$CF,$C7,$C7,$C3,$CC,$CF
        .byte   $80,$40,$B8,$B8,$58,$80,$F8,$F8,$83,$7B,$FB,$FB,$7B,$83,$FB,$FB
        .byte   $00,$08,$F8,$F8,$F8,$F8,$00,$F8,$03,$FB,$FB,$FB,$FB,$FB,$03,$FB
        .byte   $C1,$CE,$CA,$C2,$CC,$C1,$C3,$CF,$C1,$CE,$CE,$CE,$CC,$C1,$CF,$CF
        .byte   $CF,$C0,$CC,$C1,$C5,$C3,$CC,$CF,$CF,$C0,$CF,$C7,$C7,$C3,$CC,$CF
        .byte   $00,$00,$00,$00,$00,$C0,$00,$55,$00,$00,$00,$00,$00,$C0,$FF,$FF
        .byte   $FF,$AA,$00,$00,$FF,$F8,$00,$FF,$FF,$AA,$00,$00,$FF,$FF,$00,$FF
        .byte   $00,$00,$00,$00,$00,$07,$00,$55,$00,$00,$00,$00,$00,$07,$FF,$FF
        .byte   $FF,$AA,$00,$00,$95,$23,$0C,$EF,$FF,$AA,$00,$00,$F7,$E3,$0C,$EF
        .byte   $80,$40,$BF,$BF,$5F,$80,$00,$AA,$80,$7F,$FF,$FF,$7F,$80,$FF,$FF
        .byte   $FF,$AA,$00,$00,$FF,$F8,$00,$FF,$FF,$AA,$00,$00,$FF,$FF,$00,$FF
        .byte   $01,$FE,$FA,$F2,$8C,$01,$00,$AA,$01,$FE,$FE,$FE,$FC,$01,$FF,$FF
        .byte   $FF,$AA,$00,$00,$95,$23,$0C,$EF,$FF,$AA,$00,$00,$F7,$E3,$0C,$EF
        .byte   $00,$3F,$7F,$7F,$7C,$78,$78,$70,$00,$3F,$71,$67,$6F,$7F,$6F,$7F
        .byte   $7F,$42,$44,$7E,$41,$71,$3F,$00,$7F,$7F,$7F,$7F,$7F,$7E,$3F,$00
        .byte   $00,$FC,$C6,$FA,$06,$02,$02,$02,$00,$FC,$7E,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$02,$06,$0E,$FE,$7E,$FC,$A0,$FA,$FE,$FA,$F2,$F6,$8E,$FC,$A0
        .byte   $00,$3F,$7F,$7F,$7F,$7E,$78,$78,$00,$3F,$70,$63,$67,$6F,$6F,$6F
        .byte   $7F,$7A,$7C,$7E,$79,$68,$68,$68,$6F,$6F,$7F,$7F,$6F,$7F,$7F,$7F
        .byte   $02,$FF,$FF,$FE,$FF,$01,$01,$03,$02,$FF,$37,$FF,$FF,$FF,$FF,$FF
        .byte   $FE,$00,$00,$00,$FF,$13,$0D,$0E,$FF,$FF,$FF,$FF,$FF,$FC,$FB,$FA
        .byte   $00,$FF,$FF,$FF,$00,$00,$00,$80,$00,$FF,$F4,$FF,$FF,$FF,$FF,$FF
        .byte   $7F,$02,$04,$FE,$01,$80,$C0,$60,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F
        .byte   $00,$FC,$FE,$FE,$4E,$16,$06,$06,$00,$FC,$0E,$F6,$FA,$FA,$FE,$FE
        .byte   $FE,$16,$06,$06,$FE,$16,$0E,$0E,$FA,$FE,$FA,$FA,$FE,$FA,$FA,$FA
        .byte   $00,$3F,$7F,$7F,$7F,$7C,$78,$78,$00,$3F,$70,$63,$67,$6F,$6F,$6F
        .byte   $77,$72,$54,$7E,$41,$70,$3F,$00,$7F,$6F,$7F,$7F,$7F,$7F,$3F,$00
        .byte   $00,$FF,$FF,$FE,$01,$01,$01,$03,$00,$FF,$6F,$FF,$FF,$FF,$FF,$FF
        .byte   $FC,$00,$00,$00,$FF,$36,$FF,$00,$FF,$FF,$FF,$FF,$FF,$D9,$FF,$00
        .byte   $00,$FF,$FF,$7F,$80,$00,$00,$80,$00,$FF,$87,$FF,$FF,$FF,$FF,$FF
        .byte   $7F,$02,$04,$FE,$01,$33,$FF,$00,$FF,$FF,$FF,$FF,$FF,$CC,$FF,$00
        .byte   $00,$FF,$FF,$F3,$01,$01,$01,$03,$00,$FF,$BF,$FF,$FF,$FF,$FF,$FF
        .byte   $FE,$00,$00,$00,$FF,$F7,$FF,$00,$FF,$FF,$FF,$FF,$FF,$18,$FF,$00
        .byte   $00,$FF,$E0,$7F,$80,$00,$00,$80,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $7F,$02,$04,$FE,$01,$7F,$FF,$00,$FF,$FF,$FF,$FF,$FF,$80,$FF,$00
        .byte   $00,$FC,$86,$E2,$06,$02,$06,$06,$00,$FC,$FE,$FE,$FA,$FE,$FA,$FA
        .byte   $F6,$0E,$0E,$1A,$7A,$EE,$FC,$00,$FA,$F2,$F2,$E6,$86,$1E,$FC,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FB,$F7,$F7,$F7,$F7,$04,$FF,$00,$08,$0C,$0C,$0C,$0C,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FE,$FE,$FE,$FE,$00,$FF,$00,$01,$01,$01,$01,$01,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$80,$FF,$80,$80,$80,$80,$80,$80,$FF,$FF
        .byte   $F7,$F7,$F7,$F7,$F7,$F7,$04,$FF,$0C,$0C,$0C,$0C,$0C,$0C,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$00,$FF,$01,$01,$01,$01,$01,$01,$FF,$FF
        .byte   $F7,$F7,$F7,$F7,$F7,$F7,$04,$FF,$0C,$0C,$0C,$0C,$0C,$0C,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$80,$FF,$80,$80,$80,$80,$80,$80,$FF,$FF
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$00,$FF,$01,$01,$01,$01,$01,$01,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $60,$7F,$60,$7F,$60,$60,$60,$60,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $7F,$62,$6C,$7E,$71,$3F,$1F,$00,$7F,$7F,$7F,$7F,$7F,$3F,$1F,$00
        .byte   $07,$F3,$11,$FE,$01,$01,$01,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FE,$00,$00,$FF,$80,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $68,$FF,$D0,$7F,$C0,$00,$00,$80,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $7F,$02,$04,$FE,$00,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$00,$FF,$00
        .byte   $0E,$F6,$16,$F6,$06,$06,$06,$06,$FE,$FA,$FE,$FA,$FA,$FE,$FA,$FA
        .byte   $FE,$0E,$1E,$3E,$FE,$DC,$F8,$00,$F2,$F2,$E6,$C6,$0E,$3C,$F8,$00
        .byte   $00,$3F,$7F,$7F,$7E,$7C,$78,$78,$00,$3F,$70,$63,$47,$4F,$5F,$5F
        .byte   $7B,$7A,$74,$7E,$71,$40,$60,$40,$5F,$5F,$7F,$5F,$7F,$7F,$5F,$7F
        .byte   $00,$F8,$DC,$BE,$06,$02,$02,$02,$00,$F8,$BC,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$02,$06,$02,$FE,$16,$0E,$0A,$FE,$FE,$FA,$FE,$FE,$FA,$FA,$FE
        .byte   $60,$7F,$60,$7F,$60,$60,$60,$60,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $7F,$62,$64,$7E,$61,$60,$60,$60,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $1E,$F6,$06,$FE,$06,$06,$06,$06,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FA
        .byte   $FE,$06,$06,$06,$FE,$06,$06,$06,$FA,$FA,$FE,$FE,$FE,$FA,$FE,$FA
        .byte   $60,$7F,$40,$7F,$60,$40,$40,$60,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $7F,$42,$44,$7E,$61,$7B,$3F,$00,$7F,$7F,$7F,$7F,$7F,$74,$3F,$00
        .byte   $1E,$F6,$16,$FE,$06,$06,$06,$06,$FE,$FA,$FA,$FA,$FA,$FA,$FA,$FA
        .byte   $F6,$0E,$0E,$1A,$FA,$EE,$FC,$00,$FA,$F2,$F2,$E6,$C6,$1E,$FC,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$FF,$FF,$FF,$FF,$80,$FF,$00,$00,$80,$80,$80,$80,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$FF,$FF,$FF,$00,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $A6,$70,$7F,$7F,$3F,$7F,$7F,$3F,$40,$30,$3F,$3F,$1C,$23,$36,$02
        .byte   $6C,$FE,$F9,$F1,$FA,$FE,$FC,$F8,$70,$CC,$BE,$6E,$DC,$3C,$D8,$F0
        .byte   $03,$03,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FC,$F8,$FC,$FA,$41,$71,$82,$FC,$18,$00,$60,$7C,$3E,$0E,$7C,$00
        .byte   $3F,$29,$1C,$1F,$3F,$7F,$7E,$3C,$02,$10,$0C,$07,$18,$3E,$3F,$1F
        .byte   $92,$9B,$3D,$FF,$FF,$1F,$0F,$1F,$1C,$1C,$03,$B9,$7D,$FE,$FE,$EE
        .byte   $00,$00,$C0,$E0,$F0,$F0,$F0,$E0,$00,$00,$00,$C0,$E0,$E0,$E0,$00
        .byte   $1E,$0F,$0F,$1F,$13,$38,$40,$7F,$07,$00,$04,$0E,$0F,$07,$3F,$00
        .byte   $7F,$FF,$FF,$FF,$87,$83,$40,$C0,$9C,$30,$00,$00,$01,$00,$80,$00
        .byte   $90,$88,$C4,$E4,$F8,$80,$00,$00,$60,$F0,$F8,$D8,$80,$00,$00,$00
        .byte   $07,$1A,$28,$20,$43,$85,$C8,$8D,$00,$05,$17,$1F,$3C,$7A,$37,$72
        .byte   $E0,$58,$14,$02,$C6,$A1,$13,$B1,$00,$A0,$E8,$FC,$38,$5E,$EC,$4E
        .byte   $02,$0D,$14,$30,$53,$46,$8E,$49,$00,$02,$0B,$0F,$2C,$39,$71,$36
        .byte   $40,$B0,$08,$1C,$C2,$66,$71,$92,$00,$40,$F0,$E0,$3C,$98,$8E,$6C
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$03,$07,$0F,$00,$00,$00,$00,$00,$00,$03,$07
        .byte   $00,$00,$07,$1F,$39,$F9,$E7,$EF,$00,$00,$00,$07,$1A,$1E,$A7,$E2
        .byte   $00,$00,$E1,$FF,$FF,$9F,$1F,$9F,$00,$00,$00,$E1,$FB,$9F,$1F,$1F
        .byte   $00,$00,$E0,$F0,$F8,$F0,$F8,$F8,$00,$00,$00,$E0,$F0,$E0,$E0,$C0
        .byte   $0F,$0F,$1F,$3F,$3F,$7F,$7D,$CD,$07,$07,$03,$03,$01,$00,$30,$78
        .byte   $ED,$F2,$F8,$F7,$EC,$EC,$DF,$DD,$E0,$B2,$DF,$78,$B3,$F3,$E0,$E3
        .byte   $BF,$7F,$3F,$CF,$F7,$F7,$FB,$FB,$3B,$77,$FD,$3B,$0F,$0F,$07,$07
        .byte   $FC,$FC,$FE,$FA,$D1,$D1,$A1,$B1,$C0,$80,$80,$84,$8E,$8E,$1E,$0E
        .byte   $FC,$B4,$84,$84,$B4,$FC,$FC,$78,$30,$48,$78,$78,$48,$30,$00,$00
        .byte   $DB,$EB,$6F,$37,$18,$1F,$3F,$7F,$67,$74,$30,$18,$0F,$03,$00,$00
        .byte   $9B,$97,$F6,$CE,$3F,$FF,$FF,$FF,$66,$6E,$0C,$38,$F0,$C0,$00,$00
        .byte   $42,$82,$84,$84,$44,$38,$80,$C0,$3C,$7C,$78,$78,$38,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$02,$04,$07,$00,$00,$00,$00,$00,$01,$03,$00
        .byte   $7C,$D8,$88,$84,$84,$04,$02,$FE,$00,$20,$70,$78,$78,$F8,$FC,$00
        .byte   $0F,$03,$02,$02,$02,$01,$02,$03,$00,$00,$01,$01,$01,$00,$01,$00
        .byte   $C0,$20,$10,$10,$0C,$02,$01,$FF,$00,$C0,$E0,$E0,$F0,$FC,$FE,$00
        .byte   $00,$00,$00,$00,$01,$07,$0E,$FE,$00,$00,$00,$00,$00,$01,$06,$07
        .byte   $00,$00,$00,$00,$F8,$FF,$7F,$67,$00,$00,$00,$00,$00,$F8,$BE,$A7
        .byte   $00,$00,$00,$00,$78,$FD,$FF,$FF,$00,$00,$00,$00,$00,$78,$F8,$F8
        .byte   $00,$00,$00,$00,$00,$E0,$98,$04,$00,$00,$00,$00,$00,$00,$60,$F8
        .byte   $3F,$7F,$CF,$BF,$8F,$87,$87,$B7,$03,$37,$77,$77,$73,$7B,$79,$48
        .byte   $E7,$EF,$ED,$F2,$F8,$F7,$EC,$EC,$A7,$E2,$E0,$B2,$DF,$78,$B3,$F3
        .byte   $1F,$9F,$BF,$7F,$3F,$CF,$F7,$F7,$1F,$1F,$3B,$77,$FD,$3B,$0F,$0F
        .byte   $FD,$FE,$FE,$F1,$E0,$C0,$C0,$C0,$C2,$C1,$C1,$80,$80,$80,$80,$80
        .byte   $08,$08,$08,$10,$E0,$00,$00,$00,$F0,$F0,$F0,$E0,$00,$00,$00,$00
        .byte   $FD,$FD,$78,$00,$00,$00,$00,$00,$30,$00,$00,$00,$00,$00,$00,$00
        .byte   $DF,$DD,$DB,$EB,$6F,$37,$78,$FF,$E0,$E3,$67,$74,$30,$18,$0F,$03
        .byte   $FB,$FB,$9B,$97,$F7,$CF,$3F,$FF,$07,$07,$66,$6E,$0C,$38,$F0,$C0
        .byte   $80,$80,$00,$00,$00,$C0,$F0,$F8,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$01,$01,$01,$00,$03,$04,$07,$00,$00,$00,$00,$00,$00,$03,$00
        .byte   $FF,$3E,$08,$88,$C4,$04,$02,$FE,$00,$C0,$F0,$70,$38,$F8,$FC,$00
        .byte   $FF,$03,$01,$01,$01,$02,$02,$03,$00,$00,$00,$00,$00,$01,$01,$00
        .byte   $C8,$84,$04,$08,$38,$06,$01,$FF,$30,$78,$F8,$F0,$C0,$F8,$FE,$00
        .byte   $E7,$EF,$ED,$F2,$F8,$F7,$EF,$EB,$A7,$E2,$E0,$B2,$DF,$78,$B0,$F4
        .byte   $1F,$9F,$BF,$7F,$3F,$CF,$F7,$97,$1F,$1F,$3B,$77,$FD,$3B,$0F,$6F
        .byte   $D3,$DD,$DF,$EF,$6E,$37,$78,$FF,$EC,$E3,$63,$70,$31,$18,$1F,$03
        .byte   $9B,$FB,$FB,$77,$77,$CF,$3F,$FF,$67,$07,$06,$8E,$8C,$38,$F0,$C0
        .byte   $FD,$FD,$78,$00,$00,$00,$01,$03,$30,$00,$00,$00,$00,$00,$00,$00
        .byte   $DF,$DD,$DB,$EB,$6F,$37,$F8,$FF,$E0,$E3,$67,$74,$30,$18,$0F,$03
        .byte   $FB,$FB,$9B,$97,$F7,$CF,$3F,$FF,$07,$07,$66,$6E,$0C,$38,$F0,$C0
        .byte   $80,$80,$00,$00,$C0,$E0,$90,$08,$00,$00,$00,$00,$00,$00,$60,$F0
        .byte   $9F,$87,$82,$82,$41,$41,$82,$84,$60,$78,$7C,$7C,$3E,$3E,$7C,$78
        .byte   $FF,$E7,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $C1,$81,$82,$04,$84,$82,$42,$22,$3E,$7E,$7C,$F8,$78,$7C,$3C,$1C
        .byte   $88,$70,$00,$00,$00,$00,$00,$00,$70,$00,$00,$00,$00,$00,$00,$00
        .byte   $1C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$07,$0E,$FE,$00,$00,$00,$00,$00,$01,$06,$07
        .byte   $00,$00,$00,$00,$F8,$FF,$7F,$67,$00,$00,$00,$00,$00,$F8,$BE,$A7
        .byte   $03,$0F,$13,$21,$41,$43,$86,$9B,$00,$03,$0F,$1F,$3F,$3E,$78,$60
        .byte   $F0,$FC,$8E,$F7,$FE,$3C,$34,$37,$00,$F0,$FC,$FE,$30,$18,$18,$18
        .byte   $00,$E0,$98,$86,$47,$4F,$3F,$3F,$00,$00,$60,$78,$3A,$37,$0F,$1F
        .byte   $73,$E0,$EF,$F0,$7F,$BE,$9F,$DF,$00,$40,$40,$60,$30,$5D,$65,$A0
        .byte   $7F,$7F,$7E,$FE,$FE,$FF,$FF,$EF,$27,$2E,$1D,$7D,$FD,$78,$63,$16
        .byte   $C0,$C0,$40,$20,$E0,$F0,$F0,$F0,$80,$00,$80,$C0,$00,$E0,$E0,$E0
        .byte   $19,$0C,$07,$01,$01,$07,$0F,$0F,$0F,$07,$00,$00,$00,$01,$07,$00
        .byte   $F0,$C0,$83,$DC,$F8,$F8,$FC,$FC,$8F,$BF,$7C,$E0,$F0,$F0,$F8,$00
        .byte   $1E,$1D,$E7,$23,$43,$4F,$77,$07,$ED,$E6,$1B,$1D,$3C,$31,$03,$00
        .byte   $E0,$E0,$C0,$C0,$F0,$FC,$FE,$FE,$40,$C0,$80,$00,$C0,$F0,$FC,$00
        .byte   $00,$00,$E0,$98,$86,$47,$4F,$3F,$00,$00,$00,$60,$78,$3A,$37,$0F
        .byte   $00,$00,$00,$00,$00,$00,$80,$C0,$00,$00,$00,$00,$00,$00,$00,$80
        .byte   $3F,$19,$0C,$07,$01,$00,$01,$01,$1F,$0F,$07,$00,$00,$00,$00,$00
        .byte   $C7,$FF,$A7,$43,$83,$86,$0C,$36,$80,$87,$5F,$BF,$7E,$7C,$F0,$C0
        .byte   $E0,$F8,$1C,$EE,$FC,$78,$68,$6C,$00,$E0,$F8,$FC,$60,$30,$30,$30
        .byte   $00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$01
        .byte   $E6,$40,$5E,$21,$1F,$6F,$87,$06,$00,$00,$00,$00,$00,$17,$7A,$FB
        .byte   $FC,$FA,$F2,$F2,$E2,$E4,$F4,$3C,$48,$54,$2C,$EC,$1C,$98,$68,$F0
        .byte   $01,$00,$00,$01,$01,$07,$0F,$0F,$00,$00,$00,$00,$00,$01,$07,$00
        .byte   $87,$6F,$9F,$C4,$F8,$F8,$FC,$FC,$7A,$17,$60,$F8,$F0,$F0,$F8,$00
        .byte   $FA,$E1,$E1,$1B,$07,$03,$07,$07,$64,$9E,$1F,$07,$03,$01,$03,$00
        .byte   $00,$00,$80,$C0,$F0,$FC,$FE,$FE,$00,$00,$00,$80,$C0,$F0,$FC,$00
        .byte   $04,$0A,$0A,$11,$11,$20,$31,$3F,$00,$04,$04,$0E,$0E,$1F,$0E,$11
        .byte   $00,$03,$04,$08,$10,$90,$A1,$A6,$00,$00,$03,$07,$0F,$0F,$1E,$18
        .byte   $FC,$FF,$E3,$7D,$7F,$CF,$8D,$CD,$00,$FC,$FF,$FF,$CC,$86,$06,$06
        .byte   $00,$00,$80,$D0,$A8,$28,$44,$C4,$00,$00,$00,$80,$10,$10,$38,$38
        .byte   $3F,$3F,$37,$13,$1B,$0E,$07,$00,$1F,$1F,$1F,$0E,$0E,$05,$00,$00
        .byte   $9C,$F8,$BB,$3C,$1F,$7F,$87,$05,$00,$10,$50,$D8,$EC,$87,$01,$02
        .byte   $DF,$1F,$DF,$3F,$FF,$BF,$FF,$F9,$09,$0B,$07,$1F,$3F,$5E,$58,$06
        .byte   $82,$C6,$FE,$FE,$EE,$EE,$EC,$7C,$7C,$38,$44,$7C,$54,$54,$38,$38
        .byte   $00,$00,$00,$00,$01,$07,$0F,$0F,$00,$00,$00,$00,$00,$01,$07,$00
        .byte   $08,$10,$31,$7A,$FC,$FC,$FC,$FC,$07,$0F,$1E,$3C,$78,$F0,$F8,$00
        .byte   $00,$00,$FC,$03,$03,$03,$07,$07,$FF,$FF,$03,$01,$01,$01,$03,$00
        .byte   $B8,$50,$E0,$E0,$F0,$FC,$FE,$FE,$10,$80,$C0,$C0,$E0,$F0,$FC,$00
        .byte   $10,$20,$43,$C4,$E4,$FC,$7E,$7E,$0F,$1F,$3C,$78,$78,$78,$3C,$3C
        .byte   $04,$04,$84,$44,$44,$5C,$7C,$7C,$F8,$F8,$78,$38,$38,$38,$38,$38
        .byte   $E0,$40,$00,$00,$00,$00,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00
        .byte   $7C,$F9,$F1,$61,$01,$00,$00,$00,$38,$70,$60,$00,$00,$00,$00,$00
        .byte   $FC,$FC,$F8,$F8,$F0,$F0,$60,$00,$78,$F8,$F0,$F0,$E0,$60,$00,$00
        .byte   $00,$01,$02,$04,$08,$08,$10,$F3,$00,$00,$01,$03,$07,$07,$0F,$0C
        .byte   $7E,$FF,$71,$3E,$3F,$67,$C7,$64,$00,$7E,$FF,$FF,$E6,$C3,$00,$03
        .byte   $00,$80,$C0,$E0,$C0,$80,$F0,$C8,$00,$00,$80,$C0,$00,$00,$00,$30
        .byte   $9E,$8C,$4D,$4E,$3F,$3F,$1E,$0C,$60,$70,$30,$34,$0A,$1C,$0D,$03
        .byte   $6C,$0E,$EE,$1F,$FF,$DF,$FC,$00,$03,$05,$01,$0E,$1E,$AC,$03,$FF
        .byte   $34,$3A,$7E,$FE,$EE,$F7,$FF,$BF,$C8,$D4,$B8,$6C,$D4,$6E,$3E,$0E
        .byte   $08,$18,$1C,$1F,$0F,$0F,$0F,$1F,$07,$0F,$0F,$0F,$07,$07,$07,$0E
        .byte   $70,$88,$88,$8B,$CF,$CF,$9F,$3F,$8F,$07,$07,$07,$87,$87,$0F,$1F
        .byte   $8E,$80,$80,$80,$80,$80,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $1E,$0C,$00,$00,$00,$00,$00,$00,$0C,$00,$00,$00,$00,$00,$00,$00
        .byte   $3F,$3F,$3E,$1E,$0C,$00,$00,$00,$1E,$1E,$1C,$0C,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$03,$0F,$13,$21,$00,$00,$00,$00,$00,$03,$0F,$1F
        .byte   $00,$00,$00,$00,$F0,$FC,$8E,$F7,$00,$00,$00,$00,$00,$F0,$FC,$FE
        .byte   $41,$43,$86,$9B,$73,$20,$2F,$10,$3F,$3E,$78,$60,$00,$00,$00,$00
        .byte   $FE,$3C,$34,$37,$7F,$7F,$79,$F1,$30,$18,$18,$18,$37,$28,$16,$6E
        .byte   $00,$00,$00,$00,$80,$C0,$C0,$C0,$00,$00,$00,$00,$00,$80,$80,$80
        .byte   $03,$07,$0F,$1F,$1F,$1F,$0F,$07,$00,$03,$07,$0F,$07,$03,$01,$00
        .byte   $2F,$EF,$F7,$DF,$9F,$BE,$FF,$DF,$10,$17,$E8,$E3,$E6,$CD,$C6,$83
        .byte   $E1,$E2,$F4,$FA,$71,$F1,$F1,$F3,$9E,$1D,$EB,$E1,$E0,$40,$C0,$A1
        .byte   $80,$40,$20,$10,$18,$38,$F8,$F0,$00,$80,$C0,$E0,$F0,$F0,$F0,$E0
        .byte   $8F,$07,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $F3,$F9,$FC,$FC,$FC,$7C,$78,$30,$61,$F0,$F8,$78,$78,$38,$30,$00
        .byte   $F0,$F0,$F8,$78,$30,$00,$00,$00,$E0,$E0,$70,$30,$00,$00,$00,$00
        .byte   $F0,$FC,$8E,$F7,$FE,$3F,$37,$37,$00,$F0,$FC,$FE,$30,$18,$1A,$1A
        .byte   $00,$00,$00,$00,$00,$E0,$18,$1C,$00,$00,$00,$00,$00,$00,$E0,$E8
        .byte   $7E,$7F,$7E,$FC,$FC,$FC,$F5,$EB,$25,$2C,$1C,$78,$F8,$70,$68,$15
        .byte   $3E,$F6,$77,$77,$7F,$7F,$E3,$C1,$DC,$1C,$2A,$2A,$3E,$22,$1C,$BE
        .byte   $19,$0C,$07,$00,$00,$00,$00,$00,$0F,$07,$00,$00,$00,$00,$00,$00
        .byte   $E6,$C4,$86,$0F,$0F,$0F,$1F,$1F,$81,$83,$03,$07,$07,$03,$0F,$00
        .byte   $0B,$17,$2F,$FF,$E3,$F1,$F0,$F0,$F7,$EF,$DD,$83,$C1,$E0,$E0,$00
        .byte   $E1,$E2,$F2,$F4,$E8,$C0,$00,$00,$DE,$DC,$CC,$C8,$C0,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$FC,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $0F,$13,$21,$41,$43,$86,$9B,$73,$03,$0F,$1F,$3F,$3E,$78,$60,$00
        .byte   $FC,$8E,$F7,$FE,$3C,$34,$34,$7C,$F0,$FC,$FE,$30,$18,$18,$18,$20
        .byte   $81,$BD,$C3,$FF,$7B,$3F,$3F,$23,$00,$00,$01,$43,$35,$15,$00,$1D
        .byte   $F8,$F4,$F2,$FD,$FF,$FE,$FE,$DC,$B0,$68,$EC,$C2,$9C,$7C,$DC,$A8
        .byte   $27,$14,$0C,$08,$09,$0F,$07,$07,$18,$0B,$03,$07,$06,$00,$03,$00
        .byte   $BC,$FC,$7E,$7E,$FE,$FC,$F8,$F0,$D8,$70,$AC,$9C,$7C,$F8,$F0,$00
        .byte   $1C,$08,$0B,$04,$07,$1B,$61,$81,$00,$00,$00,$00,$00,$05,$1E,$7E
        .byte   $DF,$1D,$DC,$3C,$F8,$F8,$FD,$8F,$08,$0A,$03,$1B,$07,$E7,$9A,$FC
        .byte   $F0,$98,$CC,$FE,$FE,$FA,$F2,$F9,$C0,$F0,$78,$7C,$78,$74,$0C,$76
        .byte   $61,$1B,$1F,$1C,$1F,$7F,$FF,$FF,$1E,$05,$08,$0F,$0E,$1F,$7F,$00
        .byte   $FC,$F8,$F1,$8B,$07,$80,$C0,$C0,$9B,$E7,$0F,$07,$00,$00,$80,$00
        .byte   $FD,$FF,$FC,$FC,$FC,$7C,$38,$00,$F2,$F8,$B8,$78,$78,$38,$00,$00
        .byte   $00,$00,$11,$10,$7E,$42,$3C,$00,$03,$07,$13,$32,$7E,$42,$3C,$00
        .byte   $1F,$3E,$73,$F9,$FF,$FE,$FC,$B8,$00,$1F,$3F,$7F,$7F,$7F,$7F,$7F
        .byte   $00,$80,$40,$40,$60,$70,$50,$D0,$00,$00,$80,$80,$80,$A0,$A0,$60
        .byte   $41,$3F,$0C,$07,$00,$00,$00,$00,$3E,$01,$07,$00,$00,$00,$00,$00
        .byte   $90,$48,$28,$88,$78,$00,$00,$00,$60,$B0,$D0,$70,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$3E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7D,$E6,$F2,$FE,$FC,$F8,$71,$82,$3E,$7F,$FF,$FF,$FF,$FF,$FE,$7C
        .byte   $00,$00,$00,$00,$00,$00,$7C,$FA,$00,$00,$00,$00,$00,$00,$00,$7C
        .byte   $01,$03,$03,$03,$03,$02,$01,$00,$00,$01,$01,$01,$01,$01,$00,$00
        .byte   $CD,$E5,$FD,$F9,$F1,$E2,$04,$F8,$FE,$FE,$FE,$FE,$FE,$FC,$F8,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; =============================================================================
; screen_conn_flags — per-screen room connectivity ($B400)
; Read by get_screen_boundary; masked by scroll_left/right_mask_table
; per transition_type to decide legal room exits.
; =============================================================================
screen_conn_flags:
        .byte   $46,$40,$40,$40,$40,$40,$40,$24 ; screens $00-$07
        .byte   $20,$00,$40,$40,$40,$25,$00,$00 ; screens $08-$0F
        .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; screens $10-$17
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; screens $18-$1F
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; screens $20-$27
        .byte   $FF,$FF,$FF,$FF ; screens $28-$2F

; ─── screen_overlay_base — per-screen offset into overlay sets below ($B42C) ───
screen_overlay_base:
        .byte   $00,$12,$00,$00,$24,$00,$12,$12
        .byte   $00,$36,$6C,$6C,$6C,$6C,$48,$5A
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF

; =============================================================================
; chr_overlay_sets — 18-byte sets: 6 × (src_page, src_bank) CHR pairs ($B460)
; + 6 sprite palette bytes. Indexed by screen_overlay_base; streams the
; per-screen enemy CHR overlay to pattern table $0A00-$0FFF.
; =============================================================================
chr_overlay_sets:
; ─── set 0 (base $00) ───
        .byte   $98,$03,$99,$03,$92,$04,$9E,$03,$93,$04,$9F,$03
        .byte   $0F,$11,$30,$0F,$15,$28
; ─── set 1 (base $12) ───
        .byte   $91,$03,$92,$03,$93,$03,$94,$03,$95,$03,$9F,$03
        .byte   $0F,$26,$30,$0F,$14,$34
; ─── set 2 (base $24) ───
        .byte   $98,$03,$99,$03,$9A,$03,$9E,$04,$90,$03,$9F,$03
        .byte   $0F,$15,$27,$0F,$11,$3C
; ─── set 3 (base $36) ───
        .byte   $9E,$06,$9F,$06,$96,$07,$97,$07,$9E,$07,$9F,$07
        .byte   $30,$30,$28,$0F,$30,$12
; ─── set 4 (base $48) ───
        .byte   $9C,$00,$9D,$00,$9E,$00,$94,$06,$95,$06,$9F,$00
        .byte   $0F,$11,$2C,$0F,$0F,$0F
; ─── set 5 (base $5A) ───
        .byte   $BA,$08,$BB,$08,$95,$05,$96,$05,$95,$02,$9F,$00
        .byte   $0F,$2C,$15,$0F,$38,$15
; ─── set 6 (base $6C) ───
        .byte   $9D,$02,$90,$03,$95,$05,$96,$05,$95,$02,$9F,$00
        .byte   $00,$05,$26,$0F,$38,$15
; ─── set 7 (base $7E) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 8 (base $90) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 9 (base $A2) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 10 (base $B4) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 11 (base $C6) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 12 (base $D8) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 13 (base $EA) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 14 (base $FC) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 15 (base $10E) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 16 (base $120) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 17 (base $132) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 18 (base $144) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 19 (base $156) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 20 (base $168) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 21 (base $17A) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
; ─── set 22 (base $18C) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF

; =============================================================================
; spawn_screen_tbl — primary spawn screen number (1-indexed, sorted by screen) ($B600)
; =============================================================================
spawn_screen_tbl:
        .byte   $02,$03,$03,$04,$04,$06,$07,$08,$0A,$0A,$0B,$0C,$0D,$0F,$11,$1A ; $00+
        .byte   $1A,$1A,$1A,$1B,$1B,$1B,$1B,$1B,$1C,$1C,$1C,$1C,$1D,$1D,$1D,$1E ; $10+
        .byte   $1E,$1E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $30+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $40+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $50+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $60+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $70+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $80+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $90+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $A0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $B0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $C0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $D0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $E0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $F0+

; =============================================================================
; spawn_x_tbl — primary spawn X position (1-indexed, sorted by screen) ($B700)
; =============================================================================
spawn_x_tbl:
        .byte   $84,$9C,$EC,$24,$CC,$44,$40,$68,$A8,$D8,$88,$68,$F8,$38,$08,$18 ; $00+
        .byte   $58,$B0,$D0,$28,$48,$70,$B0,$E8,$28,$78,$A0,$C8,$68,$90,$B8,$30 ; $10+
        .byte   $78,$B0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $30+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $40+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $50+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $60+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $70+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $80+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $90+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $A0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $B0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $C0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $D0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $E0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $F0+

; =============================================================================
; spawn_y_tbl — primary spawn Y position (1-indexed, sorted by screen) ($B800)
; =============================================================================
spawn_y_tbl:
        .byte   $C4,$94,$94,$34,$94,$94,$84,$84,$9C,$6C,$B0,$B4,$B4,$B4,$84,$34 ; $00+
        .byte   $44,$24,$44,$24,$34,$44,$34,$54,$64,$64,$64,$64,$64,$64,$64,$64 ; $10+
        .byte   $44,$44,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $30+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $40+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $50+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $60+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $70+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $80+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $90+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $A0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $B0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $C0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $D0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $E0+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $F0+

; =============================================================================
; spawn_type_tbl — primary spawn entity type IDs ($B900)
; =============================================================================
spawn_type_tbl:
        .byte   $4B,$4B,$4C,$4B,$4B,$4C,$4E,$4B ; $00+: CrazyCannon/CrazyCannon/CrazyCannonFlip/CrazyCannon/CrazyCannon/CrazyCannonFlip/SniperArmor/CrazyCannon
        .byte   $50,$50,$31,$4E,$4E,$4E,$4E,$72 ; $08+: ScwormNest/ScwormNest/Blocky/SniperArmor/SniperArmor/SniperArmor/SniperArmor/FlashHazardA
        .byte   $73,$72,$73,$72,$73,$72,$73,$72 ; $10+: FlashHazardB/FlashHazardA/FlashHazardB/FlashHazardA/FlashHazardB/FlashHazardA/FlashHazardB/FlashHazardA
        .byte   $73,$72,$73,$72,$73,$72,$73,$72 ; $18+: FlashHazardB/FlashHazardA/FlashHazardB/FlashHazardA/FlashHazardB/FlashHazardA/FlashHazardB/FlashHazardA
        .byte   $73,$72,$FF,$FF,$FF,$FF,$FF,$FF ; $20+: FlashHazardB/FlashHazardA/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $28+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $30+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $38+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $40+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $48+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $50+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $58+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $60+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $68+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $70+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $78+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $80+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $88+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $90+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $98+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $A0+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $A8+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $B0+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $B8+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $C0+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $C8+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $D0+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $D8+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $E0+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $E8+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $F0+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $F8+: ?/?/?/?/?/?/?/?

; ─── spawn2_screen_tbl — secondary (persistent) spawns, max 64 ($BA00) ───
spawn2_screen_tbl:
        .byte   $02,$04,$05,$06,$06,$06,$09,$09,$0A,$0C,$10,$11,$11,$11,$12,$12
        .byte   $13,$13,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_x_tbl — secondary (persistent) spawns, max 64 ($BA40) ───
spawn2_x_tbl:
        .byte   $C8,$58,$58,$68,$98,$C8,$70,$98,$58,$E8,$C8,$98,$F8,$F8,$F8,$F8
        .byte   $08,$08,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_y_tbl — secondary (persistent) spawns, max 64 ($BA80) ───
spawn2_y_tbl:
        .byte   $98,$8F,$38,$2F,$2F,$2F,$78,$6F,$3A,$D8,$38,$2F,$4F,$6F,$4F,$6F
        .byte   $4F,$6F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_type_tbl — secondary spawn types ($BAC0) ───
spawn2_type_tbl:
        .byte   $76,$57,$7B,$2D,$2D,$2D,$76,$2D ; $00+: LargeHealth/CrashWall/ExtraLife/CrashWallVar/CrashWallVar/CrashWallVar/LargeHealth/CrashWallVar
        .byte   $78,$76,$7A,$2D,$2F,$2F,$2F,$2F ; $08+: LargeWeapon/LargeHealth/Etank/CrashWallVar/BossDoor/BossDoor/BossDoor/BossDoor
        .byte   $2F,$2F,$FF,$FF,$FF,$FF,$FF,$FF ; $10+: BossDoor/BossDoor/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $18+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $28+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $30+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $38+: ?/?/?/?/?/?/?/?

; =============================================================================
; Checkpoint tables — 11 arrays × 6 slots ($BB00-$BB41)
; Indexed by checkpoint_idx ($B0): slots 0-2 = Flash Man,
; slots 3-5 = Wily 6. Restored by checkpoint_respawn (bank0F:865).
; =============================================================================
chk_boss_entry_y:  .byte   $94,$84,$74,$84,$84,$84 ; boss-entrance landing Y
chk_screen:  .byte   $00,$08,$12,$16,$16,$16 ; checkpoint screen (nametable_select)
chk_spawn_idx:  .byte   $00,$07,$0F,$0F,$0F,$0F ; primary spawn scan index
chk_spawn2_idx:  .byte   $00,$06,$0E,$12,$12,$12 ; secondary spawn scan index
chk_metatile_hi:  .byte   $84,$86,$89,$8A,$8A,$8A ; metatile_ptr high
chk_metatile_lo:  .byte   $E0,$E0,$60,$60,$60,$60 ; metatile_ptr low
chk_column_hi:  .byte   $85,$87,$89,$8A,$8A,$8A ; column_ptr high
chk_column_lo:  .byte   $60,$60,$E0,$E0,$E0,$E0 ; column_ptr low
chk_cur_screen:  .byte   $00,$02,$08,$0A,$0A,$0A ; current_screen (room index)
chk_scroll_lo:  .byte   $00,$08,$12,$16,$16,$16 ; scroll_screen_lo (left bound)
chk_scroll_hi:  .byte   $06,$08,$12,$16,$16,$16 ; scroll_screen_hi (right bound)
; ─── $BB42-$BBFF ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; =============================================================================
; chr_upload_list_rm — CHR-RAM upload records: Flash Man ($BC00)
; [record count, then (src_page, page_count, src_bank) × N] → CHR $0000+
; =============================================================================
chr_upload_list_rm:
        .byte   $06                     ; 6 records
        .byte   $90,$09,$00             ; CHR $0000+: $9000 × 9 pages from bank $00
        .byte   $84,$01,$09             ; CHR $0900+: $8400 × 1 pages from bank $09
        .byte   $98,$05,$03             ; CHR $0A00+: $9800 × 5 pages from bank $03
        .byte   $9F,$01,$03             ; CHR $0F00+: $9F00 × 1 pages from bank $03
        .byte   $80,$06,$09             ; CHR $1000+: $8000 × 6 pages from bank $09
        .byte   $A0,$0A,$05             ; CHR $1600+: $A000 × 10 pages from bank $05
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; =============================================================================
; chr_upload_list_wily — CHR-RAM upload records: Wily 6 ($BD00)
; [record count, then (src_page, page_count, src_bank) × N] → CHR $0000+
; =============================================================================
chr_upload_list_wily:
        .byte   $06                     ; 6 records
        .byte   $90,$09,$00             ; CHR $0000+: $9000 × 9 pages from bank $00
        .byte   $84,$01,$09             ; CHR $0900+: $8400 × 1 pages from bank $09
        .byte   $98,$05,$03             ; CHR $0A00+: $9800 × 5 pages from bank $03
        .byte   $9F,$01,$03             ; CHR $0F00+: $9F00 × 1 pages from bank $03
        .byte   $80,$08,$09             ; CHR $1000+: $8000 × 8 pages from bank $09
        .byte   $B0,$08,$02             ; CHR $1800+: $B000 × 8 pages from bank $02
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; =============================================================================
; palette_block_rm — Flash Man palettes ($BE00)
; [anim_target, anim_counter, 32-byte palette (BG+sprite), 4 × 16-byte
; palette animation frames] — copied verbatim to $0354-$03B5.
; =============================================================================
palette_block_rm:
        .byte   $03,$20                 ; anim target, counter
        .byte   $0F,$2B,$12,$02,$0F,$20,$21,$11,$0F,$20,$21,$11,$0F,$20,$21,$11 ; palette
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$20,$38,$0F,$0F,$11,$30,$0F,$0F,$15,$28
        .byte   $0F,$2B,$12,$02,$0F,$30,$31,$2C,$0F,$20,$21,$11,$0F,$20,$21,$11 ; anim frame 0
        .byte   $0F,$2B,$12,$02,$0F,$20,$21,$11,$0F,$30,$31,$2C,$0F,$20,$21,$11 ; anim frame 1
        .byte   $0F,$2B,$12,$02,$0F,$20,$21,$11,$0F,$20,$21,$11,$0F,$30,$31,$2C ; anim frame 2
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; anim frame 3
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; =============================================================================
; palette_block_wily — Wily 6 palettes ($BF00)
; [anim_target, anim_counter, 32-byte palette (BG+sprite), 4 × 16-byte
; palette animation frames] — copied verbatim to $0354-$03B5.
; =============================================================================
palette_block_wily:
        .byte   $00,$00                 ; anim target, counter
        .byte   $0F,$27,$18,$0A,$0F,$0F,$0B,$0F,$0F,$20,$10,$00,$0F,$0B,$0F,$0B ; palette
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$20,$38,$0F,$0F,$11,$30,$0F,$0F,$15,$28
        .byte   $0F,$27,$18,$0A,$0F,$0F,$0B,$0F,$0F,$20,$10,$00,$0F,$0B,$0F,$0B ; anim frame 0
        .byte   $0F,$27,$18,$0A,$0F,$0F,$0B,$0F,$0F,$20,$10,$00,$0F,$0F,$0B,$0B ; anim frame 1
        .byte   $0F,$27,$18,$0A,$0F,$0F,$0B,$0F,$0F,$20,$10,$00,$0F,$0B,$0B,$0F ; anim frame 2
        .byte   $0F,$27,$18,$0A,$0F,$0F,$0B,$0F,$0F,$20,$10,$00,$0F,$0B,$0B,$0F ; anim frame 3
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; ─── padding, MMC1 reset stub ($BFE0: sei / inc $BFE1) and vectors ($BFFA) ───
        .byte   $78,$EE,$E1,$BF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$E0,$BF,$E0,$BF
