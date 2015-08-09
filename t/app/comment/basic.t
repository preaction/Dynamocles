
use Dynamocles::Base 'Test';
use Mojo::Pg;
use Dynamocles::Site;
use Dynamocles::App::Comment;

my $app = Dynamocles::App::Comment->new(
    base_url => '/',
);

plan skip_all => 'No test without postgres installed'
    unless Dynamocles::Test::Db->postgres_version;

my $test_db = Dynamocles::Test::Db->new;
$test_db->start;

my $site = Dynamocles::Site->new(
    pg => Mojo::Pg->new( $test_db->connect_url ),
    apps => { comment => $app },
);

$app->install;

use Test::Deep;
use Test::Mojo::WithRoles 'TestDeep';
my $t = Test::Mojo::WithRoles->new( $site );

subtest 'basic comments' => sub {
    subtest '/blog/page/1' => sub {
        subtest 'no comments to start' => sub {
            $t->get_ok( '/blog/page/1' )->status_is( 200 )->json_is( [] )
                ->or( sub { diag $t->tx->res->body } );
        };

        my $comment = {
            author_name => 'Pearl',
            author_email => 'shinydancer@beachcity.com',
            title => 'Spring Cleaning',
            content => "Clean up will begin promptly at 8",
        };

        my $expect = {
            %$comment,
            page_path => 'blog/page/1',
            date => re( qr(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}) ),
        };

        subtest 'add a comment' => sub {
            $t->post_ok( '/blog/page/1', json => $comment )->status_is( 200 )
              ->json_deeply( $expect );
        };

        subtest 'get all comments' => sub {
            $t->get_ok( '/blog/page/1' )->status_is( 200 )->json_deeply(
                [ { %$expect, author_website => ignore(), id => 1 } ],
            );
        };

        my $comment2 = {
            author_name => 'Amethyst',
            author_email => 'purplepuma@beachcity.com',
            author_website => 'http://google.com',
            title => 'Stay out of my room',
            content => "This is the last time, Pearl!",
        };

        my $expect2 = {
            %$comment2,
            page_path => 'blog/page/1',
            date => re( qr(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}) ),
        };

        subtest 'add another comment' => sub {
            $t->post_ok( '/blog/page/1', json => $comment2 )->status_is( 200 )
              ->json_deeply( $expect2 );
        };

        subtest 'get all comments' => sub {
            $t->get_ok( '/blog/page/1' )->status_is( 200 )->json_deeply(
                [
                    { %$expect, author_website => ignore(), id => 1 },
                    { %$expect2, author_website => ignore(), id => 2 },
                ],
            );
        };
    };

    subtest '/pod/Dynamocles.html' => sub {
        subtest 'no comments to start' => sub {
            $t->get_ok( '/pod/Dynamocles.html' )->status_is( 200 )->json_is( [] );
        };

        my $comment = {
            author_name => 'Garnet',
            author_email => 'rockshard@beachcity.com',
            title => 'Stop It',
            content => "Stop it you two.",
        };

        my $expect = {
            %$comment,
            page_path => 'pod/Dynamocles.html',
            date => re( qr(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}) ),
        };

        subtest 'add a comment' => sub {
            $t->post_ok( '/pod/Dynamocles.html', json => $comment )->status_is( 200 )
              ->json_deeply( $expect );
        };

        subtest 'get all comments' => sub {
            $t->get_ok( '/pod/Dynamocles.html' )->status_is( 200 )->json_deeply(
                [
                    { %$expect, author_website => ignore(), id => 3 },
                ]
            );
        };
    };
};

done_testing;
