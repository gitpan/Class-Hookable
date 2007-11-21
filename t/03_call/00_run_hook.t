#!perl -T

use strict;
use warnings;

use Test::More tests => 5 + 2 + 4;
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

# -- context test -------------------- #

$hook->context( Context->new );

$hook->run_hook_once('context');

sub context {
    my ( $plugin, $context, $args ) = @_;

    isa_ok( $context, 'Context' );
}
is_deeply(
    [ $hook->run_hook('foobar') ],
    [qw( FOO BAR )],
);

# -- dispatch_plugin test ------------ #

no warnings 'redefine';
*Class::Hookable::filter_run_hook = sub {
    my ( $self, $hook, $args, $action ) = @_;

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
};

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
