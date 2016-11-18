package TestDB;
use v5.14;
use warnings;
use File::Temp 'tempfile';
use DBI;
use DBD::SQLite;

use constant TEST_MEMBER_TYPES_TABLE => q{
    CREATE TABLE member_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT NOT NULL UNIQUE
    );
};
use constant TEST_MEMBER_TYPES_INSERT => q{
    INSERT INTO member_types (name) VALUES
        ('full'),
        ('alumni'),
        ('interm');
};
use constant TEST_MEMBERS_TABLE => q{
    CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        rfid TEXT NOT NULL UNIQUE,
        active BOOLEAN NOT NULL DEFAULT TRUE,
        member_type INT NOT NULL REFERENCES member_types (id),
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        join_date DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        end_date DATE,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        entry_type TEXT NOT NULL,
        address TEXT NOT NULL,
        address_type TEXT NOT NULL,
        signing_member INT REFERENCES members (id),
        notes TEXT
    );
    CREATE INDEX ON members (lower(first_name), lower(last_name));
};
use constant TEST_LOG_TABLE => q{
    CREATE TABLE entry_log (
        id            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        rfid          BLOB NOT NULL,
        is_active_tag BOOL NOT NULL,
        is_found_tag  BOOL NOT NULL,
        entry_time    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
};
use constant TEST_LIABILITY_TABLE => q{
    CREATE TABLE liability_waivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        full_name TEXT NOT NULL,
        check1 BOOLEAN NOT NULL,
        check2 BOOLEAN NOT NULL,
        check3 BOOLEAN NOT NULL,
        check4 BOOLEAN NOT NULL,
        addr TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        zip TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        emergency_contact_name TEXT NOT NULL,
        emergency_contact_phone TEXT NOT NULL,
        heard_from TEXT,
        signature TEXT NOT NULL
    );
};
use constant TEST_GUEST_TABLE => q{
    CREATE TABLE guest_signin (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        full_name TEXT NOT NULL,
        member_hosting TEXT,
        email TEXT NOT NULL,
        join_mailing_list BOOLEAN NOT NULL
    );
};
use constant TEST_COST_BUCKET_TABLE => q{
    CREATE TABLE cost_buckets (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT NOT NULL,
        cost INTEGER NOT NULL,
        cost_per TEXT NOT NULL
    );
};
use constant TEST_MEMBER_COST_TABLE => q{
    CREATE TABLE member_costs (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        cost_bucket_id INT NOT NULL REFERENCES cost_buckets (id),
        member_id INT NOT NULL REFERENCES members (id),
        qty INT NOT NULL,
        paid_on DATETIME,
        entered_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
};


my $tmp_obj;
sub get_test_dbh
{
    return 0 if defined $tmp_obj; # Only call this once
    $tmp_obj = File::Temp->new(
        EXLOCK => 0,
    );
    $tmp_obj->unlink_on_destroy( 1 );
    my $filename = $tmp_obj->filename;

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$filename", '', '', {
        AutoCommit => 1,
        RaiseError => 0,
    });

    foreach (
        TEST_MEMBER_TYPES_TABLE,
        TEST_MEMBER_TYPES_INSERT,
        TEST_MEMBERS_TABLE,
        TEST_LOG_TABLE,
        TEST_LIABILITY_TABLE,
        #TEST_GUEST_TABLE,
        TEST_COST_BUCKET_TABLE,
        TEST_MEMBER_COST_TABLE,
    ) {
        $dbh->do( $_ ) or die "Could not create table: " . $dbh->errstr;
    }

    return $dbh;
}


1;
__END__

