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
; --- NMI / PPU Update Pipeline ---
;   NMI handler
;    ├── OAM DMA ($0200 → PPU)
;    ├── ppu_buffer_transfer (queued writes)
;    ├── upload_palette (palette RAM → PPU)
;    ├── ppu_scroll_column_update (tile column → nametable)
;    ├── ppu_attribute_update (attribute merge/fill)
;    ├── Scroll register setup (camera offset subtraction, nametable XOR)
;    ├── RNG update (ent_x_sub XOR seed + frame)
;    └── Sound engine tick (bank $0C $8000) + queued sound command dispatch ($8003)
;
; --- Entity Collision Pipeline ---
;   apply_entity_physics_alt (called by AI handlers)
;    ├── check_player_collision → contact damage / item pickup
;    ├── check_weapon_collision → weapon handler dispatch
;    │    └── On kill: item_drop_rng → convert to DEATH_EXPLODE
;    └── Offscreen check → despawn
;
; --- Weapon Fire Pipeline ---
;   weapon_dispatch (per weapon type)
;    ├── Ammo check + deduction
;    ├── fire_weapon_scan_slot (scan slots 2-4)
;    └── weapon_spawn_projectile (type, position, velocity from tables)
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
;   $66         Sound command queue count (queue at $0580)
;   $67         Sound engine update deferred (NMI hit mid-bank-switch)
;   $68         Bank switch in progress flag (guards MMC1 serial write)
;   $69         Bank switch backup (original bank)
;   $9A-$9B     Boss beaten bitmask
;   $9C-$9F     Weapon ammo (various)
;   $A0-$A8     Weapon/item inventory
;   $A9         Current weapon ID
;   $AA         Special game mode flags
;   $AB-$AD     Weapon-specific counters
;   $AE         8×16 sprite size flag
;   $B0         Respawn checkpoint index (indexes $BB06+ tables in stage bank)
;   $B1         Boss HP / intro state
;   $B3         Boss stage ID
;   $B6         Camera Y offset (screen shake)
;   $B8-$B9     Camera X offset
;   $BC-$BD     Boss-specific flags
;   $CB         Difficulty flag (0=Normal, 1=Difficult)
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
;   $0490,x     Entity spawn X sub-pixel                    [ent_x_spawn_sub]
;   $04A0,x     Entity Y position (pixel)
;   $04B0,x     Entity spawn Y position
;   $04C0,x     Entity Y sub-pixel
;   $04D0,x     Spawn Y sub-pixel                              [ent_y_spawn_sub]
;   $04E0,x     Entity state / AI phase counter
;   $04F0,x     Item drop flag                                 [ent_drop_flag]
;   $0590,x     Entity weapon/damage type                     [ent_weapon_type]
;   $059E,x     Hitbox width (for collision)
;   $05A0-$05AA Sound/music control
;   $0600,x     Entity X velocity (whole)
;   $0610,x     Spawn hitbox width                             [ent_hitbox_w_lo]
;   $0620,x     Entity X velocity (sub-pixel)
;   $0630,x     Spawn hitbox height mask                       [ent_hitbox_w_hi]
;   $0640,x     Entity Y velocity (whole)
;   $0650,x     Spawn hitbox Y mask                            [ent_hitbox_h_lo]
;   $0660,x     Entity Y velocity (sub-pixel)
;   $0670,x     Spawn hitbox Y offset                          [ent_hitbox_h_hi]
;   $0680,x     Animation frame counter
;   $0690,x     Animation state backup
;   $06A0,x     Animation sequence index
;   $06B0,x     General entity variable
;   $06C0,x     Entity HP / hit points
;   $06D0,x     Entity timer / countdown                       [ent_timer]
;   $06E0,x     Entity screen-relative X position              [ent_screen_x]
;   $06F0,x     Entity AI behavior index                       [ent_ai_behavior]
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
;   $FA00       Sprite def pointer high (entity type → animation data)
;   $FA80       Sprite def pointer high (secondary/weapon sprites)
;   $FB00+      OAM sequence data (sprite tile IDs, attributes, offsets)
;
; =============================================================================

        .setcpu "6502"

.include "include/hardware.inc"
.include "include/ram.inc"
.include "include/zeropage.inc"
.include "include/constants.inc"

; ─── External references (banked addresses) ─────────────────────────────────
banked_entry       := $8000         ; Standard entry point in switched bank
banked_entry_alt   := $8003         ; Alternate entry point in switched bank
banked_0D_game_over := $800C        ; Bank $0D: game over / continue screen
banked_0D_ending := $800F           ; Bank $0D: ending scenes (seasons walk)
banked_0D_weapon_get := $8012       ; Bank $0D: weapon get screen
banked_0E_init_restart := $8072     ; Bank $0E: game_init entry — reset lives, restart stage
banked_0E_init_stage := $8076       ; Bank $0E: all robot masters beaten
banked_0E_init_wily_check := $8079       ; Bank $0E: advance to next stage
banked_0E_init_refill := $8088     ; Bank $0E: boss timeout/escape handler
banked_0D_wily_map := $8006          ; Bank $0D: Wily castle map screen
banked_0D_title := $8009            ; Bank $0D: title screen / prologue / attract
banked_0E_init_respawn := $80AB     ; Bank $0E: game_init entry — respawn (keep lives/ammo)
banked_0E_entity_update := $84EE    ; Bank $0E: per-frame entity update
banked_09_draw_sprites := $8600     ; Bank $09: ending — draw scene sprite block
banked_09_col_tick := $8603         ; Bank $09: ending — column tile per 4 frames
banked_09_walk_init := $8606        ; Bank $09: ending — init scene data pointer
banked_09_walk_scroll := $8609      ; Bank $09: ending — smooth vertical pan
; Bank $0A sprite data tables (read while bank $0A is switched in; these
; alias the generic $8000+ code entry addresses of other banks)
spr_frame_ptr_lo   := $8000         ; Bank $0A: entity frame data pointer (lo)
wpn_frame_ptr_lo   := $8100         ; Bank $0A: weapon frame data pointer (lo)
spr_frame_ptr_hi   := $8200         ; Bank $0A: entity frame data pointer (hi)
wpn_frame_ptr_hi   := $8300         ; Bank $0A: weapon frame data pointer (hi)
spr_offset_ptr_lo  := $8400         ; Bank $0A: per-frame OAM offset data pointer (lo)
spr_offset_ptr_hi  := $8500         ; Bank $0A: per-frame OAM offset data pointer (hi)
spr_flip_x_tbl     := $8600         ; Bank $0A: X-offset mirror table for hflipped sprites
banked_0E_wily_check := $9115       ; Bank $0E: Wily stage check
banked_sound_process := $925B       ; Banked: sound engine process
find_entity_count_check := $96CF    ; Bank $0E: scan for entity type, check population limit
banked_0B_item_spawn := $AF4C       ; Bank $0B: item/powerup spawn

; =============================================================================
; Bank Switching (MMC1)
; MMC1 requires 5 serial writes to set a register. Each write sends bit 0.
; Writing to $E000-$FFFF sets the PRG bank register.
; =============================================================================
bank_switch:                            ; PRG bank switch — A = bank number ($00-$0E)
        sta     current_bank                     ; Save requested bank number
        sta     bank_switch_backup                     ; Backup for later restore
        inc     bank_switch_active                     ; Set "bank switch in progress" flag
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
        sta     bank_switch_active                     ; Clear "in progress" flag
        lda     sound_pending                     ; sound engine update deferred by NMI?
        bne     bank_switch_run_sound
        rts

; NMI skipped the sound engine because this bank switch was in progress —
; run the deferred sound update now: bank $0C, tick driver, drain queue.
bank_switch_run_sound:  lda     #$0C            ; switch to bank $0C (sound engine)
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        jsr     banked_entry            ; sound engine per-frame tick ($8000)
bank_switch_sound_loop:  ldx     sound_queue_count ; dispatch queued sound command IDs
        beq     bank_switch_sound_done
        lda     sound_queue - 1,x
        jsr     banked_entry_alt        ; sound command dispatch ($8003)
        dec     sound_queue_count
        bne     bank_switch_sound_loop
bank_switch_sound_done:  lda     #$00   ; Queue empty — restore original bank
        sta     sound_pending
        lda     bank_switch_backup
        jmp     bank_switch

; ─── Queue a sound command ───
; A = SFX/music/command ID. Queue is drained each frame by the bank $0C
; sound engine (from NMI, or from bank_switch if NMI deferred it).
sound_queue_push:  ldy     sound_queue_count
        cpy     #$10                    ; queue full (16 entries)?
        bcs     sound_queue_push_rts
        sta     sound_queue,y
        inc     sound_queue_count
sound_queue_push_rts:  rts

; ─── Write A to the MMC1 CONTROL register ($9FFF, 5 serial writes) ───
; Called cross-bank ($C05D) from bank $0E cold boot with A=$0E:
; PRG mode 3 (fix $C000-$FFFF), CHR mode 1, vertical mirroring.
mmc1_write_control:
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
; ─── Show the Wily castle map screen (bank $0D) ───
show_wily_map:
        lda     #$0D
        jsr     bank_switch
        jsr     banked_0D_wily_map
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
        lda     controller_1                     ; save previous P1 controller state
        sta     p1_prev_buttons
        lda     controller_2                     ; save previous P2 controller state
        sta     p2_prev_buttons
        jsr     palette_anim_update     ; run palette cycling animation
        lda     #$00
        sta     vblank_done                     ; clear VBLANK-done flag
wait_vblank_loop:
        lda     vblank_done                     ; wait for NMI handler to set flag
        beq     wait_vblank_loop
        jsr     read_controllers        ; read controller hardware
        lda     controller_1                     ; P1 current state
        eor     p1_prev_buttons                     ; XOR with previous = changed bits
        and     controller_1                     ; AND with current = newly pressed
        sta     p1_new_presses                     ; store P1 new presses
        lda     controller_2                     ; P2 current state
        eor     p2_prev_buttons                     ; detect changed bits
        and     controller_2                     ; newly pressed only
        sta     p2_new_presses                     ; store P2 new presses
        lda     #$0E                    ; switch to game engine bank
        jsr     bank_switch
        rts

; ─── wait_for_vblank variant returning to bank $0D ($C0AB) ───
; Heavily used by all bank $0D screens (title, menus, password, ending).
wait_for_vblank_0D:
        lda     controller_1
        sta     p1_prev_buttons
        lda     controller_2
        sta     p2_prev_buttons
        jsr     palette_anim_update
        lda     #$00
        sta     vblank_done
wait_vblank_loop_0D:
        lda     vblank_done                     ; wait for NMI
        beq     wait_vblank_loop_0D
        jsr     read_controllers        ; read controller hardware
        lda     controller_1                     ; compute P1 new presses
        eor     p1_prev_buttons
        and     controller_1
        sta     p1_new_presses
        lda     controller_2                     ; compute P2 new presses
        eor     p2_prev_buttons
        and     controller_2
        sta     p2_new_presses
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
        lda     controller_1                     ; save P1 controller state
        pha
        lda     controller_2                     ; save P2 controller state
        pha
        lda     p1_new_presses                     ; save new presses
        pha
        lda     #$1E                    ; enable all rendering
        ora     ppumask_shadow                     ; merge with current PPUMASK shadow
        sta     ppumask_shadow
        sta     PPUMASK                   ; apply to PPU
        lda     #$00
        sta     vblank_done                     ; clear VBLANK flag
wait_frame_loop:
        lda     vblank_done                     ; wait for NMI
        beq     wait_frame_loop
        pla                             ; restore new presses
        sta     p1_new_presses
        pla
        sta     controller_2
        pla
        sta     controller_1
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
; player_death_sequence — Player death: explosion ring, checkpoint, lives ($C10B)
; =============================================================================
; Entered when player HP reaches 0 (contact damage in bank0F/bank0B) or on an
; instant-death transition (game_substate ≠ 0 skips the explosion animation).
; Plays the death explosion ring at the player's position, waits, computes the
; respawn checkpoint from the player's screen position, then decrements lives:
; lives left → respawn via bank $0E; none → game over / continue screen.
; -----------------------------------------------------------------------------
player_death_sequence:  lda     #$41
        jsr     sound_queue_push     ; sound: player death
        lda     #$FF
        jsr     sound_queue_push     ; sound: stop music
        lda     game_substate
        bne     player_death_delay_start
        sta     general_timer
player_death_anim_loop:  and     #$01
        bne     player_death_run_frame
        lda     general_timer
        and     #$07
        tax
        ldy     #$01
player_death_spawn_explosion:  lda     #$25
        sta     ent_type + $0E,y
        lda     #$80
        sta     ent_flags + $0E,y
        clc
        lda     ent_x_px
        adc     explosion_offset_x_lo_tbl,x
        sta     ent_x_px + $0E,y
        lda     ent_x_screen
        adc     explosion_offset_x_hi_tbl,x
        sta     ent_x_screen + $0E,y
        lda     ent_y_px
        adc     explosion_offset_y_tbl,x
        sta     ent_y_px + $0E,y
        lda     #$01
        sta     ent_anim_id + $0E,y
        lda     #$00
        sta     ent_x_vel_sub + $0E,y
        sta     ent_x_vel + $0E,y
        sta     ent_y_vel_sub + $0E,y
        sta     ent_y_vel + $0E,y
        sta     ent_anim_frame + $0E,y
        inx
        dey
        bpl     player_death_spawn_explosion
player_death_run_frame:  jsr     run_one_game_frame
        inc     general_timer
        lda     general_timer
        cmp     #$10                    ; 16 frames of explosions
        bcc     player_death_anim_loop
        lsr     ent_flags + $0E
        lsr     ent_flags + $0F
        jsr     setup_explosion_array   ; spawn final explosion ring
        lda     #$A0
        bne     player_death_delay_set
player_death_delay_start:  lda     #$E0
player_death_delay_set:  sta     general_timer
player_death_delay_loop:  lsr     ent_flags
        jsr     run_one_game_frame      ; run game frame during delay
        dec     general_timer
        bne     player_death_delay_loop
        lda     #$10
        sta     PPUCTRL
        lda     #$06
        sta     PPUMASK
        lda     current_stage
        and     #$07
        jsr     bank_switch
        ldx     #$00
        lda     ent_x_screen            ; player screen number vs per-stage
player_death_checkpoint_scan:  cmp     $BB07,x ; checkpoint screen thresholds
        bcc     player_death_checkpoint_set
        inx
        cpx     #$05
        bne     player_death_checkpoint_scan
player_death_checkpoint_set:  stx     checkpoint_idx
        ldx     #$FF
        txs
        lda     #$0E                    ; switch to game engine bank
        jsr     bank_switch             ; switch to game engine bank
        dec     current_lives
        bne     player_death_respawn
        lda     #$00
        sta     current_etanks
        lda     #$0D
        jsr     bank_switch
        jsr     banked_0D_game_over
        lda     #$0E
        jsr     bank_switch
        lda     general_counter
        bne     player_death_gameover
        jmp     banked_0E_init_refill

player_death_gameover:  jmp     banked_0E_init_restart

player_death_respawn:  jmp     banked_0E_init_respawn

explosion_offset_y_tbl:  .byte   $F8,$08,$FB,$05,$00,$00,$05,$FB ; Y offsets for boss explosion pattern
explosion_offset_x_lo_tbl:  .byte   $00,$00,$FB,$05,$FB,$08,$FB,$05 ; X offsets (low) for explosion pattern
explosion_offset_x_hi_tbl:  .byte   $00,$00,$FF,$00,$FF,$00,$FF,$00 ; X offsets (high) for explosion pattern

; =============================================================================
; boss_defeated_sequence — Boss defeated: death cutscene, record victory ($C1F0)
; =============================================================================
; Entered from process_sound_and_bosses when the boss's HP is depleted.
; Runs input-locked frames until the boss death animation finishes
; (boss_phase = $FF), then records the beaten-boss bit, calls the bank $0D
; post-boss handler (weapon get), and advances to the next stage.
; -----------------------------------------------------------------------------
boss_defeated_sequence:  jsr     reset_sound_state ; silence music/boss state
        inc     boss_state_flag
boss_defeated_wait:  jsr     boss_fight_frame
        lda     current_stage
        cmp     #WILY_STAGE_START
        bne     boss_defeated_finish
        lda     transition_type
        cmp     #$03
        bne     boss_defeated_finish
        lda     #$00
        sta     boss_state_flag
        lda     #$01
        sta     game_substate
        jmp     player_death_sequence

boss_defeated_finish:  lda     boss_phase
        cmp     #$FF
        bne     boss_defeated_wait
        lda     #$00
        sta     boss_state_flag
        lda     #$10
        sta     ppuctrl_shadow
        sta     PPUCTRL
        lda     #$06
        sta     ppumask_shadow
        sta     PPUMASK
        lda     #$00
        sta     checkpoint_idx
        ldx     #$FF
        txs
        lda     #$0E
        jsr     bank_switch
        ldx     current_stage
        cpx     #$08
        bcs     advance_to_next_stage
        lda     boss_beaten_mask_lo,x
        ora     beaten_bosses
        sta     beaten_bosses
        lda     boss_beaten_mask_hi,x
        ora     beaten_bosses_hi
        sta     beaten_bosses_hi
        lda     #$0D
        jsr     bank_switch
        jsr     banked_0D_weapon_get
        lda     #$0E
        jsr     bank_switch
        lda     beaten_bosses
        cmp     #$FF
        beq     all_bosses_defeated
        jmp     banked_0E_init_stage

all_bosses_defeated:  lda     #$07
        sta     current_stage
advance_to_next_stage:  inc     current_stage
        lda     current_stage
        cmp     #$0E
        bne     next_stage_continue
        lda     #$0D
        jsr     bank_switch
        jsr     banked_0D_ending
        lda     #$0E
        jmp     cold_boot_init

next_stage_continue:  jmp     banked_0E_init_wily_check

boss_beaten_mask_lo:  .byte   $01,$02,$04,$08,$10,$20,$40,$80 ; bitmask for each boss (low byte)
boss_beaten_mask_hi:  .byte   $01,$02,$00,$00,$00,$04,$00,$00 ; bitmask for each boss (high byte)

; =============================================================================
; reset_sound_state — Reset all sound/music state variables ($C289)
; =============================================================================
reset_sound_state:  lda     #$00
        sta     boss_hit_count          ; clear boss hit count
        sta     boss_work_var1
        sta     boss_work_var2
        sta     boss_hit_timer
        sta     game_mode
        lda     #$FE                    ; boss_phase = $FE (death animation running)
        sta     boss_phase
        rts

; ─── ($C295 — DEAD CODE, unreachable) Screen init + CHR column upload ───
; No JSR/JMP or pointer reference to $C295 (or the $C2D2 loop below) exists
; anywhere in the ROM. Runs 187 idle frames of palette animation, then
; streams $2E column-sized chunks from bank $09 $8600+ into pattern table 1
; — but $8600 in bank $09 now holds the ending cutscene code, so this is a
; leftover from an earlier data layout. Preserved as-is.
        lda     #$00
        sta     general_counter
        lda     #$02
        sta     palette_anim_target
        lda     #$04
        sta     palette_anim_counter
        lda     #$BB
        sta     general_counter
nametable_init_loop:  jsr     clear_entities_and_run
        dec     general_counter
        bne     nametable_init_loop
        lda     #$00
        sta     palette_anim_counter
        sta     palette_anim_target
        ldx     #$02
nametable_copy_initial:  lda     nametable_init_data,x
        sta     palette_ram + $01,x
        dex
        bpl     nametable_copy_initial
        lda     #$86
        sta     general_ptr_hi
        lda     #$00
        sta     general_ptr_lo

; =============================================================================
; nametable_column_upload — Upload nametable columns from stage bank to PPU ($C2D2)
; =============================================================================
nametable_column_upload:  lda     #$09  ; switch to bank $09 (scroll data)
        jsr     bank_switch
        lda     general_counter
        lsr     a
        tax
        lda     nametable_bank_table,x
        sta     col_update_addr_hi
        lda     nametable_addr_table,x
        sta     col_update_addr_lo
        lda     general_counter
        and     #$01
        beq     nametable_col_copy_inner
        lda     col_update_addr_lo
        ora     #$20
        sta     col_update_addr_lo
nametable_col_copy_inner:  ldy     #$20
nametable_col_copy_byte:  lda     (general_ptr_lo),y
        sta     col_update_tiles,y
        dey
        bpl     nametable_col_copy_byte
        lda     #$20
        sta     col_update_count
        clc
        lda     general_ptr_lo
        adc     #$20
        sta     general_ptr_lo
        lda     general_ptr_hi
        adc     #$00
        sta     general_ptr_hi
        jsr     clear_entities_and_run
        inc     general_counter
        lda     general_counter
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
        sta     ent_anim_frame
        lda     #$01
        sta     invincibility_timer                     ; set invincibility frame
        jsr     update_entity_positions ; move all entities
        jsr     entity_spawn_scan       ; spawn/despawn entities
        jsr     process_sound_and_bosses ; process sound + boss check
        jsr     banked_sound_process    ; run sound driver
run_sound_and_scroll:  jsr     render_all_sprites ; build OAM buffer
        lda     frame_skip_lo
        beq     game_frame_done
        inc     frame_skip_hi
        cmp     frame_skip_hi
        beq     game_frame_wait_render
        bcs     game_frame_done
game_frame_wait_render:  jsr     wait_one_rendering_frame
        lda     #$00
        sta     frame_skip_hi
game_frame_done:  jsr     wait_for_vblank ; wait for NMI and read input
        rts

; =============================================================================
; clear_entities_and_run — Clear entity slots 0-31, then run sound and scroll ($C386)
; =============================================================================
clear_entities_and_run:  ldx     #$1F
        lda     #$00
clear_entities_loop:  sta     ent_anim_frame,x
        dex
        bpl     clear_entities_loop
        jmp     run_sound_and_scroll

; =============================================================================
; setup_explosion_array — 12-piece death explosion ring at player position ($C393)
; =============================================================================
; Fills slots $02-$0D with explosion entities ($25) radiating from the player
; (slot 0). Used by player_death_sequence for the classic death ring.
; -----------------------------------------------------------------------------
setup_explosion_array:  lda     ent_x_screen
        sta     jump_ptr_hi
        lda     ent_x_px
        sta     jump_ptr
        lda     ent_y_px
        sta     temp_0A
        lda     #$25                    ; explosion entity type
        sta     temp_0B
        ldx     #$0D
explosion_array_setup_inner:
        ldy     #$0B
explosion_setup_loop:  lda     #$80
        ora     explosion_flags_tbl,y
        sta     ent_flags,x                 ; set entity flags (active)
        lda     temp_0B
        sta     ent_type,x
        lda     jump_ptr_hi
        sta     ent_x_screen,x
        lda     jump_ptr
        sta     ent_x_px,x
        lda     temp_0A
        sta     ent_y_px,x
        lda     explosion_xvel_sub_tbl,y
        sta     ent_x_vel_sub,x
        lda     explosion_xvel_tbl,y
        sta     ent_x_vel,x
        lda     explosion_yvel_sub_tbl,y
        sta     ent_y_vel_sub,x
        lda     explosion_yvel_tbl,y
        sta     ent_y_vel,x
        lda     #$00
        sta     ent_anim_frame,x
        sta     ent_anim_id,x
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
palette_anim_update:  lda     game_mode       ; check special mode flag
        bne     palette_anim_done
        lda     palette_anim_counter                   ; check palette anim frame count
        beq     palette_anim_done
        inc     palette_cycle_timer
        cmp     palette_cycle_timer
        bcs     palette_anim_done
        lda     #$00
        sta     palette_cycle_timer
        inc     palette_cycle_idx
        lda     palette_cycle_idx
        cmp     palette_anim_target
        bcc     palette_anim_advance
        lda     #$00
        sta     palette_cycle_idx
palette_anim_advance:  asl     a
        asl     a
        asl     a
        asl     a
        tax
        ldy     #$00
palette_anim_copy_loop:  lda     palette_anim_frames,x ; copy from palette animation frames
        sta     palette_ram,y                 ; write to active palette RAM
        inx
        iny
        cpy     #$10
        bne     palette_anim_copy_loop
        inc     palette_dirty
palette_anim_done:  rts

chr_upload_init:
        lda     current_stage
        and     #$07
        jsr     bank_switch
        lda     #$00
        sta     temp_0A
        lda     #$BC
        sta     temp_0B
        lda     current_stage
        and     #$08
        beq     @skip
        inc     temp_0B
@skip:
        ldy     #$00
        lda     (temp_0A),y
        sta     temp_00
        lda     #$00
        sta     PPUADDR
        sta     PPUADDR
        sta     jump_ptr
        iny
        sty     temp_01

; =============================================================================
; chr_upload_entry — Upload CHR tile data from stage banks to CHR-RAM ($C487)
; =============================================================================
chr_upload_entry:  ldy     temp_01
        lda     (temp_0A),y
        sta     jump_ptr_hi
        iny
        lda     (temp_0A),y
        sta     temp_02
        iny
        lda     (temp_0A),y
        iny
        sty     temp_01
        jsr     bank_switch
chr_upload_page_loop:  ldy     #$00
chr_upload_byte_loop:  lda     (jump_ptr),y ; read CHR byte from bank
        sta     PPUDATA                   ; write to CHR-RAM via PPUDATA
        iny
        bne     chr_upload_byte_loop
        inc     jump_ptr_hi
        dec     temp_02
        bne     chr_upload_page_loop
        lda     current_stage
        and     #$07
        jsr     bank_switch
        dec     temp_00
        bne     chr_upload_entry
        inc     temp_0B
        inc     temp_0B
        ldy     #$61
chr_upload_palette_copy:  lda     (temp_0A),y
        sta     palette_anim_target,y
        dey
        bpl     chr_upload_palette_copy
        jsr     upload_palette
        lda     #$0E
        jsr     bank_switch
        rts

; ─── Respawn at checkpoint: restore scroll state + reload CHR overlay ───
; Reads the per-stage checkpoint tables at $BB06+ (indexed by checkpoint_idx)
; to restore camera/scroll/spawn-scan state, then re-uploads the 6-page
; enemy CHR overlay ($B460 table) for that screen to pattern table $0A00+.
checkpoint_respawn:
        lda     current_stage
        and     #$07
        jsr     bank_switch
        ldy     checkpoint_idx
        lda     $BB06,y
        sta     nametable_select
        sta     ent_x_screen
        lda     $BB0C,y
        sta     spawn_scan_bwd
        sta     spawn_scan_fwd
        lda     $BB12,y
        sta     spawn_scan_sec_bwd
        sta     spawn_scan_sec_fwd
        lda     $BB18,y
        sta     metatile_ptr_hi
        lda     $BB1E,y
        sta     metatile_ptr_lo
        lda     $BB24,y
        sta     column_ptr_hi
        lda     $BB2A,y
        sta     column_ptr_lo
        lda     $BB30,y
        sta     current_screen
        lda     $BB36,y
        sta     scroll_screen_lo
        lda     $BB3C,y
        sta     scroll_screen_hi
        ldx     current_screen
        jsr     scroll_col_load_palette
        tya
        clc
        adc     #$0B
        tay
        ldx     #$0C
checkpoint_chr_list_loop:  lda     $B460,y ; push (bank, addr-hi) pairs for CHR overlay
        pha
        dey
        dex
        bne     checkpoint_chr_list_loop
        lda     #$0A
        sta     PPUADDR
        lda     #$00
        sta     PPUADDR
        sta     jump_ptr
        lda     #$06
        sta     temp_00
chr_sound_page_loop:  pla
        sta     jump_ptr_hi
        pla
        jsr     bank_switch
        ldy     #$00
chr_sound_byte_loop:  lda     (jump_ptr),y
        sta     PPUDATA
        iny
        bne     chr_sound_byte_loop
        dec     temp_00
        bne     chr_sound_page_loop
        lda     #$0E
        jsr     bank_switch
        lda     checkpoint_idx
        cmp     #$02
        bne     checkpoint_respawn_done
        jsr     banked_0E_wily_check
checkpoint_respawn_done:  rts

; ─── Run the title screen / prologue / one ending scene (bank $0D) ───
show_title_screen:
        lda     #$0D
        jsr     bank_switch
        jsr     banked_0D_title
        lda     #$0E
        jsr     bank_switch
        rts
; ─── Show the stage select screen (bank $0D $8000) ───
show_stage_select:
        lda     #$0D
        jsr     bank_switch
        jsr     banked_entry
        lda     #$0E
        jsr     bank_switch
        rts
open_weapon_menu:
        ldx     #$0F

; =============================================================================
; weapon_menu_wait_clear — Open weapon menu once projectiles clear ($C575)
; =============================================================================
; Returns immediately if ANY entity in slots 2..X is still active (the pause
; menu will not open while projectiles are on screen). Once all are gone:
; flushes a pending column update, queues sound command $32, and calls the
; bank $0D weapon-select screen ($8003). Entry open_weapon_menu scans $0F..2.
; -----------------------------------------------------------------------------
weapon_menu_wait_clear:  lda     ent_flags,x ; check entity flags (bit 7=active)
        bmi     weapon_menu_gate_done
        dex
        cpx     #$01
        bne     weapon_menu_wait_clear
        lda     col_update_count
        beq     scroll_column_setup
        jsr     wait_for_vblank
scroll_column_setup:  lda     col_update_addr_hi
        pha
        lda     col_update_addr_lo
        pha
        lda     #$32                    ; sound command $32: sound-engine bank switch
        jsr     sound_queue_push
        lda     #$0D
        jsr     bank_switch
        jsr     banked_entry_alt
        pla
        sta     col_update_addr_lo
        pla
        sta     col_update_addr_hi
        lda     #$0E
        jsr     bank_switch
weapon_menu_gate_done:  rts

; =============================================================================
; process_sound_and_bosses — Process sound engine and check boss encounter ($C5A9)
; =============================================================================
process_sound_and_bosses:  lda     boss_phase  ; boss fight active?
        beq     process_sound_done
        lda     #$0B                    ; switch to boss AI bank
        jsr     bank_switch
        jsr     banked_entry_alt        ; run boss AI update
        lda     #$0E                    ; switch back to game engine
        jsr     bank_switch
        lda     boss_hit_count          ; boss defeated flag (set at 0 HP)
        beq     process_sound_done
        lda     current_stage                     ; check current stage index
        cmp     #$0C
        bne     process_sound_jump_intro
        lda     boss_mode_flag
        cmp     #$FF
        beq     process_sound_jump_intro
        ldx     #$0F
clear_boss_entities:  lsr     ent_spawn_flags,x
        dex
        bpl     clear_boss_entities
        jsr     reset_sound_state
        lda     #$00
        sta     current_entity_slot
        lda     #ENTITY_WILY_GATE_OPEN
        ldx     #$0F
        jsr     spawn_entity_init
        lda     #$20
        sta     ent_x_spawn_px + $0F
        lda     #$AB
        sta     ent_y_spawn_px + $0F
        bne     process_sound_done
process_sound_jump_intro:  jmp     boss_defeated_sequence ; boss beaten — victory sequence

process_sound_done:  rts

; ─── Copy one 32-byte column from bank A via the boss_work pointer ───
; A = source PRG bank. Used by fortress bosses to stream arena tiles.
banked_column_copy:
        pha
        lda     boss_work_var1
        sta     jump_ptr_hi
        lda     boss_work_var2
        sta     jump_ptr
        pla
        jsr     column_copy_to_buffer
        clc
        lda     col_update_addr_lo
        adc     #$20
        sta     col_update_addr_lo
        lda     col_update_addr_hi
        adc     #$00
        sta     col_update_addr_hi
        clc
        lda     boss_work_var2
        adc     #$20
        sta     boss_work_var2
        lda     boss_work_var1
        adc     #$00
        sta     boss_work_var1
        lda     #$0B
        jsr     bank_switch
        rts

ppu_fill_from_ptr:
        jsr     bank_switch
        lda     #$00
        sta     jump_ptr
        ldx     #$04
chr_copy_ppu_loop:  lda     (jump_ptr),y
        sta     PPUDATA
        iny
        bne     chr_copy_ppu_loop
        inc     jump_ptr_hi
        dex
        bne     chr_copy_ppu_loop
        lda     #$0D
        jsr     bank_switch
        rts

; ─── Load a CHR tile group into CHR-RAM ───
; A = group index 0-6. Each group is a run of entries in the three 39-entry
; tables below (source bank, source page, page count); group runs are defined
; by chr_group_count_tbl (length) and chr_group_start_tbl (first entry).
chr_ram_bank_load:
        sta     temp_00
        tax
        lda     chr_group_count_tbl,x
        sta     temp_01                 ; entries remaining in group
        lda     chr_group_start_tbl,x
        sta     temp_02                 ; current entry index
        lda     #$00
        sta     jump_ptr
        sta     PPUADDR
        sta     PPUADDR
chr_bank_group_loop:  ldx     temp_02
        lda     chr_bank_src_page_tbl,x ; source address high byte ($xx00)
        sta     jump_ptr_hi
        lda     chr_bank_page_count_tbl,x
        sta     temp_03
        lda     chr_bank_src_bank_tbl,x
        jsr     bank_switch
        ldy     #$00
chr_copy_loop:  lda     (jump_ptr),y
        sta     PPUDATA
        iny
        bne     chr_copy_loop
        inc     jump_ptr_hi
        dec     temp_03
        bne     chr_copy_loop
        inc     temp_02
        dec     temp_01
        bne     chr_bank_group_loop
        lda     #$0D
        jsr     bank_switch
        rts

chr_group_count_tbl:  .byte   $02,$02,$03,$06,$0E,$04,$08 ; entries per CHR group
chr_group_start_tbl:  .byte   $00,$02,$04,$07,$0D,$1B,$1F ; first entry per CHR group
chr_bank_src_bank_tbl:  .byte   $05,$08,$06,$09,$06,$00,$09,$00 ; source PRG bank per entry
        .byte   $09,$08,$09,$08,$09,$03,$03,$04
        .byte   $04,$06,$04,$05,$05,$05,$07,$07
        .byte   $02,$08,$07,$05,$08,$09,$08,$00
        .byte   $06,$07,$07,$07,$02,$02,$09
chr_bank_src_page_tbl:  .byte   $90,$88,$90,$90,$90,$98,$A0,$98 ; source page (addr high) per entry
        .byte   $AC,$80,$AC,$84,$9F,$99,$9C,$9D
        .byte   $9B,$B2,$97,$93,$96,$9C,$9D,$9F
        .byte   $95,$A4,$B2,$90,$88,$9F,$8C,$98
        .byte   $B2,$9D,$9F,$AE,$96,$94,$AC
chr_bank_page_count_tbl:  .byte   $10,$10,$10,$10,$08,$08,$10,$0E ; 256-byte pages per entry
        .byte   $02,$04,$02,$04,$06,$02,$01,$01
        .byte   $01,$02,$01,$01,$02,$01,$01,$01
        .byte   $02,$0C,$02,$10,$03,$01,$0C,$08
        .byte   $01,$01,$01,$01,$01,$01,$02
; ─── Copy column data to PPU update buffer ───
scroll_column_prep:
column_copy_to_buffer:  jsr     bank_switch
        ldy     #$1F
column_copy_loop:  lda     (jump_ptr),y
        sta     col_update_tiles,y
        dey
        bpl     column_copy_loop
        lda     #$20
        sta     col_update_count
        lda     #$0D
        jsr     bank_switch
        rts

ppu_set_scroll_state:
        lda     #$01
        jsr     bank_switch
        ldx     #$1F
column_copy_from_ram:  lda     $9CD0,x
        sta     col_update_tiles,x
        dex
        bpl     column_copy_from_ram
        lda     #$08
        sta     col_update_addr_hi
        lda     #$00
        sta     col_update_addr_lo
        lda     #$20
        sta     col_update_count
        lda     #$0D
        jsr     bank_switch
        rts

ppu_column_fill:
        lda     #$09
        jsr     bank_switch
        ldy     #$1F
column_copy_from_ptr:  lda     (general_ptr_lo),y
        sta     col_update_tiles,y
        dey
        bpl     column_copy_from_ptr
        lda     #$20
        sta     col_update_count
        lda     #$0D
        jsr     bank_switch
        rts

metatile_render_column:
        lda     general_counter
        sta     jump_ptr_hi
        lda     #$00
        lsr     jump_ptr_hi
        ror     a
        lsr     jump_ptr_hi
        ror     a
        lsr     jump_ptr_hi
        ror     a
        sta     col_update_addr_lo
        sta     jump_ptr
        lda     general_counter
        cmp     #$08
        bcc     @skip
        lda     jump_ptr_hi
        jmp     @store_col_addr
@skip:
        lda     jump_ptr_hi
        adc     #$09
@store_col_addr:  sta     col_update_addr_hi
        clc
        tya
        adc     jump_ptr_hi
        sta     jump_ptr_hi
        txa
        jsr     bank_switch
        ldy     #$1F
column_copy_from_bank:  lda     (jump_ptr),y
        sta     col_update_tiles,y
        dey
        bpl     column_copy_from_bank
        lda     #$20
        sta     col_update_count
        lda     #$0D
        jsr     bank_switch
        rts

get_screen_boundary:
        lda     current_stage
        and     #$07
        jsr     bank_switch
        lda     $B400,y
        tay
        lda     #$0E
        jsr     bank_switch
        rts
boss_entrance_setup:
        lda     #$C0
        sta     ent_flags
        lda     #$80
        sta     ent_x_px
        lda     #$14
        sta     ent_y_px
        lda     #$1A                    ; player teleport-beam sprite (entity sprite table)
        sta     ent_type
; ─── Scroll boss into view on screen ───
boss_entrance_scroll:  lda     current_stage
        and     #$07
        jsr     bank_switch
        lda     #$00
        sta     ent_anim_frame
        sta     ent_anim_id
        clc
        lda     ent_y_px
        adc     #$10
        sta     ent_y_px
        ldx     checkpoint_idx
        cmp     $BB00,x
        beq     boss_entrance_done
        jsr     render_all_sprites
        jsr     wait_for_vblank
        jmp     boss_entrance_scroll

boss_entrance_done:  lda     #$30
        jsr     sound_queue_push
        lda     #$00
        sta     game_substate
        sta     max_speed_sub
        sta     max_speed_hi
        lda     #$40
        sta     scroll_dir_flags
        lda     #$0E
        jsr     bank_switch
        rts

boss_trigger_entrance:
        lda     current_stage
        sta     boss_id
boss_wily_entrance:
        lda     #$0B
        jsr     bank_switch
        jsr     banked_entry
        lda     #$0E
        jsr     bank_switch
; ─── Run one boss fight frame ───
boss_fight_frame:  lda     #$00
        sta     controller_1
        sta     p1_new_presses
        jsr     banked_0E_entity_update
        jsr     update_entity_positions
        jsr     entity_spawn_scan
        jsr     process_sound_and_bosses
        jsr     banked_sound_process
        jsr     render_all_sprites
        lda     frame_skip_lo
        beq     boss_fight_wait_vblank
        inc     frame_skip_hi
        cmp     frame_skip_hi
        beq     boss_fight_wait_render
        bcs     boss_fight_wait_vblank
boss_fight_wait_render:  jsr     wait_one_rendering_frame
        lda     #$00
        sta     frame_skip_hi
boss_fight_wait_vblank:  jsr     wait_for_vblank
        lda     boss_phase
        cmp     #$02
        bcc     boss_fight_frame
        rts

; =============================================================================
; divide_8bit — 8-bit unsigned division: $01/$02 -> quotient $03 ($C84E)
; =============================================================================
divide_8bit:  lda     #$00
        sta     temp_03
        sta     temp_04                     ; clear remainder high
        lda     temp_01
        ora     temp_02
        bne     div8_setup
        sta     temp_03
        rts

div8_setup:  ldy     #$08               ; 8 bits to process
div8_loop:  asl     temp_03
        rol     temp_01
        rol     temp_04
        sec
        lda     temp_04
        sbc     temp_02
        bcc     div8_next
        sta     temp_04
        inc     temp_03
div8_next:  dey
        bne     div8_loop
        rts

; =============================================================================
; divide_16bit — 16-bit binary long division ($C874)
; =============================================================================
; Input:  temp_0A:temp_0B = dividend (lo:hi)
;         temp_0C:temp_0D = divisor (lo:hi)
; Output: temp_0E:temp_0F = quotient (lo:hi)
;         temp_0B:temp_11 = remainder
;
; Algorithm: shift-and-subtract (restoring division). Processes 16 bits,
; shifting dividend left into remainder, subtracting divisor, and
; setting quotient bit if subtraction succeeds (no borrow).
; Returns 0 if any operand is 0.
; =============================================================================
divide_16bit:
        lda     #$00
        sta     temp_11                 ; clear remainder (hi)
        sta     temp_10                 ; clear quotient accumulator
        lda     temp_0B                 ; check for zero operands
        ora     temp_0A
        ora     temp_0D
        ora     temp_0C
        bne     div16_setup
        sta     temp_0F                 ; both zero → return 0
        sta     temp_0E
        rts

div16_setup:
        ldy     #$10                    ; 16 iterations (one per bit)
div16_loop:
        asl     temp_10                 ; shift quotient left (make room for new bit)
        rol     temp_0A                 ; shift dividend left into remainder
        rol     temp_0B
        rol     temp_11
        sec                             ; trial subtraction: remainder - divisor
        lda     temp_0B
        sbc     temp_0C
        tax
        lda     temp_11
        sbc     temp_0D
        bcc     div16_next              ; borrow = divisor doesn't fit
        stx     jump_ptr_hi             ; no borrow: keep subtraction result
        sta     temp_11
        inc     temp_10                 ; set quotient bit (bit 0)
div16_next:
        dey
        bne     div16_loop
        lda     temp_0A                 ; move quotient to output
        sta     temp_0F
        lda     temp_10
        sta     temp_0E
        rts

attr_table_write:
        ldx     ppu_buffer_count
        ldy     #$20
        lda     jump_ptr_hi
        and     #$01
        beq     @skip
        ldy     #$24
@skip:
        sty     temp_0B
        lda     jump_ptr
        lsr     a
        lsr     a
        pha
        lsr     a
        and     #$03
        ora     temp_0B
        sta     ppu_update_buf,x
        pla
        pha
        ror     a
        and     #$FC
        sta     ppu_update_buf + $04,x
        lda     temp_0B
        ora     #$03
        sta     ppu_update_buf + $08,x
        pla
        sta     temp_0A
        lsr     a
        lsr     a
        lsr     a
        asl     temp_0A
        asl     temp_0A
        asl     temp_0A
        ora     temp_0A
        ora     #$C0
        sta     ppu_update_buf + $0C,x
        rts

; ─── metatile_render ($C8EF) — cross-bank entry (see fixed_bank.inc) ───
; Stages a scroll-column attribute write into the column update buffer.
metatile_render:  ldx     attr_update_count
        ldy     #$08
        lda     jump_ptr_hi
        and     #$01
        beq     @skip_2
        ldy     #$09
@skip_2:
        sty     temp_0B
        lda     temp_0A
        and     #$F8
        asl     a
        rol     temp_0B
        asl     a
        rol     temp_0B
        sta     col_update_tiles + $04,x
        lda     jump_ptr
        lsr     a
        lsr     a
        lsr     a
        ora     col_update_tiles + $04,x
        sta     col_update_tiles + $04,x
        lda     temp_0B
        sta     col_update_addr_hi,x
        rts

metatile_attr_update:
        pha
        lda     jump_ptr
        pha
        ldx     attr_update_count
        lda     temp_0A
        and     #$E0
        lsr     a
        lsr     a
        sta     temp_0B
        asl     jump_ptr
        rol     a
        asl     jump_ptr
        rol     a
        asl     jump_ptr
        rol     a
        ora     temp_0B
        ora     #$C0
        sta     col_update_tiles + $10,x
        ldy     #$23
        lda     jump_ptr_hi
        and     #$01
        beq     attr_set_nametable
        ldy     #$27
attr_set_nametable:  tya
        sta     col_update_tiles + $0A,x
        ldy     #$00
        pla
        and     #$10
        beq     attr_check_row
        iny
attr_check_row:  lda     temp_0A
        and     #$10
        beq     attr_calc_mask
        iny
        iny
attr_calc_mask:  pla
        and     attr_mask_table,y
        sta     col_update_tiles + $16,x
        lda     attr_mask_table,y
        eor     #$FF
        sta     col_update_tiles + $1C,x
        rts

attr_mask_table:  .byte   $03,$0C,$30,$C0
; ─── Copy metatile column from stage bank ───
column_data_copy:  lda     current_stage
        and     #$07
        jsr     bank_switch
        lda     #$20
        sta     temp_0B
        ldy     #$00
        lda     (jump_ptr),y
        tax
        tay
        lda     $8400,y
        pha
        txa
        asl     a
        rol     temp_0B
        asl     a
        rol     temp_0B
        sta     temp_0A
        lda     ppu_buffer_count
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
        lda     (temp_0A),y
        asl     a
        asl     a
        clc
        sta     ppu_update_buf + $10,x
        adc     #$01
        sta     ppu_update_buf + $14,x
        adc     #$01
        sta     ppu_update_buf + $11,x
        adc     #$01
        sta     ppu_update_buf + $15,x
        iny
        cpy     #$04
        bne     metatile_render_loop
        pla
        ldy     #$20
        lda     jump_ptr
        and     #$40
        beq     metatile_set_base_nt
        ldy     #$24
metatile_set_base_nt:  sty     temp_0D
        lda     column_index
        sta     temp_0C
        lsr     a
        ror     temp_0C
        lda     temp_0C
        pha
        and     #$03
        ora     temp_0D
        sta     temp_0D
        pla
        and     #$FC
        ldx     ppu_buffer_count
        sta     ppu_update_buf + $04,x
        lda     temp_0D
        sta     ppu_update_buf,x
        lda     temp_0D
        ora     #$03
        sta     ppu_update_buf + $08,x
        lda     column_index
        sta     temp_0C
        lsr     a
        lsr     a
        lsr     a
        asl     temp_0C
        asl     temp_0C
        asl     temp_0C
        ora     #$C0
        ora     temp_0C
        sta     ppu_update_buf + $0C,x
        pla
        sta     ppu_update_buf + $50,x
        inc     ppu_buffer_count
        lda     #$0E
        jsr     bank_switch
        rts

metatile_offset_table:  .byte   $00,$08,$02,$0A

; ─── metatile_column_render ($CA0B) — cross-bank entry (see fixed_bank.inc) ───
; column_data_copy wrapper that preserves the caller's PRG bank.
metatile_column_render:  lda     current_bank
        pha
        jsr     column_data_copy
        pla
        jsr     bank_switch
        rts
; --- DEAD CODE: unreachable metatile attribute update routine (no entry point) ---
; Labels metatile_attr_loop and metatile_attr_done are only self-referenced.
; Complete routine that loads stage bank, computes PPU attribute data, and
; writes to update buffer — but nothing calls or branches into it.
scroll_y_update:
        lda     current_stage
        and     #$07
        jsr     bank_switch
        lda     column_attr_byte
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     ppu_update_buf
        lda     column_attr_byte
        asl     a
        asl     a
        asl     a
        pha
        and     #$18
        sta     ppu_update_buf + $01
        pla
        asl     a
        and     #$C0
        ora     ppu_update_buf + $01
        sta     ppu_update_buf + $01
        lda     column_attr_byte
        and     #$F8
        ora     #$C0
        sta     ppu_update_buf + $13
        lda     column_attr_byte
        and     #$03
        asl     a
        ora     ppu_update_buf + $13
        sta     ppu_update_buf + $13
        ldx     #$20
        lda     nametable_select
        and     #$01
        beq     @skip
        ldx     #$24
@skip:
        txa
        ora     ppu_update_buf
        sta     ppu_update_buf
        txa
        ora     #$03
        sta     ppu_update_buf + $12
        lda     #$00
        sta     temp_00
        lda     column_attr_byte
        and     #$3B
        lsr     a
        ror     temp_00
        lsr     a
        ror     temp_00
        lsr     a
        ror     temp_00
        lsr     temp_00
        ora     temp_00
        sta     temp_00
        lda     ent_x_screen
        ldx     #$00
        stx     jump_ptr
        lsr     a
        ror     jump_ptr
        lsr     a
        ror     jump_ptr
        clc
        adc     #$85
        sta     jump_ptr_hi
        stx     temp_01
metatile_attr_loop:  ldy     temp_00
        lda     (jump_ptr),y
        sta     temp_03
        sta     temp_0A
        lda     #$20
        asl     temp_0A
        rol     a
        asl     temp_0A
        rol     a
        sta     temp_0B
        ldy     #$00
        lda     column_attr_byte
        and     #$04
        beq     metatile_attr_count
        iny
metatile_attr_count:  lda     #$02
        sta     temp_02
metatile_attr_inner:  lda     (temp_0A),y
        asl     a
        asl     a
        clc
        sta     ppu_update_buf + $02,x
        adc     #$01
        sta     ppu_update_buf + $0A,x
        adc     #$01
        sta     ppu_update_buf + $03,x
        adc     #$01
        sta     ppu_update_buf + $0B,x
        inx
        inx
        iny
        iny
        dec     temp_02
        bne     metatile_attr_inner
        lda     column_attr_byte
        ldy     #$0F
        and     #$04
        beq     metatile_attr_mask_setup
        ldy     #$F0
metatile_attr_mask_setup:  sty     ppu_update_buf + $14
        ldy     temp_03
        lda     $8400,y
        and     ppu_update_buf + $14
        ldy     temp_01
        sta     ppu_update_buf + $15,y
        lda     temp_00
        ora     #$08
        sta     temp_00
        inc     temp_01
        lda     temp_01
        cmp     #$02
        beq     metatile_attr_done
        jmp     metatile_attr_loop

metatile_attr_done:  lda     #$80
        sta     ppu_buffer_count
        lda     #$FF
        eor     ppu_update_buf + $14
        sta     ppu_update_buf + $14
        lda     #$0E
        jsr     bank_switch
        rts

; ─── scroll_column_render ($CB0C) — cross-bank entry (see fixed_bank.inc) ───
; Streams the per-screen enemy CHR overlay: uploads two 16-byte tile columns
; per call to pattern table $0A00+ from the stage bank's $B460 CHR list.
scroll_column_render:  lda     general_counter
        cmp     #$60
        bcc     @skip
        rts
@skip:
        lda     current_bank
        pha
        lda     general_counter
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        pha
        lsr     a
        clc
        adc     #$0A
        sta     col_update_addr_hi
        lda     general_counter
        asl     a
        asl     a
        asl     a
        asl     a
        sta     col_update_addr_lo
        sta     jump_ptr
        lda     current_stage
        and     #$07
        jsr     bank_switch
        ldx     general_ptr_lo
        jsr     scroll_col_load_palette
        clc
        pla
        adc     $B42C,x
        tax
        lda     $B460,x
        sta     jump_ptr_hi
        lda     $B461,x
        jsr     bank_switch
        ldy     #$1F
scroll_col_copy_loop:  lda     (jump_ptr),y
        sta     col_update_tiles,y
        dey
        bpl     scroll_col_copy_loop
        lda     #$20
        sta     col_update_count
        inc     general_counter
        inc     general_counter
        pla
        jsr     bank_switch
        rts

; ─── Load sprite palette for scroll column ───
scroll_col_load_palette:  ldy     $B42C,x
        lda     $B46C,y
        sta     palette_sprite + $09
        lda     $B46D,y
        sta     palette_sprite + $0A
        lda     $B46E,y
        sta     palette_sprite + $0B
        lda     $B46F,y
        sta     palette_sprite + $0D
        lda     $B470,y
        sta     palette_sprite + $0E
        lda     $B471,y
        sta     palette_sprite + $0F
        rts

; ─── Build list of active entity slots ───
build_active_list:
        ldx     #$0F
        ldy     #$00
build_active_entity_list:  lda     ent_spawn_flags,x
        bpl     active_entity_next
        and     #$10
        beq     active_entity_next
        stx     active_entity_list,y
        iny
active_entity_next:  dex
        bpl     build_active_entity_list
        sty     active_entity_count
        rts

; =============================================================================
; lookup_cached_tile — Look up tile collision from cached active entity list ($CBA2)
; =============================================================================
lookup_cached_tile:  ldy     active_entity_count
cached_tile_scan_loop:  dey
        bmi     lookup_tile_from_map
        ldx     active_entity_list,y
        lda     jump_ptr
        and     ent_hitbox_w_lo,x
        cmp     ent_hitbox_h_lo,x
        bne     cached_tile_scan_loop
        lda     temp_0A
        and     ent_hitbox_w_hi,x
        cmp     ent_hitbox_h_hi,x
        bne     cached_tile_scan_loop
        lda     ent_drop_flag,x
        sta     temp_00
        rts

; =============================================================================
; lookup_tile_from_map — Convert pixel position to collision type ($CBC3)
; =============================================================================
; Input:  jump_ptr/jump_ptr_hi = X pixel / screen number
;         temp_0A/temp_0B = Y pixel / Y screen offset (0=same, neg=above, pos=below)
; Output: temp_00 = collision type (0=empty, 1=solid, 2-7=stage-specific)
;
; Algorithm:
;   1. Bounds-check Y screen offset
;   2. Compute 6-bit metatile map index: col*8 + row (column-major)
;      col = X_pixel >> 5 (bits 7-5 → 0-7), row = Y_pixel >> 5 (bits 7-5 → 0-7)
;   3. Build pointer to screen's metatile map from screen number
;   4. Load metatile ID, compute metatile data address ($2000 + ID*4)
;   5. Select quadrant (2×2 tile within metatile) from pixel bits 4
;   6. Extract 2-bit collision type from bits 7-6 of quadrant byte
;   7. Types 2-3: look up stage-specific collision via stage_collision_table
; =============================================================================
lookup_tile_from_map:  lda     current_stage
        and     #$07
        jsr     bank_switch             ; switch to stage data bank
        lda     #$00
        sta     temp_00
        lda     temp_0B                 ; Y screen offset
        beq     tile_lookup_calc_index  ; 0 = same screen
        bmi     tile_lookup_clear_y     ; negative = above screen (clamp Y to 0)
        jmp     tile_lookup_done        ; positive = below screen (out of bounds)

tile_lookup_clear_y:  lda     #$00
        sta     temp_0A
; --- Step 2: pixel → 6-bit metatile map index (column-major) ---
; Each screen is 8×8 metatiles (32px each). Index = col*8 + row.
tile_lookup_calc_index:
        lda     jump_ptr                ; X pixel position
        lsr     a
        lsr     a
        and     #$38                    ; col = X>>5, shifted to bits 5-3
        sta     temp_00
        lda     temp_0A                 ; Y pixel position
        asl     a                       ; rotate bits 7-5 down to bits 2-0
        rol     a                       ;   via 4 left rotations (wraps through carry)
        rol     a
        rol     a
        and     #$07                    ; row = Y>>5, in bits 2-0
        ora     temp_00                 ; index = col*8 | row
        sta     temp_00
; --- Step 3: build pointer to screen's metatile map ---
; Map pages start at $8500. Screen number selects page + offset.
; temp_0C:temp_0D = $8500 + screen_number * 64
        lda     #$00
        sta     temp_0C
        lda     jump_ptr_hi             ; screen number
        lsr     a                       ; bits 1-0 → temp_0C bits 7-6 (offset within page)
        ror     temp_0C
        lsr     a
        ror     temp_0C
        clc
        adc     #$85                    ; page = $85 + (screen >> 2)
        sta     temp_0D
; --- Step 4: load metatile ID → compute metatile data address ---
        ldy     temp_00
        lda     (temp_0C),y             ; metatile ID from map
        sta     temp_0C
        lda     #$20                    ; base = $2000 (metatile definition data)
        asl     temp_0C                 ; metatile_ID * 4 (each metatile = 4 quadrant bytes)
        rol     a
        asl     temp_0C
        rol     a
        sta     temp_0D                 ; (temp_0C:temp_0D) = $2000 + ID*4
; --- Step 5: select quadrant within 2×2 metatile ---
; Bit 4 of X pixel = left(0)/right(+2), bit 4 of Y pixel = top(0)/bottom(+1)
        ldy     #$00
        lda     jump_ptr
        and     #$10                    ; X bit 4: right half of metatile?
        beq     tile_check_vert
        iny                             ; +2 = right column
        iny
tile_check_vert:  lda     temp_0A
        and     #$10                    ; Y bit 4: bottom half of metatile?
        beq     tile_get_collision_type
        iny                             ; +1 = bottom row
; --- Step 6: extract 2-bit collision type from bits 7-6 ---
tile_get_collision_type:  lda     (temp_0C),y  ; quadrant byte (tile + collision)
        sta     temp_00
        asl     temp_00                 ; shift bit 7 → carry
        rol     a                       ; carry → A bit 0
        asl     temp_00                 ; shift bit 6 → carry
        rol     a                       ; carry → A bit 0
        and     #$03                    ; collision type (0-3)
; --- Step 7: map collision type to game value ---
; Type 0 = empty, type 1 = solid (returned as-is)
; Types 2-3 = stage-specific via table (2 entries per stage)
        sta     temp_00
        lsr     a                       ; 0,1 → 0 (done); 2,3 → 1 (lookup)
        beq     tile_lookup_done
        dec     temp_00                 ; type - 1
        dec     temp_00                 ; type - 2 (table offset: 0 or 1)
        lda     current_stage
        asl     a                       ; stage * 2 (2 entries per stage)
        adc     temp_00                 ; + table offset
        tax
        lda     stage_collision_table,x
        sta     temp_00
tile_lookup_done:  lda     #$0E
        jsr     bank_switch
        rts

; Collision type mapping per stage: 2 entries each (for metatile types 2 and 3)
; Stages: Heat, Air, Wood, Bubble, Quick, Flash, Metal, Crash, Wily1-4
stage_collision_table:  .byte   $02,$03,$02,$03,$02,$00,$04,$03
        .byte   $00,$03,$02,$07,$05,$06,$02,$03
        .byte   $02,$00,$02,$03,$04,$03,$02,$03
        .byte   $00,$00,$00,$00
tile_lookup:
        jsr     lookup_cached_tile
        lda     #$0B
        jsr     bank_switch
        rts

; =============================================================================
; clear_oam_buffer — Fill OAM buffer with $F8 (hide all sprites) ($CC6C)
; =============================================================================
clear_oam_buffer_fixed:
clear_oam_buffer:  lda     #$F8         ; $F8 = off-screen Y (hide sprite)
        ldx     #$00
clear_oam_loop:  sta     oam_buffer,x        ; write $F8 to OAM Y position
        inx
        bne     clear_oam_loop
        rts

; =============================================================================
; render_all_sprites — Main sprite rendering — build OAM buffer from entity data ($CC77)
; =============================================================================
render_all_sprites:  lda     #$0A       ; switch to sprite data bank
        jsr     bank_switch             ; bank $0A: frame + OAM offset data
        jsr     clear_oam_buffer        ; clear all sprites first
        lda     #$00
        sta     temp_06
        sta     temp_0D
        sta     temp_0C
        lda     game_mode
        beq     render_even_frame
        jmp     render_special_mode

render_even_frame:  lda     frame_counter         ; frame counter (odd/even toggle)
        and     #$01
        bne     render_odd_frame
        lda     #$FF
        sta     temp_0C
        lda     #$00
        sta     current_entity_slot
render_entity_forward:  jsr     render_entity_normal
        bcs     render_even_done
        inc     current_entity_slot
        lda     current_entity_slot
        cmp     #$10
        bne     render_entity_forward
render_weapon_forward:  jsr     render_weapon_normal
        bcs     render_even_done
        inc     current_entity_slot
        lda     current_entity_slot
        cmp     #$20
        bne     render_weapon_forward
        lda     temp_06
        sta     temp_0C
        jsr     render_hp_bars
render_even_done:  jmp     render_priority_fix

render_odd_frame:  jsr     render_hp_bars
        lda     temp_06
        sta     temp_0D
        lda     #$1F
        sta     current_entity_slot
render_weapon_reverse:  jsr     render_weapon_normal
        bcs     render_priority_fix
        dec     current_entity_slot
        lda     current_entity_slot
        cmp     #$0F
        bne     render_weapon_reverse
render_entity_reverse:  jsr     render_entity_normal
        bcs     render_priority_fix
        dec     current_entity_slot
        bpl     render_entity_reverse
        lda     temp_06
        sta     temp_0C
render_priority_fix:  lda     current_stage
        cmp     #$01
        bne     render_sprites_done
        ldx     temp_0D
render_priority_loop:  cpx     temp_0C
        beq     render_sprites_done
        lda     oam_buffer + $02,x
        ora     #$20
        sta     oam_buffer + $02,x
        inx
        inx
        inx
        inx
        bne     render_priority_loop
render_sprites_done:  lda     #$0E      ; switch back to game engine
        jsr     bank_switch
        rts

render_special_mode:  lda     frame_counter
        and     #$01
        bne     render_special_odd
        lda     #$FF
        sta     temp_0C
        lda     #$00
        sta     current_entity_slot
        lda     game_mode
        and     #$04
        beq     render_special_check_entity
        jsr     render_entity_special
        jmp     render_special_entity_loop

render_special_check_entity:  jsr     render_entity_normal
render_special_entity_loop:  inc     current_entity_slot
render_special_entity_inner:  lda     game_mode
        and     #$02
        bne     render_special_jump_1
        jsr     render_entity_normal
        jmp     render_special_carry

render_special_jump_1:  jsr     render_entity_special
render_special_carry:  bcs     render_special_done
        inc     current_entity_slot
        lda     current_entity_slot
        cmp     #$10
        bne     render_special_entity_inner
render_special_weapon:  jsr     render_weapon_special
        bcs     render_special_done
        inc     current_entity_slot
        lda     current_entity_slot
        cmp     #$20
        bne     render_special_weapon
        lda     temp_06
        sta     temp_0C
        jsr     render_hp_bars
render_special_done:  jmp     render_priority_fix

render_special_odd:  jsr     render_hp_bars
        lda     temp_06
        sta     temp_0D
        lda     #$1F
        sta     current_entity_slot
render_special_weapon_rev:  jsr     render_weapon_special
        bcs     render_special_jump_end
        dec     current_entity_slot
        lda     current_entity_slot
        cmp     #$0F
        bne     render_special_weapon_rev
render_special_entity_rev:  lda     game_mode
        and     #$02
        bne     render_special_entity_inner_2
        jsr     render_entity_normal
        jmp     render_special_carry_2

render_special_entity_inner_2:  jsr     render_entity_special
render_special_carry_2:  bcs     render_special_jump_end
        dec     current_entity_slot
        bne     render_special_entity_rev
        lda     game_mode
        and     #$04
        beq     render_special_check_2
        jsr     render_entity_special
        jmp     render_special_jump_2

render_special_check_2:  jsr     render_entity_normal
render_special_jump_2:  lda     temp_06
        sta     temp_0C
render_special_jump_end:  jmp     render_priority_fix

; ─── Render entity in special mode ───
render_entity_special:  ldx     current_entity_slot
        lda     ent_flags,x
        bmi     render_entity_get_sprite_ptr
        clc
        rts

render_entity_get_sprite_ptr:  ldy     ent_type,x
        lda     sprite_def_ptr_lo,y
        sta     jump_ptr
        lda     sprite_def_ptr_hi,y
        sta     jump_ptr_hi
        lda     ent_anim_id,x
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        beq     render_entity_deactivate
        jmp     render_begin_oam_write

render_entity_deactivate:  lsr     ent_flags,x
        rts

; ─── Render weapon in special mode ───
render_weapon_special:  ldx     current_entity_slot
        lda     ent_flags,x
        bmi     render_weapon_get_sprite_ptr
        clc
        rts

render_weapon_get_sprite_ptr:  ldy     ent_type,x
        lda     sprite_def_ptr_lo_wpn,y
        sta     jump_ptr
        lda     sprite_def_ptr_hi_wpn,y
        sta     jump_ptr_hi
        lda     ent_anim_id,x
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        beq     render_weapon_deactivate
        jmp     render_weapon_begin_write

render_weapon_deactivate:  lsr     ent_flags,x
        rts

; =============================================================================
; render_entity_normal — Render a normal entity's sprites to OAM ($CDE7)
; =============================================================================
render_entity_normal:  ldx     current_entity_slot
        lda     ent_flags,x                 ; check entity active flag
        bmi     render_entity_get_ptr
        clc
        rts

render_entity_get_ptr:  ldy     ent_type,x
        lda     sprite_def_ptr_lo,y
        sta     jump_ptr
        lda     sprite_def_ptr_hi,y
        sta     jump_ptr_hi
        lda     ent_anim_id,x
        pha
        inc     ent_anim_frame,x
        ldy     #$01
        lda     (jump_ptr),y
        cmp     ent_anim_frame,x
        bcs     render_entity_check_frame
        lda     #$00
        sta     ent_anim_frame,x
        inc     ent_anim_id,x
        dey
        lda     (jump_ptr),y
        cmp     ent_anim_id,x
        bcs     render_entity_check_frame
        lda     #$00
        sta     ent_anim_id,x
render_entity_check_frame:  pla
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        bne     render_begin_oam_write
        lsr     ent_flags,x
        rts

render_begin_oam_write:  tay
        cpx     #$01
        bcs     render_skip_flash
        lda     invincibility_timer
        beq     render_check_flash
        dec     invincibility_timer
        lda     frame_counter
        and     #$02
        beq     render_check_flash
render_flash_jump:  jmp     render_ok_return

render_check_flash:  lda     player_y_screen
        bne     render_flash_jump
        beq     render_load_sprite_data
render_skip_flash:  bne     render_load_sprite_data
        lda     boss_hit_timer
        beq     render_load_sprite_data
        lda     frame_counter
        and     #$02
        bne     render_dec_extra_timer
        ldy     #$18
render_dec_extra_timer:  dec     boss_hit_timer
render_load_sprite_data:  lda     spr_frame_ptr_lo,y ; frame data ptr (bank $0A)
        sta     jump_ptr
        lda     spr_frame_ptr_hi,y
        sta     jump_ptr_hi
        lda     #$00
        sta     temp_03
render_sprite_loop:  ldy     #$00
        lda     (jump_ptr),y
        sta     temp_04
        iny
        lda     (jump_ptr),y
        tay
        lda     spr_offset_ptr_lo,y     ; OAM offset data ptr (bank $0A)
        sta     temp_0A
        lda     spr_offset_ptr_hi,y
        sta     temp_0B
        sec
        lda     ent_x_px,x
        sbc     scroll_x
        sta     temp_00
        lda     ent_x_screen,x
        sbc     nametable_select
        lda     ent_y_px,x
        sta     temp_01
        lda     ent_flags,x
        and     #$40
        sta     temp_02
        lda     #$02
        sta     temp_07
render_sprite_oam_entry:  ldx     temp_06
        ldy     temp_07
        lda     (jump_ptr),y
        sta     oam_buffer + $01,x
        clc
        lda     (temp_0A),y
        adc     temp_01
        sta     oam_buffer,x
        iny
        lda     temp_03
        beq     render_sprite_load_tile
        lda     (jump_ptr),y
        and     #$F0
        ora     temp_03
        bne     render_sprite_apply_flip
render_sprite_load_tile:  lda     (jump_ptr),y
render_sprite_apply_flip:  eor     temp_02
        sta     oam_buffer + $02,x
        lda     temp_02
        beq     render_sprite_no_flip_x
        lda     (temp_0A),y
        tay
        lda     spr_flip_x_tbl,y        ; mirrored X offset (bank $0A)
        jmp     render_sprite_write_x

render_sprite_no_flip_x:  lda     (temp_0A),y
render_sprite_write_x:  clc
        bmi     render_sprite_neg_x
        adc     temp_00
        bcc     render_sprite_store_x
        bcs     render_sprite_offscreen
render_sprite_neg_x:  adc     temp_00
        bcs     render_sprite_store_x
render_sprite_offscreen:  lda     #$F8
        sta     oam_buffer,x
        bne     render_sprite_next
render_sprite_store_x:  sta     oam_buffer + $03,x
        clc
        txa
        adc     #$04
        sta     temp_06
        beq     render_full_return
render_sprite_next:  inc     temp_07
        inc     temp_07
        dec     temp_04
        bne     render_sprite_oam_entry
render_ok_return:  clc
        rts

render_full_return:  sec
        rts

; =============================================================================
; render_weapon_normal — Render a weapon entity's sprites to OAM ($CEF9)
; =============================================================================
render_weapon_normal:  ldx     current_entity_slot
        lda     ent_flags,x
        bmi     render_weapon_get_ptr
        clc
        rts

render_weapon_get_ptr:  ldy     ent_type,x
        lda     sprite_def_ptr_lo_wpn,y
        sta     jump_ptr
        lda     sprite_def_ptr_hi_wpn,y
        sta     jump_ptr_hi
        lda     ent_anim_id,x
        pha
        inc     ent_anim_frame,x
        ldy     #$01
        lda     (jump_ptr),y
        cmp     ent_anim_frame,x
        bcs     render_weapon_check_frame
        lda     #$00
        sta     ent_anim_frame,x
        inc     ent_anim_id,x
        dey
        lda     (jump_ptr),y
        cmp     ent_anim_id,x
        bcs     render_weapon_check_frame
        lda     #$00
        sta     ent_anim_id,x
render_weapon_check_frame:  pla
        clc
        adc     #$02
        tay
        lda     (jump_ptr),y
        bne     render_weapon_begin_write
        lsr     ent_flags,x
        rts

render_weapon_begin_write:  tay
        lda     ent_flags,x
        and     #$20
        bne     render_weapon_skip
        lda     wpn_frame_ptr_lo,y      ; weapon frame data ptr (bank $0A)
        sta     jump_ptr
        lda     wpn_frame_ptr_hi,y
        sta     jump_ptr_hi
        lda     ent_hit_count,x
        sta     temp_03
        jmp     render_sprite_loop

render_weapon_skip:  clc
        rts

; =============================================================================
; render_hp_bars — Render player and boss HP bars ($CF5D)
; =============================================================================
render_hp_bars:  lda     ent_hp          ; player HP (entity slot 0)
        sta     temp_00
        ldx     temp_06
        lda     #$01
        sta     temp_02
        lda     #$18
        sta     temp_01
        jsr     render_hp_bar_loop
        bcs     render_hp_done
        ldy     current_weapon
        beq     render_weapon_hp
        lda     weapon_ammo - 1,y       ; ammo for current weapon (1-indexed)
        sta     temp_00
        lda     #$00
        sta     temp_02
        lda     #$10
        sta     temp_01
        jsr     render_hp_bar_loop
        bcs     render_hp_done
render_weapon_hp:  lda     boss_phase
        beq     render_hp_done
        lda     boss_hp
        sta     temp_00
        lda     #$03
        ldy     boss_id
        cpy     #$08
        beq     render_boss_hp_start
        cpy     #$0D
        bne     render_boss_hp_setup
render_boss_hp_start:  lda     #$01
render_boss_hp_setup:  sta     temp_02
        lda     #$28
        sta     temp_01
        jsr     render_hp_bar_loop
render_hp_done:  rts

render_hp_bar_loop:  ldy     #$06
render_hp_entry:  lda     hp_y_positions_tbl,y
        sta     oam_buffer,x
        sec
        lda     temp_00
        sbc     #$04
        bcs     render_hp_empty_check
        ldx     temp_00
        lda     #$00
        sta     temp_00
        lda     hp_tile_ids_tbl,x
        ldx     temp_06
        jmp     render_hp_set_tile

render_hp_empty_check:  sta     temp_00
        lda     #$87
render_hp_set_tile:  sta     oam_buffer + $01,x
        lda     temp_02
        sta     oam_buffer + $02,x
        lda     temp_01
        sta     oam_buffer + $03,x
        inx
        inx
        inx
        inx
        stx     temp_06
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
        lda     vblank_done
        beq     nmi_do_vblank
        jmp     nmi_tail

nmi_do_vblank:                          ; Main VBLANK processing path
        lda     ppuctrl_shadow
        and     #$7C                    ; Disable NMI + clear nametable bits
        sta     ppuctrl_shadow
        sta     PPUCTRL
        lda     ppumask_shadow
        and     #$E7                    ; Disable sprite/bg rendering during updates
        sta     ppumask_shadow
        sta     PPUMASK
        lda     PPUSTATUS               ; Reset PPUADDR latch
        lda     #$00
        sta     OAMADDR
        lda     #$02
        sta     OAMDMA                  ; OAM DMA from $0200 (sprite data)
        lda     ppu_buffer_count
        beq     nmi_update_palette      ; Skip if no buffered PPU writes
        jsr     ppu_buffer_transfer
nmi_update_palette:  jsr     upload_palette  ; Always refresh palette from RAM
        lda     col_update_count                     ; col_update_count: queued column tiles?
        beq     nmi_check_scroll_update
        jsr     ppu_scroll_column_update ; write vertical tile column to nametable
nmi_check_scroll_update:  lda     attr_update_count ; attr_update_count: queued attribute writes?
        beq     nmi_check_ppu_update
        jsr     ppu_attribute_update    ; write attribute table entries
; ---------------------------------------------------------------------------
; PPU Scroll Register Setup
; ---------------------------------------------------------------------------
; The NES PPUSCROLL register takes two sequential writes: X then Y.
; Camera offsets ($B8/$B9 for X, $B6 for Y) are subtracted to implement
; screen shake effects (boss explosions, Mecha Dragon, etc.).
; After scroll writes, PPUCTRL bit 0 selects which nametable is the
; "base" — computed as nametable_select XOR scroll_x_carry, which
; ensures seamless horizontal scrolling across both nametables.
; ---------------------------------------------------------------------------
nmi_check_ppu_update:
        lda     PPUSTATUS               ; Reset PPUADDR/PPUSCROLL latch
        lda     #$00
        sta     temp_01                 ; scroll X high bit (nametable select)
        lda     scroll_x
        sta     temp_00                 ; temp_00 = base scroll X
        lda     camera_x_offset                     ; camera_x_offset (screen shake)
        beq     nmi_set_scroll_x        ; zero = no shake, skip subtraction
        sec
        lda     temp_00
        sbc     camera_x_offset                     ; subtract low byte of X offset
        sta     temp_00
        lda     #$00
        sbc     camera_x_offset_hi                     ; subtract high byte (borrow → nametable flip)
        and     #$01                    ; keep only nametable bit
        sta     temp_01                 ; XOR'd with nametable_select below
nmi_set_scroll_x:
        lda     temp_00
        sta     PPUSCROLL               ; First write: scroll X (0-255)
        lda     scroll_y
        sta     temp_00                 ; temp_00 = base scroll Y
        lda     camera_y_offset                     ; camera_y_offset (screen shake)
        beq     nmi_set_scroll_y        ; zero = no shake
        sec
        lda     temp_00
        sbc     camera_y_offset                     ; subtract Y offset
        sta     temp_00
nmi_set_scroll_y:
        lda     temp_00
        sta     PPUSCROLL               ; Second write: scroll Y (0-239)
        lda     ppumask_shadow
        ora     #$1E                    ; Re-enable sprites + background
        sta     ppumask_shadow
        sta     PPUMASK
        lda     ppuctrl_shadow
        ora     #$80                    ; Re-enable NMI
        sta     ppuctrl_shadow
        lda     nametable_select        ; base nametable (0 or 1)
        eor     temp_01                 ; XOR with carry from scroll_x - camera offset
        and     #$01                    ; isolate bit 0 (horizontal nametable select)
        ora     ppuctrl_shadow          ; merge with NMI + increment mode bits
        ora     sprite_8x16_flag                     ; merge sprite size flag (8×16 if set)
        sta     ppuctrl_shadow
        sta     PPUCTRL                 ; Write final PPUCTRL
        sta     vblank_done             ; Set "VBLANK done" flag (nonzero = processed)
        inc     frame_counter
; --- NMI exit: sound engine update ---
; If NMI interrupted a bank switch in progress ($68≠0), defer the sound
; update (bank_switch runs it after finishing); otherwise switch to bank
; $0C, tick the sound driver, and dispatch queued sound commands.
nmi_tail:  lda     bank_switch_active
        beq     nmi_sound_bank
        inc     sound_pending           ; defer: bank_switch will run sound
        bne     nmi_rng_and_exit
nmi_sound_bank:  lda     #$0C           ; switch to bank $0C (sound engine)
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        lsr     a
        sta     mmc1_scratch
        jsr     banked_entry            ; sound engine per-frame tick ($8000)
nmi_process_queue:  ldx     sound_queue_count
        beq     nmi_queue_done
        lda     sound_queue - 1,x
        cmp     #$FD                    ; $FD (music fade) takes fade params in Y
        bne     nmi_queue_call
        ldy     #$A0
nmi_queue_call:  jsr     banked_entry_alt ; sound command dispatch ($8003)
        dec     sound_queue_count
        bne     nmi_process_queue
nmi_queue_done:  lda     current_bank
        jsr     bank_switch
; --- RNG update: seed = (ent_x_sub XOR seed + frame_counter) >> 1 ---
nmi_rng_and_exit:
        lda     ent_x_sub               ; entity subpixel as entropy source
        eor     rng_seed                ; mix with current state
        adc     frame_counter           ; add frame counter for variation
        lsr     a                       ; shift right (distribute bits)
        sta     rng_seed
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
        stx     JOY1
        dex
        stx     JOY1
        inx
read_controller_loop:  ldy     #$08     ; Read 8 bits from controller X
read_controller_bits:  lda     JOY1,x  ; Shift in one button bit
        sta     p1_new_presses
        lsr     a
        ora     p1_new_presses
        lsr     a
        ror     controller_1,x
        dey
        bne     read_controller_bits
        dex
        bpl     read_controller_loop
        rts


; =============================================================================
; PPU Update Routines
; =============================================================================
; ─── Upload palette RAM to PPU ───
upload_palette:  ldy     #$3F           ; Upload 32-byte palette from $0356 to PPU $3F00
        sty     PPUADDR
        ldx     #$00
        stx     PPUADDR
upload_palette_loop:  lda     palette_ram,x   ; Copy palette bytes to PPUDATA
        sta     PPUDATA
        inx
        cpx     #$20
        bne     upload_palette_loop
        sty     PPUADDR
        lda     #$00
        sta     PPUADDR
        sta     PPUADDR
        sta     PPUADDR
        sta     palette_dirty
        rts

; ─── Transfer PPU update buffer to VRAM ───
ppu_buffer_transfer:  bpl     ppu_buffer_transfer_main; Transfer PPU update buffer to VRAM
        jmp     ppu_buffer_transfer_alt

ppu_buffer_transfer_main:  ldy     #$00
ppu_buffer_entry_loop:  sty     temp_00
        tya
        asl     a
        asl     a
        asl     a
        asl     a
        tax
        lda     #$04
        sta     temp_01
        lda     ppu_update_buf,y
        sta     temp_0B
        lda     ppu_update_buf + $04,y
        sta     temp_0A
        cmp     #$80
        bcc     ppu_buffer_write_entry
        lda     temp_0B
        and     #$03
        cmp     #$03
        bne     ppu_buffer_write_entry
        lda     #$02
        sta     temp_01
ppu_buffer_write_entry:  lda     ppu_update_buf + $08,y
        sta     PPUADDR
        lda     ppu_update_buf + $0C,y
        sta     PPUADDR
        lda     ppu_update_buf + $50,y
        sta     PPUDATA
ppu_buffer_write_row:  lda     temp_0B
        sta     PPUADDR
        clc
        lda     temp_0A
        sta     PPUADDR
        adc     #$20
        sta     temp_0A
        ldy     #$04
ppu_buffer_write_bytes:  lda     ppu_update_buf + $10,x
        sta     PPUDATA
        inx
        dey
        bne     ppu_buffer_write_bytes
        dec     temp_01
        bne     ppu_buffer_write_row
        ldy     temp_00
        iny
        dec     ppu_buffer_count
        bne     ppu_buffer_entry_loop
        rts

ppu_buffer_transfer_alt:  ldx     #$00
        stx     ppu_buffer_count
ppu_buffer_alt_row:  lda     ppu_update_buf
        sta     PPUADDR
        lda     ppu_update_buf + $01
        sta     PPUADDR
ppu_buffer_alt_byte:  lda     ppu_update_buf + $02,x
        sta     PPUDATA
        inx
        txa
        and     #$07
        bne     ppu_buffer_alt_byte
        clc
        lda     ppu_update_buf + $01
        adc     #$20
        sta     ppu_update_buf + $01
        lda     ppu_update_buf + $12
        sta     PPUADDR
        lda     ppu_update_buf + $13
        sta     PPUADDR
        lda     PPUDATA
        lda     PPUDATA
        ldy     ppu_buffer_count
        and     ppu_update_buf + $14
        ora     ppu_update_buf + $15,y
        pha
        lda     ppu_update_buf + $12
        sta     PPUADDR
        lda     ppu_update_buf + $13
        sta     PPUADDR
        pla
        sta     PPUDATA
        inc     ppu_buffer_count
        inc     ppu_update_buf + $13
        cpx     #$10
        bne     ppu_buffer_alt_row
        lda     #$00
        sta     ppu_buffer_count
        rts

; -----------------------------------------------------------------------------
; ppu_scroll_column_update — Write one tile column to nametable VRAM.
; PPUCTRL increment mode must be +32 (vertical) so each PPUDATA write
; advances one row. col_update_addr = target VRAM address ($2000+),
; col_update_tiles = tile buffer, $47 = number of tiles to write.
; Called from NMI when col_update_count ($47) is nonzero.
; -----------------------------------------------------------------------------
ppu_scroll_column_update:  lda     col_update_addr_hi ; set PPU write address (high byte)
        sta     PPUADDR
        lda     col_update_addr_lo      ; set PPU write address (low byte)
        sta     PPUADDR
        ldx     #$00
ppu_col_write_loop:  lda     col_update_tiles,x ; write one tile from buffer
        sta     PPUDATA                 ; PPUDATA auto-increments by 32 (vertical)
        inx
        dec     col_update_count                     ; decrement col_update_count
        bne     ppu_col_write_loop
        rts

; -----------------------------------------------------------------------------
; ppu_attribute_update — Write attribute table entries during scroll.
; Sets PPUCTRL bit 2 (+32 increment) for attribute table writes, which
; span columns across rows. Three modes based on $54 (attr_update_mode):
;   $54 = 0:  Normal mode — write attribute bytes from buffer at $03B5+
;   $54 < 0:  Read-modify-write — read existing attr, merge with new data
;   $54 > 0:  Overwrite mode — write sequential values directly
; $51 bit 7 selects fill mode (bulk 2×2 metatile attribute region fill).
; Called from NMI when attr_update_count ($51) is nonzero.
; -----------------------------------------------------------------------------
ppu_attribute_update:  lda     ppuctrl_shadow
        ora     #$04                    ; set PPUCTRL bit 2: +32 increment mode
        sta     PPUCTRL
        lda     attr_update_mode                     ; check attr_update_mode
        bne     attr_update_special     ; nonzero = special write mode
        ldy     attr_update_count                     ; attr_update_count
        bmi     attr_update_fill_mode   ; bit 7 set = fill mode
attr_update_loop:  lda     attr_update_addr_hi,y   ; attribute addr high byte
        sta     PPUADDR
        lda     attr_update_addr_lo,y   ; attribute addr low byte
        sta     PPUADDR
        lda     attr_update_values,y    ; attribute value
        sta     PPUDATA                 ; write first byte
        clc
        adc     #$01
        sta     PPUDATA                 ; write adjacent byte (+32 = next row)
        dey
        bne     attr_update_loop
attr_update_done:  sty     attr_update_count             ; clear attr_update_count (Y=0)
        lda     ppuctrl_shadow
        and     #$FB                    ; restore normal +1 increment mode
        sta     PPUCTRL
        rts

; Fill mode (bit 7 of $51): fills 2×2 metatile attribute regions with
; sequential palette index values, used during room transition rendering.
attr_update_fill_mode:  tya
        and     #$7F                    ; strip fill mode bit to get count
        tay
attr_fill_outer:  lda     #$02
        sta     temp_00                 ; 2 passes (2 columns)
        lda     #$E4
        sta     temp_01                 ; starting attribute value
attr_fill_write_addr:  lda     attr_update_addr_hi,y   ; set PPU address for this attr entry
        sta     PPUADDR
        lda     attr_update_addr_lo,y
        sta     PPUADDR
        lda     #$02
        sta     temp_02                 ; 2 bytes per column (2 rows)
attr_fill_write_byte:  lda     temp_01
        sta     PPUDATA                 ; write attribute byte
        inc     temp_01                 ; next palette index
        dec     temp_02
        bne     attr_fill_write_byte
        dec     temp_00
        beq     attr_fill_next          ; both columns done
        clc
        lda     attr_update_addr_lo,y   ; advance to adjacent column (+1)
        adc     #$01
        sta     attr_update_addr_lo,y
        jmp     attr_fill_write_addr

attr_fill_next:  dey
        bne     attr_fill_outer
        beq     attr_update_done
; Special mode: read-modify-write to avoid clobbering adjacent metatile palettes.
; $54 < 0 (bit 7): read current attribute, merge new data with mask.
; $54 > 0: direct overwrite with sequential values starting at $20.
attr_update_special:  bpl     attr_special_default
        lda     col_update_addr_hi      ; read existing attribute value first
        sta     PPUADDR
        ldx     attr_update_addr_lo + 1
        dex
        dex
        stx     PPUADDR
        lda     PPUDATA                 ; dummy read (PPU read buffer)
        lda     PPUDATA                 ; actual read: current attribute byte
        tax                             ; X = existing value to merge with
        jmp     attr_special_setup

attr_special_default:  ldx     #$20    ; default fill value
attr_special_setup:  ldy     #$02    ; write 2 attribute entries
attr_special_write_loop:  lda     col_update_addr_hi
        sta     PPUADDR
        lda     attr_update_addr_lo + 1
        sta     PPUADDR
        stx     PPUDATA                 ; write attribute byte
        inx
        stx     PPUDATA                 ; write next sequential byte (+32 rows)
        inx
        inc     attr_update_addr_lo + 1 ; advance to next attribute column
        dey
        bne     attr_special_write_loop
        lda     attr_update_values + 1   ; second attribute region address
        sta     PPUADDR
        lda     col_update_tiles + $10
        sta     PPUADDR
; --- Attribute merge: combine new palette bits with existing byte ---
; col_update_tiles+$1C = mask (bits to keep from new data)
; Merge formula: result = (existing AND ~mask) | (new AND mask)
        lda     attr_update_mode
        bpl     attr_special_read_current
        lda     PPUDATA                 ; dummy read (PPU latency)
        lda     PPUDATA                 ; read existing attribute byte
        sta     temp_00
        lda     col_update_tiles + $1C  ; mask for bits to preserve
        eor     #$FF                    ; invert: bits to keep from existing
        lsr     a                       ; shift mask to align with attr bit pairs
        lsr     a
        and     temp_00                 ; keep existing bits outside mask
        asl     a
        asl     a
        sta     col_update_tiles + $16  ; save preserved bits
        lda     temp_00
        jmp     attr_special_merge

attr_special_read_current:
        lda     PPUDATA                 ; dummy read
        lda     PPUDATA                 ; existing attribute byte
attr_special_merge:
        and     col_update_tiles + $1C  ; apply mask to select new palette bits
        ora     col_update_tiles + $16  ; merge with preserved existing bits
        tax
        lda     attr_update_values + 1  ; write merged result to PPU
        sta     PPUADDR
        lda     col_update_tiles + $10
        sta     PPUADDR
        stx     PPUDATA
        sty     attr_update_mode        ; clear mode flag (Y=0)
        jmp     attr_update_done

; ─── Copy weapon palette to sprite palette ───
weapon_palette_copy:
        lda     current_weapon
weapon_palette_copy_indexed:
        asl     a
        asl     a
        tax
        inx
        ldy     #$01
weapon_palette_copy_loop:  lda     weapon_palette_data,x
        sta     palette_sprite,y
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
; player_damage_knockback — Player damage recoil — i-frames, knockback, sound ($D332)
; =============================================================================
player_damage_knockback:
        lda     #$26                    ; sound: damage recoil
        jsr     sound_queue_push
        lda     #$00
        sta     weapon_fire_dir
        sta     general_timer
        lda     #$02
        sta     game_substate           ; player state = weapon active
        jsr     player_set_sprite
        lda     #$01
        sta     ent_anim_id
        lda     #$6F
        sta     invincibility_timer     ; i-frames on knockback
        lda     #$01                    ; knockback velocity: Y = $01.40
        sta     ent_y_vel
        lda     #$40
        sta     ent_y_vel_sub
        lda     #$00                    ; X velocity = $00.90
        sta     ent_x_vel
        lda     #$90
        sta     ent_x_vel_sub
        lsr     ent_flags + $0F         ; clear sprint flag (bit 7)
        lda     #$00
        sta     game_mode
; --- Scan slots $0E down to $02 for free slot to spawn damage spark ---
        ldx     #$0E
knockback_find_slot_loop:
        lda     ent_flags,x
        bpl     knockback_spawn_spark   ; bit 7 clear = slot available
        dex
        cpx     #$01
        bne     knockback_find_slot_loop
        rts                             ; no free slot

knockback_spawn_spark:  lda     #$80    ; active flag
        sta     ent_flags,x                 ; activate projectile entity
        lda     #ENTITY_CHANGKEY_PROJ   ; buster/changkey projectile entity type
        sta     ent_type,x
        lda     ent_x_screen
        sta     ent_x_screen,x
        lda     ent_x_px
        sta     ent_x_px,x
        lda     ent_y_px
        sta     ent_y_px,x
        lda     #$08
        sta     ent_y_vel_sub,x
        lda     #$00
        sta     ent_y_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
        sta     ent_anim_frame,x
        sta     ent_anim_id,x
        rts

; =============================================================================
; player_set_sprite — Set player's base sprite type from player state ($D3A8)
; =============================================================================
; game_substate = player state (0-$0B); the table gives Mega Man's base
; sprite/animation type for that state. weapon_fire_dir offsets it while
; firing (gun-out variants).
player_set_sprite:  ldx     game_substate      ; player state index
        clc
        lda     player_state_sprite_tbl,x  ; base sprite type for state
        adc     weapon_fire_dir
        cmp     ent_type
        beq     weapon_store_type
        ldx     #$00
        stx     ent_anim_id
        stx     ent_anim_frame
weapon_store_type:  sta     ent_type
        lda     general_timer
        beq     weapon_reset_direction
        dec     general_timer
        rts

weapon_reset_direction:  lda     #$00
        sta     weapon_fire_dir
        ldx     game_substate
        lda     player_state_sprite_tbl,x
        sta     ent_type
        rts

player_state_sprite_tbl:  .byte   $1A,$19,$18,$00,$04,$08,$0C,$10 ; player base sprite per state
        .byte   $14,$1B,$1F,$26

; =============================================================================
; weapon_spawn_projectile — Configure projectile entity from table data ($D3E0)
; =============================================================================
; Input: X = projectile slot, Y = projectile table index
; Sets entity type, position (with directional X offset), velocity,
; damage type, and clears animation/state fields.
; =============================================================================
weapon_spawn_projectile:
        lda     projectile_type_tbl,y
        sta     ent_type,x
        lda     ent_flags               ; get player facing direction (bit 6)
        and     #$40
        php                             ; save direction for offset branching
        ora     projectile_flags_tbl,y
        sta     ent_flags,x
; --- Position: apply X offset based on player facing direction ---
        plp
        bne     weapon_spawn_facing_right
        sec                             ; facing left: subtract X offset
        lda     ent_x_px
        sbc     projectile_x_offset_tbl,y
        sta     ent_x_px,x
        lda     ent_x_screen
        sbc     #$00                    ; propagate borrow to screen byte
        sta     ent_x_screen,x
        jmp     weapon_spawn_set_y

weapon_spawn_facing_right:
        clc                             ; facing right: add X offset
        lda     ent_x_px
        adc     projectile_x_offset_tbl,y
        sta     ent_x_px,x
        lda     ent_x_screen
        adc     #$00                    ; propagate carry to screen byte
        sta     ent_x_screen,x
weapon_spawn_set_y:
        lda     ent_y_px
        sta     ent_y_px,x
        lda     projectile_xvel_sub_tbl,y
        sta     ent_x_vel_sub,x
        lda     projectile_xvel_tbl,y
        sta     ent_x_vel,x
        lda     projectile_yvel_sub_tbl,y
        sta     ent_y_vel_sub,x
        lda     projectile_yvel_tbl,y
        sta     ent_y_vel,x
        lda     projectile_damage_type_tbl,y
        sta     ent_weapon_type,x
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        sta     ent_state,x
        sta     ent_hp,x
        rts

projectile_type_tbl:  .byte   $23,$30,$31,$32,$33,$34,$35,$36 ; entity type for each projectile
        .byte   $37,$38,$39,$3A,$2F,$3E,$3F,$74
        .byte   $79,$7C
projectile_flags_tbl:  .byte   $81,$83,$83,$82,$87,$83,$83,$81 ; entity flags for each projectile
        .byte   $82,$82,$82,$86,$81,$82,$80,$80
        .byte   $80,$80
projectile_x_offset_tbl:  .byte   $10,$00
        .byte   $10,$00
        .byte   $10,$10
        .byte   $10,$00
        .byte   $00
        .byte   $20,$20,$00,$00,$00,$00,$00,$00
        .byte   $00
projectile_xvel_sub_tbl:  .byte   $00,$00,$00,$00
        .byte   $00,$71,$00,$00,$0F,$00,$00,$27
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
        .byte   $1E
        .byte   $18
        .byte   $28
        .byte   $30
        .byte   $14
        .byte   $24
        .byte   $0C
        .byte   $10
        .byte   $18
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
        .byte   $08
        .byte   $0C,$24,$0C,$1A,$14,$24,$2C,$10
        .byte   $20,$08
        .byte   $0C,$14,$0C,$1C
        .byte   $34,$14,$14,$04,$04,$04,$04,$04
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
        .byte   $18,$14,$10,$10,$14,$2C
        .byte   $14,$22
        .byte   $1C,$2C,$34,$18,$28,$10
        .byte   $14,$1C,$14,$24
        .byte   $3C,$1C,$1C,$0C,$0C,$0C,$0C,$0C
        .byte   $0C,$0C,$0C,$0C,$0C,$20,$1C,$18
        .byte   $14,$14,$18,$30,$18,$26,$20,$30
        .byte   $38,$1C,$2C,$14,$18,$20,$18,$28
        .byte   $40,$20,$20,$10,$10,$10,$10,$10
        .byte   $10,$10,$10,$10,$10
ending_player_render:
        ldy     ent_type
ending_player_anim:
        sty     temp_01
        lda     #$09
        jsr     bank_switch
        jsr     banked_09_draw_sprites
; ─── Switch to bank $0D and return ───
switch_to_bank_0D:  lda     #$0D
        jsr     bank_switch
        rts

; ─── Ending cutscene trampolines: switch to bank $09, call entry, return via $0D ───
ending_scroll_update:
        lda     #$09
        jsr     bank_switch
        jsr     banked_09_col_tick      ; bank $09 ending entry ($8603)
        jmp     switch_to_bank_0D

ending_init_walk:
        lda     #$09
        jsr     bank_switch
        jsr     banked_09_walk_init     ; bank $09 ending entry ($8606)
        jmp     switch_to_bank_0D

ending_walk_step:
        lda     #$09
        jsr     bank_switch
        jsr     banked_09_walk_scroll   ; bank $09 ending entry ($8609)
        jmp     switch_to_bank_0D

; =============================================================================
; entity_spawn_scan — Scan stage data and spawn/despawn entities based on scroll ($D658)
; =============================================================================
entity_spawn_scan:  lda     current_stage
        and     #$07                    ; mask to stage bank index 0-7
        jsr     bank_switch             ; switch to current stage bank
        clc
        lda     scroll_x
        sta     temp_0A
        adc     #$FF
        sta     jump_ptr
        lda     nametable_select
        sta     temp_0B
        adc     #$00
        sta     jump_ptr_hi
        lda     scroll_dir_flags
        and     #$40
        bne     spawn_scan_right_scroll
spawn_scan_backward:  ldy     spawn_scan_bwd
        beq     spawn_scan_forward
        lda     $B5FF,y
        cmp     temp_0B
        bcc     spawn_scan_forward
        bne     spawn_backward_despawn
        lda     $B6FF,y
        cmp     temp_0A
        bcc     spawn_scan_forward
spawn_backward_despawn:  dey
        jsr     activate_primary_entity
        dec     spawn_scan_bwd
        bne     spawn_scan_backward
spawn_scan_forward:  ldy     spawn_scan_fwd
        beq     spawn_forward_done
spawn_forward_check:  lda     $B5FF,y
        cmp     jump_ptr_hi
        bcc     spawn_forward_done
        bne     spawn_forward_skip
        lda     $B6FF,y
        cmp     jump_ptr
        bcc     spawn_forward_done
spawn_forward_skip:  dey
        bne     spawn_forward_check
spawn_forward_done:  sty     spawn_scan_fwd
spawn_secondary_backward:  ldy     spawn_scan_sec_bwd
        beq     spawn_secondary_forward
        lda     $B9FF,y
        cmp     temp_0B
        bcc     spawn_secondary_forward
        bne     spawn_sec_check_active
        lda     $BA3F,y
        cmp     temp_0A
        bcc     spawn_secondary_forward
spawn_sec_check_active:  lda     ent_parent_ref + $0F,y
        beq     spawn_sec_backward_next
        dey
        jsr     activate_secondary_entity
spawn_sec_backward_next:  dec     spawn_scan_sec_bwd
        bne     spawn_secondary_backward
spawn_secondary_forward:  ldy     spawn_scan_sec_fwd
        beq     spawn_sec_forward_done
spawn_sec_forward_check:  lda     $B9FF,y
        cmp     jump_ptr_hi
        bcc     spawn_sec_forward_done
        bne     spawn_sec_forward_skip
        lda     $BA3F,y
        cmp     jump_ptr
        bcc     spawn_sec_forward_done
spawn_sec_forward_skip:  dey
        bne     spawn_sec_forward_check
spawn_sec_forward_done:  sty     spawn_scan_sec_fwd
        jmp     spawn_scan_done

spawn_scan_right_scroll:  ldy     spawn_scan_fwd
        lda     jump_ptr_hi
        cmp     $B600,y
        bcc     spawn_right_backward
        bne     spawn_right_activate
        lda     jump_ptr
        cmp     $B700,y
        bcc     spawn_right_backward
spawn_right_activate:  jsr     activate_primary_entity
        inc     spawn_scan_fwd
        bne     spawn_scan_right_scroll
spawn_right_backward:  ldy     spawn_scan_bwd
spawn_right_back_check:  lda     temp_0B
        cmp     $B600,y
        bcc     spawn_right_back_done
        bne     spawn_right_back_skip
        lda     temp_0A
        cmp     $B700,y
        bcc     spawn_right_back_done
spawn_right_back_skip:  iny
        bne     spawn_right_back_check
spawn_right_back_done:  sty     spawn_scan_bwd
spawn_right_sec_forward:  ldy     spawn_scan_sec_fwd
        lda     jump_ptr_hi
        cmp     $BA00,y
        bcc     spawn_right_sec_backward
        bne     spawn_right_sec_check
        lda     jump_ptr
        cmp     $BA40,y
        bcc     spawn_right_sec_backward
spawn_right_sec_check:  lda     ent_child_hp,y
        beq     spawn_right_sec_next
        jsr     activate_secondary_entity
spawn_right_sec_next:  inc     spawn_scan_sec_fwd
        bne     spawn_right_sec_forward
spawn_right_sec_backward:  ldy     spawn_scan_sec_bwd
spawn_right_sec_back_chk:  lda     temp_0B
        cmp     $BA00,y
        bcc     spawn_right_sec_back_done
        bne     spawn_right_sec_back_skip
        lda     temp_0A
        cmp     $BA40,y
        bcc     spawn_right_sec_back_done
spawn_right_sec_back_skip:  iny
        bne     spawn_right_sec_back_chk
spawn_right_sec_back_done:  sty     spawn_scan_sec_bwd
spawn_scan_done:  lda     #$0E          ; switch back to game engine
        jsr     bank_switch
        rts

; =============================================================================
; activate_primary_entity — Activate an enemy entity from stage spawn data ($D753)
; =============================================================================
activate_primary_entity:  tya
        ldx     #$0F
activate_check_dup:  cmp     ent_hit_count,x    ; check for duplicate spawn
        beq     entity_activate_done
        dex
        bpl     activate_check_dup
        jsr     find_empty_entity_slot
        bcs     entity_activate_done
        tya
        sta     ent_hit_count,x
        lda     $B600,y
        sta     ent_x_spawn_scr,x
        lda     $B700,y
        sta     ent_x_spawn_px,x
        lda     $B800,y
        sta     ent_y_spawn_px,x
        lda     $B900,y
; =============================================================================
; entity_init_from_type — Initialize entity arrays from type ID ($D77C)
; =============================================================================
; Input: A = entity type ID ($00-$7F), X = entity slot
; Populates flags, AI behavior, timer, hitbox dimensions from lookup tables.
; Uses two-stage table lookup for hitboxes: type → index → lo/hi values.
; =============================================================================
entity_init_from_type:
        sta     ent_spawn_type,x        ; store entity type ID
        tay
        pha                             ; save type (need it again for height)
        lda     entity_flags_table,y    ; default entity flags per type
        sta     ent_spawn_flags,x
        lda     entity_ai_behavior_tbl,y ; AI behavior index per type
        sta     ent_ai_behavior,x
        lda     #$14                    ; default timer = 20 frames
        sta     ent_timer,x
; --- Hitbox width: type → width_idx → lo/hi tables ---
        lda     entity_hitbox_width_idx_tbl,y
        tay
        lda     hitbox_width_lo_tbl,y
        sta     ent_hitbox_w_lo,x
        lda     hitbox_width_hi_tbl,y
        sta     ent_hitbox_w_hi,x
; --- Hitbox height: type → height_idx → lo/hi tables ---
        pla                             ; restore type ID
        tay
        lda     entity_hitbox_height_idx_tbl,y
        tay
        lda     hitbox_height_lo_tbl,y
        sta     ent_hitbox_h_lo,x
        lda     hitbox_height_hi_tbl,y
        sta     ent_hitbox_h_hi,x
; --- Zero out transient fields ---
        lda     #$00
        sta     ent_misc,x
        sta     ent_anim_backup,x
        sta     ent_drop_flag,x
        sta     ent_despawn,x
        sta     ent_x_spawn_sub,x
        sta     ent_y_spawn_sub,x
        sta     ent_parent_slot,x
entity_activate_done:  rts

; =============================================================================
; activate_secondary_entity — Activate a secondary entity from spawn data ($D7CC)
; =============================================================================
activate_secondary_entity:  tya
        ldx     #$0F
activate_sec_check_dup:  cmp     ent_parent_ref,x
        beq     entity_activate_done
        dex
        bpl     activate_sec_check_dup
        jsr     find_empty_entity_slot
        bcs     entity_activate_done
        tya
        pha
        sta     ent_parent_ref,x
        lda     $BA00,y
        sta     ent_x_spawn_scr,x
        lda     $BA40,y
        sta     ent_x_spawn_px,x
        lda     $BA80,y
        sta     ent_y_spawn_px,x
        lda     $BAC0,y
        jsr     entity_init_from_type
        pla
        sta     ent_despawn,x
        tay
        lda     ent_child_hp,y
        sta     ent_timer,x
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
        .byte   $02,$20,$02,$02,$02,$14,$16,$02
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
; ─── Find an unused entity slot ───
find_empty_entity_slot:  ldx     #$0F
find_slot_loop:  lda     ent_spawn_flags,x
        bpl     find_slot_found
        dex
        bpl     find_slot_loop
        sec
        rts

find_slot_found:  clc
        rts

fire_weapon_dispatch:
        lda     player_y_screen
        bne     @no_fire
        ldx     current_weapon
        beq     @dispatch               ; buster: no ammo check
        lda     weapon_ammo - 1,x       ; ammo for current weapon (1-indexed)
        beq     @no_fire                ; empty → can't fire
@dispatch:
        lda     weapon_dispatch_lo_tbl,x
        sta     jump_ptr
        lda     weapon_dispatch_hi_tbl,x
        sta     jump_ptr_hi
        jmp     (jump_ptr)

@no_fire:
        sec
        rts

; ─── Mega Buster fire handler (weapon 0) ───
fire_weapon_buster:  lda     p1_new_presses
        and     #$02
        beq     fire_weapon_no_slot
        ldx     #$04
fire_weapon_scan_slot:  lda     ent_flags,x
        bpl     fire_weapon_found_slot
        dex
        cpx     #$01
        bne     fire_weapon_scan_slot
        beq     fire_weapon_no_slot
fire_weapon_found_slot:  lda     #$24
        jsr     sound_queue_push
        ldy     #$00
        jsr     weapon_spawn_projectile
fire_weapon_set_timer:  lda     #$0F
        sta     general_timer
        lda     #$01
fire_weapon_set_dir:  sta     weapon_fire_dir
        ldx     game_substate
        clc
        adc     player_state_sprite_tbl,x
        sta     ent_type
        clc
        rts

fire_weapon_no_slot:  sec
        rts

; ─── Atomic Fire fire handler (weapon 1) — spawn charge entity in slot 2 ───
fire_weapon_atomic:  lda     p1_new_presses
        and     #$02
        beq     @no_fire
        ldx     #$02
        ldy     #$01
        jsr     weapon_spawn_projectile
        lda     #$82
        sta     ent_flags,x
@no_fire:
        sec
        rts

; ─── Air Shooter fire handler (weapon 2) — 3 tornadoes, slots 2-4 ───
fire_weapon_air:  lda     p1_new_presses
        and     #$02
        beq     fire_weapon_multi_fail
        ldx     #$04
fire_weapon_multi_scan:  lda     ent_flags,x
        bmi     fire_weapon_multi_fail
        dex
        cpx     #$01
        bne     fire_weapon_multi_scan
        ldx     #$04
fire_weapon_multi_loop:  stx     temp_01
        ldy     #$02
        jsr     weapon_spawn_projectile
        ldx     temp_01
        dex
        cpx     #$01
        bne     fire_weapon_multi_loop
        lda     #$3F
        jsr     sound_queue_push
        sec
        lda     weapon_ammo + 1
        sbc     #$02
        sta     weapon_ammo + 1
        jmp     fire_weapon_set_timer

fire_weapon_multi_fail:  sec
        rts

; ─── Leaf Shield fire handler (weapon 3) — 4 leaves, slots 2-5, cost 3 ───
fire_weapon_leaf:  lda     p1_new_presses
        and     #$02
        beq     fire_weapon_spread_done
        lda     ent_flags + $02
        bmi     fire_weapon_spread_done
        sec
        lda     weapon_ammo + 2
        sbc     #$03
        bcc     fire_weapon_spread_done
        ldx     #$05
fire_weapon_spread_loop:  stx     temp_02
        ldy     #$03
        jsr     weapon_spawn_projectile
        ldx     temp_02
        dex
        cpx     #$01
        bne     fire_weapon_spread_loop
fire_weapon_spread_done:
        sec
        rts

; ─── Bubble Lead fire handler (weapon 4) — 2 max, half-unit cost ───
fire_weapon_bubble:  lda     p1_new_presses
        and     #$02
        beq     fire_weapon_bubble_fail
        ldx     #$03
fire_weapon_bubble_scan:  lda     ent_flags,x
        bpl     fire_weapon_bubble_fire
        dex
        cpx     #$01
        bne     fire_weapon_bubble_scan
        beq     fire_weapon_bubble_fail
fire_weapon_bubble_fire:  ldy     #$04
        jsr     weapon_spawn_projectile
        lda     #$24
        jsr     sound_queue_push
        inc     weapon_counter_2
        lda     weapon_counter_2
        cmp     #$02
        bne     fire_weapon_bubble_done
        lda     #$00
        sta     weapon_counter_2
        dec     weapon_ammo + 3
fire_weapon_bubble_done:  jmp     fire_weapon_set_timer

fire_weapon_bubble_fail:  sec
        rts

; ─── Quick Boomerang fire handler (weapon 5) — 8 shots per unit ───
fire_weapon_quick:  lda     p1_new_presses
        and     #$02
        bne     @skip
        lda     weapon_counter_1
        cmp     #$0B
        beq     @skip
        inc     weapon_counter_1
        clc
        rts
@skip:
        ldx     #$05
fire_weapon_quick_scan:  lda     ent_flags,x
        bpl     fire_weapon_quick_fire
        dex
        cpx     #$01
        bne     fire_weapon_quick_scan
        beq     fire_weapon_quick_fail
fire_weapon_quick_fire:  ldy     #$05
        jsr     weapon_spawn_projectile
        lda     #$24
        jsr     sound_queue_push
        inc     weapon_counter_2
        lda     weapon_counter_2
        cmp     #$08
        bne     fire_weapon_quick_reset
        lda     #$00
        sta     weapon_counter_2
        dec     weapon_energy
fire_weapon_quick_reset:  lda     #$00
        sta     weapon_counter_1
        jmp     fire_weapon_set_timer

fire_weapon_quick_fail:  sec
        rts

; ─── Crash Bomber fire handler (weapon 8) — 1 bomb, cost 4 ───
fire_weapon_crash:  lda     p1_new_presses
        and     #$02
        beq     @no_fire
        lda     ent_flags + $02
        bmi     @no_fire
        sec
        lda     weapon_energy + 3       ; Crash Bomber energy
        sbc     #$04
        bcc     @no_fire
        sta     weapon_energy + 3
        ldx     #$02
        ldy     #$06
        jsr     weapon_spawn_projectile
        lda     #$24
        jsr     sound_queue_push
        jmp     fire_weapon_set_timer
@no_fire:
        sec
        rts

; ─── Metal Blade fire handler (weapon 7) — 8-way aim, 4 shots per unit ───
fire_weapon_metal:  lda     p1_new_presses
        and     #$02
        beq     fire_weapon_metal_fail
        ldx     #$04
fire_weapon_metal_scan:  lda     ent_flags,x
        bpl     fire_weapon_metal_fire
        dex
        cpx     #$01
        bne     fire_weapon_metal_scan
        beq     fire_weapon_metal_fail
fire_weapon_metal_fire:  ldy     #$07
        jsr     weapon_spawn_projectile
        lda     #$23
        jsr     sound_queue_push
        inc     weapon_counter_2
        lda     weapon_counter_2
        cmp     #$04
        bne     fire_weapon_metal_aim
        lda     #$00
        sta     weapon_counter_2
        dec     weapon_energy + 2
fire_weapon_metal_aim:  lda     controller_1
        and     #$F0
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     metal_blade_yvel_sub_tbl,y
        sta     ent_y_vel_sub,x
        lda     metal_blade_yvel_tbl,y
        sta     ent_y_vel,x
        lda     metal_blade_xvel_sub_tbl,y
        sta     ent_x_vel_sub,x
        lda     metal_blade_xvel_tbl,y
        sta     ent_x_vel,x
        jmp     fire_weapon_finish

fire_weapon_metal_fail:  sec
        rts

metal_blade_yvel_sub_tbl:  .byte   $00,$00,$00,$00,$00,$D4,$2C,$00
        .byte   $00,$D4,$2C,$00,$00,$00,$00,$00
metal_blade_yvel_tbl:  .byte   $00,$04,$FC,$00,$00,$02,$FD,$00
        .byte   $00,$02,$FD,$00,$00,$00,$00,$00
metal_blade_xvel_sub_tbl:  .byte   $00,$00,$00,$00,$00,$D4,$D4,$00
        .byte   $00,$D4,$D4,$00,$00,$00,$00,$00
metal_blade_xvel_tbl:  .byte   $04,$00,$00,$00,$04,$02,$02,$00
        .byte   $04,$02,$02,$00,$00,$00,$00,$00

; ─── Time Stopper fire handler (weapon 6) — activate freeze ───
fire_weapon_time_stopper:  lda     p1_new_presses
        and     #$02
        beq     fire_weapon_time_done
        ldx     #$02
        lda     ent_flags + $02
        bmi     fire_weapon_time_done
        ldy     #$08
        jsr     weapon_spawn_projectile
        lda     #$01
        sta     boss_spawn_timer
        lda     #$21
        jsr     sound_queue_push
fire_weapon_finish:  lda     #$0F
        sta     general_timer
        lda     #$03
        jmp     fire_weapon_set_dir

fire_weapon_time_done:
        sec
        rts

; ─── Item 1 fire handler (weapon 9) — rising platform, cost 2 ───
fire_weapon_item1:  lda     p1_new_presses
        and     #$02
        beq     fire_weapon_time_done
        ldx     #$04
fire_weapon_item1_scan:  lda     ent_flags,x
        bpl     fire_weapon_item1_fire
        dex
        cpx     #$01
        bne     fire_weapon_item1_scan
        beq     fire_weapon_item1_fail
fire_weapon_item1_fire:  ldy     #$09
        jsr     weapon_spawn_projectile
        sec
        lda     weapon_energy + 4
        sbc     #$02
        sta     weapon_energy + 4
        jmp     fire_weapon_finish

fire_weapon_item1_fail:  sec
        rts

; ─── Item 2 fire handler (weapon 10) — jet sled ───
fire_weapon_item2:  lda     p1_new_presses
        and     #$02
        beq     @done
        lda     ent_flags + $02
        bmi     @done
        ldx     #$02
        ldy     #$0A
        jsr     weapon_spawn_projectile
        lda     #$3E
        sta     ent_state + $02
        lda     #$13
        sta     ent_hp + $02
        jmp     fire_weapon_finish
@done:
        rts

; ─── Item 3 fire handler (weapon 11) — wall climber ───
fire_weapon_item3:  lda     p1_new_presses
        and     #$02
        beq     @done_2
        lda     ent_flags + $02
        bmi     @done_2
        ldx     #$02
        ldy     #$0B
        jsr     weapon_spawn_projectile
        lda     #$1F
        sta     ent_hp + $02
        jmp     fire_weapon_finish
@done_2:
        rts
; Fire handler per weapon ID (P,H,A,W,B,Q,F,M,C,Item1,Item2,Item3)
weapon_dispatch_lo_tbl:
        .byte   <fire_weapon_buster,<fire_weapon_atomic,<fire_weapon_air
        .byte   <fire_weapon_leaf,<fire_weapon_bubble,<fire_weapon_quick
        .byte   <fire_weapon_time_stopper,<fire_weapon_metal,<fire_weapon_crash
        .byte   <fire_weapon_item1,<fire_weapon_item2,<fire_weapon_item3
weapon_dispatch_hi_tbl:
        .byte   >fire_weapon_buster,>fire_weapon_atomic,>fire_weapon_air
        .byte   >fire_weapon_leaf,>fire_weapon_bubble,>fire_weapon_quick
        .byte   >fire_weapon_time_stopper,>fire_weapon_metal,>fire_weapon_crash
        .byte   >fire_weapon_item1,>fire_weapon_item2,>fire_weapon_item3

; =============================================================================
; update_entity_positions — Update screen-relative positions for all active entities ($DCD0)
; =============================================================================
update_entity_positions:  ldx     #$0F  ; start at entity slot 15
update_entity_loop:  stx     current_entity_slot
        lda     ent_flags,x                 ; check if entity is active
        bpl     update_entity_next
        and     #$02
        bne     update_entity_special
        sec
        lda     ent_x_px,x
        sbc     scroll_x                     ; subtract scroll X for screen pos
        sta     ent_screen_x,x                 ; store screen-relative X
        jsr     entity_physics_core     ; apply velocity and gravity
update_entity_next:  ldx     current_entity_slot
        dex
        cpx     #$01
        bne     update_entity_loop
        rts

update_entity_special:  lda     #$DC    ; push $DCE8: handler's RTS returns to
        pha                             ;   update_entity_next ($DCE9)
        lda     #$E8
        pha
        sec
        lda     ent_x_px,x
        sbc     scroll_x
        sta     ent_screen_x,x
        sec
        lda     ent_type,x
        sbc     #$2F
        tay
        lda     entity_special_dispatch_lo,y
        sta     jump_ptr
        lda     entity_special_dispatch_hi,y
        sta     jump_ptr_hi
        jmp     (jump_ptr)

; Handlers for weapon-slot entity types $2F-$3E (index = type - $2F).
; $36 (Metal Blade) also points at time_stopper_ai but is never dispatched
; (its flags bit 1 is clear — plain physics). $3B-$3D entries are unused.
entity_special_dispatch_lo:
        .byte   <atomic_fire_ai,<atomic_fire_ai,<air_shooter_ai,<leaf_shield_orbit_ai
        .byte   <bubble_lead_ai,<quick_boomerang_ai,<crash_bomber_ai,<time_stopper_ai
        .byte   <time_stopper_ai,<item1_platform_ai,<item2_jet_ai,<item3_climber_ai
        .byte   <type3B_bounce_ai,<offscreen_check_ai,<offscreen_check_ai,<special_ai_rts
entity_special_dispatch_hi:
        .byte   >atomic_fire_ai,>atomic_fire_ai,>air_shooter_ai,>leaf_shield_orbit_ai
        .byte   >bubble_lead_ai,>quick_boomerang_ai,>crash_bomber_ai,>time_stopper_ai
        .byte   >time_stopper_ai,>item1_platform_ai,>item2_jet_ai,>item3_climber_ai
        .byte   >type3B_bounce_ai,>offscreen_check_ai,>offscreen_check_ai,>special_ai_rts

; ─── Atomic Fire special AI (types $2F/$30) ───
; State 0: charge-up held at the player (palette flash, charge counter);
; state 1+: fired projectile animation + physics.
atomic_fire_ai:  lda     ent_state,x
        beq     @skip
        jmp     atomic_fire_state_check
@skip:
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        lda     weapon_counter_2
        cmp     #$FF
        beq     atomic_fire_check_threshold
        inc     weapon_counter_2
atomic_fire_check_threshold:  ldy     #$02
        lda     weapon_counter_2
        cmp     #$7D
        bcc     atomic_fire_set_anim
        iny
        iny
        cmp     #$BB
        bcc     atomic_fire_set_anim
        iny
        iny
atomic_fire_set_anim:  sty     temp_00
        lda     frame_counter
        and     #$04
        bne     atomic_fire_animate
        ldy     #$00
atomic_fire_animate:  jsr     atomic_fire_update_palette
        lda     ent_y_px
        sta     ent_y_px,x
        lda     ent_x_px
        sta     ent_x_px,x
        lda     ent_x_screen
        sta     ent_x_screen,x
        lda     temp_00
        lsr     a
        tay
        lda     atomic_fire_cost_tbl,y
        cmp     weapon_ammo
        bcc     atomic_fire_check_release
        beq     atomic_fire_check_release
        ldy     #$00
        sty     weapon_counter_2
        jsr     atomic_fire_update_palette
        lsr     ent_flags,x
        rts

atomic_fire_check_release:  lda     controller_1
        and     #$02
        beq     atomic_fire_reset_counter
        rts

atomic_fire_reset_counter:  ldy     #$00
        sty     weapon_counter_2
        jsr     atomic_fire_update_palette
        lsr     ent_flags + $02
        ldx     #$04
atomic_fire_find_slot:  lda     ent_flags,x
        bpl     atomic_fire_spawn_projectile
        dex
        cpx     #$02
        bne     atomic_fire_find_slot
atomic_fire_done:  rts

atomic_fire_spawn_projectile:  lda     player_y_screen
        bne     atomic_fire_deduct_ammo
        ldy     #$01
        jsr     weapon_spawn_projectile
        lda     temp_00
        lsr     a
        sta     ent_state,x
        sta     ent_weapon_type,x
        tay
        lda     atomic_fire_anim_frame_tbl,y
        sta     ent_anim_id,x
        sec
        lda     ent_x_px,x
        sbc     scroll_x
        sta     ent_screen_x,x
atomic_fire_deduct_ammo:  sec
        lda     weapon_ammo
        sbc     atomic_fire_cost_tbl,y
        sta     weapon_ammo
        lda     #$38
        jsr     sound_queue_push
        lda     #$04
        sta     ent_x_vel,x
        lda     game_substate
        beq     atomic_fire_done
        jmp     fire_weapon_set_timer

atomic_fire_state_check:  cmp     #$02
        bcs     atomic_fire_weapon_mid
        lda     ent_anim_id,x
        cmp     #$03
        bne     atomic_fire_apply_physics
        lda     #$01
        bne     atomic_fire_weapon_set_anim
atomic_fire_weapon_mid:  bne     atomic_fire_weapon_high
        lda     ent_anim_id,x
        cmp     #$06
        bne     atomic_fire_apply_physics
        lda     #$04
        bne     atomic_fire_weapon_set_anim
atomic_fire_weapon_high:  lda     ent_anim_id,x
        cmp     #$09
        bne     atomic_fire_apply_physics
        lda     #$07
atomic_fire_weapon_set_anim:  sta     ent_anim_id,x
atomic_fire_apply_physics:  jsr     entity_physics_core
        rts

atomic_fire_update_palette:  lda     atomic_fire_palette_lo_tbl,y
        sta     palette_sprite + $01
        lda     atomic_fire_palette_hi_tbl,y
        sta     palette_sprite + $03
        lda     frame_counter
        and     #$07
        bne     atomic_fire_palette_done
        lda     temp_00
        lsr     a
        tay
        lda     atomic_fire_sound_bank_tbl,y
        jsr     sound_queue_push
atomic_fire_palette_done:  rts

atomic_fire_sound_bank_tbl:  .byte   $35,$35,$36,$37
atomic_fire_palette_lo_tbl:  .byte   $0F
atomic_fire_palette_hi_tbl:  .byte   $15,$31,$15,$35,$2C,$30,$30
atomic_fire_anim_frame_tbl:  .byte   $00,$01,$04
atomic_fire_cost_tbl:  .byte   $07,$01,$06,$0A ; ammo cost per charge level

; ─── Air Shooter special AI (type $31) ───
; Slot index (2-4) selects one of three spread speeds; tornadoes drift
; upward with increasing speed (+$10 sub-velocity per frame).
air_shooter_ai:  txa
        sec
        sbc     #$02
        tay                             ; Y = slot - 2 (tornado index 0-2)
        lda     air_shooter_xvel_sub_tbl,y
        sta     ent_x_vel_sub,x
        lda     air_shooter_xvel_tbl,y
        sta     ent_x_vel,x
        clc
        lda     ent_y_vel_sub,x
        adc     #$10                    ; accelerate upward drift
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        adc     #$00
        sta     ent_y_vel,x
        jsr     entity_physics_core
        rts

air_shooter_xvel_sub_tbl:  .byte   $19,$99,$33 ; tornado X velocity (sub-pixel)
air_shooter_xvel_tbl:  .byte   $01,$01,$02 ; tornado X velocity (whole)

; ─── Leaf Shield special AI (type $32) ───
; State 0: the four leaves (slots 2-5) orbit the player at radius ent_hp,
; growing by 2 per frame; at radius $0C the shield forms around the player.
; State 1+: formed shield — leaf_shield_launch_ai.
leaf_shield_orbit_ai:  lda     ent_state,x
        bne     leaf_shield_launch_ai
        lda     #$00
        sta     ent_anim_frame,x
        lda     ent_hp,x                ; orbit radius
        sta     temp_01
        txa
        sec
        sbc     #$02
        sta     temp_00                 ; leaf index 0-3
        and     #$01
        bne     leaf_orbit_right
        sec                             ; even leaf: left of player
        lda     ent_x_px
        sbc     temp_01
        sta     ent_x_px,x
        lda     ent_x_screen
        sbc     #$00
        jmp     leaf_orbit_store_xscr

leaf_orbit_right:  clc                  ; odd leaf: right of player
        lda     ent_x_px
        adc     temp_01
        sta     ent_x_px,x
        lda     ent_x_screen
        adc     #$00
leaf_orbit_store_xscr:  sta     ent_x_screen,x
        lda     temp_00
        and     #$02
        bne     leaf_orbit_below
        sec                             ; leaves 0-1: above player
        lda     ent_y_px
        sbc     temp_01
        jmp     leaf_orbit_store_y

leaf_orbit_below:  clc                  ; leaves 2-3: below player
        lda     ent_y_px
        adc     temp_01
leaf_orbit_store_y:  sta     ent_y_px,x
        lda     temp_01
        cmp     #$0C                    ; full radius reached?
        beq     leaf_shield_form
        clc
        adc     #$02                    ; grow orbit radius
        sta     ent_hp,x
        rts

leaf_shield_form:  lsr     ent_flags + $03 ; despawn leaves in slots 3-5
        lsr     ent_flags + $04
        lsr     ent_flags + $05
        lda     #$83                    ; slot 2 becomes the formed shield
        sta     ent_flags + $02
        lda     #$01
        sta     ent_state + $02         ; state 1 = shield formed
        lda     #$01
        sta     ent_anim_id + $02
        rts

; ─── Leaf Shield formed-shield AI (type $32, state 1+) ───
; Shield tracks the player each frame; pressing a direction throws it
; (costs 3 more Leaf Shield ammo). Sound $31 loops while orbiting.
leaf_shield_launch_ai:  lda     player_y_screen
        beq     leaf_launch_check_anim
        lda     #$06
        bne     leaf_launch_set_anim
leaf_launch_check_anim:  lda     ent_anim_id,x
        cmp     #$05
        bcc     leaf_launch_check_state
        lda     #$01
leaf_launch_set_anim:  sta     ent_anim_id,x
leaf_launch_check_state:  lda     ent_state,x
        cmp     #$01
        bne     leaf_launch_physics     ; state 2 = thrown, plain physics
        lda     frame_counter
        and     #$07
        bne     leaf_launch_track_player
        lda     #$31                    ; sound: shield orbit loop
        jsr     sound_queue_push
leaf_launch_track_player:  lda     ent_x_px ; shield follows the player
        sta     ent_x_px,x
        lda     ent_x_screen
        sta     ent_x_screen,x
        lda     ent_y_px
        sta     ent_y_px,x
        lda     player_y_screen
        beq     leaf_launch_check_input
        lda     #$00
        sta     ent_y_px,x
leaf_launch_check_input:  lda     controller_1
        and     #$F0                    ; any direction pressed?
        beq     leaf_launch_done
        ldy     player_y_screen
        beq     leaf_launch_dir
        lsr     ent_flags,x
        rts

leaf_launch_dir:  and     #$C0          ; left/right pressed?
        beq     leaf_launch_up_down
        lsr     a
        and     #$40                    ; direction bit from d-pad
        ora     #$83
        sta     ent_flags,x
        lda     #$04
        sta     ent_x_vel,x
        bne     leaf_launch_deduct_ammo
leaf_launch_up_down:  ldy     #$00
        lda     controller_1
        and     #$10                    ; up pressed?
        bne     leaf_launch_set_yvel
        iny
leaf_launch_set_yvel:  lda     leaf_launch_yvel_tbl,y
        sta     ent_y_vel,x
leaf_launch_deduct_ammo:  sec
        lda     weapon_ammo + 2         ; Leaf Shield ammo: throw costs 3
        sbc     #$03
        sta     weapon_ammo + 2
        inc     ent_state,x             ; state 2 = thrown
leaf_launch_done:  rts

leaf_launch_physics:  jsr     entity_physics_core
        rts

leaf_launch_yvel_tbl:  .byte   $04,$FC ; thrown Y velocity: up/down

; ─── Bubble Lead special AI (type $33) ───
; Rolls along the floor (7x7 tile probe): launches over ledges, hugs
; walls, despawns when it hits a wall while grounded.
bubble_lead_ai:  lda     #$07
        sta     temp_01
        lda     #$07
        sta     temp_02
        jsr     check_horiz_tile_collision
        lda     ent_state,x
        bne     bubble_lead_launch_skip
        lda     temp_00
        beq     bubble_lead_physics
        inc     ent_state,x
        lda     ent_flags,x
        and     #$FB
        sta     ent_flags,x
bubble_lead_launch:  lda     #$C0
        sta     ent_y_vel_sub,x
        lda     #$FF
        sta     ent_y_vel,x
        lda     #$02
        sta     ent_x_vel,x
        bne     bubble_lead_physics
bubble_lead_launch_skip:
        cmp     #$01
        bne     bubble_lead_check_stop
        lda     temp_03
        beq     bubble_lead_check_wall
        lsr     ent_flags,x
        rts

bubble_lead_check_wall:  lda     temp_00
        bne     bubble_lead_physics
        lda     #$00
        sta     ent_x_vel,x
        sta     ent_y_vel_sub,x
        lda     #$FE
        sta     ent_y_vel,x
        inc     ent_state,x
        bne     bubble_lead_physics
bubble_lead_check_stop:  lda     temp_00
        beq     bubble_lead_physics
        dec     ent_state,x
        bne     bubble_lead_launch
bubble_lead_physics:  jsr     entity_physics_core
        rts

; ─── Quick Boomerang special AI (type $34) ───
; Flies out decelerating ($4B sub-velocity per frame); at state $12 it
; flips direction and accelerates back; despawns at state $23.
quick_boomerang_ai:  lda     ent_state,x
        cmp     #$12                    ; outbound phase?
        bcs     quick_boomerang_return
        sec                             ; decelerate outbound
        lda     ent_y_vel_sub,x
        sbc     #$4B
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        sbc     #$00
        sta     ent_y_vel,x
        jmp     quick_boomerang_step

quick_boomerang_return:  bne     quick_boomerang_check_despawn
        lda     ent_flags,x             ; state == $12: flip direction
        eor     #$40
        sta     ent_flags,x
quick_boomerang_check_despawn:  lda     ent_state,x
        cmp     #$23
        bne     quick_boomerang_accel
        lsr     ent_flags,x             ; boomerang expires
        rts

quick_boomerang_accel:  clc             ; accelerate return flight
        lda     ent_y_vel_sub,x
        adc     #$4B
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        adc     #$00
        sta     ent_y_vel,x
quick_boomerang_step:  inc     ent_state,x
        jsr     entity_physics_core
        rts

; ─── Crash Bomber special AI (type $35) ───
; Probes the tile ahead; on wall contact attaches (state 1, fuse $7E),
; then detonates into 4 scatter explosions (state 2).
crash_bomber_ai:  lda     ent_state,x
        bne     crash_bomber_hit_skip
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        sec
        lda     ent_y_px,x
        sbc     #$08
        sta     temp_0A
        lda     #$00
        sta     temp_0B
        lda     ent_flags,x
        and     #$40
        bne     @no_match
        sec
        lda     ent_x_px,x
        sbc     #$06
        sta     jump_ptr
        lda     ent_x_screen,x
        sbc     #$00
        jmp     @store_ptr_hi
@no_match:
        clc
        lda     ent_x_px,x
        adc     #$06
        sta     jump_ptr
        lda     ent_x_screen,x
        adc     #$00
@store_ptr_hi:  sta     jump_ptr_hi
        jsr     lookup_cached_tile
        ldy     temp_00
        ldx     current_entity_slot
        lda     tile_solid_flag_tbl,y
        bne     crash_bomber_hit
        clc
        lda     temp_0A
        adc     #$10
        sta     temp_0A
        jsr     lookup_cached_tile
        ldy     temp_00
        ldx     current_entity_slot
        lda     tile_solid_flag_tbl,y
        bne     crash_bomber_hit
        jsr     entity_physics_core
        rts

crash_bomber_hit:  lda     #$2E
        jsr     sound_queue_push
        lda     ent_flags,x
        and     #$FE
        sta     ent_flags,x
        inc     ent_anim_id,x
        inc     ent_state,x
        lda     #$7E
        sta     ent_hp,x
        bne     crash_bomber_bounds
crash_bomber_hit_skip:
        cmp     #$01
        bne     crash_bomber_phase2
        lda     ent_anim_id,x
        cmp     #$04
        bne     crash_bomber_phase1
        lda     #$02
        sta     ent_anim_id,x
crash_bomber_phase1:  dec     ent_hp,x
        bne     crash_bomber_bounds
        lda     #$05
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_anim_frame,x
        lda     #$38
        sta     ent_hp,x
        inc     ent_state,x
crash_bomber_bounds:  jsr     check_entity_on_screen
        rts

crash_bomber_phase2:  lda     #$00
        sta     ent_anim_frame,x
        lda     ent_hp,x
        and     #$07
        bne     crash_bomber_dec_hp
        lda     #$2B
        jsr     sound_queue_push
        lda     ent_hp,x
        lsr     a
        and     #$0C
        sta     temp_02
        lda     #$06
        sta     temp_01
crash_bomber_scatter:  lda     temp_01
        cmp     #$02
        beq     crash_bomber_dec_hp
        sta     temp_00
        ldy     #$0C
        jsr     spawn_weapon_from_entity
        ldy     temp_00
        ldx     temp_02
        clc
        lda     ent_y_px,y
        adc     scatter_offset_y_tbl,x
        sta     ent_y_px,y
        clc
        lda     ent_x_px,y
        adc     scatter_offset_x_lo_tbl,x
        sta     ent_x_px,y
        lda     ent_x_screen,y
        adc     scatter_offset_x_hi_tbl,x
        sta     ent_x_screen,y
        ldx     current_entity_slot
        inc     temp_02
        dec     temp_01
        bne     crash_bomber_scatter
crash_bomber_dec_hp:  ldx     current_entity_slot
        dec     ent_hp,x
        bpl     crash_bomber_check
        lsr     ent_flags,x
        rts

crash_bomber_check:  jsr     check_entity_on_screen
        rts

scatter_offset_y_tbl:  .byte   $F8,$F0,$08,$00,$F8,$F8
        .byte   $08
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
        .byte   $F0,$10
        .byte   $F0,$08
scatter_offset_x_hi_tbl:  .byte   $FF,$00,$00,$00,$FF,$00,$FF,$00
        .byte   $00,$00,$FF,$00,$FF,$00
        .byte   $FF,$00
tile_solid_flag_tbl:  .byte   $00,$01,$00,$00,$00,$01,$01,$01
        .byte   $01

; ─── Time Stopper special AI (types $36/$37) ───
; Freezes the world: game_mode=1 + scroll locks while draining Time
; Stopper energy (1 unit per 15 frames, ent_x_vel_sub as divider).
time_stopper_ai:  dec     ent_x_vel_sub,x
        bne     @skip
        lda     #$0F
        sta     ent_x_vel_sub,x
        dec     weapon_energy + 1
        bne     @skip
        lsr     ent_flags,x
        lda     #$00
        sta     game_mode
        lda     #$01
        sta     scroll_lock_hi
        rts
@skip:
        lda     #$01
        sta     game_mode
        lda     #$00
        sta     scroll_lock_hi
        sta     scroll_lock_lo
        lda     #$80
        sta     ent_y_px,x
        clc
        adc     scroll_x
        sta     ent_x_px,x
        lda     ent_x_screen
        adc     #$00
        sta     ent_x_screen,x
        rts

; ─── Item 1 special AI (type $38) ───
; Rising platform: ascends for $BB frames (state 0), hovers as a rideable
; platform (state 1, $059E/$05A1 = platform width/top), then expires.
item1_platform_ai:  lda     ent_state,x
        bne     @skip_3
        inc     ent_hp,x
        lda     ent_hp,x
        cmp     #$BB
        beq     @skip_2
        lda     ent_anim_id,x
        cmp     #$02
        bne     @done
        lda     #$00
        sta     ent_anim_id,x
@done:
        jmp     item1_platform_update

@skip_2:
        lda     #$3E
        sta     ent_hp,x
        inc     ent_state,x
        bne     item1_platform_update
@skip_3:
        cmp     #$01
        bne     item1_physics
        lda     ent_anim_id,x
        cmp     #$07
        bne     item1_dec_timer
        lda     #$03
        sta     ent_anim_id,x
item1_dec_timer:  dec     ent_hp,x
        beq     item1_end_phase
item1_platform_update:  sec
        lda     ent_y_px,x
        sbc     #$04
        sta     ent_hitbox_width + $03,x
        lda     #$14
        sta     ent_hitbox_width,x
        lda     #$0B
        sta     temp_01
        lda     #$1D
        sta     temp_02
        lda     #$04
        sta     temp_03
        jsr     check_wall_collision
        lda     temp_00
        beq     item1_physics
        lda     #$00
        sta     ent_y_vel_sub,x
item1_end_phase:  lda     #$02
        sta     ent_state,x
        lda     #$08
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_anim_frame,x
        sta     ent_hitbox_width,x
item1_physics:  jsr     entity_physics_core
        bcc     item1_done
        lda     #$00
        sta     ent_hitbox_width,x
item1_done:  rts

; ─── Item 2 special AI (type $39) ───
; Jet sled: accelerates to X velocity 2, drains Item 2 energy (1 unit per
; $13 frames), rideable platform ($059E/$05A1), stops at walls/ledges.
item2_jet_ai:  lda     ent_state,x
        beq     @skip
        dec     ent_state,x
        bne     item2_wall_check
@skip:
        dec     ent_hp,x
        bne     item2_accel
        lda     #$13
        sta     ent_hp,x
        dec     weapon_energy + 5       ; Item 2 energy
        bne     item2_accel
item2_deactivate:  lda     #$05
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_hitbox_width + $02
        sta     ent_x_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_anim_frame,x
        lda     #$80
        sta     ent_flags,x
        beq     item2_accel
        jmp     item2_physics

item2_accel:  lda     ent_x_vel,x
        cmp     #$02
        beq     item2_wall_check
        clc
        lda     ent_x_vel_sub,x
        adc     #$08
        sta     ent_x_vel_sub,x
        lda     ent_x_vel,x
        adc     #$00
        sta     ent_x_vel,x
        cmp     #$02
        bne     item2_wall_check
        lda     #$00
        sta     ent_x_vel_sub,x
item2_wall_check:  lda     #$0F
        sta     temp_01
        lda     #$08
        sta     temp_02
        jsr     check_horiz_tile_collision
        lda     temp_03
        bne     item2_deactivate
        sec
        lda     ent_y_px,x
        sbc     #$20
        sta     temp_0A
        lda     #$00
        sta     temp_0B
        sec
        lda     ent_x_px,x
        sbc     #$10
        sta     jump_ptr
        lda     ent_x_screen,x
        sbc     #$00
        sta     jump_ptr_hi
        jsr     lookup_cached_tile
        ldx     current_entity_slot
        ldy     temp_00
        lda     tile_solid_flag_tbl,y
        bne     item2_deactivate_jmp
        clc
        lda     jump_ptr
        adc     #$20
        sta     jump_ptr
        lda     jump_ptr_hi
        adc     #$00
        sta     jump_ptr_hi
        jsr     lookup_cached_tile
        ldx     current_entity_slot
        ldy     temp_00
        lda     tile_solid_flag_tbl,y
        beq     item2_platform_update
item2_deactivate_jmp:  jmp     item2_deactivate

item2_platform_update:  sec
        lda     ent_y_px,x
        sbc     #$04
        sta     ent_hitbox_width + $03,x
        lda     #$18
        sta     ent_hitbox_width,x
        lda     ent_anim_id,x
        cmp     #$04
        bne     item2_physics
        lda     #$00
        sta     ent_anim_id,x
item2_physics:  jsr     entity_physics_core
        bcc     item2_done
        lda     #$00
        sta     ent_hitbox_width,x
item2_done:  rts

; ─── Item 3 special AI (type $3A) ───
; Wall climber: hops along the floor, climbs walls it touches, drains
; Item 3 energy while deployed.
item3_climber_ai:  lda     ent_state,x
        bne     item3_active
        lda     ent_y_vel,x
        sta     temp_04
        lda     #$0A
        sta     temp_01
        lda     #$08
        sta     temp_02
        jsr     check_horiz_tile_collision
        lda     temp_03
        beq     item3_check_down
        lda     #$62
        sta     ent_y_vel_sub,x
        lda     #$00
        sta     ent_y_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
        lda     ent_flags,x
        and     #$FB
        sta     ent_flags,x
        inc     ent_state,x
        bne     item3_step
item3_check_down:  lda     temp_04
        bpl     item3_step
        lda     temp_00
        beq     item3_step
        lda     #$03
        sta     ent_y_vel,x
        lda     #$76
        sta     ent_y_vel_sub,x
item3_step:  lda     #$00
        sta     ent_weapon_type,x
        lda     ent_anim_id,x
        cmp     #$04
        bne     item3_dec_timer
        lda     #$00
        sta     ent_anim_id,x
item3_dec_timer:  dec     ent_hp,x
        bne     item3_physics_jmp
        lda     #$1F
        sta     ent_hp,x
        dec     weapon_energy + 6       ; Item 3 energy
        beq     item3_finish
item3_physics_jmp:  jmp     item3_physics

item3_active:  sec
        lda     ent_y_px,x
        sbc     #$08
        sta     ent_hitbox_width + $03,x ; platform top ($05A1)
        lda     #$14
        sta     ent_hitbox_width,x
        lda     #$0C
        sta     temp_01
        lda     #$21
        sta     temp_02
        lda     #$08
        sta     temp_03
        jsr     check_wall_collision
        lda     ent_state,x
        and     #$0F
        cmp     #$02
        bcs     item3_alt_state
        lda     ent_state,x
        bpl     item3_check_done
        inc     ent_state,x
        bne     item3_check_done
item3_check_done:  lda     temp_00
        bne     item3_finish
        lda     temp_03
        bne     item3_step
        lda     #$00
        sta     ent_y_vel,x
        sta     ent_y_vel_sub,x
        lda     ent_anim_id,x
        cmp     #$09
        bne     item3_inc_climb
        lda     #$05
        sta     ent_anim_id,x
item3_inc_climb:  inc     ent_weapon_type,x
        lda     ent_weapon_type,x
        cmp     #$3E
        bcc     item3_dec_timer
item3_finish:  lda     #$0A
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_y_vel,x
        sta     ent_y_vel_sub,x
        sta     ent_anim_frame,x
        sta     ent_hitbox_width,x
        lda     #$80
        sta     ent_flags,x
        rts

item3_alt_state:  lda     ent_state,x
        bpl     item3_check_fall
        and     #$0F
        sta     ent_state,x
        lda     #$62
        sta     ent_y_vel_sub,x
        lda     #$00
        sta     ent_y_vel,x
        beq     item3_check_done
item3_check_fall:  lda     ent_y_vel,x
        bpl     item3_set_vel
        lda     temp_00
        bne     item3_finish
item3_set_vel:  lda     #$9E
        sta     ent_y_vel_sub,x
        lda     #$FF
        sta     ent_y_vel,x
        jmp     item3_check_done

item3_physics:  jsr     entity_physics_core
        bcc     item3_done
        lda     #$00
        sta     ent_hitbox_width,x
item3_done:  rts

; ─── Check wall collision in facing direction ───
check_wall_collision:  lda     ent_flags,x
        and     #$40
        bne     wall_coll_facing_right
        sec
        lda     ent_x_px,x
        sbc     temp_01
        sta     jump_ptr
        lda     ent_x_screen,x
        sbc     #$00
        jmp     wall_coll_store_screen

wall_coll_facing_right:  clc
        lda     ent_x_px,x
        adc     temp_01
        sta     jump_ptr
        lda     ent_x_screen,x
        adc     #$00
wall_coll_store_screen:  sta     jump_ptr_hi
        sec
        lda     ent_y_px,x
        sbc     #$08
        sta     temp_0A
        lda     #$00
        sbc     #$00
        sta     temp_0B
        jsr     lookup_cached_tile
        ldx     current_entity_slot
        ldy     temp_00
        lda     wall_solid_flag_tbl,y
        pha
        lda     ent_y_vel,x
        bpl     wall_coll_check_below
        clc
        lda     ent_y_px,x
        adc     temp_03
        sta     temp_0A
        lda     #$00
        adc     #$00
        jmp     wall_coll_store_y

wall_coll_check_below:  sec
        lda     ent_y_px,x
        sbc     temp_02
        sta     temp_0A
        lda     #$00
        sbc     #$00
wall_coll_store_y:  sta     temp_0B
        lda     ent_x_px,x
        sta     jump_ptr
        lda     ent_x_screen,x
        sta     jump_ptr_hi
        jsr     lookup_cached_tile
        ldx     current_entity_slot
        ldy     temp_00
        lda     wall_solid_flag_tbl,y
        sta     temp_00
        pla
        sta     temp_03
        rts

wall_solid_flag_tbl:  .byte   $00,$01,$00,$01,$00,$01,$01,$01 ; wall collision solid flags
        .byte   $01

; ─── Special AI for type $3B (unused — type never spawned as weapon entity) ───
; Ping-pong bouncer: reverses direction each cycle, hops with velocity $FE/$01.
type3B_bounce_ai:  lda     #$00
        sta     ent_anim_frame,x
        lda     ent_state,x
        bne     crash_entity_accelerate
        lda     ent_hp,x
        bne     crash_entity_dec_timer
        lda     ent_flags,x
        eor     #$40
        sta     ent_flags,x
        inc     ent_anim_id,x
        and     #$40
        beq     crash_entity_reset_vel
        inc     ent_anim_id,x
crash_entity_reset_vel:  lda     #$00
        sta     ent_x_vel_sub,x
        sta     ent_y_vel_sub,x
        lda     #$FE
        sta     ent_y_vel,x
        lda     #$01
        sta     ent_x_vel,x
        lda     #$10
        sta     ent_hp,x
        inc     ent_state,x
        bne     crash_entity_dec_timer
crash_entity_accelerate:  clc
        lda     ent_x_vel_sub,x
        adc     #$40
        sta     ent_x_vel_sub,x
        lda     ent_x_vel,x
        adc     #$00
        sta     ent_x_vel,x
        lda     ent_hp,x
        bne     crash_entity_dec_timer
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_x_vel_sub,x
        sta     ent_x_vel,x
        sta     ent_y_vel_sub,x
        sta     ent_y_vel,x
        lda     #$02
        sta     ent_hp,x
        dec     ent_state,x
crash_entity_dec_timer:  dec     ent_hp,x
        jsr     entity_physics_core
        rts

; ─── Special AI for types $3C/$3D: despawn when scrolled off-screen ───
offscreen_check_ai:  jsr     check_entity_on_screen
        rts

special_ai_rts:  rts                    ; type $3E: no special AI
; ─── Deactivate entity if off-screen ───
check_entity_on_screen:  sec
        lda     ent_x_px,x
        sbc     scroll_x
        lda     ent_x_screen,x
        sbc     nametable_select
        bcc     entity_off_screen_deactivate
        bne     entity_off_screen_deactivate
        clc
        rts

entity_off_screen_deactivate:  lsr     ent_flags,x
        sec
        rts

; ─── Spawn weapon projectile from entity ───
spawn_weapon_from_entity:  lda     ent_x_px,x
        sta     jump_ptr
        lda     ent_x_screen,x
        sta     jump_ptr_hi
        lda     ent_y_px,x
        sta     temp_0A
        ldx     temp_00
        lda     projectile_type_tbl,y
        sta     ent_type,x
        lda     projectile_flags_tbl,y
        sta     ent_flags,x
        lda     jump_ptr
        sta     ent_x_px,x
        lda     jump_ptr_hi
        sta     ent_x_screen,x
        lda     temp_0A
        sta     ent_y_px,x
        lda     projectile_xvel_sub_tbl,y
        sta     ent_x_vel_sub,x
        lda     projectile_xvel_tbl,y
        sta     ent_x_vel,x
        lda     projectile_yvel_sub_tbl,y
        sta     ent_y_vel_sub,x
        lda     projectile_yvel_tbl,y
        sta     ent_y_vel,x
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        sta     ent_state,x
        sec
        lda     ent_x_px,x
        sbc     scroll_x
        sta     ent_screen_x,x
        ldx     current_entity_slot
        rts

; =============================================================================
; check_player_collision — Enemy→player contact damage check ($E55A)
; =============================================================================
; Tests bounding-box overlap between player and enemy entity in slot X.
; On hit: subtracts damage from player HP, applies knockback, or picks up item.
; Output: temp_01 = 1 if collision occurred, 0 otherwise.
; =============================================================================
check_player_collision:  lda     #$00
        sta     temp_01
        lda     game_substate           ; skip if player not active
        beq     player_collision_done
        lda     boss_state_flag
        bne     player_collision_done
        lda     player_y_screen
        bne     player_collision_done
; --- X-axis distance: |player_x - enemy_x| ---
        sec
        lda     player_screen_x
        sbc     current_ent_x
        bcs     player_coll_check_range ; positive = no borrow
        eor     #$FF                    ; negate: two's complement for |distance|
        adc     #$01
player_coll_check_range:
        ldy     ent_screen_x,x          ; Y = hitbox table index
        cmp     contact_damage_range_x_tbl,y
        bcs     player_collision_done   ; X distance >= hitbox width → no hit
; --- Y-axis distance: |player_y - enemy_y| ---
        sec
        lda     ent_y_px
        sbc     ent_y_px,x
        bcs     player_coll_check_y
        eor     #$FF
        adc     #$01
player_coll_check_y:
        cmp     contact_damage_range_y_tbl,y
        bcs     player_collision_done   ; Y distance >= hitbox height → no hit
; --- Collision confirmed: dispatch by entity type ---
        ldy     ent_type,x
        cpy     #$76                    ; types $76+ are item pickups
        bcs     player_collision_item
        lda     invincibility_timer     ; skip damage during i-frames
        bne     player_collision_done
        sec
        lda     ent_hp
        sbc     contact_damage_to_player_tbl,y ; subtract enemy's contact damage
        sta     ent_hp
        beq     player_coll_kill
        bcs     player_coll_knockback
player_coll_kill:
        lda     #$00
        sta     game_substate
        sta     ent_hp
        jmp     player_death_sequence
; --- Knockback: set player facing away from enemy ---
player_coll_knockback:
        lda     ent_flags               ; clear player direction bit
        and     #$BF
        sta     ent_flags
        lda     ent_flags,x             ; get enemy direction bit 6
        and     #$40
        eor     #$40                    ; flip: player faces AWAY from enemy
        ora     ent_flags
        sta     ent_flags
        jsr     player_damage_knockback ; trigger recoil animation
        inc     temp_01
player_collision_done:  rts

; --- Item pickup: despawn item and clear parent's child HP ---
player_collision_item:
        lda     item_pickup_type
        bne     player_collision_return
        lsr     ent_flags,x             ; deactivate item entity
        sty     item_pickup_type        ; store item type for pickup handler
        inc     temp_01
        lda     ent_state,x
        bne     player_collision_return
        lda     #$FF
        sta     ent_despawn,x           ; mark for despawn
        lda     ent_parent_slot,x       ; clear parent's child HP tracker
        tay
        lda     #$00
        sta     ent_child_hp,y
player_collision_return:  rts

; =============================================================================
; check_weapon_collision — Weapon→enemy hit detection ($E5EC)
; =============================================================================
; Scans weapon slots 2-9 for bounding-box overlap with enemy in current slot.
; Frame-alternating: starts at slot 9 on odd frames, slot 8 on even frames,
; then decrements by 2 (9,7,5,3 or 8,6,4,2) to split work across frames.
; On hit: dispatches to weapon-specific collision handler via pointer table.
; =============================================================================
check_weapon_collision:  lda     ent_y_px,x
        sta     temp_00                 ; enemy Y pixel
        lda     ent_screen_x,x
        sta     jump_ptr                ; enemy screen-relative X
        ldx     #$09                    ; start at weapon slot 9
        lda     frame_counter
        and     #$01                    ; alternate: even frames start at slot 8
        bne     weapon_coll_check_slot
        dex
weapon_coll_check_slot:
        lda     ent_flags,x
        bpl     weapon_coll_next_slot   ; skip inactive weapons (bit 7 clear)
        and     #$01
        beq     weapon_coll_next_slot   ; skip non-weapon entities (bit 0 clear)
        clc
        ldy     ent_weapon_type,x       ; weapon damage type → hitbox table offset
        lda     weapon_range_offset_tbl,y
        adc     jump_ptr                ; Y = hitbox table base + entity offset
        tay
; --- X-axis distance check ---
        sec
        lda     current_ent_x
        sbc     ent_screen_x,x
        bcs     weapon_coll_check_range_x
        eor     #$FF
        adc     #$01
weapon_coll_check_range_x:
        cmp     contact_damage_range_x_tbl,y
        bcs     weapon_coll_next_slot
; --- Y-axis distance check ---
        sec
        lda     temp_00
        sbc     ent_y_px,x
        bcs     weapon_coll_check_range_y
        eor     #$FF
        adc     #$01
weapon_coll_check_range_y:
        cmp     contact_damage_range_y_tbl,y
        bcc     weapon_collision_dispatch ; both axes within range = hit
weapon_coll_next_slot:
        dex                             ; skip to next odd/even slot
        dex
        cpx     #$02
        bcs     weapon_coll_check_slot
        ldx     current_entity_slot     ; no hit: restore entity slot
        lda     #$00
        sta     ent_hit_count,x
        clc                             ; carry clear = no collision
        rts

; --- Hit confirmed: dispatch to weapon-specific collision handler ---
weapon_collision_dispatch:
        ldy     current_weapon
        lda     weapon_handler_ptr_lo,y
        sta     jump_ptr
        lda     weapon_handler_ptr_hi,y
        sta     jump_ptr_hi
        jmp     (jump_ptr)

; ─── Buster hit handler (weapon 0) ───
; Each handler: enemy shield flag (ent_flags bit 3) → deflect; else look up
; per-type damage, apply difficulty doubling, subtract from enemy HP.
; Returns carry set = enemy killed (caller runs item drop + death explode).
weapon_hit_buster:  ldy     current_entity_slot
        lda     ent_flags,y
        and     #$08
        bne     @skip_2
        lda     ent_type,y
        tay
        lda     weapon_dmg_buster_tbl,y
        sta     temp_00
        beq     @skip_2
        jsr     apply_difficulty_modifier
        lsr     ent_flags,x
        lda     #$2B
        jsr     sound_queue_push
        ldx     current_entity_slot
        lda     ent_hit_count,x
        bne     @no_match
        inc     ent_hit_count,x
        sec
        lda     ent_hp,x
        sbc     temp_00
        sta     ent_hp,x
        beq     @skip
        bcs     @no_match
@skip:
        lda     #$00
        sta     ent_hp,x
        sec
        rts

@skip_2:
        lda     ent_flags,x
        eor     #$40
        and     #$FE
        sta     ent_flags,x
        lda     #$05
        sta     ent_y_vel,x
        sta     ent_x_vel,x
        lda     #$2D
        jsr     sound_queue_push
        ldx     current_entity_slot
@no_match:
        clc
        rts

; ─── Atomic Fire hit handler (weapon 1) ───
; Damage scales with charge level (ent_state): 0-1 = buster table,
; 2 = 3x buster table, 3+ = full-charge table.
weapon_hit_atomic:  ldy     current_entity_slot
        lda     ent_flags,y
        and     #$08
        bne     weapon_damage_zero
        lda     ent_type,y
        tay
        lda     ent_state,x
        cmp     #$02
        bcc     @skip_3
        beq     @no_match_2
        lda     weapon_dmg_atomic_tbl,y ; full charge
        jmp     weapon_damage_apply
@no_match_2:
        clc
        lda     weapon_dmg_buster_tbl,y ; mid charge: 3x buster damage
        asl     a
        adc     weapon_dmg_buster_tbl,y
        jmp     weapon_damage_apply

@skip_3:
        lda     weapon_dmg_buster_tbl,y ; uncharged: buster damage
weapon_damage_apply:  sta     temp_00
        beq     weapon_damage_zero
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     sound_queue_push
        pla
        tay
        ldx     current_entity_slot
        lda     ent_hit_count,x
        bne     weapon_damage_done
        inc     ent_hit_count,x
        sec
        lda     ent_hp,x
        sbc     temp_00
        sta     ent_hp,x
        beq     weapon_damage_killed
        bcs     weapon_damage_deactivate_wpn
weapon_damage_killed:  lda     #$00
        sta     ent_hp,x
        sec
        rts

weapon_damage_zero:  lda     #$2D
        jsr     sound_queue_push
        lsr     ent_flags,x
        jmp     weapon_damage_done

weapon_damage_deactivate_wpn:  lda     #$00
        sta     ent_flags,y
weapon_damage_done:  ldx     current_entity_slot
        clc
        rts

; ─── Air Shooter hit handler (weapon 2) ───
weapon_hit_air:  ldy     current_entity_slot
        lda     ent_flags,y
        and     #$08
        bne     weapon_damage_killed_alt_skip
        lda     ent_type,y
        tay
        lda     weapon_dmg_air_tbl,y
        sta     temp_00
        beq     weapon_damage_killed_alt_skip
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     sound_queue_push
        pla
        tay
        ldx     current_entity_slot
        lda     ent_hit_count,x
        bne     weapon_damage_return
        inc     ent_hit_count,x
        sec
        lda     ent_hp,x
        sbc     temp_00
        sta     ent_hp,x
        beq     weapon_damage_killed_alt
        bcs     weapon_damage_deactivate_wpn
weapon_damage_killed_alt:  lda     #$00
        sta     ent_hp,x
        sec
        rts

weapon_damage_killed_alt_skip:
        lda     #$2D
        jsr     sound_queue_push
        lda     ent_flags,x
        and     #$FE
        sta     ent_flags,x
        lda     #ENTITY_KAMINARI_CLOUD
        sta     ent_type,x
        lda     #$00
        sta     ent_anim_id,x
        sta     ent_anim_frame,x
        ldx     current_entity_slot
weapon_damage_return:  clc
        rts

; ─── Leaf Shield hit handler (weapon 3) ───
weapon_hit_leaf:  ldy     current_entity_slot
        lda     ent_flags,y
        and     #$08
        bne     @skip_2
        lda     ent_type,y
        tay
        lda     weapon_dmg_leaf_tbl,y
        sta     temp_00
        beq     @skip_2
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     sound_queue_push
        pla
        tay
        ldx     current_entity_slot
        lda     ent_hit_count,x
        bne     weapon_coll_handler_done_no_match
        inc     ent_hit_count,x
        sec
        lda     ent_hp,x
        sbc     temp_00
        sta     ent_hp,x
        beq     @skip
        bcs     weapon_coll_deactivate
@skip:
        lda     #$00
        sta     ent_hp,x
        sec
        rts

@skip_2:
        lda     #$2D
        jsr     sound_queue_push
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
weapon_coll_handler_done:  ldx     current_entity_slot
weapon_coll_handler_done_no_match:
        clc
        rts

weapon_coll_deactivate:  lda     #$00
        sta     ent_flags,y
        beq     weapon_coll_handler_done

; ─── Bubble Lead hit handler (weapon 4) ───
weapon_hit_bubble:  ldy     current_entity_slot
        lda     ent_flags,y
        and     #$08
        bne     weapon_coll_rebound
        lda     ent_type,y
        tay
        lda     weapon_dmg_bubble_tbl,y
        sta     temp_00
        beq     weapon_coll_rebound
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     sound_queue_push
        pla
        tay
        ldx     current_entity_slot
        lda     ent_hit_count,x
        bne     weapon_coll_rebound_done
        inc     ent_hit_count,x
        sec
        lda     ent_hp,x
        sbc     temp_00
        sta     ent_hp,x
        beq     weapon_coll_hp_zero
        bcs     weapon_coll_deactivate
weapon_coll_hp_zero:  lda     #$00
        sta     ent_hp,x
        sec
        rts

weapon_coll_rebound:  lda     #$00
        sta     ent_x_vel,x
        sta     ent_x_vel_sub,x
        sta     ent_y_vel_sub,x
        lda     #$04
        sta     ent_y_vel,x
        lda     #$80
        sta     ent_flags,x
        lda     #$2D
        jsr     sound_queue_push
        ldx     current_entity_slot
weapon_coll_rebound_done:  clc
        rts

; ─── Quick Boomerang hit handler (weapon 5) ───
weapon_hit_quick:  ldy     current_entity_slot
        lda     ent_flags,y
        and     #$08
        bne     @skip_2
        lda     ent_type,y
        tay
        lda     weapon_dmg_quick_tbl,y
        sta     temp_00
        beq     @skip_2
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     sound_queue_push
        pla
        tay
        ldx     current_entity_slot
        lda     ent_hit_count,x
        bne     weapon_coll_handler_2_done_no_match
        inc     ent_hit_count,x
        sec
        lda     ent_hp,x
        sbc     temp_00
        sta     ent_hp,x
        beq     @skip
        bcs     weapon_coll_deactivate_2
@skip:
        lda     #$00
        sta     ent_hp,x
        sec
        rts

@skip_2:
        lda     #ENTITY_COPIPI
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
        jsr     sound_queue_push
weapon_coll_handler_2_done:  ldx     current_entity_slot
weapon_coll_handler_2_done_no_match:
        clc
        rts

weapon_coll_deactivate_2:  lda     #$00
        sta     ent_flags,y
        beq     weapon_coll_handler_2_done

; ─── Crash Bomber hit handler (weapon 8) ───
; Shielded enemy → bomb attaches (anim 5, fuse $38) instead of deflecting.
weapon_hit_crash:  ldy     current_entity_slot
        lda     ent_flags,y
        and     #$08
        bne     weapon_coll_stun
        lda     ent_type,y
        tay
        lda     weapon_dmg_crash_tbl,y
        sta     temp_00
        beq     weapon_coll_stun
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     sound_queue_push
        pla
        tay
        ldx     current_entity_slot
        lda     ent_hit_count,x
        bne     weapon_coll_stun_done
        inc     ent_hit_count,x
        sec
        lda     ent_hp,x
        sbc     temp_00
        sta     ent_hp,x
        beq     weapon_coll_hp_zero_2
        bcs     weapon_coll_deactivate_2
weapon_coll_hp_zero_2:  lda     #$00
        sta     ent_hp,x
        sec
        rts

weapon_coll_stun:  lda     ent_type,x
        cmp     #$2F
        beq     weapon_coll_stun_done
        lda     ent_state,x
        cmp     #$02
        beq     weapon_coll_stun_done
        lda     #$05
        sta     ent_anim_id,x
        lda     #$00
        sta     ent_anim_frame,x
        lda     #$38
        sta     ent_hp,x
        inc     ent_state,x
        lda     #$2D
        jsr     sound_queue_push
weapon_coll_stun_done:  ldx     current_entity_slot
        clc
        rts

; ─── Metal Blade hit handler (weapon 7) ───
weapon_hit_metal:  ldy     current_entity_slot
        lda     ent_flags,y
        and     #$08
        bne     @skip_2
        lda     ent_type,y
        tay
        lda     weapon_dmg_metal_tbl,y
        sta     temp_00
        beq     @skip_2
        jsr     apply_difficulty_modifier
        txa
        pha
        lda     #$2B
        jsr     sound_queue_push
        pla
        tay
        ldx     current_entity_slot
        lda     ent_hit_count,x
        bne     weapon_coll_handler_3_done_no_match
        inc     ent_hit_count,x
        sec
        lda     ent_hp,x
        sbc     temp_00
        sta     ent_hp,x
        beq     @skip
        bcs     weapon_coll_handler_3_done_skip
@skip:
        lda     #$00
        sta     ent_hp,x
        sec
        rts

@skip_2:
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
        jsr     sound_queue_push
weapon_coll_handler_3_done:  ldx     current_entity_slot
weapon_coll_handler_3_done_no_match:
        clc
        rts

weapon_coll_handler_3_done_skip:
        lda     #$00
        sta     ent_flags,y
        beq     weapon_coll_handler_3_done
; ─── Double damage on Normal difficulty ───
; Also doubles as the Time Stopper "hit handler" (weapon 6) in
; weapon_handler_ptr — a harmless no-op since Time Stopper deals no
; collision damage.
apply_difficulty_modifier:  lda     difficulty ; 0=Normal, 1=Difficult
        bne     difficulty_done       ; Difficult: use base damage as-is
        asl     temp_00              ; Normal: double enemy collision damage to player
difficulty_done:  rts

; Weapon→enemy hit handler per weapon ID (P,H,A,W,B,Q,F,M,C)
weapon_handler_ptr_lo:
        .byte   <weapon_hit_buster,<weapon_hit_atomic,<weapon_hit_air
        .byte   <weapon_hit_leaf,<weapon_hit_bubble,<weapon_hit_quick
        .byte   <apply_difficulty_modifier,<weapon_hit_metal,<weapon_hit_crash
weapon_handler_ptr_hi:
        .byte   >weapon_hit_buster,>weapon_hit_atomic,>weapon_hit_air
        .byte   >weapon_hit_leaf,>weapon_hit_bubble,>weapon_hit_quick
        .byte   >apply_difficulty_modifier,>weapon_hit_metal,>weapon_hit_crash
; =============================================================================
; Weapon damage tables — damage per enemy type ($00-$7B), one per weapon.
; Tables overlap-truncate at 120/124 entries (high types are never checked).
; =============================================================================
weapon_dmg_buster_tbl:  .byte   $07,$07,$14,$14,$14,$14,$14,$14
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
        .byte   $00,$00,$00,$00
weapon_dmg_atomic_tbl:  .byte   $14,$14,$00,$00,$14,$00,$14,$00
        .byte   $14,$00,$14,$14,$14,$14,$00,$14
        .byte   $00,$00,$00,$00,$00,$00,$14,$14
        .byte   $00,$14,$00,$00,$00,$14,$00,$14
        .byte   $00,$00,$14,$00,$00,$00,$00,$00
        .byte   $00,$14,$14,$00,$14,$00,$00,$00
        .byte   $00,$14,$00,$00,$14,$14,$00,$00
        .byte   $14,$00,$14,$14,$14,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$14,$00
        .byte   $14,$14,$00,$14,$14,$00,$14,$14
        .byte   $14,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$14,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
weapon_dmg_air_tbl:  .byte   $00,$00,$00,$00,$14,$00,$14,$00
        .byte   $14,$00,$00,$14,$00,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$14,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$14,$14,$00,$00,$00,$00
        .byte   $00,$00,$14,$00,$14,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $14,$00,$07,$00,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$00,$00
        .byte   $07,$07,$00,$07,$07,$00,$07,$04
        .byte   $14,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
weapon_dmg_leaf_tbl:  .byte   $14,$14,$00,$00,$14,$00,$14,$00
        .byte   $14,$00,$14,$14,$00,$14,$00,$07
        .byte   $00,$00,$00,$00,$00,$00,$14,$14
        .byte   $00,$14,$00,$00,$00,$14,$00,$14
        .byte   $00,$00,$14,$07,$00,$00,$00,$00
        .byte   $00,$07,$14,$00,$07,$00,$00,$00
        .byte   $00,$00,$00,$00,$14,$00,$07,$00
        .byte   $14,$00,$14,$00,$14,$14,$00,$00
        .byte   $00,$00,$00,$00,$00,$14,$14,$00
        .byte   $14,$14,$00,$14,$14,$00,$07,$07
        .byte   $14,$14,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
weapon_dmg_bubble_tbl:  .byte   $14,$14,$00,$00,$00,$00,$14,$00
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
weapon_dmg_quick_tbl:  .byte   $07,$07,$00,$00,$14,$00,$14,$00
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
weapon_dmg_crash_tbl:  .byte   $14,$14,$00,$00,$14,$00,$14,$00
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
weapon_dmg_metal_tbl:  .byte   $14,$14,$00,$00,$14,$00,$14,$00
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
contact_damage_to_player_tbl:  .byte   $02,$02,$02,$02,$02,$02,$04,$04
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
        .byte   $00,$00,$00,$00

; ─── Platform special AI #1: rideable platform, height $14 ───
platform_ai_h14:  lda     #$14
        sta     ent_plat_height,x
        jsr     apply_entity_physics_alt
        bcc     @active
        lda     #$00
        sta     ent_plat_height,x
@active:
        sec
        lda     ent_y_px,x
        sbc     #$04
        sta     ent_plat_y,x
        rts

; ─── Platform special AI #2: rideable platform, height $18 ───
platform_ai_h18_a:  lda     #$18
        sta     ent_plat_height,x
        jsr     apply_entity_physics_alt
        bcc     @in_range_2
        lda     #$00
        sta     ent_plat_height,x
@in_range_2:
        sec
        lda     ent_y_px,x
        sbc     #$08
        sta     ent_plat_y,x
        rts

; ─── Platform special AI #3: rideable platform, height $18 ───
platform_ai_h18_b:  lda     #$18
        sta     ent_plat_height,x
        jsr     apply_entity_physics_alt
        bcc     @in_range_3
        lda     #$00
        sta     ent_plat_height,x
@in_range_3:
        sec
        lda     ent_y_px,x
        sbc     #$08
        sta     ent_plat_y,x
        rts

        jsr     entity_face_player
        sec
        lda     ent_type,x
        sbc     #$40
        tay
        lda     $AF79,y
        sta     temp_01
        lda     ent_flags,x
        and     #$20
        beq     @skip_3
        ldy     temp_01
        lda     #$15
        cmp     palette_ram + $02,y
        bne     @skip
        lda     #$04
        sta     ent_x_vel_sub,x
        bne     @skip_2
@skip:
        lda     temp_00
        cmp     #$60
        bcs     collision_apply_physics
@skip_2:
        lda     #$82
        sta     ent_flags,x
@skip_3:
        lda     ent_x_vel_sub,x
        cmp     #$04
        bcs     collision_apply_physics
        lda     ent_state,x
        and     #$03
        bne     collision_inc_state
        sta     ent_state,x
        lda     ent_x_vel_sub,x
        inc     ent_x_vel_sub,x
        asl     a
        asl     a
        tay
        ldx     temp_01
        jsr     banked_0B_item_spawn
        ldx     current_entity_slot
collision_inc_state:  inc     ent_state,x
collision_apply_physics:  jsr     apply_entity_physics_alt
        rts

        lda     ent_x_vel_sub,x
        bne     @skip
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
        bcs     @skip
        lda     #ENTITY_LIGHT_RESTORE
        jsr     spawn_entity_from_parent
@skip:
        jsr     apply_entity_physics_alt
        bcc     collision_done
        lda     #ENTITY_CHANGKEY
        jsr     find_entity_by_type
        bcc     collision_done
        lda     #ENTITY_BLACKOUT_RE
        jsr     spawn_entity_from_parent
collision_done:  rts

        rts
apply_simple_collision:                 ; bank0E entry: death_context=1 (secondary despawn)
        lda     #$01
        bne     collision_set_context
apply_entity_physics:                   ; bank0E entry: collision-gated physics ($EEBA)
        lda     #$00
collision_set_context:
        sta     death_context
        lda     ent_flags,x
        and     #$03
        beq     entity_physics_core
        pha
        and     #$01
        beq     collision_check_contact
        jsr     check_player_collision
collision_check_contact:  pla
        and     #$02
        beq     entity_physics_core
        jsr     check_weapon_collision
        bcc     entity_physics_core
        jsr     item_drop_rng
apply_collision_physics:                ; bank0E entry: kill handler ($EEDA)
        lda     #ENTITY_DEATH_EXPLODE
        sta     ent_type,x
        lda     #$80
        sta     ent_flags,x
        lda     #$00
        sta     ent_anim_frame,x
        sta     ent_anim_id,x
        jmp     physics_despawn_check

; =============================================================================
; entity_physics_core — Move entity by velocity, apply gravity, bounds check ($EEEF)
; =============================================================================
; Input: X = entity slot
; Output: carry clear = in bounds, carry set = despawned
;
; Y velocity is SUBTRACTED (positive Y_vel = upward movement in NES coords).
; X velocity is added/subtracted based on facing direction (bit 6).
; Gravity decreases Y velocity each frame (increasing downward speed).
; Entities outside screen bounds ($08-$F7 relative to scroll) are despawned.
; =============================================================================
entity_physics_core:
; --- Y movement: position -= velocity (16-bit sub-pixel) ---
        sec
        lda     ent_y_sub,x
        sbc     ent_y_vel_sub,x
        sta     ent_y_sub,x
        lda     ent_y_px,x
        sbc     ent_y_vel,x
        sta     ent_y_px,x
        cmp     #$F0                    ; Y >= $F0 = fallen off screen
        bcc     physics_check_gravity
        jmp     physics_out_of_bounds

; --- Gravity: velocity -= gravity constant (increases downward speed) ---
physics_check_gravity:
        lda     ent_flags,x
        and     #$04                    ; bit 2 = gravity enabled
        beq     physics_move_left
        clc
        lda     ent_y_vel_sub,x
        sbc     gravity_sub_lo          ; 16-bit subtract: vel -= gravity
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        sbc     gravity_sub_hi
        sta     ent_y_vel,x
; --- X movement: direction-dependent (bit 6 = facing) ---
physics_move_left:
        lda     ent_flags,x
        and     #$40                    ; bit 6: 0=left, 1=right
        bne     physics_move_right
        sec                             ; facing left: position -= velocity
        lda     ent_x_sub,x
        sbc     ent_x_vel_sub,x
        sta     ent_x_sub,x
        lda     ent_x_px,x
        sbc     ent_x_vel,x
        sta     ent_x_px,x
        lda     ent_x_screen,x
        sbc     #$00                    ; borrow into screen byte
        sta     ent_x_screen,x
        sec                             ; compute screen-relative X
        lda     ent_x_px,x
        sbc     scroll_x
        sta     jump_ptr
        lda     ent_x_screen,x
        sbc     nametable_select
        bne     physics_out_of_bounds   ; different screen = offscreen
        lda     jump_ptr
        cmp     #$08                    ; left boundary
        bcc     physics_out_of_bounds
        bcs     physics_in_bounds
physics_move_right:
        clc                             ; facing right: position += velocity
        lda     ent_x_sub,x
        adc     ent_x_vel_sub,x
        sta     ent_x_sub,x
        lda     ent_x_px,x
        adc     ent_x_vel,x
        sta     ent_x_px,x
        lda     ent_x_screen,x
        adc     #$00                    ; carry into screen byte
        sta     ent_x_screen,x
        sec                             ; compute screen-relative X
        lda     ent_x_px,x
        sbc     scroll_x
        sta     jump_ptr
        lda     ent_x_screen,x
        sbc     nametable_select
        bne     physics_out_of_bounds
        lda     jump_ptr
        cmp     #$F8                    ; right boundary
        bcs     physics_out_of_bounds
physics_in_bounds:
        clc                             ; carry clear = entity still active
        rts

; --- Despawn: deactivate entity and handle parent-child cleanup ---
physics_out_of_bounds:
        lsr     ent_flags,x             ; clear bit 7 (deactivate)
physics_despawn_check:
        cpx     #$10                    ; slots $00-$0F = player/weapons (no despawn tracking)
        bcc     physics_despawn_return
        lda     death_context
        bne     physics_despawn_secondary
        lda     #$FF                    ; primary despawn: mark spawn slot
        sta     a:$F0,x
physics_despawn_return:
        sec                             ; carry set = entity despawned
        rts

physics_despawn_secondary:
        lda     #$FF                    ; secondary despawn: notify parent
        sta     ent_despawn,x
        lda     ent_parent_slot,x
        tay
        lda     ent_hp,x               ; pass child HP to parent
        sta     ent_child_hp,y
        sec
        rts

apply_simple_physics:                   ; bank0E entry: death_context=1 ($EFAF)
        lda     #$01
        bne     apply_entity_physics_alt_skip

; =============================================================================
; apply_entity_physics_alt — Collision + death handling for enemies ($EFB3)
; =============================================================================
; Called by enemy AI handlers. Tests contact and weapon collision based on
; ent_flags bits 0-1. On weapon kill: rolls item drop, converts entity
; to death explosion, and runs despawn check.
; Output: carry set = entity destroyed, carry clear = alive
; =============================================================================
apply_entity_physics_alt:  lda     #$00
apply_entity_physics_alt_skip:
        sta     death_context           ; 0=primary despawn, 1=secondary (child)
        lda     ent_flags,x
        and     #$03                    ; bits 0-1: contact(0) + weapon(1)
        beq     physics_alt_check_offscreen
        pha
        and     #$01                    ; bit 0: player contact damage?
        beq     physics_alt_check_contact
        jsr     check_player_collision
physics_alt_check_contact:
        pla
        and     #$02                    ; bit 1: weapon collidable?
        beq     physics_alt_check_offscreen
        jsr     check_weapon_collision
        bcc     physics_alt_check_offscreen  ; carry clear = no hit
; --- Enemy killed by weapon ---
        jsr     item_drop_rng           ; random item drop
        lda     #ENTITY_DEATH_EXPLODE   ; convert to death explosion
        sta     ent_type,x
        lda     #$80                    ; active, no collision flags
        sta     ent_flags,x
        lda     #$00
        sta     ent_anim_frame,x
        sta     ent_anim_id,x
        jmp     physics_despawn_check

physics_alt_check_offscreen:  lda     offscreen_flag
        bne     physics_out_of_bounds
        clc
        rts

; ─── Turn entity to face player ───
entity_face_player:  lda     ent_flags,x
        and     #$BF
        sta     ent_flags,x
        sec
        lda     current_ent_x
        sbc     player_screen_x
        sta     temp_00
        bcs     entity_face_player_done
        lda     temp_00
        eor     #$FF
        adc     #$01
        sta     temp_00
        lda     #$40
        ora     ent_flags,x
        sta     ent_flags,x
entity_face_player_done:  rts

; ─── Find active entity by type ID ───
find_entity_by_type:  sta     temp_00
        ldy     #$0F
find_entity_scan:  lda     temp_00
find_entity_compare:  cmp     ent_spawn_type,y
        beq     find_entity_check_active
        dey
        bpl     find_entity_compare
        sec
        rts

find_entity_check_active:  lda     ent_spawn_flags,y
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
        sta     temp_0B
        lda     ent_y_vel,x                 ; Y velocity (direction)
        php
        bpl     vert_coll_falling
        clc
        lda     ent_y_px,x
        adc     temp_02
        jmp     vert_coll_store_pos

vert_coll_falling:  sec
        lda     ent_y_px,x
        sbc     temp_02
vert_coll_store_pos:  sta     temp_0A
        clc
        lda     ent_x_px,x
        adc     temp_01
        sta     jump_ptr
        lda     ent_x_screen,x
        adc     #$00
        sta     jump_ptr_hi
        cpx     #$0F
        bcs     vert_coll_lookup_uncached
        jsr     lookup_cached_tile
        jmp     vert_coll_process

vert_coll_lookup_uncached:  jsr     lookup_tile_from_map
vert_coll_process:  ldy     temp_00
        lda     tile_solid_lookup_tbl,y ; check if tile is solid
        sta     temp_02
        ldx     current_entity_slot
        sec
        lda     ent_x_px,x
        sbc     temp_01
        sta     jump_ptr
        lda     ent_x_screen,x
        sbc     #$00
        sta     jump_ptr_hi
        cpx     #$0F
        bcs     vert_coll_left_uncached
        jsr     lookup_cached_tile
        jmp     vert_coll_left_process

vert_coll_left_uncached:  jsr     lookup_tile_from_map
vert_coll_left_process:  ldx     current_entity_slot
        ldy     temp_00
        lda     tile_solid_lookup_tbl,y
        ora     temp_02
        sta     temp_00
        beq     vert_coll_no_hit
        plp
        bmi     vert_coll_snap_up
        lda     temp_0A
        and     #$0F
        eor     #$0F
        sec
        adc     ent_y_px,x
        jmp     vert_coll_store_y

vert_coll_snap_up:  lda     ent_y_px,x     ; get entity Y position
        pha
        lda     temp_0A
        and     #$0F
        sta     temp_02
        pla
        sec
        sbc     temp_02
vert_coll_store_y:  sta     ent_y_px,x
        lda     #$00
        sta     ent_y_sub,x
        lda     ent_flags,x
        and     #$04
        beq     vert_coll_done
        lda     #$C0
        sta     ent_y_vel_sub,x
        lda     #$FF
        sta     ent_y_vel,x
vert_coll_done:  rts

vert_coll_no_hit:  plp
        rts

; =============================================================================
; check_horiz_tile_collision — Check horizontal tile collision and snap to surface ($F0CF)
; =============================================================================
check_horiz_tile_collision:  lda     ent_y_px,x ; entity Y position
        sta     temp_0A
        lda     #$00
        sta     temp_0B
        lda     ent_flags,x                 ; check facing direction
        and     #$40                    ; bit 6 = facing right
        php
        beq     horiz_coll_left
        sec
        lda     ent_x_px,x
        adc     temp_01
        sta     jump_ptr
        lda     ent_x_screen,x
        adc     #$00
        jmp     horiz_coll_store_screen

horiz_coll_left:  clc
        lda     ent_x_px,x
        sbc     temp_01
        sta     jump_ptr
        lda     ent_x_screen,x
        sbc     #$00
horiz_coll_store_screen:  sta     jump_ptr_hi
        cpx     #$0F
        bcs     horiz_coll_lookup_uncached
        jsr     lookup_cached_tile
        jmp     horiz_coll_process

horiz_coll_lookup_uncached:  jsr     lookup_tile_from_map
horiz_coll_process:  ldx     current_entity_slot
        ldy     temp_00
        lda     tile_solid_lookup_tbl,y ; check if tile is solid
        sta     temp_03
        beq     horiz_coll_no_hit
        plp
        beq     horiz_coll_snap_right
        lda     jump_ptr
        and     #$0F
        sta     temp_00
        sec
        lda     ent_x_px,x
        sbc     temp_00
        sta     ent_x_px,x
        lda     ent_x_screen,x
        sbc     #$00
        sta     ent_x_screen,x
        jmp     check_vert_tile_collision

horiz_coll_snap_right:  lda     jump_ptr
        and     #$0F
        eor     #$0F
        sec
        adc     ent_x_px,x
        sta     ent_x_px,x
        lda     ent_x_screen,x
        adc     #$00
        sta     ent_x_screen,x
        jmp     check_vert_tile_collision

horiz_coll_no_hit:  plp
        jmp     check_vert_tile_collision

tile_solid_lookup_tbl:  .byte   $00,$01,$00,$01,$00,$01,$01,$01 ; solid flag lookup per tile type
        .byte   $01
; =============================================================================
; spawn_entity_from_parent — Spawn child entity from parent ($F159)
; =============================================================================
; Input: A = child entity type, X = parent slot (current_entity_slot)
; Output: carry clear = success (child slot in X), carry set = no free slot
; Copies parent's position and direction bit 6 to child entity.
; =============================================================================
spawn_entity_from_parent:
        pha
        jsr     find_empty_entity_slot
        bcs     spawn_entity_no_slot
        pla
spawn_entity_init:
        jsr     entity_init_from_type   ; init child in slot X
        txa
        tay                             ; Y = child slot
        ldx     current_entity_slot     ; X = parent slot
; --- Copy parent direction (bit 6) to child spawn flags ---
        lda     ent_flags,x
        and     #$40                    ; parent facing direction
        ora     ent_spawn_flags,y
        sta     ent_spawn_flags,y
; --- Copy parent position to child ---
        lda     ent_x_sub,x
        sta     ent_x_spawn_sub,y
        lda     ent_x_px,x
        sta     ent_x_spawn_px,y
        lda     ent_x_screen,x
        sta     ent_x_spawn_scr,y
        lda     ent_y_sub,x
        sta     ent_y_spawn_sub,y
        lda     ent_y_px,x
        sta     ent_y_spawn_px,y
        clc                             ; carry clear = success
        rts

spawn_entity_no_slot:
        pla
        ldx     current_entity_slot
        sec                             ; carry set = failed
        rts

; =============================================================================
; calc_entity_velocity — Compute velocity vector toward player ($F197)
; =============================================================================
; Input: jump_ptr/jump_ptr_hi = base speed (sub/main), X = entity slot
; Calculates X/Y distances to player, then uses division to compute
; a velocity vector that aims toward the player at the given speed.
;
; Algorithm:
;   1. Compute |delta_x| and |delta_y| between entity and player
;   2. Set entity facing direction toward player (bit 6)
;   3. If |delta_x| > |delta_y|:
;        x_vel = base_speed, y_vel = base_speed * (delta_y / delta_x)
;   4. If |delta_y| >= |delta_x|:
;        y_vel = base_speed, x_vel = base_speed * (delta_x / delta_y)
;   5. Negate Y velocity if player is above entity (PHP/PLP preserves sign)
; =============================================================================
calc_entity_velocity:                   ; bank0E entry point ($F197)
        ldy     #$40                    ; assume facing right (bit 6)
        sec
        lda     player_screen_x
        sbc     current_ent_x
        sta     temp_00                 ; temp_00 = delta_x (signed)
        bcs     @skip                   ; positive = player is to the right
        lda     temp_00
        eor     #$FF                    ; negate: |delta_x|
        adc     #$01
        ldy     #$00                    ; facing left (bit 6 = 0)
        sta     temp_00
@skip:
        lda     ent_flags,x             ; set entity facing direction
        and     #$BF
        sta     ent_flags,x
        tya
        ora     ent_flags,x
        sta     ent_flags,x
        sec
        lda     ent_y_px
        sbc     ent_y_px,x
        php                             ; save sign flag (player above/below)
        bcs     calc_vel_store_delta_y
        eor     #$FF                    ; negate: |delta_y|
        adc     #$01
calc_vel_store_delta_y:
        sta     temp_01                 ; temp_01 = |delta_y|
        cmp     temp_00                 ; compare |delta_y| vs |delta_x|
        bcs     calc_vel_y_greater
; --- |delta_x| > |delta_y|: X is primary axis ---
; x_vel = base_speed, y_vel = base_speed * (delta_y / delta_x)
        lda     jump_ptr_hi
        sta     temp_0D
        sta     ent_x_vel,x            ; X velocity = base speed (main)
        lda     jump_ptr
        sta     temp_0C
        sta     ent_x_vel_sub,x        ; X velocity = base speed (sub)
        lda     temp_00                 ; divisor = |delta_x|
        sta     temp_0B
        lda     #$00
        sta     temp_0A
        jsr     divide_16bit            ; quotient = base_speed / delta_x
        lda     temp_0F                 ; multiply quotient by delta_y:
        sta     temp_0D                 ;   set up second division
        lda     temp_0E
        sta     temp_0C
        lda     temp_01                 ; dividend = |delta_y|
        sta     temp_0B
        lda     #$00
        sta     temp_0A
        jsr     divide_16bit            ; result = base_speed * delta_y / delta_x
        ldx     current_entity_slot
        lda     temp_0F
        sta     ent_y_vel,x            ; Y velocity (main byte)
        lda     temp_0E
        sta     ent_y_vel_sub,x        ; Y velocity (sub-pixel)
        jmp     calc_vel_negate_y

; --- |delta_y| >= |delta_x|: Y is primary axis ---
; y_vel = base_speed, x_vel = base_speed * (delta_x / delta_y)
calc_vel_y_greater:
        lda     jump_ptr_hi
        sta     temp_0D
        sta     ent_y_vel,x            ; Y velocity = base speed (main)
        lda     jump_ptr
        sta     temp_0C
        sta     ent_y_vel_sub,x        ; Y velocity = base speed (sub)
        lda     temp_01                 ; divisor = |delta_y|
        sta     temp_0B
        lda     #$00
        sta     temp_0A
        jsr     divide_16bit            ; quotient = base_speed / delta_y
        lda     temp_0F
        sta     temp_0D
        lda     temp_0E
        sta     temp_0C
        lda     temp_00                 ; dividend = |delta_x|
        sta     temp_0B
        lda     #$00
        sta     temp_0A
        jsr     divide_16bit            ; result = base_speed * delta_x / delta_y
        ldx     current_entity_slot
        lda     temp_0F
        sta     ent_x_vel,x            ; X velocity (main byte)
        lda     temp_0E
        sta     ent_x_vel_sub,x        ; X velocity (sub-pixel)
; --- Negate Y velocity if player is above entity ---
calc_vel_negate_y:
        plp                             ; restore sign from delta_y comparison
        bcc     calc_vel_done           ; carry clear = player below → Y positive
        lda     ent_y_vel_sub,x         ; two's complement 16-bit negate
        eor     #$FF
        adc     #$01
        sta     ent_y_vel_sub,x
        lda     ent_y_vel,x
        eor     #$FF
        adc     #$00
        sta     ent_y_vel,x
calc_vel_done:  rts

; =============================================================================
; item_drop_rng — Random item drop on enemy death ($F25A)
; =============================================================================
item_drop_rng:  lda     boss_phase             ; check boss state (no drops during boss)
        beq     item_drop_calc
        rts

item_drop_calc:  lda     rng_seed            ; read RNG seed
        sta     temp_01
        lda     #$64
        sta     temp_02
        jsr     divide_8bit             ; remainder (0-99) in temp_04
        lda     difficulty                     ; difficulty flag: 0=Normal, 1=Difficult
        beq     item_drop_normal_mode
        ; Difficult mode thresholds (50% total drop rate):
        ;   0-47: nothing (48%), 48-72: small weapon (25%), 73-87: small health (15%)
        ;   88-92: large weapon (5%), 93-96: large health (4%), 97: nothing (1%)
        ;   98: extra life (1%), 99: nothing (1%)
        lda     temp_04
        cmp     #$30
        bcc     item_drop_nothing
        cmp     #$49
        bcc     item_drop_small_weapon
        cmp     #$58
        bcc     item_drop_small_health
        cmp     #$5D
        bcc     item_drop_large_weapon
        cmp     #$61
        bcc     item_drop_large_health
        cmp     #$62
        beq     item_drop_extra_life
item_drop_nothing:  rts

item_drop_small_weapon:  lda     #$79   ; ENTITY_SMALL_WEAPON
        bne     item_drop_spawn
item_drop_small_health:  lda     #$77   ; ENTITY_SMALL_HEALTH
        bne     item_drop_spawn
item_drop_large_weapon:  lda     #$78   ; ENTITY_LARGE_WEAPON
        bne     item_drop_spawn
item_drop_large_health:  lda     #$76   ; ENTITY_LARGE_HEALTH
        bne     item_drop_spawn
item_drop_extra_life:  lda     #$7B
        bne     item_drop_spawn
        lda     #$7A                    ; (unreachable: E-Tank drop, never rolled)
        bne     item_drop_spawn
item_drop_spawn:  jsr     spawn_entity_from_parent
        bcs     item_drop_failed
        lda     #$84
        sta     ent_spawn_flags,y
        lda     #$02
        sta     ent_hitbox_h_lo,y
        lda     #$01
        sta     ent_drop_flag,y
item_drop_failed:  rts

        ; Normal mode thresholds (71% total drop rate):
        ;   0-27: nothing (28%), 28-37: small weapon (10%), 38-47: small health (10%)
        ;   48-77: large weapon (30%), 78-97: large health (20%), 98: nothing (1%)
        ;   99: extra life (1%)
item_drop_normal_mode:  lda     temp_04
        cmp     #$1C
        bcc     item_drop_nothing
        cmp     #$26
        bcc     item_drop_small_weapon
        cmp     #$30
        bcc     item_drop_small_health
        cmp     #$4E
        bcc     item_drop_large_weapon
        cmp     #$62
        bcc     item_drop_large_health
        cmp     #$63
        beq     item_drop_extra_life
        rts


; =============================================================================
; Initialization
; =============================================================================
cold_boot_init:                         ; Cold boot: init PPU, switch to bank $0E, start game
        lda     #$10                    ; NMI enable, bg pattern $1000
        sta     PPUCTRL                   ; PPUCTRL
        lda     #$06                    ; Show bg+sprites on left edge
        sta     PPUMASK                   ; PPUMASK
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
        .byte   $93,$93,$09,$0A,$22,$20,$20,$1F
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
reset_mmc1_shift:  inc     reset_mmc1_shift                   ; Dummy ROM write with bit 7 set resets MMC1 shift register
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
