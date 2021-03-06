use Test::More;
use Test::Deep;
use Test::TCP;
use Cache::Memcached::Fast;
use JSON;
use Upas;

my $now = time();

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $upas = Upas->new( open => [[ '127.0.0.1', $port ]] );
        $upas->run;
    },
);

my $memd = Cache::Memcached::Fast->new( {
    servers => [ '127.0.0.1:'.$server->port ],
    namespace => 'upas_test',
} );

$memd->set( 'test', encode_json({ id => 1 }), 5 );
for ( 0 .. 10 ) {
    my $val = $memd->get( 'test:id:1' );
    if ( $_ <= 4 ) {
        ok defined $val, "expire 5 sec., elapsed $_ sec.";
        my $data;
        eval { $data = decode_json( $val ) };
        is $@, '', "Error when decode_json: $@";
        cmp_deeply( $data, [ { id => 1 } ] );
    }
    else {
        is $val, undef;
    }
    sleep 1;
}

$memd->delete( 'test' );

ok $memd->set( 'test', encode_json( { id => 1 } ), 3 );
ok $memd->set( 'test', encode_json( { id => 2 } ), 4 );
ok $memd->set( 'test', encode_json( { id => 3 } ), 5 );
ok $memd->set( 'test', encode_json( { id => 4 } ), 6 );

my @expect = (
    [ { id => 4 }, { id => 3 }, { id => 2 }, { id => 1 } ],
    [ { id => 4 }, { id => 3 }, { id => 2 }, { id => 1 } ],
    [ { id => 4 }, { id => 3 }, { id => 2 }, { id => 1 } ],
    [ { id => 4 }, { id => 3 }, { id => 2 } ],
    [ { id => 4 }, { id => 3 } ],
    [ { id => 4 } ],
    undef,
    undef,
);

for ( 0 .. 7 ) {
    my $exp = $expect[$_];
    my $val = $memd->get( 'test' );
    if ( defined $exp ) {
        ok defined $val, "elapsed $_ sec.";
        my $data;
        eval { $data = decode_json( $val ) };
        is $@, '', "Error when decode_json: $@";
        cmp_deeply( $data, $exp );
    }
    else {
        is $val, undef;
    }
    sleep 1;
}

done_testing();
