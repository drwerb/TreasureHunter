package Map;

use strict;
use warnings;

use Mouse;

use Cell;
use CellSet;

has 'width'  => (is => 'rw', isa => 'Int', required => 1);
has 'height' => (is => 'rw', isa => 'Int', required => 1);

has 'freePositionsSet' => (is => 'rw', isa => 'HashRef[HashRef]', builder => '_fillFreePositionsSet' );
has 'cellSet' => (is => 'rw', isa => 'HashRef[Object]', default => sub { {} } );

sub _fillFreePositionsSet {
    my ($self) = @_;

    my $freePositionsSet = {};

    for my $row ( 1 .. $self->width ) {
        for my $col ( 1 .. $self->height ) {
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

sub setCell {
    my ($self, $x, $y, $val) = @_;

    $self->cellSet()->{$x}{$y} = Cell->new({
                                        x     => $x,
                                        y     => $y,
                                        value => $val,
                                    });
}

sub getCellByPosition {
    my ($self, $position) = @_;

    return $self->cellSet->{ $self->getPositionKey($position) };
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

    for my $row ( 1 .. $self->width ) {
        for my $col ( 1 .. $self->height ) {
            my $cell = $cellSet->{ $self->getPositionKey({ x => $col, y => $row}) };
            printf "%s", $cell->cellChar if ( $cell );
        }
        print "\n";
    }
}

sub printMapWithPath {
    my ($self, $path) = @_;

    my $pathCellSet = CellSet->new();

    map {
        $pathCellSet->addPathCell($_);
    } @$path;

    my $cellSet = $self->cellSet();

    for my $row ( sort { $a <=> $b } keys %$cellSet ) {
        print join(
                "",
                map { $pathCellSet->isCellExistsInSet($cellSet->{$row}{$_})
                      ? "x"
                      : $cellSet->{$row}{$_}->value }
                    sort { $a <=> $b } keys %{ $cellSet->{$row} }
            ) . "\n";
    }
}

1;