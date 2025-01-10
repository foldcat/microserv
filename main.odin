package microserv

// microserv is a simple http server

import "core:bufio"
import "core:container/lru"
import "core:crypto"
import "core:encoding/uuid"
import "core:fmt"
import "core:log"
import "core:mem"
import vmem "core:mem/virtual"
import "core:net"
import "core:os"
import path "core:path/filepath"
import "core:strings"
import "core:time"


when ENABLE_CACHE {
	cache: lru.Cache(string, string)
}


// grabs resource path from request
// assumes format is correct
parse_req_header :: proc(s: string) -> (res: string, ok := true) #optional_ok {
	tokens := strings.split(s, "\n")
	for field in tokens {
		ftokens := strings.split(field, " ")
		if ftokens[0] == "GET" {
			res = ftokens[1]
			log.info("received:", field)
			return
		}
	}
	log.warn("received non GET request")
	ok = false
	return
}

resolve_mime :: proc(s: string) -> string {
	extension := path.ext(s)
	if extension in Mime_Type {
		return Mime_Type[extension]
	}
	return DEFAULT_MIME
}

gen_404 :: proc() -> string {
	builder := strings.builder_make()
	strings.write_string(&builder, "HTTP/1.1 404 Not Found\r\n")
	strings.write_string(&builder, "Server: MicroServ\r\n")
	strings.write_string(&builder, fmt.aprintf("Content-Type: text/plain\r\n"))
	return strings.to_string(builder)
}

gen_response :: proc(p: string) -> string {
	builder := strings.builder_make()
	// this can't be deleted or we might get use after free

	strings.write_string(&builder, "HTTP/1.1 200 OK\r\n")
	strings.write_string(&builder, "Server: MicroServ\r\n")

	mime := resolve_mime(p)
	strings.write_string(&builder, fmt.aprintf("Content-Type: %s\r\n", mime))

	// end of header
	strings.write_string(&builder, "\r\n")

	// entire file
	entire_file, ok := os.read_entire_file(p)
	if !ok {
		log.error("failed to read file")
	}
	for byte in entire_file {
		strings.write_byte(&builder, byte)
	}

	return strings.to_string(builder)
}

fetch_file :: proc(p: string) -> (data: string, ok := false) {
	from_res := []string{SERV_DIR, p}
	trg_path := path.join(from_res)
	response_payload: string

	if !os.exists(trg_path) {
		log.warn(trg_path, "does not exist")
		return
	}

	// auto switch to index.html given a path
	if os.is_dir(trg_path) {
		index := []string{trg_path, "index.html"}
		index_path := path.join(index)
		// generate explorer if index.html is not existing
		if os.exists(index_path) {
			response_payload = gen_response(index_path)
		} else {
			when GENERATE_EXPLORER {
				res := gen_explorer(trg_path) or_return
				response_payload = gen_explorer_header(res)
			} else {
				log.error(index_path, "does not exist")
				return
			}
		}
	} else {
		// not a directory
		response_payload = gen_response(trg_path)
	}

	data = response_payload
	ok = true

	return
}

// this should probably be parallelized
receive_job :: proc(socket: ^net.TCP_Socket) {
	defer net.close(socket^)

	buffer := [8192]u8{} // nice size

	byte_read, err := net.recv_tcp(socket^, buffer[:])

	data, e := strings.clone_from_bytes(buffer[:])

	path := parse_req_header(data)

	file_data: string
	ok: bool

	when ENABLE_CACHE {
		if fetch_result, fetch_ok := lru.get(&cache, path); fetch_ok {
			slice := transmute([]u8)fetch_result
			net.send_tcp(socket^, slice)
			return
		} else {
			// not found
			file_data, ok = fetch_file(path)

			// prevent discarding by arena reset
			copy := strings.clone(file_data, context.temp_allocator)
			lru.set(&cache, path, copy)
		}

	} else {
		// no cache
		file_data, ok = fetch_file(path)

	}

	if !ok {
		log.warn("file not found:", path)
		net.send_tcp(socket^, transmute([]u8)gen_404())
	} else {
		net.send_tcp(socket^, transmute([]u8)file_data)
	}
}


main :: proc() {
	// TRACKING ALLOCATOR
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	// CACHE 
	when ENABLE_CACHE {
		lru.init(&cache, CACHE_SIZE)
	}

	// LOGGER
	when ODIN_DEBUG {
		logger := log.create_console_logger()
	} else {
		logger := log.create_console_logger(lowest = .Info)
	}
	defer log.destroy_console_logger(logger)
	context.logger = logger

	log.info("microserv starting")

	// SOCKET CREATION
	log.info("listening to socket")
	lsocket, serr := net.listen_tcp(net.Endpoint{port = PORT, address = LISTEN_ADDR})
	if serr != nil {
		log.panic("listen error:", serr)
	}

	// ARENA
	arena: vmem.Arena
	arena_allocator := vmem.arena_allocator(&arena)
	context.allocator = arena_allocator
	defer vmem.arena_destroy(&arena)

	// EVENT LOOP
	should_continue := true
	for should_continue {
		// reset arena
		defer vmem.arena_free_all(&arena)

		client_soc, client_endpoint, aerr := net.accept_tcp(lsocket)
		if aerr != nil {
			log.error("error while accepting:", aerr)
			continue
		}

		receive_job(&client_soc)
	}
}
