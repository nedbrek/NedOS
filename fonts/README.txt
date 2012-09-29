How to build the font.asm file for NedOS
----------------------------------------
The font.asm file consists of sequential quadwords containing the bit patterns
for the fixed 6x10 font.

The bit patterns are built from the "UCS Fonts for X11", available from:
http://www.cl.cam.ac.uk/~mgk25/ucs-fonts.html

To convert them is a straight forward process (using the tools in this
directory):

1) retrieve the ucs-fonts

2) update the Makefile with your path

3) make

####
# (the Makefile will do some of these steps for you)
# convert all the font defs into byte wise bitmasks
awk -f extract_font.awk /path/to/ucs-fonts/6x10.bdf > fontfile.txt

# This file has all the unicode fonts, for now, we should only use ASCII
# so trim this file of everything after "asciitilde"
# Also, there is a weird "char0" at the beginning, delete that

# compress the bytes into a 64bit integer, also format everything for NASM
# make sure your Tcl supports 64bit integers!  You may need Tcl 8.5
tclsh font2asm.tcl fontfile.txt > font.asm

