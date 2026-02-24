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
addr_0010           := $0010
addr_0320           := $0320
addr_0508           := $0508
addr_0901           := $0901
addr_0D20           := $0D20
addr_0F06           := $0F06
addr_1003           := $1003
addr_1120           := $1120
addr_1121           := $1121
addr_1EA4           := $1EA4
addr_2008           := $2008
addr_2017           := $2017
addr_2020           := $2020
addr_2060           := $2060
addr_3800           := $3800
addr_5000           := $5000
addr_5E10           := $5E10
addr_72A0           := $72A0
addr_7484           := $7484
bank_switch_enqueue           := $C051
banked_entry           := $C05D
wait_for_vblank_0D           := $C0AB
ppu_fill_from_ptr           := $C628
chr_ram_bank_load           := $C644
scroll_column_prep           := $C70C
ppu_set_scroll_state           := $C723
ppu_column_fill           := $C747
metatile_render_column           := $C760
divide_8bit           := $C84E
attr_table_write           := $C8B1
metatile_column_render           := $CA0B
clear_oam_buffer_fixed     := $CC6C
fixed_sprite_data_D001           := $D001
ppu_buffer_transfer           := $D11B
ppu_scroll_column_update           := $D1DF
fixed_D2ED           := $D2ED
fixed_D2EF           := $D2EF
ending_player_render           := $D624
ending_player_anim           := $D627
ending_scroll_update           := $D637
ending_init_walk           := $D642
ending_walk_step           := $D64D
; --- Bank $0D dispatch table (7 JMP entries at $8000) ---
        jmp     stage_select_init       ; $8000: entry 0 — stage select screen
        jmp     main_stage_render       ; $8003: entry 1 — main stage OAM render
        jmp     boss_get_screen_init    ; $8006: entry 2 — boss get screen
        jmp     wily_intro_init         ; $8009: entry 3 — Wily intro sequence
        jmp     ending_chr_load         ; $800C: entry 4 — ending CHR load
        jmp     ending_scene_init       ; $800F: entry 5 — ending scene
        jmp     ending_walk_init        ; $8012: entry 6 — ending walk
; --- stage_select_init -- Stage Select Screen Init ($8015) ---
stage_select_init:
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

; =============================================================================
; Stage Select Initialization — clear boss portraits and set up OAM
; =============================================================================
stage_init_clear_loop:  stx     $00     ; Save boss index
        lsr     $01                     ; Shift out boss beaten flag
        bcc     stage_init_next_boss
        lda     intro_ppu_addr_hi,x
        sta     $09
        lda     intro_ppu_addr_lo,x
        sta     $08
        ldx     #$04
        lda     #$00
stage_init_ppu_fill:  lda     $09
        sta     $2006                   ; Set PPU write address
        lda     $08
        sta     $2006                   ; Set PPU write address
        ldy     #$04
        lda     #$00
stage_init_ppu_byte:  sta     $2007     ; Clear boss portrait tile
        dey
        bne     stage_init_ppu_byte
        clc
        lda     $08
        adc     #$20
        sta     $08
        dex
        bne     stage_init_ppu_fill
stage_init_next_boss:  ldx     $00
        inx
        cpx     #$08
        bne     stage_init_clear_loop
        ldx     #$1F
        jsr     load_scroll_palette
        jsr     clear_oam_buffer
        ldx     #$00
        lda     $9A
        sta     $02
        ldy     #$00
stage_init_oam_loop:  stx     $01       ; Save boss index
        lsr     $02
        bcs     stage_init_oam_next
        lda     boss_oam_size_table,x
        sta     $00
        lda     boss_oam_offset_table,x
        tax
stage_init_oam_copy:  lda     boss_portrait_oam_data,x
        sta     $0200,y                 ; Copy to OAM buffer
        iny
        inx
        dec     $00
        bne     stage_init_oam_copy
stage_init_oam_next:  ldx     $01
        inx
        cpx     #$08
        bne     stage_init_oam_loop
        jsr     enable_nmi_and_rendering
        lda     #$0C
        jsr     bank_switch_enqueue
        lda     #$00
        sta     $2A
        sta     $FD
        jsr     wait_for_vblank_0D

; =============================================================================
; Stage Main Loop
; Per-frame update: render player, check pause, sync PPU.
; =============================================================================
stage_main_loop:  lda     $27           ; Main stage loop (called each frame)
        and     #$08                    ; Check Start button (pause)
        bne     stage_paused_handler
        lda     $27
        and     #$F0                    ; Check D-pad for stage transition
        beq     stage_loop_render
        lda     #$2F
        jsr     bank_switch_enqueue
        jsr     check_stage_transition
stage_loop_render:  jsr     player_render_collision ; Render player & update collision
        jsr     wait_for_vblank_0D      ; Wait for next frame
        jmp     stage_main_loop

; =============================================================================
; Stage Paused Handler — check if all bosses beaten or pause menu
; =============================================================================
stage_paused_handler:  ldx     $2A
        bne     stage_select_handler
        lda     $9A
        cmp     #$FF
        bne     stage_loop_render
        lda     #$08
        sta     $2A
        jmp     intro_cleanup

; =============================================================================
; Stage Select Handler — load boss entities and run intro sequence
; =============================================================================
stage_select_handler:  ldy     stage_select_index_table,x
        lda     $9A
        and     boss_bitmask_table,y
        bne     stage_loop_render
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
stage_select_load_entity:  lda     stage_entity_x_table,x
        sta     $0460,y
        lda     stage_entity_bank_table,x
        sta     $0440,y
        lda     #$00
        sta     $0480,y
        inx
        iny
        cpy     #$06
        bne     stage_select_load_entity
        lda     #$0A
        sta     $04A0
        lda     #$00
        sta     $04C0
        sta     $0680
        lda     #$30
        sta     $FD

; =============================================================================
; Intro Palette Blink — animate stage select palette cycling
; =============================================================================
intro_palette_blink_loop:  ldx     #$3F
        lda     $FD
        and     #$04                    ; Toggle palette every 4 frames
        bne     intro_load_palette
        ldx     #$1F
intro_load_palette:  jsr     load_scroll_palette
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
        bne     intro_update_scroll_col
        inc     $0680
intro_update_scroll_col:  lda     $0440,x
        jsr     scroll_column_prep
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
        beq     intro_finish_palette
        jsr     wait_for_vblank_0D
        jmp     intro_palette_blink_loop

; =============================================================================
; Intro Finish Palette — load weapon and stage palettes for drop
; =============================================================================
intro_finish_palette:  ldx     #$1F
        jsr     load_scroll_palette
        lda     #$2C
        sta     $0358
        lda     #$11
        sta     $0359
        ldy     #$07
intro_copy_weapon_palette:  lda     weapon_palette_base,y
        sta     $0366,y
        dey
        bpl     intro_copy_weapon_palette
        lda     $2A
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
intro_copy_stage_palette:  lda     stage_palette_per_boss,x
        sta     $036E,y
        inx
        iny
        cpy     #$08
        bne     intro_copy_stage_palette
        lda     #$01
        sta     $20
        jsr     ppu_set_scroll_state
        lda     #$18
        sta     $FD
        lda     #$0A
        jsr     bank_switch_enqueue

; =============================================================================
; Intro Blank Frames — wait before player drop animation
; =============================================================================
intro_blank_frames:  jsr     clear_oam_buffer
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     intro_blank_frames
        jsr     clear_projectile_positions
        lda     #$80
        sta     $0460
        lda     #$20
        sta     $04A0
        lda     #$00
        sta     $0680
        sta     $06A0

; =============================================================================
; Intro Player Drop — drop Mega Man into stage with gravity
; =============================================================================
intro_player_drop_loop:  lda     #$00
        sta     $0680
        clc
        lda     $04A0
        adc     #$08                    ; Drop 8 pixels per frame
        sta     $04A0
        cmp     #$78                    ; Reached ground Y=$78?
        beq     intro_player_landed
        jsr     clear_oam_buffer
        jsr     update_projectile_anim
        jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        jmp     intro_player_drop_loop

; =============================================================================
; Intro Player Landed — begin weapon flash after landing
; =============================================================================
intro_player_landed:  inc     $06A0
        lda     $23
        and     #$01                    ; Facing direction from controller
        sta     $0420
        lda     #$00
        sta     $FD
        lda     #$08
        sta     $FE

; =============================================================================
; Intro Weapon Flash — cycle weapon palette colors
; =============================================================================
intro_weapon_flash_loop:  lda     #$00
        sta     $0680
        dec     $FE
        bne     intro_weapon_flash_frame
        lda     #$08
        sta     $FE
        ldx     $FD
        lda     weapon_flash_tile_lo,x
        sta     $0368
        lda     weapon_flash_tile_hi,x
        sta     $0369
        inx
        inx
        cpx     #$10                    ; All 8 color pairs shown?
        beq     intro_weapon_show_hold
        stx     $FD
intro_weapon_flash_frame:  jsr     clear_oam_buffer
        jsr     update_projectile_anim
        jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        jmp     intro_weapon_flash_loop

; =============================================================================
; Intro Weapon Show — hold weapon color then scroll health bar
; =============================================================================
intro_weapon_show_hold:  lda     #$50
        sta     $FD
intro_weapon_show_frame:  jsr     clear_oam_buffer
        jsr     update_projectile_anim
        jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     intro_weapon_show_frame
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
intro_health_fill_loop:  lda     $FD
        and     #$03                    ; Add health every 4 frames
        bne     intro_health_fill_frame
        ldx     $FE
        lda     intro_health_tile_data,x
        sta     $03B8
        lda     #$01
        sta     $47
        inc     $FE
        inc     $03B7
intro_health_fill_frame:  jsr     clear_oam_buffer
        jsr     update_projectile_anim
        jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     intro_health_fill_loop
        lda     #$BB
        sta     $FD
intro_health_hold_frame:  jsr     clear_oam_buffer
        jsr     update_projectile_anim
        jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     intro_health_hold_frame

; =============================================================================
; Intro Cleanup — disable NMI/rendering and return
; =============================================================================
intro_cleanup:  jsr     disable_nmi_and_rendering
        rts

; =============================================================================
; Load Scroll Palette — copy 32-byte palette from stage_palette_data
; =============================================================================
load_scroll_palette:  ldy     #$1F
load_palette_byte:  lda     stage_palette_data,x
        sta     $0356,y
        dex
        dey
        bpl     load_palette_byte
        rts

; =============================================================================
; Check Stage Transition — look up next stage from D-pad input
; =============================================================================
check_stage_transition:  lda     $27
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        beq     check_stage_transition_rts
        cmp     #$09
        bcs     check_stage_transition_rts
        sta     $00
        dec     $00
        lda     $2A
        asl     a
        asl     a
        asl     a
        clc
        adc     $00
        tax
        lda     stage_transition_table,x
        sta     $2A
check_stage_transition_rts:  rts

stage_transition_table:  .byte   $02,$06,$00,$08,$00,$00,$00,$04
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
        bne     collision_hide_sprites
        ldy     $2A
        lda     collision_x_offset_table,y
        sta     $09
        lda     collision_y_offset_table,y
        sta     $08
        ldx     #$00
collision_box_loop:  clc
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
        bne     collision_box_loop
        rts

collision_hide_sprites:  lda     #$F8
        ldx     #$0F
collision_hide_loop:  sta     $02E0,x
        dex
        bpl     collision_hide_loop
        rts

; =============================================================================
; Render Player Sprites — draw 3 sprite layers for Mega Man
; =============================================================================
render_player_sprites:  ldy     #$50
        ldx     #$00
        lda     #$30
        sta     $00
        lda     #$02
        sta     $03
render_sprite_layer_loop:  sty     $04
        stx     $05
        lda     $0420
        beq     render_sprite_load_data
        lda     #$80
        sta     $00
        lda     $1C
        and     #$04
        bne     render_sprite_load_data
        inc     $00
render_sprite_load_data:  ldx     $03
        lda     sprite_count_table,x
        sta     $01
        clc
        lda     $0481,x
        adc     sprite_xvel_sub_table,x
        sta     $0481,x
        lda     $0461,x
        adc     sprite_xvel_table,x
        sta     $0461,x
        sta     $02
        ldx     $05
        ldy     $04
        jsr     write_sprite_to_oam
        inc     $00
        dec     $03
        bpl     render_sprite_layer_loop
        rts

sprite_count_table:  .byte   $07,$0D,$15
sprite_xvel_sub_table:  .byte   $00,$47,$41
sprite_xvel_table:  .byte   $04,$01,$00

; =============================================================================
; Write Sprite to OAM — copy one sprite set to $0200 buffer
; =============================================================================
write_sprite_to_oam:  lda     player_sprite_y_table,x
        sta     $0200,y
        iny
        lda     $00
        sta     $0200,y
        iny
        lda     $0420
        beq     write_oam_attr_byte
        lda     #$40
write_oam_attr_byte:  sta     $0200,y
        iny
        clc
        lda     player_sprite_x_table,x
        adc     $02
        sta     $0200,y
        iny
        inx
        inx
        dec     $01
        bne     write_sprite_to_oam
        rts

; =============================================================================
; Update Projectile Animation — advance frame counter, load sprite data
; =============================================================================
update_projectile_anim:  ldx     $2A
        inc     $0680
        lda     $0680
        cmp     projectile_frame_duration,x
        bcc     projectile_anim_update
        lda     #$00
        sta     $0680
        inc     $06A0
        lda     projectile_anim_max_frame,x
        cmp     $06A0
        bcs     projectile_anim_update
        sta     $06A0
projectile_anim_update:  lda     projectile_anim_base_idx,x
        clc
        adc     $06A0
        tax
        ldy     projectile_frame_index,x
        lda     projectile_sprite_ptr_lo,y
        sta     $08
        lda     projectile_sprite_ptr_hi,y
        sta     $09
        ldy     #$00
        lda     ($08),y
        sta     $00
        iny
        ldx     #$00
projectile_oam_loop:  clc
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
        bne     projectile_oam_loop
        rts

; =============================================================================
; Load Stage Nametable — load CHR data and fill nametable columns
; =============================================================================
load_stage_nametable:  lda     #$00
        jsr     chr_ram_bank_load
        lda     #$20
        sta     $2006
        ldy     #$00
        sty     $2006
        lda     #$AE
        sta     $09
        lda     #$0B
        jsr     ppu_fill_from_ptr
        ldy     #$1F
nametable_fill_loop:  lda     nametable_fill_table,y
        ldx     #$20
nametable_fill_byte:  sta     $2007
        dex
        bne     nametable_fill_byte
        dey
        bpl     nametable_fill_loop
        rts

; =============================================================================
; Clear Projectile Positions — zero out entity sub-pixel positions
; =============================================================================
clear_projectile_positions:  ldx     #$02
        lda     #$00
clear_proj_pos_loop:  sta     $0461,x
        sta     $0481,x
        dex
        bpl     clear_proj_pos_loop
        rts


; =============================================================================
; OAM Buffer Management
; =============================================================================
clear_oam_buffer:  ldx     #$00         ; Fill OAM with $F8 (sprites off-screen)
        lda     #$F8
clear_oam_fill_loop:  sta     $0200,x
        inx
        bne     clear_oam_fill_loop
        rts

; =============================================================================
; Reset Scroll State — zero all scroll/nametable variables
; =============================================================================
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

; =============================================================================
; Stage Palette Data — 32-byte palettes for each stage select screen
; =============================================================================
stage_palette_data:  .byte   $0F,$20,$11,$2C,$0F,$20,$29,$19
        .byte   $0F,$19,$37,$17,$0F,$28,$15,$05
        .byte   $0F,$30,$36,$26,$0F,$0F,$28,$05
        .byte   $0F,$30,$38,$26,$0F,$0F,$36,$26
        .byte   $20,$30,$10,$20,$0F,$30,$20,$10
        .byte   $0F,$10,$20,$10,$0F,$30,$20,$10
        .byte   $20,$30,$20,$10,$0F,$30,$20,$10
        .byte   $0F,$30,$20,$10,$0F,$30,$20,$10

; =============================================================================
; Weapon/Boss Palette Tables — flash colors and per-boss palettes
; =============================================================================
weapon_palette_base:  .byte   $0F,$0F,$0F,$0F,$0F,$0F,$30,$38
stage_palette_per_boss:  .byte   $0F,$0F,$28
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
        bmi     data_852D
        .byte   $0F,$0F
        plp
        ora     $0F,x
        bmi     data_853C
        plp
        .byte   $0F,$0F,$30,$12,$0F,$0F,$30,$15
        .byte   $0F,$0F,$28
        ora     $0F,x
        .byte   $0F,$30
        bmi     data_852D
        .byte   $0F
        bmi     data_8537
weapon_flash_tile_lo:  brk
weapon_flash_tile_hi:  brk
        .byte   $07,$10,$17,$20,$17,$20,$17
        jsr     addr_2017
data_852D:  .byte   $17,$20,$17
        .byte   $20
intro_ppu_addr_hi:  and     ($20,x)
        and     ($20,x)
        .byte   $20
        .byte   $22
data_8537:  .byte   $22
        .byte   $22
intro_ppu_addr_lo:  .byte   $86,$8E,$96
data_853C:  stx     $96
        stx     boss_get_init_ppu

; =============================================================================
; Boss Portrait OAM Data — sprite data for stage select boss icons
; =============================================================================
boss_portrait_oam_data:  and     #$0A
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
        bcs     data_859C
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
        ora     data_B000
        .byte   $5F,$0E,$00,$B8,$5F,$0F,$00,$C0
        .byte   $67
        bpl     data_859C
data_859C:  bcs     boss_oam_size_table
        ora     ($00),y
        clv
        .byte   $67,$12,$00,$C0,$6F,$13,$00,$B7
        .byte   $6F,$14,$00,$BF,$77
        ora     $00,x
        .byte   $B7,$77,$16,$00,$BF,$9F,$1F,$00
        .byte   $38,$A7
        jsr     addr_3800
        .byte   $AF,$21,$00,$3B,$AF,$22,$00,$43
        .byte   $A7,$17,$01,$71,$A7,$18,$00,$79
        .byte   $A7,$19,$02,$81,$AF,$1A,$01,$71
        .byte   $AF,$1B,$00,$79,$AF
data_85DA:  .byte   $1C,$00
data_85DC:  sta     ($B7,x)
        ora     $7900,x
        .byte   $B7,$1E,$00,$81,$9D,$04,$00,$C0
        .byte   $A5
data_85EA:  ora     $00
data_85EC:  cpy     #$AD
        brk
        .byte   $00
        ldx     $AD,y
        ora     ($00,x)
        ldx     $02B5,y
        brk
        .byte   $B6,$B5,$03,$00,$BE

; =============================================================================
; Boss OAM Layout Tables — offsets, sizes, collision boxes
; =============================================================================
boss_oam_offset_table:  .byte   $3C,$0C,$4C
        brk
        jsr     addr_7484
        .byte   $A4
boss_oam_size_table:  bpl     data_861B
        plp
        .byte   $0C,$1C,$20,$10,$18
collision_box_table:  .byte   $F8,$2F,$00,$F9,$F8,$2F,$00,$1F
        .byte   $1E,$2F,$00,$F9,$1E,$2F
data_861B:  .byte   $00,$1F
collision_x_offset_table:  .byte   $60,$20,$20,$20,$60
        ldy     #$A0
        ldy     #$60
collision_y_offset_table:  bvs     data_8658
        bvs     data_85DA
        bcs     data_85DC
        bvs     data_865E
        bmi     data_8690
        jsr     addr_2060
        jsr     ending_column_skip
        ldy     #$30
        bvs     data_85EA
        bmi     data_85EC
        bvs     data_866E
        .byte   $B0

; =============================================================================
; Nametable Fill Table — tile pattern for stage select background
; =============================================================================
nametable_fill_table:  brk
        brk
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$2D,$20,$20,$20
        .byte   $20,$20,$20,$2C,$00,$00,$00
data_8658:  .byte   $00,$00,$00,$00,$00,$00
data_865E:  brk

; =============================================================================
; Stage Select Index/Entity Tables — mapping and entity data per boss
; =============================================================================
stage_select_index_table:  php
        .byte   $03,$01,$04,$02,$07,$05,$06,$00
        .byte   $00,$08,$02,$10,$04,$20
data_866E:  .byte   $80,$40,$01
stage_entity_x_table:  tya
        sta     boss_get_palette_data_2,y
        .byte   $9C,$9D,$AB,$AC,$AD,$AA,$AB,$AC
        .byte   $AC,$AD,$AE,$AF,$B0,$B1,$98,$99
        .byte   $9A,$9B,$9C,$9D,$90,$91,$92,$93
        .byte   $94
        sta     $9E,x
data_8690:  .byte   $9F,$96,$97,$9E,$9F,$B0,$B1,$B2
        .byte   $B3,$AA,$AB,$AE,$AF,$B0,$B1,$B2
        .byte   $B3
stage_entity_bank_table:  .byte   $06,$06,$06,$06,$06,$06,$05,$05
        .byte   $05,$06,$06,$06
        asl     zp_temp_06
        asl     zp_temp_06
        asl     zp_temp_06
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$06,$06,$07,$07
        .byte   $07,$07,$03,$03,$03,$03,$05,$05
        .byte   $05,$05,$05,$05,$05,$05
boss_bitmask_table:  .byte   $01,$02,$04,$08
        bpl     data_86F7
        rti

        .byte   $80
intro_health_tile_data:  jsr     addr_0508
        ora     ($14,x)
        .byte   $0D
        .byte   $01
data_86E0:  asl     addr_2020
        jsr     $0120
        ora     #$12
        ora     $0E01
        jsr     addr_2020
        .byte   $17,$0F,$0F,$04,$0D,$01,$0E,$20
        .byte   $20
data_86F7:  .byte   $02,$15,$02,$02,$0C
data_86FC:  ora     $0D
        ora     ($0E,x)
        jsr     addr_1120
        ora     $09,x
        .byte   $03
        .byte   $0B,$0D,$01,$0E,$20,$20,$06,$0C
        .byte   $01,$13,$08,$0D,$01,$0E
        jsr     addr_0D20
        ora     $14
        ora     ($0C,x)
        ora     $0E01
        jsr     addr_0320
        .byte   $12,$01,$13,$08,$0D,$01,$0E,$20

; =============================================================================
; Player Sprite Layout Tables — Y/X positions for intro sprites
; =============================================================================
player_sprite_y_table:  .byte   $10
player_sprite_x_table:  .byte   $18,$10,$80,$10,$D0,$14,$40
data_8731:  clc
        bcc     data_875C
        sei
        bmi     data_8757
        bmi     data_8731
        sec
        bcs     data_877C
        inx
        tya
        bcc     data_86E0
        rti

        .byte   $A0,$E8,$B0,$90,$B8,$68,$C0,$18
        .byte   $C8,$70,$C8,$C0,$D0,$D8,$D8,$60
        .byte   $D8,$C8,$18,$50,$08,$50
data_8757:  clc
        sed
        jsr     addr_2008
data_875C:  tay
        bmi     data_879F
        sec
        bne     data_87AA
        bvc     data_86FC
        clv
        tay
        sei
        bcs     data_8769
data_8769:  clv
        plp
        cpy     #$C8
        bne     data_878F
        cpx     #$88
        bit     $D0
        .byte   $34,$88,$3C,$30,$9C,$20,$A4,$D0
        .byte   $B4
data_877C:  .byte   $58,$D4,$E8,$D4,$A0

; =============================================================================
; Projectile Animation Tables — base index, max frame, duration
; =============================================================================
projectile_anim_base_idx:  .byte   $00,$18,$29,$32,$37,$41,$49,$4F
projectile_anim_max_frame:  .byte   $17,$10,$08,$04,$09,$07
data_878F:  ora     $04
projectile_frame_duration:  .byte   $02,$03,$08
        php
        ora     zp_temp_06
        php
        php
projectile_frame_index:  .byte   $03,$02,$02,$01,$01,$00
data_879F:  .byte   $27,$28,$27,$28,$27,$28,$27,$28
        .byte   $27,$28,$27
data_87AA:  .byte   $28,$27,$28,$27,$28,$27,$00,$1E
        .byte   $1B,$1B,$1C,$1D,$1C,$1D,$1C,$1D
        .byte   $1B,$1C,$1D,$1C,$1D,$1C,$1D,$1B
        .byte   $26,$23,$24,$25,$24,$25,$24,$25
        .byte   $23,$04,$04,$04
        ora     zp_temp_06
        .byte   $0F,$07,$08,$09,$0A,$0B,$0C,$0D
        .byte   $0E,$09,$16,$10,$11,$12,$13,$14
        .byte   $15,$12,$1A,$17,$17,$17,$18,$19
        .byte   $22,$1F,$1F,$20,$21

; =============================================================================
; Projectile Sprite Pointer Tables — lo/hi address for each frame
; =============================================================================
projectile_sprite_ptr_lo:  .byte   $3F,$78,$A9,$D2,$FF,$28,$59,$8A
        .byte   $BB,$EC,$1D,$4E,$83,$B8
        sbc     $4F1E
        sty     $BD
        .byte   $F2,$27,$5C,$91,$CA,$EF,$1C,$41
        .byte   $6A,$AF
        sed
        eor     ($8E,x)
        .byte   $BB,$F0,$25,$5E,$9F,$DC,$1D,$62
        .byte   $A7
projectile_sprite_ptr_hi:  dey
        dey
        dey
        dey
        dey
        .byte   $89,$89,$89,$89,$89,$8A,$8A,$8A
        .byte   $8A,$8A,$8B,$8B,$8B,$8B,$8B,$8C
        .byte   $8C,$8C,$8C,$8C,$8D,$8D

; =============================================================================
; Sprite Definition Data — raw OAM data for projectile/weapon sprites
; =============================================================================
sprite_def_data_8831:  sta     sprite_def_data_8D8D
        stx     sprite_def_data_8E8E
        stx     sprite_def_data_8F8F
        .byte   $8F,$8F,$90,$90,$90,$0E
        cpx     #$A0
        .byte   $03,$FA,$E8
        lda     ($03,x)
        beq     sprite_def_data_8831
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
sprite_def_data_88EE:  .byte   $F4,$F0,$E3,$03,$FC,$F0,$E4,$03
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
        beq     sprite_def_data_88EE
        .byte   $03,$F0,$F0,$B0,$03,$F8,$F0
        lda     ($03),y
        brk
        .byte   $F8
sprite_def_data_894A:  .byte   $B2,$03,$F0,$F8,$B3,$03,$F8,$F8
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
        beq     sprite_def_data_894A
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
sprite_def_data_8ABD:  inx
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
        beq     sprite_def_data_8ABD
        .byte   $03,$04,$F8,$B2,$03,$EC,$F8,$B3
        .byte   $03,$F4,$F8,$B4,$03,$FC,$F8,$B5
        .byte   $03,$04,$0C,$E0
        ldy     #$03
        .byte   $F3,$E0,$A1,$03,$03,$E8,$F5,$03
        .byte   $F2,$E8,$F6,$03,$FA,$E8,$F7,$03
        .byte   $02,$EC,$BF,$01
sprite_def_data_8B36:  .byte   $FB,$F0,$F8,$03,$F4
        beq     sprite_def_data_8B36
        .byte   $03,$FC,$F0,$FA,$03,$04,$F8,$FB
        .byte   $03,$F4,$F8,$FC,$03,$FC,$00,$FD
        .byte   $03,$FD,$0D,$E0,$A0,$03,$FC
sprite_def_data_8B54:  inx
        lda     ($03,x)
        inc     $E8,x
        ldx     #$03
        inc     password_dot_data,x
        .byte   $03,$06,$EB,$F4,$01,$FB,$F0,$A4
        .byte   $03,$F0,$F0,$A5,$03,$F8,$F0,$A6
        .byte   $03,$00,$F0,$A7,$03,$08,$F8,$A8
        .byte   $03,$F0,$F8,$A9,$03,$F8,$F8,$AA
        .byte   $03,$00,$F8,$AB,$03,$08,$0E,$E0
        .byte   $AC,$03,$F1,$E0
        ldy     #$03
        inc     credits_text_data_2,x
        .byte   $03,$F0,$E8,$AE,$03,$F8,$E8,$AF
        .byte   $03,$00,$E8
        bcs     sprite_def_data_8B9F
        php
        .byte   $EB,$F4
sprite_def_data_8B9F:  ora     ($FD,x)
        beq     sprite_def_data_8B54
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
sprite_def_data_8C7E:  .byte   $BF,$02,$08
        sed
        cpy     #$02
        beq     sprite_def_data_8C7E
sprite_def_data_8C86:  iny
        .byte   $02,$F8,$F8,$C9,$03,$00,$F8,$C3
        .byte   $02
        php
        asl     boss_sprite_data_ACE0
        .byte   $03,$F1,$E0,$A0,$03,$FE,$E8,$AD
        .byte   $03,$F0,$E8,$AE,$03,$F8,$E8,$AF
        .byte   $03,$00,$E8,$B0,$03,$08,$EB,$F4
        ora     ($FD,x)
sprite_def_data_8CAE:  beq     sprite_def_data_8C86
        .byte   $03,$F8,$F0,$D7,$03,$00,$F0,$D8
sprite_def_data_8CB8:  .byte   $03,$08,$F8,$D9,$03,$F8,$F8,$DA
        .byte   $03,$00,$00,$DB,$03,$F8,$00,$DC
        .byte   $03,$00,$09,$E8,$A1,$03,$F8,$E8
        .byte   $A2,$03,$00,$E9,$A0,$01,$F9,$F0
        .byte   $A3,$03,$F4,$F0,$A4,$03,$FC,$F0
        .byte   $A5,$03,$04,$F8,$A6,$03,$F4,$F8
        .byte   $A7,$03,$FC,$F8,$A8,$03,$04,$0B
        .byte   $E8,$A9,$03,$F4,$E8,$AA,$03,$FC
        .byte   $E8,$AB,$03,$04,$EA,$A0,$01,$F6
        beq     sprite_def_data_8CAE
        .byte   $03
        sbc     ($F0),y
        lda     $F903
        beq     sprite_def_data_8CB8
        .byte   $03
        ora     ($F8,x)
        .byte   $AF,$03,$EC
        sed
        bcs     sprite_def_data_8D16
        .byte   $F4,$F8,$B1
sprite_def_data_8D16:  .byte   $03,$FC,$F8,$B2,$03,$04,$09,$E8
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
sprite_def_data_8D8D:  .byte   $03,$F0,$F0,$A9,$03,$F8,$F0,$AA
        .byte   $03,$00,$F0
sprite_def_data_8D98:  .byte   $AB,$03,$08,$F8,$AC,$03
        beq     sprite_def_data_8D98
        lda     $F803
        sed
        ldx     a:$03
        sed
        .byte   $AF,$03,$08,$E2,$DE
sprite_def_data_8DAD:  ora     ($FB,x)
        .byte   $12
        cpx     #$B0
        .byte   $03,$F6,$E0,$B1,$03,$FE,$E0,$B2
        .byte   $03,$06,$E0,$B3,$03,$0E
        inx
        ldy     $03,x
        beq     sprite_def_data_8DAD
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
        inc     password_blink_check,x
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
        inc     password_blink_check,x
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
sprite_def_data_8E81:  ora     $00
        cpy     $F503
        brk
        .byte   $CD,$03,$05,$E4
        dec     $FB01,x
sprite_def_data_8E8E:  .byte   $0B,$E8,$A0,$03,$F8,$E8,$A1,$03
        .byte   $00,$F0,$A2,$03,$F0,$F0,$A3,$03
        .byte   $F8,$F0,$A4,$03,$00,$F0
sprite_def_data_8EA4:  lda     $03
        php
        sed
        ldx     $03
        beq     sprite_def_data_8EA4
        .byte   $A7,$03,$F8,$F8,$A8,$03,$00,$F8
        .byte   $A9,$03,$08,$ED,$F3,$01,$FA,$0D
        .byte   $E0
sprite_def_data_8EBD:  .byte   $AA,$03,$F0,$E0,$AB,$03,$F8,$E8
        ldy     $F003
        inx
        lda     $F803
        inx
        ldx     a:$03
        beq     sprite_def_data_8E81
        .byte   $03,$F0,$F0,$B0,$03,$F8,$F0
        lda     ($03),y
        brk
        .byte   $F8,$B2
sprite_def_data_8EDE:  .byte   $03,$F0,$F8,$B3,$03,$F8,$F8,$B4
        .byte   $03,$00,$F8,$B5,$03,$08,$ED,$F3
        .byte   $01,$F9,$0D,$E8
sprite_def_data_8EF2:  ldx     $03,y
        beq     sprite_def_data_8EDE
        .byte   $B7,$03,$F8,$E8,$B8,$03,$00,$E8
        .byte   $B9,$03,$08
        beq     sprite_def_data_8EBD
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
        beq     sprite_def_data_8EF2
        .byte   $03,$EE,$F0,$BB,$03,$F6,$F0,$BC
        .byte   $03,$FE,$F0,$BD,$03,$06,$F8,$C2
        .byte   $03,$F8,$F8,$C3,$03,$00,$F8,$C4
        .byte   $03,$08,$00,$C5,$03,$F8,$00,$C6
        .byte   $03,$00,$ED,$F3,$01,$FB,$10,$E0
        .byte   $A0,$03,$F8,$E0,$A1,$03,$00,$E0
        .byte   $A2,$03,$08,$E8,$A3,$03,$F0,$E8
        ldy     $03
        sed
sprite_def_data_8F73:  inx
        lda     $03
        brk
        .byte   $E8,$A6,$03,$08,$F0,$A7,$03,$F0
        .byte   $F0,$A8,$03,$F8,$F0,$A9,$03,$00
        .byte   $F0,$AA,$03,$08,$F8,$AB,$03,$F0
sprite_def_data_8F8F:  sed
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
        beq     sprite_def_data_8F73
        .byte   $03,$F5,$F0,$B6,$03,$FD,$F0
sprite_def_data_8FC5:  .byte   $B7,$03,$05,$F8,$B8,$03,$F0,$F8
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
        beq     sprite_def_data_8FC5
        .byte   $03,$00,$F0
sprite_def_data_9006:  .byte   $C3,$03
        php
        sed
        clv
        .byte   $03
        beq     sprite_def_data_9006
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
sprite_def_data_9034:  .byte   $03
        brk
        .byte   $E8,$CF,$03,$08,$F0,$D0,$03,$F0
        .byte   $F0,$D1,$03,$F8,$F0,$D2,$03,$00
        .byte   $F0
sprite_def_data_9047:  .byte   $D3
sprite_def_data_9048:  .byte   $03,$08,$F8,$D4,$03
        beq     sprite_def_data_9047
        cmp     $03,x
        sed
        sed
        cmp     $03,x
sprite_def_data_9055:  brk
        .byte   $F8,$D6,$03,$08,$E7,$F4,$02,$FA
        .byte   $E0,$CB
sprite_def_data_9060:  .byte   $03,$F0,$11,$E0,$C1,$03
        beq     sprite_def_data_9048
        .byte   $C2,$03,$F8,$E0,$C3,$03,$00,$E0
        .byte   $C4,$03,$08,$E8
        cmp     $03
        beq     sprite_def_data_9060
        ldx     #$03
        sed
        inx
        dec     $03
        brk
        .byte   $E8,$C7,$03,$08,$F0,$C8,$03,$F0
        .byte   $F0
        ldx     $03
        sed
        beq     sprite_def_data_9034
        .byte   $03,$00,$F0
        cmp     #$03
        php
        .byte   $F0
sprite_def_data_9094:  cpy     #$01
        .byte   $FA
        sed
        dex
        .byte   $03
        beq     sprite_def_data_9094
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
main_stage_render:
        jsr     clear_oam_buffer_fixed
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

; =============================================================================
; Weapon Select Screen — save state, calculate scroll, draw columns
; =============================================================================
wselect_save_palette_loop:  lda     $0354,x
        sta     $0700,x
        dex
        bpl     wselect_save_palette_loop
        lda     #$00
        sta     $B8
        sta     $B7
        sta     $B5
        sta     $B6
        lda     $2A
        cmp     #$04
        bne     wselect_check_boss_stage
        lda     $38
        cmp     #$03
        bcc     wselect_check_boss_stage
        cmp     #$0F
        bcs     wselect_check_boss_stage
        cmp     #$07
        beq     wselect_check_boss_stage
        ldx     #$0F
        txa
wselect_clear_palette_loop:  sta     $0356,x
        dex
        bpl     wselect_clear_palette_loop
        inc     $20

; =============================================================================
; Weapon Select — Boss Stage Palette Override
; =============================================================================
wselect_check_boss_stage:  lda     $B1
        beq     wselect_check_wily_10
        lda     $B3
        cmp     #$08
        bcc     wselect_check_wily_10
        ldx     #$00
        stx     $1F
        cmp     #$0A
        beq     wselect_check_wily_10
        cmp     #$0B
        beq     wselect_check_wily_10
        inc     $20
wselect_check_wily_10:  lda     #$0A
        cmp     $2A
        bne     wselect_calc_scroll_pos
        lda     $B1
        beq     wselect_calc_scroll_pos
        lda     #$0F
        ldx     #$02
wselect_wily10_palette_loop:  sta     $035B,x
        sta     $037B,x
        sta     $038B,x
        sta     $039B,x
        dex
        bpl     wselect_wily10_palette_loop

; =============================================================================
; Weapon Select — Calculate Scroll Position and Render Columns
; =============================================================================
wselect_calc_scroll_pos:  clc
        lda     $1F
        adc     #$80
        and     #$E0
        ora     #$04
        sta     $52
        lda     $20
        adc     #$00
        sta     $53
        ldx     #$00
wselect_column_loop:  stx     $FD
        clc
        lda     $52
        adc     wselect_column_offset,x
        sta     $08
        lda     $53
        adc     #$00
        sta     $09
        lda     #$00
        sta     $1B
        jsr     attr_table_write
        ldx     $FD
        lda     wselect_column_type,x
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
wselect_copy_tiles:  lda     wselect_tile_data,x
        sta     $0310,y
        inx
        iny
        cpy     #$10
        bne     wselect_copy_tiles
        ldx     $2A
        lda     wselect_attr_per_stage,x
        sta     $0350
        lda     #$01
        sta     $1B
        ldy     #$99
        ldx     #$00
        jsr     metatile_render_column
        jsr     wait_for_vblank_0D
        ldx     $FD
        inx
        cpx     #$0F
        bne     wselect_column_loop
        stx     $FD
        ldy     #$99
        ldx     #$00
        jsr     metatile_render_column
        lda     #$00
        sta     $FE
        sta     $FF
        ldx     $A9
        inx
        cpx     #$07
        bcc     wselect_set_weapon_index
        txa
        sbc     #$06
        tax
        inc     $FE
wselect_set_weapon_index:  stx     $FD

; =============================================================================
; Weapon Select — Input Loop (D-pad / Start / weapon switching)
; =============================================================================
wselect_input_loop:  lda     $9A
        asl     a
        ora     #$41
        sta     $07
        lda     $FE
        beq     wselect_check_start
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
wselect_check_start:  lda     $27
        and     #$08                    ; Start button pressed?
        beq     wselect_check_dpad
        jmp     wselect_start_pressed

wselect_check_dpad:  lda     $27
        and     #$30                    ; D-pad up/down new press?
        bne     wselect_dpad_pressed
        lda     $23
        and     #$30                    ; D-pad up/down new press?
        beq     wselect_clear_repeat
        sta     $00
        lda     $25
        and     #$30                    ; D-pad up/down new press?
        cmp     $00
        bne     wselect_clear_repeat
        inc     $FF
        lda     $FF
        cmp     #$18                    ; Auto-repeat delay (24 frames)
        bcc     wselect_update_and_vblank
        lda     #$08
        sta     $FF
wselect_dpad_pressed:  ldx     #$07
        lda     $FE
        beq     wselect_sound_and_move
        dex
wselect_sound_and_move:  lda     #$2F
        jsr     bank_switch_enqueue
        lda     $23
        and     #$30
        and     #$10
        bne     wselect_move_left
wselect_move_right:  inc     $FD        ; Move cursor right
        cpx     $FD
        bcs     wselect_check_valid
        lda     #$00
        sta     $FD
wselect_check_valid:  ldy     $FD
        beq     wselect_update_and_vblank
        lda     weapon_bitmask_table,y
        and     $07
        beq     wselect_move_right
        bne     wselect_update_and_vblank
wselect_move_left:  dec     $FD         ; Move cursor left
        bpl     wselect_check_valid_left
        stx     $FD
wselect_check_valid_left:  ldy     $FD
        beq     wselect_update_and_vblank
        lda     weapon_bitmask_table,y
        and     $07
        beq     wselect_move_left
        bne     wselect_update_and_vblank
wselect_clear_repeat:  lda     #$00
        sta     $FF
wselect_update_and_vblank:  jsr     wselect_render_oam
        jsr     wait_for_vblank_0D
        jmp     wselect_input_loop

; =============================================================================
; Weapon Select — Start Pressed (toggle page or select weapon)
; =============================================================================
wselect_start_pressed:  lda     $FD
        bne     wselect_check_etank
        lda     $FE
        eor     #$01
        sta     $FE
        jmp     wselect_clear_repeat

wselect_check_etank:  cmp     #$07
        bne     wselect_weapon_selected
        lda     $A7
        beq     wselect_clear_repeat
        dec     $A7
wselect_etank_fill_loop:  lda     $06C0
        cmp     #$1C                    ; Full health = 28 units
        beq     wselect_clear_repeat
        lda     $1C
        and     #$03
        bne     wselect_etank_frame
        inc     $06C0
        lda     #$28
        jsr     bank_switch_enqueue
wselect_etank_frame:  jsr     wselect_render_oam
        jsr     wait_for_vblank_0D
        jmp     wselect_etank_fill_loop

; =============================================================================
; Weapon Select — Weapon Selected (store weapon, re-render columns)
; =============================================================================
wselect_weapon_selected:  lda     $FD
        beq     wselect_clear_repeat
        cmp     #$07                    ; E-Tank slot?
        beq     wselect_clear_repeat
        tax
        dex
        lda     $FE
        beq     wselect_store_weapon
        clc
        txa
        adc     #$06
        tax
wselect_store_weapon:  stx     $A9
        jsr     clear_oam_buffer_fixed
        lda     $1A
        pha
        ldx     #$00
wselect_render_column:  stx     $FD
        clc
        lda     $52
        adc     wselect_column_offset,x
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
        jsr     metatile_column_render
        lda     $FD
        cmp     #$08
        bcs     wselect_render_default_col
        ldx     $A9
        lda     wselect_weapon_pal_idx,x
        tay
        cpx     #$09
        bcc     wselect_render_weapon_col
        ldx     #$00
        beq     wselect_render_col_call
wselect_render_weapon_col:  ldx     #$05
        bne     wselect_render_col_call
wselect_render_default_col:  ldy     #$90
        ldx     #$00
wselect_render_col_call:  jsr     metatile_render_column
        jsr     wait_for_vblank_0D
        ldx     $FD
        inx
        cpx     #$0F
        bne     wselect_render_column
        stx     $FD
        ldy     #$90
        ldx     #$00
        jsr     metatile_render_column
        jsr     fixed_D2ED
        jsr     wait_for_vblank_0D
        pla
        sta     $1A
        lda     $2A
        cmp     #$0A
        bne     wselect_restore_palette
        lda     $B1
        beq     wselect_restore_palette
        ldx     #$02
wselect_wily10_restore:  lda     wselect_wily10_pal_data,x
        sta     $035B,x
        sta     $037B,x
        sta     $038B,x
        sta     $039B,x
        dex
        bpl     wselect_wily10_restore
wselect_restore_palette:  ldx     #$11
wselect_restore_pal_loop:  lda     $0700,x
        sta     $0354,x
        dex
        bpl     wselect_restore_pal_loop
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

wselect_wily10_pal_data:  .byte   $27,$11,$16

; =============================================================================
; Weapon Select — Render OAM (header, boss icons, HP bars, cursor)
; =============================================================================
wselect_render_oam:  jsr     clear_oam_buffer_fixed
        lda     $52
        and     #$E0
        sec
        sbc     $1F
        sta     $08
        ldy     #$00
wselect_load_header_oam:  lda     wselect_header_oam,y
        sta     $0200,y
        iny
        cpy     #$14
        bne     wselect_load_header_oam
        lda     $9A
        asl     a
        ora     #$01
        sta     $07
        lda     #$05
        sta     $01
        ldx     #$00
        lda     $FE
        beq     wselect_build_boss_icons
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
wselect_build_boss_icons:  lda     $07
        sta     $02
        lda     #$44
        sta     $00
wselect_icon_oam_entry:  sta     $0200,y
        lsr     $02
        bcs     wselect_icon_tile
        lda     #$F8
        sta     $0200,y
wselect_icon_tile:  lda     wselect_icon_tile_ids,x
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
        bpl     wselect_icon_oam_entry
        lda     $FE
        bne     wselect_page2_labels
        ldx     #$00
wselect_load_labels_p1:  lda     wselect_label_oam_data,x
        sta     $0200,y
        iny
        inx
        cpx     #$04
        bne     wselect_load_labels_p1
        sty     $00
        lda     #$44
        sta     $02
        lda     $06C0
        jsr     hp_bar_draw_start
        lda     $07
        lsr     a
        sta     $04
        ldx     #$00
        lda     #$54
wselect_draw_hp_bar_p1:  stx     $03
        sta     $02
        lsr     $04
        bcc     wselect_hp_bar_next_p1
        jsr     hp_bar_draw_weapon
wselect_hp_bar_next_p1:  clc
        lda     $02
        adc     #$10
        ldx     $03
        inx
        cpx     #$05
        bne     wselect_draw_hp_bar_p1
        ldy     $00
        lda     $A7
        beq     wselect_jump_to_cursor
        sta     $02
        lda     #$1C
wselect_draw_etank_loop:  sta     $01
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
        bne     wselect_draw_etank_loop
wselect_jump_to_cursor:  jmp     wselect_cursor_blink

wselect_page2_labels:  ldx     #$04
wselect_load_labels_p2:  lda     wselect_label_oam_data,x
        sta     $0200,y
        iny
        inx
        cpx     #$18
        bne     wselect_load_labels_p2
        sty     $00
        lda     $07
        sta     $04
        ldx     #$05
        lda     #$44
wselect_draw_hp_bar_p2:  stx     $03
        sta     $02
        lsr     $04
        bcc     wselect_hp_bar_next_p2
        jsr     hp_bar_draw_weapon
wselect_hp_bar_next_p2:  clc
        lda     $02
        adc     #$10
        ldx     $03
        inx
        cpx     #$0B
        bne     wselect_draw_hp_bar_p2
        lda     $A8
        sta     $01
        dec     $01
        lda     #$0A
        sta     $02
        jsr     divide_8bit
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
wselect_cursor_blink:  ldy     #$00
        lda     $1C
        and     #$08                    ; Blink every 8 frames
        bne     wselect_cursor_offset
        ldy     #$20
wselect_cursor_offset:  sty     $00
        ldx     $FD
        bne     wselect_cursor_not_first
        lda     $00
        beq     wselect_adjust_positions
        lda     #$F8
        sta     $0200
        jmp     wselect_adjust_positions

wselect_cursor_not_first:  dex
        txa
        asl     a
        asl     a
        tay
        lda     $00
        beq     wselect_adjust_positions
        lda     #$F8
        sta     $0214,y
wselect_adjust_positions:  ldx     #$00
wselect_adjust_x_loop:  clc
        lda     $0203,x
        adc     $08
        sta     $0203,x
        inx
        inx
        inx
        inx
        bne     wselect_adjust_x_loop
        rts

        .byte   $2C,$3C,$4C,$5C,$6C,$7C,$8C,$9C
        .byte   $3C,$4C,$5C,$6C,$7C,$8C,$9C,$AC

; =============================================================================
; HP Bar Drawing — render weapon energy bar to OAM
; =============================================================================
hp_bar_draw_weapon:  lda     $9C,x
hp_bar_draw_start:  sta     $01
        ldx     #$06
hp_bar_draw_entry:  lda     $02
        sta     $0200,y
        sec
        lda     $01
        sbc     #$04
        bcs     hp_bar_store_remaining
        ldy     $01
        lda     #$00
        sta     $01
        lda     hp_bar_empty_tiles,y
        ldy     $00
        jmp     hp_bar_write_oam

hp_bar_store_remaining:  sta     $01
        lda     #$90
hp_bar_write_oam:  sta     $0201,y
        lda     #$01
        sta     $0202,y
        lda     hp_bar_x_positions,x
        sta     $0203,y
        iny
        iny
        iny
        iny
        sty     $00
        dex
        bpl     hp_bar_draw_entry
        rts

hp_bar_x_positions:  .byte   $4C,$44,$3C,$34,$2C,$24,$1C
hp_bar_empty_tiles:  sty     $93,x
        .byte   $92,$91

; =============================================================================
; Weapon Select Layout Tables — column types, offsets, tile data
; =============================================================================
wselect_column_type:  .byte   $00,$01,$02,$03,$04,$05,$03,$04
        .byte   $05,$03,$04,$05,$06,$07,$08
wselect_column_offset:  .byte   $00,$20,$40,$04,$24,$44,$08,$28
        .byte   $48,$0C,$2C,$4C,$10,$30,$50
wselect_tile_data:  .byte   $40,$40,$40,$40,$40,$41,$41,$41
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
wselect_attr_per_stage:  .byte   $00,$55,$AA,$00,$AA,$00,$00,$00
        .byte   $00,$00,$55,$AA,$00,$00

; =============================================================================
; Weapon Select OAM Data — header, icon tiles, label OAM
; =============================================================================
wselect_header_oam:  .byte   $34,$11,$01,$0C,$34,$95,$01,$1C
        .byte   $34,$96,$01,$24,$34,$97,$01,$2C
        .byte   $34,$98,$01,$34
wselect_icon_tile_ids:  .byte   $1F,$9F,$9B,$99,$9D,$9C,$9A,$9E
        .byte   $10,$15,$16,$17
wselect_label_oam_data:  ldy     $96
        ora     ($0C,x)
        ldy     #$8D
        brk
        .byte   $18,$A0,$8D,$40,$20,$A8,$8E,$01
        .byte   $18,$A8,$8E,$41
        jsr     addr_1EA4
        ora     ($2C,x)
wselect_weapon_pal_idx:  tya
        txs
        sta     boss_get_bounce_check,y
        tya
        txs
        tya
        .byte   $9B,$9B,$9B,$9B
weapon_bitmask_table:  .byte   $00,$01,$02,$04,$08,$10,$20,$40
boss_get_screen_init:
        lda     #$10
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001

; =============================================================================
; Boss Get Screen — PPU init, nametable fill, palette setup
; =============================================================================
boss_get_init_ppu:  lda     #$0F
        jsr     banked_entry
        jsr     reset_scroll_state
        lda     #$01
        jsr     chr_ram_bank_load
        lda     #$20
        sta     $2006
        ldy     #$00
        sty     $2006
boss_get_fill_nt_loop:  lda     wily_nametable_fill_tiles,y
        ldx     #$40
boss_get_fill_tile:  sta     $2007
        dex
        bne     boss_get_fill_tile
        iny
        cpy     #$10
        bne     boss_get_fill_nt_loop
        lda     #$28
        sta     $2006
        ldy     #$00
        sty     $2006
        lda     #$AC
        sta     $09
        lda     #$03
        jsr     ppu_fill_from_ptr
        ldx     #$1F
boss_get_load_palette:  lda     boss_get_palette_data,x
        sta     $0356,x
        dex
        bpl     boss_get_load_palette
        jsr     clear_oam_buffer
        lda     $2A
        cmp     #$09
        bcc     boss_get_normal_init
        jsr     wily_intro_palette_clear
        jmp     boss_get_flash_palette

; =============================================================================
; Boss Get — Normal Init (walk-in, idle, jump, shimmer, land)
; =============================================================================
boss_get_normal_init:  lda     #$12
        jsr     bank_switch_enqueue
        jsr     enable_nmi_and_rendering
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

; =============================================================================
; Boss Get — Walk-In Loop (both entities walk toward center)
; =============================================================================
boss_get_walk_loop:  clc
        lda     $0480
        adc     #$40                    ; Walk sub-pixel increment
        sta     $0480
        lda     $0460
        adc     #$01
        sta     $0460
        sta     $0461
        lda     $0440
        adc     #$00
        sta     $0440
        sta     $0441
        bne     boss_get_walk_frame
        lda     $0460
        cmp     #$68                    ; Reached center X=$68?
        bcs     boss_get_walk_stop
boss_get_walk_frame:  jsr     update_animation_frame
        jsr     clear_oam_buffer
        ldx     #$00
        stx     $00
        jsr     entity_update_handler
        ldx     #$01
        jsr     entity_update_handler
        jsr     wait_for_vblank_0D
        jmp     boss_get_walk_loop

boss_get_walk_stop:  jsr     clear_oam_buffer
        ldx     #$00
        stx     $00
        jsr     entity_update_handler
        ldx     #$01
        jsr     entity_update_handler
        lda     #$3E
        sta     $FD

; =============================================================================
; Boss Get — Idle Loop (wait before jump)
; =============================================================================
boss_get_idle_loop:  jsr     update_animation_frame
        ldx     #$00
        stx     $00
        jsr     entity_update_handler
        ldx     #$01
        jsr     entity_update_handler
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     boss_get_idle_loop
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

; =============================================================================
; Boss Get — Jump Up Loop (player rises with weapon shimmer)
; =============================================================================
boss_get_jump_up_loop:  sec
        lda     $04C0
        sbc     #$80                    ; Rise velocity sub-pixel
        sta     $04C0
        lda     $04A0
        sbc     #$00
        sta     $04A0
        jsr     update_animation_frame
        jsr     update_all_entities
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     boss_get_jump_up_loop
        lda     #$FA
        sta     $FD

; =============================================================================
; Boss Get — Shimmer Loop (weapon color cycling)
; =============================================================================
boss_get_shimmer_loop:  inc     $0682
        lda     $0682
        cmp     #$08                    ; Shimmer frame duration
        bcc     boss_get_shimmer_frame
        lda     #$00
        sta     $0682
        inc     $0402
        lda     $0402
        cmp     #$06                    ; Shimmer anim frame count
        bcc     boss_get_shimmer_frame
        lda     #$04
        sta     $0402
boss_get_shimmer_frame:  jsr     update_animation_frame
        jsr     update_all_entities
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     boss_get_shimmer_loop
        lda     #$50
        sta     $FD

; =============================================================================
; Boss Get — Land Loop (player descends back to ground)
; =============================================================================
boss_get_land_loop:  clc
        lda     $04C0
        adc     #$80                    ; Descend velocity sub-pixel
        sta     $04C0
        lda     $04A0
        adc     #$00
        sta     $04A0
        jsr     update_animation_frame
        jsr     update_all_entities
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     boss_get_land_loop
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

; =============================================================================
; Boss Get — Bounce Main (weapon orb bouncing physics)
; =============================================================================
boss_get_bounce_main:  lda     $06A0
        bne     boss_get_bounce_up_entry
        ldx     #$00
        lda     $0460
        cmp     #$68                    ; Center Y position check
        bcs     boss_get_bounce_down
        inx
boss_get_bounce_down:  clc
        lda     $0620
        adc     bounce_accel_sub,x
        sta     $0620
        lda     $0600
        adc     bounce_accel_whole,x
        sta     $0600
        sec
        lda     $0480
        sbc     $0620
        sta     $0480
        lda     $0460
        sbc     $0600
        sta     $0460
        cmp     #$18
        bcs     boss_get_bounce_render
        bcc     boss_get_bounce_reverse
boss_get_bounce_up_entry:  ldx     #$00
        lda     $0460
        cmp     #$68
        bcc     boss_get_bounce_up
        inx
boss_get_bounce_up:  clc
        lda     $0620
        adc     bounce_accel_sub,x
        sta     $0620
        lda     $0600
        adc     bounce_accel_whole,x
        sta     $0600
        clc
        lda     $0480
        adc     $0620
        sta     $0480
        lda     $0460
        adc     $0600
        sta     $0460
        cmp     #$68
        bcc     boss_get_bounce_render
        ldx     $FD
        lda     bounce_entity_type,x
        sta     $0400
        lda     $0460
        cmp     #$B8
boss_get_bounce_check:  bcc     boss_get_bounce_render
boss_get_bounce_reverse:  lda     #$00
        sta     $0600
        sta     $0620
        lda     $06A0
        php
        eor     #$01                    ; Toggle bounce direction
        sta     $06A0
        plp
        beq     boss_get_bounce_render
        inc     $FD
        lda     $FD
        cmp     #$03
        bne     boss_get_bounce_render
        lda     #$11
        jsr     bank_switch_enqueue
boss_get_bounce_render:  jsr     clear_oam_buffer
        ldx     #$00
        stx     $00
        jsr     entity_update_handler
        lda     $0400
        bne     boss_get_apply_gravity
        lda     $0460
        sta     $0461
        jsr     update_animation_frame
        ldx     #$01
        jsr     entity_update_handler
boss_get_apply_gravity:  jsr     apply_gravity
        jsr     render_stars_overlay
        jsr     wait_for_vblank_0D
        lda     $FD
        cmp     #$05
        beq     boss_get_fall_init
        jmp     boss_get_bounce_main

; =============================================================================
; Boss Get — Fall Init (orb falls off screen)
; =============================================================================
boss_get_fall_init:  lda     #$0A
        sta     $0400
boss_get_fall_loop:  clc
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
        bcc     boss_get_fall_done
        jsr     clear_oam_buffer
        ldx     #$00
        stx     $00
        jsr     entity_update_handler
        jsr     apply_gravity
        jsr     render_stars_overlay
        jsr     wait_for_vblank_0D
        jmp     boss_get_fall_loop

boss_get_fall_done:  jsr     clear_oam_buffer
        jsr     render_stars_overlay
        lda     #$3E
        sta     $FD
boss_get_wait_loop:  jsr     wait_for_vblank_0D
        dec     $FD
        bne     boss_get_wait_loop
        jsr     clear_oam_buffer

; =============================================================================
; Boss Get — Flash Palette and Title Scroll
; =============================================================================
boss_get_flash_palette:  ldx     #$1F
boss_get_flash_pal_load:  lda     boss_get_flash_palette_data,x
        sta     $0356,x
        dex
        bpl     boss_get_flash_pal_load
        lda     #$37
        sta     $FD
boss_get_flash_loop:  ldx     #$0F
        lda     $FD
        and     #$08                    ; Flash every 8 frames
        beq     boss_get_flash_set_color
        ldx     #$30
boss_get_flash_set_color:  stx     $0366
        jsr     wait_for_vblank_0D
        dec     $FD
        bpl     boss_get_flash_loop
        ldx     $2A
        lda     boss_get_scroll_start,x
        sta     $FD
        lda     #$3E
        sta     $FE
boss_get_title_scroll_start:  lda     $FD
        sta     $00
        jsr     boss_get_title_render
        jsr     wait_for_vblank_0D
        dec     $FE
        bne     boss_get_title_scroll_start

; =============================================================================
; Boss Get — Title Scroll Loop (letter-by-letter reveal)
; =============================================================================
boss_get_title_scroll_loop:  lda     $1C
        and     #$03                    ; Scroll every 4 frames
        bne     boss_get_title_frame
        lda     #$28
        jsr     bank_switch_enqueue
        clc
        lda     $FD
        adc     #$04                    ; Advance 4 pixels per step
        sta     $FD
        ldx     $2A
        cmp     boss_get_scroll_end,x
        beq     boss_get_title_hold_start
boss_get_title_frame:  lda     $FD
        sta     $00
        jsr     boss_get_title_render
        jsr     wait_for_vblank_0D
        jmp     boss_get_title_scroll_loop

boss_get_title_hold_start:  lda     #$7D
        sta     $FE
boss_get_title_hold_frame:  lda     $FD
        sta     $00
        jsr     boss_get_title_render
        jsr     wait_for_vblank_0D
        dec     $FE
        bne     boss_get_title_hold_frame
        jsr     disable_nmi_and_rendering
        lda     #$00
        sta     $AE
        lda     #$0E
        jsr     banked_entry
        rts


; =============================================================================
; Entity Update & Physics
; =============================================================================
update_animation_frame:  inc     $0681
        lda     $0681
        cmp     #$06                    ; 6-tick animation speed
        bcc     update_anim_frame_rts
        lda     #$00
        sta     $0681
        inc     $0401
        lda     $0401
        cmp     #$04                    ; 4 walk frames total
        bcc     update_anim_frame_rts
        lda     #$01
        sta     $0401
update_anim_frame_rts:  rts

; =============================================================================
; Update All Entities — loop over 3 entity slots, call handler
; =============================================================================
update_all_entities:  jsr     clear_oam_buffer; Loop over all entities, call update handler
        ldx     #$00
        stx     $00
update_all_entity_inner:  stx     $2B
        jsr     entity_update_handler
        ldx     $2B
        inx
        cpx     #$03
        bne     update_all_entity_inner
        rts

; =============================================================================
; Apply Gravity — downward acceleration with terminal velocity
; =============================================================================
apply_gravity:  lda     $22             ; Apply downward acceleration to entity
        bne     gravity_accelerate
        lda     $AE
        bne     gravity_rts
gravity_accelerate:  clc
        lda     $21
        adc     #$80
        sta     $21
        lda     $22
        adc     #$00
        cmp     #$F0
        bne     gravity_store
        lda     #$02
        sta     $AE
        lda     #$00
gravity_store:  sta     $22
        lda     $22
        bne     gravity_rts
gravity_rts:  rts

; =============================================================================
; Render Stars Overlay — draw background star sprites
; =============================================================================
render_stars_overlay:  lda     $AE
        bne     stars_overlay_with_offset
        sec
        lda     #$5F
        sbc     $22
        sta     $01
        lda     #$01
        sbc     #$00
        beq     stars_overlay_setup
        rts

stars_overlay_with_offset:  lda     #$6F
        sta     $01
stars_overlay_setup:  lda     #$05
        sta     $02
        ldx     #$00
stars_overlay_loop:  clc
        lda     star_y_offset,x
        adc     $01
        bcs     stars_overlay_next
        cmp     #$F0
        bcs     stars_overlay_next
        sta     $02EC,x
        lda     star_tile_1,x
        sta     $02ED,x
        lda     star_attr,x
        sta     $02EE,x
        lda     star_x_offset,x
        sta     $02EF,x
stars_overlay_next:  inx
        inx
        inx
        inx
        dec     $02
        bne     stars_overlay_loop
        rts

; =============================================================================
; Boss Get Title Render — draw header OAM and letter sprites
; =============================================================================
boss_get_title_render:  jsr     clear_oam_buffer
        ldx     #$23
boss_get_title_oam_load:  lda     boss_get_header_oam,x
        sta     $0200,x
        dex
        bpl     boss_get_title_oam_load
        lda     $00
        beq     boss_get_title_rts
        ldy     #$00
boss_get_title_letter_loop:  lda     boss_get_letter_oam,y
        sta     $0224,y
        iny
        inx
        dec     $00
        bne     boss_get_title_letter_loop
        lda     $1C
        and     #$08
        bne     boss_get_title_rts
        lda     $2A
        cmp     #$0C
        bcs     boss_get_title_markers
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
boss_get_title_markers:  lda     #$77
        sta     $0215
        sta     $0219
        lda     #$78
        sta     $021D
        sta     $0221
        lda     $2A
        cmp     #$0D
        bne     boss_get_title_rts
        lda     #$77
        sta     $02F5
        sta     $02E9
        lda     #$78
        sta     $02ED
        sta     $02F1
boss_get_title_rts:  rts

; =============================================================================
; Entity Update Handler — load sprite data from ptr table, write OAM
; =============================================================================
entity_update_handler:  ldy     $0400,x
        lda     entity_sprite_ptr_lo,y
        sta     $08
        lda     entity_sprite_ptr_hi,y
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
entity_oam_loop:  clc
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
        beq     entity_oam_store_x
        lda     #$F8
        sta     $0200,x
        bne     entity_oam_next_sprite
entity_oam_store_x:  lda     $01
        sta     $0203,x
        inx
        inx
        inx
        inx
entity_oam_next_sprite:  iny
        dec     $0D
        bne     entity_oam_loop
        stx     $00
        rts

; =============================================================================
; Wily Intro Palette Clear — fill palette RAM with $0F (black)
; =============================================================================
wily_intro_palette_clear:  ldx     #$1F
        lda     #$0F
wily_intro_clear_pal:  sta     $0356,x
        dex
        bpl     wily_intro_clear_pal
        lda     #$02
        sta     $AE
        jsr     enable_nmi_and_rendering
        jsr     render_stars_overlay
        ldx     #$00
        stx     $FD
        lda     #$08
        sta     $FE
wily_intro_fade_loop:  dec     $FE
        bne     wily_intro_vblank
        lda     #$08
        sta     $FE
        ldx     $FD
        ldy     #$00
wily_intro_load_pal:  lda     wily_fade_palette_data,x
        sta     $0356,y
        inx
        iny
        cpy     #$20
        bne     wily_intro_load_pal
        cpx     #$60
        beq     wily_intro_sound
        stx     $FD
wily_intro_vblank:  jsr     wait_for_vblank_0D
        jmp     wily_intro_fade_loop

wily_intro_sound:  lda     #$11
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $FE
wily_intro_wait_outer:  lda     #$A0
        sta     $FD
wily_intro_wait_inner:  jsr     wait_for_vblank_0D
        dec     $FD
        bne     wily_intro_wait_inner
        dec     $FE
        bne     wily_intro_wait_outer
        jsr     clear_oam_buffer
        rts

; =============================================================================
; Wily Intro Data — nametable fill tiles and palette data
; =============================================================================
wily_nametable_fill_tiles:  .byte   $E8,$E8,$E8,$E8,$E8,$E8,$E8,$E8
        .byte   $E8,$E8,$E8,$E8,$E8,$E8,$E8,$00
boss_get_palette_data:  .byte   $0F,$20,$21,$11,$0F,$20,$10
boss_get_palette_data_2:  .byte   $00,$0F,$20,$26,$15,$0F,$17,$21
        .byte   $07,$0F,$16,$29,$09,$0F,$0F,$30
        .byte   $38,$0F,$0F,$30,$28,$0F,$0F,$12
        .byte   $2C
boss_get_flash_palette_data:  .byte   $0F,$11,$11,$11,$0F,$11,$11,$11
        .byte   $0F,$11,$11,$11,$0F,$17,$11,$07
        .byte   $0F,$16,$29,$09,$0F,$0F,$30,$38
        .byte   $0F,$0F,$28,$30,$0F,$0F,$12,$2C

; =============================================================================
; Entity Sprite Pointer Tables — lo/hi pointers for get screen sprites
; =============================================================================
entity_sprite_ptr_lo:  .byte   $E9,$2A,$5B,$8C
        lda     $0FE6,x
        .byte   $0F,$50,$61,$6A
entity_sprite_ptr_hi:  .byte   $9B,$9C,$9C,$9C,$9C,$9C,$9D,$9D
        .byte   $9D,$9D,$9D,$10,$00,$48,$03,$08
        .byte   $00,$49,$03,$10,$00
        eor     #$43
        clc
        brk
        .byte   $48,$43,$20,$08,$4A,$03,$00,$08
        .byte   $4B,$03,$08,$08
        jmp     addr_1003

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
        jsr     addr_5000
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
        bpl     sprite_data_9D19
        .byte   $5C,$03,$08,$08,$5D,$03,$10
        php
sprite_data_9D19:  eor     $1843,x
        php
        .byte   $5C,$43
        jsr     addr_5E10
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
        bpl     boss_get_letter_oam
        .byte   $03,$10,$10,$64,$43,$18,$18,$65
        .byte   $02,$10,$18,$65,$42,$18,$02,$10
        .byte   $66,$03,$14,$18,$67,$02,$14,$01
        .byte   $14,$68,$03,$14
star_y_offset:  .byte   $00
star_tile_1:  .byte   $6B
star_attr:  .byte   $00
star_x_offset:  .byte   $60,$00,$6C,$00
        pla
        brk
        adc     $7000
        php
        .byte   $6E
data_9D7D:  brk
        rts

        php
        .byte   $6F,$00,$68
bounce_entity_type:  .byte   $00,$00,$07,$08,$09
bounce_accel_sub:  .byte   $18,$E9
bounce_accel_whole:  .byte   $00,$FF
boss_get_header_oam:  cpy     #$73
        .byte   $02,$10,$88,$73,$02,$40,$A0,$73
        .byte   $02,$60,$A8,$73,$02,$88
data_9D9C:  bvs     data_9E11
        .byte   $02,$98,$8C,$75,$02,$B4,$8C,$75
        .byte   $42,$BC
boss_get_scroll_start:  .byte   $94
boss_get_scroll_end:  ror     $02,x
        .byte   $B4
        sty     $76,x
        .byte   $42,$BC,$00,$30,$48,$5C,$7C,$98
        .byte   $D0
boss_get_letter_oam:  cpy     #$71
        .byte   $03
        clc
        cpy     #$70
        .byte   $C3,$20,$B8,$72,$03,$20,$B0,$72
        .byte   $03,$20,$A8,$72,$03
        jsr     addr_72A0
        .byte   $03,$20,$98,$70,$03,$20,$98,$71
        .byte   $03,$28,$98,$70,$C3,$30,$90,$72
        .byte   $03,$30,$88,$70,$03,$30,$88,$71
        .byte   $03,$38,$88
        bvs     data_9E2D
        pha
        bcc     data_9E5D
        .byte   $83,$48,$90,$70,$43,$50,$98,$72
        .byte   $03,$50,$A0
        bvs     data_9D7D
        bvc     data_9D9C
        adc     ($03),y
        cli
        ldy     #$71
        .byte   $03,$68,$A0,$70,$43,$70,$A8,$70
        .byte   $83,$70,$A8,$71,$03,$78,$A8,$71
data_9E11:  .byte   $03,$80,$A8,$70,$C3,$90,$A0,$72
        .byte   $03,$90,$98,$72,$03,$90,$90,$72
        .byte   $03,$90,$88,$72,$03,$90,$80,$70
        .byte   $03,$90,$80,$70
data_9E2D:  .byte   $C3,$98,$78,$72,$03,$98,$70,$71
        .byte   $03,$A0,$70,$70,$43,$A8,$78,$72
        .byte   $03,$A8,$80,$72,$03,$A8,$88,$72
        .byte   $03,$A8,$90,$70,$83,$A8,$90,$71
        .byte   $03,$B0,$98,$72,$03,$B8,$A0,$72
        .byte   $03,$B8,$A8,$72,$03,$B8,$B0,$72
data_9E5D:  .byte   $03,$B8,$B8,$72,$03,$B8,$C0,$72
        .byte   $03,$B8,$C8,$70,$83,$B8,$C8,$71
        .byte   $03,$C0,$C8,$71,$03,$C8,$C8,$71
        .byte   $03,$D0,$C4,$75,$02,$D8,$C4,$75
        .byte   $42,$E0,$CC,$76,$02,$D8,$CC,$76
        .byte   $42,$E0
wily_fade_palette_data:  .byte   $0F,$00,$01,$0F,$0F,$00,$0F,$0F
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
        jsr     addr_1121
        .byte   $0F,$20,$10,$00,$0F,$20,$26,$15
        .byte   $0F,$17,$21,$07,$0F,$16,$29,$09
        .byte   $0F,$0F,$30,$38,$0F,$0F,$28,$30
        .byte   $0F,$0F,$12,$2C
wily_intro_init:
        lda     #$10
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001
        lda     #$0F
        jsr     banked_entry
        jsr     reset_scroll_state
        lda     #$00
        sta     $BE
        lda     #$02
        jsr     chr_ram_bank_load
        lda     #$20
        sta     $2006
        ldx     #$00
        stx     $2006
        txa
        ldy     #$04

; =============================================================================
; Credits Screen — PPU clear, tile layout, fade sequence
; =============================================================================
credits_ppu_write_loop:  sta     $2007
        inx
        bne     credits_ppu_write_loop
        dey
        bne     credits_ppu_write_loop
        lda     #$0F
        ldx     #$1F
credits_clear_palette:  sta     $0356,x
        dex
        bpl     credits_clear_palette
        lda     #$04
        sta     $00
        ldx     #$00
credits_load_tiles_outer:  ldy     credits_tile_layout_data,x
        inx
        lda     credits_tile_layout_data,x
        sta     $2006
        inx
        lda     credits_tile_layout_data,x
        sta     $2006
        inx
credits_load_tiles_inner:  lda     credits_tile_layout_data,x
        sta     $2007
        inx
        dey
        bne     credits_load_tiles_inner
        dec     $00
        bne     credits_load_tiles_outer
        jsr     clear_oam_buffer
        jsr     enable_nmi_and_rendering
        lda     #$FE
        jsr     bank_switch_enqueue
        lda     #$FF
        jsr     bank_switch_enqueue
        lda     #$1F
        sta     $FE
credits_fade_outer:  lda     #$0A
        sta     $FF
credits_fade_inner:  ldx     $FE
        lda     credits_fade_brightness,x
        sta     $0357
        jsr     wait_for_vblank_0D
        lda     $27
        and     #$08
        beq     credits_fade_next
        jmp     credits_skip_init

credits_fade_next:  dec     $FF
        bne     credits_fade_inner
        dec     $FE
        bpl     credits_fade_outer
        lda     #$00
        sta     $47
        jsr     disable_nmi_and_rendering
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

; =============================================================================
; Credits — Scroll Right and Render Metatile Columns
; =============================================================================
credits_scroll_right_loop:  jsr     metatile_column_render
        inc     $08
        inc     $1A
        jsr     metatile_column_render
        jsr     ppu_buffer_and_increment
        lda     $08
        and     #$3F
        bne     credits_scroll_right_loop
        lda     #$40
        sta     $08
        lda     #$8A
        sta     $09
        lda     #$00
        sta     $1A
        sta     $1B

; =============================================================================
; Credits — Scroll Advance with PPU Buffer Update
; =============================================================================
credits_scroll_advance:  jsr     metatile_column_render
        clc
        lda     $0300
        adc     #$04
        sta     $0300
        clc
        lda     $0308
        adc     #$04
        sta     $0308
        jsr     ppu_buffer_and_increment
        lda     $08
        and     #$3F
        bne     credits_scroll_advance
        ldx     #$1F
        lda     #$0F
credits_clear_pal_2:  sta     $0356,x
        dex
        bpl     credits_clear_pal_2
        jsr     clear_oam_buffer
        jsr     enable_nmi_and_rendering
        ldx     #$0F
        lda     #$00
credits_clear_entities:  sta     $0440,x
        sta     $0400,x
        dex
        bpl     credits_clear_entities
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

; =============================================================================
; Ending Fade — palette fade in with entity initialization
; =============================================================================
ending_fade_speed:  sta     $FE
ending_fade_loop:  dec     $FE
        bne     ending_fade_frame
        lda     #$08
        sta     $FE
        ldx     $FD
        ldy     #$00
ending_fade_pal_load:  lda     ending_fade_pal_frames,x
        sta     $0356,y
        inx
        iny
        cpy     #$20
        bne     ending_fade_pal_load
        cpx     #$60
        beq     ending_column_init
        stx     $FD
ending_fade_frame:  jsr     ending_render_all_sprites
        jsr     wait_for_vblank_0D
        lda     $27
        and     #$08
        beq     ending_fade_loop
        jmp     credits_skip_init

; =============================================================================
; Ending — Column Data Loading and Text Fade
; =============================================================================
ending_column_init:  lda     #$0E
        jsr     bank_switch_enqueue
        lda     #$00
        sta     $FD
        sta     $C8
ending_column_main:  lda     $FD
        cmp     #$36
        bne     ending_column_load
ending_column_load:  jsr     ending_column_data_load
        lda     #$23
        sta     $03B6
        lda     #$03
        sta     $03B7
        jsr     wait_for_vblank_0D
        lda     $27
        and     #$08
        beq     ending_column_second
        .byte   $4C                     ; JMP credits_skip_init — overlap: $4C eats BCS bytes as target $A7B0
ending_column_skip:  bcs     ending_fade_speed
ending_column_second:  jsr     ending_column_data_load
        lda     #$23
        sta     $03B6
        lda     #$43
        sta     $03B7
        lda     #$1F
        sta     $FE
        lda     #$0A
        sta     $FF
ending_text_fade_loop:  dec     $FF
        bne     ending_text_frame
        lda     #$0A
        sta     $FF
        ldx     $FE
        lda     credits_fade_brightness,x
        sta     $035B
        dec     $FE
        bmi     ending_column_check
ending_text_frame:  jsr     wait_for_vblank_0D
        lda     $27
        and     #$08
        beq     ending_text_fade_loop
        jmp     credits_skip_init

ending_column_check:  lda     $FD
        cmp     #$0E
        bne     ending_column_main
        lda     #$02
        sta     $AE
        lda     #$F0
        sta     $22

; =============================================================================
; Ending — Fall Acceleration (Wily castle crumbles)
; =============================================================================
ending_fall_accel:  sec
        lda     $21
        sbc     #$80
        sta     $21
        lda     $22
        sbc     #$00
        sta     $22
        bcc     ending_fall_decel_init
        cmp     #$40
        bcs     ending_fall_check_col
        jsr     ending_attr_or_column
ending_fall_check_col:  jsr     ending_update_entities
        jsr     ending_render_all_sprites
        jsr     wait_for_vblank_0D
        lda     $27
        and     #$08
        beq     ending_fall_accel
        jmp     credits_skip_init

; =============================================================================
; Ending — Fall Deceleration and Landing Init
; =============================================================================
ending_fall_decel_init:  lda     #$F0
        sta     $22
        lda     #$00
        sta     $21
        sta     $AE
ending_fall_decel_loop:  sec
        lda     $21
        sbc     #$80
        sta     $21
        lda     $22
        sbc     #$00
        sta     $22
        cmp     #$C0
        beq     ending_landing_init
        jsr     ending_update_entities
        jsr     ending_render_all_sprites
        jsr     wait_for_vblank_0D
        lda     $27
        and     #$08
        beq     ending_fall_decel_loop
        jmp     credits_skip_init

; =============================================================================
; Ending — Landing (scroll down to ground level)
; =============================================================================
ending_landing_init:  ldx     #$0F
ending_landing_pal_load:  lda     ending_black_palette,x
        sta     $0356,x
        dex
        bpl     ending_landing_pal_load
        lda     #$00
        sta     $0410
        lda     #$08
        sta     $0690
        lda     #$FF
        sta     $0450
        lda     #$B7
        sta     $04B0
ending_landing_scroll:  sec
        lda     $22
        sbc     #$02                    ; Scroll down 2px per frame
        sta     $22
        jsr     ending_update_entities
        lda     $22
        beq     ending_scroll_columns
        jsr     ending_render_all_sprites
        jsr     ending_advance_anim
        jsr     ending_render_boss_sprite
        jsr     wait_for_vblank_0D
        lda     $27
        and     #$08
        beq     ending_landing_scroll
        jmp     credits_skip_init

; =============================================================================
; Ending — Scroll Columns (grass fills from bottom)
; =============================================================================
ending_scroll_columns:  lda     #$50
        sta     $FD
        lda     #$00
        sta     $03B7
        sta     $FE
        lda     #$10
        sta     $03B6
        lda     #$B0
        sta     $FF
ending_scroll_col_loop:  jsr     ending_advance_anim
        jsr     ending_render_all_sprites
        jsr     ending_render_boss_sprite
        jsr     ppu_column_fill
        jsr     wait_for_vblank_0D
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
        bne     ending_scroll_col_loop
        lda     #$20
        sta     $FD
ending_scroll_idle_loop:  jsr     ending_advance_anim
        jsr     ending_render_all_sprites
        jsr     ending_render_boss_sprite
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     ending_scroll_idle_loop
        ldx     #$0F
ending_load_ground_pal:  lda     ending_ground_palette,x
        sta     $0356,x
        dex
        bpl     ending_load_ground_pal

; =============================================================================
; Ending — Main Loop (timer, cursor, boss walk away)
; =============================================================================
ending_main_loop_init:  lda     #$0D
        jsr     bank_switch_enqueue
        lda     #$0B
        sta     $C1
        lda     #$00
        sta     $C0
        sta     $CB
ending_main_loop:  lda     $27
        and     #$08                    ; Start button = skip
        bne     ending_skip_pressed
        jsr     ending_render_all_sprites
        jsr     ending_advance_anim
        jsr     ending_render_boss_sprite
        ldx     #$02
ending_draw_cursor:  lda     ending_cursor_oam_data,x
        sta     $0281,x
        dex
        bpl     ending_draw_cursor
        ldx     $CB
        ldy     #$F8
        lda     $1C
        and     #$08
        beq     ending_cursor_y
        ldy     ending_cursor_y_table,x
ending_cursor_y:  sty     $0280
        lda     $27
        and     #$34
        beq     ending_timer_tick
        txa
        eor     #$01
        sta     $CB
        lda     #$2F
        jsr     bank_switch_enqueue
        lda     #$0B
        sta     $C1
        lda     #$00
        sta     $C0
ending_timer_tick:  jsr     wait_for_vblank_0D
        sec
        lda     $C0
        sbc     #$01
        sta     $C0
        lda     $C1
        sbc     #$00
        sta     $C1
        bcs     ending_main_loop
        inc     $BE
ending_skip_pressed:  lda     #$FF
        jsr     bank_switch_enqueue
        lda     #$19
        sta     $FD

; =============================================================================
; Ending — Teleport Animation (Mega Man beams away)
; =============================================================================
ending_teleport_loop:  lda     $1C
        and     #$01                    ; Animate every other frame
        bne     ending_teleport_frame
        lda     $FD
        cmp     #$04
        bne     ending_teleport_dec
        lda     #$3A
        jsr     bank_switch_enqueue
ending_teleport_dec:  dec     $FD
        bmi     ending_fly_away
ending_teleport_frame:  ldx     $FD
        lda     ending_teleport_anim_table,x
        sta     $0410
        jsr     ending_render_all_sprites
        jsr     ending_render_boss_sprite
        jsr     wait_for_vblank_0D
        jmp     ending_teleport_loop

; =============================================================================
; Ending — Fly Away (Mega Man rises off screen)
; =============================================================================
ending_fly_away:  lda     #$0A
        sta     $0410
        sec
        lda     $04B0
        sbc     #$08                    ; Rise 8 pixels per frame
        sta     $04B0
        lda     $0450
        sbc     #$00
        sta     $0450
        beq     ending_fly_render
        lda     $04B0
        cmp     #$F0
        bcc     ending_fly_done
ending_fly_render:  jsr     ending_render_all_sprites
        jsr     ending_render_boss_sprite
        jsr     wait_for_vblank_0D
        jmp     ending_fly_away

ending_fly_done:  jsr     ending_render_all_sprites
        lda     #$3E
        sta     $FD
ending_fly_wait:  jsr     wait_for_vblank_0D
        dec     $FD
        bne     ending_fly_wait
        jsr     disable_nmi_and_rendering
        lda     #$00
        sta     $AE
        lda     #$0E
        jsr     banked_entry
        lda     $BE
        beq     password_screen_init
        rts

ending_cursor_oam_data:  .byte   $A2,$01,$30
ending_cursor_y_table:  tya
        tay

; =============================================================================
; Password Screen — metatile render, tile upload, grid init
; =============================================================================
password_screen_init:  lda     #$03
        jsr     chr_ram_bank_load
        lda     #$05
        sta     $2A
        lda     #$40
        sta     $08
        lda     #$8D
        sta     $09
        jsr     metatile_column_render_loop
        lda     #$80
        sta     $08
        lda     #$8D
        sta     $09
        jsr     metatile_column_render_loop
        ldx     #$00
password_load_tiles:  lda     password_ppu_layout_data,x
        sta     $2006
        lda     password_ppu_layout_data_2,x
        sta     $2006
        inx
        inx
        ldy     password_ppu_layout_data,x
        inx
password_tile_inner:  lda     password_ppu_layout_data,x
        sta     $2007
        inx
        dey
        bne     password_tile_inner
        cpx     #$19
        bne     password_load_tiles
        lda     #$10
        jsr     bank_switch_enqueue
        lda     #$01
        jsr     init_scroll_and_palette

; =============================================================================
; Password Grid Init — reset cursor and enter selection loop
; =============================================================================
password_grid_init:  lda     #$00
        sta     $FD
        sta     $9A
        sta     $9B
password_cursor_loop:  ldx     #$03
password_load_cursor_oam:  lda     password_cursor_oam,x
        sta     $0200,x
        dex
        bpl     password_load_cursor_oam
        lda     $1C
        and     #$08
        bne     password_check_input
        ldx     #$60
        lda     $FD
        beq     password_cursor_x_pos
        ldx     #$70
password_cursor_x_pos:  stx     $0200
password_check_input:  lda     $27
        and     #$3C                    ; Any D-pad or Start/Select?
        beq     password_no_input
        and     #$08                    ; Start button?
        bne     password_start_pressed
        lda     #$2F
        jsr     bank_switch_enqueue
        lda     $FD
        eor     #$01
        sta     $FD
password_no_input:  jsr     wait_for_vblank_0D
        jmp     password_cursor_loop

password_start_pressed:  lda     $FD
        bne     password_enter_mode
        jmp     password_exit

; =============================================================================
; Password Enter Mode — fade, draw grid OAM, enter dot placement
; =============================================================================
password_enter_mode:  jsr     palette_fade_out
        jsr     clear_oam_buffer
        jsr     scroll_right_until_wrap
        ldx     #$2F
password_draw_grid_oam:  lda     password_grid_oam_data,x
        sta     $0200,x
        dex
        bpl     password_draw_grid_oam
        lda     #$00
        ldx     #$18
password_clear_dots:  sta     $0420,x
        dex
        bpl     password_clear_dots
        jsr     password_init_dot_oam
        jsr     palette_fade_in
        lda     #$00
        sta     $06A0
        lda     #$09
        sta     $0680
        lda     #$00
        sta     $FE

; =============================================================================
; Password Entry Loop — D-pad movement, dot placement, A/B input
; =============================================================================
password_entry_loop:  lda     $27
        and     #$F0                    ; D-pad new press?
        bne     password_dpad_pressed
        lda     $23
        and     #$F0                    ; D-pad new press?
        beq     password_clear_repeat
        lda     $25
        cmp     $23
        bne     password_clear_repeat
        inc     $FE
        lda     $FE
        cmp     #$18                    ; Auto-repeat delay (24 frames)
        bcc     password_check_ab
        lda     #$08
        sta     $FE
password_dpad_pressed:  lda     #$2F
        jsr     bank_switch_enqueue
        ldx     $06A0
        lda     $23
        and     #$C0
        beq     password_check_up
        and     #$80
        beq     password_move_left
        lda     cursor_move_right_table,x
        jmp     password_store_position

password_move_left:  lda     cursor_move_left_table,x
        jmp     password_store_position

password_check_up:  lda     $23
        and     #$10
        beq     password_move_down
        lda     cursor_move_up_table,x
        jmp     password_store_position

password_move_down:  lda     cursor_move_down_table,x
password_store_position:  sta     $06A0
        jmp     password_check_ab

password_clear_repeat:  lda     #$00
        sta     $FE
password_check_ab:  lda     $27
        and     #$03
        beq     password_render_grid
        lda     $27
        .byte   $AE
        .byte   $A0
password_dot_data:  asl     $29
        ora     ($F0,x)
        .byte   $14
        lda     $0420,x
        bne     password_render_grid
        lda     #$42
        jsr     bank_switch_enqueue
        inc     $0420,x
        dec     $0680
        beq     password_all_dots_placed
        bne     password_render_grid
        lda     $0420,x
        beq     password_render_grid
        dec     $0420,x
        inc     $0680
password_render_grid:  jsr     password_render_sprites
        jsr     wait_for_vblank_0D
        jmp     password_entry_loop

; =============================================================================
; Password All Dots Placed — decode and validate password
; =============================================================================
password_all_dots_placed:  jsr     password_render_sprites
        lda     #$0F
        sta     $036C
        ldx     #$00
password_find_difficulty:  lda     $0420,x
        bne     password_store_difficulty
        inx
        cpx     #$04
        bne     password_find_difficulty
password_store_difficulty:  stx     $04
        txa
        clc
        adc     #$05
        tax
        lda     #$00
        sta     $01
        sta     $02
        sta     $03
password_decode_loop:  lda     $0420,x
        beq     password_decode_next
        ldy     $01
        lda     password_bit_mask_table,y
        pha
        lda     password_byte_index_table,y
        tay
        pla
        ora     $02,y
        sta     $02,y
password_decode_next:  inx
        cpx     #$19
        bne     password_decode_inc
        ldx     #$05
password_decode_inc:  inc     $01
        lda     $01
        cmp     #$14
        bne     password_decode_loop
        lda     $02
        ora     $03
        cmp     #$FF
        bne     password_invalid
        jmp     password_valid

; =============================================================================
; Password Invalid — show error, return to grid
; =============================================================================
password_invalid:  ldx     #$02
        jsr     ppu_column_data_upload
        lda     #$7D
        sta     $FD
password_invalid_wait:  jsr     wait_for_vblank_0D
        dec     $FD
        bne     password_invalid_wait
        ldx     #$03
        jsr     ppu_column_data_upload
        jsr     palette_fade_out
        jsr     clear_oam_buffer
        jsr     scroll_left_until_zero
        jsr     palette_fade_in
        lda     #$7D
        sta     $FD
password_invalid_wait_2:  jsr     wait_for_vblank_0D
        dec     $FD
        bne     password_invalid_wait_2
        jsr     palette_fade_out
        ldx     #$00
        jsr     ppu_column_data_upload
        jsr     wait_for_vblank_0D
        ldx     #$01
        jsr     ppu_column_data_upload
        jsr     wait_for_vblank_0D
        jsr     palette_fade_in
        jmp     password_grid_init

; =============================================================================
; Password Valid — decode stage data, show beaten bosses
; =============================================================================
password_valid:  lda     $02
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
        jsr     metatile_full_screen_render
        lda     #$3C
        sta     $FD
password_valid_wait:  jsr     wait_for_vblank_0D
        dec     $FD
        bne     password_valid_wait
        jsr     palette_fade_out
        jsr     clear_oam_buffer
        jsr     scroll_right_until_wrap
        lda     $9A
        sta     $01
        lda     $9B
        sta     $02
        ldx     #$00
        beq     password_beaten_sprite
password_show_beaten:  lsr     $02
        ror     $01
        bcs     password_beaten_sprite
        inx
        inx
        inx
        inx
        bne     password_beaten_check
password_beaten_sprite:  ldy     #$04
password_beaten_loop:  lda     password_beaten_oam_data,x
        sta     $0200,x
        inx
        dey
        bne     password_beaten_loop
password_beaten_check:  cpx     #$30
        bne     password_show_beaten
        jsr     palette_fade_in
        lda     #$7D
        sta     $FD
password_beaten_wait:  jsr     wait_for_vblank_0D
        dec     $FD
        bne     password_beaten_wait
password_exit:  jsr     disable_nmi_and_rendering
        rts

; =============================================================================
; Enable NMI and Rendering — set ppuctrl + ppumask bits
; =============================================================================
enable_nmi_and_rendering:  lda     $F8
        ora     #$18
        sta     $F8
        lda     $F7
        ora     #$80
        sta     $F7
        sta     $2000
        rts

; =============================================================================
; Disable NMI and Rendering — clear ppuctrl + ppumask bits
; =============================================================================
disable_nmi_and_rendering:  lda     #$10
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001
        rts

; =============================================================================
; PPU Buffer and Increment — transfer buffer then advance pointer
; =============================================================================
ppu_buffer_and_increment:  lda     $08
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

; =============================================================================
; Ending Column Data Load — read credit text into PPU buffer
; =============================================================================
ending_column_data_load:  ldy     $FD
        ldx     #$00
ending_column_inner:  lda     #$46
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
        bne     ending_column_inner
        stx     $47
        sty     $FD
        rts

; =============================================================================
; Ending Attr or Column — write attribute or nametable column data
; =============================================================================
ending_attr_or_column:  sta     $00
        lda     $00
        and     #$01
        beq     ending_nametable_column
        lda     $00
        eor     #$3F
        tax
        lda     wily_castle_attr_data,x
        sta     $03B9
        lda     wily_castle_attr_data_2,x
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

ending_nametable_column:  lda     $00
        lsr     a
        cmp     #$1E
        bcc     ending_column_calc_addr
        rts

ending_column_calc_addr:  asl     a
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
ending_column_copy_loop:  lda     ($08),y
        sta     $03B8,y
        dey
        bpl     ending_column_copy_loop
        lda     #$20
        sta     $47
        rts

; =============================================================================
; Ending Advance Animation — tick boss walk animation counter
; =============================================================================
ending_advance_anim:  dec     $0690
        bne     ending_anim_rts
        lda     #$05
        sta     $0690
        inc     $0410
        lda     $0410
        cmp     #$02
        bne     ending_anim_rts
        lda     #$00
        sta     $0410
ending_anim_rts:  rts

ending_star_oam_init:
        ldx     #$14
ending_load_star_oam:  lda     ending_star_oam_positions,x
        sta     $02EC,x
        dex
        bpl     ending_load_star_oam
        rts

; =============================================================================
; Ending Update Entities — move all entities, apply gravity, spawn
; =============================================================================
ending_update_entities:  ldx     #$02
ending_entity_loop:  stx     $2B
        lda     $0400,x
        beq     ending_entity_next
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
        bne     ending_entity_next
        lda     $04A0,x
        cmp     #$E8
        bcc     ending_entity_next
        lda     #$00
        sta     $0400,x
ending_entity_next:  ldx     $2B
        inx
        cpx     #$0F
        bne     ending_entity_loop
        lda     $AE
        bne     ending_player_gravity
        lda     $22
        cmp     #$A8
        bcc     ending_gravity_accel
ending_player_gravity:  sec
        lda     $04C0
        sbc     $0660
        sta     $04C0
        lda     $04A0
        sbc     $0640
        sta     $04A0
        bcs     ending_player2_gravity
        lda     #$01
        jsr     ending_spawn_entity
        lda     #$00
        sta     $04C0
        lda     #$48
        sta     $04A0
ending_player2_gravity:  sec
        lda     $04C1
        sbc     $0660
        sta     $04C1
        lda     $04A1
        sbc     $0640
        sta     $04A1
        bcs     ending_gravity_accel
        lda     #$02
        jsr     ending_spawn_entity
        lda     #$00
        sta     $04C1
        lda     #$48
        sta     $04A1
ending_gravity_accel:  clc
        lda     $0660
        adc     #$02
        sta     $0660
        lda     $0640
        adc     #$00
        sta     $0640
        cmp     #$02
        bne     ending_boss_fall
        lda     #$00
        sta     $0660
ending_boss_fall:  clc
        lda     $04B0
        adc     $0640
        sta     $04B0
        lda     $0450
        adc     #$00
        sta     $0450
        rts

; =============================================================================
; Ending Spawn Entity — find empty slot and init new entity
; =============================================================================
ending_spawn_entity:  sta     $00
        ldx     #$02
ending_find_empty_slot:  lda     $0400,x
        beq     ending_init_entity
        inx
        cpx     #$0F
        bne     ending_find_empty_slot
        rts

ending_init_entity:  lda     $00
        sta     $0400,x
        lda     #$FF
        sta     $0440,x
        lda     #$E0
        sta     $04A0,x
        lda     #$00
        sta     $04C0,x
        rts

; =============================================================================
; Ending Render All Sprites — clear OAM, draw all entity sprites
; =============================================================================
ending_render_all_sprites:  jsr     clear_oam_buffer
        lda     #$00
        sta     $00
        ldx     #$02
ending_entity_render_loop:  stx     $2B
        lda     $0400,x
        beq     ending_entity_render_next
        ldy     $04A0,x
        sty     $08
        ldy     $0440,x
        sty     $09
        ldx     #$00
        ldy     #$0C
        cmp     #$01
        beq     ending_render_entry
        ldy     #$04
        ldx     #$30
ending_render_entry:  sty     $02
        ldy     $00
ending_oam_write_loop:  clc
        lda     $08
        adc     entity_sprite_y_offset,x
        sta     $0200,y
        lda     $09
        adc     #$00
        beq     ending_oam_tile_write
        lda     #$F8
        sta     $0200,y
        bne     ending_oam_next
ending_oam_tile_write:  lda     entity_sprite_tile_id,x
        sta     $0201,y
        lda     entity_sprite_attr,x
        sta     $0202,y
        lda     entity_sprite_x_offset,x
        sta     $0203,y
        iny
        iny
        iny
        iny
ending_oam_next:  inx
        inx
        inx
        inx
        dec     $02
        bne     ending_oam_write_loop
        sty     $00
ending_entity_render_next:  ldx     $2B
        inx
        cpx     #$0F
        bne     ending_entity_render_loop
        rts

; =============================================================================
; Ending Render Boss Sprite — draw Wily's machine from sprite defs
; =============================================================================
ending_render_boss_sprite:  ldx     $0410
        lda     boss_sprite_def_ptr_lo,x
        sta     $08
        lda     boss_sprite_def_ptr_hi,x
        sta     $09
        ldy     #$00
        lda     ($08),y
        sta     $01
        ldx     $00
        beq     ending_boss_sprite_rts
        iny
ending_boss_oam_loop:  clc
        lda     $04B0
        adc     ($08),y
        sta     $0200,x
        lda     $0450
        adc     #$00
        beq     ending_boss_oam_write
        iny
        iny
        iny
        iny
        lda     #$F8
        sta     $0200,x
        bne     ending_boss_oam_next
ending_boss_oam_write:  iny
        lda     ($08),y
        sta     $0201,x
        iny
        lda     ($08),y
        sta     $0202,x
        iny
        lda     ($08),y
        sta     $0203,x
        iny
ending_boss_oam_next:  inx
        inx
        inx
        inx
        beq     ending_boss_sprite_rts
        dec     $01
        bne     ending_boss_oam_loop
ending_boss_sprite_rts:  rts

; =============================================================================
; Credits Skip Init — fast-forward to ending walk scene
; =============================================================================
credits_skip_init:  jsr     disable_nmi_and_rendering
        lda     #$50
        sta     $FD
        lda     #$00
        sta     $03B7
        sta     $FE
        lda     #$10
        sta     $03B6
        lda     #$B0
        sta     $FF
credits_skip_scroll_loop:  jsr     ppu_column_fill
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
        bne     credits_skip_scroll_loop
        lda     #$D1
        sta     $08
        lda     #$B6
        sta     $09
        lda     #$20
        sta     $2006
        ldy     #$00
        sty     $2006
        ldx     #$1E
credits_skip_nt_outer:  ldy     #$00
credits_skip_nt_inner:  lda     ($08),y
        sta     $2007
        iny
        cpy     #$20
        bne     credits_skip_nt_inner
        sec
        lda     $08
        sbc     #$20
        sta     $08
        lda     $09
        sbc     #$00
        sta     $09
        dex
        bne     credits_skip_nt_outer
        ldy     #$3F
credits_skip_attr_load:  lda     wily_castle_attr_data,y
        sta     $2007
        dey
        bpl     credits_skip_attr_load
        ldx     #$1F
credits_skip_pal_load:  lda     credits_skip_palette,x
        sta     $0356,x
        dex
        bpl     credits_skip_pal_load
        ldx     #$0F
credits_skip_pal2_load:  lda     ending_ground_palette,x
        sta     $0356,x
        dex
        bpl     credits_skip_pal2_load
        ldx     #$1F
        lda     #$00
credits_skip_clear_ents:  sta     $0440,x
        sta     $0400,x
        dex
        bpl     credits_skip_clear_ents
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
        jsr     enable_nmi_and_rendering
        lda     #$00
        sta     $27
        sta     $22
        sta     $AE
        jmp     ending_main_loop_init

; =============================================================================
; Metatile Column Render Loop — render full screen of metatile columns
; =============================================================================
metatile_column_render_loop:  lda     #$00
        sta     $1A
        sta     $1B
metatile_col_pair_render:  jsr     metatile_column_render
        inc     $08
        inc     $1A
        jsr     metatile_column_render
        jsr     ppu_buffer_and_increment
        lda     $08
        and     #$3F
        bne     metatile_col_pair_render
        rts

; =============================================================================
; Palette Fade Out — gradually darken all palette entries
; =============================================================================
palette_fade_out:  lda     #$04
        sta     $FD
palette_fade_out_loop:  lda     $1C
        and     #$03
        bne     palette_fade_out_frame
        jsr     palette_fade_out_step
        dec     $FD
        bmi     palette_fade_out_rts
palette_fade_out_frame:  jsr     wait_for_vblank_0D
        jmp     palette_fade_out_loop

palette_fade_out_rts:  rts

palette_fade_out_step:  ldx     #$07
        lda     #$04
        jsr     palette_dec_range
        ldx     #$1F
        lda     #$0F
        jsr     palette_dec_range
        rts

palette_dec_range:  sta     $00
palette_dec_loop:  sec
        lda     $0356,x
        sbc     #$10                    ; Darken by one NES shade step
        bpl     palette_dec_store
        lda     #$0F
palette_dec_store:  sta     $0356,x
        dex
        cpx     $00
        bne     palette_dec_loop
        rts

; =============================================================================
; Palette Fade In — gradually brighten palette to target
; =============================================================================
palette_fade_in:  lda     #$04
        sta     $FD
palette_fade_in_loop:  lda     $1C
        and     #$03
        bne     palette_fade_in_frame
        jsr     palette_fade_in_step
        dec     $FD
        bmi     palette_fade_in_rts
palette_fade_in_frame:  jsr     wait_for_vblank_0D
        jmp     palette_fade_in_loop

palette_fade_in_rts:  rts

palette_fade_in_step:  ldx     #$07
        ldy     #$07
        lda     #$04
        jsr     palette_inc_range
        ldx     #$1F
        ldy     #$1F
        lda     #$0F
        jsr     palette_inc_range
        rts

palette_inc_range:  sta     $01
palette_inc_loop:  lda     $0356,x
        cmp     #$0F                    ; Is color black ($0F)?
        bne     palette_inc_add
        lda     password_target_palette,y
        and     #$0F
        jmp     palette_inc_store

palette_inc_add:  clc
        lda     $0356,x
        adc     #$10                    ; Brighten by one NES shade step
        cmp     password_target_palette,y
        beq     palette_inc_store
        bcs     palette_inc_next
palette_inc_store:  sta     $0356,x
palette_inc_next:  dey
        dex
        cpx     $01
        bne     palette_inc_loop
        rts

; =============================================================================
; Password Render Sprites — draw cursor and dot grid OAM
; =============================================================================
password_render_sprites:  ldx     $06A0
        lda     password_grid_y_table,x
        sta     $09
        lda     password_grid_x_table,x
        sta     $08
        ldx     #$0F
password_sprite_loop:  clc
        lda     password_sprite_offsets,x
        adc     $08
        sta     $0230,x
        dex
        lda     password_sprite_offsets,x
        sta     $0230,x
        dex
        lda     password_sprite_offsets,x
        sta     $0230,x
        dex
        clc
        lda     password_sprite_offsets,x
        adc     $09
        sta     $0230,x
        dex
        bpl     password_sprite_loop
        lda     $1C
        lsr     a
        and     #$07
        tax
        lda     password_blink_colors,x
        sta     $036C
        clc
        lda     $0680
        adc     #$24
        sta     $022D
        ldx     #$00
        ldy     #$40
password_dot_check_loop:  lda     $0420,x
        bne     password_dot_visible
        lda     #$F8
        bne     password_dot_write_oam
password_dot_visible:  lda     #$3F
password_dot_write_oam:  sta     $0201,y
        iny
        iny
        iny
        iny
        inx
        cpx     #$19
        bne     password_dot_check_loop
        rts

; =============================================================================
; PPU Column Data Upload — load indexed PPU column data for transfer
; =============================================================================
ppu_column_data_upload:  lda     ppu_column_table_index,x
        tax
        lda     password_ppu_layout_data,x
        sta     $03B6
        inx
        lda     password_ppu_layout_data,x
        sta     $03B7
        inx
        lda     password_ppu_layout_data,x
        sta     $47
        inx
        ldy     #$00
ppu_column_data_inner:  lda     password_ppu_layout_data,x
        sta     $03B8,y
        inx
        iny
        cpy     $47
        bne     ppu_column_data_inner
        rts

; =============================================================================
; Init Scroll and Palette — set nametable, load default palette, enable
; =============================================================================
init_scroll_and_palette:  sta     $20
        lda     #$00
        sta     $1F
        sta     $22
        ldx     #$21
init_scroll_pal_loop:  lda     init_scroll_palette_data,x
        sta     $0354,x
        dex
        bpl     init_scroll_pal_loop
        jsr     clear_oam_buffer
        jsr     enable_nmi_and_rendering
        rts

; =============================================================================
; Scroll Right Until Wrap — scroll X in 8px steps until wrap
; =============================================================================
scroll_right_until_wrap:  clc
        lda     $1F
        adc     #$08
        sta     $1F
        php
        lda     $20
        adc     #$00
        sta     $20
        plp
        beq     scroll_right_rts
        jsr     wait_for_vblank_0D
        jsr     wait_for_vblank_0D
        jsr     wait_for_vblank_0D
        jmp     scroll_right_until_wrap

scroll_right_rts:  rts

; =============================================================================
; Metatile Full Screen Render — render all columns with vblank sync
; =============================================================================
metatile_full_screen_render:  lda     #$00
        sta     $1B
        sta     $1A
metatile_render_loop:  lda     $FD
        sta     $08
        lda     $FE
        sta     $09
        jsr     metatile_column_render
        inc     $FD
        inc     $1A
        jsr     wait_for_vblank_0D
        lda     $FD
        and     #$3F
        bne     metatile_render_loop
        rts

; =============================================================================
; Scroll Left Until Zero — scroll X left in 8px steps
; =============================================================================
scroll_left_until_zero:  sec
        lda     $1F
        sbc     #$08
        sta     $1F
        beq     scroll_left_rts
        lda     $20
        sbc     #$00
        sta     $20
        jsr     wait_for_vblank_0D
        jsr     wait_for_vblank_0D
        jsr     wait_for_vblank_0D
        jmp     scroll_left_until_zero

scroll_left_rts:  rts

; =============================================================================
; Password Init Dot OAM — set up grid dot sprite positions
; =============================================================================
password_init_dot_oam:  ldx     #$00
        ldy     #$40
password_dot_oam_loop:  clc
        lda     password_grid_y_table,x
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
        lda     password_grid_x_table,x
        adc     #$04
        sta     $0200,y
        iny
        inx
        cpx     #$19
        bne     password_dot_oam_loop
        rts

; =============================================================================
; Ending Fade Palette Frames — 3 fade-in steps for ending scene
; =============================================================================
ending_fade_pal_frames:  .byte   $0F,$0F,$0F,$04,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$07,$0F,$0F,$0F,$00
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$30,$38
        .byte   $0F,$0F,$0C,$00,$0F,$0F,$0F,$00
        .byte   $0F,$00,$03,$14,$0F,$0F,$01,$00
        .byte   $0F,$00,$04,$17,$0F,$00,$00,$10
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$30,$38
        .byte   $0F,$10,$1C,$01,$0F,$00,$00,$10

; =============================================================================
; Credits Skip / Ending Palette Data Tables
; =============================================================================
credits_skip_palette:  .byte   $0F,$03,$13,$24,$0F,$0F,$11,$0C
        .byte   $0F,$04,$14,$27,$0F,$00,$10,$30
        .byte   $0F,$0F,$2C,$11,$0F,$0F,$30,$38
        .byte   $0F,$30,$2C
        ora     ($0F),y
        brk
        .byte   $10,$30
ending_black_palette:  .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0F,$00,$10,$30
ending_ground_palette:  rol     $15
        jsr     addr_0F06
        bmi     data_AAF2
        ora     $26,x
        and     ($20,x)
        .byte   $0B,$0F,$00,$10,$30
ending_star_oam_positions:  .byte   $2F,$3C,$02,$C0,$37,$3D,$02
        cpy     #$3F
        .byte   $3B,$02,$C0,$3F,$3A,$02,$B8,$3F
        .byte   $39,$02,$B0

; =============================================================================
; Entity Sprite Offset Tables — Y/tile/attr/X for ending entities
; =============================================================================
entity_sprite_y_offset:  .byte   $00
entity_sprite_tile_id:  .byte   $30
entity_sprite_attr:  .byte   $02
entity_sprite_x_offset:  .byte   $C0,$00
        and     ($02),y
        iny
        php
        .byte   $32,$02,$C0,$08,$33,$02
data_AAF2:  iny
        bpl     data_AB29
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

; =============================================================================
; Boss Sprite Definition Pointers — lo/hi for Wily machine frames
; =============================================================================
boss_sprite_def_ptr_lo:  .byte   $3D,$6A,$97,$C8,$F9,$2E
data_AB29:  .byte   $57,$80,$A9,$D2,$FB,$0C,$35
boss_sprite_def_ptr_hi:  .byte   $AB,$AB,$AB,$AB,$AB,$AC,$AC,$AC
        .byte   $AC,$AC,$AC,$AD,$AD,$0B,$00,$00
        .byte   $01
        iny
        brk
        .byte   $01,$01,$D0,$00,$02,$01,$D8,$08
        .byte   $03,$00,$C8,$08,$04,$00,$D0,$08
        .byte   $05,$00,$D8,$08,$1F,$01,$C8,$08
        jsr     fixed_sprite_data_D001
        bpl     boss_sprite_data_AB66
        brk
        .byte   $C8,$10,$07,$00,$D0
boss_sprite_data_AB66:  bpl     boss_sprite_data_AB70
        brk
        .byte   $D8,$0B,$00,$09,$01,$C8,$00
boss_sprite_data_AB70:  asl     a
        ora     ($D0,x)
        brk
        .byte   $0B,$01,$D8,$08,$03,$00,$C8,$08
        .byte   $04,$00,$D0,$08,$05,$00,$D8,$08
        .byte   $1F,$01,$C8,$08
        jsr     fixed_sprite_data_D001
        bpl     boss_sprite_data_AB93
        brk
        .byte   $C8,$10,$07,$00,$D0
boss_sprite_data_AB93:  bpl     boss_sprite_data_AB9D
        brk
        .byte   $D8,$0C,$00,$0C,$01,$C8,$00
boss_sprite_data_AB9D:  ora     fixed_sprite_data_D001
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
        bne     boss_sprite_data_ABCD
        asl     $00
        iny
        bpl     boss_sprite_data_ABC9
        brk
        .byte   $D0,$10,$08,$00,$D8,$0C
boss_sprite_data_ABC9:  .byte   $00,$0C,$01,$C8
boss_sprite_data_ABCD:  .byte   $00,$0E,$01,$D0,$00,$02,$01,$D8
        .byte   $00,$22,$00,$D0,$08,$03,$00,$C8
        .byte   $08,$04,$00,$D0,$08
        ora     $00
        cld
        php
        .byte   $23,$01,$C8,$08
        bit     $01
        bne     boss_sprite_data_ABFE
        asl     $00
        iny
        bpl     boss_sprite_data_ABFA
        brk
        .byte   $D0,$10,$08,$00,$D8,$0D
boss_sprite_data_ABFA:  .byte   $00,$0F,$01,$C8
boss_sprite_data_ABFE:  .byte   $00,$10,$01,$D0
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
        jsr     fixed_sprite_data_D001
        bpl     boss_sprite_data_AC2A
        brk
        .byte   $C8,$10,$07,$00,$D0
boss_sprite_data_AC2A:  bpl     boss_sprite_data_AC34
        brk
        .byte   $D8,$0A,$00,$12,$00,$C8,$00
boss_sprite_data_AC34:  .byte   $13,$00,$D0,$00,$14,$00,$D8,$08
        .byte   $03,$00,$C8,$08,$15,$00,$D0,$08
        .byte   $05,$00,$D8,$10,$06,$00,$C8,$10
        .byte   $07,$00,$D0
        bpl     boss_sprite_data_AC59
        brk
        .byte   $D8,$06,$27,$01,$CF,$0A,$00
boss_sprite_data_AC59:  .byte   $12,$00,$C8,$00,$16,$00,$D0,$00
        .byte   $17,$00,$D8,$08,$03,$00,$C8,$08
        .byte   $18,$00,$D0,$08,$19,$00,$D8,$10
        .byte   $06,$00,$C8,$10,$07,$00,$D0
        bpl     boss_sprite_data_AC82
        brk
        .byte   $D8,$06
        plp
        ora     ($CF,x)
        asl     a
        brk
boss_sprite_data_AC82:  .byte   $12,$00,$C8,$00,$1A,$00,$D0,$00
        .byte   $17,$00,$D8,$08,$03,$00,$C8,$08
        .byte   $1B,$00,$D0,$08,$05,$00,$D8,$10
        .byte   $06,$00,$C8,$10,$07,$00,$D0
        bpl     boss_sprite_data_ACAB
        brk
        .byte   $D8,$06
        plp
        ora     ($CF,x)
        asl     a
        brk
boss_sprite_data_ACAB:  .byte   $1C,$00,$C8,$00,$1D,$00,$D0,$00
        .byte   $17,$00,$D8,$08,$03,$00,$C8,$08
        .byte   $18,$00,$D0,$08,$05,$00,$D8,$10
        .byte   $06,$00,$C8,$10,$07,$00,$D0
        bpl     boss_sprite_data_ACD4
        brk
        .byte   $D8,$06
        plp
        ora     ($CF,x)
        asl     a
        brk
boss_sprite_data_ACD4:  .byte   $1C,$00,$C8,$00,$1E,$00,$D0,$00
        .byte   $17,$00,$D8,$08

; =============================================================================
; Boss Sprite Data — raw OAM for each Wily machine animation frame
; =============================================================================
boss_sprite_data_ACE0:  .byte   $03,$00,$C8,$08,$18,$00,$D0,$08
        .byte   $05,$00,$D8,$10,$06,$00,$C8,$10
        .byte   $07,$00,$D0
        bpl     boss_sprite_data_ACFD
        brk
        .byte   $D8,$06
        plp
        ora     ($CF,x)
        .byte   $04,$F8
boss_sprite_data_ACFD:  rol     a
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
        bpl     credits_text_data
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

; =============================================================================
; Credits Text Data — ASCII text for ending credit screens
; =============================================================================
credits_text_data:  dec     $CDC1
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
credits_text_data_2:  .byte   $00,$C8,$CF,$D7,$C5,$D6,$C5,$D2
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
credits_fade_brightness:  .byte   $0F,$00,$10,$20,$30,$30,$30,$30
        .byte   $30,$30,$30,$30,$30,$30,$30,$30
        .byte   $30
        bmi     data_AE97
        bmi     data_AE99
        bmi     data_AE9B
        bmi     data_AE9D
        bmi     data_AE9F
        bmi     data_AE91
        bpl     credits_fade_data_2
credits_fade_data_2:  .byte   $0F,$30,$30,$30,$20
        bpl     credits_fade_data_3
credits_fade_data_3:  .byte   $0F
ending_teleport_anim_table:  .byte   $0C,$0B,$0A,$06,$06,$09,$09,$08
        .byte   $08,$07,$07,$06,$06,$06,$06
        asl     zp_temp_06
        ora     $05
        .byte   $04,$04,$03
data_AE91:  .byte   $03,$02,$02
        .byte   $01
credits_tile_layout_data:  .byte   $13
        .byte   $21
data_AE97:  .byte   $47
        .byte   $A3
data_AE99:  .byte   $A7
        .byte   $A5
data_AE9B:  lda     ($A1,x)
data_AE9D:  brk
        .byte   $C3
data_AE9F:  cmp     ($D0,x)
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
init_scroll_palette_data:  .byte   $00,$00
password_target_palette:  .byte   $0F,$35,$21,$11,$0F,$30,$3C,$21
        .byte   $0F,$27,$17,$07,$0F,$30,$11,$0C
        .byte   $0F,$0F,$30,$16,$0F,$0F,$30,$0F
        .byte   $0F,$30,$30,$30,$0F,$0F,$0F,$0F
        .byte   $0F,$26,$26,$27,$0F,$17,$28
        ora     $0F
        .byte   $17,$27,$18,$0F,$19,$2A,$37,$0F
        .byte   $20,$2C,$11,$0F,$20,$26,$36,$0F
        .byte   $00,$2C,$11,$0F,$16,$35,$20
password_ppu_layout_data:  .byte   $25
password_ppu_layout_data_2:  sty     $4009
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
data_AF94:  bvc     data_AFE8
        eor     $53
        .byte   $53,$40,$41,$94,$42,$55,$54,$54
        .byte   $4F,$4E,$26,$CA,$09,$50,$41,$53
        .byte   $53,$57,$4F,$52,$44,$40,$27,$0A
        .byte   $0C,$53,$54,$41,$47,$45,$40,$53
        .byte   $45,$4C,$45,$43,$54
ppu_column_table_index:  .byte   $00,$0C,$19,$25,$32,$3D,$4C,$58
        .byte   $69,$75
password_cursor_oam:  .byte   $F8,$22,$00,$58
password_grid_oam_data:  .byte   $30,$25,$00,$44,$30,$26,$00,$54
        .byte   $30,$27,$00,$64,$30,$28,$00,$74
        .byte   $30,$29,$00,$84,$44,$E1,$02,$30
        .byte   $54,$E2,$02,$30,$64
data_AFE8:  .byte   $E3,$02,$30,$74,$E4,$02,$30,$84
        .byte   $E5,$02
        bmi     data_AF94
        .byte   $3F,$00,$D0
        ldy     $2D,x
        ora     ($D0,x)
password_grid_y_table:  rti

        rti

        .byte   $40,$40,$40
data_B000:  .byte   $50
        bvc     data_B053
        bvc     data_B055
        rts

        rts

        .byte   $60,$60,$60,$70,$70,$70,$70,$70
        .byte   $80,$80,$80,$80,$80
password_grid_x_table:  eor     ($51,x)
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
cursor_move_right_table:  ora     ($02,x)
        .byte   $03,$04,$00,$06,$07,$08,$09,$05
        .byte   $0B,$0C,$0D,$0E,$0A,$10,$11,$12
        .byte   $13,$0F,$15,$16,$17,$18,$14
cursor_move_left_table:  .byte   $04,$00,$01,$02,$03,$09
        ora     zp_temp_06
        .byte   $07
        php
        asl     $0B0A
data_B053:  .byte   $0C
        .byte   $0D
data_B055:  .byte   $13
        .byte   $0F
        bpl     data_B06A
        .byte   $12,$18,$14,$15,$16,$17
cursor_move_up_table:  .byte   $14
        ora     $16,x
        .byte   $17,$18,$00,$01,$02,$03,$04,$05
data_B06A:  asl     $07
        php
        ora     #$0A
        .byte   $0B,$0C,$0D,$0E,$0F,$10,$11,$12
        .byte   $13
cursor_move_down_table:  ora     zp_temp_06
data_B07A:  .byte   $07,$08
        ora     #$0A
        .byte   $0B,$0C,$0D,$0E,$0F,$10,$11,$12
        .byte   $13,$14,$15,$16,$17,$18,$00,$01
        .byte   $02,$03,$04
password_blink_colors:  .byte   $0F,$00,$10,$20,$30
        jsr     addr_0010
password_sprite_offsets:  brk
        .byte   $3E,$01,$00,$00,$3E
        eor     ($08,x)
        php
        rol     a:$81,x
        php
        rol     $08C1,x
password_bit_mask_table:  brk
        .byte   $01
data_B0AB:  .byte   $00,$10,$04,$20,$00,$08,$10,$80
        .byte   $08,$02,$04,$00
        ora     ($40,x)
        .byte   $80,$02,$20,$40
password_byte_index_table:  .byte   $00,$00,$00,$00,$01,$00,$00,$01
        .byte   $01,$00,$00,$01,$00,$00,$01,$01
        .byte   $01,$00,$01,$00
password_beaten_oam_data:  .byte   $60,$2F,$00,$60,$70,$1F,$00,$60
        .byte   $60,$1B,$00,$80,$70,$19,$00,$70
        .byte   $60,$1D,$00,$70,$60,$1C,$00
        bcc     credits_init_scroll
        .byte   $1A,$00,$90,$70,$1E,$00,$80,$80
        .byte   $20,$00,$60,$80
        and     $00
        bvs     data_B07A
        rol     $00
        .byte   $80,$80,$27,$00
        .byte   $90                     ; data byte (was wrongly decoded as BCC)
; --- ending_chr_load -- Ending: CHR bank load entry ($B101, dispatch entry 4) ---
ending_chr_load:
        lda     #$03
        jsr     chr_ram_bank_load
        lda     $2A
        pha
        lda     #$05
        sta     $2A
        lda     #$00
        sta     $08
        lda     #$8E
        sta     $09
        jsr     metatile_column_render_loop
        lda     #$40
        sta     $08
        lda     #$8E
        jsr     metatile_column_render_loop
        lda     #$21
        sta     $2006
        lda     #$CC
        sta     $2006
        ldx     #$00
credits_game_over_text:  lda     game_over_text_data,x
        sta     $2007
        inx
        cpx     #$09
        bne     credits_game_over_text
        lda     #$0F
        jsr     bank_switch_enqueue
        jsr     reset_scroll_state
        lda     #$00
        jsr     init_scroll_and_palette
        lda     #$04
        sta     $FE
        lda     #$7D
        sta     $FD
        ldx     $FE
        cpx     #$07
        beq     credits_ppu_upload
        jsr     ppu_column_data_upload
        inc     $FE
credits_ppu_upload:  .byte   $20
        .byte   $AB

; =============================================================================
; Credits / Game Over — init scroll, render tiles, menu select loop
; =============================================================================
credits_init_scroll:  cpy     #$C6
        sbc     $EED0,x
        jsr     palette_fade_out
        jsr     scroll_right_until_wrap
        lda     #$80
        sta     $FD
        lda     #$8E
        sta     $FE
        jsr     metatile_full_screen_render
        lda     #$10
        jsr     bank_switch_enqueue

; =============================================================================
; Credits Select Loop — continue/password/stage select menu
; =============================================================================
credits_select_loop_start:  jsr     palette_fade_in
        lda     #$00
        sta     $FD
credits_select_input:  lda     $27
        and     #$3C
        beq     credits_select_draw
        and     #$08
        bne     credits_start_pressed
        lda     #$2F
        jsr     bank_switch_enqueue
        lda     $27
        and     #$24
        bne     credits_select_next
        dec     $FD
        bpl     credits_select_draw
        lda     #$02
        sta     $FD
        bne     credits_select_draw
credits_select_next:  inc     $FD
        lda     $FD
        cmp     #$03
        bne     credits_select_draw
        lda     #$00
        sta     $FD
credits_select_draw:  ldx     #$03
credits_select_oam_load:  lda     credits_cursor_oam,x
        sta     $0200,x
        dex
        bpl     credits_select_oam_load
        lda     $1C
        and     #$08
        bne     credits_select_vblank
        ldx     $FD
        lda     credits_cursor_y_table,x
        sta     $0200
credits_select_vblank:  jsr     wait_for_vblank_0D
        jmp     credits_select_input

credits_start_pressed:  lda     $FD
        cmp     #$02
        beq     credits_continue
        jmp     credits_exit

credits_continue:  jsr     password_show_grid
        jmp     credits_select_loop_start

credits_exit:  jsr     disable_nmi_and_rendering
        pla
        sta     $2A
        lda     #$03
        sta     $A8
        rts

game_over_text_data:  .byte   $47,$41,$4D,$45,$40,$4F,$56,$45
        .byte   $52
credits_cursor_oam:  .byte   $F8,$22,$00,$48
credits_cursor_y_table:  .byte   $60,$70,$80
credits_header_oam:  .byte   $98,$22,$00,$28
credits_boss_icon_oam:  .byte   $68,$2F,$00,$C8,$88,$1F,$00,$C8
        .byte   $78,$1B,$00,$C8,$88,$19,$00,$D8
        .byte   $68,$1D,$00,$D8,$78,$1C,$00,$D8
        .byte   $98,$1A,$00,$D8,$98,$1E,$00,$C8
        .byte   $A8,$20,$00,$C8,$A8,$25,$00,$D8
        .byte   $B8,$26,$00,$C8,$B8,$27,$00,$D8

; =============================================================================
; Password Show Grid — encode current progress and display grid
; =============================================================================
password_show_grid:  jsr     palette_fade_out
        jsr     clear_oam_buffer
        jsr     scroll_right_until_wrap
        lda     #$00
        ldx     #$18
password_clear_dots_loop:  sta     $0420,x
        dex
        bpl     password_clear_dots_loop
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
password_set_dots_loop:  ldy     password_byte_index_table,x
        lda     $00,y
        ldy     $03
        and     password_bit_mask_table,x
        beq     password_set_dot_entry
        lda     #$01
password_set_dot_entry:  sta     $0420,y
        iny
        cpy     #$19
        bne     password_set_dot_next
        ldy     #$05
password_set_dot_next:  sty     $03
        inx
        cpx     #$14
        bne     password_set_dots_loop
        jsr     password_init_dot_oam
        jsr     password_render_sprites
        lda     #$F8
        sta     $0230
        sta     $0234
        sta     $0238
        sta     $023C
        ldx     #$27
password_copy_grid_oam:  lda     password_grid_oam_data,x
        sta     $0200,x
        dex
        bpl     password_copy_grid_oam
        ldx     #$03
password_copy_header_oam:  lda     credits_header_oam,x
        sta     $0228,x
        dex
        bpl     password_copy_header_oam
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
password_boss_icon_loop:  lsr     $01
        ror     $00
        bcc     password_boss_icon_skip
        ldy     #$04
password_boss_icon_copy:  lda     credits_boss_icon_oam,x
        sta     $02A4,x
        inx
        dey
        bne     password_boss_icon_copy
        beq     password_boss_icon_next
password_boss_icon_skip:  inx
        inx
        inx
        inx
password_boss_icon_next:  dec     $02
        bne     password_boss_icon_loop
        ldx     #$07
        jsr     ppu_column_data_upload
        jsr     palette_fade_in
password_blink_loop:  ldx     #$F8
        lda     $1C
        and     #$08
        bne     password_blink_store
        ldx     #$98
password_blink_store:  stx     $0228
        jsr     wait_for_vblank_0D
        lda     $27
        and     #$01
password_blink_check:  beq     password_blink_loop
        lda     #$42
        jsr     bank_switch_enqueue
        jsr     palette_fade_out
        jsr     clear_oam_buffer
        jsr     scroll_left_until_zero
        rts

; =============================================================================
; Wily Castle Attribute Data — attribute table for castle tilemap
; =============================================================================
wily_castle_attr_data:  .byte   $FF
wily_castle_attr_data_2:  .byte   $FF,$FF,$55,$55,$55,$55,$55,$FF
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
ending_scene_init:
        jsr     reset_scroll_state
        inc     $20
        lda     #$04
        jsr     chr_ram_bank_load
        lda     #$05
        sta     $2A
        lda     #$C0
        sta     $08
        lda     #$8E
        sta     $09
        jsr     metatile_column_render_loop
        lda     #$00
        sta     $08
        lda     #$8F
        sta     $09
        jsr     metatile_column_render_loop
        lda     #$00
        sta     $06A0
        sta     $0680
        sta     $0681
        sta     $0400
        sta     $0401
        sta     $04A1
        lda     #$0F
        ldx     #$1F

; =============================================================================
; Ending Walk Scene — init scroll, CHR, palette, wait, then walk
; =============================================================================
ending_clear_pal_loop:  sta     $0356,x
        dex
        bpl     ending_clear_pal_loop
        lda     #$FF
        jsr     bank_switch_enqueue
        jsr     clear_oam_buffer
        jsr     enable_nmi_and_rendering
        lda     #$BB
        sta     $FD
ending_wait_loop:  jsr     wait_for_vblank_0D
        dec     $FD
        bne     ending_wait_loop
        lda     #$13
        jsr     bank_switch_enqueue
        lda     #$04
        sta     $FD
        lda     #$3F
        sta     $FE

; =============================================================================
; Ending Scene Fade — palette fade loop with sprite rendering
; =============================================================================
ending_scene_fade_loop:  dec     $FE
        bne     ending_scene_render
        lda     #$3F
        sta     $FE
        ldx     #$1B
        ldy     #$3B
        lda     #$0F
        jsr     palette_inc_range
        dec     $FD
        beq     ending_scene_next
ending_scene_render:  jsr     ending_scene_sprite_render
        jsr     wait_for_vblank_0D
        jmp     ending_scene_fade_loop

; =============================================================================
; Ending Scene Sequence — timer-based scene progression
; =============================================================================
ending_scene_next:  ldx     $06A0
        lda     ending_scene_timer_lo,x
        sta     $FD
        lda     ending_scene_timer_hi,x
        sta     $FE
        lda     #$3F
        sta     $FF
ending_scene_timer:  lda     $FF
        beq     ending_scene_check_type
        dec     $FF
ending_scene_check_type:  lda     $06A0
        cmp     #$05
        bne     ending_scene_scroll_pal
        lda     $FF
        and     #$01
        sta     $20
        jmp     ending_scene_check_stars

ending_scene_scroll_pal:  jsr     ending_set_sky_palette
        jsr     ending_set_ground_palette
ending_scene_check_stars:  lda     $06A0
        bne     ending_scene_frame
        lda     $1C
        and     #$07
        bne     ending_scene_frame
        ldx     #$1F
        ldy     #$3F
        lda     #$FF
        jsr     palette_inc_range
ending_scene_frame:  jsr     ending_scene_sprite_render
        jsr     wait_for_vblank_0D
        sec
        lda     $FD
        sbc     #$01
        sta     $FD
        lda     $FE
        sbc     #$00
        sta     $FE
        bcs     ending_scene_timer
        inc     $06A0
        lda     $06A0
        cmp     #$06
        bne     ending_scene_next
        jsr     disable_nmi_and_rendering
        jsr     load_stage_nametable
        lda     #$05
        jsr     chr_ram_bank_load
        lda     #$20
        sta     $2006
        lda     #$00
        sta     $2006
        ldy     #$04
ending_nt_clear_outer:  ldx     #$00
ending_nt_clear_inner:  sta     $2007
        inx
        bne     ending_nt_clear_inner
        dey
        bne     ending_nt_clear_outer
        sta     $0420
        ldx     #$1F
        jsr     load_scroll_palette
        inc     $20
        jsr     clear_oam_buffer
        lda     #$30
        sta     $0369
        lda     #$0D
        jsr     bank_switch_enqueue
        jsr     enable_nmi_and_rendering
        jsr     clear_projectile_positions
        lda     #$25
        sta     $03B6
        lda     #$AC
        sta     $03B7
        lda     #$A2
        sta     $FD
        lda     #$00
        sta     $FE
        sta     $06A0

; =============================================================================
; Ending Health Bar — draw health meter tiles during walk
; =============================================================================
ending_health_bar_loop:  lda     $FD
        and     #$03
        bne     ending_health_bar_frame
        ldx     $FE
        cpx     #$05
        beq     ending_health_bar_frame
        lda     ending_health_tile_data,x
        sta     $03B8
        inc     $47
        inc     $FE
        inc     $03B7
ending_health_bar_frame:  jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     ending_health_bar_loop
        lda     #$A0
        sta     $03B7
        lda     #$20
        jsr     ppu_fill_column_with_tile

; =============================================================================
; Ending Walk Main — scroll columns while Mega Man walks right
; =============================================================================
ending_walk_main_init:  lda     #$49
        sta     $FD
        lda     #$01
        sta     $FE
        lda     #$00
        sta     $0680
        lda     #$25
        sta     $03B6
        lda     #$83
        sta     $03B7
ending_walk_frame_loop:  jsr     ending_scroll_update
        jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        sec
        lda     $FD
        sbc     #$01
        sta     $FD
        lda     $FE
        sbc     #$00
        sta     $FE
        bne     ending_walk_frame_loop
        lda     $FD
        beq     ending_walk_next_column
        cmp     #$D0
        bne     ending_walk_frame_loop
        lda     $06A0
        cmp     #$0E
        bcc     ending_walk_frame_loop
        lda     #$14
        jsr     bank_switch_enqueue
        jmp     ending_walk_frame_loop

ending_walk_next_column:  lda     #$25
        sta     $03B6
        lda     #$80
        sta     $03B7
        lda     #$20
        jsr     ppu_fill_column_with_tile
        lda     #$25
        sta     $03B6
        lda     #$C0
        sta     $03B7
        lda     #$20
        jsr     ppu_fill_column_with_tile
        inc     $06A0
        lda     $06A0
        cmp     #$10
        bne     ending_walk_main_init
        lda     #$0F
        sta     $0358
        sta     $0359
        lda     #$00
        sta     $06A0
        sta     $20
        jsr     ending_init_walk

; =============================================================================
; Ending Final Walk — last walking segment before wait for Start
; =============================================================================
ending_final_walk_loop:  jsr     ending_walk_step
        jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        lda     $06A0
        cmp     #$3C
        bne     ending_final_walk_loop
        lda     $22
        bne     ending_final_walk_loop
ending_wait_for_start:  jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        lda     $27
        and     #$08
        beq     ending_wait_for_start
        jsr     disable_nmi_and_rendering
        rts

; =============================================================================
; Ending Scene Sprite Render — draw scene-specific sprites
; =============================================================================
ending_scene_sprite_render:  jsr     clear_oam_buffer
        lda     $06A0
        cmp     #$05
        bne     ending_scene_normal
        ldy     #$04
        ldx     #$30
        lda     $FF
        and     #$01
        bne     ending_scene_helmet_off
        ldy     #$05
        ldx     #$0F
ending_scene_helmet_off:  stx     $0367
        txa
        and     #$0F
        sta     $036F
        jsr     ending_player_anim
        rts

ending_scene_normal:  lda     #$00
        sta     $0460
        sta     $04A0
        sta     $0440
        sta     $00
        inc     $0680
        lda     $0680
        cmp     #$10
        bne     ending_scene_check_phase
        lda     #$00
        sta     $0680
        inc     $0400
        lda     $0400
        cmp     #$04
        bne     ending_scene_check_phase
        lda     #$00
        sta     $0400
ending_scene_check_phase:  lda     $06A0
        cmp     #$04
        bcc     ending_scene_walk_render
        ldy     $0400
        lda     $FF
        and     #$01
        bne     ending_scene_anim_call
        ldy     #$04
ending_scene_anim_call:  jsr     ending_player_anim
        rts

ending_scene_walk_render:  jsr     ending_player_render
        ldx     $06A0
        clc
        lda     $04C1
        adc     ending_walk_vel_sub,x
        sta     $04C1
        lda     $04A1
        adc     ending_walk_vel_whole,x
        sta     $04A1
        lda     $1C
        and     #$07
        bne     ending_scene_anim_frame
        inc     $0681
        lda     $0681
        cmp     #$04
        bne     ending_scene_anim_frame
        lda     #$00
        sta     $0681
ending_scene_anim_frame:  lda     $06A0
        asl     a
        asl     a
        adc     $0681
        tax
        lda     ending_sprite_tile_table,x
        sta     $02
        lda     $FF
        beq     ending_scene_oam_write
        ldx     $06A0
        beq     ending_scene_oam_write
        dex
        lda     $FF
        beq     ending_scene_oam_write
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
        lda     ending_sprite_fade_table,x
        sta     $02
ending_scene_oam_write:  ldy     $00
        ldx     #$15
ending_scene_oam_loop:  clc
        lda     ending_sprite_y_table,x
        adc     $04A1
        sta     $0200,y
        iny
        lda     $02
        sta     $0200,y
        iny
        lda     #$03
        sta     $0200,y
        iny
        lda     ending_sprite_x_table,x
        sta     $0200,y
        iny
        dex
        bpl     ending_scene_oam_loop
        rts

; =============================================================================
; Ending Set Sky Palette — sky color based on scene index
; =============================================================================
ending_set_sky_palette:  ldx     $06A0
        lda     $FF
        and     #$01
        bne     ending_sky_pal_index
        inx
ending_sky_pal_index:  txa
        asl     a
        tax
        ldy     #$00
ending_sky_pal_copy:  lda     ending_sky_color_table,x
        sta     $0368,y
        sta     $0370,y
        inx
        iny
        cpy     #$02
        bne     ending_sky_pal_copy
        rts

; =============================================================================
; Ending Set Ground Palette — ground palette per scene
; =============================================================================
ending_set_ground_palette:  ldx     $06A0
        beq     ending_ground_pal_rts
        lda     $FF
        and     #$01
        beq     ending_ground_pal_index
        dex
ending_ground_pal_index:  txa
        asl     a
        asl     a
        sta     $00
        clc
        asl     a
        adc     $00
        tax
        ldy     #$00
ending_ground_pal_copy:  lda     ending_palette_per_scene,x
        sta     $0356,y
        inx
        iny
        cpy     #$0C
        bne     ending_ground_pal_copy
ending_ground_pal_rts:  rts

; =============================================================================
; PPU Fill Column with Tile — fill 32-tile column for PPU upload
; =============================================================================
ppu_fill_column_with_tile:  ldx     #$20
        stx     $47
        dex
ppu_fill_col_loop:  sta     $03B8,x
        dex
        bpl     ppu_fill_col_loop
        jsr     wait_for_vblank_0D
        rts

; =============================================================================
; Ending Palette Per Scene — 12-byte palette sets for each scene
; =============================================================================
ending_palette_per_scene:  .byte   $0F,$26,$26,$27,$0F,$17,$28,$05
        .byte   $0F,$17,$27,$18,$0F,$11,$11,$20
        .byte   $0F,$10,$28,$20,$0F,$10,$20,$18
        .byte   $0F,$21,$21,$35,$0F,$25,$37,$16
        .byte   $0F,$25,$35,$17,$0F,$10,$10,$00
        .byte   $0F,$00,$18,$05,$0F,$00,$10,$00
        .byte   $0F,$30,$21,$1C,$0F,$19,$37
        asl     $0F,x
        ora     $182A,y

; =============================================================================
; Ending Sky Color Table — 2-byte sky color for each scene/phase
; =============================================================================
ending_sky_color_table:  bit     $2811
        ora     $30,x
        brk
        .byte   $34,$24,$30,$11,$2C,$11
ending_scene_timer_lo:  bit     $3232
        .byte   $32,$32,$90
ending_scene_timer_hi:  .byte   $03,$02,$02,$02
data_BA85:  .byte   $02,$02
ending_sprite_y_table:  .byte   $00,$08,$10,$20,$28,$30,$40,$48
        .byte   $50,$58,$68,$78,$80,$88,$90,$A8
        .byte   $B8,$C0,$D0,$D8,$E0,$E8
ending_sprite_x_table:  .byte   $D8,$70,$18,$B0,$88,$40,$A0,$F8
        .byte   $20,$58,$C8,$08,$88,$38
        bcs     data_BA85
        bvs     ending_walk_vel_whole
        clv
        php
        tya
        pha
ending_sprite_tile_table:  .byte   $0C,$0D,$0E,$0D,$1B,$1C,$1B,$1C
        .byte   $2C,$2D,$2E,$2D,$3B,$3B,$3B,$3B
ending_sprite_fade_table:  .byte   $1B,$1A,$19,$0F,$2C,$1F,$1E,$1D
        .byte   $3C,$3A,$39,$2F,$3D,$3D,$3D,$3C
ending_walk_vel_sub:  .byte   $80,$80,$E5,$00
ending_walk_vel_whole:  .byte   $00,$00,$00,$08
ending_health_tile_data:  .byte   $13,$14,$01,$06,$06
ending_walk_init:
        lda     #$03
        jsr     chr_ram_bank_load
        lda     #$06
        jsr     chr_ram_bank_load
        lda     $2A
        pha
        lda     #$05
        sta     $2A
        lda     #$40
        sta     $08
        lda     #$8F
        sta     $09
        jsr     metatile_column_render_loop
        lda     #$80
        sta     $08
        lda     #$8F
        sta     $09
        jsr     metatile_column_render_loop
        pla
        sta     $2A
        lda     #$17
        jsr     bank_switch_enqueue
        jsr     reset_scroll_state
        lda     #$01
        jsr     init_scroll_and_palette
        ldx     #$0F
        txa

; =============================================================================
; Stage Intro — CHR load, metatile render, palette fade, name draw
; =============================================================================
stage_intro_clear_pal:  sta     $0366,x
        dex
        bpl     stage_intro_clear_pal
        lda     #$06
        sta     $0400
        jsr     ending_player_render
        lda     #$05
        sta     $FD
stage_intro_fade_loop:  lda     $1C
        and     #$07
        bne     stage_intro_vblank
        ldx     #$1B
        ldy     #$3B
        lda     #$0F
        jsr     palette_inc_range
        dec     $FD
        beq     stage_intro_draw_name
stage_intro_vblank:  jsr     wait_for_vblank_0D
        jmp     stage_intro_fade_loop

; =============================================================================
; Stage Intro — Draw Stage Name Letter by Letter
; =============================================================================
stage_intro_draw_name:  jsr     weapon_get_wait_frame
        jsr     weapon_get_draw_marker
        jsr     weapon_get_wait_frame
        inc     $03B7
        ldx     $2A
        lda     weapon_name_data,x
        sta     $03B8
        inc     $47
        jsr     weapon_get_wait_frame
        jsr     weapon_get_draw_marker
        inc     $03B7
        inc     $03B7
        jsr     wait_for_vblank_0D
        lda     #$08
        jsr     weapon_get_text_upload
        lda     #$09
        jsr     weapon_get_text_upload
        lda     $2A
        jsr     weapon_get_text_upload
        lda     $2A
        cmp     #$04
        bne     stage_intro_blink_loop
        lda     #$13
        jsr     weapon_get_text_upload

; =============================================================================
; Stage Intro — Blink Name in Stage Colors
; =============================================================================
stage_intro_blink_loop:  lda     #$9C
        sta     $FD
stage_intro_blink_frame:  ldx     #$00
        lda     $FD
        and     #$01
        beq     stage_intro_set_colors
        ldx     $2A
        inx
        txa
        asl     a
        tax
stage_intro_set_colors:  lda     stage_intro_pal_lo,x
        sta     $0368
        sta     $0370
        lda     stage_intro_pal_hi,x
        sta     $0369
        sta     $0371
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     stage_intro_blink_frame
        ldx     $2A
        lda     $C281,x
        beq     stage_intro_upload_cols
        jsr     weapon_get_init
stage_intro_upload_cols:  ldx     #$08
        jsr     ppu_column_data_upload
        jsr     wait_for_vblank_0D
        ldx     #$09
        jsr     ppu_column_data_upload
        jsr     wait_for_vblank_0D

; =============================================================================
; Stage Intro — Cursor Init and Select Loop
; =============================================================================
stage_intro_cursor_init:  ldx     #$03
stage_intro_cursor_load:  lda     stage_intro_cursor_oam,x
        sta     $02FC,x
        dex
        bpl     stage_intro_cursor_load
        lda     #$30
        sta     $0374
        lda     #$00
        sta     $FD
stage_intro_select_loop:  ldx     $FD
        lda     stage_intro_cursor_y,x
        sta     $02FC
        lda     $1C
        and     #$08
        bne     stage_intro_check_input
        lda     #$F8
        sta     $02FC
stage_intro_check_input:  lda     $27
        and     #$3C
        beq     stage_intro_no_input
        and     #$08
        bne     stage_intro_start
        lda     #$2F
        jsr     bank_switch_enqueue
        lda     $FD
        eor     #$01
        sta     $FD
stage_intro_no_input:  jsr     wait_for_vblank_0D
        jmp     stage_intro_select_loop

stage_intro_start:  lda     $FD
        beq     stage_intro_save_pal
        jmp     stage_intro_exit

; =============================================================================
; Stage Intro — Save Palette and Show Password Grid
; =============================================================================
stage_intro_save_pal:  ldx     #$1F
stage_intro_save_pal_loop:  lda     $0356,x
        sta     $0700,x
        dex
        bpl     stage_intro_save_pal_loop
        jsr     password_show_grid
        jsr     ending_player_render
        lda     #$05
        sta     $FD
stage_intro_restore_loop:  lda     $1C
        and     #$03
        bne     stage_intro_restore_frame
        ldx     #$1F
stage_intro_restore_inner:  lda     $0356,x
        cmp     #$0F
        bne     stage_intro_restore_add
        lda     $0700,x
        and     #$0F
        sta     $0356,x
        jmp     stage_intro_restore_next

stage_intro_restore_add:  clc
        adc     #$10
        cmp     $0700,x
        beq     stage_intro_restore_store
        bcs     stage_intro_restore_next
stage_intro_restore_store:  sta     $0356,x
stage_intro_restore_next:  dex
        bpl     stage_intro_restore_inner
        dec     $FD
        beq     stage_intro_restore_done
stage_intro_restore_frame:  jsr     wait_for_vblank_0D
        jmp     stage_intro_restore_loop

stage_intro_restore_done:  jmp     stage_intro_cursor_init

; =============================================================================
; Stage Intro Exit — disable rendering and return
; =============================================================================
stage_intro_exit:  jsr     disable_nmi_and_rendering
        rts

; =============================================================================
; Weapon Get Init — blink animation, draw name, draw weapon icon
; =============================================================================
weapon_get_init:  lda     #$0F
        sta     $035C
        sta     $035D
        ldx     #$02
weapon_get_load_pal:  lda     weapon_get_extra_pal,x
        sta     $0373,x
        dex
        bpl     weapon_get_load_pal
        jsr     clear_oam_buffer
        jsr     weapon_get_clear_nt
        lda     #$7D
        sta     $FD
weapon_get_blink_loop:  ldx     #$0F
        lda     $FD
        and     #$08                    ; Blink every 8 frames
        beq     weapon_get_set_blink
        ldx     #$15
weapon_get_set_blink:  stx     $0366
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     weapon_get_blink_loop
        lda     #$07
        sta     $0400
        jsr     ending_player_render
        lda     #$0A
        jsr     weapon_get_text_upload
        lda     #$0B
        jsr     weapon_get_text_upload
        jsr     weapon_get_long_wait
        jsr     weapon_get_clear_nt
        ldx     $2A
        lda     $C281,x
        lsr     a
        ora     #$A0
        sta     $0420
        inc     $0420
        lda     #$0F
        jsr     weapon_get_text_upload
        lda     #$0C
        jsr     weapon_get_text_upload
        lda     #$0D
        jsr     weapon_get_text_upload
        lda     #$0E
        jsr     weapon_get_text_upload
        jsr     weapon_get_long_wait
        jsr     weapon_get_clear_nt
        jsr     clear_oam_buffer
        lda     #$06
        sta     $0400
        jsr     ending_player_render
        jsr     weapon_get_draw_weapon
        lda     #$08
        jsr     weapon_get_text_upload
        lda     #$09
        jsr     weapon_get_text_upload
        lda     $0420
        and     #$0F
        clc
        adc     #$0F
        jsr     weapon_get_text_upload
        lda     #$7D
        sta     $FD
weapon_get_show_loop:  ldx     #$12
        lda     $FD
        and     #$01
        bne     weapon_get_set_colors
        ldx     $2A
        inx
        txa
        asl     a
        tax
weapon_get_set_colors:  lda     stage_intro_pal_lo,x
        sta     $0368
        sta     $0370
        lda     stage_intro_pal_hi,x
        sta     $0369
        sta     $0371
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     weapon_get_show_loop
        rts

; =============================================================================
; Weapon Get Draw Marker — write arrow tile to PPU buffer
; =============================================================================
weapon_get_draw_marker:  lda     #$24
        sta     $03B6
        lda     #$CD
        sta     $03B7
        lda     #$94
        sta     $03B8
        inc     $47
        rts

; =============================================================================
; Weapon Get Wait Frame — sync to frame counter mod 8
; =============================================================================
weapon_get_wait_frame:  jsr     wait_for_vblank_0D
        lda     $1C
        and     #$07
        bne     weapon_get_wait_frame
        rts

; =============================================================================
; Weapon Get Text Upload — read text table and upload letter by letter
; =============================================================================
weapon_get_text_upload:  sty     $00
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
weapon_get_text_inner:  jsr     weapon_get_wait_frame
        ldy     $FE
        cpy     #$F7                    ; Special marker: use item tile
        bne     weapon_get_text_byte
        lda     $0420
        bne     weapon_get_text_store
weapon_get_text_byte:  lda     ($C9),y
weapon_get_text_store:  sta     $03B8
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
        bne     weapon_get_text_inner
        ldy     $00
        jsr     wait_for_vblank_0D
        rts

; =============================================================================
; Weapon Get Long Wait — 125-frame delay
; =============================================================================
weapon_get_long_wait:  lda     #$7D
        sta     $FD
weapon_get_wait_loop:  jsr     wait_for_vblank_0D
        dec     $FD
        bne     weapon_get_wait_loop
        rts

; =============================================================================
; Weapon Get Clear Nametable — zero out text area columns
; =============================================================================
weapon_get_clear_nt:  ldx     #$1F
        lda     #$00
weapon_get_clear_loop:  sta     $03B8,x
        dex
        bpl     weapon_get_clear_loop
        lda     #$09
        sta     $FD
        lda     #$24
        sta     $03B6
        lda     #$AB
        sta     $03B7
weapon_get_clear_cols:  clc
        lda     $03B7
        adc     #$20
        sta     $03B7
        lda     $03B6
        adc     #$00
        sta     $03B6
        lda     #$0F
        sta     $47
        jsr     wait_for_vblank_0D
        dec     $FD
        bpl     weapon_get_clear_cols
        rts

; =============================================================================
; Weapon Get Draw Weapon — show weapon icon with marker
; =============================================================================
weapon_get_draw_weapon:  jsr     weapon_get_wait_frame
        jsr     weapon_get_draw_marker
        jsr     weapon_get_wait_frame
        inc     $03B7
        ldx     $2A
        lda     $0420
        sta     $03B8
        inc     $47
        jsr     weapon_get_wait_frame
        jsr     weapon_get_draw_marker
        inc     $03B7
        inc     $03B7
        jsr     wait_for_vblank_0D
        rts

; =============================================================================
; Weapon Name Data — text tables for stage/weapon names
; =============================================================================
weapon_name_data:  pha
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
weapon_name_data_2:  eor     $4D
        sty     $A2,x
        rti

        .byte   $40,$40,$40,$40,$40,$25,$8B,$40
        .byte   $40,$49,$54,$45,$4D,$94,$A3,$40
        .byte   $40,$40,$40,$40,$40,$25,$CB,$40
        .byte   $40,$94,$42,$4F,$4F,$4D,$45,$52
        .byte   $41,$4E,$47,$40,$40

; =============================================================================
; Stage Intro Palette Data — per-stage blink colors
; =============================================================================
stage_intro_pal_lo:  .byte   $2C
stage_intro_pal_hi:  .byte   $11,$28,$15,$20,$11,$20,$19,$20
        .byte   $00,$34,$25,$34,$14,$37,$18,$20
        .byte   $26,$20,$16
stage_intro_cursor_y:  bcs     weapon_name_data_2
stage_intro_cursor_oam:  bcs     bank_0D_padding
        .byte   $03,$40
weapon_get_extra_pal:  .byte   $20,$10,$36,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; =============================================================================
; Bank $0D Padding — unused space filled with $FF
; =============================================================================
bank_0D_padding:  .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
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
