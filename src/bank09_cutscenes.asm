.segment "BANK09"

; =============================================================================
; Bank $09 — Cutscene Code & Shared CHR Data
; No stage data lives here (Wily 3-5 layouts are in banks $02-$04; see
; DATA_REFERENCE §6). Contents:
;   $8000-$85FF  shared CHR (HUD/font/common tiles — every stage CHR list
;                pulls $8000×6 → CHR $1000+ and $8400×1)
;   $8600-$86FF  ENDING cutscene engine (only code in a data bank)
;   $8700-$8FFF  ending scene sprite blocks, walk-scene columns, CREDITS text
;   $9000-$AFFF  CHR for Wily map, title/prologue and ending screens
; Title/prologue also stream column data from here via ppu_column_fill.
; =============================================================================

        .setcpu "6502"

; --- Local equates (bank09 has no .include directives) ---
col_update_addr_hi  = $03B6     ; column update VRAM addr high
col_update_addr_lo  = $03B7     ; column update VRAM addr low
col_update_tiles    = $03B8     ; column update tile data buffer

; =============================================================================
; CHR pattern data $8000-$85FF (shared HUD/font/common tiles)
; Referenced by every stage's CHR upload list ($8000 × 6 pages → CHR $1000+,
; $8400 × 1 page); Wily 6 loads $8000 × 8 (spilling into the code below as
; filler). Password/game-over group also reads pages here.
; =============================================================================
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$7C,$7D,$00,$7D,$00,$00,$00,$00,$01,$02,$7F,$7D,$00,$00
        .byte   $00,$00,$7C,$7D,$00,$7D,$00,$00,$00,$00,$01,$02,$7F,$7D,$00,$00
        .byte   $00,$00,$3E,$BE,$00,$BE,$00,$00,$00,$00,$80,$40,$FE,$BE,$00,$00
        .byte   $00,$00,$3E,$BE,$00,$BE,$00,$00,$00,$00,$80,$40,$FE,$BE,$00,$00
        .byte   $00,$00,$7C,$7D,$00,$00,$00,$00,$03,$00,$7D,$7F,$7F,$7D,$00,$03
        .byte   $00,$00,$7C,$7D,$00,$00,$00,$00,$03,$00,$7D,$7F,$7F,$7D,$00,$03
        .byte   $00,$00,$3E,$BE,$00,$00,$00,$00,$C0,$00,$BE,$FE,$FE,$BE,$00,$C0
        .byte   $00,$00,$3E,$BE,$00,$00,$00,$00,$C0,$00,$BE,$FE,$FE,$BE,$00,$C0
        .byte   $01,$41,$21,$1B,$1F,$0F,$1B,$FF,$01,$41,$21,$1B,$1F,$0D,$1F,$FF
        .byte   $1F,$0F,$1F,$1B,$21,$41,$01,$00,$1F,$0F,$1F,$1B,$21,$41,$01,$00
        .byte   $00,$04,$08,$B0,$F0,$E0,$F0,$FE,$00,$04,$08,$B0,$F0,$E0,$F0,$FE
        .byte   $F0,$E0,$F0,$B0,$08,$04,$00,$00,$F0,$E0,$F0,$B0,$08,$04,$00,$00
        .byte   $FD,$CE,$CE,$87,$E7,$87,$85,$80,$3D,$4E,$4E,$87,$07,$87,$87,$80
        .byte   $87,$87,$85,$84,$E4,$C8,$C8,$F0,$87,$87,$87,$87,$07,$4E,$4E,$3D
        .byte   $57,$00,$F9,$7C,$01,$7D,$7C,$7C,$F0,$03,$FB,$7C,$01,$7D,$7D,$7C
        .byte   $55,$00,$7C,$54,$00,$00,$00,$07,$7D,$01,$7D,$7C,$7D,$03,$F8,$50
        .byte   $F0,$07,$00,$07,$00,$13,$16,$14,$00,$F4,$F0,$F4,$C0,$D0,$C1,$C3
        .byte   $04,$10,$30,$07,$00,$07,$00,$F7,$D3,$D3,$C0,$F4,$F0,$F4,$F0,$F4
        .byte   $3F,$60,$20,$60,$04,$94,$14,$14,$00,$DF,$1F,$DF,$03,$13,$C3,$C3
        .byte   $04,$14,$3C,$60,$20,$60,$20,$7F,$D3,$93,$03,$DF,$1F,$DF,$1F,$FF
        .byte   $F0,$07,$00,$07,$00,$13,$16,$14,$00,$F4,$F0,$F4,$C0,$D0,$C1,$C3
        .byte   $04,$10,$00,$FF,$88,$88,$88,$88,$D3,$D3,$00,$00,$00,$33,$11,$00
        .byte   $3F,$60,$20,$60,$04,$94,$14,$14,$00,$DF,$1F,$DF,$03,$13,$C3,$C3
        .byte   $04,$14,$00,$FF,$88,$88,$88,$88,$D3,$93,$00,$00,$00,$33,$11,$00
        .byte   $00,$FF,$04,$FF,$00,$FF,$04,$FF,$00,$00,$FC,$FF,$00,$00,$FC,$FF
        .byte   $00,$FF,$04,$FF,$00,$FF,$04,$FF,$00,$00,$FC,$FF,$00,$00,$FC,$FF
        .byte   $00,$FE,$02,$FE,$00,$FE,$02,$FE,$00,$02,$7E,$FE,$00,$02,$7E,$FE
        .byte   $00,$FE,$02,$FE,$00,$FE,$02,$FE,$00,$02,$7E,$FE,$00,$02,$7E,$FE
        .byte   $BC,$BC,$A0,$BC,$BC,$BC,$A0,$BC,$C3,$C3,$E1,$C3,$C3,$C3,$E1,$C3
        .byte   $BC,$BC,$A0,$AD,$A0,$AD,$A0,$BC,$C3,$C3,$E0,$F3,$E0,$F3,$E0,$C3
        .byte   $00,$60,$60,$60,$00,$60,$60,$60,$06,$10,$16,$16,$06,$10,$16,$16
        .byte   $00,$60,$60,$E0,$E0,$E0,$60,$60,$06,$10,$16,$16,$16,$16,$16,$16
        .byte   $BC,$BC,$A0,$BC,$BC,$BC,$BC,$BF,$C3,$C3,$E1,$C3,$C3,$C3,$C3,$C0
        .byte   $A3,$99,$99,$81,$80,$80,$C0,$7F,$C0,$C4,$C4,$DC,$E3,$FF,$FF,$7F
        .byte   $00,$60,$60,$60,$60,$60,$00,$00,$06,$10,$16,$16,$16,$17,$00,$FF
        .byte   $F7,$F7,$F7,$F7,$00,$00,$00,$FF,$00,$00,$00,$00,$F7,$FF,$FF,$FF
        .byte   $00,$88,$88,$FF,$00,$00,$00,$00,$00,$88,$88,$FF,$00,$FF,$70,$07
        .byte   $07,$57,$57,$07,$50,$F8,$00,$FF,$50,$00,$00,$50,$57,$07,$FF,$FF
        .byte   $00,$88,$88,$FF,$00,$00,$00,$00,$00,$88,$88,$FF,$00,$FF,$00,$FF
        .byte   $77,$77,$77,$77,$00,$00,$00,$FF,$00,$00,$00,$00,$77,$77,$FF,$FF
        .byte   $00,$FF,$FF,$FF,$FF,$FD,$FD,$FD,$00,$FF,$FF,$83,$82,$80,$80,$80
        .byte   $FD,$FC,$FC,$FC,$FD,$FD,$FF,$FF,$80,$80,$80,$80,$80,$80,$80,$80
        .byte   $00,$FF,$E0,$80,$E0,$BF,$FF,$FF,$00,$FF,$FF,$FF,$1F,$4A,$49,$49
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$19,$FF,$0F,$0F,$07,$06,$02,$00
        .byte   $00,$FF,$07,$03,$07,$FF,$FF,$FF,$00,$FF,$FF,$FC,$F8,$78,$F0,$E0
        .byte   $FF,$FF,$FF,$FE,$FE,$FC,$F8,$F8,$60,$C0,$80,$80,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$FF,$FF,$E1,$E3,$C3,$00,$FF,$FF,$07,$0F,$01,$03,$03
        .byte   $87,$87,$07,$03,$23,$23,$63,$E3,$07,$0F,$0F,$1F,$3F,$3F,$7F,$FF
        .byte   $FF,$FF,$FE,$FE,$FC,$FC,$C1,$C1,$80,$80,$80,$80,$80,$80,$C1,$C1
        .byte   $F0,$F8,$FC,$FE,$FF,$EF,$CF,$FF,$FF,$FF,$FF,$FF,$FF,$CF,$CF,$FF
        .byte   $7F,$7F,$7F,$7F,$FF,$FF,$FF,$FE,$00,$00,$40,$40,$E0,$E0,$F0,$F0
        .byte   $FE,$7C,$1E,$00,$80,$E0,$FF,$FF,$F8,$F8,$FE,$FE,$FF,$FF,$FF,$FF
        .byte   $F0,$E1,$E3,$C3,$87,$8F,$0F,$1F,$00,$01,$03,$03,$07,$0F,$0F,$1F
        .byte   $3F,$3E,$78,$00,$01,$07,$FF,$FF,$3F,$3F,$7F,$FF,$FF,$FF,$FF,$FF
        .byte   $E3,$E3,$E3,$E3,$E3,$C7,$C7,$8F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $0F,$1F,$3F,$7F,$FF,$FD,$F9,$FF,$FF,$FF,$FF,$FF,$FF,$F9,$F9,$FF
        .byte   $00,$7E,$7C,$78,$70,$60,$40,$00,$00,$00,$02,$06,$0E,$1E,$3E,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$FC,$C6,$C6,$C6,$FC,$CC,$C6
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$FE,$C0,$C0,$FC,$C0,$C0,$FE
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$7C,$C6,$C6,$C6,$FE,$C6,$C6
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$FC,$C6,$C6,$C6,$C6,$C6,$FC
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$CC,$CC,$CC,$78,$30,$30,$30
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

; =============================================================================
; Ending Cutscene Entry Vectors ($8600)
; Called via bank0F trampolines while bank0D runs the ending sequence.
; =============================================================================
        jmp     ending_draw_sprites     ; $8600: draw scene sprite block ($01 = index)
        jmp     ending_column_tick      ; $8603: one column tile per 4 frames (walk scene)
        jmp     ending_init_data_ptr    ; $8606: init scene column data pointer ($8C95)
        jmp     ending_scroll_step      ; $8609: smooth vertical pan (final walk)

; =============================================================================
; ending_draw_sprites — copy a pre-built OAM sprite block to $0200 ($860C)
; $01 = block index (0-7) → ending_sprite_block_lo/hi → [count, entries...]
; Each entry is 4 raw OAM bytes (Y, tile, attr, X).
; =============================================================================
ending_draw_sprites:  ldy     $01
        lda     ending_sprite_block_lo,y
        sta     $08
        lda     ending_sprite_block_hi,y
        sta     $09
        ldy     #$00
        lda     ($08),y
        sta     $02
        iny
        ldx     #$00

ending_sprite_copy:  lda     #$04        ; Copy 4-byte OAM entries to $0200
        sta     $01
ending_sprite_copy_loop:  lda     ($08),y
        sta     $0200,x
        iny
        inx
        dec     $01
        bne     ending_sprite_copy_loop
        dec     $02
        bne     ending_sprite_copy
        stx     $00
        rts

; =============================================================================
; Ending Scene Column / Scroll Routines
; =============================================================================
; Drive the ending walk scenes: scene data is divided into sections
; ($06A0 = section index, $0680 = offset within section). Every 4th frame
; one tile is transferred into the PPU column buffer; at a section boundary
; the section index advances.
;
; PPU buffer layout: col_update_addr_hi/lo = PPUADDR, col_update_tiles = data.
; col_update_count ($47) signals NMI to perform the actual VRAM write.
; =============================================================================

; ─── entry $8603: one column tile per 4 frames (ending walk scene loop) ───
ending_column_tick:  lda     $1C         ; frame_counter
        and     #$03
        bne     ending_tick_done      ; only update every 4th frame
        ldx     $06A0                   ; current scroll section index
        lda     $0680                   ; column offset within section
        tay
        cmp     ending_section_len,x ; reached end of this section?
        beq     ending_next_section
        clc
        adc     ending_col_index_base,x ; compute tile index offset
        tax
        lda     ending_col_tiles,x     ; look up tile ID for this column
        sta     col_update_tiles        ; store in PPU buffer
        inc     $47                     ; signal NMI: 1 tile to write
        inc     col_update_addr_lo      ; advance PPU target address
        inc     $0680                   ; advance column offset
        bne     ending_tick_done
ending_next_section:                 ; Move to next scroll section
        lda     $06A0
        and     #$01                    ; only advance on even sections
        bne     ending_tick_done
        inc     $06A0                   ; next section
        lda     #$00
        sta     $0680                   ; reset column offset
        lda     #$25                    ; PPU addr $25CC (nametable 1, row 14)
        sta     col_update_addr_hi
        lda     #$CC
        sta     col_update_addr_lo
ending_tick_done:  rts

; ─── entry $8606: point $DE/$DF at the ending scene column data ($8C95) ───
ending_init_data_ptr:  lda     #$8C
        sta     $DF                     ; metatile data pointer high
        lda     #$95
        sta     $DE                     ; metatile data pointer low ($DE/$DF)
        rts

; ─── entry $8609: smooth vertical pan (ending final walk) ───
; Adds $78 sub-pixels to scroll_y_page ($21) each call, carries into
; scroll_y ($22). Wraps at $F0 (NES visible scanline limit = 240).
; When scroll_y crosses an 8-pixel boundary (AND #$07 = 0), clears the
; incoming tile row (32 blank tiles); otherwise checks section triggers.
ending_scroll_step:  clc
        lda     $21                     ; scroll_y_page (sub-pixel accumulator)
        adc     #$78                    ; add $78 sub-pixels per frame
        sta     $21
        lda     $22                     ; scroll_y (pixel position)
        adc     #$00                    ; carry from sub-pixel addition
        cmp     #$F0                    ; wrap at 240 (NES visible height)
        bcc     ending_store_scroll_y
        lda     #$00
ending_store_scroll_y:  sta     $22
        and     #$07                    ; crossed 8-pixel tile boundary?
        bne     ending_check_triggers   ; no: check section-based triggers instead
        sec                             ; yes: clear an entire row of tiles
        lda     $22
        sta     $01                     ; Y position for address calculation
        jsr     ending_calc_nt_addr     ; compute PPU address for this row
        ldx     #$20
        stx     $47                     ; 32 tiles to write (full row)
        dex
        lda     #$00                    ; fill with blank tile ($00)
ending_clear_row_loop:  sta     col_update_tiles,x ; clear PPU buffer
        dex
        bpl     ending_clear_row_loop
        rts

; --- Section-based scroll trigger check ---
; Each section has a specific scroll_y value that triggers column data
; transfer from ROM (via $DE/$DF pointer) into the PPU buffer.
ending_check_triggers:  ldx     $06A0   ; current section index
        lda     $22                     ; scroll_y
        cmp     ending_scroll_triggers,x ; at trigger position?
        bne     ending_col_done        ; no: skip
        lda     $22
        and     #$F8                    ; align to 8-pixel boundary
        sta     $01
        jsr     ending_calc_nt_addr     ; compute PPU target address
        lda     ending_ppu_addr_lo,x ; per-section PPUADDR low byte
        sta     col_update_addr_lo
        lda     ending_col_count,x  ; tiles to copy this section
        sta     $47                     ; → col_update_count for NMI
        ldy     #$00
        ldx     #$00
ending_copy_col_loop:  lda     ($DE),y      ; read tile from metatile data
        sta     col_update_tiles,x      ; store in PPU buffer
        clc
        lda     $DE                     ; advance source pointer
        adc     #$01
        sta     $DE
        lda     $DF
        adc     #$00
        sta     $DF
        inx
        cpx     $47                     ; copied all tiles?
        bne     ending_copy_col_loop
        inc     $06A0                   ; advance to next section
ending_col_done:  rts

; --- Calculate nametable VRAM address from Y scroll position ---
; Input: $01 = Y position (aligned to 8px). Output: col_update_addr = PPUADDR.
; Formula: addr = $0800 | (Y << 2), where high byte accumulates via ROL.
ending_calc_nt_addr:  lda     #$08      ; base high byte ($08 → $20xx or $28xx)
        sta     $00
        lda     $01                     ; Y position
        asl     a                       ; shift left twice: Y * 4
        rol     $00                     ; carry into high byte
        asl     a
        rol     $00
        sta     col_update_addr_lo      ; PPU address low byte
        lda     $00
        sta     col_update_addr_hi      ; PPU address high byte
        rts

; =============================================================================
; Ending Scene Sprite Blocks ($8700)
; 8 pre-built OAM blocks: ending_sprite_block_lo/hi point to [count,
; then count × 4 raw OAM bytes (Y, tile, attr, X)]. Drawn to $0200 by
; ending_draw_sprites ($01 = block index).
; =============================================================================
ending_sprite_block_lo:
        .byte   $10,$9D,$26,$B3,$3C,$C9,$EE,$7B
ending_sprite_block_hi:
        .byte   $87,$87,$88,$88,$89,$89,$89,$8A
; ─── sprite block 0 ($8710) — 35 OAM entries ───
        .byte   $23,$80,$50,$00,$C0,$80,$51,$00
        .byte   $C8,$80,$52,$00,$D0,$88,$53,$00
        .byte   $B8,$88,$54,$00,$C0,$88,$55,$00
        .byte   $C8,$88,$56,$00,$D0,$90,$57,$00
        .byte   $B8,$90,$58,$00,$C0,$90,$59,$00
        .byte   $C8,$90,$5A,$00,$D0,$98,$5B,$00
        .byte   $B8,$98,$5C,$00,$C0,$98,$5D,$00
        .byte   $C8,$98,$5E,$00,$D0,$A0,$5F,$00
        .byte   $B8,$A0,$60,$00,$C0,$A0,$61,$00
        .byte   $C8,$A0,$62,$00,$D0,$A8,$63,$00
        .byte   $B8,$A8,$64,$00,$C0,$A8,$65,$00
        .byte   $C8,$A8,$66,$00,$D0,$B0,$67,$00
        .byte   $B8,$B0,$68,$00,$C0,$B0,$69,$00
        .byte   $C8,$B0,$6A,$00,$D0,$B8,$6B,$02
        .byte   $B8,$B8,$6C,$02,$C0,$B8,$6D,$02
        .byte   $C8,$B8,$6E,$02,$D0,$89,$A0,$01
        .byte   $C1,$89,$A0,$41,$C9,$91,$A1,$01
        .byte   $C1,$91,$A2,$01,$C9
; ─── sprite block 1 ($879D) — 34 OAM entries ───
        .byte   $22,$80,$77,$00,$C0,$80,$78,$00
        .byte   $C8,$88,$79,$00,$B8,$88,$7A,$00
        .byte   $C0,$88,$7A,$40,$C8,$88,$79,$40
        .byte   $D0,$90,$7B,$00,$B8,$90,$7C,$00
        .byte   $C0,$90,$7C,$40,$C8,$90,$7B,$40
        .byte   $D0,$98,$7D,$00,$B8,$98,$7E,$00
        .byte   $C0,$98,$7F,$00,$C8,$98,$7D,$40
        .byte   $D0,$A0,$83,$00,$B8,$A0,$84,$00
        .byte   $C0,$A0,$85,$00,$C8,$A0,$83,$40
        .byte   $D0,$A8,$86,$00,$B8,$A8,$87,$00
        .byte   $C0,$A8,$88,$00,$C8,$A8,$89,$00
        .byte   $D0,$B0,$8A,$00,$B8,$B0,$8B,$00
        .byte   $C0,$B0,$8C,$00,$C8,$B0,$8D,$00
        .byte   $D0,$B8,$8E,$02,$B8,$B8,$8F,$02
        .byte   $C0,$B8,$9D,$02,$C8,$B8,$9E,$02
        .byte   $D0,$88,$A0,$01,$C0,$88,$A0,$41
        .byte   $C8,$90,$A1,$01,$C0,$90,$A2,$01
        .byte   $C8
; ─── sprite block 2 ($8826) — 35 OAM entries ───
        .byte   $23,$80,$50,$00,$BE,$80,$51,$00
        .byte   $C6,$80,$52,$00,$CE,$88,$53,$00
        .byte   $B6,$88,$54,$00,$BE,$88,$55,$00
        .byte   $C6,$88,$56,$00,$CE,$90,$5A,$40
        .byte   $B8,$90,$59,$40,$C0,$90,$58,$40
        .byte   $C8,$90,$57,$40,$D0,$98,$5E,$40
        .byte   $B8,$98,$5D,$40,$C0,$98,$5C,$40
        .byte   $C8,$98,$5B,$40,$D0,$A0,$62,$40
        .byte   $B8,$A0,$61,$40,$C0,$A0,$60,$40
        .byte   $C8,$A0,$5F,$40,$D0,$A8,$66,$40
        .byte   $B8,$A8,$65,$40,$C0,$A8,$64,$40
        .byte   $C8,$A8,$63,$40,$D0,$B0,$6A,$40
        .byte   $B8,$B0,$69,$40,$C0,$B0,$68,$40
        .byte   $C8,$B0,$67,$40,$D0,$B8,$A3,$02
        .byte   $B8,$B8,$A4,$02,$C0,$B8,$A5,$02
        .byte   $C8,$B8,$A6,$02,$D0,$89,$A0,$01
        .byte   $BF,$89,$A0,$41,$C7,$91,$A1,$01
        .byte   $BF,$91,$A2,$01,$C7
; ─── sprite block 3 ($88B3) — 34 OAM entries ───
        .byte   $22,$80,$77,$00,$C0,$80,$78,$00
        .byte   $C8,$88,$79,$00,$B8,$88,$7A,$00
        .byte   $C0,$88,$7A,$40,$C8,$88,$79,$40
        .byte   $D0,$90,$7B,$00,$B8,$90,$7C,$00
        .byte   $C0,$90,$7C,$40,$C8,$90,$7B,$40
        .byte   $D0,$98,$7D,$00,$B8,$98,$7F,$40
        .byte   $C0,$98,$7E,$40,$C8,$98,$7D,$40
        .byte   $D0,$A0,$83,$00,$B8,$A0,$85,$40
        .byte   $C0,$A0,$84,$40,$C8,$A0,$83,$40
        .byte   $D0,$A8,$89,$40,$B8,$A8,$88,$40
        .byte   $C0,$A8,$87,$40,$C8,$A8,$86,$40
        .byte   $D0,$B0,$8D,$40,$B8,$B0,$8C,$40
        .byte   $C0,$B0,$8B,$40,$C8,$B0,$8A,$40
        .byte   $D0,$B8,$A7,$02,$B8,$B8,$A8,$02
        .byte   $C0,$B8,$A9,$02,$C8,$B8,$AA,$02
        .byte   $D0,$88,$A0,$01,$C0,$88,$A0,$41
        .byte   $C8,$90,$A1,$01,$C0,$90,$A2,$01
        .byte   $C8
; ─── sprite block 4 ($893C) — 35 OAM entries ───
        .byte   $23,$80,$B5,$00,$C0,$80,$B6,$00
        .byte   $C8,$80,$B7,$00,$D0,$88,$B8,$00
        .byte   $B8,$88,$B9,$00,$C0,$88,$BA,$00
        .byte   $C8,$88,$BB,$00,$D0,$90,$BE,$00
        .byte   $B8,$90,$BF,$00,$C0,$90,$BC,$00
        .byte   $C8,$90,$BD,$00,$D0,$98,$CB,$00
        .byte   $B8,$98,$CC,$00,$C0,$98,$CC,$40
        .byte   $C8,$98,$CB,$40,$D0,$A0,$CD,$00
        .byte   $B8,$A0,$CE,$00,$C0,$A0,$CE,$40
        .byte   $C8,$A0,$CD,$40,$D0,$A8,$CF,$00
        .byte   $B8,$A8,$D9,$00,$C0,$A8,$D9,$40
        .byte   $C8,$A8,$CF,$40,$D0,$B0,$DA,$00
        .byte   $B8,$B0,$DB,$00,$C0,$B0,$DB,$40
        .byte   $C8,$B0,$DA,$40,$D0,$B8,$DC,$02
        .byte   $B8,$B8,$DD,$02,$C0,$B8,$DD,$42
        .byte   $C8,$B8,$DC,$42,$D0,$88,$AB,$01
        .byte   $BF,$88,$AC,$01,$C7,$90,$AD,$01
        .byte   $BF,$90,$AE,$01,$C7
; ─── sprite block 5 ($89C9) — 9 OAM entries ───
        .byte   $09,$A8,$DE,$00,$B8,$A8,$DF,$00
        .byte   $C0,$A8,$E0,$00,$C8,$B0,$E1,$00
        .byte   $B8,$B0,$E2,$00,$C0,$B0,$E3,$00
        .byte   $C8,$B8,$E4,$02,$B8,$B8,$E5,$02
        .byte   $C0,$B8,$E6,$02,$C8
; ─── sprite block 6 ($89EE) — 35 OAM entries ───
        .byte   $23,$34,$80,$00,$3F,$34,$81,$00
        .byte   $47,$34,$82,$00,$4F,$3C,$83,$00
        .byte   $37,$3C,$84,$00,$3F,$3C,$85,$00
        .byte   $47,$3C,$86,$00,$4F,$44,$B9,$00
        .byte   $37,$44,$BA,$00,$3F,$44,$89,$00
        .byte   $47,$44,$BB,$00,$4F,$4C,$9B,$00
        .byte   $38,$4C,$BC,$00,$40,$4C,$BC,$40
        .byte   $48,$4C,$9B,$40,$50,$54,$9D,$00
        .byte   $38,$54,$9E,$00,$40,$54,$9E,$40
        .byte   $48,$54,$9D,$40,$50,$5C,$9F,$00
        .byte   $38,$5C,$A9,$00,$40,$5C,$A9,$40
        .byte   $48,$5C,$9F,$40,$50,$64,$AA,$00
        .byte   $38,$64,$AB,$00,$40,$64,$AB,$40
        .byte   $48,$64,$AA,$40,$50,$6C,$AC,$02
        .byte   $38,$6C,$AD,$02,$40,$6C,$AD,$42
        .byte   $48,$6C,$AC,$42,$50,$3D,$BD,$01
        .byte   $40,$3D,$BD,$41,$48,$45,$BE,$01
        .byte   $40,$45,$BF,$01,$48
; ─── sprite block 7 ($8A7B) — 19 OAM entries ───
        .byte   $13,$40,$C0,$03,$3B,$40,$C1,$03
        .byte   $43,$40,$C2,$03,$4B,$48,$C3,$03
        .byte   $38,$48,$C4,$03,$40,$48,$C5,$03
        .byte   $48,$48,$C6,$03,$50,$50,$C7,$03
        .byte   $38,$50,$C8,$03,$40,$50,$C9,$03
        .byte   $48,$50,$CA,$03,$50,$58,$CB,$03
        .byte   $38,$58,$CC,$03,$40,$58,$CD,$03
        .byte   $48,$58,$CE,$03,$50,$41,$CF,$01
        .byte   $48,$49,$D8,$01,$40,$49,$D9,$01
        .byte   $48,$49,$DA,$01,$50

; ─── ending_col_index_base — per-section base index into ending_col_tiles ($8AC8) ───
ending_col_index_base:
        .byte   $00,$10,$1E,$2C,$3A,$4B,$59,$69,$7B,$8B,$98,$A8,$B7,$C6,$D7,$E6
; ─── ending_section_len — per-section length (column count) ($8AD8) ───
ending_section_len:
        .byte   $10,$0E,$0E,$0E,$11,$0E,$10,$12,$10,$0D,$10,$0F,$0F,$11,$0F,$12
; ─── ending_col_tiles — walk-scene column tile IDs (written 1/4 frames) ($8AE8) ───
ending_col_tiles:
        .byte   $0E,$0F,$1C,$30,$30,$39,$20,$20,$0D,$05,$14,$01,$0C,$0D,$01,$0E
        .byte   $0D,$01,$13,$01,$0E,$0F,$12,$09,$20,$13,$01,$14,$0F,$15,$0E,$0F
        .byte   $1C,$30,$31,$30,$20,$20,$01,$09,$12,$0D,$01,$0E,$19,$0F,$15,$0A
        .byte   $09,$20,$0B,$01,$0E,$01,$1A,$01,$17,$01,$0E,$0F,$1C,$30,$31,$31
        .byte   $20,$20,$02,$15,$02,$02,$0C,$05,$0D,$01,$0E,$14,$01,$0B,$01,$13
        .byte   $08,$09,$20,$14,$01,$0E,$01,$0B,$01,$0E,$0F,$1C,$30,$31,$32,$20
        .byte   $20,$11,$15,$09,$03,$0B,$0D,$01,$0E,$08,$09,$12,$0F,$06,$15,$0D
        .byte   $09,$20,$0D,$09,$1A,$0F,$07,$15,$03,$08,$09,$0E,$0F,$1C,$30,$31
        .byte   $33,$20,$20,$03,$12,$01,$13,$08,$0D,$01,$0E,$01,$0B,$09,$12,$01
        .byte   $20,$19,$0F,$13,$08,$09,$04,$01,$0E,$0F,$1C,$30,$31,$34,$20,$20
        .byte   $06,$0C,$01,$13,$08,$0D,$01,$0E,$14,$0F,$0D,$0F,$0F,$20,$19,$01
        .byte   $0D,$01,$07,$15,$03,$08,$09,$0E,$0F,$1C,$30,$31,$35,$20,$20,$08
        .byte   $05,$01,$14,$0D,$01,$0E,$14,$0F,$13,$08,$09,$19,$15,$0B,$09,$20
        .byte   $0B,$01,$14,$01,$0F,$0B,$01,$0E,$0F,$1C,$30,$31,$36,$20,$20,$17
        .byte   $0F,$0F,$04,$0D,$01,$0E,$0D,$01,$13,$01,$0B,$01,$14,$13,$15,$20
        .byte   $09,$03,$08,$09,$0B,$01,$17,$01
; ─── ending_scroll_triggers — per-section scroll_y trigger values ($8BE0) ───
ending_scroll_triggers:
        .byte   $24,$4C,$5C,$6C,$7C,$8C,$9C,$04,$2C,$3C,$4C,$A4,$CC,$34,$5C,$C4
        .byte   $0C,$1C,$2C,$3C,$4C,$5C,$6C,$7C,$8C,$9C,$AC,$BC,$CC,$DC,$EC,$0C
        .byte   $1C,$2C,$3C,$4C,$5C,$6C,$7C,$8C,$9C,$AC,$BC,$CC,$DC,$EC,$0C,$1C
        .byte   $2C,$3C,$4C,$5C,$6C,$7C,$8C,$9C,$AC,$EC,$64,$74,$01
; ─── ending_ppu_addr_lo — per-section PPUADDR low byte ($8C1D) ───
ending_ppu_addr_lo:
        .byte   $87,$2B,$6C,$AC,$EC,$2B,$6E,$08,$AA,$EA,$28,$8B,$2D,$CC,$6E,$08
        .byte   $27,$68,$A9,$E8,$27,$67,$A7,$E7,$2C,$67,$A7,$E7,$2C,$69,$AA,$28
        .byte   $69,$A8,$E9,$2A,$68,$A9,$E7,$29,$69,$AB,$E7,$28,$66,$AA,$27,$67
        .byte   $AA,$E9,$2A,$66,$A6,$E6,$26,$68,$AB,$A5,$8A,$CA
; ─── ending_col_count — per-section tile counts ($8C59) ───
ending_col_count:
        .byte   $12,$09,$08,$07,$08,$0A,$03,$10,$0C,$0C,$10,$0A,$06,$07,$03,$0E
        .byte   $10,$0D,$0F,$0D,$12,$10,$0E,$0F,$0C,$0F,$0E,$0F,$09,$0D,$0C,$0F
        .byte   $0F,$10,$0C,$0C,$0D,$0D,$11,$10,$0F,$0B,$10,$0D,$0F,$0E,$0F,$0D
        .byte   $0E,$0C,$0E,$10,$10,$15,$0F,$0C,$08,$18,$0C,$0D

; =============================================================================
; credits_text — ending staff roll letter tiles ($8C95)
; Tile indices $01-$1A = A-Z, $20 = space; written to the nametable one
; letter per 4 frames by ending_column_tick (typewriter staff roll).
; =============================================================================
credits_text:
        .byte   $03,$08,$01,$12,$01,$03,$14,$05,$12,$20,$04,$05,$13,$09,$07,$0E ; "CHARACTER DESIGN"
        .byte   $05,$12,$19,$01,$13,$15,$0B,$09,$03,$08,$09,$09,$0E,$01,$06,$0B ; "ERYASUKICHIINAFK"
        .byte   $09,$0E,$07,$14,$0F,$0D,$20,$10,$0F,$0E,$0E,$01,$07,$09,$0E,$05 ; "INGTOM PONNAGINE"
        .byte   $0B,$0F,$32,$0D,$30,$33,$03,$0D,$20,$0D,$01,$0E,$01,$1C,$0B,$13 ; "KO?M??CM MANA?KS"
        .byte   $0F,$15,$0E,$04,$20,$10,$12,$0F,$07,$12,$01,$0D,$0D,$05,$12,$0F ; "OUND PROGRAMMERO"
        .byte   $07,$05,$12,$05,$14,$13,$15,$20,$0B,$15,$0E,$0D,$01,$0E,$01,$0D ; "GERETSU KUNMANAM"
        .byte   $09,$20,$09,$05,$14,$05,$0C,$19,$15,$15,$0B,$09,$03,$08,$01,$0E ; "I IETELYUUKICHAN"
        .byte   $1E,$13,$20,$10,$01,$10,$01,$10,$12,$0F,$07,$12,$01,$0D,$0D,$05 ; "?S PAPAPROGRAMME"
        .byte   $12,$08,$1C,$0D,$1C,$04,$1C,$10,$0C,$01,$0E,$0E,$05,$12,$01,$1C ; "RH?M?D?PLANNERA?"
        .byte   $0B,$13,$10,$05,$03,$09,$01,$0C,$20,$14,$08,$01,$0E,$0B,$13,$08 ; "KSPECIAL THANKSH"
        .byte   $09,$12,$0F,$19,$15,$0B,$09,$20,$0D,$01,$05,$14,$01,$0E,$09,$14 ; "IROYUKI MAETANIT"
        .byte   $01,$14,$13,$15,$19,$01,$20,$0B,$01,$13,$01,$09,$0D,$01,$0D,$0F ; "ATSUYA KASAIMAMO"
        .byte   $12,$15,$20,$01,$13,$0F,$13,$08,$09,$0E,$01,$0A,$15,$0E,$09,$03 ; "RU ASOSHINAJUNIC"
        .byte   $08,$09,$20,$0B,$01,$0E,$04,$01,$0D,$01,$13,$01,$08,$09,$12,$0F ; "HI KANDAMASAHIRO"
        .byte   $20,$14,$01,$0B,$01,$08,$01,$13,$08,$09,$01,$0B,$09,$0D,$09,$14 ; " TAKAHASHIAKIMIT"
        .byte   $13,$15,$20,$14,$13,$15,$02,$01,$14,$01,$19,$0F,$13,$08,$09,$01 ; "SU TSUBATAYOSHIA"
        .byte   $0B,$09,$20,$07,$0F,$14,$0F,$15,$0B,$01,$1A,$15,$0E,$01,$12,$09 ; "KI GOTOUKAZUNARI"
        .byte   $20,$13,$15,$1A,$15,$0B,$09,$19,$15,$15,$20,$19,$01,$0D,$01,$1A ; " SUZUKIYUU YAMAZ"
        .byte   $01,$0B,$09,$14,$0F,$0D,$0F,$08,$09,$12,$0F,$20,$08,$0F,$13,$0F ; "AKITOMOHIRO HOSO"
        .byte   $19,$01,$19,$0F,$13,$08,$09,$01,$0B,$09,$20,$0E,$01,$0E,$0B,$09 ; "YAYOSHIAKI NANKI"
        .byte   $19,$01,$13,$15,$08,$09,$14,$0F,$20,$13,$01,$13,$01,$0B,$09,$0A ; "YASUHITO SASAKIJ"
        .byte   $15,$0E,$20,$0B,$01,$14,$0F,$15,$13,$05,$09,$0B,$0F,$15,$20,$0A ; "UN KATOUSEIKOU J"
        .byte   $0F,$15,$07,$01,$0E,$0B,$05,$0E,$0A,$09,$20,$0B,$09,$0E,$0F,$15 ; "OUGANKENJI KINOU"
        .byte   $05,$14,$01,$0B,$01,$13,$08,$09,$20,$15,$0D,$05,$1A,$01,$17,$01 ; "ETAKASHI UMEZAWA"
        .byte   $0B,$01,$1A,$15,$19,$01,$20,$17,$01,$0B,$01,$1A,$15,$0B,$09,$0D ; "KAZUYA WAKAZUKIM"
        .byte   $01,$13,$01,$13,$08,$09,$20,$19,$01,$0D,$01,$15,$03,$08,$09,$0D ; "ASASHI YAMAUCHIM"
        .byte   $01,$0B,$0F,$14,$0F,$20,$0F,$07,$0F,$0D,$01,$13,$05,$09,$0A,$09 ; "AKOTO OGOMASEIJI"
        .byte   $20,$14,$01,$0E,$01,$0B,$01,$08,$09,$04,$05,$01,$0B,$09,$20,$0B ; " TANAKAHIDEAKI K"
        .byte   $01,$17,$01,$09,$12,$19,$0F,$15,$0A,$09,$20,$19,$01,$13,$15,$04 ; "AWAIRYOUJI YASUD"
        .byte   $01,$14,$01,$0B,$01,$19,$15,$0B,$09,$20,$17,$01,$0B,$09,$13,$01 ; "ATAKAYUKI WAKISA"
        .byte   $0B,$01,$14,$01,$0B,$15,$0D,$09,$20,$19,$0F,$13,$08,$09,$0E,$01 ; "KATAKUMI YOSHINA"
        .byte   $07,$01,$19,$01,$13,$15,$14,$0F,$20,$0E,$01,$0B,$01,$0D,$15,$12 ; "GAYASUTO NAKAMUR"
        .byte   $01,$13,$08,$09,$0E,$20,$09,$05,$0E,$01,$0B,$01,$08,$09,$12,$0F ; "ASHIN IENAKAHIRO"
        .byte   $06,$15,$0D,$09,$20,$0D,$0F,$12,$09,$09,$17,$01,$14,$05,$14,$13 ; "FUMI MORIIWATETS"
        .byte   $15,$19,$01,$20,$0D,$09,$15,$12,$01,$0D,$09,$03,$08,$09,$0E,$01 ; "UYA MIURAMICHINA"
        .byte   $12,$09,$20,$13,$01,$14,$0F,$15,$19,$15,$0B,$09,$0F,$20,$08,$01 ; "RI SATOUYUKIO HA"
        .byte   $13,$05,$07,$01,$17,$01,$08,$09,$12,$0F,$19,$15,$0B,$09,$20,$14 ; "SEGAWAHIROYUKI T"
        .byte   $01,$0E,$0E,$01,$09,$0D,$09,$03,$08,$09,$01,$0B,$09,$20,$08,$01 ; "ANNAIMICHIAKI HA"
        .byte   $0D,$01,$14,$01,$0B,$05,$0F,$20,$0D,$0F,$12,$09,$0D,$0F,$14,$0F ; "MATAKEO MORIMOTO"
        .byte   $0D,$01,$13,$01,$0B,$09,$20,$13,$01,$14,$0F,$15,$19,$0F,$15,$0A ; "MASAKI SATOUYOUJ"
        .byte   $09,$20,$0D,$09,$19,$01,$0D,$0F,$14,$0F,$13,$08,$09,$07,$05,$08 ; "I MIYAMOTOSHIGEH"
        .byte   $09,$13,$01,$20,$09,$09,$0E,$15,$0D,$01,$19,$0F,$13,$08,$09,$14 ; "ISA IINUMAYOSHIT"
        .byte   $0F,$0D,$0F,$20,$0B,$0F,$04,$01,$0D,$01,$14,$01,$0B,$05,$14,$13 ; "OMO KODAMATAKETS"
        .byte   $15,$07,$15,$20,$17,$01,$0B,$01,$02,$01,$19,$01,$13,$08,$09,$14 ; "UGU WAKABAYASHIT"
        .byte   $0F,$13,$08,$09,$14,$05,$12,$15,$20,$0F,$07,$15,$12,$01,$14,$01 ; "OSHITERU OGURATA"
        .byte   $0B,$05,$13,$08,$09,$20,$01,$12,$01,$09,$06,$09,$13,$08,$20,$0D ; "KESHI ARAIFISH M"
        .byte   $01,$0E,$14,$08,$01,$0E,$0B,$20,$19,$0F,$15,$20,$06,$0F,$12,$20 ; "ANTHANK YOU FOR "
        .byte   $10,$0C,$01,$19,$09,$0E,$07,$1C,$1C,$1C,$10,$12,$05,$13,$05,$0E ; "PLAYING???PRESEN"
        .byte   $14,$05,$04,$20,$02,$19,$03,$01,$10,$03,$0F,$0D,$20,$15,$1C,$13 ; "TED BYCAPCOM U?S"
        .byte   $1C,$01,$1C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; "?A??????????????"
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; "????????????????"
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; "????????????????"
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; "????????????????"
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; "????????????????"
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; "???????????"

; =============================================================================
; CHR pattern data $9000-$9FFF (16 pages)
; Referenced by: chr group 1 (Wily map screen); singles $9B-$9F pulled by
; stage CHR lists and chr group 3/5 entries.
; =============================================================================
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$18,$18,$00,$00,$00,$00,$00,$1C,$26,$26,$3E,$1C
        .byte   $00,$00,$00,$00,$00,$07,$38,$C0,$00,$00,$00,$00,$00,$00,$07,$3F
        .byte   $00,$00,$00,$00,$F8,$04,$04,$04,$00,$00,$00,$00,$00,$F8,$FA,$FA
        .byte   $00,$03,$07,$07,$0F,$1F,$1F,$3F,$00,$03,$07,$07,$0D,$19,$13,$33
        .byte   $00,$C0,$E0,$E0,$F0,$F8,$F8,$FC,$00,$C0,$E0,$E0,$F0,$F8,$F8,$FC
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$03,$04,$02,$02,$00,$00,$00,$00,$03,$07,$05,$05
        .byte   $00,$04,$20,$80,$82,$80,$8F,$8B,$00,$07,$3F,$FF,$7E,$79,$68,$57
        .byte   $FF,$00,$06,$4C,$4F,$F8,$7F,$00,$FF,$FF,$FE,$CF,$70,$07,$FF,$00
        .byte   $FF,$01,$00,$FE,$FF,$00,$0F,$F1,$FF,$FF,$00,$01,$00,$FF,$0F,$F1
        .byte   $A0,$F8,$3C,$07,$E0,$F0,$82,$E5,$A1,$F9,$3C,$C7,$18,$09,$F3,$E6
        .byte   $02,$09,$17,$4F,$BF,$7F,$FF,$FF,$83,$8E,$98,$70,$C0,$80,$00,$00
        .byte   $60,$F0,$78,$3C,$1E,$0F,$07,$06,$60,$D0,$68,$34,$1A,$0E,$06,$01
        .byte   $FF,$FF,$FF,$FF,$FF,$F7,$FD,$F0,$00,$00,$00,$00,$00,$08,$02,$0F
        .byte   $F7,$FD,$F6,$DA,$74,$D8,$60,$00,$08,$02,$09,$25,$8B,$27,$9F,$FF
        .byte   $03,$02,$01,$00,$00,$00,$01,$02,$02,$03,$01,$00,$00,$00,$00,$01
        .byte   $01,$84,$48,$A0,$50,$88,$25,$12,$00,$03,$87,$CF,$67,$33,$B9,$DC
        .byte   $00,$00,$00,$40,$20,$30,$1F,$9E,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
        .byte   $04,$08,$08,$10,$12,$62,$C2,$C0,$FA,$F6,$F6,$EE,$EE,$DE,$BE,$BC
        .byte   $3F,$7F,$7F,$FF,$FF,$F0,$8F,$7F,$23,$67,$7F,$FF,$FF,$F0,$80,$00
        .byte   $FC,$FE,$FE,$FF,$FF,$1F,$E3,$FC,$FC,$FE,$FE,$FF,$FF,$1F,$03,$00
        .byte   $01,$02,$04,$08,$10,$23,$78,$01,$01,$03,$07,$0F,$1F,$3F,$78,$00
        .byte   $02,$1C,$16,$72,$32,$01,$21,$05,$05,$1F,$2F,$4F,$4F,$7D,$5D,$7D
        .byte   $A0,$9F,$80,$80,$80,$82,$8F,$8B,$60,$7F,$7F,$7F,$7E,$7B,$68,$57
        .byte   $EF,$6F,$EF,$F7,$67,$EF,$3E,$D3,$2D,$29,$89,$B4,$64,$CD,$1C,$D3
        .byte   $FF,$FF,$F6,$F4,$6A,$4E,$53,$A2,$39,$73,$72,$F4,$6A,$4E,$53,$A2
        .byte   $4B,$13,$04,$20,$03,$07,$5F,$3F,$4C,$1C,$1B,$BF,$3C,$28,$40,$00
        .byte   $FF,$FF,$7F,$DF,$F7,$FF,$FD,$FF,$00,$00,$80,$20,$08,$00,$02,$00
        .byte   $FF,$FC,$FB,$F7,$CF,$9D,$BB,$77,$00,$03,$04,$08,$30,$63,$47,$8F
        .byte   $0F,$FF,$FF,$C0,$3F,$FF,$FF,$F8,$F0,$00,$00,$3F,$FF,$FF,$FF,$F8
        .byte   $FF,$FF,$0F,$01,$E0,$FE,$FF,$0F,$00,$00,$F0,$FE,$FF,$FF,$FF,$0F
        .byte   $00,$04,$08,$00,$11,$30,$30,$78,$03,$03,$07,$0F,$0F,$1F,$1F,$1F
        .byte   $29,$14,$16,$0B,$0B,$85,$65,$3C,$EE,$F7,$F7,$FB,$FB,$FD,$FD,$FC
        .byte   $18,$81,$42,$04,$C8,$90,$20,$80,$18,$40,$B1,$E3,$C7,$8F,$1F,$7F
        .byte   $84,$04,$08,$08,$10,$50,$60,$60,$7C,$FC,$F8,$F8,$F0,$F0,$E0,$F0
        .byte   $00,$00,$00,$06,$0A,$12,$06,$00,$00,$02,$06,$0A,$16,$2E,$3E,$01
        .byte   $BF,$BF,$BF,$BF,$BF,$81,$11,$71,$C0,$C0,$C0,$C0,$C0,$82,$6A,$8A
        .byte   $F9,$F9,$F9,$F1,$F3,$F3,$E3,$E7,$07,$07,$07,$0F,$0F,$0F,$1F,$1F
        .byte   $33,$27,$07,$20,$1F,$E7,$C3,$43,$3C,$38,$38,$20,$20,$97,$A4,$4C
        .byte   $44,$2A,$14,$0A,$02,$0A,$0A,$0A,$7D,$3B,$17,$0D,$0D,$05,$05,$05
        .byte   $A0,$9F,$80,$80,$80,$82,$8E,$8B,$60,$7F,$7F,$7F,$7E,$7B,$69,$57
        .byte   $C3,$83,$00,$32,$32,$32,$00,$2C,$FF,$FF,$C0,$AE,$0E,$8E,$80,$3C
        .byte   $F8,$F0,$01,$E3,$87,$4E,$1D,$1F,$F8,$F0,$02,$94,$E8,$51,$03,$23
        .byte   $7C,$E7,$9E,$78,$F0,$E0,$C0,$80,$83,$1F,$7E,$F8,$F0,$E0,$C0,$80
        .byte   $7E,$9F,$0D,$0F,$0F,$0F,$0F,$1F,$81,$A0,$12,$00,$00,$00,$00,$10
        .byte   $FF,$EF,$EF,$DF,$FF,$FF,$DF,$FF,$0F,$1F,$1F,$3F,$1F,$1F,$3F,$1F
        .byte   $E0,$C0,$C0,$80,$80,$80,$80,$80,$E0,$C0,$C0,$80,$80,$80,$80,$80
        .byte   $7C,$47,$83,$C7,$FF,$8F,$7F,$1F,$3F,$3F,$7F,$7F,$7F,$78,$07,$1F
        .byte   $19,$06,$C8,$FE,$C3,$C3,$FF,$FC,$F8,$E1,$C7,$CF,$3F,$FF,$FF,$FC
        .byte   $00,$01,$03,$1E,$F9,$E0,$86,$02,$FF,$FF,$FF,$FE,$F9,$E2,$87,$03
        .byte   $C0,$82,$02,$40,$20,$80,$40,$00,$CE,$85,$45,$A3,$C1,$FD,$49,$29
        .byte   $00,$00,$01,$01,$01,$00,$00,$00,$01,$01,$02,$02,$02,$07,$04,$00
        .byte   $F2,$F4,$E4,$ED,$D0,$4F,$3F,$7F,$0B,$0D,$1D,$1D,$30,$C8,$20,$80
        .byte   $C7,$9F,$F8,$86,$7F,$FF,$FF,$FF,$3F,$7F,$F8,$87,$40,$00,$00,$00
        .byte   $17,$40,$07,$08,$F9,$FE,$FF,$FF,$18,$60,$00,$F8,$07,$01,$00,$00
        .byte   $0A,$0A,$0A,$0A,$0A,$0A,$08,$00,$05,$05,$05,$05,$05,$05,$06,$08
        .byte   $A0,$9D,$81,$80,$83,$0C,$38,$C8,$60,$7D,$7D,$78,$60,$80,$00,$00
        .byte   $C2,$4C,$38,$C8,$88,$88,$88,$B8,$B1,$80,$00,$00,$00,$00,$00,$38
        .byte   $3B,$FF,$77,$F7,$E7,$F7,$E7,$77,$47,$87,$8F,$0F,$1F,$0F,$1F,$8F
        .byte   $00,$00,$00,$00,$00,$B8,$BE,$8F,$00,$00,$00,$00,$00,$00,$00,$30
        .byte   $0F,$1F,$3F,$1F,$3F,$3F,$7F,$FD,$10,$00,$20,$20,$00,$48,$9C,$3C
        .byte   $EF,$FF,$E7,$F7,$FB,$F5,$FD,$FD,$1F,$0F,$1F,$0F,$07,$0B,$03,$02
        .byte   $80,$80,$C0,$C0,$E0,$F0,$F8,$FC,$80,$80,$C0,$C0,$E0,$F0,$F8,$FC
        .byte   $00,$02,$00,$10,$00,$00,$00,$70,$00,$03,$0F,$1F,$1F,$1F,$1F,$7F
        .byte   $00,$09,$04,$06,$06,$06,$06,$06,$06,$F9,$FC,$FE,$FE,$FE,$FE,$FE
        .byte   $0F,$83,$C6,$78,$63,$0C,$78,$C8,$79,$FF,$FE,$78,$60,$00,$00,$00
        .byte   $83,$8C,$38,$C8,$88,$88,$83,$8C,$80,$80,$00,$00,$00,$00,$03,$0F
        .byte   $88,$88,$80,$80,$20,$E0,$60,$60,$00,$03,$0F,$0E,$2F,$EE,$EF,$EE
        .byte   $08,$04,$04,$04,$06,$06,$06,$07,$F8,$FC,$9C,$7C,$9E,$7E,$9E,$7F
        .byte   $67,$73,$79,$3C,$3F,$7F,$1F,$20,$9F,$8F,$87,$43,$40,$40,$20,$3E
        .byte   $83,$FF,$FF,$0D,$FB,$E3,$83,$04,$82,$FC,$F9,$F3,$07,$13,$43,$3C
        .byte   $F8,$F0,$E0,$C0,$C0,$80,$81,$02,$79,$F0,$E0,$C0,$C0,$80,$81,$03
        .byte   $FE,$FF,$60,$0F,$E0,$00,$00,$00,$01,$00,$90,$0F,$FF,$FF,$FF,$FF
        .byte   $BE,$0F,$73,$0C,$03,$00,$00,$00,$3E,$8F,$73,$FC,$FF,$FF,$FF,$FF
        .byte   $00,$80,$C0,$F0,$3D,$C3,$3C,$00,$00,$80,$C0,$F0,$3D,$C3,$FF,$FF
        .byte   $E8,$50,$10,$10,$B0,$68,$10,$20,$8F,$B7,$F7,$F7,$F7,$6F,$1F,$3F
        .byte   $06,$06,$0E,$0E,$0E,$1E,$1C,$38,$FE,$FE,$FE,$FE,$FE,$FE,$FC,$F8
        .byte   $88,$88,$83,$8C,$38,$F8,$08,$C8,$00,$00,$03,$0F,$3F,$FF,$0F,$8F
        .byte   $30,$C0,$00,$00,$00,$00,$00,$00,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $60,$60,$60,$60,$60,$61,$60,$C8,$EF,$EE,$EF,$EF,$EF,$EF,$EC,$C8
        .byte   $0E,$0E,$1C,$30,$C3,$0C,$30,$C0,$9E,$7E,$FC,$F0,$C0,$00,$00,$00
        .byte   $10,$06,$30,$C0,$00,$00,$00,$00,$11,$09,$0F,$3F,$1F,$1F,$1F,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$F1,$8F,$71,$41,$41
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FE,$F1,$F6,$F4,$F4,$F4,$F4
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$1F,$DF,$1F,$1F,$1F,$1F,$1F
        .byte   $00,$00,$00,$40,$00,$00,$01,$00,$3F,$3F,$3F,$7F,$7F,$7F,$7F,$7F
        .byte   $62,$88,$B8,$A8,$A8,$A8,$A8,$A8,$E3,$8F,$BF,$BF,$BF,$BF,$BF,$BF
        .byte   $48,$48,$4C,$4C,$4E,$4F,$48,$42,$8F,$8F,$8F,$8F,$8F,$8F,$88,$84
        .byte   $00,$00,$01,$01,$01,$81,$03,$02,$FF,$FF,$FF,$FF,$FF,$FF,$7F,$7E
        .byte   $03,$0C,$08,$08,$10,$10,$10,$10,$00,$10,$14,$34,$2F,$2F,$2C,$6C
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$03,$0F,$3C,$F0,$C0,$03,$0F,$3F
        .byte   $00,$00,$00,$00,$00,$00,$00,$20,$FF,$1F,$1F,$1F,$FF,$FF,$FF,$E1
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$41,$41,$41,$41,$41,$41,$41,$41
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F
        .byte   $00,$00,$00,$00,$00,$11,$11,$03,$00,$07,$0F,$0F,$0F,$1F,$1F,$1F
        .byte   $00,$40,$62,$E0,$E3,$CC,$30,$40,$00,$C0,$E0,$E2,$E3,$CF,$3F,$7F
        .byte   $23,$0F,$3E,$C6,$06,$06,$04,$04,$03,$2F,$3E,$FE,$FE,$FE,$FC,$FC
        .byte   $01,$81,$01,$01,$01,$01,$02,$02,$7F,$FF,$FF,$FF,$FF,$FF,$FE,$FE
        .byte   $A0,$28,$40,$50,$40,$40,$00,$40,$BF,$3F,$7F,$7F,$7E,$78,$61,$67
        .byte   $42,$02,$02,$00,$02,$00,$00,$00,$9C,$FC,$E4,$86,$1C,$7E,$FE,$FE
        .byte   $02,$02,$00,$04,$04,$04,$08,$08,$7E,$7E,$7C,$7C,$7C,$7C,$78,$78
        .byte   $20,$20,$20,$20,$40,$40,$42,$00,$5C,$5F,$5F,$5F,$BF,$BF,$83,$80
        .byte   $01,$08,$03,$07,$13,$18,$30,$30,$FF,$F8,$C3,$C7,$D3,$98,$B0,$30
        .byte   $0C,$7C,$FC,$E0,$00,$01,$01,$01,$0D,$7D,$FD,$E1,$01,$01,$01,$01
        .byte   $00,$00,$00,$00,$00,$00,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$3B,$C1,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$C1
        .byte   $00,$00,$00,$00,$00,$40,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
        .byte   $00,$00,$00,$00,$00,$00,$00,$E0,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4
        .byte   $00,$00,$00,$00,$00,$00,$10,$1E,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F
        .byte   $02,$06,$26,$26,$04,$05,$0D,$4C,$1E,$1E,$3E,$3E,$3C,$3D,$3D,$7D
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$F8,$F8,$F8,$F8,$F9,$F9,$F1,$F1
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FC,$FC,$FC,$FC,$F9,$F9,$F9,$F9
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FE,$F9,$E6,$F9,$E7,$FF
        .byte   $00,$00,$00,$00,$00,$00,$03,$07,$E6,$9E,$66,$9E,$7E,$FC,$F3,$06
        .byte   $00,$01,$03,$03,$19,$3F,$7F,$7F,$70,$71,$73,$63,$59,$37,$63,$46
        .byte   $39,$FD,$FE,$FF,$FF,$FC,$F8,$F0,$39,$BD,$86,$87,$07,$1C,$1B,$37
        .byte   $80,$E0,$C0,$00,$03,$0F,$1F,$3F,$80,$E0,$C6,$18,$33,$EE,$98,$20
        .byte   $1F,$7F,$FE,$FD,$BD,$BB,$DB,$DF,$18,$61,$82,$41,$05,$23,$43,$5F
        .byte   $F8,$8F,$7F,$FF,$FF,$FF,$FF,$FF,$F8,$8F,$79,$C7,$86,$0E,$1C,$38
        .byte   $48,$0A,$1A,$9A,$92,$B6,$F6,$F3,$79,$7B,$7B,$FB,$F3,$F7,$F7,$F3
        .byte   $00,$00,$00,$00,$00,$00,$00,$07,$FF,$FF,$FF,$FF,$FF,$FC,$F8,$F6
        .byte   $00,$00,$00,$00,$0F,$3F,$FF,$FF,$F1,$E1,$E0,$C0,$0B,$30,$E0,$03
        .byte   $00,$00,$00,$00,$C0,$E7,$E7,$FB,$F1,$F1,$31,$00,$C0,$E0,$E4,$FA
        .byte   $00,$06,$1F,$3F,$DF,$EF,$F7,$FB,$F8,$C2,$01,$01,$C1,$E0,$70,$39
        .byte   $3F,$DF,$EF,$EE,$6C,$78,$60,$00,$24,$54,$64,$AA,$08,$29,$23,$0F
        .byte   $E0,$C0,$81,$03,$07,$07,$0F,$3F,$6E,$5C,$B9,$7B,$F7,$E7,$CF,$B3
        .byte   $01,$02,$04,$08,$10,$20,$40,$80,$01,$03,$07,$0F,$1F,$3F,$7F,$FF
        .byte   $80,$C0,$E0,$70,$F8,$7C,$FE,$3F,$80,$C0,$E0,$F0,$F8,$FC,$FE,$FF
        .byte   $7F,$0F,$FF,$00,$3F,$00,$1F,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $0B,$0E,$1E,$1F,$1F,$1F,$0F,$03,$0F,$11,$21,$20,$20,$20,$10,$0C
        .byte   $38,$38,$7C,$FC,$FC,$FC,$F8,$F0,$38,$C4,$82,$02,$02,$02,$04,$08
        .byte   $00,$00,$00,$07,$78,$83,$3F,$FF,$FF,$FF,$FF,$FF,$F8,$80,$00,$00
        .byte   $01,$00,$0F,$F0,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00
        .byte   $FF,$00,$FF,$00,$00,$F0,$FE,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00
        .byte   $FF,$0D,$F7,$01,$FA,$07,$00,$F0,$FF,$FD,$F7,$FD,$FA,$07,$00,$00
        .byte   $87,$C7,$A7,$53,$A9,$D4,$6A,$07,$80,$C0,$A0,$50,$A8,$D4,$6A,$07
        .byte   $07,$07,$07,$07,$07,$07,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $F0,$D0,$F3,$D3,$D3,$D3,$D3,$D3,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $D3,$D3,$D3,$D3,$D3,$D3,$53,$13,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $13,$13,$13,$53,$13,$53,$53,$53,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $53,$53,$53,$53,$53,$53,$53,$53,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $53,$53,$53,$53,$53,$00,$F5,$F4,$00,$00,$00,$00,$00,$00,$0B,$0B
        .byte   $D3,$D3,$D3,$D3,$D3,$D3,$D3,$D3,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $D3,$D3,$D3,$D3,$D3,$D3,$13,$A3,$00,$00,$00,$00,$00,$00,$00,$60
        .byte   $F0,$D0,$F0,$D0,$D0,$D0,$D0,$D0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $50,$90,$60,$50,$5C,$5E,$5E,$5E,$00,$80,$E0,$F0,$FC,$FE,$FE,$FE
        .byte   $FE,$E0,$80,$7F,$04,$F8,$FF,$FF,$01,$1F,$00,$00,$07,$F8,$0F,$00
        .byte   $01,$00,$00,$FC,$3F,$63,$86,$F8,$FF,$FF,$00,$03,$C0,$7C,$87,$78
        .byte   $00,$40,$00,$C0,$8C,$F0,$0D,$C1,$00,$C0,$00,$C0,$7C,$0E,$F3,$FF
        .byte   $FF,$7F,$BF,$3F,$C7,$38,$0F,$83,$00,$00,$00,$00,$C0,$F8,$FF,$7F
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$1F,$87,$00,$00,$00,$00,$00,$00,$20,$88
        .byte   $36,$68,$00,$C0,$8C,$F0,$0D,$C1,$3E,$E8,$00,$C0,$7C,$0E,$F3,$FF
        .byte   $20,$40,$00,$A0,$00,$80,$00,$00,$DF,$BF,$FF,$5F,$FF,$7F,$FF,$FF
        .byte   $E1,$78,$B8,$3C,$0E,$55,$0E,$A5,$E2,$F8,$F8,$FC,$FE,$FD,$FE,$FD
        .byte   $FF,$7C,$20,$07,$02,$00,$00,$00,$00,$83,$40,$28,$03,$00,$00,$00
        .byte   $00,$00,$00,$FC,$3E,$60,$02,$21,$FF,$FF,$00,$03,$C1,$78,$03,$3E
        .byte   $36,$4C,$F0,$3E,$40,$00,$5F,$5F,$3E,$CC,$F0,$3E,$C0,$00,$A0,$A0
        .byte   $86,$F1,$F8,$FE,$7F,$7F,$9F,$CF,$67,$09,$06,$01,$80,$80,$E0,$F0
        .byte   $56,$8F,$FA,$7D,$36,$98,$8E,$CC,$FE,$FF,$FA,$7D,$B6,$58,$6E,$2C
        .byte   $00,$01,$05,$1D,$1D,$1D,$1D,$1D,$00,$01,$07,$1F,$1F,$1F,$1F,$1F
        .byte   $05,$04,$00,$01,$01,$05,$05,$05,$FA,$FB,$F8,$E1,$86,$9A,$FA,$FA
        .byte   $5F,$00,$00,$5F,$5F,$5F,$5F,$5F,$A0,$00,$00,$A0,$A0,$A0,$A0,$A0
        .byte   $F4,$74,$74,$F4,$F4,$F4,$F4,$F4,$0B,$0B,$0B,$0B,$0B,$0B,$0B,$0B
        .byte   $84,$81,$81,$81,$81,$81,$81,$81,$7C,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $10,$10,$10,$10,$10,$10,$10,$10,$30,$30,$30,$30,$30,$30,$30,$30
        .byte   $10,$10,$10,$10,$18,$18,$18,$18,$30,$30,$30,$30,$78,$78,$78,$78
        .byte   $08,$08,$0C,$0C,$0C,$4C,$4C,$4C,$78,$78,$FC,$FC,$FC,$BC,$BC,$BC
        .byte   $00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$03,$03,$03,$06,$06,$0E
        .byte   $4E,$4E,$8F,$8F,$87,$87,$87,$87,$BE,$BE,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $00,$00,$00,$00,$00,$80,$80,$C0,$00,$00,$00,$00,$00,$80,$80,$C0
        .byte   $03,$02,$01,$00,$0B,$3D,$0E,$03,$0C,$1D,$1F,$30,$4B,$3D,$0E,$03
        .byte   $03,$01,$03,$B4,$B7,$B6,$95,$49,$FF,$FF,$03,$B4,$B7,$B6,$95,$49
        .byte   $C0,$E0,$E0,$30,$48,$F0,$C0,$00,$C0,$E0,$E0,$30,$48,$F0,$C0,$00
        .byte   $E7,$73,$39,$19,$1C,$0C,$0C,$04,$F8,$7C,$3E,$1E,$1F,$0F,$0F,$07
        .byte   $C6,$E6,$E3,$F3,$F1,$F1,$F1,$E1,$36,$16,$1B,$0B,$0D,$0D,$0D,$1D
        .byte   $1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F
        .byte   $FF,$FF,$00,$FF,$00,$FF,$00,$FF,$FF,$00,$FF,$FF,$00,$00,$FF,$FF
        .byte   $D8,$F2,$30,$EB,$02,$F0,$1B,$E0,$E0,$03,$C3,$F3,$03,$0B,$E3,$F8
        .byte   $8E,$81,$78,$FF,$F9,$70,$4B,$E4,$9E,$FF,$87,$03,$07,$8F,$BB,$E4
        .byte   $81,$81,$81,$81,$81,$81,$81,$81,$7F,$7F,$7F,$7F,$7F,$7F,$7F,$7F
        .byte   $5E,$5E,$5E,$1E,$0E,$02,$02,$02,$FE,$FE,$FE,$FE,$3E,$0E,$06,$06
        .byte   $19,$02,$00,$03,$02,$00,$03,$C1,$19,$03,$03,$03,$03,$03,$03,$01
        .byte   $00,$00,$02,$00,$02,$00,$02,$2C,$00,$00,$06,$00,$06,$00,$2A,$2C
        .byte   $04,$00,$01,$01,$01,$01,$03,$03,$07,$03,$02,$02,$02,$02,$04,$04
        .byte   $E3,$E3,$C7,$C7,$C7,$8E,$8D,$0E,$1B,$1B,$37,$37,$37,$6E,$6D,$EE
        .byte   $19,$1A,$1A,$1A,$3A,$3A,$3A,$3A,$1F,$1F,$1F,$1F,$3F,$3F,$3F,$3F
        .byte   $07,$1F,$F8,$E0,$E2,$ED,$85,$85,$FF,$FF,$F8,$E0,$E3,$EA,$FA,$FA
        .byte   $5F,$5F,$5F,$5F,$5F,$5F,$5F,$5F,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0
        .byte   $03,$10,$3E,$07,$FF,$01,$1F,$00,$0C,$11,$3E,$7F,$FF,$FF,$FF,$FF
        .byte   $1E,$1C,$18,$E0,$FE,$FF,$FF,$FE,$FE,$FC,$18,$E0,$FE,$FF,$FF,$FE
        .byte   $3A,$3A,$3A,$3A,$3A,$9A,$3E,$82,$3F,$3F,$3F,$3F,$3F,$9F,$3E,$FC
        .byte   $85,$85,$85,$85,$85,$85,$85,$85,$FA,$FA,$FA,$FA,$FA,$FA,$FA,$FA
        .byte   $02,$02,$02,$02,$42,$52,$5E,$5E,$06,$06,$06,$06,$C6,$F6,$FE,$FE
        .byte   $00,$00,$00,$C0,$30,$2C,$23,$22,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $81,$81,$81,$80,$82,$82,$82,$82,$7F,$7F,$7F,$78,$79,$79,$79,$79
        .byte   $5E,$5E,$5E,$1E,$22,$0C,$07,$05,$FE,$FE,$FE,$1E,$E2,$FC,$FF,$DF
        .byte   $22,$42,$72,$78,$7A,$7A,$3A,$3A,$00,$40,$70,$7C,$7F,$7F,$3F,$3F
        .byte   $30,$2C,$22,$22,$22,$02,$02,$00,$00,$00,$00,$00,$00,$C0,$F0,$FC
        .byte   $FC,$7C,$7C,$7C,$3C,$3C,$3C,$1C,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $82,$AA,$82,$82,$82,$82,$82,$82,$C4,$EC,$FC,$C4,$FC,$C4,$FC,$FC
        .byte   $82,$82,$82,$82,$82,$82,$82,$82,$79,$79,$79,$79,$79,$79,$79,$79
        .byte   $05,$05,$05,$05,$05,$05,$05,$05,$C7,$EF,$FF,$FF,$C7,$FF,$C7,$FF
        .byte   $05,$05,$05,$05,$05,$05,$05,$05,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $3A,$3A,$3A,$3A,$3A,$3A,$3A,$0F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$0F
        .byte   $02,$02,$02,$02,$02,$02,$02,$02,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $5C,$5C,$5C,$5C,$5C,$5C,$5C,$5C,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $00,$00,$00,$00,$00,$00,$6C,$83,$FF,$FF,$FF,$FF,$FF,$FF,$EF,$83
        .byte   $8A,$8A,$8A,$8A,$8A,$FA,$8A,$FA,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4
        .byte   $00,$7E,$7E,$7A,$72,$62,$42,$7E,$00,$02,$06,$0E,$1E,$3E,$7E,$7E
        .byte   $23,$28,$2A,$2A,$2A,$2A,$2A,$2A,$33,$3C,$3F,$3F,$3F,$3F,$3F,$3F
        .byte   $C2,$F2,$3E,$0E,$02,$00,$01,$00,$FE,$FE,$3E,$CE,$F2,$FC,$FF,$FF
        .byte   $0F,$18,$78,$78,$78,$78,$38,$58,$10,$7F,$7F,$7F,$7F,$7F,$3F,$DF
        .byte   $C0,$38,$04,$02,$01,$00,$00,$00,$20,$C4,$FA,$FD,$FF,$FF,$FF,$FF
        .byte   $2A,$2A,$2A,$2A,$2A,$2A,$2A,$2A,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F
        .byte   $08,$08,$08,$08,$08,$08,$00,$08,$CF,$CF,$CE,$CE,$CE,$CE,$CE,$CE
        .byte   $00,$00,$80,$00,$00,$00,$00,$00,$FF,$FF,$FF,$3F,$FF,$3F,$FF,$3F
        .byte   $00,$30,$7C,$FC,$BE,$BB,$DB,$DF,$03,$31,$5C,$C4,$06,$23,$43,$5F
        .byte   $00,$00,$00,$18,$7F,$FF,$FF,$FF,$FB,$FB,$82,$18,$6F,$73,$71,$39
        .byte   $00,$00,$00,$00,$00,$B0,$B8,$BC,$CE,$CE,$CE,$CE,$07,$B1,$B8,$BC
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$3F,$FF,$3F,$BF,$FF,$7F,$3C
        .byte   $80,$C3,$C7,$EF,$EF,$F7,$F7,$FB,$98,$D0,$44,$2C,$2C,$36,$16,$1B
        .byte   $00,$E0,$F9,$FC,$FE,$BA,$DB,$DF,$00,$E0,$88,$44,$66,$22,$53,$5F
        .byte   $6C,$BB,$0A,$34,$41,$2A,$28,$92,$6C,$BB,$0A,$34,$41,$2A,$28,$92
        .byte   $48,$48,$08,$20,$20,$00,$00,$00,$48,$48,$08,$20,$20,$00,$00,$00
        .byte   $40,$48,$08,$00,$20,$00,$10,$00,$40,$48,$08,$00,$20,$00,$10,$00
        .byte   $6C,$BB,$0A,$24,$41,$02,$08,$82,$6C,$BB,$0A,$24,$41,$02,$08,$82
        .byte   $EF,$7F,$ED,$B7,$76,$ED,$3E,$D3,$EF,$7F,$ED,$B7,$76,$ED,$3E,$D3
        .byte   $FF,$FF,$F6,$B5,$EA,$4F,$D2,$A5,$FF,$FF,$F6,$B5,$EA,$4F,$D2,$A5
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$C0,$F0,$F8,$78,$7C,$04,$00,$00,$C0,$10,$98,$48,$74,$04
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$30,$30,$30,$30,$10
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$CE,$D6,$E6,$C6,$7C,$FF,$83,$39,$31,$29,$19,$39,$83
        .byte   $00,$38,$78,$38,$38,$38,$38,$38,$FF,$C7,$87,$C7,$C7,$C7,$C7,$C7
        .byte   $00,$7C,$C6,$06,$3C,$60,$C0,$FE,$FF,$83,$39,$F9,$C3,$9F,$3F,$01
        .byte   $00,$7C,$C6,$06,$3C,$06,$C6,$7C,$FF,$83,$39,$F9,$C3,$F9,$39,$83
        .byte   $00,$CC,$CC,$CC,$CC,$FE,$0C,$0C,$FF,$33,$33,$33,$33,$01,$F3,$F3
        .byte   $00,$FE,$C0,$FC,$06,$06,$C6,$7C,$FF,$01,$3F,$03,$F9,$F9,$39,$83
        .byte   $00,$7C,$C6,$C0,$FC,$C6,$C6,$7C,$FF,$83,$39,$3F,$03,$39,$39,$83
        .byte   $00,$FE,$06,$0C,$18,$38,$38,$38,$FF,$01,$F9,$F3,$E7,$C7,$C7,$C7
        .byte   $00,$7C,$C6,$C6,$7C,$C6,$C6,$7C,$FF,$83,$39,$39,$83,$39,$39,$83
        .byte   $00,$7C,$C6,$C6,$7E,$06,$C6,$7C,$FF,$83,$39,$39,$81,$F9,$39,$83
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; =============================================================================
; CHR pattern data $A000-$AFFF (16 pages)
; Referenced by: chr group 2 (title/prologue); $AC/$AE singles by ending
; groups and Wily 3/5 CHR lists.
; =============================================================================
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $40,$44,$40,$40,$40,$44,$44,$40,$33,$37,$33,$33,$33,$37,$37,$33
        .byte   $40,$40,$44,$40,$40,$44,$40,$40,$33,$33,$37,$33,$33,$37,$33,$33
        .byte   $4A,$0A,$0E,$4C,$08,$0E,$4E,$4C,$70,$34,$30,$70,$32,$30,$70,$70
        .byte   $0A,$0A,$4E,$0C,$0A,$4A,$0E,$4E,$30,$34,$70,$30,$30,$74,$30,$70
        .byte   $FF,$00,$00,$00,$00,$FF,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00
        .byte   $00,$FF,$00,$00,$FF,$00,$FF,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$FF
        .byte   $FF,$00,$00,$00,$00,$FF,$00,$00,$FF,$00,$00,$00,$00,$FF,$00,$00
        .byte   $00,$FF,$00,$00,$FF,$00,$FF,$FF,$00,$FF,$00,$00,$FF,$00,$FF,$FF
        .byte   $00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FE,$F9,$E7,$9F,$FF,$FF,$FF,$FF,$FE,$F9,$E7,$9F
        .byte   $00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FE,$08,$63,$F1,$FC,$FF,$FF,$FF,$FE,$08,$63,$F1,$FC,$FF
        .byte   $00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF
        .byte   $FF,$C7,$39,$FE,$FF,$FF,$FF,$7F,$FF,$C7,$39,$FE,$FF,$FF,$FF,$7F
        .byte   $00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$3F,$CF,$F7,$F9,$FF,$FF,$FF,$FF,$3F,$CF,$F7,$F9
        .byte   $7F,$9F,$E4,$F9,$B6,$FB,$9D,$CA,$7F,$9F,$E7,$F9,$B6,$FB,$9D,$CA
        .byte   $4C,$44,$22,$01,$10,$01,$07,$3C,$4C,$44,$22,$01,$10,$01,$07,$3C
        .byte   $FF,$FF,$00,$FF,$40,$90,$64,$29,$FF,$FF,$FF,$FF,$7F,$9F,$67,$29
        .byte   $86,$60,$03,$0D,$73,$E4,$09,$10,$86,$60,$03,$0D,$73,$E4,$09,$10
        .byte   $FF,$FF,$00,$FF,$02,$09,$27,$9F,$FF,$FF,$FF,$FF,$FE,$F9,$E7,$9F
        .byte   $7F,$F4,$CF,$9D,$24,$48,$12,$00,$7F,$F4,$CF,$9D,$24,$48,$12,$00
        .byte   $FE,$F9,$27,$9F,$7F,$FD,$FB,$BF,$FE,$F9,$E7,$9F,$7F,$FD,$FB,$BF
        .byte   $77,$CC,$A9,$3B,$62,$84,$08,$00,$77,$CC,$A9,$3B,$62,$84,$08,$00
        .byte   $7F,$B7,$FF,$EF,$EF,$DA,$D7,$B5,$7F,$B7,$FF,$EF,$EF,$DA,$D7,$B5
        .byte   $2D,$AA,$59,$10,$33,$21,$44,$08,$2D,$AA,$59,$10,$33,$21,$44,$08
        .byte   $FE,$FF,$7F,$FF,$FF,$FB,$6D,$55,$FE,$FF,$7F,$FF,$FF,$FB,$6D,$55
        .byte   $3F,$AE,$DB,$8B,$12,$24,$44,$08,$3F,$AE,$DB,$8B,$12,$24,$44,$08
        .byte   $00,$04,$00,$04,$04,$04,$00,$3F,$00,$04,$00,$00,$00,$00,$00,$00
        .byte   $21,$3F,$41,$7F,$41,$7F,$41,$7F,$0C,$00,$18,$00,$0C,$00,$18,$00
        .byte   $00,$49,$7F,$41,$7F,$40,$7F,$40,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $70,$47,$72,$47,$72,$47,$72,$07,$00,$00,$02,$00,$02,$00,$02,$00
        .byte   $80,$20,$00,$3E,$22,$3E,$20,$3C,$04,$00,$00,$00,$1C,$00,$1C,$00
        .byte   $23,$3A,$23,$3A,$23,$3A,$03,$00,$18,$01,$18,$01,$18,$01,$00,$00
        .byte   $21,$00,$7E,$52,$7E,$52,$7E,$02,$00,$00,$00,$10,$00,$10,$00,$00
        .byte   $DE,$42,$DE,$42,$DE,$42,$DC,$10,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$0C,$00,$0C,$00,$00,$00,$0C,$00,$00,$00,$00
        .byte   $00,$0C,$60,$6C,$60,$6C,$40,$00,$60,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$C0,$C0,$40,$C0,$40,$C0,$C0,$00,$00,$00,$80,$00,$80,$0C
        .byte   $40,$CC,$4C,$CC,$CC,$CC,$CC,$88,$80,$00,$80,$00,$00,$00,$00,$00
        .byte   $00,$00,$7F,$FF,$83,$81,$A3,$81,$00,$00,$00,$00,$7C,$00,$7C,$00
        .byte   $8B,$81,$83,$81,$93,$81,$83,$81,$7C,$00,$7C,$00,$7C,$00,$7C,$00
        .byte   $00,$00,$80,$80,$88,$80,$80,$80,$00,$00,$00,$00,$08,$00,$08,$00
        .byte   $80,$80,$80,$80,$94,$94,$94,$80,$08,$00,$08,$00,$08,$08,$08,$00
        .byte   $A3,$81,$8B,$81,$83,$81,$8B,$81,$7C,$00,$7C,$00,$7C,$00,$7C,$00
        .byte   $C3,$81,$83,$81,$83,$81,$93,$81,$7C,$00,$7C,$00,$7C,$00,$7C,$00
        .byte   $94,$80,$94,$80,$94,$80,$94,$94,$08,$00,$08,$00,$08,$00,$08,$08
        .byte   $94,$94,$94,$94,$94,$94,$94,$80,$08,$08,$08,$08,$08,$08,$08,$00
        .byte   $3F,$7F,$C8,$80,$80,$FF,$80,$80,$00,$00,$7F,$7F,$7F,$00,$00,$7F
        .byte   $80,$A2,$FF,$80,$80,$80,$8F,$9F,$00,$7F,$00,$00,$7F,$00,$60,$00
        .byte   $FC,$FC,$9C,$0C,$0C,$FC,$0C,$0C,$00,$00,$F0,$F0,$F0,$00,$00,$F0
        .byte   $0C,$2C,$FC,$0C,$0C,$0C,$0C,$0C,$00,$F0,$00,$00,$F0,$00,$70,$00
        .byte   $DF,$C3,$93,$93,$93,$83,$9B,$C3,$4C,$00,$0C,$4C,$0C,$40,$0C,$40
        .byte   $D3,$83,$9B,$93,$D3,$93,$83,$D3,$0C,$00,$4C,$0C,$4C,$0C,$40,$0C
        .byte   $1C,$7C,$0C,$0C,$0C,$0C,$0C,$1C,$70,$00,$00,$70,$00,$70,$00,$70
        .byte   $7C,$0C,$0C,$0C,$1C,$0C,$0C,$7C,$00,$00,$70,$00,$70,$00,$70,$00
        .byte   $08,$01,$44,$00,$23,$0F,$3F,$FF,$00,$00,$10,$00,$80,$00,$00,$00
        .byte   $E0,$80,$FF,$00,$24,$FF,$80,$FF,$7F,$7F,$00,$00,$04,$00,$7F,$00
        .byte   $40,$04,$01,$00,$FF,$FF,$FF,$FF,$01,$00,$20,$00,$00,$00,$00,$00
        .byte   $00,$00,$FF,$00,$59,$FF,$00,$FF,$FF,$FF,$00,$00,$41,$00,$FF,$00
        .byte   $20,$02,$00,$00,$FF,$FF,$FF,$FF,$00,$00,$20,$00,$00,$00,$00,$00
        .byte   $06,$01,$FF,$00,$44,$FF,$01,$FF,$FF,$FE,$00,$00,$40,$00,$FE,$00
        .byte   $10,$04,$00,$00,$FC,$F0,$C4,$14,$00,$00,$40,$00,$00,$0C,$30,$C0
        .byte   $54,$54,$54,$54,$5C,$70,$C4,$14,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$21,$FF,$80,$FF,$00,$24,$FF,$00,$01,$00,$7F,$00,$00,$04,$00
        .byte   $80,$FF,$00,$24,$FF,$80,$FF,$FF,$7F,$00,$00,$04,$00,$7F,$00,$00
        .byte   $00,$58,$FF,$00,$FF,$00,$59,$FF,$00,$40,$00,$FF,$00,$00,$41,$00
        .byte   $00,$FF,$00,$59,$FF,$00,$FF,$FF,$FF,$00,$00,$41,$00,$FF,$00,$00
        .byte   $00,$3F,$7F,$40,$40,$40,$40,$44,$00,$00,$40,$3F,$3F,$33,$33,$37
        .byte   $40,$40,$44,$44,$40,$40,$44,$40,$33,$33,$37,$37,$33,$33,$37,$33
        .byte   $00,$FE,$FE,$0C,$0A,$02,$0E,$0C,$00,$00,$08,$F0,$F0,$34,$30,$30
        .byte   $48,$0E,$0E,$4C,$0A,$0A,$0E,$4C,$72,$30,$30,$70,$30,$34,$30,$70
        .byte   $00,$54,$FF,$01,$FF,$00,$14,$FF,$00,$50,$00,$FE,$00,$00,$10,$00
        .byte   $01,$FF,$00,$44,$FF,$01,$FF,$FF,$FE,$00,$00,$40,$00,$FE,$00,$00
        .byte   $54,$5C,$70,$C4,$14,$54,$5C,$70,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $C4,$14,$54,$5C,$70,$C4,$14,$54,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$10,$00,$02,$00,$00,$00,$00,$00,$42,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $02,$00,$40,$04,$00,$00,$00,$00,$00,$10,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $20,$21,$80,$00,$00,$02,$00,$00,$88,$20,$08,$00,$20,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $44,$00,$41,$00,$00,$10,$00,$00,$40,$10,$01,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $20,$21,$82,$00,$00,$02,$00,$00,$88,$20,$0A,$00,$20,$00,$00,$01
        .byte   $00,$00,$02,$20,$00,$10,$04,$40,$08,$00,$00,$00,$00,$00,$00,$00
        .byte   $44,$00,$41,$00,$04,$50,$00,$10,$40,$10,$01,$00,$00,$00,$00,$02
        .byte   $00,$00,$00,$00,$42,$00,$08,$00,$00,$00,$20,$00,$00,$00,$00,$00
        .byte   $10,$7E,$10,$1E,$35,$55,$49,$3A,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $B5,$74,$7F,$74,$25,$F2,$26,$29,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$12,$79,$15,$24,$24,$44,$08,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $38,$00,$7E,$04,$0C,$18,$29,$4E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$20,$20,$20,$20,$22,$22,$1C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $04,$08,$10,$20,$20,$10,$08,$04,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$10,$7C,$20,$4E,$40,$90,$8E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$08,$7F,$04,$02,$46,$40,$3C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$4E,$40,$40,$40,$40,$48,$26,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$04,$08,$10,$10,$08,$06,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$38,$54,$92,$92,$92,$A2,$44,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $02,$4F,$42,$42,$4E,$53,$52,$2C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $38,$48,$0A,$0A,$3F,$4A,$4A,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$10,$28,$44,$02,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $04,$07,$04,$04,$1C,$26,$25,$18,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$7C,$11,$10,$30,$51,$51,$3E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $18,$04,$20,$26,$39,$21,$02,$0C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$22,$22,$22,$12,$02,$04,$18,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $3E,$0C,$1E,$21,$41,$1D,$25,$1E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$10,$76,$19,$11,$32,$52,$11,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$54,$54,$04,$08,$10,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$1C,$62,$02,$04,$08,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$1E,$12,$22,$04,$04,$08,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FE,$82,$82,$82,$82,$FC,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$61,$31,$01,$02,$02,$4C,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$7F,$01,$02,$14,$08,$08,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$03,$06,$0C,$3C,$04,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$30,$48,$48,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $60,$90,$90,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$41,$41,$01,$02,$04,$38,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $50,$50,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$22,$22,$22,$22,$02,$04,$18,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$7C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7C,$10,$7C,$54,$7C,$FE,$44,$44,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FE,$10,$54,$38,$FE,$10,$10,$10,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $0A,$9F,$04,$DF,$46,$99,$C0,$3F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $14,$9E,$24,$DF,$40,$8E,$CA,$3F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $28,$48,$FE,$5C,$6A,$49,$5C,$48,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$1E,$00,$3F,$01,$01,$02,$1C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$10,$10,$18,$14,$12,$10,$10,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $48,$48,$7E,$88,$3E,$08,$08,$7E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$92,$92,$FE,$10,$92,$92,$FE,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7F,$02,$04,$08,$14,$22,$41,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$24,$24,$24,$42,$42,$81,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $08,$08,$7F,$08,$2A,$49,$49,$08,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$10,$FE,$10,$10,$10,$20,$C0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$42,$42,$22,$04,$04,$08,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FE,$10,$10,$7C,$10,$10,$28,$C7,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $08,$7E,$08,$0C,$18,$28,$48,$08,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $22,$EA,$22,$FA,$62,$BF,$22,$22,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $52,$7E,$81,$BD,$08,$7E,$08,$18,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $3E,$08,$7E,$10,$3E,$56,$1A,$1E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $54,$54,$FE,$54,$54,$5C,$40,$3E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7C,$54,$7C,$54,$38,$6C,$AA,$28,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $20,$5E,$A8,$48,$CE,$68,$58,$7E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $EF,$A9,$EB,$A8,$EF,$AD,$AA,$AD,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $67,$55,$67,$55,$57,$65,$45,$4F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$08,$08,$0E,$28,$28,$28,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $EE,$A2,$E4,$5F,$E6,$44,$64,$CC,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $27,$F5,$47,$75,$00,$3E,$08,$7F,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $30,$E0,$2F,$F9,$69,$A9,$2F,$20,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $4C,$ED,$5E,$4C,$7E,$CD,$4C,$73,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $40,$7C,$90,$7C,$50,$FE,$10,$10,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $22,$FC,$57,$FA,$2A,$FA,$6A,$AA,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$C6,$C6,$C6,$C6,$7C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$C6,$7C,$C6,$C6,$7C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$06,$3C,$60,$C0,$FE,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$38,$44,$BA,$A2,$BA,$44,$38,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$3E,$08,$08,$08,$08,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$C6,$7E,$06,$C6,$7C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$88,$D8,$A8,$88,$88,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$1C,$3C,$1C,$1C,$1C,$1C,$1C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$7C,$20,$26,$78,$14,$20,$3E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $78,$10,$22,$43,$42,$42,$44,$38,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$42,$41,$41,$41,$48,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$20,$10,$10,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$1F,$3F,$3F,$7F,$01,$3D,$7D,$3F,$20,$40,$40,$80,$FE,$3E,$7E
        .byte   $00,$FF,$FF,$FF,$FF,$F0,$F7,$F7,$FF,$00,$00,$00,$00,$0F,$0F,$0F
        .byte   $00,$FF,$FF,$FF,$FF,$0F,$EF,$EF,$FF,$00,$00,$00,$00,$F0,$F0,$F0
        .byte   $00,$F8,$FC,$FC,$FE,$80,$BC,$BE,$FC,$04,$02,$02,$01,$7F,$7C,$7E
        .byte   $01,$01,$03,$03,$03,$03,$07,$07,$02,$02,$04,$04,$04,$04,$08,$08
        .byte   $E8,$E8,$E8,$E8,$E8,$E8,$E8,$D0,$18,$18,$18,$18,$18,$18,$18,$30
        .byte   $17,$17,$17,$17,$17,$17,$17,$0B,$18,$18,$18,$18,$18,$18,$18,$0C
        .byte   $80,$80,$C0,$C0,$C0,$C0,$E0,$E0,$40,$40,$20,$20,$20,$20,$10,$10
        .byte   $00,$00,$00,$00,$00,$00,$00,$0F,$00,$00,$00,$00,$00,$00,$1F,$10
        .byte   $07,$07,$0F,$0F,$0F,$1F,$1F,$FF,$08,$08,$10,$10,$10,$20,$E0,$00
        .byte   $D0,$D0,$D0,$D0,$D0,$D0,$C0,$FF,$30,$30,$30,$30,$30,$30,$3F,$00
        .byte   $0B,$0B,$0B,$0B,$0B,$0B,$03,$FF,$0C,$0C,$0C,$0C,$0C,$0C,$FC,$00
        .byte   $E0,$E0,$F0,$F0,$F0,$F8,$F8,$FF,$10,$10,$08,$08,$08,$04,$07,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$F0,$00,$00,$00,$00,$00,$00,$F8,$08
        .byte   $1F,$1F,$3F,$3F,$7F,$00,$3F,$7F,$20,$20,$40,$40,$80,$FF,$3F,$7F
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$FF,$FF,$00,$00,$00,$00,$00,$FF,$FF,$FF
        .byte   $F8,$F8,$FC,$FC,$FE,$00,$FC,$FE,$04,$04,$02,$02,$01,$FF,$FC,$FE
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$C6,$C6,$FE,$C6,$C6,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FC,$C6,$C6,$FC,$C6,$C6,$FC,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$C0,$C0,$C0,$C6,$7C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FC,$C6,$C6,$C6,$C6,$C6,$FC,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FE,$C0,$C0,$FC,$C0,$C0,$FE,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FE,$C0,$C0,$FC,$C0,$C0,$C0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$C0,$DE,$C6,$C6,$7C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$C6,$C6,$C6,$FE,$C6,$C6,$C6,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$30,$30,$30,$30,$30,$30,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$0C,$0C,$0C,$0C,$6C,$6C,$38,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$C4,$C8,$D0,$E0,$D0,$C8,$C4,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$60,$60,$60,$60,$60,$60,$7E,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$C6,$EE,$FE,$D6,$C6,$C6,$C6,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$C6,$E6,$F6,$DE,$CE,$C6,$C6,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$C6,$C6,$C6,$C6,$7C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FC,$C6,$C6,$C6,$FC,$C0,$C0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$C6,$C6,$DE,$CE,$7C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FC,$C6,$C6,$C6,$FC,$CC,$C6,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$7C,$C6,$C0,$7C,$06,$C6,$7C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FC,$30,$30,$30,$30,$30,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$C6,$C6,$C6,$C6,$C6,$C6,$7C,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$C6,$C6,$C6,$C6,$6C,$38,$10,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$C6,$C6,$C6,$D6,$FE,$EE,$C6,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$CC,$CC,$78,$30,$78,$CC,$CC,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$CC,$CC,$CC,$78,$30,$30,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FC,$8C,$18,$30,$60,$C4,$FC,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$58,$60,$60,$62,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$60,$60,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$60,$60,$20,$40,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$18,$18,$08,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$0C,$0C,$1C,$18,$10,$00,$30,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $52,$52,$52,$52,$52,$52,$52,$52,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F
        .byte   $52,$52,$52,$52,$52,$52,$52,$52,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F
        .byte   $2E,$2E,$2E,$2E,$2E,$2E,$2E,$2E,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0
        .byte   $2E,$2E,$2E,$2E,$2E,$2E,$2E,$2E,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0
        .byte   $80,$80,$80,$80,$80,$80,$80,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $80,$80,$80,$80,$80,$80,$80,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $C2,$C2,$C2,$C2,$C2,$C2,$C2,$C2,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $C2,$C2,$C2,$C2,$C2,$C2,$C2,$C2,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$10,$10,$10,$10,$10,$10,$10,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $10,$10,$10,$10,$10,$10,$10,$10,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$00,$00,$18,$18,$FF,$FF,$00,$FF,$FF,$FF,$00,$00,$00,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00
        .byte   $00,$52,$52,$52,$00,$15,$15,$52,$00,$2F,$2F,$2F,$00,$00,$00,$2F
        .byte   $00,$2E,$2E,$2E,$00,$50,$50,$2E,$00,$D0,$D0,$D0,$00,$00,$00,$D0
        .byte   $1F,$20,$40,$80,$80,$80,$80,$80,$3F,$7F,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $80,$80,$80,$80,$80,$80,$80,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$3F,$20,$20,$20,$23,$23,$23,$00,$00,$1F,$1F,$1F,$1F,$1F,$1C
        .byte   $20,$20,$20,$20,$20,$20,$20,$20,$1F,$1F,$11,$1F,$11,$1F,$11,$1F
        .byte   $00,$FE,$02,$02,$02,$E2,$E2,$E2,$00,$00,$FC,$FC,$FC,$DC,$DC,$1C
        .byte   $02,$12,$0A,$02,$02,$02,$02,$02,$FC,$F4,$E4,$FC,$FC,$FC,$FC,$FC
        .byte   $A0,$01,$80,$00,$00,$00,$00,$02,$88,$20,$08,$00,$21,$00,$00,$00
        .byte   $00,$01,$00,$00,$00,$00,$88,$20,$00,$00,$00,$04,$00,$00,$00,$00
        .byte   $45,$00,$40,$14,$02,$50,$00,$00,$40,$10,$01,$04,$08,$00,$00,$80
        .byte   $00,$00,$00,$00,$00,$80,$12,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$40,$00,$00,$04,$00,$00,$42,$00,$00,$00,$20,$00,$80,$08,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$01,$00,$00,$10,$01,$04,$00,$00,$00,$00,$82,$00,$00,$40,$00

; ─── unreferenced data ($B000-$BFDF) ───
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $7C,$FC,$FC,$FC,$FC,$00,$FC,$00,$7C,$02,$FE,$02,$02,$FE,$02,$FE
        .byte   $00,$00,$00,$00,$01,$00,$07,$00,$00,$00,$00,$01,$06,$0F,$38,$FF
        .byte   $07,$0F,$3F,$FF,$FF,$00,$FF,$00,$0F,$30,$FF,$00,$00,$FF,$00,$FF
        .byte   $C0,$C0,$C1,$C3,$83,$00,$07,$00,$C0,$23,$E3,$24,$44,$CF,$88,$9F
        .byte   $7F,$FF,$F0,$E0,$E0,$00,$C0,$00,$FF,$00,$FF,$10,$10,$E0,$20,$FF
        .byte   $E0,$E0,$01,$01,$03,$00,$03,$00,$F0,$11,$F3,$02,$04,$07,$04,$F7
        .byte   $7F,$FF,$F0,$F0,$F0,$00,$F8,$00,$FF,$00,$FF,$08,$08,$FC,$04,$FD
        .byte   $E0,$F0,$00,$00,$00,$00,$00,$01,$F0,$08,$FC,$00,$00,$00,$00,$FF
        .byte   $1F,$1F,$1F,$1F,$0F,$00,$07,$00,$1F,$20,$3F,$20,$10,$1F,$18,$0F
        .byte   $FE,$FF,$FF,$8F,$07,$00,$81,$00,$FF,$00,$FF,$70,$88,$87,$42,$C1
        .byte   $00,$00,$C0,$E0,$F0,$00,$FC,$00,$00,$C0,$E0,$10,$08,$FC,$02,$FF
        .byte   $00,$00,$01,$03,$07,$0F,$00,$3E,$00,$01,$03,$04,$0F,$10,$3F,$41
        .byte   $45,$F9,$F1,$E1,$C1,$81,$04,$0D,$FF,$FF,$FB,$12,$E3,$42,$87,$0E
        .byte   $04,$FF,$FF,$FF,$FE,$FD,$03,$EF,$FF,$FF,$FF,$00,$FF,$03,$FF,$1F
        .byte   $92,$E7,$C7,$07,$8F,$8F,$80,$9F,$FF,$FF,$6F,$C8,$9F,$90,$BF,$A0
        .byte   $02,$FE,$FD,$FD,$FB,$FB,$07,$F7,$FF,$FF,$FF,$03,$FF,$07,$FF,$0F
        .byte   $08,$EF,$DF,$DF,$BF,$BF,$80,$7F,$1F,$FF,$FF,$E0,$FF,$C0,$FF,$80
        .byte   $00,$FF,$C0,$BF,$BF,$78,$70,$7F,$FF,$FF,$FF,$7F,$FF,$F8,$F0,$FF
        .byte   $22,$EB,$0B,$EB,$EB,$0B,$08,$EB,$F7,$FF,$FF,$EC,$EF,$0C,$0F,$EC
        .byte   $08,$FA,$FD,$FD,$FD,$FE,$00,$FE,$FD,$FF,$FF,$03,$FF,$01,$FF,$01
        .byte   $82,$FF,$3F,$DF,$DF,$EF,$E0,$F7,$FF,$FF,$FF,$E0,$FF,$F0,$FF,$F8
        .byte   $F4,$7B,$BB,$BD,$DD,$EE,$0E,$F7,$FF,$FF,$FF,$7E,$FF,$1F,$FF,$0F
        .byte   $58,$DE,$EF,$E0,$FF,$FF,$00,$7B,$F9,$FE,$FF,$1F,$FF,$00,$FF,$87
        .byte   $81,$7F,$3F,$3F,$FF,$FF,$00,$FB,$FF,$FF,$7F,$C0,$FF,$00,$FF,$FC
        .byte   $00,$80,$C0,$E0,$F0,$F8,$00,$FE,$80,$C0,$E0,$10,$F8,$04,$FE,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$07,$0F,$00,$00,$7F
        .byte   $7C,$00,$00,$00,$01,$03,$07,$03,$82,$FC,$F8,$F0,$E1,$03,$07,$FF
        .byte   $1D,$3C,$7C,$FC,$F8,$F0,$E0,$C0,$1E,$3F,$7F,$FC,$F8,$F0,$E0,$C0
        .byte   $9F,$7F,$FF,$FE,$FE,$FF,$FE,$FC,$7F,$FF,$FF,$FF,$FF,$FF,$FE,$FC
        .byte   $BF,$00,$00,$00,$00,$8F,$0F,$00,$C0,$FF,$FF,$FF,$FF,$8F,$0F,$FF
        .byte   $F7,$0F,$0E,$1E,$1E,$FE,$FC,$00,$0F,$FF,$FF,$FF,$FF,$FE,$FC,$FC
        .byte   $7E,$00,$00,$00,$00,$3F,$3F,$7F,$81,$FF,$FF,$FF,$FF,$3F,$3F,$7F
        .byte   $FF,$00,$00,$00,$00,$C0,$C0,$00,$FF,$FF,$FF,$FF,$FF,$C0,$C0,$FF
        .byte   $E5,$04,$06,$03,$03,$03,$03,$00,$E6,$F7,$F7,$F3,$F3,$03,$03,$FF
        .byte   $FE,$00,$00,$00,$C0,$FE,$FE,$3F,$01,$FF,$FF,$FF,$FF,$FE,$FE,$FF
        .byte   $F7,$60,$00,$00,$00,$3F,$3F,$30,$78,$BF,$FF,$FF,$FF,$3F,$3F,$3F
        .byte   $F7,$03,$01,$00,$00,$C7,$E7,$00,$0F,$FF,$FF,$FF,$FF,$C7,$E7,$FF
        .byte   $7B,$81,$81,$C0,$C0,$FF,$FF,$3C,$87,$FF,$FF,$FF,$FF,$FF,$FF,$FC
        .byte   $FD,$FE,$FF,$FF,$7F,$FF,$FF,$3F,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$3F
        .byte   $FF,$00,$00,$80,$C0,$E0,$F0,$F0,$00,$FF,$FF,$FF,$FF,$E0,$F0,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$80,$C0,$E0,$F0,$F8,$00,$00,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$07,$0F,$1F,$3F,$7F,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $03,$03,$02,$00,$00,$00,$00,$03,$FF,$FF,$FE,$FC,$FC,$FC,$FC,$FF
        .byte   $80,$00,$00,$00,$00,$00,$00,$C0,$80,$00,$00,$00,$00,$01,$03,$CF
        .byte   $F0,$E0,$80,$00,$00,$00,$00,$00,$F3,$E7,$9F,$3F,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$1C,$FC,$F8,$F8,$F0,$F0,$F0,$E0,$FC
        .byte   $7E,$7E,$FC,$FC,$F8,$00,$00,$00,$7F,$7F,$FF,$FF,$FF,$07,$0F,$1F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$C0,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $1F,$0F,$0F,$07,$07,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FC,$FC,$FE
        .byte   $18,$F8,$F8,$FC,$FC,$00,$1C,$1E,$1F,$FF,$FF,$FF,$FF,$03,$1F,$1F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $0E,$03,$00,$00,$00,$00,$00,$00,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $1F,$0F,$07,$07,$00,$00,$00,$00,$1F,$0F,$07,$C7,$F0,$FC,$FF,$FF
        .byte   $F0,$F8,$FC,$FE,$00,$00,$FF,$3F,$FF,$FF,$FF,$FF,$00,$00,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$C0,$E0,$FF,$FF,$FF,$FF,$FF,$7F,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$80,$C0,$E0,$F0,$F8,$FC,$FE,$FF
        .byte   $00,$00,$00,$00,$0C,$1F,$3F,$7E,$01,$03,$07,$0F,$1B,$3F,$7F,$81
        .byte   $00,$00,$00,$00,$C1,$83,$07,$0F,$FE,$FC,$F8,$F0,$61,$C3,$87,$0F
        .byte   $00,$00,$00,$40,$60,$7F,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$80
        .byte   $03,$03,$02,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $C0,$80,$00,$00,$18,$F1,$E3,$8F,$DF,$FF,$FF,$FF,$FE,$FD,$F3,$6F
        .byte   $00,$00,$00,$00,$50,$BF,$BF,$7F,$FF,$FF,$FF,$BF,$7F,$DF,$FF,$80
        .byte   $00,$00,$00,$00,$01,$FF,$FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$01
        .byte   $1C,$38,$38,$38,$70,$70,$70,$E0,$FC,$F8,$F8,$F8,$F0,$F0,$F1,$E1
        .byte   $00,$00,$00,$00,$20,$7F,$FF,$FF,$1F,$3F,$3F,$7F,$FF,$FF,$FF,$00
        .byte   $00,$01,$01,$03,$17,$F7,$FF,$EE,$FF,$FF,$FF,$FF,$FF,$FF,$EF,$1E
        .byte   $C0,$E0,$E0,$F0,$FB,$3B,$3F,$1D,$FF,$FF,$FF,$FF,$FE,$3F,$3D,$1E
        .byte   $00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $0E,$0E,$0F,$07,$87,$87,$C3,$E3,$0F,$0F,$8F,$87,$C7,$C7,$E3,$13
        .byte   $00,$00,$00,$00,$A0,$BF,$BF,$DF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$E0
        .byte   $00,$00,$01,$01,$02,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$00,$80,$E0,$FC,$FF,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $0F,$03,$00,$00,$60,$3F,$CF,$F3,$FF,$FF,$FF,$FF,$DF,$FF,$FF,$FC
        .byte   $F0,$F8,$7C,$1E,$4F,$F3,$FC,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FB,$00
        .byte   $00,$00,$00,$00,$80,$7F,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$10,$F8,$FC,$FE,$80,$C0,$E0,$F0,$F8,$FC,$FE,$01
        .byte   $00,$01,$03,$00,$0F,$00,$00,$00,$01,$02,$04,$0F,$10,$3F,$7F,$FF
        .byte   $FC,$F8,$F0,$00,$C1,$03,$07,$0F,$FE,$04,$08,$F0,$21,$C3,$87,$0F
        .byte   $1F,$3F,$7F,$FF,$FF,$FE,$FC,$F8,$1F,$3F,$7F,$FF,$FF,$FE,$FC,$F8
        .byte   $7F,$7F,$7F,$00,$7F,$00,$01,$07,$FF,$80,$80,$FF,$80,$FF,$FF,$FF
        .byte   $FE,$F8,$E3,$0F,$1F,$7F,$FF,$FF,$FF,$07,$1F,$FF,$FF,$FF,$FF,$FF
        .byte   $1F,$FE,$FE,$FC,$FD,$F0,$E0,$80,$9F,$FF,$FF,$FF,$FE,$F7,$E7,$8F
        .byte   $7F,$FF,$FF,$00,$FF,$00,$00,$00,$FF,$00,$00,$FF,$00,$FF,$FF,$FF
        .byte   $FE,$FE,$FD,$01,$FD,$03,$03,$03,$FF,$01,$03,$FF,$03,$FF,$FF,$FF
        .byte   $E1,$E1,$C3,$C0,$C7,$80,$80,$80,$E3,$E2,$C4,$CF,$C8,$9F,$BF,$BF
        .byte   $FF,$FF,$FF,$00,$FF,$00,$00,$00,$FF,$00,$00,$FF,$00,$FF,$FF,$FF
        .byte   $F0,$FF,$FF,$00,$FF,$00,$7F,$FF,$EF,$00,$00,$FF,$00,$FF,$FF,$FF
        .byte   $03,$FF,$FF,$00,$FF,$00,$FF,$FF,$FD,$00,$00,$FF,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$FF,$00,$80,$C0,$FF,$00,$00,$FF,$00,$FF,$FF,$FF
        .byte   $E3,$F1,$F1,$01,$FC,$00,$00,$00,$F3,$09,$0D,$FD,$02,$FE,$FF,$FF
        .byte   $DF,$DF,$DF,$E0,$EF,$E0,$F0,$70,$FF,$E0,$E0,$FF,$F0,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$FF,$00,$00,$00,$FF,$00,$00,$FF,$00,$FF,$FF,$FF
        .byte   $BF,$BF,$CF,$03,$E0,$00,$00,$00,$FF,$7F,$2F,$E3,$10,$F0,$F8,$F8
        .byte   $FC,$FF,$FF,$FF,$FF,$3F,$07,$01,$FF,$FF,$FF,$FF,$FF,$3F,$07,$01
        .byte   $FF,$3F,$CF,$F0,$FC,$FF,$FF,$FF,$FF,$C0,$F0,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$FF,$00,$C0,$F0,$FF,$00,$00,$FF,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$FF,$00,$00,$00,$FF,$00,$00,$FF,$00,$FF,$FF,$FF
        .byte   $00,$80,$C0,$00,$F0,$00,$00,$00,$80,$40,$20,$F0,$08,$FC,$FE,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$01,$03,$07,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$03,$07,$00,$FE,$FC,$F8,$00,$01,$03,$07,$00
        .byte   $1F,$3F,$7F,$FF,$FF,$FE,$FC,$00,$1F,$3F,$7F,$FF,$FF,$FE,$FC,$00
        .byte   $F0,$E0,$C0,$80,$00,$00,$00,$00,$F0,$E0,$C0,$80,$00,$00,$00,$00
        .byte   $0F,$0F,$0F,$0F,$0F,$06,$00,$00,$6F,$0F,$0F,$0F,$0F,$06,$00,$00
        .byte   $FE,$FC,$F0,$C0,$80,$00,$00,$00,$FE,$FC,$F0,$C0,$80,$00,$00,$00
        .byte   $80,$00,$00,$00,$00,$00,$00,$00,$8F,$1F,$1F,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$7F,$7F,$FF,$FF,$00,$FF,$FF,$FF,$7F,$7F,$FF,$FF,$00
        .byte   $07,$07,$07,$FE,$FE,$FE,$FC,$00,$FB,$FF,$FF,$FE,$FE,$FE,$FC,$00
        .byte   $00,$00,$00,$07,$0F,$1F,$1F,$00,$7F,$7F,$FF,$07,$0F,$1F,$1F,$00
        .byte   $00,$01,$01,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $FF,$FF,$FF,$C0,$80,$80,$00,$00,$FF,$FF,$FF,$C0,$80,$80,$00,$00
        .byte   $FF,$FF,$FF,$00,$00,$00,$00,$00,$FF,$FF,$FF,$00,$00,$00,$00,$00
        .byte   $C0,$E0,$E0,$FF,$7F,$7F,$3F,$00,$FF,$FF,$FF,$FF,$7F,$7F,$3F,$00
        .byte   $00,$00,$00,$FC,$FE,$FF,$FF,$00,$FF,$FF,$FF,$FC,$FE,$FF,$FF,$00
        .byte   $70,$38,$38,$3F,$3F,$3F,$1F,$00,$FF,$FF,$FF,$3F,$3F,$3F,$1F,$00
        .byte   $00,$00,$00,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$C0,$C0,$E0,$E0,$00,$FC,$FC,$FE,$C0,$C0,$E0,$E0,$00
        .byte   $01,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00
        .byte   $7F,$0F,$03,$00,$00,$00,$00,$00,$7F,$0F,$03,$00,$00,$00,$00,$00
        .byte   $FC,$FF,$FF,$FF,$3F,$0F,$03,$00,$FF,$FF,$FF,$FF,$3F,$0F,$03,$00
        .byte   $00,$00,$C0,$FF,$FF,$FF,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$F0,$F8,$FC,$FE,$00,$FF,$FF,$FF,$F0,$F8,$FC,$FE,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$80,$C0,$E0,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$03,$07,$00,$1F,$00,$00,$01,$02,$04,$08,$1F,$20,$7F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$7E,$42,$42,$42,$42,$7E,$00
        .byte   $20,$10,$18,$0C,$0E,$07,$07,$03,$00,$00,$00,$00,$08,$00,$06,$00
        .byte   $00,$00,$00,$00,$00,$00,$80,$C0,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$40,$40,$60,$60,$70,$70,$78,$00,$00,$00,$40,$00,$40,$00,$40
        .byte   $00,$00,$00,$00,$00,$00,$01,$08,$00,$00,$00,$00,$00,$00,$01,$0F
        .byte   $00,$00,$00,$00,$00,$30,$00,$04,$00,$00,$00,$00,$00,$3F,$FF,$FF
        .byte   $03,$01,$01,$00,$00,$30,$06,$10,$03,$01,$01,$00,$00,$F0,$FE,$FF
        .byte   $E0,$F0,$F8,$FC,$FE,$79,$60,$10,$80,$00,$00,$C0,$80,$41,$67,$1F
        .byte   $78,$7C,$7C,$7E,$70,$40,$88,$58,$60,$40,$60,$40,$40,$4F,$8F,$DF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$C0
        .byte   $00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$01
        .byte   $00,$00,$02,$08,$20,$40,$88,$08,$00,$00,$03,$0F,$3F,$7F,$FF,$FF
        .byte   $20,$80,$08,$08,$08,$08,$08,$04,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $08,$08,$08,$08,$08,$08,$08,$0C,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $11,$03,$00,$00,$39,$5E,$DF,$DF,$FF,$C3,$BC,$87,$81,$C0,$C0,$C0
        .byte   $B0,$30,$38,$3C,$0E,$44,$A3,$D1,$BF,$3F,$3F,$3F,$CF,$77,$3B,$1D
        .byte   $03,$01,$00,$00,$00,$00,$07,$8F,$E3,$FF,$FF,$FF,$FF,$F8,$F7,$EF
        .byte   $00,$80,$00,$00,$00,$00,$80,$C3,$C0,$E0,$F0,$FC,$FE,$7F,$BC,$DB
        .byte   $00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$01
        .byte   $02,$04,$08,$19,$31,$31,$70,$70,$03,$07,$0F,$1F,$3F,$3F,$7F,$7F
        .byte   $08,$04,$04,$02,$02,$01,$81,$80,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $04,$06,$03,$01,$00,$00,$81,$E7,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $07,$07,$0F,$FF,$FC,$F0,$E0,$C0,$FF,$FF,$FF,$FF,$FC,$F0,$E0,$C0
        .byte   $DF,$3C,$73,$40,$0F,$3F,$0F,$07,$C0,$03,$0F,$30,$40,$00,$00,$00
        .byte   $01,$73,$01,$F4,$EC,$D1,$81,$00,$FD,$F3,$09,$0C,$1D,$33,$43,$81
        .byte   $03,$A0,$A0,$20,$00,$10,$18,$08,$EF,$EF,$EF,$3F,$9F,$5F,$5F,$8F
        .byte   $E7,$E7,$F7,$FF,$C9,$C9,$FF,$E7,$E7,$E6,$34,$18,$00,$00,$08,$1F
        .byte   $80,$80,$C0,$C0,$C0,$C0,$C0,$80,$00,$00,$00,$00,$00,$40,$40,$E0
        .byte   $00,$00,$00,$00,$00,$00,$00,$01,$00,$01,$01,$03,$03,$03,$02,$01
        .byte   $03,$07,$0F,$1F,$3F,$7F,$FF,$FF,$7B,$F7,$EF,$DF,$BF,$7F,$FF,$FF
        .byte   $BF,$BF,$BF,$DF,$DF,$EF,$EF,$F7,$BF,$BF,$BF,$DF,$DF,$EF,$EF,$F7
        .byte   $40,$40,$20,$30,$18,$0E,$07,$01,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $3F,$0F,$07,$07,$06,$1E,$FE,$FC,$FF,$FF,$FF,$FF,$FE,$FE,$FE,$FC
        .byte   $80,$80,$00,$00,$00,$00,$00,$00,$80,$80,$00,$00,$00,$00,$00,$00
        .byte   $02,$00,$00,$00,$00,$00,$00,$00,$01,$02,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $04,$02,$01,$00,$00,$00,$00,$00,$07,$03,$01,$00,$00,$00,$00,$00
        .byte   $01,$00,$80,$80,$40,$20,$10,$0C,$FF,$FF,$FF,$FF,$7F,$3F,$1F,$0F
        .byte   $80,$C0,$40,$00,$1E,$79,$04,$20,$F0,$F0,$F8,$F8,$FE,$FF,$FD,$3B
        .byte   $03,$07,$0F,$1F,$1F,$3F,$3F,$7F,$03,$07,$0F,$1F,$1F,$3F,$3F,$7F
        .byte   $FF,$F8,$E0,$C0,$80,$80,$00,$00,$FF,$F8,$E3,$CF,$9F,$9F,$3F,$3F
        .byte   $FA,$7D,$1E,$0F,$07,$07,$03,$03,$FB,$79,$90,$E0,$F0,$F0,$F8,$F8
        .byte   $00,$00,$80,$60,$B8,$C7,$F8,$FF,$FF,$FF,$FF,$7F,$3F,$07,$00,$00
        .byte   $3C,$1C,$18,$18,$30,$CC,$1E,$FF,$FC,$FC,$F8,$F8,$F0,$C0,$00,$00
        .byte   $07,$01,$00,$00,$00,$00,$00,$00,$07,$01,$00,$00,$00,$00,$00,$00
        .byte   $01,$86,$78,$00,$00,$00,$00,$00,$DF,$FE,$78,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$01,$01,$03,$03,$03,$00,$00,$00,$01,$01,$03,$03,$03
        .byte   $7F,$FF,$FF,$FF,$FF,$FF,$FF,$C0,$7F,$FF,$FF,$FF,$FF,$FF,$FF,$C0
        .byte   $00,$00,$80,$80,$C0,$E1,$F9,$1C,$3F,$3F,$9E,$9C,$CC,$E0,$F0,$00
        .byte   $03,$03,$39,$7C,$FC,$F9,$F3,$E3,$C0,$00,$00,$00,$00,$01,$03,$03
        .byte   $FF,$FF,$C1,$3E,$C0,$80,$00,$00,$00,$00,$00,$3E,$FE,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$0F,$03,$01,$00,$00,$00,$00,$00,$00,$F0,$FC,$FE,$FF
        .byte   $00,$80,$C0,$C0,$E0,$E0,$F0,$70,$00,$38,$1E,$1E,$0F,$0F,$06,$02
        .byte   $07,$04,$00,$00,$00,$00,$00,$00,$07,$04,$03,$07,$0F,$0F,$1F,$1F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$3F,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $06,$01,$00,$00,$00,$00,$00,$00,$C0,$F0,$FC,$FE,$FF,$FF,$FF,$FF
        .byte   $E3,$67,$87,$47,$33,$1C,$1F,$0F,$03,$07,$07,$07,$03,$80,$80,$C0
        .byte   $00,$00,$00,$80,$D8,$F0,$0F,$FF,$FF,$FB,$FB,$FB,$F9,$F0,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$07,$C7,$FD,$FC,$FE,$FE,$FE,$F0,$30,$00
        .byte   $78,$F8,$F8,$FC,$FC,$FC,$FC,$FC,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$1E,$3C,$38,$38,$38,$38,$38,$18
        .byte   $00,$00,$00,$20,$70,$70,$70,$20,$1F,$0F,$07,$27,$77,$77,$77,$27
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $0F,$07,$07,$03,$03,$03,$03,$03,$C0,$E0,$E0,$E0,$F0,$F0,$F0,$F0
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FC,$FC,$FC,$FC,$F8,$F8,$F8,$F0,$00,$00,$00,$01,$01,$01,$03,$03
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$80,$C0,$C0,$C0,$E0,$E0,$E0,$E0
        .byte   $00,$00,$00,$00,$10,$10,$18,$1C,$1C,$1E,$0F,$0F,$17,$17,$1B,$1D
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$0F,$1F,$FF,$FF,$FF,$FF,$FC,$F0
        .byte   $00,$00,$00,$00,$00,$00,$30,$F8,$FF,$FF,$FF,$FF,$87,$03,$01,$01
        .byte   $03,$03,$07,$07,$0F,$0F,$1F,$3F,$F0,$E0,$E0,$E0,$C0,$C0,$80,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FE,$FC,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $F0,$E0,$E0,$C0,$80,$00,$00,$00,$07,$07,$0F,$0F,$1F,$3F,$7E,$38
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$E0,$C0,$C0,$80,$80,$00,$00,$00
        .byte   $0E,$0F,$0F,$0F,$07,$07,$07,$03,$0E,$0F,$0F,$0F,$07,$07,$07,$03
        .byte   $01,$03,$C7,$F0,$FE,$FF,$FF,$F1,$00,$00,$C0,$F0,$FE,$FF,$FF,$FF
        .byte   $C0,$80,$00,$00,$02,$41,$A1,$D0,$00,$3C,$7E,$FF,$FB,$7D,$BD,$DE
        .byte   $FF,$FF,$FF,$7F,$3F,$0F,$80,$C0,$00,$00,$00,$00,$80,$C0,$F0,$FC
        .byte   $FF,$FF,$FF,$FE,$F8,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $F8,$E0,$80,$00,$60,$18,$04,$01,$00,$00,$00,$03,$7F,$1F,$07,$01
        .byte   $00,$00,$00,$40,$20,$10,$0C,$03,$00,$00,$40,$E0,$B0,$DC,$EF,$F3
        .byte   $00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,$00,$00,$00,$00,$E0
        .byte   $01,$01,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00
        .byte   $E0,$E0,$E0,$F0,$7C,$3F,$1C,$18,$FF,$FF,$FF,$FF,$7F,$3F,$1F,$1F
        .byte   $68,$28,$34,$14,$EA,$8B,$0D,$05,$EF,$EF,$F7,$F7,$FB,$FB,$FD,$FD
        .byte   $00,$30,$18,$06,$03,$00,$00,$80,$7F,$BF,$DF,$E7,$FB,$FC,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$C0,$72,$37,$00,$C0,$F0,$FC,$FE,$F8,$70,$B0
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $C0,$60,$20,$30,$18,$08,$06,$03,$FC,$7F,$3F,$3F,$1F,$0F,$07,$03
        .byte   $60,$10,$0C,$0E,$76,$7B,$79,$7C,$78,$9C,$C0,$80,$00,$00,$00,$00
        .byte   $0C,$0E,$06,$03,$03,$01,$01,$00,$0F,$0F,$07,$03,$03,$01,$01,$00
        .byte   $06,$02,$07,$8F,$F1,$C0,$80,$C0,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $80,$C1,$43,$62,$B6,$DE,$E6,$38,$FF,$FF,$7F,$7E,$BE,$DE,$E6,$F8
        .byte   $07,$C7,$03,$E1,$F0,$F0,$F8,$78,$C0,$E0,$10,$00,$00,$00,$00,$00
        .byte   $00,$80,$80,$80,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $1C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        .byte   $C0,$40,$60,$30,$3F,$30,$10,$10,$FF,$7F,$7F,$3F,$3F,$3F,$1F,$1F
        .byte   $1F,$0F,$27,$C1,$01,$01,$03,$02,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
        .byte   $38,$18,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
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

; ─── padding, MMC1 reset stub ($BFE0: sei / inc $BFE1) and vectors ($BFFA) ───
        .byte   $78,$EE,$E1,$BF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$00,$00,$E0,$BF,$E0,$BF
