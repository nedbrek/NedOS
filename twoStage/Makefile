.PHONY: all clean
ASMFLAGS := -w+orphan-labels

all: os.bin

-include DependAsm.Make

DependAsm.Make: boot strap kernel
	@nasm $(ASMFLAGS) -M boot.asm > DependAsm.Make
	@nasm $(ASMFLAGS) -M strap.asm >> DependAsm.Make
	@nasm $(ASMFLAGS) -M kernel.asm >> DependAsm.Make

%: %.asm
	@nasm $(ASMFLAGS) -Ox $<

stage2.bin: strap
	@cat $^ > $@

os.bin: boot stage2.bin kernel
	@cat $^ > $@

zeros.bin: os.bin
	$(eval FILESIZE := $(shell stat -L -c %s os.bin))
	$(eval REMAINDER := $(shell echo "4096 - $(FILESIZE) % 4096" | bc))
	@dd count=$(REMAINDER) bs=1 if=/dev/zero of=$@

bochs.img: os.bin zeros.bin main.bin
	@cat $^ > $@

clean:
	@rm -f boot os.bin stage2.bin

