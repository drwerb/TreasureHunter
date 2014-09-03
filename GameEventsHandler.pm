package MapGeneratorHandler;

use Data::Dumper;
use JSON;

use GameServer;

use Apache2::Const -compile => qw(OK);
#use Apache2::Request;

sub handler {
    my $r = shift;
    #my $req = Apache2::Request->new($r);

    my $args = parseParams( $r->args );

    my $Action = $args->{Action};

    if ( $Action eq 'startNewGame' ) {
        printAsJSON({
            sessionID => startNewGame($args),
            msg       => "New game started. You are on Earth.",
        });
    }
    elsif ( $Action eq 'resetGame' ) {
    }
    elsif ( $Action eq 'makeMove' ) {
    }
    elsif ( $Action eq 'showMap' ) {
    }

    return OK;
}

sub parseParams {
    my ($argsStr) = @_;

    chomp($argsStr);
    my %args = map { warn $_; split("=", $_) } split("&", $argsStr);

    return \%args;
}

sub getSessionID {
    my ($args) = @_;

    my $sessionID = $args->{sessionID} || "";

    $sessionID = undef if ( $sessionID !~ /^\d{16}$/ );

    return $sessionID;
}

sub printAsJSON {
    my ($data) = @_;
    print JSON->new->pretty(1)->encode($data);
}

sub startNewGame {
    my ($args) = @_;

    my $width  = $args->{width} || "";
    my $height = $args->{height} || "";

    my $sessionID = getSessionID($args);

    $width = 5  if ( $width  !~ /^\d+$/ );
    $height = 5 if ( $height !~ /^\d+$/ );

    my $gs = GameServer->new();

    return $gs->startNewGame({
            mapWidth  => $width,
            mapHeight => $height,
            sessionID => $sessionID,
        });
}


sub printMapDataJSON {
    my ($args) = @_;

    my $sessionID = getSessionID($args);

    my $gs = GameServer->new();

    my $mapData = $gs->restoreSessionMap($sessionID);

    printAsJSON( $mapData );
}

sub printMapDataText {
    my ($args) = @_;

    my $mg = initMapGenerator($args);

    $map = $mg->generateMap();

    printf "Width = %d\nHeight = %d\n\n", $map->width, $map->height;

    $map->printMap();

    if ( my @path = $map->shortestPathBetweenCells( $mg->earthCell->position, $mg->treasureCell->position) ) {
        printf "\nTreasure is reachable from Earth - %d steps\n\n", scalar(@path) - 1;
    } else {
        print "\nTreasure is not reachable from Earth\n\n";
    }

    if ( my @path = $map->shortestPathBetweenCells( $mg->moonCell->position, $mg->treasureCell->position) ) {
        printf "\nTreasure is reachable from Moon - %d steps\n\n", scalar(@path) - 1;
    } else {
        print "\nTreasure is not reachable from Moon\n\n";
    }

    if ( my @path = $map->shortestPathBetweenCells( $mg->treasureCell->position, $mg->earthCell->position, { "Cell::ET" => 1 } ) ) {
        printf "\nEarth is reachable with Treasure - %d steps\n\n", scalar(@path) - 1;
    } else {
        print "\nEarth is not reachable with Treasure\n\n";
    }
}

sub generateAndStoreNewGame {
    my ($args) = @_;

}

1;