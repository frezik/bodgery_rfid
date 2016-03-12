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
use Test::More;
use v5.14;
use Test::More;
use Test::Mojo;
use lib 't/lib';
use TestDB;
use Sereal::Decoder 'decode_sereal';

use FindBin;
require "$FindBin::Bin/../app.pl";
my $test_dbh = TestDB->get_test_dbh;
set_dbh( $test_dbh );
set_liability_dbh( $test_dbh );

my $t = Test::Mojo->new;
$t->get_ok( '/secure/search_liability/foo', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "" );

my $dbh = get_liability_dbh();
my $sth = $dbh->prepare_cached( 'INSERT INTO liability_waivers'
    . ' (full_name, check1, check2, check3, check4, addr, city, state, zip, phone'
    . ', email, emergency_contact_name, emergency_contact_phone, heard_from, signature)'
    . ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
) or die "Can't prepare statement: " . $dbh->errstr;
$sth->execute( 'Foo Name', 1, 1, 1, 1, 'foo', 'bar', 'baz', '11111', '15555556666',
    'foo@bar.com', 'baz', '15555557777', 'somewhere', '' )
    or die "Can't execute statement: " . $sth->errstr;
$sth->finish;

$t->get_ok( '/secure/search_liability/foo', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_like(
        qr/\AFoo Name,foo,bar,baz,11111,15555556666,foo\@bar.com,baz,15555557777,/ );

done_testing();
