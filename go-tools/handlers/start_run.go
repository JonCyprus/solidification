package handlers

import (
	"fmt"
	"github.com/google/uuid"
	cloudcfg "solidification/config_cloud"
)

func handlerStartRun(cfg *cloudcfg.CloudConfig, args []string) error {
	newID := uuid.New()
	cfg.SetRunID(newID)
	fmt.Println("New run ID set: ", newID.String())
	return nil
}
