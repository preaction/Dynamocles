package Dynamocles::Test::Db;
# ABSTRACT: Create and run a postgres instance for a test database

use Dynamocles::Base 'Class';
use Mojo::Util qw( url_escape );
use Path::Tiny;
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

=attr db_name

The name of the database. Defaults to C<test>.

=cut

has db_name => (
    is => 'ro',
    isa => Str,
    default => 'test',
);

=attr data_dir

The data directory to use. Defaults to a temporary directory.

=cut

has data_dir => (
    is => 'ro',
    isa => InstanceOf['Path::Tiny'],
    default => sub {
        Path::Tiny->tempdir;
    },
);

=attr sock_dir

The socket directory to use to connect to the database. Defaults to a
temporary directory.

=cut

has sock_dir => (
    is => 'ro',
    isa => InstanceOf['Path::Tiny'],
    default => sub {
        Path::Tiny->tempdir;
    },
);

=attr pid

The process ID for the forked postgres instance.

=cut

has pid => (
    is => 'rw',
    isa => Int,
    default => -1,
);

=attr fh

The filehandle for the forked postgres instance.

=cut

has fh => (
    is => 'rw',
);

=method postgres_version

    Dynamocles::Test::Db->postgres_version

Get the detected postgres version, or undef if postgres cannot be found.

=cut

sub postgres_version {
    my $output = `postgres --version`;
    my ( $v ) = $output =~ m{(\d+(?:[.]\d+)*)};
    return $v;
}

=method start

    $test_db->start;

Initialize a postgres database and start a test postgres instance.

=cut

sub start {
    my ( $self ) = @_;

    return if $self->pid != -1;

    my $data_dir = $self->data_dir;
    my $sock_dir = $self->sock_dir;
    my $db_name = $self->db_name;
    my ( $in, $out, $err, $pid );

    # initdb -D data
    $pid = open3( $in = gensym, $out = gensym, $err = gensym, "initdb -D $data_dir" );
    waitpid $pid, 0;

    # postgres -D data -k $sock_dir
    my $cmd = "postgres -D $data_dir -k $sock_dir -c listen_addresses=''";
    my $db_pid = open3( $in = gensym, $out = gensym, $err = gensym, $cmd );
    if ( !defined $db_pid ) {
        die "Could not open postgres: $!";
    }
    elsif ( $db_pid ) {
        $self->pid( $db_pid );
        # Wait until it's started
        while ( my $line = <$err> ) {
            last if $line =~ /database system is ready to accept connections/;
        }
    }
    else {
        # We're the postgres child process
        exit $?;
    }

    # createdb test
    $pid = open3( $in = gensym, $out = gensym, $err = gensym, "createdb -h $sock_dir $db_name" );
    waitpid $pid, 0;

    return;
}

=sub stop

    $test_db->stop;
    # OR
    undef $test_db;

Kill the running postgres database. This is done automatically when the
object is destroyed.

=cut

sub stop {
    my ( $self ) = @_;
    return if $self->pid == -1;
    kill 'INT', $self->pid;
    waitpid $self->pid, 0;
    $self->pid( -1 );
    return;
}

=method connect_url

    my $pg_url = $test_db->connect_url;
    my $pg = Mojo::Pg->new( $pg_url );

Create a connect URL suitable for L<Mojo::Pg/new>.

=cut

sub connect_url {
    my ( $self ) = @_;
    return 'postgresql://' . url_escape( $self->sock_dir ) . '/' . $self->db_name;
}

sub DEMOLISH {
    my ( $self ) = @_;
    $self->stop;
}

1;

=head1 SYNOPSIS

    my $test_db = Dynamocles::Test::Db->new;
    $test_db->start;

    my $pg = Mojo::Pg->new( $test_db->connect_url );

=head1 DESCRIPTION

This module will create a blank Postgres environment and launch a Postgres
server for testing purposes. Once L<the start method|/start> returns, you can
connect to the database, create necessary tables, and run your tests.

Multiple instances of this object should work fine: The database will not bind
to any TCP ports.
