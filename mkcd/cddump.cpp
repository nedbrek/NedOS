#include "iso9660.h"
#include "eltorito.h"
#include <cstdio>

int main(int argc, char **argv)
{
	printf("Sizeof(boot record)=%d\n", sizeof(BootRecord));

	uint8_t *buf = new uint8_t[2048];
	PrimaryVolDesc *pvd = (PrimaryVolDesc*)buf;
	BootRecord     *br  =     (BootRecord*)buf;

	printf("Sizeof(pvd)=%d\n", sizeof(PrimaryVolDesc));

	unsigned sectorCt = 0;
	unsigned bootCatalog = 0;
	FILE *f = fopen(argv[1], "rb");
	for(
	    fread(buf, 2048, 1, f);
	    !feof(f);
	    fread(buf, 2048, 1, f), ++sectorCt)
	{
		if( sectorCt < 16 ) continue;

		printf("Sector(%3d) Type: %d\n", sectorCt, pvd->type_);
		if( pvd->type_ == 1 )
			pvd->print();
		else if( br->type_ == 0 )
		{
			br->print();
			bootCatalog = br->bootCatLoc_;
		}

		if( pvd->type_ == 255 ) break; // terminator
	}

	printf("Size of BootCatalog=%d\n", sizeof(BootCatalog));
	if( fseek(f, bootCatalog * 2048, SEEK_SET) )
	{
		printf("Error finding boot catalog\n");
		return 1;
	}
	fread(buf, 2048, 1, f);

	BootCatalog *bcp = (BootCatalog*)buf;
	bcp->print();

	uint32_t bootImageLBA = bcp->getBootImageLBA();
	if( bootImageLBA == 0 ||
	    fseek(f, bootImageLBA * 2048, SEEK_SET) )
	{
		printf("Error finding boot image\n");
		return 1;
	}
	fread(buf, 2048, 1, f);

	for(unsigned i = 0; i < 176; ++i)
	{
		printf("%02x ", buf[i]);
		if( i % 16 == 15 ) printf("\n");
	}
	printf("\n");

	return 0;
}

