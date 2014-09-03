package GameServer;

use Mouse;

use Digest::SHA qw(sha256_hex);
use JSON;
use IO::File;
use Time::HiRes qw(gettimeofday);

use MapGenerator;

has 'gameMapStorePath' => ( is => 'ro', isa => 'Str', default => sub { $ENV{GameStore} || 'StoredData/GameMap' });
has 'sessionStorePath' => ( is => 'ro', isa => 'Str', default => sub { $ENV{GameStore} || 'StoredData/Session' });

sub startNewGame {
    my ($self, $args) = @_;

    my ($mapHash, $mapGenerator) = $self->storeNewMap($args);

    if ( $args->{sessionID} ) {
        $self->setSessionNewMap($args->{sessionID}, $args);
    }
    else {
        return $self->storeNewSession({ mapHash => $mapHash, position => $mapGenerator->earthCell->position, });
    }

}

sub storeNewMap {
    my ($self, $args) = @_;

    my $mg;

    while (1) {
        $mg = MapGenerator->new({ mapWidth => $args->{mapWidth}, mapHeight => $args->{mapHeight} });

        $map = $mg->generateMap();
    }
    continue {
        last if (
            $map->shortestPathBetweenCells( $mg->earthCell->position, $mg->treasureCell->position ) 
            &&
            $map->shortestPathBetweenCells( $mg->moonCell->position, $mg->treasureCell->position )
            &&
            $map->shortestPathBetweenCells( $mg->treasureCell->position, $mg->earthCell->position, { "Cell::ET" => 1 } )
        );
    }

    my $jsonMapData = JSON->new->pretty(1)->encode( $map->serialize() );

    my $fileName = sha256_hex( $jsonMapData );
    my $filePath = join("/", $self->gameMapStorePath, $fileName);

    my $fh = IO::File->new( $filePath, "w" );

    print $fh $jsonMapData;

    $fh->close();

    return ($fileName, $mg);
}

sub storeNewSession {
    my ($self, $args) = @_;

    my $sessionData = {
            mapHash     => $args->{mapHash},
            position    => $args->{position},
            hasTreasure => 0,
            movesCount  => 0,
        };

    my $sessionID = gettimeofday();

    $self->storeSession($sessionID, $sessionData);

    return ($sessionID);
}

sub storeSession {
    my ($self, $sessionID, $sessionData) = @_;

    my $jsonSessionData = JSON->new->pretty(1)->encode( $sessionData );

    my $filePath = join("/", $self->sessionStorePath, $sessionID);

    my $fh = IO::File->new( $filePath, "w" );

    print $fh $jsonSessionData;

    $fh->close();
}

sub resetSession {
    my ($self, $sessionID) = @_;

    my $sessionData = $self->restoreSession($sessionID);
    my $map         = $self->restoreMap($args->{mapHash});

    $sessionData->{position}    = $map->earthCellPosition;
    $sessionData->{hasTreasure} = 0;
    $sessionData->{movesCount}  = 0;

    $self->storeSession($sessionID, $sessionData);
}

sub setSessionNewMap {
    my ($self, $sessionID, $args) = @_;

    my $sessionData = $self->restoreSession($sessionID);

    my ($mapHash, $mapGenerator) = $self->storeNewMap($args);

    $sessionData->{position}    = $map$mapGenerator->earthCell->position;
    $sessionData->{hasTreasure} = 0;
    $sessionData->{movesCount}  = 0;

    $self->storeSession($sessionID, $sessionData);

    return $sessionID;
}

sub restoreSession {
    my ($self, $sessionID) = @_;

    my $filePath = join("/", $self->sessionStorePath, $sessionID);

    my $fh = IO::File->new( $filePath, "r" );

    my $sessionData = JSON->new->decode( join("", <$fh>) );

    $fh->close();

    return ($sessionData);
}

sub restoreMap {
    my ($self, $mapHash) = @_;

    my $filePath = join("/", $self->gameMapStorePath, $mapHash);

    my $fh = IO::File->new( $filePath, "r" );

    my $mapData = JSON->new->decode( join("", <$fh>) );

    $fh->close();

    my $map = Map->new({ width => $mapData->{width}, height => $mapData->{height} });

    $map->restore( $mapData );

    return ($map);
}

sub restoreSessionMap {
    my ($self, $sessionID) = @_;

    my $sessionData = $self->restoreSession($sessionID);

    return $self->restoreMap( $sessionData->{mapHash} );
}

1;