#ifndef GRPC_PERL_CHANNEL_H
#define GRPC_PERL_CHANNEL_H

#include <grpc/grpc.h>

typedef struct {
  grpc_channel *wrapped;
} ChannelCTX;

typedef ChannelCTX* Grpc__XS__Channel;

#endif
