#include <stdio.h>
#include <string.h>
#include <avr/pgmspace.h>
#include "../../uart.h"
#include "aes.h"
#include "testvectors.h"

int main(void)
{
  uint8 pt[16], ct[16], k[16], out[16];
  uint8 i, j;

  initUART();

  for (i = 0; i < TEST_AMOUNT; i++)
  {
    for (j = 0; j < 16; j++)
    {
      pt[j] = pgm_read_byte(&(plain_text[i][j]));
      ct[j] = pgm_read_byte(&(cipher_text[i][j]));
      k[j]  = pgm_read_byte(&(key[i][j]));
    }

    #if ACTION == 1

      encrypt(pt, out, k);
      j = memcmp(ct, out, 16);

    #elif ACTION == 2

      decrypt(ct, out, k);
      j = memcmp(pt, out, 16);

    #endif

    printf("Test %2d: %s\n", i+1, (!j) ? "PASSED" : "FAILED");
  }

  return 0;
}
