package main

import (
	"flag"
	"fmt"
	"log"
	"os"
)

type cmdlineT struct {
	laddr       string // address to listen on
	dir         string // data dir
	tls         bool
	cert, key   string
	singleuser  string
	quittimeout int
}

var cmdline = getCmdLine() // other global vars depend on this one

func getCmdLine() (result cmdlineT) {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
		fmt.Fprintln(os.Stderr,
			"\t[options] datadir [cert.pem key.pem]")
		flag.PrintDefaults()
	}

	flag.StringVar(&result.laddr, "listen", ":8000",
		"listen address, \":8080\" or \"localhost:5050\"")
	flag.BoolVar(&result.tls, "tls", false, "use TLS. "+
		"Requires cert.pem and key.pem positional args "+
		"(see crypto/tls/generate_cert.go).")
	flag.StringVar(&result.singleuser, "singleuser", "",
		"Always logged in as specified user, without password")
	flag.IntVar(&result.quittimeout, "quittimeout", 1,
		"seconds to wait when shutting down")
	flag.Parse()

	if !result.tls {
		if flag.NArg() != 1 {
			log.Fatalln("Expecting 1 positional arg, found",
				flag.NArg())
		}
	} else {
		if flag.NArg() != 3 {
			log.Fatalln("TLS requires 3 positional args, found",
				flag.NArg())
		}
		result.cert = flag.Arg(1)
		result.key = flag.Arg(2)
	}
	result.dir = flag.Arg(0)
	return
}
