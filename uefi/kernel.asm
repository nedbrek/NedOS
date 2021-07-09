; use RIP relative addressing
default rel

bits 64

%include "bob.asm"
extern bob
global kernel_main

fill_screen:
	; IN  rax - color to fill
	; OUT rdx - screen width
	; OUT rcx - 0
	; OUT rdi - end of screen mem
	mov  edx, [bob+Bob.vgaWidth]
	mov  ecx, [bob+Bob.vgaHeight]
	imul ecx, edx
	shr  ecx, 1 ; we will write 2 pixels per

	;; write
	mov  edi, [bob+Bob.vgaLFBP]
	rep  stosq

	ret

kernel_main:
	cli

	; TODO? config IOAPIC?
	; TODO fill IDT

	; blank screen
	mov  rax, 0x0000_FF00_0000_00FF
	call fill_screen

	; loop forever
.die:
	hlt
	jmp .die

