#!/usr/bin/perl
use strict; use warnings;
my $PROGRAMNAME = "Panini pantry system";
my $version = "0.21a";
my $cfn = "config.ini";
my $debug = 0;
my $dbn = 'pantry';
my $dbs = '';

$|++; # Immediate STDOUT, maybe?
print "[I] $PROGRAMNAME v$version is running.";
flush STDOUT;

use Getopt::Long;

GetOptions(
	'data|d=s' => \$dbn, # database name
	'host|h=s' => \$dbs, # DB host
	'conf|c=s' => \$cfn, # configuration file
	'verbose|v' => \$debug, # debug verbosity (default 0)
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
#Common::debugAdd('q'); # Show SQL queries

my $gui = TGK::createMainWin($PROGRAMNAME,$version,670,490);
my ($pw,$ph) = (600,480);
my ($dbh,$error) = FlexSQL::getDB('L') or undef;

Sui::storeData('panewidth',$pw);
Sui::storeData('paneheight',$ph);

TGUI::populateMainWin($dbh,$gui,0);

MainLoop; # actually run the program

# TODO: Cook panel: Add a upc field to scan to decrement Qty
