package handlers

import (
	"bufio"
	"context"
	"database/sql"
	"errors"
	"fmt"
	"github.com/google/uuid"
	"os"
	cloudcfg "solidification/config_cloud"
	"solidification/internal/database"
	"time"
)

func handlerStartRun(cfg *cloudcfg.CloudConfig, args []string) error {
	newID := uuid.New()
	cfg.SetRunID(newID)
	fmt.Println("New run ID set: ", newID.String())

	// Check for proper arguments
	if len(args) < 1 || args[0] != "one-body" && args[0] != "two-body" {
		return errors.New("usage: upload <one-body OR two-body> <filename.ext>")
	}

	// Get the version of simulation
	var version string
	if len(args) > 1 {
		version = args[1]
	} else {
		version = "latest"
	}
	cfg.SetRunVersion(version)
	// Get the note for the run
	fmt.Print("Enter a note: ")
	scanner := bufio.NewScanner(os.Stdin)
	if !scanner.Scan() {
		return errors.New("failed to read note from input")
	}
	note := scanner.Text()

	queries := cfg.GetDBQueries()

	// Update the sql record
	switch args[0] {
	case "one-body":
		return nil
	case "two-body":
		current := time.Now().UTC()
		_, err := queries.CreateTwoBodyRun(context.Background(),
			database.CreateTwoBodyRunParams{
				Temperature: cfg.GetRunTemperature(),
				Density:     cfg.GetRunDensity(),
				Version:     cfg.GetRunVersion(),
				RunID:       cfg.GetRunID(),
				Note:        sql.NullString{String: note, Valid: true}, //will change later
				CreatedAt:   current,
				UpdatedAt:   current,
			})
		if err != nil {
			return err
			//log.Fatal("Unable to create two body run: ", err)
		} else {
			fmt.Println("Created two body run: ", cfg.GetRunID())
		}
	}

	return nil
}
