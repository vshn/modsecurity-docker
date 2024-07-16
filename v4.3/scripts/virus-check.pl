#!/usr/bin/perl
#---------------------------------------------------
#
# virus-check.pl
#
# ModSec virus check script used as a wrapper for
# clamAV
#
#---------------------------------------------------
# Author:       Christian Folini, netnea.com
# Last Update:  2015-06-23
#---------------------------------------------------

#---------------------------------------------------
# Initialisation
#---------------------------------------------------

use strict;
use warnings;
use POSIX qw(strftime);

my $do_log = $ENV{"CLAMD_DEBUG_LOG"} eq "on" ? 1 : 0;
my $logfile = "/dev/stdout";

my $BIN = "clamdscan";

if ($#ARGV != 0) {
    print "Usage: virus-check.pl <filename>\n";
    exit;
}

my ($myfile) = shift @ARGV;
my $filesize = -s $myfile;

if ( $do_log ) { writelog("Initialisation for scanning of file $myfile ($filesize bytes)")} ;

my $result = "";
my $status = "";
my $output = "";

#---------------------------------------------------
# Sub-Functions
#---------------------------------------------------

sub writelog {  
   # We open/close the logfile after every time as there might be 
   # multiple instances attempting to write.
   # If there is a collision we simply ignore the failure and move on

   my ($logitem) = @_;
   my $date = strftime "%Y-%m-%d %H:%M:%S", localtime;
   
   if ( open(LOG, ">>", $logfile)) {
   	print LOG "$date : pid $$ : $logitem\n";
   	close(LOG);
   } else {
   	print "Problem writing logfile $logfile. Ignoring.\n";
   }

}

#---------------------------------------------------
# clamAV execution
#---------------------------------------------------


if ( $do_log ) { writelog("Calling clamAV ($BIN) ...")} ;

$result = `$BIN --stdout $myfile`;

my $myresult = $result;

$myresult =~ s/\n/ | /g;
if ( $do_log ) { writelog("ClamAV returned result : $myresult")} ;

$result =~ m/^(.+)/;
$status = $1;

if ( $do_log ) { writelog("Extracted status : $status")} ;

$output = "0 Error parsing clamAV output : $1";

#---------------------------------------------------
# Interpretation of clamAV output
#---------------------------------------------------

if ($status =~ m/: OK$/) {
    $output = "1 clamAV OK";
}
elsif ($status =~ m/: Empty file\.?$/) {
    $output = "1 empty file";
}
elsif ($status =~ m/: (.+) ERROR$/) {
    $output = "0 clamAV: $1";
}
elsif ($status =~ m/: (.+) FOUND$/) {
    $output = "0 clamAV: $1";
}

#---------------------------------------------------
# Bailing out
#---------------------------------------------------

if ( $do_log ) { writelog("Return value : $output")} ;

print "$output\n";

if ( $do_log ) { writelog("Bailing out")} ;

