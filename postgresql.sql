CREATE TABLE bodgery_rfid (
    id        SERIAL PRIMARY KEY NOT NULL,
    rfid      TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL UNIQUE,
    active    BOOLEAN NOT NULL DEFAULT 1
);

CREATE TABLE entry_log (
    id              SERIAL PRIMARY KEY NOT NULL,
    bodgery_rfid_id INTEGER NOT NULL,
    entry_time      TIMESTAMP NOT NULL DEFAULT NOW()
);
