requires 'Memcached::Server';
requires 'AnyEvent';
requires 'JSON';

on test => sub {
    requires 'Test::More';
    requires 'Test::Deep';
    requires 'Test::Warn';
    requires 'Test::TCP';
    requires 'Cache::Memcached::Fast';
};
