OS Info boot image

A simpler boot configuration which just sets text mode and prints stuff.

Currently:
1) Dump VBE mode info (only those with 32bpp and lfb):
	mode_num width height

2) Jump to 64 bit mode.

3) Print "Hello world" and some MSR's
	APIC base
	MTRR caps
	MTRR def
	16 MTRR's

4) Look for ACPI tables (panic if not found)
	Print number of IO redirects
	Print IO redirects

5) Scan for hard drive controllers

