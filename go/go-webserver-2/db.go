package main

import (
	"code.google.com/p/gosqlite/sqlite"
	"io/ioutil"
	"log"
	"path"
	"strings"
)

var (
	dbDir            = path.Join(cmdline.dir, "db")
	createTablesFile = path.Join(dbDir, "create-tables.sql")
)

// Get connection to db for user. Remeber to close it.
func getDb(user string) (*sqlite.Conn, error) {
	return sqlite.Open(path.Join(dbDir, user+".sqlite"))
}

// HACK to execute a script file. Python3 has a helper executescript(..).
// Don't know the way to do it in the C API. Maybe sqlite3_complete(..) helps
// by extending the current substring until the following semicolon, until
// it says the query is complete (you can also have semicolons in strings).
// Execute and repeat. Maybe.
// No support in gosqlite, but for now our create-tables script is simple
// and we can execute substrings up to each semicolon.
func hack_create_tables(conn *sqlite.Conn) error {
	bytes, err := ioutil.ReadFile(createTablesFile)
	if err != nil {
		return err
	}

	chars := []rune(strings.TrimSpace(string(bytes)))
	for i := 0; i < len(chars); {
		j := i
		for ; j < len(chars)-1; j++ {
			if chars[j] == ';' {
				break
			}
		}

		// now 'j' is either the first semicolon or the very last rune
		query := chars[i : j+1]
		err = conn.Exec(string(query))
		if err != nil {
			return err
		}

		i = j + 1
	}

	return nil
}

func create_tables_if_missing(conn *sqlite.Conn) error {
	stmt, err := conn.Prepare("SELECT name FROM sqlite_master " +
		"WHERE name = 'accounts';")
	if err != nil {
		return err
	}
	defer func() {
		err := stmt.Finalize()
		if err != nil {
			log.Println(err)
		}
	}()

	err = stmt.Exec()
	if err != nil {
		return err
	}

	found := false
	for stmt.Next() {
		found = true
	}

	if found {
		return nil
	}
	return hack_create_tables(conn)
}
