package GameEventsHandler;

use Data::Dumper;
use JSON;
use IO::Socket::UNIX;
use Carp;

use GameServer;

use Apache2::Const -compile => qw(OK);
#use Apache2::Request;

my $GAME_SOCKET_PATH = '/tmp/tf_game.sock';

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
    my ($data, $fh) = @_;
    $fh ||= STDOUT;
    print JSON->new->pretty(1)->encode($data);
}

sub startNewGame {
    my ($args) = @_;

    my $width  = $args->{width} || "";
    my $height = $args->{height} || "";

    my $sessionID = getSessionID($args);

    $width = 5  if ( $width  !~ /^\d+$/ );
    $height = 5 if ( $height !~ /^\d+$/ );


    return sendGameDaemonData({
            method => 'startNewGame',
            args   => [
                {
                    mapWidth  => $width,
                    mapHeight => $height,
                    sessionID => $sessionID,
                },
            ],
        });
}

sub resetGame {
    my ($args) = @_;

    my $sessionID = getSessionID($args);

    $width = 5  if ( $width  !~ /^\d+$/ );
    $height = 5 if ( $height !~ /^\d+$/ );

    sendGameDaemonData({
            method => 'resetSession',
            args   => [ { sessionID => $sessionID } ],
        });

    return $sessionID;
}

sub getSessionMapData {
    my ($args) = @_;

    my $sessionID = getSessionID($args);

    return sendGameDaemonData({
            method => 'restoreSessionMap',
            args   => [ $sessionID ],
        });
}

sub makeMove {
    my ($args) = @_;

    my $sessionID = getSessionID($args);

    my $move = $args->{move};

    return undef if ( $move !~ /^(up|down|left|right)$/ );

    return sendGameDaemonData({
            method => 'makeMove',
            args   => [ $sessionID, $move, $args ],
        });
}

sub sendGameDaemonData {
    my ($data) = @_;

    my $sock = IO::Socket::UNIX->new(
            Type => SOCK_STREAM,
            Peer => $GAME_SOCKET_PATH,
        );

    croak "Unable connect to socket: $GAME_SOCKET_PATH" if ( ! $sock );

    local $/ = '<term>';

    my $json = JSON->new;
    my $dataJSON = $json->encode($data);

    print $sock $dataJSON . $/;

    my $respJSON = <$sock>;

    close $sock;

    chomp($respJSON);

    my $response = $json->decode($respJSON);

    croak $response->{error} if ( ! $response->{success} );

    return $response->{result};
}

1;