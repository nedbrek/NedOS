struc Bob
	.vgaWidth:  resd 1; px
	.vgaHeight: resd 1; px
	.vgaBPP:    resd 1; bits
	.vgaLFBP:   resq 1; far*
	.vgaCaps:   resd 1
	.vgaMode:   resd 1
	.freeList:  resq 1; far*, start of free memory
endstruc

