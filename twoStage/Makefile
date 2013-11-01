.PHONY: all clean
ASMFLAGS := -w+orphan-labels

all: os.bin

-include DependAsm.Make

DependAsm.Make: boot
	@nasm $(ASMFLAGS) -M boot.asm > DependAsm.Make

lboot.txt: boot.asm
	@nasm -l lboot.txt boot.asm

%: %.asm
	@nasm $(ASMFLAGS) -Ox $<

os.bin: boot stage2.bin
	@cat $^ > os.bin

clean:
	@rm -f boot os.bin

