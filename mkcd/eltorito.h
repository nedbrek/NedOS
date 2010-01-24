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

#endif

