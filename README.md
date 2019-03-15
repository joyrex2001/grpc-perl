# Grpc::XS / grpc-perl

## Overview

This repository contains source code for a perl 5 implementation of gRPC
transport layer. It binds to the official shared C library. The implementation
is heavily based on the php implementation of the [gRPC library](https://grpc.io).

## Usage

This implementation only implements the grpc client, not the server. This
library also only implements the transport layer and is not intended to be used
directly. Instead it should be used in combination with a protocol buffer
implementation that support service rpc definitions. Currently the excellent
[Google::ProtocolBuffers::Dynamic](http://search.cpan.org/dist/Google-ProtocolBuffers-Dynamic/)
module is the best option for this.
