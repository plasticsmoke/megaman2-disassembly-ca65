.segment "HEADER"

; iNES header for Mega Man 2 (U)
; Mapper 1 (MMC1), 256KB PRG, CHR-RAM
.byte "NES", $1A                        ; Magic number
.byte $10                               ; 16 x 16KB PRG ROM = 256KB
.byte $00                               ; 0 CHR ROM banks (CHR-RAM)
.byte $11                               ; Flags 6: mapper low nibble (1), vertical mirroring
.byte $00                               ; Flags 7: mapper high nibble (0)
.byte $00, $00, $00, $00, $00, $00, $00, $00 ; Padding
