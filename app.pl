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
use DBI;
use SQL::Abstract;
use Sereal::Encoder qw{
    SRL_SNAPPY
    SRL_ZLIB
};
use Mojolicious::Plugin::CHI;
use CHI;
use Cache::FastMmap;

use constant DB_NAME     => 'bodgery_rfid';
use constant DB_USERNAME => '';
use constant DB_PASSWORD => '';

use constant DB_GUEST_NAME => 'bodgery_liability';
use constant DB_GUEST_USERNAME => '';
use constant DB_GUEST_PASSWORD => '';

use constant SEREAL_COMPRESS       => SRL_SNAPPY;
use constant SEREAL_DEDUPE_STRINGS => 1;

use constant SHOP_OPEN_KEY => 'shop_open';



my $FIND_TAG_SQL = q{
    SELECT id, active FROM bodgery_rfid WHERE rfid = ?
};
my $INSERT_ENTRY_TIME_SQL = q{
    INSERT INTO entry_log (rfid, is_active_tag, is_found_tag) VALUES (?, ?, ?)
};
my $FIND_ENTRY_LOG_SQL = q{
    SELECT bodgery_rfid.full_name, entry_log.rfid, entry_log.entry_time,
            entry_log.is_active_tag, entry_log.is_found_tag
        FROM entry_log
        LEFT OUTER JOIN bodgery_rfid ON entry_log.rfid = bodgery_rfid.rfid
};
my $FIND_LIABILITY_SQL = q{
    SELECT full_name, addr, city, state, zip, phone, email,
        emergency_contact_name, emergency_contact_phone, created_date
        FROM liability_waivers
        WHERE lower(full_name) LIKE ?
};


plugin 'CHI' => {
    default => {
        driver => 'FastMmap',
        cache_size => '1m',
    },
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
    my $sa = SQL::Abstract->new;
    my ($sql, @params) = $sa->insert( 'bodgery_rfid', {
        rfid      => $tag,
        full_name => $full_name,
        active    => 1,
    });
    $dbh->do( $sql, {}, @params )
        or die "Can't do new tag statement: " . $dbh->errstr;

    $c->res->code( 201 );
    $c->render( text => '' );
};

post '/secure/deactivate_tag/:tag' => sub {
    my ($c) = @_;
    my $tag = $c->param( 'tag' );

    my $dbh = get_dbh();
    my $sa = SQL::Abstract->new;
    my ($sql, @sql_bind) = $sa->update(
        'bodgery_rfid',
        {
            active => 0,
        },
        {
            rfid => $tag,
        },
    );
    $dbh->do( $sql, {}, @sql_bind )
        or die "Can't do deactivate statement: " . $dbh->errstr;

    $c->res->code( 200 );
    $c->render( text => '' );
};

post '/secure/reactivate_tag/:tag' => sub {
    my ($c) = @_;
    my $tag = $c->param( 'tag' );

    my $dbh = get_dbh();
    my $sa = SQL::Abstract->new;
    my ($sql, @sql_bind) = $sa->update(
        'bodgery_rfid',
        {
            active => 1,
        },
        {
            rfid => $tag,
        },
    );
    $dbh->do( $sql, {}, @sql_bind )
        or die "Can't do deactivate statement: " . $dbh->errstr;

    $c->res->code( 200 );
    $c->render( text => '' );
};

get '/secure/search_tags' => sub {
    my ($c)    = @_;
    my $name   = $c->param( 'name' );
    my $tag    = $c->param( 'tag' );
    my $offset = $c->param( 'offset' ) // 0;
    my $limit  = $c->param( 'limit' )  // 0;

    my $sa = SQL::Abstract->new;
    my ($sql, @sql_params) = $sa->select(
        'bodgery_rfid',
        [qw{ rfid full_name active }],
        {
            (defined $name
                ? ('lower(full_name)' => { 'like', lc($name) . '%' })
                : ()),
            (defined $tag  ? ('rfid' => $tag) : ()),
        },
    );

    my $dbh = get_dbh();
    my $sth = $dbh->prepare_cached( $sql )
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute( @sql_params )
        or die "Couldn't execute statement: " . $sth->errstr;

    my @results = ();
    my $out = '';
    while( my $row = $sth->fetchrow_arrayref ) {
        my ($rfid, $full_name, $active) = @$row;
        $out .= "$rfid,$full_name,$active\n";
    }
    $sth->finish;

    $c->render( text => $out );
};

get '/secure/search_entry_log' => sub {
    my ($c)    = @_;
    my $tag    = $c->param( 'tag' );
    my $offset = $c->param( 'offset' ) // 0;
    my $limit  = $c->param( 'limit' )  // 0;

    my $sql = $FIND_ENTRY_LOG_SQL;
    my @sql_params = ();
    if( defined $tag ) {
        $sql .= ' WHERE entry_log.rfid = ?';
        push @sql_params, $tag;
    }

    $sql .= ' ORDER BY entry_time DESC';

    my $dbh = get_dbh();
    my $sth = $dbh->prepare_cached( $sql )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( @sql_params )
        or die "Can't execute statement: " . $sth->errstr;

    my $out = '';
    while( my $row = $sth->fetchrow_arrayref ) {
        no warnings; # $full_name could be NULL, which is OK
        my ($full_name, $rfid, $entry_time, $is_active_tag, $is_found_tag)
            = @$row;
        $out .= join( ",", $full_name, $rfid, $entry_time,
            $is_active_tag, $is_found_tag )
            . "\n";
    }
    $sth->finish;

    $c->render( text => $out );
};

get '/secure/dump_active_tags' => sub {
    my ($c) = @_;

    my $sa = SQL::Abstract->new;
    my ($sql, @sql_params) = $sa->select(
        'bodgery_rfid',
        [qw{ rfid }],
        {
            active => 1,
        },
    );

    my $dbh = get_dbh();
    my $sth = $dbh->prepare_cached( $sql )
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute( @sql_params )
        or die "Couldn't execute statement: " . $sth->errstr;

    my %tags;
    while( my ($rfid) = $sth->fetchrow_array ) {
        $tags{$rfid} = 1;
    }

    $sth->finish;

    my $sereal = get_sereal_encoder();
    my $encoded = $sereal->encode( \%tags );
    $c->render( data => $encoded, format => 'sereal' );
};

get '/secure/search_liability/:name' => sub {
    my ($c) = @_;
    my $search_name = $c->param( 'name' );

    my $sql = $FIND_LIABILITY_SQL;
    my @sql_params = ( $search_name . '%' );
    my $dbh = get_liability_dbh();
    my $sth = $dbh->prepare_cached( $sql )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( @sql_params )
        or die "Can't execute statement: " . $sth->errstr;

    my $out = '';
    while( my $row = $sth->fetchrow_arrayref ) {
        no warnings; # $full_name could be NULL, which is OK
        my ($full_name, $addr, $city, $state, $zip, $phone, $email,
            $emergency_name, $emergency_phone, $date) = @$row;
        $out .= join( ",", $full_name, $addr, $city, $state, $zip, $phone, $email,
            $emergency_name, $emergency_phone, $date )
            . "\n";
    }
    $sth->finish;

    $c->render( text => $out );
};

get '/shop_open' => sub {
    my ($c) = @_;
    my $cache = get_mojo_cache($c);
    my $out = $cache->get( SHOP_OPEN_KEY );
    $out = 0 unless defined $out;
    $c->render( text => $out );
};

post '/shop_open/:is_open' => sub {
    my ($c) = @_;
    my $is_open = $c->param( 'is_open' );
    my $cache = get_mojo_cache($c);
    $cache->set( SHOP_OPEN_KEY, $is_open );
    $c->render( text => '' );
};

{
    my $dbh;
    sub get_dbh
    {
        return $dbh if defined $dbh;
        $dbh = DBI->connect(
            'dbi:Pg:dbname=' . DB_NAME,
            DB_USERNAME,
            DB_PASSWORD,
            {
                AutoCommit => 1,
                RaiseError => 0,
            },
        ) or die "Could not connect to database: " . DBI->errstr;
        return $dbh;
    }

    sub set_dbh
    {
        my ($in_dbh) = @_;
        $dbh = $in_dbh;
        return 1;
    }
}

{
    my $liability_dbh;
    sub get_liability_dbh
    {
        return $liability_dbh if defined $liability_dbh;
        $liability_dbh = DBI->connect(
            'dbi:Pg:dbname=' . DB_GUEST_NAME,
            DB_GUEST_USERNAME,
            DB_GUEST_PASSWORD,
            {
                AutoCommit => 1,
                RaiseError => 0,
            },
        ) or die "Could not connect to database: " . DBI->errstr;
        return $liability_dbh;
    }

    sub set_liability_dbh
    {
        my ($in_dbh) = @_;
        $liability_dbh = $in_dbh;
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

{
    my $sereal;
    sub get_sereal_encoder
    {
        return $sereal if defined $sereal;

        $sereal = Sereal::Encoder->new({
            compress       => SEREAL_COMPRESS,
            dedupe_strings => SEREAL_DEDUPE_STRINGS,
        });

        return $sereal;
    }
}

sub get_mojo_cache
{
    my ($c) = @_;
    return $c->chi;
}


app->types->type( 'plain' => 'text/plain' );
app->types->type( 'sereal' => 'application/sereal' );
app->start;
