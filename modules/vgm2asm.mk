ifndef MODULES_VGM2ASM
MODULES_VGM2ASM = 1

OBJS+=$(OBJDIR)/vgm2asm/sfxplayer.o
$(OBJDIR)/vgm2asm/sfxplayer.o:

$(OBJDIR)/vgm2asm/%.o:modules/vgm2asm/%.asm
	$(call $(MKDIR),$(dir $@))
	$(RGBASM) $(ASFLAGS) -Imodules/vgm2asm/ -o $@ $<
	

.SECONDEXPANSION:
$(SRCDIR)/%.vgm.asm:$(SRCDIR)/%.vgm $$(wildcard $(SRCDIR)/%.vgm.meta)
	python modules/vgm2asm/vgm2asm.py $(call $(CAT),$<.meta) -o $@ $<
	
endif