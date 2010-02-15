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
	mov  edi, [BOOT_PARMS+0x10]

	;;; find top two bits (pd offset)
	mov eax, edi
	shr eax, 30

	;;; add two for pd offset
	inc eax ; shift past PML4
	inc eax ; shift past pdp

	;;; multiply by PAGE_LEN
	shl eax, 12

	add rsi, rax ; done pd offset

	;;; get pde (bits 29..21)
	mov eax, edi
	shr eax, 21
	and eax, 0x1ff

	shl eax, 3 ; scale for pde size

	add rsi, rax ; add pde offset

	;;; build pde
	mov eax, edi
	or  eax, 0x80|PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER
	mov [rsi], eax

	;;; need two for 4 MB VRAM
	add eax, 0x20_0000
	mov [rsi+8], eax

	;; flush TLB
	mov rax, cr3
	mov cr3, rax

	xchg bx, bx
	; find ACPI tables
	;; look in EBDA
	cld
	mov rax, 'RSD PTR '
	movzx edi, WORD [0x40e]
	shl edi, 4
	mov ecx, 0xa0000
	sub ecx, edi
	shr ecx, 3
	repne scasq
	je acpi_found

	;; look in BIOS high mem
	mov edi, 0xe_0000
	mov ecx, (0x10_0000 - 0xe_0000) >> 3
	repne scasq
	jne panic

acpi_found:
	; RSDP is at edi-8
	sub edi, 8

	mov  rax, 0x0000_FF00_0000_00FF
	call fill_screen
	jmp die

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
	; show red screen of death
	mov  rax, 0x00FF_0000_00FF_0000
	call fill_screen

	; loop forever
die:
	inc rax
	jmp die

