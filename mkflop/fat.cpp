#include "fat.h"
#include <cstring>

// format for a 1.44M floppy
BiosParamBlock::BiosParamBlock(void)
{
	jmpCode_[0] = 0xeb; // jump imm b
	jmpCode_[1] = 0x3c; // address 3e
	jmpCode_[2] = 0x90; // nop

	memcpy(oemName_, "NedOS0.1", 8);

	bytesPerSector_     =  512;
	sectorsPerCluster_  =    1;
	numReservedSectors_ =    1;
	numFAT_             =    2;
	numDirEnt_          =  224;
	numSectors_         = 2880;
	mediaDescriptor_    = 0xf0; // FAT12
	sectorsPerFAT_      =    9;
	sectorsPerTrack_    =   18;
	numHeads_           =    2;
	numHiddenSectors_   =    0;
	sectorUpperHalf_    =    0;

	biosDriveNum_ = 0;
	rsvd_         = 0;
	sig_          = 0x29;
	serialNum_    = 0xefbeadde;

	memcpy(label_, "Boot disk  ", 11);
	memcpy(sysId_, "FAT12   ", 8);

	memset(bootCode_, 0, sizeof(bootCode_));

	bootSig_ = 0xaa55;
}

void BiosParamBlock::write(FILE *f)
{
	fwrite(this, sizeof(*this), 1, f);
}

