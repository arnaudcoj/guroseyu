include "include/hardware.inc/hardware.inc"
include "modules/vgm2asm/sfxplayer.inc"

; using "obj/vwf_demo.o"
using "obj/beep.o"
using "obj/assets/pipe_de_bois.o"
using "obj/audio.o"

SECTION "Intro", ROMX

Intro::
; Remove this line
	; rst $38

; Put your code here!
	; jr @
	
	ld a, %11100100
	ld [hBGP], a

	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BLK01
	ldh [hLCDC], a
	; And turn the LCD on!
	ldh [rLCDC], a
	
	; Enable audio
	ld a, AUDENA_ON
	ldh [rNR52], a
	ld a, $FF
	ldh [rNR51], a
	ld a, $77
	ldh [rNR50], a

	ld b, BANK(pipe_de_bois)
	ld hl, pipe_de_bois
	call Music_init

Loop:
	rst WaitVBlank

.music_switch
	ldh a, [hPressedKeys]
	and PADF_SELECT
	jr z, .check_sfx ; skip if not pressed

	ldh a, [hAudioState]
	xor MUSIC_VBLANK
	ldh [hAudioState], a
	
.check_sfx
	ldh a, [hPressedKeys]
	and PADF_A
	jr z, Loop ; skip if not pressed
	
	ld b, BANK(sfx_Beep)
	ld hl, sfx_Beep
	call SFX_start

	jr Loop

	; jp VWFEntryPoint