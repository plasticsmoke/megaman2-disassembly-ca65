.segment "BANK0E"

; =============================================================================
; Bank $0E — Main Game Engine
; Cold boot entry point, hardware initialization, main game loop,
; and game state dispatch table. Bank $0E is switched in first by
; cold_boot_init in the fixed bank after reset.
; =============================================================================

; da65 V2.18 - Ubuntu 2.19-1
; Created:    2026-02-23 18:17:35
; Input file: build/bank0E.bin
; Page:       1


        .setcpu "6502"

.include "include/hardware.inc"
.include "include/ram.inc"
.include "include/zeropage.inc"
.include "include/constants.inc"

zp_0F15           := $0F15
zp_0F20           := $0F20
addr_2020           := $2020
addr_5060           := $5060
bank_switch_enqueue           := $C051
banked_entry           := $C05D
boss_beaten_check           := $C071
boss_beaten_mask_lo         := $C279
wait_for_vblank           := $C07F
wait_one_rendering_frame           := $C0D7
boss_death_sequence           := $C10B
chr_upload_init           := $C45D
chr_upload_run           := $C4CD
nametable_init           := $C557
nametable_stage_setup           := $C565
palette_anim_run           := $C573
process_sound_and_bosses           := $C5A9
get_screen_boundary           := $C7A4
boss_entrance_setup           := $C7B5
boss_trigger_entrance           := $C808
boss_wily_entrance           := $C80C
divide_8bit           := $C84E
divide_16bit           := $C874
metatile_render           := $C8EF
metatile_attr_update           := $C91B
column_data_copy           := $C96B
scroll_y_update           := $CA16
scroll_column_render           := $CB0C
build_active_list           := $CB8C
lookup_cached_tile           := $CBA2
lookup_tile_from_map           := $CBC3
clear_oam_buffer           := $CC6C
render_all_sprites           := $CC77
ppu_buffer_transfer           := $D11B
weapon_palette_setup           := $D2ED
weapon_set_base_type           := $D3A8
weapon_spawn_projectile           := $D3E0
entity_spawn_scan           := $D658
fire_weapon_dispatch           := $DA51
update_entity_positions           := $DCD0
apply_entity_physics           := $EEBA
apply_collision_physics           := $EEDA
apply_simple_physics           := $EFAF
apply_entity_physics_alt           := $EFB3
entity_face_player           := $EFEE
find_entity_by_type           := $F010
find_entity_scan           := $F014
check_vert_tile_collision           := $F02C
check_horiz_tile_collision           := $F0CF
spawn_entity_from_parent           := $F159
spawn_entity_init           := $F160
calc_entity_velocity           := $F197
        sei
        ldx     #$FF
        txs
        ldx     #$01

; =============================================================================
; wait_ppu_warmup_1 -- Cold Boot Entry — wait for PPU warmup, clear RAM, init MMC1 ($8000)
; =============================================================================
wait_ppu_warmup_1:  lda     PPUSTATUS       ; read PPUSTATUS to clear latch
        bpl     wait_ppu_warmup_1
wait_ppu_warmup_2:  lda     PPUSTATUS       ; wait for second VBLANK
        bmi     wait_ppu_warmup_2
        dex
        bpl     wait_ppu_warmup_1
        lda     #$00
        sta     temp_00
        sta     temp_01
        ldy     #$00
clear_ram_loop:  sta     (temp_00),y        ; zero out RAM page
        iny
        bne     clear_ram_loop
        inc     temp_01
        ldx     temp_01
        cpx     #$08
        bne     clear_ram_loop
        lda     #$0E
        jsr     banked_entry
        lda     #$01
        sta     mmc1_shift_register
        lsr     a
        sta     mmc1_shift_register
        lsr     a
        sta     mmc1_shift_register
        lsr     a
        sta     mmc1_shift_register
        lsr     a
        sta     mmc1_shift_register
        lda     #$1F
        sta     $DFFF
        lsr     a
        sta     $DFFF
        lsr     a
        sta     $DFFF
        lsr     a
        sta     $DFFF
        lsr     a
        sta     $DFFF
        lda     #$03
        sta     current_lives
        lda     #$00
        sta     current_etanks

; =============================================================================
; game_init -- Game Initialization — set up PPU, load stage data, fill palettes ($805F)
; =============================================================================
game_init:  jsr     nametable_init      ; initialize nametable data
        lda     $BE
        bne     game_init
        lda     $9A
        cmp     #$FF
        bne     game_init_set_scroll_bank
        lda     #$08
        sta     current_stage
        bne     game_init_check_wily
game_init_set_scroll_bank:  lda     #$03
        sta     current_lives
        jsr     nametable_stage_setup
game_init_check_wily:  lda     current_stage
        cmp     #WILY_STAGE_START                    ; stages 8+ are Wily fortress
        bcc     game_init_fill_weapon_ammo
        jsr     boss_beaten_check
        lda     current_stage
        cmp     #$09
        bcs     game_init_set_boss_offset
game_init_fill_weapon_ammo:  ldx     #$0A
        lda     #MAX_HP                    ; $1C = full weapon energy (28)
fill_weapon_ammo_loop:  sta     $9C,x
        dex
        bpl     fill_weapon_ammo_loop
game_init_set_boss_offset:  ldx     #$00
        lda     current_stage
        and     #$08
        beq     game_init_store_boss_offset
        ldx     #$03
game_init_store_boss_offset:  stx     $B0 ; boss table offset (0=Robot Master, 3=Wily)
        lda     #$14
        ldx     #$1F
game_init_fill_timers:  sta     $0140,x
        dex
        bpl     game_init_fill_timers
        lda     #$00
        sta     $BC
        lda     #$00
        sta     $46
        lda     #$40
        sta     $45
        lda     #$10
        sta     ppuctrl_shadow
        sta     PPUCTRL
        lda     #$06
        sta     ppumask_shadow
        sta     PPUMASK
        jsr     chr_upload_init
        lda     #MAX_HP
        sta     ent_hp
        lda     #$00
        sta     $AA
        sta     current_weapon
        jsr     weapon_palette_setup
        jsr     chr_upload_run
        lda     #$00
        sta     scroll_x
        sta     scroll_subpixel
        sta     scroll_y
        sta     $B5
        sta     camera_y_offset
        sta     $B7
        sta     camera_x_offset
        sta     camera_x_offset_hi
        sta     ent_x_px
        sta     ent_x_sub
        sta     $43
        sta     $44
        sta     $B1
        lda     nametable_select
        jsr     render_full_nametable
        clc
        lda     nametable_select
        adc     #$01
        jsr     render_full_nametable
        lda     #$20
        sta     column_index
        jsr     clear_oam_buffer
        lda     ppumask_shadow
        ora     #$1E
        sta     ppumask_shadow
        sta     PPUMASK
        lda     ppuctrl_shadow
        ora     #$80
        sta     ppuctrl_shadow
        sta     PPUCTRL
        sta     vblank_done
        lda     #$40
        sta     $30
        lda     #$00
        sta     $31
        ldx     current_stage
        lda     stage_bank_table,x
        jsr     bank_switch_enqueue
        ldx     #$13
game_init_copy_stage_sprites:  lda     stage_intro_oam_data,x
        sta     oam_buffer,x
        dex
        bpl     game_init_copy_stage_sprites
        lda     #$C0
        sta     $FD
game_init_blink_loop:  ldy     #$60
        ldx     #$10
        lda     $FD
        and     #$08
        bne     blink_sprite_store
        ldy     #$F8
blink_sprite_store:  tya
        sta     oam_buffer,x
        dex
        dex
        dex
        dex
        bpl     blink_sprite_store
        jsr     wait_for_vblank
        dec     $FD
        bne     game_init_blink_loop
        jsr     clear_oam_buffer
        lda     #$DF
        sta     $3B
        lda     #$04
        sta     $3C
        jsr     reset_entity_slots
        jsr     boss_entrance_setup
        lda     current_stage
        cmp     #$0C
        bne     main_game_loop
        jmp     wily_game_loop

; =============================================================================
; main_game_loop -- Main Game Loop — per-frame update for normal stages ($8171)
; =============================================================================
main_game_loop:  lda     $AD
        beq     main_loop_check_start   ; skip item handler if no item
        jsr     item_collection_handler
main_loop_check_start:  lda     p1_new_presses
        and     #$08
        beq     main_loop_update_entities ; START not pressed
        jsr     palette_anim_run
main_loop_update_entities:  jsr     build_active_list ; scan entities within screen range
        jsr     entity_update_dispatch  ; run player state machine
        jsr     update_entity_positions ; move all entities
        jsr     entity_spawn_scan       ; spawn/despawn by scroll
        jsr     process_sound_and_bosses ; sound engine + boss check
        jsr     entity_ai_dispatch      ; run enemy AI for all entities
        jsr     render_all_sprites      ; build OAM buffer
        lda     transition_type
        beq     main_loop_check_scroll
        jsr     check_screen_transition
main_loop_check_scroll:  lda     $FB
        beq     main_loop_wait_frame
        inc     $FC
        cmp     $FC
        beq     main_loop_frame_skip
        bcs     main_loop_wait_frame
main_loop_frame_skip:  jsr     wait_one_rendering_frame
        lda     #$00
        sta     $FC
main_loop_wait_frame:  jsr     wait_for_vblank ; wait for NMI
        jmp     main_game_loop

        .byte   $10,$10,$10,$15,$15,$10
stage_intro_oam_data:  .byte   $60,$96,$01,$6C,$60,$97,$01,$74
        .byte   $60,$98,$01,$7C,$60,$99,$01,$84
        .byte   $60,$9A,$01
        .byte   $8C
stage_bank_table:                        ; PRG bank per stage index ($2A)
        .byte   $03                      ; $00 Heat Man   → bank $03
        .byte   $04                      ; $01 Air Man    → bank $04
        .byte   $01                      ; $02 Wood Man   → bank $01
        .byte   $07                      ; $03 Bubble Man → bank $07
        .byte   $06                      ; $04 Quick Man  → bank $06
        .byte   $00                      ; $05 Flash Man  → bank $00
        .byte   $05                      ; $06 Metal Man  → bank $05
        .byte   $02                      ; $07 Crash Man  → bank $02
        .byte   $08                      ; $08 Wily 1     → bank $08
        .byte   $08                      ; $09 Wily 2     → bank $08
        .byte   $09                      ; $0A Wily 3     → bank $09
        .byte   $09                      ; $0B Wily 4     → bank $09
        .byte   $09                      ; $0C Wily 5     → bank $09
        .byte   $FF                      ; terminator

; =============================================================================
; wily_spawn_gate_entities -- Wily Fortress Gate — spawn gate entities from bitmask ($81DE)
; =============================================================================
wily_spawn_gate_entities:  lda     $BC
        cmp     #$FF
        bne     wily_spawn_gate_loop
        ldx     #$00
        stx     current_entity_slot
        lda     #$7E
        ldx     #$0E
        jsr     spawn_entity_init
        lda     #$3B
        sta     $04BE
        lda     #$80
        sta     $047E
wily_spawn_gate_loop:  lda     #$00
        sta     current_entity_slot
        sta     temp_02
        lda     $BC
        sta     temp_03
wily_spawn_shift_flags:  lsr     temp_03
wily_spawn_check_done:  bcs     wily_spawn_next_bit
        lda     #$7C
        ldx     temp_02
        jsr     spawn_entity_init
        lda     wily_gate_anim_table,y
        sta     ent_y_spawn_px,y
        lda     wily_gate_y_pos_table,y
        sta     ent_x_spawn_px,y
wily_spawn_next_bit:  inc     temp_02
        lda     temp_02
        cmp     #$08
        bne     wily_spawn_shift_flags
        rts

; =============================================================================
; wily_game_loop -- Wily Fortress Main Loop — per-frame update with gate spawning ($8223)
; =============================================================================
wily_game_loop:  jsr     wily_spawn_gate_entities ; spawn/update gate entities
wily_loop_main:  lda     $AD
        beq     wily_loop_check_start
        jsr     item_collection_handler
wily_loop_check_start:  lda     p1_new_presses
        and     #$08
        beq     wily_loop_update_entities
        jsr     palette_anim_run
wily_loop_update_entities:  jsr     build_active_list
        jsr     entity_update_dispatch
        jsr     update_entity_positions
        jsr     process_sound_and_bosses
        jsr     entity_ai_dispatch
        jsr     render_all_sprites
        lda     transition_type
        beq     wily_loop_check_scroll
        jsr     check_screen_transition
wily_loop_check_scroll:  lda     $FB
        beq     wily_loop_wait_frame
        inc     $FC
        cmp     $FC
        beq     wily_loop_frame_skip
        bcs     wily_loop_wait_frame
wily_loop_frame_skip:  jsr     wait_one_rendering_frame
        lda     #$00
        sta     $FC
wily_loop_wait_frame:  jsr     wait_for_vblank ; wait for NMI
        jmp     wily_loop_main

wily_gate_anim_table:  .byte   $3B,$7B,$BB,$BB,$BB,$3B,$7B,$BB ; animation frame per gate position
wily_gate_y_pos_table:                   ; Y pixel position per gate
        .byte   $20,$20,$20,$70,$90,$E0,$E0,$E0

; =============================================================================
; check_screen_transition -- Screen Transition Check — test scroll boundaries for room changes ($8278)
; =============================================================================
; Called when scroll reaches a room boundary. Tests whether the current
; scroll position matches $14 (left boundary) or $15 (right boundary).
; $37 = transition_type: 0=none, 2=horizontal, 1/3=vertical/boss.
; $38 = current_screen: room index. get_screen_boundary returns room
; connectivity flags in Y; the mask tables select which flag bits
; permit left vs right exits for the given transition_type.
; =============================================================================
check_screen_transition:  ldx     scroll_x
        bne     check_vertical_transition ; scroll_x != 0: not at boundary, skip
        ldx     nametable_select
        beq     check_scroll_right      ; nametable 0: can't scroll further left
        cpx     scroll_screen_lo                     ; at left boundary nametable?
        bne     check_scroll_right
        ldy     current_screen                     ; Y = current_screen - 1 (previous room)
        dey
        jsr     get_screen_boundary     ; Y = connectivity flags for previous room
        tya
        ldy     transition_type                     ; index mask table by transition_type
        and     scroll_left_mask_table,y ; test if left exit allowed
        beq     check_scroll_right      ; blocked: try right instead
        jsr     transition_screen_left  ; execute full room transition left
        jmp     clear_scroll_request

check_scroll_right:  cpx     scroll_screen_hi             ; at right boundary nametable?
        bne     check_vertical_transition
        ldy     current_screen                     ; Y = current_screen
        jsr     get_screen_boundary     ; Y = connectivity flags for this room
        tya
        ldy     transition_type                     ; index mask table by transition_type
        and     scroll_right_mask_table,y ; test if right exit allowed
        beq     check_vertical_transition ; blocked: check vertical
        jsr     transition_screen_right ; execute full room transition right
        ldx     current_stage
        lda     nametable_select
        cmp     stage_max_screen_table,x ; reached final screen of stage?
        bne     scroll_transition_done
        jsr     boss_trigger_entrance   ; trigger boss door sequence
scroll_transition_done:  jmp     clear_scroll_request

check_vertical_transition:  lda     transition_type
        cmp     #$03                    ; transition_type $03 = boss entrance
        bne     clear_scroll_request
        lda     #$01
        sta     game_substate
        jmp     boss_death_sequence

clear_scroll_request:  lda     #$00
        sta     transition_type                     ; clear transition request
scroll_left_mask_table:  rts             ; (also serves as rts for no-transition path)
                                        ; mask_table[0]=$60(rts opcode), [1]=$40, [2]=$00, [3]=$80
        .byte   $40,$00,$80
scroll_right_mask_table:  .byte   $20,$80,$20,$40,$00 ; bitmask for right scroll boundary

; =============================================================================
; item_collection_handler -- Item Collection Handler — dispatch item pickup via pointer table ($82D5)
; =============================================================================
item_collection_handler:  sec
        lda     $AD
        sbc     #$76
        tay
        lda     #$00
        sta     $AD
        lda     item_handler_ptr_lo,y
        sta     jump_ptr
        lda     item_handler_ptr_hi,y
        sta     jump_ptr_hi
        jmp     (jump_ptr)

health_refill_large:
        lda     #$0A              ; large pickup: 10 ticks
        bne     health_refill_set ; always branch
health_refill_small:
        lda     #$02              ; small pickup: 2 ticks
health_refill_set:
        sta     $FD
        lda     ent_hp
        cmp     #MAX_HP
        bcs     health_refill_full_rts
        lda     #$07
        sta     $AA
health_refill_loop:  ldx     current_weapon
        lda     ent_hp
        cmp     #MAX_HP                    ; $1C = max HP (28)
        bcs     health_refill_done_jmp
        lda     frame_counter
        and     #$07
        bne     health_refill_render
        dec     $FD
        bmi     health_refill_done_jmp
        inc     ent_hp
        lda     #$28
        jsr     bank_switch_enqueue
health_refill_render:  jsr     render_all_sprites
        jsr     wait_for_vblank
        jmp     health_refill_loop

health_refill_done_jmp:  jmp     refill_complete

health_refill_full_rts:  rts

weapon_refill_large:
        lda     #$0A              ; large pickup: 10 ticks
        bne     weapon_refill_set ; always branch
weapon_refill_small:
        lda     #$02              ; small pickup: 2 ticks
weapon_refill_set:
        sta     $FD
        lda     current_weapon
        beq     refill_exit
        ldx     current_weapon
        lda     $9B,x
        cmp     #MAX_HP
        beq     refill_exit
        lda     #$07
        sta     $AA
weapon_refill_loop:  ldx     current_weapon
        lda     $9B,x
        cmp     #MAX_HP                    ; $1C = max energy (28)
        bcs     refill_complete
        lda     frame_counter
        and     #$07
        bne     weapon_refill_render
        dec     $FD
        bmi     refill_complete
        inc     $9B,x
        lda     #$28
        jsr     bank_switch_enqueue
weapon_refill_render:  jsr     render_all_sprites
        jsr     wait_for_vblank
        jmp     weapon_refill_loop

refill_complete:  lda     #$00
        sta     $FD
        sta     $AA
        lda     #$03
        sta     game_substate
        jsr     weapon_set_base_type
refill_exit:  rts

etank_pickup:
        lda     current_etanks               ; current E-tank count
        cmp     #$04              ; max = 4
        bcs     etank_pickup_done
        inc     current_etanks               ; add E-tank
etank_pickup_done:
        lda     #$42
        jsr     bank_switch_enqueue
        rts

extra_life_pickup:
        lda     current_lives               ; current lives count
        cmp     #$63              ; max = 99
        bcs     extra_life_done
        inc     current_lives
        lda     #$42
        jsr     bank_switch_enqueue
extra_life_done:
        rts

        jsr     wily_teleport_sequence
        lda     #$00
        sta     $FD
        ldx     $BA
        lda     wily_door_bank_table,x
        sta     $FE
        dex
        stx     current_stage
        jsr     wait_screen_fade
        lda     #$0C
        sta     current_stage
        ldx     #$05
        lda     $BA
        cmp     #$04
        bne     wily_door_transition
        ldx     #$02
wily_door_transition:  jsr     set_palette_colors
        inc     nametable_select
        inc     ent_x_screen
        inc     current_screen
        inc     scroll_screen_lo
        inc     scroll_screen_hi
        lda     #$20
        sta     ent_x_px
        lda     #$B4
        sta     ent_y_px
        jsr     reset_player_state
        lda     #$0B
        jsr     bank_switch_enqueue
        lda     $BA
        sta     $B3
        dec     $B3
        jsr     boss_wily_entrance
wily_door_bank_table:  rts

        .byte   $06,$04,$0D,$07,$11,$09,$04,$10
wily_teleport_sequence:  lda     #$30
        jsr     bank_switch_enqueue
        lda     #$0B
        sta     game_substate
        jsr     weapon_set_base_type
        jsr     reset_entity_slots
wily_teleport_wait:  lda     ent_anim_id
        cmp     #$03
        beq     wily_teleport_done
        jsr     render_all_sprites
        jsr     wait_for_vblank
        jmp     wily_teleport_wait

wily_teleport_done:  lda     #$00
        sta     ent_flags
        jsr     render_all_sprites
        rts

reset_player_state:  lda     #$C0
        sta     ent_flags
        lda     #$00
        sta     $36
        sta     game_substate
        jsr     weapon_set_base_type
        rts

wait_screen_fade:  jsr     scroll_column_render
        jsr     wait_for_vblank
        lda     $FD
        cmp     #$60
        bne     wait_screen_fade
        rts

wily_gate_mark_beaten:
        jsr     wily_teleport_sequence
        ldx     $B3
        lda     $BC               ; boss beaten bitmask
        ora     boss_beaten_mask_lo,x
        sta     $BC
        cmp     #$FF              ; all bosses beaten?
        bne     wily_fade_reverse
        lda     #$00
        sta     $FD
        lda     #$14
        sta     $FE
        jsr     wait_screen_fade
        lda     #$28
        jsr     render_full_nametable
        lda     #$28
        sta     nametable_select
        sta     ent_x_screen
        sta     scroll_screen_lo
        sta     scroll_screen_hi
        bne     wily_set_palette
wily_fade_reverse:
        dec     nametable_select
        dec     ent_x_screen
        dec     current_screen
        dec     scroll_screen_lo
        dec     scroll_screen_hi
wily_set_palette:
        ldx     #$08
        jsr     set_palette_colors
        lda     #$00
        sta     $B1
        ldx     $B3
        clc
        lda     wily_gate_anim_table,x
        adc     #$07
        sta     ent_y_px
        lda     wily_gate_y_pos_table,x
        sta     ent_x_px
        jsr     reset_player_state
        lda     #$09
        jsr     bank_switch_enqueue
        jsr     wily_spawn_gate_entities
        rts

set_palette_colors:  ldy     #$02
set_palette_loop:  lda     palette_color_data,x
        sta     $035F,y
        sta     $037F,y
        sta     $038F,y
        sta     $039F,y
        sta     $03AF,y
        dex
        dey
        bpl     set_palette_loop
        rts

palette_color_data:                      ; NES palette indices (PPU $3F00 values)
        .byte   $21,$11,$01,$19,$09,$0A,$19,$09,$21
        jsr     wily_teleport_sequence
        lda     #$29
        jsr     render_full_nametable
        lda     #$29
        sta     nametable_select
        sta     ent_x_screen
        sta     scroll_screen_lo
        sta     scroll_screen_hi
        lda     #$00
        sta     $FD
        lda     #$15
        sta     $FE
        jsr     wait_screen_fade
        lda     #$2A
        jsr     render_full_nametable
        lda     #$B4
        sta     ent_y_px
        lda     #$28
        sta     ent_x_px
        jsr     reset_player_state
        lda     #$0B
        jsr     bank_switch_enqueue
        jsr     boss_trigger_entrance
        rts

item_handler_ptr_lo:                     ; item pickup handler address low bytes
        .byte   $EC,$F0,$27,$2B,$6F,$7D,$8B,$23,$A3
item_handler_ptr_hi:  .byte   $82,$82,$83,$83,$83,$83,$83,$84 ; item handler pointer table (high)
        .byte   $84

; =============================================================================
; entity_update_dispatch -- Entity Update / Player State Machine — dispatch based on $2C ($84EE)
; =============================================================================
entity_update_dispatch:  lda     $AA
        and     #$04
        beq     entity_dispatch_setup   ; check pause flag bit 2
        rts

entity_dispatch_setup:  lda     #$00
        sta     transition_type
        ldx     game_substate                     ; current player state index
        lda     player_state_ptr_lo,x
        sta     jump_ptr
        lda     player_state_ptr_hi,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)

        lda     ent_anim_id
        cmp     #$04
        bne     player_state_rts
        lda     #$C0
        sta     ent_y_vel_sub
        lda     #$FF
        sta     ent_y_vel
        lda     #$00
        sta     $AA
        lda     #$03
        sta     game_substate
        jsr     weapon_set_base_type
        lda     ent_x_px
        sta     jump_ptr
        lda     ent_x_screen
        sta     jump_ptr_hi
        lda     ent_y_px
        sta     $0A
        lda     #$00
        sta     $0B
        jsr     lookup_tile_from_map
        lda     temp_00
        cmp     #$04
        bne     player_state_rts
        lda     #$04
        sta     $FB
player_state_rts:  rts

        rts
player_state_gun_update:
        lda     ent_flags             ; player entity flags
        and     #$40              ; check flip bit
        eor     #$40              ; toggle
        sta     $42
        jsr     player_horiz_movement
        jsr     player_vertical_physics
        lda     ent_anim_id
        beq     player_select_ground_state
        jsr     weapon_set_base_type
        rts
player_select_ground_state:
        ldy     #$06
        lda     temp_00
        beq     player_set_state
        ldy     #$03
player_set_state:  sty     game_substate
        rts

        jsr     player_check_fire_weapon
        lda     controller_1               ; controller input
        and     #$C0              ; check A+B buttons
        beq     player_state_skip_facing
        lda     #$04
        sta     game_substate
        jsr     player_update_facing
player_state_skip_facing:
        jsr     player_set_max_speed
        jsr     player_horiz_movement
        jsr     player_vertical_physics
        lda     temp_00
        bne     player_state_common_exit
        lda     #$06
        sta     game_substate
        jsr     weapon_set_base_type
        rts

player_state_common_exit:  lda     p1_new_presses
        and     #$01
        beq     player_state_set_weapon
        lda     $3B
        sta     ent_y_vel_sub
        lda     $3C
        sta     ent_y_vel
        lda     #$06
        sta     game_substate
player_state_set_weapon:  jsr     weapon_set_base_type
        rts

        jsr     player_check_fire_weapon
        jsr     player_update_facing
        jsr     player_set_max_speed
        jsr     player_horiz_movement
        jsr     player_vertical_physics
        lda     temp_00
        beq     player_state_to_idle
        lda     controller_1
        and     #$C0
        bne     player_state_check_land
        lda     #$03
        sta     game_substate
        bne     player_state_jump_exit
player_state_check_land:  lda     ent_anim_id
        cmp     #$01
        bne     player_state_jump_exit
        lda     #$05
        sta     game_substate
player_state_jump_exit:  jmp     player_state_common_exit

        jsr     player_check_fire_weapon
        jsr     player_update_facing
        jsr     player_set_max_speed
        jsr     player_horiz_movement
        jsr     player_vertical_physics
        lda     temp_00
        bne     player_state_walk_check
player_state_to_idle:  lda     #$06
        sta     game_substate
        jsr     weapon_set_base_type
        rts

player_state_walk_check:
        lda     controller_1
        and     #$C0
        bne     player_state_check_dir
        lda     #$07
        sta     game_substate
player_state_check_dir:  jmp     player_state_common_exit

        jsr     player_check_fire_weapon
        lda     #$00
        sta     ent_x_vel_sub             ; clear X velocity (sub-pixel)
        sta     ent_x_vel             ; clear X velocity (high byte)
        lda     controller_1               ; controller input
        and     #$C0
        bne     player_state_update_face
        lda     $3E
        ora     $3F
        bne     player_state_decel_speed
        lda     $40
        and     #$0F
        beq     player_state_run_movement
        jsr     player_handle_conveyor
        jmp     player_state_run_movement

player_state_decel_speed:  sec
        lda     $3E
        sbc     #$80
        sta     $3E
        tax
        lda     $3F
        sbc     #$00
        sta     $3F
        bmi     player_state_speed_zero
        bne     player_state_run_movement
        cpx     #$80
        bcs     player_state_run_movement
player_state_speed_zero:  lda     #$00
        sta     $3E
        sta     $3F
        beq     player_state_run_movement
player_state_update_face:  jsr     player_update_facing
        jsr     player_set_max_speed
player_state_run_movement:  jsr     player_horiz_movement
        lda     ent_y_vel
        bmi     player_state_climbing
        jsr     player_vertical_physics
        lda     temp_00
        bne     player_state_on_ground_rts
        lda     controller_1
        and     #$01
        bne     player_state_on_ground_rts
        lda     ent_y_vel
        bmi     player_state_on_ground_rts
        cmp     #$01
        bcc     player_state_on_ground_rts
        beq     player_state_on_ground_rts
        lda     #$01
        sta     ent_y_vel
        lda     #$00
        sta     ent_y_vel_sub
player_state_on_ground_rts:  rts

player_state_climbing:  jsr     player_vertical_physics
        lda     temp_00
        beq     player_state_climb_set_weapon
        lda     #$29
        jsr     bank_switch_enqueue
        ldx     #$05
        lda     p1_prev_buttons
        and     #$C0
        bne     player_state_climb_dir
        ldx     #$08
player_state_climb_dir:  stx     game_substate
        jmp     player_state_common_exit

player_state_climb_set_weapon:  jsr     weapon_set_base_type
        rts

        jsr     player_check_fire_weapon
        jsr     player_update_facing
        jsr     player_set_max_speed
        jsr     player_horiz_movement
        jsr     player_vertical_physics
        lda     temp_00
        bne     player_ladder_check_buttons
        jmp     player_state_to_idle
player_ladder_check_buttons:
        lda     controller_1
        and     #$C0
        bne     player_ladder_state_jump
        lda     ent_anim_id
        cmp     #$02
        bne     player_ladder_state_exit
        lda     #$03
        sta     game_substate
        bne     player_ladder_state_exit
player_ladder_state_jump:  lda     #$04
        sta     game_substate
player_ladder_state_exit:  jmp     player_state_common_exit

player_state_ladder_idle:  lda     #$09
        sta     game_substate
        lda     controller_1
        and     #$02
        beq     player_ladder_clear_ab
        jmp     player_ladder_fire_weapon

player_ladder_clear_ab:  lda     #$00
        sta     $AB
player_ladder_check_input:  lda     controller_1
        and     #$31
        bne     player_ladder_check_updown
        jmp     player_ladder_clear_vel

player_ladder_check_updown:  and     #$30
        beq     player_ladder_to_idle
        and     #$10
        beq     player_ladder_move_down
        ldy     #$00
        ldx     #$C0
        lda     $35
        and     #$0C
        bne     player_ladder_check_left
        lda     ent_y_px
        and     #$F0
        sec
        sbc     #$0C
        sta     ent_y_px
        lda     $F9
        sbc     #$00
        sta     $F9
        ldx     #$03
        jmp     player_ladder_set_state

player_ladder_check_left:  and     #$08
        bne     player_ladder_check_solid
        lda     #$0A
        sta     game_substate
        bne     player_ladder_check_solid
player_ladder_move_down:  lda     $35
        cmp     #$01
        bne     player_ladder_set_vel
        lda     ent_y_px
        clc
        adc     #$0C
        sta     ent_y_px
        lda     $F9
        adc     #$00
        sta     $F9
player_ladder_set_vel:  ldy     #$FF
        ldx     #$40
        lda     $35
        and     #$0C
        bne     player_ladder_check_solid
        lda     #$0A
        sta     game_substate
player_ladder_check_solid:  lda     $3D
        beq     player_ladder_store_vel
        ldy     #$00
        ldx     #$00
player_ladder_store_vel:  sty     ent_y_vel
        stx     ent_y_vel_sub
        jsr     player_ground_collision
        lda     $35
        beq     player_ladder_to_idle
        jsr     player_vertical_physics
        lda     temp_00
        beq     player_ladder_exit
        ldx     #$03
        bne     player_ladder_set_state
player_ladder_to_idle:  ldx     #$06
player_ladder_set_state:  stx     game_substate
        lda     #$00
        sta     $35
        lda     #$C0
        sta     ent_y_vel_sub
        lda     #$FF
        sta     ent_y_vel
        bne     player_ladder_exit
player_ladder_clear_vel:  lda     #$00
        sta     ent_anim_frame
player_ladder_exit:  jsr     weapon_set_base_type
        rts

player_ladder_fire_weapon:  jsr     player_update_facing
        jsr     fire_weapon_dispatch
        bcc     player_ladder_fire_done
        jmp     player_ladder_check_input

player_ladder_fire_done:  jmp     player_ladder_clear_vel

player_ladder_clear_anim:
        lda     ent_anim_id             ; animation state
        cmp     #$03
        bne     player_ladder_clear_rts
        lda     #$00
        sta     ent_anim_frame             ; clear Y velocity sub-pixel
player_ladder_clear_rts:
        rts

; =============================================================================
; player_state_ptr_lo -- Player State Dispatch Table — 12 states (idle, walk, jump, etc.) ($8783)
; =============================================================================
player_state_ptr_lo:                     ; player state handler address low bytes (12 states)
        .byte   $08,$45,$46,$69,$A6,$D3,$FB,$8C,$8C,$BC,$BC,$76
player_state_ptr_hi:  .byte   $85,$85,$85,$85,$85,$85,$85,$86 ; player state pointer table (high)
        .byte   $86,$86,$86,$87

; =============================================================================
; player_check_fire_weapon -- Player Weapon Fire — check A button, fire weapon, check ladder ($879B)
; =============================================================================
player_check_fire_weapon:  lda     controller_1
        and     #$02
        bne     player_fire_weapon
        lda     #$00
        sta     $AB
        beq     player_check_ladder_rts
player_fire_weapon:  jsr     fire_weapon_dispatch ; call weapon fire handler
player_check_ladder_rts:  lda     $35
        bne     player_check_ladder_snap
player_fire_rts:  rts

player_check_ladder_snap:  lda     controller_1
        and     #$30
        beq     player_fire_rts
        ora     $35
        cmp     #$11
        beq     player_fire_rts
        cmp     #$2E
        beq     player_fire_rts
        lda     ent_x_px
        sta     $2E
        and     #$F0
        ora     #$08
        sec
        sta     ent_x_px
        sbc     $2E
        bcc     player_snap_left
        sta     temp_00
        jsr     scroll_right_handler
        jmp     player_snap_update_facing

player_snap_left:  eor     #$FF
        clc
        adc     #$01
        sta     temp_00
        jsr     scroll_left_handler
player_snap_update_facing:  lda     ent_flags
        eor     #$40
        sta     ent_flags
        jsr     weapon_set_base_type
        pla
        pla
        jmp     player_state_ladder_idle

; =============================================================================
; player_update_facing -- Player Facing Direction — update sprite flip from D-pad input ($87F2)
; =============================================================================
player_update_facing:  lda     controller_1
        and     #$C0
        beq     player_facing_rts
        lda     ent_flags
        and     #$BF
        sta     ent_flags
        lda     controller_1
        and     #$40
        eor     #$40
        ora     ent_flags
        sta     ent_flags
player_facing_rts:  rts

; =============================================================================
; player_set_max_speed -- Player Speed Control — max speed, acceleration, deceleration ($880D)
; =============================================================================
player_set_max_speed:  ldx     game_substate      ; player state index for speed table
        lda     max_speed_hi_table,x
        sta     ent_x_vel
        lda     max_speed_lo_table,x
        sta     ent_x_vel_sub
        lda     $3D
        cmp     #$03
        bne     player_check_accel_start
        lda     game_substate
        cmp     #$06
        beq     player_check_accel_start
        lda     #$00
        sta     ent_x_vel_sub
        sta     ent_x_vel
player_check_accel_start:  lda     $40
        bmi     player_check_facing_change
        lda     $3E
        ora     $3F
        beq     player_handle_conveyor
        bne     player_decelerate
player_check_facing_change:  lda     ent_flags
        and     #$40
        cmp     $42
        beq     player_accelerate
player_decelerate:  ldx     #$00
        lda     game_substate
        cmp     #$06
        beq     player_apply_decel
        inx
        lda     controller_1
        and     #$C0
        beq     player_apply_decel
        inx
player_apply_decel:  sec
        lda     $3E
        sbc     decel_rate_table,x
        sta     $3E
        tax
        lda     $3F
        sbc     #$00
        sta     $3F
        bmi     player_speed_zero
        bne     player_store_max_speed
        cpx     #$80
        bcs     player_store_max_speed
player_speed_zero:  lda     #$00
        sta     $3E
        sta     $3F
        beq     player_set_face_dir
player_store_max_speed:  lda     $3E
        sta     ent_x_vel_sub
        lda     $3F
        sta     ent_x_vel
        jmp     player_handle_conveyor

player_accelerate:  sec
        lda     ent_x_vel_sub
        sbc     $3E
        lda     ent_x_vel
        sbc     $3F
        bcc     player_decelerate
        lda     ent_x_vel_sub
        sta     $3E
        lda     ent_x_vel
        sta     $3F
player_set_face_dir:  lda     ent_flags
        and     #$40
        sta     $42
player_handle_conveyor:  lda     $40
        bpl     player_conveyor_check
        rts

player_conveyor_check:  and     #$0F
        beq     player_no_conveyor
        lda     ent_flags
        and     #$40
        cmp     $AF
        beq     player_conveyor_forward
        sec
        lda     ent_x_vel_sub
        sbc     $4F
        sta     ent_x_vel_sub
        lda     ent_x_vel
        sbc     $50
        sta     ent_x_vel
        bcc     player_conveyor_reverse
        lda     ent_flags
        and     #$40
        sta     $42
        rts

player_conveyor_reverse:  lda     ent_x_vel_sub
        eor     #$FF
        adc     #$01
        sta     ent_x_vel_sub
        lda     ent_x_vel
        eor     #$FF
        adc     #$00
        sta     ent_x_vel
        lda     $AF
        sta     $42
        rts

player_conveyor_forward:  clc
        lda     ent_x_vel_sub
        adc     $4F
        sta     ent_x_vel_sub
        lda     ent_x_vel
        adc     $50
        sta     ent_x_vel
        lda     $AF
        sta     $42
        rts

player_no_conveyor:  lda     $3F
        ora     $3E
        beq     player_conveyor_idle
        rts

player_conveyor_idle:  lda     ent_flags
        and     #$40
        sta     $42
        rts

decel_rate_table:  .byte   $80,$02,$04  ; deceleration rate per state
max_speed_hi_table:  .byte   $00,$00,$00,$00,$00,$01,$01,$00 ; max speed high byte per state
        .byte   $00,$00,$00
max_speed_lo_table:  .byte   $00,$00,$90,$00 ; max speed low byte per state
        jsr     addr_5060
        .byte   $80,$00,$00,$00

; =============================================================================
; player_horiz_movement -- Player Horizontal Movement — X position update with scroll ($8922)
; =============================================================================
player_horiz_movement:  ldx     ent_x_screen
        stx     $2D
        ldy     ent_x_px
        sty     $2E
        lda     ent_x_sub
        sta     $2F
        lda     #$00
        sta     temp_00
        lda     $42
        and     #$40
        beq     player_move_left_check
        cpx     scroll_screen_hi
        bne     player_move_right
        cpy     #$EC
        bcc     player_move_right
        lda     #$02
        sta     transition_type
        jmp     player_scroll_right

player_move_right:  clc
        lda     ent_x_sub
        adc     ent_x_vel_sub
        sta     ent_x_sub
        lda     ent_x_px
        adc     ent_x_vel
        sta     ent_x_px
        lda     ent_x_screen
        adc     #$00
        sta     ent_x_screen
        clc
        lda     ent_x_px
        adc     #$08
        sta     jump_ptr
        lda     ent_x_screen
        adc     #$00
        sta     jump_ptr_hi
        jsr     player_check_tile_ahead
        lda     temp_00
        beq     player_right_check_delta
        lda     #$00
        sta     ent_x_sub
        lda     jump_ptr
        and     #$0F
        sta     temp_00
        sec
        lda     ent_x_px
        sbc     temp_00
        sta     ent_x_px
        lda     ent_x_screen
        sbc     #$00
        sta     ent_x_screen
player_right_check_delta:  sec
        lda     ent_x_px
        sbc     $2E
        sta     temp_00
        bpl     player_scroll_right
        clc
        eor     #$FF
        adc     #$01
        sta     temp_00
        jmp     player_scroll_left

player_move_left_check:  cpx     scroll_screen_lo
        bne     player_move_left
        cpy     #$14
        bcs     player_move_left
        jmp     player_scroll_left

player_move_left:  sec
        lda     ent_x_sub
        sbc     ent_x_vel_sub
        sta     ent_x_sub
        lda     ent_x_px
        sbc     ent_x_vel
        sta     ent_x_px
        lda     ent_x_screen
        sbc     #$00
        sta     ent_x_screen
        sec
        lda     ent_x_px
        sbc     #$08
        sta     jump_ptr
        lda     ent_x_screen
        sbc     #$00
        sta     jump_ptr_hi
        jsr     player_check_tile_ahead
        lda     temp_00
        beq     player_left_check_delta
        lda     #$00
        sta     ent_x_sub
        lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     ent_x_px
        sta     ent_x_px
        lda     ent_x_screen
        adc     #$00
        sta     ent_x_screen
player_left_check_delta:  sec
        lda     $2E
        sbc     ent_x_px
        sta     temp_00
        bpl     player_scroll_left
        eor     #$FF
        clc
        adc     #$01
        sta     temp_00
player_scroll_right:  jsr     scroll_right_handler
        jsr     player_ground_collision
        rts

player_scroll_left:  jsr     scroll_left_handler
        jsr     player_ground_collision
        rts

player_check_tile_ahead:  lda     #$02
        sta     temp_01
tile_check_loop:  ldx     temp_01
        clc
        lda     ent_y_px
        adc     tile_y_offset_table,x
        sta     $0A
        lda     $F9
        adc     tile_y_page_table,x
        sta     $0B
        jsr     lookup_cached_tile
        ldx     temp_01
        lda     temp_00
        sta     $32,x
        dec     temp_01
        bpl     tile_check_loop
        lda     #$00
        sta     temp_00
        ldx     #$02
tile_eval_loop:  ldy     $32,x
        lda     tile_type_flags,y
        bpl     tile_check_spike
        ldy     #$02
        sty     transition_type
        bne     tile_combine_result
tile_check_spike:  cmp     #$03
        bne     tile_combine_result
        ldy     invincibility_timer
        bne     tile_combine_result
        lda     #$00
        sta     game_substate
        jmp     boss_death_sequence

tile_combine_result:  ora     temp_00
        sta     temp_00
        dex
        bpl     tile_eval_loop
        rts

gravity_hi_table:  .byte   $40,$1E      ; gravity acceleration per mode
frame_skip_table:  .byte   $00,$04
scroll_speed_table:  .byte   $04,$05
player_bounds_table:  .byte   $DF,$80
tile_type_flags:  .byte   $00,$01,$00,$03,$00,$01,$01,$01 ; tile type collision flags
        .byte   $81
tile_y_offset_table:  .byte   $F4,$FC,$0B
tile_y_page_table:  .byte   $FF,$FF,$00

; =============================================================================
; player_ground_collision -- Player Ground Collision — scan tiles below for solid/lava/item ($8A84)
; =============================================================================
player_ground_collision:  lda     ent_x_px
        sta     jump_ptr
        lda     ent_x_screen
        sta     jump_ptr_hi
        lda     #$02
        sta     temp_01
ground_tile_loop:  ldx     temp_01
        clc
        lda     ent_y_px
        adc     tile_y_offset_table,x
        sta     $0A
        lda     $F9
        adc     tile_y_page_table,x
        sta     $0B
        jsr     lookup_tile_from_map
        ldx     temp_01
        lda     temp_00
        sta     $32,x
        dec     temp_01
        bpl     ground_tile_loop
        ldx     #$00
        lda     $B1
        beq     ground_check_lava
        lda     $B3
        cmp     #$03
        beq     ground_spawn_item
ground_check_lava:  lda     $33
        cmp     #$04
        bne     ground_store_params
        lda     $FB
        bne     ground_spawn_item
        lda     ent_y_vel
        bpl     ground_spawn_item
        lda     #$3B
        jsr     bank_switch_enqueue
        lda     $042E
        bmi     ground_spawn_item
        ldy     #$0E
        ldx     #$0E
        jsr     weapon_spawn_projectile
        sec
        lda     $04AE
        sbc     #$04
        and     #$F0
        sta     $04AE
ground_spawn_item:  inc     $39
        lda     $39
        cmp     #$60
        bcc     ground_set_params
        beq     ground_spawn_random_item
        cmp     #$80
        bcc     ground_set_params
        lda     #$00
        sta     $39
ground_spawn_random_item:  lda     $F9
        bne     ground_set_params
        stx     current_entity_slot
        lda     #$0E
        jsr     spawn_entity_from_parent
        bcs     ground_set_params
        lda     ent_spawn_flags,y
        and     #$F0
        sta     ent_spawn_flags,y
ground_set_params:  ldx     #$00
        inx
ground_store_params:  lda     gravity_hi_table,x
        sta     $30
        lda     frame_skip_table,x
        sta     $FB
        lda     scroll_speed_table,x
        sta     $3C
        lda     player_bounds_table,x
        sta     $3B
        lda     #$00
        sta     $35
        lda     #$02
        sta     temp_01
        ldx     #$02
ground_calc_platform_dir:  lda     $32,x
        cmp     #$02
        bne     ground_shift_platform
        lda     temp_01
        ora     $35
        sta     $35
ground_shift_platform:  asl     temp_01
        dex
        bpl     ground_calc_platform_dir
        sec
        lda     ent_y_sub
        sbc     ent_y_vel_sub
        lda     ent_y_px
        sbc     ent_y_vel
        ldx     ent_y_vel
        bmi     ground_check_above
        sec
        sbc     #$0C
        sta     $0A
        lda     $F9
        sbc     #$00
        jmp     ground_store_above

ground_check_above:  clc
        adc     #$0C
        sta     $0A
        lda     $F9
        adc     #$00
ground_store_above:  sta     $0B
        jsr     lookup_tile_from_map
        lda     temp_00
        cmp     #$02
        bne     ground_collision_rts
        lda     ent_y_vel
        bmi     ground_above_left
        lda     #$10
        bne     ground_store_dir
ground_above_left:  lda     #$01
ground_store_dir:  ora     $35
        sta     $35
ground_collision_rts:  rts

; =============================================================================
; player_vertical_physics -- Player Vertical Physics — gravity, fall limit, ceiling snap ($8B83)
; =============================================================================
player_vertical_physics:  lda     ent_y_px
        sta     $2E
        lda     ent_y_sub
        sta     $2F
        lda     #$00
        sta     temp_00
        lda     ent_y_vel
        bpl     player_apply_gravity
        dec     temp_00
player_apply_gravity:  sec
        lda     ent_y_sub
        sbc     ent_y_vel_sub
        sta     ent_y_sub
        lda     ent_y_px
        sbc     ent_y_vel
        sta     ent_y_px
        tax
        lda     $F9
        sbc     temp_00
        sta     $F9
        cpx     #$04
        bcs     player_check_fall_limit
        lda     game_substate
        cmp     #$09
        beq     player_set_scroll_trigger
        cmp     #$0A
        bne     player_gravity_falling
player_set_scroll_trigger:  lda     #$01
        sta     transition_type
        bne     player_gravity_falling
player_check_fall_limit:  cpx     #$E8
        bcc     player_gravity_falling
        lda     $F9
        bmi     player_gravity_falling
        lda     #$03
        sta     transition_type
player_gravity_falling:  lda     ent_y_vel
        bmi     player_gravity_rising
        sec
        lda     ent_y_px
        sbc     #$0C
        sta     $0A
        lda     $F9
        sbc     #$00
        sta     $0B
        jsr     player_floor_tile_check
        lda     temp_00
        beq     player_apply_gravity_sub
        lda     #$00
        sta     ent_y_sub
        lda     $0A
        and     #$0F
        eor     #$0F
        sec
        adc     ent_y_px
        sta     ent_y_px
player_gravity_stop:  lda     #$00
        sta     ent_y_vel_sub
        sta     ent_y_vel
player_apply_gravity_sub:  sec
        lda     ent_y_vel_sub
        sbc     $30
        sta     ent_y_vel_sub
        lda     ent_y_vel
        sbc     $31
        sta     ent_y_vel
        bpl     player_gravity_rts
        cmp     #$F4
        bcs     player_gravity_rts
        lda     #$00
        sta     ent_y_vel_sub
        lda     #$F4
        sta     ent_y_vel
player_gravity_rts:  rts

player_gravity_rising:  clc
        lda     ent_y_px
        adc     #$0C
        sta     $0A
        lda     $F9
        adc     #$00
        sta     $0B
        jsr     player_floor_tile_check
        jsr     check_platform_collision
        lda     temp_00
        bne     player_ceiling_snap
        bcs     player_ceiling_set_flag
        bcc     player_apply_gravity_sub
player_ceiling_snap:  lda     #$00
        sta     ent_y_sub
        lda     ent_y_px
        pha
        lda     $0A
        and     #$0F
        sta     ent_y_px
        pla
        sec
        sbc     ent_y_px
        sta     ent_y_px
        lda     $F9
        sbc     #$00
        sta     $F9
        jmp     player_gravity_stop

player_ceiling_set_flag:  lda     #$01
        sta     temp_00
        rts

; =============================================================================
; player_floor_tile_check -- Player Floor Tile Check — scan floor tiles for collision type ($8C6A)
; =============================================================================
player_floor_tile_check:  lda     #$01
        sta     temp_01
floor_tile_loop:  ldx     temp_01
        clc
        lda     ent_x_px
        adc     floor_x_offset_table,x
        sta     jump_ptr
        lda     ent_x_screen
        adc     floor_x_page_table,x
        sta     jump_ptr_hi
        jsr     lookup_cached_tile
        ldx     temp_01
        lda     temp_00
        sta     $32,x
        dec     temp_01
        bpl     floor_tile_loop
        lda     #$00
        sta     $40
        ldx     #$01
floor_tile_eval:  lda     $32,x
        cmp     #$08
        bcs     floor_check_spike
        cmp     #$05
        bcc     floor_check_spike
        sbc     #$05
        tay
        lda     floor_conveyor_type_table,y
        sta     $40
        bmi     floor_set_solid
        tay
        lda     $44,y
        sta     $AF
        lda     #$01
        sta     $50
        lda     #$00
        sta     $4F
floor_set_solid:  lda     #$01
        bne     floor_store_result
floor_check_spike:  cmp     #$03
        bne     floor_check_done
        ldy     invincibility_timer
        bne     floor_check_done
        lda     #$00
        sta     game_substate
        jmp     boss_death_sequence

floor_check_done:  dex
        bpl     floor_tile_eval
        lda     $32
        ora     $33
        and     #$01
floor_store_result:  sta     temp_00
        lda     $35
        beq     floor_tile_rts
        cmp     #$01
        beq     floor_set_scroll_trigger
        ldx     $F9
        bpl     floor_tile_rts
        lda     controller_1
        and     #$30
        beq     floor_tile_rts
        ldx     #$01
        stx     transition_type
floor_set_scroll_trigger:  sta     temp_00
floor_tile_rts:  rts

floor_x_offset_table:  .byte   $07,$F9
floor_x_page_table:  .byte   $00,$FF
floor_conveyor_type_table:  .byte   $01,$02,$80 ; conveyor belt direction per tile

; =============================================================================
; check_platform_collision -- Platform Collision — scan entity list for rideable platforms ($8CF4)
; =============================================================================
check_platform_collision:  sec
        lda     ent_x_px
        sbc     scroll_x
        sta     jump_ptr
        clc
        lda     $2E
        adc     #$0C
        sta     jump_ptr_hi
        lda     current_weapon
        cmp     #$09                    ; weapon >= Item 1?
        bcc     platform_skip_secondary ; no — skip secondary platform scan
        ldx     #$02
platform_scan_secondary:  lda     $05A0,x
        bne     platform_check_secondary
platform_scan_next:  dex
        bpl     platform_scan_secondary
platform_skip_secondary:
        ldx     #$0F
platform_scan_primary:  lda     $0160,x
        bne     platform_check_y
platform_skip_primary:  dex
        bpl     platform_scan_primary
        clc
        rts

platform_check_y:  lda     $F9
        bne     platform_skip_primary
        sec
        lda     ent_x_spawn_px,x
        sbc     scroll_x
        sta     $0C
        sec
        sbc     jump_ptr
        bcs     platform_check_range
        eor     #$FF
        adc     #$01
platform_check_range:  cmp     $0160,x
        bcs     platform_skip_primary
        lda     ent_y_spawn_px,x
        cmp     jump_ptr_hi
        bcc     platform_skip_primary
        lda     $0170,x
        cmp     $0A
        beq     platform_check_type
        bcs     platform_skip_primary
platform_check_type:  lda     ent_spawn_type,x
        cmp     #$13
        bne     platform_land_on
        inc     $04F0,x
platform_land_on:  sec
        lda     $0170,x
        sbc     #$0C
        sta     ent_y_px
        lda     $F9
        sbc     #$00
        sta     $F9
        lda     #$00
        sta     ent_y_sub
        sta     ent_y_vel_sub
        lda     #$FF
        sta     ent_y_vel
        lda     #$01
        sta     $40
        lda     ent_spawn_flags,x
        and     #$40
        sta     $AF
        lda     $0630,x
        sta     $4F
        lda     $0610,x
        sta     $50
        sec
        rts

platform_check_secondary:  lda     $F9
        bne     platform_not_found
        sec
        lda     $0462,x
        sbc     scroll_x
        sta     $0C
        sec
        sbc     jump_ptr
        bcs     platform_sec_check_range
        eor     #$FF
        adc     #$01
platform_sec_check_range:  cmp     $05A0,x
        bcs     platform_not_found
        lda     $04A2,x
        cmp     jump_ptr_hi
        bcc     platform_not_found
        lda     $05A3,x
        cmp     $0A
        beq     platform_sec_check_type
        bcs     platform_not_found
platform_sec_check_type:  lda     $0402,x
        cmp     #$3A
        bne     platform_sec_land_on
        lda     $04E2,x
        ora     #$80
        sta     $04E2,x
platform_sec_land_on:  sec
        lda     $05A3,x
        sbc     #$0C
        sta     ent_y_px
        lda     $F9
        sbc     #$00
        sta     $F9
        lda     #$00
        sta     ent_y_sub
        sta     ent_y_vel_sub
        lda     #$FF
        sta     ent_y_vel
        lda     #$01
        sta     $40
        lda     $0422,x
        and     #$40
        sta     $AF
        lda     $0622,x
        sta     $4F
        lda     $0602,x
        sta     $50
        sec
        rts

platform_not_found:  jmp     platform_scan_next

; =============================================================================
; scroll_right_handler -- Scroll Right Handler — shift viewport right, update columns ($8DF5)
; =============================================================================
; Incremental scroll: called each frame while player moves right.
; Triggers when player X - scroll_x >= $80 (past screen midpoint).
; temp_00 = pixel delta to scroll this frame.
; Pixel→column conversion: (old_scroll_x_low_2bits + delta) >> 2 = tile columns
; crossed, since each metatile column is 4 pixels wide in scroll units.
; For each column crossed, copies tile data and advances column_index mod 64.
; =============================================================================
scroll_right_handler:  sec
        lda     ent_x_px
        sbc     scroll_x
        cmp     #$80                    ; player past center of 256px viewport?
        bcs     scroll_right_exec
        rts

scroll_right_exec:  clc
        lda     scroll_x
        pha                             ; save old scroll_x for column math
        adc     temp_00                 ; scroll_x += pixel delta
        sta     scroll_x
        lda     nametable_select
        adc     #$00                    ; carry into nametable index
        sta     nametable_select
        cmp     scroll_screen_hi                     ; hit right boundary (scroll_screen_hi)?
        bne     scroll_right_clamp
        sec                             ; clamp: reduce delta by overshoot
        lda     temp_00
        sbc     scroll_x
        sta     temp_00
        lda     #$00
        sta     scroll_x               ; pin scroll_x to 0 at boundary
        sta     scroll_subpixel                     ; clear sub-pixel accumulator
scroll_right_clamp:  pla                ; A = old scroll_x
        and     #$03                    ; low 2 bits = pixel offset within tile column
        adc     temp_00                 ; add delta to get total pixel movement
        lsr     a                       ; divide by 4 = number of tile columns crossed
        lsr     a
        sta     temp_01                 ; temp_01 = columns to render
        beq     scroll_right_rts        ; 0 columns: nothing to update
        clc
        lda     column_ptr_lo                     ; advance column_ptr by columns crossed
        sta     jump_ptr                ; jump_ptr = working copy for column_data_copy
        adc     temp_01
        sta     column_ptr_lo
        lda     column_ptr_hi
        sta     jump_ptr_hi
        adc     #$00
        sta     column_ptr_hi
        clc
        lda     metatile_ptr_lo                     ; advance metatile_ptr by columns crossed
        adc     temp_01
        sta     metatile_ptr_lo
        lda     metatile_ptr_hi
        adc     #$00
        sta     metatile_ptr_hi
scroll_right_column_loop:  jsr     column_data_copy ; decode metatile column → PPU buffer
        inc     column_index                     ; advance column_index
        lda     column_index
        and     #$3F                    ; wrap mod 64 (2 nametables × 32 columns)
        sta     column_index
        clc
        lda     jump_ptr                ; advance working pointer to next column
        adc     #$01
        sta     jump_ptr
        lda     jump_ptr_hi
        adc     #$00
        sta     jump_ptr_hi
        dec     temp_01                 ; one fewer column to render
        bne     scroll_right_column_loop
scroll_right_rts:  rts

; =============================================================================
; scroll_left_handler -- Scroll Left Handler — shift viewport left, update columns ($8E65)
; =============================================================================
; Mirror of scroll_right_handler for leftward movement.
; Triggers when player X - scroll_x < $80 (player behind midpoint).
; EOR #$FF inverts the low bits for leftward pixel→column conversion.
; Pointers and column_index are decremented instead of incremented.
; =============================================================================
scroll_left_handler:  sec
        lda     ent_x_px
        sbc     scroll_x
        cmp     #$80                    ; player behind center of viewport?
        bcc     scroll_left_exec
        rts

scroll_left_exec:  sec
        lda     scroll_x
        pha                             ; save old scroll_x for column math
        sbc     temp_00                 ; scroll_x -= pixel delta
        sta     scroll_x
        lda     nametable_select
        sbc     #$00                    ; borrow into nametable index
        sta     nametable_select
        ldx     scroll_screen_lo                     ; left boundary (scroll_screen_lo)
        dex                             ; one below = forbidden nametable
        cpx     nametable_select
        bne     scroll_left_calc_columns ; not at boundary, continue
        inc     nametable_select        ; undo: pin to boundary
        clc
        lda     temp_00                 ; reduce delta by overshoot
        adc     scroll_x
        sta     temp_00
        lda     #$00
        sta     scroll_x               ; pin scroll_x to 0
        sta     scroll_subpixel                     ; clear sub-pixel accumulator
scroll_left_calc_columns:  clc
        pla                             ; A = old scroll_x
        eor     #$FF                    ; invert low bits for leftward math
        and     #$03                    ; pixels remaining in current tile column
        adc     temp_00                 ; add delta
        lsr     a                       ; divide by 4 = columns crossed
        lsr     a
        sta     temp_01                 ; temp_01 = columns to render
        beq     scroll_left_rts         ; 0 columns: nothing to update
        sec
        lda     metatile_ptr_lo                     ; retract metatile_ptr by columns crossed
        sta     jump_ptr
        sbc     temp_01
        sta     metatile_ptr_lo
        lda     metatile_ptr_hi
        sta     jump_ptr_hi
        sbc     #$00
        sta     metatile_ptr_hi
        sec
        lda     column_ptr_lo                     ; retract column_ptr by columns crossed
        sbc     temp_01
        sta     column_ptr_lo
        lda     column_ptr_hi
        sbc     #$00
        sta     column_ptr_hi
scroll_left_column_loop:  jsr     column_data_copy ; decode metatile column → PPU buffer
        dec     column_index                     ; retract column_index
        lda     column_index
        and     #$3F                    ; wrap mod 64
        sta     column_index
        sec
        lda     jump_ptr                ; retract working pointer
        sbc     #$01
        sta     jump_ptr
        lda     jump_ptr_hi
        sbc     #$00
        sta     jump_ptr_hi
        dec     temp_01                 ; one fewer column to render
        bne     scroll_left_column_loop
scroll_left_rts:  rts

; =============================================================================
; transition_screen_left -- Screen Transition Left — full room scroll to previous screen ($8EDD)
; =============================================================================
; Full room transition (not incremental): clears entities, renders the
; destination nametable off-screen, runs smooth scroll animation, then
; adjusts metatile/column pointers by -$40 (64 bytes = one full screen
; of column data) and repopulates entities for the new room.
; =============================================================================
transition_screen_left:  jsr     reset_entity_slots ; clear all entities for new room
        ldx     scroll_screen_lo                     ; old left boundary → new right boundary
        dex
        stx     scroll_screen_hi
        dec     current_screen                     ; move to previous screen
        ldy     current_screen
        jsr     get_screen_boundary     ; get connectivity for new screen
        tya
        and     #$1F                    ; low 5 bits = room width
        sta     scroll_screen_lo
        txa                             ; X = boundary base from get_screen_boundary
        sec
        sbc     scroll_screen_lo                     ; compute new left boundary
        sta     scroll_screen_lo
        lda     scroll_screen_hi
        jsr     render_full_nametable   ; render destination nametable (off-screen)
        dec     ent_x_screen            ; player shifts one screen left
        lda     current_screen
        sta     $FE
        jsr     transition_scroll_setup ; execute smooth scroll animation
        dec     nametable_select
        sec
        lda     metatile_ptr_lo                     ; retract metatile_ptr by $40 (one screen)
        sbc     #$40
        sta     metatile_ptr_lo
        lda     metatile_ptr_hi
        sbc     #$00
        sta     metatile_ptr_hi
        sec
        lda     column_ptr_lo                     ; retract column_ptr by $40 (one screen)
        sbc     #$40
        sta     column_ptr_lo
        lda     column_ptr_hi
        sbc     #$00
        sta     column_ptr_hi
        jsr     wait_for_vblank
        sec
        lda     scroll_screen_hi
        sbc     #$01
        jsr     render_full_nametable   ; render adjacent nametable
        lda     #$00
        sta     $F9
        lda     #$00
        sta     $42
        jsr     entity_spawn_scan       ; repopulate enemies for new room
        rts

; =============================================================================
; transition_screen_right -- Screen Transition Right — full room scroll to next screen ($8F39)
; =============================================================================
; Full rightward room transition. Renders the off-screen nametable ahead,
; optionally fills attribute tables for stages that require pre-rendering
; (every 8th column triggers a metatile_render + metatile_attr_update batch),
; runs the smooth scroll animation, then advances pointers by +$40 (64 bytes)
; and repopulates entities. The attribute pre-fill uses $54/$51 to queue
; PPU attribute writes that the NMI handler processes during VBLANK.
; =============================================================================
transition_screen_right:  jsr     reset_entity_slots ; clear all entities for new room
        ldx     scroll_screen_hi                     ; current right boundary
        inx                             ; next nametable = destination
        txa
        pha                             ; save for later boundary calc
        jsr     render_full_nametable   ; render destination nametable (off-screen)
        inc     ent_x_screen            ; player shifts one screen right
        lda     transition_type
        and     #$01                    ; bit 0 set = vertical transition (skip attr fill)
        bne     transition_right_scroll
        lda     #$18                    ; 25 columns to pre-render attributes ($00-$18)
        sta     $FD
        lda     #$00
        sta     $FE
transition_right_attr_loop:  ldx     current_stage
        lda     nametable_select
        cmp     stage_min_screen_table,x ; skip attr fill if before stage start
        bcc     transition_right_scroll
        lda     $FD
        and     #$07                    ; every 8th column: render metatile attributes
        bne     transition_right_attr_step
        lda     #$34
        jsr     bank_switch_enqueue     ; switch to metatile data bank
        lda     nametable_select
        sta     jump_ptr_hi
        lda     #$F0
        sta     jump_ptr
        lda     $FD
        asl     a
        adc     stage_attr_base_table,x ; compute attribute table offset
        sta     $0A
        jsr     metatile_render
        jsr     metatile_attr_update
        lda     #$80
        sta     attr_update_mode                     ; attr_update_mode = read-modify-write
        inc     attr_update_count                     ; queue attribute PPU write
transition_right_attr_step:  jsr     wait_for_vblank ; let NMI process queued PPU writes
        dec     $FD
        bpl     transition_right_attr_loop
        lda     #$FE
        jsr     bank_switch_enqueue     ; restore bank
transition_right_scroll:  lda     current_screen
        sta     $FE
        inc     $FE                     ; $FE = destination screen index
        jsr     transition_scroll_setup ; execute smooth scroll animation
        inc     nametable_select
        jsr     wait_for_vblank
        clc
        lda     scroll_screen_hi
        adc     #$02                    ; render nametable 2 ahead (for next scroll)
        jsr     render_full_nametable
        inc     current_screen                     ; advance to new screen
        ldy     current_screen
        jsr     get_screen_boundary     ; get new room's connectivity
        tya
        and     #$1F                    ; low 5 bits = room width
        sta     scroll_screen_lo
        pla                             ; recover old scroll_screen_hi + 1
        tax
        clc
        adc     scroll_screen_lo                     ; new right boundary = base + width
        sta     scroll_screen_hi
        stx     scroll_screen_lo                     ; new left boundary = old right + 1
        clc
        lda     column_ptr_lo                     ; advance column_ptr by $40 (one screen)
        adc     #$40
        sta     column_ptr_lo
        lda     column_ptr_hi
        adc     #$00
        sta     column_ptr_hi
        clc
        lda     metatile_ptr_lo                     ; advance metatile_ptr by $40 (one screen)
        adc     #$40
        sta     metatile_ptr_lo
        lda     metatile_ptr_hi
        adc     #$00
        sta     metatile_ptr_hi
        lda     #$00
        sta     $F9
        lda     transition_type
        and     #$01                    ; vertical transition? skip post-fill
        bne     transition_right_done
        lda     #$00                    ; post-scroll attribute fill for destination
        sta     $FD
        sta     $FE
transition_right_col_loop:  ldx     current_stage
        lda     nametable_select
        cmp     stage_min_screen_table,x
        bcc     transition_right_done
        cmp     stage_max_screen_table,x
        bne     transition_right_col_step
        lda     #$0B
        jsr     bank_switch_enqueue
        lda     current_stage
        cmp     #$0B
        beq     transition_right_col_step
        cmp     #WILY_STAGE_START
        bcs     transition_right_done
transition_right_col_step:  lda     $FD
        and     #$07                    ; every 8th column: render metatile attributes
        bne     transition_right_wait_frame
        lda     #$34
        jsr     bank_switch_enqueue
        lda     nametable_select
        sta     jump_ptr_hi
        lda     #$00
        sta     jump_ptr
        lda     $FD
        asl     a
        adc     stage_attr_base_table,x
        sta     $0A
        jsr     metatile_render
        ldx     current_stage
        lda     stage_attr_mode_table,x
        jsr     metatile_attr_update
        inc     attr_update_mode                     ; queue attribute update
        inc     attr_update_count
transition_right_wait_frame:  jsr     wait_for_vblank
        inc     $FD
        lda     $FD
        cmp     #$19                    ; 25 columns rendered?
        bne     transition_right_col_loop
        lda     #$FE
        jsr     bank_switch_enqueue     ; restore bank
transition_right_done:  lda     #$40
        sta     $42
        jsr     entity_spawn_scan       ; repopulate enemies for new room
        rts

; Per-stage scroll configuration tables. Indexed by current_stage (0-13).
; Stages 0-7 = Robot Masters, 8-13 = Wily fortress.
stage_attr_base_table:  .byte   $60,$40,$40,$40,$40,$40,$40,$40 ; attribute data base offset per stage
        .byte   $00,$00,$80,$80,$00,$80
stage_attr_mode_table:  .byte   $00,$55,$AA,$00,$00,$55,$00,$AA ; attribute merge mode per stage (→ $54)
        .byte   $00,$00,$00,$00,$00,$00
stage_min_screen_table:  .byte   $15,$13,$15,$13,$15,$11,$13,$11 ; first nametable index per stage
        .byte   $00,$00,$26,$25,$00,$1E
stage_max_screen_table:  .byte   $17,$15,$17,$15,$17,$13,$15,$13 ; last nametable index (boss trigger)
        .byte   $00,$27,$27,$26,$00,$1F

; =============================================================================
; render_full_nametable -- Full-Screen Nametable Render — upload all 32 columns to PPU ($907D)
; =============================================================================
; Renders an entire nametable (32 tile columns) from metatile data.
; A = nametable index to render. Converts to a metatile data pointer:
;   ptr = (A >> 2) | (A << 6) + $8500   (256-byte aligned pages in ROM)
; Processes columns in pairs (2 per loop), with a VBLANK wait between
; pairs when rendering is enabled ($80 bit of ppuctrl_shadow).
; Saves/restores column_index ($1A) since this is a bulk operation.
; =============================================================================
render_full_nametable:  ldx     #$00
        stx     jump_ptr                ; build pointer: low byte = nametable << 6
        lsr     a
        ror     jump_ptr
        lsr     a
        ror     jump_ptr
        clc
        adc     #$85                    ; high byte = nametable >> 2 + $85
        sta     jump_ptr_hi
        lda     column_index
        pha                             ; save column_index
        lda     #$00
        sta     column_index                     ; start from column 0
nametable_column_loop:  jsr     column_data_copy ; render column pair (even)
        inc     jump_ptr
        inc     column_index
        jsr     column_data_copy        ; render column pair (odd)
        lda     jump_ptr
        pha
        lda     jump_ptr_hi
        pha
        lda     ppuctrl_shadow
        and     #$80                    ; NMI enabled = rendering active?
        beq     nametable_direct_upload
        jsr     wait_for_vblank         ; wait for VBLANK to transfer tiles
        jmp     nametable_advance_column

nametable_direct_upload:  lda     ppu_buffer_count ; rendering off: direct PPU write
        jsr     ppu_buffer_transfer
nametable_advance_column:  clc
        pla
        sta     jump_ptr_hi
        pla
        sta     jump_ptr
        inc     jump_ptr
        inc     column_index
        lda     jump_ptr
        and     #$3F                    ; 64 columns per nametable pair: done?
        bne     nametable_column_loop
        pla
        sta     column_index                     ; restore column_index
        rts

; =============================================================================
; transition_scroll_setup -- Transition Scroll Setup — configure and execute scroll animation ($90C9)
; =============================================================================
; Dispatches to horizontal or vertical scroll animation based on
; transition_type bit 0: 0 = horizontal, 1 = vertical.
; =============================================================================
transition_scroll_setup:  lda     transition_type
        and     #$01
        beq     transition_scroll_horizontal
        jmp     transition_scroll_vertical

; -----------------------------------------------------------------------------
; Horizontal scroll animation: 63 frames, scroll_x += 4/frame.
; 63 × 4 = 252 pixels ≈ one nametable width (256 - 4 to finish at 0).
; Player X nudged $C0 sub-pixels/frame (~3 px/frame) to track camera.
; scroll_column_render queues PPU column writes each frame.
; -----------------------------------------------------------------------------
transition_scroll_horizontal:  jsr     transition_load_palette
        lda     #$00
        sta     $3E
        sta     $3F
        sta     $FD
        ldy     #$3F                    ; 63 frames ($3F)
transition_scroll_frame_loop:  tya
        pha
        lda     #$01
        clc
        lda     scroll_x
        adc     #$04                    ; scroll 4 pixels/frame rightward
        sta     scroll_x
        clc
        lda     ent_x_sub
        adc     #$C0                    ; nudge player X by $C0 sub-pixels/frame
        sta     ent_x_sub
        lda     ent_x_px
        adc     #$00                    ; carry into pixel position
        sta     ent_x_px
        lda     current_weapon
        cmp     #$01
        bne     transition_scroll_render
        jsr     vert_scroll_update_entity ; sync companion entity (Item-1 riding)
transition_scroll_render:  jsr     render_all_sprites
        jsr     scroll_column_render    ; queue tile column updates for NMI
        jsr     wait_for_vblank         ; let NMI apply PPU writes + scroll
        pla
        tay
        dey
        bne     transition_scroll_frame_loop
        sty     scroll_x                ; Y=0: pin scroll_x to 0 at destination
        rts

transition_load_palette:  ldx     current_stage
        cpx     #$03
        bne     transition_palette_check
        ldy     current_screen
        cpy     #$04
        beq     transition_palette_rts
transition_palette_check:  ldy     stage_palette_offset_table,x
        beq     transition_palette_rts
        lda     stage_palette_count,x
        sta     $FD
        lda     stage_palette_src_index,x
        tax
transition_palette_copy:  lda     stage_palette_data,x
        sta     palette_ram,y
        sta     $0376,y
        sta     $0386,y
        sta     $0396,y
        sta     $03A6,y
        dex
        dey
        dec     $FD
        bne     transition_palette_copy
transition_palette_rts:  rts

stage_palette_offset_table:  .byte   $00,$0B,$00,$0B,$00,$00,$00,$0F ; palette offset per stage
        .byte   $00,$00,$03,$00,$00,$0B
stage_palette_src_index:  .byte   $00,$02,$00,$05,$00,$00,$00,$0C
        .byte   $00,$00,$0F,$00,$00,$12
stage_palette_count:  .byte   $00,$03,$00,$03,$00,$00,$00,$07
        .byte   $00,$00,$03,$00,$00,$03
stage_palette_data:  .byte   $2B,$1B,$0B,$21,$01,$0F,$39,$18 ; palette color entries for transitions
        .byte   $01,$0F,$39,$18,$0F,$27,$37,$30
        .byte   $0F,$0F,$0F

; =============================================================================
; transition_scroll_vertical -- Vertical Scroll Transition — smooth scroll up/down between rooms ($9185)
; =============================================================================
; Vertical scroll animation for ladder/pit transitions.
; Direction from transition_type >> 1: index 0 = scroll up, index 1 = scroll down.
; Frame counter $39 runs $3B→$FF (up, ~60 frames) or $00→$3C (down, 60 frames).
; Each frame: update scroll_y, player Y position, and render sprites/columns.
; Data tables provide per-direction initial values, step sizes, and deltas.
; =============================================================================
transition_scroll_vertical:  lda     transition_type
        lsr     a                       ; bit 1 → carry, result = direction index
        bne     vert_scroll_setup       ; nonzero = up/down (skip boss setup)
        ldx     #$09                    ; transition_type 0 with vertical = boss warp
        stx     game_substate
        pha
        jsr     weapon_set_base_type
        pla
vert_scroll_setup:  tax                     ; X = direction index (0=up, 1=down)
        lda     vert_scroll_y_start,x  ; initial frame counter value
        sta     $39
        lda     vert_scroll_y_init,x   ; initial scroll_y position
        sta     scroll_y
        lda     #$00
        sta     $FD
vert_scroll_frame_loop:  txa
        pha
        jsr     render_all_sprites
        jsr     scroll_y_update         ; update Y scroll PPU registers
        jsr     scroll_column_render    ; queue column writes if needed
        jsr     wait_for_vblank
        pla
        tax
        lda     current_weapon
        cmp     #$01
        bne     vert_scroll_update_pos
        jsr     vert_scroll_update_entity ; sync companion entity
vert_scroll_update_pos:  clc
        lda     ent_y_sub               ; update player Y sub-pixel
        adc     vert_scroll_sub_step,x  ; up: +$BF (~+3.75px), down: +$41 (~-3.75px)
        sta     ent_y_sub
        lda     ent_y_px                ; update player Y pixel
        adc     vert_scroll_pixel_step,x ; up: +$03 (up=+3), down: +$FC (down=-4)
        sta     ent_y_px
        lda     $F9
        adc     vert_scroll_page_step,x ; up: +$00, down: +$FF (page decrement)
        sta     $F9
        clc
        lda     scroll_y                ; update scroll Y position
        adc     vert_scroll_y_delta,x   ; up: -4, down: +4
        sta     scroll_y
        clc
        lda     $39                     ; update frame counter
        adc     vert_scroll_y_step,x    ; up: -1 ($FF), down: +1
        sta     $39
        bmi     vert_scroll_finish      ; up: counter went negative → done
        cmp     #$3C
        beq     vert_scroll_finish      ; down: counter reached $3C → done
        bne     vert_scroll_frame_loop
vert_scroll_finish:  lda     #$00
        sta     scroll_y_page                     ; clear scroll_y_page
        sta     scroll_y                ; reset scroll_y to 0
        sta     ent_y_sub               ; clear player sub-pixel
        jsr     render_all_sprites
        rts

vert_scroll_update_entity:  lda     ent_x_px ; sync Item-1 entity position with player
        sta     $0462
        lda     ent_x_screen
        sta     $0442
        lda     ent_y_px
        sta     $04A2
        lda     #$00
        sta     $0682
        rts

; Vertical scroll data tables: index 0 = up, index 1 = down.
vert_scroll_y_start:  .byte   $3B,$00   ; frame counter initial: up=$3B (counts down), down=$00 (counts up)
vert_scroll_y_step:  .byte   $FF,$01   ; frame counter step: up=-1, down=+1
vert_scroll_sub_step:  .byte   $BF,$41  ; player Y sub-pixel step per frame
vert_scroll_pixel_step:  .byte   $03,$FC ; player Y pixel step: up=+3, down=-4
vert_scroll_y_delta:  .byte   $FC,$04   ; scroll_y delta per frame: up=-4, down=+4
vert_scroll_y_init:  .byte   $EF,$00   ; initial scroll_y: up=$EF (near bottom), down=$00 (top)
vert_scroll_page_step:  .byte   $00,$FF ; Y page step: up=0, down=-1 (page decrement)

; =============================================================================
; reset_entity_slots -- Reset Entity Slots — clear all entity data, preserve boss if active ($9220)
; =============================================================================
reset_entity_slots:  ldx     #$00
        lda     current_weapon
        cmp     #$06                    ; state 6 = boss fight active
        beq     reset_entity_save_boss
        cmp     #$01
        bne     reset_entity_clear
reset_entity_save_boss:  ldx     $0422
reset_entity_clear:  txa
        pha
        lda     #$00
        ldx     #$1F
reset_entity_clear_loop:  sta     ent_flags,x ; clear entity flags (deactivate)
        dex
        bne     reset_entity_clear_loop
        sta     $05A0
        sta     $05A1
        sta     $05A2
        pla
        sta     $0422
        ldx     #$0F
reset_entity_clear_spawn:  lda     #$FF
        sta     $0100,x
        sta     $0130,x
        lda     #$00
        sta     $0160,x
        dex
        bpl     reset_entity_clear_spawn
        rts

; =============================================================================
; entity_ai_dispatch -- Entity AI Dispatch — iterate entities, call AI via pointer table ($925B)
; =============================================================================
entity_ai_dispatch:  sec
        lda     ent_x_px
        sbc     scroll_x
        sta     $2D
        lda     $AA
        beq     entity_ai_normal_loop
        cmp     #$04
        bne     entity_ai_special_loop
entity_ai_normal_loop:  ldx     #$10    ; entity slot 16 = first enemy slot
        stx     current_entity_slot
entity_ai_normal_step:  lda     ent_flags,x ; check entity active flag (bit 7)
        bpl     entity_ai_next_normal
        sec
        lda     ent_x_px,x
        sbc     scroll_x
        sta     $2E
        lda     ent_x_screen,x
        sbc     nametable_select
        sta     $2F
        ldy     ent_type,x
        lda     entity_ai_ptr_lo,y
        sta     jump_ptr
        lda     entity_ai_ptr_hi,y
        sta     jump_ptr_hi
        lda     #$92
        pha
        lda     #$98
        pha
        jmp     (jump_ptr)

entity_ai_next_normal:  inc     current_entity_slot
        ldx     current_entity_slot
        cpx     #$20
        bne     entity_ai_normal_step
        rts

entity_ai_special_loop:  ldx     #$10
        stx     current_entity_slot
entity_ai_special_step:  lda     ent_flags,x ; check entity active flag
        bpl     entity_ai_next_special
        sec
        lda     ent_x_px,x
        sbc     scroll_x
        sta     $2E
        lda     ent_x_screen,x
        sbc     nametable_select
        sta     $2F
        lda     #$92
        pha
        lda     #$E6
        pha
        ldy     ent_type,x
        lda     entity_ai_bank_table,y
        bne     entity_ai_special_indirect
        ldy     ent_type,x
        lda     entity_ai_ptr_lo,y
        sta     jump_ptr
        lda     entity_ai_ptr_hi,y
        sta     jump_ptr_hi
        jmp     (jump_ptr)

entity_ai_special_indirect:  tay
        dey
        lda     entity_special_ai_ptr_lo,y
        sta     jump_ptr
        lda     entity_special_ai_ptr_hi,y
        sta     jump_ptr_hi
        jmp     (jump_ptr)

entity_ai_next_special:  inc     current_entity_slot
        ldx     current_entity_slot
        cpx     #$20
        bne     entity_ai_special_step
        rts

; =============================================================================
; entity_ai_ptr_lo -- Entity AI Pointer Table — 128 entries, low/high/bank for each type ($92F0)
; =============================================================================
entity_ai_ptr_lo:  .byte   $8D,$8D,$23,$55,$D7,$4E,$71,$75 ; $00-$07: Shrink, Anko, Anko(02), AnkoSeg, M-445, Anko(05), DeathExplode, Claw
        .byte   $E5,$6F,$76,$2B,$2F,$8F,$2B,$E3 ; $08-$0F: ClawVar, StageTrans, Tanishi, TanishiBare, Kerog, PetitKerog, Bubble, BossDeath
        .byte   $43,$65,$73,$5B,$90,$CE,$81,$22 ; $10-$17: Anko(10), Anko(11), RailPlat, Crumble, LaserBeam, MetalBlade, Batton, Robbit
        .byte   $2B,$D1,$36,$54,$69,$F4,$ED,$46 ; $18-$1F: QuickBoom, AirTornado1, AirTornado2, AtomicFire, Friender, Monking, KukkuSpawn, Kukku
        .byte   $7E,$85,$A6,$C2,$2B,$5A,$AB,$B8 ; $20-$27: KukkuDesp, TellySpawn, Telly, Changkey, ChangkeyProj, Blackout, LightRestore, BlackoutEnd
        .byte   $C5,$2A,$F1,$0D,$2E,$D7,$D7,$D3 ; $28-$2F: BlackoutRe, Gear, Pierrobot, FlyBoy(2B), FlyBoy, CrashWallVar, FrienderFire, BossDoor
        .byte   $F2,$EA,$C3,$EC,$4E,$2B,$89,$A4 ; $30-$37: Press, Blocky, BlockyPh2, MechaFire, NeoMetall, GenericProj, Matasaburo, PipiSpawn
        .byte   $12,$8F,$96,$2B,$30,$4C,$A3,$2B ; $38-$3F: Pipi, PipiAlt, PipiEgg, EggHatch, Copipi, KaminariChild, KaminariGoro, KaminariBolt
        .byte   $49,$49,$81,$81,$A1,$E0,$1B,$FA ; $40-$47: Goblin, GoblinB, GoblinCleanA, GoblinCleanB, GoblinHorn, PetitGoblin, Springer, Mole
        .byte   $8A,$97,$0B,$12,$12,$2B,$F0,$21 ; $48-$4F: JoeBulletB, JoeBulletA, Mole(4A), CrazyCannon, CrazyCannon(4C), Shotman, SniperArmor, SniperJoe
        .byte   $96,$D0,$5C,$69,$6D,$71,$E5,$D7 ; $50-$57: ScwormNest, Scworm, PressRetract, AppearBlkA, AppearBlkB, AppearBlkC, NeoMetallFlip, CrashWall
        .byte   $41,$E3,$2B,$20,$2B,$4B,$67,$2B ; $58-$5F: WilyBoss, QuickBoomer, (5A), BubbleShot, MetalmanBlade, AirTornado, CrashBomb, CrashBlast
        .byte   $2B,$2B,$18,$55,$91,$7A,$B7,$CE ; $60-$67: BossDebris, WoodmanLeaf, WoodmanTornado, Wily4Shield, BoobeamCtrl, DragonBodyA, DragonBodyB, DragonPart
        .byte   $2B,$FE,$32,$EF,$2B,$25,$2B,$2B ; $68-$6F: DragonBreath, GutsdozerTurret, WilyTeleport, WilyGravity, WilyMachShot, GutsdozerCannon, WilyProj, AlienBossShot
        .byte   $98,$AD,$30,$30,$79,$A9,$A9,$B1 ; $70-$77: AlienBody, WilyFinal, FlashHaz(72), FlashHaz(73), FlashProj, (75), LargeHealth, SmallHealth
        .byte   $A9,$B1,$A9,$A9,$08,$08,$08,$24 ; $78-$7F: LargeWeapon, SmallWeapon, ETank, ExtraLife, (7C), (7D), (7E), (7F)
entity_ai_ptr_hi:  .byte   $94,$94,$95,$95,$95,$96,$96,$96 ; $00-$07
        .byte   $96,$97,$97,$98,$98,$98,$98,$98 ; $08-$0F
        .byte   $9A,$9A,$9A,$9C,$9C,$9D,$9E,$9F ; $10-$17
        .byte   $98,$9F,$A1,$A1,$A1,$A2,$A3,$A4 ; $18-$1F
        .byte   $A4,$A4,$A4,$A4,$98,$A5,$A5,$A5 ; $20-$27
        .byte   $A5,$A6,$A6,$A7,$A7,$A7,$A7,$A7 ; $28-$2F
        .byte   $A7,$A8,$A9,$A9,$AA,$98,$AB,$AB ; $30-$37
        .byte   $AC,$AC,$AC,$98,$AD,$AD,$AD,$98 ; $38-$3F
        .byte   $AE,$AE,$AF,$AF,$AF,$AF,$B0,$B0 ; $40-$47
        .byte   $B1,$B1,$B2,$B2,$B2,$98,$B2,$B4 ; $48-$4F
        .byte   $B4,$B4,$B5,$B5,$B5,$B5,$B5,$A7 ; $50-$57
        .byte   $B6,$B6,$98,$B7,$98,$B7,$B7,$98 ; $58-$5F
        .byte   $98,$98,$B8,$B8,$B8,$B9,$B9,$B9 ; $60-$67
        .byte   $98,$B9,$BA,$BA,$98,$BB,$98,$98 ; $68-$6F
        .byte   $BB,$BB,$BC,$BC,$BC,$BC,$BC,$BC ; $70-$77
        .byte   $BC,$BC,$BC,$BC,$BD,$BD,$BD,$BD ; $78-$7F
entity_ai_bank_table:  .byte   $01,$02,$01,$00,$01,$00,$01,$00 ; $00-$07
        .byte   $01,$00,$01,$01,$01,$01,$00,$02 ; $08-$0F
        .byte   $02,$02,$03,$04,$01,$01,$01,$01 ; $10-$17
        .byte   $01,$01,$01,$01,$01,$01,$00,$01 ; $18-$1F
        .byte   $00,$01,$01,$08,$01,$00,$00,$00 ; $20-$27
        .byte   $00,$01,$01,$01,$01,$00,$02,$00 ; $28-$2F
        .byte   $01,$01,$01,$01,$01,$01,$01,$00 ; $30-$37
        .byte   $01,$00,$01,$01,$01,$01,$05,$01 ; $38-$3F
        .byte   $06,$07,$00,$00,$01,$01,$01,$00 ; $40-$47
        .byte   $01,$01,$00,$01,$01,$01,$01,$01 ; $48-$4F
        .byte   $01,$01,$01,$01,$01,$01,$00,$01 ; $50-$57
        .byte   $01,$01,$01,$01,$01,$01,$01,$01 ; $58-$5F
        .byte   $01,$01,$01,$00,$01,$01,$01,$01 ; $60-$67
        .byte   $01,$01,$01,$01,$01,$00,$00,$00 ; $68-$6F
        .byte   $00,$01,$01,$01,$01,$00,$00,$00 ; $70-$77
        .byte   $00,$00,$00,$00,$00,$00,$00,$00 ; $78-$7F
entity_special_ai_ptr_lo:  .byte   $B3,$AF,$D8,$F1,$0A,$23,$23,$7C ; special AI pointer (low bytes)
        .byte   $B5,$B5,$B5,$B5,$B5,$B5,$B5
entity_special_ai_ptr_hi:  .byte   $EF,$EF,$ED,$ED,$EE,$EE,$EE,$EE ; special AI pointer (high bytes)
        .byte   $EE,$EE,$E6,$EE,$EE,$EE,$BD
met_ai_preamble:
        cpx     #$04
        bne     met_update_timer
        sta     ent_anim_frame,x
        lda     $0110,x
        bne     met_reset_state

; =============================================================================
; met_init_shoot -- Enemy AI: Met (Hard Hat) — hide/shoot pattern ($949A)
; =============================================================================
met_init_shoot:
        lda     #$01
        sta     $0110,x
        lda     #$14
        sta     ent_state,x
        lda     #$05
        sta     ent_anim_id,x
        lda     rng_seed
        and     #$03
        beq     met_calc_aim
        lda     #$02
        sta     jump_ptr_hi
        lda     #$0C
        sta     jump_ptr
        jsr     calc_entity_velocity
        ldx     current_entity_slot
        jmp     met_update_timer

met_calc_aim:  jsr     entity_face_player
        lda     $DA01
        sta     ent_x_vel,x
        lda     $DA02
        sta     ent_x_vel_sub,x
        lda     $DA21
        sta     ent_y_vel,x
        lda     $DA22
        sta     ent_y_vel_sub,x
        bne     met_update_timer
met_reset_state:
        lda     #$00
        sta     ent_anim_id,x
        sta     $0110,x
        lda     rng_seed
        and     #$01
        tay
        lda     met_delay_table,y
        sta     ent_state,x
        lda     #$00
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
        lda     #$3C
        sta     ent_y_vel_sub,x
        lda     #$FF
        sta     ent_y_vel,x
met_update_timer:  dec     ent_state,x
        lda     ent_anim_id,x
        cmp     #$04
        bcc     met_apply_physics
        bne     met_check_state_4
        lda     #$00
        sta     ent_anim_id,x
        beq     met_apply_physics
met_check_state_4:  cmp     #$07
        bne     met_apply_physics
        lda     #$00
        sta     ent_anim_frame,x
met_apply_physics:  jsr     apply_entity_physics
        rts

met_delay_table:  .byte   $19,$4A                         ; Met hide/shoot delay timings
; --- anko_spawner_ai_entry -- Anko spawner (type $02) — state check, spawns shrimp children ---
anko_spawner_ai_entry:
        lda     ent_state,x
        bne     anko_spawner_dec_timer
        ldy     #$0F
        lda     #$02
        sta     temp_01
        lda     #$01
        sta     temp_00

; =============================================================================
; anko_spawner_scan -- Enemy AI: Anko spawner (type $02) — creates Shrink-AI entities ($9532)
; Mislabeled by annotation scripts as "Telly". Actually type $02 (Anko sub-part).
; =============================================================================
anko_spawner_scan:  jsr     find_entity_scan
        bcs     anko_spawner_create
        dec     temp_01
        beq     anko_spawner_set_timer
        dey
        bne     anko_spawner_scan
        bne     anko_spawner_set_timer
anko_spawner_create:  lda     #ENTITY_ANKO_BODY
        jsr     spawn_entity_from_parent
        lda     #$31
        bne     anko_spawner_store_timer
anko_spawner_set_timer:  lda     #$62
anko_spawner_store_timer:  sta     ent_state,x
anko_spawner_dec_timer:
        dec     ent_state,x
        jsr     apply_simple_physics
        rts

; =============================================================================
; anko_seg_ai -- Enemy AI: Anko segment (type $03) — spawns M-445 jellyfish ($9555)
; Mislabeled by annotation scripts as "Pipi". Actually type $03 (Anko sub-part).
; =============================================================================
anko_seg_entry:
        lda     ent_x_vel_sub,x           ; check X velocity (sub)
        bne     anko_seg_track_parent
        lda     #ENTITY_ANKO_SEG
        jsr     check_entity_collision_scan
        bcc     anko_seg_track_parent
        rts
anko_seg_track_parent:
        lda     ent_x_px
        sta     ent_x_px,x
        lda     ent_x_screen
        sta     ent_x_screen,x
        lda     ent_state,x
        bne     anko_seg_dec_timer
        lda     #$03
        sta     temp_01
        lda     #ENTITY_M445
        jsr     find_entity_count_check
        bcs     anko_seg_set_timer
        lda     #ENTITY_M445
        jsr     spawn_entity_from_parent
        bcs     anko_seg_set_timer
        lda     $0110,x
        and     #$01
        tax
        clc
        lda     ent_x_spawn_px,y
        adc     anko_seg_x_offset_table,x
        sta     ent_x_spawn_px,y
        lda     ent_x_spawn_scr,y
        adc     anko_seg_x_page_table,x
        sta     ent_x_spawn_scr,y
        ldx     current_entity_slot
        inc     $0110,x
anko_seg_set_timer:  lda     #$4B
        sta     ent_state,x
anko_seg_dec_timer:  dec     ent_state,x
        ldy     #$17
        jsr     boss_set_palette
        rts

anko_seg_x_offset_table:  .byte   $50,$C8
anko_seg_x_page_table:  .byte   $00,$FF

; =============================================================================
; check_entity_collision_scan -- Entity Collision Scan — check overlap between entity pairs ($95B5)
; =============================================================================
check_entity_collision_scan:  sta     temp_00
        ldy     #$0F
collision_scan_loop:  jsr     find_entity_scan
        bcs     collision_scan_set_active
        lda     $0630,y
        beq     collision_scan_next
        lsr     ent_flags,x
        lda     #$00
        sta     a:$F0,x
        sec
        rts

collision_scan_next:  dey
        bne     collision_scan_loop
collision_scan_set_active:  lda     #$01
        sta     ent_x_vel_sub,x
        clc
        rts

; --- m445_ai_entry -- proximity check, face player, timer (ptr table: type $04) ---
m445_ai_entry:
        lda     ent_x_vel_sub,x
        bne     m445_check_timer
        sec
        lda     ent_y_px
        sbc     ent_y_px,x
        cmp     #$03
        bcc     m445_face_player
        cmp     #$FE
        bcc     m445_apply_physics
m445_face_player:
        jsr     entity_face_player
m445_check_timer:
        lda     ent_state,x
        bne     m445_dec_timer
        lda     #$0B
        sta     ent_state,x
        lda     $0110,x
        pha
        and     #$07
        tay
        lda     #$00
        sta     ent_x_vel,x
        sta     ent_y_vel,x
        lda     m445_x_speed_table,y
        sta     ent_x_vel_sub,x
        lda     m445_y_speed_table,y
        sta     ent_y_vel_sub,x
        pla
        pha
        cmp     #$04
        bcc     m445_update_direction
        cmp     #$0C
        bcs     m445_update_direction
        lda     ent_y_vel_sub,x
        eor     #$FF
        adc     #$01
        sta     ent_y_vel_sub,x
        lda     #$FF
        adc     #$00
        sta     ent_y_vel,x
m445_update_direction:  pla
        clc
        adc     #$01
        and     #$0F
        sta     $0110,x
m445_dec_timer:  dec     ent_state,x    ; decrement movement timer
m445_apply_physics:
        jsr     apply_entity_physics
        rts

m445_x_speed_table:  .byte   $17,$5E,$AD,$E3,$E3,$AD,$5E,$17 ; M-445 X speed per animation frame
m445_y_speed_table:  .byte   $F5,$E3,$AD,$5E,$5E,$AD,$E3,$F5 ; M-445 Y speed per animation frame
enemy_destroy_setup:
        lda     #$03
        sta     temp_00
enemy_destroy_scan:
        ldy     #$0F

; =============================================================================
; enemy_destroy_all -- Enemy Destroy — deactivate all child entities and self ($9654)
; =============================================================================
enemy_destroy_all:  jsr     find_entity_scan
        bcs     enemy_deactivate_self
        lda     #$00
        sta     ent_spawn_flags,y
        lda     #$FF
        sta     $0100,y
        dey
        bpl     enemy_destroy_all
enemy_deactivate_self:  lda     #$00
        sta     ent_flags,x
        lda     #$FF
        sta     a:$F0,x
        rts

; =============================================================================
; death_explode_ai / claw_ai_entry — Death explosion (type $06) + Claw (type $07) ($9671)
; =============================================================================
death_explode_ai:
        jsr     apply_entity_physics_alt
        rts
claw_ai_entry:
        lda     ent_x_vel_sub,x
        bne     claw_spawner_copy_pos
        lda     #ENTITY_CLAW
        jsr     check_entity_collision_scan
        bcc     claw_spawner_copy_pos
        rts
claw_spawner_copy_pos:
        lda     ent_x_px
        sta     ent_x_px,x
        lda     ent_x_screen
        sta     ent_x_screen,x
        lda     ent_state,x
        bne     claw_spawner_dec_timer
        lda     #$02
        sta     temp_01
        lda     #ENTITY_CLAW_VAR
        jsr     find_entity_count_check
        bcs     claw_spawner_set_timer
        lda     #ENTITY_CLAW_VAR
        jsr     spawn_entity_from_parent
        bcs     claw_spawner_set_timer
        lda     $0110,x
        and     #$01
        tax
        lda     ent_x_spawn_px,y
        adc     claw_spawner_x_offset_tbl,x
        sta     ent_x_spawn_px,y
        lda     ent_x_spawn_scr,y
        adc     claw_spawner_x_page_tbl,x
        sta     ent_x_spawn_scr,y
        ldx     current_entity_slot
        inc     $0110,x
claw_spawner_set_timer:  lda     #$5D
        sta     ent_state,x
claw_spawner_dec_timer:  dec     ent_state,x
        rts

claw_spawner_x_offset_tbl:  .byte   $30,$E0 ; Claw spawn X offset per direction
claw_spawner_x_page_tbl:  .byte   $00,$FF   ; Claw spawn X page per direction

; =============================================================================
; find_entity_count_check -- Find Entity Count — scan for entity type, check population limit ($96CF)
; =============================================================================
find_entity_count_check:  sta     temp_00
        ldy     #$0F
find_entity_count_loop:  jsr     find_entity_scan
        bcs     find_entity_count_ok
        dec     temp_01
        beq     find_entity_count_fail
        dey
        bne     find_entity_count_loop
        beq     find_entity_count_fail
find_entity_count_ok:  clc
        rts

find_entity_count_fail:  sec
        rts

; --- claw_var_ai_entry -- tile collision, fall trigger, face player (ptr table: type $08) ---
claw_var_ai_entry:
        lda     #$0B
        sta     temp_01
        lda     #$08
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     ent_state,x
        bne     claw_var_check_state
        lda     temp_00
        beq     claw_var_apply_physics
        inc     ent_state,x
        lda     #$76
        sta     ent_y_vel_sub,x           ; set fall velocity sub
        lda     #$03
        sta     ent_y_vel,x           ; set fall velocity high
        lda     ent_flags,x
        ora     #$04
        sta     ent_flags,x
        jsr     entity_face_player
        bne     claw_var_apply_physics
claw_var_check_state:
        cmp     #$03
        beq     claw_var_check_land
        lda     temp_00
        beq     claw_var_apply_physics
        lda     ent_state,x
        cmp     #$02
        beq     claw_var_set_fall_vel
        lda     #$00
        sta     ent_y_vel_sub,x
        lda     #$02
        sta     ent_y_vel,x
        inc     ent_state,x
        bne     claw_var_apply_physics
claw_var_set_fall_vel:  lda     #$C0
        sta     ent_y_vel_sub,x
        lda     #$FF
        sta     ent_y_vel,x
        lda     #$00
        sta     ent_x_vel,x
        lda     #$A3
        sta     ent_x_vel_sub,x
        inc     ent_state,x
        lda     ent_flags,x
        and     #$FB
        sta     ent_flags,x
        bne     claw_var_apply_physics
claw_var_check_land:  lda     #$0C
        lda     temp_00
        bne     claw_var_apply_physics
        lda     #$00
        sta     ent_state,x
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
        lda     ent_flags,x
        ora     #$04
        sta     ent_flags,x
claw_var_apply_physics:  jsr     apply_entity_physics
        rts

; =============================================================================
; tanishi_ai -- Enemy AI: Tanishi (type $0A) — snail, spawns bare form on hit ($9776)
; Mislabeled by annotation scripts as "Shotman". Actually type $0A (Tanishi).
; =============================================================================
stage_trans_ai:
        lda     #$07
        sta     temp_00
        jmp     enemy_destroy_scan
tanishi_ai_main:
        lda     ent_state,x
        bne     tanishi_state_check
        lda     #$0C
        sta     temp_02
        lda     ent_anim_id,x
        cmp     #$02
        bcc     tanishi_hp_check
        lda     #$00
        sta     ent_anim_id,x
tanishi_hp_check:
        lda     ent_hp,x
        cmp     #$14
        beq     tanishi_check_facing
        lda     #ENTITY_TANISHI_BARE    ; spawn bare Tanishi on HP threshold
        jsr     spawn_entity_from_parent
        lda     ent_spawn_flags,y
        ora     #$04
        eor     #$40
        sta     ent_spawn_flags,y
        clc
        lda     ent_y_px,x
        adc     #$08
        sta     ent_y_px,x
        lda     #$01
        sta     ent_x_vel,x
        lda     #$47
        sta     ent_x_vel_sub,x
        lda     #$03
        sta     $06E0,x
        lda     #$03
        sta     ent_anim_id,x
        inc     ent_state,x
        bne     tanishi_check_facing
tanishi_state_check:
        lda     #$04
        sta     temp_02
        lda     ent_anim_id,x
        cmp     #$05
        bcc     tanishi_check_facing
        lda     #$03
        sta     ent_anim_id,x
tanishi_check_facing:  lda     ent_flags,x
        and     #$40
        beq     tanishi_facing_left
        clc
        lda     ent_x_px,x
        adc     #$0C
        sta     jump_ptr
        lda     ent_x_screen,x
        adc     #$00
        jmp     tanishi_store_position

tanishi_facing_left:  sec
        lda     ent_x_px,x
        sbc     #$0C
        sta     jump_ptr
        lda     ent_x_screen,x
        sbc     #$00
tanishi_store_position:  sta     jump_ptr_hi
        lda     ent_y_px,x
        sta     $0A
        lda     #$00
        sta     $0B
        jsr     lookup_tile_from_map
        ldx     current_entity_slot
        lda     temp_00
        and     #$01
        bne     tanishi_flip_facing
        clc
        lda     $0A
        adc     temp_02
        sta     $0A
        jsr     lookup_tile_from_map
        ldx     current_entity_slot
        lda     temp_00
        and     #$01
        bne     tanishi_apply_physics
tanishi_flip_facing:  lda     ent_flags,x
        eor     #$40
        sta     ent_flags,x
tanishi_apply_physics:  jsr     apply_entity_physics
        rts

kerog_physics_rts:
        jsr     apply_entity_physics
        rts
; =============================================================================
; kerog_ai -- Enemy AI: Kerog (type $0C) — frog, spawns Petit Kerogs ($982F)
; Mislabeled by annotation scripts as "Springer". Actually type $0C (Kerog).
; =============================================================================
kerog_ai_entry:
        lda     ent_anim_id,x
        cmp     #$09
        bcs     kerog_check_jump_state
        lda     #$01
        sta     temp_01
        lda     #ENTITY_PETIT_KEROG
        jsr     find_entity_count_check
        bcs     kerog_check_anim
        lda     #$09
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_anim_frame,x
        jsr     kerog_apply_physics
kerog_check_jump_state:
        cmp     #$0A
        bne     kerog_apply_physics
        lda     ent_anim_frame,x
        bne     kerog_apply_physics
        lda     #$02
        sta     temp_01
kerog_spawn_child_loop:  lda     #ENTITY_PETIT_KEROG
        jsr     spawn_entity_from_parent
        bcs     kerog_check_anim
        ldx     temp_01
        lda     kerog_child_vel_x_sub,x
        sta     $0630,y
        lda     kerog_child_vel_x_hi,x
        sta     $0610,y
        ldx     current_entity_slot
        dec     temp_01
        bpl     kerog_spawn_child_loop
kerog_check_anim:  lda     ent_anim_id,x
        cmp     #$08
        bne     kerog_apply_physics
        lda     #$00
        sta     ent_anim_id,x
kerog_apply_physics:  jsr     entity_face_player
        jsr     apply_entity_physics_alt
        rts

kerog_child_vel_x_sub:  .byte   $15,$8D,$A2 ; Petit Kerog X velocity table
kerog_child_vel_x_hi:  .byte   $04,$02,$01
kerog_child_collision_check:
        lda     #$00
        sta     ent_anim_frame,x
        lda     #$03
        sta     temp_01
        lda     #$04
        sta     temp_02
        jsr     check_horiz_tile_collision
        lda     $0110,x
        bne     kerog_dec_timer
        lda     temp_00
        beq     petit_kerog_apply_physics
        lda     #$3E
        sta     ent_state,x
        inc     ent_anim_id,x
        lda     #$00
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
        inc     $0110,x
        bne     petit_kerog_apply_physics
kerog_dec_timer:  dec     ent_state,x
        bne     petit_kerog_apply_physics
        dec     ent_anim_id,x
        dec     $0110,x
        jsr     entity_face_player
        lda     #$A2
        sta     ent_x_vel_sub,x
        lda     #$01
        sta     ent_x_vel,x
        lda     #$E6
        sta     ent_x_vel_sub,x
        lda     #$04
        sta     ent_y_vel,x
petit_kerog_apply_physics:  jsr     apply_entity_physics
        rts

; --- boss_ai_init_entry -- Boss intro sequence — HP fill, palette flash, countdown (ptr table: type $0F) ---
boss_ai_init_entry:
        lda     ent_x_vel_sub,x
        bne     boss_countdown_dec
        lda     ent_state,x
        beq     boss_skip_palette
        ldy     #$02
        cmp     ent_hp,x
        beq     boss_apply_palette
        ldy     #$05
boss_apply_palette:
        jsr     boss_set_palette
boss_skip_palette:
        lda     ent_hp,x
        sta     ent_state,x
        lda     ent_x_screen,x
        sta     ent_y_vel_sub,x
        jsr     apply_simple_physics
        lda     ent_hp,x
        bne     die_expand_phase
        lda     #$A0
        sta     ent_flags,x
        lda     #ENTITY_BOSS_DEATH
        sta     ent_type,x
        ldx     #$01
die_spawn_part_loop:  stx     temp_01
        lda     boss_debris_type,x
        jsr     find_entity_by_type
        bcs     die_spawn_part_next
        lda     #$00
        sta     ent_spawn_flags,y
        lda     #$FF
        sta     $0120,y
die_spawn_part_next:  ldx     temp_01
        dex
        bpl     die_spawn_part_loop
        ldx     current_entity_slot
        ldy     $0110,x
        lda     #$00
        sta     $013F,y
        sta     $0141,y
        sta     $013E,y
        sta     $0142,y
        lda     #$0E
        sta     ent_x_vel_sub,x
        lda     #$06
        sta     ent_x_vel,x
die_expand_phase:  rts

boss_countdown_dec:
        dec     ent_x_vel,x
        php
        lda     ent_x_vel_sub,x
        cmp     #$05
        bcc     die_expand_normal
        ldy     #$02
        plp
        beq     die_expand_large
        jsr     boss_set_palette
        rts

die_expand_large:  ldy     #$05
        bne     die_expand_set_timer
die_expand_normal:  plp
        bne     die_expand_rts
        ldy     ent_x_vel_sub,x
        lda     boss_debris_anim_table,y
        tay
die_expand_set_timer:  lda     #$09
        sta     ent_x_vel,x
        jsr     boss_set_palette
        lda     ent_x_vel_sub,x
        cmp     #$06
        bcs     die_expand_check_done
        jsr     boss_spawn_debris
die_expand_check_done:  dec     ent_x_vel_sub,x
        bne     die_expand_rts
        lsr     ent_flags,x
die_expand_rts:  rts

; =============================================================================
; boss_set_palette -- Boss Palette Setup — copy palette data for boss encounter ($998D)
; =============================================================================
boss_set_palette:  ldx     #$02
boss_palette_copy_loop:  lda     boss_palette_data,y
        sta     $035F,x
        sta     $037F,x
        sta     $038F,x
        sta     $039F,x
        dey
        dex
        bpl     boss_palette_copy_loop
        ldx     current_entity_slot
        rts

boss_spawn_debris:  lda     #$04
        sta     temp_01
        lda     ent_x_vel_sub,x
        asl     a
        asl     a
        adc     ent_x_vel_sub,x
        sta     temp_02
        lda     ent_y_vel_sub,x
        sta     temp_03
boss_debris_loop:  lda     #ENTITY_DEATH_EXPLODE
        jsr     spawn_entity_from_parent
        bcs     boss_debris_done
        ldx     temp_02
        lda     boss_debris_y_table,x
        sta     ent_y_spawn_px,y
        lda     temp_03
        sta     ent_x_spawn_scr,y
        cmp     #$09
        php
        lda     boss_debris_x_table,x
        plp
        beq     boss_debris_set_pos
        sec
        sbc     #$20
boss_debris_set_pos:  sta     ent_x_spawn_px,y
        sec
        sbc     scroll_x
        lda     temp_03
        sbc     nametable_select
        beq     boss_debris_check_screen
        lda     #$00
        sta     ent_spawn_flags,y
boss_debris_check_screen:  ldx     current_entity_slot
        inc     temp_02
        dec     temp_01
        bpl     boss_debris_loop
boss_debris_done:  ldx     current_entity_slot
        lda     #$2B
        jsr     bank_switch_enqueue
        rts

boss_palette_data:                       ; boss intro palette (2 x 3-byte entries)
        .byte   $20,$15,$0F,$20,$20,$0F
boss_debris_type:  .byte   $10          ; entity type for debris pieces
boss_debris_anim_table:                  ; boss debris animation frame indices
        .byte   $02,$17,$14,$11,$0E,$31,$14,$0F
        .byte   $21,$13,$01,$11
boss_debris_x_table:  .byte   $11,$01,$11,$11,$11,$68,$78,$88
        .byte   $88,$A8,$68,$78,$98,$98,$B8,$68
        .byte   $78,$98,$98,$A8,$58,$68,$88,$A8
        .byte   $B8
boss_debris_y_table:                     ; Y pixel position per debris piece (30 entries)
        .byte   $68,$78,$78,$88,$A8,$B8,$A8,$88
        .byte   $B8,$B8,$A8,$B8,$98,$B8,$A8,$98
        .byte   $B8,$98,$B8,$A8,$B8,$88,$98,$88
        .byte   $B8,$B8,$88,$A8,$A8,$98
        lda     ent_state,x
        bne     atomic_fire_check_state
        lda     #$01
        sta     ent_anim_id,x
        lda     #$70
        sta     ent_state,x
atomic_fire_check_state:  lda     ent_anim_id,x
        cmp     #$04
        bcc     atomic_fire_update
        lda     #$00
        sta     ent_anim_frame,x
atomic_fire_update:  dec     ent_state,x
        jsr     apply_simple_physics
        rts

anko_11_ai:
        ldy     #$02
        jsr     boss_set_palette
        lda     #$FF
        sta     $0120,x
        lsr     ent_flags,x
        rts
rail_platform_ai:
        lda     #$14
        sta     $0150,x
        sec
        lda     ent_x_screen,x
        sbc     #$04
        ldy     current_stage
        cpy     #$07
        beq     crashman_store_pos
        sec
        lda     ent_x_screen,x
        sbc     #$1B
crashman_store_pos:
        sta     temp_00
        tay
        lda     crashman_path_offset_table,y
        sta     temp_01
        clc
        adc     ent_state,x
        tay
        lda     temp_00
        cmp     #$03
        bcs     crashman_path_wily
        lda     crashman_path_data,y
        sta     temp_02
        lda     crashman_path_entry,y
        jmp     crashman_check_axis

; =============================================================================
; crashman_path_wily -- Boss AI: Crashman — pathfinding with bounce patterns ($9AA8)
; =============================================================================
crashman_path_wily:  lda     crashman_wily_path_data,y
        sta     temp_02
        lda     crashman_wily_path_entry,y
crashman_check_axis:  and     #$01
        bne     crashman_check_x
        lda     ent_y_px,x
        cmp     temp_02
        beq     crashman_at_target
        bne     crashman_get_direction
crashman_check_x:  lda     ent_x_px,x
        cmp     temp_02
        bne     crashman_get_direction
crashman_at_target:  lda     #$00
        sta     ent_x_sub,x
        sta     ent_y_sub,x
        iny
        iny
        inc     ent_state,x
        inc     ent_state,x
        lda     ent_state,x
        ldx     temp_00
        cmp     crashman_path_len_table,x
        bne     crashman_get_direction
        ldx     current_entity_slot
        lda     #$00
        sta     ent_state,x
        ldy     temp_01
crashman_get_direction:  ldx     temp_00
        cpx     #$03
        bcs     crashman_get_direction_wily
        lda     crashman_path_entry,y
        jmp     crashman_set_velocity

crashman_get_direction_wily:  lda     crashman_wily_path_entry,y
crashman_set_velocity:  ldx     current_entity_slot
        tay
        lda     crashman_vel_y_sub_table,y
        sta     ent_y_vel_sub,x
        lda     crashman_vel_y_table,y
        sta     ent_y_vel,x
        lda     crashman_vel_x_sub_table,y
        sta     ent_x_vel_sub,x
        lda     crashman_flags_table,y
        sta     ent_flags,x
        jsr     apply_entity_physics
        bcc     crashman_set_hitbox
        lda     #$00
        sta     $0150,x
crashman_set_hitbox:  sec
        lda     ent_y_px,x
        sbc     #$04
        sta     $0160,x
        rts

crashman_path_offset_table:  .byte   $00,$08,$24,$00,$44,$5C,$8C
crashman_vel_y_sub_table:  .byte   $1B,$00,$E5,$00
crashman_vel_y_table:  .byte   $FF,$00,$00,$00
crashman_vel_x_sub_table:  .byte   $00,$E5,$00,$E5
crashman_flags_table:  .byte   $80,$80,$C0,$C0
crashman_path_len_table:  .byte   $08,$1C,$54,$44,$18,$30,$14
crashman_path_data:                      ; Crashman movement path coordinate data
        .byte   $A0                       ; path header
crashman_path_entry:
        .byte   $00,$28,$01,$40,$02,$D8,$03,$A0
        .byte   $00,$68,$01,$80,$02,$98,$03,$60
        .byte   $02,$B8,$03,$40,$02,$88,$01,$60
        .byte   $00,$28,$01,$40,$02,$68,$03,$20
        .byte   $02,$D8,$03,$A0,$00,$28,$01,$90
        .byte   $02,$C8,$03,$30,$02,$A8,$01,$40
        .byte   $00,$B8,$03,$50,$00,$A8,$01,$60
        .byte   $00,$B8,$03,$70,$00,$A8,$01,$80
        .byte   $00,$88,$01,$70,$02,$98,$03,$60
        .byte   $02,$88,$01,$50,$02,$98,$03,$40
        .byte   $02,$88,$01,$30,$02,$78,$01,$80
        .byte   $00,$38,$01,$70,$02,$68,$03,$60
        .byte   $02,$38,$01,$50,$02,$68,$03,$40
        .byte   $02,$28,$01,$70,$00,$18,$01,$30
        .byte   $02,$68,$03,$20,$02,$D8,$03
crashman_wily_path_data:                 ; Crashman Wily stage path data
        .byte   $A0                       ; path header
crashman_wily_path_entry:
        .byte   $00,$B8,$01,$50,$02,$E8,$03,$40
        .byte   $02,$C8,$01,$20,$02,$88,$01,$30
        .byte   $00,$A8,$03,$60,$00,$88,$01,$70
        .byte   $00,$A8,$03,$B0,$00,$78,$01,$50
        .byte   $02,$98,$03,$40,$02,$58,$01,$30
        .byte   $02,$78,$03,$20,$02,$38,$01,$60
        .byte   $00,$48,$03,$50,$02,$68,$03,$70
        .byte   $00,$48,$01,$C0,$00,$C8,$03,$80
        .byte   $02,$D8,$03,$C0,$00,$18,$01,$90
        .byte   $02,$38,$03,$B0,$00,$58,$03,$C0
        .byte   $00,$C8,$03,$70,$02,$88,$01,$20
        .byte   $02,$48,$01,$90,$00,$18,$01,$60
        .byte   $02,$28,$03,$B0,$00,$B8,$03,$C0
        .byte   $00,$E8,$03,$40,$02,$C8,$01,$30
        .byte   $02,$98,$01,$40,$00,$B8,$03,$50
        .byte   $00,$D8,$03,$B0,$00,$C8,$01,$60
        .byte   $02,$58,$01,$30,$02,$28,$01,$40
        .byte   $00,$38,$03,$80,$00,$38,$01,$60
        .byte   $02,$48,$03,$A0,$00,$88,$03,$C0
        .byte   $00,$D8,$03,$50,$02,$58,$01
        lda     #$18
        sta     $0150,x
        lda     ent_flags,x
        and     #$04
        bne     metalman_set_throw_flag
        lda     ent_state,x
        cmp     #$06
        bcs     metalman_set_throw_flag
        jsr     apply_entity_physics_alt
        jmp     metalman_physics

; =============================================================================
; metalman_set_throw_flag -- Boss AI: Metal Man — blade throw with pattern tables ($9C74)
; Spawns entity $15 (Metal Blade projectile).
; =============================================================================
metalman_set_throw_flag:  lda     ent_flags,x
        ora     #$04
        sta     ent_flags,x
        jsr     apply_entity_physics
metalman_physics:  bcc     metalman_hitbox_rts
        lda     #$00
        sta     $0150,x
metalman_hitbox_rts:  sec
        lda     ent_y_px,x
        sbc     #$08
        sta     $0160,x
        rts

laser_beam_ai:
        sec
        lda     ent_x_screen,x
        sbc     #$03
        tay
        lda     metalman_blade_count_table,y
        sta     temp_02
        lda     metalman_blade_src_table,y
        sta     temp_01
metalman_spawn_blade:  lda     #ENTITY_METAL_BLADE
        jsr     spawn_entity_from_parent
        ldx     temp_01
        lda     metalman_blade_flags,x
        sta     ent_spawn_flags,y
        and     #$40
        bne     metalman_blade_offset
        lda     #$FC
        bne     metalman_blade_set_x
metalman_blade_offset:  lda     #$04
metalman_blade_set_x:  sta     ent_x_spawn_px,y
        lda     metalman_blade_y_table,x
        sta     ent_y_spawn_px,y
        lda     metalman_blade_range,x
        sta     $0120,y
        lda     metalman_blade_timer_table,x
        sta     $04F0,y
        ldx     current_entity_slot
        inc     temp_01
        dec     temp_02
        bne     metalman_spawn_blade
        lsr     ent_flags,x
        lda     #$00
        sta     a:$F0,x
        rts

metalman_blade_count_table:
        .byte   $02,$03,$04,$00,$00,$00,$00,$00
        .byte   $00,$0C,$0A,$05,$05,$02,$05,$04
metalman_blade_src_table:  .byte   $00,$02,$05,$09,$09,$09,$09,$09 ; Metalman blade source position table
        .byte   $09,$09,$15,$1F,$24,$29,$2B,$30
metalman_blade_flags:                    ; entity flags per blade direction (52 entries)
        .byte   $E1,$A1,$E1,$A1,$A1,$E1,$A1,$E1
        .byte   $A1,$E1,$A1,$E1,$A1,$E1,$A1,$E1
        .byte   $A1,$E1,$A1,$E1,$A1,$E1,$A1,$E1
        .byte   $A1,$E1,$A1,$E1,$A1,$E1,$A1,$E1
        .byte   $A1,$E1,$A1,$A1,$A1,$A1,$E1,$E1
        .byte   $A1,$A1,$A1,$A1,$A1,$A1,$A1,$E1
        .byte   $A1,$A1,$E1,$A1
metalman_blade_y_table:  .byte   $47
        .byte   $77,$57,$87,$C7,$47,$67,$87,$C7
        .byte   $17,$17,$37,$37,$57,$57,$77,$77
        .byte   $A7,$A7,$B7,$B7,$37,$37,$57,$57
        .byte   $77,$77,$97,$97,$B7,$B7,$17,$17
        .byte   $27,$27,$A7,$17,$37,$67,$87,$A7
        .byte   $67,$B7,$27,$47,$67,$77,$A7,$17
        .byte   $27,$67,$A7
metalman_blade_range:                    ; distance range per throw direction (52 entries)
        .byte   $FF,$00,$FF,$00,$00,$FF,$A0,$60
        .byte   $60,$80,$80,$80,$80,$80,$80,$80
        .byte   $80,$80,$80,$80,$80,$80,$80,$80
        .byte   $80,$60,$A0,$80,$80,$80,$80,$80
        .byte   $80,$80,$80,$00,$00,$00,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$80,$00,$70
        .byte   $00,$00,$FF,$20
metalman_blade_timer_table:              ; frame timing per throw pattern (52 entries)
        .byte   $01,$1F,$01,$1F,$3E,$01,$1F,$3E
        .byte   $5D,$01,$01,$1F,$1F,$3E,$3E,$5D
        .byte   $5D,$7C,$7C,$9D,$9D,$01,$01,$1F
        .byte   $1F,$3E,$3E,$5D,$5D,$7C,$7C,$01
        .byte   $01,$1F,$1F,$3E,$01,$1F,$3E,$5D
        .byte   $7C,$01,$1F,$01,$1F,$3E,$5D,$7C
        .byte   $01,$1F,$3E,$5D
; --- woodman_ai_timer_check -- Wood Man boss AI (bank0E) — timer countdown, Leaf Shield trigger (ptr table: type $15) ---
woodman_ai_timer_check:
        lda     ent_state,x
        beq     woodman_timer_expired
        dec     ent_state,x
        beq     woodman_timer_just_zero
        rts
woodman_timer_just_zero:
        lda     ent_flags,x
        and     #$DF
        sta     ent_flags,x
        lda     #$27
        jsr     bank_switch_enqueue
woodman_timer_expired:
        lda     ent_flags,x
        and     #$20
        bne     woodman_check_contact
        lda     ent_flags,x
        and     #$40
        bne     woodman_check_leaf_wall
        lda     ent_x_px,x
        cmp     $0110,x
        bcs     woodman_walk_step
        bcc     woodman_at_target_x

; =============================================================================
; woodman_check_leaf_wall -- Boss AI: Woodman — walk, leaf shield, contact check ($9DFE)
; =============================================================================
woodman_check_leaf_wall:  lda     ent_x_px,x
        cmp     $0110,x
        bcc     woodman_walk_step
woodman_at_target_x:  lda     $0110,x
        sta     ent_x_px,x
        lda     ent_flags,x
        ora     #$20
        sta     ent_flags,x
        bne     woodman_check_contact
woodman_walk_step:  lda     ent_x_screen,x
        sta     jump_ptr_hi
        lda     ent_x_px,x
        sta     jump_ptr
        lda     ent_y_px,x
        and     #$F0
        sta     $0A
        jsr     metatile_render
        ldy     #$74
        lda     $03BC,x
        and     #$01
        beq     woodman_set_tile
        ldy     #$76
woodman_set_tile:  tya
        sta     $03C2,x
        inc     attr_update_count
        ldx     current_entity_slot
        jsr     apply_entity_physics
        bcc     woodman_check_contact
        lda     ent_flags,x
        asl     a
        ora     #$20
        sta     ent_flags,x
woodman_check_contact:  lda     invincibility_timer
        bne     woodman_rts
        sec
        lda     ent_y_px,x
        sbc     ent_y_px
        bcs     woodman_check_y_range
        eor     #$FF
        adc     #$01
woodman_check_y_range:  cmp     #$10
        bcs     woodman_rts
        lda     ent_flags,x
        and     #$40
        bne     woodman_facing_left
        lda     ent_x_px,x
        cmp     ent_x_px
        bcs     woodman_rts
        bcc     woodman_trigger_shield
woodman_facing_left:  lda     ent_x_px,x
        cmp     ent_x_px
        bcc     woodman_rts
woodman_trigger_shield:  lda     #$00
        sta     game_substate
        jmp     boss_death_sequence

woodman_rts:  rts

; --- bubbleman_ai_init -- Bubble Man boss AI (bank0E) — state init, jump/shoot pattern (ptr table: type $16) ---
bubbleman_ai_init:
        lda     ent_state,x
        bne     bubbleman_check_state
        lda     rng_seed
        eor     #$01
        sta     rng_seed
        and     #$01
        tay
        lda     bubbleman_timer_table,y
        sta     ent_state,x
        lda     #$8B
        sta     ent_flags,x
        bne     bubbleman_apply_physics
bubbleman_check_state:
        cmp     #$01
        beq     bubbleman_state_swim
        cmp     #$FF
        beq     bubbleman_state_fall
        dec     ent_state,x
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
bubbleman_apply_physics:
        jsr     apply_entity_physics_alt
        rts

; =============================================================================
; bubbleman_state_swim -- Boss AI: Bubbleman — swim/fall physics, bubble shot ($9EB3)
; =============================================================================
bubbleman_state_swim:  lda     ent_flags,x
        and     #$F7
        sta     ent_flags,x
        lda     ent_anim_id,x
        cmp     #$08
        bne     bubbleman_swim_physics
        lda     #$05
        sta     ent_anim_id,x
        lda     #$00
        sta     jump_ptr_hi
        lda     #$83
        sta     jump_ptr
        jsr     calc_entity_velocity
bubbleman_swim_physics:  jsr     apply_entity_physics
        lda     temp_01
        beq     bubbleman_swim_rts
        lda     #$00
        sta     ent_x_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_y_vel_sub,x
        lda     #$02
        sta     ent_y_vel,x
        lda     #$FF
        sta     ent_state,x
bubbleman_swim_rts:  rts

bubbleman_state_fall:  lda     ent_anim_id,x
        cmp     #$08
        bne     bubbleman_fall_setup
        lda     #$05
        sta     ent_anim_id,x
bubbleman_fall_setup:  lda     #$04
        sta     temp_01
        lda     #$08
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     temp_00
        beq     bubbleman_fall_physics
        lda     #$00
        sta     ent_y_vel,x
        sta     ent_y_vel_sub,x
        lda     #$8B
        sta     ent_flags,x
        lda     #$3E
        sta     ent_state,x
bubbleman_fall_physics:  jsr     apply_entity_physics
        rts

bubbleman_timer_table:  .byte   $3E,$9C         ; Bubbleman AI timer values (62/156 frames)
; --- quickman_ai_init -- Quick Man boss AI (bank0E) — tile collision, dash/jump pattern (ptr table: type $17) ---
quickman_ai_init:
        lda     ent_y_vel,x
        sta     temp_04
        lda     #$0C
        sta     temp_01
        lda     #$10
        sta     temp_02
        jsr     check_horiz_tile_collision
        lda     $0110,x
        bne     quickman_check_pattern
        lda     ent_state,x
        bne     quickman_dec_timer
        lda     #$C0
        sta     ent_x_vel_sub,x
        sta     ent_y_vel_sub,x
        lda     #$04
        sta     ent_y_vel,x
        sta     temp_04
        jsr     entity_face_player
        inc     $0110,x
        lda     #$01
        sta     ent_anim_id,x
quickman_check_pattern:
        lda     $0110,x
        cmp     #$01
        bne     quickman_check_timer
        lda     temp_04
        bpl     quickman_dec_timer
        lda     temp_00
        beq     quickman_dec_timer
        lda     #$00
        sta     ent_x_vel_sub,x
        inc     $0110,x
        lda     #$3E
        sta     ent_state,x
        lda     #$03
        sta     ent_anim_id,x
        bne     quickman_dec_timer

; =============================================================================
; quickman_check_timer -- Boss AI: Quick Man — timer-based movement, boomerang throw ($9F79)
; Spawns entity $18 (Quick Boomerang projectile).
; =============================================================================
quickman_check_timer:  lda     ent_state,x
        bne     quickman_dec_timer
        jsr     entity_face_player
        lda     #ENTITY_QUICK_BOOM      ; spawn Quick Boomerang projectile
        jsr     spawn_entity_from_parent
        bcs     quickman_set_timer
        lda     current_entity_slot
        pha
        tya
        clc
        adc     #$10
        tax
        stx     current_entity_slot
        lda     #$02
        sta     jump_ptr_hi
        lda     #$0C
        sta     jump_ptr
        jsr     calc_entity_velocity
        pla
        sta     current_entity_slot
        tax
quickman_set_timer:  lda     #$3E
        sta     ent_state,x
        inc     $0110,x
        lda     $0110,x
        cmp     #$05
        bne     quickman_dec_timer
        lda     #$00
        sta     $0110,x
quickman_dec_timer:  dec     ent_state,x
        ldy     $0110,x
        lda     ent_anim_id,x
        cmp     quickman_anim_threshold,y
        bne     quickman_state_table
        lda     #$00
        sta     ent_anim_frame,x
quickman_state_table:  jsr     apply_entity_physics
        rts

quickman_anim_threshold:  .byte   $00,$02,$00,$00,$00             ; Quickman animation speed thresholds
air_tornado_proj_ai:
        ldy     #$02
        lda     ent_hp,x
        bne     quickman_palette_check
        jmp     heatman_check_state_entry
quickman_palette_check:
        cmp     ent_y_vel_sub,x
        beq     quickman_palette_set
        ldy     #$05
quickman_palette_set:  sta     ent_y_vel_sub,x
        ldx     #$0F
quickman_palette_loop:  lda     heatman_palette_data,y
        sta     palette_ram,x
        dey
        dex
        cpx     #$0C
        bne     quickman_palette_loop
        ldx     current_entity_slot
        lda     ent_x_vel_sub,x
        bne     heatman_check_state
        lda     #$01
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_anim_frame,x
        lda     ent_state,x
        bne     heatman_dec_timer
        lda     #ENTITY_ATOMIC_FIRE     ; spawn Atomic Fire projectile
        jsr     spawn_entity_from_parent
        bcs     heatman_spawn_fire
        clc
        lda     ent_y_spawn_px,y
        adc     #$0C
        sta     ent_y_spawn_px,y

; =============================================================================
; heatman_spawn_fire -- Boss AI: Heat Man — flame pattern, charge attack ($A019)
; Spawns entity $1B (Atomic Fire projectile).
; =============================================================================
heatman_spawn_fire:  lda     #$02
        sta     ent_state,x
        dec     ent_x_vel,x
        bne     heatman_apply_physics
        inc     ent_x_vel_sub,x
        bne     heatman_apply_physics
heatman_dec_timer:  dec     ent_state,x
heatman_check_state:  lda     ent_anim_id,x
        bne     heatman_apply_physics
        lda     #$00
        sta     ent_x_vel_sub,x
        lda     #$03
        sta     ent_x_vel,x
        lda     rng_seed
        and     #$03
        beq     heatman_apply_physics
        asl     ent_x_vel,x
        and     #$01
        bne     heatman_apply_physics
        clc
        lda     ent_x_vel,x
        adc     #$03
        sta     ent_x_vel,x
heatman_apply_physics:  jsr     apply_entity_physics_alt
        bcc     heatman_rts
        lda     #$80
        sta     ent_flags,x
        lda     #ENTITY_AIR_TORNADO1    ; convert self to fire/tornado projectile
        sta     ent_type,x
        lda     #$00
        sta     ent_state,x
        sta     ent_x_vel_sub,x
        sta     $0100,x
heatman_rts:  rts

heatman_check_state_entry:
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        lda     ent_x_vel_sub,x
        beq     heatman_flame_pattern
        jmp     heatman_dec_cooldown

heatman_flame_pattern:  lda     ent_state,x
        and     #$03
        sta     temp_00
        asl     a
        asl     a
        adc     temp_00
        sta     temp_01
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$05
        sta     temp_02
heatman_flame_loop:  lda     #ENTITY_DEATH_EXPLODE
        jsr     spawn_entity_from_parent
        bcs     heatman_flame_done
        ldx     temp_01
        clc
        lda     ent_x_spawn_px,y
        adc     heatman_flame_x_offset,y
        sta     ent_x_spawn_px,y
        clc
        lda     ent_y_spawn_px,y
        adc     heatman_flame_y_offset,y
        sta     ent_y_spawn_px,y
        .byte   $E6                      ; code: INC $01 (advance flame slot)
heatman_flame_inc:  .byte   $01,$C6,$02  ; dual-use: data table AND code (DEC $02)
        bne     heatman_flame_loop
heatman_flame_done:  ldx     current_entity_slot
        inc     ent_state,x
        lda     ent_state,x
        cmp     #$08
        bne     heatman_set_cooldown
        lda     #$1A
        jsr     find_entity_by_type
        bcs     heatman_deactivate_parts
        lda     #$00
        sta     ent_spawn_flags,y
        lda     #$FF
        sta     $0100,y
heatman_deactivate_parts:  lda     #$1C
        jsr     find_entity_by_type
        bcs     heatman_deactivate_more
        lda     #$FF
        sta     $04F0,y
heatman_deactivate_more:  lda     #$2E
        jsr     find_entity_by_type
        bcs     heatman_deactivate_final
        lda     #$00
        sta     ent_spawn_flags,y
        lda     #$FF
        sta     $0130,y
        lda     $0120,y
        tay
        lda     #$00
        sta     $0140,y
        beq     heatman_deactivate_more
heatman_deactivate_final:  sta     a:$F0,x
        asl     ent_flags,x
heatman_set_cooldown:  lda     #$08
        sta     ent_x_vel_sub,x
heatman_dec_cooldown:  dec     ent_x_vel_sub,x
        rts

heatman_palette_data:                    ; Heat Man intro palette (6 bytes)
        .byte   $08,$2C,$12,$08,$20,$20
heatman_flame_x_offset:  .byte   $FC    ; Heatman flame X offset per slot
        .byte   $FC,$14,$1C,$2C,$F4,$04,$0C,$14
        .byte   $24,$F4,$04,$14,$2C,$2C,$04,$0C
heatman_flame_data_end:  .byte   $14,$24,$24
heatman_flame_y_offset:                  ; Heat Man flame Y pixel offsets (11 entries)
        .byte   $F8,$10,$08,$F0,$F8,$00,$E8,$10
        .byte   $F8,$08,$08
heatman_flame_y_data_2:                  ; Heat Man flame Y offsets continued (9 entries)
        .byte   $F8,$00,$E8,$08,$00,$E8,$F8,$F0
        .byte   $08
        ; code: Friender fire init (check timer, set animation state)
        lda     ent_state,x
        bne     airman_check_state
        lda     #$6E
        sta     ent_state,x
        lda     #$01
        sta     ent_anim_id,x
airman_check_state:
        lda     ent_anim_id,x
        bne     airman_dec_timer
        sta     ent_anim_frame,x

; =============================================================================
; airman_dec_timer -- Boss AI: Air Man — tornado spawn, tile pattern update ($A14D)
; Spawns entities $19/$1A (Air Shooter tornados, primary/secondary).
; =============================================================================
airman_dec_timer:  dec     ent_state,x
        jsr     apply_entity_physics_alt
        rts

atomic_fire_ai:
        clc
        lda     ent_y_vel_sub,x
        adc     #$40
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        adc     #$00
        sta     ent_y_vel,x
        jsr     apply_entity_physics
        rts
friender_ai:
        sec
        lda     ent_x_screen,x
        sbc     #$06
        tay
        lda     airman_height_threshold,y
        cmp     ent_y_px,x
        beq     airman_landing_reached
        lda     ent_flags,x
        and     #$DF
        sta     ent_flags,x
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        jsr     apply_entity_physics
        rts
airman_landing_reached:
        lda     #$00
        sta     ent_y_vel,x
        jsr     apply_entity_physics_alt
        lda     ent_anim_id,x
        pha
        tay
        clc
        lda     ent_y_px,x
        adc     airman_y_offset_table,y
        and     #$E0
        sta     $0A
        clc
        lda     ent_x_px,x
        adc     airman_x_offset_table,y
        and     #$E0
        sta     jump_ptr
        lda     ent_x_screen,x
        sta     jump_ptr_hi
        jsr     metatile_render
        jsr     metatile_attr_update
        ldy     ppu_buffer_count
        lda     col_update_addr_hi
        sta     ppu_update_buf,y
        lda     $03BC
        sta     $0304,y
        lda     $03C2
        sta     $0308,y
        lda     $03C8
        sta     $030C,y
        lda     #$FF
        sta     $0350,y
        tya
        asl     a
        asl     a
        asl     a
        asl     a
        tay
        pla
        sta     temp_00
        ldx     current_entity_slot
        lda     ent_state,x
        cmp     #$FF
        bne     airman_set_tile_pattern
        clc
        lda     temp_00
        adc     #$04
        sta     temp_00
airman_set_tile_pattern:  lda     temp_00
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        lda     #$10
        sta     temp_00
airman_copy_tiles:  lda     airman_tile_data,x
        sta     $0310,y
        inx
        iny
        dec     temp_00
        bne     airman_copy_tiles
        inc     ppu_buffer_count
        ldx     current_entity_slot
        lda     ent_anim_id,x
        cmp     #$03
        bne     airman_rts
        lda     ent_state,x
        bne     airman_rts
        lda     #ENTITY_AIR_TORNADO1    ; spawn Air Shooter tornado (primary)
        jsr     spawn_entity_from_parent
        lda     #$08
        sta     $04F0,y
        lda     #$03
        sta     $0610,y
        lda     #$14
        sta     ent_y_sub,x
        lda     rng_seed
        and     #$03
        beq     airman_spawn_tornado_2
        pha
        lda     $0610,y
        asl     a
        sta     $0610,y
        pla
        and     #$01
        bne     airman_spawn_tornado_2
        clc
        lda     $0610,y
        adc     #$03
        sta     $0610,y
airman_spawn_tornado_2:  lda     #ENTITY_AIR_TORNADO2    ; spawn Air Shooter tornado (secondary)
        jsr     spawn_entity_from_parent
        clc
        lda     ent_x_spawn_px,y
        adc     #$2F
        sta     ent_x_spawn_px,y
        sec
        lda     ent_y_spawn_px,y
        sbc     #$0C
        sta     ent_y_spawn_px,y
        inc     ent_state,x
        lda     #$A0
        sta     ent_flags,x
airman_rts:  rts

airman_height_threshold:
        .byte   $88,$68,$48
airman_y_offset_table:
        .byte   $F0,$00,$F0,$00       ; Y pixel offsets: -16, 0, -16, 0
airman_x_offset_table:
        .byte   $00,$00,$20,$20       ; X pixel offsets: 0, 0, 32, 32
airman_tile_data:                         ; 128 bytes — CHR tile indices for Air Man sprite
        .byte   $88,$8A,$84,$86,$89,$8B,$85,$87  ; frame 1
        .byte   $84,$86,$8C,$8E,$85,$87,$8D,$8F
        .byte   $84,$86,$74,$76,$85,$87,$75,$77
        .byte   $90,$92,$94,$96,$91,$93,$95,$97
        .byte   $84,$86,$84,$86,$85,$87,$85,$87
        .byte   $6C,$6E,$70,$72,$6D,$6F,$71,$73
        .byte   $78,$7A,$7C,$7E,$79,$7B,$7D,$7F
        .byte   $98,$9A,$9C,$9E,$99,$9B,$9D,$9F
        .byte   $88,$8A,$84,$86,$89,$8B,$85,$87  ; frame 2
        .byte   $84,$86,$84,$86,$85,$87,$85,$87
        .byte   $84,$86,$84,$86,$85,$87,$85,$87
        .byte   $84,$86,$84,$86,$85,$87,$85,$87
        .byte   $84,$86,$84,$86,$85,$87,$85,$87
        .byte   $84,$86,$84,$86,$85,$87,$85,$87
        .byte   $84,$86,$84,$86,$85,$87,$85,$87
        .byte   $84,$86,$84,$86,$85,$87,$85,$87
        jsr     entity_face_player
        lda     ent_flags,x
        and     #$20
        beq     flashman_state_walk
        lda     temp_00
        cmp     #$50
        bcc     flashman_stop_freeze
        jsr     apply_entity_physics_alt
        rts

; =============================================================================
; flashman_stop_freeze -- Boss AI: Flashman — time stopper, walk/jump/shoot ($A308)
; =============================================================================
flashman_stop_freeze:  lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        lda     ent_flags,x
        and     #$DF
        sta     ent_flags,x
        lda     #$04
        sta     ent_y_vel,x
flashman_state_walk:  lda     ent_anim_id,x
        bne     flashman_check_shoot
        lda     #$00
        sta     ent_anim_frame,x
        lda     #$07
        sta     temp_01
        lda     #$01
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     temp_00
        bne     flashman_wall_stop
        jmp     flashman_physics

flashman_wall_stop:  lda     #$00
        sta     ent_y_vel,x
        inc     ent_anim_id,x
        jmp     flashman_physics

flashman_check_shoot:  lda     ent_anim_id,x
        cmp     #$02
        bne     flashman_check_height
        clc
        lda     ent_y_px,x
        adc     #$05
        sta     ent_y_px,x
        inc     ent_anim_id,x
flashman_check_height:  lda     ent_anim_id,x
        cmp     #$08
        bcs     flashman_state_air
        lda     temp_00
        cmp     #$20
        bcc     flashman_jump
        inc     ent_state,x
        lda     ent_state,x
        cmp     #$7D
        beq     flashman_jump
        lda     ent_anim_id,x
        cmp     #$07
        bne     flashman_physics
        lda     #$03
        sta     ent_anim_id,x
        bne     flashman_physics
flashman_jump:  sec
        lda     ent_y_px,x
        sbc     #$20
        sta     ent_y_px,x
        lda     ent_flags,x
        ora     #$04
        sta     ent_flags,x
        lda     #$02
        sta     ent_state,x
        lda     #$08
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_anim_frame,x
        bne     flashman_physics
flashman_state_air:  lda     #$08
        sta     temp_01
        lda     #$10
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     #$00
        sta     ent_anim_frame,x
        lda     ent_anim_id,x
        cmp     #$09
        beq     flashman_state_land
        dec     ent_state,x
        bne     flashman_physics
        lda     #$03
        sta     ent_y_vel,x
        lda     #$76
        sta     ent_y_vel_sub,x
        lda     #$01
        sta     ent_x_vel,x
        lda     #$7B
        sta     ent_x_vel_sub,x
        inc     ent_anim_id,x
        bne     flashman_physics
flashman_state_land:  lda     temp_00
        beq     flashman_physics
        lda     #$08
        sta     ent_anim_id,x
        lda     #$32
        sta     ent_state,x
        lda     #$00
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
flashman_physics:  jsr     apply_entity_physics
        rts

; --- kukku_spawner_ai -- Kukku spawner (type $1E) — tracks player X, spawns Kukku bodies ---
kukku_spawner_ai:
        lda     ent_x_vel_sub,x
        bne     kukku_spawner_track
        lda     #ENTITY_KUKKU_SPAWN
        jsr     check_entity_collision_scan
        bcc     kukku_spawner_track
        rts
kukku_spawner_track:
        lda     ent_x_px
        sta     ent_x_px,x
        lda     ent_x_screen
        sta     ent_x_screen,x
        lda     ent_state,x
        bne     kukku_spawner_dec_timer
        lda     #$01
        sta     temp_01
        lda     #ENTITY_KUKKU
        jsr     find_entity_count_check
        bcs     kukku_spawner_set_timer
        lda     #ENTITY_KUKKU
        jsr     spawn_entity_from_parent
        bcs     kukku_spawner_set_timer
        clc
        lda     ent_x_spawn_px,y
        adc     #$78
        sta     ent_x_spawn_px,y
        lda     ent_x_spawn_scr,y
        adc     #$00
        sta     ent_x_spawn_scr,y
        sec
        lda     ent_y_px
        sbc     #$2C
        bcs     kukku_spawn_store_y
        lda     #$08
kukku_spawn_store_y:  sta     ent_y_spawn_px,y
        ldx     current_entity_slot
kukku_spawner_set_timer:  lda     #$1F
        sta     ent_state,x
kukku_spawner_dec_timer:  dec     ent_state,x
        rts

kukku_body_ai:
        lda     #$08
        sta     temp_01
        lda     #$14
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     temp_00
        beq     kukku_body_airborne
        lda     ent_state,x
        cmp     #$13
        bne     kukku_body_inc_timer
        lda     #$04
        sta     ent_y_vel,x
        lda     #$78
        sta     ent_y_vel_sub,x
        lda     #$00
        sta     ent_state,x
kukku_body_inc_timer:
        inc     ent_state,x
        bne     kukku_body_physics
kukku_body_airborne:
        lda     #$02
        sta     ent_anim_id,x
        lda     #$03
        sta     ent_anim_frame,x

; =============================================================================
; kukku_body_physics -- Kukku body (type $1F) — apply physics ($A47A)
; =============================================================================
kukku_body_physics:  jsr     apply_entity_physics
        rts

; --- kukku_despawn_ai -- Kukku despawner (type $20) — destroys all Kukku spawners via enemy_destroy_scan ---
kukku_despawn_ai:
        lda     #ENTITY_KUKKU_SPAWN
        sta     temp_00
        jmp     enemy_destroy_scan
; --- telly_spawn_ai -- Telly spawner (type $21) — timer-based, spawns up to 3 Telly bodies ---
telly_spawn_ai:
        lda     ent_state,x
        bne     boss_telly_dec_timer
        lda     #$03
        sta     temp_01
        lda     #ENTITY_TELLY
        jsr     find_entity_count_check
        bcs     boss_telly_store_timer
        lda     #ENTITY_TELLY
        jsr     spawn_entity_from_parent
boss_telly_store_timer:
        lda     #$DA
        sta     ent_state,x
boss_telly_dec_timer:
        dec     ent_state,x
        jsr     apply_entity_physics_alt
        rts

telly_ai:
        lda     ent_state,x
        bne     boss_spawn_dec_timer
        lda     #$00
        sta     jump_ptr_hi
        lda     #$42
        sta     jump_ptr
        jsr     calc_entity_velocity
        lda     #$10
        sta     ent_state,x
boss_spawn_dec_timer:  dec     ent_state,x
        jsr     apply_entity_physics
        rts

; --- changkey_ai -- Changkey flame enemy (type $23) — movement pattern, spawns projectile children ---
changkey_ai:
        lda     ent_x_vel_sub,x
        bne     boss_shot_check_timer
        lda     #$6E
        sta     ent_state,x
        inc     ent_x_vel_sub,x
        lda     #$00
        sta     ent_flags,x
        lda     #$01
        sta     temp_01
        lda     #ENTITY_CHANGKEY
        jsr     find_entity_count_check
        lda     #$83
        sta     ent_flags,x
        bcs     boss_dec_timer
        lda     #ENTITY_LIGHT_RESTORE
        jsr     spawn_entity_from_parent
        jmp     boss_dec_timer
boss_shot_check_timer:
        lda     ent_state,x
        beq     boss_check_anim_state
        lda     ent_anim_id,x
        cmp     #$02
        bne     boss_dec_timer
        lda     #$00
        sta     ent_anim_id,x
        beq     boss_dec_timer
boss_check_anim_state:  lda     ent_anim_id,x
        cmp     #$04
        bne     boss_check_physics
        lda     ent_anim_frame,x
        bne     boss_check_physics
        jsr     entity_face_player
        lda     #ENTITY_CHANGKEY_PROJ
        jsr     spawn_entity_from_parent
        bcs     boss_random_timer
        sec
        lda     rng_seed
        and     #$1F
        sta     rng_seed
        sec
        lda     temp_00
        sbc     rng_seed
        sta     temp_00
        lda     #$00
        asl     temp_00
        rol     a
        asl     temp_00
        rol     a
        asl     temp_00
        rol     a
        sta     $0610,y
        lda     temp_00
        sta     $0630,y
boss_random_timer:  lda     rng_seed
        and     #$03
        tay
        lda     boss_random_timer_table,y
        sta     ent_state,x
boss_dec_timer:  dec     ent_state,x
boss_check_physics:  jsr     apply_entity_physics_alt
        bcc     boss_misc_rts
        lda     #ENTITY_CHANGKEY
        jsr     find_entity_by_type
        bcc     boss_misc_rts
        lda     #ENTITY_BLACKOUT_RE
        jsr     spawn_entity_from_parent
boss_misc_rts:  rts

boss_random_timer_table:  .byte   $12,$1F,$1F,$3D             ; random timer values for boss AI
blackout_trigger_ai:
        lda     $0357
        cmp     #$0F
        beq     blackout_trigger_ai_done
        lda     #ENTITY_CHANGKEY
        jsr     find_entity_by_type
        bcc     blackout_trigger_ai_done
        lda     #ENTITY_LIGHT_RESTORE
        jsr     find_entity_by_type
        bcc     blackout_trigger_ai_done
        lda     ent_state,x
        bne     boss_palette_flash_dec
        lda     ent_x_vel_sub,x

; =============================================================================
; boss_palette_flash -- Boss Palette Flash — cycle palette during death/hit animation ($A577)
; =============================================================================
boss_palette_flash:  asl     a
        asl     a
        sta     temp_00
        asl     a
        clc
        adc     temp_00
        tax
        ldy     #$00
boss_palette_flash_loop:  lda     boss_palette_flash_data,x
        sta     palette_ram,y
        inx
        iny
        cpy     #$0C
        bne     boss_palette_flash_loop
        ldx     current_entity_slot
        inc     ent_x_vel_sub,x
        lda     ent_x_vel_sub,x
        cmp     #$04
blackout_trigger_ai_done:
        bne     boss_palette_flash_timer
        lsr     ent_flags,x
        lda     #$FF
        sta     a:$F0,x
boss_palette_flash_timer:  lda     #$08
        sta     ent_state,x
boss_palette_flash_dec:  dec     ent_state,x
        rts

        lda     ent_state,x
        bne     boss_palette_flash_dec
        clc
        lda     ent_x_vel_sub,x
        adc     #$03
        bne     boss_palette_flash
        lda     ent_state,x
        bne     boss_palette_flash_dec
        lda     ent_x_vel_sub,x
        eor     #$03
        jmp     boss_palette_flash

blackout_restore_ai:
        lda     ent_state,x
        bne     boss_palette_flash_dec
        sec
        lda     ent_x_vel_sub,x
        eor     #$03
        clc
        adc     #$03
        jmp     boss_palette_flash
boss_palette_flash_data:  .byte   $0F,$2C,$10,$1C,$0F,$37,$27,$07 ; palette flash color cycle data
        .byte   $0F,$28,$16,$07,$0F,$1C,$00,$0C
        .byte   $0F,$37,$27,$08,$0F,$17,$06,$08
        .byte   $0F,$0C,$0C,$0F,$0F,$37,$27,$08
        .byte   $0F,$07,$07,$08,$0F,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
        .byte   $0F,$16,$07,$08,$0F,$37,$27,$08
        .byte   $0F,$07,$07,$08,$0F,$26,$16,$06
        .byte   $0F,$37,$27,$08,$0F,$17,$06,$08
        .byte   $0F,$36,$26,$16,$0F,$37,$27,$07
        .byte   $0F,$27,$16,$07
; --- gear_ai -- Gear spinning platform (type $29) — spawns Pierrobot child, phase transition ---
gear_ai:
        lda     $0110,x
        bne     wily_machine_ai_entry
        inc     ent_state,x
        lda     ent_state,x
        cmp     #$3E
        bne     wily_machine_physics
        lda     #ENTITY_PIERROBOT
        jsr     spawn_entity_from_parent
        bcs     wily_machine_physics
        lda     #$08
        sta     ent_y_spawn_px,y
        lda     current_entity_slot
        sta     $0120,y
        tya
        sta     $0110,x
        lda     #$00
        sta     ent_state,x

; =============================================================================
; wily_machine_physics -- Boss AI: Wily Machine — turret spawn, physics ($A653)
; =============================================================================
wily_machine_physics:  jsr     apply_entity_physics_alt
        rts

wily_machine_ai_entry:
        ldy     $0110,x
        cpy     #$FF
        beq     wily_capsule_collision
        lda     ent_state,x
        cmp     #$04
        bcs     wily_capsule_attack
        sec
        lda     ent_y_px,x
        sbc     ent_y_spawn_px,y
        cmp     #$20
        bcs     wily_machine_physics
        lda     #$D4
        sta     $0670,y
        lda     #$02
        sta     $0650,y
        inc     ent_state,x
        lda     ent_state,x
        cmp     #$04
        bne     wily_machine_physics
        lda     #$87
        sta     ent_flags,x

; =============================================================================
; wily_capsule_attack -- Boss AI: Wily Capsule — attack, collision, bounce physics ($A689)
; =============================================================================
wily_capsule_attack:  sec
        lda     ent_y_px,x
        sbc     #$20
        sta     ent_y_spawn_px,y
        lda     ent_x_px,x
        sta     ent_x_spawn_px,y
        lda     ent_x_screen,x
        sta     ent_x_spawn_scr,y
        lda     #$00
        sta     $0650,y
wily_capsule_collision:  lda     #$0F
        sta     temp_01
        lda     #$0E
        sta     temp_02
        jsr     check_horiz_tile_collision
        lda     ent_state,x
        cmp     #$04
        bne     wily_capsule_check_bounce
        lda     temp_00
        beq     wily_capsule_check_bounce
        jsr     entity_face_player
        lda     #$47
        sta     ent_x_vel_sub,x
        lda     #$01
        sta     ent_x_vel,x
        inc     ent_state,x
wily_capsule_check_bounce:  lda     temp_03
        beq     wily_capsule_physics
        lda     ent_flags,x
        eor     #$40
        sta     ent_flags,x
wily_capsule_physics:  jsr     apply_entity_physics
        bcc     wily_capsule_rts
        ldy     $0110,x
        cpy     #$FF
        beq     wily_capsule_rts
        lda     #$FF
        sta     $0120,y
        lda     #$D4
        sta     $0670,y
        lda     #$02
        sta     $0650,y
wily_capsule_rts:  rts

pierrobot_ai:
        jsr     apply_entity_physics
        bcc     pierrobot_ai_rts
        ldy     $0110,x
        cpy     #$FF
        beq     pierrobot_ai_rts
        lda     #$00
        sta     ent_x_vel,y
        lda     #$A3
        sta     ent_x_vel_sub,y
        lda     #$FF
        sta     $0110,y
pierrobot_ai_rts:
        rts

; --- fly_boy_spawn_ai -- Fly Boy spawner (type $2B) — spawns Fly Boy child on timer ---
fly_boy_spawn_ai:
        lda     ent_state,x
        bne     wily_capsule_dec_timer
        lda     #$02
        sta     temp_01
        lda     #ENTITY_FLY_BOY
        jsr     find_entity_count_check
        bcs     wily_capsule_set_timer
        lda     #ENTITY_FLY_BOY
        jsr     spawn_entity_from_parent
wily_capsule_set_timer:
        lda     #$7D
        sta     ent_state,x
wily_capsule_dec_timer:
        dec     ent_state,x
        jsr     apply_entity_physics_alt
        rts

fly_boy_ai:
        lda     $0110,x
        bne     angler_phase_check
        inc     $0110,x
angler_phase_check:
        lda     $0110,x
        cmp     #$02
        bcs     angler_check_bite_state
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        lda     #$08
        sta     temp_01
        lda     #$14
        sta     temp_02
        lda     ent_y_vel,x
        php
        jsr     check_horiz_tile_collision
        plp
        bpl     angler_physics
        lda     temp_00
        beq     angler_physics
        lda     #$39
        jsr     bank_switch_enqueue
        lda     #$00
        sta     ent_y_vel,x
        sta     ent_y_vel_sub,x
        sta     ent_x_vel,x
        sta     ent_x_vel_sub,x
        lda     ent_flags,x
        and     #$FB
        sta     ent_flags,x
        inc     $0110,x
angler_check_bite_state:  lda     $0110,x
        cmp     #$02
        bne     angler_check_anim
        lda     ent_anim_id,x
        cmp     #$09
        bne     angler_physics
        lda     #$E5
        sta     ent_y_vel_sub,x
        lda     #$47
        sta     ent_state,x
        inc     $0110,x
angler_check_anim:  lda     ent_anim_id,x
        cmp     #$0B
        bne     angler_dec_timer
        lda     #$09
        sta     ent_anim_id,x
angler_dec_timer:  dec     ent_state,x
        bne     angler_physics
        lda     #$87
        sta     ent_flags,x
        jsr     entity_face_player
        lda     #$00
        asl     temp_00
        rol     a
        asl     temp_00
        rol     a
        asl     temp_00
        rol     a
        sta     ent_x_vel,x
        lda     temp_00
        sta     ent_x_vel_sub,x
        lda     #$03
        sta     ent_y_vel,x
        lda     #$76
        sta     ent_y_vel_sub,x
        lda     #$01
        sta     $0110,x
angler_physics:  jsr     apply_entity_physics
        rts

entity_init_timer_long:
        lda     #$08
        bne     entity_store_timer
entity_init_timer_short:
        lda     #$01
entity_store_timer:
        sta     ent_state,x
        lda     ent_x_px,x
        and     ent_x_vel,x
        sta     ent_y_vel,x
        lda     ent_y_px,x
        and     ent_x_vel_sub,x
        sta     ent_y_vel_sub,x
        jsr     apply_simple_physics
        rts

press_ai:
        lda     $0110,x
        bne     mecha_dragon_tile_check
        jsr     entity_face_player
        lda     temp_00
        cmp     #$28
        bcs     mecha_dragon_apply_physics
        lda     #$87
        sta     ent_flags,x
        lda     #$FF
        sta     ent_y_vel,x
        lda     #$C0
        sta     ent_y_vel_sub,x
        inc     $0110,x
mecha_dragon_apply_physics:
        jsr     apply_entity_physics_alt
        rts

mecha_dragon_tile_check:
        lda     #$08
        sta     temp_01
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     $0110,x
        cmp     #$02
        bcs     mecha_dragon_check_landed
        lda     temp_00
        beq     mecha_dragon_physics_2
        lda     #$21
        jsr     bank_switch_enqueue
        lda     #$2B
        sta     ent_state,x
        inc     $0110,x
        lda     #ENTITY_PRESS_RETRACT
        jsr     spawn_entity_from_parent
        sec
        lda     ent_y_spawn_px,y
        sbc     #$28
        sta     ent_y_spawn_px,y
        lda     #$2B
        sta     $04F0,y
        bne     mecha_dragon_physics_2
mecha_dragon_check_landed:  lda     ent_state,x
        beq     mecha_dragon_check_wall
        dec     ent_state,x
        bne     mecha_dragon_physics_2
        lda     #$00
        sta     ent_y_vel,x
        lda     #$62
        sta     ent_y_vel_sub,x
        lda     #$83
        sta     ent_flags,x
        bne     mecha_dragon_physics_2
mecha_dragon_check_wall:  lda     temp_00
        beq     mecha_dragon_physics_2
        lda     #$00
        sta     ent_y_vel_sub,x
        sta     $0110,x
mecha_dragon_physics_2:  jsr     apply_entity_physics
        rts

; =============================================================================
; mecha_dragon_fire -- Boss AI: Mecha Dragon — fire breath, walk, debris spawn ($A877)
; Spawns entity $33 (fireball, reused for debris).
; =============================================================================
mecha_dragon_fire:  lda     #$07
        sta     temp_01
        lda     #$08
        sta     temp_02
        jsr     check_horiz_tile_collision
        lda     ent_anim_id,x
        cmp     #$0F
        bne     mecha_dragon_check_timer
        lda     #$0E
        sta     ent_anim_id,x
mecha_dragon_check_timer:  lda     ent_state,x
        beq     mecha_dragon_check_state
        dec     ent_state,x
        bne     mecha_dragon_check_state
        lda     #$02
        sta     temp_01
mecha_dragon_spawn_fire:  lda     #ENTITY_MECHA_FIRE
        jsr     spawn_entity_from_parent
        bcs     mecha_dragon_fire_done
        lda     #$E0
        sta     ent_y_spawn_px,y
        lda     #$A8
        sta     ent_spawn_flags,y
        ldx     temp_01
        lda     mecha_dragon_fire_timer,x
        sta     $04F0,y
        ldx     current_entity_slot
        txa
        sta     $0120,y
        dec     temp_01
        bpl     mecha_dragon_spawn_fire
mecha_dragon_fire_done:  ldx     current_entity_slot
mecha_dragon_check_state:  lda     $0110,x
        cmp     #$04
        bne     mecha_dragon_physics
        sec
        lda     ent_y_px,x
        sbc     #$20
        sta     ent_y_px,x
        lda     #$87
        sta     ent_flags,x
        lda     #$41
        sta     ent_x_vel_sub,x
        lda     #$00
        sta     ent_anim_frame,x
        sta     ent_anim_id,x
        sta     $0110,x
mecha_dragon_physics:  jsr     apply_entity_physics
        rts

; --- blocky_ai -- Blocky block enemy (type $31) — tile collision, split animation, face player ---
blocky_ai:
        lda     $0110,x
        bne     mecha_dragon_check_walk
        lda     #ENTITY_BLOCKY_PHASE2
        jsr     spawn_entity_from_parent
        txa
        sta     $04F0,y
        inc     $0110,x
mecha_dragon_check_walk:
        lda     ent_flags,x
        and     #$08
        beq     mecha_dragon_walk
        jmp     mecha_dragon_fire

mecha_dragon_walk:  lda     #$07
        sta     temp_01
        lda     #$28
        sta     temp_02
        sec
        lda     ent_x_px,x
        sbc     #$07
        sta     jump_ptr
        lda     ent_x_screen,x
        sbc     #$00
        sta     jump_ptr_hi
        clc
        lda     #$00
        sta     $0B
        lda     ent_y_px,x
        adc     #$20
        sta     $0A
        jsr     lookup_tile_from_map
        ldx     current_entity_slot
        ldy     temp_00
        beq     mecha_dragon_collision
        lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     ent_x_px,x
        sta     ent_x_px,x
mecha_dragon_store_screen:  lda     ent_x_screen,x
        adc     #$00
        sta     ent_x_screen,x
mecha_dragon_collision:  jsr     check_vert_tile_collision
        lda     ent_anim_id,x
        cmp     #$0C
        bne     mecha_dragon_check_hit
        lda     #$00
        sta     ent_anim_id,x
mecha_dragon_check_hit:  jsr     apply_entity_physics
        bcs     mecha_dragon_rts
        lda     $0100,x
        beq     mecha_dragon_rts
        lda     #$0D
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_anim_frame,x
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
        lda     #$7E
        sta     ent_state,x
        jsr     entity_face_player
        lda     #$02
        sta     temp_01
mecha_dragon_spawn_debris:  lda     #ENTITY_MECHA_FIRE     ; spawn fireball (reused as debris)
        jsr     spawn_entity_from_parent
        bcs     mecha_dragon_debris_done
        ldx     temp_01
        clc
        lda     ent_y_spawn_px,y
        adc     mecha_dragon_debris_y_off,x
        sta     ent_y_spawn_px,y
        lda     mecha_dragon_debris_vel_hi,x
        sta     $0610,y
        lda     mecha_dragon_debris_vel_lo,x
        sta     $0630,y
        lda     #$04
        sta     $0650,y
        lda     #$00
        sta     $0670,y
        lda     #$FF
        sta     $0120,y
mecha_dragon_debris_loop_end:  ldx     current_entity_slot
        dec     temp_01
        bpl     mecha_dragon_spawn_debris
mecha_dragon_debris_done:  ldx     current_entity_slot
        lda     #$8F
        sta     ent_flags,x
mecha_dragon_rts:  rts

mecha_dragon_debris_y_off:  .byte   $F0,$10,$20 ; Mecha Dragon debris Y offset
mecha_dragon_debris_vel_hi:  .byte   $03,$02,$01 ; debris X velocity (high byte)
mecha_dragon_debris_vel_lo:  .byte   $00,$40,$00 ; debris X velocity (low byte)
mecha_dragon_fire_timer:  .byte   $01,$06,$0B ; fire attack cooldown timers
        ldy     ent_state,x           ; Guts Tank AI entry
        lda     ent_flags,y
        bpl     guts_tank_deactivate
        and     #$08
        beq     guts_tank_track_parent
guts_tank_deactivate:  lsr     ent_flags,x
        rts

guts_tank_track_parent:  lda     ent_x_px,y
        sta     ent_x_px,x
        lda     ent_x_screen,y
        sta     ent_x_screen,x
        clc
        lda     ent_y_px,y
        adc     #$08
        sta     ent_y_px,x
        jsr     apply_entity_physics_alt
        rts

        ldy     $0110,x
        bpl     picopico_check_timer
        lda     #$07
        sta     temp_01
        lda     #$08
        sta     temp_02
        jsr     check_horiz_tile_collision
        lda     temp_00
        beq     picopico_physics
        lda     ent_state,x
        beq     picopico_stop_movement
        lda     #$00
        sta     $4E
        jmp     apply_collision_physics

; =============================================================================
; picopico_stop_movement -- Boss AI: Picopico-kun — bouncing block enemy, shot spawn ($AA0C)
; Spawns entity $35 (projectile, shared type with Neo Metall bullet).
; =============================================================================
picopico_stop_movement:  lda     #$00
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
        sta     ent_y_vel_sub,x
        lda     #$02
        sta     ent_y_vel,x
        inc     ent_state,x
        bne     picopico_physics
picopico_check_timer:  lda     ent_state,x
        beq     picopico_check_player
        dec     ent_state,x                 ; decrement AI timer
        bne     picopico_physics
        lda     #$8B
        sta     ent_flags,x
        lda     #$04
        sta     ent_y_vel,x
picopico_check_player:  lda     ent_y_px,x
        cmp     ent_y_px,y
        bcs     picopico_physics
        clc
        lda     $0110,y
        adc     #$01
        sta     $0110,y
        lsr     ent_flags,x
        rts

picopico_physics:  jsr     apply_entity_physics
        rts

        lda     current_stage                   ; check if Wily stage 3 (Guts-Dozer)
        cmp     #$0A
        bne     picopico_begin_hitbox
        jmp     picopico_wily3_entry  ; alternate AI for Wily 3
picopico_begin_hitbox:
        ldy     #$08
        lda     ent_anim_id,x
        cmp     #$03
        bcc     picopico_set_hitbox
        ldy     #$10
picopico_set_hitbox:  sty     temp_02
        lda     #$07
        sta     temp_01
        jsr     check_horiz_tile_collision
        lda     $0110,x
        bne     picopico_state_1
        jsr     entity_face_player
        lda     temp_00
        cmp     #$40
        bcs     picopico_clear_anim
        lda     ent_state,x
        bne     picopico_dec_main_timer
        inc     ent_anim_id,x
        inc     $0110,x
        lda     ent_flags,x
        and     #$F7
        sta     ent_flags,x
        lda     #$3E
        sta     ent_state,x
        bne     picopico_jmp_physics
picopico_dec_main_timer:  dec     ent_state,x
picopico_clear_anim:  lda     #$00
        sta     ent_anim_frame,x
        sta     ent_anim_id,x
picopico_jmp_physics:  jmp     picopico_apply_physics

picopico_state_1:  cmp     #$02
        bcs     picopico_state_2_timer
        lda     ent_anim_id,x
        cmp     #$02
        bne     picopico_dec_timer
        lda     #$25
        jsr     bank_switch_enqueue
        lda     #$02
        sta     temp_01
picopico_spawn_shot:  lda     #ENTITY_GENERIC_PROJ
        jsr     spawn_entity_from_parent ; spawn projectile
        bcs     picopico_advance_state
        ldx     temp_01
        lda     picopico_shot_vel_y_sub,x
        sta     $0670,y
        lda     picopico_shot_vel_y_hi,x
        sta     $0650,y
        lda     picopico_shot_vel_x_sub,x
        sta     $0630,y
        lda     picopico_shot_vel_x_hi,x
        sta     $0610,y
        ldx     current_entity_slot
        dec     temp_01
        bpl     picopico_spawn_shot
picopico_advance_state:  lda     #$03
        sta     ent_anim_id,x
        sec
        lda     ent_y_px,x
        sbc     #$08
        sta     ent_y_px,x
picopico_dec_timer:  dec     ent_state,x
        bne     picopico_check_anim
        jsr     entity_face_player
        lda     #$02
        sta     ent_x_vel,x
        lda     #$14
        sta     ent_state,x
        inc     $0110,x
        bne     picopico_check_anim
picopico_state_2_timer:  dec     ent_state,x
        bne     picopico_check_anim
        lda     #$00
        sta     ent_x_vel,x
        sta     ent_anim_id,x
        sta     $0110,x
        lda     rng_seed
        and     #$03
        tay
        lda     picopico_random_timer,y
        sta     ent_state,x
        lda     ent_flags,x
        ora     #$08
        sta     ent_flags,x
picopico_check_anim:  lda     ent_anim_id,x
        cmp     #$05
        bne     picopico_apply_physics
        lda     #$03
        sta     ent_anim_id,x
picopico_apply_physics:  jsr     apply_entity_physics
        rts

picopico_random_timer:  .byte   $1F,$3E,$9B,$1F
picopico_shot_vel_y_sub:  .byte   $25,$00,$DB ; Picopico shot Y velocity (sub-pixel)
picopico_shot_vel_y_hi:  .byte   $01,$00,$FE
picopico_shot_vel_x_sub:  .byte   $A3,$00,$A3 ; Picopico shot X velocity (sub-pixel)
picopico_shot_vel_x_hi:  .byte   $01,$02,$01
picopico_wily3_entry:
        lda     ent_state,x
        bne     buebeam_collision
        lda     ent_y_px,x
        cmp     #$80
        bcc     buebeam_check_anim
        inc     ent_state,x
        lda     #$03
        sta     ent_y_vel,x
buebeam_collision:  lda     #$08
        sta     temp_01
        lda     #$10
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     temp_00
        beq     buebeam_check_anim
        lda     #$FF
        sta     ent_y_vel,x
        lda     #$01
        sta     ent_x_vel,x
        lda     #$00
        sta     ent_y_vel_sub,x
        sta     ent_x_vel_sub,x
buebeam_check_anim:  lda     ent_anim_id,x
        cmp     #$05
        bne     buebeam_physics
        lda     #$03
        sta     ent_anim_id,x
buebeam_physics:  jsr     apply_entity_physics
        rts

; =============================================================================
; matasaburo_wind_push -- Enemy AI: Matasaburo (Fan Fiend) — wind push effect ($AB89)
; Entity type $36. Air Man stage only. Pushes player backward with wind.
; =============================================================================
matasaburo_wind_push:
        sec
        lda     $2D
        sbc     $2E
        bcs     matasaburo_apply_physics
        lda     #$01
        sta     $40
        lda     #$00
        sta     $AF
        lda     #$A3
        sta     $4F
        lda     #$00
        sta     $50
matasaburo_apply_physics:
        jsr     apply_entity_physics_alt
        rts

; Entity AI subroutine — collision check, entity $37 parameter ($ABA4)
pipi_spawn_ai:
        lda     ent_x_vel_sub,x
        bne     boobeam_init
        lda     #ENTITY_PIPI_SPAWN
        jsr     check_entity_collision_scan
        bcc     boobeam_init
        rts

; =============================================================================
; boobeam_init -- Boss AI: Boobeam Trap — turret initialization and firing ($ABB1)
; =============================================================================
boobeam_init:  lda     ent_x_px
        sta     ent_x_px,x
        lda     ent_x_screen
        sta     ent_x_screen,x
        lda     ent_state,x
        bne     boobeam_dec_timer
        lda     #$BB
        sta     ent_state,x
        lda     #$01
        sta     temp_01
        lda     #ENTITY_PIPI
        jsr     find_entity_count_check
        bcs     boobeam_dec_timer
        lda     #$02
        sta     temp_01
        lda     #ENTITY_COPIPI
        jsr     find_entity_count_check
        bcs     boobeam_dec_timer
        lda     #ENTITY_PIPI
        jsr     spawn_entity_from_parent
        bcs     boobeam_dec_timer
        ldx     #$00
        lda     ent_flags
        and     #$40
        bne     boobeam_set_direction
        inx
boobeam_set_direction:  lda     boobeam_dir_flags_table,x
        sta     ent_spawn_flags,y
        clc
        lda     scroll_x
        adc     boobeam_x_offset_table,x
        sta     ent_x_spawn_px,y
        lda     nametable_select
        adc     #$00
        sta     ent_x_spawn_scr,y
boobeam_dec_timer:  ldx     current_entity_slot
        dec     ent_state,x
        rts

boobeam_x_offset_table:  .byte   $F8,$08 ; Boobeam turret X offset per slot
boobeam_dir_flags_table:  .byte   $83,$C3 ; Boobeam shot direction flags
entity_shift_flags:
        lsr     ent_flags,x
        rts

; --- pipi_ai -- Pipi flying bird (type $38) — horizontal flight, drops egg on proximity ---
pipi_ai:
        lda     $0110,x
        bne     capsule_missile_check_timer
        lda     #ENTITY_PIPI_EGG
        jsr     spawn_entity_from_parent
        bcs     entity_shift_flags
        txa
        sta     $0120,y
        iny
        tya
        sta     $0110,x
capsule_missile_check_timer:
        lda     ent_state,x
        bne     capsule_missile_anim
        lda     ent_flags,x
        pha
        jsr     entity_face_player
        pla
        sta     ent_flags,x
        ldy     $0110,x
        dey
        clc
        lda     ent_y_px,x
        adc     #$10
        sta     ent_y_spawn_px,y
        lda     ent_x_px,x
        sta     ent_x_spawn_px,y
        lda     ent_x_screen,x
        sta     ent_x_spawn_scr,y
        lda     temp_00
        cmp     #$30
        bcc     capsule_missile_move
        lda     ent_anim_id,x
        cmp     #$02
        bne     capsule_missile_physics
        lda     #$00
        sta     ent_anim_id,x
        beq     capsule_missile_physics
capsule_missile_move:  lda     #$87
        sta     ent_spawn_flags,y
        inc     ent_state,x
        lda     #$02
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
capsule_missile_anim:  lda     ent_anim_id,x
        cmp     #$03
        bne     capsule_missile_physics
        lda     #$00
        sta     ent_anim_frame,x
capsule_missile_physics:  jsr     apply_entity_physics
        bcc     capsule_missile_rts
        ldy     $0110,x
        dey
        lda     #$00
        sta     ent_spawn_flags,y
capsule_missile_rts:  rts

; --- pipi_alt_ai -- Pipi alt spawner (type $39) — destroys all Pipi spawn entities via enemy_destroy_scan ---
pipi_alt_ai:
        lda     #ENTITY_PIPI_SPAWN
        sta     temp_00
        jmp     enemy_destroy_scan

pipi_egg_ai:
        lda     ent_flags,x
        and     #$04
        bne     boss_explode_tile_check
        jsr     apply_entity_physics_alt
        rts

boss_explode_tile_check:
        lda     #$07
        sta     temp_01
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     temp_00
        bne     boss_explode_start
        jsr     apply_entity_physics
        lda     temp_01
        bne     boss_explode_start
        rts

; =============================================================================
; boss_explode_start -- Boss Explosion — spawn debris ring on boss death ($ACB6)
; =============================================================================
boss_explode_start:  lda     #ENTITY_EGG_HATCH      ; spawn explosion flash effect
        jsr     spawn_entity_from_parent
        lda     #ENTITY_EGG_HATCH      ; spawn second flash
        jsr     spawn_entity_from_parent
        lda     #$C4
        sta     ent_spawn_flags,y
        lda     #$07
        sta     temp_01
boss_explode_spawn_loop:  lda     #ENTITY_COPIPI         ; spawn explosion debris
        jsr     spawn_entity_from_parent ; spawn debris piece
        bcs     boss_explode_deactivate
        ldx     temp_01
        lda     boss_explode_flags_table,x
        sta     ent_spawn_flags,y
        lda     boss_explode_vel_y_sub,x
        sta     $0670,y
        lda     boss_explode_vel_y_hi,x
        sta     $0650,y
        lda     boss_explode_vel_x_sub,x
        sta     $0630,y
        lda     boss_explode_vel_x_hi,x
        sta     $0610,y
        lda     boss_explode_timer_table,x
        sta     $04F0,y
        ldx     current_entity_slot
        dec     temp_01
        bpl     boss_explode_spawn_loop
boss_explode_deactivate:  lsr     ent_flags,x
        rts

boss_explode_flags_table:  .byte   $C3,$C3,$C3,$C3,$C3,$83,$83,$83 ; explosion entity flags per slot
boss_explode_vel_y_sub:  .byte   $96,$7B,$1E,$6A,$F0,$00,$E6,$9E ; explosion Y velocity (sub-pixel)
boss_explode_vel_y_hi:  .byte   $FE,$00,$01,$01,$01,$02,$01,$00
boss_explode_vel_x_sub:  .byte   $6A,$F0,$A8,$6A,$7B,$00,$9E,$E6 ; explosion X velocity (sub-pixel)
boss_explode_vel_x_hi:  .byte   $01,$01,$01,$01,$00,$00,$00,$01
boss_explode_timer_table:  .byte   $0B,$21,$1C,$0B,$21,$10,$19,$19

copipi_ai:
        lda     $0110,x
        bne     boss_explode_apply_physics
        dec     ent_state,x
        bne     boss_explode_apply_physics
        lda     #$47
        sta     jump_ptr
        lda     #$01
        sta     jump_ptr_hi
        jsr     calc_entity_velocity
        inc     $0110,x
boss_explode_apply_physics:
        jsr     apply_entity_physics
        rts

kaminari_child_ai:
        ldy     $0110,x
        lda     ent_flags,y
        bpl     multi_boss_deactivate
        lda     ent_type,y
        cmp     #$3E
        bne     multi_boss_deactivate
        sec
        lda     ent_y_px,y
        sbc     #$14
        sta     ent_y_px,x
        lda     ent_x_px,y
        sta     ent_x_px,x
        lda     ent_x_screen,y
        sta     ent_x_screen,x
        jsr     entity_face_player
        inc     ent_state,x
        lda     ent_state,x
        cmp     #$9D
        bne     multi_boss_anim_check
        lda     #ENTITY_KAMINARI_BOLT
        jsr     spawn_entity_from_parent
        lda     #$03
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_anim_frame,x
        sta     ent_state,x
multi_boss_anim_check:
        lda     ent_anim_id,x
        cmp     #$02
        bne     multi_boss_child_physics
        lda     #$00
        sta     ent_anim_id,x
multi_boss_child_physics:
        jsr     apply_entity_physics
        rts

multi_boss_deactivate:
        lsr     ent_flags,x
        rts

; --- kaminari_goro_ai -- Kaminari Goro (type $3E) — spawns child, circular shot pattern on timer ---
kaminari_goro_ai:
        lda     #$18
        sta     $0150,x
        lda     ent_x_vel_sub,x
        ora     ent_y_vel_sub,x
        bne     circular_shot_timer_check
        lda     #ENTITY_KAMINARI_CHILD
        jsr     spawn_entity_from_parent
        bcs     circular_shot_timer_check
        txa
        sta     $0120,y
        sec
        lda     ent_y_px,x
        sbc     #$14
        sta     ent_y_spawn_px,y
circular_shot_timer_check:
        lda     ent_state,x
        bne     circular_shot_dec_timer
        lda     $0110,x
        and     #$0F
        tay
        clc
        adc     #$01
        sta     $0110,x
        lda     circular_vel_y_sub_table,y
        sta     ent_y_vel_sub,x
        lda     circular_vel_y_hi_table,y
        sta     ent_y_vel,x
        lda     circular_vel_x_sub_table,y
        sta     ent_x_vel_sub,x
        lda     circular_flags_table,y
        sta     ent_flags,x
        lda     #$2A
        sta     ent_state,x
circular_shot_dec_timer:  dec     ent_state,x
        jsr     apply_entity_physics
        bcc     circular_shot_set_hitbox
        lda     #$00
        sta     $0150,x
circular_shot_set_hitbox:  sec
        lda     ent_y_px,x
        sbc     #$08
        sta     $0160,x
        rts

circular_vel_y_sub_table:  .byte   $00,$CE,$A4,$87,$75,$87,$A4,$CE ; circular shot Y velocity table
        .byte   $00,$32,$5C,$79,$8B,$79,$5C,$32
circular_vel_y_hi_table:  .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
circular_vel_x_sub_table:  .byte   $8B,$79,$5C,$32,$00,$32,$5C,$79 ; circular shot X velocity table
        .byte   $8B,$79,$5C,$32,$00,$32,$5C,$79
circular_flags_table:  .byte   $80,$80,$80,$80,$C0,$C0,$C0,$C0 ; circular shot direction flags
        .byte   $C0,$C0,$C0,$C0,$80,$80,$80,$80
goblin_ai_init:
        jsr     entity_face_player
        sec
        lda     ent_type,x
        sbc     #$40
        tay
        lda     goblin_palette_index_table,y
        sta     temp_01
        lda     ent_flags,x
        and     #$20
        beq     goblin_check_phase
        ldy     temp_01
        lda     #$15
        cmp     $0358,y
        bne     goblin_check_distance
        lda     #$04
        sta     ent_x_vel_sub,x
        bne     goblin_set_active
goblin_check_distance:
        lda     temp_00
        cmp     #$60
        bcs     goblin_jump_physics
goblin_set_active:
        lda     #$82
        sta     ent_flags,x
goblin_check_phase:
        lda     ent_x_vel_sub,x
        cmp     #$04
        bcs     goblin_check_fire
        lda     ent_state,x
        and     #$03
        bne     goblin_jump_physics
        sta     ent_state,x
        lda     ent_x_vel_sub,x
        inc     ent_x_vel_sub,x
        asl     a
        asl     a
        tay
        ldx     temp_01
        jsr     goblin_set_palette
        ldx     current_entity_slot

; =============================================================================
; goblin_jump_physics -- Goblin AI: jump physics, timer increment ($AE9B)
; Parent AI spawns $44 (horn) and $45 (Petit Goblin).
; =============================================================================
goblin_jump_physics:  jmp     goblin_inc_timer

; --- goblin_check_fire -- Goblin fire check — spawns Petit Goblins when close, horns on descent ---
goblin_check_fire:  lda     temp_00
        cmp     #$28
        bcs     goblin_check_descent
        lda     ent_state,x
        and     #$3F
        bne     goblin_check_descent
        lda     #$03
        sta     temp_01
        lda     #ENTITY_PETIT_GOBLIN
        jsr     find_entity_count_check
        bcs     goblin_check_descent
        lda     #ENTITY_PETIT_GOBLIN   ; spawn Petit Goblin
        jsr     spawn_entity_from_parent
        bcs     goblin_check_descent
        lda     ent_x_vel,x
        and     #$01
        tax
        lda     goblin_horn_flags_table,x
        sta     ent_spawn_flags,y
        clc
        lda     ent_y_spawn_px,y
        adc     #$03
        sta     ent_y_spawn_px,y
        clc
        lda     ent_x_spawn_px,y
        adc     goblin_horn_x_offset_lo,x
        sta     ent_x_spawn_px,y
        lda     ent_x_spawn_scr,y
        adc     goblin_horn_x_offset_hi,x
        sta     ent_x_spawn_scr,y
        lda     #$3F
        sta     $04F0,y
        ldx     current_entity_slot
        inc     ent_x_vel,x
goblin_check_descent:  lda     ent_y_vel_sub,x
        ora     ent_y_vel,x
        bne     goblin_hover_dec
        lda     #$01
        sta     temp_01
goblin_spawn_horn_loop:  lda     #ENTITY_GOBLIN_HORN    ; spawn Goblin horn
        jsr     spawn_entity_from_parent
        bcs     goblin_set_hover_timer
        lda     ent_y_spawn_px,y
        sbc     #$24
        sta     ent_y_spawn_px,y
        ldx     temp_01
        clc
        lda     ent_x_spawn_px,y
        adc     goblin_horn_x_offset_lo,x
        sta     ent_x_spawn_px,y
        lda     ent_x_spawn_scr,y
        adc     goblin_horn_x_offset_hi,x
        sta     ent_x_spawn_scr,y
        lda     #$78
        sta     $04F0,y
        ldx     current_entity_slot
        dec     temp_01
        bpl     goblin_spawn_horn_loop
goblin_set_hover_timer:  lda     #$48
        sta     ent_y_vel_sub,x
        lda     #$01
        sta     ent_y_vel,x
goblin_hover_dec:  sec
        lda     ent_y_vel_sub,x
        sbc     #$01
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        sbc     #$00
        sta     ent_y_vel,x
goblin_inc_timer:  inc     ent_state,x
        jsr     apply_entity_physics_alt
        rts

goblin_set_palette:  lda     #$03
        sta     temp_02
goblin_palette_copy_loop:  lda     goblin_palette_data,y
        sta     palette_ram,x                 ; write alien palette
        sta     $0376,x
        sta     $0386,x
        sta     $0396,x
        sta     $03A6,x
        iny
        inx
        dec     temp_02
        bpl     goblin_palette_copy_loop
        rts

goblin_palette_data:  .byte   $0F,$21,$21,$21,$0F,$31,$35,$21 ; Goblin palette cycle data
        .byte   $0F,$30,$25,$10,$0F,$30,$15,$0F
goblin_palette_index_table:  .byte   $08,$0C ; palette subgroup index per boss type
goblin_horn_flags_table:  .byte   $C3,$83 ; Goblin horn direction flags
goblin_horn_x_offset_lo:  .byte   $1D,$E3
goblin_horn_x_offset_hi:  .byte   $00,$FF
; --- goblin_cleanup_ai -- Goblin cleanup (types $42/$43): deactivate + set palette ($AF81) ---
goblin_cleanup_ai:
        lsr     ent_flags,x
        lda     #$FF
        sta     $0120,x
        ldy     $0110,x
        lda     #$00
        sta     $0140,y
        sec
        lda     ent_type,x
        sbc     #$42
        tay
        ldx     goblin_palette_index_table,y
        ldy     #$00
        jsr     goblin_set_palette
        rts
; --- goblin_horn_ai -- Goblin horn (type $44): phase/timer check ($AFA1) ---
goblin_horn_ai:
        lda     ent_state,x
        bne     turret_dec_timer
        lda     $0110,x
        cmp     #$01
        bcs     goblin_horn_check_deactivate
        lda     #$3E
        sta     ent_state,x
        lda     #$00
        sta     ent_y_vel,x
        sta     ent_y_vel_sub,x
        inc     $0110,x
        bne     turret_dec_timer
goblin_horn_check_deactivate:
        bne     turret_deactivate
        lda     #$C0
        sta     ent_y_vel_sub,x
        lda     #$FE
        sta     ent_y_vel,x
        lda     #$0B
        sta     ent_state,x
        inc     $0110,x
        bne     turret_dec_timer
turret_deactivate:  lsr     ent_flags,x
        rts

turret_dec_timer:  dec     ent_state,x
        jsr     apply_entity_physics
        rts

petit_goblin_ai:
        lda     $0110,x
        cmp     #$02
        bne     drop_boss_active
        jmp     telly_ai
drop_boss_active:
        lda     ent_state,x
        bne     drop_boss_dec_timer
        lda     $0110,x
        bne     drop_boss_advance
        lda     #$1A
        sta     ent_state,x
        lda     #$00
        sta     ent_x_vel,x
        sta     ent_x_vel_sub,x
        lda     #$03
        sta     ent_y_vel,x
        lda     #$33
        sta     ent_y_vel_sub,x
        inc     $0110,x
        bne     drop_boss_dec_timer
drop_boss_advance:  inc     $0110,x
        rts

drop_boss_dec_timer:  dec     ent_state,x
        jsr     apply_entity_physics
        rts

; =============================================================================
; springer_ai -- Enemy AI: Scworm — pipe worm, tile-check movement ($B01B)
; =============================================================================
springer_ai:
        lda     $0110,x
        beq     scworm_tile_check
        jmp     scworm_anim

scworm_tile_check:
        ldy     #$00
        sty     $0B
        lda     ent_flags,x
        and     #$40
        bne     scworm_calc_tile
        iny
scworm_calc_tile:  clc
        lda     ent_x_px,x
        adc     scworm_x_offset_table,y
        sta     jump_ptr
        lda     ent_x_screen,x
        adc     scworm_x_page_table,y
        sta     jump_ptr_hi
        clc
        lda     ent_y_px,x
        adc     #$09
        sta     $0A
        jsr     lookup_tile_from_map
        ldx     current_entity_slot
        lda     temp_00
        beq     scworm_flip
        lda     ent_y_px,x
        sta     $0A
        jsr     lookup_tile_from_map
        ldx     current_entity_slot
        lda     temp_00
        beq     scworm_set_speed
scworm_flip:  lda     ent_flags,x
        eor     #$40                    ; flip facing direction
        sta     ent_flags,x
scworm_set_speed:  lda     #$00
        sta     ent_x_vel,x
        lda     #$41
        sta     ent_x_vel_sub,x
        sec
        lda     ent_y_px
        sbc     ent_y_px,x
        bcs     scworm_check_dist
        eor     #$FF
        adc     #$01
scworm_check_dist:  cmp     #$05
        bcs     scworm_resume
        lda     #$00
        sta     ent_x_vel_sub,x
        lda     #$02
        sta     ent_x_vel,x
        lda     ent_flags,x
        pha
        jsr     entity_face_player
        pla
        sta     ent_flags,x
        lda     temp_00
        cmp     #$11
        bcs     scworm_resume
        lda     #$01
        sta     ent_anim_id,x
        sec
        lda     ent_y_px,x
        sbc     #$08
        sta     ent_y_px,x
        lda     #$70
        sta     ent_state,x
        lda     ent_flags,x
        and     #$F7
        sta     ent_flags,x
        inc     $0110,x
        bne     scworm_anim
scworm_resume:  lda     #$00
        sta     ent_anim_id,x
        lda     #$07
        sta     $06E0,x
        jsr     apply_entity_physics
        rts

scworm_anim:  lda     ent_anim_id,x
        cmp     #$05
        bne     scworm_set_speed_val
        lda     #$01
        sta     ent_anim_id,x
scworm_set_speed_val:  lda     #$09
        sta     $06E0,x
        dec     ent_state,x
        bne     scworm_physics
        dec     $0110,x
        lda     #$00
        sta     ent_anim_id,x
        clc
        lda     ent_y_px,x
        adc     #$08
        sta     ent_y_px,x
scworm_physics:  jsr     apply_entity_physics_alt
        rts

scworm_x_offset_table:  .byte   $08,$F8 ; Scworm X check offset
scworm_x_page_table:  .byte   $00,$FF,$BD,$20,$06,$D0,$08,$A9
        .byte   $47,$20,$B5,$95,$90,$01,$60
        lda     ent_x_px
        sta     ent_x_px,x
        lda     ent_x_screen
        sta     ent_x_screen,x
        lda     ent_state,x
        bne     mole_done
        lda     #$3E
        sta     ent_state,x
        lda     #$06
        sta     temp_01
        lda     #ENTITY_JOE_BULLET_B
        jsr     find_entity_count_check
        lda     #ENTITY_JOE_BULLET_A
        jsr     find_entity_count_check
        bcs     mole_done
        lda     ent_x_vel,x
        asl     a
        sta     temp_01
        lda     #$02
        sta     temp_02

; =============================================================================
; mole_spawn_shot -- Enemy AI: Mole controller (type $47) — spawn shot children ($B137)
; Spawns entities $49/$48 (Mole projectiles) from mole_shot_type_table.
; =============================================================================
mole_spawn_shot:  ldy     temp_01
        lda     mole_shot_type_table,y
        jsr     spawn_entity_from_parent ; spawn bullet
        bcs     mole_done
        ldx     temp_01
        clc
        lda     ent_x_spawn_px,y
        adc     mole_shot_x_offset,x
        sta     ent_x_spawn_px,y
        lda     ent_x_spawn_scr,y
        adc     #$00
        sta     ent_x_spawn_scr,y
        lda     mole_shot_y_table,x
        sta     ent_y_spawn_px,y
        ldx     current_entity_slot
        inc     temp_01
        dec     temp_02
        bne     mole_spawn_shot
        inc     ent_x_vel,x
        lda     ent_x_vel,x
        cmp     #$03
        bne     mole_done
        lda     #$00
        sta     ent_x_vel,x
mole_done:  ldx     current_entity_slot
        dec     ent_state,x
        rts

mole_shot_type_table:  .byte   ENTITY_JOE_BULLET_A,ENTITY_JOE_BULLET_B,ENTITY_JOE_BULLET_A,ENTITY_JOE_BULLET_B,ENTITY_JOE_BULLET_A,ENTITY_JOE_BULLET_B
mole_shot_x_offset:  .byte   $18,$58,$50,$20,$28,$60 ; X offsets for Mole shot spawn

mole_shot_y_table:  .byte   $10,$D0,$10,$D0,$10,$D0 ; Mole shot Y-position lookup table
        lda     #$00
        sta     temp_01
        sec
        lda     ent_y_px,x
        sbc     #$0C
        jmp     sniper_joe_store_a

        lda     #$04
        sta     temp_01
        clc
        lda     ent_y_px,x
        adc     #$0C
sniper_joe_store_a:  sta     $0A
        lda     #$00
        sta     $0B
        lda     ent_x_px,x
        sta     jump_ptr
        lda     ent_x_screen,x
        sta     jump_ptr_hi
        jsr     lookup_tile_from_map
        ldx     current_entity_slot
        lda     $0110,x
        bne     sniper_joe_timer_check
        lda     temp_00
        bne     sniper_joe_physics
        ldy     temp_01
        lda     sniper_joe_vel_fwd,y
        sta     ent_y_vel_sub,x
        lda     sniper_joe_vel_hi_fwd,y
        sta     ent_y_vel,x
        inc     $0110,x
        lda     #$4B
        sta     ent_state,x
        bne     sniper_joe_physics
sniper_joe_timer_check:  ldy     temp_01
        lda     ent_state,x
        beq     sniper_joe_reverse
        dec     ent_state,x
        bne     sniper_joe_wall_check
sniper_joe_reverse:  lda     sniper_joe_vel_rev,y
        sta     ent_y_vel_sub,x
        lda     sniper_joe_vel_hi_rev,y
        sta     ent_y_vel,x
sniper_joe_wall_check:  lda     temp_00
        beq     sniper_joe_physics
        lda     sniper_joe_vel_fwd,y
        sta     ent_y_vel_sub,x
        lda     sniper_joe_vel_hi_fwd,y
        sta     ent_y_vel,x
sniper_joe_physics:  jsr     apply_entity_physics
        rts

sniper_joe_vel_fwd:  .byte   $41
sniper_joe_vel_rev:  .byte   $E5
sniper_joe_vel_hi_fwd:  .byte   $00
sniper_joe_vel_hi_rev:  .byte   $00
        .byte   $BF,$1B,$FF,$FF   ; unknown data bytes
mole_4a_ai:
        lda     #$47
        sta     temp_00
        jmp     enemy_destroy_scan
crazy_cannon_ai:
        lda     $0110,x
        beq     sniper_joe_boss_proj_init
        lda     ent_anim_id,x
        cmp     #$05
        bne     sniper_joe_boss_proj_jmp
        lda     #$00
        sta     ent_anim_frame,x
        lda     ent_state,x
        bne     boss_proj_mgr_dec_timer
        lda     #$00
        sta     temp_01
        jsr     boss_proj_mgr_fire
        dec     ent_x_vel_sub,x
        beq     sniper_joe_boss_proj_dec
        lda     #$1F
        sta     ent_state,x
        bne     boss_proj_mgr_dec_timer
sniper_joe_boss_proj_dec:
        dec     $0110,x
sniper_joe_boss_proj_jmp:
        jmp     boss_proj_mgr_physics

sniper_joe_boss_proj_init:
        lda     ent_anim_id,x
        bne     boss_proj_mgr_physics
        lda     #$00
        sta     ent_anim_frame,x
        lda     ent_state,x
        bne     boss_proj_mgr_dec_timer
        lda     #$0A
        sta     temp_01
        jsr     boss_proj_mgr_fire
        inc     ent_x_vel_sub,x
        lda     ent_x_vel_sub,x
        cmp     #$06
        bne     boss_proj_mgr_set_timer
        inc     $0110,x
        bne     boss_proj_mgr_physics

; =============================================================================
; boss_proj_mgr_set_timer -- Boss Projectile Manager — timer-based firing with RNG ($B266)
; =============================================================================
boss_proj_mgr_set_timer:  lda     #$1F
        sta     ent_state,x
boss_proj_mgr_dec_timer:  dec     ent_state,x
boss_proj_mgr_physics:  jsr     apply_entity_physics_alt
        rts

boss_proj_mgr_fire:  ldx     temp_01
        lda     rng_seed
        and     boss_fire_rng_mask,x
        clc
        adc     boss_fire_rng_base,x
        sta     $0B
        lda     boss_fire_rng_divisor,x
        sta     $0D
        lda     #$00
        sta     $0A
        sta     $0C
        jsr     divide_16bit
        ldx     current_entity_slot
        lda     #$25
        jsr     bank_switch_enqueue
        lda     #ENTITY_SHOTMAN
        jsr     spawn_entity_from_parent
        bcs     boss_fire_done
        ldx     temp_01
        lda     boss_fire_vel_y_sub,x
        sta     $0670,y
        lda     boss_fire_vel_y_hi,x
        sta     $0650,y
        lda     $0E
        sta     $0630,y
        lda     $0F
        sta     $0610,y
        sec
        lda     ent_y_spawn_px,y
        sbc     boss_fire_y_offset,x
        sta     ent_y_spawn_px,y
        lda     ent_spawn_flags,y
        and     #$40
        bne     boss_fire_adjust_x
        inx
        inx
boss_fire_adjust_x:  clc
        lda     ent_x_spawn_px,y
        adc     boss_fire_x_offset,x
        sta     ent_x_spawn_px,y
        lda     ent_x_spawn_scr,y
        adc     boss_fire_x_offset_hi,x
        sta     ent_x_spawn_scr,y
boss_fire_done:  ldx     current_entity_slot
        rts

boss_fire_rng_mask:  .byte   $23        ; boss fire RNG bitmask
boss_fire_rng_base:  .byte   $18
boss_fire_rng_divisor:  .byte   $30
boss_fire_vel_y_sub:  .byte   $E6
boss_fire_vel_y_hi:  .byte   $04
boss_fire_y_offset:  .byte   $0C
boss_fire_x_offset:  .byte   $0C
boss_fire_x_offset_hi:  .byte   $00,$F4,$FF,$1F,$60,$18,$D4,$02
        .byte   $00,$08,$00,$F8,$FF  ; unknown data padding
sniper_armor_ai:
        lda     $0110,x
        bne     multi_boss_state_check
        lda     ent_state,x
        bne     boss_fire_anim_check
        lda     ent_anim_id,x
        cmp     #$02
        bne     multi_boss_physics
        lda     #$87
        sta     ent_flags,x
        jsr     entity_face_player
        lda     #$78
        sta     ent_y_vel_sub,x
        lda     #$04
        sta     ent_y_vel,x
        lda     #$C9
        sta     ent_x_vel_sub,x
        lda     #$01
        sta     ent_x_vel,x
        inc     $0110,x
        bne     multi_boss_physics
boss_fire_anim_check:
        lda     ent_anim_id,x
        bne     multi_boss_dec_main_timer
        sta     ent_anim_frame,x
multi_boss_dec_main_timer:  dec     ent_state,x

; =============================================================================
; multi_boss_physics -- Multi-Phase Boss — state machine with timer-based phase changes ($B32D)
; =============================================================================
multi_boss_physics:  jsr     apply_entity_physics_alt
        bcc     multi_boss_rts
        jmp     multi_boss_death_check

multi_boss_rts:  rts

multi_boss_fallthrough:  jmp     multi_boss_full_physics

multi_boss_state_check:
        cmp     #$01
        bne     multi_boss_state_2
        lda     #$02
        sta     ent_anim_id,x
        lda     ent_y_vel,x
        php
        lda     #$0F
        sta     temp_01
        lda     #$1C
        sta     temp_02
        jsr     check_horiz_tile_collision
        plp
        bpl     multi_boss_fallthrough
        lda     temp_00
        beq     multi_boss_fallthrough
        lda     #$21
        jsr     bank_switch_enqueue
        lda     #$03
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_x_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_y_vel_sub,x
        sta     ent_y_vel,x
        sta     ent_anim_frame,x
        lda     ent_flags,x
        and     #$FB
        sta     ent_flags,x
        lda     #$3E
        sta     ent_state,x
        dec     $0110,x
        sec
        lda     ent_y_px
        sbc     ent_y_px,x
        cmp     #$10
        bne     multi_boss_dec_timer
        lda     #$12
        sta     ent_state,x
        lda     #$02
        sta     $0110,x
        bne     multi_boss_dec_timer
multi_boss_state_2:  lda     ent_anim_id,x
        bne     multi_boss_check_timer
        lda     #$00
        sta     ent_anim_frame,x
multi_boss_check_timer:  lda     ent_state,x
        bne     multi_boss_dec_timer
        lda     #$25
        jsr     bank_switch_enqueue
        jsr     entity_face_player
        lda     #ENTITY_GENERIC_PROJ
        jsr     spawn_entity_from_parent
        bcs     multi_boss_check_cycle
        lda     $0110,x
        tax
        lda     multi_boss_shot_vel_y_sub,x
        sta     $0670,y
        lda     multi_boss_shot_vel_y_hi,x
        sta     $0650,y
        lda     multi_boss_shot_vel_x_sub,x
        sta     $0630,y
        lda     multi_boss_shot_vel_x_hi,x
        sta     $0610,y
multi_boss_check_cycle:  txa
        ldx     current_entity_slot
        cmp     #$06
        bne     multi_boss_set_short_timer
        lda     #$00
        sta     $0110,x
        lda     #$3F
        sta     ent_state,x
        bne     multi_boss_dec_timer
multi_boss_set_short_timer:  lda     #$12
        sta     ent_state,x
        inc     $0110,x
multi_boss_dec_timer:  dec     ent_state,x
multi_boss_full_physics:  jsr     apply_entity_physics
        bcc     multi_boss_rts_2
        jmp     multi_boss_death_check

multi_boss_rts_2:  rts

multi_boss_death_check:  lda     ent_hp,x
        bne     multi_boss_rts_2
        lda     #ENTITY_SNIPER_JOE
        jsr     spawn_entity_from_parent
        bcs     multi_boss_rts_2
        lda     #$7E
        .byte   $99,$F0           ; STA $04F0,Y (hi byte overlaps table below)
multi_boss_shot_vel_y_sub:  .byte   $04,$60,$6A,$A0,$88 ; vel Y sub table (also STA hi byte + RTS)
multi_boss_shot_vel_y_hi:  .byte   $12,$58,$FB,$FC,$FD
multi_boss_shot_vel_x_sub:  .byte   $FE,$FF,$8C,$4E,$9A ; multi-boss shot X velocity table
multi_boss_shot_vel_x_hi:  .byte   $C2,$D2,$06,$07,$07,$07,$07
; --- sniper_joe_ai -- Sniper Joe unarmored (type $4F) — face player, 3-shot burst, walk after firing ---
sniper_joe_ai:
        jsr     entity_face_player
        lda     #$00
        sta     ent_anim_frame,x
        lda     #$0B
        sta     temp_01
        lda     #$0C
        sta     temp_02
        jsr     check_horiz_tile_collision
        lda     ent_anim_id,x
        bne     sniper_joe_check_shoot
        lda     #$00
        sta     ent_anim_id,x
        lda     ent_state,x
        bne     sniper_joe_dec_timer
        inc     ent_anim_id,x
        lda     #$1F
        sta     ent_state,x
        lda     ent_flags,x
        and     #$F7
        sta     ent_flags,x
sniper_joe_check_shoot:
        lda     ent_state,x
        bne     sniper_joe_dec_timer
        lda     #$25
        jsr     bank_switch_enqueue
        lda     #ENTITY_GENERIC_PROJ
        jsr     spawn_entity_from_parent
        bcs     sniper_joe_advance
        lda     #$02
        sta     $0610,y

; =============================================================================
; sniper_joe_advance -- Sniper Joe unarmored (type $4F) — advance shot counter ($B469)
; =============================================================================
sniper_joe_advance:  inc     $0110,x
        lda     $0110,x
        cmp     #$03
        bne     sniper_joe_set_timer
        lda     #$00
        sta     $0110,x
        sta     ent_anim_id,x
        lda     #$7E
        sta     ent_state,x
        lda     ent_flags,x
        ora     #$08
        sta     ent_flags,x
        bne     sniper_joe_dec_timer
sniper_joe_set_timer:  lda     #$1F
        sta     ent_state,x
sniper_joe_dec_timer:  dec     ent_state,x
        jsr     apply_entity_physics
        rts

; --- scworm_nest_ai -- Scworm nest (type $50) — spawns up to 3 Scworm worms on timer if player in range ---
scworm_nest_ai:
        lda     ent_state,x
        bne     scworm_nest_dec_timer
        lda     #$20
        sta     ent_state,x
        lda     #$03
        sta     temp_01
        lda     #ENTITY_SCWORM
        jsr     find_entity_count_check
        bcs     scworm_nest_dec_timer
        jsr     entity_face_player
        lda     temp_00
        cmp     #$48
        bcs     scworm_nest_dec_timer
        lda     #ENTITY_SCWORM
        jsr     spawn_entity_from_parent
        bcs     scworm_nest_dec_timer
        sec
        lda     ent_y_spawn_px,y
        sbc     #$0C
        sta     ent_y_spawn_px,y
        lda     #$1F
        sta     $04F0,y
scworm_nest_dec_timer:  dec     ent_state,x
        jsr     apply_entity_physics_alt
        rts

scworm_worm_ai:
        lda     $0110,x
        bne     scworm_worm_dispatch
        dec     ent_state,x
        bne     scworm_worm_check_anim
        lda     #$87
        sta     ent_flags,x
        jsr     entity_face_player
        lda     rng_seed
        and     #$1F
        sta     temp_01
        sec
        lda     temp_00
        sbc     temp_01
        bcs     scworm_worm_store_dist
        lda     #$00
scworm_worm_store_dist:
        sta     temp_00
        lda     #$00
        asl     temp_00
        rol     a
        asl     temp_00
        rol     a
        asl     temp_00
        rol     a
        sta     ent_x_vel,x
        lda     temp_00
        sta     ent_x_vel_sub,x
        lda     #$04
        sta     ent_y_vel,x
        inc     $0110,x
        bne     scworm_worm_check_anim
scworm_worm_dispatch:
        cmp     #$02
        bcs     scworm_worm_wall_timer
        lda     ent_y_vel,x
        php
        lda     #$05
        sta     temp_01
        lda     #$08
        sta     temp_02
        jsr     check_horiz_tile_collision
        plp
        bpl     scworm_worm_check_anim
        lda     temp_00
        beq     scworm_worm_check_anim
        lda     #$5D
        sta     ent_state,x
        inc     $0110,x
        bne     scworm_worm_wall_timer
scworm_worm_check_anim:  lda     ent_anim_id,x
        cmp     #$0A
        bne     scworm_worm_physics
        lda     #$06
        sta     ent_anim_id,x
scworm_worm_physics:  jsr     apply_entity_physics
        rts

scworm_worm_wall_timer:  lda     ent_state,x
        beq     scworm_worm_wall_physics
        dec     ent_state,x
        lda     ent_anim_id,x
        cmp     #$0A
        bne     scworm_worm_wall_physics
        lda     #$06
        sta     ent_anim_id,x
scworm_worm_wall_physics:  jsr     apply_entity_physics_alt
        rts

press_retract_ai:
        dec     ent_state,x
        beq     wily_gravity_deactivate
        jsr     apply_entity_physics_alt
        rts
wily_gravity_deactivate:
        lsr     ent_flags,x
        rts

appear_block_a_ai:
        lda     #$7D
        bne     despawn_timer_store
appear_block_b_ai:
        lda     #$BB
        bne     despawn_timer_store
appear_block_c_ai:
        lda     #$FA
despawn_timer_store:
        sta     temp_00
        lda     $0110,x
        bne     despawn_timer_phase_1
        lda     temp_00
        sta     $0160,x
        inc     $0110,x
        bne     despawn_timer_dec
despawn_timer_phase_1:  cmp     #$01
        bne     despawn_timer_phase_2
        lda     $0160,x
        bne     despawn_timer_dec
        lda     #$90
        sta     ent_flags,x
        lda     #$3C
        jsr     bank_switch_enqueue
        lda     #$7D
        sta     $0160,x
        inc     $0110,x
        lda     #$00
        sta     ent_anim_frame,x
        sta     ent_anim_id,x
        beq     despawn_timer_dec
despawn_timer_phase_2:  lda     ent_anim_id,x
        cmp     #$05
        bne     despawn_phase_3_setup
        lda     #$00
        sta     ent_anim_frame,x
despawn_phase_3_setup:  lda     #$01
        sta     ent_state,x
        lda     ent_x_px,x
        and     ent_x_vel,x
        sta     ent_y_vel,x
        lda     ent_y_px,x
        and     ent_x_vel_sub,x
        sta     ent_y_vel_sub,x
        lda     $0160,x
        bne     despawn_timer_dec
        lda     #$A0
        sta     ent_flags,x
        lda     #$7D
        sta     $0160,x
        dec     $0110,x
despawn_timer_dec:  dec     $0160,x
        jsr     apply_entity_physics_alt
        rts

neo_metall_flip_ai:
        lda     current_stage
        cmp     #$0C
        beq     stage_palette_check_boss
        lsr     ent_flags,x
        lda     #$FF
        sta     a:$00F0,x
        lda     current_stage
        cmp     #$0A
        beq     stage_palette_clear
        sec
        lda     ent_x_screen,x
        sbc     #$0A
        asl     a
        asl     a
        asl     a
        tay
        ldx     #$00
stage_palette_copy_loop:  lda     stage_palette_entries,y
        sta     $035E,x
        iny
        inx
        cpx     #$08
        bne     stage_palette_copy_loop
        rts

stage_palette_clear:
        lda     #$0F
        sta     $0363
        sta     $0364
        sta     $0365
        rts

stage_palette_check_boss:
        lda     $AA
        beq     stage_boss_jmp
        jsr     apply_entity_physics_alt
        rts

stage_boss_jmp:  jmp     wily4_enemy_shared_ai

stage_palette_entries:  .byte   $0F,$39,$18,$12,$0F,$39,$18,$01 ; stage palette entries for boss rooms
        .byte   $0F,$39,$18,$01,$0F,$39,$18,$01
        .byte   $0F,$39,$18,$01,$0F,$39,$18,$0F
; --- wily_boss_init -- Wily Boss (type $58) — tile collision check, spawns copies with velocity pattern ---
wily_boss_init:
        lda     $0110,x
        bne     wily_boss_check_phase
        lda     #$03
        sta     temp_01
        lda     #$04
        sta     temp_02
        jsr     check_horiz_tile_collision
        lda     temp_03
        beq     wily_boss_first_phase
        lsr     ent_flags,x
        rts
wily_boss_first_phase:
        lda     temp_00
        beq     wily_boss_physics
        lda     #$04
        sta     temp_01
wily_boss_spawn_loop:  lda     #ENTITY_WILY_BOSS
        jsr     spawn_entity_from_parent
        bcs     wily_boss_setup_vel
        ldx     temp_01
        lda     wily_boss_vel_table,x
        sta     $0670,y
        lda     wily_boss_vel_hi_table,x
        sta     $0650,y
        lda     #$01
        sta     $0120,y
        lda     #$1F
        sta     $04F0,y
        ldx     current_entity_slot
        dec     temp_01
        bne     wily_boss_spawn_loop
wily_boss_setup_vel:  lda     #$81
        sta     ent_flags,x
        lda     #$00
        sta     ent_y_vel_sub,x
        sta     ent_y_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
        lda     #$1F
        sta     ent_state,x
        inc     $0110,x
wily_boss_check_phase:
        lda     $0110,x
        cmp     #$01
        bne     wily_boss_timer_check
        dec     ent_state,x
        bne     wily_boss_physics
        clc
        lda     ent_y_vel_sub,x
        eor     #$FF
        adc     #$01
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        eor     #$FF
        adc     #$00
        sta     ent_y_vel,x
        inc     $0110,x
        lda     #$1F
        sta     ent_state,x
        bne     wily_boss_physics
wily_boss_timer_check:  dec     ent_state,x
        bne     wily_boss_physics
        lsr     ent_flags,x
        rts

wily_boss_physics:  jsr     apply_entity_physics
        rts

wily_boss_vel_table:  .byte   $00,$41,$82,$C4,$06 ; Wily boss velocity table
wily_boss_vel_hi_table:  .byte   $00,$00,$00,$00,$01
; --- quick_boomer_ai -- Quick Boomerang (type $59) — delayed fall: hover, pause, then accelerate toward player ---
quick_boomer_ai:
        lda     $0110,x
        bne     quick_boomer_phase_1
        dec     ent_state,x
        bne     quick_boomer_physics
        inc     $0110,x
        lda     #$1F
        sta     ent_state,x
        lda     #$00
        sta     ent_x_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_y_vel,x
        sta     ent_y_vel_sub,x
        beq     quick_boomer_physics
quick_boomer_phase_1:
        cmp     #$01
        bne     quick_boomer_physics
        dec     ent_state,x
        bne     quick_boomer_physics
        inc     $0110,x
        lda     #$00
        sta     jump_ptr
        lda     #$04
        sta     jump_ptr_hi
        jsr     calc_entity_velocity
quick_boomer_physics:  jsr     apply_entity_physics
        rts

; --- bubble_shot_ai -- Bubble Man shot (type $5B) — bounce on floor, deactivate on wall ---
bubble_shot_ai:
        lda     ent_y_vel,x
        php
        lda     #$07
        sta     temp_00
        lda     #$08
        sta     temp_02
        jsr     check_horiz_tile_collision
        plp
        bpl     bubble_shot_check_deactivate
        lda     temp_00
        beq     bubble_shot_check_deactivate
        lda     #$03
        sta     ent_y_vel,x
        lda     #$76
        sta     ent_y_vel_sub,x
bubble_shot_check_deactivate:
        lda     temp_03
        beq     bubble_shot_physics
        lsr     ent_flags,x
bubble_shot_physics:  jsr     apply_entity_physics
        rts

; --- air_tornado_boss_ai -- Air Tornado boss (type $5D) — timer-based velocity decay ---
air_tornado_boss_ai:
        lda     ent_state,x
        beq     air_tornado_boss_physics
        dec     ent_state,x
        bne     air_tornado_boss_physics
        lda     #$00
        sta     ent_x_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_y_vel_sub,x
        sta     ent_y_vel,x
air_tornado_boss_physics:
        jsr     apply_entity_physics
        rts

; --- crash_bomb_ai -- Crash Bomb (type $5E) — fly until wall hit, stick, countdown, spawn blast ring ---
crash_bomb_ai:
        lda     ent_state,x
        bne     crash_bomb_phase_check
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        lda     #$07
        sta     temp_01
        lda     #$08
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     temp_00
        bne     crash_bomb_stick
        jmp     crash_bomb_check_anim
crash_bomb_stick:
        lda     #$00
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
        sta     ent_y_vel_sub,x
        sta     ent_y_vel,x
        inc     ent_anim_id,x
        lda     #$2E
        jsr     bank_switch_enqueue
        lda     #$1F
        sta     $0110,x
        inc     ent_state,x
        bne     crash_bomb_check_anim
crash_bomb_phase_check:
        cmp     #$01
        bne     crash_bomb_timer_check
        dec     $0110,x
        bne     crash_bomb_check_anim
        inc     ent_state,x
        lda     #$38
        sta     $0110,x
crash_bomb_timer_check:  lda     $0110,x
        and     #$07
        bne     crash_bomb_done
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     $0110,x
        lsr     a
        and     #$0C
        sta     temp_02
        ldx     #$04
        sta     temp_01
crash_bomb_spawn_blast:  lda     #ENTITY_CRASH_BLAST
        jsr     spawn_entity_from_parent
        bcs     crash_bomb_done
        ldx     temp_02
        clc
        lda     ent_y_spawn_px,y
        adc     $E11F,x
        sta     ent_y_spawn_px,y
        clc
        lda     ent_x_spawn_px,y
        adc     $E12F,x
        sta     ent_x_spawn_px,y
        lda     ent_x_spawn_scr,y
        adc     $E13F,x
        sta     ent_x_spawn_scr,y
        ldx     current_entity_slot
        inc     temp_02
        dec     temp_01
        bne     crash_bomb_spawn_blast
crash_bomb_done:  ldx     current_entity_slot
        dec     $0110,x
        bpl     crash_bomb_check_anim
        lsr     ent_flags,x
        rts

crash_bomb_check_anim:  lda     ent_anim_id,x
        cmp     #$04
        bne     crash_bomb_physics
        lda     #$02
        sta     ent_anim_id,x
crash_bomb_physics:  jsr     apply_entity_physics
        rts

; --- wood_tornado_ai -- Wood Man tornado projectile (type $62) — flip direction, rise with gravity ---
wood_tornado_ai:
        lda     ent_state,x
        bne     wily_gravity_init
        lda     #$00
        sta     ent_anim_frame,x
        jsr     apply_entity_physics
        rts
wily_gravity_init:
        lda     ent_anim_id,x
        ora     ent_anim_frame,x
        bne     wily_gravity_accel
        lda     ent_flags,x
        eor     #$40
        sta     ent_flags,x
        lda     #$FE
        sta     ent_y_vel,x
        lda     #$00
        sta     ent_y_vel_sub,x
wily_gravity_accel:  clc
        lda     ent_y_vel_sub,x
        adc     #$20
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        adc     #$00
        sta     ent_y_vel,x
        jsr     apply_entity_physics
        rts

; --- wily4_shield_ai -- Wily 4 shield (type $63) — stage check, hitbox setup, track parent Y position ---
wily4_shield_ai:
        lda     current_stage
        cmp     #WILY_STAGE_START
        beq     wily4_shield_hitbox_small
        lda     #$58
        sta     $0150,x
        sec
        lda     ent_y_px,x
        sbc     #$18
        sta     $0160,x
        lda     $AA
        bne     wily4_shield_physics
        jmp     wily4_enemy_shared_ai
wily4_shield_hitbox_small:
        lda     #$10
        sta     $0150,x
        sec
        lda     ent_y_px,x
        sbc     #$08
        sta     $0160,x
        lda     $AA
        bne     wily4_shield_physics
        jsr     apply_entity_physics
        bcc     wily4_shield_rts
        lda     #$00
        sta     $0150,x
wily4_shield_rts:  rts

wily4_shield_physics:  jsr     apply_entity_physics_alt
        rts

; --- wily4_timer_check -- Boobeam Trap controller (type $64) — spawns shield turrets, phase management ---
wily4_timer_check:
        lda     ent_state,x
        bpl     wily4_timer_positive
        rts
wily4_timer_positive:
        bne     wily4_boss_active
        lda     scroll_screen_hi
        sta     scroll_screen_lo
        inc     current_screen
        lda     #$07
        sta     ent_hp,x
        lda     #$08
        sta     $B3
        lda     #$01
        sta     $B1
        lda     #$17
        sta     col_update_addr_hi
        lda     #$E0
        sta     col_update_addr_lo
        lda     #$00
        sta     $04E1
        sta     $06C1
        sta     $05A9
        sta     $B2
        lda     #$B8
        sta     $05A7
        lda     #$0F
        ldx     #$0F

; =============================================================================
; wily4_palette_loop -- Wily Stage 4 Boss — multi-turret with entity spawning ($B8CC)
; =============================================================================
wily4_palette_loop:  sta     palette_ram,x
        dex
        bpl     wily4_palette_loop
        ldx     current_entity_slot
        inc     ent_state,x
        lda     #$18
        sta     $0110,x
        lda     #ENTITY_WILY4_SHIELD
        sta     temp_00
        ldy     #$0F
wily4_entity_init_loop:  jsr     find_entity_scan ; find unused entity slot
        bcs     wily4_entity_init_rts
        lda     #$01
        sta     $0610,y
        dey
        bpl     wily4_entity_init_loop
wily4_entity_init_rts:  rts

wily4_boss_active:  lda     #$01
        sta     $40
        lda     #$00
        sta     $AF
        lda     #$00
        sta     $4F
        lda     #$01
        sta     $50
        lda     ent_state,x
        cmp     #$01
        bne     wily4_boss_phase_2
        dec     $0110,x
        bne     wily4_boss_rts
        lda     #$40
        sta     $0110,x
        lda     #ENTITY_WILY4_SHIELD
        jsr     spawn_entity_from_parent
        lda     #$01
        sta     $0610,y
        sta     $04F0,y
        dec     ent_hp,x
        bne     wily4_boss_rts
        inc     ent_state,x
        rts

wily4_boss_phase_2:  dec     $0110,x
        bne     wily4_boss_rts
        ldy     ent_hp,x
        lda     wily4_timer_table,y     ; look up spawn timing
        sta     $0110,x
        bmi     wily4_boss_despawn_all
        lda     wily4_y_pos_table,y
        sta     temp_02
        lda     #ENTITY_WILY4_SHIELD
        jsr     spawn_entity_from_parent
        lda     temp_02
        sta     ent_y_spawn_px,y
        lda     #$01
        sta     $0610,y
        inc     ent_hp,x
wily4_boss_rts:  rts

wily4_boss_despawn_all:  lda     #ENTITY_WILY4_SHIELD
        sta     temp_00
        ldy     #$0F
wily4_despawn_loop:  jsr     find_entity_scan
        bcs     wily4_despawn_done
        lda     #$00
        sta     $0610,y
        dey
        bpl     wily4_despawn_loop
wily4_despawn_done:  ldx     current_entity_slot
        lda     #$FF
        sta     ent_state,x
        inc     $B1
        lda     #$0B
        jsr     bank_switch_enqueue
        rts

wily4_timer_table:  .byte   $40,$01,$20,$28,$FF ; Wily stage 4 spawn timer table
wily4_y_pos_table:  .byte   $98,$98,$48,$78 ; Wily stage 4 Y position table
wily4_enemy_shared_ai:  lda     $0641
        sta     ent_y_vel,x
        lda     $0661
        sta     ent_y_vel_sub,x
wily4_shared_velocity:  lda     $0601
        sta     ent_x_vel,x
        lda     $0621
        sta     ent_x_vel_sub,x
        lda     $05A7
        sta     ent_flags,x
        jsr     apply_entity_physics
        lda     $B3
        cmp     #$08
        beq     wily4_shared_set_flags
        lda     ent_type,x
        cmp     #ENTITY_GUTSDOZER_TURRET
        beq     wily4_shared_set_flags
        lda     ent_flags,x
        ora     #$23
        sta     ent_flags,x
        rts

wily4_shared_set_flags:  lda     #$8B
        sta     ent_flags,x
        rts

; --- dragon_body_facing_setup -- Dragon body A (type $65) — set facing from parent velocity ---
dragon_body_facing_setup:
        lda     #$00
        sta     ent_anim_id,x
        lda     $05A7
        and     #$40
        beq     wily4_facing_setup
        inc     ent_anim_id,x
wily4_facing_setup:  lda     #$00
        sta     ent_anim_frame,x
        jmp     wily4_enemy_shared_ai

; --- dragon_part_ai -- Mecha Dragon body/platform part (type $67) — stage-conditional physics ---
dragon_part_ai:
        lda     current_stage
        cmp     #WILY_STAGE_START
        beq     wily4_stage_physics
        jmp     wily4_enemy_shared_ai
wily4_stage_physics:
        jsr     apply_entity_physics
        lda     ent_y_px,x
        cmp     #$80
        bne     wily4_pos_reset_anim
        lda     #$00
        sta     ent_y_vel,x
        lda     ent_anim_id,x
        ora     ent_anim_frame,x
        bne     wily4_pos_check_rts
        inc     $04E1
        lsr     ent_flags,x
wily4_pos_check_rts:  rts

wily4_pos_reset_anim:  lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        rts

; --- gutsdozer_turret_ai -- Guts-Dozer oscillating turret (type $69) — vertical oscillation ---
gutsdozer_turret_ai:
        lda     ent_state,x
        bne     wily_capsule_set_movement
        lda     #$80
        sta     ent_y_vel_sub,x
        lda     #$FF
        sta     ent_y_vel,x
        lda     ent_y_px,x
        cmp     #$7F
        bcc     wily_capsule_jmp_shared
        bcs     wily_capsule_stop_vel
wily_capsule_set_movement:
        lda     #$80
        sta     ent_y_vel_sub,x
        lda     #$00
        sta     ent_y_vel,x
        lda     ent_y_px,x
        cmp     #$68
        bcs     wily_capsule_jmp_shared
wily_capsule_stop_vel:
        lda     #$00
        sta     ent_y_vel,x
        sta     ent_y_vel_sub,x

; =============================================================================
; wily_capsule_jmp_shared -- Wily Capsule Teleport AI — teleportation and attack pattern ($BA2F)
; =============================================================================
wily_capsule_jmp_shared:  jmp     wily4_shared_velocity

; --- wily_teleport_phase_check -- Wily teleport (type $6A) — multi-phase teleport + velocity targeting ---
wily_teleport_phase_check:
        lda     ent_anim_id,x
        bne     wily_teleport_ai
        sta     ent_anim_frame,x
        dec     $0110,x
        bne     wily_teleport_apply
        lda     ent_flags,x
        and     #$40
        bne     wily_teleport_adjust
        lsr     ent_flags,x
        rts
wily_teleport_adjust:
        clc
        lda     ent_x_px,x
        adc     #$08
        sta     ent_x_px,x
        inc     ent_anim_id,x
        lda     #$01
        sta     $0160,x
        lda     #$0F
        sta     $0110,x
        bne     wily_teleport_ai
wily_teleport_apply:
        jsr     apply_entity_physics
        rts

wily_teleport_ai:  lda     $0160,x
        bne     wily_teleport_stop_vel
        dec     $0110,x
        beq     wily_teleport_pause
        lda     ent_x_px,x
        cmp     #$30
        bcc     wily_teleport_pause
        cmp     #$D0
        bcs     wily_teleport_pause
        lda     ent_y_px,x
        cmp     #$30
        bcc     wily_teleport_pause
        cmp     #$C0
        bcc     wily_teleport_check_anim
wily_teleport_pause:  lda     #$01
        sta     $0160,x
        lda     #$3E
        sta     $0110,x
wily_teleport_stop_vel:  lda     #$00
        sta     ent_x_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_y_vel_sub,x
        sta     ent_y_vel,x
        dec     $0110,x
        bne     wily_teleport_check_anim
        lda     #$83
        sta     ent_flags,x
        lda     #$01
        sta     $06E0,x
        lda     #$00
        sta     $0160,x
        ldy     ent_state,x
        lda     wily_teleport_timer_table,y
        sta     $0110,x
        lda     wily_teleport_target_lo,y
        sta     jump_ptr
        lda     wily_teleport_target_hi,y
        sta     jump_ptr_hi
        jsr     calc_entity_velocity
wily_teleport_check_anim:  lda     ent_anim_id,x
        cmp     #$06
        bne     wily_teleport_set_anim
        lda     #$04
        sta     ent_anim_id,x
wily_teleport_set_anim:  jsr     apply_entity_physics
        bcc     wily_teleport_rts
        sec
        lda     $06C1
        sbc     #$02
        sta     $06C1
wily_teleport_rts:  rts

wily_teleport_timer_table:  .byte   $3E,$1F,$1F,$1F ; Wily teleport timing table
wily_teleport_target_lo:  .byte   $00,$68,$00,$80
wily_teleport_target_hi:  .byte   $01,$01,$02,$02
; --- wily_teleport_gravity -- Wily teleport: gravity apply or vert check ($BAEF) ---
wily_teleport_gravity:
        lda     $B1
        cmp     #$04
        bcs     wily_final_vert_check
        clc
        lda     ent_y_vel_sub,x
        adc     #$40
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        adc     #$00
        sta     ent_y_vel,x
; =============================================================================
; wily_final_physics -- Wily Final Boss — gravity, movement, and multi-phase AI ($BB06)
; =============================================================================
wily_final_physics:  jsr     apply_entity_physics
        rts

wily_final_vert_check:
        lda     #$07
        sta     temp_01
        lda     #$08
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     temp_00
        beq     wily_final_physics
        lda     #$04
        sta     ent_y_vel,x
        lda     #$78
        sta     ent_y_vel_sub,x
        bne     wily_final_physics
        sec
        lda     ent_x_vel_sub,x
        sbc     #$01
        sta     ent_x_vel_sub,x
        tay
        lda     ent_x_vel,x
        sbc     #$00
        sta     ent_x_vel,x
        bne     wily_final_check_state
        cpy     #$00
        beq     wily_final_spawn_projectile
        cpy     #$3E
        bcs     wily_final_check_state
        lda     ent_anim_id,x
        cmp     #$06
        bne     wily_final_run_physics
        lda     #$04
        bne     wily_final_set_state
; --- wily_final_spawn_projectile -- Wily final boss projectile spawn — resets velocity, spawns ENTITY_WILY_PROJ ---
wily_final_spawn_projectile:  lda     #$77
        sta     ent_x_vel_sub,x
        lda     #$01
        sta     ent_x_vel,x
        lda     #ENTITY_WILY_PROJ
        ldx     #$01
        jsr     spawn_entity_from_parent
        bcs     wily_final_check_state
        txa
        pha
        tya
        adc     #$10
        tax
        stx     current_entity_slot
        lda     #$08
        sta     jump_ptr_hi
        lda     #$00
        sta     jump_ptr
        jsr     calc_entity_velocity
        pla
        tax
        stx     current_entity_slot
wily_final_check_state:  lda     ent_anim_id,x
        cmp     #$04
        bne     wily_final_run_physics
        lda     #$00
wily_final_set_state:  sta     ent_anim_id,x
wily_final_run_physics:  jsr     apply_entity_physics_alt
        bcc     wily_final_rts
        sec
        lda     $06C1
        sbc     #$06
        sta     $06C1
        bcs     wily_final_rts
        lda     #$00
        sta     $06C1
wily_final_rts:  rts

        lda     #$00
        sta     ent_anim_frame,x
        ldy     ent_anim_id,x
        clc
        lda     ent_x_px,x
        adc     wily_final_x_adjust_table,y
        sta     ent_x_px,x
        rts

wily_final_x_adjust_table:  .byte   $03,$02
; --- wily_final_ai_main -- Wily Final: face player + phase dispatch ($BBAD) ---
wily_final_ai_main:
        jsr     entity_face_player
        lda     ent_state,x
        bne     wily_final_phase_active
        lda     temp_00
        cmp     #$38
        bcs     wily_final_apply_physics
        lda     rng_seed
        sta     temp_01
        lda     #$03
        sta     temp_02
        jsr     divide_8bit
        ldy     temp_04
        ldx     current_entity_slot
        lda     wily_final_timer_table,y
        sta     $0110,x
        inc     ent_state,x
wily_final_apply_physics:  jsr     apply_entity_physics_alt
        rts

wily_final_phase_active:
        cmp     #$02
        bcs     wily_final_gravity
        lda     temp_00
        cmp     #$38
        bcc     wily_final_timer_check
        dec     ent_state,x
        beq     wily_final_apply_physics
wily_final_timer_check:  dec     $0110,x
        bne     wily_final_apply_physics
        lda     #$02
        sta     ent_y_vel,x
        lda     #$00
        sta     ent_y_vel_sub,x
        lda     #$83
        sta     ent_flags,x
        inc     ent_state,x
wily_final_gravity:  lda     ent_y_vel,x
        bpl     wily_final_rise_check
        lda     ent_y_px,x
        cmp     #$E0
        bcc     wily_final_physics_2
        lda     #$00
        sta     ent_state,x
        lda     #$A0
        sta     ent_flags,x
        bne     wily_final_physics_2
wily_final_rise_check:  lda     ent_y_px,x
        cmp     #$80
        bcs     wily_final_physics_2
        lda     #$FF
        sta     ent_y_vel_sub,x
        sta     ent_y_vel,x
        lda     #$87
        sta     ent_flags,x
wily_final_physics_2:  jsr     apply_entity_physics
        rts

wily_final_timer_table:  .byte   $1F,$2E,$7D ; Wily final boss timer table (3 entries: RNG/3)
; --- flash_hazard_ai -- Flash hazard (types $72/$73) — timer check + projectile spawn ($BC30) ---
flash_hazard_ai:
        lda     ent_state,x
        cmp     #$3E
wily_final_bank_table:                  ; also read as data by pickup_ai_check (LDA $BC35,y)
        bne     wily_final_inc_timer
        lda     ent_anim_id,x
        cmp     #$05
        bne     wily_final_check_anim
        lda     ent_anim_frame,x
        bne     wily_final_check_anim
        lda     #ENTITY_FLASH_PROJ
        jsr     spawn_entity_from_parent
        bcs     wily_final_clear_timer
        lda     ent_type,x
        sta     $04F0,y
        clc
        lda     ent_y_spawn_px,y
        adc     #$04
        sta     ent_y_spawn_px,y
        lda     #$FF
        sta     $0650,y
        sta     $0670,y
wily_final_clear_timer:
        lda     #$00
        sta     ent_state,x
wily_final_inc_timer:
        inc     ent_state,x
        lda     ent_anim_id,x
        cmp     #$02
        bne     wily_final_check_anim
        lda     #$00
        sta     ent_anim_id,x
wily_final_check_anim:  jsr     apply_entity_physics_alt
        rts

; --- pickup_ai_check -- pickup/item physics init (ptr table: type $74) — anim check, tile collision ---
pickup_ai_check:
        lda     ent_anim_id,x
        beq     pickup_ai_init
        jsr     apply_entity_physics_alt
        rts
pickup_ai_init:
        lda     #$00
        sta     ent_anim_frame,x
        lda     #$03
        sta     temp_01
        lda     #$04
        sta     temp_02
        jsr     check_vert_tile_collision
        lda     temp_00
        beq     wily_final_check_physics
        ldy     ent_state,x
        lda     wily_final_bank_table,y
        jsr     bank_switch_enqueue
        inc     ent_anim_id,x
        rts

wily_final_check_physics:  jsr     apply_entity_physics
        rts

        .byte   $3D,$3E                 ; unknown padding bytes
; --- pickup_setup_large -- Pickup AI entry: large hitbox (7x8), jump to pickup_check_state ($BCA9) ---
pickup_setup_large:
        lda     #$07
        sta     temp_01
        ldy     #$08
        bne     pickup_check_state
; --- pickup_setup_small -- Pickup AI entry: small hitbox (3x4), fall through to pickup_check_state ($BCB1) ---
pickup_setup_small:
        lda     #$03
        sta     temp_01
        ldy     #$04

; =============================================================================
; pickup_check_state -- Pickup/item — simple physics with gravity ($BCB7)
; =============================================================================
pickup_check_state:  lda     ent_flags,x
        cmp     #$81
        beq     pickup_stopped_state
        lda     temp_01
        pha
        tya
        pha
        jsr     apply_entity_physics
        pla
        sta     temp_02
        pla
        sta     temp_01
        lda     ent_flags,x
        bpl     pickup_rts
        lda     ent_y_vel,x
        php
        jsr     check_horiz_tile_collision
        plp
        bpl     pickup_rts
        lda     temp_00
        beq     pickup_rts
        lda     #$FA
        sta     $0110,x
        lda     #$00
        sta     ent_y_vel,x
        sta     ent_y_vel_sub,x
        lda     #$81
        sta     ent_flags,x
pickup_rts:  rts

pickup_stopped_state:  lda     ent_state,x
        beq     pickup_simple_physics
        dec     $0110,x
        bne     pickup_stopped_physics
        lsr     ent_flags,x
        rts

pickup_stopped_physics:  jsr     apply_entity_physics_alt
        rts

pickup_simple_physics:  jsr     apply_simple_physics ; apply simple movement
        rts

        ldy     #$25
        lda     frame_counter
        and     #$08
        bne     boss_indicator_palette
        ldy     #$0F

; =============================================================================
; boss_indicator_palette -- Boss Room Indicator — palette flash to signal boss door ($BD12)
; =============================================================================
boss_indicator_palette:  sty     $0371
        jsr     apply_entity_physics_alt
        lda     temp_01
        beq     boss_indicator_rts
        txa
        and     #$0F
        sta     $BA
        inc     $BA
boss_indicator_rts:  rts

        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$78,$EE,$E1,$BF
        .byte   $4C,$D1,$F2,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$F0,$CF
        .byte   $E0,$FF,$E0
mmc1_shift_register:  .byte   $FF
