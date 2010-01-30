; bootloader
; memory map
; 00000..003FF	IDT
; 00400..004FF BIOS data
; 00500..07BFF free
; 07C00..07DFF boot sector
; 07E00..0FFFF free
; 10000..1FFFF GDT+IDT
; 20000..2FFFF stage 1 page tables
; 30000..7FFFF free
; 80000..9FBFF possible BIOS EDA
; 9FC00..9FFFF definite BIOS EDA
; A0000..FFFFF ROM

; constants
PAGE_BASE   	equ	0x20000

; section start
	org 0x7c00

	bits 16

	; set VGA mode

	; get mem map

	; set A20
	xchg bx,bx
	mov  ax, 0x2401
	int  0x15

	; jump into pmode
%include "pmode.asm"

