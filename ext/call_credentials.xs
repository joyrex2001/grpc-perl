Grpc::XS::CallCredentials
createComposite(Grpc::XS::CallCredentials cred1, Grpc::XS::CallCredentials cred2)
  PREINIT:
    CallCredentialsCTX* ctx = (CallCredentialsCTX *)malloc( sizeof(CallCredentialsCTX) );
    ctx->wrapped = NULL;
  CODE:
    ctx->wrapped = grpc_composite_call_credentials_create(
                                cred1->wrapped, cred2->wrapped, NULL);
    RETVAL = ctx;
  OUTPUT: RETVAL

Grpc::XS::CallCredentials
createFromPlugin(/* method callback */)
  CODE:
    // todo
  OUTPUT:

void
DESTROY(Grpc::XS::CallCredentials self)
  CODE:
    if (self->wrapped != NULL) {
      grpc_call_credentials_release(self->wrapped);
    }
    Safefree(self);
