Grpc::XS::ChannelCredentials
createDefault()
  PREINIT:
    ChannelCredentialsCTX* ctx = (ChannelCredentialsCTX *)malloc( sizeof(ChannelCredentialsCTX) );
  CODE:
    ctx->wrapped = grpc_google_default_credentials_create();
    RETVAL = ctx;
  OUTPUT: RETVAL

Grpc::XS::ChannelCredentials
createSsl(const char *class, ...)
  PREINIT:
    ChannelCredentialsCTX* ctx = (ChannelCredentialsCTX *)malloc( sizeof(ChannelCredentialsCTX) );
  CODE:
    if ( items % 2 ) {
      croak("Expecting a hash as input to channel credentials constructor");
    }

    // @param string pem_root_certs PEM encoding of the server root certificates
    // @param string pem_private_key PEM encoding of the client's private key
    //     (optional)
    // @param string pem_cert_chain PEM encoding of the client's certificate chain
    //     (optional)
    // @return ChannelCredentials The new SSL credentials object

    const char* pem_root_certs = NULL;

    grpc_ssl_pem_key_cert_pair pem_key_cert_pair;
    pem_key_cert_pair.private_key = pem_key_cert_pair.cert_chain = NULL;

    int i;
    for (i = 0; i < items; i += 2 ) {
      const char *key = SvPV_nolen(ST(i));
      if (!strcmp( key, "pem_root_certs")) {
        pem_root_certs = SvPV_nolen(ST(i+1));
      } else if (!strcmp( key, "pem_private_key")) {
        pem_key_cert_pair.private_key = SvPV_nolen(ST(i+1));
      } else if (!strcmp( key, "perm_cert_chain")) {
        pem_key_cert_pair.cert_chain = SvPV_nolen(ST(i+1));
      }
    }

    ctx->wrapped = grpc_ssl_credentials_create(
        pem_root_certs,
        pem_key_cert_pair.private_key == NULL ? NULL : &pem_key_cert_pair, NULL);

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
    Safefree(self);
