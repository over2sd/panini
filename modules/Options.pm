package Options;

use strict;
use warnings;
print __PACKAGE__;

use FIO qw( config );

my $MAINBG = "#CCF";

=item mkOptBox GUI HASH

Builds and displays a dialog box of options described in provided HASH.

=cut
sub mkOptBox {
	# need: guiset (for setting window marker, so if it exists, I can present the window instead of recreating it?)
	my ($target,$w,$h,%opts) = @_;
print "mOB: $target\n";
	my $changes = 0;
	my $pos = 1;
	my $spos = 1;
	my $page = 0;
	my $running = 1;
	my $toSave = {};
	my $nb = cfp($target->Scrolled('Frame', -scrollbars => 'osoe',-width => $w, -height => $h - 50, ),'panebg','',2,1);
	my $splash = cfp($nb->Label(-text => "Loading options..."),'panebg','bighead',$pos,2);
	TGK::pushStatus("Loading options... Please wait...");
	TGK::TFresh();
	cfp($nb->Label(-text => (FIO::config('Custom','options') or "Options") . ":"),'panebg','head',$pos++,1);
	my $vb;# = PGK::labelBox($optbox,"Options",'optlist','v',boxfill => 'both', boxex => 1);
	my %args;
#	my @tablist;
#	foreach my $k (sort keys %opts) {
#		my @o = @{ $opts{$k} };
#		next unless ($o[0] eq "l");
#		push(@tablist,$o[1]);
#$nb->Label(-text => "Option: $o[0]: $o[1]")->pack();
#	}
#	if (defined config('UI','tabson')) { $args{orientation} = (config('UI','tabson') eq "bottom" ? tno::Bottom : tno::Top); } # set tab position based on config option
	my $buttons = TGK::setBG($target->Frame(),'panebg');
	place($buttons,3,1,'e');
	my ($curtab,$section);
	my $spacer = TGK::setBG($buttons->Label(-text => " ")->pack(-fill => 'x', -expand => 1, -side=>'left'),'panebg');
	my $cancelB = TGUI::setBGF($buttons->Button(-text => "Cancel", -command => sub { TGUI::emptyFrame($target); })->pack(-side=>'left'),'buttonbg','button');
	my $saveB = TGUI::setBGF($buttons->Button(-text => "Save", )->pack(-side=>'left'),'buttonbg','button');
	$saveB->configure(-command => sub { saveFromOpt($saveB,[$target,$toSave,$target->parent]); });
	$curtab = $nb; # until/unless tabs implemented, set current tab to main page
	foreach my $k (sort keys %opts) {
		my @o = @{ $opts{$k} };
		if ($o[0] eq "l") { # label for tab
			my $l = cfp($nb->Label(-text => "  $o[1]", -justify => 'left' ),'panebg','body',$pos++,1); # for each section, make a notebook page
			$section = $o[2];
			filler($curtab,$spos,20,'x');
			$curtab = cfp($nb->Frame(-relief=>'groove',-bd=>2),'panebg','',$pos++,1,'we');
			$page++;
			$spos = 1;
		}elsif (defined $section and defined $curtab) { # not first option in list
			addModOpts($curtab,$section,\$changes,$spos,$saveB,$toSave,@o); # build and add option to page
#print "Opt-$k: " . join(", ",@o) . "\n";
			$spos++;
		} else {
			warn "First option in hash was not a label! mkOptBox() needs a label for the first tab";
			return -1;
		}
	}
#	$pages->{selector}->notify(q(Change)) if (config('UI','notabs')); # force a Change event to bring first panel to front.
	$splash->destroy();
	TGK::pushStatus("done.",1);
	TGK::TFresh();
	return;
}
print ".";

sub addModOpts {
	my ($parent,$s,$change,$pos,$applyBut,$saveHash,@a) = @_;
	unless (scalar @a > 2) { print "\n[W] Option array too short: @a - length: ". scalar @a . "."; return; } # malformed option, obviously
	my $item;
	my $t = $a[0];
	my $lab = $a[1];
	my $key = $a[2];
	my $col = ($a[3] or "#FF0000");
	splice @a, 0, 4; # leave 4-n in array
#	my $rw = $parent->Frame()->grid(-row=>$pos++,-column=>1,-sticky=>'w');
	for ($t) {
		if (/c/) {
			my $checkit = (config($s,$key) or 0);
	print "CHECK: $s/$key: $checkit\n";
			$checkit = (("$checkit" eq "1" or "$checkit" =~ /[Yy]/) ? 1 : 0);
			my $col = 1;
			$_ =~ m/c(\d)/;
			if (defined $1) { $col = $1; $pos -= $1 - 1; }
			$col = $col * 2 - 1;
			my $cb = cfp($parent->Checkbutton(-text => $lab, -variable => \$checkit),'panebg','body',$pos,$col);
			$cb->configure(-command => sub { optChange($cb,[$change,$pos,$saveHash,$s,$key,$applyBut,(config($s,$key) or 0)]); } );
		}elsif (/d/) { # Date row (with calendar button if option enabled)
$parent->Label(-text=>"Date type option not coded: $lab - $key - $col")->grid(-row=>$pos,-column=>1);
#PGUI::devHelp($parent,"Date type options ($key)");
		}elsif (/f/) {
			if ($col =~ m/^#/) { $col = "Verdana 12"; } # if passed a hex code
			require Tk::FontDialog;
			labelRow($parent,$lab,$pos);
			my $e = cfp($parent->Entry(-text => (config($s,$key) or $col)),'entbg','entry',$pos,3);
			my $b = cfp($parent->Button(-text => "Choose"),'buttonbg','button',$pos,4);
			my $fl = $parent->Label(-text => (config('Custom','fontsamp') or $e->get()), -foreground => "#000", -background => "#FFF"); # "Lorem Ipsum Fox Qqgfo0O"
			place($fl,$pos,5);
			sub setFont { return TGK::setFont(@_); }
			setFont($fl,$e->get(),1);
			$b->configure(-command => sub {
				my $f = $b->FontDialog->Show;
				return unless defined $f;
				my $df = $b->GetDescriptiveFontName($f);
				$e->configure(-text => $df);
				setFont($fl,$df,1);
				$e->focus();
				});
			$e->configure(-validate => 'focusout', -validatecommand => sub { 
				my $df = $e->get();
				setFont($fl,$df,1);
				return optChange($e,[$change,$pos,$saveHash,$s,$key,$applyBut,(config($s,$key) or "")]);
			});
			TGK::bindEnters($e,sub { setFont($fl,$e->get(),1); });
#		}elsif (/g/) {
#			$parent->insert( Label => text => $lab, alignment => ta::Center, pack => { fill => 'x', expand => 0 }, font => PGK::applyFont($key));
		}elsif (/h/) { # heading row
			# TODO: Add heading row handling
			($col eq "#FF0000") and $col = undef; # remove the default so it doesn't become a header.
			unshift(@a,$lab,$key,$col);
			my $c = 1;
			foreach my $h (@a) {
				cfp($parent->Label(-text => "$h"),'panebg','head',$pos,$c++); # add a header for each item.
			}
		}elsif (/l/) {
			cfp($parent->Label(-text => "$lab"),'panebg','body',$pos,1);
#		}elsif (/m/) {
#PGUI::devHelp($parent,"Mask page options ($key)");
		}elsif (/n/) {
			my $paired = 0;
			if (/n2/) {
				$paired = 1;
				$pos--;
			}
			my $col = (config($s,$key) or $col); # pull value from config, if present
			if ($col =~ m/^#/) { $col = 0; } # if passed a hex code
			buildNumericRow($parent,$saveHash,$applyBut,$lab,$s,$key,$col,$change,$pos,$paired,@a);
#		}elsif (/r/) {
#			my $col = (config($s,$key) or $col);
#			buildComboRow($parent,$saveHash,$applyBut,$lab,$s,$key,$col,$change,$pos,$_,@a);
#		}elsif (/s/) {
#			my $val = (config($s,$key) or "");
#			foreach my $i (0..$#a) { # find the value among the options
#				if ($a[$i] eq $val) { $col = $i; }
#			}
#			buildComboRow($parent,$saveHash,$applyBut,$lab,$s,$key,$col,$change,$pos,$_,@a);
		}elsif (/t/) {
			# TODO: Add handling of t2
			my $c = 1;
			if (/t2/) {
				$c = 3;
				$pos--;
			}
			labelRow($parent,$lab,$pos,$c);
			my $e = cfp($parent->Entry(-text => (config($s,$key) or "")),'entbg','entry',$pos,$c+2);
			$e->configure(-validate => 'focusout', -validatecommand => sub { return optChange($e,[$change,$pos,$saveHash,$s,$key,$applyBut,(config($s,$key) or "")]); });
		}elsif (/x/) {
			my $col = (config($s,$key) or $col); # pull value from config, if present
			buildColorRow($parent,$saveHash,$applyBut,$lab,$s,$key,$col,$change,$pos);
		} else {
#	place($parent->Label(-text=>"$t"),$pos,1);
#	place($parent->Label(-text=>"$lab"),$pos,2);
#	place($parent->Label(-text=>"$key"),$pos,3);
			warn "Ignoring bad option $t.\n";
			return;
		}
	}
}
print ".";

sub mayApply {
	my ($button,$maskref) = @_;
	unless ($$maskref == 0) { $button->configure(-state => 'normal'); }
}
print ".";

sub optChange {
	my ($caller,$args,$altargs) = @_;
	unless ($args =~ m/ARRAY/) { $args = $altargs; } # combobox sends an extraneous event argument before the user args
	my ($maskref,$p,$href,$sec,$k,$aButton,$default,$rbval) = @$args;
	print "my (\$maskref,\$p,\$href,\$sec,\$k,\$aButton,\$default,\$rbval)\n" if main::howVerbose() > 3 and Common::showDebug('d');
	printf("my (%s,%s,%s,%s,%s,%s,%s,%s)\n",$maskref,$p,$href,$sec,$k,$aButton,$default,($rbval or "undef")) if main::howVerbose() > 3 and Common::showDebug('d');
	my $value;
	for (ref($caller)) {
		print "Checking $_...";
		if (/Checkbutton/) {
			$value = $caller->cget('-variable') or 0;
			print "C $k " . $value . " V " . $$value . "\n";
			$value = (defined $value ? $$value : 0);
		} elsif (/Entry/) {
			$value = $caller->get();
			print "E $k V " . $value . "\n";
		} elsif (/ComboBox/) {
			$value = $caller->text;
#		} elsif (/FontButton/) {
#			$value = $caller->get_font_name();
		} elsif (/RadioButton/) {
			($caller->get_active() ? $value = $rbval : return );
		} elsif (/XButtons/ or /MaskGroup/) {
			$value = $caller->value;
		} elsif (/SpinEdit/ or /SpinButton/ or /AltSpinButton/) {
			$value = $caller->value;
		} else {
			warn "Fail! '$_' (" . (defined $default ? $default : "undef") . ") unhandled";
		}
#				$value = $caller->get_value_as_int();
#				$value = $caller->get_value_as_int() * 100;
#		print "$_: $value\n";
	}
	defined $value or return 0;
	unless (defined $default) { # no default; no need to check changed value
		$$maskref = Common::setBit($p,$$maskref);  $$href{$sec}{$k} = $value or 0;
		mayApply($aButton,$maskref);
	} else {
		unless ($value eq $default) { # check value changed from default
			$$maskref = Common::setBit($p,$$maskref); $$href{$sec}{$k} = $value or 0;
			mayApply($aButton,$maskref);
		} else { # use default; delete key
			$$maskref = Common::unsetBit($p,$$maskref); delete $$href{$sec}{$k};
		}
	}
	return 1;
}
print ".";

sub saveFromOpt {
	my ($caller,$args) = @_;
	$caller->configure(-state => 'disabled');
	my ($parent,$href,$grandparent) = @$args;
	print "sFO: $parent, $grandparent\n";
	foreach my $s (keys %$href) {
#		print "Section $s:\n";
		foreach (keys %{ $$href{$s} }) {
#			print "	Key $_: $$href{$s}{$_}\n";
			config($s,$_,($$href{$s}{$_} or 0));
		}
	}
	FIO::saveConf();
	TGK::pushStatus("Options applied.");
	# TODO: check here to see if something potentially crash-inducing has been changed, and shut down cleanly, instead, after informing user that a restart is required.
#	formatTooltips(); # set tooltip format, in case it was changed.
	TGK::emptyFrame($parent);
	cfp($parent->Label(-text => "Options applied."),'panebg','body',1,1);
	cfp($parent->Button(-text => "Reload Options pane", -command => sub { TGUI::showOptionsBox($grandparent); }),'buttonbg','button',2,1);

=item Comment

}
print ".";

sub buildComboRow {
	my ($box,$options,$applyBut,$lab,$s,$key,$d,$changes,$pos,$optyp,@presets) = @_;
	if ($d =~ m/^#/) { $d = 0; } # if passed a hex code
	my $row = PGK::labelBox( $box,$lab,'comborow','h', boxex => 0, labex => 0) unless ($optyp eq 'r');
	if ($optyp eq 's') {
		$d = int($d); # cast as a number
		my $selected = -1;
		foreach my $f (0..$#presets) {
			if ($f == $d) { $selected = $f; }
			$f++;
		}
		my $c = $row->insert( ComboBox => style => cs::DropDown, items => \@presets, text => (config($s,$key) or ''), height => 30 );
		$c->onChange( sub { optChange($c,[$changes,$pos,$options,$s,$key,$applyBut,config($s,$key)]); });
	} elsif ($optyp eq 'r') {
		my $g = $box-> insert( XButtons => name => $lab, pack => { fill => "none", expand => 0, }, );
		$g->onChange( sub { optChange($g,[$changes,$pos,$options,$s,$key,$applyBut,$d,$g->value()]); }, );
		$g->arrange("left"); # line up buttons horizontally (TODO: make this an option in the options hash? or depend on text length?)
		my $current = config($s,$key); # pull current value from config
		if (defined $current) { # translate current value to an array position (for default)
			$d = Common::findIn($current,@presets); # by finding it in the array
			$d = ($d == -1 ? scalar @presets : $d/2); # and dividing its position by 2 (behavior is undefined if position is odd)
		}
		$g-> build($lab,$d,@presets); # turn key:value pairs into exclusive buttons
	} else {
		warn "Incompatible selection type ($optyp)";
	}
=cut
}
print ".";

=item matchColor MODEL TARGET

Applies the MODEL's text as a color string to the background of the
TARGET.

=cut
sub matchColor {
	my ($model,$target) = @_;
	my $c = $model->get();
	$c eq "%main%" and $c = (FIO::config('UI','mainbg') or $MAINBG);
	$c =~ /(#?[0-9a-fA-F]{3})([0-9a-fA-F]{3})?([0-9a-fA-F]{6})?/;
	return 0 unless (defined $1);
	$c = (defined $3 ? "$1$2$3" : (defined $2 ? "$1$2" : $1));
	return $target->configure(-background => $c);
}
print ".";

sub buildColorRow {
	my ($box,$options,$applyBut,$lab,$s,$key,$col,$change,$pos) = @_;
	labelRow($box,$lab,$pos,1);
	my $e = cfp($box->Entry(-text => "$col"),'entbg','entry',$pos,3);
	$col eq "%main%" and $col = (FIO::config('UI','mainbg') or $MAINBG);
	my $b = cfp($box->Button(-text => " Select ", -background => "$col"),'buttonbg','button',$pos,4,'w',-columnspan => 3);
	$e->configure(-validate => 'all', -validatecommand => sub { matchColor($e,$b); return 1; } );
	TGK::bindEnters($e,sub { matchColor($e,$b); });
	#color => (config($s,$key) or $col)
	# TODO: if special color picker {
	# configure button command to a dialog I make to pick colors and return 6-digit hex
	#	} else {
	$b->configure(-command => sub { my $color = $b->chooseColor(-title => "Choose $lab Color", -initialcolor => $e->get()); $color and $e->configure(-text => $color); matchColor($e,$b); });
	#	}
	$e->configure(-validatecommand => sub { optChange($e,[$change,$pos,$options,$s,$key,$applyBut,(config($s,$key) or "")]); });
# TODO: Change background of $e to color selected in color dialog?
}
print ".";

sub buildNumericRow {
	my ($box,$options,$applyBut,$lab,$s,$key,$v,$changes,$pos,$paired,@boundaries) = @_;
	my $col = ($paired ? 8 : 1);
	labelRow($box,$lab,$pos,$col);
#skrDebug::dump(\@boundaries,"Bounds");
	my ($f,$t,$i,$p) = (($boundaries[0] or 0),($boundaries[1] or 10),($boundaries[2] or 1),($boundaries[3] or 5));
	$v or $v = 0; # default value
#	my $n = $box->Spinbox(-width=>3,-from=>$f,-to=>$t,-increment=>$i,-value=>$v);
	my $n = cfp($box->Entry(-width=>4, -text => "$v"),'entbg','entry',$pos,$col + 2);
	cfp($box->Button(-width => 4, -padx => 1, -pady => 1, -text=>$f,-command=>sub { $n->configure(-text => "$f"); }),'buttonbg','button',$pos,$col + 3);
# TODO: Optional pagedn button
	cfp($box->Button(-padx => 1, -pady => 1, -text=>"-",-command=>sub { $n->configure(-text => $n->get() - $i); }),'buttonbg','button',$pos,$col + 4);
	cfp($box->Button(-padx => 1, -pady => 1, -text=>"+",-command=>sub { $n->configure(-text => $n->get() + $i); $n->focus(); $n->focus(); $n->focusNext(); }),'buttonbg','button',$pos,$col + 5);
# TODO: Optional pageup button
	cfp($box->Button(-width => 4, -padx => 1, -pady => 1, -text=>$t,-command=>sub { $n->configure(-text => "$t"); }),'buttonbg','button',$pos,$col + 6);
	$n->configure(-validate => 'focusout', -validatecommand => sub { return optChange($n,[$changes,$pos,$options,$s,$key,$applyBut,config($s,$key)]); });
}
print ".";

sub filler {
	my ($t,$r,$c,$f) = @_;
	my $ff = $t->Frame();
	$t->gridColumnconfigure($c,-weight=>10);
	return cfp($ff,'panebg','',$r,$c,'nswe');
}
print ".";

sub labelRow { # make a quick label at the given row (and column)
	my ($t,$v,$r,$c,@e) = @_;
	my $w = $t->Label(-text=>"$v");
	cfp($w,'panebg','body',$r,($c or 1),@e);
	return $w;
}
print ".";

=item formatTooltips

Formats (or reformats after options have been changed) the font,
colors, and delay of the tooltips (hints) displayed by the program.
Takes no arguments, as it gets its settings from L<FIO/config>().

=cut
sub formatTooltips {
	return $::application->set(
		hintPause => 2500,
		hintColor => PGK::convertColor((FIO::config('UI','hintfore') or '#000')),
		hintBackColor => PGK::convertColor((FIO::config('UI','hintback') or '#CFF')),
		hintFont => PGK::applyFont('hint'),
	);
}
print ".";

sub place {
	return TGK::place(@_);
}
print ".";

sub cfp { return TGK::cfp(@_); }

print " OK; ";
1;
