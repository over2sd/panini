package TGUI;
print __PACKAGE__;

use Panini qw(Prod );
require Tk::BrowseEntry;

sub entryRow {
	my ($parent,$name,$r,$c,$s,$tv) = @_;
	my %args = ( -row => $r, -column => $c );
	my $lab = $parent->Label(-text=>"$name")->grid(%args);
	$args{-columnspan} = $s if defined $s;
	$args{-column}++;
	my $ent = $parent->Entry()->grid(%args);
	$ent->configure(-textvariable=> $tv) if (defined $tv and ref($tv) eq "SCALAR");
	return $ent;
}

sub emptyFrame {
	my $frame = shift;
	my @kids = $frame->children;
	foreach my $c (@kids) {
		$c->destroy();
	}
}

sub showPantryLoader {
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	emptyFrame($of);
	my $upc = "";
	my $name = "";
	my $size = 0;
	my $unit = "oz";
	my $ue = entryRow($of,"UPC: ",1,1);
	my $if = $of->Frame();
	$if->grid(-row=>2,-column=>1,-columnspan=>4);
	sub saveItemInfo {
		my ($but,$dbh,$upc,$name,$size,$uom) = @_;
		$but->configure(-state => 'disabled');
		print "N: $name, S: $size, U: $uom, C: $upc...\n";
die "Not finished coding this.\n";
	}

	# bind enter here to a function that either adds one to the onhand,
	#	or if not found, pulls open the description entries below for saving.
	sub incrementUPC {
		my $ut = $ue->get();
		print "Received: $ut...\n";
		my $dbh = FlexSQL::getDB();
		my $st = "SELECT * FROM counts WHERE upc=?;";
		my $row = FlexSQL::doQuery(6,$dbh,$st,$ut);
		skrDebug::dump($row);
		if (defined $row) {
			$st = "UPDATE counts SET qty=qty+1 WHERE upc=?;";
		} else {
			$st = "INSERT INTO counts (upc,qty) VALUES (?,1);";
		}
		my $err = FlexSQL::doQuery(2,$dbh,$st,$ut);
		print "Err: $err\n";
		my $qty = (defined $row{qty} ? $row{qty} : 1);
		$st = "SELECT * FROM items WHERE upc=?;";
		$row = FlexSQL::doQuery(6,$dbh,$st,$ut);
		skrDebug::dump($row);
		$row{name} = "UNNAMED" unless defined $row{name};
		my ($nv,$sv,$uv,$okb) = (undef,1,"oz",undef);

		my $ne = entryRow($if,"Name: ",1,1,undef,\$nv);
		$ne->delete(0,'end');
		$ne->insert(0,$row{name});
		my $se = entryRow($if,"Size: ",2,1,undef,\$sv);
		my $ce = $if->BrowseEntry(-width=>5,-textvariable=>\$uv);
		$ce->grid(-row=>2,-column=>3);
		my $ql = $if->Label(-text=>"Qty: ");
		$ql->grid(-row=>1,-column=>3);
		my $qe = $if->Entry(-text=>$qty);
		$qe->grid(-row=>1,-column=>4);
		$okb = $if->Button(-text=>"Save", -command=> sub {
			return if ($nv eq "UNNAMED");
			saveItemInfo($okb,$dbh,$ut,$nv,$sv,$uv);
		});
		$okb->grid(-row=>5,-column=>5);
	}
	$ue->bind('<Key-Return>', \&incrementUPC);
	$ue->focus;
}
print ".";

sub showButtonPanel {
	my ($parent,) = @_;
	my $bf = $parent->Frame();
	my %butpro = ( -fill=>'x', -padx=>2, -pady=>2);
	my $loadb = $bf->Button(-text=>"Store",-command=>sub { showPantryLoader($parent); })->pack(%butpro);
	my $contb = $bf->Button(-text=>"Cook",-command=>sub { showPantryContents($parent); })->pack(%butpro);
	my $listb = $bf->Button(-text=>"Buy",-command=>sub { showShoppingList($parent); })->pack(%butpro);
	my $prodb = $bf->Button(-text=>"Price",-command=>sub { showProductInfo($parent); })->pack(%butpro);
	
	
	$bf->grid(-row=>1,-column=>1);
}
print ".";

sub showPantryContents {
}
sub showProductEntry {
}
sub showProductInfo {
}
sub showShoppingList {
}
sub showPriceEntry {
}
sub showStoreEntry {
}

sub populateMainWin {
	my ($dbh,$win,$reset) = @_;
	my $of = $win->Frame();
	$win->{rtpan} = $of;
	$of->grid(-row=>1,-column=>2,-columnspan=>4);
	unless (FlexSQL::table_exists($dbh,"items") && FlexSQL::table_exists($dbh,"stores")) {
		print "-=-";
		FlexSQL::makeTables($dbh);
	}
	showButtonPanel($win);
	showPantryLoader($win);
}
print ".";

print ".";
1;
