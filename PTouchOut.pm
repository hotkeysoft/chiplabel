package PTouchOut;
use strict;
use warnings;
use fields  qw/width output margin force minquality scale datamatrix/;
use PTouch;
use GdUtil qw/:all/;
use Carp;
use List::Util qw/max/;
use v5.10;

my PTouchOut $gself;

my %default_values = (
    output => "label.png",
    margin => 2,
    minquality => 'L',
);

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;
    %$self = %default_values;
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
    "w=n" => \$self->{width},  # width of tape
    "o=s" => \$self->{output},
    "force" => \$self->{force},
    );
}

sub opts_code {
    my ($self) = self(@_);
    return (
    "M=n" => \$self->{margin},
    "s=f" => \$self->{scale},
    "q=s" => \$self->{minquality},
    );
}

sub pixels {
    my ($self) = self(@_);
    return PTouch::pixels($self->{width});
}

sub output {
    my ($self,$canvas) = self(@_);
    my ($w,$h) = $canvas->getBounds();
    croak "Final output is too big for tape width: $h > $self->pixels" if $h > $self->pixels;
    writepng(crop_centered($canvas, undef, $self->pixels), $self->{output});
}

sub code {
    my ($self,$text) = self(@_);
    my $code = $self->{datamatrix} ? createcode_dm($text) : createcode_qr($text, quality => $self->{minquality});
    my ($cbw,$cbh) = $code->getBounds();
    $code = crop_centered($code,$cbw + 2*max(4,$self->{margin}) - 8, $cbh + 2*$self->{margin} - 8);
    printf "modified QRBounds (%i,%i) -> (%i,%i)\n", $cbw, $cbh, $code->getBounds();

    my ($cw,$ch) = $code->getBounds();
    my $scale = $self->{scale};
    if (!defined $scale) {
        my $factor = $self->pixels / $ch;
        $scale = $factor < 3.5 ? int($factor) : $factor;
        printf "Scale factor: %.4f -> %.4f\n",$factor, $scale;
        die "computed scale is too small to create readable code." if $scale < 2 && !$self->{force};
    }
    return stretch($code,$scale);
}

1;
