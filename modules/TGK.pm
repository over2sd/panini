package TGK;
print __PACKAGE__;

my $mw;
my $status = "\n(Status)";

sub createMainWin {
	my ($name,$ver,$w,$h,$x,$y) = @_;
	unless (defined $name) {
		$name = "Unnamed program";
	}
	unless (defined $ver) {
		$ver = "?";
	}
	my $geo = "+40+40";
	if (defined $x and defined $y) {
		$geo = "+$x+$y";
	}
	$geo = "x${h}$geo" if defined $h;
	$geo = "$w$geo" if defined $w;
	my $title = main::myName(1);
	$mw = new MainWindow(-title => "$title");
	setBG($mw,'mainbg'); # set my background
	$mw->geometry($geo);
#	place($mw->Label(-relief => 'sunken',-textvariable => \$status,-anchor => 'nw', -justify => 'left'),2,2,'ews',-columnspan => 10); # a status bar
	$mw->Label(-relief => 'sunken',-textvariable => \$status,-anchor => 'nw', -justify => 'left')->pack(-side => 'bottom', -fill => 'x', -expand => 0); # a status bar
	$mw->protocol('WM_DELETE_WINDOW', sub {
print "Checking for save window position..";
		if (FIO::config('Main','savepos') or 0) {
			my $geo = $mw->geometry;
			print ".saving..";
			$geo =~ m/(\d+)x(\d+)\+(\d+)\+(\d+)/;
			my ($w,$h,$x,$y) = ($1,$2,$3,$4);
			FIO::config('Main','width',$w);
			FIO::config('Main','height',$h);
			FIO::config('Main','left',$x);
			FIO::config('Main','top',$y);
			FIO::saveConf();
			$mw->destroy();
		}
		print ".Done.";
	});
	return $mw;
}
print ".";

sub pushStatus {
	my ($text,$continues) = @_;
	if ($continues) {
		$status .= "$text";
		return 1;
	}
	$status =~ s/.*\n//;
	$status .= "\n$text";
	return 1;
}

print ".";

sub setFont {
	my ($w,$fn) = @_;
	my $f = $w->GetDescriptiveFontName($fn);
	# TODO: Sanity check font name
	$w->configure(-font => $f, -text => $fn);
}
print ".";

sub setBG {
	my ($w,$cn) = @_;
	ref($w) =~ m/Tk::/ or print Common::lineNo(2);
	print "Coloring " . ref($w) . " - ";
	if (ref(\$cn) eq "SCALAR") {
		print "Keyword: $cn";
		$cn = (FIO::config('UI',$cn) or "%main%");
		print " $cn\n";
	}
	($cn eq "%main%") and $cn = (FIO::config('UI','mainbg') or "#CCF");
	$w->configure(-background => $cn);
	return $w;
}
print ".";

sub getGUI {
	return $mw;
}
print ".";

sub TFresh {
	$mw->update();
}
print ".";

sub updateEntry {
	my ($e,$newtext) = @_;
	my $oldtext = $e->get;
	$e->delete('0','end');
	$e->insert('end',"$newtext");
	print "Change " . ($e->validate ? "failed" : "successful") . ": $oldtext >> $newtext\n";
}
print ".";

sub bindEnters {
	my ($o,$s,$m) = @_;
	$m = 15 unless defined $m; # default mask
	my @mask = Common::expandMask($m,4);
	$o->bind('<Key-Return>',$s);
	$o->bind('<Return>',$s);
	$o->bind('<KP_Enter>',$s);
	return 0;
}
print ".";


sub makeOptBox {
	my ($t,@tabs) = @_;
	my $bb = $t->Frame()->grid(-row=>2,-column=>1);
	my $nb = $t->Scrolled('Frame', -scrollbars => 'osoe',)->grid(-row=>3,-column=>1);
	$t->Label(-text => "Options:")->grid(-row => 1, -column => 1);
	my $np = $nb->Frame()->grid(-row=>1,-column=>1);
	my ($optgroups) = ({});
	foreach my $n (@tabs) {
		$optgroups = addOptTab($bb,$np,$n,$optgroups);
	}
	Sui::storeData('ogroups',$optgroups);
	return ($bb,$np);
}
print ".";

sub addOptTab {
	my ($bb,$np,$on,$og) = @_;
	
	return $og;
}
print ".";

sub place {
	my ($w,$r,$c,$a,%extra) = @_;
	my $s = Common::hashString(%extra);
	$s = ($s eq "" ? "" : " + $s");
	Common::showDebug('g') and main::howVerbose() > 5 and print "placeWidget: $r x $c, S:" . ($a or "'w'") . $s . "\n";
	$w->grid(%extra);
	return $w->grid(-sticky=>($a or 'w'),-row=>($r or 1),-column=>($c or 1));
}
print ".";

### Destroy each child of a given frame
sub emptyFrame {
	my $frame = shift;
	my @kids = $frame->children;
	foreach my $c (@kids) {
		$c->destroy();
	}
	return 1;
}
print ".";

FIO::config("UI","GUI","tk"); # set UI type
print " OK; ";
1;
