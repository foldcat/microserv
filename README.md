# MicroServ

MicroServ is a simple http server for hosting small static webpages.
It is rather minimalistic and can handle a lot of requests.

## Optional Features 
- caching
- rendering file explorer

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
