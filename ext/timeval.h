#ifndef GRPC_PERL_TIMEVAL_H
#define GRPC_PERL_TIMEVAL_H

#include <grpc/grpc.h>
#include <grpc/support/time.h>

#define pl_wrap_gpr_timespec(hash,time) \
  hv_stores(hash, "tv_sec", newSViv(time.tv_sec));      \
  hv_stores(hash, "tv_nsec", newSViv(time.tv_nsec));    \
  hv_stores(hash, "clock_type", newSViv(time.clock_type));

gpr_timespec pl_init_gpr_timespec(tv_sec,tv_nsec,clock_type) {
  // pragmatic approach to seperating code from the xs, due to the macro's
  // that should be used in xs, it's not possible to move this code to the
  // xs file itself. hence it's in the header file instead :-/
  gpr_timespec t;
  t.tv_sec = tv_sec;
  t.tv_nsec = tv_nsec;
  t.clock_type = clock_type;
  return t;
}

#endif
