module github.com/nikitalystsev/BookSmart-repo-postgres

go 1.22.5

require (
	github.com/avito-tech/go-transaction-manager/drivers/sqlx/v2 v2.0.0
	github.com/go-redis/redis/v8 v8.11.5
	github.com/google/uuid v1.6.0
	github.com/jmoiron/sqlx v1.4.0
	github.com/nikitalystsev/BookSmart-services v0.0.0-20240919123005-14b28ba85ee2
	github.com/redis/go-redis/v9 v9.6.1
	github.com/sirupsen/logrus v1.9.3
)

require (
	github.com/avito-tech/go-transaction-manager/drivers/sql/v2 v2.0.0 // indirect
	github.com/avito-tech/go-transaction-manager/trm/v2 v2.0.0 // indirect
	github.com/cespare/xxhash/v2 v2.2.0 // indirect
	github.com/davecgh/go-spew v1.1.2-0.20180830191138-d8f796af33cc // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/fsnotify/fsnotify v1.7.0 // indirect
	github.com/golang-jwt/jwt/v4 v4.5.0 // indirect
	github.com/google/go-cmp v0.6.0 // indirect
	github.com/onsi/gomega v1.24.1 // indirect
	github.com/pmezard/go-difflib v1.0.1-0.20181226105442-5d4384ee4fb2 // indirect
	github.com/stretchr/testify v1.9.0 // indirect
	go.uber.org/atomic v1.9.0 // indirect
	go.uber.org/multierr v1.9.0 // indirect
	golang.org/x/crypto v0.27.0 // indirect
	golang.org/x/net v0.29.0 // indirect
	golang.org/x/sys v0.25.0 // indirect
)

replace github.com/nikitalystsev/BookSmart-services => ../component-services
