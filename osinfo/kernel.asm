%include "cursor.h"

	org 0x8000

	bits 64

end:
	xchg bx,bx
	inc rax
	jmp end

putc:
	;  IN - AL char to print
	;  IN - AH attr
	push rbx

	mov bx, [cursor]
