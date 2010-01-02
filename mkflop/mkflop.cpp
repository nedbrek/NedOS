#include "fat.h"

int main(int argc, char **argv)
{
	if( argc < 2 )
	{
		printf("Usage: %s <bootloader>\n", argv[0]);
		return -1;
	}

	FILE *ofile = fopen("test.img", "wb");

	BiosParamBlock bpb;

	FILE *ifile = fopen(argv[1], "rb");
	fread(bpb.bootCode_, sizeof(bpb.bootCode_), 1, ifile);

	bpb.write(ofile);

	uint8_t bZero = 0;
	for(unsigned i = 512; i < 2880*512; ++i)
		fwrite(&bZero, 1, 1, ofile);

	return 0;
}

