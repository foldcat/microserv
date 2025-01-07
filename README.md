# MicroServ

MicroServ is a simple http server for hosting static webpages.
It is rather minimalistic and can handle a lot of requests.

Optionally, MicroServ can generate a file explorer.

## Building

MicroServ has no external dependencies. Simply:
```bash
# release (-o:speed boost performance by 2x)
odin build . -o:speed

# debug (debug loggimg, tracking allocator)
odin build . -debug
```

## Configuration

MicroServ is configured by editing the `config.odin` file.
Options are documented inside.

## Planned features
- multithreading
- caching
