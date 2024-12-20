# IMPORTED BY MAKEFILE

ifeq ($(OS), Windows_NT)
	SYS=win
	SHELL:=cmd.exe
	EXE:=.exe
else # assume it's a unix environment
	SYS=unix
	EXE:=
	# Use system shell
endif

define rmdir_unix
	@rm -rf $1
endef

define rmdir_win
	@if exist $(subst /,\,$1) rmdir /q /s $(subst /,\,$1)
endef

define rm_unix
	@rm -f $1
endef

define rm_win
	@$(foreach f, $1, 
		@if exist $(subst /,\,$f) del $(subst /,\,$f)
	)
endef

define mkdir_unix
	@mkdir -p $1
endef

define mkdir_win
	@if not exist $(subst /,\,$1) mkdir $(subst /,\,$1)
endef

define cp_unix
	@cp -f $1 $2
endef

define cp_win
	@echo copy /y $(subst /,\,$1) $(subst /,\,$2)
	@copy /y $(subst /,\,$1) $(subst /,\,$2) > NUL
endef

define cat_unix
	cat $1
endef

define cat_win
	type $(subst /,\,$1)
endef

define exists_unix
$(shell which perl > /dev/null 2>&1; echo $$?)
endef

define exists_win
$(shell where.exe $1 > NUL 2> NUL && echo 0 || echo 1)
endef

RM:=rm_$(SYS)
RMDIR:=rmdir_$(SYS)
CP:=cp_$(SYS)
MKDIR:=mkdir_$(SYS)
EXISTS:=exists_$(SYS)
CAT:=cat_$(SYS)
