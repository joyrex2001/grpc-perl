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

This library is not intended to be used directly, but rather
in combination with a protocol buffer implementation like the
L<Google::ProtocolBuffers::Dynamic> module.

=cut

=head1 AUTHOR

Vincent van Dam <joyrex2001@gmail.com>

=cut

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2019 by Vincent van Dam.
grpc-perl is licensed under the Apache License 2.0.

=cut

=head1 SEE ALSO

L<Google::ProtocolBuffers::Dynamic>

=cut

our $VERSION = '0.32';

XSLoader::load(__PACKAGE__, $VERSION );

END { destroy(); }

1;
