.segment "BANK02"

; =============================================================================
; Bank $02 — Wood Man (stage $02) + Wily 3 (stage $0A) Stage Data
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
        .byte   $01,$01,$01,$01 ; metatile $00
        .byte   $00,$00,$00,$00 ; metatile $01
        .byte   $6E,$6E,$6E,$6E ; metatile $02
        .byte   $6E,$6E,$6F,$6F ; metatile $03
        .byte   $6E,$6E,$2F,$2F ; metatile $04
        .byte   $32,$3E,$31,$3E ; metatile $05
        .byte   $31,$3E,$31,$3E ; metatile $06
        .byte   $31,$3E,$33,$3E ; metatile $07
        .byte   $31,$28,$31,$3E ; metatile $08
        .byte   $31,$3E,$2E,$32 ; metatile $09
        .byte   $2E,$2E,$2E,$2E ; metatile $0A
        .byte   $2E,$2E,$2F,$2F ; metatile $0B
        .byte   $32,$3E,$2E,$32 ; metatile $0C
        .byte   $2E,$31,$2E,$31 ; metatile $0D
        .byte   $2E,$33,$33,$3E ; metatile $0E
        .byte   $2A,$2A,$00,$00 ; metatile $0F
        .byte   $2E,$32,$2E,$31 ; metatile $10
        .byte   $2E,$33,$31,$3E ; metatile $11
        .byte   $28,$28,$3D,$00 ; metatile $12
        .byte   $3D,$00,$3E,$36 ; metatile $13
        .byte   $37,$00,$36,$00 ; metatile $14
        .byte   $3E,$3D,$3E,$3D ; metatile $15
        .byte   $36,$00,$3D,$00 ; metatile $16
        .byte   $2A,$2B,$2D,$60 ; metatile $17
        .byte   $3E,$3D,$3E,$37 ; metatile $18
        .byte   $3D,$2A,$3D,$00 ; metatile $19
        .byte   $28,$28,$3E,$3D ; metatile $1A
        .byte   $3E,$2A,$37,$00 ; metatile $1B
        .byte   $3E,$2A,$3E,$36 ; metatile $1C
        .byte   $00,$2D,$00,$2D ; metatile $1D
        .byte   $2A,$2B,$00,$2D ; metatile $1E
        .byte   $28,$28,$00,$2D ; metatile $1F
        .byte   $01,$34,$34,$2E ; metatile $20
        .byte   $2C,$2E,$2C,$2E ; metatile $21
        .byte   $28,$28,$3E,$3E ; metatile $22
        .byte   $35,$2E,$01,$35 ; metatile $23
        .byte   $2C,$2E,$3F,$2F ; metatile $24
        .byte   $3E,$3E,$3E,$3E ; metatile $25
        .byte   $2E,$31,$21,$33 ; metatile $26
        .byte   $3E,$37,$3D,$00 ; metatile $27
        .byte   $00,$2D,$08,$08 ; metatile $28
        .byte   $31,$3E,$59,$59 ; metatile $29
        .byte   $78,$78,$59,$59 ; metatile $2A
        .byte   $79,$79,$21,$21 ; metatile $2B
        .byte   $21,$21,$78,$78 ; metatile $2C
        .byte   $2B,$60,$2D,$60 ; metatile $2D
        .byte   $28,$60,$2D,$60 ; metatile $2E
        .byte   $2A,$2B,$2D,$60 ; metatile $2F
        .byte   $6E,$6E,$59,$59 ; metatile $30
        .byte   $3E,$37,$59,$59 ; metatile $31
        .byte   $58,$58,$79,$79 ; metatile $32
        .byte   $79,$58,$21,$60 ; metatile $33
        .byte   $5A,$01,$01,$01 ; metatile $34
        .byte   $82,$00,$5A,$00 ; metatile $35
        .byte   $5A,$00,$5A,$00 ; metatile $36
        .byte   $82,$82,$2E,$2E ; metatile $37
        .byte   $2E,$2E,$59,$59 ; metatile $38
        .byte   $00,$00,$59,$59 ; metatile $39
        .byte   $58,$58,$59,$79 ; metatile $3A
        .byte   $60,$78,$60,$59 ; metatile $3B
        .byte   $60,$58,$60,$79 ; metatile $3C
        .byte   $5B,$5D,$EF,$60 ; metatile $3D
        .byte   $5B,$5D,$EF,$81 ; metatile $3E
        .byte   $00,$00,$00,$00 ; metatile $3F
        .byte   $01,$60,$01,$60 ; metatile $40
        .byte   $E8,$60,$01,$60 ; metatile $41
        .byte   $82,$82,$59,$59 ; metatile $42
        .byte   $01,$01,$59,$59 ; metatile $43
        .byte   $21,$21,$21,$21 ; metatile $44
        .byte   $22,$21,$22,$21 ; metatile $45
        .byte   $21,$21,$22,$21 ; metatile $46
        .byte   $22,$21,$21,$21 ; metatile $47
        .byte   $21,$21,$82,$82 ; metatile $48
        .byte   $21,$21,$82,$21 ; metatile $49
        .byte   $21,$24,$1D,$25 ; metatile $4A
        .byte   $1E,$26,$1F,$27 ; metatile $4B
        .byte   $22,$21,$21,$23 ; metatile $4C
        .byte   $21,$1B,$21,$1C ; metatile $4D
        .byte   $60,$58,$60,$59 ; metatile $4E
        .byte   $58,$58,$59,$59 ; metatile $4F
        .byte   $00,$00,$08,$08 ; metatile $50
        .byte   $2E,$31,$49,$49 ; metatile $51
        .byte   $47,$4C,$47,$4D ; metatile $52
        .byte   $4E,$4B,$4F,$4B ; metatile $53
        .byte   $22,$21,$08,$08 ; metatile $54
        .byte   $21,$21,$08,$08 ; metatile $55
        .byte   $5A,$22,$22,$21 ; metatile $56
        .byte   $21,$60,$21,$60 ; metatile $57
        .byte   $82,$82,$22,$21 ; metatile $58
        .byte   $22,$21,$59,$59 ; metatile $59
        .byte   $58,$58,$21,$21 ; metatile $5A
        .byte   $22,$21,$82,$82 ; metatile $5B
        .byte   $58,$58,$82,$82 ; metatile $5C
        .byte   $5A,$22,$59,$59 ; metatile $5D
        .byte   $22,$21,$5A,$22 ; metatile $5E
        .byte   $58,$58,$5A,$22 ; metatile $5F
        .byte   $69,$01,$69,$01 ; metatile $60
        .byte   $21,$21,$00,$01 ; metatile $61
        .byte   $58,$5A,$22,$21 ; metatile $62
        .byte   $21,$21,$59,$59 ; metatile $63
        .byte   $21,$82,$59,$59 ; metatile $64
        .byte   $5A,$22,$5A,$22 ; metatile $65
        .byte   $5A,$01,$59,$59 ; metatile $66
        .byte   $58,$58,$59,$59 ; metatile $67
        .byte   $35,$36,$38,$37 ; metatile $68
        .byte   $34,$36,$2F,$37 ; metatile $69
        .byte   $5A,$22,$59,$5A ; metatile $6A
        .byte   $82,$60,$21,$60 ; metatile $6B
        .byte   $82,$82,$5A,$22 ; metatile $6C
        .byte   $38,$38,$59,$59 ; metatile $6D
        .byte   $60,$58,$59,$59 ; metatile $6E
        .byte   $58,$58,$60,$59 ; metatile $6F
        .byte   $21,$21,$60,$59 ; metatile $70
        .byte   $60,$58,$82,$82 ; metatile $71
        .byte   $82,$82,$60,$59 ; metatile $72
        .byte   $60,$58,$21,$21 ; metatile $73
        .byte   $58,$5A,$59,$5A ; metatile $74
        .byte   $58,$5A,$59,$59 ; metatile $75
        .byte   $58,$58,$59,$5A ; metatile $76
        .byte   $58,$5A,$5A,$22 ; metatile $77
        .byte   $58,$5A,$5A,$01 ; metatile $78
        .byte   $5A,$2E,$2E,$2E ; metatile $79
        .byte   $58,$5A,$82,$82 ; metatile $7A
        .byte   $82,$82,$59,$5A ; metatile $7B
        .byte   $22,$21,$59,$5A ; metatile $7C
        .byte   $01,$01,$5A,$01 ; metatile $7D
        .byte   $21,$60,$21,$21 ; metatile $7E
        .byte   $39,$3A,$37,$39 ; metatile $7F
        .byte   $00,$00,$3A,$00 ; metatile $80
        .byte   $3C,$3D,$37,$3F ; metatile $81
        .byte   $3B,$2A,$39,$3A ; metatile $82
        .byte   $36,$3D,$39,$3F ; metatile $83
        .byte   $38,$35,$38,$37 ; metatile $84
        .byte   $00,$00,$59,$59 ; metatile $85
        .byte   $00,$2D,$59,$59 ; metatile $86
        .byte   $37,$3A,$59,$59 ; metatile $87
        .byte   $F0,$F1,$33,$37 ; metatile $88
        .byte   $2D,$60,$2D,$60 ; metatile $89
        .byte   $01,$2C,$2C,$38 ; metatile $8A
        .byte   $2C,$38,$2C,$38 ; metatile $8B
        .byte   $2C,$38,$01,$2C ; metatile $8C
        .byte   $01,$2C,$2C,$2E ; metatile $8D
        .byte   $01,$2C,$01,$2C ; metatile $8E
        .byte   $01,$2C,$01,$01 ; metatile $8F
        .byte   $38,$38,$2C,$38 ; metatile $90
        .byte   $2C,$35,$01,$2C ; metatile $91
        .byte   $38,$35,$38,$38 ; metatile $92
        .byte   $34,$35,$2F,$38 ; metatile $93
        .byte   $60,$5A,$60,$5A ; metatile $94
        .byte   $60,$58,$59,$59 ; metatile $95
        .byte   $58,$58,$22,$21 ; metatile $96
        .byte   $01,$69,$01,$69 ; metatile $97
        .byte   $58,$5A,$22,$21 ; metatile $98
        .byte   $5A,$22,$21,$21 ; metatile $99
        .byte   $21,$21,$5A,$22 ; metatile $9A
        .byte   $58,$58,$21,$60 ; metatile $9B
        .byte   $21,$21,$59,$59 ; metatile $9C
        .byte   $60,$58,$21,$21 ; metatile $9D
        .byte   $58,$5A,$21,$21 ; metatile $9E
        .byte   $3E,$37,$49,$4A ; metatile $9F
        .byte   $5B,$5D,$00,$00 ; metatile $A0
        .byte   $5B,$5D,$5A,$5C ; metatile $A1
        .byte   $5B,$5F,$5A,$5C ; metatile $A2
        .byte   $5B,$5D,$2E,$2D ; metatile $A3
        .byte   $5B,$5F,$2D,$2D ; metatile $A4
        .byte   $59,$5D,$2D,$2D ; metatile $A5
        .byte   $5F,$2E,$2D,$2D ; metatile $A6
        .byte   $5B,$5F,$5A,$5E ; metatile $A7
        .byte   $2D,$2D,$2D,$2D ; metatile $A8
        .byte   $2D,$2D,$60,$2E ; metatile $A9
        .byte   $60,$2E,$2D,$2D ; metatile $AA
        .byte   $2D,$2D,$2D,$60 ; metatile $AB
        .byte   $2D,$2D,$2E,$2D ; metatile $AC
        .byte   $2E,$2D,$2D,$2D ; metatile $AD
        .byte   $2D,$2D,$5E,$2E ; metatile $AE
        .byte   $2E,$2D,$2E,$2D ; metatile $AF
        .byte   $59,$5D,$58,$5C ; metatile $B0
        .byte   $5B,$5D,$58,$5C ; metatile $B1
        .byte   $2D,$59,$2D,$58 ; metatile $B2
        .byte   $5F,$2E,$5E,$2E ; metatile $B3
        .byte   $2E,$2D,$5A,$5C ; metatile $B4
        .byte   $2D,$2D,$2D,$58 ; metatile $B5
        .byte   $2D,$2D,$5A,$5C ; metatile $B6
        .byte   $5F,$2E,$5A,$5C ; metatile $B7
        .byte   $2D,$59,$5A,$5C ; metatile $B8
        .byte   $2D,$60,$2D,$60 ; metatile $B9
        .byte   $61,$60,$2D,$60 ; metatile $BA
        .byte   $61,$61,$2D,$2D ; metatile $BB
        .byte   $2D,$61,$2D,$2D ; metatile $BC
        .byte   $60,$81,$60,$81 ; metatile $BD
        .byte   $00,$7C,$00,$7C ; metatile $BE
        .byte   $7C,$7C,$7C,$7C ; metatile $BF
        .byte   $5B,$5D,$5E,$2E ; metatile $C0
        .byte   $5B,$5D,$81,$81 ; metatile $C1
        .byte   $81,$81,$5A,$5C ; metatile $C2
        .byte   $5B,$5D,$2D,$2D ; metatile $C3
        .byte   $5B,$5D,$A8,$81 ; metatile $C4
        .byte   $A8,$81,$A8,$81 ; metatile $C5
        .byte   $2A,$2A,$2C,$2C ; metatile $C6
        .byte   $2A,$2A,$2B,$2B ; metatile $C7
        .byte   $2D,$60,$5A,$5E ; metatile $C8
        .byte   $81,$59,$5A,$5C ; metatile $C9
        .byte   $2D,$2D,$00,$2D ; metatile $CA
        .byte   $5B,$5D,$EF,$EF ; metatile $CB
        .byte   $5B,$5D,$61,$61 ; metatile $CC
        .byte   $81,$EF,$81,$EF ; metatile $CD
        .byte   $81,$81,$81,$81 ; metatile $CE
        .byte   $61,$61,$61,$61 ; metatile $CF
        .byte   $61,$61,$EF,$EF ; metatile $D0
        .byte   $61,$61,$81,$A9 ; metatile $D1
        .byte   $61,$61,$80,$80 ; metatile $D2
        .byte   $81,$EF,$61,$61 ; metatile $D3
        .byte   $81,$A9,$61,$61 ; metatile $D4
        .byte   $80,$80,$61,$61 ; metatile $D5
        .byte   $61,$61,$EF,$A9 ; metatile $D6
        .byte   $61,$61,$81,$EF ; metatile $D7
        .byte   $EF,$A9,$EF,$A9 ; metatile $D8
        .byte   $5F,$00,$5E,$08 ; metatile $D9
        .byte   $81,$81,$81,$61 ; metatile $DA
        .byte   $81,$81,$81,$EF ; metatile $DB
        .byte   $81,$EF,$81,$81 ; metatile $DC
        .byte   $81,$A9,$81,$A9 ; metatile $DD
        .byte   $A8,$81,$58,$5C ; metatile $DE
        .byte   $5F,$81,$5E,$81 ; metatile $DF
        .byte   $5B,$5D,$5A,$5C ; metatile $E0
        .byte   $59,$5D,$58,$5C ; metatile $E1
        .byte   $59,$5D,$81,$EF ; metatile $E2
        .byte   $5B,$5D,$EF,$EF ; metatile $E3
        .byte   $EF,$EF,$5A,$5C ; metatile $E4
        .byte   $5F,$EF,$5E,$EF ; metatile $E5
        .byte   $5F,$EF,$EF,$EF ; metatile $E6
        .byte   $31,$33,$32,$34 ; metatile $E7
        .byte   $81,$81,$5E,$81 ; metatile $E8
        .byte   $EF,$81,$5A,$5C ; metatile $E9
        .byte   $5B,$5D,$5E,$EF ; metatile $EA
        .byte   $5B,$5F,$EF,$EF ; metatile $EB
        .byte   $59,$5D,$5A,$5C ; metatile $EC
        .byte   $EF,$EF,$81,$81 ; metatile $ED
        .byte   $81,$81,$EF,$EF ; metatile $EE
        .byte   $EF,$81,$EF,$81 ; metatile $EF
        .byte   $81,$81,$EF,$81 ; metatile $F0
        .byte   $5B,$5F,$5A,$5E ; metatile $F1
        .byte   $5B,$5D,$81,$EF ; metatile $F2
        .byte   $5B,$5D,$5A,$5E ; metatile $F3
        .byte   $EF,$81,$5E,$EF ; metatile $F4
        .byte   $81,$EF,$EF,$58 ; metatile $F5
        .byte   $EF,$59,$81,$EF ; metatile $F6
        .byte   $EF,$81,$81,$81 ; metatile $F7
        .byte   $81,$59,$81,$58 ; metatile $F8
        .byte   $5B,$5D,$81,$60 ; metatile $F9
        .byte   $81,$60,$81,$60 ; metatile $FA
        .byte   $81,$81,$81,$58 ; metatile $FB
        .byte   $EF,$A9,$61,$61 ; metatile $FC
        .byte   $5B,$5D,$00,$00 ; metatile $FD
        .byte   $00,$00,$08,$08 ; metatile $FE
        .byte   $00,$59,$08,$58 ; metatile $FF

; =============================================================================
; metatile_attrs — palette attribute byte per metatile ($8400)
; =============================================================================
metatile_attrs:
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; $00-$07
        .byte   $10,$00,$00,$00,$00,$00,$00,$11 ; $08-$0F
        .byte   $00,$00,$11,$00,$00,$00,$00,$81 ; $10-$17
        .byte   $00,$10,$11,$10,$10,$00,$01,$11 ; $18-$1F
        .byte   $00,$00,$11,$00,$00,$00,$00,$00 ; $20-$27
        .byte   $88,$88,$AA,$AA,$AA,$A0,$A1,$81 ; $28-$2F
        .byte   $88,$88,$AA,$AE,$02,$0A,$0A,$22 ; $30-$37
        .byte   $88,$88,$AA,$AA,$AA,$08,$88,$00 ; $38-$3F
        .byte   $A0,$A1,$AA,$88,$FF,$FF,$FF,$FF ; $40-$47
        .byte   $BB,$FB,$FF,$FF,$FF,$FF,$AA,$AA ; $48-$4F
        .byte   $88,$88,$AA,$AA,$BB,$BB,$FE,$AF ; $50-$57
        .byte   $EE,$BB,$EE,$BB,$AA,$BA,$FB,$EA ; $58-$5F
        .byte   $05,$33,$EE,$BB,$AB,$FA,$8A,$AA ; $60-$67
        .byte   $00,$00,$BA,$AE,$EA,$88,$AA,$AA ; $68-$6F
        .byte   $BB,$AA,$AA,$EE,$AA,$AA,$AA,$EA ; $70-$77
        .byte   $2A,$02,$AA,$AA,$BB,$08,$EF,$00 ; $78-$7F
        .byte   $00,$00,$10,$00,$00,$88,$88,$88 ; $80-$87
        .byte   $00,$A0,$00,$00,$00,$00,$00,$00 ; $88-$8F
        .byte   $00,$00,$00,$00,$AA,$AA,$EE,$50 ; $90-$97
        .byte   $EE,$FE,$FB,$AE,$BB,$EE,$EE,$88 ; $98-$9F
        .byte   $00,$55,$55,$DD,$DD,$DD,$FD,$55 ; $A0-$A7
        .byte   $FF,$F7,$FD,$7F,$FF,$FF,$F7,$FF ; $A8-$AF
        .byte   $55,$55,$5F,$F5,$77,$7F,$77,$75 ; $B0-$B7
        .byte   $57,$5F,$5D,$DD,$DF,$A0,$0F,$00 ; $B8-$BF
        .byte   $D5,$88,$22,$DD,$88,$AA,$FF,$FF ; $C0-$C7
        .byte   $57,$02,$FF,$88,$00,$AA,$AA,$00 ; $C8-$CF
        .byte   $88,$88,$88,$22,$22,$22,$88,$88 ; $D0-$D7
        .byte   $AA,$45,$2A,$AA,$AA,$AA,$22,$A0 ; $D8-$DF
        .byte   $00,$00,$88,$88,$22,$A0,$A8,$FF ; $E0-$E7
        .byte   $A2,$22,$80,$88,$00,$AA,$AA,$AA ; $E8-$EF
        .byte   $AA,$00,$88,$00,$A2,$2A,$8A,$AA ; $F0-$F7
        .byte   $0A,$08,$0A,$2A,$22,$00,$44,$54 ; $F8-$FF

; =============================================================================
; screen_layouts — 64-byte rooms, column-major 8×8 metatile IDs ($8500)
; ptr = $8500 + screen × $40. Rooms are consumed in virtual-screen order;
; checkpoint tables give each stage's range:
;   Wood Man rooms $00-$16+, Wily 3 rooms $18-$22+
; Each row below = one 8-metatile column (left to right).
; =============================================================================
screen_layouts:
; ─── screen $00 ($8500) — Wood Man rooms ───
        .byte   $02,$02,$02,$0C,$18,$1D,$4E,$4F
        .byte   $02,$02,$02,$0D,$19,$1E,$4E,$4F
        .byte   $02,$02,$02,$0D,$12,$1F,$4E,$4F
        .byte   $02,$03,$03,$0E,$19,$1E,$4E,$4F
        .byte   $02,$02,$02,$05,$13,$1D,$4E,$4F
        .byte   $02,$02,$02,$06,$18,$1E,$4E,$4F
        .byte   $02,$02,$02,$08,$12,$1F,$4E,$4F
        .byte   $02,$02,$0B,$07,$19,$1E,$4E,$4F
; ─── screen $01 ($8540) — Wood Man rooms ───
        .byte   $02,$02,$0A,$0C,$14,$2D,$4F,$4F
        .byte   $02,$02,$0A,$0D,$12,$2E,$4F,$4F
        .byte   $02,$02,$03,$0E,$1B,$1E,$4E,$4F
        .byte   $02,$02,$02,$05,$13,$1D,$4E,$4F
        .byte   $02,$02,$0A,$09,$18,$17,$6E,$4F
        .byte   $02,$02,$0A,$0D,$12,$2E,$4F,$4F
        .byte   $03,$0B,$0B,$0E,$1B,$2D,$4F,$4F
        .byte   $02,$0A,$0D,$18,$1E,$4E,$4F,$4F
; ─── screen $02 ($8580) — Wood Man rooms ───
        .byte   $02,$0A,$0D,$12,$1F,$4E,$4F,$4F
        .byte   $02,$0A,$11,$13,$1D,$4E,$4F,$4F
        .byte   $02,$02,$10,$18,$1E,$4E,$4F,$4F
        .byte   $02,$02,$0D,$1A,$1F,$4E,$4F,$4F
        .byte   $03,$0A,$0E,$18,$1E,$4E,$4F,$4F
        .byte   $02,$0D,$25,$19,$1E,$4E,$4F,$4F
        .byte   $02,$02,$05,$13,$01,$2D,$4F,$4F
        .byte   $02,$02,$08,$22,$12,$2E,$4F,$4F
; ─── screen $03 ($85C0) — Wood Man rooms ───
        .byte   $02,$03,$07,$25,$1B,$2D,$4F,$4F
        .byte   $02,$02,$0C,$15,$0F,$2D,$4F,$4F
        .byte   $02,$02,$02,$05,$16,$1D,$4E,$4F
        .byte   $02,$02,$02,$08,$12,$1F,$4E,$4F
        .byte   $02,$02,$02,$07,$19,$1E,$4E,$4F
        .byte   $02,$02,$0A,$0C,$1C,$1E,$4E,$4F
        .byte   $02,$02,$0A,$0D,$1A,$1F,$4E,$4F
        .byte   $02,$02,$0B,$0E,$18,$1E,$4E,$4F
; ─── screen $04 ($8600) — Wood Man rooms ───
        .byte   $02,$02,$0A,$09,$19,$1E,$4E,$4F
        .byte   $02,$02,$0A,$0D,$12,$1F,$4E,$4F
        .byte   $02,$02,$0B,$0E,$1C,$1E,$4E,$4F
        .byte   $02,$02,$0A,$05,$15,$1E,$4E,$4F
        .byte   $02,$02,$0A,$08,$1A,$1F,$4E,$4F
        .byte   $30,$30,$38,$29,$31,$39,$42,$42
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
; ─── screen $05 ($8640) — Wood Man rooms ───
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
        .byte   $4F,$4F,$4F,$65,$44,$44,$48,$48
        .byte   $4F,$4F,$4F,$6A,$46,$44,$4E,$4F
        .byte   $4F,$4F,$76,$62,$47,$57,$4F,$4F
        .byte   $4F,$4F,$75,$5E,$44,$44,$4E,$4F
        .byte   $42,$6C,$6B,$65,$44,$57,$4F,$4F
        .byte   $4F,$65,$44,$44,$44,$44,$4E,$4F
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
; ─── screen $06 ($8680) — Wood Man rooms ───
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
        .byte   $48,$49,$44,$4E,$4F,$4F,$4F,$4F
        .byte   $76,$56,$44,$44,$44,$9D,$6F,$4F
        .byte   $76,$62,$47,$44,$44,$44,$4E,$4F
        .byte   $4F,$76,$56,$44,$44,$44,$4E,$4F
        .byte   $4F,$76,$62,$47,$44,$4E,$4F,$4F
        .byte   $4F,$5F,$99,$44,$44,$4E,$4F,$4F
        .byte   $4F,$75,$59,$9A,$44,$4E,$4F,$4F
; ─── screen $07 ($86C0) — Wood Man rooms ───
        .byte   $4F,$4F,$4F,$74,$45,$4E,$4F,$4F
        .byte   $4F,$4F,$4F,$74,$45,$4E,$4F,$4F
        .byte   $4F,$4F,$76,$62,$47,$4E,$4F,$4F
        .byte   $4F,$77,$47,$44,$44,$4E,$4F,$4F
        .byte   $4F,$76,$56,$44,$44,$4E,$4F,$4F
        .byte   $76,$62,$47,$44,$4E,$4F,$4F,$4F
        .byte   $76,$56,$44,$44,$4E,$4F,$4F,$4F
        .byte   $4F,$75,$7C,$46,$44,$44,$4E,$4F
; ─── screen $08 ($8700) — Wood Man rooms ───
        .byte   $4F,$4F,$76,$62,$47,$44,$4E,$4F
        .byte   $4F,$4F,$65,$44,$44,$4E,$4F,$4F
        .byte   $4F,$4F,$74,$45,$4E,$4F,$4F,$4F
        .byte   $4F,$5F,$9E,$47,$4E,$4F,$4F,$4F
        .byte   $4F,$6A,$46,$44,$4E,$4F,$4F,$4F
        .byte   $74,$45,$44,$44,$4E,$4F,$4F,$4F
        .byte   $77,$47,$44,$4E,$4F,$4F,$4F,$4F
        .byte   $65,$44,$44,$4E,$4F,$4F,$4F,$4F
; ─── screen $09 ($8740) — Wood Man rooms ───
        .byte   $65,$44,$44,$4E,$4F,$4F,$4F,$4F
        .byte   $65,$44,$44,$4E,$4F,$4F,$4F,$4F
        .byte   $65,$44,$44,$4E,$4F,$4F,$4F,$4F
        .byte   $65,$44,$44,$4E,$4F,$4F,$4F,$4F
        .byte   $65,$44,$44,$4E,$4F,$4F,$4F,$4F
        .byte   $65,$44,$44,$4E,$4F,$4F,$4F,$4F
        .byte   $42,$42,$42,$6E,$4F,$4F,$4F,$4F
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
; ─── screen $0A ($8780) — Wood Man rooms ───
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
        .byte   $5C,$5C,$5C,$5C,$5A,$9B,$4F,$4F
        .byte   $4F,$74,$45,$44,$44,$57,$4F,$4F
        .byte   $4F,$4F,$74,$45,$44,$57,$4F,$4F
        .byte   $4F,$4F,$74,$45,$44,$44,$4E,$4F
        .byte   $4F,$4F,$4F,$74,$45,$44,$4E,$4F
        .byte   $4F,$4F,$4F,$75,$59,$9C,$42,$42
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
; ─── screen $0B ($87C0) — Wood Man rooms ───
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
        .byte   $4F,$4F,$4F,$76,$96,$5A,$5C,$5C
        .byte   $4F,$4F,$4F,$74,$45,$44,$4E,$4F
        .byte   $4F,$4F,$4F,$74,$45,$44,$4E,$4F
        .byte   $4F,$4F,$74,$45,$44,$4E,$4F,$4F
        .byte   $4F,$4F,$74,$45,$44,$4E,$4F,$4F
        .byte   $4F,$4F,$74,$45,$4E,$4F,$4F,$4F
        .byte   $4F,$4F,$74,$45,$4E,$4F,$4F,$4F
; ─── screen $0C ($8800) — Wood Man rooms ───
        .byte   $4F,$76,$34,$00,$60,$23,$0A,$0A
        .byte   $4F,$78,$00,$00,$60,$00,$21,$0A
        .byte   $74,$00,$00,$00,$60,$20,$0A,$0A
        .byte   $74,$00,$00,$00,$60,$21,$0A,$0A
        .byte   $00,$00,$00,$00,$20,$0A,$0A,$0A
        .byte   $00,$00,$00,$60,$21,$0A,$0A,$0A
        .byte   $00,$00,$00,$60,$23,$0A,$0A,$0A
        .byte   $00,$00,$00,$60,$00,$23,$0A,$0A
; ─── screen $0D ($8840) — Wood Man rooms ───
        .byte   $00,$00,$00,$60,$00,$00,$21,$0A
        .byte   $00,$00,$00,$60,$00,$00,$21,$0A
        .byte   $00,$00,$00,$00,$00,$60,$23,$0A
        .byte   $00,$00,$00,$00,$00,$60,$20,$0A
        .byte   $00,$00,$00,$00,$00,$60,$21,$0A
        .byte   $00,$00,$00,$00,$00,$60,$23,$0A
        .byte   $00,$00,$00,$00,$00,$60,$20,$0A
        .byte   $00,$00,$00,$00,$00,$60,$21,$0A
; ─── screen $0E ($8880) — Wood Man rooms ───
        .byte   $00,$00,$00,$00,$00,$20,$0A,$0A
        .byte   $00,$00,$00,$00,$60,$21,$0A,$0B
        .byte   $00,$00,$00,$00,$60,$23,$0A,$0A
        .byte   $00,$00,$00,$00,$60,$00,$23,$0A
        .byte   $00,$00,$97,$00,$00,$00,$00,$21
        .byte   $00,$00,$97,$00,$00,$00,$00,$21
        .byte   $00,$00,$4E,$66,$43,$00,$00,$23
        .byte   $00,$00,$4E,$4F,$4F,$4F,$66,$43
; ─── screen $0F ($88C0) — Wood Man rooms ───
        .byte   $74,$45,$4E,$4F,$4F,$4F,$4F,$4F
        .byte   $74,$45,$4E,$4F,$4F,$4F,$4F,$4F
        .byte   $74,$45,$4E,$4F,$4F,$4F,$4F,$4F
        .byte   $74,$45,$4E,$4F,$4F,$4F,$4F,$4F
        .byte   $74,$45,$4E,$4F,$4F,$4F,$4F,$4F
        .byte   $74,$45,$4E,$4F,$4F,$4F,$4F,$4F
        .byte   $74,$45,$71,$5C,$5C,$5C,$5C,$5C
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
; ─── screen $10 ($8900) — Wood Man rooms ───
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
        .byte   $4F,$74,$45,$44,$44,$44,$72,$42
        .byte   $74,$45,$44,$44,$44,$44,$4E,$4F
        .byte   $74,$45,$44,$44,$44,$44,$4E,$4F
        .byte   $74,$45,$44,$44,$44,$44,$4E,$4F
        .byte   $74,$45,$44,$44,$44,$44,$4E,$4F
        .byte   $7A,$5B,$48,$44,$44,$44,$4E,$4F
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
; ─── screen $11 ($8940) — Wood Man rooms ───
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
        .byte   $7B,$58,$4E,$4F,$4F,$4F,$4F,$4F
        .byte   $74,$45,$7E,$6F,$4F,$4F,$4F,$4F
        .byte   $74,$45,$44,$7E,$6F,$4F,$4F,$4F
        .byte   $74,$45,$44,$44,$7E,$6F,$4F,$4F
        .byte   $74,$45,$44,$44,$44,$7E,$6F,$4F
        .byte   $75,$59,$63,$63,$63,$63,$42,$42
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
; ─── screen $12 ($8980) — Wood Man rooms ───
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
        .byte   $74,$45,$44,$44,$44,$44,$72,$35
        .byte   $74,$45,$44,$44,$44,$70,$6E,$36
        .byte   $74,$45,$44,$44,$44,$4E,$4F,$36
        .byte   $74,$45,$44,$44,$70,$6E,$4F,$36
        .byte   $74,$45,$44,$44,$4E,$4F,$4F,$36
        .byte   $42,$42,$6E,$4F,$4F,$4F,$4F,$36
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$36
; ─── screen $13 ($89C0) — Wood Man rooms ───
        .byte   $4F,$4F,$4F,$4F,$4F,$4F,$4F,$4F
        .byte   $37,$37,$0A,$05,$19,$1E,$4E,$4F
        .byte   $0A,$0A,$0A,$08,$12,$1F,$4E,$4F
        .byte   $0A,$0B,$0B,$07,$19,$1E,$4E,$4F
        .byte   $0A,$0A,$0D,$25,$13,$1D,$4E,$4F
        .byte   $0A,$0A,$0D,$25,$18,$1E,$4E,$4F
        .byte   $0A,$0A,$0D,$22,$12,$1F,$4E,$4F
        .byte   $0A,$0A,$0E,$25,$1B,$1E,$4E,$4F
; ─── screen $14 ($8A00) — Wood Man rooms ───
        .byte   $0A,$0A,$0C,$15,$1D,$4E,$4F,$4F
        .byte   $0A,$0A,$0D,$1A,$1F,$4E,$4F,$4F
        .byte   $0A,$0B,$0E,$18,$1E,$4E,$4F,$4F
        .byte   $0A,$11,$25,$1B,$1E,$4E,$4F,$4F
        .byte   $0A,$10,$15,$1D,$4E,$4F,$4F,$4F
        .byte   $0A,$0D,$1A,$1F,$4E,$4F,$4F,$4F
        .byte   $0A,$11,$18,$1E,$4E,$4F,$4F,$4F
        .byte   $0A,$0D,$19,$1E,$4E,$4F,$4F,$4F
; ─── screen $15 ($8A40) — Wood Man rooms ───
        .byte   $0A,$0D,$12,$1F,$4E,$4F,$4F,$4F
        .byte   $0A,$11,$13,$1D,$4E,$4F,$4F,$4F
        .byte   $0A,$10,$18,$1E,$4E,$4F,$4F,$4F
        .byte   $0A,$0D,$1A,$1F,$4E,$4F,$4F,$4F
        .byte   $0B,$0E,$18,$1E,$4E,$4F,$4F,$4F
        .byte   $0D,$25,$1B,$1E,$4E,$4F,$4F,$4F
        .byte   $51,$9F,$01,$1D,$4E,$4F,$4F,$4F
        .byte   $52,$53,$50,$28,$4E,$4F,$4F,$4F
; ─── screen $16 ($8A80) — Wood Man rooms ───
        .byte   $4F,$74,$45,$44,$4E,$4F,$4F,$4F
        .byte   $4F,$74,$45,$44,$4E,$4F,$4F,$4F
        .byte   $4F,$74,$45,$44,$4E,$4F,$4F,$4F
        .byte   $4F,$74,$45,$44,$4E,$4F,$4F,$4F
        .byte   $4F,$74,$45,$44,$4E,$4F,$4F,$4F
        .byte   $4F,$74,$45,$44,$4E,$4F,$4F,$4F
        .byte   $4F,$74,$45,$44,$4E,$4F,$4F,$4F
        .byte   $4F,$74,$54,$55,$4E,$4F,$4F,$4F
; ─── screen $17 ($8AC0) — Wood Man boss corridor ───
        .byte   $4F,$77,$47,$44,$73,$5A,$6F,$4F
        .byte   $75,$7C,$46,$44,$44,$44,$4E,$4F
        .byte   $4F,$5F,$99,$44,$44,$44,$4E,$4F
        .byte   $76,$98,$47,$44,$44,$44,$4E,$4F
        .byte   $76,$98,$47,$44,$44,$44,$4E,$4F
        .byte   $76,$56,$44,$44,$44,$44,$4E,$4F
        .byte   $4F,$6A,$46,$44,$44,$44,$4E,$4F
        .byte   $4F,$4F,$5D,$63,$63,$63,$6E,$4F
; ─── screen $18 ($8B00) — Wily 3 rooms ───
        .byte   $A1,$A1,$A1,$A1,$A1,$A1,$A1,$A1
        .byte   $A1,$A1,$A1,$A1,$A1,$A1,$A1,$A1
        .byte   $A1,$A1,$A1,$A1,$A1,$A1,$A1,$A1
        .byte   $A8,$A8,$A8,$A8,$A8,$A9,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$AA,$A8,$A8
        .byte   $A1,$A1,$A1,$A1,$A1,$A1,$A1,$A1
        .byte   $A1,$A1,$A1,$A1,$A1,$A1,$A1,$A1
        .byte   $A1,$A1,$A1,$A1,$A1,$A1,$A1,$A1
; ─── screen $19 ($8B40) — Wily 3 rooms ───
        .byte   $A1,$A1,$A1,$A7,$A3,$B1,$A1,$A1
        .byte   $A1,$A1,$A1,$A7,$AF,$B0,$A1,$A1
        .byte   $A1,$A2,$A3,$A4,$AD,$A5,$A6,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A9,$A8,$A8
        .byte   $A8,$A8,$AB,$AC,$A8,$A8,$A8,$A8
        .byte   $B4,$AE,$B5,$B6,$AE,$A8,$A8,$A8
        .byte   $A1,$B3,$B2,$A1,$A1,$A1,$A1,$A1
        .byte   $A1,$B7,$B8,$A1,$A1,$A1,$A1,$A1
; ─── screen $1A ($8B80) — Wily 3 rooms ───
        .byte   $A1,$A1,$A1,$A1,$A1,$C0,$C3,$C3
        .byte   $A1,$A1,$C0,$C3,$A6,$A8,$A8,$A8
        .byte   $A8,$A8,$AA,$A8,$A8,$A8,$A8,$A8
        .byte   $A8,$A8,$A8,$A8,$A8,$A8,$AB,$CA
        .byte   $A8,$BC,$BB,$BB,$AD,$BB,$BA,$01
        .byte   $A8,$A8,$A8,$AB,$AC,$A8,$B9,$01
        .byte   $A2,$B4,$B6,$C8,$AF,$A8,$B9,$01
        .byte   $A1,$A1,$A1,$A1,$A1,$A1,$A7,$01
; ─── screen $1B ($8BC0) — Wily 3 rooms ───
        .byte   $C3,$C3,$C4,$CB,$CB,$CC,$CC,$CC
        .byte   $A8,$A8,$C5,$CE,$CD,$D0,$D1,$D2
        .byte   $A8,$A8,$C5,$CE,$CE,$D3,$D4,$D5
        .byte   $A8,$A8,$C5,$CE,$CE,$D7,$D6,$D2
        .byte   $C7,$C7,$C5,$CE,$CE,$CE,$D8,$01
        .byte   $C7,$E7,$C5,$CE,$CE,$D3,$D4,$D5
        .byte   $C6,$C6,$C5,$CE,$CE,$CF,$CF,$CF
        .byte   $C6,$C6,$C5,$CE,$CE,$DC,$D8,$01
; ─── screen $1C ($8C00) — Wily 3 rooms ───
        .byte   $C7,$C7,$C5,$CE,$CE,$DB,$D8,$01
        .byte   $C7,$E7,$C5,$CE,$CE,$D3,$D4,$D5
        .byte   $C7,$C7,$C5,$CE,$CE,$DC,$D8,$01
        .byte   $C7,$E7,$C5,$CE,$CE,$CE,$D8,$01
        .byte   $C6,$C6,$C5,$CE,$CE,$DA,$FC,$D5
        .byte   $C6,$C6,$C5,$CE,$CE,$CE,$D8,$01
        .byte   $C6,$C6,$C5,$CE,$CE,$CD,$DD,$01
        .byte   $E7,$C7,$C5,$CE,$CE,$CF,$CF,$CF
; ─── screen $1D ($8C40) — Wily 3 rooms ───
        .byte   $C7,$C7,$C5,$CE,$CE,$CE,$DD,$01
        .byte   $C6,$C6,$C5,$CE,$CE,$CE,$DD,$01
        .byte   $C6,$C6,$C5,$CE,$CE,$D3,$D4,$D5
        .byte   $C7,$E7,$C5,$CE,$CE,$D7,$D1,$D2
        .byte   $C7,$E7,$C5,$CE,$CE,$D3,$D4,$D5
        .byte   $C7,$E7,$C5,$CE,$CE,$D7,$D1,$D2
        .byte   $C7,$C7,$C5,$CE,$CE,$DB,$D8,$01
        .byte   $C7,$C7,$C5,$CE,$CE,$CF,$CF,$CF
; ─── screen $1E ($8C80) — Wily 3 rooms ───
        .byte   $C6,$C6,$C5,$CE,$CE,$CE,$DD,$01
        .byte   $E7,$C7,$C5,$CE,$CE,$CE,$DD,$01
        .byte   $C6,$C6,$C5,$CE,$CE,$D3,$D4,$D5
        .byte   $A1,$A1,$DF,$CE,$E1,$E0,$E0,$E0
        .byte   $A1,$A1,$E5,$CE,$E1,$E0,$E0,$E0
        .byte   $A1,$A1,$E5,$CE,$E1,$E0,$E0,$E0
        .byte   $A1,$A1,$E5,$CE,$E1,$E0,$E0,$E0
        .byte   $A1,$A1,$E5,$CE,$E1,$E0,$E0,$E0
; ─── screen $1F ($8CC0) — Wily 3 rooms ───
        .byte   $A1,$A1,$E5,$CE,$E1,$E0,$E0,$E0
        .byte   $A1,$A1,$E5,$CE,$E1,$E0,$E0,$E0
        .byte   $A1,$A1,$E5,$CE,$E1,$E0,$E0,$E0
        .byte   $A7,$E3,$E6,$CE,$E1,$E0,$E0,$E0
        .byte   $A7,$EF,$CE,$CE,$E2,$E3,$E3,$E3
        .byte   $A7,$EF,$CE,$CE,$CE,$CE,$CE,$CE
        .byte   $A7,$E4,$E4,$E4,$E4,$E4,$E4,$E4
        .byte   $A1,$E0,$E0,$E0,$E0,$E0,$E0,$E0
; ─── screen $20 ($8D00) — Wily 3 rooms ───
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$EA,$E3,$E3,$E3
        .byte   $E3,$EB,$ED,$ED,$F7,$CE,$CE,$CE
        .byte   $CE,$CE,$CE,$CE,$CE,$EE,$EE,$EE
        .byte   $E4,$E4,$E4,$E4,$E4,$EC,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
; ─── screen $21 ($8D40) — Wily 3 rooms ───
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E3,$E6,$ED,$ED,$ED,$F6,$E3,$E3
        .byte   $CE,$CE,$CE,$CE,$CE,$CE,$CE,$CE
        .byte   $EE,$EE,$F5,$E4,$F4,$EE,$EE,$EE
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
; ─── screen $22 ($8D80) — Wily 3 rooms ───
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$F3,$F2,$C1,$F2,$C1
        .byte   $EB,$F7,$ED,$F7,$CE,$CE,$CE,$CE
        .byte   $CE,$CE,$CE,$CE,$CE,$CE,$CE,$CE
        .byte   $EE,$CE,$CE,$CE,$CE,$CE,$CE,$CE
        .byte   $F1,$E9,$E4,$E8,$F0,$DB,$CE,$CE
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
; ─── screen $23 ($8DC0) — Wily 3 boss corridor ───
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $C1,$F2,$E3,$3D,$3E,$C1,$C1,$C1
        .byte   $CE,$CE,$CE,$FA,$EF,$FB,$C2,$C2
        .byte   $CE,$CE,$BD,$FA,$F7,$F8,$E0,$E0
        .byte   $CE,$CE,$BD,$CE,$FB,$C9,$E0,$E0
        .byte   $EE,$FB,$E1,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
; ─── screen $24 ($8E00) ───
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
        .byte   $C1,$C1,$C1,$C1,$C1,$E3,$E1,$E0
        .byte   $C2,$C2,$C2,$C2,$C2,$CE,$E1,$E0
        .byte   $E0,$F3,$FD,$C4,$C1,$CE,$E1,$E0
        .byte   $E0,$F1,$01,$DE,$C2,$C2,$E1,$E0
        .byte   $A1,$A7,$01,$B0,$A1,$A1,$A1,$A1
        .byte   $A1,$A7,$01,$B0,$A1,$A1,$A1,$A1
; ─── screen $25 ($8E40) ───
        .byte   $A1,$A7,$01,$01,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
; ─── screen $26 ($8E80) ───
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$01,$01,$B0,$A1
        .byte   $A1,$A1,$A1,$A7,$FE,$FE,$B0,$A1
; ─── screen $27 ($8EC0) ───
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
; ─── screen $28 ($8F00) ───
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
; ─── screen $29 ($8F40) ───
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
        .byte   $01,$01,$01,$01,$01,$01,$BF,$BF
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
; CHR pattern data $9000-$AEFF (31 pages)
; Referenced by: Bubble Man CHR list, Wily 3 CHR list, Wily 4 CHR list, Wily 5 CHR list, Wood Man CHR list, bank00 overlay sets, bank01 overlay sets, bank02 overlay sets, bank03 overlay sets, bank04 overlay sets, bank05 overlay sets, bank07 overlay sets, group 4 (ending), group 6 (ending/weapon get)
; =============================================================================
        .byte   $00,$00,$07,$08,$13,$16,$10,$10,$00,$00,$00,$07,$0E,$0F,$0F,$0F
        .byte   $01,$03,$87,$E8,$1F,$CC,$1D,$39,$00,$01,$00,$07,$E0,$F0,$E0,$C0
        .byte   $F8,$C6,$81,$30,$C8,$05,$6D,$65,$00,$B8,$7E,$CF,$07,$03,$03,$03
        .byte   $00,$00,$00,$87,$BE,$CE,$DE,$9F,$00,$00,$00,$00,$01,$31,$21,$60
        .byte   $00,$00,$F0,$1C,$62,$39,$09,$01,$00,$00,$00,$E0,$FC,$FE,$FE,$FE
        .byte   $09,$06,$00,$00,$00,$00,$00,$00,$06,$00,$00,$00,$00,$00,$00,$00
        .byte   $30,$F1,$31,$11,$08,$0E,$09,$11,$C0,$00,$00,$00,$00,$00,$06,$0F
        .byte   $02,$01,$01,$02,$04,$38,$E0,$F8,$01,$00,$00,$01,$03,$07,$1F,$FF
        .byte   $9F,$9F,$8F,$46,$40,$21,$1E,$00,$60,$60,$70,$B9,$BF,$DE,$E1,$FF
        .byte   $C2,$D4,$38,$80,$80,$80,$40,$20,$3C,$28,$00,$00,$00,$00,$80,$C0
        .byte   $13,$27,$27,$2F,$2F,$7F,$FF,$FF,$0E,$1C,$1C,$18,$18,$08,$08,$09
        .byte   $FE,$FF,$FF,$FF,$FF,$FF,$9F,$FF,$07,$C1,$E0,$60,$00,$60,$6F,$8F
        .byte   $00,$00,$80,$80,$C0,$C1,$C7,$CF,$FF,$FF,$FF,$FF,$7F,$7E,$78,$70
        .byte   $20,$10,$10,$10,$10,$E0,$F0,$88,$C0,$E0,$E0,$E0,$E0,$00,$00,$70
        .byte   $00,$00,$00,$00,$01,$02,$04,$07,$00,$00,$00,$00,$00,$01,$03,$00
        .byte   $9F,$AF,$57,$63,$99,$30,$00,$FF,$67,$75,$3A,$1D,$7E,$FF,$FF,$00
        .byte   $FF,$FF,$FF,$FF,$FC,$7F,$20,$E0,$86,$80,$00,$83,$7F,$80,$C0,$00
        .byte   $DE,$9C,$B0,$20,$30,$E0,$40,$7F,$61,$E3,$CF,$DF,$CF,$1F,$3F,$00
        .byte   $28,$68,$D0,$30,$CC,$32,$01,$FF,$F0,$F0,$E0,$C0,$F0,$FC,$FE,$00
        .byte   $00,$01,$03,$07,$08,$07,$04,$05,$00,$00,$01,$00,$07,$00,$00,$00
        .byte   $00,$F8,$C6,$81,$30,$C8,$05,$6D,$00,$00,$B8,$7E,$CF,$07,$03,$03
        .byte   $00,$00,$00,$00,$80,$C0,$B0,$8F,$00,$00,$00,$00,$00,$00,$40,$70
        .byte   $00,$00,$00,$00,$00,$00,$00,$C0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$02,$05,$07,$0A,$08,$00,$00,$00,$01,$03,$03,$07,$07
        .byte   $19,$70,$F1,$71,$31,$38,$3E,$69,$00,$00,$00,$80,$C0,$C0,$C0,$86
        .byte   $65,$02,$01,$01,$02,$04,$38,$F8,$03,$01,$00,$00,$01,$03,$07,$3F
        .byte   $94,$AB,$A7,$47,$47,$47,$47,$23,$6F,$5C,$58,$B8,$B8,$B8,$B8,$DC
        .byte   $F0,$C8,$B4,$12,$1A,$89,$01,$01,$00,$30,$78,$FC,$FC,$7E,$FE,$FE
        .byte   $08,$04,$03,$00,$00,$00,$00,$00,$07,$03,$00,$00,$00,$00,$00,$00
        .byte   $33,$67,$A7,$2F,$2F,$7F,$FF,$FF,$CE,$9C,$1C,$1B,$1B,$0B,$08,$08
        .byte   $FE,$FF,$FF,$FF,$FF,$9F,$FF,$FF,$07,$01,$04,$0E,$8E,$6E,$60,$00
        .byte   $1F,$01,$80,$80,$C0,$C1,$C7,$CF,$E0,$FE,$FF,$FF,$7F,$7E,$78,$70
        .byte   $01,$82,$FC,$10,$10,$E0,$F0,$88,$FE,$7C,$00,$E0,$E0,$00,$00,$70
        .byte   $9F,$AF,$57,$63,$99,$30,$00,$FF,$64,$74,$3A,$1D,$7E,$FF,$FF,$00
        .byte   $FF,$FF,$FF,$FF,$FC,$7F,$20,$E0,$30,$38,$38,$83,$7F,$80,$C0,$00
        .byte   $33,$67,$A7,$2F,$2F,$7F,$FF,$FF,$CE,$9C,$1C,$18,$18,$08,$08,$09
        .byte   $00,$00,$00,$00,$00,$00,$62,$20,$00,$00,$00,$00,$00,$0C,$FE,$A4
        .byte   $06,$0F,$0E,$0E,$0E,$07,$01,$00,$06,$0F,$0E,$0E,$0E,$07,$01,$00
        .byte   $98,$FC,$FE,$FE,$FC,$F8,$C0,$00,$98,$FC,$FE,$FE,$FC,$F8,$C0,$00
        .byte   $00,$00,$00,$00,$00,$07,$18,$2E,$00,$00,$00,$00,$00,$00,$07,$1F
        .byte   $00,$00,$00,$00,$00,$E0,$18,$04,$00,$00,$00,$00,$00,$00,$E0,$F8
        .byte   $2E,$2C,$42,$77,$42,$40,$80,$FF,$1F,$1F,$3D,$08,$3D,$3F,$7F,$00
        .byte   $01,$01,$00,$7F,$00,$00,$00,$FF,$FE,$FE,$FF,$80,$FF,$FF,$FF,$00
        .byte   $00,$00,$80,$80,$80,$80,$40,$C0,$00,$00,$00,$00,$00,$00,$80,$00
        .byte   $00,$00,$07,$18,$2E,$5C,$58,$84,$00,$00,$00,$07,$1F,$3F,$3F,$7B
        .byte   $00,$00,$E0,$18,$04,$02,$02,$01,$00,$00,$00,$E0,$F8,$FC,$FC,$FE
        .byte   $77,$42,$40,$80,$FF,$2B,$40,$7F,$08,$3D,$3F,$7F,$00,$1C,$3F,$00
        .byte   $7F,$00,$00,$00,$FF,$E6,$C0,$FF,$80,$FF,$FF,$FF,$00,$1F,$3F,$00
        .byte   $07,$0C,$18,$30,$60,$00,$00,$00,$00,$03,$07,$0F,$1F,$3F,$1F,$0F
        .byte   $C7,$FF,$3F,$3F,$7F,$7F,$FF,$FF,$00,$06,$C8,$C0,$80,$8C,$1E,$19
        .byte   $E3,$FF,$FC,$FC,$FE,$FE,$FF,$FF,$00,$00,$03,$03,$01,$31,$78,$98
        .byte   $00,$01,$03,$06,$1C,$30,$00,$00,$0F,$0E,$1C,$19,$23,$0F,$01,$00
        .byte   $FF,$FF,$7E,$38,$17,$10,$2F,$61,$19,$0E,$80,$C0,$E0,$E0,$D0,$9E
        .byte   $C1,$81,$01,$01,$00,$00,$00,$00,$3E,$7E,$06,$02,$00,$00,$00,$00
        .byte   $00,$00,$00,$03,$07,$0F,$0F,$0F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $07,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$00,$06,$08,$00,$00,$0C,$0E,$19
        .byte   $E0,$F8,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$30,$70,$98
        .byte   $0F,$07,$07,$03,$03,$03,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$BF,$3E,$38,$37,$10,$1F,$11,$19,$4E,$C0,$C0,$C0,$E0,$E0,$6E
        .byte   $09,$08,$00,$00,$00,$00,$00,$00,$36,$11,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $07,$1F,$3F,$3F,$7F,$FF,$FF,$FF,$00,$06,$08,$00,$00,$0C,$0E,$09
        .byte   $E0,$F8,$FC,$FC,$FE,$FF,$FF,$FF,$00,$00,$00,$00,$00,$30,$70,$90
        .byte   $01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FE,$F8,$FF,$7C,$7F,$3C,$09,$06,$00,$00,$00,$00,$00,$03
        .byte   $1C,$06,$02,$00,$00,$00,$00,$00,$03,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$08,$1C,$1F,$0F,$03,$03,$03,$00,$00,$08,$0C,$03,$00,$01,$01
        .byte   $07,$1F,$3F,$7F,$7F,$FF,$FF,$FF,$00,$00,$07,$0F,$1C,$18,$10,$00
        .byte   $E0,$F8,$FC,$FE,$FE,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$08,$1C,$1F,$0F,$03,$07,$1F,$00,$00,$08,$0C,$03,$00,$01,$01
        .byte   $00,$00,$18,$7E,$81,$FF,$00,$00,$00,$00,$18,$7E,$81,$FF,$00,$00
        .byte   $00,$00,$18,$7E,$00,$3C,$00,$00,$00,$00,$18,$7E,$00,$3C,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$60
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$04,$08,$38,$31,$61,$C1,$03,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$A0,$A0,$60,$40,$C0,$80
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$00,$55,$FF,$FF,$FF,$FF,$00,$FF,$FF,$AA,$00,$00,$00,$00
        .byte   $00,$FF,$00,$55,$FF,$FF,$FF,$FF,$00,$FF,$FF,$AA,$00,$00,$00,$00
        .byte   $FF,$AA,$00,$00,$AA,$FF,$FF,$00,$00,$55,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $FF,$AA,$00,$00,$AA,$FF,$FF,$00,$00,$55,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$80,$E0,$F0,$F8,$FC,$FC,$FE,$00,$00,$80,$E0,$F0,$F8,$F8,$FC
        .byte   $3F,$3B,$3F,$1F,$17,$17,$17,$2F,$17,$17,$13,$08,$08,$08,$08,$10
        .byte   $FD,$FE,$FF,$FF,$FF,$FF,$FE,$FE,$C3,$81,$00,$00,$00,$00,$01,$01
        .byte   $FE,$FE,$7E,$64,$62,$4A,$DA,$94,$FC,$FC,$FC,$F8,$FC,$F4,$E4,$E8
        .byte   $2F,$2F,$77,$FF,$FF,$7F,$1F,$00,$10,$10,$08,$07,$00,$00,$00,$00
        .byte   $FD,$FD,$FD,$FD,$FE,$FF,$FF,$00,$03,$03,$7B,$83,$01,$00,$00,$00
        .byte   $94,$C8,$FE,$FF,$FF,$FE,$F8,$00,$E8,$B0,$D0,$E0,$C0,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$03,$05,$0F,$00,$00,$00,$00,$00,$01,$02,$04
        .byte   $00,$00,$0F,$7F,$FF,$FF,$FF,$FF,$00,$00,$00,$0F,$3F,$7F,$7F,$FF
        .byte   $00,$00,$F0,$FE,$E7,$E3,$F3,$FF,$00,$00,$00,$C0,$98,$BD,$BD,$D9
        .byte   $00,$00,$00,$00,$80,$C0,$E0,$E0,$00,$00,$00,$00,$00,$80,$C0,$C0
        .byte   $0F,$1F,$1F,$1F,$3F,$3F,$3F,$3F,$01,$07,$0F,$0F,$1F,$1F,$1F,$1F
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$EF,$C7,$FF,$FF,$FF,$FF,$FF,$83,$19,$3D
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E3,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $F0,$F8,$F8,$F8,$FC,$FC,$FC,$F4,$E0,$F0,$F0,$F0,$F8,$E0,$C8,$C8
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $07,$1F,$1F,$35,$15,$0A,$00,$3F,$08,$00,$20,$0A,$2A,$15,$0F,$03
        .byte   $8F,$FF,$FF,$FC,$F3,$C7,$1F,$FF,$50,$00,$00,$03,$0F,$3F,$FC,$E0
        .byte   $80,$E0,$F8,$78,$3C,$9C,$18,$90,$40,$10,$00,$84,$42,$A2,$87,$4F
        .byte   $0C,$08,$03,$06,$0D,$0D,$0D,$1F,$03,$04,$07,$02,$00,$04,$06,$03
        .byte   $FF,$30,$73,$AD,$26,$26,$FD,$EF,$38,$7C,$73,$21,$20,$20,$63,$EE
        .byte   $32,$02,$C6,$C7,$CE,$9E,$3A,$F8,$C9,$31,$C1,$C1,$C2,$82,$02,$00
        .byte   $00,$00,$C0,$40,$40,$80,$80,$00,$F0,$F8,$D8,$4C,$4C,$8C,$8C,$1C
        .byte   $3F,$7E,$7F,$FF,$FF,$FF,$FF,$7F,$00,$00,$80,$00,$00,$00,$00,$80
        .byte   $9F,$F3,$07,$FF,$1F,$3F,$FF,$FF,$80,$00,$08,$00,$E0,$C0,$00,$00
        .byte   $E0,$F0,$F8,$E0,$F0,$F0,$F0,$E0,$1C,$0E,$07,$1F,$0F,$0F,$0F,$1F
        .byte   $00,$00,$00,$60,$38,$0C,$08,$02,$18,$78,$10,$00,$80,$B0,$B0,$B0
        .byte   $7F,$3F,$17,$45,$60,$F0,$F8,$7E,$00,$40,$28,$1A,$87,$08,$07,$81
        .byte   $FF,$FF,$FF,$FF,$FC,$00,$00,$00,$00,$00,$00,$00,$03,$FF,$00,$FF
        .byte   $E0,$C0,$00,$00,$00,$00,$1E,$00,$1F,$3F,$FE,$FD,$F3,$8F,$21,$FF
        .byte   $0F,$18,$30,$07,$0F,$03,$06,$0E,$60,$66,$C9,$E0,$90,$AC,$39,$71
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10,$08,$0C,$04,$04
        .byte   $00,$01,$06,$09,$13,$27,$26,$45,$00,$01,$06,$09,$13,$27,$26,$44
        .byte   $7E,$81,$00,$C0,$E6,$B7,$4D,$BF,$7E,$81,$00,$C0,$E0,$82,$32,$40
        .byte   $00,$80,$60,$10,$08,$04,$04,$82,$00,$80,$60,$10,$08,$04,$04,$02
        .byte   $43,$C2,$C2,$E1,$72,$3F,$0F,$03,$41,$C1,$C1,$60,$31,$0C,$03,$00
        .byte   $CB,$A2,$87,$CD,$3F,$FD,$FF,$FF,$85,$25,$00,$82,$C8,$02,$FF,$00
        .byte   $82,$E3,$E3,$C7,$0E,$3C,$F0,$C0,$02,$03,$03,$06,$0C,$30,$C0,$00
        .byte   $00,$01,$01,$01,$02,$02,$02,$05,$00,$00,$00,$00,$01,$01,$01,$03
        .byte   $FF,$FF,$FF,$7E,$7E,$E7,$42,$00,$00,$18,$81,$E7,$C3,$81,$00,$00
        .byte   $06,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00,$00,$00,$00
        .byte   $07,$0B,$0B,$16,$14,$28,$30,$00,$00,$06,$07,$0E,$0C,$18,$10,$00
        .byte   $FF,$C7,$FF,$CC,$4C,$4C,$68,$68,$81,$7E,$00,$7C,$3C,$3C,$38,$38
        .byte   $E0,$F0,$B0,$58,$28,$14,$0C,$00,$00,$60,$E0,$70,$30,$18,$08,$00
        .byte   $28,$20,$30,$30,$00,$00,$00,$00,$18,$10,$10,$10,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$30,$58,$78,$30,$00,$00,$00,$00
        .byte   $30,$58,$78,$30,$00,$00,$00,$00,$30,$58,$78,$30,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$02,$02,$04,$00,$00,$00,$00,$00,$01,$01,$03
        .byte   $00,$00,$00,$C6,$29,$33,$27,$6F,$00,$00,$00,$00,$C6,$CE,$DE,$9E
        .byte   $04,$04,$04,$02,$07,$08,$13,$34,$03,$03,$03,$01,$00,$07,$0C,$08
        .byte   $6E,$5E,$DC,$DC,$D8,$70,$20,$90,$9C,$BC,$38,$38,$30,$A0,$C0,$60
        .byte   $28,$48,$56,$56,$20,$F8,$FD,$7E,$00,$00,$00,$00,$08,$5F,$0E,$38
        .byte   $51,$56,$58,$3C,$3E,$7E,$BE,$2C,$20,$21,$27,$4B,$DD,$9D,$0D,$13
        .byte   $F8,$06,$79,$1C,$04,$03,$07,$0F,$00,$F8,$FE,$FF,$FF,$FC,$FB,$F7
        .byte   $00,$00,$00,$80,$80,$C0,$A0,$70,$00,$00,$00,$00,$00,$00,$C0,$E0
        .byte   $38,$00,$00,$01,$03,$07,$0B,$09,$00,$00,$00,$00,$00,$03,$07,$07
        .byte   $20,$60,$E0,$F0,$F0,$F8,$F7,$D1,$1F,$1F,$5F,$CF,$0F,$C7,$A0,$A0
        .byte   $08,$0F,$0E,$1D,$7F,$FF,$7E,$3A,$F7,$F0,$F7,$EE,$80,$78,$F4,$F4
        .byte   $70,$70,$D0,$A0,$C0,$00,$00,$00,$E0,$E0,$60,$40,$00,$00,$00,$00
        .byte   $07,$00,$00,$01,$06,$08,$1F,$1F,$00,$00,$00,$00,$01,$07,$0F,$00
        .byte   $F8,$DC,$6F,$F5,$3C,$01,$FF,$FF,$00,$60,$30,$1B,$C3,$FE,$FD,$00
        .byte   $FF,$1B,$0D,$BE,$C7,$00,$FF,$FF,$00,$0C,$06,$03,$38,$FF,$FF,$00
        .byte   $00,$80,$E0,$B0,$AC,$02,$FF,$FF,$00,$00,$00,$60,$50,$FC,$FE,$00
        .byte   $00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00,$00,$01
        .byte   $00,$00,$00,$00,$00,$C6,$29,$33,$00,$00,$00,$00,$00,$00,$C6,$CE
        .byte   $02,$04,$04,$04,$04,$02,$07,$08,$01,$03,$03,$03,$03,$01,$00,$07
        .byte   $27,$6F,$6E,$5E,$DC,$DC,$D8,$70,$DE,$9E,$9C,$BC,$38,$38,$30,$A0
        .byte   $13,$34,$28,$48,$56,$56,$20,$B8,$0C,$08,$00,$00,$00,$00,$08,$1F
        .byte   $20,$90,$51,$56,$58,$3C,$3E,$7E,$C0,$60,$20,$21,$27,$4B,$DD,$9D
        .byte   $00,$00,$F8,$06,$79,$1C,$04,$03,$00,$00,$00,$F8,$FE,$FF,$FF,$FC
        .byte   $00,$00,$00,$00,$00,$80,$80,$C0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FD,$7E,$38,$00,$00,$03,$07,$0B,$0E,$38,$00,$00,$00,$00,$03,$07
        .byte   $BE,$2C,$20,$60,$E0,$F0,$F0,$F9,$0D,$13,$1F,$1F,$5F,$0F,$CF,$A6
        .byte   $07,$0F,$08,$0F,$1E,$7D,$FF,$7F,$FB,$F7,$F7,$F0,$EF,$82,$78,$F4
        .byte   $A0,$70,$70,$70,$D0,$A0,$C0,$00,$C0,$E0,$E0,$E0,$60,$40,$00,$00
        .byte   $09,$0F,$00,$01,$06,$08,$1F,$1F,$07,$00,$00,$00,$01,$07,$0F,$00
        .byte   $DF,$F0,$DF,$F5,$3C,$01,$FF,$FF,$A0,$00,$60,$1B,$C3,$FE,$FD,$00
        .byte   $3A,$FE,$1B,$BE,$C7,$00,$FF,$FF,$F4,$00,$0C,$03,$38,$FF,$FF,$00
        .byte   $00,$00,$E0,$B0,$AC,$02,$FF,$FF,$00,$00,$00,$60,$50,$FC,$FE,$00
        .byte   $00,$00,$01,$02,$07,$08,$13,$34,$00,$00,$00,$01,$00,$07,$0C,$08
        .byte   $77,$8C,$31,$EF,$DF,$7F,$27,$90,$00,$73,$CF,$1F,$3F,$A7,$C0,$60
        .byte   $E0,$10,$F8,$F0,$E0,$C0,$00,$00,$00,$E0,$F0,$E0,$C0,$00,$00,$00
        .byte   $38,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $20,$20,$20,$30,$30,$78,$6E,$CD,$1F,$1F,$1F,$0F,$0F,$37,$31,$70
        .byte   $0F,$0E,$08,$07,$07,$0E,$0D,$F9,$F7,$F7,$F7,$F8,$FB,$F7,$F6,$0E
        .byte   $70,$70,$50,$20,$C0,$C0,$80,$80,$E0,$E0,$E0,$C0,$00,$00,$00,$00
        .byte   $3E,$7F,$BF,$9D,$7E,$1B,$1D,$1D,$00,$3C,$7A,$7A,$00,$0C,$06,$06
        .byte   $07,$0F,$17,$13,$0F,$C3,$63,$53,$00,$07,$0F,$0F,$00,$01,$C1,$A0
        .byte   $C0,$E0,$E0,$A0,$C0,$78,$AC,$AA,$00,$80,$40,$40,$00,$80,$D8,$D4
        .byte   $2F,$4E,$40,$80,$81,$87,$FE,$78,$10,$31,$3F,$7F,$7F,$7E,$78,$00
        .byte   $15,$38,$68,$D0,$90,$10,$1F,$0F,$E2,$E7,$C7,$8F,$0F,$0F,$0F,$00
        .byte   $E2,$06,$0C,$18,$30,$E0,$C0,$00,$1C,$FC,$F8,$F0,$E0,$C0,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$80,$00,$06,$2F,$6F,$53,$53,$2E,$80,$00
        .byte   $0F,$11,$21,$21,$42,$4C,$B0,$C0,$00,$0E,$1E,$1E,$3C,$30,$40,$00
        .byte   $00,$00,$00,$10,$38,$78,$7C,$F8,$00,$00,$00,$00,$10,$20,$38,$40
        .byte   $07,$0B,$15,$1D,$1F,$1F,$0F,$17,$00,$04,$0E,$02,$08,$08,$07,$08
        .byte   $78,$A4,$43,$3E,$FE,$FE,$FC,$78,$00,$78,$FC,$C1,$0D,$8D,$7B,$87
        .byte   $00,$00,$00,$C0,$30,$08,$C4,$E2,$00,$00,$00,$00,$C0,$F0,$38,$5C
        .byte   $20,$20,$10,$0F,$1F,$3F,$5F,$60,$1F,$1F,$0F,$00,$00,$00,$20,$3F
        .byte   $03,$1F,$FF,$FE,$FD,$FB,$E7,$1F,$FC,$E0,$00,$01,$03,$07,$1F,$FF
        .byte   $A1,$44,$62,$E3,$E1,$F0,$F8,$FC,$5E,$BF,$DF,$DF,$DF,$DF,$DF,$DF
        .byte   $00,$80,$40,$40,$20,$20,$10,$10,$00,$00,$80,$80,$C0,$C0,$E0,$E0
        .byte   $FF,$FF,$FF,$FF,$7F,$7F,$3F,$3F,$7F,$7F,$7F,$7F,$3F,$3F,$1F,$1F
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
        .byte   $FC,$FE,$FE,$FF,$FF,$8E,$AE,$AE,$DF,$BF,$BF,$BE,$8C,$75,$55,$55
        .byte   $10,$08,$E8,$98,$08,$74,$74,$74,$E0,$F0,$10,$60,$F0,$88,$C8,$88
        .byte   $1F,$0F,$07,$03,$03,$1C,$20,$3F,$0F,$07,$01,$00,$00,$03,$1F,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$78,$C0,$FF,$FE,$FD,$FB,$76,$00,$87,$3F,$00
        .byte   $8E,$FF,$BF,$BF,$FF,$F9,$30,$FF,$75,$0C,$5E,$5F,$38,$07,$CF,$00
        .byte   $04,$68,$D8,$F8,$CC,$C2,$01,$FF,$F8,$90,$20,$80,$30,$FC,$FE,$00
        .byte   $1F,$0F,$07,$03,$1C,$20,$3F,$00,$0F,$07,$01,$00,$03,$1F,$00,$00
        .byte   $FF,$FF,$FF,$FF,$78,$C0,$FF,$00,$FE,$FD,$FB,$70,$87,$3F,$00,$00
        .byte   $8E,$FF,$BF,$BF,$F9,$30,$FF,$00,$75,$0C,$5E,$58,$07,$CF,$00,$00
        .byte   $04,$68,$F8,$CC,$C2,$01,$FF,$00,$F8,$90,$00,$30,$FC,$FE,$00,$00
        .byte   $20,$20,$10,$0F,$0F,$0F,$0F,$1F,$1F,$1F,$0F,$00,$00,$00,$00,$00
        .byte   $03,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$E0,$00,$00,$00,$00,$00,$00
        .byte   $A1,$C4,$E2,$A3,$A1,$B0,$78,$7C,$5E,$3F,$1F,$5F,$5F,$5F,$DF,$DF
        .byte   $3F,$7F,$BF,$BF,$C0,$FF,$7F,$7F,$00,$00,$40,$40,$7F,$7F,$3F,$3F
        .byte   $FE,$FD,$FB,$E7,$1F,$FF,$FF,$FF,$01,$03,$07,$1F,$FF,$FF,$FF,$FE
        .byte   $FC,$FE,$FE,$FF,$FF,$8E,$AE,$AE,$DF,$BF,$BF,$BE,$8C,$75,$55,$55
        .byte   $3F,$1F,$0F,$07,$1D,$20,$3F,$00,$1F,$0F,$07,$01,$02,$1F,$00,$00
        .byte   $FF,$FF,$FF,$FF,$F8,$C0,$FF,$00,$FE,$FD,$FB,$F0,$07,$3F,$00,$00
        .byte   $20,$20,$10,$0F,$07,$07,$07,$07,$1F,$1F,$0F,$00,$00,$00,$00,$00
        .byte   $03,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FC,$E0,$00,$00,$00,$00,$00,$00
        .byte   $A1,$C4,$C2,$C3,$E1,$D0,$D8,$BC,$5E,$3F,$3F,$3F,$1F,$2F,$2F,$6F
        .byte   $0F,$0F,$0F,$1F,$1F,$3F,$7F,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FE,$FE,$FD,$FB,$F7,$00,$00,$00,$01,$01,$03,$07,$0F
        .byte   $BC,$7E,$7E,$FF,$FF,$8E,$AE,$AE,$6F,$EF,$DF,$DE,$8C,$75,$55,$55
        .byte   $BF,$40,$7F,$3F,$1F,$1F,$23,$3F,$40,$3F,$3F,$1F,$0F,$03,$1C,$00
        .byte   $CF,$3F,$FF,$FF,$FF,$F8,$E0,$FF,$3F,$FF,$FE,$FC,$F8,$E7,$1F,$00
        .byte   $07,$0B,$11,$15,$15,$19,$0F,$17,$00,$04,$0E,$0E,$0E,$06,$00,$08
        .byte   $78,$84,$23,$62,$42,$8E,$FC,$78,$00,$78,$FC,$FD,$FD,$71,$03,$87
        .byte   $18,$34,$72,$82,$F1,$F9,$7D,$3E,$00,$18,$1C,$7C,$0E,$7E,$36,$00
        .byte   $18,$34,$72,$82,$F9,$79,$7D,$3C,$00,$18,$1C,$7C,$06,$0E,$36,$03
        .byte   $08,$F4,$4A,$6A,$44,$00,$00,$00,$00,$08,$04,$04,$00,$00,$00,$00
        .byte   $FF,$81,$BD,$A5,$A5,$BD,$81,$FF,$FE,$FE,$FA,$FA,$FA,$C2,$FE,$00
        .byte   $00,$03,$01,$00,$00,$00,$00,$00,$FF,$7F,$3F,$07,$00,$00,$00,$00
        .byte   $00,$F8,$E0,$00,$00,$00,$00,$00,$FF,$FE,$FC,$E0,$00,$00,$00,$00
        .byte   $00,$00,$03,$01,$00,$00,$00,$00,$7F,$3F,$0F,$03,$01,$00,$00,$00
        .byte   $00,$03,$01,$01,$01,$01,$03,$03,$1F,$0F,$03,$01,$01,$03,$03,$07
        .byte   $00,$C0,$80,$00,$00,$00,$00,$00,$F8,$F0,$C0,$80,$80,$C0,$C0,$E0
        .byte   $03,$01,$00,$00,$00,$00,$00,$00,$07,$03,$01,$00,$00,$00,$00,$00
        .byte   $00,$80,$00,$00,$00,$00,$00,$00,$E0,$C0,$80,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$02,$04,$04,$00,$00,$00,$00,$00,$01,$03,$03
        .byte   $30,$48,$64,$A2,$F2,$09,$05,$05,$00,$30,$38,$7C,$0C,$86,$02,$02
        .byte   $04,$02,$03,$05,$05,$04,$07,$07,$03,$01,$00,$03,$03,$03,$00,$00
        .byte   $05,$09,$F1,$1D,$9D,$9D,$9D,$DD,$02,$86,$0E,$E2,$EA,$E2,$6A,$22
        .byte   $C0,$C6,$4F,$C0,$00,$C0,$C0,$4F,$07,$8F,$9F,$07,$00,$00,$8F,$9F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$F0,$80,$00,$00,$00,$80,$F0
        .byte   $03,$02,$02,$02,$01,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00,$00
        .byte   $23,$DE,$C6,$64,$0E,$F9,$D1,$99,$DC,$E0,$F8,$F8,$F0,$06,$3E,$7E
        .byte   $C0,$00,$00,$00,$00,$00,$00,$C0,$07,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$70,$8E,$00,$00,$00,$00,$00,$00,$00,$70
        .byte   $43,$3E,$04,$02,$01,$00,$00,$00,$3C,$01,$03,$01,$00,$00,$00,$00
        .byte   $21,$92,$DC,$37,$F3,$3C,$00,$00,$C0,$E1,$E3,$CD,$0C,$00,$00,$00
        .byte   $07,$1E,$78,$E0,$80,$00,$00,$00,$FE,$F8,$E0,$80,$00,$00,$00,$00
        .byte   $C0,$DC,$40,$C0,$00,$C0,$FC,$40,$1C,$BF,$9E,$08,$00,$0C,$BE,$9C
        .byte   $C0,$00,$00,$00,$00,$00,$00,$C0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$0E,$1F,$3F,$00,$00,$00,$00,$00,$0E,$1F,$3F
        .byte   $00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,$00,$00,$00,$00,$80
        .byte   $FF,$FF,$7F,$FF,$1E,$FF,$FF,$7F,$3F,$BF,$BF,$3F,$1E,$3F,$BF,$BF
        .byte   $80,$80,$80,$00,$00,$00,$80,$80,$80,$80,$80,$00,$00,$00,$80,$80
        .byte   $FF,$3F,$1F,$0E,$00,$00,$00,$C0,$3F,$3F,$1F,$0E,$00,$00,$00,$00
        .byte   $80,$80,$00,$00,$00,$00,$70,$8E,$80,$80,$00,$00,$00,$00,$00,$70
        .byte   $00,$00,$00,$00,$00,$00,$03,$04,$00,$00,$00,$00,$00,$00,$00,$03
        .byte   $00,$00,$00,$18,$24,$54,$F4,$34,$00,$00,$00,$00,$18,$38,$38,$D8
        .byte   $08,$08,$0C,$14,$2A,$59,$71,$73,$06,$04,$00,$08,$1C,$3E,$1E,$0D
        .byte   $34,$12,$12,$12,$22,$C4,$CC,$CE,$08,$0C,$0C,$0C,$1C,$38,$B0,$34
        .byte   $77,$4B,$A4,$B7,$B1,$47,$3E,$09,$0A,$34,$7B,$78,$7E,$38,$01,$07
        .byte   $94,$28,$F0,$A0,$40,$81,$5E,$32,$68,$C0,$20,$40,$00,$00,$81,$CD
        .byte   $0E,$11,$20,$43,$8F,$BC,$F0,$80,$00,$0E,$1F,$3F,$7C,$70,$80,$00
        .byte   $00,$E0,$E0,$C0,$00,$00,$00,$00,$00,$00,$C0,$00,$00,$00,$00,$00
        .byte   $09,$04,$03,$00,$00,$00,$00,$00,$07,$03,$00,$00,$00,$00,$00,$00
        .byte   $AB,$62,$9C,$00,$00,$00,$00,$00,$DC,$9C,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$30,$30,$00,$00,$00,$00,$70,$F8,$C8,$C8,$70,$00,$00,$00
        .byte   $03,$0F,$78,$E0,$80,$00,$00,$07,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $F8,$01,$3F,$FF,$FF,$FF,$FC,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $F1,$02,$04,$04,$08,$11,$E7,$1F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $7F,$FE,$FC,$FD,$F2,$8C,$11,$6E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $83,$07,$1F,$3C,$70,$C0,$83,$0C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $10,$23,$44,$88,$31,$C6,$38,$C1,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FC,$F0,$83,$0C,$30,$C3,$0C,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $C1,$03,$0C,$F1,$07,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $03,$07,$1F,$3C,$70,$C0,$83,$0C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $C9,$5B,$F7,$FD,$77,$7B,$33,$00,$FF,$FF,$FF,$FF,$77,$7B,$33,$00
        .byte   $FC,$F0,$83,$0C,$30,$C3,$0C,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $C1,$83,$5E,$35,$7E,$B5,$CA,$80,$FF,$FF,$FF,$7F,$7E,$B5,$CA,$80
        .byte   $7F,$FF,$FC,$FB,$F7,$EF,$1F,$3F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $CF,$F0,$60,$40,$80,$80,$80,$00,$C0,$F0,$EE,$DF,$BF,$BE,$BC,$7C
        .byte   $CF,$3E,$FE,$FD,$FB,$FB,$E7,$DE,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $B8,$67,$1C,$18,$0B,$07,$03,$03,$00,$07,$1F,$9F,$CF,$67,$23,$33
        .byte   $7F,$FF,$FC,$FB,$F7,$EF,$1F,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $07,$F8,$60,$C0,$80,$80,$00,$02,$00,$F8,$E0,$DF,$BF,$BC,$78,$7A
        .byte   $CF,$3E,$FE,$FD,$FB,$FB,$E7,$DE,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $BD,$7B,$67,$1F,$3E,$1D,$1B,$07,$00,$00,$00,$00,$80,$C0,$40,$60
        .byte   $7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $7F,$BF,$BF,$BF,$5F,$CF,$8F,$07,$7F,$3F,$3F,$3F,$1F,$0F,$0F,$07
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $01,$01,$01,$01,$80,$80,$C0,$C0,$7D,$7D,$7D,$7D,$BE,$BE,$DF,$DF
        .byte   $E0,$F0,$F8,$FF,$FF,$FE,$FC,$F0,$EF,$F7,$F8,$FF,$FF,$FE,$FC,$F0
        .byte   $03,$01,$01,$01,$01,$01,$13,$03,$13,$11,$11,$11,$11,$11,$33,$E3
        .byte   $07,$30,$60,$C1,$86,$05,$0B,$17,$C7,$B0,$60,$C0,$80,$00,$00,$00
        .byte   $02,$03,$03,$01,$80,$80,$C0,$E0,$7A,$7B,$7B,$7D,$BC,$BE,$DF,$EF
        .byte   $C0,$0F,$70,$88,$78,$C6,$BF,$7F,$C0,$0F,$07,$03,$01,$00,$00,$00
        .byte   $0F,$0E,$0E,$0D,$0B,$2B,$47,$B6,$20,$20,$20,$20,$20,$60,$C0,$B0
        .byte   $75,$3B,$1B,$1B,$0C,$0D,$05,$86,$70,$F8,$F8,$F8,$FC,$FC,$7C,$0E
        .byte   $00,$FF,$FF,$04,$FB,$00,$7F,$00,$FB,$04,$04,$FF,$FB,$00,$00,$7F
        .byte   $00,$C7,$BC,$30,$67,$CF,$94,$A3,$00,$C7,$FF,$FF,$FF,$FF,$F7,$EF
        .byte   $38,$BB,$B9,$38,$BB,$38,$BA,$02,$83,$00,$02,$83,$83,$00,$03,$BB
        .byte   $00,$01,$83,$BB,$BB,$47,$FF,$FC,$38,$39,$BB,$BB,$BB,$C7,$FF,$FD
        .byte   $7F,$FF,$FC,$FB,$F7,$EF,$1F,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FE,$F1,$8F,$78,$C7,$BF,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $CF,$3E,$FE,$FD,$FB,$FB,$E7,$DE,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $BD,$7B,$E7,$1F,$FE,$FD,$FB,$F7,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$E0,$FE,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FE,$F1,$8F,$78,$C7,$BF,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$06,$1D,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $BD,$7B,$E7,$1F,$FE,$FD,$FB,$F7,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7F,$FF,$FC,$FB,$F7,$EF,$1F,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FE,$F9,$F7,$8F,$5F,$DF,$BF,$3F,$00,$01,$07,$0F,$1F,$1F,$3F,$3F
        .byte   $CF,$3E,$FE,$FD,$FB,$FB,$E7,$80,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7F,$F8,$FC,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $7F,$FF,$FC,$FB,$F7,$EF,$1F,$E1,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $9E,$47,$83,$1F,$7F,$FF,$FF,$00,$1E,$7F,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $CF,$3E,$FE,$FC,$F8,$F9,$E0,$80,$00,$00,$00,$00,$00,$03,$07,$1F
        .byte   $00,$01,$83,$C7,$C2,$D1,$D9,$01,$7F,$7F,$BF,$DF,$C2,$D8,$D8,$00
        .byte   $03,$08,$0C,$0D,$0B,$9B,$D7,$CF,$23,$38,$7C,$7C,$38,$98,$D0,$C0
        .byte   $DF,$DE,$B0,$0C,$78,$C0,$B8,$78,$C0,$C0,$80,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$00,$FD,$FB,$FB,$E7,$DE,$FF,$FF,$00,$00,$00,$00,$00,$00
        .byte   $80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $C0,$00,$C0,$C0,$80,$80,$00,$01,$C0,$00,$00,$00,$00,$00,$00,$00
        .byte   $03,$0E,$11,$0F,$18,$07,$0F,$0F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $0F,$3E,$3E,$7D,$7B,$FB,$E7,$DE,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $BD,$7B,$E7,$1F,$FE,$FD,$FB,$F7,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7F,$FF,$FC,$FB,$F7,$EE,$1E,$F8,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $E7,$D8,$B0,$A7,$6F,$7F,$7F,$00,$07,$1F,$3F,$3F,$7F,$7F,$7F,$00
        .byte   $86,$00,$80,$05,$05,$05,$0D,$0A,$06,$30,$38,$7C,$7C,$FC,$FC,$78
        .byte   $99,$ED,$75,$F9,$FC,$F8,$FA,$00,$98,$EC,$F4,$F8,$FC,$FA,$FA,$00
        .byte   $00,$00,$00,$06,$16,$16,$16,$10,$1B,$5F,$7F,$79,$69,$69,$69,$69
        .byte   $16,$10,$16,$00,$13,$53,$00,$00,$68,$68,$68,$0F,$48,$08,$5B,$4B
        .byte   $00,$00,$C0,$E0,$00,$E0,$00,$00,$40,$E4,$36,$16,$16,$16,$00,$FE
        .byte   $E8,$E8,$E8,$00,$30,$30,$00,$00,$16,$16,$16,$E0,$8A,$8A,$BA,$30
        .byte   $00,$FA,$FA,$A8,$00,$00,$FF,$FF,$FF,$05,$05,$52,$FA,$00,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$FF,$FF,$AA,$00,$00,$FF,$FF,$FF,$00,$00,$55,$FF,$00,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$01,$00,$01,$00,$00,$00,$00,$07,$02,$07,$02,$07,$00,$05,$00
        .byte   $00,$01,$00,$01,$00,$01,$00,$00,$03,$06,$03,$06,$03,$06,$03,$06
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$E8,$F0,$E8,$F0,$E8,$00,$E0,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$F0,$E8,$F0,$E8,$F0,$E8,$B0,$48
        .byte   $01,$02,$02,$04,$08,$13,$10,$22,$48,$25,$14,$0A,$85,$48,$6B,$55
        .byte   $24,$24,$48,$20,$10,$89,$4A,$00,$13,$0B,$A6,$46,$AB,$54,$94,$DE
        .byte   $00,$20,$40,$88,$08,$14,$A4,$44,$80,$10,$28,$41,$96,$A2,$02,$22
        .byte   $62,$22,$B2,$B2,$9A,$9A,$92,$14,$04,$DC,$4D,$4D,$65,$45,$6D,$EB
        .byte   $EF,$F6,$F7,$3E,$A2,$34,$58,$8B,$FF,$FD,$BE,$D4,$D8,$C1,$83,$B0
        .byte   $23,$E7,$D4,$46,$80,$20,$01,$0A,$54,$58,$2B,$B0,$57,$95,$EA,$D4
        .byte   $F7,$FB,$6B,$67,$ED,$62,$62,$56,$F7,$F3,$F3,$F3,$41,$CB,$99,$84
        .byte   $15,$1C,$39,$32,$22,$A5,$02,$91,$A7,$C3,$84,$C9,$DD,$4A,$95,$2A
        .byte   $00,$00,$00,$00,$01,$40,$20,$10,$00,$00,$31,$0A,$02,$04,$04,$00
        .byte   $08,$88,$44,$24,$52,$4A,$8A,$00,$02,$21,$A8,$4A,$24,$95,$55,$FF
        .byte   $00,$00,$00,$00,$00,$80,$48,$50,$00,$04,$08,$08,$10,$10,$01,$02
        .byte   $10,$20,$22,$62,$44,$44,$98,$80,$44,$14,$88,$88,$28,$18,$42,$5A
        .byte   $8A,$D1,$40,$08,$CE,$A3,$67,$E2,$54,$0C,$9B,$D6,$21,$54,$90,$1C
        .byte   $98,$16,$36,$14,$31,$2A,$82,$C1,$24,$41,$C8,$EA,$46,$85,$19,$3A
        .byte   $C1,$8D,$8B,$09,$90,$08,$19,$50,$1C,$50,$30,$74,$2B,$57,$E2,$AD
        .byte   $E7,$CD,$67,$4E,$84,$80,$28,$42,$18,$12,$98,$A0,$53,$35,$43,$94
        .byte   $0A,$D1,$40,$08,$4A,$A0,$24,$40,$D5,$2C,$9B,$76,$A1,$57,$99,$AE
        .byte   $98,$14,$25,$10,$20,$2A,$82,$41,$27,$41,$DA,$EE,$57,$C5,$59,$BA
        .byte   $40,$04,$00,$09,$10,$00,$09,$00,$1C,$D9,$BB,$64,$AB,$5E,$F2,$AD
        .byte   $00,$48,$01,$00,$00,$80,$08,$42,$FB,$96,$FC,$AE,$D7,$34,$63,$94
        .byte   $8A,$D1,$40,$08,$C6,$81,$22,$40,$55,$2C,$9B,$F6,$29,$76,$9D,$BE
        .byte   $88,$02,$20,$14,$21,$00,$02,$00,$35,$55,$DF,$EA,$56,$ED,$59,$FB
        .byte   $40,$80,$88,$00,$90,$00,$09,$00,$9D,$55,$32,$7D,$2B,$57,$F2,$DD
        .byte   $20,$04,$00,$08,$04,$00,$08,$02,$D7,$59,$FB,$A4,$D3,$B5,$63,$D4
        .byte   $09,$48,$4C,$56,$80,$23,$04,$52,$52,$05,$A0,$89,$17,$88,$69,$A0
        .byte   $10,$28,$10,$00,$00,$00,$00,$00,$AA,$13,$48,$56,$23,$2C,$05,$91
        .byte   $99,$1D,$33,$3A,$2A,$11,$08,$42,$44,$20,$CC,$41,$91,$AC,$56,$A5
        .byte   $24,$C4,$A0,$20,$90,$08,$08,$00,$DB,$11,$52,$C6,$2D,$D4,$92,$24
        .byte   $02,$0A,$28,$08,$12,$04,$18,$20,$94,$00,$02,$24,$48,$41,$80,$D2
        .byte   $00,$00,$01,$00,$00,$00,$00,$00,$61,$AA,$4A,$C4,$D1,$9D,$6B,$CA
        .byte   $09,$09,$15,$54,$40,$27,$08,$62,$90,$B6,$28,$8A,$97,$40,$07,$11
        .byte   $64,$80,$00,$00,$00,$00,$00,$00,$01,$28,$13,$99,$58,$EA,$51,$7B
        .byte   $19,$48,$20,$29,$80,$15,$40,$82,$86,$B2,$1E,$44,$56,$60,$AA,$58
        .byte   $04,$52,$02,$00,$00,$00,$00,$00,$70,$A0,$48,$40,$90,$05,$02,$08
        .byte   $00,$00,$C0,$30,$00,$84,$80,$00,$98,$A1,$10,$4C,$09,$00,$4B,$65
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$23,$56,$0B,$91,$58,$6A,$51,$3B
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$FB
        .byte   $F7,$F7,$F3,$FC,$DC,$D7,$C1,$A0,$FB,$F9,$FC,$FB,$FB,$FC,$FC,$D7
        .byte   $FF,$FF,$FF,$FF,$EF,$FF,$DD,$C9,$FF,$FF,$FF,$FB,$F9,$E4,$E4,$F2
        .byte   $83,$B1,$D1,$90,$08,$10,$98,$0A,$38,$0A,$0C,$2E,$D5,$EA,$47,$B5
        .byte   $FF,$FF,$FF,$3F,$3B,$EB,$83,$05,$FF,$9F,$DF,$DF,$DF,$3F,$3F,$EB
        .byte   $05,$4A,$E5,$C6,$94,$A5,$24,$88,$BA,$12,$14,$39,$61,$4A,$DA,$56
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$BF,$FF,$FF,$FF,$FF,$FF,$FF,$9F,$7F
        .byte   $BF,$BF,$7F,$FF,$F7,$FF,$BB,$93,$7F,$7F,$FF,$DF,$9F,$27,$27,$4F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$20,$42,$11,$01,$00,$06,$08,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$D1,$82,$4A,$21,$24,$46,$94,$02
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$11,$08,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$8B,$41,$56,$80,$24,$63,$29,$45
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$49,$A4,$A2,$20,$02,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$04,$52,$88,$88,$40,$20,$00,$C0
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$30,$10,$10,$00,$00,$00,$00,$00
        .byte   $BF,$DF,$BB,$7F,$6C,$1A,$3F,$5E,$BF,$DF,$BB,$7F,$6F,$1F,$3F,$5F
        .byte   $EA,$FB,$76,$3E,$ED,$7E,$3A,$55,$FF,$FF,$7F,$3F,$EF,$7F,$3F,$5F
        .byte   $FC,$F0,$83,$4C,$30,$C3,$8C,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $81,$43,$0C,$F1,$07,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $83,$07,$1F,$3C,$70,$C0,$83,$0C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $10,$23,$44,$88,$31,$C6,$38,$C1,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FE,$FF,$DC,$AE,$3C,$DE,$2E,$BF,$FE,$FF,$FC,$FE,$FC,$FE,$FE,$FF
        .byte   $EF,$5E,$7C,$F6,$1D,$BA,$EC,$F8,$FF,$FE,$FC,$FE,$FD,$FA,$EC,$F8
        .byte   $F3,$67,$DF,$F8,$70,$B8,$77,$6E,$FF,$7F,$FF,$FF,$7F,$FF,$7F,$7F
        .byte   $BD,$3F,$F7,$BF,$57,$45,$23,$00,$BF,$7F,$FF,$BF,$57,$45,$23,$00
        .byte   $EE,$D7,$BD,$36,$3F,$DD,$36,$6C,$FE,$FF,$FD,$FE,$FF,$FD,$F6,$FC
        .byte   $DE,$B3,$CE,$7A,$A9,$C1,$88,$80,$FE,$B3,$CE,$7A,$A9,$C1,$88,$80
        .byte   $63,$C7,$FF,$7C,$30,$D0,$E3,$EC,$7F,$FF,$FF,$7F,$3F,$FF,$FF,$FF
        .byte   $50,$F3,$A4,$48,$F1,$46,$F8,$61,$7F,$FF,$FF,$7F,$FF,$7F,$FF,$7F
        .byte   $FB,$F6,$83,$0E,$34,$DE,$0F,$3F,$FF,$FE,$FF,$FE,$FC,$FE,$FF,$FF
        .byte   $D6,$1C,$39,$DF,$2A,$1F,$FC,$FF,$FE,$FC,$F9,$FF,$FE,$FF,$FC,$FF
        .byte   $83,$07,$1F,$3C,$70,$C0,$83,$0C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $10,$A3,$C4,$88,$F1,$C6,$78,$C1,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$FF
        .byte   $FC,$F0,$83,$0C,$30,$C3,$0C,$30,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $C1,$03,$0C,$F1,$07,$3D,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FD,$FE,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$54,$4A,$8D,$34,$2A,$15,$A4,$18
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$45,$92,$12,$24,$A1,$04,$40,$08
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$19,$B5,$3C,$EA,$55,$55,$1B,$93
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$C5,$6E,$26,$42,$52,$00,$40,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$54,$4A,$8D,$34,$AA,$15,$B4,$D8
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$55,$AA,$46,$64,$D1,$95,$6B,$D9
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$19,$B5,$3C,$EA,$55,$55,$3B,$93
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$E5,$6E,$1B,$89,$58,$E2,$41,$2B
        .byte   $EF,$B4,$C7,$6E,$80,$24,$50,$8B,$FB,$FF,$AE,$C4,$FA,$D1,$8B,$B0
        .byte   $02,$E7,$94,$46,$80,$20,$01,$0A,$75,$58,$6B,$B0,$57,$95,$EA,$D4
        .byte   $37,$B3,$23,$63,$E1,$62,$62,$56,$B7,$7B,$FB,$B7,$4D,$CB,$99,$84
        .byte   $15,$14,$20,$00,$23,$A5,$00,$91,$A7,$CB,$9D,$FB,$DD,$4A,$97,$2A
        .byte   $90,$00,$03,$1B,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $21,$00,$30,$7A,$FA,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$BF,$BF,$3C,$5C,$0A,$08,$00,$FF,$BF,$BF,$3C,$5C,$0A,$08,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FD,$FF,$ED,$E4,$A0,$08,$00,$80,$FD,$FF,$ED,$E4,$A0,$08,$00,$80
        .byte   $7F,$DF,$A7,$C7,$E7,$E3,$C3,$C2,$F8,$FF,$CF,$CF,$FF,$FF,$FF,$DE
        .byte   $C2,$C0,$80,$80,$A0,$80,$00,$00,$7E,$7F,$7F,$7F,$4F,$4F,$FF,$00
        .byte   $FF,$FF,$FF,$FF,$F3,$F3,$B1,$A0,$14,$FF,$FF,$FF,$FB,$F7,$BF,$EF
        .byte   $20,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $FF,$FF,$FF,$FB,$BB,$31,$11,$01,$30,$FF,$FF,$FB,$FB,$FF,$F7,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $FC,$F6,$FA,$D2,$DE,$9E,$96,$86,$9E,$FE,$F2,$F2,$DE,$BE,$BE,$FE
        .byte   $84,$80,$00,$00,$08,$00,$00,$00,$FC,$FE,$FE,$FE,$F2,$F2,$FE,$00
        .byte   $E6,$E4,$E6,$E4,$A6,$26,$06,$00,$29,$EB,$E9,$EB,$E9,$EB,$EF,$E0
        .byte   $06,$0F,$0F,$0D,$06,$0C,$06,$04,$EF,$EF,$EF,$EF,$E9,$EB,$E9,$0B
        .byte   $3C,$36,$3A,$12,$1E,$1E,$16,$06,$1E,$3E,$32,$32,$1E,$3E,$3E,$3E
        .byte   $04,$00,$00,$00,$08,$00,$00,$00,$3C,$3E,$3E,$3E,$32,$32,$3E,$00
        .byte   $18,$18,$18,$18,$18,$18,$18,$18,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3
        .byte   $18,$18,$18,$00,$18,$18,$18,$18,$C3,$C3,$C3,$C3,$DB,$D3,$C3,$C3
        .byte   $18,$18,$18,$00,$18,$18,$18,$18,$C3,$C3,$C3,$C3,$DB,$D3,$C3,$C3
        .byte   $18,$18,$18,$18,$18,$18,$18,$18,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $18,$18,$18,$00,$18,$18,$18,$18,$00,$C3,$C3,$C3,$DB,$D3,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $18,$18,$18,$18,$18,$18,$18,$18,$00,$C3,$C3,$C3,$C3,$C3,$C3,$C3
        .byte   $FE,$BE,$DE,$E4,$E0,$F0,$E4,$00,$FE,$BE,$DE,$E4,$E0,$F2,$E4,$00
        .byte   $E0,$F0,$E0,$E4,$DE,$BE,$FE,$FF,$E0,$F0,$E0,$E4,$DE,$BE,$FE,$FF
        .byte   $FF,$FB,$F7,$4F,$0F,$1F,$0F,$01,$FF,$FB,$F7,$4F,$0F,$1F,$0F,$01
        .byte   $0F,$1F,$0F,$4F,$F7,$FB,$FF,$FF,$0F,$1F,$0F,$4F,$F7,$FB,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$00,$00,$00,$00,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$00,$00,$00,$00,$FF,$FF,$00
        .byte   $FF,$FF,$FF,$FF,$00,$00,$00,$00,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$FF,$FF,$00,$FF,$00,$00,$FF,$FF,$00,$00,$00,$00,$FF,$FF,$00
        .byte   $7F,$DF,$A7,$C7,$E7,$E3,$C3,$C2,$F8,$FF,$CF,$CF,$FF,$FF,$FF,$DE
        .byte   $C2,$C0,$80,$80,$A0,$80,$00,$0F,$7E,$7F,$7E,$7E,$4D,$4D,$E0,$00
        .byte   $FF,$FF,$F8,$FB,$F3,$F3,$B1,$80,$14,$FF,$F8,$F8,$F8,$F0,$B2,$CC
        .byte   $07,$1C,$30,$60,$60,$43,$07,$07,$B8,$63,$CF,$9C,$93,$B4,$E8,$68
        .byte   $FF,$FF,$3F,$9B,$9B,$09,$01,$01,$30,$FF,$3F,$1B,$1B,$8F,$8F,$63
        .byte   $00,$10,$08,$00,$00,$80,$80,$01,$F9,$EC,$F6,$7E,$9F,$5F,$6E,$EC
        .byte   $FC,$F6,$FA,$D2,$DE,$9E,$96,$86,$9E,$FE,$F2,$F2,$DE,$BE,$BE,$FE
        .byte   $84,$80,$00,$00,$08,$00,$00,$E0,$FC,$FE,$7E,$7E,$32,$32,$0E,$00
        .byte   $6C,$C0,$A0,$C8,$EC,$FE,$FE,$EA,$E3,$EF,$C0,$C9,$FC,$FE,$FE,$FE
        .byte   $CB,$C3,$81,$81,$A0,$80,$00,$00,$7F,$7F,$7F,$7F,$4F,$4F,$FF,$00
        .byte   $06,$00,$00,$00,$00,$00,$00,$80,$69,$6F,$F7,$F3,$FC,$DF,$6F,$BC
        .byte   $43,$72,$38,$28,$00,$01,$00,$00,$C8,$F1,$FB,$FB,$F8,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$ED,$ED,$DE,$9F,$7F,$FA,$F6,$7C
        .byte   $00,$02,$02,$12,$12,$D0,$80,$00,$B0,$83,$9F,$BF,$3F,$FF,$FF,$00
        .byte   $0C,$06,$0A,$02,$1E,$1E,$36,$66,$EE,$EE,$02,$12,$1E,$3E,$7E,$7E
        .byte   $E4,$C0,$C0,$40,$08,$00,$00,$00,$FC,$FE,$FE,$FE,$F2,$F2,$FE,$00
        .byte   $82,$02,$42,$22,$12,$0A,$EF,$0F,$81,$61,$71,$39,$1D,$0D,$03,$E0
        .byte   $08,$E9,$08,$09,$08,$08,$27,$44,$E7,$E6,$06,$06,$26,$67,$EF,$CC
        .byte   $40,$41,$42,$44,$48,$40,$FF,$FF,$C3,$C7,$CE,$DC,$D8,$C0,$C0,$00
        .byte   $00,$C0,$00,$C0,$00,$00,$FF,$3F,$FF,$30,$30,$30,$30,$FF,$FF,$3F
        .byte   $82,$02,$42,$22,$12,$0A,$FF,$FF,$81,$61,$71,$39,$1D,$0D,$03,$00
        .byte   $00,$03,$00,$03,$00,$00,$FF,$FC,$FF,$0C,$0C,$0C,$0C,$FF,$FF,$FC
        .byte   $40,$41,$42,$44,$48,$40,$F7,$F0,$C3,$C7,$CE,$DC,$D8,$C0,$C0,$07
        .byte   $00,$87,$00,$80,$00,$00,$F5,$32,$F7,$77,$70,$70,$74,$F6,$F7,$33
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

; ─── unreferenced data ($AF00-$AFFF) ───
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

; =============================================================================
; CHR pattern data $B000-$B3FF (4 pages)
; Referenced by: Wily 6 CHR list
; =============================================================================
        .byte   $B3,$33,$E3,$66,$46,$46,$C6,$C7,$8F,$8F,$9F,$1E,$3E,$3F,$3F,$3E
        .byte   $87,$47,$C7,$0F,$1C,$0C,$78,$FC,$7E,$BE,$BE,$7E,$3D,$0C,$80,$02
        .byte   $01,$7D,$4E,$CE,$DA,$DC,$9C,$9C,$00,$0E,$3D,$3D,$39,$3B,$7B,$7B
        .byte   $10,$10,$09,$0C,$88,$8D,$8E,$8E,$F7,$F3,$FB,$FC,$79,$7E,$FD,$FD
        .byte   $9C,$14,$14,$30,$30,$30,$2E,$49,$73,$FB,$FB,$F7,$F3,$F0,$F2,$D7
        .byte   $49,$4F,$8F,$1E,$10,$B0,$70,$50,$D7,$CF,$81,$01,$2F,$8F,$CF,$EF
        .byte   $30,$30,$30,$30,$61,$61,$82,$86,$8F,$8F,$8F,$0F,$1F,$1F,$7E,$7E
        .byte   $4C,$96,$64,$98,$D1,$F1,$F1,$F3,$BC,$F0,$7B,$87,$EF,$CF,$CF,$CF
        .byte   $D1,$C1,$C1,$81,$41,$62,$E2,$42,$2F,$3F,$3F,$7F,$BF,$9E,$9E,$BF
        .byte   $43,$83,$87,$84,$84,$44,$04,$00,$BE,$7E,$7E,$7D,$7D,$3D,$7C,$3C
        .byte   $0A,$C2,$C7,$45,$45,$47,$87,$8B,$79,$B9,$BC,$3E,$3E,$BC,$7C,$78
        .byte   $8B,$8B,$12,$1A,$1A,$1A,$3A,$71,$7C,$7C,$F5,$FD,$FD,$FD,$F9,$72
        .byte   $58,$48,$08,$18,$04,$0C,$18,$0B,$C7,$D7,$D7,$D7,$EB,$EB,$FF,$FB
        .byte   $00,$03,$06,$14,$14,$18,$18,$0C,$F0,$F4,$F1,$F3,$FB,$F7,$F7,$E3
        .byte   $72,$72,$63,$62,$62,$61,$C1,$21,$CF,$CF,$DF,$DE,$DE,$DF,$FF,$1F
        .byte   $21,$63,$63,$42,$C2,$C1,$C1,$A1,$5F,$1F,$1F,$3E,$BE,$BF,$BF,$DF
        .byte   $82,$FF,$77,$B0,$B0,$70,$13,$73,$FE,$E0,$48,$8F,$CF,$4F,$6C,$4C
        .byte   $33,$32,$32,$22,$22,$32,$32,$30,$4C,$4D,$4D,$5D,$5D,$4D,$4D,$4F
        .byte   $3F,$FA,$E3,$E0,$E1,$C1,$E1,$21,$01,$45,$5F,$5F,$5F,$7F,$7F,$FF
        .byte   $21,$23,$23,$23,$27,$23,$23,$03,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $CF,$FF,$BF,$23,$30,$60,$60,$60,$F0,$C0,$80,$5C,$4F,$1F,$1F,$1F
        .byte   $60,$20,$30,$B0,$B0,$A1,$A1,$A1,$1F,$5F,$4F,$CF,$8F,$9F,$9F,$9F
        .byte   $F1,$FD,$E1,$01,$01,$03,$63,$62,$0F,$03,$1F,$FF,$FF,$FF,$DF,$DE
        .byte   $E2,$C1,$C1,$C1,$81,$81,$81,$01,$9E,$BF,$BF,$BF,$7F,$7F,$7F,$FF
        .byte   $7E,$71,$71,$21,$31,$31,$31,$31,$41,$4F,$4F,$5F,$4F,$4F,$4F,$4F
        .byte   $21,$A1,$E0,$E1,$E1,$E1,$E1,$BD,$5F,$DF,$9F,$9E,$9E,$9E,$BE,$FC
        .byte   $39,$FE,$C6,$C6,$86,$84,$8C,$8C,$C4,$03,$3F,$3D,$7D,$7B,$7B,$7B
        .byte   $8C,$8C,$8C,$98,$98,$98,$18,$29,$7B,$7B,$7B,$77,$77,$77,$F7,$EF
        .byte   $20,$E0,$50,$50,$50,$50,$41,$43,$9F,$5F,$CF,$CF,$CF,$CF,$DE,$DE
        .byte   $66,$EA,$E6,$CE,$C8,$C8,$88,$08,$ED,$E9,$E5,$CD,$CF,$CF,$8F,$0F
        .byte   $02,$03,$03,$33,$39,$31,$31,$61,$FE,$FF,$FF,$EF,$EF,$EF,$EF,$DF
        .byte   $61,$60,$61,$63,$63,$62,$46,$3C,$DF,$DE,$DF,$DF,$DF,$DE,$FE,$7C
        .byte   $08,$08,$59,$B3,$B9,$BD,$7D,$7D,$7B,$7B,$7B,$B3,$B9,$BD,$7D,$6D
        .byte   $7D,$7B,$7B,$4B,$4A,$08,$0A,$09,$4C,$40,$00,$30,$31,$7B,$7B,$79
        .byte   $45,$0D,$1C,$9E,$DE,$EF,$EF,$EF,$DF,$DF,$DF,$DF,$DF,$EB,$EB,$61
        .byte   $EF,$CF,$DB,$40,$80,$81,$81,$A1,$60,$04,$04,$9F,$BF,$BF,$BF,$BF
        .byte   $00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$31
        .byte   $04,$02,$00,$08,$08,$08,$0A,$09,$7D,$7B,$7B,$7B,$7B,$7B,$7B,$79
        .byte   $00,$00,$00,$00,$00,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00,$C0
        .byte   $20,$00,$41,$40,$80,$81,$81,$A1,$E0,$CE,$DF,$DF,$BF,$BF,$BF,$BF
        .byte   $08,$08,$58,$B0,$80,$84,$44,$44,$7B,$7B,$7B,$B3,$B9,$BD,$7D,$7D
        .byte   $04,$02,$00,$08,$08,$08,$0A,$09,$7D,$7B,$7B,$7B,$7B,$7B,$7B,$79
        .byte   $41,$01,$00,$00,$00,$20,$21,$21,$DF,$DF,$DF,$DF,$DF,$EF,$EF,$EF
        .byte   $2F,$0E,$41,$40,$80,$81,$81,$A1,$EF,$CE,$DF,$DF,$BF,$BF,$BF,$BF
        .byte   $FF,$00,$FF,$FF,$00,$00,$FF,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$00
        .byte   $FF,$00,$FF,$FF,$00,$00,$FF,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$00
        .byte   $FF,$00,$FF,$FF,$00,$00,$FF,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$00
        .byte   $FF,$00,$FF,$FF,$00,$00,$FF,$00,$FF,$FF,$00,$00,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00
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

; =============================================================================
; screen_conn_flags — per-screen room connectivity ($B400)
; Read by get_screen_boundary; masked by scroll_left/right_mask_table
; per transition_type to decide legal room exits.
; =============================================================================
screen_conn_flags:
        .byte   $44,$40,$20,$20,$20,$80,$80,$44 ; screens $00-$07
        .byte   $40,$40,$40,$22,$20,$00,$40,$40 ; screens $08-$0F
        .byte   $40,$44,$40,$40,$40,$40,$22,$00 ; screens $10-$17
        .byte   $00,$00,$FF,$FF,$FF,$FF,$FF,$FF ; screens $18-$1F
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; screens $20-$27
        .byte   $FF,$FF,$FF,$FF ; screens $28-$2F

; ─── screen_overlay_base — per-screen offset into overlay sets below ($B42C) ───
screen_overlay_base:
        .byte   $36,$12,$5A,$5A,$5A,$12,$12,$24
        .byte   $36,$36,$36,$48,$00,$6C,$00,$12
        .byte   $90,$A2,$00,$12,$5A,$5A,$00,$7E
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
        .byte   $98,$03,$99,$03,$9A,$03,$9B,$03,$9F,$04,$9F,$03
        .byte   $0F,$11,$30,$0F,$16,$27
; ─── set 1 (base $12) ───
        .byte   $93,$02,$93,$02,$93,$02,$94,$02,$93,$02,$9F,$03
        .byte   $0F,$16,$30,$0F,$16,$30
; ─── set 2 (base $24) ───
        .byte   $98,$01,$99,$01,$9A,$01,$9B,$01,$9C,$01,$9F,$03
        .byte   $0F,$16,$27,$0F,$11,$31
; ─── set 3 (base $36) ───
        .byte   $98,$02,$99,$02,$9A,$02,$94,$02,$93,$02,$9F,$03
        .byte   $0F,$15,$30,$0F,$14,$34
; ─── set 4 (base $48) ───
        .byte   $90,$01,$91,$01,$92,$01,$93,$01,$91,$01,$9F,$03
        .byte   $0F,$16,$27,$0F,$16,$27
; ─── set 5 (base $5A) ───
        .byte   $98,$04,$99,$04,$9A,$04,$9B,$04,$96,$03,$96,$03
        .byte   $0F,$15,$28,$0F,$12,$2C
; ─── set 6 (base $6C) ───
        .byte   $AC,$06,$AD,$06,$AE,$06,$AF,$06,$B0,$06,$B1,$06
        .byte   $0F,$30,$29,$0F,$36,$17
; ─── set 7 (base $7E) ───
        .byte   $AF,$07,$B0,$07,$92,$02,$9A,$03,$B1,$07,$B1,$06
        .byte   $0F,$27,$30,$0F,$37,$27
; ─── set 8 (base $90) ───
        .byte   $9B,$03,$9C,$03,$9C,$03,$9D,$03,$9E,$03,$9F,$03
        .byte   $0F,$16,$27,$0F,$15,$28
; ─── set 9 (base $A2) ───
        .byte   $94,$04,$95,$04,$96,$04,$97,$04,$9F,$04,$9F,$03
        .byte   $0F,$10,$00,$0F,$10,$00
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
        .byte   $01,$01,$01,$01,$01,$02,$02,$02,$03,$03,$04,$04,$04,$05,$05,$05 ; $00+
        .byte   $06,$07,$08,$0A,$0A,$0C,$0C,$0C,$0D,$0D,$0D,$0E,$0E,$10,$11,$12 ; $10+
        .byte   $13,$14,$14,$15,$1A,$1D,$1E,$25,$25,$26,$23,$FF,$FF,$FF,$FF,$FF ; $20+
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
        .byte   $08,$48,$88,$F0,$F8,$38,$88,$F0,$48,$B8,$18,$80,$98,$38,$60,$80 ; $00+
        .byte   $AC,$AC,$CC,$50,$78,$30,$70,$F0,$40,$B0,$E0,$70,$F0,$48,$C0,$38 ; $10+
        .byte   $00,$10,$B0,$C0,$BC,$20,$20,$2C,$CC,$5C,$80,$FF,$FF,$FF,$FF,$FF ; $20+
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
        .byte   $48,$68,$48,$90,$18,$18,$28,$A0,$68,$48,$48,$B0,$48,$78,$88,$68 ; $00+
        .byte   $08,$08,$08,$48,$68,$08,$E0,$E0,$30,$30,$E0,$E0,$08,$B0,$B0,$B0 ; $10+
        .byte   $08,$08,$08,$08,$C4,$E0,$E0,$B4,$B4,$B4,$80,$FF,$FF,$FF,$FF,$FF ; $20+
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
        .byte   $16,$16,$16,$17,$16,$16,$16,$17 ; $00+: Batton/Batton/Batton/Robbit/Batton/Batton/Batton/Robbit
        .byte   $16,$16,$16,$17,$16,$16,$16,$16 ; $08+: Batton/Batton/Batton/Robbit/Batton/Batton/Batton/Batton
        .byte   $1C,$1C,$1C,$16,$16,$39,$1D,$1D ; $10+: Friender/Friender/Friender/Batton/Batton/PipiDespawn/Monking/Monking
        .byte   $37,$37,$1D,$1D,$39,$17,$17,$17 ; $18+: PipiSpawn/PipiSpawn/Monking/Monking/PipiDespawn/Robbit/Robbit/Robbit
        .byte   $20,$1E,$1E,$20,$0A,$71,$71,$4B ; $20+: KukkuDespawn/KukkuSpawn/KukkuSpawn/KukkuDespawn/Tanishi/BigFish/BigFish/CrazyCannon
        .byte   $4B,$4B,$56,$FF,$FF,$FF,$FF,$FF ; $28+: CrazyCannon/CrazyCannon/NeoMetallFlip/?/?/?/?/?
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
        .byte   $06,$06,$07,$07,$08,$08,$15,$15,$16,$16,$17,$17,$19,$19,$19,$19
        .byte   $19,$19,$1A,$1A,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_x_tbl — secondary (persistent) spawns, max 64 ($BA40) ───
spawn2_x_tbl:
        .byte   $B8,$B8,$B8,$B8,$D8,$D8,$F8,$F8,$F8,$F8,$08,$08,$20,$38,$48,$B8
        .byte   $C8,$E0,$48,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_y_tbl — secondary (persistent) spawns, max 64 ($BA80) ───
spawn2_y_tbl:
        .byte   $6F,$8F,$4F,$6F,$2F,$4F,$4F,$6F,$4F,$6F,$4F,$6F,$9A,$8F,$8F,$3F
        .byte   $3F,$48,$3A,$6A,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
; ─── spawn2_type_tbl — secondary spawn types ($BAC0) ───
spawn2_type_tbl:
        .byte   $2E,$2E,$2E,$2E,$2E,$2E,$2F,$2F ; $00+: FrienderFire/FrienderFire/FrienderFire/FrienderFire/FrienderFire/FrienderFire/BossDoor/BossDoor
        .byte   $2F,$2F,$2F,$2F,$78,$2D,$2D,$2D ; $08+: BossDoor/BossDoor/BossDoor/BossDoor/LargeWeapon/CrashWallVar/CrashWallVar/CrashWallVar
        .byte   $2D,$7A,$78,$78,$FF,$FF,$FF,$FF ; $10+: CrashWallVar/Etank/LargeWeapon/LargeWeapon/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $18+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $20+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $28+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $30+: ?/?/?/?/?/?/?/?
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; $38+: ?/?/?/?/?/?/?/?

; =============================================================================
; Checkpoint tables — 11 arrays × 6 slots ($BB00-$BB41)
; Indexed by checkpoint_idx ($B0): slots 0-2 = Wood Man,
; slots 3-5 = Wily 3. Restored by checkpoint_respawn (bank0F:865).
; =============================================================================
chk_boss_entry_y:  .byte   $B4,$54,$74,$94,$84,$84 ; boss-entrance landing Y
chk_screen:  .byte   $00,$09,$16,$18,$22,$22 ; checkpoint screen (nametable_select)
chk_spawn_idx:  .byte   $00,$13,$24,$24,$27,$27 ; primary spawn scan index
chk_spawn2_idx:  .byte   $00,$06,$08,$0C,$14,$14 ; secondary spawn scan index
chk_metatile_hi:  .byte   $84,$87,$8A,$8A,$8D,$8D ; metatile_ptr high
chk_metatile_lo:  .byte   $E0,$20,$60,$E0,$60,$60 ; metatile_ptr low
chk_column_hi:  .byte   $85,$87,$8A,$8B,$8D,$8D ; column_ptr high
chk_column_lo:  .byte   $60,$A0,$E0,$60,$E0,$E0 ; column_ptr low
chk_cur_screen:  .byte   $00,$05,$0C,$0E,$14,$14 ; current_screen (room index)
chk_scroll_lo:  .byte   $00,$09,$16,$18,$22,$22 ; scroll_screen_lo (left bound)
chk_scroll_hi:  .byte   $04,$09,$16,$18,$22,$22 ; scroll_screen_hi (right bound)
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
; chr_upload_list_rm — CHR-RAM upload records: Wood Man ($BC00)
; [record count, then (src_page, page_count, src_bank) × N] → CHR $0000+
; =============================================================================
chr_upload_list_rm:
        .byte   $06                     ; 6 records
        .byte   $90,$09,$00             ; CHR $0000+: $9000 × 9 pages from bank $00
        .byte   $84,$01,$09             ; CHR $0900+: $8400 × 1 pages from bank $09
        .byte   $98,$05,$00             ; CHR $0A00+: $9800 × 5 pages from bank $00
        .byte   $9F,$01,$03             ; CHR $0F00+: $9F00 × 1 pages from bank $03
        .byte   $80,$06,$09             ; CHR $1000+: $8000 × 6 pages from bank $09
        .byte   $A0,$0A,$02             ; CHR $1600+: $A000 × 10 pages from bank $02
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
; chr_upload_list_wily — CHR-RAM upload records: Wily 3 ($BD00)
; [record count, then (src_page, page_count, src_bank) × N] → CHR $0000+
; =============================================================================
chr_upload_list_wily:
        .byte   $08                     ; 8 records
        .byte   $90,$09,$00             ; CHR $0000+: $9000 × 9 pages from bank $00
        .byte   $84,$01,$09             ; CHR $0900+: $8400 × 1 pages from bank $09
        .byte   $98,$05,$00             ; CHR $0A00+: $9800 × 5 pages from bank $00
        .byte   $9F,$01,$03             ; CHR $0F00+: $9F00 × 1 pages from bank $03
        .byte   $80,$06,$09             ; CHR $1000+: $8000 × 6 pages from bank $09
        .byte   $AA,$04,$01             ; CHR $1600+: $AA00 × 4 pages from bank $01
        .byte   $AA,$05,$02             ; CHR $1A00+: $AA00 × 5 pages from bank $02
        .byte   $AC,$01,$02             ; CHR $1F00+: $AC00 × 1 pages from bank $02
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
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF

; =============================================================================
; palette_block_rm — Wood Man palettes ($BE00)
; [anim_target, anim_counter, 32-byte palette (BG+sprite), 4 × 16-byte
; palette animation frames] — copied verbatim to $0354-$03B5.
; =============================================================================
palette_block_rm:
        .byte   $00,$00                 ; anim target, counter
        .byte   $0F,$29,$19,$2C,$0F,$28,$18,$2C,$0F,$27,$17,$07,$0F,$08,$2C,$12 ; palette
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$20,$38,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$25,$15,$2C,$0F,$28,$18,$2C,$0F,$27,$17,$07,$0F,$08,$2C,$12 ; anim frame 0
        .byte   $0F,$26,$16,$2C,$0F,$28,$18,$2C,$0F,$27,$17,$07,$0F,$08,$2C,$12 ; anim frame 1
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; anim frame 2
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; anim frame 3
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
; palette_block_wily — Wily 3 palettes ($BF00)
; [anim_target, anim_counter, 32-byte palette (BG+sprite), 4 × 16-byte
; palette animation frames] — copied verbatim to $0354-$03B5.
; =============================================================================
palette_block_wily:
        .byte   $00,$00                 ; anim target, counter
        .byte   $0F,$28,$17,$18,$0F,$29,$18,$07,$0F,$0F,$28,$18,$0F,$0A,$08,$0B ; palette
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$20,$38,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$27,$37,$30,$0F,$27,$11,$16,$0F,$00,$10,$16,$0F,$27,$06,$16 ; anim frame 0
        .byte   $0F,$27,$37,$30,$0F,$27,$11,$16,$0F,$10,$00,$16,$0F,$27,$06,$16 ; anim frame 1
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
