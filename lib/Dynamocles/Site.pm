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

    # Sort apps by the length of their base URL, longer bases first.
    # This puts the more-specific apps first, which means they get matched
    # by incoming requests first.
    my @app_names = map { $_->[0] }
                    sort { length $b->[1] <=> length $a->[1] }
                    map { [ $_, $self->apps->{ $_ }->base_url ] }
                    keys %{ $self->apps };

    # Mount apps
    for my $app_name ( @app_names ) {
        my $app = $self->apps->{ $app_name };
        $app->site( $self );
        $self->routes->any( $app->base_url )->detour( $app );
    }
}

1;
__END__

