package config_cloud

import (
	"bufio"
	"database/sql"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/google/uuid"
	"solidification/internal/database"
)

// CloudConfig struct type for holding db connections and s3 relevant info
type CloudConfig struct {
	s3AccessKey    string
	s3SecretAccess string
	s3Bucket       string
	s3Region       string
	dataFilepath   string
	runTemperature float64
	runDensity     float64
	runVersion     string
	inputScanner   *bufio.Scanner
	runID          uuid.UUID
	db             *sql.DB
	dbQueries      *database.Queries
	s3Client       *s3.Client
}

// Selectors
func (cfg *CloudConfig) GetDBQueries() *database.Queries { return cfg.dbQueries }

func (cfg *CloudConfig) GetDB() *sql.DB {
	return cfg.db
}

func (cfg *CloudConfig) GetS3Client() *s3.Client {
	return cfg.s3Client
}

func (cfg *CloudConfig) GetS3Bucket() string {
	return cfg.s3Bucket
}

func (cfg *CloudConfig) GetS3Region() string {
	return cfg.s3Region
}

func (cfg *CloudConfig) GetRunID() uuid.UUID {
	return cfg.runID
}

func (cfg *CloudConfig) GetDataFilepath() string {
	return cfg.dataFilepath
}

func (cfg *CloudConfig) GetRunTemperature() float64 {
	return cfg.runTemperature
}

func (cfg *CloudConfig) GetRunDensity() float64 {
	return cfg.runDensity
}

func (cfg *CloudConfig) GetRunVersion() string {
	return cfg.runVersion
}

func (cfg *CloudConfig) GetInputScanner() *bufio.Scanner { return cfg.inputScanner }

// Constructors

func (cfg *CloudConfig) SetRunID(runID uuid.UUID) {
	cfg.runID = runID
	return
}

func (cfg *CloudConfig) SetRunTemperature(temperature float64) {
	cfg.runTemperature = temperature
	return
}

func (cfg *CloudConfig) SetRunDensity(density float64) {
	cfg.runDensity = density
	return
}

func (cfg *CloudConfig) SetRunVersion(version string) {
	cfg.runVersion = version
	return
}

func (cfg *CloudConfig) SetScanner(scanner *bufio.Scanner) {
	cfg.inputScanner = scanner
	return
}

// SetDBQueries This is really a query wrapper not the websocket connection itself
func (cfg *CloudConfig) SetDBQueries(db *sql.DB) {
	queries := database.New(db)
	cfg.dbQueries = queries
	return
}
