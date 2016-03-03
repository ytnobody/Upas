package Upas;
use strict;
use warnings;
our $VERSION = '0.01';

use parent qw/ Memcached::Server /;
use AnyEvent;
use JSON ();

our %DATA = ();
our $EXPIRE_DEFAULT = 300;
our %COMMAND = (map {$_ => \&{$_}} qw/get set delete flush_all/);
our $SERIALIZER = JSON->new->canonical(1)->utf8(1);

sub new {
    my $class = shift;
    $class->SUPER::new(no_extra => 1, cmd => \%COMMAND, @_);
}

sub run { AE::cv->recv() };

sub set {
    my ($cb, $area, $flag, $expire, $data) = @_;
    $expire ||= $EXPIRE_DEFAULT;
    if (defined $area) {
        $DATA{$area} ||= [];
        unshift @{$DATA{$area}}, [$flag, $expire, time, $SERIALIZER->decode($data)];
    }
    return $cb->(1);
}

sub get {
    my ($cb, $key) = @_;
    my $req = _parse_key($key) or return $cb->(0);
    return $cb->(0) unless defined $DATA{$req->{area}};
    _expire($req->{area});
    my @rows = _search($req) or return $cb->(0);
    $cb->(1, $SERIALIZER->encode([map {$_->[3]} @rows]));
}

sub delete {
    my ($cb, $key) = @_;
    my $req = _parse_key($key) or return $cb->(0);
    my @rows = _search($req) or return $cb->(0);
    $_->[1] = 0 for @rows;
    $cb->(1);
}

sub _expire {
    my $area = shift;
    my $time = time;
    my @tmpdata = grep { $time < $_->[1] + $_->[2] } @{$DATA{$area}};
    $DATA{$area} = \@tmpdata;
}

sub _parse_key {
    my $key = shift;
    return unless defined $key;
    my ($area, %param) = split /:/, $key;
    return +{area => $area, param => {%param}};
}

sub _search {
    my $req = shift;
    my $area = $req->{area};
    my @param_keys = keys %{$req->{param}};
    my $key;
    return @param_keys ? 
        map {$key = $_; grep {$_->[3]{$key} eq $req->{param}{$key}} @{$DATA{$area}}} @param_keys :
        @{$DATA{$area}}
    ;
}

1;
__END__

=head1 NAME

Upas - Memory-array based memcache-daemon

=head1 SYNOPSIS

Start an upas daemon.

  $ upas


Then, use via memcached client.

  ### your application
  use Cache::Memcached::Fast;
  use JSON;
  
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
  $m->set(myhome => encode_json($_), 3600*24 ) for @members;
  
  # get list of members in "myhome"
  my $res = $m->get('myhome');
  my $myhome = $res ? decode_json($res) : undef;
  die "Couldn't get list of members in \"myhome\"" unless $myhome;
  
  # move ytnobody to company
  $res = $m->get('myhome:id:1');                 # got data of ytnobody!
  my $ytnobody = decode_json($res);
  $m->delete('myhome:id:1');                     # removed ytnobody from "myhome"...
  $m->set('company', encode_json($ytnobody), 3600*12); # Work!


=head1 Usage about upas daemon

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
