#!perl -T

use strict;
use warnings;

use Test::More tests => 2;
use Class::Hookable;

my $hook    = Class::Hookable->new;
my $pluginA = PluginA->new;
my $pluginB = PluginB->new;

$hook->register_hook(
    $pluginA,
    'hook.A' => $pluginA->can('foo'),
    'hook.B' => $pluginA->can('bar'),
);

$hook->register_hook(
    $pluginB,
    'hook.A' => $pluginB->can('foo'),
    'hook.B' => $pluginB->can('bar'),
);

$hook->delete_hook('hook.A', $pluginA);

is_deeply(
    [ $hook->registered_hooks( $pluginA ) ],
    [ qw( hook.B ) ],
);

$hook->delete_hook('hook.B');

is_deeply(
    [ $hook->registered_plugins('hook.B') ],
    [],
);

package PluginA;

sub new { bless {}, shift }
sub foo {}
sub bar {}

1;

package PluginB;

sub new { bless {}, shift }
sub foo {}
sub bar {}

1;
