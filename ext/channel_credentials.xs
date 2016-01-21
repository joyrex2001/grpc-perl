Grpc::XS::ChannelCredentials
createDefault()
  PREINIT:
    ChannelCredentialsCTX* ctx = (ChannelCredentialsCTX *)malloc( sizeof(ChannelCredentialsCTX) );
  CODE:
    ctx->wrapped = grpc_google_default_credentials_create();
    RETVAL = ctx;
  OUTPUT: RETVAL

Grpc::XS::ChannelCredentials
createSsl()
  PREINIT:
    ChannelCredentialsCTX* ctx = (ChannelCredentialsCTX *)malloc( sizeof(ChannelCredentialsCTX) );
  CODE:
    // @param string pem_root_certs PEM encoding of the server root certificates
    // @param string pem_private_key PEM encoding of the client's private key
    //     (optional)
    // @param string pem_cert_chain PEM encoding of the client's certificate chain
    //     (optional)
    // @return ChannelCredentials The new SSL credentials object
    RETVAL = ctx;
  OUTPUT: RETVAL

Grpc::XS::ChannelCredentials
createComposite(Grpc::XS::ChannelCredentials cred1, Grpc::XS::CallCredentials cred2)
  PREINIT:
    ChannelCredentialsCTX* ctx = (ChannelCredentialsCTX *)malloc( sizeof(ChannelCredentialsCTX) );
  CODE:
    ctx->wrapped = grpc_composite_channel_credentials_create(
                                cred1->wrapped, cred2->wrapped, NULL);
    RETVAL = ctx;
  OUTPUT: RETVAL

Grpc::XS::ChannelCredentials
createInsecure()
  CODE:
    XSRETURN_UNDEF;
  OUTPUT:

void
DESTROY(Grpc::XS::ChannelCredentials self)
  CODE:
    grpc_channel_credentials_release(self->wrapped);
    free(self->wrapped);
    Safefree(self);
