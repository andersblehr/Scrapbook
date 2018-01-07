package SGMLTags;

use strict;


sub _print {
  my $self = shift();
  my %params = @_;

  defined($params{indent}) and print(' ' x $params{indent});
  defined($params{CDATA}) and print('<![CDATA[');
  print($params{data});
  defined($params{CDATA}) and print(']]>');
}


sub _printTagWithAttributes {
  my $self = shift();
  my %params = @_;
  my $tag = $params{tag};
  my $indent = $params{indent};
  my @attributes = $params{attributes};

  $self->_print(data => "<$tag", indent => $indent);
  for (my $i=0; $i<=$#attributes; $i++) {
    $self->_print(data => " $attributes[$i]{name}=\"$attributes[$i]{value}\"");
  }
}


sub PrintTag {
  my ($self, $tag, $indent) = @_;

  $self->_print(data => "<$tag>", indent => $indent);
}


sub OpenTag {
  my ($self, $tag, $indent) = @_;

  $self->PrintTag($tag, $indent);
}


sub OpenTagWithAttributes {
  my $self = shift();

  $self->_printTagWithAttributes(@_);
  $self->_print(data => ">");
}


sub CloseTag {
  my ($self, $tag, $indent) = @_;

  $self->_print(data => "</$tag>", indent => $indent);
}


sub OpenCloseTagWithAttributes {
  my $self = shift();

  $self->_printTagWithAttributes(@_);
  $self->_print(data => "/>");
}


sub DumpData {
  my ($self, $data, $CDATA) = @_;

  $self->_print(data => $data, CDATA => $CDATA);
}


sub NewLine {
  print("\n");
}


sub New {
  my $class = shift;
  my $self = {};

  return bless($self, $class);
}


1;
