; bootloader
	org 0x7c3e

	bits 16

	xchg bx,bx ; Bochs magic debug break 

	; loop forever
loop:
	jmp loop

