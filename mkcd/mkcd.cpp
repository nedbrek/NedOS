#include "eltorito.h"
#include <cstdio>
#include <string>

int main(int argc, char **argv)
{
	if( argc < 2 )
	{
		printf("Usage: %s <bootloader> [fname]\n", argv[0]);
		return -1;
	}

	FILE *bootFile = fopen(argv[1], "rb");

	std::string fname = "test.iso";
	if( argc > 2 )
	{
		fname = argv[2];
	}

	FILE *ofile = fopen(fname.c_str(), "r+b");
	if( !ofile )
	{
		printf("%s does not exist, creating.\n", fname.c_str());
		ofile = fopen(fname.c_str(), "wb");

		// write initial zero sectors
		uint8_t bZero = 0;
		for(unsigned i = 0; i < 2048 * 16; ++i)
			fwrite(&bZero, 1, 1, ofile);

		PrimaryVolDesc pvd;
		fwrite(&pvd, 1, 2048, ofile);

		BootRecord br;
		fwrite(&br, 1, 2048, ofile);

		NullDesc nd;
		fwrite(&nd, 1, 2048, ofile);

		BootCatalog bc;
		fwrite(&bc, 1, 2048, ofile);
	}

	if( fseek(ofile, 20 * 2048, SEEK_SET) )
	{
		printf("Error: Unable to seek to boot image\n");
		return -2;
	}

	char buf[2048];
	memset(buf, 0, 2048);

	size_t numRead = fread(buf, 1, 2048, bootFile);
	if( numRead == 0 )
	{
		printf("Error: No bytes in boot image.\n");
		return -3;
	}

	unsigned numSec = 0;
	while( !feof(bootFile) )
	{
		fwrite(buf, 1, 2048, ofile);
		++numSec;

		numRead = fread(buf, 1, 2048, bootFile);
	}

	if( numRead != 0 )
	{
		memset(buf+numRead, 0, 2048-numRead);
		fwrite(buf, 1, 2048, ofile);
		++numSec;
	}
	printf("Wrote %d boot sectors\n", numSec);

	return 0;
}

