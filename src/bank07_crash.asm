.segment "BANK07"

; =============================================================================
; Bank $07 — Crash Man (stage $07) Stage Data
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
        .byte   $01,$01,$01,$01 ; metatile $01
        .byte   $01,$01,$01,$01 ; metatile $02
        .byte   $01,$01,$01,$01 ; metatile $03
        .byte   $01,$01,$01,$01 ; metatile $04
        .byte   $3A,$3A,$39,$39 ; metatile $05
        .byte   $38,$38,$39,$39 ; metatile $06
        .byte   $01,$58,$01,$7F ; metatile $07
        .byte   $06,$00,$07,$00 ; metatile $08
        .byte   $5E,$01,$5E,$01 ; metatile $09
        .byte   $01,$5E,$01,$5E ; metatile $0A
        .byte   $5F,$01,$01,$01 ; metatile $0B
        .byte   $01,$01,$01,$45 ; metatile $0C
        .byte   $45,$01,$5E,$01 ; metatile $0D
        .byte   $5E,$01,$5F,$01 ; metatile $0E
        .byte   $01,$45,$01,$5E ; metatile $0F
        .byte   $08,$00,$08,$00 ; metatile $10
        .byte   $78,$66,$61,$7B ; metatile $11
        .byte   $61,$67,$62,$78 ; metatile $12
        .byte   $6A,$63,$67,$79 ; metatile $13
        .byte   $66,$79,$78,$66 ; metatile $14
        .byte   $5A,$64,$5B,$65 ; metatile $15
        .byte   $02,$03,$02,$03 ; metatile $16
        .byte   $78,$6B,$1D,$1D ; metatile $17
        .byte   $63,$66,$59,$7B ; metatile $18
        .byte   $62,$78,$7A,$79 ; metatile $19
        .byte   $59,$67,$62,$78 ; metatile $1A
        .byte   $7C,$62,$63,$66 ; metatile $1B
        .byte   $61,$7B,$62,$6B ; metatile $1C
        .byte   $66,$6A,$78,$7B ; metatile $1D
        .byte   $79,$7B,$67,$7B ; metatile $1E
        .byte   $66,$6B,$78,$6A ; metatile $1F
        .byte   $78,$66,$61,$6B ; metatile $20
        .byte   $79,$67,$63,$78 ; metatile $21
        .byte   $6A,$7A,$6B,$63 ; metatile $22
        .byte   $66,$61,$78,$61 ; metatile $23
        .byte   $61,$6A,$61,$7B ; metatile $24
        .byte   $62,$79,$7A,$78 ; metatile $25
        .byte   $61,$61,$6A,$62 ; metatile $26
        .byte   $6A,$62,$78,$66 ; metatile $27
        .byte   $5E,$6A,$5E,$78 ; metatile $28
        .byte   $6A,$5E,$78,$5E ; metatile $29
        .byte   $58,$01,$7C,$01 ; metatile $2A
        .byte   $7C,$01,$7C,$01 ; metatile $2B
        .byte   $7F,$01,$01,$01 ; metatile $2C
        .byte   $67,$6A,$7C,$63 ; metatile $2D
        .byte   $01,$01,$61,$6A ; metatile $2E
        .byte   $7C,$7C,$6B,$7C ; metatile $2F
        .byte   $02,$04,$02,$05 ; metatile $30
        .byte   $01,$5E,$6A,$5E ; metatile $31
        .byte   $01,$01,$01,$58 ; metatile $32
        .byte   $01,$7F,$01,$01 ; metatile $33
        .byte   $6A,$01,$6B,$01 ; metatile $34
        .byte   $3A,$00,$39,$00 ; metatile $35
        .byte   $7B,$01,$6B,$01 ; metatile $36
        .byte   $6A,$01,$7C,$01 ; metatile $37
        .byte   $01,$62,$01,$7A ; metatile $38
        .byte   $01,$7A,$01,$63 ; metatile $39
        .byte   $01,$62,$01,$63 ; metatile $3A
        .byte   $01,$01,$61,$79 ; metatile $3B
        .byte   $6A,$01,$78,$61 ; metatile $3C
        .byte   $63,$78,$1D,$1D ; metatile $3D
        .byte   $61,$61,$01,$01 ; metatile $3E
        .byte   $1D,$1D,$08,$08 ; metatile $3F
        .byte   $17,$09,$3E,$0A ; metatile $40
        .byte   $83,$83,$7F,$01 ; metatile $41
        .byte   $83,$01,$58,$01 ; metatile $42
        .byte   $7C,$01,$83,$83 ; metatile $43
        .byte   $17,$0B,$16,$00 ; metatile $44
        .byte   $15,$15,$15,$16 ; metatile $45
        .byte   $01,$83,$01,$7C ; metatile $46
        .byte   $00,$00,$00,$00 ; metatile $47
        .byte   $16,$3E,$17,$09 ; metatile $48
        .byte   $01,$58,$01,$83 ; metatile $49
        .byte   $3E,$0A,$17,$0B ; metatile $4A
        .byte   $83,$83,$79,$61 ; metatile $4B
        .byte   $83,$01,$6A,$62 ; metatile $4C
        .byte   $83,$83,$62,$79 ; metatile $4D
        .byte   $0A,$3E,$17,$00 ; metatile $4E
        .byte   $83,$83,$6B,$01 ; metatile $4F
        .byte   $01,$01,$83,$83 ; metatile $50
        .byte   $01,$01,$83,$01 ; metatile $51
        .byte   $83,$83,$01,$01 ; metatile $52
        .byte   $83,$01,$01,$01 ; metatile $53
        .byte   $6A,$01,$83,$83 ; metatile $54
        .byte   $16,$15,$09,$16 ; metatile $55
        .byte   $01,$01,$34,$33 ; metatile $56
        .byte   $63,$78,$83,$83 ; metatile $57
        .byte   $62,$61,$83,$83 ; metatile $58
        .byte   $59,$69,$83,$83 ; metatile $59
        .byte   $83,$83,$79,$79 ; metatile $5A
        .byte   $83,$83,$63,$7B ; metatile $5B
        .byte   $83,$83,$7C,$01 ; metatile $5C
        .byte   $62,$61,$7C,$01 ; metatile $5D
        .byte   $01,$83,$79,$61 ; metatile $5E
        .byte   $01,$01,$01,$30 ; metatile $5F
        .byte   $30,$34,$31,$01 ; metatile $60
        .byte   $31,$01,$31,$01 ; metatile $61
        .byte   $31,$01,$32,$34 ; metatile $62
        .byte   $35,$01,$01,$01 ; metatile $63
        .byte   $35,$01,$30,$34 ; metatile $64
        .byte   $01,$31,$01,$31 ; metatile $65
        .byte   $30,$35,$31,$30 ; metatile $66
        .byte   $31,$32,$31,$01 ; metatile $67
        .byte   $34,$34,$01,$01 ; metatile $68
        .byte   $31,$01,$2D,$2C ; metatile $69
        .byte   $01,$01,$34,$34 ; metatile $6A
        .byte   $31,$30,$31,$31 ; metatile $6B
        .byte   $31,$32,$32,$34 ; metatile $6C
        .byte   $34,$35,$34,$34 ; metatile $6D
        .byte   $33,$31,$31,$31 ; metatile $6E
        .byte   $31,$31,$31,$31 ; metatile $6F
        .byte   $33,$01,$31,$01 ; metatile $70
        .byte   $2D,$2C,$31,$01 ; metatile $71
        .byte   $31,$01,$35,$01 ; metatile $72
        .byte   $01,$30,$33,$31 ; metatile $73
        .byte   $34,$34,$34,$34 ; metatile $74
        .byte   $31,$31,$35,$31 ; metatile $75
        .byte   $35,$31,$01,$31 ; metatile $76
        .byte   $34,$35,$33,$30 ; metatile $77
        .byte   $30,$34,$31,$30 ; metatile $78
        .byte   $32,$35,$34,$34 ; metatile $79
        .byte   $33,$30,$32,$35 ; metatile $7A
        .byte   $1D,$01,$49,$49 ; metatile $7B
        .byte   $47,$4C,$47,$4D ; metatile $7C
        .byte   $4E,$4B,$4F,$4B ; metatile $7D
        .byte   $1D,$01,$49,$4A ; metatile $7E
        .byte   $0A,$16,$0B,$3E ; metatile $7F
        .byte   $09,$16,$0A,$3E ; metatile $80
        .byte   $17,$00,$17,$0E ; metatile $81
        .byte   $0C,$0D,$0E,$0F ; metatile $82
        .byte   $01,$01,$59,$69 ; metatile $83
        .byte   $59,$69,$01,$01 ; metatile $84
        .byte   $0C,$0D,$3F,$0C ; metatile $85
        .byte   $09,$16,$0A,$16 ; metatile $86
        .byte   $01,$62,$01,$7A ; metatile $87
        .byte   $83,$83,$61,$6B ; metatile $88
        .byte   $83,$83,$63,$78 ; metatile $89
        .byte   $3F,$0C,$0E,$0F ; metatile $8A
        .byte   $3F,$0C,$0F,$0F ; metatile $8B
        .byte   $01,$83,$01,$62 ; metatile $8C
        .byte   $1D,$63,$1D,$01 ; metatile $8D
        .byte   $01,$7A,$01,$63 ; metatile $8E
        .byte   $83,$7C,$01,$7C ; metatile $8F
        .byte   $01,$01,$01,$58 ; metatile $90
        .byte   $0D,$10,$0F,$11 ; metatile $91
        .byte   $3E,$15,$15,$00 ; metatile $92
        .byte   $00,$15,$0C,$16 ; metatile $93
        .byte   $7A,$61,$63,$61 ; metatile $94
        .byte   $62,$6B,$7C,$01 ; metatile $95
        .byte   $01,$7C,$61,$6B ; metatile $96
        .byte   $01,$01,$01,$62 ; metatile $97
        .byte   $61,$6B,$01,$01 ; metatile $98
        .byte   $01,$62,$01,$7C ; metatile $99
        .byte   $01,$7C,$01,$63 ; metatile $9A
        .byte   $01,$01,$61,$61 ; metatile $9B
        .byte   $7C,$01,$7B,$01 ; metatile $9C
        .byte   $78,$6A,$01,$7C ; metatile $9D
        .byte   $79,$6B,$7C,$01 ; metatile $9E
        .byte   $6B,$01,$01,$01 ; metatile $9F
        .byte   $0D,$17,$0F,$3E ; metatile $A0
        .byte   $7A,$79,$7C,$7C ; metatile $A1
        .byte   $7C,$7C,$7A,$7B ; metatile $A2
        .byte   $78,$61,$1D,$1D ; metatile $A3
        .byte   $7C,$7C,$7C,$7C ; metatile $A4
        .byte   $01,$01,$61,$6A ; metatile $A5
        .byte   $01,$1D,$62,$79 ; metatile $A6
        .byte   $1D,$1D,$79,$6A ; metatile $A7
        .byte   $01,$3E,$01,$01 ; metatile $A8
        .byte   $01,$01,$01,$28 ; metatile $A9
        .byte   $01,$3E,$01,$28 ; metatile $AA
        .byte   $28,$01,$3E,$01 ; metatile $AB
        .byte   $20,$01,$01,$20 ; metatile $AC
        .byte   $20,$28,$01,$01 ; metatile $AD
        .byte   $3E,$01,$28,$01 ; metatile $AE
        .byte   $01,$28,$28,$01 ; metatile $AF
        .byte   $01,$01,$3E,$01 ; metatile $B0
        .byte   $28,$01,$01,$01 ; metatile $B1
        .byte   $20,$01,$3D,$01 ; metatile $B2
        .byte   $01,$3D,$01,$20 ; metatile $B3
        .byte   $17,$10,$3E,$11 ; metatile $B4
        .byte   $12,$13,$13,$01 ; metatile $B5
        .byte   $10,$12,$11,$14 ; metatile $B6
        .byte   $00,$15,$15,$16 ; metatile $B7
        .byte   $10,$13,$11,$14 ; metatile $B8
        .byte   $12,$12,$14,$13 ; metatile $B9
        .byte   $01,$00,$01,$00 ; metatile $BA
        .byte   $12,$00,$14,$00 ; metatile $BB
        .byte   $3F,$00,$3F,$00 ; metatile $BC
        .byte   $01,$00,$14,$00 ; metatile $BD
        .byte   $12,$00,$01,$00 ; metatile $BE
        .byte   $38,$00,$39,$00 ; metatile $BF
        .byte   $63,$66,$59,$7B ; metatile $C0
        .byte   $62,$78,$67,$79 ; metatile $C1
        .byte   $6A,$01,$7C,$01 ; metatile $C2
        .byte   $7B,$01,$6B,$01 ; metatile $C3
        .byte   $63,$78,$01,$01 ; metatile $C4
        .byte   $78,$6B,$01,$01 ; metatile $C5
        .byte   $83,$83,$01,$01 ; metatile $C6
        .byte   $83,$83,$63,$79 ; metatile $C7
        .byte   $83,$83,$67,$78 ; metatile $C8
        .byte   $83,$83,$1F,$01 ; metatile $C9
        .byte   $83,$83,$6B,$01 ; metatile $CA
        .byte   $61,$61,$1F,$01 ; metatile $CB
        .byte   $6B,$01,$01,$01 ; metatile $CC
        .byte   $62,$79,$7A,$78 ; metatile $CD
        .byte   $1F,$01,$1F,$01 ; metatile $CE
        .byte   $83,$31,$01,$31 ; metatile $CF
        .byte   $78,$66,$61,$6B ; metatile $D0
        .byte   $79,$67,$63,$78 ; metatile $D1
        .byte   $6A,$7A,$6B,$63 ; metatile $D2
        .byte   $66,$61,$78,$61 ; metatile $D3
        .byte   $61,$6A,$61,$7B ; metatile $D4
        .byte   $62,$79,$7A,$78 ; metatile $D5
        .byte   $61,$61,$6A,$62 ; metatile $D6
        .byte   $6A,$62,$78,$66 ; metatile $D7
        .byte   $63,$66,$59,$7B ; metatile $D8
        .byte   $62,$78,$67,$79 ; metatile $D9
        .byte   $61,$67,$62,$78 ; metatile $DA
        .byte   $66,$6A,$78,$7B ; metatile $DB
        .byte   $1D,$7C,$1D,$7C ; metatile $DC
        .byte   $83,$83,$61,$79 ; metatile $DD
        .byte   $7C,$1D,$7C,$01 ; metatile $DE
        .byte   $79,$78,$63,$69 ; metatile $DF
        .byte   $83,$83,$01,$01 ; metatile $E0
        .byte   $78,$6B,$01,$01 ; metatile $E1
        .byte   $63,$78,$01,$01 ; metatile $E2
        .byte   $01,$83,$79,$61 ; metatile $E3
        .byte   $01,$01,$83,$83 ; metatile $E4
        .byte   $83,$01,$01,$01 ; metatile $E5
        .byte   $83,$83,$58,$01 ; metatile $E6
        .byte   $63,$66,$61,$7B ; metatile $E7
        .byte   $1D,$1C,$1D,$00 ; metatile $E8
        .byte   $1C,$00,$1D,$00 ; metatile $E9
        .byte   $1D,$00,$1D,$1C ; metatile $EA
        .byte   $1C,$00,$00,$1C ; metatile $EB
        .byte   $1C,$00,$1D,$1D ; metatile $EC
        .byte   $1D,$1C,$00,$1D ; metatile $ED
        .byte   $1D,$1D,$61,$61 ; metatile $EE
        .byte   $1D,$1D,$83,$83 ; metatile $EF
        .byte   $83,$83,$1D,$1D ; metatile $F0
        .byte   $78,$6B,$1D,$1D ; metatile $F1
        .byte   $1D,$1D,$1C,$1D ; metatile $F2
        .byte   $6A,$01,$7B,$01 ; metatile $F3
        .byte   $7B,$01,$7C,$01 ; metatile $F4
        .byte   $00,$1D,$1C,$00 ; metatile $F5
        .byte   $00,$1D,$1D,$00 ; metatile $F6
        .byte   $1D,$1D,$00,$1C ; metatile $F7
        .byte   $1C,$00,$00,$1D ; metatile $F8
        .byte   $00,$1D,$00,$00 ; metatile $F9
        .byte   $1D,$00,$1C,$1D ; metatile $FA
        .byte   $1D,$00,$00,$1C ; metatile $FB
        .byte   $1D,$00,$00,$00 ; metatile $FC
        .byte   $1D,$83,$00,$58 ; metatile $FD
        .byte   $00,$00,$00,$00 ; metatile $FE
        .byte   $00,$00,$00,$00 ; metatile $FF

; =============================================================================
; metatile_attrs — palette attribute byte per metatile ($8400)
; =============================================================================
metatile_attrs:
        .byte   $00,$00,$55,$AA,$FF,$FF,$FF,$05 ; $00-$07
        .byte   $55,$05,$50,$01,$40,$05,$05,$50 ; $08-$0F
        .byte   $55,$00,$00,$00,$00,$55,$55,$BF ; $10-$17
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; $18-$1F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; $20-$27
        .byte   $05,$50,$00,$00,$00,$00,$00,$00 ; $28-$2F
        .byte   $55,$50,$00,$00,$00,$0F,$00,$00 ; $30-$37
        .byte   $00,$00,$00,$00,$FF,$FB,$FF,$BA ; $38-$3F
        .byte   $20,$11,$01,$44,$00,$00,$10,$00 ; $40-$47
        .byte   $80,$40,$00,$11,$01,$11,$00,$11 ; $48-$4F
        .byte   $44,$04,$11,$01,$44,$08,$44,$44 ; $50-$57
        .byte   $44,$44,$DD,$DD,$11,$FF,$DF,$40 ; $58-$5F
        .byte   $15,$05,$45,$01,$45,$50,$55,$15 ; $60-$67
        .byte   $11,$45,$44,$55,$55,$55,$55,$55 ; $68-$6F
        .byte   $05,$15,$05,$54,$55,$55,$51,$55 ; $70-$77
        .byte   $55,$55,$55,$BA,$AA,$AA,$BA,$00 ; $78-$7F
        .byte   $02,$80,$22,$00,$00,$80,$02,$FF ; $80-$87
        .byte   $DD,$DD,$20,$A8,$DF,$FB,$FF,$FD ; $88-$8F
        .byte   $FF,$02,$00,$00,$FF,$FF,$FF,$FF ; $90-$97
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $98-$9F
        .byte   $02,$FF,$FF,$FF,$FF,$FF,$FF,$FE ; $A0-$A7
        .byte   $55,$55,$55,$05,$51,$11,$05,$15 ; $A8-$AF
        .byte   $04,$01,$55,$50,$A0,$88,$00,$00 ; $B0-$B7
        .byte   $20,$2A,$08,$00,$00,$02,$02,$0F ; $B8-$BF
        .byte   $AA,$AA,$AA,$AA,$AA,$AA,$99,$99 ; $C0-$C7
        .byte   $99,$99,$99,$AA,$AA,$AA,$AA,$51 ; $C8-$CF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $D0-$D7
        .byte   $FF,$FF,$FF,$FF,$FF,$DD,$EF,$FF ; $D8-$DF
        .byte   $DD,$FF,$FF,$DF,$77,$FD,$DD,$FF ; $E0-$E7
        .byte   $1E,$0D,$4E,$41,$CD,$93,$FE,$76 ; $E8-$EF
        .byte   $DD,$BF,$BA,$FF,$FF,$08,$3C,$A3 ; $F0-$F7
        .byte   $40,$20,$CF,$83,$02,$DF,$00,$55 ; $F8-$FF

; =============================================================================
; screen_layouts — 64-byte rooms, column-major 8×8 metatile IDs ($8500)
; ptr = $8500 + screen × $40. Rooms are consumed in virtual-screen order;
; checkpoint tables give each stage's range:
;   Crash Man rooms $00-$12+
; Each row below = one 8-metatile column (left to right).
; =============================================================================
screen_layouts:
; ─── screen $00 ($8500) — Crash Man rooms ───
        .byte   $20,$21,$15,$28,$15,$21,$13,$14
        .byte   $01,$01,$01,$0E,$01,$01,$18,$13
        .byte   $52,$52,$2A,$01,$01,$01,$19,$14
        .byte   $01,$01,$43,$50,$51,$01,$18,$13
        .byte   $0C,$01,$2C,$01,$2A,$01,$19,$14
        .byte   $0A,$01,$01,$01,$43,$50,$18,$12
        .byte   $0A,$01,$0D,$01,$2B,$01,$19,$14
        .byte   $29,$27,$28,$25,$14,$27,$11,$12
; ─── screen $01 ($8540) — Crash Man rooms ───
        .byte   $20,$21,$22,$28,$15,$21,$1A,$23
        .byte   $01,$01,$01,$0B,$01,$01,$2B,$01
        .byte   $50,$50,$50,$01,$01,$01,$5C,$52
        .byte   $2D,$2E,$01,$32,$01,$01,$2C,$01
        .byte   $11,$1C,$01,$46,$52,$53,$01,$01
        .byte   $13,$15,$0C,$33,$01,$01,$01,$01
        .byte   $11,$2D,$31,$2E,$01,$0F,$01,$01
        .byte   $13,$14,$29,$12,$26,$29,$24,$25
; ─── screen $02 ($8580) — Crash Man rooms ───
        .byte   $11,$12,$13,$23,$20,$15,$22,$23
        .byte   $13,$14,$11,$34,$01,$01,$01,$01
        .byte   $11,$12,$13,$37,$01,$49,$50,$50
        .byte   $13,$14,$20,$36,$01,$38,$24,$25
        .byte   $11,$15,$36,$01,$01,$39,$13,$14
        .byte   $13,$14,$37,$01,$01,$38,$11,$12
        .byte   $11,$12,$36,$01,$01,$1A,$13,$14
        .byte   $13,$14,$37,$01,$01,$1B,$15,$12
; ─── screen $03 ($85C0) — Crash Man rooms ───
        .byte   $11,$12,$36,$01,$01,$1A,$13,$14
        .byte   $13,$37,$01,$01,$01,$1B,$11,$12
        .byte   $11,$36,$01,$01,$3A,$12,$13,$14
        .byte   $13,$34,$01,$01,$38,$15,$11,$12
        .byte   $11,$37,$01,$01,$19,$12,$13,$14
        .byte   $22,$36,$01,$01,$19,$14,$11,$12
        .byte   $4B,$4B,$4C,$3B,$2F,$12,$15,$14
        .byte   $13,$14,$11,$12,$13,$14,$11,$12
; ─── screen $04 ($8600) — Crash Man rooms ───
        .byte   $01,$01,$01,$01,$01,$01,$19,$14
        .byte   $01,$01,$60,$68,$68,$70,$18,$12
        .byte   $01,$01,$61,$01,$01,$71,$19,$14
        .byte   $01,$01,$61,$01,$01,$61,$18,$12
        .byte   $01,$01,$61,$01,$01,$69,$19,$14
        .byte   $01,$01,$61,$01,$01,$61,$18,$12
        .byte   $54,$51,$62,$6A,$6A,$72,$4D,$4B
        .byte   $37,$01,$01,$01,$01,$01,$18,$12
; ─── screen $05 ($8640) — Crash Man rooms ───
        .byte   $34,$01,$01,$01,$01,$01,$1A,$34
        .byte   $4F,$53,$60,$70,$01,$01,$1B,$37
        .byte   $01,$01,$61,$61,$01,$01,$1A,$36
        .byte   $01,$60,$63,$61,$60,$70,$1B,$34
        .byte   $01,$61,$60,$64,$72,$71,$1A,$37
        .byte   $01,$61,$62,$72,$01,$69,$1B,$37
        .byte   $01,$62,$6A,$6A,$6A,$72,$57,$57
        .byte   $01,$01,$01,$01,$01,$01,$1B,$24
; ─── screen $06 ($8680) — Crash Man rooms ───
        .byte   $34,$5F,$6A,$56,$01,$01,$18,$21
        .byte   $4F,$CF,$78,$77,$73,$70,$4D,$4B
        .byte   $01,$65,$6F,$6F,$6F,$71,$18,$37
        .byte   $01,$66,$79,$79,$75,$61,$19,$36
        .byte   $01,$67,$7A,$7A,$6E,$61,$18,$37
        .byte   $01,$6B,$7A,$7A,$76,$69,$19,$36
        .byte   $01,$6C,$74,$74,$6D,$72,$18,$37
        .byte   $01,$01,$01,$01,$01,$01,$19,$36
; ─── screen $07 ($86C0) — Crash Man rooms ───
        .byte   $A8,$B0,$AC,$02,$AE,$01,$18,$21
        .byte   $A9,$B1,$01,$AD,$01,$01,$4D,$4B
        .byte   $A8,$B0,$01,$01,$01,$01,$19,$37
        .byte   $02,$AA,$01,$01,$01,$01,$18,$36
        .byte   $02,$AB,$01,$01,$01,$01,$19,$37
        .byte   $A9,$B1,$01,$01,$01,$01,$18,$36
        .byte   $AA,$01,$01,$01,$01,$01,$19,$37
        .byte   $AB,$01,$01,$01,$01,$01,$18,$36
; ─── screen $08 ($8700) — Crash Man rooms ───
        .byte   $A8,$B0,$01,$01,$01,$01,$19,$36
        .byte   $02,$AA,$01,$01,$01,$01,$18,$37
        .byte   $02,$AB,$01,$01,$01,$01,$19,$36
        .byte   $A9,$B1,$84,$01,$01,$01,$18,$37
        .byte   $B1,$01,$01,$01,$01,$01,$19,$36
        .byte   $50,$50,$50,$50,$50,$50,$18,$37
        .byte   $24,$25,$26,$15,$24,$25,$13,$27
        .byte   $13,$14,$11,$12,$13,$14,$11,$12
; ─── screen $09 ($8740) — Crash Man rooms ───
        .byte   $01,$01,$32,$B2,$02,$02,$02,$02
        .byte   $01,$01,$33,$AC,$02,$07,$02,$02
        .byte   $01,$32,$01,$01,$AC,$02,$02,$02
        .byte   $01,$33,$01,$01,$32,$B2,$02,$02
        .byte   $01,$01,$01,$01,$33,$AC,$AF,$AC
        .byte   $50,$50,$50,$50,$50,$50,$58,$54
        .byte   $24,$25,$26,$27,$24,$15,$26,$27
        .byte   $13,$14,$15,$12,$13,$14,$11,$12
; ─── screen $0A ($8780) — Crash Man rooms ───
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $52,$52,$01,$84,$01,$01,$01,$01
        .byte   $01,$01,$01,$83,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$59,$50,$50,$58,$54
        .byte   $24,$15,$26,$27,$24,$25,$26,$27
        .byte   $13,$14,$11,$12,$13,$14,$11,$12
; ─── screen $0B ($87C0) — Crash Man rooms ───
        .byte   $03,$03,$03,$03,$03,$03,$C1,$C3
        .byte   $03,$03,$03,$03,$03,$03,$C0,$C2
        .byte   $03,$03,$03,$03,$03,$03,$C7,$CA
        .byte   $C6,$C6,$C6,$C6,$C6,$C6,$C0,$C2
        .byte   $C6,$C6,$C6,$C6,$C6,$C6,$C1,$C3
        .byte   $03,$03,$03,$03,$03,$03,$C0,$C2
        .byte   $03,$03,$03,$03,$03,$03,$C1,$CD
        .byte   $03,$03,$03,$03,$03,$03,$C0,$C1
; ─── screen $0C ($8800) — Crash Man rooms ───
        .byte   $04,$04,$04,$04,$04,$04,$04,$04
        .byte   $E0,$E0,$E0,$E0,$D5,$F3,$04,$04
        .byte   $E0,$E0,$E0,$E0,$D8,$F4,$04,$04
        .byte   $5A,$5B,$89,$5A,$88,$E6,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$5B,$E6,$E0,$E0
        .byte   $89,$5B,$89,$88,$D9,$F3,$04,$04
        .byte   $E2,$98,$E1,$E2,$E2,$9F,$04,$04
        .byte   $04,$04,$04,$04,$04,$04,$04,$04
; ─── screen $0D ($8840) — Crash Man rooms ───
        .byte   $F9,$FA,$FB,$04,$04,$04,$04,$04
        .byte   $FB,$FC,$F9,$89,$E0,$E0,$E0,$E0
        .byte   $E0,$F0,$E0,$5B,$E0,$E0,$E0,$E0
        .byte   $D6,$D7,$D1,$DA,$A5,$5A,$5B,$88
        .byte   $5A,$5A,$5B,$88,$E0,$E0,$E0,$E0
        .byte   $5A,$5B,$89,$88,$5B,$88,$5A,$5B
        .byte   $E1,$E2,$98,$E2,$E1,$E2,$98,$E1
        .byte   $FB,$FC,$F9,$04,$04,$04,$04,$04
; ─── screen $0E ($8880) — Crash Man rooms ───
        .byte   $F9,$FA,$FB,$FC,$F9,$FA,$FB,$FB
        .byte   $FB,$FC,$F9,$FA,$FB,$FC,$F9,$FA
        .byte   $F0,$F0,$E0,$F0,$E0,$F0,$F0,$E0
        .byte   $FB,$FC,$F9,$87,$D6,$D7,$D1,$D2
        .byte   $D6,$D7,$D4,$DA,$3C,$E3,$5A,$88
        .byte   $5B,$DD,$88,$89,$5A,$5A,$5B,$89
        .byte   $F1,$E2,$E2,$F1,$F1,$E2,$F1,$98
        .byte   $FB,$FC,$F9,$FA,$FB,$FC,$F9,$FA
; ─── screen $0F ($88C0) — Crash Man rooms ───
        .byte   $F5,$F6,$F7,$F8,$F9,$FA,$FB,$FC
        .byte   $88,$F0,$E5,$F6,$FB,$FC,$F9,$FA
        .byte   $D0,$F6,$F7,$F8,$90,$FA,$FD,$E0
        .byte   $88,$F0,$E0,$F0,$8F,$FC,$DC,$04
        .byte   $F5,$F6,$F7,$F8,$8E,$D7,$D9,$D5
        .byte   $E8,$E8,$F5,$F6,$8C,$5A,$89,$5A
        .byte   $F5,$E9,$E8,$F8,$8D,$F1,$E2,$F1
        .byte   $F7,$E8,$F5,$F6,$FB,$FC,$F9,$FA
; ─── screen $10 ($8900) — Crash Man rooms ───
        .byte   $F5,$F6,$F7,$F8,$F5,$F6,$F7,$F8
        .byte   $F7,$F8,$89,$88,$5A,$DD,$5B,$5A
        .byte   $F5,$F6,$94,$D3,$D1,$D2,$D3,$D4
        .byte   $F7,$F8,$F5,$F6,$F7,$8C,$DD,$DD
        .byte   $F5,$F6,$F7,$F8,$F5,$DC,$DC,$F8
        .byte   $F7,$F8,$F5,$F6,$97,$96,$DC,$F6
        .byte   $F5,$EA,$F7,$F8,$DC,$F6,$DC,$F8
        .byte   $F7,$F8,$F5,$99,$98,$F8,$95,$F6
; ─── screen $11 ($8940) — Crash Man rooms ───
        .byte   $F5,$F6,$F7,$9A,$EE,$EE,$9C,$F8
        .byte   $F7,$F8,$F5,$F6,$F7,$F8,$DE,$F6
        .byte   $EA,$EB,$F7,$F8,$F5,$F6,$DE,$F8
        .byte   $F7,$EC,$EB,$F6,$F7,$5D,$9D,$F6
        .byte   $F5,$F6,$ED,$F8,$F5,$DE,$DC,$F8
        .byte   $F7,$F8,$F5,$F6,$5D,$A3,$9E,$F6
        .byte   $7B,$7E,$F7,$F8,$A1,$3E,$9F,$F8
        .byte   $7C,$7D,$3F,$3F,$A2,$F8,$F5,$F6
; ─── screen $12 ($8980) — Crash Man rooms ───
        .byte   $F5,$A4,$F7,$F8,$A4,$F6,$F7,$F8
        .byte   $F7,$A2,$F5,$F6,$A2,$F8,$F5,$F6
        .byte   $F5,$A4,$F7,$F8,$A4,$F6,$F7,$F8
        .byte   $F7,$A2,$F5,$F6,$A2,$F8,$F5,$F6
        .byte   $F5,$A4,$F7,$F8,$A4,$F6,$F7,$F8
        .byte   $F7,$A2,$F5,$F6,$A2,$F8,$F5,$F6
        .byte   $F5,$A4,$F7,$F8,$A4,$F6,$F7,$F8
        .byte   $F7,$A2,$3F,$3F,$A2,$F8,$F5,$F6
; ─── screen $13 ($89C0) — Crash Man boss corridor ───
        .byte   $3E,$17,$F7,$F8,$3D,$3E,$DF,$D7
        .byte   $F7,$F8,$F5,$F6,$F7,$F8,$D8,$DA
        .byte   $F5,$F6,$F7,$F8,$F5,$F6,$D9,$DB
        .byte   $F7,$F8,$F5,$F6,$F7,$F8,$D8,$DA
        .byte   $F5,$F6,$F7,$F8,$F5,$F6,$D9,$DB
        .byte   $F7,$F8,$F5,$F6,$F7,$F8,$D8,$DA
        .byte   $F5,$F6,$F7,$F8,$F5,$F6,$D9,$DB
        .byte   $A6,$A6,$A6,$A5,$A7,$A7,$E7,$D1
; ─── screen $14 ($8A00) ───
        .byte   $40,$4E,$82,$91,$B5,$BA,$FF,$FF
        .byte   $44,$55,$85,$92,$B6,$BB,$FF,$FF
        .byte   $45,$7F,$86,$93,$B7,$BC,$FF,$FF
        .byte   $48,$80,$8A,$A0,$B8,$BD,$FF,$FF
        .byte   $4A,$81,$8B,$B4,$B9,$BE,$FF,$FF
        .byte   $06,$06,$06,$06,$06,$BF,$FF,$FF
        .byte   $05,$05,$05,$05,$05,$35,$FF,$FF
        .byte   $05,$05,$05,$05,$05,$35,$FF,$FF
; ─── screen $15 ($8A40) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$16,$08
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$16,$08
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$30,$10
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$16,$08
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$16,$08
        .byte   $06,$06,$06,$06,$06,$06,$06,$06
        .byte   $05,$05,$05,$05,$05,$05,$05,$05
        .byte   $05,$05,$05,$05,$05,$05,$05,$05
; ─── screen $16 ($8A80) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $17 ($8AC0) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $18 ($8B00) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $19 ($8B40) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $1A ($8B80) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $1B ($8BC0) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $1C ($8C00) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $1D ($8C40) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $1E ($8C80) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $1F ($8CC0) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $20 ($8D00) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $21 ($8D40) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $22 ($8D80) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $23 ($8DC0) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $24 ($8E00) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $25 ($8E40) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $26 ($8E80) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $27 ($8EC0) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $28 ($8F00) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $29 ($8F40) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $2A ($8F80) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── screen $2B ($8FC0) ───
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; =============================================================================
; CHR pattern data $9000-$B3FF (36 pages)
; Referenced by: Crash Man CHR list, bank00 overlay sets, bank02 overlay sets, bank03 overlay sets, bank04 overlay sets, bank05 overlay sets, group 4 (ending), group 6 (ending/weapon get)
; =============================================================================
        .byte   $00,$00,$00,$00,$00,$01,$02,$02,$00,$00,$00,$00,$00,$00,$01,$01
        .byte   $00,$00,$00,$00,$20,$20,$40,$40,$00,$00,$00,$00,$40,$40,$80,$80
        .byte   $02,$02,$01,$01,$01,$01,$07,$0F,$01,$01,$00,$00,$00,$00,$00,$06
        .byte   $3C,$7C,$79,$33,$05,$89,$59,$5B,$01,$BF,$FE,$FD,$F9,$71,$21,$03
        .byte   $80,$80,$00,$80,$70,$7C,$7E,$FE,$00,$00,$00,$00,$80,$A0,$A0,$60
        .byte   $3F,$7F,$5F,$9B,$99,$9C,$FC,$7C,$06,$03,$23,$71,$70,$78,$78,$38
        .byte   $83,$83,$C6,$7D,$BB,$C7,$7F,$FF,$82,$02,$81,$C3,$FF,$7E,$38,$00
        .byte   $FF,$FF,$FF,$DF,$BF,$BE,$FE,$FC,$40,$C6,$8E,$86,$1E,$0C,$1C,$00
        .byte   $39,$03,$04,$08,$1F,$7F,$FF,$FF,$00,$00,$03,$07,$07,$1F,$7F,$00
        .byte   $FF,$E1,$C0,$C0,$C1,$81,$83,$83,$00,$00,$00,$80,$80,$00,$01,$00
        .byte   $E8,$C8,$E8,$F8,$F8,$FE,$FF,$FF,$10,$30,$70,$70,$E0,$F8,$FE,$00
        .byte   $00,$00,$00,$00,$00,$00,$40,$40,$00,$00,$00,$00,$00,$00,$80,$80
        .byte   $04,$04,$04,$04,$02,$02,$02,$03,$02,$02,$02,$03,$01,$01,$01,$00
        .byte   $00,$00,$79,$F9,$F2,$67,$0A,$12,$01,$01,$02,$7E,$FC,$FA,$F3,$E3
        .byte   $80,$80,$00,$0C,$1E,$3F,$FF,$FE,$00,$00,$00,$00,$0C,$1E,$0C,$40
        .byte   $06,$0E,$1F,$1F,$1F,$0F,$0F,$07,$00,$04,$0D,$02,$01,$00,$00,$00
        .byte   $B2,$B7,$07,$07,$8D,$FB,$E7,$FF,$43,$06,$04,$05,$03,$86,$7C,$00
        .byte   $F0,$E0,$E0,$C0,$80,$00,$00,$E0,$40,$C0,$80,$80,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $07,$07,$0B,$1F,$3F,$FF,$FF,$FE,$01,$01,$04,$0E,$0F,$3C,$FE,$00
        .byte   $0F,$DF,$FF,$FC,$F8,$01,$01,$01,$F8,$FC,$FC,$38,$00,$00,$00,$00
        .byte   $F8,$E4,$F4,$FC,$FC,$FE,$FF,$FF,$00,$18,$38,$38,$70,$7C,$FE,$00
        .byte   $00,$07,$0C,$1F,$1F,$1F,$0C,$00,$00,$00,$07,$0F,$0F,$0C,$00,$00
        .byte   $23,$A7,$57,$F3,$F0,$F8,$F5,$75,$10,$1B,$8F,$8F,$0F,$27,$22,$20
        .byte   $C8,$C8,$90,$38,$54,$94,$96,$BF,$10,$F0,$E0,$D0,$98,$18,$18,$36
        .byte   $78,$28,$14,$17,$1B,$0C,$07,$0F,$28,$10,$08,$0C,$07,$03,$00,$00
        .byte   $3F,$3F,$77,$EF,$9F,$7F,$FF,$FF,$27,$2E,$1E,$3C,$F9,$F3,$E3,$0F
        .byte   $80,$80,$C0,$C0,$C0,$C0,$C0,$80,$00,$00,$00,$00,$80,$80,$80,$00
        .byte   $1F,$13,$17,$1F,$3F,$7F,$FF,$FF,$00,$0C,$0E,$0E,$07,$3F,$7F,$00
        .byte   $FF,$9F,$0F,$03,$83,$81,$C1,$C1,$0E,$0E,$00,$01,$01,$00,$80,$00
        .byte   $80,$40,$20,$F0,$FC,$FE,$FF,$FF,$00,$80,$C0,$E0,$F0,$FC,$FE,$00
        .byte   $00,$00,$00,$20,$24,$7C,$38,$00,$02,$06,$86,$A4,$7C,$7C,$38,$00
        .byte   $04,$04,$04,$04,$03,$03,$03,$03,$02,$02,$02,$03,$01,$01,$01,$00
        .byte   $04,$04,$04,$04,$02,$02,$02,$03,$02,$02,$02,$03,$01,$01,$01,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$02,$06,$0C,$98,$F0,$E0
        .byte   $00,$00,$79,$F9,$F2,$67,$0B,$13,$00,$00,$00,$78,$F0,$62,$03,$03
        .byte   $00,$00,$00,$04,$0C,$98,$F0,$E0,$01,$01,$02,$06,$0C,$98,$F0,$E0
        .byte   $00,$00,$00,$00,$00,$00,$40,$40,$00,$00,$00,$00,$00,$00,$80,$80
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$10,$10,$38,$FE,$38,$10
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$80,$80,$80,$80,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$10,$38,$10,$10
        .byte   $04,$04,$04,$04,$02,$72,$FA,$BF,$02,$02,$02,$03,$01,$01,$71,$78
        .byte   $9E,$9E,$9F,$9F,$DF,$7F,$79,$31,$78,$78,$71,$72,$21,$01,$00,$00
        .byte   $B2,$B7,$07,$07,$8D,$7B,$87,$FF,$43,$06,$04,$05,$03,$86,$FC,$00
        .byte   $03,$07,$09,$13,$3F,$FF,$FF,$FE,$00,$00,$06,$0E,$0F,$3C,$FE,$00
        .byte   $FF,$FF,$C3,$80,$80,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6F,$0F,$0F,$1B,$F7,$EE,$1E,$FE,$0D,$09,$09,$06,$0E,$FC,$F8,$E0
        .byte   $3D,$FE,$7E,$FF,$ED,$CE,$1F,$23,$18,$1A,$8C,$CE,$87,$01,$00,$1C
        .byte   $00,$00,$00,$00,$00,$00,$04,$08,$00,$00,$00,$00,$00,$00,$00,$04
        .byte   $00,$00,$00,$00,$00,$20,$20,$40,$00,$00,$00,$00,$00,$40,$40,$80
        .byte   $08,$08,$09,$05,$04,$04,$06,$1D,$04,$04,$06,$03,$03,$03,$01,$00
        .byte   $01,$F2,$F2,$E4,$CE,$15,$25,$65,$02,$04,$FC,$F8,$F4,$E6,$C6,$86
        .byte   $00,$00,$00,$00,$00,$C0,$F0,$F8,$00,$00,$00,$00,$00,$00,$80,$00
        .byte   $0F,$10,$38,$3F,$3F,$1F,$0E,$00,$00,$0F,$1F,$1F,$1E,$0A,$00,$00
        .byte   $3D,$FE,$7E,$FF,$ED,$C6,$03,$07,$18,$1A,$8C,$CE,$87,$03,$01,$00
        .byte   $6F,$0F,$0F,$1B,$F7,$EE,$1E,$FF,$0D,$09,$09,$06,$0E,$FC,$F8,$E0
        .byte   $FC,$FC,$FC,$F8,$C0,$00,$00,$00,$D8,$F8,$F8,$C0,$00,$00,$00,$00
        .byte   $1F,$13,$17,$1F,$3F,$7F,$FF,$FF,$00,$0C,$0E,$0E,$1F,$3F,$7F,$00
        .byte   $FF,$9F,$07,$03,$83,$81,$C1,$C1,$00,$00,$00,$01,$01,$00,$80,$00
        .byte   $80,$40,$20,$F0,$FC,$FE,$FF,$FF,$00,$80,$C0,$E0,$F0,$FC,$FE,$00
        .byte   $00,$00,$00,$00,$40,$80,$80,$8F,$00,$00,$00,$00,$00,$40,$40,$40
        .byte   $00,$00,$00,$08,$08,$10,$10,$20,$00,$00,$00,$10,$10,$20,$20,$40
        .byte   $04,$02,$02,$02,$03,$0E,$1E,$3F,$03,$01,$01,$01,$00,$00,$0C,$0D
        .byte   $00,$00,$3E,$22,$22,$3E,$00,$00,$00,$00,$3E,$22,$22,$3E,$00,$00
        .byte   $F9,$F2,$67,$0A,$12,$B2,$B7,$07,$7E,$FC,$FA,$F3,$E3,$43,$06,$04
        .byte   $00,$00,$00,$E0,$F8,$FC,$FE,$FF,$00,$00,$00,$00,$40,$40,$C0,$86
        .byte   $7F,$7F,$FE,$D3,$99,$BC,$FC,$7C,$06,$07,$03,$21,$70,$78,$78,$38
        .byte   $07,$8D,$FB,$77,$8F,$FF,$FF,$FF,$05,$03,$87,$FE,$FC,$70,$00,$00
        .byte   $DF,$9F,$BF,$3E,$3E,$1C,$80,$80,$8E,$06,$1E,$0C,$1C,$00,$00,$00
        .byte   $78,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7C,$7C,$7E,$3F,$1F,$0F,$01,$00,$03,$03,$03,$0B,$05,$01,$00,$00
        .byte   $C0,$C0,$E0,$E0,$E0,$E0,$C0,$00,$80,$80,$C0,$C0,$C0,$C0,$00,$00
        .byte   $80,$80,$00,$80,$70,$7C,$7E,$FF,$00,$00,$00,$00,$80,$A0,$A0,$60
        .byte   $3F,$7F,$7F,$FE,$D3,$99,$BD,$FF,$0D,$06,$07,$03,$21,$70,$78,$78
        .byte   $07,$07,$8D,$FB,$77,$8F,$FF,$FF,$04,$05,$03,$87,$FE,$FC,$18,$00
        .byte   $FF,$DF,$9F,$BF,$3E,$BE,$9C,$C0,$86,$8E,$06,$1E,$0C,$1C,$00,$00
        .byte   $7C,$7C,$06,$03,$03,$07,$07,$03,$3B,$03,$03,$01,$01,$03,$03,$00
        .byte   $E7,$C1,$E0,$E0,$E0,$E0,$C0,$80,$00,$80,$C0,$C0,$C0,$C0,$80,$00
        .byte   $E0,$D0,$C8,$7C,$7C,$3C,$00,$00,$00,$20,$70,$38,$38,$00,$00,$00
        .byte   $3F,$7F,$7F,$FE,$D3,$99,$BC,$FC,$0D,$06,$07,$03,$21,$70,$78,$78
        .byte   $07,$07,$8D,$FB,$77,$8F,$FF,$FE,$04,$05,$03,$87,$FE,$F0,$60,$00
        .byte   $FF,$DF,$9F,$BF,$3E,$3E,$1C,$00,$86,$8E,$06,$1E,$0C,$1C,$00,$00
        .byte   $7C,$79,$01,$01,$00,$00,$00,$00,$38,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$3F,$37,$BB,$F9,$F8,$F0,$E0,$00,$C1,$E1,$F1,$70,$70,$60,$00
        .byte   $00,$80,$C0,$C0,$C0,$C0,$00,$00,$00,$00,$80,$80,$80,$00,$00,$00
        .byte   $01,$01,$3C,$46,$FF,$FF,$7F,$07,$00,$00,$00,$38,$70,$71,$01,$01
        .byte   $1E,$3E,$BC,$99,$82,$C4,$AC,$AD,$80,$DF,$7F,$7E,$7C,$38,$10,$01
        .byte   $40,$40,$80,$C0,$A0,$B8,$BE,$FF,$80,$80,$00,$80,$C0,$C0,$D0,$B0
        .byte   $0F,$07,$06,$06,$03,$0F,$1F,$23,$05,$02,$03,$01,$00,$00,$00,$1C
        .byte   $07,$07,$8D,$FB,$67,$9E,$FE,$FE,$04,$05,$03,$87,$FE,$7C,$30,$00
        .byte   $FE,$FF,$DF,$9F,$3F,$3E,$3E,$1C,$C0,$86,$8E,$0E,$1E,$0C,$1C,$00
        .byte   $23,$17,$1F,$1F,$1F,$1F,$1E,$0C,$1E,$0F,$0F,$07,$0E,$0E,$0C,$00
        .byte   $FE,$3E,$9E,$9E,$13,$11,$13,$0F,$00,$00,$00,$00,$0C,$0E,$0E,$06
        .byte   $1F,$1F,$1F,$1F,$1F,$0E,$00,$00,$0E,$0E,$0E,$0E,$0E,$00,$00,$00
        .byte   $00,$00,$00,$00,$3C,$42,$81,$00,$00,$18,$3C,$7E,$C3,$81,$00,$00
        .byte   $40,$20,$10,$10,$10,$10,$20,$40,$30,$18,$0C,$0E,$0E,$0C,$18,$30
        .byte   $00,$00,$01,$02,$02,$07,$0F,$0F,$00,$00,$00,$01,$01,$01,$07,$00
        .byte   $3F,$FF,$7F,$38,$10,$F0,$F8,$F8,$00,$00,$80,$C0,$E0,$E0,$F0,$00
        .byte   $FF,$FF,$FF,$01,$01,$01,$03,$03,$18,$F8,$00,$00,$00,$00,$01,$00
        .byte   $DC,$E0,$90,$08,$C8,$FC,$FE,$FE,$00,$00,$60,$F0,$F0,$E0,$FC,$00
        .byte   $00,$01,$02,$07,$0D,$BF,$4B,$C9,$00,$00,$01,$03,$06,$04,$B3,$31
        .byte   $70,$08,$0C,$FE,$FE,$FD,$ED,$CD,$00,$F0,$F0,$0C,$FC,$C6,$96,$36
        .byte   $20,$F0,$70,$38,$10,$F0,$F8,$F8,$1F,$0F,$8F,$C0,$E0,$E0,$F0,$00
        .byte   $00,$01,$03,$01,$01,$01,$03,$03,$FF,$FE,$FC,$00,$00,$00,$01,$00
        .byte   $1F,$0F,$0F,$00,$00,$E0,$F0,$00,$20,$F0,$F0,$F8,$F0,$F0,$F8,$F8
        .byte   $FF,$FE,$F8,$00,$00,$00,$00,$00,$18,$F9,$07,$01,$01,$01,$03,$03
        .byte   $00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $0F,$15,$78,$4B,$78,$15,$0F,$00,$00,$0A,$07,$34,$07,$0A,$00,$00
        .byte   $80,$47,$38,$BC,$3E,$7E,$81,$01,$00,$80,$C7,$43,$C1,$81,$00,$00
        .byte   $10,$20,$7F,$DF,$FC,$B8,$90,$80,$0C,$10,$30,$6F,$4C,$38,$10,$00
        .byte   $80,$C0,$E0,$E0,$D0,$D0,$DE,$D1,$00,$00,$C0,$C0,$60,$60,$60,$6E
        .byte   $80,$80,$C1,$C7,$FE,$B8,$40,$7F,$00,$00,$41,$86,$B9,$47,$3F,$00
        .byte   $F0,$F9,$FF,$BF,$13,$23,$E7,$F7,$4F,$DE,$B8,$50,$E1,$C0,$03,$C3
        .byte   $80,$80,$C0,$E0,$E0,$E0,$E0,$C0,$00,$00,$00,$C0,$C0,$C0,$C0,$80
        .byte   $01,$03,$04,$08,$0F,$0F,$1F,$1F,$00,$00,$03,$07,$07,$01,$0F,$00
        .byte   $FF,$FF,$FF,$60,$C0,$E0,$F0,$F0,$1F,$0F,$00,$80,$80,$C0,$E0,$00
        .byte   $FF,$FF,$F9,$10,$0F,$07,$07,$07,$83,$00,$06,$0F,$07,$01,$03,$00
        .byte   $C0,$80,$00,$80,$C0,$F8,$FC,$FC,$80,$00,$00,$00,$80,$C0,$F8,$00
        .byte   $38,$3C,$1C,$17,$0B,$04,$0F,$1F,$10,$14,$08,$0B,$04,$03,$02,$01
        .byte   $0F,$1F,$7B,$E1,$82,$0E,$FE,$FE,$0D,$1B,$65,$9E,$7C,$F0,$04,$FC
        .byte   $FC,$F8,$E0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $3F,$3F,$4E,$43,$43,$27,$3F,$3F,$00,$00,$30,$3C,$3F,$1F,$07,$1E
        .byte   $FE,$FE,$3E,$1E,$9E,$92,$A2,$22,$E0,$00,$00,$00,$00,$0C,$1C,$1C
        .byte   $3F,$3E,$1C,$00,$00,$00,$00,$00,$1E,$1C,$00,$00,$00,$00,$00,$00
        .byte   $32,$7E,$7C,$7C,$7C,$7C,$38,$00,$1C,$3C,$38,$38,$38,$38,$00,$00
        .byte   $00,$07,$0A,$3C,$25,$3D,$1A,$07,$00,$00,$05,$03,$1A,$02,$05,$00
        .byte   $20,$7F,$DF,$FC,$B8,$90,$80,$80,$10,$30,$6F,$4C,$38,$10,$00,$00
        .byte   $C0,$E0,$E0,$D0,$D0,$D0,$D0,$F0,$00,$C0,$C0,$60,$60,$60,$60,$40
        .byte   $00,$00,$00,$00,$18,$3C,$3A,$13,$00,$00,$00,$00,$00,$18,$1C,$0C
        .byte   $0F,$1F,$3F,$7F,$EE,$F5,$DB,$DB,$00,$08,$1F,$00,$11,$0A,$24,$24
        .byte   $C0,$E0,$F0,$F0,$F8,$B4,$34,$34,$00,$C0,$E0,$20,$10,$58,$D8,$D8
        .byte   $38,$5C,$7F,$7F,$3E,$1D,$0F,$01,$00,$28,$0C,$3E,$1F,$0E,$00,$00
        .byte   $C8,$F7,$40,$61,$BF,$2E,$3C,$98,$37,$08,$FF,$BF,$40,$D9,$DB,$E7
        .byte   $F8,$E4,$C2,$82,$33,$1F,$1F,$7F,$00,$58,$BC,$7C,$CE,$E6,$E6,$EE
        .byte   $01,$01,$02,$07,$07,$0F,$3F,$FF,$00,$00,$01,$03,$03,$01,$00,$00
        .byte   $FF,$7F,$1F,$20,$E0,$F0,$F8,$FC,$FF,$FF,$E0,$C0,$C0,$E0,$00,$00
        .byte   $FF,$9E,$1C,$BE,$7F,$7F,$7F,$FF,$CE,$E0,$F8,$7C,$3E,$38,$00,$00
        .byte   $00,$00,$00,$00,$00,$80,$E0,$F0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$0C,$1E,$3F,$3F,$00,$00,$00,$00,$00,$0C,$1E,$1E
        .byte   $00,$00,$60,$F0,$E8,$4C,$7E,$FF,$00,$00,$00,$60,$70,$30,$00,$46
        .byte   $0F,$0F,$0F,$0F,$05,$05,$04,$02,$07,$07,$06,$06,$02,$02,$03,$01
        .byte   $FF,$FF,$DD,$EB,$B6,$B6,$C8,$F7,$BF,$00,$22,$14,$49,$49,$37,$08
        .byte   $E0,$E0,$F0,$68,$68,$68,$F8,$F0,$C0,$40,$20,$B0,$B0,$B0,$00,$40
        .byte   $02,$01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $C0,$61,$BF,$BE,$AC,$BC,$D8,$FF,$7F,$BF,$40,$41,$5B,$5B,$67,$7F
        .byte   $C8,$84,$24,$12,$3E,$FE,$FC,$F8,$B0,$78,$D8,$EC,$CC,$3C,$78,$70
        .byte   $00,$01,$01,$03,$03,$07,$1F,$7F,$00,$00,$00,$01,$01,$00,$00,$00
        .byte   $9F,$0F,$C9,$D1,$F1,$F1,$F9,$FD,$7F,$F8,$F0,$E0,$E0,$60,$00,$00
        .byte   $F8,$18,$18,$BC,$FC,$FE,$FF,$FF,$00,$E0,$F0,$78,$78,$E0,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$80,$C0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$18,$3C,$3A,$00,$00,$00,$00,$00,$00,$18,$1C
        .byte   $00,$00,$01,$03,$07,$0E,$0F,$ED,$00,$00,$00,$01,$00,$01,$00,$02
        .byte   $98,$FC,$FE,$FF,$FF,$EF,$5B,$B3,$60,$00,$8C,$FE,$02,$11,$A5,$4D
        .byte   $00,$00,$00,$00,$00,$BC,$7E,$7F,$00,$00,$00,$00,$00,$00,$BC,$BE
        .byte   $36,$3E,$3F,$3E,$3E,$3C,$1F,$0C,$08,$14,$1C,$1D,$1F,$1F,$0C,$00
        .byte   $B6,$C8,$F7,$C0,$E1,$3F,$97,$9E,$49,$37,$08,$7F,$3F,$C0,$6C,$6D
        .byte   $6F,$F7,$E9,$C0,$90,$10,$10,$30,$B7,$09,$50,$B0,$60,$E0,$E0,$E0
        .byte   $E0,$C0,$80,$00,$00,$00,$00,$00,$C0,$80,$00,$00,$00,$00,$00,$00
        .byte   $01,$06,$0F,$0F,$07,$0F,$3F,$FF,$00,$01,$07,$07,$03,$01,$00,$00
        .byte   $CC,$7F,$3F,$9F,$E0,$F0,$F0,$F8,$73,$FF,$FF,$E0,$C0,$C0,$00,$00
        .byte   $EC,$C6,$8F,$FF,$3F,$7F,$7F,$FF,$F0,$FC,$FE,$1E,$1C,$38,$00,$00
        .byte   $00,$00,$00,$00,$00,$80,$E0,$F0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$30,$78,$74,$26,$3F,$00,$00,$00,$00,$30,$38,$18,$00
        .byte   $00,$00,$01,$03,$03,$03,$07,$19,$00,$00,$00,$00,$00,$00,$00,$06
        .byte   $7F,$FF,$FF,$BB,$D6,$6C,$6C,$91,$23,$7F,$00,$44,$29,$93,$93,$6E
        .byte   $80,$C0,$C0,$E0,$D0,$D0,$DC,$F3,$00,$80,$80,$40,$60,$60,$60,$0C
        .byte   $38,$7C,$FF,$FC,$B8,$70,$00,$00,$0F,$3F,$7C,$38,$50,$00,$00,$00
        .byte   $F7,$C0,$E1,$BF,$B7,$9E,$4C,$A3,$08,$7F,$3F,$40,$4C,$6D,$33,$7F
        .byte   $E0,$E1,$C7,$89,$08,$18,$70,$D0,$5F,$9F,$39,$70,$F0,$F0,$E0,$E0
        .byte   $E0,$F0,$F8,$F8,$F8,$60,$00,$00,$80,$E0,$F0,$F0,$40,$00,$00,$00
        .byte   $4F,$87,$E8,$FC,$7C,$7C,$7C,$7C,$3F,$78,$70,$70,$38,$30,$00,$00
        .byte   $C4,$84,$7E,$7E,$7E,$7C,$7C,$7C,$F8,$78,$1C,$3C,$3C,$18,$00,$00
        .byte   $7C,$F8,$F8,$F8,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $3E,$3E,$3E,$1E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$61,$FB,$FF,$FF,$7B,$39,$00,$00,$00,$60,$78,$78,$3C,$0E
        .byte   $80,$C0,$C0,$E3,$D7,$DF,$D7,$F3,$00,$80,$80,$40,$63,$67,$6F,$0C
        .byte   $00,$00,$E0,$F0,$F0,$E0,$C0,$00,$00,$00,$00,$E0,$80,$C0,$00,$00
        .byte   $06,$01,$00,$00,$00,$01,$02,$07,$01,$00,$00,$00,$00,$00,$01,$03
        .byte   $F7,$C0,$E1,$BF,$B7,$9E,$6C,$9F,$08,$7F,$3F,$40,$4C,$6D,$B3,$FF
        .byte   $E2,$E4,$C8,$88,$18,$30,$F8,$CC,$5C,$98,$30,$70,$F0,$E0,$C0,$F8
        .byte   $1F,$1F,$0F,$0F,$1F,$3F,$7E,$FC,$0F,$0E,$07,$06,$00,$00,$00,$00
        .byte   $3C,$FE,$81,$C3,$81,$00,$00,$00,$FF,$01,$00,$00,$00,$00,$00,$00
        .byte   $78,$F8,$F8,$F8,$F8,$FC,$7E,$3F,$F0,$70,$F0,$F0,$40,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $F8,$F9,$7F,$1F,$3F,$77,$7A,$6D,$1F,$1E,$00,$0F,$00,$08,$05,$12
        .byte   $C0,$E0,$FE,$FF,$FF,$7F,$DB,$9B,$00,$00,$60,$F6,$17,$8B,$2D,$6C
        .byte   $00,$00,$00,$00,$80,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6D,$32,$3D,$30,$18,$1F,$15,$17,$12,$0D,$02,$1F,$0F,$00,$0B,$0B
        .byte   $9A,$3F,$F8,$30,$77,$EF,$CF,$8F,$6C,$C0,$17,$EF,$C9,$17,$37,$77
        .byte   $00,$00,$C0,$E0,$F0,$F0,$E0,$C0,$00,$00,$00,$C0,$E0,$E0,$C0,$00
        .byte   $05,$0C,$1F,$1F,$0F,$0F,$3F,$FF,$02,$03,$0C,$0F,$07,$01,$00,$00
        .byte   $8F,$3F,$7E,$F9,$E0,$F0,$F8,$FC,$7C,$FF,$B9,$00,$C0,$80,$00,$00
        .byte   $E0,$90,$18,$3C,$FE,$FF,$7F,$FF,$40,$E0,$F0,$F8,$7C,$78,$00,$00
        .byte   $00,$00,$00,$00,$00,$80,$E0,$F0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$01,$03,$07,$0E,$0F,$0D,$8D,$00,$00,$01,$00,$01,$00,$02,$02
        .byte   $FC,$FE,$FF,$FF,$EF,$5B,$B3,$B3,$00,$8C,$FE,$02,$11,$A5,$4D,$4D
        .byte   $00,$00,$00,$00,$80,$40,$40,$40,$00,$00,$00,$00,$00,$80,$80,$80
        .byte   $07,$0F,$17,$17,$0F,$07,$00,$00,$00,$07,$0B,$0B,$07,$00,$00,$00
        .byte   $FE,$E7,$E6,$C3,$FB,$04,$02,$03,$81,$D8,$FB,$FD,$04,$03,$01,$00
        .byte   $47,$BF,$06,$0E,$FD,$5D,$78,$70,$B8,$42,$FD,$F9,$02,$B2,$B7,$8F
        .byte   $E0,$98,$1C,$FE,$FE,$FC,$F8,$E0,$00,$60,$F8,$3C,$FC,$F8,$60,$00
        .byte   $06,$0C,$0F,$0F,$07,$07,$0F,$1F,$01,$07,$07,$07,$03,$03,$00,$00
        .byte   $83,$7E,$3F,$C0,$C0,$E1,$C0,$80,$FF,$FF,$C0,$00,$80,$00,$00,$00
        .byte   $18,$1C,$3C,$FC,$FC,$FC,$FC,$7E,$E0,$F8,$F8,$38,$78,$78,$20,$00
        .byte   $3F,$7E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $70,$4F,$87,$E8,$FC,$7C,$7C,$7C,$3F,$3F,$78,$70,$70,$38,$30,$00
        .byte   $E8,$C4,$84,$7E,$7E,$7E,$7C,$7C,$F0,$F8,$78,$1C,$3C,$3C,$18,$00
        .byte   $7C,$7C,$F8,$F8,$F8,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7C,$3E,$3E,$3E,$1E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $30,$48,$84,$84,$48,$30,$00,$00,$02,$30,$78,$7A,$30,$07,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$90,$04,$51,$02,$80,$00
        .byte   $00,$30,$48,$84,$80,$48,$20,$00,$00,$0C,$30,$79,$7E,$30,$1C,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$40,$00,$40,$00,$20,$00,$00
        .byte   $00,$00,$30,$48,$84,$84,$48,$30,$01,$00,$0A,$30,$78,$78,$34,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$10,$00,$90,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$07,$18,$20,$47,$4F,$9E,$9C,$98
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$E0,$18,$04,$02,$02,$01,$01,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$07,$18,$30,$27,$4F,$4E,$4C
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$E0,$18,$0C,$04,$02,$02,$02
        .byte   $00,$00,$00,$00,$10,$30,$38,$6C,$07,$07,$0F,$0F,$17,$37,$3A,$7C
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$7F,$7F,$7F,$7F,$3F
        .byte   $4E,$5E,$7E,$BC,$BE,$F6,$72,$3C,$7E,$7E,$7E,$FC,$FE,$F6,$72,$3D
        .byte   $40,$E0,$FF,$7F,$1F,$0F,$03,$00,$4F,$E0,$FF,$7F,$9F,$EF,$F3,$F8
        .byte   $00,$00,$00,$00,$01,$01,$03,$02,$01,$01,$01,$00,$01,$01,$03,$03
        .byte   $80,$C1,$C7,$FE,$7B,$67,$7F,$FF,$00,$41,$06,$79,$24,$1B,$07,$07
        .byte   $F8,$E4,$C2,$C2,$E2,$FC,$F8,$FC,$C0,$98,$3C,$BC,$1C,$00,$C0,$E0
        .byte   $13,$13,$0B,$0F,$0F,$0F,$0F,$06,$0C,$0F,$07,$01,$07,$07,$06,$00
        .byte   $FF,$FF,$C0,$E0,$E0,$C0,$80,$00,$1E,$00,$80,$C0,$C0,$80,$00,$00
        .byte   $F0,$F8,$E4,$66,$3F,$1F,$0F,$07,$00,$00,$18,$1C,$0E,$0E,$06,$00
        .byte   $00,$00,$00,$00,$00,$1C,$42,$83,$00,$00,$00,$00,$00,$00,$30,$40
        .byte   $03,$06,$07,$05,$04,$04,$04,$0C,$01,$03,$02,$01,$00,$00,$00,$00
        .byte   $FF,$FF,$E6,$C6,$86,$06,$07,$07,$86,$7E,$63,$C3,$83,$03,$02,$06
        .byte   $00,$00,$80,$80,$F8,$BC,$BC,$FC,$00,$00,$00,$00,$00,$40,$40,$88
        .byte   $01,$02,$0F,$09,$0F,$06,$01,$00,$00,$01,$00,$06,$00,$01,$00,$00
        .byte   $FA,$BA,$1D,$7D,$0E,$B3,$E1,$00,$06,$44,$E7,$82,$F1,$40,$00,$00
        .byte   $0F,$3F,$F1,$C3,$0E,$FF,$FF,$FF,$0D,$33,$CF,$3C,$F0,$00,$00,$00
        .byte   $FC,$FC,$FC,$7C,$38,$00,$00,$00,$98,$98,$38,$38,$00,$00,$00,$00
        .byte   $FE,$7F,$7D,$31,$09,$07,$07,$03,$00,$00,$02,$0F,$07,$03,$03,$00
        .byte   $00,$00,$80,$C0,$C0,$C0,$C0,$80,$00,$00,$00,$80,$80,$80,$80,$00
        .byte   $FA,$BA,$1D,$7D,$0E,$BF,$F7,$23,$06,$44,$E7,$82,$F1,$40,$08,$1C
        .byte   $0F,$3F,$F1,$C3,$0F,$FF,$FF,$FE,$0D,$33,$CF,$3C,$F0,$02,$86,$7C
        .byte   $27,$3F,$3F,$3E,$7C,$79,$33,$07,$1C,$1C,$1E,$1C,$38,$30,$01,$03
        .byte   $FE,$7E,$7C,$7C,$F8,$C8,$88,$90,$44,$00,$00,$00,$00,$F0,$F0,$E0
        .byte   $3F,$3E,$3E,$1E,$0C,$00,$00,$00,$1E,$1C,$1C,$0C,$00,$00,$00,$00
        .byte   $06,$8C,$58,$5A,$FE,$FE,$7C,$70,$00,$02,$86,$A6,$FE,$86,$7C,$70
        .byte   $06,$8C,$58,$5A,$FE,$FE,$7C,$70,$00,$02,$86,$A6,$FE,$C6,$44,$70
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$10,$10,$10,$38,$FF,$38,$10,$10
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$38,$10,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$10,$10,$10,$10,$10,$00
        .byte   $00,$00,$00,$00,$00,$C0,$78,$FC,$FE,$FE,$FE,$FC,$3C,$C0,$F8,$FC
        .byte   $02,$03,$07,$05,$05,$07,$06,$00,$03,$03,$07,$07,$07,$07,$07,$00
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$3C,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$3C
        .byte   $0F,$5C,$BB,$BF,$BF,$60,$1F,$01,$0F,$1F,$3F,$3F,$3F,$00,$00,$00
        .byte   $CD,$FD,$FB,$FB,$F7,$0F,$FF,$FF,$CC,$FC,$F8,$F8,$F0,$00,$00,$00
        .byte   $00,$00,$03,$06,$0C,$1C,$1F,$37,$00,$00,$00,$03,$07,$0F,$0C,$1F
        .byte   $3C,$C3,$CF,$3F,$1F,$7F,$FF,$FF,$00,$3C,$F3,$CF,$FF,$BF,$7F,$FF
        .byte   $80,$3F,$6A,$40,$60,$40,$63,$43,$FF,$C0,$95,$BF,$9F,$B8,$9B,$BB
        .byte   $63,$43,$60,$7F,$2A,$00,$00,$80,$9B,$BB,$9F,$80,$D5,$FF,$7F,$80
        .byte   $00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00,$FF,$FF
        .byte   $FF,$FF,$00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00
        .byte   $80,$3F,$6A,$40,$60,$40,$63,$43,$FF,$C0,$95,$BF,$9F,$B8,$9B,$BB
        .byte   $63,$43,$63,$43,$63,$43,$63,$43,$9B,$BB,$9B,$BB,$9B,$BB,$9B,$BB
        .byte   $01,$F0,$B8,$10,$18,$10,$D8,$D0,$FD,$0E,$46,$EE,$E6,$2E,$E6,$EE
        .byte   $D8,$D0,$D8,$D0,$D8,$D0,$D8,$D0,$E6,$EE,$E6,$EE,$E6,$EE,$E6,$EE
        .byte   $FF,$FF,$FF,$FE,$F8,$F0,$E0,$C0,$00,$00,$00,$01,$07,$0F,$1F,$32
        .byte   $C3,$84,$87,$88,$0F,$08,$07,$00,$3F,$64,$7F,$48,$FF,$88,$FF,$00
        .byte   $D8,$C0,$80,$00,$08,$18,$DF,$DF,$3E,$00,$6F,$EF,$D8,$DA,$DF,$DF
        .byte   $BF,$BF,$BF,$BE,$BC,$B8,$A0,$00,$BF,$BF,$BF,$BE,$BE,$BF,$BF,$00
        .byte   $63,$03,$00,$00,$80,$80,$C0,$C0,$F8,$00,$F8,$FF,$8F,$AF,$FF,$FF
        .byte   $80,$80,$00,$C3,$82,$00,$00,$00,$FF,$FF,$3C,$DB,$DB,$3C,$FF,$00
        .byte   $FF,$FF,$FF,$3F,$1F,$0F,$07,$03,$00,$00,$00,$00,$C0,$E0,$F0,$F8
        .byte   $03,$01,$01,$08,$08,$00,$00,$00,$F8,$FC,$F4,$6A,$6A,$F6,$FE,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,$00,$00,$00,$00,$80
        .byte   $C0,$80,$00,$00,$00,$00,$00,$00,$40,$80,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$04,$00,$00,$00,$00,$00,$00,$00,$04,$00,$00,$00,$00
        .byte   $00,$00,$00,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$0C,$00,$00,$00,$00,$00,$00,$00,$0C,$00,$00,$00,$00,$00,$00
        .byte   $FF,$00,$55,$00,$FF,$FF,$AA,$00,$00,$FF,$FF,$00,$FF,$FF,$FF,$00
        .byte   $FF,$AA,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$00,$FF,$55,$00,$00
        .byte   $FF,$00,$55,$00,$FF,$FF,$AA,$00,$00,$FF,$FF,$00,$FF,$FF,$FF,$00
        .byte   $FF,$AA,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$00,$FF,$55,$00,$00
        .byte   $EA,$00,$5F,$3E,$80,$BE,$BE,$3E,$0F,$C0,$DF,$3E,$80,$BE,$BE,$3E
        .byte   $AA,$80,$3E,$2A,$00,$00,$00,$E0,$BE,$80,$BE,$3E,$BE,$40,$1F,$0A
        .byte   $BF,$73,$73,$E1,$E7,$E1,$A1,$01,$BC,$72,$72,$E1,$E0,$E1,$E1,$01
        .byte   $E1,$E1,$A1,$21,$27,$13,$13,$0F,$E1,$E1,$E1,$E1,$E0,$72,$72,$BC
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$FE,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$80,$C0,$E0,$E0,$F0,$F0
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$F8,$FC,$FE,$FE,$FF,$FF,$FF
        .byte   $63,$43,$63,$43,$63,$43,$63,$43,$9B,$BB,$9B,$BB,$9B,$BB,$9B,$BB
        .byte   $63,$43,$63,$43,$63,$43,$63,$43,$9B,$BB,$9B,$BB,$9B,$BB,$9B,$BB
        .byte   $D8,$D0,$D8,$D0,$D8,$D0,$D8,$D0,$E6,$EE,$E6,$EE,$E6,$EE,$E6,$EE
        .byte   $D8,$D0,$D8,$D0,$D8,$D0,$D8,$D0,$E6,$EE,$E6,$EE,$E6,$EE,$E6,$EE
        .byte   $80,$3F,$6A,$40,$60,$40,$63,$43,$FF,$C0,$95,$BF,$9F,$B8,$9B,$BB
        .byte   $63,$43,$63,$43,$63,$43,$63,$43,$9B,$BB,$9B,$BB,$9B,$BB,$9B,$BB
        .byte   $00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00,$FF,$FF
        .byte   $FF,$FF,$E0,$CF,$DA,$D0,$D8,$D0,$FF,$FF,$FF,$F0,$E5,$EF,$E7,$EE
        .byte   $00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00,$FF,$FF
        .byte   $FF,$FF,$07,$C3,$E3,$43,$63,$43,$FF,$FF,$F7,$3B,$1B,$BB,$9B,$BB
        .byte   $01,$F0,$B8,$10,$18,$10,$D8,$D0,$FD,$0E,$46,$EE,$E6,$2E,$E6,$EE
        .byte   $D8,$D0,$D8,$D0,$D8,$D0,$D8,$D0,$E6,$EE,$E6,$EE,$E6,$EE,$E6,$EE
        .byte   $17,$00,$00,$0F,$00,$80,$87,$80,$FF,$C0,$DE,$7F,$60,$6E,$3F,$00
        .byte   $C3,$C0,$E0,$F0,$F8,$FE,$FF,$FF,$1F,$1F,$0F,$07,$01,$00,$00,$00
        .byte   $FF,$00,$00,$00,$00,$00,$00,$04,$FF,$FF,$FF,$FF,$FF,$FF,$E0,$0E
        .byte   $E0,$00,$00,$00,$00,$00,$C0,$D0,$E0,$FF,$FF,$FF,$FA,$3F,$00,$3E
        .byte   $D3,$02,$12,$02,$10,$00,$10,$00,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$03
        .byte   $00,$00,$00,$00,$00,$00,$01,$43,$FB,$FB,$FB,$EA,$1B,$F6,$00,$F8
        .byte   $80,$00,$00,$00,$00,$01,$01,$01,$FE,$FE,$1E,$FE,$1C,$F4,$14,$E8
        .byte   $03,$03,$07,$0F,$1F,$7F,$FF,$FF,$C8,$90,$20,$C0,$80,$00,$00,$00
        .byte   $00,$FF,$AA,$00,$00,$00,$03,$63,$FF,$00,$55,$FF,$FF,$00,$03,$9B
        .byte   $43,$63,$00,$FF,$AA,$00,$00,$00,$BB,$9B,$FF,$00,$55,$FF,$FF,$00
        .byte   $00,$FF,$AA,$00,$00,$00,$C0,$D8,$FF,$00,$55,$FF,$FF,$00,$C0,$E6
        .byte   $D0,$D8,$00,$FF,$AA,$00,$00,$00,$EE,$E6,$FF,$00,$55,$FF,$FF,$00
        .byte   $60,$41,$61,$40,$60,$40,$63,$43,$99,$B8,$98,$B9,$99,$B8,$9B,$BB
        .byte   $63,$43,$60,$41,$61,$40,$60,$40,$9B,$BB,$99,$B8,$98,$B9,$99,$B8
        .byte   $18,$D0,$58,$10,$18,$10,$D8,$D0,$E6,$2E,$A6,$EE,$E6,$2E,$E6,$EE
        .byte   $D8,$D0,$18,$D0,$58,$10,$18,$10,$E6,$EE,$E6,$2E,$A6,$EE,$E6,$2E
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$F8,$80
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FE,$FC,$FC,$F8
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F0,$80,$80,$00,$00,$00,$00,$00
        .byte   $63,$43,$63,$43,$63,$43,$63,$43,$9B,$BB,$9B,$BB,$9B,$BB,$9B,$BB
        .byte   $63,$43,$60,$7F,$2A,$00,$00,$80,$9B,$BB,$9F,$80,$D5,$FF,$7F,$80
        .byte   $D8,$D0,$D8,$D0,$D8,$D0,$D8,$D0,$E6,$EE,$E6,$EE,$E6,$EE,$E6,$EE
        .byte   $D0,$D8,$10,$F8,$B0,$00,$00,$01,$EE,$E6,$EE,$06,$4E,$FE,$FC,$01
        .byte   $63,$43,$63,$43,$63,$43,$63,$43,$9B,$BB,$9B,$BB,$9B,$BB,$9B,$BB
        .byte   $63,$43,$60,$7F,$2A,$00,$00,$80,$9B,$BB,$9F,$80,$D5,$FF,$7F,$80
        .byte   $D8,$DF,$CA,$C0,$C0,$E0,$FF,$FF,$E7,$E0,$F5,$FF,$DF,$E0,$FF,$FF
        .byte   $FF,$FF,$00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00
        .byte   $63,$C3,$83,$03,$03,$07,$FF,$FF,$9B,$3B,$7B,$FB,$F3,$07,$FF,$FF
        .byte   $FF,$FF,$00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00
        .byte   $D8,$D0,$D8,$D0,$D8,$D0,$D8,$D0,$E6,$EE,$E6,$EE,$E6,$EE,$E6,$EE
        .byte   $D8,$D0,$18,$F0,$A8,$00,$00,$01,$E6,$EE,$E6,$0E,$56,$FE,$FC,$01
        .byte   $FD,$FE,$FD,$FE,$FD,$FE,$FD,$FE,$01,$00,$01,$00,$01,$00,$01,$00
        .byte   $FD,$FE,$FD,$FE,$FD,$FE,$FD,$FE,$01,$00,$01,$00,$01,$00,$01,$00
        .byte   $7F,$FF,$7F,$FF,$7F,$FF,$7F,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7F,$FF,$7F,$FF,$7F,$FF,$7F,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$F7,$F7,$00,$00,$00,$00,$00,$00,$F7,$F7
        .byte   $A5,$00,$FD,$FE,$FD,$FE,$FD,$FE,$A5,$00,$01,$00,$01,$00,$01,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$DF,$DF,$00,$00,$00,$00,$00,$00,$DF,$DF
        .byte   $4A,$00,$7F,$FF,$7F,$FF,$7F,$FF,$4A,$00,$00,$00,$00,$00,$00,$00
        .byte   $E1,$DC,$A6,$42,$02,$02,$02,$22,$00,$1C,$26,$42,$32,$1A,$4A,$62
        .byte   $22,$02,$42,$62,$22,$02,$42,$62,$32,$1A,$4A,$62,$32,$1A,$4A,$62
        .byte   $F0,$C0,$07,$1E,$38,$00,$00,$00,$00,$0F,$3F,$7E,$FE,$F8,$08,$3E
        .byte   $00,$00,$7C,$FE,$FE,$00,$F2,$FE,$FE,$83,$31,$60,$00,$00,$F2,$FE
        .byte   $0F,$03,$00,$00,$00,$00,$00,$00,$00,$F0,$FC,$7E,$7F,$1F,$10,$7C
        .byte   $00,$00,$3E,$7F,$7F,$00,$4F,$7F,$7F,$C1,$98,$30,$00,$00,$4F,$7F
        .byte   $87,$3B,$65,$42,$40,$40,$40,$44,$00,$38,$64,$42,$4C,$58,$52,$46
        .byte   $44,$40,$42,$46,$44,$40,$42,$46,$4C,$58,$52,$46,$4C,$58,$52,$46
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$01,$03
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$03,$03,$03,$03,$03,$03,$03
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $AA,$00,$9F,$3F,$BF,$3F,$BF,$3F,$AA,$00,$80,$00,$80,$00,$80,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $AA,$00,$FF,$FF,$FF,$FF,$FF,$FF,$AA,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $AA,$00,$FF,$FF,$FF,$FF,$FF,$FF,$AA,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $AB,$03,$FB,$FF,$FF,$FF,$FF,$FF,$AB,$03,$03,$03,$03,$03,$03,$03
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$7F,$BF,$00,$00,$00,$00,$00,$00,$00,$80
        .byte   $BF,$3F,$BF,$3F,$BF,$3F,$BF,$3F,$80,$00,$80,$00,$80,$00,$80,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$03,$03,$03,$03,$03,$03,$03
        .byte   $FD,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $BF,$3F,$BF,$3F,$BF,$1F,$FF,$FF,$80,$00,$80,$00,$80,$00,$FF,$FF
        .byte   $AA,$00,$FF,$FF,$FF,$FF,$FF,$FF,$AA,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$03,$03,$03,$03,$03,$03,$03
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$03,$03,$03,$03,$03,$03,$03
        .byte   $BF,$3F,$BF,$3F,$BF,$3F,$BF,$3F,$80,$00,$80,$00,$80,$00,$80,$00
        .byte   $BF,$3F,$BF,$3F,$BF,$3F,$BF,$3F,$80,$00,$80,$00,$80,$00,$80,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$03,$03,$03,$03,$03,$07,$FF,$FF
        .byte   $AA,$00,$FF,$FF,$FF,$FF,$FF,$FF,$AA,$00,$00,$00,$00,$00,$00,$00
        .byte   $BF,$3F,$BF,$3F,$BF,$3F,$BF,$3F,$80,$00,$80,$00,$80,$00,$80,$00
        .byte   $3F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $02,$02,$02,$06,$0C,$30,$40,$80,$32,$1A,$4A,$66,$4C,$33,$47,$0F
        .byte   $C9,$C2,$C2,$E2,$C2,$A2,$00,$01,$1B,$12,$1E,$0E,$06,$22,$00,$00
        .byte   $7C,$38,$00,$00,$1E,$3C,$00,$FF,$7C,$38,$07,$3C,$FE,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $3E,$1C,$00,$00,$00,$00,$00,$FF,$3E,$1C,$E0,$3C,$7F,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $40,$40,$40,$60,$30,$0C,$02,$01,$4C,$58,$52,$66,$32,$CC,$E2,$F0
        .byte   $A3,$43,$43,$47,$43,$45,$00,$80,$E8,$48,$78,$70,$60,$44,$00,$00
        .byte   $00,$FF,$AA,$00,$00,$00,$03,$63,$FF,$00,$55,$FF,$FF,$00,$03,$9B
        .byte   $43,$63,$00,$FF,$AA,$00,$00,$00,$BB,$9B,$FF,$00,$55,$FF,$FF,$00
        .byte   $18,$F0,$A8,$00,$00,$01,$FF,$FF,$E6,$0E,$56,$FE,$FC,$01,$FF,$FF
        .byte   $FF,$FF,$01,$F0,$B8,$10,$18,$10,$FF,$FF,$FD,$0E,$46,$EE,$E6,$2E
        .byte   $60,$7F,$15,$00,$00,$80,$FF,$FF,$9F,$80,$EA,$FF,$7F,$80,$FF,$FF
        .byte   $FF,$FF,$80,$3F,$6A,$40,$60,$40,$FF,$FF,$FF,$C0,$95,$BF,$9F,$B8
        .byte   $18,$D0,$58,$10,$18,$10,$D8,$D0,$E6,$2E,$A6,$EE,$E6,$2E,$E6,$EE
        .byte   $D8,$D0,$00,$FF,$AA,$00,$00,$00,$E6,$EE,$FF,$00,$55,$FF,$FF,$00
        .byte   $07,$C3,$63,$43,$63,$43,$63,$43,$F7,$3B,$9B,$BB,$9B,$BB,$9B,$BB
        .byte   $63,$43,$60,$41,$60,$40,$60,$40,$9B,$BB,$99,$B8,$99,$B9,$99,$B8
        .byte   $E0,$CF,$DA,$D8,$D0,$D8,$D0,$D8,$FF,$F0,$E5,$E7,$EF,$E6,$EE,$E6
        .byte   $D0,$D8,$00,$FF,$AA,$00,$00,$00,$EE,$E6,$FF,$00,$55,$FF,$FF,$00
        .byte   $00,$FF,$AA,$00,$00,$00,$03,$63,$FF,$00,$55,$FF,$FF,$00,$03,$9B
        .byte   $43,$63,$43,$E3,$A3,$03,$03,$07,$BB,$9B,$BB,$1B,$5B,$FB,$F3,$07
        .byte   $18,$D0,$98,$10,$18,$10,$D8,$D0,$E6,$2E,$66,$EE,$E6,$2E,$E6,$EE
        .byte   $D8,$D0,$D8,$DF,$CA,$C0,$C0,$E0,$E6,$EE,$E7,$E0,$F5,$FF,$DF,$E0
        .byte   $00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00,$FF,$FF
        .byte   $FF,$FF,$00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00
        .byte   $00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00,$FF,$FF
        .byte   $FF,$FF,$00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$01,$01,$01,$07
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1F,$3F,$3F,$7F,$7F,$7F,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$1F,$7F,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$7F,$3F,$1F,$07
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01,$01,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$3F,$0F,$01
        .byte   $00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00,$FF,$FF
        .byte   $FF,$FF,$00,$FF,$AA,$00,$00,$00,$FF,$FF,$FF,$00,$55,$FF,$FF,$00
        .byte   $01,$F0,$B8,$10,$18,$10,$D8,$D0,$FD,$0E,$46,$EE,$E6,$2E,$E6,$EE
        .byte   $D8,$D0,$18,$F0,$A8,$00,$00,$01,$E6,$EE,$E6,$0E,$56,$FE,$FC,$01
        .byte   $18,$18,$18,$1F,$38,$30,$30,$70,$1F,$1F,$1F,$1F,$3F,$3F,$3F,$7F
        .byte   $02,$12,$E6,$84,$0C,$08,$18,$30,$FE,$FE,$FE,$FC,$FC,$F8,$F8,$F0
        .byte   $00,$00,$00,$01,$03,$07,$1F,$7F,$00,$00,$00,$01,$02,$04,$18,$60
        .byte   $00,$00,$00,$C0,$E0,$F0,$F0,$E0,$00,$00,$00,$C0,$60,$30,$30,$20
        .byte   $00,$00,$01,$03,$07,$0E,$3C,$74,$00,$00,$01,$03,$07,$0F,$3F,$7F
        .byte   $79,$C7,$80,$81,$42,$34,$18,$60,$7F,$FF,$FF,$FF,$FE,$FC,$F8,$E0
        .byte   $A0,$40,$80,$00,$00,$00,$00,$00,$E0,$C0,$80,$00,$00,$00,$00,$00
        .byte   $FF,$F8,$FF,$7F,$1F,$07,$03,$01,$C7,$8F,$C7,$61,$18,$04,$02,$01
        .byte   $E0,$10,$81,$E8,$F0,$F0,$E0,$C0,$E0,$F0,$FF,$EF,$30,$30,$60,$C0
        .byte   $01,$0F,$F8,$00,$FE,$00,$00,$00,$01,$0F,$FF,$FF,$FE,$00,$00,$00
        .byte   $C3,$C6,$18,$C0,$00,$00,$00,$00,$FF,$FE,$F8,$C0,$00,$00,$00,$00
        .byte   $80,$00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,$00,$00,$00,$00
        .byte   $08,$08,$0F,$09,$08,$04,$04,$04,$0F,$0F,$0F,$0F,$0F,$07,$07,$07
        .byte   $02,$02,$06,$C4,$0C,$08,$08,$00,$FE,$FE,$FE,$FC,$FC,$F8,$F8,$F0
        .byte   $07,$05,$04,$04,$04,$04,$0C,$0E,$07,$07,$07,$07,$07,$07,$0F,$0F
        .byte   $00,$D0,$10,$00,$20,$00,$40,$00,$F0,$F0,$F0,$E0,$E0,$C0,$C0,$80
        .byte   $08,$08,$11,$10,$12,$20,$24,$48,$0F,$0F,$1F,$1E,$1E,$3C,$3C,$78
        .byte   $80,$00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$03,$07,$00,$00,$00,$00,$00,$00,$03,$04
        .byte   $00,$00,$01,$02,$04,$05,$0A,$94,$00,$00,$01,$03,$07,$07,$0E,$9C
        .byte   $80,$90,$20,$40,$80,$00,$00,$00,$F0,$F0,$E0,$C0,$80,$00,$00,$00
        .byte   $07,$0F,$0F,$0F,$0F,$1F,$1F,$1F,$04,$08,$08,$09,$09,$18,$10,$10
        .byte   $E8,$D0,$B0,$78,$FC,$FC,$FC,$F8,$F8,$70,$F0,$F8,$8C,$04,$04,$18
        .byte   $1F,$0F,$00,$00,$00,$00,$00,$00,$11,$0F,$00,$00,$00,$00,$00,$00
        .byte   $E0,$00,$00,$00,$00,$00,$00,$00,$E0,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$60,$E0,$F0,$F0,$78,$78,$3C,$00,$60,$E8,$F4,$F6,$7B,$7B,$3D
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$C0
        .byte   $3E,$1F,$0F,$07,$01,$00,$00,$00,$3E,$1F,$0F,$07,$01,$00,$00,$00
        .byte   $00,$00,$80,$C0,$E0,$70,$38,$1F,$E0,$70,$B8,$DC,$EC,$70,$38,$1F
        .byte   $00,$00,$00,$00,$40,$20,$10,$F0,$00,$00,$00,$00,$40,$20,$10,$F0
        .byte   $FF,$7E,$00,$00,$00,$00,$00,$00,$FF,$7E,$00,$00,$00,$00,$00,$00
        .byte   $00,$60,$E0,$E0,$F0,$F0,$F0,$70,$00,$6C,$EE,$EF,$F7,$F7,$F7,$77
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$C0,$C0,$E0
        .byte   $F0,$70,$78,$38,$38,$1C,$0C,$0C,$F7,$77,$7B,$3B,$3B,$1D,$0D,$0D
        .byte   $00,$00,$04,$04,$04,$04,$04,$04,$C0,$E0,$E4,$E4,$E4,$E4,$E4,$E4
        .byte   $06,$06,$03,$03,$01,$00,$00,$00,$06,$06,$03,$03,$01,$00,$00,$00
        .byte   $06,$02,$02,$03,$83,$C7,$7E,$3C,$E6,$C2,$02,$03,$83,$C7,$7E,$3C
        .byte   $0C,$0F,$0F,$0F,$07,$07,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7E,$42,$5A,$5A,$42,$7E,$00,$FE,$FE,$C6,$DE,$DE,$FE,$FE,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$07,$1F,$7F,$FF
        .byte   $00,$00,$03,$0F,$37,$3F,$CF,$3F,$07,$3F,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$40,$C0,$F0,$F8,$F4,$F8,$C0,$F0,$FC,$FC,$FE,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$0F
        .byte   $00,$00,$00,$00,$03,$0F,$07,$1F,$00,$00,$0F,$3F,$7F,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$E0,$F0,$F8,$F8,$00,$00,$E0,$F8,$F8,$FC,$FC,$FE
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$0F,$07,$07,$07,$03,$03,$03,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$40,$A0,$A0,$50,$50,$00,$80,$40,$60,$30,$38,$18,$1C
        .byte   $00,$00,$00,$00,$00,$08,$10,$10,$00,$00,$00,$00,$00,$08,$04,$04
        .byte   $00,$00,$00,$00,$01,$03,$07,$0F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $68,$68,$E8,$F4,$F4,$FA,$FA,$FB,$0C,$0E,$0F,$07,$07,$03,$03,$03
        .byte   $00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$80,$80,$C0,$C0
        .byte   $10,$18,$38,$38,$78,$70,$F0,$E0,$02,$02,$02,$02,$02,$06,$04,$0C
        .byte   $00,$00,$01,$0E,$03,$01,$01,$01,$00,$1F,$01,$00,$00,$00,$00,$00
        .byte   $FD,$3D,$0E,$46,$B2,$D8,$ED,$E7,$01,$01,$C0,$70,$38,$1C,$0F,$07
        .byte   $03,$03,$87,$87,$86,$81,$C3,$C2,$C0,$E0,$E0,$E0,$F0,$F1,$F3,$C2
        .byte   $D0,$C0,$A0,$40,$80,$00,$00,$00,$18,$18,$30,$60,$C0,$80,$00,$00
        .byte   $03,$03,$04,$01,$00,$00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00
        .byte   $F3,$02,$1E,$80,$00,$00,$00,$00,$03,$0E,$FE,$80,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$07,$00,$00,$00,$00,$00,$00,$07,$3F
        .byte   $00,$00,$00,$00,$00,$00,$00,$E0,$00,$00,$00,$00,$00,$FC,$FE,$FE
        .byte   $00,$00,$03,$02,$04,$08,$58,$70,$00,$00,$03,$0E,$1C,$38,$78,$70
        .byte   $00,$01,$07,$18,$47,$1F,$07,$01,$01,$07,$1F,$78,$C0,$00,$00,$00
        .byte   $3F,$E0,$1F,$FF,$FF,$FF,$FE,$FD,$FF,$E0,$00,$00,$00,$03,$06,$0C
        .byte   $F0,$00,$E0,$C0,$C0,$80,$C0,$C0,$F8,$00,$00,$00,$C0,$80,$00,$40
        .byte   $60,$00,$00,$00,$00,$00,$00,$00,$60,$00,$00,$00,$00,$00,$00,$00
        .byte   $F3,$EF,$DF,$8E,$0C,$0C,$08,$00,$10,$20,$41,$82,$04,$04,$08,$00
        .byte   $C0,$80,$00,$00,$00,$00,$00,$00,$C0,$80,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$7F,$FF,$F5,$F0,$C7,$EF,$CF,$EE
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FC,$FE,$5C,$0E,$F4,$BE,$DC,$4E
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$CE,$EB,$CC,$EE,$F7,$FF,$55,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$DC,$CE,$3C,$BE,$FC,$FE,$54,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$01,$03
        .byte   $80,$00,$00,$00,$00,$00,$00,$00,$80,$80,$80,$40,$00,$C0,$E0,$F0
        .byte   $40,$00,$00,$00,$00,$00,$00,$00,$60,$40,$40,$80,$00,$C0,$E0,$F0
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$F0,$FC,$FF,$7F,$7F,$7F,$7F,$3F
        .byte   $00,$00,$00,$00,$00,$1C,$30,$31,$00,$00,$00,$00,$38,$20,$4A,$41
        .byte   $31,$31,$3F,$3E,$3F,$1C,$07,$01,$41,$09,$21,$3F,$3F,$1C,$0F,$03
        .byte   $8C,$8C,$FC,$7C,$FC,$38,$E0,$80,$82,$90,$84,$7C,$FC,$38,$F0,$C0
        .byte   $30,$58,$98,$B8,$B8,$F8,$F0,$70,$30,$78,$F8,$F8,$F8,$F8,$F0,$70
        .byte   $00,$00,$00,$00,$00,$00,$40,$20,$00,$00,$00,$00,$C0,$E0,$60,$30
        .byte   $20,$20,$20,$20,$20,$40,$00,$00,$30,$30,$30,$30,$30,$60,$E0,$C0
        .byte   $0F,$0F,$0F,$1F,$1F,$1E,$3E,$3E,$0E,$0E,$0E,$1E,$1E,$1C,$3C,$3C
        .byte   $00,$00,$00,$01,$03,$07,$0F,$1B,$00,$00,$00,$01,$03,$07,$0F,$1F
        .byte   $7E,$7C,$FC,$FC,$F8,$F8,$F0,$E0,$7C,$78,$F8,$F8,$F0,$F0,$E0,$C0
        .byte   $00,$00,$00,$01,$01,$02,$02,$02,$00,$00,$00,$00,$00,$01,$01,$01
        .byte   $30,$70,$E0,$60,$60,$70,$7F,$3F,$10,$30,$60,$E0,$E0,$F0,$FF,$FF
        .byte   $00,$00,$00,$01,$07,$3E,$F8,$E0,$00,$00,$00,$01,$07,$3F,$FF,$FF
        .byte   $31,$61,$C3,$83,$07,$0E,$0C,$18,$3F,$7F,$FF,$FF,$FE,$FC,$F8,$F0
        .byte   $E0,$C0,$80,$80,$00,$00,$00,$00,$C0,$80,$00,$00,$00,$00,$00,$00
        .byte   $02,$02,$01,$01,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$80,$40,$30,$0F,$FF,$FF,$FF,$FF,$7F,$3F,$0F,$00
        .byte   $00,$00,$00,$00,$03,$0C,$30,$C0,$FF,$FF,$FF,$FF,$FC,$F0,$C0,$00
        .byte   $10,$20,$40,$80,$00,$00,$00,$00,$E0,$C0,$80,$00,$00,$00,$00,$00
        .byte   $07,$07,$07,$07,$0F,$0F,$0F,$1E,$06,$06,$06,$06,$0E,$0E,$0E,$1C
        .byte   $0F,$1F,$1F,$3E,$3C,$7C,$7C,$F8,$0E,$1E,$1E,$3C,$38,$78,$78,$F0
        .byte   $01,$03,$07,$07,$0F,$0F,$1F,$1B,$01,$03,$07,$07,$0F,$0F,$1E,$1E
        .byte   $E0,$C0,$C0,$80,$80,$80,$00,$00,$C0,$80,$80,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$30,$60,$E0,$00,$00,$00,$00,$00,$10,$20,$60
        .byte   $07,$07,$07,$07,$05,$05,$05,$02,$03,$03,$03,$03,$03,$03,$03,$01
        .byte   $00,$00,$00,$00,$00,$80,$C0,$FF,$00,$00,$00,$00,$00,$80,$C0,$FF
        .byte   $00,$00,$00,$01,$03,$07,$3E,$F8,$00,$00,$00,$01,$03,$07,$3F,$FF
        .byte   $32,$62,$E2,$C4,$84,$04,$04,$18,$3C,$7C,$FC,$F8,$F8,$F8,$F8,$E0
        .byte   $02,$01,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $3F,$00,$00,$80,$40,$30,$0F,$00,$FF,$FF,$FF,$7F,$3F,$0F,$00,$00
        .byte   $E0,$00,$00,$00,$03,$1C,$F0,$00,$FF,$FF,$FF,$FF,$FC,$E0,$00,$00
        .byte   $10,$20,$40,$80,$00,$00,$00,$00,$E0,$C0,$80,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$07,$1F,$3F,$77,$67,$00,$00,$00,$07,$1F,$3F,$7F,$7F
        .byte   $00,$1F,$78,$FF,$FF,$FF,$03,$80,$00,$1F,$7F,$FF,$C0,$FF,$FF,$FF
        .byte   $00,$80,$60,$90,$C8,$E4,$F4,$F6,$00,$80,$E0,$F0,$78,$BC,$DC,$DE
        .byte   $C7,$C7,$80,$83,$8F,$DF,$4F,$43,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$7F
        .byte   $FC,$FC,$FE,$FC,$F8,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$C0
        .byte   $76,$7E,$7E,$7E,$FC,$FC,$F8,$F8,$EE,$EE,$EE,$EE,$EC,$C0,$20,$F0
        .byte   $C7,$C7,$CF,$DF,$DF,$4F,$6F,$27,$FF,$FF,$FF,$FF,$FF,$7F,$7F,$3F
        .byte   $FF,$C0,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$F8
        .byte   $F8,$F8,$F8,$F8,$F0,$E0,$C0,$C0,$F0,$F0,$F0,$F0,$E0,$C0,$00,$C0
        .byte   $37,$3F,$1F,$0F,$03,$00,$00,$00,$3F,$3F,$1F,$0F,$03,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FE,$00,$00,$00,$FF,$FF,$FF,$FF,$FE,$00,$00,$00
        .byte   $C0,$C0,$80,$00,$00,$00,$00,$00,$C0,$C0,$80,$00,$00,$00,$00,$00
        .byte   $00,$00,$7F,$1F,$40,$40,$DF,$C0,$00,$00,$7F,$FF,$BF,$BF,$BF,$BF
        .byte   $00,$00,$FF,$FF,$00,$00,$FE,$00,$00,$00,$FF,$FF,$FF,$FE,$FE,$FC
        .byte   $DF,$FF,$FF,$FF,$FF,$7F,$00,$00,$BF,$BF,$BF,$FF,$7F,$00,$00,$00
        .byte   $FC,$FC,$F8,$F8,$F8,$F8,$00,$00,$FC,$FC,$F8,$F8,$F8,$00,$00,$00
        .byte   $00,$00,$3F,$0F,$20,$20,$6E,$60,$00,$00,$3F,$7F,$5F,$5E,$5E,$5C
        .byte   $6C,$7C,$78,$78,$78,$38,$00,$00,$5C,$5C,$58,$78,$38,$00,$00,$00
        .byte   $00,$00,$07,$01,$04,$04,$0D,$0C,$00,$00,$07,$0F,$0B,$0B,$0B,$0B
        .byte   $0D,$0F,$0F,$0F,$0F,$07,$00,$00,$0B,$0B,$0B,$0F,$07,$00,$00,$00
        .byte   $FF,$DF,$FE,$EF,$BF,$FB,$FF,$FF,$00,$20,$01,$10,$40,$04,$00,$00
        .byte   $FF,$FB,$FF,$FF,$DF,$FF,$FF,$FF,$00,$04,$00,$00,$20,$00,$00,$00
        .byte   $6F,$FF,$FD,$DF,$FF,$EE,$FF,$BF,$90,$00,$02,$20,$00,$11,$00,$40
        .byte   $FF,$FF,$FF,$FF,$EF,$FF,$FF,$FF,$00,$00,$00,$00,$10,$00,$00,$00
        .byte   $40,$54,$10,$04,$A2,$00,$44,$20,$BF,$AB,$EF,$FB,$5D,$FF,$BB,$DF
        .byte   $14,$91,$20,$22,$08,$82,$10,$44,$EB,$6E,$DF,$DD,$F7,$7D,$EF,$BB
        .byte   $40,$54,$10,$04,$A2,$00,$44,$20,$BF,$AB,$EF,$FB,$5D,$FF,$BB,$DF
        .byte   $14,$91,$20,$22,$08,$82,$10,$44,$EB,$6E,$DF,$DD,$F7,$7D,$EF,$BB
        .byte   $42,$11,$90,$2C,$91,$42,$49,$94,$15,$AA,$4A,$D3,$6E,$BD,$B6,$6B
        .byte   $50,$04,$29,$49,$40,$8A,$10,$81,$AF,$FB,$D6,$B6,$BF,$75,$EF,$7E
        .byte   $54,$C4,$10,$04,$A2,$00,$44,$20,$01,$2A,$E7,$FB,$5D,$FF,$BB,$DF
        .byte   $14,$91,$20,$22,$08,$82,$10,$44,$EB,$6E,$DF,$DD,$F7,$7D,$EF,$BB
        .byte   $09,$50,$46,$1F,$A7,$4F,$1F,$B3,$F6,$AF,$BF,$FF,$5B,$BD,$FF,$6F
        .byte   $20,$0C,$27,$89,$00,$FC,$3F,$81,$DF,$F3,$D8,$76,$FF,$03,$C0,$7E
        .byte   $40,$22,$5D,$38,$62,$E2,$F1,$9C,$BF,$DD,$BE,$E7,$FD,$DD,$FE,$6F
        .byte   $84,$4E,$58,$D9,$D0,$66,$FF,$80,$7B,$B1,$A7,$26,$2F,$89,$00,$3F
        .byte   $24,$89,$54,$40,$2B,$80,$3C,$0E,$DB,$77,$AB,$BF,$D7,$7F,$C3,$F1
        .byte   $CF,$7B,$34,$48,$07,$9F,$3C,$40,$FC,$B4,$DF,$F7,$F8,$60,$C3,$BF
        .byte   $49,$0A,$91,$76,$F9,$22,$20,$4D,$B6,$FD,$FE,$FF,$6A,$AD,$DF,$B2
        .byte   $58,$B8,$B7,$7E,$E0,$39,$8C,$22,$A7,$47,$48,$01,$1F,$C6,$73,$DD
        .byte   $59,$C6,$52,$A5,$6A,$FA,$B5,$FA,$22,$31,$AD,$5A,$95,$05,$4A,$05
        .byte   $EF,$BF,$FD,$FF,$FF,$EF,$FF,$FF,$10,$40,$02,$00,$00,$10,$00,$00
        .byte   $DD,$47,$6A,$B5,$AE,$ED,$B6,$FF,$20,$B0,$95,$4A,$51,$12,$49,$00
        .byte   $6D,$FF,$FD,$BF,$F7,$FF,$7E,$FF,$92,$00,$02,$40,$08,$00,$81,$00
        .byte   $22,$5D,$CA,$2C,$D5,$3B,$ED,$B7,$54,$80,$35,$D3,$2A,$C4,$12,$48
        .byte   $FD,$BF,$F7,$FF,$FE,$DF,$FF,$FF,$02,$40,$08,$00,$01,$20,$00,$00
        .byte   $FD,$D7,$6E,$AD,$3A,$ED,$B3,$F6,$00,$00,$80,$52,$C5,$12,$4C,$09
        .byte   $FF,$BD,$FF,$EF,$E4,$F4,$D3,$AD,$00,$42,$00,$10,$11,$0B,$24,$52
        .byte   $FF,$BF,$EF,$DD,$F7,$3D,$A7,$DE,$00,$00,$00,$00,$00,$C0,$58,$20
        .byte   $D3,$FC,$B3,$E0,$A2,$50,$20,$28,$28,$02,$08,$0F,$15,$AF,$DF,$57
        .byte   $FF,$FF,$FF,$FA,$69,$F5,$6A,$D5,$00,$00,$00,$05,$02,$0A,$05,$0A
        .byte   $12,$48,$25,$89,$2A,$44,$20,$82,$ED,$97,$5A,$76,$D5,$BB,$DF,$7D

; =============================================================================
; screen_conn_flags — per-screen room connectivity ($B400)
; Read by get_screen_boundary; masked by scroll_left/right_mask_table
; per transition_type to decide legal room exits.
; =============================================================================
screen_conn_flags:
        .byte   $80,$80,$81,$80,$80,$80,$81,$80 ; screens $00-$07
        .byte   $80,$80,$80,$80,$80,$80,$21,$20 ; screens $08-$0F
        .byte   $00,$00,$00,$FF,$FF,$FF,$FF,$FF ; screens $10-$17
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; screens $18-$1F
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; screens $20-$27
        .byte   $FF,$FF,$FF,$FF ; screens $28-$2F

; ─── screen_overlay_base — per-screen offset into overlay sets below ($B42C) ───
screen_overlay_base:
        .byte   $24,$24,$12,$24,$24,$24,$36,$36
        .byte   $12,$12,$00,$00,$00,$48,$5A,$5A
        .byte   $6C,$6C,$FF,$FF,$FF,$FF,$FF,$FF
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
        .byte   $98,$03,$99,$03,$93,$01,$93,$01,$9C,$01,$9F,$03
        .byte   $0F,$15,$30,$0F,$11,$30
; ─── set 1 (base $12) ───
        .byte   $95,$03,$93,$01,$92,$02,$9A,$03,$9A,$03,$9F,$03
        .byte   $0F,$27,$30,$0F,$27,$30
; ─── set 2 (base $24) ───
        .byte   $9C,$01,$9C,$01,$9C,$01,$95,$03,$93,$01,$9F,$03
        .byte   $0F,$11,$30,$0F,$15,$37
; ─── set 3 (base $36) ───
        .byte   $95,$02,$96,$02,$94,$02,$9E,$03,$9B,$02,$9F,$03
        .byte   $0F,$11,$30,$0F,$16,$28
; ─── set 4 (base $48) ───
        .byte   $98,$03,$99,$03,$9A,$03,$9B,$03,$9C,$03,$9F,$03
        .byte   $0F,$11,$30,$0F,$16,$27
; ─── set 5 (base $5A) ───
        .byte   $94,$01,$95,$01,$96,$01,$97,$01,$98,$01,$9F,$03
        .byte   $0F,$11,$30,$0F,$16,$27
; ─── set 6 (base $6C) ───
        .byte   $AE,$05,$AF,$05,$B0,$05,$B1,$05,$B2,$05,$B3,$05
        .byte   $0F,$30,$30,$0F,$30,$16
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
        .byte   $00,$00,$00,$01,$01,$01,$02,$03,$03,$04,$04,$04,$04,$05,$05,$05 ; $00+
        .byte   $05,$06,$06,$06,$06,$08,$0A,$0A,$0B,$0B,$0C,$0C,$0D,$0E,$0E,$10 ; $10+
        .byte   $11,$11,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+
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
        .byte   $48,$88,$B8,$38,$A8,$B8,$C8,$48,$88,$10,$10,$D8,$F0,$10,$D8,$F0 ; $00+
        .byte   $F0,$10,$D8,$F0,$F0,$18,$20,$48,$20,$A8,$20,$80,$80,$40,$6C,$E0 ; $10+
        .byte   $40,$A8,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+
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
        .byte   $78,$28,$48,$68,$58,$B8,$98,$88,$78,$38,$68,$48,$68,$78,$48,$48 ; $00+
        .byte   $70,$68,$48,$38,$68,$90,$20,$58,$20,$B8,$20,$30,$30,$30,$64,$10 ; $10+
        .byte   $10,$10,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+
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
        .byte   $21,$21,$21,$21,$21,$21,$34,$34 ; $00+: TellySpawn/TellySpawn/TellySpawn/TellySpawn/TellySpawn/TellySpawn/NeoMetall/NeoMetall
        .byte   $34,$21,$21,$12,$21,$21,$12,$21 ; $08+: NeoMetall/TellySpawn/TellySpawn/RailPlat/TellySpawn/TellySpawn/RailPlat/TellySpawn
        .byte   $21,$21,$12,$21,$21,$31,$56,$34 ; $10+: TellySpawn/TellySpawn/RailPlat/TellySpawn/TellySpawn/Blocky/NeoMetallFlip/NeoMetall
        .byte   $56,$34,$56,$37,$37,$37,$4B,$2B ; $18+: NeoMetallFlip/NeoMetall/NeoMetallFlip/PipiSpawn/PipiSpawn/PipiSpawn/CrazyCannon/FlyBoySpawn
        .byte   $2B,$2B,$FF,$FF,$FF,$FF,$FF,$FF ; $20+: FlyBoySpawn/FlyBoySpawn/?/?/?/?/?/?
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
        .byte   $0E,$0F,$10,$11,$11,$12,$12,$13,$13,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_x_tbl — secondary (persistent) spawns, max 64 ($BA40) ───
spawn2_x_tbl:
        .byte   $88,$70,$48,$F8,$F8,$F8,$F8,$08,$08,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_y_tbl — secondary (persistent) spawns, max 64 ($BA80) ───
spawn2_y_tbl:
        .byte   $A8,$C8,$38,$4F,$6F,$4F,$6F,$4F,$6F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_type_tbl — secondary spawn types ($BAC0) ───
spawn2_type_tbl:
        .byte   $76,$7A,$7B,$2F,$2F,$2F,$2F,$2F ; $00+: LargeHealth/Etank/ExtraLife/BossDoor/BossDoor/BossDoor/BossDoor/BossDoor
        .byte   $2F,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $08+: BossDoor/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $10+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $18+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $28+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $30+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $38+: ?/?/?/?/?/?/?/?

; =============================================================================
; Checkpoint tables — 11 arrays × 6 slots ($BB00-$BB41)
; Indexed by checkpoint_idx ($B0): slots 0-2 = Crash Man,
; slots 3-5 = (unused). Restored by checkpoint_respawn (bank0F:865).
; =============================================================================
chk_boss_entry_y:  .byte   $B4,$B4,$74,$B4,$B4,$B4 ; boss-entrance landing Y
chk_screen:  .byte   $00,$07,$12,$FF,$00,$00 ; checkpoint screen (nametable_select)
chk_spawn_idx:  .byte   $00,$15,$22,$22,$22,$22 ; primary spawn scan index
chk_spawn2_idx:  .byte   $00,$00,$05,$09,$09,$09 ; secondary spawn scan index
chk_metatile_hi:  .byte   $84,$86,$89,$84,$84,$84 ; metatile_ptr high
chk_metatile_lo:  .byte   $E0,$A0,$60,$E0,$E0,$E0 ; metatile_ptr low
chk_column_hi:  .byte   $85,$87,$89,$85,$85,$85 ; column_ptr high
chk_column_lo:  .byte   $60,$20,$E0,$60,$60,$60 ; column_ptr low
chk_cur_screen:  .byte   $00,$06,$0F,$00,$00,$00 ; current_screen (room index)
chk_scroll_lo:  .byte   $00,$07,$12,$00,$00,$00 ; scroll_screen_lo (left bound)
chk_scroll_hi:  .byte   $00,$08,$12,$00,$00,$00 ; scroll_screen_hi (right bound)
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
; chr_upload_list_rm — CHR-RAM upload records: Crash Man ($BC00)
; [record count, then (src_page, page_count, src_bank) × N] → CHR $0000+
; =============================================================================
chr_upload_list_rm:
        .byte   $06                     ; 6 records
        .byte   $90,$09,$00             ; CHR $0000+: $9000 × 9 pages from bank $00
        .byte   $84,$01,$09             ; CHR $0900+: $8400 × 1 pages from bank $09
        .byte   $8F,$05,$01             ; CHR $0A00+: $8F00 × 5 pages from bank $01
        .byte   $9F,$01,$03             ; CHR $0F00+: $9F00 × 1 pages from bank $03
        .byte   $80,$06,$09             ; CHR $1000+: $8000 × 6 pages from bank $09
        .byte   $A0,$0A,$07             ; CHR $1600+: $A000 × 10 pages from bank $07
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
; chr_upload_list_wily — CHR-RAM upload records: (unused) ($BD00)
; [record count, then (src_page, page_count, src_bank) × N] → CHR $0000+
; =============================================================================
chr_upload_list_wily:
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
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; =============================================================================
; palette_block_rm — Crash Man palettes ($BE00)
; [anim_target, anim_counter, 32-byte palette (BG+sprite), 4 × 16-byte
; palette animation frames] — copied verbatim to $0354-$03B5.
; =============================================================================
palette_block_rm:
        .byte   $00,$00                 ; anim target, counter
        .byte   $0F,$39,$18,$12,$0F,$12,$27,$20,$0F,$39,$18,$12,$0F,$39,$18,$01 ; palette
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$20,$38,$0F,$0F,$11,$30,$0F,$0F,$11,$30
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; anim frame 0
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; anim frame 1
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F ; anim frame 2
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
; palette_block_wily — (unused) palettes ($BF00)
; [anim_target, anim_counter, 32-byte palette (BG+sprite), 4 × 16-byte
; palette animation frames] — copied verbatim to $0354-$03B5.
; =============================================================================
palette_block_wily:
        .byte   $FF,$FF                 ; anim target, counter
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; palette
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; anim frame 0
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; anim frame 1
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; anim frame 2
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; anim frame 3
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
