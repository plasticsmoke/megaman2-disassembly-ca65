.segment "BANK0B"

; =============================================================================
; Bank $0B — Game Logic & Enemy AI
; Enemy AI dispatch, boss initialization, collision detection, projectile
; management, and sprite handling for all enemy types.
; =============================================================================

; da65 V2.18 - Ubuntu 2.19-1
; Created:    2026-02-23 18:17:35
; Input file: build/bank0B.bin
; Page:       1


        .setcpu "6502"

.include "include/hardware.inc"
.include "include/ram.inc"
.include "include/zeropage.inc"
.include "include/constants.inc"

addr_0508           := $0508
addr_0917           := $0917
ppu_addr_2020           := $2020
ppu_addr_2220           := $2220
ppu_addr_2820           := $2820
bank_switch_enqueue           := $C051
boss_death_sequence           := $C10B
explosion_array_setup_inner           := $C3A8
sound_column_copy           := $C5F1
divide_8bit           := $C84E
divide_16bit           := $C874
metatile_render           := $C8EF
scroll_attr_update           := $CA0B
tile_lookup           := $CC63
fixed_D0B0           := $D0B0
fixed_D332           := $D332
fixed_D3E0           := $D3E0
fixed_D77C           := $D77C
fixed_DA43           := $DA43
        jmp     boss_init

        lda     #$01
        sta     current_entity_slot
        ldy     $B3
        lda     $AA
        and     #$01
        beq     *+10
        lda     enemy_spawn_timer_table,y
        beq     *+5
        jmp     $8063
        ldx     $B1
        bpl     enemy_ai_dispatch
        jmp     enemy_ai_fallback


; =============================================================================
; Enemy AI Dispatch
; Dispatches to enemy-specific AI routine based on Y index.
; 14 entries: 8 Robot Masters + 6 Wily fortress enemies.
; =============================================================================
enemy_ai_dispatch:  lda     enemy_ai_routine_lo,y; Dispatch to AI routine via pointer table
        sta     jump_ptr
        lda     enemy_ai_routine_hi,y
        sta     jump_ptr_hi
        jmp     (jump_ptr)

enemy_spawn_timer_table:  .byte   $0F,$0F,$0F,$0F,$1E,$0F,$0F,$0F
        .byte   $0F,$0F,$0F,$0F,$0F,$0F
enemy_spawn_enable_table:  .byte   $00,$00,$00,$00,$01,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00
enemy_ai_routine_lo:  .byte   $C5,$E3,$FB,$56,$9E,$56,$20,$C3
        .byte   $10,$13,$9B,$6E,$C0,$2A
enemy_ai_routine_hi:  .byte   $80,$82,$84,$86,$87,$89,$8B,$8C
        .byte   $8E,$92,$93,$96,$96,$9B
        lda     #$00
        sta     $0681
        jsr     setup_ppu_normal
        lda     current_weapon
        cmp     #$06
        bne     boss_spawn_done
        lda     $0422
        bpl     boss_spawn_done
        lda     $B1
        cmp     #$02
        bcc     boss_spawn_done
        lda     $B3
        cmp     #$05
        beq     boss_spawn_special_type
        cmp     #$0D
        bne     boss_spawn_inc_timer
boss_spawn_special_type:  lda     #MAX_HP
        sta     $06C1
        bne     boss_spawn_done
boss_spawn_inc_timer:  inc     $05A6
        ldx     $B3
        lda     $05A6
        cmp     enemy_spawn_timer_table,x
        bne     boss_spawn_done
        lda     #$00
        sta     $05A6
        lda     enemy_spawn_enable_table,x
        beq     boss_spawn_done
        sec
        lda     $06C1
        sbc     enemy_spawn_enable_table,x
        beq     boss_spawn_deplete
        bcs     boss_spawn_store_count
boss_spawn_deplete:  lda     #$00
        lsr     $0422
        lda     #$00
        sta     $AA
        lda     #$01
        sta     $50
        inc     $05AA
        lda     #$00
boss_spawn_store_count:  sta     $06C1
boss_spawn_done:  rts

        dex
        lda     $82D9,x
        sta     jump_ptr
        lda     $82DE,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)
        lda     $04E1
        bne     *+44
        ldy     $B3
        lda     $813E,y
        sta     temp_01
        lda     $8146,y
        sta     temp_02
        jsr     boss_floor_collision_check
        lda     temp_00
        bne     *+14
        lda     #$00
        sta     $06A1
        sta     $0681
boss_frame_update_rts:  jsr     boss_apply_movement_physics
        rts

        lda     #$00
        sta     $0641
        sta     $0661
        inc     $04E1
        lda     $06A1
        ldy     $B3
        cmp     enemy_state_transition,y
        bne     boss_frame_update_rts
        sta     $06A1
        lda     #$00
        sta     $0681
        lda     $06C1
        cmp     #MAX_HP
        bne     boss_palette_timer_tick
boss_activate_phase:  lda     #$02
        sta     $B1
        lda     #$00
        sta     $B2
        sta     $04E1
        ldy     $B3
        lda     enemy_spawn_sound_ids,y
        jsr     play_sound_and_reset_anim
        rts

boss_palette_timer_tick:  lda     frame_counter
        and     #$03
        bne     boss_palette_tick_rts
        inc     $06C1                   ; increment health bar fill
        lda     #$28
        jsr     bank_switch_enqueue
boss_palette_tick_rts:  rts

        .byte   $09,$0C,$0F,$0A,$09,$09,$08,$08
        .byte   $0C,$10,$10,$0C,$0C,$0C,$0C,$0C
enemy_state_transition:  .byte   $0F,$0F,$0B,$05,$09,$07,$05,$03
enemy_spawn_sound_ids:  .byte   $51,$67,$6D
        adc     ($55,x)
        .byte   $5C,$64,$6A
        lda     #$58
        jsr     find_entity_by_type
        bcs     *+12
        lda     $06A1
        bne     heatman_frame_update
        sta     $0681
        beq     heatman_frame_update
        lda     $0681
        bne     heatman_frame_update
        lda     $06A1
        cmp     #$02
        bne     heatman_frame_update
        jsr     calc_player_boss_distance
        lda     temp_00
        sta     temp_03
        clc
        adc     #$20
        sta     temp_02
        sec
        sbc     #$40
        bcs     heatman_store_aim_low
        lda     #$00
heatman_store_aim_low:  sta     temp_04
        lda     #$02
        sta     temp_01


; =============================================================================
; Boss AI: Heat Man — projectile spawning and movement patterns ($8194)
; =============================================================================
heatman_spawn_projectile_loop:  ldx     temp_01
        lda     #$00
        sta     $0A
        sta     $0C
        lda     temp_02,x
        sta     $0B
        lda     heatman_proj_speed_table,x
        sta     $0D
        jsr     divide_16bit            ; divide for velocity ratio
        ldx     #$01
        lda     #$58
        jsr     spawn_entity_from_boss
        ldx     temp_01
        lda     heatman_proj_hitbox_y,x
        sta     $0670,y
        lda     heatman_proj_hitbox_mask,x
        sta     $0650,y
        lda     $0E
        sta     $0630,y
        lda     $0F
        sta     $0610,y
        lda     ent_spawn_flags,y
        ora     #$04
        sta     ent_spawn_flags,y
        dec     temp_01
        bpl     heatman_spawn_projectile_loop
heatman_frame_update:  ldx     #$01
        jsr     boss_check_weapon_hit
        lda     temp_02
        cmp     #$01
        bne     heatman_attack_rts
        bne     heatman_attack_rts
        lda     #$04
        sta     $B1
        lda     #$12
        sta     $05A8
        lda     #$53
        jsr     play_sound_and_reset_anim
heatman_attack_rts:  rts

        .byte   $0F,$15,$0F,$0F,$0F
heatman_proj_hitbox_y:  rol     current_lives,x
        .byte   $76
heatman_proj_hitbox_mask:  .byte   $07
        ora     temp_03
heatman_proj_speed_table:  .byte   $3A,$2E,$1C
        lda     $04E1
        bne     *+55
        lda     $06A1
        cmp     #$02
        bne     *+7
        lda     #$00
        sta     $06A1
        dec     $B2
        bne     heatman_frame_update
        lda     #$03
        sta     $06A1
        lda     #$00
        sta     $0681
        lda     #$11
        sta     $06E1
        jsr     calc_player_boss_distance
        lda     temp_00
        lsr     a
        lsr     a
        clc
        adc     #$0A
        sta     $B2
        lda     #$38
        jsr     bank_switch_enqueue
        inc     $04E1
        bne     heatman_frame_update
        cmp     #$01
        bne     heatman_check_death_anim
        lda     $06A1
        cmp     #$06
        bcc     heatman_check_anim_state
        ldy     #$04
        sty     $0601
heatman_check_anim_state:  cmp     #$09
        bne     heatman_dec_timer
        lda     #$06
        sta     $06A1
heatman_dec_timer:  lda     $B2
        beq     heatman_phase3_reset
        dec     $B2
        bne     heatman_jmp_frame_update
heatman_phase3_reset:  lda     #$00
        sta     $0601
        sta     $0681
        lda     #$01
        sta     $06E1
        lda     #$0A
        sta     $06A1
        inc     $04E1
        bne     heatman_jmp_frame_update
heatman_check_death_anim:  lda     $06A1
        cmp     #$0D
        bne     heatman_jmp_frame_update
        lda     #$50
        jsr     play_sound_and_reset_anim
        lda     #$83
        sta     $0421
        jsr     calc_player_boss_distance
        inc     ent_anim_id,x
        lda     #$05
        sta     $B1
heatman_jmp_frame_update:  jmp     heatman_frame_update

heatman_random_delay_table:  .byte   $1F,$3E,$5D
        lda     $06A1
        beq     *+53
        dec     $B1
        lda     #$8B
        ldx     $0461
        cpx     #$80
        bcs     *+4
        lda     #$CB
        sta     $0421
        lda     #$00
        sta     $04E1
        sta     $B4
        lda     rng_seed
        sta     temp_01
        lda     #$03
        sta     temp_02
        jsr     divide_8bit
        ldx     temp_04
        lda     heatman_random_delay_table,x
        sta     $B2
        lda     #$52
        jsr     play_sound_and_reset_anim
        lda     #$38
        jsr     bank_switch_enqueue
        jsr     boss_apply_movement_physics
        rts

        lda     $06A1
        cmp     #$04
        beq     *+5
        jmp     heatman_frame_update
        jmp     boss_activate_phase

        .byte   $D3,$5E,$FD,$90,$CC,$80,$81,$81
        .byte   $82,$82
        dex
        lda     $84F3,x
        sta     jump_ptr
        lda     $84F7,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)
        lda     #$00
        sta     $40
        sta     $4F
        sta     $50
        lda     $B2
        cmp     #$03
        bne     *+30
        lda     #$00
        sta     $B2
        lda     #$68
        jsr     play_sound_and_reset_anim
        lda     $0421
        ora     #$04
        sta     $0421
        lda     #$04
        sta     $B1
        lda     #$FF
        sta     $0641
        bne     *+97
        lda     rng_seed
        sta     temp_01
        lda     #$05
        sta     temp_02
        jsr     divide_8bit
        ldx     temp_04
        lda     airman_leaf_count_table,x
        sta     $04E1
        lda     temp_04
        asl     a
        sta     temp_01
        asl     a
        adc     temp_01
        sta     temp_01
        lda     #$06
        sta     temp_02


; =============================================================================
; Boss AI: Air Man — Leaf Shield creation and leaf projectile spawning ($833C)
; =============================================================================
airman_spawn_leaf_loop:  lda     #$5D
        ldx     #$01
        jsr     spawn_entity_from_boss
        ldx     temp_01
        lda     enemy_sprite_ids,x
        sta     $0670,y
        lda     enemy_palette_data,x
        sta     $0650,y
        lda     enemy_x_offsets,x
        sta     $0630,y
        lda     enemy_collision_data,x
        sta     $0610,y
        lda     enemy_damage_values,x
        sta     $04F0,y
        inc     temp_01
        dec     temp_02
        bne     airman_spawn_leaf_loop
        lda     #$3F
        jsr     bank_switch_enqueue
        inc     $B2
        inc     $B1
        lda     #$00
        sta     $06A1
        sta     $0681
        jsr     boss_update_with_sound
        rts

airman_leaf_count_table:  .byte   $44,$4A,$42,$43,$43
enemy_sprite_ids:  .byte   $00,$F0,$50,$3C,$00,$00,$D3,$CD
        .byte   $68,$0F,$1A,$00,$A7,$68,$00,$7F
        .byte   $B1,$A7,$88,$50,$D4,$D0,$D0,$B9
        .byte   $98,$50,$3C,$1A,$7C,$35
enemy_palette_data:  .byte   $04,$03,$03,$02,$02,$00,$03,$03
        .byte   $02,$02,$01,$00,$03,$02,$02,$01
        .byte   $00,$FF,$03,$03,$02
airman_leaf_data_overflow:  .byte   $01,$01
        .byte   $FF,$03,$03,$02,$01,$00,$00
enemy_x_offsets:  .byte   $00,$B1,$3C,$50,$76,$00,$2B,$3C
        .byte   $31,$6B,$DB,$00,$A0,$31
airman_leaf_data_mid:  .byte   $76,$B5
        .byte   $F0,$FC
        .byte   $E0,$3C
        .byte   $D4,$90,$90
        .byte   $FD,$C0,$3C
        .byte   $50,$DB
        .byte   $F8
        .byte   $FE
enemy_collision_data:  .byte   $00
        .byte   $00
        .byte   $02,$03,$03,$04,$01,$01,$03,$03
        .byte   $03,$04,$01,$03,$03,$03,$03,$03
        .byte   $01,$02,$02,$03,$03,$03,$01,$02
        .byte   $03,$03,$03,$03
enemy_damage_values:  .byte   $0C,$16,$24,$0E,$24,$18,$1B,$0E
        .byte   $1E,$2A,$1D,$0C,$0D,$0A,$20,$15
        .byte   $22,$18,$21,$15,$05,$0D,$23,$1C
        .byte   $1A,$0E,$1C,$1D,$10,$24,$AD,$E1
        .byte   $04,$F0,$0C
airman_dec_leaf_count:  lda     #$00
        sta     $0681
        dec     $04E1
        jsr     boss_update_with_sound
        rts

        lda     #$5D
        jsr     find_entity_by_type
        bcc     airman_shield_active
        dec     $B1
        jmp     airman_dec_leaf_count

airman_shield_active:  lda     #$01
        sta     $40
        lda     $0421
        and     #$40
        sta     $AF
        clc
        lda     $4F
        adc     #$10
        sta     $4F
        lda     $50
        adc     #$00
        sta     $50
        cmp     #$04
        bne     airman_update_scroll_lock
        lda     #$00
        sta     $4F
airman_update_scroll_lock:  ldy     #$0F
        lda     #$5D
        sta     temp_00
airman_sprite_scan_loop:  jsr     collision_check_sprite
        bcs     airman_check_anim_state
        lda     $4F
        sta     $0630,y
        lda     $50
        sta     $0610,y
        dey
        bpl     airman_sprite_scan_loop
airman_check_anim_state:  lda     $06A1
        cmp     #$03
        bne     airman_frame_update
        lda     #$01
        sta     $06A1
airman_frame_update:  ldx     #$01
        jsr     boss_update_with_sound
        rts

        .byte   $20,$D9
        sty     current_weapon
        .byte   $0B,$85,$01,$A9,$10,$85,$02,$20
        .byte   $D4,$A2,$A5,$00,$F0,$3A,$A6,$B2
        .byte   $BD,$CD,$84,$8D,$61,$06,$BD,$D0
        .byte   $84,$8D,$41,$06,$BD,$D3,$84,$8D
        .byte   $21,$06,$BD,$D6,$84,$8D,$01,$06
        .byte   $E6,$B2,$A5,$B2,$C9,$03,$D0,$18
        .byte   $A9,$02,$85,$B1,$AD,$21,$04,$29
        .byte   $FB,$49,$40,$8D,$21,$04,$A9,$00
        .byte   $85,$B2,$A9,$67,$20,$0C,$A1,$60
        .byte   $60,$E6,$76,$00,$04,$07,$00,$39
        .byte   $9A,$00,$01,$01,$00
boss_update_with_sound:  lda     $05A8
        beq     boss_update_collision_check
        jsr     boss_apply_movement_physics
        jmp     boss_update_rts

boss_update_collision_check:  jsr     boss_check_weapon_hit
        lda     temp_02
        cmp     #$01
        bne     boss_update_rts
        lda     #$12
        sta     $05A8
boss_update_rts:  rts

        .byte   $D3,$F1,$19,$80,$80,$82,$84,$84
        dex
        lda     $864E,x
        .byte   $85
        php
        lda     bubbleman_ai_table_hi,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)

        jsr     calc_player_boss_distance
        lda     $04E1
        bne     woodman_check_phase
        lda     #$61
        ldx     #$01
        jsr     spawn_entity_from_boss
        inc     $04E1
        jmp     woodman_frame_update


; =============================================================================
; Boss AI: Wood Man — tornado spawning and wind patterns ($851E)
; =============================================================================
woodman_check_phase:  cmp     #$04
        bcs     woodman_spawn_multi_tornado
woodman_inc_timer:  inc     $B2
        lda     $B2
        cmp     #$12
        bne     woodman_jmp_frame_update
        lda     #$00
        sta     $B2
        inc     $04E1
woodman_spawn_tornado:  lda     #$62
        ldx     #$01
        jsr     spawn_entity_from_boss
woodman_jmp_frame_update:  jmp     woodman_frame_update

woodman_spawn_multi_tornado:  lda     #$62
        jsr     find_entity_by_type
        bcc     woodman_frame_update
        lda     #$03
        sta     temp_02
woodman_tornado_loop:  lda     #$62
        ldx     #$01
        jsr     spawn_entity_from_boss
        bcs     woodman_advance_phase
        ldx     temp_02
        lda     #$C1
        sta     ent_spawn_flags,y
        lda     #$20
        sta     ent_y_spawn_px,y
        lda     #$01
        sta     $04F0,y
        lda     #$FE
        sta     $0650,y
        lda     #$02
        sta     $0610,y
        lda     woodman_tornado_x_offset,x
        sta     ent_x_spawn_px,y
        dec     temp_02
        bpl     woodman_tornado_loop
woodman_advance_phase:  inc     $B1
        lda     #$6F
        jsr     play_sound_and_reset_anim
woodman_frame_update:  jsr     woodman_update_with_sound
        rts

woodman_tornado_x_offset:  .byte   $40
        bvs     woodman_inc_timer
        bne     woodman_spawn_tornado
        lda     (temp_06,x)
        cmp     #$02
        bcc     woodman_jmp_frame_update_2
        bne     woodman_phase3_sound
        lda     $0681
        bne     woodman_jmp_frame_update_2
        lda     #$61
        jsr     find_entity_by_type
woodman_bcc_frame_update:  bcs     woodman_jmp_frame_update_2
        lda     #$04
        sta     $0610,y
        .byte   $B9
        .byte   $30
woodman_data_byte:  .byte   $04
        and     #$BF
        sta     temp_00
        lda     $0421
        and     #$40
        ora     temp_00
        sta     ent_spawn_flags,y
        bne     woodman_jmp_frame_update_2
woodman_phase3_sound:  lda     #$6E
        jsr     play_sound_and_reset_anim
        inc     $B1
woodman_jmp_frame_update_2:  jsr     woodman_update_with_sound
        rts

        jsr     woodman_update_with_sound
        lda     $06A1
        cmp     #$02
        .byte   $90
        bvs     woodman_bcc_frame_update
        .byte   $52
        lda     $0681
        bne     *+20
        lda     #$04
        sta     $0641
        lda     #$01
        sta     $0601
        lda     $0421
        ora     #$04
        sta     $0421
        lda     #$01
        sta     $0681
        lda     $0641
        php
        lda     #$0F
        sta     temp_01
        lda     #$10
        sta     temp_02
        jsr     boss_wall_collision_check
        plp
        bpl     woodman_collision_rts
        lda     temp_00
        beq     woodman_collision_rts
        lda     #$03
        sta     $06A1
        lda     #$00
        sta     $0641
        sta     $0661
        sta     $0601
        sta     $0681
        sta     $04E1
        sta     $B2
        lda     $0421
        and     #$FB
        sta     $0421
        lda     $06A1
        cmp     #$04
        bne     woodman_collision_rts
        lda     #$00
        sta     $0681
        lda     #$62
        jsr     find_entity_by_type
        bcc     woodman_collision_rts
        lda     #$02
        sta     $B1
        lda     #$6D
        jsr     play_sound_and_reset_anim
woodman_collision_rts:  rts

woodman_update_with_sound:  lda     $05A8
        beq     woodman_collision_check
        jsr     boss_apply_movement_physics
        rts

woodman_collision_check:  jsr     boss_check_weapon_hit
        lda     temp_02
        cmp     #$01
        bne     woodman_update_rts
        lda     #$12
        sta     $05A8
woodman_update_rts:  rts

        .byte   $D3,$09,$83,$BB
bubbleman_ai_table_hi:  .byte   $80,$85,$85,$85
        dex
        lda     $8796,x
        sta     jump_ptr
        lda     $879A,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)
        lda     #$83
        sta     $0421
        jsr     calc_player_boss_distance
        lda     ent_anim_id,x
        bne     *+5
        sta     $0681
        lda     $04E1
        bne     bubbleman_dec_aim_timer
        sec
        lda     $04A1
        sbc     ent_y_px
        bcs     bubbleman_aim_check_dist
        eor     #$FF
        adc     #$01


; =============================================================================
; Boss AI: Bubble Man — Crash Bomber aiming and movement ($8686)
; =============================================================================
bubbleman_aim_check_dist:  cmp     #$03
        bcs     bubbleman_frame_update
        lda     rng_seed
        sta     temp_01
        lda     #$03
        sta     temp_02
        jsr     divide_8bit
        inc     temp_04
        lda     temp_04
        sta     $04E1
        lda     #$01
        sta     $B2
bubbleman_dec_aim_timer:  dec     $B2
        bne     bubbleman_frame_update
        lda     #$1F
        sta     $B2
        lda     #$5B
        ldx     #$01
        jsr     spawn_entity_from_boss
        lda     #$01
        sta     $06A1
        dec     $04E1
        bne     bubbleman_frame_update
        lda     ent_y_px
        pha
        lda     #$50
        sta     ent_y_px
        lda     #$01
        sta     jump_ptr_hi
        lda     #$60
        sta     jump_ptr
        ldx     #$01
        stx     current_entity_slot
        jsr     calc_velocity_toward_player
        pla
        sta     ent_y_px
        lda     #$00
        sta     $B2
        lda     $0421
        sta     $04E1
        inc     $B1
        lda     #$62
        jsr     play_sound_and_reset_anim
bubbleman_frame_update:  jsr     bubbleman_update_with_sound
        rts

        lda     $04E1
        sta     $0421
        jsr     bubbleman_update_with_sound
        lda     $04A1
        cmp     #$50
        bcs     *+22
        lda     #$FF
        sta     $0641
        lda     #$00
        sta     $0661
        sta     $0601
        sta     $0621
        lda     #$04
        sta     $B1
        jsr     calc_player_boss_distance
        lda     $B2
        bne     bubbleman_dec_shot_timer
        sec
        lda     $04A1
        sbc     ent_y_px
        bcs     bubbleman_check_dist_2
        eor     #$FF
        adc     #$01
bubbleman_check_dist_2:  cmp     #$03
        bcs     bubbleman_check_anim_reset
        lda     #$01
        sta     $05A7
        lda     #$04
        sta     $B2
bubbleman_dec_shot_timer:  dec     $05A7
        bne     bubbleman_check_anim_reset
        lda     #$12
        sta     $05A7
        lda     #$03
        sta     $06A1
        lda     #$5A
        ldx     #$01
        jsr     spawn_entity_from_boss
        dec     $B2
bubbleman_check_anim_reset:  lda     $06A1
        cmp     #$02
        bne     bubbleman_anim_rts
        lda     #$00
        sta     $06A1
bubbleman_anim_rts:  rts

        jsr     bubbleman_update_with_sound
        lda     temp_00
        beq     *-75
        lda     #$02
        sta     $B1
        lda     #$00
        sta     $0641
        sta     $04E1
        sta     $B2
        lda     #$61
        jsr     play_sound_and_reset_anim
        jmp     bubbleman_check_anim_reset
bubbleman_update_with_sound:  lda     $05A8
        beq     bubbleman_collision_check
        jsr     boss_apply_movement_physics
        jmp     bubbleman_collision_params

bubbleman_collision_check:  jsr     boss_check_weapon_hit
        lda     temp_02
        cmp     #$01
        bne     bubbleman_collision_params
        lda     #$12
        sta     $05A8
bubbleman_collision_params:  lda     #$09
        sta     temp_01
        lda     #$0C
        sta     temp_02
        jsr     boss_wall_collision_check
        rts

        .byte   $D3,$64,$EA,$54,$80,$86,$86,$87
        dex
        lda     $894C,x
        sta     jump_ptr
        lda     $8951,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)

        lda     $04E1
        bne     *+83
        lda     #$87
        sta     $0421
        jsr     calc_player_boss_distance
        lda     rng_seed
        sta     temp_01
        lda     #$03
        sta     temp_02
        jsr     $C84E
        ldx     temp_04
        lda     temp_00
        clc
        adc     #$20
        sta     temp_01
        sec
        sbc     #$40
        bcs     *+4
        lda     #$00
        sta     temp_02
        lda     #$00
        sta     $0661
        lda     quickman_y_vel_table,x
        sta     $0641
        lda     temp_00,x
        sta     $0B
        lda     quickman_sec_flag,x
        sta     $0D
        lda     #$00
        sta     $0A
        sta     $0C
        jsr     divide_16bit            ; divide for velocity ratio
        lda     $0F
        sta     $0601
        lda     $0E
        sta     $0621
        inc     $04E1
        inc     $B2
        lda     #$08
        sta     temp_01
        lda     #$0C
        sta     temp_02
        lda     $0641
        php
        jsr     boss_wall_collision_check
        plp
        bpl     quickman_check_anim
        lda     temp_00
        beq     quickman_check_anim
        dec     $04E1
        lda     $B2
        cmp     #$03
        bne     quickman_check_anim
        ldx     #$01
        jmp     quickman_phase_transition


; =============================================================================
; Boss AI: Quickman — fast movement and boomerang attacks ($8826)
; =============================================================================
quickman_check_anim:  lda     $06A1
        bne     quickman_check_y_vel
        sta     $0681
quickman_check_y_vel:  lda     $0641
        php
        jsr     quickman_update_with_sound
        plp
        bmi     quickman_frame_rts
        lda     $0641
        bpl     quickman_frame_rts
        lda     $B2
        cmp     #$02
        bne     quickman_frame_rts
        lda     $B1
        cmp     #$02
        bne     quickman_frame_rts
        lda     #$00
        sta     $0681
        lda     #$01
        sta     $06A1
        lda     ent_y_px
        pha
        sec
        sbc     #$18
        sta     ent_y_px
        lda     #$03
        sta     temp_02
quickman_spawn_boomerang_loop:  lda     #$59
        ldx     #$01
        jsr     spawn_entity_from_boss
        bcs     quickman_restore_y
        tya
        clc
        adc     #$10
        tax
        sta     current_entity_slot
        lda     #$25
        sta     ent_state,x
        lda     #$04
        sta     jump_ptr_hi
        lda     #$00
        sta     jump_ptr
        jsr     calc_velocity_toward_player
        clc
        lda     ent_y_px
        adc     #$18
        sta     ent_y_px
        dec     temp_02
        bne     quickman_spawn_boomerang_loop
quickman_restore_y:  pla
        sta     ent_y_px
quickman_frame_rts:  rts

quickman_y_vel_table:  .byte   $07,$08,$04
quickman_sec_flag:  .byte   $38,$40
        .byte   $20,$20,$09,$A2,$A2,$00
quickman_phase_transition:  lda     #$00
        sta     $04E1
        sta     $B2
        lda     quickman_phase_id_table,x
        sta     $B1
        lda     quickman_sound_table,x
        jsr     play_sound_and_reset_anim
        jsr     quickman_hitbox_params
        rts

quickman_phase_id_table:  .byte   $02,$05
quickman_sound_table:  .byte   $55,$58
        dec     $04E1
        beq     *+44
        jsr     quickman_hitbox_params
        rts
        lda     $04E1
        bne     *+22
        lda     #$87
        sta     $0421
        jsr     calc_player_boss_distance
        lda     #$02
        sta     $0601
        lda     #$3E
        sta     $B2
        inc     $04E1
        dec     $B2
        bne     quickman_state2_frame_update
        ldx     #$00
        jsr     quickman_phase_transition
quickman_state2_frame_update:  jsr     quickman_hitbox_params
        rts

        lda     #$00
        sta     $04E1
        sta     $B2
        lda     #$03
        sta     $B1
        lda     #$56
        jsr     play_sound_and_reset_anim
        lda     #$0B
        sta     temp_01
        lda     #$0C
        sta     temp_02
        jsr     boss_flip_and_check_wall
        rts

quickman_hitbox_params:  lda     #$08
        sta     temp_01
        lda     #$0C
        sta     temp_02
        jsr     boss_wall_collision_check
quickman_update_with_sound:  lda     $05A8
        beq     quickman_collision_check
        jsr     boss_apply_movement_physics
        jmp     quickman_update_rts

quickman_collision_check:  jsr     boss_check_weapon_hit
        lda     temp_02
        beq     quickman_update_rts
        cmp     #$01
        bne     quickman_hit_response
        lda     #$12
        sta     $05A8
        bne     quickman_update_rts
quickman_hit_response:  lda     #$00
        sta     $0601
        sta     $0621
        lda     #$FF
        sta     $0641
        lda     #$C0
        sta     $0661
        lda     #$57
        jsr     play_sound_and_reset_anim
        lda     #$04
        sta     $B1
        lda     #$3E
        sta     $04E1
quickman_update_rts:  rts

        .byte   $D3,$AC,$99,$B8,$C1,$80,$87,$88
        .byte   $88,$88
        dex
        lda     $8B16,x
        sta     jump_ptr
        lda     $8B1B,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)
        lda     $0421
        ora     #$04
        sta     $0421
        lda     #$06
        sta     $0621
        lda     #$01
        sta     $0601
        inc     $B2
        lda     $B2
        cmp     #$BB
        bcc     *+30
        lda     #$00
        sta     $04E1
        lda     #$03
        sta     $B1
        lda     #$5A
        jsr     play_sound_and_reset_anim
        lda     #$03
        sta     $06A1
        jsr     flashman_update_with_sound
        lda     #$21
        jsr     bank_switch_enqueue
        rts

        jsr     flashman_update_with_sound
        lda     temp_03
        beq     flashman_rts
        lda     $B1
        cmp     #$06
        beq     flashman_rts
        lda     #$00
        sta     $04E1
        lda     #$05
        sta     $B1
        lda     #$5D
        jsr     play_sound_and_reset_anim
flashman_rts:  rts

        lda     #$00
        sta     $0621
        sta     $0601
        lda     $06A1
        cmp     #$07
        bne     flashman_frame_update
        lda     #$5F
        sta     $040F
        lda     #$80
        sta     $042F
        sta     $046F
        sta     $04AF
        lda     $0441
        sta     $044F
        lda     #$00
        sta     $066F
        sta     $064F
        sta     $060F
        sta     $062F
        sta     $068F
        sta     $06AF
        lda     #$04
        sta     $AA
        lda     #$20
        sta     $0366
        lda     #$06
        sta     $04E1
        lda     #$1F
        sta     $B2
        inc     $B1
        lda     #$5B
        jsr     play_sound_and_reset_anim


; =============================================================================
; Boss AI: Flash Man — flame charge and projectile patterns ($8A08)
; =============================================================================
flashman_frame_update:  jsr     flashman_update_with_sound
        rts

        lda     #$0F
        sta     $0366
        lda     $06A1
        beq     flashman_frame_update
flashman_data_overlap:cmp     #$02
        bne     *+29
        lda     #$02
        sta     $B1
        lda     #$00
        sta     $AA
        sta     $B2
        sta     $04E1
        lsr     $042F
        lda     #$5C
        jsr     play_sound_and_reset_anim
        jsr     calc_player_boss_distance
        jmp     flashman_frame_update
        jsr     calc_player_boss_distance
        lda     #$00
        sta     $0681
        dec     $B2
        bne     flashman_frame_update
        lda     #$06
        sta     $B2
        lda     ent_y_px
        pha
        lda     rng_seed
        sta     temp_01
        lda     #$50
        sta     temp_02
        jsr     divide_8bit
        sec
        lda     $04A1
        sbc     #$28
        clc
        adc     temp_04
        sta     ent_y_px
        lda     #$35
        ldx     #$01
        jsr     spawn_entity_from_boss
        bcs     flashman_restore_y_pos
        clc
        tya
        adc     #$10
        tax
        stx     current_entity_slot
        lda     #$08
        sta     jump_ptr_hi
        lda     #$00
        sta     jump_ptr
        ldy     #$00
        lda     $0421
        and     #$40
        pha
        bne     flashman_aim_adjust_x
        iny
flashman_aim_adjust_x:  clc
        lda     ent_x_px,x
        adc     flashman_aim_offset_table,y
        sta     ent_x_px,x
        pla
        tay
        lda     #$60
        sta     temp_00
        jsr     calc_velocity_set_facing
        lda     #$01
        sta     current_entity_slot
flashman_restore_y_pos:  pla
        sta     ent_y_px
        ldx     #$01
        dec     $04E1
        bne     flashman_jmp_frame_update
        inc     $06A1
flashman_jmp_frame_update:  jmp     flashman_frame_update

flashman_aim_offset_table:  .byte   $08,$F8
        lda     $04E1
        bne     *+26
        jsr     calc_player_boss_distance
        lda     #$00
        sta     $0661
        sta     $0601
        lda     #$04
        sta     $0641
        lda     #$80
        sta     $0621
        inc     $04E1
        jsr     flashman_update_with_sound
        bne     flashman_hit_response
flashman_collision_rts:  rts

flashman_hit_response:  lda     $B1
        cmp     #$06
        beq     flashman_collision_rts
        lda     #$00
        sta     $04E1
        lda     #$02
        sta     $B1
        lda     #$5C
        jsr     play_sound_and_reset_anim
flashman_update_with_sound:  lda     $05A8
        beq     flashman_collision_check
        jsr     boss_apply_movement_physics
        jmp     flashman_hitbox_params

flashman_collision_check:  jsr     boss_check_weapon_hit
        lda     temp_02
        cmp     #$01
        bne     flashman_hitbox_params
        lda     #$12
        sta     $05A8
        rts

flashman_hitbox_params:  lda     #$08
        sta     temp_01
        lda     #$0C
        sta     temp_02
        lda     $0641
        php
        jsr     boss_wall_collision_check
        plp
        bpl     flashman_no_hit
        lda     temp_00
        rts

flashman_no_hit:  lda     #$00
        rts

        .byte   $D3,$64,$B6,$0C,$AD,$80,$89,$89
        .byte   $8A,$8A
        dex
        lda     $8CBB,x
        sta     jump_ptr
        lda     $8CBF,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)
        lda     #$87
        sta     $0421
        jsr     calc_player_boss_distance
        lda     p1_new_presses
        and     #$02
        bne     *+8
        lda     $B2
        cmp     #$BB
        bne     *+21
        lda     rng_seed
        sta     temp_01
        lda     #$03
        sta     temp_02
        jsr     divide_8bit
        ldx     temp_04
        jsr     metalman_fire_blade
        jmp     metalman_inc_timer

        lda     temp_00
        cmp     #$48
        bcs     metalman_inc_timer
        lda     #$87
        ldy     $0461
        cpy     #$80
        bcs     metalman_aim_at_player
        ora     #$40
metalman_aim_at_player:  sta     $0421
        ldx     #$03
        jsr     metalman_fire_blade
metalman_inc_timer:  inc     $B2
        jsr     metalman_palette_flash
        rts


; =============================================================================
; Boss AI: Metalman — Metal Blade throws and jump patterns ($8B74)
; =============================================================================
metalman_fire_blade:  lda     #$65
        jsr     play_sound_and_reset_anim
        lda     #$01
        sta     $B2
        lda     metalman_vel_y_sub_table,x
        sta     $0661
        lda     metalman_vel_y_hi_table,x
        sta     $0641
        lda     metalman_vel_x_sub_table,x
        sta     $0621
        lda     metalman_vel_x_hi_table,x
        sta     $0601
        lda     metalman_phase_table,x
        sta     $B1
        lda     $0421
        sta     $04E1
        rts

metalman_vel_y_sub_table:  .byte   $ED,$A8,$00
        .byte   $00
metalman_vel_y_hi_table:  .byte   $06,$05,$04,$08
metalman_vel_x_sub_table:  .byte   $00,$00,$00,$20
metalman_vel_x_hi_table:  .byte   $00,$00,$00,$02
metalman_phase_table:  .byte   $03,$03,$03,$04,$AD,$E1,$04,$8D
        .byte   $21,$04,$20,$3E,$8C,$A5,$00,$48
        .byte   $20,$09,$A2,$68,$85,$00,$AD,$41
        .byte   $06,$10,$3A,$C6,$B2,$D0,$21,$A0
        .byte   $12,$A5,$B1,$C9,$04,$D0,$02,$A0
        .byte   $40
        sty     $B2
        lda     #$00
        sta     $0641
        sta     $0661
        lda     $0421
        and     #$FB
        sta     $0421
        lda     #$01
        sta     $06A1
        lda     temp_00
        beq     metalman_check_anim
        lda     #$00
        sta     $B2
        dec     $B1
        sta     $0601
        sta     $0621
        lda     #$64
        jsr     play_sound_and_reset_anim
metalman_check_anim:  lda     $06A1
        bne     metalman_check_anim_2
        sta     $0681
metalman_check_anim_2:  cmp     #$02
        bne     metalman_frame_rts
        lda     $0681
        bne     metalman_frame_rts
        lda     #$23
        jsr     bank_switch_enqueue
        lda     #$5C
        ldx     #$01
        jsr     spawn_entity_from_boss
        clc
        tya
        adc     #$10
        tax
        stx     current_entity_slot
        lda     #$00
        sta     jump_ptr
        lda     #$04
        sta     jump_ptr_hi
        jsr     calc_velocity_toward_player
        lda     $0421
        ora     #$04
        sta     $0421
metalman_frame_rts:  rts


; =============================================================================
; Metalman Palette Flash — stage lightning effect timer ($8C3E)
; =============================================================================
metalman_palette_flash:  lda     #$0F
        sta     $0366
        clc
        lda     $05A7
        adc     #$01
        sta     $05A7
        lda     $05A9
        adc     #$00
        sta     $05A9
        beq     metalman_update_with_sound
        lda     $05A7
        cmp     #$77
        bne     metalman_update_with_sound
        lda     #$00
        sta     $05A7
        sta     $05A9
        lda     current_stage
        cmp     #$0C
        beq     metalman_update_with_sound
        lda     #$30
        sta     $0366
        ldx     #$00
        ldy     #$00
        lda     $45
        eor     #$40
        sta     $45
        lda     $46
        eor     #$40
        sta     $46
        beq     metalman_palette_copy_loop
        inx
metalman_palette_copy_loop:  lda     metalman_palette_data,x
        sta     $037B,y
        inx
        inx
        iny
        cpy     #$03
        bne     metalman_palette_copy_loop
metalman_update_with_sound:  lda     $05A8
        beq     metalman_collision_check
        jsr     boss_apply_movement_physics
        jmp     metalman_hitbox_params

metalman_collision_check:  jsr     boss_check_weapon_hit
        lda     temp_02
        cmp     #$01
        bne     metalman_hitbox_params
        lda     #$12
        sta     $05A8
metalman_hitbox_params:  lda     #$07
        sta     temp_01
        lda     #$0C
        sta     temp_02
        jsr     boss_wall_collision_check
        rts

metalman_palette_data:  .byte   $10,$10,$10,$15,$15,$10,$D3,$2E
        .byte   $B5,$B5,$80,$8B,$8B,$8B,$CA,$BD
        .byte   $08,$8E
        sta     jump_ptr
        lda     crashman_ai_table_hi,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)

        lda     $04E1
        ora     #$83
        sta     $0421
        lda     #$00
        sta     $0661
        sta     $0641
        lda     #$47
        sta     $0621
        lda     #$01
        sta     $0601
        lda     #$6A
        jsr     play_sound_and_reset_anim
        inc     $B1
        jsr     crashman_update_with_sound
        rts
        lda     p1_new_presses
        and     #$02
        bne     *+12
        lda     $05A7
        beq     *+89
        .byte   $CE,$A7
        ora     $D0
        .byte   $52
        lda     #$87
        sta     $0421
        jsr     calc_player_boss_distance
        lda     $0421
        sta     $05A9
        lda     #$ED
        sta     $0661
        lda     #$06
        sta     $0641
        clc
        lda     temp_00
        adc     #$20
        sta     $0B
        lda     rng_seed
        and     #$01
        beq     crashman_setup_velocity
        sec
        lda     $0B
        sbc     #$40
        bcs     crashman_aim_y_offset
        lda     #$00
crashman_aim_y_offset:  sta     $0B


; =============================================================================
; Boss AI: Crash Man — Time Stopper freeze and movement ($8D36)
; =============================================================================
crashman_setup_velocity:  lda     #$37
        sta     $0D
        lda     #$00
        sta     $0A
        sta     $0C
        jsr     divide_16bit            ; divide for velocity ratio
        lda     $0F
        sta     $0601
        lda     $0E
        sta     $0621
        lda     #$6B
        jsr     play_sound_and_reset_anim
        lda     #$04
        sta     $B1
        bne     crashman_frame_update
        ldx     $0461
        lda     $0421
        and     #$40
        bne     crashman_check_x_right
        cpx     #$38
        bcs     crashman_frame_update
        bcc     crashman_check_facing_flip
crashman_check_x_right:  cpx     #$C8
        bcc     crashman_frame_update
crashman_check_facing_flip:  lda     $04E1
        eor     #$40
        sta     $04E1
        lda     $0421
        eor     #$40
        sta     $0421
crashman_frame_update:  jsr     crashman_update_with_sound
        rts

        lda     $05A9
        sta     $0421
        lda     $0641
        php
        jsr     crashman_update_with_sound
        lda     #$0B
        sta     temp_01
        lda     #$0C
        sta     temp_02
        jsr     boss_wall_collision_check
        plp
        bmi     crashman_hit_response
        lda     $0641
        bpl     crashman_check_anim_state
        lda     #$01
        sta     $06A1
        bne     crashman_check_anim_state
crashman_hit_response:  lda     temp_00
        beq     crashman_check_anim_fire
        lda     #$02
        sta     $B1
        lda     #$9C
        sta     $05A7
        bne     crashman_check_anim_state
crashman_check_anim_fire:  lda     $06A1
        cmp     #$02
        bne     crashman_check_anim_state
        lda     $0681
        bne     crashman_check_anim_state
        lda     #$5E
        jsr     find_entity_by_type
        bcc     crashman_check_anim_state
        lda     #$5E
        ldx     #$01
        jsr     spawn_entity_from_boss
        bcs     crashman_check_anim_state
        clc
        tya
        adc     #$10
        tax
        stx     current_entity_slot
        lda     #$24
        sta     jump_ptr
        lda     #$06
        sta     jump_ptr_hi
        jsr     calc_velocity_toward_player
crashman_check_anim_state:  lda     $06A1
        bne     crashman_jmp_aim
        sta     $0681
crashman_jmp_aim:  jsr     calc_player_boss_distance
        rts

crashman_update_with_sound:  lda     $05A8
        beq     crashman_collision_check
        jsr     boss_apply_movement_physics
        rts

crashman_collision_check:  jsr     boss_check_weapon_hit
        lda     temp_02
        cmp     #$01
        bne     crashman_update_rts
        lda     #$12
        sta     $05A8
crashman_update_rts:  rts

        .byte   $D3,$D1,$F6,$80
crashman_ai_table_hi:  .byte   $80,$8C,$8C,$8D
        dex
        lda     $9205,x
        sta     jump_ptr
        lda     $920C,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)
        lda     $04E1
        bne     *+29
        lda     #$09
        jsr     $C5F1
        inc     $B2
        lda     $B2
        cmp     #$40
        beq     *+3
        rts
        inc     $04E1
        lda     #$00
        sta     $B2
        lda     #$80
        sta     $05A7
        rts

        cmp     #$01
        bne     dragon_phase2_check
        ldx     $B2
        lda     dragon_column_addr_hi_table,x
        sta     col_update_addr_hi
        lda     dragon_column_addr_lo_table,x
        sta     col_update_addr_lo
        lda     dragon_column_length_table,x
        sta     col_update_count
        sta     temp_00
        ldy     #$00


; =============================================================================
; Boss AI: Wily 1 — Mecha Dragon nametable setup and column fill ($8E59)
; =============================================================================
dragon_fill_column_loop:  lda     $05A7
        sta     col_update_tiles,y
        iny
        inc     $05A7
        dec     temp_00
        bne     dragon_fill_column_loop
        inx
        stx     $B2
        cpx     #$0F
        bne     dragon_phase_rts
        inc     $04E1
        lda     #$00
        sta     $B2
        rts

dragon_phase2_check:  cmp     #$02
        bne     dragon_clear_attr_loop_outer
        ldx     $B2
        cpx     #$10
        beq     dragon_phase3_setup
        lda     #$23
        sta     col_update_addr_hi
        txa
        asl     a
        adc     #$D0
        sta     col_update_addr_lo
        ldy     #$00
dragon_attr_copy_loop:  lda     dragon_attr_data,x
        sta     col_update_tiles,y
        inx
        iny
        cpy     #$04
        bne     dragon_attr_copy_loop
        sty     col_update_count
        stx     $B2
        rts

dragon_phase3_setup:  inc     $04E1
        lda     #$23
        sta     col_update_addr_hi
        lda     #$E0
        sta     col_update_addr_lo
        lda     #$1E
        sta     $B2
dragon_clear_attr_loop_outer:  lda     #$00
        ldx     #$1F
dragon_clear_attr_loop_inner:  sta     col_update_tiles,x
        dex
        bpl     dragon_clear_attr_loop_inner
        clc
        lda     #$20
        sta     col_update_count
        adc     col_update_addr_lo
        sta     col_update_addr_lo
        lda     col_update_addr_hi
        adc     #$00
        sta     col_update_addr_hi
        dec     $B2
        bne     dragon_phase_rts
        inc     $B1
        lda     #$00
        sta     $04E1
dragon_phase_rts:  rts

dragon_column_addr_hi_table:  .byte   $21,$21,$21,$21,$21,$21,$21,$22
        .byte   $22,$22,$22,$22,$22,$22,$22
dragon_column_addr_lo_table:  .byte   $4B,$69,$87,$A6,$C5,$E5,$EE,$04
        .byte   $24,$44,$64,$84,$A4,$C5,$E6
dragon_column_length_table:  .byte   $03,$06,$08,$0A,$0B,$05,$02,$07
        .byte   $07
        php
        php
        php
        php
        .byte   $07,$03
dragon_attr_data:  .byte   $FF,$FF,$FF,$FF,$FF,$5F,$FF,$F3
        .byte   $FF,$55,$7F,$FF,$FF,$FF,$FF,$FF
        lda     $04E1
        bne     *+28
        lda     #$67
        ldx     #$01
        jsr     spawn_entity_from_boss
        lda     nametable_select
        sta     ent_x_spawn_scr,y
        lda     #$30
        sta     ent_x_spawn_px,y
        lda     #$E0
        sta     ent_y_spawn_px,y
        inc     $04E1
        rts
        cmp     #$02
        bcs     dragon_phase2_entry
        rts

dragon_phase2_entry:  bne     dragon_palette_done
        ldx     #$0F
dragon_load_palette:  lda     dragon_palette_data,x
        sta     palette_ram,x
        dex
        bpl     dragon_load_palette
        jsr     boss_init
        lda     #$03
        sta     $B1
        lda     #$5D
        sta     $B2
        lda     #$65
        ldx     #$01
        jsr     spawn_entity_from_boss
        lda     #$40
        sta     ent_x_spawn_px,y
        lda     #$87
        sta     ent_y_spawn_px,y
        lda     #$66
        ldx     #$01
        jsr     spawn_entity_from_boss
        lda     #$38
        sta     ent_x_spawn_px,y
        lda     #$BF
        sta     ent_y_spawn_px,y
        lda     #$2C
        jsr     bank_switch_enqueue
dragon_palette_done:  rts

dragon_palette_data:  .byte   $0F,$30,$29,$19,$0F,$27,$11,$19
        .byte   $0F,$11,$29,$19,$0F,$27,$29,$19
        lda     #$63
        sta     temp_00
        ldy     #$0F


; =============================================================================
; Boss AI: Wily 1 — Mecha Dragon battle and collision ($8F90)
; =============================================================================
dragon_sprite_collision_loop:  jsr     collision_check_sprite
        bcs     dragon_movement_update
        lda     ent_spawn_flags,y
        and     #$04
        bne     dragon_sprite_next
        lda     ent_x_spawn_px,y
        cmp     #$60
        bcs     dragon_sprite_next
        lda     #$C4
        sta     ent_spawn_flags,y
        lda     rng_seed
        and     #$03
        sta     $0610,y
dragon_sprite_next:  dey
        bpl     dragon_sprite_collision_loop
dragon_movement_update:  jsr     dragon_y_bounds_check
        dec     $B2
        bne     dragon_dec_phase_timer
        lda     #$5D
        sta     $B2
dragon_dec_phase_timer:  jsr     dragon_update_position
        lda     $06A1
        bne     dragon_frame_rts
        sta     $0681
dragon_frame_rts:  rts

dragon_y_bounds_check:  lda     $04E1
        bne     dragon_y_set_rising
        lda     $04A1
        cmp     #$53
        bcc     dragon_y_set_rising
dragon_y_reset_velocity:  lda     #$00
        sta     $04E1
        lda     #$00
        sta     $0641
        lda     #$80
        sta     $0661
        rts

dragon_y_set_rising:  lda     $04A1
        cmp     #$73
        bcs     dragon_y_reset_velocity
        lda     #$01
        sta     $04E1
        lda     #$FF
        sta     $0641
        lda     #$80
        sta     $0661
        rts

        lda     #$63
        sta     temp_00
        ldy     #$0F
dragon_sprite_scan_2:  jsr     collision_check_sprite
        bcs     dragon_movement_update_2
        lda     ent_spawn_flags,y
        and     #$04
        bne     dragon_sprite_next_2
        lda     ent_x_spawn_px,y
        cmp     #$90
        bcs     dragon_sprite_next_2
        lda     #$C4
        sta     ent_spawn_flags,y
dragon_sprite_next_2:  dey
        bpl     dragon_sprite_scan_2
dragon_movement_update_2:  jsr     dragon_y_bounds_check
        jsr     dragon_update_position
        jsr     boss_health_bar_tick
        lda     $06C1
        cmp     #MAX_HP
        bne     dragon_health_check_rts
        lda     #$00
        sta     $04E1
        inc     $B1
dragon_health_check_rts:  rts

dragon_fire_breath:  lda     #$2C
        jsr     bank_switch_enqueue
        lda     #$01
        sta     $06A1
        lda     #$68
        ldx     #$01
        jsr     spawn_entity_from_boss
        bcs     dragon_fire_done
        clc
        lda     ent_y_spawn_px,y
        adc     #$10
        sta     ent_y_spawn_px,y
        lda     #$02
dragon_fire_setup_velocity:  sta     jump_ptr_hi
        lda     #$00
        sta     jump_ptr
        tya
        clc
        adc     #$10
        tax
        stx     current_entity_slot
        jsr     calc_velocity_toward_player
dragon_fire_done:  rts

        lda     $04E1
        bne     *+10
        ldy     #$A0
        jsr     $90C5
        inc     $04E1
        jsr     dragon_check_fire_range
        bcs     dragon_phase3_reset
        lda     $0461
        cmp     #$A0
        bcc     dragon_velocity_check
dragon_phase3_reset:  lda     #$00
        sta     $04E1
        inc     $B1
dragon_velocity_check:  lda     $06A1
        bne     dragon_check_x_velocity
        sta     $0681
dragon_check_x_velocity:  lda     $0641
        bpl     dragon_check_y_lower_bound
        lda     $04A1
        cmp     #$A0
        bcc     dragon_apply_facing
        bcs     dragon_reverse_velocity
dragon_check_y_lower_bound:  lda     $04A1
        cmp     #$20
        bcs     dragon_apply_facing
dragon_reverse_velocity:  clc
        lda     $0661
        eor     #$FF
        adc     #$01
        sta     $0661
        lda     $0641
        eor     #$FF
        adc     #$00
        sta     $0641
dragon_apply_facing:  lda     $05A7
        sta     $0421
        jsr     dragon_update_position
        lda     #$83
        sta     $0421
        rts

        lda     #$00
        sta     jump_ptr_hi
        lda     #$C4
        sta     jump_ptr
        ldx     #$01
        stx     current_entity_slot
        lda     ent_x_px
        pha
        sty     ent_x_px
        jsr     calc_velocity_toward_player
        lda     #$C3
        sta     $05A7
        pla
        sta     ent_x_px
        rts

        lda     $04E1
        bne     *+15
        ldy     #$58
        jsr     $90C5
        lda     #$83
        sta     $05A7
        inc     $04E1
        lda     $0461
        cmp     #$58
        beq     dragon_phase2_reset
        bcs     dragon_jmp_vel_check
dragon_phase2_reset:  lda     #$00
        sta     $04E1
        dec     $B1
dragon_jmp_vel_check:  jmp     dragon_velocity_check

dragon_check_fire_range:  sec
        lda     ent_y_px
        sbc     $04A1
        bcs     dragon_fire_range_check_2
        eor     #$FF
        adc     #$01
dragon_fire_range_check_2:  cmp     #$04
        bcs     dragon_no_fire
        jsr     dragon_fire_breath
        sec
        rts

dragon_no_fire:  clc
        rts

        lda     $B2
        bne     *+10
        lda     #$0F
        sta     $0366
        jmp     fortress_post_defeat
        jsr     picopico_palette_flash
        lda     frame_counter
        and     #$0F
        bne     dragon_fade_rts
        ldx     #$0F
dragon_palette_fade_loop:  sec
        lda     palette_ram,x
        sbc     #$10
        bpl     dragon_palette_store
        lda     #$0F
dragon_palette_store:  sta     palette_ram,x
        dex
        bpl     dragon_palette_fade_loop
        ldx     #$07
dragon_palette_fade_2:  sec
        lda     $036E,x
        sbc     #$10
        bpl     dragon_palette_store_2
        lda     #$0F
dragon_palette_store_2:  sta     $036E,x
        dex
        bpl     dragon_palette_fade_2
        dec     $B2
        bne     dragon_fade_rts
        lda     #$70
        sta     $05A7
dragon_fade_rts:  rts


; =============================================================================
; Mecha Dragon Movement — position update and scroll tracking ($9165)
; =============================================================================
dragon_update_position:  lda     ent_y_px
        cmp     #$B0
        bcc     dragon_update_palette_and_hit
        lda     #$00
        sta     $0661
        sta     $0641
dragon_update_palette_and_hit:  lda     #$0F
        sta     $0366
        jsr     weapon_boss_collision_check
        bcc     dragon_check_hit_flash
        lda     #$0D
        sta     $B2
        lda     #$00
        sta     $0661
        sta     $0641
        sta     $0621
        sta     $0601
        inc     $05AA
        lda     #$07
        sta     $B1
        bne     dragon_apply_movement
dragon_check_hit_flash:  lda     temp_02
        cmp     #$01
        bne     dragon_apply_movement
        lda     #$30
        sta     $0366
dragon_apply_movement:  jsr     boss_apply_movement_physics
        sec
        lda     $B5
        sbc     $0661
        sta     $B5
        lda     camera_y_offset
        sbc     $0641
        sta     camera_y_offset
        beq     dragon_check_facing_dir
        ldy     $0641
        bpl     dragon_clamp_y_upper
        cmp     #$10
        bcs     dragon_check_facing_dir
        clc
        adc     #$10
        sta     camera_y_offset
        jmp     dragon_check_facing_dir

dragon_clamp_y_upper:  cmp     #$11
        bcs     dragon_check_facing_dir
        sec
        sbc     #$10
        sta     camera_y_offset
dragon_check_facing_dir:  lda     $0421
        and     #$40
        beq     dragon_move_facing_left
        clc
        lda     $B7
        adc     $0621
        sta     $B7
        lda     camera_x_offset
        adc     $0601
        sta     camera_x_offset
        lda     camera_x_offset_hi
        adc     #$00
        sta     camera_x_offset_hi
        rts

dragon_move_facing_left:  sec
        lda     $B7
        sbc     $0621
        sta     $B7
        lda     camera_x_offset
        sbc     $0601
        sta     camera_x_offset
        lda     camera_x_offset_hi
        sbc     #$00
        sta     camera_x_offset_hi
        rts

        asl     flashman_data_overlap,x
        .byte   $FC,$64,$E5,$22,$8E,$8F,$8F,$8F
        .byte   $90,$90,$91
        dex
        lda     $9395,x
        sta     jump_ptr
        lda     $9398,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)
        lda     $B2
        bne     *+9
        inc     $B2
        lda     #$0B
        jsr     $C051
        jsr     boss_health_bar_tick
        lda     $06C1
        cmp     #MAX_HP
        bne     picopico_phase_rts
        lda     #$6F
        sta     $04E1
        inc     $B1
        lda     #$00
        sta     $B2
picopico_phase_rts:  rts

        jmp     picopico_rts

        dec     $04E1
        bne     *-6
        lda     #$1F
        sta     $04E1
        lda     #$6A
        jsr     find_entity_by_type
        bcc     *-18
        ldx     $B2
        ldy     $92DD,x
        ldx     #$00


; =============================================================================
; Boss AI: Wily 2 — Picopico-kun entity spawning and setup ($925D)
; =============================================================================
picopico_copy_data_loop:  lda     picopico_spawn_data,y
        sta     jump_ptr,x
        iny
        inx
        cpx     #$08
        bne     picopico_copy_data_loop
        lda     $B2
        asl     a
        sta     temp_01
        ldx     #$00
picopico_spawn_entity_loop:  stx     temp_02
        lda     #$6A
        ldx     #$01
        jsr     spawn_entity_from_boss
        ldx     temp_01
        lda     picopico_y_pos_table,x
        sta     ent_y_spawn_px,y
        lda     picopico_x_pos_table,x
        sta     ent_x_spawn_px,y
        lda     picopico_phase_id_table,x
        sta     $04F0,y
        ldx     temp_02
        lda     jump_ptr,x
        sta     $0650,y
        lda     $0A,x
        sta     $0610,y
        lda     $0C,x
        sta     ent_spawn_flags,y
        lda     $0E,x
        sta     $0120,y
        inc     temp_01
        inx
        cpx     #$02
        bne     picopico_spawn_entity_loop
        lda     $B2
        asl     a
        sta     $0C
picopico_attr_update_loop:  ldx     $0C
        lda     ent_x_screen
        sta     jump_ptr_hi
        lda     picopico_x_pos_table,x
        and     #$F0
        sta     jump_ptr
        lda     picopico_y_pos_table,x
        sta     $0A
        jsr     metatile_render
        lda     attr_update_count
        bne     picopico_advance_phase
        inc     attr_update_count
        inc     $0C
        bne     picopico_attr_update_loop
picopico_advance_phase:  lda     #$82
        sta     attr_update_count
        inc     $B2
        lda     $B2
        cmp     #$0E
        bne     picopico_rts
        inc     $B1
picopico_rts:  rts

        .byte   $00,$00,$00,$08,$10,$00,$00,$10
        .byte   $08,$00,$10,$10,$00,$10
picopico_y_pos_table:  .byte   $57,$57,$87,$87,$B7,$B7,$27,$C7
        .byte   $27,$C7,$77,$77,$37,$37,$27,$C7
        .byte   $27,$C7,$A7,$A7,$27,$C7,$27,$C7
        .byte   $97,$97,$27,$C7
picopico_x_pos_table:  .byte   $28
        .byte   $D8
        .byte   $28
        .byte   $D8
        .byte   $28
        .byte   $D8
        .byte   $58
        .byte   $68
        .byte   $B8
        .byte   $A8
        .byte   $28
        .byte   $D8
        .byte   $28
        .byte   $D8
        .byte   $A8
        .byte   $98
        .byte   $38
        .byte   $48
        .byte   $28
        .byte   $D8
        .byte   $68
        .byte   $58
        .byte   $C8
        .byte   $B8
        .byte   $28
        .byte   $D8
        .byte   $48
        .byte   $38
picopico_phase_id_table:  .byte   $00
        .byte   $00,$00,$00,$00,$00,$00,$00,$01
        .byte   $01,$01,$01,$01,$01,$01,$01,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$03
        .byte   $03,$03,$03
picopico_spawn_data:  .byte   $00,$00,$01,$01,$CB,$8B,$50,$50
        .byte   $FF,$01,$00,$00,$CB,$8B,$50,$50
        .byte   $FF,$01,$00,$00,$8B,$CB,$50,$50
        lda     $06C1
        bne     *+14
        lda     #$BB
        sta     $B2
        inc     $05AA
        lda     #$FF
        jsr     $C051
        rts
        lda     $B2
        beq     *+15
        dec     $B2
        beq     *+6
        jsr     picopico_palette_flash
        rts
        lda     #$80
        sta     $05A7
        lda     #$0F
        sta     $0366
        jmp     fortress_post_defeat


; =============================================================================
; Picopico-kun Palette — flash effect on hit ($9382)
; =============================================================================
picopico_palette_flash:  ldx     #$0F
        lda     frame_counter
        and     #$07
        bne     picopico_palette_store
        lda     #$2B
        jsr     bank_switch_enqueue
        ldx     #$30
picopico_palette_store:  stx     $0366
        rts

        .byte   $21
        eor     $57
        .byte   $92,$92,$93,$CA,$BD,$62,$96
        sta     jump_ptr
        lda     gutsdozer_ai_table_hi,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)

        jsr     boss_health_bar_tick
        lda     $04E1
        bne     *+39
        lda     #$02
        sta     $0354
        lda     #$04
        sta     $0355
        lda     #$B2
        sta     $05A7
        lda     #$00
        sta     $05A9
        lda     #$10
        sta     col_update_addr_hi
        lda     #$E0
        sta     col_update_addr_lo
        lda     #$69
        sta     $B2
        inc     $04E1
        lda     $04E1
        cmp     #$01
        bne     gutsdozer_phase2_check
        lda     #$0B
        jsr     sound_column_copy
        dec     $B2
        beq     gutsdozer_advance_phase
        rts


; =============================================================================
; Boss AI: Wily 3 — Guts-Dozer nametable and column setup ($93E7)
; =============================================================================
gutsdozer_advance_phase:  inc     $04E1
        lda     #$10
        sta     $05A7
        rts

gutsdozer_phase2_check:  cmp     #$02
        bne     gutsdozer_phase3_check
        ldx     $B2
        cpx     #$0B
        beq     gutsdozer_column_done
        lda     gutsdozer_nt_addr_hi_table,x
        sta     col_update_addr_hi
        lda     gutsdozer_nt_addr_lo_table,x
        sta     col_update_addr_lo
        lda     gutsdozer_nt_length_table,x
        sta     col_update_count
        ldy     #$00
gutsdozer_fill_column_loop:  lda     $05A7
        sta     col_update_tiles,y
        inc     $05A7
        iny
        cpy     col_update_count
        bne     gutsdozer_fill_column_loop
        inx
        stx     $B2
        rts

gutsdozer_column_done:  lda     #$21
        sta     col_update_addr_hi
        lda     #$E0
        sta     col_update_addr_lo
        lda     #$00
        sta     $B2
        inc     $04E1
gutsdozer_phase3_check:  lda     $04E1
        cmp     #$03
        bne     gutsdozer_attr_update
        clc
        lda     #$20
        sta     col_update_count
        adc     col_update_addr_lo
        sta     col_update_addr_lo
        lda     col_update_addr_hi
        adc     #$00
        sta     col_update_addr_hi
        ldx     $B2
        cpx     #$B0
        beq     gutsdozer_tile_done
        ldy     #$00
gutsdozer_tile_copy_loop:  lda     gutsdozer_nt_tile_data,x
        sta     col_update_tiles,y
        inx
        iny
        cpy     #$16
        bne     gutsdozer_tile_copy_loop
        stx     $B2
        rts

gutsdozer_tile_done:  lda     #$23
        sta     col_update_addr_hi
        lda     #$C0
        sta     col_update_addr_lo
        lda     #$00
        sta     $B2
        inc     $04E1
gutsdozer_attr_update:  clc
        lda     col_update_addr_lo
        adc     #$08
        sta     col_update_addr_lo
        lda     col_update_addr_hi
        adc     #$00
        sta     col_update_addr_hi
        lda     #$06
        sta     col_update_count
        ldx     $B2
        cpx     #$1E
        beq     gutsdozer_setup_complete
        ldy     #$00
gutsdozer_attr_copy_loop:  lda     gutsdozer_attr_data,x
        sta     col_update_tiles,y
        inx
        iny
        cpy     #$06
        bne     gutsdozer_attr_copy_loop
        stx     $B2
        rts

gutsdozer_setup_complete:  lda     #$00
        sta     col_update_count
        sta     $04E1
        lda     #$8B
        sta     $05A7
        inc     $B1
        rts

        lda     $0421
        bmi     *+7
        lda     #$FF
        sta     $0461
        ldx     $04E1
        lda     camera_x_offset
        cmp     gutsdozer_spawn_screen_table,x
        bne     gutsdozer_jmp_movement
        cpx     #$01
        bne     gutsdozer_spawn_turret
        lda     #$8B
        sta     $0421
        lda     $B7
        sta     $0481
        jmp     gutsdozer_advance_turret


; =============================================================================
; Guts-Dozer Battle — turret spawning and phase management ($94D2)
; =============================================================================
gutsdozer_spawn_turret:  lda     gutsdozer_turret_y_table,x
        sta     temp_01
        lda     gutsdozer_turret_ai_table,x
        sta     temp_02
        lda     gutsdozer_turret_type_table,x
        ldx     #$01
        jsr     spawn_entity_from_boss
        lda     temp_01
        sta     ent_y_spawn_px,y
        lda     #$FF
        sta     ent_x_spawn_px,y
        lda     $B7
        sta     $0490,y
        lda     temp_02
        sta     $06F0,y
gutsdozer_advance_turret:  inc     $04E1
        lda     $04E1
        cmp     #$04
        bne     gutsdozer_jmp_movement
        lda     #$3F
        sta     $04E1
        inc     $B1
gutsdozer_jmp_movement:  jsr     dragon_apply_movement
        rts

gutsdozer_spawn_screen_table:  .byte   $D7,$C7,$A7,$8C
gutsdozer_turret_type_table:  .byte   $69,$00,$63,$67
gutsdozer_turret_y_table:  .byte   $7F,$00,$A8,$68
gutsdozer_turret_ai_table:  ora     #$00
        .byte   $14
        asl     $A5
        clv
        cmp     #$30
        bne     *+8
        lda     #$7D
        sta     $B2
        inc     $B1
        lda     #$8B
gutsdozer_set_facing:  sta     $05A7
        lda     #$60
        sta     $0621
        jsr     gutsdozer_spawn_tick
        rts

        lda     camera_x_offset
        cmp     #$80
        bne     *+8
        lda     #$7D
        sta     $B2
        inc     $B1
        lda     #$CB
        bne     gutsdozer_set_facing
        lda     #$05
        bne     gutsdozer_dec_phase_timer
        lda     #$03
gutsdozer_dec_phase_timer:  sta     temp_00
        dec     $B2
        bne     gutsdozer_clear_velocity
        lda     temp_00
        sta     $B1
gutsdozer_clear_velocity:  lda     #$00
        sta     $0601
        sta     $0621
        jsr     gutsdozer_spawn_tick
        rts


; =============================================================================
; Guts-Dozer Projectile — spawn timing and aim calculation ($9563)
; =============================================================================
gutsdozer_spawn_tick:  dec     $04E1
        beq     gutsdozer_spawn_setup
        jmp     gutsdozer_check_anim_state

gutsdozer_spawn_setup:  lda     #$3F
        sta     $04E1
        jsr     calc_player_boss_distance
        lda     temp_00
        cmp     #$38
        bcc     gutsdozer_calc_aim_angle
        lda     #$69
        jsr     find_entity_by_type
        lda     #$01
        sta     $04F0,y
        lda     #$02
        sta     temp_02
        lda     #$34
        sta     temp_00
        ldy     #$0F
gutsdozer_sprite_scan_loop:  jsr     collision_check_sprite
        bcs     gutsdozer_spawn_shot
        dec     temp_02
        beq     gutsdozer_check_anim_state
        dey
        bpl     gutsdozer_sprite_scan_loop
gutsdozer_spawn_shot:  lda     #$34
        ldx     #$01
        jsr     spawn_entity_from_boss
        bcs     gutsdozer_check_anim_state
        lda     #$87
        sta     ent_spawn_flags,y
        clc
        lda     ent_y_spawn_px,y
        adc     #$30
        sta     ent_y_spawn_px,y
        lda     #$C4
        sta     $0630,y
        lda     #$01
        sta     $0610,y
        lda     #$02
        sta     $0650,y
        lda     #$D4
        sta     $0670,y
        bne     gutsdozer_check_anim_state
gutsdozer_calc_aim_angle:  sec
        lda     temp_00
        sbc     #$10
        bcs     gutsdozer_aim_shift
        lda     #$00
gutsdozer_aim_shift:  sta     jump_ptr
        lda     #$00
        asl     jump_ptr
        rol     a
        asl     jump_ptr
        rol     a
        asl     jump_ptr
        rol     a
        sta     jump_ptr_hi
        lda     #$69
        jsr     find_entity_by_type
        lda     #$00
        sta     $04F0,y
        lda     #$35
        ldx     #$01
        jsr     spawn_entity_from_boss
        bcs     gutsdozer_check_anim_state
        lda     #$85
        sta     ent_spawn_flags,y
        clc
        lda     ent_y_spawn_px,y
        adc     #$10
        sta     ent_y_spawn_px,y
        lda     #$04
        sta     $0650,y
        lda     jump_ptr_hi
        sta     $0610,y
        lda     jump_ptr
        sta     $0630,y
        lda     #$01
        sta     $06A1
gutsdozer_check_anim_state:  lda     $06A1
        bne     gutsdozer_palette_and_hit
        sta     $0681
gutsdozer_palette_and_hit:  lda     #$0F
        sta     $0366
        jsr     weapon_boss_collision_check
        bcc     gutsdozer_check_hit_flash
gutsdozer_death_fade:  lda     #$00
        sta     $0354
        sta     $0355
        lda     #$0D
        sta     $B2
        lda     #$00
        sta     $0661
        sta     $0641
        sta     $0621
        sta     $0601
        inc     $05AA
        lda     #$07
        sta     $B1
        bne     gutsdozer_apply_facing
gutsdozer_check_hit_flash:  lda     temp_02
        cmp     #$01
        bne     gutsdozer_apply_facing
        lda     #$30
        sta     $0366
gutsdozer_apply_facing:  lda     $05A7
        sta     $0421
        jsr     dragon_apply_movement
        lda     #$83
        sta     $0421
        rts

        .byte   $A9,$AD,$1D,$47,$37,$4B
gutsdozer_ai_table_hi:  .byte   $93,$94,$95,$95,$95,$95
        dex
        lda     $96BC,x
        sta     jump_ptr
        lda     $96BE,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)
        jsr     boss_health_bar_tick
        lda     $06C1
        cmp     #MAX_HP
        beq     *+3
        rts
        lda     #$04
        sta     temp_02


; =============================================================================
; Boss AI: Guts Dozer — part spawning and position tables ($968B)
; =============================================================================
gutsdozer_spawn_part_loop:  lda     #$6D
        ldx     #$01
        jsr     spawn_entity_from_boss
        ldx     temp_02
        lda     gutsdozer_part_x_table,x
        sta     ent_x_spawn_px,y
        lda     gutsdozer_part_y_table,x
        sta     ent_y_spawn_px,y
        lda     gutsdozer_part_flags_table,x
        sta     ent_spawn_flags,y
        dec     temp_02
        bpl     gutsdozer_spawn_part_loop
        inc     $B1
        rts

gutsdozer_part_x_table:  .byte   $14,$44,$AC,$EC,$EC
gutsdozer_part_y_table:  .byte   $60,$30,$40,$70,$B0
gutsdozer_part_flags_table:  .byte   $C3,$C3,$83,$83,$83,$7C,$57,$96
        .byte   $93
        dex
        lda     $9B1C,x
        sta     jump_ptr
        lda     $9B23,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)
        lda     #$00
        sta     $0681
        lda     $04E1
        bne     *+55
        lda     #$02
        sta     $0354
        lda     #$04
        sta     $0355
        lda     #$B0
        sta     $05A7
        lda     #$00
        sta     $05A9
        sta     $0354
        sta     $0355
        lda     #$0F
        ldx     #$0B


; =============================================================================
; Boss AI: Wily 4 — Boobeam Trap palette and nametable setup ($96F6)
; =============================================================================
boobeam_fill_palette_loop:  sta     $035A,x
        dex
        bpl     boobeam_fill_palette_loop
        lda     #$15
        sta     col_update_addr_hi
        lda     #$A0
        sta     col_update_addr_lo
        lda     #$52
        sta     $B2
        inc     $04E1
        lda     $04E1
        cmp     #$01
        bne     boobeam_phase2_check
        lda     #$08
        jsr     sound_column_copy
        dec     $B2
        beq     boobeam_advance_phase
        rts

boobeam_advance_phase:  inc     $04E1
        lda     #$00
        sta     $B2
        lda     #$27
        sta     col_update_addr_hi
        lda     #$CB
        sta     col_update_addr_lo
        rts

boobeam_phase2_check:  cmp     #$02
        bne     boobeam_phase3_entry
        ldx     $B2
        cpx     #$14
        beq     boobeam_phase2_done
        jsr     boobeam_tile_row_copy
        rts

boobeam_phase2_done:  inc     $04E1
        lda     #$00
        sta     $B2
        lda     #$5C
        sta     $05A7
        rts

boobeam_phase3_entry:  ldx     $B2
        cpx     #$0E
        bcs     boobeam_palette_anim_check
        jsr     boobeam_column_fill
        rts

boobeam_palette_anim_check:  cpx     #$13
        bcs     boobeam_health_check
        lda     frame_counter
        and     #$03
        bne     boobeam_health_check
        lda     #$04
        ldy     #$0B
        ldx     #$0F
        jsr     boobeam_palette_blend
        lda     #$18
        ldy     #$13
        ldx     #$1F
        jsr     boobeam_palette_blend
        inc     $B2
        rts

boobeam_health_check:  jsr     boss_health_bar_tick
        lda     $06C1
        cmp     #MAX_HP
        bne     boobeam_health_rts
        inc     $B1
        lda     #$56
        ldx     #$01
        jsr     spawn_entity_from_boss
        lda     #$AB
        sta     ent_spawn_flags,y
        lda     #$B0
        sta     ent_x_spawn_px,y
        lda     #$80
        sta     ent_y_spawn_px,y
        lda     #$3E
        sta     $B2
boobeam_health_rts:  rts


; =============================================================================
; Boobeam Palette Blend — smooth color transition for trap room ($979B)
; =============================================================================
boobeam_palette_blend:  sta     temp_00
boobeam_palette_blend_loop:  lda     palette_ram,x
        cmp     #$0F
        bne     boobeam_palette_add
        lda     boobeam_target_palette,y
        and     #$0F
        jmp     boobeam_palette_store

boobeam_palette_add:  clc
        adc     #$10
        cmp     boobeam_target_palette,y
        beq     boobeam_palette_store
        bcs     boobeam_palette_loop_end
boobeam_palette_store:  sta     palette_ram,x
boobeam_palette_loop_end:  dex
        dey
        cpx     temp_00
        bne     boobeam_palette_blend_loop
        rts

boobeam_target_palette:  .byte   $0F,$15,$17,$35,$0F,$27,$17,$07
        .byte   $0F,$15,$17,$07,$0F,$0F,$11,$2C
        .byte   $0F,$0F,$25,$15
boobeam_column_fill:  lda     projectile_x_velocity,x
        sta     col_update_addr_hi
        lda     projectile_y_velocity,x
        sta     col_update_addr_lo
        lda     projectile_timing,x
        sta     col_update_count
        ldy     #$00
boobeam_column_fill_loop:  lda     $05A7
        sta     col_update_tiles,y
        inc     $05A7
        iny
        cpy     col_update_count
        bne     boobeam_column_fill_loop
        inc     $B2
        rts

boobeam_tile_row_copy:  ldy     #$00
boobeam_tile_row_loop:  lda     projectile_anim_frames,x
        sta     col_update_tiles,y
        inx
        iny
        cpy     #$05
        bne     boobeam_tile_row_loop
        sty     col_update_count
        stx     $B2
        clc
        lda     col_update_addr_lo
        adc     #$08
        sta     col_update_addr_lo
        rts

        lda     $0461
        cmp     #$38
        bcs     *+4
        inc     $B1
        lda     #$83


; =============================================================================
; Boss AI: Wily 5 — Wily Machine movement and attack patterns ($981F)
; =============================================================================
wily_machine_apply_facing:  sta     $0421
        sta     $05A7
        jsr     wily_machine_hit_check
        lda     #$83
        sta     $0421
        dec     $B2
        bne     wily_machine_store_facing
        lda     #$3E
        sta     $B2
        lda     $0461
        pha
        clc
        adc     #$28
        sta     $0461
        jsr     calc_player_boss_distance
        pla
        sta     $0461
        lda     temp_00
        sta     $0B
        lda     #$1A
        sta     $0D
        lda     #$00
        sta     $0A
        sta     $0C
        jsr     divide_16bit            ; divide for velocity ratio
        lda     #$6B
        ldx     #$01
        jsr     spawn_entity_from_boss
        bcs     wily_machine_store_facing
        clc
        lda     $0461
        adc     #$28
        sta     ent_x_spawn_px,y
        clc
        lda     $04A1
        adc     #$36
        sta     ent_y_spawn_px,y
        lda     $0F
        sta     $0610,y
        lda     $0E
        sta     $0630,y
        lda     $B1
        cmp     #$04
        bcc     wily_machine_store_facing
        lda     ent_spawn_flags,y
        ora     #$04
        sta     ent_spawn_flags,y
        lda     #$00
        sta     $0650,y
        sta     $0670,y
        lda     #$01
        sta     $0610,y
        lda     #$1E
        sta     $0630,y
wily_machine_store_facing:  lda     #$83
        sta     $0421
        rts

        lda     $0461
        cmp     #$98
        bcc     *+4
        dec     $B1
        lda     #$C3
        jmp     wily_machine_apply_facing

        jsr     boss_health_bar_tick
        lda     #$00
        sta     $0681
        sta     $06A1
        dec     $05AB
        bne     *+67
        lda     #$0C
        sta     $05AB
        lda     rng_seed
        sta     temp_01
        lda     #$18
        sta     temp_02
        jsr     $C84E
        lda     temp_04
        sta     jump_ptr
        lda     rng_seed
        sta     temp_01
        lda     #$30
        sta     temp_02
        jsr     $C84E
        lda     temp_04
        sta     jump_ptr_hi
        lda     #$6C
        ldx     #$01
        jsr     spawn_entity_from_boss
        bcs     *+23
        sec
        lda     $04A1
        sbc     #$18
        clc
        adc     jump_ptr_hi
        sta     ent_y_spawn_px,y
        clc
        lda     $0461
        adc     jump_ptr
        sta     ent_x_spawn_px,y
        lda     $04E1
        bne     wily_machine_phase_check
        lda     #$73
        sta     $0401
        lda     #$27
        sta     col_update_addr_hi
        lda     #$CB
        sta     col_update_addr_lo
        lda     #$14
        sta     $B2
        inc     $04E1
wily_machine_phase_check:  lda     $04E1
        cmp     #$02
        bcs     wily_machine_phase2
        ldx     $B2
        cpx     #$28
        beq     wily_machine_phase1_check
        jsr     boobeam_tile_row_copy
        rts

wily_machine_phase1_check:  lda     #$0E
        sta     $B2
        lda     #$00
        sta     $05A9
        inc     $04E1
wily_machine_phase2:  ldx     $B2
        cpx     #$16
        bcs     wily_machine_health_check
        lda     projectile_x_velocity,x
        sta     col_update_addr_hi
        lda     projectile_y_velocity,x
        sta     col_update_addr_lo
        lda     projectile_timing,x
        sta     col_update_count
        ldy     #$00
        ldx     $05A9
wily_machine_tile_copy_loop:  lda     projectile_tile_ids,x
        sta     col_update_tiles,y
        inx
        iny
        cpy     col_update_count
        bne     wily_machine_tile_copy_loop
        stx     $05A9
        inc     $B2
        rts

wily_machine_health_check:  lda     $06C1
        cmp     #MAX_HP
        beq     wily_machine_advance_phase
        rts

wily_machine_advance_phase:  inc     $B1
        lda     #$3E
        sta     $B2
        lda     #$A3
        sta     $0621
        rts

        lda     $04E1
        beq     *+30
        lda     ent_y_px
        cmp     #$E0
        bcs     wily_machine_clear_flags
        inc     ent_y_px
        inc     ent_y_px
        rts

wily_machine_clear_flags:  lda     #$00
        sta     ent_flags
        dec     $B2
        bne     wily_machine_scroll_rts
        lda     #$FF
        sta     $B1
wily_machine_scroll_rts:  rts

        jsr     picopico_palette_flash
        lda     $04A1
        beq     wily_machine_rng_spawn
        sec
        lda     $04C1
        sbc     #$80
        sta     $04C1
        lda     $04A1
        sbc     #$00
        sta     $04A1
        bne     wily_machine_rng_spawn
        sta     $0421
wily_machine_rng_spawn:  lda     rng_seed
        sta     temp_01
        lda     #$20
        sta     temp_02
        jsr     divide_8bit
        lda     #$06
        ldx     #$01
        jsr     spawn_entity_from_boss
        bcs     wily_machine_inc_timer
        lda     rng_seed
        asl     a
        lda     rng_seed
        rol     a
        rol     a
        rol     a
        rol     a
        ora     #$08
        sta     ent_x_spawn_px,y
        clc
        lda     temp_04
        adc     #$C8
        sta     ent_y_spawn_px,y
wily_machine_inc_timer:  inc     $B2
        lda     $B2
        cmp     #$FD
        beq     wily_machine_palette_reset
        rts

wily_machine_palette_reset:  lda     #$0F
        ldx     #$10
wily_machine_palette_loop:  sta     palette_ram,x
        dex
        bpl     wily_machine_palette_loop
        inc     $04E1
        lda     #$0B
        sta     game_substate
        lda     #$00
        sta     ent_anim_id
        sta     ent_anim_frame
        lda     #ENTITY_KEROG
        sta     ent_type
        lda     #$3E
        sta     $B2
        rts


; =============================================================================
; Wily Machine Damage — weapon invincibility and hit detection ($9A10)
; =============================================================================
wily_machine_hit_check:  lda     #$0F
        sta     $0366
        lda     $B1
        cmp     #$04
        bcs     wily_machine_invincible_check
        lda     current_weapon
        cmp     #$02
        beq     wily_machine_set_invincible
        cmp     #$05
        beq     wily_machine_set_invincible
        bne     wily_machine_collision_test
wily_machine_invincible_check:  lda     current_weapon
        cmp     #$01
        bne     wily_machine_collision_test
wily_machine_set_invincible:  lda     $0421
        ora     #$08
        sta     $0421
wily_machine_collision_test:  jsr     weapon_boss_collision_check
        bcc     wily_machine_check_flash
        lda     $B1
        cmp     #$04
        bcs     wily_machine_death_explosion
        lda     #$04
        sta     $B1
        lda     #$0C
        sta     $05AB
        lda     #$00
        sta     $0601
        sta     $0621
        sta     $04E1
        beq     wily_machine_jmp_movement
wily_machine_death_explosion:  lda     #$74
        jsr     play_sound_and_reset_anim
        clc
        lda     $0461
        adc     #$28
        sta     $0461
        lda     #$57
        sta     $04A1
        lda     #$00
        sta     $04E1
        lda     #$56
        jsr     find_entity_by_type
        bcs     wily_machine_death_jmp
        lda     #$00
        .byte   $99
        .byte   $30
wily_machine_data_byte:  .byte   $04
wily_machine_death_jmp:  jmp     gutsdozer_death_fade

wily_machine_check_flash:  lda     temp_02
        cmp     #$01
        bne     wily_machine_jmp_movement
        lda     #$30
        sta     $0366
wily_machine_jmp_movement:  jsr     dragon_apply_movement
        rts

projectile_x_velocity:  and     p1_prev_buttons
        and     p1_prev_buttons
        and     p1_prev_buttons
        and     p1_prev_buttons
        rol     p2_prev_buttons
        rol     p2_prev_buttons
        rol     p2_prev_buttons
        and     p1_prev_buttons
        and     p1_prev_buttons
        rol     p2_prev_buttons
        rol     p2_prev_buttons
projectile_y_velocity:  .byte   $17
        rol     $56,x
        adc     ($90),y
        bcs     wily_machine_data_byte
        beq     wily_machine_proj_timing_data
        rol     $6E4E
        .byte   $93,$B4,$90,$B0,$D0,$F0,$0E,$2E
        .byte   $4E,$6E
projectile_timing:  .byte   $04
wily_machine_proj_timing_data:  ora     temp_06
        .byte   $0B,$0D,$0D,$0D,$0D,$0F,$0E,$0D
        .byte   $0C,$04,$02,$04,$04,$04,$04,$06
        .byte   $07,$05,$04
projectile_anim_frames:  .byte   $FF,$AF,$FF,$BF,$FF,$FF,$FD,$FF
        .byte   $FA,$EE,$F7,$BF,$AF,$FF,$FF,$FF
        .byte   $FB,$FA,$FF,$FF,$FF,$AF,$FF,$BF
        .byte   $FF,$FF,$EE,$FF,$FA,$EE,$FB,$BE
        .byte   $AF,$FF,$FF,$FF,$FB,$FA,$FF,$FF
projectile_tile_ids:  .byte   $00,$E6,$E7,$E8,$00,$00,$E9,$EA
        .byte   $00,$00,$EB,$EC,$ED,$EE,$EF,$F0
        .byte   $00,$00,$F1,$F2,$F3,$F4,$F5,$F6
        .byte   $F7,$F8,$F9,$FA,$FB,$00,$00,$00
        .byte   $00,$FC,$00,$00,$00,$00
        dec     calc_distance_data_byte
        bcs     alien_jmp_dispatch
        ldx     #$7B
        stx     $98,y
        tya
        tya
        tya
        tya
        sta     chr_data_BDCA,y
        lda     woodman_data_byte,x
        php
        lda     alien_phase_ptr_hi_table,x
        sta     jump_ptr_hi


; =============================================================================
; Boss AI: Wily 6 — Alien hologram movement and attack ($9B35)
; =============================================================================
alien_jmp_dispatch:  jmp     (jump_ptr)

        lda     $04E1
        bne     *+34
        ldy     #$0F
        ldx     #$0E
        jsr     $D3E0
        lda     #$08
        sta     $04AE
        lda     #$B4
        sta     $046E
        lda     #$7D
        sta     $B2
        lda     #$00
        sta     $0354
        sta     $0355
        inc     $04E1
        lda     $04E1
        cmp     #$02
        bcs     alien_phase2_check
        lda     $042E
        bpl     alien_dec_timer
        lda     $04AE
        cmp     #$90
        bcc     alien_descent_rts
        ldx     #$83
        stx     $0421
        cmp     #$E0
        bcc     alien_descent_rts
        lsr     $042E
alien_descent_rts:  rts

alien_dec_timer:  dec     $B2
        bne     alien_descent_rts
        ldx     #$02
alien_palette_copy:  lda     alien_palette_table,x
        sta     $036F,x
        dex
        bpl     alien_palette_copy
        inc     $04E1
        lda     #$76
        jsr     play_sound_and_reset_anim
alien_palette_rts:  rts

alien_phase2_check:  bne     alien_movement_update
        lda     $06A1
alien_phase2_compare:  cmp     #$03
        bne     alien_palette_rts
        lda     #$00
        sta     $0681
        ldx     #$0A
        lda     $B2
        cmp     #$7D
        bcc     alien_palette_threshold
        ldx     #$12
alien_palette_threshold:  lda     $B2
        and     #$04
        beq     alien_palette_anim_range
        txa
        clc
        adc     #$08
        tax
alien_palette_anim_range:  ldy     #$07
alien_palette_copy_loop:  lda     alien_palette_table,x
        sta     $036E,y
        dex
        dey
        bpl     alien_palette_copy_loop
        inc     $B2
        lda     $B2
        cmp     #$FD
        bne     alien_palette_inc_rts
        inc     $04E1
        lda     #$77
        jsr     play_sound_and_reset_anim
alien_palette_inc_rts:  rts

alien_movement_update:  lda     $0461
        cmp     #$D8
        beq     alien_health_check
        clc
        lda     $0481
        adc     #$80
        sta     $0481
        lda     $0461
        adc     #$00
        sta     $0461
alien_health_check:  jsr     boss_health_bar_tick
        lda     $06C1
        cmp     #MAX_HP
        bne     alien_palette_inc_rts
        inc     $B1
        lda     #$0E
        sta     $B2
        lda     #$3E
        sta     $05A7
        lda     #$00
        sta     $05A9
        lda     #$30
        sta     $035F
        lda     #$01
        sta     current_entity_slot
        ldx     #$0C
alien_spawn_part_loop:  stx     temp_02
        lda     #$70
        jsr     spawn_entity_init_type
        ldx     temp_02
alien_part_setup_loop:  lda     alien_part_y_table,x
        sta     ent_y_spawn_px,x
        lda     alien_part_x_flags_table,x
        pha
        and     #$F0
        ora     #$04
        sta     ent_x_spawn_px,x
        pla
        and     #$0F
        sta     $06B0,x
        dex
        bpl     alien_spawn_part_loop
        rts

alien_part_y_table:  .byte   $34,$34,$64,$94,$B4,$D4,$24,$44
        .byte   $54,$74,$84,$B4,$C4
alien_part_x_flags_table:  jsr     fixed_D0B0
        bvs     alien_facing_store
        beq     alien_part_setup_loop
        eor     (temp_01),y
        lda     ($31,x)
        sbc     ($11,x)
alien_palette_table:  bmi     alien_palette_data_byte
        asl     $0F,x
        asl     $30,x
        bmi     alien_palette_block_2
        asl     current_screen,x
        sec
        .byte   $0F,$16,$38,$29,$0F,$16,$38,$29
        .byte   $0F,$16,$29,$19
alien_palette_block_2:  .byte   $0F,$16,$29,$19
        jsr     $9CD8
        jsr     boss_check_weapon_hit
        ldx     #$0F
        lda     temp_02
        cmp     #$01
        bne     alien_facing_store
        lda     $05AA
        beq     *+10
        lda     #$00
        sta     $04E1
        inc     $B1
        rts
        ldx     #$30
alien_facing_store:  .byte   $8E
        .byte   $66
alien_palette_data_byte:  .byte   $03
        clc
        lda     $B7
        adc     #$60
        sta     $B7
        lda     camera_x_offset
        adc     #$01
        sta     camera_x_offset
        lda     camera_x_offset_hi
        adc     #$00
        sta     camera_x_offset_hi
        jsr     calc_player_boss_distance
        dec     $05A7
        bne     alien_frame_update
        lda     #$3E
        sta     $05A7
        lda     #$6F
        jsr     spawn_entity_from_boss
        bcs     alien_frame_update
        lda     #$04
        jsr     dragon_fire_setup_velocity
alien_frame_update:  rts

alien_move_y_sub_table:  .byte   $B9,$19,$00,$E7,$47,$E7,$00,$19
alien_move_y_hi_table:  .byte   $FE,$FF,$00,$00,$01,$00,$00,$FF
alien_move_x_sub_table:  .byte   $00,$E7,$47,$E7,$00,$E7,$47,$E7
alien_move_x_hi_table:  .byte   $00,$00,$01,$00,$00,$00,$01,$00
        dec     $B2
        bne     alien_movement_pattern
        inc     $05A9
        lda     #MAX_HP
        sta     $B2


; =============================================================================
; Alien Movement Pattern — sinusoidal path from velocity tables ($9CE3)
; =============================================================================
alien_movement_pattern:  lda     $05A9
        pha
        and     #$07
        tax
        lda     alien_move_y_sub_table,x
        sta     $0661
        lda     alien_move_y_hi_table,x
        sta     $0641
        lda     alien_move_x_sub_table,x
        sta     $0621
        lda     alien_move_x_hi_table,x
        sta     $0601
        ldx     #$83
        pla
        and     #$08
        beq     alien_facing_store_2
        ldx     #$C3
alien_facing_store_2:  stx     $0421
        rts

        ldx     $04E1
        bne     alien_phase_dispatch
        lda     #$E0
        sta     col_update_addr_lo
        lda     #$0F
        sta     col_update_addr_hi
        lda     #$00
        sta     $05A9
        lda     #$94
        sta     $05A7
        lda     #$80
        sta     $B2
        inc     $04E1
        inx
        lda     #$FF
        jsr     bank_switch_enqueue
        lsr     $0421
alien_phase_dispatch:  dex
        lda     alien_phase_dispatch_hi,x
        sta     jump_ptr_hi
        lda     alien_phase_ptr_lo,x
        sta     jump_ptr
        jmp     (jump_ptr)

alien_palette_flash_tick:  lda     frame_counter
        and     #$0F
        bne     alien_palette_set_colors
        lda     #$2B
        jsr     bank_switch_enqueue
alien_palette_set_colors:  ldx     #$10
        ldy     #$0F
        lda     frame_counter
        and     #$04
        bne     alien_palette_alt_color
        ldy     #$30
alien_palette_alt_color:  tya
alien_palette_fill_loop:  sta     palette_ram,x
        dex
        bpl     alien_palette_fill_loop
        rts

        jsr     alien_palette_flash_tick
        lda     $B2
        beq     *+10
        lda     #$08
        jsr     $C5F1
        dec     $B2
        rts
        inc     $04E1
        lda     #$00
        sta     $FD
        lda     #$0F
        sta     $FE
        rts

        jsr     alien_palette_flash_tick
        lda     $FD
        cmp     #$60
        bcs     *+6
        jsr     $CB0C
        rts
        inc     $04E1
        lda     #$00
        sta     $05A7
        lda     #$8D
        sta     $05A9
        lda     #$00
        sta     column_index
        sta     ppu_buffer_count
        beq     alien_scroll_update
        jsr     alien_palette_flash_tick
        lda     $05A7
        and     #$3F
        beq     alien_scroll_setup_entities


; =============================================================================
; Alien Scroll — stage background scrolling during battle ($9DAC)
; =============================================================================
alien_scroll_update:  lda     #$0C
        sta     current_stage
        lda     $05A7
        sta     jump_ptr
        lda     $05A9
        sta     jump_ptr_hi
        jsr     scroll_attr_update
        lda     #$0D
        sta     current_stage
        inc     $05A7
        inc     column_index
        rts


; =============================================================================
; Alien Stage Setup — entity spawn and palette initialization ($9DC7)
; =============================================================================
alien_scroll_setup_entities:  inc     $04E1
        inc     nametable_select
        inc     ent_x_screen
        inc     $0441
        lda     #$00
        sta     camera_x_offset
        sta     camera_x_offset_hi
        ldx     #$10
alien_load_palette_loop:  lda     alien_stage_palette,x
        sta     palette_ram,x
        dex
        bpl     alien_load_palette_loop
        ldy     #$10
        ldx     #$0E
        jsr     fixed_D3E0
        lda     #$80
        sta     $042E
        lda     #$A7
        sta     $04AE
        lda     #$E0
        sta     $046E
        ldy     #$11
        ldx     #$0D
        jsr     fixed_D3E0
        lda     #$80
        sta     $046D
        lda     #$37
        sta     $04AD
        lda     #$80
        sta     $0421
        lda     #$80
        sta     $04A1
        lda     #$D8
        sta     $0461
        lda     #$0E
        sta     $B2
        lda     #$00
        sta     $05A9
        sta     $05AB
        lda     #$78
        jsr     play_sound_and_reset_anim
        lda     #$2A
        jsr     bank_switch_enqueue
        rts

alien_stage_palette:  .byte   $0F,$20,$11,$01,$0F,$20,$2C,$1C
        .byte   $0F,$20,$23,$13,$0F,$20,$0F,$0F
        .byte   $0F,$20,$6D,$9E
        lda     $05A9
        cmp     #$24
        beq     *+11
        jsr     $9CD8
        stx     temp_03
        jsr     $A157
        rts
        lda     #$84
        sta     $0421
        lda     #$00
        sta     $B2
        sta     $0601
        sta     $0621
        sta     $0641
        sta     $0661
        inc     $04E1
        rts

        ldx     #$2C
        lda     frame_counter
        and     #$04
        bne     alien_sprite_flash_store
        ldx     #$00
alien_sprite_flash_store:  stx     $0370
        rts

alien_fade_palette_data:  .byte   $0F,$20,$0F,$0F,$0F,$20,$0C,$0F
        .byte   $0F,$20,$1C,$0C,$0F,$20,$11,$0C
        .byte   $0F,$20,$11,$01
        jsr     $9E6D
        lda     #$80
        sta     temp_03
        jsr     $A157
        lda     #$04
        sta     temp_01
        sta     temp_02
        jsr     boss_floor_collision_check
        lda     temp_00
        beq     alien_aim_rts
        ldx     $B2
        cpx     #$02
        beq     alien_deactivate_sprites
        lda     alien_vel_y_data,x
        sta     $0661
        lda     alien_vel_y_hi_data,x
        sta     $0641
        inc     $B2
alien_aim_rts:  rts

alien_deactivate_sprites:  lsr     $042E
        lda     #$79
        jsr     play_sound_and_reset_anim
        lda     #$A7
        sta     $04A1
        lda     #$E0
        sta     $0461
        lda     #$3E
        sta     $B2
        lda     #$00
        sta     $05A7
        inc     $04E1
        lsr     $042D
        ldx     #$0F
alien_deactivate_loop:  lsr     ent_spawn_flags,x
        dex
        bpl     alien_deactivate_loop
        lda     #$30
        sta     $0374
        lda     #$15
        sta     $0375
        rts

alien_vel_y_data:  .byte   $76,$00
alien_vel_y_hi_data:  .byte   $03,$02
        lda     $B2
        beq     *+29
        lda     frame_counter
        and     #$07
        bne     *+7
        lda     #$2B
        jsr     $C051
        ldx     #$0F
        lda     frame_counter
        and     #$04
        bne     alien_palette_flash_store
        ldx     #$30
alien_palette_flash_store:  stx     $0366
        dec     $B2
        rts

        lda     #$0F
        sta     $0366
        inc     $05A7
        lda     $05A7
        cmp     #$41
        beq     alien_advance_phase
        lsr     a
        lsr     a
        and     #$1C
        tax
        ldy     #$00
alien_fade_palette_loop:  lda     alien_fade_palette_data,x
        sta     $0362,y
        inx
        iny
        cpy     #$04
        bne     alien_fade_palette_loop
        rts

alien_advance_phase:  inc     $04E1
        lda     #$7A
        jsr     play_sound_and_reset_anim
        lda     #$84
        sta     $0421
        lda     #$50
        sta     $0621
        lda     #$00
        sta     $0601
        lda     #$53
        sta     $0661
        lda     #$06
        sta     $0641
        rts

        lda     #$84
        sta     temp_03
        jsr     $A157
        lda     #$0C
        sta     temp_01
        sta     temp_02
        jsr     boss_floor_collision_check
        lda     temp_00
        bne     *+3
        rts
        lda     ent_flags
        and     #$BF
        ldx     ent_x_px
        cpx     #$B0
        bcs     alien_facing_update
        ora     #$40
alien_facing_update:  sta     ent_flags
        lda     #$7B
        jsr     play_sound_and_reset_anim
        inc     $04E1
        lda     #$FD
        sta     $05A7
        lda     #$80
        sta     $05A9
        lda     #$02
        sta     $05AB
        lda     #$16
        jsr     bank_switch_enqueue
        rts

        jsr     calc_player_boss_distance
        lda     $05A7
        beq     *+6
        dec     $05A7
        rts
        lda     #$00
        sta     $06A1
        sta     $0681
        dec     $05A9
        bne     alien_phase_rts
        dec     $05AB
        bne     alien_phase_rts
        lda     #$FF
        sta     $B1
alien_phase_rts:  rts

        sec
        .byte   $6B,$0F
alien_phase_ptr_lo:  .byte   $65,$80,$A2,$41,$8F,$F3,$57,$9A
alien_phase_ptr_hi_table:  .byte   $9B,$9C,$9D
alien_phase_dispatch_hi:  .byte   $9D,$9D,$9D,$9E,$9E,$9E,$9F,$9F


; =============================================================================
; Fortress Enemy Fallback — generic AI for non-boss fortress enemies ($9FD3)
; =============================================================================
enemy_ai_fallback:  sec
        lda     $B3
        sbc     #$08
        bcc     fortress_enemy_no_boss
        tax
        lda     fortress_boss_ptr_lo,x
        sta     jump_ptr
        lda     fortress_boss_ptr_hi,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)

fortress_enemy_no_boss:  lda     #$00
        sta     $0681
        lda     $05A7
        cmp     #$10
        bcc     fortress_spawn_check_odd
        jmp     fortress_post_defeat

fortress_spawn_check_odd:  and     #$01
        bne     fortress_inc_spawn_timer
        lda     $05A7
        and     #$07
        sta     temp_02
        ldx     #$01
fortress_spawn_entity_loop:  stx     temp_01
        lda     #$60
        jsr     spawn_entity_init_type
        ldx     temp_02
        clc
        lda     $0461
        adc     $C1E0,x
        sta     ent_x_spawn_px,y
        lda     $0441
        adc     $C1E8,x
        sta     ent_x_spawn_scr,y
        clc
        lda     $04A1
        adc     $C1D8,x
        sta     ent_y_spawn_px,y
        lda     #$01
        sta     $06B0,y
        inx
        stx     temp_02
        ldx     temp_01
        dex
        bpl     fortress_spawn_entity_loop
fortress_inc_spawn_timer:  inc     $05A7
        lda     $05A7
        cmp     #$10
        bne     fortress_spawn_rts
        ldx     #$1B
        lda     $0461
        sta     jump_ptr
        lda     $0441
        sta     jump_ptr_hi
        lda     $04A1
        sta     $0A
        lda     #$60
        sta     $0B
        jsr     explosion_array_setup_inner
        lda     #$41
        jsr     bank_switch_enqueue
        lda     #$FF
        jsr     bank_switch_enqueue
        lda     current_stage
        cmp     #$0C
        bne     fortress_spawn_rts
        lda     #$76
        ldx     #$0E
        jsr     spawn_entity_init_type
        lda     #$02
        sta     $065E
        lda     #$85
        sta     $043E
        inc     $04FE
        lda     $BC
        cmp     #$FF
        beq     fortress_spawn_rts
        lsr     $0421
        lda     #$00
        sta     $B1
fortress_spawn_rts:  rts


; =============================================================================
; Fortress Post-Defeat — cleanup after fortress boss defeated ($A08B)
; =============================================================================
fortress_post_defeat:  lsr     $0421
        lda     $05A7
        cmp     #$FD
        bcs     fortress_defeat_phase_2
        inc     $05A7
        rts

fortress_defeat_phase_2:  bne     fortress_defeat_phase_3
        inc     $05A7
        lda     #$FD
        sta     $05A9
        lda     #$15
        jsr     bank_switch_enqueue
        rts

fortress_defeat_phase_3:  cmp     #$FE
        bne     fortress_defeat_check_timer
        dec     $05A9
        bne     fortress_defeat_done
        inc     $05A7
        lda     #$D0
        sta     $05A9
fortress_defeat_check_timer:  lda     $05A9
        cmp     #$40
        bcc     fortress_defeat_spawn_entity
        bne     fortress_defeat_dec_timer
        dec     $05A9
        lda     #ENTITY_LIGHT_RESTORE
        sta     ent_type
        lda     #$00
        sta     ent_anim_id
        sta     ent_anim_frame
        lda     #$0B
        sta     game_substate
        lda     #$3A
        jsr     bank_switch_enqueue
fortress_defeat_spawn_entity:  lda     ent_anim_id
        cmp     #$03
        bne     fortress_defeat_done
        lda     ent_flags
        bpl     fortress_defeat_dec_timer
        sec
        lda     ent_y_px
        sbc     #$08
        sta     ent_y_px
        bcs     fortress_defeat_done
        lsr     ent_flags
fortress_defeat_dec_timer:  dec     $05A9
        bne     fortress_defeat_done
        lda     #$FF
        sta     $B1
fortress_defeat_done:  rts

fortress_boss_ptr_lo:  .byte   $22,$69,$22,$69,$7B,$0F
fortress_boss_ptr_hi:  .byte   $91,$93,$91,$93,$99,$9D


; =============================================================================
; Play Sound & Reset — queue sound effect, clear anim/hit state ($A10C)
; =============================================================================
play_sound_and_reset_anim:  sta     $0401; queue sound effect ID
        lda     #$00
        sta     $0681
        sta     $06A1
        rts


; =============================================================================
; Boss Health Bar — increment health bar fill during intro ($A118)
; =============================================================================
boss_health_bar_tick:  lda     frame_counter      ; frame counter for timing
        and     #$03
        bne     boss_health_bar_rts
        lda     $06C1
        cmp     #MAX_HP
        beq     boss_health_bar_rts
        inc     $06C1                   ; increment health bar fill
        lda     #$28
        jsr     bank_switch_enqueue
boss_health_bar_rts:  rts

boss_flip_and_check_wall:  lda     $0421
        eor     #$40
        sta     $0421
        jsr     boss_wall_collision_check
        lda     $0421
        sta     temp_03
        eor     #$40
        sta     $0421
        jmp     boss_movement_physics_inner

boss_check_weapon_hit:  jsr     weapon_boss_collision_check
        bcc     boss_apply_movement_physics
        inc     $05AA
        rts


; =============================================================================
; Boss Movement Physics — apply velocity to position with clamping ($A14F)
; =============================================================================
boss_apply_movement_physics:  lda     $0421
        sta     temp_03
boss_movement_physics_inner:  jsr     setup_ppu_normal
        sec
        lda     $04C1
        sbc     $0661
        sta     $04C1
        lda     $04A1
        sbc     $0641
        sta     $04A1
        cmp     #$F0
        bcc     boss_clamp_y_position
        lda     #$F0
        sta     $04A1
boss_clamp_y_position:  lda     $0421
        and     #$04
        beq     boss_check_facing_right
        clc
        lda     $0661
        sbc     $30
        sta     $0661
        lda     $0641
        sbc     $31
        sta     $0641
boss_check_facing_right:  lda     temp_03
        and     #$40
        bne     boss_move_facing_right
        sec
        lda     $0481
        sbc     $0621
        sta     $0481
        lda     $0461
        sbc     $0601
        sta     $0461
        lda     $0441
        sbc     #$00
        sta     $0441
        sec
        lda     $0461
        sbc     scroll_x
        sta     jump_ptr
        lda     $0441
        sbc     nametable_select
        bne     boss_clamp_x_left
        lda     jump_ptr
        cmp     #$08
        bcs     boss_movement_done
boss_clamp_x_left:  lda     nametable_select
        sta     ent_x_screen
        lda     #$08
        sta     $0461
        bne     boss_movement_done
boss_move_facing_right:  clc
        lda     $0481
        adc     $0621
        sta     $0481
        lda     $0461
        adc     $0601
        sta     $0461
        lda     $0441
        adc     #$00
        sta     $0441
        sec
        lda     $0461
        sbc     scroll_x
        sta     jump_ptr
        lda     $0441
        sbc     nametable_select
        bne     boss_clamp_x_right
        lda     jump_ptr
        cmp     #$F8
        bcc     boss_movement_done
boss_clamp_x_right:  lda     nametable_select
        sta     $0441
        lda     #$F8
        sta     $0461
boss_movement_done:  clc
        rts


; =============================================================================
; Player-Boss Distance — calculate X distance for aim/facing ($A209)
; =============================================================================
calc_player_boss_distance:  lda     $0421; boss entity flags
        and     #$BF
        sta     $0421
        sec
        .byte   $AD
        .byte   $61
calc_distance_data_byte:  .byte   $04
        sbc     ent_x_px
        sta     temp_00
        bcs     calc_distance_done
        lda     temp_00
        eor     #$FF
        adc     #$01
        sta     temp_00
        lda     #$40
        ora     $0421
        sta     $0421
calc_distance_done:  rts


; =============================================================================
; Find Entity by Type — scan entity slots for matching type ID ($A22D)
; =============================================================================
find_entity_by_type:  sta     temp_00; store target type ID
        ldy     #$0F
collision_check_sprite:  lda     temp_00; Check collision between player and sprite
find_entity_scan_loop:  cmp     ent_spawn_type,y
        beq     find_entity_check_active
        dey
        bpl     find_entity_scan_loop
        sec
        rts

find_entity_check_active:  lda     ent_spawn_flags,y
        bmi     find_entity_found
        dey
        bpl     collision_check_sprite
        sec
        rts

find_entity_found:  clc
        rts


; =============================================================================
; Boss Floor Collision — check tiles below boss for solid ground ($A249)
; =============================================================================
boss_floor_collision_check:  lda     #$00
        sta     $0B
        lda     $0641
        php
        bpl     boss_floor_check_above
        clc
        lda     $04A1
        adc     temp_02
        jmp     boss_floor_store_y

boss_floor_check_above:  sec
        lda     $04A1
        sbc     temp_02
boss_floor_store_y:  sta     $0A
        clc
        lda     $0461
        adc     temp_01
        sta     jump_ptr
        lda     $0441
        adc     #$00
        sta     jump_ptr_hi
        jsr     tile_lookup
        ldy     temp_00
        lda     tile_solidity_table,y
        sta     temp_02
        sec
        lda     $0461
        sbc     temp_01
        sta     jump_ptr
        lda     $0441
        sbc     #$00
        sta     jump_ptr_hi
        jsr     tile_lookup
        ldy     temp_00
        lda     tile_solidity_table,y
        ora     temp_02
        sta     temp_00
        beq     boss_floor_rts
        plp
        bmi     boss_floor_snap_down
        lda     $0A
        and     #$0F
        eor     #$0F
        sec
        adc     $04A1
        jmp     boss_floor_store_y_pos

boss_floor_snap_down:  lda     $04A1
        pha
        lda     $0A
        and     #$0F
        sta     temp_02
        pla
        sec
        sbc     temp_02
boss_floor_store_y_pos:  sta     $04A1
        lda     #$00
        sta     $04C1
        lda     $0421
        and     #$04
        beq     boss_floor_no_snap_rts
        lda     #$C0
        sta     $0661
        lda     #$FF
        sta     $0641
boss_floor_no_snap_rts:  rts

boss_floor_rts:  plp
        rts


; =============================================================================
; Boss Wall Collision — check tiles ahead of boss for walls ($A2D4)
; =============================================================================
boss_wall_collision_check:  lda     $04A1
        sta     $0A
        lda     #$00
        sta     $0B
        lda     $0421
        and     #$40
        php
        beq     boss_wall_check_left
        sec
        lda     $0461
        adc     temp_01
        sta     jump_ptr
        lda     $0441
        adc     #$00
        jmp     boss_wall_store_page

boss_wall_check_left:  clc
        lda     $0461
        sbc     temp_01
        sta     jump_ptr
        lda     $0441
        sbc     #$00
boss_wall_store_page:  sta     jump_ptr_hi
        jsr     tile_lookup
        ldy     temp_00
        lda     tile_solidity_table,y
        sta     temp_03
        beq     boss_wall_no_snap
        plp
        beq     boss_wall_snap_left
        lda     jump_ptr
        and     #$0F
        sta     temp_00
        sec
        lda     $0461
        sbc     temp_00
        sta     $0461
        lda     $0441
        sbc     #$00
        sta     $0441
        jmp     boss_floor_collision_check

boss_wall_snap_left:  lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     $0461
        sta     $0461
        lda     $0441
        adc     #$00
        sta     $0441
        jmp     boss_floor_collision_check

boss_wall_no_snap:  plp
        jmp     boss_floor_collision_check

tile_solidity_table:  .byte   $00
        .byte   $01,$00,$01,$00,$01,$01,$01,$01


; =============================================================================
; Spawn Entity from Boss — find free slot and initialize projectile ($A352)
; =============================================================================
spawn_entity_from_boss:  pha            ; save entity type on stack
        jsr     fixed_DA43              ; find empty entity slot
        bcs     spawn_entity_fail
        pla
spawn_entity_init_type:  jsr     fixed_D77C; initialize entity from type table
        txa
        tay
        lda     $0421
        and     #$40
        ora     ent_spawn_flags,y
        sta     ent_spawn_flags,y
        lda     $0481
        sta     $0490,y
        lda     $0461
        sta     ent_x_spawn_px,y
        lda     $0441
        sta     ent_x_spawn_scr,y
        lda     $04C1
        sta     $04D0,y
        lda     $04A1
        sta     ent_y_spawn_px,y
        clc
        rts

spawn_entity_fail:  pla
        sec
        rts


; =============================================================================
; Velocity Toward Player — calculate X/Y velocity to aim at player ($A38C)
; =============================================================================
calc_velocity_toward_player:  ldy     #$40; default: face right
        sec
        lda     ent_x_px
        sbc     ent_x_px,x
        sta     temp_00
        bcs     calc_velocity_set_facing
        lda     temp_00
        eor     #$FF
        adc     #$01
        ldy     #$00
        sta     temp_00
calc_velocity_set_facing:  lda     ent_flags,x
        and     #$BF
        sta     ent_flags,x
        tya
        ora     ent_flags,x
        sta     ent_flags,x
        sec
        lda     ent_y_px
        sbc     ent_y_px,x
        php
        bcs     velocity_calc_y_major
        eor     #$FF
        adc     #$01
velocity_calc_y_major:  sta     temp_01
        cmp     temp_00
        bcs     velocity_calc_x_major
        lda     jump_ptr_hi
        sta     $0D
        sta     ent_x_vel,x
        lda     jump_ptr
        sta     $0C
        sta     ent_x_vel_sub,x
        lda     temp_00
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     divide_16bit            ; divide for velocity ratio
        lda     $0F
        sta     $0D
        lda     $0E
        sta     $0C
        lda     temp_01
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     divide_16bit            ; divide for velocity ratio
        ldx     current_entity_slot
        lda     $0F
        sta     ent_y_vel,x
        lda     $0E
        sta     ent_y_vel_sub,x
        jmp     velocity_calc_negate_y

velocity_calc_x_major:  lda     jump_ptr_hi
        sta     $0D
        sta     ent_y_vel,x
        lda     jump_ptr
        sta     $0C
        sta     ent_y_vel_sub,x
        lda     temp_01
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     divide_16bit            ; divide for velocity ratio
        lda     $0F
        sta     $0D
        lda     $0E
        sta     $0C
        lda     temp_00
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     divide_16bit            ; divide for velocity ratio
        ldx     current_entity_slot
        lda     $0F
        sta     ent_x_vel,x
        lda     $0E
        sta     ent_x_vel_sub,x
velocity_calc_negate_y:  plp
        bcc     velocity_calc_done
        lda     ent_y_vel_sub,x
        eor     #$FF
        adc     #$01
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        eor     #$FF
        adc     #$00
        sta     ent_y_vel,x
velocity_calc_done:  rts


; =============================================================================
; Boss Initialization
; Sets up boss properties from indexed tables.
; X = boss ID ($B3), loads AI flags, position, type, etc.
; =============================================================================
boss_init:  ldx     $B3                 ; Initialize boss from property tables (X = boss ID)
        lda     nametable_select
        sta     $0441
        lda     boss_ai_flags,x         ; load AI behavior flags for this boss
        sta     $0421
        lda     boss_movement_mode,x    ; load default X position
        sta     $0461
        lda     boss_x_position,x       ; load Y position
        sta     $04A1
        lda     boss_y_position,x
        sta     $0401
        lda     boss_type_table,x       ; load boss entity type
        sta     $06E1
        lda     boss_x_velocity_table,x
        sta     $0621
        lda     boss_palette_table,x
        sta     $0601
        lda     boss_y_vel_sub_table,x
        sta     $0661
        lda     boss_y_vel_hi_table,x
        sta     $0641
        lda     #$00
        sta     $04C1
        sta     $0481
        sta     $0681
        sta     $06A1
        sta     $04E1
        sta     $06C1
        sta     $05A8
        sta     $05AA
        sta     $B2
        lda     #$01
        sta     $B1
        rts

boss_ai_flags:  .byte   $83,$83,$83,$83,$83,$83,$83,$83
        .byte   $8B,$00,$00,$00,$83,$00
boss_movement_mode:  .byte   $C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8
        .byte   $70,$C8,$FF,$C8,$78,$B4
boss_x_position:  .byte   $28
        .byte   $28
        .byte   $30,$28
        .byte   $28
        .byte   $28
        .byte   $28
        .byte   $28
        .byte   $6B,$10,$4B,$10,$77,$7C
boss_y_position:  .byte   $50,$66,$6C,$60,$54,$5A,$63,$69
        .byte   $70,$50,$71,$50,$72,$75
boss_type_table:  .byte   $01,$09,$09,$01,$01,$01,$01,$01
        .byte   $0D,$01,$01,$01,$00,$01
boss_x_velocity_table:  .byte   $00,$00
boss_x_vel_data:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $60,$00
        .byte   $C4,$00
boss_palette_table:  .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00,$00,$00,$00,$00
        .byte   $00
        .byte   $00
        .byte   $00,$00,$00
boss_y_vel_sub_table:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00
boss_y_vel_hi_table:  .byte   $F8,$F8
        .byte   $F8
        .byte   $F8
        .byte   $F8
        .byte   $F8
        .byte   $F8
        .byte   $F8
        .byte   $00
        .byte   $00,$00,$00,$00,$00


; =============================================================================
; Setup PPU Normal — check player-boss proximity for contact damage ($A52D)
; =============================================================================
setup_ppu_normal:  lda     #$00
        sta     temp_01
        lda     game_substate
        beq     proximity_check_rts
        lda     $BD
        bne     proximity_check_rts
        lda     $F9
        bne     proximity_check_rts
        sec
        lda     ent_x_px
        sbc     $0461
        bcs     proximity_calc_x_dist
        eor     #$FF
        adc     #$01
proximity_calc_x_dist:  ldy     $06E1
        cmp     $D4E4,y
        bcs     proximity_check_rts
        sec
        lda     ent_y_px
        sbc     $04A1
        bcs     proximity_check_y_dist
        eor     #$FF
        adc     #$01
proximity_check_y_dist:  cmp     $D584,y
        bcs     proximity_check_rts
        lda     invincibility_timer
        bne     proximity_check_rts
        ldy     $B3
        sec
        lda     ent_hp
        sbc     boss_contact_damage_table,y
        sta     ent_hp
        beq     proximity_boss_defeated
        bcs     proximity_flip_facing
proximity_boss_defeated:  lda     #$00
        sta     game_substate
        sta     ent_hp
        jmp     boss_death_sequence

proximity_flip_facing:  lda     ent_flags
        and     #$BF
        sta     ent_flags
        lda     $0421
        and     #$40
        eor     #$40
        ora     ent_flags
        sta     ent_flags
        jsr     fixed_D332
        inc     temp_01
proximity_check_rts:  rts


; =============================================================================
; Weapon-Boss Collision — check if player weapon hits boss ($A59D)
; =============================================================================
weapon_boss_collision_check:  ldx     #$09; start scanning from slot 9
        lda     frame_counter
        and     #$01
        bne     weapon_boss_check_slot
        dex
weapon_boss_check_slot:  lda     ent_flags,x
        bpl     weapon_boss_next_slot
        and     #$01
        beq     weapon_boss_next_slot
        clc
        ldy     $0590,x
        lda     $D4DF,y
        adc     $06E1
        tay
        sec
        lda     $0461
        sbc     $06E0,x
        bcs     weapon_boss_check_x_range
        eor     #$FF
        adc     #$01
weapon_boss_check_x_range:  cmp     $D4E4,y
        bcs     weapon_boss_next_slot
        sec
        lda     $04A1
        sbc     ent_y_px,x
        bcs     weapon_boss_check_y_range
        eor     #$FF
        adc     #$01
weapon_boss_check_y_range:  cmp     $D584,y
        bcc     weapon_boss_hit_dispatch
weapon_boss_next_slot:  dex
        dex
        cpx     #$02
        bcs     weapon_boss_check_slot
        ldx     current_entity_slot
        lda     #$00
        sta     $B4
        sta     temp_02
weapon_boss_no_hit:  clc
        rts


; =============================================================================
; Weapon Hit Dispatch — route to weapon-specific damage handler ($A5EE)
; =============================================================================
weapon_boss_hit_dispatch:  lda     $B4  ; check already-hit flag
        bne     weapon_boss_no_hit
        ldy     current_weapon
        lda     weapon_handler_ptr_lo,y
        sta     jump_ptr
        lda     weapon_handler_ptr_hi,y
        sta     jump_ptr_hi
        jmp     (jump_ptr)

        .byte   $AD
        and     (temp_04,x)
        and     #$08
        bne     buster_deflect
        ldy     $B3
        lda     weapon_base_damage_table,y
        sta     temp_00
        beq     buster_deflect
        php
        lsr     ent_flags,x
        plp
        bpl     buster_apply_damage
        jmp     weapon_force_kill_boss


; =============================================================================
; Weapon Damage: Mega Buster — standard pellet damage to boss ($A61B)
; =============================================================================
buster_apply_damage:  jsr     weapon_difficulty_scale
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     temp_02
        inc     $B4
        sec
        lda     $06C1
        sbc     temp_00
        sta     $06C1
        beq     buster_boss_killed
        bcs     buster_deflect_done
buster_boss_killed:  lda     #$00
        sta     $06C1
        sec
        rts

buster_deflect:  lda     ent_flags,x
        eor     #$40
        and     #$FE
        sta     ent_flags,x
        lda     #$05
        sta     ent_y_vel,x
        sta     ent_x_vel,x
        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     temp_02
buster_deflect_done:  clc
        rts

        lda     $B3
        cmp     #$00
        bne     *+5
        jmp     weapon_force_kill_boss

        lda     $0421
        and     #$08
        bne     metal_blade_deflect
        ldy     $B3
        lda     weapon_metal_damage_table,y
        beq     metal_blade_deflect
        lda     ent_state,x
        cmp     #$02
        bcc     metal_blade_base_damage
        beq     metal_blade_triple_damage
        lda     weapon_metal_damage_table,y
        bne     metal_blade_store_damage
metal_blade_triple_damage:  clc
        lda     weapon_base_damage_table,y
        asl     a
        adc     weapon_base_damage_table,y
        jmp     metal_blade_store_damage

metal_blade_base_damage:  lda     weapon_base_damage_table,y


; =============================================================================
; Weapon Damage: Metal Blade — variable damage based on boss ($A68D)
; =============================================================================
metal_blade_store_damage:  sta     temp_00
        beq     metal_blade_deflect
        bpl     metal_blade_apply
        jmp     weapon_force_kill_boss

metal_blade_apply:  jsr     weapon_difficulty_scale
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     temp_02
        inc     $B4
        sec
        lda     $06C1
        sbc     temp_00
        sta     $06C1
        beq     metal_blade_killed
        bcs     metal_blade_clear_hit
metal_blade_killed:  lda     #$00
        sta     $06C1
        sec
        rts

metal_blade_deflect:  lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     temp_02
        lsr     ent_flags,x
        jmp     metal_blade_done

metal_blade_clear_hit:  lda     #$00
        sta     ent_flags,x
metal_blade_done:  clc
        rts

        lda     $0421
        and     #$08
        bne     *+50
        ldy     $B3
        lda     $A95E,y
        sta     temp_00
        beq     *+41
        bpl     *+5
        jmp     weapon_force_kill_boss
        jsr     weapon_difficulty_scale
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     temp_02
        inc     $B4
        sec
        lda     $06C1
        sbc     temp_00
        sta     $06C1
        beq     air_shooter_killed
        bcs     metal_blade_clear_hit
air_shooter_killed:  lda     #$00
        sta     $06C1
        sec
        rts

        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     temp_02
        lda     ent_flags,x
        and     #$FE
        sta     ent_flags,x
        lda     #ENTITY_KAMINARI_CHILD
        sta     ent_type,x
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        clc
        rts

        lda     $0421
        and     #$08
        bne     *+50
        ldy     $B3
        lda     $A96C,y
        sta     temp_00
        beq     *+41
        bpl     *+5
        jmp     weapon_force_kill_boss
        jsr     weapon_difficulty_scale
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     temp_02
        inc     $B4
        sec
        lda     $06C1
        sbc     temp_00
        sta     $06C1
        beq     air_shooter_killed_2
        bcs     air_shooter_clear_hit
air_shooter_killed_2:  lda     #$00
        sta     $06C1
        sec
        rts

        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     temp_02
        lda     ent_flags,x
        and     #$F2
        sta     ent_flags,x
        lda     #ENTITY_EGG_HATCH
        sta     ent_type,x
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        sta     ent_state,x
        sta     ent_hp,x
air_shooter_done:  clc
        rts

air_shooter_clear_hit:  lda     #$00
        sta     ent_flags,x
        beq     air_shooter_done
        lda     $0421
        and     #$08
        bne     leaf_shield_deflect
        ldy     $B3
        lda     weapon_leaf_damage_table,y
        sta     temp_00
        beq     leaf_shield_deflect
        bpl     leaf_shield_apply
        jmp     weapon_force_kill_boss

leaf_shield_apply:  jsr     weapon_difficulty_scale
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     temp_02
        inc     $B4
        sec
        lda     $06C1
        sbc     temp_00
        sta     $06C1
        beq     leaf_shield_killed
        bcs     air_shooter_clear_hit
leaf_shield_killed:  lda     #$00
        sta     $06C1
        sec
        rts

leaf_shield_deflect:  lda     #$00
        sta     ent_x_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_y_vel_sub,x
        lda     #$04
        sta     ent_y_vel,x
        lda     #$80
        sta     ent_flags,x
        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     temp_02
        clc
        rts

        lda     $0421
        and     #$08
        bne     crash_bomber_deflect
        ldy     $B3
        lda     $A988,y
        sta     temp_00
        beq     crash_bomber_deflect
        bpl     crash_bomber_apply
        jmp     weapon_force_kill_boss

crash_bomber_apply:  jsr     weapon_difficulty_scale
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     temp_02
        inc     $B4
        sec
        lda     $06C1
        sbc     temp_00
        sta     $06C1
        beq     crash_bomber_killed
        bcs     crash_bomber_clear_hit
crash_bomber_killed:  lda     #$00
        sta     $06C1
        sec
        rts

crash_bomber_deflect:  lda     #ENTITY_COPIPI
        sta     ent_type,x
        lda     ent_flags,x
        and     #$C0
        eor     #$40
        ora     #$04
        sta     ent_flags,x
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        sta     ent_x_vel,x
        sta     ent_y_vel_sub,x
        lda     #$C0
        sta     ent_x_vel_sub,x
        lda     #$04
        sta     ent_y_vel,x
        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     temp_02
crash_bomber_restore_x:  ldx     current_entity_slot
        clc
        rts

crash_bomber_clear_hit:  lda     #$00
        sta     ent_flags,x
        beq     crash_bomber_restore_x
        lda     $0421
        and     #$08
        bne     quick_boomerang_deflect
        ldy     $B3
        lda     weapon_quick_damage_table,y
        sta     temp_00
        beq     quick_boomerang_deflect
        bpl     quick_boomerang_apply
        jmp     weapon_force_kill_boss

quick_boomerang_apply:  jsr     weapon_difficulty_scale
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     temp_02
        inc     $B4
        sec
        lda     $06C1
        sbc     temp_00
        sta     $06C1
        beq     quick_boomerang_killed
        bcs     crash_bomber_clear_hit
quick_boomerang_killed:  lda     #$00
        sta     $06C1
        sec
        rts

quick_boomerang_deflect:  lda     ent_type,x
        cmp     #$2F
        beq     quick_boomerang_done
        lda     ent_state,x
        cmp     #$02
        beq     quick_boomerang_done
        lda     #$05
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_anim_frame,x
        lda     #$38
        sta     ent_hp,x
        inc     ent_state,x
        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$01
        sta     temp_02
quick_boomerang_done:  clc
        rts

        lda     $0421
        and     #$08
        bne     *+50
        ldy     $B3
        lda     $A9A4,y
        sta     temp_00
        beq     *+41
        bpl     *+5
        jmp     weapon_force_kill_boss
        jsr     weapon_difficulty_scale
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     #$01
        sta     temp_02
        inc     $B4
        sec
        lda     $06C1
        sbc     temp_00
        sta     $06C1
        beq     atomic_fire_killed
        bcs     atomic_fire_clear_hit
atomic_fire_killed:  lda     #$00
        sta     $06C1
        sec
        rts

        lda     #$03
        sta     ent_y_vel,x
        lda     #$B2
        sta     ent_y_vel_sub,x
        lda     #$01
        sta     ent_x_vel,x
        lda     #$87
        sta     ent_x_vel_sub,x
        lda     ent_flags,x
        and     #$F0
        sta     ent_flags,x
        lda     #$2D
        jsr     bank_switch_enqueue
        lda     #$02
        sta     temp_02
atomic_fire_done:  clc
        rts

atomic_fire_clear_hit:  lda     #$00
        sta     ent_flags,x
        beq     atomic_fire_done


; =============================================================================
; Force Kill Boss — instant-kill for weakness weapons (max HP loss) ($A91B)
; =============================================================================
weapon_force_kill_boss:  lda     #MAX_HP   ; set HP to max (instant kill)
        sta     $06C1
        lda     #$00
        sta     temp_02
        lsr     ent_flags,x
        clc
        rts

weapon_difficulty_scale:  lda     $CB   ; difficulty flag: 0=Normal, 1=Difficult
        bne     weapon_difficulty_rts ; Difficult: use base damage as-is
        asl     temp_00              ; Normal: double weapon damage to bosses
weapon_difficulty_rts:  rts


; =============================================================================
; Weapon Damage Tables — per-weapon and per-boss damage values ($A930)
; =============================================================================
weapon_handler_ptr_lo:  .byte   $01,$5A,$CE,$25,$89,$E0,$1B,$B6
        .byte   $54
weapon_handler_ptr_hi:  .byte   $A6,$A6
        .byte   $A6,$A7
        .byte   $A7,$A7,$A9,$A8,$A8
weapon_base_damage_table:  .byte   $02,$02,$01,$01,$02,$02,$01,$01
        .byte   $01,$00,$01,$00,$01,$FF
weapon_metal_damage_table:  .byte   $FF,$06,$0E,$00,$0A,$06,$04,$06
        .byte   $08,$00,$08,$00,$0E,$FF,$02,$00
        .byte   $04,$00,$02,$00,$00,$0A,$00,$00
        .byte   $00,$00,$01,$FF,$00,$08,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF
weapon_leaf_damage_table:  .byte   $06,$00,$00,$FF,$00,$02,$00,$01
        .byte   $00,$00
        .byte   $01,$00
        .byte   $00
        .byte   $01,$02,$02,$00,$02,$00,$00,$04
        .byte   $01,$01,$00,$02,$00,$01,$FF
weapon_quick_damage_table:  .byte   $FF,$00,$02,$02,$04,$03,$00,$00
        .byte   $01,$00,$01,$00,$04,$FF
        .byte   $01,$00
        .byte   $02,$04,$00,$04
        .byte   $0E,$00,$00
        .byte   $00
        .byte   $00
        .byte   $00,$01,$FF


; =============================================================================
; Boss Contact Damage — damage dealt to player on touch per boss ($A9B2)
; =============================================================================
boss_contact_damage_table:  .byte   $08
        .byte   $08
        .byte   $08
        .byte   $04,$04,$04,$06,$04,$1C,$08,$04
        .byte   $08,$0A,$14


; =============================================================================
; Guts-Dozer Nametable Data — PPU addresses and tile data for arena ($A9C0)
; =============================================================================
gutsdozer_nt_addr_hi_table:  .byte   $20,$20,$20
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
gutsdozer_nt_addr_lo_table:  .byte   $C7,$E6,$EE,$06,$26,$44,$64,$85
        .byte   $A5,$C5,$E6
gutsdozer_nt_length_table:  .byte   $03,$05,$02,$0A,$0A,$0D,$0F,$0E
        .byte   $0E,$0F,$0E
gutsdozer_nt_tile_data:  .byte   $00,$00,$00,$00,$00,$00,$83,$84
        .byte   $85,$86,$87,$88,$89,$8A,$8B,$8C
        .byte   $8D,$8D,$8D,$8E,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$8F,$90,$91,$92
        .byte   $93,$94,$95,$96,$97,$98
        .byte   $98
        .byte   $99,$9A,$9B
        .byte   $00
        .byte   $00,$9C,$9D,$9E,$9F,$A0,$A1,$A2
        .byte   $A3,$A2,$A3,$A2,$A3,$A2,$A3,$A2
        .byte   $A3,$A2,$A4,$A5,$A6,$A7,$00,$A8
        .byte   $A9,$AA,$AB,$AC,$AD,$AE,$AF,$AE
        .byte   $AF,$AE,$AF,$AE,$AF,$AE,$AF,$AE
        .byte   $B0,$B1,$B2,$B3,$B4,$B5,$B6,$B7
        .byte   $B8
        .byte   $B9,$BA,$BB
        .byte   $BC,$BD,$BA
        .byte   $BB
        .byte   $BC,$BD,$BA
        .byte   $BB
        .byte   $BC,$BD,$BA
        .byte   $BB
        .byte   $BC,$BE,$BF
        .byte   $C0,$C1
        .byte   $C2,$C3,$C4,$C5,$C6,$C7,$C8,$C5
        .byte   $C6,$C7,$C8,$C5,$C6,$C7,$C8,$C5
        .byte   $C6,$C7,$C9,$CA,$CB,$CC,$CD,$CE
        .byte   $CF,$D0,$D1,$D2,$D3,$D0,$D1,$D2
        .byte   $D3,$D0,$D1,$D2,$D3,$D0,$D1,$D2
        .byte   $D4,$D5,$D6,$D7,$D8,$D9,$DA,$DB
        .byte   $DC,$DD,$DE,$DF,$DC,$DD,$DE,$DF
        .byte   $DC,$DD,$DE,$DF,$DC,$DD,$E0,$E1
gutsdozer_attr_data:  .byte   $FF,$3F,$0F,$FF,$FF,$FF,$FF,$33
        .byte   $44,$FD,$FF,$FF,$FF,$7F,$D0,$FF
        .byte   $FF,$FF,$FF,$F7,$F5,$FF,$FF,$FF
        .byte   $AF
        .byte   $AA
        .byte   $AA
        .byte   $AA
        .byte   $AA
        .byte   $AA
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$21,$21,$21,$21,$21,$21,$21
        .byte   $21,$21,$20,$10,$12,$05,$13,$13
        .byte   $20,$20,$13,$14,$01,$12,$14,$20
        .byte   $21,$21,$21,$21,$21,$21,$21
        .byte   $21,$21
        .byte   $20,$20,$20
        .byte   $20,$20,$22
        .byte   $23,$23,$23,$23,$24,$20,$20,$22
        .byte   $23,$23,$23,$23,$24,$20,$20,$22
        .byte   $23,$23,$23,$23,$24,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$25
        .byte   $30,$31,$32,$33,$2B,$20,$20
        .byte   $25,$40
        .byte   $41,$42
        .byte   $43,$2B,$20,$20,$25,$50,$51,$52
        .byte   $53,$2B,$20,$20,$20,$20,$20,$2C
        .byte   $2C,$2C,$2C,$2C,$26,$34,$35,$36
        .byte   $37,$2B,$2C,$2C
        .byte   $26,$44
        .byte   $45,$46
        .byte   $47,$2B,$2C,$2C,$26,$54,$55,$56
        .byte   $57,$2B,$2C,$2C,$2C,$2C,$2C,$2D
        .byte   $2D,$2D,$2D,$2D,$27,$38,$39,$3A
        .byte   $3B,$2B,$2D,$2D,$27,$48,$49,$4A
        .byte   $4B,$2B,$2D,$2D,$27,$58,$59,$5A
        .byte   $5B,$2B,$2D,$2D,$2D,$2D,$2D,$20
        .byte   $20,$20,$20,$20,$25,$3C,$3D,$3E
        .byte   $3F,$2B,$20,$20,$25,$4C,$4D,$4E
        .byte   $4F,$2B,$20,$20,$25,$5C,$5D,$5E
        .byte   $5F,$2B,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$28,$29,$29,$29
        .byte   $29,$2A,$20,$20,$28,$29,$29,$29
        .byte   $29,$2A,$20,$20,$28,$29,$29,$29
        .byte   $29,$2A,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$02,$15,$02,$02
        .byte   $0C,$05,$20,$20,$20,$01,$09,$12
        .byte   $20,$20,$20,$20,$11,$15,$09,$03
        .byte   $0B,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$0D
        .byte   $01,$0E,$20,$20,$20,$20,$20,$0D
        .byte   $01,$0E,$20,$20,$20,$20,$20,$0D
        .byte   $01,$0E,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$22,$23,$23,$23
        .byte   $23,$24,$20,$20,$22,$23,$23,$23
        .byte   $23,$24,$20,$20,$22,$23,$23,$23
        .byte   $23,$24,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$25,$60,$61,$62
        .byte   $63,$2B,$20,$20
        .byte   $25,$70
        .byte   $71,$72
        .byte   $73,$2B,$20,$20,$25,$80,$81,$82
        .byte   $83,$2B,$20,$20,$20,$20,$20,$2C
        .byte   $2C,$2C,$2C,$2C,$26,$64,$65,$66
        .byte   $67,$2B,$2C,$2C,$26,$74,$75,$76
        .byte   $77,$2B,$2C,$2C,$26,$84,$85,$86
        .byte   $87,$2B,$2C,$2C,$2C,$2C,$2C,$2D
        .byte   $2D,$2D,$2D,$2D,$27,$68,$69,$6A
        .byte   $6B,$2B,$2D,$2D,$27,$78,$79,$7A
        .byte   $7B,$2B,$2D,$2D,$27,$88,$89,$8A
        .byte   $8B,$2B,$2D,$2D,$2D,$2D,$2D,$20
        .byte   $20,$20,$20,$20,$25,$6C,$6D,$6E
        .byte   $6F,$2B,$20,$20,$25,$7C,$7D,$7E
        .byte   $7F,$2B,$20,$20,$25,$8C,$8D,$8E
        .byte   $8F,$2B,$20,$20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $28
        .byte   $29,$29
        .byte   $29,$29
        .byte   $2A
        .byte   $20,$20,$28
        .byte   $29,$29
        .byte   $29,$29
        .byte   $2A
        .byte   $20,$20,$28
        .byte   $29,$29
        .byte   $29,$29
        .byte   $2A
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$08,$05
        .byte   $01,$14
        .byte   $20,$20,$20
        .byte   $20,$20,$04
        .byte   $1B,$20,$20,$20,$20,$20,$17,$0F
        .byte   $0F,$04,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20
        .byte   $0D,$01,$0E
        .byte   $20,$20,$20
        .byte   $20,$17,$09
        .byte   $0C,$19,$20,$20,$20,$20,$20,$0D
        .byte   $01,$0E,$20,$20,$20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$22
        .byte   $23,$23,$23,$23,$24,$20,$20,$22
        .byte   $23,$23,$23,$23,$24,$20,$20,$22
        .byte   $23,$23,$23,$23,$24,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$25
        .byte   $90,$91,$92,$93,$2B,$20,$20,$25
        .byte   $A0,$A1
        .byte   $A2,$A3
        .byte   $2B,$20,$20,$25,$B0,$B1,$B2,$B3
        .byte   $2B,$20,$20
        .byte   $20,$20,$20
        .byte   $2C,$2C,$2C
        .byte   $2C,$2C,$26
        .byte   $94,$95
        .byte   $96,$97
        .byte   $2B,$2C,$2C,$26,$A4,$A5,$A6,$A7
        .byte   $2B,$2C,$2C,$26,$B4,$B5,$B6,$B7
        .byte   $2B,$2C,$2C,$2C,$2C,$2C,$2D,$2D
        .byte   $2D,$2D,$2D,$27,$98,$99,$9A,$9B
        .byte   $2B,$2D,$2D,$27,$A8,$A9,$AA,$AB
        .byte   $2B,$2D,$2D,$27,$B8,$B9,$BA,$BB
        .byte   $2B,$2D,$2D,$2D,$2D,$2D,$20,$20
        .byte   $20,$20,$20,$25,$9C,$9D,$9E,$9F
        .byte   $2B,$20,$20,$25,$AC,$AD,$AE,$AF
        .byte   $2B,$20,$20,$25,$BC,$BD,$BE,$BF
        .byte   $2B,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$28,$29,$29,$29,$29
        .byte   $2A,$20,$20,$28,$29,$29,$29,$29
        .byte   $2A,$20,$20,$28,$29,$29,$29,$29
        .byte   $2A,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$0D,$05,$14,$01,$0C
        .byte   $20,$20,$20,$06,$0C,$01,$13,$08
        .byte   $20,$20,$20,$03,$12,$01,$13,$08
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$0D,$01
        .byte   $0E,$20,$20,$20,$20,$20,$0D,$01
        .byte   $0E,$20,$20,$20,$20,$20,$0D,$01
        .byte   $0E,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$20,$20
        .byte   $20,$20,$20,$20,$20,$20,$21,$21
        .byte   $21,$21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$21
        .byte   $21,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$00,$00
        .byte   $00
        .byte   $00,$00,$00,$00,$00,$00,$44,$11
        .byte   $00,$00,$CC,$33,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$CC,$33
        .byte   $00,$00,$88,$22,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$CC,$30
        .byte   $00,$00,$00,$33,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$03,$03,$00,$00,$00
        .byte   $00,$00,$03,$04,$04,$00,$00,$00
        .byte   $01,$01,$02,$02,$04,$00,$00,$07
        .byte   $38,$C0,$01,$01,$03,$00,$00,$00
        .byte   $20,$10,$08,$04,$02,$00,$00,$80
        .byte   $C0,$E0,$F0,$F8,$FC,$00,$00,$00
        .byte   $00,$00,$00,$00,$01,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$07,$06,$0C
        .byte   $00,$03,$1F,$FC,$F1,$08,$08,$10
        .byte   $10,$20,$40,$03,$0E,$04,$00,$0E
        .byte   $7F,$FF,$1F,$7E,$F0,$03,$01,$00
        .byte   $00,$00,$E0,$80,$00,$02,$01,$01
        .byte   $C0,$F0,$80,$01,$1E,$FC,$FE,$3E
        .byte   $0F,$07,$03,$00,$00,$00,$00,$00
        .byte   $80,$80,$C0,$C0,$C0,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00
        .byte   $01,$01
        .byte   $03
        .byte   $00
        .byte   $00,$00,$00,$00,$01,$01,$03,$00
        .byte   $00,$40,$C0,$C0,$C0,$C0,$C0,$00
        .byte   $00,$40,$E0,$E0,$E0,$E0,$E0,$03
        .byte   $07,$0F,$0F,$1F,$1F,$3F,$3F,$00
        .byte   $00,$00,$00,$01,$03,$07,$07,$E1
        .byte   $C3,$80,$00,$80,$C1,$C2,$D1,$1E
        .byte   $3C,$7C,$F8,$B8,$D8,$DD,$CE,$C0
        .byte   $03,$0F,$3F,$FF,$FF,$70,$C0,$00
        .byte   $00,$00,$00,$00,$00,$80,$00,$FF
        .byte   $FF,$FF,$FE,$FD,$FB,$FB,$36,$00
        .byte   $00,$00,$00,$01,$03,$03,$06,$60
        .byte   $20,$8E,$07,$C3,$E1,$60,$30
        .byte   $00
        .byte   $00
        .byte   $00,$00,$C0,$E0,$20,$10,$00,$00
        .byte   $00,$80,$E0,$E0,$F0,$F0,$00,$00
        .byte   $00,$80,$60,$20,$37,$13,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$80,$F0,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$03,$07
        .byte   $07,$0F,$0F,$1F,$1F,$3F,$03,$07
        .byte   $07,$0F,$0F,$1F,$1F,$3F,$C0,$C0
        .byte   $C0,$C0,$80,$80,$80,$80,$F0,$F0
        .byte   $F0,$F0,$F0,$F0,$F8,$F8,$6F,$4F
        .byte   $4F,$FF,$7E,$7F,$3F,$3E,$07,$07
        .byte   $07,$03,$80,$80,$C0,$C0,$D1,$D6
        .byte   $A4,$A8,$59,$F3,$E7,$E7,$CE,$C8
        .byte   $98,$90,$21,$03,$07,$07,$0E,$3F
        .byte   $7F,$FF,$FF,$FF,$FF,$FE,$0E,$3F
        .byte   $7F,$FF,$FF,$FF,$FF,$FE,$16,$16
        .byte   $86,$A6,$B6,$73,$6B,$ED,$06,$06
        .byte   $86,$86,$86,$03,$03,$01,$30,$30
        .byte   $30,$31,$31,$61,$E3,$C3,$10,$10
        .byte   $10,$10,$10,$20,$E0,$C0,$F8,$F8
        .byte   $FC,$FC,$FC,$FC,$FC,$F8,$19,$18
        .byte   $1C,$1C,$1C,$3C,$3C,$39,$00,$00
        .byte   $00,$20,$00,$00,$01,$83,$FE,$FF
        .byte   $FF,$CE,$CC,$FC
        .byte   $F9,$33,$00
        .byte   $00
        .byte   $06,$1E
        .byte   $7F
        .byte   $FF
        .byte   $FF,$FF,$00,$80,$C6,$1E,$71,$C0
        .byte   $80,$80,$3F,$1F,$8F,$86,$40
        .byte   $A0,$D8
        .byte   $E0,$3F
        .byte   $3F,$BF,$DF,$67,$B0,$DF,$E7,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$F8
        .byte   $F8,$F8,$F0,$E8,$1C,$FA,$F6,$00
        .byte   $00,$00,$00,$00,$06,$07,$07,$00
        .byte   $00,$00,$00,$00,$06,$07,$07,$00
        .byte   $00,$00,$00,$00,$00,$00,$C0,$00
        .byte   $00,$00,$00,$00,$00,$00,$C0,$0E
        .byte   $02,$00,$38,$3C,$3E,$38,$18,$70
        .byte   $44,$02,$38,$3C,$3E,$38,$18,$CF
        .byte   $CF,$0F,$1F,$11,$10,$10,$40,$0F
        .byte   $0F,$0F,$1F,$11,$10,$10,$00
        .byte   $FE,$FD,$FD
        .byte   $FB,$F7,$EA,$D0,$20,$FE,$FC,$FC
        .byte   $F8,$F0,$E4,$CC,$18,$C0,$C0,$80
        .byte   $80,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$07,$07,$0F
        .byte   $0F,$1F,$1F,$3F,$3F,$00,$00,$00
        .byte   $01,$01,$03,$03,$07,$F8,$F8,$F0
        .byte   $F2,$E0,$C0,$80,$00
        .byte   $79,$FB,$F2
        .byte   $F4,$E4,$CF,$8F,$1F,$07,$07,$2F
        .byte   $0F,$5F,$1F,$3F,$3F,$07,$06,$2E
        .byte   $0C,$5C,$1C,$3C,$3F,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$01,$07,$0F
        .byte   $1F,$3F,$7F,$FF,$FF,$F8,$FC,$FC
        .byte   $FC,$FC,$F8,$F8,$F8,$F8,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$C0,$E0
        .byte   $E0,$E0,$C0,$00,$00,$0F,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$80
        .byte   $80,$C0,$C0,$C0,$C0,$03,$03,$03
        .byte   $03,$01,$01,$01,$01,$03,$03,$03
        .byte   $03,$01,$01
chr_data_B4BE:  .byte   $01,$01
        .byte   $F0,$FC
        .byte   $FE,$F9,$F6
        .byte   $E8
        .byte   $DC,$BE,$F0,$FC,$FE,$F8,$F0,$E0
        .byte   $C4,$8E,$18,$0C,$00,$C3,$00,$00
        .byte   $00,$00,$18,$0C,$00,$1C,$1F,$0F
        .byte   $03,$00,$70,$5F,$8E,$00,$01,$04
        .byte   $10,$00,$00,$20,$71,$FF,$FE,$F8
        .byte   $E0,$00,$C0,$80,$00,$00,$00,$00
        .byte   $00,$00,$30,$60,$C0,$80,$00,$00
        .byte   $00,$00,$00,$00,$01,$03,$07,$00
        .byte   $03,$0F,$00,$00,$00,$00,$01,$00
        .byte   $00,$00,$7E,$FC,$F8,$F0,$C0,$03
        .byte   $C7,$F7,$0E,$1C,$38,$F1,$C0,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$E0
        .byte   $F0,$F8,$3E,$7E,$FC,$FC,$18,$00
        .byte   $00,$00,$1F,$1F,$1F,$0F,$0F,$07
        .byte   $03,$01,$3F,$7F,$7F,$7F,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FE,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$F8,$F0,$F0,$E0,$C0,$80
        .byte   $00,$03,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FC,$F3,$00,$00,$00,$00,$00,$00
        .byte   $FE,$FF,$FF,$FF,$FF,$FF,$FF,$01
        .byte   $FE,$FF,$1E,$1E,$1E,$1C,$19,$01
        .byte   $00,$00,$C1,$C3,$D7,$DF,$9F,$9F
        .byte   $01,$00,$80,$E0,$F0,$F0,$F2,$F3
        .byte   $67,$0F,$00,$00,$00,$1C,$BC,$FC
        .byte   $F8,$7C,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $80,$C0,$BF,$7F,$7E,$FE,$FE,$FC
        .byte   $FC,$F8,$9F,$1F,$0E,$0E,$1E,$3C
        .byte   $7C,$78,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$1E,$38,$30,$71,$63,$67
        .byte   $2F,$3E,$01,$07,$0F,$0E,$1C,$18
        .byte   $10,$01,$39,$0C,$07,$F7,$FF,$9F
        .byte   $0F,$3F,$C0,$F0,$F8,$08,$00,$60
        .byte   $F0,$C0,$FC,$FE,$FE,$FF,$FF,$FF
        .byte   $FF,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$3C,$1F,$8F
        .byte   $8F,$87,$FF,$FF,$03,$7C,$3F,$3F
        .byte   $1F,$1F,$38,$00,$00,$00,$C1,$F9
        .byte   $FE,$FE,$FF,$FF,$FF,$3E,$C5,$F9
        .byte   $FE,$FF,$0E,$39,$67,$DF,$BF,$7F
        .byte   $FF,$3F,$CE,$B8,$60,$C0,$80,$00
        .byte   $00,$00,$01,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$01,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$80,$80,$C0,$C0
        .byte   $C0,$E0,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$1F,$0E,$01,$07,$07,$07
        .byte   $03,$00,$3F,$1F,$0E,$0C,$0E,$0F
        .byte   $0F,$0F,$00,$40,$E0,$E0,$E0,$C0
        .byte   $00,$40,$C0,$A0,$00,$00,$00,$A0
        .byte   $E0,$A0,$F8,$F8,$F8,$F8,$FC,$7C
        .byte   $7E,$7F,$F8,$F8,$F8,$F8,$FC,$7C
        .byte   $7E,$7F,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$01,$01,$03,$02,$02,$03
        .byte   $01,$01,$00,$00,$00,$01,$01,$00
        .byte   $00,$00,$9C,$DC,$7C,$7C,$7D,$7D
        .byte   $3D,$BD,$03,$03,$83,$83,$82,$82
        .byte   $C2,$42,$3F,$7F,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$C0,$80,$00,$00,$00,$00
        .byte   $00,$00,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$87,$87,$87,$87,$83,$03
        .byte   $01,$00,$1F,$1F,$1F,$1F,$1F,$1F
        .byte   $1F,$3F,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$8F,$C3,$F1,$F0,$F8,$FC
        .byte   $FE,$FF,$C0,$F0,$FC,$FE,$FE,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$7F,$3F
        .byte   $1F,$1F,$00,$00,$00,$00,$00,$00
        .byte   $80,$C0,$E0,$E0,$F0,$F0,$F0,$F0
        .byte   $F0,$F0,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$07,$0F,$0F,$07,$20,$38
        .byte   $7E,$3C,$0C,$1C
        .byte   $1E,$3F,$7F
        .byte   $77,$F0,$FA,$C0,$C0,$80,$00,$00
        .byte   $00,$00,$00,$00,$00,$40,$80,$80
        .byte   $00,$00,$00,$3F,$3F,$1F,$0F,$07
        .byte   $03,$00,$00,$3F,$3F,$1F,$0F,$07
        .byte   $03,$00,$00,$00,$80,$80,$80,$80
        .byte   $81,$86,$0C,$00,$8C,$8F,$9F,$9F
        .byte   $BF,$BE,$3C,$00,$00,$00,$03,$3C
        .byte   $C0,$00,$00,$00,$03,$0F,$FF,$FC
        .byte   $C0,$00
        .byte   $00
        .byte   $00,$01,$01,$F1,$00,$00,$00,$00
        .byte   $E0,$F0,$F0,$F8,$08,$08,$0C,$0E
        .byte   $FF,$7F,$FF,$FF,$FF,$FF,$7F,$3F
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $FE,$FE,$FE,$FC,$FC,$F8,$F8,$F0
        .byte   $00,$00,$00,$00,$00,$00,$00,$01
        .byte   $00,$00,$00,$00,$00,$00,$00,$01
        .byte   $3F,$3F,$7F,$7F,$7F,$FF,$FF,$FF
        .byte   $1F,$01,$01,$3C,$0E,$E7,$31,$85
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FC,$E0,$7C,$FE,$FF,$FE
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $0F,$87,$07,$03,$03
chr_data_B805:  .byte   $81,$81
        .byte   $01,$C0
        .byte   $E0,$F0
        .byte   $F0,$F8
        .byte   $F8
        .byte   $F8
        .byte   $FC,$F0,$F0,$F0,$F0,$F0,$E0,$E0
        .byte   $E0,$07,$07,$07,$07,$07,$0F,$0F
        .byte   $0F,$00,$00,$00,$31,$36,$76,$71
        .byte   $17,$00,$FF,$FF,$71,$76,$76,$71
        .byte   $17,$00,$00,$00,$DF,$84,$D7,$D7
        .byte   $D4,$FF,$FF,$F3,$DF
        .byte   $84,$D7
        .byte   $D7,$D4,$00,$00,$00,$C0,$20,$B0
        .byte   $78,$B8,$C0,$E0,$F0,$F0,$38,$B8
        .byte   $7C,$BC,$0C,$18,$18,$18,$18,$18
        .byte   $18,$18,$7C,$78,$78,$F8,$F8,$F8
        .byte   $F8,$F8,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$0F,$0F,$0F,$07,$07,$07
        .byte   $07,$03,$1F,$0F,$03,$00,$00,$00
        .byte   $00,$00,$00,$00,$80
chr_data_B88B:  .byte   $C0,$E0
        .byte   $F0,$FC
        .byte   $FF,$FF,$FF,$FF,$7E,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$E0,$C0,$80,$00,$03,$7F,$7F
        .byte   $7F,$01,$03,$07,$0F,$3F,$7F,$7F
        .byte   $7F,$00,$00,$00,$01,$03,$01,$00
        .byte   $80,$F3,$E0,$E0,$C0,$C0,$80,$80
        .byte   $E0,$FC
        .byte   $7E,$0F,$01
        .byte   $C0,$F0
        .byte   $7C,$1E,$FF,$FF,$7F,$1F,$07,$01
        .byte   $00,$00,$F0,$00,$80,$FC,$8A,$00
        .byte   $00,$20,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $7F,$3F,$01,$01,$01,$01,$01,$03
        .byte   $02,$04,$FC,$FC,$FC,$F8,$F8,$F0
        .byte   $F0,$E0,$C1,$C1,$C3,$83,$07,$0F
        .byte   $1F,$3F,$1F,$1E,$1C,$3C,$78,$FF
        .byte   $F0,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$00,$00,$00,$FF
        .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$00,$00,$00,$FF
        .byte   $00,$FF,$F8,$F8,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FE,$0E,$06,$07,$07,$FF
        .byte   $07,$FF,$18,$0C,$0C,$06,$06,$03
        .byte   $01,$00,$F8,$FC,$FC,$FE,$7E,$7F
        .byte   $3F,$3F,$00,$00,$00,$00,$00,$00
        .byte   $80,$FF,$00,$00,$00,$00,$00,$00
        .byte   $80,$FF,$00,$00,$00,$00,$01,$07
        .byte   $7F,$F8,$03,$03,$01,$00
        .byte   $01,$07
        .byte   $7F,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FC,$F0,$00,$00,$00,$03,$07,$0F
        .byte   $1F,$3F,$F8,$F8,$F0,$E0,$80,$00
        .byte   $00,$00,$3F,$1F,$0F,$03,$80,$C0
        .byte   $E0,$E8,$3F,$1F,$0F,$03,$00,$00
        .byte   $00,$08,$C8,$F6,$F7,$F9,$FC,$00
        .byte   $00,$00,$F8,$FE,$FF,$FF,$FF,$3F
        .byte   $03,$00,$06,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$80,$F0,$FF,$FF
        .byte   $FE,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$3F,$7F,$7F,$FF,$FC,$E0
        .byte   $00,$01,$00,$00,$01,$07,$0F,$1F
        .byte   $3F,$FF,$E1,$C3,$87,$0F,$1F,$3F
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FC,$F8,$F8,$F8,$F8,$F0
        .byte   $E0,$80,$FF,$0F,$FF,$FF,$FF,$FF
        .byte   $FE,$FE,$00,$00,$00,$00,$00,$01
        .byte   $00,$00,$1F,$0F,$07,$01,$00,$00
        .byte   $00,$00,$7F,$00,$00,$00,$00,$C0
        .byte   $FF,$00,$FF,$FF,$FF,$FF,$00,$00
        .byte   $00,$00,$80,$00,$00,$00,$01,$0F
        .byte   $FF,$00,$FF,$FE,$F0,$00,$00,$00
        .byte   $00,$00,$00,$01,$07,$3F,$FF,$FF
        .byte   $FF,$00,$C0,$00,$00,$00,$00,$00
        .byte   $00,$00,$FF,$FF,$FF,$FE,$FC,$F8
        .byte   $F0,$00,$00,$00,$00,$00,$00,$00
        .byte   $02,$00,$C0,$90,$00,$18,$C0,$1A
        .byte   $00,$00,$02,$10,$01,$00
        .byte   $C0,$02
        .byte   $80,$00,$00,$00,$10,$00
        .byte   $39,$02,$38
        .byte   $00
        .byte   $0C,$00,$7A,$00,$29,$82,$A9,$00
        .byte   $00,$00,$98,$90,$00
        .byte   $30,$20
        .byte   $00
        .byte   $00,$00,$C6,$CA,$80,$0C,$94,$00
        .byte   $00,$1F,$1F,$00,$00,$00,$00,$00
        .byte   $07,$1F,$1F,$3F,$3F,$7F,$FF,$00
        .byte   $00,$FF,$FF,$00,$00,$00,$00
chr_data_BA87:  .byte   $00,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $00,$00,$FF,$FF,$00,$00,$00,$01
        .byte   $07,$FF,$FF,$FF,$FF,$FC,$F1,$C7
        .byte   $3F,$01,$DC,$9F,$3F,$77,$E7,$FF
        .byte   $FF,$E1,$DC,$BF,$7F,$E7,$E7,$FF
        .byte   $FF,$00,$00,$80,$E0,$B8,$3C,$FE
        .byte   $FF,$FE,$7C,$9C,$E0,$38
chr_data_BABD:  .byte   $3C,$FE,$FF,$00,$00,$7F,$00,$0F
        .byte   $08,$08,$08,$7F,$FF,$FF,$7F,$3F
        .byte   $1E,$1E,$1E,$00,$00,$FF,$00,$FF
        .byte   $61,$61,$61,$FF,$FF,$FF,$FF,$FF
        .byte   $79,$79,$79,$00,$00,$FF,$00,$FF
        .byte   $86,$86,$86,$FF,$FF,$FF,$FF,$FF
        .byte   $E7,$E7,$E7,$00,$00,$FF,$00,$FF
        .byte   $18,$18,$18,$FF,$FF,$FF,$FF,$FF
        .byte   $9E,$9E,$9E,$00,$00,$80,$00,$F0
        .byte   $78,$78,$78,$FF,$FF,$FF,$FF,$FF
        .byte   $7F,$7F,$7F,$00,$00,$FF,$FF,$FF
        .byte   $E7,$F3,$E3,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$E7,$E7,$00,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$00,$FF,$FF,$FF
        .byte   $E7,$F3,$E3,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$E7,$E7,$1E,$70,$C1,$8F,$3F
        .byte   $7F,$3F,$0F,$FE,$F1,$CF,$BF,$7E
        .byte   $7F,$7F,$3F,$00,$00,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$FF,$FF,$01,$03
        .byte   $FF,$FF,$FF,$00,$00,$FE,$FE,$FF
        .byte   $FF,$FF,$FF,$00,$FE,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$00,$00,$78,$7C,$3E
        .byte   $3E,$3F,$3F,$00,$F8,$04,$02,$81
        .byte   $81,$80,$80,$0F,$0F,$00,$00,$1F
        .byte   $3F,$00,$7F,$1F,$1F,$1F,$00,$3F
        .byte   $7F,$7F,$FF,$FF,$FF,$00,$00,$FF
        .byte   $FF,$1F,$81,$FF,$FF,$FF,$00,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$00,$FF
        .byte   $FF,$E0,$CF,$FF,$FF,$FF,$00,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$00,$00,$FF
        .byte   $FF,$00,$FC,$FF,$FF
chr_data_BBBA:  .byte   $FF,$00,$FF,$FF,$FF,$FF,$F8,$F8
        .byte   $00,$00,$FF,$E0,$00,$00,$FF,$FF
        .byte   $FF,$07,$FF,$FF,$FF,$FF,$E7,$FF
        .byte   $FF,$00,$FF,$00,$00,$00,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$00,$FF,$00,$00,$00,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$E7,$FF
        .byte   $FF,$00,$FF,$00,$00,$00,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$01,$00
        .byte   $00,$00,$C0,$00,$00,$00,$4F,$31
        .byte   $8E,$C1,$F0,$FE,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $00,$FF,$00,$00,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$FF,$FF
        .byte   $00,$FF,$00,$00,$FF,$FF,$3E,$00
        .byte   $7C,$00,$01,$03,$0F,$07,$81,$BF
        .byte   $03,$7E,$FD,$03,$FF,$FF,$80,$80
        .byte   $C0
        .byte   $C0,$C0
        .byte   $E0,$E0
        .byte   $E0,$80
        .byte   $80,$C0,$C0,$C0,$E0,$E0,$E0,$7F
        .byte   $67,$73,$73,$43,$67,$7F,$7F,$FF
        .byte   $FF,$C7,$C7,$C7,$FF,$FF,$FF,$00
        .byte   $00,$04,$0E,$0E,$04,$00,$80,$C3
        .byte   $81,$00,$00,$00,$00,$81,$C3,$DF
        .byte   $5C,$5E,$5E,$78,$7C,$7F,$FF,$FF
        .byte   $FF,$F8,$F8,$F8,$FF,$FF,$FF,$FC
        .byte   $FC,$7C,$7C,$7C,$FC,$FC,$FC,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$03,$07,$02,$01,$00,$00
        .byte   $00,$00,$00,$00,$0C,$0C,$1B,$00
        .byte   $3F,$F0,$8F,$7F,$FF,$FF,$FF,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$06,$00
        .byte   $E0,$18,$C6,$E1,$F8,$FC,$F8,$00
        .byte   $00,$00,$00,$05,$85,$80,$45,$00
        .byte   $00,$00,$00,$05,$05,$00,$05,$03
        .byte   $01,$00,$00,$00,$80,$80,$40,$03
        .byte   $01,$00,$00,$00,$00,$00,$00,$E0
        .byte   $F0,$F0,$70,$38,$38,$18,$18,$E0
        .byte   $F0,$F0,$70,$38,$38,$18,$18,$7F
        .byte   $01,$00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00,$FF,$FF,$7F,$03,$01,$01,$01
        .byte   $01,$C1,$FF,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$FF,$FF,$C0,$C0,$80,$80
        .byte   $80,$FC,$00,$00,$00,$00,$00,$00
        .byte   $00,$FE,$FE,$FC,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$37
        .byte   $37,$1B,$37,$37,$37,$37,$37,$00
        .byte   $00,$7F,$38,$13,$06,$04,$05,$ED
        .byte   $EC,$80,$C0,$E0,$F0
        .byte   $E8
        .byte   $E9,$01
        .byte   $00
        .byte   $0E,$1F,$0F,$27,$17,$97,$80,$00
        .byte   $F0,$00
        .byte   $C0,$00
        .byte   $00
        .byte   $80,$97,$17,$40,$25,$20,$20,$20
        .byte   $20,$00,$00,$00,$05,$00,$00,$00
        .byte   $00,$20,$20,$40,$20,$20,$20,$21
        .byte   $21,$01,$01,$00,$01,$01,$01,$00
        .byte   $00,$20,$20,$18,$18,$18,$18,$90
        .byte   $90,$90,$80,$18,$18,$98,$98,$10
        .byte   $10,$10,$00,$40,$2A,$7F,$7F,$00
        .byte   $00,$00,$3F,$00,$00,$00,$00,$7F
        .byte   $3F,$3F,$00,$FE,$FE,$7E,$7E,$7E
        .byte   $7E,$7E,$BE,$FE,$FE
chr_data_BDCA:  .byte   $7E,$7E,$7E
        .byte   $7E,$7E,$3E
        .byte   $2A
        .byte   $3F,$3F,$3F,$00,$00,$00,$1F,$00
        .byte   $00,$00,$00,$3F,$3F,$3F,$00,$AA
        .byte   $FF,$FF,$FF,$00,$00,$00,$FF,$00
        .byte   $00,$00,$00,$FF,$FF,$FF,$00,$A0
        .byte   $E0,$E0,$E0,$0C,$0C,$0E,$EC,$0C
        .byte   $0C,$0C,$0C,$E0,$E0,$E0,$02,$37
        .byte   $37,$37,$1B,$1B,$0D,$0E,$04,$00
        .byte   $00,$00,$00,$00,$00,$00,$03,$F2
        .byte   $F1,$E0,$C0,$80,$00,$00,$00,$04
        .byte   $02,$18,$3F,$7F,$FF,$FF,$7F,$20
        .byte   $C0,$10,$F8,$FC,$FC,$F9,$E1,$07
        .byte   $0F,$0F,$06,$02,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$20
        .byte   $20,$20,$40,$40,$80,$80,$00,$00
        .byte   $00,$00,$00,$01,$01,$01,$00,$21
        .byte   $21,$21,$41,$40,$80,$80,$01,$00
        .byte   $00,$00,$00,$80,$80,$80,$00,$80
        .byte   $80,$80,$80,$00,$00,$00,$00,$1F
        .byte   $1F,$00,$00,$00,$01,$00,$00,$00
        .byte   $00,$0F,$07,$03,$00,$00,$00,$BF
        .byte   $DF,$1F,$0F,$07,$FB,$7C,$1F,$3F
        .byte   $1F,$DF,$EF,$F7,$03,$00,$00,$1F
        .byte   $1F,$00,$80,$80,$C3,$F1,$00,$00
        .byte   $00,$0F,$8F,$87,$C0,$F0,$00,$FF
        .byte   $FF,$00,$00,$00,$FF,$FF,$FF,$00
        .byte   $00,$FF,$FF,$FF,$00,$00,$00,$F0
        .byte   $F0,$00,$03,$01,$FE,$FF,$FF,$06
        .byte   $06,$F3,$F8,$FC,$00,$00,$00,$00
        .byte   $00,$00,$80,$80,$80,$0F,$DF,$03
        .byte   $00,$00,$00,$40,$70,$30,$00,$00
        .byte   $00,$00,$00,$00,$00,$0F,$0F,$8F
        .byte   $F0,$3F,$00,$00,$00,$F0,$F0
        .byte   $C6,$18
        .byte   $E0,$00
        .byte   $00
        .byte   $00,$0F,$0F,$00,$00,$00,$00,$00
        .byte   $00,$F0,$F0,$00,$88,$00,$00,$00
        .byte   $00,$0F,$0F,$00,$88,$00,$00,$00
        .byte   $00,$F0
        .byte   $F0,$00
chr_data_BEF1:  .byte   $80,$00,$00,$00,$00,$0F,$0F,$03
        .byte   $80,$00,$00,$00,$00,$F0
        .byte   $F0,$00
chr_data_BF01:  .byte   $00
        .byte   $00,$0E,$1C,$08,$00,$00,$03,$03
        .byte   $06,$00
        .byte   $00
        .byte   $30,$F0,$C0,$00,$00,$00,$00,$00
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
        .byte   $00
chr_data_BFBE:  .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$78,$EE,$E1,$BF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$00,$00,$E0,$BF
        .byte   $E0,$BF
