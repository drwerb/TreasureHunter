package Cell::BlackHole;

use Mouse;

use base qw(Cell);

has 'nextHolePosition' => ( is => 'rw', isa => 'HashRef' );
has 'cellChar' => ( is => 'ro', isa => 'Str', default => 'H');

1;