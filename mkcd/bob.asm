struc Bob
	.bootDisk:  resd 1; value from POST in DX
	.vgaWidth:  resd 1; px
	.vgaHeight: resd 1; px
	.vgaBPP:    resd 1; bits
	.vgaLFBP:   resd 1; near*
	.vgaCaps:   resd 1
	.vgaMode:   resd 1
	.freeList:  resq 1; far*, start of free memory
endstruc

struc Vector
	.len: resd 1
	.cap: resd 1
	.ary: resq 1
endstruc

struc BasicString
	.vtbl: resd 1
	.ref:  resd 1
	.vec:  resb Vector_size
endstruc

struc StrVtbl
	.typeInfo: resd 1
	.delete  : resd 1
	.clone   : resd 1
	.incRef  : resd 1
	.decRef  : resd 1

	.clear   : resd 1
	.length  : resd 1
	.append_near: resd 1
	.append_far : resd 1

	.compare: resd 1
	.intVal: resd 1
	.lookup: resd 1

	.run: resd 1
endstruc

struc SubStringNearShort
	.vtbl:  resd 1
	.ref:   resd 1
	.src:   resd 1
	.start: resw 1
	.len:   resw 1
endstruc

struc CwrappedStringNear
	.vtbl: resd 1
	.ref:  resd 1
	.len:  resd 1
	.act:  resd 1
endstruc

struc BasicMap
	.vtbl:    resd 1
	.ref:     resd 1
	.vecTags: resb Vector_size
	.vecLocs: resb Vector_size
endstruc

struc IntString
	.vtbl: resd 1
	.ref:  resd 1
	.val:  resq 1
endstruc

struc TermContext
	.consoleX: resd 1; console x pos (px)
	.consoleY: resd 1; console y pos (px)
	.width:    resd 1; width (chars)
	.height:   resd 1; height (chars)
	.cursorX:  resd 1; cursor X (chars)
	.cursorY:  resd 1; cursor Y (chars)
endstruc

; 8K located at the top of the 64K BOB region
INPUT_QUEUE_SIZE equ 0x2000
INPUT_QUEUE equ BOOT_PARMS + 0x1_0000 - INPUT_QUEUE_SIZE
; start and end pointers located in different cache lines
QUEUE_START equ INPUT_QUEUE - 32
QUEUE_END   equ INPUT_QUEUE - 64

RET_OK    equ 0
RET_ERR   equ 1
RET_BREAK equ 2
RET_CONT  equ 3
