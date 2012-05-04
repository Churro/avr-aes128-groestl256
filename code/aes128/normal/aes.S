/**
 * AES-128 implementation for Atmel AVRs
 *
 * Author: Johannes Feichtner
 */

; 16-bit registers
#define XL r26
#define XH r27
#define YL r28
#define YH r29
#define ZL r30
#define ZH r31

; Argument registers for function calls
#define ARG1 r24
#define ARG2 r22
#define ARG3 r20

; Only encrypt and decrypt are callable externally
.global decrypt
.global encrypt

.text

/**
 * push_registers macro:
 *
 * Pushes a given range of registers in ascending order
 * To be called like: push_registers 0,15
 */
.macro push_registers from:req, to:req
  push \from
  .if \to-\from
    push_registers "(\from+1)",\to
  .endif
.endm

/**
 * pop_registers macro:
 *
 * Pops a given range of registers in descending order
 * To be called like: pop_registers 0,15
 */
.macro pop_registers from:req, to:req
  pop \to
  .if \to-\from
    pop_registers \from,"(\to-1)"
  .endif
.endm

/**
 * subBytesShiftRows:
 *
 * r0-r15: state matrix
 * r18: temporary register
 * Z: sbox
 */
subBytesShiftRows:
  ; Do only byte substitution to index 0,4,8,12
  mov ZL, r0
  ld r0, Z
  mov ZL, r4
  ld r4, Z
  mov ZL, r8
  ld r8, Z
  mov ZL, r12
  ld r12, Z

  ; Row 2 shifted by 1
  mov r18, r1
  mov ZL, r5
  ld r1, Z
  mov ZL, r9
  ld r5, Z
  mov ZL, r13
  ld r9, Z
  mov ZL, r18
  ld r13, Z

  ; Row 3 shifted by 2
  mov r18, r10
  mov ZL, r2
  ld r10, Z
  mov ZL, r18
  ld r2, Z
  mov r18, r14
  mov ZL, r6
  ld r14, Z
  mov ZL, r18
  ld r6, Z

  ; Row 4 shifted by 3
  mov r18, r3
  mov ZL, r15
  ld r3, Z
  mov ZL, r11
  ld r15, Z
  mov ZL, r7
  ld r11, Z
  mov ZL, r18
  ld r7, Z

  ret

/**
 * subBytesShiftRows_inv:
 * performs the inverse subBytes and shiftRows and
 * then immediately proceeds with expDecKeyAndRoundKey
 *
 * r0-r15: state matrix
 * r18: temporary register
 * Z: sbox
 */
subBytesShiftRows_inv:
  ldi ZH, hi8(sbox_inv)

  ; Do only byte substitution to index 0,4,8,12
  mov ZL, r0
  ld r0, Z
  mov ZL, r4
  ld r4, Z
  mov ZL, r8
  ld r8, Z
  mov ZL, r12
  ld r12, Z

  mov r18, r1
  mov ZL, r13
  ld r1, Z
  mov ZL, r9
  ld r13, Z
  mov ZL, r5
  ld r9, Z
  mov ZL, r18
  ld r5, Z

  mov r18, r2
  mov ZL, r10
  ld r2, Z
  mov ZL, r18
  ld r10, Z
  mov r18, r3
  mov ZL, r7
  ld r3, Z
  mov ZL, r11
  ld r7, Z
  mov ZL, r15
  ld r11, Z
  mov ZL, r18
  ld r15, Z

  mov r18, r6
  mov ZL, r14
  ld r6, Z
  mov ZL, r18
  ld r14, Z

/**
 * expDecKeyAndRoundKey:
 * performs decryption key expansion and round key addition in one step
 * Note: this function is not called directly but followed by subBytesShiftRows_inv
 *
 * r18-r21, r24, r25: temporary registers
 * whereas r19 has the handed over rcon value
 * Y: key
 * Z: sbox
 */
expDecKeyAndRoundKey:
  ldi ZH, hi8(sbox)

  ; ckey[12] ^= ckey[8];
  ldd r24, Y+8
  ldd r25, Y+12
  eor r25, r24
  eor r12, r25 ; state[12] ^= ckey[12];
  std Y+12, r25

  ; ckey[13] ^= ckey[9];
  ldd r25, Y+9
  ldd r18, Y+13
  eor r18, r25
  eor r13, r18
  std Y+13, r18

  ; ckey[14] ^= ckey[10];
  ldd r18, Y+10
  ldd r20, Y+14
  eor r20, r18
  eor r14, r20
  std Y+14, r20

  ; ckey[15] ^= ckey[11];
  ldd r20, Y+11
  ldd r21, Y+15
  eor r21, r20
  eor r15, r21
  std Y+15, r21

  ; ckey[8] ^= ckey[4];
  ldd r21, Y+4
  eor r24, r21
  eor r8, r24
  std Y+8, r24

  ; ckey[9] ^= ckey[5];
  ldd r24, Y+5
  eor r25, r24
  eor r9, r25
  std Y+9, r25

  ; ckey[10] ^= ckey[6];
  ldd r25, Y+6
  eor r18, r25
  eor r10, r18
  std Y+10, r18

  ; ckey[11] ^= ckey[7]
  ldd r18, Y+7
  eor r20, r18
  eor r11, r20
  std Y+11, r20

  ; ckey[4] ^= ckey[0];
  ld r20, Y
  eor r21, r20
  eor r4, r21
  std Y+4, r21

  ; ckey[5] ^= ckey[1];
  ldd r21, Y+1
  eor r24, r21
  eor r5, r24
  std Y+5, r24

  ; ckey[6] ^= ckey[2];
  ldd r24, Y+2
  eor r25, r24
  eor r6, r25
  std Y+6, r25

  ; ckey[7] ^= ckey[3];
  ldd r25, Y+3
  eor r18, r25
  eor r7, r18
  std Y+7, r18

  ; ckey[3] ^= sbox[ckey[12]];
  ldd r18, Y+12
  mov ZL, r18
  ld r18, Z
  eor r25, r18
  eor r3, r25
  std Y+3, r25

  ; ckey[2] ^= sbox[ckey[15]];
  ldd r25, Y+15
  mov ZL, r25
  ld r25, Z
  eor r24, r25
  eor r2, r24
  std Y+2, r24

  ; ckey[1] ^= sbox[ckey[14]];
  ldd r24, Y+14
  mov ZL, r24
  ld r24, Z
  eor r21, r24
  eor r1, r21
  std Y+1, r21

  ; ckey[0] ^= sbox[ckey[13]] ^ rcon;
  ldd r21, Y+13
  mov ZL, r21
  ld r21, Z
  eor r20, r21
  eor r20, r19
  eor r0, r20
  st Y, r20

  ret

/**
 * mixColumns_inv:
 *
 * r0-r15: state matrix
 * r16: irreducible polynomial
 * r18-r21, r24-r26: temporary registers
 * Z: sbox
 */
mixColumns_inv:
  ; First row
  mov r18, r0
  eor r18, r2
  add r18, r18
  brcc .+2
  eor r18, r16
  add r18, r18
  brcc .+2
  eor r18, r16

  mov r19, r1
  eor r19, r3
  add r19, r19
  brcc .+2
  eor r19, r16
  add r19, r19
  brcc .+2
  eor r19, r16

  eor r0, r18
  eor r1, r19
  eor r2, r18
  eor r3, r19

  ; Second row
  mov r18, r4
  eor r18, r6
  add r18, r18
  brcc .+2
  eor r18, r16
  add r18, r18
  brcc .+2
  eor r18, r16

  mov r19, r5
  eor r19, r7
  add r19, r19
  brcc .+2
  eor r19, r16
  add r19, r19
  brcc .+2
  eor r19, r16

  eor r4, r18
  eor r5, r19
  eor r6, r18
  eor r7, r19

  ; Third row
  mov r18, r8
  eor r18, r10
  add r18, r18
  brcc .+2
  eor r18, r16
  add r18, r18
  brcc .+2
  eor r18, r16

  mov r19, r9
  eor r19, r11
  add r19, r19
  brcc .+2
  eor r19, r16
  add r19, r19
  brcc .+2
  eor r19, r16

  eor r8, r18
  eor r9, r19
  eor r10, r18
  eor r11, r19

  ; Fourth row
  mov r18, r12
  eor r18, r14
  add r18, r18
  brcc .+2
  eor r18, r16
  add r18, r18
  brcc .+2
  eor r18, r16

  mov r19, r13
  eor r19, r15
  add r19, r19
  brcc .+2
  eor r19, r16
  add r19, r19
  brcc .+2
  eor r19, r16

  eor r12, r18
  eor r13, r19
  eor r14, r18
  eor r15, r19

/**
 * mixColumns:
 *
 * r0-r15: state matrix
 * r16: irreducible polynomial
 * r18-r21, r24: temporary registers
 * Z: sbox
 */
mixColumns:
  ; First row
  mov r18, r0 ; t0 = state[0] ^ state[1];
  eor r18, r1
  mov r19, r1 ; t1 = state[1] ^ state[2];
  eor r19, r2
  mov r20, r2 ; t2 = state[2] ^ state[3];
  eor r20, r3
  mov r21, r3 ; t3 = state[3] ^ state[0];
  eor r21, r0
  mov r24, r0 ; i = state[0];

  mov r0, r18 ; state[0] = mul2[t0] ^ t1 ^ state[3];
  add r0, r0
  brcc .+2
  eor r0, r16
  eor r0, r19
  eor r0, r3

  mov r3, r21 ; state[3] = mul2[t3] ^ t0 ^ state[2];
  add r3, r3
  brcc .+2
  eor r3, r16
  eor r3, r18
  eor r3, r2

  mov r2, r20 ; state[2] = mul2[t2] ^ t3 ^ state[1];
  add r2, r2
  brcc .+2
  eor r2, r16
  eor r2, r21
  eor r2, r1

  mov r1, r19 ; state[1] = mul2[t1] ^ t2 ^ i;
  add r1, r1
  brcc .+2
  eor r1, r16
  eor r1, r20
  eor r1, r24

  ; Second row
  mov r18, r4 ; t0 = state[4] ^ state[5];
  eor r18, r5
  mov r19, r5 ; t1 = state[5] ^ state[6];
  eor r19, r6
  mov r20, r6 ; t2 = state[6] ^ state[7];
  eor r20, r7
  mov r21, r7 ; t3 = state[7] ^ state[4];
  eor r21, r4
  mov r24, r4 ; i = state[4];

  mov r4, r18 ; state[4] = mul2[t0] ^ t1 ^ state[7];
  add r4, r4
  brcc .+2
  eor r4, r16
  eor r4, r19
  eor r4, r7

  mov r7, r21 ; state[7] = mul2[t3] ^ t0 ^ state[6];
  add r7, r7
  brcc .+2
  eor r7, r16
  eor r7, r18
  eor r7, r6

  mov r6, r20 ; state[6] = mul2[t2] ^ t3 ^ state[5];
  add r6, r6
  brcc .+2
  eor r6, r16
  eor r6, r21
  eor r6, r5

  mov r5, r19 ; state[5] = mul2[t1] ^ t2 ^ i;
  add r5, r5
  brcc .+2
  eor r5, r16
  eor r5, r20
  eor r5, r24

  ; Third row
  mov r18, r8 ; t0 = state[8] ^ state[9];
  eor r18, r9
  mov r19, r9 ; t1 = state[9] ^ state[10];
  eor r19, r10
  mov r20, r10 ; t2 = state[10] ^ state[11];
  eor r20, r11
  mov r21, r11 ; t3 = state[11] ^ state[8];
  eor r21, r8
  mov r24, r8 ; i = state[8];

  mov r8, r18 ; state[8] = mul2[t0] ^ t1 ^ state[11];
  add r8, r8
  brcc .+2
  eor r8, r16
  eor r8, r19
  eor r8, r11

  mov r11, r21 ; state[11] = mul2[t3] ^ t0 ^ state[10];
  add r11, r11
  brcc .+2
  eor r11, r16
  eor r11, r18
  eor r11, r10

  mov r10, r20 ; state[10] = mul2[t2] ^ t3 ^ state[9];
  add r10, r10
  brcc .+2
  eor r10, r16
  eor r10, r21
  eor r10, r9

  mov r9, r19 ; state[9] = mul2[t1] ^ t2 ^ i;
  add r9, r9
  brcc .+2
  eor r9, r16
  eor r9, r20
  eor r9, r24

  ; Fourth row
  mov r18, r12 ; t0 = state[12] ^ state[13];
  eor r18, r13
  mov r19, r13 ; t1 = state[13] ^ state[14];
  eor r19, r14
  mov r20, r14 ; t2 = state[14] ^ state[15];
  eor r20, r15
  mov r21, r15 ; t3 = state[15] ^ state[12];
  eor r21, r12
  mov r24, r12 ; i = state[12];

  mov r12, r18 ; state[12] = mul2[t0] ^ t1 ^ state[15];
  add r12, r12
  brcc .+2
  eor r12, r16
  eor r12, r19
  eor r12, r15

  mov r15, r21 ; state[15] = mul2[t3] ^ t0 ^ state[14];
  add r15, r15
  brcc .+2
  eor r15, r16
  eor r15, r18
  eor r15, r14

  mov r14, r20 ; state[14] = mul2[t2] ^ t3 ^ state[13];
  add r14, r14
  brcc .+2
  eor r14, r16
  eor r14, r21
  eor r14, r13

  mov r13, r19 ; state[13] = mul2[t1] ^ t2 ^ i;
  add r13, r13
  brcc .+2
  eor r13, r16
  eor r13, r20
  eor r13, r24

  ret

/**
 * expEncKeyAndRoundKey:
 * performs encryption key expansion and round key addition in one step
 *
 * r18-r21, XL: temporary registers
 * whereas r19 has the handed over rcon value
 * Y: key
 * Z: sbox
 */
expEncKeyAndRoundKey:
  ; ckey[0] ^= sbox[ckey[13]] ^ rcon;
  ldd XL, Y+13 ; XL <- ckey[13]
  mov ZL, XL ; XL <- sbox[ckey[13]]
  ld XL, Z
  ld r21, Y ; r21 <- ckey[0]
  eor r21, XL
  eor r21, r19
  eor r0, r21 ; state[0] ^= ckey[0];
  st Y, r21

  ; ckey[1] ^= sbox[ckey[14]];
  ldd XL, Y+14
  mov ZL, XL
  ld XL, Z
  ldd r18, Y+1
  eor r18, XL
  eor r1, r18
  std Y+1, r18

  ; ckey[2] ^= sbox[ckey[15]];
  ldd XL, Y+15
  mov ZL, XL
  ld XL, Z
  ldd r19, Y+2
  eor r19, XL
  eor r2, r19
  std Y+2, r19

  ; ckey[3] ^= sbox[ckey[12]];
  ldd XL, Y+12
  mov ZL, XL
  ld XL, Z
  ldd r20, Y+3
  eor r20, XL
  eor r3, r20
  std Y+3, r20

  ; ckey[4] ^= ckey[0];
  ldd XL, Y+4
  eor XL, r21
  eor r4, XL
  std Y+4, XL

  ; ckey[5] ^= ckey[1];
  ldd r21, Y+5
  eor r21, r18
  eor r5, r21
  std Y+5, r21

  ; ckey[6] ^= ckey[2];
  ldd r18, Y+6
  eor r18, r19
  eor r6, r18
  std Y+6, r18

  ; ckey[7] ^= ckey[3];
  ldd r19, Y+7
  eor r19, r20
  eor r7, r19
  std Y+7, r19

  ; ckey[8] ^= ckey[4];
  ldd r20, Y+8
  eor r20, XL
  eor r8, r20
  std Y+8, r20

  ; ckey[9] ^= ckey[5];
  ldd XL, Y+9
  eor XL, r21
  eor r9, XL
  std Y+9, XL

  ; ckey[10] ^= ckey[6];
  ldd r21, Y+10
  eor r21, r18
  eor r10, r21
  std Y+10, r21

  ; ckey[11] ^= ckey[7];
  ldd r18, Y+11
  eor r18, r19
  eor r11, r18
  std Y+11, r18

  ; ckey[12] ^= ckey[8];
  ldd r19, Y+12
  eor r19, r20
  eor r12, r19
  std Y+12, r19

  ; ckey[13] ^= ckey[9];
  ldd r20, Y+13
  eor r20, XL
  eor r13, r20
  std Y+13, r20

  ; ckey[14] ^= ckey[10];
  ldd XL, Y+14
  eor XL, r21
  eor r14, XL
  std Y+14, XL

  ; ckey[15] ^= ckey[11];
  ldd r21, Y+15
  eor r21, r18
  eor r15, r21
  std Y+15, r21

  ret

/**
 * encrypt
 *
 * r0-r15: state matrix
 * r16: irreducible polynomial
 * r18-r20: temporary variables
 * Z: plaintext
 * Y: key / output
 *
 * Note:
 * r18-r27, r30-31 are call-used registers
 * r20 provides ARG3 and can be used regularily after being copied to YL
 * According to the avr-libc FAQ they need not to be pushed/popped
 */
encrypt:
  ; Push r0-r16 for the state matrix
  push_registers 0,16

  ; Push the remaining call-saved registers
  push YL
  push YH

  ; Save the argument pointers to Z (plaintext) and X (key)
  movw XL, ARG1
  movw ZL, ARG3

  ; Load the plaintext given by argument to register 0-15
  .irp param,r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15
    ld \param, X+
  .endr

  ; Load in the key to Y and do the first addRoundKey
  ldi YH, hi8(key)
  ldi YL, lo8(key)

  .irp param,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
    ldd r18, Z+\param
    std Y+\param, r18
    eor r\param, r18
  .endr

  ; The irreducible polynomial is held consistently in r16, the sbox in Z
  ldi r16, 0x1b
  ldi ZH, hi8(sbox)

  rcall subBytesShiftRows
  rcall mixColumns
  ldi r19, 0x01 ; rcon value
  rcall expEncKeyAndRoundKey

  rcall subBytesShiftRows
  rcall mixColumns
  ldi r19, 0x02
  rcall expEncKeyAndRoundKey

  rcall subBytesShiftRows
  rcall mixColumns
  ldi r19, 0x04
  rcall expEncKeyAndRoundKey

  rcall subBytesShiftRows
  rcall mixColumns
  ldi r19, 0x08
  rcall expEncKeyAndRoundKey

  rcall subBytesShiftRows
  rcall mixColumns
  ldi r19, 0x10
  rcall expEncKeyAndRoundKey

  rcall subBytesShiftRows
  rcall mixColumns
  ldi r19, 0x20
  rcall expEncKeyAndRoundKey

  rcall subBytesShiftRows
  rcall mixColumns
  ldi r19, 0x40
  rcall expEncKeyAndRoundKey

  rcall subBytesShiftRows
  rcall mixColumns
  ldi r19, 0x80
  rcall expEncKeyAndRoundKey

  rcall subBytesShiftRows
  rcall mixColumns
  ldi r19, 0x1B
  rcall expEncKeyAndRoundKey

  rcall subBytesShiftRows
  ldi r19, 0x36
  rcall expEncKeyAndRoundKey

  ; Save the final state from the registers to Y (ARG2)
  movw YL, ARG2

  .irp param,r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15
    st Y+, \param
  .endr

  ; Pop the call-saved registers
  pop YH
  pop YL

  ; Pop the state matrix registers
  pop_registers 0,16

  ret

/**
 * decrypt
 *
 * r0-r15: state matrix
 * r16: irreducible polynomial
 * r18-r20: temporary variables
 * Z: plaintext
 * Y: key / output
 *
 * Note:
 * r18-r27, r30-31 are call-used registers
 * r20/r21 provides ARG3 and can be used regularily after being copied to Y
 * According to the avr-libc FAQ they need not to be pushed/popped
 */
decrypt:
  ; Push r0-r15 for the state matrix
  push_registers 0,15

  ; Push the remaining call-saved registers
  push r16
  push YL
  push YH

  ; Save the argument pointers to Z (plaintext) and Y (key)
  movw YL, ARG3

  ; The irreducible polynomial is held consistently in r16, the sbox in Z
  ldi r16, 0x1b
  ldi ZH, hi8(sbox)

  ; Unroll the key
  ldi r19, 0x01
  rcall expEncKeyAndRoundKey
  ldi r19, 0x02
  rcall expEncKeyAndRoundKey
  ldi r19, 0x04
  rcall expEncKeyAndRoundKey
  ldi r19, 0x08
  rcall expEncKeyAndRoundKey
  ldi r19, 0x10
  rcall expEncKeyAndRoundKey
  ldi r19, 0x20
  rcall expEncKeyAndRoundKey
  ldi r19, 0x40
  rcall expEncKeyAndRoundKey
  ldi r19, 0x80
  rcall expEncKeyAndRoundKey
  ldi r19, 0x1B
  rcall expEncKeyAndRoundKey

  movw XL, ARG1
  ; Load the plaintext given by argument to register 0-15
  .irp param,r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15
    ld \param, X+
  .endr

  ; At the last encryption key expansion step,
  ; the first addRoundKey (belonging to the decryption process) is performed too
  ldi r19, 0x36
  rcall expEncKeyAndRoundKey

  ; Do the decryption
  ldi r19, 0x36
  ; subBytesShiftRows_inv consecutively calls
  ; expDecKeyAndAddRoundKey (this way, rcall & ret can be omitted)
  rcall subBytesShiftRows_inv

  rcall mixColumns_inv
  ldi r19, 0x1B
  rcall subBytesShiftRows_inv

  rcall mixColumns_inv
  ldi r19, 0x80
  rcall subBytesShiftRows_inv

  rcall mixColumns_inv
  ldi r19, 0x40
  rcall subBytesShiftRows_inv

  rcall mixColumns_inv
  ldi r19, 0x20
  rcall subBytesShiftRows_inv

  rcall mixColumns_inv
  ldi r19, 0x10
  rcall subBytesShiftRows_inv

  rcall mixColumns_inv
  ldi r19, 0x08
  rcall subBytesShiftRows_inv

  rcall mixColumns_inv
  ldi r19, 0x04
  rcall subBytesShiftRows_inv

  rcall mixColumns_inv
  ldi r19, 0x02
  rcall subBytesShiftRows_inv

  rcall mixColumns_inv
  ldi r19, 0x01
  rcall subBytesShiftRows_inv

  ; Save the final state from the registers to Y (ARG2)
  movw YL, ARG2

  .irp param,r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15
    st Y+, \param
  .endr

  ; Pop the call-saved registers
  pop YH
  pop YL
  pop r16

  ; Pop the state matrix registers
  pop_registers 0,15

  ret

; 16 bytes are allocated uninitialized for the key
.section .bss

key:
.fill 16, 1, 0

; The following tables reside in RAM
.data
.balign 256

sbox:
.byte 0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5, 0x30, 0x01, 0x67, 0x2B, 0xFE, 0xD7, 0xAB, 0x76
.byte 0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0, 0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0
.byte 0xB7, 0xFD, 0x93, 0x26, 0x36, 0x3F, 0xF7, 0xCC, 0x34, 0xA5, 0xE5, 0xF1, 0x71, 0xD8, 0x31, 0x15
.byte 0x04, 0xC7, 0x23, 0xC3, 0x18, 0x96, 0x05, 0x9A, 0x07, 0x12, 0x80, 0xE2, 0xEB, 0x27, 0xB2, 0x75
.byte 0x09, 0x83, 0x2C, 0x1A, 0x1B, 0x6E, 0x5A, 0xA0, 0x52, 0x3B, 0xD6, 0xB3, 0x29, 0xE3, 0x2F, 0x84
.byte 0x53, 0xD1, 0x00, 0xED, 0x20, 0xFC, 0xB1, 0x5B, 0x6A, 0xCB, 0xBE, 0x39, 0x4A, 0x4C, 0x58, 0xCF
.byte 0xD0, 0xEF, 0xAA, 0xFB, 0x43, 0x4D, 0x33, 0x85, 0x45, 0xF9, 0x02, 0x7F, 0x50, 0x3C, 0x9F, 0xA8
.byte 0x51, 0xA3, 0x40, 0x8F, 0x92, 0x9D, 0x38, 0xF5, 0xBC, 0xB6, 0xDA, 0x21, 0x10, 0xFF, 0xF3, 0xD2
.byte 0xCD, 0x0C, 0x13, 0xEC, 0x5F, 0x97, 0x44, 0x17, 0xC4, 0xA7, 0x7E, 0x3D, 0x64, 0x5D, 0x19, 0x73
.byte 0x60, 0x81, 0x4F, 0xDC, 0x22, 0x2A, 0x90, 0x88, 0x46, 0xEE, 0xB8, 0x14, 0xDE, 0x5E, 0x0B, 0xDB
.byte 0xE0, 0x32, 0x3A, 0x0A, 0x49, 0x06, 0x24, 0x5C, 0xC2, 0xD3, 0xAC, 0x62, 0x91, 0x95, 0xE4, 0x79
.byte 0xE7, 0xC8, 0x37, 0x6D, 0x8D, 0xD5, 0x4E, 0xA9, 0x6C, 0x56, 0xF4, 0xEA, 0x65, 0x7A, 0xAE, 0x08
.byte 0xBA, 0x78, 0x25, 0x2E, 0x1C, 0xA6, 0xB4, 0xC6, 0xE8, 0xDD, 0x74, 0x1F, 0x4B, 0xBD, 0x8B, 0x8A
.byte 0x70, 0x3E, 0xB5, 0x66, 0x48, 0x03, 0xF6, 0x0E, 0x61, 0x35, 0x57, 0xB9, 0x86, 0xC1, 0x1D, 0x9E
.byte 0xE1, 0xF8, 0x98, 0x11, 0x69, 0xD9, 0x8E, 0x94, 0x9B, 0x1E, 0x87, 0xE9, 0xCE, 0x55, 0x28, 0xDF
.byte 0x8C, 0xA1, 0x89, 0x0D, 0xBF, 0xE6, 0x42, 0x68, 0x41, 0x99, 0x2D, 0x0F, 0xB0, 0x54, 0xBB, 0x16

sbox_inv:
.byte 0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb
.byte 0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb
.byte 0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e
.byte 0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25
.byte 0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92
.byte 0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84
.byte 0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06
.byte 0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b
.byte 0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73
.byte 0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e
.byte 0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b
.byte 0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4
.byte 0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f
.byte 0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef
.byte 0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61
.byte 0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
