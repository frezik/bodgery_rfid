#!perl
# Copyright (c) 2018  Timm Murray
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
use Cpanel::JSON::XS ();
use Mojolicious::Plugin::CHI;
use CHI;
use Cache::FastMmap;
use SQL::Functional;

use constant DB_NAME     => 'bodgery_rfid';
use constant DB_USERNAME => '';
use constant DB_PASSWORD => '';

use constant DB_GUEST_NAME => 'bodgery_liability';
use constant DB_GUEST_USERNAME => '';
use constant DB_GUEST_PASSWORD => '';

use constant SEREAL_COMPRESS       => SRL_SNAPPY;
use constant SEREAL_DEDUPE_STRINGS => 1;

use constant SHOP_OPEN_KEY => 'shop_open';

use constant DOORBOT_HOST => 'pi@10.0.0.14';
use constant DOORBOT_SSH_KEY => 'doorbot_key.rsa';
use constant DOORBOT_OPEN_COMMAND => '/home/pi/bodgery_rfid/manual_open.sh';



my $FIND_TAG_SQL = q{
    SELECT id, active FROM members WHERE rfid = ?
};
my $INSERT_ENTRY_TIME_SQL = q{
    INSERT INTO entry_log (rfid, is_active_tag, is_found_tag) VALUES (?, ?, ?)
};
my $INSERT_ENTRY_TIME_LOCATION_SQL = q{
    INSERT INTO entry_log (rfid, is_active_tag, is_found_tag, location)
        VALUES (?, ?, ?, (
            SELECT id FROM locations WHERE name = ? LIMIT 1
        ))
};
my $INSERT_MEMBER_COST_SQL = q{
    INSERT INTO member_costs (member_id, cost_bucket_id, qty) VALUES (
        (SELECT DISTINCT id FROM members WHERE rfid = ?)
    , ?, ?)
};
my $FIND_ENTRY_LOG_SQL = q{
    SELECT
        members.full_name
        ,entry_log.rfid
        ,entry_log.entry_time
        ,entry_log.is_active_tag
        ,entry_log.is_found_tag
        ,locations.name
    FROM entry_log
    LEFT OUTER JOIN members ON entry_log.rfid = members.rfid
    LEFT OUTER JOIN locations ON entry_log.location = locations.id
};
my $FIND_LIABILITY_SQL = q{
    SELECT full_name, addr, city, state, zip, phone, email,
        emergency_contact_name, emergency_contact_phone, created_date
        FROM liability_waivers
        WHERE lower(full_name) LIKE ?
};
my $DUMP_EMAILS_SQL = 'SELECT id, email FROM guest_signin'
    . ' WHERE is_mailing_list_exported = FALSE AND email is not null';
my $FIND_MEMBER_COST_SQL = q{
    SELECT bucket.name, bucket.cost, bucket.cost_per, member.paid_on
        FROM member_costs member, cost_buckets bucket
        WHERE member.cost_bucket_id = bucket.id 
            AND member.id = ?
};
my $UPDATE_BUCKET_PAID_SQL_CALLBACK = sub {
    'UPDATE member_costs SET paid_on = '
        . get_db_now_keyword()
        . ' WHERE id = ?';
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

get '/entry/:tag/#location' => sub {
    my ($c) = @_;
    my $tag = $c->param( 'tag' );
    my $location = $c->param( 'location' );

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
            log_entry_time( $tag, 1, 1, $location );
        }
        else {
            $text = "Tag $tag is not active";
            $code = 403;
            log_entry_time( $tag, 0, 1, $location );
        }
    }
    else {
        $text = "Tag $tag was not found";
        $code = 404;
        log_entry_time( $tag, 0, 0, $location );
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
    my ($sql, @params) = $sa->insert( 'members', {
        rfid      => $tag,
        active    => 1,
        full_name => $full_name,
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
        'members',
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
        'members',
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
        'members',
        [qw{ rfid full_name active }],
        {
            (defined $name
                ? (q{lower(full_name)}
                    => { 'like', lc($name) . '%' })
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
    my $offset = $c->param( 'offset' );
    my $limit  = $c->param( 'limit' );

    my $sql = $FIND_ENTRY_LOG_SQL;
    my @sql_params = ();
    if( defined $tag ) {
        $sql .= ' WHERE entry_log.rfid = ?';
        push @sql_params, $tag;
    }

    $sql .= ' ORDER BY entry_time DESC';

    if( defined $limit ) {
        $sql .= ' LIMIT ?';
        push @sql_params, $limit;
    }
    if( defined $offset ) {
        $sql .= ' OFFSET ?';
        push @sql_params, $offset;
    }


    my $dbh = get_dbh();
    my $sth = $dbh->prepare_cached( $sql )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( @sql_params )
        or die "Can't execute statement: " . $sth->errstr;

    my $out = '';
    while( my $row = $sth->fetchrow_arrayref ) {
        no warnings; # $full_name could be NULL, which is OK
        my ($full_name, $rfid, $entry_time, $is_active_tag,
            $is_found_tag, $location) = @$row;
        $out .= join( ",",
            $full_name,
            $rfid,
            $entry_time,
            $is_active_tag,
            $is_found_tag,
            $location
        ) . "\n";
    }
    $sth->finish;

    $c->render( text => $out );
};

get '/secure/dump_active_tags' => sub {
    my ($c) = @_;

    my $sa = SQL::Abstract->new;
    my ($sql, @sql_params) = $sa->select(
        'members',
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

    my $encoded = undef;
    my $format = undef;
    if( $c->req->headers->accept =~ m! application/json !x ) {
        my $json = get_json_encoder();
        $encoded = $json->encode( \%tags );
        $format = 'json';
    }
    else {
        # Default to Sereal
        my $sereal = get_sereal_encoder();
        $encoded = $sereal->encode( \%tags );
        $format = 'sereal';
    }

    $c->render( data => $encoded, format => $format );
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

get '/secure/dump_email_signups' => sub {
    my ($c) = @_;
    my $dbh = get_liability_dbh();

    my $sth = $dbh->prepare_cached( $DUMP_EMAILS_SQL )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute()
        or die "Can't execute statement: " . $sth->errstr;
    
    my (@ids, @emails);
    while( my $row = $sth->fetchrow_hashref ) {
        push @ids => $row->{id};
        push @emails => $row->{email};
    }
    $sth->finish;

    $c->render( json => {
        ids => \@ids,
        emails => \@emails,
    });
};

post '/secure/mark_emails_signed_up' => sub {
    my ($c) = @_;
    my $dbh = get_liability_dbh();
    my @ids = @{ $c->every_param( 'id' ) };

    my $mark_emails_signed_up_sql = 'UPDATE guest_signin'
        . ' SET is_mailing_list_exported = TRUE'
        . ' WHERE id IN (' . join( ',', ('?') x scalar(@ids) ) . ')';

    my $sth = $dbh->prepare_cached( $mark_emails_signed_up_sql )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( @ids )
        or die "Can't execute statement: " . $sth->errstr;
    $sth->finish;

    $c->res->code( 200 );
    $c->render( text => scalar(@ids) . ' emails marked as joined' );
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

put '/secure/bucket/:name/:cost/:per' => sub {
    my ($c) = @_;
    my $name = $c->param( 'name' );
    my $cost = $c->param( 'cost' );
    my $per  = $c->param( 'per' );

    my $dbh = get_dbh();
    my $sa = SQL::Abstract->new;
    my ($sql, @params) = $sa->insert( 'cost_buckets', {
        name => $name,
        cost => $cost,
        cost_per => $per,
    });
    $dbh->do( $sql, {}, @params )
        or die "Can't do new tag statement: " . $dbh->errstr;

    my $id = $dbh->last_insert_id( undef, undef, undef, undef, {
        sequence => 'cost_bucket_seq',
    });

    $c->res->code( 201 );
    $c->render( text => $id );
};

get '/buckets' => sub {
    my ($c) = @_;

    my $sa = SQL::Abstract->new;
    my ($sql, @sql_params) = $sa->select(
        'cost_buckets',
        [qw{ id name cost cost_per }],
        {
        },
    );

    my $dbh = get_dbh();
    my $sth = $dbh->prepare_cached( $sql )
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute( @sql_params )
        or die "Couldn't execute statement: " . $sth->errstr;

    my @results = ();
    while( my $row = $sth->fetchrow_hashref ) {
        push @results, $row;
    }
    $sth->finish;

    $c->render( json => \@results );
};

put '/bucket' => sub {
    my ($c) = @_;
    my $rfid = $c->param( 'rfid' );
    my $bucket = $c->param( 'bucket' );
    my $qty = $c->param( 'qty' );

    my $dbh = get_dbh();
    $dbh->do( $INSERT_MEMBER_COST_SQL, {}, $rfid, $bucket, $qty )
        or die "Can't do statement: " . $dbh->errstr;

    my $id = $dbh->last_insert_id( undef, undef, undef, undef, {
        sequence => 'member_cost_seq',
    });

    $c->res->code( 201 );
    $c->render( text => $id );
};

get '/bucket/:id' => sub {
    my ($c) = @_;
    my $id = $c->param( 'id' );

    my $dbh = get_dbh();
    my $sth = $dbh->prepare_cached( $FIND_MEMBER_COST_SQL )
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute( $id )
        or die "Couldn't execute statement: " . $sth->errstr;

    my @results = ();
    while( my $row = $sth->fetchrow_hashref ) {
        $row->{is_paid} = defined $row->{paid_on} ? 1 : 0;
        push @results, $row;
    }
    $sth->finish;

    $c->render( json => \@results );
};

post '/bucket_paid/:id' => sub {
    my ($c) = @_;
    my $id = $c->param( 'id' );

    my $dbh = get_dbh();
    my $sql = $UPDATE_BUCKET_PAID_SQL_CALLBACK->();
    my $sth = $dbh->prepare_cached( $sql )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( $id )
        or die "Can't execute statement: " . $dbh->errstr;
    $sth->finish;

    $c->res->code( 200 );
    $c->render( text => '' );
};

get '/temp/:room_id' => sub {
    my ($c) = @_;
    my $room_id = $c->param( 'room_id' );
    my $dbh = get_dbh();

    my ($sql, @sql_params) = SELECT [qw{ centigrade }],
        FROM( 'temperatures' ),
        WHERE( match( 'room', '=', $room_id ) ),
        ORDER_BY( DESC 'date' ),
        LIMIT 1;
    my $sth = $dbh->prepare_cached( $sql )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( @sql_params )
        or die "Can't execute statement: " . $sth->errstr;

    my $temp = 0;
    while( my @row = $sth->fetchrow_array ) {
        ($temp) = @row;
    }
    $sth->finish;

    $c->render( text => $temp );
};

post '/temp/:room_id/:temp' => sub {
    my ($c) = @_;
    my $room_id = $c->param( 'room_id' );
    my $temp = $c->param( 'temp' );
    die "Room param should be a number\n" if $room_id !~ /\A\d+\z/;
    die "Temperature param should be a number\n" if $temp !~ /\A\d+\z/;

    my $dbh = get_dbh();
    my ($sql, @sql_params) = INSERT INTO 'temperatures',
        [ 'centigrade', 'room' ],
        VALUES [ $temp, $room_id ];
    my $sth = $dbh->prepare_cached( $sql )
        or die "Can't prepare statement: " . $dbh->errstr;
    $sth->execute( @sql_params )
        or die "Can't execute statement: " . $sth->errstr;
    $sth->finish;

    $c->render( text => $temp );
};

post '/secure/open_door' => sub {
    my ($c) =  @_;
    my $result = system( "ssh"
        . " -o IdentityFile=" . DOORBOT_SSH_KEY
        . " " . DOORBOT_HOST
        . " " . DOORBOT_OPEN_COMMAND
    );

    if( 0 == $result ) {
        $c->render( text => "Opened" );
    }
    else {
        $c->res->code( 500 );
        $c->render( text => "Error opening door" );
    }
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

    my $db_now_keyword = 'NOW()';
    sub set_db_now_keyword
    {
        my ($set) = @_;
        $db_now_keyword = $set;
    }

    sub get_db_now_keyword { $db_now_keyword }
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
    my ($tag, $is_active_tag, $is_found_tag, $location) = @_;
    my $dbh = get_dbh();

    if( defined $location && $location ne '' ) {
        $dbh->do(
            $INSERT_ENTRY_TIME_LOCATION_SQL,
            {},
            $tag,
            $is_active_tag,
            $is_found_tag,
            $location,
        ) or die "Can't do statement: " . $dbh->errstr;
    }
    else {
        $dbh->do(
            $INSERT_ENTRY_TIME_SQL,
            {},
            $tag,
            $is_active_tag,
            $is_found_tag,
        ) or die "Can't do statement: " . $dbh->errstr;
    }

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

{
    my $json;
    sub get_json_encoder
    {
        return $json if defined $json;

        $json = Cpanel::JSON::XS->new;
        $json->pretty( 0 );

        return $json;
    }
}

sub get_mojo_cache
{
    my ($c) = @_;
    return $c->chi;
}


app->types->type( 'plain' => 'text/plain' );
app->types->type( 'sereal' => 'application/sereal' );
app->types->type( 'json' => 'application/json' );
app->start;
