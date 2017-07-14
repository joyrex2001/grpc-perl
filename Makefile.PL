use 5.008005;
use ExtUtils::MakeMaker;

use Getopt::Long;
use Devel::CheckLib;

# perl Makefile.PL -d to enable -g flag for gdb.
Getopt::Long::Configure('pass_through');
GetOptions(
    'd'             => \my $DEBUG,
    'grpc-prefix=s' => \my $GRPC_PREFIX,
)
    or die "Error in command line arguments\n";

my ($EXTRA_INCFLAGS, $EXTRA_DEFINES, $EXTRA_LDFLAGS, %CHECKLIB_ARGS);
if ($GRPC_PREFIX) {
    $EXTRA_INCFLAGS = "-I$GRPC_PREFIX/include";
    $EXTRA_LDFLAGS = "-L$GRPC_PREFIX/lib";
    $EXTRA_DEFINES = '';
    %CHECKLIB_ARGS = (
        header      => 'grpc/grpc.h',
        INC         => $EXTRA_INCFLAGS,
        LIBS        => "$EXTRA_LDFLAGS -lgrpc",
    );
} else {
    $EXTRA_INCFLAGS = $EXTRA_DEFINES = $EXTRA_LDFLAGS = '';
    %CHECKLIB_ARGS = (
        LIBS        => '-lgrpc',
        header      => 'grpc/grpc.h',
    );
}

# sanity check
check_lib_or_exit(
    %CHECKLIB_ARGS,
    function    => 'grpc_version_string();',
);

WriteMakefile(
      NAME                  => 'Grpc::XS',
      VERSION_FROM          => 'lib/Grpc/XS.pm',
      AUTHOR                => 'Vincent van Dam',
      LIBS                  => ["$EXTRA_LDFLAGS -lgrpc"],
      DEFINE                => $EXTRA_DEFINES,
      INC                   => "$EXTRA_INCFLAGS -I.",
      C                     => [ "Grpc.c", "util.c" ],
      OBJECT                => '$(O_FILES)',
      OPTIMIZE              => $DEBUG ? '-g' : '-O2',
      CONFIGURE_REQUIRES    => {
          'Devel::CheckLib'     => 0,
      },
    );
