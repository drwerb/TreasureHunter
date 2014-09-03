package CellFabric;

use Mouse;

has 'cellClasses' => ( is => 'ro', isa => 'ArrayRef', builder => '_enumCellClasses' );
has 'cellCharMap' => ( is => 'rw', isa => 'HashRef', builder => '_mapCellCharsToClasses' );

sub _enumCellClasses {
    return [
            qw(
                Cell::BlackHole
                Cell::ET
                Cell::Earth
                Cell::Flow
                Cell::Moon
                Cell::Treasure
            )
        ];
}

sub _mapCellCharsToClasses {
    my ($self) = @_;

    my $mapHash = {};

    for my $cellClass ( @{ $self->cellClasses } ) {
        eval "require $cellClass";
        $mapHash->{ $cellClass->new->cellChar } = $cellClass;
    }

    return $mapHash;
}

sub getCellObjectByChar {
    my ($self, $char) = @_;

    my $cellClass = $self->cellCharMap->{$char};

    return $cellClass->new();
}

1;