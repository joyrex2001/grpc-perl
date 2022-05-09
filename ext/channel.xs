Grpc::XS::Channel
new(const char *class, const char* target, ... )
  PREINIT:
    ChannelCTX* ctx = (ChannelCTX *)malloc( sizeof(ChannelCTX) );
    ctx->wrapped = NULL;
  CODE:
    if ( items > 2 && ( items - 2 ) % 2 ) {
      croak("Expecting a hash as input to constructor");
    }

    Grpc__XS__ChannelCredentials creds = NULL;

    // channel, args_hash
    // hash->{credentials} - credentials object (optional)

    int i;
    HV *hash = newHV();
    if (items>2) {
      for (i = 2; i < items; i += 2 ) {
        SV *key = ST(i);
        if (!strcmp(SvPV_nolen(key), "credentials")) {
          if (!sv_isobject(ST(i+1)) ||
              !sv_derived_from(ST(i+1),"Grpc::XS::ChannelCredentials")) {
            croak("credentials is not a credentials object");
          } else {
            IV tmp = SvIV((SV*)SvRV(ST(i+1)));
            creds = INT2PTR(Grpc__XS__ChannelCredentials,tmp);
          }
        } else {
          SV *value = newSVsv(ST(i+1));
          hv_store_ent(hash,key,value,0);
        }
      }
    }

    grpc_channel_args args;
    perl_grpc_read_args_array(hash, &args);

    if (creds == NULL) {
#ifdef GRPC_NO_INSECURE_BUILD
      grpc_channel_credentials * insecure_cred = grpc_insecure_credentials_create();
      ctx->wrapped = grpc_channel_create(target, insecure_cred, &args);
      grpc_channel_credentials_release(insecure_cred);
#else
      ctx->wrapped = grpc_insecure_channel_create(target, &args, NULL);
#endif
    } else {
      gpr_log(GPR_DEBUG, "Initialized secure channel");
#ifdef GRPC_NO_INSECURE_BUILD
      ctx->wrapped = grpc_channel_create(target, creds->wrapped, &args);
#else
      ctx->wrapped =
          grpc_secure_channel_create(creds->wrapped, target, &args, NULL);
#endif
    }
    free(args.args);

    RETVAL = ctx;
  OUTPUT: RETVAL

const char*
getTarget(Grpc::XS::Channel self)
  CODE:
    RETVAL = grpc_channel_get_target(self->wrapped);
  OUTPUT: RETVAL

long
getConnectivityState(Grpc::XS::Channel self, ... )
  CODE:
    int try_to_connect = 0;
    if ( items > 1  ) {
      if (items > 2 || !SvIOK(ST(1))) {
        croak("Invalid param getConnectivityState");
      }
      try_to_connect = SvUV(ST(1));
    }
    RETVAL = grpc_channel_check_connectivity_state(self->wrapped, try_to_connect);
  OUTPUT: RETVAL

int
watchConnectivityState(Grpc::XS::Channel self, long last_state, Grpc::XS::Timeval deadline)
  CODE:
    grpc_channel_watch_connectivity_state(
                self->wrapped, (grpc_connectivity_state)last_state,
                deadline->wrapped, completion_queue, NULL);
    grpc_event event = grpc_completion_queue_pluck(
                completion_queue, NULL,
                gpr_inf_future(GPR_CLOCK_REALTIME), NULL);
    RETVAL = event.success;
  OUTPUT: RETVAL

void
close(Grpc::XS::Channel self)
  CODE:
    if (self->wrapped != NULL) {
      grpc_channel_destroy(self->wrapped);
      self->wrapped = NULL;
    }

void
DESTROY(Grpc::XS::Channel self)
  CODE:
    if (self->wrapped != NULL) {
      grpc_channel_destroy(self->wrapped);
    }
    Safefree(self);
