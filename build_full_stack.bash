#!/usr/bin/env bash
set -Eeuo pipefail

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

source ./versions.sh

DEFAULT_DOCKER_REPO='gmao'
DOCKER_REPO=${DEFAULT_DOCKER_REPO}

usage () {
   cat << HELP_USAGE
   Usage: $0 -o <osversion>|--os-version=<osversion> <options>

   REQUIRED:
      -o <osversion>|--os-version=<osversion>
         OS version to build (REQUIRED. Allowed values: ubuntu20, opensuse15)
  
   BUILD OPTIONS:
      --build-base
         Build the Base Linux image
      --build-gcc
         Build the GCC image
      --build-mpi
         Build the Open MPI image
      --build-bsl
         Build the ESMA Baselibs image
      --build-env
         Build the GEOS Environment image
      --build-mkl
         Build the Intel MKL image
      --build-all
         Build the above images (images needed to build GEOSgcm)

      --build-gcm
         Build the Base Linux image
      --build-fv3
         Build the FV3 Standalone image

   DOCKER OPTIONS:
      --push
         Push Images to Docker Hub
      --docker-repo=<repo>
         Docker Repository to push to (Default: ${DOCKER_REPO})
      --no-cache
         Build image with --no-cache (only affects Baselibs)

   VERSION OPTIONS:
      --baselibs-version=<tag>
         Tag of Baselibs to checkout (Default: ${BASELIBS_VERSION})
      --esmf-version=<tag>
         Tag of ESMF submodule to checkout in Baselibs (Default: Tag in Baselibs being built)
      --gcm-version=<tag>
         Tag of GCM to build (Default: ${GCM_VERSION}, useful only if --build-gcm is on)
      --fv3-version=<tag>
         Tag of FV3 Standalone to build (Default: ${FV3_VERSION}, useful only if --build-fv3 is on)

   OTHER OPTIONS: 
      -h|--help
         Print this usage
      -v|--verbose 
         Verbose
      -n|--dry-run
         Output the various settings and exit
HELP_USAGE
}

VERBOSE=FALSE
DRYRUN=FALSE

NO_CACHE=
DO_PUSH=FALSE

OS_VERSION=UNKNOWN
ESMF_VERSION=

BUILD_ALL=FALSE

BUILD_BASE=FALSE # Base Image (Ubuntu or OpenSUSE)
BUILD_GCC=FALSE # GCC Image
BUILD_MPI=FALSE # MPI Image
BUILD_BSL=FALSE # Baselibs Image
BUILD_ENV=FALSE # GEOS Enviroment (mepo and checkout_externals)
BUILD_MKL=FALSE # MKL
BUILD_FV3=FALSE # FV3 Standalone
BUILD_GCM=FALSE # GEOSgcm

while getopts hno:v-: OPT; do
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "$OPT" in
    o | os_version       ) needs_arg; OS_VERSION="$OPTARG"       ;;

        baselibs-version ) needs_arg; BASELIBS_VERSION="$OPTARG" ;;
        esmf-version     ) needs_arg; ESMF_VERSION="$OPTARG"     ;;
        gcm-version      ) needs_arg; GCM_VERSION="$OPTARG"      ;;
        fv3-version      ) needs_arg; FV3_VERSION="$OPTARG"      ;;

        no-cache    ) NO_CACHE="--no-cache" ;;
        docker-repo ) needs_arg; DOCKER_REPO="$OPTARG"      ;;
        push        ) DO_PUSH=TRUE          ;;

        build-all ) BUILD_ALL=TRUE        ;;
        build-base) BUILD_BASE=TRUE       ;;
        build-gcc ) BUILD_GCC=TRUE        ;;
        build-mpi ) BUILD_MPI=TRUE        ;;
        build-bsl ) BUILD_BSL=TRUE        ;;
        build-env ) BUILD_ENV=TRUE        ;;
        build-mkl ) BUILD_MKL=TRUE        ;;
        build-gcm ) BUILD_GCM=TRUE        ;;
        build-fv3 ) BUILD_FV3=TRUE        ;;

    h | help     ) usage; exit  ;;
    n | dry-run  ) DRYRUN=TRUE  ;;
    v | verbose  ) VERBOSE=TRUE ;;

    ??* )          die "Illegal option --$OPT" ;;  # bad long option
    ? )            exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

if [[ "$BUILD_ALL" == "TRUE" ]]
then
   BUILD_BASE=TRUE # Base Image (Ubuntu or OpenSUSE)
   BUILD_GCC=TRUE # GCC Image
   BUILD_MPI=TRUE # MPI Image
   BUILD_BSL=TRUE # Baselibs Image
   BUILD_ENV=TRUE # GEOS Enviroment (mepo and checkout_externals)
   BUILD_MKL=TRUE # MKL
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
else
   echo "Invalid osversion!"
   usage
   exit 1
fi

COMMON_DOCKER_DIR="Common"

if [[ "$DRYRUN" == "TRUE" ]]
then
   echo "Version Info:"
   echo "  OS_VERSION: ${OS_VERSION}"
   echo "  BASE_IMAGE: ${BASE_IMAGE}"
   echo "  GCC_VERSION: ${GCC_VERSION}"
   echo "  OPENMPI_VERSION: ${OPENMPI_VERSION}"
   echo "  BASELIBS_VERSION: ${BASELIBS_VERSION}"
   echo "  FV3_VERSION: ${FV3_VERSION}"
   echo "  GCM_VERSION: ${GCM_VERSION}"
   echo "  CMAKE_VERSION: ${CMAKE_VERSION}"
   echo "  ESMF_VERSION: ${ESMF_VERSION}"
   echo ""
   echo "Build Options:"
   echo "  BUILD_BASE=${BUILD_BASE}"
   echo "  BUILD_GCC=${BUILD_GCC}"
   echo "  BUILD_MPI=${BUILD_MPI}"
   echo "  BUILD_BSL=${BUILD_BSL}"
   echo "  BUILD_ENV=${BUILD_ENV}"
   echo "  BUILD_MKL=${BUILD_MKL}"
   echo "  BUILD_FV3=${BUILD_FV3}"
   echo "  BUILD_GCM=${BUILD_GCM}"
   echo ""
   echo "Docker Options:"
   echo "  DO_PUSH: ${DO_PUSH}"
   echo "  DOCKER_REPO: ${DOCKER_REPO}"
   echo "  NO_CACHE: ${NO_CACHE}"

   exit
fi

## Base Image
if [[ "$BUILD_BASE" == "TRUE" ]]
then
   docker build \
      --build-arg cmakeversion=${CMAKE_VERSION} \
      -f ${OS_DOCKER_DIR}/Dockerfile.${OS_VERSION} \
      -t ${DOCKER_REPO}/${BASE_IMAGE} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push ${DOCKER_REPO}/${BASE_IMAGE}
   fi
fi

## GCC
if [[ "$BUILD_GCC" == "TRUE" ]]
then
   docker build \
      --build-arg baseimage=${BASE_IMAGE} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.gcc \
      -t ${DOCKER_REPO}/${OS_VERSION}-gcc:${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push ${DOCKER_REPO}/${OS_VERSION}-gcc:${GCC_VERSION}
   fi
fi

## Open MPI
if [[ "$BUILD_MPI" == "TRUE" ]]
then
   docker build \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.openmpi \
      -t ${DOCKER_REPO}/${OS_VERSION}-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push ${DOCKER_REPO}/${OS_VERSION}-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## Baselibs
if [[ "$BUILD_BSL" == "TRUE" ]]
then
   docker build \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      --build-arg esmfversion=${ESMF_VERSION} \
      ${NO_CACHE} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.baselibs \
      -t ${DOCKER_REPO}/${OS_VERSION}-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push ${DOCKER_REPO}/${OS_VERSION}-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## GEOS Build Env
if [[ "$BUILD_ENV" == "TRUE" ]]
then
   docker build \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.geos-env \
      -t ${DOCKER_REPO}/${OS_VERSION}-geos-env:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push ${DOCKER_REPO}/${OS_VERSION}-geos-env:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## GEOS Build Env with MKL
if [[ "$BUILD_MKL" == "TRUE" ]]
then
   docker build \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${OS_DOCKER_DIR}/Dockerfile.geos-env-mkl \
      -t ${DOCKER_REPO}/${OS_VERSION}-geos-env-mkl:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push ${DOCKER_REPO}/${OS_VERSION}-geos-env-mkl:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## FV3 Standalone
if [[ "$BUILD_FV3" == "TRUE" ]]
then
   docker build \
      --build-arg fv3version=${FV3_VERSION} \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.geos-fv3standalone \
      -t ${DOCKER_REPO}/${OS_VERSION}-geos-fv3standalone:1.0.6 .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push ${DOCKER_REPO}/${OS_VERSION}-geos-fv3standalone:1.0.6
   fi
fi

## GEOSgcm
if [[ "$BUILD_GCM" == "TRUE" ]]
then
   docker build \
      --build-arg gcmversion=${GCM_VERSION} \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.geos-gcm \
      -t ${DOCKER_REPO}/${OS_VERSION}-geos-gcm:10.14.1 .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push ${DOCKER_REPO}/${OS_VERSION}-geos-gcm:10.14.1
   fi
fi
