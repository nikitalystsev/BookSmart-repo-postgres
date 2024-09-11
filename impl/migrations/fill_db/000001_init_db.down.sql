DROP VIEW IF EXISTS bs.reservation_view;
DROP FUNCTION IF EXISTS bs.update_expired_reservations;
DROP TABLE IF EXISTS bs.reservation;
DROP TABLE IF EXISTS bs.favorite_books;
DROP VIEW IF EXISTS bs.lib_card_view;
DROP FUNCTION IF EXISTS bs.update_inactive_lib_cards;
DROP TABLE IF EXISTS bs.lib_card;
DROP TABLE IF EXISTS bs.reader;
DROP TABLE IF EXISTS bs.book;

DROP TYPE BOOK_RARITY;
DROP TYPE RESERVATION_STATE;
DROP TYPE READER_ROLE;