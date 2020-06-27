package PTouchOut;
use strict;
use warnings;
use v5.10;
use fields  qw/width output margin scale/;

use PTouch qw/PIX_PER_MM/;
use GdUtil qw/:all/;
use Carp;
use List::Util qw/max/;

my PTouchOut $gself;

my %default_values = (
    output => "label.png",
);

sub defaults {
    %default_values = (%default_values, @_);
}

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;
    %$self = (%default_values,@_);
    hspace(1)->useFontConfig(1);
    return $self;
}

sub self {
    my $self = shift;
    return ($self,@_) if ref $self && $self->isa("PTouchOut");
    $gself = PTouchOut->new() if !defined $gself;
    return ($gself,@_);
}

sub opts {
    my ($self) = self(@_);
    return (
    "w=f" => \$self->{width},  # width of tape
    "o=s" => \$self->{output},
    );
}

sub pixels {
    my ($self) = self(@_);
    return PTouch::pixels($self->{width});
}

sub mmtopix {
    my ($self,$mm) = self(@_);
    return PIX_PER_MM*$mm if defined $mm;
}

sub output {
    my ($self,$canvas,$fn) = self(@_);
    my ($w,$h) = $canvas->getBounds();
    croak "Final output is too big for tape width: $h > $self->pixels" if $h > $self->pixels;
    writepng($canvas, $fn // $self->{output});
}

1;
