#!perl -T

use strict;
use warnings;

use Test::More tests => 5 + 2 + 6;
use Class::Hookable;

my $hook    = Class::Hookable->new;
my $plugin  = Plugin->new;

$hook->register_hook(
    $plugin,
    'once'      => \&once,
    'context'   => \&context,
    'foobar'    => $plugin->can('foo'),
    'foobar'    => $plugin->can('bar'),
    'dispatch'  => $plugin->can('foo'),
);

# -- run_hook test ------------------- #

is(
    $hook->run_hook_once('once', { foo => 'bar' }, \&callback),
    'FOO'
);

sub once {
    my ( $plugin, $context, $args ) = @_;

    isa_ok( $plugin, 'Plugin' );
    isa_ok( $context, 'Class::Hookable' );
    is_deeply(
        $args,
        { foo => 'bar' },
    );

    return 'FOO',
}

sub callback {
    my ( $result ) = @_;
    is( $result, 'FOO' );
}

is_deeply(
    [ $hook->run_hook('foobar') ],
    [qw( FOO BAR )],
);

# -- context test -------------------- #

$hook->hookable_context( Context->new );

$hook->run_hook_once('context');

sub context {
    my ( $plugin, $context, $args ) = @_;

    isa_ok( $context, 'Context' );
}

# -- dispatch_plugin test ------------ #

$hook->hookable_set_filter(
    'run_hook' => sub {
        my ( $self, $filter, $hook, $args, $action ) = @_;

        isa_ok( $self, 'Class::Hookable' );
        is( $filter, 'run_hook' );
        is( $hook, 'dispatch' );
        is( $args, undef );
        is_deeply(
            $action,
            {
                plugin      => $plugin,
                callback    => $plugin->can('foo'),
            }
        );

        return 0;
    },
);

is(
    $hook->run_hook_once('dispatch'),
    undef,
);

package Plugin;
sub new { bless {}, shift }
sub foo { 'FOO' }
sub bar { 'BAR' }

package Context;
sub new { bless {}, shift }
