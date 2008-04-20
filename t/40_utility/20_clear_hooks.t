#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
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
    'hook.E' => $plugin->can('foo'),
    'hook.F' => $plugin->can('bar'),
);

is_deeply(
    $hook->clear_hooks( qw( hook.A hook.B hook.C ) ),
    {
        'hook.A' => [
            { plugin => $plugin, callback => $plugin->can('foo') }
        ],
        'hook.B' => [
            { plugin => $plugin, callback => $plugin->can('bar') }
        ],
        'hook.C' => [
            { plugin => $plugin, callback => $plugin->can('foo') }
        ],
    }
);

is_deeply(
    [ $hook->registered_hooks ],
    [qw( hook.D hook.E hook.F )],
);

is_deeply(
    $hook->clear_hooks,
    {
        'hook.D' => [
            { plugin => $plugin, callback => $plugin->can('bar') }
        ],
        'hook.E' => [
            { plugin => $plugin, callback => $plugin->can('foo') }
        ],
        'hook.F' => [
            { plugin => $plugin, callback => $plugin->can('bar') }
        ],
    },
);

is_deeply(
    [ $hook->registered_hooks ],
    [],
);
