# NAME

Upas - Memory-array based memcache-daemon

# SYNOPSIS

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

# Usage about upas daemon

    $ upas [-b bind_address (default=0.0.0.0)] [-p port(default=4616)]

# AUTHOR

satoshi azuma <ytnobody@gmail.com>

# TODO

\- more test

\- benchmark

\- more document

\- sharpens performance

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
