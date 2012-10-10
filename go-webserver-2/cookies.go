package main

import (
	"crypto/rand"
	"math/big"
	"net/http"
)

const cookieName = "MoneyCookie"

var (
	// happens-before: don't access directly. Use the channels below.
	cookieToUser = make(map[string]string)

	cookieSetCh     chan<- cookieSetT
	cookieGetUserCh chan<- cookieGetUserT
	cookieRemoveCh  chan<- cookieRemoveT
	cookieQuitCh    chan<- cookieQuitT

	cookieMaxRand *big.Int
)

func init() {
	cookieMaxRand = big.NewInt(2)
	cookieMaxRand.Exp(cookieMaxRand, big.NewInt(64), nil)
}

// Not an init(), but started and closed together with the webserver.
// This way we don't leave the goroutine running if another init() panics.
func startCookieServer() {
	// forcing recv channels for server and send channels for the queries
	var (
		bidirSetCh    = make(chan cookieSetT)
		bidirGetCh    = make(chan cookieGetUserT)
		bidirRemoveCh = make(chan cookieRemoveT)
		bidirQuitCh   = make(chan cookieQuitT)
	)

	cookieSetCh = bidirSetCh
	cookieGetUserCh = bidirGetCh
	cookieRemoveCh = bidirRemoveCh
	cookieQuitCh = bidirQuitCh

	go cookieServer(bidirSetCh, bidirGetCh, bidirRemoveCh, bidirQuitCh)
}

func stopCookieServer() {
	ch := make(chan interface{})
	cookieQuitCh <- cookieQuitT{responseCh: ch}
	<-ch
}

// intended to be run as a goroutine
func cookieServer(setCh <-chan cookieSetT, getCh <-chan cookieGetUserT,
	removeCh <-chan cookieRemoveT, quitCh <-chan cookieQuitT) {
	one := big.NewInt(1)
	n := big.NewInt(0)
	for {
		select {
		case quitReq := <-quitCh:
			quitReq.responseCh <- true
			return
		case getReq := <-getCh:
			getReq.responseCh <- cookieToUser[getReq.cookie]
		case setReq := <-setCh:
			// Avoid collisions: if N1 was the cookie for User1
			// and the random generator just generated N1 again
			// for User2, on the next request both users would be
			// authenticated as User2.
			val := n.Add(n, one).String() + ":" + setReq.cookieRoot
			cookieToUser[val] = setReq.user
			setReq.responseCh <- val
		case remReq := <-removeCh:
			delete(cookieToUser, remReq.cookie)
			remReq.responseCh <- true
		}
	}
}

type (
	cookieSetT struct {
		user, cookieRoot string
		responseCh       chan<- string // the actual cookie value set
	}

	cookieGetUserT struct {
		cookie     string
		responseCh chan<- string
	}

	cookieRemoveT struct {
		cookie     string
		responseCh chan<- interface{}
	}

	cookieQuitT struct {
		responseCh chan<- interface{}
	}
)

// Username for cookie, or empty string
func getUser(r *http.Request) (user string) {
	if cmdline.singleuser != "" {
		return cmdline.singleuser
	}
	cookie, err := r.Cookie(cookieName)
	if err != nil {
		return ""
	}

	ch := make(chan string)
	cookieGetUserCh <- cookieGetUserT{cookie: cookie.Value, responseCh: ch}
	return <-ch
}

func isLoggedIn(r *http.Request) bool {
	return getUser(r) != ""
}

// Sets login cookie. On error, sends http.StatusInternalServerError to w.
func setLoginCookie(w http.ResponseWriter, user string) (success bool) {
	i, err := rand.Int(rand.Reader, cookieMaxRand)
	if err != nil {
		http.Error(w, "Internal server error: "+err.Error(),
			http.StatusInternalServerError)
		return false
	}
	ch := make(chan string)
	cookieSetCh <- cookieSetT{
		user:       user,
		cookieRoot: i.String(),
		responseCh: ch,
	}

	http.SetCookie(w, &http.Cookie{
		Name:  cookieName,
		Value: <-ch,
		Path:  "/",
	})
	return true
}

func removeCookie(r *http.Request) {
	cookie, err := r.Cookie(cookieName)
	if err != nil {
		return
	}

	ch := make(chan interface{})
	cookieRemoveCh <- cookieRemoveT{cookie: cookie.Value, responseCh: ch}
	<-ch
}
