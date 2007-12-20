#!perl -T

use strict;
use warnings;

use Test::More tests => 4;
use Class::Hookable;

my $hook = Class::Hookable->new;
my $plugin = Plugin->new;

$hook->register_hook(
    $plugin,
    'hook.A' => $plugin->can('foo'),
    'hook.B' => $plugin->can('foo'),
);

$hook->register_method(
    $plugin,
    'method.A' => $plugin->can('bar'),
    'method.B' => $plugin->can('bar'),
);

$hook->delete_plugin( $plugin => qw( hook.A method.B ) );

is_deeply(
    [ $hook->registered_hooks( $plugin ) ],
    [qw( hook.B )],
);

is_deeply(
    [ $hook->registered_methods( $plugin ) ],
    [qw( method.A )],
);

$hook->delete_plugin( $plugin );

is_deeply(
    [ $hook->registered_hooks( $plugin ) ],
    [],
);

is_deeply(
    [ $hook->registered_methods( $plugin ) ],
    [],
);

package Plugin;

sub new { bless {}, shift }
sub foo {}
sub bar {}
sub baz {}
1;
