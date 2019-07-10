package skrDebug;

$|++; # immediate STDOUT, one would hope.
use Data::Dumper; # used by debug statements that unpack references.
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( Dumper dump );

sub dump {
	my ($ref,$desc) = @_;
	print "$desc: " if defined $desc;
	print Dumper $ref;
}
1;