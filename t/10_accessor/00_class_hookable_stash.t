#!perl -T

use strict;
use warnings;

use Test::More tests => 2;
use Class::Hookable;

my $hook = Class::Hookable->new;

can_ok( $hook, 'class_hookable_stash' );
is(
    ref $hook->class_hookable_stash,
    'HASH',
);
