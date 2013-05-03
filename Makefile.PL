use inc::Module::Install;

name     'PDF-TableX';
all_from 'lib/PDF/TableX.pm';
author   'Grzegorz Papkala <grzegorzpapkala@gmail.com>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

