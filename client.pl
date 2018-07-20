#!/usr/bin/perl
# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use v5.14;
use warnings;
use Getopt::Long ();
use Time::HiRes ();
use HiPi::Wiring qw( :wiring );
use Sereal::Decoder qw{};
use Fcntl qw( :flock );
use AnyEvent;
use AnyEvent::HTTP::LWP::UserAgent;
use Device::WebIO::RaspberryPi;

use constant DEBUG => 1;

use constant DOOR_OPEN_SEC        => 15;
# How long to hold the door for general open shop
use constant DOOR_HOLD_OPEN_SEC   => 60 * 60 * 1;

use constant {
    DONT_HOLD_DOOR => 0,
    MAYBE_HOLD_DOOR => 1,
    DO_HOLD_DOOR => 2,
};


my @SERVERS          = ('app.tyrion.thebodgery.org');
my $AUTH_REALM       = 'Required';
my $USERNAME         = '';
my $PASSWORD         = '';
my $LOCK_PIN         = 22;
my $UNLOCK_PIN       = 25;
my $OPEN_SWITCH      = 17;
my $UNLOCK_DURATION_SEC = 15;
my $SEREAL_FALLBACK_DB = '/var/tmp-ramdisk/rfid_fallback.db';
my $TMP_DIR            = '/var/tmp-ramdisk';
my $LED_PIN       = 4;
my $ARCHIVE = 'music.zip';
my $RICK_ROLL_CHANCE = 1 / 100;
my $PLAY_MUSIC_DELAY_SEC = 5;
Getopt::Long::GetOptions(
    'host=s'     => \@SERVERS,
    'username=s' => \$USERNAME,
    'password=s' => \$PASSWORD,
    'local-db=s' => \$SEREAL_FALLBACK_DB,
    'tmp-dir=s'  => \$TMP_DIR,
    'music-archive=s' => \$ARCHIVE,
    'rick-roll-chance=i' => \$RICK_ROLL_CHANCE,
    'delay-play-music=i' => \$PLAY_MUSIC_DELAY_SEC,
);
die "Need at least one --host\n" unless @SERVERS;


my $UA = AnyEvent::HTTP::LWP::UserAgent->new;
my @HOSTS;
foreach my $server (@SERVERS) {
    my $host = 'https://' . $server;
    push @HOSTS, $host;

    $UA->credentials( $host . ':443', $AUTH_REALM, $USERNAME, $PASSWORD );
}


my $HOLD_DOOR_OPEN = DONT_HOLD_DOOR;


sub get_tag_input_event
{
    my ($dev) = @_;
    return sub {
        my $tag = get_next_tag();
        my $result = check_tag({
            dev              => $dev,
            tag              => $tag,
            on_success       => \&do_success_action,
            on_inactive_tag  => \&do_inactive_tag_action,
            on_tag_not_found => \&do_tag_not_found_action,
            on_unknown_error => \&do_unknown_error_action,
            fallback_check   => \&check_tag_sereal,
        });
    };
}

sub get_next_tag
{
    my $next_tag = <>;
    chomp $next_tag;
    return $next_tag;
}

sub check_tag
{
    my (%args) = %{ +shift };
    my ($tag, $dev, $on_success, $on_inactive_tag, $on_tag_not_found,
        $on_unknown_error, $fallback_check) = @args{qw[
            tag dev on_success on_inactive_tag on_tag_not_found on_unknown_error
            fallback_check ]};

    # Check our local DB first, then fall back to remote servers
    if( check_tag_sereal( $tag ) ) {
        $on_success->( $dev );
    }

    my $start_time = [Time::HiRes::gettimeofday];

    my $host_index = 0;
    my $host = $HOSTS[$host_index];
    my $got_tag_fallback; $got_tag_fallback = sub {
        my $end_time   = [Time::HiRes::gettimeofday];
        my $duration   = Time::HiRes::tv_interval( $start_time, $end_time );

        my $r    = shift->recv;
        my $code = $r->code;

        say "Response time: " . sprintf( '%.0f ms', $duration * 1000);

        my $do_next_host = 0;
        if(! defined $code ) {
            $on_unknown_error->( $dev );
            $do_next_host = 1;
        }
        elsif( $code == 200 ) {
            $on_success->( $dev );
        }
        elsif( $code == 403 ) {
            $on_inactive_tag->( $dev );
        }
        elsif( $code == 404 ) {
            $on_tag_not_found->( $dev );
        }
        else {
            say "Unknown error from server, checking fallback DB";
            $do_next_host = 1;
        }

        if( $do_next_host ) {
            $host_index++;
            if( $host_index > $#HOSTS ) {
                # Out of hosts to check, so fail out
                $on_unknown_error->( $dev );
            }
            else {
                $host = $HOSTS[$host_index];
                $UA->get_async(
                    $host . '/check_tag/' . $tag
                )->cb( $got_tag_fallback );
            }
        }
    };
    $UA->get_async( $host . '/check_tag/' . $tag )->cb( $got_tag_fallback );

    return 1;
}

sub check_tag_sereal
{
    my ($tag) = @_;
    if(! -e $SEREAL_FALLBACK_DB ) {
        say "Local DB ($SEREAL_FALLBACK_DB) does not exist";
        return 0;
    }

    open( my $fh, '<', $SEREAL_FALLBACK_DB ) or do {
        say "Could not open local DB ($SEREAL_FALLBACK_DB): $!";
        return 0;
    };
    flock( $fh, LOCK_SH ) or say "Could not get a shared lock on local DB"
        . ", because [$!], checking it anyway . . .";

    # TODO Slurp with AnyEvent
    local $/ = undef;
    my $in = <$fh>;
    close $fh;

    my $decoder = get_sereal_decoder();
    $decoder->decode( $in, my $data );

    if( exists $data->{$tag} ) {
        say "Found tag in local DB";
        return 1;
    }
    else {
        say "Did not find tag in local DB";
        return 0;
    }
}

sub do_success_action
{
    my ($dev) = @_;
    say "Good RFID";
    unlock_door( $dev );

    if( MAYBE_HOLD_DOOR == $HOLD_DOOR_OPEN ) {
        # Button was pressed and then a scan happened.
        # Hold the door open much longer.
        $HOLD_DOOR_OPEN = DO_HOLD_DOOR;
        say "Opening shop to public, holding open for " . DOOR_HOLD_OPEN_SEC . " seconds";

        my $close_door_timer; $close_door_timer = AnyEvent->timer(
            after => DOOR_HOLD_OPEN_SEC,
            cb => sub { 
                lock_door( $dev );
                $HOLD_DOOR_OPEN = DONT_HOLD_DOOR;
                $close_door_timer;
            },
        );
    }
    elsif( DO_HOLD_DOOR == $HOLD_DOOR_OPEN ) {
        say "Shop is already open, so do nothing";
    }
    else {
        say "Locking door in $UNLOCK_DURATION_SEC seconds";
        my $close_door_timer; $close_door_timer = AnyEvent->timer(
            after => $UNLOCK_DURATION_SEC,
            cb => sub {
                lock_door( $dev );
                $HOLD_DOOR_OPEN = DONT_HOLD_DOOR; # Just in case
                $close_door_timer;
            },
        );
    }

    return 1;
}

sub do_inactive_tag_action
{
    say "Inactive RFID";
    return 1;
}

sub do_tag_not_found_action
{
    say "Did not find RFID";
    return 1;
}

sub do_unknown_error_action
{
    say "Unknown error";
    return 1;
}

{
    my $sereal;
    sub get_sereal_decoder
    {
        return $sereal if defined $sereal;

        $sereal = Sereal::Decoder->new({
        });

        return $sereal;
    }
}

sub get_open_status_callbacks
{
    my ($rpi) = @_;

    my $is_open = 0;
    my $input_callback = sub {
        $is_open = $rpi->input_pin( $OPEN_SWITCH );

        if( (DONT_HOLD_DOOR == $HOLD_DOOR_OPEN) && $is_open ) {
            say "Exit button pressed, holding open for " . DOOR_OPEN_SEC . " seconds";
            unlock_door( $rpi );
            $HOLD_DOOR_OPEN = MAYBE_HOLD_DOOR;
            my $input_timer; $input_timer = AnyEvent->timer(
                after => DOOR_OPEN_SEC,
                cb => sub { 
                    if( DONT_HOLD_DOOR == $HOLD_DOOR_OPEN ) {
                        # Shouldn't have gotten here, but lock door to be safe
                        lock_door( $rpi );
                        $HOLD_DOOR_OPEN = DONT_HOLD_DOOR;
                    }
                    elsif( MAYBE_HOLD_DOOR == $HOLD_DOOR_OPEN ) {
                        # No scan was seen during open period, so lock it again
                        say "No scan of tag, so lock door";
                        lock_door( $rpi );
                        $HOLD_DOOR_OPEN = DONT_HOLD_DOOR;
                    }
                    elsif( DO_HOLD_DOOR == $HOLD_DOOR_OPEN ) {
                        say "Tag was scanned, so keep door open";
                    }

                    $input_timer;
                },
            );
        }

        say "Open setting: $is_open" if DEBUG;
        return 1;
    };

    return $input_callback;
}

sub unlock_door
{
    my ($dev) = @_;
    say "Unlocking door";
    $dev->output_pin( $LED_PIN, 1 );
    $dev->output_pin( $LOCK_PIN, 1 );
    $dev->output_pin( $UNLOCK_PIN, 0 );
    return 1;
}

sub lock_door
{
    my ($dev) = @_;
    say "Locking door";
    $dev->output_pin( $LED_PIN, 0 );
    $dev->output_pin( $LOCK_PIN, 0 );
    $dev->output_pin( $UNLOCK_PIN, 1 );
    return 1;
}


{
    get_sereal_decoder(); # Pre-fetch the Sereal::Decode object

    my $rpi = Device::WebIO::RaspberryPi->new;
    $rpi->set_as_input( $OPEN_SWITCH );
    $rpi->set_as_output( $LED_PIN );
    $rpi->set_as_output( $LOCK_PIN );
    $rpi->set_as_output( $UNLOCK_PIN );

    # Set pullup resisters for lock/unlock pins.  Have to use 
    # Wiring Pi pin numbering for this
    HiPi::Wiring::pullUpDnControl( $_, WPI_PUD_DOWN )
        for 0, 3, 6;

    lock_door( $rpi );

    my $cv = AnyEvent->condvar;
    my $stdin_watcher = AnyEvent->io(
        fh   => \*STDIN,
        poll => 'r',
        cb   => get_tag_input_event( $rpi ),
    );

    my $input_callback = get_open_status_callbacks( $rpi );
    my $input_timer = AnyEvent->timer(
        after    => 1,
        interval => 0.10,
        cb       => $input_callback,
    );

    say "Ready for input";
    $cv->recv;
}
