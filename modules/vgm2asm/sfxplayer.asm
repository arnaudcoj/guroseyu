include "sfxplayer.inc"

macro copy_reg
.copy_reg\@
    sla b
    jr nc, .skip\@
    ld a, [hli]
    ldh [c], a
.skip\@
    inc c
endm

SECTION "SFX WRAM", WRAM0
sfx_play_bank::
    db 
sfx_play_sample::
    dw
sfx_frame_skip::
    db 
    
SECTION "SFX ROM", ROM0

sfx_play_tick::
    ld hl, sfx_play_sample
    ld a, [hli]
    ld e, a
    or [hl]
    ret z                       ; return FALSE
    ld d, [hl]

    ld hl, sfx_frame_skip
    xor a
    or [hl]
    jr z, .7
    dec [hl]
    ret                         ; A != 0 that returns TRUE
.7:
    ld h, d
    ld l, e                     ; HL = current position inside the sample

    ldh a, [hCurROMBank]     ; save bank and switch
    ld e, a
    ld a, [sfx_play_bank]
    inc a                       ; SFX_STOP_BANK ?
    ret z                       ; return FALSE
    dec a
    ldh [hCurROMBank], a
    ld [rROMB0], a

    ld d, $0f
    ld a, [hl]
    swap a
    and d
    ld [sfx_frame_skip], a

    ld a, [hli]
    and d
    ld d, a                     ; d = frame channel count
    jp z, .6
.2:
    ld a, [hli]
    ld b, a                     ; a = b = channel no + register mask

    and %00000111
    cp 5
    jr c, .3
    cp 7
    jr z, .5                    ; terminator

    ldh a, [rNR51]
    ld c, a
    and %10111011
    ldh [rNR51], a

    xor a
    ld [rNR30], a
    
def ofs = 0
rept 16
    ld a, [hli]
    ldh [_AUD3WAVERAM+ofs], a
def ofs += 1
endr
purge ofs

    ld a, b
    cp 6
    jr nz, .9                   ; just load waveform, not play

    ld a, $80
    ldh [rNR30],a
    ld a, $FE                 ; length of wave
    ldh [rNR31],a
    ld a, $20                 ; volume
    ldh [rNR32],a
    xor a                       ; low freq bits are zero
    ldh [rNR33],a
    ld a, $C7                 ; start; no loop; high freq bits are 111
    ldh [rNR34],a

.9:
    ld a, c
    ldh [rNR51], a

    jr .4
.5:                                 ; terminator
    ld hl, 0
    ld d, l
    jr .0
.3:
    ld  c, a
    add a
    add a
    add c
warn "check if following line is correct"
    add LOW(rNR10)
    ld c, a                     ; c = rNR10 + (a & 7) * 5

rept 5
    copy_reg
endr

.4:
    dec d
    jp nz, .2
.6:
    inc d                       ; return TRUE if still playing
.0:
    ld a, l                     ; save current position
    ld [sfx_play_sample], a
    ld a, h
    ld [sfx_play_sample + 1], a

    ld a, e                     ; restore bank
    ldh [hCurROMBank], a
    ld [rROMB0], a

    ld a, d                     ; result in a

    ret