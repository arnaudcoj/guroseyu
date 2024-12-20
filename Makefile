
.SUFFIXES: # Suppress a lot of useless default rules, which also provides a nice speedup.

ifeq (${MAKE_VERSION},3.81)
# Parallel builds are broken with macOS' bundled version of Make.
# Please consider installing Make from Homebrew (`brew install make`, **make sure to read the caveats**).
# Please see https://github.com/ISSOtm/gb-starter-kit/issues/1#issuecomment-1793775226 for details.
.NOTPARALLEL: # Delete this line if you want to have parallel builds regardless!
endif

include src/tools/mkutils/crossplatform.mk

# Recursive `wildcard` function.
rwildcard = $(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

# Argument constants
SRCDIR  = src
INCDIR  = include
BINDIR  = bin
RESDIR  = res
GENDIR  = assets
OBJDIR  = obj
LIBDIR  = lib
TOOLSDIR= tools

RGBDS   ?= # Shortcut if you want to use a local copy of RGBDS.
RGBASM  := ${RGBDS}rgbasm
RGBLINK := ${RGBDS}rgblink
RGBFIX  := ${RGBDS}rgbfix
RGBGFX  := ${RGBDS}rgbgfx
VWFENCODER:= $(TOOLSDIR)/gb-vwf/font_encoder
RUNNER	:= bgb

ROM = bin/${ROMNAME}.${ROMEXT}


WARNINGS = all extra
ASFLAGS  = -p ${PADVALUE} $(addprefix -W,${WARNINGS}) -D VWF_CFG_FILE=$(VWF_CFG_FILE) -P src/tools/mkutils/macros.inc
LDFLAGS  = -p ${PADVALUE}
FIXFLAGS = -p ${PADVALUE} -i "${GAMEID}" -k "${LICENSEE}" -l ${OLDLIC} -m ${MBC} -n ${VERSION} -r ${SRAMSIZE} -t ${TITLE}

## Project-specific configuration
# Use this to override the above
include project.mk

# `all` (Default target): build the ROM
all: bin
.PHONY: all

bin: ${ROM}
.PHONY: bin

# The list of ASM files that RGBASM will be invoked on.
SRCS = $(call rwildcard,$(SRCDIR),*.asm)
INCS = $(call rwildcard,$(INCDIR),*.inc)
VWF_CFG_FILE:=$(INCDIR)/vwf_config.inc

DEPS = ${SRCS:.asm=.mk} ${INCS:.inc=.mk}
DEPS := $(filter-out include/hardware.mk,$(DEPS))

ifeq ($(filter clean purge dependencies,${MAKECMDGOALS}),)
include $(DEPS)
endif

# `clean`: Clean obj and bin files
clean:
	@echo Cleaning project
	$(call $(RMDIR),$(BINDIR))
	$(call $(RMDIR),$(OBJDIR))
.PHONY:clean

# `clean`: Clean obj, bin and generated files
purge:clean
	@echo Cleaning project harder
	$(call $(RMDIR),$(GENDIR))
	$(call $(RMDIR),$(OBJDIR))
	$(call $(RM), $(DEPS))
	$(call $(RM), $(call rwildcard,$(RESDIR),*.vwf))
	$(call $(RM), $(call rwildcard,$(RESDIR),*.vwflen))
	$(call $(RMDIR), $(dir $(VWFENCODER)))
	$(call $(RMDIR), $(SRCDIR)/gb-vwf/target/)
.PHONY:purge

# `rebuild`: Build everything from scratch
# It's important to do these two in order if we're using more than one job
rebuild:
	${MAKE} clean
	${MAKE} all
.PHONY: rebuild

run:$(ROM)
	@echo $(RUNNER) $(ROM)
	@$(RUNNER) $(ROM)||:
.PHONY:run

dependencies:$(DEPS)
	echo $(DEPS)
.PHONY:dependencies

assets/%.2bpp: $(SRCDIR)/assets/%.png
	$(call $(MKDIR),$(dir $@))
	${RGBGFX} -o $@ $<

assets/%.1bpp: $(SRCDIR)/assets/%.png
	$(call $(MKDIR),$(dir $@))
	${RGBGFX} -d 1 -o $@ $<

# Define how to compress files using the PackBits16 codec
# Compressor script requires Python 3
assets/%.pb16: assets/% $(SRCDIR)/tools/pb16.py
	$(call $(MKDIR),$(dir $@))
	$(SRCDIR)/tools/pb16.py $< assets/$*.pb16

assets/%.pb16.size: assets/%
	$(call $(MKDIR),$(dir $@))
	printf 'def NB_PB16_BLOCKS equ ((%u) + 15) / 16\n' "$$(wc -c <$<)" > assets/$*.pb16.size

# Define how to compress files using the PackBits8 codec
# Compressor script requires Python 3
assets/%.pb8: assets/% $(SRCDIR)/tools/pb8.py
	$(call $(MKDIR),$(dir $@))
	python $(SRCDIR)/tools/pb8.py $< assets/$*.pb8

assets/%.pb8.size: assets/%
	$(call $(MKDIR),$(dir $@))
	printf 'def NB_PB8_BLOCKS equ ((%u) + 7) / 8\n' "$$(wc -c <$<)" > assets/$*.pb8.size

$(INCDIR)/%.mk:$(INCDIR)/%.asm
	$(call $(MKDIR),$(dir $@))
	perl src/tools/mkutils/generate_dep.pl $^ ${subst ${INCDIR}, ${OBJDIR}, ${@:.mk=.o}} $@

$(SRCDIR)/%.mk:$(SRCDIR)/%.asm
	$(call $(MKDIR),$(dir $@))
	perl src/tools/mkutils/generate_dep.pl $^ ${subst ${SRCDIR}, ${OBJDIR}, ${@:.mk=.o}} $@

$(INCDIR)/%.mk:$(INCDIR)/%.inc 
	$(call $(MKDIR),$(dir $@))
	perl src/tools/mkutils/generate_dep.pl $^ $@

$(OBJDIR)/%.o:$(SRCDIR)/%.asm
	$(call $(MKDIR),$(dir $@))
	$(RGBASM) $(ASFLAGS) -o $@ $<

$(GENDIR)/charmap.inc:$(SRCDIR)/gb-vwf/vwf.asm
	$(call $(MKDIR),$(GENDIR))
	$(RGBASM) $(ASFLAGS) -DPRINT_CHARMAP $^ > $@

assets/%.vwf:$(SRCDIR)/assets/%.png tools/gb-vwf/font_encoder
	$(call $(MKDIR),$(dir $@))
	$(VWFENCODER) $< $@

assets/%.vwflen:$(SRCDIR)/assets/%.png tools/gb-vwf/font_encoder
	$(call $(MKDIR),$(dir $@))
	$(VWFENCODER) $< $(@:.vwflen=.vwf)

# How to build a ROM.
# Notice that the build date is always refreshed.
bin/%.${ROMEXT}:$(OBJS)
	$(call $(MKDIR),$(OBJDIR))
	${RGBASM} ${ASFLAGS} -o obj/build_date.o $(SRCDIR)/assets/build_date.asm

	$(call $(MKDIR),$(BINDIR))

	${RGBLINK} ${LDFLAGS} -m bin/$*.map -n bin/$*.sym -o $@ $(OBJS)
	${RGBFIX} -v ${FIXFLAGS} $@

$(VWFENCODER):$(SRCDIR)/gb-vwf/target/release/font_encoder
	$(call $(MKDIR),$(dir $@))
	cp -f $^ $@

$(SRCDIR)/gb-vwf/target/release/font_encoder:$(SRCDIR)/gb-vwf/font_encoder/Cargo.toml
	cargo build --release --manifest-path=$^


# By default, cloning the repo does not init submodules; if that happens, warn the user.
# Note that the real paths aren't used!
# Since RGBASM fails to find the files, it outputs the raw paths, not the actual ones.
$(INCDIR)/hardware.inc/hardware.inc $(INCDIR)/rgbds-structs/structs.asm $(SRCDIR)/gb-vwf/vwf.asm:
	@echo '$@ is not present; have you initialized submodules?'
	@echo 'Run `git submodule update --init`, then `make clean`, then `make` again.'
	@echo 'Tip: to avoid this, use `git clone --recursive` next time!'
	@exit 1
