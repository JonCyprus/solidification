package search

import (
	"fmt"
	cloudcfg "solidification/config_cloud"
)

// Simple dispatching system for the search functionality

// Sub Command type
type searchingSubCommand struct {
	name        string
	description string
	usage       string
	callback    func(*cloudcfg.CloudConfig, []string) error
}

// Selectors and way to invoke callback

func (cmd *searchingSubCommand) Name() string {
	return cmd.name
}
func (cmd *searchingSubCommand) Description() string {
	return cmd.description
}
func (cmd *searchingSubCommand) Usage() string {
	return cmd.usage
}

func (cmd *searchingSubCommand) Invoke(cfg *cloudcfg.CloudConfig, args []string) error {
	err := cmd.callback(cfg, args)
	return err
}

// This function is meant to interface with the search handler  to abstract away execution and retrieval logic of commands

func InvokeSearchCommand(txtCmd string, args []string, config *cloudcfg.CloudConfig) error {
	// Get the cmd from the command map
	cmd, ok := searchingCommands[txtCmd]
	if !ok {
		return fmt.Errorf("unknown search command '%s'; try 'search help'", txtCmd)
	}

	// Invoke the command
	err := cmd.Invoke(config, args)
	return err
}

// Map of subcommands for dispatching

var searchingCommands = map[string]searchingSubCommand{}

func init() {
	searchingCommands["help"] = searchingSubCommand{
		name:        "help",
		usage:       "search help",
		description: "prints out all search commands; specify the simulation type for data retrieval as first argument after command",
		callback:    searchHelp,
	}

	searchingCommands["all"] = searchingSubCommand{
		name:        "all",
		usage:       "search all [optional]-t",
		description: "gives all results for table of runs, -t includes the created at and updated at information per run",
		callback:    searchAllRuns,
	}
}
