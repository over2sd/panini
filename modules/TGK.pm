package TGK;
print __PACKAGE__;

my $mw;

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
	my $title = "$name v. $ver";
	$mw = new MainWindow(-title => "$title");
	$mw->geometry($geo);
	return $mw;
}
print ".";

sub setFont {
	my ($w,$fn) = @_;
	my $f = $w->GetDescriptiveFontName($fn);
	# TODO: Sanity check font name
	$w->configure(-font => $f, -text => $fn);
}
print ".";

sub getGUI {
	return $mw;
}

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
	Common::showDebug('g') and main::howVerbose() > 5 and print "placeWidget: $r, $c, " . ($a or "'w'") . ", " . $s . "\n";
	$w->grid(%extra);
	return $w->grid(-sticky=>($a or 'w'),-row=>($r or 1),-column=>($c or 1));
}
print ".";

FIO::config("UI","GUI","tk"); # set UI type
print " OK; ";
1;
