package db_tests

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/google/uuid"
	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"log"
	"os"
	"reflect"
	"solidification/internal/database"
	"strings"
	"testing"
	"time"
)

func setupTestQueries(t *testing.T) (*database.Queries, func()) {
	t.Helper()

	// Load .env
	err := godotenv.Load("../../../.env")
	if err != nil {
		t.Fatal("Failed to load .env file")
	}

	// Database connection
	dbURL := os.Getenv("DB_URL")
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		t.Fatalf("Failed to connect to test DB: %v", err)
	}

	dbSchema := os.Getenv("SIMULATION_SCHEMA")
	_, err = db.ExecContext(context.Background(), fmt.Sprintf(`SET search_path TO "%s"`, dbSchema))
	if err != nil {
		t.Fatalf("error setting search_path to %s: %v\n", dbSchema, err)
	}

	// SQLC Query wrapper
	queries := database.New(db)

	// Cleanup function for database connection
	cleanup := func() {
		_ = db.Close()
	}
	return queries, cleanup
}

func TestCreateTwoBodyRow(t *testing.T) {
	// DB connection
	queries, cleanup := setupTestQueries(t)
	defer cleanup()

	// Current time and test parameters
	currentTime := time.Now().UTC() // DB stores as UTC

	temp := 1200.00
	density := 0.1364
	version := "unit testing"
	runID := uuid.New()
	note := sql.NullString{
		String: "this is a test note",
		Valid:  true,
	}

	// Do the Database Query
	results, err := queries.CreateTwoBodyRun(context.Background(),
		database.CreateTwoBodyRunParams{
			Temperature: temp,
			Density:     density,
			Version:     version,
			RunID:       runID,
			Note:        note,
			CreatedAt:   currentTime,
			UpdatedAt:   currentTime})

	// Check for Query Errors
	if err != nil {
		switch {
		case strings.Contains(strings.ToLower(err.Error()), "duplicate key"):
			t.Logf("duplicate key error occurred: %v", err)
			return
		default:
			log.Fatalf("insert failed: %v", err)
		}
	}

	// Check that the inputted result returns what is expected
	expected := database.TwobodyParameter{
		Temperature: temp,
		Density:     density,
		Version:     version,
		RunID:       runID,
		Note:        note,
		CreatedAt:   currentTime,
		UpdatedAt:   currentTime,
	}

	// Convert the timezones to be the same, not sure why but it is needed when getting the results back (timezone sync?)

	expected.CreatedAt = expected.CreatedAt.UTC()
	expected.UpdatedAt = expected.UpdatedAt.UTC()
	results.CreatedAt = results.CreatedAt.UTC()
	results.UpdatedAt = results.UpdatedAt.UTC()

	if !reflect.DeepEqual(expected, results) {
		t.Fatalf("result mismatch:\nExpected: %v\nGot: %v", expected, results)
	}
	return
}
