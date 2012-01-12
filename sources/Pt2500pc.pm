#-*-perl-*- $Id: Pt2500pc.pm 2085 2003-01-23 20:34:56Z ff $
package Pt2500pc;
use strict;
use Device::SerialPort;
use Device::USB;
use Time::HiRes qw( usleep );

# Maps media number to name
my %MEDIA =
    (
     0=>'Tape cassette is not installed',
     1=>'Laminated tape',
     2=>'Lettering tape',
     3=>'Non-laminated tape',
     );

# Why did we receive the status message?
my %STATUSKIND =
    (
     0=>'Reply to status request',
     1=>'Printing completion',
     2=>'Error',
     3=>'Power off',
     4=>'Notice',
     5=>'Phase change',
     );

# Notice number to text mapping
my %NOTICE =
    (
     0=>'Invalid',
     1=>'Cover is open',
     2=>'Cover is closed',
     );

# Error bit fields -> text descriptions:
my %ERROR1 =
    (
     0x01 => 'Tape cassette not installed',
     0x02 => 'The cassette has run out of tape',
     0x04 => 'Cutter jam',
     0x08 => 'Not defined 1.08',
     0x10 => 'Not defined 1.10',
     0x20 => 'Power off',
     0x40 => 'Not defined 1.40',
     0x80 => 'Not defined 1.80',
     );

my %ERROR2 =
    (
     0x01 => 'Exchanging tape cassette',
     0x02 => 'Expanding buffer full',
     0x04 => 'Transmission error',
     0x08 => 'Transmission buffer full',
     0x10 => 'Cover open',
     0x20 => 'Cancel key',
     0x40 => 'Top of tape not detected',
     0x80 => 'Not defined 2.80',
     );

# This maps the tape width from mm to pixels
# Note that we use a 2 pixel (one in each side) margin,
# the Brother driver uses a much wider margin.
my %WIDTH =
    (
     6=>42-2,
     9=>64-2,
     12=>84-2,
     18=>128-2,
     24=>128,
     );

# Constructor, call with the device to open '/dev/ttyS0'
# and, optionally, a hashref with other values than $opt below.
sub new($$;$) {
  my $class = shift;
  my $device = shift;
  my $opt = shift || {cut=>1, mirror=>0, feed=>4};

  my $usb = Device::USB->new();
  my $dev = $usb->find_device( 0x04f9, 0x202d) || die "couldn't find device";

 printf "Device: %04X:%04X\n", $dev->idVendor(), $dev->idProduct();
    print "Manufactured by ", $dev->manufacturer(), "\n",
          " Product: ", $dev->product(), "\n";
 $dev->open();
 my $cfg = $dev->config()->[0];
 print "Config:", $cfg->iConfiguration(), ": interface count: ",
       $cfg->bNumInterfaces(), "\n";
 my $inter = $cfg->interfaces()->[0]->[0];
 print "Interface:", $inter->bInterfaceNumber(),
       " name: ", $dev->get_string_simple($inter->iInterface()), 
       ": endpoint count: ", $inter->bNumEndpoints(), "\n";
my $ep = $inter->endpoints()->[0];
print "Endpoint:", $ep->bEndpointAddress(), " name: ", $dev->get_string_simple($inter->iInterface()), "\n";

  my $port = $dev;
#  my $port = new Device::SerialPort ($device) or die "Can't open $device: $!\n";
#  open my $port, "+<", "$device";
#  binmode $port;
#  $port->baudrate(57600); # This is the default speed, consult Brother docs for baudrate changing protocol
#  $port->parity("none");
#  $port->databits(8);
#  $port->stopbits(1);
#  $port->handshake("rts");

  my $self = bless {
      port=>$port,
      error=>'No response, is the device plugged in at all?', # This gets cleared if the device answers...
  }, $class;

  $self->getstatus;

  # initialize;
  unless ($self->{error}) {
      $self->{port}->write(chr(0x1B).'@');              # Initialize
      my $mode = ($opt->{feed}||0) & 31 | $opt->{cut} ? 64 : 0 | $opt->{mirror} ? 128 : 0;
      $self->{port}->write(chr(0x1B).'iM'.chr($mode));  # Set mode
      $self->{port}->write(chr(0x1B).'iR'.chr(1));      # Set raster mode
  }

  return $self;
}

# Request and read the status of the device...
sub getstatus($) {
    my $self = shift;

    $self->{port}->write(chr(0x1B).'iS');
#    select(undef,undef,undef,0.2);
    $self->readstatus;
}

# Read the status of the device, this will block for the specified timeout until the status has been received.
sub readstatus($;$) {
    my $self = shift;
    my $timeout = shift || 2;

    my $t0 = time;
    my $data = '';
    while (length($data) < 32 and $t0+$timeout >= time) {
	my ($l,$d) = $self->{port}->read(32);
	$data .= $d;
	select(undef,undef,undef,0.01) unless $l;
	while ($data and ord(substr($data,0,1)) != 0x80) {
	    $data = substr($data,1);
	}
    }

    my @s = map {ord} split '',$data;
    return 0 if $data eq '';

    unless ($s[0] == 0x80 and $s[1] == 0x20) {
	$self->{error} = 'Unable to find PT2500PC at serialport ('.join(',',map{sprintf("%02x",$_)} @s).')';
	return 0;
    }

    $self->{tapewidth}  = $s[10];
    $self->{pixelwidth} = $WIDTH{$s[10]};
    $self->{medium}     = $MEDIA{$s[11]}||"Unknown: $s[11]";
    $self->{statuskind} = $STATUSKIND{$s[18]}||"Unknown: $s[18]";
    $self->{sk}         = $s[18];
    $self->{phase1}     = $s[20];
    $self->{phase2}     = $s[21];
    $self->{notice}     = $NOTICE{$s[22]}||"Unknown: $s[22]";

    $self->{error} = '';
    while (my ($bit,$err) = each %ERROR1) {
	$self->{error} .= "$err " if $s[8] & $bit;
    }
    while (my ($bit,$err) = each %ERROR2) {
	$self->{error} .= "$err " if $s[9] & $bit;
    }

    return 1;
}

# This will print a number of pages, each one a GD image.
sub print {
    my $self = shift;

    while (@_ and !$self->{error}) {
	my $img = shift @_;

	my ($w,$h) = $img->getBounds();
	my $y0 = 64-$h / 2;
	for my $x (0..$w-1) {
	    my @bytes;
	    for my $x (0..15) {
		push @bytes, 0;
	    }

	    for my $y (0..127) {
		my $set = $y > 64-$WIDTH{$self->{tapewidth}}/2 && $y < 64+$WIDTH{$self->{tapewidth}}/2;
		$set = 0 unless $img->getPixel($x,$y-$y0);
		if ($set) {
		    my $bit = 2** (7-($y % 8));
		    $bytes[int($y / 8)] |= $bit;
		}
	    }

	    # Chop off the bytes that are zero, this cuts down on rs323 bandwidth.
	    while (@bytes and !$bytes[@bytes-1]) {
		pop @bytes;
	    }

	    if (!@bytes) {
		$self->{port}->write('Z'); # All bytes were zero
	    } else {
		my $data = join '', map {chr} @bytes;
		$self->{port}->write('G'.chr(@bytes).chr(0).$data);
	    }
	    usleep(500); # This seems to make it much more reliable...
	}

	if (@_) {
	    $self->{port}->write(chr(0x0C)); # There are more pages to print, don't discharge.
	} else {
	    $self->{port}->write(chr(0x1A)); # This is the last page, discharge.
	}

	# Wait for the page to print
	my $done = 0;
	while (!$done) {
	    if ($self->readstatus(10)) {
		$done = 1 if $self->{sk} == 1;
	    }
	}
    }
}

1;

