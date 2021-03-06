package skrDebug;

$|++; # immediate STDOUT, one would hope.
use Data::Dumper; # used by debug statements that unpack references.
use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw( Dumper dump );

sub dump {
	my ($ref,$desc,$showref) = @_;
	my $desc2 = (defined $desc ? $desc : "Variable");
	my $type = (ref($ref) eq "" ? ref(\$ref) : "reference to " . ref($ref));
	Common::dbgMes("$desc2 is a $type.\n") if $showref;
	Common::dbgMes("$desc: ",1) if defined $desc;
	print Dumper $ref;
}
1;
