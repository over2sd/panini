package TGK;
print __PACKAGE__;

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
	my $mw = new MainWindow(-title => "$title");
	$mw->geometry($geo);
	return $mw;
}
print ".";


print ".";
1;
