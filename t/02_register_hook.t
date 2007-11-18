#!perl -T

use strict;
use warnings;

use Test::More tests => 3;
use Class::Hookable;

my $hook = Class::Hookable->new;
my $plugin = Plugin->new;

$hook->register_hook(
    $plugin,
    'foo.bar' => $plugin->can('foo'),
);

is(
    $hook->hooks->{'foo.bar'}->[0]->{'plugin'},
    $plugin,
);

is(
    $hook->hooks->{'foo.bar'}->[0]->{'callback'},
    $plugin->can('foo'),
);

{
    no warnings 'redefine';
    *Class::Hookable::filter_plugin = sub { 0 };
}

$hook->register_hook(
    $plugin,
    'AAA.BBB' => $plugin->can('bar'),
);

is(
    $hook->hooks->{'foo.bar'}->[1],
    undef,
);

package Plugin;

sub new { bless {}, shift }
sub foo {}
sub bar {}

1;
__END__
