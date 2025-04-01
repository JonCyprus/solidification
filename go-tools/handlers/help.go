package handlers

import (
	"fmt"
	"solidification/config_cloud"
)

// This command prints out all the registered commands in the global command map, name and description.
func handlerHelp(cfg *config_cloud.CloudConfig, args []string) error {
	for _, command := range Commands {
		fmt.Printf("%v: %v\n", command.name, command.description)
	}
	return nil
}
