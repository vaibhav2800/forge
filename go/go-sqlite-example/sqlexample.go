package main

import (
	"code.google.com/p/gosqlite/sqlite"
	"fmt"
)

func main() {
	fmt.Println(sqlite.Version())
	conn, err := sqlite.Open("tmp.sqlite")
	defer func() {
		err := conn.Close()
		if err != nil {
			fmt.Println(err)
		}
	}()
	if err != nil {
		fmt.Println(err)
		return
	}

	err = conn.Exec("CREATE TABLE T1(id int, name string);")
	if err != nil {
		fmt.Println(err)
		return
	}

	err = conn.Exec("INSERT INTO T1 VALUES(3, \"john\");")
	if err != nil {
		fmt.Println(err)
		return
	}

	err = conn.Exec("INSERT INTO T1 VALUES(4, \"mark\");")
	if err != nil {
		fmt.Println(err)
		return
	}

	stmt1, err := conn.Prepare("SELECT NAME FROM T1;")
	if err != nil {
		fmt.Println(err)
		return
	}

	defer func() {
		err := stmt1.Finalize()
		if err != nil {
			fmt.Println(err)
		}
	}()

	err = stmt1.Exec()
	if err != nil {
		fmt.Println(err)
		return
	}

	for stmt1.Next() {
		// you can parse anything (name, ID) as string
		// but parsing name as int will give an error
		var s string
		err = stmt1.Scan(&s)
		if err != nil {
			fmt.Println(err)
			return
		}
		fmt.Println(s)
	}

	stmt2, err := conn.Prepare("SELECT NAME FROM T1 WHERE ID = ?;")
	if err != nil {
		fmt.Println(err)
		return
	}

	defer func() {
		err := stmt2.Finalize()
		if err != nil {
			fmt.Println(err)
		}
	}()

	// http://sqlite.org/lang_expr.html#varparam
	// ?, ?NNN, :VVV, @VVV, $VVV
	// It looks like gosqlite binds by index, so only use '?'.
	err = stmt2.Exec(3) // you can also use string "3"
	if err != nil {
		fmt.Println(err)
		return
	}

	for stmt2.Next() {
		// you can parse anything (name, ID) as string
		// but parsing name as int will give an error
		var s string
		err = stmt2.Scan(&s)
		if err != nil {
			fmt.Println(err)
			return
		}
		fmt.Println(s)
	}
}
