package Business::CyberSource::Response::Role::Accept;
use 5.008;
use strict;
use warnings;
use namespace::autoclean;

# VERSION

use Moose::Role;
with qw(
	Business::CyberSource::Role::Currency
	Business::CyberSource::Role::MerchantReferenceCode
);

use MooseX::Types::Moose         qw( Num Int );
use MooseX::Types::Varchar       qw( Varchar );
use MooseX::Types::DateTime::W3C qw( DateTimeW3C );


has amount => (
	required => 0,
	is       => 'ro',
	isa      => Num,
);

has datetime => (
	required => 0,
	is       => 'ro',
	isa      => DateTimeW3C,
);

has request_specific_reason_code => (
	required => 1,
	is       => 'ro',
	isa      => Int,
);

1;

# ABSTRACT: role for handling accepted transactions

=head1 DESCRIPTION

If the transaction has a C<decision> of C<ACCEPT> then this Role is applied.

=cut
