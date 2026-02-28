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
.byte   24                      ; total songs (tracks 0-23)
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
; Durations from VGMRips (intro+loop format).
; Looping tracks: intro + 2×loop (two full loops before fade).
; One-shot tracks: total duration (no repeat).
; =============================================================================
.dword  time_end - time_start
.byte   "time"
time_start:
.dword   41000                  ;  0: $0E Opening (0:41, one-shot)
.dword   86000                  ;  1: $0D Title (0:43 loop ×2)
.dword  116000                  ;  2: $00 Flash Man Stage (1:04+0:26 ×2)
.dword  104000                  ;  3: $01 Wood Man Stage (0:40+0:32 ×2)
.dword  218000                  ;  4: $02 Crash Man Stage (1:30+1:04 ×2)
.dword   91000                  ;  5: $03 Heat Man Stage (0:39+0:26 ×2)
.dword  138000                  ;  6: $04 Air Man Stage (0:46+0:46 ×2)
.dword  117000                  ;  7: $05 Metal Man Stage (0:39+0:39 ×2)
.dword  117000                  ;  8: $06 Quick Man Stage (0:39+0:39 ×2)
.dword  107000                  ;  9: $07 Bubble Man Stage (0:43+0:32 ×2)
.dword  225000                  ; 10: $08 Dr. Wily Stage 1 (1:15+1:15 ×2)
.dword  231000                  ; 11: $09 Dr. Wily Stage 2 (1:17+1:17 ×2)
.dword   36000                  ; 12: $17 Last Stage (0:30+0:03 ×2)
.dword   21000                  ; 13: $10 Password (0:07+0:07 ×2)
.dword   19000                  ; 14: $0C Stage Select (0:07+0:06 ×2)
.dword    8000                  ; 15: $0A Dr. Wily Map (0:08, one-shot)
.dword    7000                  ; 16: $11 Game Start (0:07, one-shot)
.dword   46000                  ; 17: $0B Boss (0:20+0:13 ×2)
.dword    6000                  ; 18: $15 Stage Clear (0:06, one-shot)
.dword    3000                  ; 19: $0F Game Over (0:03, one-shot)
.dword   17000                  ; 20: $16 Clear Demo (0:17, one-shot)
.dword    9000                  ; 21: $13 All Stage Clear (0:09, one-shot)
.dword   86000                  ; 22: $0D Ending (0:43 loop ×2, same as Title)
.dword    3000                  ; 23: $14 Dr. Wily UFO (0:01+0:01 ×2)
time_end:

; =============================================================================
; fade chunk — per-track fade-out in milliseconds (signed 32-bit)
; =============================================================================
; Looping music: 5s fade after 2 full loops.
; One-shot jingles: no fade (0).
; =============================================================================
.dword  fade_end - fade_start
.byte   "fade"
fade_start:
.dword      0                   ;  0: $0E Opening (one-shot)
.dword   5000                   ;  1: $0D Title (loops)
.dword   5000                   ;  2: $00 Flash Man Stage (loops)
.dword   5000                   ;  3: $01 Wood Man Stage (loops)
.dword   5000                   ;  4: $02 Crash Man Stage (loops)
.dword   5000                   ;  5: $03 Heat Man Stage (loops)
.dword   5000                   ;  6: $04 Air Man Stage (loops)
.dword   5000                   ;  7: $05 Metal Man Stage (loops)
.dword   5000                   ;  8: $06 Quick Man Stage (loops)
.dword   5000                   ;  9: $07 Bubble Man Stage (loops)
.dword   5000                   ; 10: $08 Dr. Wily Stage 1 (loops)
.dword   5000                   ; 11: $09 Dr. Wily Stage 2 (loops)
.dword   5000                   ; 12: $17 Last Stage (loops)
.dword   5000                   ; 13: $10 Password (loops)
.dword   5000                   ; 14: $0C Stage Select (loops)
.dword      0                   ; 15: $0A Dr. Wily Map (one-shot)
.dword      0                   ; 16: $11 Game Start (one-shot)
.dword   5000                   ; 17: $0B Boss (loops)
.dword      0                   ; 18: $15 Stage Clear (one-shot)
.dword      0                   ; 19: $0F Game Over (one-shot)
.dword      0                   ; 20: $16 Clear Demo (one-shot)
.dword      0                   ; 21: $13 All Stage Clear (one-shot)
.dword   5000                   ; 22: $0D Ending (loops)
.dword   5000                   ; 23: $14 Dr. Wily UFO (loops)
fade_end:

; =============================================================================
; tlbl chunk — per-track labels (null-terminated strings)
; =============================================================================
; Track names from code context (bank_switch_enqueue call sites)
; cross-referenced with VGMRips Mega Man 2 (NES) pack.
;
; Sound IDs $00-$07 map to stage themes via stage_bank_table in bank $0E.
; Sound IDs $08-$09 map to Wily stages via the same table.
; Sound IDs $0A-$17 are UI/jingle/ending music triggered directly.
; =============================================================================
.dword  tlbl_end - tlbl_start
.byte   "tlbl"
tlbl_start:
.byte   "$0E - Opening", 0                      ;  0
.byte   "$0D - Title", 0                        ;  1
.byte   "$00 - Flash Man Stage", 0              ;  2
.byte   "$01 - Wood Man Stage", 0               ;  3
.byte   "$02 - Crash Man Stage", 0              ;  4
.byte   "$03 - Heat Man Stage", 0               ;  5
.byte   "$04 - Air Man Stage", 0                ;  6
.byte   "$05 - Metal Man Stage", 0              ;  7
.byte   "$06 - Quick Man Stage", 0              ;  8
.byte   "$07 - Bubble Man Stage", 0             ;  9
.byte   "$08 - Dr. Wily Stage 1", 0             ; 10
.byte   "$09 - Dr. Wily Stage 2", 0             ; 11
.byte   "$17 - Last Stage", 0                   ; 12
.byte   "$10 - Password", 0                     ; 13
.byte   "$0C - Stage Select", 0                 ; 14
.byte   "$0A - Dr. Wily Map", 0                 ; 15
.byte   "$11 - Game Start", 0                   ; 16
.byte   "$0B - Boss", 0                         ; 17
.byte   "$15 - Stage Clear", 0                  ; 18
.byte   "$0F - Game Over", 0                    ; 19
.byte   "$16 - Clear Demo", 0                   ; 20
.byte   "$13 - All Stage Clear", 0              ; 21
.byte   "$0D - Ending", 0                       ; 22
.byte   "$14 - Dr. Wily UFO", 0                 ; 23
tlbl_end:

; =============================================================================
; NEND terminator
; =============================================================================
.dword  0
.byte   "NEND"
