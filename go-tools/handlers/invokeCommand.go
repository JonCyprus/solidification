package handlers

import (
	"fmt"
	cloudcfg "solidification/config_cloud"
)

// This function is meant to interface with the main script to abstract away execution and retrieval logic of commands

func InvokeCommand(txtCmd string, args []string, config *cloudcfg.CloudConfig) error {
	// Get the cmd from the command map
	cmd, ok := Commands[txtCmd]
	if !ok {
		return fmt.Errorf("unknown command '%s'", txtCmd)
	}

	// Invoke the commands
	err := cmd.Invoke(config, args)
	return err
}
