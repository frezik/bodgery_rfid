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
use Test::More;
use Test::Mojo;
use lib 't/lib';
use TestDB;

use FindBin;
require "$FindBin::Bin/../app.pl";
set_dbh( TestDB->get_test_dbh );


my $t = Test::Mojo->new;
$t->get_ok( '/check_tag/1234' )
    ->status_is( '404' ); # Tag does not yet exist

$t->put_ok( '/secure/new_tag/1234/foo' )
    ->status_is( '201' ); # Tag added

$t->get_ok( '/check_tag/1234' )
    ->status_is( '200' ); # Tag now exists and is active

$t->post_ok( '/secure/deactivate_tag/1234' )
    ->status_is( '200' ); # Tag deactivated

$t->get_ok( '/check_tag/1234' )
    ->status_is( '403' ); # Tag exists, but no longer active

$t->post_ok( '/secure/reactivate_tag/1234' )
    ->status_is( '200' ); # Tag reactivated

$t->get_ok( '/check_tag/1234' )
    ->status_is( '200' ); # Tag now exists and is active

$t->get_ok( '/secure/search_tags', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "1234,foo,1\n" );
$t->get_ok( '/secure/search_tags?name=foo', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "1234,foo,1\n" );
$t->get_ok( '/secure/search_tags?name=bar', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "" );
$t->get_ok( '/secure/search_tags?name=Fo', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "1234,foo,1\n" );
$t->get_ok( '/secure/search_tags?tag=1234', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "1234,foo,1\n" );
$t->get_ok( '/secure/search_tags?tag=3456', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "" );

my $date_reg = qr/[\d\-: ]+/;
$t->get_ok( '/secure/search_entry_log', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_like( qr/\A
        1234,$date_reg,0,0 \n
        1234,$date_reg,1,1 \n
        1234,$date_reg,0,1 \n
        1234,$date_reg,1,1 \n
    /msx );
$t->get_ok( '/secure/search_entry_log?tag=3456', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_is( "" );
$t->get_ok( '/secure/search_entry_log?tag=1234', {Accept => 'text/plain'} )
    ->status_is( '200' )
    ->content_like( qr/\A
        1234,$date_reg,0,0 \n
        1234,$date_reg,1,1 \n
        1234,$date_reg,0,1 \n
        1234,$date_reg,1,1 \n
    /mx );

done_testing();
