package main

import (
	"crypto/tls"
	"fmt"
	"net"
	"net/http"
	"path"
	"time"
)

const (
	loginPath = "/login/"
	pubPath   = "/pub/"
)

var (
	wsListener    net.Listener
	gateKeeperMux = http.NewServeMux()
)

func init() {
	gateKeeperMux.HandleFunc("/", rootGkHandleFunc)
	gateKeeperMux.HandleFunc(loginPath, loginHandleFunc)

	pubDir := path.Join(cmdline.dir, "pub")
	gateKeeperMux.Handle(pubPath,
		http.StripPrefix(pubPath, http.FileServer(http.Dir(pubDir))))
}

func rootGkHandleFunc(w http.ResponseWriter, r *http.Request) {
	if !isLoggedIn(r) {
		http.Redirect(w, r, loginPath, http.StatusFound)
		return
	}
	authMux.ServeHTTP(w, r)
}

func loginHandleFunc(w http.ResponseWriter, r *http.Request) {
	err := r.ParseForm()
	if err != nil {
		http.Error(w, "Error parsing form: "+err.Error(),
			http.StatusBadRequest)
		return
	}

	templData := map[string]interface{}{
		"title":     "Login – Money Trail",
		"loginPath": loginPath,
	}

	if r.Method == "POST" {
		user, pass := r.FormValue("user"), r.FormValue("pass")
		if checkPass(user, pass) {
			if !setLoginCookie(w, user) {
				return
			}
			http.Redirect(w, r, "/", http.StatusFound)
			return
		} else {
			removeCookie(r)
			templData["badLogin"] = true
		}
	} else if isLoggedIn(r) {
		http.Redirect(w, r, "/", http.StatusFound)
		return
	}

	templ.ExecuteTemplate(w, "login", templData)
}

func startWebserver() (err error) {
	server := http.Server{Handler: gateKeeperMux}
	if cmdline.tls {
		// copied from net.http ListenAndServeTLS()
		// so we have a reference to the Listener to close it on /quit/
		config := &tls.Config{}
		config.NextProtos = []string{"http/1.1"}
		config.Certificates = make([]tls.Certificate, 1)
		config.Certificates[0], err =
			tls.LoadX509KeyPair(cmdline.cert, cmdline.key)
		if err != nil {
			return
		}
		wsListener, err = net.Listen("tcp", cmdline.laddr)
		if err != nil {
			return
		}
		wsListener = tls.NewListener(wsListener, config)
	} else {
		wsListener, err = net.Listen("tcp", cmdline.laddr)
		if err != nil {
			return
		}
	}

	startCookieServer()
	err = server.Serve(wsListener)
	stopCookieServer()

	fmt.Println("Shutting down in", cmdline.quittimeout, "second(s)...")
	time.Sleep(time.Duration(cmdline.quittimeout) * time.Second)

	return err
}
