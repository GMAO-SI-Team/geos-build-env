#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPTDIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTDIR="$(dirname "$SCRIPTDIR")"

usage() {
  echo "Usage: $0 [--dry-run|-n] <baselibs-version>"
  exit 2
}

DRY_RUN=FALSE
BASELIBS_VERSION=
for arg in "$@"; do
  case "$arg" in
    --dry-run | -n ) DRY_RUN=TRUE ;;
    -* ) usage ;;
    * )
      [[ -z "$BASELIBS_VERSION" ]] || usage
      BASELIBS_VERSION="$arg"
      ;;
  esac
done

[[ -n "$BASELIBS_VERSION" ]] || usage

run() {
  if [[ "$DRY_RUN" == "TRUE" ]]; then
    printf '%s ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

build_baselibs_stack() {
  run "${ROOTDIR}/build_full_stack.bash" -o ubuntu24 "$@" \
    --baselibs-version="$BASELIBS_VERSION" \
    --build-baselibs-stack --push --prune
}

prune_docker() {
  run docker system prune -a -f
}

build_baselibs_stack --compiler=gnu --gcc-version=15.2.0 --openmpi-version=5.0.5
prune_docker

build_baselibs_stack --compiler=gnu --gcc-version=16.2.0 --openmpi-version=5.0.11rc1
prune_docker

build_baselibs_stack --compiler=ifort
prune_docker

build_baselibs_stack --compiler=ifx
prune_docker
