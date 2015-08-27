This script is Perl implementation of [VI/42 Identification of a Constellation From Position (Roman 1987)](http://cdsarc.u-strasbg.fr/viz-bin/Cat?VI/42).

Based on C code of program.c

Requirements:
* data.dat from VI/42 (see link above) or from this package
* Getopt::Long
* Math::Trig
    
Usage (from console):
    $ ./constByCoords.pl [--ra HH.hhhh --dec DD.dddd [--epoch YYYY.0] [--quiet]]
Note: instead HH.hhhh or DD.dddd you can use HH:MM:SS.ss or DD:MM:SS.ss (see below)

Options:
    --ra — RA (α), right ascension of the celestial object
    --dec — DEC (δ), declination of the celestial object
    --epoch — Epoch of the coordinates (default 2000.0)
    --quiet — Print only constellation name

Examples:
1. Without any option:
    $ ./constByCoords.pl
    Output:
Usage: ./constByCoords.pl [--ra HH.hhhh --dec DD.dddd [--epoch YYYY.0] [--quiet]]
  Note: instead HH.hhhh or DD.dddd you can use HH:MM:SS.ss or DD:MM:SS.ss

2. Using format HH.hhhh, DD.dddd (Sirius, α CMa)
    $ ./constByCoords.pl --ra=6.75230861111 --dec=-16.7215361111
    Output:
 RA =  6.7523 Dec = -16.7215  is in Constellation: CMa
===============The Equinox for these positions is: 2000.0

3. Using format HH:MM:SS.sss, DD:MM:SS.sss (Regulus, α Leo)
    $ ./constByCoords.pl --ra=10:08:22.053 --dec=+11:58:02.05
    Output:
 RA = 10.1395 Dec =  11.9672  is in Constellation: Leo
===============The Equinox for these positions is: 2000.0

4. Using epoch 1950.0 instead default 2000.0
    $ ./constByCoords.pl --ra=6.2222 --dec=-81.1234 --epoch 1950.0
    Output:
 RA =  6.2222 Dec = -81.1234  is in Constellation: Men
===============The Equinox for these positions is: 1950.0

5. Using qiuet mode (print only constellation name)
    $ ./constByCoords.pl --ra=9.4555 --dec=-19.9000 --epoch 1950.0 --quiet
    Output:
Hya

Some example data got from README file of VI/42
