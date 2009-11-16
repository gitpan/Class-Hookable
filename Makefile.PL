use inc::Module::Install;

name 'Class-Hookable';
all_from 'lib/Class/Hookable.pm';

author 'Naoki Okamura (Nyarla) <nyarla[:)]thotep.net>';

requires 'Carp';
requires 'Scalar::Util';

build_requires 'Test::More'     => 0.74;
build_requires 'Test::Builder'  => 0.74;

tests 't/*.t t/*/*.t';

auto_include;
auto_install;

WriteAll;
