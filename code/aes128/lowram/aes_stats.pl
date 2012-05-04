#!/usr/bin/perl

use strict;

# For ELF analysis: The used AVR device and the object file holding relevant functions
my $device = "atmega128";
my $criticalobject = "aes.o";

# All function names to be filtered (in proper capitalization!)
my @aes_functions = qw(encrypt decrypt expEncKeyAndRoundKey expDecKeyAndRoundKey mixColumns 
                       mixColumns_inv subBytesShiftRows subBytesShiftRows_inv loo loo_1
			asdf normal_round after_l last_round after_2);

# The sum of all critical instructions
my $instruction_count = 0;

printf("___ AES Statistics ___\n\n");

# Extract from the objdump parser output
printf("Lines of code per critical function:\n");
my @objdump_parse = `perl ../../objdump_parser.pl < aes.s.disasm`;
foreach (@objdump_parse) {
  # Extract the function name and counting
  if (/.*?: ((?:[0-9A-Za-z_,.]*)) .*? ([0-9]+)/) {
    # Check if the name is within the set of critical functions
    if (exists {map { $_ => 1 } @aes_functions}->{$1} ) {
        printf("%-23s %d\n", $1, $2);
        $instruction_count += $2;
    }
  }
}

# The sum of all clock cycle critical functions
my $cycles_count = 0;

# Extract from the objdump parser output
printf("\nClock cycles per critical function:\n");
my @simulavr_parse = `perl ../../simulavr_parser.pl < aes.trace.txt`;
foreach (@simulavr_parse) {
  # Extract the function name and counting
  if (/((?:[0-9A-Za-z_,.]*)) .*? ([0-9]+)/) {
    # Check if the name is within the set of critical functions
    if (exists {map { $_ => 1 } @aes_functions}->{$1} ) {
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
printf("Total lines of code: %d\n", $instruction_count);
printf("Total clock cycles: %d\n", $cycles_count);

