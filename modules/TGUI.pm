package TGUI;
print __PACKAGE__;

use Panini qw(Prod );
require Tk::BrowseEntry;
require Tk::Pane;


sub Tdie {
# TODO: attempt to save config here?
	print @_;
	exit(0);
}
print ".";

sub setBG { return TGK::setBG(@_); }
sub setFont { return TGK::setFont(@_); }
sub cfp { return TGK::cfp(@_); } # color/font/position
sub setBGF {
	my ($w,$c,$f) = @_;
	setBG($w,$c);
	$f = FIO::config('Font',($f or 'body'));
	setFont($w,$f,0);
	return $w;
}
print ".";

sub explain {
	my ($frame,$name) = @_;
	TGK::TFresh();
	$name = $frame unless defined $name;
	Common::dbgMes("Frame $name (" . $frame->width() . "x" . $frame->height() . ")") if (main::howVerbose() > 0 and Common::showDebug('g'));
}
print ".";

### Create a label and an entry in a row, then return the entry
sub entryRow { return entryGroup(@_,'h'); }
### Create a label and an entry in a column, then return the entry
sub entryStack { return entryGroup(@_,'v'); }

#print "Debug: $parent ... " . ref($parent) . " ...\n";
sub entryGroup {
	my ($parent,$name,$r,$c,$s,$tv,$valcmd,$col,$dir) = @_;
	#print join(" : ",($parent,$name,$r,$c,$s,$tv,$valcmd,$col,$dir));
	my %args = ( -row => $r, -column => $c );
	unless (defined $parent) {
		print "\nentryGroup no parent " . Common::lineNo(2);
	}
	my $lab = $parent->Label(-text=>"$name")->grid(%args);
	setBGF($lab,$col,'body');
	if ("$dir" eq "v") { # make a column
		$args{-rowspan} = $s if defined $s;
		$args{-row}++;
	} else { # default to row
		$args{-columnspan} = $s if defined $s;
		$args{-column}++;
	}
	my $ent = ("$dir" eq "v" ? $parent->Entry(-width=>15) : $parent->Entry())->grid(%args);
	setBGF($ent,'entbg','entry');
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
	$font = ($$tah{head} ? 'head' : 'body');
	delete $$tah{head};
	my $lab = setBGF($parent->Label(-text=>"$name", %$tah)->grid(%args),'listbg',$font);
	foreach my $i (@list) {
		$args{-column}++;
		setBGF($parent->Label(-text=>"$i", %$tah)->grid(%args),'listbg',$font);
	}
	return $lab;
}

### Destroy each child of a given frame
sub emptyFrame {
	return TGK::emptyFrame(@_);
}

### Refresh or populate a frame with its heading and an inner frame, then return the inner frame
sub makeMyFrame {
	my ($of,$heading,$pane) = @_;
	emptyFrame($of);
#	my ($pw,$ph) = (Sui::passData('panewidth'),Sui::passData('paneheight'));
	my $header = cfp($of->Label(-text => "$heading"),'panebg','head',1,1);
	my %args = %{ Sui::passData('frameargs') };
	$args{-height} -= 10;
	Common::dbgMes("Making frame $heading (" . $args{-width} . "x" . $args{-height} . ")") if (main::howVerbose() > 1 and Common::showDebug('g'));
	my $if = cfp($of->Frame(%args),'panebg',undef,3,1,'nse',-columnspan=>4);
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
	cfp($if->Label(-text => $$info{description}, -wraplength => 275),'panebg','body',5,1,'w',-columnspan => 6) if exists $$info{description} and $$info{description} ne '';
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
	selectButton("Store");
	my $if = makeMyFrame($of,(FIO::config('Custom','itemhead') or "Enter new pantry contents"),"Store");
	setBG($if,'panebg');
	my $ue = entryRow($of,"UPC: ",2,1,undef,undef,undef,'panebg');
	our $speedy = 0;
	cfp($of->Checkbutton( -text => "Fast Entry", -variable => \$speedy, -command => sub { print "\nPressed: $speedy\n"; }),'panebg','body',2,3);
	sub saveItemInfo {
		my ($but,$dbh,$upc,$name,$size,$uom,$qty,$generic,$keep,$hr,$tf) = @_;
#		$but->configure(-state => 'disabled');
		if ($name eq "UNNAMED") { print "Product needs name!\n"; return unless $speedy; }
		if ($generic eq "Grocery") { print "Product needs equivalence!\n"; return unless $speedy; }
		TGK::pushStatus("Saving item $upc/$name.");
#		print "N: $name, S: $size, U: $uom, C: $upc... Q: $qty, G: $generic, K: $keep...\n";
		my $st;
		skrDebug::dump($hr) if Common::showDebug('a');
		if ($$hr{update}) {
			$st = "UPDATE items SET name=?, unit=?, size=?, generic=?, keep=? WHERE upc=?;";
		} else {
			$st = "INSERT INTO items (name,unit,size,generic,keep,upc) VALUES (?,?,?,?,?,?);";
		}
		my @parms = ($name,$uom,$size,$generic,$keep,$upc);
		my $err = FlexSQL::doQuery(2,$dbh,$st,@parms);
		return unless ($err);
		emptyFrame($tf);
		my $l = cfp($tf->Label(-text=>"Item Saved!"),'panebg','body',1,2,'ew'); # position and color
		unless ($qty == $$hr{qty}) {
			$st = "UPDATE counts SET qty=? WHERE upc=?;";
			$err = FlexSQL::doQuery(2,$dbh,$st,$qty,$upc);
			print "Records changed: $err\n";
			return unless ($err);
			my $lq = cfp($tf->Label(-text=>"Quantity updated!"),'paneBG','body',10,1,'we');
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
		TGK::pushStatus("Added one $ut.");
		my $err = FlexSQL::doQuery(2,$dbh,$st,$ut);
		$err and TGK::pushStatus("..successfully.",1);
		if (defined $row) { # get updated qty, because we just changed it.
			my $st = "SELECT * FROM counts WHERE upc=?;";
			$row = FlexSQL::doQuery(6,$dbh,$st,$ut);
		}
		if ($speedy) {
			$ue->delete(0, 'end'); # clear the UPC box if we're going fast.
			emptyFrame($if); # clear the inner frame of old info fields
			cfp($if->Label(-text => "$ut incremented."),'panebg','body',7,1,'we'); # assure user we did something else
		}
		my $UPConButton = (FIO::config('UI','buttonUPC') || 1);
		$UPConButton || cfp($if->Label( -text => "Working UPC: $ut"),'panebg','body',6,1,'w',-columnspan => 2);
		my $qty = (defined $$row{qty} ? $$row{qty} : 1);
		$st = "SELECT * FROM items WHERE upc=?;";
		$row = FlexSQL::doQuery(6,$dbh,$st,$ut);
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
		our $ne = entryRow($if,"Name: ",1,1,undef,\$nv,\&myValidate,'panebg');
		my $qb = cfp($if->Frame(),'panebg','',1,4,'w',-columnspan=>2);
		our $qe = $qb->Entry(-textvariable=>\$qty,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, );
		our $ke = $qb->Entry(-textvariable=>\$kv,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, );
		our $se = entryRow($if,"Size: ",2,1,undef,\$sv,\&myValidate,'panebg');
		our $ce = $if->BrowseEntry(-width=>5,-variable=>\$uv,-validate=>'focusout',-validatecommand =>\&myValidate);
		our $ge = entryRow($if,"Item Equivalence: ",4,1,undef,\$gv,\&myValidate,'panebg');
		foreach my $e ($qe,$ke,$ce,$ge) {
			setBGF($e,'entbg','entry');
		}
		$okb->configure(-command=> sub {
			$ne->focus if ($nv eq "$defname");
			$ge->focus if ($gv eq "$defgen");
			return if ($nv eq "$defname" or $gv eq "$defgen");
			$ue->delete(0, 'end');
			$newkeep and Sui::storeData('minchanged',time());
# TODO: make this not change the width of the frame.
			saveItemInfo($okb,$dbh,$ut,$nv,$sv,$uv,$qty,$gv,$kv,$row,$if);
			$ue->focus();
		});
		our $ufb = UPC::makeUPCbutton($if,6,4,\$ut,\&formatInfo,"Populate");
		foreach my $b ($okb,$ufb) {
			setBGF($b,'buttonbg','button');
		}
		sub myValidate {
			my ($pv,$av,$cv) = @_;
			return 0 if ($pv eq $cv); # no change made
			$okb->configure( -state=> 'active' ) if (defined $okb);
			return 1
		}
		$ne->delete(0,'end');
		$ne->insert(0,$$row{name});
		our $ql = $qb->Label(-text=>"Qty: ");
		setBGF($ql,'panebg','body');
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
		$ql->grid(-row=>1,-column=>1);
		$qe->grid(-row=>1,-column=>2);
		cfp($qb->Label(-text=>"/"),'panebg','body',1,3);
		$ke->grid(-row=>1,-column=>4);
		my $changed = 0;
		$ne->focus();
	}
	cfp($if->Frame(),'panebg',undef,10,1,'w',-columnspan=>5);
	TGK::bindEnters($ue,sub { incrementUPC($ue,$if); });
	$ue->focus;
	explain($if);
}
print ".";

### Create buttons for sidebar that lead to each function
Sui::storeData('bnames',["Cook","Edit","Buy","Store","Plan","Price","Options","About","Help"]);
sub showButtonPanel {
	my ($parent,$dbh) = @_;
#	my $if = $parent->Frame(-height => 510)->grid(-row=>1,-column=>1,-sticky=>"nws", -rowspan => 2, -ipady => 1, -pady => 1);
	my $if = $parent->Frame(-height => 510)->pack(-side => 'left', -fill => 'y', -expand => 1, -anchor => 'nw');
	my $bf = $if->Frame(-width => 10);
	my %butpro = ( -fill=>'x', -padx=>2, -pady=>2);
	setBG($bf->Label(-text=>"Tasks:",-width=>7)->pack(%butpro),'panebg');
	my $loadb = $bf->Button(-text=>(FIO::config('Custom','itemadd') or "Store"),-command=>sub { showPantryLoader($parent); })->pack(%butpro);
	my $editb = $bf->Button(-text=>(FIO::config('Custom','editor') or "Edit"),-command=>sub { showItemDB($parent); })->pack(%butpro);
	my $prodb = $bf->Button(-text=>(FIO::config('Custom','priceadd') or "Price"),-command=>sub { showProductInfo($parent); })->pack(%butpro);
	my $planb = $bf->Button(-text=>(FIO::config('Custom','recipe') or "Plan"),-command=>sub { showRecipeProposal($parent); }); #->pack(%butpro);
	my $listb = $bf->Button(-text=>(FIO::config('Custom','buylist') or "Buy"),-command=>sub { showShoppingList($parent); })->pack(%butpro);
	my $contb = $bf->Button(-text=>(FIO::config('Custom','pantrylist') or "Cook"),-command=>sub { showPantryContents($parent); })->pack(%butpro);
	setBG($bf->Label(-text => " ")->pack(%butpro),'panebg');
	Sui::storeData('blogos',[$if->Photo(-file => "img/cook.gif"),$if->Photo(-file => "img/edit.gif"),$if->Photo(-file => "img/buy.gif"),$if->Photo(-file => "img/store.gif"),$if->Photo(-file => "img/plan.gif"),$if->Photo(-file => "img/price.gif"),$if->Photo(-file => "img/opts.gif"),$if->Photo(-file => "img/info.gif"),$if->Photo(-file => "img/help.gif")]);
	Sui::storeData('bplaq',$if->Label(-image => @{ Sui::passData('blogos') }[0])->grid(-row=>1,-column=>1,-rowspan => 2));
#	Sui::storeData('bnames',["Cook","Edit","Buy","Store","Plan","Price"]);
	# Changes to these should be made just above this subroutine declaration. Keep the order matching on all (3) lists.
	my @bgroup = ($contb,$editb,$listb,$loadb,$planb,$prodb);
	$bf->grid(-row=>1,-column=>2,-sticky=>"ne");
	my $sysf = $if->Frame()->grid(-row=>2,-column=>2);
	push(@bgroup,$sysf->Button(-image=>$if->Photo(-file => "img/Tango-gear.gif"), -command => sub { showOptionsBox($parent); } )->grid(-row=>1,-column=>1)); # Add options gear at bottom of frame
	push(@bgroup,$sysf->Button(-image=>$if->Photo(-file => "img/Tango-info.gif"), -command => sub { showAboutBox($parent); } )->grid(-row=>1,-column=>2)); # Add an about button to bottom of frame
	push(@bgroup,$sysf->Button(-image=>$if->Photo(-file => "img/Tango-question.gif"), -command => sub { showHelp($parent); })->grid(-row=>1,-column=>3)); # Add a help button to bottom of frame
	Sui::storeData('bgroup',\@bgroup);
	setBG($if,'panebg'); # set background to pane or main color
	setBG($bf,'panebg'); # set background to pane or main color
	foreach my $b (@bgroup) {
		setBGF($b,'buttonbg','button'); # set backgroud to button or main color and font to button font
	}
}
print ".";

sub selectButton { # Disables the active page's button and changes the plaque's image.
	my ($active) = @_;
	main::activePage($active);
	print "\n";
	#print "sB $active ...";
	my @bnames = @{ Sui::passData('bnames') };
	my @bgroup = @{ Sui::passData('bgroup') };
	my $plaque = Sui::passData('bplaq');
	foreach my $i (0..$#bnames) {
		if ($active eq $bnames[$i]) {
			Common::dbgMes("Selecting $active.") if (main::howVerbose() > 0 and Common::showDebug('g'));
			$bgroup[$i]->configure(-state => 'disabled');
			$plaque->configure(-image => getLogo($bnames[$i]));
		} else {
			print "Enabling $bnames[$i]!\n" if ($bgroup[$i]->cget('-state') eq "disabled" and main::howVerbose() > 2 and Common::showDebug('g'));
			$bgroup[$i]->configure(-state => 'normal');
		}
	}
}
print ".";


sub selectPage { # Disables the active page's button and changes the plaque's image.
	my ($active) = @_;
	#print "sB $active ...";
	my @bnames = @{ Sui::passData('bnames') };
	my @bgroup = @{ Sui::passData('bgroup') };
	foreach my $i (0..$#bnames) {
		if ($active eq $bnames[$i]) {
			Common::dbgMes("Invoking $active!") if (main::howVerbose() > 1 and Common::showDebug('g'));
			$bgroup[$i]->invoke();
			return 0; # success!
		} else {
			print ".";
		}
	}
	return 1; # failure
}
print ".";


sub setQty {
	my ($upc,$qty) = @_;
	return -1 if ($qty < 0); # prevent negative onhands
	my $st = "UPDATE counts SET qty=? WHERE upc=?;";
	my $err = FlexSQL::doQuery(2, Sui::passData('db') ,$st, $qty, $upc);
	$err == 1 and TGK::pushStatus("Count set to $qty for $upc.");
	#print "Affected: $err\n";
	return $err;
}
print ".";

sub lowerQty {
	my ($upc,$output,$count,%objs) = @_;
	unless (defined $upc and $upc ne "") {
		$output->configure(-text => "No UPC given! Cannot use up.");
	}
	unless (exists $objs{$upc}) {
		$output->configure(-text => "$upc not found! Cannot use up.");
		return 2;
	}
	my $i = $objs{$upc}{o};
	my $qt = $i->cget('-text');
	$qt =~ /(\d+)\/(\d+)/;
	unless (defined $1 and defined $2) {
		$output->configure(-text => "$qt could not be parsed for $upc! Cannot use up.");
		return 3;
	}
	my ($q,$n) = ($1,$2);
	unless ($q > 0) {
		$output->configure(-text => "You have no $upc to use. Cannot use up.");
		return 4;
	}
	$q--;
	setQty($upc,$q);
	${ $objs{$upc}{q} }--;
	$output->configure(-text => "Used up $count of $upc");
	$i->configure(-text => "$q/$n");
}
print ".";

sub showOptionsBox { # For changing options
	my ($parent,) = @_;
	selectButton("Options");
	my $of = $parent->{rtpan};
	emptyFrame($of);
	my ($pw,$ph) = (Sui::passData('panewidth'),Sui::passData('paneheight'));
	print "sOB: $parent, $of\n";
	Options::mkOptBox($of,$pw,$ph,Sui::getOpts());
}
print ".";

sub showAboutBox { # For displaying the about text in a box
	my ($parent,) = @_;
	selectButton("About");
	my $of = $parent->{rtpan};
	emptyFrame($of);
	my ($pw,$ph) = (Sui::passData('panewidth'),Sui::passData('paneheight'));
	my $if = makeMyFrame($of,"About This Program");
	my $aboutstring = Sui::aboutMeText();
	my @abouts = split('\n',$aboutstring);
	my $row = 1;
	foreach my $a (@abouts) {
		cfp($if->Label(-text => $a),'panebg','body',$row++,1);
	}
}
print ".";

sub showPantryContents { # For cooking/reducing inventory
	my ($parent,) = @_;
	selectButton("Cook");
	my $pxwidth = (FIO::config('UI','maxcolw') or 100);
	my $of = $parent->{rtpan};
	my $if = makeMyFrame($of,(FIO::config('Custom','listhead') or "Contents of Pantry"));
	my %args = %{ Sui::passData('frameargs') };
	my %qtyos;
	my $sf = $if->Scrolled('Frame', -scrollbars => 'osoe', %args, -width => $args{-width} * 0.95)->pack(-fill => 'both',);
	my $userow = cfp($sf->Frame(),'listbg','',1,1,'w',-columnspan=>7);
	cfp($userow->Label(-text => "Item to use up:"),'listbg','body',1,1);
	my $dq = 0;
	my $de = cfp($userow->Entry(-validate => 'all', -validatecommand => sub { $dq = 0; return 1; } ),'entbg','entry',1,2);
	my $ol = $userow->Label(-text => " ")->grid(-row => 1, -column => 3);
	my $db = cfp($userow->Button(-text => "Use", -command => sub { lowerQty($de->get(),$ol,++$dq,%qtyos); }),'buttonbg','button',1,4);
	TGK::bindEnters($de, sub { lowerQty($de->get(),$ol,++$dq,%qtyos); });
	cfp($sf->Label(-text => " ", -width => 80, -height => 1),'listbg','body',2,1,'w',-columnspan => 7);
	my $st = "SELECT * FROM items WHERE upc NOT LIKE 'RG%' ORDER BY generic ASC;";
	my $qst = "SELECT qty FROM counts WHERE upc=?;";
	my $dbh = Sui::passData('db');
	my $tah = { -justify => 'left', -wraplength => $pxwidth, head => 1 };
	my $res = FlexSQL::doQuery(3,$dbh,$st,'upc'); # Get items in pantry
	my @order = sort {$$res{$a}{generic} cmp $$res{$b}{generic}} keys %$res;
	my $showitem = (Sui::passData('showcookgeneric') or 0);
	listRow($sf,"Qty",3,1,$tah,($showitem ? "Item" : ""),"Product","UPC");
	cfp($sf->Label(-text => "Change"),'listbg','head',3,6,'w',-columnspan => 2);
	my $row = 4;
	foreach my $o ($sf,$ol) {
		setBGF($o,'listbg','body');
	}
	delete $$tah{head};
	foreach my $i (@order) {
		my $qty = @{ FlexSQL::doQuery(7,$dbh,$qst,$$res{$i}{upc}) }[0];
		my $q = listRow($sf,"$qty/$$res{$i}{keep}",$row,1,$tah,($showitem ? "$$res{$i}{generic}" : ""),"$$res{$i}{name}","$$res{$i}{upc}");
		$qtyos{"$$res{$i}{upc}"}{o} = $q;
		$qtyos{"$$res{$i}{upc}"}{q} = \$qty;
		my $usebutton = cfp($sf->Button(-text => "-1",-command => sub { $qty--; setQty($$res{$i}{upc},$qty); $q->configure(-text => "$qty/$$res{$i}{keep}"); }),'buttonbg','button',$row,6);
		my $undobutton = cfp($sf->Button(-text => "+1",-command => sub { $qty++; setQty($$res{$i}{upc},$qty); $q->configure(-text => "$qty/$$res{$i}{keep}"); }),'buttonbg','button',$row,7);
		$row++;
	}
	$de->focus();
	explain($if);
}
sub showProductEntry { # For adding a new product entry
	# TODO: Allow price entry for UPCs not found in DB.
}
sub showProductInfo { # for pricing products in the store
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	selectButton("Price");
	my $if = makeMyFrame($of,(FIO::config('Custom','pricehead') or "Pricing Tool"));
	my ($r,$c) = (1,1);
	my %args = %{ Sui::passData('frameargs') };
	unless (defined $parent) {
		print "No parent given to sPI()" . Common::lineNo();
	}
	my $si = (Sui::passData('storeID') or 1);
	my ($uv,$pv);
	our ($dv,$okb);
	cfp($if->Label(-text=>"Store: "),'panebg','body',2,1);
	our $de = cfp($if->Entry(-textvariable => \$dv),'entbg','entry',2,5);
	my $sn = cfp($if->Label(-text=>"Unnamed Store"),'panebg','body',2,3);
	my $pnl = cfp($if->Label(-text => "Unknown Product"),'panebg','body',3,3,'w',-columnspan => 2);
	my $psw = cfp($if->Scrolled('Frame', -scrollbars => 'ose', -width => $args{-width} * 0.95, -height => $args{-height} * 0.85),'listbg','',4,1,'ew',-columnspan => 5);
	my $ptable = setBG($psw->Frame()->pack(-fill => 'both'),'listbg');
	my $se = cfp($if->Entry(-textvariable=> \$si),'entbg','entry',2,2);
	$dv = Common::datenow();
	$sn->configure(-text => getStore($si));
	# text, characters changed, previous text, position, operation
	$se->configure(-validate => 'all', -validatecommand => sub {
		my ($nt,$ct,$ot,$pos,$op) = @_;
		return 0 if($nt eq $ot);
		my $nam = getStoreNames($nt);
		$sn->configure(-text => $nam);
		return 1; });
	$sb = cfp($if->Button(-text => "Change/Add", -command => sub { showStoreEntry($if,$se); } ),'buttonbg','button',2,4); # show a button to change/add the store
	$ue = entryRow($if,"UPC:",3,1,undef,\$uv,sub { $r = getProdData($ptable,$pnl,$ue->get()); },'panebg'); # show a UPC entry
	my $pe = entryRow($if,"Price:",10,1,2,\$pv,\&allowSave,'panebg');
	$okb = cfp($if->Button(-text=> "Save Price", -state => 'disabled', -command=> sub {
		$r = savePriceInfo($okb,$dbh,$ptable,$se->get(),$uv,$dv,$pv,$ue);
		$ue->delete(0, 'end');
		$ue->focus();
		Sui::storeData('storeID',$si);
		$dv = Common::datenow();
	}),'buttonbg','button',10,5);
	$ue->configure(-validate => 'focusout');
	$pe->configure(-validate => 'all');
	TGK::bindEnters($ue,sub { $r = getProdData($ptable,$pnl,$uv); }); # bind return on entry to a function that adds a table of price information and an entry where you can enter the price
	# TODO: bind return on the price field to the price update function
	sub getProdData {
		my ($target,$pl,$cv) = @_; # target frame, product name label
		# TODO: Make displayed name include size in UOM
		$pl->configure(-text => getProdName($cv,1)) if (defined $cv and $cv ne "");
		emptyFrame($target);
		$r = 1; $c = 1;
		my $list = getProdPrices($cv);
		addPriceListHeads($target,$r);
		cfp($target->Label(-text => ""),'listbg','',$r,4);
		foreach my $listrow (reverse @$list) {
			makePriceRow($target,1,\$r,@$listrow);
		}
		return $r;
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
		$pv =~ /^(\d+.?\d*)$/;
		unless (defined $1) {
			$but->configure(-state => 'disabled');
			return;
		}
		my $ist = "INSERT INTO prices(upc,store,price,date) VALUES(?,?,?,?);";
		(defined $dbh or $dbh = FlexSQL::getDB());
		FlexSQL::doQuery(2,$dbh,$ist,$uv,$si,$pv,$dv) and TGK::pushStatus("Added price $pv for $uv at store $si.");
		makePriceRow($target,1,\$r,$si,$pv,$dv);
		$but->configure(-state => 'disabled');
		$ue->focus();
		return $r;
	}
	showAddMinButton($of,0); # Make the item being priced an item user wants to keep on hand.
	$ue->focus();
	explain($if);
}
print ".";

sub getProdPrices {
	my $st = "SELECT store,price,date FROM prices WHERE upc=? ORDER BY date DESC LIMIT ?;";
	return FlexSQL::doQuery(4,FlexSQL::getDB(),$st,shift,(FIO::config('Rules','shortcount') or 25));
}
print ".";

sub getAvgPrice {
	my $st = "SELECT AVG(price) AS mean FROM prices WHERE upc=? AND date >= DATE('now',?);";
	return @{ FlexSQL::doQuery(5,FlexSQL::getDB(),$st,shift,"-" . (FIO::config('Rules','logdays') or 90) . " days") }[0];
}
print ".";


sub addPriceListHeads {
	my ($target,$r) = @_;
	cfp($target->Label(-text => "Store"),'listbg','head',$r,1);
	cfp($target->Label(-text => "Price"),'listbg','head',$r,2);
	cfp($target->Label(-text => "Date"),'listbg','head',$r,3);
}
print ".";

sub makePriceRow {
	my ($t,$showrembut,$r,$a,$b,$c) = @_;
	unless (defined $t) {
		print "No target for mPR()" . Common::lineNo(1);
	}
	$$r++;
	$c =~ /(\d\d\d\d-\d\d-\d\d)/;
	my $rl1 = cfp($t->Label(-text => getStore($a) . "   "),'listbg','body',$$r,1);
	my $rl2 = cfp($t->Label(-text => "   $b   "),'listbg','body',$$r,2);
	my $rl3 = cfp($t->Label(-text => "   $1"),'listbg','body',$$r,3);
	my $rb;
	$rb = cfp($t->Button(-text => "-", -command => sub {
		my $st = "DELETE FROM prices WHERE date=?;"; # set query
		FlexSQL::doQuery(2,FlexSQL::getDB(),$st,$c); # delete price
		$rl1->destroy(); # clear the line from the list.
		$rl2->destroy();
		$rl3->destroy();
		print "B: " . join(',',@_);
		$rb->destroy(); # remove this button.
	} ),'buttonbg','button',$$r,5) if $showrembut;
	$t->gridColumnconfigure(1,-weight=>10);
}
print ".";

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
	my $wiggle = (FIO::config('Rules','beloworat') or 0);
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
	cfp($parent->Label(-text => "UPC"),'listbg','head',$row,1);
	cfp($parent->Label(-text => "Item"),'listbg','head',$row,2);
	cfp($parent->Label(-text => "OnHand"),'listbg','head',$row,4);
	cfp($parent->Label(-text => "Desired"),'listbg','head',$row,5);
	cfp($parent->Label(-text => "Buy"),'listbg','head',$row,6);
	$row++;
	foreach my $i (@list) {
		my ($gen,$upc,$name,$qty,$desired) = @$i;
		unless ($gen eq $curhed) {
			$curhed = $gen;
			cfp($parent->Label(-text => "$curhed:", -font => [-underline => 1]),'listbg','body',$row,2);
			cfp($parent->Label(-text => "$desired"),'listbg','body',$row,5);
			$row++;
		}
		cfp($parent->Label(-text => "$upc"),'listbg','body',$row,1);
		cfp($parent->Label(-text => "$name"),'listbg','body',$row,3);
		cfp($parent->Label(-text => "$qty"),'listbg','body',$row,4);
		my $buy = $desired - $qty;
		cfp($parent->Label(-text => "$buy"),'listbg','body',$row,6);
		cfp($parent->Checkbutton( -text => ""),'listbg','body',$row,7); # just a user element for shopping convenience.
		$row++;
	}
}

sub showShoppingList { # For buying items that are getting low
	my ($parent,) = @_;
	my %args = %{ Sui::passData('frameargs') };
	my $of = $parent->{rtpan};
	emptyFrame($of);
	selectButton("Buy");
	my $header = cfp($of->Label(-text => (FIO::config('Custom','shophead') or "Shopping List")),'panebg','head',1,2);
	my @list = getDeficits(getMinimums());
	# VVV
	my $if = $of->Frame()->grid(-row => 2, -column => 1, -columnspan => 7);
	$args{-width} *= 0.95;
	my $sf = $if->Scrolled('Frame', -scrollbars => 'osoe', %args)->pack(-fill => 'both',);
	setBG($sf,'listbg');
	listToBuys($sf,@list);
	showAddMinButton($of,4); # add a minimum for items not yet in DB for keeping on hand.
	explain($if);
}
print ".";

sub addPriceList { # For showing a price history and analysis
	my ($parent,$upc,$name) = @_;
	my %args = %{ Sui::passData('frameargs') };
	emptyFrame($parent);
	$parent->grid(-sticky => 'ew');
	my $header = cfp($parent->Label(-text => "Price List"),'panebg','head',1,2);
	Common::dbgMes("Grabbing prices for $name ($upc)...") if Common::showDebug('d');
	my ($r,$c) = (2,1);
	addPriceListHeads($parent,$r);
	# get avg price
	my $list = getProdPrices($upc); # get all price info for last 25 entries (user alterable)
	my $m90 = getAvgPrice($upc); # get avg price for 90 days (user alterable)
	my $m25 = 0;
	my $c25 = 0;
	my $lowind = -1;
	my $lowest = 999;
	my $i = 0;
	foreach my $p (@$list) {
		$c25++;
		$m25 += $$p[1];
		$lowind = $i if $$p[1] < $lowest;
		$lowest = $$p[1] if $$p[1] < $lowest;
		$i++;
	}
	$m25 = Common::nround(3,$m25 / $c25);
	$m90 = Common::nround(3,$m90);
	print "=\\ $m25:$m90 $lowind/=";
	cfp($parent->Label(-text => "+/-"),'listbg','head',$r,4);
	my $j = 0;
	foreach my $p (@$list) {
		my $d1 = Common::nround(3,$$p[1] - $m25);
		my $d2 = Common::nround(3,$$p[1] - $m90);
		my $c1 = ($d1 > 0 ? 1 : 2); # red or green
		my $c2 = ($d2 > 0 ? 1 : 2); # for each avg
		$c1 = 4 if $lowind == $j; # blue for lowest
		my $lm = ($lowind == $j ? "*" : "");
		makePriceRow($parent,0,\$r,@$p);
		$c1 = Common::getColors($c1,1,1);
		setFont($parent->Label(-text => "$lm $d1/$d2 $lm", -background => "#EEF", -foreground => "$c1")->grid(-row => $r, -column => 4),'body');
		$j++;
	}
	return $r;
}
print ".";

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
	my $ne = cfp(entryRow($if,"Name:",1,1,undef,\$nv,'listbg'),'entbg','entry');
	my $le = cfp(entryRow($if,"Address:",2,1,undef,\$lv,'listbg'),'entbg','entry');
	my $nb = cfp($if->Button(-text => "Add New", -command => sub {
		my $sid = 0;
		return unless (defined $nv and defined $lv); # skip processing of incomplete data.
		FlexSQL::doQuery(2,$dbh,"DELETE FROM stores WHERE name='DELETE';");
		my $cst = "INSERT INTO stores(name,loc) VALUES(?,?);";
		if (FlexSQL::doQuery(2,$dbh,$cst,"DELETE",$lv)) {
			$cst = "SELECT store FROM stores WHERE name=?;";
			$sid = FlexSQL::doQuery(7,$dbh,$cst,"DELETE"); $sid = $$sid[0];
			TGK::pushStatus("Added store $nv.");
			$cst = "UPDATE stores SET name=? WHERE store=?;";
			FlexSQL::doQuery(2,$dbh,$cst,$nv,$sid);
			getStoreNames(FlexSQL::getDB(),1);
		}
		print "ID: $sid\n";
		setEntry($if,$entry,$sid) if ($sid);
		}),'buttonbg','button',2,4);
	my $st = "SELECT store,name FROM stores WHERE name IS NOT NULL AND name != 'DELETE';";
	my @sids = @{ FlexSQL::doQuery(4,$dbh,$st); };
	my $row = 3;
	foreach my $r (@sids) {
		my ($id,$name) = @$r;
		cfp($if->Button(-text => "$name", -command => sub { setEntry($if,$entry,$id); }),'buttonbg','button',$row,2);
		$row++;
	}
	cfp($if->Button(-text => "Cancel", -command => sub { setEntry($if); }),'buttonbg','button',$row,3);
	explain($if,"Store Entry");
}

sub populateMainWin {
	my ($dbh,$win,$reset) = @_;
	my $frameargs = {-width => 594};
	if ($reset) {
		exists $win->{rtpan} and $win->{rtpan}->destroy();
	} else {
		my $w = ($win->width * 0.9 or 594);
		my $h = ($win->height * 0.9 or 435);
		$frameargs->{-height} = (Sui::passData('paneheight') or $h);
		$frameargs->{-width} = (Sui::passData('panewidth') or $w);
		Sui::storeData('frameargs',$frameargs);
		unless (FlexSQL::table_exists($dbh,"items") && FlexSQL::table_exists($dbh,"stores")) {
			print "-=-";
			TGK::pushStatus("Required tables not found. Attempting to create them. Please wait...");
			FlexSQL::makeTables($dbh);
			TGK::pushStatus("Done.",1);
		}
		Sui::storeData('db',$dbh);
	}
	my $of = $win->Frame(%$frameargs);
	setBG($of,'panebg');
	$win->{rtpan} = $of;
	$of->pack(-side => 'right', -fill => 'both', -expand => 1);
	showButtonPanel($win,$dbh);
	showDefaultPage() # try to load default page
	and showPantryLoader($win); # if default page fails...
}
print ".";

sub showDefaultPage {
	my $default = (FIO::config('UI','defaultpage') || "Store");
	my $error = selectPage($default);
	if ($error) {
		Common::errorOut('inline',0,color => 1, fatal => 0, string => "\n[W] Default page could not be loaded", %args);
		TGK::pushStatus("Failed to load default page!");
	}
	return $error;
}
print ".";

sub showItemDB {
	my ($parent,) = @_;
	my $of = $parent->{rtpan};
	my $upc = "";
	my $name = "";
	my $size = 0;
	my $unit = "oz";
	selectButton("Edit");
	my $if = makeMyFrame($of,(FIO::config('Custom','edithead') or "Edit item information"));
	my $ue = entryRow($of,"UPC: ",2,1,undef,undef,undef,'panebg');
	$if->configure(-height => Sui::passData('paneheight') * 0.5);
	my $pf = cfp($of->Frame(-width => Sui::passData('panewidth'), -height => Sui::passData('paneheight') * 0.48),'listbg',undef,5,1,'w',-columnspan => 6);
	cfp($of->Button( -text => "Fetch Info", -command => sub { print "\nWhen this is coded, it'll try to pull item info from a UPC database. For now, enjoy the pretty status button.\n"; $if->Button(-text => "Not yet coded")->pack(-anchor => 'w'); }),'buttonbg',undef,2,3);
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
	cfp($of->Button( -text => "Review Autodata", -command => sub { print "\nWhen this is coded, it'll try to pull items from the database that haven't been reviewed. For now, enjoy the pretty status button.\n"; $if->Button(-text => "Not yet coded")->pack(-anchor => 'w'); }),'buttonbg',undef,2,4);
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
		my $l = cfp($tf->Label(-text=>"Item Saved!"),'panebg','body',1,2);
		unless ($qty == $$hr{qty}) {
			$st = "UPDATE counts SET qty=? WHERE upc=?;";
			$err = FlexSQL::doQuery(2,$dbh,$st,$qty,$upc);
			print "Records changed: $err\n";
			$err and TGK::pushStatus("Count for $upc set to $qty.");
			return unless ($err);
			my $lq = cfp($tf->Label(-text=>"Quantity updated!"),'panebg','body',1,1);
		}
		$tf->focusPrev();
	}

	sub editUPC {
		my ($ue,$if,$plf) = @_;
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
		$UPConButton || cfp($if->Label( -text => "Working UPC: $ut"),'panebg','body',6,1,'w',-columnspan => 2);
		my $qty = (defined $$row{qty} ? $$row{qty} : 1);
		$st = "SELECT * FROM items WHERE upc=?;";
		$row = FlexSQL::doQuery(6,$dbh,$st,$ut);
		$$row{update} = (defined $row ? 1 : 0);
		$$row{name} = "UNNAMED" unless defined $$row{name};
		$$row{qty} = $qty;
		my ($nv,$sv,$uv,$gv,$kv) = (undef,1,"oz","Grocery",0);
		$sv = $$row{size} if defined $$row{size};
		$uv = $$row{unit} if defined $$row{unit};
		$gv = $$row{generic} if defined $$row{generic};
		if (defined $$row{keep} and $$row{keep} ne $kv) { $newkeep = 1; }
		$kv = $$row{keep} if defined $$row{keep};
		our $okb = cfp($if->Button(-text=> ($UPConButton ? "Save $ut" : "Save"), -state => 'disabled',),'buttonbg','button',6,5);
		our $ne = entryRow($if,"Name: ",1,1,undef,\$nv,\&myValidate,'panebg');
		our $qe = setBGF($if->Entry(-textvariable=>\$qty,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, ),'entbg','entry');
		our $ke = setBGF($if->Entry(-textvariable=>\$kv,-validate=>'focusout',-validatecommand=> \&myValidate, -width => 4, ),'entbg','entry');
		our $se = entryRow($if,"Size: ",2,1,undef,\$sv,\&myValidate,'panebg');
		our $ce = setBGF($if->BrowseEntry(-width=>5,-variable=>\$uv,-validate=>'focusout',-validatecommand =>\&myValidate),'entbg','entry');
		our $ge = entryRow($if,"Item Equivalence: ",4,1,undef,\$gv,\&myValidate,'panebg');
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
		cfp($if->Label(-text=>"/"),'panebg','body',1,5);
		my $changed = 0;
		$qe->grid(-row=>1,-column=>4);
		$ke->grid(-row=>1,-column=>6);
		our $ufb = UPC::makeUPCbutton($if,6,4,\$ut,\&formatInfo,"Populate");
		setBGF($ufb,'buttonbg','button');
		addPriceList($plf,$ut,$$row{name});
		$ne->focus();
	}
	# bind enter here to a function that either adds one to the onhand,
	#	or if not found, pulls open the description entries below for saving.
	# TODO: Make this not alter the width of the frame.
	TGK::bindEnters($ue,sub { editUPC($ue,$if,$pf); });
	$ue->focus;
	explain($if);
}
print ".";

sub showRecipeProposal {
	my ($parent,) = @_;
	my %args = %{ Sui::passData('frameargs') };
	my ($of,$rowindex,$addbutton) = ($parent->{rtpan},0,undef);
	emptyFrame($of);
	selectButton("Plan");
	my $header = cfp($of->Label(-text => (FIO::config('Custom','planhead') or "Recipe Worksheet")),'panebg','head',1,2);
	our $rframe = cfp($of->Scrolled('Frame',-scrollbars=>'osoe', -width => $args{-width}, -height => $args{-height} * 0.85),'listbg',undef,2,1,'nsw',-columnspan => 5);
	our (@rows,@costs,$buttons);
	my $buttonrow = cfp($of->Frame(),'panebg',undef,3,1,'w',-columnspan => 5);
	my $costl = cfp($buttonrow->Label(-text => "Cost:"),'panebg','body',1,1);
	my $costo = cfp($buttonrow->Label(-text => "\$0.00"),'panebg','body',1,2);
	$addbutton = cfp($buttonrow->Button(-text=>"Add Ingredient",-command=>sub { addIngredient($rframe,$addbutton,\$rowindex,$buttons,$costo); }),'buttonbg','button',1,3);
	my $buybutton = cfp($buttonrow->Button(-text=>"Buy Ingredients",-state => 'disabled', -command=>sub { print "TODO: code these (buy)"; }),'buttonbg','button',1,4);
	my $recsavbut = cfp($buttonrow->Button(-text=>"Save",-state => 'disabled', -command=>sub { print "TODO: code these (save)"; }),'buttonbg','button',1,5);
	sub addIngredient {
		my ($target,$daib,$r,$bbox,$out) = @_;
		$daib->configure(-state => 'disabled');
		my ($gt,$upc,%dat) = (0,"",());
		my $gbbox = cfp($target->Frame(),'listbg',undef,1,1,'w',-columnspan => 5);
skrDebug::dump($r,"Row3",1);
		our $ge = $gbbox->Entry(-text => "", -validate => 'all', -validatecommand => sub { return searchGens(\$gt,$target,$gbbox,$bbox,$daib,$r,$out,@_); })->grid(-row => 1, -column => 1); # Entry that searches generics (once every three characters entered)
		sub searchGens {
			my ($go,$t,$t2,$bb,$dib,$ir,$output,$en,$ed,$eo,$ep,$op,$ee) = @_;
		print "sG - Objects: mI target: $t; GBBox: $t2; Button Box: $bb; GEntry: $ge;\n";
			my ($br,$bc,$gv,$gl) = (1,1,$ge->get(),length($ge->get()));
			$$go = $gl - 2 if ($$go > 0 && $op == 7);
			my $gts = ($gl >= $$go + 2 and $gl > 2 ? 1 : 0); # are we going to search?
			my $gtr = ($op == 7 or $gts ? 1 : 0); # are we going to refresh the buttons?
		print "Values: $gtr/$gts)) $$go, $eo/$ed/$en ($op\@$ep) +$ee\n";
			if ($gtr and defined $bb) { emptyFrame($bb); print "U"; }
#			if ($gtr and defined $bb) { $bb->destroy(); }
			unless (defined $bb) { $bb = $t2->Frame()->grid(-row => 2, -column => 1, -sticky => "new"); } # row of buttons, one for each generic, from results of search
			my $genbut = Sui::passData('genericbutton');
		skrDebug::dump($genbut,"GB",1);
			if (defined $genbut and $gl > 2) { # update or create the generic button
print "+=+";
				$genbut->configure(-text => "New Generic: $gt", -command => sub { addGeneric($t,$t2,$bb,$ge,$dib,$gt,$ir,$output); });
			} elsif (length $gt > 2 and defined $bb) {
print "-=-";
				$genbut = $bb->Button(-text => "New Generic: $gt", -command => sub { addGeneric($t,$t2,$bb,$ge,$dib,$gt,$ir,$output); })->grid(-row => $br, -column => $bc++);
				Sui::storeData('genericbutton',$genbut);
			} else {
				print "=-=";
			}
			return 1 unless ($gts);
			#TODO: Fix the display of this button.
			my $gt = (defined length($ed) ? $en : $ge->get());
skrDebug::dump($ir,"Row2",1);
			$$go = $gl;
			print "Length: $gl...\n";
			my $st = "SELECT generic FROM items WHERE generic LIKE ? GROUP BY generic;";
			my $res = FlexSQL::doQuery(7,FlexSQL::getDB(),$st,"\%$en\%");
			foreach my $g (@$res) {
				# Each generic button will do a search and show items with that generic as buttons in a replacement of the generics buttons
				$bb->Button(-text => "$g", -command => sub { showItems($t,$t2,$bb,$ge,$dib,$g,$ir,$output); })->grid(-row => $br, -column => $bc);
				$bc++;
				if ($bc > 4) {
					$bc = 1;
					$br++;
				}
			}
			return 1;
		}
		# bind Enter on entry to search and fill button row, but if no results, make a button to add a new generic
		TGK::bindEnters($ge,sub { return searchGens(\$gt,$target,$gbbox,$bbox,$daib,$r,$out,@_); });
		sub addGeneric {
			my ($t,$t2,$butb,$mge,$aib,$gt,$ir,$ol) = @_;
			my %idh;
			$idh{upc} = "RG" . time(); # Assign a random upc or a upc based on the name of the generic
			$idh{name} = "RGeneric $gt"; # TODO: Add generic to item DB
			$idh{keep} = 0; # Assign a keep count
			$idh{generic} = "$gt"; # Generic (the whole reason for creating this item)
			# Assign a cost, size, and UOM
			$idh{unit} = "oz";
			$idh{size} = 1;
			$idh{cost} = ($$cost[0] or 0.00);
			$idh{qty} = 0; # assign a 0 quantity
			$idh{out} = $ol;
# Save data to the DB and to the hash we pass to makeIngredient
			saveGeneric(%idh);
			$mge->destroy();
			$butb->destroy();
skrDebug::dump($ir,"Row1",1);
			Sui::storeData('genericbutton',undef);
			makeIngredient($idh{upc},$t,$ir,%idh);
			$aib->configure(-state => 'normal');
		}
		sub saveGeneric {
			my %i = @_;
			my $sti = "INSERT INTO items (name,unit,size,generic,keep,upc) VALUES (?,?,?,?,?,?);";
			my $stc = "INSERT INTO counts (upc,qty) VALUES (?,?);";
			my $dbh = FlexSQL::getDB();
			if (FlexSQL::doQuery(2,$dbh,$sti,$i{name},$i{unit},$i{size},$i{generic},$i{keep},$i{upc})) {
				my $err = FlexSQL::doQuery(2,$dbh,$stc,$i{upc},$i{qty});
				TGK::pushStatus("Added Generic $i{generic} to Items DB.");
			}
			return 0;
		}
		sub showItems {
			my ($t,$t2,$butb,$mge,$aib,$gt,$ir,$ol) = @_;
		#print "sI - Objects: mI target: $t; GBBox: $t2; Button Box: $butb; GEntry: $mge;\n";
			my $st = "SELECT upc,name,unit,size FROM items WHERE generic=?;";
			my $res = FlexSQL::doQuery(3,FlexSQL::getDB(),$st,$gt,'upc'); # Get items of this generic
			my @order = sort {$$res{$a}{upc} cmp $$res{$b}{upc}} keys %$res;
			defined $butb and emptyFrame($butb);
			Sui::storeData('genericbutton',undef);
			$butb = $t2->Frame()->grid(-row => 2, -column => 1, -sticky => "new"); # row of buttons, one for each item, from results of search
			my ($br,$bc) = (1,1);
			foreach my $i (@order) {
				print "Item $$res{$i}{upc}: $$res{$i}{name}\n";
				my $st = "SELECT AVG(price) FROM prices WHERE upc=?";
				if (0) { # TODO: make a limit on the date
					$st = "$st AND date > ?";
				}
				$st = "$st ORDER BY date DESC LIMIT 10;"; # limit to latest 10 prices
				my $cost = FlexSQL::doQuery(7,FlexSQL::getDB(),$st,$$res{$i}{upc});
				$$res{$i}{cost} = ($$cost[0] or 0.00);
				$$res{$i}{out} = $ol;
				# Get cost and add to $$res data;
		# once an item or generic is selected, that item's UOM is used to determine the unit used in recipe planning
		#   and how many items the required amount represents
		# Or I may have to just make a cost calculation ahead of calling makeIngredient, and leave the unit breakout for the buyIngredients display
		# makeIngredient is then called to show the row
				$butb->Button(-text => "$$res{$i}{name}", -command => sub { $mge->destroy(); $butb->destroy(); makeIngredient($i,$t,$ir,%{ $$res{$i} }); $aib->configure(-state => 'normal'); })->grid(-row => $br, -column => $bc);
				$bc++;
				if ($bc > 4) {
					$bc = 1;
					$br++;
				}
			}
		}
		$ge->focus();
		return 1;
	}

	sub sumCosts {
		my ($output) = shift;
		my $total = 0.00;
		foreach my $c (@costs) {
			$total += $c;
		}
		$output->configure(-text => "\$$total");
	}
	sub makeIngredient {
		my ($upc,$t,$r,%data) = @_;
	#print "mI - Objects: mI target: $t;\n";
skrDebug::dump($r,"Row",1);
		push(@rows,$t->Frame()->grid(-row => $$r + 2, -column => 1, -sticky=>"ew"));
		push(@costs,$data{cost});
		my $ud = $data{size};
		$rows[$$r]->Label(-text=>"$data{name}")->grid(-row=>1,-column=>1); # Name
		my $qe = $rows[$$r]->Entry(-text=>"$ud")->grid(-row=>1,-column=>2); # Qty
		$rows[$$r]->Label(-text=>"$data{unit}")->grid(-row=>1,-column=>3); # Units
		my $cl = $rows[$$r]->Entry(-text=>"$data{cost}",-state => 'disabled', -width => 6)->grid(-row=>1,-column=>4); # Cost
		my $pc = $rows[$$r]->Label(-text => "1")->grid(-row => 1, -column => 6);
		my $rowind = $$r;
		$qe->configure(-validate => 'all', -validatecommand => sub {
			return 0 unless validateNumeric(@_);
			my $count = Common::nround(0,$qe->get() / $ud + 0.499);
			$pc->configure(-text => "$count");
			$costs[$rowind] = $count * $cl->get();
			sumCosts($data{out});
			return 1;
			});
		$rows[$$r]->Button(-text=>" - ", -command => sub { $costs[$rowind] = 0.00; $rows[$rowind]->destroy(); sumCosts($data{out}); })->grid(-row=>1,-column=>7); # Remove
		sumCosts($data{out});
		TGK::pushStatus("Ingredient $data{name} added to plan");
		$$r++; 		# $$r++ if makeIngredient succeeds.
	}
	explain($rframe,"Plan");
}
print ".";


sub getProdName {
	my ($ut,$showgen,$dbh) = @_;
	$st = "SELECT name,generic FROM items WHERE upc=?;";
	(defined $dbh or $dbh = FlexSQL::getDB());
	$row = FlexSQL::doQuery(6,$dbh,$st,$ut);
	skrDebug::dump($row);
	return "unknown" unless (defined $row);
	$$row{name} = "unknown" unless defined $$row{name};
	return $$row{name} . "  (" . $$row{generic} . ")" if $showgen; # TODO: Show QTY/UOM optionally
	return $$row{name};
}
print ".";

sub showHelp {
	my $parent = shift;
	my $page = main::activePage();
	my $of = $parent->{rtpan};
	my $t = cfp($of->Frame(),'helpbg',undef,1,1,'n',-columnspan => 7);
	cfp($t->Label(-image =>$parent->Photo(-file => "img/Tango-question.gif")),'helpbg',undef,1,1);
	for ($page) {
		if (/Store/) {
			cfp($t->Label(-text => "The UPC entry takes a UPC, PLU, or private product code."),'helpbg',undef,1,2);
			cfp($t->Label(-text => "The Fast Entry checkbox allows you to increase UPC counts without entering information about each one."),'helpbg',undef,2,2);
			cfp($t->Label(-text => "Once a UPC is entered, if Fast Entry is off, you can enter information about the item:"),'helpbg',undef,3,1,'w',-columnspan => 3);
			cfp($t->Label(-text => "Name"),'helpbg',undef,4,2);
			cfp($t->Label(-text => "Generic"),'helpbg',undef,5,2);
			cfp($t->Label(-text => "Quantity/Keep"),'helpbg',undef,6,2);
			cfp($t->Label(-text => "Size & UOM"),'helpbg',undef,7,2);
			cfp($t->Label(-text => ""),'helpbg',undef,8,2);
			cfp($t->Label(-text => ""),'helpbg',undef,9,2);
			cfp($t->Label(-text => "Populate button"),'helpbg',undef,10,2);
			cfp($t->Label(-text => "Save button"),'helpbg',undef,11,2);
		} else {
			cfp($t->Label(-text => "Help is not available for this page. Sorry."),'helpbg',undef,1,2);
		}
	}
	cfp($t->Button(-text => "Close", -command => sub { $t->destroy(); }),'buttonbg',undef,100,7);
}
print ".";

sub place {
	return TGK::place(@_);
}
print ".";

sub getLogo {
	my $n = shift;
	my @bnames = @{ Sui::passData('bnames') };
	my @bgroup = @{ Sui::passData('bgroup') };
	return @{ Sui::passData('blogos') }[Common::findIn($n,@bnames)] or undef;

}
print ".";

sub validateNumeric { my ($en,$ed,$eo,$ep,$op,$ee) = @_; $en =~ /^(\d*\.?\d+)$/; return (defined $1 or $en eq ""); }
print ".";

sub getDBPass {
	my ($parent,$snt,$dnt) = @_;
	my $bg = 'panebg';
	my $dia = $parent->DialogBox(-title=>"Login to $snt/$dnt",-buttons=>['Ok','Cancel'],-default_button=>'Ok');
	setBG($dia,$bg);
	setBG($dia->add('Label',-text=>"Username")->pack(-side=>"left"),$bg);
	my $una = (FIO::config('DB','uname') or "");
	setBG($dia->add('Entry',-textvariable=>\$una)->pack(-side=>"left"),$bg);
	setBG($dia->add('Label',-text=>"Password")->pack(-side=>"left"),$bg);
	my $pwt;
	setBG($dia->add('Entry',-textvariable=>\$pwt,-show=>"*")->pack(-side=>"left"),$bg)->focus();
	$dia->Show();
	return $pwt;
}
print ".";

my $servers;
sub getServers {
	defined $servers and return $servers;
	$servers = Config::IniFiles->new();
	my $fn = (FIO::config('Disk','servers') or "servers.ini");
	$servers->SetFileName($fn);
	Common::infMes("Seeking server file...",1);
	if ( -s $fn ) {
		print "found. Loading...";
		$servers->ReadConfig();
	}
	return $servers;
}
print ".";

sub selectPalette {
	my ($t,@args) = @_;
	Common::showDebug('x') and print "selectPalette(" . ($args[0] or "") . ")\n";
	return unless defined $args[0]; # the background is required.
	my $palbox = cfp($t->Frame(-relief=>'ridge',-bd=>4),@args);
	my ($c,$r,$w) = (100,1,13);
	cfp($palbox->Label(-text=>"Select a color scheme:"),$args[0],'head',1,1,'n',-columnspan=>$w);
	my %cols = ( # mainbg, panebg, listbg, helpbg, buttonbg, entbg
		'Mono' => [qw(#EEF %main% %main% %main% %main% %main%)],
		'HiContrast' => [qw(#FFF #FFC #CFF #CFC #FCF #CCF)],
		'Green' => [qw(#CDD #3BDD2C #9BC999 #71C2BD #F3C77C #2DA47C)],
		'Lynx' => [qw(#bfc #6B6 #bfc #fff #ff0 #FF0 #005 #000 #000 #500 #0fc #050)],
		'Sunshine' => [qw(#acca7e #FF0 #dace33 #cf6422 #a39766 #66a871)],
		'Ocean' => [qw(#0ff #30d0b5 #64a9b7 #4579ad #55f #779)],
		'Flame' => [qw(#f00 #d86176 #fa0 #cee06b #df5 #ff6)],
		'Royal' => [qw(#d0f #c0f #e19fa3 #ae7c84 #b4b82f #62911c)],
	);
	sub setScheme {
		my ($m,$p,$l,$h,$b,$e,$mf,$pf,$lf,$hf,$bf,$ef) = @_;
		print "setScheme Rcvd $m $p $l $h $b $e...\n";
		my @args = ($m,$p,$l,$h,$b,$e,$mf,$pf,$lf,$hf,$bf,$ef);
		my @keys = qw(mainbg panebg listbg helpbg buttonbg entrybg mainfg panefg listfg helpfg buttonfg entryfg);
		foreach my $i (0..$#args) {
			next unless defined $args[$i]; # skip undefined colors.
			Common::showDebug('c') and print "Setting colors $keys[$i] to $args[$i].\n";
			FIO::config('UI',$keys[$i],$args[$i]);
		}
	}
	my %pa = (-fill=>'x',-expand=>1);
	foreach my $s (qw(Mono HiContrast Green Lynx Sunshine Ocean Flame Royal)) {
		if ($c > $w) {
			$c = 1;
			$r++;
			my $labs = cfp($palbox->Frame(),$args[0],'',$r,$c++);
			setBG($labs->Button(-text=>"",-state=>'disabled')->pack(%pa),$args[0]);
			setBG($labs->Label(-text=>"Main")->pack(%pa),$args[0]);
			setBG($labs->Label(-text=>"Pane")->pack(%pa),$args[0]);
			setBG($labs->Label(-text=>"List")->pack(%pa),$args[0]);
			setBG($labs->Label(-text=>"Help")->pack(%pa),$args[0]);
			setBG($labs->Label(-text=>"Button")->pack(%pa),$args[0]);
			setBG($labs->Label(-text=>"Entry")->pack(%pa),$args[0]);
		}
		print "Making button $s\n";
		my $x = cfp($palbox->Frame(-relief=>'groove',-bd=>2),$args[0],'',$r,$c);
		setBG($x->Button(-text=>$s, -command=>sub { setScheme(@{$cols{$s}}); TGK::pushStatus("Color scheme set to $s."); })->pack(%pa),'buttonbg');
		setBG($x->Label(-text=>"$cols{$s}[0]")->pack(%pa),$cols{$s}[0]);
		setBG($x->Label(-text=>"$cols{$s}[1]")->pack(%pa),$cols{$s}[1]);
		setBG($x->Label(-text=>$cols{$s}[2])->pack(%pa),$cols{$s}[2]);
		setBG($x->Label(-text=>$cols{$s}[3])->pack(%pa),$cols{$s}[3]);
		setBG($x->Label(-text=>$cols{$s}[4])->pack(%pa),$cols{$s}[4]);
		setBG($x->Label(-text=>$cols{$s}[5])->pack(%pa),$cols{$s}[5]);
		$c++;
	}
	$r++;
}
print ".";

sub selectDB {
	my ($parent,) = @_;
	my $bg = 'panebg';
	my $of = setBG($parent->Frame()->pack(-side=>'top',-fill=>'both',-expand=>1),$bg);
	cfp($of->Label(-text => "Welcome to " . main::myName() . ". Select your database options below.\n"),$bg,'body',1,1,'w',-columnspan=>3);
	# 1 SQL 2 COMMON 3 SQLITE
	cfp($of->Label(-text => "Database Type"),$bg,'body',2,2);
	my ($sb,$fb,$dbt,$dnt,$snt,$pwc,$unt,$pwe,$loadb,$adc);
	my $srvlst = getServers(); # use config with "servers.ini"
	# pull the config into a hash, then save the hash into the config
	my $sne = entryStack($of,"Host/filename",5,2,undef,\$snt,undef,$bg);
	$sne->configure(-validate => "key", -validatecommand => sub { my $new = shift; return 1 if $new eq ""; return 0 unless defined $loadb; $loadb->configure( -text => "Load " . ($dbt eq "L" ? "$new.dbl" : "$dnt\@$new")); return 1; });
	my $name = Sui::passData('dbname');
	defined $name and $dnt = $name;
	my $host = (Sui::passData('dbhost') or 'pantry');
	defined $host and $snt = $host;
	my $dne = entryStack($of,"Database Name",2,1,undef,\$dnt,undef,$bg);
	$dne->configure(-validate => "key", -validatecommand => sub { my $new = shift; return 1 if $new eq ""; return 0 unless defined $loadb; ($dbt eq "L"  or $loadb->configure( -text => "Load $new\@$snt")); return 1; });
	my $une = entryStack($of,"Username",4,1,undef,\$unt,undef,$bg);
	$pwc = (FIO::config('DB','pwp') or 0);
	my $pcb = cfp($of->Checkbutton(-text => "Password protected", -variable => \$pwc, -command => sub { groupable($pwc,$pwe); }),'panebg','body',6,1);
	$pwe = entryStack($of,"Password",7,1,undef,undef,undef,$bg);
	$pwe->configure(-show=>"*",-state=>($pwc ? 'normal' : 'disabled'), -width=>15);
	TGK::bindEnters($pwe,sub { $loadb->focus(); });
# TODO: Make checkbutton skipped in tab order, and give it an accelerator
	my @sgroup = ($dne,$une,$pcb,);
	my @fgroup = ();
	my @pgroup = ();
	$dbt = 'L';
	our $fails = 0;
	unless (defined FIO::config('UI','listbg')) {
		selectPalette($of,'panebg','',16,1,'n',-columnspan=>3);
		cfp($of->Label(-text=>"Individual colors can be changed in the options pane at any time."),'panebg','body',17,1,'n',-columnspan=>3);
	}
	$snt =~ s/\.dbl//; # we're about to add this on the button, so remove it if it's there.
	$loadb = cfp($of->Button(-text => "Load " . ($dbt eq "L" ? "$snt.dbl" : "$dnt\@$snt"), -command => sub {
	# dbtype host/file dbname password username
		$snt =~ s/\.dbl//; # we're about to add this, so remove it if it's there.
		my @args = (($dbt or FIO::config('DB','type') or 'L'),($dbt eq "L" ? "$snt.dbl" : $snt),);
		if ("$args[0]" eq "M") {
			push(@args,$dnt,($pwc ? $pwe->get() : undef),($unt eq "" ? undef : $unt));
		}
		my ($dbh,$err,$errstr) = FlexSQL::getDB(@args) or undef;
		sub saveAndPop {
			my ($t,$sdb,$adb,$dty,$dho,$una,$dbn,$pwp,$dbh) = @_;
			$sdb->destroy();
			TGK::pushStatus("Please wait while database information is saved.");
			# Save database information:
			FIO::config('DB','askDB',$adb); # show DB selection on startup
#			FIO::config('DB','askDB',1); # TODO: Check for password/username fail and set this to 1 in main. Then allow saving of 0.
			FIO::config('DB','type',$dty); # DB type
			FIO::config('DB','host',$dho); # DB hostname or filename
			FIO::config('DB','pwp',$pwp); # DB is password protected?
			defined $dbn and length($dbn) and FIO::config('DB','dbname',$dbn);
			defined $una and length($una) and FIO::config('DB','uname',$una);
			Common::showDebug('f') and print "Saving $adb:$una@$dho/$dbn " . ($pwp ? "Safe" : "Free") . " $dty\n";
			FIO::saveConf(); # keep DB for next time
			TGK::pushStatus("Loading GUI...");
			TGUI::populateMainWin($dbh,$t,0);
			TGK::pushStatus("Done.",1);
		}
		if ($err eq "") {
			saveAndPop($parent,$of,$adc,$args[0],$args[1],$unt,$dnt,$pwc,$dbh);
# TODO: accelerator, automatically check password button if password error, writecfg on sucessful db connection
		} elsif ("$err" eq "2") {
			print "((($errstr)))  ";
			TGK::pushStatus("Creating Database. This may take a moment.");
			($dbh,$err,$errstr) = FlexSQL::makeDB(@args) or undef;
			if (defined $dbh and "$err" eq "OK") {
				saveAndPop($parent,$of,$adc,$args[0],$args[1],$unt,$dnt,$pwc,$dbh);
			} else {
				$fails++;
				TGK::pushStatus("The selected database could not be loaded. Please try again. ($fails)");
				print "\n[E] Error loading database: $err. ($errstr)\n";
			}
		} else {
			print "\n[E] Error loading database: $err. ($errstr)\n";
		}
		return; }),'buttonbg','button',15,1,'we',-columnspan=>3);
	#TODO: Finish server selection box
	my $pbox = cfp($of->Frame(-relief=>'raised',-bd=>1),$bg,'',5,3,'ew',-rowspan=>5); # box for profiles
	our $pname = entryStack($of,"Profile Name",2,3,undef,undef,undef,'panebg'); # entry for profile name
	my $psave = cfp($of->Button(-text=>"Add/Save"),'buttonbg','button',4,3);# button to save new profile
	sub spro {
		my ($srv,$section,$key,$value) = @_;
		#print "spro($srv,$section,$key,$value)\n";
		unless (defined $value) {
			if (defined $srv->val($section,$key,undef)) {
				return $srv->val($section,$key);
			} else {
				return undef;
			}
		} else {
			if (defined $srv->val($section,$key,undef)) {
				return $srv->setval($section,$key,$value);
			} else {
				return $srv->newval($section,$key,$value);
			}
		}
	}
	our @pkeys = ();
	my $temp = (spro($srvlst,'Servers','list') or "");
	unless ($temp eq "") {
		push(@pkeys,split(':',$temp));
	}
	$psave->configure(-command => sub {
		my $proname = ($pname->get() or undef);
		return if ($proname eq undef or $proname eq "");
		return unless defined $snt and $snt ne '';
		$snt =~ s/\.dbl//; # we're going to add this, so remove it if it's there.
		my @args = (($dbt or FIO::config('DB','type') or 'L'),$snt,);
		spro($srvlst,$proname,'type',$args[0]);
		spro($srvlst,$proname,'host',$args[1]);
		if ("$args[0]" eq "M") {
			push(@args,$dnt,$pwc,($unt eq "" ? undef : $unt));
			spro($srvlst,$proname,'basename',$args[2]);
			spro($srvlst,$proname,'password',$args[3]);
			spro($srvlst,$proname,'username',$args[4]);
		}
		my $pos = Common::findIn($proname,@pkeys);
		unless ($pos > -1) { # name not found in list
			push(@pkeys,$proname);
			$pbox->Button(-text=>"$proname",-command=>sub {
				$pname->configure(-text=>"$proname"); $dbt = $args[0]; $snt = $args[1];
				$dnt = $args[2]; $pwc = $args[3]; $unt = $args[4];
				groupable(($dbt eq "L"),@fgroup,$sb); groupable(($dbt eq "M"),@sgroup,$fb);
				($pwc ? $pwe->focus() : $loadb->focus()); # Focus either the password field or the load button
			})->pack(-fill=>'x');
			my $temp = join(':',@pkeys);
			spro($srvlst,'Servers','list',$temp);
		}
		$srvlst->RewriteConfig();
	});
	foreach my $p (@pkeys) { # button for each server; push to @pgroup, on click, enable each @pgroup, disable self
		my ($pt,$ph,$pb,$pp,$pu,$pn); # variables for profile info. Each one is necessary for button to work properly.
		$pn = $p; # profile name
		next if ($pn eq undef or $pn eq ""); # Profile must have a name (not sure how it loaded without one)
		$pt = spro($srvlst,$pn,'type'); # DB type
		$ph = spro($srvlst,$pn,'host'); # DB host/filename
		$ph =~ s/\.dbl//; # we're about to add this, so remove it if it's there.
		next unless defined $ph and $ph ne ''; # profile must have a host/file name.
		if ("$pt" eq "M") { # MySQL database
			$pb = spro($srvlst,$pn,'basename'); # ... needs a base name
			$pp = spro($srvlst,$pn,'password'); # ... needs to know whether to send a password
			$pu = spro($srvlst,$pn,'username'); # ... needs to have a username
		} # ... but SQLite doesn't.
		setBGF($pbox->Button(-text=>"$pn",-command=>sub { # place a button for selection.
			$pname->configure(-text=>"$pn"); $dbt = $pt; $snt = $ph; # set profile name box, so if something changes on this host, it can be saved back to the same profile; change the DB type and hostname
			$dnt = $pb; $pwc = $pp; $unt = $pu; # set the basename, password checkbox, and username
			groupable($pwc,$pwe);
			groupable(($pt eq "L"),@fgroup,$sb); groupable(($pt eq "M"),@sgroup,$fb); # set the appopriate button disabled with its fields, if any.
			($pwc ? $pwe->focus() : $loadb->focus()); # Focus either the password field or the load button
		})->pack(-fill=>'x'),'buttonbg','button'); # set the button background and font.
	}
	cfp($of->Checkbutton(-text => "Ask for DB", -variable => \$adc),'panebg','body',7,2);
	$dbt = (FIO::config('DB','type') or 'L');
	$sb = cfp($of->Button(-text => "MySQL", -command => sub { groupable(0,@fgroup,$sb); groupable(1,@sgroup,$fb); $dbt = 'M'; }, -anchor => 'center'),'buttonbg','button',3,2,'ew');
	$fb = cfp($of->Button(-text => "SQLite", -command => sub { groupable(1,@fgroup,$sb); groupable(0,@sgroup,$fb); $dbt = 'L'; }, -anchor => 'center'),'buttonbg','button',4,2,'ew');
	$adc = FIO::config('DB','askDB'); # Ordinarily, this would always be 1, but in case I ever add a Change DB button, I'm pulling it from config.
	groupable(($dbt eq "L"),@fgroup,$sb); groupable(($dbt eq "M"),@sgroup,$fb);
	#my ($sb,$fb,$dbt,$dnt,$snt,$pwc,$unt,$pwe,$loadb,$adc);
	$dnt = (FIO::config('DB','dbname') or '');
	$snt = (FIO::config('DB','host') or 'pantry');
	$unt = (FIO::config('DB','uname') or '');
	($pwc ? $pwe->focus() : $loadb->focus()); # Focus either the password field or the load button
	return;
}
print ".";

sub groupable {
	my ($on,@list) = @_;
	foreach my $o (@list) {
		$on and $o->configure(-state => 'normal');
		$on or $o->configure(-state => 'disabled');
	}
}
print ".";

print " OK; ";
1;
