package Cell::Treasure;

use Mouse;

use base qw(Cell);
has 'cellChar' => ( is => 'ro', isa => 'Str', default => 'T');

__PACKAGE__->meta->make_immutable();

1;