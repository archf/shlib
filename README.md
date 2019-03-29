# shlib

Reusable shell script boilerplate and shell snippets.

## Features & Guidelines

- All template provided functions syntax are meant to be as portable as possible.
  To run a `dash` script simply edit the shebang.
- Pure shell implementation preferred over usage of external programs ( `date`,
    `readlink`,...) to avoid extra I/O operations and scheduling of OS processes.
- Provided more than needed. Need less? Just delete what you don't want.

## Conventions

- External environmental variables that may influence the script behavior are
all capital case. E.g.:
  - `VERBOSE`
  - `DEBUG`
  - `FORCE`
  - ...
- Function names are prefixed by a single underscore '`_`' unless they are meant for public consumption
  and/or are relevant public entry points. (e.g.: `function _my_private_func () {true;}`)
- Variables names are prefixed by a double underscore '`__`'  unless the scope is function
  local. ( e.g.: `__my_script_var='foo'`).

- Safety first spirit. Shell options below are enabled by default when they
  are available.

```
# Exit immediately on error. Same as '-e'. Use of '|| true' may be handy.
set -o errexit

# Any trap on ERR is inherited by any functions or subshells. Available on bash
# only.
[ -n "${BASH_VERSION}" ] && set -o errtrace || true

# Return value of a pipeline is the one of right most cmd with non-zero exit
# code. Available on bash only.
[ -n "${BASH_VERSION}" ] && set -o pipefail

# Errors on unset variables and parameters. Same as '-u'. Use '${VAR:-}'.
set -o nounset
```

- Provide useful attributes as variables akin to python's one:
  - `__file__` -> Fully qualified script path after symlink resolution.
  - `__path__` -> Script directory derived from `__file__`.
  - `__name__` -> Program name based on `__file__` basename.
  - `__version__` -> Script version string. Will be read in file
  `${__path__}/${__version__}` if it exists. Alternatively, you may define it
  directly in your script.
  - `__doc__` -> Script usage script. Displayed by the `_usage` function.

## Shell snippets

Copy paste in your script useful shell snippets packaged as functions and
grouped by category in the `lib` directory of this repository.

## Usage

```
VERBOSE=7 ./template.sh -v 7
```

### Method #1: Use the standalone script

1. Copy and rename the `shlib_template_standalone.sh` script.
2. Customize it deleting what you don't need.
3. Code what you need.

### Method 2: Source it from your script.

1. Copy and rename `shlib_template.sh`. Doing that the `shlib` library must be
   available to be sourced. That methode makes it easier to maintain
   your scripts if you have many in case of eventual `shlib` library update.
2. Customize it deleting what you don't need.
3. Code what you need.

This is most probably the way to go to in order to break subcommands in
distinct files.

## Todo

- better STDERR color toggling support
- trap handling functions template
- namespacing support (sourcing multiple scripts)
- add systemd unit file templates for easy daemonizing
