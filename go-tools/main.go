package main

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/jackc/pgx/v5"
	"github.com/joho/godotenv"
	"log"
	"os"
)

type cloudConfig struct {
	s3AccessKey    string
	s3SecretAccess string
	s3Bucket       string
	s3Region       string
	db             *pgx.Conn
	s3Client       *s3.Client
}

func main() {
	// Load .env
	err := godotenv.Load(".env")
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	// Set up the s3 Client
	awsConfig, err := config.LoadDefaultConfig(context.Background(), config.WithRegion(os.Getenv("S3_REGION")))
	if err != nil {
		log.Fatal("error initializing AWS config", err)
	}
	awsClient := s3.NewFromConfig(awsConfig)

	// Set up the database connection
	dbURL := os.Getenv("DB_URL")
	if dbURL == "" {
		log.Fatal("DB_URL environment variable not set")
	}
	db, err := pgx.Connect(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("error connecting to the database: %v\n", err)
	}
	defer db.Close(context.Background())

	// Set up the struct
	cloudConfig :=


}
