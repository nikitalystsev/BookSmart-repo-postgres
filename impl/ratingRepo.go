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

func (rr *RatingRepo) Create(ctx context.Context, rating *models.RatingModel) error {
	rr.logger.Infof("inserting rating with ID %s", rating.ID.String())

	query := `insert into bs.rating values ($1, $2, $3, $4, $5)`

	result, err := rr.db.ExecContext(ctx, query,
		rating.ID,
		rating.ReaderID,
		rating.BookID,
		rating.Review,
		rating.Rating,
	)

	if err != nil {
		rr.logger.Errorf("error inserting rating: %v", err)
		return err
	}
	rows, err := result.RowsAffected()
	if err != nil {
		rr.logger.Errorf("error inserting rating: %v", err)
		return err
	}
	if rows != 1 {
		rr.logger.Errorf("error inserting rating: expected 1 row affected, got %d", rows)
		return errors.New("ratingRepo.Create: expected 1 row affected")
	}

	return nil
}

func (rr *RatingRepo) GetByReaderAndBook(ctx context.Context, readerID, bookID uuid.UUID) (*models.RatingModel, error) {
	rr.logger.Infof("selecting rating with readerID and bookID: %s, %s", readerID.String(), bookID.String())

	query := `select id, reader_id, book_id, review, rating from bs.rating where reader_id = $1 and book_id = $2`

	var rating repomodels.RatingModel
	err := rr.db.GetContext(ctx, &rating, query, readerID, bookID)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		rr.logger.Errorf("error selecting rating: %v", err)
		return nil, err
	}
	if errors.Is(err, sql.ErrNoRows) {
		rr.logger.Warn("rating not found")
		return nil, errs.ErrRatingDoesNotExists
	}

	rr.logger.Infof("selected rating with readerID and bookID: %s, %s", readerID.String(), bookID.String())

	return rr.convertToRatingModel(&rating), nil
}

// GetByBookID TODO logs
func (rr *RatingRepo) GetByBookID(ctx context.Context, bookID uuid.UUID, limit, offset int) ([]*models.RatingModel, error) {
	rr.logger.Infof("selecting ratings with bookID: %s", bookID.String())

	query := `select id, reader_id, book_id, review, rating from bs.rating where book_id = $1 order by id limit $2 offset $3`

	var coreRatings []*repomodels.RatingModel

	err := rr.db.SelectContext(ctx, &coreRatings, query, bookID, limit, offset)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		rr.logger.Errorf("error selecting ratings: %v", err)
		return nil, err
	}
	if errors.Is(err, sql.ErrNoRows) || len(coreRatings) == 0 {
		rr.logger.Warn("ratings not found")
		return nil, errs.ErrRatingDoesNotExists
	}

	ratings := make([]*models.RatingModel, len(coreRatings))
	for i, book := range coreRatings {
		ratings[i] = rr.convertToRatingModel(book)
	}

	rr.logger.Infof("selected ratings with bookID: %s", bookID.String())

	return ratings, nil
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
