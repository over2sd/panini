package TGK;
print __PACKAGE__;

my $mw;

sub createMainWin {
	my ($name,$ver,$w,$h,$x,$y) = @_;
	unless (defined $name and defined $ver) {
		$name = "Unnamed program";
		$ver = "?";
	}
	my $geo = "+40+40";
	$geo = "x${h}$geo" if defined $h;
	$geo = "$w$geo" if defined $w;
	my $title = "$name v. $ver";
	$mw = new MainWindow(-title => "$title");
	$mw->geometry($geo);
	return $mw;
}
print ".";

sub getGUI {
	return $mw;
}

sub TFresh {
	$mw->update();
}
print ".";

FIO::config("UI","GUI","tk"); # set UI type
print ".";
1;