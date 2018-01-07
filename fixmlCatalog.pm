package fixmlCatalog;

@ISA = qw(SGMLTags);

use strict;
use fixmlContext;


sub New {
  my $class = shift();
  my $self = {};
  ($self->{name}, $self->{CDATA}) = @_;
  @{$self->{contexts}} = ();
  return bless($self, $class);
}


sub AddContext {
  my ($self, $name, $value) = @_;
  push(@{$self->{contexts}}, fixmlContext->New($name, $value));
}


sub Name {
  my ($self) = @_;
  return($self->{name});
}


sub Print {
  my ($self, $indent) = @_;
  $self->OpenTagWithAttributes(tag => "catalog", indent => $indent,
			       attributes => ({name => "name",
					       value => $self->{name}}));
  $self->NewLine();
  foreach my $context (@{$self->{contexts}}) {
    $context->Print(indent => $indent+2,
		    CDATA => defined($self->{CDATA}) ? 'CDATA' : undef);
  }
  $self->CloseTag("catalog", $indent);
  $self->NewLine();
}


1;
