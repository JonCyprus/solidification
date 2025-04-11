package handlers

import (
	cloudcfg "solidification/config_cloud"
	"strings"
)

// This function handles the input from any reader so that it can be abstracted away

func HandleInput(inputText string, config *cloudcfg.CloudConfig) error {
	input := strings.Fields(inputText)

	var cmd string
	if len(input) > 0 {
		cmd = strings.ToLower(input[0])
	} else {
		cmd = "help"
	}

	var args []string
	if len(input) > 1 {
		args = input[1:]
	} else {
		args = []string{}
	}

	// Invoke the cmd from the input
	err := InvokeCommand(cmd, args, config)
	if err != nil {
		return err
	}

	return nil
}
