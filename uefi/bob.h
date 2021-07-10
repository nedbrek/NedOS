#ifndef BOB_H
#define BOB_H

/*
 * Boot Output Block
 * (holds information from the bootloader needed by the OS)
 */
struct Bob
{
	UINT64   vga_lfbp; /* far ptr */
	UINT64   free_list; /* far ptr, start of free memory */
	unsigned vga_width;
	unsigned vga_height;
	unsigned vga_bpp;
	unsigned vga_caps;
	unsigned vga_mode;
} __attribute__((packed));

#endif

