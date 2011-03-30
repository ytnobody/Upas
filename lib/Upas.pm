package Upas;
use strict;
use warnings;
our $VERSION = '0.01';

use parent qw/ Memcached::Server /;
use SUPER;
use AnyEvent;
use Storable qw/ freeze thaw /;

our $DATA = {};

sub new {
    my $class = shift;
    my $cmd = {};
    $cmd->{ $_ } = \&{ $_ } for qw/ get set delete flush_all /;
    my $self = $class->SUPER::new( no_extra => 1, cmd => $cmd, @_ );
    return $self;
}

sub run { AE::cv->recv() };

sub set {
    my ( $cb, $area, $flag, $expire, $data ) = @_;
    $expire = $expire ? $expire : 300;
    if ( defined $area ) {
        $DATA->{ $area } ||= [];
        unshift @{ $DATA->{ $area } }, [ $flag, $expire, time, $data ];
    }
    $cb->(1);
}

sub get {
    my ( $cb, $key ) = @_;
    return $cb->( 0 ) unless defined $key;
    my ( $area, %keyvals ) = split /:/, $key;
    return $cb->( 0 ) unless defined $DATA->{ $area };
    _expire( $area );
    my @rtn;
    if ( %keyvals ) {
        for my $k ( keys %keyvals ) {
            push @rtn, grep { thaw( $_->[3] )->{ $k } eq $keyvals{ $k } } @{ $DATA->{ $area } };
        }
    }
    else {
        @rtn = @{ $DATA->{ $area } };
    }
    return $cb->( 0 ) unless @rtn;
    $cb->( 1, freeze( [ map { thaw( $_->[3] ) } @rtn ] ) );
}

sub delete {
    my ( $cb, $key ) = @_;
    $cb->( 0 ) unless defined $key;
    my ( $area, %keyvals ) = split /:/, $key;
    if ( %keyvals ) {
        for my $data ( @{ $DATA->{ $area } } ) {
            for my $k ( keys %keyvals ) {
                $data->[1] = 0 if thaw( $data->[3] )->{ $k } eq $keyvals{ $k };
            }
        }
    }
    else {
        delete $DATA->{ $area };
    }
    $cb->( 1 );
}


sub _expire {
    my $area = shift;
    my $time = time;
    my @tmpdata = ();
    map { $time <= $_->[1] + $_->[2] ? push @tmpdata, $_ : undef } @{ $DATA->{ $area } };
    $DATA->{ $area } = \@tmpdata;
}

1;
__END__

=head1 NAME

Upas - Memory-array based memcache-daemon

=head1 INSTALL

  $ git clone git://github.com/ytnobody/Upas.git
  $ cpanm ./Upas

=head1 SYNOPSIS

  ### in your shell
  $ upas
  
  ### your application
  use Cache::Memcached::Fast;
  use Storable qw/ freeze thaw /;
  
  my $m = Cache::Memcached::Fast->new( { 
      servers => [ qw/ 127.0.0.1:4616 / ], 
      ... 
  } );
  
  # enter some members into upas
  my @members = (
      { id => 1, name => 'ytnobody', age => 30, sex => 'male' },
      { id => 2, name => 'Wife', age => 30, sex => 'female' },
      { id => 3, name => 'Eldest son', age => 9, sex => 'male' },
      { id => 4, name => 'Second son', age => 5, sex => 'male' },
  );
  $m->set( 'myhome', freeze $_, 3600*24 ) for @members;
  
  # get list of members in "myhome"
  my $res = $m->get( 'myhome' );
  my $myhome = $res ? thaw( $res ) : undef;
  die "Couldn't get list of members in \"myhome\"" unless $myhome;
  
  # move ytnobody to company
  $res = $m->get( 'myhome:id:1' );                 # got data of ytnobody!
  my $ytnobody = thaw $res;
  $m->delete( 'myhome:id:1' );                     # removed ytnobody from "myhome"...
  $m->set( 'company', freeze $ytnobody, 3600*12 ); # Work!

=head1 USAGE OF upas

  $ upas [-b bind_address (default=0.0.0.0)] [-p port(default=4616)]

=head1 AUTHOR

satoshi azuma E<lt>ytnobody@gmail.comE<gt>

=head1 TODO

- more test

- benchmark

- more document

- sharpens performance

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
