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
use Test::More;
use v5.14;
use Test::Mojo;
use lib 't/lib';
use TestDB;
use Sereal::Decoder 'decode_sereal';

use FindBin;
require "$FindBin::Bin/../app.pl";
set_dbh( TestDB->get_test_dbh );


my $t = Test::Mojo->new;
note( "entry 1234, 0, 0" );
$t->get_ok( '/check_tag/1234' )
    ->status_is( '404' ); # Tag does not yet exist

$t->put_ok( '/secure/new_tag/1234/foo bar')->status_is( '201' ); # Tag added

sleep 1;
note( "entry 1234, 1, 1" );
$t->get_ok( '/check_tag/1234' )
    ->status_is( '200' ); # Tag now exists and is active

$t->post_ok( '/secure/deactivate_tag/1234' )
    ->status_is( '200' ); # Tag deactivated

sleep 1; # Ensures ordering
note( "entry 1234, 0, 1, woodshop.tablesaw" );
$t->get_ok( '/entry/1234/woodshop.tablesaw' )
    ->status_is( '403' ); # Tag exists, but no longer active

$t->post_ok( '/secure/reactivate_tag/1234' )
    ->status_is( '200' ); # Tag reactivated

sleep 1;
note( "entry 1234, 1, 1, laser.big" );
$t->get_ok( '/entry/1234/laser.big' )
    ->status_is( '200' ); # Tag now exists and is active

sleep 1;
note( "entry 1234, 1, 1, woodshop.door" );
$t->get_ok( '/entry/1234/woodshop.door' )
    ->status_is( '200' ); # Logged entry to the woodshop door

sleep 1;
note( "entry 1234, 1, 1" );
$t->get_ok( '/entry/1234/no.such.location' )
    ->status_is( '200' ); # Logged entry, but we don't know where

$t->get_ok( '/secure/search_tags', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "1234,foo bar,1\n" );
$t->get_ok( '/secure/search_tags?name=foo', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "1234,foo bar,1\n" );
$t->get_ok( '/secure/search_tags?name=bar', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "" );
$t->get_ok( '/secure/search_tags?name=Fo', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "1234,foo bar,1\n" );
$t->get_ok( '/secure/search_tags?tag=1234', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "1234,foo bar,1\n" );
$t->get_ok( '/secure/search_tags?tag=3456', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "" );

sleep 1;
note( "entry 1236, 0, 0, cleanroom.door" );
$t->get_ok( '/entry/1236/cleanroom.door' )
    ->status_is( '404' );

my $date_reg = qr/[\d\-: ]+/;
note( "Fetch complete log" );
$t->get_ok( '/secure/search_entry_log', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_like( qr/\A
        ,1236,$date_reg,0,0,cleanroom.door \n
        foo\sbar,1234,$date_reg,1,1, \n
        foo\sbar,1234,$date_reg,1,1,woodshop\.door \n
        foo\sbar,1234,$date_reg,1,1,laser.big \n
        foo\sbar,1234,$date_reg,0,1,woodshop.tablesaw \n
        foo\sbar,1234,$date_reg,1,1, \n
        foo\sbar,1234,$date_reg,0,0, \n
    /msx );
$t->get_ok( '/secure/search_entry_log?tag=3456', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "" );
note( "Fetch log for fob 1234" );
$t->get_ok( '/secure/search_entry_log?tag=1234', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_like( qr/\A
        foo\sbar,1234,$date_reg,1,1, \n
        foo\sbar,1234,$date_reg,1,1,woodshop\.door \n
        foo\sbar,1234,$date_reg,1,1,laser.big \n
        foo\sbar,1234,$date_reg,0,1,woodshop.tablesaw \n
        foo\sbar,1234,$date_reg,1,1, \n
        foo\sbar,1234,$date_reg,0,0, \n
    /mx );
note( "Fetch complete log, limit 2" );
$t->get_ok( '/secure/search_entry_log?limit=2', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_like( qr/\A
        ,1236,$date_reg,0,0,cleanroom.door \n
        foo\sbar,1234,$date_reg,1,1, \n
    \z/msx );
note( "Fetch complete log, limit 2, offset 2" );
$t->get_ok( '/secure/search_entry_log?limit=2&offset=2',
    {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_like( qr/\A
        foo\sbar,1234,$date_reg,1,1,woodshop\.door \n
        foo\sbar,1234,$date_reg,1,1,laser.big \n
    /msx );

$t->get_ok( '/secure/dump_active_tags' )
    ->header_is( 'Content-type' => 'application/sereal' );
my $dump_tx = $t->tx;
my $dump_response = $dump_tx->res;
cmp_ok( $dump_response->code, '==', 200, 'Fetched active tags' );
my $dump = decode_sereal( $dump_response->body );
is_deeply( $dump, {
    1234 => 1,
});

done_testing();
