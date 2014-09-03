%include "mmap.asm"
%include "bob.asm"

; constants (for page table bits)
PAGE_PRESENT   equ   1
PAGE_WRITE     equ   2
PAGE_SUPER     equ   4

PAGE_LEN       equ   0x01000

; Start
; Boot loader places us in next block (512B)
; - we are in 64 bit mode, with limited page tables and interrupts off
; - screen resolution has been set via VBE, info in the BOB
; - memmap (INT15) info is in the BOB
	org 0x7e00
	bits 64

%include "kernel_core.asm"

keymap:
%include "keymap.asm"

font6x10:
%include "font.asm"

