#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use Class::Hookable;

my $hook = Class::Hookable->new;

$hook->class_hookable_set_filter(
    run_hook => \&filter,
);

is(
    $hook->class_hookable_filters->{'run_hook'},
    \&filter,
);

sub filter {}
