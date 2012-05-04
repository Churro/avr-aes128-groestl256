#!/usr/bin/perl

use strict;

# For ELF analysis: The used AVR device and the object file holding relevant functions
my $device = "atmega128";
my $criticalobject = "hash.o";

# All function names to be filtered (in proper capitalization!)
my @groestl_functions = qw(mixBytes permP loop_permP loop_permP_end permQ loop_permQ loop_permQ_end crypto_hash
			   loop_resetH loop_blockamount loop_blocks # 1st level labels in hash
			   loop_blocks_elsif loop_blocks_else loop_blocks_endif # 2nd level labels (context: loop_blocks)
			   loop_blocks_if loop_blocks_elsif1 loop_blocks_elsif2 loop_blocks_elsif3 loop_blocks_else1 loop_blocks_else2
			   loop_permPIn ploop_hstate qloop_hstate processQ loop_blocks_end loop_output1 loop_output2); # 1st level in hash

# The sum of all critical instructions
my $instruction_count = 0;

printf("___ Groestl Statistics ___\n\n");

# Extract from the objdump parser output
printf("Lines of code per critical function:\n");
my @objdump_parse = `perl ../../objdump_parser.pl < groestl.s.disasm`;
foreach (@objdump_parse) {
  # Extract the function name and counting
  if (/.*?: ((?:[0-9A-Za-z_,.]*)) .*? ([0-9]+)/) {
    # Check if the name is within the set of critical functions
    if (exists {map { $_ => 1 } @groestl_functions}->{$1}) {
        printf("%-23s %d\n", $1, $2);
        $instruction_count += $2;
    }
  }
}

# The sum of all clock cycle critical functions
my $cycles_count = 0;

# Extract from the objdump parser output
printf("\nClock cycles per critical function:\n");
my @simulavr_parse = `perl ../../simulavr_parser.pl < groestl.trace.txt`;
foreach (@simulavr_parse) {
  # Extract the function name and counting
  if (/((?:[0-9A-Za-z_,.]*)) .*? ([0-9]+)/) {
    # Check if the name is within the set of critical functions
    if (exists {map { $_ => 1 } @groestl_functions}->{$1} ) {
        printf("%-23s %d\n", $1, $2);
        $cycles_count += $2;
    }
  }
}

# Get further statistics from the encryption/decryption object (only!)
printf("\nMemory usage at $device:\n");
# Lines, beginning with Program or Data are read into an array line-per-line.
# The words 'Program' and 'Data' are cut off, to be substituted by 'Flash' and 'Ram'
my @avr_size = `avr-size -C $criticalobject --mcu=$device | egrep '(^Program|^Data)' | cut -c12-`;
chomp(@avr_size);
printf("Flash: %s\n", $avr_size[0]);
printf("RAM:   %s\n", $avr_size[1]);

printf("\nSummary:\n");
printf("Total lines of code: %d => Code size: %d bytes\n", $instruction_count, $instruction_count * 2);
printf("Total clock cycles: %d\n", $cycles_count);
