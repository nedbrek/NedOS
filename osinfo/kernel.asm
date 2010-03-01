%include "cursor.h"

	org 0x8000

	bits 64

	xchg bx,bx
	mov eax, 0x0700
	mov ebx, str_hello64
	call puts

end:
	inc rax
	jmp end

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
	; ja .shift_screen
	cmova ebx, eax
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

printByte:

printWord:

str_hello64:
	db "Hello from 64 bit land",0xa,0

