package main

import (
	"log"
	"net/http"
)

var (
	authMux  = http.NewServeMux()
	sections = getSections()
)

func init() {
	for _, sec := range sections {
		authMux.Handle(sec.GetPath(), sec)
	}
}

func getSections() []siteSection {
	return []siteSection{
		&homeHandler{},
		&logoutHandler{},
		&quitHandler{},
	}
}

type siteSection interface {
	http.Handler

	// URL path
	GetPath() string

	// Label to show in navigation, empty string to hide from navigation
	GetNavLabel() string
}

type homeHandler struct{}

func (*homeHandler) GetPath() string {
	return "/"
}

func (*homeHandler) GetNavLabel() string {
	return ""
}

func (*homeHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	conn, err := getDb(getUser(r))
	if err != nil {
		http.Error(w, "Error opening database: "+err.Error(),
			http.StatusInternalServerError)
		return
	}
	defer func() {
		err := conn.Close()
		if err != nil {
			log.Println("Error closing DB:", err)
		}
	}()

	err = create_tables_if_missing(conn)
	if err != nil {
		http.Error(w, "Error opening database: "+err.Error(),
			http.StatusInternalServerError)
		return
	}

	templ.ExecuteTemplate(w, "home", map[string]interface{}{
		"sections": sections,
	})
}

type logoutHandler struct{}

func (*logoutHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	removeCookie(r)
	templ.ExecuteTemplate(w, "logout", map[string]interface{}{
		"title": "Logout – Money Trail",
	})
}

func (*logoutHandler) GetPath() string {
	return "/logout/"
}

func (*logoutHandler) GetNavLabel() string {
	return "Logout"
}

type quitHandler struct{}

func (*quitHandler) GetPath() string {
	return "/quit/"
}

func (*quitHandler) GetNavLabel() string {
	return "Quit"
}

func (*quitHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ok := canShutdown(getUser(r))
	templ.ExecuteTemplate(w, "quit", map[string]interface{}{
		"title":       "Quit – Money Trail",
		"canShutdown": ok,
	})
	if ok {
		wsListener.Close()
	}
}
