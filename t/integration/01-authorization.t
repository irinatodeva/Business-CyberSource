#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;
use String::Random qw(random_string);
use MooseX::Params::Validate;

use FindBin; use lib "$FindBin::Bin/lib";
use Test::Business::CyberSource::Client qw(create_client);
use Test::Business::CyberSource::Authorization qw(attempt_authorization);

use Business::CyberSource::Client;

use DateTime;
use Math::Currency;
use Readonly;

Readonly my $AMEX_NUMBER        => "378282246310005";
Readonly my $VISA_NUMBER        => "4111111111111111";
Readonly my $MASTERCARD_NUMBER  => "5555555555554444";
Readonly my $DISCOVER_NUMBER    => "6011111111111117";

Readonly my $PAYMENT_AMOUNT => Math::Currency->new("100.00");
Readonly my $EXPIRED_AMOUNT => Math::Currency->new("3000.37");
Readonly my $DECLINE_AMOUNT => Math::Currency->new('3000.28');

my $client = create_client();

my $testing_hash = {
    'Visa' => [
        [ "Success",      $VISA_NUMBER, $PAYMENT_AMOUNT, "ACCEPT", 100 ],
        [ "Declined",     $VISA_NUMBER, $DECLINE_AMOUNT, "REJECT", 203 ],
        [ "Expired Card", $VISA_NUMBER, $EXPIRED_AMOUNT, "REJECT", 202 ],
    ],
    'American Express' => [
        [ "Success",      $AMEX_NUMBER, $PAYMENT_AMOUNT, "ACCEPT", 100 ],
        [ "Declined",     $AMEX_NUMBER, $DECLINE_AMOUNT, "REJECT", 203 ],
        [ "Expired Card", $AMEX_NUMBER, $EXPIRED_AMOUNT, "REJECT", 202 ],
    ],
    'MasterCard' => [
        [ "Success",      $MASTERCARD_NUMBER, $PAYMENT_AMOUNT, "ACCEPT", 100 ],
        [ "Declined",     $MASTERCARD_NUMBER, $DECLINE_AMOUNT, "REJECT", 203 ],
        [ "Expired Card", $MASTERCARD_NUMBER, $EXPIRED_AMOUNT, "REJECT", 202 ],
    ],
    'Discover' => [
        [ "Success",      $DISCOVER_NUMBER, $PAYMENT_AMOUNT, "ACCEPT", 100 ],
        [ "Declined",     $DISCOVER_NUMBER, $DECLINE_AMOUNT, "REJECT", 203 ],
        [ "Expired Card", $DISCOVER_NUMBER, $EXPIRED_AMOUNT, "REJECT", 202 ],
    ],
};


for my $card_type ( keys $testing_hash ) {
    for my $test (@{ $testing_hash->{$card_type} }) {
        subtest "$card_type - $test->[0]" => sub {
            my $reference_code = "R" . random_string("nnCCnnCCnnCCnnCCnnCC");

            my ($authorization, $response) = attempt_authorization({
                client         => $client,
                reference_code => $reference_code,
                account_number => $test->[1],
                total          => $test->[2],
                decision       => $test->[3],
                reason_code    => $test->[4],
            });

            if($card_type eq "American Express") {
                cmp_ok($response->auth->ev_email,        'eq', 'Y',  "Correct ev_email");
                cmp_ok($response->auth->ev_phone_number, 'eq', 'Y',  "Correct ev_phone_number");
                cmp_ok($response->auth->ev_postal_code,  'eq', 'Y',  "Correct ev_postal_code");
                cmp_ok($response->auth->ev_name,         'eq', 'Y',  "Correct ev_name");
                cmp_ok($response->auth->ev_street,       'eq', 'Y',  "Correct ev_street");
                cmp_ok($response->auth->ev_email_raw,    'eq', 'Y',  "Correct ev_email_raw");
                cmp_ok($response->auth->ev_phone_number_raw, 'eq', 'Y',  "Correct ev_phone_number_raw");
                cmp_ok($response->auth->ev_postal_code_raw,  'eq', 'Y',  "Correct ev_postal_code_raw");
                cmp_ok($response->auth->ev_name_raw,     'eq', 'Y',  "Correct ev_name_raw");
                cmp_ok($response->auth->ev_street_raw,   'eq', 'Y',  "Correct ev_street_raw");
            }
            else {
                ok(!$response->auth->has_ev_email,            "No ev_email");
                ok(!$response->auth->has_ev_phone_number,     "No ev_phone_number");
                ok(!$response->auth->has_ev_postal_code,      "No ev_postal_code");
                ok(!$response->auth->has_ev_name,             "No ev_name");
                ok(!$response->auth->has_ev_street,           "No ev_street");
                ok(!$response->auth->has_ev_email_raw,        "No ev_email_raw");
                ok(!$response->auth->has_ev_phone_number_raw, "No ev_phone_number_raw");
                ok(!$response->auth->has_ev_postal_code_raw,  "No ev_postal_code_raw");
                ok(!$response->auth->has_ev_name_raw,         "No ev_name_raw");
                ok(!$response->auth->has_ev_street_raw,       "No ev_street_raw");
            }
        };
    }
}

done_testing;
