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
createFromPlugin(SV* callback)
  PREINIT:
    CallCredentialsCTX* ctx = (CallCredentialsCTX *)malloc( sizeof(CallCredentialsCTX) );
    ctx->wrapped = NULL;
  CODE:
    grpc_metadata_credentials_plugin plugin;
    plugin.get_metadata = plugin_get_metadata;
    plugin.destroy = plugin_destroy_state;
    plugin.state = (void *)SvRV(callback);
    plugin.type = "";
    ctx->wrapped = grpc_metadata_credentials_create_from_plugin(plugin, NULL);
    RETVAL = ctx;
  OUTPUT: RETVAL

void
DESTROY(Grpc::XS::CallCredentials self)
  CODE:
    if (self->wrapped != NULL) {
      grpc_call_credentials_release(self->wrapped);
    }
    Safefree(self);
