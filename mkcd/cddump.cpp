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

	return 0;
}

