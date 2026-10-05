#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPTDIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTDIR="$(dirname "$SCRIPTDIR")"

usage() {
  echo "Usage: $0 [--dry-run|-n] <bcs-version>"
  exit 2
}

DRY_RUN=FALSE
BCS_VERSION=
for arg in "$@"; do
  case "$arg" in
    --dry-run | -n ) DRY_RUN=TRUE ;;
    -* ) usage ;;
    * )
      [[ -z "$BCS_VERSION" ]] || usage
      BCS_VERSION="$arg"
      ;;
  esac
done

[[ -n "$BCS_VERSION" ]] || usage
BASELIBS_VERSIONS="v8.33.0,v9.13.0"

run() {
  if [[ "$DRY_RUN" == "TRUE" ]]; then
    printf '%s ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

build_bcs() {
  run "${ROOTDIR}/build_full_stack.bash" -o ubuntu24 "$@" \
    --baselibs-version="$BASELIBS_VERSIONS" \
    --bcs-version="$BCS_VERSION" --build-bcs --push
}

prune_docker() {
  run docker system prune --all --volumes -f
}

build_bcs --compiler=gnu --gcc-version=15.2.0 --openmpi-version=5.0.5
prune_docker

build_bcs --compiler=gnu --gcc-version=16.2.0 --openmpi-version=5.0.11rc1
prune_docker

build_bcs --compiler=ifort
prune_docker

build_bcs --compiler=ifx
prune_docker
