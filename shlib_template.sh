#!/usr/bin/env bash

. shlib

# From this point below put your business value adding code.
__doc__="\
This script here is an example leveraging shlib core functions and is used to
selftest shlib itself. It can be used as a genereric template if you decide to
source the 'shlib' shell code library. As an alternative you can use the
'shlib_template_standalone.sh' which is as the name implies a standalone
equivalent should you need extra portability at the cost of duplictation
maintainability and storage.

USAGE
  ${__name__:-} CMD [OPTIONS] ARGS

OPTIONS
  -h|--help             Display this help and exit.
  -V|--version          Output version information.
  -v|--verbose [level]  Increase verbosity level as per standart severity
                        levels. Accepts a number ranging from 1 to 7.
  -n|-D|--dry-run       Dry run. Print what would be executed.
  -d|--debug            Enable shell tracing mode (set -O xtrace) at beginning
                        of main.
  -f|--force            Skip all user interaction. Implied 'Yes' to all actions.
  -u|--username <username>  Prompt for username.
  -p|--password <password>  Propmt for password.
  -q|--quiet            Supresse STDOUT output.

  -m|--markdown         Output to STDOUT commands and results as markdown
                        cells.

CMD
  test_log          Test and showcase various 'log_level' output
  test_is_defined   Test the 'is_defined' provided function
  test_is_cmd       Test the 'is_cmd' provided function
"

_parse_options() {
  # Parse short and long options. May be called multiple times.
  debug "_parse_options input args: $*"
  while _is_option ${1:-}; do
    case $1 in
      -h|--help) _usage; exit 0;;
      -V|--version) _usage; exit 0;;
      -v|--verbose)
        if [ -z "${2#?}" ]; then shift
          # will throw an error if not a single digit number
          [ $1 -le 9 ] && VERBOSE=$1 || true
        fi ;;

      # convenient options
      -D|-n|--dry-run) DRY_RUN=true;;
      -f|--force) FORCE=true;;
      -d|--debug) VERBOSE=8;;
      -q|--quiet) QUIET=true;;

      # credentials prompting
      -u|--username) shift; username=${1};;
      -p|--password) echo "Enter Password: "; stty -echo
        read __password; stty echo; echo ;;

      # misc
      --m|--markdown) TO_MARKDOWN=true;;

      --) shift; break;;
      *) die "Invalid option: '$1'";;
    esac
    shift
  done
  __argv=$@
  debug "_parse_options remaining args: '$*'"
}

_parse_args() {
  # Parse script options and args. Call this from your main().
  debug "_parse_args input args: '$*'"
  _normalize_args $@; set -- ${__argv:-}

  # parse script global options and set args to to what remains
  _parse_options $@
  set -- ${__argv:-}

  # Print main script flags.
  _hook_pre_exec

  # Parse positional args.
  while [ $# -gt 0 ]; do
    case $1 in
      # parse global options allowed after subcommand
      show|list) shift; _parse_options $; set -- ${__argv:-};;
      set_something) shift; __somevar=$1;;
      test_log) _test_log;;
      test_is_defined) _test_is_defined;;
      test_is_cmd) _test_is_cmd;;
      *) die "Invalid positional argument: '$1'";;
      --) shift; break;;
    esac
    shift
  done
  __argv=$@
  debug "_parse_args remaining args: '$@'"
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
  do_test is_cmd warning bash bar \
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

main() {
  if [ $# -eq 0 ]; then _usage; exit 0; fi

  # Parse script args setting '__argv' to remainder.
  _parse_args $@; set -- ${__argv:-};

  # Add code you want to run here. Depending on your script architecture you
  # may however never get to this point if you branch to the desired function
  # from the positional argument parser.

  # func_a
  # func_b
  # do_c
}

# Customize this to match your script filename.
shlib_template.sh() {
  echo 'Running "shlib_template.sh"'
  main
}

if [ "${__name__:-}" = "shlib_template.sh" ]; then
  main $@
else
  # Run script after importing in current shell namespace.
  [ -n "${BASH_VERSION:-}" ] && export -f shlib_template.sh || true
fi
