package models

import "github.com/google/uuid"

type BookModel struct {
	ID             uuid.UUID `db:"id"`
	Title          string    `db:"title"`
	Author         string    `db:"author"`
	Publisher      string    `db:"publisher"`
	CopiesNumber   uint      `db:"copies_number"`
	Rarity         string    `db:"rarity"`
	Genre          string    `db:"genre"`
	PublishingYear uint      `db:"publishing_year"`
	Language       string    `db:"language"`
	AgeLimit       uint      `db:"age_limit"`
}
