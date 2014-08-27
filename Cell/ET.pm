package Cell::ET;

use Mouse;

use base qw(Cell);

has 'moonPosition' => ( is => 'rw', isa => 'HashRef', required => 1 );
has 'cellChar' => ( is => 'ro', isa => 'Str', default => 'U');

1;