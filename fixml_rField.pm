package fixml_rField;

@ISA = qw(SGMLTags);

use strict;


sub New {
  my $class = shift();
  my $self = {};
  ($self->{name}, $self->{value}) = @_;
  return bless($self, $class);
}


sub Print {
  my $self = shift();
  my %params = @_;
  if ($self->{value} !~ /^\s*$/) {
    $self->OpenTagWithAttributes(tag => "rField", indent => $params{indent},
				 attributes => ({name => "name",
						 value => $self->{name}}));
    $self->DumpData($self->{value});
    $self->CloseTag("rField");
    $self->NewLine();
  }
}


1;
