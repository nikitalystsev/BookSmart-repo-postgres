CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE BOOK_RARITY AS ENUM ('Common', 'Rare', 'Unique');

CREATE TABLE IF NOT EXISTS bs.book
(
    id              UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    title           TEXT             NOT NULL,
    author          TEXT             NOT NULL,
    publisher       TEXT             NOT NULL,
    copies_number   INT              NOT NULL CHECK (copies_number > 0),
    rarity          BOOK_RARITY      NOT NULL,
    genre           TEXT             NOT NULL,
    publishing_year INT              NOT NULL,
    language        TEXT             NOT NULL,
    age_limit       INT              NOT NULL CHECK (age_limit >= 0)
);

CREATE TYPE READER_ROLE AS ENUM ('Reader', 'Admin');

CREATE TABLE IF NOT EXISTS bs.reader
(
    id           UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    fio          TEXT             NOT NULL,
    phone_number VARCHAR(20)      NOT NULL UNIQUE,
    age          INT              NOT NULL CHECK (age > 0 AND age < 100),
    password     TEXT             NOT NULL,
    role         READER_ROLE      NOT NULL
);

CREATE TABLE IF NOT EXISTS bs.lib_card
(
    id            UUID PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    reader_id     UUID             NOT NULL,
    lib_card_num  VARCHAR(13)      NOT NULL UNIQUE,
    validity      INT              NOT NULL,
    issue_date    DATE             NOT NULL,
    action_status BOOLEAN          NOT NULL,
    FOREIGN KEY (reader_id) REFERENCES reader (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS bs.favorite_books
(
    book_id   UUID NOT NULL,
    reader_id UUID NOT NULL,
    PRIMARY KEY (book_id, reader_id),
    FOREIGN KEY (book_id) REFERENCES book (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (reader_id) REFERENCES reader (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TYPE RESERVATION_STATE AS ENUM ('Issued', 'Extended', 'Expired', 'Closed');

CREATE TABLE IF NOT EXISTS bs.reservation
(
    id          UUID PRIMARY KEY  NOT NULL DEFAULT uuid_generate_v4(),
    reader_id   UUID              NOT NULL,
    book_id     UUID              NOT NULL,
    issue_date  DATE              NOT NULL,
    return_date DATE              NOT NULL,
    state       RESERVATION_STATE NOT NULL,
    FOREIGN KEY (reader_id) REFERENCES reader (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (book_id) REFERENCES book (id) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK (issue_date < return_date)
);

create table if not exists bs.rating
(
    id        uuid primary key not null default uuid_generate_v4(),
    reader_id uuid             not null,
    book_id   uuid             not null,
    review    text,
    rating    int              not null,
    FOREIGN KEY (reader_id) REFERENCES reader (id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (book_id) REFERENCES book (id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE OR REPLACE FUNCTION bs.update_expired_reservations()
    RETURNS void AS
$$
BEGIN
    UPDATE bs.reservation
    SET state = 'Expired'
    WHERE state != 'Closed'
      AND return_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW bs.reservation_view AS
SELECT r.id,
       r.reader_id,
       r.book_id,
       r.issue_date,
       r.return_date,
       r.state
FROM (SELECT bs.update_expired_reservations()) AS u,
     bs.reservation r;

CREATE OR REPLACE FUNCTION bs.update_inactive_lib_cards()
    RETURNS void AS
$$
BEGIN
    UPDATE bs.lib_card
    SET action_status = false
    WHERE action_status = true
      AND (issue_date + validity * INTERVAL '1 day') < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW bs.lib_card_view AS
SELECT lc.id,
       lc.reader_id,
       lc.lib_card_num,
       lc.validity,
       lc.issue_date,
       lc.action_status
FROM (SELECT bs.update_inactive_lib_cards()) AS u,
     bs.lib_card lc;