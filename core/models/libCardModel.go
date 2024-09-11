package models

import (
	"github.com/google/uuid"
	"time"
)

type LibCardModel struct {
	ID           uuid.UUID `db:"id"`
	ReaderID     uuid.UUID `db:"reader_id"`
	LibCardNum   string    `db:"lib_card_num"`
	Validity     int       `db:"validity"`
	IssueDate    time.Time `db:"issue_date"`
	ActionStatus bool      `db:"action_status"`
}
