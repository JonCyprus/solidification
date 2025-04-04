package handlers

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"os"
	cloudcfg "solidification/config_cloud"
	"solidification/s3utils"
	"strings"
)

// THIS FUNCTION IS ONLY FOR DEV USE
func handlerFullDataReset(cfg *cloudcfg.CloudConfig, args []string) error {
	// Get confirmation that this is what you really want to do
	dbName, schema, err := getDatabaseAndSchema(cfg)
	fmt.Printf("This will wipe all databases of %s.%s, and associated s3utils bucket %s are you POSITIVE? [Yes] to Confirm. ", dbName, schema, cfg.GetS3Bucket())
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	if strings.ToLower(scanner.Text()) != "yes" {
		fmt.Println("Exiting command")
		return nil
	}

	// Reset the databases
	err = cfg.GetDBQueries().WipeTwoBodyTable(context.Background())
	if err != nil {
		return errors.New("failed to reset twobody_params table" + err.Error())
	}
	fmt.Println("twobody_params table wiped")

	err = cfg.GetDBQueries().WipeTwoBodyFiles(context.Background()) // Technically unnecessary due to CASCADE DELETE
	if err != nil {
		return errors.New("failed to reset twobody_filepaths" + err.Error())
	}
	fmt.Println("twobody_filepaths table wiped")

	// Reset the S3 bucket
	err = s3utils.WipeS3Bucket(cfg.GetS3Client(), cfg.GetS3Bucket())
	if err != nil {
		return errors.New("failed to reset s3utils bucket" + err.Error())
	}
	return nil
}

func getDatabaseAndSchema(cfg *cloudcfg.CloudConfig) (string, string, error) {
	var dbName, schemaName string

	db := cfg.GetDB()
	err := db.QueryRow("SELECT current_database()").Scan(&dbName)
	if err != nil {
		return "", "", fmt.Errorf("failed to get database name: %w", err)
	}

	err = db.QueryRow("SELECT current_schema()").Scan(&schemaName)
	if err != nil {
		return "", "", fmt.Errorf("failed to get schema name: %w", err)
	}

	return dbName, schemaName, nil
}
