package main

import (
	"bufio"
	"crypto/sha1"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"path"
)

var (
	usersFile  = path.Join(cmdline.dir, "users.json")
	userToHash = loadUsers()
)

// JSON requires exported fields
type userAttrs struct {
	PassHash    string
	CanShutdown bool
}

func loadUsers() (result map[string]userAttrs) {
	if cmdline.singleuser != "" {
		return result
	}

	f, err := os.Open(usersFile)
	if err != nil {
		log.Fatalln("Error opening", usersFile, err)
	}

	err = json.NewDecoder(bufio.NewReader(f)).Decode(&result)
	if err != nil {
		log.Fatalln("Error decoding", usersFile, err)
	}
	return result
}

func checkPass(user, pass string) bool {
	attrs, ok := userToHash[user]
	if !ok {
		return false
	}

	h := sha1.New()
	io.WriteString(h, pass)
	return attrs.PassHash == fmt.Sprintf("%x", h.Sum(nil))
}

func canShutdown(user string) bool {
	if cmdline.singleuser != "" {
		return true
	}

	// zero value is safe (boolean false) if user or field is missing
	return userToHash[user].CanShutdown
}
