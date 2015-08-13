
use Dynamocles::Base 'Test';
use Mojo::Pg;
use Dynamocles::Site;
use Dynamocles::App::Comment;

BEGIN {
    plan skip_all => 'No test without postgres installed'
        unless Dynamocles::Test::Db->postgres_version;

    plan skip_all => 'No test without phantomjs installed'
        unless eval { require Mojo::Phantom; 1 };
};

use Test::Mojo::WithRoles 'Phantom';

{
    package MyStaticApp;
    use Dynamocles::Base 'App';

    sub startup {
        my ( $app ) = @_;
        $app->routes->get( '/index' )->to( cb => sub {
            my ( $c ) = @_;
            $c->render( inline => <<ENDHTML );
<html>
    <head>
        <title>Page with Comments</title>
    </head>
    <body>
        <div id="comment"></div>
        <script src="/api/comment/script.js"></script>
        <script>Dynamocles.App.Comment( '#comment' )</script>
    </body>
</html>
ENDHTML

        } );
    }
}

my $test_db = Dynamocles::Test::Db->new;
$test_db->start;

my $app = Dynamocles::App::Comment->new(
    base_url => '/api/comment',
);

my $site = Dynamocles::Site->new(
    pg => Mojo::Pg->new( $test_db->connect_url ),
    apps => {
        comment => $app,
        static => MyStaticApp->new,
    },
);

$app->install;

my $t = Test::Mojo::WithRoles->new( $site );


subtest 'phantom' => sub {
    $t->phantom_ok( '/index' => <<'ENDJS' );

var form = page.evaluate( function () {
    return document.getElementsByTagName( 'form' )[0];
} );
perl.ok( form, 'form exists' );

var text = page.evaluate( function () {
    return document.querySelector( 'form [type=text]' );
} );
perl.ok( text, 'form has name field' );

var email = page.evaluate( function () {
    return document.querySelector( 'form [type=email]' );
} );
perl.ok( email, 'form has email field' );

var content = page.evaluate( function () {
    return document.querySelector( 'form textarea' );
} );
perl.ok( content, 'form has content field' );

ENDJS
};

done_testing;
