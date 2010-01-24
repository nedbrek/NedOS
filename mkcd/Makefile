.PHONY: all clean
CPPFLAGS = -Wall

all: cddump.exe

-include Depend.Make

.cpp.o:
	@g++ -c $(CPPFLAGS) -o $@ $<

cddump.exe: eltorito.o iso9660.o cddump.o
	@g++ -Wall -o$@ $^

clean:
	@rm -f *.o cddump.exe

Depend.Make: *.cpp
	@g++ -MM $^ > Depend.Make

