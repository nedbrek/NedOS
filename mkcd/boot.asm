; bootloader
; memory map
; 00000..003FF	IDT
; 00400..004FF BIOS data
; 00500..07BFF free
; 07C00..07DFF boot sector
; 07E00..0FFFF free
; 10000..1FFFF GDT+IDT
; 20000..2FFFF stage 1 page tables
; 30000..3FFFF memory map
; 40000..7FFFF free
; 80000..9FBFF possible BIOS EDA
; 9FC00..9FFFF definite BIOS EDA
; A0000..FFFFF ROM

; constants
GDT_BASE    	equ	0x10000
PAGE_BASE   	equ	0x20000
MMAP_BASE   	equ	0x30000

; section start
	org 0x7c00

	bits 16

	; set up the stack (needed for BIOS calls)
	xor eax, eax
	mov ss, ax
	mov sp, 0xffff

	; get mem map
	xor   di,  di
	push (MMAP_BASE >> 4)
	pop  es
	mov  cx, 0x8000
	rep  stosw

	xchg bx,bx

	xor ebx, ebx ; ask for start of map
	mov ecx, 24  ; ACPI 3

	; first call is CF==error
	mov  ax, 0xe820
	mov edx, 'PAMS' ; 'SMAP' little endian
	mov BYTE [es:di+20], 1 ; set ACPI 3 valid

	int 0x15

	jc  error

	mov edx, 'PAMS'
	cmp eax, edx ; success will copy edx to eax
	jne error

	test ebx, ebx ; ebx == 0 is done
	je   doneMap

	jcxz nextMap ; skip zero len entries

	add di, 24 ; advance to next

	; later calls are CF==done
nextMap:
	xor  eax, eax
	mov   ax, 0xe820
	mov  ecx, 24
	mov  edx, 'PAMS'
	mov  BYTE [es:di+20], 1 ; set ACPI 3 valid
	int 0x15
	jc   doneMap
	test ebx, ebx ; ebx == 0 is done too
	je   doneMap

	jcxz nextMap ; skip zero len entries

	; check for extended entry valid
	test BYTE [es:di+20], 1
	jz   nextMap

	; test for len==0 (qword from di+8..15)
	mov  eax, [es:di+8]
	test eax, eax
	jnz  incMap
	mov  eax, [es:di+12]
	jz   nextMap

	; advance to next
incMap:
	add di, 24
	cmp di, 0xfff0
	je  error ; ran out of buffer space (2730 entries!)

	jmp nextMap

error:
	jmp error

doneMap:

	; set VGA mode

	; set A20
	mov  ax, 0x2401
	int  0x15

	; jump into pmode
%include "pmode.asm"

