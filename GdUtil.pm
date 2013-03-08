package GdUtil;
use Exporter 'import';
@EXPORT_OK = qw/crop_centered drawtext createcode_qr createcode_dm writepng hcat vcat stretch hspace vspace drawtext2/;
%EXPORT_TAGS = ( all => \@EXPORT_OK );
use strict;
use warnings;

use GD;
use GD::Barcode::QRcode;
#use GD::Barcode::DataMatrix;
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
    $o{font} ||= "Ariel";
    $o{size} ||= 18;
    $o{angle} ||= 0;
    my @tb = GD::Image->stringFT(0, $o{font}, $o{size}, $o{angle}, 0, 0, $text);
    my ($tw,$th) = ($tb[2] - $tb[6], $tb[3] - $tb[7]);
    #print "Text($tw,$th) ", join " ", @tb ," \n";
    my ($img,$fg) = new_image($tw,$th);
    $img->stringFT(-$fg, $o{font}, $o{size}, $o{angle}, -$tb[6], -$tb[7], $text);
    return $img;
}

sub drawtext2 ($%) {
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

sub createcode_qr ($%) {
    my ($text, %opt) = @_;
    $opt{quality} ||= 'L';
    foreach my $v (1 .. 40) {
        my $code = eval { GD::Barcode::QRcode->new($text, { Ecc => $opt{quality}, Version => $v }) };
        if (defined $code) {
            print "QR Version: $v\n";
            foreach my $q ('H', 'Q', 'M', 'L') {
                $code = eval { GD::Barcode::QRcode->new($text, { Ecc => $q, Version => $v }) };
                if (defined $code) {
                    print "QR Quality: $q\n";
                    return $code->plot();
                }
            }
        }
    }
}

sub createcode_dm ($) {
#    my ($text) = @_;
#    my $code = GD::Barcode::DataMatrix->new($text);
#    return $code->plot();
}

sub vcat  {
    #my $opt = ref $_[0] eq 'HASH' ? shift : {};
    my @is = @_;
    return GD::Image->new(0,0) unless @_;
    return $_[0] if @_ == 1;
    my ($w,$h);
    my $mw = max(map { ($w,$h) = $_->getBounds(); $w; } @is);
    my $th = sum(map { ($w,$h) = $_->getBounds(); $h; } @is);

    my $img = new_image($mw,$th);
    my $cy = 0;
    while (@is) {
        my $c = shift(@is);
        my ($w,$h) = $c->getBounds;
        $img->copy($c,($mw - $w) / 2,$cy,0,0,$w,$h);
        $cy += $h;
    }
    return $img;
}

sub hcat  {
    #my $opt = ref $_[0] eq 'HASH' ? shift : {};
    my @is = @_;
    return new_image(0,0) unless @_;
    return $_[0] if @_ == 1;
    my ($w,$h);
    my $tw = sum(map { ($w,$h) = $_->getBounds(); $w; } @is);
    my $mh = max(map { ($w,$h) = $_->getBounds(); $h; } @is);

    my $img = new_image($tw,$mh);
    my $cx = 0;
    while (@is) {
        my $c = shift(@is);
        my ($w,$h) = $c->getBounds;
        $img->copy($c, $cx, ($mh - $h) / 2,0,0,$w,$h);
        $cx += $w;
    }
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
