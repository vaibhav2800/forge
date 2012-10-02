package main

import (
	"flag"
)

type cmdlineArgsT struct {
	addr    string
	posArgs []string
}

var cmdlineArgs cmdlineArgsT

func init() {
	flag.StringVar(&cmdlineArgs.addr, "addr", ":8000", "addr to listen on")
	flag.Parse()
	cmdlineArgs.posArgs = flag.Args()
}
