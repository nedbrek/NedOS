%include "mmap.asm"

PAGE_PRESENT   equ   1
PAGE_WRITE     equ   2
PAGE_SUPER     equ   4

PAGE_LEN       equ   0x01000

	org 0x7e00

	bits 64

	; update page tables
	mov esi, PAGE_BASE

	;; install pds for 1..2, 2..3 and 3..4 G
	mov [rsi+PAGE_LEN+1*8], DWORD ((PAGE_BASE + 3*PAGE_LEN) \
                    |PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)
	mov [rsi+PAGE_LEN+2*8], DWORD ((PAGE_BASE + 4*PAGE_LEN) \
                    |PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)
	mov [rsi+PAGE_LEN+3*8], DWORD ((PAGE_BASE + 5*PAGE_LEN) \
                    |PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)

	;; install VRAM pages
	;;; get the video mem base
	mov  eax, [BOOT_PARMS+0x10]
	;Ned set WC
	call add_2M_page
	;;; leaves eax pointing to the pde

	;;; need two for 4 MB VRAM
	add eax, 0x20_0000 |0x80|PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER
	mov [rsi+8], eax

	;; flush TLB
	mov rax, cr3
	mov cr3, rax

	; find ACPI tables (RSDP)
	;; there is no well known addr, must search for the key
	mov rax, 'RSD PTR '

	;; look in EBDA
	movzx edi, WORD [0x40e] ; EBDA paragraph addr
	shl edi, 4 ; convert to linear

	mov ecx, 0xa0000 ; stop at top of free mem
	sub ecx, edi ; byte count
	shr ecx, 3 ; we will scan 8 B per

	cld
	repne scasq ; search!
	je acpi_found ; yea!

	;;else look in BIOS high mem
	mov edi, 0xe_0000
	mov ecx, (0x10_0000 - 0xe_0000) >> 3
	repne scasq
	jne panic ; oh no

acpi_found:
	; RSDP is at edi-8 (scas leaves things for next)
	; RSDT is at offset 16
	mov edi, [rdi-8+16]

	;; likely need a new page to get at it
	mov eax, edi
	mov esi, PAGE_BASE
	call add_2M_page

	; find IOAPIC
	mov ebx, 32

.next_tbl:
	add ebx, 4
	mov esi, [rdi+rbx]
	cmp DWORD [rsi], 'APIC'
	jnz .next_tbl

.found_apic:
	mov ebx, 44

	mov eax, [rsi+rbx]
	cmp al, 1 ; want IOAPIC
	je .found_ioapic

	;; add proc apic offset
	shr eax, 8
	and eax, 0xff
	add ebx, eax

	mov eax, [rsi+rbx]
	cmp al, 1 ; still looking for IOAPIC
	jne panic

.found_ioapic:
	mov edi, [rsi+rbx+4]

	;; map it in
	mov eax, edi
	mov esi, PAGE_BASE
	call add_2M_page

	; fill the 16 legacy INT redirects
	mov ecx, 16

.next_ioredir:
	dec ecx

	;; access reg[ecx*2+16]
	mov eax, ecx
	add eax, eax
	add eax, 16
	mov DWORD [rdi], eax

	mov edx, ecx
	or  edx, 0x0000_a0f0
	mov DWORD [rdi+16], edx

	test ecx, ecx
	jnz .next_ioredir

	; disable pic
	mov al, 0xff
	out 0xa1, al
	out 0x21, al

	xchg bx,bx
	; fill IDT
	;; skip entries 00..EF (for now)
	mov edi, IDT_BASE+0xF0*16

	xchg bx,bx
	mov edx, isr_dev_nop

	;; mov high offset to second dword
	mov eax, edx
	mov  ax, 0x8e01

	shl rax, 32

	and edx, 0xffff
	or  rax, rdx ; grab low offset
	bts rax, 19  ; set code seg

	xor ecx, ecx

	;; irq0
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq1
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq2
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq3
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq4
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq5
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq6
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq7
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq8
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq9
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq10
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq11
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq12
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq13
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq14
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	;; irq15
	mov [rdi+rcx*8], rax
	inc ecx
	inc ecx

	lidt [idt]

	; build TSS
	;; descriptor
	mov edi, GDT_BASE

	;;; first put in user segments
	;;;; user code (64 bit)
	mov [rdi+0x1c], DWORD 0x00e0_f900
	;;;; user data
	mov [rdi+0x24], DWORD 0x00c0_f300

	;;; TSS descriptor (limit 104, base[15:0] in high word
	mov [rdi+0x28], DWORD 0x68|((TSS_BASE&0xffff)<<16)
	;;; (type, base[23:16] in low word, TSS restricted to 16M)
	mov [rdi+0x2c], DWORD 0x8900|((TSS_BASE&0xff0000) >> 16)

	;; fill in TSS data
	mov edi, TSS_BASE

	;;; stack pointers for rings 0,1,2 (set to low reclaim (0x500) for now)
	mov [rdi+ 5], BYTE 0x5
	mov [rdi+13], BYTE 0x5
	mov [rdi+21], BYTE 0x5

	;;; stack pointers 1..7 for interrupts (use area just below BOB)
	mov [rdi+36], DWORD BOOT_PARMS
	mov [rdi+44], DWORD BOOT_PARMS
	mov [rdi+52], DWORD BOOT_PARMS
	mov [rdi+60], DWORD BOOT_PARMS
	mov [rdi+68], DWORD BOOT_PARMS
	mov [rdi+76], DWORD BOOT_PARMS
	mov [rdi+84], DWORD BOOT_PARMS

	mov ax, 0x28
	ltr ax

	; add a pte for the EOI
	mov eax, 0xfee0_0000
	mov esi, PAGE_BASE
	call add_2M_page

	xchg bx,bx
	; enable APIC
	mov edi, 0xfee0_00f0
	mov DWORD [rdi], 0x100 ; write SVR

	sti

	; draw a character

	; success, aqua screen of life
	mov  rax, 0x0000_FF00_0000_00FF
	call fill_screen

	; clear a terminal box
	xor eax, eax    ; pixel color
	mov ecx, 80*6   ; rect width (80 chars in px)
	mov edi, 50*10*4; y coord (50 chars in bytes)
	mov edx, 80*6*4 ; x coord (80 chars in bytes)
	mov ebx, 25*10  ; height, 25 chars
	call fill_rect

	; printf Hello world (in white)
	mov eax, 0xffff_ffff
	mov rdx, hi_str
	mov esi, termLR_ctx
	call vputs

	; again (test newline code)
	mov rdx, hi_str
	call vputs

	jmp die

idt:
	dw 4095
	dq IDT_BASE

isr_dev_nop:
	; empty interrupt handler for devices
	inc r9
	push rax
	mov rax, 0xfee0_00b0
	mov DWORD [rax], 0 ; write EOI
	pop rax
	db 0x48
	iret

add_2M_page:
	; IN eax - vaddr to add a page for
	; IN esi - start of page table (CR3)
	; OUT eax - addr of pde
	xchg bx, bx
	push rdi

	mov edi, eax

	;;; find top two bits (pd offset)
	shr eax, 30

	;;; add two for pd offset
	inc eax ; shift past PML4
	inc eax ; shift past pdp

	;;; multiply by PAGE_LEN
	shl eax, 12

	add esi, eax ; done pd offset

	;;; get pde (bits 29..21)
	mov eax, edi
	shr eax, 21
	and eax, 0x1ff

	shl eax, 3 ; scale for pde size

	add esi, eax ; add pde offset

	;;; build pde
	mov eax, edi
	and eax, 0xffe0_0000
	or  eax, 0x80|PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER
	mov [rsi], eax

	mov eax, edi
	pop rdi
	ret

fill_row:
	; IN eax - pixel to fill
	; IN rcx - width in pixels
	; IN edi - y coord (row num)
	; IN edx - x coord (px, ie. col*4)
	; OUT ecx - 0
	; OUT edi - pixel after last in row

	;; scale y coord by screen width
	imul edi, [BOOT_PARMS+4]

	;; add x coord
	add  edi, edx

	;; add to lfb base
	add  edi, [BOOT_PARMS+0x10]

	rep stosd

	ret

vputc:
	; IN rax - color (high bits bg)
	; IN rdx - char code
	; IN esi - context ptr
	; OUT edx - zero
	push rbp
	push rdi
	push rbx
	push rcx

	cmp edx, 10
	je .next_row

	sub edx, 32
	mov rdx, [rdx*8+space]

.normal:
	; get upper right of char
	;; lfb + (console.y + cursor.y * 10) * screen.width +
	;; console.x + cursor.x * 6

	;;; edi = cursor.y * 10
	imul edi, [rsi+20], 10
	;;; edi += console.y
	add  edi, [rsi+ 4]

	;;; ebx = screen.width
	mov ebx, [BOOT_PARMS+4]

	;;; edi = (console.y + cursor.y * 10) * screen.width
	imul edi, ebx

	;;; ecx = cursor.x * 6 + console.x
	imul ecx, [rsi+16], 6
	add  ecx, [rsi]

	add edi, ecx

	;; scale px to bytes
	shl edi, 2

	;; add to lfb base
	add  edi, [BOOT_PARMS+0x10]

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

	add edi, 4
	dec ecx
	jnz .put_px

	;; wrap to next row (add screen_width - 6)
	add edi, ebx
	dec ebp
	jnz .put_row

	; update cursor
	mov ebx, [rsi+16]
	mov ecx, [rsi+20]

	xchg bx,bx
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

.done:
	mov [rsi+16], ebx
	mov [rsi+20], ecx

	pop rcx
	pop rbx
	pop rdi
	pop rbp
	ret

vputs:
	; IN rax - color (high bits bg)
	; IN rdx - char*
	; IN esi - context ptr

	xchg bx,bx
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

fill_rect:
	; IN eax - pixel to fill
	; IN rcx - width in pixels
	; IN edi - y coord (bytes)
	; IN edx - x coord (bytes, ie. col*4)
	; IN ebx - height
	xchg bx,bx

	push rsi
	;; save width
	push rcx

	;; get screen width
	mov esi, [BOOT_PARMS+4]

	;; scale y coord by screen width
	imul edi, esi

	;; subtract the row width
	sub esi, ecx
	;; scale to pixels
	shl esi, 2

	;; add x coord
	add  edi, edx

	;; add to lfb base
	add  edi, [BOOT_PARMS+0x10]

.fill_row:
	rep stosd
	dec ebx
	jz .end

	add edi, esi
	mov ecx, [rsp]
	jmp .fill_row

.end:
	pop rcx
	pop rsi
	ret

fill_screen:
	; IN rax - color to fill
	; OUT rdx - screen width
	; OUT rcx - 0
	; OUT rdi - end of screen mem
	mov  edx, [BOOT_PARMS+4]
	mov  ecx, [BOOT_PARMS+8]
	imul ecx, edx
	shr  ecx, 1 ; we will write 2 pixels per

	;; write
	mov  edi, [BOOT_PARMS+0x10]
	rep stosq
	ret

panic:
	; stack may be trashed
	mov rsp, 0x7c00
	; show red screen of death
	mov  rax, 0x00FF_0000_00FF_0000
	call fill_screen

	; loop forever
die:
	inc rax
	jmp die

termLR_ctx:
	dd 480 ; console x pos (px)
	dd 500 ; console y pos (px)
	dd  50 ; width (chars)
	dd  25 ; height (chars)
	dd   0 ; cursor X (chars)
	dd   0 ; cursor Y (chars)

hi_str:
	db "Hello, world",10,0

cap_h: ; 72
	dq 0x228A2FA28A2000

%include "font.asm"

