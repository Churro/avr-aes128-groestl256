#include <avr/pgmspace.h>
#include <stdio.h>
#include <string.h>
#include "../../uart.h"
#include "hash.h"
#include "test_api.h"

int main(void)
{
  unsigned char in[VECTORS_MAXBYTES], out[32], exp[32];
  unsigned int inlen, test_no, j;

  initUART();

  for (test_no = TEST_MIN; test_no < TEST_MAX; test_no++)
  {
    // If the large testvectors file is included, the length isn't consecutive
    // and so it's read in. In case of the small vectors, it's ascending.
    #if defined (_TESTVECTORS_LARGE_H)
      inlen = pgm_read_word(&lengths[test_no]);

      // First read in the pointer to the target array, then the target array
      const unsigned char *pp = (unsigned char*)pgm_read_word(&plain_text[test_no]);
      for (j = 0; j < inlen; j++) in[j] = pgm_read_byte(&(pp[j]));

      pp = (unsigned char*)pgm_read_word(&expected_hash[test_no]);
      for (j = 0; j < 32; j++) exp[j] = pgm_read_byte(&(pp[j]));
    #else
      inlen = test_no;

      for (j = 0; j < inlen; j++) in[j] = pgm_read_byte(&(plain_text[test_no][j]));
      for (j = 0; j < 32; j++) exp[j] = pgm_read_byte(&(expected_hash[test_no][j]));
    #endif

    crypto_hash_groestl256_8bit_asm(out, in, inlen);
    j = memcmp(exp, out, 32);

    printf("Test %3d, length: %4d: %s\n", test_no+1, inlen, (!j) ? "PASSED" : "FAILED");
  }

  return 0;
}
