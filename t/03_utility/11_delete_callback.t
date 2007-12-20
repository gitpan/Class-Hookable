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
    'hook.B' => $pluginA->can('foo'),
);

$hook->register_hook(
    $pluginB,
    'hook.A' => $pluginB->can('foo'),
    'hook.B' => $pluginB->can('foo'),
);

$hook->delete_callback( $pluginA->can('foo') => qw( hook.A ) );

is_deeply(
    [ $hook->registered_hooks( $pluginA ) ],
    [qw( hook.B )],
);

$hook->delete_callback( $pluginB->can('foo') );

is_deeply(
    [ $hook->registered_hooks( $pluginB ) ],
    [],
);

package PluginA;

sub new { bless {}, shift }
sub foo {}
1;

package PluginB;

sub new { bless {}, shift }
sub foo {}
1;
