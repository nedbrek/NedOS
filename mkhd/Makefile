.PHONY: run

run: boot

-include DependAsm.Make

%: %.asm
	@nasm -Ox $<

DependAsm.Make: *asm
	@nasm -M boot.asm > DependAsm.Make

