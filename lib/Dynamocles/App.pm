package Dynamocles::App;
# ABSTRACT: A single applications

use Dynamocles::Base 'Class';
extends 'Mojolicious';

has base_url => (
    is => 'ro',
    isa => Str,
    default => '/',
);

1;

