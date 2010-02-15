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

	bootCatLoc_ = 19;
}

void BootRecord::print(void)
{
	printf("Type: %d\n", type_);
	printf("Boot Catalog sector: %d\n", bootCatLoc_);
}

//----------------------------------------------------------------------------
BCEntry::BCEntry(void)
{
	memset(b_, 0, 32);
}

void BCEntry::print(void)
{
	printStr(b_, 32);
}

//----------------------------------------------------------------------------
ValidationEntry::ValidationEntry(void)
{
	init();
}

void ValidationEntry::init(void)
{
	headerID_   = 1;
	platformID_ = 0;
	memset(idStr_, 0, 24);
	checksum_   = 21930;
	key1_       = 0x55;
	key2_       = 0xaa;
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
BCInit::BCInit(void)
{
	init();
}

void BCInit::init(void)
{
	bootable_   = 0x88;
	mediaType_  = 0;
	startSeg_   = 0x07c0;
	systemType_ = 0;
	unused0_    = 0;
	numSec_     = 1;
	imageLoc_   = 20;
	memset(unused1_, 0, 20);
}

void BCInit::print(void)
{
	printf("Default Entry Begin\n");
	printf("BootId=0x%x\n", bootable_);
	printf("Media=%d\n", mediaType_);
	printf("StartSeg=0x%x\n", startSeg_);
	printf("SystemType=%d\n", systemType_);
	printf("NumSec=%d\n", numSec_);
	printf("ImageLoc=%d\n", imageLoc_);
	printf("Default Entry End\n");
}

//----------------------------------------------------------------------------
BootCatalog::BootCatalog(void)
{
	ValidationEntry *ve = (ValidationEntry*)entries_;
	ve->init();

	BCInit *bci = (BCInit*)entries_+1;
	bci->init();
}

void BootCatalog::print(void)
{
	ValidationEntry *ve = (ValidationEntry*)entries_;

	if( ve->isValid() )
		ve->print();
	else
		printf("Bad validation entry\n");

	BCInit *bci = (BCInit*)entries_+1;
	bci->print();

	for(unsigned i = 2; i < 64; ++i)
	{
		if( entries_[i].b_[0] == 0x90 ||
		    entries_[i].b_[0] == 0x91 )
		{
			entries_[i].print();
		}
	}
}

uint32_t BootCatalog::getBootImageLBA(void) const
{
	ValidationEntry *ve = (ValidationEntry*)entries_;
	if( !ve->isValid() ) return 0;

	BCInit *bci = (BCInit*)entries_+1;
	return bci->imageLoc_;
}

BCInit* BootCatalog::getBCE(unsigned i)
{
	return (BCInit*)entries_+i;
}

