#!perl -T

use strict;
use warnings;

use Test::More tests => 2 + 4 + 2;
use Class::Hookable;
use lib 't';
use DummyClass;

my $hook    = Class::Hookable->new;
my $plugin  = Plugin->new;


$hook->register_hook(
    $plugin,
    'hook.A' => $plugin->can('foo'),
    'hook.B' => $plugin->can('bar'),
);

$hook->register_hook(
    'Plugin',
    'hook.A' => $plugin->can('foo'),
    'hook.B' => $plugin->can('bar'),
);

# ------------------------------------ #

my $hooks = $hook->registered_hooks;
is_deeply(
    $hooks,
    $hook->class_hookable_hooks,
);

is_deeply(
    [ $hook->registered_hooks ],
    [qw( hook.A hook.B )],
);

# ------------------------------------ #

my $data = $hook->registered_hooks( $plugin );
is_deeply(
    $data,
    [
        'hook.A' => $plugin->can('foo'),
        'hook.B' => $plugin->can('bar'),
    ],
);

is_deeply(
    [ $hook->registered_hooks( $plugin ) ],
    [qw( hook.A hook.B )],
);

$data = $hook->registered_hooks('Plugin');
is_deeply(
    $data,
    [
        'hook.A' => Plugin->can('foo'),
        'hook.B' => Plugin->can('bar'),
    ],
);

is_deeply(
    [ $hook->registered_hooks('Plugin') ],
    [qw( hook.A hook.B )],
);

# ------------------------------------ #

$data = $hook->registered_hooks( $plugin->can('foo') );
is_deeply(
    $data,
    [
        'hook.A' => $plugin,
        'hook.A' => 'Plugin',
    ],
);

is_deeply(
    [ $hook->registered_hooks( Plugin->can('bar') ) ],
    [qw( hook.B )],
);
