use 5.008005;
use ExtUtils::MakeMaker;

# perl Makefile.PL -d to enable -g flag for gdb.
my $DEBUG = grep $_ eq '-d', @ARGV;

WriteMakefile(
      NAME          => 'Grpc::XS',
      VERSION_FROM  => 'lib/Grpc/XS.pm',
      AUTHOR        => 'Vincent van Dam',
      LIBS          => [''],
      DEFINE        => '',
      INC           => '-I.',
      OBJECT        => '$(O_FILES)',
      OPTIMIZE      => $DEBUG ? '-g' : '-O2',
    );
