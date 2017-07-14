use 5.008005;
use ExtUtils::MakeMaker;

use Getopt::Long;

# perl Makefile.PL -d to enable -g flag for gdb.
Getopt::Long::Configure('pass_through');
GetOptions(
    'd'             => \my $DEBUG,
    'grpc-prefix=s' => \my $GRPC_PREFIX,
)
    or die "Error in command line arguments\n";

my ($EXTRA_CPPFLAGS, $EXTRA_LDFLAGS);
if ($GRPC_PREFIX) {
    $EXTRA_CPPFLAGS = "-I$GRPC_PREFIX/include";
    $EXTRA_LDFLAGS = "-L$GRPC_PREFIX/lib";
}

WriteMakefile(
      NAME          => 'Grpc::XS',
      VERSION_FROM  => 'lib/Grpc/XS.pm',
      AUTHOR        => 'Vincent van Dam',
      LIBS          => ["$EXTRA_LDFLAGS -lgrpc"],
      DEFINE        => '',
      INC           => "$EXTRA_CPPFLAGS -I.",
      C             => [ "Grpc.c", "util.c" ],
      OBJECT        => '$(O_FILES)',
      OPTIMIZE      => $DEBUG ? '-g' : '-O2',
    );
