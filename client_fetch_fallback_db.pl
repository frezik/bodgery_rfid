#!perl
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
use WWW::Mecahnize;
use Fcntl qw( :flock );

my $SEREAL_FALLBACK_DB = '/var/tmp-ramdisk/rfid_fallback.db';
my $SSL_CERT         = 'app.tyrion.crt';
my $HOST             = 'https://app.tyrion.thebodgery.org';
my $AUTH_REALM       = 'Authentication';
my $USERNAME         = 'varys';
my $PASSWORD         = '';
Getopt::Long::GetOptions(
    'ssl-cert=s' => \$SSL_CERT,
    'host=s'     => \$HOST,
    'username=s' => \$USERNAME,
    'password=s' => \$PASSWORD,
);


my $MECH = WWW::Mechanize->new(
    autocheck => 0,
);
$MECH->credentials( $USERNAME, $PASSWORD );
$MECH->ssl_opts(
    SSL_ca_file => $SSL_CERT,
);

my $response = $MECH->get( $HOST . '/secure/dump_active_tags' );
if( $response->is_success ) {
    open( my $fh, '<', $SEREAL_FALLBACK_DB )
        or die "Could not open fallback DB ($SEREAL_FALLBACK_DB): $!\n";
    flock( $fh, LOCK_EX )
        or die "Could not get a shared lock on fallback DB: $!\n";
    print $fh $response->content;
    close $fh;
}
