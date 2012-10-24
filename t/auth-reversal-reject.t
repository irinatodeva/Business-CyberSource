use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Class::Load 0.20 qw( load_class );
use FindBin; use lib "$FindBin::Bin/lib";

my $t = new_ok( load_class('Test::Business::CyberSource') );

my $client   = $t->resolve( service => '/client/object'    );

my $auth_res
	= $client->run_transaction(
		$t->resolve( service => '/request/authorization' )
	);

my $authrevc = load_class('Business::CyberSource::Request::AuthReversal');

my $rev_req
	= new_ok( $authrevc => [{
		reference_code => $auth_res->reference_code,
		service => {
			request_id => '834',
		},
		purchase_totals => {
			total    => $auth_res->auth->amount,
			currency => $auth_res->currency,
		},
	}]);

my $rev_res = exception { $client->run_transaction( $rev_req ) };

isa_ok $rev_res, 'Business::CyberSource::Response::Exception';

is( $rev_res->decision, 'REJECT', 'check decision' );
is( $rev_res->reason_code, 102, 'check reason_code' );

ok( $rev_res->request_token, 'request token exists' );

done_testing;
