Grpc::XS::Server
new(const char *class, ... )
  PREINIT:
    ServerCTX* ctx = (ServerCTX *)malloc( sizeof(ServerCTX) );
    ctx->wrapped = NULL;
  CODE:
    RETVAL = ctx;
  OUTPUT: RETVAL

SV *
requestCall()
  CODE:
  OUTPUT:

long
addHttp2Port(Grpc::XS::Server self, SV* addr)
  CODE:
    RETVAL = grpc_server_add_insecure_http2_port(self->wrapped, SvPV_nolen(addr));
  OUTPUT: RETVAL

long
addSecureHttp2Port(Grpc::XS::Server self, SV* addr, Grpc::XS::ServerCredentials creds)
  CODE:
    RETVAL = grpc_server_add_secure_http2_port(self->wrapped, SvPV_nolen(addr), creds->wrapped);
  OUTPUT: RETVAL

void
start(Grpc::XS::Server self)
  CODE:
    grpc_server_start(self->wrapped);
  OUTPUT:

void
DESTROY(Grpc::XS::Server self)
  CODE:
    Safefree(self);
