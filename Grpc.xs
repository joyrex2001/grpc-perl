#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ext/timeval.h"

MODULE = Grpc::XS    PACKAGE = Grpc::XS

MODULE = Grpc::XS    PACKAGE = Grpc::XS::Timeval

INCLUDE: ext/timeval.xs
