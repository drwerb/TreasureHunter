package GameSession;

use Mouse;

use IO::File;
use Time::HiRes qw(gettimeofday);

has 'sessionStorePath' => ( is => 'ro', isa => 'Str', default => sub { ( $ENV{GameStore} ? $ENV{GameStore} : '.' ) . 'StoredData/Session' });
has 'ID' => ( is => 'rw', isa => 'Int', default => sub { join("", gettimeofday()) } );

has 'sessionData' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub store {
    my ($self) = @_;

    my $jsonSessionData = JSON->new->pretty(1)->encode( $self->sessionData );

    my $fh = IO::File->new( $self->getFilePath, "w" );

    print $fh $jsonSessionData;

    $fh->close();
}

sub restore {
    my ($self) = @_;

    my $fh = IO::File->new( $self->getFilePath, "r" );

    $self->sessionData( JSON->new->decode( join("", <$fh>) ) );

    $fh->close();
}

sub getFilePath {
    my ($self) = @_;
    return join("/", $self->sessionStorePath, $self->ID);
}

sub DEMOLISH {
    my ($self) = @_;
    $self->store();
}

__PACKAGE__->meta->make_immutable();

1;