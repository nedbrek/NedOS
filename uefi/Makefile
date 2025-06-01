.PHONY: all
all: BOOTX64.EFI

main.o: main.c bob.h
	@x86_64-w64-mingw32-gcc -ffreestanding -I/usr/include/efi -I/usr/include/efi/x86_64 main.c -fPIC -c -o main.o

kernel.obj: bob.asm kernel.asm
	@nasm -f win64 kernel.asm

BOOTX64.EFI: kernel.obj main.o
	@x86_64-w64-mingw32-gcc -nostdlib -Wl,-dll -shared -Wl,--subsystem,10 -e efi_main -o BOOTX64.EFI $^

floppy.img: BOOTX64.EFI
	@dd if=/dev/zero of=floppy.img bs=1k count=1440
	@mformat -i floppy.img -f 1440 ::
	@mmd -i floppy.img ::/EFI
	@mmd -i floppy.img ::/EFI/BOOT
	@mcopy -i floppy.img BOOTX64.EFI ::/EFI/BOOT

.PHONY: run
run: floppy.img
	@qemu-system-x86_64 -bios /usr/share/qemu/OVMF.fd -cdrom floppy.img

