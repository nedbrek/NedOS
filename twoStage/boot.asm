; two stage bootloader
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

	mov [boot_disk], dx

	; set video mode
	mov ax, 0x0003 ; mode 3, 80x25 color
	int 0x10

	; say hello
	mov ah, 7
	mov bx, str_hello
	call puts

	mov ah, 7
	mov al, [boot_disk]
	call printByte
	mov al, ' '
	call putc

	mov ah, 0x42
	mov si, disk_address_packet
	mov dl, [boot_disk]
	int 0x13

	xor si, si
	mov bx, 0x7e00
	mov ah, 7
.printBlock:
	mov al, [si+bx]
	call printByte
	mov al, ' '
	call putc

	inc si
	cmp si, 15
	jbe .printBlock

.done:
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

disk_address_packet:
	db 0x10       ; structure size
	db 0          ; padding
	dw 0x7f       ; block count
	dd 0x7e00     ; destination
	dq 0xdeadbeef ; put absolute sector here

boot_disk:
	dw 0

pmode:
	jmp 0x7e00

times 510-($-$$) db 0
dw 0xaa55

