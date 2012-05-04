#ifndef _AES_H
#define _AES_H

// Amount of tests to perform
#define TEST_AMOUNT 1

// Action = 1 -> encrypt
// Action = 2 -> decrypt
#define ACTION 1

typedef unsigned char uint8;

extern void encrypt(const uint8 *in, uint8 *out, const uint8 *key);
extern void decrypt(const uint8 *in, uint8 *out, const uint8 *key);

#endif // _AES_H
