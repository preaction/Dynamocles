package Dynamocles::App::Comment;
# ABSTRACT: Add comments to any web page

use Dynamocles::Base 'App';
use Time::Piece;

=method install

    $app->install;

Install the application into the configured database. If the application is
already installed, this method does nothing.

=cut

sub install {
    my ( $self ) = @_;
    my $db = $self->site->pg->db;

    $db->query(
        'CREATE TABLE IF NOT EXISTS comment (
            id SERIAL UNIQUE PRIMARY KEY,
            page_path VARCHAR,
            date TIMESTAMP,
            title VARCHAR,
            content TEXT,
            author_name VARCHAR,
            author_email VARCHAR,
            author_website VARCHAR
        )'
    );

    # Create an index for the page path, since that's the most common
    # way we'll be looking these up
    # XXX "CREATE INDEX IF NOT EXISTS" is in Postgres 9.5
    eval { $db->query( "SELECT 'comment_page_path_idx::regclass'" ) };
    if ( $@ ) {
        $db->query(
            'CREATE INDEX comment_page_path_idx ON comment ( page_path )'
        );
    }
}

=method startup

    # Called automatically by Mojolicious

Perform startup tasks for the app. Declare routes, add plugins, and get
everything ready to serve requests.

=cut

sub startup {
    my ( $self ) = @_;

    my $r = $self->routes;
    $r->get( '/*page_path' )->to( cb => sub {
        my ( $c ) = @_;
        my $db = $c->app->site->pg->db;

        $db->query( 'SELECT * FROM comment WHERE page_path=?', $c->stash( 'page_path' ),
            sub {
                my ( $db, $err, $results ) = @_;
                $c->render( json => [ $results->hashes->each ] );
            }
        );
    } );

    $r->post( '/*page_path' )->to( cb => sub {
        my ( $c ) = @_;
        my $db = $c->app->site->pg->db;
        my $post = $c->req->json;

        $post->{page_path} = $c->stash( 'page_path' );
        $post->{date} = Time::Piece->new->datetime;

        my @fields = keys %$post;
        my $fields = join ', ', @fields;
        my @values = map { $post->{$_} } @fields;
        my $places = join ', ', ( '?' ) x @fields;

        $db->query( 'INSERT INTO comment (' . $fields . ') VALUES (' . $places . ')', @values,
            sub {
                my ( $db, $err, $results ) = @_;
                $c->render( json => $post );
            }
        );

    } );
}

1;

