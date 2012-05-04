#!/usr/bin/perl

## This script reads in an objdump disassembly file by STDIN and looks for
## labels and instructions. If a label is found, the amount of subsequent
## instructions is summed up (lines of code per label).
## At the end the start/end offset of the found functions, the label and
## the corresponding instruction count is printed in alphabetical order.
##
## @author: Johannes Feichtner
## @version: 06.01.2012

use strict;

my $totalcount;
my @labels;
my $i;

# loop through each line looking for labels and instructions
while ($_ = <STDIN>) {
  if (/([0-9A-Fa-f]{8}) <(.*)>:/) {
    $#labels++;
    $labels[$#labels]->{'start_address'} = hex($1);
    my $name = $2;
    # crypto_hash_groestl256_8bit_asm is too long to parse so it's stripped
    $name =~ s/_groestl256_8bit_asm//g;
    $labels[$#labels]->{'name'} = $name;
  }
  elsif (/[0-9A-Fa-f]:/) {
    $labels[$#labels]->{count}++;
  }
}

# add the function end offsets, while assuming that the end address might be
# 1 less the start offset of the next label
for ($i = 0; $i < $#labels; $i++) {
  $labels[$i]->{'end_address'} = $labels[$i + 1]->{'start_address'} - 1;
}

# for the last label we have no end offset so let's set a dummy value
$labels[$#labels]->{'end_address'} = hex("FFFFFFFF");

# sort the labels array in alphabetical order
@labels = sort { lc($a->{'name'}) cmp lc($b->{'name'}) } @labels;

printf("Lines of code per function:\n\n");
for ($i = 0; $i <= $#labels; $i++) {
  printf("%08x -> %08x: %-23s $labels[$i]->{'count'}\n",
    $labels[$i]->{'start_address'}, $labels[$i]->{'end_address'}, $labels[$i]->{'name'});
  $totalcount += $labels[$i]->{'count'};
}

printf("\nTotal lines of code: %d\n", $totalcount);

