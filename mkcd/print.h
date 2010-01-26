#ifndef PRINT_H
#define PRINT_H

///@return true if c is printable
bool isPrintable(uint8_t c);

/// print c like od -tc
void printC(uint8_t c);

/// print len chars from cary using printC
void printStr(uint8_t *cary, unsigned len);

#endif

