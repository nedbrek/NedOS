struc Bob
	.bootDisk:  resd 1; value from POST in DX
	.vgaWidth:  resd 1; px
	.vgaHeight: resd 1; px
	.vgaBPP:    resd 1; bits
	.vgaLFBP:   resd 1; near*
	.vgaCaps:   resd 1
	.vgaMode:   resd 1
	.freeList:  resd 1; near*, start of free memory
endstruc

struc Vector
	.len: resd 1
	.cap: resd 1
	.ary: resd 1
endstruc

struc BasicString
	.vtbl: resd 1
	.ref:  resd 1
	.vec:  resb Vector_size
endstruc

; 8K located at the top of the 64K BOB region
INPUT_QUEUE_SIZE equ 0x2000
INPUT_QUEUE equ BOOT_PARMS + 0x1_0000 - INPUT_QUEUE_SIZE
; start and end pointers located in different cache lines
QUEUE_START equ INPUT_QUEUE - 32
QUEUE_END   equ INPUT_QUEUE - 64

