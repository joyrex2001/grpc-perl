#ifndef GRPC_PERL_SERVER_CREDENTIALS_H
#define GRPC_PERL_SERVER_CREDENTIALS_H

#include <grpc/grpc.h>
#include <grpc/grpc_security.h>

typedef struct {
  grpc_server_credentials *wrapped;
} ServerCredentialsCTX;

typedef ServerCredentialsCTX* Grpc__XS__ServerCredentials;

#endif
