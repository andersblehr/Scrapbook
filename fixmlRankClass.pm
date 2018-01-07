package fixmlRankClass;

@ISA = qw(SGMLTags);

use strict;
use fixml_rField;


sub New {
  my $class = shift();
  my $self = {};
  ($self->{name}) = @_;
  @{$self->{rFields}} = ();
  return bless($self, $class);
}


sub Add_rField {
  my ($self, $name, $value) = @_;
  push(@{$self->{rFields}}, fixml_rField->New($name, $value));
}


sub Name {
  my ($self) = @_;
  return($self->{name});
}


sub Print {
  my ($self, $indent) = @_;
  $self->OpenTagWithAttributes(tag => "rank", indent => $indent,
			       attributes => ({name => "class",
					       value => $self->{name}}));
  $self->NewLine();
  foreach my $rField (@{$self->{rFields}}) {
    $rField->Print(indent => $indent+2);
  }
  $self->CloseTag("rank", $indent);
  $self->NewLine();
}


1;
