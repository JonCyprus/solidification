package handlers

import "solidification/config_cloud"

// CLICommand struct and associated methods
type CLICommand struct {
	name        string
	description string
	callback    func(*config_cloud.CloudConfig, []string) error
}

// Selectors for CLICommand type

func (command *CLICommand) Name() string {
	return command.name
}

func (command *CLICommand) Description() string {
	return command.description
}

func (command *CLICommand) Invoke(cfg *config_cloud.CloudConfig, args []string) error {
	err := command.callback(cfg, args)
	return err
}
