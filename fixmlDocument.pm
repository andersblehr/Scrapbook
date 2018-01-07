package fixmlDocument;

@ISA = qw(SGMLTags);

use strict;
use fixmlCatalog;
use fixmlRankClass;
use fixmlSummaryClass;


sub New {
  my ($class, $CDATA) = @_;
  my $self = {};
  $self->{CDATA} = defined($CDATA) ? $CDATA : undef;
  $self->{printable} = 1;
  @{$self->{catalogs}} = ();
  @{$self->{rankClasses}} = ();
  @{$self->{summaryClasses}} = ();
  return bless($self, $class);
}


sub SetPrintable {
  my ($self, $printable) = @_;
  $self->{printable} = $printable;
}


sub AddCatalog {
  my ($self, $catalog) = @_;
  push(@{$self->{catalogs}}, $catalog);
}


sub GetOrAddCatalog {
  my ($self, $name) = @_;
  my $catalog;
  my $catalogExists = 0;

  for my $i (0 .. $#{$self->{catalogs}}) {
    if ($self->{catalogs}[$i]{name} eq $name) {
      $catalogExists = 1;
      $catalog = $self->{catalogs}[$i];
      last;
    }
  }
  
  if (not $catalogExists) {
    $self->AddCatalog($catalog = fixmlCatalog->New($name, $self->{CDATA}));
  }

  return($catalog);
}


sub GetOrAddRankClass {
  my ($self, $name) = @_;
  my $rankClass;
  my $rankClassExists = 0;

  for my $i (0 .. $#{$self->{rankClasses}}) {
    if ($self->{rankClasses}[$i]{name} eq $name) {
      $rankClassExists = 1;
      $rankClass = $self->{rankClasses}[$i];
      last;
    }
  }
  
  if (not $rankClassExists) {
    $self->AddRankClass($rankClass = fixmlRankClass->New($name));
  }

  return($rankClass);
}


sub GetOrAddSummaryClass {
  my ($self, $name) = @_;
  my $summaryClass;
  my $summaryClassExists = 0;

  for my $i (0 .. $#{$self->{summaryClasses}}) {
    if ($self->{summaryClasses}[$i]{name} eq $name) {
      $summaryClassExists = 1;
      $summaryClass = $self->{summaryClasses}[$i];
      last;
    }
  }
  
  if (not $summaryClassExists) {
    $self->AddSummaryClass($summaryClass =
			   fixmlSummaryClass->New($name, $self->{CDATA}));
  }

  return($summaryClass);
}


sub AddRankClass {
  my ($self, $rankClass) = @_;
  push(@{$self->{rankClasses}}, $rankClass);
}


sub AddSummaryClass {
  my ($self, $summaryClass) = @_;
  push(@{$self->{summaryClasses}}, $summaryClass);
}


sub Print {
  my ($self, $indent) = shift();

  if ($self->{printable}) {
    my %params = @_;
    my $indent = $params{indent};
    
    $self->OpenTag("document", $indent);
    $self->NewLine();
    foreach my $catalog (@{$self->{catalogs}}) {
      $catalog->Print($indent+2);
    }
    foreach my $rankClass (@{$self->{rankClasses}}) {
      $rankClass->Print($indent+2);
    }
    foreach my $summaryClass (@{$self->{summaryClasses}}) {
      $summaryClass->Print($indent+2);
    }
    $self->CloseTag("document", $indent);
    $self->NewLine();
  }
}


1;
