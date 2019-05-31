package TGUI;
print __PACKAGE__;

use Panini qw(Prod );
require Tk::BrowseEntry;

sub entryRow {
	my ($parent,$name,$r,$c,$s) = @_;
	my %args = ( -row => $r, -column => $c );
	my $lab = $parent->Label(-text=>"$name")->grid(%args);
	$args{-columnspan} = $s if defined $s;
	$args{-column}++;
	my $ent = $parent->Entry()->grid(%args);
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
	# bind enter here to a function that either adds one to the onhand,
	#	or if not found, pulls open the description entries below for saving.
	
	my $ne = entryRow($of,"Name: ",2,1);
	my $se = entryRow($of,"Size: ",3,1);
	my $ce = $of->BrowseEntry();
	$ce->grid(-row=>3,-column=>3);
	# Label: Qty: [ onhand ]
	my $okb = $of->Button(-text=>"Save");
	$okb->grid(-row=>5,-column=>4);
	
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
	showButtonPanel($win);
	showPantryLoader($win);
}
print ".";

print ".";
1;
