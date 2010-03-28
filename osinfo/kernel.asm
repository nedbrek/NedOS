%include "cursor.h"
%include "../mkcd/mmap.asm"

PAGE_LEN       equ   0x01000
PAGE_PRESENT   equ   1
PAGE_WRITE     equ   2
PAGE_SUPER     equ   4

	org 0x8000

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

	;; flush TLB
	mov rax, cr3
	mov cr3, rax

	; print stuff
	xchg bx,bx
	mov eax, 0x0700
	mov ebx, str_hello64
	call puts

	mov rdx, 0xdeadbeef
	call printQWord

	mov eax, 0x070a
	call putc

debug_printMSRs:
	mov ecx, 0x1b ; APIC BASE
	call printMSR
	mov al, 0x0a
	call putc

	mov ecx, 0xfe ; MTRR caps
	call printMSR
	mov al, 0x0a
	call putc

	mov ecx, 0x2ff ; MTRR def
	call printMSR
	mov al, 0x0a
	call putc

	xchg bx,bx
	mov ecx, 0x200
.msr_MTRR_loop:
	call printMSR
	mov al, 0x0a
	call putc

	inc ecx
	cmp ecx, 0x210
	jb .msr_MTRR_loop

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

end:
	inc rax
	jmp end

str_panic:
	db "Kernel panic",0
panic:
	mov esp, 0x7c00
	mov eax, 0x0700
	mov ebx, str_panic
	call puts

putc:
	;  IN - AL char to print
	;  IN - AH attr
	push rbx

	xor ebx, ebx
	mov bx, [cursor]

	; check for LF
	cmp al, 0xa
	jne .putc_normal

	; advance to next row, 0 col
	push rax
	mov  eax, ebx
	mov  ebx, 160
	div  bl
	; ah has col*2
	; al has row

	inc al ; next row
	mul bl ; scale

	mov ebx, eax

	pop rax

	jmp .putc_earlyOut

.putc_normal:
	mov [rbx+0xb8000], ax
	; advance the cursor two bytes, and save it
	inc ebx
	inc ebx

.putc_earlyOut:
	push rax
	xor eax, eax
	cmp ebx, 0xfa0
	jb .finish

.shift_screen:
	push rsi
	push rdi
	push rcx

	mov esi, 0xb8000+80*2
	mov edi, 0xb8000
	mov ecx, (160*25) >> 3
	rep movsq

	mov ebx, 160*24

	pop  rcx
	pop  rdi
	pop  rsi

.finish:
	pop rax

	mov [cursor], bx
	pop rbx
	ret

puts:
	;  IN - ebx ptr to str
	;  IN - AH attr
	; OUT - eax trashed
	; OUT - ebx end of string
.nextc:
	mov al, [rbx]
	test al, al
	jz .done

	call putc
	inc  ebx
	jmp .nextc

.done:
	ret

printNibble:
	;  IN AL - nibble (0..F)
	;  IN AH - attr
	; OUT AL - ASCII val of nibble
	cmp al, 9
	jbe .printLo

	add al, 'A'-10
	jmp .done

.printLo:
	add al, '0'

.done:
	call putc
	ret

printByte:
	;  IN AL - byte
	;  IN AH - attr
	; OUT AL - ASCII val of low nibble
	; save byte
	push rcx
	mov ecx, eax

	; print high nibble
	shr al, 4
	call printNibble
	; print lo nibble from cx
	mov al, cl
	and al, 0xf
	call printNibble

	pop rcx
	ret

printWord:
	;  IN AH - attr
	;  IN DX - word
	; OUT AL - ASCII val of low nibble
	mov al, dh
	call printByte

	mov al, dl
	call printByte

	ret

printDWord:
	;  IN AH - attr
	;  IN EDX - dword
	; OUT AL - ASCII val of low nibble
	push rdx
	shr edx, 16
	call printWord

	pop rdx
	call printWord

	ret

printQWord:
	;  IN AH - attr
	;  IN RDX - qword
	; OUT AL - ASCII val of low nibble
	push rdx

	shr rdx, 32
	call printDWord

	pop rdx
	call printDWord

	ret

printMSR:
	;  IN - ECX msr
	;  IN - AH attr
	; OUT - EDX 64bit MSR val
	; OUT - ASCII val of low nibble of MSR val
	push rax

	mov edx, ecx
	call printDWord
	rdmsr
	shl rdx, 32
	or  rdx, rax

	pop rax
	mov al, 0x20
	call putc
	call printQWord

	ret

str_hello64:
	db "Hello from 64 bit land",0xa,0

