# MicroServ

MicroServ is a simple http server for hosting static webpages.
It is rather minimalistic and can handle a lot of requests.

Optionally, MicroServ can generate a file explorer.

## Building

MicroServ has no external dependencies. Simply:
```bash
# release
odin build . -o:speed

# debug
odin build . -debug
```

## Configuration

MicroServ is configured by editing the `config.odin` file.
Options are documented inside.

## Planned features
- multithreading
- caching
