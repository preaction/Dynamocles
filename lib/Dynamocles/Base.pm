package Dynamocles::Base;
# ABSTRACT: Base import sets for Dynamocles modules

use strict;
use warnings;
use base 'Import::Base';

our @IMPORT_MODULES = (
    qw( strict warnings ),
    feature => [qw( :5.10 )],
);

our %IMPORT_BUNDLES = (
    Test => [
        qw( Test::More Test::Mojo Test::Lib ),
    ],
    App => [
        'Dynamocles::App',
        sub {
            my ( $bundles, $args ) = @_;
            no strict 'refs';
            push @{ $args->{package} . "::ISA" }, 'Dynamocles::App';
            return;
        },
    ],
);

