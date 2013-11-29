package Business::CyberSource::RequestPart::Card;
use 5.010;
use strict;
use warnings;
use namespace::autoclean;

# VERSION

use Moose;
extends 'Business::CyberSource::MessagePart';
with    'MooseX::RemoteHelper::CompositeSerialization';

use MooseX::Aliases;

use MooseX::Types::CyberSource      qw( CvIndicator CardTypeCode  );
use MooseX::Types::Common::String   qw( NonEmptySimpleStr         );
use MooseX::Types::CreditCard 0.002 qw(
	CardNumber
	CardSecurityCode
	CardExpiration
);

use Exception::Base (
	'Business::CyberSource::Card::Exception' => {
		has               => [qw( type )],
		string_attributes => [qw( type message )],
	},
	verbosity => 4,
	ignore_package => [ __PACKAGE__ ],
);

use Module::Runtime qw( use_module );

sub _build_type {
	my $self = shift;

	use_module('Business::CreditCard');
	my $ct = Business::CreditCard::cardtype( $self->account_number );

	Exception::Base->throw( message => $ct )
		if $ct =~ /not a credit card/ixms
		;

	$ct =~ s/[\s]card//xms;

	return uc $ct;
}

sub _build_expired {
	my $self = shift;
	use_module('DateTime');

	return $self->_compare_date_against_expiration( DateTime->now );
}

sub _compare_date_against_expiration {
	my ( $self, $date ) = @_;

	my $exp = $self->expiration->clone;
	# add 2 days so that we allow for a 24 hour period where
	# the card could be expired at UTC but not the issuer
	$exp->add( days => 1 );

	use_module('DateTime');
	my $cmp = DateTime->compare( $date, $exp );

	if    ( $cmp == -1 ) { # current date is before than the expiration date
		return 0;
	}
	elsif ( $cmp ==  0 ) { # expiration equal to current date
		return 0;
	}
	elsif ( $cmp ==  1 ) { # current date is past the expiration date
		return 1;
	}
	return; # da F*? should never hit this
}

sub _build_card_type_code {
	my $self = shift;

	my $code
		= $self->type =~ /visa             /ixms ? '001'
		: $self->type =~ /mastercard       /ixms ? '002'
		: $self->type =~ /discover         /ixms ? '004'
		: $self->type =~ /jcb              /ixms ? '007'
		: $self->type =~ /enroute          /ixms ? '014'
		: $self->type =~ /laser            /ixms ? '035'
		: $self->type =~ /american\ express/ixms ? '003'
		:                                  undef
		;

	Business::CyberSource::Card::Exception->throw(
		message => 'card type code was unable to be detected please define it'
			. ' manually'
			,
		type => $self->type,
	)
	unless $code;

	return $code;
}

has account_number => (
	isa         => CardNumber,
	remote_name => 'accountNumber',
	alias       => [ qw( credit_card_number card_number ) ],
	required    => 1,
	is          => 'ro',
	coerce      => 1,
	trigger     => sub { shift->type },
);

has type => (
	isa       => 'Str',
	lazy      => 1,
	is        => 'ro',
	builder   => '_build_type',
);

has expiration => (
	isa      => CardExpiration,
	required => 1,
	is       => 'ro',
	coerce   => 1,
	handles  => [ qw( month year ) ],
);

has is_expired => (
	isa      => 'Bool',
	builder  => '_build_expired',
	lazy     => 1,
	is       => 'ro',
);

has security_code => (
	isa         => CardSecurityCode,
	remote_name => 'cvNumber',
	alias       => [ qw( cvn cvv cvv2 cvc2 cid ) ],
	predicate   => 'has_security_code',
	traits      => [ 'SetOnce' ],
	is          => 'rw',
);

has holder => (
	isa         => NonEmptySimpleStr,
	remote_name => 'fullName',
	alias       => [ qw( name full_name card_holder ) ],
	predicate   => 'has_holder',
	traits      => [ 'SetOnce' ],
	is          => 'rw',
);

has card_type_code => (
	isa         => CardTypeCode,
	remote_name => 'cardType',
	lazy        => 1,
	is          => 'ro',
	builder     => '_build_card_type_code',
);

has cv_indicator => (
	isa         => CvIndicator,
	remote_name => 'cvIndicator',
	lazy        => 1,
	predicate   => 'has_cv_indicator',
	traits      => [ 'SetOnce' ],
	is          => 'rw',
	default     => sub { $_[0]->has_security_code ? 1 : 0 },
);

has _expiration_month => (
	remote_name => 'expirationMonth',
	isa         => 'Int',
	is          => 'ro',
	lazy        => 1,
	reader      => undef,
	writer      => undef,
	init_arg    => undef,
	default     => sub { $_[0]->expiration->month },
);

has _expiration_year => (
	remote_name => 'expirationYear',
	isa         => 'Int',
	is          => 'ro',
	lazy        => 1,
	reader      => undef,
	writer      => undef,
	init_arg    => undef,
	default     => sub { $_[0]->expiration->year },
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Credit Card Helper Class

=head1 EXTENDS

L<Business::CyberSource::MessagePart>

=attr account_number

This is the Credit Card Number

=attr expiration

	my $card = Business::CyberSource::RequestPart::Card->new({
			account_number => '4111111111111111',
			expiration     => {
				year  => '2025',
				month => '04',
			},
		});

A DateTime object, you should construct it by passing a hashref with keys for
month, and year, it will actually contain the last day of that month/year. You
can pass a L<DateTime> object, as long as it was built using the
L<last_day_of_month|DateTime/"DateTime-last_day_of_month-...-"> factory method.

=attr security_code

The 3 digit security number on the back of the card.

=attr holder

The full name of the card holder as printed on the card.

=attr is_expired

Boolean, returns true if the card is older than
L<expiration date|/"expiration"> plus one day. This is done to compensate for
unknown issuer time zones as we can't be sure that all issuers shut cards of on
the first of every month UTC. In fact I have been told that some issuers will
allow renewed cards to be run with expired dates. Use this at your discretion.

=attr cv_indicator

Boolean, true if the L<security code|/"security_code"> was passed.

=attr type

The card issuer, e.g. VISA, MasterCard. it is generated from the card number.

=attr card_type_code

Type of card to authorize. This should be auto detected, but if it's not you
can specify the value manually.

Possible values:

=over

=item 001: Visa

=item 002: MasterCard, Eurocard*

European regional brand of MasterCard

=item 003: American Express

=item 004: Discover

=item 005: Diners Club

see Discover Acquisitions and Alliances.

=item 006: Carte Blanche*

=item 007: JCB*

=item 014: EnRoute*

=item 021: JAL*

=item 024: Maestro (UK Domestic)*

=item 031: Delta*

use this value only for Global Collect. For other processors, use
001 for all Visa card types.

=item 033: Visa Electron*

=item 034: Dankort*

=item 035: Laser*

=item 036: Carte Bleue*

=item 037: Carta Si*

=item 039: Encoded account number*

=item 040: UATP*

=item 042: Maestro (International)*

=item 043: Santander card*

before setting up your system to work with Santander
cards, contact the CyberSource UK Support Group.

=back

=cut
