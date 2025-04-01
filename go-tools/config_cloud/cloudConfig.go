package config_cloud

import (
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/jackc/pgx/v5"
)

// CloudConfig struct type for holding db connections and s3 relevant info
type CloudConfig struct {
	s3AccessKey    string
	s3SecretAccess string
	s3Bucket       string
	s3Region       string
	dataFilepath   string
	db             *pgx.Conn
	s3Client       *s3.Client
}

// Selectors

func (cfg *CloudConfig) GetDB() *pgx.Conn {
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
