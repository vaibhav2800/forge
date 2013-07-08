package main

import (
	"flag"
	"log"
)

type cmdlineT struct {
	laddr                      string // address to listen to
	caddr                      string // address to connect to
	minPreDelay, maxPreDelay   int
	minPostDelay, maxPostDelay int
	bufsize                    int
}

var cmdline = getCmdLine()

func getCmdLine() (result cmdlineT) {
	flag.StringVar(&result.laddr, "listen", ":9090",
		"listen address, \":9090\" or \"localhost:9090\"")
	flag.StringVar(&result.caddr, "connect", ":8080",
		"connect address, \":8080\" or \"example.com:8080\"")
	flag.IntVar(&result.minPreDelay, "minpre", 0,
		"minimum pre delay (before any data is transmitted)")
	flag.IntVar(&result.maxPreDelay, "maxpre", 0,
		"maximum pre delay (before any data is transmitted)")
	flag.IntVar(&result.minPostDelay, "minpost", 0,
		"minimum post delay (before each chunk of data, "+
			"except the first, is transmitted)")
	flag.IntVar(&result.maxPostDelay, "maxpost", 0,
		"maximum post delay (before each chunk of data, "+
			"except the first, is transmitted)")
	flag.IntVar(&result.bufsize, "bufsize", 1024,
		"size of the buffer used to transmit data, in bytes")
	flag.Parse()

	if result.minPreDelay > result.maxPreDelay ||
		result.minPreDelay < 0 || result.maxPreDelay < 0 {
		log.Fatal("Invalid min & max pre delays")
	}
	if result.minPostDelay > result.maxPostDelay ||
		result.minPostDelay < 0 || result.maxPostDelay < 0 {
		log.Fatal("Invalid min & max post delays")
	}
	return
}
