CREATE TABLE bodgery_rfid (
    id        SERIAL PRIMARY KEY NOT NULL,
    rfid      TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL UNIQUE,
    active    BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX ON bodgery_rfid (lower(full_name));

CREATE TABLE entry_log (
    id              SERIAL PRIMARY KEY NOT NULL,
    -- This could be some random RFID tag, which we may not have in our 
    -- database.  So don't reference tags in bodgery_rfid directly.
    rfid            TEXT NOT NULL,
    entry_time      TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active_tag   BOOLEAN NOT NULL,
    is_found_tag    BOOLEAN NOT NULL
);
CREATE INDEX ON entry_log (entry_time);
