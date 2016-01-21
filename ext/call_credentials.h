#ifndef GRPC_PERL_CALL_CREDENTIALS_H
#define GRPC_PERL_CALL_CREDENTIALS_H

#include <grpc/grpc.h>
#include <grpc/grpc_security.h>

typedef struct {
  grpc_call_credentials *wrapped;
} CallCredentialsCTX;

typedef CallCredentialsCTX* Grpc__XS__CallCredentials;

#endif
