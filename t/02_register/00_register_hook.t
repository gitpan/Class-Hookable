#!perl -T

use strict;
use warnings;

use Test::More tests => 7;
use Class::Hookable;

my $hook = Class::Hookable->new;
my $plugin = Plugin->new;

$hook->register_hook(
    $plugin,
    'foo.bar' => $plugin->can('foo'),
);

is(
    $hook->hookable_all_hooks->{'foo.bar'}->[0]->{'plugin'},
    $plugin,
);

is(
    $hook->hookable_all_hooks->{'foo.bar'}->[0]->{'callback'},
    $plugin->can('foo'),
);

$hook->hookable_set_filter(
    'register_hook' => sub {
        my ( $self, $filter, $hook, $action ) = @_;
        isa_ok( $self, 'Class::Hookable' );
        is( $filter, 'register_hook' );
        is( $hook, 'AAA.BBB' );
        is_deeply(
            $action,
            {
                plugin      => $plugin,
                callback    => $plugin->can('bar'),
            },
        );
    },
);

$hook->register_hook(
    $plugin,
    'AAA.BBB' => $plugin->can('bar'),
);

is(
    $hook->hookable_all_hooks->{'foo.bar'}->[1],
    undef,
);

package Plugin;

sub new { bless {}, shift }
sub foo {}
sub bar {}

1;
__END__
