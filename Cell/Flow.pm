package Cell::Flow;

use Mouse;

use base qw(Cell);

has 'nextFlowCell' => ( is => 'rw', isa => 'Cell::Flow' );
has 'cellChar' => ( is => 'ro', isa => 'Str', default => 'F');

1;