#!perl -T

use strict;
use warnings;

use Test::More tests => 1;
use Class::Hookable;

my $hook = Class::Hookable->new;
my $plugin = Plugin->new;

$hook->register_method(
    $plugin,
    'method.A' => $plugin->can('foo'),
    'method.B' => $plugin->can('bar'),
);

$hook->delete_method('method.A');

is_deeply(
    [ $hook->registered_methods( $plugin ) ],
    [ qw( method.B ) ],
);

package Plugin;

sub new { bless {}, shift }
sub foo {}
sub bar {}
