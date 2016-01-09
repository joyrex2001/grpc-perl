#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
// ============================================================================

static bool has_seen(SV* source,HV* reflist)
{
  if (hv_exists(reflist,(char*)SvRV(source),PTRSIZE)) return TRUE;
  hv_store(reflist,(char*)SvRV(source),PTRSIZE,NULL,0);
  return FALSE;
}

static void dispose_circ(SV* source,HV* reflist)
{
  // dereference and track reference as visited
  if (SvROK(source)) {
    has_seen(source,reflist);
    return dispose_circ(SvRV(source),reflist);
  }

  //  // get hash from blessed objects
  //  if (sv_isobject(source)) {
  //    return dispose_circ(SvSTASH(source),reflist);
  //  }

  // handle arrays
  if (SvTYPE(source)==SVt_PVAV) {
    I32 len = av_len((AV*)source);
    if (len>=0) {
      I32 i;
      for(i=0;i<=len;i++) {
	SV** value = av_fetch((AV*)source,i,0);
	if (SvROK(*value) && has_seen(*value,reflist)) {
	  av_delete((AV*)source,i,G_DISCARD);
	} else {
	  dispose_circ(*value,reflist);
	}
      }
    }
    return;
  }

  // handle hashes
  if (SvTYPE(source)==SVt_PVHV) {
    char* key;
    I32 keylen;
    SV* value;
    hv_iterinit((HV*)source);
    while((value = hv_iternextsv((HV*)source,&key,&keylen))!=NULL) {
      if (SvROK(value) && has_seen(value,reflist)) {
	hv_delete((HV*)source,key,keylen,G_DISCARD);
      } else {
	dispose_circ(value,reflist);
      }
    }
    return;
  }

  return;
}

// ============================================================================
MODULE = Grpc::Helper::Timeval	PACKAGE = Grpc::Helper::Timeval

void
disposeCirc(source)
         SV * source
     CODE:
         HV* reflist = newHV();
         dispose_circ(source,reflist);
         hv_undef(reflist);
