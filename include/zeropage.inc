; =============================================================================
; Mega Man 2 — Zero Page Variable Definitions
; =============================================================================
; Confirmed from fixed bank (bank0F) analysis and Mesen tracing.
; High-confidence names only — uncertain addresses left as raw hex.

; ─── General purpose temporaries ────────────────────────────────────────────
temp_00               = $00    ; general scratch ($00)
temp_01               = $01    ; general scratch ($01)
temp_02               = $02    ; general scratch ($02)
temp_03               = $03    ; general scratch ($03)
temp_04               = $04    ; general scratch / game state index ($04)
temp_05               = $05    ; general scratch ($05)
temp_06               = $06    ; general scratch ($06)
temp_07               = $07    ; general scratch ($07)

; ─── Indirect jump pointer ──────────────────────────────────────────────────
jump_ptr              = $08    ; jump table pointer low ($08) — jmp ($0008)
jump_ptr_hi           = $09    ; jump table pointer high ($09)

; ─── Extended temporaries / pointer pairs ───────────────────────────────────
temp_0A               = $0A    ; general scratch / pointer low ($0A)
temp_0B               = $0B    ; general scratch / pointer high ($0B)
temp_0C               = $0C    ; general scratch / pointer low ($0C)
temp_0D               = $0D    ; general scratch / pointer high ($0D)
temp_0E               = $0E    ; general scratch / pointer low ($0E)
temp_0F               = $0F    ; general scratch / pointer high ($0F)
temp_10               = $10    ; division remainder low ($10)
temp_11               = $11    ; division remainder high ($11)

; ─── Scroll / Camera ───────────────────────────────────────────────────────
scroll_screen_lo      = $14    ; left boundary nametable index for current room ($14)
scroll_screen_hi      = $15    ; right boundary nametable index for current room ($15)
metatile_ptr_lo       = $16    ; 16-bit pointer into metatile column data, low ($16)
metatile_ptr_hi       = $17    ; 16-bit pointer into metatile column data, high ($17)
column_ptr_lo         = $18    ; 16-bit pointer into column tile buffer, low ($18)
column_ptr_hi         = $19    ; 16-bit pointer into column tile buffer, high ($19)
column_index          = $1A    ; current tile column counter, wraps mod 64 ($1A)
scroll_subpixel       = $1E    ; scroll sub-pixel accumulator, cleared at boundaries ($1E)
scroll_y_page         = $21    ; scroll Y page / nametable vertical bit ($21)
transition_type       = $37    ; room transition request: 0=none, bit0=vertical, $03=boss ($37)
current_screen        = $38    ; current room/screen index within stage ($38)

; ─── PPU / Rendering ────────────────────────────────────────────────────────
ppu_buffer_count      = $1B    ; PPU buffer entry count ($1B)
frame_counter         = $1C    ; frame counter, incremented every NMI ($1C)
vblank_done           = $1D    ; VBLANK completion flag ($1D)
scroll_x              = $1F    ; horizontal scroll position ($1F)
nametable_select      = $20    ; active nametable, bit 0 ($20)
scroll_y              = $22    ; vertical scroll position ($22)

; ─── Controller Input ───────────────────────────────────────────────────────
controller_1          = $23    ; P1 buttons ($23) — A=$80 B=$40 Sel=$20 Start=$10 U=$08 D=$04 L=$02 R=$01
controller_2          = $24    ; P2 buttons ($24)
p1_prev_buttons       = $25    ; P1 previous frame buttons ($25)
p2_prev_buttons       = $26    ; P2 previous frame buttons ($26)
p1_new_presses        = $27    ; P1 newly pressed this frame ($27)
p2_new_presses        = $28    ; P2 newly pressed this frame ($28)

; ─── Game State ─────────────────────────────────────────────────────────────
current_bank          = $29    ; currently switched PRG bank ($29)
current_stage         = $2A    ; stage index 0-13 ($2A)
current_entity_slot   = $2B    ; entity slot being processed ($2B)
game_substate         = $2C    ; game sub-state / weapon select state ($2C)

; ─── Entity AI Context (per-frame scratch) ──────────────────────────────────
player_screen_x       = $2D    ; player X position relative to camera ($2D)
current_ent_x         = $2E    ; current entity X relative to camera ($2E)
offscreen_flag        = $2F    ; entity off-screen flag ($2F)

; ─── Player Physics ─────────────────────────────────────────────────────────
gravity_sub_lo        = $30    ; gravity sub-pixel accumulator low ($30)
gravity_sub_hi        = $31    ; gravity sub-pixel accumulator high ($31)
floor_tile_type       = $32    ; tile type from floor collision check ($32)
floor_collision_result = $33   ; combined floor collision result bits ($33)
is_on_ground          = $35    ; solid ground detection flag ($35)
general_timer         = $36    ; general-purpose timer / counter ($36)
column_attr_byte      = $39    ; metatile column attribute / scroll counter ($39)
palette_dirty         = $3A    ; palette dirty flag — nonzero triggers upload ($3A)
player_jump_sub       = $3B    ; player jump velocity sub / scroll bounds ($3B)
player_jump_hi        = $3C    ; player jump velocity high / scroll speed ($3C)
weapon_fire_dir       = $3D    ; weapon firing direction offset ($3D)
max_speed_sub         = $3E    ; max speed sub-pixel (acceleration cache) ($3E)
max_speed_hi          = $3F    ; max speed high byte ($3F)

; ─── Platform / Conveyor / Palette ──────────────────────────────────────────
conveyor_type         = $40    ; platform/conveyor type from floor eval ($40)
sound_pause_flag      = $41    ; sound engine pause flag — bit0 silences all channels ($41)
scroll_dir_flags      = $42    ; scroll direction flags ($42)
palette_cycle_idx     = $43    ; palette animation cycle index ($43)
palette_cycle_timer   = $44    ; palette animation cycle timer ($44)
palette_toggle_a      = $45    ; palette animation toggle A ($45)
palette_toggle_b      = $46    ; palette animation toggle B ($46)

; ─── PPU Column / Attribute Update ─────────────────────────────────────────
col_update_count      = $47    ; PPU column tile write pending count, 0=done ($47)
attr_update_count     = $51    ; PPU attribute write pending count, bit7=fill mode ($51)
attr_update_mode      = $54    ; attribute merge mode: 0=overwrite, nonzero=read-modify-write ($54)

; ─── Entity Spawn Scanning ──────────────────────────────────────────────────
spawn_scan_bwd        = $48    ; entity spawn scan backward index ($48)
spawn_scan_fwd        = $49    ; entity spawn scan forward index ($49)
spawn_scan_sec_bwd    = $4C    ; secondary spawn scan backward index ($4C)
spawn_scan_sec_fwd    = $4D    ; secondary spawn scan forward index ($4D)
death_context         = $4E    ; death/despawn context flag ($4E)
scroll_lock_lo        = $4F    ; scroll lock / conveyor velocity sub ($4F)
scroll_lock_hi        = $50    ; scroll lock / conveyor velocity high ($50)
wselect_ppu_lo        = $52    ; weapon select PPU address low ($52)
wselect_ppu_hi        = $53    ; weapon select PPU address high ($53)

; ─── Misc ───────────────────────────────────────────────────────────────────
rng_seed              = $4A    ; random number generator ($4A)
invincibility_timer   = $4B    ; player i-frames countdown ($4B)
active_entity_count   = $55    ; active entity count for collision scan ($55)
active_entity_list    = $56    ; active entity slot list base ($56+)

; ─── Bank Switching ─────────────────────────────────────────────────────────
bank_queue_count      = $66    ; bank switch queue count ($66)
bank_callback_pending = $67    ; bank switch callback pending flag ($67)
bank_switch_active    = $68    ; bank switch in-progress flag ($68)
bank_switch_backup    = $69    ; bank switch backup (original bank number) ($69)

; ─── Boss / Game Progression ────────────────────────────────────────────────
beaten_bosses         = $9A    ; boss beaten bitmask low ($9A)
beaten_bosses_hi      = $9B    ; boss beaten bitmask high / complement ($9B)
weapon_ammo           = $9C    ; weapon ammo array, 4+ bytes ($9C-$9F)
weapon_energy         = $A0    ; weapon/item energy array ($A0-$A6)

; ─── Player State ───────────────────────────────────────────────────────────
current_etanks        = $A7    ; E-tank count ($A7)
current_lives         = $A8    ; lives remaining ($A8)
current_weapon        = $A9    ; selected weapon ID ($A9)

; ─── Boss Battle State ────────────────────────────────────────────────────
game_mode             = $AA    ; game mode / entity dispatch flag ($AA) — 0=normal, bit2=pause entities
weapon_counter_1      = $AB    ; weapon-specific counter 1 ($AB)
weapon_counter_2      = $AC    ; weapon-specific counter 2 ($AC)
weapon_counter_3      = $AD    ; weapon-specific counter 3 ($AD)
sprite_8x16_flag      = $AE    ; 8×16 sprite size flag ($AE)
platform_facing       = $AF    ; platform/conveyor facing direction bit 6 ($AF)
score_rank_idx        = $B0    ; score/rank index ($B0)
boss_phase            = $B1    ; boss fight phase counter ($B1) — inc/dec to advance boss AI state
boss_action_timer     = $B2    ; boss action timer ($B2) — countdown/up for boss attack timing
boss_id               = $B3    ; boss index ($B3) — indexes into boss property tables
boss_hit_flag         = $B4    ; boss weapon hit flag — incremented per hit ($B4)
camera_y_sub          = $B5    ; camera Y offset sub-pixel ($B5)

; ─── Camera Offsets (screen shake) ─────────────────────────────────────────
camera_y_offset       = $B6    ; camera Y offset, subtracted from scroll_y in NMI ($B6)
camera_x_sub          = $B7    ; camera X offset sub-pixel ($B7)
camera_x_offset       = $B8    ; camera X offset low, subtracted from scroll_x in NMI ($B8)
camera_x_offset_hi    = $B9    ; camera X offset high ($B9)
wily_stage_index      = $BA    ; Wily fortress stage index, 1-based ($BA)
boss_mode_flag        = $BC    ; boss mode / sound state flag ($BC)
boss_state_flag       = $BD    ; boss-specific state flag ($BD)
ending_state          = $BE    ; ending sequence state ($BE)

; ─── Ending / Weapon-Get ────────────────────────────────────────────────────
ending_timer_lo       = $C0    ; ending timer low byte ($C0)
ending_timer_hi       = $C1    ; ending timer high byte ($C1)
indirect_page         = $C8    ; indirect data page offset ($C8)
indirect_ptr_lo       = $C9    ; indirect data pointer low ($C9)
indirect_ptr_hi       = $CA    ; indirect data pointer high ($CA)
difficulty            = $CB    ; difficulty flag: 0=Normal, 1=Difficult ($CB)

; ─── Weapon/Sound Engine (bank0C only) ──────────────────────────────────────
weapon_select_state   = $E0    ; weapon selection state — packed nibbles ($E0)
weapon_display_bits   = $E1    ; weapon slot active/visible bit flags ($E1)
weapon_data_lo        = $E2    ; weapon definition data pointer low ($E2)
weapon_data_hi        = $E3    ; weapon definition data pointer high ($E3)
sound_busy_flag       = $E4    ; sound engine busy flag ($E4)
slot_counter          = $E5    ; weapon slot loop counter, counts down from 4 ($E5)
slot_tile_offset      = $E6    ; weapon slot tile X offset ($E6)
frame_repeat_count    = $E7    ; sound note repeat counter ($E7)
lives_timer           = $E8    ; lives display timer / password flag ($E8)
lives_animate_timer   = $E9    ; lives display animation counter ($E9)
sound_frame_counter   = $EA    ; sound engine frame counter ($EA)
apu_channel_offset    = $EB    ; APU register offset (0/4/8/12) ($EB)
sound_slot_lo         = $EC    ; sound channel state pointer low ($EC)
sound_slot_hi         = $ED    ; sound channel state pointer high ($ED)
active_channel_count  = $EE    ; remaining channels to process ($EE)
channel_active_flags  = $EF    ; per-channel active status bits ($EF)
sound_stream_lo       = $F0    ; sound stream read pointer low ($F0)
sound_stream_hi       = $F1    ; sound stream read pointer high ($F1)
instrument_type       = $F2    ; instrument ID / refill timer ($F2)
stream_update_flag    = $F3    ; stream pointer update tracker ($F3)
freq_register_hi      = $F5    ; APU frequency hi-byte / temp pointer ($F5)

; ─── Engine Temporaries ─────────────────────────────────────────────────────
ppuctrl_shadow        = $F7    ; PPUCTRL mirror ($F7)
ppumask_shadow        = $F8    ; PPUMASK mirror ($F8)
boss_fight_flag       = $F9    ; boss fight active flag ($F9)
frame_skip_lo         = $FB    ; frame skip timer low ($FB)
frame_skip_hi         = $FC    ; frame skip timer high ($FC)
general_counter       = $FD    ; general-purpose counter / column index ($FD)
general_ptr_lo        = $FE    ; general-purpose pointer low ($FE)
general_ptr_hi        = $FF    ; general-purpose pointer high ($FF)
