package Business::CyberSource::Factory::Request;
use strict;
use warnings;
use namespace::autoclean;

# VERSION

use Moose;
extends 'Business::CyberSource::Factory';
use MooseX::AbstractFactory;
implementation_class_via sub { 'Business::CyberSource::Request::' . shift };

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: CyberSource Request Factory Module

=head1 SYNOPSIS

	use Business::CyberSource::RequestFactory;

	my $factory = Business::CyberSource::RequestFactory->new;

	my $request_obj = $factory->create(
		'Authorization',
		{
			reference_code => '42',
			first_name     => 'Caleb',
			last_name      => 'Cushing',
			street         => 'somewhere',
			city           => 'Houston',
			state          => 'TX',
			zip            => '77064',
			country        => 'US',
			email          => 'xenoterracide@gmail.com',
			total          => 5.00,
			currency       => 'USD',
			credit_card    => '4111111111111111',
			cc_exp_month   => '09',
			cc_exp_year    => '2013',
		}
	);

=head1 DESCRIPTION

This Module is to provide a replacement for what
L<Business::CyberSource::Request> originally was, a factory. Once backwards
compatibility is no longer needed this code may be removed.

=method new

=method create

	$factory->create( $implementation, { ... } )

Create a new request object. C<create> takes a request implementation and a hashref to pass to the
implementation's C<new> method. The implementation string accepts any
implementation whose package name is prefixed by
C<Business::CyberSource::Request::>.

	my $req = $factory->create(
			'Capture',
			{
				first_name => 'John',
				last_name  => 'Smith',
				...
			}
		);

=head1 SEE ALSO

=over

=item * L<MooseX::AbstractFactory>

=back

=cut