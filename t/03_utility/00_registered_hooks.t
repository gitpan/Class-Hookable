#!perl -T

use strict;
use warnings;

use Test::More tests => 3;
use Class::Hookable;

my $hook = Class::Hookable->new;
my $pluginA = PluginA->new;
my $pluginB = PluginB->new;

$hook->register_hook(
    $pluginA,
    'foo.bar' => $pluginA->can('foo'),
    'bar.baz' => $pluginA->can('bar'),
);

$hook->register_hook(
    $pluginB,
    'foo.bar' => $pluginB->can('foo'),
    'baz.foo' => $pluginB->can('bar'),
);

is_deeply(
    [ $hook->registered_hooks ],
    [ qw( bar.baz baz.foo foo.bar ) ],
);

is_deeply(
    [ $hook->registered_hooks( $pluginA ) ],
    [ qw( bar.baz foo.bar) ],
);

is_deeply(
    [ $hook->registered_hooks('PluginB') ],
    [ qw( baz.foo foo.bar ) ],
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