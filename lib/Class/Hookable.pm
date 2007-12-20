package Class::Hookable;

use strict;
use warnings;

use Carp ();
use Scalar::Util();

use vars qw( $VERSION );
$VERSION = '0.03';

sub new { bless {}, shift }

sub hookable_stash {
    my ( $self ) = @_;

    if ( ref $self->{'Class::Hookable'} ne 'HASH' ) {
        $self->{'Class::Hookable'} = {
            hooks   => {},
            methods => {},
            filters => {},
        };
    }

    return $self->{'Class::Hookable'};
}


sub hookable_context {
    my $self = shift;

    if ( @_ ) {
        my $context = shift;
        if ( ref($context) && ! Scalar::Util::blessed($context) ) {
            Carp::croak "Argument is not blessed object or class name.";
        }
        $self->hookable_stash->{'context'} = $context;
    }

    return $self->hookable_stash->{'context'};
}

sub hookable_all_hooks {
    my $self = shift;
    return $self->hookable_stash->{'hooks'};
}

sub hookable_all_methods {
    my $self = shift;
    return $self->hookable_stash->{'methods'};
}

sub hookable_set_filter {
    my ( $self, @filters ) = @_;

    while ( my ( $method, $filter ) = splice @filters, 0, 2 ) {
        Carp::croak "Invalid filter name. you can use [a-zA-Z_]"
            if ( $method =~ m{[^a-zA-Z_]} );

        Carp::croak "filter is not CODE reference."
            if ( ref $filter ne 'CODE' );

        $self->hookable_stash->{'filters'}->{$method} = $filter;
    }

}

sub hookable_filter_prefix {
    my $self = shift;

    if ( @_ ) {
        my $prefix = shift;
        Carp::croak "Invalid filter prefix. you can use [a-zA-Z_]"
            if ( $prefix =~ m{[^a-zA-Z_]} );
        $self->hookable_stash->{'filter_prefix'} = $prefix;
    }
    else {
        return $self->hookable_stash->{'filter_prefix'};
    }
}

sub hookable_call_filter {
    my ( $self, $name, @args ) = @_;

    Carp::croak "Filter name is not specified."
        if ( ! $name );

    my $prefix = $self->hookable_filter_prefix
              || 'hookable_filter';

    my $filter   = $self->hookable_stash->{'filters'}->{$name};
       $filter ||= $self->can("${prefix}_${name}");
       $filter ||= sub { return 1 };

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

        if ( $self->hookable_call_filter( 'register_hook', $hook, $action ) ) {
            $self->hookable_all_hooks->{$hook} = []
                if ( ref $self->hookable_all_hooks->{$hook} ne 'ARRAY' );

            push @{ $self->hookable_all_hooks->{$hook} }, $action;
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

        if ( $self->hookable_call_filter( 'register_method', $method, $action ) ) {
            $self->hookable_all_methods->{$method} = $action;
        }
    }
}

sub registered_hooks {
    my $self = shift;

    my @hooks;

    if ( @_ > 0 ) {
        my $object = shift;

        if ( ref $object && ! Scalar::Util::blessed( $object ) ) {
            Carp::croak "Argument is not blessed object or class name.";
        }

        my $is_class = ( ! ref $object ) ? 1 : 0 ;

        for my $hook ( keys %{ $self->hookable_all_hooks } ) {
            for my $action ( @{ $self->hookable_all_hooks->{$hook} } ) {
                my $plugin = $action->{'plugin'};
                my $class  = ref $plugin || $plugin;
                if ( $is_class ) {
                    push @hooks, $hook if ( $class eq $object );
                }
                else {
                    push @hooks, $hook if ( $plugin eq $object );
                }
            }
        }
    }
    else {
        @hooks = keys %{ $self->hookable_all_hooks };
    }

    @hooks = sort { $a cmp $b } @hooks;
    return @hooks;
}

sub registered_callbacks {
    my ( $self, $hook ) = @_;

    Carp::croak "Hook name is not specified." if ( ! defined $hook );

    my $list = $self->hookable_all_hooks->{$hook};
       $list ||= [];

    return @{ $list };
}

sub registered_methods {
    my $self    = shift;
    my @methods = ();

    if ( @_ > 0 ) {
        my $object = shift;

        if ( ref $object && ! Scalar::Util::blessed($object) ) {
            Carp::croak "Argument is not blessed object or class name.";
        }

        my $is_class = ( ! ref $object ) ? 1 : 0 ;

        for my $method ( keys %{ $self->hookable_all_methods } ) {
            my $plugin  = $self->hookable_all_methods->{$method}->{'plugin'};
            next if ( ! defined $plugin );
            my $class   = ref $plugin || $plugin;
            if ( $is_class ) {
                push @methods, $method if ( $class eq $object );
            }
            else {
                push @methods, $method if ( $plugin eq $object );
            }
        }
    }
    else {
        @methods = keys %{ $self->hookable_all_methods };
    }

    @methods = sort { $a cmp $b } @methods;
    return @methods;
}

sub registered_function {
    my ( $self, $method ) = @_;

    Carp::croak "Method name is not specified"
        if ( ! $method );

    my $action = $self->hookable_all_methods->{$method};

    return if ( ! $action );
    return $action;
}

sub delete_hook {
    my ( $self, $hook, @plugins ) = @_;

    Carp::croak "Hook is not specified." if ( ! defined $hook );

    if ( @plugins == 0 ) {
        $self->hookable_all_hooks->{$hook} = [];
    }
    else {
        my @new;
        for my $action ( $self->registered_callbacks( $hook ) ) {
            my $plugin = $action->{'plugin'};
            my $class  = ref $plugin || $plugin;
            for my $object ( @plugins ) {
                if ( ref $object && ! Scalar::Util::blessed($object) ) {
                    Carp::croak "Argument is not blessed object or class name.";
                }

                my $is_class = ( ! ref $object ) ? 1 : 0 ;
                if ( $is_class ) {
                    push @new, $action if ( $class ne $object );
                }
                else {
                    push @new, $action if ( $plugin ne $object );
                }
            }
        }
        $self->hookable_all_hooks->{$hook} = \@new;
    } 
}

sub delete_callback {
    my ( $self, $callback, @hooks ) = @_;

    Carp::croak "Callback is not CODE reference."
        if ( ref $callback ne 'CODE' );

    @hooks = $self->registered_hooks
        if ( @hooks == 0 );

    for my $hook ( @hooks ) {
        my @new;
        for my $action ( $self->registered_callbacks( $hook ) ) {
            if ( $action->{'callback'} ne $callback ) {
                push @new, $action;
            }
        }
        $self->hookable_all_hooks->{$hook} = \@new;
    }
}

sub delete_method {
    my ( $self, $method, @plugins ) = @_;

    Carp::croak "Method name is not specified."
        if ( ! defined $method );

    return if ( ! defined $self->hookable_all_methods->{$method} );

    my $plugin = $self->hookable_all_methods->{$method}->{'plugin'};
    my $class  = ref $plugin || $plugin;

    if ( @plugins == 0 ) {
        delete $self->hookable_all_methods->{$method};
    }
    else {
        for my $object ( @plugins ) {
            my $is_class = ( ! ref $object ) ? 1 : 0 ;
            if ( $is_class ) {
                delete $self->hookable_all_methods->{$method}
                    if ( $class eq $object );
            }
            else {
                delete $self->hookable_all_methods->{$method}
                    if ( $plugin eq $object );
            }
        }
    }
}

sub delete_function {
    my ( $self, $function, @methods ) = @_;

    Carp::croak "Function is not CODE reference."
        if ( ref $function ne 'CODE' );

    @methods = $self->registered_methods
        if ( @methods == 0 );

    for my $method ( @methods ) {
        my $action = $self->registered_function( $method );
        if ( $action->{'function'} eq $function ) {
            $self->delete_method( $method );
        }
    }
}

sub delete_plugin {
    my ( $self, $object, @points ) = @_;

    if ( ref $object && ! Scalar::Util::blessed($object) ) {
        Carp::croak "Argument is not blessed object or class name.";
    }

    if ( @points == 0 ) {
        push @points, $self->registered_hooks( $object );
        push @points, $self->registered_methods( $object );
    }

    for my $point ( @points ) {
        $self->delete_hook( $point => $object );
        $self->delete_method( $point => $object );
    }
}

sub run_hook {
    my ( $self, $hook, $args, $once, $callback ) = @_;

    if ( defined $callback && ref $callback ne 'CODE' ) {
        Carp::croak "callabck is not code reference.";
    }
    

    my @results;

    my $context = ( defined $self->hookable_context ) ? $self->hookable_context : $self ;

    for my $action ( $self->registered_callbacks( $hook ) ) {
        if ( $self->hookable_call_filter( 'run_hook', $hook, $args, $action ) ) {
            my $plugin = $action->{'plugin'};
            my $result = $action->{'callback'}->( $plugin, $context, $args );
            $callback->( $result ) if ( $callback );
            if ( $once ) {
                return $result if ( defined $once );
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

Class::Hookable is having substantial changes from version 0.02 to version0.03.
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

Only when C<$hook-E<gt>hookable_call_filter( 'run_hook', $hook, $action )> has returned truth,
the callback specified by this method is registered with a hook.

Please see L<"hookable_call_filter"> about C<$hook-E<gt>hookable_call_filter>.

B<Arguments of C<$hook-E<gt>hookable_call_filter>>:

  $hook->hookable_call_filter( 'run_hook', $hook, $action );

=over 3

=item 'run_hook'

C<'run_hook'> is filter name.

=item $hook

The hook name specified as the register_hook method.

=item $action

  my ( $plugin, $callback ) = @{ $action }{qw( plugin callback )};

The hash reference including plugin and callback.

=back

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

Only when C<$hook-E<gt>hookable_call_filter( 'register_method', $method, $action )> has returned truth,
this method registers a plugin and function.

Please see L<"hookable_call_filter"> about C<$hook-E<gt>hookable_call_filter>.

B<Arguments of C<$hook-E<gt>hookable_call_filter>>:

=over 3

=item C<'register_method'>

C<'run_hook'> is filter name.

=item C<$method>

The method name specified as the register_method method.

=item C<$action>

  my ( $plugin, $function ) = @{ $action }{qw( plugin function )};

The hash reference including plugin and function.

=back

=head1 CALL METHODS

=head2 run_hook

  $hook->run_hook( $hook, $args, $once, $callback );
  my @results = $hook->run_hook('hook.name', \%args, undef, \&callback);
  my $result  = $hook->run_hook('hook.name', \%args, 1, \&callback);

This method calls callback of the registered plugin to hook by the registered order.
Arguments are specified by the order of C<$hook>, C<$args>, C<$once> and C<$callback>.

B<Arguments to run_hook method>:

=over 4

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

=over 3

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

B<Arguments of C<$hook-E<gt>hookable_call_filter>>:

  $hook->hookable_call_filter( 'run_hook', $hook, $args, $action );

Only when C<$hook-E<gt>hookable_call_filter( 'run_hook', $hook, $args, $action )> has returned truth,
this method calls callback.

Please see L<"hookable_call_filter"> about C<$hook-E<gt>hookable_call_filter>.

=over 4

=item 'run_hook'

C<'run_hook'> is filter name.

=item C<$hook>

The hook name specified by the run_hook method.

=item C<$args>

The argument specified by the run_hook method.

=item C<$action>

  my ( $plugin, $callback ) = @{ $action }{qw( plugin callback )};

The hash reference including the plugin and the callback.

=back

=head2 run_hook_once

  my $result = $hook->run_hook_once( $hook, $args, $callback );

This method is an alias of C<$hook-E<gt>run_hook( $hook, $args, 1, \&callback )>.

=head1 FILTER METHODS

=head2 hookable_set_filter

  $hook->hookable_set_filter(
      register_hook => \&filterA
      run_hook      => \&filterB,
  );

This method registers the filter of hook and method.

Arguments are specified by the order of C<'name' =E<gt> \&filter>.
The character which can be used for the filter name is C<[a-zA-Z_]>.

When registering a homonymous filter of the filter registered already,
a old filter is replaced with a new filter.

Please see L<"hookable_call_filter"> about a calling of the filter.

=head2 hookable_call_filter

  my $bool = $hook->hookable_call_filter( $name => @args );

This method calls a specified filter.

A filter name is specified as the first argument
and an argument to a filter is specified as an argument after that.

B<Search of filter>:

This method searches for a filter from several places.

First, when a specified filter is specified by C<$hook-E<gt>hookable_set_filter> method, 
the filter is used.

Next when C<$hook-E<gt>can("${prefix}_${filter_name}")> is defined,
its method is used as a filter.

C<${prefix}> is return value of $hook->hookable_filter_prefix,
and C<${filter_name}> is the filter name specified as this method.

When C<$hook-E<gt>hookble_filter_perfix> is not specified, 
C<${prefix}> will be C<'hookable_filter'>.

Please see L<"hookable_filter_prefix"> about C<$hook-E<gt>hookable_filter_prefix>.

When a filter wasn't found, this method uses the filter to which truth is just always returned.

B<Arguments of filter>:

  $hook->hookable_set_filter(
      'run_hook' => sub {
          my ( $hook, $filter, @args ) = @_;
      },
  );

=over 3

=item C<$hook>

Instance of Class::Hookable (or the class inheriting to Class::Hookable).

=item C<$filter>

The filter name called in C<$hook-E<gt>hookable_call_filter>.

=item C<@args>

Arguments to the filter to which it was passed by C<$hook-E<gt>hookable_call_filter>.

=back

=head2 hookable_filter_prefix

  $hook->hookable_filter_prefix('myfilter_prefix');

This method is accessor of filter prefix;

When finding filter in call_filer_method,
prefix specified by this method is used.

The character which can be used for the filter prefix is C<[a-zA-Z_]>.

=head1 UTILITY METHODS

=head2 registered_hooks

  my @hooks = $hook->registered_hooks( $plugin );
  my @hooks = $hook->registered_hooks( 'ClassName' );

This method returns a registered hook name.

When calling without arguments, all registered hook name is returned.

And when specifying plugin obejct (or Class name) as an argument,
the hook name with which a plugin is registered is returned.

=head2 registered_callbacks

  for my $action ( $hook->registered_callbacks('hook.name') ) {
      my ( $plugin, $callback ) = @{ $action }{qw( plugin callback )};
      # some code
  }

This method returns plugin and callback registered with a hook.

Return value is a list of hash reference including plugin and callback.
When there are no registered plugin and callback, this method returns empty list.

=head2 registered_methods

  my @methods = $hook->registered_methods( $plugin );
  my @methods = $hook->registered_methods( 'ClassName' );

This method returns a registered method names.

When calling without arguments, all registered method name is returned.
and When specifying plugin object (or class name) as an arguments,
the method name with which a plugin is registered is returned.

=head2 registered_function

  my $action = $hook->registered_function('method.name');
  my ( $plugin, $function ) = @{ $action }{qw( plugin function )};

This method returns plugin and callback registered with a method.

Return value is a hash reference including plugin and callback.
When nothing is registered, no this methods are returned.

=head2 delete_hook

  $hook->delete_hook( 'hook.name' );
  $hook->delete_hook( 'hook.name' => ( $pluginA, 'ClassName' ) );

This method deletes a registered hook.

Hook name is specified as the first argument,
and plugin object or class name is specified as an argument after that.

When specifying only a hook as an argument,
all plugin registered with the hook are deleted.

And when specifying a hook and plugin object (or class name) as arguments,
specified plugins are deleted from specified hooks.

=head2 delete_callback

  $hook->delete_callback( $plugin->can('callback') );
  $hook->delete_callback( \&callback => qw( hook.A hook.B ) );

This method deletes a registered callback.

Callback (CODE reference) is specified as the first argument,
and some hook names are specified after that.

When specifying only a callback as an argument,
all callbacks registered with the hook are deleted.

And When specifying callback and hook names as arguments,
specified callbacks are deleted from specified hooks.

=head2 delete_method

  $hook->delete_method('method.name');

This method deleted a registered hookable method.
The method name is specified as an argument.

=head2 delete_function

  $hook->delete_function( $plugin->can('function') );:
  $hook->delete_function( \&function => qw( method.A method.B ) );

This method deletes a registered function.

Function (CODE reference) is specified as the first argument.
and some method names are specified after that.

When specifying only a function as an argument,
all functions registered with the method are deleted.

And when specifying function and method names as arguments,
specified functions are deleted from specified methods. 

=head2 delete_plugin

  $hook->delete_plugin( $plugin );
  $hook->delete_plugin( ClassName => qw( hook.A method.A ) );

This method deletes a registered plugin.

A plugin object or class name is specified as the first argument,
and hook names or method names are specified as an argument after that.

When specifying only a plugin object (or class name) as an argument,
a plugin is deleted from all hooks and all methods.

And when specifying a plugin object (or class name) and hook names or method names as arguments,
a plugin is deleted from specified hooks and specified methods.

=head1 ACCESSOR METOHDS

=head2 hookable_stash

  my $data = $hook->hookable_stash;

This method is stash in Class::Hookable.
All variables Class::Hookable needs are put here.

This method does not get arguments,
and return hash reference includes all variables.

=head2 hookable_context

  # set
  $hook->hookable_context( $context );
  # get
  my $context = $hook->hookable_context;

This method is accessor of context object.

blessed object or class name is specified as the context object.

Context object specified by this method is passed as the second argument of
the subroutine registered with hook and method.

see also L<"run_hook">.

=head2 hookable_all_hooks

  my $hooks = $hook->hookable_all_hooks;

This method is accessor to hash reference which keeps hooks.
all method of Class::Hookable is accessing hooks through this method.

=head2 hookable_all_methods

  my $methods = $hook->hookable_all_methods;

This method is accesor to hash reference which keeps methods.
all method of Class::Hookable is accessing methods through this method.

=head1 AUTHOR

Original idea by Tatsuhiko Miyagawa L<http://search.cpan.org/~miyagawa> in L<Plagger>

Code by Naoki Okamura (Nyarla) E<lt>thotep@nayrla.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
