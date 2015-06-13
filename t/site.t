
use Dynamocles::Base 'Test';
use Dynamocles::Site;
use TestApp;

my $site = Dynamocles::Site->new( apps => {
    default => TestApp->new(
        base_url => '/foo',
    ),
} );

my $t = Test::Mojo->new( $site );

$t->get_ok( '/foo/test' )->status_is( 200 )->content_is( 'derp' );

done_testing;
