Grpc::XS::Server
new(const char *class, ... )
  PREINIT:
    ServerCTX* ctx = (ServerCTX *)malloc( sizeof(ServerCTX) );
    ctx->wrapped = NULL;
  CODE:
    if ( items > 1 && ( items - 1 ) % 2 ) {
      croak("Expecting a hash as input to constructor");
    }

    int i;
    HV *hash = newHV();
    if (items>1) {
      for (i = 1; i < items; i += 2 ) {
        SV *key = ST(i);
        SV *value = newSVsv(ST(i+1));
        hv_store_ent(hash,key,value,0);
      }
      grpc_channel_args args;
      perl_grpc_read_args_array(hash, &args);
      ctx->wrapped = grpc_server_create(&args, NULL);
      free(args.args);
    } else {
      ctx->wrapped = grpc_server_create(NULL, NULL);
    }

    RETVAL = ctx;
  OUTPUT: RETVAL

SV *
requestCall()
  CODE:
    // TODO
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
