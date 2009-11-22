package Class::Hookable;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

use vars qw( $VERSION );
$VERSION = '0.08';

sub new { bless {}, shift }

sub class_hookable_stash {
    my ( $self ) = @_;

    $self->{'Class::Hookable'} = {
        hooks   => {},
        methods => {},
        filters => {},
    } if ( ref $self->{'Class::Hookable'} ne 'HASH' );

    return $self->{'Class::Hookable'};
}


sub class_hookable_context {
    my $self = shift;

    if ( my $context = shift ) {
        $self->class_hookable_stash->{'context'} = $context;
    }

    return $self->class_hookable_stash->{'context'};
}

sub class_hookable_hooks      { shift->class_hookable_stash->{'hooks'}      }
sub class_hookable_methods    { shift->class_hookable_stash->{'methods'}    }
sub class_hookable_filters    { shift->class_hookable_stash->{'filters'}    }

sub class_hookable_set_filter {
    my ( $self, @filters ) = @_;

    while ( my ( $method, $filter ) = splice @filters, 0, 2 ) {
        Carp::croak "Invalid filter name. you can use [a-zA-Z_]"
            if ( $method =~ m{[^a-zA-Z_]} );

        Carp::croak "filter is not CODE reference."
            if ( ref $filter ne 'CODE' );

        $self->class_hookable_filters->{$method} = $filter;
    }

}

sub class_hookable_filter_prefix {
    my $self = shift;

    if ( my $prefix = shift ) {
        Carp::croak "Invalid filter prefix. you can use [a-zA-Z_]"
            if ( $prefix =~ m{^a-zA-Z_} );
        $self->class_hookable_stash->{'filter_prefix'} = $prefix;
    }
    else {
        my $prefix = $self->class_hookable_stash->{'filter_prefix'}
                   || 'class_hookable_filter';
        return $prefix;
    }
}

sub class_hookable_filter {
    my ( $self, $name, @args ) = @_;

    Carp::croak "Filter name is not specified."
        if ( ! $name );

    my $prefix  = $self->class_hookable_filter_prefix;

    my $filter  = $self->can("${prefix}_${name}")
               || $self->class_hookable_filters->{$name}
               || sub { 1 };

    return $filter->( $self, $name, @args );
}

sub register_hook {
    my ( $self, $plugin, @hooks ) = @_;

    Carp::croak "Plugin object is not blessed object or class name"
        if ( ref $plugin && ! Scalar::Util::blessed($plugin) );

    while ( my ( $hook, $callback ) = splice @hooks, 0, 2 ) {
        Carp::croak "Callback is not CODE reference."
            if ( ref $callback ne 'CODE' );

        my $action = {
            plugin      => $plugin,
            callback    => $callback,
        };

        if ( $self->class_hookable_filter( 'register_hook', $hook, $action ) ) {
            $self->class_hookable_hooks->{$hook} = []
                if ( ref $self->class_hookable_hooks->{$hook} ne 'ARRAY' );

            push @{ $self->class_hookable_hooks->{$hook} }, $action;
        }
    }
}

sub register_method {
    my ( $self, $plugin, @methods ) = @_;

    Carp::croak "Plugin object is not blessed obejct or class name."
        if ( ref $plugin && ! Scalar::Util::blessed($plugin) );

    while ( my ( $method, $function ) = splice @methods, 0, 2 ) {
        Carp::croak "Function is not CODE reference."
            if ( ref $function ne 'CODE' );

        my $action = {
            plugin      => $plugin,
            function    => $function,
        };

        if ( $self->class_hookable_filter( 'register_method', $method, $action ) ) {
            $self->class_hookable_methods->{$method} = $action;
        }
    }
}

sub registered_hooks {
    my $self = shift;

    if ( @_ == 0 ) {
        return ( wantarray )
            ? ( sort keys %{ $self->class_hookable_hooks } )
            : $self->class_hookable_hooks
            ;
    }
    else {
        my $object = shift;
        my $comp;
        my $return;

        if ( Scalar::Util::blessed($object) || ! ref $object ) {
            $comp = 'plugin';
        }
        elsif ( ref $object eq 'CODE') {
            $comp = 'callback';
        }
        else {
            Carp::croak "Unsupport object: Support objects are scalar, blessed object and CODE reference.";
        }

        $return = ( $comp eq 'plugin' )
                ? 'callback'
                : 'plugin'
                ;

        my @data;
        my @hooks;

        for my $hook ( sort keys %{ $self->class_hookable_hooks } ) {
            for my $action ( @{ $self->class_hookable_hooks->{$hook} || [] } ) {
                my $target = $action->{$comp};
                if ( $target eq $object ) {
                    push @data, ( $hook => $action->{$return} );
                    push @hooks, $hook;
                }
            }
        }

        my %count;
        @hooks = grep { ! $count{$_}++ } @hooks;

        return ( wantarray ) ? @hooks : \@data ;
    }
}

sub registered_methods {
    my $self = shift;

    if ( @_ == 0 ) {
        return ( wantarray )
            ? ( sort keys %{ $self->class_hookable_methods } )
            : $self->class_hookable_methods
            ;
    }
    else {
        my $object = shift;
        my $comp;
        my $return;

        if ( Scalar::Util::blessed($object) || ! ref $object ) {
            $comp = 'plugin';
        }
        elsif ( ref $object eq 'CODE') {
            $comp = 'function';
        }
        else {
            Carp::croak "Unsupport object: Support objects are scalar, blessed object and CODE reference.";
        }

        $return = ( $comp eq 'plugin' )
                ? 'function'
                : 'plugin'
                ;

        my @data;
        my @methods;

        for my $method ( sort keys %{ $self->class_hookable_methods } ) {
            my $action = $self->class_hookable_methods->{$method} || {};
            my $target = $action->{$comp};
            if ( $target eq $object ) {
                push @data, ( $method => $action->{$return} );
                push @methods, $method;
            }
        }

        my %count;
        @methods = grep { ! $count{$_}++ } @methods;

        return ( wantarray ) ? @methods : \@data ;
    }
}

sub remove_hook {
    my ( $self, %opt ) = @_;

    my $targets = delete $opt{'target'}
        or Carp::croak "Deletion 'target' is not specified.";
       $targets = [ $targets ] if ( ref $targets ne 'ARRAY' );
    my @tmp;
    for my $target ( @{ $targets } ) {
        if ( Scalar::Util::blessed($target) || ! ref $target ) {
            $target = { plugin => $target };
        }
        elsif ( ref $target eq 'CODE' ) {
            $target = { callback => $target };
        }
        elsif (  ref $target eq 'HASH') {}
        else {
            Carp::croak "Unsuppot target: $target";
        }
        push @tmp, $target;
    }
    $targets = \@tmp;


    my $froms = delete $opt{'from'} || [ $self->registered_hooks ];
       $froms = [ $froms ] if ( ref $froms ne 'ARRAY' );

    my $removed = {};
    for my $hook ( @{ $froms } ) {
        my @filtered = ();
        ACTION: for my $action ( @{ $self->class_hookable_hooks->{$hook} } ) {
            for my $target ( @{ $targets } ) {
                if ( defined $target->{'plugin'} && defined $target->{'callback'} ) {
                    if (
                        $action->{'plugin'} eq $target->{'plugin'}
                        && $action->{'callback'} eq $target->{'callback'}
                    ) {
                        push @{ $removed->{$hook} }, $action;
                        next ACTION;
                    }
                }
                elsif ( defined $target->{'plugin'} || defined $target->{'callback'} ) {
                    my $comp = ( defined $target->{'plugin'} )
                             ? 'plugin'
                             : 'callback' ;
                    if ( $action->{$comp} eq $target->{$comp} ) {
                        push @{ $removed->{$hook} }, $action;
                        next ACTION;
                    }
                }
                else {
                    Carp::croak "Compared target is not specified.";
                }
            }
            push @filtered, $action;
        }
        $self->class_hookable_hooks->{$hook} = \@filtered;
    }

    return $removed;
}

sub remove_method {
    my ( $self, %opt ) = @_;

    my $targets = delete $opt{'target'}
        or Carp::croak "Deletion 'target' is not specified.";
       $targets = [ $targets ] if ( ref $targets ne 'ARRAY' );
    my @tmp;
    for my $target ( @{ $targets } ) {
        if ( ! ref $target || Scalar::Util::blessed($target) ) {
            $target = { plugin => $target };
        }
        elsif ( ref $target eq 'CODE' ) {
            $target = { function => $target };
        }
        elsif ( ref $target eq 'HASH' ) {}
        else {
            Carp::croak "Unsupport target: $target";
        }
        push @tmp, $target;
    }
    $targets = \@tmp;

    my $froms = delete $opt{'from'} || [ $self->registered_methods ];
       $froms = [ $froms ] if ( ref $froms ne 'ARRAY' );

    my $removed = {};
    METHOD: for my $method ( @{ $froms } ) {
        my $action = $self->class_hookable_methods->{$method};
        for my $target ( @{ $targets } ) {
            if ( defined $target->{'plugin'} && defined $target->{'function'} ) {
                if (
                    $action->{'plugin'} eq $target->{'plugin'}
                    && $action->{'function'} eq $target->{'function'}
                ) {
                    $removed->{$method} = delete $self->class_hookable_methods->{$method};
                    next METHOD;
                }
            }
            elsif ( defined $target->{'plugin'} || defined $target->{'function'} ) {
                my $comp = ( defined $target->{'plugin'} )
                         ? 'plugin'
                         : 'function' ;
                if ( $action->{$comp} eq $target->{$comp} ) {
                    $removed->{$method} = delete $self->class_hookable_methods->{$method};
                    next METHOD;
                }
            }
            else {
                Carp::croak "Compared target is not specified.";
            }
        }
    }

    return $removed;
}

sub clear_hooks {
    my ( $self, @hooks ) = @_;
    @hooks = $self->registered_hooks if ( scalar @hooks <= 0 );

    my $removed = {};

    for my $hook ( @hooks ) {
        next if ( ! exists $self->class_hookable_hooks->{$hook} );
        $removed->{$hook} = delete $self->class_hookable_hooks->{$hook};
    }

    return $removed;
}

sub clear_methods {
    my ( $self, @methods ) = @_;
    @methods = $self->registered_methods if ( scalar @methods <= 0 );

    my $removed = {};
    for my $method ( @methods ) {
        next if ( ! exists $self->class_hookable_methods->{$method} );
        $removed->{$method} = delete $self->class_hookable_methods->{$method};
    }

    return $removed;
}

sub run_hook {
    my ( $self, $hook, $args, $once, $callback ) = @_;

    if ( defined $callback && ref $callback ne 'CODE' ) {
        Carp::croak "callabck is not code reference.";
    }

    if ( ! defined $hook ) {
        Carp::croak "hook name is not specified.";
    }

    my @results;

    my $context = ( defined $self->class_hookable_context ) ? $self->class_hookable_context : $self ;

    for my $action ( @{ $self->class_hookable_hooks->{$hook} || [] } ) {
        if ( $self->class_hookable_filter( 'run_hook', $hook, $action, $args ) ) {
            my $plugin = $action->{'plugin'};
            my $result = $action->{'callback'}->( $plugin, $context, $args );
            $callback->( $result ) if ( $callback );
            if ( $once ) {
                return $result if ( defined $result );
            }
            else {
                push @results, $result;
            }
        }
    }

    return if ( $once );
    return @results;
}

sub run_hook_once {
    my ( $self, $hook, $args, $callback ) = @_;
    return $self->run_hook( $hook, $args, 1, $callback );
}

sub call_method {
    my ( $self, $method, $args ) = @_;

    if ( ! defined $method ) {
        Carp::croak "method name is not specified.";
    }

    my $context = ( defined $self->class_hookable_context )
                ? $self->class_hookable_context
                : $self ;

    my $action  = $self->class_hookable_methods->{$method};
    return if ( ! $action );

    if ( $self->class_hookable_filter( 'call_method', $method, $action, $args ) ) {
        my ( $plugin, $function ) = @{ $action }{qw( plugin function )};
        my $result = $function->( $plugin, $context, $args );
        return $result;
    }
    else {
        return;
    }
}

1;
__END__

=head1 NAME

Class::Hookable - Base class for hook mechanism

=head1 SYNOPSIS

  package MyApp::Plugins;
  use base qw( Class::Hookable );
  
  my $hook = MyApp::Plugins->new;
  
  $hook->register_hook(
      $plugin,
      'hook.name' => $plugin->can('callback'),
  );
  
  $hook->run_hook('hook.name', $args);

=head1 DESCRIPTION

Class::Hookable is the base class for the hook mechanism.
This module supports the hook mechanism like L<Plagger>.

This module was made based on the hook mechanism of L<Plagger>.
I thank Tatsuhiko Miyagawa and Plagger contributors.

B<NOTE>:

Class::Hookable is having substantial changes from version 0.05 to version0.06.
When using Class::Hookable, please be careful.

Please see Changes file about a change point.

=head1 BASIC METHOD

=head2 new

  my $hook = Class::Hookalbe->new;

This method is a constructor of Class::Hookable.
Nothing but that is being done.

=head1 REGISTER METOHDS

=head2 register_hook

  $hook->register_hook(
      $plugin,
      'hook.A' => $plugin->can('callbackA'),
      'hook.B' => $plugin->can('callbackB'),
  );

This method registers a plugin object and callbacks which corresponds to hooks.

The plugin object is specified as the first argument,
and one after that is specified by the order of C<'hook' =E<gt> \&callabck>.

Only when C<$hook-E<gt>class_hookable_filter( 'run_hook', $hook, $action )> has returned truth,
the callback specified by this method is registered with a hook.

Please see L<"class_hookable_filter"> about C<$hook-E<gt>class_hookable_filter>.

=head2 register_method

  $hook->register_method(
      $plugin,
      'method.A' => $plugin->can('methodA'),
      'method.B' => $plugin->can('methodB'),
  );

This method registers a plugin and functions with the methods.

The specification of arguments is same as L<"register_hook"> method.

The method is different from B<hook> and only a set of plugin and function are kept about one method.
When specifying the method name which exists already, the old method is replaced with the new method.

Only when C<$hook-E<gt>class_hookable_filter( 'register_method', $method, $action )> has returned truth,
this method registers a plugin and function.

Please see L<"class_hookable_filter"> about C<$hook-E<gt>class_hookable_filter>.

=head1 CALL METHODS

=head2 run_hook

  $hook->run_hook( $hook, $args, $once, $callback );
  my @results = $hook->run_hook('hook.name', \%args, undef, \&callback);
  my $result  = $hook->run_hook('hook.name', \%args, 1, \&callback);

This method calls callback of the registered plugin to hook by the registered order.
Arguments are specified by the order of C<$hook>, C<$args>, C<$once> and C<$callback>.

B<Arguments to run_hook method>:

=over

=item C<$hook>

Designation of the hook with which a plugin was registered.
This argument is indispensable.

=item C<$args>

The argument which passes it to callback.
This argument is optional.

=item C<$once>

When this argument becomes true, this method finishes calling callback
when the first return value has been received.

This argument is optional.

=item C<$callback>

  my $callback = sub {
      my ( $result ) = @_;
      # some code
  }

This argument specifies code reference.

When having received a return value from callback of the registered,
the callback specified by this argument is called.

A return value of callback of registered plugin is passed to an argument of this callback.

=back

B<Arguments of registered callback>:

  sub callback {
      my ( $plugin, $context, $args ) = @_;
      # some code
  }

The argument by which it is passed to callback is C<$plugin>, C<$context>, C<$args>.

=over

=item C<$plugin>

The plugin object which passed a plugin and callback to the register_hook method when registering.

=item C<$context>

The context object.

When C<$hook-E<gt>hookable_context> is specified, the specified object is passed,
and when it isn't so, object of Class::Hookable (or object of inherited Class::Hookable class) is passed.

Please see L<"hookable_context"> about context object which can be specified in C<$hook-E<gt>hookable_context>.

=item C<$args>

the argument specified by the run_hook method.

=back

Only when C<$hook-E<gt>class_hookable_filter( 'run_hook', $hook, $action, $args )> has returned truth,
this method calls callback.

Please see L<"class_hookable_filter"> about C<$hook-E<gt>class_hookable_filter>.

=head2 run_hook_once

  my $result = $hook->run_hook_once( $hook, $args, $callback );

This method is an alias of C<$hook-E<gt>run_hook( $hook, $args, 1, \&callback )>.

=head2 call_method

  my $result = $hook->call_method( $method => $args );

This method calls function of the registered plugin to method.
Arguments are specified by the order of C<$method> and C<$args>.

When the function was not found,
no this methods are returned.

B<Arguments of call_method method>:

=over

=item C<$method>

Designation of the method name with which a plugin was registered.
This argument is indispensable.

=item C<$args>

The argument which passes it to function.
This argument is optional.

=back

B<Arguments of registered function>:

  sub function {
      my ( $plugin, $context, $args ) = @_;
      # some code
  }

The argument by which it is passed to callback is C<$plugin>, C<$context>, C<$args>.

=over

=item C<$plugin>

The plugin object which passed a plugin and function to the register_method method when registering.

=item C<$context>

When C<$hook-E<gt>hookable_context> is specified, the specified object is passed,
and when it isn't so, object of Class::Hookable (or object of inherited Class::Hookable class) is passed.

Please see L<"class_hookable_context"> about context object which can be specified in C<$hook-E<gt>hookable_context>.

=item C<$args>

The argument specified by the run_hook method.

=back

Only when C<$hook-E<gt>class_hookable_filter( 'call_method', $method, $action, $args )> has returned truth,
this method calls function.

Please see L<"class_hookable_filter"> about C<$hook-E<gt>class_hookable_filter>.

=head1 FILTER METHODS

=head2 class_hookable_set_filter

  $hook->class_hookable_set_filter(
      register_hook => \&filterA
      run_hook      => \&filterB,
  );

This method registers the filter of hook and method.

Arguments are specified by the order of C<'name' =E<gt> \&filter>.
The character which can be used for the filter name is C<[a-zA-Z_]>.

When registering a homonymous filter of the filter registered already,
a old filter is replaced with a new filter.

Please see L<"class_hookable_filter"> about a calling of the filter.

=head2 class_hookable_filter_prefix

  $hook->class_hookable_filter_prefix('myfilter_prefix');

This method is accessor of filter prefix.

When finding filter in C<$hook-E<gt>class_hookable_filter> method,
prefix specified by this method is used.

The character which can be used for the filter prefix is C<[a-zA-Z_]>.

When prefix is not specified, this method returns C<'class_hookable_filter'> by default.

=head2 class_hookable_filter

  my $result = $hook->class_hookable_filter( $filter => @args );

This method calls a specified filter.

A filter name is specified as the first argument
and an argument to a filter is specified as an argument after that.

B<Search of filter>:

This method searches for a filter from several places.

First, when C<$hook-E<gt>can("${prefix}_${filter_name}")> is defined,
its method is used as a filter.

C<${prefix}> is return value of C<$hook-E<gt>class_hookable_filter_prefix>,
and C<${filter_name}> is the filter name specified as this method.

Please see L<"class_hookable_filter_prefix"> about C<$hook-E<gt>class_hookable_filter_prefix>.

Next when a specified filter is specified by C<$hook-E<gt>class_hookable_set_filter> method,
the filter is used.

When a filter was not found, this method uses the filter to which truth is just always returned.

B<Arguments of filter>:

  $hook->class_hookable_set_filter(
      register_hook     => sub {
          my ( $self, $filter, $hook, $action ) = @_;
      },
      register_method   => sub {
          my ( $self, $filter, $method, $action ) = @_;
      },
      run_hook          => sub {
          my ( $self, $filter, $hook, $action, $args ) = @_;
      },
      call_method       => sub {
          my ( $self, $filter, $method, $action, $args ) = @_;
      },
  )

The filters Class::Hookable calls are C<'register_hook'>, C<'register_method'>,
C<'run_hook'> and C<'call_method'>, and the argument to which it's passed is as follows.

=over

=item C<$self>

Instance of Class::Hookable ( or the class inheriting to Class::Hookable ).

This argument is passed to all filters.

=item C<$filter>

The filter name called in C<$hook-E<gt>class_hookable_filter>.

This argument is passed to all filters.

=item C<@args>

Arguments to the filter to which it was passed by C<$hook-E<gt>class_hookable_filter>.

The argument when Class::Hookable calls a filter, is as follows.

=over

=item C<$hook> or C<$method>

the hook name or the method name.

This argument is passed to all C<'register_hook'>, C<'reigster_method'>, C<'run_hook'> and C<'call_method'>.

=item C<$action>

  # In case of hook
  my ( $plugin, $callback ) = @{ $action }{qw( plugin callback )};

  # In case of method
  my ( $plugin, $function ) = @{ $action }{qw( plugin function )};

The hash reference including the plugin and the callback or function.

This argument is passed to all C<'register_hook'>, C<'reigster_method'>, C<'run_hook'> and C<'call_method'>.

=item C<$args>

The argument specified by the L<run_hook> or L<call_method> method.

This argument is passed to C<'run_hook'> and C<'call_method'>.

=back

=back

=head1 UTILITY METHODS

=head2 registered_hooks

  my $all_hook_data = $hook->registered_hooks;
  #  $all_hook_data = { 'hook.name' => [ { plugin => $plugin callback => \&callback }, ... ] ... };

  my @all_hook_name = $hook->registered_hooks;
  #  @all_hook_name = qw( hook.A hook.B hook.C ... );
  
  my $registered_data = $hook->registered_hooks( $plugin );
  #  $registered_data = [ 'hook.A' => \&callabck, 'hook.B' => \&callback, ... ];
  
  my @registered_hooks = $hook->registered_hooks( $plugin );
  #  @registered_hooks = qw( hook.A hook.B hook.C ... );
  
  my $registered_data = $hook->registered_hooks( \&callback );
  #  $registered_data = [ 'hook.A' => $plugin, 'hook.B' => $plugin, ... ];

  my @registered_hooks = $hook->registered_hooks( \&callback );
  #  @registered_hooks = qw( hook.A hook.B hook.C ... );

This method gets registered data or a hook name.

This method returns registered data in scalar context
and returns registered hooks name in list context.

B<List of arguments and return values>:

=over

=item when there are no arguments

=over

=item scalar context

This method returns all registered data.

This data is same as C<$hook-E<gt>class_hookable_hooks>.

=item list context

This method returns a registered all hook name.

=back

=item when a registered C<$plugin> object was specified

=over

=item scalar context

This method returns the hook name with which a plugin is registered
and the callback when registering.

The returned value is ARRAY reference, and the contents are the following feeling.

  [
      'hook.A' => \&callbackA,
      'hook.B' => \&callbackB,
      ...
  ]

=item list context

This method returns the hook name with which a plugin is registered.

=back

=item when registered C<\&callback> was specified

=over

=item scalar context

This method returns the hook name with which callback is registered
and the plugin when registering.

The returned value is ARRAY reference, and the contents are the following feeling.

  [
      'hook.A' => $plugin,
      'hook.B' => $plugin,
      ...
  ]

=item list context

This method returns the hook name with which callback is registered.

=back

=back

=head2 registered_methods

  my $all_hook_data = $hook->registered_methods;
  #  $all_hook_data = { 'method.name' => { plugin => $plugin, function => \&function, }, ... };

  my @all_hook_name = $hook->registered_methods;
  #  @all_hook_name = qw( method.A method.B method.C ... );
  
  my $registered_data = $hook->registered_methods( $plugin );
  #  $registered_data = [ 'method.A' => \&function, 'method.B' => \&function, ... ];
  
  my @registered_methods = $hook->registered_methods( $plugin );
  #  @registered_methods = qw( method.A method.B method.C ... );
  
  my $registered_data = $hook->registered_methods( \&function );
  #  $registered_data = [ 'method.A' => \&function, 'method.B' => \&function ];

  my @registered_methods = $hook->registered_hooks( \&function );
  #  @registered_methods = qw( method.A method.B method.C ... );

This method gets registered data or a method name.

This method returns registered data in scalar context
and returns registered methods name in list context.

B<List of arguments and return values>:

=over

=item when there are no arguments

=over

=item scalar context

This method returns all registered data.

This data is same as C<$hook-E<gt>class_hookable_methods>.

=item list context

This method returns a registered all method name.

=back

=item when a registered C<$plugin> object was specified

=over

=item scalar context

This method returns the method name with which a plugin is registered
and the function when registering.

The returned value is ARRAY reference, and the contents are the following feeling.

  [
      'method.A' => \&functionA,
      'method.B' => \&functionB,
      ...
  ]

=item list context

This method returns the method name with which a plugin is registered.

=back

=item when registered C<\&function> was specified

=over

=item scalar context

This method returns the method name with which function is registered
and the plugin when registering.

The returned value is ARRAY reference, and the contents are the following feeling.

  [
      'method.A' => $plugin,
      'method.B' => $plugin,
      ...
  ]

=item list context

This method returns the hook name with which callback is registered.

=back

=back

=head2 remove_hook

  $hook->remove_hook( target => $plugin );
  $hook->remove_hook( target => $plugin->can('callback') );
  $hook->remove_hook( target => { plugin => $plugin, callback => $plugin->can('callback') } );
  $hook->remove_hook( target => [ $pluginA \&callbackB, \%expressonC ] );
  
  $hook->remove_hook( target => $plugin, from => 'hook.name' );
  $hook->remove_hook( target => $plugin, from => [qw( hook.A hook.B )] );
  
  $hook->remove_hook( target => \@targets, from => \@hooks );
  
  my $removed = $hook->remove_hook( target => $plugin );

This method deleted hook which matches the specified condition.

B<About Arguments>:

=over

=item C<'target'>

An deleted target is specified.

They are C<$plugin>, C<\&callback> and C<\%hash_ref> that it can be specified as this argument.

When specifying plugin and callback in hash reference, hook with designated plugin and calllback is deleted.

It is possible to specify more than one deletion target using Array reference.

This argument is indispensable.

=item C<'from'>

It is specified in which hook an deletion target is deleted.

More than one hook can be specified by using Arrary reference.

When this argument was not specified, an deletion target is deleted from all hook.

=back

B<About Return value>

This method returns deleted hook to a return value.

A return value is the following feeling:

  $removed = {
      'hook.A' => [
          { plugin => $plugin, callback => \&callback },
          { plugin => $plugin, callback => \&callback },
      ],
      'hook.B' => [
          { plugin => $plugin, callback => \&callback },
          { plugin => $plugin, callback => \&callback },
      ],
  }

=head2 remove_method

  $hook->remove_method( target => $plugin );
  $hook->remove_method( target => $plugin->can('function') );
  $hook->remove_method( target => { plugin => $plugin, function => $plugin->can('function') } );
  $hook->remove_method( target => [ $pluginA \&functionB, \%expressonC ] );
  
  $hook->remove_method( target => $plugin, from => 'method.name' );
  $hook->remove_method( target => $plugin, from => [qw( method.A method.B )] );
  
  $hook->remove_method( target => \@targets, from => \@methods, );
  
  my $removed = $hook->remove_method( target => $plugin );

This method deleted method which matches the specified condition.

B<About Arguments>:

=over

=item C<'target'>

An deleted target is specified.

They are C<$plugin>, C<\&function> and C<\%hash_ref> that it can be specified as this argument.

When specifying plugin and callback in hash reference, hook with designated plugin and function is deleted.

It is possible to specify more than one deletion target using Array reference.

This argument is indispensable.

=item C<'from'>

It is specified in which method an deletion target is deleted.

More than one method can be specified by using Arrary reference.

When this argument was not specified, an deletion target is deleted from all method.

=back

B<About Return value>

This method returns deleted method to a return value.

A return value is the following feeling:

  $removed = {
      'method.A' => { plugin => $plugin, function => \&function },
      'method.B' => { plugin => $plugin, function => \&function },
  }

=head2 clear_hooks

  # clear 'hook.A' and 'hook.B'
  $hook->clear_hooks(qw( hook.A hook.B ));
  
  # clear all
  $hook->clear_hooks;
  
  my $removed = $hook->clear_hooks;

This method deleted all registered hooks.

An deleted hook name is specified as an argument.

When arguments were specified, all plugin registered with specified hooks are deleted,
and when arguments are not specified, all plugins are deleted from all hooks.

A return value of this method is such feeling:

  $removed = {
      'hook.A' => [
          { plugin => $pluginA, callback => $pluginA->can('foo') },
          { plugin => $pluginB, callback => $pluginB->can('bar') },
          ...
      ],
      'hook.B' => [
          { plugin => $pluginA, callback => $pluginA->can('foo') },
          { plugin => $pluginB, callback => $pluginB->can('bar') },
          ...
      ],
      ...
  };

=head2 clear_methods

  # clear 'method.A' and 'methodB'
  $hook->clear_methods(qw( method.A method.B ));
  
  # clear all
  $hook->clear_methods;
  
  my $removed = $hook->clear_methods;

This method deletes all registered method.

An deleted method name is specified as an argument.

When arguments were specified, a plugin registered with specified method is deleted,
and when arguments are not specified, all plugins are deleted from all methods.

A return value of this method is such feeling:

  $removed = {
      'method.A' => { plugin => $pluginA, function => $pluginA->can('foo') },
      'method.B' => { plugin => $pluginB, function => %pluginB->can('bar') },
      ...
  };

=head1 ACCESSOR METOHDS

=head2 class_hookable_stash

  my $data = $hook->class_hookable_stash;

This method is stash in Class::Hookable.
All variables Class::Hookable needs are put here.

This method does not get arguments,
and return hash reference includes all variables.

=head2 class_hookable_context

  # set
  $hook->class_hookable_context( $context );
  # get
  my $context = $hook->class_hookable_context;

This method is accessor of context object.

Context object specified by this method is passed as the second argument of
the subroutine registered with hook and method.

see also L<"run_hook"> and L<"call_method">.

=head2 class_hookable_hooks

  my $hooks = $hook->class_hookable_hooks;

This method is accessor to hash reference which keeps hooks.
all method of Class::Hookable is accessing hooks through this method.

=head2 class_hookable_methods

  my $methods = $hook->class_hookable_methods;

This method is accesor to hash reference which keeps methods.
all method of Class::Hookable is accessing methods through this method.

=head2 class_hookable_filters

  my $filters = $hook->class_hookable_filters;

This method is accessor to hash reference which keeps filters.
all filter of Class::Hookable is accessing filters through this method.

=head1 AUTHOR

Original idea by Tatsuhiko Miyagawa L<http://search.cpan.org/~miyagawa> in L<Plagger>

Code by Naoki Okamura (Nyarla) E<lt>nyarla[:)]thotep.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
