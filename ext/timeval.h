#ifndef GRPC_PERL_TIMEVAL_H
#define GRPC_PERL_TIMEVAL_H

#include <grpc/grpc.h>
#include <grpc/support/time.h>

typedef struct {
  gpr_timespec wrapped_gpr_timespec;
} TimevalCTX;

typedef TimevalCTX* Grpc__XS__Timeval;

#endif
