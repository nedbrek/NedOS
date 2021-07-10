struc Bob
	.vgaLFBP:   resq 1; far*
	.freeList:  resq 1; far*, start of free memory
	.vgaWidth:  resd 1; px
	.vgaHeight: resd 1; px
	.vgaBPP:    resd 1; bits
	.vgaCaps:   resd 1
	.vgaMode:   resd 1
endstruc

