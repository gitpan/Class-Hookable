#!perl -T

use strict;
use warnings;

use Test::More tests => 3;
use Class::Hookable;

my $hook = Class::Hookable->new;

is(
    $hook->hookable_context,
    undef,
);

$hook->hookable_context('Class::Hookable');

is(
    $hook->hookable_context,
    'Class::Hookable',
);

$hook->hookable_context( Context->new );

isa_ok(
    $hook->hookable_context,
    'Context',
);

package Context;

sub new { bless {}, shift }
1;
