package PDF::TableX::Cell;

use Moose;
use MooseX::Types;
use PDF::API2;

use PDF::TableX::Types qw/StyleDefinition/;
with 'PDF::TableX::Drawable';

our $ATTRIBUTES = [ qw/padding border_width border_color border_style background_color content font_color font_size text_align/ ];

has width     => (is => 'rw', isa => 'Num');
has min_width => (is => 'rw', isa => 'Num', lazy => 1, builder => '_get_min_width');
has reg_width => (is => 'rw', isa => 'Num', lazy => 1, builder => '_get_reg_width');
has height  => (is => 'rw', isa => 'Num', lazy => 1, builder => '_get_height' );
has content => (is => 'rw', isa => 'Str', default=> '');
has padding => (is => 'rw', isa => StyleDefinition, coerce => 1, default => sub{[1,1,1,1]} );
has border_width => (is => 'rw', isa => StyleDefinition, coerce => 1, default => sub{[1,1,1,1]} );
has border_color => (is => 'rw', isa => StyleDefinition, coerce => 1, default => 'black' );
has border_style => (is => 'rw', isa => StyleDefinition, coerce => 1, default => 'solid' );
has font				 => (is => 'rw', isa => 'Any', default => 'Times');
has font_color   => (is => 'rw', isa => 'Str', default => 'black');
has font_size    => (is => 'rw', isa => 'Num', default => 12);
has text_align	 => (is => 'rw', isa => 'Str', default => 'left');
has background_color => (is => 'rw', isa => 'Str', default => '' );

has _pdf_api_content => (is => 'ro', isa => class_type('PDF::API2::Page'), lazy => 1, builder => '_get_content');
has _parent	 => (is => 'ro', isa => 'Object');
has _row_idx => (is => 'ro', isa => 'Int', default => 0);
has _col_idx => (is => 'ro', isa => 'Int', default => 0);

# method modifiers
for my $func ( @{ $ATTRIBUTES } ) {
	around $func => sub {
		my ($orig, $self, $value) = @_;
		if ( $value ) {
			$self->$orig($value);
			return $self;
		} else {
			return $self->$orig;
		}		
	};
}

sub _get_content { return PDF::API2->new()->page; }

sub _get_min_width {
	my ($self) = @_;
	my $txt = $self->_pdf_api_content->text();
	$txt->font( PDF::API2->new()->corefont( $self->font ), $self->font_size );
	my $min_width = 0;
	for (split(/\s/, $self->content)) {
		my $word_width = $txt->advancewidth($_);
		$min_width = ($word_width > $min_width) ? $word_width : $min_width;
	}
	return $min_width + $self->padding->[1] + $self->padding->[3];
}

sub _get_reg_width {
	my ($self) = @_;
	my $txt = $self->_pdf_api_content->text();
	$txt->font( PDF::API2->new()->corefont( $self->font ), $self->font_size );
	my $reg_width = 0;
	for (split("\n", $self->content)) {
		my $line_width = $txt->advancewidth($_);
		$reg_width = ($line_width > $reg_width) ? $line_width : $reg_width;
	}
	return $reg_width + $self->padding->[1] + $self->padding->[3];
}

sub _get_height {
	my ($self) = @_;
	my $height = $self->padding->[0] + $self->padding->[2];
	$height   += scalar(split("\n", $self->content)) * $self->font_size;
	return $height;
}

sub draw_content {
	my ($self, $x, $y, $gfx, $txt) = @_;
	$y -= $self->padding->[0] + $self->font_size;
	$x += $self->padding->[3];
	my $width = 0;
	$txt->save;
	$txt->font( PDF::API2->new()->corefont( $self->font ), $self->font_size );
	$txt->lead( $self->font_size );
	$txt->fillcolor( $self->font_color );
	$txt->translate($x, $y);
	for my $p ( split ( "\n", $self->content ) ) {
		$txt->paragraph($p, $self->get_text_width, 10000, -spillover => 0);
	}
	$self->height( $y - [ $txt->textpos() ]->[1] + $self->padding->[0] + $self->padding->[2]);
	$txt->restore;
	return ($self->get_text_width, $self->height);
}

sub get_text_width {
	my ($self) = @_;
	return $self->width - $self->padding->[1] - $self->padding->[3];
}

sub draw_borders {
	my ($self, $x, $y, $gfx, $txt) = @_;
	if ($self->border_width->[0]) {$self->_draw_top_border($x, $y, $gfx)}
	if ($self->border_width->[1]) {$self->_draw_right_border($x, $y, $gfx)}
	if ($self->border_width->[2]) {$self->_draw_bottom_border($x, $y, $gfx)}
	if ($self->border_width->[3]) {$self->_draw_left_border($x, $y, $gfx)}
}

sub _draw_top_border {
	my ($self, $x, $y, $gfx) = @_;
	$y = ($self->{_row_idx} == 0) ? $y-$self->border_width->[0]/2 : $y;
	$gfx->move($x, $y);
	$gfx->linewidth($self->border_width->[0]);
	$gfx->strokecolor($self->border_color->[0]);
	$gfx->hline($x+$self->width);
	$gfx->stroke();
}

sub _draw_right_border {
	my ($self, $x, $y, $gfx) = @_;
	$x = ($self->{_parent}->is_last_in_row($self->{_col_idx})) ? $x-$self->border_width->[1]/2 : $x;
	$gfx->move($x+$self->width, $y);
	$gfx->linewidth($self->border_width->[1]);
	$gfx->strokecolor($self->border_color->[1]);
	$gfx->vline($y-$self->height);
	$gfx->stroke();
}

sub _draw_bottom_border {
	my ($self, $x, $y, $gfx) = @_;
	$y = ($self->{_parent}->is_last_in_col($self->{_row_idx})) ? $y+$self->border_width->[2]/2 : $y;
	$gfx->move($x, $y-$self->height);
	$gfx->linewidth($self->border_width->[2]);
	$gfx->strokecolor($self->border_color->[2]);
	$gfx->hline($x+$self->width);
	$gfx->stroke();
}

sub _draw_left_border {
	my ($self, $x, $y, $gfx) = @_;
	$x = ($self->{_col_idx} == 0) ? $x+$self->border_width->[3]/2 : $x;
	$gfx->move($x, $y);
	$gfx->linewidth($self->border_width->[3]);
	$gfx->strokecolor($self->border_color->[3]);
	$gfx->vline($y-$self->height);
	$gfx->stroke();
}

sub draw_background {
	my ($self, $x, $y, $gfx, $txt) = @_;
	if ( $self->background_color ) {
		$gfx->linewidth(0);
		$gfx->fillcolor($self->background_color);
		$gfx->rect($x, $y-$self->height, $self->width, $self->height);
		$gfx->fill();
	}	
}

1;

=head1 NAME
PDF::TableX::Cell

=head1 VERSION
Version 0.01
=cut

=head1 SYNOPSIS
The module provides capabilities to create tabular structures in PDF files.
It is similar to PDF::Table module, however extends its functionality adding OO interface
and allowing placement of any element inside table cell such as image, another pdf, or nested table.

=head1 FUNCTIONS

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