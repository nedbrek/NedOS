#include "iso9660.h"
#include <cstdio>

int main(int argc, char **argv)
{
	uint8_t *buf = new uint8_t[2048];
	PrimaryVolDesc *pvd = (PrimaryVolDesc*)buf;

	printf("Sizeof(pvd)=%d\n", sizeof(PrimaryVolDesc));

	FILE *f = fopen(argv[1], "rb");
	fread(buf, 2048, 1, f);
	while( !feof(f) )
	{
		printf("Sector Type: %d\n", pvd->type_);
		if( pvd->type_ == 1 )
			pvd->print();

		if( pvd->type_ == 255 ) break; // terminator

		fread(buf, 2048, 1, f);
	}

	return 0;
}

