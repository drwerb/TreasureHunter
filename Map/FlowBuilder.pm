package Map::FlowBuilder;

use Mouse;
use Storable qw(dclone);

use Data::Dumper;

use base qw(Map);

use constant MAX_FLOW_FORCE => 3;

has 'firstFlowCell' => ( is => 'rw', isa => 'Cell::Flow' );
has 'iteration' => ( is => 'rw', isa => 'Int' );

sub cloneMap {
    my ($self, $map) = @_;

    $self->freePositionsSet( dclone($map->freePositionsSet) );
    $self->cellSet( dclone($map->cellSet) );
}

sub generateRandomFlow {
    my ($self) = @_;

    my $freeCellPosition;

    for my $cellPos ( $self->getFreeCellsSetRandomPositions() ) {
        next if ( $self->freeNeighborsCount($cellPos) < 2 );
        $freeCellPosition = $cellPos;
        last;
    }

    return () if ( ! $freeCellPosition );

    $self->firstFlowCell( Cell::Flow->new() );

    $self->setCellOnPosition({
            cell     => $self->firstFlowCell,
            position => $freeCellPosition,
        });

    my @flowCellsSequence;

    $self->iteration(0);

    if ( $self->findNextRandomFlowCell( $self->firstFlowCell ) ) {
        my $prevCell  = $self->firstFlowCell;
        my $tmpCell;
        my $flowForce = int(rand(MAX_FLOW_FORCE)) + 1;
        while (1) {
            $tmpCell = $prevCell->nextFlowCell;
            $tmpCell->Force($flowForce);
            $tmpCell->prevFlowCell($prevCell);
            push @flowCellsSequence, $tmpCell;
        }
        continue {
            last if ( $tmpCell->isSameCell( $self->firstFlowCell ) );
            $prevCell = $tmpCell;
        }
    }

    return @flowCellsSequence;
}

sub findNextRandomFlowCell {
    my ($self, $cell) = @_;

    $self->iteration( $self->iteration + 1 );

    my @directions = qw( upperNeighbor bottomNeighbor leftNeighbor rightNeighbor );

    my $cellFlowNeighbor;

    while ( my $directionMethod = splice(@directions, rand(@directions), 1) ) {

        $cellFlowNeighbor = $cell->$directionMethod;

        if ( $cellFlowNeighbor && $cellFlowNeighbor->isSameCell( $self->firstFlowCell ) && $self->iteration > 2 ) {
            $cell->nextFlowCell( $self->firstFlowCell );
            $self->iteration( $self->iteration - 1 );
            return $cellFlowNeighbor;
        }
        elsif ( ! $cellFlowNeighbor ) {
            my $freePos = $self->isNeighborDirectionFree($cell, $directionMethod);

            next if ( ! $freePos );

            my $newFlowCell = Cell::Flow->new();

            $self->setCellOnPosition({
                    cell     => $newFlowCell,
                    position => $freePos,
                });

            if ( $self->findNextRandomFlowCell($newFlowCell) ) {
                $cell->nextFlowCell( $newFlowCell );
                $self->iteration( $self->iteration - 1 );
                return $newFlowCell;
            }
        }
    }

    $self->iteration( $self->iteration - 1 );
    return undef;
}

1;