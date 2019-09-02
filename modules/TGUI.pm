package TGUI;
print __PACKAGE__;

use Panini qw(Prod );
require Tk::BrowseEntry;
require Tk::Pane;


sub Tdie {
# attempt to save config here?
	print @_;
	exit(0);
}
print ".";

sub entryRow {
	my ($parent,$name,$r,$c,$s,$tv,$valcmd) = @_;
print "Debug: $parent ... " . ref($parent) . " ...\n";
	my %args = ( -row => $r, -column => $c );
	unless (defined $parent) {
		print Common::lineNo();
	}
	my $lab = $parent->Label(-text=>"$name")->grid(%args);
	$args{-columnspan} = $s if defined $s;
	$args{-column}++;
	my $ent = $parent->Entry()->grid(%args);
	$ent->configure(-textvariable=> $tv) if (defined $tv and ref($tv) eq "SCALAR");
	$ent->configure(-validate => 'focusout', -validatecommand => $valcmd) if (defined $valcmd and ref($valcmd) eq "CODE");
	return $ent;
}
print ".";

sub listRow {
	my ($parent,$name,$r,$c,$tah,@list) = @_;
	my %args = ( -row => $r, -column => $c );
	my $lab = $parent->Label(-text=>"$name", %$tah)->grid(%args);
	foreach my $i (@list) {
		$args{-column}++;
		$parent->Label(-text=>"$i", %$tah)->grid(%args);
	}
	return $lab;
}

sub emptyFrame {
	my $frame = shift;
	my @kids = $frame->children;
	foreach my $c (@kids) {
		$c->destroy();
	}
}

sub makeMyFrame {
	my ($of,$heading) = @_;
	emptyFrame($of);
	my $header = $of->Label(-text => "$heading")->grid(-row => 1, -column => 1);
	my %args = %{ Sui::passData('frameargs') };
	my $if = $of->Frame(%args);
	$if->grid(-row=>3,-column=>1,-columnspan=>4);
	return $if;
}

sub showPantryLoader {
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	my $upc = "";
	my $name = "";
	my $size = 0;
	my $unit = "oz";
	my $if = makeMyFrame($of,"Enter new pantry contents");
	my $ue = entryRow($of,"UPC: ",2,1);
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
		my $ue = shift;
		my $newkeep = 0;
		my $ut = $ue->get();
		if ($ut eq "" or not defined $ue) {
			print "Empty UPC!\n";
			return;
		}
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
		if (defined $row) { # get updated qty, because we just changed it.
			my $st = "SELECT * FROM counts WHERE upc=?;";
			my $row = FlexSQL::doQuery(6,$dbh,$st,$ut);
		}
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
		if (defined $$row{keep} and $$row{keep} ne $kv) { $newkeep = 1; }
		$kv = $$row{keep} if defined $$row{keep};
		our $okb;
		our $ne = entryRow($if,"Name: ",1,1,undef,\$nv,\&myValidate);
		our $ge = entryRow($if,"Item Equivalence: ",4,1,undef,\$gv,\&myValidate);
		$okb = $if->Button(-text=>"Save", -state => 'disabled', -command=> sub {
			$ne->focus if ($nv eq "UNNAMED");
			$ge->focus if ($gv eq "Grocery");
			$ue->delete(0, 'end');
			$newkeep and Sui::storeData('minchanged',time());
			saveItemInfo($okb,$dbh,$ut,$nv,$sv,$uv,$qty,$gv,$kv,$row,$if);
			$ue->focus();
		});
		sub myValidate {
			my ($pv,$av,$cv) = @_;
			return 0 if ($pv eq $cv); # no change made
			$okb->configure( -state=> 'active' ) if (defined $okb);
			return 1
		}
		sub formatUPCinfo {
			my ($info) = @_;
			print join(',',keys %$info);
			#title weight size offers[title] description images
			TGK::updateEntry($ne,"$$info{title}") if exists $$info{title} and $$info{title} ne '';
			print "Name: $$info{title}\n";
			TGK::updateEntry($se,"$$info{size}") if exists $$info{size} and $$info{size} ne '';
			TGK::updateEntry($se,"$$info{weight}") if exists $$info{wieght} and $$info{wieght} ne '';
			print "Size: $$info{size}/$$info{weight}\n";
			my $generictext = $$info{title};
			$generictext =~ s/$$info{brand} //i;
			TGK::updateEntry($ge,"$generictext") if $generictext ne '';
			print "Equivalence: $generictext\n";
			$if->Label(-text => $$info{description}, -wraplength => 275)->grid(-row => 5, -column => 1, -columnspan => 6) if exists $$info{description} and $$info{description} ne '';
			print "Desc: $$info{description}\n";
		}
		$ne->delete(0,'end');
		$ne->insert(0,$$row{name});
		our $se = entryRow($if,"Size: ",2,1,undef,\$sv,\&myValidate);
		our $ce = $if->BrowseEntry(-width=>5,-variable=>\$uv,-validate=>'focusout',-validatecommand =>\&myValidate);
		$ce->insert('end','oz');
		$ce->insert('end','ml');
		$ce->insert('end','cnt');
		$ce->insert('end','in');
		# if large measures:
		$ce->insert('end','ft');
		$ce->insert('end','lb');
		$ce->insert('end','L');
		$ce->grid(-row=>2,-column=>3);
		our $ql = $if->Label(-text=>"Qty: ");
		$ql->grid(-row=>1,-column=>3);
		$if->Label(-text=>"/")->grid(-row=>1,-column=>5);
		my $changed = 0;
		our $qe = $if->Entry(-textvariable=>\$qty,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, );
		our $ke = $if->Entry(-textvariable=>\$kv,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, );
		$qe->grid(-row=>1,-column=>4);
		$ke->grid(-row=>1,-column=>6);
		$okb->grid(-row=>6,-column=>5);
		our $ufb = UPC::makeUPCbutton($if,6,4,\$ut,\&formatUPCinfo,"Populate");
	}
	$ue->bind('<Key-Return>', sub { incrementUPC($ue); });
	$ue->focus;
}
print ".";

sub showButtonPanel {
	my ($parent,) = @_;
	my $bf = $parent->Frame(-relief=>'groove', -width => 10);
	$bf->Label(-text=>"Tasks:",-width=>7)->pack();
	my %butpro = ( -fill=>'x', -padx=>2, -pady=>2);
#	my $loadb = $bf->Button(-text=>"Store",-command=>sub { showPantryLoader($parent); })->pack(%butpro); # disabled until I can figure out why it fails after loading with button
	my $contb = $bf->Button(-text=>"Cook",-command=>sub { showPantryContents($parent); })->pack(%butpro);
	my $listb = $bf->Button(-text=>"Buy",-command=>sub { showShoppingList($parent); })->pack(%butpro);
	my $prodb = $bf->Button(-text=>"Price",-command=>sub { showProductInfo($parent); })->pack(%butpro);
	
	
	$bf->grid(-row=>1,-column=>1,-sticky=>"nws");
}
print ".";

sub setQty {
	my ($upc,$qty) = @_;
	my $st = "UPDATE counts SET qty=? WHERE upc=?;";
	my $dbh = Sui::passData('db');
	return -1 if ($qty < 0); # prevent negative onhands
	my $err = FlexSQL::doQuery(2,$dbh,$st,$qty,$upc);
	print "Err: $err\n";
	return $err;
}
print ".";

sub showPantryContents { # For cooking/reducing inventory
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	my $if = makeMyFrame($of,"Contents of Pantry");
	my %args = %{ Sui::passData('frameargs') };
	$args{-width} *= 0.9;
	my $sf = $if->Scrolled('Frame', -scrollbars => 'osoe', %args)->pack(-fill => 'both',);
	$sf->Label(-text => " ", -width => 80, -height => 2)->grid(-row => 2, -column => 1, -columnspan => 7);
	my $st = "SELECT * FROM items;";
	my $qst = "SELECT qty FROM counts WHERE upc=?;";
	my $dbh = Sui::passData('db');
	my $tah = { -justify => 'left', };
	my $res = FlexSQL::doQuery(3,$dbh,$st,'upc'); # Get items in pantry
	my @order = sort {$$res{$a}{generic} cmp $$res{$b}{generic}} keys %$res;
	listRow($sf,"Qty",3,1,$tah,"Of","Item","Product","UPC");
	my $row = 4;
	foreach my $i (@order) {
		my $qty = @{ FlexSQL::doQuery(7,$dbh,$qst,$$res{$i}{upc}) }[0];
		my $q = listRow($sf,$qty,$row,1,$tah,"$$res{$i}{keep}","$$res{$i}{generic}","$$res{$i}{name}","$$res{$i}{upc}");
		my $usebutton = $sf->Button(-text => "-1",-command => sub { $qty--; setQty($$res{$i}{upc},$qty); $q->configure(-text => "$qty"); }, -padx => 3)->grid(-row => $row, -column => 6);
		my $undobutton = $sf->Button(-text => "+1",-command => sub { $qty++; setQty($$res{$i}{upc},$qty); $q->configure(-text => "$qty"); }, -padx => 3)->grid(-row => $row, -column => 7);
		$row++;
	}
}
sub showProductEntry { # For adding a new product entry
}
sub showProductInfo { # for pricing products in the store
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	emptyFrame($of);
	my $if = makeMyFrame($of,"Pricing Tool");

	showAddMinButton($of,0); # Make the item being priced an item user wants to keep on hand.
}

sub getMinimums { # calculate the highest minimum of items in a category.
	# Allows you to set a minimum for "Tomatoes, Diced" on the name brand can and have it apply to the generic that has a keep of 0.
	my $minimums = Sui::passData('minimums');
	my $dbh = Sui::passData('db');
	unless (Sui::passData('minchanged') <= Sui::passData('minindexed')) { # only do this once unless a minimum has been chaged.
		Sui::storeData('minindexed',time()); # store new index time
		my $st = "SELECT generic, MAX(keep) FROM items GROUP BY generic;";
		$list = FlexSQL::doQuery(4,$dbh,$st); # pull data from DB here.
		foreach my $a (@$list) {
			my ($k,$v) = @$a;
			$$minimums{$k} = $v;
		}
		Sui::storeData('minimums',$minimums); # Store new minimums
	}
	return $minimums;
}
print ".";

sub getDeficits {
	my ($kvs,) = @_;
	my @generics = keys %$kvs;
	my @lows;
	my $pst = "SELECT upc,name FROM items WHERE generic=?;";
	my $cst = "SELECT qty FROM counts WHERE upc=?;";
	my $dbh = Sui::passData('db');
	my $wiggle = (FIO::config('Rules','beloworat') ? 1 : 0);
	foreach my $k (@generics) { # get list of lows/outs
		my $list = FlexSQL::doQuery(4,$dbh,$pst,$k); # Get items in this generic
		foreach my $i (@$list) {
			my ($upc,$name) = @$i;
			my $qty = FlexSQL::doQuery(7,$dbh,$cst,$upc);
			$qty = $$qty[0];
			if (($qty - $wiggle) < $$kvs{$k}) {
				push(@lows,[$k,$upc,$name,$qty,$$kvs{$k}]); # store info for use elsewhere
			}
		}
	}
	return @lows;
}
print ".";

sub showAddMinButton { # Adds a button to the list that allows adding a
	# minimum/upc, allowing user to add an item to the shopping list
	# and PITS without changing its onhand qty.
	# parent, grid (0 = pack)
}

sub listToBuys {
	my ($parent,@list) = @_;
	my $curhed = "";
	my $row = 2;
	$parent->Label(-text => "UPC")->grid(-row => $row, -column => 1);
	$parent->Label(-text => "Item")->grid(-row => $row, -column => 2);
	$parent->Label(-text => "OnHand")->grid(-row => $row, -column => 4);
	$parent->Label(-text => "Desired")->grid(-row => $row, -column => 5);
	$parent->Label(-text => "Buy")->grid(-row => $row, -column => 6);
	$row++;
	foreach my $i (@list) {
		my ($gen,$upc,$name,$qty,$desired) = @$i;
		unless ($gen eq $curhed) {
			$curhed = $gen;
			$parent->Label(-text => "$curhed:", -font => [-underline => 1])->grid(-row => $row,-column => 2);
			$parent->Label(-text => "$desired")->grid(-row => $row,-column => 5);
			$row++;
		}
		$parent->Label(-text => "$upc")->grid(-row => $row,-column => 1);
		$parent->Label(-text => "$name")->grid(-row => $row,-column => 3);
		$parent->Label(-text => "$qty")->grid(-row => $row,-column => 4);
		my $buy = $desired - $qty;
		$parent->Label(-text => "$buy")->grid(-row => $row,-column => 6);
		$parent->Checkbutton( -text => "")->grid(-row => $row, -column => 7); # just a user element for shopping convenience.
		$row++;
	}
}

sub showShoppingList { # For buying items that are getting low
	my ($parent,) = @_;
	my %args = %{ Sui::passData('frameargs') };
	my $of = $parent->{rtpan};
	emptyFrame($of);
	my $header = $of->Label(-text => "Shopping List")->grid(-row => 1, -column => 2);
	my @list = getDeficits(getMinimums());
	my $if = $of->Frame()->grid(-row => 1, -column => 1, -columnspan => 7);
	my $sf = $if->Scrolled('Frame', -scrollbars => 'osoe', %args)->pack(-fill => 'both',);
	listToBuys($sf,@list);
	showAddMinButton($of,3); # add a minimum for items not yet in DB for keeping on hand.
}
sub showPriceEntry { # For showing a price history and analysis
}
sub showStoreEntry {
}

sub populateMainWin {
	my ($dbh,$win,$reset) = @_;
	my $w = $win->width * 0.9;
	my $h = $win->height * 0.9;
	my $frameargs = {-width => 600, -height => 440};
	Sui::storeData('frameargs',$frameargs);
	my $of = $win->Frame(-relief=>"raised", %$frameargs);
#	$of->configure(-scrollbars => 'e');
	$win->{rtpan} = $of;
	$of->grid(-row=>1,-column=>2,-columnspan=>7,-sticky=>"nse");
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
