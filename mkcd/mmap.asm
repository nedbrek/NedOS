; memory map
; 00000..003FF IDT
; 00400..004FF BIOS data
; 00500..07BFF stack (30464 bytes)
; 07C00..07DFF boot sector
; 07E00..3FFFF free
; 40000..4FFFF boot output block
; 50000..5FFFF GDT+IDT
; 60000..6FFFF stage 1 page tables
; 70000..7FFFF memory map
; 80000..9FBFF possible BIOS EDA
; 9FC00..9FFFF definite BIOS EDA
; A0000..FFFFF ROM

BOOT_PARMS     equ   0x40000 ; information from boot time
TSS_BASE       equ   0x50000
GDT_BASE       equ   TSS_BASE+0x1000
IDT_BASE       equ   GDT_BASE+0x1000
PAGE_BASE      equ   0x60000
MMAP_BASE      equ   0x70000

