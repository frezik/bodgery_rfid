#!/usr/bin/perl
#
# Check if Open Shop switch is toggled. If so, send Open Shop REST call.
#
use v5.14;
use warnings;
use Device::WebIO::RaspberryPi;
use LWP::UserAgent;

my $POST_URL = 'https://app.tyrion.thebodgery.org/shop_open/';
my $INPUT_PIN = 23;
#my $CHECK_TIME_SEC = 30;
my $CHECK_TIME_SEC = 1;


sub send_open
{
    my ($value) = @_;

    my $url = $POST_URL . ($value ? '1' : '0');
    say "Sending URL: $url";

#    my $ua = LWP::UserAgent->new;
#    my $response = $ua->post( $POST_URL );
#
#    if(! $response->is_success ) {
#        say "Invalid response to '$POST_URL': " . $response->status_line;
#    }

    return 1;
}


my $rpi = Device::WebIO::RaspberryPi->new;
$rpi->set_as_input( $INPUT_PIN );
say "Ready . . . ";

while(1) {
    my $in = $rpi->input_pin( $INPUT_PIN );
    say "Got open value: $in";
    #send_open( $in );
    sleep $CHECK_TIME_SEC;
}
