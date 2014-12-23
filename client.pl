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


my $SSL_CERT   = 'app.tyrion.crt';
my $HOST       = 'app.tyrion.thebodgery.org';
my $AUTH_REALM = 'Authentication';
my $USERNAME   = '';
my $PASSWORD   = '';
Getopt::Long::GetOptions(
    'ssl-cert=s' => \$SSL_CERT,
    'host=s'     => \$HOST,
    'username=s' => \$USERNAME,
    'password=s' => \$PASSWORD,
);

my $MECH = WWW::Mechanize->new(
);
$MECH->credentials( $USERNAME, $PASSWORD );
$MECH->ssl_opts(
    SSL_ca_file => $SSL_CERT,
);


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
}


{
    while(1) {
        my $tag = get_next_tag();
        my $result = check_tag( $tag );
        say $result > 0 ? "Tag $tag OK" :
            $result == -1 ? "Tag $tag not active" :
            $result == -2 ? "Tag $tag not found"  :
            "Unknown tag error";
    }
}
