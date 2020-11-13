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

### Create a label and an entry in a row, then return the entry
sub entryRow {
	my ($parent,$name,$r,$c,$s,$tv,$valcmd) = @_;
#print "Debug: $parent ... " . ref($parent) . " ...\n";
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

### Create a label for each item in a list, put each label in the same row,
#	and return the first label in the list
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

### Destroy each child of a given frame
sub emptyFrame {
	my $frame = shift;
	my @kids = $frame->children;
	foreach my $c (@kids) {
		$c->destroy();
	}
}

### Refresh or populate a frame with its heading and an inner frame, then return the inner frame
sub makeMyFrame {
	my ($of,$heading) = @_;
	emptyFrame($of);
	my $header = $of->Label(-text => "$heading")->grid(-row => 1, -column => 1);
	my %args = %{ Sui::passData('frameargs') };
	my $if = $of->Frame(%args);
	$if->grid(-row=>3,-column=>1,-columnspan=>4, -sticky => 'nse');
	return $if;
}
print ".";

### Updates three fields from information hash
sub formatUPCinfo {
	my ($info,$ne,$se,$ge,$ce,$if) = @_; # hash, name, size, generic fields
	print join(',',keys %$info);
	print "We are given $info, $ne, $se, $ge, $ce...";
	#title weight size offers[title] description images
#####DONE?:	# try to regex size from title, both removing it and parsing it into the size field
	print "Name: $$info{title}\n";
	$$info{title} =~ s/,? ?(\d*\.?\d+) ?((fl\.? oz|fl\.?oz|foz|oz|lb|\#|ml|L))\.?//i;
	my $size = $1;
	my $uom = $2;
	(FIO::config('DB','unifyoz') || 1) && $uom =~ s/fl ?//i; # if not distinguishing between fl oz and oz
	print "New: $$info{title} / $size / $uom\n";
	TGK::updateEntry($ne,"$$info{title}") if exists $$info{title} and $$info{title} ne '';
	TGK::updateEntry($se,"$$info{weight}") if exists $$info{wieght} and $$info{wieght} ne '';
	if (exists $$info{size} and $$info{size} ne '') {
		TGK::updateEntry($se,"$$info{size}");
	} elsif (defined $1 and $1 ne '') {
		TGK::updateEntry($se,"$1");
	}
	print "Size: $$info{size}/$$info{weight}\n";
	my $generictext = $$info{title};
	$generictext =~ s/$$info{brand}:? //i;
	$generic = lc($generic) if (FIO::config('DB','lcgeneric') || 0);  # lowercase the generic?
	TGK::updateEntry($ge,"$generictext") if $generictext ne '';
	print "Equivalence: $generictext\n";
	$if->Label(-text => $$info{description}, -wraplength => 275)->grid(-row => 5, -column => 1, -columnspan => 6) if exists $$info{description} and $$info{description} ne '';
	print "Desc: $$info{description}\n";
}
print ".";

### Display the entry form
sub showPantryLoader {
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	my $upc = "";
	my $name = "";
	my $size = 0;
	my $unit = "oz";
	selectButton($parent,"Store");
	my $if = makeMyFrame($of,"Enter new pantry contents");
	my $ue = entryRow($of,"UPC: ",2,1);
	our $speedy = 0; $of->Checkbutton( -text => "Fast Entry", -variable => \$speedy, -command => sub { print "\nPressed: $speedy\n"; })->grid(-row => 2, -column => 3);
	sub saveItemInfo {
		my ($but,$dbh,$upc,$name,$size,$uom,$qty,$generic,$keep,$hr,$tf) = @_;
#		$but->configure(-state => 'disabled');
		if ($name eq "UNNAMED") { print "Product needs name!\n"; return unless $speedy; }
		if ($generic eq "Grocery") { print "Product needs equivalence!\n"; return unless $speedy; }
#		print "N: $name, S: $size, U: $uom, C: $upc... Q: $qty, G: $generic, K: $keep...\n";
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
			$st = "UPDATE counts SET qty=? WHERE upc=?;";
			$err = FlexSQL::doQuery(2,$dbh,$st,$qty,$upc);
			print "Records changed: $err\n";
			return unless ($err);
			my $lq = $tf->Label(-text=>"Quantity updated!");
			$lq->grid(-row=>10,-column=>1);
		}
		$tf->focusPrev();
	}

	# bind enter here to a function that either adds one to the onhand,
	#	or if not found, pulls open the description entries below for saving.
	sub incrementUPC {
		my ($ue,$if) = @_;
		my ($newkeep,$defname,$defgen) = (0,"UNNAMED","Grocery");
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
			$row = FlexSQL::doQuery(6,$dbh,$st,$ut);
		}
		if ($speedy) {
			$ue->delete(0, 'end'); # clear the UPC box if we're going fast.
			emptyFrame($if); # clear the inner frame of old info fields
			$if->Label(-text => "$ut incremented.")->grid(-row => 7, -column => 1); # assure user we did something else
		}
		my $UPConButton = (FIO::config('UI','buttonUPC') || 1);
		$UPConButton || $if->Label( -text => "Working UPC: $ut")->grid(-row => 6, -column => 1, -columnspan => 2);
		my $qty = (defined $$row{qty} ? $$row{qty} : 1);
		$st = "SELECT * FROM items WHERE upc=?;";
		$row = FlexSQL::doQuery(6,$dbh,$st,$ut);
		skrDebug::dump($row);
		$$row{update} = (defined $row ? 1 : 0);
		$$row{name} = "$defname" unless defined $$row{name};
		$$row{qty} = $qty;
		my ($nv,$sv,$uv,$gv,$kv) = (undef,1,"oz","$defgen",0);
		$sv = $$row{size} if defined $$row{size};
		$uv = $$row{unit} if defined $$row{unit};
		$gv = $$row{generic} if defined $$row{generic};
		if (defined $$row{keep} and $$row{keep} ne $kv) { $newkeep = 1; }
		$kv = $$row{keep} if defined $$row{keep};
		our $okb = $if->Button(-text=> ($UPConButton ? "Save $ut" : "Save"), -state => 'disabled',)->grid(-row=>6,-column=>5);
		our $ne = entryRow($if,"Name: ",1,1,undef,\$nv,\&myValidate);
		our $qe = $if->Entry(-textvariable=>\$qty,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, );
		our $ke = $if->Entry(-textvariable=>\$kv,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, );
		our $se = entryRow($if,"Size: ",2,1,undef,\$sv,\&myValidate);
		our $ce = $if->BrowseEntry(-width=>5,-variable=>\$uv,-validate=>'focusout',-validatecommand =>\&myValidate);
		our $ge = entryRow($if,"Item Equivalence: ",4,1,undef,\$gv,\&myValidate);
		$okb->configure(-command=> sub {
			$ne->focus if ($nv eq "$defname");
			$ge->focus if ($gv eq "$defgen");
			return if ($nv eq "$defname" or $gv eq "$defgen");
			$ue->delete(0, 'end');
			$newkeep and Sui::storeData('minchanged',time());
			saveItemInfo($okb,$dbh,$ut,$nv,$sv,$uv,$qty,$gv,$kv,$row,$if);
			$ue->focus();
		});
		our $ufb = UPC::makeUPCbutton($if,6,4,\$ut,\&formatInfo,"Populate");
		sub myValidate {
			my ($pv,$av,$cv) = @_;
			return 0 if ($pv eq $cv); # no change made
			$okb->configure( -state=> 'active' ) if (defined $okb);
			return 1
		}
		$ne->delete(0,'end');
		$ne->insert(0,$$row{name});
		our $ql = $if->Label(-text=>"Qty: ");
		$if->Label(-text=>"/")->grid(-row=>1,-column=>5);
		sub formatInfo { return formatUPCinfo($_[0],$ne,$se,$ge,$ce,$if); }
		$ce->insert('end','oz');
		$ce->insert('end','ml');
		$ce->insert('end','cnt');
		$ce->insert('end','in');
		# if large measures:
		$ce->insert('end','ft');
		$ce->insert('end','lb');
		$ce->insert('end','L');
		$ce->grid(-row=>2,-column=>3);
		$ql->grid(-row=>1,-column=>3);
		$qe->grid(-row=>1,-column=>4);
		$ke->grid(-row=>1,-column=>6);
		my $changed = 0;
		$ne->focus();
	}
	$ue->bind('<Key-Return>', sub { incrementUPC($ue,$if); });
	$ue->focus;
}
print ".";

### SCreate buttons for sidebar that lead to each function
sub showButtonPanel {
	my ($parent,$dbh) = @_;
	my $bf = $parent->Frame(-relief=>'groove', -width => 10);
	$bf->Label(-text=>"Tasks:",-width=>7)->pack();
	my %butpro = ( -fill=>'x', -padx=>2, -pady=>2);
	my $loadb = $bf->Button(-text=>"Store",-command=>sub { showPantryLoader($parent); })->pack(%butpro);
	my $editb = $bf->Button(-text=>"Edit",-command=>sub { showItemDB($parent); })->pack(%butpro);
	my $prodb = $bf->Button(-text=>"Price",-command=>sub { showProductInfo($parent); })->pack(%butpro);
	my $planb = $bf->Button(-text=>"Plan",-command=>sub { showRecipeProposal($parent); })->pack(%butpro);
	my $listb = $bf->Button(-text=>"Buy",-command=>sub { showShoppingList($parent); })->pack(%butpro);
	my $contb = $bf->Button(-text=>"Cook",-command=>sub { showPantryContents($parent); })->pack(%butpro);
	Sui::storeData('bnames',["Cook","Edit","Buy","Store","Plan","Price"]);
	Sui::storeData('bgroup',[$contb,$editb,$listb,$loadb,$planb,$prodb]);
	$bf->grid(-row=>1,-column=>1,-sticky=>"nw");
}
print ".";

sub selectButton { # TODO: Figure out why this doesn't work, and fix it.
	my ($parent,$active) = @_;
	#print "sB $active ...";
	my @bnames = @{ Sui::passData('bnames') };
	my @bgroup = @{ Sui::passData('bgroup') };
	foreach my $i (0..$#bnames) {
		if ($active eq $bnames[$i]) {
			Common::infMes("Selecting $active!") if (main::howVerbose() > 5);
			$bgroup[$i]->configure(-state => 'disabled');
		} else {
			print "Enabling $bnames[$i]!\n" if ($bgroup[i]->configure(-state) eq "disabled");
			$bgroup[$i]->configure(-state => 'normal');
		}
	}
}
print ".";

sub setQty {
	my ($upc,$qty) = @_;
	return -1 if ($qty < 0); # prevent negative onhands
	my $st = "UPDATE counts SET qty=? WHERE upc=?;";
	my $err = FlexSQL::doQuery(2, Sui::passData('db') ,$st, $qty, $upc);
	print "Err: $err\n";
	return $err;
}
print ".";

sub showPantryContents { # For cooking/reducing inventory
	my ($parent,) = @_;
	selectButton($parent,"Cook");
	my $pxwidth = (FIO::config('UI','maxcolw') or 100);
	my $of = $parent->{rtpan};
	my $if = makeMyFrame($of,"Contents of Pantry");
	my %args = %{ Sui::passData('frameargs') };
	$args{-width} *= 0.95;
	my $sf = $if->Scrolled('Frame', -scrollbars => 'osoe', %args)->pack(-fill => 'both',);
	$sf->Label(-text => " ", -width => 80, -height => 2)->grid(-row => 2, -column => 1, -columnspan => 7);
	my $st = "SELECT * FROM items ORDER BY generic ASC;";
	my $qst = "SELECT qty FROM counts WHERE upc=?;";
	my $dbh = Sui::passData('db');
	my $tah = { -justify => 'left', -wraplength => $pxwidth };
	my $res = FlexSQL::doQuery(3,$dbh,$st,'upc'); # Get items in pantry
	my @order = sort {$$res{$a}{generic} cmp $$res{$b}{generic}} keys %$res;
	my $showitem = (Sui::passData('showcookgeneric') or 0);
	listRow($sf,"Qty",3,1,$tah,($showitem ? "Item" : ""),"Product","UPC");
	$sf->Label(-text => "Change")->grid(-row => 3, -column => 6, -columnspan => 2);
	my $row = 4;
	foreach my $i (@order) {
		my $qty = @{ FlexSQL::doQuery(7,$dbh,$qst,$$res{$i}{upc}) }[0];
		my $q = listRow($sf,"$qty/$$res{$i}{keep}",$row,1,$tah,($showitem ? "$$res{$i}{generic}" : ""),"$$res{$i}{name}","$$res{$i}{upc}");
		my $usebutton = $sf->Button(-text => "-1",-command => sub { $qty--; setQty($$res{$i}{upc},$qty); $q->configure(-text => "$qty/$$res{$i}{keep}"); }, -padx => 3)->grid(-row => $row, -column => 6);
		my $undobutton = $sf->Button(-text => "+1",-command => sub { $qty++; setQty($$res{$i}{upc},$qty); $q->configure(-text => "$qty/$$res{$i}{keep}"); }, -padx => 3)->grid(-row => $row, -column => 7);
		$row++;
	}
}
sub showProductEntry { # For adding a new product entry
}
sub showProductInfo { # for pricing products in the store
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	emptyFrame($of);
	selectButton($parent,"Price");
	my $if = makeMyFrame($of,"Pricing Tool");
	my ($r,$c) = (1,1);
	my %args = ( -row => $r, -column => $c );
	unless (defined $parent) {
		print Common::lineNo();
	}
	my $si = (Sui::passData('storeID') or 1);
	my ($uv,$pv);
	our ($dv,$okb);
	$if->Label(-text=>"Store: ")->grid( -row => 2, -column => 1 );
	our $de = $if->Entry(-textvariable => \$dv)->grid(-row => 2, -column => 5);
	my $sn = $if->Label(-text=>"Unnamed Store")->grid( -row => 2, -column => 3);
	my $pnl = $if->Label(-text => "Unknown Product")->grid(-row => 3,-column => 3, -columnspan => 2);
	my $psw = $if->Scrolled('Frame', -scrollbars => 'ose', -height => 300)->grid(-sticky => 'ew', -row => 4, -column => 1, -columnspan => 5);
	my $ptable = $psw->Frame()->pack(-fill => 'both');
	my $se = $if->Entry(-textvariable=> \$si)->grid( -row => 2, -column => 2 );
	$dv = Common::datenow();
	$sn->configure(-text => getStore($si));
	# text, characters changed, previous text, position, operation
	$se->configure(-validate => 'all', -validatecommand => sub {
		my ($nt,$ct,$ot,$pos,$op) = @_;
		return 0 if($nt eq $ot);
		my $nam = getStoreNames($nt);
		$sn->configure(-text => $nam);
		return 1; });
	$sb = $if->Button(-text => "Change/Add", -command => sub { showStoreEntry($if,$se); } )->grid( -row => 2, -column => 4); # show a button to change/add the store
	$ue = entryRow($if,"UPC:",3,1,undef,\$uv,sub { getProdData($ptable,$pnl,$ue->get()); }); # show a UPC entry
	my $pe = entryRow($if,"Price:",10,1,2,\$pv,\&allowSave);
	$okb = $if->Button(-text=> "Save Price", -state => 'disabled', -command=> sub {
		savePriceInfo($okb,$dbh,$ptable,$se->get(),$uv,$dv,$pv,$ue);
		$ue->delete(0, 'end');
		$ue->focus();
		Sui::storeData('storeID',$si);
		$dv = Common::datenow();
	})->grid( -row => 10, -column => 5);
	$ue->configure(-validate => 'focusout');
	$pe->configure(-validate => 'all');
	$ue->bind('<Key-Return>', sub { getProdData($ptable,$pnl,$uv); }); # bind return on entry to a function that adds a table of price information and an entry where you can enter the price
	# bind return on the price field to the price update function
	sub getProdData {
		my ($target,$pl,$cv) = @_;
#		print "$pv/$av/$cv]";
#		return 0 if ($pv eq $cv); # no change made
		$pl->configure(-text => getProdName($cv)) if (defined $cv and $cv ne "");
		emptyFrame($target);
		$r = 1; $c = 1;
		my $st = "SELECT store,price,date FROM prices WHERE upc=? ORDER BY date DESC LIMIT 25;";
		my $list = FlexSQL::doQuery(4,FlexSQL::getDB(),$st,$cv);
		$target->Label(-text => "Store")->grid(-row => $r, -column => 1);
		$target->Label(-text => "Price")->grid(-row => $r, -column => 2);
		$target->Label(-text => "Date")->grid(-row => $r, -column => 3);
		$target->Label(-text => "")->grid(-row => $r, -column => 4);
		foreach my $listrow (reverse @$list) {
			makePriceRow($target,@$listrow);
		}
	}
	sub makePriceRow {
		my ($t,$a,$b,$c) = @_;
		unless (defined $t) {
			print Common::lineNo(1);
		}
		$r++;
		my $rl1 = $t->Label(-text => getStore($a) . "   ")->grid(-row => $r, -column => 1);
		my $rl2 = $t->Label(-text => "   $b   ")->grid(-row => $r, -column => 2);
		my $rl3 = $t->Label(-text => "   $c")->grid(-row => $r, -column => 3);
		my $rb;
		$rb = $t->Button(-text => "-", -command => sub {
			my $st = "DELETE FROM prices WHERE date=?;"; # set query
			FlexSQL::doQuery(2,FlexSQL::getDB(),$st,$c); # delete price
			$rl1->destroy(); # clear the line from the list.
			$rl2->destroy();
			$rl3->destroy();
			print "B: " . join(',',@_);
			$rb->destroy(); # remove this button.
		} )->grid(-row => $r, -column => 5);
	}
	sub allowSave {
		my ($pv,$av,$cv) = @_;
#		print "$pv/$cv>";
		return 0 if ($pv eq $cv); # no change made
		$okb->configure( -state=> 'active' ) if (defined $okb);
		return 1
	}
	sub savePriceInfo {
		my ($but,$dbh,$target,$si,$uv,$dv,$pv,$ue) = @_;
print "sPI(" . join(',',@_) . ")\n";
		$pv =~ /^(\d+.?\d*)$/;
		unless (defined $1) {
			$but->configure(-state => 'disabled');
			return;
		}
		my $ist = "INSERT INTO prices(upc,store,price,date) VALUES(?,?,?,?);";
		(defined $dbh or $dbh = FlexSQL::getDB());
		FlexSQL::doQuery(2,$dbh,$ist,$uv,$si,$pv,$dv);
		makePriceRow($target,$si,$pv,$dv);
		$but->configure(-state => 'disabled');
		$ue->focus();
	}
	showAddMinButton($of,0); # Make the item being priced an item user wants to keep on hand.
	$ue->focus();
}

sub getStore {
	my ($id,$dbh) = @_;
	(defined $dbh or $dbh = FlexSQL::getDB());
#	my $st = "SELECT name FROM stores WHERE store=?;";
#	my $sn = FlexSQL::doQuery(7,$dbh,$st,$id);
#	return ($$sn[0] or "Unknown Store");
	my $names = getStoreNames($dbh);
	return ($$names{$id} or "Unknown Store");
}
print ".";

sub getStoreNames {
	my $namelist = Sui::passData('storenames');
	my ($dbh,$force) = @_;
	return $namelist if (not $force and defined $namelist and scalar (keys %{ $namelist}));
	(defined $dbh or $dbh = FlexSQL::getDB());
	my $st = "SELECT store,name FROM stores;";
	my $namehash = FlexSQL::doQuery(3,$dbh,$st,'store');
	foreach my $i (keys %$namehash) { # query returns a nested hash that's not very accessible
		$$namelist{$i} = $$namehash{$i}{'name'};
	}
	Sui::storeData('storenames',$namelist);
	return $namelist;
}
print ".";

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
	my @generics = sort keys %$kvs;
	my @lows;
	my $pst = "SELECT upc,name FROM items WHERE generic=? ORDER BY name;";
	my $cst = "SELECT qty FROM counts WHERE upc=?;";
	my $dbh = Sui::passData('db');
	my $wiggle = (FIO::config('Rules','beloworat') ? 1 : 0);
	foreach my $k (@generics) { # get list of lows/outs
		next if ($k eq "Auto"); # Don't display Auto-generated generic category
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

#skrDebug::dump($i,"List");
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
	selectButton($parent,"Buy");
	my $header = $of->Label(-text => "Shopping List")->grid(-row => 1, -column => 2);
	my @list = getDeficits(getMinimums());
	my $if = $of->Frame()->grid(-row => 1, -column => 1, -columnspan => 7);
	$args{-width} *= 0.95;
	my $sf = $if->Scrolled('Frame', -scrollbars => 'osoe', %args)->pack(-fill => 'both',);
	listToBuys($sf,@list);
	showAddMinButton($of,3); # add a minimum for items not yet in DB for keeping on hand.
}
sub showPriceEntry { # For showing a price history and analysis
	my ($parent,) = @_;
	my %args = %{ Sui::passData('frameargs') };
	my $of = $parent->{rtpan};
	emptyFrame($of);
	my $header = $of->Label(-text => "Price List")->grid(-row => 1, -column => 2);
}
sub showStoreEntry {
	my ($parent,$entry) = @_;
	my ($nv,$lv);
	print "Store select: " . @_ . "\n";
	sub setEntry {
		my ($box,$ent,$val) = @_;
		$ent->configure(-text=>$val) if (defined $ent and defined $val);
		$box->destroy();
		return;
	}
	my $if = $parent->Scrolled('Frame', -scrollbars => 'osoe')->grid(-sticky => 'we', -row => 1, -column => 1, -columnspan => 10);
	my $dbh = FlexSQL::getDB();
	my $ne = entryRow($if,"Name:",1,1,undef,\$nv,);
	my $le = entryRow($if,"Address:",2,1,undef,\$lv,);
	my $nb = $if->Button(-text => "Add New", -command => sub {
		my $sid = 0;
		return unless (defined $nv and defined $lv); # skip processing of incomplete data.
		FlexSQL::doQuery(2,$dbh,"DELETE FROM stores WHERE name='DELETE';");
		my $cst = "INSERT INTO stores(name,loc) VALUES(?,?);";
		if (FlexSQL::doQuery(2,$dbh,$cst,"DELETE",$lv)) {
			$cst = "SELECT store FROM stores WHERE name=?;";
			$sid = FlexSQL::doQuery(7,$dbh,$cst,"DELETE"); $sid = $$sid[0];
			$cst = "UPDATE stores SET name=? WHERE store=?;";
			FlexSQL::doQuery(2,$dbh,$cst,$nv,$sid);
			getStoreNames(FlexSQL::getDB(),1);
		}
		print "ID: $sid\n";
		setEntry($if,$entry,$sid) if ($sid);
		})->grid(-row => 2,-column => 4);
	my $st = "SELECT store,name FROM stores WHERE name IS NOT NULL AND name != 'DELETE';";
	my @sids = @{ FlexSQL::doQuery(4,$dbh,$st); };
	my $row = 3;
	foreach my $r (@sids) {
		my ($id,$name) = @$r;
		$if->Button(-text => "$name", -command => sub { setEntry($if,$entry,$id); })->grid(-row => $row, -column => 2);
		$row++;
	}
	$if->Button(-text => "Cancel", -command => sub { setEntry($if); })->grid(-row => $row, -column => 3);
}

sub populateMainWin {
	my ($dbh,$win,$reset) = @_;
	my $frameargs = {-width => 600, -height => 440};
	if ($reset) {
		exists $win->{rtpan} and $win->{rtpan}->destroy();
	} else {
		my $w = $win->width * 0.9;
		my $h = $win->height * 0.9;
		Sui::storeData('frameargs',$frameargs);
		unless (FlexSQL::table_exists($dbh,"items") && FlexSQL::table_exists($dbh,"stores")) {
			print "-=-";
			FlexSQL::makeTables($dbh);
		}
		Sui::storeData('db',$dbh);
	}
	my $of = $win->Frame(-relief=>"raised", %$frameargs);
#	$of->configure(-scrollbars => 'e');
	$win->{rtpan} = $of;
	$of->grid(-row=>1,-column=>2,-columnspan=>7,-sticky=>"nse");
	showButtonPanel($win,$dbh);
	showPantryLoader($win);
}
print ".";

sub showItemDB {
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	my $upc = "";
	my $name = "";
	my $size = 0;
	my $unit = "oz";
	selectButton($parent,"Edit");
	my $if = makeMyFrame($of,"Edit item information");
	my $ue = entryRow($of,"UPC: ",2,1);
	$of->Button( -text => "Fetch Info", -command => sub { print "\nWhen this is coded, it'll try to pull item info from a UPC database. For now, enjoy the pretty status button.\n"; $if->Button(-text => "Not yet coded")->pack(-anchor => 'w'); })->grid(-row => 2, -column => 3);
	# get list of items that are UNNAMED and Grocery
	# count items and create a progress bar (fetching from the API is a bit slow) and a status label
	# for each item: {
		# update the status label with "Attempting to fetch UPC $upc"
		# fetch UPC
		# Update the status label with "Attempting to fetch UPC $upc... processing response..."
		# process response
		# Update the status label with "Attempting to fetch UPC $upc... processing response... saving..."
		# save results to DB using "Auto $generic" as the generic !!! even if fetch or processing failed.
			#We don't want to keep trying to fetch this item if it's not in the DB.
			#That just wastes queries, which are capped!!
		# update the progress bar
		# go to next unnamed item
	#}
	$of->Button( -text => "Review Autodata", -command => sub { print "\nWhen this is coded, it'll try to pull item info from a UPC database. For now, enjoy the pretty status button.\n"; $if->Button(-text => "Not yet coded")->pack(-anchor => 'w'); })->grid(-row => 2, -column => 4);
	# grab autodata generic LIKE "Auto%"
	# create an inner frame with a scrollbar
	# create a header row
	# for each item: {
		# create a row
		# put the autogenerated info on the row in entry fields, lined up with headers
			# for the generic field, grab the value removing the "Auto " prepension.
		# put an edit button by each row
			# clicking button opens a new window with an item editor and destroys the row (but not the data that was used to generate it, in case of error)
		# put a save button by each row
			# clicking the button destroys the row and saves the data
	sub saveItemInfo {
		my ($but,$dbh,$upc,$name,$size,$uom,$qty,$generic,$keep,$hr,$tf) = @_;
#		$but->configure(-state => 'disabled');
		if ($name eq "UNNAMED") { print "Product needs name!\n"; return; }
		if ($generic eq "Grocery") { print "Product needs equivalence!\n"; return; }
		print "N: $name, S: $size, U: $uom, C: $upc... Q: $qty, G: $generic, K: $keep...\n";
		my $st;
		skrDebug::dump($hr,"Item info");
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
			$st = "UPDATE counts SET qty=? WHERE upc=?;";
			$err = FlexSQL::doQuery(2,$dbh,$st,$qty,$upc);
			print "Records changed: $err\n";
			return unless ($err);
			my $lq = $tf->Label(-text=>"Quantity updated!");
			$lq->grid(-row=>1,-column=>1);
		}
		$tf->focusPrev();
	}

	sub editUPC {
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
		my $UPConButton = (FIO::config('UI','buttonUPC') || 1);
		$UPConButton || $if->Label( -text => "Working UPC: $ut")->grid(-row => 6, -column => 1, -columnspan => 2);
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
		our $okb = $if->Button(-text=> ($UPConButton ? "Save $ut" : "Save"), -state => 'disabled',)->grid(-row=>6,-column=>5);
		our $ne = entryRow($if,"Name: ",1,1,undef,\$nv,\&myValidate);
		our $qe = $if->Entry(-textvariable=>\$qty,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, );
		our $ke = $if->Entry(-textvariable=>\$kv,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, );
		our $se = entryRow($if,"Size: ",2,1,undef,\$sv,\&myValidate);
		our $ce = $if->BrowseEntry(-width=>5,-variable=>\$uv,-validate=>'focusout',-validatecommand =>\&myValidate);
		our $ge = entryRow($if,"Item Equivalence: ",4,1,undef,\$gv,\&myValidate);
		$okb->configure(-command=> sub {
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
		$ne->delete(0,'end');
		$ne->insert(0,$$row{name});
		sub formatInfo { return formatUPCinfo($_[0],$ne,$se,$ge,$ce,$if); }
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
		$qe->grid(-row=>1,-column=>4);
		$ke->grid(-row=>1,-column=>6);
		our $ufb = UPC::makeUPCbutton($if,6,4,\$ut,\&formatInfo,"Populate");
		$ne->focus();
	}
	# bind enter here to a function that either adds one to the onhand,
	#	or if not found, pulls open the description entries below for saving.
	$ue->bind('<Key-Return>', sub { editUPC($ue); });
	$ue->focus;
}
print ".";

sub showRecipeProposal {
	my ($parent,) = @_;
	my %args = %{ Sui::passData('frameargs') };
	my $of = $parent->{rtpan};
	emptyFrame($of);
	selectButton($parent,"Plan");
	my $header = $of->Label(-text => "Recipe Worksheet")->grid(-row => 1, -column => 2);
	our $rframe = $of->Scrolled('Frame',-scrollbars=>'osoe')->grid(-row => 2,-column => 1,-columnspan => 5);
	our (@rows,@costs);
	my $buttonrow = $of->Frame()->grid(-row => 3,-column => 1,-columnspan => 5);
	my $costl = $buttonrow->Label(-text => "Cost:")->grid(-row=>1,-column=>1);
	my $costo = $buttonrow->Label(-text => "\$0.00")->grid(-row=>1,-column=>2);
	my $rowindex = 0;
	my $addbutton = $buttonrow->Button(-text=>"Add Ingredient",-command=>sub { print "TODO: code these (add)"; })->grid(-row=>1,-column=>3);
	my $buybutton = $buttonrow->Button(-text=>"Buy Ingredients",-command=>sub { print "TODO: code these (buy)"; })->grid(-row=>1,-column=>4);
	my $recsavbut = $buttonrow->Button(-text=>"Save",-command=>sub { print "TODO: code these (save)"; })->grid(-row=>1,-column=>5);

	sub makeIngredient {
		my ($upc,$t,$r) = @_;
		push(@rows,$t->Frame()->pack(-fill=>"x"));
		push(@costs,0.00);
		$rows[$r]->Label(-text=>"$data[0]")->grid(-row=>1,-column=>1); # Name
		$rows[$r]->Entry(-text=>"0")->grid(-row=>1,-column=>2); # Qty
		$rows[$r]->Label(-text=>"$data[1]")->grid(-row=>1,-column=>3); # Units
		$rows[$r]->Label(-text=>"$data[2]")->grid(-row=>1,-column=>4); # Cost
		$rows[$r]->Button(-text=>" - ", -command => sub { $costs[$r] = 0.00; $rows[$r]->destroy(); })->grid(-row=>1,-column=>5); # Remove
	}

}
print ".";


sub getProdName {
	my ($ut,$dbh) = @_;
	$st = "SELECT name FROM items WHERE upc=?;";
	(defined $dbh or $dbh = FlexSQL::getDB());
	$row = FlexSQL::doQuery(6,$dbh,$st,$ut);
	skrDebug::dump($row);
	return "unknown" unless (defined $row);
	$$row{name} = "unknown" unless defined $$row{name};
	return $$row{name};
}
print ".";

print ".";
1;
