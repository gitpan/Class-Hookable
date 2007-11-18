package Class::Hookable;

use strict;
use warnings;

use Carp ();
use Scalar::Util();

our $VERSION = '0.01';

sub new { bless {}, shift }

sub hooks {
    my ( $self ) =  @_;

    if ( ref $self->{'Class::Hookable'} ne 'HASH' ) {
        $self->{'Class::Hookable'} = {
            hooks => {},
        };
    }

    return $self->{'Class::Hookable'}->{'hooks'};
}

sub register_hook {
    my ( $self, $plugin, @hooks ) = @_;

    Carp::croak "Plugin object is not blessed object or class name"
        if ( ref $plugin && ! Scalar::Util::blessed($plugin) );

    while ( my ( $hook, $callback ) = splice @hooks, 0, 2 ) {
        my $action = {
            plugin      => $plugin,
            callback    => $callback,
        };

        if ( $self->filter_plugin( $hook, $action ) ) {
            $self->hooks->{$hook} = []
                if ( ref $self->hooks->{$hook} ne 'ARRAY' );

            push @{ $self->hooks->{$hook} }, $action;
        }
    }
}

sub filter_plugin { 1 }

sub registered_hooks {
    my ( $self, $object ) = @_;

    if ( ref $object && ! Scalar::Util::blessed( $object ) ) {
        Carp::croak "Argument is not blessed object or class name.";
    }

    my $is_class = ( ! ref $object ) ? 1 : 0 ;
    my @hooks = ();

    for my $hook ( keys %{ $self->hooks } ) {
        for my $action ( @{ $self->hooks->{$hook} } ) {
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

    return @hooks;
}

sub registered_plugins {
    my ( $self, $hook ) = @_;

    Carp::croak "Hook name is not specified." if ( ! defined $hook );

    my $list = $self->hooks->{$hook};
       $list ||= [];

    return @{ $list };
}

sub delete_plugin {
    my ( $self, $object, @hooks ) = @_;

    if ( ref $object && ! Scalar::Util::blessed($object) ) {
        Carp::croak "Argument is not blessed object or class name.";
    }

    my $is_class = ( ! ref $object ) ? 1  : 0 ;
    @hooks = keys %{ $self->hooks } if ( @hooks == 0 );

    for my $hook ( $self->registered_hooks( $object ) ) {
        next if ( ! grep { $hook eq $_ } @hooks );

        my @actions = ();
        for my $action ( $self->registered_plugins( $hook ) ) {
            my $plugin  = $action->{'plugin'};
            my $class   = ref $plugin || $plugin;
            if ( $is_class ) {
                push @actions, $action if ( $class ne $object );
            }
            else {
                push @actions, $action if ( $plugin ne $object );
            }
        }

        $self->hooks->{$hook} = \@actions;
    }

}

sub delete_hook {
    my ( $self, $hook, @plugins ) = @_;

    Carp::croak "Hook is not specified." if ( ! defined $hook );

    if ( @plugins == 0 ) {
        $self->hooks->{$hook} = [];
    }
    else {
        for my $plugin ( @plugins ) {
            $self->delete_plugin( $plugin, $hook );
        }
    }
}

sub run_hook {
    my ( $self, $hook, $args, $once, $callback ) = @_;

    if ( defined $callback && ref $callback ne 'CODE' ) {
        Carp::croak "callabck is not code reference.";
    }
    

    my @results;

    my $context = ( defined $self->context ) ? $self->context : $self ;

    for my $action ( $self->registered_plugins( $hook ) ) {
        if ( $self->dispatch_plugin( $hook, $args, $action ) ) {
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

sub dispatch_plugin { 1 }

sub context {
    my $self = shift;

    if ( ref $self->{'Class::Hookable'} ne 'HASH' ) {
        $self->{'Class::Hookable'} = {
            hooks => {},
        };
    }

    if ( @_ ) {
        my $context = shift;
        $self->{'Class::Hookable'}->{'context'} = $context;
    }
    else {
        return $self->{'Class::Hookable'}->{'context'};
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

Class::Hookable is the simple base class for the hook mechanism.
This module supports only a hook mechanism.

This module was made by making reference to the hook mechanism of L<Plagger>.
I thank L<Tatsuhiko miyagawa|http://search.cpan.org/~miyagawa/> who made wonderful application.

=head1 METHODS

=head2 new

  my $hook = Class::Hookalbe->new;

This method is a constructor of Class::Hookable.
Nothing but that is being done.

=head2 register_hook

  $hook->register_hook(
      $plugin,
      'hook.A' => $plugin->can('callbackA'),
      'hook.B' => $plugin->can('callbackB'),
  );

This method registers a plugin object and callbacks which corresponds to hooks.

The plugin object is specified as the first argument,
and one after that is specified by the order of C<'hook' =E<gt> \&callabck>.

=head2 filter_plugin

  sub filter_plugin {
      my ( $self, $hook, $action ) = @_;
      my ( $plugin, $callback ) = @{ $action }{qw( plugin callback )};
      # your filter code
  }

When registering a plugin, this method is filtered a plugin.
Arguments are passed by the order of C<$hook> and C<$action>.

=over 2

=item C<$hook>

The hook name specified as the run_hook method.

=item C<$action>

The hash reference including plugin and callback.

=back

When this method has returned ture, plugin and hook are registered,
and when having returned false, it isn't registered.

This method exists to rewrite when inheriting.

=head2 registered_hooks

  my @hooks = $hook->registered_hooks( $plugin );
  my @hooks = $hook->registered_hooks( 'ClassName' );

This method returns hooks with which a plugin is registered.
An argument is plugin object or class name.

=head2 registered_plugins

  for my $action ( $hook->registered_plugins('hook.name') ) {
      my ( $plugin, $callback ) = @{ $action }{qw( plugin callback )};
      # some code
  }

This method returns plugin and callback registered with a hook.
Return value is a list of hash reference including plugin and callback.

=head2 delete_plugin

  $hook->delete_plugin( $plugin );
  $hook->delete_plugin( 'ClassName', 'hook.A', 'hook.B' );

This method delete a registered plugin.

When specifying only a plugin object (or class name) as an argument,
a plugin is deleted from all hooks.

And when specifying a plugin object (or class name) and hooks as arguments,
a plugin is deleted from specified hooks.

=head2 delete_hook

  $hook->delete_hook( 'hook.name' );
  $hook->delete_hook( 'hook.name', $pluginA, 'ClassName' );

This method delete a registered hook.

When specifying only a hook as an argument,
all plugin registered with the hook are deleted.

And when specifying a hook and plugin object (or class name) as arguments,
specified plugins are deleted from a specified hook.

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

B<Argument to callback of the registered plugin>:

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

When C<$hook-E<gt>context> is specified, the specified object is passed,
and when it isn't so, C<$hook>(Class::Hookable) object is passed.

see also L<"context"> method.

=item C<$args>

C<$args> specified by the run_hook method.

=back

=head2 run_hook_once

  my $result = $hook->run_hook_once( $hook, $args, $callback );

This method is an alias of C<$hook-E<gt>run_hook( $hook, $args, 1, \&callback )>.

=head2 dispatch_plugin

  sub dispatch_plugin {
      my ( $self, $hook, $args, $action ) = @_;
      my ( $plugin, $callabck ) = @{ $action }{qw( plugin callback )};
      # some code
  }

When calling a hook, this method does a dispatch of a plugin.
Argument are passed by the order of C<$hook>, C<$args>, C<$action>.

=over 3

=item C<$hook>

The hook name specified by the run_hook method.

=item C<$args>

The argument specified by the run_hook method.

=item C<$action>

The hash reference including the plugin and the callback.

=back

When this method has returned true, callback of a plugin is called, 
and when having returned false, callback isn't called.

This method exists to rewrite when inheriting.

=head2 context

  my $context = $hook->context;
  $hook->context( $context );

This method is accessor of context object.

When specifying object by this method,
it's passed to callback of the plugin as context object.

see also L<"run_hook"> method.

=head2 hooks

  my $hooks = $hook->hooks;

This method is accessor to hash reference which keeps hooks.
all method of Class::Hookable is accessing hooks through this method.

=head1 AUTHOR

Naoki Okamura (Nyarla) E<lt>thotep@nayrla.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
