#!/usr/bin/perl

use strict;
use warnings;

use Proc::Daemon;
use IO::Socket::UNIX;
use JSON;

use Devel::Size qw(total_size);

use lib('/home/vvi/work/git_projects/TreasureHunterServer');

$ENV{GameStore} = '/home/vvi/work/git_projects/TreasureHunterServer/';

use GameServer;

Proc::Daemon::Init;

my $socketpath = '/tmp/tf_game.sock';
my $logpath    = '/tmp/tf_game.log';

my $_debug = 0;

unlink($socketpath) if ( -S $socketpath );

my $sock = IO::Socket::UNIX->new(
        Type   => SOCK_STREAM,
        Local  => $socketpath,
        Listen => 1,
    );

$SIG{TERM} = sub { $sock->close };

my $gameServer = GameServer->new();
my $json = JSON->new();

logPrint($gameServer->gameMapStorePath);

CONN_LOOP: while (1) {
    logPrint("Waiting for connection...\n") if $_debug;

    my $connection = $sock->accept;

    $connection->autoflush(1);

    local $/ = '<term>';

    while ( my $data = <$connection> ) {
        last CONN_LOOP if ( $data =~ /^stop$/ );

        chomp($data);

        logPrint("Accepted data: " . $data) if $_debug;

        my $response;

        eval {
            my $dataHash = $json->decode($data);

            my $method = $dataHash->{method};
            my @args   = @{ $dataHash->{args} };

            my $resultData = $gameServer->$method(@args);

            $response = $json->encode( {
                    success => 1,
                    result  => $resultData,
                } );

            logPrint("Response data: " . $response) if $_debug;
        };

        if ( $@ ) {
            logPrint("ERROR: " . $@);
            $response = $json->encode({
                    success => 0,
                    error   => $@,
                });
        }

        print $connection $response . $/;
    }

    close $connection;

    logPrint("GameServer size: " . total_size($gameServer->sessionCache));
}

$sock->close;

sub logPrint {
    my ($msg) = @_;
    open my $fh, ">>", $logpath;
    print $fh $msg . "\n";
    close $fh;
}