; use RIP relative addressing
default rel

bits 64

%include "bob.asm"
extern bob

global kernel_main
kernel_main:
	cli

	; TODO fill IDT
	xor ecx, ecx
	lea rdi, [idt]

	;; INT0 divide error
	lea rdx, [isr_print0]
	call write_isr_to_idt

	;; INT1 reserved
	inc ecx
	inc ecx
	lea rdx, [isr_print1]
	call write_isr_to_idt

	;; INT2 NMI
	inc ecx
	inc ecx
	lea rdx, [isr_print2]
	call write_isr_to_idt

	;; INT3 breakpoint
	inc ecx
	inc ecx
	lea rdx, [isr_print3]
	call write_isr_to_idt

	;; INT4 overflow
	inc ecx
	inc ecx
	lea rdx, [isr_print4]
	call write_isr_to_idt

	;; INT5 bound
	inc ecx
	inc ecx
	lea rdx, [isr_print5]
	call write_isr_to_idt

	;; INT6 invalid opcode
	inc ecx
	inc ecx
	lea rdx, [isr_print6]
	call write_isr_to_idt

	;; INT7 math coprocessor not present
	inc ecx
	inc ecx
	lea rdx, [isr_print7]
	call write_isr_to_idt

	;; INT8 double fault
	inc ecx
	inc ecx
	lea rdx, [isr_print8]
	call write_isr_to_idt

	;; INT9 coprocessor seg fault
	inc ecx
	inc ecx
	lea rdx, [isr_print9]
	call write_isr_to_idt

	;; INT10 invalid TSS
	inc ecx
	inc ecx
	lea rdx, [isr_print10]
	call write_isr_to_idt

	;; INT11 seg fault
	inc ecx
	inc ecx
	lea rdx, [isr_print11]
	call write_isr_to_idt

	;; INT12 stack seg fault
	inc ecx
	inc ecx
	lea rdx, [isr_print12]
	call write_isr_to_idt

	;; INT13 general protection fault
	inc ecx
	inc ecx
	lea rdx, [isr_print13]
	call write_isr_to_idt

	;; INT14 page fault
	inc ecx
	inc ecx
	lea rdx, [isr_print14]
	call write_isr_to_idt

	;; INT15 reserved
	inc ecx
	inc ecx
	lea rdx, [isr_print15]
	call write_isr_to_idt

	;; irq0
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq1
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq2
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq3
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq4
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq5
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq6
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq7
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq8
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq9
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq10
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq11
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq12
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq13
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq14
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;; irq15
	inc ecx
	inc ecx
	lea rdx, [isr_dev_nop]
	call write_isr_to_idt

	;;; load idt
	lidt [idt]

	; TODO? config IOAPIC?
	; TODO? config TSS?

	; blank screen
	mov  rax, 0x0000_FF00_0000_00FF ; aqua - alternate red and green
	call fill_screen

	; clear a terminal box
	mov rsi, termLR_ctx

	xor eax, eax ; background color - black
	call fill_term

	; print memory
	xor ebx, ebx
	xor ecx, ecx
	mov rdi, [bob+Bob.freeList]
.mem_top:
	test rdi, rdi
	jz .mem_end
	inc ebx
	add rcx, [rdi+8]
	mov rdi, [rdi]
	jmp .mem_top

.mem_end:
	mov eax, 0xffffffff

	lea rdx, [mem_sections]
	call vputs

	mov rdx, rcx
	call vputQWord

	lea rdx, [mem_sections2]
	call vputs

	mov rdx, rbx
	call vputQWord

	mov dl, 10
	call vputc

	; print hello world
	lea rdx, [hello_str]
	call vputs

	sfence

	; loop forever
.die:
	hlt
	jmp .die

panic:
	mov rsp, 0x7c00
	mov rax, 0x00FF_0000_00FF_0000 ; red screen of death
	call fill_screen

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

vputNibble:
	; IN  rax - color
	; IN  dl  - value 0-15 (hex digit)
	; IN  rsi - terminal context ptr
	; OUT dl  - ASCII value of dl
	cmp dl, 9
	jbe .printLo

	add dl, 'A'-10
	jmp .done

.printLo:
	add dl, '0'

.done:
	call vputc
	ret

vputByte:
	; IN  rax - color
	; IN  dl  - byte
	; IN  rsi - context ptr
	; OUT dl  - ASCII value of low nibble
	push rdx

	shr dl, 4
	call vputNibble

	pop rdx
	and dl, 0xf
	call vputNibble

	ret

vputWord:
	; IN  rax - color
	; IN  dx - word
	; IN  rsi - context ptr
	; OUT dl - ASCII value of lowest nibble
	push rdx
	shr edx, 8
	call vputByte

	pop rdx
	and edx, 0xff
	call vputByte

	ret

vputDWord:
	; IN  rax - color
	; IN  edx - dword
	; IN  rsi - context ptr
	; OUT dl  - ASCII value of lowest nibble
	push rdx
	shr edx, 16
	call vputWord

	pop rdx
	and edx, 0xffff
	call vputWord

	ret

vputQWord:
	; IN  rax - color
	; IN  rdx - qword
	; IN  rsi - context ptr
	; OUT dl  - ASCII value of lowest nibble
	push rdx
	shr rdx, 32
	call vputDWord

	pop rdx
	call vputDWord

	ret

; interrupt handlers
isr_print:
	lea rsi, [termLR_ctx]
	mov eax, 0xffff_ffff
	call vputByte

.done:
	hlt
		jmp .done

isr_print0:
	mov dl, 0
	jmp isr_print

isr_print1:
	mov dl, 1
	jmp isr_print

isr_print2:
	mov dl, 2
	jmp isr_print

isr_print3:
	mov dl, 3
	jmp isr_print

isr_print4:
	mov dl, 4
	jmp isr_print

isr_print5:
	mov dl, 5
	jmp isr_print

isr_print6:
	mov dl, 6
	jmp isr_print

isr_print7:
	mov dl, 7
	jmp isr_print

isr_print8:
	mov dl, 8
	jmp isr_print

isr_print9:
	mov dl, 9
	jmp isr_print

isr_print10:
	mov dl, 10
	jmp isr_print

isr_print11:
	mov dl, 11
	jmp isr_print

isr_print12:
	mov dl, 12
	jmp isr_print

isr_print13:
	mov dl, 13
	jmp isr_print

isr_print14:
	mov dl, 14
	jmp isr_print

isr_print15:
	mov dl, 15
	jmp isr_print

isr_dev_nop:
	; empty interrupt handler for devices
	push rax
	mov rax, 0xfee0_00b0
	mov DWORD [rax], 0 ; write EOI
	pop rax
	iretq

write_isr_to_idt:
	; IN  rdx - address of isr
	; IN  rdi - address of idt
	; IN  ecx - vector number * 2
	; OUT eax - IDT value
	push rdx

	; grab low bits
	mov rax, rdx ; copy input
	and edx, 0xffff
	bts edx, 19 ; code segment 1 (1000 with ring and local/global)

	; build 64 bit IDT entry
	;; bits[31:16] are the high bits of isr
	;; bits[16:00] are the properties
	mov ax, 0x8e01 ; present, ring 0, INT, IST=1

	;; move bits [31:0] up to [63:32]
	shl rax, 32

	;; bring in low bits
	or rax, rdx

	; write the IDT
	mov [rdi + rcx * 8], rax

	pop rdx
	ret

; data
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
	db "Hello world", 0

mem_sections:
	db "Total memory ", 0

mem_sections2:
	db " section ct: ", 0

font6x10:
%include "../mkcd/font.asm"

idt:
	dw 4095
	dq idt

