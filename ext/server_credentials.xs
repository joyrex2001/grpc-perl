Grpc::XS::ServerCredentials
createSsl(const char *class, ...)
  PREINIT:
    ServerCredentialsCTX* ctx = (ServerCredentialsCTX *)malloc( sizeof(ServerCredentialsCTX) );
    ctx->wrapped = NULL;
  CODE:
    if (items % 2) {
      croak("Expecting a hash as input to server credentials constructor");
    }

    // @param string pem_root_certs PEM encoding of the server root certificates (optional)
    // @param string pem_private_key PEM encoding of the client's private key
    // @param string pem_cert_chain PEM encoding of the client's certificate chain
    // @return Credentials The new SSL credentials object

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
      } else if (!strcmp( key, "pem_cert_chain")) {
        pem_key_cert_pair.cert_chain = SvPV_nolen(ST(i+1));
      }
    }

    ctx->wrapped = grpc_ssl_server_credentials_create(
        pem_root_certs,
        pem_key_cert_pair.private_key == NULL ? NULL : &pem_key_cert_pair,
        1, 0, NULL);

    RETVAL = ctx;
  OUTPUT: RETVAL

void
DESTROY(Grpc::XS::ServerCredentials self)
  CODE:
    if (self->wrapped != NULL) {
      grpc_server_credentials_release(self->wrapped);
    }
    Safefree(self);
