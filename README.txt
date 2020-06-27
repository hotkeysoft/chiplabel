this code is placed in the public domain by John Meacham.
john@repetae.net  http://notanumber.net/
code imported from darcs repository http://repetae.net/repos/clabel

More information on setup/usage https://www.johnrleeman.com/2014/02/11/never-confuse-chip-pinouts-again/

2020 Updates by hotkeysoft <dev@hotkeysoft.net>
Original untouched code from  http://repetae.net/repos/clabel in archive branch
Removed PTouch specific code as I only need to generate images to print on regular printer

Usage:
./chip_label.prl -c 555

     Options:
       --help            brief help message
       -w n              specify tape width in mm
       -c chip           chip name as specified in chips.yaml
       -a                generate pngs for all chips in the file
       -t (hc,ttl,ac,cd) technology of 74 or 4000 series logic
       -i                invert label, for dead bug soldering.
       -f                draw a frame around the chip

    output placed in out/ directory.
