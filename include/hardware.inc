; =============================================================================
; NES Hardware Register Definitions
; =============================================================================

; PPU Registers
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007

; OAM DMA
OAMDMA    = $4014

; APU Registers
SQ1_VOL   = $4000
SQ1_SWEEP = $4001
SQ1_LO    = $4002
SQ1_HI    = $4003
SQ2_VOL   = $4004
SQ2_SWEEP = $4005
SQ2_LO    = $4006
SQ2_HI    = $4007
TRI_LINEAR = $4008
TRI_LO    = $400A
TRI_HI    = $400B
NOISE_VOL = $400C
NOISE_LO  = $400E
NOISE_HI  = $400F
DMC_FREQ  = $4010
DMC_RAW   = $4011
DMC_START = $4012
DMC_LEN   = $4013
SND_CHN   = $4015
APU_FRAME = $4017

; Controller Registers
JOY1      = $4016
JOY2      = $4017

; MMC1 (Mapper 1) Registers
; Written serially: 5 writes to target register, bit 0 of each byte
; Register is selected by address range:
MMC1_CONTROL  = $8000   ; $8000-$9FFF: Control (mirroring, PRG/CHR mode)
MMC1_CHR0     = $A000   ; $A000-$BFFF: CHR bank 0
MMC1_CHR1     = $C000   ; $C000-$DFFF: CHR bank 1
MMC1_PRG      = $E000   ; $E000-$FFFF: PRG bank + PRG-RAM enable
