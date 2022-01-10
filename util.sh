#!/usr/bin/env bash
#
# Utilities for esp8266 development container scripts

# usage: print [args...]
print() {
  echo "${CURRENT_SCRIPT}: $*"
}

# usage: print_raw [args...]
print_raw() {
  echo "$*"
}

# usage: error [args...]
error() {
  print "error: $*" >&2
}

# usage: error_raw [args...]
error_raw() {
  print_raw "$*" >&2
}

# usage: check_requirements
check_requirements() {
  if [[ -z "${CURRENT_SCRIPT}" ]]; then
    error "CURRENT_SCRIPT not set"
    exit 1
  fi

  if [[ -z "${CURRENT_DIRECTORY}" ]]; then
    error "CURRENT_DIRECTORY not set"
    exit 1
  fi

  if [[ -z "${DOCKER_BINARY}" ]]; then
    error "unable to find docker (DOCKER_BINARY not set)"
    return 1
  fi
}

# usage: docker [args...]
docker() {
  "${DOCKER_BINARY}" "$@"

  local exit_code="$?"

  if [[ "${exit_code}" -ne 0 ]]; then
    error "${DOCKER_BINARY} exited with code ${exit_code}"
    return 1
  fi
}

# usage: arg_or_default arg default [new arg value]
arg_or_default() {
  if [[ -n "$1" ]]; then
    if [[ "$#" -eq 3 ]]; then
      echo "$3"
    else
      echo "$1"
    fi
  else
    echo "$2"
  fi
}
build

#!/usr/bin/env bash
#
# Build esp8266 development container

readonly CURRENT_SCRIPT="$(basename -- ${BASH_SOURCE[0]})"
readonly CURRENT_DIRECTORY="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly DOCKER_BINARY="$(command -v docker)"

source "${CURRENT_DIRECTORY}/scripts/config.sh"
source "${CURRENT_DIRECTORY}/scripts/util.sh"

# usage: usage [printer]
usage() {
  local printer="$(arg_or_default "$1" 'print_raw')"

  "${printer}" "usage: ${CURRENT_SCRIPT} [-h] [TAG]"
}

# usage: full_usage [printer]
full_usage() {
  local printer="$(arg_or_default "$1" 'print_raw')"

  usage "${printer}"
  "${printer}"
  "${printer}" 'Build tool for esp8266 development container'
  "${printer}"
  "${printer}" 'arguments:'
  "${printer}" '  -h                    show this help message and exit'
  "${printer}" '  TAG                   the tag of the image to build'
}


# usage: build_image [tag]
build_image() {
  # Generate image name
  local name="${DOCKER_IMAGE_NAME}:$(arg_or_default "$1" \
                                                    "${DOCKER_IMAGE_TAG}")"

  print "building image ${name}"

  # Run docker with the provided arguments
  docker build -t "${name}" \
                  "${CURRENT_DIRECTORY}/${DOCKER_LOCAL_SOURCE_DIRECTORY}"
}

# usage: main [-h] [-d DATA_DIRECTORY] [-t TAG] [ARGS...]
main() {
  check_requirements "$@" || exit 1

  while getopts ':h' OPT; do
    case "${OPT}" in
      h)
        full_usage
        exit 0
        ;;
      ?)
        full_usage
        print
        error "invalid argument: ${OPTARG}"
        exit 1
        ;;
    esac
  done

  shift $((OPTIND - 1))

  build_image "$@"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main "$@"
fi
