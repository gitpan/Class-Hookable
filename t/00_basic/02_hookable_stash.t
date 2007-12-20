#!perl -T

use strict;
use warnings;

use Test::More tests => 2;
use Class::Hookable;

my $hook = Class::Hookable->new;

can_ok( $hook, 'hookable_stash' );
is(
    ref $hook->hookable_stash,
    'HASH',
);
