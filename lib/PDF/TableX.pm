package PDF::TableX;

use Moose;
use MooseX::Types;
use MooseX::Types::Moose qw/Int/;

use Carp;
use PDF::API2;

use PDF::TableX::Types qw/StyleDefinition/;
use PDF::TableX::Row;
use PDF::TableX::Column;
use PDF::TableX::Cell;

our $ATTRIBUTES = [ qw/padding border_width border_color border_style background_color/ ];
our $VERSION    = '0.01';

# public attrs
has width   => (is => 'rw', isa => 'Num', default => 0);
has start_x => (is => 'rw', isa => 'Num', default => 0);
has start_y => (is => 'rw', isa => 'Num', default => 0);
has rows	  => (is => 'ro', isa => 'Int', default => 0);
has cols	  => (is => 'ro', isa => 'Int', default => 0);
has padding => (is => 'rw', isa => StyleDefinition, coerce => 1, default => sub{[1,1,1,1]} );
has border_width => (is => 'rw', isa => StyleDefinition, coerce => 1, default => sub{[1,1,1,1]} );
has border_color => (is => 'rw', isa => StyleDefinition, coerce => 1, default => 'black' );
has border_style => (is => 'rw', isa => StyleDefinition, coerce => 1, default => 'solid' );
has background_color => (is => 'rw', isa => 'Str', default => '' );

# private attrs
has _rows => (is => 'ro', init_arg => undef, isa => 'ArrayRef[ Object ]', default => sub {[]});
has _cols => (is => 'ro', init_arg => undef, isa => 'ArrayRef[ Object ]', default => sub {[]});
has _attributes => (is => 'ro', init_arg => undef, isa => 'ArrayRef', default => sub{
	$ATTRIBUTES;
});

# method modifiers
for my $func ( @{ $ATTRIBUTES } ) {
	around $func => sub {
		my ($orig, $self, $value) = @_;
		if ( $value ) {
			$self->$orig($value);
			for (@{$self->{_rows}}) {
				$_->$func( $value );
			}
			return $self;
		} else {
			return $self->$orig;
		}		
	};
}

use overload '@{}' => sub { return $_[0]->{_rows}; }, fallback => 1;

# overridden methods
override BUILDARGS => sub {
	my $class = shift;
	
	if (@_ == 2 and Int->check($_[0]) and Int->check($_[1])) {
		return { 
			cols    => $_[0],
			rows    => $_[1],
			width   => 190 / 25.4 *72,
			start_x => 10 / 25.4 *72,
			start_y => 287 / 25.4 *72,
		};
	}
	
	return super;
};

sub BUILD {
	my ($self) = @_;
	$self->_create_initial_struct;
};

sub _create_initial_struct {
	my ($self) = @_;
	if ( my $rows =  $self->rows ) {
		$self->{rows} = 0;
		for (0..$rows-1) {
			$self->add_row( PDF::TableX::Row->new(
				cols     => $self->cols,
				width    => $self->width,
				_row_idx => $_,
				_parent  => $self,
				$self->properties,
				)
			);
		}	
	}
}

sub properties {
	my ($self, @attrs) = @_;
	@attrs = ( scalar(@attrs) ) ? @attrs : @{ $self->{_attributes} };
	return (map { $_ => $self->$_ } @attrs);
}

sub add_row {
	my ($self, $row) = @_;
	$self->{rows}++;
	push @{$self->{_rows}}, $row;
}

sub col {
	my ($self, $i) = @_;
	return $self->{_cols}->[$i] if (defined $self->{_cols}->[$i]);
	my $col = PDF::TableX::Column->new();
	for ( @{$self} ) {
		$col->add_cell( $_->[$i] );
	}
	$self->{_cols}->[$i] = $col;
	return $col;
}

sub draw {
	my ($self, $pdf, $page_no) = @_;
	my $page = $pdf->openpage($page_no) || $pdf->page;
	$self->_set_col_widths();
	# get gfx, txt page objects in proper order to prevent from background hiding the text
	my ($bg_gfx, $bg_txt, $ct_gfx, $ct_txt, $bd_gfx, $bd_txt) = ($page->gfx, $page->text, $page->gfx, $page->text, $page->gfx, $page->text);
	for (@{$self->{_rows}}) {
		$_->height( $_->draw_content($self->start_x, $self->start_y, $ct_gfx, $ct_txt) );
		$_->draw_background($self->start_x, $self->start_y, $bg_gfx, $bg_txt);
		$_->draw_borders($self->start_x, $self->start_y, $bd_gfx, $bd_txt);
		$self->{start_y} -= $_->height;
	}
}

sub _set_col_widths {
	my ($self) = @_;
	my @min_col_widths = ();
	my @reg_col_widths = ();
	my @width_ratio    = ();
	
	for my $col (map {$self->col($_)} (0..$self->cols-1)) {
		push @min_col_widths, $col->get_min_width();
		push @reg_col_widths, $col->get_reg_width();
		push @width_ratio, ( $reg_col_widths[-1] / $min_col_widths[-1] );
	}

	my ($min_width, $free_space, $ratios) = (0,0,0);
	$min_width += $_ for @min_col_widths;
	$free_space = $self->width - $min_width;
	$ratios    += $_ for @width_ratio;

	return if ($free_space == 0);
	if ( $free_space ) {
		for (0..$self->cols-1) {
			$self->col($_)->width(($free_space/$ratios)*$width_ratio[$_] + $min_col_widths[$_]);
		}
	} else {
		carp "Error: unable to resolve column widht, content requires more space than the table has.\n";
	}
}

sub is_last_in_row {
	my ($self, $idx) = @_;
	return ($idx == $self->cols-1); #index starts from 0
}

sub is_last_in_col {
	my ($self, $idx) = @_;
	return ($idx == $self->rows-1); #index starts from 0
}

sub cycle_background_color {
	my ($self, @colors) = @_;
	
	my $length = (scalar @colors);
	for (0..$self->rows-1) {
		$self->[$_]->background_color( $colors[ $_ % $length ] );
	}
	
	return $self;
}

1;

=head1 NAME
PDF::TableX - Moose driven table generation module that is based on famous PDF::API2

=head1 VERSION
Version 0.01
=cut

=head1 SYNOPSIS
The module provides capabilities to create tabular structures in PDF files.
It is similar to PDF::Table module, however extends its functionality adding OO interface
and allowing placement of any element inside table cell such as image, another pdf, or nested table.

Sample usage:

		use PDF::API2;
    use PDF::TableX;

		my $pdf		= PDF::API2->new();
    my $table = PDF::TableX->new(40,40); 	# create 40 x 40 table
    $table->set_padding([3,3,3,3]);						# set padding for cells
    $table->set_border(1,'black');						# set border of table
    $table[0][0] = "Sample text";							# place "Sample text" in cell 0,0 (first cell in first row)
    $table[0][1] = PDF::TableX::Cell::Image->new('/paht/to/image.jpeg');
    $table->place( $pdf, 1 );									# place table in first page of pdf
    $pdf->save_as('some_file.pdf');


=head1 FUNCTIONS

=head2 set_padding
=cut

=head2 set_border
=cut

=head2 add_row
=cut

=head2 BUILD
=cut

=head1 AUTHOR

Grzegorz Papkala, C<< <grzegorzpapkala at gmail.com> >>

=head1 BUGS
Please report any bugs or feature requests to C<bug-pdf-tablex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PDF-TableX>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT
You can find documentation for this module with the perldoc command.
    perldoc PDF::TableX

You can also look for information at:
=over 4
=item * RT: CPAN's request tracker
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PDF-TableX>
=item * AnnoCPAN: Annotated CPAN documentation
L<http://annocpan.org/dist/PDF-TableX>
=item * CPAN Ratings
L<http://cpanratings.perl.org/d/PDF-TableX>
=item * Search CPAN
L<http://search.cpan.org/dist/PDF-TableX/>
=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE
Copyright 2013 Grzegorz Papkala, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut