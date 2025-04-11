package socket

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"solidification/config_cloud"
)

func StartSocketListener(cfg *config_cloud.CloudConfig) {
	socketPort := os.Getenv("SOCKET_PORT")
	listener, err := net.Listen("tcp", "127.0.0.1:"+socketPort)
	if err != nil {
		panic(err)
	}
	fmt.Println("Socket REPL listening on 127.0.0.1:" + socketPort)

	conn, _ := listener.Accept()
	cfg.SetScanner(bufio.NewScanner(conn))
}
