#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use Class::Hookable;

my $hook = Class::Hookable->new;

$hook->hookable_set_filter(
    run_hook => \&filter,
);

is(
    $hook->hookable_stash->{'filters'}->{'run_hook'},
    \&filter,
);

sub filter {}
