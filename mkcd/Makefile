.PHONY: all clean
CPPFLAGS = -Wall

all: cddump.exe mkcd.exe

-include Depend.Make

.cpp.o:
	@g++ -c $(CPPFLAGS) -o $@ $<

cddump.exe: eltorito.o iso9660.o cddump.o
	@g++ -Wall -o$@ $^

mkcd.exe: eltorito.o iso9660.o mkcd.cpp
	@g++ -Wall -o$@ $^

clean:
	@rm -f *.o cddump.exe mkcd.exe

Depend.Make: *.cpp *.h
	@g++ -MM $^ > Depend.Make

boot: boot.asm
	@nasm -Ox boot.asm

run: mkcd.exe boot
	@./mkcd.exe boot

