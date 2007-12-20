#!perl -T

use strict;
use warnings;

use Test::More tests => 2;
use Class::Hookable;

my $hook    = Class::Hookable->new;
my $plugin  = Plugin->new;

$hook->register_method(
    $plugin,
    'method.A' => $plugin->can('foo'),
    'method.B' => $plugin->can('foo'),
    'method.C' => $plugin->can('foo'),
);

$hook->delete_function( $plugin->can('foo') => qw( method.A ) );

is_deeply(
    [ $hook->registered_methods( $plugin ) ],
    [qw( method.B method.C )],
);

$hook->delete_function( $plugin->can('foo') );

is_deeply(
    [ $hook->registered_methods( $plugin ) ],
    [],
);

package Plugin;

sub new { bless {}, shift }
sub foo {}
sub bar {}

1;
