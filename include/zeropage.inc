; =============================================================================
; Mega Man 2 — Zero Page Variable Definitions
; =============================================================================
; Confirmed from fixed bank (bank0F) analysis.
; These are NOT yet .imported — they serve as reference documentation
; for annotation work. Use Ctrl+F with the address to find usage.
;
; Format: name = $XX    ; description (source routine)

; ─── General purpose temporaries ──────────────────────────────────────────────
; zp_temp_lo            = $00    ; General temp (used in NMI scroll calc, PPU buffer)
; zp_temp_hi            = $01    ; General temp high byte
; zp_game_state         = $04    ; Game state index (checked in LF2B6 dispatch)

; ─── Indirect jump pointer ────────────────────────────────────────────────────
; jump_ptr_lo           = $08    ; Jump table pointer low (jmp ($0008))
; jump_ptr_hi           = $09    ; Jump table pointer high

; ─── PPU / Rendering ─────────────────────────────────────────────────────────
; ppu_buffer_count      = $1B    ; Number of PPU buffer entries to transfer
; frame_counter         = $1C    ; Incremented every NMI
; vblank_done           = $1D    ; Nonzero after VBLANK processing complete
; scroll_x              = $1F    ; Horizontal scroll position
; nametable_select      = $20    ; Base nametable (bit 0)
; scroll_y              = $22    ; Vertical scroll position
; controller_1          = $23    ; Player 1 controller state (8 buttons)
; controller_2          = $24    ; Player 2 controller state (8 buttons)
; controller_temp       = $27    ; Temp used during controller read
; current_bank          = $29    ; Currently switched PRG bank number
; palette_dirty         = $3A    ; Cleared after palette upload
; ppu_col_update        = $47    ; Nonzero = update nametable column this frame
; rng_seed              = $4A    ; Random number generator state
; ppu_attr_update       = $51    ; Nonzero = update attribute table this frame
; bank_queue_count      = $66    ; Number of queued bank switch requests
; bank_callback_flag    = $67    ; Nonzero = bank switch callback pending
; bank_switch_busy      = $68    ; Nonzero = bank switch in progress (for NMI safety)
; bank_switch_backup    = $69    ; Backup of bank number for restore after callback

; ─── PPU control shadows ─────────────────────────────────────────────────────
; sprite_size_flag      = $AE    ; 8x16 sprite size flag (ORed into PPUCTRL)
; camera_offset_y       = $B6    ; Camera Y offset (screen shake / split scroll)
; camera_offset_x       = $B8    ; Camera X offset low
; camera_offset_x_hi    = $B9    ; Camera X offset high
; ppuctrl_shadow        = $F7    ; Shadow of PPUCTRL ($2000) register
; ppumask_shadow        = $F8    ; Shadow of PPUMASK ($2001) register

; ─── RAM buffers (not zero page) ─────────────────────────────────────────────
; oam_buffer            = $0200  ; 256-byte OAM sprite buffer (DMA source)
; ppu_update_buffer     = $0300  ; PPU nametable update buffer
; palette_ram           = $0356  ; 32-byte palette copy (uploaded to $3F00)
; bank_switch_queue     = $057F  ; Queued bank switch request stack
; bank_switch_queue2    = $0580  ; Bank switch enqueue destination
; rng_entropy           = $0480  ; Entropy source for RNG
