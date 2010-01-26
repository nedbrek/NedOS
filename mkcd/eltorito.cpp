#include "eltorito.h"
#include "print.h"
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

//----------------------------------------------------------------------------
BCEntry::BCEntry(void)
{
}

void BCEntry::print(void)
{
	printStr(b_, 32);
}

//----------------------------------------------------------------------------
ValidationEntry::ValidationEntry(void)
{
}

bool ValidationEntry::isValid(void) const
{
	return headerID_ == 1 && key1_ == 0x55 && key2_ == 0xaa;
}

void ValidationEntry::print(void)
{
	printf("ID=%d\n", headerID_);
	printf("PlatformID=%d\n", platformID_);
	printf("idStr=\n");
	printStr(idStr_, 24);
	printf("Checksum=%d\n", checksum_);
}

//----------------------------------------------------------------------------
BootCatalog::BootCatalog(void)
{
}

void BootCatalog::print(void)
{
	ValidationEntry *ve = (ValidationEntry*)entries_;

	if( ve->isValid() )
		ve->print();
	else
		printf("Bad validation entry\n");

	for(unsigned i = 1; i < 64; ++i)
		entries_[i].print();
}

