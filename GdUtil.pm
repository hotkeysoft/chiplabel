package GdUtil;
use Exporter 'import';
@EXPORT_OK = qw/crop_centered drawtext createcode_qr createcode_dm writepng hcat vcat stretch/;
use strict;
use warnings;

use GD;
use GD::Barcode::QRcode;
use GD::Barcode::DataMatrix;
use List::Util qw/sum max min/;

my $font = "Ariel";
my $fsize = 18;

sub crop_centered ($@) {
    my ($img,$nw,$nh) = @_;
    my ($ow,$oh) = $img->getBounds();
    $nw = $ow unless defined $nw;
    $nh = $oh unless defined $nh;
    my $cw = int(($nw - $ow) / 2);
    my $ch = int(($nh - $oh) / 2);
    my $nimg = GD::Image->new($nw,$nh);
    $nimg->colorAllocate(255,255,255);
    $nimg->copy($img,max(0,$cw),max(0,$ch),-min(0,$cw),-min(0,$ch),$nw,$nh);
    return $nimg;
}

sub stretch ($@) {
    my ($img,$nw,$nh) = @_;
    my ($ow,$oh) = $img->getBounds();
    $nw = $ow unless defined $nw;
    $nh = $oh unless defined $nh;
    my $nimg = GD::Image->new($nw,$nh);
    $nimg->copyResize($img,0,0,0,0,$nw,$nh,$ow,$oh);
    return $nimg;
}

sub drawtext ($) {
    my ($text) = @_;
    my @tb = GD::Image->stringFT(0, $font, $fsize, 0, 0, 0, $text);
    my ($tw,$th) = ($tb[2] - $tb[6], $tb[3] - $tb[7]);
    print "Text($tw,$th) ", join " ", @tb ," \n";
    my $img = GD::Image->new($tw,$th);
    my $bg = $img->colorAllocate(255,255,255);
    my $fg = $img->colorAllocate(0,0,0);
    $img->stringFT(-$fg, $font, $fsize, 0, -$tb[6], -$tb[7], $text);
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
    my ($text) = @_;
    my $code = GD::Barcode::DataMatrix->new($text);
    return $code->plot();
}

sub vcat  {
    #my $opt = ref $_[0] eq 'HASH' ? shift : {};
    my @is = @_;
    return GD::Image->new(0,0) unless @_;
    return $_[0] if @_ == 1;
    my ($w,$h);
    my $mw = max(map { ($w,$h) = $_->getBounds(); $w; } @is);
    my $th = sum(map { ($w,$h) = $_->getBounds(); $h; } @is);

    my $img = GD::Image->new($mw,$th);
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
    return GD::Image->new(0,0) unless @_;
    return $_[0] if @_ == 1;
    my ($w,$h);
    my $tw = sum(map { ($w,$h) = $_->getBounds(); $w; } @is);
    my $mh = max(map { ($w,$h) = $_->getBounds(); $h; } @is);

    my $img = GD::Image->new($tw,$mh);
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
