#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdbool.h>

#include <grpc/grpc.h>
#include <grpc/support/time.h>

/* C functions */

//add
//compare
//now
//similar
//sleepUntil
//subtract

MODULE = Grpc::XS    PACKAGE = Grpc::XS

MODULE = Grpc::XS    PACKAGE = Grpc::XS::Timeval

SV *
zero()
  CODE:
  {
    HV* hash = newHV();
    gpr_timespec time = gpr_time_0(GPR_CLOCK_REALTIME);
    hv_stores(hash, "tv_sec", newSViv(time.tv_sec));
    hv_stores(hash, "tv_nsec", newSViv(time.tv_nsec));
    hv_stores(hash, "clock_type", newSViv(time.clock_type));
    RETVAL = newRV_noinc((SV *)hash);
  }
  OUTPUT: RETVAL

SV *
infFuture()
  CODE:
  {
    HV* hash = newHV();
    gpr_timespec time = gpr_inf_future(GPR_CLOCK_REALTIME);
    hv_stores(hash, "tv_sec", newSViv(time.tv_sec));
    hv_stores(hash, "tv_nsec", newSViv(time.tv_nsec));
    hv_stores(hash, "clock_type", newSViv(time.clock_type));
    RETVAL = newRV_noinc((SV *)hash);
  }
  OUTPUT: RETVAL

SV *
infPast()
  CODE:
  {
    HV* hash = newHV();
    gpr_timespec time = gpr_inf_past(GPR_CLOCK_REALTIME);
    hv_stores(hash, "tv_sec", newSViv(time.tv_sec));
    hv_stores(hash, "tv_nsec", newSViv(time.tv_nsec));
    hv_stores(hash, "clock_type", newSViv(time.clock_type));
    RETVAL = newRV_noinc((SV *)hash);
  }
  OUTPUT: RETVAL

SV *
add_numbers_perl(SV *a, SV *b)
      CODE:
      {
          const double sum = SvNV(a) + SvNV(b);
          RETVAL = newSVnv(sum);
      }

      OUTPUT: RETVAL
