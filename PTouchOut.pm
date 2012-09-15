package PTouchOut;
use strict;
use warnings;
use fields  qw/width output margin force/;
use PTouch;
use v5.10;

my PTouchOut $gself;

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
    "o=s" => \$self->{output}
    );
}

sub pixels {
    my ($self) = self(@_);
    return PTouch::pixels($self->{width});
}

sub output {
    my ($self,$canvas) = self(@_);
    use GdUtil;
    GdUtil::writepng($canvas, $self->{output});
}

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;
    $self->{output} = "label.png";
    return $self;
}

1;
