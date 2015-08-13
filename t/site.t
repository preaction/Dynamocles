
use Dynamocles::Base 'Test';
use Dynamocles::Site;
use TestApp;

my $site = Dynamocles::Site->new( apps => {
    default => TestApp->new(
        base_url => '/foo',
    ),
    other => TestApp->new(
        base_url => '/',
        text => 'bar',
    ),
} );

my $t = Test::Mojo->new( $site );

$t->get_ok( '/foo/test' )->status_is( 200 )->content_is( 'foo' );
$t->get_ok( '/test' )->status_is( 200 )->content_is( 'bar' );

done_testing;
