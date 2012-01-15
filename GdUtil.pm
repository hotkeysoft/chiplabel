package GdUtil;
use Exporter 'import';
@EXPORT_OK = qw/crop drawtext createcode_qr createcode_dm/;
use strict;
use warnings;

use GD;
use GD::Barcode::QRcode;
use GD::Barcode::DataMatrix;

my $font = "Ariel";
my $fsize = 8;
my $minquality = 'L';

sub crop ($@) {
    my ($img,$x,$y,$nw,$nh) = @_;
    my $nimg = GD::Image->new($nw,$nh);
    $nimg->colorAllocate(255,255,255);
    $nimg->copy($img,0,0,$x,$y,$nw,$nh);
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

sub createcode_qr {
    my ($text) = @_;
    foreach my $v (1 .. 40) {
        my $code = eval { GD::Barcode::QRcode->new($text, { Ecc => $minquality, Version => $v }) };
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

sub createcode_dm{
    my ($text) = @_;
    my $code = GD::Barcode::DataMatrix->new($text);
    return $code->plot();
}
