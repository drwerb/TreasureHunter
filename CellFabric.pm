package CellFabric;

use Mouse;

has 'cellClasses' => ( is => 'ro', isa => 'ArrayRef', builder => _enumCellClasses );
has 'cellCharMap' => ( is => 'ro', isa => 'HashRef', builder => _mapCellCharsToClasses );

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

    my $mapHash = map {
            { $_->cellChar => $_ }
        } @{ $self->cellClasses };

    return $mapHash;
}

sub getCellObjectByChar {
    my ($self, $char) = @_;

    my $cellClass = $self->cellCharMap->{$char};

    return $cellClass->new();
}

1;