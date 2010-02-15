.PHONY: all clean run
CPPFLAGS = -Wall

all: cddump.exe mkcd.exe

-include Depend.Make
-include DependAsm.Make

.cpp.o:
	@g++ -c $(CPPFLAGS) -o $@ $<

cddump.exe: eltorito.o iso9660.o cddump.o
	@g++ -Wall -o$@ $^

mkcd.exe: eltorito.o iso9660.o mkcd.cpp
	@g++ -Wall -o$@ $^

clean:
	@rm -f *.o cddump.exe mkcd.exe Depend.Make DependAsm.Make

Depend.Make: *.cpp *.h
	@g++ -MM $^ > Depend.Make

DependAsm.Make: *.asm
	@nasm -M boot.asm > DependAsm.Make

%: %.asm
	@nasm -Ox $<

os.bin: boot kernel
	cat boot kernel > os.bin

run: mkcd.exe os.bin
	@./mkcd.exe os.bin

