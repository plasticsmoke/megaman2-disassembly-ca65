; =============================================================================
; NSFe Container — Mega Man 2 Soundtrack
; =============================================================================
; Pure ca65 assembly NSFe builder.  Includes the pre-assembled sound engine
; PRG binary (bank $0C + NSF shim) and wraps it in NSFe chunk format.
;
; Built entirely from source — no ROM extraction, no external scripts.
;
; NSFe spec: each chunk is [4-byte LE size][4-byte FourCC][data...].
; Required chunks: INFO, DATA, NEND.  Optional: rate, auth, time, fade, tlbl.
;
; Sound engine architecture:
;   Bank $0C ($8000-$BFFF, 16 KB) contains the complete sound driver and all
;   music/instrument data.  It is fully self-contained — no other ROM banks
;   are needed for music playback.  The NSF shim ($C000+) provides init/play
;   entry points that bridge the NSFe player interface to bank $0C's internal
;   dispatch (weapon_select_handler doubles as the music loader).
; =============================================================================

.segment "NSFE"

; =============================================================================
; NSFe magic
; =============================================================================
.byte   "NSFE"

; =============================================================================
; INFO chunk (10 bytes)
; =============================================================================
; Load:  $8000 (start of bank $0C — sound engine)
; Init:  $C000 (nsf_init — reset engine, map track, dispatch)
; Play:  $C020 (nsf_play — per-frame sound_update_main + trigger)
; =============================================================================
.dword  10
.byte   "INFO"
.word   $8000                   ; load address
.word   $C000                   ; init address (nsf_init in shim)
.word   $C020                   ; play address (nsf_play in shim)
.byte   $00                     ; NTSC only
.byte   $00                     ; no expansion sound
.byte   53                      ; total songs (tracks 0-52: 24 music + 29 SFX)
.byte   $00                     ; starting song (0-based)

; =============================================================================
; DATA chunk (20480 bytes)
; =============================================================================
; Bank $0C (sound engine, 16 KB) + NSF shim (4 KB fill).
; The shim occupies ~200 bytes at $C000; the rest is zero-filled by the linker.
; =============================================================================
.dword  20480
.byte   "DATA"
.incbin "build/nsfe_prg.bin", 0, 20480

; =============================================================================
; rate chunk (4 bytes) — NTSC play speed
; =============================================================================
.dword  4
.byte   "rate"
.word   16666                   ; NTSC microseconds/frame (~60.0 Hz)
.word   0                       ; PAL (unused)

; =============================================================================
; auth chunk — title, artist, copyright, ripper
; =============================================================================
; Composers (VGMPF / Mega Man Wiki):
;   Takashi Tateishi ("Ogeretsu") — majority of soundtrack
;   Manami Matsumae ("Chanchacorin") — Opening, Ending (credited in-game)
; =============================================================================
.dword  auth_end - auth_start
.byte   "auth"
auth_start:
.byte   "Mega Man 2", 0
.byte   "Takashi Tateishi, Manami Matsumae", 0
.byte   "1988, 1989 Capcom", 0
.byte   "ca65 disassembly rip, 2026", 0
auth_end:

; =============================================================================
; time chunk — per-track duration in milliseconds (signed 32-bit)
; =============================================================================
; Music: looping tracks use intro + 2×loop; one-shot tracks use total duration.
; SFX: estimated playback length (most are short one-shots).
; =============================================================================
.dword  time_end - time_start
.byte   "time"
time_start:
.dword   39300                  ;  0: $0E Opening (0:39, one-shot)
.dword   43000                  ;  1: $0D Title (0:43, 1 loop)
.dword   21000                  ;  2: $10 Password (0:07+0:07 ×2)
.dword   19000                  ;  3: $0C Stage Select (0:07+0:06 ×2)
.dword    8000                  ;  4: $0A Stage Intro (0:08, one-shot)
.dword   91000                  ;  5: $03 Heat Man Stage (0:39+0:26 ×2)
.dword  138000                  ;  6: $04 Air Man Stage (0:46+0:46 ×2)
.dword  104000                  ;  7: $01 Wood Man Stage (0:40+0:32 ×2)
.dword  107000                  ;  8: $07 Bubble Man Stage (0:43+0:32 ×2)
.dword  117000                  ;  9: $06 Quick Man Stage (0:39+0:39 ×2)
.dword  116000                  ; 10: $00 Flash Man Stage (1:04+0:26 ×2)
.dword  117000                  ; 11: $05 Metal Man Stage (0:39+0:39 ×2)
.dword  218000                  ; 12: $02 Crash Man Stage (1:30+1:04 ×2)
.dword    6000                  ; 13: $15 Stage Clear (0:06, one-shot)
.dword   36000                  ; 14: $17 Weapon Upgrade (0:30+0:03 ×2)
.dword    8000                  ; 15: $11 Dr. Wily Map (0:08, one-shot)
.dword  225000                  ; 16: $08 Dr. Wily Stage 1 (1:15+1:15 ×2)
.dword  231000                  ; 17: $09 Dr. Wily Stage 2 (1:17+1:17 ×2)
.dword   46000                  ; 18: $0B Boss (0:20+0:13 ×2)
.dword    8000                  ; 19: $16 Wily Defeated (0:08, one-shot)
.dword   70000                  ; 20: $13 Epilogue (1:10, loops)
.dword   43000                  ; 21: $0D Ending / Title Repeat (0:43, non-looping)
.dword   66000                  ; 22: $14 Credits (1:06, one-shot)
.dword    3000                  ; 23: $0F Game Over (0:03, one-shot)
; ─── Sound Effects ──────────────────────────────────────────────────────
.dword    1000                  ; 24: $2F Menu Cursor
.dword    2000                  ; 25: $29 Landing
.dword    2000                  ; 26: $26 Damage Recoil
.dword    2000                  ; 27: $24 Mega Buster
.dword    2000                  ; 28: $2B Damage Hit
.dword    2000                  ; 29: $2D Deflect
.dword    2000                  ; 30: $42 Extra Life
.dword    2000                  ; 31: $28 Health Tick
.dword    3000                  ; 32: $35 Skew 1
.dword    3000                  ; 33: $36 Skew 2
.dword    3000                  ; 34: $37 Skew 3
.dword    3000                  ; 35: $30 Teleport In
.dword    2000                  ; 36: $3A Teleport Out
.dword    2000                  ; 37: $38 Heat Charge
.dword    3000                  ; 38: $3F Air Shooter
.dword    6000                  ; 39: $31 Leaf Shield Orbit
.dword    2000                  ; 40: $21 Time Stopper
.dword    2000                  ; 41: $23 Metal Blade
.dword    2000                  ; 42: $2E Crash Bomb Stick
.dword    4000                  ; 43: $41 Death Explosion
.dword    2000                  ; 44: $25 Enemy Shot
.dword    2000                  ; 45: $39 Enemy Bounce
.dword    2000                  ; 46: $27 Quick Man Laser
.dword    2000                  ; 47: $3B Water Splash
.dword    2000                  ; 48: $3C Block Appear
.dword    2000                  ; 49: $2A Wily Alarm
.dword    3000                  ; 50: $2C Dragon Fire
.dword    2000                  ; 51: $3D Acid Drip 1
.dword    2000                  ; 52: $3E Acid Drip 2
time_end:

; =============================================================================
; fade chunk — per-track fade-out in milliseconds (signed 32-bit)
; =============================================================================
; Looping music: 5s fade.  One-shot jingles/SFX: no fade (0).
; =============================================================================
.dword  fade_end - fade_start
.byte   "fade"
fade_start:
.dword      0                   ;  0: $0E Opening (one-shot)
.dword      0                   ;  1: $0D Title (1 loop, clean stop)
.dword   5000                   ;  2: $10 Password (loops)
.dword   5000                   ;  3: $0C Stage Select (loops)
.dword      0                   ;  4: $0A Stage Intro (one-shot)
.dword   5000                   ;  5: $03 Heat Man Stage (loops)
.dword   5000                   ;  6: $04 Air Man Stage (loops)
.dword   5000                   ;  7: $01 Wood Man Stage (loops)
.dword   5000                   ;  8: $07 Bubble Man Stage (loops)
.dword   5000                   ;  9: $06 Quick Man Stage (loops)
.dword   5000                   ; 10: $00 Flash Man Stage (loops)
.dword   5000                   ; 11: $05 Metal Man Stage (loops)
.dword   5000                   ; 12: $02 Crash Man Stage (loops)
.dword      0                   ; 13: $15 Stage Clear (one-shot)
.dword   5000                   ; 14: $17 Weapon Upgrade (loops)
.dword      0                   ; 15: $11 Dr. Wily Map (one-shot)
.dword   5000                   ; 16: $08 Dr. Wily Stage 1 (loops)
.dword   5000                   ; 17: $09 Dr. Wily Stage 2 (loops)
.dword   5000                   ; 18: $0B Boss (loops)
.dword      0                   ; 19: $16 Wily Defeated (one-shot)
.dword      0                   ; 20: $13 Epilogue (clean stop)
.dword      0                   ; 21: $0D Ending / Title Repeat (non-looping)
.dword      0                   ; 22: $14 Credits (one-shot)
.dword      0                   ; 23: $0F Game Over (one-shot)
; ─── Sound Effects (all one-shot, no fade) ──────────────────────────────
.dword      0                   ; 24: $2F Menu Cursor
.dword      0                   ; 25: $29 Landing
.dword      0                   ; 26: $26 Damage Recoil
.dword      0                   ; 27: $24 Mega Buster
.dword      0                   ; 28: $2B Damage Hit
.dword      0                   ; 29: $2D Deflect
.dword      0                   ; 30: $42 Extra Life
.dword      0                   ; 31: $28 Health Tick
.dword      0                   ; 32: $35 Skew 1
.dword      0                   ; 33: $36 Skew 2
.dword      0                   ; 34: $37 Skew 3
.dword      0                   ; 35: $30 Teleport In
.dword      0                   ; 36: $3A Teleport Out
.dword      0                   ; 37: $38 Heat Charge
.dword      0                   ; 38: $3F Air Shooter
.dword      0                   ; 39: $31 Leaf Shield Orbit
.dword      0                   ; 40: $21 Time Stopper
.dword      0                   ; 41: $23 Metal Blade
.dword      0                   ; 42: $2E Crash Bomb Stick
.dword      0                   ; 43: $41 Death Explosion
.dword      0                   ; 44: $25 Enemy Shot
.dword      0                   ; 45: $39 Enemy Bounce
.dword      0                   ; 46: $27 Quick Man Laser
.dword      0                   ; 47: $3B Water Splash
.dword      0                   ; 48: $3C Block Appear
.dword      0                   ; 49: $2A Wily Alarm
.dword      0                   ; 50: $2C Dragon Fire
.dword      0                   ; 51: $3D Acid Drip 1
.dword      0                   ; 52: $3E Acid Drip 2
fade_end:

; =============================================================================
; tlbl chunk — per-track labels (null-terminated strings)
; =============================================================================
; Music names from code context and VGMRips.
; SFX names verified against in-game playback.
;
; Sound IDs $00-$07 map to stage themes via stage_bank_table in bank $0E.
; Sound IDs $08-$09 map to Wily stages via the same table.
; Sound IDs $0A-$17 are UI/jingle/ending music triggered directly.
; Sound IDs $21-$42 are sound effects dispatched via bank_switch_enqueue.
; =============================================================================
.dword  tlbl_end - tlbl_start
.byte   "tlbl"
tlbl_start:
.byte   "Opening", 0                            ;  0: $0E
.byte   "Title", 0                              ;  1: $0D
.byte   "Password", 0                           ;  2: $10
.byte   "Stage Select", 0                       ;  3: $0C
.byte   "Stage Intro", 0                        ;  4: $0A
.byte   "Heat Man Stage", 0                     ;  5: $03
.byte   "Air Man Stage", 0                      ;  6: $04
.byte   "Wood Man Stage", 0                     ;  7: $01
.byte   "Bubble Man Stage", 0                   ;  8: $07
.byte   "Quick Man Stage", 0                    ;  9: $06
.byte   "Flash Man Stage", 0                    ; 10: $00
.byte   "Metal Man Stage", 0                    ; 11: $05
.byte   "Crash Man Stage", 0                    ; 12: $02
.byte   "Stage Clear", 0                        ; 13: $15
.byte   "Weapon Upgrade", 0                     ; 14: $17
.byte   "Dr. Wily Map", 0                       ; 15: $11
.byte   "Dr. Wily Stage 1", 0                   ; 16: $08
.byte   "Dr. Wily Stage 2", 0                   ; 17: $09
.byte   "Boss", 0                               ; 18: $0B
.byte   "Wily Defeated", 0                      ; 19: $16
.byte   "Epilogue", 0                           ; 20: $13
.byte   "Ending (Title Repeat)", 0               ; 21: $0D
.byte   "Credits", 0                            ; 22: $14
.byte   "Game Over", 0                          ; 23: $0F
; ─── Sound Effects ──────────────────────────────────────────────────────
.byte   "Menu Cursor", 0                        ; 24: $2F
.byte   "Landing", 0                            ; 25: $29
.byte   "Damage Recoil", 0                      ; 26: $26
.byte   "Mega Buster", 0                        ; 27: $24
.byte   "Damage Hit", 0                         ; 28: $2B
.byte   "Deflect", 0                            ; 29: $2D
.byte   "Extra Life", 0                         ; 30: $42
.byte   "Health Tick", 0                        ; 31: $28
.byte   "Skew 1", 0                             ; 32: $35
.byte   "Skew 2", 0                             ; 33: $36
.byte   "Skew 3", 0                             ; 34: $37
.byte   "Teleport In", 0                        ; 35: $30
.byte   "Teleport Out", 0                       ; 36: $3A
.byte   "Heat Charge", 0                        ; 37: $38
.byte   "Air Shooter", 0                        ; 38: $3F
.byte   "Leaf Shield Orbit", 0                  ; 39: $31
.byte   "Time Stopper", 0                       ; 40: $21
.byte   "Metal Blade", 0                        ; 41: $23
.byte   "Crash Bomb Stick", 0                   ; 42: $2E
.byte   "Death Explosion", 0                    ; 43: $41
.byte   "Enemy Shot", 0                         ; 44: $25
.byte   "Enemy Bounce", 0                       ; 45: $39
.byte   "Quick Man Laser", 0                    ; 46: $27
.byte   "Water Splash", 0                       ; 47: $3B
.byte   "Block Appear", 0                       ; 48: $3C
.byte   "Wily Alarm", 0                         ; 49: $2A
.byte   "Dragon Fire", 0                        ; 50: $2C
.byte   "Acid Drip 1", 0                        ; 51: $3D
.byte   "Acid Drip 2", 0                        ; 52: $3E
tlbl_end:

; =============================================================================
; NEND terminator
; =============================================================================
.dword  0
.byte   "NEND"
