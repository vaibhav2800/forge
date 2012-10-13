package main

import (
	"html/template"
	"path"
)

var (
	templDir = path.Join(cmdline.dir, "templates")
	// exclude dot-files, e.g. .header.swp
	templ = template.Must(template.ParseGlob(templDir + "/[^.]*"))
)
