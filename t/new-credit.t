use strict;
use warnings;
use Test::More;

use Class::Load qw( load_class );
use FindBin; use lib "$FindBin::Bin/lib";

my $t = load_class('Test::Business::CyberSource')->new;

my $dto
	= new_ok( load_class('Business::CyberSource::Request::Credit') => [{
		reference_code => 'notarealcode',
		bill_to =>
			$t->resolve( service => '/helper/bill_to' ),
		purchase_totals =>
			$t->resolve( service => '/helper/purchase_totals'),
		card =>
			$t->resolve( service => '/helper/card' ),
	}]);

my %expected = (
	billTo => {
		firstName   => 'Caleb',
		lastName    => 'Cushing',
		country     => 'US',
		ipAddress   => '192.168.100.2',
		street1     => 'somewhere',
		state       => 'TX',
		email       => 'xenoterracide@gmail.com',
		city        => 'Houston',
		postalCode => '77064',
	},
	card => {
		accountNumber   => '4111111111111111',
		cardType        => '001',
		cvIndicator     => 1,
		cvNumber        => 1111,
		expirationMonth => 5,
		expirationYear  => 2025,
		fullName        => 'Caleb Cushing',
	},
	ccCreditService => {
		run => 'true',
	},
	purchaseTotals => {
		currency         => 'USD',
		grandTotalAmount => 3000.00,
	},
	merchantReferenceCode => 'notarealcode',
);

is_deeply $dto->serialize, \%expected, 'serialize';

done_testing;
