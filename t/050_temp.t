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


our $CREATE_TEMP_TABLE = q{
    CREATE TABLE temperatures (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        centigrade INTEGER NOT NULL,
        room INTEGER NOT NULL,
        date DATETIME DEFAULT CURRENT_TIMESTAMP
    )
};


my $t = Test::Mojo->new;
$t->post_ok( '/temp/0/20' )
    ->status_is( 200 )
    ->content_is( '20' );
$t->get_ok( '/temp/0' )
    ->status_is( 200 )
    ->content_is( '20' );

$t->post_ok( '/temp/1/30' ) 
    ->status_is( 200 )
    ->content_is( '30' );
$t->get_ok( '/temp/1' )
    ->status_is( 200 )
    ->content_is( '30' );
$t->get_ok( '/temp/0' )
    ->status_is( 200 )
    ->content_is( '20' );

done_testing();
