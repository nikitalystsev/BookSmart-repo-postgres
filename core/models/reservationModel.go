package models

import (
	"github.com/google/uuid"
	"time"
)

type ReservationModel struct {
	ID         uuid.UUID `db:"id"`
	ReaderID   uuid.UUID `db:"reader_id"`
	BookID     uuid.UUID `db:"book_id"`
	IssueDate  time.Time `db:"issue_date"`
	ReturnDate time.Time `db:"return_date"`
	State      string    `db:"state"`
}
