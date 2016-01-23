Grpc::XS::ServerCredentials
createSsl()
  PREINIT:
    ServerCredentialsCTX* ctx = (ServerCredentialsCTX *)malloc( sizeof(ServerCredentialsCTX) );
  CODE:
  OUTPUT:

void
DESTROY(Grpc::XS::ServerCredentials self)
  CODE:
    grpc_server_credentials_release(self->wrapped);
    Safefree(self);
