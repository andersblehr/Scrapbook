package fixmlContext;

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
    $self->OpenTagWithAttributes(tag => "context", indent => $params{indent},
				 attributes => ({name => "name",
						 value => $self->{name}}));
    $self->DumpData($self->{value}, $params{CDATA});
    $self->CloseTag("context");
    $self->NewLine();
  }
}


1;
