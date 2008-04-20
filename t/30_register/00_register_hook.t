#!perl -T

use strict;
use warnings;

use Test::More tests => 7;
use Class::Hookable;
use lib 't';
use DummyClass;

my $hook = Class::Hookable->new;
my $plugin = Plugin->new;

$hook->register_hook(
    $plugin,
    'foo.bar' => $plugin->can('foo'),
);

is(
    $hook->class_hookable_hooks->{'foo.bar'}->[0]->{'plugin'},
    $plugin,
);

is(
    $hook->class_hookable_hooks->{'foo.bar'}->[0]->{'callback'},
    $plugin->can('foo'),
);

$hook->class_hookable_set_filter(
    'register_hook' => sub {
        my ( $self, $filter, $hook, $action ) = @_;
        isa_ok( $self, 'Class::Hookable' );
        is( $filter, 'register_hook' );
        is( $hook, 'AAA.BBB' );
        is_deeply(
            $action,
            {
                plugin      => $plugin,
                callback    => $plugin->can('bar'),
            },
        );
    },
);

$hook->register_hook(
    $plugin,
    'AAA.BBB' => $plugin->can('bar'),
);

is(
    $hook->class_hookable_hooks->{'foo.bar'}->[1],
    undef,
);
