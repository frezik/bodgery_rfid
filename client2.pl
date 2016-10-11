#!perl
# Copyright (c) 2016  Timm Murray
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
use Sereal::Decoder qw{};
use Fcntl qw( :flock );
use HiPi::Wiring qw( :wiring );
use Device::PCD8544;
use Device::WebIO::RaspberryPi;
use Getopt::Long ();

use constant DEBUG => 1;

my $SSL_CERT = undef;
my $DOMAIN = 'app.tyrion.thebodgery.org';
my $AUTH_REALM = 'Required';
my $USERNAME = '';
my $PASSWORD = '';
my $SEREAL_FALLBACK_DB = '/var/tmp-ramdisk/rfid_fallback.db';
my $TMP_DIR = '/var/tmp-ramdisk';
my $UNLOCK_DURATION_SEC = 15;
my $LED_PIN = 4;
my $LOCK_PIN = 22;
my $UNLOCK_PIN = 25;
Getopt::Long::GetOptions(
    'ssl-cert=s'    => \$SSL_CERT,
    'host=s'        => \$DOMAIN,
    'username=s'    => \$USERNAME,
    'password=s'    => \$PASSWORD,
    'fallback-db=s' => \$SEREAL_FALLBACK_DB,
    'tmp-dir=s'     => \$TMP_DIR,
);

my $HOST = 'https://' . $DOMAIN;
my $UA = AnyEvent::HTTP::LWP::UserAgent->new;
$UA->credentials( $DOMAIN . ':443', $AUTH_REALM, $USERNAME, $PASSWORD );
$UA->ssl_opts(
    SSL_ca_file => $SSL_CERT,
) if defined $SSL_CERT;


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

sub check_tag_remote
{
    my ($tag) = @_;
    my $response = $UA->get( $HOST . '/check_tag/' . $tag );
    my $code = $response->code;

    my $is_valid = 0;
    if(! defined $code ) {
        say "Unkown error" if DEBUG;
    }
    elsif( $code == 200 ) {
        $is_valid = 1;
    }
    elsif( $code == 403 ) {
        say "Tag is inactive" if DEBUG;
    }
    elsif( $code == 404 ) {
        say "Tag is not found" if DEBUG;
    }
    else {
        say "Unknown error from server" if DEBUG;
    }

    return $is_valid;
}

sub check_tag
{
    my ($tag) = @_;

    my $is_valid = 0;
    my $do_log_remote = 0;
    if( check_tag_local( $tag ) ) {
        $is_valid = 1;
        $do_log_remote = 1;
    }
    elsif( check_tag_remote( $tag ) ) {
        $is_valid = 1;
    }

    return ($is_valid, $do_log_remote);
}

sub read_loop
{
    my ($rpi) = @_;

    while(1) {
        my $in = <>;
        chomp $in;

        my ($is_valid, $do_log_remote) = check_tag( $in );
        if( $is_valid ) {
            unlock_door( $rpi );
            sleep $UNLOCK_DURATION_SEC;
            lock_door( $rpi );
        }
        if( $do_log_remote ) {
            check_tag_remote( $tag );
        }
    }

    return;
}


{
    my $rpi = Device::WebIO::RaspberryPi->new;
    $rpi->set_as_output( $LED_PIN );
    $rpi->set_as_output( $LOCK_PIN );
    $rpi->set_as_output( $UNLOCK_PIN );

    # Set pullup resisters for lock/unlock pins.  Have to use 
    # Wiring Pi pin numbering for this
    HiPi::Wiring::pullUpDnControl( $_, WPI_PUD_DOWN )
        for 3, 6;

    lock_door( $rpi );
    read_loop( $rpi );
}
