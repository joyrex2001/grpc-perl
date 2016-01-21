Grpc::XS::CallCredentials
createComposite(Grpc::XS::CallCredentials cred1, Grpc::XS::CallCredentials cred2)
  PREINIT:
    CallCredentialsCTX* ctx = (CallCredentialsCTX *)malloc( sizeof(CallCredentialsCTX) );
  CODE:
    ctx->wrapped = grpc_composite_call_credentials_create(
                                cred1->wrapped, cred2->wrapped, NULL);
    RETVAL = ctx;
  OUTPUT: RETVAL

Grpc::XS::CallCredentials
createFromPlugin()
  CODE:
    // todo
  OUTPUT:

void
DESTROY(Grpc::XS::CallCredentials self)
  CODE:
    grpc_call_credentials_release(self->wrapped);
    free(self->wrapped);
    Safefree(self);
