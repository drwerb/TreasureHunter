package GameServer;

use Mouse;

use Digest::SHA qw(sha256_hex);
use JSON;
use IO::File;
#use Cache::FileCache;

use MapGenerator;
use GameSession;

has 'sessionCache' => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
#has 'sessionCache' => ( is => 'ro', isa => 'Cache::FileCache', default => sub { Cache::FileCache->new({ namespace => 'gameCache', default_expires_in => 60 }) } );

has 'gameMapStorePath' => ( is => 'ro', isa => 'Str', default => sub { ( $ENV{GameStore} ? $ENV{GameStore} : '.' ) . 'StoredData/GameMap' });

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

    my ($mg, $map);

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

    warn "File did't open $filePath" if ! $fh;

    print $fh $jsonMapData;

    $fh->close();

    return ($fileName, $mg);
}

sub storeNewSession {
    my ($self, $args) = @_;

    my $session = GameSession->new();

    $session->sessionData({
            mapHash     => $args->{mapHash},
            position    => $args->{position},
            hasTreasure => 0,
            movesCount  => 0,
        });

    $session->store();

    $self->sessionCache->{$session->ID} = $session;

    return ($session->ID);
}

sub resetSession {
    my ($self, $sessionID) = @_;

    my $session     = $self->getSession($sessionID);

    my $sessionData = $session->sessionData();

    my $map         = $self->restoreMap($sessionData->{mapHash});

    $sessionData->{position}    = $map->earthCellPosition;
    $sessionData->{hasTreasure} = 0;
    $sessionData->{movesCount}  = 0;

    $session->store();
}

sub setSessionNewMap {
    my ($self, $sessionID, $args) = @_;

    my $session = $self->getSession($sessionID);

    my ($mapHash, $mapGenerator) = $self->storeNewMap($args);

    my $sessionData = $session->sessionData();

    $sessionData->{position}    = $mapGenerator->earthCell->position;
    $sessionData->{hasTreasure} = 0;
    $sessionData->{movesCount}  = 0;

    $session->store();

    return $sessionID;
}

sub getSession {
    my ($self, $sessionID) = @_;

    my $session = $self->sessionCache->{$sessionID};

    if ( ! $session ) {
        $session = GameSession->new({ ID => $sessionID });

        $session->restore();

        $self->sessionCache->{$sessionID} = $session;
    }

    return $session;
}

sub restoreMap {
    my ($self, $mapHash, $args) = @_;

    my $filePath = join("/", $self->gameMapStorePath, $mapHash);

    my $fh = IO::File->new( $filePath, "r" );

    my $mapData = JSON->new->decode( join("", <$fh>) );

    $fh->close();

    return $mapData if ( $args->{rawData} );

    my $map = Map->new({ width => $mapData->{width}, height => $mapData->{height} });

    $map->restore( $mapData );

    return ($map);
}

sub restoreSessionMap {
    my ($self, $sessionID) = @_;

    my $sessionData = $self->getSession($sessionID)->sessionData;

    my $mapData = $self->restoreMap( $sessionData->{mapHash}, { rawData => 1 } );

    $mapData->{currentPosition} = $sessionData->{position};

    return $mapData;
}

sub makeMove {
    my ($self, $sessionID, $move, $args) = @_;

    my $result = {
        sessionID => $sessionID,
    };

    my $session     = $self->getSession($sessionID);
    my $sessionData = $session->sessionData;
    my $map         = $self->restoreMap($sessionData->{mapHash});

    my $currentCell = $map->getCellByPosition( $sessionData->{position} );

    my %moveDestMethodMap = (
            'up'    => 'upperNeighbor',
            'down'  => 'bottomNeighbor',
            'left'  => 'leftNeighbor',
            'right' => 'rightNeighbor',
        );

    my $method = $moveDestMethodMap{$move};

    my $stepOnCell = $map->$method($currentCell);

    if ( ! $stepOnCell ) {
        $result->{msg} = "Wall";
    }
    else {
        my $newPosition = $stepOnCell->onCellStep( { stepFromCell => $currentCell } );
        my $newCell     = $map->getCellByPosition( $newPosition );

        if ( ref($newCell) eq 'Cell::Earth' ) {
            $result->{msg}  = "Earth!";
            if ( $sessionData->{hasTreasure} ) {
                $result->{msg} .= " You has reached with treasure!";
                $result->{gameComplete} = 1;
            }
        }
        elsif ( ref($newCell) eq 'Cell::Moon' ) {
            if ( ref($stepOnCell) eq 'Cell::ET' ) {
                $result->{msg}  = "Extraterrastrial!";
                $result->{msg} .= " You have lost treasure :(";
                $sessionData->{hasTreasure} = 0;
            }
            else {
                $result->{msg} = "Moon!";
            }
        }
        elsif ( ref($newCell) eq 'Cell::Treasure' ) {
            $result->{msg} = "Treasure!";
            $sessionData->{hasTreasure} = 1;
        }
        elsif ( ref($newCell) eq 'Cell::Flow' ) {
            $result->{msg} = "Flow (+/-)" . $newCell->Force;
        }
        elsif ( ref($newCell) eq 'Cell::BlackHole' ) {
            $result->{msg} = "Black Hole!";
        }
        else {
            $result->{msg} = "Unknown";
        }

        $sessionData->{position} = $newPosition;

    }

    $sessionData->{movesCount}++;

    $result->{hasTreasure} = $sessionData->{hasTreasure};

    if ( $args->{isMapShown} ) {
        $result->{currentPosition} = $sessionData->{position};
    }

    #$session->sessionData( $sessionData );
    #$self->sessionCache->set($session->ID, $session);

    return $result;
}

__PACKAGE__->meta->make_immutable();

1;