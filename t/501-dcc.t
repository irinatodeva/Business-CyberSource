#!/usr/bin/perl
use 5.008;
use strict;
use warnings;
use Env qw( CYBS_ID CYBS_KEY );
use Test::More;

plan skip_all
	=> 'You MUST set ENV variable CYBS_ID and CYBS_KEY to test this!'
	unless $CYBS_ID and $CYBS_KEY
	;

use Business::CyberSource::Request::DCC;
use Business::CyberSource::Request::Authorization;
#use SOAP::Lite +trace => [ 'debug' ] ;

my $auth_req
	= Business::CyberSource::Request::DCC->new({
		username       => $CYBS_ID,
		password       => $CYBS_KEY,
		reference_code => '500',
		total          => 5.00,
		currency       => 'USD',
		credit_card    => '4111-1111-1111-1111',
		cc_exp_month   => '09',
		cc_exp_year    => '2025',
	});

my $auth = $auth_req->submit;

ok( $auth, 'authorization response exists' );

my $rev_req = Business::CyberSource::Request::AuthReversal->new({
		username       => $auth_req->username,
		password       => $auth_req->password,
		reference_code => $auth_req->reference_code,
		request_id     => $auth->request_id,
		total          => $auth->amount,
		currency       => $auth->currency,
	})
	;

my $rev = $rev_req->submit;

ok( $rev, 'reversal response exists' );

is( $rev->reference_code, '404', 'check reference_code' );
is( $rev->decision, 'ACCEPT', 'check decision' );
is( $rev->reason_code, 100, 'check reason_code' );
is( $rev->currency, 'USD', 'check currency' );
is( $rev->amount, '5.00', 'check amount' );
is( $rev->reversal_reason_code, 100, 'check capture_reason_code' );

ok( $rev->datetime, 'datetime exists' );
note( $rev->datetime );

done_testing;
