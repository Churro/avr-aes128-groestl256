#!/usr/bin/perl

## This script reads in a simulavr trace file by STDIN and looks for
## labels and instruction offsets. The instruction offset is cut off and the
## instructions are summed up in an associative array.
## At the end the array is printed in alphabetical order.
##
## @author: Johannes Feichtner
## @version: 11.01.2012

use strict;

my $filler = '.*?'; # data we don't want
my $variable = '((?:[0-9A-Za-z_,.]*))'; # label / instruction offset (with +0x)

my %assoc_array;
my $temp = '';
my $label = '';

# loop through each line looking for labels and instructions
while ($_ = <STDIN>) {
    if (/.*?: $variable.$filler/) {
        # increment the counter for label $x
        $label = $1;
        # crypto_hash_groestl256_8bit_asm is too long to parse so it's stripped
        $label =~ s/_groestl256_8bit_asm//g;
        $assoc_array{$label}++;
    }
}

printf("Instructions per function:\n\n");

# output the labels array in alphabetical order
my $totalcount = 0;
foreach my $label (sort keys %assoc_array) {
  printf("%-23s $assoc_array{$label}\n", $label);
  $totalcount += $assoc_array{$label};
}

printf("\nTotal instruction count: %d\n", $totalcount);

