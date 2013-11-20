%include "../mkcd/mmap.asm"
%include "../mkcd/bob.asm"

; constants (for page table bits)
PAGE_PRESENT   equ   1
PAGE_WRITE     equ   2
PAGE_SUPER     equ   4

PAGE_LEN       equ   0x01000

	org 0x8000
	bits 64

start:
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
	mov eax, [BOOT_PARMS+Bob.vgaLFBP]
	;Ned set WC
	call add_2M_page
	;;; leaves rsi with address of pde

	;;; need two for 4 MB VRAM
	add eax, 0x20_0000 |0x80|PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER
	mov [rsi+8], eax

	;; flush TLB
	mov rax, cr3
	mov cr3, rax

	; success, aqua screen of life
	mov rax, 0x0000_FF00_0000_00FF
	call fill_screen

	hlt

add_2M_page:
	; IN  eax - vaddr to add a page for
	; IN  esi - start of page table (CR3)
	; OUT esi - addr of pde
	push rdi

	mov edi, eax

	; make esi point to proper pd
	;; find top two bits
	shr eax, 30

	;; add two for pd offset
	inc eax ; shift past PML4
	inc eax ; shift past pdp

	;; multiply by PAGE_LEN
	shl eax, 12

	add esi, eax ; done pd offset

	; build pde
	mov eax, edi ; restore eax
	and eax, 0xffe0_0000 ; clear low bits
	or  eax, 0x80|PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER
	mov [rsi], eax

	mov eax, edi

	pop rdi
	ret

fill_screen:
	; IN  rax - color to fill
	; OUT rdx - screen width
	; OUT rcx - 0
	; OUT rdi - end of screen mem
	mov edx, [BOOT_PARMS+Bob.vgaWidth]
	mov ecx, [BOOT_PARMS+Bob.vgaHeight]
	imul ecx, edx
	shr ecx, 1 ; we will write 2 pixels per

	;; write
	mov edi, [BOOT_PARMS+Bob.vgaLFBP]
	rep stosq

	ret

