package main

import (
	"flag"
	"log"
)

type cmdlineT struct {
	laddr              string // address to listen to
	caddr              string // address to connect to
	useMillis          bool
	minDelay, maxDelay int
}

var cmdline = getCmdLine()

func getCmdLine() (result cmdlineT) {
	flag.StringVar(&result.laddr, "listen", ":9090",
		"listen address, \":9090\" or \"localhost:9090\"")
	flag.StringVar(&result.caddr, "connect", ":8080",
		"connect address, \":8080\" or \"example.com:8080\"")
	flag.BoolVar(&result.useMillis, "millis", false,
		"intervals are in milliseconds not seconds")
	flag.IntVar(&result.minDelay, "min", 0, "minimum delay")
	flag.IntVar(&result.maxDelay, "max", 2, "maximum delay")
	flag.Parse()

	if result.minDelay > result.maxDelay ||
		result.minDelay < 0 || result.maxDelay < 0 {
		log.Fatal("Invalid min & max delays")
	}
	return
}
