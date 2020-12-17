package Sui; # Self - Program-specific data storage
print __PACKAGE__;

=head1 Sui

Keeps common modules as clean as possible by storing program-specific
data needed by those common-module functions in a separate file.

=head2 passData STRING

Passes the data identified by STRING to the caller.
Returns some data block, usually an arrayref or hashref, but possibly
anything. Calling programs should be carefully written to expect what
they're asking for.

=cut

my %data = (
	disambiguations => {
		tag => ["tag_(context1)","tag_(context2)"],
		othertag => ["othertag_(context1)","othertag_(context2)"]
	},
	objectionablecontent => [],
	minchanged => 1,
	minindexed => 0,
	minimums => {},
);

sub passData {
	my $key = shift;
	for ($key) {
		if (/^opts$/) {
			return getOpts();
		} elsif (/^twidths$/) {
			return getTableWidths();
		} else {
			return $data{$key} or undef;
		}
	}
}
print ".";

sub storeData {
	my ($key,$value) = @_;
	defined $key and defined $value or return undef;
	return $data{$key} = $value;
}
print ".";

sub getOpts {
	# First hash key (when sorted) MUST be a label containing a key that corresponds to the INI Section for the options that follow it!
	# EACH Section needs a label conaining the Section name in the INI file where it resides.
	my %opts = (
		'000' => ['l',"General",'Main'],
		'001' => ['c',"Save window positions",'savepos'],
		'002' => ['c',"Errors are fatal",'fatalerr'],
		'006' => ['n',"Time Zone Offset (from GMT)",'tz',-6,-12,12,1,6],
		'009' => ['c',"Write config on exit",'writecfg',0],
		'00c' => ['n',"Left",'left',0,0,400,1,25],
		'00d' => ['n2',"Top",'top',0,0,400,1,25],
		'00a' => ['n',"Width",'width',640,0,4000,1,25],
		'00b' => ['n2',"Height",'height',480,0,3000,1,25],
		'00e' => ['n',"Left Offset",'xoff',0,0,80,1,25],
		'00f' => ['n2',"Top Offset",'yoff',0,0,80,1,25],
		

		'010' => ['l',"Fonts",'Font'],
		'011' => ['f',"Major heading font/size: ",'bighead',"Arial-24"],
		'012' => ['f',"General font/size: ",'body'],
		'013' => ['f',"Navigation font/size: ",'button'], # buttonfont
		'014' => ['f',"Special font/size: ",'special'], # for lack of a better term
		'015' => ['f',"Entry font/size: ",'entry'],
		'016' => ['f',"Listing font/size: ",'listfont'],
		'017' => ['f',"Heading font/size: ",'head'],
		'018' => ['f',"Sole-entry font/size: ",'bigent'],

		'020' => ['l',"File",'Disk'],
		'021' => ['t',"Database Lite files live here",'dbdir'],
		'022' => ['t',"Servers are stored in this file",'servers',"servers.ini"],
		
		'030' => ['l',"User Interface",'UI'],
		#'031' => ['t',"GUI",'GUI',"no"],
		'032' => ['n',"Shorten names to this length",'namelimit',20,15,100,1,10],
		'033' => ['c',"Show UPC on button",'buttonUPC',1],
		'034' => ['n',"Width of columns",'maxcolw',100,20,500,1,10],
		'035' => ['t',"Default page to load",'defaultpage'],
		'036' => ['c',"Show generic item in Cook tab",'showcookgeneric'],
		'03e' => ['x',"Background for list tables",'listbg',"%main%"],
		'03a' => ['x',"Background for main window",'mainbg',"#FDC"],
		'03b' => ['x',"Background for buttons",'buttonbg',"#CFC"],
		'03c' => ['x',"Background for help box",'helpbg',"%main%"],
		'03d' => ['x',"Background for panes",'panebg',"%main%"],
		'03f' => ['x',"Background for entry boxes",'entbg',"%main%"],
		'042' => ['n',"How many rows per column in file lists?",'filerows',10,3,30,1,5],
		'043' => ['t',"Color codes for gradient (comma separated)",'gradient'],
		'044' => ['c',"Show Page Step Buttons on numeric rows",'showpstep'],
		# hintfore
		# hintback

		'050' => ['l',"Database",'DB'],
		'051' => ['t',"Connection",'type'], # TODO: Change to combobox
		'052' => ['c',"Ask before connecting",'askDB'],
		'053' => ['c2',"Store FL OZ as OZ",'unifyoz',1],
		'054' => ['c3',"Generics stored lowercase",'lcgeneric',0],
		'055' => ['t',"Server",'host'],
		'056' => ['t',"Username",'uname'],
		#dbname,pwp,

		'060' => ['l',"Inventory Management",'Rules'],
		'061' => ['c',"Show barely fulfilled items on restock list",'beloworat',0],
		'062' => ['n',"Add to shopping count over minimum",'sparecount',0,0,100,1,10],
		'064' => ['n2',"Days for long-term price average",'longdays',90,7,365,1,10],
		'063' => ['n',"Count for short-term price average",'shortcount',25,3,97,1,5],

		'100' => ['l',"Network",'Net'],
		'101' => ['c',"Save bandwidth by saving image thumbnails",'savethumbs'],
		'102' => ['t',"Thumbnail Directory",'thumbdir'],
		'103' => ['n',"File argument Style",'wierdRL'], # 0 = xxx.png, 1 = xxx.png?dl=1, 2 = view?asset=xxxx, 3 = view.png?asset=xxxx

		'870' => ['l',"Custom Text",'Custom'],
		'87f' => ['t',"Options dialog",'options'],
		'871' => ['t',"Sample Text for fonts",'fontsamp'],
		'872' => ['h',"","","Button","","Heading"],
		'873' => ['t',"Where items are added",'itemadd'],
		'875' => ['t',"Where prices are added",'priceadd'],
		'877' => ['t',"Where contents are shown",'pantrylist'],
		'879' => ['t',"Where unmet mins are listed",'buylist'],
		'87b' => ['t',"Where recipes are priced",'recipe'],
		'87d' => ['t',"Where items are updated",'editor'],
		'874' => ['t2',"",'itemhead'],
		'876' => ['t2',"",'pricehead'],
		'878' => ['t2',"",'listhead'],
		'87a' => ['t2',"",'shophead'],
		'87c' => ['t2',"",'planhead'],
		'87e' => ['t2',"",'edithead'],
		#program
		#TODO: Custom text for each button and page heading

		'ff0' => ['l',"Debug Options",'Debug'],
		'ff1' => ['c',"Colored terminal output",'termcolors'],
		'ff2' => ['n',"Verbosity of debug output",'v',0,0,7,1,3],
	);
	return %opts;
}
print ".";

sub getDefaults {
	return (
		['Main','savepos',1],
		['Main','width',980],
		['Main','height',640],
		['UI','GUI','tk'],
		['Font','bighead',"Verdana 24"],
		['Font','button',"Verdana 12"],
		['Main','tz',-6],
		['Net','savethumbs',1],
		['Net','thumbdir',"itn"],
		['DB','lcgeneric',1],
		['DB','askDB',1],
		['UI','mainbg',"#FED"],
		['UI','gradient',"#F00,#F30,#F60,#F90,#FC0,#FF0,#CF0,#9F0,#6F0,#3F0,#0F0,#0F3,#0F6,#0F9,#0FC,#0FF,#0CF,#09F,#06F,#03F,#00F,#30F,#60F,#90F,#C0F,#F0F,#F0C,#F09,#F06,#F03,#EEF,#DDE,#CCD,#BBC,#AAB,#99A,#889,#778,#667,#556,#445,#334,#223,#112,#001"],
	);
}
print ".";

my %outputstore = (
	'facprice' => [],
);

sub registerOutputs {
	my ($key,$object) = @_;
	unless (exists $outputstore{$key}) {
		$outputstore{$key} = [];
	}
	push(@{ $outputstore{$key} },$object);
}
print ".";

sub getOutputs {
	my ($key) = @_;
	return ($outputstore{$key} or []);
}
print ".";

sub poll {
	my ($key,$object) = @_;
	my $input = passData($key);
	$object->poll($input);
}
print ".";

sub aboutMeText {
	return "\n" . main::myName(1) . "\n PANINI: Pantry Inventory Information system.\nThis program exists to allow you to catalogue your pantry, make up shopping\n"
	. " lists, and track prices at different stores.\nI hope you enjoy it.\n"
	. " You can use PLUs, UPCs in most formats, or private item numbers.\n"
	. " If you'd like to see a feature added to this program, please visit\n"
	. " https://github.com/over2sd/panini/issue and create a 'new issue' with the\n"
	. " 'Feature Request' label.";
}
print ".";

print "OK; ";
1;
