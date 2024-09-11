package repoPostgres

import (
	"github.com/jmoiron/sqlx"
)

func NewClient(url string) (*sqlx.DB, error) {
	dsn := url

	db, err := sqlx.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}

	err = db.Ping()
	if err != nil {
		return nil, err
	}

	return db, nil
}
