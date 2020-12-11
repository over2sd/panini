#!/usr/bin/perl
use strict; use warnings;
my $PROGRAMNAME = "Panini pantry system";
my $version = "0.27a";
my $cfn = "config.ini";
my $debug = 1;
my $dbn = 'pantry';
my $dbs = '';
my $active = '';

$|++; # Immediate STDOUT, maybe?
print "[I] $PROGRAMNAME v$version is running.";
flush STDOUT;

sub myName {
	my ($showver,) = @_;
	return "$PROGRAMNAME" . ($showver ? " v. $version" : "");
}

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

sub activePage {
	my $page = shift;
	return $active unless defined $page;
	TGK::pushStatus("Selecting $page.");
	$active = $page;
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
require Options;
#Common::debugAdd('q'); # Show SQL queries
Common::debugAdd('d'); # Show data transfer
Common::debugAdd('g'); # Show certain GUI events
Common::debugAdd('c'); # Show config loading
FIO::loadConf($cfn);
FIO::config('Debug','v',$debug);
my ($w,$h,$x,$y) = ((FIO::config('Main','width') or 1020),(FIO::config('Main','height') or 620),(FIO::config('Main','top') or 40),(FIO::config('Main','left') or 40),);
my $gui = TGK::createMainWin($PROGRAMNAME,$version,$w,$h,$x,$y);
my ($pw,$ph) = (800,542);
my  ($dbh,$error);
Sui::storeData('panewidth',$pw);
Sui::storeData('paneheight',$ph);
TGK::pushStatus("Loading GUI..");
if (FIO::config('DB','askDB')) {
	TGUI::selectDB($gui);
} else {
	my $pwc = (FIO::config('DB','pwp') or 0);
	my $pwt;
	my ($dbs,$dbu,$dbn) = ((FIO::config('DB','host') or "ERROR"),(FIO::config('DB','uname') or "ERROR"),(FIO::config('DB','dbname') or "ERROR"));
	$pwc and ($pwt = TGUI::getDBPass($gui,$dbs,$dbu,$dbn));
	my @args = ((FIO::config('DB','type') or 'L'),$dbs,);
	if ("$args[0]" eq "M") {
		push(@args,$dbn,($pwc ? $pwt : undef),($dbu eq "" ? undef : $dbu));
	}
	($dbh,$error) = FlexSQL::getDB(@args) or undef;
	TGUI::populateMainWin($dbh,$gui,0);
}
TGK::pushStatus(".Ready",1);
MainLoop; # actually run the program
FIO::config('Main','writecfg') and FIO::saveConf(); # write config on exit
