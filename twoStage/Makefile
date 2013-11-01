.PHONY: all clean
ASMFLAGS := -w+orphan-labels

all: os.bin

-include DependAsm.Make

DependAsm.Make: boot strap
	@nasm $(ASMFLAGS) -M boot.asm > DependAsm.Make
	@nasm $(ASMFLAGS) -M strap.asm >> DependAsm.Make

%: %.asm
	@nasm $(ASMFLAGS) -Ox $<

stage2.bin: strap
	@cat $^ > $@

os.bin: boot stage2.bin
	@cat $^ > $@

clean:
	@rm -f boot os.bin stage2.bin

