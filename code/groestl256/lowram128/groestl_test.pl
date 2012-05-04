#!/usr/bin/perl

## This script should be used in combination with the adherent Makefile.
## It inserts each single test vector to the test API and then executes the 
## program with "make stats". The return values are then stripped down to
## the input message length and the needed clock cycles. Finally, the clock
## cycles per byte are calculated and printed to teststats.csv.
##
## @author: Johannes Feichtner

use strict;

# A sub routine which writes the test file
sub writeAPI {
  my ($test_min, $test_max, $test_file) = @_;

  open (API, "> test_api.h");
  print API "#define TEST_MIN $test_min\n";
  print API "#define TEST_MAX $test_max\n";
  print API "#include \"$test_file\"\n";
  close (API);
}

# A sub routine to process a file containing test vectors
sub processTestfile {
  my ($test_min, $test_max, $test_file) = @_;

  my $tmp;
  my $msg_len;
  my $c = 0;

  for (my $i = $test_min; $i < $test_max; $i++) {
    writeAPI($i, $i+1, $test_file);
    
    open (my $sim, "-|", "make stats | egrep 'Test|Total clock cycles' | cut -c18-");
    while (<$sim>) {
      $tmp = $_;
      $tmp =~ /(\d+)/;

      # If the auxiliary counter is 0, just save the current line
      # because an output happens every two lines
      if ($c == 0) {
        $msg_len = $1;
        $c++;
      } else {
        my $cycles = $1;
        my $cycle_len = $msg_len;
        if ($msg_len == 0) {
          $cycle_len = 1;
        }
        my $cycles_per_byte = $cycles / $cycle_len;

        printf("%6d\t\t%6d\t\t%6.4f\n", $msg_len, $cycles, $cycles_per_byte);
        $cycles_per_byte = sprintf("%6.4f", $cycles_per_byte);
        # The cycles per byte need to be reformatted because the german excel is stupid
        $cycles_per_byte =~ s/\./,/g;
        printf STATS "$msg_len;$cycles;$cycles_per_byte\n";
        $c = 0;
      }
    }

    close $sim;    
  }
}

# Main routine
printf("___ Groestl Tester ___\n\n");

# If no argument is given, all testcases should be executed
if (length($ARGV[0]) == 0) {
  print "Going to execute all testcases...\n";
  
  # All testvectors from testvectors_small.h
  writeAPI(0, 109, "testvectors_small.h");
  open (my $sim, "|-", "make sim");
  close $sim;

  # All testvectors from testvectors_large.h
  writeAPI(0, 25, "testvectors_large.h");
  open (my $sim, "|-", "make sim");
  close $sim;

} else {
  print "Going to save statistics for every testcase to teststats.csv...\n\n";

  # Write the output to the file and STDOUT
  open (STATS, "> teststats.csv");
  print STATS "Length;Cycles;Cycles per byte\n";
  print "Length\t\tCycles\t\tCycles per byte\n";

  processTestfile(0, 109, "testvectors_small.h");
  processTestfile(0, 25, "testvectors_large.h");

  close (STATS);
}

