; =============================================================================
; Mega Man 2 — RAM Definitions (Entity Arrays + Buffers)
; =============================================================================
; Entity arrays are indexed by slot (X register), 16 slots $00-$0F.
; Slots $00-$0F: player/weapons ($00-$0F), enemies ($10-$1F).

; ─── Entity Arrays (page $01) ──────────────────────────────────────────────
; These share the 6502 stack page ($0100-$01FF). Safe because the game
; uses very little stack depth; entity slots $00-$0F occupy $0100-$017F.
ent_hit_count       = $0100  ; collision hit guard — prevents multi-hit same frame ($0100,x)
ent_parent_slot     = $0110  ; parent entity slot index for child despawn ($0110,x)
ent_despawn         = $0120  ; despawn marker ($FF=despawned) / spawn type ($0120,x)
ent_parent_ref      = $0130  ; secondary spawn duplicate guard ($0130,x)
ent_child_hp        = $0140  ; secondary entity HP/timer ($0140,x)
ent_plat_height     = $0150  ; platform collision height ($0150,x)
ent_plat_y          = $0160  ; platform collision Y offset ($0160,x)
ent_plat_type       = $0170  ; platform type reference ($0170,x)

; ─── Entity Arrays (page $04+) ─────────────────────────────────────────────
ent_type            = $0400  ; entity type ID ($0400,x)
ent_spawn_type      = $0410  ; spawn type from stage data ($0410,x)
ent_flags           = $0420  ; entity flags ($0420,x) — bit 7=active, 6=facing, 5=priority
ent_spawn_flags     = $0430  ; secondary spawn flags ($0430,x)
ent_x_screen        = $0440  ; X position screen/page ($0440,x)
ent_x_spawn_scr     = $0450  ; X screen from spawn data ($0450,x)
ent_x_px            = $0460  ; X position pixel ($0460,x)
ent_x_spawn_px      = $0470  ; X pixel from spawn data ($0470,x)
ent_x_sub           = $0480  ; X sub-pixel ($0480,x)
ent_y_px            = $04A0  ; Y position pixel ($04A0,x)
ent_y_spawn_px      = $04B0  ; Y pixel from spawn data ($04B0,x)
ent_y_sub           = $04C0  ; Y sub-pixel ($04C0,x)
ent_state           = $04E0  ; AI state / timer ($04E0,x)
ent_x_vel           = $0600  ; X velocity whole, signed ($0600,x)
ent_x_vel_sub       = $0620  ; X velocity sub-pixel ($0620,x)
ent_y_vel           = $0640  ; Y velocity whole, signed ($0640,x)
ent_y_vel_sub       = $0660  ; Y velocity sub-pixel ($0660,x)
ent_anim_frame      = $0680  ; animation frame counter ($0680,x)
ent_anim_backup     = $0690  ; animation state backup ($0690,x)
ent_anim_id         = $06A0  ; animation sequence index ($06A0,x)
ent_misc            = $06B0  ; general-purpose entity variable ($06B0,x)
ent_hp              = $06C0  ; hit points ($06C0,x — player=$06C0, boss=$06C1)

; ─── Entity Arrays (extended) ─────────────────────────────────────────────
ent_x_spawn_sub     = $0490  ; spawn X sub-pixel ($0490,x)
ent_y_spawn_sub     = $04D0  ; spawn Y sub-pixel ($04D0,x)
ent_drop_flag       = $04F0  ; item drop / spawn parameter ($04F0,x)
ent_weapon_type     = $0590  ; weapon/damage type ($0590,x)
ent_hitbox_width    = $059E  ; hitbox width for collision ($059E,x)
ent_hitbox_w_lo     = $0610  ; hitbox width mask low ($0610,x)
ent_hitbox_w_hi     = $0630  ; hitbox width mask high ($0630,x)
ent_hitbox_h_lo     = $0650  ; hitbox height mask low ($0650,x)
ent_hitbox_h_hi     = $0670  ; hitbox height mask high ($0670,x)
ent_timer           = $06D0  ; entity timer / countdown ($06D0,x)
ent_screen_x        = $06E0  ; screen-relative X position ($06E0,x)
ent_ai_behavior     = $06F0  ; AI behavior table index ($06F0,x)

; ─── Boss Entity (Slot $01) ─────────────────────────────────────────────────
; Direct (non-indexed) access to entity slot $01, the boss during boss fights.
; Also reused for ending scene protagonist animation.
boss_type           = ent_type + 1        ; $0401
boss_flags          = ent_flags + 1       ; $0421 — bit 7=active, 6=facing
boss_x_screen       = ent_x_screen + 1    ; $0441
boss_x_px           = ent_x_px + 1        ; $0461
boss_x_sub          = ent_x_sub + 1       ; $0481
boss_y_px           = ent_y_px + 1        ; $04A1
boss_y_sub          = ent_y_sub + 1       ; $04C1
boss_ai_state       = ent_state + 1       ; $04E1 — AI sub-state counter
boss_x_vel          = ent_x_vel + 1       ; $0601
boss_x_vel_sub      = ent_x_vel_sub + 1   ; $0621
boss_y_vel          = ent_y_vel + 1       ; $0641
boss_y_vel_sub      = ent_y_vel_sub + 1   ; $0661
boss_anim_frame     = ent_anim_frame + 1  ; $0681
boss_anim_id        = ent_anim_id + 1     ; $06A1
boss_hp             = ent_hp + 1          ; $06C1
boss_screen_x       = ent_screen_x + 1    ; $06E1

; ─── Boss State (non-entity-array) ─────────────────────────────────────────
boss_spawn_timer    = $05A6  ; boss spawn/intro countdown timer
boss_hit_timer      = $05A8  ; boss hit stun timer (set to $12 on hit, decrements)
boss_hit_count      = $05AA  ; weapon hit counter (inc per hit in boss_check_weapon_hit)

; ─── RAM Buffers ────────────────────────────────────────────────────────────
oam_buffer          = $0200  ; OAM sprite buffer, 256 bytes ($0200-$02FF)
ppu_update_buf      = $0300  ; PPU nametable update buffer ($0300)
palette_anim_target = $0354  ; palette animation target frame ($0354)
palette_anim_counter = $0355 ; palette animation current frame ($0355)
palette_ram         = $0356  ; palette mirror, 32 bytes ($0356-$0375 → $3F00)
palette_sprite      = $0366  ; sprite palette 0 base ($0366 = palette_ram+$10 → $3F10)
col_update_addr_hi  = $03B6  ; column update VRAM addr high ($03B6)
col_update_addr_lo  = $03B7  ; column update VRAM addr low ($03B7)
col_update_tiles    = $03B8  ; column update tile data, 32 bytes ($03B8-$03D7)
