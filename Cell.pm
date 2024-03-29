package Cell;

use Mouse;

has 'x' => ( is => 'rw', isa => 'Int' );
has 'y' => ( is => 'rw', isa => 'Int' );

has 'upperNeighbor'  => ( is => 'rw', isa => 'Cell' );
has 'bottomNeighbor' => ( is => 'rw', isa => 'Cell' );
has 'leftNeighbor'   => ( is => 'rw', isa => 'Cell' );
has 'rightNeighbor'  => ( is => 'rw', isa => 'Cell' );

has 'cellChar' => ( is => 'ro', isa => 'Str', default => '');

has 'isFree' => ( is => 'rw', isa => 'Bool', default => sub {1} );

sub isSameCell {
    my ($self, $cellData) = @_;

    if ( ref($cellData) eq 'HASH' ) {
        return ( $self->x == $cellData->{x} && $self->y == $cellData->{y} );
    }
    else {
        return ( $self->x == $cellData->x && $self->y == $cellData->y );
    }
}

sub position {
    my ($self) = @_;
    return {
        x => $self->x,
        y => $self->y,
    };
}

sub onCellStep {
    my ($self) = @_;
    return $self->position;
}

sub serialize {
    my ($self) = @_;

    my $cellSerialized = {
        x        => $self->x,
        y        => $self->y,
        cellType => $self->cellChar,
    };

    return $cellSerialized;
}

sub restore {
    my ($self, $data) = @_;

    $self->x( $data->{x} );
    $self->y( $data->{y} );
}

__PACKAGE__->meta->make_immutable();

1;