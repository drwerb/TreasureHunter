package Cell::ET;

use Mouse;

use base qw(Cell);

has 'moonPosition' => ( is => 'rw', isa => 'HashRef', required => 1 );
has 'cellChar' => ( is => 'ro', isa => 'Str', default => 'A');

sub onCellStep {
    my ($self) = @_;
    return $self->moonPosition;
}

around 'serialize' => sub {
    my ($orig, $self) = @_;

    my $cellSerialized = $self->$orig();

    $cellSerialized->{meta} = {
        moonPosition => $self->moonPosition,
    };

    return $cellSerialized;
};

1;