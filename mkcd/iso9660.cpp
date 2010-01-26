#include "iso9660.h"
#include <cstring>
#include <arpa/inet.h>
#include <cstdio>
#include <ctype.h>

//----------------------------------------------------------------------------
bool isPrintable(uint8_t c)
{
	if( isalpha(c) ) return true;

	if( '0' <= c && c <= '9' ) return true;

	switch( c )
	{
	case '.': return true;
	case '_': return true;
	case '(': return true;
	case ')': return true;
	}
	return false;
}

void printC(uint8_t c)
{
	if( isPrintable(c) )
		printf("\\%2c ", c);
	else
		printf(" %02x ", c);
}

void printStr(uint8_t *cary, unsigned len)
{
	for(unsigned i = 0; i < len; ++i)
	{
		printC(cary[i]);
		if( i % 16 == 15 ) printf("\n");
	}
	printf("\n");
}

//----------------------------------------------------------------------------
VolDescBase::VolDescBase(void)
{
	type_ = 254; // invalid
	memcpy(cd001_, "CD001", 5);
	version_ = 1;
}

//----------------------------------------------------------------------------
void BiEnd32::set(uint32_t val)
{
	little_ = val;
	big_    = htonl(val);
}

//----------------------------------------------------------------------------
void BiEnd16::set(uint16_t val)
{
	little_ = val;
	big_    = htons(val);
}

//----------------------------------------------------------------------------
DirEnt::DirEnt(void)
{
	memset(weird_, 0, 34);
}

void DirEnt::print(void)
{
	printf("DirEnt in C\n");
	for(unsigned i = 0; i < 34; ++i)
	{
		printC(weird_[i]);
		if( i == 16 ) printf("\n");
	}
	printf("\n");

	printf("DirEnt in 0x\n");
	for(unsigned i = 0; i < 34; ++i)
	{
		printf("%02x ", weird_[i]);
		if( i == 16 ) printf("\n");
	}
	printf("\n");
}

//----------------------------------------------------------------------------
DateTime::DateTime(void)
{
}

//----------------------------------------------------------------------------
PrimaryVolDesc::PrimaryVolDesc(void)
{
	type_    = 1;
	unused0_ = 0;

	memset(systemId_, ' ', 32);
	memcpy(systemId_, "NedOS", 5);

	memset(volumeId_, ' ', 32);
	static const char *const nedOSvolLabel = "NedOS Boot Disk 0.0";
	memcpy(volumeId_, nedOSvolLabel, strlen(nedOSvolLabel)-1);

	memset(unused1_, 0, 8);
	memset(unused2_, 0, 32);

	volSize_.set(0);
	numDisks_.set(1);
	diskNum_.set(1);
	sectorSize_.set(2048);
	pathTableSize_.set(0);
	pathTableLoc_ = 0;
	altPTLoc_ = 0;
	bigEndPTL_ = 0;
	bigEndAPTL_ = 0;

	//rootDE_

	memset(volSetId_, ' ', 128);
	memset(pubId_   , ' ', 128);
	memset(prepId_  , ' ', 128);

	memset(appId_   , ' ', 128);
	static const char *const appId = "NedOS mkcd Utility";
	memcpy(appId_, appId, strlen(appId)-1);

	memset(copyFile_, ' ', 38);
	memset(absFile_ , ' ', 36);
	memset(bioFile_ , ' ', 37);

	//volCreate_;
	//volMod_;
	//volExp_;
	//volEff_;

	fsVer_   = 1;
	unused3_ = 0;

	memset(appAvail_, 0, 512);
	memset(rsvd_,     0, 653);
}

void PrimaryVolDesc::print(void)
{
	printf("Type: %d\n", type_);
	printStr(systemId_, 32);
	printStr(volumeId_, 32);
	printf("VolSize : %d\n", volSize_.little_);
	printf("NumDisks: %d\n", numDisks_.little_);
	printf("DiskNum : %d\n", diskNum_.little_);
	printf("SectorSz: %d\n", sectorSize_.little_);
	printf("PathTblS: %d\n", pathTableSize_.little_);
	printf("PathTblL: %d\n", pathTableLoc_);
	printf("AltPTL  : %d\n", altPTLoc_);

	rootDE_.print();

	printStr(volSetId_, 128);
	printStr(pubId_, 128);
	printStr(prepId_, 128);
	printStr(appId_, 128);

	printStr(copyFile_, 38);
	printStr(absFile_, 36);
	printStr(bioFile_, 37);
}

//----------------------------------------------------------------------------
NullDesc::NullDesc(void)
{
	type_ = 255;
}

