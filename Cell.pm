package Cell;

use Mouse;

has 'x' => ( is => 'rw', isa => 'Int' );
has 'y' => ( is => 'rw', isa => 'Int' );

has 'value' => ( is => 'rw', isa => 'Str' );

use constant PATH_CELL => 1;

sub isSameCell {
    my ($self, $cell) = @_;

    return ( $self->x == $cell->x && $self->y == $cell->y );
}

sub isPathOpen {
    my ($self) = @_;
    return defined $self->value && $self->value == PATH_CELL;
}

1;