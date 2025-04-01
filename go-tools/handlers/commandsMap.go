package handlers

// This file is for the initialization of all the REPL commands into a Commands map. If its not here it can't be used.

var Commands = map[string]CLICommand{}

func init() {
	Commands["help"] = CLICommand{
		name:        "help",
		description: "Shows all commands and their descriptions",
		callback:    handlerHelp,
	}

	Commands["exit"] = CLICommand{
		name:        "exit",
		description: "Exits all commands",
		callback:    handlerExit,
	}

}
