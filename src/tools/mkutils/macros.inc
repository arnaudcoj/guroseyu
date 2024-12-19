; Indents this line so it can be used as a macro
DEF using EQUS "    using_macro"
DEF USING EQUS "    using_macro"

; Comments out using command, so it can be used to define prerequisite in Makefile
MACRO using_macro
    ;using \1
ENDM

