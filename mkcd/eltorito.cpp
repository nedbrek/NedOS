#include "eltorito.h"
#include <cstring>
#include <cstdio>

//----------------------------------------------------------------------------
BootRecord::BootRecord(void)
{
	type_ = 0;

	memset(bootSysId_, ' ', 32);
	memcpy(bootSysId_, "EL TORITO SPECIFICATION", 23);

	memset(unused0_, 0, 32);
	memset(unused1_, 0, 1973);

	bootCatLoc_ = 0;
}

void BootRecord::print(void)
{
	printf("Type: %d\n", type_);
	printf("Boot Catalog sector: %d\n", bootCatLoc_);
}

