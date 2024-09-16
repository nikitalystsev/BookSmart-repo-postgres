package impl

import (
	"context"
	"database/sql"
	"errors"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	repomodels "github.com/nikitalystsev/BookSmart-repo-postgres/core/models"
	"github.com/nikitalystsev/BookSmart-services/core/models"
	"github.com/nikitalystsev/BookSmart-services/errs"
	"github.com/nikitalystsev/BookSmart-services/intfRepo"
	"github.com/sirupsen/logrus"
)

type RatingRepo struct {
	db     *sqlx.DB
	logger *logrus.Entry
}

func NewRatingRepo(db *sqlx.DB, logger *logrus.Entry) intfRepo.IRatingRepo {
	return &RatingRepo{db: db, logger: logger}
}

// Create TODO logs
func (rr *RatingRepo) Create(ctx context.Context, rating *models.RatingModel) error {
	query := `insert into bs.rating values ($1, $2, $3, $4, $5)`

	result, err := rr.db.ExecContext(ctx, query,
		rating.ID,
		rating.ReaderID,
		rating.BookID,
		rating.Review,
		rating.Rating,
	)
	if err != nil {
		return err
	}
	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows != 1 {
		return errors.New("ratingRepo.Create: expected 1 row affected")
	}

	return nil
}

// GetByReaderAndBook TODO logs
func (rr *RatingRepo) GetByReaderAndBook(ctx context.Context, readerID uuid.UUID, bookID uuid.UUID) (*models.RatingModel, error) {
	query := `select id, reader_id, book_id, review, rating from bs.rating where reader_id = $1 and book_id = $2`

	var rating repomodels.RatingModel
	err := rr.db.GetContext(ctx, &rating, query, readerID, bookID)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	}
	if errors.Is(err, sql.ErrNoRows) {
		return nil, errs.ErrRatingDoesNotExists
	}

	return rr.convertToRatingModel(&rating), nil
}

func (rr *RatingRepo) convertToRatingModel(rating *repomodels.RatingModel) *models.RatingModel {
	return &models.RatingModel{
		ID:       rating.ID,
		BookID:   rating.BookID,
		ReaderID: rating.ReaderID,
		Review:   rating.Review,
		Rating:   rating.Rating,
	}
}
