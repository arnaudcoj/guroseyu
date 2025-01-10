ifndef MODULES_HUGEDRIVER
MODULES_HUGEDRIVER = 1

OBJS+=$(OBJDIR)/hUGEDriver/hUGEDriver.o
$(OBJDIR)/hUGEDriver/hUGEDriver.o:

$(OBJDIR)/hUGEDriver/%.o:modules/hUGEDriver/%.asm
	$(call $(MKDIR),$(dir $@))
	$(RGBASM) $(ASFLAGS) -Imodules/hUGEDriver/ -o $@ $<

$(OBJDIR)/%.uge.o:$(SRCDIR)/%.uge.asm
	$(call $(MKDIR),$(dir $@))
	$(RGBASM) $(ASFLAGS) -Imodules/hUGEDriver/include/ -o $@ $<

.SECONDEXPANSION:
$(SRCDIR)/%.uge.asm:$(SRCDIR)/%.uge $$(wildcard $(SRCDIR)/%.uge.meta)
	$(TOOLSDIR)/hUGEDriver/uge2source$(EXE) $< $(basename $(notdir $<)) $(call $(CAT),$<.meta) $@ 

endif