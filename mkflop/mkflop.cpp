#include "fat.h"

int main(int argc, char **argv)
{
	FILE *ofile = fopen("test.img", "wb");

	BiosParamBlock bpb;
	bpb.bootCode_[0] = 0x87; // xchg
	bpb.bootCode_[1] = 0xdb; // bx,bx
	bpb.bootCode_[2] = 0xeb; // jmp imm b
	bpb.bootCode_[3] = 0xfe; // -2 (self)

	bpb.write(ofile);

	uint8_t bZero = 0;
	for(unsigned i = 512; i < 2880*512; ++i)
		fwrite(&bZero, 1, 1, ofile);

	return 0;
}

