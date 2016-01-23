Grpc::XS::Channel
new(const char *class, const char* channel, ... )
  PREINIT:
    ChannelCTX* ctx = (ChannelCTX *)malloc( sizeof(ChannelCTX) );
  CODE:
    if ( ( items - 2 ) % 2 ) {
      croak("Expecting a hash as input to constructor");
    }

    Grpc__XS__Channel credentials = NULL;

    // channel, args_hash
    // hash->{credentials} - credentials object (optional)

    int i;
    HV *hash = newHV();
    for (i = 1; i < items; i += 2 ) {
      SV *key = ST(i);
      if (!strcmp( SvPV_nolen(key), "credentials")) {
        if (!sv_isobject(ST(i+1))) {
          croak("credentials is not a credentials object");
        }
        // check object
        credentials = (Grpc__XS__Channel)SvPV_nolen(ST(i+1));
      } else {
        SV *value = newSVsv(ST(i+1));
        hv_store_ent(hash,key,value,0);
      }
    }

    // hash -> grpc_channel_args *args; (tool method, also used in server)
    // long vs. string
    // create util.c --> solve callcredentials etc..

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
    if ( items > 1  ) { try_to_connect = SvUV(ST(1)); }
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
      free(self->wrapped);
      self->wrapped = NULL;
    }

void
DESTROY(Grpc::XS::Channel self)
  CODE:
    if (self->wrapped != NULL) {
      grpc_channel_destroy(self->wrapped);
      free(self->wrapped);
    }
    Safefree(self);
