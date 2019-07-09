package TGUI;
print __PACKAGE__;

use Panini qw(Prod );
require Tk::BrowseEntry;

sub entryRow {
	my ($parent,$name,$r,$c,$s,$tv,$valcmd) = @_;
	my %args = ( -row => $r, -column => $c );
	my $lab = $parent->Label(-text=>"$name")->grid(%args);
	$args{-columnspan} = $s if defined $s;
	$args{-column}++;
	my $ent = $parent->Entry()->grid(%args);
	$ent->configure(-textvariable=> $tv) if (defined $tv and ref($tv) eq "SCALAR");
	$ent->configure(-validate => 'focusout', -validatecommand => $valcmd) if (defined $valcmd and ref($valcmd) eq "CODE");
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
	my $tmp = $of->Label(-text => "Enter new pantry contents")->grid(-row => 1, -column => 1);
	my $upc = "";
	my $name = "";
	my $size = 0;
	my $unit = "oz";
	my $ue = entryRow($of,"UPC: ",2,1);
	my $if = $of->Frame();
	$if->grid(-row=>3,-column=>1,-columnspan=>4);
	sub saveItemInfo {
		my ($but,$dbh,$upc,$name,$size,$uom,$qty,$generic,$keep,$hr,$tf) = @_;
#		$but->configure(-state => 'disabled');
		if ($name eq "UNNAMED") { print "Product needs name!\n"; return; }
		if ($generic eq "Grocery") { print "Product needs equivalence!\n"; return; }
		print "N: $name, S: $size, U: $uom, C: $upc... Q: $qty, G: $generic, K: $keep...\n";
		my $st;
		skrDebug::dump($hr);
		if ($$hr{update}) {
			$st = "UPDATE items SET name=?, unit=?, size=?, generic=?, keep=? WHERE upc=?;";
		} else {
			$st = "INSERT INTO items (name,unit,size,generic,keep,upc) VALUES (?,?,?,?,?,?);";
		}
		my @parms = ($name,$uom,$size,$generic,$keep,$upc);
		my $err = FlexSQL::doQuery(2,$dbh,$st,@parms);
		return unless ($err);
		emptyFrame($tf);
		my $l = $tf->Label(-text=>"Item Saved!");
		$l->grid(-row=>1,-column=>2);
		unless ($qty == $$hr{qty}) {
		print "QQ: $qty vs " . $$hr{qty} . "...\n";
			$st = "UPDATE counts SET qty=? WHERE upc=?;";
			$err = FlexSQL::doQuery(2,$dbh,$st,$qty,$upc);
			print "Records changed: $err\n";
			return unless ($err);
			my $lq = $tf->Label(-text=>"Quantity updated!");
			$lq->grid(-row=>1,-column=>1);
		}
		$tf->focusPrev();
	}

	# bind enter here to a function that either adds one to the onhand,
	#	or if not found, pulls open the description entries below for saving.
	sub incrementUPC {
		my $ut = $ue->get();
		print "Received: $ut...\n";
		my $dbh = FlexSQL::getDB();
		my $st = "SELECT * FROM counts WHERE upc=?;";
		my $row = FlexSQL::doQuery(6,$dbh,$st,$ut);
		if (defined $row) {
			$st = "UPDATE counts SET qty=qty+1 WHERE upc=?;";
		} else {
			$st = "INSERT INTO counts (upc,qty) VALUES (?,1);";
		}
		my $err = FlexSQL::doQuery(2,$dbh,$st,$ut);
		print "Err: $err\n";
		my $qty = (defined $$row{qty} ? $$row{qty} : 1);
		$st = "SELECT * FROM items WHERE upc=?;";
		$row = FlexSQL::doQuery(6,$dbh,$st,$ut);
		skrDebug::dump($row);
		$$row{update} = (defined $row ? 1 : 0);
		$$row{name} = "UNNAMED" unless defined $$row{name};
		$$row{qty} = $qty;
		my ($nv,$sv,$uv,$gv,$kv) = (undef,1,"oz","Grocery",0);
		$sv = $$row{size} if defined $$row{size};
		$uv = $$row{unit} if defined $$row{unit};
		$gv = $$row{generic} if defined $$row{generic};
		$kv = $$row{keep} if defined $$row{keep};
		our $okb;
		our $ne = entryRow($if,"Name: ",1,1,undef,\$nv,\&myValidate);
		our $ge = entryRow($if,"Item Equivalence: ",4,1,undef,\$gv,\&myValidate);
		$okb = $if->Button(-text=>"Save", -state => 'disabled', -command=> sub {
			$ne->focus if ($nv eq "UNNAMED");
			$ge->focus if ($gv eq "Grocery");
			saveItemInfo($okb,$dbh,$ut,$nv,$sv,$uv,$qty,$gv,$kv,$row,$if);
		});
		sub myValidate {
			my ($pv,$av,$cv) = @_;
			return 0 if ($pv eq $cv); # no change made
			$okb->configure( -state=> 'active' ) if (defined $okb);
			return 1
		}
		
		$ne->delete(0,'end');
		$ne->insert(0,$$row{name});
		my $se = entryRow($if,"Size: ",2,1,undef,\$sv,\&myValidate);
		my $ce = $if->BrowseEntry(-width=>5,-variable=>\$uv,-validate=>'focusout',-validatecommand =>\&myValidate);
		$ce->insert('end','oz');
		$ce->insert('end','ml');
		$ce->insert('end','cnt');
		$ce->insert('end','in');
		# if large measures:
		$ce->insert('end','ft');
		$ce->insert('end','lb');
		$ce->insert('end','L');
		$ce->grid(-row=>2,-column=>3);
		my $ql = $if->Label(-text=>"Qty: ");
		$ql->grid(-row=>1,-column=>3);
		$if->Label(-text=>"/")->grid(-row=>1,-column=>5);
		my $changed = 0;
		my $qe = $if->Entry(-textvariable=>\$qty,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, );
		my $ke = $if->Entry(-textvariable=>\$kv,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, );
		$qe->grid(-row=>1,-column=>4);
		$ke->grid(-row=>1,-column=>6);
		$okb->grid(-row=>6,-column=>5);
	}
	$ue->bind('<Key-Return>', \&incrementUPC);
	$ue->focus;
}
print ".";

sub showButtonPanel {
	my ($parent,) = @_;
	my $bf = $parent->Frame(-relief=>'groove');
	my %butpro = ( -fill=>'x', -padx=>2, -pady=>2);
	my $loadb = $bf->Button(-text=>"Store",-command=>sub { showPantryLoader($parent); })->pack(%butpro);
	my $contb = $bf->Button(-text=>"Cook",-command=>sub { showPantryContents($parent); })->pack(%butpro);
	my $listb = $bf->Button(-text=>"Buy",-command=>sub { showShoppingList($parent); })->pack(%butpro);
	my $prodb = $bf->Button(-text=>"Price",-command=>sub { showProductInfo($parent); })->pack(%butpro);
	
	
	$bf->grid(-row=>1,-column=>1,-sticky=>"nsw");
}
print ".";

sub showPantryContents { # For cooking/reducing inventory
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	emptyFrame($of);
	my $tmp = $of->Label(-text => "Contents of Pantry")->pack();

}
sub showProductEntry { # For adding a new product entry
}
sub showProductInfo { # for pricing products in the store
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	emptyFrame($of);
	my $tmp = $of->Label(-text => "Pricing Tool")->pack();

#	showAddMinButton($of); # Make the item being priced an item user wants to keep on hand.
}

sub getMinimums { # calculate the highest minimum of items in a category.
	# Allows you to set a minimum for "Tomatoes, Diced" on the name brand can and have it apply to the generic that has a keep of 0.
	my $minimums = Sui::passData('minimums');
	my $dbh = Sui::passData('db');
	unless (Sui::passData('minchanged') <= Sui::passData('minindexed')) { # only do this once unless a minimum has been chaged.
		Sui::storeData('minindexed',time()); # store new index time
		my $st = "SELECT generic, MAX(keep) FROM items GROUP BY generic;";
		$list = FlexSQL::doQuery(4,$dbh,$st,$ut);
		


		# pull data from DB here.
		Sui::storeData('minimums',$minimums); # Store new minimums
	}
	return $minimums;
}
print ".";

sub getDeficits {
	my ($kvs,) = @_;
	my @generics = keys %$kvs;
	my @lows;
	# get list of lows/outs
	return @lows;
}
print ".";

sub showAddMinButton { # Adds a button to the list that allows adding a
	# minimum/upc, allowing user to add an item to the shopping list
	# and PITS without changing its onhand qty.	
}

sub listToBuys {
	
}

sub showShoppingList { # For buying items that are getting low
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	emptyFrame($of);
	my $tmp = $of->Label(-text => "Shopping List")->pack();
	my $pims = getMinimums();
	my @list = getDeficits($pims);
	listToBuys($parent,@list);
	showAddMinButton($of); # add a minimum for items not yet in DB for keeping on hand.
}
sub showPriceEntry { # For showing a price history and analysis
}
sub showStoreEntry {
}

sub populateMainWin {
	my ($dbh,$win,$reset) = @_;
	my $of = $win->Frame(-relief=>"raised");
	$win->{rtpan} = $of;
	$of->grid(-row=>1,-column=>2,-columnspan=>4,-sticky=>"nse");
	unless (FlexSQL::table_exists($dbh,"items") && FlexSQL::table_exists($dbh,"stores")) {
		print "-=-";
		FlexSQL::makeTables($dbh);
	}
	Sui::storeData('db',$dbh);
	showButtonPanel($win);
	showPantryLoader($win);
}
print ".";

print ".";
1;
