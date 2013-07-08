package main

import (
	"log"
	"net"
)

func main() {
	l, err := net.Listen("tcp", cmdline.laddr)
	if err != nil {
		log.Fatal(err)
	}

	for {
		var conn net.Conn
		conn, err = l.Accept()
		if err != nil {
			log.Print(err)
			continue
		}

		handleAsync(conn)
	}
}
