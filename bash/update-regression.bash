#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPTDIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOTDIR="$(dirname "$SCRIPTDIR")"

usage() {
  echo "Usage: $0 [--dry-run|-n] <regression-version>"
  exit 2
}

DRY_RUN=FALSE
REGRESSION_VERSION=
for arg in "$@"; do
  case "$arg" in
    --dry-run | -n ) DRY_RUN=TRUE ;;
    -* ) usage ;;
    * )
      [[ -z "$REGRESSION_VERSION" ]] || usage
      REGRESSION_VERSION="$arg"
      ;;
  esac
done

[[ -n "$REGRESSION_VERSION" ]] || usage
BASELIBS_VERSIONS="v8.33.0,v9.13.0"

run() {
  if [[ "$DRY_RUN" == "TRUE" ]]; then
    printf '%s ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

run "${ROOTDIR}/build_full_stack.bash" -o ubuntu24 --compiler=gnu \
  --gcc-version=15.2.0 --openmpi-version=5.0.5 \
  --baselibs-version="$BASELIBS_VERSIONS" \
  --regression-version="$REGRESSION_VERSION" --build-regression --push

run "${ROOTDIR}/build_full_stack.bash" -o ubuntu24 --compiler=gnu \
  --gcc-version=16.2.0 --openmpi-version=5.0.11rc1 \
  --baselibs-version="$BASELIBS_VERSIONS" \
  --regression-version="$REGRESSION_VERSION" --build-regression --push

run "${ROOTDIR}/build_full_stack.bash" -o ubuntu24 --compiler=ifort \
  --baselibs-version="$BASELIBS_VERSIONS" \
  --regression-version="$REGRESSION_VERSION" --build-regression --push

run "${ROOTDIR}/build_full_stack.bash" -o ubuntu24 --compiler=ifx \
  --baselibs-version="$BASELIBS_VERSIONS" \
  --regression-version="$REGRESSION_VERSION" --build-regression --push

run docker system prune --all --volumes -f
