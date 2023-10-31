#!perl -w
use strict;
use Data::Dumper;
use Test::More;
use Devel::Peek;

use Grpc::XS::Server;
use Grpc::XS::Channel;
use Grpc::XS::Call;

my $ITERATIONS = 1;

sub run_server {
    my $do_exit = shift;

    Grpc::XS::init();
    my $server = new Grpc::XS::Server();
    my $port = $server->addHttp2Port('0.0.0.0:0');
    my $channel = new Grpc::XS::Channel('localhost:'.$port);
    $server->start();
    exit 3 if $do_exit;
}

foreach my $i (1..$ITERATIONS) {
    run_server();

    Grpc::XS::destroy();
    my $pid1 = fork() || run_server(1);
    my $pid2 = fork() || run_server(1);

    waitpid $pid1, 0;
    is $?, 256 * 3;

    waitpid $pid2, 0;
    is $?, 256 * 3;

    run_server();
}

done_testing;
