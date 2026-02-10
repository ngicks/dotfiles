package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strconv"
)

func main() {
	args := os.Args[1:]

	var socketFlag string
	var projectFlag string

	// Parse flags
	for len(args) > 0 {
		switch args[0] {
		case "--socket":
			if len(args) < 2 {
				outputError("--socket requires a value")
				return
			}
			socketFlag = args[1]
			args = args[2:]
		case "--project":
			if len(args) < 2 {
				outputError("--project requires a value")
				return
			}
			projectFlag = args[1]
			args = args[2:]
		default:
			goto done
		}
	}
done:

	if len(args) == 0 {
		outputError("no command specified. Commands: definition, references, hover, symbols, diagnostics, health, server")
		return
	}

	command := args[0]
	args = args[1:]

	// Resolve project root
	projectRoot := projectFlag
	if projectRoot == "" {
		var err error
		projectRoot, err = DetectProjectRoot()
		if err != nil {
			outputError(fmt.Sprintf("detect project root: %v", err))
			return
		}
	}

	// Resolve socket
	socket := socketFlag
	if socket == "" {
		socket = os.Getenv("LSP_GW_SOCKET")
	}
	if socket == "" {
		socket = ProjectSocket(projectRoot)
	}

	switch command {
	case "server":
		handleServer(args, socket, projectRoot)
	case "health":
		handleQuery(socket, projectRoot, luaHealth)
	case "definition":
		handleLocationQuery(args, socket, projectRoot, luaGetDefinition, "definition <filepath> <line> <col>")
	case "references":
		handleLocationQuery(args, socket, projectRoot, luaGetReferences, "references <filepath> <line> <col>")
	case "hover":
		handleLocationQuery(args, socket, projectRoot, luaGetHover, "hover <filepath> <line> <col>")
	case "symbols":
		handleFileQuery(args, socket, projectRoot, luaGetDocumentSymbols, "symbols <filepath>")
	case "diagnostics":
		handleFileQuery(args, socket, projectRoot, luaGetDiagnostics, "diagnostics <filepath>")
	default:
		outputError(fmt.Sprintf("unknown command: %s", command))
	}
}

func handleServer(args []string, socket, projectRoot string) {
	if len(args) == 0 {
		outputError("server requires a subcommand: start, stop, status")
		return
	}

	switch args[0] {
	case "start":
		if err := StartServer(socket, projectRoot); err != nil {
			outputError(fmt.Sprintf("start server: %v", err))
			return
		}
		outputJSON(map[string]interface{}{"ok": true, "result": "server started"})
	case "stop":
		if err := StopServer(socket); err != nil {
			outputError(fmt.Sprintf("stop server: %v", err))
			return
		}
		outputJSON(map[string]interface{}{"ok": true, "result": "server stopped"})
	case "status":
		status := ServerStatus(socket)
		outputJSON(map[string]interface{}{"ok": true, "result": status})
	default:
		outputError(fmt.Sprintf("unknown server subcommand: %s", args[0]))
	}
}

func handleLocationQuery(args []string, socket, projectRoot, luaCode, usage string) {
	if len(args) < 3 {
		outputError(fmt.Sprintf("usage: lsp-gw %s", usage))
		return
	}

	filepath := args[0]
	line, err := strconv.Atoi(args[1])
	if err != nil {
		outputError(fmt.Sprintf("invalid line number: %s", args[1]))
		return
	}
	col, err := strconv.Atoi(args[2])
	if err != nil {
		outputError(fmt.Sprintf("invalid col number: %s", args[2]))
		return
	}

	handleQuery(socket, projectRoot, luaCode, filepath, line, col)
}

func handleFileQuery(args []string, socket, projectRoot, luaCode, usage string) {
	if len(args) < 1 {
		outputError(fmt.Sprintf("usage: lsp-gw %s", usage))
		return
	}

	handleQuery(socket, projectRoot, luaCode, args[0])
}

func handleQuery(socket, projectRoot, luaCode string, luaArgs ...interface{}) {
	if err := EnsureRunning(socket, projectRoot); err != nil {
		outputError(fmt.Sprintf("ensure server: %v", err))
		return
	}

	client, err := Connect(socket)
	if err != nil {
		outputError(fmt.Sprintf("connect: %v", err))
		return
	}
	defer client.Close()

	result, err := QueryGateway(client, luaCode, luaArgs...)
	if err != nil {
		outputError(fmt.Sprintf("query: %v", err))
		return
	}

	outputJSON(result)
}

func outputJSON(v interface{}) {
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	enc.Encode(v)
}

func outputError(msg string) {
	outputJSON(map[string]interface{}{
		"ok":    false,
		"error": msg,
	})
}
