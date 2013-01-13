.PHONY: all clean
ASMFLAGS := -w+orphan-labels

all: test.iso

-include DependAsm.Make

DependAsm.Make: boot kernel
	@nasm $(ASMFLAGS) -M boot.asm > DependAsm.Make
	@nasm $(ASMFLAGS) -M kernel.asm >> DependAsm.Make

test.iso: os.bin
	@mkisofs -quiet -o test.iso -b os.bin -no-emul-boot -m test.iso .
#	@../mkcd/mkcd.exe os.bin

cursor.h: lboot.txt
	@grep -A1 cursor: lboot.txt | awk '{printf $$2}' | sed 's/:/ equ 0x7c00 + 0x/' > cursor.h

lboot.txt: boot.asm
	@nasm -l lboot.txt boot.asm

kernel.asm: cursor.h

boot: pmode.asm

%: %.asm
	@nasm $(ASMFLAGS) -Ox $<

os.bin: boot kernel
	@cat $^ > os.bin

clean:
	@rm -f test.iso boot kernel os.bin cursor.h

