#!/usr/bin/perl

use strict 'vars';
use FileHandle;
use Getopt::Std;


sub Main {
  my $line;
  my $fileNumber = 0;
  my $inDocument = 0;
  my $done = 0;
  my $docNumber;
  my $inputFile;
  my $hInputFile;
  my $outputFile;
  my $hOutputFile;
  my $limit = 100000;
  my $prefix = 'fixml';

  getopts('i:n:p:');
  $Getopt::Std::opt_i and $inputFile = $Getopt::Std::opt_i;
  $Getopt::Std::opt_n and $limit = $Getopt::Std::opt_n;
  $Getopt::Std::opt_p and $prefix = $Getopt::Std::opt_p;
  $inputFile and $hInputFile = FileHandle->new("< $inputFile") or
    $hInputFile = "STDIN";

  while (not $done) {
    $docNumber = 0;
    $outputFile = sprintf("%s-%04d.xml", $prefix, $fileNumber);
    $hOutputFile = FileHandle->new("> $outputFile");
    print($hOutputFile '<?xml version="1.0" encoding="UTF-8" ?>', "\n");
    print($hOutputFile '<!DOCTYPE fixmlDocumentCollection SYSTEM "fixml1_0.dtd">', "\n");
    print($hOutputFile '<fixmlDocumentCollection>', "\n");
    while ($docNumber < $limit) {
      $line = <$hInputFile>;
      ($line =~ /^<\/fixmlDocumentCollection>/) and $done = 1;
      if ($line !~ /^<.*>/) {
	print($hOutputFile $line);
	if ($line =~ /^\s*<document>/) {
	  $inDocument = 1;
	}
	if ($line =~ /^\s*<\/document>/) {
	  $inDocument and $docNumber++;
	  $inDocument = 0;
	}
      }
    }
    print($hOutputFile '</fixmlDocumentCollection>', "\n");
    $hOutputFile->close();
    $fileNumber++;
  }
  if ($line =~ /^<\/fixmlDocumentCollection>/) {
    print($hOutputFile $line);
  }
  $hInputFile->close();
}


Main();
