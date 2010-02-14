; bootloader
; memory map
; 00000..003FF	IDT
; 00400..004FF BIOS data
; 00500..07BFF stack (30464 bytes)
; 07C00..07DFF boot sector
; 07E00..0FFFF free
; 10000..1FFFF boot output block
; 20000..2FFFF GDT+IDT
; 30000..3FFFF stage 1 page tables
; 40000..4FFFF memory map
; 50000..7FFFF free
; 80000..9FBFF possible BIOS EDA
; 9FC00..9FFFF definite BIOS EDA
; A0000..FFFFF ROM

; constants
BOOT_PARMS  	equ	0x10000 ; information from boot time
GDT_BASE    	equ	0x20000
PAGE_BASE   	equ	0x30000
MMAP_BASE   	equ	0x40000

BIOS_GET_MMAP	equ   0xe820
BIOS_SET_A20M	equ	0x2401

; section start
	org 0x7c00

	bits 16

	; set up the stack (needed for BIOS calls)
	xor eax, eax
	mov ss, ax
	mov sp, 0x7c00

	xor   di,  di

	; save boot disk id
	push (BOOT_PARMS >> 4)
	pop  es
	mov  cx, 0x8000
	rep  stosw

	xor ebx, ebx
	mov [es:bx], dx

	; set VGA mode

	;; first get VESA info
	mov di, 0xfd00
	mov DWORD [es:di], '2EBV' ; VBE2 little endian
	mov ax, 0x4f00
	int 0x10
	cmp ax, 0x004f
	jne error

	;; search the mode blocks for one we like
	lds si, [es:di+14] ; load list seg:off into ds:si
	add di, 0x200 ; shift past VESA info block

	xchg bx,bx

	;; fill the mode info block
top_vbe:
	mov cx, [si] ; mode we will consider
	cmp cx, 0xffff ; -1 is end of list
	je  done_vbe

	mov ax, 0x4f01
	int 0x10
	cmp ax, 0x004f
	jne error

	;; space saver, ds=es (needs to be restored)
	push ds
	push es
	pop  ds

	;; check the attributes for hw sup, color, graphics, lfb
	mov ax, [di]
	and ax, 0x99
	cmp ax, 0x99
	jne next_vbe

	;; examine x,y,bpp,mm to see if we want it
	mov ax, [di+27] ; get mem mode
	and al, 0xfd ; check 4 and 6 (non-banked)
	cmp al, 4
	jne next_vbe

	movzx ax, [di+25] ; get bpp
	cmp   BYTE [12], 32
	jne   vbe_not_32bpp

	;;; if we already have 32 bpp
	;;; only want higher x in 32 bpp
	cmp ax, 32
	jne next_vbe

vbe_check_width:
	;;; check width
	mov ax, [di+18] ; get width
	;;; don't want more than 1024
	cmp ax, 1024
	ja  next_vbe

	;;; compare widths
	cmp ax, [4]
	jbe next_vbe ; less or same, skip
	jmp save_vbe ; more, save

vbe_not_32bpp:
	;;; current mode is not 32bpp (ax is new bpp)
	cmp ax, [12]
	jb  next_vbe        ; less, skip
	ja  save_vbe        ; more, take it
	jmp vbe_check_width ; equal, check width

save_vbe:
	mov   ax, [di+18] ; get width
	mov   [4], ax
	mov   ax, [di+20] ; get height
	mov   [8], ax
	movzx ax, [di+25] ; get bpp
	mov   [12], ax
	mov   ax, [di+40] ; get lfb
	mov   [16], ax
	mov   ax, [di+42] ; get lfb
	mov   [18], ax
	movzx ax, [di] ; get caps
	mov   [20], ax
	mov   [24], cx

next_vbe:
	pop ds
	add si, 2
	jmp top_vbe

done_vbe:

	; get mem map (assumes ebx is 0)
	xor  di, di
	push (MMAP_BASE >> 4)
	pop  es
	xor  ax, ax
	mov  cx, 0x8000
	rep  stosw

	mov ecx, 24  ; ACPI 3

	;; first call is CF==error
	mov  ax, BIOS_GET_MMAP
	;xor ebx, ebx
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
	mov   ax, BIOS_GET_MMAP
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
	xchg bx,bx
	jmp error

doneMap:

	; set A20
	mov  ax, BIOS_SET_A20M
	int  0x15

	; jump into pmode
%include "pmode.asm"

