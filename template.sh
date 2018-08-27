#!/usr/bin/env bash

# Usage:
#  VERBOSE=7 ./template.sh -v 7

### Environment variables
##############################################################################
DEBUG=${DEBUG:-}
# Defaulting to 'warning'. Can be controled by setting the verbosity level.
# Set to '7' to debug argument parsing (tip set it on the CLI).
VERBOSE=${VERBOSE:-6} # 7 = debug -> 0 = emergency
FORCE=${FORCE:-}
NOCOLOR=${NOCOLOR:-}

### Shell Options and script meta variables
##############################################################################

# Exit immediately on error. Same as '-e'. Use of '|| true' may be handy.
set -o errexit

# Any trap on ERR is inherited by any functions or subshells. Available on bash
# only.
[ -n "${BASH_VERSION}" ] && set -o errtrace || true

# Return value of a pipeline is the one of right most cmd with non-zero exit
# code.  Available on bash only.
[ -n "${BASH_VERSION}" ] && set -o pipefail

# Errors on unset variables and parameters. Same as '-u'. Use '${VAR:-}'.
#   - feat: exportable 'main' by the name of $0 in bash
set -o nounset

# mac osx path handling
if [ "${OSTYPE:-}" = darwin* ]; then
  alias date=/usr/bin/date
  alias readlink=/usr/bin/readlink
else
  alias date=/bin/date
  alias readlink=/bin/readlink
fi

__file__=$(readlink --no-newline --canonicalize-existing "${0}")
__path__=${__file__%/*}
__name__="${0##*/}"

if [ -r ${__path__}/VERSION ]; then
  __version__=$(< "${__path__}/VERSION")
else
  __version__=
fi

if [ -z "${LS_COLORS:-}" ]; then
  # Try and see if there is color support
  if [ ! -x /usr/bin/dircolors >/dev/null 2>&1 ]; then
    [ -r ~/.dircolors ] && eval "$(/usr/bin/dircolors -b ~/.dircolors)" \
      || eval "$(/usr/bin/dircolors -b)"
  fi
  [ -z "${LS_COLORS:-}" ] && NOCOLOR="${NOCOLOR:-}" || true
fi

__color_info="\\e[32m"
__color_notice="\\e[34m"
__color_warning="\\e[33m"
__color_error="\\e[31m"
__color_error="\\e[31m"
__color_critical="\\e[1;31m"
__color_alert="\\e[1;33;41m"
__color_emergency="\\e[1;4;5;33;41m"
__color_reset="\\033[0m"
__color_bold="\\E[1m"

### Functions

_log() {
  local log_level="${1}"
  shift
  local msg=
  if [ ${NOCOLOR:-} ] || [ ! -t 2 ]; then
    local color=""; local color_reset=""
  else
    # portable indirection to resolve the color
    eval local color="\${__color_${log_level}:-}"
    local color_reset="${__color_reset}"
  fi

  # print date in debug mode only to reduce
  if [ "${log_level}" = "debug" ]; then
    # printf '%b' "$(date --iso-8601=seconds) ${color}[${log_level}]${color_reset}: $@\n" 1>&2
    printf '%b' "$(date --rfc-3339=seconds) ${color}[${log_level}]${color_reset}: $@\n" 1>&2
  else
    printf '%b' "${color}[${log_level}]${color_reset}: $@\n" 1>&2
  fi
}

# see https://en.wikipedia.org/wiki/Syslog#Severity_levels as reference
emergency() { _log emergency "$@"; exit 1; }
alert()     { [ "${VERBOSE}" -ge 1 ] && _log alert "$@"; true; }
critical()  { [ "${VERBOSE}" -ge 2 ] && _log critical "$@"; true; }
error()     { [ "${VERBOSE}" -ge 3 ] && _log error "$@"; true; }
warning()   { [ "${VERBOSE}" -ge 4 ] && _log warning "$@"; true; }
notice()    { [ "${VERBOSE}" -ge 5 ] && _log notice "$@"; true; }
info()      { [ "${VERBOSE}" -ge 6 ] && _log info "$@"; true; }
debug()     { [ "${VERBOSE}" -ge 7 ] && _log debug "$@"; true; }

# logging system alternative.
verbose() {
  if [ -n "$VERBOSE" ]; then
    printf "%s\n" "$*" 1>&2
  fi
}

die_with_status () {
	local status=$1; shift
	printf >&2 '%s\n' "$*"
	exit "$status"
}

die() {
	die_with_status 1 "$@"
}

_normalize_args() {
  # Allow more flavorfull argparsing capabilities
  debug "_normalize_args input args: '$@'"
  while [ $# -gt 0 ]; do
    case $1 in
      # break '-xyz' into '-x -y -z'
      -[!-]?*)
        OPTIND=1
        while getopts ${1#-} opt "$1"; do
          __argv="${__argv:-} -${opt}"
        done
        ;;
      # break --foo=bar style long options
      --?*=*) __argv="${__argv:-} ${1%%=*} ${1#*=}" ;;
      # add other args exactly as they are
      *) __argv="${__argv:-} ${1}" ;;
    esac
    shift
  done
  # strip a leading whitespace that may be introduced
  __argv=${__argv# }
  debug "_normalize_args output args: '$__argv'"
}

do_test() {
  # do_test test_fct <log_level> arg1 arg2 ... argN
  local fct=$1; shift
  case $1 in
    debug|info|notice|warning|error|critical|alert|emergency)
      local log_level=${1}; shift ;;
  esac

  # return on first failing
  # set -x
  while [ $# -gt 0 ]; do
    if ! $fct $1 ${log_level:='warning'}; then
      return 1
    fi
    shift
  done
}

is_cmd() {
  # test a cmd is available on system.
  local cmd=${1}
  local log_level=${2:-'debug'}
  debug "searching for '$1' cmd on system"
  if ! type "${cmd}" >/dev/null 2>&1; then
    $log_level "cmd '${cmd}' is undefined."
    return 1
  fi
  debug "found $1 on system!"
  return 0
}

is_defined() {
  # Test a variable is defined.
  local var=${1}
  local log_level=${2:-'debug'}
  debug "Testing '$1' is defined"
  if eval [ -z "\${${var}}" ]; then
    $log_level "Variable '${var}' is undefined!"
    return 1
  else
    return 0
  fi
}

run() {
  # Wrapper around command execution to allow dry-run mode and/or mardown
  # output to stdout.
  if [ -z "${DRY_RUN:-}" -a  ]; then
    if [ -z "${MARKDOWN:-}" ]; then
      $*
    else
      echo -e "```"; echo "$@"; $*;  echo -e "```\n"
    fi
  else
    if [ -z "${MARKDOWN}" ]; then
      echo "$*"
    else
      echo -e "```"; echo "$@"; echo -e "```\n"
    fi
  fi
}

_is_option() { case ${1:-} in -*) return 0;; *)  return 1;; esac; }
_version() { echo "${__version__:-No version string available}" 1>&2; }
_usage() { echo "${__doc__:-No usage available}" 1>&2; }

### Argument parsing (customize as per your script input)

__doc__="\
This is an example help text. Provide the needed informations for your users

USAGE
  ${__name__} [OPTIONS] cmd ARGS

OPTIONS
  -h|--help             Display this help and exit
  -V|--version          Output version information
  -v|--verbose [level]  Increase verbosity level as per standart severity
                        levels. Accepts a number ranging from 1 to 7.
  -x|--debug            Enable shell tracing mode (set -O xtrace) at beginning
                        of main.
  -f|--force            Skip all user interaction. Implied 'Yes' to all actions.
  -u|--username <username>  Prompt for username
  -p|--password <password>  Propmt for password
  -q|--quiet            Supresse STDOUT output.

  -m|--markdown         Output to STDOUT commands and results as markdown cells

CMD
  list  list stuff
  show  show stuff
  test_log          Test and showcase various 'log_level' output
  test_is_defined   Test the 'is_defined' provided function
  test_is_cmd       Test the 'is_cmd' provided function
"

_parse_options() {
  # Parse short and long options. May be called multiple times.
  debug "_parse_options input args: '$@'"
  while _is_option ${1:-}; do
    case $1 in
      -h|--help) _usage; exit 0;;
      -V|--version) _usage; exit 0 ;;
      -v|--verbose)
        if [ -z "${2#?}" ]; then shift
          # will throw an error if not a single digit number
          [ $1 -le 9 ] && VERBOSE=$1 || true
        fi ;;

      # convenient options
      -D|--dry-run) DRY_RUN=true;;
      -f|--force) FORCE=true;;
      -x|--debug) DEBUG=true;;
      -q|--quite) QUIET=true;;

      # credentials prompting
      -u|--username) shift; username=${1} ;;
      -p|--password) echo "Enter Password: "; stty -echo
        read __password; stty echo; echo ;;

      # misc
      --m|--markdown) TO_MARKDOWN=true;;

      --) shift; break;;
      *) die "Invalid option: '$1'" ;;
    esac
    shift
  done
  __argv=$@
  debug "_parse_options remaining args: '$@'"
}

_parse_args() {
  # Parse script options and args. Call this from your main().
  debug "_parse_args input args: '$@'"
  _normalize_args $@; set -- "${__argv:-}"

  # parse script global options and set args to to what remains
  _parse_options $@
  set -- "${__argv:-}"

  # Parse positional args.
  while [ $# -gt 0 ]; do
    case $1 in
      # parse global options allowed after subcommand
      show|list) shift; _parse_options $; set -- "${__argv:-}" ;;
      do_something) shift; __somevar=$1;;
      test_log) _test_log;;
      test_is_defined) _test_is_defined;;
      test_is_cmd) _test_is_cmd;;
      *) die "Invalid positional argument: '$1'" ;;
      --) shift; break;;
    esac
    shift
  done
  __argv=$@
  debug "_parse_args remaining args: '$@'"
}

_hook_pre_exec() {
  ### Runtime
  #############################################################################
  info "script '__name__ ': ${__name__}"
  info "script '__file__': ${__file__}"
  info "script '__path__': ${__path__}"
  info "script '__version__': ${__version__}"
  # info "script '__doc__': \n${__doc__}"
  info "Verbosity level: ${VERBOSE}"
  info "Debug mode: ${DEBUG}"
  info "Dry-run mode: ${DRY_RUN:-}"
  info "Force: ${FORCE:-}"
  info "Quiet: ${Quiet:-}"
}

_test_log() {
  # All of these go to STDERR so you can safely pipe STDOUT to other software.
  debug "Messages that contain information normally of use only when \n\
          debugging a program."
  info "Informational messages. May be harvested for reporting and/or measuring"
  notice "Conditions that are not error conditions, but that may require \n\
          special handling."
  warning "Warning messages. Not an error but an indication that one will \n\
          occur if action is not taken"
  error "Errors. Not urgent failures to resolve in a given time"
  critical "Critical conditions (e.g.: Hardware errors). Indicates failure \n\
          in a primary system. Should be corrected immediately"
  alert "Action must be taken immediately (e.g.: corrupted data or loss of
          network connection). "
  emergency "Panic condition (e.g.: System is unusable).Multiple \n\
          apps servers or sites are affected."
}

_test_is_cmd() {
  # Abort script if any required commands are missing.
  info 'Testing availabity of cmd: "do_test is_cmd warning wget bar"'
  do_test is_cmd warning wget bar \
    || die "aborting... missing required 'cmd'."
}

_test_is_defined() {
  # Abort script if any required variables are undefined.
  info 'Defining vars: "foo=bar; baz="'
  foo=bar; baz=
  info 'Testing for defined variables: "do_test is_defined warning foo baz"'
  do_test is_defined warning foo baz \
       || die "aborting... missing required variable."
}

# template.sh() {
#   echo 'Running "template.sh"'
# }

main() {

  if [ $# -eq 0 ]; then
    _usage; exit 0
  fi

  # Parse script positional args and set args to to what remains
  _parse_args $@; set -- "${__argv:-}";

  # Depending on logic flow you want to achieve, remainder of
  _hook_pre_exec

  ### begin actual script below ###
  # template.sh

}

if [ "${__name__}" = "template.sh" ]; then
  main $@
else
  [ -n "${BASH_VERSION:-}" ] && export -f template.sh || true
fi
