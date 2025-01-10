include "include/hardware.inc"

USING "src/audio.asm"
	
; Used to setup timer in header
; NOTE : Set rTMA to $e0 when using CGB double speed !
def TAC_4096_8192 = %00000100 ; TIMA = 4096Hz, 8192Hz on double-speed
	EXPORT TAC_4096_8192

def TMA_SIMPLE_SPEED = $f0  ; TIMA = 4096 / (256 - $f0) = 4096 / 16 = 256Hz
	EXPORT TMA_SIMPLE_SPEED
def TMA_DOUBLE_SPEED = $e0  ; TIMA = 8192 / (256 - $e0) = 8192 / 32 = 256Hz
	EXPORT TMA_SIMPLE_SPEED


SECTION "Timer handler", ROM0[$50]
TimerHandler:
	push af
	push bc
	push de
	push hl
	
.sfx
	call SFX_tick

.music
	; Check if should handle music
	ldh a, [hAudioState]
	and MUSIC_VBLANK
	jr nz, .end
	
	; Increment then check if music tick is modulo 4
	ldh a, [hMusicTick]
	inc a
	and 4 - 1
	ldh [hMusicTick], a
	jr nz, .end
	
	call Music_tick
	
.end
	pop hl
	pop de
	pop bc
	pop af

	reti

SECTION "Timer HRAM", HRAM
	hMusicTick::db