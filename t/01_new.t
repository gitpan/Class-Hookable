#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use Class::Hookable;

isa_ok( Class::Hookable->new, 'Class::Hookable' );