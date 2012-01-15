package PTouch;
use Exporter 'import';
@EXPORT_OK = qw/pixels/;
use strict;
use warnings;


# This maps the tape width from mm to pixels
# Note that we use a 2 pixel (one in each side) margin,
# the Brother driver uses a much wider margin.
my %WIDTH = (
#     6=>42-2,
     6=>42,
     9=>64-2,
     12=>84-2,
     18=>128-2,
     24=>128,
     );

sub pixels {
    return $WIDTH{$_[0]};
}


