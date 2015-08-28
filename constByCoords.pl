#!/usr/bin/perl

use strict;
use warnings;
use Math::Trig;
#use Data::Dumper;
use Getopt::Long;
use FindBin qw /$Bin/;

my $CONVH = 0.2617993878;
my $CONVD = 0.1745329251994e-01;
my $PI4 = 6.28318530717948;
my $E75 = 1875.0;
my ($ARAD, $DRAD, $A, $D, $E, $RAH, $RA, $DEC, $RAL, $RAU, $DECL, $DECD, $CON, $quiet);

usage() if (scalar @ARGV == 0);

GetOptions('ra=s'    => \$RAH,
           'dec=s'   => \$DECD,
           'epoch=f' => \$E,
           'quiet!'  => \$quiet)
    or die("Error in command line arguments\n");

usage() unless $RAH;
$RAH = validate_ra($RAH);

usage() unless $DECD;
$DECD = validate_dec($DECD);

$E ||= 2000.0;

# PRECESS POSITION TO 1875.0 EQUINOX #
$ARAD = $CONVH * $RAH;#die "ARAD = $ARAD\n";
$DRAD = $CONVD * $DECD;
($ARAD, $DRAD, $E, $E75, $A, $D) = HGTPRC($ARAD, $DRAD, $E, $E75, $A, $D);
if ($A <  0.0) {
    $A = $A + $PI4;
}
if ($A >= $PI4) {
    $A = $A - $PI4;
}
$RA = $A / $CONVH;
$DEC = $D / $CONVD;

# FIND CONSTELLATION SUCH THAT THE DECLINATION ENTERED IS HIGHER THAN
# THE LOWER BOUNDARY OF THE CONSTELLATION WHEN THE UPPER AND LOWER
# RIGHT ASCENSIONS FOR THE CONSTELLATION BOUND THE ENTERED RIGHT
# ASCENSION
open my $f2, '<', $FindBin::Bin . '/data.dat' or die "open() failed: $!\n";
#seek ($f2, 0, 0);
while (<$f2>)
{
    chomp;
    if (/^\s*(\d+\.\d+)\s+(\d+\.\d+)\s+(\-?\d+\.\d+)\s+(\w{3})$/) {
        ($RAL, $RAU, $DECL, $CON) = ($1, $2, $3, $4);
        next if $DECL >  $DEC;
        next if $RAU <= $RA;
        next if $RAL > $RA;
        # if CONSTELLATION HAS BEEN FOUND, WRITE RESULT AND RERUN PROGRAM FOR
        #   NEXT ENTRY.  OTHERWISE, CONTINUE THE SEARCH BY RETURNING TO RAU
        if ($RA >= $RAL && $RA < $RAU &&  $DECL <= $DEC) {
            printf " RA =%8.4f Dec = %8.4f  is in Constellation: %s\n",
                    $RAH, $DECD, $CON unless $quiet;
            printf "%s\n", $CON if $quiet;
        } elsif ($RAU < $RA) {
            next;
        } else {
            printf " Constellation NOT FOUND for: RA =%8.4f Dec = %8.4f\n",
                   $RAH, $DECD unless $quiet;
        }
        last;
    } else {
        print STDERR "Invalid file format\n";
        print "$_\n";
        exit -1;
    }
}
close $f2;

# printf(" End of input positions after: RA = %7.4f   DEC = %8.4f\n", 
#$RAH,$DECD) ;
printf "===============The Equinox for these positions is: %6.1f\n", $E unless $quiet;


1;

sub HGTPRC
{
    my ($RA1, $DEC1, $EPOCH1, $EPOCH2, $RA2, $DEC2) = @_;
#      HERGET PRECESSION, SEE P. 9 OF PUBL. CINCINNATI OBS. NO. 24
# INPUT=  RA1 AND DEC1 MEAN PLACE, IN RADIANS, FOR EPOCH1, IN YEARS A.D.
# OUTPUT= RA2 AND DEC2 MEAN PLACE, IN RADIANS, FOR EPOCH2, IN YEARS A.D.
    my ($CDR, @X1, @X2, @R, $T, $ST, $A, $B, $C, $EP1, $EP2, $CSR,
        $SINA, $SINB, $SINC, $COSA, $COSB, $COSC);
    $CDR = 0.17453292519943e-01;
    ($EP1, $EP2) = (0.0, 0.0);
#      COMPUTE INPUT DIRECTION COSINES
    $A = cos($DEC1);
    $X1[0] = $A * cos($RA1);
    $X1[1] = $A * sin($RA1);
    $X1[2] = sin($DEC1);
#      SET UP ROTATION MATRIX (R)
    if (($EP1 == $EPOCH1) && ($EP2 == $EPOCH2)) {}
    else {
        $CSR = $CDR / 3600.0;
        $T = 0.001 * ($EPOCH2 - $EPOCH1);
        $ST = 0.001 * ($EPOCH1 - 1900.0);
        $A = $CSR * $T * (23042.53 + $ST * (139.75 + 0.06 * $ST) 
           + $T * (30.23 - 0.27 * $ST + 18.0 * $T));
        $B = $CSR * $T * $T * (79.27 + 0.66 * $ST + 0.32 * $T) + $A;
        $C = $CSR * $T * (20046.85 - $ST * (85.33 + 0.37 * $ST) 
           + $T * (-42.67 - 0.37 * $ST - 41.8 * $T));
        $SINA = sin($A);
        $SINB = sin($B);
        $SINC = sin($C);
        $COSA = cos($A);
        $COSB = cos($B);
        $COSC = cos($C);
        $R[0][0] = $COSA * $COSB * $COSC - $SINA * $SINB;
        $R[0][1] = -$COSA * $SINB - $SINA * $COSB * $COSC;
        $R[0][2] = -$COSB * $SINC;
        $R[1][0] = $SINA * $COSB + $COSA * $SINB * $COSC;
        $R[1][1] = $COSA * $COSB - $SINA * $SINB * $COSC;
        $R[1][2] = -$SINB * $SINC;
        $R[2][0] = $COSA * $SINC;
        $R[2][1] = -$SINA * $SINC;
        $R[2][2] = $COSC;
    }
#      PERFORM THE ROTATION TO GET THE DIRECTION COSINES AT EPOCH2
    for my $i (0 .. 2) {
        $X2[$i] = 0.0;
        for my $j (0 .. 2) {
            $X2[$i] += $R[$i][$j] * $X1[$j];
        }
    }
    $RA2 = atan2($X2[1], $X2[0]);
    if ($RA2 < 0)
    {
        $RA2 = 6.28318530717948 + $RA2;
    }
    $DEC2 = asin($X2[2]);
    return ($RA1, $DEC1, $EPOCH1, $EPOCH2, $RA2, $DEC2);
}

sub usage {
    print STDOUT "Usage: $0 [--ra HH.hhhh --dec DD.dddd [--epoch YYYY.0] [--quiet]]\n";
    print STDOUT "  Note: instead HH.hhhh or DD.dddd you can use HH:MM:SS.ss or DD:MM:SS.ss\n";
    exit 0;
}

sub validate_ra {
    my $ra = shift;
    my $ret = 0;
    if ($ra =~ /^\d{1,3}\.\d+$/) {
        if ($ra < 0 or $ra > 360) {
            print STDERR "RA(DD.ddd) must be in [0..360]\n";
            exit -1;
        }
        #print "RA(DD.ddd): $ra\n";
        $ret = $ra;
    } elsif ($ra =~ /^(\d{1,2}):(\d{1,2}):(\d{1,2}(?:\.\d+)?)$/) {
        my ($h, $m, $s) = ($1, $2, $3);
        $h = trim_leading_zero($h);
        $m = trim_leading_zero($m);
        $s = trim_leading_zero($s);
        $h = 0 unless $h;
        if (($h < 0) or ($h > 23)) {
            print STDERR "RA hour must be in [0..23]\n";
            exit -1;
        }
        $h = int $h;
        $m = 0 unless $m;
        if (($m < 0) or ($m > 59)) {
            print STDERR "RA min must be in [0..59]\n";
            exit -1;
        }
        $m = int $m;
        $s += 0.0;
        if (($s < 0) or ($s > 59.99999999)) {
            print STDERR "RA sec must be in [0..60)\n";
            exit -1;
        }
        #print "RA(HH:MM:SS.ss)$h $m $s\n";
        $ret = 1 * ($h + $m / 60 + $s / 3600);
    }
    return $ret;
}

sub validate_dec {
    my $dec = shift;
    my $ret = 0;
    if ($dec =~ /^[-+]?\d{1,3}\.\d+$/) {
        $dec += 0.0;
        my $mod = abs $dec;
        if ($mod < 0 or $mod > 90) {
            print STDERR "DEC(DD.ddd) must be in [-90..90]\n";
            exit -1;
        }
        #print "DEC(DD.ddd): $dec\n";
        $ret = $dec;
    } elsif ($dec =~ /^([-+]?)(\d{1,2}):(\d{1,2}):(\d{1,2}(?:\.\d+)?)$/) {
        my ($sign, $d, $m, $s) = ($1, $2, $3, $4);
        if ($sign eq '+' or $sign eq '') {
            $sign = 1;
        } elsif ($sign eq '-') {
            $sign = -1;
        } else {
            $sign = 0;
        }
        #print "$sign $d $m $s\n";die;
        $d = trim_leading_zero($d);
        $m = trim_leading_zero($m);
        $s = trim_leading_zero($s);
        $d = 0 unless $d;
        if (($d < 0) or ($d > 90)) {
            print STDERR "DEC degree must be in [-90..90]\n";
            exit -1;
        }
        $d = int $d;
        $m = 0 unless $m;
        if (($m < 0) or ($m > 59)) {
            print STDERR "DEC min must be in [0..59]\n";
            exit -1;
        }
        $m = int $m;
        $s = 0.0 unless $s;
        $s += 0.0;
        if (($s < 0) or ($s > 59.99999999)) {
            print STDERR "DEC sec must be in [0..60)\n";
            exit -1;
        }
        #print "DEC(DD:MM:SS.ss) $sign $d $m $s\n";
        $ret = $sign * ($d + $m / 60 + $s / 3600);
    }
    return $ret;
}

sub trim_leading_zero {
    my $str = shift;
    $str =~ s/^0+//;
    return $str;
}
