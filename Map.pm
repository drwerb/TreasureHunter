package Map;

use strict;
use warnings;

use Mouse;

use Cell;
use CellSet;

has 'width'  => (is => 'rw', isa => 'Int');
has 'heigth' => (is => 'rw', isa => 'Int');

has 'cellSet' => (is => 'rw', isa => 'HashRef[HashRef[Cell]]', default => sub { {} } );

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

sub getCell {
    my ($self, $x, $y) = @_;

    return $self->cellSet()->{$x}{$y};
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

    for my $row ( sort { $a <=> $b } keys %$cellSet ) {
        print join(
                "",
                map { $cellSet->{$row}{$_}->value }
                    sort { $a <=> $b } keys %{ $cellSet->{$row} }
            ) . "\n";
    }
}

sub printMap {
    my ($self) = @_;

    my $cellSet = $self->cellSet();

    for my $row ( sort { $a <=> $b } keys %$cellSet ) {
        print join(
                "",
                map { $cellSet->{$row}{$_}->value }
                    sort { $a <=> $b } keys %{ $cellSet->{$row} }
            ) . "\n";
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