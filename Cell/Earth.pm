package Cell::Earth;

use Mouse;

use base qw(Cell);
has 'cellChar' => ( is => 'ro', isa => 'Str', default => 'E');

1;