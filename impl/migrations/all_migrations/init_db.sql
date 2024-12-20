create schema if not exists bs;

-- таблицы

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
    action_status BOOLEAN          NOT NULL
);

alter table bs.lib_card
    add foreign key (reader_id) references reader (id) on delete cascade on update cascade;

CREATE TABLE IF NOT EXISTS bs.favorite_books
(
    book_id   UUID NOT NULL,
    reader_id UUID NOT NULL
);

alter table bs.favorite_books
    add primary key (book_id, reader_id),
    add foreign key (book_id) references book (id) on delete cascade on update cascade,
    add foreign key (reader_id) references reader (id) on delete cascade on update cascade;

CREATE TYPE RESERVATION_STATE AS ENUM ('Issued', 'Extended', 'Expired', 'Closed');

CREATE TABLE IF NOT EXISTS bs.reservation
(
    id          UUID PRIMARY KEY  NOT NULL DEFAULT uuid_generate_v4(),
    reader_id   UUID              NOT NULL,
    book_id     UUID              NOT NULL,
    issue_date  DATE              NOT NULL,
    return_date DATE              NOT NULL,
    state       RESERVATION_STATE NOT NULL
);

alter table bs.reservation
    add foreign key (reader_id) references reader (id) on delete cascade on update cascade,
    add foreign key (book_id) references book (id) on delete cascade on update cascade,
    add check (issue_date < return_date);

create table if not exists bs.rating
(
    id        uuid primary key not null default uuid_generate_v4(),
    reader_id uuid             not null,
    book_id   uuid             not null,
    review    text,
    rating    int              not null
);

alter table bs.rating
    add foreign key (reader_id) references reader (id) on delete cascade on update cascade,
    add foreign key (book_id) references book (id) on delete cascade on update cascade;

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

-- добавление книг

COPY bs.book FROM '/data/books.csv' DELIMITER ',' CSV HEADER;

-- немного значений

insert into bs.reader
values ('3885b2d3-ef6e-4f62-8f86-d1454d108207', 'Mitrofan Bogdanov', '76867456521', 40,
        '$2a$10$KxEprnJtxnL./4Zts.IP3uOQfGktXZXTp1BmvMKZxyDSJoIm4hmt6', 'Reader'), -- пароль: hghhfnnbdd
       ('75919792-c2d9-4685-92b2-e2a80b2ed5be', 'Randall C. Jernigan', '79314562376', 25,
        '$2a$10$8APnhcfxoGxXGdNHSdBEaebuwcIkjwEnSHOIv.xu9bmROkpCRLTJS', 'Reader'), -- пароль: sdgdgsgsgd
       ('5818061a-662d-45bb-a67c-0d2873038e65', 'Jesse M. Flores', '72443564633', 20,
        '$2a$10$2cYeMgl8fjH76HjIm54enOuHUiV3qzV81jdVJLLNCQbo2zXc9jija', 'Reader'), -- пароль: qwresdfdsf
       ('6800b3ee-9810-450e-9ca5-776aa1c6191d', 'Peter Zuev', '32534523451', 13,
        '$2a$10$GjKIYnr6wRohYWkUhmlPhO5uza1zvudS9rWeydAv1yzEW0GfTOAme', 'Reader'), -- пароль: rtjhhhgffr
       ('8d9b001f-5760-4c40-bc60-988e0ca54d18', 'Vasilisa Agapova', '73453562423', 36,
        '$2a$10$sQZzp5BlhAvTMc/AIzAUS.PVuAxxH/rVmNfv.W73RhdxH7xSdbyQy', 'Reader'), -- пароль: gfjkjdgffy
       ('362b79f6-d671-404a-b1a0-5a655aebc1b6', 'Лысцев Никита Дмитриевич', '89314022581', 21,
        '$2a$10$xDzRFS0ClhEcosyFVQEPCev8AXakZyYau4Hk8iN3dyTXJYXUj1coO', 'Admin');

-- для Peter Zuev 32534523451 rtjhhhgffr
insert into bs.lib_card
values ('894f6d5c-f81a-46c0-98aa-d7a90aafd93e', '6800b3ee-9810-450e-9ca5-776aa1c6191d', '5435645425466', 365,
        '2023-03-05', false);
-- end

-- для Randall C. Jernigan
insert into bs.lib_card
values ('e71af5a9-dd02-4f00-982e-ec58908ec5bd', '75919792-c2d9-4685-92b2-e2a80b2ed5be', '4654645456328', 365,
        '2024-07-26', true);

insert into bs.reservation
values ('89ff79cd-5ef9-4553-9dac-b3fc2954048c', '75919792-c2d9-4685-92b2-e2a80b2ed5be',
        'f01107fb-4f7a-4f37-ba1e-6c6012c5203c', '2024-09-10', '2024-09-24', 'Issued'),
       ('97f918b0-b8f6-4bd4-b0e0-9d25971b9af2', '75919792-c2d9-4685-92b2-e2a80b2ed5be',
        '43f45552-4a95-4f12-864b-e1d8bfa30b8d', '2024-09-10', '2024-09-24', 'Issued');
-- end

-- для Jesse M. Flores 72443564633 qwresdfdsf
insert into bs.lib_card
values ('5411019a-7dbf-4dbb-b621-784176da6ec5', '5818061a-662d-45bb-a67c-0d2873038e65', '3455787683242', 365,
        '2024-05-13', true);

insert into bs.reservation
values ('bdf16862-6289-4f21-aff7-2e5fdb9edfed', '5818061a-662d-45bb-a67c-0d2873038e65',
        'b33b30c8-254e-45f2-8314-0b93a6b8c561', '2024-05-14', '2024-05-28', 'Expired');
-- end

-- для Mitrofan Bogdanov 76867456521 hghhfnnbdd
insert into bs.lib_card
values ('0614f5de-ac79-4bab-995f-99944a7ca4db', '3885b2d3-ef6e-4f62-8f86-d1454d108207', '7945544456734', 365,
        '2022-07-26', false);
-- end

-- для Vasilisa Agapova 73453562423 gfjkjdgffy
insert into bs.reservation (reader_id, book_id, issue_date, return_date, state)
values ('8d9b001f-5760-4c40-bc60-988e0ca54d18',
        'c5fc4421-9455-47a2-b93e-796e79b76321', '2024-09-10', '2024-09-24', 'Issued'),
       ('8d9b001f-5760-4c40-bc60-988e0ca54d18',
        'deb3123e-7bd5-4126-8cc2-724909bc8f84', '2024-09-10', '2024-09-24', 'Issued'),
       ('8d9b001f-5760-4c40-bc60-988e0ca54d18',
        'cfd75998-1d5b-4bf3-9f42-f6e68c1ddecb', '2024-09-10', '2024-09-24', 'Issued'),
       ('8d9b001f-5760-4c40-bc60-988e0ca54d18',
        'a0809a90-d9d2-40a8-979e-ed716527a9d6', '2024-09-10', '2024-09-24', 'Issued'),
       ('8d9b001f-5760-4c40-bc60-988e0ca54d18',
        '7b8d16d1-bd35-4848-87f2-9cfc41e38ce1', '2024-09-10', '2024-09-24', 'Issued'),
       ('8d9b001f-5760-4c40-bc60-988e0ca54d18',
        'fa236d56-0882-44fe-941f-ea3e41bfef0d', '2024-09-10', '2024-09-24', 'Issued'),
       ('8d9b001f-5760-4c40-bc60-988e0ca54d18',
        '8a5e15fc-8b8f-4f39-bf28-188ae8f245ff', '2024-09-10', '2024-09-24', 'Issued'),
       ('8d9b001f-5760-4c40-bc60-988e0ca54d18',
        '5bfe4574-ba58-4712-a7c8-0527f64d2a48', '2024-09-10', '2024-09-24', 'Issued'),
       ('8d9b001f-5760-4c40-bc60-988e0ca54d18',
        'b327b41e-390c-4bee-bcf2-0056b67e0e5a', '2024-09-10', '2024-09-24', 'Issued'),
       ('8d9b001f-5760-4c40-bc60-988e0ca54d18',
        'f7328494-46fb-444c-ac86-96835a0f50be', '2024-09-10', '2024-09-24', 'Issued');

insert into bs.lib_card (reader_id, lib_card_num, validity, issue_date, action_status)
values ('8d9b001f-5760-4c40-bc60-988e0ca54d18', '4324546523555', 365, '2024-07-26', true);
-- end


-- роли бд

create role administrator;

grant usage on schema bs to administrator;
grant all privileges on all tables in schema bs to administrator;

create user admin_user with password 'admin';

grant administrator to admin_user;


create role reader;

grant usage on schema bs to reader;
grant select on all tables in schema bs to reader;

create user reader_user with password 'reader';

grant reader to reader_user;


