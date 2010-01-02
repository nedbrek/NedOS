#ifndef FAT_H
#define FAT_H
/// data structures for FAT formatted (and FAT-like) disks

#include <stdint.h>
#include <stdio.h>

/// boot sector on a FAT-12 like disk
struct BiosParamBlock
{
	uint8_t  jmpCode_[3];
	uint8_t  oemName_[8];
	uint16_t bytesPerSector_;
	uint8_t  sectorsPerCluster_;
	uint16_t numReservedSectors_;
	uint8_t  numFAT_;
	uint16_t numDirEnt_;
	uint16_t numSectors_;
	uint8_t  mediaDescriptor_;
	uint16_t sectorsPerFAT_;
	uint16_t sectorsPerTrack_;
	uint16_t numHeads_;
	uint32_t numHiddenSectors_;
	uint32_t sectorUpperHalf_;

	// extended info
	uint8_t  biosDriveNum_;
	uint8_t  rsvd_;
	uint8_t  sig_;
	uint32_t serialNum_;
	uint8_t  label_[11];
	uint8_t  sysId_[8];
	uint8_t  bootCode_[448];
	uint16_t bootSig_;

public: // methods
	BiosParamBlock(void);

	void write(FILE *f);

} __attribute__((packed));
// g++ requires two parens for some bizarre reason

#endif

