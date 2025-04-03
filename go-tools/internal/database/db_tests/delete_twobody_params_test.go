package db_tests

import (
	"context"
	"database/sql"
	"errors"
	"github.com/google/uuid"
	"solidification/internal/database"
	"testing"
	"time"
)

func createTwoBodyTestRow(t *testing.T) (*database.Queries, func(), uuid.UUID) {
	t.Helper()

	queries, cleanup := setupTestQueries(t)

	// Current time and test parameters
	currentTime := time.Now().UTC() // DB stores as UTC

	temp := 1200.00
	density := 0.1364
	version := "unit testing for deletion"
	runID := uuid.New()
	note := sql.NullString{
		String: "this is a test note for deletion",
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

	if err != nil {
		t.Fatalf("Failed to create twobody params row: %v", err)
	}

	return queries, cleanup, results.RunID
}

/*
func TestDeleteTwoBodyRuns(t *testing.T) {
	queries, cleanup, _ := createTwoBodyTestRow(t)
	defer cleanup()

	// Delete Query
	err := queries.WipeTwoBodyTable(context.Background())
	if err != nil {
		t.Fatalf("Failed to wipe twobody rows: %v", err)
	}

	// Check if it was deleted
	rows, err := queries.ListAllTwoBodyParams(context.Background())
	if err != nil {
		t.Fatalf("Failed to get twobody rows: %v", err)
	}
	if len(rows) != 0 {
		t.Fatalf("All rows must be deleted")
	}
	return
}
*/ // The above function test passes, but let's not delete all the runs on our future tables haha

func TestDeleteTwoBodyRunByID(t *testing.T) {
	queries, cleanup, runID := createTwoBodyTestRow(t)
	defer cleanup()

	// Delete Query
	_, err := queries.RemoveRunByID(context.Background(), runID)
	if err != nil {
		t.Fatalf("Failed to wipe twobody rows: %v", err)
	}

	// Check if it was deleted
	_, err = queries.SelectTwoBodyParamByRunID(context.Background(), runID)
	if err == nil {
		t.Fatalf("Expected no row after deletion, but found one")
	} else if !errors.Is(err, sql.ErrNoRows) {
		t.Fatalf("Unexpected DB error: %v", err)
	}

	return
}
