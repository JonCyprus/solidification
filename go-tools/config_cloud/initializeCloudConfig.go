package config_cloud

import (
	"context"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
	"log"
	"os"
)

func InitializeCloudConfig() *CloudConfig {
	// Load .env
	err := godotenv.Load(".env")
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	// Set up the s3 Client
	awsConfig, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(os.Getenv("S3_REGION")))
	if err != nil {
		log.Fatal("error initializing AWS config_cloud", err)
	}
	awsClient := s3.NewFromConfig(awsConfig)

	// Set up the sql connection and correct to the right schema
	dbURL := mustGetenv("DB_URL")
	db, err := pgx.Connect(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("error connecting to the sql: %v\n", err)
	}

	dbSchema := mustGetenv("SIMULATION_SCHEMA")
	_, err = db.Exec(context.Background(), fmt.Sprintf(`SET search_path TO "%s"`, dbSchema))
	if err != nil {
		log.Fatalf("error setting search_path to %s: %v\n", dbSchema, err)
	}

	// Load in other .env
	s3AccessKey := mustGetenv("AWS_ACCESS_KEY_ID")
	s3SecretAccess := mustGetenv("AWS_SECRET_ACCESS_KEY")
	s3Bucket := mustGetenv("S3_BUCKET")
	s3Region := mustGetenv("AWS_REGION")
	dataFilepath := mustGetenv("DATA_FILEPATH")

	// Set up the config_cloud struct
	cfg := CloudConfig{
		s3AccessKey:    s3AccessKey,
		s3SecretAccess: s3SecretAccess,
		s3Bucket:       s3Bucket,
		s3Region:       s3Region,
		s3Client:       awsClient,
		dataFilepath:   dataFilepath,
	}

	// Set the Queries part of the struct (using SQLC)
	cfg.SetDB(db)

	return &cfg
}

func mustGetenv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("%s environment variable not set", key)
	}
	return v
}
