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

// use a LRU cache to store webpages, with this enabled changes 
// in files may not be reflected by the server
ENABLE_CACHE :: true

// has no effect if ENABLE_CACHE is false, control 
// the size of the cache
CACHE_SIZE :: 100
