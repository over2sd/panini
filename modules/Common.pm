package Common;
print __PACKAGE__;

use strict;
use Exporter qw(import);
our @EXPORT = qw( infMes getColorsbyName missing );

my $debug = main::howVerbose();
my @obj = @{ Sui::passData('objectionablecontent') };
my %objindex;
$objindex{@obj} = (0..$#obj);
# used by contentMask and by contentList
sub contentMask {
	my ($key,$mask) = @_;
	# get position, or position just outside the array
	# (won't bother getBit, but beware using this return value elsewhere!)
	my $pos = get(\%objindex,$key,scalar @obj);
	unless (defined $mask) { return $pos; }
	return getBit($pos,$mask); # if passed a mask, return true/false that that key's bit is set in the mask.
}
print ".";

# contentList can be used by option setter to choose which types of content to allow to be noted/flitered
sub contentList { return @obj; }
print ".";

sub getBit { # returns bool
	my ($pos,$mask) = @_;
	$pos = 2**$pos;
	return ($mask & $pos) == $pos ? 1 : 0;
}
print ".";

sub setBit { # returns mask
	my ($pos,$mask) = @_;
	$pos = 2**$pos;
	return $mask | $pos;
}

sub unsetBit { # returns mask
	my ($pos,$mask) = @_;
	$pos = 2**$pos;
	return $mask ^ $pos;
}
print ".";

sub toggleBit { # returns mask
	my ($pos,$mask) = @_;
	$pos = 2**$pos;
	$pos = $mask & $pos ? $pos : $pos * -1;
	return $mask + $pos;
}
print ".";

sub expandMask { # returns array
	my ($mask,$size) = @_;
	defined($size) || ($size = 8);
	my @bitlist = (0 .. $size-1);
	my @bits;
	foreach my $b (@bitlist) {
		push(@bits,$b) if getBit($b,$mask);
	}
	return @bits;
}

sub fmod { # useful for working with fractional values, since x%y may return int.
	use POSIX qw( floor );
	my ($x,$y,$both) = @_;
	errSpecial("db0e") unless $y; # death by zero division
	my $q = floor($x/$y);
	my $r = $x - ($y*$q);
	return ($both ? ($r,$q) : $r); # mostly, we'll just want the remainder
}

sub get {
	my ($hr,$key,$dv) = @_;
	if ((not defined $hr) or (not defined $key) or (not defined $dv)) {
		$hr = 'undef' unless defined $hr; $key = 'undef' unless defined $key; $dv = 'undef' unless defined $dv;
		warn "Safe getter called without required parameter(s)! ($hr,$key,$dv)";
		return undef;
	}
	if (exists $hr->{$key}) {
		return $hr->{$key};
	} else {
		return $dv;
	}
}
print ".";

sub loadSeedsFrom {
	my @ls;
	my $fn = shift;
	my $fail = 0;
    open (INFILE, "<$fn") || ($fail = 1);
	if ($fail) { print "Dying of file error: $! Woe, I am slain!"; exit(-1); }
	while(<INFILE>) {
		my($line) = $_;
		chomp($line);
		if ($line =~ m/^((, ?)?-?\d)*$/) {
			my @nums = split(',',$line);
			foreach my $i (@nums) {
				push(@ls,int($i));
			}
		} elsif ($line =~ m/^-?\d+\s?\.\.\s?-?\d+$/) { # 1 .. 10 sequence
			$line =~ s/\.\./;/;
			my @nums = split(';',$line); # TODO: sanity checking here
			my @range = (int($nums[0]) .. int($nums[1]));
			push(@ls,@range);
		} elsif ($line eq '') {
			# Skipping empty line
		} else {
			print "Bad seed in line: $line\n";
		}
	}
	return @ls;
}

=item selectWidth()
	Given an increment and a total number of units in the rectangle, returns a logical width for smallest total rectangle area.
=cut
sub selectWidth {
	my $w = 1;
	my ($increment,$total) = @_;
	my @breaks = (0,1,4,9,16,25,36,49,64,81,100,121,144);
	foreach my $b (0 .. $#breaks) {
		if ($total <= $breaks[$b]) {
			$w = $b;
			last;
		} else {
			# do nothing
		}
	}
	#print "Width: $w * $increment";
	$w *= $increment; # for units, use increment = 1.
	#print " = $w\n";
	return $w;
}

# I've pulled these three functions into so many projects, I ought to release them as part of a library.
sub getColorsbyName {
	my $name = shift;
	my @colnames = qw( base red green yellow blue purple cyan ltred ltgreen ltyellow ltblue pink ltcyan white bluong blkrev gray );
	my $ccode = -1;
	++$ccode until $ccode > $#colnames or $colnames[$ccode] eq $name;
	$ccode = ($ccode > $#colnames) ? 0 : $ccode;
	return getColors($ccode);
}
print ".";

my $bwterm = eval { require Win32; };
sub getColors{
	if (0) { # TODO: check for terminal color compatibility
		return "";
	}
	my ($index,$hex,$force) = @_;
	my @colors = ($hex ? ("#aaaaaa","#aa0000","#00aa00","#aa5500","#0000aa","#aa00aa","#00aaaa","#aaaaaa","#ff5555","#55ff55","#ffff55","#5555ff","#ff55ff","#55ffff","#ffffff","#0000ff","#000000","#555555") : ("\033[0;37;40m","\033[0;31;40m","\033[0;32;40m","\033[0;33;40m","\033[0;34;40m","\033[0;35;40m","\033[0;36;40m","\033[1;31;40m","\033[1;32;40m","\033[1;33;40m","\033[1;34;40m","\033[1;35;40m","\033[1;36;40m","\033[1;37;40m","\033[0;34;47m","\033[7;37;40m","\033[1;30;40m"));
	return '' if ($bwterm && !$force);
	if ($index >= scalar @colors) {
		$index = $index % scalar @colors;
	}
	if (defined($index)) {
		return $colors[int($index)];
	} else {
		return @colors;
	}
}
print ".";

sub missing { # useful if multiple values must be checked in one conditional
	my ($sCat,$blankok) = @_;
	return 1 unless(defined $sCat); # not defined: TRUE
	return 1 unless($sCat ne "" || $blankok); # blank: TRUE unless blank is ok.
	return 0; # defined an not blank: FALSE
}
print ".";

sub findIn {
	my ($v,@a) = @_;
	if (defined $debug && $debug > 0) {
		use Data::Dumper;
		print ">>".Dumper @a;
		print "($v)<<";
	}
	unless (defined $a[$#a] and defined $v) {
#		print "Found '$v' (" . @a . ")\n";
		die "FATAL: findIn requires a \$SCALAR and an \@ARRAY (was given '" . $v . "' and '" . @a . "' at " . lineNo() . "\n";
		return -1;
	}
	my $i = 0;
	while ($i < scalar @a) {
		print ":$i:" if $debug > 0;
		if ("$a[$i]" eq "$v") { return $i; }
		$i++;
	}
	return -1;
}
print ".";

sub between {
	my ($unk,$bound1,$bound2,$exclusive,$fuzziness) = @_;
	$fuzziness = 0 if not defined $fuzziness;
	if ($unk < min($bound1,$bound2) - $fuzziness or $unk > max($bound1,$bound2) + $fuzziness) {
		return 0; # out of range
	}
	if (defined $exclusive and $exclusive == 1 and ($unk == $bound1 or $unk == $bound2)) {
		return 0; # not between but on one boundary
	}
	return 1; # in range
}

sub nround {
	my ($prec,$value) = @_;
	use Math::Round qw( nearest );
	my $target = 1;
	while ($prec > 0) { $target /= 10; $prec--; }
	while ($prec < 0) { $target *= 10; $prec++; } # negative precision gives 10s, 100s, etc.
	if ($debug) { print "Value $value rounded to $target: " . nearest($target,$value) . ".\n"; }
	return nearest($target,$value);
}
print ".";

# Perhaps this should be loaded from an external file, so the user can modify it without diving into code?
my %ambiguous = %{ Sui::passData('disambiguations') };
sub disambig {
	# if given a gui reference, display an askbox to select from options for disambiguation
	# if tag is key in hash, return first value; otherwise, return tag
}
print ".";

sub revGet { # works best on a 1:1 hash
	my ($target,$default,%hash) = @_;
	foreach (keys %hash) {
		return $_ if ($target eq $hash{$_});
	}
	return $default;
}
print ".";

=item indexOrder()
	Expects a reference to a hash that contains hashes of data as from fetchall_hashref.
	This function will return an array of keys ordered by whichever internal hash key you provide.
	@array from indexOrder($hashref,$]second-level key by which to sort first-level keys[)
=cut
sub indexOrder {
	my ($hr,$orderkey) = @_;
	my %hok;
	foreach (keys %$hr) {
		my $val = $_;
		my $key = qq( $$hr{$_}{$orderkey} );
		$hok{$key} = [] unless exists $hok{$key};
		push(@{ $hok{$key} },$val); # handles identical values without overwriting key
	}
	my @keys;
	foreach (sort keys %hok){
		push(@keys,@{ $hok{$_} });
	}
	return @keys;
}
print ".";

=item shorten TEXT MAXLENGTH POSTLENGTH

Given a string TEXT and two integers MAXLENGTH for the shortened length and POSTLENGTH for the number of characters after the ellipsis,
shortens a string by inserting ellipsis into it.
Returns a shortened STRING.

 shorten("Thomas Edward Robinson",15); 							      # returns Thomas Edwa... (default endlength of 7 requires a max length of at least 17 to not leave the end off)
 shorten("Ozymandius the Magnificent, Gracious, and Longwinded,20,3); # returns Ozymandius the...ded
 shorten("The Great and Powerful Oz",20,5); 						  # returns The Great an...ul Oz

=cut

sub shorten {
	my ($text,$len,$endlen) = @_;
	return $text unless (defined $text and length($text) > $len); # don't do anything unless text is too long.
	my $part2length = ($endlen or 7); # how many characters after the ellipsis?
	my $part1length = $len - ($part2length + 3); # how many characters before the ellipsis?
	if ($part1length < $part2length) { # if string would be lopsided (end part longer than beginning)
		$part2length = 0; # end with ellipsis instead of string ending
		$part1length = $len - 3;
	}
	if ($part1length < 7 or $part1length + 3 > $len - $part2length) { # resulting string is too short, or doesn't chop off enough for ellipsis to make sense.
		warn "Shortening string of length " . length($text) . " ($text) to $len does not make sense. Skipping.\n";
		return $text;
	}
	my $part2 = ($part2length ? substr($text,-$part2length) : ""); # part after ...
	$text = sprintf("%.${part1length}s...$part2",$text); # strung together with ...
	return $text;
}
print ".";

sub getAge {
	my $dob = shift; # expects date as "YYYY-MM-DD" or "YYYYMMDD"
	use DateTime;
	return undef unless (defined $dob and $dob ne '');
	$dob =~ s/\//-/g; # prevents failure if date sent with slashes. Silly user.
	$dob=~/([0-9]{4})-?([0-9]{2})-?([0-9]{2})/; # DATE field format from MySQL. May not work for other sources of date.
	return undef unless (defined $1 and defined $2 and defined $3); # prevents a segfault if date sent with bad format
	my @maxdays = (0,31,28,31,30,31,30,31,31,30,31,30,31);
	$maxdays[2] = 29 if (($1%400 == 0) || ($1%4 == 0 && $1%100 != 0));
	return undef if (int($2) > 12 or $3 > $maxdays[int($2)]); # Prevents a segfault if date sent is out of bounds, like 9999-99-99
	my $start = DateTime->new( year => $1, month => $2, day => $3);
#	$start->add( days => 1 ) if $leapday;
	my $end = DateTime->now;
	my $age = $end - $start;
	return $age->in_units('years');
}
print ".";

sub stripDOBdashes {
	my $dob = shift; # expects date as "YYYY-MM-DD" or "YYYYMMDD"
	$dob=~/([0-9]{4})-?([0-9]{2})-?([0-9]{2})/; # DATE field format from MySQL. May not work for other sources of date.
	return "$1$2$3";
}
print ".";

=item DoBrangefromAges REFERENCEDATE MINAGE MAXAGE
Given a REFERENCEDATE from which to calculate, minimum age MINAGE, and
an optional maximum age MAXAGE, this function returns two strings in
YYYY-MM-DD format, suitable for use in SQL queries, e.g., 'WHERE ?<dob
AND dob<?', using the return values in order as parameters. If no
MAXAGE is given, date range is for the year spanning MINAGE only.
=cut
sub DoBrangefromAges {
	my ($querydate,$agemin,$agemax,$inclusive) = @_;
	die "[E] Minimum age omitted in DoBrangefromAges" unless (defined $agemin and $agemin ne '');
	$agemin = int($agemin);
	$agemax = int($agemin) unless defined $agemax;
	$agemax = int($agemax);
	$inclusive = ($inclusive ? $inclusive : 0);
	my ($maxdob,$mindob) = ($querydate,$querydate);
	$maxdob->subtract(years => $agemin);
	$mindob->subtract(years => $agemax + 1);
	return $mindob->ymd('-'),$maxdob->ymd('-');
}
print ".";

=item registerErrors FUNCTION ARRAY
Given an ARRAY of error texts and a FUNCTION name, stores error texts
for later display on error.
=cut
my %errorcodelist;
sub registerErrors {
	my ($func,@errors) = @_;
	$errorcodelist{$func} = ['',] unless defined $errorcodelist{$func}; # prepare if no codes on record.
	print "\n - Registering error codes for $func:" if main::howVerbose() > 8; # "\n";
	my ($col,$base) = (getColors(5),getColorsbyName('base'));
	foreach (0 .. $#errors) {
#		printf(" %d",$_ + 1); # "\t" . $_ + 1 . ": $errors[$_]\n";
		$errorcodelist{$func}[$_ + 1] = $errors[$_];
		print "$col-$base" if main::howVerbose() > 6;
	}
#	print "\n";
}
print ".";

=item registerZero FUNCTION DISPLAY
This function registers errorcode for result of 0. Useful for either
success or failure code of 0 (e.g. 0 results).
=cut
sub registerZero {
	my ($func,$text) = @_;
	$errorcodelist{$func} = ['',] unless defined $errorcodelist{$func}; # prepare if no codes on record.
	$errorcodelist{$func}[0] = $text;
	my ($col,$base) = (getColors(6),getColorsbyName('base'));
	print "$col+$base" if main::howVerbose() > 6;
}
print ".";

sub errorOut {
	my ($func,$code,%args) = @_;
	my $str = ($args{string} or undef);
	my $trace = ($args{trace} or 0);
	unless (defined $func and defined $code) {
		warn "errorOut called without required parameters";
		return 1;
	}
#		use FIO qw( config ); # TODO: Fail gracefully here (eval?)
	my $fatal = (defined $args{fatal} ? $args{fatal} : (FIO::config('Main','fatalerr') or 0 ));
	my $color = (defined $args{color} ? $args{color} : (FIO::config('Debug','termcolors') or 1));
	my $error = qq{errorOut could not find error code $code associated with $func};
	unless (defined $errorcodelist{$func} or $func eq 'inline') {
		warn $error;
		return 2;
	}
	my @list = ($func eq 'inline' ? (($args{string} or "[E] Oops!")) : @{ $errorcodelist{$func} });
	unless (int($code) < scalar @list) {
		if ($list[$#list] =~ m/%d/) { # Test for %d in final error code.
			$code = $#list; # If found, use it as generic error message.
		} else {
			warn $error;
			return 2;
		}
	}
	# actually registered error codes:
	$error = $list[int($code)];
	if ($trace) {
		$error = $error . lineNo($args{depth} or 1);
	}
	$error =~ s/%d/$code/; # replace %d with $code
	if (defined $str) {
		$str = $func if ($str eq '%self');
		$error =~ s/%s/$str/; # replace %s with given string
	}
	my $nl = ($error =~ m/^\n/ ? 1 : 0); # allow string to begin with newline
	if ($error =~ m/^\n?\[E\]/) { # error
		$color = ($color ? 1 : 0);
		($fatal ? die errColor($error,$color,$nl,$args{gobj}) : warn errColor($error,$color,$nl,$args{gobj}));
	} elsif ($error =~ m/^\n?\[W\]/) { # warning
		$color = ($color ? 3 : 0);
		($fatal ? warn errColor($error,$color,$nl,$args{gobj}) : print errColor($error,$color,$nl,$args{gobj}));
	} elsif ($error =~ m/^\n?\[I\]/) { # information
		$color = ($color ? 2 : 0);
		my $lf = (($args{continues} or 0) ? "" : "\n");
		print errColor($error . $lf,$color,$nl,$args{gobj});
	} else { # unformatted (malformed) error
		defined $args{gobj} and $args{gobj}->push($error) and return;
		print $error;
	}
}
print ".";

sub errSpecial {
	my ($error) = @_;
	if ($error eq "db0e") {
		Common::errorOut('inline',0,color => 1, fatal => 1, string => "\n[E] You have attempted to divide by 0 " . lineNo());
	}
}
print ".";

sub infMes {
	my ($text,$continue,%args) = @_;
	defined $continue and $args{continues} = $continue;
	Common::errorOut('inline',0,color => 1, fatal => 0, string => "\n[I] $text", %args);
}
print ".";

sub errColor {
	my ($string,$color,$nl,$gobj) = @_;
	my ($col,$base) = (getColors($color),getColorsbyName('base'));
	my $colstring = substr($string,0,1 + $nl) . $col . substr($string,1 + $nl,1) . $base . substr($string,2 + $nl);
	if (defined $gobj) {
		$string = substr($string,1);
		$gobj->push($string) or $gobj->text($string);
		return ""; # we just printed it to the GUI object; no need to print it.
	}
	return ($color ? $colstring : $string);
}
print ".";

sub findClosest {
	my ($v,@ordered) = @_;
	if ($debug > 0) {
		use Data::Dumper;
		print ">>".Dumper @ordered;
		print "($v)<<";
	}
	unless (defined $ordered[$#ordered] and defined $v) {
		use Carp qw( croak );
		my @loc = caller(0);
		my $line = $loc[2];
		@loc = caller(1);
		my $file = $loc[1];
		my $func = $loc[3];
		croak("FATAL: findClosest was not sent a \$SCALAR and an ordered \@ARRAY as required from line $line of $func in $file. Caught");
		return -1;
	}
	my $i = 0;
	my $diffunder = $v;
	while ($i < scalar @ordered) {
		print ":$i:" if $debug > 0;
		if ($ordered[$i] < $v) {
			$diffunder = $v - $ordered[$i];
			$i++;
			next;
		} else {
			my $diffover = $ordered[$i] - $v;
			if ($diffover > $diffunder) { return $i - 1; }
			return $i;
		}
	}
	return -1;
}

=item vary()
	Vary an input ($base) by +/- an amount ($variance).
	Returns altered input.
=cut
sub vary {
	my ($base,$variance) = @_;
	$base -= $variance;
	$base += rand(2 * $variance);
	return $base;
}

sub listSort {
	use POSIX qw( floor );
	my ($index,@array) = @_;
	if (@array <= 1) { return \@array,$index; } # already sorted if length 0-1
	unless (defined $index) { $index = (); }
	my (@la,@ra,@li,@ri);
	my $mid = floor(@array/2) - 1;
#	print "Trying: $mid/$#array/" . $#{$index} . "\n";
	@la = ($mid <= $#array ? @array[0 .. $mid] : @la);
	@ra = ($mid + 1 <= $#array ? @array[$mid + 1 .. $#array] : @ra);
	@li = ($mid <= $#{$index} ? @$index[0 .. $mid] : @li);
	@ri = ($mid + 1 <= $#{$index} ? @$index[$mid + 1 .. $#{$index}] : @ri);
	my ($la,$li) = listSort(\@li,@la);
	my ($ra,$ri) = listSort(\@ri,@ra);
	my ($outa,$outi) = listMerge($la,$ra,$li,$ri);
	return ($outa,$outi);
}

sub listMerge {
	my ($left,$right,$lind,$rind) = @_;
	my (@oa,@oi);
	while (@$left or @$right) {
		if (@$left and @$right) {
			if (@$lind[0] < @$rind[0]) {
				push(@oa,shift(@$left));
				push(@oi,shift(@$lind));
			} else {
				push(@oa,shift(@$right));
				push(@oi,shift(@$rind));
			}
		} elsif (@$left) {
			push(@oa,shift(@$left));
			if (@$lind) { push(@oi,shift(@$lind)); }
		} elsif (@$right) {
			push(@oa,shift(@$right));
			if (@$rind) { push(@oi,shift(@$rind)); }
		}
	}
	return \@oa,\@oi;
}

sub listUnsort { # Fisher-Yates shuffle
my $limit = 0;
	my $ar = shift;
	my $i = @$ar; #start at end
	while (--$i) { # moving pointer backward
		my $j = int(rand($i+1)); # pick a random number between pointer and start
		@$ar[$i,$j] = @$ar[$j,$i]; # swap these two
return if ($limit++ > 200);
	}
	return 0; # success
}
print ".";

sub sequenceAoA {
	my ($aoa,$styp,$seed,$missing) = @_;
	$seed or ($seed = (time() + scalar @$aoa % int $styp));
	srand($seed) unless ($seed < 0); # option to set seed.
	my @newa = ();
	my @widths = ();
	my $widest = -1;
	my $rows = @$aoa;
	my $limit = 0;
	foreach my $k (0..$#$aoa) {
		push(@widths,scalar @{$$aoa[$k]});
		$widest = ($widest > $widths[$#widths] ? $widest : $widths[$#widths]);
	}
	my @roworder = (0..$#$aoa);
	listUnsort(\@roworder); # shuffle rows
	for ($styp) { # 0 is under 4.
		if (/1/ ) { # striped = 1-3,2-3,3-3,1-1,2-1,3-1,1-2,2-2,3-2... random column, carried through each row
			my @columns = (0..$widest-1);
			listUnsort(\@columns); # shuffle columns
			foreach my $c (@columns) { # for each random column
				foreach my $r (0..$#$aoa) { # for each row in order
					next if ($c >= $widths[$r] && not defined $missing); # skip if row not wide enough
					$c = (int($missing) == 0 ? $widths[$r] : $c % $widths[$r] - 1) if ($c >= $widths[$r]); # allow user to select 0: last available or nonzero: modulo of given column
					push(@newa,$$aoa[$r][$c]); # copy item from this row/column
				}
			}
		} elsif (/2/ ) { # grouped = 2-1,2-3,2-2,3-2,3-1,3-3,1-2,1-1,1-3... random rows, random column in each row
			foreach my $r (@roworder) { # in each row...
				my @columns = (0..$widths[$r]-1); # get column numbers...
				listUnsort(\@columns); # shuffle column numbers...
				foreach my $c (@columns) { # take each selected column...
					push(@newa,$$aoa[$r][$c]); # copy item from this row/column
				}
			}
		} elsif (/3/ ) { # mixed = 2-3,3-1,1-2,3-3,2-1,1-1,3-2,2-2... random order, but a different row each item
			my @columns = ();
			foreach my $r (0..$#$aoa) { # for each row
				my @row = (0..$widths[$r]-1); # get this row's indices
				listUnsort(\@row); # shuffle this row
				push(@columns,\@row); # add row to row record
			}
			my $total = 0;
			foreach my $r (0..$#widths) {
				$total += $widths[$r];
			}
			while ($total > 0) {
				foreach my $r (@roworder) {
					my $c = $columns[$r];
					if (scalar @$c) {
						my $i = shift @$c;
						$total--; $widths[$r]--;
#						print "\n$r-$i ";
						push(@newa,$$aoa[$r][$i]);
					}
				}
				listUnsort(\@roworder); # shuffle rows
			}
			foreach my $r (@roworder) { # clean up last few items that might be left: (shouldn't happen now)
				my $c = $columns[$r];
				if (scalar @$c) {
					my $i = shift @$c;
					$widths[$r]--;
					print "\n$r-$i\n";
					push(@newa,$$aoa[$r][$i]);
				}
			}
		} elsif (/[04]/ ) { # none,sequenced
			foreach my $r (@$aoa) { # sequenced = 1-1,1-2,1-3,2-1,2-2,2-3,3-1,3-2,3-3... each column of each row in original order
				foreach my $c (@$r) {
					push(@newa,$c);
				}
			}
			listUnsort(\@newa) if ($styp == 0); # none = 2-1,3-2,3-3,2-2,2-3,1-3,3-1,1-1,2-1,1-2... completely random order
		}
	}
	return @newa;
}
print ".";

sub sequenceHoA {
	my ($hoa,$styp,$aok,$seed) = @_;
	$seed or ($seed = (time() + scalar $hoa % int $styp));
	srand($seed) unless ($seed < 0); # option to set seed.
	my @newa = ();
	my @widths = ();
	my $widest = -1;
	my $rows = @$aok;
	my $limit = 0;
	foreach my $k (@$aok) {
		push(@widths,scalar @{$$hoa{$k}});
		$widest = ($widest > $widths[$#widths] ? $widest : $widths[$#widths]);
	}
	my @roworder = (0..$#$aok);
	listUnsort(\@roworder); # shuffle rows
	for ($styp) { # 0 is under 4.
		if (/1/ ) { # striped = 1-3,2-3,3-3,1-1,2-1,3-1,1-2,2-2,3-2... random column, carried through each row
			my @columns = (0..$widest-1);
			listUnsort(\@columns); # shuffle columns
			foreach my $c (@columns) { # for each random column
				foreach my $r (0..$#$aok) { # for each row in order
					next if ($c >= $widths[$r]); # skip if row not wide enough
					push(@newa,$$hoa{$$aok[$r]}[$c]); # copy item from this row/column
				}
			}
		} elsif (/2/ ) { # grouped = 2-1,2-3,2-2,3-2,3-1,3-3,1-2,1-1,1-3... random rows, random column in each row
			foreach my $r (@roworder) { # in each row...
				my @columns = (0..$widths[$r]-1); # get column numbers...
				listUnsort(\@columns); # shuffle column numbers...
				foreach my $c (@columns) { # take each selected column...
					push(@newa,$$hoa{$$aok[$r]}[$c]); # copy item from this row/column
				}
			}
		} elsif (/3/ ) { # mixed = 2-3,3-1,1-2,3-3,2-1,1-1,3-2,2-2... random order, but a different row each item
			my @columns = ();
			foreach my $r (0..$#$aok) { # for each row
				my @row = (0..$widths[$r]-1); # get this row's indices
				listUnsort(\@row); # shuffle this row
				push(@columns,\@row); # add row to row record
			}
			my $total = 0;
			foreach my $r (0..$#widths) {
				$total += $widths[$r];
			}
			while ($total > 0) {
				foreach my $r (@roworder) {
					my $c = $columns[$r];
					if (scalar @$c) {
						my $i = shift @$c;
						$total--; $widths[$r]--;
#						print "\n$r-$i ";
						push(@newa,$$hoa{$$aok[$r]}[$i]);
					}
				}
				listUnsort(\@roworder); # shuffle rows
			}
			foreach my $r (@roworder) { # clean up last few items that might be left: (shouldn't happen now)
				my $c = $columns[$r];
				if (scalar @$c) {
					my $i = shift @$c;
					$widths[$r]--;
					print "\n$r-$i\n";
					push(@newa,$$hoa{$$aok[$r]}[$i]);
				}
			}
		} elsif (/[04]/ ) { # none,sequenced
			foreach my $r (@$aok) { # sequenced = 1-1,1-2,1-3,2-1,2-2,2-3,3-1,3-2,3-3... each column of each row in original order
				foreach my $c (@{$$hoa{$r}}) {
					push(@newa,$c);
				}
			}
			listUnsort(\@newa) if ($styp == 0); # none = 2-1,3-2,3-3,2-2,2-3,1-3,3-1,1-1,2-1,1-2... completely random order
		}
	}
	return @newa;
}
print ".";

sub lineNo {
	my $depth = shift;
	$depth = 1 unless defined $depth;
	use Carp qw( croak );
	my @loc = caller($depth);
	my $line = $loc[2];
	my $file = $loc[1];
	@loc = caller($depth + 1);
	my $sub = $loc[3];
	if ($sub ne '') {
		@loc = split("::",$sub);
		$sub = $loc[$#loc];
	} else {
		$sub = "(MAIN)";
	}
	return qq{ at line $line of $sub in $file.\n };
}
print ".";

sub defineAllValues {
	my $ref = shift;
	foreach (keys %{ $ref }) {
#print $_ unless defined $$ref{$_};
		$$ref{$_} = '' unless defined $$ref{$_};
	}
}
print ".";

sub median {
	my ($aref,$default) = @_;
	return $default unless (defined $aref and @$aref);
	my $midpoint = int(@$aref /2);
	my @sortedscores = sort { $a <=> $b } @$aref;
	if ($midpoint % 2) {
		return $sortedscores[$midpoint];
	} else {
		return ($sortedscores[$midpoint] + $sortedscores[$midpoint-1])/2;
	}
}
print ".";

sub today {
	my ($y,$m,$d) = (localtime)[5,4,3];
	return sprintf('%d-%02d-%02d', $y+1900, $m+1, $d);
}
print ".";

# new for castagogue
=item RSSclean()
	Remove troublesome characters from CDATA/PCDATA ($in).
	Returns altered input.
=cut
sub RSSclean {
my ($in,$zealous) = @_;
	$in =~ s/\015\012?/\012/g; # CR or CRLF to LF
	$in =~ s/&(?!(?:[a-zA-Z0-9]+|#\d+);)/&#x26;/g unless ($zealous); # Lonely Ampersand
	$in =~ s/(#x26;){2}/#x26;/g; # Too much ampersand processing
	return $in;
}
print ".";

sub pad { # recipe from perlfaq (READ" pad TEXT to LENGTH with CHAR
	my ($text,$pad_len,$filler,$after) = @_;
	# TODO: divide pad_len by length of filler for pad patterns instead of characters.
	unless (defined $after and $after) {
		substr( $text, 0, 0 ) = $filler x ( $pad_len - length( $text ) ); # maybe pl - l(t) / l(f)?
	} else {
		$text .= $filler x ( $pad_len - length( $text ) );
	}
	return $text;
}
print ".";

# Ordinal function provided by Borodin on a Stack Overflow question
sub ordinal {
  return $_.(qw/th st nd rd/)[/(?<!1)([123])$/ ? $1 : 0] for int shift;
}
print ".";

sub dateConv {
	my $date = shift;
	if (ref($date) eq "DateTime") {
		$date->ymd =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;
		return ($date,$1,$2,$3); # have same return values as other input
	} else {
		$date =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;
		my $source = lineNo();
		die "Non-date string passed to dateConv: '$date' $source.\n" unless (defined $1 and defined $2 and defined $3);
		my ($y,$m,$d) = ($1,$2,$3);
		use DateTime;
		use DateTime::Format::DateParse;
		my $datestr = "$y-$m-$d";
		return (DateTime::Format::DateParse->parse_datetime( $datestr ),$y,$m,$d);
	}
}
print ".";

print " OK; ";
1;
