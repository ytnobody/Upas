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
test_requires 'AnyEvent::Memcached';

install_script 'bin/upas';

auto_set_repository;
auto_include;
WriteAll;
