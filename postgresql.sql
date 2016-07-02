CREATE TABLE member_types (
    id SERIAL PRIMARY KEY NOT NULL,
    name TEXT NOT NULL UNIQUE
);
INSERT INTO member_types (name) VALUES
    ('full'),
    ('alumni'),
    ('interm');

CREATE TABLE members (
    id SERIAL PRIMARY KEY NOT NULL,
    rfid TEXT NOT NULL UNIQUE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    member_type INT NOT NULL REFERENCES member_types (id),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    join_date DATE NOT NULL DEFAULT NOW(),
    end_date DATE,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    entry_type TEXT NOT NULL,
    address TEXT NOT NULL,
    address_type TEXT NOT NULL,
    signing_member INT REFERENCES members (id),
    notes TEXT
);
CREATE INDEX ON members ( lower( first_name || ' ' || last_name ) );

CREATE TABLE liability_waivers (
    id SERIAL PRIMARY KEY NOT NULL,
    created_date TIMESTAMP NOT NULL DEFAULT NOW(),
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
CREATE INDEX ON liability_waivers (lower(full_name));
CREATE INDEX ON liability_waivers (created_date);
CREATE INDEX ON liability_waivers (lower(email));

CREATE TABLE guest_signin (
    id SERIAL PRIMARY KEY NOT NULL,
    created_date TIMESTAMP NOT NULL DEFAULT NOW(),
    full_name TEXT NOT NULL,
    member_hosting TEXT,
    email TEXT NOT NULL,
    join_mailing_list BOOLEAN NOT NULL,
    is_mailing_list_exported BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX ON guest_signin (lower(full_name));
CREATE INDEX ON guest_signin (created_date);
CREATE INDEX ON guest_signin (lower(email));
CREATE INDEX ON guest_signin (is_mailing_list_exported);

CREATE TABLE entry_log (
    id              SERIAL PRIMARY KEY NOT NULL,
    -- This could be some random RFID tag, which we may not have in our 
    -- database.  So don't reference tags in bodgery_rfid directly.
    rfid            TEXT NOT NULL,
    entry_time      TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active_tag   BOOLEAN NOT NULL,
    is_found_tag    BOOLEAN NOT NULL
);
CREATE INDEX ON entry_log (entry_time DESC);




-- Old RFID table
CREATE TABLE bodgery_rfid (
    id        SERIAL PRIMARY KEY NOT NULL,
    rfid      TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL UNIQUE,
    active    BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX ON bodgery_rfid (lower(full_name));

