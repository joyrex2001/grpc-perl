#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ext/timeval.h"
#include "ext/call.h"
#include "ext/call_credentials.h"

MODULE = Grpc::XS    PACKAGE = Grpc::XS

MODULE = Grpc::XS    PACKAGE = Grpc::XS::Timeval
INCLUDE: ext/timeval.xs

MODULE = Grpc::XS    PACKAGE = Grpc::XS::Call
INCLUDE: ext/call.xs

MODULE = Grpc::XS    PACKAGE = Grpc::XS::CallCredentials
INCLUDE: ext/call_credentials.xs
