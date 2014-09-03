package Map;

use strict;
use warnings;

use Mouse;
use Graph::Directed;

use Cell;
use CellSet;
use CellFabric;

has 'width'  => (is => 'rw', isa => 'Int', required => 1);
has 'height' => (is => 'rw', isa => 'Int', required => 1);

has 'freePositionsSet' => (is => 'rw', isa => 'HashRef[HashRef]', builder => '_fillFreePositionsSet' );
has 'cellSet' => (is => 'rw', isa => 'HashRef[Object]', default => sub { {} } );

sub _fillFreePositionsSet {
    my ($self) = @_;

    my $freePositionsSet = {};

    for my $row ( 1 .. $self->height ) {
        for my $col ( 1 .. $self->width ) {
            $freePositionsSet->{$col . "_" . $row} = { x => $col, y => $row };
        }
    }

    $self->freePositionsSet( $freePositionsSet );
}

sub getRandomFreePosition {
    my ($self) = @_;
    my $posHash   = $self->freePositionsSet;
    my @keysArray = keys %$posHash;

    return undef if ( ! @keysArray );

    my $randomKey = $keysArray[ rand @keysArray ];

    return $posHash->{$randomKey};
}

sub setCellOnRandomFreePosition {
    my ($self, $cell) = @_;

    my $randPos = $self->getRandomFreePosition();

    $self->setCellOnPosition({ cell => $cell, position => $randPos });

    return $randPos;
}

sub setCellOnPosition {
    my ($self, $args) = @_;

    my $cell = $args->{cell};
    my $position = $args->{position};

    $cell->x( $position->{x} );
    $cell->y( $position->{y} );
    
    my $cellSet = $self->cellSet;

    my $posKey = $self->getPositionKey($position);

    $cellSet->{ $posKey } = $cell;

    delete $self->freePositionsSet->{$posKey};

    $self->setCellNeighbors($cell);
}

sub setCellNeighbors {
    my ($self, $cell) = @_;

    my $cellSet = $self->cellSet;
    my $neighborCell;

    my ($x, $y) = ($cell->x, $cell->y);

    # upper
    if ( $neighborCell = $cellSet->{ $self->getPositionKey({ x => $x, y => ($y - 1) }) } ) {
        $cell->upperNeighbor( $neighborCell );
        $neighborCell->bottomNeighbor( $cell );
    }

    # bottom
    if ( $neighborCell = $cellSet->{ $self->getPositionKey({ x => $x, y => ($y + 1) }) } ) {
        $cell->bottomNeighbor( $neighborCell );
        $neighborCell->upperNeighbor( $cell );
    }

    # left
    if ( $neighborCell = $cellSet->{ $self->getPositionKey({ x => ($x - 1), y => $y }) } ) {
        $cell->leftNeighbor( $neighborCell );
        $neighborCell->rightNeighbor( $cell );
    }

    # right
    if ( $neighborCell = $cellSet->{ $self->getPositionKey({ x => ($x + 1), y => $y }) } ) {
        $cell->rightNeighbor( $neighborCell );
        $neighborCell->leftNeighbor( $cell );
    }
}

sub getPositionKey {
    my ($self, $position) = @_;
    return $position->{x} . "_" . $position->{y};
}

sub distanceBetween {
    my ($self, $position1, $position2) = @_;

    my $dX = $position1->{x} - $position2->{x};
    my $dY = $position1->{y} - $position2->{y};

    return sqrt( $dX * $dX  +  $dY * $dY );
}

sub countFreePositions {
    my ($self) = @_;
    return scalar( keys %{ $self->freePositionsSet } );
}

sub getFreeCellsSetRandomPositions {
    my ($self) = @_;

    my $posHash   = $self->freePositionsSet;
    my @keysArray = keys %$posHash;

    my @randFreePositions;
    while ( @keysArray ) {
        my $randomIndex = rand @keysArray;
        my $randomKey   = splice(@keysArray, $randomIndex, 1);
        push @randFreePositions, $posHash->{$randomKey};
    }

    return @randFreePositions;
}

sub freeNeighborsCount {
    my ($self, $position) = @_;

    my $freeSet = $self->freePositionsSet;

    my $count = 0;

    my ($x, $y) = ($position->{x}, $position->{y});

    # upper
    $count++ if ( $freeSet->{ $self->getPositionKey({ x => $x, y => ($y - 1) }) } );

    # bottom
    $count++ if ( $freeSet->{ $self->getPositionKey({ x => $x, y => ($y + 1) }) } );

    # left
    $count++ if ( $freeSet->{ $self->getPositionKey({ x => ($x - 1), y => $y }) } );

    # right
    $count++ if ( $freeSet->{ $self->getPositionKey({ x => ($x + 1), y => $y }) } );

    return $count;
}

sub isNeighborDirectionFree {
    my ($self, $cell, $direction) = @_;

    my $freeSet = $self->freePositionsSet;

    my ($x, $y) = ($cell->x, $cell->y);

    # upper
    if ( $direction eq 'upperNeighbor' ) {
        return $freeSet->{ $self->getPositionKey({ x => $x, y => ($y - 1) }) };
    }
    # bottom
    elsif ( $direction eq 'bottomNeighbor' ) {
        return $freeSet->{ $self->getPositionKey({ x => $x, y => ($y + 1) }) };
    }
    # left
    elsif ( $direction eq 'leftNeighbor' ) {
        return $freeSet->{ $self->getPositionKey({ x => ($x - 1), y => $y }) };
    }
    # right
    elsif ( $direction eq 'rightNeighbor' ) {
        return $freeSet->{ $self->getPositionKey({ x => ($x + 1), y => $y }) };
    }

    return undef;
}

sub loadMap {
    my ($self, $args) = @_;

    my $filepath = $args->{file} || die "No file path set";

    -f $filepath || die "File $filepath does not exist";

    open( my $fh, "<", $filepath ) || die "Cannot open $filepath for read";

    while ( <$fh> ) {
        $self->processFileRow($_, $.);
    }

    close $fh;
}

sub processFileRow {
    my ($self, $row, $rowNumber) = @_;

    chomp($row);

    my @rowChars = split(//, $row);

    my $i;

    for ( $i = 0; $i < @rowChars; $i++ ) {
        $self->setCell($rowNumber, $i, $rowChars[$i]);
    }
}

sub getCellByPosition {
    my ($self, $position) = @_;

    return $self->cellSet->{ $self->getPositionKey($position) };
}

sub getCellByKey {
    my ($self, $key) = @_;

    return $self->cellSet->{ $key };
}

sub getCellNeighbors {
    my ($self, $cell) = @_;

    my @neighbors;

    for my $dX ( -1, 0, 1 ) {
        for my $dY ( -1, 0, 1 ) {
            next if ( ! $dX & ! $dY );

            my ( $x, $y ) = ( $cell->x + $dX, $cell->y + $dY );

            next if ( $x < 0 || $y < 0 );

            my $candidate = $self->getCell($x, $y);

            push @neighbors, $candidate if ( $candidate->isPathCell() );
        }
    }

    return @neighbors;
}

sub printMap {
    my ($self) = @_;

    my $cellSet = $self->cellSet();

    for my $row ( 1 .. $self->height ) {
        for my $col ( 1 .. $self->width ) {
            my $cell = $cellSet->{ $self->getPositionKey({ x => $col, y => $row}) };
            printf "%s", $cell->cellChar if ( $cell );
        }
        print "\n";
    }
}

sub shortestPathBetweenCells {
    my ($self, $cellPositionFrom, $cellPositionTo, $args) = @_;

    my $stayOnCellOnly = $args->{stayOnCellOnly};

    my $directedGraph = $self->generateDirectedGraph({
            excludedTypes   => $args->{excludedTypes},
            stayOnCellOnly => $stayOnCellOnly,
        });

    my $cellFromKey = $self->getPositionKey( $cellPositionFrom );
    my $cellToKey   = $self->getPositionKey( $cellPositionTo );

    my @path = $directedGraph->SP_Dijkstra($cellFromKey, $cellToKey);

    return () if ( !@path );

    my $cellSet = $self->cellSet;
    my $blackHolesOrder = $self->getBlackHolesOrder();

    my @reversedBlackHolesKeys = sort {
                                    $blackHolesOrder->{$b} <=> $blackHolesOrder->{$a}
                                } keys %$blackHolesOrder;

    use Data::Dumper;

    my %reversedBlackHolesMap;

    for my $i ( 0 .. (@reversedBlackHolesKeys - 1) ) {
        my $nextIndex = ($i + 1) % scalar(@reversedBlackHolesKeys);
        $reversedBlackHolesMap{ $reversedBlackHolesKeys[$i] } = $reversedBlackHolesKeys[$nextIndex];
    }

    my @posPath = map {
            my $cell = $cellSet->{$_};
            if ( ref($cell) eq 'Cell::BlackHole' && ! $stayOnCellOnly ) {
                my $previousBlackHole = $cellSet->{ $reversedBlackHolesMap{$_} };
                ($previousBlackHole->position, $cell->position)
            }
            else {
                $cell->position
            }
        } @path;

    return @posPath;
}

sub generateDirectedGraph {
    my ($self, $args) = @_;

    # HashRef is expected or undef
    my $excludedTypes   = $args->{excludedTypes};
    my $stayOnCellOnly = $args->{stayOnCellOnly};

    my $directedGraph = Graph::Directed->new();

    my $cellSet = $self->cellSet();

    my @directions = qw( upperNeighbor bottomNeighbor leftNeighbor rightNeighbor );

    for my $row ( 1 .. $self->height ) {
        for my $col ( 1 .. $self->width ) {
            my $cell = $cellSet->{ $self->getPositionKey({ x => $col, y => $row}) };

            next if ( ref($cell) eq 'Cell::ET' );

            for my $directionMethod ( @directions ) {
                my $fromCell = $cell;
                my $stepCell = $fromCell->$directionMethod;

                next if ( ! $stepCell || $excludedTypes->{ ref($stepCell) } );

                my $reachedCellPosition = $stepCell->onCellStep({ stepFromCell => $fromCell });

                if ( ref($stepCell) eq 'Cell::ET' && ! $stayOnCellOnly ) {
                    $self->_addGraphEdge($directedGraph, $fromCell->position, $stepCell->position);
                    $fromCell = $stepCell;
                }

                $self->_addGraphEdge($directedGraph, $fromCell->position, $reachedCellPosition);
            }
        }
    }

    return $directedGraph;
}

sub _addGraphEdge {
    my ($self, $graph, $posFrom, $posTo) = @_;

    my $cellFromKey = $self->getPositionKey( $posFrom );
    my $cellToKey   = $self->getPositionKey( $posTo );

    $graph->add_edge($cellFromKey, $cellToKey);
}

sub getBlackHolesOrder {
    my ($self) = @_;

    my $cellSet = $self->cellSet;
    my $firstBlackHole;

    for ( keys %$cellSet ) {
        if ( ref($cellSet->{$_}) eq "Cell::BlackHole" ) {
            $firstBlackHole = $cellSet->{$_};
            last;
        }
    }

    my $blackHoleCellKey = $self->getPositionKey( $firstBlackHole->position );
    my %blackHolesOrder;
    my $blackHoleCount = 0;

    while (1) {
        $blackHolesOrder{ $blackHoleCellKey } = ++$blackHoleCount;
    }
    continue {
        my $blackHoleCell = $cellSet->{$blackHoleCellKey};
        $blackHoleCellKey = $self->getPositionKey($blackHoleCell->nextHolePosition);
        last if ( $firstBlackHole->isSameCell( $cellSet->{$blackHoleCellKey} ) );
    }

    return \%blackHolesOrder;
}

sub dataHash {
    my ($self) = @_;

}

sub serialize {
    my ($self) = @_;

    my $mapSerialized = {
        width  => $self->width,
        height => $self->height,
    };

    my $cellSet = $self->cellSet;
    my $firstBlackHole;

    for my $key ( keys %$cellSet ) {
        $mapSerialized->{cellSet}->{$key} = $cellSet->{$key}->serialize();
    }

    $mapSerialized->{blackHolesOrder} = $self->getBlackHolesOrder();

    $mapSerialized->{ pathEarthTreasure }->{allCells} = [
            map {
                $self->getPositionKey($_)
            } $self->shortestPathBetweenCells( $self->earthCell->position, $self->treasureCell->position)
        ];

    $mapSerialized->{ pathEarthTreasure }->{stayOnCells} = [
            map {
                $self->getPositionKey($_)
            } $self->shortestPathBetweenCells(
                        $self->earthCell->position,
                        $self->treasureCell->position,
                        { stayOnCellOnly => 1 },
                    )
    ];

    $mapSerialized->{ pathMoonTreasure }->{allCells} = [
            map {
                $self->getPositionKey($_)
            } $self->shortestPathBetweenCells( $self->moonCell->position, $self->treasureCell->position)
        ];

    $mapSerialized->{ pathMoonTreasure }->{stayOnCells} = [
            map {
                $self->getPositionKey($_)
            } $self->shortestPathBetweenCells(
                        $self->moonCell->position,
                        $self->treasureCell->position,
                        { stayOnCellOnly => 1 },
                    )
        ];

    $mapSerialized->{ pathTreasureEarth }->{allCells} = [
            map {
                $self->getPositionKey($_)
            } $self->shortestPathBetweenCells(
                                                $self->treasureCell->position,
                                                $self->earthCell->position,
                                                {
                                                    excludedTypes => { "Cell::ET" => 1 },
                                                }
                                            )
        ];

    $mapSerialized->{ pathTreasureEarth }->{stayOnCells} = [
            map {
                $self->getPositionKey($_)
            } $self->shortestPathBetweenCells(
                                                $self->treasureCell->position,
                                                $self->earthCell->position,
                                                {
                                                    excludedTypes  => { "Cell::ET" => 1 },
                                                    stayOnCellOnly => 1,
                                                }
                                            )
        ];

    return $mapSerialized;
}

sub restore {
    my ($self, $mapData) = @_;

    my $cellSet = $mapData->{cellSet};
    my $cellFabric = CellFabric->new();

    for my $cellKey ( keys %$cellSet ) {
        my $cell = $cellFabric->getCellObjectByChar( $cellSet->{ $cellKey }->{cellType} );
        $cell->restore( $cellSet->{ $cellKey } );
        $self->setCellOnPosition({ cell => $cell, position => $cell->position });
    }

    $self->restoreFlows();
}

sub restoreFlows {
    my ($self) = @_;

    my $cellSet = $self->cellSet;

    for my $cellKey ( keys %$cellSet ) {
        my $cell = $cellSet->{ $cellKey };
        next if ( ref($cell) ne 'Cell::Flow' );
        $cell->nextFlowCell( $self->getCellByPosition( $cell->nextFlowCellPos ) );
        $cell->prevFlowCell( $self->getCellByPosition( $cell->prevFlowCellPos ) );
    }
}

sub findCellByType {
    my ($self, $type) = @_;

    my $cellSet = $self->cellSet();

    for my $row ( 1 .. $self->height ) {
        for my $col ( 1 .. $self->width ) {
            my $cell = $cellSet->{ $self->getPositionKey({ x => $col, y => $row}) };
            return $cell if ( ref($cell) eq $type );
        }
    }

    return undef;
}

sub earthCell {
    my ($self) = @_;

    return $self->findCellByType('Cell::Earth');
}

sub moonCell {
    my ($self) = @_;

    return $self->findCellByType('Cell::Moon');
}

sub treasureCell {
    my ($self) = @_;

    return $self->findCellByType('Cell::Treasure');
}

1;