package handlers

import (
	"errors"
	"fmt"
	"path/filepath"
	cloudcfg "solidification/config_cloud"
)

func handlerUpload(cfg *cloudcfg.CloudConfig, args []string) error {
	if len(args) != 2 {
		return errors.New("usage: upload <one-body OR two-body> <filename.ext>")
	}

	// Check for proper arguments
	if args[0] != "one-body" && args[0] != "two-body" {
		return errors.New("usage: upload <one-body OR two-body> <filename.ext>")
	}

	ext := filepath.Ext(args[1])
	if !validExts[ext] {
		return fmt.Errorf("unsupported file extension: %s", ext)
	}
	//filename := args[1]

	// Update the sql record
	return nil

}

var validExts = map[string]bool{
	".jpg":  true,
	".jpeg": true,
	".mat":  true,
}
