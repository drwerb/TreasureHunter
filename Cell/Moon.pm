package Cell::Moon;

use Mouse;

use base qw(Cell);
has 'cellChar' => ( is => 'ro', isa => 'Str', default => 'M');

1;