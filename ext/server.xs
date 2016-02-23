Grpc::XS::Server
new(const char *class, ... )
  PREINIT:
    ServerCTX* ctx = (ServerCTX *)malloc( sizeof(ServerCTX) );
    ctx->wrapped = NULL;
  CODE:
    if ( items > 1 && ( items - 1 ) % 2 ) {
      croak("Expecting a hash as input to constructor");
    }

    grpc_init();
    grpc_perl_init_completion_queue();

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

    grpc_server_register_completion_queue(ctx->wrapped,completion_queue,NULL);

    RETVAL = ctx;
  OUTPUT: RETVAL

HV *
requestCall(Grpc::XS::Server self)
  CODE:
    grpc_call_error error_code;
    grpc_call *call;
    grpc_call_details details;
    grpc_metadata_array metadata;
    grpc_event event;

    grpc_call_details_init(&details);
    grpc_metadata_array_init(&metadata);

    error_code =
        grpc_server_request_call(self->wrapped, &call, &details, &metadata,
                                 completion_queue, completion_queue, NULL);
    if (error_code != GRPC_CALL_OK) {
      warn("request_call failed, error = %d",error_code);
      goto cleanup;
    }

    event = grpc_completion_queue_pluck(completion_queue, NULL,
                                        gpr_inf_future(GPR_CLOCK_REALTIME), NULL);

    if (!event.success) {
      warn("Failed to request a call for some reason");
      goto cleanup;
    }

    HV* result;

    CallCTX* call_ctx = (CallCTX *)malloc( sizeof(CallCTX) );
    call_ctx->wrapped = call;
    hv_store(result,"call",strlen("call"),(SV*)call_ctx,0);

    hv_store(result,"method",strlen("method"),newSVpv(details.method,strlen(details.method)),0);
    hv_store(result,"host",strlen("host"),newSVpv(details.host,strlen(details.host)),0);

    TimevalCTX* timeval_ctx = (TimevalCTX *)malloc( sizeof(TimevalCTX) );
    timeval_ctx->wrapped = details.deadline;
    hv_store(result,"absolute_deadline",strlen("absolute_deadline"),(SV*)timeval_ctx,0);

    hv_store(result,"metadata",strlen("metadata"),
              newRV_noinc((SV *)grpc_parse_metadata_array(&metadata)),0);

  cleanup:
    grpc_call_details_destroy(&details);
    grpc_metadata_array_destroy(&metadata);
    RETVAL = result;
  OUTPUT: RETVAL

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
