; memory map
; 0_0000..0_03FF Real-mode IDT (reclaimable)
; 0_0400..0_04FF BIOS data (reclaimable)
; 0_0500..0_7BFF boot stack (30464 bytes)
; 0_7C00..0_7DFF boot sector (reclaimable)
; 0_7E00..3_FFFF free
; 4_0000..4_FFFF boot output block
; 5_0000..5_FFFF GDT+IDT
; 6_0000..6_FFFF stage 1 page tables
; 7_0000..7_FFFF memory map
; 8_0000..9_FBFF possible BIOS EDA
; 9_FC00..9_FFFF definite BIOS EDA
; A_0000..F_FFFF ROM

BOOT_PARMS     equ   0x40000 ; information from boot time
TSS_BASE       equ   0x50000
GDT_BASE       equ   TSS_BASE+0x1000
IDT_BASE       equ   GDT_BASE+0x1000
PAGE_BASE      equ   0x60000
MMAP_BASE      equ   0x70000

