; info dump bootloader
%include "../mkcd/mmap.asm"

; section start
	org 0x7c00

	bits 16

	; make things safe
	jmp 0:start

start:
	; zero seg regs
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00 ; set stack pointer to match mmap

	; set video mode
	mov ax, 0x0003 ; mode 3, 80x25 color
	int 0x10

	; say hello
	mov ah, 7

	xchg bx,bx
	mov bx, str_hello
	call puts

	mov bx, str_longTest
	call puts

	mov al, 0xde
	call printByte
	mov ax, 0x070a
	call putc

vbe_check:
	mov bx, str_VBE_check
	call puts

	push 0x4000
	pop  es
	mov di, 0xfd00
	mov DWORD [es:di], '2EBV'
	mov ax, 0x4f00
	int 0x10

	cmp ax, 0x004f
	jne .vbe_fail

	mov bx, str_SUCCESS
	jmp .vbe_print

.vbe_fail:
	mov bx, str_FAIL

.vbe_print:
	mov ah, 7
	call puts

	mov al, 0xa
	call putc

	cmp bx, str_FAIL
	je  .vbe_mode_fail

	mov bx, str_VBE_md_desc
	call puts

	; display available VBE modes
	lds si, [es:di+14] ; load list seg:off into ds:si
	add di, 0x200 ; shift past VESA info block

	;; fill the mode info block
.top_vbe:
	mov cx, [si] ; mode we will consider
	cmp cx, 0xffff ; -1 is end of list
	je  .done_vbe

	mov ax, 0x4f01
	int 0x10
	cmp ax, 0x004f
	jne .vbe_mode_fail

	;;; space saver, ds=es (needs to be restored)
	push ds
	push es
	pop  ds

	mov ax, [di]
	and al, 0x99
	cmp al, 0x99
	jne .next_vbe

	;; examine x,y,bpp,mm to see if we want it
	mov al, [di+27] ; get mem mode
	and al, 0xfd ; check 4 and 6
	cmp al, 4
	jne .next_vbe

	mov al, [di+25] ; get bpp
	cmp al, 32
	jne .next_vbe

	mov ah, 0x07
	mov dx, cx
	call printWord

	mov al, ' '
	call putc

	mov dx, [di+18] ; get width
	call printWord

	mov al, ' '
	call putc

	mov dx, [di+20] ; get height
	call printWord

	mov al, 0xa
	call putc

.next_vbe:
	pop ds
	inc si
	inc si
	jmp .top_vbe

.vbe_mode_fail:
.done_vbe:

	jmp pmode

putc:
	;  IN - AL char to print (AH is attr)
	;  IN - AH attr
	push ds
	push bx

	push 0
	pop ds
	mov bx, [cursor]

	; check for LF
	cmp al, 0xa
	jne .putc_normal

	; advance to next row, 0 col
	push ax
	mov ax, bx
	mov bl, 160
	div bl
	; ah has col*2
	; al has row

	inc al ; next row
	mul bl ; scale

	mov bx, ax

	pop ax

	jmp .putc_earlyOut

.putc_normal:
	push es

	; set es to VRAM
	push 0xb800
	pop  es

	mov [es:bx], ax

	; advance cursor two bytes, and save it
	inc bx
	inc bx

	pop es

.putc_earlyOut:
	push ax
	xor ax, ax
	cmp bx, 0xfa0
	;ja  .shift_screen
	cmova bx, ax
	pop ax

	mov [cursor], bx
	pop bx
	pop ds
	ret

puts:
	;  IN - bx ptr to str
	;  IN - AH attr
	; OUT - AX trashed
	push bx

.nextc:
	mov  al, [bx]
	test al, al
	jz   .done

	call putc
	inc  bx
	jmp  .nextc

.done:
	pop bx
	ret

printNibble:
	;  IN AL - nibble (0..F)
	;  IN AH - attr
	; OUT AX - trash
	push bx
	push cx

	cmp al, 9
	jbe .printNib_lo
	add al, 'A'-10
	call putc
	jmp .printNib_done

.printNib_lo:
	add al, '0'
	call putc

.printNib_done:
	pop cx
	pop bx
	ret

printByte:
	; IN AL - byte
	; IN AH - attr

	; save byte
	push cx
	mov cx, ax

	; print high nibble
	shr al, 4
	call printNibble
	; print lo nibble from cx
	mov al, cl
	and al, 0xf
	call printNibble

	pop cx
	ret

printWord:
	; IN AH - attr
	; IN DX - word
	mov al, dh
	call printByte
	mov al, dl
	call printByte

	ret

cursor:
	dw 0x00 ; offset into VRAM r{0..24}*160+c{0..79}*2

str_hello:
	db "Hello world",0xa,0
str_longTest:
	db "A very, very, very, very, very, super, extra, mega, long, string "
	db "to test the line wrap code, don't you know",0xa,0
str_VBE_check:
	db "Checking Get VBE info...",0
str_SUCCESS:
	db "Success",0
str_FAIL:
	db "Fail",0
str_VBE_md_desc:
	db "Mode wd   ht",0xa,0

pmode:
%include "pmode.asm"

