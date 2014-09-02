package GameServer;

use Mouse;

use Digest::SHA qw(sha256_hex);
use JSON;
use IO::File;
use Time::HiRes qw(gettimeofday);

use MapGenerator;

has 'mapGenerator' => ( is => 'rw', isa => 'MapGenerator' );
has 'gameMapStorePath' => ( is => 'ro', isa => 'Str', default => sub { $ENV{GameStore} || 'StoredData/GameMap' });
has 'sessionStorePath' => ( is => 'ro', isa => 'Str', default => sub { $ENV{GameStore} || 'StoredData/Session' });

sub startNewGame {
    my ($self, $args) = @_;

    my ($mapHash, $mapGenerator) = $self->storeNewMap($args);

    $self->storeNewSession({ mapHash => $mapHash, position => $mapGenerator->earthCell->position, });
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

    my $jsonSessionData = JSON->new->pretty(1)->encode(
        {
            mapHash     => $args->{mapHash},
            position    => $args->{position},
            hasTreasure => 0,
            movesCount  => 0,
        }
    );

    my $sessionID = gettimeofday();
    my $filePath = join("/", $self->sessionStorePath, $sessionID);

    my $fh = IO::File->new( $filePath, "w" );

    print $fh $jsonSessionData;

    $fh->close();

    return ($sessionID);
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

1;