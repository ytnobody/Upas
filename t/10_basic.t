use Test::More;
use Test::Deep;
use Test::TCP;
use Cache::Memcached::Fast;
use Storable qw/ freeze thaw /;
use Upas;

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

ok $memd->set( 'test', freeze( { id => $_ } ) ), "Set $_ failed" for 0 .. 9;

my $data = get_data_with_test( 'test' );
cmp_deeply( $data, [ map { { id => $_ } } reverse( 0 .. 9 ) ] );

for ( 0 .. 9 ) {
    $data = get_data_with_test( "test:id:$_" );
    cmp_deeply( $data, [ { id => $_ } ] );
}

eval { $memd->delete( 'test:id:3' ) };
is $@, '', "Delete failed: $@";

is $memd->get( 'test:id:3' ), undef, 'unperfect deletion';

done_testing();

sub get_data_with_test {
    my $val = $memd->get( shift );
    ok defined $val;
    return unless defined $val;
    my $data;
    eval { $data = thaw( $val ) };
    is $@, '', "Error when thaw: $@";
    return $data;
}
