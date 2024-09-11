package models

import "github.com/google/uuid"

type ReaderModel struct {
	ID          uuid.UUID `db:"id"`
	Fio         string    `db:"fio"`
	PhoneNumber string    `db:"phone_number"`
	Age         uint      `db:"age"`
	Password    string    `db:"password"`
	Role        string    `db:"role"`
}
