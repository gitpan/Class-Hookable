#!perl -T

use strict;
use warnings;

use Test::More tests => 4 + 1 + 6;
use Class::Hookable;

my $hook    = Class::Hookable->new;
my $plugin  = Plugin->new;

$hook->register_method(
    $plugin,
    'call'      => \&call,
    'context'   => \&context,
    'filter'    => $plugin->can('foo'),
);

# -- call method test ---------------- #

is(
    $hook->call_method('call' => { foo => 'bar' }),
    'FOO',
);

sub call {
    my ( $plugin, $c, $args ) = @_;

    isa_ok( $plugin, 'Plugin' );
    isa_ok( $c, 'Class::Hookable' );
    is_deeply(
        $args,
        {
            foo => 'bar',
        },
    );

    return 'FOO',
}

# -- context test -------------------- #

$hook->hookable_context( Context->new );
$hook->call_method('context');

sub context {
    my ( $plugin, $c, $args ) = @_;
    isa_ok( $c, 'Context' );
}

# -- filter test --------------------- #

$hook->hookable_set_filter(
    'call_method' => sub {
        my ( $self, $filter, $method, $args, $action ) = @_;

        isa_ok( $self, 'Class::Hookable' );
        is( $filter, 'call_method' );
        is( $method, 'filter' );
        is( $args, undef );
        is_deeply(
            $action,
            {
                plugin      => $plugin,
                function    => $plugin->can('foo'),
            }
        );

        return 0;
    },
);

is(
    $hook->call_method('filter'),
    undef,
);

package Plugin;

sub new { bless {}, shift }
sub foo {}

package Context;

sub new { bless {}, shift }
