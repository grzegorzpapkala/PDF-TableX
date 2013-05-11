package PDF::TableX::Row;

use Moose;
use MooseX::Types;

with 'PDF::TableX::Drawable';

use PDF::TableX::Types qw/StyleDefinition/;
use PDF::TableX::Cell;

our $ATTRIBUTES = [ qw/padding border_width border_color border_style background_color height/ ];

has cols	  => (is => 'ro', isa => 'Int', default => 0);
has width   => (is => 'rw', isa => 'Num');
has height  => (is => 'rw', isa => 'Num');
has padding => (is => 'rw', isa => StyleDefinition, coerce => 1, default => sub{[1,1,1,1]} );
has border_width => (is => 'rw', isa => StyleDefinition, coerce => 1, default => sub{[1,1,1,1]} );
has border_color => (is => 'rw', isa => StyleDefinition, coerce => 1, default => 'black' );
has border_style => (is => 'rw', isa => StyleDefinition, coerce => 1, default => 'solid' );
has background_color => (is => 'rw', isa => 'Str', default => '' );

has _row_idx    => (is => 'ro', isa => 'Int', default => 0);
has _parent		  => (is => 'ro', isa => 'Object');
has _cells	    => (is => 'ro', init_arg => undef, isa => 'ArrayRef', default => sub{[]});
has _attributes => (is => 'ro', init_arg => undef, isa => 'ArrayRef', default => sub{
	$ATTRIBUTES;
});

use overload '@{}' => sub { return $_[0]->{_cells} }, fallback => 1;

# method modifiers
for my $func ( @{ $ATTRIBUTES } ) {
	around $func => sub {
		my ($orig, $self, $value) = @_;
		if ( $value ) {
			$self->$orig($value);
			for (@{$self->{_cells}}) {
				$_->$func( $value );
			}
			return $self;
		} else {
			return $self->$orig;
		}		
	};
}

sub BUILD {
	my ($self) = @_;
	$self->_create_cells;
}

sub _create_cells {
	my ($self) = @_;
	for (0..$self->cols-1) {
		$self->add_cell( PDF::TableX::Cell->new(
			width => ($self->width/$self->cols),
			_row_idx => $self->{_row_idx},
			_col_idx => $_,
			_parent  => $self,
			$self->properties,
		));
	}
}

sub add_cell {
	my ($self, $cell) = @_;
	push @{$self->{_cells}}, $cell;
}

sub properties {
	my ($self, @attrs) = @_;
	@attrs = ( scalar(@attrs) ) ? @attrs : qw/padding border_width border_color border_style/;
	return ( map { $_ => $self->$_ } @attrs );
}

sub draw_content    {
	my ($self, $x, $y, $gfx, $txt) = @_;
	my $height = 0;
	for (@{$self->{_cells}}) {
		my ($w, $h) = $_->draw_content( $x, $y, $gfx, $txt );
		$height = ($height > $h) ? $height : $h;
		$x += ($w > $_->width ? $w : $_->width);
	}
	return $height;
}

sub draw_borders    {
	my ($self, $x, $y, $gfx, $txt) = @_;
	for (@{$self->{_cells}}) {
		$_->draw_borders( $x, $y, $gfx, $txt );
		$x += $_->width;
	}
}

sub draw_background {
	my ($self, $x, $y, $gfx, $txt) = @_;
	for (@{$self->{_cells}}) {
		$_->draw_background( $x, $y, $gfx, $txt );
		$x += $_->width;
	}
}

sub is_last_in_row {
	my ($self, $idx) = @_;
	return ($idx == $self->cols-1); #index starts from 0
}

sub is_last_in_col {
	my ($self, $idx) = @_;
	return $self->{_parent}->is_last_in_col($idx);
}

1;

=head1 NAME
PDF::TableX::Row

=head1 VERSION
Version 0.01
=cut

=head1 SYNOPSIS
The module provides capabilities to create tabular structures in PDF files.
It is similar to PDF::Table module, however extends its functionality adding OO interface
and allowing placement of any element inside table cell such as image, another pdf, or nested table.

=head1 FUNCTIONS

=head2 BUILD
=cut

=head2 add_cell
=cut

=head1 AUTHOR
Grzegorz Papkala, C<< <grzegorzpapkala at gmail.com> >>

=head1 BUGS
Please report any bugs or feature requests to C<bug-pdf-tablex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PDF-TableX>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT
You can find documentation for this module with the perldoc command.
    perldoc PDF::TableX::Row

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