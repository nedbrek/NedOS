BOOT_PARMS     equ   0x40000 ; information from boot time
PAGE_BASE      equ   0x60000

PAGE_PRESENT   equ   1
PAGE_WRITE     equ   2
PAGE_SUPER     equ   4

PAGE_LEN       equ   0x01000

	org 0x7e00

	bits 64

	mov edi, PAGE_BASE
	mov [rdi+PAGE_LEN+3*8], DWORD ((PAGE_BASE + 3*PAGE_LEN) \
                    |PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)
	mov [rdi+3*PAGE_LEN+0x100*8], DWORD (0xe000_0000 \
                                 |0x80|PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)
	mov [rdi+3*PAGE_LEN+0x100*8+8], DWORD (0xe020_0000 \
                                 |0x80|PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)

	mov rax, cr3
	mov cr3, rax

	mov  eax, [BOOT_PARMS+4]
	mov  ecx, [BOOT_PARMS+8]
	mov  edi, [BOOT_PARMS+0x10]
	imul ecx, eax
	shr  ecx, 1
	mov  rax, 0x00FF_0000_00FF_0000
	rep stosq

	; loop forever
loop:
	inc rax
	jmp loop

