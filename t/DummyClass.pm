package DummyClass;

use strict;
use warnings;
1;

package Context;

sub new { bless {}, shift }

1;

package Plugin;

sub new { bless {}, shift }
sub foo { 'FOO' }
sub bar { 'BAR' }

1;

package PluginA;

sub new { bless {}, shift }
sub foo {}
sub bar {}
1;

package PluginB;

sub new { bless {}, shift }
sub foo {}
sub bar {}
1;
__END__
