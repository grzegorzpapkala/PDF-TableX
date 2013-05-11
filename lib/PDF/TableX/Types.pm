package PDF::TableX::Types;

use MooseX::Types -declare => [qw/StyleDefinition/];
use MooseX::Types::Moose qw/ArrayRef Any/;

subtype StyleDefinition, as ArrayRef;
coerce StyleDefinition, from Any, via {
	[$_,$_,$_,$_];
};