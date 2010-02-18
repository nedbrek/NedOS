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
	call add_2M_page
	;;; leaves rsi pointing to the pde

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

	; success, aqua screen of life
	mov  rax, 0x0000_FF00_0000_00FF
	call fill_screen
	jmp die

add_2M_page:
	; IN eax - vaddr to add a page for
	; IN esi - start of page table (CR3)
	; OUT esi - addr of pde
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

fill_screen:
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

