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

    my @flowCellsSequence = $self->buildRandomFlowCellSequence();

    if ( @flowCellsSequence ) {
        my $flowCellsCount = @flowCellsSequence;
        my $flowForce = int(rand($flowCellsCount - 1)) + 1;

        for my $i ( 0 .. $flowCellsCount-1 ) {
            my $prevIndex = $i - 1;
            my $nextIndex = ( $i != ($flowCellsCount-1) ) ? $i + 1 : 0;
            my $flowCell = $flowCellsSequence[$i];

            $flowCell->Force($flowForce);
            $flowCell->prevFlowCell( $flowCellsSequence[$prevIndex] );
            $flowCell->nextFlowCell( $flowCellsSequence[$nextIndex] );
        }
    }

    return @flowCellsSequence;
}

sub buildRandomFlowCellSequence {
    my ($self) = @_;

    my @flow = ( $self->firstFlowCell );

    NEXT_FLOW_CELL: while ( @flow ) {
        my @directions = qw( upperNeighbor bottomNeighbor leftNeighbor rightNeighbor );

        my $cell = $flow[-1];
        my $cellFlowNeighbor;

        NEXT_DIRECTION: while ( my ($directionMethod) = splice(@directions, rand(@directions), 1) ) {

            $cellFlowNeighbor = $self->$directionMethod($cell);

            if ( $cellFlowNeighbor && $cellFlowNeighbor->isSameCell( $self->firstFlowCell ) && @flow > 2 ) {
                return @flow;
            }
            elsif ( ! $cellFlowNeighbor ) {
                my $freePos = $self->isNeighborDirectionFree($cell, $directionMethod);

                next NEXT_DIRECTION if ( ! $freePos );

                my $newFlowCell = Cell::Flow->new();

                $self->setCellOnPosition({
                        cell     => $newFlowCell,
                        position => $freePos,
                    });

                push @flow, $newFlowCell;

                next NEXT_FLOW_CELL;
            }
        }

        pop @flow;
    }

    return ();
}

__PACKAGE__->meta->make_immutable();

1;