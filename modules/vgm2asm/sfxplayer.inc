include "include/hardware.inc"

; setting SFX bank to this value stops the playback
def SFX_STOP_BANK = $ff

; mute mask helper macro
;def SFX_MUTE_MASK(VARNAME) ( (uint8_t) & __mute_mask_ ## VARNAME )

def SFX_CH_RETRIGGER = %11000000
def SFX_CH_ENABLE    = %10000000

; initialize the SFX driver
macro sfx_sound_init
    ld a, SFX_CH_ENABLE
    ldh [rNR52], a
    ld a, $FF
    ldh [rNR51], a
    ld a, $77
    ldh [rNR50]
endm

; cut sound on all channels
macro sfx_sound_cut
    xor a
    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR32], a
    ldh [rNR42], a
    
    ld a, SFX_CH_RETRIGGER
    ldh [rNR14], a
    ldh [rNR24], a
    ldh [rNR44], a
    
    ld a, $FF
    ldh [rNR51], a
endm

; SFX channel constants
def SFX_CH_1 = %0001
def SFX_CH_2 = %0010
def SFX_CH_3 = %0100
def SFX_CH_4 = %1000

; cut sound on the selected channels
macro sfx_sound_cut_mask ;(uint8_t mask)
def mask equ \1

; set a to 0 if needed
if (mask & (SFX_CH_1 | SFX_CH_2 | SFX_CH_3 | SFX_CH_4)) 
    xor a
endc

; update registers to a (0)

if (mask & SFX_CH_1) 
    ldh [rNR12], a
endc

if (mask & SFX_CH_2) 
    ldh [rNR22], a
endc

if (mask & SFX_CH_3) 
    ldh [rNR32], a
endc

if (mask & SFX_CH_4)
    ldh [rNR42], a
endc

; set a to SFX_CH_RETRIGGER if needed
if (mask & (SFX_CH_1 | SFX_CH_2 | SFX_CH_4)) 
    ld a, SFX_CH_RETRIGGER
endc

; update registers to a (SFX_CH_RETRIGGER)

if (mask & SFX_CH_1) 
    ldh [rNR14], a
endc

if (mask & SFX_CH_2) 
    ldh [rNR24], a
endc

if (mask & SFX_CH_4)
    ldh [rNR44], a
endc

; Update last register to FF

    ld a, $FF
    ld [rNR51], a

purge mask
endm

; stop playing SFX
macro sfx_reset_sample
    ld a, SFX_STOP_BANK
    ld [sfx_play_bank], a
    
    xor a
    ld [sfx_play_sample], a
    ld [sfx_play_sample + 1], a
endm
