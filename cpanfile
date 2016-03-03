requires 'Memcached::Server';
requires 'SUPER';
requires 'AnyEvent';
requires 'Storable';

on test => sub {
    requires 'Test::More';
    requires 'Test::Deep';
    requires 'Test::Warn';
    requires 'Test::TCP';
    requires 'Cache::Memcached::Fast';
};
