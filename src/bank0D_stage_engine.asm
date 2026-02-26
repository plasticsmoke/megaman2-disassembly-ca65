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

.include "include/hardware.inc"
.include "include/ram.inc"
.include "include/zeropage.inc"
.include "include/constants.inc"

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
ppu_buffer_transfer           := $D11B
ppu_scroll_column_update           := $D1DF
weapon_palette_copy           := $D2ED
weapon_palette_copy_indexed     := $D2EF
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
        sta     ppuctrl_shadow
        sta     PPUCTRL
        lda     #$06
        sta     ppumask_shadow
        sta     PPUMASK
        jsr     reset_scroll_state
        jsr     load_stage_nametable
        ldx     #$00
        lda     $9A
        sta     temp_01

; =============================================================================
; Stage Select Initialization — clear boss portraits and set up OAM
; =============================================================================
stage_init_clear_loop:  stx     temp_00     ; Save boss index
        lsr     temp_01                     ; Shift out boss beaten flag
        bcc     stage_init_next_boss
        lda     intro_ppu_addr_hi,x
        sta     jump_ptr_hi
        lda     intro_ppu_addr_lo,x
        sta     jump_ptr
        ldx     #$04
        lda     #$00
stage_init_ppu_fill:  lda     jump_ptr_hi
        sta     PPUADDR                   ; Set PPU write address
        lda     jump_ptr
        sta     PPUADDR                   ; Set PPU write address
        ldy     #$04
        lda     #$00
stage_init_ppu_byte:  sta     PPUDATA     ; Clear boss portrait tile
        dey
        bne     stage_init_ppu_byte
        clc
        lda     jump_ptr
        adc     #$20
        sta     jump_ptr
        dex
        bne     stage_init_ppu_fill
stage_init_next_boss:  ldx     temp_00
        inx
        cpx     #$08
        bne     stage_init_clear_loop
        ldx     #$1F
        jsr     load_scroll_palette
        jsr     clear_oam_buffer
        ldx     #$00
        lda     $9A
        sta     temp_02
        ldy     #$00
stage_init_oam_loop:  stx     temp_01       ; Save boss index
        lsr     temp_02
        bcs     stage_init_oam_next
        lda     boss_oam_size_table,x
        sta     temp_00
        lda     boss_oam_offset_table,x
        tax
stage_init_oam_copy:  lda     boss_portrait_oam_data,x
        sta     oam_buffer,y                 ; Copy to OAM buffer
        iny
        inx
        dec     temp_00
        bne     stage_init_oam_copy
stage_init_oam_next:  ldx     temp_01
        inx
        cpx     #$08
        bne     stage_init_oam_loop
        jsr     enable_nmi_and_rendering
        lda     #$0C
        jsr     bank_switch_enqueue
        lda     #$00
        sta     current_stage
        sta     $FD
        jsr     wait_for_vblank_0D

; =============================================================================
; Stage Main Loop
; Per-frame update: render player, check pause, sync PPU.
; =============================================================================
stage_main_loop:  lda     p1_new_presses           ; Main stage loop (called each frame)
        and     #$08                    ; Check Start button (pause)
        bne     stage_paused_handler
        lda     p1_new_presses
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
stage_paused_handler:  ldx     current_stage
        bne     stage_select_handler
        lda     $9A
        cmp     #$FF
        bne     stage_loop_render
        lda     #$08
        sta     current_stage
        jmp     intro_cleanup

; =============================================================================
; Stage Select Handler — load boss entities and run intro sequence
; =============================================================================
stage_select_handler:  ldy     stage_select_index_table,x
        lda     $9A
        and     boss_bitmask_table,y
        bne     stage_loop_render
        sty     current_stage
        lda     #$3A
        jsr     bank_switch_enqueue
        lda     current_stage
        asl     a
        sta     temp_00
        asl     a
        adc     temp_00
        tax
        ldy     #$00
stage_select_load_entity:  lda     stage_entity_x_table,x
        sta     ent_x_px,y
        lda     stage_entity_bank_table,x
        sta     ent_x_screen,y
        lda     #$00
        sta     ent_x_sub,y
        inx
        iny
        cpy     #$06
        bne     stage_select_load_entity
        lda     #$0A
        sta     ent_y_px
        lda     #$00
        sta     ent_y_sub
        sta     ent_anim_frame
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
        ldx     ent_anim_frame
        clc
        lda     ent_x_sub,x
        sta     jump_ptr
        adc     #$20
        sta     ent_x_sub,x
        php
        lda     ent_x_px,x
        sta     jump_ptr_hi
        adc     #$00
        sta     ent_x_px,x
        plp
        bne     intro_update_scroll_col
        inc     ent_anim_frame
intro_update_scroll_col:  lda     ent_x_screen,x
        jsr     scroll_column_prep
        clc
        lda     ent_y_sub
        sta     col_update_addr_lo
        adc     #$20
        sta     ent_y_sub
        lda     ent_y_px
        sta     col_update_addr_hi
        adc     #$00
        sta     ent_y_px
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
        lda     current_stage
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
        sta     nametable_select
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
        sta     ent_x_px
        lda     #$20
        sta     ent_y_px
        lda     #$00
        sta     ent_anim_frame
        sta     ent_anim_id

; =============================================================================
; Intro Player Drop — drop Mega Man into stage with gravity
; =============================================================================
intro_player_drop_loop:  lda     #$00
        sta     ent_anim_frame
        clc
        lda     ent_y_px
        adc     #$08                    ; Drop 8 pixels per frame
        sta     ent_y_px
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
intro_player_landed:  inc     ent_anim_id
        lda     controller_1
        and     #$01                    ; Facing direction from controller
        sta     ent_flags
        lda     #$00
        sta     $FD
        lda     #$08
        sta     $FE

; =============================================================================
; Intro Weapon Flash — cycle weapon palette colors
; =============================================================================
intro_weapon_flash_loop:  lda     #$00
        sta     ent_anim_frame
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
        sta     col_update_addr_hi
        lda     #$0A
        sta     col_update_addr_lo
        lda     current_stage
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
        sta     col_update_tiles
        lda     #$01
        sta     col_update_count
        inc     $FE
        inc     col_update_addr_lo
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
        sta     palette_ram,y
        dex
        dey
        bpl     load_palette_byte
        rts

; =============================================================================
; Check Stage Transition — look up next stage from D-pad input
; =============================================================================
check_stage_transition:  lda     p1_new_presses
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        beq     check_stage_transition_rts
        cmp     #$09
        bcs     check_stage_transition_rts
        sta     temp_00
        dec     temp_00
        lda     current_stage
        asl     a
        asl     a
        asl     a
        clc
        adc     temp_00
        tax
        lda     stage_transition_table,x
        sta     current_stage
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
player_render_collision:  lda     frame_counter
        and     #$08
        bne     collision_hide_sprites
        ldy     current_stage
        lda     collision_x_offset_table,y
        sta     jump_ptr_hi
        lda     collision_y_offset_table,y
        sta     jump_ptr
        ldx     #$00
collision_box_loop:  clc
        lda     collision_box_table,x
        adc     jump_ptr_hi
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
        adc     jump_ptr
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
        sta     temp_00
        lda     #$02
        sta     temp_03
render_sprite_layer_loop:  sty     temp_04
        stx     temp_05
        lda     ent_flags
        beq     render_sprite_load_data
        lda     #$80
        sta     temp_00
        lda     frame_counter
        and     #$04
        bne     render_sprite_load_data
        inc     temp_00
render_sprite_load_data:  ldx     temp_03
        lda     sprite_count_table,x
        sta     temp_01
        clc
        lda     $0481,x
        adc     sprite_xvel_sub_table,x
        sta     $0481,x
        lda     $0461,x
        adc     sprite_xvel_table,x
        sta     $0461,x
        sta     temp_02
        ldx     temp_05
        ldy     temp_04
        jsr     write_sprite_to_oam
        inc     temp_00
        dec     temp_03
        bpl     render_sprite_layer_loop
        rts

sprite_count_table:  .byte   $07,$0D,$15
sprite_xvel_sub_table:  .byte   $00,$47,$41
sprite_xvel_table:  .byte   $04,$01,$00

; =============================================================================
; Write Sprite to OAM — copy one sprite set to $0200 buffer
; =============================================================================
write_sprite_to_oam:  lda     player_sprite_y_table,x
        sta     oam_buffer,y
        iny
        lda     temp_00
        sta     oam_buffer,y
        iny
        lda     ent_flags
        beq     write_oam_attr_byte
        lda     #$40
write_oam_attr_byte:  sta     oam_buffer,y
        iny
        clc
        lda     player_sprite_x_table,x
        adc     temp_02
        sta     oam_buffer,y
        iny
        inx
        inx
        dec     temp_01
        bne     write_sprite_to_oam
        rts

; =============================================================================
; Update Projectile Animation — advance frame counter, load sprite data
; =============================================================================
update_projectile_anim:  ldx     current_stage
        inc     ent_anim_frame
        lda     ent_anim_frame
        cmp     projectile_frame_duration,x
        bcc     projectile_anim_update
        lda     #$00
        sta     ent_anim_frame
        inc     ent_anim_id
        lda     projectile_anim_max_frame,x
        cmp     ent_anim_id
        bcs     projectile_anim_update
        sta     ent_anim_id
projectile_anim_update:  lda     projectile_anim_base_idx,x
        clc
        adc     ent_anim_id
        tax
        ldy     projectile_frame_index,x
        lda     projectile_sprite_ptr_lo,y
        sta     jump_ptr
        lda     projectile_sprite_ptr_hi,y
        sta     jump_ptr_hi
        ldy     #$00
        lda     (jump_ptr),y
        sta     temp_00
        iny
        ldx     #$00
projectile_oam_loop:  clc
        lda     ent_y_px
        adc     (jump_ptr),y
        sta     oam_buffer,x
        iny
        inx
        lda     (jump_ptr),y
        sta     oam_buffer,x
        iny
        inx
        lda     (jump_ptr),y
        sta     oam_buffer,x
        iny
        inx
        clc
        lda     ent_x_px
        adc     (jump_ptr),y
        sta     oam_buffer,x
        inx
        iny
        dec     temp_00
        bne     projectile_oam_loop
        rts

; =============================================================================
; Load Stage Nametable — load CHR data and fill nametable columns
; =============================================================================
load_stage_nametable:  lda     #$00
        jsr     chr_ram_bank_load
        lda     #$20
        sta     PPUADDR
        ldy     #$00
        sty     PPUADDR
        lda     #$AE
        sta     jump_ptr_hi
        lda     #$0B
        jsr     ppu_fill_from_ptr
        ldy     #$1F
nametable_fill_loop:  lda     nametable_fill_table,y
        ldx     #$20
nametable_fill_byte:  sta     PPUDATA
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
clear_oam_fill_loop:  sta     oam_buffer,x
        inx
        bne     clear_oam_fill_loop
        rts

; =============================================================================
; Reset Scroll State — zero all scroll/nametable variables
; =============================================================================
reset_scroll_state:  lda     #$00
        sta     scroll_x
        sta     nametable_select
        sta     scroll_y
        sta     scroll_y_page
        sta     $B5
        sta     camera_y_offset
        sta     $B7
        sta     camera_x_offset
        sta     camera_x_offset_hi
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
        .byte   $15,$0F
        .byte   $0F,$28
        .byte   $15,$0F
        .byte   $0F,$28
        .byte   $11,$0F
        .byte   $0F,$28
        .byte   $11,$0F
        .byte   $0F,$30
        .byte   $29,$0F
        .byte   $0F,$36,$17,$0F,$0F,$30,$19,$0F
        .byte   $0F,$30
        .byte   $19,$0F,$0F
        .byte   $30,$28
        .byte   $0F,$0F
        .byte   $28
        .byte   $15,$0F
        .byte   $30,$30
        .byte   $28
        .byte   $0F,$0F,$30,$12,$0F,$0F,$30,$15
        .byte   $0F,$0F,$28
        .byte   $15,$0F
        .byte   $0F,$30
        .byte   $30,$0F
        .byte   $0F
        .byte   $30,$16
weapon_flash_tile_lo:  .byte   $00
weapon_flash_tile_hi:  .byte   $00
        .byte   $07,$10,$17,$20,$17,$20,$17
        .byte   $20,$17,$20
data_852D:  .byte   $17,$20,$17
        .byte   $20
intro_ppu_addr_hi:  .byte   $21,$20
        .byte   $21,$20
        .byte   $20
        .byte   $22
data_8537:  .byte   $22
        .byte   $22
intro_ppu_addr_lo:  .byte   $86,$8E,$96
data_853C:  .byte   $86,$96
        .byte   $8E,$86,$96

; =============================================================================
; Boss Portrait OAM Data — sprite data for stage select boss icons
; =============================================================================
boss_portrait_oam_data:  .byte   $29,$0A
        .byte   $01,$31
        .byte   $28
        .byte   $0B,$00,$3D,$28,$0C,$00,$45
        .byte   $26,$27
        .byte   $02
        .byte   $78
        .byte   $2E,$25,$01
        .byte   $76,$2E
        .byte   $26,$01
        .byte   $7E,$36,$23
        .byte   $01,$70
        .byte   $36,$24
        .byte   $01,$83
        .byte   $17,$2E,$01,$C8,$26,$28,$00
        .byte   $C0,$2E
        .byte   $29,$00
        .byte   $B0,$2E
        .byte   $2A
        .byte   $00
        .byte   $B8,$2E,$2B,$00,$C0,$36,$2C,$00
        .byte   $B8,$36,$2D,$00,$C0
        .byte   $6C,$06,$00

        .byte   $3B,$6C,$07,$00,$43,$74
        .byte   $08
        .byte   $00
        .byte   $3B,$74
        .byte   $09,$00
        .byte   $43,$5F
        .byte   $0D,$00,$B0
        .byte   $5F,$0E,$00,$B8,$5F,$0F,$00,$C0
        .byte   $67
        .byte   $10,$00
data_859C:  .byte   $B0,$67
        .byte   $11,$00
        .byte   $B8
        .byte   $67,$12,$00,$C0,$6F,$13,$00,$B7
        .byte   $6F,$14,$00,$BF,$77
        .byte   $15,$00
        .byte   $B7,$77,$16,$00,$BF,$9F,$1F,$00
        .byte   $38,$A7
        .byte   $20,$00,$38
        .byte   $AF,$21,$00,$3B,$AF,$22,$00,$43
        .byte   $A7,$17,$01,$71,$A7,$18,$00,$79
        .byte   $A7,$19,$02,$81,$AF,$1A,$01,$71
        .byte   $AF,$1B,$00,$79,$AF
data_85DA:  .byte   $1C,$00
data_85DC:  .byte   $81,$B7
        .byte   $1D,$00,$79
        .byte   $B7,$1E,$00,$81,$9D,$04,$00,$C0
        .byte   $A5
data_85EA:  .byte   $05,$00
data_85EC:  .byte   $C0,$AD
        .byte   $00
        .byte   $00
        .byte   $B6,$AD
        .byte   $01,$00
        .byte   $BE,$B5,$02
        .byte   $00
        .byte   $B6,$B5,$03,$00,$BE

; =============================================================================
; Boss OAM Layout Tables — offsets, sizes, collision boxes
; =============================================================================
boss_oam_offset_table:  .byte   $3C,$0C,$4C
        .byte   $00
        .byte   $20,$84,$74
        .byte   $A4
boss_oam_size_table:  .byte   $10,$14
        .byte   $28
        .byte   $0C,$1C,$20,$10,$18
collision_box_table:  .byte   $F8,$2F,$00,$F9,$F8,$2F,$00,$1F
        .byte   $1E,$2F,$00,$F9,$1E,$2F
data_861B:  .byte   $00,$1F
collision_x_offset_table:  .byte   $60,$20,$20,$20,$60
        .byte   $A0,$A0
        .byte   $A0,$60
collision_y_offset_table:  .byte   $70,$30
        .byte   $70,$B0
        .byte   $B0,$B0
        .byte   $70,$30
        .byte   $30,$60
        .byte   $20,$60,$20
        .byte   $20,$A0,$A0
        .byte   $A0,$30
        .byte   $70,$B0
        .byte   $30,$B0
        .byte   $70,$30
        .byte   $B0

; =============================================================================
; Nametable Fill Table — tile pattern for stage select background
; =============================================================================
nametable_fill_table:  .byte   $00
        .byte   $00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$2D,$20,$20,$20
        .byte   $20,$20,$20,$2C,$00,$00,$00
data_8658:  .byte   $00,$00,$00,$00,$00,$00
data_865E:  .byte   $00

; =============================================================================
; Stage Select Index/Entity Tables — mapping and entity data per boss
; =============================================================================
stage_select_index_table:  .byte   $08
        .byte   $03,$01,$04,$02,$07,$05,$06,$00
        .byte   $00,$08,$02,$10,$04,$20
data_866E:  .byte   $80,$40,$01
stage_entity_x_table:  .byte   $98
        .byte   $99,$9A,$9B
        .byte   $9C,$9D,$AB,$AC,$AD,$AA,$AB,$AC
        .byte   $AC,$AD,$AE,$AF,$B0,$B1,$98,$99
        .byte   $9A,$9B,$9C,$9D,$90,$91,$92,$93
        .byte   $94
        .byte   $95,$9E
data_8690:  .byte   $9F,$96,$97,$9E,$9F,$B0,$B1,$B2
        .byte   $B3,$AA,$AB,$AE,$AF,$B0,$B1,$B2
        .byte   $B3
stage_entity_bank_table:  .byte   $06,$06,$06,$06,$06,$06,$05,$05
        .byte   $05,$06,$06,$06
        .byte   $06,$06
        .byte   $06,$06
        .byte   $06,$06
        .byte   $07,$07,$07,$07,$07,$07,$07,$07
        .byte   $07,$07,$07,$07,$06,$06,$07,$07
        .byte   $07,$07,$03,$03,$03,$03,$05,$05
        .byte   $05,$05,$05,$05,$05,$05
boss_bitmask_table:  .byte   $01,$02,$04,$08
        .byte   $10,$20
        .byte   $40

        .byte   $80
intro_health_tile_data:  .byte   $20,$08,$05
        .byte   $01,$14
        .byte   $0D
        .byte   $01
data_86E0:  .byte   $0E,$20,$20
        .byte   $20,$20,$01
        .byte   $09,$12
        .byte   $0D,$01,$0E
        .byte   $20,$20,$20
        .byte   $17,$0F,$0F,$04,$0D,$01,$0E,$20
        .byte   $20
data_86F7:  .byte   $02,$15,$02,$02,$0C
data_86FC:  .byte   $05,$0D
        .byte   $01,$0E
        .byte   $20,$20,$11
        .byte   $15,$09
        .byte   $03
        .byte   $0B,$0D,$01,$0E,$20,$20,$06,$0C
        .byte   $01,$13,$08,$0D,$01,$0E
        .byte   $20,$20,$0D
        .byte   $05,$14
        .byte   $01,$0C
        .byte   $0D,$01,$0E
        .byte   $20,$20,$03
        .byte   $12,$01,$13,$08,$0D,$01,$0E,$20

; =============================================================================
; Player Sprite Layout Tables — Y/X positions for intro sprites
; =============================================================================
player_sprite_y_table:  .byte   $10
player_sprite_x_table:  .byte   $18,$10,$80,$10,$D0,$14,$40
data_8731:  .byte   $18
        .byte   $90,$28
        .byte   $78
        .byte   $30,$20
        .byte   $30,$F8
        .byte   $38
        .byte   $B0,$40
        .byte   $E8
        .byte   $98
        .byte   $90,$A0
        .byte   $40

        .byte   $A0,$E8,$B0,$90,$B8,$68,$C0,$18
        .byte   $C8,$70,$C8,$C0,$D0,$D8,$D8,$60
        .byte   $D8,$C8,$18,$50,$08,$50
data_8757:  .byte   $18
        .byte   $F8
        .byte   $20,$08,$20
data_875C:  .byte   $A8
        .byte   $30,$40
        .byte   $38
        .byte   $D0,$48
        .byte   $50,$98
        .byte   $B8
        .byte   $A8
        .byte   $78
        .byte   $B0,$00
data_8769:  .byte   $B8
        .byte   $28
        .byte   $C0,$C8
        .byte   $D0,$20
        .byte   $E0,$88
        .byte   $24,$D0
        .byte   $34,$88,$3C,$30,$9C,$20,$A4,$D0
        .byte   $B4
data_877C:  .byte   $58,$D4,$E8,$D4,$A0

; =============================================================================
; Projectile Animation Tables — base index, max frame, duration
; =============================================================================
projectile_anim_base_idx:  .byte   $00,$18,$29,$32,$37,$41,$49,$4F
projectile_anim_max_frame:  .byte   $17,$10,$08,$04,$09,$07
data_878F:  .byte   $05,$04
projectile_frame_duration:  .byte   $02,$03,$08
        .byte   $08
        .byte   $05,$06
        .byte   $08
        .byte   $08
projectile_frame_index:  .byte   $03,$02,$02,$01,$01,$00
data_879F:  .byte   $27,$28,$27,$28,$27,$28,$27,$28
        .byte   $27,$28,$27
data_87AA:  .byte   $28,$27,$28,$27,$28,$27,$00,$1E
        .byte   $1B,$1B,$1C,$1D,$1C,$1D,$1C,$1D
        .byte   $1B,$1C,$1D,$1C,$1D,$1C,$1D,$1B
        .byte   $26,$23,$24,$25,$24,$25,$24,$25
        .byte   $23,$04,$04,$04
        .byte   $05,$06
        .byte   $0F,$07,$08,$09,$0A,$0B,$0C,$0D
        .byte   $0E,$09,$16,$10,$11,$12,$13,$14
        .byte   $15,$12,$1A,$17,$17,$17,$18,$19
        .byte   $22,$1F,$1F,$20,$21

; =============================================================================
; Projectile Sprite Pointer Tables — lo/hi address for each frame
; =============================================================================
projectile_sprite_ptr_lo:  .byte   $3F,$78,$A9,$D2,$FF,$28,$59,$8A
        .byte   $BB,$EC,$1D,$4E,$83,$B8
        .byte   $ED,$1E,$4F
        .byte   $84,$BD
        .byte   $F2,$27,$5C,$91,$CA,$EF,$1C,$41
        .byte   $6A,$AF
        .byte   $F8
        .byte   $41,$8E
        .byte   $BB,$F0,$25,$5E,$9F,$DC,$1D,$62
        .byte   $A7
projectile_sprite_ptr_hi:  .byte   $88
        .byte   $88
        .byte   $88
        .byte   $88
        .byte   $88
        .byte   $89,$89,$89,$89,$89,$8A,$8A,$8A
        .byte   $8A,$8A,$8B,$8B,$8B,$8B,$8B,$8C
        .byte   $8C,$8C,$8C,$8C,$8D,$8D

; =============================================================================
; Sprite Definition Data — raw OAM data for projectile/weapon sprites
; =============================================================================
sprite_def_data_8831:  .byte   $8D,$8D,$8D
        .byte   $8E,$8E,$8E
        .byte   $8E,$8F,$8F
        .byte   $8F,$8F,$90,$90,$90,$0E
        .byte   $E0,$A0
        .byte   $03,$FA,$E8
        .byte   $A1,$03
        .byte   $F0,$E8
        .byte   $A2,$03
        .byte   $F8
        .byte   $E8
        .byte   $A3,$03,$00,$E8,$A4,$03,$08,$F0
        .byte   $A5,$03,$F0,$F0,$A6,$03,$F8,$F0
        .byte   $A7,$03,$00,$F0,$A8,$03,$08,$F0
        .byte   $C0,$01
        .byte   $FA,$F8,$A9,$03,$F0,$F8,$AA,$03
        .byte   $F8,$F8,$AB,$03,$00,$F8,$AC,$03
        .byte   $08,$0C
        .byte   $E0,$AD
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
        .byte   $E5,$03
        .byte   $F7,$F8,$E6,$03,$04,$0A,$E0
        .byte   $A0,$03
        .byte   $F8
        .byte   $E8
        .byte   $A1,$03
        .byte   $F7,$E8,$A2,$03,$FF,$F0,$A3,$03
        .byte   $F0,$F0,$A4,$03,$F8,$F0
        .byte   $A5,$03
        .byte   $00
        .byte   $F8,$A6,$03,$F0,$F8,$A7,$03,$F8
        .byte   $F8,$A8,$03,$00,$F8,$A9,$03,$08
        .byte   $0C,$E0,$AA,$03,$F2,$E0,$AB,$03
        .byte   $F8
        .byte   $E8
        .byte   $AC,$03,$F0
        .byte   $E8
        .byte   $AD,$03,$F8
        .byte   $E8
        .byte   $AE,$03,$00
        .byte   $F0,$AF
        .byte   $03,$F0,$F0,$B0,$03,$F8,$F0
        .byte   $B1,$03
        .byte   $00
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
        .byte   $E0,$A1
        .byte   $03,$04,$E8
        .byte   $A2,$03
        .byte   $F4,$E8,$A3,$03,$FC,$E8,$A4,$03
        .byte   $04,$EC,$BF
        .byte   $01,$FC
        .byte   $F0,$A5
        .byte   $03,$F4,$F0,$A6,$03,$FC,$F0,$A7
        .byte   $03,$04,$F8,$A8,$03,$F4,$F8,$A9
        .byte   $03,$FC
        .byte   $F8
        .byte   $AA
        .byte   $03,$04,$0C
        .byte   $E0,$A0
        .byte   $03,$F0,$E0,$A1,$03,$00,$E8,$B6
        .byte   $03,$EC,$E8,$B7,$03,$F4,$E8,$B8
        .byte   $03,$FC,$EC,$BF,$01,$F8,$F0,$B9
        .byte   $03,$F4,$F0,$BA,$03,$FC,$F0,$BB
        .byte   $03,$04,$F8,$BC,$03,$F4,$F8,$BD
        .byte   $03,$FC
        .byte   $F8
        .byte   $BE,$03,$04
        .byte   $0C
        .byte   $E0,$AB
        .byte   $03,$04,$E8,$AC,$03,$F4,$E8,$AD
        .byte   $03,$FC,$E8,$AE,$03,$04,$EE,$BF
        .byte   $01,$FB,$F0,$AF,$03,$F4,$F0,$B0
        .byte   $03,$FC,$F0,$B1,$03,$04,$F8,$B2
        .byte   $03,$EC,$F8,$B3,$03,$F4,$F8,$B4
        .byte   $03,$FC,$F8,$B5,$03,$04,$0C,$E0
        .byte   $AB,$03,$04
        .byte   $E8
        .byte   $C0,$02
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
        .byte   $E8
        .byte   $C4,$02
        .byte   $FC,$E8,$C3,$03,$FC,$E8,$AE,$03
        .byte   $04,$EE,$BF,$01,$FB,$F0,$AF,$03
        .byte   $F4,$F0,$B0,$03,$FC,$F0,$B1,$03
        .byte   $04,$F8,$B2,$03,$EC,$F8,$B3,$03
        .byte   $F4,$F8,$B4,$03,$FC,$F8,$B5,$03
        .byte   $04
        .byte   $0D,$E0,$C6
        .byte   $02,$04
sprite_def_data_8ABD:  .byte   $E8
        .byte   $AC,$03,$F4
        .byte   $E8
        .byte   $AD,$03,$FC
        .byte   $E8
        .byte   $AE,$03,$04
        .byte   $E8
        .byte   $C7,$02,$04,$EE,$BF,$01,$FB,$F0
        .byte   $AF,$03,$F4,$F0,$B0,$03,$FC,$F0
        .byte   $B1,$03,$04,$F8,$B2,$03,$EC,$F8
        .byte   $B3,$03,$F4,$F8,$B4,$03,$FC,$F8
        .byte   $B5,$03,$04,$0C,$E0,$C8,$02,$04
        .byte   $E8,$AC,$03,$F4,$E8,$AD,$03,$FC
        .byte   $E8,$AE,$03,$04,$EE,$BF,$01,$FB
        .byte   $F0,$AF,$03,$F4,$F0,$B0,$03,$FC
        .byte   $F0,$B1
        .byte   $03,$04,$F8,$B2,$03,$EC,$F8,$B3
        .byte   $03,$F4,$F8,$B4,$03,$FC,$F8,$B5
        .byte   $03,$04,$0C,$E0
        .byte   $A0,$03
        .byte   $F3,$E0,$A1,$03,$03,$E8,$F5,$03
        .byte   $F2,$E8,$F6,$03,$FA,$E8,$F7,$03
        .byte   $02,$EC,$BF,$01
sprite_def_data_8B36:  .byte   $FB,$F0,$F8,$03,$F4
        .byte   $F0,$F9
        .byte   $03,$FC,$F0,$FA,$03,$04,$F8,$FB
        .byte   $03,$F4,$F8,$FC,$03,$FC,$00,$FD
        .byte   $03,$FD,$0D,$E0,$A0,$03,$FC
sprite_def_data_8B54:  .byte   $E8
        .byte   $A1,$03
        .byte   $F6,$E8
        .byte   $A2,$03
        .byte   $FE,$E8,$A3
        .byte   $03,$06,$EB,$F4,$01,$FB,$F0,$A4
        .byte   $03,$F0,$F0,$A5,$03,$F8,$F0,$A6
        .byte   $03,$00,$F0,$A7,$03,$08,$F8,$A8
        .byte   $03,$F0,$F8,$A9,$03,$F8,$F8,$AA
        .byte   $03,$00,$F8,$AB,$03,$08,$0E,$E0
        .byte   $AC,$03,$F1,$E0
        .byte   $A0,$03
        .byte   $FE,$E8,$AD
        .byte   $03,$F0,$E8,$AE,$03,$F8,$E8,$AF
        .byte   $03,$00,$E8
        .byte   $B0,$03
        .byte   $08
        .byte   $EB,$F4
sprite_def_data_8B9F:  .byte   $01,$FD
        .byte   $F0,$B1
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
        .byte   $C5,$03
        .byte   $00
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
        .byte   $F8
        .byte   $C0,$02
        .byte   $F0,$F8
sprite_def_data_8C86:  .byte   $C8
        .byte   $02,$F8,$F8,$C9,$03,$00,$F8,$C3
        .byte   $02
        .byte   $08
        .byte   $0E,$E0,$AC
        .byte   $03,$F1,$E0,$A0,$03,$FE,$E8,$AD
        .byte   $03,$F0,$E8,$AE,$03,$F8,$E8,$AF
        .byte   $03,$00,$E8,$B0,$03,$08,$EB,$F4
        .byte   $01,$FD
sprite_def_data_8CAE:  .byte   $F0,$D6
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
        .byte   $F0,$AC
        .byte   $03
        .byte   $F1,$F0
        .byte   $AD,$03,$F9
        .byte   $F0,$AE
        .byte   $03
        .byte   $01,$F8
        .byte   $AF,$03,$EC
        .byte   $F8
        .byte   $B0,$03
        .byte   $F4,$F8,$B1
sprite_def_data_8D16:  .byte   $03,$FC,$F8,$B2,$03,$04,$09,$E8
        .byte   $B3,$03,$F4,$E8,$B4,$03,$FC,$E8
        .byte   $B5,$03,$04,$E9,$A0,$01,$FC,$F0
        .byte   $B6,$03,$F9,$F0,$B7,$03,$01
        .byte   $F8
        .byte   $B8
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
        .byte   $A5,$03
        .byte   $F8
        .byte   $E8
        .byte   $A6,$03
        .byte   $00
        .byte   $E8,$A7,$03,$08,$F0,$A8
sprite_def_data_8D8D:  .byte   $03,$F0,$F0,$A9,$03,$F8,$F0,$AA
        .byte   $03,$00,$F0
sprite_def_data_8D98:  .byte   $AB,$03,$08,$F8,$AC,$03
        .byte   $F0,$F8
        .byte   $AD,$03,$F8
        .byte   $F8
        .byte   $AE,$03,$00
        .byte   $F8
        .byte   $AF,$03,$08,$E2,$DE
sprite_def_data_8DAD:  .byte   $01,$FB
        .byte   $12
        .byte   $E0,$B0
        .byte   $03,$F6,$E0,$B1,$03,$FE,$E0,$B2
        .byte   $03,$06,$E0,$B3,$03,$0E
        .byte   $E8
        .byte   $B4,$03
        .byte   $F0,$E8
        .byte   $B5,$03
        .byte   $F8
        .byte   $E8
        .byte   $B6,$03
        .byte   $00
        .byte   $E8,$B7,$03,$08,$E8,$B8,$03,$10
        .byte   $F0,$B9,$03,$F0,$F0,$BA,$03,$F8
        .byte   $F0,$BB,$03,$00,$F0
        .byte   $BC,$03,$08
        .byte   $F8
        .byte   $BD,$03,$F0
        .byte   $F8
        .byte   $BE,$03,$F8
        .byte   $F8
        .byte   $BF,$03,$00,$F8,$C0,$03,$08,$E4
        .byte   $DE
        .byte   $01,$FB
        .byte   $12,$E0,$B0,$03,$F6,$E0
        .byte   $B1,$03
        .byte   $FE,$E0,$B2
        .byte   $03,$06,$E0,$B3,$03,$0E,$E8,$B4
        .byte   $03,$F0,$E8
        .byte   $C1,$03
        .byte   $F8
        .byte   $E8
        .byte   $C2,$03,$00,$E8,$B7,$03,$08,$E8
        .byte   $B8,$03,$10,$F0,$B9,$03,$F0,$F0
        .byte   $C3,$03,$F8,$F0,$C4,$03,$00,$F0
        .byte   $BC,$03,$08,$F8,$BD,$03,$F0,$F8
        .byte   $BE,$03,$F8,$F8,$BF,$03,$00,$F8
        .byte   $C0,$03
        .byte   $08
        .byte   $E4,$DE
        .byte   $01,$FB
        .byte   $13,$E0,$B0,$03
        .byte   $F6,$E0
        .byte   $B1,$03
        .byte   $FE,$E0,$B2
        .byte   $03,$06,$E0,$B3,$03,$0A,$E8,$B4
        .byte   $03,$F0,$E8
        .byte   $B5,$03
        .byte   $F8
        .byte   $E8
        .byte   $B6,$03
        .byte   $00
        .byte   $E8,$B7,$03,$08,$E8,$B8,$03,$10
        .byte   $F0,$C5,$03,$F0,$F0,$C6,$03,$F8
        .byte   $F0,$C7,$03,$00,$F0,$C8,$03,$08
        .byte   $F8,$C9,$03,$F5,$F8,$CA,$03,$FD
        .byte   $F8,$CB,$03
sprite_def_data_8E81:  .byte   $05,$00
        .byte   $CC,$03,$F5
        .byte   $00
        .byte   $CD,$03,$05,$E4
        .byte   $DE,$01,$FB
sprite_def_data_8E8E:  .byte   $0B,$E8,$A0,$03,$F8,$E8,$A1,$03
        .byte   $00,$F0,$A2,$03,$F0,$F0,$A3,$03
        .byte   $F8,$F0,$A4,$03,$00,$F0
sprite_def_data_8EA4:  .byte   $A5,$03
        .byte   $08
        .byte   $F8
        .byte   $A6,$03
        .byte   $F0,$F8
        .byte   $A7,$03,$F8,$F8,$A8,$03,$00,$F8
        .byte   $A9,$03,$08,$ED,$F3,$01,$FA,$0D
        .byte   $E0
sprite_def_data_8EBD:  .byte   $AA,$03,$F0,$E0,$AB,$03,$F8,$E8
        .byte   $AC,$03,$F0
        .byte   $E8
        .byte   $AD,$03,$F8
        .byte   $E8
        .byte   $AE,$03,$00
        .byte   $F0,$AF
        .byte   $03,$F0,$F0,$B0,$03,$F8,$F0
        .byte   $B1,$03
        .byte   $00
        .byte   $F8,$B2
sprite_def_data_8EDE:  .byte   $03,$F0,$F8,$B3,$03,$F8,$F8,$B4
        .byte   $03,$00,$F8,$B5,$03,$08,$ED,$F3
        .byte   $01,$F9,$0D,$E8
sprite_def_data_8EF2:  .byte   $B6,$03
        .byte   $F0,$E8
        .byte   $B7,$03,$F8,$E8,$B8,$03,$00,$E8
        .byte   $B9,$03,$08
        .byte   $F0,$BA
        .byte   $03,$F0,$F0,$BB,$03,$F8,$F0,$BC
        .byte   $03,$00,$F0,$BD,$03,$08,$F8,$BE
        .byte   $03,$F0,$F8,$BF,$03,$F8,$F8,$C0
        .byte   $03,$00,$F8,$C1,$03,$08,$ED,$F3
        .byte   $01,$FC,$0E,$E8,$B6,$03,$EE,$E8
        .byte   $B7,$03,$F6
        .byte   $E8
        .byte   $B8
        .byte   $03,$FE,$E8
        .byte   $B9,$03,$06
        .byte   $F0,$BA
        .byte   $03,$EE,$F0,$BB,$03,$F6,$F0,$BC
        .byte   $03,$FE,$F0,$BD,$03,$06,$F8,$C2
        .byte   $03,$F8,$F8,$C3,$03,$00,$F8,$C4
        .byte   $03,$08,$00,$C5,$03,$F8,$00,$C6
        .byte   $03,$00,$ED,$F3,$01,$FB,$10,$E0
        .byte   $A0,$03,$F8,$E0,$A1,$03,$00,$E0
        .byte   $A2,$03,$08,$E8,$A3,$03,$F0,$E8
        .byte   $A4,$03
        .byte   $F8
sprite_def_data_8F73:  .byte   $E8
        .byte   $A5,$03
        .byte   $00
        .byte   $E8,$A6,$03,$08,$F0,$A7,$03,$F0
        .byte   $F0,$A8,$03,$F8,$F0,$A9,$03,$00
        .byte   $F0,$AA,$03,$08,$F8,$AB,$03,$F0
sprite_def_data_8F8F:  .byte   $F8
        .byte   $AC,$03,$F8
        .byte   $F8
        .byte   $AC,$43,$00
        .byte   $F8
        .byte   $AD,$03,$08
        .byte   $E7,$F4,$02,$FA,$0F,$E0,$AE,$03
        .byte   $F8,$E0,$AF,$03,$00,$E0,$B0,$03
        .byte   $08,$E8,$B1,$03,$F0,$E8,$B2,$03
        .byte   $F8,$E8,$B3,$03,$00,$E8,$B4,$03
        .byte   $08
        .byte   $F0,$B5
        .byte   $03,$F5,$F0,$B6,$03,$FD,$F0
sprite_def_data_8FC5:  .byte   $B7,$03,$05,$F8,$B8,$03,$F0,$F8
        .byte   $B9,$03,$F8,$F8,$BA,$03,$00,$F8
        .byte   $BB,$03,$08,$E8,$F4,$02,$FA,$10
        .byte   $E0,$AE,$03,$F8,$E0,$AF,$03,$00
        .byte   $E0,$B0,$03,$08,$E8,$BC,$03,$F0
        .byte   $E8
        .byte   $BD,$03,$F8
        .byte   $E8
        .byte   $BE,$03,$00
        .byte   $E8
        .byte   $BF,$03,$08,$F0,$C0,$03,$F0,$F0
        .byte   $C1,$03,$F8
        .byte   $F0,$C2
        .byte   $03,$00,$F0
sprite_def_data_9006:  .byte   $C3,$03
        .byte   $08
        .byte   $F8
        .byte   $B8
        .byte   $03
        .byte   $F0,$F8
        .byte   $B9,$03,$F8
        .byte   $F8
        .byte   $BA
        .byte   $03,$00,$F8,$BB,$03
        .byte   $08
        .byte   $E8
        .byte   $F4,$02,$FA,$11,$E0,$A0,$03,$F8
        .byte   $E0,$A1,$03,$00,$E0,$CC,$03,$08
        .byte   $E8,$CD,$03,$F0,$E8
        .byte   $CE,$03,$F8
        .byte   $E8
        .byte   $A5
sprite_def_data_9034:  .byte   $03
        .byte   $00
        .byte   $E8,$CF,$03,$08,$F0,$D0,$03,$F0
        .byte   $F0,$D1,$03,$F8,$F0,$D2,$03,$00
        .byte   $F0
sprite_def_data_9047:  .byte   $D3
sprite_def_data_9048:  .byte   $03,$08,$F8,$D4,$03
        .byte   $F0,$F8
        .byte   $D5,$03
        .byte   $F8
        .byte   $F8
        .byte   $D5,$03
sprite_def_data_9055:  .byte   $00
        .byte   $F8,$D6,$03,$08,$E7,$F4,$02,$FA
        .byte   $E0,$CB
sprite_def_data_9060:  .byte   $03,$F0,$11,$E0,$C1,$03
        .byte   $F0,$E0
        .byte   $C2,$03,$F8,$E0,$C3,$03,$00,$E0
        .byte   $C4,$03,$08,$E8
        .byte   $C5,$03
        .byte   $F0,$E8
        .byte   $A2,$03
        .byte   $F8
        .byte   $E8
        .byte   $C6,$03
        .byte   $00
        .byte   $E8,$C7,$03,$08,$F0,$C8,$03,$F0
        .byte   $F0
        .byte   $A6,$03
        .byte   $F8
        .byte   $F0,$A7
        .byte   $03,$00,$F0
        .byte   $C9,$03
        .byte   $08
        .byte   $F0
sprite_def_data_9094:  .byte   $C0,$01
        .byte   $FA
        .byte   $F8
        .byte   $CA
        .byte   $03
        .byte   $F0,$F8
        .byte   $CB,$03,$F8
        .byte   $F8
        .byte   $CC,$03,$00
        .byte   $F8
        .byte   $CD,$03,$08
        .byte   $11,$E0
        .byte   $CE,$03,$F0
        .byte   $E0,$CF
        .byte   $03,$F8,$E0,$D0,$03,$00,$E0,$D1
        .byte   $03,$08,$E8,$D2,$03,$F0,$E8
        .byte   $A2,$03
        .byte   $F8
        .byte   $E8
        .byte   $D3,$03,$00,$E8,$D4,$03,$08,$F0
        .byte   $D5,$03,$F0,$F0,$A6,$03,$F8,$F0
        .byte   $A7,$03,$00,$F0,$C9,$03,$08,$F0
        .byte   $C0,$01
        .byte   $FA,$F8,$CA,$03,$F0,$F8,$CB,$03
        .byte   $F8,$F8,$CC,$03,$00,$F8,$CD,$03
        .byte   $08
main_stage_render:
        jsr     clear_oam_buffer_fixed
        lda     #$00
        jsr     weapon_palette_copy_indexed
        lda     $B5
        pha
        lda     camera_y_offset
        pha
        lda     $B7
        pha
        lda     camera_x_offset
        pha
        lda     camera_x_offset_hi
        pha
        lda     nametable_select
        pha
        lda     scroll_x
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
        sta     camera_x_offset
        sta     $B7
        sta     $B5
        sta     camera_y_offset
        lda     current_stage
        cmp     #$04
        bne     wselect_check_boss_stage
        lda     current_screen
        cmp     #$03
        bcc     wselect_check_boss_stage
        cmp     #$0F
        bcs     wselect_check_boss_stage
        cmp     #$07
        beq     wselect_check_boss_stage
        ldx     #$0F
        txa
wselect_clear_palette_loop:  sta     palette_ram,x
        dex
        bpl     wselect_clear_palette_loop
        inc     nametable_select

; =============================================================================
; Weapon Select — Boss Stage Palette Override
; =============================================================================
wselect_check_boss_stage:  lda     boss_phase
        beq     wselect_check_wily_10
        lda     boss_id
        cmp     #WILY_STAGE_START
        bcc     wselect_check_wily_10
        ldx     #$00
        stx     scroll_x
        cmp     #$0A
        beq     wselect_check_wily_10
        cmp     #$0B
        beq     wselect_check_wily_10
        inc     nametable_select
wselect_check_wily_10:  lda     #$0A
        cmp     current_stage
        bne     wselect_calc_scroll_pos
        lda     boss_phase
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
        lda     scroll_x
        adc     #$80
        and     #$E0
        ora     #$04
        sta     $52
        lda     nametable_select
        adc     #$00
        sta     $53
        ldx     #$00
wselect_column_loop:  stx     $FD
        clc
        lda     $52
        adc     wselect_column_offset,x
        sta     jump_ptr
        lda     $53
        adc     #$00
        sta     jump_ptr_hi
        lda     #$00
        sta     ppu_buffer_count
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
        ldx     current_stage
        lda     wselect_attr_per_stage,x
        sta     $0350
        lda     #$01
        sta     ppu_buffer_count
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
        ldx     current_weapon
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
        sta     temp_07
        lda     $FE
        beq     wselect_check_start
        lda     $9A
        sta     temp_07
        lda     $9B
        asl     temp_07
        rol     a
        asl     temp_07
        rol     a
        asl     temp_07
        rol     a
        sta     temp_07
wselect_check_start:  lda     p1_new_presses
        and     #$08                    ; Start button pressed?
        beq     wselect_check_dpad
        jmp     wselect_start_pressed

wselect_check_dpad:  lda     p1_new_presses
        and     #$30                    ; D-pad up/down new press?
        bne     wselect_dpad_pressed
        lda     controller_1
        and     #$30                    ; D-pad up/down new press?
        beq     wselect_clear_repeat
        sta     temp_00
        lda     p1_prev_buttons
        and     #$30                    ; D-pad up/down new press?
        cmp     temp_00
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
        lda     controller_1
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
        and     temp_07
        beq     wselect_move_right
        bne     wselect_update_and_vblank
wselect_move_left:  dec     $FD         ; Move cursor left
        bpl     wselect_check_valid_left
        stx     $FD
wselect_check_valid_left:  ldy     $FD
        beq     wselect_update_and_vblank
        lda     weapon_bitmask_table,y
        and     temp_07
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
        lda     current_etanks
        beq     wselect_clear_repeat
        dec     current_etanks
wselect_etank_fill_loop:  lda     ent_hp
        cmp     #MAX_HP                    ; Full health = 28 units
        beq     wselect_clear_repeat
        lda     frame_counter
        and     #$03
        bne     wselect_etank_frame
        inc     ent_hp
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
wselect_store_weapon:  stx     current_weapon
        jsr     clear_oam_buffer_fixed
        lda     column_index
        pha
        ldx     #$00
wselect_render_column:  stx     $FD
        clc
        lda     $52
        adc     wselect_column_offset,x
        sta     jump_ptr
        lda     $53
        adc     #$00
        sta     jump_ptr_hi
        lda     jump_ptr
        lsr     jump_ptr_hi
        ror     a
        lsr     jump_ptr_hi
        ror     a
        sta     jump_ptr
        and     #$3F
        sta     column_index
        clc
        lda     jump_ptr_hi
        adc     #$85
        sta     jump_ptr_hi
        lda     #$00
        sta     ppu_buffer_count
        jsr     metatile_column_render
        lda     $FD
        cmp     #$08
        bcs     wselect_render_default_col
        ldx     current_weapon
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
        jsr     weapon_palette_copy
        jsr     wait_for_vblank_0D
        pla
        sta     column_index
        lda     current_stage
        cmp     #$0A
        bne     wselect_restore_palette
        lda     boss_phase
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
        sta     scroll_x
        pla
        sta     nametable_select
        pla
        sta     camera_x_offset_hi
        pla
        sta     camera_x_offset
        pla
        sta     $B7
        pla
        sta     camera_y_offset
        pla
        sta     $B5
        lda     #$00
        sta     $AC
        sta     game_substate
        sta     ent_anim_frame
        sta     ent_anim_id
        lda     #ENTITY_AIR_TORNADO2
        sta     ent_type
        lda     #$03
        sta     game_mode
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
        sbc     scroll_x
        sta     jump_ptr
        ldy     #$00
wselect_load_header_oam:  lda     wselect_header_oam,y
        sta     oam_buffer,y
        iny
        cpy     #$14
        bne     wselect_load_header_oam
        lda     $9A
        asl     a
        ora     #$01
        sta     temp_07
        lda     #$05
        sta     temp_01
        ldx     #$00
        lda     $FE
        beq     wselect_build_boss_icons
        ldx     #$06
        lda     $9A
        sta     temp_07
        lda     $9B
        asl     temp_07
        rol     a
        asl     temp_07
        rol     a
        asl     temp_07
        rol     a
        sta     temp_07
wselect_build_boss_icons:  lda     temp_07
        sta     temp_02
        lda     #$44
        sta     temp_00
wselect_icon_oam_entry:  sta     oam_buffer,y
        lsr     temp_02
        bcs     wselect_icon_tile
        lda     #$F8
        sta     oam_buffer,y
wselect_icon_tile:  lda     wselect_icon_tile_ids,x
        sta     $0201,y
        lda     #$01
        sta     $0202,y
        lda     #$0C
        sta     $0203,y
        clc
        lda     temp_00
        adc     #$10
        sta     temp_00
        iny
        iny
        iny
        iny
        inx
        dec     temp_01
        bpl     wselect_icon_oam_entry
        lda     $FE
        bne     wselect_page2_labels
        ldx     #$00
wselect_load_labels_p1:  lda     wselect_label_oam_data,x
        sta     oam_buffer,y
        iny
        inx
        cpx     #$04
        bne     wselect_load_labels_p1
        sty     temp_00
        lda     #$44
        sta     temp_02
        lda     ent_hp
        jsr     hp_bar_draw_start
        lda     temp_07
        lsr     a
        sta     temp_04
        ldx     #$00
        lda     #$54
wselect_draw_hp_bar_p1:  stx     temp_03
        sta     temp_02
        lsr     temp_04
        bcc     wselect_hp_bar_next_p1
        jsr     hp_bar_draw_weapon
wselect_hp_bar_next_p1:  clc
        lda     temp_02
        adc     #$10
        ldx     temp_03
        inx
        cpx     #$05
        bne     wselect_draw_hp_bar_p1
        ldy     temp_00
        lda     current_etanks
        beq     wselect_jump_to_cursor
        sta     temp_02
        lda     #MAX_HP
wselect_draw_etank_loop:  sta     temp_01
        lda     #$A4
        sta     oam_buffer,y
        lda     #$13
        sta     $0201,y
        lda     #$00
        sta     $0202,y
        lda     temp_01
        sta     $0203,y
        iny
        iny
        iny
        iny
        clc
        lda     temp_01
        adc     #$10
        dec     temp_02
        bne     wselect_draw_etank_loop
wselect_jump_to_cursor:  jmp     wselect_cursor_blink

wselect_page2_labels:  ldx     #$04
wselect_load_labels_p2:  lda     wselect_label_oam_data,x
        sta     oam_buffer,y
        iny
        inx
        cpx     #$18
        bne     wselect_load_labels_p2
        sty     temp_00
        lda     temp_07
        sta     temp_04
        ldx     #$05
        lda     #$44
wselect_draw_hp_bar_p2:  stx     temp_03
        sta     temp_02
        lsr     temp_04
        bcc     wselect_hp_bar_next_p2
        jsr     hp_bar_draw_weapon
wselect_hp_bar_next_p2:  clc
        lda     temp_02
        adc     #$10
        ldx     temp_03
        inx
        cpx     #$0B
        bne     wselect_draw_hp_bar_p2
        lda     current_lives
        sta     temp_01
        dec     temp_01
        lda     #$0A
        sta     temp_02
        jsr     divide_8bit
        ldy     temp_00
        lda     #$A5
        sta     oam_buffer,y
        sta     $0204,y
        clc
        lda     temp_03
        adc     #$14
        sta     $0201,y
        clc
        lda     temp_04
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
        lda     frame_counter
        and     #$08                    ; Blink every 8 frames
        bne     wselect_cursor_offset
        ldy     #$20
wselect_cursor_offset:  sty     temp_00
        ldx     $FD
        bne     wselect_cursor_not_first
        lda     temp_00
        beq     wselect_adjust_positions
        lda     #$F8
        sta     oam_buffer
        jmp     wselect_adjust_positions

wselect_cursor_not_first:  dex
        txa
        asl     a
        asl     a
        tay
        lda     temp_00
        beq     wselect_adjust_positions
        lda     #$F8
        sta     $0214,y
wselect_adjust_positions:  ldx     #$00
wselect_adjust_x_loop:  clc
        lda     $0203,x
        adc     jump_ptr
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
hp_bar_draw_start:  sta     temp_01
        ldx     #$06
hp_bar_draw_entry:  lda     temp_02
        sta     oam_buffer,y
        sec
        lda     temp_01
        sbc     #$04
        bcs     hp_bar_store_remaining
        ldy     temp_01
        lda     #$00
        sta     temp_01
        lda     hp_bar_empty_tiles,y
        ldy     temp_00
        jmp     hp_bar_write_oam

hp_bar_store_remaining:  sta     temp_01
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
        sty     temp_00
        dex
        bpl     hp_bar_draw_entry
        rts

hp_bar_x_positions:  .byte   $4C,$44,$3C,$34,$2C,$24,$1C
hp_bar_empty_tiles:  .byte   $94,$93
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
wselect_label_oam_data:  .byte   $A4,$96
        .byte   $01,$0C
        .byte   $A0,$8D
        .byte   $00
        .byte   $18,$A0,$8D,$40,$20,$A8,$8E,$01
        .byte   $18,$A8,$8E,$41
        .byte   $20,$A4,$1E
        .byte   $01,$2C
wselect_weapon_pal_idx:  .byte   $98
        .byte   $9A
        .byte   $99,$9C,$98
        .byte   $98
        .byte   $9A
        .byte   $98
        .byte   $9B,$9B,$9B,$9B
weapon_bitmask_table:  .byte   $00,$01,$02,$04,$08,$10,$20,$40
boss_get_screen_init:
        lda     #$10
        sta     ppuctrl_shadow
        sta     PPUCTRL
        lda     #$06
        sta     ppumask_shadow
        sta     PPUMASK

; =============================================================================
; Boss Get Screen — PPU init, nametable fill, palette setup
; =============================================================================
boss_get_init_ppu:  lda     #$0F
        jsr     banked_entry
        jsr     reset_scroll_state
        lda     #$01
        jsr     chr_ram_bank_load
        lda     #$20
        sta     PPUADDR
        ldy     #$00
        sty     PPUADDR
boss_get_fill_nt_loop:  lda     wily_nametable_fill_tiles,y
        ldx     #$40
boss_get_fill_tile:  sta     PPUDATA
        dex
        bne     boss_get_fill_tile
        iny
        cpy     #$10
        bne     boss_get_fill_nt_loop
        lda     #$28
        sta     PPUADDR
        ldy     #$00
        sty     PPUADDR
        lda     #$AC
        sta     jump_ptr_hi
        lda     #$03
        jsr     ppu_fill_from_ptr
        ldx     #$1F
boss_get_load_palette:  lda     boss_get_palette_data,x
        sta     palette_ram,x
        dex
        bpl     boss_get_load_palette
        jsr     clear_oam_buffer
        lda     current_stage
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
        sta     ent_x_screen
        sta     $0441
        lda     #$D0
        sta     ent_x_px
        sta     $0461
        lda     #$68
        sta     ent_y_px
        lda     #$80
        sta     $04A1
        lda     #$00
        sta     ent_type
        sta     $0681
        sta     ent_x_sub
        sta     $0481
        sta     ent_y_sub
        sta     $04C1
        lda     #$01
        sta     $0401

; =============================================================================
; Boss Get — Walk-In Loop (both entities walk toward center)
; =============================================================================
boss_get_walk_loop:  clc
        lda     ent_x_sub
        adc     #$40                    ; Walk sub-pixel increment
        sta     ent_x_sub
        lda     ent_x_px
        adc     #$01
        sta     ent_x_px
        sta     $0461
        lda     ent_x_screen
        adc     #$00
        sta     ent_x_screen
        sta     $0441
        bne     boss_get_walk_frame
        lda     ent_x_px
        cmp     #$68                    ; Reached center X=$68?
        bcs     boss_get_walk_stop
boss_get_walk_frame:  jsr     update_animation_frame
        jsr     clear_oam_buffer
        ldx     #$00
        stx     temp_00
        jsr     entity_update_handler
        ldx     #$01
        jsr     entity_update_handler
        jsr     wait_for_vblank_0D
        jmp     boss_get_walk_loop

boss_get_walk_stop:  jsr     clear_oam_buffer
        ldx     #$00
        stx     temp_00
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
        stx     temp_00
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
        lda     ent_y_sub
        sbc     #$80                    ; Rise velocity sub-pixel
        sta     ent_y_sub
        lda     ent_y_px
        sbc     #$00
        sta     ent_y_px
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
        lda     ent_y_sub
        adc     #$80                    ; Descend velocity sub-pixel
        sta     ent_y_sub
        lda     ent_y_px
        adc     #$00
        sta     ent_y_px
        jsr     update_animation_frame
        jsr     update_all_entities
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     boss_get_land_loop
        lda     #$FD
        jsr     bank_switch_enqueue
        lda     #ENTITY_DEATH_EXPLODE
        sta     ent_type
        lda     #$01
        sta     ent_anim_id
        lda     #$00
        sta     $FD
        sta     ent_x_vel_sub
        lda     #$04
        sta     ent_x_vel

; =============================================================================
; Boss Get — Bounce Main (weapon orb bouncing physics)
; =============================================================================
boss_get_bounce_main:  lda     ent_anim_id
        bne     boss_get_bounce_up_entry
        ldx     #$00
        lda     ent_x_px
        cmp     #$68                    ; Center Y position check
        bcs     boss_get_bounce_down
        inx
boss_get_bounce_down:  clc
        lda     ent_x_vel_sub
        adc     bounce_accel_sub,x
        sta     ent_x_vel_sub
        lda     ent_x_vel
        adc     bounce_accel_whole,x
        sta     ent_x_vel
        sec
        lda     ent_x_sub
        sbc     ent_x_vel_sub
        sta     ent_x_sub
        lda     ent_x_px
        sbc     ent_x_vel
        sta     ent_x_px
        cmp     #$18
        bcs     boss_get_bounce_render
        bcc     boss_get_bounce_reverse
boss_get_bounce_up_entry:  ldx     #$00
        lda     ent_x_px
        cmp     #$68
        bcc     boss_get_bounce_up
        inx
boss_get_bounce_up:  clc
        lda     ent_x_vel_sub
        adc     bounce_accel_sub,x
        sta     ent_x_vel_sub
        lda     ent_x_vel
        adc     bounce_accel_whole,x
        sta     ent_x_vel
        clc
        lda     ent_x_sub
        adc     ent_x_vel_sub
        sta     ent_x_sub
        lda     ent_x_px
        adc     ent_x_vel
        sta     ent_x_px
        cmp     #$68
        bcc     boss_get_bounce_render
        ldx     $FD
        lda     bounce_entity_type,x
        sta     ent_type
        lda     ent_x_px
        cmp     #$B8
boss_get_bounce_check:  bcc     boss_get_bounce_render
boss_get_bounce_reverse:  lda     #$00
        sta     ent_x_vel
        sta     ent_x_vel_sub
        lda     ent_anim_id
        php
        eor     #$01                    ; Toggle bounce direction
        sta     ent_anim_id
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
        stx     temp_00
        jsr     entity_update_handler
        lda     ent_type
        bne     boss_get_apply_gravity
        lda     ent_x_px
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
boss_get_fall_init:  lda     #ENTITY_TANISHI
        sta     ent_type
boss_get_fall_loop:  clc
        lda     ent_x_vel_sub
        adc     #$18
        sta     ent_x_vel_sub
        lda     ent_x_vel
        adc     #$00
        sta     ent_x_vel
        sec
        lda     ent_x_sub
        sbc     ent_x_vel_sub
        sta     ent_x_sub
        lda     ent_x_px
        sbc     ent_x_vel
        sta     ent_x_px
        cmp     #$68
        bcc     boss_get_fall_done
        jsr     clear_oam_buffer
        ldx     #$00
        stx     temp_00
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
        sta     palette_ram,x
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
        ldx     current_stage
        lda     boss_get_scroll_start,x
        sta     $FD
        lda     #$3E
        sta     $FE
boss_get_title_scroll_start:  lda     $FD
        sta     temp_00
        jsr     boss_get_title_render
        jsr     wait_for_vblank_0D
        dec     $FE
        bne     boss_get_title_scroll_start

; =============================================================================
; Boss Get — Title Scroll Loop (letter-by-letter reveal)
; =============================================================================
boss_get_title_scroll_loop:  lda     frame_counter
        and     #$03                    ; Scroll every 4 frames
        bne     boss_get_title_frame
        lda     #$28
        jsr     bank_switch_enqueue
        clc
        lda     $FD
        adc     #$04                    ; Advance 4 pixels per step
        sta     $FD
        ldx     current_stage
        cmp     boss_get_scroll_end,x
        beq     boss_get_title_hold_start
boss_get_title_frame:  lda     $FD
        sta     temp_00
        jsr     boss_get_title_render
        jsr     wait_for_vblank_0D
        jmp     boss_get_title_scroll_loop

boss_get_title_hold_start:  lda     #$7D
        sta     $FE
boss_get_title_hold_frame:  lda     $FD
        sta     temp_00
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
        stx     temp_00
update_all_entity_inner:  stx     current_entity_slot
        jsr     entity_update_handler
        ldx     current_entity_slot
        inx
        cpx     #$03
        bne     update_all_entity_inner
        rts

; =============================================================================
; Apply Gravity — downward acceleration with terminal velocity
; =============================================================================
apply_gravity:  lda     scroll_y             ; Apply downward acceleration to entity
        bne     gravity_accelerate
        lda     $AE
        bne     gravity_rts
gravity_accelerate:  clc
        lda     scroll_y_page
        adc     #$80
        sta     scroll_y_page
        lda     scroll_y
        adc     #$00
        cmp     #$F0
        bne     gravity_store
        lda     #$02
        sta     $AE
        lda     #$00
gravity_store:  sta     scroll_y
        lda     scroll_y
        bne     gravity_rts
gravity_rts:  rts

; =============================================================================
; Render Stars Overlay — draw background star sprites
; =============================================================================
render_stars_overlay:  lda     $AE
        bne     stars_overlay_with_offset
        sec
        lda     #$5F
        sbc     scroll_y
        sta     temp_01
        lda     #$01
        sbc     #$00
        beq     stars_overlay_setup
        rts

stars_overlay_with_offset:  lda     #$6F
        sta     temp_01
stars_overlay_setup:  lda     #$05
        sta     temp_02
        ldx     #$00
stars_overlay_loop:  clc
        lda     star_y_offset,x
        adc     temp_01
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
        dec     temp_02
        bne     stars_overlay_loop
        rts

; =============================================================================
; Boss Get Title Render — draw header OAM and letter sprites
; =============================================================================
boss_get_title_render:  jsr     clear_oam_buffer
        ldx     #$23
boss_get_title_oam_load:  lda     boss_get_header_oam,x
        sta     oam_buffer,x
        dex
        bpl     boss_get_title_oam_load
        lda     temp_00
        beq     boss_get_title_rts
        ldy     #$00
boss_get_title_letter_loop:  lda     boss_get_letter_oam,y
        sta     $0224,y
        iny
        inx
        dec     temp_00
        bne     boss_get_title_letter_loop
        lda     frame_counter
        and     #$08
        bne     boss_get_title_rts
        lda     current_stage
        cmp     #$0C
        bcs     boss_get_title_markers
        sec
        lda     current_stage
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
        lda     current_stage
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
entity_update_handler:  ldy     ent_type,x
        lda     entity_sprite_ptr_lo,y
        sta     jump_ptr
        lda     entity_sprite_ptr_hi,y
        sta     jump_ptr_hi
        lda     ent_x_px,x
        sta     $0A
        lda     ent_x_screen,x
        sta     $0B
        lda     ent_y_px,x
        sta     $0C
        ldy     #$00
        lda     (jump_ptr),y
        iny
        sta     $0D
        ldx     temp_00
entity_oam_loop:  clc
        lda     (jump_ptr),y
        adc     $0C
        sta     oam_buffer,x
        iny
        lda     (jump_ptr),y
        sta     $0201,x
        iny
        lda     (jump_ptr),y
        sta     $0202,x
        iny
        clc
        lda     (jump_ptr),y
        adc     $0A
        sta     temp_01
        lda     $0B
        adc     #$00
        beq     entity_oam_store_x
        lda     #$F8
        sta     oam_buffer,x
        bne     entity_oam_next_sprite
entity_oam_store_x:  lda     temp_01
        sta     $0203,x
        inx
        inx
        inx
        inx
entity_oam_next_sprite:  iny
        dec     $0D
        bne     entity_oam_loop
        stx     temp_00
        rts

; =============================================================================
; Wily Intro Palette Clear — fill palette RAM with $0F (black)
; =============================================================================
wily_intro_palette_clear:  ldx     #$1F
        lda     #$0F
wily_intro_clear_pal:  sta     palette_ram,x
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
        sta     palette_ram,y
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
        .byte   $BD,$E6,$0F
        .byte   $0F,$50,$61,$6A
entity_sprite_ptr_hi:  .byte   $9B,$9C,$9C,$9C,$9C,$9C,$9D,$9D
        .byte   $9D,$9D,$9D,$10,$00,$48,$03,$08
        .byte   $00,$49,$03,$10,$00
        .byte   $49,$43
        .byte   $18
        .byte   $00
        .byte   $48,$43,$20,$08,$4A,$03,$00,$08
        .byte   $4B,$03,$08,$08
        .byte   $4C,$03,$10

        .byte   $08,$4C,$43,$18,$08,$4B,$43,$20
        .byte   $08,$4A,$43,$28,$10,$4D,$03,$00
        .byte   $10,$4E,$03,$08,$10,$4F,$03,$10
        .byte   $10,$4F,$43,$18,$10,$4E,$43,$20
        .byte   $10,$4D,$43,$28,$0C,$00,$50,$02
        .byte   $00
        .byte   $00
        .byte   $51,$02
        .byte   $08
        .byte   $00
        .byte   $52,$02,$10,$00,$52,$42,$18,$00
        .byte   $51,$42
        .byte   $20,$00,$50
        .byte   $42,$28,$08,$53,$02,$00,$08,$54
        .byte   $02,$08,$08,$55,$02,$10,$08,$55
        .byte   $42,$18,$08,$54,$42,$20,$08,$53
        .byte   $42,$28,$0C,$00,$56,$02,$00,$00
        .byte   $57,$02,$08,$00,$58,$02,$10,$00
        .byte   $59,$02,$18
        .byte   $00
        .byte   $5A,$02,$20,$00,$5B,$02,$28,$08
        .byte   $53,$02,$00,$08,$54,$02,$08,$08
        .byte   $55,$02,$10,$08,$55,$42,$18,$08
        .byte   $54,$42,$20,$08,$53,$42,$28,$0C
        .byte   $00,$5B,$42,$00,$00,$5A,$42,$08
        .byte   $00,$59,$42,$10,$00,$58,$42
        .byte   $18
        .byte   $00
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
        .byte   $08
        .byte   $08
        .byte   $44,$01,$10,$08,$45,$01,$18,$08
        .byte   $6A,$43,$20
        .byte   $10,$08
        .byte   $5C,$03,$08,$08,$5D,$03,$10
        .byte   $08
sprite_data_9D19:  .byte   $5D,$43,$18
        .byte   $08
        .byte   $5C,$43
        .byte   $20,$10,$5E
        .byte   $03,$08,$10,$5F,$03,$10,$10,$5F
        .byte   $43,$18,$10,$5E,$43,$20,$18,$60
        .byte   $02,$08,$18,$61,$02,$10,$18
        .byte   $61,$42
        .byte   $18
        .byte   $18
        .byte   $60

        .byte   $42,$20,$20,$62,$02,$08,$20,$63
        .byte   $02,$10,$20,$63,$42,$18,$20,$62
        .byte   $42,$20,$04
        .byte   $10,$64
        .byte   $03,$10,$10,$64,$43,$18,$18,$65
        .byte   $02,$10,$18,$65,$42,$18,$02,$10
        .byte   $66,$03,$14,$18,$67,$02,$14,$01
        .byte   $14,$68,$03,$14
star_y_offset:  .byte   $00
star_tile_1:  .byte   $6B
star_attr:  .byte   $00
star_x_offset:  .byte   $60,$00,$6C,$00
        .byte   $68
        .byte   $00
        .byte   $6D,$00,$70
        .byte   $08
        .byte   $6E
data_9D7D:  .byte   $00
        .byte   $60

        .byte   $08
        .byte   $6F,$00,$68
bounce_entity_type:  .byte   $00,$00,$07,$08,$09
bounce_accel_sub:  .byte   $18,$E9
bounce_accel_whole:  .byte   $00,$FF
boss_get_header_oam:  .byte   $C0,$73
        .byte   $02,$10,$88,$73,$02,$40,$A0,$73
        .byte   $02,$60,$A8,$73,$02,$88
data_9D9C:  .byte   $70,$73
        .byte   $02,$98,$8C,$75,$02,$B4,$8C,$75
        .byte   $42,$BC
boss_get_scroll_start:  .byte   $94
boss_get_scroll_end:  .byte   $76,$02
        .byte   $B4
        .byte   $94,$76
        .byte   $42,$BC,$00,$30,$48,$5C,$7C,$98
        .byte   $D0
boss_get_letter_oam:  .byte   $C0,$71
        .byte   $03
        clc
        cpy     #$70
        .byte   $C3,$20,$B8,$72,$03,$20,$B0,$72
        .byte   $03,$20,$A8,$72,$03
        .byte   $20,$A0,$72
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
        adc     (temp_03),y
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
        .byte   $0F,$00,$06,$0F,$0F,$00,$01,$0F
        .byte   $0F,$0F,$09,$0F,$0F,$0F,$00,$08
        .byte   $0F,$0F,$08,$00,$0F,$0F,$00,$0C
        .byte   $0F,$10,$11,$11,$0F,$10,$00,$00
        .byte   $0F,$10,$16,$05,$0F,$07,$11,$00
        .byte   $0F,$06,$19,$00,$0F,$0F,$10,$18
        .byte   $0F,$0F,$18,$10,$0F
        .byte   $0F,$02,$1C,$0F
        .byte   $20,$21,$11
        .byte   $0F,$20,$10,$00,$0F,$20,$26,$15
        .byte   $0F,$17,$21,$07,$0F,$16,$29,$09
        .byte   $0F,$0F,$30,$38,$0F,$0F,$28,$30
        .byte   $0F,$0F,$12,$2C
wily_intro_init:
        lda     #$10
        sta     ppuctrl_shadow
        sta     PPUCTRL
        lda     #$06
        sta     ppumask_shadow
        sta     PPUMASK
        lda     #$0F
        jsr     banked_entry
        jsr     reset_scroll_state
        lda     #$00
        sta     $BE
        lda     #$02
        jsr     chr_ram_bank_load
        lda     #$20
        sta     PPUADDR
        ldx     #$00
        stx     PPUADDR
        txa
        ldy     #$04

; =============================================================================
; Credits Screen — PPU clear, tile layout, fade sequence
; =============================================================================
credits_ppu_write_loop:  sta     PPUDATA
        inx
        bne     credits_ppu_write_loop
        dey
        bne     credits_ppu_write_loop
        lda     #$0F
        ldx     #$1F
credits_clear_palette:  sta     palette_ram,x
        dex
        bpl     credits_clear_palette
        lda     #$04
        sta     temp_00
        ldx     #$00
credits_load_tiles_outer:  ldy     credits_tile_layout_data,x
        inx
        lda     credits_tile_layout_data,x
        sta     PPUADDR
        inx
        lda     credits_tile_layout_data,x
        sta     PPUADDR
        inx
credits_load_tiles_inner:  lda     credits_tile_layout_data,x
        sta     PPUDATA
        inx
        dey
        bne     credits_load_tiles_inner
        dec     temp_00
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
        lda     p1_new_presses
        and     #$08
        beq     credits_fade_next
        jmp     credits_skip_init

credits_fade_next:  dec     $FF
        bne     credits_fade_inner
        dec     $FE
        bpl     credits_fade_outer
        lda     #$00
        sta     col_update_count
        jsr     disable_nmi_and_rendering
        lda     #$00
        sta     $AE
        lda     #$07
        sta     current_stage
        lda     #$00
        sta     jump_ptr
        lda     #$8A
        sta     jump_ptr_hi
        lda     #$00
        sta     column_index
        sta     ppu_buffer_count

; =============================================================================
; Credits — Scroll Right and Render Metatile Columns
; =============================================================================
credits_scroll_right_loop:  jsr     metatile_column_render
        inc     jump_ptr
        inc     column_index
        jsr     metatile_column_render
        jsr     ppu_buffer_and_increment
        lda     jump_ptr
        and     #$3F
        bne     credits_scroll_right_loop
        lda     #$40
        sta     jump_ptr
        lda     #$8A
        sta     jump_ptr_hi
        lda     #$00
        sta     column_index
        sta     ppu_buffer_count

; =============================================================================
; Credits — Scroll Advance with PPU Buffer Update
; =============================================================================
credits_scroll_advance:  jsr     metatile_column_render
        clc
        lda     ppu_update_buf
        adc     #$04
        sta     ppu_update_buf
        clc
        lda     $0308
        adc     #$04
        sta     $0308
        jsr     ppu_buffer_and_increment
        lda     jump_ptr
        and     #$3F
        bne     credits_scroll_advance
        ldx     #$1F
        lda     #$0F
credits_clear_pal_2:  sta     palette_ram,x
        dex
        bpl     credits_clear_pal_2
        jsr     clear_oam_buffer
        jsr     enable_nmi_and_rendering
        ldx     #$0F
        lda     #$00
credits_clear_entities:  sta     ent_x_screen,x
        sta     ent_type,x
        dex
        bpl     credits_clear_entities
        lda     #$80
        sta     ent_y_sub
        lda     #$00
        sta     ent_y_px
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
        sta     ent_y_vel_sub
        lda     #$00
        sta     ent_y_vel
        lda     #$00
        sta     $AE
        lda     #$00
        sta     scroll_y
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
        sta     palette_ram,y
        inx
        iny
        cpy     #$20
        bne     ending_fade_pal_load
        cpx     #$60
        beq     ending_column_init
        stx     $FD
ending_fade_frame:  jsr     ending_render_all_sprites
        jsr     wait_for_vblank_0D
        lda     p1_new_presses
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
        sta     col_update_addr_hi
        lda     #$03
        sta     col_update_addr_lo
        jsr     wait_for_vblank_0D
        lda     p1_new_presses
        and     #$08
        beq     ending_column_second
        .byte   $4C                     ; JMP credits_skip_init — overlap: $4C eats BCS bytes as target $A7B0
ending_column_skip:  bcs     ending_fade_speed
ending_column_second:  jsr     ending_column_data_load
        lda     #$23
        sta     col_update_addr_hi
        lda     #$43
        sta     col_update_addr_lo
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
        lda     p1_new_presses
        and     #$08
        beq     ending_text_fade_loop
        jmp     credits_skip_init

ending_column_check:  lda     $FD
        cmp     #$0E
        bne     ending_column_main
        lda     #$02
        sta     $AE
        lda     #$F0
        sta     scroll_y

; =============================================================================
; Ending — Fall Acceleration (Wily castle crumbles)
; =============================================================================
ending_fall_accel:  sec
        lda     scroll_y_page
        sbc     #$80
        sta     scroll_y_page
        lda     scroll_y
        sbc     #$00
        sta     scroll_y
        bcc     ending_fall_decel_init
        cmp     #$40
        bcs     ending_fall_check_col
        jsr     ending_attr_or_column
ending_fall_check_col:  jsr     ending_update_entities
        jsr     ending_render_all_sprites
        jsr     wait_for_vblank_0D
        lda     p1_new_presses
        and     #$08
        beq     ending_fall_accel
        jmp     credits_skip_init

; =============================================================================
; Ending — Fall Deceleration and Landing Init
; =============================================================================
ending_fall_decel_init:  lda     #$F0
        sta     scroll_y
        lda     #$00
        sta     scroll_y_page
        sta     $AE
ending_fall_decel_loop:  sec
        lda     scroll_y_page
        sbc     #$80
        sta     scroll_y_page
        lda     scroll_y
        sbc     #$00
        sta     scroll_y
        cmp     #$C0
        beq     ending_landing_init
        jsr     ending_update_entities
        jsr     ending_render_all_sprites
        jsr     wait_for_vblank_0D
        lda     p1_new_presses
        and     #$08
        beq     ending_fall_decel_loop
        jmp     credits_skip_init

; =============================================================================
; Ending — Landing (scroll down to ground level)
; =============================================================================
ending_landing_init:  ldx     #$0F
ending_landing_pal_load:  lda     ending_black_palette,x
        sta     palette_ram,x
        dex
        bpl     ending_landing_pal_load
        lda     #$00
        sta     ent_spawn_type
        lda     #$08
        sta     $0690
        lda     #$FF
        sta     ent_x_spawn_scr
        lda     #$B7
        sta     ent_y_spawn_px
ending_landing_scroll:  sec
        lda     scroll_y
        sbc     #$02                    ; Scroll down 2px per frame
        sta     scroll_y
        jsr     ending_update_entities
        lda     scroll_y
        beq     ending_scroll_columns
        jsr     ending_render_all_sprites
        jsr     ending_advance_anim
        jsr     ending_render_boss_sprite
        jsr     wait_for_vblank_0D
        lda     p1_new_presses
        and     #$08
        beq     ending_landing_scroll
        jmp     credits_skip_init

; =============================================================================
; Ending — Scroll Columns (grass fills from bottom)
; =============================================================================
ending_scroll_columns:  lda     #$50
        sta     $FD
        lda     #$00
        sta     col_update_addr_lo
        sta     $FE
        lda     #$10
        sta     col_update_addr_hi
        lda     #$B0
        sta     $FF
ending_scroll_col_loop:  jsr     ending_advance_anim
        jsr     ending_render_all_sprites
        jsr     ending_render_boss_sprite
        jsr     ppu_column_fill
        jsr     wait_for_vblank_0D
        clc
        lda     col_update_addr_lo
        adc     #$20
        sta     col_update_addr_lo
        lda     col_update_addr_hi
        adc     #$00
        sta     col_update_addr_hi
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
        sta     palette_ram,x
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
        sta     $CB                     ; default to Normal (0) for next playthrough
ending_main_loop:  lda     p1_new_presses
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
        ldx     $CB                     ; 0=Normal cursor, 1=Difficult cursor
        ldy     #$F8
        lda     frame_counter
        and     #$08
        beq     ending_cursor_y
        ldy     ending_cursor_y_table,x
ending_cursor_y:  sty     $0280
        lda     p1_new_presses
        and     #$34                    ; D-pad or A/B = toggle selection
        beq     ending_timer_tick
        txa
        eor     #$01                    ; flip between Normal (0) and Difficult (1)
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
ending_teleport_loop:  lda     frame_counter
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
        sta     ent_spawn_type
        jsr     ending_render_all_sprites
        jsr     ending_render_boss_sprite
        jsr     wait_for_vblank_0D
        jmp     ending_teleport_loop

; =============================================================================
; Ending — Fly Away (Mega Man rises off screen)
; =============================================================================
ending_fly_away:  lda     #$0A
        sta     ent_spawn_type
        sec
        lda     ent_y_spawn_px
        sbc     #$08                    ; Rise 8 pixels per frame
        sta     ent_y_spawn_px
        lda     ent_x_spawn_scr
        sbc     #$00
        sta     ent_x_spawn_scr
        beq     ending_fly_render
        lda     ent_y_spawn_px
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
        sta     current_stage
        lda     #$40
        sta     jump_ptr
        lda     #$8D
        sta     jump_ptr_hi
        jsr     metatile_column_render_loop
        lda     #$80
        sta     jump_ptr
        lda     #$8D
        sta     jump_ptr_hi
        jsr     metatile_column_render_loop
        ldx     #$00
password_load_tiles:  lda     password_ppu_layout_data,x
        sta     PPUADDR
        lda     password_ppu_layout_data_2,x
        sta     PPUADDR
        inx
        inx
        ldy     password_ppu_layout_data,x
        inx
password_tile_inner:  lda     password_ppu_layout_data,x
        sta     PPUDATA
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
        sta     oam_buffer,x
        dex
        bpl     password_load_cursor_oam
        lda     frame_counter
        and     #$08
        bne     password_check_input
        ldx     #$60
        lda     $FD
        beq     password_cursor_x_pos
        ldx     #$70
password_cursor_x_pos:  stx     oam_buffer
password_check_input:  lda     p1_new_presses
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
        sta     oam_buffer,x
        dex
        bpl     password_draw_grid_oam
        lda     #$00
        ldx     #$18
password_clear_dots:  sta     ent_flags,x
        dex
        bpl     password_clear_dots
        jsr     password_init_dot_oam
        jsr     palette_fade_in
        lda     #$00
        sta     ent_anim_id
        lda     #$09
        sta     ent_anim_frame
        lda     #$00
        sta     $FE

; =============================================================================
; Password Entry Loop — D-pad movement, dot placement, A/B input
; =============================================================================
password_entry_loop:  lda     p1_new_presses
        and     #$F0                    ; D-pad new press?
        bne     password_dpad_pressed
        lda     controller_1
        and     #$F0                    ; D-pad new press?
        beq     password_clear_repeat
        lda     p1_prev_buttons
        cmp     controller_1
        bne     password_clear_repeat
        inc     $FE
        lda     $FE
        cmp     #$18                    ; Auto-repeat delay (24 frames)
        bcc     password_check_ab
        lda     #$08
        sta     $FE
password_dpad_pressed:  lda     #$2F
        jsr     bank_switch_enqueue
        ldx     ent_anim_id
        lda     controller_1
        and     #$C0
        beq     password_check_up
        and     #$80
        beq     password_move_left
        lda     cursor_move_right_table,x
        jmp     password_store_position

password_move_left:  lda     cursor_move_left_table,x
        jmp     password_store_position

password_check_up:  lda     controller_1
        and     #$10
        beq     password_move_down
        lda     cursor_move_up_table,x
        jmp     password_store_position

password_move_down:  lda     cursor_move_down_table,x
password_store_position:  sta     ent_anim_id
        jmp     password_check_ab

password_clear_repeat:  lda     #$00
        sta     $FE
password_check_ab:  lda     p1_new_presses
        and     #$03
        beq     password_render_grid
        lda     p1_new_presses
        .byte   $AE
        .byte   $A0
password_dot_data:  asl     current_bank
        ora     ($F0,x)
        .byte   $14
        lda     ent_flags,x
        bne     password_render_grid
        lda     #$42
        jsr     bank_switch_enqueue
        inc     ent_flags,x
        dec     ent_anim_frame
        beq     password_all_dots_placed
        bne     password_render_grid
        lda     ent_flags,x
        beq     password_render_grid
        dec     ent_flags,x
        inc     ent_anim_frame
password_render_grid:  jsr     password_render_sprites
        jsr     wait_for_vblank_0D
        jmp     password_entry_loop

; =============================================================================
; Password All Dots Placed — decode and validate password
; =============================================================================
password_all_dots_placed:  jsr     password_render_sprites
        lda     #$0F
        sta     $036C
        ; Decode E-tank count from password grid: scan cells 0-3 for first dot.
        ; The dot position = number of E-tanks (0-3). This also sets the
        ; starting offset for the 20-cell boss data region (E-tanks + 5).
        ldx     #$00
password_find_etanks:  lda     ent_flags,x
        bne     password_store_etanks
        inx
        cpx     #$04
        bne     password_find_etanks
password_store_etanks:  stx     temp_04         ; temp_04 = E-tank count (0-3)
        ; Start data decode at cell (E-tanks + 5), wrapping 24→5.
        ; 20 cells encode 16 meaningful bits via scrambled lookup tables:
        ; 8 bits of beaten boss flags → temp_02, 8 bits complement → temp_03.
        txa
        clc
        adc     #$05
        tax
        lda     #$00
        sta     temp_01
        sta     temp_02
        sta     temp_03
password_decode_loop:  lda     ent_flags,x
        beq     password_decode_next
        ldy     temp_01
        lda     password_bit_mask_table,y
        pha
        lda     password_byte_index_table,y
        tay
        pla
        ora     temp_02,y
        sta     temp_02,y
password_decode_next:  inx
        cpx     #$19
        bne     password_decode_inc
        ldx     #$05                    ; wrap from cell 24 back to cell 5
password_decode_inc:  inc     temp_01
        lda     temp_01
        cmp     #$14                    ; 20 data positions
        bne     password_decode_loop
        lda     temp_02                 ; validation: data OR complement must = $FF
        ora     temp_03
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
password_valid:  lda     temp_02         ; temp_02 = beaten boss flags (8 bits in $9A)
        sta     $9A
        and     #$03                    ; extract $9B: bits 0-1 from $9A
        sta     $9B
        lda     $9A
        and     #$20                    ; bit 5 of $9A → bit 2 of $9B
        lsr     a
        lsr     a
        lsr     a
        ora     $9B
        sta     $9B                     ; $9B = derived boss flags (3 bits)
        lda     temp_04
        sta     current_etanks          ; restore E-tank count from password
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
        sta     temp_01
        lda     $9B
        sta     temp_02
        ldx     #$00
        beq     password_beaten_sprite
password_show_beaten:  lsr     temp_02
        ror     temp_01
        bcs     password_beaten_sprite
        inx
        inx
        inx
        inx
        bne     password_beaten_check
password_beaten_sprite:  ldy     #$04
password_beaten_loop:  lda     password_beaten_oam_data,x
        sta     oam_buffer,x
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
enable_nmi_and_rendering:  lda     ppumask_shadow
        ora     #$18
        sta     ppumask_shadow
        lda     ppuctrl_shadow
        ora     #$80
        sta     ppuctrl_shadow
        sta     PPUCTRL
        rts

; =============================================================================
; Disable NMI and Rendering — clear ppuctrl + ppumask bits
; =============================================================================
disable_nmi_and_rendering:  lda     #$10
        sta     ppuctrl_shadow
        sta     PPUCTRL
        lda     #$06
        sta     ppumask_shadow
        sta     PPUMASK
        rts

; =============================================================================
; PPU Buffer and Increment — transfer buffer then advance pointer
; =============================================================================
ppu_buffer_and_increment:  lda     jump_ptr
        pha
        lda     jump_ptr_hi
        pha
        lda     ppu_buffer_count
        jsr     ppu_buffer_transfer
        clc
        pla
        sta     jump_ptr_hi
        pla
        sta     jump_ptr
        inc     jump_ptr
        inc     column_index
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
        sta     col_update_tiles,x
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
        stx     col_update_count
        sty     $FD
        rts

; =============================================================================
; Ending Attr or Column — write attribute or nametable column data
; =============================================================================
ending_attr_or_column:  sta     temp_00
        lda     temp_00
        and     #$01
        beq     ending_nametable_column
        lda     temp_00
        eor     #$3F
        tax
        lda     wily_castle_attr_data,x
        sta     $03B9
        lda     wily_castle_attr_data_2,x
        sta     col_update_tiles
        lda     #$23
        sta     col_update_addr_hi
        ldx     temp_00
        dex
        txa
        ora     #$C0
        sta     col_update_addr_lo
        lda     #$02
        sta     col_update_count
        rts

ending_nametable_column:  lda     temp_00
        lsr     a
        cmp     #$1E
        bcc     ending_column_calc_addr
        rts

ending_column_calc_addr:  asl     a
        asl     a
        asl     a
        asl     a
        rol     jump_ptr
        asl     a
        rol     jump_ptr
        sta     col_update_addr_lo
        lda     jump_ptr
        and     #$03
        ora     #$20
        sta     col_update_addr_hi
        lda     temp_00
        lsr     a
        eor     #$1F
        sta     jump_ptr_hi
        lda     #$00
        lsr     jump_ptr_hi
        ror     a
        lsr     jump_ptr_hi
        ror     a
        lsr     jump_ptr_hi
        ror     a
        sta     jump_ptr
        clc
        lda     jump_ptr
        adc     #$F1
        sta     jump_ptr
        lda     jump_ptr_hi
        adc     #$B2
        sta     jump_ptr_hi
        ldy     #$1F
ending_column_copy_loop:  lda     (jump_ptr),y
        sta     col_update_tiles,y
        dey
        bpl     ending_column_copy_loop
        lda     #$20
        sta     col_update_count
        rts

; =============================================================================
; Ending Advance Animation — tick boss walk animation counter
; =============================================================================
ending_advance_anim:  dec     $0690
        bne     ending_anim_rts
        lda     #$05
        sta     $0690
        inc     ent_spawn_type
        lda     ent_spawn_type
        cmp     #$02
        bne     ending_anim_rts
        lda     #$00
        sta     ent_spawn_type
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
ending_entity_loop:  stx     current_entity_slot
        lda     ent_type,x
        beq     ending_entity_next
        clc
        lda     ent_y_sub,x
        adc     ent_y_vel_sub
        sta     ent_y_sub,x
        lda     ent_y_px,x
        adc     ent_y_vel
        sta     ent_y_px,x
        lda     ent_x_screen,x
        adc     #$00
        sta     ent_x_screen,x
        bne     ending_entity_next
        lda     ent_y_px,x
        cmp     #$E8
        bcc     ending_entity_next
        lda     #$00
        sta     ent_type,x
ending_entity_next:  ldx     current_entity_slot
        inx
        cpx     #$0F
        bne     ending_entity_loop
        lda     $AE
        bne     ending_player_gravity
        lda     scroll_y
        cmp     #$A8
        bcc     ending_gravity_accel
ending_player_gravity:  sec
        lda     ent_y_sub
        sbc     ent_y_vel_sub
        sta     ent_y_sub
        lda     ent_y_px
        sbc     ent_y_vel
        sta     ent_y_px
        bcs     ending_player2_gravity
        lda     #$01
        jsr     ending_spawn_entity
        lda     #$00
        sta     ent_y_sub
        lda     #$48
        sta     ent_y_px
ending_player2_gravity:  sec
        lda     $04C1
        sbc     ent_y_vel_sub
        sta     $04C1
        lda     $04A1
        sbc     ent_y_vel
        sta     $04A1
        bcs     ending_gravity_accel
        lda     #$02
        jsr     ending_spawn_entity
        lda     #$00
        sta     $04C1
        lda     #$48
        sta     $04A1
ending_gravity_accel:  clc
        lda     ent_y_vel_sub
        adc     #$02
        sta     ent_y_vel_sub
        lda     ent_y_vel
        adc     #$00
        sta     ent_y_vel
        cmp     #$02
        bne     ending_boss_fall
        lda     #$00
        sta     ent_y_vel_sub
ending_boss_fall:  clc
        lda     ent_y_spawn_px
        adc     ent_y_vel
        sta     ent_y_spawn_px
        lda     ent_x_spawn_scr
        adc     #$00
        sta     ent_x_spawn_scr
        rts

; =============================================================================
; Ending Spawn Entity — find empty slot and init new entity
; =============================================================================
ending_spawn_entity:  sta     temp_00
        ldx     #$02
ending_find_empty_slot:  lda     ent_type,x
        beq     ending_init_entity
        inx
        cpx     #$0F
        bne     ending_find_empty_slot
        rts

ending_init_entity:  lda     temp_00
        sta     ent_type,x
        lda     #$FF
        sta     ent_x_screen,x
        lda     #$E0
        sta     ent_y_px,x
        lda     #$00
        sta     ent_y_sub,x
        rts

; =============================================================================
; Ending Render All Sprites — clear OAM, draw all entity sprites
; =============================================================================
ending_render_all_sprites:  jsr     clear_oam_buffer
        lda     #$00
        sta     temp_00
        ldx     #$02
ending_entity_render_loop:  stx     current_entity_slot
        lda     ent_type,x
        beq     ending_entity_render_next
        ldy     ent_y_px,x
        sty     jump_ptr
        ldy     ent_x_screen,x
        sty     jump_ptr_hi
        ldx     #$00
        ldy     #$0C
        cmp     #$01
        beq     ending_render_entry
        ldy     #$04
        ldx     #$30
ending_render_entry:  sty     temp_02
        ldy     temp_00
ending_oam_write_loop:  clc
        lda     jump_ptr
        adc     entity_sprite_y_offset,x
        sta     oam_buffer,y
        lda     jump_ptr_hi
        adc     #$00
        beq     ending_oam_tile_write
        lda     #$F8
        sta     oam_buffer,y
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
        dec     temp_02
        bne     ending_oam_write_loop
        sty     temp_00
ending_entity_render_next:  ldx     current_entity_slot
        inx
        cpx     #$0F
        bne     ending_entity_render_loop
        rts

; =============================================================================
; Ending Render Boss Sprite — draw Wily's machine from sprite defs
; =============================================================================
ending_render_boss_sprite:  ldx     ent_spawn_type
        lda     boss_sprite_def_ptr_lo,x
        sta     jump_ptr
        lda     boss_sprite_def_ptr_hi,x
        sta     jump_ptr_hi
        ldy     #$00
        lda     (jump_ptr),y
        sta     temp_01
        ldx     temp_00
        beq     ending_boss_sprite_rts
        iny
ending_boss_oam_loop:  clc
        lda     ent_y_spawn_px
        adc     (jump_ptr),y
        sta     oam_buffer,x
        lda     ent_x_spawn_scr
        adc     #$00
        beq     ending_boss_oam_write
        iny
        iny
        iny
        iny
        lda     #$F8
        sta     oam_buffer,x
        bne     ending_boss_oam_next
ending_boss_oam_write:  iny
        lda     (jump_ptr),y
        sta     $0201,x
        iny
        lda     (jump_ptr),y
        sta     $0202,x
        iny
        lda     (jump_ptr),y
        sta     $0203,x
        iny
ending_boss_oam_next:  inx
        inx
        inx
        inx
        beq     ending_boss_sprite_rts
        dec     temp_01
        bne     ending_boss_oam_loop
ending_boss_sprite_rts:  rts

; =============================================================================
; Credits Skip Init — fast-forward to ending walk scene
; =============================================================================
credits_skip_init:  jsr     disable_nmi_and_rendering
        lda     #$50
        sta     $FD
        lda     #$00
        sta     col_update_addr_lo
        sta     $FE
        lda     #$10
        sta     col_update_addr_hi
        lda     #$B0
        sta     $FF
credits_skip_scroll_loop:  jsr     ppu_column_fill
        jsr     ppu_scroll_column_update
        clc
        lda     col_update_addr_lo
        adc     #$20
        sta     col_update_addr_lo
        lda     col_update_addr_hi
        adc     #$00
        sta     col_update_addr_hi
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
        sta     jump_ptr
        lda     #$B6
        sta     jump_ptr_hi
        lda     #$20
        sta     PPUADDR
        ldy     #$00
        sty     PPUADDR
        ldx     #$1E
credits_skip_nt_outer:  ldy     #$00
credits_skip_nt_inner:  lda     (jump_ptr),y
        sta     PPUDATA
        iny
        cpy     #$20
        bne     credits_skip_nt_inner
        sec
        lda     jump_ptr
        sbc     #$20
        sta     jump_ptr
        lda     jump_ptr_hi
        sbc     #$00
        sta     jump_ptr_hi
        dex
        bne     credits_skip_nt_outer
        ldy     #$3F
credits_skip_attr_load:  lda     wily_castle_attr_data,y
        sta     PPUDATA
        dey
        bpl     credits_skip_attr_load
        ldx     #$1F
credits_skip_pal_load:  lda     credits_skip_palette,x
        sta     palette_ram,x
        dex
        bpl     credits_skip_pal_load
        ldx     #$0F
credits_skip_pal2_load:  lda     ending_ground_palette,x
        sta     palette_ram,x
        dex
        bpl     credits_skip_pal2_load
        ldx     #$1F
        lda     #$00
credits_skip_clear_ents:  sta     ent_x_screen,x
        sta     ent_type,x
        dex
        bpl     credits_skip_clear_ents
        lda     #$77
        sta     ent_y_spawn_px
        lda     #$00
        sta     ent_spawn_type
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
        sta     p1_new_presses
        sta     scroll_y
        sta     $AE
        jmp     ending_main_loop_init

; =============================================================================
; Metatile Column Render Loop — render full screen of metatile columns
; =============================================================================
metatile_column_render_loop:  lda     #$00
        sta     column_index
        sta     ppu_buffer_count
metatile_col_pair_render:  jsr     metatile_column_render
        inc     jump_ptr
        inc     column_index
        jsr     metatile_column_render
        jsr     ppu_buffer_and_increment
        lda     jump_ptr
        and     #$3F
        bne     metatile_col_pair_render
        rts

; =============================================================================
; Palette Fade Out — gradually darken all palette entries
; =============================================================================
palette_fade_out:  lda     #$04
        sta     $FD
palette_fade_out_loop:  lda     frame_counter
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

palette_dec_range:  sta     temp_00
palette_dec_loop:  sec
        lda     palette_ram,x
        sbc     #$10                    ; Darken by one NES shade step
        bpl     palette_dec_store
        lda     #$0F
palette_dec_store:  sta     palette_ram,x
        dex
        cpx     temp_00
        bne     palette_dec_loop
        rts

; =============================================================================
; Palette Fade In — gradually brighten palette to target
; =============================================================================
palette_fade_in:  lda     #$04
        sta     $FD
palette_fade_in_loop:  lda     frame_counter
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

palette_inc_range:  sta     temp_01
palette_inc_loop:  lda     palette_ram,x
        cmp     #$0F                    ; Is color black ($0F)?
        bne     palette_inc_add
        lda     password_target_palette,y
        and     #$0F
        jmp     palette_inc_store

palette_inc_add:  clc
        lda     palette_ram,x
        adc     #$10                    ; Brighten by one NES shade step
        cmp     password_target_palette,y
        beq     palette_inc_store
        bcs     palette_inc_next
palette_inc_store:  sta     palette_ram,x
palette_inc_next:  dey
        dex
        cpx     temp_01
        bne     palette_inc_loop
        rts

; =============================================================================
; Password Render Sprites — draw cursor and dot grid OAM
; =============================================================================
password_render_sprites:  ldx     ent_anim_id
        lda     password_grid_y_table,x
        sta     jump_ptr_hi
        lda     password_grid_x_table,x
        sta     jump_ptr
        ldx     #$0F
password_sprite_loop:  clc
        lda     password_sprite_offsets,x
        adc     jump_ptr
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
        adc     jump_ptr_hi
        sta     $0230,x
        dex
        bpl     password_sprite_loop
        lda     frame_counter
        lsr     a
        and     #$07
        tax
        lda     password_blink_colors,x
        sta     $036C
        clc
        lda     ent_anim_frame
        adc     #$24
        sta     $022D
        ldx     #$00
        ldy     #$40
password_dot_check_loop:  lda     ent_flags,x
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
        sta     col_update_addr_hi
        inx
        lda     password_ppu_layout_data,x
        sta     col_update_addr_lo
        inx
        lda     password_ppu_layout_data,x
        sta     col_update_count
        inx
        ldy     #$00
ppu_column_data_inner:  lda     password_ppu_layout_data,x
        sta     col_update_tiles,y
        inx
        iny
        cpy     col_update_count
        bne     ppu_column_data_inner
        rts

; =============================================================================
; Init Scroll and Palette — set nametable, load default palette, enable
; =============================================================================
init_scroll_and_palette:  sta     nametable_select
        lda     #$00
        sta     scroll_x
        sta     scroll_y
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
        lda     scroll_x
        adc     #$08
        sta     scroll_x
        php
        lda     nametable_select
        adc     #$00
        sta     nametable_select
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
        sta     ppu_buffer_count
        sta     column_index
metatile_render_loop:  lda     $FD
        sta     jump_ptr
        lda     $FE
        sta     jump_ptr_hi
        jsr     metatile_column_render
        inc     $FD
        inc     column_index
        jsr     wait_for_vblank_0D
        lda     $FD
        and     #$3F
        bne     metatile_render_loop
        rts

; =============================================================================
; Scroll Left Until Zero — scroll X left in 8px steps
; =============================================================================
scroll_left_until_zero:  sec
        lda     scroll_x
        sbc     #$08
        sta     scroll_x
        beq     scroll_left_rts
        lda     nametable_select
        sbc     #$00
        sta     nametable_select
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
        sta     oam_buffer,y
        iny
        lda     #$0F
        sta     oam_buffer,y
        iny
        lda     #$00
        sta     oam_buffer,y
        iny
        clc
        lda     password_grid_x_table,x
        adc     #$04
        sta     oam_buffer,y
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
        .byte   $11,$0F
        .byte   $00
        .byte   $10,$30
ending_black_palette:  .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0F,$00,$10,$30
ending_ground_palette:  .byte   $26,$15
        .byte   $20,$06,$0F
        .byte   $30,$2C
        .byte   $15,$26
        .byte   $21,$20
        .byte   $0B,$0F,$00,$10,$30
ending_star_oam_positions:  .byte   $2F,$3C,$02,$C0,$37,$3D,$02
        .byte   $C0,$3F
        .byte   $3B,$02,$C0,$3F,$3A,$02,$B8,$3F
        .byte   $39,$02,$B0

; =============================================================================
; Entity Sprite Offset Tables — Y/tile/attr/X for ending entities
; =============================================================================
entity_sprite_y_offset:  .byte   $00
entity_sprite_tile_id:  .byte   $30
entity_sprite_attr:  .byte   $02
entity_sprite_x_offset:  .byte   $C0,$00
        .byte   $31,$02
        .byte   $C8
        .byte   $08
        .byte   $32,$02,$C0,$08,$33,$02
data_AAF2:  .byte   $C8
        .byte   $10,$34
        .byte   $02,$C0,$10,$35,$02,$C8,$00,$30
        .byte   $02,$E0
        .byte   $00
        .byte   $31,$02
        .byte   $E8
        .byte   $08
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
        .byte   $C8
        .byte   $00
        .byte   $01,$01,$D0,$00,$02,$01,$D8,$08
        .byte   $03,$00,$C8,$08,$04,$00,$D0,$08
        .byte   $05,$00,$D8,$08,$1F,$01,$C8,$08
        .byte   $20,$01,$D0
        .byte   $10,$06
        .byte   $00
        .byte   $C8,$10,$07,$00,$D0
boss_sprite_data_AB66:  .byte   $10,$08
        .byte   $00
        .byte   $D8,$0B,$00,$09,$01,$C8,$00
boss_sprite_data_AB70:  .byte   $0A
        .byte   $01,$D0
        .byte   $00
        .byte   $0B,$01,$D8,$08,$03,$00,$C8,$08
        .byte   $04,$00,$D0,$08,$05,$00,$D8,$08
        .byte   $1F,$01,$C8,$08
        .byte   $20,$01,$D0
        .byte   $10,$06
        .byte   $00
        .byte   $C8,$10,$07,$00,$D0
boss_sprite_data_AB93:  .byte   $10,$08
        .byte   $00
        .byte   $D8,$0C,$00,$0C,$01,$C8,$00
boss_sprite_data_AB9D:  .byte   $0D,$01,$D0
        .byte   $00
        .byte   $02,$01,$D8,$00,$21,$00,$D0,$08
        .byte   $03
        .byte   $00
        .byte   $C8
        .byte   $08
        .byte   $04,$00,$D0,$08
        .byte   $05,$00
        .byte   $D8
        .byte   $08
        .byte   $23,$01,$C8,$08
        .byte   $24,$01
        .byte   $D0,$10
        .byte   $06,$00
        .byte   $C8
        .byte   $10,$07
        .byte   $00
        .byte   $D0,$10,$08,$00,$D8,$0C
boss_sprite_data_ABC9:  .byte   $00,$0C,$01,$C8
boss_sprite_data_ABCD:  .byte   $00,$0E,$01,$D0,$00,$02,$01,$D8
        .byte   $00,$22,$00,$D0,$08,$03,$00,$C8
        .byte   $08,$04,$00,$D0,$08
        .byte   $05,$00
        .byte   $D8
        .byte   $08
        .byte   $23,$01,$C8,$08
        .byte   $24,$01
        .byte   $D0,$10
        .byte   $06,$00
        .byte   $C8
        .byte   $10,$07
        .byte   $00
        .byte   $D0,$10,$08,$00,$D8,$0D
boss_sprite_data_ABFA:  .byte   $00,$0F,$01,$C8
boss_sprite_data_ABFE:  .byte   $00,$10,$01,$D0
        .byte   $00
        .byte   $11,$01
        .byte   $D8
        .byte   $00
        .byte   $25,$00,$C8,$00,$26,$00,$D0,$08
        .byte   $03,$00,$C8,$08,$04,$00,$D0,$08
        .byte   $05,$00
        .byte   $D8
        .byte   $08
        .byte   $1F,$01,$C8,$08
        .byte   $20,$01,$D0
        .byte   $10,$06
        .byte   $00
        .byte   $C8,$10,$07,$00,$D0
boss_sprite_data_AC2A:  .byte   $10,$08
        .byte   $00
        .byte   $D8,$0A,$00,$12,$00,$C8,$00
boss_sprite_data_AC34:  .byte   $13,$00,$D0,$00,$14,$00,$D8,$08
        .byte   $03,$00,$C8,$08,$15,$00,$D0,$08
        .byte   $05,$00,$D8,$10,$06,$00,$C8,$10
        .byte   $07,$00,$D0
        .byte   $10,$08
        .byte   $00
        .byte   $D8,$06,$27,$01,$CF,$0A,$00
boss_sprite_data_AC59:  .byte   $12,$00,$C8,$00,$16,$00,$D0,$00
        .byte   $17,$00,$D8,$08,$03,$00,$C8,$08
        .byte   $18,$00,$D0,$08,$19,$00,$D8,$10
        .byte   $06,$00,$C8,$10,$07,$00,$D0
        .byte   $10,$08
        .byte   $00
        .byte   $D8,$06
        .byte   $28
        .byte   $01,$CF
        .byte   $0A
        .byte   $00
boss_sprite_data_AC82:  .byte   $12,$00,$C8,$00,$1A,$00,$D0,$00
        .byte   $17,$00,$D8,$08,$03,$00,$C8,$08
        .byte   $1B,$00,$D0,$08,$05,$00,$D8,$10
        .byte   $06,$00,$C8,$10,$07,$00,$D0
        .byte   $10,$08
        .byte   $00
        .byte   $D8,$06
        .byte   $28
        .byte   $01,$CF
        .byte   $0A
        .byte   $00
boss_sprite_data_ACAB:  .byte   $1C,$00,$C8,$00,$1D,$00,$D0,$00
        .byte   $17,$00,$D8,$08,$03,$00,$C8,$08
        .byte   $18,$00,$D0,$08,$05,$00,$D8,$10
        .byte   $06,$00,$C8,$10,$07,$00,$D0
        .byte   $10,$08
        .byte   $00
        .byte   $D8,$06
        .byte   $28
        .byte   $01,$CF
        .byte   $0A
        .byte   $00
boss_sprite_data_ACD4:  .byte   $1C,$00,$C8,$00,$1E,$00,$D0,$00
        .byte   $17,$00,$D8,$08

; =============================================================================
; Boss Sprite Data — raw OAM for each Wily machine animation frame
; =============================================================================
boss_sprite_data_ACE0:  .byte   $03,$00,$C8,$08,$18,$00,$D0,$08
        .byte   $05,$00,$D8,$10,$06,$00,$C8,$10
        .byte   $07,$00,$D0
        .byte   $10,$08
        .byte   $00
        .byte   $D8,$06
        .byte   $28
        .byte   $01,$CF
        .byte   $04,$F8
boss_sprite_data_ACFD:  .byte   $2A
        .byte   $00
        .byte   $D0
        .byte   $00
        .byte   $2A
        .byte   $00
        .byte   $D0
        .byte   $08
        .byte   $2A
        .byte   $00
        .byte   $D0,$10,$2A,$00,$D0,$0A,$F8,$2F
        .byte   $00,$D0,$00
        .byte   $2C,$00,$C8
        .byte   $00
        .byte   $2D,$00,$D0,$00,$2C,$40,$D8,$08
        .byte   $2C,$00,$C8,$08,$2D,$00,$D0,$08
        .byte   $2C,$40,$D8,$10,$2B,$00,$C8,$10
        .byte   $2E,$00,$D0,$10,$2B,$40,$D8,$04
        .byte   $08,$2F,$00,$D0,$10,$2B,$00,$C8
        .byte   $10,$2E,$00,$D0
        .byte   $10,$2B
        .byte   $40

        .byte   $D8,$00,$00,$00,$C9,$CE,$00,$D4
        .byte   $C8,$C5,$00,$D9,$C5,$C1,$D2,$00
        .byte   $CF
        .byte   $C6,$00
        .byte   $A2,$A0
        .byte   $A0,$D8
        .byte   $DD,$00,$00
        .byte   $00
        .byte   $00,$C1,$00,$D3,$D5,$D0,$C5,$D2
        .byte   $00,$D2,$CF,$C2,$CF,$D4
        .byte   $00

; =============================================================================
; Credits Text Data — ASCII text for ending credit screens
; =============================================================================
credits_text_data:  .byte   $CE,$C1,$CD
        .byte   $C5,$C4
        .byte   $00
        .byte   $CD,$C5,$C7,$C1,$CD,$C1,$CE,$00
        .byte   $00,$00,$00,$00,$00,$00,$D7,$C1
        .byte   $D3,$00,$C3,$D2,$C5,$C1,$D4,$C5
        .byte   $C4,$DC,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$C4,$D2,$DC,$CC,$C9
        .byte   $C7,$C8,$D4,$00,$C3,$D2,$C5,$C1
        .byte   $D4,$C5,$C4,$00,$CD,$C5,$C7
        .byte   $C1,$CD
        .byte   $C1,$CE
        .byte   $00
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
        .byte   $30,$30
        .byte   $30,$30
        .byte   $30,$30
        .byte   $30,$30
        .byte   $30,$30
        .byte   $30,$20
        .byte   $10,$00
credits_fade_data_2:  .byte   $0F,$30,$30,$30,$20
        .byte   $10,$00
credits_fade_data_3:  .byte   $0F
ending_teleport_anim_table:  .byte   $0C,$0B,$0A,$06,$06,$09,$09,$08
        .byte   $08,$07,$07,$06,$06,$06,$06
        .byte   $06,$06
        .byte   $05,$05
        .byte   $04,$04,$03
data_AE91:  .byte   $03,$02,$02
        .byte   $01
credits_tile_layout_data:  .byte   $13
        .byte   $21
data_AE97:  .byte   $47
        .byte   $A3
data_AE99:  .byte   $A7
        .byte   $A5
data_AE9B:  .byte   $A1,$A1
data_AE9D:  .byte   $00
        .byte   $C3
data_AE9F:  .byte   $C1,$D0
        .byte   $C3
        .byte   $CF,$CD,$00,$C3,$CF,$DC,$CC,$D4
        .byte   $C4,$1F,$21
        .byte   $81,$D4
        .byte   $CD,$00,$C1
        .byte   $CE,$C4,$00
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
        .byte   $0F,$26,$26,$27,$0F,$17,$28,$05
        .byte   $0F,$17,$27,$18,$0F,$19,$2A,$37,$0F
        .byte   $20,$2C,$11,$0F,$20,$26,$36,$0F
        .byte   $00,$2C,$11,$0F,$16,$35,$20
password_ppu_layout_data:  .byte   $25
password_ppu_layout_data_2:  .byte   $8C,$09,$40
        .byte   $53,$54,$41,$52,$54,$40,$40,$40
        .byte   $25,$CC,$0A,$40,$50,$41,$53,$53
        .byte   $57,$4F,$52,$44,$40,$25,$8C,$09
        .byte   $50,$41,$53,$53,$57,$4F,$52,$44
        .byte   $40,$25,$CC,$0A,$45,$52,$52,$4F
        .byte   $52,$40,$5F,$40,$40,$40,$25,$8B
        .byte   $08,$43,$4F,$4E,$54,$49,$4E
        .byte   $55,$45
        .byte   $25,$CB
        .byte   $0C,$53,$54,$41,$47,$45,$40,$53
        .byte   $45,$4C,$45,$43,$54,$26,$0B,$09
        .byte   $50,$41,$53,$53,$57,$4F,$52,$44
        .byte   $40,$22,$66,$0E
data_AF94:  .byte   $50,$52
        .byte   $45,$53
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
        .byte   $30,$A0
        .byte   $3F,$00,$D0
        .byte   $B4,$2D
        .byte   $01,$D0
password_grid_y_table:  .byte   $40

        .byte   $40

        .byte   $40,$40,$40
data_B000:  .byte   $50
        .byte   $50,$50
        .byte   $50,$50
        .byte   $60

        .byte   $60

        .byte   $60,$60,$60,$70,$70,$70,$70,$70
        .byte   $80,$80,$80,$80,$80
password_grid_x_table:  .byte   $41,$51
        .byte   $61,$71
        .byte   $81,$41
        .byte   $51,$61
        .byte   $71,$81
        .byte   $41,$51
        .byte   $61,$71
        .byte   $81,$41
        .byte   $51,$61
        .byte   $71,$81
        .byte   $41,$51
        .byte   $61,$71
        .byte   $81
cursor_move_right_table:  .byte   $01,$02
        .byte   $03,$04,$00,$06,$07,$08,$09,$05
        .byte   $0B,$0C,$0D,$0E,$0A,$10,$11,$12
        .byte   $13,$0F,$15,$16,$17,$18,$14
cursor_move_left_table:  .byte   $04,$00,$01,$02,$03,$09
        .byte   $05,$06
        .byte   $07
        .byte   $08
        .byte   $0E,$0A,$0B
data_B053:  .byte   $0C
        .byte   $0D
data_B055:  .byte   $13
        .byte   $0F
        .byte   $10,$11
        .byte   $12,$18,$14,$15,$16,$17
cursor_move_up_table:  .byte   $14
        .byte   $15,$16
        .byte   $17,$18,$00,$01,$02,$03,$04,$05
data_B06A:  .byte   $06,$07
        .byte   $08
        .byte   $09,$0A
        .byte   $0B,$0C,$0D,$0E,$0F,$10,$11,$12
        .byte   $13
cursor_move_down_table:  .byte   $05,$06
data_B07A:  .byte   $07,$08
        .byte   $09,$0A
        .byte   $0B,$0C,$0D,$0E,$0F,$10,$11,$12
        .byte   $13,$14,$15,$16,$17,$18,$00,$01
        .byte   $02,$03,$04
password_blink_colors:  .byte   $0F,$00,$10,$20,$30
        .byte   $20,$10,$00
password_sprite_offsets:  .byte   $00
        .byte   $3E,$01,$00,$00,$3E
        .byte   $41,$08
        .byte   $08
        .byte   $3E,$81,$00
        .byte   $08
        .byte   $3E,$C1,$08
password_bit_mask_table:  .byte   $00
        .byte   $01
data_B0AB:  .byte   $00,$10,$04,$20,$00,$08,$10,$80
        .byte   $08,$02,$04,$00
        .byte   $01,$40
        .byte   $80,$02,$20,$40
password_byte_index_table:  .byte   $00,$00,$00,$00,$01,$00,$00,$01
        .byte   $01,$00,$00,$01,$00,$00,$01,$01
        .byte   $01,$00,$01,$00
password_beaten_oam_data:  .byte   $60,$2F,$00,$60,$70,$1F,$00,$60
        .byte   $60,$1B,$00,$80,$70,$19,$00,$70
        .byte   $60,$1D,$00,$70,$60,$1C,$00
        .byte   $90,$70
        .byte   $1A,$00,$90,$70,$1E,$00,$80,$80
        .byte   $20,$00,$60,$80
        .byte   $25,$00
        .byte   $70,$80
        .byte   $26,$00
        .byte   $80,$80,$27,$00
        .byte   $90                     ; data byte (was wrongly decoded as BCC)
; --- ending_chr_load -- Ending: CHR bank load entry ($B101, dispatch entry 4) ---
ending_chr_load:
        lda     #$03
        jsr     chr_ram_bank_load
        lda     current_stage
        pha
        lda     #$05
        sta     current_stage
        lda     #$00
        sta     jump_ptr
        lda     #$8E
        sta     jump_ptr_hi
        jsr     metatile_column_render_loop
        lda     #$40
        sta     jump_ptr
        lda     #$8E
        jsr     metatile_column_render_loop
        lda     #$21
        sta     PPUADDR
        lda     #$CC
        sta     PPUADDR
        ldx     #$00
credits_game_over_text:  lda     game_over_text_data,x
        sta     PPUDATA
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
credits_select_input:  lda     p1_new_presses
        and     #$3C
        beq     credits_select_draw
        and     #$08
        bne     credits_start_pressed
        lda     #$2F
        jsr     bank_switch_enqueue
        lda     p1_new_presses
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
        sta     oam_buffer,x
        dex
        bpl     credits_select_oam_load
        lda     frame_counter
        and     #$08
        bne     credits_select_vblank
        ldx     $FD
        lda     credits_cursor_y_table,x
        sta     oam_buffer
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
        sta     current_stage
        lda     #$03
        sta     current_lives
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
password_clear_dots_loop:  sta     ent_flags,x
        dex
        bpl     password_clear_dots_loop
        ; Encode current progress into 9 dots on the 5x5 grid:
        ; temp_00 = beaten boss flags, temp_01 = complement (for validation).
        lda     $9A
        sta     temp_00
        eor     #$FF
        sta     temp_01
        clc
        lda     current_etanks
        tax
        adc     #$05
        sta     temp_03                 ; data region starts at cell (E-tanks + 5)
        inc     ent_flags,x             ; place E-tank dot in cell 0-3
        ldx     #$00
password_set_dots_loop:  ldy     password_byte_index_table,x
        lda     temp_00,y
        ldy     temp_03
        and     password_bit_mask_table,x
        beq     password_set_dot_entry
        lda     #$01
password_set_dot_entry:  sta     ent_flags,y
        iny
        cpy     #$19
        bne     password_set_dot_next
        ldy     #$05
password_set_dot_next:  sty     temp_03
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
        sta     oam_buffer,x
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
        sta     temp_00
        lda     $9B
        rol     a
        sta     temp_01
        ldx     #$00
        lda     #$0C
        sta     temp_02
password_boss_icon_loop:  lsr     temp_01
        ror     temp_00
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
password_boss_icon_next:  dec     temp_02
        bne     password_boss_icon_loop
        ldx     #$07
        jsr     ppu_column_data_upload
        jsr     palette_fade_in
password_blink_loop:  ldx     #$F8
        lda     frame_counter
        and     #$08
        bne     password_blink_store
        ldx     #$98
password_blink_store:  stx     $0228
        jsr     wait_for_vblank_0D
        lda     p1_new_presses
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
        .byte   $E4,$E6
        .byte   $E8
        .byte   $EA
        .byte   $E4,$E6
        .byte   $00
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
        inc     nametable_select
        lda     #$04
        jsr     chr_ram_bank_load
        lda     #$05
        sta     current_stage
        lda     #$C0
        sta     jump_ptr
        lda     #$8E
        sta     jump_ptr_hi
        jsr     metatile_column_render_loop
        lda     #$00
        sta     jump_ptr
        lda     #$8F
        sta     jump_ptr_hi
        jsr     metatile_column_render_loop
        lda     #$00
        sta     ent_anim_id
        sta     ent_anim_frame
        sta     $0681
        sta     ent_type
        sta     $0401
        sta     $04A1
        lda     #$0F
        ldx     #$1F

; =============================================================================
; Ending Walk Scene — init scroll, CHR, palette, wait, then walk
; =============================================================================
ending_clear_pal_loop:  sta     palette_ram,x
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
ending_scene_next:  ldx     ent_anim_id
        lda     ending_scene_timer_lo,x
        sta     $FD
        lda     ending_scene_timer_hi,x
        sta     $FE
        lda     #$3F
        sta     $FF
ending_scene_timer:  lda     $FF
        beq     ending_scene_check_type
        dec     $FF
ending_scene_check_type:  lda     ent_anim_id
        cmp     #$05
        bne     ending_scene_scroll_pal
        lda     $FF
        and     #$01
        sta     nametable_select
        jmp     ending_scene_check_stars

ending_scene_scroll_pal:  jsr     ending_set_sky_palette
        jsr     ending_set_ground_palette
ending_scene_check_stars:  lda     ent_anim_id
        bne     ending_scene_frame
        lda     frame_counter
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
        inc     ent_anim_id
        lda     ent_anim_id
        cmp     #$06
        bne     ending_scene_next
        jsr     disable_nmi_and_rendering
        jsr     load_stage_nametable
        lda     #$05
        jsr     chr_ram_bank_load
        lda     #$20
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        ldy     #$04
ending_nt_clear_outer:  ldx     #$00
ending_nt_clear_inner:  sta     PPUDATA
        inx
        bne     ending_nt_clear_inner
        dey
        bne     ending_nt_clear_outer
        sta     ent_flags
        ldx     #$1F
        jsr     load_scroll_palette
        inc     nametable_select
        jsr     clear_oam_buffer
        lda     #$30
        sta     $0369
        lda     #$0D
        jsr     bank_switch_enqueue
        jsr     enable_nmi_and_rendering
        jsr     clear_projectile_positions
        lda     #$25
        sta     col_update_addr_hi
        lda     #$AC
        sta     col_update_addr_lo
        lda     #$A2
        sta     $FD
        lda     #$00
        sta     $FE
        sta     ent_anim_id

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
        sta     col_update_tiles
        inc     col_update_count
        inc     $FE
        inc     col_update_addr_lo
ending_health_bar_frame:  jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        dec     $FD
        bne     ending_health_bar_loop
        lda     #$A0
        sta     col_update_addr_lo
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
        sta     ent_anim_frame
        lda     #$25
        sta     col_update_addr_hi
        lda     #$83
        sta     col_update_addr_lo
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
        lda     ent_anim_id
        cmp     #$0E
        bcc     ending_walk_frame_loop
        lda     #$14
        jsr     bank_switch_enqueue
        jmp     ending_walk_frame_loop

ending_walk_next_column:  lda     #$25
        sta     col_update_addr_hi
        lda     #$80
        sta     col_update_addr_lo
        lda     #$20
        jsr     ppu_fill_column_with_tile
        lda     #$25
        sta     col_update_addr_hi
        lda     #$C0
        sta     col_update_addr_lo
        lda     #$20
        jsr     ppu_fill_column_with_tile
        inc     ent_anim_id
        lda     ent_anim_id
        cmp     #$10
        bne     ending_walk_main_init
        lda     #$0F
        sta     $0358
        sta     $0359
        lda     #$00
        sta     ent_anim_id
        sta     nametable_select
        jsr     ending_init_walk

; =============================================================================
; Ending Final Walk — last walking segment before wait for Start
; =============================================================================
ending_final_walk_loop:  jsr     ending_walk_step
        jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        lda     ent_anim_id
        cmp     #$3C
        bne     ending_final_walk_loop
        lda     scroll_y
        bne     ending_final_walk_loop
ending_wait_for_start:  jsr     render_player_sprites
        jsr     wait_for_vblank_0D
        lda     p1_new_presses
        and     #$08
        beq     ending_wait_for_start
        jsr     disable_nmi_and_rendering
        rts

; =============================================================================
; Ending Scene Sprite Render — draw scene-specific sprites
; =============================================================================
ending_scene_sprite_render:  jsr     clear_oam_buffer
        lda     ent_anim_id
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
        sta     ent_x_px
        sta     ent_y_px
        sta     ent_x_screen
        sta     temp_00
        inc     ent_anim_frame
        lda     ent_anim_frame
        cmp     #$10
        bne     ending_scene_check_phase
        lda     #$00
        sta     ent_anim_frame
        inc     ent_type
        lda     ent_type
        cmp     #$04
        bne     ending_scene_check_phase
        lda     #$00
        sta     ent_type
ending_scene_check_phase:  lda     ent_anim_id
        cmp     #$04
        bcc     ending_scene_walk_render
        ldy     ent_type
        lda     $FF
        and     #$01
        bne     ending_scene_anim_call
        ldy     #$04
ending_scene_anim_call:  jsr     ending_player_anim
        rts

ending_scene_walk_render:  jsr     ending_player_render
        ldx     ent_anim_id
        clc
        lda     $04C1
        adc     ending_walk_vel_sub,x
        sta     $04C1
        lda     $04A1
        adc     ending_walk_vel_whole,x
        sta     $04A1
        lda     frame_counter
        and     #$07
        bne     ending_scene_anim_frame
        inc     $0681
        lda     $0681
        cmp     #$04
        bne     ending_scene_anim_frame
        lda     #$00
        sta     $0681
ending_scene_anim_frame:  lda     ent_anim_id
        asl     a
        asl     a
        adc     $0681
        tax
        lda     ending_sprite_tile_table,x
        sta     temp_02
        lda     $FF
        beq     ending_scene_oam_write
        ldx     ent_anim_id
        beq     ending_scene_oam_write
        dex
        lda     $FF
        beq     ending_scene_oam_write
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     temp_02
        txa
        asl     a
        asl     a
        adc     temp_02
        tax
        lda     ending_sprite_fade_table,x
        sta     temp_02
ending_scene_oam_write:  ldy     temp_00
        ldx     #$15
ending_scene_oam_loop:  clc
        lda     ending_sprite_y_table,x
        adc     $04A1
        sta     oam_buffer,y
        iny
        lda     temp_02
        sta     oam_buffer,y
        iny
        lda     #$03
        sta     oam_buffer,y
        iny
        lda     ending_sprite_x_table,x
        sta     oam_buffer,y
        iny
        dex
        bpl     ending_scene_oam_loop
        rts

; =============================================================================
; Ending Set Sky Palette — sky color based on scene index
; =============================================================================
ending_set_sky_palette:  ldx     ent_anim_id
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
ending_set_ground_palette:  ldx     ent_anim_id
        beq     ending_ground_pal_rts
        lda     $FF
        and     #$01
        beq     ending_ground_pal_index
        dex
ending_ground_pal_index:  txa
        asl     a
        asl     a
        sta     temp_00
        clc
        asl     a
        adc     temp_00
        tax
        ldy     #$00
ending_ground_pal_copy:  lda     ending_palette_per_scene,x
        sta     palette_ram,y
        inx
        iny
        cpy     #$0C
        bne     ending_ground_pal_copy
ending_ground_pal_rts:  rts

; =============================================================================
; PPU Fill Column with Tile — fill 32-tile column for PPU upload
; =============================================================================
ppu_fill_column_with_tile:  ldx     #$20
        stx     col_update_count
        dex
ppu_fill_col_loop:  sta     col_update_tiles,x
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
        .byte   $16,$0F
        .byte   $19,$2A,$18

; =============================================================================
; Ending Sky Color Table — 2-byte sky color for each scene/phase
; =============================================================================
ending_sky_color_table:  .byte   $2C,$11,$28
        .byte   $15,$30
        .byte   $00
        .byte   $34,$24,$30,$11,$2C,$11
ending_scene_timer_lo:  .byte   $2C,$32,$32
        .byte   $32,$32,$90
ending_scene_timer_hi:  .byte   $03,$02,$02,$02
data_BA85:  .byte   $02,$02
ending_sprite_y_table:  .byte   $00,$08,$10,$20,$28,$30,$40,$48
        .byte   $50,$58,$68,$78,$80,$88,$90,$A8
        .byte   $B8,$C0,$D0,$D8,$E0,$E8
ending_sprite_x_table:  .byte   $D8,$70,$18,$B0,$88,$40,$A0,$F8
        .byte   $20,$58,$C8,$08,$88,$38
        .byte   $B0,$D8
        .byte   $70,$28
        .byte   $B8
        .byte   $08
        .byte   $98
        .byte   $48
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
        lda     current_stage
        pha
        lda     #$05
        sta     current_stage
        lda     #$40
        sta     jump_ptr
        lda     #$8F
        sta     jump_ptr_hi
        jsr     metatile_column_render_loop
        lda     #$80
        sta     jump_ptr
        lda     #$8F
        sta     jump_ptr_hi
        jsr     metatile_column_render_loop
        pla
        sta     current_stage
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
        sta     ent_type
        jsr     ending_player_render
        lda     #$05
        sta     $FD
stage_intro_fade_loop:  lda     frame_counter
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
        inc     col_update_addr_lo
        ldx     current_stage
        lda     weapon_name_data,x
        sta     col_update_tiles
        inc     col_update_count
        jsr     weapon_get_wait_frame
        jsr     weapon_get_draw_marker
        inc     col_update_addr_lo
        inc     col_update_addr_lo
        jsr     wait_for_vblank_0D
        lda     #$08
        jsr     weapon_get_text_upload
        lda     #$09
        jsr     weapon_get_text_upload
        lda     current_stage
        jsr     weapon_get_text_upload
        lda     current_stage
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
        ldx     current_stage
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
        ldx     current_stage
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
        lda     frame_counter
        and     #$08
        bne     stage_intro_check_input
        lda     #$F8
        sta     $02FC
stage_intro_check_input:  lda     p1_new_presses
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
stage_intro_save_pal_loop:  lda     palette_ram,x
        sta     $0700,x
        dex
        bpl     stage_intro_save_pal_loop
        jsr     password_show_grid
        jsr     ending_player_render
        lda     #$05
        sta     $FD
stage_intro_restore_loop:  lda     frame_counter
        and     #$03
        bne     stage_intro_restore_frame
        ldx     #$1F
stage_intro_restore_inner:  lda     palette_ram,x
        cmp     #$0F
        bne     stage_intro_restore_add
        lda     $0700,x
        and     #$0F
        sta     palette_ram,x
        jmp     stage_intro_restore_next

stage_intro_restore_add:  clc
        adc     #$10
        cmp     $0700,x
        beq     stage_intro_restore_store
        bcs     stage_intro_restore_next
stage_intro_restore_store:  sta     palette_ram,x
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
        sta     ent_type
        jsr     ending_player_render
        lda     #$0A
        jsr     weapon_get_text_upload
        lda     #$0B
        jsr     weapon_get_text_upload
        jsr     weapon_get_long_wait
        jsr     weapon_get_clear_nt
        ldx     current_stage
        lda     $C281,x
        lsr     a
        ora     #$A0
        sta     ent_flags
        inc     ent_flags
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
        sta     ent_type
        jsr     ending_player_render
        jsr     weapon_get_draw_weapon
        lda     #$08
        jsr     weapon_get_text_upload
        lda     #$09
        jsr     weapon_get_text_upload
        lda     ent_flags
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
        ldx     current_stage
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
        sta     col_update_addr_hi
        lda     #$CD
        sta     col_update_addr_lo
        lda     #$94
        sta     col_update_tiles
        inc     col_update_count
        rts

; =============================================================================
; Weapon Get Wait Frame — sync to frame counter mod 8
; =============================================================================
weapon_get_wait_frame:  jsr     wait_for_vblank_0D
        lda     frame_counter
        and     #$07
        bne     weapon_get_wait_frame
        rts

; =============================================================================
; Weapon Get Text Upload — read text table and upload letter by letter
; =============================================================================
weapon_get_text_upload:  sty     temp_00
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
        sta     col_update_addr_hi
        tya
        clc
        adc     #$01
        tay
        lda     $CA
        adc     #$00
        sta     $CA
        lda     ($C9),y
        sta     col_update_addr_lo
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
        lda     ent_flags
        bne     weapon_get_text_store
weapon_get_text_byte:  lda     ($C9),y
weapon_get_text_store:  sta     col_update_tiles
        inc     col_update_count
        inc     col_update_addr_lo
        lda     $FE
        clc
        adc     #$01
        sta     $FE
        lda     $CA
        adc     #$00
        sta     $CA
        dec     $FD
        bne     weapon_get_text_inner
        ldy     temp_00
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
weapon_get_clear_loop:  sta     col_update_tiles,x
        dex
        bpl     weapon_get_clear_loop
        lda     #$09
        sta     $FD
        lda     #$24
        sta     col_update_addr_hi
        lda     #$AB
        sta     col_update_addr_lo
weapon_get_clear_cols:  clc
        lda     col_update_addr_lo
        adc     #$20
        sta     col_update_addr_lo
        lda     col_update_addr_hi
        adc     #$00
        sta     col_update_addr_hi
        lda     #$0F
        sta     col_update_count
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
        inc     col_update_addr_lo
        ldx     current_stage
        lda     ent_flags
        sta     col_update_tiles
        inc     col_update_count
        jsr     weapon_get_wait_frame
        jsr     weapon_get_draw_marker
        inc     col_update_addr_lo
        inc     col_update_addr_lo
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
        .byte   $46,$52,$4F,$4D,$40,$25,$6B,$40,$44,$52,$5C,$4C,$49,$47
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
