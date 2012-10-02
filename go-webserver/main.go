package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
	"strings"
	"time"
)

var listener net.Listener
var gateKeeperMux = http.NewServeMux()

func init() {
	gateKeeperMux.HandleFunc("/", rootGkFunc)
	gateKeeperMux.HandleFunc("/login/", loginGkFunc)
	gateKeeperMux.HandleFunc("/quit/", quitGkFunc)
}

func rootGkFunc(w http.ResponseWriter, r *http.Request) {
	c, err := r.Cookie("mycookie")
	if err != nil {
		http.Redirect(w, r, "/login/", http.StatusFound)
		return
	}
	fmt.Fprintln(w, "Cookie value:", c.Value)
}

func loginGkFunc(w http.ResponseWriter, r *http.Request) {
	http.SetCookie(w, &http.Cookie{
		Name:  "mycookie",
		Value: strings.Replace(time.Now().String(), " ", "_", -1),
		Path:  "/",
	})
	c, err := r.Cookie("mycookie")
	if err == nil {
		fmt.Fprintln(w, "Cookie value:", c.Value)
	}
}

func quitGkFunc(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Quitting")
	go func() {
		fmt.Println("Will close listener after sleeping")
		time.Sleep(7 * time.Second)
		err := listener.Close()
		if err != nil {
			log.Print(err)
		}
		fmt.Println("Listener was closed")
	}()
}

func main() {
	fmt.Println(cmdlineArgs.addr, cmdlineArgs.posArgs)
	var err error
	listener, err = net.Listen("tcp", cmdlineArgs.addr)
	if err != nil {
		log.Fatal(err)
	}

	server := http.Server{Handler: gateKeeperMux}
	err = server.Serve(listener)
	if err != nil {
		log.Print(err)
	}
}
