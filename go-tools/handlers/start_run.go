package handlers

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"github.com/google/uuid"
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
				Note:        sql.NullString{String: "", Valid: false}, //will change later
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
