.segment "BANK04"

; =============================================================================
; Bank $04 — Stage Data 5
; CHR tile patterns and level layout data.
; This bank contains no executable code — all bytes are data.
; =============================================================================

; da65 V2.18 - Ubuntu 2.19-1
; Created:    2026-02-23 18:17:35
; Input file: build/bank04.bin
; Page:       1


        .setcpu "6502"

L0000           := $0000
L00C0           := $00C0
L011E           := $011E
L0819           := $0819
L0F13           := $0F13
L1020           := $1020
L1919           := $1919
L212B           := $212B
L3E70           := $3E70
L404C           := $404C
L7000           := $7000
LE03F           := $E03F
        brk
        .byte   $00,$00,$00,$69,$69,$68,$68
        ror     a
        ror     a
        adc     #$69
        adc     ($69),y
        ror     $68
        adc     $6A
        adc     ($69),y
        adc     #$69
        bvs     L8081
        .byte   $72,$69,$69,$69,$33,$65,$33,$71
        .byte   $69,$69,$69,$69,$77,$77,$68,$68
        .byte   $6A,$6A,$77,$77,$71,$77,$66,$68
        .byte   $65,$6A,$71,$77,$77,$77,$70,$69
        .byte   $72,$69,$77,$77,$62,$6D,$69,$61
        adc     ($69),y
        adc     ($69),y
        .byte   $6F,$77,$68,$68,$6A,$6A,$6F,$77
        .byte   $69,$61,$68,$6E,$6A,$6D,$69,$61
        .byte   $69,$69,$69,$60,$69,$62,$69,$69
        .byte   $69,$69,$70,$60,$71,$69,$71,$77
        .byte   $77,$77,$69,$69
        adc     #$69
        .byte   $77,$77,$77,$61,$68,$6E,$6A,$6D
        .byte   $77,$61,$67,$69,$67,$60,$67,$62
        .byte   $67,$69,$71,$61,$71,$61
        .byte   $71
L8081:  .byte   $77
        adc     ($69),y
        .byte   $6F,$77,$67,$69,$67,$69,$6F,$77
        .byte   $67,$61,$68
        ror     $6D6A
        .byte   $67
        adc     ($77,x)
        .byte   $77,$69,$60,$69,$62,$77,$77
        adc     ($61),y
        ror     $6E
        adc     #$61
        adc     #$61
        .byte   $67
        adc     ($67,x)
        adc     ($69,x)
        adc     ($77,x)
        adc     ($6F,x)
        adc     ($68,x)
        ror     $6D6A
        .byte   $6F
        adc     ($6F,x)
        .byte   $77,$67,$60,$67,$62,$6F,$77,$71
        .byte   $34,$71,$34,$77,$61,$69,$61,$6F
        .byte   $61,$67,$61,$67,$61,$6F,$61,$67
        .byte   $69,$67,$69,$68,$68,$34,$33,$65
        .byte   $6A,$66,$68,$71,$77,$66,$70,$65
        .byte   $6D,$71,$61,$69,$60,$68,$6E,$67
        .byte   $69,$68,$68,$6A,$6A,$67,$69,$69
        .byte   $67,$69,$67,$68,$6E,$33,$33,$6A
        .byte   $6A,$70,$69,$33,$71,$33,$71,$33
        .byte   $71,$33,$66,$34,$71,$34,$71,$34
        .byte   $71,$34,$66,$34,$65,$34,$71,$6A
        .byte   $72,$67,$69,$33,$59,$33,$71,$6A
        .byte   $6A,$68,$68,$34,$59,$34,$71,$68
        .byte   $68,$33,$33,$61,$34,$61,$34,$61
        .byte   $34,$6E,$34,$6D,$34,$61,$34,$65
        .byte   $6D,$66,$6E,$34,$65,$34,$66,$6A
        .byte   $6D,$68,$6E,$33,$66,$33,$33,$6E
        .byte   $34,$33,$33,$33,$71,$33,$5A,$6A
        .byte   $6A,$68,$70,$6A,$6A,$67,$60,$66
        .byte   $6E,$33,$33,$6D,$34,$5B,$34,$65
        .byte   $6A,$72,$69,$33,$33,$33,$65,$33
        .byte   $33,$6A,$6A,$71,$34,$5A,$34,$67
        .byte   $61,$67,$62,$6D,$34,$6E,$34,$69
        .byte   $62,$60,$68,$34,$33,$6A,$6D,$33
        .byte   $33,$6A,$6D,$6A,$6D,$69,$62,$34
        .byte   $33,$6A,$6A,$23,$2B,$24,$2C,$33
        .byte   $33,$23,$2B,$24,$2C,$33,$33,$36
        .byte   $33,$36,$35,$58,$34,$58,$34,$5A
        .byte   $34,$33,$33,$33,$58,$33,$58,$33
        .byte   $33,$59,$34,$35,$35,$35,$35,$35
        .byte   $35,$33,$35,$35,$33,$35,$35,$34
        .byte   $33,$34,$33,$34,$33,$33,$33,$33
        .byte   $33,$34,$33,$33,$33,$65,$6D,$71
        .byte   $69,$71,$60,$33,$33,$33,$33,$1C
        .byte   $33,$33,$1C,$33,$1C,$1C,$33,$1C
        .byte   $1C,$1C,$1C,$33,$1C,$1C,$1C,$1C
        .byte   $1C,$1C,$33,$36,$35,$36,$33,$33
        .byte   $35,$35,$35,$59,$34,$71,$34,$72
        .byte   $69,$70,$69,$33,$65,$33,$66,$68
        .byte   $68,$49,$49,$47,$4C,$47,$4D,$4E
        .byte   $4B,$4F,$4B,$08,$08,$08,$08,$34
        .byte   $33,$08,$08,$66,$68,$33,$33,$71
        .byte   $69,$72,$69,$70,$69,$71,$69,$69
        .byte   $61,$69,$62,$69,$60,$69,$61,$68
        .byte   $6E,$34,$33,$68,$68,$49,$4A,$33
        .byte   $33,$08,$08,$35,$35
        and     $33,x
        rol     $35,x
        rol     $35,x
        adc     ($6A),y
        adc     ($69),y
        .byte   $33,$33,$5E,$34,$33,$33,$33,$5F
        .byte   $33,$5A,$33,$33,$33,$33,$6D,$34
        .byte   $62,$6D,$77,$61,$4A,$52,$00,$00
        .byte   $33,$33,$33,$65,$33,$71,$65,$72
        .byte   $66,$70,$33,$71,$33,$66,$33,$33
        .byte   $00,$00,$00,$00,$C5,$C5,$48,$50
        .byte   $C5,$C5,$16,$17,$29,$30,$2A,$30
        .byte   $2B,$30,$2C,$30,$2D,$30,$2E,$30
        .byte   $2F,$30,$30,$30,$30,$30,$30,$30
        .byte   $17,$C5,$17,$4E,$38,$3A,$39,$3B
        .byte   $17,$AE,$17,$AE
        ora     ($0D,x)
        .byte   $02
        asl     $0F03
        .byte   $04,$11,$05,$12,$06,$13,$07,$14
        .byte   $08,$15
        ora     #$16
        asl     a
        .byte   $17,$0B,$18,$0C,$19,$1A,$37,$1B
        .byte   $26,$1C,$27,$1D
        plp
        asl     $1F29,x
        rol     a
        jsr     L212B
        bit     $2D22
        .byte   $23,$2E,$24,$2F,$25,$37,$37,$37
        .byte   $37,$37,$37,$37,$30,$37,$31,$37
        .byte   $32,$37,$33,$37,$34,$37,$35,$37
        .byte   $37,$37,$78,$7A,$79,$7B,$40,$40
        .byte   $36,$37,$40,$40,$37,$37,$40,$78
        .byte   $37,$79,$37,$78,$37,$79,$7A,$78
        .byte   $7B,$79,$36,$37,$40,$40,$37,$37
        .byte   $40,$40,$37,$37,$37,$7C,$37,$7D
        .byte   $40,$40,$37,$78,$7E
        adc     $787F,y
        rti

        .byte   $79,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$5E,$5E,$6C
        .byte   $6A,$6C,$6B,$64,$6C,$64,$6C,$64
        .byte   $6C,$54,$54,$54,$54,$00,$00,$00
        .byte   $00,$64,$6C,$5E,$5E,$64,$6C,$6C
        .byte   $6A,$6C,$6B,$5E,$5E,$5E,$5E,$60
        .byte   $00,$61,$00,$30,$38,$31,$39,$32
        .byte   $3A,$33,$3B,$1A,$1C,$1B,$1D,$30
        .byte   $38,$25,$2D,$5E,$5E,$33,$3B,$60
        .byte   $00,$61,$00,$5E,$5E,$5E,$5E,$00
        .byte   $68,$00,$69,$34,$3C,$35,$3D,$36
        .byte   $3E,$37,$3F,$1A,$1C,$1B,$1D,$34
        .byte   $3C,$2D,$2D,$5E,$5E,$37,$3F,$00
        .byte   $68,$00,$69,$5E,$5E
        and     $2D
        and     $2D
        adc     (L0000,x)
        rol     $2E
        .byte   $27,$2F,$1F,$59,$1F,$1F,$1A,$1C
        .byte   $1B,$1D,$1F,$1F,$1F,$59,$26,$2E
        .byte   $27,$2F,$60,$00,$00,$00,$00,$00
        .byte   $2D,$2D,$2D,$2D,$00,$69
        bmi     L83C0
        lsr     $2D5E,x
        ora     $0E2D
        and     $5E2D
        lsr     a:L0000,x
        brk
        .byte   $00,$2D,$2D,$33,$3B,$00,$68,$5E
        lsr     $6A68,x
        adc     #$6B
        .byte   $64,$6C,$61,$00,$59,$3C,$5E,$5E
        .byte   $64,$6C,$62,$00,$63,$00,$33,$3B
        .byte   $60,$00,$61,$00,$30,$38,$59,$3F
        .byte   $60,$00,$5E,$5E,$25,$2D
L83C0:  lsr     $2D5E,x
        and     $6900
        .byte   $1F,$64,$1F,$64,$1F,$64,$00,$68
        .byte   $00,$69,$37,$3F,$00,$68,$00,$69
        .byte   $34,$3C,$1F,$64,$00,$68,$2B,$2B
        .byte   $2D,$2D,$5E,$5E,$6A,$64,$6B,$64
        .byte   $6C,$64,$6C,$64,$6C,$64,$6A,$64
        .byte   $6B,$64,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$6C,$64,$6A,$64,$6B,$64
        .byte   $5E,$5E,$00,$00,$00,$00,$00,$00
        .byte   $00,$05,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$50,$00,$00,$00,$00,$44,$00
        .byte   $00,$00,$00,$00,$00,$00,$44,$00
        .byte   $05,$05,$05,$05,$05,$00,$05,$00
        .byte   $05,$44,$50,$50,$50,$00
        ora     L0000
        eor     $54
        ora     L0000
        brk
        .byte   $44,$50,$00
        ora     $11,x
        bvc     L845A
L845A:  bvc     L845C
L845C:  ora     ($11),y
        brk
        .byte   $11,$AA,$99,$66,$AA,$5F,$54,$F5
        .byte   $51,$AA,$AA,$AA,$55,$55,$55,$11
        .byte   $00,$55,$55,$55,$55,$55,$55,$AA
        .byte   $AA,$50,$00
        ora     L0000
        brk
        .byte   $00,$00,$11,$44,$00,$00,$00,$00
        .byte   $44,$00,$11,$AA,$AA,$00,$51,$15
        .byte   $45,$51,$00,$33,$15,$01,$04,$45
        .byte   $00,$CC,$88,$0A,$0A
        asl     a
        asl     a
        brk
        .byte   $CA,$00,$0A,$CC,$FF,$FF,$FF,$FF
        .byte   $33,$00,$CF,$FF,$FF,$3F,$00,$00
        .byte   $00,$00,$00,$00,$55,$11,$11,$51
        .byte   $50,$55,$44,$44,$80,$64,$58,$56
        .byte   $00,$00,$00,$40,$10,$00,$00,$00
        .byte   $00,$40,$10,$04,$CD,$FF,$BB,$EE
        .byte   $22,$37,$01,$40,$DC,$FF,$BB,$EE
        .byte   $22,$73,$10,$AA,$89,$2A,$AA,$AA
        .byte   $8A,$26,$00,$AA,$DC,$88,$AA,$00
        .byte   $88,$73,$44,$11,$C1,$00,$05,$37
        .byte   $CD,$34,$88,$88,$18,$0A,$50,$73
        .byte   $DC,$42,$99,$04,$01,$00,$05,$00
        .byte   $00,$04,$01,$09,$11,$09,$0D,$21
        .byte   $19,$21,$21,$72,$74,$69,$03
        and     $3305,y
        .byte   $33,$60,$60,$70,$69,$68,$18,$22
        .byte   $22,$72,$60,$60,$70,$69,$10,$33
        .byte   $33,$75,$71,$72,$70,$71,$0B,$11
        .byte   $11,$6A,$72,$61,$71,$72,$70,$70
        .byte   $70,$68,$6A,$62,$72,$75,$0C,$12
        .byte   $0A,$0A,$12,$0A,$12,$0A,$0E,$22
        .byte   $1A,$19,$19,$19,$19,$25,$09,$09
        .byte   $09,$08,$15,$38,$34,$3C,$6C,$72
        .byte   $71,$1A,$2A,$6B,$71,$72,$71,$0C
        .byte   $12,$08,$5B,$5A,$70,$35,$3D,$06
        .byte   $33,$09,$49,$73,$71,$72,$10,$08
        .byte   $33
        adc     ($72),y
        bvs     L8578
        .byte   $12,$0E,$1A,$22,$0A,$0A,$12,$0E
        .byte   $22,$1A,$1A,$22
L8578:  .byte   $1A,$1A,$22,$1A,$22,$1A,$1A,$22
        .byte   $09,$09,$0D,$19,$19,$21
        ora     $7021,y
        adc     ($36),y
        ora     $1125,y
        ora     #$11
        bit     $3E6B
        php
        plp
        .byte   $6B,$60,$70,$29,$6B,$3F,$17,$13
        .byte   $6B,$60
        bvs     L85BF
        lsr     a
        bvs     L85C3
        .byte   $6B,$61,$61,$70,$22,$8F,$6B,$27
        .byte   $6B,$62,$62,$70,$22,$2A,$6B,$71
        .byte   $72,$0C,$12,$0A,$22,$26,$12,$0A
        .byte   $0A,$0E,$22
L85BF:  .byte   $1A,$21,$30
        rti

L85C3:  pha
        bpl     L85F9
        .byte   $33,$08,$11,$1B,$41
        eor     #$0B
        ora     ($11),y
        ora     #$71
        .byte   $72,$73
        bvs     L8647
        bvs     L8648
        bvs     L8639
        rts

        .byte   $70,$71,$72,$70,$04,$3A,$70,$71
        .byte   $72
        bvs     L8656
        .byte   $0C,$0E,$22,$73,$72,$71,$70,$0C
        .byte   $0E,$1A,$22,$12,$2C,$42,$4A,$10
        .byte   $08,$08,$33,$22
L85F9:  .byte   $32,$40,$48,$18,$1A,$1A,$22,$2D
        .byte   $09,$49,$27,$41,$13,$41,$01,$23
        .byte   $6B,$71,$72,$75,$72,$70,$70,$70
        .byte   $60,$70,$60,$70,$4B,$4C,$45,$14
        .byte   $6B,$70,$60,$70,$70,$71,$72,$2A
        .byte   $6B,$72,$71,$70,$72,$73,$71,$2A
        .byte   $6B,$71,$72,$70,$70,$71,$70,$16
        .byte   $02,$4A,$37,$42,$14,$42,$12,$1A
L8639:  .byte   $1A,$48,$1F,$40,$28,$40,$33,$01
        .byte   $13,$41,$13,$41,$01,$11
L8647:  .byte   $01
L8648:  bvs     L86BA
        bvs     L86BE
        adc     ($70),y
        bvs     L86C0
        eor     $4D
        .byte   $42
        .byte   $1C
        .byte   $6B,$07
L8656:  eor     ($3A),y
        bvs     L86CA
        lsr     $4F47
        rol     $2240,x
        rts

        rts

        .byte   $8C,$57,$8B,$50,$41,$11,$70,$60
        .byte   $70,$70,$70,$70,$70,$70,$12,$2C
        lsr     $42
        .byte   $02,$24,$42,$02,$33,$29,$40,$40
        ora     $4031,y
        php
        ora     ($11,x)
        ora     ($01,x)
        ora     ($11),y
        ora     ($01,x)
        bvs     L86FA
        bvs     L86FC
        bvs     L86FE
        rts

        .byte   $70,$02,$52,$45
        eor     $45
        .byte   $54
        lsr     $57,x
        .byte   $1A,$32,$6B,$70,$70,$2F
        rol     $0921,x
        .byte   $2B,$6B,$37,$6B,$58,$3E,$33
        bvs     L871A
        bvs     L86FF
        jmp     (L3E70)

        .byte   $22,$02,$5E,$5F,$57,$57,$55,$43
        .byte   $33,$19,$19
L86BA:  and     ($19,x)
        .byte   $19
        .byte   $21
L86BE:  .byte   $19
        .byte   $19
L86C0:  ora     ($09),y
        ora     #$11
        ora     #$11
        ora     $6021
        rts

L86CA:  bvs     L872C
        adc     ($77),y
        clc
        .byte   $22,$5D,$6D,$71,$72,$77,$68,$20
        .byte   $21,$30,$6B,$60,$70
        adc     ($69),y
        clc
        .byte   $22,$28,$6B,$60,$70,$75,$72,$10
        .byte   $33,$2A,$6B,$72,$73,$70,$77,$18
        .byte   $22,$28,$63,$77,$6A,$77,$88,$10
        .byte   $33,$30,$76
L86FA:  bvs     L8765
L86FC:  dey
        .byte   $74
L86FE:  .byte   $10
L86FF:  .byte   $33
        .byte   $32,$6B,$70,$74,$70,$04,$06,$08
        .byte   $29,$6B,$60,$70,$71
        jsr     L1919
        and     ($6B),y
        .byte   $72,$71,$04,$06,$08,$08,$29,$6B
L871A:  bvs     L878E
        .byte   $0B,$0D,$19,$19,$32,$6B,$60,$70
        .byte   $70,$0B,$0D,$19,$59,$5C,$6D
        .byte   $70
L872C:  bvs     L879E
        bpl     L8738
        and     ($30,x)
        .byte   $6B,$60,$70,$71,$20,$19
L8738:  .byte   $33,$28,$6B,$60,$70,$72,$10,$08
        .byte   $22,$2A,$63,$71,$70,$0C,$0E,$1A
        .byte   $33,$28,$76,$6A,$77,$20
        ora     $2119,y
        bmi     L87BE
        adc     #$0C
        asl     $1A1A
        .byte   $33,$28,$6B,$70,$03,$05,$08,$08
        .byte   $22,$2A,$6B,$72,$71
L8765:  .byte   $18,$1A,$1A,$21,$30,$6B,$60,$70
        .byte   $03,$05,$08,$33,$28,$6B,$60,$60
        .byte   $70,$18,$1A,$22,$2A,$6B,$71,$72
        .byte   $70
        bpl     L8788
        .byte   $33,$16,$24,$6B,$70,$0C,$0E,$1A
L8788:  and     ($19,x)
        and     ($6B),y
        bvs     L879E
L878E:  php
        php
        .byte   $33,$08
        and     #$6B
        bvs     L87AE
        .byte   $1A,$1A,$22,$1A,$32,$6B,$70
        .byte   $20
L879E:  ora     $2119,y
        ora     $6B31,y
        bvs     L87B6
        php
        php
        and     ($19,x)
        and     ($6B),y
        bvs     L87BE
L87AE:  php
        php
        .byte   $33,$08,$29,$6B,$0C,$0E
L87B6:  .byte   $1A,$1A,$22,$1A,$32,$6B,$10,$08
L87BE:  php
        php
        .byte   $33,$08,$29,$6B,$10,$08
        php
        pha
        .byte   $22,$1A,$32,$6B,$18,$1A,$1A,$48
        .byte   $33,$08,$29,$6B,$20,$19,$19,$48
        .byte   $21,$19,$31,$6B,$10,$08,$08,$48
        .byte   $22,$1A,$32,$6B,$0B,$09
        ora     #$49
        .byte   $33,$08,$29,$6B,$70,$70,$70,$70
        .byte   $22,$1A,$2E,$12,$0A,$12,$0A,$4A
        .byte   $33,$08,$33,$33,$08,$33,$08,$48
        .byte   $6B,$70,$70,$72,$3E,$6B,$70,$73
        .byte   $6B,$70,$70,$70,$3E,$6B,$70,$70
        .byte   $6B,$70,$70,$70,$3E,$6B,$70,$70
        .byte   $6B,$70,$70,$67,$8D,$6C,$78,$70
        .byte   $6B,$70,$70,$65,$67,$70,$58,$70
        .byte   $70,$70,$67,$70,$2F,$70,$70,$71
        .byte   $6B,$70,$2F,$70,$2F,$72,$71,$72
        .byte   $6B,$70,$2F,$70,$2F,$73,$73,$73
        .byte   $73,$73,$2F,$75,$72,$70,$70,$70
        .byte   $75,$72,$2F
        bvs     L88BD
        bvs     L88BF
        bvs     L88C2
        .byte   $72,$58
        bvs     L88C5
        sei
        bvs     L88C8
        bvs     L88CA
        bvs     L88A0
        .byte   $6B,$2F
        bvs     L88D0
        bvs     L88D2
        bvs     L88B4
        .byte   $6B,$2F,$70,$70,$70,$70
        sei
        bvs     L88DD
        cli
        bvs     L88E0
        bvs     L88E7
        .byte   $2F
        bvs     L88E5
        bvs     L88E8
        .byte   $72,$75,$72,$2F
        adc     ($70),y
        .byte   $72,$74,$73
        bvs     L88F2
        .byte   $2F
        bvs     L88F5
        bvs     L88F8
        .byte   $72
        bvs     L88FA
        .byte   $2F
        bvs     L88FD
        bvs     L88FF
        bvs     L8901
        bvs     L88EB
        bvs     L8905
        bvs     L88A3
        lsr     a
        bvs     L890A
        bvs     L890C
        bvs     L890E
        bpl     L88E8
L88A0:  bvs     L8912
        .byte   $70
L88A3:  bvs     L8915
        bvs     L88BF
        pha
        bvs     L891A
        sei
        bvs     L891D
        adc     ($10),y
        pha
        adc     ($70),y
        .byte   $2F,$70
L88B4:  adc     ($74),y
        bpl     L8900
        adc     $72,x
        .byte   $2F,$70,$72
L88BD:  adc     $18,x
L88BF:  pha
        adc     ($70),y
L88C2:  rol     $4040,x
L88C5:  .byte   $6B
        bvs     L8938
L88C8:  bvs     L893A
L88CA:  bvc     L890C
        rti

        .byte   $6B,$70,$70
L88D0:  .byte   $6B,$70
L88D2:  bvs     L8924
        rti

        .byte   $6B,$70,$70,$6B,$70
        bvs     L894C
        .byte   $3E
L88DD:  .byte   $6B
        bvs     L8950
L88E0:  .byte   $6B
        bvs     L8953
        bvs     L8935
L88E5:  .byte   $6B,$0C
L88E7:  .byte   $0A
L88E8:  .byte   $6B,$70,$70
L88EB:  adc     ($70),y
        bvs     L8907
        .byte   $1A,$6B,$70
L88F2:  .byte   $72,$71,$72
L88F5:  adc     ($20),y
        .byte   $19
L88F8:  .byte   $6B
        .byte   $70
L88FA:  adc     ($73),y
        .byte   $73
L88FD:  .byte   $74
        .byte   $10
L88FF:  php
L8900:  .byte   $71
L8901:  .byte   $72
        bvs     L8978
        .byte   $70
L8905:  .byte   $72
        .byte   $70
L8907:  bvs     L8979
        .byte   $70
L890A:  bvs     L897C
L890C:  bvs     L897F
L890E:  bvs     L8980
        bvs     L8982
L8912:  adc     ($70),y
        .byte   $72
L8915:  adc     $70,x
        adc     ($70),y
        .byte   $70
L891A:  bvs     L8960
        .byte   $6B
L891D:  bvs     L8997
        .byte   $72,$12,$0A,$2C,$40
L8924:  .byte   $3A,$4A
        txa
        lsr     a
        .byte   $22,$1A,$32,$40,$21,$48,$10
        pha
        and     ($19,x)
        and     ($40),y
        .byte   $22
L8935:  pha
        bpl     L8980
L8938:  .byte   $33,$08
L893A:  and     #$40
        .byte   $33,$48,$10,$48
        adc     $70,x
        rol     $7048,x
        bvs     L89B8
        adc     $72,x
        adc     ($3E),y
        pha
L894C:  bvs     L89BF
        .byte   $72,$70
L8950:  adc     ($72),y
        .byte   $3E
L8953:  pha
        bvs     L89C6
        bvs     L89CA
        bvs     L89CA
        .byte   $3F
        eor     #$56
        stx     $7070
L8960:  .byte   $6B,$70,$70,$70,$3E
        pha
        bvs     L89D8
        .byte   $6B,$70,$71,$70,$3E,$48,$70,$70
        .byte   $6B,$70,$70,$70,$3E,$48,$72,$71
L8978:  .byte   $6B
L8979:  bvs     L89EB
        .byte   $70
L897C:  rol     $7148,x
L897F:  .byte   $72
L8980:  adc     ($72),y
L8982:  .byte   $1F,$6B,$6F,$01,$39
        ora     ($70,x)
        adc     ($1F),y
        .byte   $6B,$1F,$6B,$70,$70,$70,$71,$1F
        .byte   $6B,$1F,$6B,$0C
L8997:  .byte   $12,$71,$75,$27,$6B,$27,$6B,$10
        .byte   $33,$70,$70,$70
        bvs     L8A15
        bvs     L89BF
        .byte   $22,$70,$70
        bvs     L8A1C
        bvs     L8A1E
        bpl     L89E3
        adc     ($71),y
        ror     $6E6D
        adc     $2120
L89B8:  adc     ($72),y
        .byte   $1F,$6B,$1F,$6B,$10
L89BF:  .byte   $33,$01,$39
        ora     ($01,x)
        .byte   $39
        .byte   $01
L89C6:  ora     $08
        bvs     L8A3A
L89CA:  adc     ($70),y
        .byte   $72,$70,$10,$08,$0A,$2C,$6B,$60
        .byte   $70,$70,$18,$1A
L89D8:  php
        and     #$6B
        adc     ($60),y
        bvs     L89EF
        php
        .byte   $1A,$32,$6B
L89E3:  .byte   $60,$70,$70,$20,$19,$08,$29,$6B
L89EB:  .byte   $72
        adc     ($77),y
        .byte   $20
L89EF:  ora     $3119,y
        .byte   $89
        pla
        pla
        pla
        bpl     L8A00
        php
        and     #$6B
        rts

        .byte   $70,$69,$20,$19
L8A00:  php
        and     #$6B
        rts

        .byte   $60,$70,$20,$19,$19,$31,$6B,$60
        .byte   $70,$70,$18,$1A,$08,$29,$6B,$70
        .byte   $71
L8A15:  .byte   $7A
        adc     $1908,y
        and     ($6B),y
        .byte   $71
L8A1C:  .byte   $72
        .byte   $73
L8A1E:  .byte   $18,$1A,$19,$31,$6B,$71,$71,$72
        .byte   $10
        php
        php
        asl     $6B14,x
        bvs     L8AA8
        adc     $1908,y
        and     ($30,x)
        .byte   $63,$72,$71,$18,$1A,$08,$33
L8A3A:  .byte   $28,$89,$68,$68,$20,$19,$08,$33
        .byte   $28,$76,$70,$7A
        adc     $1908,y
        and     ($30,x)
        .byte   $6B,$71,$72,$18,$1A,$19,$21,$30
        .byte   $6B,$72,$71
        jsr     L0819
        .byte   $33,$28,$6B,$70,$04,$06,$08,$1A
        .byte   $22,$2A,$6B,$72,$20,$19
        ora     $3308,y
        plp
        .byte   $6B,$71,$10,$08,$08,$7B,$86,$85
        .byte   $6C,$0C,$0E,$1A,$1A,$7C,$7D,$7F
        .byte   $87,$10,$08
        php
        php
        brk
        .byte   $1F,$6B,$70,$1F,$00,$00,$00,$00
        .byte   $1F,$6B,$70,$1F,$00,$00,$00,$00
        .byte   $1F,$6B,$70,$1F,$00,$00,$00,$00
        .byte   $1F,$6B,$70,$1F,$00,$00,$00,$00
        .byte   $1F,$6B,$70,$1F,$00,$00,$00
L8AA8:  .byte   $00,$1F,$6B,$70,$1F,$00,$00,$00
        .byte   $00,$1F,$6B,$70,$1F,$00,$00,$00
        .byte   $00,$1F,$7F,$87,$1F,$00,$00,$00
        .byte   $47,$3C,$6C,$71,$80,$47,$82,$08
        .byte   $71,$72,$71,$72
L8ACC:  adc     ($91),y
L8ACE:  sta     ($08,x)
        .byte   $72,$71,$72,$71,$72,$92,$08,$08
        .byte   $71,$72,$71,$72,$71,$93,$08,$08
        .byte   $72,$71,$72,$71,$72,$92,$08,$08
        .byte   $71,$72,$71,$72,$71,$93,$08,$08
        .byte   $72,$71,$72,$71,$72,$94,$82,$08
        .byte   $57,$57,$57,$57,$57,$57,$81,$08
L8B00:  cpy     #$C8
        bne     L8ACC
        bne     L8ACE
        bne     L8B00
        cmp     ($C9,x)
        cmp     ($D9),y
        sbc     ($E9,x)
        sbc     ($F9),y
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE
        inc     $EE
        inc     $FE,x
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0
L8B4C:  .byte   $E3,$E0
L8B4E:  .byte   $E8,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C5,$CD,$D5,$D5,$D5,$D5
        .byte   $C5,$C5
L8B80:  cpy     #$C8
        bne     L8B4C
        bne     L8B4E
        bne     L8B80
        cmp     ($C9,x)
        cmp     ($D9),y
        sbc     ($E9,x)
        sbc     ($F9),y
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE
        inc     $EE
        inc     $FE,x
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0
L8BCC:  .byte   $E3,$E0
L8BCE:  .byte   $E8,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C5,$CD,$D5,$D5,$D5,$D5
        .byte   $C5,$C5
L8C00:  cpy     #$C8
        bne     L8BCC
        bne     L8BCE
        bne     L8C00
        cmp     ($C9,x)
        cmp     ($D9),y
        sbc     ($E9,x)
        sbc     ($F9),y
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE
        inc     $EE
        inc     $FE,x
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0
L8C4C:  .byte   $E3,$E0
L8C4E:  .byte   $E8,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C5,$CD,$D5,$D5,$D5,$D5
        .byte   $C5,$C5
L8C80:  cpy     #$C8
        bne     L8C4C
        bne     L8C4E
        bne     L8C80
        cmp     ($C9,x)
        cmp     ($D9),y
        sbc     ($E9,x)
        sbc     ($F9),y
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE
        inc     $EE
        inc     $FE,x
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0,$E3,$E0,$E8,$C2
        .byte   $C2,$D8,$E0,$E0,$E0,$E0,$C2,$C2
        .byte   $C2
        cld
        cpx     #$E0
        cpx     #$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C5,$CD,$D5,$D5,$D5,$D5
        .byte   $C5,$C5,$B1,$B2,$B3,$B3,$B3,$B3
        .byte   $B4,$B6,$B1,$A0,$A6,$AC,$AC,$AC
        .byte   $B5,$B6,$B1,$A1,$A7,$AD,$AC,$AC
        .byte   $B5,$B6,$B1,$A2,$A8,$AE,$AC,$AC
        .byte   $B5,$B6,$B1,$A3,$A9,$AF,$AC,$AC
        .byte   $B5,$B6,$B1,$A4,$AA,$B0,$AC,$AC
        lda     $B6,x
        lda     ($A5),y
        .byte   $AB,$AC
        ldy     LBBB9
        ldx     $B1,y
        .byte   $B7,$B8,$B8,$B8,$BA,$BC,$B6,$EA
        .byte   $EF,$F0,$F0,$E2,$F0,$E7,$EA,$C2
        .byte   $D8,$E0,$E0
L8D4C:  .byte   $E3,$E0
L8D4E:  .byte   $E8,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C5,$CD,$D5,$D5,$D5,$D5
        .byte   $C5,$C5
L8D80:  cpy     #$C8
        bne     L8D4C
        bne     L8D4E
        bne     L8D80
        cmp     ($C9,x)
        cmp     ($D9),y
        sbc     ($E9,x)
        sbc     ($F9),y
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE
        inc     $EE
        inc     $FE,x
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0
L8DCC:  .byte   $E3,$E0
L8DCE:  .byte   $E8,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C5,$CD,$D5,$D5,$D5,$D5
        .byte   $C5,$C5
L8E00:  cpy     #$C8
        bne     L8DCC
        bne     L8DCE
        bne     L8E00
        cmp     ($C9,x)
        cmp     ($D9),y
        sbc     ($E9,x)
        sbc     ($F9),y
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE
        inc     $EE
        inc     $FE,x
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0
L8E4C:  .byte   $E3,$E0
L8E4E:  .byte   $E8,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C5,$CD,$D5,$D5,$D5,$D5
        .byte   $C5,$C5
L8E80:  cpy     #$C8
        bne     L8E4C
        bne     L8E4E
        bne     L8E80
        cmp     ($C9,x)
        cmp     ($D9),y
        sbc     ($E9,x)
        sbc     ($F9),y
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C2,$CB,$D3,$DB,$CB,$EB,$F3,$FB
        .byte   $C2,$CC,$D4,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE
        inc     $EE
        inc     $FE,x
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
        .byte   $EA,$EF,$F0,$F0,$E2,$F0,$E7,$EA
        .byte   $C2,$D8,$E0,$E0
L8ECC:  .byte   $E3,$E0
L8ECE:  .byte   $E8,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C2,$D8,$E0,$E0,$E0,$E0
        .byte   $C2,$C2,$C5,$CD,$D5,$D5,$D5,$D5
        .byte   $C5,$C5
L8F00:  cpy     #$C8
        bne     L8ECC
        bne     L8ECE
        bne     L8F00
        cmp     ($C9,x)
        cmp     ($D9),y
        sbc     ($E9,x)
        sbc     ($F9),y
        .byte   $C2,$CA,$D2,$DA,$CA,$D2,$F2,$FA
        .byte   $C6,$EC,$F4,$DB,$CB,$EB,$F3,$FB
        .byte   $C1,$ED,$F5,$DC,$CC,$EB,$F3,$FB
        .byte   $C2,$CA,$D2,$DD,$CA,$D2,$F2,$FA
        .byte   $C6,$CE,$D6,$DE,$E6,$EE,$F6,$FE
        .byte   $C7,$CF,$D7,$CF,$D7,$CF,$D7,$FF
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $00,$00,$00,$00,$00,$00,$C3,$C3
        .byte   $B1,$B2,$B3,$B3,$B3,$B3,$B4,$B6
        .byte   $B1,$A0,$A6,$AC,$AC,$AC,$B5,$B6
        .byte   $B1,$A1,$A7,$AD,$AC,$AC,$B5,$B6
        .byte   $B1,$A2,$A8,$AE,$AC,$AC,$B5,$B6
        .byte   $B1,$A3,$A9,$AF,$AC,$AC,$B5,$B6
        .byte   $B1,$A4,$AA,$B0,$AC,$AC,$B5,$B6
        .byte   $B1,$A5,$AB,$AC,$AC,$B9,$BB,$B6
        .byte   $B1,$B7,$B8,$B8,$B8,$BA,$BC,$B6
        .byte   $00,$00,$00,$00,$00,$20,$20,$10
        .byte   $00,$00,$00,$00,$00,$40,$40,$E0
        .byte   $00,$0E,$31,$43,$44,$84,$87,$BC
        .byte   $00,$00,$0E,$3C,$3B,$7B,$78,$43
        .byte   $00,$00,$00,$00,$83,$45,$4B,$57
        .byte   $00,$00,$00,$00,$00,$82,$84,$88
        .byte   $04,$00,$49,$1B,$1F,$1F,$9F,$CF
        .byte   $19,$1F,$BF,$FF,$FF,$FF,$7F,$3F
        .byte   $A4,$94,$C2,$C3,$F8,$F9,$F1,$E3
        .byte   $C8,$E9,$FC,$FC,$FF,$FE,$FE,$FC
        .byte   $00,$00,$00,$00,$C0,$20,$D0,$C8
        .byte   $00,$00,$00,$00,$00,$C0,$20,$30
        .byte   $48,$21,$1F,$0F,$07,$07,$02,$01
        .byte   $37,$1E,$00,$06,$03,$03,$01,$00
        .byte   $53,$91,$12,$3F,$7F,$FF,$77,$23
        .byte   $8C,$0E,$0D,$14,$34,$72,$E2,$C1
        .byte   $E7,$FF,$00,$F1,$CA,$84,$B1,$B1
        .byte   $1F,$00,$FF,$0E,$04,$00,$00,$00
        .byte   $FF,$F8,$03,$FF,$1F
L9095:  .byte   $0F,$8E,$8C
        cpx     #$07
        .byte   $FC,$00,$00,$00,$01,$03,$08,$18
        .byte   $34,$62,$E2,$E2,$3E,$1E,$F0
        cpx     #$C8
        .byte   $9C,$9C,$1C,$C4,$EC,$C1,$00,$00
        .byte   $00,$00,$00,$00,$01,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$C6,$FF,$4F
        .byte   $30,$1F,$7A,$FF,$F8,$80,$46,$3F
        .byte   $0F,$00,$17,$78,$C0,$1F,$FC,$04
        .byte   $3C,$F2,$79,$FE,$1D,$00,$0B,$FB
        .byte   $C3,$01,$B0,$18,$0E,$1F,$0F,$0D
        .byte   $1D
        rol     a:L00C0,x
        brk
        .byte   $E6,$F2,$FA,$EE,$C0,$00,$00,$00
        .byte   $02,$04,$04,$0F,$3F,$7F,$FF,$FF
        .byte   $01,$03,$03,$00,$0F,$3F,$7F
L90FF:  brk
        jsr     L1020
        bpl     L9095
        beq     L90FF
        sed
        cpy     #$C0
        cpx     #$E0
        rts

        .byte   $80,$F0,$00
        php
        bpl     L9123
        bpl     L9120
        .byte   $0F,$1F,$1F,$07,$0F,$0F,$0F,$04
        .byte   $03,$0F,$00
L9120:  .byte   $80
L9121:  .byte   $40,$40
L9123:  beq     L9121
        inc     $FFFF,x
        brk
        .byte   $80,$80,$00,$F0,$FC,$FE,$00,$00
        .byte   $00,$00,$03,$C3,$8F,$CF,$C7,$01
        .byte   $0B,$0B,$3F,$3F,$7F,$3F,$3F,$00
        .byte   $08,$8C,$82,$A7,$E3,$A7,$C7,$20
        .byte   $F0,$F0,$FC,$F8,$FC,$F8,$F8,$E3
        .byte   $FF,$00,$F1,$CA,$84,$B1,$B1,$1F
        .byte   $00,$FF,$0E,$04,$00,$00,$00,$1F
        .byte   $F8,$03,$FF,$1F,$0F,$8E,$8C,$E0
        .byte   $07,$FC,$00,$00,$00,$01,$03,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$31,$7B,$4E,$4E,$39,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$E0,$F0,$70,$70,$E0,$00
        .byte   $00,$00,$00,$04,$44,$42,$21,$00
        .byte   $00,$00,$00,$08,$88,$8C,$C6,$01
        .byte   $00,$25,$25,$03,$07,$27,$2F,$2E
        .byte   $0F,$4F,$5F,$7F,$7F,$FF,$FF,$0B
        .byte   $07,$07,$C6,$CE,$CC,$D8,$13,$F0
        .byte   $F8,$F8,$F9,$F1,$F3,$E7,$ED,$C0
        .byte   $20,$3C,$32,$61,$E1,$E7,$EF,$00
        .byte   $C0,$E0,$EC,$DE,$DE,$D8,$D6,$00
        .byte   $00,$00,$01,$03,$06,$0D,$1D,$00
        .byte   $00,$00,$00,$00,$01,$02,$0A,$2F
        .byte   $1F,$0F,$9F,$C7,$FE,$F8,$F0,$FF
        .byte   $FF,$FE,$7C,$38,$01,$07,$0F,$F7
        .byte   $E7,$CF,$9F,$23
        eor     ($41,x)
        lda     ($89),y
        clc
        bmi     L925C
        cpy     #$80
        .byte   $80,$00,$FE,$FA,$F9,$F9,$F1,$D1
        .byte   $D2,$A4,$E3,$F1,$F0,$F0,$60,$60
        .byte   $61,$43
L9210:  .byte   $80,$40,$E0,$F0,$F0,$10,$08,$04
        .byte   $00,$80,$C0,$E0,$E0,$E0,$F0,$F8
        .byte   $00,$00,$00,$00,$00,$01,$02,$04
        .byte   $00,$00,$00,$00,$00,$00,$01,$03
        and     L9A7C,x
        cmp     ($E0),y
        beq     L923F
        php
        .byte   $1A,$3B,$71,$60,$40,$40,$F0
L923F:  beq     L9210
        ora     $FC39,y
        .byte   $7F,$1F,$03,$07,$30,$E0,$C0,$60
        .byte   $1C,$03,$00,$03,$31,$82,$BC,$71
        .byte   $E3,$8C,$FA,$FF,$00,$01,$03,$3E
L925C:  .byte   $3C,$F3,$07,$C0,$24,$44,$C2,$C2
        .byte   $61,$70,$F8,$3E,$C3,$83,$01,$01
        .byte   $80
        ldy     #$30
        clc
        .byte   $04,$04,$08,$70,$80,$00,$00,$00
        .byte   $F8,$F8,$F0,$80,$00,$00,$00,$00
        .byte   $08,$08,$08,$05,$05,$03,$00,$00
        .byte   $07,$07,$07,$02,$02,$00,$00,$00
        .byte   $04,$14,$34
        sec
        rti

        .byte   $40,$80,$00,$F8,$E8,$C8,$C0,$80
        .byte   $80,$00,$00,$0F,$08,$08,$0F,$3F
        .byte   $7F,$FF,$FF,$06,$07,$07,$00,$0F
        .byte   $3F,$7F,$00,$E0,$40,$20,$10,$90
        .byte   $F0,$F8,$F8,$00,$80,$C0,$E0,$60
        .byte   $80,$F0,$00
        ora     $2020,y
        jsr     L0F13
        .byte   $1F,$1F,$06,$1F,$1F,$1F,$0C,$03
        .byte   $0F,$00,$80
L92D1:  cpy     #$40
        beq     L92D1
        inc     $FFFF,x
        brk
        .byte   $00,$80,$00,$F0,$FC,$FE,$00,$00
        .byte   $00,$01,$02,$04,$09,$09,$08,$00
        .byte   $00,$00,$01,$03,$06,$06,$07,$02
        .byte   $00,$E0,$18,$08,$81,$C1,$0D,$05
        .byte   $0F,$0F,$E7,$F7,$7F,$3F,$FF,$03
        .byte   $77,$4F,$06,$0E
        ldy     L9318
        brk
        .byte   $80,$B0,$F9,$F1,$F3,$E7,$ED,$09
        .byte   $0F,$1F,$3F,$4F,$5B,$7D,$3D
L9318:  asl     $04
        asl     $301C
        bmi     L9351
        .byte   $1A,$86,$04,$C3,$83,$C7,$FE,$F8
        .byte   $F0,$7F,$FF,$3E,$7C,$38,$01,$07
        .byte   $0F,$1D,$0C,$02,$01,$00,$00,$00
        .byte   $00,$0A,$03,$01,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$01,$0C,$0C,$07,$00,$00,$00
        .byte   $00,$00
L9351:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $38,$7C,$7C,$9C,$9C,$F8,$80,$03
        .byte   $0D,$12,$17,$2E,$46,$43,$BF,$00
        .byte   $02,$0C,$0C,$17,$3F,$3F,$4F,$30
        .byte   $48,$C8,$0C,$12
        ldy     $F6
        .byte   $FA,$00,$30,$30,$F0,$EC,$F8,$F8
        .byte   $C4,$BF,$97,$93,$9F,$4F,$23,$18
        .byte   $07,$47,$6B,$6C,$73,$3F,$1F,$07
        .byte   $00,$F9,$B1,$31,$F2,$E2,$C4,$18
        .byte   $E0
        stx     $CE4E
        .byte   $1C,$FC,$F8
        cpx     #$00
        brk
        .byte   $03,$04,$16,$2A,$22,$22,$7A,$00
        .byte   $00,$03
        ora     ($15,x)
        .byte   $1F,$1F,$0F,$00,$80,$50,$68,$44
        .byte   $04,$C2,$FA,$00,$00,$80,$90,$B8
        .byte   $F8,$FC,$C4,$7F,$57,$53,$4F,$27
        .byte   $13,$08,$07,$07,$2B,$2C,$33,$1F
        .byte   $0F,$07,$00,$F2,$B2,$32,$E4,$C4
        .byte   $88,$30,$C0,$8C,$4C,$CC,$18,$F8
        .byte   $F0,$C0,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$F2,$17,$52,$72
        .byte   $47,$42,$42,$03,$0D,$3D,$7D,$FD
        .byte   $FD,$FD,$FD,$00,$02,$0E,$3E,$7E
        .byte   $FE,$FE,$FE,$0F,$1F,$1F,$3E,$3C
        .byte   $78,$78,$F8,$07,$0F,$0F,$1E,$1C
        .byte   $38,$38,$78,$FD,$FD,$FD,$1D,$0D
        .byte   $05,$05,$05,$FE,$FE,$FE,$1E,$0E
        .byte   $06,$06,$06,$BF,$BF,$BF,$BF,$BF
        .byte   $BF,$BF,$BF,$7F,$7F,$7F,$7F,$7F
        .byte   $7F,$7F,$7F,$F0,$F8,$F8,$FC,$FC
        .byte   $FE,$FE,$FF,$E0,$F0,$F0,$F8,$F8
        .byte   $FC,$FC,$FE,$00,$00,$01,$01,$01
        .byte   $01,$03,$03,$00,$00,$00,$00,$00
        .byte   $00,$01,$01,$F8,$FC,$FE,$FF,$FF
        .byte   $FF,$FF,$FF,$78,$7C,$FE,$FF,$FF
        .byte   $FF,$FF,$FF,$05,$0D,$1D,$FD,$FF
        .byte   $FE,$FE,$FF,$06,$0E,$1E,$FE,$FD
        .byte   $FB,$FB,$FD,$BF,$BF,$BF,$BF,$FF
        .byte   $7F,$7F,$FF,$7F,$7F,$7F,$7F,$BF
        .byte   $DF,$DF,$BF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FE,$FE,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$03,$07,$0B,$13,$23
        .byte   $43,$81,$81,$01,$01,$05,$0D,$1D
        .byte   $3D,$7E,$7E,$DF,$9F,$8F,$8F,$8F
        .byte   $CF,$E7,$F7,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
        .byte   $FC,$FC,$F8,$FE,$3F,$C7,$F8,$FD
        .byte   $FB,$FB,$F7,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$C0,$C0,$C0,$C0,$C0
        .byte   $C0,$80,$80,$80,$80,$80,$80,$80
        .byte   $80,$00,$00,$81,$81,$81,$41,$40
        .byte   $40,$40,$20,$7E,$7E,$7E,$3E,$3F
        .byte   $3F,$3F,$1F,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$7F,$FF,$FF,$FF,$FF,$7F
        .byte   $7F,$7F,$BF,$F8,$F0,$F0,$E0,$E0
        .byte   $F8,$FF,$FF,$F7,$EF,$EF,$DF,$DF
        .byte   $E7,$F8,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FE,$FF,$FF,$FF,$FF,$FE
        .byte   $FE,$FE,$FC,$80,$80,$80,$80,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$20,$10,$10,$08,$04
        .byte   $02,$01,$00,$1F,$0F,$0F,$07,$03
        .byte   $01,$00,$00,$7F,$3F,$3F,$1F,$1F
        .byte   $0F,$07,$83,$BF,$DF,$DF,$EF,$EF
        .byte   $F7,$FB,$7D,$FF,$FC,$FC,$F8,$F8
        .byte   $F8,$E9,$C6,$FC,$FB,$FB,$F7,$F7
        .byte   $E7,$C6,$80,$00,$80,$40,$40,$40
        .byte   $80,$00,$00,$00,$00,$80,$80,$80
        .byte   $00,$00,$00,$43,$23,$11,$09
        ora     $03
        ora     ($01,x)
        and     $0E1D,x
        asl     $02
        brk
        .byte   $00,$00,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$9E,$FF,$FF,$FF,$FF,$FF,$0F
        .byte   $F6,$F0,$FF,$FF,$FE,$FC,$F0,$C0
        .byte   $80,$00,$FF,$FE,$FC,$F0,$C0,$80
        .byte   $00,$00,$00,$00,$00,$00,$03,$0C
        .byte   $30,$20,$00,$00,$00,$00,$00,$03
        .byte   $0F,$1F,$03,$0C,$30,$C0,$00,$00
        .byte   $00,$00,$00,$03,$0F,$3F
L95CC:  .byte   $FF,$FF
L95CE:  .byte   $FF,$FF
L95D0:  sed
        sed
        php
        php
        php
        php
        php
        php
        beq     L95DA
L95DA:  beq     L95CC
        beq     L95CE
        beq     L95D0
        jsr     L011E
        brk
        .byte   $00,$00,$00,$00,$1F,$01,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$C0,$3C
        .byte   $02,$01,$00,$00,$FF,$FF,$3F,$03
        ora     (L0000,x)
        brk
        .byte   $00,$08,$08,$08,$08,$08,$88,$68
        .byte   $18,$F0,$F0,$F0,$F0,$F0,$70,$10
        .byte   $00,$00,$00,$00,$06,$0D,$1D,$3E
        .byte   $3E,$00,$00,$00,$00,$06,$0E,$1F
        .byte   $1F,$00,$00,$00,$00,$F8,$08,$90
        ldy     #$00
        brk
        .byte   $00,$00,$00,$F0,$60,$40,$00,$00
        .byte   $00,$00,$01,$01,$03,$03,$00,$00
        .byte   $00,$00,$00,$00,$01,$01,$7F,$7F
        .byte   $FF,$FF,$FF,$F0,$E0,$C0,$3F,$3F
        .byte   $7F,$7F,$FF,$F0,$E0,$C0,$40,$40
        .byte   $BE,$A2,$D4,$D8,$68,$28,$80,$80
        .byte   $C0,$DC,$E8,$E0,$70,$30,$06,$02
        .byte   $7D,$45,$2B,$1B,$17,$17,$01,$01
        .byte   $03,$3B,$17,$07,$0F,$0F,$FE,$FE
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FC,$FC
        .byte   $FE,$FE,$FF,$FF,$FF,$FF,$03,$03
        .byte   $07,$07,$07,$07,$07,$07,$01,$01
        .byte   $03,$03,$03,$03,$03,$03,$C0,$C0
        .byte   $C0,$E0,$F0,$FF,$FF,$FF,$C0,$C0
        .byte   $C0,$E0,$F0,$FF,$FF,$FF,$34,$36
        .byte   $3B,$7F,$FF,$FE,$FE,$FF,$38,$38
        .byte   $3C,$7C,$FD,$FB,$FB,$FD,$2F,$6F
        .byte   $DF,$FF,$FF,$7F,$7F,$FF,$1F,$1F
        .byte   $3F,$3F,$BF,$DF,$DF
L96BF:  .byte   $BF,$7F,$3F,$3F,$1F,$1F,$0F,$07
        .byte   $C3,$BF,$DF,$DF,$EF,$EF,$F7,$FB
        .byte   $3D,$FF,$FC,$FC,$F8,$F8,$F8,$E9
        .byte   $E6,$FC,$FB,$FB,$F7,$F7,$E7,$C6
        .byte   $C0,$31,$0C,$03,$00,$00,$00,$00
        .byte   $00,$0E,$03,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$7F,$FF,$0F,$03,$01
        .byte   $00,$FF,$7F,$BF,$0F,$03,$01,$00
        .byte   $00,$C0,$C0,$80,$80,$80,$00,$80
        .byte   $80,$80,$80,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$01,$03
        .byte   $07,$00,$00,$00,$00,$00,$00,$01
        .byte   $03,$00,$18,$3C,$3C,$18,$00,$00
        .byte   $00,$3C,$66,$C3,$C3,$E7,$FF,$7E
        .byte   $3C,$01,$41,$21,$1B,$1F
L9735:  ora     $FF1F
        brk
        .byte   $00,$00,$00,$00,$02,$04,$00,$00
        .byte   $04
        php
        bcs     L9735
        cpx     #$F0
        inc     a:L0000,x
        brk
        .byte   $00,$00,$00,$00,$00,$1F,$0F,$1F
        .byte   $1B,$21,$41,$01,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$F0,$E0,$F0
        .byte   $B0,$08,$04,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$03,$01
        .byte   $0D,$3C,$64,$C7,$CD,$00,$02,$02
        .byte   $0E,$3F,$7C,$FF,$FE,$00,$C0,$80
        .byte   $B0,$3C,$3E,$FF,$BF,$00,$40,$40
        .byte   $70,$FC,$3E,$FF,$7F,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$03,$03,$03,$03,$FD,$FC,$FC
        .byte   $C7,$83,$81,$01,$00,$FE,$FF,$FC
        .byte   $C7,$83,$81,$01,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$01,$01,$00
        .byte   $00,$00,$01,$03,$07,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$80
        .byte   $00,$C0,$C0,$E0,$F0,$00,$00,$00
        .byte   $30,$30,$68,$4C,$DE,$07,$0F,$0F
        .byte   $37,$37,$7A,$7C,$FE,$00,$00,$00
        .byte   $00,$00,$00,$00,$40,$FE,$FF,$7F
        .byte   $7F,$7F,$7F,$3F,$4F,$00,$00,$00
        .byte   $00,$00,$00,$01,$03,$7F,$FF,$FE
        .byte   $FE,$FE,$FE,$FD,$F3,$00,$00,$00
        .byte   $00,$00,$00,$00,$E0,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$18,$64,$9C,$00,$00,$00
        .byte   $00,$00,$00,$18,$60,$01,$02,$05
        .byte   $04,$09,$0B,$0F,$0B,$00,$01,$03
        .byte   $03,$06,$04,$01,$07,$11,$D1,$12
        .byte   $7E,$C2,$02,$C1,$00,$E0,$E0,$E1
        .byte   $81,$3D,$FD,$FE,$FF,$3C,$7C,$7C
        .byte   $78,$78,$70,$68,$C4,$C8,$88,$98
        .byte   $90,$90,$80,$90,$38,$16,$24,$21
        .byte   $43,$46,$3F,$23,$40,$0F,$1F,$1E
        .byte   $3C,$39,$00,$1C,$3F,$78,$CC,$84
        .byte   $04,$05,$89,$83,$0F,$87,$03,$03
        .byte   $03,$82,$06,$1C,$F0,$04,$02,$02
        .byte   $E3,$B7,$57,$5D,$39,$F8,$FC,$FC
        .byte   $1C,$48,$E8,$E2,$C6,$03,$07,$07
        .byte   $07,$04,$03,$00,$00,$00,$02,$00
        .byte   $00,$03,$00,$00,$00,$80,$E0,$C1
        .byte   $87,$1F,$FB,$DB,$0B,$7F,$1F,$3E
        .byte   $78,$E0,$04
        sty     $3844
        .byte   $77,$FF,$FF,$FE,$FE,$FD,$FD,$C7
        .byte   $8F,$0F,$0F,$0F,$0F,$0E
        asl     $62F1,x
        .byte   $62,$44,$58
        cpx     #$80
        brk
        .byte   $0E,$9C,$9C,$B8
        ldy     #$00
        brk
        .byte   $00,$0F,$1F,$1F,$7F,$BF,$BF,$5D
        .byte   $3E,$00,$00,$00,$24,$41,$7F,$3E
        .byte   $00,$FA,$F4,$E8,$D0,$E0,$C0,$80
        .byte   $00,$3C
L98D9:  .byte   $38,$70,$E0,$80,$00,$00,$00,$3F
        .byte   $7F,$FF,$FF,$FB,$FF,$FF,$FF,$C0
        .byte   $83,$07,$07,$07,$03,$03,$03,$F1
        .byte   $62,$A2,$A4,$B8,$A0,$40,$80,$0E
        .byte   $9C,$DC,$D8,$C0,$C0,$80,$00,$0F
        .byte   $07,$07,$07,$0F,$0F,$1F,$2F,$00
        .byte   $00,$00,$00,$00,$00,$09,$10,$FD
        .byte   $FE,$FA,$FC,$F4,$F8,$E8,$F0,$06
        .byte   $04,$0C,$08,$18,$10,$30,$60,$2F
        .byte   $17,$0F,$00,$00,$00,$00,$00,$1F
        .byte   $0F,$00,$00,$00,$00,$00,$00,$A0
        .byte   $40,$80,$00,$00,$00,$00,$00,$C0
        .byte   $80,$00,$00,$00,$00,$00,$00,$1F
        .byte   $20,$58,$5C,$BC,$BC,$BC,$98,$00
        .byte   $1F,$27,$23,$43,$43,$43,$67,$00
        .byte   $E0,$1C,$E2,$79,$0C,$00,$00,$00
        .byte   $00,$E0,$FC,$FE,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$80,$40,$40,$00
        .byte   $00,$00,$00,$00,$00,$80,$80,$40
        .byte   $20,$1F,$00,$00,$00,$00,$00,$3F
        .byte   $1F,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$01,$00,$00,$00,$00,$FF
        .byte   $FF,$00,$00,$00,$00,$00,$00,$40
        .byte   $A0,$50,$10,$F0,$B0,$90,$E0,$80
        .byte   $40,$E0,$E0,$00,$60,$60,$00,$B0
        .byte   $20,$00,$00,$00,$00,$00,$00,$60
        .byte   $40,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$0F,$10,$2E,$5E,$00
        .byte   $00,$00,$00,$00,$0F,$11,$21,$00
        .byte   $00,$00,$00,$00,$80,$40,$40,$00
        .byte   $00,$00,$00,$00,$00,$80,$80,$BE
        .byte   $BC,$B8,$40,$20,$10,$08,$04,$41
        .byte   $43,$47,$3F,$1F,$0F,$07,$03,$20
        .byte   $A0,$D0,$70,$68,$38,$14,$04,$C0
        .byte   $C0,$E0,$E0,$F0,$F0,$F8,$F8,$02
        .byte   $01,$00,$00,$00,$00,$00,$00,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$02,$02,$01,$01,$00,$00,$00
        .byte   $00,$00,$01,$00,$00,$00,$00,$06
        .byte   $02,$12,$FA,$F9,$F9,$F9,$F9,$00
        .byte   $0C,$1C,$FC,$FE,$FE,$7E,$7E,$00
        .byte   $00,$00,$00,$01,$07,$0B,$F7,$00
        .byte   $00,$00,$00,$00,$01,$07,$0F,$F1
        .byte   $E1,$F2,$B2,$FA,$E6,$E4,$C8,$7E
        .byte   $1E,$0C,$4C,$E4,$F8,$F8,$F0,$03
        .byte   $05,$0B,$17,$14,$20,$20,$3F,$00
        .byte   $03,$07,$0F,$0F,$1F,$1F,$00,$0F
        .byte   $C6,$E3,$01,$00,$00,$00,$FF,$F7
        .byte   $FB,$FC,$FE,$FF,$FF,$FF,$00,$90
        .byte   $30,$20,$E0,$90,$B0,$90,$E0,$E0
        .byte   $C0,$C0,$00,$60,$60,$60,$00,$00
        .byte   $00,$00,$00,$00,$00,$10,$30,$00
        .byte   $00,$00,$00
L9A7C:  .byte   $00,$00,$00,$00,$00,$00,$01,$03
        .byte   $03,$03,$01,$01,$00,$00,$00,$03
        .byte   $01,$01,$00,$00,$68,$C8
        cpx     $F4
        .byte   $F4,$FA,$FA,$6A,$10,$30,$78,$F8
        .byte   $F8,$FC,$FC,$9C,$00,$00,$00,$01
        .byte   $03,$07,$7F,$87,$00,$00,$00,$00
        .byte   $01,$03,$07,$7B
        sbc     $EDFD,y
        inc     $F2,x
        cpx     $E8
        inx
        asl     $02
        .byte   $72,$F8,$FC,$F8,$F0,$F0,$01,$02
        .byte   $05,$0B,$0A,$10,$10,$1F,$00,$01
        .byte   $03,$07,$07,$0F,$0F,$00,$E3,$F1
        .byte   $80,$00,$00,$00,$FF,$00,$FD,$FE
        .byte   $FF,$FF,$FF,$FF,$00,$00,$D0,$90
        .byte   $F0,$48,$58,$48,$F0,$00
        cpx     #$60
        brk
        .byte   $B0,$B0
        bcs     L9AEF
L9AEF:  brk
        .byte   $00,$00
L9AF2:  .byte   $00,$06,$05,$06,$07,$0F,$00,$00
        .byte   $00,$00,$02,$03,$03,$07,$00,$00
        .byte   $00,$00,$80,$40,$20,$A0,$00,$00
        .byte   $00,$00,$00,$80,$C0,$C0,$1F,$3F
        .byte   $7F,$0F,$03,$01,$01,$02,$07,$0F
        .byte   $0F,$02,$00,$00,$00,$01
L9B20:  bne     L9AF2
        php
        iny
        sec
        sed
        inx
        inx
        cpx     #$E0
        beq     L9B5C
        cpy     #$E0
        beq     L9B20
        .byte   $02
        .byte   $03,$0C
        bpl     L9B5C
        bit     $585C
        ora     (L0000,x)
        .byte   $03,$0F,$1F,$1F,$3F,$3F
        cpx     $76CA
        rol     a
        .byte   $1C,$04,$08,$08,$F0,$34,$88,$DC
        .byte   $E0,$F8,$F0,$F0,$58,$50,$40,$20
        .byte   $21,$1E,$00,$00,$3F,$3F,$3F,$1F
L9B5C:  asl     a:L0000,x
        brk
        .byte   $10,$10,$20,$40,$80,$00,$00,$00
        .byte   $E0,$E0,$C0,$80,$00,$00,$00,$00
        .byte   $04,$04
        cpy     $2A7A
        .byte   $32,$3C,$54,$F8,$F8,$30,$04,$1C
        .byte   $0C,$00,$38
        inx
        bne     L9BE3
        brk
        .byte   $00,$00,$00,$00,$10,$60,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$30,$78,$F8
        .byte   $78,$70,$60,$00,$00,$00,$01,$02
        .byte   $02,$04,$04,$07,$00,$00,$00,$01
        .byte   $01,$03,$03,$00,$00,$01,$05,$0F
        .byte   $27,$1F,$1F,$7F,$07,$1F,$3F,$7F
        .byte   $7F,$FF,$FF,$FF,$00,$00,$00,$00
        .byte   $02,$03,$0F,$07,$00,$00,$03,$1F
        .byte   $1F,$1F,$3F,$3F,$08,$00,$00,$41
        .byte   $00,$00,$00,$08,$08,$00,$00,$41
        .byte   $00,$00,$00,$08,$00,$00,$00
L9BE3:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$01,$18,$39,$30,$00,$00,$00
        .byte   $1F,$20,$58
        ldx     $AF,y
        asl     $3F
        .byte   $F3,$C8,$7F,$80,$00,$80,$00,$06
        .byte   $3F,$77,$80,$40,$20,$20,$E0,$78
        ldx     L96BF,y
        .byte   $63,$1A,$05,$00,$E0,$70,$76,$6F
        .byte   $1E,$05,$03,$00,$00,$00,$00,$80
        .byte   $40,$E0,$E0,$00,$00,$00,$00,$00
        .byte   $80,$C0,$C0,$0C,$0C,$11,$0E,$00
        .byte   $00,$00,$00,$9F,$9F,$8E,$40,$20
        .byte   $1F,$00,$00,$80,$80,$00,$00,$00
        .byte   $00,$00,$00,$20,$20,$20,$40,$80
        .byte   $00,$00,$00,$05,$03,$02,$02,$01
        .byte   $01
        ora     ($01,x)
        .byte   $03,$00,$01,$01,$00,$00,$00,$00
        .byte   $D0,$B0,$78,$F8,$F8,$E4,$0C,$7C
        .byte   $A0,$60,$F0,$F0,$E0,$18,$F8,$F8
        .byte   $00,$00,$00,$00,$01,$18,$3F,$3F
        .byte   $00,$00,$00,$1F,$20,$58,$B6,$AF
        .byte   $1F,$1F,$1F,$0E,$00,$00,$00,$00
        .byte   $9F,$9F,$8E,$40,$20,$1F,$00,$00
        .byte   $3C,$42,$B1,$B1,$81,$81,$42,$3C
        .byte   $00,$3C,$7E,$7E,$7E,$7E,$3C,$00
        .byte   $00,$03,$0F,$1C,$39,$E3,$47,$CF
        .byte   $00,$00,$03,$0F
        asl     $F83C,x
        .byte   $73,$FE,$FF,$3F,$FF,$FF,$FF,$FF
        .byte   $83,$00,$FC,$C0,$00,$00,$00,$7E
        .byte   $FC,$00,$C0,$C0,$80,$00,$00,$80
        .byte   $F0,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$9C,$90
L9CE2:  .byte   $83,$8F,$C0,$70,$FF,$FF,$FF,$FF
        .byte   $FC,$7F,$3F,$8F,$00,$00,$3F,$FF
        .byte   $FF,$FF,$0F,$7F,$FF,$FF,$C0,$00
        .byte   $00,$FE,$F0,$80,$00,$00
L9D00:  beq     L9CE2
        cpy     #$C0
        cpy     #$E0
        beq     L9D00
        brk
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$03,$0F,$7C,$73,$61,$00
        .byte   $00,$00,$00,$03,$0F,$1C,$3E,$00
        .byte   $07,$7F,$FF,$9F,$FF,$FF,$FF,$00
        .byte   $00,$07,$78,$E0,$00,$00,$00,$00
        .byte   $F8,$FC,$F8,$F0,$F0,$F8,$FC,$00
        .byte   $00,$F0,$00,$00,$00,$00,$00,$61
        .byte   $40,$40,$03,$41,$61,$78,$7F,$7F
        .byte   $7F,$7F,$7C,$3E,$1F,$07,$00,$FF
        .byte   $00,$1F,$FF,$FF,$FF,$3F,$FF,$FF
        .byte   $FF,$E0,$00,$00,$C0,$FF,$00,$FF
        .byte   $1F,$FE,$FC,$FC,$FE,$FF,$F8,$FC
        .byte   $E0,$00,$00,$00,$00,$F0,$00,$00
        .byte   $00,$00,$15,$15,$00,$00,$00,$00
        .byte   $00,$15,$15,$15,$15,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$15,$15,$15,$15,$00,$00,$04
        .byte   $1C,$1E,$3E,$3C,$38,$18,$10,$04
        .byte   $1C,$1E,$3E,$3C
        sec
        clc
        bpl     L9DA9
        .byte   $0C,$1C,$1C,$1C,$18,$08,$08,$08
L9DA9:  .byte   $0C,$1C,$1C,$1C,$18,$08,$08,$08
        .byte   $08,$08,$08,$08,$08,$08,$08,$08
        .byte   $08,$08,$08,$08,$08,$08,$08,$08
        .byte   $1C,$3E,$3E,$3E,$1C,$08,$00,$08
        .byte   $1C,$3E,$3E,$3E,$1C,$08,$00,$00
        .byte   $08,$1C,$3E,$1C,$08,$00,$00,$00
        .byte   $08,$1C,$3E,$1C,$08,$00,$00,$00
        .byte   $00,$08,$1C,$08,$00,$00,$00,$00
        .byte   $00,$08,$1C,$08,$00,$00,$00,$08
        .byte   $08,$1C,$7F,$1C,$08,$08,$08,$08
        .byte   $08,$1C,$7F,$1C,$08,$08,$08,$34
        .byte   $3C,$6A,$7A,$5A,$5A,$24,$34,$18
        .byte   $18,$34,$24,$24,$24,$18,$18,$07
        .byte   $0F,$1A,$15,$3E,$2A,$7F,$87,$01
        .byte   $05,$0D,$08,$00,$1C,$00,$7F,$60
        .byte   $70,$58,$A8,$7C,$54,$FE,$E1,$80
        .byte   $A0,$B0,$10,$00
        sec
        brk
        .byte   $FE,$0C,$1B,$14,$14,$7F,$C2,$C2
        .byte   $C2,$07,$0C,$08,$08,$00,$3F,$3F
        .byte   $3F,$B7,$B7,$87,$FF,$FF,$FF,$FF
        .byte   $FC,$6F,$4F,$7F,$00,$00,$FF,$F0
        .byte   $F3,$82,$FF,$30,$38,$18,$18,$08
        .byte   $08,$7F,$00,$3E,$3E,$1C,$1C,$08
        .byte   $08,$FF,$FF,$30,$38,$18,$18,$08
        .byte   $08,$FF,$00,$3E,$3E,$1C,$1C,$08
        .byte   $08,$FF,$FF,$60,$70,$30,$30,$10
        .byte   $10,$FF,$00,$7C,$7C,$38,$38,$10
        .byte   $10,$41,$FF,$60,$70,$30,$30,$10
L9E87:  bpl     L9E87
        brk
        .byte   $7C,$7C
        sec
        sec
        bpl     L9EA0
        .byte   $0F,$11,$1F,$27,$40,$FF,$B7,$FF
        .byte   $00,$0F,$00,$1F,$3F,$00,$5B,$00
L9EA0:  .byte   $00,$00,$00,$00,$00,$3C,$5A,$5A
        .byte   $00,$00,$00,$00,$00,$00,$3C,$3C
        .byte   $1F,$2D,$2D,$4E,$5A,$DA,$B4,$FC
        .byte   $00,$1E,$1E,$3C,$3C,$3C,$78,$00
        .byte   $FC,$B4,$B4,$BA,$5A,$5D,$2D,$2D
        .byte   $00,$78,$78,$7C,$3C,$3E,$1E
        asl     a:L0000,x
        brk
        .byte   $01,$02,$02,$05,$07,$00,$00,$00
        .byte   $00,$01,$01,$03,$00,$2D,$4D,$99
        .byte   $32,$64,$C8,$90,$F0,$1E,$3E,$7E
        .byte   $FC,$F8,$F0,$E0,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$7F,$0B,$01
        .byte   $01,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$FC,$B0,$80
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $04,$84,$07,$74,$3F,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $18,$10,$71,$F8,$C0,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$09,$01,$03,$07,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$80,$00,$80
        .byte   $80,$80,$C0,$E4,$D0,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$FF,$77,$41
        .byte   $0F,$2D,$05
L9F6E:  .byte   $07,$03,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$FF,$37,$F4,$C0,$E0,$C4
        .byte   $C4,$80,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$03,$09,$01,$01,$01,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$A0,$80,$80,$40,$80,$80
        .byte   $00,$80,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$01,$01,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $01,$07,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $80,$E0,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$80,$00
        .byte   $40,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$01,$04,$01
        .byte   $00,$01,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$20,$00,$40
        .byte   $00,$00,$FF,$FF,$01,$C0,$CD,$CD
        .byte   $DF,$DF,$FF,$FF,$01,$C0,$CD,$CD
        .byte   $DF,$DF,$C1,$CC,$CD,$C1,$DF,$C1
        .byte   $FF,$00,$C1,$CC,$CD,$C1,$DF,$C1
        .byte   $FF,$00,$FF,$FF,$80,$05,$B5,$B5
        .byte   $FF,$FF,$FF,$FF,$80,$05,$B5,$B5
        .byte   $FF,$FF,$81,$35,$B5,$85,$BD,$81
        .byte   $FF,$00,$81,$35,$B5,$85,$BD,$81
        .byte   $FF,$00,$7F,$FF,$C0,$B1,$81,$82
        .byte   $80,$82,$7F,$C0,$BF,$C7,$C7,$FE
        .byte   $C0,$DE,$02,$82,$99,$80,$98,$C0
        .byte   $60,$3F,$1E,$FE,$E3,$E3,$E3,$E3
        .byte   $7F,$3F,$FF,$FF,$D0,$FF,$00,$24
        .byte   $24,$24,$FF,$50,$7F,$FF,$00,$36
        .byte   $36,$36,$00,$FD,$00,$40,$7F,$40
        .byte   $7F,$C0,$00,$FD,$1D,$C0,$FF,$FF
        .byte   $FF,$C0,$FF,$FF,$0B,$FF,$00,$49
        .byte   $49,$49,$FF,$0A,$FE,$FF,$00,$6D
        .byte   $6D,$6D,$00,$BF,$00,$02,$FE,$02
        .byte   $FE,$03,$00,$BF,$B8,$03,$FF,$FF
        .byte   $FF,$03
        inc     $03FF,x
        sta     $4181,y
        ora     ($41,x)
        inc     $FD03,x
        .byte   $E3,$E3,$7F,$03,$7B,$40
        eor     ($B1,x)
        ora     ($31,x)
        .byte   $03,$06,$FC,$78,$7F,$C7,$C7,$C7
        .byte   $C7,$FE,$FC,$52,$D2,$12,$E2,$0A
        .byte   $02,$FC,$00,$76,$F6,$F6,$E6,$0E
        .byte   $FE,$FC,$00,$00,$BF,$00,$00,$FF
        .byte   $00,$FF,$00,$00,$BF,$BF,$00,$FF
        .byte   $FF,$FF,$00,$EB,$0B,$08,$E7,$00
        .byte   $36,$A4,$64,$ED,$EC,$0F,$E7,$E0
        .byte   $36,$B6,$F6,$00,$DF,$10,$00,$FF
        .byte   $00,$FF,$00,$00,$DF,$DF,$00,$FF
        .byte   $FF,$FF,$00,$9F,$80,$9F,$C0,$FF
        .byte   $DF,$9F,$FF,$9F,$80,$9F,$C0,$FF
        .byte   $DF,$9F,$FF,$C0,$80,$9F,$88,$9F
        .byte   $88,$9F,$80,$C0,$80,$9F,$88,$9F
        .byte   $88,$9F,$80
        sbc     $FD11,x
        .byte   $03,$FF,$FE,$FC,$FF,$FD,$11,$FD
        .byte   $03,$FF,$FE,$FC,$FF,$03,$01,$FD
        .byte   $01,$FD,$01,$FD,$01,$03,$01,$FD
        .byte   $01,$FD,$01,$FD,$01,$00
LA141:  .byte   $FF,$00,$55,$FF,$FF,$FF,$FF,$00
        .byte   $FF,$FF,$AA,$00,$00,$00,$00,$FF
        .byte   $AA,$00,$00,$AA,$FF
LA156:  .byte   $FF,$00,$00,$55,$FF,$FF,$FF
LA15D:  .byte   $FF,$FF,$00,$00,$FF,$00,$55,$FF
        .byte   $FF,$FF,$FF,$00,$FF,$FF,$AA,$00
        .byte   $00,$00,$00,$FF,$AA,$00,$00,$AA
        .byte   $FF,$FF,$00
LA178:  .byte   $00,$55,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $D0,$D0,$D7,$D0
        beq     LA15D
        beq     LA178
        bcs     LA141
        .byte   $B7,$B0,$F7,$B7,$F0,$90,$D8,$C5
        cpy     #$D0
        bne     LA156
        cpx     #$7F
        clv
        lda     LA5BD,x
        lda     $A4
        .byte   $DF,$7F,$4A
        asl     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        .byte   $5F,$41,$6E,$0E,$6E,$6E,$6E,$4E
        .byte   $5F,$5F,$21
        cmp     ($29,x)
        and     #$01
        .byte   $03,$06,$7C,$3F,$FF,$C3,$C3,$C3
        .byte   $7F,$7E,$7C,$7F,$E0,$D0,$D0,$C0
        .byte   $C0,$C5,$D8,$7F,$DF,$A4,$A5,$A5
        .byte   $BD,$BD,$B8,$F7,$F0,$D0,$F7,$D0
        .byte   $D0,$D7,$D0,$97,$F0,$B7,$F7,$B0
        .byte   $B7,$B7,$B0,$7C,$06,$03,$29,$29
        .byte   $01,$C1,$21,$7C,$7E,$7F,$C3,$C3
        .byte   $C3,$FF,$3F,$41,$5F,$4A,$4A,$4A
        .byte   $4A,$0A,$4A,$5F,$5F,$4E,$6E,$6E
        .byte   $6E,$0E,$6E,$40,$1F,$20,$51,$42
        .byte   $44,$48,$51,$C0,$9F,$3F,$67,$66
        .byte   $7C,$79,$73,$53,$52,$52,$52,$52
        .byte   $52,$52,$52,$77,$76,$76,$76,$76
        .byte   $76,$76,$76,$00,$FF,$00,$FF,$00
        .byte   $00,$FF,$80,$00,$FF,$FF,$FF,$00
        .byte   $FF,$FF,$80,$21,$21,$D3,$20,$03
        .byte   $04,$29,$EB,$3B,$3B,$DB,$E0,$E3
        .byte   $07,$EE,$ED,$01,$FB,$03,$FA,$00
        .byte   $03,$BF,$03,$01,$FA,$FA,$FA,$01
        .byte   $BE,$BE,$02,$4B,$4B,$6F,$03,$FD
        .byte   $FF,$00,$FF,$6E,$6E,$6E,$02,$FE
        .byte   $00,$FF,$FF,$80,$D7,$40,$57,$80
        .byte   $50,$5F,$40,$80,$57,$D7,$57,$80
        .byte   $DF,$DF,$C0,$44,$44,$56,$40,$3F
        .byte   $FF,$00,$FF,$D6,$D6,$D6,$C0,$FF
        .byte   $00,$FF,$FF,$00,$FF,$00,$FF,$00
        .byte   $00,$FF,$01,$00,$FF,$FF,$FF,$00
        .byte   $FF,$FF,$01,$44,$44,$DB,$04,$C7
        .byte   $20,$94,$D7,$DC,$DC,$DB,$07,$C7
        .byte   $E0,$77,$B7,$02,$F8,$04,$92,$42
        .byte   $22,$12,$8A,$03,$F9,$FC,$E6,$66
        .byte   $3E,$9E,$CE,$CA
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        inc     $6E6E
        ror     $6E6E
        ror     L9F6E
        .byte   $80,$9C,$80,$90,$81,$83,$B7,$9F
        .byte   $80,$9D,$83,$97,$8F,$9F,$BF,$9F
        .byte   $8F,$8F,$80,$85,$80,$05,$E0,$BF
        .byte   $BF,$BF,$B0,$B7,$B0,$07,$E0,$FD
        .byte   $01,$01,$01,$F9,$F9
        sbc     $FD99,y
        ora     ($F9,x)
        sbc     $F9F9,y
        sbc     L98D9,y
        .byte   $E7,$DC,$B0,$20,$66,$4F,$4F,$98
        .byte   $E7,$DF,$BF,$3F,$79,$70,$70,$9F
        .byte   $80,$80,$81,$9E,$93,$93,$9E,$9F
        .byte   $80,$9F,$9F,$9E,$9B,$93,$9F,$1E
        .byte   $E7,$7B,$1D,$0C
        asl     $0606
        asl     $FBE7,x
        sbc     $FEFC,x
        inc     $FDFE,x
        ora     ($BD,x)
        cmp     ($ED,x)
        adc     ($B9),y
        eor     $01FD,x
        lda     $EDC1,x
        adc     ($B9),y
        eor     $F169,x
        sbc     ($01),y
        lda     ($01,x)
        ldy     #$07
        adc     #$F1
        sbc     ($01),y
        sbc     ($01,x)
        cpx     #$07
        jsr     LE03F
        rti

        jmp     L404C

        .byte   $40,$3F,$40,$9F,$BF,$B1,$B1,$B1
        .byte   $BF,$40,$41,$40,$AE,$00,$22,$22
        .byte   $00,$BF,$BF,$BE,$FE,$00,$8A,$8A
        .byte   $00,$10,$E0,$16,$00,$10,$10,$16
        .byte   $60,$F6,$10,$F0,$F0,$F6,$F0,$F6
        .byte   $E0,$80,$3F,$40,$40,$47,$48
        eor     #$4A
        .byte   $80,$3F,$5F,$60,$67,$6B,$6D,$6E
        .byte   $08,$07,$68,$00,$08,$08,$68,$06
        .byte   $6F,$08,$0F,$0F,$6F,$0F,$6F,$07
        .byte   $01,$FC,$02,$02,$E2,$12,$92,$52
        .byte   $01,$FC,$FA,$06,$E6,$D6,$B6,$76
        .byte   $04,$FC,$07,$02,$62,$62,$02,$02
        .byte   $FC,$02,$F9,$FD,$8D,$8D,$8D,$FD
        .byte   $02,$82,$02,$75,$00,$44,$44,$00
        .byte   $FD,$FD,$7D,$7F,$00,$51,$51,$00
        .byte   $08,$05,$7D,$40,$40,$40,$FF,$FF
        .byte   $F8,$FD,$FD,$C0,$DF,$DF,$FF,$00
        .byte   $00,$FF,$00,$10,$10,$10,$10,$17
        .byte   $FF,$FF,$00,$F4,$F7,$F4,$F7,$F7
        .byte   $08,$F0,$00,$00,$40,$40,$FF,$FF
        .byte   $0F,$FF,$FD,$19,$DF,$DF,$FF,$00
        .byte   $00,$FF,$00,$02,$02,$02,$3E,$E0
        .byte   $FF,$FF,$00,$7E,$7E,$7E,$FE,$E0
        .byte   $52,$50,$52,$52,$52,$02,$77,$E7
        .byte   $76,$70,$76,$76,$76,$06,$77,$88
        .byte   $C8,$77,$00,$56,$02,$52,$52,$52
        .byte   $AF,$77,$00,$76,$06,$76,$76,$76
        .byte   $0B,$EB,$2B,$0B,$EB,$2B,$F3,$FF
        .byte   $0D,$ED,$ED,$0D,$ED,$ED,$FD,$01
        .byte   $03,$F3,$0B,$2B,$0B,$EB,$2B,$0B
        .byte   $FD,$FD,$0D,$ED,$0D,$ED,$ED,$0D
        .byte   $08
        ora     $7D
        rti

        rti

        .byte   $40,$C0,$00,$F8,$FD,$FD,$C0,$DF
        .byte   $DF,$DF,$1F,$1F,$10
        bpl     LA464
        bpl     LA466
        bpl     LA46F
        .byte   $FF,$F0,$F7,$F4,$F7,$F4,$F7,$F7
        .byte   $08,$F0,$00
        brk
LA464:  rti

        rti

LA466:  .byte   $5F,$40,$0F,$FF,$FD,$19,$DF,$DF
        .byte   $DF
LA46F:  cpy     #$C2
        .byte   $02,$02,$02,$02,$02,$3E,$E0,$DE
        .byte   $1E,$7E,$7E,$7E,$7E,$FE,$E0,$D0
        .byte   $D7,$D4,$D0,$D7,$D4,$EF,$FF,$B0
        .byte   $B7,$B7,$B0,$B7,$B7,$9F,$80,$C0
        .byte   $CF,$D0,$D4,$D0,$D7,$D4,$D0,$BF
        .byte   $BF,$B0,$B7,$B0,$B7,$B7,$B0,$4A
        .byte   $0A
        lsr     a
        lsr     a
        lsr     a
        rti

        .byte   $EE,$E7,$6E,$0E,$6E,$6E,$6E,$60
        .byte   $EE,$11,$13
        inc     $6A00
        rti

        .byte   $4A,$4A,$4A,$F5,$EE,$00,$6E,$60
        .byte   $6E,$6E,$6E,$65,$00,$85,$80,$85
        .byte   $80,$9F,$AE,$67,$00,$B7,$B0,$B7
        .byte   $B0,$BF,$AF,$86,$83,$91,$80,$9C
        .byte   $80,$9F,$80,$86,$83,$91,$80,$9C
        .byte   $80,$9F,$80,$46,$60,$60,$30,$3C
        .byte   $1F,$C7,$30,$79,$7F,$7F,$3F,$3F
        .byte   $1F,$C7,$B0,$39,$19,$19,$F9,$01
        .byte   $01,$FD,$01,$39,$D9,$19,$F9,$01
        .byte   $01,$FD,$01,$06,$0E,$0E,$1C,$7C
        .byte   $F8,$E3,$0F,$FE,$FE,$FE,$FC,$FC
        .byte   $F8,$E3,$0F,$98,$98,$9F,$9F,$80
        .byte   $80,$9F,$80,$9E,$98,$9F,$9F,$80
        .byte   $80,$9F,$80,$A7,$00,$A1,$01,$A1
        .byte   $01,$F1,$F1,$E7,$00
        sbc     ($01,x)
        sbc     ($01,x)
        sbc     ($F1),y
        sbc     ($C1,x)
        sta     $3D01
        ora     ($FD,x)
        ora     ($E1,x)
        cmp     ($8D,x)
        ora     ($3D,x)
        ora     ($FD,x)
        ora     (L0000,x)
        .byte   $22,$22,$00,$AE,$40,$41,$40,$00
        .byte   $8A,$8A,$00,$FE,$BE,$BF,$BF,$40
        .byte   $4C,$4C,$40,$00,$80,$7F,$3F,$BF
        .byte   $B1,$B1,$B1,$FF,$FF,$7F,$3F,$4A
        .byte   $49,$48,$47,$40,$40,$3F,$80,$6E
        .byte   $6D,$6B,$67,$60,$5F,$3F,$80,$60
        .byte   $10,$10,$16,$00,$10,$F0,$F6,$E0
        .byte   $F6,$F0,$F0,$F0,$F6,$F0,$F6,$52
        .byte   $92,$12,$E2,$02,$02,$FC,$01,$76
        .byte   $B6,$D6,$E6,$06,$FA,$FC,$01,$06
        .byte   $08,$08,$68,$00,$08,$0F,$6F,$07
        .byte   $6F,$0F,$0F,$0F,$6F,$0F,$6F,$00
        .byte   $44,$44,$00
        adc     $02,x
        .byte   $82,$02,$00,$51,$51,$00,$7F,$7D
        .byte   $FD,$FD,$02,$62,$62,$02,$00,$01
        .byte   $FE,$FC,$FD,$8D,$8D,$8D,$FF
LA5BD:  .byte   $FF,$FE,$FC,$0B,$07,$7F,$43,$43
        .byte   $43,$FF,$FF,$FA,$FE,$FE,$C2,$DE
        .byte   $DE,$FE,$00,$01,$FD,$03,$13,$13
        .byte   $13,$13,$17,$FE,$FE,$02,$F6,$F6
        .byte   $F6,$F6,$F6,$48,$50,$40,$40,$40
        .byte   $40,$7F,$FF,$CF,$DF,$DD,$D9,$DF
        .byte   $DF,$FF,$00,$00,$3F,$40,$42,$42
        .byte   $42,$5E,$40,$FF,$FF,$C0,$DE,$DE
        .byte   $DE,$DE,$C0,$52,$52,$52,$52,$52
        .byte   $52,$52,$53,$76,$76,$76,$76,$76
        .byte   $76,$76,$77,$51,$48,$44,$52,$41
        .byte   $20,$9F,$00,$73,$79,$7C,$66,$67
        .byte   $3F,$9F,$C0,$2B,$E9,$04,$03,$20
        .byte   $D3,$21,$21,$ED,$EE,$07,$E3,$E0
        .byte   $DB,$3B,$3B,$80,$FF,$00,$00,$FF
        .byte   $00,$FF,$00,$80,$FF,$FF,$00,$FF
        .byte   $FF,$FF,$00,$FF,$FF,$01,$FD,$03
        .byte   $6F,$4B,$4B,$FF,$00,$FE,$FE,$02
        .byte   $6E,$6E,$6E,$03,$BF,$03,$00,$FA
        .byte   $03,$FB,$01,$02,$BE,$BE,$01,$FA
        .byte   $FA,$FA,$01,$FF,$FF,$00,$3F,$40
        .byte   $56,$44,$44,$FF,$00,$FF,$FF,$C0
        .byte   $D6,$D6,$D6,$40,$5F,$50,$80,$57
        .byte   $C0,$57,$80,$C0,$DF,$DF,$80,$57
        .byte   $57,$D7,$80,$D4,$97,$20,$C4,$04
        .byte   $DB,$44,$44,$B7,$77,$E0,$C7,$07
        .byte   $DB,$DC,$DC,$01,$FF,$00,$00,$FF
        .byte   $00,$FF,$00,$01,$FF,$FF,$00,$FF
        .byte   $FF,$FF,$00,$4A,$4A,$4A,$4A,$4A
        .byte   $4A,$4A,$CA,$6E,$6E,$6E,$6E,$6E
        .byte   $6E,$6E,$EE,$8A,$12,$22,$52,$82
        .byte   $04,$F9,$00,$CE,$9E,$3E,$66,$E6
        .byte   $FC,$F9,$03,$9F,$80,$9F,$80,$9F
        .byte   $80,$9F,$80,$9F,$80,$9F,$80,$9F
        .byte   $80,$9F,$80,$9F,$80,$9F,$80,$9F
        .byte   $80,$9F,$80,$9F,$80,$9F,$80,$9F
        .byte   $80,$9F,$80,$FD,$41,$FD,$41,$FD
        .byte   $41,$FD,$41,$FD,$41,$FD,$41,$FD
        .byte   $41,$FD,$41,$FD,$01,$FD,$01,$FD
        .byte   $01,$FD,$01,$FD,$01,$FD,$01,$FD
        .byte   $01,$FD,$01,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$9F,$80,$9F,$80,$9F
        .byte   $80,$9F,$80,$9F,$80,$9F,$80,$9F
        .byte   $80,$9F,$80,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$FD,$01,$FD,$01,$FD
        .byte   $01,$FD,$01,$FD,$01,$FD,$01,$FD
        .byte   $01,$FD,$01,$FF,$FF,$E3,$E3,$E3
        .byte   $E3,$FF,$FF,$FF,$FF,$FB,$E3,$FB
        .byte   $E3,$FF,$FF,$00,$F7,$30,$B7,$B7
        .byte   $B7,$B7,$80,$00,$F7,$30,$B7,$B7
        .byte   $B7,$B7,$80,$DD,$C1,$DD,$DD,$DD
        .byte   $DD,$DD,$DD,$DD,$C1,$DD,$DD,$DD
        .byte   $DD,$DD,$DD,$1C,$FD,$00,$FF,$FF
        .byte   $F3,$F3,$1F,$1C,$FD,$00,$FF,$FF
        .byte   $FB,$F3,$1F,$00,$00,$00,$00,$00
        .byte   $00,$00,$FF,$00,$00,$00,$00,$00
        .byte   $00,$00,$FF,$00,$F7,$30,$B7,$B7
        .byte   $B7,$B7,$80,$00,$F7,$30,$B7,$B7
        .byte   $B7,$B7,$80,$00,$00,$00,$00,$00
        .byte   $00,$00,$DD,$00,$00,$00,$00,$00
        .byte   $00,$00,$DD,$1C,$FD,$00,$FF,$FF
        .byte   $F3,$F3,$1F,$1C,$FD,$00,$FF,$FF
        .byte   $FB,$F3,$1F,$0B,$07,$7F,$43,$43
        .byte   $43,$C3,$03,$FA,$FE,$FE,$C2,$DE
        .byte   $DE,$DE,$1E,$1F,$13,$13,$13,$13
        .byte   $13,$13,$17,$FE,$F2,$F6,$F6,$F6
        .byte   $F6,$F6,$F6,$48,$50,$40,$40,$40
        .byte   $40,$5F,$40,$CF,$DF,$DD,$D9,$DF
        .byte   $DF,$DF,$C0,$42,$42,$42,$42,$42
        .byte   $42,$5E,$40,$DE,$DE,$DE,$DE,$DE
        .byte   $DE,$DE,$C0,$00,$00,$00,$00,$00
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
        .byte   $00,$00,$00,$00,$FF,$FF,$00,$00
        .byte   $FF,$FF,$00,$FF,$00,$00,$FF,$FF
        .byte   $FF,$FF,$00,$00,$FF,$FF,$00,$00
        .byte   $FF,$FF,$00,$FF,$00,$00,$FF,$FF
        .byte   $FF,$FF,$00,$00,$FF,$FF,$00,$00
        .byte   $FF,$FF,$00,$FF,$00,$00,$FF,$FF
        .byte   $FF,$FF,$00,$00,$FF,$FF,$00,$00
        .byte   $FF,$FF,$00,$FF,$00,$00,$FF,$FF
        .byte   $FF,$FF,$00,$FF,$FF,$FF,$FF,$80
        .byte   $B1,$A2,$A2,$00,$00,$FF,$00,$7F
        .byte   $46,$55,$55,$A0,$A0,$A0,$A0,$A0
        .byte   $80,$83,$FC,$56,$57,$57,$57,$57
        .byte   $47,$7F,$FC,$FF,$FF,$FF,$FF,$01
        .byte   $F9,$01,$01,$01,$01,$FF,$01,$FF
        .byte   $07,$FB,$FB,$01,$01,$01,$01,$01
        .byte   $01,$C1,$3F,$07,$FF,$FF,$E3,$FF
        .byte   $E3,$FF,$3F,$00,$07,$08,$4B,$4B
        .byte   $4A,$4B,$0A,$FF,$F8,$F0,$93,$93
        .byte   $92,$93,$92,$0B,$0B,$0B,$0B,$0B
        .byte   $4B,$4B,$4A,$F3,$F3,$F3,$F3,$F3
        .byte   $93,$93,$92,$00,$FF,$00,$FF,$7F
        .byte   $3C,$7B,$37,$FF,$00,$00,$FF,$7F
        .byte   $3C,$7B,$37,$77,$77,$77,$76,$79
        .byte   $64,$1F,$00,$77,$77,$77,$76,$79
        .byte   $64,$1F,$00,$00,$FF,$00,$FF,$FE
        .byte   $3F,$DF,$EF,$FF,$00,$00,$FF,$FE
        .byte   $3F,$DF,$EF,$E9,$E7,$8F,$6F,$DF
        .byte   $3F,$F6,$00,$E9,$E7,$8F,$6F,$DF
        .byte   $3F,$F6,$00,$00,$F0,$08,$E8,$28
        .byte   $A8,$A8,$E8,$FF,$07,$03,$E3,$23
        .byte   $A1,$A1,$E1,$E8,$E8,$E8,$E8,$E8
        .byte   $E8,$E8,$28,$E1,$E3,$E3,$E3,$E3
        .byte   $E1,$E1,$21,$4B,$0B,$08,$07,$00
        .byte   $00,$02,$44,$93,$93,$F0,$F0,$F8
        .byte   $FF,$FC,$99,$48,$48,$48,$08,$08
        .byte   $04,$02,$00,$93,$93,$93,$93,$F3
        .byte   $F9,$FC,$FF,$7F,$FF,$00,$FF,$00
        .byte   $00,$00,$28,$7F,$FF,$00,$00,$00
        .byte   $FF,$FF,$A8,$28,$00,$00,$2A,$2A
        .byte   $00,$00,$00,$A8,$FF,$FF,$AA,$AA
        .byte   $FF,$FF,$FF,$F6,$FF,$00,$FF,$00
        .byte   $00,$20,$00,$F6,$FF,$00,$00,$00
        .byte   $FF,$CF,$78,$07,$0F,$0C,$0F,$07
        .byte   $00
        jsr     L7000
        cpx     #$E0
        rts

        .byte   $70,$F8,$CF,$FF,$E8,$E8,$08,$F0
        .byte   $00,$00,$20,$10
        sbc     ($E3,x)
        .byte   $03,$03,$07,$FF,$CF,$E7,$08,$88
        .byte   $08,$88,$08,$10,$20,$00,$73,$33
        .byte   $33,$33,$73,$E7,$CF,$FF,$D7,$F4
        .byte   $D4,$D4,$D4,$F4,$D7,$D0,$30,$F3
        .byte   $33,$33,$33,$F3,$37,$30,$D7,$F4
        .byte   $D4,$D4,$D4,$F4,$D7
        bne     LABC9
        .byte   $F3,$33,$33,$33,$F3,$37,$30,$ED
        .byte   $0F,$0D,$0D,$0D,$0F,$ED,$0D,$03
        .byte   $EF,$E3,$E3,$E3,$EF,$E3,$03,$ED
        .byte   $0F,$0D,$0D,$0D,$0F,$ED,$0D,$03
        .byte   $EF,$E3,$E3,$E3,$EF,$E3,$03,$0C
        .byte   $00,$3F,$39,$3A,$B7,$B7,$2F,$E1
LABC9:  .byte   $80,$BF,$B9,$3A,$37,$37,$2F,$3F
        .byte   $00,$0C,$00,$00,$57,$00,$00,$BF
        .byte   $80,$E1,$FF,$00,$00,$57,$00,$30
        .byte   $00,$FC,$F4,$EC,$6D,$5D,$9C,$87
        .byte   $01,$FD,$F5,$EC,$6C,$5C,$9C,$FC
        .byte   $00,$30,$00,$00,$EA,$00,$00,$FD
        .byte   $01,$87,$FF,$00,$00,$EA,$00,$00
        .byte   $33,$00,$33,$00,$33,$00,$33,$00
        .byte   $55,$00,$55,$00,$55,$00,$55,$00
        .byte   $DD,$DD,$D9,$D1,$DD,$DD,$DD,$00
        .byte   $E2,$E2,$E2,$E2,$E2,$E2,$E2,$03
        .byte   $00,$03,$00,$5D,$5D,$5D,$5D,$04
        .byte   $00,$04,$00,$62,$62,$62,$62,$00
        .byte   $91,$90,$90,$91,$80,$87,$00,$00
        .byte   $6E,$60,$60,$6E,$60,$04,$00,$20
        .byte   $00,$20,$00,$56,$56
        lsr     $56,x
        cpx     #$00
        cpx     #$00
        inc     $FEFE,x
        inc     $1100,x
        ora     ($01,x)
        ora     ($01),y
        and     (L0000,x)
        brk
        .byte   $FF,$0F,$0F,$FF,$07,$E1,$00,$00
        .byte   $66,$00,$66,$00,$66,$00,$66,$00
        .byte   $AA,$00,$AA,$00,$AA,$00,$AA,$00
        .byte   $2E,$2E,$2E,$0E,$2E,$2E,$2E,$00
        .byte   $FE,$FE,$CE,$CE,$FE,$FE,$FE,$00
        .byte   $C1,$DD,$DD,$DD,$DC,$00,$0A,$00
        .byte   $E0,$E2,$E2,$E2,$E2,$00,$16,$00
        .byte   $DD,$DD,$D9,$D1,$DD,$DD,$DD,$00
        .byte   $E2,$E2,$E2,$E2,$E2,$E2,$E2,$00
        .byte   $91,$91,$91,$80,$34
        ldy     $B4,x
        brk
        .byte   $6E,$6E
        ror     $0B00
        .byte   $CB,$CB,$00,$91,$90,$90,$91,$80
        .byte   $87,$00,$00,$6E,$60,$60,$6E,$60
        .byte   $04,$00,$00,$11,$11,$11,$01,$A8
        .byte   $AE,$AE,$00,$FF,$FF,$FF,$03,$F8
        .byte   $FE,$FE,$00,$11,$01,$01,$11,$01
        .byte   $41,$00,$00,$FF,$0F,$0F,$FF,$07
        .byte   $C1,$00,$00,$06,$2E,$2E,$2E,$2E
        .byte   $00,$28,$00,$86,$FE,$FE,$FE,$FE
        .byte   $00,$58,$00,$2E,$2E,$2E,$0E,$2E
        .byte   $2E,$2E,$00,$FE,$FE,$CE,$CE,$FE
        .byte   $FE,$FE,$FF,$FF,$FF,$FF,$00,$3C
        .byte   $38,$20,$00,$00,$FF,$00,$FF,$C3
        .byte   $C3,$DB,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$DB,$DB,$DB,$DB,$DB,$DB
        .byte   $DB,$DB,$FF,$FF,$FF,$FF,$00,$3C
        sec
        jsr     L0000
        .byte   $FF,$00,$FF,$C3,$C3,$DB,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$DB,$DB
        .byte   $DB,$DB,$DB,$DB,$DB,$DB,$00,$61
        .byte   $31,$19,$09,$01,$FE,$03,$00,$63
        .byte   $33,$1B,$0B,$03,$FD,$FC,$02,$FE
        .byte   $02,$1E,$0A,$12,$22,$42,$FC,$FD
        .byte   $01,$1D,$39,$71,$E1,$C1,$00,$C6
        .byte   $CC,$D8,$D0,$C0,$5F,$40,$00,$C6
        .byte   $CC,$D8,$D0,$C0,$DF,$5F,$40,$5F
        .byte   $40,$58,$50,$48,$45,$42,$5F,$DF
        .byte   $C0,$D8,$DC,$CE,$C7,$C3,$FF,$FF
        .byte   $C0,$C7,$C8,$D7,$D7,$D7,$00,$00
        .byte   $3F,$38,$30,$27,$27,$27,$C8,$C7
        .byte   $C0,$C0,$80,$B0,$B0,$A1,$30,$38
LAD9A:  .byte   $3F,$3F,$07,$06,$06,$0C,$FF,$FF
        .byte   $00,$18,$80,$58,$40,$40,$00,$00
        .byte   $FF,$E3,$63,$23,$23,$3C,$83,$0C
        .byte   $13,$2F,$5B
        lda     $79BA,y
        bvs     LAD9A
        .byte   $C3,$8F,$1B,$39,$3A,$79,$FF,$FF
        .byte   $00,$C0,$00,$00,$00,$00,$00,$00
        .byte   $FF,$18,$1F,$F8,$FF,$0E,$F0,$0C
        .byte   $F2,$FD,$DE,$DB,$BB,$B7,$03,$01
        .byte   $F0,$FC,$DE,$DB,$BB,$B7,$FE,$FC
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FC,$0C,$FC,$0C,$FC,$0C,$00,$00
        .byte   $00,$00,$80,$40,$40,$A0,$FC,$8C
        .byte   $FC,$7C,$30,$16,$16,$8A,$DD,$DD
        .byte   $DD,$D9,$D1,$DD,$DD,$DD,$E2,$E2
        .byte   $E2,$E2,$E2,$E2,$E2,$E2,$00,$33
        .byte   $00,$33,$00,$33,$00,$33,$00,$55
        .byte   $00,$55,$00,$55,$00,$55,$00,$87
        .byte   $80,$91,$91,$91,$91,$91,$00,$04
        .byte   $60,$6E,$6E,$6E,$6E,$6E,$00,$5D
        .byte   $5D,$5D,$5D,$00,$03,$00,$00,$62
        .byte   $62,$62,$62,$00,$04,$00,$00,$21
        .byte   $01,$11,$11,$11,$11,$11,$00,$E1
        .byte   $07,$FF,$FF,$FF,$FF,$FF,$00,$56
        .byte   $56,$56,$56,$00,$20,$00,$00,$FE
        .byte   $FE,$FE,$FE,$00,$E0,$00,$2E,$2E
        .byte   $2E,$2E,$0E,$2E,$2E,$2E,$FE,$FE
        .byte   $FE,$CE,$CE,$FE,$FE,$FE,$00,$66
        .byte   $00,$66,$00,$66,$00,$66,$00,$AA
        .byte   $00,$AA,$00,$AA,$00,$AA,$00,$33
        .byte   $00,$33,$00,$33,$00,$33,$00,$55
        .byte   $00,$55,$00,$55,$00,$55,$00,$33
        .byte   $00,$33,$00,$33,$00,$33,$00,$55
        .byte   $00,$55,$00,$55,$00
        eor     $03,x
        brk
        .byte   $03,$00,$03,$00,$03,$00,$04,$00
        .byte   $04,$00,$04,$00,$04,$00,$03,$00
        .byte   $03,$00,$03,$00,$03,$00,$04,$00
        .byte   $04,$00,$04,$00,$04,$00,$20,$00
        .byte   $20,$00,$20,$00,$20,$00,$E0,$00
        .byte   $E0,$00,$E0,$00,$E0,$00,$20,$00
        .byte   $20,$00,$20,$00,$20,$00,$E0,$00
        .byte   $E0,$00,$E0,$00,$E0,$00,$00,$66
        .byte   $00,$66,$00,$66,$00,$66,$00,$AA
        .byte   $00,$AA,$00,$AA,$00,$AA,$00,$66
        .byte   $00,$66,$00,$66,$00,$66,$00,$AA
        .byte   $00,$AA,$00,$AA,$00,$AA,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$DB,$DB
        .byte   $DB,$DB,$DB,$DB,$DB,$DB,$20,$20
        .byte   $00,$00,$00,$00,$FF,$FF,$DB,$C3
        .byte   $C3,$FF,$FF,$00,$FF,$FF,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$DB,$DB
        .byte   $DB,$DB,$DB,$DB,$DB,$DB,$20,$20
        .byte   $00,$00,$00,$00,$FF,$FF,$DB,$C3
        .byte   $C3,$FF,$FF,$00,$FF,$FF,$82,$02
        .byte   $42,$22,$12,$0A,$FE,$03,$81,$61
        .byte   $71,$39,$1D,$0D,$01,$FC,$02,$FE
        .byte   $02,$1E,$0A,$12,$22,$42,$FC,$FD
        .byte   $01,$1D,$39,$71,$E1,$C1,$40,$41
        .byte   $42,$44,$48,$40,$5F,$40,$C3,$C7
        .byte   $CE,$DC,$D8,$C0,$C0,$5F,$40,$5F
        .byte   $40,$58,$50,$48,$45,$42,$5F,$DF
        .byte   $C0,$D8,$DC,$CE,$C7,$C3,$A1,$A1
        .byte   $A1,$A1,$A1,$B0,$B0,$80,$0C,$0C
        .byte   $0C,$0C,$0C,$06,$06,$07,$C0,$C0
        .byte   $D8,$C0,$C3,$C0,$C0,$80,$3F,$24
        .byte   $24,$24,$24,$24,$3F,$00,$7B,$7F
        .byte   $40,$72,$7C,$BD,$BB,$5B,$7B,$7F
        .byte   $40,$72,$7C,$3D,$3B,$1B,$2F,$13
        .byte   $0C,$03,$00,$00,$00,$00,$8F,$C3
        .byte   $E0,$F0,$FC,$FF,$FF,$00,$77,$6F
        .byte   $00,$DF,$DF,$3F,$8F,$72,$77,$6F
        .byte   $00,$DF,$DF,$3F,$8F,$72,$7D,$F2
        .byte   $0C,$F0,$01,$00,$00,$00,$7C,$F0
        .byte   $01,$03
        asl     $FFFE
        brk
        .byte   $A0,$A0,$A0,$A0,$A0,$40,$40,$80
        .byte   $8A,$8A,$8A,$8A,$8A,$16,$16,$30
        .byte   $00
        jsr     L0000
        jsr     L0000
        brk
        .byte   $7C,$CC,$CC,$FC,$4C,$4C,$FC,$00
        .byte   $00,$3F,$7F,$60,$6F,$6F,$6F,$6F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F
        .byte   $00,$00,$00,$00,$40,$40,$40,$40
        .byte   $40,$7F,$7F,$7F,$7F,$7F,$7F,$40
        .byte   $40,$40,$40,$40,$40,$40,$40,$7F
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $00,$00,$00,$01,$02,$04,$08,$08
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$FF,$7F,$7F,$7F,$7F,$7F
        .byte   $00,$3F,$C0,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$00,$FF,$FF,$7F,$7F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7D,$FB,$77,$7F,$5F,$3F,$7F
        .byte   $01,$02,$C4,$28,$00,$28,$44,$84
        .byte   $00,$FC,$FE,$06,$F6,$F6,$76,$76
        .byte   $00,$00,$00,$00,$00,$00,$00,$80
        .byte   $16,$76,$76,$76,$76,$76,$76,$76
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F
        .byte   $00,$00,$00,$07,$00,$00,$00,$00
        .byte   $00,$5F,$5F,$3F,$3F,$3F,$3F,$3F
        .byte   $20,$20,$20,$40,$40,$40,$40,$40
        .byte   $00,$3F,$3F,$DF,$7F,$5F,$6F,$6F
        .byte   $40,$40,$40,$A0,$58,$27
        bpl     LB150
        rti

        .byte   $7F,$7F,$7F,$7F,$7F,$7F,$7F,$40
        .byte   $40,$40,$40,$40,$40,$40,$40
LB150:  .byte   $40,$7D,$7B,$77,$6F,$DF,$7F,$7F
        .byte   $41,$42,$44,$48,$50,$E0,$38,$C7
        .byte   $0A,$7F,$7F,$77,$6F,$5F,$3F,$7F
        .byte   $0B,$0A,$0C,$08,$1E,$24,$44,$84
        .byte   $00,$7F,$7F,$7F,$7F,$7F,$7F,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$80
        .byte   $CA,$FE,$FF,$7F,$FF,$FF,$FF,$FF
        .byte   $CB,$8B,$A5,$00,$D3,$D3,$92,$DB
        .byte   $00,$FF,$FF,$7E,$FE,$7E,$7D,$7D
        .byte   $00,$EA,$CA,$25,$E5,$01,$03,$03
        .byte   $A9,$FF,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $A9,$A8,$2C,$80,$F7,$D5,$F5,$C7
        .byte   $00,$FF,$FF,$7F,$FF,$7F,$FF,$FF
        .byte   $80,$EE,$C4,$24,$E4,$00,$C1,$9A
        .byte   $40,$FF,$FF,$7F,$7F,$7F,$7F,$7F
        .byte   $40,$80,$80,$00,$77,$52,$62,$52
        .byte   $00,$FF,$FF,$FF,$FF,$7F,$FF,$7F
        .byte   $00,$D1,$DB,$95,$D1,$00,$CE,$31
        .byte   $16,$76,$76,$76,$76,$76,$76,$76
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $16,$76,$76,$76,$76,$76,$76,$76
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $6C,$6F,$6F,$6F,$6F,$6F,$6F,$6F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7E,$7D,$7D,$7B,$7B,$7B,$7B
        .byte   $00,$01,$02,$02,$04,$04,$04,$04
        .byte   $00,$7B,$7C,$7D,$7A,$77,$6F,$6F
        .byte   $04,$04,$03,$02,$05,$08,$10,$10
        .byte   $40,$7F,$7F,$7F,$7F,$7F,$7F,$78
        .byte   $80,$40,$40,$40,$40,$40,$40,$47
        .byte   $40,$7F,$7F,$7F,$7F,$7F,$40,$7F
        .byte   $78,$80,$40,$40,$40,$80,$7F,$40
        .byte   $00,$5F,$6F,$6F,$77,$77,$77,$07
        .byte   $C0,$20,$10,$10,$08,$08,$08,$F8
        .byte   $00,$77,$6F,$6F,$5F,$3F,$7F,$7F
        .byte   $0F,$08,$10,$10
        jsr     L00C0
        .byte   $0C,$10,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $7F,$10,$10,$10,$10
        bpl     LB29E
        php
        php
        .byte   $04,$3D,$5B,$67,$67,$5B,$3D,$7D
        .byte   $05,$C2
        and     $18
        clc
        .byte   $24
LB29E:  .byte   $42
        txa
        brk
        .byte   $7D,$7B,$77,$6F,$5F,$3F,$7F,$01
        .byte   $02,$04,$08,$10,$20,$40,$80,$00
        .byte   $7F,$7F,$FF,$7F,$7F,$7F,$FF,$00
        .byte   $00,$00,$C0,$3F,$00,$00,$A9,$02
        .byte   $7F,$7F,$7F,$7F,$7F,$7F,$7F,$02
        .byte   $02,$02,$02,$02,$02,$04,$04,$08
        .byte   $7F,$7F,$FF,$7F,$7F,$7F,$7F,$08
        .byte   $10,$20,$C0,$00,$00,$00,$40,$16
        .byte   $76,$76,$76,$76,$76,$76,$76,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$16
        .byte   $76,$76,$76,$76,$76,$76,$76,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$6C
        .byte   $6F,$6F,$6F,$6F,$6F,$6F,$6F,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$6C
        .byte   $6F,$6F,$6F,$60,$7F,$3F,$00,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $79,$79,$76,$6F,$5F,$3F,$7F,$09
        .byte   $06,$06,$09,$10,$20,$40,$80,$00
        .byte   $7F,$7F,$FF,$00,$FF,$FF,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$40
        .byte   $7F,$7F,$7F,$7F,$47,$78,$7F,$40
        .byte   $40,$40,$40,$80,$78,$47,$40,$40
        .byte   $7F,$7F,$FF,$00,$FF,$FF,$00,$40
        .byte   $40,$00,$00,$00,$00,$00,$00,$78
        .byte   $7F,$7F,$7F,$7F,$78,$07,$7F,$78
        .byte   $07,$00,$00,$00,$07,$F8,$00,$00
        .byte   $7F,$7F,$FF,$00,$FF,$FF,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$01
        .byte   $F7,$6F,$5F,$3F,$7F,$7F,$7F,$05
        .byte   $89,$78,$27,$C0,$00,$00,$00,$00
        .byte   $7F,$7F,$FF,$00,$FF,$FF,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$02
        .byte   $FF,$7F,$FF,$7F,$7F,$7F,$7F,$02
        .byte   $D9,$00,$80,$78,$07,$00,$00,$00
        .byte   $7F,$7F,$FF,$00,$FF,$FF,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$31
        .byte   $FF,$7F,$7F,$7F,$FF,$7F,$7F,$31
        .byte   $CE,$00,$00,$00,$80,$78,$00,$00
        .byte   $7F,$7F,$FF,$00,$FF,$FF,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$16
        .byte   $76,$76,$76,$76,$76,$76,$76,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$16
        .byte   $76,$76,$F6,$06,$FE,$FC,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$40
        .byte   $40,$40,$40,$40,$40,$40,$44,$40
        .byte   $40,$40,$40,$40,$40,$40,$22,$20
        .byte   $00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$5A,$5A,$36,$36
        .byte   $36,$00,$12,$36,$36,$36,$36,$36
        .byte   $36,$36,$24,$12,$48,$00,$12,$6C
        .byte   $7E,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$90
        .byte   $02,$90,$02
        bcc     LB468
        sty     $02,x
LB468:  .byte   $93,$02,$9F,$03,$0F,$25,$25,$0F
        .byte   $15,$28,$90,$04,$91,$04,$92,$04
        .byte   $9E,$04,$93,$04,$9F,$03,$0F,$11
        .byte   $3C,$0F,$15,$27,$91,$03,$92,$03
        .byte   $93,$03,$94,$03,$95,$03,$9F,$03
        .byte   $0F,$26,$30,$0F,$14,$34,$94,$02
        .byte   $94,$02,$94,$02,$94,$02,$94,$02
        .byte   $9F,$03,$0F,$11,$30,$37,$27,$07
        .byte   $90,$07,$91,$07,$92,$07,$93,$07
        .byte   $94,$07,$95,$07,$0F,$30,$28,$0F
        .byte   $28,$15,$90,$02,$91,$02,$92,$02
        .byte   $9E,$04,$9C,$01,$96,$03,$0F,$15
        .byte   $27,$0F,$11,$3C,$AA,$04,$AB,$04
        .byte   $AC,$04,$AD,$04,$AE,$04,$AF,$04
        .byte   $30,$32,$22,$19,$09,$21,$94
        ora     $95
        ora     $96
        ora     $94
        asl     $95
        asl     $95
        .byte   $04,$0F,$0F,$0F,$0F,$0F,$0F,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$01
        .byte   $01,$03,$03,$04,$05,$05,$08,$08
        .byte   $09,$0A,$0A,$0B,$0C,$0D,$0E,$0F
        .byte   $10,$11,$12,$13,$14,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$50
        .byte   $90,$68,$80,$80,$80,$98,$00,$60
        .byte   $10,$10,$60,$80,$80,$80,$80,$80
        .byte   $80,$80,$80,$F8,$E8,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$BC
        .byte   $9C,$B8,$80,$80,$80,$A8,$08,$70
        .byte   $90,$90,$08,$08,$80,$80,$80,$80
        .byte   $80,$80,$80
        ldy     $A4
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$50,$50,$46,$14,$14,$14
        .byte   $46,$25,$23,$23,$23,$25,$27,$14
        .byte   $14,$14,$14,$14,$14,$14,$4E,$4E
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$00,$06,$06,$06
        asl     $1010
        .byte   $12,$15,$15,$16,$16,$17,$17,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$30,$70,$90,$C0,$B8,$70,$70
        .byte   $68,$F8,$F8,$F8,$F8,$08,$08,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$58,$98,$58,$9A,$B8,$68,$B8
        .byte   $78,$4F,$6F,$4F,$6F,$4F,$6F,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$7B,$7A,$7B,$78,$78,$76,$7B
        .byte   $78,$2F,$2F,$2F,$2F,$2F,$2F,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$94,$B4,$74,$94,$94,$94,$00
        .byte   $07,$16,$18,$28,$28,$00,$07,$16
        .byte   $16,$16,$16,$00,$04,$0A,$0E,$0E
        .byte   $0E,$84,$86,$8A,$8A,$8E,$8E,$E0
        .byte   $A0,$60,$E0,$E0,$E0,$85,$87,$8A
        .byte   $8B,$8F,$8F,$60,$20,$E0,$60,$60
        .byte   $60,$00,$07,$10,$12,$12,$12,$00
        .byte   $07,$16,$18,$28,$28,$00,$0B,$16
        .byte   $18,$28,$28,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF
LBBB9:  .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$06
        .byte   $90,$09,$00,$84,$01,$09,$98,$05
        .byte   $00,$9F,$01,$03,$80,$06,$09,$A0
        .byte   $0A,$04,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$09
        .byte   $90,$09,$00,$84,$01,$09,$98,$05
        .byte   $00,$9F,$01,$03,$80,$02,$09,$AC
        .byte   $02,$02,$84,$01,$09,$AA,$01,$04
        .byte   $AA,$0A,$04,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$0F,$2C,$10,$1C,$0F,$37,$27
        .byte   $07,$0F,$28,$16,$07,$0F,$28,$0F
        .byte   $2C,$0F,$0F,$2C,$11,$0F,$0F,$20
        .byte   $38,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$2C,$10,$1C,$0F,$27,$27
        .byte   $07,$0F,$28,$16,$07,$0F,$28,$0F
        .byte   $2C,$0F,$2C,$10,$1C,$0F,$37,$27
        .byte   $07,$0F,$28,$16,$07,$0F,$0F,$28
        .byte   $2C,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$04
        .byte   $06,$0F,$30,$32,$22,$0F,$37,$27
        .byte   $17,$0F,$19,$09,$21,$0F,$01,$01
        .byte   $01,$0F,$0F,$2C,$11,$0F,$0F,$20
        .byte   $38,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$30,$32,$22,$0F,$37,$27
        .byte   $17,$0F,$19,$09,$21,$0F,$01,$01
        .byte   $01,$0F,$30,$32,$22,$0F,$37,$27
        .byte   $17,$0F,$19,$09,$21,$0F,$01,$21
        .byte   $01,$0F,$30,$32,$22,$0F,$37,$27
        .byte   $17,$0F,$19,$09,$21,$0F,$01,$01
        .byte   $21,$0F,$30,$32,$22,$0F,$37,$27
        .byte   $17,$0F,$19,$09,$21,$0F,$01,$21
        .byte   $21,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$78
        .byte   $EE,$E1,$BF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$00,$00,$E0,$BF,$E0,$BF
