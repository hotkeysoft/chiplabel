package PTouch;
use Exporter 'import';
@EXPORT_OK = qw/pixels PIX_PER_MM/;
use strict;
use warnings;

# This maps the tape width from mm to pixels
# Note that we use a 2 pixel (one in each side) margin,
# the Brother driver uses a much wider margin.
my %WIDTH = (
     3.5=>24-2,
     6=>42-2,
     9=>64-2,
     12=>84-2,
     18=>128-2,
     24=>128,
     );

use constant PIX_PER_MM => 7.0;

sub pixels {
    return undef unless defined $_[0];
    return $WIDTH{$_[0]} or die "Invalid width specified: $_[0]mm";
}

