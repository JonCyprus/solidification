package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	cloudcfg "solidification/config_cloud"
	"solidification/handlers"
	"strings"
)

func main() {
	// Initialize config_cloud connections
	cfg := cloudcfg.InitializeCloudConfig()
	defer cfg.GetDB().Close()

	// Current band-aid for setting the parameters, will change to be in dif config and change depending on run type
	params, err := cloudcfg.UnmarshalRunParams()
	if err != nil {
		log.Fatalf("error unmarshalling params: %v", err.Error())
	}
	cfg.SetRunTemperature(params.Temperature)
	cfg.SetRunDensity(params.Density)
	cfg.SetRunVersion("Default")

	// Inject run info into SQL database still bandaid
	err = handlers.InvokeCommand("start-run", []string{"two-body"}, cfg)
	/*if err != nil {
		log.Fatalf("error starting new run: %v", err.Error())
	}*/
	if err != nil {
		fmt.Printf("error starting run: %v", err.Error())
	}

	// Start the REPL
	fmt.Println("Simulation file uploader REPL ready. Type 'help' or 'exit'.")

	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Print("> ")
		if !scanner.Scan() {
			fmt.Println("Error scanning input. Exiting.")
			break
		}

		// Get the command and the arguments
		input := strings.Fields(scanner.Text())
		cmd := strings.ToLower(input[0])
		var args []string
		if len(input) > 1 {
			args = input[1:]
		} else {
			args = []string{}
		}

		// Invoke the cmd from the input
		err = handlers.InvokeCommand(cmd, args, cfg)
		if err != nil {
			fmt.Println(err)
		}

	}
}
