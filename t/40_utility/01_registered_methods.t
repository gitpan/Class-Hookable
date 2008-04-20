#!perl -T

use strict;
use warnings;

use Test::More tests => 2 + 4 + 2;
use Class::Hookable;
use lib 't';
use DummyClass;

my $hook    = Class::Hookable->new;
my $plugin  = Plugin->new;


$hook->register_method(
    $plugin,
    'method.A' => $plugin->can('foo'),
    'method.B' => $plugin->can('bar'),
);

$hook->register_method(
    'Plugin',
    'method.C' => $plugin->can('foo'),
    'method.D' => $plugin->can('bar'),
);

# ------------------------------------ #

my $data = $hook->registered_methods;

is_deeply(
    $data,
    $hook->class_hookable_methods,
);

is_deeply(
    [ $hook->registered_methods ],
    [qw( method.A method.B method.C method.D )],
);

# ------------------------------------ #

$data = $hook->registered_methods( $plugin );

is_deeply(
    $data,
    [
        'method.A' => $plugin->can('foo'),
        'method.B' => $plugin->can('bar'),
    ],
);

is_deeply(
    [ $hook->registered_methods( $plugin ) ],
    [qw( method.A method.B )],
);

$data = $hook->registered_methods('Plugin');

is_deeply(
    $data,
    [
        'method.C' => Plugin->can('foo'),
        'method.D' => Plugin->can('bar'),
    ],
);

is_deeply(
    [ $hook->registered_methods('Plugin') ],
    [qw( method.C method.D )],
);

# ------------------------------------ #

$data = $hook->registered_methods( $plugin->can('foo') );

is_deeply(
    $data,
    [
        'method.A' => $plugin,
        'method.C' => 'Plugin',
    ],
);

is_deeply(
    [ $hook->registered_methods( Plugin->can('bar') ) ],
    [qw( method.B method.D )],
);
