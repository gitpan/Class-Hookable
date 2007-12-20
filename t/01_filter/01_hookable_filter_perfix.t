#!perl -T

use strict;
use warnings;

use Test::More tests => 2;
use Class::Hookable;

my $hook = Class::Hookable->new;

is(
    $hook->hookable_filter_prefix,
    undef,
);

$hook->hookable_filter_prefix('myfilter_prefix');

is(
    $hook->hookable_filter_prefix,
    'myfilter_prefix',
);
