package microserv

// which directory microserv should be serving
SERV_DIR :: "./resources/"

// what port to use
PORT :: 45392

// whether generate a file explorer if index.html is not found
// and the client requests a directory
GENERATE_EXPLORER :: true

// the default mime type if the file 
// extension is NOT found in mime.odin
DEFAULT_MIME :: "application/octet-stream"
