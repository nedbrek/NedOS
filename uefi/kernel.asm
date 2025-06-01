; use RIP relative addressing
default rel

bits 64

%include "bob.asm"
extern bob

global kernel_main
kernel_main:
	cli

	; TODO? config IOAPIC?
	; TODO fill IDT

	; blank screen
	mov  rax, 0x0000_FF00_0000_00FF
	call fill_screen

	; clear a terminal box
	mov rsi, termLR_ctx

	xor eax, eax ; background color
	call fill_term

	; print hello world
	mov eax, 0xffffffff
	lea rdx, [hello_str]
	call vputs

	sfence

	; loop forever
.die:
	hlt
	jmp .die

malloc:
	; IN  eax - size (don't malloc more than 4GB!)
	; OUT rax - addr of block
	push rdi
	push rsi
	push rcx

	mov  rsi, [bob+Bob.freeList]
	mov  rdi, [rsi+8] ; block size
	cmp  rdi, rax
	jb   .next_block

	mov  rcx, rax
	mov  rax, rsi

	sub  rdi, rcx ; shrink size
	add  rsi, rcx ; shift head

	mov rcx, [rax] ; move next block ptr
	mov [rsi], rcx

	mov [rsi+8], rdi ; update size

	mov [bob+Bob.freeList], rsi ; update free list

	jmp .end

.next_block: ; Ned, implement
	xor eax, eax ; return NULL for now

.end:
	pop  rcx
	pop  rsi
	pop  rdi
	ret

fill_rect:
	; IN  eax - pixel to fill
	; IN  ecx - width in pixels
	; IN  edi - y coord (bytes)
	; IN  edx - x coord (bytes, ie. col*4)
	; IN  ebx - height
	; OUT ebx - zero
	; OUT edi - end of filled block in LFB

	push rsi
	; save width
	push rcx

	; get screen width
	mov esi, [bob+Bob.vgaWidth]

	; scale y coord by screen width
	imul edi, esi

	; subtract the row width
	sub esi, ecx
	; scale to pixels
	shl esi, 2

	; add x coord
	add  edi, edx

	; add to lfb base
	add  rdi, [bob+Bob.vgaLFBP]

.fill_row:
	rep stosd
	dec ebx
	jz .end

	; shift down 1 row
	add rdi, rsi
	; reset count
	mov ecx, [rsp]
	jmp .fill_row

.end:
	pop rcx
	pop rsi
	ret

fill_term:
	; IN esi - term ctxt
	; IN eax - pixel
	push rcx
	push rdi
	push rdx
	push rbx

	imul ecx, [rsi+ 8], 6 ; term width, chars to px
	mov  edi, [rsi+ 4]    ; y coord (px)
	shl  edi, 2           ; px to bytes
	mov  edx, [rsi+ 0]    ; x coord
	shl  edx, 2           ; px to bytes
	imul ebx, [rsi+12], 10; term height, chars to px
	call fill_rect

	pop rbx
	pop rdx
	pop rdi
	pop rcx
	ret

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
	mov  rdi, [bob+Bob.vgaLFBP]
	rep  stosq

	ret

cursorRight:
	; update cursor
	mov ebx, [rsi+16]
	mov ecx, [rsi+20]

	cmp edx, 10
	je .next_row

	;; next col
	inc ebx
	;; check for wrap
	cmp ebx, [rsi+8]
	jb .done

.next_row:
	;; next row
	mov ebx, 0

	mov ecx, [rsi+20]
	inc ecx
	cmp ecx, [rsi+12]
	jb .done

	;; shift screen
	;;; temp hack, clear and reset
	xor ecx, ecx
	push rax
	xor eax, eax ; black
	call fill_term
	pop rax

.done:
	mov [rsi+16], ebx
	mov [rsi+20], ecx

	ret

drawChar:
	; IN  eax - color
	; IN  rdx - pattern to draw
	; IN  rsi - terminal context
	; OUT rdx - 0
	push rbp
	push rdi
	push rbx
	push rcx

	; get upper right of char
	;; lfb + (console.y + cursor.y * 10) * screen.width +
	;; console.x + cursor.x * 6

	;;; edi = cursor.y * 10
	imul edi, [rsi+20], 10
	;;; edi += console.y
	add  edi, [rsi+ 4]

	;;; ebx = screen.width
	mov ebx, [bob+Bob.vgaWidth]

	;;; edi = (console.y + cursor.y * 10) * screen.width
	imul edi, ebx

	;;; ecx = cursor.x * 6 + console.x
	imul ecx, [rsi+16], 6
	add  ecx, [rsi]

	add edi, ecx

	;; scale px to bytes
	shl edi, 2

	;; add to lfb base
	add  rdi, [bob+Bob.vgaLFBP]

	sub ebx, 6 ; wrap short 6 px
	;; scale px to bytes
	shl ebx, 2

	shl rdx,  4 ; 4 dead bits on top
	mov ebp, 10 ; 10 rows

.put_row:
	;; put 6 px (burn 6 bits of bmp)
	mov ecx, 6

.put_px:
	shl rdx, 1

	jnc .no_put
	mov [rdi], eax
.no_put:

	add rdi, 4
	dec ecx
	jnz .put_px

	;; wrap to next row (add screen_width - 6)
	add rdi, rbx
	dec ebp
	jnz .put_row

.done:
	pop  rcx
	pop  rbx
	pop  rdi
	pop  rbp
	ret

vputc:
	; IN  rax - color (high bits bg)
	; IN  rdx - char code
	; IN  rsi - terminal context ptr
	; OUT edx - zero
	push rbp
	push rdi
	push rbx
	push rcx

	cmp edx, 10
	je .updateCursor

	sub edx, 32
	lea rbp, [font6x10.space]
	mov rdx, [rbp + rdx*8]

	call drawChar

.updateCursor:
	call cursorRight

	pop rcx
	pop rbx
	pop rdi
	pop rbp
	ret

vputs:
	; IN  rax - color (high bits will be bg, not implemented)
	; IN  rdx - char*
	; IN  rsi - terminal context ptr
	; OUT rdx - end of string

.nextc:
	push rdx
	movzx edx, BYTE [rdx]
	test dl, dl
	jz .done

	call vputc

	pop rdx
	inc rdx
	jmp .nextc

.done:
	pop rdx
	ret

termLR_ctx:
.consoleX:
	dd 480 ; console x pos (px)
.consoleY:
	dd 500 ; console y pos (px)
.width:
	dd  80 ; width (chars)
.height:
	dd  25 ; height (chars)
.cursorX:
	dd   0 ; cursor X (chars)
.cursorY:
	dd   0 ; cursor Y (chars)

hello_str:
	db "Hello world"

font6x10:
%include "../mkcd/font.asm"

