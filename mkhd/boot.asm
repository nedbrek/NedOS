; bootloader
%include "../mkcd/mmap.asm"
%include "../mkcd/bob.asm"

; constants
BIOS_GET_MMAP	equ   0xe820
BIOS_SET_A20M	equ	0x2401

; section start
	org 0x7c00

	bits 16

	; clear boot output block (BOB)
	mov ax, (BOOT_PARMS >> 4)
	call fun_kzero

	; set up the stack (needed for BIOS calls)
	mov ss, ax
	mov sp, 0x7c00

	; set VGA mode

	;; first get VESA info
	mov di, 0xfd00
	mov DWORD [es:di], '2EBV' ; VBE2 little endian
	mov ax, 0x4f00
	int 0x10

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

	;;; space saver, ds=es (needs to be restored)
	push ds
	push es
	pop  ds

	;; check the attributes for hw sup, color, graphics, lfb
	mov ax, [di]
	and al, 0x99
	cmp al, 0x99
	jne next_vbe

	;; examine x,y,bpp,mm to see if we want it
	mov al, [di+27] ; get mem mode
	and al, 0xfd ; check 4 and 6 (non-banked)
	cmp al, 4
	jne next_vbe

	mov al, [di+25] ; get bpp
	cmp BYTE [12], 32
	jne vbe_not_32bpp

	;;; if we already have 32 bpp
	;;; only want higher x in 32 bpp
	cmp al, 32
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
	cmp al, [12]
	jb  next_vbe        ; less, skip
	ja  save_vbe        ; more, take it
	jmp vbe_check_width ; equal, check width

save_vbe:
	mov ax, [di+18] ; get width
	mov [4], ax
	mov ax, [di+20] ; get height
	mov [8], ax
	mov al, [di+25] ; get bpp
	mov [12], al
	mov ax, [di+40] ; get lfb
	mov [16], ax
	mov ax, [di+42] ; get high word lfb
	mov [18], ax
	mov al, [di]    ; get caps
	mov [20], al
	mov [24], cx    ; store mode

next_vbe:
	pop ds
	;add si, 2
	inc si ; space saver
	inc si
	jmp top_vbe

fun_kzero:
	; IN seg on stack
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
	; save boot disk id
	mov [di+Bob.bootDisk], dx

get_mem_map:
	mov ax, (MMAP_BASE >> 4)
	call fun_kzero

	mov ebp, 'PAMS' ; 'SMAP' little endian

	;; first call is CF==error
	xor  ebx, ebx
	call fun_getMMap

	test ebx, ebx ; ebx == 0 is done
	je   doneMap

	jcxz .nextMap ; skip zero len entries

	add di, 24 ; advance to next

	; later calls are CF==done
.nextMap:
	call fun_getMMap
	jc   doneMap  ; now, carry is done
	test ebx, ebx ; ebx == 0 is done too
	je   doneMap

	jcxz .nextMap ; skip zero len entries

	; check for extended entry valid
	test BYTE [di+20], 1
	jz   .nextMap

	; test for len==0 (qword from di+8..15)
	xor  esi, esi
	test [di+8], esi
	jnz  .incMap
	test [di+12], esi
	jz   .nextMap

	; advance to next
.incMap:
	add di, 24

	jmp .nextMap

doneMap:

	; set A20
	mov  ax, BIOS_SET_A20M
	int  0x15

	; jump into pmode
%include "pmode.asm"

