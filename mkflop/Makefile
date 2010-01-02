.PHONY: all clean
CPPFLAGS = -Wall

all: mkflop.exe

-include Depend.Make

.cpp.o:
	@$(CC) -c $(CPPFLAGS) -o $@ $<

mkflop.exe: fat.o mkflop.o
	@g++ -o$@ -Wall $^

clean:
	@rm -f *.o mkflop.exe

Depend.Make: *.cpp
	@g++ -MM $^ > Depend.Make

