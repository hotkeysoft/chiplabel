package GdUtil;
use Exporter 'import';
@EXPORT_OK = qw/crop_centered drawtext writepng stretch hspace vspace new_image/;
%EXPORT_TAGS = ( all => \@EXPORT_OK );
use strict;
use warnings;

use GD;
use List::Util qw/sum max min/;

# create an image with the proper foreground and background colors set
sub new_image {
    my ($w,$h) = @_;
    my $img = GD::Image->new($w,$h);
    my $bg = $img->colorAllocate(255,255,255);
    $img->transparent($bg);
    my $fg = $img->colorAllocate(0,0,0);
    return wantarray ? ($img,$fg,$bg) : $img;
}

sub crop_centered ($@) {
    my ($img,$nw,$nh) = @_;
    my ($ow,$oh) = $img->getBounds();
    $nw = $ow unless defined $nw;
    $nh = $oh unless defined $nh;
    my $cw = int(($nw - $ow) / 2);
    my $ch = int(($nh - $oh) / 2);
    my $nimg = new_image($nw,$nh);
    $nimg->copy($img,max(0,$cw),max(0,$ch),-min(0,$cw),-min(0,$ch),$nw,$nh);
    return $nimg;
}
sub rectangle ($@) {
    my ($img,$x,$y,$w,$h,$fg) = @_;
    return if $w <= 0 || $h <= 0;
    $img->filledRectangle($x,$y,$x+$w - 1, $y + $h - 1, $fg);
    return $img;
}

sub stretch ($@) {
    my $img = shift;
    my ($ow,$oh) = $img->getBounds();
    my ($nw,$nh) = @_ == 2 ? @_ : ($_[0]*$ow,$_[0]*$oh);
    $nw = $ow unless defined $nw;
    $nh = $oh unless defined $nh;
    my $nimg = new_image($nw,$nh);
    $nimg->copyResized($img,0,0,0,0,$nw,$nh,$ow,$oh);
    return $nimg;
}

sub drawtext ($%) {
    my ($text,%o) = @_;
    my $font = $o{font} || GD::Font->Small;
    $o{angle} ||= 0;
    $o{overbar} ||= 0;
    my $ooff = $o{overbar} ? 2 : 0;
    my ($tw,$th) = ($font->width * length $text, $font->height + $ooff);
#    print "Text2($text,$tw,$th)\n";
    my $img = GD::Image->new($tw,$th);
    my $bg = $img->colorAllocate(255,255,255);
    $img->transparent($bg);
    my $fg = $img->colorAllocate(0,0,0);
    $img->string($font, 0,$ooff, $text, $fg);
    $img->line(0,0,$tw,0,$fg) if $o{overbar};
    return $img;
}

sub writepng ($$) {
    open my $fh, ">", $_[1] or die "$!: $_[1]";
    binmode $fh;
    print $fh $_[0]->png;
    close $fh;
}

sub hspace ($) {
    return scalar new_image($_[0],1);
}

sub vspace ($) {
    return scalar new_image(1, $_[0]);
}
