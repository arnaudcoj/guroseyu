include "include/hardware.inc"

using "src/misc.asm"

SECTION "Sprite Engine", ROM0
; Displays a sprite using our custom data structure 
; @param a BANK(Sprite)
; @param de Sprite_Address
; @param hl Tiles VRAM Start Address
; @param bc Map VRAM Start Address
DisplaySprite::
	; bc = Map vram address, will be used later by hl
	push bc 

	; Backup current bank in _0
	ldh [hLocalVar_0], a
	ldh a, [hCurROMBank] 
	ldh [hLocalVar_1], a

	; Change bank
	ldh a, [hLocalVar_0]
	ldh [hCurROMBank], a
	ld [rROMB0], a

	; Fetch nb tiles and push it
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	inc de
	push bc

	; Fetch line width and keep it in _2
	ld a, [de]
	ldh [hLocalVar_2], a
	inc de

	; Fetch line height and keep it in _3
	ld a, [de]
	ldh [hLocalVar_3], a
	inc de

	; Pop nb tiles 
	pop bc

	; Copy tile data
	call Memcpy

	; Get back line height
	ld a, [hLocalVar_3]
	ld b, a

	; Pop Map vram address into hl (previously in bc)
	pop hl 

	; Copy all lines
.cpy_map
	ldh a, [hLocalVar_2]
	ld c, a
	
	; Copy 1 line
.cpy_line
	rst MemcpySmall

	; Add offset to map VRAM address to keep sprite aligned
	; (VirtualScreen_Width - Sprite_Width)
	ldh a, [hLocalVar_2]
	push bc
	ld b, 0
	ld c, a
	ld a, SCRN_VX_B 
	sub a, c
	ld c, a
	add hl, bc 
	pop bc

	; Continue until there is no more line to copy
	dec b
	jr nz, .cpy_map

	; Restore bank
	ldh a, [hLocalVar_1]
	ldh [hCurROMBank], a
	ld [rROMB0], a

	; Returns
	ret

