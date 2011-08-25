package Business::CyberSource::Request::AuthReversal;
use 5.008;
use strict;
use warnings;
use Carp;
BEGIN {
	# VERSION
}

use SOAP::Lite; # +trace => [ 'debug' ] ;
use Moose;
use namespace::autoclean;
with qw(
	Business::CyberSource::Request::Role::Common
	Business::CyberSource::Request::Role::PurchaseInfo
);

sub submit {
	my $self = shift;

	my $ret = $self->_build_soap_request;

	my $decision    = $ret->valueof('decision'  );
	my $request_id  = $ret->valueof('requestID' );
	my $reason_code = $ret->valueof('reasonCode');

	croak 'no decision from CyberSource' unless $decision;

	my $res;
	if ( $decision eq 'ACCEPT' ) {
		$res
			= Business::CyberSource::Response
			->with_traits(qw{
				Business::CyberSource::Response::Role::Accept
				Business::CyberSource::Response::Role::AuthReversal
			})
			->new({
				request_id     => $request_id,
				decision       => $decision,
				reason_code    => $reason_code,
				reference_code => $ret->valueof('merchantReferenceCode'  ),
				currency       => $ret->valueof('purchaseTotals/currency'),
				datetime       => $ret->valueof('ccAuthReversalReply/requestDateTime'),
				amount         => $ret->valueof('ccAuthReversalReply/amount'  ),
				reversal_reason_code
					=> $ret->valueof('ccAuthReversalReply/reasonCode'),
				processor_response
					=> $ret->valueof('ccAuthReversalReply/processorResponse'),
			})
			;
	}
	elsif ( $decision eq 'REJECT' ) {
		$res
			= Business::CyberSource::Response
			->with_traits(qw{
				Business::CyberSource::Response::Role::Reject
			})
			->new({
				decision      => $decision,
				request_id    => $request_id,
				reason_code   => $reason_code,
				request_token => $ret->valueof('requestToken'),
			})
			;
	}
	else {
		croak 'decision defined, but not sane: ' . $decision;
	}

	return $res;
}

has request_id => (
	required => 1,
	is       => 'ro',
	isa      => 'Str',
);


sub _build_sdbo {
	my $self = shift;

	my $sb = $self->_build_sdbo_header;

	$sb = $self->_build_purchase_info   ( $sb );

	my $auth_reversal = $sb->add_elem(
		attributes => { run => 'true' },
		name       => 'ccAuthReversalService',
	);

	$sb->add_elem(
		name   => 'authRequestID',
		value  => $self->request_id,
		parent => $auth_reversal,
	);

	return $sb;
}

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: CyberSource Reverse Authorization request object

=head1 SYNOPSIS

	my $req = Business::CyberSource::Request::AuthReversal->new({
		username       => 'merchantID',
		password       => 'transaction key',
		production     => 0,
		reference_code => 'orignal authorization merchant reference code',
		request_id     => 'request id returned in original authorization response',
		total          => 5.00, # same as original authorization amount
		currency       => 'USD', # same as original currency
	});

	my $res = $req->submit;

=head1 DESCRIPTION

=method new

Instantiates a authorization reversal request object, see
L<the attributes listed below|/ATTRIBUTES> for which ones are required and
which are optional.

=method submit

Actually sends the required data to CyberSource for processing and returns a
L<Business::CyberSource::Response> object.

=cut
