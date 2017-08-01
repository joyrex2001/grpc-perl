# grpc-perl

## Overview

This repository contains source code for a perl5 implementation of gRPC layered
on shared C library. The implementation is heavily based on the php
implementation of the [gRPC library](https://grpc.io).

## Usage

This implementation only implements the grpc-client. To use it, there are
currently two options:

* [Google::ProtocolBuffers::Dynamic](http://search.cpan.org/dist/Google-ProtocolBuffers-Dynamic/) to generate the client
* [protoxs-perl](https://github.com/joyrex2001/protobuf-perlxs) to generate the client based on a proto2 file (see examples)

## Status

Experimental/in development.
