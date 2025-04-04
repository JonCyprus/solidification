package handlers

import (
	"errors"
	"fmt"
	cloudcfg "solidification/config_cloud"
	"solidification/handlers/search"
	"strings"
)

func handlerSearch(cfg *cloudcfg.CloudConfig, args []string) error {
	if len(args) < 1 {
		return errors.New("usage: search <command> [use 'search help' for list of commands and usage]")
	}

	err := search.InvokeSearchCommand(strings.ToLower(args[0]), args[1:], cfg)
	if err != nil {
		return fmt.Errorf("could not execute command '%s': %w", args[0], err)
	}

	return nil
}
