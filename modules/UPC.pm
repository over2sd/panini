package UPC;
print __PACKAGE__;

use JSON::MaybeXS qw(encode_json decode_json);
use HTTP::Tiny;

sub makeUPCbutton {
	my ($parent,$r,$c,$uvar,$cbref,$t) = @_;
	my $info;
	my $fetchb;
	$fetchb = $parent->Button(-text=>($t or "Fetch"),-command=>sub { $info = fetchUPCinfo($fetchb,$$uvar); $fetchb->{UPC} = $info; $cbref->($info); });
	$fetchb->grid(-row=>$r,-column=>$c);
	return $fetchb;
}
print ".";

sub fetchUPCinfo {
	my ($button,$upc) = @_;
	$button->configure(-state => 'disabled');
	my $url = 'https://api.upcitemdb.com/prod/trial/lookup?upc=%s';
	$upc =~ s/\D//g;
	$url =~ s/\%s/$upc/;
	my $data;
	print "Fetching URL...";
	my $response = HTTP::Tiny->new->get($url);
	print "done\n";
	if ($response->{success}) {
		my $html = $response->{content};
		my $remains = $response->{headers}->{x-rate-limit-remaining} or 0;
		print "$remaining lookups left.\n";
		$button->configure(-text => "$remaining queries left");
		$data= decode_json $html;
	} else {
		$button->configure(-text => "Error");
	}
	my @info = ($$data{code} == 'OK' ? $$data{items} : {} );
#skrDebug::dump(\%info,"Response");
	return $info[0][0];
}
print ".";

print " OK; ";
1;
