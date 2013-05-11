#!perl -T

use Test::More tests => 2;

use PDF::TableX;
use PDF::API2;

my $table = PDF::TableX->new(5,10);
my $pdf		= PDF::API2->new();
$pdf->mediabox('a4');

$table
	->padding(20)
	->cycle_background_color('#333333','#cccccc', '#999999');

is($table->[0]->background_color(), '#333333');
is($table->[3]->background_color(), '#333333');

$table->[2][2]
	->border_width(10)
	->background_color('red');

$table->draw($pdf, 1);
$pdf->saveas('t/03-cycled-styles.pdf');

diag( "Testing PDF::TableX $PDF::TableX::VERSION, Perl $], $^X" );