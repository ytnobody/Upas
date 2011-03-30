use inc::Module::Install;
name 'Upas';
all_from 'lib/Upas.pm';

requires 'Memcached::Server';
requires 'SUPER';
requires 'AnyEvent';
requires 'Storable';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Deep';
test_requires 'Test::Warn';
test_requires 'Test::TCP';
test_requires 'Cache::Memcached::Fast';

install_script 'bin/upas';

auto_set_repository;
auto_include;
WriteAll;
