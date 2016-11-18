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
use Test::Mojo;
use lib 't/lib';
use TestDB;

use FindBin;
require "$FindBin::Bin/../app.pl";
set_dbh( TestDB->get_test_dbh );
set_db_now_keyword( q{datetime('now')} );

my $t = Test::Mojo->new;
$t->put_ok( '/secure/new_tag/1234' => form => {
    first_name => 'foo',
    last_name => 'bar',
    phone => '5551112222',
    email => 'foo@example.com',
    address => '1111 no where',
    member_type_id => 1,
})->status_is( '201' ); # Tag added

$t->put_ok( '/secure/bucket/laser/1000/hour' )
    ->status_is( '201' );
my $laser_id = $t->tx->res->body;

$t->get_ok( '/buckets' )
    ->status_is( '200' )
    ->content_type_is( 'application/json;charset=UTF-8' )
    ->json_is( '/0' => {
        id => $laser_id,
        name => 'laser',
        cost => '1000',
        cost_per => 'hour',
    });

$t->put_ok( '/bucket' => form => {
    rfid => 1234,
    bucket => $laser_id,
    qty => 1,
})->status_is( '201' );
my $bucket_id = $t->tx->res->body;

$t->get_ok( '/bucket/' . $bucket_id )
    ->status_is( '200' )
    ->content_type_is( 'application/json;charset=UTF-8' )
    ->json_is([{
        name => 'laser',
        cost => '1000',
        cost_per => 'hour',
        is_paid => 0,
        paid_on => undef,
    }]);

$t->post_ok( '/bucket_paid/' . $bucket_id )
    ->status_is( '200' );

$t->get_ok( '/bucket/' . $bucket_id )
    ->status_is( '200' )
    ->content_type_is( 'application/json;charset=UTF-8' )
    ->json_is( '/0/name' => 'laser' )
    ->json_is( '/0/is_paid' => 1 )
    ->json_like( '/0/paid_on' => qr/\A \d{4}-\d{2}-\d{2} /x );

done_testing();
