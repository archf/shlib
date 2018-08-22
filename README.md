# shlib

# Features & Guidelines

- All default provided functions syntax are meant to be as portable as possible. As such all To
run a `dash` script.
- When possible pure shell is perefered over usarge of external programs ( `date`, `readlink`,...)
to avoid extra I/O operations and scheduling of OS processes.
- A little more is provided but you may delete the extra stuff you need

Conventions

- External environmental variables that may influence the script behavior are
all capital case
  - `VERBOSE`
  - `DEBUG`
  - `FORCE`
  - ...

- Private functions not meant te be consumed directly (after sourcing) begin by
a '`_`' (e.g.: `function _my_private_func () { }`)
- Provide useful attributes as variables akin to python's one:
  - `__file__` -> fully qualified script path after symlink resolution
  - `__name__` -> program name based on `__file__` basename
  - `__path__` -> script directory derived from `__file__`.
  - `__version__` -> script version. Will be read in file `${__path__}/${__version__}` if it exists. Altenatively, you may define it directly in your script.
  - `__doc__` -> script usage script

## Usage

## Todo

- print timestamps in debug mode
- add systemd unit templates for easy daemonizing
- namespacing support (sourcing multiple scripts)?
