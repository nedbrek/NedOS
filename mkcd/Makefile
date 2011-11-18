.PHONY: all clean
CPPFLAGS += -Wall -g
ASMFLAGS := -w+orphan-labels

all: test.iso cddump.exe mkcd.exe

-include Depend.Make
-include DependAsm.Make

.cpp.o:
	@g++ -c $(CPPFLAGS) -o $@ $<

cddump.exe: eltorito.o iso9660.o cddump.o
	@g++ -Wall -o$@ $^

mkcd.exe: eltorito.o iso9660.o mkcd.o
	@g++ -Wall -o$@ $^

clean:
	@rm -f *.o cddump.exe mkcd.exe Depend.Make DependAsm.Make

Depend.Make: *.cpp *.h
	@g++ -MM $^ > Depend.Make

DependAsm.Make: boot.asm kernel.asm
	@nasm $(ASMFLAGS) -M boot.asm    > DependAsm.Make
	@nasm $(ASMFLAGS) -M kernel.asm >> DependAsm.Make

%: %.asm
	@nasm $(ASMFLAGS) -Ox $<

os.bin: boot kernel
	@cat boot kernel > os.bin

test.iso: os.bin
	@genisoimage -quiet -o $@ -b $< -no-emul-boot -m $@ .
#	@./mkcd.exe os.bin

