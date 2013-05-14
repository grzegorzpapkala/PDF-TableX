package PDF::TableX::Column;

use Moose;
use MooseX::Types;

use PDF::TableX::Types qw/StyleDefinition/;
use PDF::TableX::Cell;

with 'PDF::TableX::Stylable';

has rows  => (is => 'ro', isa => 'Int', default => 0);
has width => (is => 'rw', isa => 'Num');

use overload '@{}' => sub { return $_[0]->{_children} }, fallback => 1;

around 'width' => sub {
	my $orig = shift;
	my $self = shift;
	return $self->$orig() unless @_;
	for (@{ $self->{_children} }) { $_->width(@_) };
	$self->$orig(@_);
	return $self;
};

sub add_cell {
	my ($self, $cell) = @_;
	push @{$self->{_children}}, $cell;
}

sub get_min_width {
	my ($self) = @_;
	my $width = 0;
	for my $cell_min_width ( map {$_->min_width} @{$self->{_children}} ) {
		$width = $cell_min_width if ($cell_min_width > $width);
	}
	return $width;
}

sub get_reg_width {
	my ($self) = @_;
	my $width = 0;
	for my $cell_reg_width ( map {$_->reg_width} @{$self->{_children}} ) {
		$width = $cell_reg_width if ($cell_reg_width > $width);
	}
	return $width;
}

1;

=head1 NAME
PDF::TableX::Column

=head1 VERSION
Version 0.01
=cut

=head1 SYNOPSIS

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