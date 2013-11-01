; 16 bit to 32 bit strap
; (make all the BIOS calls before switching to pmode)
%include "../mkcd/mmap.asm"
%include "../mkcd/bob.asm"

; constants
BIOS_GET_MMAP	equ 0xe820
BIOS_SET_A20M	equ	0x2401

; section start
	org 0x7e00

	bits 16

start:
	; clear boot output block (BOB)
	mov ax, (BOOT_PARMS >> 4)
	call fun_kzero

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

	;; fill the mode info block
.top_vbe:
	mov cx, [si] ; mode we will consider
	cmp cx, 0xffff ; -1 is end of list
	je  done_vbe

	mov ax, 0x4f01
	int 0x10
	cmp ax, 0x004f
	jne error

	;;; space saver, ds=es (needs to be restored)
	push ds
	push es
	pop  ds

	;; check the attributes for hw sup, color, graphics, lfb
	mov ax, [di]
	and al, 0x99
	cmp al, 0x99
	jne .next_vbe

	;; examine x,y,bpp,mm to see if we want it
	mov al, [di+27] ; get mem mode
	and al, 0xfd ; check 4 and 6 (non-banked)
	cmp al, 4
	jne .next_vbe

	mov al, [di+25] ; get bpp
	cmp BYTE [Bob.vgaBPP], 32
	jne .vbe_not_32bpp

	;;; if we already have 32 bpp
	;;; only want higher x in 32 bpp
	cmp al, 32
	jne .next_vbe

.vbe_check_width:
	;;; check width
	mov ax, [di+18] ; get width
	;;; don't want more than 1024
	cmp ax, 1024
	ja  .next_vbe

	;;; compare widths
	cmp ax, [Bob.vgaWidth]
	jbe .next_vbe ; less or same, skip
	jmp .save_vbe ; more, save

.vbe_not_32bpp:
	;;; current mode is not 32bpp (ax is new bpp)
	cmp al, [Bob.vgaBPP]
	jb  .next_vbe        ; less, skip
	ja  .save_vbe        ; more, take it
	jmp .vbe_check_width ; equal, check width

.save_vbe:
	mov ax, [di+18] ; get width
	mov [Bob.vgaWidth], ax
	mov ax, [di+20] ; get height
	mov [Bob.vgaHeight], ax
	mov al, [di+25] ; get bpp
	mov [Bob.vgaBPP], al
	mov ax, [di+40] ; get lfb
	mov [Bob.vgaLFBP], ax
	mov ax, [di+42] ; get high word lfb
	mov [Bob.vgaLFBP+2], ax
	mov al, [di]    ; get caps
	mov [Bob.vgaCaps], al
	mov [Bob.vgaMode], cx    ; store mode

.next_vbe:
	pop ds
	;add si, 2
	inc si ; space saver
	inc si
	jmp .top_vbe

error:
	hlt

fun_kzero:
	;  IN AX - seg
	; OUT AX - 0
	; OUT CX - 0
	; OUT ES - cleared seg
	push ax
	pop  es
	xor ax, ax
	;mov   ax, 0xdead ; testing mem range
	mov cx, 0x8000
	rep stosw
	ret

fun_getMMap:
	; IN ebp = SMAP, ds:di = MMAP block
	xor  eax, eax
	mov  ax, BIOS_GET_MMAP
	mov ecx, 24  ; ACPI 3
	mov edx, ebp ; 'SMAP'
	mov BYTE [di+20], 1 ; set ACPI 3 valid

	; requires ES:DI to point to out buf, EBX=index, EDX='SMAP', EAX=E820, ECX=24
	int 0x15
	ret

done_vbe:
	;; space saver
	push es
	pop  ds

	;; set the chosen mode
	mov bx, [24]
	or  bh, 0x40
	mov ax, 0x4f02
	int 0x10

	xor  di, di

get_mem_map:
	mov ax, (MMAP_BASE >> 4)
	call fun_kzero

	push es
	pop  ds

	mov ebp, 'PAMS' ; 'SMAP' little endian

	;; first call is CF==error
	xor  ebx, ebx
	call fun_getMMap
	jc  error

	cmp eax, ebp ; success will copy old edx to eax (edx is trash)
	jne error

	test ebx, ebx ; ebx == 0 is done
	je   doneMap

	jcxz .nextMap ; skip zero len entries

	; later calls are CF==done
	add di, 24 ; advance to next

.nextMap:
	call fun_getMMap
	jc   doneMap  ; now, carry is done
	test ebx, ebx ; ebx == 0 is done too
	je   doneMap

	jcxz .nextMap ; skip zero len entries

	; test for len==0 (qword from di+8..15)
	xor esi, esi
	cmp [di+8], esi
	jnz .incMap
	cmp [di+12], esi
	jz  .nextMap

	; advance to next
.incMap:
	add di, 24
	cmp di, 0xfff0
	je  error ; ran out of buffer space (2730 entries!)

	jmp .nextMap

doneMap:

	; set A20
	mov  ax, BIOS_SET_A20M
	int  0x15

	; jump into pmode
%include "pmode.asm"

