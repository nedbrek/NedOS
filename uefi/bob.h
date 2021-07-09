#ifndef BOB_H
#define BOB_H

/*
 * Boot Output Block
 * (holds information from the bootloader needed by the OS)
 */
struct Bob
{
	unsigned vga_width;
	unsigned vga_height;
	unsigned vga_bpp;
	unsigned long vga_lfbp; /* near ptr */
	unsigned vga_caps;
	unsigned vga_mode;
	unsigned long free_list; /* far ptr, start of free memory */
} __attribute__((packed));

#endif

