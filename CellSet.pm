package CellSet;

use Mouse;
use Tree::Binary::Search;

has 'setAsArray' => ( is => 'rw', isa => 'ArrayRef[Cell::Path]', default => sub { [] } );
has 'setAsHash'  => ( is => 'rw', isa => 'HashRef[Cell::Path]',  default => sub { {} } );

has 'saveToTree' => ( is => 'rw', isa => 'Bool', default => sub { 1 } );

has 'setAsTree'  => ( is      => 'ro',
                    isa     => 'Tree::Binary::Search',
                    default => sub {
                                        my $tree = Tree::Binary::Search->new();
                                        $tree->useNumericComparison();
                                        return $tree;
                                   }
                     );

has 'cellArrayIndexHash' => ( is => 'rw', isa => 'HashRef[Int]' );

sub isEmpty {
    my ($self) = @_;
    return @{ $self->setAsArray() };
}

sub addPathCell {
    my ($self, $pathCell) = @_;

    $self->addCellToArray($pathCell);
    $self->addCellToHash($pathCell);
    $self->addCellToTree($pathCell) if ( $self->saveToTree );

}

sub addCellToArray {
    my ($self, $pathCell) = @_;

    #push @{ $self->setAsArray }, $pathCell;
}

sub addCellToHash {
    my ($self, $pathCell) = @_;

    my $hash_key = $self->_getCellHashKey($pathCell);

    $self->setAsHash->{$hash_key} = $pathCell;
}

sub addCellToTree {
    my ($self, $pathCell) = @_;

    my $cell_hash_key = $self->_getCellHashKey($pathCell);

    if ( $self->setAsTree->exists( $pathCell->f ) ) {
        $self->setAsTree->select( $pathCell->f )->{ $cell_hash_key } = $pathCell;
    }
    else {
        $self->setAsTree->insert( $pathCell->f => { $cell_hash_key => $pathCell } );
    }
}

sub getCellWithLowestF {
    my ($self) = @_;

    my $minNode = $self->setAsTree->min || return undef;

    my $firstKey = (keys %$minNode)[0];

    return $minNode->{$firstKey};
}

sub deletePathCell {
    my ($self, $pathCell) = @_;

    $self->deleteCellFromArray($pathCell);
    $self->deleteCellFromHash($pathCell);
    $self->deleteCellFromTree($pathCell) if ( $self->saveToTree );

}

sub deleteCellFromArray {
    my ($self, $pathCell) = @_;

    #push @{ $self->setAsArray }, $pathCell;
}

sub deleteCellFromHash {
    my ($self, $pathCell) = @_;

    delete $self->setAsHash->{ $self->_getCellHashKey($pathCell) };
}

sub deleteCellFromTree {
    my ($self, $pathCell) = @_;

    my $cell_hash_key = $self->_getCellHashKey($pathCell);
    my $cellNode      = $self->setAsTree->select( $pathCell->f );

    delete $cellNode->{$cell_hash_key};
    if ( $cellNode ) {
        delete $cellNode->{$cell_hash_key};
        $self->setAsTree->delete( $pathCell->f ) if ( ! keys %$cellNode );
    }

}

sub _getCellHashKey {
    my ($self, $cell) = @_;

    return $cell->x() . "_" . $cell->y();
}

sub isCellExistsInSet {
    my ($self, $cell) = @_;

    return exists $self->setAsHash->{ $self->_getCellHashKey($cell) };
}

1;