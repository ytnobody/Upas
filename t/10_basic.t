use Test::More;
use Test::Deep;
use AnyEvent;
use AnyEvent::Memcached;
use Storable qw/ freeze thaw /;
use Upas;

eval { Upas->new( open => [[ 0, 4616 ]] ) };
plan skip_all => "Couldn't bind address 0.0.0.0:4616. Because $@" if $@;
plan 'no_plan'; 

my $cv = AE::cv;

my $memd = AnyEvent::Memcached->new(
    servers => [ qw/ 127.0.0.1:4616 / ],
    namespace => 'upas_test',
    cv => $cv,
);

for my $i ( 0 .. 9 ) {
    $memd->set( 
        test => freeze( { id => $i } ), 
        cb => sub {
            my $r = shift;
            ok $r, "Set failed: @_";
        } 
    );
}

$memd->get( 'test', cb => sub {
    my ( $val, $err ) = shift;
    is $err, undef, "Get failed: @_";
    my $data = thaw( $val );
    cmp_deeply( $data, [ map { { id => $_ } } reverse( 0 .. 9 ) ] );
} );

$memd->get( 'test:id:4', cb => sub {
    my ( $val, $err ) = shift;
    is $err, undef, "Get failed: @_";
    my $data = thaw( $val );
    cmp_deeply( $data, [ { id => 4 } ] );
} );

$memd->get( 'test:id:3', cb => sub {
    my ( $val, $err ) = shift;
    is $err, undef, "Get failed: @_";
    my $data = thaw( $val );
    cmp_deeply( $data, [ { id => 3 } ] );
} );

$memd->delete( 'test:id:3', cb => sub {
    my ( $val, $err ) = shift;
    is $err, undef, "Delete failed: @_";
} );

$memd->get( 'test:id:3', cb => sub {
    my ( $val, $err ) = shift;
    is $err, undef, "Get failed: @_";
    is $val, undef;
} );

$cv->recv;
