SECTION "Groseille Sprite", ROMX

DEF WIDTH EQU 4

Sprite_Groseille::
.nb_bytes::
    dw (.map - .tiles)
.width::
    db WIDTH
.height::
    db (.end - .map) / WIDTH
.tiles::
    INCBIN "assets/groseille.2bpp"
.map::
    INCBIN "assets/groseille.map"
.end