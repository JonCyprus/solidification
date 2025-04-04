package handlers

import (
	"errors"
	cloudcfg "solidification/config_cloud"
	"solidification/handlers/search"
	"strings"
)

func handlerSearch(cfg *cloudcfg.CloudConfig, args []string) error {
	if len(args) < 1 || args[0] != "two-body" && args[0] != "one-body" && args[0] != "help" {
		return errors.New("usage: search <one-body OR two-body> <commands> [use 'search help' for list of commands and usage]")
	}

	if strings.ToLower(args[0]) == "help" {
		search.InvokeSearchCommand("help", args, cfg)
	}

	/*searchCmd, ok := search.SearchingCommands[args[1]]
	if !ok {
		return errors.New("search sub command ")
	}*/return nil
}
