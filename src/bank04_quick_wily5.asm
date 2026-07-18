.segment "BANK04"

; =============================================================================
; Bank $04 — Quick Man (stage $04) + Wily 5 (stage $0C) Stage Data
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
        .byte   $69,$69,$68,$68 ; metatile $01
        .byte   $6A,$6A,$69,$69 ; metatile $02
        .byte   $71,$69,$66,$68 ; metatile $03
        .byte   $65,$6A,$71,$69 ; metatile $04
        .byte   $69,$69,$70,$69 ; metatile $05
        .byte   $72,$69,$69,$69 ; metatile $06
        .byte   $33,$65,$33,$71 ; metatile $07
        .byte   $69,$69,$69,$69 ; metatile $08
        .byte   $77,$77,$68,$68 ; metatile $09
        .byte   $6A,$6A,$77,$77 ; metatile $0A
        .byte   $71,$77,$66,$68 ; metatile $0B
        .byte   $65,$6A,$71,$77 ; metatile $0C
        .byte   $77,$77,$70,$69 ; metatile $0D
        .byte   $72,$69,$77,$77 ; metatile $0E
        .byte   $62,$6D,$69,$61 ; metatile $0F
        .byte   $71,$69,$71,$69 ; metatile $10
        .byte   $6F,$77,$68,$68 ; metatile $11
        .byte   $6A,$6A,$6F,$77 ; metatile $12
        .byte   $69,$61,$68,$6E ; metatile $13
        .byte   $6A,$6D,$69,$61 ; metatile $14
        .byte   $69,$69,$69,$60 ; metatile $15
        .byte   $69,$62,$69,$69 ; metatile $16
        .byte   $69,$69,$70,$60 ; metatile $17
        .byte   $71,$69,$71,$77 ; metatile $18
        .byte   $77,$77,$69,$69 ; metatile $19
        .byte   $69,$69,$77,$77 ; metatile $1A
        .byte   $77,$61,$68,$6E ; metatile $1B
        .byte   $6A,$6D,$77,$61 ; metatile $1C
        .byte   $67,$69,$67,$60 ; metatile $1D
        .byte   $67,$62,$67,$69 ; metatile $1E
        .byte   $71,$61,$71,$61 ; metatile $1F
        .byte   $71,$77,$71,$69 ; metatile $20
        .byte   $6F,$77,$67,$69 ; metatile $21
        .byte   $67,$69,$6F,$77 ; metatile $22
        .byte   $67,$61,$68,$6E ; metatile $23
        .byte   $6A,$6D,$67,$61 ; metatile $24
        .byte   $77,$77,$69,$60 ; metatile $25
        .byte   $69,$62,$77,$77 ; metatile $26
        .byte   $71,$61,$66,$6E ; metatile $27
        .byte   $69,$61,$69,$61 ; metatile $28
        .byte   $67,$61,$67,$61 ; metatile $29
        .byte   $69,$61,$77,$61 ; metatile $2A
        .byte   $6F,$61,$68,$6E ; metatile $2B
        .byte   $6A,$6D,$6F,$61 ; metatile $2C
        .byte   $6F,$77,$67,$60 ; metatile $2D
        .byte   $67,$62,$6F,$77 ; metatile $2E
        .byte   $71,$34,$71,$34 ; metatile $2F
        .byte   $77,$61,$69,$61 ; metatile $30
        .byte   $6F,$61,$67,$61 ; metatile $31
        .byte   $67,$61,$6F,$61 ; metatile $32
        .byte   $67,$69,$67,$69 ; metatile $33
        .byte   $68,$68,$34,$33 ; metatile $34
        .byte   $65,$6A,$66,$68 ; metatile $35
        .byte   $71,$77,$66,$70 ; metatile $36
        .byte   $65,$6D,$71,$61 ; metatile $37
        .byte   $69,$60,$68,$6E ; metatile $38
        .byte   $67,$69,$68,$68 ; metatile $39
        .byte   $6A,$6A,$67,$69 ; metatile $3A
        .byte   $69,$67,$69,$67 ; metatile $3B
        .byte   $68,$6E,$33,$33 ; metatile $3C
        .byte   $6A,$6A,$70,$69 ; metatile $3D
        .byte   $33,$71,$33,$71 ; metatile $3E
        .byte   $33,$71,$33,$66 ; metatile $3F
        .byte   $34,$71,$34,$71 ; metatile $40
        .byte   $34,$71,$34,$66 ; metatile $41
        .byte   $34,$65,$34,$71 ; metatile $42
        .byte   $6A,$72,$67,$69 ; metatile $43
        .byte   $33,$59,$33,$71 ; metatile $44
        .byte   $6A,$6A,$68,$68 ; metatile $45
        .byte   $34,$59,$34,$71 ; metatile $46
        .byte   $68,$68,$33,$33 ; metatile $47
        .byte   $61,$34,$61,$34 ; metatile $48
        .byte   $61,$34,$6E,$34 ; metatile $49
        .byte   $6D,$34,$61,$34 ; metatile $4A
        .byte   $65,$6D,$66,$6E ; metatile $4B
        .byte   $34,$65,$34,$66 ; metatile $4C
        .byte   $6A,$6D,$68,$6E ; metatile $4D
        .byte   $33,$66,$33,$33 ; metatile $4E
        .byte   $6E,$34,$33,$33 ; metatile $4F
        .byte   $33,$71,$33,$5A ; metatile $50
        .byte   $6A,$6A,$68,$70 ; metatile $51
        .byte   $6A,$6A,$67,$60 ; metatile $52
        .byte   $66,$6E,$33,$33 ; metatile $53
        .byte   $6D,$34,$5B,$34 ; metatile $54
        .byte   $65,$6A,$72,$69 ; metatile $55
        .byte   $33,$33,$33,$65 ; metatile $56
        .byte   $33,$33,$6A,$6A ; metatile $57
        .byte   $71,$34,$5A,$34 ; metatile $58
        .byte   $67,$61,$67,$62 ; metatile $59
        .byte   $6D,$34,$6E,$34 ; metatile $5A
        .byte   $69,$62,$60,$68 ; metatile $5B
        .byte   $34,$33,$6A,$6D ; metatile $5C
        .byte   $33,$33,$6A,$6D ; metatile $5D
        .byte   $6A,$6D,$69,$62 ; metatile $5E
        .byte   $34,$33,$6A,$6A ; metatile $5F
        .byte   $23,$2B,$24,$2C ; metatile $60
        .byte   $33,$33,$23,$2B ; metatile $61
        .byte   $24,$2C,$33,$33 ; metatile $62
        .byte   $36,$33,$36,$35 ; metatile $63
        .byte   $58,$34,$58,$34 ; metatile $64
        .byte   $5A,$34,$33,$33 ; metatile $65
        .byte   $33,$58,$33,$58 ; metatile $66
        .byte   $33,$33,$59,$34 ; metatile $67
        .byte   $35,$35,$35,$35 ; metatile $68
        .byte   $35,$35,$33,$35 ; metatile $69
        .byte   $35,$33,$35,$35 ; metatile $6A
        .byte   $34,$33,$34,$33 ; metatile $6B
        .byte   $34,$33,$33,$33 ; metatile $6C
        .byte   $33,$33,$34,$33 ; metatile $6D
        .byte   $33,$33,$65,$6D ; metatile $6E
        .byte   $71,$69,$71,$60 ; metatile $6F
        .byte   $33,$33,$33,$33 ; metatile $70
        .byte   $1C,$33,$33,$1C ; metatile $71
        .byte   $33,$1C,$1C,$33 ; metatile $72
        .byte   $1C,$1C,$1C,$1C ; metatile $73
        .byte   $33,$1C,$1C,$1C ; metatile $74
        .byte   $1C,$1C,$1C,$33 ; metatile $75
        .byte   $36,$35,$36,$33 ; metatile $76
        .byte   $33,$35,$35,$35 ; metatile $77
        .byte   $59,$34,$71,$34 ; metatile $78
        .byte   $72,$69,$70,$69 ; metatile $79
        .byte   $33,$65,$33,$66 ; metatile $7A
        .byte   $68,$68,$49,$49 ; metatile $7B
        .byte   $47,$4C,$47,$4D ; metatile $7C
        .byte   $4E,$4B,$4F,$4B ; metatile $7D
        .byte   $08,$08,$08,$08 ; metatile $7E
        .byte   $34,$33,$08,$08 ; metatile $7F
        .byte   $66,$68,$33,$33 ; metatile $80
        .byte   $71,$69,$72,$69 ; metatile $81
        .byte   $70,$69,$71,$69 ; metatile $82
        .byte   $69,$61,$69,$62 ; metatile $83
        .byte   $69,$60,$69,$61 ; metatile $84
        .byte   $68,$6E,$34,$33 ; metatile $85
        .byte   $68,$68,$49,$4A ; metatile $86
        .byte   $33,$33,$08,$08 ; metatile $87
        .byte   $35,$35,$35,$33 ; metatile $88
        .byte   $36,$35,$36,$35 ; metatile $89
        .byte   $71,$6A,$71,$69 ; metatile $8A
        .byte   $33,$33,$5E,$34 ; metatile $8B
        .byte   $33,$33,$33,$5F ; metatile $8C
        .byte   $33,$5A,$33,$33 ; metatile $8D
        .byte   $33,$33,$6D,$34 ; metatile $8E
        .byte   $62,$6D,$77,$61 ; metatile $8F
        .byte   $4A,$52,$00,$00 ; metatile $90
        .byte   $33,$33,$33,$65 ; metatile $91
        .byte   $33,$71,$65,$72 ; metatile $92
        .byte   $66,$70,$33,$71 ; metatile $93
        .byte   $33,$66,$33,$33 ; metatile $94
        .byte   $00,$00,$00,$00 ; metatile $95
        .byte   $C5,$C5,$48,$50 ; metatile $96
        .byte   $C5,$C5,$16,$17 ; metatile $97
        .byte   $29,$30,$2A,$30 ; metatile $98
        .byte   $2B,$30,$2C,$30 ; metatile $99
        .byte   $2D,$30,$2E,$30 ; metatile $9A
        .byte   $2F,$30,$30,$30 ; metatile $9B
        .byte   $30,$30,$30,$30 ; metatile $9C
        .byte   $17,$C5,$17,$4E ; metatile $9D
        .byte   $38,$3A,$39,$3B ; metatile $9E
        .byte   $17,$AE,$17,$AE ; metatile $9F
        .byte   $01,$0D,$02,$0E ; metatile $A0
        .byte   $03,$0F,$04,$11 ; metatile $A1
        .byte   $05,$12,$06,$13 ; metatile $A2
        .byte   $07,$14,$08,$15 ; metatile $A3
        .byte   $09,$16,$0A,$17 ; metatile $A4
        .byte   $0B,$18,$0C,$19 ; metatile $A5
        .byte   $1A,$37,$1B,$26 ; metatile $A6
        .byte   $1C,$27,$1D,$28 ; metatile $A7
        .byte   $1E,$29,$1F,$2A ; metatile $A8
        .byte   $20,$2B,$21,$2C ; metatile $A9
        .byte   $22,$2D,$23,$2E ; metatile $AA
        .byte   $24,$2F,$25,$37 ; metatile $AB
        .byte   $37,$37,$37,$37 ; metatile $AC
        .byte   $37,$37,$30,$37 ; metatile $AD
        .byte   $31,$37,$32,$37 ; metatile $AE
        .byte   $33,$37,$34,$37 ; metatile $AF
        .byte   $35,$37,$37,$37 ; metatile $B0
        .byte   $78,$7A,$79,$7B ; metatile $B1
        .byte   $40,$40,$36,$37 ; metatile $B2
        .byte   $40,$40,$37,$37 ; metatile $B3
        .byte   $40,$78,$37,$79 ; metatile $B4
        .byte   $37,$78,$37,$79 ; metatile $B5
        .byte   $7A,$78,$7B,$79 ; metatile $B6
        .byte   $36,$37,$40,$40 ; metatile $B7
        .byte   $37,$37,$40,$40 ; metatile $B8
        .byte   $37,$37,$37,$7C ; metatile $B9
        .byte   $37,$7D,$40,$40 ; metatile $BA
        .byte   $37,$78,$7E,$79 ; metatile $BB
        .byte   $7F,$78,$40,$79 ; metatile $BC
        .byte   $00,$00,$00,$00 ; metatile $BD
        .byte   $00,$00,$00,$00 ; metatile $BE
        .byte   $00,$00,$00,$00 ; metatile $BF
        .byte   $5E,$5E,$6C,$6A ; metatile $C0
        .byte   $6C,$6B,$64,$6C ; metatile $C1
        .byte   $64,$6C,$64,$6C ; metatile $C2
        .byte   $54,$54,$54,$54 ; metatile $C3
        .byte   $00,$00,$00,$00 ; metatile $C4
        .byte   $64,$6C,$5E,$5E ; metatile $C5
        .byte   $64,$6C,$6C,$6A ; metatile $C6
        .byte   $6C,$6B,$5E,$5E ; metatile $C7
        .byte   $5E,$5E,$60,$00 ; metatile $C8
        .byte   $61,$00,$30,$38 ; metatile $C9
        .byte   $31,$39,$32,$3A ; metatile $CA
        .byte   $33,$3B,$1A,$1C ; metatile $CB
        .byte   $1B,$1D,$30,$38 ; metatile $CC
        .byte   $25,$2D,$5E,$5E ; metatile $CD
        .byte   $33,$3B,$60,$00 ; metatile $CE
        .byte   $61,$00,$5E,$5E ; metatile $CF
        .byte   $5E,$5E,$00,$68 ; metatile $D0
        .byte   $00,$69,$34,$3C ; metatile $D1
        .byte   $35,$3D,$36,$3E ; metatile $D2
        .byte   $37,$3F,$1A,$1C ; metatile $D3
        .byte   $1B,$1D,$34,$3C ; metatile $D4
        .byte   $2D,$2D,$5E,$5E ; metatile $D5
        .byte   $37,$3F,$00,$68 ; metatile $D6
        .byte   $00,$69,$5E,$5E ; metatile $D7
        .byte   $25,$2D,$25,$2D ; metatile $D8
        .byte   $61,$00,$26,$2E ; metatile $D9
        .byte   $27,$2F,$1F,$59 ; metatile $DA
        .byte   $1F,$1F,$1A,$1C ; metatile $DB
        .byte   $1B,$1D,$1F,$1F ; metatile $DC
        .byte   $1F,$59,$26,$2E ; metatile $DD
        .byte   $27,$2F,$60,$00 ; metatile $DE
        .byte   $00,$00,$00,$00 ; metatile $DF
        .byte   $2D,$2D,$2D,$2D ; metatile $E0
        .byte   $00,$69,$30,$38 ; metatile $E1
        .byte   $5E,$5E,$2D,$0D ; metatile $E2
        .byte   $2D,$0E,$2D,$2D ; metatile $E3
        .byte   $5E,$5E,$00,$00 ; metatile $E4
        .byte   $00,$00,$2D,$2D ; metatile $E5
        .byte   $33,$3B,$00,$68 ; metatile $E6
        .byte   $5E,$5E,$68,$6A ; metatile $E7
        .byte   $69,$6B,$64,$6C ; metatile $E8
        .byte   $61,$00,$59,$3C ; metatile $E9
        .byte   $5E,$5E,$64,$6C ; metatile $EA
        .byte   $62,$00,$63,$00 ; metatile $EB
        .byte   $33,$3B,$60,$00 ; metatile $EC
        .byte   $61,$00,$30,$38 ; metatile $ED
        .byte   $59,$3F,$60,$00 ; metatile $EE
        .byte   $5E,$5E,$25,$2D ; metatile $EF
        .byte   $5E,$5E,$2D,$2D ; metatile $F0
        .byte   $00,$69,$1F,$64 ; metatile $F1
        .byte   $1F,$64,$1F,$64 ; metatile $F2
        .byte   $00,$68,$00,$69 ; metatile $F3
        .byte   $37,$3F,$00,$68 ; metatile $F4
        .byte   $00,$69,$34,$3C ; metatile $F5
        .byte   $1F,$64,$00,$68 ; metatile $F6
        .byte   $2B,$2B,$2D,$2D ; metatile $F7
        .byte   $5E,$5E,$6A,$64 ; metatile $F8
        .byte   $6B,$64,$6C,$64 ; metatile $F9
        .byte   $6C,$64,$6C,$64 ; metatile $FA
        .byte   $6A,$64,$6B,$64 ; metatile $FB
        .byte   $00,$00,$00,$00 ; metatile $FC
        .byte   $00,$00,$00,$00 ; metatile $FD
        .byte   $6C,$64,$6A,$64 ; metatile $FE
        .byte   $6B,$64,$5E,$5E ; metatile $FF

; =============================================================================
; metatile_attrs — palette attribute byte per metatile ($8400)
; =============================================================================
metatile_attrs:
        .byte   $00,$00,$00,$00,$00,$00,$00,$05 ; $00-$07
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; $08-$0F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; $10-$17
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; $18-$1F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; $20-$27
        .byte   $00,$00,$00,$00,$00,$00,$00,$50 ; $28-$2F
        .byte   $00,$00,$00,$00,$44,$00,$00,$00 ; $30-$37
        .byte   $00,$00,$00,$00,$44,$00,$05,$05 ; $38-$3F
        .byte   $05,$05,$05,$00,$05,$00,$05,$44 ; $40-$47
        .byte   $50,$50,$50,$00,$05,$00,$45,$54 ; $48-$4F
        .byte   $05,$00,$00,$44,$50,$00,$15,$11 ; $50-$57
        .byte   $50,$00,$50,$00,$11,$11,$00,$11 ; $58-$5F
        .byte   $AA,$99,$66,$AA,$5F,$54,$F5,$51 ; $60-$67
        .byte   $AA,$AA,$AA,$55,$55,$55,$11,$00 ; $68-$6F
        .byte   $55,$55,$55,$55,$55,$55,$AA,$AA ; $70-$77
        .byte   $50,$00,$05,$00,$00,$00,$00,$11 ; $78-$7F
        .byte   $44,$00,$00,$00,$00,$44,$00,$11 ; $80-$87
        .byte   $AA,$AA,$00,$51,$15,$45,$51,$00 ; $88-$8F
        .byte   $33,$15,$01,$04,$45,$00,$CC,$88 ; $90-$97
        .byte   $0A,$0A,$0A,$0A,$00,$CA,$00,$0A ; $98-$9F
        .byte   $CC,$FF,$FF,$FF,$FF,$33,$00,$CF ; $A0-$A7
        .byte   $FF,$FF,$3F,$00,$00,$00,$00,$00 ; $A8-$AF
        .byte   $00,$55,$11,$11,$51,$50,$55,$44 ; $B0-$B7
        .byte   $44,$80,$64,$58,$56,$00,$00,$00 ; $B8-$BF
        .byte   $40,$10,$00,$00,$00,$00,$40,$10 ; $C0-$C7
        .byte   $04,$CD,$FF,$BB,$EE,$22,$37,$01 ; $C8-$CF
        .byte   $40,$DC,$FF,$BB,$EE,$22,$73,$10 ; $D0-$D7
        .byte   $AA,$89,$2A,$AA,$AA,$8A,$26,$00 ; $D8-$DF
        .byte   $AA,$DC,$88,$AA,$00,$88,$73,$44 ; $E0-$E7
        .byte   $11,$C1,$00,$05,$37,$CD,$34,$88 ; $E8-$EF
        .byte   $88,$18,$0A,$50,$73,$DC,$42,$99 ; $F0-$F7
        .byte   $04,$01,$00,$05,$00,$00,$04,$01 ; $F8-$FF

; =============================================================================
; screen_layouts — 64-byte rooms, column-major 8×8 metatile IDs ($8500)
; ptr = $8500 + screen × $40. Rooms are consumed in virtual-screen order;
; checkpoint tables give each stage's range:
;   Quick Man rooms $00-$16+, Wily 5 rooms $18-$28+
; Each row below = one 8-metatile column (left to right).
; =============================================================================
screen_layouts:
; ─── screen $00 ($8500) — Quick Man rooms ───
        .byte   $09,$11,$09,$0D,$21,$19,$21,$21
        .byte   $72,$74,$69,$03,$39,$05,$33,$33
        .byte   $60,$60,$70,$69,$68,$18,$22,$22
        .byte   $72,$60,$60,$70,$69,$10,$33,$33
        .byte   $75,$71,$72,$70,$71,$0B,$11,$11
        .byte   $6A,$72,$61,$71,$72,$70,$70,$70
        .byte   $68,$6A,$62,$72,$75,$0C,$12,$0A
        .byte   $0A,$12,$0A,$12,$0A,$0E,$22,$1A
; ─── screen $01 ($8540) — Quick Man rooms ───
        .byte   $19,$19,$19,$19,$25,$09,$09,$09
        .byte   $08,$15,$38,$34,$3C,$6C,$72,$71
        .byte   $1A,$2A,$6B,$71,$72,$71,$0C,$12
        .byte   $08,$5B,$5A,$70,$35,$3D,$06,$33
        .byte   $09,$49,$73,$71,$72,$10,$08,$33
        .byte   $71,$72,$70,$0C,$12,$0E,$1A,$22
        .byte   $0A,$0A,$12,$0E,$22,$1A,$1A,$22
        .byte   $1A,$1A,$22,$1A,$22,$1A,$1A,$22
; ─── screen $02 ($8580) — Quick Man rooms ───
        .byte   $09,$09,$0D,$19,$19,$21,$19,$21
        .byte   $70,$71,$36,$19,$25,$11,$09,$11
        .byte   $2C,$6B,$3E,$08,$28,$6B,$60,$70
        .byte   $29,$6B,$3F,$17,$13,$6B,$60,$70
        .byte   $1E,$4A,$70,$1F,$6B,$61,$61,$70
        .byte   $22,$8F,$6B,$27,$6B,$62,$62,$70
        .byte   $22,$2A,$6B,$71,$72,$0C,$12,$0A
        .byte   $22,$26,$12,$0A,$0A,$0E,$22,$1A
; ─── screen $03 ($85C0) — Quick Man rooms ───
        .byte   $21,$30,$40,$48,$10,$33,$33,$08
        .byte   $11,$1B,$41,$49,$0B,$11,$11,$09
        .byte   $71,$72,$73,$70,$72,$70,$71,$70
        .byte   $60,$60,$70,$71,$72,$70,$04,$3A
        .byte   $70,$71,$72,$70,$71,$0C,$0E,$22
        .byte   $73,$72,$71,$70,$0C,$0E,$1A,$22
        .byte   $12,$2C,$42,$4A,$10,$08,$08,$33
        .byte   $22,$32,$40,$48,$18,$1A,$1A,$22
; ─── screen $04 ($8600) — Quick Man rooms ───
        .byte   $2D,$09,$49,$27,$41,$13,$41,$01
        .byte   $23,$6B,$71,$72,$75,$72,$70,$70
        .byte   $70,$60,$70,$60,$70,$4B,$4C,$45
        .byte   $14,$6B,$70,$60,$70,$70,$71,$72
        .byte   $2A,$6B,$72,$71,$70,$72,$73,$71
        .byte   $2A,$6B,$71,$72,$70,$70,$71,$70
        .byte   $16,$02,$4A,$37,$42,$14,$42,$12
        .byte   $1A,$1A,$48,$1F,$40,$28,$40,$33
; ─── screen $05 ($8640) — Quick Man rooms ───
        .byte   $01,$13,$41,$13,$41,$01,$11,$01
        .byte   $70,$70,$70,$72,$71,$70,$70,$70
        .byte   $45,$4D,$42,$1C,$6B,$07,$51,$3A
        .byte   $70,$70,$4E,$47,$4F,$3E,$40,$22
        .byte   $60,$60,$8C,$57,$8B,$50,$41,$11
        .byte   $70,$60,$70,$70,$70,$70,$70,$70
        .byte   $12,$2C,$46,$42,$02,$24,$42,$02
        .byte   $33,$29,$40,$40,$19,$31,$40,$08
; ─── screen $06 ($8680) — Quick Man rooms ───
        .byte   $01,$11,$01,$01,$11,$11,$01,$01
        .byte   $70,$70,$70,$70,$70,$70,$60,$70
        .byte   $02,$52,$45,$45,$45,$54,$56,$57
        .byte   $1A,$32,$6B,$70,$70,$2F,$3E,$21
        .byte   $09,$2B,$6B,$37,$6B,$58,$3E,$33
        .byte   $70,$70,$70,$53,$6C,$70,$3E,$22
        .byte   $02,$5E,$5F,$57,$57,$55,$43,$33
        .byte   $19,$19,$21,$19,$19,$21,$19,$19
; ─── screen $07 ($86C0) — Quick Man rooms ───
        .byte   $11,$09,$09,$11,$09,$11,$0D,$21
        .byte   $60,$60,$70,$60,$71,$77,$18,$22
        .byte   $5D,$6D,$71,$72,$77,$68,$20,$21
        .byte   $30,$6B,$60,$70,$71,$69,$18,$22
        .byte   $28,$6B,$60,$70,$75,$72,$10,$33
        .byte   $2A,$6B,$72,$73,$70,$77,$18,$22
        .byte   $28,$63,$77,$6A,$77,$88,$10,$33
        .byte   $30,$76,$70,$69,$88,$74,$10,$33
; ─── screen $08 ($8700) — Quick Man rooms ───
        .byte   $32,$6B,$70,$74,$70,$04,$06,$08
        .byte   $29,$6B,$60,$70,$71,$20,$19,$19
        .byte   $31,$6B,$72,$71,$04,$06,$08,$08
        .byte   $29,$6B,$70,$72,$0B,$0D,$19,$19
        .byte   $32,$6B,$60,$70,$70,$0B,$0D,$19
        .byte   $59,$5C,$6D,$70,$70,$70,$10,$08
        .byte   $21,$30,$6B,$60,$70,$71,$20,$19
        .byte   $33,$28,$6B,$60,$70,$72,$10,$08
; ─── screen $09 ($8740) — Quick Man rooms ───
        .byte   $22,$2A,$63,$71,$70,$0C,$0E,$1A
        .byte   $33,$28,$76,$6A,$77,$20,$19,$19
        .byte   $21,$30,$6B,$69,$0C,$0E,$1A,$1A
        .byte   $33,$28,$6B,$70,$03,$05,$08,$08
        .byte   $22,$2A,$6B,$72,$71,$18,$1A,$1A
        .byte   $21,$30,$6B,$60,$70,$03,$05,$08
        .byte   $33,$28,$6B,$60,$60,$70,$18,$1A
        .byte   $22,$2A,$6B,$71,$72,$70,$10,$08
; ─── screen $0A ($8780) — Quick Man rooms ───
        .byte   $33,$16,$24,$6B,$70,$0C,$0E,$1A
        .byte   $21,$19,$31,$6B,$70,$10,$08,$08
        .byte   $33,$08,$29,$6B,$70,$18,$1A,$1A
        .byte   $22,$1A,$32,$6B,$70,$20,$19,$19
        .byte   $21,$19,$31,$6B,$70,$10,$08,$08
        .byte   $21,$19,$31,$6B,$70,$10,$08,$08
        .byte   $33,$08,$29,$6B,$0C,$0E,$1A,$1A
        .byte   $22,$1A,$32,$6B,$10,$08,$08,$08
; ─── screen $0B ($87C0) — Quick Man rooms ───
        .byte   $33,$08,$29,$6B,$10,$08,$08,$48
        .byte   $22,$1A,$32,$6B,$18,$1A,$1A,$48
        .byte   $33,$08,$29,$6B,$20,$19,$19,$48
        .byte   $21,$19,$31,$6B,$10,$08,$08,$48
        .byte   $22,$1A,$32,$6B,$0B,$09,$09,$49
        .byte   $33,$08,$29,$6B,$70,$70,$70,$70
        .byte   $22,$1A,$2E,$12,$0A,$12,$0A,$4A
        .byte   $33,$08,$33,$33,$08,$33,$08,$48
; ─── screen $0C ($8800) — Quick Man rooms ───
        .byte   $6B,$70,$70,$72,$3E,$6B,$70,$73
        .byte   $6B,$70,$70,$70,$3E,$6B,$70,$70
        .byte   $6B,$70,$70,$70,$3E,$6B,$70,$70
        .byte   $6B,$70,$70,$67,$8D,$6C,$78,$70
        .byte   $6B,$70,$70,$65,$67,$70,$58,$70
        .byte   $70,$70,$67,$70,$2F,$70,$70,$71
        .byte   $6B,$70,$2F,$70,$2F,$72,$71,$72
        .byte   $6B,$70,$2F,$70,$2F,$73,$73,$73
; ─── screen $0D ($8840) — Quick Man rooms ───
        .byte   $73,$73,$2F,$75,$72,$70,$70,$70
        .byte   $75,$72,$2F,$70,$70,$70,$70,$70
        .byte   $71,$72,$58,$70,$70,$78,$70,$70
        .byte   $70,$70,$70,$44,$6B,$2F,$70,$70
        .byte   $70,$70,$70,$50,$6B,$2F,$70,$70
        .byte   $70,$70,$78,$70,$70,$58,$70,$70
        .byte   $70,$75,$2F,$70,$70,$70,$71,$72
        .byte   $75,$72,$2F,$71,$70,$72,$74,$73
; ─── screen $0E ($8880) — Quick Man rooms ───
        .byte   $70,$70,$2F,$70,$70,$70,$71,$72
        .byte   $70,$70,$2F,$70,$70,$70,$70,$70
        .byte   $70,$70,$58,$70,$70,$70,$0C,$4A
        .byte   $70,$70,$70,$70,$70,$70,$10,$48
        .byte   $70,$70,$70,$70,$70,$70,$18,$48
        .byte   $70,$70,$78,$70,$70,$71,$10,$48
        .byte   $71,$70,$2F,$70,$71,$74,$10,$48
        .byte   $75,$72,$2F,$70,$72,$75,$18,$48
; ─── screen $0F ($88C0) — Quick Man rooms ───
        .byte   $71,$70,$3E,$40,$40,$6B,$70,$70
        .byte   $70,$70,$50,$40,$40,$6B,$70,$70
        .byte   $6B,$70,$70,$50,$40,$6B,$70,$70
        .byte   $6B,$70,$70,$70,$3E,$6B,$70,$70
        .byte   $6B,$70,$70,$70,$50,$6B,$0C,$0A
        .byte   $6B,$70,$70,$71,$70,$70,$18,$1A
        .byte   $6B,$70,$72,$71,$72,$71,$20,$19
        .byte   $6B,$70,$71,$73,$73,$74,$10,$08
; ─── screen $10 ($8900) — Quick Man rooms ───
        .byte   $71,$72,$70,$74,$70,$72,$70,$70
        .byte   $70,$70,$70,$70,$70,$71,$70,$70
        .byte   $70,$70,$71,$70,$72,$75,$70,$71
        .byte   $70,$70,$70,$44,$6B,$70,$78,$72
        .byte   $12,$0A,$2C,$40,$3A,$4A,$8A,$4A
        .byte   $22,$1A,$32,$40,$21,$48,$10,$48
        .byte   $21,$19,$31,$40,$22,$48,$10,$48
        .byte   $33,$08,$29,$40,$33,$48,$10,$48
; ─── screen $11 ($8940) — Quick Man rooms ───
        .byte   $75,$70,$3E,$48,$70,$70,$71,$75
        .byte   $72,$71,$3E,$48,$70,$71,$72,$70
        .byte   $71,$72,$3E,$48,$70,$70,$70,$72
        .byte   $70,$70,$3F,$49,$56,$8E,$70,$70
        .byte   $6B,$70,$70,$70,$3E,$48,$70,$70
        .byte   $6B,$70,$71,$70,$3E,$48,$70,$70
        .byte   $6B,$70,$70,$70,$3E,$48,$72,$71
        .byte   $6B,$70,$70,$70,$3E,$48,$71,$72
; ─── screen $12 ($8980) — Quick Man rooms ───
        .byte   $71,$72,$1F,$6B,$6F,$01,$39,$01
        .byte   $70,$71,$1F,$6B,$1F,$6B,$70,$70
        .byte   $70,$71,$1F,$6B,$1F,$6B,$0C,$12
        .byte   $71,$75,$27,$6B,$27,$6B,$10,$33
        .byte   $70,$70,$70,$70,$70,$70,$18,$22
        .byte   $70,$70,$70,$70,$70,$70,$10,$33
        .byte   $71,$71,$6E,$6D,$6E,$6D,$20,$21
        .byte   $71,$72,$1F,$6B,$1F,$6B,$10,$33
; ─── screen $13 ($89C0) — Quick Man rooms ───
        .byte   $01,$39,$01,$01,$39,$01,$05,$08
        .byte   $70,$70,$71,$70,$72,$70,$10,$08
        .byte   $0A,$2C,$6B,$60,$70,$70,$18,$1A
        .byte   $08,$29,$6B,$71,$60,$70,$10,$08
        .byte   $1A,$32,$6B,$60,$70,$70,$20,$19
        .byte   $08,$29,$6B,$72,$71,$77,$20,$19
        .byte   $19,$31,$89,$68,$68,$68,$10,$08
        .byte   $08,$29,$6B,$60,$70,$69,$20,$19
; ─── screen $14 ($8A00) — Quick Man rooms ───
        .byte   $08,$29,$6B,$60,$60,$70,$20,$19
        .byte   $19,$31,$6B,$60,$70,$70,$18,$1A
        .byte   $08,$29,$6B,$70,$71,$7A,$79,$08
        .byte   $19,$31,$6B,$71,$72,$73,$18,$1A
        .byte   $19,$31,$6B,$71,$71,$72,$10,$08
        .byte   $08,$1E,$14,$6B,$70,$7A,$79,$08
        .byte   $19,$21,$30,$63,$72,$71,$18,$1A
        .byte   $08,$33,$28,$89,$68,$68,$20,$19
; ─── screen $15 ($8A40) — Quick Man rooms ───
        .byte   $08,$33,$28,$76,$70,$7A,$79,$08
        .byte   $19,$21,$30,$6B,$71,$72,$18,$1A
        .byte   $19,$21,$30,$6B,$72,$71,$20,$19
        .byte   $08,$33,$28,$6B,$70,$04,$06,$08
        .byte   $1A,$22,$2A,$6B,$72,$20,$19,$19
        .byte   $08,$33,$28,$6B,$71,$10,$08,$08
        .byte   $7B,$86,$85,$6C,$0C,$0E,$1A,$1A
        .byte   $7C,$7D,$7F,$87,$10,$08,$08,$08
; ─── screen $16 ($8A80) — Quick Man rooms ───
        .byte   $00,$1F,$6B,$70,$1F,$00,$00,$00
        .byte   $00,$1F,$6B,$70,$1F,$00,$00,$00
        .byte   $00,$1F,$6B,$70,$1F,$00,$00,$00
        .byte   $00,$1F,$6B,$70,$1F,$00,$00,$00
        .byte   $00,$1F,$6B,$70,$1F,$00,$00,$00
        .byte   $00,$1F,$6B,$70,$1F,$00,$00,$00
        .byte   $00,$1F,$6B,$70,$1F,$00,$00,$00
        .byte   $00,$1F,$7F,$87,$1F,$00,$00,$00
; ─── screen $17 ($8AC0) — Quick Man boss corridor ───
        .byte   $47,$3C,$6C,$71,$80,$47,$82,$08
        .byte   $71,$72,$71,$72,$71,$91,$81,$08
        .byte   $72,$71,$72,$71,$72,$92,$08,$08
        .byte   $71,$72,$71,$72,$71,$93,$08,$08
        .byte   $72,$71,$72,$71,$72,$92,$08,$08
        .byte   $71,$72,$71,$72,$71,$93,$08,$08
        .byte   $72,$71,$72,$71,$72,$94,$82,$08
        .byte   $57,$57,$57,$57,$57,$57,$81,$08
; ─── screen $18 ($8B00) — Wily 5 rooms ───
        .byte   $C0,$C8,$D0,$C8,$D0,$C8,$D0,$F8
        .byte   $C1,$C9,$D1,$D9,$E1,$E9,$F1,$F9
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE,$E6,$EE,$F6,$FE
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
; ─── screen $19 ($8B40) — Wily 5 rooms ───
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0,$E3,$E0,$E8,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C5,$CD,$D5,$D5,$D5,$D5,$C5,$C5
; ─── screen $1A ($8B80) — Wily 5 rooms ───
        .byte   $C0,$C8,$D0,$C8,$D0,$C8,$D0,$F8
        .byte   $C1,$C9,$D1,$D9,$E1,$E9,$F1,$F9
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE,$E6,$EE,$F6,$FE
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
; ─── screen $1B ($8BC0) — Wily 5 rooms ───
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0,$E3,$E0,$E8,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C5,$CD,$D5,$D5,$D5,$D5,$C5,$C5
; ─── screen $1C ($8C00) — Wily 5 rooms ───
        .byte   $C0,$C8,$D0,$C8,$D0,$C8,$D0,$F8
        .byte   $C1,$C9,$D1,$D9,$E1,$E9,$F1,$F9
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE,$E6,$EE,$F6,$FE
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
; ─── screen $1D ($8C40) — Wily 5 rooms ───
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0,$E3,$E0,$E8,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C5,$CD,$D5,$D5,$D5,$D5,$C5,$C5
; ─── screen $1E ($8C80) — Wily 5 rooms ───
        .byte   $C0,$C8,$D0,$C8,$D0,$C8,$D0,$F8
        .byte   $C1,$C9,$D1,$D9,$E1,$E9,$F1,$F9
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE,$E6,$EE,$F6,$FE
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
; ─── screen $1F ($8CC0) — Wily 5 rooms ───
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0,$E3,$E0,$E8,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C5,$CD,$D5,$D5,$D5,$D5,$C5,$C5
; ─── screen $20 ($8D00) — Wily 5 rooms ───
        .byte   $B1,$B2,$B3,$B3,$B3,$B3,$B4,$B6
        .byte   $B1,$A0,$A6,$AC,$AC,$AC,$B5,$B6
        .byte   $B1,$A1,$A7,$AD,$AC,$AC,$B5,$B6
        .byte   $B1,$A2,$A8,$AE,$AC,$AC,$B5,$B6
        .byte   $B1,$A3,$A9,$AF,$AC,$AC,$B5,$B6
        .byte   $B1,$A4,$AA,$B0,$AC,$AC,$B5,$B6
        .byte   $B1,$A5,$AB,$AC,$AC,$B9,$BB,$B6
        .byte   $B1,$B7,$B8,$B8,$B8,$BA,$BC,$B6
; ─── screen $21 ($8D40) — Wily 5 rooms ───
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0,$E3,$E0,$E8,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C5,$CD,$D5,$D5,$D5,$D5,$C5,$C5
; ─── screen $22 ($8D80) — Wily 5 rooms ───
        .byte   $C0,$C8,$D0,$C8,$D0,$C8,$D0,$F8
        .byte   $C1,$C9,$D1,$D9,$E1,$E9,$F1,$F9
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE,$E6,$EE,$F6,$FE
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
; ─── screen $23 ($8DC0) — Wily 5 rooms ───
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0,$E3,$E0,$E8,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C5,$CD,$D5,$D5,$D5,$D5,$C5,$C5
; ─── screen $24 ($8E00) — Wily 5 rooms ───
        .byte   $C0,$C8,$D0,$C8,$D0,$C8,$D0,$F8
        .byte   $C1,$C9,$D1,$D9,$E1,$E9,$F1,$F9
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE,$E6,$EE,$F6,$FE
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
; ─── screen $25 ($8E40) — Wily 5 rooms ───
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0,$E3,$E0,$E8,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C5,$CD,$D5,$D5,$D5,$D5,$C5,$C5
; ─── screen $26 ($8E80) — Wily 5 rooms ───
        .byte   $C0,$C8,$D0,$C8,$D0,$C8,$D0,$F8
        .byte   $C1,$C9,$D1,$D9,$E1,$E9,$F1,$F9
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE,$E6,$EE,$F6,$FE
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
; ─── screen $27 ($8EC0) — Wily 5 rooms ───
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0,$E3,$E0,$E8,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C5,$CD,$D5,$D5,$D5,$D5,$C5,$C5
; ─── screen $28 ($8F00) — Wily 5 rooms ───
        .byte   $C0,$C8,$D0,$C8,$D0,$C8,$D0,$F8
        .byte   $C1,$C9,$D1,$D9,$E1,$E9,$F1,$F9
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C6,$EC,$F4,$DB,$CB,$EB,$F3,$FB
        .byte   $C1,$ED,$F5,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE,$E6,$EE,$F6,$FE
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
; ─── screen $29 ($8F40) — Wily 5 boss corridor ───
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
; ─── screen $2A ($8F80) ───
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
; ─── screen $2B ($8FC0) ───
        .byte   $B1,$B2,$B3,$B3,$B3,$B3,$B4,$B6
        .byte   $B1,$A0,$A6,$AC,$AC,$AC,$B5,$B6
        .byte   $B1,$A1,$A7,$AD,$AC,$AC,$B5,$B6
        .byte   $B1,$A2,$A8,$AE,$AC,$AC,$B5,$B6
        .byte   $B1,$A3,$A9,$AF,$AC,$AC,$B5,$B6
        .byte   $B1,$A4,$AA,$B0,$AC,$AC,$B5,$B6
        .byte   $B1,$A5,$AB,$AC,$AC,$B9,$BB,$B6
        .byte   $B1,$B7,$B8,$B8,$B8,$BA,$BC,$B6

; =============================================================================
; CHR pattern data $9000-$B3FF (36 pages)
; Referenced by: Metal Man CHR list, Quick Man CHR list, Wily 5 CHR list, bank00 overlay sets, bank01 overlay sets, bank02 overlay sets, bank03 overlay sets, bank04 overlay sets, bank05 overlay sets, bank06 overlay sets, group 4 (ending)
; =============================================================================
        .byte   $00,$00,$00,$00,$00,$20,$20,$10,$00,$00,$00,$00,$00,$40,$40,$E0
        .byte   $00,$0E,$31,$43,$44,$84,$87,$BC,$00,$00,$0E,$3C,$3B,$7B,$78,$43
        .byte   $00,$00,$00,$00,$83,$45,$4B,$57,$00,$00,$00,$00,$00,$82,$84,$88
        .byte   $04,$00,$49,$1B,$1F,$1F,$9F,$CF,$19,$1F,$BF,$FF,$FF,$FF,$7F,$3F
        .byte   $A4,$94,$C2,$C3,$F8,$F9,$F1,$E3,$C8,$E9,$FC,$FC,$FF,$FE,$FE,$FC
        .byte   $00,$00,$00,$00,$C0,$20,$D0,$C8,$00,$00,$00,$00,$00,$C0,$20,$30
        .byte   $48,$21,$1F,$0F,$07,$07,$02,$01,$37,$1E,$00,$06,$03,$03,$01,$00
        .byte   $53,$91,$12,$3F,$7F,$FF,$77,$23,$8C,$0E,$0D,$14,$34,$72,$E2,$C1
        .byte   $E7,$FF,$00,$F1,$CA,$84,$B1,$B1,$1F,$00,$FF,$0E,$04,$00,$00,$00
        .byte   $FF,$F8,$03,$FF,$1F,$0F,$8E,$8C,$E0,$07,$FC,$00,$00,$00,$01,$03
        .byte   $08,$18,$34,$62,$E2,$E2,$3E,$1E,$F0,$E0,$C8,$9C,$9C,$1C,$C4,$EC
        .byte   $C1,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $C6,$FF,$4F,$30,$1F,$7A,$FF,$F8,$80,$46,$3F,$0F,$00,$17,$78,$C0
        .byte   $1F,$FC,$04,$3C,$F2,$79,$FE,$1D,$00,$0B,$FB,$C3,$01,$B0,$18,$0E
        .byte   $1F,$0F,$0D,$1D,$3E,$C0,$00,$00,$E6,$F2,$FA,$EE,$C0,$00,$00,$00
        .byte   $02,$04,$04,$0F,$3F,$7F,$FF,$FF,$01,$03,$03,$00,$0F,$3F,$7F,$00
        .byte   $20,$20,$10,$10,$90,$F0,$F8,$F8,$C0,$C0,$E0,$E0,$60,$80,$F0,$00
        .byte   $08,$10,$10,$10,$0B,$0F,$1F,$1F,$07,$0F,$0F,$0F,$04,$03,$0F,$00
        .byte   $80,$40,$40,$F0,$FC,$FE,$FF,$FF,$00,$80,$80,$00,$F0,$FC,$FE,$00
        .byte   $00,$00,$00,$03,$C3,$8F,$CF,$C7,$01,$0B,$0B,$3F,$3F,$7F,$3F,$3F
        .byte   $00,$08,$8C,$82,$A7,$E3,$A7,$C7,$20,$F0,$F0,$FC,$F8,$FC,$F8,$F8
        .byte   $E3,$FF,$00,$F1,$CA,$84,$B1,$B1,$1F,$00,$FF,$0E,$04,$00,$00,$00
        .byte   $1F,$F8,$03,$FF,$1F,$0F,$8E,$8C,$E0,$07,$FC,$00,$00,$00,$01,$03
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$31,$7B,$4E,$4E,$39
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$E0,$F0,$70,$70,$E0
        .byte   $00,$00,$00,$00,$04,$44,$42,$21,$00,$00,$00,$00,$08,$88,$8C,$C6
        .byte   $01,$00,$25,$25,$03,$07,$27,$2F,$2E,$0F,$4F,$5F,$7F,$7F,$FF,$FF
        .byte   $0B,$07,$07,$C6,$CE,$CC,$D8,$13,$F0,$F8,$F8,$F9,$F1,$F3,$E7,$ED
        .byte   $C0,$20,$3C,$32,$61,$E1,$E7,$EF,$00,$C0,$E0,$EC,$DE,$DE,$D8,$D6
        .byte   $00,$00,$00,$01,$03,$06,$0D,$1D,$00,$00,$00,$00,$00,$01,$02,$0A
        .byte   $2F,$1F,$0F,$9F,$C7,$FE,$F8,$F0,$FF,$FF,$FE,$7C,$38,$01,$07,$0F
        .byte   $F7,$E7,$CF,$9F,$23,$41,$41,$B1,$89,$18,$30,$60,$C0,$80,$80,$00
        .byte   $FE,$FA,$F9,$F9,$F1,$D1,$D2,$A4,$E3,$F1,$F0,$F0,$60,$60,$61,$43
        .byte   $80,$40,$E0,$F0,$F0,$10,$08,$04,$00,$80,$C0,$E0,$E0,$E0,$F0,$F8
        .byte   $00,$00,$00,$00,$00,$01,$02,$04,$00,$00,$00,$00,$00,$00,$01,$03
        .byte   $3D,$7C,$9A,$D1,$E0,$F0,$08,$08,$1A,$3B,$71,$60,$40,$40,$F0,$F0
        .byte   $CF,$19,$39,$FC,$7F,$1F,$03,$07,$30,$E0,$C0,$60,$1C,$03,$00,$03
        .byte   $31,$82,$BC,$71,$E3,$8C,$FA,$FF,$00,$01,$03,$3E,$3C,$F3,$07,$C0
        .byte   $24,$44,$C2,$C2,$61,$70,$F8,$3E,$C3,$83,$01,$01,$80,$A0,$30,$18
        .byte   $04,$04,$08,$70,$80,$00,$00,$00,$F8,$F8,$F0,$80,$00,$00,$00,$00
        .byte   $08,$08,$08,$05,$05,$03,$00,$00,$07,$07,$07,$02,$02,$00,$00,$00
        .byte   $04,$14,$34,$38,$40,$40,$80,$00,$F8,$E8,$C8,$C0,$80,$80,$00,$00
        .byte   $0F,$08,$08,$0F,$3F,$7F,$FF,$FF,$06,$07,$07,$00,$0F,$3F,$7F,$00
        .byte   $E0,$40,$20,$10,$90,$F0,$F8,$F8,$00,$80,$C0,$E0,$60,$80,$F0,$00
        .byte   $19,$20,$20,$20,$13,$0F,$1F,$1F,$06,$1F,$1F,$1F,$0C,$03,$0F,$00
        .byte   $80,$C0,$40,$F0,$FC,$FE,$FF,$FF,$00,$00,$80,$00,$F0,$FC,$FE,$00
        .byte   $00,$00,$01,$02,$04,$09,$09,$08,$00,$00,$00,$01,$03,$06,$06,$07
        .byte   $02,$00,$E0,$18,$08,$81,$C1,$0D,$05,$0F,$0F,$E7,$F7,$7F,$3F,$FF
        .byte   $03,$77,$4F,$06,$0E,$AC,$18,$93,$00,$80,$B0,$F9,$F1,$F3,$E7,$ED
        .byte   $09,$0F,$1F,$3F,$4F,$5B,$7D,$3D,$06,$04,$0E,$1C,$30,$30,$32,$1A
        .byte   $86,$04,$C3,$83,$C7,$FE,$F8,$F0,$7F,$FF,$3E,$7C,$38,$01,$07,$0F
        .byte   $1D,$0C,$02,$01,$00,$00,$00,$00,$0A,$03,$01,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$01,$0C,$0C,$07,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$38,$7C,$7C,$9C,$9C,$F8,$80
        .byte   $03,$0D,$12,$17,$2E,$46,$43,$BF,$00,$02,$0C,$0C,$17,$3F,$3F,$4F
        .byte   $30,$48,$C8,$0C,$12,$A4,$F6,$FA,$00,$30,$30,$F0,$EC,$F8,$F8,$C4
        .byte   $BF,$97,$93,$9F,$4F,$23,$18,$07,$47,$6B,$6C,$73,$3F,$1F,$07,$00
        .byte   $F9,$B1,$31,$F2,$E2,$C4,$18,$E0,$8E,$4E,$CE,$1C,$FC,$F8,$E0,$00
        .byte   $00,$03,$04,$16,$2A,$22,$22,$7A,$00,$00,$03,$01,$15,$1F,$1F,$0F
        .byte   $00,$80,$50,$68,$44,$04,$C2,$FA,$00,$00,$80,$90,$B8,$F8,$FC,$C4
        .byte   $7F,$57,$53,$4F,$27,$13,$08,$07,$07,$2B,$2C,$33,$1F,$0F,$07,$00
        .byte   $F2,$B2,$32,$E4,$C4,$88,$30,$C0,$8C,$4C,$CC,$18,$F8,$F0,$C0,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$F2,$17,$52,$72,$47,$42,$42
        .byte   $03,$0D,$3D,$7D,$FD,$FD,$FD,$FD,$00,$02,$0E,$3E,$7E,$FE,$FE,$FE
        .byte   $0F,$1F,$1F,$3E,$3C,$78,$78,$F8,$07,$0F,$0F,$1E,$1C,$38,$38,$78
        .byte   $FD,$FD,$FD,$1D,$0D,$05,$05,$05,$FE,$FE,$FE,$1E,$0E,$06,$06,$06
        .byte   $BF,$BF,$BF,$BF,$BF,$BF,$BF,$BF,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $F0,$F8,$F8,$FC,$FC,$FE,$FE,$FF,$E0,$F0,$F0,$F8,$F8,$FC,$FC,$FE
        .byte   $00,$00,$01,$01,$01,$01,$03,$03,$00,$00,$00,$00,$00,$00,$01,$01
        .byte   $F8,$FC,$FE,$FF,$FF,$FF,$FF,$FF,$78,$7C,$FE,$FF,$FF,$FF,$FF,$FF
        .byte   $05,$0D,$1D,$FD,$FF,$FE,$FE,$FF,$06,$0E,$1E,$FE,$FD,$FB,$FB,$FD
        .byte   $BF,$BF,$BF,$BF,$FF,$7F,$7F,$FF,$7F,$7F,$7F,$7F,$BF,$DF,$DF,$BF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $03,$07,$0B,$13,$23,$43,$81,$81,$01,$01,$05,$0D,$1D,$3D,$7E,$7E
        .byte   $DF,$9F,$8F,$8F,$8F,$CF,$E7,$F7,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FE,$FC,$FC,$F8,$FE,$3F,$C7,$F8,$FD,$FB,$FB,$F7
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $C0,$C0,$C0,$C0,$C0,$C0,$80,$80,$80,$80,$80,$80,$80,$80,$00,$00
        .byte   $81,$81,$81,$41,$40,$40,$40,$20,$7E,$7E,$7E,$3E,$3F,$3F,$3F,$1F
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$7F,$7F,$7F,$BF
        .byte   $F8,$F0,$F0,$E0,$E0,$F8,$FF,$FF,$F7,$EF,$EF,$DF,$DF,$E7,$F8,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FE,$FE,$FE,$FC
        .byte   $80,$80,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $20,$10,$10,$08,$04,$02,$01,$00,$1F,$0F,$0F,$07,$03,$01,$00,$00
        .byte   $7F,$3F,$3F,$1F,$1F,$0F,$07,$83,$BF,$DF,$DF,$EF,$EF,$F7,$FB,$7D
        .byte   $FF,$FC,$FC,$F8,$F8,$F8,$E9,$C6,$FC,$FB,$FB,$F7,$F7,$E7,$C6,$80
        .byte   $00,$80,$40,$40,$40,$80,$00,$00,$00,$00,$80,$80,$80,$00,$00,$00
        .byte   $43,$23,$11,$09,$05,$03,$01,$01,$3D,$1D,$0E,$06,$02,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$9E,$FF,$FF,$FF,$FF,$FF,$0F,$F6,$F0
        .byte   $FF,$FF,$FE,$FC,$F0,$C0,$80,$00,$FF,$FE,$FC,$F0,$C0,$80,$00,$00
        .byte   $00,$00,$00,$00,$03,$0C,$30,$20,$00,$00,$00,$00,$00,$03,$0F,$1F
        .byte   $03,$0C,$30,$C0,$00,$00,$00,$00,$00,$03,$0F,$3F,$FF,$FF,$FF,$FF
        .byte   $F8,$F8,$08,$08,$08,$08,$08,$08,$F0,$00,$F0,$F0,$F0,$F0,$F0,$F0
        .byte   $20,$1E,$01,$00,$00,$00,$00,$00,$1F,$01,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$C0,$3C,$02,$01,$00,$00,$FF,$FF,$3F,$03,$01,$00,$00,$00
        .byte   $08,$08,$08,$08,$08,$88,$68,$18,$F0,$F0,$F0,$F0,$F0,$70,$10,$00
        .byte   $00,$00,$00,$06,$0D,$1D,$3E,$3E,$00,$00,$00,$00,$06,$0E,$1F,$1F
        .byte   $00,$00,$00,$00,$F8,$08,$90,$A0,$00,$00,$00,$00,$00,$F0,$60,$40
        .byte   $00,$00,$00,$00,$01,$01,$03,$03,$00,$00,$00,$00,$00,$00,$01,$01
        .byte   $7F,$7F,$FF,$FF,$FF,$F0,$E0,$C0,$3F,$3F,$7F,$7F,$FF,$F0,$E0,$C0
        .byte   $40,$40,$BE,$A2,$D4,$D8,$68,$28,$80,$80,$C0,$DC,$E8,$E0,$70,$30
        .byte   $06,$02,$7D,$45,$2B,$1B,$17,$17,$01,$01,$03,$3B,$17,$07,$0F,$0F
        .byte   $FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$FC,$FE,$FE,$FF,$FF,$FF,$FF
        .byte   $03,$03,$07,$07,$07,$07,$07,$07,$01,$01,$03,$03,$03,$03,$03,$03
        .byte   $C0,$C0,$C0,$E0,$F0,$FF,$FF,$FF,$C0,$C0,$C0,$E0,$F0,$FF,$FF,$FF
        .byte   $34,$36,$3B,$7F,$FF,$FE,$FE,$FF,$38,$38,$3C,$7C,$FD,$FB,$FB,$FD
        .byte   $2F,$6F,$DF,$FF,$FF,$7F,$7F,$FF,$1F,$1F,$3F,$3F,$BF,$DF,$DF,$BF
        .byte   $7F,$3F,$3F,$1F,$1F,$0F,$07,$C3,$BF,$DF,$DF,$EF,$EF,$F7,$FB,$3D
        .byte   $FF,$FC,$FC,$F8,$F8,$F8,$E9,$E6,$FC,$FB,$FB,$F7,$F7,$E7,$C6,$C0
        .byte   $31,$0C,$03,$00,$00,$00,$00,$00,$0E,$03,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$7F,$FF,$0F,$03,$01,$00,$FF,$7F,$BF,$0F,$03,$01,$00,$00
        .byte   $C0,$C0,$80,$80,$80,$00,$80,$80,$80,$80,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$01,$03,$07,$00,$00,$00,$00,$00,$00,$01,$03
        .byte   $00,$18,$3C,$3C,$18,$00,$00,$00,$3C,$66,$C3,$C3,$E7,$FF,$7E,$3C
        .byte   $01,$41,$21,$1B,$1F,$0D,$1F,$FF,$00,$00,$00,$00,$00,$02,$04,$00
        .byte   $00,$04,$08,$B0,$F0,$E0,$F0,$FE,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $1F,$0F,$1F,$1B,$21,$41,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $F0,$E0,$F0,$B0,$08,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$03,$01,$0D,$3C,$64,$C7,$CD,$00,$02,$02,$0E,$3F,$7C,$FF,$FE
        .byte   $00,$C0,$80,$B0,$3C,$3E,$FF,$BF,$00,$40,$40,$70,$FC,$3E,$FF,$7F
        .byte   $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$03,$03,$03,$03
        .byte   $FD,$FC,$FC,$C7,$83,$81,$01,$00,$FE,$FF,$FC,$C7,$83,$81,$01,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$01,$03,$07
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$C0,$C0,$E0,$F0
        .byte   $00,$00,$00,$30,$30,$68,$4C,$DE,$07,$0F,$0F,$37,$37,$7A,$7C,$FE
        .byte   $00,$00,$00,$00,$00,$00,$00,$40,$FE,$FF,$7F,$7F,$7F,$7F,$3F,$4F
        .byte   $00,$00,$00,$00,$00,$00,$01,$03,$7F,$FF,$FE,$FE,$FE,$FE,$FD,$F3
        .byte   $00,$00,$00,$00,$00,$00,$00,$E0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$18,$64,$9C,$00,$00,$00,$00,$00,$00,$18,$60
        .byte   $01,$02,$05,$04,$09,$0B,$0F,$0B,$00,$01,$03,$03,$06,$04,$01,$07
        .byte   $11,$D1,$12,$7E,$C2,$02,$C1,$00,$E0,$E0,$E1,$81,$3D,$FD,$FE,$FF
        .byte   $3C,$7C,$7C,$78,$78,$70,$68,$C4,$C8,$88,$98,$90,$90,$80,$90,$38
        .byte   $16,$24,$21,$43,$46,$3F,$23,$40,$0F,$1F,$1E,$3C,$39,$00,$1C,$3F
        .byte   $78,$CC,$84,$04,$05,$89,$83,$0F,$87,$03,$03,$03,$82,$06,$1C,$F0
        .byte   $04,$02,$02,$E3,$B7,$57,$5D,$39,$F8,$FC,$FC,$1C,$48,$E8,$E2,$C6
        .byte   $03,$07,$07,$07,$04,$03,$00,$00,$00,$02,$00,$00,$03,$00,$00,$00
        .byte   $80,$E0,$C1,$87,$1F,$FB,$DB,$0B,$7F,$1F,$3E,$78,$E0,$04,$8C,$44
        .byte   $38,$77,$FF,$FF,$FE,$FE,$FD,$FD,$C7,$8F,$0F,$0F,$0F,$0F,$0E,$1E
        .byte   $F1,$62,$62,$44,$58,$E0,$80,$00,$0E,$9C,$9C,$B8,$A0,$00,$00,$00
        .byte   $0F,$1F,$1F,$7F,$BF,$BF,$5D,$3E,$00,$00,$00,$24,$41,$7F,$3E,$00
        .byte   $FA,$F4,$E8,$D0,$E0,$C0,$80,$00,$3C,$38,$70,$E0,$80,$00,$00,$00
        .byte   $3F,$7F,$FF,$FF,$FB,$FF,$FF,$FF,$C0,$83,$07,$07,$07,$03,$03,$03
        .byte   $F1,$62,$A2,$A4,$B8,$A0,$40,$80,$0E,$9C,$DC,$D8,$C0,$C0,$80,$00
        .byte   $0F,$07,$07,$07,$0F,$0F,$1F,$2F,$00,$00,$00,$00,$00,$00,$09,$10
        .byte   $FD,$FE,$FA,$FC,$F4,$F8,$E8,$F0,$06,$04,$0C,$08,$18,$10,$30,$60
        .byte   $2F,$17,$0F,$00,$00,$00,$00,$00,$1F,$0F,$00,$00,$00,$00,$00,$00
        .byte   $A0,$40,$80,$00,$00,$00,$00,$00,$C0,$80,$00,$00,$00,$00,$00,$00
        .byte   $1F,$20,$58,$5C,$BC,$BC,$BC,$98,$00,$1F,$27,$23,$43,$43,$43,$67
        .byte   $00,$E0,$1C,$E2,$79,$0C,$00,$00,$00,$00,$E0,$FC,$FE,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$80,$40,$40,$00,$00,$00,$00,$00,$00,$80,$80
        .byte   $40,$20,$1F,$00,$00,$00,$00,$00,$3F,$1F,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$FF,$01,$00,$00,$00,$00,$FF,$FF,$00,$00,$00,$00,$00,$00
        .byte   $40,$A0,$50,$10,$F0,$B0,$90,$E0,$80,$40,$E0,$E0,$00,$60,$60,$00
        .byte   $B0,$20,$00,$00,$00,$00,$00,$00,$60,$40,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$0F,$10,$2E,$5E,$00,$00,$00,$00,$00,$0F,$11,$21
        .byte   $00,$00,$00,$00,$00,$80,$40,$40,$00,$00,$00,$00,$00,$00,$80,$80
        .byte   $BE,$BC,$B8,$40,$20,$10,$08,$04,$41,$43,$47,$3F,$1F,$0F,$07,$03
        .byte   $20,$A0,$D0,$70,$68,$38,$14,$04,$C0,$C0,$E0,$E0,$F0,$F0,$F8,$F8
        .byte   $02,$01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$02,$02,$01,$01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00
        .byte   $06,$02,$12,$FA,$F9,$F9,$F9,$F9,$00,$0C,$1C,$FC,$FE,$FE,$7E,$7E
        .byte   $00,$00,$00,$00,$01,$07,$0B,$F7,$00,$00,$00,$00,$00,$01,$07,$0F
        .byte   $F1,$E1,$F2,$B2,$FA,$E6,$E4,$C8,$7E,$1E,$0C,$4C,$E4,$F8,$F8,$F0
        .byte   $03,$05,$0B,$17,$14,$20,$20,$3F,$00,$03,$07,$0F,$0F,$1F,$1F,$00
        .byte   $0F,$C6,$E3,$01,$00,$00,$00,$FF,$F7,$FB,$FC,$FE,$FF,$FF,$FF,$00
        .byte   $90,$30,$20,$E0,$90,$B0,$90,$E0,$E0,$C0,$C0,$00,$60,$60,$60,$00
        .byte   $00,$00,$00,$00,$00,$00,$10,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$03,$03,$03,$01,$01,$00,$00,$00,$03,$01,$01,$00,$00
        .byte   $68,$C8,$E4,$F4,$F4,$FA,$FA,$6A,$10,$30,$78,$F8,$F8,$FC,$FC,$9C
        .byte   $00,$00,$00,$01,$03,$07,$7F,$87,$00,$00,$00,$00,$01,$03,$07,$7B
        .byte   $F9,$FD,$ED,$F6,$F2,$E4,$E8,$E8,$06,$02,$72,$F8,$FC,$F8,$F0,$F0
        .byte   $01,$02,$05,$0B,$0A,$10,$10,$1F,$00,$01,$03,$07,$07,$0F,$0F,$00
        .byte   $E3,$F1,$80,$00,$00,$00,$FF,$00,$FD,$FE,$FF,$FF,$FF,$FF,$00,$00
        .byte   $D0,$90,$F0,$48,$58,$48,$F0,$00,$E0,$60,$00,$B0,$B0,$B0,$00,$00
        .byte   $00,$00,$00,$06,$05,$06,$07,$0F,$00,$00,$00,$00,$02,$03,$03,$07
        .byte   $00,$00,$00,$00,$80,$40,$20,$A0,$00,$00,$00,$00,$00,$80,$C0,$C0
        .byte   $1F,$3F,$7F,$0F,$03,$01,$01,$02,$07,$0F,$0F,$02,$00,$00,$00,$01
        .byte   $D0,$D0,$08,$C8,$38,$F8,$E8,$E8,$E0,$E0,$F0,$30,$C0,$E0,$F0,$F0
        .byte   $02,$03,$0C,$10,$27,$2C,$5C,$58,$01,$00,$03,$0F,$1F,$1F,$3F,$3F
        .byte   $EC,$CA,$76,$2A,$1C,$04,$08,$08,$F0,$34,$88,$DC,$E0,$F8,$F0,$F0
        .byte   $58,$50,$40,$20,$21,$1E,$00,$00,$3F,$3F,$3F,$1F,$1E,$00,$00,$00
        .byte   $10,$10,$20,$40,$80,$00,$00,$00,$E0,$E0,$C0,$80,$00,$00,$00,$00
        .byte   $04,$04,$CC,$7A,$2A,$32,$3C,$54,$F8,$F8,$30,$04,$1C,$0C,$00,$38
        .byte   $E8,$D0,$60,$00,$00,$00,$00,$00,$10,$60,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$78,$F8,$78,$70,$60,$00
        .byte   $00,$00,$01,$02,$02,$04,$04,$07,$00,$00,$00,$01,$01,$03,$03,$00
        .byte   $00,$01,$05,$0F,$27,$1F,$1F,$7F,$07,$1F,$3F,$7F,$7F,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$02,$03,$0F,$07,$00,$00,$03,$1F,$1F,$1F,$3F,$3F
        .byte   $08,$00,$00,$41,$00,$00,$00,$08,$08,$00,$00,$41,$00,$00,$00,$08
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$18,$39,$30,$00,$00,$00,$1F,$20,$58,$B6,$AF
        .byte   $06,$3F,$F3,$C8,$7F,$80,$00,$80,$00,$06,$3F,$77,$80,$40,$20,$20
        .byte   $E0,$78,$BE,$BF,$96,$63,$1A,$05,$00,$E0,$70,$76,$6F,$1E,$05,$03
        .byte   $00,$00,$00,$00,$80,$40,$E0,$E0,$00,$00,$00,$00,$00,$80,$C0,$C0
        .byte   $0C,$0C,$11,$0E,$00,$00,$00,$00,$9F,$9F,$8E,$40,$20,$1F,$00,$00
        .byte   $80,$80,$00,$00,$00,$00,$00,$00,$20,$20,$20,$40,$80,$00,$00,$00
        .byte   $05,$03,$02,$02,$01,$01,$01,$01,$03,$00,$01,$01,$00,$00,$00,$00
        .byte   $D0,$B0,$78,$F8,$F8,$E4,$0C,$7C,$A0,$60,$F0,$F0,$E0,$18,$F8,$F8
        .byte   $00,$00,$00,$00,$01,$18,$3F,$3F,$00,$00,$00,$1F,$20,$58,$B6,$AF
        .byte   $1F,$1F,$1F,$0E,$00,$00,$00,$00,$9F,$9F,$8E,$40,$20,$1F,$00,$00
        .byte   $3C,$42,$B1,$B1,$81,$81,$42,$3C,$00,$3C,$7E,$7E,$7E,$7E,$3C,$00
        .byte   $00,$03,$0F,$1C,$39,$E3,$47,$CF,$00,$00,$03,$0F,$1E,$3C,$F8,$73
        .byte   $FE,$FF,$3F,$FF,$FF,$FF,$FF,$83,$00,$FC,$C0,$00,$00,$00,$7E,$FC
        .byte   $00,$C0,$C0,$80,$00,$00,$80,$F0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $9C,$90,$83,$8F,$C0,$70,$FF,$FF,$FF,$FF,$FC,$7F,$3F,$8F,$00,$00
        .byte   $3F,$FF,$FF,$FF,$0F,$7F,$FF,$FF,$C0,$00,$00,$FE,$F0,$80,$00,$00
        .byte   $F0,$E0,$C0,$C0,$C0,$E0,$F0,$F8,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$03,$0F,$7C,$73,$61,$00,$00,$00,$00,$03,$0F,$1C,$3E
        .byte   $00,$07,$7F,$FF,$9F,$FF,$FF,$FF,$00,$00,$07,$78,$E0,$00,$00,$00
        .byte   $00,$F8,$FC,$F8,$F0,$F0,$F8,$FC,$00,$00,$F0,$00,$00,$00,$00,$00
        .byte   $61,$40,$40,$03,$41,$61,$78,$7F,$7F,$7F,$7F,$7C,$3E,$1F,$07,$00
        .byte   $FF,$00,$1F,$FF,$FF,$FF,$3F,$FF,$FF,$FF,$E0,$00,$00,$C0,$FF,$00
        .byte   $FF,$1F,$FE,$FC,$FC,$FE,$FF,$F8,$FC,$E0,$00,$00,$00,$00,$F0,$00
        .byte   $00,$00,$00,$15,$15,$00,$00,$00,$00,$00,$15,$15,$15,$15,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$15,$15,$15,$15,$00,$00
        .byte   $04,$1C,$1E,$3E,$3C,$38,$18,$10,$04,$1C,$1E,$3E,$3C,$38,$18,$10
        .byte   $08,$0C,$1C,$1C,$1C,$18,$08,$08,$08,$0C,$1C,$1C,$1C,$18,$08,$08
        .byte   $08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08,$08
        .byte   $08,$1C,$3E,$3E,$3E,$1C,$08,$00,$08,$1C,$3E,$3E,$3E,$1C,$08,$00
        .byte   $00,$08,$1C,$3E,$1C,$08,$00,$00,$00,$08,$1C,$3E,$1C,$08,$00,$00
        .byte   $00,$00,$08,$1C,$08,$00,$00,$00,$00,$00,$08,$1C,$08,$00,$00,$00
        .byte   $08,$08,$1C,$7F,$1C,$08,$08,$08,$08,$08,$1C,$7F,$1C,$08,$08,$08
        .byte   $34,$3C,$6A,$7A,$5A,$5A,$24,$34,$18,$18,$34,$24,$24,$24,$18,$18
        .byte   $07,$0F,$1A,$15,$3E,$2A,$7F,$87,$01,$05,$0D,$08,$00,$1C,$00,$7F
        .byte   $60,$70,$58,$A8,$7C,$54,$FE,$E1,$80,$A0,$B0,$10,$00,$38,$00,$FE
        .byte   $0C,$1B,$14,$14,$7F,$C2,$C2,$C2,$07,$0C,$08,$08,$00,$3F,$3F,$3F
        .byte   $B7,$B7,$87,$FF,$FF,$FF,$FF,$FC,$6F,$4F,$7F,$00,$00,$FF,$F0,$F3
        .byte   $82,$FF,$30,$38,$18,$18,$08,$08,$7F,$00,$3E,$3E,$1C,$1C,$08,$08
        .byte   $FF,$FF,$30,$38,$18,$18,$08,$08,$FF,$00,$3E,$3E,$1C,$1C,$08,$08
        .byte   $FF,$FF,$60,$70,$30,$30,$10,$10,$FF,$00,$7C,$7C,$38,$38,$10,$10
        .byte   $41,$FF,$60,$70,$30,$30,$10,$10,$FE,$00,$7C,$7C,$38,$38,$10,$10
        .byte   $0F,$11,$1F,$27,$40,$FF,$B7,$FF,$00,$0F,$00,$1F,$3F,$00,$5B,$00
        .byte   $00,$00,$00,$00,$00,$3C,$5A,$5A,$00,$00,$00,$00,$00,$00,$3C,$3C
        .byte   $1F,$2D,$2D,$4E,$5A,$DA,$B4,$FC,$00,$1E,$1E,$3C,$3C,$3C,$78,$00
        .byte   $FC,$B4,$B4,$BA,$5A,$5D,$2D,$2D,$00,$78,$78,$7C,$3C,$3E,$1E,$1E
        .byte   $00,$00,$00,$01,$02,$02,$05,$07,$00,$00,$00,$00,$01,$01,$03,$00
        .byte   $2D,$4D,$99,$32,$64,$C8,$90,$F0,$1E,$3E,$7E,$FC,$F8,$F0,$E0,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$7F,$0B,$01,$01,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FC,$B0,$80,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$84,$07,$74,$3F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$18,$10,$71,$F8,$C0
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$09,$01,$03,$07
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$80,$80,$80,$C0,$E4,$D0
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$77,$41,$0F,$2D,$05,$07,$03
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$37,$F4,$C0,$E0,$C4,$C4,$80
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$03,$09,$01,$01,$01,$01,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$A0,$80,$80,$40,$80,$80,$00,$80
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$07
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$E0
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$40,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$04,$01,$00,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$00,$40,$00,$00
        .byte   $FF,$FF,$01,$C0,$CD,$CD,$DF,$DF,$FF,$FF,$01,$C0,$CD,$CD,$DF,$DF
        .byte   $C1,$CC,$CD,$C1,$DF,$C1,$FF,$00,$C1,$CC,$CD,$C1,$DF,$C1,$FF,$00
        .byte   $FF,$FF,$80,$05,$B5,$B5,$FF,$FF,$FF,$FF,$80,$05,$B5,$B5,$FF,$FF
        .byte   $81,$35,$B5,$85,$BD,$81,$FF,$00,$81,$35,$B5,$85,$BD,$81,$FF,$00
        .byte   $7F,$FF,$C0,$B1,$81,$82,$80,$82,$7F,$C0,$BF,$C7,$C7,$FE,$C0,$DE
        .byte   $02,$82,$99,$80,$98,$C0,$60,$3F,$1E,$FE,$E3,$E3,$E3,$E3,$7F,$3F
        .byte   $FF,$FF,$D0,$FF,$00,$24,$24,$24,$FF,$50,$7F,$FF,$00,$36,$36,$36
        .byte   $00,$FD,$00,$40,$7F,$40,$7F,$C0,$00,$FD,$1D,$C0,$FF,$FF,$FF,$C0
        .byte   $FF,$FF,$0B,$FF,$00,$49,$49,$49,$FF,$0A,$FE,$FF,$00,$6D,$6D,$6D
        .byte   $00,$BF,$00,$02,$FE,$02,$FE,$03,$00,$BF,$B8,$03,$FF,$FF,$FF,$03
        .byte   $FE,$FF,$03,$99,$81,$41,$01,$41,$FE,$03,$FD,$E3,$E3,$7F,$03,$7B
        .byte   $40,$41,$B1,$01,$31,$03,$06,$FC,$78,$7F,$C7,$C7,$C7,$C7,$FE,$FC
        .byte   $52,$D2,$12,$E2,$0A,$02,$FC,$00,$76,$F6,$F6,$E6,$0E,$FE,$FC,$00
        .byte   $00,$BF,$00,$00,$FF,$00,$FF,$00,$00,$BF,$BF,$00,$FF,$FF,$FF,$00
        .byte   $EB,$0B,$08,$E7,$00,$36,$A4,$64,$ED,$EC,$0F,$E7,$E0,$36,$B6,$F6
        .byte   $00,$DF,$10,$00,$FF,$00,$FF,$00,$00,$DF,$DF,$00,$FF,$FF,$FF,$00
        .byte   $9F,$80,$9F,$C0,$FF,$DF,$9F,$FF,$9F,$80,$9F,$C0,$FF,$DF,$9F,$FF
        .byte   $C0,$80,$9F,$88,$9F,$88,$9F,$80,$C0,$80,$9F,$88,$9F,$88,$9F,$80
        .byte   $FD,$11,$FD,$03,$FF,$FE,$FC,$FF,$FD,$11,$FD,$03,$FF,$FE,$FC,$FF
        .byte   $03,$01,$FD,$01,$FD,$01,$FD,$01,$03,$01,$FD,$01,$FD,$01,$FD,$01
        .byte   $00,$FF,$00,$55,$FF,$FF,$FF,$FF,$00,$FF,$FF,$AA,$00,$00,$00,$00
        .byte   $FF,$AA,$00,$00,$AA,$FF,$FF,$00,$00,$55,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$FF,$00,$55,$FF,$FF,$FF,$FF,$00,$FF,$FF,$AA,$00,$00,$00,$00
        .byte   $FF,$AA,$00,$00,$AA,$FF,$FF,$00,$00,$55,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $D0,$D0,$D7,$D0,$F0,$D7,$F0,$F0,$B0,$B7,$B7,$B0,$F7,$B7,$F0,$90
        .byte   $D8,$C5,$C0,$D0,$D0,$C0,$E0,$7F,$B8,$BD,$BD,$A5,$A5,$A4,$DF,$7F
        .byte   $4A,$0A,$4A,$4A,$4A,$4A,$5F,$41,$6E,$0E,$6E,$6E,$6E,$4E,$5F,$5F
        .byte   $21,$C1,$29,$29,$01,$03,$06,$7C,$3F,$FF,$C3,$C3,$C3,$7F,$7E,$7C
        .byte   $7F,$E0,$D0,$D0,$C0,$C0,$C5,$D8,$7F,$DF,$A4,$A5,$A5,$BD,$BD,$B8
        .byte   $F7,$F0,$D0,$F7,$D0,$D0,$D7,$D0,$97,$F0,$B7,$F7,$B0,$B7,$B7,$B0
        .byte   $7C,$06,$03,$29,$29,$01,$C1,$21,$7C,$7E,$7F,$C3,$C3,$C3,$FF,$3F
        .byte   $41,$5F,$4A,$4A,$4A,$4A,$0A,$4A,$5F,$5F,$4E,$6E,$6E,$6E,$0E,$6E
        .byte   $40,$1F,$20,$51,$42,$44,$48,$51,$C0,$9F,$3F,$67,$66,$7C,$79,$73
        .byte   $53,$52,$52,$52,$52,$52,$52,$52,$77,$76,$76,$76,$76,$76,$76,$76
        .byte   $00,$FF,$00,$FF,$00,$00,$FF,$80,$00,$FF,$FF,$FF,$00,$FF,$FF,$80
        .byte   $21,$21,$D3,$20,$03,$04,$29,$EB,$3B,$3B,$DB,$E0,$E3,$07,$EE,$ED
        .byte   $01,$FB,$03,$FA,$00,$03,$BF,$03,$01,$FA,$FA,$FA,$01,$BE,$BE,$02
        .byte   $4B,$4B,$6F,$03,$FD,$FF,$00,$FF,$6E,$6E,$6E,$02,$FE,$00,$FF,$FF
        .byte   $80,$D7,$40,$57,$80,$50,$5F,$40,$80,$57,$D7,$57,$80,$DF,$DF,$C0
        .byte   $44,$44,$56,$40,$3F,$FF,$00,$FF,$D6,$D6,$D6,$C0,$FF,$00,$FF,$FF
        .byte   $00,$FF,$00,$FF,$00,$00,$FF,$01,$00,$FF,$FF,$FF,$00,$FF,$FF,$01
        .byte   $44,$44,$DB,$04,$C7,$20,$94,$D7,$DC,$DC,$DB,$07,$C7,$E0,$77,$B7
        .byte   $02,$F8,$04,$92,$42,$22,$12,$8A,$03,$F9,$FC,$E6,$66,$3E,$9E,$CE
        .byte   $CA,$4A,$4A,$4A,$4A,$4A,$4A,$4A,$EE,$6E,$6E,$6E,$6E,$6E,$6E,$6E
        .byte   $9F,$80,$9C,$80,$90,$81,$83,$B7,$9F,$80,$9D,$83,$97,$8F,$9F,$BF
        .byte   $9F,$8F,$8F,$80,$85,$80,$05,$E0,$BF,$BF,$BF,$B0,$B7,$B0,$07,$E0
        .byte   $FD,$01,$01,$01,$F9,$F9,$F9,$99,$FD,$01,$F9,$F9,$F9,$F9,$F9,$D9
        .byte   $98,$E7,$DC,$B0,$20,$66,$4F,$4F,$98,$E7,$DF,$BF,$3F,$79,$70,$70
        .byte   $9F,$80,$80,$81,$9E,$93,$93,$9E,$9F,$80,$9F,$9F,$9E,$9B,$93,$9F
        .byte   $1E,$E7,$7B,$1D,$0C,$0E,$06,$06,$1E,$E7,$FB,$FD,$FC,$FE,$FE,$FE
        .byte   $FD,$01,$BD,$C1,$ED,$71,$B9,$5D,$FD,$01,$BD,$C1,$ED,$71,$B9,$5D
        .byte   $69,$F1,$F1,$01,$A1,$01,$A0,$07,$69,$F1,$F1,$01,$E1,$01,$E0,$07
        .byte   $20,$3F,$E0,$40,$4C,$4C,$40,$40,$3F,$40,$9F,$BF,$B1,$B1,$B1,$BF
        .byte   $40,$41,$40,$AE,$00,$22,$22,$00,$BF,$BF,$BE,$FE,$00,$8A,$8A,$00
        .byte   $10,$E0,$16,$00,$10,$10,$16,$60,$F6,$10,$F0,$F0,$F6,$F0,$F6,$E0
        .byte   $80,$3F,$40,$40,$47,$48,$49,$4A,$80,$3F,$5F,$60,$67,$6B,$6D,$6E
        .byte   $08,$07,$68,$00,$08,$08,$68,$06,$6F,$08,$0F,$0F,$6F,$0F,$6F,$07
        .byte   $01,$FC,$02,$02,$E2,$12,$92,$52,$01,$FC,$FA,$06,$E6,$D6,$B6,$76
        .byte   $04,$FC,$07,$02,$62,$62,$02,$02,$FC,$02,$F9,$FD,$8D,$8D,$8D,$FD
        .byte   $02,$82,$02,$75,$00,$44,$44,$00,$FD,$FD,$7D,$7F,$00,$51,$51,$00
        .byte   $08,$05,$7D,$40,$40,$40,$FF,$FF,$F8,$FD,$FD,$C0,$DF,$DF,$FF,$00
        .byte   $00,$FF,$00,$10,$10,$10,$10,$17,$FF,$FF,$00,$F4,$F7,$F4,$F7,$F7
        .byte   $08,$F0,$00,$00,$40,$40,$FF,$FF,$0F,$FF,$FD,$19,$DF,$DF,$FF,$00
        .byte   $00,$FF,$00,$02,$02,$02,$3E,$E0,$FF,$FF,$00,$7E,$7E,$7E,$FE,$E0
        .byte   $52,$50,$52,$52,$52,$02,$77,$E7,$76,$70,$76,$76,$76,$06,$77,$88
        .byte   $C8,$77,$00,$56,$02,$52,$52,$52,$AF,$77,$00,$76,$06,$76,$76,$76
        .byte   $0B,$EB,$2B,$0B,$EB,$2B,$F3,$FF,$0D,$ED,$ED,$0D,$ED,$ED,$FD,$01
        .byte   $03,$F3,$0B,$2B,$0B,$EB,$2B,$0B,$FD,$FD,$0D,$ED,$0D,$ED,$ED,$0D
        .byte   $08,$05,$7D,$40,$40,$40,$C0,$00,$F8,$FD,$FD,$C0,$DF,$DF,$DF,$1F
        .byte   $1F,$10,$10,$10,$10,$10,$10,$17,$FF,$F0,$F7,$F4,$F7,$F4,$F7,$F7
        .byte   $08,$F0,$00,$00,$40,$40,$5F,$40,$0F,$FF,$FD,$19,$DF,$DF,$DF,$C0
        .byte   $C2,$02,$02,$02,$02,$02,$3E,$E0,$DE,$1E,$7E,$7E,$7E,$7E,$FE,$E0
        .byte   $D0,$D7,$D4,$D0,$D7,$D4,$EF,$FF,$B0,$B7,$B7,$B0,$B7,$B7,$9F,$80
        .byte   $C0,$CF,$D0,$D4,$D0,$D7,$D4,$D0,$BF,$BF,$B0,$B7,$B0,$B7,$B7,$B0
        .byte   $4A,$0A,$4A,$4A,$4A,$40,$EE,$E7,$6E,$0E,$6E,$6E,$6E,$60,$EE,$11
        .byte   $13,$EE,$00,$6A,$40,$4A,$4A,$4A,$F5,$EE,$00,$6E,$60,$6E,$6E,$6E
        .byte   $65,$00,$85,$80,$85,$80,$9F,$AE,$67,$00,$B7,$B0,$B7,$B0,$BF,$AF
        .byte   $86,$83,$91,$80,$9C,$80,$9F,$80,$86,$83,$91,$80,$9C,$80,$9F,$80
        .byte   $46,$60,$60,$30,$3C,$1F,$C7,$30,$79,$7F,$7F,$3F,$3F,$1F,$C7,$B0
        .byte   $39,$19,$19,$F9,$01,$01,$FD,$01,$39,$D9,$19,$F9,$01,$01,$FD,$01
        .byte   $06,$0E,$0E,$1C,$7C,$F8,$E3,$0F,$FE,$FE,$FE,$FC,$FC,$F8,$E3,$0F
        .byte   $98,$98,$9F,$9F,$80,$80,$9F,$80,$9E,$98,$9F,$9F,$80,$80,$9F,$80
        .byte   $A7,$00,$A1,$01,$A1,$01,$F1,$F1,$E7,$00,$E1,$01,$E1,$01,$F1,$F1
        .byte   $E1,$C1,$8D,$01,$3D,$01,$FD,$01,$E1,$C1,$8D,$01,$3D,$01,$FD,$01
        .byte   $00,$22,$22,$00,$AE,$40,$41,$40,$00,$8A,$8A,$00,$FE,$BE,$BF,$BF
        .byte   $40,$4C,$4C,$40,$00,$80,$7F,$3F,$BF,$B1,$B1,$B1,$FF,$FF,$7F,$3F
        .byte   $4A,$49,$48,$47,$40,$40,$3F,$80,$6E,$6D,$6B,$67,$60,$5F,$3F,$80
        .byte   $60,$10,$10,$16,$00,$10,$F0,$F6,$E0,$F6,$F0,$F0,$F0,$F6,$F0,$F6
        .byte   $52,$92,$12,$E2,$02,$02,$FC,$01,$76,$B6,$D6,$E6,$06,$FA,$FC,$01
        .byte   $06,$08,$08,$68,$00,$08,$0F,$6F,$07,$6F,$0F,$0F,$0F,$6F,$0F,$6F
        .byte   $00,$44,$44,$00,$75,$02,$82,$02,$00,$51,$51,$00,$7F,$7D,$FD,$FD
        .byte   $02,$62,$62,$02,$00,$01,$FE,$FC,$FD,$8D,$8D,$8D,$FF,$FF,$FE,$FC
        .byte   $0B,$07,$7F,$43,$43,$43,$FF,$FF,$FA,$FE,$FE,$C2,$DE,$DE,$FE,$00
        .byte   $01,$FD,$03,$13,$13,$13,$13,$17,$FE,$FE,$02,$F6,$F6,$F6,$F6,$F6
        .byte   $48,$50,$40,$40,$40,$40,$7F,$FF,$CF,$DF,$DD,$D9,$DF,$DF,$FF,$00
        .byte   $00,$3F,$40,$42,$42,$42,$5E,$40,$FF,$FF,$C0,$DE,$DE,$DE,$DE,$C0
        .byte   $52,$52,$52,$52,$52,$52,$52,$53,$76,$76,$76,$76,$76,$76,$76,$77
        .byte   $51,$48,$44,$52,$41,$20,$9F,$00,$73,$79,$7C,$66,$67,$3F,$9F,$C0
        .byte   $2B,$E9,$04,$03,$20,$D3,$21,$21,$ED,$EE,$07,$E3,$E0,$DB,$3B,$3B
        .byte   $80,$FF,$00,$00,$FF,$00,$FF,$00,$80,$FF,$FF,$00,$FF,$FF,$FF,$00
        .byte   $FF,$FF,$01,$FD,$03,$6F,$4B,$4B,$FF,$00,$FE,$FE,$02,$6E,$6E,$6E
        .byte   $03,$BF,$03,$00,$FA,$03,$FB,$01,$02,$BE,$BE,$01,$FA,$FA,$FA,$01
        .byte   $FF,$FF,$00,$3F,$40,$56,$44,$44,$FF,$00,$FF,$FF,$C0,$D6,$D6,$D6
        .byte   $40,$5F,$50,$80,$57,$C0,$57,$80,$C0,$DF,$DF,$80,$57,$57,$D7,$80
        .byte   $D4,$97,$20,$C4,$04,$DB,$44,$44,$B7,$77,$E0,$C7,$07,$DB,$DC,$DC
        .byte   $01,$FF,$00,$00,$FF,$00,$FF,$00,$01,$FF,$FF,$00,$FF,$FF,$FF,$00
        .byte   $4A,$4A,$4A,$4A,$4A,$4A,$4A,$CA,$6E,$6E,$6E,$6E,$6E,$6E,$6E,$EE
        .byte   $8A,$12,$22,$52,$82,$04,$F9,$00,$CE,$9E,$3E,$66,$E6,$FC,$F9,$03
        .byte   $9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80
        .byte   $9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80
        .byte   $FD,$41,$FD,$41,$FD,$41,$FD,$41,$FD,$41,$FD,$41,$FD,$41,$FD,$41
        .byte   $FD,$01,$FD,$01,$FD,$01,$FD,$01,$FD,$01,$FD,$01,$FD,$01,$FD,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80,$9F,$80
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FD,$01,$FD,$01,$FD,$01,$FD,$01,$FD,$01,$FD,$01,$FD,$01,$FD,$01
        .byte   $FF,$FF,$E3,$E3,$E3,$E3,$FF,$FF,$FF,$FF,$FB,$E3,$FB,$E3,$FF,$FF
        .byte   $00,$F7,$30,$B7,$B7,$B7,$B7,$80,$00,$F7,$30,$B7,$B7,$B7,$B7,$80
        .byte   $DD,$C1,$DD,$DD,$DD,$DD,$DD,$DD,$DD,$C1,$DD,$DD,$DD,$DD,$DD,$DD
        .byte   $1C,$FD,$00,$FF,$FF,$F3,$F3,$1F,$1C,$FD,$00,$FF,$FF,$FB,$F3,$1F
        .byte   $00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00,$00,$00,$00,$00,$FF
        .byte   $00,$F7,$30,$B7,$B7,$B7,$B7,$80,$00,$F7,$30,$B7,$B7,$B7,$B7,$80
        .byte   $00,$00,$00,$00,$00,$00,$00,$DD,$00,$00,$00,$00,$00,$00,$00,$DD
        .byte   $1C,$FD,$00,$FF,$FF,$F3,$F3,$1F,$1C,$FD,$00,$FF,$FF,$FB,$F3,$1F
        .byte   $0B,$07,$7F,$43,$43,$43,$C3,$03,$FA,$FE,$FE,$C2,$DE,$DE,$DE,$1E
        .byte   $1F,$13,$13,$13,$13,$13,$13,$17,$FE,$F2,$F6,$F6,$F6,$F6,$F6,$F6
        .byte   $48,$50,$40,$40,$40,$40,$5F,$40,$CF,$DF,$DD,$D9,$DF,$DF,$DF,$C0
        .byte   $42,$42,$42,$42,$42,$42,$5E,$40,$DE,$DE,$DE,$DE,$DE,$DE,$DE,$C0
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
        .byte   $00,$FF,$FF,$00,$00,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$FF,$FF,$00
        .byte   $00,$FF,$FF,$00,$00,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$FF,$FF,$00
        .byte   $00,$FF,$FF,$00,$00,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$FF,$FF,$00
        .byte   $00,$FF,$FF,$00,$00,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$FF,$FF,$00
        .byte   $FF,$FF,$FF,$FF,$80,$B1,$A2,$A2,$00,$00,$FF,$00,$7F,$46,$55,$55
        .byte   $A0,$A0,$A0,$A0,$A0,$80,$83,$FC,$56,$57,$57,$57,$57,$47,$7F,$FC
        .byte   $FF,$FF,$FF,$FF,$01,$F9,$01,$01,$01,$01,$FF,$01,$FF,$07,$FB,$FB
        .byte   $01,$01,$01,$01,$01,$01,$C1,$3F,$07,$FF,$FF,$E3,$FF,$E3,$FF,$3F
        .byte   $00,$07,$08,$4B,$4B,$4A,$4B,$0A,$FF,$F8,$F0,$93,$93,$92,$93,$92
        .byte   $0B,$0B,$0B,$0B,$0B,$4B,$4B,$4A,$F3,$F3,$F3,$F3,$F3,$93,$93,$92
        .byte   $00,$FF,$00,$FF,$7F,$3C,$7B,$37,$FF,$00,$00,$FF,$7F,$3C,$7B,$37
        .byte   $77,$77,$77,$76,$79,$64,$1F,$00,$77,$77,$77,$76,$79,$64,$1F,$00
        .byte   $00,$FF,$00,$FF,$FE,$3F,$DF,$EF,$FF,$00,$00,$FF,$FE,$3F,$DF,$EF
        .byte   $E9,$E7,$8F,$6F,$DF,$3F,$F6,$00,$E9,$E7,$8F,$6F,$DF,$3F,$F6,$00
        .byte   $00,$F0,$08,$E8,$28,$A8,$A8,$E8,$FF,$07,$03,$E3,$23,$A1,$A1,$E1
        .byte   $E8,$E8,$E8,$E8,$E8,$E8,$E8,$28,$E1,$E3,$E3,$E3,$E3,$E1,$E1,$21
        .byte   $4B,$0B,$08,$07,$00,$00,$02,$44,$93,$93,$F0,$F0,$F8,$FF,$FC,$99
        .byte   $48,$48,$48,$08,$08,$04,$02,$00,$93,$93,$93,$93,$F3,$F9,$FC,$FF
        .byte   $7F,$FF,$00,$FF,$00,$00,$00,$28,$7F,$FF,$00,$00,$00,$FF,$FF,$A8
        .byte   $28,$00,$00,$2A,$2A,$00,$00,$00,$A8,$FF,$FF,$AA,$AA,$FF,$FF,$FF
        .byte   $F6,$FF,$00,$FF,$00,$00,$20,$00,$F6,$FF,$00,$00,$00,$FF,$CF,$78
        .byte   $07,$0F,$0C,$0F,$07,$00,$20,$00,$70,$E0,$E0,$60,$70,$F8,$CF,$FF
        .byte   $E8,$E8,$08,$F0,$00,$00,$20,$10,$E1,$E3,$03,$03,$07,$FF,$CF,$E7
        .byte   $08,$88,$08,$88,$08,$10,$20,$00,$73,$33,$33,$33,$73,$E7,$CF,$FF
        .byte   $D7,$F4,$D4,$D4,$D4,$F4,$D7,$D0,$30,$F3,$33,$33,$33,$F3,$37,$30
        .byte   $D7,$F4,$D4,$D4,$D4,$F4,$D7,$D0,$30,$F3,$33,$33,$33,$F3,$37,$30
        .byte   $ED,$0F,$0D,$0D,$0D,$0F,$ED,$0D,$03,$EF,$E3,$E3,$E3,$EF,$E3,$03
        .byte   $ED,$0F,$0D,$0D,$0D,$0F,$ED,$0D,$03,$EF,$E3,$E3,$E3,$EF,$E3,$03
        .byte   $0C,$00,$3F,$39,$3A,$B7,$B7,$2F,$E1,$80,$BF,$B9,$3A,$37,$37,$2F
        .byte   $3F,$00,$0C,$00,$00,$57,$00,$00,$BF,$80,$E1,$FF,$00,$00,$57,$00
        .byte   $30,$00,$FC,$F4,$EC,$6D,$5D,$9C,$87,$01,$FD,$F5,$EC,$6C,$5C,$9C
        .byte   $FC,$00,$30,$00,$00,$EA,$00,$00,$FD,$01,$87,$FF,$00,$00,$EA,$00
        .byte   $00,$33,$00,$33,$00,$33,$00,$33,$00,$55,$00,$55,$00,$55,$00,$55
        .byte   $00,$DD,$DD,$D9,$D1,$DD,$DD,$DD,$00,$E2,$E2,$E2,$E2,$E2,$E2,$E2
        .byte   $03,$00,$03,$00,$5D,$5D,$5D,$5D,$04,$00,$04,$00,$62,$62,$62,$62
        .byte   $00,$91,$90,$90,$91,$80,$87,$00,$00,$6E,$60,$60,$6E,$60,$04,$00
        .byte   $20,$00,$20,$00,$56,$56,$56,$56,$E0,$00,$E0,$00,$FE,$FE,$FE,$FE
        .byte   $00,$11,$01,$01,$11,$01,$21,$00,$00,$FF,$0F,$0F,$FF,$07,$E1,$00
        .byte   $00,$66,$00,$66,$00,$66,$00,$66,$00,$AA,$00,$AA,$00,$AA,$00,$AA
        .byte   $00,$2E,$2E,$2E,$0E,$2E,$2E,$2E,$00,$FE,$FE,$CE,$CE,$FE,$FE,$FE
        .byte   $00,$C1,$DD,$DD,$DD,$DC,$00,$0A,$00,$E0,$E2,$E2,$E2,$E2,$00,$16
        .byte   $00,$DD,$DD,$D9,$D1,$DD,$DD,$DD,$00,$E2,$E2,$E2,$E2,$E2,$E2,$E2
        .byte   $00,$91,$91,$91,$80,$34,$B4,$B4,$00,$6E,$6E,$6E,$00,$0B,$CB,$CB
        .byte   $00,$91,$90,$90,$91,$80,$87,$00,$00,$6E,$60,$60,$6E,$60,$04,$00
        .byte   $00,$11,$11,$11,$01,$A8,$AE,$AE,$00,$FF,$FF,$FF,$03,$F8,$FE,$FE
        .byte   $00,$11,$01,$01,$11,$01,$41,$00,$00,$FF,$0F,$0F,$FF,$07,$C1,$00
        .byte   $00,$06,$2E,$2E,$2E,$2E,$00,$28,$00,$86,$FE,$FE,$FE,$FE,$00,$58
        .byte   $00,$2E,$2E,$2E,$0E,$2E,$2E,$2E,$00,$FE,$FE,$CE,$CE,$FE,$FE,$FE
        .byte   $FF,$FF,$FF,$FF,$00,$3C,$38,$20,$00,$00,$FF,$00,$FF,$C3,$C3,$DB
        .byte   $20,$20,$20,$20,$20,$20,$20,$20,$DB,$DB,$DB,$DB,$DB,$DB,$DB,$DB
        .byte   $FF,$FF,$FF,$FF,$00,$3C,$38,$20,$00,$00,$FF,$00,$FF,$C3,$C3,$DB
        .byte   $20,$20,$20,$20,$20,$20,$20,$20,$DB,$DB,$DB,$DB,$DB,$DB,$DB,$DB
        .byte   $00,$61,$31,$19,$09,$01,$FE,$03,$00,$63,$33,$1B,$0B,$03,$FD,$FC
        .byte   $02,$FE,$02,$1E,$0A,$12,$22,$42,$FC,$FD,$01,$1D,$39,$71,$E1,$C1
        .byte   $00,$C6,$CC,$D8,$D0,$C0,$5F,$40,$00,$C6,$CC,$D8,$D0,$C0,$DF,$5F
        .byte   $40,$5F,$40,$58,$50,$48,$45,$42,$5F,$DF,$C0,$D8,$DC,$CE,$C7,$C3
        .byte   $FF,$FF,$C0,$C7,$C8,$D7,$D7,$D7,$00,$00,$3F,$38,$30,$27,$27,$27
        .byte   $C8,$C7,$C0,$C0,$80,$B0,$B0,$A1,$30,$38,$3F,$3F,$07,$06,$06,$0C
        .byte   $FF,$FF,$00,$18,$80,$58,$40,$40,$00,$00,$FF,$E3,$63,$23,$23,$3C
        .byte   $83,$0C,$13,$2F,$5B,$B9,$BA,$79,$70,$E0,$C3,$8F,$1B,$39,$3A,$79
        .byte   $FF,$FF,$00,$C0,$00,$00,$00,$00,$00,$00,$FF,$18,$1F,$F8,$FF,$0E
        .byte   $F0,$0C,$F2,$FD,$DE,$DB,$BB,$B7,$03,$01,$F0,$FC,$DE,$DB,$BB,$B7
        .byte   $FE,$FC,$00,$00,$00,$00,$00,$00,$00,$00,$FC,$0C,$FC,$0C,$FC,$0C
        .byte   $00,$00,$00,$00,$80,$40,$40,$A0,$FC,$8C,$FC,$7C,$30,$16,$16,$8A
        .byte   $DD,$DD,$DD,$D9,$D1,$DD,$DD,$DD,$E2,$E2,$E2,$E2,$E2,$E2,$E2,$E2
        .byte   $00,$33,$00,$33,$00,$33,$00,$33,$00,$55,$00,$55,$00,$55,$00,$55
        .byte   $00,$87,$80,$91,$91,$91,$91,$91,$00,$04,$60,$6E,$6E,$6E,$6E,$6E
        .byte   $00,$5D,$5D,$5D,$5D,$00,$03,$00,$00,$62,$62,$62,$62,$00,$04,$00
        .byte   $00,$21,$01,$11,$11,$11,$11,$11,$00,$E1,$07,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$56,$56,$56,$56,$00,$20,$00,$00,$FE,$FE,$FE,$FE,$00,$E0,$00
        .byte   $2E,$2E,$2E,$2E,$0E,$2E,$2E,$2E,$FE,$FE,$FE,$CE,$CE,$FE,$FE,$FE
        .byte   $00,$66,$00,$66,$00,$66,$00,$66,$00,$AA,$00,$AA,$00,$AA,$00,$AA
        .byte   $00,$33,$00,$33,$00,$33,$00,$33,$00,$55,$00,$55,$00,$55,$00,$55
        .byte   $00,$33,$00,$33,$00,$33,$00,$33,$00,$55,$00,$55,$00,$55,$00,$55
        .byte   $03,$00,$03,$00,$03,$00,$03,$00,$04,$00,$04,$00,$04,$00,$04,$00
        .byte   $03,$00,$03,$00,$03,$00,$03,$00,$04,$00,$04,$00,$04,$00,$04,$00
        .byte   $20,$00,$20,$00,$20,$00,$20,$00,$E0,$00,$E0,$00,$E0,$00,$E0,$00
        .byte   $20,$00,$20,$00,$20,$00,$20,$00,$E0,$00,$E0,$00,$E0,$00,$E0,$00
        .byte   $00,$66,$00,$66,$00,$66,$00,$66,$00,$AA,$00,$AA,$00,$AA,$00,$AA
        .byte   $00,$66,$00,$66,$00,$66,$00,$66,$00,$AA,$00,$AA,$00,$AA,$00,$AA
        .byte   $20,$20,$20,$20,$20,$20,$20,$20,$DB,$DB,$DB,$DB,$DB,$DB,$DB,$DB
        .byte   $20,$20,$00,$00,$00,$00,$FF,$FF,$DB,$C3,$C3,$FF,$FF,$00,$FF,$FF
        .byte   $20,$20,$20,$20,$20,$20,$20,$20,$DB,$DB,$DB,$DB,$DB,$DB,$DB,$DB
        .byte   $20,$20,$00,$00,$00,$00,$FF,$FF,$DB,$C3,$C3,$FF,$FF,$00,$FF,$FF
        .byte   $82,$02,$42,$22,$12,$0A,$FE,$03,$81,$61,$71,$39,$1D,$0D,$01,$FC
        .byte   $02,$FE,$02,$1E,$0A,$12,$22,$42,$FC,$FD,$01,$1D,$39,$71,$E1,$C1
        .byte   $40,$41,$42,$44,$48,$40,$5F,$40,$C3,$C7,$CE,$DC,$D8,$C0,$C0,$5F
        .byte   $40,$5F,$40,$58,$50,$48,$45,$42,$5F,$DF,$C0,$D8,$DC,$CE,$C7,$C3
        .byte   $A1,$A1,$A1,$A1,$A1,$B0,$B0,$80,$0C,$0C,$0C,$0C,$0C,$06,$06,$07
        .byte   $C0,$C0,$D8,$C0,$C3,$C0,$C0,$80,$3F,$24,$24,$24,$24,$24,$3F,$00
        .byte   $7B,$7F,$40,$72,$7C,$BD,$BB,$5B,$7B,$7F,$40,$72,$7C,$3D,$3B,$1B
        .byte   $2F,$13,$0C,$03,$00,$00,$00,$00,$8F,$C3,$E0,$F0,$FC,$FF,$FF,$00
        .byte   $77,$6F,$00,$DF,$DF,$3F,$8F,$72,$77,$6F,$00,$DF,$DF,$3F,$8F,$72
        .byte   $7D,$F2,$0C,$F0,$01,$00,$00,$00,$7C,$F0,$01,$03,$0E,$FE,$FF,$00
        .byte   $A0,$A0,$A0,$A0,$A0,$40,$40,$80,$8A,$8A,$8A,$8A,$8A,$16,$16,$30
        .byte   $00,$20,$00,$00,$20,$00,$00,$00,$7C,$CC,$CC,$FC,$4C,$4C,$FC,$00
        .byte   $00,$3F,$7F,$60,$6F,$6F,$6F,$6F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F,$00,$00,$00,$00,$40,$40,$40,$40
        .byte   $40,$7F,$7F,$7F,$7F,$7F,$7F,$40,$40,$40,$40,$40,$40,$40,$40,$7F
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$00,$00,$00,$01,$02,$04,$08,$08
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$FF,$7F,$7F,$7F,$7F,$7F,$00,$3F,$C0,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7D,$FB,$77,$7F,$5F,$3F,$7F,$01,$02,$C4,$28,$00,$28,$44,$84
        .byte   $00,$FC,$FE,$06,$F6,$F6,$76,$76,$00,$00,$00,$00,$00,$00,$00,$80
        .byte   $16,$76,$76,$76,$76,$76,$76,$76,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F,$00,$00,$00,$07,$00,$00,$00,$00
        .byte   $00,$5F,$5F,$3F,$3F,$3F,$3F,$3F,$20,$20,$20,$40,$40,$40,$40,$40
        .byte   $00,$3F,$3F,$DF,$7F,$5F,$6F,$6F,$40,$40,$40,$A0,$58,$27,$10,$10
        .byte   $40,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$40,$40,$40,$40,$40,$40,$40,$40
        .byte   $40,$7D,$7B,$77,$6F,$DF,$7F,$7F,$41,$42,$44,$48,$50,$E0,$38,$C7
        .byte   $0A,$7F,$7F,$77,$6F,$5F,$3F,$7F,$0B,$0A,$0C,$08,$1E,$24,$44,$84
        .byte   $00,$7F,$7F,$7F,$7F,$7F,$7F,$FF,$00,$00,$00,$00,$00,$00,$00,$80
        .byte   $CA,$FE,$FF,$7F,$FF,$FF,$FF,$FF,$CB,$8B,$A5,$00,$D3,$D3,$92,$DB
        .byte   $00,$FF,$FF,$7E,$FE,$7E,$7D,$7D,$00,$EA,$CA,$25,$E5,$01,$03,$03
        .byte   $A9,$FF,$7F,$7F,$7F,$7F,$7F,$7F,$A9,$A8,$2C,$80,$F7,$D5,$F5,$C7
        .byte   $00,$FF,$FF,$7F,$FF,$7F,$FF,$FF,$80,$EE,$C4,$24,$E4,$00,$C1,$9A
        .byte   $40,$FF,$FF,$7F,$7F,$7F,$7F,$7F,$40,$80,$80,$00,$77,$52,$62,$52
        .byte   $00,$FF,$FF,$FF,$FF,$7F,$FF,$7F,$00,$D1,$DB,$95,$D1,$00,$CE,$31
        .byte   $16,$76,$76,$76,$76,$76,$76,$76,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $16,$76,$76,$76,$76,$76,$76,$76,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7E,$7D,$7D,$7B,$7B,$7B,$7B,$00,$01,$02,$02,$04,$04,$04,$04
        .byte   $00,$7B,$7C,$7D,$7A,$77,$6F,$6F,$04,$04,$03,$02,$05,$08,$10,$10
        .byte   $40,$7F,$7F,$7F,$7F,$7F,$7F,$78,$80,$40,$40,$40,$40,$40,$40,$47
        .byte   $40,$7F,$7F,$7F,$7F,$7F,$40,$7F,$78,$80,$40,$40,$40,$80,$7F,$40
        .byte   $00,$5F,$6F,$6F,$77,$77,$77,$07,$C0,$20,$10,$10,$08,$08,$08,$F8
        .byte   $00,$77,$6F,$6F,$5F,$3F,$7F,$7F,$0F,$08,$10,$10,$20,$C0,$00,$0C
        .byte   $10,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$10,$10,$10,$10,$10,$10,$08,$08
        .byte   $04,$3D,$5B,$67,$67,$5B,$3D,$7D,$05,$C2,$25,$18,$18,$24,$42,$8A
        .byte   $00,$7D,$7B,$77,$6F,$5F,$3F,$7F,$01,$02,$04,$08,$10,$20,$40,$80
        .byte   $00,$7F,$7F,$FF,$7F,$7F,$7F,$FF,$00,$00,$00,$C0,$3F,$00,$00,$A9
        .byte   $02,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$02,$02,$02,$02,$02,$02,$04,$04
        .byte   $08,$7F,$7F,$FF,$7F,$7F,$7F,$7F,$08,$10,$20,$C0,$00,$00,$00,$40
        .byte   $16,$76,$76,$76,$76,$76,$76,$76,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $16,$76,$76,$76,$76,$76,$76,$76,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$60,$7F,$3F,$00,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$79,$79,$76,$6F,$5F,$3F,$7F,$09,$06,$06,$09,$10,$20,$40,$80
        .byte   $00,$7F,$7F,$FF,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $40,$7F,$7F,$7F,$7F,$47,$78,$7F,$40,$40,$40,$40,$80,$78,$47,$40
        .byte   $40,$7F,$7F,$FF,$00,$FF,$FF,$00,$40,$40,$00,$00,$00,$00,$00,$00
        .byte   $78,$7F,$7F,$7F,$7F,$78,$07,$7F,$78,$07,$00,$00,$00,$07,$F8,$00
        .byte   $00,$7F,$7F,$FF,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$F7,$6F,$5F,$3F,$7F,$7F,$7F,$05,$89,$78,$27,$C0,$00,$00,$00
        .byte   $00,$7F,$7F,$FF,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $02,$FF,$7F,$FF,$7F,$7F,$7F,$7F,$02,$D9,$00,$80,$78,$07,$00,$00
        .byte   $00,$7F,$7F,$FF,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $31,$FF,$7F,$7F,$7F,$FF,$7F,$7F,$31,$CE,$00,$00,$00,$80,$78,$00
        .byte   $00,$7F,$7F,$FF,$00,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $16,$76,$76,$76,$76,$76,$76,$76,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $16,$76,$76,$F6,$06,$FE,$FC,$00,$00,$00,$00,$00,$00,$00,$00,$00

; =============================================================================
; screen_conn_flags — per-screen room connectivity ($B400)
; Read by get_screen_boundary; masked by scroll_left/right_mask_table
; per transition_type to decide legal room exits.
; =============================================================================
screen_conn_flags:
        .byte   $40,$40,$40,$40,$40,$40,$40,$44 ; screens $00-$07
        .byte   $40,$40,$40,$40,$40,$40,$40,$22 ; screens $08-$0F
        .byte   $20,$00,$00,$00,$00,$00,$00,$FF ; screens $10-$17
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; screens $18-$1F
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; screens $20-$27
        .byte   $FF,$FF,$FF,$FF ; screens $28-$2F

; ─── screen_overlay_base — per-screen offset into overlay sets below ($B42C) ───
screen_overlay_base:
        .byte   $00,$5A,$5A,$36,$36,$36,$00,$12
        .byte   $36,$36,$36,$36,$36,$36,$36,$24
        .byte   $12,$48,$00,$12,$6C,$7E,$FF,$FF
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
        .byte   $90,$02,$90,$02,$90,$02,$94,$02,$93,$02,$9F,$03
        .byte   $0F,$25,$25,$0F,$15,$28
; ─── set 1 (base $12) ───
        .byte   $90,$04,$91,$04,$92,$04,$9E,$04,$93,$04,$9F,$03
        .byte   $0F,$11,$3C,$0F,$15,$27
; ─── set 2 (base $24) ───
        .byte   $91,$03,$92,$03,$93,$03,$94,$03,$95,$03,$9F,$03
        .byte   $0F,$26,$30,$0F,$14,$34
; ─── set 3 (base $36) ───
        .byte   $94,$02,$94,$02,$94,$02,$94,$02,$94,$02,$9F,$03
        .byte   $0F,$11,$30,$37,$27,$07
; ─── set 4 (base $48) ───
        .byte   $90,$07,$91,$07,$92,$07,$93,$07,$94,$07,$95,$07
        .byte   $0F,$30,$28,$0F,$28,$15
; ─── set 5 (base $5A) ───
        .byte   $90,$02,$91,$02,$92,$02,$9E,$04,$9C,$01,$96,$03
        .byte   $0F,$15,$27,$0F,$11,$3C
; ─── set 6 (base $6C) ───
        .byte   $AA,$04,$AB,$04,$AC,$04,$AD,$04,$AE,$04,$AF,$04
        .byte   $30,$32,$22,$19,$09,$21
; ─── set 7 (base $7E) ───
        .byte   $94,$05,$95,$05,$96,$05,$94,$06,$95,$06,$95,$04
        .byte   $0F,$0F,$0F,$0F,$0F,$0F
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
        .byte   $01,$01,$03,$03,$04,$05,$05,$08,$08,$09,$0A,$0A,$0B,$0C,$0D,$0E ; $00+
        .byte   $0F,$10,$11,$12,$13,$14,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $10+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+
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
        .byte   $50,$90,$68,$80,$80,$80,$98,$00,$60,$10,$10,$60,$80,$80,$80,$80 ; $00+
        .byte   $80,$80,$80,$80,$F8,$E8,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $10+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+
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
        .byte   $BC,$9C,$B8,$80,$80,$80,$A8,$08,$70,$90,$90,$08,$08,$80,$80,$80 ; $00+
        .byte   $80,$80,$80,$80,$A4,$A4,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $10+
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+
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
        .byte   $50,$50,$46,$14,$14,$14,$46,$25 ; $00+: ScwormNest/ScwormNest/Springer/LaserBeam/LaserBeam/LaserBeam/Springer/Blackout
        .byte   $23,$23,$23,$25,$27,$14,$14,$14 ; $08+: Changkey/Changkey/Changkey/Blackout/BlackoutEnd/LaserBeam/LaserBeam/LaserBeam
        .byte   $14,$14,$14,$14,$4E,$4E,$FF,$FF ; $10+: LaserBeam/LaserBeam/LaserBeam/LaserBeam/SniperArmor/SniperArmor/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $18+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+: ?/?/?/?/?/?/?/?
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
        .byte   $00,$06,$06,$06,$0E,$10,$10,$12,$15,$15,$16,$16,$17,$17,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_x_tbl — secondary (persistent) spawns, max 64 ($BA40) ───
spawn2_x_tbl:
        .byte   $30,$70,$90,$C0,$B8,$70,$70,$68,$F8,$F8,$F8,$F8,$08,$08,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_y_tbl — secondary (persistent) spawns, max 64 ($BA80) ───
spawn2_y_tbl:
        .byte   $58,$98,$58,$9A,$B8,$68,$B8,$78,$4F,$6F,$4F,$6F,$4F,$6F,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_type_tbl — secondary spawn types ($BAC0) ───
spawn2_type_tbl:
        .byte   $7B,$7A,$7B,$78,$78,$76,$7B,$78 ; $00+: ExtraLife/Etank/ExtraLife/LargeWeapon/LargeWeapon/LargeHealth/ExtraLife/LargeWeapon
        .byte   $2F,$2F,$2F,$2F,$2F,$2F,$FF,$FF ; $08+: BossDoor/BossDoor/BossDoor/BossDoor/BossDoor/BossDoor/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $10+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $18+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $28+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $30+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $38+: ?/?/?/?/?/?/?/?

; =============================================================================
; Checkpoint tables — 11 arrays × 6 slots ($BB00-$BB41)
; Indexed by checkpoint_idx ($B0): slots 0-2 = Quick Man,
; slots 3-5 = Wily 5. Restored by checkpoint_respawn (bank0F:865).
; =============================================================================
chk_boss_entry_y:  .byte   $94,$B4,$74,$94,$94,$94 ; boss-entrance landing Y
chk_screen:  .byte   $00,$07,$16,$18,$28,$28 ; checkpoint screen (nametable_select)
chk_spawn_idx:  .byte   $00,$07,$16,$16,$16,$16 ; primary spawn scan index
chk_spawn2_idx:  .byte   $00,$04,$0A,$0E,$0E,$0E ; secondary spawn scan index
chk_metatile_hi:  .byte   $84,$86,$8A,$8A,$8E,$8E ; metatile_ptr high
chk_metatile_lo:  .byte   $E0,$A0,$60,$E0,$E0,$E0 ; metatile_ptr low
chk_column_hi:  .byte   $85,$87,$8A,$8B,$8F,$8F ; column_ptr high
chk_column_lo:  .byte   $60,$20,$E0,$60,$60,$60 ; column_ptr low
chk_cur_screen:  .byte   $00,$07,$10,$12,$12,$12 ; current_screen (room index)
chk_scroll_lo:  .byte   $00,$07,$16,$18,$28,$28 ; scroll_screen_lo (left bound)
chk_scroll_hi:  .byte   $00,$0B,$16,$18,$28,$28 ; scroll_screen_hi (right bound)
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
; chr_upload_list_rm — CHR-RAM upload records: Quick Man ($BC00)
; [record count, then (src_page, page_count, src_bank) × N] → CHR $0000+
; =============================================================================
chr_upload_list_rm:
        .byte   $06                     ; 6 records
        .byte   $90,$09,$00             ; CHR $0000+: $9000 × 9 pages from bank $00
        .byte   $84,$01,$09             ; CHR $0900+: $8400 × 1 pages from bank $09
        .byte   $98,$05,$00             ; CHR $0A00+: $9800 × 5 pages from bank $00
        .byte   $9F,$01,$03             ; CHR $0F00+: $9F00 × 1 pages from bank $03
        .byte   $80,$06,$09             ; CHR $1000+: $8000 × 6 pages from bank $09
        .byte   $A0,$0A,$04             ; CHR $1600+: $A000 × 10 pages from bank $04
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
; chr_upload_list_wily — CHR-RAM upload records: Wily 5 ($BD00)
; [record count, then (src_page, page_count, src_bank) × N] → CHR $0000+
; =============================================================================
chr_upload_list_wily:
        .byte   $09                     ; 9 records
        .byte   $90,$09,$00             ; CHR $0000+: $9000 × 9 pages from bank $00
        .byte   $84,$01,$09             ; CHR $0900+: $8400 × 1 pages from bank $09
        .byte   $98,$05,$00             ; CHR $0A00+: $9800 × 5 pages from bank $00
        .byte   $9F,$01,$03             ; CHR $0F00+: $9F00 × 1 pages from bank $03
        .byte   $80,$02,$09             ; CHR $1000+: $8000 × 2 pages from bank $09
        .byte   $AC,$02,$02             ; CHR $1200+: $AC00 × 2 pages from bank $02
        .byte   $84,$01,$09             ; CHR $1400+: $8400 × 1 pages from bank $09
        .byte   $AA,$01,$04             ; CHR $1500+: $AA00 × 1 pages from bank $04
        .byte   $AA,$0A,$04             ; CHR $1600+: $AA00 × 10 pages from bank $04
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
        .byte   $FF,$FF,$FF,$FF

; =============================================================================
; palette_block_rm — Quick Man palettes ($BE00)
; [anim_target, anim_counter, 32-byte palette (BG+sprite), 4 × 16-byte
; palette animation frames] — copied verbatim to $0354-$03B5.
; =============================================================================
palette_block_rm:
        .byte   $00,$00                 ; anim target, counter
        .byte   $0F,$2C,$10,$1C,$0F,$37,$27,$07,$0F,$28,$16,$07,$0F,$28,$0F,$2C ; palette
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$20,$38,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$2C,$10,$1C,$0F,$27,$27,$07,$0F,$28,$16,$07,$0F,$28,$0F,$2C ; anim frame 0
        .byte   $0F,$2C,$10,$1C,$0F,$37,$27,$07,$0F,$28,$16,$07,$0F,$0F,$28,$2C ; anim frame 1
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
; palette_block_wily — Wily 5 palettes ($BF00)
; [anim_target, anim_counter, 32-byte palette (BG+sprite), 4 × 16-byte
; palette animation frames] — copied verbatim to $0354-$03B5.
; =============================================================================
palette_block_wily:
        .byte   $04,$06                 ; anim target, counter
        .byte   $0F,$30,$32,$22,$0F,$37,$27,$17,$0F,$19,$09,$21,$0F,$01,$01,$01 ; palette
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$20,$38,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$30,$32,$22,$0F,$37,$27,$17,$0F,$19,$09,$21,$0F,$01,$01,$01 ; anim frame 0
        .byte   $0F,$30,$32,$22,$0F,$37,$27,$17,$0F,$19,$09,$21,$0F,$01,$21,$01 ; anim frame 1
        .byte   $0F,$30,$32,$22,$0F,$37,$27,$17,$0F,$19,$09,$21,$0F,$01,$01,$21 ; anim frame 2
        .byte   $0F,$30,$32,$22,$0F,$37,$27,$17,$0F,$19,$09,$21,$0F,$01,$21,$21 ; anim frame 3
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
