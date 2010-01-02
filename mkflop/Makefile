.PHONY: all clean run_test run_boot
CPPFLAGS = -Wall

all: mkflop.exe test

-include Depend.Make

.cpp.o:
	@$(CC) -c $(CPPFLAGS) -o $@ $<

mkflop.exe: fat.o mkflop.o
	@g++ -o$@ -Wall $^

test: test.asm
	@nasm -Ox test.asm

boot: boot.asm
	@nasm -Ox boot.asm

clean:
	@rm -f *.o mkflop.exe test test.img

Depend.Make: *.cpp
	@g++ -MM $^ > Depend.Make

run_test: test mkflop.exe
	@./mkflop.exe test
	diff test.img test.img.gold

run_boot: boot mkflop.exe
	@./mkflop.exe boot

