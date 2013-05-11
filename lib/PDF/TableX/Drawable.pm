package PDF::TableX::Drawable;

use Moose::Role;

requires 'draw_content';
requires 'draw_borders';
requires 'draw_background';

1;