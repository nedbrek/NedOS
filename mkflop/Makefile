.PHONY: all clean run
CPPFLAGS = -Wall

all: mkflop.exe test

-include Depend.Make

.cpp.o:
	@$(CC) -c $(CPPFLAGS) -o $@ $<

mkflop.exe: fat.o mkflop.o
	@g++ -o$@ -Wall $^

test: test.asm
	@nasm -Ox test.asm

clean:
	@rm -f *.o mkflop.exe test test.img

Depend.Make: *.cpp
	@g++ -MM $^ > Depend.Make

run: all
	@./mkflop.exe test
	diff test.img test.img.gold

