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
		description: "Exits file uploader",
		callback:    handlerExit,
	}

	Commands["start-run"] = CLICommand{
		name:        "start-run",
		description: "Initializes cfg with UUID for cloud services",
		callback:    handlerStartRun,
	}

	Commands["upload"] = CLICommand{
		name:        "upload",
		description: "Uploads a file to neon-postgres and s3utils bucket",
		callback:    handlerUpload,
	}

	Commands["dev-full-reset"] = CLICommand{
		name:        "dev-full-reset",
		description: "Resets all files from neon-postgres and s3utils bucket",
		callback:    handlerFullDataReset,
	}
}
