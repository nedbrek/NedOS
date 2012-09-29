USC_FONTS_PATH:=

all: font.asm

fontfile.txt: extract_font.awk $(USC_FONTS_PATH)/6x10.bdf
	@awk -f extract_font.awk $(USC_FONTS_PATH)/6x10.bdf > fontfile.txt

font.asm: font2asm.tcl fontfile.txt
	@tclsh font2asm.tcl fontfile.txt > font.asm

