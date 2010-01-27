#ifndef ISO9660_H
#define ISO9660_H

#include <stdint.h>

struct VolDescBase
{
	uint8_t type_;
	uint8_t cd001_[5];
	uint8_t version_; // 1

	VolDescBase(void);
} __attribute__((packed));
// g++ requires two parens for some bizarre reason

struct BiEnd32
{
	uint32_t little_;
	uint32_t big_;

	void set(uint32_t val);

} __attribute__((packed));
// g++ requires two parens for some bizarre reason

struct BiEnd16
{
	uint16_t little_;
	uint16_t big_;

	void set(uint16_t val);

} __attribute__((packed));
// g++ requires two parens for some bizarre reason

// 34 bytes
struct DirEnt
{
	uint8_t len_;
	uint8_t exLen_;
	BiEnd32 extLba_;
	BiEnd32 extSz_;
	uint8_t date_[7];
	uint8_t flags_;
	uint8_t interleaveSz_;
	BiEnd16 seqNum_;
	uint8_t fnameLen_;
	uint8_t len1_;
	uint8_t pad_;

public: // methods
	DirEnt(void);

	void print(void);

} __attribute__((packed));
// g++ requires two parens for some bizarre reason

// all fields in ascii, except TZ
struct DateTime
{
	uint8_t  year_[4];
	uint8_t month_[2];
	uint8_t   day_[2];
	uint8_t  hour_[2];
	uint8_t   min_[2];
	uint8_t   sec_[2];
	uint8_t  hsec_[2];

	uint8_t  tz_; // -48..52

public: // methods
	DateTime(void);

} __attribute__((packed));
// g++ requires two parens for some bizarre reason

struct PrimaryVolDesc : public VolDescBase
{
	//type_ = 1
	uint8_t  unused0_;
	uint8_t  systemId_[32];
	uint8_t  volumeId_[32];
	uint8_t  unused1_[8];
	BiEnd32  volSize_; // in 2KB sectors
	uint8_t  unused2_[32];
	BiEnd16  numDisks_;
	BiEnd16  diskNum_;
	BiEnd16  sectorSize_;
	BiEnd32  pathTableSize_; // in bytes
	uint32_t pathTableLoc_; // LBA
	uint32_t altPTLoc_; // LBA
	uint32_t bigEndPTL_; // LBA
	uint32_t bigEndAPTL_; // LBA

	DirEnt   rootDE_;

	uint8_t  volSetId_[128];
	uint8_t     pubId_[128];
	uint8_t    prepId_[128];
	uint8_t     appId_[128];

	uint8_t copyFile_[38];
	uint8_t  absFile_[36]; // not a typo
	uint8_t  bioFile_[37]; // not a typo

	DateTime volCreate_;
	DateTime volMod_;
	DateTime volExp_;
	DateTime volEff_;

	uint8_t  fsVer_; // 1
	uint8_t  unused3_;

	uint8_t  appAvail_[512];
	uint8_t  rsvd_[653];

public: // methods
	PrimaryVolDesc(void);

	void print(void);

} __attribute__((packed));
// g++ requires two parens for some bizarre reason

struct NullDesc : public VolDescBase
{
	//type_ = 255
	uint8_t unused_[2041];

public:
	NullDesc(void);

} __attribute__((packed));
// g++ requires two parens for some bizarre reason

#endif

