package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"os"
	cloudcfg "solidification/config_cloud"
	"solidification/handlers"
	pjsock "solidification/socket"
)

var socketMode = flag.Bool("socket", false, "Run in socket mode (listen for MATLAB commands)")

func main() {
	flag.Parse()

	// Initialize config_cloud connections
	cfg := cloudcfg.InitializeCloudConfig()
	defer cfg.GetDB().Close()

	// Initialize socket connection/ scanner
	if *socketMode {
		fmt.Println("Running in SOCKET mode")
		pjsock.StartSocketListener(cfg)
	} else {
		fmt.Println("Running in CLI mode")
		cfg.SetScanner(bufio.NewScanner(os.Stdin))
	}

	// Current band-aid for setting the parameters, will change to be in dif config and change depending on run type
	params, err := cloudcfg.UnmarshalRunParams()
	if err != nil {
		log.Fatalf("error unmarshalling params: %v", err.Error())
	}
	cfg.SetRunTemperature(params.Temperature)
	cfg.SetRunDensity(params.Density)

	// Start the REPL
	fmt.Print("\n")
	fmt.Println("Simulation file handler REPL ready. Type 'help' or 'exit'.")

	scanner := cfg.GetInputScanner()
	for {
		fmt.Print("> ")
		if !scanner.Scan() {
			fmt.Println("Error scanning input. Exiting.")
			break
		}

		// Get the command and the arguments
		line := scanner.Text()
		err = handlers.HandleInput(line, cfg)
		if err != nil {
			fmt.Printf(err.Error())
		}

	}
}
