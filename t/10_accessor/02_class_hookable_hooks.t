#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use Class::Hookable;

my $hook = Class::Hookable->new;

is(
    ref $hook->class_hookable_hooks,
    'HASH',
);
