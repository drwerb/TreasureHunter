package Cell::Earth;

use Mouse;

use base qw(Cell);
has 'cellChar' => ( is => 'ro', isa => 'Str', default => 'E');

__PACKAGE__->meta->make_immutable();

1;