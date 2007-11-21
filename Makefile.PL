use inc::Module::Install;

name 'Class-Hookable';
all_from 'lib/Class/Hookable.pm';

requires 'Carp';
requires 'Scalar::Util';

build_requires 'Test::More' ;

tests 't/*.t t/*/*.t';

auto_include;
auto_install;

WriteAll;
