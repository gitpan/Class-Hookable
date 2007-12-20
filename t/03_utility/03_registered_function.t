#!perl -T

use strict;
use warnings;

use Test::More tests => 2;
use Class::Hookable;

my $hook    = Class::Hookable->new;
my $plugin  = Plugin->new;

$hook->register_method(
    $plugin,
    'method.name' => $plugin->can('foo'),
);

ok( ! $hook->registered_function('empty') );

is_deeply(
    $hook->registered_function('method.name'),
    {
        plugin      => $plugin,
        function    => $plugin->can('foo'),
    },
);

package Plugin;

sub new { bless {}, shift }
sub foo {}
1;
