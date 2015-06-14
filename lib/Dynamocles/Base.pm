package Dynamocles::Base;
# ABSTRACT: Base import sets for Dynamocles modules

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    qw( strict warnings ),
    feature => [qw( :5.10 )],
);

my @class_modules = (
    'Types::Standard' => [qw( :all )],
);

our %IMPORT_BUNDLES = (
    Class => [
        '<Moo',
        @class_modules,
    ],

    Test => [
        qw( Test::More Test::Mojo Test::Lib ),
    ],

    App => [
        '<Moo',
        @class_modules,
        'Dynamocles::App',
        sub {
            my ( $bundles, $args ) = @_;
            no strict 'refs';
            ( $args->{package} . "::extends" )->( 'Dynamocles::App' );
            return;
        },
    ],
);

