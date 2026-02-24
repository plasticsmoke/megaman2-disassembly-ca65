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

jump_ptr           := $0008
zp_0F15           := $0F15
zp_0F20           := $0F20
addr_1D06           := $1D06
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
wait_ppu_warmup_1:  lda     $2002       ; read PPUSTATUS to clear latch
        bpl     wait_ppu_warmup_1
wait_ppu_warmup_2:  lda     $2002       ; wait for second VBLANK
        bmi     wait_ppu_warmup_2
        dex
        bpl     wait_ppu_warmup_1
        lda     #$00
        sta     $00
        sta     $01
        ldy     #$00
clear_ram_loop:  sta     ($00),y        ; zero out RAM page
        iny
        bne     clear_ram_loop
        inc     $01
        ldx     $01
        cpx     #$08
        bne     clear_ram_loop
        lda     #$0E
        jsr     banked_entry
        lda     #$01
        sta     LBFFF
        lsr     a
        sta     LBFFF
        lsr     a
        sta     LBFFF
        lsr     a
        sta     LBFFF
        lsr     a
        sta     LBFFF
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
        sta     $A8
        lda     #$00
        sta     $A7

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
        sta     $2A
        bne     game_init_check_wily
game_init_set_scroll_bank:  lda     #$03
        sta     $A8
        jsr     nametable_stage_setup
game_init_check_wily:  lda     $2A
        cmp     #$08                    ; stages 8+ are Wily fortress
        bcc     game_init_fill_weapon_ammo
        jsr     boss_beaten_check
        lda     $2A
        cmp     #$09
        bcs     game_init_set_boss_offset
game_init_fill_weapon_ammo:  ldx     #$0A
        lda     #$1C                    ; $1C = full weapon energy (28)
fill_weapon_ammo_loop:  sta     $9C,x
        dex
        bpl     fill_weapon_ammo_loop
game_init_set_boss_offset:  ldx     #$00
        lda     $2A
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
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001
        jsr     chr_upload_init
        lda     #$1C
        sta     $06C0
        lda     #$00
        sta     $AA
        sta     $A9
        jsr     weapon_palette_setup
        jsr     chr_upload_run
        lda     #$00
        sta     $1F
        sta     $1E
        sta     $22
        sta     $B5
        sta     $B6
        sta     $B7
        sta     $B8
        sta     $B9
        sta     $0460
        sta     $0480
        sta     $43
        sta     $44
        sta     $B1
        lda     $20
        jsr     render_full_nametable
        clc
        lda     $20
        adc     #$01
        jsr     render_full_nametable
        lda     #$20
        sta     $1A
        jsr     clear_oam_buffer
        lda     $F8
        ora     #$1E
        sta     $F8
        sta     $2001
        lda     $F7
        ora     #$80
        sta     $F7
        sta     $2000
        sta     $1D
        lda     #$40
        sta     $30
        lda     #$00
        sta     $31
        ldx     $2A
        lda     stage_bank_table,x
        jsr     bank_switch_enqueue
        ldx     #$13
game_init_copy_stage_sprites:  lda     stage_intro_oam_data,x
        sta     $0200,x
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
        sta     $0200,x
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
        lda     $2A
        cmp     #$0C
        bne     main_game_loop
        jmp     wily_game_loop

; =============================================================================
; main_game_loop -- Main Game Loop — per-frame update for normal stages ($8171)
; =============================================================================
main_game_loop:  lda     $AD
        beq     main_loop_check_start   ; skip item handler if no item
        jsr     item_collection_handler
main_loop_check_start:  lda     $27
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
        lda     $37
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
        stx     $2B
        lda     #$7E
        ldx     #$0E
        jsr     spawn_entity_init
        lda     #$3B
        sta     $04BE
        lda     #$80
        sta     $047E
wily_spawn_gate_loop:  lda     #$00
        sta     $2B
        sta     $02
        lda     $BC
        sta     $03
wily_spawn_shift_flags:  lsr     $03
wily_spawn_check_done:  bcs     wily_spawn_next_bit
        lda     #$7C
        ldx     $02
        jsr     spawn_entity_init
        lda     wily_gate_anim_table,y
        sta     $04B0,y
        lda     wily_gate_y_pos_table,y
        sta     $0470,y
wily_spawn_next_bit:  inc     $02
        lda     $02
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
wily_loop_check_start:  lda     $27
        and     #$08
        beq     wily_loop_update_entities
        jsr     palette_anim_run
wily_loop_update_entities:  jsr     build_active_list
        jsr     entity_update_dispatch
        jsr     update_entity_positions
        jsr     process_sound_and_bosses
        jsr     entity_ai_dispatch
        jsr     render_all_sprites
        lda     $37
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
check_screen_transition:  ldx     $1F
        bne     check_vertical_transition ; scroll_x == 0, skip left check
        ldx     $20
        beq     check_scroll_right
        cpx     $14
        bne     check_scroll_right
        ldy     $38
        dey
        jsr     get_screen_boundary
        tya
        ldy     $37
        and     scroll_left_mask_table,y
        beq     check_scroll_right
        jsr     transition_screen_left
        jmp     clear_scroll_request

check_scroll_right:  cpx     $15
        bne     check_vertical_transition
        ldy     $38
        jsr     get_screen_boundary
        tya
        ldy     $37
        and     scroll_right_mask_table,y
        beq     check_vertical_transition
        jsr     transition_screen_right
        ldx     $2A
        lda     $20
        cmp     stage_max_screen_table,x
        bne     scroll_transition_done
        jsr     boss_trigger_entrance
scroll_transition_done:  jmp     clear_scroll_request

check_vertical_transition:  lda     $37
        cmp     #$03                    ; transition type 3 = boss entrance
        bne     clear_scroll_request
        lda     #$01
        sta     $2C
        jmp     boss_death_sequence

clear_scroll_request:  lda     #$00
        sta     $37
scroll_left_mask_table:  rts

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
        sta     $09
        jmp     (jump_ptr)

health_refill_large:
        lda     #$0A              ; large pickup: 10 ticks
        bne     health_refill_set ; always branch
health_refill_small:
        lda     #$02              ; small pickup: 2 ticks
health_refill_set:
        sta     $FD
        lda     $06C0
        cmp     #$1C
        bcs     health_refill_full_rts
        lda     #$07
        sta     $AA
health_refill_loop:  ldx     $A9
        lda     $06C0
        cmp     #$1C                    ; $1C = max HP (28)
        bcs     health_refill_done_jmp
        lda     $1C
        and     #$07
        bne     health_refill_render
        dec     $FD
        bmi     health_refill_done_jmp
        inc     $06C0
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
        lda     $A9
        beq     refill_exit
        ldx     $A9
        lda     $9B,x
        cmp     #$1C
        beq     refill_exit
        lda     #$07
        sta     $AA
weapon_refill_loop:  ldx     $A9
        lda     $9B,x
        cmp     #$1C                    ; $1C = max energy (28)
        bcs     refill_complete
        lda     $1C
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
        sta     $2C
        jsr     weapon_set_base_type
refill_exit:  rts

etank_pickup:
        lda     $A7               ; current E-tank count
        cmp     #$04              ; max = 4
        bcs     etank_pickup_done
        inc     $A7               ; add E-tank
etank_pickup_done:
        lda     #$42
        jsr     bank_switch_enqueue
        rts

extra_life_pickup:
        lda     $A8               ; current lives count
        cmp     #$63              ; max = 99
        bcs     extra_life_done
        inc     $A8
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
        stx     $2A
        jsr     wait_screen_fade
        lda     #$0C
        sta     $2A
        ldx     #$05
        lda     $BA
        cmp     #$04
        bne     wily_door_transition
        ldx     #$02
wily_door_transition:  jsr     set_palette_colors
        inc     $20
        inc     $0440
        inc     $38
        inc     $14
        inc     $15
        lda     #$20
        sta     $0460
        lda     #$B4
        sta     $04A0
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
        sta     $2C
        jsr     weapon_set_base_type
        jsr     reset_entity_slots
wily_teleport_wait:  lda     $06A0
        cmp     #$03
        beq     wily_teleport_done
        jsr     render_all_sprites
        jsr     wait_for_vblank
        jmp     wily_teleport_wait

wily_teleport_done:  lda     #$00
        sta     $0420
        jsr     render_all_sprites
        rts

reset_player_state:  lda     #$C0
        sta     $0420
        lda     #$00
        sta     $36
        sta     $2C
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
        sta     $20
        sta     $0440
        sta     $14
        sta     $15
        bne     wily_set_palette
wily_fade_reverse:
        dec     $20
        dec     $0440
        dec     $38
        dec     $14
        dec     $15
wily_set_palette:
        ldx     #$08
        jsr     set_palette_colors
        lda     #$00
        sta     $B1
        ldx     $B3
        clc
        lda     wily_gate_anim_table,x
        adc     #$07
        sta     $04A0
        lda     wily_gate_y_pos_table,x
        sta     $0460
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
        sta     $20
        sta     $0440
        sta     $14
        sta     $15
        lda     #$00
        sta     $FD
        lda     #$15
        sta     $FE
        jsr     wait_screen_fade
        lda     #$2A
        jsr     render_full_nametable
        lda     #$B4
        sta     $04A0
        lda     #$28
        sta     $0460
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
        sta     $37
        ldx     $2C                     ; current player state index
        lda     player_state_ptr_lo,x
        sta     jump_ptr
        lda     player_state_ptr_hi,x
        sta     $09
        jmp     (jump_ptr)

        lda     $06A0
        cmp     #$04
        bne     player_state_rts
        lda     #$C0
        sta     $0660
        lda     #$FF
        sta     $0640
        lda     #$00
        sta     $AA
        lda     #$03
        sta     $2C
        jsr     weapon_set_base_type
        lda     $0460
        sta     jump_ptr
        lda     $0440
        sta     $09
        lda     $04A0
        sta     $0A
        lda     #$00
        sta     $0B
        jsr     lookup_tile_from_map
        lda     $00
        cmp     #$04
        bne     player_state_rts
        lda     #$04
        sta     $FB
player_state_rts:  rts

        rts
player_state_gun_update:
        lda     $0420             ; player entity flags
        and     #$40              ; check flip bit
        eor     #$40              ; toggle
        sta     $42
        jsr     player_horiz_movement
        jsr     player_vertical_physics
        lda     $06A0
        beq     player_select_ground_state
        jsr     weapon_set_base_type
        rts
player_select_ground_state:
        ldy     #$06
        lda     $00
        beq     player_set_state
        ldy     #$03
player_set_state:  sty     $2C
        rts

        jsr     player_check_fire_weapon
        lda     $23               ; controller input
        and     #$C0              ; check A+B buttons
        beq     player_state_skip_facing
        lda     #$04
        sta     $2C
        jsr     player_update_facing
player_state_skip_facing:
        jsr     player_set_max_speed
        jsr     player_horiz_movement
        jsr     player_vertical_physics
        lda     $00
        bne     player_state_common_exit
        lda     #$06
        sta     $2C
        jsr     weapon_set_base_type
        rts

player_state_common_exit:  lda     $27
        and     #$01
        beq     player_state_set_weapon
        lda     $3B
        sta     $0660
        lda     $3C
        sta     $0640
        lda     #$06
        sta     $2C
player_state_set_weapon:  jsr     weapon_set_base_type
        rts

        jsr     player_check_fire_weapon
        jsr     player_update_facing
        jsr     player_set_max_speed
        jsr     player_horiz_movement
        jsr     player_vertical_physics
        lda     $00
        beq     player_state_to_idle
        lda     $23
        and     #$C0
        bne     player_state_check_land
        lda     #$03
        sta     $2C
        bne     player_state_jump_exit
player_state_check_land:  lda     $06A0
        cmp     #$01
        bne     player_state_jump_exit
        lda     #$05
        sta     $2C
player_state_jump_exit:  jmp     player_state_common_exit

        jsr     player_check_fire_weapon
        jsr     player_update_facing
        jsr     player_set_max_speed
        jsr     player_horiz_movement
        jsr     player_vertical_physics
        lda     $00
        bne     player_state_walk_check
player_state_to_idle:  lda     #$06
        sta     $2C
        jsr     weapon_set_base_type
        rts

player_state_walk_check:
        lda     $23
        and     #$C0
        bne     player_state_check_dir
        lda     #$07
        sta     $2C
player_state_check_dir:  jmp     player_state_common_exit

        jsr     player_check_fire_weapon
        lda     #$00
        sta     $0620             ; clear X velocity (sub-pixel)
        sta     $0600             ; clear X velocity (high byte)
        lda     $23               ; controller input
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
        lda     $0640
        bmi     player_state_climbing
        jsr     player_vertical_physics
        lda     $00
        bne     player_state_on_ground_rts
        lda     $23
        and     #$01
        bne     player_state_on_ground_rts
        lda     $0640
        bmi     player_state_on_ground_rts
        cmp     #$01
        bcc     player_state_on_ground_rts
        beq     player_state_on_ground_rts
        lda     #$01
        sta     $0640
        lda     #$00
        sta     $0660
player_state_on_ground_rts:  rts

player_state_climbing:  jsr     player_vertical_physics
        lda     $00
        beq     player_state_climb_set_weapon
        lda     #$29
        jsr     bank_switch_enqueue
        ldx     #$05
        lda     $25
        and     #$C0
        bne     player_state_climb_dir
        ldx     #$08
player_state_climb_dir:  stx     $2C
        jmp     player_state_common_exit

player_state_climb_set_weapon:  jsr     weapon_set_base_type
        rts

        jsr     player_check_fire_weapon
        jsr     player_update_facing
        jsr     player_set_max_speed
        jsr     player_horiz_movement
        jsr     player_vertical_physics
        lda     $00
        bne     player_ladder_check_buttons
        jmp     player_state_to_idle
player_ladder_check_buttons:
        lda     $23
        and     #$C0
        bne     player_ladder_state_jump
        lda     $06A0
        cmp     #$02
        bne     player_ladder_state_exit
        lda     #$03
        sta     $2C
        bne     player_ladder_state_exit
player_ladder_state_jump:  lda     #$04
        sta     $2C
player_ladder_state_exit:  jmp     player_state_common_exit

player_state_ladder_idle:  lda     #$09
        sta     $2C
        lda     $23
        and     #$02
        beq     player_ladder_clear_ab
        jmp     player_ladder_fire_weapon

player_ladder_clear_ab:  lda     #$00
        sta     $AB
player_ladder_check_input:  lda     $23
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
        lda     $04A0
        and     #$F0
        sec
        sbc     #$0C
        sta     $04A0
        lda     $F9
        sbc     #$00
        sta     $F9
        ldx     #$03
        jmp     player_ladder_set_state

player_ladder_check_left:  and     #$08
        bne     player_ladder_check_solid
        lda     #$0A
        sta     $2C
        bne     player_ladder_check_solid
player_ladder_move_down:  lda     $35
        cmp     #$01
        bne     player_ladder_set_vel
        lda     $04A0
        clc
        adc     #$0C
        sta     $04A0
        lda     $F9
        adc     #$00
        sta     $F9
player_ladder_set_vel:  ldy     #$FF
        ldx     #$40
        lda     $35
        and     #$0C
        bne     player_ladder_check_solid
        lda     #$0A
        sta     $2C
player_ladder_check_solid:  lda     $3D
        beq     player_ladder_store_vel
        ldy     #$00
        ldx     #$00
player_ladder_store_vel:  sty     $0640
        stx     $0660
        jsr     player_ground_collision
        lda     $35
        beq     player_ladder_to_idle
        jsr     player_vertical_physics
        lda     $00
        beq     player_ladder_exit
        ldx     #$03
        bne     player_ladder_set_state
player_ladder_to_idle:  ldx     #$06
player_ladder_set_state:  stx     $2C
        lda     #$00
        sta     $35
        lda     #$C0
        sta     $0660
        lda     #$FF
        sta     $0640
        bne     player_ladder_exit
player_ladder_clear_vel:  lda     #$00
        sta     $0680
player_ladder_exit:  jsr     weapon_set_base_type
        rts

player_ladder_fire_weapon:  jsr     player_update_facing
        jsr     fire_weapon_dispatch
        bcc     player_ladder_fire_done
        jmp     player_ladder_check_input

player_ladder_fire_done:  jmp     player_ladder_clear_vel

player_ladder_clear_anim:
        lda     $06A0             ; animation state
        cmp     #$03
        bne     player_ladder_clear_rts
        lda     #$00
        sta     $0680             ; clear Y velocity sub-pixel
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
player_check_fire_weapon:  lda     $23
        and     #$02
        bne     player_fire_weapon
        lda     #$00
        sta     $AB
        beq     player_check_ladder_rts
player_fire_weapon:  jsr     fire_weapon_dispatch ; call weapon fire handler
player_check_ladder_rts:  lda     $35
        bne     player_check_ladder_snap
player_fire_rts:  rts

player_check_ladder_snap:  lda     $23
        and     #$30
        beq     player_fire_rts
        ora     $35
        cmp     #$11
        beq     player_fire_rts
        cmp     #$2E
        beq     player_fire_rts
        lda     $0460
        sta     $2E
        and     #$F0
        ora     #$08
        sec
        sta     $0460
        sbc     $2E
        bcc     player_snap_left
        sta     $00
        jsr     scroll_right_handler
        jmp     player_snap_update_facing

player_snap_left:  eor     #$FF
        clc
        adc     #$01
        sta     $00
        jsr     scroll_left_handler
player_snap_update_facing:  lda     $0420
        eor     #$40
        sta     $0420
        jsr     weapon_set_base_type
        pla
        pla
        jmp     player_state_ladder_idle

; =============================================================================
; player_update_facing -- Player Facing Direction — update sprite flip from D-pad input ($87F2)
; =============================================================================
player_update_facing:  lda     $23
        and     #$C0
        beq     player_facing_rts
        lda     $0420
        and     #$BF
        sta     $0420
        lda     $23
        and     #$40
        eor     #$40
        ora     $0420
        sta     $0420
player_facing_rts:  rts

; =============================================================================
; player_set_max_speed -- Player Speed Control — max speed, acceleration, deceleration ($880D)
; =============================================================================
player_set_max_speed:  ldx     $2C      ; player state index for speed table
        lda     max_speed_hi_table,x
        sta     $0600
        lda     max_speed_lo_table,x
        sta     $0620
        lda     $3D
        cmp     #$03
        bne     player_check_accel_start
        lda     $2C
        cmp     #$06
        beq     player_check_accel_start
        lda     #$00
        sta     $0620
        sta     $0600
player_check_accel_start:  lda     $40
        bmi     player_check_facing_change
        lda     $3E
        ora     $3F
        beq     player_handle_conveyor
        bne     player_decelerate
player_check_facing_change:  lda     $0420
        and     #$40
        cmp     $42
        beq     player_accelerate
player_decelerate:  ldx     #$00
        lda     $2C
        cmp     #$06
        beq     player_apply_decel
        inx
        lda     $23
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
        sta     $0620
        lda     $3F
        sta     $0600
        jmp     player_handle_conveyor

player_accelerate:  sec
        lda     $0620
        sbc     $3E
        lda     $0600
        sbc     $3F
        bcc     player_decelerate
        lda     $0620
        sta     $3E
        lda     $0600
        sta     $3F
player_set_face_dir:  lda     $0420
        and     #$40
        sta     $42
player_handle_conveyor:  lda     $40
        bpl     player_conveyor_check
        rts

player_conveyor_check:  and     #$0F
        beq     player_no_conveyor
        lda     $0420
        and     #$40
        cmp     $AF
        beq     player_conveyor_forward
        sec
        lda     $0620
        sbc     $4F
        sta     $0620
        lda     $0600
        sbc     $50
        sta     $0600
        bcc     player_conveyor_reverse
        lda     $0420
        and     #$40
        sta     $42
        rts

player_conveyor_reverse:  lda     $0620
        eor     #$FF
        adc     #$01
        sta     $0620
        lda     $0600
        eor     #$FF
        adc     #$00
        sta     $0600
        lda     $AF
        sta     $42
        rts

player_conveyor_forward:  clc
        lda     $0620
        adc     $4F
        sta     $0620
        lda     $0600
        adc     $50
        sta     $0600
        lda     $AF
        sta     $42
        rts

player_no_conveyor:  lda     $3F
        ora     $3E
        beq     player_conveyor_idle
        rts

player_conveyor_idle:  lda     $0420
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
player_horiz_movement:  ldx     $0440
        stx     $2D
        ldy     $0460
        sty     $2E
        lda     $0480
        sta     $2F
        lda     #$00
        sta     $00
        lda     $42
        and     #$40
        beq     player_move_left_check
        cpx     $15
        bne     player_move_right
        cpy     #$EC
        bcc     player_move_right
        lda     #$02
        sta     $37
        jmp     player_scroll_right

player_move_right:  clc
        lda     $0480
        adc     $0620
        sta     $0480
        lda     $0460
        adc     $0600
        sta     $0460
        lda     $0440
        adc     #$00
        sta     $0440
        clc
        lda     $0460
        adc     #$08
        sta     jump_ptr
        lda     $0440
        adc     #$00
        sta     $09
        jsr     player_check_tile_ahead
        lda     $00
        beq     player_right_check_delta
        lda     #$00
        sta     $0480
        lda     jump_ptr
        and     #$0F
        sta     $00
        sec
        lda     $0460
        sbc     $00
        sta     $0460
        lda     $0440
        sbc     #$00
        sta     $0440
player_right_check_delta:  sec
        lda     $0460
        sbc     $2E
        sta     $00
        bpl     player_scroll_right
        clc
        eor     #$FF
        adc     #$01
        sta     $00
        jmp     player_scroll_left

player_move_left_check:  cpx     $14
        bne     player_move_left
        cpy     #$14
        bcs     player_move_left
        jmp     player_scroll_left

player_move_left:  sec
        lda     $0480
        sbc     $0620
        sta     $0480
        lda     $0460
        sbc     $0600
        sta     $0460
        lda     $0440
        sbc     #$00
        sta     $0440
        sec
        lda     $0460
        sbc     #$08
        sta     jump_ptr
        lda     $0440
        sbc     #$00
        sta     $09
        jsr     player_check_tile_ahead
        lda     $00
        beq     player_left_check_delta
        lda     #$00
        sta     $0480
        lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     $0460
        sta     $0460
        lda     $0440
        adc     #$00
        sta     $0440
player_left_check_delta:  sec
        lda     $2E
        sbc     $0460
        sta     $00
        bpl     player_scroll_left
        eor     #$FF
        clc
        adc     #$01
        sta     $00
player_scroll_right:  jsr     scroll_right_handler
        jsr     player_ground_collision
        rts

player_scroll_left:  jsr     scroll_left_handler
        jsr     player_ground_collision
        rts

player_check_tile_ahead:  lda     #$02
        sta     $01
tile_check_loop:  ldx     $01
        clc
        lda     $04A0
        adc     tile_y_offset_table,x
        sta     $0A
        lda     $F9
        adc     tile_y_page_table,x
        sta     $0B
        jsr     lookup_cached_tile
        ldx     $01
        lda     $00
        sta     $32,x
        dec     $01
        bpl     tile_check_loop
        lda     #$00
        sta     $00
        ldx     #$02
tile_eval_loop:  ldy     $32,x
        lda     tile_type_flags,y
        bpl     tile_check_spike
        ldy     #$02
        sty     $37
        bne     tile_combine_result
tile_check_spike:  cmp     #$03
        bne     tile_combine_result
        ldy     $4B
        bne     tile_combine_result
        lda     #$00
        sta     $2C
        jmp     boss_death_sequence

tile_combine_result:  ora     $00
        sta     $00
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
player_ground_collision:  lda     $0460
        sta     jump_ptr
        lda     $0440
        sta     $09
        lda     #$02
        sta     $01
ground_tile_loop:  ldx     $01
        clc
        lda     $04A0
        adc     tile_y_offset_table,x
        sta     $0A
        lda     $F9
        adc     tile_y_page_table,x
        sta     $0B
        jsr     lookup_tile_from_map
        ldx     $01
        lda     $00
        sta     $32,x
        dec     $01
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
        lda     $0640
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
        stx     $2B
        lda     #$0E
        jsr     spawn_entity_from_parent
        bcs     ground_set_params
        lda     $0430,y
        and     #$F0
        sta     $0430,y
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
        sta     $01
        ldx     #$02
ground_calc_platform_dir:  lda     $32,x
        cmp     #$02
        bne     ground_shift_platform
        lda     $01
        ora     $35
        sta     $35
ground_shift_platform:  asl     $01
        dex
        bpl     ground_calc_platform_dir
        sec
        lda     $04C0
        sbc     $0660
        lda     $04A0
        sbc     $0640
        ldx     $0640
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
        lda     $00
        cmp     #$02
        bne     ground_collision_rts
        lda     $0640
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
player_vertical_physics:  lda     $04A0
        sta     $2E
        lda     $04C0
        sta     $2F
        lda     #$00
        sta     $00
        lda     $0640
        bpl     player_apply_gravity
        dec     $00
player_apply_gravity:  sec
        lda     $04C0
        sbc     $0660
        sta     $04C0
        lda     $04A0
        sbc     $0640
        sta     $04A0
        tax
        lda     $F9
        sbc     $00
        sta     $F9
        cpx     #$04
        bcs     player_check_fall_limit
        lda     $2C
        cmp     #$09
        beq     player_set_scroll_trigger
        cmp     #$0A
        bne     player_gravity_falling
player_set_scroll_trigger:  lda     #$01
        sta     $37
        bne     player_gravity_falling
player_check_fall_limit:  cpx     #$E8
        bcc     player_gravity_falling
        lda     $F9
        bmi     player_gravity_falling
        lda     #$03
        sta     $37
player_gravity_falling:  lda     $0640
        bmi     player_gravity_rising
        sec
        lda     $04A0
        sbc     #$0C
        sta     $0A
        lda     $F9
        sbc     #$00
        sta     $0B
        jsr     player_floor_tile_check
        lda     $00
        beq     player_apply_gravity_sub
        lda     #$00
        sta     $04C0
        lda     $0A
        and     #$0F
        eor     #$0F
        sec
        adc     $04A0
        sta     $04A0
player_gravity_stop:  lda     #$00
        sta     $0660
        sta     $0640
player_apply_gravity_sub:  sec
        lda     $0660
        sbc     $30
        sta     $0660
        lda     $0640
        sbc     $31
        sta     $0640
        bpl     player_gravity_rts
        cmp     #$F4
        bcs     player_gravity_rts
        lda     #$00
        sta     $0660
        lda     #$F4
        sta     $0640
player_gravity_rts:  rts

player_gravity_rising:  clc
        lda     $04A0
        adc     #$0C
        sta     $0A
        lda     $F9
        adc     #$00
        sta     $0B
        jsr     player_floor_tile_check
        jsr     check_platform_collision
        lda     $00
        bne     player_ceiling_snap
        bcs     player_ceiling_set_flag
        bcc     player_apply_gravity_sub
player_ceiling_snap:  lda     #$00
        sta     $04C0
        lda     $04A0
        pha
        lda     $0A
        and     #$0F
        sta     $04A0
        pla
        sec
        sbc     $04A0
        sta     $04A0
        lda     $F9
        sbc     #$00
        sta     $F9
        jmp     player_gravity_stop

player_ceiling_set_flag:  lda     #$01
        sta     $00
        rts

; =============================================================================
; player_floor_tile_check -- Player Floor Tile Check — scan floor tiles for collision type ($8C6A)
; =============================================================================
player_floor_tile_check:  lda     #$01
        sta     $01
floor_tile_loop:  ldx     $01
        clc
        lda     $0460
        adc     floor_x_offset_table,x
        sta     jump_ptr
        lda     $0440
        adc     floor_x_page_table,x
        sta     $09
        jsr     lookup_cached_tile
        ldx     $01
        lda     $00
        sta     $32,x
        dec     $01
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
        ldy     $4B
        bne     floor_check_done
        lda     #$00
        sta     $2C
        jmp     boss_death_sequence

floor_check_done:  dex
        bpl     floor_tile_eval
        lda     $32
        ora     $33
        and     #$01
floor_store_result:  sta     $00
        lda     $35
        beq     floor_tile_rts
        cmp     #$01
        beq     floor_set_scroll_trigger
        ldx     $F9
        bpl     floor_tile_rts
        lda     $23
        and     #$30
        beq     floor_tile_rts
        ldx     #$01
        stx     $37
floor_set_scroll_trigger:  sta     $00
floor_tile_rts:  rts

floor_x_offset_table:  .byte   $07,$F9
floor_x_page_table:  .byte   $00,$FF
floor_conveyor_type_table:  .byte   $01,$02,$80 ; conveyor belt direction per tile

; =============================================================================
; check_platform_collision -- Platform Collision — scan entity list for rideable platforms ($8CF4)
; =============================================================================
check_platform_collision:  sec
        lda     $0460
        sbc     $1F
        sta     jump_ptr
        clc
        lda     $2E
        adc     #$0C
        sta     $09
        lda     $A9
        .byte   $C9
platform_scan_start:  ora     #$90
        asl     a
        ldx     #$02
platform_scan_secondary:  lda     $05A0,x
        bne     platform_check_secondary
platform_scan_next:  dex
        bpl     platform_scan_secondary
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
        lda     $0470,x
        sbc     $1F
        sta     $0C
        sec
        sbc     jump_ptr
        bcs     platform_check_range
        eor     #$FF
        adc     #$01
platform_check_range:  cmp     $0160,x
        bcs     platform_skip_primary
        lda     $04B0,x
        cmp     $09
        bcc     platform_skip_primary
        lda     $0170,x
        cmp     $0A
        beq     platform_check_type
        bcs     platform_skip_primary
platform_check_type:  lda     $0410,x
        cmp     #$13
        bne     platform_land_on
        inc     $04F0,x
platform_land_on:  sec
        lda     $0170,x
        sbc     #$0C
        sta     $04A0
        lda     $F9
        sbc     #$00
        sta     $F9
        lda     #$00
        sta     $04C0
        sta     $0660
        lda     #$FF
        sta     $0640
        lda     #$01
        sta     $40
        lda     $0430,x
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
        sbc     $1F
        sta     $0C
        sec
        sbc     jump_ptr
        bcs     platform_sec_check_range
        eor     #$FF
        adc     #$01
platform_sec_check_range:  cmp     $05A0,x
        bcs     platform_not_found
        lda     $04A2,x
        cmp     $09
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
        sta     $04A0
        lda     $F9
        sbc     #$00
        sta     $F9
        lda     #$00
        sta     $04C0
        sta     $0660
        lda     #$FF
        sta     $0640
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
scroll_right_handler:  sec
        lda     $0460
        sbc     $1F
        cmp     #$80                    ; check if player past midpoint
        bcs     scroll_right_exec
        rts

scroll_right_exec:  clc
        lda     $1F
        pha
        adc     $00
        sta     $1F
        lda     $20
        adc     #$00
        sta     $20
        cmp     $15
        bne     scroll_right_clamp
        sec
        lda     $00
        sbc     $1F
        sta     $00
        lda     #$00
        sta     $1F
        sta     $1E
scroll_right_clamp:  pla
        and     #$03
        adc     $00
        lsr     a
        lsr     a
        sta     $01
        beq     scroll_right_rts
        clc
        lda     $18
        sta     jump_ptr
        adc     $01
        sta     $18
        lda     $19
        sta     $09
        adc     #$00
        sta     $19
        clc
        lda     $16
        adc     $01
        sta     $16
        lda     $17
        adc     #$00
        sta     $17
scroll_right_column_loop:  jsr     column_data_copy ; copy column tile data to buffer
        inc     $1A
        lda     $1A
        and     #$3F
        sta     $1A
        clc
        lda     jump_ptr
        adc     #$01
        sta     jump_ptr
        lda     $09
        adc     #$00
        sta     $09
        dec     $01
        bne     scroll_right_column_loop
scroll_right_rts:  rts

; =============================================================================
; scroll_left_handler -- Scroll Left Handler — shift viewport left, update columns ($8E65)
; =============================================================================
scroll_left_handler:  sec
        lda     $0460
        sbc     $1F
        cmp     #$80
        bcc     scroll_left_exec
        rts

scroll_left_exec:  sec
        lda     $1F
        pha
        sbc     $00
        sta     $1F
        lda     $20
        sbc     #$00
        sta     $20
        ldx     $14
        dex
        cpx     $20
        bne     scroll_left_calc_columns
        inc     $20
        clc
        lda     $00
        adc     $1F
        sta     $00
        lda     #$00
        sta     $1F
        sta     $1E
scroll_left_calc_columns:  clc
        pla
        eor     #$FF
        and     #$03
        adc     $00
        lsr     a
        lsr     a
        sta     $01
        beq     scroll_left_rts
        sec
        lda     $16
        sta     jump_ptr
        sbc     $01
        sta     $16
        lda     $17
        sta     $09
        sbc     #$00
        sta     $17
        sec
        lda     $18
        sbc     $01
        sta     $18
        lda     $19
        sbc     #$00
        sta     $19
scroll_left_column_loop:  jsr     column_data_copy ; copy column tile data to buffer
        dec     $1A
        lda     $1A
        and     #$3F
        sta     $1A
        sec
        lda     jump_ptr
        sbc     #$01
        sta     jump_ptr
        lda     $09
        sbc     #$00
        sta     $09
        dec     $01
        bne     scroll_left_column_loop
scroll_left_rts:  rts

; =============================================================================
; transition_screen_left -- Screen Transition Left — full room scroll to previous screen ($8EDD)
; =============================================================================
transition_screen_left:  jsr     reset_entity_slots ; clear all entities for new room
        ldx     $14
        dex
        stx     $15
        dec     $38
        ldy     $38
        jsr     get_screen_boundary
        tya
        and     #$1F
        sta     $14
        txa
        sec
        sbc     $14
        sta     $14
        lda     $15
        jsr     render_full_nametable
        dec     $0440
        lda     $38
        sta     $FE
        jsr     transition_scroll_setup
        dec     $20
        sec
        lda     $16
        sbc     #$40
        sta     $16
        lda     $17
        sbc     #$00
        sta     $17
        sec
        lda     $18
        sbc     #$40
        sta     $18
        lda     $19
        sbc     #$00
        sta     $19
        jsr     wait_for_vblank
        sec
        lda     $15
        sbc     #$01
        jsr     render_full_nametable
        lda     #$00
        sta     $F9
        lda     #$00
        sta     $42
        jsr     entity_spawn_scan
        rts

; =============================================================================
; transition_screen_right -- Screen Transition Right — full room scroll to next screen ($8F39)
; =============================================================================
transition_screen_right:  jsr     reset_entity_slots ; clear all entities for new room
        ldx     $15
        inx
        txa
        pha
        jsr     render_full_nametable
        inc     $0440
        lda     $37
        and     #$01
        bne     transition_right_scroll
        lda     #$18
        sta     $FD
        lda     #$00
        sta     $FE
transition_right_attr_loop:  ldx     $2A
        lda     $20
        cmp     stage_min_screen_table,x
        bcc     transition_right_scroll
        lda     $FD
        and     #$07
        bne     transition_right_attr_step
        lda     #$34
        jsr     bank_switch_enqueue
        lda     $20
        sta     $09
        lda     #$F0
        sta     jump_ptr
        lda     $FD
        asl     a
        adc     stage_attr_base_table,x
        sta     $0A
        jsr     metatile_render
        jsr     metatile_attr_update
        lda     #$80
        sta     $54
        inc     $51
transition_right_attr_step:  jsr     wait_for_vblank
        dec     $FD
        bpl     transition_right_attr_loop
        lda     #$FE
        jsr     bank_switch_enqueue
transition_right_scroll:  lda     $38
        sta     $FE
        inc     $FE
        jsr     transition_scroll_setup
        inc     $20
        jsr     wait_for_vblank
        clc
        lda     $15
        adc     #$02
        jsr     render_full_nametable
        inc     $38
        ldy     $38
        jsr     get_screen_boundary
        tya
        and     #$1F
        sta     $14
        pla
        tax
        clc
        adc     $14
        sta     $15
        stx     $14
        clc
        lda     $18
        adc     #$40
        sta     $18
        lda     $19
        adc     #$00
        sta     $19
        clc
        lda     $16
        adc     #$40
        sta     $16
        lda     $17
        adc     #$00
        sta     $17
        lda     #$00
        sta     $F9
        lda     $37
        and     #$01
        bne     transition_right_done
        lda     #$00
        sta     $FD
        sta     $FE
transition_right_col_loop:  ldx     $2A
        lda     $20
        cmp     stage_min_screen_table,x
        bcc     transition_right_done
        cmp     stage_max_screen_table,x
        bne     transition_right_col_step
        lda     #$0B
        jsr     bank_switch_enqueue
        lda     $2A
        cmp     #$0B
        beq     transition_right_col_step
        cmp     #$08
        bcs     transition_right_done
transition_right_col_step:  lda     $FD
        and     #$07
        bne     transition_right_wait_frame
        lda     #$34
        jsr     bank_switch_enqueue
        lda     $20
        sta     $09
        lda     #$00
        sta     jump_ptr
        lda     $FD
        asl     a
        adc     stage_attr_base_table,x
        sta     $0A
        jsr     metatile_render
        ldx     $2A
        lda     stage_attr_mode_table,x
        jsr     metatile_attr_update
        inc     $54
        inc     $51
transition_right_wait_frame:  jsr     wait_for_vblank
        inc     $FD
        lda     $FD
        cmp     #$19
        bne     transition_right_col_loop
        lda     #$FE
        jsr     bank_switch_enqueue
transition_right_done:  lda     #$40
        sta     $42
        jsr     entity_spawn_scan
        rts

stage_attr_base_table:  .byte   $60,$40,$40,$40,$40,$40,$40,$40 ; attribute base offset per stage
        .byte   $00,$00,$80,$80,$00,$80
stage_attr_mode_table:  .byte   $00,$55,$AA,$00,$00,$55,$00,$AA ; attribute mode per stage
        .byte   $00,$00,$00,$00,$00,$00
stage_min_screen_table:  .byte   $15,$13,$15,$13,$15,$11,$13,$11 ; minimum screen index per stage
        .byte   $00,$00,$26,$25,$00,$1E
stage_max_screen_table:  .byte   $17,$15,$17,$15,$17,$13,$15,$13 ; maximum screen index per stage
        .byte   $00,$27,$27,$26,$00,$1F

; =============================================================================
; render_full_nametable -- Full-Screen Nametable Render — upload all 32 columns to PPU ($907D)
; =============================================================================
render_full_nametable:  ldx     #$00
        stx     jump_ptr
        lsr     a
        ror     jump_ptr
        lsr     a
        ror     jump_ptr
        clc
        adc     #$85
        sta     $09
        lda     $1A
        pha
        lda     #$00
        sta     $1A
nametable_column_loop:  jsr     column_data_copy
        inc     jump_ptr
        inc     $1A
        jsr     column_data_copy
        lda     jump_ptr
        pha
        lda     $09
        pha
        lda     $F7
        and     #$80
        beq     nametable_direct_upload
        jsr     wait_for_vblank
        jmp     nametable_advance_column

nametable_direct_upload:  lda     $1B
        jsr     ppu_buffer_transfer
nametable_advance_column:  clc
        pla
        sta     $09
        pla
        sta     jump_ptr
        inc     jump_ptr
        inc     $1A
        lda     jump_ptr
        and     #$3F
        bne     nametable_column_loop
        pla
        sta     $1A
        rts

; =============================================================================
; transition_scroll_setup -- Transition Scroll Setup — configure and execute scroll animation ($90C9)
; =============================================================================
transition_scroll_setup:  lda     $37
        and     #$01
        beq     transition_scroll_horizontal
        jmp     transition_scroll_vertical

transition_scroll_horizontal:  jsr     transition_load_palette
        lda     #$00
        sta     $3E
        sta     $3F
        sta     $FD
        ldy     #$3F
transition_scroll_frame_loop:  tya
        pha
        lda     #$01
        clc
        lda     $1F
        adc     #$04
        sta     $1F
        clc
        lda     $0480
        adc     #$C0
        sta     $0480
        lda     $0460
        adc     #$00
        sta     $0460
        lda     $A9
        cmp     #$01
        bne     transition_scroll_render
        jsr     vert_scroll_update_entity
transition_scroll_render:  jsr     render_all_sprites
        jsr     scroll_column_render
        jsr     wait_for_vblank
        pla
        tay
        dey
        bne     transition_scroll_frame_loop
        sty     $1F
        rts

transition_load_palette:  ldx     $2A
        cpx     #$03
        bne     transition_palette_check
        ldy     $38
        cpy     #$04
        beq     transition_palette_rts
transition_palette_check:  ldy     stage_palette_offset_table,x
        beq     transition_palette_rts
        lda     stage_palette_count,x
        sta     $FD
        lda     stage_palette_src_index,x
        tax
transition_palette_copy:  lda     stage_palette_data,x
        sta     $0356,y
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
transition_scroll_vertical:  lda     $37
        lsr     a
        bne     vert_scroll_setup
        ldx     #$09
        stx     $2C
        pha
        jsr     weapon_set_base_type
        pla
vert_scroll_setup:  tax
        lda     vert_scroll_y_start,x
        sta     $39
        lda     vert_scroll_y_init,x
        sta     $22
        lda     #$00
        sta     $FD
vert_scroll_frame_loop:  txa
        pha
        jsr     render_all_sprites
        jsr     scroll_y_update
        jsr     scroll_column_render
        jsr     wait_for_vblank
        pla
        tax
        lda     $A9
        cmp     #$01
        bne     vert_scroll_update_pos
        jsr     vert_scroll_update_entity
vert_scroll_update_pos:  clc
        lda     $04C0
        adc     vert_scroll_sub_step,x
        sta     $04C0
        lda     $04A0
        adc     vert_scroll_pixel_step,x
        sta     $04A0
        lda     $F9
        adc     vert_scroll_page_step,x
        sta     $F9
        clc
        lda     $22
        adc     vert_scroll_y_delta,x
        sta     $22
        clc
        lda     $39
        adc     vert_scroll_y_step,x
        sta     $39
        bmi     vert_scroll_finish
        cmp     #$3C
        beq     vert_scroll_finish
        bne     vert_scroll_frame_loop
vert_scroll_finish:  lda     #$00
        sta     $21
        sta     $22
        sta     $04C0
        jsr     render_all_sprites
        rts

vert_scroll_update_entity:  lda     $0460
        sta     $0462
        lda     $0440
        sta     $0442
        lda     $04A0
        sta     $04A2
        lda     #$00
        sta     $0682
        rts

vert_scroll_y_start:  .byte   $3B,$00   ; vertical scroll start positions
vert_scroll_y_step:  .byte   $FF,$01
vert_scroll_sub_step:  .byte   $BF,$41
vert_scroll_pixel_step:  .byte   $03,$FC
vert_scroll_y_delta:  .byte   $FC,$04
vert_scroll_y_init:  .byte   $EF,$00
vert_scroll_page_step:  .byte   $00,$FF

; =============================================================================
; reset_entity_slots -- Reset Entity Slots — clear all entity data, preserve boss if active ($9220)
; =============================================================================
reset_entity_slots:  ldx     #$00
        lda     $A9
        cmp     #$06                    ; state 6 = boss fight active
        beq     reset_entity_save_boss
        cmp     #$01
        bne     reset_entity_clear
reset_entity_save_boss:  ldx     $0422
reset_entity_clear:  txa
        pha
        lda     #$00
        ldx     #$1F
reset_entity_clear_loop:  sta     $0420,x ; clear entity flags (deactivate)
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
        lda     $0460
        sbc     $1F
        sta     $2D
        lda     $AA
        beq     entity_ai_normal_loop
        cmp     #$04
        bne     entity_ai_special_loop
entity_ai_normal_loop:  ldx     #$10    ; entity slot 16 = first enemy slot
        stx     $2B
entity_ai_normal_step:  lda     $0420,x ; check entity active flag (bit 7)
        bpl     entity_ai_next_normal
        sec
        lda     $0460,x
        sbc     $1F
        sta     $2E
        lda     $0440,x
        sbc     $20
        sta     $2F
        ldy     $0400,x
        lda     entity_ai_ptr_lo,y
        sta     jump_ptr
        lda     entity_ai_ptr_hi,y
        sta     $09
        lda     #$92
        pha
        lda     #$98
        pha
        jmp     (jump_ptr)

entity_ai_next_normal:  inc     $2B
        ldx     $2B
        cpx     #$20
        bne     entity_ai_normal_step
        rts

entity_ai_special_loop:  ldx     #$10
        stx     $2B
entity_ai_special_step:  lda     $0420,x ; check entity active flag
        bpl     entity_ai_next_special
        sec
        lda     $0460,x
        sbc     $1F
        sta     $2E
        lda     $0440,x
        sbc     $20
        sta     $2F
        lda     #$92
        pha
        lda     #$E6
        pha
        ldy     $0400,x
        lda     entity_ai_bank_table,y
        bne     entity_ai_special_indirect
        ldy     $0400,x
        lda     entity_ai_ptr_lo,y
        sta     jump_ptr
        lda     entity_ai_ptr_hi,y
        sta     $09
        jmp     (jump_ptr)

entity_ai_special_indirect:  tay
        dey
        lda     entity_special_ai_ptr_lo,y
        sta     jump_ptr
        lda     entity_special_ai_ptr_hi,y
        sta     $09
        jmp     (jump_ptr)

entity_ai_next_special:  inc     $2B
        ldx     $2B
        cpx     #$20
        bne     entity_ai_special_step
        rts

; =============================================================================
; entity_ai_ptr_lo -- Entity AI Pointer Table — 128 entries, low/high/bank for each type ($92F0)
; =============================================================================
entity_ai_ptr_lo:  .byte   $8D,$8D,$23,$55,$D7,$4E,$71,$75 ; entity AI routine pointer (low bytes)
        .byte   $E5,$6F,$76,$2B,$2F,$8F,$2B,$E3
        .byte   $43,$65,$73,$5B,$90,$CE,$81,$22
        .byte   $2B,$D1,$36,$54,$69,$F4,$ED,$46
        .byte   $7E,$85,$A6,$C2,$2B,$5A,$AB,$B8
        .byte   $C5,$2A,$F1,$0D,$2E,$D7,$D7,$D3
        .byte   $F2,$EA,$C3,$EC,$4E,$2B,$89,$A4
        .byte   $12,$8F,$96,$2B,$30,$4C,$A3,$2B
        .byte   $49,$49,$81,$81,$A1,$E0,$1B,$FA
        .byte   $8A,$97,$0B,$12,$12,$2B,$F0,$21
        .byte   $96,$D0,$5C,$69,$6D,$71,$E5,$D7
        .byte   $41,$E3,$2B,$20,$2B,$4B,$67,$2B
        .byte   $2B,$2B,$18,$55,$91,$7A,$B7,$CE
        .byte   $2B,$FE,$32,$EF,$2B,$25,$2B,$2B
        .byte   $98
        lda     $3030
        adc     mecha_dragon_debris_loop_end,y
        lda     ($A9),y
        lda     ($A9),y
        lda     #$08
        php
        php
        .byte   $24
entity_ai_ptr_hi:  sty     $94,x
        sta     $95,x
        sta     $96,x
        stx     $96,y
        stx     $97,y
        .byte   $97,$98,$98,$98,$98,$98,$9A,$9A
        .byte   $9A,$9C,$9C,$9D,$9E,$9F,$98,$9F
        .byte   $A1,$A1,$A1,$A2,$A3,$A4,$A4
        ldy     $A4
        ldy     $98
        lda     $A5
        lda     $A5
        ldx     $A6
        .byte   $A7,$A7,$A7,$A7,$A7,$A7,$A8,$A9
        .byte   $A9,$AA,$98,$AB,$AB,$AC,$AC,$AC
        .byte   $98,$AD,$AD,$AD,$98,$AE,$AE,$AF
        .byte   $AF,$AF,$AF,$B0,$B0,$B1,$B1,$B2
        .byte   $B2,$B2,$98,$B2,$B4,$B4,$B4,$B5
        .byte   $B5,$B5,$B5,$B5,$A7,$B6,$B6,$98
        .byte   $B7,$98,$B7,$B7,$98,$98,$98,$B8
        .byte   $B8,$B8,$B9,$B9,$B9,$98,$B9,$BA
        .byte   $BA,$98,$BB,$98,$98,$BB,$BB,$BC
        .byte   $BC,$BC,$BC,$BC,$BC,$BC,$BC,$BC
        .byte   $BC,$BD,$BD,$BD,$BD
entity_ai_bank_table:  .byte   $01,$02,$01,$00,$01,$00,$01,$00 ; bank for each AI routine (0=local)
        .byte   $01,$00,$01,$01,$01,$01,$00,$02
        .byte   $02,$02,$03,$04,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$00,$01
        .byte   $00,$01,$01,$08,$01,$00,$00,$00
        .byte   $00,$01,$01,$01,$01,$00,$02,$00
        .byte   $01,$01,$01,$01,$01,$01,$01,$00
        .byte   $01,$00,$01,$01,$01,$01,$05,$01
        .byte   $06,$07,$00,$00,$01,$01,$01,$00
        .byte   $01,$01,$00,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$01,$00,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$01
        .byte   $01,$01,$01,$00,$01,$01,$01,$01
        .byte   $01,$01,$01,$01,$01,$00,$00,$00
        .byte   $00,$01,$01,$01,$01,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
entity_special_ai_ptr_lo:  .byte   $B3,$AF,$D8,$F1,$0A,$23,$23,$7C ; special AI pointer (low bytes)
        .byte   $B5,$B5,$B5,$B5,$B5,$B5,$B5
entity_special_ai_ptr_hi:  .byte   $EF,$EF,$ED,$ED,$EE,$EE,$EE,$EE ; special AI pointer (high bytes)
        .byte   $EE,$EE,$E6,$EE,$EE,$EE,$BD
met_ai_preamble:
        cpx     #$04
        bne     met_update_timer
        sta     $0680,x
        lda     $0110,x
        bne     met_reset_state

; =============================================================================
; met_init_shoot -- Enemy AI: Met (Hard Hat) — hide/shoot pattern ($949A)
; =============================================================================
met_init_shoot:
        lda     #$01
        sta     $0110,x
        lda     #$14
        sta     $04E0,x
        lda     #$05
        sta     $06A0,x
        lda     $4A
        and     #$03
        beq     met_calc_aim
        lda     #$02
        sta     $09
        lda     #$0C
        sta     jump_ptr
        jsr     calc_entity_velocity
        ldx     $2B
        jmp     met_update_timer

met_calc_aim:  jsr     entity_face_player
        lda     $DA01
        sta     $0600,x
        lda     $DA02
        sta     $0620,x
        lda     $DA21
        sta     $0640,x
        lda     $DA22
        sta     $0660,x
        bne     met_update_timer
met_reset_state:
        lda     #$00
        sta     $06A0,x
        sta     $0110,x
        lda     $4A
        and     #$01
        tay
        lda     met_delay_table,y
        sta     $04E0,x
        lda     #$00
        sta     $0620,x
        sta     $0600,x
        lda     #$3C
        sta     $0660,x
        lda     #$FF
        sta     $0640,x
met_update_timer:  dec     $04E0,x
        lda     $06A0,x
        cmp     #$04
        bcc     met_apply_physics
        bne     met_check_state_4
        lda     #$00
        sta     $06A0,x
        beq     met_apply_physics
met_check_state_4:  cmp     #$07
        bne     met_apply_physics
        lda     #$00
        sta     $0680,x
met_apply_physics:  jsr     apply_entity_physics
        rts

met_delay_table:  .byte   $19,$4A                         ; Met hide/shoot delay timings
anko_spawner_ai_entry:
        lda     $04E0,x
        bne     anko_spawner_dec_timer
        ldy     #$0F
        lda     #$02
        sta     $01
        lda     #$01
        sta     $00

; =============================================================================
; anko_spawner_scan -- Enemy AI: Anko spawner (type $02) — creates Shrink-AI entities ($9532)
; Mislabeled by annotation scripts as "Telly". Actually type $02 (Anko sub-part).
; =============================================================================
anko_spawner_scan:  jsr     find_entity_scan
        bcs     anko_spawner_create
        dec     $01
        beq     anko_spawner_set_timer
        dey
        bne     anko_spawner_scan
        bne     anko_spawner_set_timer
anko_spawner_create:  lda     #$01
        jsr     spawn_entity_from_parent
        lda     #$31
        bne     anko_spawner_store_timer
anko_spawner_set_timer:  lda     #$62
anko_spawner_store_timer:  sta     $04E0,x
anko_spawner_dec_timer:
        dec     $04E0,x
        jsr     apply_simple_physics
        rts

; =============================================================================
; anko_seg_ai -- Enemy AI: Anko segment (type $03) — spawns M-445 jellyfish ($9555)
; Mislabeled by annotation scripts as "Pipi". Actually type $03 (Anko sub-part).
; =============================================================================
anko_seg_entry:
        lda     $0620,x           ; check X velocity (sub)
        bne     anko_seg_track_parent
        lda     #$03
        jsr     check_entity_collision_scan
        bcc     anko_seg_track_parent
        rts
anko_seg_track_parent:
        lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04E0,x
        bne     anko_seg_dec_timer
        lda     #$03
        sta     $01
        lda     #$04
        jsr     find_entity_count_check
        bcs     anko_seg_set_timer
        lda     #$04
        jsr     spawn_entity_from_parent
        bcs     anko_seg_set_timer
        lda     $0110,x
        and     #$01
        tax
        clc
        lda     $0470,y
        adc     anko_seg_x_offset_table,x
        sta     $0470,y
        lda     $0450,y
        adc     anko_seg_x_page_table,x
        sta     $0450,y
        ldx     $2B
        inc     $0110,x
anko_seg_set_timer:  lda     #$4B
        sta     $04E0,x
anko_seg_dec_timer:  dec     $04E0,x
        ldy     #$17
        jsr     boss_set_palette
        rts

anko_seg_x_offset_table:  .byte   $50,$C8
anko_seg_x_page_table:  .byte   $00,$FF

; =============================================================================
; check_entity_collision_scan -- Entity Collision Scan — check overlap between entity pairs ($95B5)
; =============================================================================
check_entity_collision_scan:  sta     $00
        ldy     #$0F
collision_scan_loop:  jsr     find_entity_scan
        bcs     collision_scan_set_active
        lda     $0630,y
        beq     collision_scan_next
        lsr     $0420,x
        lda     #$00
        sta     a:$F0,x
        sec
        rts

collision_scan_next:  dey
        bne     collision_scan_loop
collision_scan_set_active:  lda     #$01
        sta     $0620,x
        clc
        rts

friender_ai_entry:
        lda     $0620,x
        bne     friender_check_timer
        sec
        lda     $04A0
        sbc     $04A0,x
        cmp     #$03
        bcc     friender_face_player
        cmp     #$FE
        bcc     friender_apply_physics
friender_face_player:
        jsr     entity_face_player
friender_check_timer:
        lda     $04E0,x
        bne     friender_dec_timer
        lda     #$0B
        sta     $04E0,x
        lda     $0110,x
        pha
        and     #$07
        tay
        lda     #$00
        sta     $0600,x
        sta     $0640,x
        lda     friender_x_speed_table,y
        sta     $0620,x
        lda     friender_y_speed_table,y
        sta     $0660,x
        pla
        pha
        cmp     #$04
        bcc     friender_update_direction
        cmp     #$0C
        bcs     friender_update_direction
        lda     $0660,x
        eor     #$FF
        adc     #$01
        sta     $0660,x
        lda     #$FF
        adc     #$00
        sta     $0640,x
friender_update_direction:  pla
        clc
        adc     #$01
        and     #$0F
        sta     $0110,x
friender_dec_timer:  dec     $04E0,x    ; decrement movement timer
friender_apply_physics:
        jsr     apply_entity_physics
        rts

friender_x_speed_table:  .byte   $17,$5E,$AD,$E3,$E3,$AD,$5E,$17 ; Friender X speed per animation frame
friender_y_speed_table:  .byte   $F5,$E3,$AD,$5E,$5E,$AD,$E3,$F5 ; Friender Y speed per animation frame
enemy_destroy_setup:
        lda     #$03
        sta     $00
enemy_destroy_scan:
        ldy     #$0F

; =============================================================================
; enemy_destroy_all -- Enemy Destroy — deactivate all child entities and self ($9654)
; =============================================================================
enemy_destroy_all:  jsr     find_entity_scan
        bcs     enemy_deactivate_self
        lda     #$00
        sta     $0430,y
        lda     #$FF
        sta     $0100,y
        dey
        bpl     enemy_destroy_all
enemy_deactivate_self:  lda     #$00
        sta     $0420,x
        lda     #$FF
        sta     a:$F0,x
        rts

; =============================================================================
; claw_spawner_ai -- Enemy AI: Claw spawner (type $07) — creates Claw variants ($9675)
; Mislabeled by annotation scripts as "Sniper". Actually type $07 (Claw).
; =============================================================================
claw_spawner_physics:
        jsr     apply_entity_physics_alt
        rts
claw_spawner_ai_entry:
        lda     $0620,x
        bne     claw_spawner_copy_pos
        lda     #$07
        jsr     check_entity_collision_scan
        bcc     claw_spawner_copy_pos
        rts
claw_spawner_copy_pos:
        lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04E0,x
        bne     claw_spawner_dec_timer
        lda     #$02
        sta     $01
        lda     #$08
        jsr     find_entity_count_check
        bcs     claw_spawner_set_timer
        lda     #$08
        jsr     spawn_entity_from_parent
        bcs     claw_spawner_set_timer
        lda     $0110,x
        and     #$01
        tax
        lda     $0470,y
        adc     claw_spawner_x_offset_tbl,x
        sta     $0470,y
        lda     $0450,y
        adc     claw_spawner_x_page_tbl,x
        sta     $0450,y
        ldx     $2B
        inc     $0110,x
claw_spawner_set_timer:  lda     #$5D
        sta     $04E0,x
claw_spawner_dec_timer:  dec     $04E0,x
        rts

claw_spawner_x_offset_tbl:  .byte   $30,$E0 ; Claw spawn X offset per direction
claw_spawner_x_page_tbl:  .byte   $00,$FF   ; Claw spawn X page per direction

; =============================================================================
; find_entity_count_check -- Find Entity Count — scan for entity type, check population limit ($96CF)
; =============================================================================
find_entity_count_check:  sta     $00
        ldy     #$0F
find_entity_count_loop:  jsr     find_entity_scan
        bcs     find_entity_count_ok
        dec     $01
        beq     find_entity_count_fail
        dey
        bne     find_entity_count_loop
        beq     find_entity_count_fail
find_entity_count_ok:  clc
        rts

find_entity_count_fail:  sec
        rts

blocky_ai_entry:
        lda     #$0B
        sta     $01
        lda     #$08
        sta     $02
        jsr     check_vert_tile_collision
        lda     $04E0,x
        bne     blocky_check_state
        lda     $00
        beq     blocky_apply_physics
        inc     $04E0,x
        lda     #$76
        sta     $0660,x           ; set fall velocity sub
        lda     #$03
        sta     $0640,x           ; set fall velocity high
        lda     $0420,x
        ora     #$04
        sta     $0420,x
        jsr     entity_face_player
        bne     blocky_apply_physics
blocky_check_state:
        cmp     #$03
        beq     blocky_check_land
        lda     $00
        beq     blocky_apply_physics
        lda     $04E0,x
        cmp     #$02
        beq     blocky_set_fall_vel
        lda     #$00
        sta     $0660,x
        lda     #$02
        sta     $0640,x
        inc     $04E0,x
        bne     blocky_apply_physics
blocky_set_fall_vel:  lda     #$C0
        sta     $0660,x
        lda     #$FF
        sta     $0640,x
        lda     #$00
        sta     $0600,x
        lda     #$A3
        sta     $0620,x
        inc     $04E0,x
        lda     $0420,x
        and     #$FB
        sta     $0420,x
        bne     blocky_apply_physics
blocky_check_land:  lda     #$0C
        lda     $00
        bne     blocky_apply_physics
        lda     #$00
        sta     $04E0,x
        sta     $0620,x
        sta     $0600,x
        lda     $0420,x
        ora     #$04
        sta     $0420,x
blocky_apply_physics:  jsr     apply_entity_physics
        rts

; =============================================================================
; tanishi_ai -- Enemy AI: Tanishi (type $0A) — snail, spawns bare form on hit ($9776)
; Mislabeled by annotation scripts as "Shotman". Actually type $0A (Tanishi).
; =============================================================================
tanishi_ai_entry:
        lda     #$07
        sta     $00
        jmp     enemy_destroy_scan
tanishi_ai_main:
        lda     $04E0,x
        bne     tanishi_state_check
        lda     #$0C
        sta     $02
        lda     $06A0,x
        cmp     #$02
        bcc     tanishi_hp_check
        lda     #$00
        sta     $06A0,x
tanishi_hp_check:
        lda     $06C0,x
        cmp     #$14
        beq     tanishi_check_facing
        lda     #$0B                    ; entity type $0B = Tanishi (bare/shell-less)
        jsr     spawn_entity_from_parent
        lda     $0430,y
        ora     #$04
        eor     #$40
        sta     $0430,y
        clc
        lda     $04A0,x
        adc     #$08
        sta     $04A0,x
        lda     #$01
        sta     $0600,x
        lda     #$47
        sta     $0620,x
        lda     #$03
        sta     $06E0,x
        lda     #$03
        sta     $06A0,x
        inc     $04E0,x
        bne     tanishi_check_facing
tanishi_state_check:
        lda     #$04
        sta     $02
        lda     $06A0,x
        cmp     #$05
        bcc     tanishi_check_facing
        lda     #$03
        sta     $06A0,x
tanishi_check_facing:  lda     $0420,x
        and     #$40
        beq     tanishi_facing_left
        clc
        lda     $0460,x
        adc     #$0C
        sta     jump_ptr
        lda     $0440,x
        adc     #$00
        jmp     tanishi_store_position

tanishi_facing_left:  sec
        lda     $0460,x
        sbc     #$0C
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
tanishi_store_position:  sta     $09
        lda     $04A0,x
        sta     $0A
        lda     #$00
        sta     $0B
        jsr     lookup_tile_from_map
        ldx     $2B
        lda     $00
        and     #$01
        bne     tanishi_flip_facing
        clc
        lda     $0A
        adc     $02
        sta     $0A
        jsr     lookup_tile_from_map
        ldx     $2B
        lda     $00
        and     #$01
        bne     tanishi_apply_physics
tanishi_flip_facing:  lda     $0420,x
        eor     #$40
        sta     $0420,x
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
        lda     $06A0,x
        cmp     #$09
        bcs     kerog_check_jump_state
        lda     #$01
        sta     $01
        lda     #$0D
        jsr     find_entity_count_check
        bcs     kerog_check_anim
        lda     #$09
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        jsr     kerog_apply_physics
kerog_check_jump_state:
        cmp     #$0A
        bne     kerog_apply_physics
        lda     $0680,x
        bne     kerog_apply_physics
        lda     #$02
        sta     $01
kerog_spawn_child_loop:  lda     #$0D    ; entity type $0D = Petit Kerog
        jsr     spawn_entity_from_parent
        bcs     kerog_check_anim
        ldx     $01
        lda     kerog_child_vel_x_sub,x
        sta     $0630,y
        lda     kerog_child_vel_x_hi,x
        sta     $0610,y
        ldx     $2B
        dec     $01
        bpl     kerog_spawn_child_loop
kerog_check_anim:  lda     $06A0,x
        cmp     #$08
        bne     kerog_apply_physics
        lda     #$00
        sta     $06A0,x
kerog_apply_physics:  jsr     entity_face_player
        jsr     apply_entity_physics_alt
        rts

kerog_child_vel_x_sub:  .byte   $15,$8D,$A2 ; Petit Kerog X velocity table
kerog_child_vel_x_hi:  .byte   $04,$02,$01,$A9,$00,$9D,$80,$06
        .byte   $A9,$03,$85
        ora     ($A9,x)
        .byte   $04
        sta     $02
        jsr     check_horiz_tile_collision
        lda     $0110,x
        bne     kerog_dec_timer
        lda     $00
        beq     petit_kerog_apply_physics
        lda     #$3E
        sta     $04E0,x
        inc     $06A0,x
        lda     #$00
        sta     $0620,x
        sta     $0600,x
        inc     $0110,x
        bne     petit_kerog_apply_physics
kerog_dec_timer:  dec     $04E0,x
        bne     petit_kerog_apply_physics
        dec     $06A0,x
        dec     $0110,x
        jsr     entity_face_player
        lda     #$A2
        sta     $0620,x
        lda     #$01
        sta     $0600,x
        lda     #$E6
        sta     $0620,x
        lda     #$04
        sta     $0640,x
petit_kerog_apply_physics:  jsr     apply_entity_physics
        rts

boss_ai_init_entry:
        lda     $0620,x
        bne     boss_countdown_dec
        lda     $04E0,x
        beq     boss_skip_palette
        ldy     #$02
        cmp     $06C0,x
        beq     boss_apply_palette
        ldy     #$05
boss_apply_palette:
        jsr     boss_set_palette
boss_skip_palette:
        lda     $06C0,x
        sta     $04E0,x
        lda     $0440,x
        sta     $0660,x
        jsr     apply_simple_physics
        lda     $06C0,x
        bne     die_expand_phase
        lda     #$A0
        sta     $0420,x
        lda     #$0F
        sta     $0400,x
        ldx     #$01
die_spawn_part_loop:  stx     $01
        lda     boss_debris_type,x
        jsr     find_entity_by_type
        bcs     die_spawn_part_next
        lda     #$00
        sta     $0430,y
        lda     #$FF
        sta     $0120,y
die_spawn_part_next:  ldx     $01
        dex
        bpl     die_spawn_part_loop
        ldx     $2B
        ldy     $0110,x
        lda     #$00
        sta     $013F,y
        sta     $0141,y
        sta     $013E,y
        sta     $0142,y
        lda     #$0E
        sta     $0620,x
        lda     #$06
        sta     $0600,x
die_expand_phase:  rts

boss_countdown_dec:
        dec     $0600,x
        php
        lda     $0620,x
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
        ldy     $0620,x
        lda     boss_debris_anim_table,y
        tay
die_expand_set_timer:  lda     #$09
        sta     $0600,x
        jsr     boss_set_palette
        lda     $0620,x
        cmp     #$06
        bcs     die_expand_check_done
        jsr     boss_spawn_debris
die_expand_check_done:  dec     $0620,x
        bne     die_expand_rts
        lsr     $0420,x
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
        ldx     $2B
        rts

boss_spawn_debris:  lda     #$04
        sta     $01
        lda     $0620,x
        asl     a
        asl     a
        adc     $0620,x
        sta     $02
        lda     $0660,x
        sta     $03
boss_debris_loop:  lda     #$06
        jsr     spawn_entity_from_parent
        bcs     boss_debris_done
        ldx     $02
        lda     boss_debris_y_table,x
        sta     $04B0,y
        lda     $03
        sta     $0450,y
        cmp     #$09
        php
        lda     boss_debris_x_table,x
        plp
        beq     boss_debris_set_pos
        sec
        sbc     #$20
boss_debris_set_pos:  sta     $0470,y
        sec
        sbc     $1F
        lda     $03
        sbc     $20
        beq     boss_debris_check_screen
        lda     #$00
        sta     $0430,y
boss_debris_check_screen:  ldx     $2B
        inc     $02
        dec     $01
        bpl     boss_debris_loop
boss_debris_done:  ldx     $2B
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
        lda     $04E0,x
        bne     atomic_fire_check_state
        lda     #$01
        sta     $06A0,x
        lda     #$70
        sta     $04E0,x
atomic_fire_check_state:  lda     $06A0,x
        cmp     #$04
        bcc     atomic_fire_update
        lda     #$00
        sta     $0680,x
atomic_fire_update:  dec     $04E0,x
        jsr     apply_simple_physics
        rts

        .byte   $A0,$02,$20,$8D,$99,$A9,$FF,$9D
        .byte   $20,$01,$5E,$20,$04,$60,$A9,$14
        .byte   $9D,$50,$01,$38,$BD,$40,$04,$E9
        .byte   $04,$A4,$2A,$C0,$07,$F0,$06,$38
        .byte   $BD,$40,$04,$E9,$1B
        sta     $00
        tay
        lda     crashman_path_offset_table,y
        sta     $01
        clc
        adc     $04E0,x
        tay
        lda     $00
        cmp     #$03
        bcs     crashman_path_wily
        lda     crashman_path_data,y
        sta     $02
        lda     crashman_path_entry,y
        jmp     crashman_check_axis

; =============================================================================
; crashman_path_wily -- Boss AI: Crashman — pathfinding with bounce patterns ($9AA8)
; =============================================================================
crashman_path_wily:  lda     crashman_wily_path_data,y
        sta     $02
        lda     crashman_wily_path_entry,y
crashman_check_axis:  and     #$01
        bne     crashman_check_x
        lda     $04A0,x
        cmp     $02
        beq     crashman_at_target
        bne     crashman_get_direction
crashman_check_x:  lda     $0460,x
        cmp     $02
        bne     crashman_get_direction
crashman_at_target:  lda     #$00
        sta     $0480,x
        sta     $04C0,x
        iny
        iny
        inc     $04E0,x
        inc     $04E0,x
        lda     $04E0,x
        ldx     $00
        cmp     crashman_path_len_table,x
        bne     crashman_get_direction
        ldx     $2B
        lda     #$00
        sta     $04E0,x
        ldy     $01
crashman_get_direction:  ldx     $00
        cpx     #$03
        bcs     crashman_get_direction_wily
        lda     crashman_path_entry,y
        jmp     crashman_set_velocity

crashman_get_direction_wily:  lda     crashman_wily_path_entry,y
crashman_set_velocity:  ldx     $2B
        tay
        lda     crashman_vel_y_sub_table,y
        sta     $0660,x
        lda     crashman_vel_y_table,y
        sta     $0640,x
        lda     crashman_vel_x_sub_table,y
        sta     $0620,x
        lda     crashman_flags_table,y
        sta     $0420,x
        jsr     apply_entity_physics
        bcc     crashman_set_hitbox
        lda     #$00
        sta     $0150,x
crashman_set_hitbox:  sec
        lda     $04A0,x
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
        lda     $0420,x
        and     #$04
        bne     metalman_set_throw_flag
        lda     $04E0,x
        cmp     #$06
        bcs     metalman_set_throw_flag
        jsr     apply_entity_physics_alt
        jmp     metalman_physics

; =============================================================================
; metalman_set_throw_flag -- Boss AI: Metal Man — blade throw with pattern tables ($9C74)
; Spawns entity $15 (Metal Blade projectile).
; =============================================================================
metalman_set_throw_flag:  lda     $0420,x
        ora     #$04
        sta     $0420,x
        jsr     apply_entity_physics
metalman_physics:  bcc     metalman_hitbox_rts
        lda     #$00
        sta     $0150,x
metalman_hitbox_rts:  sec
        lda     $04A0,x
        sbc     #$08
        sta     $0160,x
        rts

metalman_blade_calc:
        sec
        lda     $0440,x
        sbc     #$03
        tay
        lda     metalman_blade_count_table,y
        sta     $02
        lda     metalman_blade_src_table,y
        sta     $01
metalman_spawn_blade:  lda     #$15    ; entity type $15 = Metal Blade projectile
        jsr     spawn_entity_from_parent
        ldx     $01
        lda     metalman_blade_flags,x
        sta     $0430,y
        and     #$40
        bne     metalman_blade_offset
        lda     #$FC
        bne     metalman_blade_set_x
metalman_blade_offset:  lda     #$04
metalman_blade_set_x:  sta     $0470,y
        lda     metalman_blade_y_table,x
        sta     $04B0,y
        lda     metalman_blade_range,x
        sta     $0120,y
        lda     metalman_blade_timer_table,x
        sta     $04F0,y
        ldx     $2B
        inc     $01
        dec     $02
        bne     metalman_spawn_blade
        lsr     $0420,x
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
woodman_ai_timer_check:
        lda     $04E0,x
        beq     woodman_timer_expired
        dec     $04E0,x
        beq     woodman_timer_just_zero
        rts
woodman_timer_just_zero:
        lda     $0420,x
        and     #$DF
        sta     $0420,x
        lda     #$27
        jsr     bank_switch_enqueue
woodman_timer_expired:
        lda     $0420,x
        and     #$20
        bne     woodman_check_contact
        lda     $0420,x
        and     #$40
        bne     woodman_check_leaf_wall
        lda     $0460,x
        cmp     $0110,x
        bcs     woodman_walk_step
        bcc     woodman_at_target_x

; =============================================================================
; woodman_check_leaf_wall -- Boss AI: Woodman — walk, leaf shield, contact check ($9DFE)
; =============================================================================
woodman_check_leaf_wall:  lda     $0460,x
        cmp     $0110,x
        bcc     woodman_walk_step
woodman_at_target_x:  lda     $0110,x
        sta     $0460,x
        lda     $0420,x
        ora     #$20
        sta     $0420,x
        bne     woodman_check_contact
woodman_walk_step:  lda     $0440,x
        sta     $09
        lda     $0460,x
        sta     jump_ptr
        lda     $04A0,x
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
        inc     $51
        ldx     $2B
        jsr     apply_entity_physics
        bcc     woodman_check_contact
        lda     $0420,x
        asl     a
        ora     #$20
        sta     $0420,x
woodman_check_contact:  lda     $4B
        bne     woodman_rts
        sec
        lda     $04A0,x
        sbc     $04A0
        bcs     woodman_check_y_range
        eor     #$FF
        adc     #$01
woodman_check_y_range:  cmp     #$10
        bcs     woodman_rts
        lda     $0420,x
        and     #$40
        bne     woodman_facing_left
        lda     $0460,x
        cmp     $0460
        bcs     woodman_rts
        bcc     woodman_trigger_shield
woodman_facing_left:  lda     $0460,x
        cmp     $0460
        bcc     woodman_rts
woodman_trigger_shield:  lda     #$00
        sta     $2C
        jmp     boss_death_sequence

woodman_rts:  rts

bubbleman_ai_init:
        lda     $04E0,x
        bne     bubbleman_check_state
        lda     $4A
        eor     #$01
        sta     $4A
        and     #$01
        tay
        lda     bubbleman_timer_table,y
        sta     $04E0,x
        lda     #$8B
        sta     $0420,x
        bne     bubbleman_apply_physics
bubbleman_check_state:
        cmp     #$01
        beq     bubbleman_state_swim
        cmp     #$FF
        beq     bubbleman_state_fall
        dec     $04E0,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
bubbleman_apply_physics:
        jsr     apply_entity_physics_alt
        rts

; =============================================================================
; bubbleman_state_swim -- Boss AI: Bubbleman — swim/fall physics, bubble shot ($9EB3)
; =============================================================================
bubbleman_state_swim:  lda     $0420,x
        and     #$F7
        sta     $0420,x
        lda     $06A0,x
        cmp     #$08
        bne     bubbleman_swim_physics
        lda     #$05
        sta     $06A0,x
        lda     #$00
        sta     $09
        lda     #$83
        sta     jump_ptr
        jsr     calc_entity_velocity
bubbleman_swim_physics:  jsr     apply_entity_physics
        lda     $01
        beq     bubbleman_swim_rts
        lda     #$00
        sta     $0600,x
        sta     $0620,x
        sta     $0660,x
        lda     #$02
        sta     $0640,x
        lda     #$FF
        sta     $04E0,x
bubbleman_swim_rts:  rts

bubbleman_state_fall:  lda     $06A0,x
        cmp     #$08
        bne     bubbleman_fall_setup
        lda     #$05
        sta     $06A0,x
bubbleman_fall_setup:  lda     #$04
        sta     $01
        lda     #$08
        sta     $02
        jsr     check_vert_tile_collision
        lda     $00
        beq     bubbleman_fall_physics
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        lda     #$8B
        sta     $0420,x
        lda     #$3E
        sta     $04E0,x
bubbleman_fall_physics:  jsr     apply_entity_physics
        rts

bubbleman_timer_table:  .byte   $3E,$9C         ; Bubbleman AI timer values (62/156 frames)
quickman_ai_init:
        lda     $0640,x
        sta     $04
        lda     #$0C
        sta     $01
        lda     #$10
        sta     $02
        jsr     check_horiz_tile_collision
        lda     $0110,x
        bne     quickman_check_pattern
        lda     $04E0,x
        bne     quickman_dec_timer
        lda     #$C0
        sta     $0620,x
        sta     $0660,x
        lda     #$04
        sta     $0640,x
        sta     $04
        jsr     entity_face_player
        inc     $0110,x
        lda     #$01
        sta     $06A0,x
quickman_check_pattern:
        lda     $0110,x
        cmp     #$01
        bne     quickman_check_timer
        lda     $04
        bpl     quickman_dec_timer
        lda     $00
        beq     quickman_dec_timer
        lda     #$00
        sta     $0620,x
        inc     $0110,x
        lda     #$3E
        sta     $04E0,x
        lda     #$03
        sta     $06A0,x
        bne     quickman_dec_timer

; =============================================================================
; quickman_check_timer -- Boss AI: Quick Man — timer-based movement, boomerang throw ($9F79)
; Spawns entity $18 (Quick Boomerang projectile).
; =============================================================================
quickman_check_timer:  lda     $04E0,x
        bne     quickman_dec_timer
        jsr     entity_face_player
        lda     #$18                    ; entity type $18 = Quick Boomerang projectile
        jsr     spawn_entity_from_parent
        bcs     quickman_set_timer
        lda     $2B
        pha
        tya
        clc
        adc     #$10
        tax
        stx     $2B
        lda     #$02
        sta     $09
        lda     #$0C
        sta     jump_ptr
        jsr     calc_entity_velocity
        pla
        sta     $2B
        tax
quickman_set_timer:  lda     #$3E
        sta     $04E0,x
        inc     $0110,x
        lda     $0110,x
        cmp     #$05
        bne     quickman_dec_timer
        lda     #$00
        sta     $0110,x
quickman_dec_timer:  dec     $04E0,x
        ldy     $0110,x
        lda     $06A0,x
        cmp     quickman_anim_threshold,y
        bne     quickman_state_table
        lda     #$00
        sta     $0680,x
quickman_state_table:  jsr     apply_entity_physics
        rts

quickman_anim_threshold:  .byte   $00,$02,$00,$00,$00             ; Quickman animation speed thresholds
quickman_hp_check:
        ldy     #$02
        lda     $06C0,x
        bne     quickman_palette_check
        jmp     heatman_check_state_entry
quickman_palette_check:
        cmp     $0660,x
        beq     quickman_palette_set
        ldy     #$05
quickman_palette_set:  sta     $0660,x
        ldx     #$0F
quickman_palette_loop:  lda     heatman_palette_data,y
        sta     $0356,x
        dey
        dex
        cpx     #$0C
        bne     quickman_palette_loop
        ldx     $2B
        lda     $0620,x
        bne     heatman_check_state
        lda     #$01
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        lda     $04E0,x
        bne     heatman_dec_timer
        lda     #$1B                    ; entity type $1B = Atomic Fire projectile
        jsr     spawn_entity_from_parent
        bcs     heatman_spawn_fire
        clc
        lda     $04B0,y
        adc     #$0C
        sta     $04B0,y

; =============================================================================
; heatman_spawn_fire -- Boss AI: Heat Man — flame pattern, charge attack ($A019)
; Spawns entity $1B (Atomic Fire projectile).
; =============================================================================
heatman_spawn_fire:  lda     #$02
        sta     $04E0,x
        dec     $0600,x
        bne     heatman_apply_physics
        inc     $0620,x
        bne     heatman_apply_physics
heatman_dec_timer:  dec     $04E0,x
heatman_check_state:  lda     $06A0,x
        bne     heatman_apply_physics
        lda     #$00
        sta     $0620,x
        lda     #$03
        sta     $0600,x
        lda     $4A
        and     #$03
        beq     heatman_apply_physics
        asl     $0600,x
        and     #$01
        bne     heatman_apply_physics
        clc
        lda     $0600,x
        adc     #$03
        sta     $0600,x
heatman_apply_physics:  jsr     apply_entity_physics_alt
        bcc     heatman_rts
        lda     #$80
        sta     $0420,x
        lda     #$19                    ; convert self to type $19 (fire/tornado projectile)
        sta     $0400,x
        lda     #$00
        sta     $04E0,x
        sta     $0620,x
        sta     $0100,x
heatman_rts:  rts

heatman_check_state_entry:
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        lda     $0620,x
        beq     heatman_flame_pattern
        jmp     heatman_dec_cooldown

heatman_flame_pattern:  lda     $04E0,x
        and     #$03
        sta     $00
        asl     a
        asl     a
        adc     $00
        sta     $01
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$05
        sta     $02
heatman_flame_loop:  lda     #$06
        jsr     spawn_entity_from_parent
        bcs     heatman_flame_done
        ldx     $01
        clc
        lda     $0470,y
        adc     heatman_flame_x_offset,y
        sta     $0470,y
        clc
        lda     $04B0,y
        adc     heatman_flame_y_offset,y
        sta     $04B0,y
        .byte   $E6                      ; code: INC $01 (advance flame slot)
heatman_flame_inc:  .byte   $01,$C6,$02  ; dual-use: data table AND code (DEC $02)
        bne     heatman_flame_loop
heatman_flame_done:  ldx     $2B
        inc     $04E0,x
        lda     $04E0,x
        cmp     #$08
        bne     heatman_set_cooldown
        lda     #$1A
        jsr     find_entity_by_type
        bcs     heatman_deactivate_parts
        lda     #$00
        sta     $0430,y
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
        sta     $0430,y
        lda     #$FF
        sta     $0130,y
        lda     $0120,y
        tay
        lda     #$00
        sta     $0140,y
        beq     heatman_deactivate_more
heatman_deactivate_final:  sta     a:$F0,x
        asl     $0420,x
heatman_set_cooldown:  lda     #$08
        sta     $0620,x
heatman_dec_cooldown:  dec     $0620,x
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
        lda     $04E0,x
        bne     airman_check_state
        lda     #$6E
        sta     $04E0,x
        lda     #$01
        sta     $06A0,x
airman_check_state:
        lda     $06A0,x
        bne     airman_dec_timer
        sta     $0680,x

; =============================================================================
; airman_dec_timer -- Boss AI: Air Man — tornado spawn, tile pattern update ($A14D)
; Spawns entities $19/$1A (Air Shooter tornados, primary/secondary).
; =============================================================================
airman_dec_timer:  dec     $04E0,x
        jsr     apply_entity_physics_alt
        rts

        .byte   $18,$BD,$60,$06,$69,$40,$9D,$60
        .byte   $06,$BD,$40,$06,$69,$00,$9D,$40
        .byte   $06,$20,$BA,$EE,$60,$38,$BD,$40
        .byte   $04,$E9,$06,$A8,$B9,$69,$A2,$DD
        .byte   $A0,$04,$F0,$14,$BD,$20,$04,$29
        .byte   $DF,$9D,$20,$04,$A9,$00,$9D,$A0
        .byte   $06,$9D,$80,$06,$20,$BA,$EE,$60
        lda     #$00
        sta     $0640,x
        jsr     apply_entity_physics_alt
        lda     $06A0,x
        pha
        tay
        clc
        lda     $04A0,x
        adc     airman_y_offset_table,y
        and     #$E0
        sta     $0A
        clc
        lda     $0460,x
        adc     airman_x_offset_table,y
        and     #$E0
        sta     jump_ptr
        lda     $0440,x
        sta     $09
        jsr     metatile_render
        jsr     metatile_attr_update
        ldy     $1B
        lda     $03B6
        sta     $0300,y
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
        sta     $00
        ldx     $2B
        lda     $04E0,x
        cmp     #$FF
        bne     airman_set_tile_pattern
        clc
        lda     $00
        adc     #$04
        sta     $00
airman_set_tile_pattern:  lda     $00
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        lda     #$10
        sta     $00
airman_copy_tiles:  lda     airman_tile_data,x
        sta     $0310,y
        inx
        iny
        dec     $00
        bne     airman_copy_tiles
        inc     $1B
        ldx     $2B
        lda     $06A0,x
        cmp     #$03
        bne     airman_rts
        lda     $04E0,x
        bne     airman_rts
        lda     #$19                    ; entity type $19 = Air Shooter tornado (primary)
        jsr     spawn_entity_from_parent
        lda     #$08
        sta     $04F0,y
        lda     #$03
        sta     $0610,y
        lda     #$14
        sta     $04C0,x
        lda     $4A
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
airman_spawn_tornado_2:  lda     #$1A    ; entity type $1A = Air Shooter tornado (secondary)
        jsr     spawn_entity_from_parent
        clc
        lda     $0470,y
        adc     #$2F
        sta     $0470,y
        sec
        lda     $04B0,y
        sbc     #$0C
        sta     $04B0,y
        inc     $04E0,x
        lda     #$A0
        sta     $0420,x
airman_rts:  rts

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
        lda     $0420,x
        and     #$20
        beq     flashman_state_walk
        lda     $00
        cmp     #$50
        bcc     flashman_stop_freeze
        jsr     apply_entity_physics_alt
        rts

; =============================================================================
; flashman_stop_freeze -- Boss AI: Flashman — time stopper, walk/jump/shoot ($A308)
; =============================================================================
flashman_stop_freeze:  lda     #$00
        sta     $06A0,x
        sta     $0680,x
        lda     $0420,x
        and     #$DF
        sta     $0420,x
        lda     #$04
        sta     $0640,x
flashman_state_walk:  lda     $06A0,x
        bne     flashman_check_shoot
        lda     #$00
        sta     $0680,x
        lda     #$07
        sta     $01
        lda     #$01
        sta     $02
        jsr     check_vert_tile_collision
        lda     $00
        bne     flashman_wall_stop
        jmp     flashman_physics

flashman_wall_stop:  lda     #$00
        sta     $0640,x
        inc     $06A0,x
        jmp     flashman_physics

flashman_check_shoot:  lda     $06A0,x
        cmp     #$02
        bne     flashman_check_height
        clc
        lda     $04A0,x
        adc     #$05
        sta     $04A0,x
        inc     $06A0,x
flashman_check_height:  lda     $06A0,x
        cmp     #$08
        bcs     flashman_state_air
        lda     $00
        cmp     #$20
        bcc     flashman_jump
        inc     $04E0,x
        lda     $04E0,x
        cmp     #$7D
        beq     flashman_jump
        lda     $06A0,x
        cmp     #$07
        bne     flashman_physics
        lda     #$03
        sta     $06A0,x
        bne     flashman_physics
flashman_jump:  sec
        lda     $04A0,x
        sbc     #$20
        sta     $04A0,x
        lda     $0420,x
        ora     #$04
        sta     $0420,x
        lda     #$02
        sta     $04E0,x
        lda     #$08
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        bne     flashman_physics
flashman_state_air:  lda     #$08
        sta     $01
        lda     #$10
        sta     $02
        jsr     check_vert_tile_collision
        lda     #$00
        sta     $0680,x
        lda     $06A0,x
        cmp     #$09
        beq     flashman_state_land
        dec     $04E0,x
        bne     flashman_physics
        lda     #$03
        sta     $0640,x
        lda     #$76
        sta     $0660,x
        lda     #$01
        sta     $0600,x
        lda     #$7B
        sta     $0620,x
        inc     $06A0,x
        bne     flashman_physics
flashman_state_land:  lda     $00
        beq     flashman_physics
        lda     #$08
        sta     $06A0,x
        lda     #$32
        sta     $04E0,x
        lda     #$00
        sta     $0620,x
        sta     $0600,x
flashman_physics:  jsr     apply_entity_physics
        rts

        .byte   $BD,$20,$06,$D0,$08,$A9,$1E,$20
        .byte   $B5,$95,$90,$01,$60
        lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04E0,x
        bne     item_2_dec_timer
        lda     #$01
        sta     $01
        lda     #$1F
        jsr     find_entity_count_check
        bcs     item_2_set_timer
        lda     #$1F
        jsr     spawn_entity_from_parent
        bcs     item_2_set_timer
        clc
        lda     $0470,y
        adc     #$78
        sta     $0470,y
        lda     $0450,y
        adc     #$00
        sta     $0450,y
        sec
        lda     $04A0
        sbc     #$2C
        bcs     item_2_store_y
        lda     #$08
item_2_store_y:  sta     $04B0,y
        ldx     $2B
item_2_set_timer:  lda     #$1F
        sta     $04E0,x
item_2_dec_timer:  dec     $04E0,x
        rts

        .byte   $A9,$08,$85,$01,$A9,$14,$85,$02
        .byte   $20,$2C,$F0,$A5,$00,$F0,$1B,$BD
        .byte   $E0,$04,$C9,$13,$D0,$0F,$A9,$04
        .byte   $9D,$40,$06,$A9,$78,$9D,$60,$06
        .byte   $A9,$00,$9D,$E0,$04
        inc     $04E0,x
        bne     boss_extra_physics
        lda     #$02
        sta     $06A0,x
        lda     #$03
        sta     $0680,x

; =============================================================================
; boss_extra_physics -- Boss Common — extra physics, random timer, palette flash ($A47A)
; =============================================================================
boss_extra_physics:  jsr     apply_entity_physics
        rts

        .byte   $A9,$1E,$85,$00,$4C,$52,$96,$BD
        .byte   $E0,$04,$D0,$15,$A9,$03,$85,$01
        .byte   $A9,$22,$20,$CF,$96,$B0,$05,$A9
        .byte   $22,$20,$59,$F1
        lda     #$DA
        sta     $04E0,x
        dec     $04E0,x
        jsr     apply_entity_physics_alt
        rts

        lda     $04E0,x
        bne     boss_spawn_dec_timer
        lda     #$00
        sta     $09
        lda     #$42
        sta     jump_ptr
        jsr     calc_entity_velocity
        lda     #$10
        sta     $04E0,x
boss_spawn_dec_timer:  dec     $04E0,x
        jsr     apply_entity_physics
        rts

        .byte   $BD,$20,$06,$D0,$25,$A9,$6E,$9D
        .byte   $E0,$04,$FE,$20,$06,$A9,$00,$9D
        .byte   $20,$04,$A9,$01,$85,$01,$A9,$23
        .byte   $20,$CF,$96,$A9,$83,$9D,$20,$04
        .byte   $B0,$5D,$A9,$26,$20,$59,$F1,$4C
        .byte   $41,$A5
        lda     $04E0,x
        beq     boss_check_anim_state
        lda     $06A0,x
        cmp     #$02
        bne     boss_dec_timer
        lda     #$00
        sta     $06A0,x
        beq     boss_dec_timer
boss_check_anim_state:  lda     $06A0,x
        cmp     #$04
        bne     boss_check_physics
        lda     $0680,x
        bne     boss_check_physics
        jsr     entity_face_player
        lda     #$24
        jsr     spawn_entity_from_parent
        bcs     boss_random_timer
        sec
        lda     $4A
        and     #$1F
        sta     $4A
        sec
        lda     $00
        sbc     $4A
        sta     $00
        lda     #$00
        asl     $00
        rol     a
        asl     $00
        rol     a
        asl     $00
        rol     a
        sta     $0610,y
        lda     $00
        sta     $0630,y
boss_random_timer:  lda     $4A
        and     #$03
        tay
        lda     boss_random_timer_table,y
        sta     $04E0,x
boss_dec_timer:  dec     $04E0,x
boss_check_physics:  jsr     apply_entity_physics_alt
        bcc     boss_misc_rts
        lda     #$23
        jsr     find_entity_by_type
        bcc     boss_misc_rts
        lda     #$28
        jsr     spawn_entity_from_parent
boss_misc_rts:  rts

boss_random_timer_table:  .byte   $12,$1F,$1F,$3D,$AD,$57,$03,$C9 ; random timer values for boss AI
        .byte   $0F,$F0,$37,$A9,$23,$20,$10,$F0
        .byte   $90,$30,$A9,$26,$20,$10,$F0,$90
        .byte   $29,$BD,$E0,$04,$D0,$33,$BD,$20
        .byte   $06

; =============================================================================
; boss_palette_flash -- Boss Palette Flash — cycle palette during death/hit animation ($A577)
; =============================================================================
boss_palette_flash:  asl     a
        asl     a
        sta     $00
        asl     a
        clc
        adc     $00
        tax
        ldy     #$00
boss_palette_flash_loop:  lda     boss_palette_flash_data,x
        sta     $0356,y
        inx
        iny
        cpy     #$0C
        bne     boss_palette_flash_loop
        ldx     $2B
        inc     $0620,x
        lda     $0620,x
        cmp     #$04
        bne     boss_palette_flash_timer
        lsr     $0420,x
        lda     #$FF
        sta     a:$F0,x
boss_palette_flash_timer:  lda     #$08
        sta     $04E0,x
boss_palette_flash_dec:  dec     $04E0,x
        rts

        lda     $04E0,x
        bne     boss_palette_flash_dec
        clc
        lda     $0620,x
        adc     #$03
        bne     boss_palette_flash
        lda     $04E0,x
        bne     boss_palette_flash_dec
        lda     $0620,x
        eor     #$03
        jmp     boss_palette_flash

        .byte   $BD,$E0,$04,$D0,$DD,$38,$BD,$20
        .byte   $06,$49,$03,$18,$69,$03,$4C,$77
        .byte   $A5
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
        .byte   $0F,$27,$16,$07,$BD,$10,$01,$D0
        .byte   $28,$FE,$E0,$04
        lda     $04E0,x
        cmp     #$3E
        bne     wily_machine_physics
        lda     #$2A
        jsr     spawn_entity_from_parent
        bcs     wily_machine_physics
        lda     #$08
        sta     $04B0,y
        lda     $2B
        sta     $0120,y
        tya
        sta     $0110,x
        lda     #$00
        sta     $04E0,x

; =============================================================================
; wily_machine_physics -- Boss AI: Wily Machine — turret spawn, physics ($A653)
; =============================================================================
wily_machine_physics:  jsr     apply_entity_physics_alt
        rts

        ldy     $0110,x
        cpy     #$FF
        beq     wily_capsule_collision
        lda     $04E0,x
        cmp     #$04
        bcs     wily_capsule_attack
        sec
        lda     $04A0,x
        sbc     $04B0,y
        cmp     #$20
        bcs     wily_machine_physics
        lda     #$D4
        sta     $0670,y
        lda     #$02
        sta     $0650,y
        inc     $04E0,x
        lda     $04E0,x
        cmp     #$04
        bne     wily_machine_physics
        lda     #$87
        sta     $0420,x

; =============================================================================
; wily_capsule_attack -- Boss AI: Wily Capsule — attack, collision, bounce physics ($A689)
; =============================================================================
wily_capsule_attack:  sec
        lda     $04A0,x
        sbc     #$20
        sta     $04B0,y
        lda     $0460,x
        sta     $0470,y
        lda     $0440,x
        sta     $0450,y
        lda     #$00
        sta     $0650,y
wily_capsule_collision:  lda     #$0F
        sta     $01
        lda     #$0E
        sta     $02
        jsr     check_horiz_tile_collision
        lda     $04E0,x
        cmp     #$04
        bne     wily_capsule_check_bounce
        lda     $00
        beq     wily_capsule_check_bounce
        jsr     entity_face_player
        lda     #$47
        sta     $0620,x
        lda     #$01
        sta     $0600,x
        inc     $04E0,x
wily_capsule_check_bounce:  lda     $03
        beq     wily_capsule_physics
        lda     $0420,x
        eor     #$40
        sta     $0420,x
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

        .byte   $20,$BA,$EE,$90,$16,$BC,$10,$01
        .byte   $C0,$FF,$F0,$0F,$A9,$00,$99,$00
        .byte   $06,$A9,$A3,$99,$20,$06,$A9,$FF
        .byte   $99,$10,$01,$60,$BD,$E0,$04,$D0
        .byte   $15,$A9,$02,$85,$01,$A9,$2C,$20
        .byte   $CF,$96,$B0,$05,$A9,$2C,$20,$59
        .byte   $F1
        lda     #$7D
        sta     $04E0,x
        dec     $04E0,x
        jsr     apply_entity_physics_alt
        rts

        .byte   $BD,$10,$01,$D0,$03,$FE,$10,$01
        lda     $0110,x
        cmp     #$02
        bcs     angler_check_bite_state
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        lda     #$08
        sta     $01
        lda     #$14
        sta     $02
        lda     $0640,x
        php
        jsr     check_horiz_tile_collision
        plp
        bpl     angler_physics
        lda     $00
        beq     angler_physics
        lda     #$39
        jsr     bank_switch_enqueue
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        sta     $0600,x
        sta     $0620,x
        lda     $0420,x
        and     #$FB
        sta     $0420,x
        inc     $0110,x
angler_check_bite_state:  lda     $0110,x
        cmp     #$02
        bne     angler_check_anim
        lda     $06A0,x
        cmp     #$09
        bne     angler_physics
        lda     #$E5
        sta     $0660,x
        lda     #$47
        sta     $04E0,x
        inc     $0110,x
angler_check_anim:  lda     $06A0,x
        cmp     #$0B
        bne     angler_dec_timer
        lda     #$09
        sta     $06A0,x
angler_dec_timer:  dec     $04E0,x
        bne     angler_physics
        lda     #$87
        sta     $0420,x
        jsr     entity_face_player
        lda     #$00
        asl     $00
        rol     a
        asl     $00
        rol     a
        asl     $00
        rol     a
        sta     $0600,x
        lda     $00
        sta     $0620,x
        lda     #$03
        sta     $0640,x
        lda     #$76
        sta     $0660,x
        lda     #$01
        sta     $0110,x
angler_physics:  jsr     apply_entity_physics
        rts

        .byte   $A9,$08,$D0,$02,$A9,$01
        sta     $04E0,x
        lda     $0460,x
        and     $0600,x
        sta     $0640,x
        lda     $04A0,x
        and     $0620,x
        sta     $0660,x
        jsr     apply_simple_physics
        rts

        .byte   $BD,$10,$01,$D0,$1F,$20,$EE,$EF
        .byte   $A5,$00,$C9,$28,$B0,$12
        lda     #$87
        sta     $0420,x
        lda     #$FF
        sta     $0640,x
        lda     #$C0
        sta     $0660,x
        inc     $0110,x
        jsr     apply_entity_physics_alt
        rts

        lda     #$08
        sta     $01
        sta     $02
        jsr     check_vert_tile_collision
        lda     $0110,x
        cmp     #$02
        bcs     mecha_dragon_check_landed
        lda     $00
        beq     mecha_dragon_physics_2
        lda     #$21
        jsr     bank_switch_enqueue
        lda     #$2B
        sta     $04E0,x
        inc     $0110,x
        lda     #$52
        jsr     spawn_entity_from_parent
        sec
        lda     $04B0,y
        sbc     #$28
        sta     $04B0,y
        lda     #$2B
        sta     $04F0,y
        bne     mecha_dragon_physics_2
mecha_dragon_check_landed:  lda     $04E0,x
        beq     mecha_dragon_check_wall
        dec     $04E0,x
        bne     mecha_dragon_physics_2
        lda     #$00
        sta     $0640,x
        lda     #$62
        sta     $0660,x
        lda     #$83
        sta     $0420,x
        bne     mecha_dragon_physics_2
mecha_dragon_check_wall:  lda     $00
        beq     mecha_dragon_physics_2
        lda     #$00
        sta     $0660,x
        sta     $0110,x
mecha_dragon_physics_2:  jsr     apply_entity_physics
        rts

; =============================================================================
; mecha_dragon_fire -- Boss AI: Mecha Dragon — fire breath, walk, debris spawn ($A877)
; Spawns entity $33 (fireball, reused for debris).
; =============================================================================
mecha_dragon_fire:  lda     #$07
        sta     $01
        lda     #$08
        sta     $02
        jsr     check_horiz_tile_collision
        lda     $06A0,x
        cmp     #$0F
        bne     mecha_dragon_check_timer
        lda     #$0E
        sta     $06A0,x
mecha_dragon_check_timer:  lda     $04E0,x
        beq     mecha_dragon_check_state
        dec     $04E0,x
        bne     mecha_dragon_check_state
        lda     #$02
        sta     $01
mecha_dragon_spawn_fire:  lda     #$33    ; entity type $33 = Mecha Dragon fireball
        jsr     spawn_entity_from_parent
        bcs     mecha_dragon_fire_done
        lda     #$E0
        sta     $04B0,y
        lda     #$A8
        sta     $0430,y
        ldx     $01
        lda     mecha_dragon_fire_timer,x
        sta     $04F0,y
        ldx     $2B
        txa
        sta     $0120,y
        dec     $01
        bpl     mecha_dragon_spawn_fire
mecha_dragon_fire_done:  ldx     $2B
mecha_dragon_check_state:  lda     $0110,x
        cmp     #$04
        bne     mecha_dragon_physics
        sec
        lda     $04A0,x
        sbc     #$20
        sta     $04A0,x
        lda     #$87
        sta     $0420,x
        lda     #$41
        sta     $0620,x
        lda     #$00
        sta     $0680,x
        sta     $06A0,x
        sta     $0110,x
mecha_dragon_physics:  jsr     apply_entity_physics
        rts

        .byte   $BD,$10,$01,$D0,$0C,$A9,$32,$20
        .byte   $59,$F1,$8A,$99,$F0,$04,$FE,$10
        .byte   $01
        lda     $0420,x
        and     #$08
        beq     mecha_dragon_walk
        jmp     mecha_dragon_fire

mecha_dragon_walk:  lda     #$07
        sta     $01
        lda     #$28
        sta     $02
        sec
        lda     $0460,x
        sbc     #$07
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
        sta     $09
        clc
        lda     #$00
        sta     $0B
        lda     $04A0,x
        adc     #$20
        sta     $0A
        jsr     lookup_tile_from_map
        ldx     $2B
        ldy     $00
        beq     mecha_dragon_collision
        lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     $0460,x
        sta     $0460,x
mecha_dragon_store_screen:  lda     $0440,x
        adc     #$00
        sta     $0440,x
mecha_dragon_collision:  jsr     check_vert_tile_collision
        lda     $06A0,x
        cmp     #$0C
        bne     mecha_dragon_check_hit
        lda     #$00
        sta     $06A0,x
mecha_dragon_check_hit:  jsr     apply_entity_physics
        bcs     mecha_dragon_rts
        lda     $0100,x
        beq     mecha_dragon_rts
        lda     #$0D
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        sta     $0620,x
        sta     $0600,x
        lda     #$7E
        sta     $04E0,x
        jsr     entity_face_player
        lda     #$02
        sta     $01
mecha_dragon_spawn_debris:  lda     #$33    ; entity type $33 = Mecha Dragon fireball (reused as debris)
        jsr     spawn_entity_from_parent
        bcs     mecha_dragon_debris_done
        ldx     $01
        clc
        lda     $04B0,y
        adc     mecha_dragon_debris_y_off,x
        sta     $04B0,y
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
mecha_dragon_debris_loop_end:  ldx     $2B
        dec     $01
        bpl     mecha_dragon_spawn_debris
mecha_dragon_debris_done:  ldx     $2B
        lda     #$8F
        sta     $0420,x
mecha_dragon_rts:  rts

mecha_dragon_debris_y_off:  .byte   $F0,$10,$20 ; Mecha Dragon debris Y offset
mecha_dragon_debris_vel_hi:  .byte   $03,$02,$01 ; debris X velocity (high byte)
mecha_dragon_debris_vel_lo:  .byte   $00,$40,$00 ; debris X velocity (low byte)
mecha_dragon_fire_timer:  .byte   $01,$06,$0B ; fire attack cooldown timers
        ldy     $04E0,x           ; Guts Tank AI entry
        lda     $0420,y
        bpl     guts_tank_deactivate
        and     #$08
        beq     guts_tank_track_parent
guts_tank_deactivate:  lsr     $0420,x
        rts

guts_tank_track_parent:  lda     $0460,y
        sta     $0460,x
        lda     $0440,y
        sta     $0440,x
        clc
        lda     $04A0,y
        adc     #$08
        sta     $04A0,x
        jsr     apply_entity_physics_alt
        rts

        .byte   $BC,$10,$01
        bpl     picopico_check_timer
        lda     #$07
        sta     $01
        lda     #$08
        sta     $02
        jsr     check_horiz_tile_collision
        lda     $00
        beq     picopico_physics
        lda     $04E0,x
        beq     picopico_stop_movement
        lda     #$00
        sta     $4E
        jmp     apply_collision_physics

; =============================================================================
; picopico_stop_movement -- Boss AI: Picopico-kun — bouncing block enemy, shot spawn ($AA0C)
; Spawns entity $35 (projectile, shared type with Neo Metall bullet).
; =============================================================================
picopico_stop_movement:  lda     #$00
        sta     $0620,x
        sta     $0600,x
        sta     $0660,x
        lda     #$02
        sta     $0640,x
        inc     $04E0,x
        bne     picopico_physics
picopico_check_timer:  lda     $04E0,x
        beq     picopico_check_player
        dec     $04E0,x                 ; decrement AI timer
        bne     picopico_physics
        lda     #$8B
        sta     $0420,x
        lda     #$04
        sta     $0640,x
picopico_check_player:  lda     $04A0,x
        cmp     $04A0,y
        bcs     picopico_physics
        clc
        lda     $0110,y
        adc     #$01
        sta     $0110,y
        lsr     $0420,x
        rts

picopico_physics:  jsr     apply_entity_physics
        rts

        lda     $2A                   ; check if Wily stage 3 (Guts-Dozer)
        cmp     #$0A
        bne     picopico_begin_hitbox
        jmp     picopico_wily3_entry  ; alternate AI for Wily 3
picopico_begin_hitbox:
        ldy     #$08
        lda     $06A0,x
        cmp     #$03
        bcc     picopico_set_hitbox
        ldy     #$10
picopico_set_hitbox:  sty     $02
        lda     #$07
        sta     $01
        jsr     check_horiz_tile_collision
        lda     $0110,x
        bne     picopico_state_1
        jsr     entity_face_player
        lda     $00
        cmp     #$40
        bcs     picopico_clear_anim
        lda     $04E0,x
        bne     picopico_dec_main_timer
        inc     $06A0,x
        inc     $0110,x
        lda     $0420,x
        and     #$F7
        sta     $0420,x
        lda     #$3E
        sta     $04E0,x
        bne     picopico_jmp_physics
picopico_dec_main_timer:  dec     $04E0,x
picopico_clear_anim:  lda     #$00
        sta     $0680,x
        sta     $06A0,x
picopico_jmp_physics:  jmp     picopico_apply_physics

picopico_state_1:  cmp     #$02
        bcs     picopico_state_2_timer
        lda     $06A0,x
        cmp     #$02
        bne     picopico_dec_timer
        lda     #$25
        jsr     bank_switch_enqueue
        lda     #$02
        sta     $01
picopico_spawn_shot:  lda     #$35    ; entity type $35 = projectile (shared with Neo Metall)
        jsr     spawn_entity_from_parent ; spawn projectile
        bcs     picopico_advance_state
        ldx     $01
        lda     picopico_shot_vel_y_sub,x
        sta     $0670,y
        lda     picopico_shot_vel_y_hi,x
        sta     $0650,y
        lda     picopico_shot_vel_x_sub,x
        sta     $0630,y
        lda     picopico_shot_vel_x_hi,x
        sta     $0610,y
        ldx     $2B
        dec     $01
        bpl     picopico_spawn_shot
picopico_advance_state:  lda     #$03
        sta     $06A0,x
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $04A0,x
picopico_dec_timer:  dec     $04E0,x
        bne     picopico_check_anim
        jsr     entity_face_player
        lda     #$02
        sta     $0600,x
        lda     #$14
        sta     $04E0,x
        inc     $0110,x
        bne     picopico_check_anim
picopico_state_2_timer:  dec     $04E0,x
        bne     picopico_check_anim
        lda     #$00
        sta     $0600,x
        sta     $06A0,x
        sta     $0110,x
        lda     $4A
        and     #$03
        tay
        lda     picopico_random_timer,y
        sta     $04E0,x
        lda     $0420,x
        ora     #$08
        sta     $0420,x
picopico_check_anim:  lda     $06A0,x
        cmp     #$05
        bne     picopico_apply_physics
        lda     #$03
        sta     $06A0,x
picopico_apply_physics:  jsr     apply_entity_physics
        rts

picopico_random_timer:  .byte   $1F,$3E,$9B,$1F
picopico_shot_vel_y_sub:  .byte   $25,$00,$DB ; Picopico shot Y velocity (sub-pixel)
picopico_shot_vel_y_hi:  .byte   $01,$00,$FE
picopico_shot_vel_x_sub:  .byte   $A3,$00,$A3 ; Picopico shot X velocity (sub-pixel)
picopico_shot_vel_x_hi:  .byte   $01,$02,$01
picopico_wily3_entry:
        lda     $04E0,x
        bne     buebeam_collision
        lda     $04A0,x
        cmp     #$80
        bcc     buebeam_check_anim
        inc     $04E0,x
        lda     #$03
        sta     $0640,x
buebeam_collision:  lda     #$08
        sta     $01
        lda     #$10
        sta     $02
        jsr     check_vert_tile_collision
        lda     $00
        beq     buebeam_check_anim
        lda     #$FF
        sta     $0640,x
        lda     #$01
        sta     $0600,x
        lda     #$00
        sta     $0660,x
        sta     $0620,x
buebeam_check_anim:  lda     $06A0,x
        cmp     #$05
        bne     buebeam_physics
        lda     #$03
        sta     $06A0,x
buebeam_physics:  jsr     apply_entity_physics
        rts

; =============================================================================
; matasaburo_wind_push -- Enemy AI: Matasaburo (Fan Fiend) — wind push effect ($AB89)
; Entity type $36. Air Man stage only. Pushes player backward with wind.
; =============================================================================
        .byte   $38,$A5,$2D,$E5,$2E,$B0,$10,$A9
        .byte   $01,$85,$40,$A9,$00,$85,$AF,$A9
        .byte   $A3,$85,$4F,$A9,$00,$85,$50
        jsr     apply_entity_physics_alt
        rts

; Entity AI subroutine — collision check, entity $37 parameter ($ABA4)
        .byte   $BD,$20,$06,$D0,$08,$A9,$37
        jsr     check_entity_collision_scan
        bcc     boobeam_init
        rts

; =============================================================================
; boobeam_init -- Boss AI: Boobeam Trap — turret initialization and firing ($ABB1)
; =============================================================================
boobeam_init:  lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04E0,x
        bne     boobeam_dec_timer
        lda     #$BB
        sta     $04E0,x
        lda     #$01
        sta     $01
        lda     #$38
        jsr     find_entity_count_check
        bcs     boobeam_dec_timer
        lda     #$02
        sta     $01
        lda     #$3C
        jsr     find_entity_count_check
        bcs     boobeam_dec_timer
        lda     #$38
        jsr     spawn_entity_from_parent
        bcs     boobeam_dec_timer
        ldx     #$00
        lda     $0420
        and     #$40
        bne     boobeam_set_direction
        inx
boobeam_set_direction:  lda     boobeam_dir_flags_table,x
        sta     $0430,y
        clc
        lda     $1F
        adc     boobeam_x_offset_table,x
        sta     $0470,y
        lda     $20
        adc     #$00
        sta     $0450,y
boobeam_dec_timer:  ldx     $2B
        dec     $04E0,x
        rts

boobeam_x_offset_table:  .byte   $F8,$08 ; Boobeam turret X offset per slot
boobeam_dir_flags_table:  .byte   $83,$C3 ; Boobeam shot direction flags
        lsr     $0420,x
        rts

        .byte   $BD,$10,$01,$D0,$10,$A9,$3A,$20
        .byte   $59,$F1,$B0,$F0,$8A,$99,$20,$01
        .byte   $C8,$98,$9D,$10,$01
        lda     $04E0,x
        bne     capsule_missile_anim
        lda     $0420,x
        pha
        jsr     entity_face_player
        pla
        sta     $0420,x
        ldy     $0110,x
        dey
        clc
        lda     $04A0,x
        adc     #$10
        sta     $04B0,y
        lda     $0460,x
        sta     $0470,y
        lda     $0440,x
        sta     $0450,y
        lda     $00
        cmp     #$30
        bcc     capsule_missile_move
        lda     $06A0,x
        cmp     #$02
        bne     capsule_missile_physics
        lda     #$00
        sta     $06A0,x
        beq     capsule_missile_physics
capsule_missile_move:  lda     #$87
        sta     $0430,y
        inc     $04E0,x
        lda     #$02
        sta     $06A0,x
        sta     $0680,x
capsule_missile_anim:  lda     $06A0,x
        cmp     #$03
        bne     capsule_missile_physics
        lda     #$00
        sta     $0680,x
capsule_missile_physics:  jsr     apply_entity_physics
        bcc     capsule_missile_rts
        ldy     $0110,x
        dey
        lda     #$00
        sta     $0430,y
capsule_missile_rts:  rts

        .byte   $A9,$37,$85,$00,$4C,$52,$96,$BD
        .byte   $20,$04,$29,$04,$D0,$04,$20,$B3
        .byte   $EF,$60
        lda     #$07
        sta     $01
        sta     $02
        jsr     check_vert_tile_collision
        lda     $00
        bne     boss_explode_start
        jsr     apply_entity_physics
        lda     $01
        bne     boss_explode_start
        rts

; =============================================================================
; boss_explode_start -- Boss Explosion — spawn debris ring on boss death ($ACB6)
; =============================================================================
boss_explode_start:  lda     #$3B    ; entity type $3B = explosion flash effect
        jsr     spawn_entity_from_parent
        lda     #$3B                    ; spawn second flash
        jsr     spawn_entity_from_parent
        lda     #$C4
        sta     $0430,y
        lda     #$07
        sta     $01
boss_explode_spawn_loop:  lda     #$3C    ; entity type $3C = explosion debris
        jsr     spawn_entity_from_parent ; spawn debris piece
        bcs     boss_explode_deactivate
        ldx     $01
        lda     boss_explode_flags_table,x
        sta     $0430,y
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
        ldx     $2B
        dec     $01
        bpl     boss_explode_spawn_loop
boss_explode_deactivate:  lsr     $0420,x
        rts

boss_explode_flags_table:  .byte   $C3,$C3,$C3,$C3,$C3,$83,$83,$83 ; explosion entity flags per slot
boss_explode_vel_y_sub:  .byte   $96,$7B,$1E,$6A,$F0,$00,$E6,$9E ; explosion Y velocity (sub-pixel)
boss_explode_vel_y_hi:  .byte   $FE,$00,$01,$01,$01,$02,$01,$00
boss_explode_vel_x_sub:  .byte   $6A,$F0,$A8,$6A,$7B,$00,$9E,$E6 ; explosion X velocity (sub-pixel)
boss_explode_vel_x_hi:  .byte   $01,$01,$01,$01,$00,$00,$00,$01
boss_explode_timer_table:  .byte   $0B,$21,$1C,$0B,$21,$10,$19,$19
        .byte   $BD,$10,$01,$D0,$13,$DE,$E0,$04
        .byte   $D0,$0E,$A9,$47,$85,$08,$A9,$01
        .byte   $85,$09,$20,$97,$F1,$FE,$10,$01
        jsr     apply_entity_physics
        rts

        .byte   $BC,$10,$01,$B9,$20,$04,$10,$4B
        .byte   $B9,$00,$04,$C9,$3E,$D0,$44,$38
        .byte   $B9,$A0,$04,$E9,$14,$9D,$A0,$04
        .byte   $B9,$60,$04,$9D,$60,$04,$B9,$40
        .byte   $04,$9D,$40,$04,$20,$EE,$EF,$FE
        .byte   $E0,$04,$BD,$E0,$04,$C9,$9D,$D0
        .byte   $12,$A9,$3F,$20,$59,$F1,$A9,$03
        .byte   $9D,$A0,$06,$A9,$00,$9D,$80
        asl     $9D
        cpx     #$04
        lda     $06A0,x
        cmp     #$02
        bne     boss_proj_physics
        lda     #$00
        sta     $06A0,x
boss_proj_physics:  jsr     apply_entity_physics
        rts

        lsr     $0420,x
        rts

        .byte   $A9,$18,$9D,$50,$01,$BD
        jsr     addr_1D06
        rts

        asl     $D0
        .byte   $14,$A9,$3D,$20,$59,$F1,$B0,$0D
        .byte   $8A,$99,$20,$01,$38,$BD,$A0,$04
        .byte   $E9,$14,$99,$B0,$04
        lda     $04E0,x
        bne     circular_shot_dec_timer
        lda     $0110,x
        and     #$0F
        tay
        clc
        adc     #$01
        sta     $0110,x
        lda     circular_vel_y_sub_table,y
        sta     $0660,x
        lda     circular_vel_y_hi_table,y
        sta     $0640,x
        lda     circular_vel_x_sub_table,y
        sta     $0620,x
        lda     circular_flags_table,y
        sta     $0420,x
        lda     #$2A
        sta     $04E0,x
circular_shot_dec_timer:  dec     $04E0,x
        jsr     apply_entity_physics
        bcc     circular_shot_set_hitbox
        lda     #$00
        sta     $0150,x
circular_shot_set_hitbox:  sec
        lda     $04A0,x
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
        .byte   $20,$EE,$EF,$38,$BD,$00,$04,$E9
        .byte   $40,$A8,$B9,$79,$AF,$85,$01,$BD
        .byte   $20,$04,$29,$20,$F0,$1B,$A4,$01
        .byte   $A9,$15,$D9,$58,$03,$D0,$07,$A9
        .byte   $04,$9D,$20,$06,$D0,$06
        lda     $00
        cmp     #$60
        bcs     alien_jump_physics
        lda     #$82
        sta     $0420,x
        lda     $0620,x
        cmp     #$04
        bcs     alien_check_fire
        lda     $04E0,x
        and     #$03
        bne     alien_jump_physics
        sta     $04E0,x
        lda     $0620,x
        inc     $0620,x
        asl     a
        asl     a
        tay
        ldx     $01
        jsr     alien_set_palette
        ldx     $2B

; =============================================================================
; alien_jump_physics -- Boss AI: Alien Wily — final boss hover, shot pattern ($AE9B)
; Spawns entities $44 (shot) and $45 (orb).
; =============================================================================
alien_jump_physics:  jmp     alien_inc_timer

alien_check_fire:  lda     $00
        cmp     #$28
        bcs     alien_check_descent
        lda     $04E0,x
        and     #$3F
        bne     alien_check_descent
        lda     #$03
        sta     $01
        lda     #$45
        jsr     find_entity_count_check
        bcs     alien_check_descent
        lda     #$45                    ; entity type $45 = Alien Wily orb
        jsr     spawn_entity_from_parent
        bcs     alien_check_descent
        lda     $0600,x
        and     #$01
        tax
        lda     alien_shot_flags_table,x
        sta     $0430,y
        clc
        lda     $04B0,y
        adc     #$03
        sta     $04B0,y
        clc
        lda     $0470,y
        adc     alien_shot_x_offset_lo,x
        sta     $0470,y
        lda     $0450,y
        adc     alien_shot_x_offset_hi,x
        sta     $0450,y
        lda     #$3F
        sta     $04F0,y
        ldx     $2B
        inc     $0600,x
alien_check_descent:  lda     $0660,x
        ora     $0640,x
        bne     alien_hover_dec
        lda     #$01
        sta     $01
alien_spawn_shot_loop:  lda     #$44    ; entity type $44 = Alien Wily shot
        jsr     spawn_entity_from_parent
        bcs     alien_set_hover_timer
        lda     $04B0,y
        sbc     #$24
        sta     $04B0,y
        ldx     $01
        clc
        lda     $0470,y
        adc     alien_shot_x_offset_lo,x
        sta     $0470,y
        lda     $0450,y
        adc     alien_shot_x_offset_hi,x
        sta     $0450,y
        lda     #$78
        sta     $04F0,y
        ldx     $2B
        dec     $01
        bpl     alien_spawn_shot_loop
alien_set_hover_timer:  lda     #$48
        sta     $0660,x
        lda     #$01
        sta     $0640,x
alien_hover_dec:  sec
        lda     $0660,x
        sbc     #$01
        sta     $0660,x
        lda     $0640,x
        sbc     #$00
        sta     $0640,x
alien_inc_timer:  inc     $04E0,x
        jsr     apply_entity_physics_alt
        rts

alien_set_palette:  lda     #$03
        sta     $02
alien_palette_copy_loop:  lda     alien_palette_data,y
        sta     $0356,x                 ; write alien palette
        sta     $0376,x
        sta     $0386,x
        sta     $0396,x
        sta     $03A6,x
        iny
        inx
        dec     $02
        bpl     alien_palette_copy_loop
        rts

alien_palette_data:  .byte   $0F,$21,$21,$21,$0F,$31,$35,$21 ; Alien Wily palette cycle data
        .byte   $0F,$30,$25,$10,$0F,$30,$15,$0F
        .byte   $08,$0C
alien_shot_flags_table:  .byte   $C3,$83 ; Alien Wily shot direction flags
alien_shot_x_offset_lo:  .byte   $1D,$E3
alien_shot_x_offset_hi:  .byte   $00,$FF,$5E,$20,$04,$A9,$FF,$9D
        .byte   $20,$01,$BC,$10,$01,$A9,$00,$99
        .byte   $40,$01,$38,$BD,$00,$04,$E9,$42
        .byte   $A8,$BE
        adc     heatman_flame_inc,y
        brk
        .byte   $20,$4C,$AF,$60,$BD,$E0,$04,$D0
        .byte   $33,$BD,$10,$01,$C9,$01,$B0,$12
        .byte   $A9,$3E
        sta     $04E0,x
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        inc     $0110,x
        bne     turret_dec_timer
        bne     turret_deactivate
        lda     #$C0
        sta     $0660,x
        lda     #$FE
        sta     $0640,x
        lda     #$0B
        sta     $04E0,x
        inc     $0110,x
        bne     turret_dec_timer
turret_deactivate:  lsr     $0420,x
        rts

turret_dec_timer:  dec     $04E0,x
        jsr     apply_entity_physics
        rts

        .byte   $BD,$10,$01,$C9,$02,$D0,$03,$4C
        .byte   $A6,$A4
        lda     $04E0,x
        bne     drop_boss_dec_timer
        lda     $0110,x
        bne     drop_boss_advance
        lda     #$1A
        sta     $04E0,x
        lda     #$00
        sta     $0600,x
        sta     $0620,x
        lda     #$03
        sta     $0640,x
        lda     #$33
        sta     $0660,x
        inc     $0110,x
        bne     drop_boss_dec_timer
drop_boss_advance:  inc     $0110,x
        rts

drop_boss_dec_timer:  dec     $04E0,x
        jsr     apply_entity_physics
        rts

        .byte   $BD
        bpl     scworm_init
        .byte   $F0

; =============================================================================
; scworm_init -- Enemy AI: Scworm — pipe worm, tile-check movement ($B01F)
; =============================================================================
scworm_init:  .byte   $03
        jmp     scworm_anim

        ldy     #$00
        sty     $0B
        lda     $0420,x
        and     #$40
        bne     scworm_calc_tile
        iny
scworm_calc_tile:  clc
        lda     $0460,x
        adc     scworm_x_offset_table,y
        sta     jump_ptr
        lda     $0440,x
        adc     scworm_x_page_table,y
        sta     $09
        clc
        lda     $04A0,x
        adc     #$09
        sta     $0A
        jsr     lookup_tile_from_map
        ldx     $2B
        lda     $00
        beq     scworm_flip
        lda     $04A0,x
        sta     $0A
        jsr     lookup_tile_from_map
        ldx     $2B
        lda     $00
        beq     scworm_set_speed
scworm_flip:  lda     $0420,x
        eor     #$40                    ; flip facing direction
        sta     $0420,x
scworm_set_speed:  lda     #$00
        sta     $0600,x
        lda     #$41
        sta     $0620,x
        sec
        lda     $04A0
        sbc     $04A0,x
        bcs     scworm_check_dist
        eor     #$FF
        adc     #$01
scworm_check_dist:  cmp     #$05
        bcs     scworm_resume
        lda     #$00
        sta     $0620,x
        lda     #$02
        sta     $0600,x
        lda     $0420,x
        pha
        jsr     entity_face_player
        pla
        sta     $0420,x
        lda     $00
        cmp     #$11
        bcs     scworm_resume
        lda     #$01
        sta     $06A0,x
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $04A0,x
        lda     #$70
        sta     $04E0,x
        lda     $0420,x
        and     #$F7
        sta     $0420,x
        inc     $0110,x
        bne     scworm_anim
scworm_resume:  lda     #$00
        sta     $06A0,x
        lda     #$07
        sta     $06E0,x
        jsr     apply_entity_physics
        rts

scworm_anim:  lda     $06A0,x
        cmp     #$05
        bne     scworm_set_speed_val
        lda     #$01
        sta     $06A0,x
scworm_set_speed_val:  lda     #$09
        sta     $06E0,x
        dec     $04E0,x
        bne     scworm_physics
        dec     $0110,x
        lda     #$00
        sta     $06A0,x
        clc
        lda     $04A0,x
        adc     #$08
        sta     $04A0,x
scworm_physics:  jsr     apply_entity_physics_alt
        rts

scworm_x_offset_table:  .byte   $08,$F8 ; Scworm X check offset
scworm_x_page_table:  .byte   $00,$FF,$BD,$20,$06,$D0,$08,$A9
        .byte   $47,$20,$B5,$95,$90,$01,$60
        lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04E0,x
        bne     sniper_joe_done
        lda     #$3E
        sta     $04E0,x
        lda     #$06
        sta     $01
        lda     #$48
        jsr     find_entity_count_check
        lda     #$49
        jsr     find_entity_count_check
        bcs     sniper_joe_done
        lda     $0600,x
        asl     a
        sta     $01
        lda     #$02
        sta     $02

; =============================================================================
; sniper_joe_spawn_shot -- Enemy AI: Sniper Joe — shielded soldier, shoot and walk ($B137)
; Spawns entities $49/$48 (Sniper Joe bullets) from sniper_joe_type_table.
; =============================================================================
sniper_joe_spawn_shot:  ldy     $01
        lda     sniper_joe_type_table,y
        jsr     spawn_entity_from_parent ; spawn bullet
        bcs     sniper_joe_done
        ldx     $01
        clc
        lda     $0470,y
        adc     sniper_joe_x_offset_table,x
        sta     $0470,y
        lda     $0450,y
        adc     #$00
        sta     $0450,y
        .byte   $BD
sniper_joe_store_y:  sty     $B1
sniper_joe_store_val:  .byte   $99
        .byte   $B0
sniper_joe_data:  .byte   $04
        ldx     $2B
        inc     $01
        dec     $02
        bne     sniper_joe_spawn_shot
        inc     $0600,x
        lda     $0600,x
        cmp     #$03
        bne     sniper_joe_done
        lda     #$00
        sta     $0600,x
sniper_joe_done:  ldx     $2B
        dec     $04E0,x
        rts

sniper_joe_type_table:  eor     #$48    ; data: entity types $49/$48 = Sniper Joe bullets
        eor     #$48                    ;   (bytes: $49,$48,$49,$48,$49,$48)
        eor     #$48
sniper_joe_x_offset_table:  clc
        cli
        bvc     sniper_joe_shift
        plp
        rts

sniper_joe_check_above:  bpl     sniper_joe_store_y
        bpl     sniper_joe_store_val
        bpl     sniper_joe_data
        lda     #$00
        sta     $01
        sec
        lda     $04A0,x
        sbc     #$0C
        jmp     sniper_joe_store_a

        lda     #$04
        sta     $01
        clc
        lda     $04A0,x
        adc     #$0C
sniper_joe_store_a:  .byte   $85
sniper_joe_shift:  asl     a
        lda     #$00
        sta     $0B
        lda     $0460,x
        sta     jump_ptr
        lda     $0440,x
        sta     $09
        jsr     lookup_tile_from_map
        ldx     $2B
        lda     $0110,x
        bne     sniper_joe_timer_check
        lda     $00
        bne     sniper_joe_physics
        ldy     $01
        lda     sniper_joe_vel_fwd,y
        sta     $0660,x
        lda     sniper_joe_vel_hi_fwd,y
        sta     $0640,x
        inc     $0110,x
        lda     #$4B
        sta     $04E0,x
        bne     sniper_joe_physics
sniper_joe_timer_check:  ldy     $01
        lda     $04E0,x
        beq     sniper_joe_reverse
        dec     $04E0,x
        bne     sniper_joe_wall_check
sniper_joe_reverse:  lda     sniper_joe_vel_rev,y
        sta     $0660,x
        lda     sniper_joe_vel_hi_rev,y
        sta     $0640,x
sniper_joe_wall_check:  lda     $00
        beq     sniper_joe_physics
        lda     sniper_joe_vel_fwd,y
        sta     $0660,x
        lda     sniper_joe_vel_hi_fwd,y
        sta     $0640,x
sniper_joe_physics:  jsr     apply_entity_physics
        rts

sniper_joe_vel_fwd:  .byte   $41
sniper_joe_vel_rev:  .byte   $E5
sniper_joe_vel_hi_fwd:  brk
sniper_joe_vel_hi_rev:  .byte   $00,$BF,$1B,$FF,$FF,$A9,$47,$85
        .byte   $00,$4C,$52,$96,$BD,$10,$01,$F0
        .byte   $2A,$BD,$A0,$06,$C9,$05,$D0,$20
        .byte   $A9,$00,$9D,$80,$06,$BD,$E0,$04
        .byte   $D0,$43,$A9,$00,$85,$01,$20,$72
        .byte   $B2,$DE,$20,$06,$F0,$07,$A9,$1F
        .byte   $9D,$E0,$04,$D0,$30
        dec     $0110,x
        jmp     boss_proj_mgr_physics

        lda     $06A0,x
        bne     boss_proj_mgr_physics
        lda     #$00
        sta     $0680,x
        lda     $04E0,x
        bne     boss_proj_mgr_dec_timer
        lda     #$0A
        sta     $01
        jsr     boss_proj_mgr_fire
        inc     $0620,x
        lda     $0620,x
        cmp     #$06
        bne     boss_proj_mgr_set_timer
        inc     $0110,x
        bne     boss_proj_mgr_physics

; =============================================================================
; boss_proj_mgr_set_timer -- Boss Projectile Manager — timer-based firing with RNG ($B266)
; =============================================================================
boss_proj_mgr_set_timer:  lda     #$1F
        sta     $04E0,x
boss_proj_mgr_dec_timer:  dec     $04E0,x
boss_proj_mgr_physics:  jsr     apply_entity_physics_alt
        rts

boss_proj_mgr_fire:  ldx     $01
        lda     $4A
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
        ldx     $2B
        lda     #$25
        jsr     bank_switch_enqueue
        lda     #$4D
        jsr     spawn_entity_from_parent
        bcs     boss_fire_done
        ldx     $01
        lda     boss_fire_vel_y_sub,x
        sta     $0670,y
        lda     boss_fire_vel_y_hi,x
        sta     $0650,y
        lda     $0E
        sta     $0630,y
        lda     $0F
        sta     $0610,y
        sec
        lda     $04B0,y
        sbc     boss_fire_y_offset,x
        sta     $04B0,y
        lda     $0430,y
        and     #$40
        bne     boss_fire_adjust_x
        inx
        inx
boss_fire_adjust_x:  clc
        lda     $0470,y
        adc     boss_fire_x_offset,x
        sta     $0470,y
        lda     $0450,y
        adc     boss_fire_x_offset_hi,x
        sta     $0450,y
boss_fire_done:  ldx     $2B
        rts

boss_fire_rng_mask:  .byte   $23        ; boss fire RNG bitmask
boss_fire_rng_base:  .byte   $18
boss_fire_rng_divisor:  .byte   $30
boss_fire_vel_y_sub:  .byte   $E6
boss_fire_vel_y_hi:  .byte   $04
boss_fire_y_offset:  .byte   $0C
boss_fire_x_offset:  .byte   $0C
boss_fire_x_offset_hi:  .byte   $00,$F4,$FF,$1F,$60,$18,$D4,$02
        .byte   $00,$08,$00,$F8,$FF,$BD,$10,$01
        .byte   $D0,$44,$BD,$E0,$04,$D0,$28,$BD
        .byte   $A0,$06,$C9,$02,$D0,$2C,$A9,$87
        .byte   $9D,$20,$04,$20,$EE,$EF,$A9,$78
        .byte   $9D,$60,$06,$A9,$04,$9D,$40,$06
        .byte   $A9,$C9,$9D,$20,$06,$A9,$01,$9D
        .byte   $00,$06,$FE,$10,$01
        bne     multi_boss_physics
        lda     $06A0,x
        bne     multi_boss_dec_main_timer
        sta     $0680,x
multi_boss_dec_main_timer:  dec     $04E0,x

; =============================================================================
; multi_boss_physics -- Multi-Phase Boss — state machine with timer-based phase changes ($B32D)
; =============================================================================
multi_boss_physics:  jsr     apply_entity_physics_alt
        bcc     multi_boss_rts
        jmp     multi_boss_death_check

multi_boss_rts:  rts

multi_boss_fallthrough:  jmp     multi_boss_full_physics

        cmp     #$01
        bne     multi_boss_state_2
        lda     #$02
        sta     $06A0,x
        lda     $0640,x
        php
        lda     #$0F
        sta     $01
        lda     #$1C
        sta     $02
        jsr     check_horiz_tile_collision
        plp
        bpl     multi_boss_fallthrough
        lda     $00
        beq     multi_boss_fallthrough
        lda     #$21
        jsr     bank_switch_enqueue
        lda     #$03
        sta     $06A0,x
        lda     #$00
        sta     $0600,x
        sta     $0620,x
        sta     $0660,x
        sta     $0640,x
        sta     $0680,x
        lda     $0420,x
        and     #$FB
        sta     $0420,x
        lda     #$3E
        sta     $04E0,x
        dec     $0110,x
        sec
        lda     $04A0
        sbc     $04A0,x
        cmp     #$10
        bne     multi_boss_dec_timer
        lda     #$12
        sta     $04E0,x
        lda     #$02
        sta     $0110,x
        bne     multi_boss_dec_timer
multi_boss_state_2:  lda     $06A0,x
        bne     multi_boss_check_timer
        lda     #$00
        sta     $0680,x
multi_boss_check_timer:  lda     $04E0,x
        bne     multi_boss_dec_timer
        lda     #$25
        jsr     bank_switch_enqueue
        jsr     entity_face_player
        lda     #$35
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
        ldx     $2B
        cmp     #$06
        bne     multi_boss_set_short_timer
        lda     #$00
        sta     $0110,x
        lda     #$3F
        sta     $04E0,x
        bne     multi_boss_dec_timer
multi_boss_set_short_timer:  lda     #$12
        sta     $04E0,x
        inc     $0110,x
multi_boss_dec_timer:  dec     $04E0,x
multi_boss_full_physics:  jsr     apply_entity_physics
        bcc     multi_boss_rts_2
        jmp     multi_boss_death_check

multi_boss_rts_2:  rts

multi_boss_death_check:  lda     $06C0,x
        bne     multi_boss_rts_2
        lda     #$4F
        jsr     spawn_entity_from_parent
        bcs     multi_boss_rts_2
        lda     #$7E
        .byte   $99
        .byte   $F0
multi_boss_shot_vel_y_sub:  .byte   $04 ; multi-boss shot Y velocity table
        rts

        .byte   $6A,$A0,$88
multi_boss_shot_vel_y_hi:  .byte   $12,$58,$FB,$FC,$FD
multi_boss_shot_vel_x_sub:  .byte   $FE,$FF,$8C,$4E,$9A ; multi-boss shot X velocity table
multi_boss_shot_vel_x_hi:  .byte   $C2,$D2,$06,$07,$07,$07,$07,$20
        .byte   $EE,$EF,$A9,$00,$9D,$80,$06,$A9
        .byte   $0B,$85,$01,$A9,$0C,$85,$02,$20
        .byte   $CF,$F0,$BD,$A0,$06,$D0,$1A,$A9
        .byte   $00,$9D,$A0,$06,$BD,$E0,$04,$D0
        .byte   $4C,$FE,$A0,$06,$A9,$1F,$9D,$E0
        .byte   $04,$BD,$20,$04,$29,$F7,$9D,$20
        .byte   $04
        lda     $04E0,x
        bne     turret_boss_dec_timer
        lda     #$25
        jsr     bank_switch_enqueue
        lda     #$35
        jsr     spawn_entity_from_parent
        bcs     turret_boss_advance
        lda     #$02
        sta     $0610,y

; =============================================================================
; turret_boss_advance -- Turret Boss — stationary shooter with timer ($B469)
; =============================================================================
turret_boss_advance:  inc     $0110,x
        lda     $0110,x
        cmp     #$03
        bne     turret_boss_set_timer
        lda     #$00
        sta     $0110,x
        sta     $06A0,x
        lda     #$7E
        sta     $04E0,x
        lda     $0420,x
        ora     #$08
        sta     $0420,x
        bne     turret_boss_dec_timer
turret_boss_set_timer:  lda     #$1F
        sta     $04E0,x
turret_boss_dec_timer:  dec     $04E0,x
        jsr     apply_entity_physics
        rts

        .byte   $BD,$E0,$04,$D0,$2E,$A9,$20,$9D
        .byte   $E0,$04,$A9,$03,$85,$01,$A9,$51
        .byte   $20,$CF,$96
        bcs     turret_boss_physics
        jsr     entity_face_player
        lda     $00
        cmp     #$48
        bcs     turret_boss_physics
        lda     #$51
        jsr     spawn_entity_from_parent
        bcs     turret_boss_physics
        sec
        lda     $04B0,y
        sbc     #$0C
        sta     $04B0,y
        lda     #$1F
        sta     $04F0,y
turret_boss_physics:  dec     $04E0,x
        jsr     apply_entity_physics_alt
        rts

        .byte   $BD,$10,$01,$D0,$3B,$DE,$E0,$04
        .byte   $D0,$5A,$A9,$87,$9D,$20,$04,$20
        .byte   $EE,$EF,$A5,$4A,$29,$1F,$85,$01
        .byte   $38,$A5,$00,$E5,$01,$B0,$02,$A9
        .byte   $00
        sta     $00
        lda     #$00
        asl     $00
        rol     a
        asl     $00
        rol     a
        asl     $00
        rol     a
        sta     $0600,x
        lda     $00
        sta     $0620,x
        lda     #$04
        sta     $0640,x
        inc     $0110,x
        bne     jump_boss_check_anim
        cmp     #$02
        bcs     jump_boss_wall_timer
        lda     $0640,x
        php
        lda     #$05
        sta     $01
        lda     #$08
        sta     $02
        jsr     check_horiz_tile_collision
        plp
        bpl     jump_boss_check_anim
        lda     $00
        beq     jump_boss_check_anim
        lda     #$5D
        sta     $04E0,x
        inc     $0110,x
        bne     jump_boss_wall_timer
jump_boss_check_anim:  lda     $06A0,x
        cmp     #$0A
        bne     jump_boss_physics
        lda     #$06
        sta     $06A0,x
jump_boss_physics:  jsr     apply_entity_physics
        rts

jump_boss_wall_timer:  lda     $04E0,x
        beq     jump_boss_wall_physics
        dec     $04E0,x
        lda     $06A0,x
        cmp     #$0A
        bne     jump_boss_wall_physics
        lda     #$06
        sta     $06A0,x
jump_boss_wall_physics:  jsr     apply_entity_physics_alt
        rts

        .byte   $DE,$E0,$04,$F0,$04,$20,$B3,$EF
        .byte   $60
        lsr     $0420,x
        rts

        .byte   $A9,$7D,$D0,$06,$A9,$BB,$D0,$02
        .byte   $A9,$FA
        sta     $00
        lda     $0110,x
        bne     despawn_timer_phase_1
        lda     $00
        sta     $0160,x
        inc     $0110,x
        bne     despawn_timer_dec
despawn_timer_phase_1:  cmp     #$01
        bne     despawn_timer_phase_2
        lda     $0160,x
        bne     despawn_timer_dec
        lda     #$90
        sta     $0420,x
        lda     #$3C
        jsr     bank_switch_enqueue
        lda     #$7D
        sta     $0160,x
        inc     $0110,x
        lda     #$00
        sta     $0680,x
        sta     $06A0,x
        beq     despawn_timer_dec
despawn_timer_phase_2:  lda     $06A0,x
        cmp     #$05
        bne     despawn_phase_3_setup
        lda     #$00
        sta     $0680,x
despawn_phase_3_setup:  lda     #$01
        sta     $04E0,x
        lda     $0460,x
        and     $0600,x
        sta     $0640,x
        lda     $04A0,x
        and     $0620,x
        sta     $0660,x
        lda     $0160,x
        bne     despawn_timer_dec
        lda     #$A0
        sta     $0420,x
        lda     #$7D
        sta     $0160,x
        dec     $0110,x
despawn_timer_dec:  dec     $0160,x
        jsr     apply_entity_physics_alt
        rts

        .byte   $A5,$2A,$C9,$0C,$F0,$33,$5E,$20
        .byte   $04,$A9,$FF,$9D,$F0,$00,$A5,$2A
        .byte   $C9,$0A,$F0,$19,$38,$BD,$40,$04
        .byte   $E9,$0A,$0A,$0A,$0A,$A8,$A2,$00
stage_palette_copy_loop:  lda     stage_palette_entries,y
        sta     $035E,x
        iny
        inx
        cpx     #$08
        bne     stage_palette_copy_loop
        rts

        lda     #$0F
        sta     $0363
        sta     $0364
        sta     $0365
        rts

        lda     $AA
        beq     stage_boss_jmp
        jsr     apply_entity_physics_alt
        rts

stage_boss_jmp:  jmp     wily4_enemy_shared_ai

stage_palette_entries:  .byte   $0F,$39,$18,$12,$0F,$39,$18,$01 ; stage palette entries for boss rooms
        .byte   $0F,$39,$18,$01,$0F,$39,$18,$01
        .byte   $0F,$39,$18,$01,$0F,$39,$18,$0F
        .byte   $BD,$10,$01,$D0,$5B,$A9,$03,$85
        .byte   $01,$A9,$04,$85,$02,$20,$CF,$F0
        .byte   $A5,$03,$F0,$04,$5E,$20,$04,$60
        lda     $00
        beq     wily_boss_physics
        lda     #$04
        sta     $01
wily_boss_spawn_loop:  lda     #$58
        jsr     spawn_entity_from_parent
        bcs     wily_boss_setup_vel
        ldx     $01
        lda     wily_boss_vel_table,x
        sta     $0670,y
        lda     wily_boss_vel_hi_table,x
        sta     $0650,y
        lda     #$01
        sta     $0120,y
        lda     #$1F
        sta     $04F0,y
        ldx     $2B
        dec     $01
        bne     wily_boss_spawn_loop
wily_boss_setup_vel:  lda     #$81
        sta     $0420,x
        lda     #$00
        sta     $0660,x
        sta     $0640,x
        sta     $0620,x
        sta     $0600,x
        lda     #$1F
        sta     $04E0,x
        inc     $0110,x
        lda     $0110,x
        cmp     #$01
        bne     wily_boss_timer_check
        dec     $04E0,x
        bne     wily_boss_physics
        clc
        lda     $0660,x
        eor     #$FF
        adc     #$01
        sta     $0660,x
        lda     $0640,x
        eor     #$FF
        adc     #$00
        sta     $0640,x
        inc     $0110,x
        lda     #$1F
        sta     $04E0,x
        bne     wily_boss_physics
wily_boss_timer_check:  dec     $04E0,x
        bne     wily_boss_physics
        lsr     $0420,x
        rts

wily_boss_physics:  jsr     apply_entity_physics
        rts

wily_boss_vel_table:  .byte   $00,$41,$82,$C4,$06 ; Wily boss velocity table
wily_boss_vel_hi_table:  .byte   $00,$00,$00,$00,$01,$BD,$10,$01
        .byte   $D0
        ora     $E0DE,x
        .byte   $04,$D0,$2F,$FE,$10,$01,$A9,$1F
        .byte   $9D,$E0,$04,$A9,$00,$9D,$00,$06
        .byte   $9D,$20,$06,$9D,$40,$06,$9D,$60
        .byte   $06,$F0,$17
        cmp     #$01
        bne     falling_platform_physics
        dec     $04E0,x
        bne     falling_platform_physics
        inc     $0110,x
        lda     #$00
        sta     jump_ptr
        lda     #$04
        sta     $09
        jsr     calc_entity_velocity
falling_platform_physics:  jsr     apply_entity_physics
        rts

        .byte   $BD,$40,$06,$08,$A9,$07,$85,$00
        .byte   $A9,$08,$85,$02,$20,$CF,$F0,$28
        .byte   $10,$0E,$A5,$00,$F0,$0A,$A9,$03
        .byte   $9D,$40,$06,$A9,$76,$9D,$60,$06
        lda     $03
        beq     beam_boss_physics
        lsr     $0420,x
beam_boss_physics:  jsr     apply_entity_physics
        rts

        .byte   $BD,$E0,$04,$F0,$13,$DE,$E0,$04
        .byte   $D0,$0E,$A9,$00,$9D,$00,$06,$9D
        .byte   $20,$06,$9D,$60,$06,$9D,$40,$06
        jsr     apply_entity_physics
        rts

        .byte   $BD,$E0,$04,$D0,$3A,$A9,$00,$9D
        .byte   $A0,$06,$9D,$80,$06,$A9,$07,$85
        .byte   $01,$A9,$08,$85,$02,$20,$2C,$F0
        .byte   $A5,$00,$D0,$03,$4C,$08,$B8
        lda     #$00
        sta     $0620,x
        sta     $0600,x
        sta     $0660,x
        sta     $0640,x
        inc     $06A0,x
        lda     #$2E
        jsr     bank_switch_enqueue
        lda     #$1F
        sta     $0110,x
        inc     $04E0,x
        bne     beam_boss_check_anim
        cmp     #$01
        bne     beam_pattern_check
        dec     $0110,x
        bne     beam_boss_check_anim
        inc     $04E0,x
        lda     #$38
        sta     $0110,x
beam_pattern_check:  lda     $0110,x
        and     #$07
        bne     beam_pattern_done
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     $0110,x
        lsr     a
        and     #$0C
        sta     $02
        ldx     #$04
        sta     $01
beam_pattern_spawn_loop:  lda     #$5F
        jsr     spawn_entity_from_parent
        bcs     beam_pattern_done
        ldx     $02
        clc
        lda     $04B0,y
        adc     $E11F,x
        sta     $04B0,y
        clc
        lda     $0470,y
        adc     $E12F,x
        sta     $0470,y
        lda     $0450,y
        adc     $E13F,x
        sta     $0450,y
        ldx     $2B
        inc     $02
        dec     $01
        bne     beam_pattern_spawn_loop
beam_pattern_done:  ldx     $2B
        dec     $0110,x
        bpl     beam_boss_check_anim
        lsr     $0420,x
        rts

beam_boss_check_anim:  lda     $06A0,x
        cmp     #$04
        bne     beam_boss_apply_physics
        lda     #$02
        sta     $06A0,x
beam_boss_apply_physics:  jsr     apply_entity_physics
        rts

        .byte   $BD,$E0,$04,$D0,$09,$A9,$00,$9D
        .byte   $80,$06,$20,$BA,$EE,$60
        lda     $06A0,x
        ora     $0680,x
        bne     gravity_boss_accel
        lda     $0420,x
        eor     #$40
        sta     $0420,x
        lda     #$FE
        sta     $0640,x
        lda     #$00
        sta     $0660,x
gravity_boss_accel:  clc
        lda     $0660,x
        adc     #$20
        sta     $0660,x
        lda     $0640,x
        adc     #$00
        sta     $0640,x
        jsr     apply_entity_physics
        rts

        .byte   $A5,$2A,$C9,$08,$F0,$15,$A9,$58
        .byte   $9D,$50,$01,$38,$BD,$A0,$04,$E9
        .byte   $18,$9D,$60,$01,$A5,$AA,$D0,$20
        .byte   $4C,$7A,$B9
        lda     #$10
        sta     $0150,x
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $0160,x
        lda     $AA
        bne     shield_boss_physics
        jsr     apply_entity_physics
        bcc     shield_boss_rts
        lda     #$00
        sta     $0150,x
shield_boss_rts:  rts

shield_boss_physics:  jsr     apply_entity_physics_alt
        rts

        .byte   $BD,$E0,$04,$10,$01,$60
        bne     wily4_boss_active
        lda     $15
        sta     $14
        inc     $38
        lda     #$07
        sta     $06C0,x
        lda     #$08
        sta     $B3
        lda     #$01
        sta     $B1
        lda     #$17
        sta     $03B6
        lda     #$E0
        sta     $03B7
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
wily4_palette_loop:  sta     $0356,x
        dex
        bpl     wily4_palette_loop
        ldx     $2B
        inc     $04E0,x
        lda     #$18
        sta     $0110,x
        lda     #$63
        sta     $00
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
        lda     $04E0,x
        cmp     #$01
        bne     wily4_boss_phase_2
        dec     $0110,x
        bne     wily4_boss_rts
        lda     #$40
        sta     $0110,x
        lda     #$63
        jsr     spawn_entity_from_parent
        lda     #$01
        sta     $0610,y
        sta     $04F0,y
        dec     $06C0,x
        bne     wily4_boss_rts
        inc     $04E0,x
        rts

wily4_boss_phase_2:  dec     $0110,x
        bne     wily4_boss_rts
        ldy     $06C0,x
        lda     wily4_timer_table,y     ; look up spawn timing
        sta     $0110,x
        bmi     wily4_boss_despawn_all
        lda     wily4_y_pos_table,y
        sta     $02
        lda     #$63
        jsr     spawn_entity_from_parent
        lda     $02
        sta     $04B0,y
        lda     #$01
        sta     $0610,y
        inc     $06C0,x
wily4_boss_rts:  rts

wily4_boss_despawn_all:  lda     #$63
        sta     $00
        ldy     #$0F
wily4_despawn_loop:  jsr     find_entity_scan
        bcs     wily4_despawn_done
        lda     #$00
        sta     $0610,y
        dey
        bpl     wily4_despawn_loop
wily4_despawn_done:  ldx     $2B
        lda     #$FF
        sta     $04E0,x
        inc     $B1
        lda     #$0B
        jsr     bank_switch_enqueue
        rts

wily4_timer_table:  .byte   $40,$01,$20,$28,$FF ; Wily stage 4 spawn timer table
wily4_y_pos_table:  .byte   $98,$98,$48,$78 ; Wily stage 4 Y position table
wily4_enemy_shared_ai:  lda     $0641
        sta     $0640,x
        lda     $0661
        sta     $0660,x
wily4_shared_velocity:  lda     $0601
        sta     $0600,x
        lda     $0621
        sta     $0620,x
        lda     $05A7
        sta     $0420,x
        jsr     apply_entity_physics
        lda     $B3
        cmp     #$08
        beq     wily4_shared_set_flags
        lda     $0400,x
        cmp     #$69
        beq     wily4_shared_set_flags
        lda     $0420,x
        ora     #$23
        sta     $0420,x
        rts

wily4_shared_set_flags:  lda     #$8B
        sta     $0420,x
        rts

        .byte   $A9
        brk
        sta     $06A0,x
        lda     $05A7
        and     #$40
        beq     wily4_facing_setup
        inc     $06A0,x
wily4_facing_setup:  lda     #$00
        sta     $0680,x
        jmp     wily4_enemy_shared_ai

        .byte   $A5,$2A,$C9,$08,$F0,$03,$4C,$7A
        .byte   $B9
        jsr     apply_entity_physics
        lda     $04A0,x
        cmp     #$80
        bne     wily4_pos_reset_anim
        lda     #$00
        sta     $0640,x
        lda     $06A0,x
        ora     $0680,x
        bne     wily4_pos_check_rts
        inc     $04E1
        lsr     $0420,x
wily4_pos_check_rts:  rts

wily4_pos_reset_anim:  lda     #$00
        sta     $06A0,x
        sta     $0680,x
        rts

        .byte   $BD,$E0,$04,$D0,$13,$A9,$80,$9D
        .byte   $60,$06,$A9,$FF,$9D,$40,$06,$BD
        .byte   $A0,$04,$C9,$7F,$90,$1B,$B0,$11
        lda     #$80
        sta     $0660,x
        lda     #$00
        sta     $0640,x
        lda     $04A0,x
        cmp     #$68
        bcs     wily_capsule_jmp_shared
        lda     #$00
        sta     $0640,x
        sta     $0660,x

; =============================================================================
; wily_capsule_jmp_shared -- Wily Capsule Teleport AI — teleportation and attack pattern ($BA2F)
; =============================================================================
wily_capsule_jmp_shared:  jmp     wily4_shared_velocity

        .byte   $BD,$A0,$06,$D0,$2F,$9D,$80,$06
        .byte   $DE,$10,$01,$D0,$23,$BD,$20,$04
        .byte   $29,$40,$D0,$04,$5E,$20,$04,$60
        clc
        lda     $0460,x
        adc     #$08
        sta     $0460,x
        inc     $06A0,x
        lda     #$01
        sta     $0160,x
        lda     #$0F
        sta     $0110,x
        bne     wily_teleport_ai
        jsr     apply_entity_physics
        rts

wily_teleport_ai:  lda     $0160,x
        bne     wily_teleport_stop_vel
        dec     $0110,x
        beq     wily_teleport_pause
        lda     $0460,x
        cmp     #$30
        bcc     wily_teleport_pause
        cmp     #$D0
        bcs     wily_teleport_pause
        lda     $04A0,x
        cmp     #$30
        bcc     wily_teleport_pause
        cmp     #$C0
        bcc     wily_teleport_check_anim
wily_teleport_pause:  lda     #$01
        sta     $0160,x
        lda     #$3E
        sta     $0110,x
wily_teleport_stop_vel:  lda     #$00
        sta     $0600,x
        sta     $0620,x
        sta     $0660,x
        sta     $0640,x
        dec     $0110,x
        bne     wily_teleport_check_anim
        lda     #$83
        sta     $0420,x
        lda     #$01
        sta     $06E0,x
        lda     #$00
        sta     $0160,x
        ldy     $04E0,x
        lda     wily_teleport_timer_table,y
        sta     $0110,x
        lda     wily_teleport_target_lo,y
        sta     jump_ptr
        lda     wily_teleport_target_hi,y
        sta     $09
        jsr     calc_entity_velocity
wily_teleport_check_anim:  lda     $06A0,x
        cmp     #$06
        bne     wily_teleport_set_anim
        lda     #$04
        sta     $06A0,x
wily_teleport_set_anim:  jsr     apply_entity_physics
        bcc     wily_teleport_rts
        sec
        lda     $06C1
        sbc     #$02
        sta     $06C1
wily_teleport_rts:  rts

wily_teleport_timer_table:  .byte   $3E,$1F,$1F,$1F ; Wily teleport timing table
wily_teleport_target_lo:  .byte   $00,$68,$00,$80
wily_teleport_target_hi:  .byte   $01,$01,$02,$02,$A5,$B1,$C9,$04
        .byte   $B0,$15,$18,$BD,$60,$06,$69,$40
        .byte   $9D,$60,$06,$BD,$40,$06,$69,$00
        .byte   $9D,$40,$06

; =============================================================================
; wily_final_physics -- Wily Final Boss — gravity, movement, and multi-phase AI ($BB06)
; =============================================================================
wily_final_physics:  jsr     apply_entity_physics
        rts

        lda     #$07
        sta     $01
        lda     #$08
        sta     $02
        jsr     check_vert_tile_collision
        lda     $00
        beq     wily_final_physics
        lda     #$04
        sta     $0640,x
        lda     #$78
        sta     $0660,x
        bne     wily_final_physics
        sec
        lda     $0620,x
        sbc     #$01
        sta     $0620,x
        tay
        lda     $0600,x
        sbc     #$00
        sta     $0600,x
        bne     beam_boss_check_state
        cpy     #$00
        beq     beam_boss_reset_counter
        cpy     #$3E
        bcs     beam_boss_check_state
        lda     $06A0,x
        cmp     #$06
        bne     beam_boss_run_physics
        lda     #$04
        bne     beam_boss_set_state
beam_boss_reset_counter:  lda     #$77
        sta     $0620,x
        lda     #$01
        sta     $0600,x
        lda     #$6E
        ldx     #$01
        jsr     spawn_entity_from_parent
        bcs     beam_boss_check_state
        txa
        pha
        tya
        adc     #$10
        tax
        stx     $2B
        lda     #$08
        sta     $09
        lda     #$00
        sta     jump_ptr
        jsr     calc_entity_velocity
        pla
        tax
        stx     $2B
beam_boss_check_state:  lda     $06A0,x
        cmp     #$04
        bne     beam_boss_run_physics
        lda     #$00
beam_boss_set_state:  sta     $06A0,x
beam_boss_run_physics:  jsr     apply_entity_physics_alt
        bcc     beam_boss_rts
        sec
        lda     $06C1
        sbc     #$06
        sta     $06C1
        bcs     beam_boss_rts
        lda     #$00
        sta     $06C1
beam_boss_rts:  rts

        lda     #$00
        sta     $0680,x
        ldy     $06A0,x
        clc
        lda     $0460,x
        adc     wily_final_x_adjust_table,y
        sta     $0460,x
        rts

wily_final_x_adjust_table:  .byte   $03,$02,$20,$EE,$EF,$BD,$E0,$04
        .byte   $D0,$22,$A5,$00,$C9,$38
        bcs     wily_final_apply_physics
        lda     $4A
        sta     $01
        lda     #$03
        sta     $02
        jsr     divide_8bit
        ldy     $04
        ldx     $2B
        lda     wily_final_timer_table,y
        sta     $0110,x
        inc     $04E0,x
wily_final_apply_physics:  jsr     apply_entity_physics_alt
        rts

        cmp     #$02
        bcs     wily_final_gravity
        lda     $00
        cmp     #$38
        bcc     wily_final_timer_check
        dec     $04E0,x
        beq     wily_final_apply_physics
wily_final_timer_check:  dec     $0110,x
        bne     wily_final_apply_physics
        lda     #$02
        sta     $0640,x
        lda     #$00
        sta     $0660,x
        lda     #$83
        sta     $0420,x
        inc     $04E0,x
wily_final_gravity:  lda     $0640,x
        bpl     wily_final_rise_check
        lda     $04A0,x
        cmp     #$E0
        bcc     wily_final_physics_2
        lda     #$00
        sta     $04E0,x
        lda     #$A0
        sta     $0420,x
        bne     wily_final_physics_2
wily_final_rise_check:  lda     $04A0,x
        cmp     #$80
        bcs     wily_final_physics_2
        lda     #$FF
        sta     $0660,x
        sta     $0640,x
        lda     #$87
        sta     $0420,x
wily_final_physics_2:  jsr     apply_entity_physics
        rts

wily_final_timer_table:  .byte   $1F,$2E,$7D,$BD,$E0,$04,$C9,$3E ; Wily final boss timer table
wily_final_bank_table:  .byte   $D0,$2F,$BD,$A0,$06,$C9,$05,$D0 ; Wily final boss bank switch table
        .byte   $37,$BD,$80,$06,$D0,$32,$A9,$74
        .byte   $20,$59,$F1,$B0,$17,$BD,$00,$04
        .byte   $99,$F0,$04,$18,$B9,$B0,$04,$69
        .byte   $04,$99,$B0,$04,$A9,$FF,$99,$50
        .byte   $06,$99,$70,$06
        lda     #$00
        sta     $04E0,x
        inc     $04E0,x
        lda     $06A0,x
        cmp     #$02
        bne     wily_final_check_anim
        lda     #$00
        sta     $06A0,x
wily_final_check_anim:  jsr     apply_entity_physics_alt
        rts

        .byte   $BD,$A0,$06,$F0,$04,$20,$B3,$EF
        .byte   $60
        lda     #$00
        sta     $0680,x
        lda     #$03
        sta     $01
        lda     #$04
        sta     $02
        jsr     check_vert_tile_collision
        lda     $00
        beq     wily_final_check_physics
        ldy     $04E0,x
        lda     wily_final_bank_table,y
        jsr     bank_switch_enqueue
        inc     $06A0,x
        rts

wily_final_check_physics:  jsr     apply_entity_physics
        rts

        and     mecha_dragon_store_screen,x
        .byte   $07
        sta     $01
        ldy     #$08
        bne     walker_check_state
        lda     #$03
        sta     $01
        ldy     #$04

; =============================================================================
; walker_check_state -- Generic Walker Enemy — simple walking AI with physics ($BCB7)
; =============================================================================
walker_check_state:  lda     $0420,x
        cmp     #$81
        beq     walker_stopped_state
        lda     $01
        pha
        tya
        pha
        jsr     apply_entity_physics
        pla
        sta     $02
        pla
        sta     $01
        lda     $0420,x
        bpl     walker_rts
        lda     $0640,x
        php
        jsr     check_horiz_tile_collision
        plp
        bpl     walker_rts
        lda     $00
        beq     walker_rts
        lda     #$FA
        sta     $0110,x
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        lda     #$81
        sta     $0420,x
walker_rts:  rts

walker_stopped_state:  lda     $04E0,x
        beq     walker_simple_physics
        dec     $0110,x
        bne     walker_stopped_physics
        lsr     $0420,x
        rts

walker_stopped_physics:  jsr     apply_entity_physics_alt
        rts

walker_simple_physics:  jsr     apply_simple_physics ; apply simple movement
        rts

        ldy     #$25
        lda     $1C
        and     #$08
        bne     boss_indicator_palette
        ldy     #$0F

; =============================================================================
; boss_indicator_palette -- Boss Room Indicator — palette flash to signal boss door ($BD12)
; =============================================================================
boss_indicator_palette:  sty     $0371
        jsr     apply_entity_physics_alt
        lda     $01
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
LBFFF:  .byte   $FF
