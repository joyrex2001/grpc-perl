## constructor, optionally takes long to create timespan timeval object

Grpc::XS::Timeval
new(const char *class, ... )
  PREINIT:
    TimevalCTX* ctx = (TimevalCTX *)malloc( sizeof(TimevalCTX) );
  CODE:
    if (items>1) {
      ctx->wrapped =
          gpr_time_from_micros(SvUV(ST(1)),GPR_TIMESPAN);
    } else {
      ctx->wrapped = gpr_time_0(GPR_CLOCK_REALTIME);
    }
    RETVAL = ctx;
  OUTPUT: RETVAL

long
similar( Grpc::XS::Timeval t1, Grpc::XS::Timeval t2, Grpc::XS::Timeval thres )
  CODE:
    RETVAL = gpr_time_similar(t1->wrapped, t2->wrapped, thres->wrapped);
  OUTPUT: RETVAL

long
compare( Grpc::XS::Timeval t1, Grpc::XS::Timeval t2 )
  CODE:
    RETVAL = gpr_time_cmp(t1->wrapped,t2->wrapped);
  OUTPUT: RETVAL

Grpc::XS::Timeval
substract( Grpc::XS::Timeval t1, Grpc::XS::Timeval t2 )
  PREINIT:
    TimevalCTX* ctx = (TimevalCTX *)malloc( sizeof(TimevalCTX) );
  CODE:
    ctx->wrapped = gpr_time_sub(t1->wrapped,t2->wrapped);
    RETVAL = ctx;
  OUTPUT: RETVAL

Grpc::XS::Timeval
add( Grpc::XS::Timeval t1, Grpc::XS::Timeval t2 )
  PREINIT:
    TimevalCTX* ctx = (TimevalCTX *)malloc( sizeof(TimevalCTX) );
  CODE:
    ctx->wrapped = gpr_time_add(t1->wrapped,t2->wrapped);
    RETVAL = ctx;
  OUTPUT: RETVAL

## sleep until this, or given timeval.

void
sleepUntil(Grpc::XS::Timeval timeval)
  CODE:
    gpr_sleep_until(timeval->wrapped);
  OUTPUT:

## static methods to create specific timeval values

Grpc::XS::Timeval
now()
  PREINIT:
    TimevalCTX* ctx = (TimevalCTX *)malloc( sizeof(TimevalCTX) );
  CODE:
    ctx->wrapped = gpr_now(GPR_CLOCK_REALTIME);
    RETVAL = ctx;
  OUTPUT: RETVAL

Grpc::XS::Timeval
zero()
  PREINIT:
    TimevalCTX* ctx = (TimevalCTX *)malloc( sizeof(TimevalCTX) );
  CODE:
    ctx->wrapped = gpr_time_0(GPR_CLOCK_REALTIME);
    RETVAL = ctx;
  OUTPUT: RETVAL

Grpc::XS::Timeval
infFuture()
  PREINIT:
    TimevalCTX* ctx = (TimevalCTX *)malloc( sizeof(TimevalCTX) );
  CODE:
    ctx->wrapped = gpr_inf_future(GPR_CLOCK_REALTIME);
    RETVAL = ctx;
  OUTPUT: RETVAL

Grpc::XS::Timeval
infPast()
  PREINIT:
    TimevalCTX* ctx = (TimevalCTX *)malloc( sizeof(TimevalCTX) );
  CODE:
    ctx->wrapped = gpr_inf_past(GPR_CLOCK_REALTIME);
    RETVAL = ctx;
  OUTPUT: RETVAL

## helper methods to access timespec struct values

unsigned long
getTvNsec(Grpc::XS::Timeval self)
  CODE:
    RETVAL = self->wrapped.tv_nsec;
  OUTPUT: RETVAL

unsigned long
getTvSec(Grpc::XS::Timeval self)
  CODE:
    RETVAL = self->wrapped.tv_sec;
  OUTPUT: RETVAL

unsigned long
getClockType(Grpc::XS::Timeval self)
  CODE:
    RETVAL = self->wrapped.clock_type;
  OUTPUT: RETVAL

## cleanup

void
DESTROY(Grpc::XS::Timeval self)
  CODE:
    Safefree(self);
