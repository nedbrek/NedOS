; pmode bootstrap
; constants
PAGE_PRESENT   equ   1
PAGE_WRITE     equ   2
PAGE_SUPER     equ   4

PAGE_LEN       equ   0x01000

	; GDT/IDT (64KB at GDT_BASE)
	mov ax, (GDT_BASE >> 4)
	mov ds, ax ; space saver
	call fun_kzero

	; entry0 - null segment
	; entry1 - code segment
	;     [0x08] base = 0
	mov   [0x0c], WORD 0x9800
	mov   [0x0e], BYTE 0xf
	; entry2 - data segment
	;     [0x10] base = 0
	mov   [0x14], WORD 0x9300
	mov   [0x16], BYTE 0xf

	; leave space for IDT

	; page tables (PML,PDP,PD at PAGE_BASE)
	mov ax, (PAGE_BASE >> 4)
	mov ds, ax ; space saver
	call fun_kzero

	; PML4 point to next
	mov   [0x0000], DWORD ((PAGE_BASE + PAGE_LEN) \
	                        |PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)

	; PDP point to next
	mov   [PAGE_LEN], DWORD ((PAGE_BASE + 2*PAGE_LEN) \
	                        |PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)

	; 2meg identity
	mov   [2*PAGE_LEN], BYTE (0x80 |PAGE_PRESENT|PAGE_WRITE|PAGE_SUPER)

	mov ds, ax ; needed for lgdt (ax is 0 from kzero)

	; load the page table base
	mov   eax, PAGE_BASE
	mov   cr3, eax

	; set PSE, PAE, and PGE in CR4
	mov   eax, cr4
	or     ax, 0xb0
	mov   cr4, eax

	lgdt  [gdt]

	xchg bx,bx ; Bochs magic debug break 

	; enter protected mode (no paging)
	cli

	mov   eax, cr0
	or    al, 1
	mov   cr0, eax

	; jump to the next instruction, to load the seg desc
	jmp   8:codePE

	;bits 32 - we set our code segment to 16bit!
codePE:
	; load the ds seg desc
	mov   ax, 16
	mov   ds, ax

	; set long mode
	mov   ecx, 0xC000_0080
	rdmsr
	or    ah, 0x1
	wrmsr

	; set L bit in code segment
	mov  eax, GDT_BASE+0xe
	or   byte [eax], 32

	; turn on paging
	mov   eax, cr0
	bts   eax, 31
	mov   cr0, eax

	jmp 8:code64

	bits 64
code64: ; we made it!

	; loop forever
loop:
	inc rax
	jmp loop

gdt:
	dw 32
	dd GDT_BASE

