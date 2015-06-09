
use Dynamocles::Base 'Test';
use Dynamocles::Site;

{
    package TestApp;
    use Dynamocles::Base 'App';

    sub startup {
        my ( $self ) = @_;
        $self->routes->get( '/test' )->to( cb => sub {
            my ( $c ) = @_;
            return $c->render( text => 'derp' );
        } );
    }
}

my $site = Dynamocles::Site->new( apps => {
    default => TestApp->new(
        base_url => '/foo',
    ),
} );

my $t = Test::Mojo->new( $site );

$t->get_ok( '/foo/test' )->status_is( 200 )->content_is( 'derp' );

done_testing;
