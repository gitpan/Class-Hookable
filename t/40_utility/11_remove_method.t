#!perl -T

use strict;
use warnings;

use Test::More tests => 14;
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

$hook->register_method(
    'Plugin',
    'method.G' => Plugin->can('foo'),
    'method.H' => Plugin->can('bar'),
    'method.I' => Plugin->can('foo'),
    'method.J' => Plugin->can('bar'),
    'method.K' => Plugin->can('foo'),
    'method.L' => Plugin->can('bar'),
);

is_deeply(
    $hook->remove_method( target => $plugin->can('foo') ),
    {
        'method.A' => { plugin => $plugin, function => $plugin->can('foo') },
        'method.C' => { plugin => $plugin, function => $plugin->can('foo') },
        'method.E' => { plugin => $plugin, function => $plugin->can('foo') },
        'method.G' => { plugin => 'Plugin', function => Plugin->can('foo') },
        'method.I' => { plugin => 'Plugin', function => Plugin->can('foo') },
        'method.K' => { plugin => 'Plugin', function => Plugin->can('foo') },
    },
);

is_deeply(
    [ $hook->registered_methods( $plugin ) ],
    [qw( method.B method.D method.F )],
);

is_deeply(
    [ $hook->registered_methods( 'Plugin' ) ],
    [qw( method.H method.J method.L )],
);

is_deeply(
    $hook->remove_method( target => $plugin ),
    {
        'method.B' => { plugin => $plugin, function => $plugin->can('bar') },
        'method.D' => { plugin => $plugin, function => $plugin->can('bar') },
        'method.F' => { plugin => $plugin, function => $plugin->can('bar') },
    },
);

is_deeply(
    [ $hook->registered_methods( $plugin ) ],
    [],
);

is_deeply(
    $hook->remove_method( target => 'Plugin' ),
    {
        'method.H' => { plugin => 'Plugin', function => Plugin->can('bar') },
        'method.J' => { plugin => 'Plugin', function => Plugin->can('bar') },
        'method.L' => { plugin => 'Plugin', function => Plugin->can('bar') },
    },
);

is_deeply(
    [ $hook->registered_methods( 'Plugin' ) ],
    [],
);

$hook->register_method(
    $plugin,
    'method.A' => $plugin->can('foo'),
    'method.B' => $plugin->can('bar'),
    'method.C' => $plugin->can('foo'),
    'method.D' => $plugin->can('bar'),
    'method.E' => $plugin->can('foo'),
    'method.F' => $plugin->can('bar'),
);

$hook->register_method(
    'Plugin',
    'method.G' => Plugin->can('foo'),
    'method.H' => Plugin->can('bar'),
    'method.I' => Plugin->can('foo'),
    'method.J' => Plugin->can('bar'),
    'method.K' => Plugin->can('foo'),
    'method.L' => Plugin->can('bar'),
);

is_deeply(
    $hook->remove_method( target => { plugin => $plugin, function => $plugin->can('foo') } ),
    {
        'method.A' => { plugin => $plugin, function => $plugin->can('foo') },
        'method.C' => { plugin => $plugin, function => $plugin->can('foo') },
        'method.E' => { plugin => $plugin, function => $plugin->can('foo') },
    }
);

is_deeply(
    [ $hook->registered_methods( $plugin ) ],
    [qw( method.B method.D method.F )],
);

is_deeply(
    $hook->remove_method( target => $plugin->can('bar'), from => [qw( method.H method.J method.L )] ),
    {
        'method.H' => { plugin => 'Plugin', function => Plugin->can('bar') },
        'method.J' => { plugin => 'Plugin', function => Plugin->can('bar') },
        'method.L' => { plugin => 'Plugin', function => Plugin->can('bar') },
    },
);

is_deeply(
    [ $hook->registered_methods('Plugin') ],
    [qw( method.G method.I method.K )],
);

is_deeply(
    $hook->remove_method( target => [ $plugin, 'Plugin' ] ),
    {
        'method.B' => { plugin => $plugin, function => $plugin->can('bar') },
        'method.D' => { plugin => $plugin, function => $plugin->can('bar') },
        'method.F' => { plugin => $plugin, function => $plugin->can('bar') },
        'method.G' => { plugin => 'Plugin', function => Plugin->can('foo') },
        'method.I' => { plugin => 'Plugin', function => Plugin->can('foo') },
        'method.K' => { plugin => 'Plugin', function => Plugin->can('foo') },
    },
);

is_deeply(
    [ $hook->registered_methods( $plugin ) ],
    [],
);

is_deeply(
    [ $hook->registered_methods('Plugin') ],
    [],
);
