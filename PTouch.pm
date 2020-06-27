package PTouch;
use Exporter 'import';
@EXPORT_OK = qw/pixels PIX_PER_MM VPIX_PER_MM/;
use strict;
use warnings;

#horizontal pixels per MM
#multiple of 96 DPI (DPI set in .png file)
use constant PIX_PER_MM => (96.0 * 2.0)/25.4;

#vertical pixels per MM
use constant VPIX_PER_MM => (96.0 * 2.0)/25.4;

sub pixels {
    return undef unless defined $_[0];
    return VPIX_PER_MM*($_[0] + 0.0) - 2;
}
