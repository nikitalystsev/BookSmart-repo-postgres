package impl

import (
	"context"
	"database/sql"
	"errors"
	trmsqlx "github.com/avito-tech/go-transaction-manager/drivers/sqlx/v2"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	repomodels "github.com/nikitalystsev/BookSmart-repo-postgres/core/models"
	"github.com/nikitalystsev/BookSmart-services/core/dto"
	"github.com/nikitalystsev/BookSmart-services/core/models"
	"github.com/nikitalystsev/BookSmart-services/errs"
	"github.com/nikitalystsev/BookSmart-services/intfRepo"
	"github.com/sirupsen/logrus"
)

type BookRepo struct {
	db     *sqlx.DB
	getter *trmsqlx.CtxGetter
	logger *logrus.Entry
}

func NewBookRepo(db *sqlx.DB, logger *logrus.Entry) intfRepo.IBookRepo {
	return &BookRepo{db: db, getter: trmsqlx.DefaultCtxGetter, logger: logger}
}

func (br *BookRepo) Create(ctx context.Context, book *models.BookModel) error {
	br.logger.Infof("inserting book with ID: %s", book.ID)

	query := `insert into bs.book values ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`

	result, err := br.getter.DefaultTrOrDB(ctx, br.db).ExecContext(
		ctx, query,
		book.ID,
		book.Title,
		book.Author,
		book.Publisher,
		book.CopiesNumber,
		book.Rarity,
		book.Genre,
		book.PublishingYear,
		book.Language,
		book.AgeLimit,
	)
	if err != nil {
		br.logger.Errorf("error inserting book: %v", err)
		return err
	}
	rows, err := result.RowsAffected()
	if err != nil {
		br.logger.Errorf("error inserting book: %v", err)
		return err
	}
	if rows != 1 {
		br.logger.Errorf("error inserting book: expected 1 row affected, got %d", rows)
		return errors.New("bookRepo.Create: expected 1 row affected")
	}

	br.logger.Infof("inserted book with ID: %s", book.ID)

	return nil
}

func (br *BookRepo) GetByID(ctx context.Context, ID uuid.UUID) (*models.BookModel, error) {
	br.logger.Infof("selecting book with ID: %s", ID)

	query := `select 
    			id, 
    			title,
    			author, 
    			publisher,
    			copies_number, 
    			rarity, 
    			genre, 
    			publishing_year, 
    			language, 
    			age_limit
			  from bs.book 
			  where id = $1`

	var book repomodels.BookModel
	err := br.getter.DefaultTrOrDB(ctx, br.db).GetContext(ctx, &book, query, ID)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		br.logger.Errorf("error selecting book with ID: %v", err)
		return nil, err
	}
	if errors.Is(err, sql.ErrNoRows) {
		br.logger.Warnf("book with this ID not found %s", ID)
		return nil, errs.ErrBookDoesNotExists
	}

	br.logger.Infof("selected book with ID: %s", ID)

	return br.convertToBookModel(&book), nil
}

func (br *BookRepo) GetByTitle(ctx context.Context, title string) (*models.BookModel, error) {
	br.logger.Infof("selecting book by title: %s", title)

	query := `select 
    			id, 
    			title,
    			author, 
    			publisher,
    			copies_number, 
    			rarity, 
    			genre, 
    			publishing_year, 
    			language, 
    			age_limit
			  from bs.book 
			  where title = $1`

	var book repomodels.BookModel
	err := br.getter.DefaultTrOrDB(ctx, br.db).GetContext(ctx, &book, query, title)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		br.logger.Errorf("error selecting book by title: %v", err)
		return nil, err
	}
	if errors.Is(err, sql.ErrNoRows) {
		br.logger.Warnf("book with this title not found: %s", title)
		return nil, errs.ErrBookDoesNotExists
	}

	br.logger.Infof("selected book with title: %s", title)

	return br.convertToBookModel(&book), nil
}

func (br *BookRepo) Delete(ctx context.Context, ID uuid.UUID) error {
	br.logger.Infof("deleting book with ID: %s", ID)

	query := `delete from bs.book where id = $1`

	result, err := br.getter.DefaultTrOrDB(ctx, br.db).ExecContext(ctx, query, ID)
	if err != nil {
		br.logger.Errorf("error deleting book: %v", err)
		return err
	}
	rows, err := result.RowsAffected()
	if err != nil {
		br.logger.Errorf("error deleting book: %v", err)
		return err
	}
	if rows != 1 {
		br.logger.Errorf("error deleting book: expected 1 row affected, got %d", rows)
		return errors.New("bookRepo.Delete: expected 1 row affected")
	}

	br.logger.Infof("deleted book with ID: %s", ID)

	return nil
}

func (br *BookRepo) Update(ctx context.Context, book *models.BookModel) error {
	br.logger.Infof("updating book with ID: %s", book.ID)

	query := `update bs.book 
			  set title = $1, 
			      author = $2, 
			      publisher = $3, 
			      copies_number = $4, 
			      rarity = $5, 
			      genre = $6,
			      publishing_year = $7,
			      language = $8,
			      age_limit = $9
			  where id = $10`

	result, err := br.getter.DefaultTrOrDB(ctx, br.db).ExecContext(
		ctx, query,
		book.Title,
		book.Author,
		book.Publisher,
		book.CopiesNumber,
		book.Rarity,
		book.Genre,
		book.PublishingYear,
		book.Language,
		book.AgeLimit,
		book.ID,
	)
	if err != nil {
		br.logger.Errorf("error updating book: %v", err)
		return err
	}
	rows, err := result.RowsAffected()
	if err != nil {
		br.logger.Errorf("error updating book: %v", err)
		return err
	}
	if rows != 1 {
		br.logger.Errorf("error updating book: expected 1 row affected, got %d", rows)
		return errors.New("bookRepo.Update: expected 1 row affected")
	}

	br.logger.Infof("updated book with ID: %s", book.ID)

	return nil
}

func (br *BookRepo) GetByParams(ctx context.Context, params *dto.BookParamsDTO) ([]*models.BookModel, error) {
	br.logger.Infof("selecting books with params")

	query := `select * 
	          from bs.book 
	          where ($1 = '' or title ilike '%' || $1 || '%') and 
	                ($2 = '' or author ilike '%' || $2 || '%') and 
	                ($3 = '' or publisher ilike '%' || $3 || '%') and 
	                ($4 = 0 or copies_number = $4) and 
	                ($5 = '' or rarity::text = $5) and 
	                ($6 = '' or genre ilike '%' || $6 || '%') and 
	                ($7 = 0 or publishing_year = $7) and 
	                ($8 = '' or language ilike '%' || $8 || '%') and 
	                ($9 = 0 or age_limit = $9)
	          limit $10 offset $11`

	var coreBooks []*repomodels.BookModel

	err := br.getter.DefaultTrOrDB(ctx, br.db).SelectContext(ctx, &coreBooks, query,
		params.Title,
		params.Author,
		params.Publisher,
		params.CopiesNumber,
		params.Rarity,
		params.Genre,
		params.PublishingYear,
		params.Language,
		params.AgeLimit,
		params.Limit,
		params.Offset,
	)

	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		br.logger.Errorf("error selecting books with params")
		return nil, err
	}
	if errors.Is(err, sql.ErrNoRows) || len(coreBooks) == 0 {
		br.logger.Warnf("books not found with this params")
		return nil, errs.ErrBookDoesNotExists
	}

	br.logger.Infof("found %d books", len(coreBooks))

	books := make([]*models.BookModel, len(coreBooks))
	for i, book := range coreBooks {
		books[i] = br.convertToBookModel(book)
	}

	return books, nil
}

func (br *BookRepo) convertToBookModel(book *repomodels.BookModel) *models.BookModel {
	return &models.BookModel{
		ID:             book.ID,
		Title:          book.Title,
		Author:         book.Author,
		Publisher:      book.Publisher,
		CopiesNumber:   book.CopiesNumber,
		Rarity:         book.Rarity,
		Genre:          book.Genre,
		PublishingYear: book.PublishingYear,
		Language:       book.Language,
		AgeLimit:       book.AgeLimit,
	}
}
