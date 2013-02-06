package main

import (
	"io"
	"log"
	"math/rand"
	"net"
	"time"
)

func delay(min, max int) {
	t := min + rand.Intn(max-min+1)

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

	firstChunk := true
	buf := make([]byte, cmdline.bufsize)
	for {
		var n int
		n, err = r.Read(buf)
		if n <= 0 {
			return
		}

		if firstChunk {
			firstChunk = false
		} else {
			delay(cmdline.minPostDelay, cmdline.maxPostDelay)
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
		if err == nil {
			err = err2
		}
	}()

	delay(cmdline.minPreDelay, cmdline.maxPreDelay)

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
