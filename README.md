# NedOS - My hobby operating system
   Primarily a workbench for exploring how the PC platform works

## Builds
mkcd   - build into a CD ISO image (latest development)
mkflop - build into a FAT12 floppy image (first development)
mkhd   - build into a hard drive image (side development)
osinfo - a CD image which just dumps configuration information

Of possible use to other people is my bootloader: one sector (512B), sets
the video mode, and readies the kernel for 64 bit mode.

The best source I've found for OS development is:
http://wiki.osdev.org/Main_Page

## Setup
I use Bochs for testing the os image (see the OSDev Bochs page).

`apt-get install bochs` probably won't be enough.
You'll probably need: bochs-x, bochsbios, vgabios
When you first run bochs, make sure to enable a 64 bit CPU, and set CD
boot (and save the config)

## To build:
- `cd mkcd`
- `make`
- `cp test.iso <bochs area>`

I use Bochs magic instructions (xchg bx,bx) for debugging.  You should use them
too.  You will need to continue several times to reach the end (jmp end).

## To run the two stage hard drive boot through qemu:
- `cd twoStage`
- `make`
- `qemu-system-x86_64 -hda twoStage/bochs.img`

