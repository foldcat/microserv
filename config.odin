package microserv

import "core:net"

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

// set to net.IP4_Address{0, 0, 0, 0} if you want other 
// devices to connect to microserv
LISTEN_ADDR :: net.IP4_Loopback
