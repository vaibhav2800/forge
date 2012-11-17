package main

import (
	"io"
	"log"
	"math/rand"
	"net"
	"time"
)

const bufsize = 1024

func delay() {
	t := cmdline.minDelay +
		rand.Intn(cmdline.maxDelay-cmdline.minDelay+1)

	var d time.Duration
	if cmdline.useMillis {
		d = time.Millisecond
	} else {
		d = time.Second
	}
	time.Sleep(time.Duration(t) * d)
}

func pipe(r io.Reader, w io.Writer) {
	var err error
	defer func() {
		if err != nil && err != io.EOF {
			log.Print(err)
		}
	}()

	buf := make([]byte, bufsize)
	for {
		var n int
		n, err = r.Read(buf)
		if err != nil {
			return
		}

		_, err = w.Write(buf[:n])
		if err != nil {
			return
		}
	}
}

func handleSync(conn net.Conn) {
	var err error
	defer func() {
		if err != nil {
			log.Print(err)
		}
	}()

	defer func() {
		err2 := conn.Close()
		if err == nil {
			err = err2
		}
	}()

	conn2, err := net.Dial("tcp", cmdline.caddr)
	if err != nil {
		return
	}
	defer func() {
		err2 := conn2.Close()
		if err != nil {
			err = err2
		}
	}()

	delay()

	ch := make(chan bool)
	go func() {
		pipe(conn, conn2)
		ch <- true
	}()
	go func() {
		pipe(conn2, conn)
		ch <- true
	}()
	<-ch
	<-ch
}

func handleAsync(conn net.Conn) {
	go handleSync(conn)
}
