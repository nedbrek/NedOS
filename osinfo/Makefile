.PHONY: run

run: os.bin
	@../mkcd/mkcd.exe os.bin

%: %.asm
	@nasm -Ox $<

os.bin: boot
	@cat boot > os.bin

