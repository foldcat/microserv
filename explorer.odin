package microserv

// generates a file explorer

import "core:fmt"
import "core:log"
import "core:os"
import path "core:path/filepath"
import "core:strings"

// ancient templating technique
Explorer_Head :: `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Explorer</title>
    <style>
      body {
        font-family: sans-serif;
        background-color: #222;
        color: #eee;
      }

      .path {
          font-weight: bold;
          margin-bottom: 10px;
          color: #fff;
      }

      .file-list {
          list-style: none;
          padding: 0;
      }

      .file-list li {
          margin-bottom: 5px;
          color: #ddd;
      }
    </style> </head> <body>
`


//<li><a href="#">file1.txt</a></li>
//<li><a href="#">file2.pdf</a></li>
//<li><a href="#">folder1</a></li>

Explorer_Tail :: `
    </ul>
</body>
</html>
`


// only returns the relative path in the serving directory
clean_path :: proc(p: string) -> (out: string, ok := false) {
	sane_path := path.clean(p)
	sane_base := path.clean(SERV_DIR)

	out = strings.trim_left(sane_path, sane_base)
	if out == p {
		return
	}

	ok = true
	return
}

gen_explorer :: proc(p: string) -> (result: string, ok := false) {
	builder := strings.builder_make()

	strings.write_string(&builder, Explorer_Head)

	handle, err := os.open(p)
	defer os.close(handle)
	if err != nil {
		log.error("failed to open", p)
		log.error("reason:", err)
		return
	}

	files, rerr := os.read_dir(handle, 2048)
	if rerr != nil {
		log.error("failed to read", p)
		log.error("reason:", rerr)
		return
	}

	strings.write_string(&builder, "<ul class=\"file-list\">\n")

	for file in files {
		fname := file.name
		fpath := file.name
		fpath = path.join([]string{p, file.name})
		cpath := clean_path(fpath) or_return
		fpath = cpath
		if file.is_dir {
			fname = fmt.aprint(fname, "/", sep = "")
		}

		list_item := fmt.aprintf("<li><a href=\"%s\">%s</a></li>", fpath, fname)

		strings.write_string(&builder, list_item)
	}

	strings.write_string(&builder, Explorer_Tail)

	result = strings.to_string(builder)

	ok = true

	return
}


gen_explorer_header :: proc(s: string) -> string {
	builder := strings.builder_make()
	strings.write_string(&builder, "HTTP/1.1 200 OK\r\n")
	strings.write_string(&builder, "Server: MicroServ\r\n")
	strings.write_string(&builder, "Content-Type: text/html\r\n")
	strings.write_string(&builder, "\r\n")
	strings.write_string(&builder, s)

	return strings.to_string(builder)
}
