package handlers

import (
	"context"
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"log"
	"os"
	"path/filepath"
	cloudcfg "solidification/config_cloud"
	"solidification/internal/database"
	"solidification/s3utils"
	"strconv"
	"time"
)

func handlerUpload(cfg *cloudcfg.CloudConfig, args []string) error {
	if len(args) != 4 {
		return errors.New("usage: upload <one-body OR two-body> <file category> <timestep> <filename.ext>")
	}

	// Check for proper arguments
	if args[0] != "one-body" && args[0] != "two-body" {
		return errors.New("usage: upload <one-body OR two-body> <filename.ext>")
	}

	// Get the category for the file (figure 1/2/mat etc)
	category := args[1]

	// Get the timestep of the file
	timeStep := mustParseTimestep(args[2])

	// Check filetype
	ext := filepath.Ext(args[3])
	if !validExts[ext] {
		return fmt.Errorf("unsupported file extension: %s", ext)
	}
	filename := args[3]

	// Current time
	current := time.Now().UTC()

	// File to upload
	fileLoc := filepath.Join(cfg.GetDataFilepath(), filename)
	uploadFile, err := os.Open(fileLoc)
	if err != nil {
		return errors.New("Failed to open file to upload: " + err.Error())
	}
	defer uploadFile.Close()

	// Upload the file to s3 bucket
	fullKey := cfg.GetRunID().String() + "/" + category + "/" + fmt.Sprintf("%v_", timeStep) + filename // full filepath on the s3 bucket
	_, err = cfg.GetS3Client().PutObject(context.Background(), &s3.PutObjectInput{
		Bucket:      aws.String(cfg.GetS3Bucket()),
		Key:         aws.String(fullKey),
		Body:        uploadFile,
		ContentType: aws.String(detectMimeType(ext)),
	})

	if err != nil {
		return errors.New("Failed to upload file to S3:  " + err.Error())
	}
	fmt.Printf("Successfully uploaded %s to %s\n", filename, fullKey)

	// Update the sql record
	queries := cfg.GetDBQueries()
	_, err = queries.CreateTwoBodyFile(context.Background(), database.CreateTwoBodyFileParams{
		RunID:     cfg.GetRunID(),
		Category:  category,
		Timestep:  timeStep,
		Filename:  fullKey,
		CreatedAt: current,
		UpdatedAt: current,
	})

	// If the query fails then delete the s3 item and return an error
	if err != nil {
		// try to delete the s3 object up to 10 times
		var s3Err error
		for tryCounter := 0; tryCounter < 10; tryCounter++ {
			s3Err = s3utils.DeleteS3Object(cfg.GetS3Client(), cfg.GetS3Bucket(), fullKey)
			if s3Err == nil {
				break
			}
		}

		// If it still fails after 10 tries
		if s3Err != nil {
			errorMsg := fmt.Sprintf("upload to SQL failed & failed to delete S3 object after 10 tries. %s is orphaned in S3: ", fullKey)
			return errors.New(errorMsg + s3Err.Error())
		}

		// If delete succeeded but SQL failed
		return errors.New("upload to SQL database failed (S3 object deleted): " + err.Error())
	}

	return nil
}

func mustParseTimestep(arg string) int64 {
	t, err := strconv.ParseInt(arg, 10, 64)
	if err != nil {
		log.Fatalf("Expected numeric timestep, got '%s'", arg)
	}
	return t
}

func detectMimeType(ext string) string {
	switch ext {
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".mat":
		return "application/octet-stream"
	default:
		return "application/octet-stream"
	}
}

// No .pngs, if too much storage starts being used then I would like to use compression algorithms on the .jpgs.
var validExts = map[string]bool{
	".jpg":  true,
	".jpeg": true,
	".mat":  true,
}
