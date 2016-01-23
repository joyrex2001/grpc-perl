Grpc::XS::ServerCredentials
createSsl()
  PREINIT:
    ServerCredentialsCTX* ctx = (ServerCredentialsCTX *)malloc( sizeof(ServerCredentialsCTX) );
    ctx->wrapped = NULL;
  CODE:
  OUTPUT:

void
DESTROY(Grpc::XS::ServerCredentials self)
  CODE:
    if (self->wrapped != NULL) {
      grpc_server_credentials_release(self->wrapped);
    }
    Safefree(self);
