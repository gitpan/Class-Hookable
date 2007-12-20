#!perl -T

use strict;
use warnings;

use Test::Base tests => 4;
use Class::Hookable;

my $hook = Class::Hookable->new;

ok( $hook->hookable_call_filter('run_hook') );

{
    package Class::Hookable;
    no warnings;
    *hookable_filter_run_hook = sub {
        return 'false';
    };
    *filter_run_hook = sub {
        return 'true';
    }
}

is(
    $hook->hookable_call_filter('run_hook'),
    'false',
);

$hook->hookable_filter_prefix('filter');

is(
    $hook->hookable_call_filter('run_hook'),
    'true',
);

$hook->hookable_set_filter(
    'run_hook' => sub {
        return 0;
    }
);

is(
    $hook->hookable_call_filter('run_hook'),
    0,
);
