#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Class::Hookable;
use lib 't';
use DummyClass;

my $hook    = Class::Hookable->new;
my $plugin  = Plugin->new;

$hook->register_method(
    $plugin,
    'method.A' => $plugin->can('foo'),
    'method.B' => $plugin->can('bar'),
    'method.C' => $plugin->can('foo'),
    'method.D' => $plugin->can('bar'),
    'method.E' => $plugin->can('foo'),
    'method.F' => $plugin->can('bar'),
);

is_deeply(
    $hook->clear_methods( qw( method.A method.B method.C ) ),
    {
        'method.A' => { plugin => $plugin, function => $plugin->can('foo') },
        'method.B' => { plugin => $plugin, function => $plugin->can('bar') },
        'method.C' => { plugin => $plugin, function => $plugin->can('foo') },
    },
);

is_deeply(
    [ $hook->registered_methods ],
    [qw( method.D method.E method.F )],
);

is_deeply(
    $hook->clear_methods,
    {
        'method.D' => { plugin => $plugin, function => $plugin->can('bar') },
        'method.E' => { plugin => $plugin, function => $plugin->can('foo') },
        'method.F' => { plugin => $plugin, function => $plugin->can('bar') },
    },
);

is_deeply(
    [ $hook->registered_methods ],
    [],
);
