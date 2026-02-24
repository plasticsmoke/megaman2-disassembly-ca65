.segment "FIXED"

; =============================================================================
; MEGA MAN 2 (U) — BANK $0F — FIXED BANK ($C000-$FFFF)
; =============================================================================
; This is the fixed code bank for Mega Man 2. Always mapped to $C000-$FFFF.
; Contains:
;   - MMC1 bank switching (5-bit serial writes)
;   - NMI / VBLANK handler (OAM DMA, palette, PPU buffer, scroll)
;   - Controller input reading
;   - PPU update routines (palette upload, nametable column/attribute writes)
;   - Sprite rendering engine (OAM assembly from entity data)
;   - Entity spawning and despawning
;   - Entity movement physics (velocity → position, gravity)
;   - Player-entity collision detection
;   - Weapon-entity collision detection
;   - Boss defeat sequence
;   - Boss intro sequence
;   - Division routines (8-bit and 16-bit)
;   - Item drop RNG
;   - Weapon firing dispatch
;   - CHR-RAM upload support
;   - Damage tables (player→enemy, enemy→player)
;   - Sprite animation data (~$F900-$FFEF)
;   - Reset handler and interrupt vectors
;
; Mapper: MMC1 (mode 3: $C000-$FFFF fixed, $8000-$BFFF switchable)
; PRG layout: 16 × 16KB banks ($00-$0F), bank $0F always present
;
; =============================================================================
; KEY MEMORY MAP
; =============================================================================
;
; Zero Page:
;   $00-$01     General temporaries
;   $04         Game state index
;   $08-$09     Indirect jump pointer (jump_ptr)
;   $1B         PPU buffer entry count
;   $1C         Frame counter (incremented every NMI)
;   $1D         VBLANK done flag (nonzero after NMI processing)
;   $1F         Scroll X position
;   $20         Base nametable select (bit 0)
;   $22         Scroll Y position
;   $23         Player 1 controller state
;   $24         Player 2 controller state
;   $25-$26     Previous controller state (for new-press detection)
;   $27-$28     New button presses this frame
;   $29         Currently switched PRG bank number
;   $2A         Current stage index
;   $2B         Entity loop counter / current entity slot
;   $2C         Weapon select / general game sub-state
;   $2D-$2E     Player screen X position / entity screen X
;   $2F         Off-screen flag
;   $30-$31     Gravity sub-pixel accumulators
;   $36         General timer / counter
;   $3A         Palette dirty flag
;   $3D         Weapon direction offset
;   $3E-$3F     General state variables
;   $42         Scroll direction flags
;   $43-$44     Palette animation index / timer
;   $47         Nametable column update pending count
;   $48-$49     Entity spawn scan pointers (forward)
;   $4A         RNG seed
;   $4B         Invincibility timer (flash frames)
;   $4C-$4D     Entity spawn scan pointers (secondary)
;   $4E         Death/despawn context flag
;   $4F-$50     Scroll lock flags
;   $51         Attribute table update pending count
;   $54         Attribute update sub-mode
;   $55         Active entity count
;   $56+        Active entity slot list
;   $66         Bank switch queue count
;   $67         Bank switch callback pending flag
;   $68         Bank switch in progress flag
;   $69         Bank switch backup (original bank)
;   $9A-$9B     Boss beaten bitmask
;   $9C-$9F     Weapon ammo (various)
;   $A0-$A8     Weapon/item inventory
;   $A9         Current weapon ID
;   $AA         Special game mode flags
;   $AB-$AD     Weapon-specific counters
;   $AE         8×16 sprite size flag
;   $B0         Score/rank index
;   $B1         Boss HP / intro state
;   $B3         Boss stage ID
;   $B6         Camera Y offset (screen shake)
;   $B8-$B9     Camera X offset
;   $BC-$BD     Boss-specific flags
;   $CB         Difficulty flag (normal/difficult)
;   $F7         PPUCTRL shadow
;   $F8         PPUMASK shadow
;   $F9         Boss fight active flag
;   $FB-$FC     Frame skip timer
;   $FD         General counter / column index
;   $FE-$FF     General pointer
;
; Entity Arrays (indexed by X, 16 slots $00-$0F):
;   $0100,x     Collision hit counter
;   $0110,x     Spawn cross-reference (secondary)
;   $0120,x     Despawn marker ($FF = despawned)
;   $0130,x     Secondary entity spawn tracking
;   $0140,x     Secondary entity HP/timer
;   $0160,x     Hitbox Y offset for collision
;   $0400,x     Entity type/ID
;   $0410,x     Enemy type (from spawn data)
;   $0420,x     Entity flags (bit 7=active, 6=facing, 5=priority,
;               4=weapon-collidable, 3=invincible, 2=gravity, 1=weapon, 0=contact)
;   $0430,x     Entity spawn flags / secondary flags
;   $0440,x     Entity X position high byte (screen)
;   $0450,x     Entity spawn X screen
;   $0460,x     Entity X position low byte (pixel)
;   $0470,x     Entity spawn X pixel
;   $0480,x     Entity X sub-pixel
;   $0490,x     Entity spawn X sub-pixel
;   $04A0,x     Entity Y position (pixel)
;   $04B0,x     Entity spawn Y position
;   $04C0,x     Entity Y sub-pixel
;   $04D0,x     Spawn Y sub-pixel
;   $04E0,x     Entity state / AI phase counter
;   $04F0,x     Item drop flag
;   $0590,x     Entity weapon/damage type
;   $059E,x     Hitbox width (for collision)
;   $05A0-$05AA Sound/music control
;   $0600,x     Entity X velocity (whole)
;   $0610,x     Spawn hitbox width
;   $0620,x     Entity X velocity (sub-pixel)
;   $0630,x     Spawn hitbox height mask
;   $0640,x     Entity Y velocity (whole)
;   $0650,x     Spawn hitbox Y mask
;   $0660,x     Entity Y velocity (sub-pixel)
;   $0670,x     Spawn hitbox Y offset
;   $0680,x     Animation frame counter
;   $0690,x     Animation state backup
;   $06A0,x     Animation sequence index
;   $06B0,x     General entity variable
;   $06C0,x     Entity HP / hit points
;   $06D0,x     Entity timer / countdown
;   $06E0,x     Entity screen-relative X position
;   $06F0,x     Entity AI behavior index
;
; RAM Buffers:
;   $0200-$02FF OAM sprite buffer (DMA source for $4014)
;   $0300-$034F PPU nametable update buffer
;   $0350-$0355 PPU buffer tile data
;   $0356-$0375 Palette RAM (32 bytes, uploaded to $3F00)
;   $0376+      Palette animation frames
;   $03B6-$03B7 Column update: VRAM address high/low
;   $03B8-$03D7 Column update: 32 bytes of tile data
;   $057F-$0580 Bank switch queue
;
; Sprite Data Tables ($F900-$FAFF):
;   $F900       Sprite def pointer low (entity type → animation data)
;   $F980       Sprite def pointer low (secondary/weapon sprites)
;   $FA00       Sprite def pointer high (entity type → bank)
;   $FA80       Sprite def pointer high (secondary/weapon sprites)
;   $FB00+      OAM sequence data (sprite tile IDs, attributes, offsets)
;
; =============================================================================

; da65 V2.18 - Ubuntu 2.19-1
; Created:    2026-02-23 18:17:35
; Input file: build/bank0F.bin
; Page:       1


        .setcpu "6502"

; ─── External references (banked addresses) ─────────────────────────────────
jump_ptr           := $0008         ; Indirect jump pointer (zero page)
ppu_nametable_2020 := $2020         ; PPU nametable address $2020
banked_entry       := $8000         ; Standard entry point in switched bank
banked_entry_alt   := $8003         ; Alternate entry point in switched bank
banked_0D_scroll_update := $800C    ; Bank $0D: scroll/camera update
banked_0D_stage_complete := $800F   ; Bank $0D: stage completion handler
banked_0D_boss_init := $8012        ; Bank $0D: boss initialization
banked_0E_boss_defeated := $8072    ; Bank $0E: boss defeated handler
banked_0E_all_beaten := $8076       ; Bank $0E: all robot masters beaten
banked_0E_next_stage := $8079       ; Bank $0E: advance to next stage
banked_0E_boss_timeout := $8088     ; Bank $0E: boss timeout/escape handler
banked_0E_boss_continue := $80AB    ; Bank $0E: boss intro continue
banked_0E_entity_update := $84EE    ; Bank $0E: per-frame entity update
banked_09_scroll_code := $8600      ; Bank $09: scroll column update code
banked_0E_wily_check := $9115       ; Bank $0E: Wily stage check
banked_sound_process := $925B       ; Banked: sound engine process
banked_0B_item_spawn := $AF4C       ; Bank $0B: item/powerup spawn

; =============================================================================
; Bank Switching (MMC1)
; MMC1 requires 5 serial writes to set a register. Each write sends bit 0.
; Writing to $E000-$FFFF sets the PRG bank register.
; =============================================================================
bank_switch:                            ; PRG bank switch — A = bank number ($00-$0E)
        sta     $29                     ; Save requested bank number
        sta     $69                     ; Backup for later restore
        inc     $68                     ; Set "bank switch in progress" flag
        sta     mmc1_scratch            ; MMC1 serial write: bit 0
        lsr     a
        sta     mmc1_scratch            ; bit 1
        lsr     a
        sta     mmc1_scratch            ; bit 2
        lsr     a
        sta     mmc1_scratch            ; bit 3
        lsr     a
        sta     mmc1_scratch            ; bit 4 (5th write commits)
        lda     #$00
        sta     $68                     ; Clear "in progress" flag
        lda     $67                     ; Check if callback pending
        bne     bank_switch_with_callback
        rts

bank_switch_with_callback:  lda     #$0C; Switch to bank $0C (CHR upload?), call banked_entry
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        jsr     banked_entry
bank_switch_process_queue:  ldx     $66 ; Process queued bank switch requests
        beq     bank_switch_queue_done
        lda     $057F,x
        jsr     banked_entry_alt
        dec     $66
        bne     bank_switch_process_queue
bank_switch_queue_done:  lda     #$00   ; Queue empty — restore original bank
        sta     $67
        lda     $69
        jmp     bank_switch

bank_switch_enqueue:  ldy     $66       ; Enqueue a bank switch request (A = bank number)
        cpy     #$10
        bcs     bank_switch_enqueue_rts
        sta     $0580,y
        inc     $66
bank_switch_enqueue_rts:  rts

        sta     $9FFF
        lsr     a
        sta     $9FFF
        lsr     a
        sta     $9FFF
        lsr     a
        sta     $9FFF
        lsr     a
        sta     $9FFF
        rts
        lda     #$0D
        jsr     bank_switch
        jsr     $8006
        lda     #$0E
        jsr     bank_switch
        rts
; =============================================================================
; wait_for_vblank — Wait for VBLANK, read controllers, detect new presses ($C07F)
; =============================================================================
; Saves previous controller state, runs palette animation, waits for NMI to
; complete, then reads controllers and computes newly-pressed buttons.
; Returns with bank $0E switched in.
; Output: $27 = P1 new presses, $28 = P2 new presses
; -----------------------------------------------------------------------------
wait_for_vblank:
        lda     $23                     ; save previous P1 controller state
        sta     $25
        lda     $24                     ; save previous P2 controller state
        sta     $26
        jsr     palette_anim_update     ; run palette cycling animation
        lda     #$00
        sta     $1D                     ; clear VBLANK-done flag
wait_vblank_loop:
        lda     $1D                     ; wait for NMI handler to set flag
        beq     wait_vblank_loop
        jsr     read_controllers        ; read controller hardware
        lda     $23                     ; P1 current state
        eor     $25                     ; XOR with previous = changed bits
        and     $23                     ; AND with current = newly pressed
        sta     $27                     ; store P1 new presses
        lda     $24                     ; P2 current state
        eor     $26                     ; detect changed bits
        and     $24                     ; newly pressed only
        sta     $28                     ; store P2 new presses
        lda     #$0E                    ; switch to game engine bank
        jsr     bank_switch
        rts

; ─── (unreachable code: duplicate wait-for-vblank, returns to bank $0D) ─────
        lda     $23
        sta     $25
        lda     $24
        sta     $26
        jsr     palette_anim_update
        lda     #$00
        sta     $1D
wait_vblank_loop_0D:
        lda     $1D                     ; wait for NMI
        beq     wait_vblank_loop_0D
        jsr     read_controllers        ; read controller hardware
        lda     $23                     ; compute P1 new presses
        eor     $25
        and     $23
        sta     $27
        lda     $24                     ; compute P2 new presses
        eor     $26
        and     $24
        sta     $28
        lda     #$0D                    ; switch to stage engine bank
        jsr     bank_switch
        rts

; =============================================================================
; wait_one_rendering_frame — Enable rendering, wait one VBLANK, restore ($C0D7)
; =============================================================================
; Used during boss defeat to keep screen visible while waiting.
; Preserves controller state across the wait.
; -----------------------------------------------------------------------------
wait_one_rendering_frame:
        lda     $23                     ; save P1 controller state
        pha
        lda     $24                     ; save P2 controller state
        pha
        lda     $27                     ; save new presses
        pha
        lda     #$1E                    ; enable all rendering
        ora     $F8                     ; merge with current PPUMASK shadow
        sta     $F8
        sta     $2001                   ; apply to PPU
        lda     #$00
        sta     $1D                     ; clear VBLANK flag
wait_frame_loop:
        lda     $1D                     ; wait for NMI
        beq     wait_frame_loop
        pla                             ; restore new presses
        sta     $27
        pla
        sta     $24
        pla
        sta     $23
        lda     #$0E
        jsr     bank_switch
        rts

; =============================================================================
; wait_multiple_frames — Wait A frames calling wait_for_vblank in a loop ($C100)
; =============================================================================
wait_multiple_frames:  pha
        jsr     wait_for_vblank
        pla
        sec
        sbc     #$01
        bne     wait_multiple_frames
        rts

; =============================================================================
; boss_death_sequence — Boss defeat sequence — explosions, score, screen fade ($C10B)
; =============================================================================
boss_death_sequence:  lda     #$41
        jsr     bank_switch_enqueue     ; queue sound effect
        lda     #$FF
        jsr     bank_switch_enqueue
        lda     $2C
        bne     boss_death_delay_start
        sta     $36
boss_death_check_type:  and     #$01
        bne     boss_death_run_frame
        lda     $36
        and     #$07
        tax
        ldy     #$01
boss_death_setup_slot:  lda     #$25
        sta     $040E,y
        lda     #$80
        sta     $042E,y
        clc
        lda     $0460
        adc     explosion_offset_x_lo_tbl,x
        sta     $046E,y
        lda     $0440
        adc     explosion_offset_x_hi_tbl,x
        sta     $044E,y
        lda     $04A0
        adc     explosion_offset_y_tbl,x
        sta     $04AE,y
        lda     #$01
        sta     $06AE,y
        lda     #$00
        sta     $062E,y
        sta     $060E,y
        sta     $066E,y
        sta     $064E,y
        sta     $068E,y
        inx
        dey
        bpl     boss_death_setup_slot
boss_death_run_frame:  jsr     run_one_game_frame
        inc     $36
        lda     $36
        cmp     #$10                    ; 16 frames of explosions
        bcc     boss_death_check_type
        lsr     $042E
        lsr     $042F
        jsr     setup_explosion_array   ; spawn final explosion ring
        lda     #$A0
        bne     boss_death_delay_loop
boss_death_delay_start:  lda     #$E0
boss_death_delay_loop:  sta     $36
boss_death_delay_step:  lsr     $0420
        jsr     run_one_game_frame      ; run game frame during delay
        dec     $36
        bne     boss_death_delay_step
        lda     #$10
        sta     $2000
        lda     #$06
        sta     $2001
        lda     $2A
        and     #$07
        jsr     bank_switch
        ldx     #$00
        lda     $0440
boss_death_calc_score:  cmp     $BB07,x
        bcc     boss_death_finish
        inx
        cpx     #$05
        bne     boss_death_calc_score
boss_death_finish:  stx     $B0
        ldx     #$FF
        txs
        lda     #$0E                    ; switch to game engine bank
        jsr     bank_switch             ; switch to game engine bank
        dec     $A8
        bne     boss_death_to_0E_2
        lda     #$00
        sta     $A7
        lda     #$0D
        jsr     bank_switch
        jsr     banked_0D_scroll_update
        lda     #$0E
        jsr     bank_switch
        lda     $FD
        bne     boss_death_to_0E_1
        jmp     banked_0E_boss_timeout

boss_death_to_0E_1:  jmp     banked_0E_boss_defeated

boss_death_to_0E_2:  jmp     banked_0E_boss_continue

explosion_offset_y_tbl:  .byte   $F8,$08,$FB,$05,$00,$00,$05,$FB ; Y offsets for boss explosion pattern
explosion_offset_x_lo_tbl:  .byte   $00,$00,$FB,$05,$FB,$08,$FB,$05 ; X offsets (low) for explosion pattern
explosion_offset_x_hi_tbl:  .byte   $00,$00,$FF,$00,$FF,$00,$FF,$00 ; X offsets (high) for explosion pattern

; =============================================================================
; boss_intro_sequence — Boss intro — health bar fill and Wily fortress check ($C1F0)
; =============================================================================
boss_intro_sequence:  jsr     reset_sound_state ; silence music for intro
        inc     $BD
boss_intro_loop:  jsr     boss_fight_frame
        lda     $2A
        cmp     #$08
        bne     boss_intro_done
        lda     $37
        cmp     #$03
        bne     boss_intro_done
        lda     #$00
        sta     $BD
        lda     #$01
        sta     $2C
        jmp     boss_death_sequence

boss_intro_done:  lda     $B1
        cmp     #$FF
        bne     boss_intro_loop
        lda     #$00
        sta     $BD
        lda     #$10
        sta     $F7
        sta     $2000
        lda     #$06
        sta     $F8
        sta     $2001
        lda     #$00
        sta     $B0
        ldx     #$FF
        txs
        lda     #$0E
        jsr     bank_switch
        ldx     $2A
        cpx     #$08
        bcs     advance_to_next_stage
        lda     boss_beaten_mask_lo,x
        ora     $9A
        sta     $9A
        lda     boss_beaten_mask_hi,x
        ora     $9B
        sta     $9B
        lda     #$0D
        jsr     bank_switch
        jsr     banked_0D_boss_init
        lda     #$0E
        jsr     bank_switch
        lda     $9A
        cmp     #$FF
        beq     all_bosses_defeated
        jmp     banked_0E_all_beaten

all_bosses_defeated:  lda     #$07
        sta     $2A
advance_to_next_stage:  inc     $2A
        lda     $2A
        cmp     #$0E
        bne     next_stage_continue
        lda     #$0D
        jsr     bank_switch
        jsr     banked_0D_stage_complete
        lda     #$0E
        jmp     cold_boot_init

next_stage_continue:  jmp     banked_0E_next_stage

boss_beaten_mask_lo:  .byte   $01,$02,$04,$08,$10,$20,$40,$80 ; bitmask for each boss (low byte)
boss_beaten_mask_hi:  .byte   $01,$02,$00,$00,$00,$04,$00,$00 ; bitmask for each boss (high byte)

; =============================================================================
; reset_sound_state — Reset all sound/music state variables ($C289)
; =============================================================================
reset_sound_state:  lda     #$00
        sta     $05AA                   ; clear sound channel state
        sta     $05A7
        sta     $05A9
        sta     $05A8
        sta     $AA
        lda     #$FE                    ; set boss HP to pre-intro value
        sta     $B1
        rts

        lda     #$00
        sta     $FD
        lda     #$02
        sta     $0354
        lda     #$04
        sta     $0355
        lda     #$BB
        sta     $FD
nametable_init_loop:  jsr     clear_entities_and_run
        dec     $FD
        bne     nametable_init_loop
        lda     #$00
        sta     $0355
        sta     $0354
        ldx     #$02
nametable_copy_initial:  lda     nametable_init_data,x
        sta     $0357,x
        dex
        bpl     nametable_copy_initial
        lda     #$86
        sta     $FF
        lda     #$00
        sta     $FE

; =============================================================================
; nametable_column_upload — Upload nametable columns from stage bank to PPU ($C2D2)
; =============================================================================
nametable_column_upload:  lda     #$09  ; switch to bank $09 (scroll data)
        jsr     bank_switch
        lda     $FD
        lsr     a
        tax
        lda     nametable_bank_table,x
        sta     $03B6
        lda     nametable_addr_table,x
        sta     $03B7
        lda     $FD
        and     #$01
        beq     nametable_col_copy_inner
        lda     $03B7
        ora     #$20
        sta     $03B7
nametable_col_copy_inner:  ldy     #$20
nametable_col_copy_byte:  lda     ($FE),y
        sta     $03B8,y
        dey
        bpl     nametable_col_copy_byte
        lda     #$20
        sta     $47
        clc
        lda     $FE
        adc     #$20
        sta     $FE
        lda     $FF
        adc     #$00
        sta     $FF
        jsr     clear_entities_and_run
        inc     $FD
        lda     $FD
        cmp     #$2E
        bne     nametable_column_upload
        lda     #$0E
        jsr     bank_switch
        rts

nametable_init_data:  .byte   $28,$18,$2C ; initial nametable setup params
nametable_bank_table:  .byte   $10,$1A,$1A,$1B,$1B,$1B,$1B,$1C ; column data VRAM addr high per index
        .byte   $1C,$1C,$1C,$1D,$1D,$1D,$1D,$1E
        .byte   $1E,$1E,$1E,$1F,$1F,$1F,$1F
nametable_addr_table:  .byte   $00,$80,$C0,$00,$40,$80,$C0,$00 ; column data VRAM addr low per index
        .byte   $40,$80,$C0,$00,$40,$80,$C0,$00
        .byte   $40,$80,$C0,$00,$40,$80,$C0

; =============================================================================
; run_one_game_frame — Execute one frame: entities, sound, rendering, scroll ($C352)
; =============================================================================
run_one_game_frame:  lda     #$0E       ; switch to game engine bank
        jsr     bank_switch
        lda     #$00
        sta     $0680
        lda     #$01
        sta     $4B                     ; set invincibility frame
        jsr     update_entity_positions ; move all entities
        jsr     entity_spawn_scan       ; spawn/despawn entities
        jsr     process_sound_and_bosses ; process sound + boss check
        jsr     banked_sound_process    ; run sound driver
run_sound_and_scroll:  jsr     render_all_sprites ; build OAM buffer
        lda     $FB
        beq     game_frame_done
        inc     $FC
        cmp     $FC
        beq     game_frame_wait_render
        bcs     game_frame_done
game_frame_wait_render:  jsr     wait_one_rendering_frame
        lda     #$00
        sta     $FC
game_frame_done:  jsr     wait_for_vblank ; wait for NMI and read input
        rts

; =============================================================================
; clear_entities_and_run — Clear entity slots 0-31, then run sound and scroll ($C386)
; =============================================================================
clear_entities_and_run:  ldx     #$1F
        lda     #$00
clear_entities_loop:  sta     $0680,x
        dex
        bpl     clear_entities_loop
        jmp     run_sound_and_scroll

; =============================================================================
; setup_explosion_array — Set up 12 explosion entities around boss position ($C393)
; =============================================================================
setup_explosion_array:  lda     $0440
        sta     $09
        lda     $0460
        sta     jump_ptr
        lda     $04A0
        sta     $0A
        lda     #$25                    ; explosion entity type
        sta     $0B
        ldx     #$0D
        ldy     #$0B
explosion_setup_loop:  lda     #$80
        ora     explosion_flags_tbl,y
        sta     $0420,x                 ; set entity flags (active)
        lda     $0B
        sta     $0400,x
        lda     $09
        sta     $0440,x
        lda     jump_ptr
        sta     $0460,x
        lda     $0A
        sta     $04A0,x
        lda     explosion_xvel_sub_tbl,y
        sta     $0620,x
        lda     explosion_xvel_tbl,y
        sta     $0600,x
        lda     explosion_yvel_sub_tbl,y
        sta     $0660,x
        lda     explosion_yvel_tbl,y
        sta     $0640,x
        lda     #$00
        sta     $0680,x
        sta     $06A0,x
        dex
        dey
        bpl     explosion_setup_loop
        rts

explosion_xvel_sub_tbl:  .byte   $00,$00,$00,$00,$60,$60,$60,$60 ; explosion X velocity (sub-pixel)
        .byte   $00,$C0,$00,$E0
explosion_xvel_tbl:  .byte   $00,$02,$00,$02,$01,$01,$01,$01 ; explosion X velocity (whole pixel)
        .byte   $00,$00,$00,$00
explosion_yvel_sub_tbl:  .byte   $00,$00,$00,$00,$60,$A0,$A0,$60 ; explosion Y velocity (sub-pixel)
        .byte   $C0,$00,$40,$00
explosion_yvel_tbl:  .byte   $02,$00,$FE,$00,$01,$FE,$FE,$01 ; explosion Y velocity (whole pixel)
        .byte   $00,$00,$FF,$00
explosion_flags_tbl:  .byte   $00,$40,$00,$00,$40,$40,$00,$00 ; explosion facing/flip flags
        .byte   $00,$40,$00,$00

; =============================================================================
; palette_anim_update — Update palette animation cycling ($C427)
; =============================================================================
palette_anim_update:  lda     $AA       ; check special mode flag
        bne     palette_anim_done
        lda     $0355                   ; check palette anim frame count
        beq     palette_anim_done
        inc     $44
        cmp     $44
        bcs     palette_anim_done
        lda     #$00
        sta     $44
        inc     $43
        lda     $43
        cmp     $0354
        bcc     palette_anim_advance
        lda     #$00
        sta     $43
palette_anim_advance:  asl     a
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
palette_anim_copy_loop:  lda     $0376,x ; copy from palette animation frames
        sta     $0356,y                 ; write to active palette RAM
        inx
        iny
        cpy     #$10
        bne     palette_anim_copy_loop
        inc     $3A
palette_anim_done:  rts

        lda     $2A
        and     #$07
        jsr     bank_switch
        lda     #$00
        sta     $0A
        lda     #$BC
        sta     $0B
        lda     $2A
        and     #$08
        beq     *+4
        inc     $0B
        ldy     #$00
        lda     ($0A),y
        sta     $00
        lda     #$00
        sta     $2006
        sta     $2006
        sta     jump_ptr
        iny
        sty     $01

; =============================================================================
; chr_upload_entry — Upload CHR tile data from stage banks to CHR-RAM ($C487)
; =============================================================================
chr_upload_entry:  ldy     $01
        lda     ($0A),y
        sta     $09
        iny
        lda     ($0A),y
        sta     $02
        iny
        lda     ($0A),y
        iny
        sty     $01
        jsr     bank_switch
chr_upload_page_loop:  ldy     #$00
chr_upload_byte_loop:  lda     (jump_ptr),y ; read CHR byte from bank
        sta     $2007                   ; write to CHR-RAM via PPUDATA
        iny
        bne     chr_upload_byte_loop
        inc     $09
        dec     $02
        bne     chr_upload_page_loop
        lda     $2A
        and     #$07
        jsr     bank_switch
        dec     $00
        bne     chr_upload_entry
        inc     $0B
        inc     $0B
        ldy     #$61
chr_upload_palette_copy:  lda     ($0A),y
        sta     $0354,y
        dey
        bpl     chr_upload_palette_copy
        jsr     upload_palette
        lda     #$0E
        jsr     bank_switch
        rts

        lda     $2A
        and     #$07
        jsr     bank_switch
        ldy     $B0
        lda     $BB06,y
        sta     $20
        sta     $0440
        lda     $BB0C,y
        sta     $48
        sta     $49
        lda     $BB12,y
        sta     $4C
        sta     $4D
        lda     $BB18,y
        sta     $17
        lda     $BB1E,y
        sta     $16
        lda     $BB24,y
        sta     $19
        lda     $BB2A,y
        sta     $18
        lda     $BB30,y
        sta     $38
        lda     $BB36,y
        sta     $14
        lda     $BB3C,y
        sta     $15
        ldx     $38
        jsr     scroll_col_load_palette
        tya
        clc
        adc     #$0B
        tay
        ldx     #$0C
chr_upload_sound_bank:  lda     $B460,y
        pha
        dey
        dex
        bne     chr_upload_sound_bank
        lda     #$0A
        sta     $2006
        lda     #$00
        sta     $2006
        sta     jump_ptr
        lda     #$06
        sta     $00
chr_sound_page_loop:  pla
        sta     $09
        pla
        jsr     bank_switch
        ldy     #$00
chr_sound_byte_loop:  lda     (jump_ptr),y
        sta     $2007
        iny
        bne     chr_sound_byte_loop
        dec     $00
        bne     chr_sound_page_loop
        lda     #$0E
        jsr     bank_switch
        lda     $B0
        cmp     #$02
        bne     chr_upload_wily_check
        jsr     banked_0E_wily_check
chr_upload_wily_check:  rts

        lda     #$0D
        jsr     bank_switch
        jsr     $8009
        lda     #$0E
        jsr     bank_switch
        rts
        lda     #$0D
        jsr     bank_switch
        jsr     $8000
        lda     #$0E
        jsr     bank_switch
        rts
        ldx     #$0F

; =============================================================================
; find_active_entity_slot — Scan entity slots for an unused one ($C575)
; =============================================================================
find_active_entity_slot:  lda     $0420,x ; check entity flags (bit 7=active)
        bmi     find_entity_done
        dex
        cpx     #$01
        bne     find_active_entity_slot
        lda     $47
        beq     scroll_column_setup
        jsr     wait_for_vblank
scroll_column_setup:  lda     $03B6
        pha
        lda     $03B7
        pha
        lda     #$32
        jsr     bank_switch_enqueue
        lda     #$0D
        jsr     bank_switch
        jsr     banked_entry_alt
        pla
        sta     $03B7
        pla
        sta     $03B6
        lda     #$0E
        jsr     bank_switch
find_entity_done:  rts

; =============================================================================
; process_sound_and_bosses — Process sound engine and check boss encounter ($C5A9)
; =============================================================================
process_sound_and_bosses:  lda     $B1  ; check boss HP / intro state
        beq     process_sound_done
        lda     #$0B                    ; switch to game logic bank
        jsr     bank_switch
        jsr     banked_entry_alt        ; call entity AI update
        lda     #$0E                    ; switch back to game engine
        jsr     bank_switch
        lda     $05AA                   ; check sound trigger flag
        beq     process_sound_done
        lda     $2A                     ; check current stage index
        cmp     #$0C
        bne     process_sound_jump_intro
        lda     $BC
        cmp     #$FF
        beq     process_sound_jump_intro
        ldx     #$0F
clear_boss_entities:  lsr     $0430,x
        dex
        bpl     clear_boss_entities
        jsr     reset_sound_state
        lda     #$00
        sta     $2B
        lda     #$7D
        ldx     #$0F
        jsr     spawn_entity_init
        lda     #$20
        sta     $047F
        lda     #$AB
        sta     $04BF
        bne     process_sound_done
process_sound_jump_intro:  jmp     boss_intro_sequence ; start boss intro

process_sound_done:  rts

        pha
        lda     $05A7
        sta     $09
        lda     $05A9
        sta     $08
        pla
        jsr     column_copy_to_buffer
        clc
        lda     $03B7
        adc     #$20
        sta     $03B7
        lda     $03B6
        adc     #$00
        sta     $03B6
        clc
        lda     $05A9
        adc     #$20
        sta     $05A9
        lda     $05A7
        adc     #$00
        sta     $05A7
        lda     #$0B
        jsr     bank_switch
        rts

        jsr     bank_switch
        lda     #$00
        sta     $08
        ldx     #$04
chr_copy_ppu_loop:  lda     (jump_ptr),y
        sta     $2007
        iny
        bne     chr_copy_ppu_loop
        inc     $09
        dex
        bne     chr_copy_ppu_loop
        lda     #$0D
        jsr     bank_switch
        rts

        sta     $00
        tax
        lda     $C689,x
        sta     $01
        lda     $C690,x
        sta     $02
        lda     #$00
        sta     $08
        sta     $2006
        sta     $2006
chr_bank_load_ptr_lo:  .byte   $A6
chr_bank_load_ptr_hi:  .byte   $02
        lda     chr_bank_src_addr_lo_tbl,x
        sta     $09
        lda     chr_bank_page_count_tbl,x
        sta     $03
        lda     chr_bank_src_bank_tbl,x
        jsr     bank_switch
        ldy     #$00
chr_copy_loop:  lda     (jump_ptr),y
        sta     $2007
        iny
        bne     chr_copy_loop
        inc     $09
        dec     $03
        bne     chr_copy_loop
        inc     $02
        dec     $01
        bne     chr_bank_load_ptr_lo
        lda     #$0D
        jsr     bank_switch
        rts

        .byte   $02,$02,$03,$06,$0E,$04,$08,$00
        .byte   $02,$04,$07,$0D,$1B,$1F
chr_bank_src_bank_tbl:  .byte   $05,$08,$06,$09,$06,$00,$09,$00
        .byte   $09,$08,$09,$08,$09,$03,$03,$04
        .byte   $04,$06,$04,$05,$05,$05,$07,$07
        .byte   $02,$08,$07,$05,$08,$09,$08,$00
        .byte   $06,$07,$07,$07,$02,$02,$09
chr_bank_src_addr_lo_tbl:  .byte   $90,$88,$90,$90
        bcc     chr_bank_load_ptr_hi
        ldy     #$98
        ldy     $AC80
        sty     $9F
        sta     $9D9C,y
        .byte   $9B,$B2,$97,$93,$96,$9C,$9D,$9F
        .byte   $95,$A4,$B2,$90,$88,$9F,$8C,$98
        .byte   $B2,$9D,$9F,$AE,$96,$94,$AC
chr_bank_page_count_tbl:  .byte   $10,$10,$10,$10,$08,$08,$10,$0E
        .byte   $02,$04,$02,$04,$06,$02,$01,$01
        .byte   $01,$02,$01,$01,$02,$01
        ora     ($01,x)
        .byte   $02,$0C,$02,$10,$03,$01,$0C,$08
        ora     ($01,x)
        ora     ($01,x)
        ora     ($01,x)
        .byte   $02
column_copy_to_buffer:  jsr     bank_switch
        ldy     #$1F
column_copy_loop:  lda     (jump_ptr),y
        sta     $03B8,y
        dey
        bpl     column_copy_loop
        lda     #$20
        sta     $47
        lda     #$0D
        jsr     bank_switch
        rts

        lda     #$01
        jsr     bank_switch
        ldx     #$1F
column_copy_from_ram:  lda     $9CD0,x
        sta     $03B8,x
        dex
        bpl     column_copy_from_ram
        lda     #$08
        sta     $03B6
        lda     #$00
        sta     $03B7
        lda     #$20
        sta     $47
        lda     #$0D
        jsr     bank_switch
        rts

        lda     #$09
        jsr     bank_switch
        ldy     #$1F
column_copy_from_ptr:  lda     ($FE),y
        sta     $03B8,y
        dey
        bpl     column_copy_from_ptr
        lda     #$20
        sta     $47
        lda     #$0D
        jsr     bank_switch
        rts

        lda     $FD
        sta     $09
        lda     #$00
        lsr     $09
        ror     a
        lsr     $09
        ror     a
        lsr     $09
        ror     a
        sta     $03B7
        sta     $08
        lda     $FD
        cmp     #$08
        bcc     *+7
        lda     $09
        jmp     $C783
        lda     $09
        adc     #$09
        sta     $03B6
        clc
        tya
        adc     $09
        sta     $09
        txa
        jsr     bank_switch
        ldy     #$1F
column_copy_from_bank:  lda     (jump_ptr),y
        sta     $03B8,y
        dey
        bpl     column_copy_from_bank
        lda     #$20
        sta     $47
        lda     #$0D
        jsr     bank_switch
        rts

        lda     $2A
        and     #$07
        jsr     bank_switch
        lda     $B400,y
        tay
        lda     #$0E
        jsr     bank_switch
        rts
        lda     #$C0
        sta     $0420
        lda     #$80
        sta     $0460
        lda     #$14
        sta     $04A0
        lda     #$1A
        sta     $0400
boss_entrance_scroll:  lda     $2A
        and     #$07
        jsr     bank_switch
        lda     #$00
        sta     $0680
        sta     $06A0
        clc
        lda     $04A0
        adc     #$10
        sta     $04A0
        ldx     $B0
        cmp     $BB00,x
        beq     boss_entrance_done
        jsr     render_all_sprites
        jsr     wait_for_vblank
        jmp     boss_entrance_scroll

boss_entrance_done:  lda     #$30
        jsr     bank_switch_enqueue
        lda     #$00
        sta     $2C
        sta     $3E
        sta     $3F
        lda     #$40
        sta     $42
        lda     #$0E
        jsr     bank_switch
        rts

        lda     $2A
        sta     $B3
        lda     #$0B
        jsr     bank_switch
        jsr     banked_entry
        lda     #$0E
        jsr     bank_switch
boss_fight_frame:  lda     #$00
        sta     $23
        sta     $27
        jsr     banked_0E_entity_update
        jsr     update_entity_positions
        jsr     entity_spawn_scan
        jsr     process_sound_and_bosses
        jsr     banked_sound_process
        jsr     render_all_sprites
        lda     $FB
        beq     boss_fight_wait_vblank
        inc     $FC
        cmp     $FC
        beq     boss_fight_wait_render
        bcs     boss_fight_wait_vblank
boss_fight_wait_render:  jsr     wait_one_rendering_frame
        lda     #$00
        sta     $FC
boss_fight_wait_vblank:  jsr     wait_for_vblank
        lda     $B1
        cmp     #$02
        bcc     boss_fight_frame
        rts

; =============================================================================
; divide_8bit — 8-bit unsigned division: $01/$02 -> quotient $03 ($C84E)
; =============================================================================
divide_8bit:  lda     #$00
        sta     $03
        sta     $04                     ; clear remainder high
        lda     $01
        ora     $02
        bne     div8_setup
        sta     $03
        rts

div8_setup:  ldy     #$08               ; 8 bits to process
div8_loop:  asl     $03
        rol     $01
        rol     $04
        sec
        lda     $04
        sbc     $02
        bcc     div8_next
        sta     $04
        inc     $03
div8_next:  dey
        bne     div8_loop
        rts

; =============================================================================
; divide_16bit — 16-bit unsigned division: $0A:$0B / $0C:$0D -> $0E:$0F ($C874)
; =============================================================================
divide_16bit:  lda     #$00
        sta     $11
        sta     $10
        lda     $0B
        ora     $0A
        ora     $0D
        ora     $0C
        bne     div16_setup
        sta     $0F
        sta     $0E
        rts

div16_setup:  ldy     #$10              ; 16 bits to process
div16_loop:  asl     $10
        rol     $0A
        rol     $0B
        rol     $11
        sec
        lda     $0B
        sbc     $0C
        tax
        lda     $11
        sbc     $0D
        bcc     div16_next
        stx     $09
        sta     $11
        inc     $10
div16_next:  dey
        bne     div16_loop
        lda     $0A
        sta     $0F
        lda     $10
        sta     $0E
        rts

        ldx     $1B
        ldy     #$20
        lda     $09
        and     #$01
        beq     *+4
        ldy     #$24
        sty     $0B
        lda     jump_ptr
        lsr     a
        lsr     a
        pha
        lsr     a
        and     #$03
        ora     $0B
        sta     $0300,x
        pla
        pha
        ror     a
        and     #$FC
        sta     $0304,x
        lda     $0B
        ora     #$03
        sta     $0308,x
        pla
        sta     $0A
        lsr     a
        lsr     a
        lsr     a
        asl     $0A
        asl     $0A
        asl     $0A
        ora     $0A
        ora     #$C0
        sta     $030C,x
        rts

        ldx     $51
        ldy     #$08
        lda     $09
        and     #$01
        beq     *+4
        ldy     #$09
        sty     $0B
        lda     $0A
        and     #$F8
        asl     a
        rol     $0B
        asl     a
        rol     $0B
        sta     $03BC,x
        lda     jump_ptr
        lsr     a
        lsr     a
        lsr     a
        ora     $03BC,x
        sta     $03BC,x
        lda     $0B
        sta     $03B6,x
        rts

        pha
        lda     $08
        pha
        ldx     $51
        lda     $0A
        and     #$E0
        lsr     a
        lsr     a
        sta     $0B
        asl     $08
        rol     a
        asl     jump_ptr
        rol     a
        asl     jump_ptr
        rol     a
        ora     $0B
        ora     #$C0
        sta     $03C8,x
        ldy     #$23
        lda     $09
        and     #$01
        beq     attr_set_nametable
        ldy     #$27
attr_set_nametable:  tya
        sta     $03C2,x
        ldy     #$00
        pla
        and     #$10
        beq     attr_check_row
        iny
attr_check_row:  lda     $0A
        and     #$10
        beq     attr_calc_mask
        iny
        iny
attr_calc_mask:  pla
        and     attr_mask_table,y
        sta     $03CE,x
        lda     attr_mask_table,y
        eor     #$FF
        sta     $03D4,x
        rts

attr_mask_table:  .byte   $03,$0C,$30,$C0
        lda     $2A
        and     #$07
        jsr     bank_switch
        lda     #$20
        sta     $0B
        ldy     #$00
        lda     (jump_ptr),y
        tax
        tay
        lda     $8400,y
        pha
        txa
        asl     a
        rol     $0B
        asl     a
        rol     $0B
        sta     $0A
        lda     $1B
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        pha
        ldy     #$00
metatile_render_loop:  clc
        pla
        pha
        adc     metatile_offset_table,y
        tax
        lda     ($0A),y
        asl     a
        asl     a
        clc
        sta     $0310,x
        adc     #$01
        sta     $0314,x
        adc     #$01
        sta     $0311,x
        adc     #$01
        sta     $0315,x
        iny
        cpy     #$04
        bne     metatile_render_loop
        pla
        ldy     #$20
        lda     jump_ptr
        and     #$40
        beq     metatile_set_base_nt
        ldy     #$24
metatile_set_base_nt:  sty     $0D
        lda     $1A
        sta     $0C
        lsr     a
        ror     $0C
        lda     $0C
        pha
        and     #$03
        ora     $0D
        sta     $0D
        pla
        and     #$FC
        ldx     $1B
        sta     $0304,x
        lda     $0D
        sta     $0300,x
        lda     $0D
        ora     #$03
        sta     $0308,x
        lda     $1A
        sta     $0C
        lsr     a
        lsr     a
        lsr     a
        asl     $0C
        asl     $0C
        asl     $0C
        ora     #$C0
        ora     $0C
        sta     $030C,x
        pla
        sta     $0350,x
        inc     $1B
        lda     #$0E
        jsr     bank_switch
        rts

metatile_offset_table:  .byte   $00,$08,$02,$0A
        lda     $29
        pha
        jsr     $C96B
        pla
        jsr     bank_switch
        rts
        lda     $2A
        and     #$07
        jsr     bank_switch
        lda     $39
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     $0300
        lda     $39
        asl     a
        asl     a
        asl     a
        pha
        and     #$18
        sta     $0301
        pla
        asl     a
        and     #$C0
        ora     $0301
        sta     $0301
        lda     $39
        and     #$F8
        ora     #$C0
        sta     $0313
        lda     $39
        and     #$03
        asl     a
        ora     $0313
        sta     $0313
        ldx     #$20
        lda     $20
        and     #$01
        beq     *+4
        ldx     #$24
        txa
        ora     $0300
        sta     $0300
        txa
        ora     #$03
        sta     $0312
        lda     #$00
        sta     $00
        lda     $39
        and     #$3B
        lsr     a
        ror     $00
        lsr     a
        ror     $00
        lsr     a
        ror     $00
        lsr     $00
        ora     $00
        sta     $00
        lda     $0440
        ldx     #$00
        stx     jump_ptr
        lsr     a
        ror     jump_ptr
        lsr     a
        ror     jump_ptr
        clc
        adc     #$85
        sta     $09
        stx     $01
metatile_attr_loop:  ldy     $00
        lda     (jump_ptr),y
        sta     $03
        sta     $0A
        lda     #$20
        asl     $0A
        rol     a
        asl     $0A
        rol     a
        sta     $0B
        ldy     #$00
        lda     $39
        and     #$04
        beq     metatile_attr_count
        iny
metatile_attr_count:  lda     #$02
        sta     $02
metatile_attr_inner:  lda     ($0A),y
        asl     a
        asl     a
        clc
        sta     $0302,x
        adc     #$01
        sta     $030A,x
        adc     #$01
        sta     $0303,x
        adc     #$01
        sta     $030B,x
        inx
        inx
        iny
        iny
        dec     $02
        bne     metatile_attr_inner
        lda     $39
        ldy     #$0F
        and     #$04
        beq     metatile_attr_mask_setup
        ldy     #$F0
metatile_attr_mask_setup:  sty     $0314
        ldy     $03
        lda     $8400,y
        and     $0314
        ldy     $01
        sta     $0315,y
        lda     $00
        ora     #$08
        sta     $00
        inc     $01
        lda     $01
        cmp     #$02
        beq     metatile_attr_done
        jmp     metatile_attr_loop

metatile_attr_done:  lda     #$80
        sta     $1B
        lda     #$FF
        eor     $0314
        sta     $0314
        lda     #$0E
        jsr     bank_switch
        rts

        lda     $FD
        cmp     #$60
        bcc     *+3
        rts
        lda     $29
        pha
        lda     $FD
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        pha
        lsr     a
        clc
        adc     #$0A
        sta     $03B6
        lda     $FD
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $03B7
        sta     jump_ptr
        lda     $2A
        and     #$07
        jsr     bank_switch
        ldx     $FE
        jsr     scroll_col_load_palette
        clc
        pla
        adc     $B42C,x
        tax
        lda     $B460,x
        sta     $09
        lda     $B461,x
        jsr     bank_switch
        ldy     #$1F
scroll_col_copy_loop:  lda     (jump_ptr),y
        sta     $03B8,y
        dey
        bpl     scroll_col_copy_loop
        lda     #$20
        sta     $47
        inc     $FD
        inc     $FD
        pla
        jsr     bank_switch
        rts

scroll_col_load_palette:  ldy     $B42C,x
        lda     $B46C,y
        sta     $036F
        lda     $B46D,y
        sta     $0370
        lda     $B46E,y
        sta     $0371
        lda     $B46F,y
        sta     $0373
        lda     $B470,y
        sta     $0374
        lda     $B471,y
        sta     $0375
        rts

        ldx     #$0F
        ldy     #$00
build_active_entity_list:  lda     $0430,x
        bpl     active_entity_next
        and     #$10
        beq     active_entity_next
        stx     $56,y
        iny
active_entity_next:  dex
        bpl     build_active_entity_list
        sty     $55
        rts

; =============================================================================
; lookup_cached_tile — Look up tile collision from cached active entity list ($CBA2)
; =============================================================================
lookup_cached_tile:  ldy     $55
cached_tile_scan_loop:  dey
        bmi     lookup_tile_from_map
        ldx     $56,y
        lda     jump_ptr
        and     $0610,x
        cmp     $0650,x
        bne     cached_tile_scan_loop
        lda     $0A
        and     $0630,x
        cmp     $0670,x
        bne     cached_tile_scan_loop
        lda     $04F0,x
        sta     $00
        rts

; =============================================================================
; lookup_tile_from_map — Look up tile collision type from stage metatile map ($CBC3)
; =============================================================================
lookup_tile_from_map:  lda     $2A
        and     #$07                    ; stage bank = stage index & 7
        jsr     bank_switch             ; switch to stage data bank
        lda     #$00
        sta     $00
        lda     $0B
        beq     tile_lookup_calc_index
        bmi     tile_lookup_clear_y
        jmp     tile_lookup_done

tile_lookup_clear_y:  lda     #$00
        sta     $0A
tile_lookup_calc_index:  lda     jump_ptr
        lsr     a
        lsr     a
        and     #$38
        sta     $00
        lda     $0A
        asl     a
        rol     a
        rol     a
        rol     a
        and     #$07
        ora     $00
        sta     $00
        lda     #$00
        sta     $0C
        lda     $09
        lsr     a
        ror     $0C
        lsr     a
        ror     $0C
        clc
        adc     #$85
        sta     $0D
        ldy     $00
        lda     ($0C),y
        sta     $0C
        lda     #$20
        asl     $0C
        rol     a
        asl     $0C
        rol     a
        sta     $0D
        ldy     #$00
        lda     jump_ptr
        and     #$10
        beq     tile_check_vert
        iny
        iny
tile_check_vert:  lda     $0A
        and     #$10
        beq     tile_get_collision_type
        iny
tile_get_collision_type:  lda     ($0C),y
        sta     $00
        asl     $00
        rol     a
        asl     $00
        rol     a
        and     #$03
        sta     $00
        lsr     a
        beq     tile_lookup_done
        dec     $00
        dec     $00
        lda     $2A
        asl     a
        adc     $00
        tax
        lda     stage_collision_table,x
        sta     $00
tile_lookup_done:  lda     #$0E         ; switch back to game engine
        jsr     bank_switch
        rts

stage_collision_table:  .byte   $02,$03,$02,$03,$02,$00,$04,$03
        .byte   $00,$03,$02,$07,$05,$06,$02,$03
        .byte   $02,$00,$02,$03,$04,$03,$02,$03
        .byte   $00,$00,$00,$00
        jsr     lookup_cached_tile
        lda     #$0B
        jsr     bank_switch
        rts

; =============================================================================
; clear_oam_buffer — Fill OAM buffer with $F8 (hide all sprites) ($CC6C)
; =============================================================================
clear_oam_buffer:  lda     #$F8         ; $F8 = off-screen Y (hide sprite)
        ldx     #$00
clear_oam_loop:  sta     $0200,x        ; write $F8 to OAM Y position
        inx
        bne     clear_oam_loop
        rts

; =============================================================================
; render_all_sprites — Main sprite rendering — build OAM buffer from entity data ($CC77)
; =============================================================================
render_all_sprites:  lda     #$0A       ; switch to sound data bank
        jsr     bank_switch             ; bank $0A has sprite def ptrs
        jsr     clear_oam_buffer        ; clear all sprites first
        lda     #$00
        sta     $06
        sta     $0D
        sta     $0C
        lda     $AA
        beq     render_even_frame
        jmp     render_special_mode

render_even_frame:  lda     $1C         ; frame counter (odd/even toggle)
        and     #$01
        bne     render_odd_frame
        lda     #$FF
        sta     $0C
        lda     #$00
        sta     $2B
render_entity_forward:  jsr     render_entity_normal
        bcs     render_even_done
        inc     $2B
        lda     $2B
        cmp     #$10
        bne     render_entity_forward
render_weapon_forward:  jsr     render_weapon_normal
        bcs     render_even_done
        inc     $2B
        lda     $2B
        cmp     #$20
        bne     render_weapon_forward
        lda     $06
        sta     $0C
        jsr     render_hp_bars
render_even_done:  jmp     render_priority_fix

render_odd_frame:  jsr     render_hp_bars
        lda     $06
        sta     $0D
        lda     #$1F
        sta     $2B
render_weapon_reverse:  jsr     render_weapon_normal
        bcs     render_priority_fix
        dec     $2B
        lda     $2B
        cmp     #$0F
        bne     render_weapon_reverse
render_entity_reverse:  jsr     render_entity_normal
        bcs     render_priority_fix
        dec     $2B
        bpl     render_entity_reverse
        lda     $06
        sta     $0C
render_priority_fix:  lda     $2A
        cmp     #$01
        bne     render_sprites_done
        ldx     $0D
render_priority_loop:  cpx     $0C
        beq     render_sprites_done
        lda     $0202,x
        ora     #$20
        sta     $0202,x
        inx
        inx
        inx
        inx
        bne     render_priority_loop
render_sprites_done:  lda     #$0E      ; switch back to game engine
        jsr     bank_switch
        rts

render_special_mode:  lda     $1C
        and     #$01
        bne     render_special_odd
        lda     #$FF
        sta     $0C
        lda     #$00
        sta     $2B
        lda     $AA
        and     #$04
        beq     render_special_check_entity
        jsr     render_entity_special
        jmp     render_special_entity_loop

render_special_check_entity:  jsr     render_entity_normal
render_special_entity_loop:  inc     $2B
render_special_entity_inner:  lda     $AA
        and     #$02
        bne     render_special_jump_1
        jsr     render_entity_normal
        jmp     render_special_carry

render_special_jump_1:  jsr     render_entity_special
render_special_carry:  bcs     render_special_done
        inc     $2B
        lda     $2B
        cmp     #$10
        bne     render_special_entity_inner
render_special_weapon:  jsr     render_weapon_special
        bcs     render_special_done
        inc     $2B
        lda     $2B
        cmp     #$20
        bne     render_special_weapon
        lda     $06
        sta     $0C
        jsr     render_hp_bars
render_special_done:  jmp     render_priority_fix

render_special_odd:  jsr     render_hp_bars
        lda     $06
        sta     $0D
        lda     #$1F
        sta     $2B
render_special_weapon_rev:  jsr     render_weapon_special
        bcs     render_special_jump_end
        dec     $2B
        lda     $2B
        cmp     #$0F
        bne     render_special_weapon_rev
render_special_entity_rev:  lda     $AA
        and     #$02
        bne     render_special_entity_inner_2
        jsr     render_entity_normal
        jmp     render_special_carry_2

render_special_entity_inner_2:  jsr     render_entity_special
render_special_carry_2:  bcs     render_special_jump_end
        dec     $2B
        bne     render_special_entity_rev
        lda     $AA
        and     #$04
        beq     render_special_check_2
        jsr     render_entity_special
        jmp     render_special_jump_2

render_special_check_2:  jsr     render_entity_normal
render_special_jump_2:  lda     $06
        sta     $0C
render_special_jump_end:  jmp     render_priority_fix

render_entity_special:  ldx     $2B
        lda     $0420,x
        bmi     render_entity_get_sprite_ptr
        clc
        rts

render_entity_get_sprite_ptr:  ldy     $0400,x
        lda     sprite_def_ptr_lo,y
        sta     jump_ptr
        lda     sprite_def_ptr_hi,y
        sta     $09
        lda     $06A0,x
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        beq     render_entity_deactivate
        jmp     render_begin_oam_write

render_entity_deactivate:  lsr     $0420,x
        rts

render_weapon_special:  ldx     $2B
        lda     $0420,x
        bmi     render_weapon_get_sprite_ptr
        clc
        rts

render_weapon_get_sprite_ptr:  ldy     $0400,x
        lda     sprite_def_ptr_lo_wpn,y
        sta     jump_ptr
        lda     sprite_def_ptr_hi_wpn,y
        sta     $09
        lda     $06A0,x
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        beq     render_weapon_deactivate
        jmp     render_weapon_begin_write

render_weapon_deactivate:  lsr     $0420,x
        rts

; =============================================================================
; render_entity_normal — Render a normal entity's sprites to OAM ($CDE7)
; =============================================================================
render_entity_normal:  ldx     $2B
        lda     $0420,x                 ; check entity active flag
        bmi     render_entity_get_ptr
        clc
        rts

render_entity_get_ptr:  ldy     $0400,x
        lda     sprite_def_ptr_lo,y
        sta     jump_ptr
        lda     sprite_def_ptr_hi,y
        sta     $09
        lda     $06A0,x
        pha
        inc     $0680,x
        ldy     #$01
        lda     (jump_ptr),y
        cmp     $0680,x
        bcs     render_entity_check_frame
        lda     #$00
        sta     $0680,x
        inc     $06A0,x
        dey
        lda     (jump_ptr),y
        cmp     $06A0,x
        bcs     render_entity_check_frame
        lda     #$00
        sta     $06A0,x
render_entity_check_frame:  pla
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        bne     render_begin_oam_write
        lsr     $0420,x
        rts

render_begin_oam_write:  tay
        cpx     #$01
        bcs     render_skip_flash
        lda     $4B
        beq     render_check_flash
        dec     $4B
        lda     $1C
        and     #$02
        beq     render_check_flash
render_flash_jump:  jmp     render_ok_return

render_check_flash:  lda     $F9
        bne     render_flash_jump
        beq     render_load_sprite_data
render_skip_flash:  bne     render_load_sprite_data
        lda     $05A8
        beq     render_load_sprite_data
        lda     $1C
        and     #$02
        bne     render_dec_extra_timer
        ldy     #$18
render_dec_extra_timer:  dec     $05A8
render_load_sprite_data:  lda     banked_entry,y
        sta     jump_ptr
        lda     $8200,y
        sta     $09
        lda     #$00
        sta     $03
render_sprite_loop:  ldy     #$00
        lda     (jump_ptr),y
        sta     $04
        iny
        lda     (jump_ptr),y
        tay
        lda     $8400,y
        sta     $0A
        lda     $8500,y
        sta     $0B
        sec
        lda     $0460,x
        sbc     $1F
        sta     $00
        lda     $0440,x
        sbc     $20
        lda     $04A0,x
        sta     $01
        lda     $0420,x
        and     #$40
        sta     $02
        lda     #$02
        sta     $07
render_sprite_oam_entry:  ldx     $06
        ldy     $07
        lda     (jump_ptr),y
        sta     $0201,x
        clc
        lda     ($0A),y
        adc     $01
        sta     $0200,x
        iny
        lda     $03
        beq     render_sprite_load_tile
        lda     (jump_ptr),y
        and     #$F0
        ora     $03
        bne     render_sprite_apply_flip
render_sprite_load_tile:  lda     (jump_ptr),y
render_sprite_apply_flip:  eor     $02
        sta     $0202,x
        lda     $02
        beq     render_sprite_no_flip_x
        lda     ($0A),y
        tay
        lda     banked_09_scroll_code,y
        jmp     render_sprite_write_x

render_sprite_no_flip_x:  lda     ($0A),y
render_sprite_write_x:  clc
        bmi     render_sprite_neg_x
        adc     $00
        bcc     render_sprite_store_x
        bcs     render_sprite_offscreen
render_sprite_neg_x:  adc     $00
        bcs     render_sprite_store_x
render_sprite_offscreen:  lda     #$F8
        sta     $0200,x
        bne     render_sprite_next
render_sprite_store_x:  sta     $0203,x
        clc
        txa
        adc     #$04
        sta     $06
        beq     render_full_return
render_sprite_next:  inc     $07
        inc     $07
        dec     $04
        bne     render_sprite_oam_entry
render_ok_return:  clc
        rts

render_full_return:  sec
        rts

; =============================================================================
; render_weapon_normal — Render a weapon entity's sprites to OAM ($CEF9)
; =============================================================================
render_weapon_normal:  ldx     $2B
        lda     $0420,x
        bmi     render_weapon_get_ptr
        clc
        rts

render_weapon_get_ptr:  ldy     $0400,x
        lda     sprite_def_ptr_lo_wpn,y
        sta     jump_ptr
        lda     sprite_def_ptr_hi_wpn,y
        sta     $09
        lda     $06A0,x
        pha
        inc     $0680,x
        ldy     #$01
        lda     (jump_ptr),y
        cmp     $0680,x
        bcs     render_weapon_check_frame
        lda     #$00
        sta     $0680,x
        inc     $06A0,x
        dey
        lda     (jump_ptr),y
        cmp     $06A0,x
        bcs     render_weapon_check_frame
        lda     #$00
        sta     $06A0,x
render_weapon_check_frame:  pla
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        bne     render_weapon_begin_write
        lsr     $0420,x
        rts

render_weapon_begin_write:  tay
        lda     $0420,x
        and     #$20
        bne     render_weapon_skip
        lda     $8100,y
        sta     jump_ptr
        lda     $8300,y
        sta     $09
        lda     $0100,x
        sta     $03
        jmp     render_sprite_loop

render_weapon_skip:  clc
        rts

; =============================================================================
; render_hp_bars — Render player and boss HP bars ($CF5D)
; =============================================================================
render_hp_bars:  lda     $06C0          ; player HP (entity slot 0)
        sta     $00
        ldx     $06
        lda     #$01
        sta     $02
        lda     #$18
        sta     $01
        jsr     render_hp_bar_loop
        bcs     render_hp_done
        ldy     $A9
        beq     render_weapon_hp
        lda     $9B,y
        sta     $00
        lda     #$00
        sta     $02
        lda     #$10
        sta     $01
        jsr     render_hp_bar_loop
        bcs     render_hp_done
render_weapon_hp:  lda     $B1
        beq     render_hp_done
        lda     $06C1
        sta     $00
        lda     #$03
        ldy     $B3
        cpy     #$08
        beq     render_boss_hp_start
        cpy     #$0D
        bne     render_boss_hp_setup
render_boss_hp_start:  lda     #$01
render_boss_hp_setup:  sta     $02
        lda     #$28
        sta     $01
        jsr     render_hp_bar_loop
render_hp_done:  rts

render_hp_bar_loop:  ldy     #$06
render_hp_entry:  lda     hp_y_positions_tbl,y
        sta     $0200,x
        sec
        lda     $00
        sbc     #$04
        bcs     render_hp_empty_check
        ldx     $00
        lda     #$00
        sta     $00
        lda     hp_tile_ids_tbl,x
        ldx     $06
        jmp     render_hp_set_tile

render_hp_empty_check:  sta     $00
        lda     #$87
render_hp_set_tile:  sta     $0201,x
        lda     $02
        sta     $0202,x
        lda     $01
        sta     $0203,x
        inx
        inx
        inx
        inx
        stx     $06
        beq     render_hp_overflow
        dey
        bpl     render_hp_entry
        clc
        rts

render_hp_overflow:  sec
        rts

hp_y_positions_tbl:  .byte   $18,$20,$28,$30,$38,$40,$48 ; Y positions for HP bar sprites
hp_tile_ids_tbl:  .byte   $8B,$8A,$89,$88 ; tile IDs for HP bar fill levels

; =============================================================================
; NMI Handler (VBLANK)
; Called every frame during vertical blanking interval.
; Handles: OAM DMA, palette upload, PPU buffer transfer, scroll setup.
; =============================================================================
nmi_handler:  pha                       ; NMI handler — called every VBLANK
        php
        txa
        pha
        tya
        pha
        lda     $1D
        beq     nmi_do_vblank
        jmp     nmi_tail

nmi_do_vblank:                          ; Main VBLANK processing path
        lda     $F7                     ; PPUCTRL shadow
        and     #$7C                    ; Disable NMI, clear nametable select
        sta     $F7
        sta     $2000                   ; Apply to PPUCTRL
        lda     $F8                     ; PPUMASK shadow
        and     #$E7                    ; Disable sprite/bg rendering
        sta     $F8
        sta     $2001                   ; Apply to PPUMASK (rendering off)
        lda     $2002                   ; Read PPUSTATUS (reset addr latch)
        lda     #$00
        sta     $2003                   ; OAMADDR = 0
        lda     #$02
        sta     $4014                   ; OAM DMA from $0200
        lda     $1B                     ; PPU buffer transfer count
        beq     nmi_update_palette      ; Skip if no buffer data
        jsr     ppu_buffer_transfer
nmi_update_palette:  jsr     upload_palette
        lda     $47
        beq     nmi_check_scroll_update
        jsr     ppu_scroll_column_update
nmi_check_scroll_update:  lda     $51
        beq     nmi_check_ppu_update
        jsr     ppu_attribute_update
nmi_check_ppu_update:                   ; Set scroll position
        lda     $2002                   ; Reset PPUADDR latch
        lda     #$00
        sta     $01                     ; Scroll X high byte (nametable bit)
        lda     $1F                     ; Scroll X position
        sta     $00
        lda     $B8                     ; Camera X offset (shake/split)
        beq     nmi_set_scroll_x        ; Skip if no offset
        sec
        lda     $00
        sbc     $B8
        sta     $00
        lda     #$00
        sbc     $B9
        and     #$01
        sta     $01
nmi_set_scroll_x:
        lda     $00
        sta     $2005                   ; PPUSCROLL X
        lda     $22                     ; Scroll Y position
        sta     $00
        lda     $B6                     ; Camera Y offset (shake/split)
        beq     nmi_set_scroll_y
        sec
        lda     $00
        sbc     $B6
        sta     $00
nmi_set_scroll_y:
        lda     $00
        sta     $2005                   ; PPUSCROLL Y
        lda     $F8                     ; PPUMASK shadow
        ora     #$1E                    ; Enable sprites + background
        sta     $F8
        sta     $2001                   ; Re-enable rendering
        lda     $F7                     ; PPUCTRL shadow
        ora     #$80                    ; Re-enable NMI
        sta     $F7
        lda     $20                     ; Base nametable select
        eor     $01                     ; XOR with scroll high bit
        and     #$01                    ; Keep bit 0 only
        ora     $F7
        ora     $AE                     ; OR with sprite size flag
        sta     $F7
        sta     $2000                   ; Write final PPUCTRL
        sta     $1D                     ; Set "VBLANK done" flag (nonzero)
        inc     $1C                     ; Increment frame counter
nmi_tail:  lda     $68                  ; NMI exit path (also handles interrupted bank switches)
        beq     nmi_restore_bank
        inc     $67
        bne     nmi_rng_and_exit
nmi_restore_bank:  lda     #$0C         ; Restore bank that was active when NMI fired
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        jsr     banked_entry
nmi_process_queue:  ldx     $66
        beq     nmi_queue_done
        lda     $057F,x
        cmp     #$FD
        bne     nmi_queue_call
        ldy     #$A0
nmi_queue_call:  jsr     banked_entry_alt
        dec     $66
        bne     nmi_process_queue
nmi_queue_done:  lda     $29
        jsr     bank_switch
nmi_rng_and_exit:                       ; Update RNG seed and return from interrupt
        lda     $0480                   ; Entropy source
        eor     $4A                     ; XOR with current RNG state
        adc     $1C                     ; Add frame counter
        lsr     a
        sta     $4A                     ; Store new RNG value
        pla                             ; Restore Y
        tay
        pla                             ; Restore X
        tax
        plp                             ; Restore flags
        pla                             ; Restore A
        rti


; =============================================================================
; Controller Input
; =============================================================================
read_controllers:  ldx     #$01         ; Read both controllers into $23 (P1) and $24 (P2)
        stx     $4016
        dex
        stx     $4016
        inx
read_controller_loop:  ldy     #$08     ; Read 8 bits from controller X
read_controller_bits:  lda     $4016,x  ; Shift in one button bit
        sta     $27
        lsr     a
        ora     $27
        lsr     a
        ror     $23,x
        dey
        bne     read_controller_bits
        dex
        bpl     read_controller_loop
        rts


; =============================================================================
; PPU Update Routines
; =============================================================================
upload_palette:  ldy     #$3F           ; Upload 32-byte palette from $0356 to PPU $3F00
        sty     $2006
        ldx     #$00
        stx     $2006
upload_palette_loop:  lda     $0356,x   ; Copy palette bytes to PPUDATA
        sta     $2007
        inx
        cpx     #$20
        bne     upload_palette_loop
        sty     $2006
        lda     #$00
        sta     $2006
        sta     $2006
        sta     $2006
        sta     $3A
        rts

ppu_buffer_transfer:  bpl     ppu_buffer_transfer_main; Transfer PPU update buffer to VRAM
        jmp     ppu_buffer_transfer_alt

ppu_buffer_transfer_main:  ldy     #$00
ppu_buffer_entry_loop:  sty     $00
        tya
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        lda     #$04
        sta     $01
        lda     $0300,y
        sta     $0B
        lda     $0304,y
        sta     $0A
        cmp     #$80
        bcc     ppu_buffer_write_entry
        lda     $0B
        and     #$03
        cmp     #$03
        bne     ppu_buffer_write_entry
        lda     #$02
        sta     $01
ppu_buffer_write_entry:  lda     $0308,y
        sta     $2006
        lda     $030C,y
        sta     $2006
        lda     $0350,y
        sta     $2007
ppu_buffer_write_row:  lda     $0B
        sta     $2006
        clc
        lda     $0A
        sta     $2006
        adc     #$20
        sta     $0A
        ldy     #$04
ppu_buffer_write_bytes:  lda     $0310,x
        sta     $2007
        inx
        dey
        bne     ppu_buffer_write_bytes
        dec     $01
        bne     ppu_buffer_write_row
        ldy     $00
        iny
        dec     $1B
        bne     ppu_buffer_entry_loop
        rts

ppu_buffer_transfer_alt:  ldx     #$00
        stx     $1B
ppu_buffer_alt_row:  lda     $0300
        sta     $2006
        lda     $0301
        sta     $2006
ppu_buffer_alt_byte:  lda     $0302,x
        sta     $2007
        inx
        txa
        and     #$07
        bne     ppu_buffer_alt_byte
        clc
        lda     $0301
        adc     #$20
        sta     $0301
        lda     $0312
        sta     $2006
        lda     $0313
        sta     $2006
        lda     $2007
        lda     $2007
        ldy     $1B
        and     $0314
        ora     $0315,y
        pha
        lda     $0312
        sta     $2006
        lda     $0313
        sta     $2006
        pla
        sta     $2007
        inc     $1B
        inc     $0313
        cpx     #$10
        bne     ppu_buffer_alt_row
        lda     #$00
        sta     $1B
        rts

ppu_scroll_column_update:  lda     $03B6; Update nametable column during scroll
        sta     $2006
        lda     $03B7
        sta     $2006
        ldx     #$00
ppu_col_write_loop:  lda     $03B8,x
        sta     $2007
        inx
        dec     $47
        bne     ppu_col_write_loop
        rts

ppu_attribute_update:  lda     $F7      ; Update attribute table during scroll
        ora     #$04
        sta     $2000
        lda     $54
        bne     attr_update_special
        ldy     $51
        bmi     attr_update_fill_mode
attr_update_loop:  lda     $03B5,y
        sta     $2006
        lda     $03BB,y
        sta     $2006
        lda     $03C1,y
        sta     $2007
        clc
        adc     #$01
        sta     $2007
        dey
        bne     attr_update_loop
attr_update_done:  sty     $51
        lda     $F7
        and     #$FB
        sta     $2000
        rts

attr_update_fill_mode:  tya
        and     #$7F
        tay
attr_fill_outer:  lda     #$02
        sta     $00
        lda     #$E4
        sta     $01
attr_fill_write_addr:  lda     $03B5,y
        sta     $2006
        lda     $03BB,y
        sta     $2006
        lda     #$02
        sta     $02
attr_fill_write_byte:  lda     $01
        sta     $2007
        inc     $01
        dec     $02
        bne     attr_fill_write_byte
        dec     $00
        beq     attr_fill_next
        clc
        lda     $03BB,y
        adc     #$01
        sta     $03BB,y
        jmp     attr_fill_write_addr

attr_fill_next:  dey
        bne     attr_fill_outer
        beq     attr_update_done
attr_update_special:  bpl     attr_special_default
        lda     $03B6
        sta     $2006
        ldx     $03BC
        dex
        dex
        stx     $2006
        lda     $2007
        lda     $2007
        tax
        jmp     attr_special_setup

attr_special_default:  ldx     #$20
attr_special_setup:  ldy     #$02
attr_special_write_loop:  lda     $03B6
        sta     $2006
        lda     $03BC
        sta     $2006
        stx     $2007
        inx
        stx     $2007
        inx
        inc     $03BC
        dey
        bne     attr_special_write_loop
        lda     $03C2
        sta     $2006
        lda     $03C8
        sta     $2006
        lda     $54
        bpl     attr_special_read_current
        lda     $2007
        lda     $2007
        sta     $00
        lda     $03D4
        eor     #$FF
        lsr     a
        lsr     a
        and     $00
        asl     a
        asl     a
        sta     $03CE
        lda     $00
        jmp     attr_special_merge

attr_special_read_current:  lda     $2007
        lda     $2007
attr_special_merge:  and     $03D4
        ora     $03CE
        tax
        lda     $03C2
        sta     $2006
        lda     $03C8
        sta     $2006
        stx     $2007
        sty     $54
        jmp     attr_update_done

        lda     $A9
        asl     a
        asl     a
        tax
        inx
        ldy     #$01
weapon_palette_copy_loop:  lda     weapon_palette_data,x
        sta     $0366,y
        iny
        inx
        cpy     #$04
        bne     weapon_palette_copy_loop
        rts

weapon_palette_data:  .byte   $0F,$0F,$2C,$11,$0F,$0F,$28,$15 ; palette entries per weapon type
        .byte   $0F,$0F,$30,$11,$0F,$0F,$30,$19
        .byte   $0F,$0F,$30,$00,$0F,$0F,$34,$25
        .byte   $0F,$0F,$34,$14,$0F,$0F,$37,$18
        .byte   $0F,$0F,$30,$26,$0F,$0F,$30,$16
        .byte   $0F,$0F,$30,$16,$0F,$0F,$30,$16

; =============================================================================
; fire_weapon_buster — Fire Mega Buster — create bullet projectile ($D332)
; =============================================================================
fire_weapon_buster:  lda     #$26       ; sound effect: buster shot
        jsr     bank_switch_enqueue     ; queue buster sound
        lda     #$00
        sta     $3D
        sta     $36
        lda     #$02
        sta     $2C
        jsr     weapon_set_base_type    ; set player animation type
        lda     #$01
        sta     $06A0
        lda     #$6F                    ; invincibility timer duration
        sta     $4B                     ; set invincibility timer
        lda     #$01
        sta     $0640
        lda     #$40
        sta     $0660
        lda     #$00
        sta     $0600
        lda     #$90
        sta     $0620
        lsr     $042F
        lda     #$00
        sta     $AA
        ldx     #$0E
fire_find_slot_loop:  lda     $0420,x
        bpl     fire_setup_projectile
        dex
        cpx     #$01
        bne     fire_find_slot_loop
        rts

fire_setup_projectile:  lda     #$80    ; active flag
        sta     $0420,x                 ; activate projectile entity
        lda     #$24                    ; buster projectile entity type
        sta     $0400,x
        lda     $0440
        sta     $0440,x
        lda     $0460
        sta     $0460,x
        lda     $04A0
        sta     $04A0,x
        lda     #$08
        sta     $0660,x
        lda     #$00
        sta     $0640,x
        sta     $0620,x
        sta     $0600,x
        sta     $0680,x
        sta     $06A0,x
        rts

; =============================================================================
; weapon_set_base_type — Set weapon's base entity type from current weapon ID ($D3A8)
; =============================================================================
weapon_set_base_type:  ldx     $2C      ; current weapon select index
        clc
        lda     weapon_base_type_tbl,x  ; look up base sprite type
        adc     $3D
        cmp     $0400
        beq     weapon_store_type
        ldx     #$00
        stx     $06A0
        stx     $0680
weapon_store_type:  sta     $0400
        lda     $36
        beq     weapon_reset_direction
        dec     $36
        rts

weapon_reset_direction:  lda     #$00
        sta     $3D
        ldx     $2C
        lda     weapon_base_type_tbl,x
        sta     $0400
        rts

weapon_base_type_tbl:  .byte   $1A,$19,$18,$00,$04,$08,$0C,$10 ; base sprite type per weapon ID
        .byte   $14,$1B,$1F,$26

; =============================================================================
; weapon_spawn_projectile — Spawn a projectile entity at player position ($D3E0)
; =============================================================================
weapon_spawn_projectile:  lda     projectile_type_tbl,y ; entity type for this weapon
        sta     $0400,x
        lda     $0420
        and     #$40
        php
        ora     projectile_flags_tbl,y  ; merge weapon entity flags
        sta     $0420,x
        plp
        bne     weapon_spawn_facing_right
        sec
        lda     $0460
        sbc     projectile_x_offset_tbl,y
        sta     $0460,x
        lda     $0440
        sbc     #$00
        sta     $0440,x
        jmp     weapon_spawn_set_y

weapon_spawn_facing_right:  clc
        lda     $0460
        adc     projectile_x_offset_tbl,y
        sta     $0460,x
        lda     $0440
        adc     #$00
        sta     $0440,x
weapon_spawn_set_y:  lda     $04A0      ; copy player Y position
        sta     $04A0,x
        lda     projectile_xvel_sub_tbl,y
        sta     $0620,x
        lda     projectile_xvel_tbl,y
        sta     $0600,x
        lda     projectile_yvel_sub_tbl,y
        sta     $0660,x
        lda     projectile_yvel_tbl,y
        sta     $0640,x
        lda     projectile_damage_type_tbl,y
        sta     $0590,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        sta     $04E0,x
        sta     $06C0,x
        rts

projectile_type_tbl:  .byte   $23,$30,$31,$32,$33,$34,$35,$36 ; entity type for each projectile
        .byte   $37,$38,$39,$3A,$2F,$3E,$3F,$74
        .byte   $79,$7C
projectile_flags_tbl:  .byte   $81,$83,$83,$82,$87,$83,$83,$81 ; entity flags for each projectile
        .byte   $82,$82,$82,$86,$81,$82,$80,$80
        .byte   $80,$80
projectile_x_offset_tbl:  .byte   $10,$00
        .byte   $10,$00
projectile_x_offset_2:  .byte   $10,$10
        .byte   $10,$00
projectile_x_offset_3:  .byte   $00
        .byte   $20,$20,$00,$00,$00,$00,$00,$00
        .byte   $00
projectile_xvel_sub_tbl:  .byte   $00,$00,$00,$00
projectile_xvel_sub_2:  .byte   $00,$71,$00,$00,$0F,$00,$00,$27
        .byte   $00,$00,$00,$00,$00,$00
projectile_xvel_tbl:  .byte   $04,$00,$00,$00,$01,$04,$04,$00 ; X velocity per projectile type
        .byte   $00,$00,$00,$01,$00,$00,$00,$00
        .byte   $00,$00
projectile_yvel_sub_tbl:  .byte   $00,$00,$40,$00,$00,$AA,$00,$00
        .byte   $00,$41,$00,$76,$00,$00,$00,$C0
        .byte   $00,$00
projectile_yvel_tbl:  .byte   $00,$00,$00,$00,$02,$02,$00,$00 ; Y velocity per projectile type
        .byte   $00,$00,$00,$03,$00,$00,$00,$FE
        .byte   $00,$00
projectile_damage_type_tbl:  .byte   $01,$01,$02,$04,$02,$01,$02,$02 ; damage type per projectile
        .byte   $00,$00,$00,$00,$02,$00,$00,$00
        .byte   $00,$00
weapon_range_offset_tbl:  .byte   $00,$20,$40,$60,$80 ; hitbox table offset per damage type
contact_damage_range_x_tbl:  .byte   $0E,$12,$12,$12,$0A,$16,$2E,$0E ; hitbox X range per entity type
        .byte   $12,$16,$09,$2E,$0A,$16,$0E,$0C
        .byte   $0A,$1E,$1E,$26,$46,$02,$06,$06
        .byte   $06,$06,$06,$06,$06,$06,$06,$06
        .byte   $0C,$10,$10,$10,$08,$14,$2C,$0C
        .byte   $10,$14,$04,$2C,$08,$14,$0C,$0A
        .byte   $08,$1C,$1C
        .byte   $24,$44
        .byte   $02,$04,$04,$04,$04,$04,$04,$04
        .byte   $04,$04,$04,$10,$14,$14,$14,$0C
        .byte   $18,$30,$10,$14,$18,$08,$30,$0C
        .byte   $18,$10,$0E,$0A,$20,$20,$28,$48
        .byte   $02
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $14,$18,$18,$18,$10,$1C,$34,$14
        .byte   $18,$1C,$0C,$34,$10,$1C,$14,$12
        .byte   $10,$24,$24,$2C,$4C,$02,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
        .byte   $18,$1C,$1C,$1C,$14,$20,$38,$18
        .byte   $1C,$20
        .byte   $10,$38
        .byte   $14,$20,$18,$16,$14,$28,$28,$30
        .byte   $50,$02
        .byte   $10,$10
        .byte   $10,$10
        .byte   $10,$10
        .byte   $10,$10
        .byte   $10,$10
contact_damage_range_y_tbl:  .byte   $18
        .byte   $14,$10,$0C,$0C,$10,$28,$10
contact_range_y_data_1:  .byte   $1E
        .byte   $18
contact_range_y_data_2:  .byte   $28
        .byte   $30
contact_range_y_data_3:  .byte   $14
        .byte   $24
contact_range_y_data_4:  .byte   $0C
        .byte   $10
contact_range_y_data_5:  .byte   $18
        .byte   $10,$20
        .byte   $38
        .byte   $18
        .byte   $18
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $14
        .byte   $10,$0C
        .byte   $08
contact_range_y_data_6:  .byte   $08
        .byte   $0C,$24,$0C,$1A,$14,$24,$2C,$10
        .byte   $20,$08
contact_range_y_data_7:  .byte   $0C,$14,$0C,$1C
contact_range_y_data_8:  .byte   $34,$14,$14,$04,$04,$04,$04,$04
        .byte   $04,$04,$04,$04,$04,$18,$14,$10
        .byte   $0C,$0C
        .byte   $10,$28
        .byte   $10,$1E
        .byte   $18
        .byte   $28
        .byte   $30,$14
        .byte   $24,$0C
        .byte   $10,$18
        .byte   $10,$20
        .byte   $38
        .byte   $18
        .byte   $18
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $08
        .byte   $1C
contact_range_y_data_9:  .byte   $18,$14,$10,$10,$14,$2C
contact_range_y_data_10:  .byte   $14,$22
contact_range_y_data_11:  .byte   $1C,$2C,$34,$18,$28,$10
contact_range_y_data_12:  .byte   $14,$1C,$14,$24
contact_range_y_data_13:  .byte   $3C,$1C,$1C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$20,$1C,$18
        .byte   $14,$14,$18,$30,$18,$26,$20,$30
        .byte   $38,$1C,$2C,$14,$18,$20,$18,$28
        .byte   $40,$20,$20,$10,$10,$10,$10,$10
        .byte   $10,$10,$10,$10,$10
        ldy     $0400
        sty     $01
        lda     #$09
        jsr     bank_switch
        jsr     banked_09_scroll_code
switch_to_bank_0D:  lda     #$0D
        jsr     bank_switch
        rts

        .byte   $A9,$09,$20,$00,$C0,$20,$03,$86
        .byte   $4C,$31,$D6,$A9,$09,$20,$00,$C0
        .byte   $20
        .byte   $06,$86
        .byte   $4C,$31,$D6

        .byte   $A9,$09,$20,$00,$C0,$20,$09,$86
        .byte   $4C,$31,$D6

; =============================================================================
; entity_spawn_scan — Scan stage data and spawn/despawn entities based on scroll ($C658)
; =============================================================================
entity_spawn_scan:  lda     $2A
        and     #$07                    ; mask to stage bank index 0-7
        jsr     bank_switch             ; switch to current stage bank
        clc
        lda     $1F
        sta     $0A
        adc     #$FF
        sta     jump_ptr
        lda     $20
        sta     $0B
        adc     #$00
        sta     $09
        lda     $42
        and     #$40
        bne     spawn_scan_right_scroll
spawn_scan_backward:  ldy     $48
        beq     spawn_scan_forward
        lda     $B5FF,y
        cmp     $0B
        bcc     spawn_scan_forward
        bne     spawn_backward_despawn
        lda     $B6FF,y
        cmp     $0A
        bcc     spawn_scan_forward
spawn_backward_despawn:  dey
        jsr     activate_primary_entity
        dec     $48
        bne     spawn_scan_backward
spawn_scan_forward:  ldy     $49
        beq     spawn_forward_done
spawn_forward_check:  lda     $B5FF,y
        cmp     $09
        bcc     spawn_forward_done
        bne     spawn_forward_skip
        lda     $B6FF,y
        cmp     jump_ptr
        bcc     spawn_forward_done
spawn_forward_skip:  dey
        bne     spawn_forward_check
spawn_forward_done:  sty     $49
spawn_secondary_backward:  ldy     $4C
        beq     spawn_secondary_forward
        lda     $B9FF,y
        cmp     $0B
        bcc     spawn_secondary_forward
        bne     spawn_sec_check_active
        lda     $BA3F,y
        cmp     $0A
        bcc     spawn_secondary_forward
spawn_sec_check_active:  lda     $013F,y
        beq     spawn_sec_backward_next
        dey
        jsr     activate_secondary_entity
spawn_sec_backward_next:  dec     $4C
        bne     spawn_secondary_backward
spawn_secondary_forward:  ldy     $4D
        beq     spawn_sec_forward_done
spawn_sec_forward_check:  lda     $B9FF,y
        cmp     $09
        bcc     spawn_sec_forward_done
        bne     spawn_sec_forward_skip
        lda     $BA3F,y
        cmp     jump_ptr
        bcc     spawn_sec_forward_done
spawn_sec_forward_skip:  dey
        bne     spawn_sec_forward_check
spawn_sec_forward_done:  sty     $4D
        jmp     spawn_scan_done

spawn_scan_right_scroll:  ldy     $49
        lda     $09
        cmp     $B600,y
        bcc     spawn_right_backward
        bne     spawn_right_activate
        lda     jump_ptr
        cmp     $B700,y
        bcc     spawn_right_backward
spawn_right_activate:  jsr     activate_primary_entity
        inc     $49
        bne     spawn_scan_right_scroll
spawn_right_backward:  ldy     $48
spawn_right_back_check:  lda     $0B
        cmp     $B600,y
        bcc     spawn_right_back_done
        bne     spawn_right_back_skip
        lda     $0A
        cmp     $B700,y
        bcc     spawn_right_back_done
spawn_right_back_skip:  iny
        bne     spawn_right_back_check
spawn_right_back_done:  sty     $48
spawn_right_sec_forward:  ldy     $4D
        lda     $09
        cmp     $BA00,y
        bcc     spawn_right_sec_backward
        bne     spawn_right_sec_check
        lda     jump_ptr
        cmp     $BA40,y
        bcc     spawn_right_sec_backward
spawn_right_sec_check:  lda     $0140,y
        beq     spawn_right_sec_next
        jsr     activate_secondary_entity
spawn_right_sec_next:  inc     $4D
        bne     spawn_right_sec_forward
spawn_right_sec_backward:  ldy     $4C
spawn_right_sec_back_chk:  lda     $0B
        cmp     $BA00,y
        bcc     spawn_right_sec_back_done
        bne     spawn_right_sec_back_skip
        lda     $0A
        cmp     $BA40,y
        bcc     spawn_right_sec_back_done
spawn_right_sec_back_skip:  iny
        bne     spawn_right_sec_back_chk
spawn_right_sec_back_done:  sty     $4C
spawn_scan_done:  lda     #$0E          ; switch back to game engine
        jsr     bank_switch
        rts

; =============================================================================
; activate_primary_entity — Activate an enemy entity from stage spawn data ($C753)
; =============================================================================
activate_primary_entity:  tya
        ldx     #$0F
activate_check_dup:  cmp     $0100,x    ; check for duplicate spawn
        beq     entity_activate_done
        dex
        bpl     activate_check_dup
        jsr     find_empty_entity_slot
        bcs     entity_activate_done
        tya
        sta     $0100,x
        lda     $B600,y
        sta     $0450,x
        lda     $B700,y
        sta     $0470,x
        lda     $B800,y
        sta     $04B0,x
        lda     $B900,y
entity_init_from_type:  sta     $0410,x ; store enemy type ID
        tay
        pha
        lda     entity_flags_table,y    ; look up default entity flags
        sta     $0430,x                 ; store entity spawn flags
        lda     entity_ai_behavior_tbl,y ; look up AI behavior index
        sta     $06F0,x                 ; store entity AI behavior
        lda     #$14                    ; default entity timer (20 frames)
        sta     $06D0,x
        lda     entity_hitbox_width_idx_tbl,y
        tay
        lda     hitbox_width_lo_tbl,y
        sta     $0610,x
        lda     hitbox_width_hi_tbl,y
        sta     $0630,x
        pla
        tay
        lda     entity_hitbox_height_idx_tbl,y
        tay
        lda     hitbox_height_lo_tbl,y
        sta     $0650,x
        lda     hitbox_height_hi_tbl,y
        sta     $0670,x
        lda     #$00
        sta     $06B0,x
        sta     $0690,x
        sta     $04F0,x
        sta     $0120,x
        sta     $0490,x
        sta     $04D0,x
        sta     $0110,x
entity_activate_done:  rts

; =============================================================================
; activate_secondary_entity — Activate a secondary entity from spawn data ($C7CC)
; =============================================================================
activate_secondary_entity:  tya
        ldx     #$0F
activate_sec_check_dup:  cmp     $0130,x
        beq     entity_activate_done
        dex
        bpl     activate_sec_check_dup
        jsr     find_empty_entity_slot
        bcs     entity_activate_done
        tya
        pha
        sta     $0130,x
        lda     $BA00,y
        sta     $0450,x
        lda     $BA40,y
        sta     $0470,x
        lda     $BA80,y
        sta     $04B0,x
        lda     $BAC0,y
        jsr     entity_init_from_type
        pla
        sta     $0120,x
        tay
        lda     $0140,y
        sta     $06D0,x
        rts

entity_flags_table:  .byte   $83,$83,$A0,$A0,$83,$A0,$80,$A0 ; default flags per entity type
        .byte   $83,$A0,$83,$83,$83,$87,$80,$83
        .byte   $83,$A0,$80,$80,$A0,$A0,$8B,$87
        .byte   $81,$83,$80,$81,$A0,$A3,$A0,$87
        .byte   $A0,$A0,$83,$83,$85,$A0,$A0,$A0
        .byte   $A0,$83,$87,$A0,$87,$92,$B0,$B0
        .byte   $83,$87,$AB,$87,$8F,$81,$83,$A0
        .byte   $83,$A0,$80,$84,$83,$83,$80,$85
        .byte   $A0,$A0,$A0,$A0,$8B,$83,$83,$A0
        .byte   $83,$83,$A0,$83,$C3,$85,$83,$8F
        .byte   $83,$83,$A1,$A0,$A0,$A0,$A0,$92
        .byte   $81,$81,$81,$85,$81,$8B,$81,$81
        .byte   $80,$8B,$81,$80,$A0,$8B,$8B,$80
        .byte   $81,$8B,$87,$81,$80,$83,$81,$81
        .byte   $80,$A3,$81,$81,$85,$00,$81,$81
        .byte   $81,$81,$81,$81,$81,$81,$81,$00
entity_hitbox_width_idx_tbl:  .byte   $00,$02,$02,$02,$02,$02,$02,$02 ; hitbox width table index per type
        .byte   $02,$02,$04,$06,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$08,$02,$02
        .byte   $02,$02,$02,$0A,$02,$02,$02,$0C
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$1C,$0E,$0E
        .byte   $02,$10,$02,$02,$02,$02,$02,$02
        .byte   $12,$02,$02,$14,$02,$02,$02,$16
        .byte   $02,$02,$02,$02,$02,$18,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$1A,$1A,$1A,$02,$0E
        .byte   $02,$02,$08,$14,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$08,$1E,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02
entity_hitbox_height_idx_tbl:  .byte   $00,$02,$02,$02,$04,$02,$04,$04 ; hitbox height table index per type
        .byte   $06,$04,$02,$08,$02,$08,$0A,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$01,$02,$0E,$0C,$02,$02,$02
        .byte   $02,$02,$02,$02,$10,$02,$02,$02
        .byte   $02,$02,$02,$02,$04,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$0A,$10,$02,$02,$02
        .byte   $10,$02
        .byte   $02,$02
entity_hitbox_height_idx_2:  .byte   $02,$20,$02,$02,$02,$14,$16,$02
        .byte   $02,$02,$02,$02,$18,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $1C,$02,$02,$02,$02,$02,$02,$10
        .byte   $02,$02,$02,$02,$14,$02,$02,$02
        .byte   $1E,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02,$02,$02,$02
        .byte   $02,$02,$02,$02,$02
entity_ai_behavior_tbl:  .byte   $00,$00,$00,$01,$01,$01,$01,$01 ; AI behavior index per entity type
        .byte   $02,$02,$01,$01,$01,$04,$00,$05
        .byte   $06,$01,$01,$01,$07,$07,$02,$01
        .byte   $04,$08,$02,$04,$08,$09,$00,$00
        .byte   $00,$00,$07,$09,$07,$00,$00,$00
        .byte   $00,$09,$00,$00,$00,$10,$00,$00
        .byte   $05,$07,$0A,$07,$07,$04,$09,$00
        .byte   $07,$00,$07,$04,$04,$01,$03,$07
        .byte   $0B,$0B,$00,$00,$07,$07,$07,$00
        .byte   $0C,$0C,$00,$01,$01,$04,$0D,$01
        .byte   $0E,$0F,$0A
        .byte   $00
        .byte   $00,$00,$13,$10,$04,$04,$0E,$07
        .byte   $07,$07,$07,$07,$00,$12,$07,$00
        .byte   $00,$13,$00,$00,$02,$00,$07,$09
        .byte   $00,$04,$04,$04,$00,$0D,$04,$04
        .byte   $04,$00,$07,$04,$07,$04,$07,$07
        .byte   $15,$15,$15,$00
hitbox_width_lo_tbl:  .byte   $01
hitbox_width_hi_tbl:  .byte   $E3,$00,$00,$00,$83,$00,$C4,$04
        .byte   $40,$03,$80,$01,$A9,$F0,$E0,$00
        .byte   $41,$02,$0C,$01,$00,$01,$40,$00
        .byte   $6C,$F0,$F0,$F0,$C0,$01,$77
hitbox_height_lo_tbl:  .byte   $00
hitbox_height_hi_tbl:  .byte   $C7,$00,$00,$FF,$5D,$FE,$98,$04
        .byte   $E6,$01,$00,$F8,$00,$FC,$00,$04
        .byte   $00,$01,$47,$08,$00,$F8,$00,$02
        .byte   $D4,$02,$00,$03,$76,$FC,$8A,$00
        .byte   $20
find_empty_entity_slot:  ldx     #$0F
find_slot_loop:  lda     $0430,x
        bpl     find_slot_found
        dex
        bpl     find_slot_loop
        sec
        rts

find_slot_found:  clc
        rts

        lda     $F9
        bne     *+23
        ldx     $A9
        beq     *+6
        lda     $9B,x
        beq     *+15
        lda     weapon_dispatch_lo_tbl,x
        sta     jump_ptr
        lda     weapon_dispatch_hi_tbl,x
        sta     $09
        jmp     (jump_ptr)

        sec
        rts

        lda     $27
        and     #$02
        beq     fire_weapon_no_slot
        ldx     #$04
fire_weapon_scan_slot:  lda     $0420,x
        bpl     fire_weapon_found_slot
        dex
        cpx     #$01
        bne     fire_weapon_scan_slot
        beq     fire_weapon_no_slot
fire_weapon_found_slot:  lda     #$24
        jsr     bank_switch_enqueue
        ldy     #$00
        jsr     weapon_spawn_projectile
fire_weapon_set_timer:  lda     #$0F
        sta     $36
        lda     #$01
fire_weapon_set_dir:  sta     $3D
        ldx     $2C
        clc
        adc     weapon_base_type_tbl,x
        sta     $0400
        clc
        rts

fire_weapon_no_slot:  sec
        rts

        lda     $27
        and     #$02
        beq     *+14
        ldx     #$02
        ldy     #$01
        jsr     weapon_spawn_projectile
        lda     #$82
        sta     $0420,x
        sec
        rts

        lda     $27
        and     #$02
        beq     fire_weapon_multi_fail
        ldx     #$04
fire_weapon_multi_scan:  lda     $0420,x
        bmi     fire_weapon_multi_fail
        dex
        cpx     #$01
        bne     fire_weapon_multi_scan
        ldx     #$04
fire_weapon_multi_loop:  stx     $01
        ldy     #$02
        jsr     weapon_spawn_projectile
        ldx     $01
        dex
        cpx     #$01
        bne     fire_weapon_multi_loop
        lda     #$3F
        jsr     bank_switch_enqueue
        sec
        lda     $9D
        sbc     #$02
        sta     $9D
        jmp     fire_weapon_set_timer

fire_weapon_multi_fail:  sec
        rts

        lda     $27
        and     #$02
        beq     *+30
        lda     $0422
        bmi     *+25
        sec
        lda     $9E
        sbc     #$03
        bcc     *+18
        ldx     #$05
fire_weapon_spread_loop:  stx     $02
        ldy     #$03
        jsr     weapon_spawn_projectile
        ldx     $02
        dex
        cpx     #$01
        bne     fire_weapon_spread_loop
        sec
        rts

        lda     $27
        and     #$02
        beq     fire_weapon_bubble_fail
        ldx     #$03
fire_weapon_bubble_scan:  lda     $0420,x
        bpl     fire_weapon_bubble_fire
        dex
        cpx     #$01
        bne     fire_weapon_bubble_scan
        beq     fire_weapon_bubble_fail
fire_weapon_bubble_fire:  ldy     #$04
        jsr     weapon_spawn_projectile
        lda     #$24
        jsr     bank_switch_enqueue
        inc     $AC
        lda     $AC
        cmp     #$02
        bne     fire_weapon_bubble_done
        lda     #$00
        sta     $AC
        dec     $9F
fire_weapon_bubble_done:  jmp     fire_weapon_set_timer

fire_weapon_bubble_fail:  sec
        rts

        lda     $27
        and     #$02
        bne     *+12
        lda     $AB
        cmp     #$0B
        beq     *+6
        inc     $AB
        clc
        rts
        ldx     #$05
fire_weapon_leaf_scan:  lda     $0420,x
        bpl     fire_weapon_leaf_fire
        dex
        cpx     #$01
        bne     fire_weapon_leaf_scan
        beq     fire_weapon_leaf_fail
fire_weapon_leaf_fire:  ldy     #$05
        jsr     weapon_spawn_projectile
        lda     #$24
        jsr     bank_switch_enqueue
        inc     $AC
        lda     $AC
        cmp     #$08
        bne     fire_weapon_leaf_reset
        lda     #$00
        sta     $AC
        dec     $A0
fire_weapon_leaf_reset:  lda     #$00
        sta     $AB
        jmp     fire_weapon_set_timer

fire_weapon_leaf_fail:  sec
        rts

        lda     $27
        and     #$02
        beq     *+31
        lda     $0422
        bmi     *+26
        sec
        lda     $A3
        sbc     #$04
        bcc     *+19
        sta     $A3
        ldx     #$02
        ldy     #$06
        jsr     weapon_spawn_projectile
        lda     #$24
        jsr     bank_switch_enqueue
        jmp     fire_weapon_set_timer
        sec
        rts

        lda     $27
        and     #$02
        beq     fire_weapon_crash_fail
        ldx     #$04
fire_weapon_crash_scan:  lda     $0420,x
        bpl     fire_weapon_crash_fire
        dex
        cpx     #$01
        bne     fire_weapon_crash_scan
        beq     fire_weapon_crash_fail
fire_weapon_crash_fire:  ldy     #$07
        jsr     weapon_spawn_projectile
        lda     #$23
        jsr     bank_switch_enqueue
        inc     $AC
        lda     $AC
        cmp     #$04
        bne     fire_weapon_crash_aim
        lda     #$00
        sta     $AC
        dec     $A2
fire_weapon_crash_aim:  lda     $23
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     crash_yvel_sub_tbl,y
        sta     $0660,x
        lda     crash_yvel_tbl,y
        sta     $0640,x
        lda     crash_xvel_sub_tbl,y
        sta     $0620,x
        lda     crash_xvel_tbl,y
        sta     $0600,x
        jmp     fire_weapon_finish

fire_weapon_crash_fail:  sec
        rts

crash_yvel_sub_tbl:  .byte   $00,$00,$00,$00,$00,$D4,$2C,$00
        .byte   $00,$D4,$2C,$00,$00,$00,$00,$00
crash_yvel_tbl:  .byte   $00,$04,$FC,$00,$00,$02,$FD,$00
        .byte   $00,$02,$FD,$00,$00,$00,$00,$00
crash_xvel_sub_tbl:  .byte   $00,$00,$00,$00,$00,$D4,$D4,$00
        .byte   $00,$D4,$D4,$00,$00,$00,$00,$00
crash_xvel_tbl:  .byte   $04,$00,$00,$00,$04,$02,$02,$00
        .byte   $04,$02,$02,$00,$00,$00,$00,$00
        lda     $27
        and     #$02
        beq     *+33
        ldx     #$02
        lda     $0422
        bmi     *+26
        ldy     #$08
        jsr     weapon_spawn_projectile
        lda     #$01
        sta     $05A6
        lda     #$21
        jsr     bank_switch_enqueue
fire_weapon_finish:  lda     #$0F
        sta     $36
        lda     #$03
        jmp     fire_weapon_set_dir

        sec
        rts

        lda     $27
        and     #$02
        beq     *-6
        ldx     #$04
fire_weapon_star_scan:  lda     $0420,x
        bpl     fire_weapon_star_fire
        dex
        cpx     #$01
        bne     fire_weapon_star_scan
        beq     fire_weapon_star_fail
fire_weapon_star_fire:  ldy     #$09
        jsr     weapon_spawn_projectile
        sec
        lda     $A4
        sbc     #$02
        sta     $A4
        jmp     fire_weapon_finish

fire_weapon_star_fail:  sec
        rts

        lda     $27
        and     #$02
        beq     *+27
        lda     $0422
        bmi     *+22
        ldx     #$02
        ldy     #$0A
        jsr     weapon_spawn_projectile
        lda     #$3E
        sta     $04E2
        lda     #$13
        sta     $06C2
        jmp     fire_weapon_finish
        rts
        lda     $27
        and     #$02
        beq     *+22
        lda     $0422
        bmi     *+17
        ldx     #$02
        ldy     #$0B
        jsr     weapon_spawn_projectile
        lda     #$1F
        sta     $06C2
        jmp     fire_weapon_finish
        rts
weapon_dispatch_lo_tbl:  .byte   $6C,$9F,$B3,$E6,$0A,$3B,$31,$9F
        .byte   $7A,$58,$7D,$9D
weapon_dispatch_hi_tbl:  .byte   $DA,$DA,$DA,$DA,$DB,$DB,$DC,$DB
        .byte   $DB,$DC,$DC,$DC

; =============================================================================
; update_entity_positions — Update screen-relative positions for all active entities ($DCD0)
; =============================================================================
update_entity_positions:  ldx     #$0F  ; start at entity slot 15
update_entity_loop:  stx     $2B
        lda     $0420,x                 ; check if entity is active
        bpl     update_entity_next
        and     #$02
        bne     update_entity_special
        sec
        lda     $0460,x
        sbc     $1F                     ; subtract scroll X for screen pos
        sta     $06E0,x                 ; store screen-relative X
        jsr     apply_entity_physics    ; apply velocity and gravity
update_entity_next:  ldx     $2B
        dex
        cpx     #$01
        bne     update_entity_loop
        rts

update_entity_special:  lda     #$DC
        pha
        lda     #$E8
        pha
        sec
        lda     $0460,x
        sbc     $1F
        sta     $06E0,x
        sec
        lda     $0400,x
        sbc     #$2F
        tay
        lda     entity_special_dispatch_lo,y
        sta     jump_ptr
        lda     entity_special_dispatch_hi,y
        sta     $09
        jmp     (jump_ptr)

entity_special_dispatch_lo:  .byte   $34,$34,$48,$74,$6F,$CE,$16,$58
        .byte   $58,$90,$10,$DD,$71,$E4,$E4,$E8
entity_special_dispatch_hi:  .byte   $DD,$DD,$DE,$DE,$DF,$DF,$E0,$E1
        .byte   $E1,$E1,$E2,$E2,$E4,$E4,$E4,$E4
        lda     $04E0,x
        beq     *+5
        jmp     $DDEC
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        lda     $AC
        cmp     #$FF
        beq     etank_check_threshold
        inc     $AC
etank_check_threshold:  ldy     #$02
        lda     $AC
        cmp     #$7D
        bcc     etank_set_anim
        iny
        iny
        cmp     #$BB
        bcc     etank_set_anim
        iny
        iny
etank_set_anim:  sty     $00
        lda     $1C
        and     #$04
        bne     etank_animate
        ldy     #$00
etank_animate:  jsr     etank_update_palette
        lda     $04A0
        sta     $04A0,x
        lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $00
        lsr     a
        tay
        lda     etank_cost_tbl,y
        cmp     $9C
        bcc     etank_check_fire
        beq     etank_check_fire
        ldy     #$00
        sty     $AC
        jsr     etank_update_palette
        lsr     $0420,x
        rts

etank_check_fire:  lda     $23
        and     #$02
        beq     etank_reset_counter
        rts

etank_reset_counter:  ldy     #$00
        sty     $AC
        jsr     etank_update_palette
        lsr     $0422
        ldx     #$04
etank_find_projectile:  lda     $0420,x
        bpl     etank_spawn_projectile
        dex
        cpx     #$02
        bne     etank_find_projectile
etank_done:  rts

etank_spawn_projectile:  lda     $F9
        bne     etank_deduct_ammo
        ldy     #$01
        jsr     weapon_spawn_projectile
        lda     $00
        lsr     a
        sta     $04E0,x
        sta     $0590,x
        tay
        lda     etank_anim_frame_tbl,y
        sta     $06A0,x
        sec
        lda     $0460,x
        sbc     $1F
        sta     $06E0,x
etank_deduct_ammo:  sec
        lda     $9C
        sbc     etank_cost_tbl,y
        sta     $9C
        lda     #$38
        jsr     bank_switch_enqueue
        lda     #$04
        sta     $0600,x
        lda     $2C
        beq     etank_done
        jmp     fire_weapon_set_timer

        cmp     #$02
        bcs     etank_weapon_mid
        lda     $06A0,x
        cmp     #$03
        bne     etank_apply_physics
        lda     #$01
        bne     etank_weapon_set_anim
etank_weapon_mid:  bne     etank_weapon_high
        lda     $06A0,x
        cmp     #$06
        bne     etank_apply_physics
        lda     #$04
        bne     etank_weapon_set_anim
etank_weapon_high:  lda     $06A0,x
        cmp     #$09
        bne     etank_apply_physics
        lda     #$07
etank_weapon_set_anim:  sta     $06A0,x
etank_apply_physics:  jsr     apply_entity_physics
        rts

etank_update_palette:  lda     etank_palette_lo_tbl,y
        sta     $0367
        lda     etank_palette_hi_tbl,y
        sta     $0369
        lda     $1C
        and     #$07
        bne     etank_palette_done
        lda     $00
        lsr     a
        tay
        lda     etank_sound_bank_tbl,y
        jsr     bank_switch_enqueue
etank_palette_done:  rts

etank_sound_bank_tbl:  .byte   $35,$35,$36,$37
etank_palette_lo_tbl:  .byte   $0F
etank_palette_hi_tbl:  .byte   $15,$31,$15,$35,$2C,$30,$30
etank_anim_frame_tbl:  .byte   $00,$01,$04
etank_cost_tbl:  .byte   $07,$01,$06,$0A,$8A,$38,$E9,$02
        .byte   $A8,$B9,$6E,$DE,$9D,$20,$06,$B9
        .byte   $71,$DE,$9D,$00,$06,$18,$BD,$60
        .byte   $06,$69,$10,$9D,$60,$06,$BD,$40
        .byte   $06,$69,$00,$9D,$40,$06,$20,$EF
        .byte   $EE,$60,$19,$99,$33,$01,$01,$02
        .byte   $BD,$E0,$04,$D0,$74,$A9,$00,$9D
        .byte   $80,$06,$BD,$C0,$06,$85,$01,$8A
        .byte   $38,$E9,$02,$85,$00,$29,$01,$D0
        .byte   $11,$38,$AD,$60,$04,$E5,$01,$9D
        .byte   $60,$04,$AD,$40,$04,$E9,$00,$4C
        .byte   $AC,$DE
        clc
        lda     $0460
        adc     $01
        sta     $0460,x
        lda     $0440
        adc     #$00
        sta     $0440,x
        lda     $00
        and     #$02
        bne     crash_bomb_add_y
        sec
        lda     $04A0
        sbc     $01
        jmp     crash_bomb_store_y

crash_bomb_add_y:  clc
        lda     $04A0
        adc     $01
crash_bomb_store_y:  sta     $04A0,x
        lda     $01
        cmp     #$0C
        beq     crash_bomb_explode
        clc
        adc     #$02
        sta     $06C0,x
        rts

crash_bomb_explode:  lsr     $0423
        lsr     $0424
        lsr     $0425
        lda     #$83
        sta     $0422
        lda     #$01
        sta     $04E2
        lda     #$01
        sta     $06A2
        rts

        lda     $F9
        beq     bubble_check_anim
        lda     #$06
        bne     bubble_set_anim
bubble_check_anim:  lda     $06A0,x
        cmp     #$05
        bcc     bubble_check_state
        lda     #$01
bubble_set_anim:  sta     $06A0,x
bubble_check_state:  lda     $04E0,x
        cmp     #$01
        bne     bubble_apply_physics
        lda     $1C
        and     #$07
        bne     bubble_track_player
        lda     #$31
        jsr     bank_switch_enqueue
bubble_track_player:  lda     $0460
        sta     $0460,x
        lda     $0440
        sta     $0440,x
        lda     $04A0
        sta     $04A0,x
        lda     $F9
        beq     bubble_check_input
        lda     #$00
        sta     $04A0,x
bubble_check_input:  lda     $23
        and     #$F0
        beq     bubble_done
        ldy     $F9
        beq     bubble_check_direction
        lsr     $0420,x
        rts

bubble_check_direction:  and     #$C0
        beq     bubble_check_up_down
        lsr     a
        and     #$40
        ora     #$83
        sta     $0420,x
        lda     #$04
        sta     $0600,x
        bne     bubble_deduct_ammo
bubble_check_up_down:  ldy     #$00
        lda     $23
        and     #$10
        bne     bubble_set_yvel
        iny
bubble_set_yvel:  lda     bubble_yvel_tbl,y
        sta     $0640,x
bubble_deduct_ammo:  sec
        lda     $9E
        sbc     #$03
        sta     $9E
        inc     $04E0,x
bubble_done:  rts

bubble_apply_physics:  jsr     apply_entity_physics
        rts

bubble_yvel_tbl:  .byte   $04,$FC
        lda     #$07
        sta     $01
        lda     #$07
        sta     $02
        jsr     check_horiz_tile_collision
        lda     $04E0,x
        bne     *+34
        lda     $00
        beq     metal_blade_physics
        inc     $04E0,x
        lda     $0420,x
        and     #$FB
        sta     $0420,x
metal_blade_launch:  lda     #$C0
        sta     $0660,x
        lda     #$FF
        sta     $0640,x
        lda     #$02
        sta     $0600,x
        bne     metal_blade_physics
        cmp     #$01
        bne     metal_blade_check_stop
        lda     $03
        beq     metal_blade_check_wall
        lsr     $0420,x
        rts

metal_blade_check_wall:  lda     $00
        bne     metal_blade_physics
        lda     #$00
        sta     $0600,x
        sta     $0660,x
        lda     #$FE
        sta     $0640,x
        inc     $04E0,x
        bne     metal_blade_physics
metal_blade_check_stop:  lda     $00
        beq     metal_blade_physics
        dec     $04E0,x
        bne     metal_blade_launch
metal_blade_physics:  jsr     apply_entity_physics
        rts

        .byte   $BD,$E0,$04,$C9,$12,$B0,$14,$38
        .byte   $BD,$60,$06,$E9,$4B,$9D,$60,$06
        .byte   $BD
        .byte   $40

        .byte   $06,$E9
        .byte   $00
        .byte   $9D,$40,$06,$4C,$0F,$E0
        bne     metal_blade_check_despawn
        lda     $0420,x
        eor     #$40
        sta     $0420,x
metal_blade_check_despawn:  lda     $04E0,x
        cmp     #$23
        bne     metal_blade_accelerate
        lsr     $0420,x
        rts

metal_blade_accelerate:  clc
        lda     $0660,x
        adc     #$4B
        sta     $0660,x
        lda     $0640,x
        adc     #$00
        sta     $0640,x
        inc     $04E0,x
        jsr     apply_entity_physics
        rts

        lda     $04E0,x
        bne     *+121
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $0A
        lda     #$00
        sta     $0B
        lda     $0420,x
        and     #$40
        bne     *+18
        sec
        lda     $0460,x
        sbc     #$06
        sta     $08
        lda     $0440,x
        sbc     #$00
        jmp     $E053
        clc
        lda     $0460,x
        adc     #$06
        sta     jump_ptr
        lda     $0440,x
        adc     #$00
        sta     $09
        jsr     lookup_cached_tile
        ldy     $00
        ldx     $2B
        lda     tile_solid_flag_tbl,y
        bne     quick_boomerang_hit
        clc
        lda     $0A
        adc     #$10
        sta     $0A
        jsr     lookup_cached_tile
        ldy     $00
        ldx     $2B
        lda     tile_solid_flag_tbl,y
        bne     quick_boomerang_hit
        jsr     apply_entity_physics
        rts

quick_boomerang_hit:  lda     #$2E
        jsr     bank_switch_enqueue
        lda     $0420,x
        and     #$FE
        sta     $0420,x
        inc     $06A0,x
        inc     $04E0,x
        lda     #$7E
        sta     $06C0,x
        bne     quick_boomerang_bounds
        cmp     #$01
        bne     quick_boomerang_phase2
        lda     $06A0,x
        cmp     #$04
        bne     quick_boomerang_phase1
        lda     #$02
        sta     $06A0,x
quick_boomerang_phase1:  dec     $06C0,x
        bne     quick_boomerang_bounds
        lda     #$05
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        lda     #$38
        sta     $06C0,x
        inc     $04E0,x
quick_boomerang_bounds:  jsr     check_entity_on_screen
        rts

quick_boomerang_phase2:  lda     #$00
        sta     $0680,x
        lda     $06C0,x
        and     #$07
        bne     quick_boomerang_dec_hp
        lda     #$2B
        jsr     bank_switch_enqueue
        lda     $06C0,x
        lsr     a
        and     #$0C
        sta     $02
        lda     #$06
        sta     $01
quick_boomerang_scatter:  lda     $01
        cmp     #$02
        beq     quick_boomerang_dec_hp
        sta     $00
        ldy     #$0C
        jsr     spawn_weapon_from_entity
        ldy     $00
        ldx     $02
        clc
        lda     $04A0,y
        adc     scatter_offset_y_tbl,x
        sta     $04A0,y
        clc
        lda     $0460,y
        adc     scatter_offset_x_lo_tbl,x
        sta     $0460,y
        lda     $0440,y
        adc     scatter_offset_x_hi_tbl,x
        sta     $0440,y
        ldx     $2B
        inc     $02
        dec     $01
        bne     quick_boomerang_scatter
quick_boomerang_dec_hp:  ldx     $2B
        dec     $06C0,x
        bpl     quick_boomerang_check
        lsr     $0420,x
        rts

quick_boomerang_check:  jsr     check_entity_on_screen
        rts

scatter_offset_y_tbl:  .byte   $F8,$F0,$08,$00,$F8,$F8
scatter_offset_y_2:  .byte   $08
        .byte   $00
        .byte   $F0,$00
        .byte   $10,$10
        .byte   $F0,$F8
        .byte   $08
        .byte   $08
scatter_offset_x_lo_tbl:  .byte   $F8
        .byte   $08
        .byte   $00
        .byte   $10,$F8,$10,$F0,$08,$00,$00,$F8
        .byte   $10
scatter_offset_x_lo_2:  .byte   $F0,$10
        .byte   $F0,$08
scatter_offset_x_hi_tbl:  .byte   $FF,$00,$00,$00,$FF,$00,$FF,$00
scatter_offset_x_hi_2:  .byte   $00,$00,$FF,$00,$FF,$00
scatter_offset_x_hi_3:  .byte   $FF,$00
tile_solid_flag_tbl:  .byte   $00,$01,$00,$00,$00,$01,$01,$01
        .byte   $01
        dec     $0620,x
        bne     *+23
        lda     #$0F
        sta     $0620,x
        dec     $A1
        bne     *+14
        lsr     $0420,x
        lda     #$00
        sta     $AA
        lda     #$01
        sta     $50
        rts
        lda     #$01
        sta     $AA
        lda     #$00
        sta     $50
        sta     $4F
        lda     #$80
        sta     $04A0,x
        clc
        adc     $1F
        sta     $0460,x
        lda     $0440
        adc     #$00
        sta     $0440,x
        rts

        lda     $04E0,x
        bne     *+37
        inc     $06C0,x
        lda     $06C0,x
        cmp     #$BB
        beq     *+17
        lda     $06A0,x
        cmp     #$02
        bne     *+7
        lda     #$00
        sta     $06A0,x
        jmp     air_shooter_collision

        lda     #$3E
        sta     $06C0,x
        inc     $04E0,x
        bne     air_shooter_collision
        cmp     #$01
        bne     air_shooter_physics
        lda     $06A0,x
        cmp     #$07
        bne     air_shooter_dec_timer
        lda     #$03
        sta     $06A0,x
air_shooter_dec_timer:  dec     $06C0,x
        beq     air_shooter_end_phase
air_shooter_collision:  sec
        lda     $04A0,x
        sbc     #$04
        sta     $05A1,x
        lda     #$14
        sta     $059E,x
        lda     #$0B
        sta     $01
        lda     #$1D
        sta     $02
        lda     #$04
        sta     $03
        jsr     check_wall_collision
        lda     $00
        beq     air_shooter_physics
        lda     #$00
        sta     $0660,x
air_shooter_end_phase:  lda     #$02
        sta     $04E0,x
        lda     #$08
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        sta     $059E,x
air_shooter_physics:  jsr     apply_entity_physics
        bcc     air_shooter_done
        lda     #$00
        sta     $059E,x
air_shooter_done:  rts

        lda     $04E0,x
        beq     *+7
        dec     $04E0,x
        bne     leaf_shield_wall_check
        dec     $06C0,x
        bne     leaf_shield_accel
        lda     #$13
        sta     $06C0,x
        dec     $A5
        bne     leaf_shield_accel
leaf_shield_deactivate:  lda     #$05
        sta     $06A0,x
        lda     #$00
        sta     $05A0
        sta     $0600,x
        sta     $0620,x
        sta     $0680,x
        lda     #$80
        sta     $0420,x
        beq     leaf_shield_accel
        jmp     leaf_shield_physics

leaf_shield_accel:  lda     $0600,x
        cmp     #$02
        beq     leaf_shield_wall_check
        clc
        lda     $0620,x
        adc     #$08
        sta     $0620,x
        lda     $0600,x
        adc     #$00
        sta     $0600,x
        cmp     #$02
        bne     leaf_shield_wall_check
        lda     #$00
        sta     $0620,x
leaf_shield_wall_check:  lda     #$0F
        sta     $01
        lda     #$08
        sta     $02
        jsr     check_horiz_tile_collision
        lda     $03
        bne     leaf_shield_deactivate
        sec
        lda     $04A0,x
        sbc     #$20
        sta     $0A
        lda     #$00
        sta     $0B
        sec
        lda     $0460,x
        sbc     #$10
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
        sta     $09
        jsr     lookup_cached_tile
        ldx     $2B
        ldy     $00
        lda     tile_solid_flag_tbl,y
        bne     leaf_shield_fail
        clc
        lda     jump_ptr
        adc     #$20
        sta     jump_ptr
        lda     $09
        adc     #$00
        sta     $09
        jsr     lookup_cached_tile
        ldx     $2B
        ldy     $00
        lda     tile_solid_flag_tbl,y
        beq     leaf_shield_hitbox
leaf_shield_fail:  jmp     leaf_shield_deactivate

leaf_shield_hitbox:  sec
        lda     $04A0,x
        sbc     #$04
        sta     $05A1,x
        lda     #$18
        sta     $059E,x
        lda     $06A0,x
        cmp     #$04
        bne     leaf_shield_physics
        lda     #$00
        sta     $06A0,x
leaf_shield_physics:  jsr     apply_entity_physics
        bcc     leaf_shield_done
        lda     #$00
        sta     $059E,x
leaf_shield_done:  rts

        .byte   $BD,$E0,$04,$D0
        adc     $BD
        rti

        asl     $85
        .byte   $04
        lda     #$0A
        sta     $01
        lda     #$08
        sta     $02
        jsr     check_horiz_tile_collision
        lda     $03
        beq     time_stopper_check_down
        lda     #$62
        sta     $0660,x
        lda     #$00
        sta     $0640,x
        sta     $0620,x
        sta     $0600,x
        lda     $0420,x
        and     #$FB
        sta     $0420,x
        inc     $04E0,x
        bne     time_stopper_clear_dmg
time_stopper_check_down:  lda     $04
        bpl     time_stopper_clear_dmg
        lda     $00
        beq     time_stopper_clear_dmg
        lda     #$03
        sta     $0640,x
        lda     #$76
        sta     $0660,x
time_stopper_clear_dmg:  lda     #$00
        sta     $0590,x
        lda     $06A0,x
        cmp     #$04
        bne     time_stopper_dec_timer
        lda     #$00
        sta     $06A0,x
time_stopper_dec_timer:  dec     $06C0,x
        bne     time_stopper_physics_jmp
        lda     #$1F
        sta     $06C0,x
        dec     $A6
        beq     time_stopper_finish
time_stopper_physics_jmp:  jmp     time_stopper_physics

        sec
        lda     $04A0,x
        sbc     #$08
        sta     $05A1,x
        lda     #$14
        sta     $059E,x
        lda     #$0C
        sta     $01
        lda     #$21
        sta     $02
        lda     #$08
        sta     $03
        jsr     check_wall_collision
        lda     $04E0,x
        and     #$0F
        cmp     #$02
        bcs     time_stopper_alt_state
        lda     $04E0,x
        bpl     time_stopper_check_done
        inc     $04E0,x
        bne     time_stopper_check_done
time_stopper_check_done:  lda     $00
        bne     time_stopper_finish
        lda     $03
        bne     time_stopper_clear_dmg
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        lda     $06A0,x
        cmp     #$09
        bne     time_stopper_inc_dmg
        lda     #$05
        sta     $06A0,x
time_stopper_inc_dmg:  inc     $0590,x
        lda     $0590,x
        cmp     #$3E
        bcc     time_stopper_dec_timer
time_stopper_finish:  lda     #$0A
        sta     $06A0,x
        lda     #$00
        sta     $0640,x
        sta     $0660,x
        sta     $0680,x
        sta     $059E,x
        lda     #$80
        sta     $0420,x
        rts

time_stopper_alt_state:  lda     $04E0,x
        bpl     time_stopper_check_fall
        and     #$0F
        sta     $04E0,x
        lda     #$62
        sta     $0660,x
        lda     #$00
        sta     $0640,x
        beq     time_stopper_check_done
time_stopper_check_fall:  lda     $0640,x
        bpl     time_stopper_set_vel
        lda     $00
        bne     time_stopper_finish
time_stopper_set_vel:  lda     #$9E
        sta     $0660,x
        lda     #$FF
        sta     $0640,x
        jmp     time_stopper_check_done

time_stopper_physics:  jsr     apply_entity_physics
        bcc     time_stopper_done
        lda     #$00
        sta     $059E,x
time_stopper_done:  rts

check_wall_collision:  lda     $0420,x
        and     #$40
        bne     wall_coll_facing_right
        sec
        lda     $0460,x
        sbc     $01
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
        jmp     wall_coll_store_screen

wall_coll_facing_right:  clc
        lda     $0460,x
        adc     $01
        sta     jump_ptr
        lda     $0440,x
        adc     #$00
wall_coll_store_screen:  sta     $09
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $0A
        lda     #$00
        sbc     #$00
        sta     $0B
        jsr     lookup_cached_tile
        ldx     $2B
        ldy     $00
        lda     wall_solid_flag_tbl,y
        pha
        lda     $0640,x
        bpl     wall_coll_check_below
        clc
        lda     $04A0,x
        adc     $03
        sta     $0A
        lda     #$00
        adc     #$00
        jmp     wall_coll_store_y

wall_coll_check_below:  sec
        lda     $04A0,x
        sbc     $02
        sta     $0A
        lda     #$00
        sbc     #$00
wall_coll_store_y:  sta     $0B
        lda     $0460,x
        sta     jump_ptr
        lda     $0440,x
        sta     $09
        jsr     lookup_cached_tile
        ldx     $2B
        ldy     $00
        lda     wall_solid_flag_tbl,y
        sta     $00
        pla
        sta     $03
        rts

wall_solid_flag_tbl:  .byte   $00,$01,$00,$01,$00,$01,$01,$01 ; wall collision solid flags
        .byte   $01
        lda     #$00
        sta     $0680,x
        lda     $04E0,x
        bne     crash_entity_accelerate
        lda     $06C0,x
        bne     crash_entity_dec_timer
        lda     $0420,x
        eor     #$40
        sta     $0420,x
        inc     $06A0,x
        and     #$40
        beq     crash_entity_reset_vel
        inc     $06A0,x
crash_entity_reset_vel:  lda     #$00
        sta     $0620,x
        sta     $0660,x
        lda     #$FE
        sta     $0640,x
        lda     #$01
        sta     $0600,x
        lda     #$10
        sta     $06C0,x
        inc     $04E0,x
        bne     crash_entity_dec_timer
crash_entity_accelerate:  clc
        lda     $0620,x
        adc     #$40
        sta     $0620,x
        lda     $0600,x
        adc     #$00
        sta     $0600,x
        lda     $06C0,x
        bne     crash_entity_dec_timer
        lda     #$00
        sta     $06A0,x
        sta     $0620,x
        sta     $0600,x
        sta     $0660,x
        sta     $0640,x
        lda     #$02
        sta     $06C0,x
        dec     $04E0,x
crash_entity_dec_timer:  dec     $06C0,x
        jsr     apply_entity_physics
        rts

        jsr     check_entity_on_screen
        rts

        rts
check_entity_on_screen:  sec
        lda     $0460,x
        sbc     $1F
        lda     $0440,x
        sbc     $20
        bcc     entity_off_screen_deactivate
        bne     entity_off_screen_deactivate
        clc
        rts

entity_off_screen_deactivate:  lsr     $0420,x
        sec
        rts

spawn_weapon_from_entity:  lda     $0460,x
        sta     jump_ptr
        lda     $0440,x
        sta     $09
        lda     $04A0,x
        sta     $0A
        ldx     $00
        lda     projectile_type_tbl,y
        sta     $0400,x
        lda     projectile_flags_tbl,y
        sta     $0420,x
        lda     jump_ptr
        sta     $0460,x
        lda     $09
        sta     $0440,x
        lda     $0A
        sta     $04A0,x
        lda     projectile_xvel_sub_tbl,y
        sta     $0620,x
        lda     projectile_xvel_tbl,y
        sta     $0600,x
        lda     projectile_yvel_sub_tbl,y
        sta     $0660,x
        lda     projectile_yvel_tbl,y
        sta     $0640,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        sta     $04E0,x
        sec
        lda     $0460,x
        sbc     $1F
        sta     $06E0,x
        ldx     $2B
        rts

; =============================================================================
; check_player_collision — Check if an enemy entity touches the player (contact damage) ($E55A)
; =============================================================================
check_player_collision:  lda     #$00
        sta     $01
        lda     $2C                     ; weapon select (0=no weapon out)
        beq     player_collision_done
        lda     $BD
        bne     player_collision_done
        lda     $F9                     ; boss fight active flag
        bne     player_collision_done
        sec
        lda     $2D
        sbc     $2E
        bcs     player_coll_check_range
        eor     #$FF
        adc     #$01
player_coll_check_range:  ldy     $06E0,x ; entity screen-relative X
        cmp     contact_damage_range_x_tbl,y ; compare to hitbox width
        bcs     player_collision_done
        sec
        lda     $04A0
        sbc     $04A0,x
        bcs     player_coll_check_y
        eor     #$FF
        adc     #$01
player_coll_check_y:  cmp     contact_damage_range_y_tbl,y ; compare to hitbox height
        bcs     player_collision_done
        ldy     $0400,x
        cpy     #$76
        bcs     player_collision_item
        lda     $4B
        bne     player_collision_done
        sec
        lda     $06C0
        sbc     contact_damage_to_player_tbl,y
        sta     $06C0
        beq     player_coll_kill
        bcs     player_coll_knockback
player_coll_kill:  lda     #$00
        sta     $2C
        sta     $06C0
        jmp     boss_death_sequence     ; player died — run death seq

player_coll_knockback:  lda     $0420
        and     #$BF
        sta     $0420
        lda     $0420,x
        and     #$40
        eor     #$40
        ora     $0420
        sta     $0420
        jsr     fire_weapon_buster
        inc     $01
player_collision_done:  rts

player_collision_item:  lda     $AD
        bne     player_collision_return
        lsr     $0420,x
        sty     $AD
        inc     $01
        lda     $04E0,x
        bne     player_collision_return
        lda     #$FF
        sta     $0120,x
        lda     $0110,x
        tay
        lda     #$00
        sta     $0140,y
player_collision_return:  rts

; =============================================================================
; check_weapon_collision — Check if a weapon projectile hits an enemy entity ($E5EC)
; =============================================================================
check_weapon_collision:  lda     $04A0,x
        sta     $00
        lda     $06E0,x
        sta     jump_ptr
        ldx     #$09                    ; start scanning from weapon slot 9
        lda     $1C
        and     #$01
        bne     weapon_coll_check_slot
        dex
weapon_coll_check_slot:  lda     $0420,x
        bpl     weapon_coll_next_slot
        and     #$01
        beq     weapon_coll_next_slot
        clc
        ldy     $0590,x
        lda     weapon_range_offset_tbl,y
        adc     jump_ptr
        tay
        sec
        lda     $2E
        sbc     $06E0,x
        bcs     weapon_coll_check_range_x
        eor     #$FF
        adc     #$01
weapon_coll_check_range_x:  cmp     contact_damage_range_x_tbl,y ; compare X distance to hitbox
        bcs     weapon_coll_next_slot
        sec
        lda     $00
        sbc     $04A0,x
        bcs     weapon_coll_check_range_y
        eor     #$FF
        adc     #$01
weapon_coll_check_range_y:  cmp     contact_damage_range_y_tbl,y ; compare Y distance to hitbox
        bcc     weapon_collision_dispatch
weapon_coll_next_slot:  dex
        dex
        cpx     #$02
        bcs     weapon_coll_check_slot
        ldx     $2B
        lda     #$00
        sta     $0100,x
        clc
        rts

weapon_collision_dispatch:  ldy     $A9 ; current weapon ID for handler
        lda     weapon_handler_ptr_lo,y ; dispatch to weapon handler
        sta     jump_ptr
        lda     weapon_handler_ptr_hi,y
        sta     $09
        jmp     (jump_ptr)              ; indirect jump to handler

        ldy     $2B
        lda     $0420,y
        and     #$08
        bne     *+54
        lda     $0400,y
        tay
        lda     weapon_damage_table,y
        sta     $00
        beq     *+43
        jsr     apply_difficulty_modifier
        lsr     $0420,x
        lda     #$2B
        jsr     bank_switch_enqueue
        ldx     $2B
        lda     $0100,x
        bne     *+50
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     *+4
        bcs     *+34
        lda     #$00
        sta     $06C0,x
        sec
        rts

        lda     $0420,x
        eor     #$40
        and     #$FE
        sta     $0420,x
        lda     #$05
        sta     $0640,x
        sta     $0600,x
        lda     #$2D
        jsr     bank_switch_enqueue
        ldx     $2B
        clc
        rts

        ldy     $2B
        lda     $0420,y
        and     #$08
        bne     weapon_damage_zero
        lda     $0400,y
        tay
        lda     $04E0,x
        cmp     #$02
        bcc     *+21
        beq     *+8
        lda     $EA14,y
        jmp     weapon_damage_apply
        clc
        lda     weapon_damage_table,y
        asl     a
        adc     weapon_damage_table,y
        jmp     weapon_damage_apply

        lda     weapon_damage_table,y
weapon_damage_apply:  sta     $00
        beq     weapon_damage_zero
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     weapon_damage_done
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     weapon_damage_killed
        bcs     weapon_damage_deactivate_wpn
weapon_damage_killed:  lda     #$00
        sta     $06C0,x
        sec
        rts

weapon_damage_zero:  lda     #$2D
        jsr     bank_switch_enqueue
        lsr     $0420,x
        jmp     weapon_damage_done

weapon_damage_deactivate_wpn:  lda     #$00
        sta     $0420,y
weapon_damage_done:  ldx     $2B
        clc
        rts

        ldy     $2B
        lda     $0420,y
        and     #$08
        bne     *+55
        lda     $0400,y
        tay
        lda     $EA8C,y
        sta     $00
        .byte   $F0
        rol     a
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     weapon_damage_return
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     weapon_damage_killed_alt
        bcs     weapon_damage_deactivate_wpn
weapon_damage_killed_alt:  lda     #$00
        sta     $06C0,x
        sec
        rts

        lda     #$2D
        jsr     bank_switch_enqueue
        lda     $0420,x
        and     #$FE
        sta     $0420,x
        lda     #$3D
        sta     $0400,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        ldx     $2B
weapon_damage_return:  clc
        rts

        ldy     $2B
        lda     $0420,y
        and     #$08
        bne     *+55
        lda     $0400,y
        tay
        lda     $EB04,y
        sta     $00
        beq     *+44
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     *+59
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     *+4
        bcs     weapon_coll_deactivate
        lda     #$00
        sta     $06C0,x
        sec
        rts

        lda     #$2D
        jsr     bank_switch_enqueue
        lda     $0420,x
        and     #$F2
        sta     $0420,x
        lda     #$3B
        sta     $0400,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        sta     $04E0,x
        sta     $06C0,x
weapon_coll_handler_done:  ldx     $2B
        clc
        rts

weapon_coll_deactivate:  lda     #$00
        sta     $0420,y
        beq     weapon_coll_handler_done
        ldy     $2B
        lda     $0420,y
        and     #$08
        bne     weapon_coll_rebound
        lda     $0400,y
        tay
        lda     weapon_damage_table_2,y
        sta     $00
        beq     weapon_coll_rebound
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     weapon_coll_rebound_done
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     weapon_coll_hp_zero
        bcs     weapon_coll_deactivate
weapon_coll_hp_zero:  lda     #$00
        sta     $06C0,x
        sec
        rts

weapon_coll_rebound:  lda     #$00
        sta     $0600,x
        sta     $0620,x
        sta     $0660,x
        lda     #$04
        sta     $0640,x
        lda     #$80
        sta     $0420,x
        lda     #$2D
        jsr     bank_switch_enqueue
        ldx     $2B
weapon_coll_rebound_done:  clc
        rts

        ldy     $2B
        lda     $0420,y
        and     #$08
        bne     *+55
        lda     $0400,y
        tay
        lda     $EBF4,y
        sta     $00
        beq     *+44
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     *+73
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     *+4
        bcs     weapon_coll_deactivate_2
        lda     #$00
        sta     $06C0,x
        sec
        rts

        lda     #$3C
        sta     $0400,x
        lda     $0420,x
        and     #$C0
        eor     #$40
        ora     #$04
        sta     $0420,x
        lda     #$00
        sta     $06A0,x
        sta     $0680,x
        sta     $0600,x
        sta     $0660,x
        lda     #$C0
        sta     $0620,x
        lda     #$04
        sta     $0640,x
        lda     #$2D
        jsr     bank_switch_enqueue
weapon_coll_handler_2_done:  ldx     $2B
        clc
        rts

weapon_coll_deactivate_2:  lda     #$00
        sta     $0420,y
        beq     weapon_coll_handler_2_done
        ldy     $2B
        lda     $0420,y
        and     #$08
        bne     weapon_coll_stun
        lda     $0400,y
        tay
        lda     weapon_damage_table_3,y
        sta     $00
        beq     weapon_coll_stun
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     weapon_coll_stun_done
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     weapon_coll_hp_zero_2
        bcs     weapon_coll_deactivate_2
weapon_coll_hp_zero_2:  lda     #$00
        sta     $06C0,x
        sec
        rts

weapon_coll_stun:  lda     $0400,x
        cmp     #$2F
        beq     weapon_coll_stun_done
        lda     $04E0,x
        cmp     #$02
        beq     weapon_coll_stun_done
        lda     #$05
        sta     $06A0,x
        lda     #$00
        sta     $0680,x
        lda     #$38
        sta     $06C0,x
        inc     $04E0,x
        lda     #$2D
        jsr     bank_switch_enqueue
weapon_coll_stun_done:  ldx     $2B
        clc
        rts

        ldy     $2B
        lda     $0420,y
        and     #$08
        bne     *+55
        lda     $0400,y
        tay
        lda     $ECE4,y
        sta     $00
        beq     *+44
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     bank_switch_enqueue
        pla
        tay
        ldx     $2B
        lda     $0100,x
        bne     *+60
        inc     $0100,x
        sec
        lda     $06C0,x
        sbc     $00
        sta     $06C0,x
        beq     *+4
        bcs     *+46
        lda     #$00
        sta     $06C0,x
        sec
        rts

        lda     #$03
        sta     $0640,x
        lda     #$B2
        sta     $0660,x
        lda     #$01
        sta     $0600,x
        lda     #$87
        sta     $0620,x
        lda     $0420,x
        and     #$F0
        sta     $0420,x
        lda     #$2D
        jsr     bank_switch_enqueue
weapon_coll_handler_3_done:  ldx     $2B
        clc
        rts

        lda     #$00
        sta     $0420,y
        beq     weapon_coll_handler_3_done
apply_difficulty_modifier:  lda     $CB
        bne     difficulty_done
        asl     $00
difficulty_done:  rts

weapon_handler_ptr_lo:  .byte   $52,$AA,$16,$72,$DB,$37,$7F,$15 ; collision handler ptr low bytes
        .byte   $AE
weapon_handler_ptr_hi:  .byte   $E6,$E6,$E7,$E7,$E7,$E8,$E9,$E9 ; collision handler ptr high bytes
        .byte   $E8
weapon_damage_table:  .byte   $07,$07,$14,$14,$14,$14,$14,$14 ; weapon damage values (normal)
        .byte   $14,$14,$0A,$0A,$02,$14,$14,$02
        .byte   $00,$00,$00,$00,$00,$00,$0A,$02
        .byte   $00,$01,$00,$00,$00,$07,$00,$02
        .byte   $00,$00,$14,$02,$00,$00,$00,$00
        .byte   $00,$06,$14,$00,$04,$00,$00,$00
        .byte   $00,$0A,$00,$00,$14,$00,$04,$00
        .byte   $14,$00,$14,$00,$14,$07,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$00,$00
        .byte   $04,$04,$00,$04,$04,$00,$01,$02
        .byte   $04,$04,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$07,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$14,$14,$00,$00
        .byte   $14,$00,$14,$00,$14,$00,$14,$14
        .byte   $14,$14,$00,$14,$00,$00,$00,$00
        .byte   $00,$00,$14,$14,$00,$14,$00,$00
        .byte   $00,$14,$00,$14,$00,$00,$14,$00
        .byte   $00,$00,$00,$00,$00,$14,$14,$00
        .byte   $14,$00,$00,$00,$00,$14,$00,$00
        .byte   $14,$14,$00,$00,$14,$00,$14,$14
        .byte   $14,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$14,$14,$00,$14,$14,$00,$14
        .byte   $14,$00,$14,$14,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$14,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $14,$00,$14,$00,$14,$00,$00,$14
        .byte   $00,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$14,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$14,$14
        .byte   $00,$00,$00,$00,$00,$00,$14,$00
        .byte   $14,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$14,$00,$07,$00
        .byte   $14,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$14,$00,$00,$07,$07,$00,$07
        .byte   $07,$00,$07,$04,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$14,$14,$00,$00
        .byte   $14,$00,$14,$00,$14,$00,$14,$14
        .byte   $00,$14,$00,$07,$00,$00,$00,$00
        .byte   $00,$00,$14,$14,$00,$14,$00,$00
        .byte   $00,$14,$00,$14,$00,$00,$14,$07
        .byte   $00,$00,$00,$00,$00,$07,$14,$00
        .byte   $07,$00,$00,$00,$00,$00,$00,$00
        .byte   $14,$00,$07,$00,$14,$00,$14,$00
        .byte   $14,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$14,$14,$00,$14,$14,$00,$14
        .byte   $14,$00,$07,$07,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00
weapon_damage_table_2:  .byte   $14,$14,$00,$00,$00,$00,$14,$00
        .byte   $14,$00,$00,$14,$04,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$07
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$07,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$14,$00,$07,$00
        .byte   $00,$00,$00,$00,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$07,$00
        .byte   $00,$00,$00,$02,$02,$00,$00,$04
        .byte   $07,$07,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$14,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $07,$07,$00,$00,$14,$00,$14,$00
        .byte   $07,$00,$04,$14,$04,$14,$00,$02
        .byte   $00,$00,$00,$00,$00,$00,$0A,$04
        .byte   $00,$02,$00,$00,$00,$07,$00,$02
        .byte   $00,$00,$14,$02,$00,$00,$00,$00
        .byte   $00,$07,$07,$00,$04,$00,$00,$00
        .byte   $00,$0A,$00,$00,$14,$00,$04,$00
        .byte   $14,$00,$00,$00,$14,$07,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$07,$00
        .byte   $04,$04,$00,$04,$04,$00,$04,$04
        .byte   $04,$04,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$07,$00,$00,$00,$00,$00
        .byte   $00,$14,$00,$00,$00,$00,$00,$00
weapon_damage_table_3:  .byte   $14,$14,$00,$00,$14,$00,$14,$00
        .byte   $14,$00,$14,$14,$00,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$14,$14
        .byte   $00,$00,$00,$00,$00,$14,$00,$14
        .byte   $00,$00,$14,$00,$00,$00,$00,$00
        .byte   $00,$14,$14,$00,$14,$0A,$00,$00
        .byte   $00,$14,$00,$00,$14,$00,$07,$00
        .byte   $14,$00,$14,$00,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$07,$00
        .byte   $04,$04,$00,$04,$04,$00,$04,$02
        .byte   $04,$04,$00,$00,$00,$00,$00,$0A
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$00,$00
        .byte   $00,$14,$00,$00,$00,$00,$00,$00
        .byte   $14,$14,$00,$00,$14,$00,$14,$00
        .byte   $14,$00,$04,$14,$02,$14,$00,$04
        .byte   $00,$00,$00,$00,$00,$00,$14,$04
        .byte   $00,$02,$00,$00,$00,$07,$00,$00
        .byte   $00,$00,$14,$04,$00,$00,$00,$00
        .byte   $00,$00,$14,$00,$14,$00,$00,$00
        .byte   $00,$0A,$00,$00,$14,$00,$04,$00
        .byte   $14,$00,$14,$00,$14,$07,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$00,$00
        .byte   $07,$07,$00,$04,$04,$00,$00,$02
        .byte   $14,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$07,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
contact_damage_to_player_tbl:  .byte   $02,$02,$02,$02,$02,$02,$04,$04 ; damage to player per entity type
        .byte   $04,$04,$04,$04,$04,$01,$00,$0C
        .byte   $0C,$00,$00,$00,$00,$1C,$04,$04
        .byte   $02,$08,$08,$04,$00,$04,$00,$04
        .byte   $00,$00,$02,$08,$03,$00,$00,$00
        .byte   $00,$04,$04,$00,$04,$00,$00,$00
        .byte   $08,$08,$08,$04,$04,$02,$06,$00
        .byte   $04,$00,$04,$00,$02,$04,$00,$02
        .byte   $00,$00,$00,$00,$02,$02,$04,$00
        .byte   $04,$04,$00,$04,$04,$02,$08,$04
        .byte   $02,$02,$08,$00,$00,$00,$0A,$00
        .byte   $04,$04,$02,$04,$03,$04,$04,$04
        .byte   $00,$08,$04,$04,$00,$1C,$1C,$04
        .byte   $06,$04,$08,$06,$00,$04,$04,$06
        .byte   $00,$0A,$0A,$0A,$0A,$00,$00,$00
        .byte   $00,$00,$00,$00,$A9,$14,$9D
        bvc     *+3
        jsr     apply_entity_physics_alt
        bcc     *+7
        lda     #$00
        sta     $0150,x
        sec
        lda     $04A0,x
        sbc     #$04
        sta     $0160,x
        rts

        lda     #$18
        sta     $0150,x
        jsr     apply_entity_physics_alt
        bcc     *+7
        lda     #$00
        sta     $0150,x
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $0160,x
        rts

        lda     #$18
        sta     $0150,x
        jsr     apply_entity_physics_alt
        bcc     *+7
        lda     #$00
        sta     $0150,x
        sec
        lda     $04A0,x
        sbc     #$08
        sta     $0160,x
        rts

        jsr     $EFEE
        sec
        lda     $0400,x
        sbc     #$40
        tay
        lda     $AF79,y
        sta     $01
        lda     $0420,x
        and     #$20
        beq     *+29
        ldy     $01
        lda     #$15
        cmp     $0358,y
        bne     *+9
        lda     #$04
        sta     $0620,x
        bne     *+8
        lda     $00
        cmp     #$60
        bcs     collision_apply_physics
        lda     #$82
        sta     $0420,x
        lda     $0620,x
        cmp     #$04
        bcs     collision_apply_physics
        lda     $04E0,x
        and     #$03
        bne     collision_inc_state
        sta     $04E0,x
        lda     $0620,x
        inc     $0620,x
        asl     a
        asl     a
        tay
        ldx     $01
        jsr     banked_0B_item_spawn
        ldx     $2B
collision_inc_state:  inc     $04E0,x
collision_apply_physics:  jsr     apply_entity_physics_alt
        rts

        lda     $0620,x
        bne     *+36
        lda     #$6E
        sta     $04E0,x
        inc     $0620,x
        lda     #$00
        sta     $0420,x
        lda     #$01
        sta     $01
        lda     #$23
        jsr     $96CF
        lda     #$83
        sta     $0420,x
        bcs     *+7
        lda     #$26
        jsr     spawn_entity_from_parent
        jsr     apply_entity_physics_alt
        bcc     collision_done
        lda     #$23
        jsr     find_entity_by_type
        bcc     collision_done
        lda     #$28
        jsr     spawn_entity_from_parent
collision_done:  rts

        rts
        lda     #$01
        bne     *+4
        lda     #$00
        sta     $4E
        lda     $0420,x
        and     #$03
        beq     apply_entity_physics
        pha
        and     #$01
        beq     collision_check_contact
        jsr     check_player_collision
collision_check_contact:  pla
        and     #$02
        beq     apply_entity_physics
        jsr     check_weapon_collision
        bcc     apply_entity_physics
        jsr     item_drop_rng
        lda     #$06
        sta     $0400,x
        lda     #$80
        sta     $0420,x
        lda     #$00
        sta     $0680,x
        sta     $06A0,x
        jmp     physics_despawn_check

; =============================================================================
; apply_entity_physics — Apply velocity to entity position, handle bounds checking ($EEEF)
; =============================================================================
apply_entity_physics:  sec
        lda     $04C0,x                 ; Y sub-pixel position
        sbc     $0660,x                 ; subtract Y velocity (sub-pixel)
        sta     $04C0,x
        lda     $04A0,x                 ; Y pixel position
        sbc     $0640,x                 ; subtract Y velocity (whole)
        sta     $04A0,x
        cmp     #$F0
        bcc     physics_check_gravity
        jmp     physics_out_of_bounds

physics_check_gravity:  lda     $0420,x ; check entity flags
        and     #$04                    ; bit 2 = gravity enabled
        beq     physics_move_left
        clc
        lda     $0660,x
        sbc     $30
        sta     $0660,x
        lda     $0640,x
        sbc     $31
        sta     $0640,x
physics_move_left:  lda     $0420,x     ; check facing direction
        and     #$40                    ; bit 6 = facing right
        bne     physics_move_right
        sec
        lda     $0480,x
        sbc     $0620,x
        sta     $0480,x
        lda     $0460,x
        sbc     $0600,x
        sta     $0460,x
        lda     $0440,x
        sbc     #$00
        sta     $0440,x
        sec
        lda     $0460,x
        sbc     $1F
        sta     jump_ptr
        lda     $0440,x
        sbc     $20
        bne     physics_out_of_bounds
        lda     jump_ptr
        cmp     #$08
        bcc     physics_out_of_bounds
        bcs     physics_in_bounds
physics_move_right:  clc
        lda     $0480,x
        adc     $0620,x
        sta     $0480,x
        lda     $0460,x
        adc     $0600,x
        sta     $0460,x
        lda     $0440,x
        adc     #$00
        sta     $0440,x
        sec
        lda     $0460,x
        sbc     $1F
        sta     jump_ptr
        lda     $0440,x
        sbc     $20
        bne     physics_out_of_bounds
        lda     jump_ptr
        cmp     #$F8
        bcs     physics_out_of_bounds
physics_in_bounds:  clc
        rts

physics_out_of_bounds:  lsr     $0420,x ; deactivate entity (clear bit 7)
physics_despawn_check:  cpx     #$10
        bcc     physics_despawn_return
        lda     $4E
        bne     physics_despawn_secondary
        lda     #$FF
        sta     a:$F0,x
physics_despawn_return:  sec
        rts

physics_despawn_secondary:  lda     #$FF
        sta     $0120,x
        lda     $0110,x
        tay
        lda     $06C0,x
        sta     $0140,y
        sec
        rts

        lda     #$01
        bne     *+4

; =============================================================================
; apply_entity_physics_alt — Alternate physics — used for weapons/projectiles ($EFB3)
; =============================================================================
apply_entity_physics_alt:  lda     #$00
        sta     $4E
        lda     $0420,x
        and     #$03                    ; check contact/weapon bits
        beq     physics_alt_check_offscreen
        pha
        and     #$01                    ; bit 0 = contact damage
        beq     physics_alt_check_contact
        jsr     check_player_collision  ; test player contact
physics_alt_check_contact:  pla
        and     #$02                    ; bit 1 = weapon collidable
        beq     physics_alt_check_offscreen
        jsr     check_weapon_collision  ; test weapon hits
        bcc     physics_alt_check_offscreen
        jsr     item_drop_rng           ; roll for item drop
        lda     #$06
        sta     $0400,x
        lda     #$80
        sta     $0420,x
        lda     #$00
        sta     $0680,x
        sta     $06A0,x
        jmp     physics_despawn_check

physics_alt_check_offscreen:  lda     $2F
        bne     physics_out_of_bounds
        clc
        rts

        lda     $0420,x
        and     #$BF
        sta     $0420,x
        sec
        lda     $2E
        sbc     $2D
        sta     $00
        bcs     entity_face_player_done
        lda     $00
        eor     #$FF
        adc     #$01
        sta     $00
        lda     #$40
        ora     $0420,x
        sta     $0420,x
entity_face_player_done:  rts

find_entity_by_type:  sta     $00
        ldy     #$0F
find_entity_scan:  lda     $00
find_entity_compare:  cmp     $0410,y
        beq     find_entity_check_active
        dey
        bpl     find_entity_compare
        sec
        rts

find_entity_check_active:  lda     $0430,y
        bmi     find_entity_not_found
        dey
        bpl     find_entity_scan
        sec
        rts

find_entity_not_found:  clc
        rts

; =============================================================================
; check_vert_tile_collision — Check vertical tile collision and snap to surface ($F02C)
; =============================================================================
check_vert_tile_collision:  lda     #$00
        sta     $0B
        lda     $0640,x                 ; Y velocity (direction)
        php
        bpl     vert_coll_falling
        clc
        lda     $04A0,x
        adc     $02
        jmp     vert_coll_store_pos

vert_coll_falling:  sec
        lda     $04A0,x
        sbc     $02
vert_coll_store_pos:  sta     $0A
        clc
        lda     $0460,x
        adc     $01
        sta     jump_ptr
        lda     $0440,x
        adc     #$00
        sta     $09
        cpx     #$0F
        bcs     vert_coll_lookup_uncached
        jsr     lookup_cached_tile
        jmp     vert_coll_process

vert_coll_lookup_uncached:  jsr     lookup_tile_from_map
vert_coll_process:  ldy     $00
        lda     tile_solid_lookup_tbl,y ; check if tile is solid
        sta     $02
        ldx     $2B
        sec
        lda     $0460,x
        sbc     $01
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
        sta     $09
        cpx     #$0F
        bcs     vert_coll_left_uncached
        jsr     lookup_cached_tile
        jmp     vert_coll_left_process

vert_coll_left_uncached:  jsr     lookup_tile_from_map
vert_coll_left_process:  ldx     $2B
        ldy     $00
        lda     tile_solid_lookup_tbl,y
        ora     $02
        sta     $00
        beq     vert_coll_no_hit
        plp
        bmi     vert_coll_snap_up
        lda     $0A
        and     #$0F
        eor     #$0F
        sec
        adc     $04A0,x
        jmp     vert_coll_store_y

vert_coll_snap_up:  lda     $04A0,x     ; get entity Y position
        pha
        lda     $0A
        and     #$0F
        sta     $02
        pla
        sec
        sbc     $02
vert_coll_store_y:  sta     $04A0,x
        lda     #$00
        sta     $04C0,x
        lda     $0420,x
        and     #$04
        beq     vert_coll_done
        lda     #$C0
        sta     $0660,x
        lda     #$FF
        sta     $0640,x
vert_coll_done:  rts

vert_coll_no_hit:  plp
        rts

; =============================================================================
; check_horiz_tile_collision — Check horizontal tile collision and snap to surface ($F0CF)
; =============================================================================
check_horiz_tile_collision:  lda     $04A0,x ; entity Y position
        sta     $0A
        lda     #$00
        sta     $0B
        lda     $0420,x                 ; check facing direction
        and     #$40                    ; bit 6 = facing right
        php
        beq     horiz_coll_left
        sec
        lda     $0460,x
        adc     $01
        sta     jump_ptr
        lda     $0440,x
        adc     #$00
        jmp     horiz_coll_store_screen

horiz_coll_left:  clc
        lda     $0460,x
        sbc     $01
        sta     jump_ptr
        lda     $0440,x
        sbc     #$00
horiz_coll_store_screen:  sta     $09
        cpx     #$0F
        bcs     horiz_coll_lookup_uncached
        jsr     lookup_cached_tile
        jmp     horiz_coll_process

horiz_coll_lookup_uncached:  jsr     lookup_tile_from_map
horiz_coll_process:  ldx     $2B
        ldy     $00
        lda     tile_solid_lookup_tbl,y ; check if tile is solid
        sta     $03
        beq     horiz_coll_no_hit
        plp
        beq     horiz_coll_snap_right
        lda     jump_ptr
        and     #$0F
        sta     $00
        sec
        lda     $0460,x
        sbc     $00
        sta     $0460,x
        lda     $0440,x
        sbc     #$00
        sta     $0440,x
        jmp     check_vert_tile_collision

horiz_coll_snap_right:  lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     $0460,x
        sta     $0460,x
        lda     $0440,x
        adc     #$00
        sta     $0440,x
        jmp     check_vert_tile_collision

horiz_coll_no_hit:  plp
        jmp     check_vert_tile_collision

tile_solid_lookup_tbl:  .byte   $00,$01,$00,$01,$00,$01,$01,$01 ; solid flag lookup per tile type
        .byte   $01
spawn_entity_from_parent:  pha
        jsr     find_empty_entity_slot
        bcs     spawn_entity_no_slot
        pla
spawn_entity_init:  jsr     entity_init_from_type
        txa
        tay
        ldx     $2B
        lda     $0420,x
        and     #$40
        ora     $0430,y
        sta     $0430,y
        lda     $0480,x
        sta     $0490,y
        lda     $0460,x
        sta     $0470,y
        lda     $0440,x
        sta     $0450,y
        lda     $04C0,x
        sta     $04D0,y
        lda     $04A0,x
        sta     $04B0,y
        clc
        rts

spawn_entity_no_slot:  pla
        ldx     $2B
        sec
        rts

        ldy     #$40
        sec
        lda     $2D
        sbc     $2E
        sta     $00
        bcs     *+12
        lda     $00
        eor     #$FF
        adc     #$01
        ldy     #$00
        sta     $00
        lda     $0420,x
        and     #$BF
        sta     $0420,x
        tya
        ora     $0420,x
        sta     $0420,x
        sec
        lda     $04A0
        sbc     $04A0,x
        php
        bcs     calc_entity_velocity
        eor     #$FF
        adc     #$01
calc_entity_velocity:  sta     $01
        cmp     $00
        bcs     calc_vel_y_greater
        lda     $09
        sta     $0D
        sta     $0600,x
        lda     jump_ptr
        sta     $0C
        sta     $0620,x
        lda     $00
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     divide_16bit
        lda     $0F
        sta     $0D
        lda     $0E
        sta     $0C
        lda     $01
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     divide_16bit
        ldx     $2B
        lda     $0F
        sta     $0640,x
        lda     $0E
        sta     $0660,x
        jmp     calc_vel_negate_y

calc_vel_y_greater:  lda     $09
        sta     $0D
        sta     $0640,x
        lda     jump_ptr
        sta     $0C
        sta     $0660,x
        lda     $01
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     divide_16bit
        lda     $0F
        sta     $0D
        lda     $0E
        sta     $0C
        lda     $00
        sta     $0B
        lda     #$00
        sta     $0A
        jsr     divide_16bit
        ldx     $2B
        lda     $0F
        sta     $0600,x
        lda     $0E
        sta     $0620,x
calc_vel_negate_y:  plp
        bcc     calc_vel_done
        lda     $0660,x
        eor     #$FF
        adc     #$01
        sta     $0660,x
        lda     $0640,x
        eor     #$FF
        adc     #$00
        sta     $0640,x
calc_vel_done:  rts

; =============================================================================
; item_drop_rng — Random item drop on enemy death ($F25A)
; =============================================================================
item_drop_rng:  lda     $B1             ; check boss state (no drops during boss)
        beq     item_drop_calc
        rts

item_drop_calc:  lda     $4A            ; read RNG seed
        sta     $01
        lda     #$64
        sta     $02
        jsr     divide_8bit             ; divide RNG by 100
        lda     $CB                     ; check difficulty flag
        beq     item_drop_normal_mode
        lda     $04
        cmp     #$30
        bcc     item_drop_nothing
        cmp     #$49
        bcc     item_drop_large_weapon
        cmp     #$58
        bcc     item_drop_large_health
        cmp     #$5D
        bcc     item_drop_small_health
        cmp     #$61
        bcc     item_drop_small_weapon
        cmp     #$62
        beq     item_drop_extra_life
item_drop_nothing:  rts

item_drop_large_weapon:  lda     #$79
        bne     item_drop_spawn
item_drop_large_health:  lda     #$77
        bne     item_drop_spawn
item_drop_small_health:  lda     #$78
        bne     item_drop_spawn
item_drop_small_weapon:  lda     #$76
        bne     item_drop_spawn
item_drop_extra_life:  lda     #$7B
        bne     item_drop_spawn
        lda     #$7A
        bne     item_drop_spawn
item_drop_spawn:  jsr     spawn_entity_from_parent
        bcs     item_drop_failed
        lda     #$84
        sta     $0430,y
        lda     #$02
        sta     $0650,y
        lda     #$01
        sta     $04F0,y
item_drop_failed:  rts

item_drop_normal_mode:  lda     $04
        cmp     #$1C
        bcc     item_drop_nothing
        cmp     #$26
        bcc     item_drop_large_weapon
        cmp     #$30
        bcc     item_drop_large_health
        cmp     #$4E
        bcc     item_drop_small_health
        cmp     #$62
        bcc     item_drop_small_weapon
        cmp     #$63
        beq     item_drop_extra_life
        rts


; =============================================================================
; Initialization
; =============================================================================
cold_boot_init:                         ; Cold boot: init PPU, switch to bank $0E, start game
        lda     #$10                    ; NMI enable, bg pattern $1000
        sta     $2000                   ; PPUCTRL
        lda     #$06                    ; Show bg+sprites on left edge
        sta     $2001                   ; PPUMASK
        lda     #$0E                    ; Switch to bank $0E (game engine)
        jsr     bank_switch
        jmp     banked_entry            ; Jump to $8000 in bank $0E

        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF
sprite_def_ptr_lo:  .byte   $00,$0D,$1A,$27,$34,$38,$3C,$40 ; sprite def pointer table (low bytes)
        .byte   $44,$4A,$50,$56,$5C,$5F,$62,$65
        .byte   $68,$6D,$72,$77,$7C,$81,$86,$8B
        .byte   $90,$9C,$A4,$AB,$AF,$B3,$B3,$B7
        .byte   $BB,$BF,$BF,$C3,$C6,$CC,$D2,$D8
        .byte   $D8,$D8,$D8,$D8,$D8
        .byte   $D8
        .byte   $D8
        .byte   $D8
        .byte   $DF,$EB,$F0,$F9,$FE,$04,$0C,$10
        .byte   $1B,$2A,$36,$47,$4C,$4F,$56,$56
        .byte   $5E,$5E,$5E,$5E,$5E,$5E,$5E,$5E
        .byte   $5E,$5E,$5E,$5E,$5E,$5E,$5E,$5E
        .byte   $5E,$70,$76,$86
        .byte   $8A
        .byte   $96,$9A
        .byte   $9E,$A2,$A8,$AC,$B6,$BB,$BF,$C2
        .byte   $C6,$D1,$D9
        .byte   $DD,$E5,$ED
        .byte   $F3,$F8,$0A,$10,$13,$19,$1F,$24
        .byte   $32,$36,$3D,$43,$47,$4B,$4F,$53
        .byte   $58,$5C,$62,$66,$69,$6D,$70,$74
        .byte   $78
        .byte   $78
        .byte   $78
sprite_def_ptr_lo_wpn:  .byte   $78
        .byte   $82,$8C,$8C,$8C,$90,$90,$97,$97
        .byte   $9B,$9B,$A3,$A6,$B5,$B9,$BD,$C1
        .byte   $C8,$C8,$CC,$CF,$CF,$D2,$DD,$E3
        .byte   $E6,$F1,$FA,$FE,$04,$10,$10,$16
        .byte   $16,$16,$1E,$26,$26,$26,$26,$26
        .byte   $2A,$2E,$32,$32,$40,$40,$40,$43
        .byte   $46,$58,$58,$5B,$63,$66
        .byte   $79,$79,$79
        .byte   $7F,$82,$85,$89,$90,$94,$97,$97
        .byte   $97,$97,$9B,$9E,$A3,$AB,$AB,$B0
        .byte   $B5,$B5,$B5,$63,$C2,$C8,$CC,$CF
        .byte   $CC,$E1,$E1,$E1,$E9,$40,$E9,$EE
        .byte   $F4,$F9,$FD,$01,$06,$0D,$14,$1A
        .byte   $20,$27,$27,$2A,$2E,$FE,$32,$36
        .byte   $39,$42,$46,$49,$52,$63
        .byte   $55,$59
        .byte   $5D,$5D,$67
        .byte   $6D,$6D,$71
        .byte   $75,$79
        .byte   $7D,$81,$84
        .byte   $84,$84
        .byte   $87
sprite_def_ptr_hi:  .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB ; sprite def pointer table (high bytes)
        .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FB,$FB,$FB
        .byte   $FB,$FB,$FB,$FB,$FB,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC
        .byte   $FC,$FC,$FC,$FC,$FC,$FC,$FC,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
sprite_def_ptr_hi_wpn:  .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
        .byte   $FD,$FD,$FD,$FD,$FD,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
        .byte   $FE,$FE,$FE,$FE,$FE,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FD
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $0A,$08,$04,$04,$04,$04,$04,$04
        .byte   $04,$04,$04,$04,$05,$0A,$08,$09
        .byte   $09,$09,$09,$09,$09,$09,$09,$09
        .byte   $09,$09,$0A,$08,$10,$10,$10,$10
        .byte   $10,$10,$10,$10,$10,$10,$11,$0A
        .byte   $08,$20,$20,$20,$20,$20
        .byte   $20,$20,$20
        .byte   $20,$20,$20
        .byte   $01,$05
        .byte   $06,$06
        .byte   $01,$05
        .byte   $09,$09
        .byte   $01,$05
        .byte   $12
        .byte   $12,$01,$05,$20,$20,$03,$06,$01
        .byte   $03,$02,$03,$03,$06,$0A,$0C,$0B
        .byte   $0C,$03,$06,$0D,$0F,$0E,$0F,$03
        .byte   $06,$20,$20,$20,$20,$00,$00,$08
        .byte   $00,$00,$14,$00,$00,$13,$00,$00
        .byte   $1E,$02,$03,$06,$06,$06,$02,$03
        .byte   $09,$09,$09,$02,$03,$12,$12,$12
        .byte   $02,$06,$20,$20,$20,$02,$01,$02
        .byte   $04,$04,$02,$01,$0B,$09,$09,$02
        .byte   $01,$0E,$10,$10,$02,$01,$20,$20
        .byte   $20,$09,$02,$18,$07,$07,$18,$07
        .byte   $07,$18,$07,$07
        .byte   $18
        .byte   $05,$07
        .byte   $1A,$1A,$1A,$1A,$1A,$1A,$04,$02
        .byte   $1B,$1C,$1D,$1B,$1B,$01,$08,$15
        .byte   $16,$01,$08,$19,$19,$01,$08,$1F
        .byte   $1F,$01,$0A,$17,$21,$01,$0A,$19
        .byte   $19,$01,$0A,$1F,$1F,$00,$00,$22
        .byte   $03,$08,$23,$24,$25,$00,$03,$01
        .byte   $26,$27,$28,$29,$03,$02,$1B,$1D
        .byte   $1C,$1B,$04,$02,$39,$3A,$3B,$3C
        .byte   $00,$09,$03,$2F,$4D,$4E,$4D,$4F
        .byte   $50,$4F,$51,$52,$51,$02,$01,$3D
        .byte   $3E,$3F,$06,$03,$53,$56,$58,$57
        .byte   $59,$56,$2E,$02,$05
        .byte   $48
        .byte   $49,$4A
        .byte   $03,$03,$44,$45,$46,$47,$05,$06
        .byte   $2A,$2B,$2C,$2D,$2C,$2E,$01,$04
        .byte   $4B,$4C,$08,$06,$30,$31,$32,$33
        .byte   $34,$35,$36,$37,$38,$0C,$02,$5A
        .byte   $5B,$5A,$5A,$2E,$5B,$2E,$5A,$39
        .byte   $3A,$3B,$3C,$00,$09,$02,$5C,$5C
        .byte   $5D,$5D,$5C,$39,$3A,$3B,$3C,$00
        .byte   $0E,$02,$5E,$5E,$5F,$5F,$5E,$5E
        .byte   $2E,$5F,$2E,$5E,$39,$3A,$3B,$3C
        .byte   $00,$02,$03,$57,$54,$55,$00,$00
        .byte   $44,$04,$03,$40,$41,$42,$43,$00
        .byte   $05,$04,$C3,$C4,$C5,$C6,$C6,$00
        .byte   $0F,$02,$65,$62,$62,$61,$61,$60
        .byte   $63,$64,$63,$64,$63,$64,$63,$64
        .byte   $63,$60,$03,$06,$60,$66,$67,$67
        .byte   $0D,$02,$63,$64,$63,$68,$69,$6A
        .byte   $6B,$6C,$6D,$6B,$6A,$69,$68,$62
        .byte   $01,$12,$62,$62,$09,$05,$7C,$6E
        .byte   $6F,$70,$71,$72,$73,$74,$75,$70
        .byte   $01,$06,$7C,$7B,$01,$10,$76,$76
        .byte   $01,$7E,$77,$77,$03,$05,$78,$7A
        .byte   $79,$7A,$01,$24,$7C,$7C,$07,$06
        .byte   $84,$7D,$7E,$7F,$80,$81,$82,$7F
        .byte   $02,$10,$7D,$83,$83,$01,$08,$86
        .byte   $87,$00,$00,$84,$01,$12,$85,$85
        .byte   $08,$06,$88,$89,$8A,$8B,$8C,$8D
        .byte   $8E,$8F,$90,$05,$08,$91,$91,$91
        .byte   $91,$92,$93,$01,$08
        .byte   $91,$96
        .byte   $05,$05
        .byte   $94,$95
        .byte   $94,$97
        .byte   $98
        .byte   $97,$05,$08,$9C,$99,$99,$99,$9A
        .byte   $9B,$03,$06,$9F,$A0,$A1,$A0,$02
        .byte   $08,$9C
        .byte   $9D,$9E,$0F
        .byte   $03,$A5
        .byte   $A2,$A3
        .byte   $A4,$A3
        .byte   $A4,$A2
        .byte   $A3,$A4,$A3,$A4,$A2,$A3,$A4,$A3
        .byte   $A2,$03,$03,$A6,$A3,$A4,$A3,$00
        .byte   $00,$A5,$03,$08,$AA,$A7,$A8,$A9
        .byte   $03,$06,$AD,$AE,$AF,$AE,$02,$06
        .byte   $AA,$AB,$AC,$0B,$06,$B4,$B3,$B0
        .byte   $B1,$B2,$B1,$B2,$B1,$B2,$B1,$B2
        .byte   $B0,$01,$06
        .byte   $B1,$B2
        .byte   $04,$06,$B0,$B3,$B4,$B3,$B0,$03
        .byte   $08,$B0,$B5
        .byte   $B6,$B0
        .byte   $01,$18
        .byte   $B7,$B8,$01,$08,$B9,$BA,$01,$02
        .byte   $BC,$BD,$01,$04,$BE,$BF,$02,$06
        .byte   $C0,$C1,$C2,$01,$04,$C7,$C8,$03
        .byte   $1C,$C9,$CA,$CB,$CC,$01,$05,$CC
        .byte   $CD,$00,$00,$BB,$01,$06,$CE,$CF
        .byte   $00,$00,$D0,$01,$0C,$D2,$D1,$01
        .byte   $08,$D3,$D4,$07,$02,$45,$45,$46
        .byte   $46,$45,$47,$45,$48,$07,$02,$45
        .byte   $45,$46,$46,$45,$47,$45,$48,$01
        .byte   $05,$39,$3A,$04,$02,$79,$7A,$7B
        .byte   $7C,$00,$01,$06,$69,$6A,$05,$05
        .byte   $61,$62,$61,$63,$64,$63,$00,$00
        .byte   $7D,$0C,$06,$3E,$3F,$3E,$3F,$3E
        .byte   $3F,$3E,$40,$3E,$41,$42,$42,$41
        .byte   $01,$02,$44,$43,$01,$04,$7E,$7F
        .byte   $01,$08,$80,$81,$04,$08,$82,$83
        .byte   $82,$83,$82,$01,$06,$84,$85,$00
        .byte   $00,$86,$00,$00,$87,$08,$04,$2C
        .byte   $2C,$2D,$2E,$2F,$30,$31,$32,$30
        .byte   $03,$04,$3B,$3C
        .byte   $3D,$3C,$00
        .byte   $00
        .byte   $88,$08,$06,$89,$8A,$89,$8B,$8C
        .byte   $89,$8B,$8C,$89,$06,$04,$8D,$8E
        .byte   $8D,$8E,$8D,$8E,$8D,$01,$04,$8F
        .byte   $90,$03
        .byte   $00
        .byte   $91,$92
sprite_data_FE02:  .byte   $93,$93,$09,$0A,$22,$20,$20,$1F
        .byte   $1E,$1D,$1E,$1F,$21,$22,$03,$04
        .byte   $01,$02,$03,$02,$05,$06,$04,$05
        .byte   $06,$07,$08,$09,$05,$06,$71,$72
        .byte   $71,$74,$73,$73,$01,$04,$75,$76
        .byte   $01,$06,$13,$14,$01,$08,$11,$12
        .byte   $0B,$04,$0D,$0E,$0F,$0D,$0E,$0F
        .byte   $0D,$0E,$0F,$10,$0F,$10,$00,$00
        .byte   $94,$00,$00,$65,$0F,$06,$6B,$6C
        .byte   $6B,$6D,$6B,$6C,$6B,$6D,$6E,$6C
        .byte   $6B,$6D,$6D,$6F,$66,$66,$00,$00
        .byte   $70,$05,$06,$5D,$5E,$5E,$5F,$60
        .byte   $5F,$00,$00,$95,$10,$03,$29,$2A
        .byte   $2B,$2A,$2B,$2A,$2B,$2A,$2B,$2A
        .byte   $2B,$2A,$2B,$2A,$2B,$2A,$2B,$03
        .byte   $04,$15,$16,$15,$17,$00,$00,$18
        .byte   $00,$00,$19,$01,$04,$1B,$1C,$04
        .byte   $08,$23,$24,$23,$25,$25,$01,$03
        .byte   $27,$28,$00,$00,$26,$01,$08,$96
        .byte   $97,$00,$00,$98,$02,$08,$0A,$0B
        .byte   $0C,$05,$04,$99,$9A,$9B,$9C,$9D
        .byte   $9A,$02,$0A,$49,$4A,$4B,$02,$0A
        .byte   $4C,$4D,$4E,$0A,$04,$57,$58,$59
        .byte   $5A,$5B,$5C,$5B,$5A,$59,$58,$57
        .byte   $03,$08,$52,$53,$54,$53,$01,$04
        .byte   $55,$56,$00,$00,$9E,$0F,$02,$9F
        .byte   $9F,$A0,$A0,$A2,$A2,$A1,$A1,$A3
        .byte   $A3,$A1,$79,$7A,$7B,$7C,$00,$05
        .byte   $06,$A4,$A5,$A6,$A7,$A8,$A5,$02
        .byte   $04,$B4,$B5,$B6,$03,$03,$B7,$B8
        .byte   $B9,$BA,$02,$04,$BB,$BC
        .byte   $BD,$01,$04
        .byte   $BE,$BF,$01
        .byte   $03
        .byte   $C0,$C1
        .byte   $02
        .byte   $01,$C2
        .byte   $C3,$C4,$06,$04
        .byte   $C5,$C6
        .byte   $C7,$C8,$C7,$04,$00,$79,$7A,$7B
        .byte   $7C,$00,$03,$01,$79,$7A,$7B,$7C
        .byte   $03,$03,$C9,$CA,$CB,$CC,$04,$02
        .byte   $CD,$CE,$CF,$D0,$D1,$00,$00,$D2
        .byte   $01,$02,$D3,$D4,$01,$05,$D6,$D5
        .byte   $01,$03,$D7,$D8,$00,$00,$D9,$06
        .byte   $04,$33,$34,$35,$36,$37,$38,$37
        .byte   $01,$02,$7A,$79,$00,$00,$68,$06
        .byte   $04,$4F,$50,$51,$DA,$DA,$DB,$DA
        .byte   $00,$00,$DC,$01,$04,$DD,$DE,$01
        .byte   $08,$77,$78,$07,$04,$DF,$E0,$DF
        .byte   $E1,$E2,$E2,$E3,$E1,$03,$05,$E6
        .byte   $E4,$E5,$00,$01,$04,$A9,$AA,$01
        .byte   $04,$AB,$AC,$01,$04,$AD,$AE,$01
        .byte   $04,$AF,$B0,$01,$04
        .byte   $B1,$B2
        .byte   $00
        .byte   $00,$B3,$00,$00,$67,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF,$FF,$FF,$FF,$FF,$FF

; =============================================================================
; Reset Handler & Vectors
; =============================================================================
reset_handler:                          ; Reset vector entry point
        sei                             ; Disable interrupts
LFFE1:  inc     LFFE1                   ; Self-modifying: resets MMC1 shift register
        jmp     cold_boot_init          ; Jump to initialization

        .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
        .byte   $FF                     ; Padding
mmc1_scratch:                           ; $FFF0: MMC1 write target (any ROM addr works)
        .byte   $78,$E9,$00,$00,$48,$04,$00,$00
        .byte   $08,$AC
; Interrupt vectors
        .addr   nmi_handler             ; $FFFA: NMI vector
        .addr   reset_handler           ; $FFFC: Reset vector
        .addr   reset_handler           ; $FFFE: IRQ vector (same as reset)
