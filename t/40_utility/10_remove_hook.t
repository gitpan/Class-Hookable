#!perl -T

use strict;
use warnings;

use Test::More tests => 17;
use Class::Hookable;
use lib 't';
use DummyClass;

my $hook    = Class::Hookable->new;
my $plugin  = Plugin->new;

$hook->register_hook(
    $plugin,
    'hook.A' => $plugin->can('foo'),
    'hook.B' => $plugin->can('bar'),
    'hook.C' => $plugin->can('foo'),
    'hook.D' => $plugin->can('bar'),
);

$hook->register_hook(
    'Plugin',
    'hook.A' => Plugin->can('foo'),
    'hook.B' => Plugin->can('bar'),
    'hook.C' => Plugin->can('foo'),
    'hook.D' => Plugin->can('bar'),
);

is_deeply(
    $hook->remove_hook( target => Plugin->can('bar') ),
    {
        'hook.B' => [
            { plugin => $plugin, callback => $plugin->can('bar') },
            { plugin => 'Plugin', callback => Plugin->can('bar') },
        ],
        'hook.D' => [
            { plugin => $plugin, callback => $plugin->can('bar') },
            { plugin => 'Plugin', callback => Plugin->can('bar') },
        ],
    },
);

is_deeply(
    [ $hook->registered_hooks( $plugin ) ],
    [qw( hook.A hook.C )],
);
is_deeply(
    [ $hook->registered_hooks( 'Plugin' ) ],
    [qw( hook.A hook.C )],
);

is_deeply(
    $hook->remove_hook( target => $plugin ),
    {
        'hook.A' => [
            { plugin => $plugin, callback => $plugin->can('foo') },
        ],
        'hook.C' => [
            { plugin => $plugin, callback => $plugin->can('foo') },
        ],
    },
);

is_deeply(
    [ $hook->registered_hooks( $plugin ) ],
    [],
);

is_deeply(
    $hook->remove_hook( target => 'Plugin' ),
    {
        'hook.A' => [
            { plugin => 'Plugin', callback => Plugin->can('foo') },
        ],
        'hook.C' => [
            { plugin => 'Plugin', callback => Plugin->can('foo') },
        ],
    },
);

is_deeply(
    [ $hook->registered_hooks( 'Plugin' ) ],
    [],
);

$hook->register_hook(
    $plugin,
    'hook.A' => $plugin->can('foo'),
    'hook.B' => $plugin->can('bar'),
    'hook.C' => $plugin->can('foo'),
    'hook.D' => $plugin->can('bar'),
);

$hook->register_hook(
    'Plugin',
    'hook.A' => Plugin->can('foo'),
    'hook.B' => Plugin->can('bar'),
    'hook.C' => Plugin->can('foo'),
    'hook.D' => Plugin->can('bar'),
);

is_deeply(
    $hook->remove_hook( target => { plugin => $plugin, callback => $plugin->can('foo') } ),
    {
        'hook.A' => [
            { plugin => $plugin, callback => $plugin->can('foo') },
        ],
        'hook.C' => [
            { plugin => $plugin, callback => $plugin->can('foo') },
        ]
    }
);

is_deeply(
    [ $hook->registered_hooks( $plugin ) ],
    [qw( hook.B hook.D )],
);

is_deeply(
    $hook->remove_hook( target => $plugin->can('bar'), from => 'hook.B' ),
    {
        'hook.B' => [
            { plugin => $plugin, callback => $plugin->can('bar') },
            { plugin => 'Plugin', callback => Plugin->can('bar') },
        ],
    },
);

is_deeply(
    [ $hook->registered_hooks( $plugin ) ],
    [qw( hook.D )],
);

is_deeply(
    [ $hook->registered_hooks( 'Plugin' ) ],
    [qw( hook.A hook.C hook.D )],
);

is_deeply(
    $hook->remove_hook( target => $plugin->can('foo'), from => [qw( hook.A hook.C )] ),
    {
        'hook.A' => [
            { plugin => 'Plugin', callback => Plugin->can('foo') },
        ],
        'hook.C' => [
            { plugin => 'Plugin', callback => Plugin->can('foo') },
        ],
    },
);

is_deeply(
    [ $hook->registered_hooks( 'Plugin' ) ],
    [qw( hook.D )],
);

is_deeply(
    $hook->remove_hook( target => ['Plugin', $plugin] ),
    {
        'hook.D' => [
            { plugin => $plugin, callback => $plugin->can('bar') },
            { plugin => 'Plugin', callback => Plugin->can('bar') },
        ],
    },
);

is_deeply(
    [ $hook->registered_hooks( $plugin ) ],
    [],
);

is_deeply(
    [ $hook->registered_hooks( 'Plugin' ) ],
    [],
);
