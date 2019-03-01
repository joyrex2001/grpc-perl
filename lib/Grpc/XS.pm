package Grpc::XS;
use strict;
use warnings;
use XSLoader;

=head1 NAME

Grpc::XS - binding to the grpc library.

=cut

=head1 DESCRIPTION

This is the low-level binding to the L<grpc|https://grpc.io> library.
This implementation only supports a grpc client.

To use it, there are currently two options:

* L<Google::ProtocolBuffers::Dynamic> to generate the client

* L<protoxs-perl|https://github.com/joyrex2001/protobuf-perlxs> to generate the client based on a proto2 file (see examples)

=cut

=head1 AUTHOR

Vincent van Dam <joyrex2001@gmail.com>

=cut

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vincent van Dam.
grpc-perl is licensed under the Apache License 2.0.

=cut

=head1 SEE ALSO

L<Google::ProtocolBuffers::Dynamic>
L<https://github.com/joyrex2001/grpc-perl>

=cut

our $VERSION = '0.20';

XSLoader::load(__PACKAGE__, $VERSION );

END { destroy(); }

1;
