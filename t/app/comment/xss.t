
use Dynamocles::Base 'Test';
use Mojo::Pg;
use Dynamocles::Site;
use Dynamocles::App::Comment;

plan skip_all => 'No test without postgres installed'
    unless Dynamocles::Test::Db->postgres_version;

my $test_db = Dynamocles::Test::Db->new;
$test_db->start;

my $app = Dynamocles::App::Comment->new(
    base_url => '/',
);

my $site = Dynamocles::Site->new(
    pg => Mojo::Pg->new( $test_db->connect_url ),
    apps => { comment => $app },
);

$app->install;

my $t = Test::Mojo::WithRoles->new( $site );

subtest 'XSS' => sub {
    subtest '/blog/page/2' => sub {
        subtest 'no comments to start' => sub {
            $t->get_ok( '/blog/page/2' )->status_is( 200 )->json_is( [] );
        };

        my $comment = {
            author_name => 'Preaction',
            author_email => 'root@example.com',
            title => 'Post Title',
            content => "# Hello\n\n<b>This is a bold comment.</b>\n\n[Buy my book](http://example.com)",
        };

        my $expect = {
            author_name => 'Preaction',
            author_email => 'root@example.com',
            title => 'Post Title',
            content => ignore(),
        };

        subtest 'add a comment' => sub {
            $t->post_ok( '/blog/page/2', json => $comment )->status_is( 200 )
              ->json_deeply( superhashof( $expect ) );

            my $dom = Mojo::DOM->new( $t->tx->res->json->{content} );
            is $dom->at( 'h1' )->text, 'Hello';
            is $dom->at( 'h1 + p' )->to_string, '<p>&lt;b&gt;This is a bold comment.&lt;/b&gt;</p>';
            is $dom->at( 'a' )->attr( 'href' ), 'http://example.com';
            is $dom->at( 'a' )->attr( 'rel' ), 'nofollow';
            is $dom->at( 'a' )->text, 'Buy my book';
        };

        subtest 'get all comments' => sub {
            $t->get_ok( '/blog/page/2' )->status_is( 200 )
              ->json_deeply( [ superhashof( $expect ) ] );

            my $dom = Mojo::DOM->new( $t->tx->res->json->[0]{content} );
            is $dom->at( 'h1' )->text, 'Hello';
            is $dom->at( 'h1 + p' )->to_string, '<p>&lt;b&gt;This is a bold comment.&lt;/b&gt;</p>';
            is $dom->at( 'a' )->attr( 'href' ), 'http://example.com';
            is $dom->at( 'a' )->attr( 'rel' ), 'nofollow';
            is $dom->at( 'a' )->text, 'Buy my book';
        };
    };
};

done_testing;
