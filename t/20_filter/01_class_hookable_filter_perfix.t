#!perl -T

use strict;
use warnings;

use Test::More tests => 2;
use Class::Hookable;

my $hook = Class::Hookable->new;

is(
    $hook->class_hookable_filter_prefix,
    'class_hookable_filter',
);

$hook->class_hookable_filter_prefix('myfilter_prefix');

is(
    $hook->class_hookable_filter_prefix,
    'myfilter_prefix',
);
