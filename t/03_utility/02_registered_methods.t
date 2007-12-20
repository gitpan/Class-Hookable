#!perl -T

use strict;
use warnings;

use Test::More tests => 3;
use Class::Hookable;

my $hook    = Class::Hookable->new;
my $pluginA = PluginA->new;
my $pluginB = PluginB->new;

$hook->register_method(
    $pluginA,
    'method.A' => $pluginA->can('foo'),
    'method.B' => $pluginA->can('bar'),
);

$hook->register_method(
    $pluginB,
    'method.B' => $pluginB->can('foo'),
    'method.C' => $pluginB->can('bar'),
);

is_deeply(
    [ $hook->registered_methods ],
    [qw( method.A method.B method.C )],
);

is_deeply(
    [ $hook->registered_methods( $pluginA ) ],
    [qw( method.A )],
);

is_deeply(
    [ $hook->registered_methods( 'PluginB' ) ],
    [qw( method.B method.C )],
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