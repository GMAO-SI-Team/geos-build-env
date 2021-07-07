#!/usr/bin/env bash
set -Eeuo pipefail
#set -x

# From http://stackoverflow.com/a/246128/1876449
# ----------------------------------------------
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPTDIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
PARENTDIR=$(dirname $SCRIPTDIR)

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

ENV_FILE=${PARENTDIR}/versions.sh
source $ENV_FILE

DRYRUN=FALSE
VERBOSE=FALSE

OS_VERSION=UNKNOWN
ESMF_VERSION=

COMPILER=UNKNOWN

ORIG_BASELIBS_VERSION=${BASELIBS_VERSION}

DEFAULT_DOCKER_REPO='gmao'
DOCKER_REPO=${DEFAULT_DOCKER_REPO}

usage () {
   cat << HELP_USAGE
   Usage: $0 -o <osversion>|--os-version=<osversion> <options>

   REQUIRED:
      -o <osversion>|--os-version=<osversion>
         OS version to build (REQUIRED. Allowed values: ubuntu20, opensuse15, centos8)
      --compiler=<compiler>
         compiler to use (REQUIRED. Allowed values: intel, gnu)

   VERSION OPTIONS:
      --baselibs-version=<tag>
         Tag of Baselibs to checkout (Default: ${BASELIBS_VERSION})
      --esmf-version=<tag>
         Tag of ESMF submodule to checkout in Baselibs (Default: Tag in Baselibs being built)

   DOCKER OPTIONS:
      --docker-repo=<repo>
         Docker Repository to push to (Default: ${DOCKER_REPO})

   OTHER OPTIONS:
      -h|--help
         Print this usage
      -v|--verbose
         Verbose
      -n|--dry-run
         Output the various settings and exit
HELP_USAGE
}

while getopts hno:v-: OPT; do
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "$OPT" in
    o | os-version       ) needs_arg; OS_VERSION="$OPTARG"       ;;
        compiler         ) needs_arg; COMPILER="$OPTARG"         ;;

        baselibs-version ) needs_arg; BASELIBS_VERSION="$OPTARG" ;;
        esmf-version     ) needs_arg; ESMF_VERSION="$OPTARG"     ;;

        docker-repo      ) needs_arg; DOCKER_REPO="$OPTARG"      ;;

    h | help     ) usage; exit  ;;
    n | dry-run  ) DRYRUN=TRUE  ;;
    v | verbose  ) VERBOSE=TRUE ;;

    ??* )          die "Illegal option --$OPT" ;;  # bad long option
    ? )            exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

if [[ "$VERBOSE" == "TRUE" ]]
then
   set -x
fi

# Check we have a valid os
if [[ "$OS_VERSION" == "UNKNOWN" ]]
then
   echo "os_version must be passed in!"
   usage
   exit 1
elif [[ "$OS_VERSION" == "opensuse15" ]]
then
   BASE_IMAGE="opensuse:15.2"
   OS_DOCKER_DIR="OpenSUSE15"
elif [[ "$OS_VERSION" == "ubuntu20" ]]
then
   BASE_IMAGE="ubuntu:20.04"
   OS_DOCKER_DIR="Ubuntu20"
elif [[ "$OS_VERSION" == "centos8" ]]
then
   BASE_IMAGE="centos:8"
   OS_DOCKER_DIR="Centos8"
else
   echo "Invalid osversion!"
   usage
   exit 1
fi

# Check we have a valid compiler
if [[ "$COMPILER" == "UNKNOWN" ]]
then
   echo "compiler must be passed in!"
   usage
   exit 1
elif [[ "$COMPILER" == "intel" ]]
then
   COMPILER_NAME="intel"
   COMPILER_VERSION=${INTEL_VERSION}
   MPI_NAME="intelmpi"
   MPI_VERSION=${INTEL_VERSION}
   FINAL_DOCKER_IMAGE_NAME="geos-env"
   ESMF_COMM="intelmpi"
   ESMF_COMPILER="intel"
elif [[ "$COMPILER" == "gnu" ]]
then
   COMPILER_NAME="gcc"
   COMPILER_VERSION=${GCC_VERSION}
   MPI_NAME="openmpi"
   MPI_VERSION=${OPENMPI_VERSION}
   FINAL_DOCKER_IMAGE_NAME="geos-env-mkl"
   ESMF_COMM="openmpi"
   ESMF_COMPILER="gfortran"
else
   echo "Invalid compiler!"
   usage
   exit 1
fi

EXTRA_OPTIONS=""
if [[ "x${ESMF_VERSION}" != "x" ]]
then
   EXTRA_OPTIONS+="--esmf-version=${ESMF_VERSION} "
fi
if [[ "x${BASELIBS_VERSION}" != "x${ORIG_BASELIBS_VERSION}" ]]
then
   EXTRA_OPTIONS+="--baselibs-version=${BASELIBS_VERSION} "
fi

if [[ "$DRYRUN" == "TRUE" ]]
then
   echo "Version Info:"
   echo "  OS_VERSION: ${OS_VERSION}"
   echo "  BASE_IMAGE: ${BASE_IMAGE}"
   echo "  GCC_VERSION: ${GCC_VERSION}"
   echo "  INTEL_VERSION: ${INTEL_VERSION}"
   echo "  OPENMPI_VERSION: ${OPENMPI_VERSION}"
   echo "  BASELIBS_VERSION: ${BASELIBS_VERSION}"
   echo "  FV3_VERSION: ${FV3_VERSION}"
   echo "  GCM_VERSION: ${GCM_VERSION}"
   echo "  CMAKE_VERSION: ${CMAKE_VERSION}"
   echo "  ESMF_VERSION: ${ESMF_VERSION}"
   echo ""
   echo "EXTRA_OPTIONS: ${EXTRA_OPTIONS}"
   exit
fi

bash ${PARENTDIR}/build_full_stack.bash --os-version=${OS_VERSION} --compiler=${COMPILER} --build-bsl --no-cache ${EXTRA_OPTIONS} 2>&1 | tee esmf_testing_build_full_stack.out

[ "$(docker ps -a | grep runner)" ] && docker rm --force runner
docker run --name runner --env ESMF_COMM=$ESMF_COMM --env ESMF_COMPILER=$ESMF_COMPILER --env-file=$ENV_FILE -dit ${DOCKER_REPO}/${OS_VERSION}-baselibs:${BASELIBS_VERSION}-${MPI_NAME}_${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION}
docker exec -t runner bash "/opt/esmf-test-Dockerfile.baselibs.bash"
docker stop runner
