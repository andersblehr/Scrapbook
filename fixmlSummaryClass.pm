package fixmlSummaryClass;

@ISA = qw(SGMLTags);

use strict;
use fixml_sField;


sub New {
  my $class = shift();
  my $self = {};
  ($self->{name}, $self->{CDATA}) = @_;
  @{$self->{sFields}} = ();
  return bless($self, $class);
}


sub Add_sField {
  my ($self, $name, $value) = @_;
  push(@{$self->{sFields}}, fixml_sField->New($name, $value));
}


sub Name {
  my ($self) = @_;
  return($self->{name});
}


sub Print {
  my ($self, $indent) = @_;
  $self->OpenTagWithAttributes(tag => "summary", indent => $indent,
			       attributes => ({name => "class",
					       value => $self->{name}}));
  $self->NewLine();
  foreach my $sField (@{$self->{sFields}}) {
    $sField->Print(indent => $indent+2,
		   CDATA => defined($self->{CDATA}) ? 'CDATA' : undef);
  }
  $self->CloseTag("summary", $indent);
  $self->NewLine();
}


1;
