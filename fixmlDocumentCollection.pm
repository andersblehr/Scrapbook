package fixmlDocumentCollection;

@ISA = qw(SGMLTags);

use strict;
use FileHandle;
use fixmlDocument;
use SGMLTags;

my $c_XMLVersion = '?xml version="1.0" encoding="UTF-8" ?';
my $c_XMLDocType = '!DOCTYPE fixmlDocumentCollection SYSTEM "fixml1_0.dtd"';


sub New {
  my $class = shift();
  my $self = {};
  bless($self, $class);

  $self->PrintTag($c_XMLVersion);
  $self->NewLine();
  $self->PrintTag($c_XMLDocType);
  $self->NewLine();
  $self->OpenTag("fixmlDocumentCollection");
  $self->NewLine();

  return $self;
}


sub AddDocument {
  my ($self, $document) = @_;
  $document->Print(indent => 2);
}


sub Close {
  my $self = shift();
  $self->CloseTag("fixmlDocumentCollection");
  $self->NewLine();
}
