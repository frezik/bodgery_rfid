package TestDB;
use v5.14;
use warnings;
use File::Temp 'tempfile';
use DBI;
use DBD::SQLite;

use constant TEST_RFID_TABLE => q{
    CREATE TABLE bodgery_rfid (
        id        INTEGER PRIMARY KEY NOT NULL,
        rfid      BLOB NOT NULL UNIQUE,
        full_name BLOB NOT NULL UNIQUE,
        active    BOOL NOT NULL DEFAULT 1
    );
};
use constant TEST_LOG_TABLE => q{
    CREATE TABLE entry_log (
        id            INTEGER PRIMARY KEY NOT NULL,
        rfid          BLOB NOT NULL,
        is_active_tag BOOL NOT NULL,
        is_found_tag  BOOL NOT NULL,
        entry_time    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
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

    foreach (TEST_RFID_TABLE, TEST_LOG_TABLE) {
        $dbh->do( $_ ) or die "Could not create table: " . $dbh->errstr;
    }

    return $dbh;
}


1;
__END__

