#!/usr/bin/perl
use strict; use warnings;
my $PROGRAMNAME = "Panini pantry system";
my $version = "0.17a";
my $cfn = "config.ini";
my $debug = 9;
my $dbn = 'pantry';
my $dbs = '';

$|++; # Immediate STDOUT, maybe?
print "[I] $PROGRAMNAME v$version is running.";
flush STDOUT;

use Getopt::Long;

GetOptions(
	'data|d=s' => \$dbn,
	'host|h=s' => \$dbs,
	'conf|c=s' => \$cfn,
	'verbose|v' => \$debug,
);

sub howVerbose {
	return $debug;
}

print "DB: $dbn...\n";

use Tk;

use lib "./modules/";
print "\n[I] Loading modules...";

require skrDebug;

require Sui;
Sui::storeData('dbname',$dbn);
require Common;
require FIO;
require FlexSQL;
require UPC;
require TGUI;
require TGK;
FIO::loadConf($cfn);
FIO::config('Debug','v',$debug);

my $gui = TGK::createMainWin($PROGRAMNAME,$version,630,460);
my ($dbh,$error) = FlexSQL::getDB('L') or undef;

TGUI::populateMainWin($dbh,$gui,0);

MainLoop; # actually run the program