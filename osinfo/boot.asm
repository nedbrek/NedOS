; info dump bootloader
%include "../mkcd/mmap.asm"

; section start
	org 0x7c00

	bits 16

	; make things safe
	jmp 0:start

start:
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, 0x7c00

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

	xchg bx,bx
end:
	jmp end

putc:
	;  IN - AL char to print (AH is attr)
	push bx
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
	mov [cursor], bx
	pop bx
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

