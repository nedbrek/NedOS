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

	; blank the screen
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

	;; calculate size of VRAM
	mov  eax, [BOOT_PARMS+4]
	mov  ecx, [BOOT_PARMS+8]
	imul ecx, eax
	shr  ecx, 1 ; we will write 2 pixels per

	;; build the pixel
	mov  rax, 0x00FF_0000_00FF_0000

	;; write
	rep stosq

	; loop forever
loop:
	inc rax
	jmp loop

