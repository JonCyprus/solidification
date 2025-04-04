package search

import (
	"context"
	"errors"
	"fmt"
	cloudcfg "solidification/config_cloud"
)

// Include pagination later on to make it easier if you have a bajillion runs
func searchAllRuns(cfg *cloudcfg.CloudConfig, args []string) error {
	if len(args) < 1 {
		return errors.New("usage: search <one-body OR two-body> -t [optional flag to show times]")
	}

	// Currently no flag support so just list without time
	err := handleListAllTwoBodyRuns(cfg)
	if err != nil {
		return err
	}
	return nil
}

func handleListAllTwoBodyRuns(cfg *cloudcfg.CloudConfig) error {
	results, err := cfg.GetDBQueries().ListAllTwoBodyParams(context.Background())
	if err != nil {
		return fmt.Errorf("failed to fetch rows: %w", err)
	}

	if len(results) == 0 {
		fmt.Println("No results found.")
		return nil
	}

	for _, row := range results {
		fmt.Printf("\nTemp: %.2f, Density: %.4f, Version: %s | RunID: %s | Note: %s\n",
			row.Temperature, row.Density, row.Version, row.RunID, row.Note)
		//fmt.Println("---------------------------------------------------------------------------------------------")
		for _ = range 150 {
			fmt.Print("-")
		}
		fmt.Print("\n")
	}

	return nil
}
