; bootloader
	org 0x7c3e

	bits 16

	; clear blocks of memory
	xor   ax, ax
	;mov   ax, 0xdead ; testing mem range
	xor   di, di

	; GDT (64KB at 0x10000)
	push  0x1000
	pop   es
	mov   cx, 0x8000
	rep stosw
	; entry0 - null segment
	; entry1 - code segment
	;     [es:0x08] base = 0
	mov   [es:0x0c], WORD 0x9800
	mov   [es:0x0e], BYTE 0xf
	; entry2 - data segment
	;     [es:0x10] base = 0
	mov   [es:0x14], WORD 0x9300
	mov   [es:0x16], BYTE 0xf

	; leave space for IDT

	; page tables (PML,PDP,PD at 0x30000)
	push  0x3000
	pop   es
	mov   cx, 0x8000
	rep stosw
	mov   [es:0x0000], DWORD 0x31007 ; point to next
	mov   [es:0x1000], DWORD 0x32007 ; point to next
	mov   [es:0x2000], BYTE 0x87     ; 2meg identity

	; load the page table base
	mov   eax, 0x30000
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
	or    ax, 1
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
	or    ax, 0x100
	wrmsr

	; set L bit in code segment
	mov   eax, 0x1000e
	bts   word [eax], 5

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
	dd 0x10000

