.PHONY: all clean
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
	@rm -f *.o mkflop.exe test

Depend.Make: *.cpp
	@g++ -MM $^ > Depend.Make

