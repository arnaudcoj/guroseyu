include "include/hardware.inc"

using "modules/hUGEDriver/hUGEDriver.asm"
using "modules/vgm2asm/sfxplayer.asm"

def MUSIC_VBLANK  = %10000000
    EXPORT MUSIC_VBLANK

def MUSIC_MASK    = %01110000
def MUSIC_STOPPED = %00000000
def MUSIC_LOADING = %00010000
def MUSIC_PLAYING = %00100000

def SFX_MASK      = %00001111
def SFX_STOPPED   = %00000000
def SFX_LOADING   = %00000001
def SFX_PLAYING   = %00000010

SECTION "Audio ROM", ROM0
    
Music_init:: ; b = bank, hl = pointer
	ld a, [hAudioState]
	and ~MUSIC_MASK
	or MUSIC_LOADING
	ld [hAudioState], a
	
	ldh a, [hCurROMBank]
	push af

	ld a, b
	ldh [hCurROMBank], a
	ld [rROMB0], a

	ld [wMusicROMBank], a

    call hUGE_init

	pop af
	ldh [hCurROMBank], a
	ld [rROMB0], a

	ld a, [hAudioState]
	and ~MUSIC_MASK
	or MUSIC_PLAYING
	ld [hAudioState], a

	ret

Music_tick:: 
	ldh a, [hAudioState]
	and MUSIC_PLAYING
	ret z
	
	ldh a, [hCurROMBank]
	push af

	ld a, [wMusicROMBank]
	ldh [hCurROMBank], a
	ld [rROMB0], a

    call hUGE_dosound

	pop af
	ldh [hCurROMBank], a
	ld [rROMB0], a

	ret

Music_release_channels::
	ld bc, 0
	call hUGE_mute_channel
	inc b
	ld c, 0
	call hUGE_mute_channel
	inc b
	ld c, 0
	call hUGE_mute_channel
	inc b
	ld c, 0
	call hUGE_mute_channel
	
	ret

; b = bank, c = priority, hl = address
SFX_start:: 
    ld a, [hAudioState]
    and SFX_PLAYING
    jr z, .skip_priority_check

; Check current priority vs SFX priority (0 = higher, 255 = lower)
    ld a, [wSFXPriority]
    cp c
    ret c ; if (current priority < new priority) return
.skip_priority_check

; Set State to Loading (do nothing if interrupted by a tick)
    ld a, [hAudioState]
    and ~SFX_MASK
    or SFX_LOADING
    ldh [hAudioState], a

; Store Priority
    ld a, c
    ld [wSFXPriority], a

; Store current bank
    ldh a, [hCurROMBank]
    push af

; Switch bank and keep it in SFX hRAM
    ld a, b
    ld [sfx_play_bank], a
    ldh [hCurROMBank], a
    ld [rROMB0], a

; Fetch mute mask and increment hl
	ld a, [hli]
    ld d, a

; Set sample address in RAM
    ld a, l
    ld [sfx_play_sample], a
    ld a, h
    ld [sfx_play_sample + 1], a

; Misc
    xor a
    ld [sfx_frame_skip], a

; Start muting channels
    ld b, 0

; Mute Channel 1
    ld a, d
    and a, %00000001
    ld c, a

    call hUGE_mute_channel

    srl d

; Mute Channel 2
    inc b

    ld a, d
    and a, %00000001
    ld c, a

    call hUGE_mute_channel

    srl d

; Mute Channel 3 and reset wave data if needed
    inc b

    ld a, d
    and a, %00000001
    ld c, a

    call hUGE_mute_channel

    srl d
    jr nc, .keep_wave

.reset_wave
    ld a, hUGE_NO_WAVE
    ld [hUGE_current_wave], a
.keep_wave

; Mute Channel 4
    inc b

    ld a, d
    and a, %00000001
    ld c, a

    call hUGE_mute_channel
    
; Restore bank
    pop af
    ldh [hCurROMBank], a
    ld [rROMB0], a

; Set State to Playing
    ld a, [hAudioState]
    and ~SFX_MASK
    or SFX_PLAYING
    ldh [hAudioState], a
    
    ret

SFX_tick::
; Handle SFX
	ldh a, [hAudioState]
	and SFX_PLAYING
    ret z

	call sfx_play_tick
	or a
	ret nz
	
; Stop SFX if needed
    ld a, [hAudioState]
    and ~SFX_MASK
    or SFX_STOPPED
    ldh [hAudioState], a

	call Music_release_channels    
    ret

SECTION "Audio WRAM", WRAM0
    wMusicROMBank::db
    wSFXPriority::db

SECTION "Audio HRAM", HRAM 
	hAudioState::db