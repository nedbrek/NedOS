#ifndef EL_TORITO_H
#define EL_TORITO_H

#include "iso9660.h"

struct BootRecord : public VolDescBase
{
	//type_ = 0
	uint8_t  bootSysId_[32];
	uint8_t  unused0_[32];
	uint32_t bootCatLoc_;
	uint8_t  unused1_[1973];

public: // methods
	BootRecord(void);

	void print(void);

} __attribute__((packed));
// g++ requires two parens for some bizarre reason

struct BCEntry
{
	uint8_t b_[32];

	BCEntry(void);

	void print(void);

} __attribute__((packed));
// g++ requires two parens for some bizarre reason

struct ValidationEntry // IsA BCEntry
{
	uint8_t  headerID_; // 1
	uint8_t  platformID_; // 0 x86
	uint16_t rsvd_; // 0
	uint8_t  idStr_[24];
	int16_t  checksum_;
	uint8_t  key1_; // 0x55
	uint8_t  key2_; // 0xaa

	ValidationEntry(void);

	bool isValid(void) const;

	void print(void);

} __attribute__((packed));
// g++ requires two parens for some bizarre reason

struct BootCatalog
{
	BCEntry entries_[64];

	BootCatalog(void);

	void print(void);
};

#endif

