package config_cloud

import (
	"encoding/json"
	"errors"
	"os"
)

func UnmarshalRunParams() (RunParams, error) {
	path := os.Getenv("PARAM_FILEPATH") // assumes gotdotenv.Load has been called already
	if path == "" {
		return RunParams{}, errors.New("PARAM_FILEPATH environment variable not set")
	}

	// Create a reader
	data, err := os.ReadFile(path)
	if err != nil {
		return RunParams{}, err
	}

	var runParams RunParams

	err = json.Unmarshal(data, &runParams)
	if err != nil {
		return RunParams{}, err
	}

	return runParams, nil
}

type RunParams struct {
	Temperature float64 `json:"temperature"`
	Density     float64 `json:"density"` // Must be set into the JSON at runtime from the MATLAB script
}
