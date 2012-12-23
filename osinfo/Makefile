.PHONY: all

all: test.iso

test.iso: os.bin
	@genisoimage -quiet -o $@ -b os.bin -no-emul-boot -m test.iso .
#	@../mkcd/mkcd.exe os.bin

cursor.h: lboot.txt
	@grep -A1 cursor: lboot.txt | awk '{printf $$2}' | sed 's/:/ equ 0x7c00 + 0x/' > cursor.h

lboot.txt: boot.asm
	@nasm -l lboot.txt boot.asm

kernel.asm: cursor.h

boot: pmode.asm

%: %.asm
	@nasm -Ox $<

os.bin: boot kernel
	@cat $^ > os.bin

