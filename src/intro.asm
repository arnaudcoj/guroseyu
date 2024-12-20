include "include/hardware.inc/hardware.inc"

using "obj/vwf_demo.o"

SECTION "Intro", ROMX

Intro::
	jp VWFEntryPoint

; Remove this line
	rst $38

; Put your code here!
	jr @
