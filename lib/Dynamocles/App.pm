package Dynamocles::App;
# ABSTRACT: A single applications

use Dynamocles::Base 'Class';
extends 'Mojolicious';

has site => (
    is => 'rw',
    isa => InstanceOf['Dynamocles::Site'],
);

has base_url => (
    is => 'ro',
    isa => Str,
    default => '/',
);

1;

