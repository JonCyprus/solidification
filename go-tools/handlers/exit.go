package handlers

import (
	"errors"
	"fmt"
	"os"
	cloudcfg "solidification/config_cloud"
)

// This is to exit the REPL at the end of use

func handlerExit(cfg *cloudcfg.CloudConfig, args []string) error {
	if len(args) != 0 {
		return errors.New("usage: exit")
	}

	fmt.Println("Exiting simulation file handler...")
	os.Exit(0)
	return nil // req for signature
}
