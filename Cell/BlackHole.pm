package Cell::BlackHole;

use Mouse;

use base qw(Cell);

has 'nextHolePosition' => ( is => 'rw', isa => 'HashRef' );
has 'prevHolePosition' => ( is => 'rw', isa => 'HashRef' );
has 'cellChar' => ( is => 'ro', isa => 'Str', default => 'H');

sub onCellStep {
    my ($self) = @_;
    return $self->nextHolePosition;
}

around 'serialize' => sub {
    my ($orig, $self) = @_;

    my $cellSerialized = $self->$orig();

    $cellSerialized->{meta}->{nextHole} = $self->nextHolePosition;
    $cellSerialized->{meta}->{prevHole} = $self->prevHolePosition;

    return $cellSerialized;
};

around 'restore' => sub {
    my ($orig, $self, $data) = @_;

    $self->$orig($data);

    $self->nextHolePosition( $data->{meta}->{nextHole} );
    $self->prevHolePosition( $data->{meta}->{prevHole} );
};

__PACKAGE__->meta->make_immutable();

1;