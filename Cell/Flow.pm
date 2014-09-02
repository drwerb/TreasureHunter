package Cell::Flow;

use Mouse;

use base qw(Cell);

has 'nextFlowCell' => ( is => 'rw', isa => 'Cell::Flow' );
has 'prevFlowCell' => ( is => 'rw', isa => 'Cell::Flow' );
has 'Force'        => ( is => 'rw', isa => 'Int' );
has 'cellChar'     => ( is => 'ro', isa => 'Str', default => 'F');

sub onCellStep {
    my ($self, $args) = @_;

    my $stepFromCell = $args->{stepFromCell};

    if ( ref($stepFromCell) ne 'Cell::Flow' ) {
        return $self->position;
    }
    elsif ( $stepFromCell->nextFlowCell->isSameCell($self) ) {
        return $self->useForce()->position;
    }
    elsif ( $self->nextFlowCell->isSameCell($stepFromCell) ) {
        return $self->useForce()->position;
    }
    else {
        return $self->position;
    }
}

sub useForce {
    my ($self) = @_;

    my $flowCell = $self;

    for ( 1 .. $self->Force ) {
        $flowCell = $flowCell->nextFlowCell;
    }

    return $flowCell;
}

around 'serialize' => sub {
    my ($orig, $self) = @_;

    my $cellSerialized = $self->$orig();

    $cellSerialized->{meta} = {
        force        => $self->Force,
        nextFlowCell => $self->nextFlowCell->position,
        prevFlowCell => $self->prevFlowCell->position,
    };

    return $cellSerialized;
};

around 'restore' => sub {
    my ($orig, $self, $data) = @_;

    $self->$orig($data);

    $self->Force( $data->{meta}->{force} );
    $self->nextFlowCell( $data->{meta}->{nextFlowCell} );
    $self->prevFlowCell( $data->{meta}->{prevFlowCell} );
};

1;