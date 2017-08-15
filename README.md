# avr-aes128-groestl256

Optimized assembly implementations of the AES-128 block cipher and Grøstl-256 hash function (SHA-3 finalist) for resource-constrained 8-bit AVR microcontrollers, such as ATmega128.

- All performance-critical design choices and performance stats for each version are provided in `Paper.pdf`  
- `Performance Profiling.xlsx` additionally lists the clock cycles needed depending on the input length.

## Setup

Probably, the easiest way is to build a Docker image based on the provided `Dockerfile` and to use it within an interactive bash session. All implementations are available in subfoldres of `/code/`

```bash
# docker build -t avr-aes128-groestl256 .
# docker run --rm -it avr-aes128-groestl256

# ls -l /code/
total 24
drwxr-xr-x 4 root root 4096 Apr  3  2012 aes128/
drwxr-xr-x 8 root root 4096 Apr  3  2012 groestl256/
-rw-r--r-- 1 root root 1707 Apr  3  2012 objdump_parser.pl
-rw-r--r-- 1 root root 1176 Apr  3  2012 simulavr_parser.pl
-rw-r--r-- 1 root root  835 Apr  3  2012 uart.c
-rw-r--r-- 1 root root  156 Apr  3  2012 uart.h
```

Alternatively, required build dependencies can be installed directly, e.g., on Ubuntu:

```bash
apt-get update; apt-get install -y --no-install-recommends simulavr make avr-libc gdb-avr
```

## AES-128

Assembly versions:

- `normal`: High-speed version with pre-encryption round key generation and S-box in RAM.
- `lowram`: On-the-fly key expansion and S-box in ROM.

In both versions, all loops are unrolled and no macro embedding is used.

### Example: Encryption stats for aes128-lowram

```bash
# cd /code/aes128/lowram/
# make stats
avr-gcc -I.  -g -mmcu=atmega128 -O3 -fpack-struct -fshort-enums -ffunction-sections -fdata-sections -funsigned-bitfields -funsigned-char -Wall -Wstrict-prototypes -Wa,-ahlms=main.lst -c main.c -o main.o
avr-gcc -I.  -g -mmcu=atmega128 -O3 -fpack-struct -fshort-enums -ffunction-sections -fdata-sections -funsigned-bitfields -funsigned-char -Wall -Wstrict-prototypes -Wa,-ahlms=../../uart.lst -c ../../uart.c -o ../../uart.o
avr-gcc -I.  -mmcu=atmega128 -Wa,-gstabs,-ahlms=aes.lst -x assembler-with-cpp  -c aes.S -o aes.o
avr-gcc -Wl,-Map,aes.out.map -mmcu=atmega128 -Wl,-static -Wl,-gc-sections -lm  -o aes.out main.o ../../uart.o aes.o
avr-objdump -S aes.out > aes.s.disasm
simulavr -d atmega128 -f aes.out -T exit -t aes.trace.txt
SystemClock::Endless stopped
number of cpu cycles simulated: 67174
perl aes_stats.pl

___ AES Statistics ___

Lines of code per critical function:
decrypt                 125
encrypt                 165
expEncKeyAndRoundKey    78
mixColumns              133
mixColumns_inv          80
subBytesShiftRows       37
subBytesShiftRows_inv   116

Clock cycles per critical function:
encrypt                 328
expEncKeyAndRoundKey    1250
mixColumns              1224
subBytesShiftRows       720

Memory usage at atmega128:
Flash:  2048 bytes (1.6% Full)
RAM:      16 bytes (0.4% Full)

Summary:
Total lines of code: 734
Total clock cycles: 3522
```

## Grøstl-256

Assembly versions:

- `highspeed`: Assembly macros, no `RCALL` and `RET` calls
- `balanced`: No embedding of _MixBytes_, one `RCALL` instruction
- `lowram256`: S-box values loaded from ROM
- `lowram192a`: Changed _ShiftBytes_ step
- `lowram192b`: Initial message read twice
- `lowram128`: Combination of `lowram192a` and `lowram192b`

All implementations share the same optimized _MixBytes_ computation and the initial message padding.

For each version, the `Makefile` provides several usage options:

```bash
# cd /code/groestl256/highspeed/
# make help
Grøstl Suite v0.1
Author: Johannes Feichtner

Available targets:

- debug:        Runs the simulation with listings of every call and ret instruction
- disasm:       Creates a disassembly using objdump and analyzes it
- dist:         Creates a .tar.gz archive for eBASH
- sim:          Simulates the executable
- stats:        Simulates the executable, creates a disassembly and trace file and analyzes them
- test:         Simulates all known testcases consecutively
- teststats:    Simulates all testcases and fetches the clock cycles needed for execution
- trace:        Simulates the executable with further tracing
```

### Example: Encryption stats for groestl256-highspeed

```bash
# cd /code/groestl256/highspeed/
# make stats
avr-gcc -I.  -g -mmcu=atmega128 -O3 -fpack-struct -fshort-enums -ffunction-sections -fdata-sections -funsigned-bitfields -funsigned-char -Wall -Wstrict-prototypes -Wa,-ahlms=main.lst -c main.c -o main.o
avr-gcc -I.  -g -mmcu=atmega128 -O3 -fpack-struct -fshort-enums -ffunction-sections -fdata-sections -funsigned-bitfields -funsigned-char -Wall -Wstrict-prototypes -Wa,-ahlms=../../uart.lst -c ../../uart.c -o ../../uart.o
avr-gcc -I.  -mmcu=atmega128 -Wa,-gstabs,-ahlms=hash.lst -x assembler-with-cpp -c hash.S -o hash.o
avr-gcc -Wl,-Map,groestl.out.map -mmcu=atmega128 -Wl,-static -Wl,-gc-sections -o groestl.out main.o ../../uart.o hash.o
avr-objdump -S groestl.out > groestl.s.disasm
simulavr -d atmega128 -f groestl.out -T exit -t groestl.trace.txt
SystemClock::Endless stopped
number of cpu cycles simulated: 1394816
perl groestl_stats.pl

___ Groestl Statistics ___

Lines of code per critical function:
crypto_hash             25
loop_blockamount        9
loop_blocks             7
loop_blocks_else        5
loop_blocks_else2       6
loop_blocks_elsif       4
loop_blocks_elsif1      10
loop_blocks_elsif2      3
loop_blocks_elsif3      6
loop_blocks_end         3
loop_blocks_endif       7
loop_blocks_if          8
loop_hstate             11
loop_output1            8
loop_output2            29
loop_permP              1063
loop_permP_end          1
loop_permPIn            15
loop_permQ              1120
loop_permQ_end          1
loop_resetH             17
permP                   3
permQ                   3

Clock cycles per critical function:
crypto_hash             45
loop_blockamount        35
loop_blocks             308
loop_blocks_elsif       4
loop_blocks_elsif1      174
loop_blocks_elsif2      194
loop_blocks_elsif3      9
loop_blocks_end         3
loop_blocks_endif       308
loop_blocks_if          19436
loop_hstate             36739
loop_output1            230
loop_output2            365
loop_permP              565110
loop_permPIn            28732
loop_permP_end          180
loop_permQ              577632
loop_permQ_end          176
loop_resetH             335
permP                   135
permQ                   132

Memory usage at atmega128:
Flash:  4988 bytes (3.8% Full)
RAM:     512 bytes (12.5% Full)

Summary:
Total lines of code: 2364 => Code size: 4728 bytes
Total clock cycles: 1230282
```
