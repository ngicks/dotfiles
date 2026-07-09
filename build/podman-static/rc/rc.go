package rc

import (
	"embed"
	"io/fs"
	"strings"
)

//go:embed resource
//go:embed tag
var content embed.FS

func FS() fs.FS {
	sub, err := fs.Sub(content, "resource")
	if err != nil {
		panic(err)
	}
	return sub
}

func Tag() string {
	b, err := content.ReadFile("tag")
	if err != nil {
		panic(err)
	}
	return strings.TrimSpace(string(b))
}
