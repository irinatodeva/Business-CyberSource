package Business::CyberSource::Exception::Response;
use strict;
use warnings;

# VERSION

use Moose;
use MooseX::Aliases;
extends 'Business::CyberSource::Exception';

sub _build_message {
	my $self = shift;
	return $self->decison . ' ' . $self->reason_text;
}

has $_ => (
	isa => 'Str',
	is  => 'ro',
) foreach qw(
	decision
	reason_text
	request_id
	request_token
);

has reason_code => (
	isa   => 'Int',
	is    => 'ro',
	alias => 'value',
);

has $_ => (
	isa => 'Bool',
	is  => 'ro',
) foreach qw(
	is_error
	is_accept
	is_reject
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Card number is not a valid credit card