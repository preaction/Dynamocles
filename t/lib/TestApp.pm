package
    TestApp;

use Dynamocles::Base 'App';

sub startup {
    my ( $self ) = @_;
    $self->routes->get( '/test' )->to( cb => sub {
        my ( $c ) = @_;
        return $c->render( text => 'derp' );
    } );
}

1;
