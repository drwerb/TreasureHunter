package MapGenerator;

use strict;
use warnings;

use Mouse;

use Map;
use Cell;

use constant (
    CELL_EARTH => 1,
    CELL_TREASURE => 2,
    CELL_MOON => 3,
    CELL_ET => 4,
    CELL_FLOW => 5,
    CELL_BLACK_HOLE => 6,
);

has 'mapWidth'  => ( is => 'rw', isa => 'Int', required => 1 );
has 'mapHeight' => ( is => 'rw', isa => 'Int', required => 1 );

has 'gameMap' => ( is => 'rw', isa => 'Map' );

has 'firstBlackHole' => ( is => 'rw', isa => 'Cell::BlackHole' );
has 'lastBlackHole'  => ( is => 'rw', isa => 'Cell::BlackHole' );

has 'treasureCell' => ( is => 'rw', isa => 'Cell::Treasure' );

has 'earthCell' => ( is => 'rw', isa => 'Cell::Earth' );
has 'moonCell' => ( is => 'rw', isa => 'Cell::Land' );

sub generateMap {
    my ($self) = @_;

    return undef if ( $self->mapWidth * $self->mapHeight < 4 );

    my $map = Map->new({ width => $self->mapWidth, heigth => $self->mapHeight });

    $self->gameMap($map);

    $self->addEarth();
    $self->addTreasure();
    $self->addMoon();
    $self->addET();

    $self->addFlow();

    $self->addRandomCells();

    return $map;
}

sub addEarth {
    my ($self) = @_;

    my $map = $self->gameMap;

    my $earthCell = Cell::Earth->new();

    my $earthPos = $map->setCellOnRandomFreePosition($earthCell);

    $self->earthPosition( $earthPos );
}

sub addTreasure {
    my ($self) = @_;

    my $map = $self->gameMap;

    my $treasureCell = Cell::Treasure->new();

    my $freePositionsSet = $map->getFreePositionsSet();

    while ( my $freePosition = $freePositionsSet->each() ) {
        next if ( $map->distanceBetween($freePosition, $self->earthPosition) );
        $map->setCellOnPosition({ cell => $treasureCell, pos => $freePosition });
        return 1;
    }

    return undef;
}

sub addMoon {
    my ($self, $args) = @_;

    my $map = $self->gameMap;

    my $moonCell = Cell::Moon->new();

   $map->setCellOnRandomFreePosition($moonCell);

    return 1;
}

sub addET {
    my ($self, $args) = @_;

    my $map = $self->gameMap;

    my $ETCell = Cell::ET->new({ moon => $self->moonCell });

   $map->setCellOnRandomFreePosition($ETCell);

    return 1;
}

sub addRandomCells {
    my ($self) = @_;

    while ( $self->gameMap->hasFreePosition() ) {
        my @cellTypeSet = (CELL_BLACK_HOLE, CELL_ET, CELL_FLOW);
        my $newCellType = @cellTypeSet( rand(@cellTypeSet) );

        if ( $newCellType == CELL_BLACK_HOLE ) {
            $self->addBlackHole();
        }
        elsif ( $newCellType == CELL_ET ) {
            $self->addET();
        }
        elsif ( $newCellType == CELL_FLOW ) {
            $self->addFlow();
        }
    }
}

sub addBlackHole {
    my ($self) = @_;

    my $map = $self->gameMap;

    if ( $self->firstBlackHole ) {

        my $newBlackHole = Cell::BlackHole->new({ nextHole => $self->firstBlackHole });
        $self->lastBlackHole->nextHole( $newBlackHole );
        $self->lastBlackHole( $newBlackHole );

       $map->setCellOnRandomFreePosition($newBlackHole);

    }
    elsif ( $map->countFreePositions() >= 2 ) {
        $self->firstBlackHole( Cell::BlackHole->new() );
        $self->lastBlackHole( Cell::BlackHole->new() );

        $self->firstBlackHole->nextHole( $self->lastBlackHole );
        $self->lastBlackHole->nextHole( $self->firstBlackHole );

        $map->setCellOnRandomFreePosition($self->firstBlackHole);
        $map->setCellOnRandomFreePosition($self->lastBlackHole);
    }

    return 1;
}

sub addFlow {
    my ($self) = @_;

    my $map = $self->gameMap;

    my $mapClone = $map->clone();

    my $freePositionsSet = $mapClone->getFreePositionsSet();

    my $flowBuilder = Map::FlowBuilder->new({ map => $mapClone });

    for my $freePosition ( $freePositionsSet ) {
        my $newVacantFlowCell = Cell::Flow::Vacant->new({ map => $mapClone });

        $flowBuilder->setCellOnPosition({ cell => $newVacantFlowCell, position => $freePosition });

        if ( $flowBuilder->allowedDirectionsCount($newVacantFlowCell) > 2 ) {
            $flowBuilder->setRecurciveRegionIndex($newVacantFlowCell);
        }
        elsif ( $flowBuilder->allowedDirectionsCount($newVacantFlowCell) == 2 ) {
            if ( $flowBuilder->isNeiborhoodRegionsDefined($newVacantFlowCell) ) {
                $flowBuilder->setRecurciveRegionIndex($newVacantFlowCell);
            }
            else {
                $flowBuilder->setUnknownRegion($newVacantFlowCell);
            }
        }
        else {
            $flowBuilder->setRecurciveOnedirectedDenied($newVacantFlowCell);
        }
    }

    my $flowRegion  = $flowBuilder->selectRandomRegion(); # Map::FlowBuilder::Region

    my $vacantCellsLine = $flowRegion->getFlowRandomLine(); # Map::FlowBuilder::Line

    my $flowFirstCornerCell = $vacantCellsLine->getRandomCornerCell();

    $flowFirstCornerCell->setTrueFlowCell();

    my $lastCornerCell;

    $vacantCellsLine = $flowRegion->getNormalLineCrossing({
            line => $vacantCellsLine,
            cell => $flowFirstCornerCell,
        });

    while (1) {
        $lastCornerCell = $vacantCellsLine->getRandomVacantCornerCell();
    }
    continue {
        my $tmpLine = Map::FlowBuilder::Line->new({
                cell1 => $flowFirstCornerCell,
                cell2 => $lastCornerCell,
            });

        last if ( $flowRegion->isCellReachableThroughInactiveCells({
                        withActive => $tmpLine,
                        start      => $lastCornerCell,
                        goal       => $flowFirstCornerCell,
                    })
                );

        $vacantCellsLine->markExcludedCornerCell($lastCornerCell);
    }

    $flowRegion->setTrueFlowLineCells({ from => $flowFirstCornerCell, to => $lastCornerCell });

    $flowRegion->markDisabledUnreachableArea({
            start => $lastCornerCell,
            goal  => $flowFirstCornerCell,
        });

    while ( $vacantCellsLine = $flowRegion->getNormalLineCrossing({ line => $vacantCellsLine, cell => $lastCornerCell }) ) {

        if ( $vacantCellsLine->isContains({ cell => $flowFirstCornerCell }) ) {
            $flowRegion->setTrueFlowLineCells({ from => $lastCornerCell, to => $flowFirstCornerCell });
            last;
        }

        my $currentCornerCell;

        while (1) {
            $currentCornerCell = $vacantCellsLine->getRandomVacantCornerCell();
        }
        continue {
            my $tmpLine = Map::FlowBuilder::Line->new({
                    cell1 => $lastCornerCell,
                    cell2 => $currentCornerCell,
                });

            last if ( $flowRegion->isCellReachableThroughInactiveCells({
                            withActive => $tmpLine,
                            start      => $currentCornerCell,
                            goal       => $flowFirstCornerCell,
                        })
                    );

            $vacantCellsLine->markExcludedCornerCell($currentCornerCell);
        }
    }

    for my $flowActiveCell ( $flowRegion->getActiveFlowCellsSet() ) {
        $map->setCellOnPosition({
                cell     => $flowActiveCell,
                position => $flowActiveCell->getPosition(),
            });
    }
}

1;