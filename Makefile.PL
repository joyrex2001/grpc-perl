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
    function    => 'grpc_version_string();exit(0);',
);

check_lib(
    %CHECKLIB_ARGS,
    function    => <<'EOT',
grpc_op op; op.data.send_message.send_message = (grpc_byte_buffer *) NULL;
exit(0);
EOT
) and ($EXTRA_DEFINES .= " -DGRPC_VERSION_1_1");

check_lib(
    %CHECKLIB_ARGS,
    function    => <<'EOT',
grpc_call_details details;
grpc_call_details_init(&details);
grpc_slice_to_c_string(details.method);
exit(0);
EOT
) and ($EXTRA_DEFINES .= " -DGRPC_VERSION_1_2");

check_lib(
    %CHECKLIB_ARGS,
    function    => <<'EOT',
void (*call_unref)(grpc_call *call) = &grpc_call_unref;
exit(0);
EOT
) and ($EXTRA_DEFINES .= " -DGRPC_VERSION_1_4");

check_lib(
    %CHECKLIB_ARGS,
    function    => <<'EOT',
return 0;
grpc_op op;
op.data.recv_status_on_client.error_string = 0;
EOT
) and ($EXTRA_DEFINES .= " -DGRPC_RECV_STATUS_ON_CLIENT_HAS_ERROR_STRING");

check_lib(
    %CHECKLIB_ARGS,
    header => [$CHECKLIB_ARGS{header}, "grpc/grpc_security.h"],
    function    => <<'EOT',
return 0;
grpc_ssl_credentials_create(0, 0, 0, 0);
EOT
) and ($EXTRA_DEFINES .= " -DGRPC_SSL_CREDENTIALS_HAS_4_ARGS");

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
