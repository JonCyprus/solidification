package config_cloud

import (
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
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
	runID          uuid.UUID
	db             *database.Queries
	s3Client       *s3.Client
}

// Selectors

func (cfg *CloudConfig) GetDB() *database.Queries {
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
}

// SetDB This is really a query wrapper not the webscoket itself
func (cfg *CloudConfig) SetDB(db *pgx.Conn) {
	queries := database.New(db)
	cfg.db = queries
	return
}
