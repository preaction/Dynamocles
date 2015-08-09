package Dynamocles::Site;
# ABSTRACT: A collection of Dynamocles application

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Dynamocles::Base 'Class';
extends 'Mojolicious';

has apps => (
    is => 'ro',
    isa => HashRef[InstanceOf['Dynamocles::App']],
    default => sub { {} },
);

has pg => (
    is => 'ro',
    isa => InstanceOf['Mojo::Pg'],
);

sub startup {
    my ( $self ) = @_;

    # Mount apps
    for my $app_name ( keys %{ $self->apps } ) {
        my $app = $self->apps->{ $app_name };
        $app->site( $self );
        $self->routes->any( $app->base_url )->detour( $app );
    }
}

1;
__END__

