package GameEventsHandler;

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
        printAsJSON({
            sessionID => resetGame($args),
            msg       => "Game has been reseted. You are on Earth.",
        });
    }
    elsif ( $Action eq 'makeMove' ) {
        printAsJSON( makeMove($args) );
    }
    elsif ( $Action eq 'showMap' ) {
        printAsJSON( getSessionMapData($args) );
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

sub resetGame {
    my ($args) = @_;

    my $sessionID = getSessionID($args);

    $width = 5  if ( $width  !~ /^\d+$/ );
    $height = 5 if ( $height !~ /^\d+$/ );

    my $gs = GameServer->new();

    $gs->resetSession({
            sessionID => $sessionID,
        });

    return $sessionID;
}

sub getSessionMapData {
    my ($args) = @_;

    my $sessionID = getSessionID($args);

    my $gs = GameServer->new();

    return $gs->restoreSessionMap($sessionID);
}

sub makeMove {
    my ($args) = @_;

    my $sessionID = getSessionID($args);

    my $move = $args->{move};

    return undef if ( $move !~ /^(up|down|left|right)$/ );

    my $gs = GameServer->new();

    return $gs->makeMove($sessionID, $move, $args);
}

1;