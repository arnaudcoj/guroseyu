include "include/hardware.inc/hardware.inc"
include "modules/vgm2asm/sfxplayer.inc"

using "obj/vwf_demo.o"
using "obj/beep.o"

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

	ld b, BANK(sample_song)
	ld hl, sample_song
	call Far_hUGE_init
	
    ld a, SFX_STOP_BANK
    ld [sfx_play_bank], a
	
Loop:
	rst WaitVBlank
	
.check_sfx
	ldh a, [hPressedKeys]
	and PADF_A
	jr z, .audio ; skip if not pressed
	
	sfx_set_sample sfx_Beep
	ld a, %00001011
	ld [_hUGE_mute_mask], a
.audio
.sfx
	call sfx_play_tick
	or a
	jr nz, .music
	
	ld a, %00000000
	ld [_hUGE_mute_mask], a
	
.music
	call Far_hUGE_dosound

	jr Loop

	; jp VWFEntryPoint

SECTION "VWF engine additions", ROM0

Far_TickVWFEngine::
	ldh a, [hCurROMBank]
	push af

	call TickVWFEngine

	pop af
	ldh [hCurROMBank], a
	ld [rROMB0], a

	ret

ClearTextbox::
	; Load the textbox's origin, and reset the "printer head" to point there.
	ld hl, wTextbox.origin
	ld a, [hli]
	ld [wPrinterHeadPtr], a
	ld h, [hl]
	ld l, a
	ld a, h
	ld [wPrinterHeadPtr + 1], a

	ld a, [wTextbox.width]
	ld [wLookahead.nbTilesRemaining], a
	ld a, [wTextbox.height]
	ld [wNbLinesRemaining], a ; Reset this, since we're resetting the "print head" as well.
	ld [wNbLinesRead], a ; Same.

	; Clear the textbox.
	ld b, a
.clearRow
	ld a, [wTextbox.width]
	ld c, a
.clear
	ldh a, [rSTAT]
	and STATF_BUSY
	jr nz, .clear
	; a = 0 here.
	ld [hli], a
	dec c
	jr nz, .clear
	ld a, [wTextbox.width]
	cpl
	add SCRN_VX_B + 1 ; a = SCRN_VX_B - [wTextbox.width]
	add a, l
	ld l, a
	adc a, h
	sub l
	ld h, a
	dec b
	jr nz, .clearRow

	; Ensure we'll start printing to a new tile.
	ld hl, wTileBuffer
	assert wTileBuffer.end == wNbPixelsDrawn
	ld c, wTileBuffer.end - wTileBuffer + 1
	xor a
.clearTileBuffer
	ld [hli], a
	dec c
	jr nz, .clearTileBuffer
	ret

	
SECTION "hUGE additions", ROM0

Far_hUGE_init:: ; b = bank, hl = pointer
	ldh a, [hCurROMBank]
	push af

	ld a, b
	ldh [hMusicROMBank], a
	ldh [hCurROMBank], a
	ld [rROMB0], a
    call hUGE_init

	pop af
	ldh [hCurROMBank], a
	ld [rROMB0], a

	ret

Far_hUGE_dosound:: 
	ldh a, [hCurROMBank]
	push af

	ldh a, [hMusicROMBank]
	ldh [hCurROMBank], a
	ld [rROMB0], a
    call hUGE_dosound

	pop af
	ldh [hCurROMBank], a
	ld [rROMB0], a

	ret

SECTION "hUGE Variables", HRAM
	
hMusicROMBank:: db