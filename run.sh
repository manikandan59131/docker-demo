#!/usr/bin/env bash
#
# Run esp8266 development container

readonly CURRENT_SCRIPT="$(basename -- ${BASH_SOURCE[0]})"
readonly CURRENT_DIRECTORY="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly DOCKER_BINARY="$(command -v docker)"

source "${CURRENT_DIRECTORY}/scripts/config.sh"
source "${CURRENT_DIRECTORY}/scripts/util.sh"

# usage: usage [printer]
usage() {
  local printer="$(arg_or_default "$1" 'print_raw')"

  "${printer}" "usage: ${CURRENT_SCRIPT} [-h] [-d DATA_DIRECTORY] [-t TAG]" \
               "[ARGS...]"
}

# usage: full_usage [printer]
full_usage() {
  local printer="$(arg_or_default "$1" 'print_raw')"

  usage "${printer}"
  "${printer}"
  "${printer}" 'Make tool for esp8266 development container'
  "${printer}"
  "${printer}" 'arguments:'
  "${printer}" '  -h                    show this help message and exit'
  "${printer}" '  -d DATA_DIRECTORY     mount point for /mnt/data inside the'
  "${printer}" '                        container'
  "${printer}" '  -t TAG                the tag of the image to run'
  "${printer}" '  ARGS...               the command to run in the container'
}


# usage: run_image [data_directory] [tag] [args...]
run_image() {
  local arguments=(run --rm --interactive --tty --entrypoint /sbin/my_init)

  # Generate volume and image names
  local volume="$(arg_or_default "$1" \
               "${CURRENT_DIRECTORY}/${DOCKER_LOCAL_MOUNT_DIRECTORY}")"
  local name="${DOCKER_IMAGE_NAME}:$(arg_or_default "$2" \
                                                    "${DOCKER_IMAGE_TAG}")"

  # Add volume and name to arguments
  arguments+=(-v "${volume}:/mnt/data" ${name})

  # Remove the first two arguments from the argument list
  shift 2

  # Run docker with the provided arguments
  docker "${arguments[@]}" -- "$@"
}

# usage: main [-h] [-d DATA_DIRECTORY] [-t TAG] [ARGS...]
main() {
  check_requirements "$@" || exit 1

  local docker_volume=''
  local docker_image_tag=''

  while getopts ':hd:t:' OPT; do
    case "${OPT}" in
      h)
        full_usage
        exit 0
        ;;
      d)
        docker_volume="${OPTARG}"
        ;;
      t)
        docker_image_tag="${OPTARG}"
        ;;
      ?)
        full_usage error_raw
        error_raw
        error "invalid argument: ${OPTARG}"
        exit 1
        ;;
    esac
  done

  shift $((OPTIND - 1))

  run_image "${docker_volume}" "${docker_image_tag}" "$@"
}

if [[ "$0" == "${BASH_SOURCE[0]}" ]]; then
  main "$@"
fi
