BOOT_DISK   equ  0
VGA_WIDTH   equ  4
VGA_HEIGHT  equ  8
VGA_BPP     equ 12
VGA_LFBP    equ 16
VGA_CAPS    equ 20
VGA_MODE    equ 24

; 8K located at the top of the 64K BOB region
INPUT_QUEUE equ BOOT_PARMS + 0x1_0000 - 0x2000
; start and end pointers located in different cache lines
QUEUE_START equ INPUT_QUEUE - 32
QUEUE_END   equ INPUT_QUEUE - 64

