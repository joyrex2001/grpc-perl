#ifndef GRPC_PERL_CALL_H
#define GRPC_PERL_CALL_H

#include <grpc/grpc.h>

typedef struct {
  grpc_call *wrapped_grpc_call;
} CallCTX;

typedef CallCTX* Grpc__XS__Call;

#endif
