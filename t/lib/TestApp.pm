package
    TestApp;

use Dynamocles::Base 'App';

has text => (
    is => 'ro',
    default => 'foo',
);

sub startup {
    my ( $self ) = @_;
    $self->routes->get( '/test' )->to( cb => sub {
        my ( $c ) = @_;
        return $c->render( text => $self->text );
    } );
}

1;
