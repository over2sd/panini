#!/usr/bin/perl
use strict; use warnings;
my $PROGRAMNAME = "Panini pantry system";
my $version = "0.01a";
my $cfn = "config.ini";
my $debug = 9;
my $dbn = 'pantry.dbl';
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

use Tk;

use lib "./modules/";
print "\n[I] Loading modules...";

require Sui;
require Common;
require FIO;
require FlexSQL;
require TGUI;
require TGK;
FIO::loadConf($cfn);
FIO::config('Debug','v',$debug);

my $gui = TGK::createMainWin($PROGRAMNAME,$version,);
my ($dbh,$error) = FlexSQL::getDB('L') or undef;

TGUI::populateMainWin($dbh,$gui,0);

MainLoop; # actually run the program