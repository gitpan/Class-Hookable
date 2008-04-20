#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Class::Hookable;

my $hook = Class::Hookable->new;

ok( $hook->class_hookable_filter('run_hook') );

$hook->class_hookable_set_filter(
    run_hook => sub { 'foo' },
);

is(
    $hook->class_hookable_filter('run_hook'),
    'foo',
);

{
    package Class::Hookable;
    no warnings;
    *class_hookable_filter_run_hook = sub { 'bar' };
    *filter_run_hook                = sub { 'baz' };
}

is(
    $hook->class_hookable_filter('run_hook'),
    'bar',
);

$hook->class_hookable_filter_prefix('filter');

is(
    $hook->class_hookable_filter('run_hook'),
    'baz',
);
