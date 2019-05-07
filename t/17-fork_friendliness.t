#!perl -w
use strict;
use Data::Dumper;
use Test::More;
use Devel::Peek;

use Grpc::XS::Server;
use Grpc::XS::Channel;
use Grpc::XS::Call;

sub run_in_child {
    Grpc::XS::init();
    my $server = new Grpc::XS::Server();
    my $port = $server->addHttp2Port('0.0.0.0:0');
    my $channel = new Grpc::XS::Channel('localhost:'.$port);
    $server->start();
    exit 3;
}

Grpc::XS::destroy();
my $pid1 = fork() || run_in_child();
my $pid2 = fork() || run_in_child();

waitpid $pid1, 0;
is $?, 256 * 3;

waitpid $pid2, 0;
is $?, 256 * 3;

done_testing;
