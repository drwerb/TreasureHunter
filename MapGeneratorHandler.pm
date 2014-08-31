package MapGeneratorHandler;

use JSON;
use Data::Dumper;

use MapGenerator;

use Apache2::Const -compile => qw(OK);
#use Apache2::Request;

sub handler {
    my $r = shift;
    #my $req = Apache2::Request->new($r);

    my $args = parseParams( $r->args );

    my $Action = $args->{Action};

    if ( $Action eq 'simplePrint' ) {
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
    elsif ( $Action eq 'json' ) {
        my $mg = initMapGenerator($args);

        $map = $mg->generateMap();

        my $mapData = $map->serialize();

        $mapData->{ pathEarthTreasure }->{allCells} = [
                map {
                    $map->getPositionKey($_)
                } $map->shortestPathBetweenCells( $mg->earthCell->position, $mg->treasureCell->position)
            ];

        $mapData->{ pathEarthTreasure }->{stayOnCells} = [
                map {
                    $map->getPositionKey($_)
                } $map->shortestPathBetweenCells(
                            $mg->earthCell->position,
                            $mg->treasureCell->position,
                            { stayOnCellOnly => 1 },
                        )
        ];

        $mapData->{ pathMoonTreasure }->{allCells} = [
                map {
                    $map->getPositionKey($_)
                } $map->shortestPathBetweenCells( $mg->moonCell->position, $mg->treasureCell->position)
            ];

        $mapData->{ pathMoonTreasure }->{stayOnCells} = [
                map {
                    $map->getPositionKey($_)
                } $map->shortestPathBetweenCells(
                            $mg->moonCell->position,
                            $mg->treasureCell->position,
                            { stayOnCellOnly => 1 },
                        )
            ];

        $mapData->{ pathTreasureEarth }->{allCells} = [
                map {
                    $map->getPositionKey($_)
                } $map->shortestPathBetweenCells(
                                                    $mg->treasureCell->position,
                                                    $mg->earthCell->position,
                                                    {
                                                        excludedTypes => { "Cell::ET" => 1 },
                                                    }
                                                )
            ];

        $mapData->{ pathTreasureEarth }->{stayOnCells} = [
                map {
                    $map->getPositionKey($_)
                } $map->shortestPathBetweenCells(
                                                    $mg->treasureCell->position,
                                                    $mg->earthCell->position,
                                                    {
                                                        excludedTypes  => { "Cell::ET" => 1 },
                                                        stayOnCellOnly => 1,
                                                    }
                                                )
            ];

        my $json = JSON->new()->pretty(1);

        print $json->encode( $mapData );
    }

    return OK;
}

sub parseParams {
    my ($argsStr) = @_;

    chomp($argsStr);
    my %args = map { warn $_; split("=", $_) } split("&", $argsStr);

    return \%args;
}

sub initMapGenerator {
    my ($args) = @_;

    my $width  = $args->{width} || "";
    my $height = $args->{height} || "";

    $width = 5  if ( $width  !~ /^\d+$/ );
    $height = 5 if ( $height !~ /^\d+$/ );

    $mg = MapGenerator->new({ mapWidth => $width, mapHeight => $height });

    return $mg; 
}

1;