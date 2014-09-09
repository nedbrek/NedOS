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

check_memmap:
	mov edi, MMAP_BASE-24

.top:
	add edi, 24
	mov ebx, [rdi+16] ; mem type

	test ebx, ebx
	jz .done ; zero -> done

	cmp ebx, 1 ; normal
	jnz .top

	call install_ram

	jmp .top

.done:

	; allocate command buffer
	mov eax, 512
	call BasicString~new@int

	mov eax, 8*8 ; eight substring ptr (far)
	call malloc
	mov r10, rax

	mov edx, 7

.alloc_parms:
	xor ebx, ebx
	xor ecx, ecx
	call SubStringNearShort~new
	mov [r10+rdx*8], rax

	dec dl
	jns .alloc_parms

	mov esi, termLR_ctx

runCmd:
	; print prompt
	mov eax, 0xffff_ffff
	xor edx, edx
	mov dl, '%'
	call vputc

	mov dl, ' '
	call vputc

	xor rax, rax
	mov ecx, INPUT_QUEUE_SIZE >> 3
	mov edi, INPUT_QUEUE
	rep stosq

	call BasicString~clear

	xor ebp, ebp

check_keyboard:
	; eax - scratch
	; ebx - escape flag
	; edx - char tmp
	; edi - queue ptr
	; esi - term ctxt
	; ebp - count
	; r9  - command buffer this
	; r10 - base of parameter substring array
	xor ebx, ebx ; escape flag
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

	cmp  al, 0xe0 ; escape code
	jz .escape_start

	;; skip break codes
	test al, 0x80
	jnz  check_keyboard

	; if escape code
	test bl, bl
	jnz  .escape_code ; handle it

	jmp .print ; else, just print

.escape_start:
	inc ebx ; set escape flag

	jmp .wait ; fetch next code

.escape_code:
	; check for funky codes
	cmp al, 0x2a ; fake LShift
	jz check_keyboard

	cmp al, 0x36 ; fake RShift
	jz check_keyboard

	cmp al, 0x37 ; Ctrl+PrintScreen
	jz check_keyboard

	cmp al, 0x46 ; Ctrl+Break
	jz check_keyboard

.print:
	xor edx, edx
	mov dl, [keymap+rax] ; map from scan code to ASCII

	cmp dl, 10 ; check for new line
	jz .doRunCmd

	cmp dl, 8 ; backspace
	jz .larrow_bs

	cmp dl, 0x1a ; left arrow
	jz .larrow_bs

	cmp dl, 32 ; check for unprintable
	jb check_keyboard

	cmp dl, 127 ; DEL
	jz check_keyboard

	jmp .actual_print

.larrow_bs:
	; decrement position
	;; check for position 0
	test ebp, ebp
	jz   check_keyboard

	;; shift pointer
	dec ebp

	call cursorLeft

	; for backspace, erase current character
	cmp dl, 8
	jnz check_keyboard

	mov rdx, 0x0fff_ffff_ffff_ffff
	xor eax, eax
	call drawChar
	sfence

	jmp check_keyboard

.actual_print:
	cmp ebp, [r9+BasicString.vec+Vector.len]
	jae .append

	; buffer ptr
	mov eax, [r9+BasicString.vec+Vector.ary]

	; overwrite current spot
	mov [rax+rbp], dl
	mov rdx, 0x0fff_ffff_ffff_ffff
	xor eax, eax
	call drawChar

	; restore char
	xor edx, edx
	mov eax, [r9+BasicString.vec+Vector.ary]
	mov dl, [rax+rbp]

	jmp .final_print

.append:
	call BasicString~appendChar

.final_print:
	mov eax, 0xffff_ffff
	call vputc
	sfence

	inc ebp ; bump count
	jmp check_keyboard

.doRunCmd:
	; print the eol
	xor eax, eax
	call vputc

	; TODO Ned, process command
	call parseArgs

	jmp runCmd
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

pci_read1:
	; IN  eax pci addr
	; OUT eax value
	; OUT edx 0xcfc
	xor edx, edx
	mov dx, 0xcf8
	out dx, eax

	or  dl, 4
	xor eax, eax
	in  al, dx

	ret

pci_read2:
	; IN  eax pci addr
	; OUT eax value
	; OUT edx 0xcfc
	xor edx, edx
	mov dx, 0xcf8
	out dx, eax

	or  dl, 4
	xor eax, eax
	in  ax, dx

	ret

pci_read4:
	; IN  eax pci addr
	; OUT eax value
	; OUT edx 0xcfc
	xor edx, edx
	mov dx, 0xcf8
	out dx, eax

	or  dl, 4
	in  eax, dx

	ret

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

install_ram:
	; IN  rdi - ACPI table entry
	; IN  esi - term context
	; IN  eax - print color
	; OUT rdx - trashed
	; OUT rbx - trashed
	; OUT rcx - trashed
	mov rdx, [rdi] ; load base

	; check for blocks below 1 MB
	mov ebx, 0x10_0000 ; 1MB
	cmp rdx, rbx
	jb .end ; ignore them

	; now we need to handle 1MB-2MB, which is problematic (it is covered by the 1M table)
	mov ebx, 0x20_0000 ; 2MB
	cmp rdx, rbx
	ja .trimBase ; region starts above 2M

	add rdx, [rdi+8] ; size
	cmp rdx, rbx
	jbe .end ; region ends at or below 2M

	sub ebx, [rdi]     ; find how much is below 2M
	sub [rdi+8], rbx   ; remove it from the size of the region

	mov edx, 0x20_0000 ; reset the base
	mov [rdi], rdx
	jmp .trimLimit ; base is aligned

.trimBase:
	; make sure base is aligned to 2M boundary
	mov ebx, edx
	mov ecx, 0x1f_ffff
	and ebx, ecx ; ebx gets low bits
	jz .trimLimit; no low bits

	; skip to next aligned page
	inc ecx
	sub ecx, ebx ; how much are we skipping?
	add rdx, rcx
	mov [rdi], rdx
	sub [rdi+8], rcx ; subtract from size

	; same for limit
.trimLimit:
	mov ecx, 0x1f_ffff
	add rdx, [rdi+8] ; limit = base (rdx) + size
	dec rdx ; topmost address is 1 short
	mov ebx, edx
	and ebx, ecx ; low bits
	jz .install ; none

	inc ebx
	sub [rdi+8], rbx ; must drop off ebx from the end

.install:
	mov esi, termLR_ctx
	mov eax, 0xffff_ffff
	mov edx, ram1_str
	call vputs

	mov rdx, [rdi]
	mov rcx, rdx
	call vputQWord

	mov edx, ram2_str
	call vputs

	mov rdx, [rdi+8]
	add rcx, rdx ; rcx -> top of mem block
	mov rdx, rcx
	call vputQWord

	mov dl, 10
	call vputc

	mov ebx, 0x20_0000
	mov rdx, [rdi]
	cmp rdx, rcx
	jae .end ; nothing to install

.install_top:
	mov esi, PAGE_BASE
	mov rax, rdx

	; reset rdx for page flags
	push rdx
	xor edx, edx
	call add_2M_page
	pop rdx

	add rdx, rbx
	cmp rdx, rcx
	jb .install_top

.finish: ; update free list
	mov rdx, [rdi] ; get base again
	cmp rdx, rcx ; make sure there is something
	jae .end

	mov rcx, [BOOT_PARMS+Bob.freeList] ; head of list (could be NULL)
	mov [rdx], rcx ; block->next = freeList
	mov rcx, [rdi+8] ; size
	mov [rdx+8], rcx ; block->size = size
	mov [BOOT_PARMS+Bob.freeList], rdx ; freeList = block

.end:
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

fill_row:
	; IN  eax - pixel to fill
	; IN  rcx - width in pixels
	; IN  edi - y coord (row num)
	; IN  edx - x coord (px, ie. col*4)
	; OUT ecx - 0
	; OUT edi - pixel after last in row

	;; scale y coord by screen width
	imul edi, [BOOT_PARMS+Bob.vgaWidth]

	;; add x coord
	add  edi, edx

	;; add to lfb base
	add  edi, [BOOT_PARMS+Bob.vgaLFBP]

	rep stosd

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

cursorLeft:
	; IN  - rsi terminal context

	; update cursor
	push rax

	mov  eax, [rsi+TermContext.cursorX]
	test eax, eax
	jz .decRow

	dec eax
	mov [rsi+TermContext.cursorX], eax

	jmp .larrow_done

.decRow:
	; BUGFIX Ned, adjust to maxX
	xor eax, eax
	mov [rsi+TermContext.cursorX], eax

	mov eax, [rsi+TermContext.cursorY]
	; TODO Ned, handle scrollback
	dec eax
	mov [rsi+TermContext.cursorY], eax

.larrow_done:
	pop  rax
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

parseArgs:
	; IN  r9  - source string
	; IN  r10 - base of parameter array
	; OUT eax - trash
	; OUT ecx - parameter count
	push rsi
	push rdx

	; make rsi the source vector
	mov rsi, [r9+BasicString.vec+Vector.ary]

	xor ecx, ecx ; parameter count
	xor rdx, rdx ; char offset into source string

.next_arg:
	mov rax, [r10+rcx*8] ; rax = substring[ecx]
	; handle spaces at start

.handle_start_spaces:
	mov [rax+SubStringNearShort.start], dx ; substring[ecx].start = dx

	; if rdx >= string.length then done
	cmp edx, [r9+BasicString.vec+Vector.len]
	jae .done

	cmp BYTE [rsi+rdx], ' '
	jne .start_arg

	inc edx
	jmp .handle_start_spaces

.start_arg:
.next_char:
	; if rdx >= string.length then done
	cmp edx, [r9+BasicString.vec+Vector.len]
	jae .done

	; if string[rdx] == ' ' then done arg
	cmp BYTE [rsi+rdx], ' '
	je .done_arg

	inc edx
	jmp .next_char

.done_arg:
	; convert end count to length
	push rdx
	sub dx, [rax+SubStringNearShort.start]
	mov [rax+SubStringNearShort.len], dx
	pop rdx

	inc ecx
	cmp cl, 7 ; max args
	jae .done
	jmp .next_arg

.done:
	; save last parm
	mov rax, [r10+rcx*8] ; rax = substring[ecx]
	sub dx, [rax+SubStringNearShort.start]
	mov [rax+SubStringNearShort.len], dx
	inc ecx

	pop rdx
	pop rsi
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

BasicString~appendChar: ;Ned? make into Vector~push_back?
	; IN  rdx - char (TODO Ned, support UTF-8)
	; IN  r9  - this
	push rsi
	push rdi

	; get length
	mov esi, [r9+BasicString.vec+Vector.len]
	; check for overflow
	cmp esi, [r9+BasicString.vec+Vector.cap]
	jae .end ; TODO Ned, add vector growth

	; get data array
	mov rdi, [r9+BasicString.vec+Vector.ary]
	; store char to array (TODO UTF-8)
	mov [rdi+rsi], dl

	; update length
	inc esi
	mov [r9+BasicString.vec+Vector.len], esi

.end:
	pop  rdi
	pop  rsi
	ret

BasicString~clear:
	; IN  r9 - this
	push rax
	xor  rax, rax
	mov [r9+BasicString.vec+Vector.len], eax
	pop  rax
	ret

BasicString~length:
	; IN  r15 - this
	; OUT eax - length
	mov eax, [r15+BasicString.vec+Vector.len]
	ret

SubStringNearShort~new:
	; IN  r9d - parent string (near)
	; IN  bx  - short start
	; IN  cx  - short length
	; OUT rax - ptr to new
	mov eax, SubStringNearShort_size
	call malloc
	mov [rax+SubStringNearShort.vtbl], DWORD SubStringNearShort~vtable
	mov [rax+SubStringNearShort.ref], DWORD 1
	mov [rax+SubStringNearShort.src], r9d
	mov [rax+SubStringNearShort.start], bx
	mov [rax+SubStringNearShort.len], cx
	ret

IntString~new@qword:
	; IN  rdx val
	; OUT rax ptr to new IntString(val)
	mov eax, IntString_size
	call malloc
	mov [rax+IntString.vtbl], DWORD IntString~vtable
	mov [rax+IntString.ref], DWORD 1
	mov [rax+IntString.val], rdx
	ret

; vtables
BasicString~vtable:
	.typeInfo   dd 0xdeadbeef
	.delete     dd 0;BasicString~delete
	.clone      dd 0;BasicString~clone
	.incRef     dd 0;BasicString~incRef
	.decRef     dd 0;BasicString~decRef
	.clear      dd BasicString~clear
	.length     dd BasicString~length
	.appendChar dd BasicString~appendChar
	.appendNear dd 0;BasicString~appendNear
	.appendFar  dd 0;BasicString~appendFar
	.compare    dd 0;BasicString~compare
	.intVal     dd 0;BasicString~intVal
	.lookup     dd 0;BasicString~lookup
	.run        dd 0;BasicString~run

SubStringNearShort~vtable:
	.typeInfo   dd 0x33334444
	.delete     dd 0;SubStringNearShort~delete
	.clone      dd 0;SubStringNearShort~clone
	.incRef     dd 0;SubStringNearShort~incRef
	.decRef     dd 0;SubStringNearShort~decRef
	.clear      dd 0;SubStringNearShort~clear
	.length     dd 0;SubStringNearShort~length
	.appendChar dd 0;SubStringNearShort~appendChar
	.appendNear dd 0;SubStringNearShort~appendNear
	.appendFar  dd 0;SubStringNearShort~appendFar
	.compare    dd 0;SubStringNearShort~compare
	.intVal     dd 0;SubStringNearShort~intVal
	.lookup     dd 0;SubStringNearShort~lookup
	.run        dd 0;SubStringNearShort~run

CwrappedStringNear~vtable:
	.typeInfo   dd 0xbaadf00d
	.delete     dd 0;CwrappedStringNear~delete
	.clone      dd 0;CwrappedStringNear~clone
	.incRef     dd 0;CwrappedStringNear~incRef
	.decRef     dd 0;CwrappedStringNear~decRef
	.clear      dd 0;CwrappedStringNear~clear
	.length     dd 0;CwrappedStringNear~length
	.appendChar dd 0;CwrappedStringNear~appendChar
	.appendNear dd 0;CwrappedStringNear~appendNear
	.appendFar  dd 0;CwrappedStringNear~appendFar
	.compare    dd 0;CwrappedStringNear~compare
	.intVal     dd 0;CwrappedStringNear~intVal
	.lookup     dd 0;CwrappedStringNear~lookup
	.run        dd 0;CwrappedStringNear~run

BasicMap~vtable:
	.typeInfo   dd 0xabacdbad
	.delete     dd 0;BasicMap~delete
	.clone      dd 0;BasicMap~clone
	.incRef     dd 0;BasicMap~incRef
	.decRef     dd 0;BasicMap~decRef
	.clear      dd 0;BasicMap~clear
	.length     dd 0;BasicMap~length
	.appendChar dd 0;BasicMap~appendChar
	.appendNear dd 0;BasicMap~appendNear
	.appendFar  dd 0;BasicMap~appendFar
	.compare    dd 0;BasicMap~compare
	.intVal     dd 0;BasicMap~intVal
	.lookup     dd 0;BasicMap~lookup
	.run        dd 0;BasicMap~run

IntString~vtable:
	.typeInfo   dd 0x11112222
	.delete     dd 0;IntString~delete
	.clone      dd 0;IntString~clone
	.incRef     dd 0;IntString~incRef
	.decRef     dd 0;IntString~decRef
	.clear      dd 0;IntString~clear
	.length     dd 0;IntString~length
	.appendChar dd 0;IntString~appendChar
	.appendNear dd 0;IntString~appendNear
	.appendFar  dd 0;IntString~appendFar
	.compare    dd 0;IntString~compare
	.intVal     dd 0;IntString~intVal
	.lookup     dd 0;IntString~lookup
	.run        dd 0;IntString~run

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

ram1_str:
	db "Usable pages from ",0

ram2_str:
	db " to ",0

