use inc::Module::Install;
name 'Upas';
all_from 'lib/Upas.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
