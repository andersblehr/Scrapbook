#!/usr/bin/perl
###############################################################################
# Script:   fixmlconvert.pl
# Author:   Anders Blehr (Fast Search & Transfer, Inc.)
# Function: Converts arbitrary, tag-based data formats to FIXML (Fast IndeXing
#           Markup Language).  Reads input either from STDIN or from one or
#           more input files
# Usage:    fixmlconvert.pl -m <mapping file> [-v <log level>]
###############################################################################

use strict 'vars';
use Getopt::Std;
use FileHandle;
use lib "/shome/fast/include";

use fixmlDocumentCollection;
use fixmlDocument;
use fixmlCatalog;
use fixmlRankClass;
use fixmlSummaryClass;

my $_start = 0;
my $_filler = 1;
my $_data = 2;
my $_skip = 3;

my $mappingFile;
my $hMappingFile;
my $verbose = 0;
my $CDATA = undef;


###############################################################################
# Subroutine: IfVerbose
# Parameters: level       - Log level for this message to be displayed
#             text        - Message text
#             (optparam1) - Optional parameter 1
#             (optparam2) - Optional parameter 2
#             (...)       - ...
# Function:   IfVerbose sends 'text' and optional parameters to STDERR if
#             'level' is less than or equal to log level set by using -v option
#             at startup.
###############################################################################
sub IfVerbose {
  my $level = shift();
  my $more;

  ($level <= $verbose) and do {
    chomp($more = shift());
    print(STDERR $more);
    chomp($more = shift());
    defined($more) and print(STDERR ': ', $more);
    while (defined($more = shift())) {
      chomp($more);
      print(STDERR ', ', $more);
    }
    print(STDERR "\n");
  }
}


###############################################################################
# Subroutine: GetOptions
# Parameters: <none>
# Function:   GetOptions parses and interprets the command line parameters
#             that were passed at startup.
###############################################################################
sub GetOptions {
  getopts('m:v:c');

  # $mappingFile stores the name of the mapping file
  $Getopt::Std::opt_m and $mappingFile = $Getopt::Std::opt_m;

  # $verbose stores the log level (0 = no logging)
  $Getopt::Std::opt_v and $verbose = $Getopt::Std::opt_v;

  # $CDATA indicates whether data should be embedded in <![CDATA[...]>
  $Getopt::Std::opt_c and $CDATA = 'CDATA';
}


###############################################################################
# Subroutine: GetDataStructure
# Paramaters: pattern  - Data pattern from mapping file (e.g., 'tag+data+EOL')
# Function:   GetDataStructure stores the supplied data pattern in the internal
#             mapping definition structure.  The pattern is used during
#             processing of input data.
###############################################################################
sub GetDataStructure {
  IfVerbose(1, 'Enter: GetDataStructure()');

  my ($pattern) = @_;
  my @elements = split(/\+/, $pattern);
  my $i = 0;
  my %dataStructure;

  # Start element should always be present as first element
  $dataStructure{start} = $elements[$i++];

  # If second element is not 'data', it is 'filler'
  ($elements[$i] ne 'data') and $dataStructure{filler} = $elements[$i++];

  # Last element is end element (don't need to store data element)
  $dataStructure{end} = $elements[++$i];

  IfVerbose(1, 'Exit:  GetDataStructure()');

  return(\%dataStructure);
}


###############################################################################
# Subroutine: ReadMappingDefinition
# Parameters: <none> (Mapping file is supplied with the -m command line option)
# Function:   ReadMappingDefinition reads the mapping definition from the
#             mapping file specified on the command line and stores it in the
#             internal mapping definition structure.
#
#             Lines in the mapping files are either header or data description
#             lines, indicated by putting either an 'H' or a 'D' at the
#             beginning of the line.  Cf. the documentation for a full
#             description of the format of the mapping file.
###############################################################################
sub ReadMappingDefinition {
  IfVerbose(1, 'Enter: ReadMappingDefinition()', @_);

  my $thisTag;
  my $thisFile;
  my %definition;
  my $fieldNo = 0;
  my $fileNo = 0;

  # Verify that mapping file name has been supplied
  defined($mappingFile) or
    die("Use -m option to specify mapping file.\n");

  # Open mapping file
  $hMappingFile = FileHandle->new($mappingFile, "r");

  # Verify that mapping file exists as supplied
  defined($hMappingFile) or
    die("Mapping file \'$mappingFile\' does not exist.\n");

  # Iterate through all lines in mapping file
  while (chomp(my @definitionLine = split(/ /, <$hMappingFile>))) {

    # Determine if line is a header or data line
    my $lineIdentifier = shift(@definitionLine);
    my $headerLine = ($lineIdentifier eq 'H');
    my $dataLine = ($lineIdentifier eq 'D');

    # Iterate through all definitions in line
    foreach my $definition (@definitionLine) {
      
      # Split definition into identifier (tag) and data
      my ($tag, @data) = split(/:/, $definition);
      my $data = $data[0];

      # Reconstruct data portion if it contained ':' (split character)
      if ($#data > 0) {
	for my $i (1 .. $#data) {
	  $data .= (':' . $data[$i]);
	}
      }

      # In case $data is on form <data>@<operation>
      ($data, my $operation) = split(/@/, $data);

      if ($headerLine) {
	IfVerbose(3, 'Found header tag "' . $tag. '".');

      SWITCH: {

	  # 'files': For each file, store name, open file and store handle
	  ($tag eq 'files') and do {
	    my @files = split(/,/, $data);
	    for my $i (0 .. $#files) {
	      my ($id, $name) = split(/=/, $files[$i]);
	      $definition{files}{$id}{name} = $name;
	      if ($name eq 'STDIN') {
		$definition{files}{$id}{handle} = $name;
	      } else {
		local *H;
		open(H, "< $name");
		$definition{files}{$id}{handle} = *H;
	      }
	      IfVerbose(4, 'Storing file: ', $name);
	    }
	    last SWITCH;
	  };

	  # 'delimiters': Store delimiters in mapping definition
	  ($tag eq 'delimiters') and do {
	    my @delimiters = split(/,/, $data);
	    for my $i (0 .. $#delimiters) {
	      my ($id, $delimiters) = split(/=/, $delimiters[$i]);
	      $delimiters =~ s/([\\\(\)\[\{\^\$\*\+\?\.])/\\$1/g;
	      $definition{files}{$id}{delimiters} = $delimiters;
	      IfVerbose(4, 'Storing delimiters: ', $delimiters);
	    }
	    last SWITCH;
	  };

	  # 'linetypes': Store line (i.e., data) structures in mapping def.
	  ($tag eq 'linetypes') and do {
	    my @lineTypes = split(/,/, $data);
	    for my $i (0 .. $#lineTypes) {
	      my ($id, $pattern) = split(/=/, $lineTypes[$i]);
	      $definition{files}{$id}{structure} = GetDataStructure($pattern);
	      IfVerbose(4, 'Storing line type: ', $pattern);
	    }
	    last SWITCH;
	  };

	  # 'recordtypes': Store delimiters and associated record type names
	  ($tag eq 'recordtypes') and do {
	    my @typeLists = split(/,/, $data);
	    for my $i (0 .. $#typeLists) {
	      my ($id, $typeList) = split(/=/, $typeLists[$i]);
	      my @recordTypes = split(/\|/, $typeList);
	      for my $j (0 .. $#recordTypes) {
		my ($typeName, $delimiter) = split(/[\(\)]/, $recordTypes[$j]);
		$definition{recordTypes}{$id}{names}{$delimiter} = $typeName;
		IfVerbose(4, 'Storing record type: ', $typeName);
	      }
	    }
	    last SWITCH;
	  };
	}

      }

      if ($dataLine) {
	IfVerbose(3, 'Found data tag "' . $tag. '".');

      SWITCH: {

	  # 'file': Remember this file
	  ($tag eq 'file') and do {
	    $thisFile = $data;
	    last SWITCH;
	  };

	  # 'tag': Remember tag and append it to known tags (fmt: t1|t2|...)
	  ($tag eq 'tag') and do {
	    $thisTag = $data;
	    $thisTag =~ s/([\\\|\(\)\[\{\^\$\*\+\?\.])/\\$1/g;
	    if (defined($definition{files}{$thisFile}{knownTags})) {
	      $definition{files}{$thisFile}{knownTags} .= "|$thisTag";
	    } else {
	      $definition{files}{$thisFile}{knownTags} = $thisTag;
	    }
	    last SWITCH;
	  };

	  # 'printable': Indicates whether documents with tag should be printed
	  ($tag eq 'printable') and do {
	    $definition{files}{$thisFile}{tags}{$thisTag}{printable} = $data;
	    last SWITCH;
	  };

	  # 'catalog': Store catalog for this tag
	  ($tag eq 'catalog') and do {
	    $definition{files}{$thisFile}{tags}{$thisTag}{catalog} = $data;
	    last SWITCH;
	  };

	  # 'rankclass': Store rank class for this tag
	  ($tag eq 'rankclass') and do {
	    $definition{files}{$thisFile}{tags}{$thisTag}{rankClass} = $data;
	    last SWITCH;
	  };

	  # 'summaryclass': Store summary class for this tag
	  ($tag eq 'summaryclass') and do {
	    $definition{files}{$thisFile}{tags}{$thisTag}{summaryClass} = $data;
	    last SWITCH;
	  };

	  # 'context': Store context for this tag
	  ($tag eq 'context') and do {
	    $definition{files}{$thisFile}{tags}{$thisTag}{context}{name} =
	      $data;
	    $definition{files}{$thisFile}{tags}{$thisTag}{context}{op} =
	      $operation;
	    last SWITCH;
	  };

	  # 'rField': Store rField for this tag
	  ($tag eq 'rfield') and do {
	    $definition{files}{$thisFile}{tags}{$thisTag}{rField}{name} =
	      $data;
	    $definition{files}{$thisFile}{tags}{$thisTag}{rField}{op} =
	      $operation;
	    last SWITCH;
	  };

	  # 'sField': Store sField for this tag
	  ($tag eq 'sfield') and do {
	    $definition{files}{$thisFile}{tags}{$thisTag}{sField}{name} =
	      $data;
	    $definition{files}{$thisFile}{tags}{$thisTag}{sField}{op} =
	      $operation;
	    last SWITCH;
	  };
	}
      }
    }
  }

  # For each input file, format known tags according to start-tag format
  foreach my $file (keys %{$definition{files}}) {
    my $knownTagsFormatted = $definition{files}{$file}{structure}{start};
    $knownTagsFormatted = s/tag/\($definition{files}{$file}{knownTags}\)/g;
    $definition{files}{$file}{knownTagsFormatted} = $knownTagsFormatted;
  }

  # Close mapping file
  $hMappingFile->close();

  IfVerbose(1, 'Exit:  ReadMappingDefinition()');
  return(\%definition);
}


###############################################################################
# Subroutine: ExpandName
# Parameters: name              - Name to be expanded
#             recordDefinition  - Structure providing delimiter-name mapping
#             delimiter         - Delimiter indicating the record type
# Function:   ExpandName expands catalog, rank class, and summary class names
#             on the form '<variable>' to the value of 'variable' given the
#             current record type.
###############################################################################
sub ExpandName {
  my ($name, $recordDefinition, $delimiter) = @_;

  IfVerbose(1, 'Enter: ExpandName($name)', $name);

  my $variable;

  # Retrieve variable name
  if ($name =~ /<*.>/) {
    my @name = split(/(<|>)/, $name);
    for my $i (0 .. $#name) {
      ($name[$i] eq '<') and do {
	$variable = $name[$i+1];
	last;
      }
    }

    # Currently only handles variable 'recordtype'...
  SWITCH: {

      # Substitute variable 'recordtype' with name of record type
      ($variable eq 'recordtype') and do {
	$name =~ s/<$variable>/$recordDefinition->{names}{$delimiter}/g;
	last SWITCH;
      };
    }
  }

  IfVerbose(1, 'Exit:  ExpandName()', $name);

  return($name);
}


###############################################################################
# Subroutine: GetCatalog
# Parameters: delimiter   - Delimiter identifying the current record type
#             tag         - Tag identifying the data currently being processed
#             fid         - ID of the current input file
#             definition  - Reference to the mapping definition
#             document    - fixmlDocument instance to hold the catalog
# Function:   GetCatalog retrieves the catalog name from the mapping
#             definition, using the 'tag' parameter.  If the name is defined,
#             this means that a context will be created based on 'tag', and the
#             catalog name is expanded (in case it's on the form '<variable>'),
#             whereupon a lookup is performed in 'document' to see if the
#             catalog already exists.  If it does, it is returned; if not, it
#             is created before it's returned.
###############################################################################
sub GetCatalog {
  my ($delimiter, $tag, $fid, $definition, $document) = @_;

  IfVerbose(1, 'Enter: GetCatalog($delimiter, $tag)', $delimiter, $tag);

  my $catalog;
  my $catalogName = $definition->{files}{$fid}{tags}{$tag}{catalog};

  if (defined($catalogName)) {
    $catalogName =
      ExpandName($catalogName, $definition->{recordTypes}{$fid}, $delimiter);
    $catalog = $document->GetOrAddCatalog($catalogName);
  }

  IfVerbose(1, 'Exit:  GetCatalog()', $catalog->{name});

  return($catalog);
}


###############################################################################
# Subroutine: GetRankClass
# Parameters: delimiter   - Delimiter identifying the current record type
#             tag         - Tag identifying the data currently being processed
#             fid         - ID of the current input file
#             definition  - Reference to the mapping definition
#             document    - fixmlDocument instance to hold the rank class
# Function:   GetRankClass retrieves the rank class name from the mapping
#             definition, using the 'tag' parameter.  If the name is defined,
#             this means that an rField will be created based on 'tag', and the
#             rank class name is expanded (in case it's on the form
#             '<variable>'), whereupon a lookup is performed in 'document' to
#             see if the rank class already exists.  If it does, it is
#             returned; if not, it is created before it's returned.
###############################################################################
sub GetRankClass {
  my ($delimiter, $tag, $fid, $definition, $document) = @_;

  IfVerbose(1, 'Enter: GetRankClass($delimiter, $tag)', $delimiter, $tag);

  my $rankClass;
  my $rankClassName = $definition->{files}{$fid}{tags}{$tag}{rankClass};

  if (defined($rankClassName)) {
    $rankClassName =
      ExpandName($rankClassName, $definition->{recordTypes}{$fid}, $delimiter);
    $rankClass = $document->GetOrAddRankClass($rankClassName)
  }

  IfVerbose(1, 'Exit:  GetRankClass()');

  return($rankClass);
}


###############################################################################
# Subroutine: GetSummaryClass
# Parameters: delimiter   - Delimiter identifying the current record type
#             tag         - Tag identifying the data currently being processed
#             fid         - ID of the current input file
#             definition  - Reference to the mapping definition
#             document    - fixmlDocument instance to hold the summary class
# Function:   GetSummaryClass retrieves the summary class name from the mapping
#             definition, using the 'tag' parameter.  If the name is defined,
#             this means that an sField will be created based on 'tag', and the
#             summary class name is expanded (in case it's on the form
#             '<variable>'), whereupon a lookup is performed in 'document' to
#             see if the summary class already exists.  If it does, it is
#             returned; if not, it is created before it's returned.
###############################################################################
sub GetSummaryClass {
  my ($delimiter, $tag, $fid, $definition, $document) = @_;

  IfVerbose(1, 'Enter: GetSummaryClass($delimiter, $tag)', $delimiter, $tag);

  my $summaryClass;
  my $summaryClassName = $definition->{files}{$fid}{tags}{$tag}{summaryClass};

  if (defined($summaryClassName)) {
    $summaryClassName =
      ExpandName($summaryClassName, $definition->{recordTypes}{$fid},
		 $delimiter);
    $summaryClass = $document->GetOrAddSummaryClass($summaryClassName);
  }

  IfVerbose(1, 'Exit:  GetSummaryClass()');

  return($summaryClass);
}


###############################################################################
# Subroutine: MassageData
# Paramaters: data      - Data string
#             operation - Operation to be performed on the data string
# Function:   MassageData performs the operation indicated by $operation on
#             the data string.  Currently (05/08/00) only substr() is
#             supported.
###############################################################################
sub MassageData {
  IfVerbose(1, 'Enter: MassageData()');

  my ($data, $operation) = @_;

  if (defined($operation)) {
  SWITCH: {
      ($operation =~ /^substr/) and do {
	my ($ignore, $offsets) = split(/\(|\)/, $operation);
	my ($start, $count) = split(/-/, $offsets);
	$data = defined($count) ?
	  substr($data, $start, $count) : substr($data, $start);
	last SWITCH;
      };
    }
  }

  IfVerbose(1, 'Exit: MassageData()');

  return($data);
}


###############################################################################
# Subroutine: ProcessLine
# Parameters: line        - The input line currently being processed
#             fid         - ID of the current input file
#             definition  - Reference to the mapping definition
#             document    - fixmlDocument instance being created
#             state       - Reference to processing state
#             data        - Reference to data being extracted from input lines
#             delimiter   - Delimiter identifying the current record type
#             tag         - Reference to tag identifying the data
# Function:   ProcessLine operates a state machine that, based on the data
#             structure obtained in GetDataStructure, iterates through the
#             given input line, determining which contexts, rank classes, and
#             summary classes the data should go in, based on the tag
#             delimiting the data, and of course on the mapping definition.
#             If the data for a given tag is spread across more than one line,
#             the 'state', 'data', and 'tag' are preserved across calss to
#             ProcessLine.
###############################################################################
sub ProcessLine {
  my ($line, $fid, $definition,
      $document, $state, $data, $delimiter, $tag) = @_;

  IfVerbose(1, 'Enter: ProcessLine($line, $state)', $line, $$state);

  my $catalog;
  my $rankClass;
  my $summaryClass;

  # Remove control characters (might confuse indexer)
  $line =~ s/[ 
]+//g;

  # Create array of all known tags for this file
  my @knownTags = split(/\|/, $definition->{files}{$fid}{knownTags});

  # Iterate while current line is not empty (and should not be skipped)
  while (($line ne '') and ($$state != $_skip)) {
    IfVerbose(2, 'Line processing status ($line, $state)', $line, $$state);

  SWITCH: {

      # Start: Find which tag is matching and cut off tag from line
      ($$state == $_start) and do {
	my $lineStart = $definition->{files}{$fid}{structure}{start};
	foreach my $knownTag (@knownTags) {
	  (my $thisStart = $lineStart) =~ s/tag/$knownTag/g;
	  if ($line =~ /^\s*$thisStart/) {
	    $$tag = $knownTag;
	    $line =~ m/$thisStart/g;
	    $line = substr($line, pos($line));
	    last;
	  }
	}

	# Set next state to 'skip' if tag is unknown
	$$state = defined($$tag) ? $_filler : $_skip;
	last SWITCH;
      };

      # Filler: Skip filler if expected (currently only handles is whitespace)
      ($$state == $_filler) and do {
	my $filler = $definition->{files}{$fid}{structure}{filler};
	if (defined($filler)) {
	  ($filler eq 'WS') and $line =~ s/^\s+(\S*)/$1/g;
	}
	$$state = $_data;
	last SWITCH;
      };

      # Data: Identify end delimiter for data and read until delimiter found
      ($$state == $_data) and do {
	my $dataEnd = $definition->{files}{$fid}{structure}{end};
	($dataEnd =~ /tag/) and $dataEnd =~ s/tag/$$tag/g;
	($dataEnd eq 'EOL') and $dataEnd = "\n";

	if ($line =~ m/$dataEnd/gi) {
	  # End delimiter found on this line, cut off delimiter and reset state
	  my $lineEnd = substr($line, 0, length($`));
	  chomp($$data .= $lineEnd);
	  $$state = $_start;
	} else {
	  # End delimiter not found on this line, keep state
	  chomp($$data .= $line);
	}

	$line = '';
	last SWITCH;
      };
    }
  }

  # State = 'start' means ready to start new tag means done with this tag
  if ($$state == $_start) {

    # Create or retrieve catalog and rank and summary classes (if any) for tag
    $catalog = GetCatalog($delimiter, $$tag, $fid, $definition, $document);
    $rankClass = GetRankClass($delimiter, $$tag, $fid, $definition, $document);
    $summaryClass = GetSummaryClass($delimiter, $$tag, $fid, $definition,
				    $document);

    # Set flag that indicates whether document should be printed or not
    if (defined($definition->{files}{$fid}{tags}{$$tag}{printable})) {
      my $printable = $definition->{files}{$fid}{tags}{$$tag}{printable};
      $document->SetPrintable($printable);
    }

    # Add data as context to catalog if catalog and context defined
    if (defined($catalog) and
	defined($definition->{files}{$fid}{tags}{$$tag}{context})) {

      # Potentially "massage" a copy of the data, not the "original"
      my $data = $$data;

      # "Massage" the data if an operation is defined
      defined($definition->{files}{$fid}{tags}{$$tag}{context}{op}) and
	$data =
	  MassageData($data,
		      $definition->{files}{$fid}{tags}{$$tag}{context}{op});

      IfVerbose(2, 'Adding context',
		$definition->{files}{$fid}{tags}{$$tag}{context}{name},
		$data);

      # Add the context
      $catalog->AddContext(
          $definition->{files}{$fid}{tags}{$$tag}{context}{name}, $data);
    }

    # Add data as rField to rank class if rank class and rField defined
    if (defined($rankClass) and
	defined($definition->{files}{$fid}{tags}{$$tag}{rField})) {

      # Potentially "massage" a copy of the data, not the "original"
      my $data = $$data;

      # "Massage" the data if an operation is defined
      defined($definition->{files}{$fid}{tags}{$$tag}{rField}{op}) and
	$data =
	  MassageData($data,
		      $definition->{files}{$fid}{tags}{$$tag}{rField}{op});

      IfVerbose(2, 'Adding rField',
		$definition->{files}{$fid}{tags}{$$tag}{rField}{name}, $data);

      # Add the rField
      $rankClass->Add_rField(
          $definition->{files}{$fid}{tags}{$$tag}{rField}{name}, $data);
    }

    # Add data as sField to summary class if summary class and sField defined
    if (defined($summaryClass) and
	defined($definition->{files}{$fid}{tags}{$$tag}{sField})) {

      # Potentially "massage" a copy of the data, not the "original"
      my $data = $$data;

      # "Massage" the data if an operation is defined
      defined($definition->{files}{$fid}{tags}{$$tag}{sField}{op}) and
	$data =
	  MassageData($data,
		      $definition->{files}{$fid}{tags}{$$tag}{sField}{op});

      IfVerbose(2, 'Adding sField',
		$definition->{files}{$fid}{tags}{$$tag}{sField}{name}, $data);

      # Add the sField
      $summaryClass->Add_sField(
          $definition->{files}{$fid}{tags}{$$tag}{sField}{name}, $data);
    }

    undef($$tag);
    $$data = '';
  }

  # State = 'skip' means ready to start new tag means state should be 'start'
  ($$state == $_skip) and $$state = $_start;

  IfVerbose(1, 'Exit:  ProcessLine()');
}


###############################################################################
# Subroutine: GetDocument
# Parameters: definition - Reference to the mapping definition structure
#             line       - Reference to the current input line
# Function:   GetDocument iterates through an input record (which may be
#             spread across two or more input files) and calls ProcessLine for
#             all lines that are tagged with a 'known tag'.  Known tags are
#             tags specified in the mapping file.
###############################################################################
sub GetDocument {
  IfVerbose(1, 'Enter: GetDocument()');

  my ($definition, $line) = @_;
  my $state = $_start;
  my $data = '';
  my $tag;
  my $delimiter;
  my $document = fixmlDocument->New($CDATA);
  my $moreData = 0;

  # Process input files individually (assuming records occur in same order)
  foreach my $file (keys %{$definition->{files}}) {

    # Get handle for this input file
    my $handle = $definition->{files}{$file}{handle};

    # Skip until record delimiter is found or end of file
    while (($line->{$file}) and
	   (($line->{$file} eq 'NULL') or
	    ($line->{$file} !~
	     /^\s*($definition->{files}{$file}{delimiters})/))) {
      $line->{$file} = <$handle>;
      IfVerbose(3, 'Current input line', $line->{$file});
    }

    # Continue if not end of file
    if (($line->{$file}) and
	($line->{$file} =~ /^\s*($definition->{files}{$file}{delimiters})/)) {

      # Set flag that indicates that data was found so $document is returned
      $moreData = 1;

      # Find out which of all defined delimiters identifies this record
      my @delimiters = split(/\|/, $definition->{files}{$file}{delimiters});
      foreach my $delim (@delimiters) {
	if ($line->{$file} =~ /^\s*$delim/) {
	  $delimiter = $delim;
	  last;
	}
      }

      # Process the current input line and read the next
      ProcessLine($line->{$file}, $file, $definition,
		  $document, \$state, \$data, $delimiter, \$tag);
      $line->{$file} = <$handle>;
      IfVerbose(3, 'Current input line', $line->{$file});

      # Iterate while current input line is not delimiter line
      while ((defined($line->{$file})) and 
	     (($line->{$file} !~
	       /^\s*($definition->{files}{$file}{delimiters})/))) {

	# Process line if known tag or non-tag and state != start
	if (($line->{$file} =~
	     /^\s*$definition->{files}{$file}{knownTagsFormatted}/) or
	    ($state != $_start)) {
	  ProcessLine($line->{$file}, $file, $definition,
		      $document, \$state, \$data, $delimiter, \$tag);
	}

	# Read next input line
	$line->{$file} = <$handle>;
	IfVerbose(3, 'Current input line', $line->{$file});
      }
    }
  }

  IfVerbose(1, 'Exit:  GetDocument()');

  # Return document generated if data was found, undef if not
  return($moreData ? $document : undef);
}


###############################################################################
# Subroutine: Main
# Paramaters: <none>
# Function:   Main body of the script (emulating C-style main()).
###############################################################################
sub Main {
  IfVerbose(1, 'Enter: Main()', @_);

  my %line;
  my $document;
  my $collection = fixmlDocumentCollection->New();

  GetOptions();

  my $definition = ReadMappingDefinition();

  # Initialize input lines for all input files
  foreach my $file (keys %{$definition->{files}}) {
    $line{$file} = 'NULL';
  }

  # Add documents to collection (i.e., write to STDOUT) as long as more input
  while (defined($document = GetDocument($definition, \%line))) {
    $collection->AddDocument($document);
  }

  # Terminate the FIXML collection (i.e., write close tag)
  $collection->Close();

  # Close all input files
  foreach my $file (keys %{$definition->{files}}) {
    $definition->{files}{$file}{handle}->close();
  }

  IfVerbose(1, 'Exit:  Main()');
}


Main();
