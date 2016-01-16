package Grpc::XS::Timeval;

use strict;
use warnings;

use Grpc::XS;

use constant GPR_CLOCK_MONOTONIC => 0;
use constant GPR_CLOCK_REALTIME  => 1;
use constant GPR_CLOCK_PRECISE   => 2;
use constant GPR_TIMESPAN        => 3;

sub similar {
    my $time1 = shift;
    my $time2 = shift;
    my $tresh = shift;
    return _similar(
        $time1->{tv_sec},$time1->{tv_nsec},$time1->{clock_type},
        $time2->{tv_sec},$time2->{tv_nsec},$time2->{clock_type},
        $tresh->{tv_sec},$tresh->{tv_nsec},$tresh->{clock_type}  );
}

sub compare {
    my $time1 = shift;
    my $time2 = shift;
    return _compare(
        $time1->{tv_sec},$time1->{tv_nsec},$time1->{clock_type},
        $time2->{tv_sec},$time2->{tv_nsec},$time2->{clock_type}  );
}

sub add {
    my $time1 = shift;
    my $time2 = shift;
    return _add(
        $time1->{tv_sec},$time1->{tv_nsec},$time1->{clock_type},
        $time2->{tv_sec},$time2->{tv_nsec},$time2->{clock_type}  );
}

sub substract {
    my $time1 = shift;
    my $time2 = shift;
    return _substract(
        $time1->{tv_sec},$time1->{tv_nsec},$time1->{clock_type},
        $time2->{tv_sec},$time2->{tv_nsec},$time2->{clock_type}  );
}

sub sleepUntil {
    my $time = shift;
    return _substract($time->{tv_sec},$time->{tv_nsec},$time->{clock_type});
}

1;
