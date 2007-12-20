#!perl -T

use strict;
use warnings;

use Test::More tests => 6;
use Class::Hookable;

my $hook    = Class::Hookable->new;
my $plugin  = Plugin->new;

$hook->register_method(
    $plugin,
    'foo.bar' => $plugin->can('foo'),
);

is_deeply(
    $hook->hookable_all_methods->{'foo.bar'},
    {
        plugin      => $plugin,
        function    => $plugin->can('foo'),
    },
);

$hook->hookable_set_filter(
    'register_method' => sub {
        my ( $self, $filter, $method, $action ) = @_;
        isa_ok( $self, 'Class::Hookable' );
        is( $filter, 'register_method' );
        is( $method, 'bar.baz' );
        is_deeply(
            $action,
            {
                plugin      => $plugin,
                function    => $plugin->can('bar'),
            },
        );
        return 0;
    },
);

$hook->register_method(
    $plugin,
    'bar.baz' => $plugin->can('bar'),
);

is(
    $hook->hookable_all_methods->{'bar.baz'},
    undef,
);

package Plugin;

sub new { bless {}, shift }
sub foo {}
sub bar {}

