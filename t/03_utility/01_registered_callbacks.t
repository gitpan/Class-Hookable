#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use Class::Hookable;

my $hook = Class::Hookable->new;
my $pluginA = PluginA->new;
my $pluginB = PluginB->new;

$hook->register_hook(
    $pluginA,
    'aaa.bbb' => $pluginA->can('foo'),
    'bbb.ccc' => $pluginA->can('bar'),
);

$hook->register_hook(
    $pluginB,
    'aaa.bbb' => $pluginB->can('foo'),
    'aaa.bbb' => $pluginB->can('bar'),
);

is_deeply(
    [ $hook->registered_callbacks('aaa.bbb') ],
    [
        { plugin => $pluginA, callback => $pluginA->can('foo') },
        { plugin => $pluginB, callback => $pluginB->can('foo') },
        { plugin => $pluginB, callback => $pluginB->can('bar') },
    ],
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
