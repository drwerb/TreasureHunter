package Cell::Treasure;

use Mouse;

use base qw(Cell);
has 'cellChar' => ( is => 'ro', isa => 'Str', default => 'T');

1;