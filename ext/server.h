#ifndef GRPC_PERL_SERVER_H
#define GRPC_PERL_SERVER_H

#include <grpc/grpc.h>

typedef struct {
  grpc_server *wrapped;
} ServerCTX;

typedef ServerCTX* Grpc__XS__Server;

#endif
