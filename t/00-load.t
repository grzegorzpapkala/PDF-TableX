#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'PDF::TableX' );
}

diag( "Testing PDF::TableX $PDF::TableX::VERSION, Perl $], $^X" );
