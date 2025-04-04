package search

import (
	"fmt"
	cloudcfg "solidification/config_cloud"
)

func searchHelp(cfg *cloudcfg.CloudConfig, args []string) error {
	for _, cmd := range searchingCommands {
		fmt.Printf("Name: %v  |  Usage: %v\nDescription: %v\n\n", cmd.Name(), cmd.Usage(), cmd.Description())
	}
	return nil

}
