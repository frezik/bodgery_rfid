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
use Mojolicious::Lite;


my $FIND_TAG_SQL = q{
    SELECT id, active FROM bodgery_rfid WHERE rfid = ?
};
my $INSERT_TAG_SQL = q{
    INSERT INTO bodgery_rfid (rfid, full_name, active) 
        VALUES (?, ?, 1)
};
my $DEACTIVATE_TAG_SQL = q{
    UPDATE bodgery_rfid SET active = 0 WHERE rfid = ?
};
my $REACTIVATE_TAG_SQL = q{
    UPDATE bodgery_rfid SET active = 1 WHERE rfid = ?
};
my $INSERT_ENTRY_TIME_SQL = q{
    INSERT INTO entry_log (rfid, is_active_tag, is_found_tag) VALUES (?, ?, ?)
};

get '/check_tag/:tag' => sub {
    my ($c) = @_;
    my $tag = $c->param( 'tag' );

    my $dbh = get_dbh();
    my $sth = $dbh->prepare_cached( $FIND_TAG_SQL )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( $tag )
        or die "Can't execute statement: " . $sth->errstr;

    my @row = $sth->fetchrow_array;
    my ($text, $code) = ('', 200);
    if( @row ) {
        my ($id, $active) = @row;
        if( $active ) {
            log_entry_time( $tag, 1, 1 );
        }
        else {
            $text = "Tag $tag is not active";
            $code = 403;
            log_entry_time( $tag, 0, 1 );
        }
    }
    else {
        $text = "Tag $tag was not found";
        $code = 404;
        log_entry_time( $tag, 0, 0 );
    }

    $sth->finish;
    $c->res->code( $code );
    $c->render( text => $text );
};

put '/secure/new_tag/:tag/:full_name' => sub {
    my ($c)       = @_;
    my $tag       = $c->param( 'tag' );
    my $full_name = $c->param( 'full_name' );

    my $dbh = get_dbh();
    $dbh->do( $INSERT_TAG_SQL, {}, $tag, $full_name )
        or die "Can't do new tag statement: " . $dbh->errstr;

    $c->res->code( 201 );
    $c->render( text => '' );
};

post '/secure/deactivate_tag/:tag' => sub {
    my ($c) = @_;
    my $tag = $c->param( 'tag' );

    my $dbh = get_dbh();
    $dbh->do( $DEACTIVATE_TAG_SQL, {}, $tag )
        or die "Can't do deactivate statement: " . $dbh->errstr;

    $c->res->code( 200 );
    $c->render( text => '' );
};

post '/secure/reactivate_tag/:tag' => sub {
    my ($c) = @_;
    my $tag = $c->param( 'tag' );

    my $dbh = get_dbh();
    $dbh->do( $REACTIVATE_TAG_SQL, {}, $tag )
        or die "Can't do reactivate statement: " . $dbh->errstr;

    $c->res->code( 200 );
    $c->render( text => '' );
};


{
    my $dbh;
    sub get_dbh
    {
        return $dbh if defined $dbh;
        # TODO make database connection
    }

    sub set_dbh
    {
        my ($in_dbh) = @_;
        $dbh = $in_dbh;
        return 1;
    }
}

sub log_entry_time
{
    my ($tag, $is_active_tag, $is_found_tag) = @_;
    my $dbh = get_dbh();
    $dbh->do( $INSERT_ENTRY_TIME_SQL, {}, $tag, $is_active_tag, $is_found_tag )
        or die "Can't do statement: " . $dbh->errstr;
    return 1;
}

app->start;
