package MapGenerator;

use strict;
use warnings;

use Mouse;

use Map;
use Map::FlowBuilder;

use Cell;
use Cell::Earth;
use Cell::Moon;
use Cell::BlackHole;
use Cell::ET;
use Cell::Flow;
use Cell::Treasure;

use constant {
    CELL_EARTH => 1,
    CELL_TREASURE => 2,
    CELL_MOON => 3,
    CELL_ET => 4,
    CELL_FLOW => 5,
    CELL_BLACK_HOLE => 6,
};

has 'mapWidth'  => ( is => 'rw', isa => 'Int', required => 1 );
has 'mapHeight' => ( is => 'rw', isa => 'Int', required => 1 );

has 'gameMap' => ( is => 'rw', isa => 'Map' );

has 'firstBlackHole' => ( is => 'rw', isa => 'Cell::BlackHole' );
has 'lastBlackHole'  => ( is => 'rw', isa => 'Cell::BlackHole' );

has 'treasureCell' => ( is => 'rw', isa => 'Cell::Treasure' );

has 'earthCell' => ( is => 'rw', isa => 'Cell::Earth' );
has 'moonCell' => ( is => 'rw', isa => 'Cell::Moon' );

sub generateMap {
    my ($self) = @_;

    return undef if ( $self->mapWidth * $self->mapHeight < 4 );

    my $map = Map->new({ width => $self->mapWidth, height => $self->mapHeight });

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

    $self->earthCell( $earthCell );
}

sub addTreasure {
    my ($self) = @_;

    my $map = $self->gameMap;

    my $treasureCell = Cell::Treasure->new();

    my $freePositionsSet = $map->freePositionsSet();

    while ( my ($posKey, $freePosition) = each %$freePositionsSet ) {
        next if ( $map->distanceBetween($freePosition, $self->earthCell->position) <= 1 );
        $map->setCellOnPosition({ cell => $treasureCell, position => $freePosition });
        return 1;
    }

    return undef;
}

sub addMoon {
    my ($self, $args) = @_;

    my $map = $self->gameMap;

    my $moonCell = Cell::Moon->new();

    $map->setCellOnRandomFreePosition($moonCell);

    $self->moonCell( $moonCell );

    return 1;
}

sub addET {
    my ($self, $args) = @_;

    my $map = $self->gameMap;

    my $ETCell = Cell::ET->new({ moonPosition => $self->moonCell->position });

    $map->setCellOnRandomFreePosition($ETCell);

    return 1;
}

sub addRandomCells {
    my ($self) = @_;

    while ( $self->gameMap->countFreePositions() > 0 ) {
        my @cellTypeSet = (CELL_BLACK_HOLE, CELL_ET, CELL_FLOW);
        my $newCellType = @cellTypeSet[ rand(@cellTypeSet) ];

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

        my $newBlackHole = Cell::BlackHole->new({ nextHolePosition => $self->firstBlackHole->position });
        $self->lastBlackHole->nextHolePosition( $newBlackHole->position );
        $self->lastBlackHole( $newBlackHole );

       $map->setCellOnRandomFreePosition($newBlackHole);

    }
    elsif ( $map->countFreePositions() >= 2 ) {
        $self->firstBlackHole( Cell::BlackHole->new() );
        $self->lastBlackHole( Cell::BlackHole->new() );

        $map->setCellOnRandomFreePosition($self->firstBlackHole);
        $map->setCellOnRandomFreePosition($self->lastBlackHole);

        $self->firstBlackHole->nextHolePosition( $self->lastBlackHole->position );
        $self->lastBlackHole->nextHolePosition( $self->firstBlackHole->position );
    }

    return 1;
}

sub addFlow {
    my ($self) = @_;

    my $map = $self->gameMap;

    my $flowBuilder = Map::FlowBuilder->new({ width => $map->width, height => $map->height });

    $flowBuilder->cloneMap($map);

    my @flowCellsSequence = $flowBuilder->generateRandomFlow();

    for my $flowCell ( @flowCellsSequence ) {
        $map->setCellOnPosition({
                cell     => $flowCell,
                position => $flowCell->position(),
            });
    }

}

1;