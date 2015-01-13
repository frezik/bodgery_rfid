#!perl
# Copyright (c) 2014  Timm Murray
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
use WWW::Mechanize;
use Time::HiRes ();
use HiPi::Wiring qw( :wiring );
use Sereal::Decoder qw{};
use Fcntl qw( :flock );


my $SSL_CERT         = 'app.tyrion.crt';
my $HOST             = 'https://app.tyrion.thebodgery.org';
my $AUTH_REALM       = 'Authentication';
my $USERNAME         = '';
my $PASSWORD         = '';
my $PIEZO_PIN        = 18;
my $LOCK_PIN         = 4;
# Zelda Uncovered Secret Music
# Notes: G2 F2# D2# A2 G# E2 G2# C3 
#my $GOOD_NOTES       = [qw{ 1568 1480 1245 880 831 1319 1661 2093 }];
my $GOOD_NOTES       = [ 100, 110, 120 ];
my $BAD_NOTES        = [ 60 ];
my $NOTE_DURATION_MS = 500;
my $UNLOCK_DURATION_MS = 10_000;
my $TEST               = 0;
my $SEREAL_FALLBACK_DB = '/var/tmp-ramdisk/rfid_fallback.db';
Getopt::Long::GetOptions(
    'ssl-cert=s' => \$SSL_CERT,
    'host=s'     => \$HOST,
    'username=s' => \$USERNAME,
    'password=s' => \$PASSWORD,
    'test'       => \$TEST,
);

my $MECH = WWW::Mechanize->new(
    autocheck => 0,
);
$MECH->credentials( $USERNAME, $PASSWORD );
$MECH->ssl_opts(
    SSL_ca_file => $SSL_CERT,
);

HiPi::Wiring::wiringPiSetupGpio();
HiPi::Wiring::pinMode( $LOCK_PIN, WPI_OUTPUT );
HiPi::Wiring::pinMode( $PIEZO_PIN, WPI_PWM_OUTPUT );
HiPi::Wiring::pwmSetMode( WPI_PWM_MODE_MS );



sub get_next_tag
{
    my $next_tag = <>;
    chomp $next_tag;
    return $next_tag;
}

sub check_tag
{
    my ($tag) = @_;
    
    my $result = $MECH->get( $HOST . '/check_tag/' . $tag );
    my $code   = $result->code;

    my $return = $code == 200 ? 1 :
        $code == 403 ? -1 :
        $code == 404 ? -2 :
        undef;

    if(! defined $return ) {
        say "Unknown error from server, checking fallback DB";
        if( check_tag_sereal_fallback( $tag ) ) {
            $return = 1;
        }
    }

    return $return;
}

sub check_tag_sereal_fallback
{
    my ($tag) = @_;
    if(! -e $SEREAL_FALLBACK_DB ) {
        say "Fallback DB ($SEREAL_FALLBACK_DB) does not exist";
        return 0;
    }

    open( my $fh, '<', $SEREAL_FALLBACK_DB ) or do {
        say "Could not open fallback DB ($SEREAL_FALLBACK_DB): $!";
        return 0;
    };
    flock( $fh, LOCK_SH ) or say "Could not get a shared lock on fallback DB"
        . ", because [$!], checking it anyway . . .";
    local $/ = undef;
    my $in = <$fh>;
    close $fh;

    my $decoder = get_sereal_decoder();
    $decoder->decode( $in, my $data );

    if( exists $data->{$tag} ) {
        say "Found tag in fallback DB";
        return 1;
    }
    else {
        say "Did not find tag in fallback DB";
        return 0;
    }
}


sub play_notes
{
    my (@notes) = @_;
    foreach my $freq (@notes) {
        # Taken from http://www.raspberrypi.org/forums/viewtopic.php?f=44&t=20559
        my $period = sprintf '%.0f', 600000/440/2**(($freq-69)/12);
        HiPi::Wiring::pwmSetRange( $period );
        HiPi::Wiring::pwmWrite( $PIEZO_PIN, $period / 2 );
        HiPi::Wiring::delay( $NOTE_DURATION_MS );
    }

    HiPi::Wiring::pwmWrite( $PIEZO_PIN, 0 );
}

sub do_success_action
{
    say "Good RFID";
    return 1 if $TEST;
    HiPi::Wiring::digitalWrite( $LOCK_PIN, WPI_HIGH );

    my $start_time = Time::HiRes::time();
    my $expect_end_time = $start_time + ($UNLOCK_DURATION_MS / 1000);

    my $now = $start_time;
    while( $now <= $expect_end_time ) {
        play_notes( @$GOOD_NOTES );
        $now = Time::HiRes::time();
    }

    HiPi::Wiring::digitalWrite( $LOCK_PIN, WPI_LOW );
    return 1;
}

sub do_inactive_tag_action
{
    say "Inactive RFID";
    return 1 if $TEST;
    play_notes( @$BAD_NOTES );
    return 1;
}

sub do_tag_not_found_action
{
    say "Did not find RFID";
    return 1 if $TEST;
    play_notes( @$BAD_NOTES );
    return 1;
}

sub do_unknown_error_action
{
    say "Unknown error";
    return 1 if $TEST;
    play_notes( @$BAD_NOTES );
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


{
    get_sereal_decoder(); # Pre-fetch the Sereal::Decode object

    say "Ready for input";

    while(1) {
        my $tag = get_next_tag();
        my $result = check_tag( $tag );

        if(! defined $result ) {
            do_unknown_error_action();
        }
        elsif( $result > 0 ) {
            do_success_action();
        }
        elsif( $result == -1 ) {
            do_inactive_tag_action();
        }
        elsif( $result == -2 ) {
            do_tag_not_found_action();
        }
        else {
            do_unknown_error_action();
        }
    }
}
