include "include/hardware.inc"
INCLUDE "assets/charmap.inc"

setcharmap vwf

	rev_Check_hardware_inc 4.0

; using "src/vwf_demo.asm"
using "src/sprite.asm"
using "src/audio.asm"
using "src/assets/groseille.asm"
using "src/assets/sound_effect1.vgm.asm"
using "src/assets/sound_effect3.vgm.asm"
using "src/assets/pipe_de_bois.uge.asm"
using "modules/gb-vwf/vwf.asm"

def TEXT_WIDTH_TILES equ 16
def TEXT_HEIGHT_TILES equ 8

SECTION "Intro", ROMX

Intro::
	ldh a, [hConsoleType]
	or a
	jr z, .cgb

	rst WaitVBlank
	rst WaitVBlank

	ld a, %10101000
	ld [hBGP], a

	rst WaitVBlank
	rst WaitVBlank

	ld a, %01010100
	ld [hBGP], a

	rst WaitVBlank
	rst WaitVBlank

	ld a, %00000000
	ld [hBGP], a

.cgb

	rst WaitVBlank

	ld a, LCDCF_OFF
	ldh [hLCDC], a
	; And turn the LCD off!
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

.clear
	ld a, 0
	ld bc, (_SCRN1 - _SCRN0)
	ld hl, _SCRN0
	rst Memset

; Display Groseille

	; ; Center sprite in visible screen
	; ; Add (Screen_Width - Line_Width) / 2
	; ; TODO move outside of this function
	; ld a, SCRN_X_B
	; sub a, b
	; sra a
	; ld b, 0
	; ld c, a
	; add hl, bc

	ld a, BANK(Sprite_Groseille)
	ld de, Sprite_Groseille
	ld hl, $9000
	ld bc, _SCRN0 + SCRN_VX_B + 8

	call DisplaySprite

	; We will be insta-printing this string.
	xor a
	ld [wNbTicksBetweenPrints], a
	; Specify that string's "tile pool".
	ld a, LOW(vStaticTextTiles / 16)
	ld [wCurTileID], a
	ld [wCurTileID.min], a
	ld a, LOW(vStaticTextTiles.end / 16)
	ld [wCurTileID.max], a
	; Specify that string's "textbox".
	ld a, LOW(vStaticText)
	ld [wTextbox.origin], a
	ld [wPrinterHeadPtr], a
	ld a, HIGH(vStaticText)
	ld [wTextbox.origin + 1], a
	ld [wPrinterHeadPtr + 1], a
	ld a, 15
	ld [wTextbox.width], a
	ld a, 2
	ld [wTextbox.height], a
	ld [wNbLinesRead], a
	; Setup the print.
	assert VWF_NEW_STR == 0
	xor a
	ld hl, StaticText
	ld b, BANK(StaticText)
	call SetupVWFEngine

	: ; Actually do the printing.
	call Far_TickVWFEngine
	call PrintVWFChars
	ld a, [wSourceStack.len]
	and a
	jr nz, :-

	ld a, LCDCF_ON | LCDCF_BGON 
	ldh [hLCDC], a
	; And turn the LCD on!
	ldh [rLCDC], a

	rst WaitVBlank
	rst WaitVBlank

	ld a, %01000000
	ld [hBGP], a

	rst WaitVBlank
	rst WaitVBlank

	ld a, %10010000
	ld [hBGP], a

	rst WaitVBlank
	rst WaitVBlank

	ld a, %11100100
	ld [hBGP], a

	rst WaitVBlank
	
Loop:
	halt
	jr Loop

SECTION "Static text", ROMX

StaticText:
	db "<SET_FONT>",0,"Groseille la plus belle ! <3<END>"

	
SECTION UNION "8800 tiles", VRAM[$8800]
vStaticTextTiles:
	ds 16 * 32
.end

	
SECTION UNION "9800 tilemap", VRAM[_SCRN0]

ds SCRN_VX_B * 3

ds 1
vTextboxTopRow:
ds TEXT_WIDTH_TILES + 2
ds SCRN_VX_B - TEXT_WIDTH_TILES - 3

ds 2
vText::
.row0
ds TEXT_WIDTH_TILES
ds SCRN_VX_B - TEXT_WIDTH_TILES - 2

ds 2
.row1
ds TEXT_WIDTH_TILES
ds SCRN_VX_B - TEXT_WIDTH_TILES - 2

ds 2
.row2
ds TEXT_WIDTH_TILES
ds SCRN_VX_B - TEXT_WIDTH_TILES - 2

ds 2
.row3
ds TEXT_WIDTH_TILES
ds SCRN_VX_B - TEXT_WIDTH_TILES - 2

ds 2
.row4
ds TEXT_WIDTH_TILES
ds SCRN_VX_B - TEXT_WIDTH_TILES - 2

ds 2
.row5
ds TEXT_WIDTH_TILES
ds SCRN_VX_B - TEXT_WIDTH_TILES - 2

ds 2
.row6
ds TEXT_WIDTH_TILES
ds SCRN_VX_B - TEXT_WIDTH_TILES - 2

ds 2
.row7
ds TEXT_WIDTH_TILES
ds SCRN_VX_B - TEXT_WIDTH_TILES - 2

ds 1
vTextboxBottomRow:
ds TEXT_WIDTH_TILES + 2
ds SCRN_VX_B - TEXT_WIDTH_TILES - 3

ds SCRN_VX_B

ds 3
vStaticText:
ds SCRN_VX_B - 3

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
