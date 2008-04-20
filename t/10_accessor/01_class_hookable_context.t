#!perl -T

use strict;
use warnings;

use Test::More tests => 3;
use Class::Hookable;
use lib 't';
use DummyClass;

my $hook = Class::Hookable->new;

is(
    $hook->class_hookable_context,
    undef,
);

$hook->class_hookable_context('Class::Hookable');

is(
    $hook->class_hookable_context,
    'Class::Hookable',
);

$hook->class_hookable_context( Context->new );

isa_ok(
    $hook->class_hookable_context,
    'Context',
);

