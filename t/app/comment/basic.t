
use Dynamocles::Base 'Test';
use Mojo::Pg;
use Dynamocles::Site;
use Dynamocles::App::Comment;

my $app = Dynamocles::App::Comment->new(
    base_url => '/',
);

plan skip_all => 'No test without postgres installed'
    unless `postgres --version`;

use File::Temp ();
use Mojo::Util qw( url_escape );
my $data_dir = File::Temp->newdir;
my $sock_dir = File::Temp->newdir;

# initdb -D data
system( "initdb -D $data_dir" );

# postgres -D data -k $sock_dir
say "postgres -D $data_dir -k $sock_dir -c listen_addresses=''";
my $db_pid = fork;
if ( $db_pid ) {
    sleep 3;
}
else {
    exec( "postgres -D $data_dir -k $sock_dir -c listen_addresses=''" );
    exit $?;
}

# createdb test
system( "createdb -h $sock_dir test" );

# dropdb test

my $site = Dynamocles::Site->new(
    pg => Mojo::Pg->new( 'postgresql://' . url_escape( $sock_dir ) . '/test' ),
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

kill 'INT', $db_pid;

