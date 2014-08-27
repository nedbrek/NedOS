%include "../mkcd/mmap.asm"
%include "../mkcd/bob.asm"

; constants (for page table bits)
PAGE_PRESENT   equ   1
PAGE_WRITE     equ   2
PAGE_SUPER     equ   4

PAGE_LEN       equ   0x01000

; Start
; Boot loader places us two blocks down (1024 B)
; - we are in 64 bit mode, with limited page tables and interrupts off
; - screen resolution has been set via VBE, info in the BOB
; - memmap (INT15) info is in the BOB
	org 0x8000
	bits 64

start:
	; enable caches
	mov rax, cr0
	btr eax, 30
	btr eax, 29
	mov cr0, rax
	wbinvd

	; update page tables
	mov esi, PAGE_BASE

	;; install pds for 1..2, 2..3, and 3..4 G
	mov [rsi+PAGE_LEN+1*8], DWORD ((PAGE_BASE + 3*PAGE_LEN) \
	                 |PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)
	mov [rsi+PAGE_LEN+2*8], DWORD ((PAGE_BASE + 4*PAGE_LEN) \
	                 |PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)
	mov [rsi+PAGE_LEN+3*8], DWORD ((PAGE_BASE + 5*PAGE_LEN) \
	                 |PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)

	;; install VRAM pages
	;;; get the video mem base
	mov  eax, [BOOT_PARMS+Bob.vgaLFBP]
	;;; set WC (memory type UC-, PAT=2)
	xor edx, edx
	mov dl, 0x10 ; set PCD=1, PWT=0
	call add_2M_page
	;;; leaves rsi with address of pde

	;;; need two for 4 MB VRAM (also UC-)
	and eax, 0xffe0_0000 ; clear low bits
	add eax, 0x20_0010 |0x80|PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER
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
	xor edx, edx
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

.next_entry:
	mov eax, [rsi+rbx]
	cmp al, 1 ; want IOAPIC
	je .found_ioapic

	;; add offset
	shr eax, 8
	and eax, 0xff
	add ebx, eax
	jmp .next_entry

.found_ioapic:
	mov edi, [rsi+rbx+4]

	;; map it in
	mov eax, edi
	mov esi, PAGE_BASE
	xor edx, edx
	mov dl, 0x18 ; UC page
	call add_2M_page

program_ioapic:
	; fill the 16 legacy INT redirects
	mov ecx, 16
	xor edx, edx

.next_ioredir:
	dec ecx
	mov dh, [ioapic_flags+rcx]
	mov dl, cl
	or  dl, 0xf0
	call write_ioredir
	test cl, cl
	jnz .next_ioredir

	; disable pic
	mov al, 0xff
	out 0xa1, al
	out 0x21, al

	; disable pit
	mov al, 0x10
	out 0x43, al

	; fill IDT
	xor ecx, ecx
	mov edi, IDT_BASE

	;; INT0 divide error
	mov edx, isr_print0
	call write_isr_to_idt

	;; INT1 reserved
	inc ecx
	inc ecx
	mov edx, isr_panic
	call write_isr_to_idt

	;; INT2 NMI
	inc ecx
	inc ecx
	mov edx, isr_print2
	call write_isr_to_idt

	;; INT3 breakpoint
	inc ecx
	inc ecx
	mov edx, isr_print3
	call write_isr_to_idt

	;; INT4 overflow
	inc ecx
	inc ecx
	mov edx, isr_print4
	call write_isr_to_idt

	;; INT5 bound
	inc ecx
	inc ecx
	mov edx, isr_print5
	call write_isr_to_idt

	;; INT6 invalid opcode
	inc ecx
	inc ecx
	mov edx, isr_print6
	call write_isr_to_idt

	;; INT7 math coprocessor not present
	inc ecx
	inc ecx
	mov edx, isr_print7
	call write_isr_to_idt

	;; INT8 double fault
	inc ecx
	inc ecx
	mov edx, isr_panic
	call write_isr_to_idt

	;; INT9 coprocessor seg fault
	inc ecx
	inc ecx
	mov edx, isr_print9
	call write_isr_to_idt

	;; INT10 invalid TSS
	inc ecx
	inc ecx
	mov edx, isr_print10
	call write_isr_to_idt

	;; INT11 seg fault
	inc ecx
	inc ecx
	mov edx, isr_print11
	call write_isr_to_idt

	;; INT12 stack seg fault
	inc ecx
	inc ecx
	mov edx, isr_print12
	call write_isr_to_idt

	;; INT13 general protection fault
	inc ecx
	inc ecx
	mov edx, isr_print13
	call write_isr_to_idt

	;; INT14 page fault
	inc ecx
	inc ecx
	mov edx, isr_print14
	call write_isr_to_idt

	;; INT15 reserved
	inc ecx
	inc ecx
	mov edx, isr_panic
	call write_isr_to_idt

	;; skip entries 10..EF (for now)
	mov edi, IDT_BASE+0xF0*16

	;; irq0
	mov edx, isr_dev_nop
	xor ecx, ecx
	call write_isr_to_idt

	;; irq1 (keyboard)
	mov edx, isr_mouse_keyb
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq2
	mov edx, isr_dev_nop
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq3
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq4
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq5
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq6
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq7
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq8
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq9
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq10
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq11
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq12 (mouse)
	mov edx, isr_dev_nop
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq13
	mov edx, isr_dev_nop
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq14
	inc ecx
	inc ecx
	call write_isr_to_idt

	;; irq15
	inc ecx
	inc ecx
	call write_isr_to_idt

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
	xor edx, edx
	mov dl, 0x18 ; UC page
	call add_2M_page

	; enable APIC
	mov edi, 0xfee0_00f0
	mov DWORD [rdi], 0x100 ; write SVR

	sti

	; success, aqua screen of life
	mov  rax, 0x0000_FF00_0000_00FF
	call fill_screen

	; clear a terminal box
	mov esi, termLR_ctx

	xor eax, eax ; pixel color
	call fill_term
	sfence

	; TODO install RAM
	mov QWORD [BOOT_PARMS+Bob.freeList], 1024*1024 ; freeList = 1M
	mov QWORD [1024*1024], 0 ; no next ptr
	mov QWORD [1024*1024+8], 1024*1024 ; size = 1M

	; allocate command buffer
	mov eax, 512
	call BasicString~new@int

	xor ebp, ebp

.done:
	; print key codes
	mov edi, [QUEUE_START]

.wait:
	test BYTE [rdi*2+INPUT_QUEUE+1], 1
	jz .wait

	;; get the code
	xor  eax, eax
	mov  al, [rdi*2+INPUT_QUEUE]

	;; clear the buffer
	mov  WORD [rdi*2+INPUT_QUEUE], 0

	;; move along
	inc edi
	and edi, 0xfff
	mov [QUEUE_START], edi

	;; skip break codes
	test al, 0x80
	jnz .wait

	;; actually print
	mov edx, eax
	mov eax, 0xffff_ffff
	call vputByte
	sfence
	jmp .done
	; end

; data
idt:
	dw 4095
	dq IDT_BASE

ioapic_flags:
	; edge / level, high / low (ready to poke)
	db 00 ; IRQ 0
	db 00 ; IRQ 1
	db 00 ; IRQ 2
	db 00 ; IRQ 3
	db 00 ; IRQ 4
	db 00 ; IRQ 5
	db 00 ; IRQ 6
	db 00 ; IRQ 7
	db 00 ; IRQ 8
	db 00 ; IRQ 9
	db 00 ; IRQ 10
	db 00 ; IRQ 11
	db 00 ; IRQ 12
	db 00 ; IRQ 13
	db 00 ; IRQ 14
	db 00 ; IRQ 15

; functions
isr_print:
	mov esi, termLR_ctx
	mov eax, 0xffff_ffff
	call vputByte

.done:
	hlt
	jmp .done

write_ioredir:
	; IN  ecx redir reg
	; IN  edx value
	; IN  edi IOAPIC space
	; OUT eax trash
	;; access reg[ecx*2+16]
	mov eax, ecx
	add eax, eax
	add eax, 16
	mov DWORD [rdi], eax

	mov [rdi+16], edx
	ret

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

; page fault
isr_print14:
	mov esi, termLR_ctx
	mov eax, 0xffff_ffff
	xor edx, edx

	mov dl, 14
	call vputByte
	mov dl, 10
	call vputc

	;; error code
	mov edx, [rsp]
	call vputDWord
	mov edx, 10
	call vputc

	;; EIP of faulting instruction
	mov edx, [rsp+8]
	call vputDWord
	mov edx, 10
	call vputc

	;; CS of faulting instruction
	mov edx, [rsp+16]
	call vputDWord
	mov edx, 10
	call vputc

	;; faulting address
	mov rax, cr2
	mov rdx, rax
	call vputQWord
	mov edx, 10
	call vputc

.done:
	hlt
	jmp .done

isr_print15:
	mov dl, 15
	jmp isr_print

isr_panic:
	jmp panic

isr_dev_nop:
	; empty interrupt handler for devices
	push rax
	mov rax, 0xfee0_00b0
	mov DWORD [rax], 0 ; write EOI
	pop rax
	iretq

isr_mouse_keyb:
	; interrupt handler for mouse and keyboard
	push rax

	; get the status and data bytes
	xor eax, eax

	; status, bit 0 tells ready
	in   al, 0x64
	test al, 1
	jz   .end ; not ready, spurious int

	; insert at end of input queue
	;; check for overflow
	push rdi

	;;; if slot occupied
	mov  edi, [QUEUE_END]
	test BYTE [rdi*2+INPUT_QUEUE+1], 1
	jnz  panic

	;; get the next byte
	mov  ah, al
	in   al, 0x60

	;; do the write
	mov [rdi*2+INPUT_QUEUE], ax

	;; update the end of queue pointer
	inc edi
	and edi, 0xfff
	mov [QUEUE_END], edi

	pop rdi

.end:
	mov rax, 0xfee0_00b0
	mov DWORD [rax], 0 ; write EOI

	pop rax
	iretq

add_2M_page:
	; IN  eax - vaddr to add a page for
	; IN  esi - start of page table (CR3)
	; IN  edx - additional flags
	; OUT esi - addr of pde

	; save incoming eax
	push rdi
	mov edi, eax

	; make esi point to proper pd
	;; find top two bits (pd offset)
	shr eax, 30

	;; add two for pd offset
	inc eax ; shift past PML4
	inc eax ; shift past pdp

	;; multiply by PAGE_LEN
	shl eax, 12

	add esi, eax ; done pd offset

	; get offset into pd (eax[29:21])
	mov eax, edi ; restore eax
	shr eax, 21 ; bits 21..29
	and eax, 0x1ff
	lea esi, [esi + eax*8] ; shift to the proper directory entry

	; build identity pde
	mov eax, edi ; restore eax
	and eax, 0xffe0_0000 ; clear low bits
	or  eax, 0x80|PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER
	or  eax, edx
	mov [rsi], eax

	mov eax, edi ; restore eax

	pop rdi
	ret

malloc:
	; IN  eax - size (don't malloc more than 4GB!)
	; OUT rax - addr of block
	push rdi
	push rsi
	push rcx

	mov  rsi, [BOOT_PARMS+Bob.freeList]
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

	mov [BOOT_PARMS+Bob.freeList], rsi ; update free list

	jmp .end

.next_block: ; Ned, implement
	xor eax, eax ; return NULL for now

.end:
	pop  rcx
	pop  rsi
	pop  rdi
	ret

free:
	; IN rax - address of free block
	; IN ecx - size of block (see malloc about 4GB)
	push rdi

	mov rdi, [BOOT_PARMS+Bob.freeList]
	mov [rax], rdi
	mov [rax+8], rcx

	mov [BOOT_PARMS+Bob.freeList], rax

	pop  rdi
	ret

drawChar:
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
	mov ebx, [BOOT_PARMS+Bob.vgaWidth]

	;;; edi = (console.y + cursor.y * 10) * screen.width
	imul edi, ebx

	;;; ecx = cursor.x * 6 + console.x
	imul ecx, [rsi+16], 6
	add  ecx, [rsi]

	add edi, ecx

	;; scale px to bytes
	shl edi, 2

	;; add to lfb base
	add  edi, [BOOT_PARMS+Bob.vgaLFBP]

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
	mov rdx, [rdx*8 + font6x10.space]

	call drawChar

.updateCursor:
	call cursorRight

	pop rcx
	pop rbx
	pop rdi
	pop rbp
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

vputNibble:
	; IN  rax - color
	; IN  dl  - value 0-15
	; IN  esi - context ptr
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
	; IN  esi - context ptr
	; OUT dl  - ASCII value of low nibble
	push rdx

	shr dl, 4
	call vputNibble

	pop  rdx
	and dl, 0xf
	call vputNibble

	ret

vputWord:
	; IN  rax - color
	; IN  dx  - word
	; IN  esi - context ptr
	; OUT dl  - ASCII value of lowest nibble
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
	; IN  esi - context ptr
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
	; IN  esi - context ptr
	; OUT dl  - ASCII value of lowest nibble
	push rdx
	shr rdx, 32
	call vputDWord

	pop rdx
	call vputDWord

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
	mov esi, [BOOT_PARMS+Bob.vgaWidth]

	; scale y coord by screen width
	imul edi, esi

	; subtract the row width
	sub esi, ecx
	; scale to pixels
	shl esi, 2

	; add x coord
	add  edi, edx

	; add to lfb base
	add  edi, [BOOT_PARMS+Bob.vgaLFBP]

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
	; IN  rax - color to fill
	; OUT rdx - screen width
	; OUT rcx - 0
	; OUT rdi - end of screen mem
	mov  edx, [BOOT_PARMS+Bob.vgaWidth]
	mov  ecx, [BOOT_PARMS+Bob.vgaHeight]
	imul ecx, edx
	shr  ecx, 1 ; we will write 2 pixels per

	;; write
	mov  edi, [BOOT_PARMS+Bob.vgaLFBP]
	rep  stosq

	ret

write_isr_to_idt:
	; IN  edx - address of isr
	; IN  rdi - address of idt
	; IN  ecx - vector number * 2
	; OUT eax - IDT value
	push rdx

	mov eax, edx

	; save low bits of &isr
	and edx, 0xffff
	bts edx, 19 ; set for code segment 8 (entry 1 in GDT)

	; build a 64 bit IDT entry
	;; bits [31:16] are the high bits of &isr
	;; bits [16:00] are the properties
	mov  ax, 0x8e01 ; present, ring 0, INT, IST=1

	;; move bits [31:0] up to [63:32]
	shl rax, 32

	;; bring in low bits
	or  rax, rdx

	; write the IDT
	mov [rdi+rcx*8], rax

	pop  rdx
	ret

panic:
	; stack may be trashed
	mov rsp, 0x7c00
	; show red screen of death
	mov  rax, 0x00FF_0000_00FF_0000
	call fill_screen

	; loop forever
.die:
	hlt
	jmp .die

Vector~init@int:
	; IN  eax - initial buffer size
	; IN  ecx - this
	; trashed eax
	mov DWORD [rcx+Vector.len], 0
	mov [rcx+Vector.cap], eax

	call malloc
	mov [rcx+Vector.ary], rax
	ret

BasicString~new@int:
	; IN  eax - initial buffer size
	; OUT rax - ptr to string
	; OUT r9  - also a ptr to string
	push rax

	mov  eax, BasicString_size
	call malloc
	mov  r9, rax
	mov DWORD [rax+BasicString.vtbl], 0
	mov DWORD [rax+BasicString.ref], 1

	lea  rcx, [rax+BasicString.vec]
	pop  rax

	call Vector~init@int

	mov rax, r9
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
	db "Hello world", 0

keymap:
%include "../mkcd/keymap.asm"

font6x10:
%include "../mkcd/font.asm"

