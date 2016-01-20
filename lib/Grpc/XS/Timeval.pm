package Grpc::XS::Timeval;

use strict;
use warnings;

use Grpc::XS;

use constant GPR_CLOCK_MONOTONIC => 0;
use constant GPR_CLOCK_REALTIME  => 1;
use constant GPR_CLOCK_PRECISE   => 2;
use constant GPR_TIMESPAN        => 3;

1;
