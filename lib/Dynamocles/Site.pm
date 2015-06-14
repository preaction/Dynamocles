package Dynamocles::Site;
# ABSTRACT: A collection of Dynamocles application

use Dynamocles::Base 'Class';
extends 'Mojolicious';

has apps => (
    is => 'ro',
    isa => HashRef[InstanceOf['Dynamocles::App']],
    default => sub { {} },
);

sub startup {
    my ( $self ) = @_;

    # Mount apps
    for my $app_name ( keys %{ $self->apps } ) {
        my $app = $self->apps->{ $app_name };
        $self->routes->any( $app->base_url )->detour( $app );
    }
}

1;
__END__

=head1 SYNOPSIS

=head1 DESCRIPTION


