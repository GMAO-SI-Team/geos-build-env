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

die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "Error: No arg for --$OPT option. Did you use an equals sign?"; fi; }

source ${SCRIPTDIR}/versions.sh

DEFAULT_DOCKER_REPO='gmao'
DOCKER_REPO=${DEFAULT_DOCKER_REPO}

usage () {
   cat << HELP_USAGE
   Usage: $0 -o <osversion>|--os-version=<osversion> <options>

   REQUIRED:
      -o <osversion>|--os-version=<osversion>
         OS version to build (REQUIRED. Allowed values: ubuntu20, ubuntu24, opensuse15, centos8)
      --compiler=<compiler>
         compiler to use (REQUIRED. Allowed values: ifort, ifx, gnu)

   BUILD OPTIONS:
      --build-base
         Build the Base Linux image
      --build-ifx
         Build the ifx Compiler and MPI image
      --build-ifort
         Build the ifort Compiler and MPI image
      --build-gcc
         Build the GCC image
      --build-openmpi
         Build the Open MPI image
      --build-bsl
         Build the ESMA Baselibs image
      --build-env
         Build the GEOS Environment image
      --build-bcs
         Build the GEOS Environment image with BCs
      --build-mkl
         Build the Intel MKL image
      --build-all
         Build the above images (images needed to build GEOSgcm)

      --build-gcm
         Build the GEOSgcm image
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

COMPILER=UNKNOWN

BUILD_ALL=FALSE

BUILD_BASE=FALSE    # Base Image (Ubuntu 20, Ubuntu 24, OpenSUSE 15, CentOS 8)
BUILD_GCC=FALSE     # GCC Image
BUILD_IFX=FALSE     # ifx Image
BUILD_IFORT=FALSE   # Ifort Image
BUILD_OPENMPI=FALSE # MPI Image
BUILD_BSL=FALSE     # Baselibs Image
BUILD_ENV=FALSE     # GEOS Enviroment (mepo and checkout_externals)
BUILD_MKL=FALSE     # MKL
BUILD_BCS=FALSE     # BCS Image
BUILD_FV3=FALSE     # FV3 Standalone
BUILD_GCM=FALSE     # GEOSgcm

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
        gcm-version      ) needs_arg; GCM_VERSION="$OPTARG"      ;;
        fv3-version      ) needs_arg; FV3_VERSION="$OPTARG"      ;;
        bcs-version      ) needs_arg; BCS_VERSION="$OPTARG"      ;;

        no-cache    ) NO_CACHE="--no-cache" ;;
        docker-repo ) needs_arg; DOCKER_REPO="$OPTARG"      ;;
        push        ) DO_PUSH=TRUE          ;;

        build-all     ) BUILD_ALL=TRUE     ;;
        build-base    ) BUILD_BASE=TRUE    ;;
        build-gcc     ) BUILD_GCC=TRUE     ;;
        build-ifx     ) BUILD_IFX=TRUE     ;;
        build-ifort   ) BUILD_IFORT=TRUE   ;;
        build-openmpi ) BUILD_OPENMPI=TRUE ;;
        build-bsl     ) BUILD_BSL=TRUE     ;;
        build-env     ) BUILD_ENV=TRUE     ;;
        build-mkl     ) BUILD_MKL=TRUE     ;;
        build-bcs     ) BUILD_BCS=TRUE     ;;
        build-gcm     ) BUILD_GCM=TRUE     ;;
        build-fv3     ) BUILD_FV3=TRUE     ;;

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
   OS_DOCKER_DIR="${SCRIPTDIR}/OpenSUSE15"
elif [[ "$OS_VERSION" == "ubuntu20" ]]
then
   BASE_IMAGE="ubuntu:20.04"
   OS_DOCKER_DIR="${SCRIPTDIR}/Ubuntu20"
elif [[ "$OS_VERSION" == "ubuntu24" ]]
then
   BASE_IMAGE="ubuntu:24.04"
   OS_DOCKER_DIR="${SCRIPTDIR}/Ubuntu24"
elif [[ "$OS_VERSION" == "centos8" ]]
then
   BASE_IMAGE="centos:8"
   OS_DOCKER_DIR="${SCRIPTDIR}/Centos8"
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
elif [[ "$COMPILER" == "ifx" ]]
then
   COMPILER_NAME="ifx"
   COMPILER_VERSION=${INTEL_VERSION}
   MPI_NAME="intelmpi"
   MPI_VERSION=${INTELMPI_VERSION}
   FINAL_DOCKER_IMAGE_NAME="geos-env"
elif [[ "$COMPILER" == "ifort" ]]
then
   COMPILER_NAME="ifort"
   MPI_NAME="intelmpi"
   # We hardcode the ifort versions as
   # it is "stable" and will never change
   # unlike ifx
   COMPILER_VERSION="2021.13"
   INTEL_VERSION="2024.2"
   MPI_VERSION="2021.13"
   INTELMPI_VERSION="2021.13"
   FINAL_DOCKER_IMAGE_NAME="geos-env"
elif [[ "$COMPILER" == "gnu" ]]
then
   COMPILER_NAME="gcc"
   COMPILER_VERSION=${GCC_VERSION}
   MPI_NAME="openmpi"
   MPI_VERSION=${OPENMPI_VERSION}
   FINAL_DOCKER_IMAGE_NAME="geos-env-mkl"
else
   echo "Invalid compiler!"
   usage
   exit 1
fi

if [[ "$BUILD_ALL" == "TRUE" ]]
then
   if [[ "$COMPILER" == "ifx" ]]
   then
      BUILD_BASE=TRUE # Base Image (Ubuntu 20, Ubuntu 24, OpenSUSE 15, CentOS 8)
      BUILD_IFX=TRUE # ifx Compiler and MPI Image
      BUILD_BSL=TRUE # Baselibs Image
      BUILD_ENV=TRUE # GEOS Enviroment (mepo and checkout_externals)
   elif [[ "$COMPILER" == "ifort" ]]
   then
      BUILD_BASE=TRUE # Base Image (Ubuntu 20, Ubuntu 24, OpenSUSE 15, CentOS 8)
      BUILD_IFORT=TRUE # Ifort Compiler and MPI Image
      BUILD_BSL=TRUE # Baselibs Image
      BUILD_ENV=TRUE # GEOS Enviroment (mepo and checkout_externals)
   elif [[ "$COMPILER" == "gnu" ]]
   then
      BUILD_BASE=TRUE # Base Image (Ubuntu 20, Ubuntu 24, OpenSUSE 15, CentOS 8)
      BUILD_GCC=TRUE # GCC Image
      BUILD_OPENMPI=TRUE # MPI Image
      BUILD_BSL=TRUE # Baselibs Image
      BUILD_ENV=TRUE # GEOS Enviroment (mepo and checkout_externals)
      BUILD_MKL=TRUE # MKL
   fi
fi

if [[ "$COMPILER" == "intel" && "$BUILD_MKL" == "TRUE" ]]
then
   echo "ERROR! The Intel image already provides MKL"
   exit 1
fi

if [[ "$COMPILER" == "ifort" && "$BUILD_MKL" == "TRUE" ]]
then
   echo "ERROR! The Intel ifort image already provides MKL"
   exit 1
fi

COMMON_DOCKER_DIR="${SCRIPTDIR}/Common"
ROOT_DIR=$(dirname ${SCRIPTDIR})
#echo $ROOT_DIR

if [[ "$DRYRUN" == "TRUE" ]]
then
   echo "Version Info:"
   echo "  OS_VERSION: ${OS_VERSION}"
   echo "  BASE_IMAGE: ${BASE_IMAGE}"
   echo "  GCC_VERSION: ${GCC_VERSION}"
   echo "  INTEL_VERSION: ${INTEL_VERSION}"
   echo "  INTELMPI_VERSION: ${INTELMPI_VERSION}"
   echo "  OPENMPI_VERSION: ${OPENMPI_VERSION}"
   echo "  BASELIBS_VERSION: ${BASELIBS_VERSION}"
   echo "  FV3_VERSION: ${FV3_VERSION}"
   echo "  GCM_VERSION: ${GCM_VERSION}"
   echo "  BCS_VERSION: ${BCS_VERSION}"
   echo "  CMAKE_VERSION: ${CMAKE_VERSION}"
   echo "  ESMF_VERSION: ${ESMF_VERSION}"
   echo ""
   echo "Build Options:"
   echo "  BUILD_BASE=${BUILD_BASE}"
   echo "  BUILD_GCC=${BUILD_GCC}"
   echo "  BUILD_IFX=${BUILD_IFX}"
   echo "  BUILD_IFORT=${BUILD_IFORT}"
   echo "  BUILD_OPENMPI=${BUILD_OPENMPI}"
   echo "  BUILD_BSL=${BUILD_BSL}"
   echo "  BUILD_ENV=${BUILD_ENV}"
   echo "  BUILD_MKL=${BUILD_MKL}"
   echo "  BUILD_BCS=${BUILD_BCS}"
   echo "  BUILD_FV3=${BUILD_FV3}"
   echo "  BUILD_GCM=${BUILD_GCM}"
   echo ""
   echo "Docker Options:"
   echo "  DO_PUSH: ${DO_PUSH}"
   echo "  DOCKER_REPO: ${DOCKER_REPO}"
   echo "  NO_CACHE: ${NO_CACHE}"
   echo ""
   echo "Commands that will run:"
   echo ""
fi

doCmd() {
  if [[ "$DRYRUN" == "TRUE" ]]
  then 
     echo "$@"
  else
     "$@"
  fi
}

## Base Image
if [[ "$BUILD_BASE" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg cmakeversion=${CMAKE_VERSION} \
      -f ${OS_DOCKER_DIR}/Dockerfile.${OS_VERSION} \
      -t ${DOCKER_REPO}/${BASE_IMAGE} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${BASE_IMAGE}
   fi
fi

## GCC
if [[ "$BUILD_GCC" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg baseimage=${BASE_IMAGE} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.gcc \
      -t ${DOCKER_REPO}/${OS_VERSION}-gcc:${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${OS_VERSION}-gcc:${GCC_VERSION}
   fi
fi

## ifx
if [[ "$BUILD_IFX" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg baseimage=${BASE_IMAGE} \
      --build-arg intelversion=${INTEL_VERSION} \
      --build-arg intelmpiversion=${INTELMPI_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${OS_DOCKER_DIR}/Dockerfile.ifx \
      -t ${DOCKER_REPO}/${OS_VERSION}-${MPI_NAME}:${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${OS_VERSION}-${MPI_NAME}:${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION}
   fi
fi

## ifort
if [[ "$BUILD_IFORT" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg baseimage=${BASE_IMAGE} \
      --build-arg intelversion=${INTEL_VERSION} \
      --build-arg intelmpiversion=${INTELMPI_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${OS_DOCKER_DIR}/Dockerfile.ifort \
      -t ${DOCKER_REPO}/${OS_VERSION}-${MPI_NAME}:${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${OS_VERSION}-${MPI_NAME}:${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION}
   fi
fi

## Open MPI
if [[ "$BUILD_OPENMPI" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.openmpi \
      -t ${DOCKER_REPO}/${OS_VERSION}-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${OS_VERSION}-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## Baselibs
if [[ "$BUILD_BSL" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg mpiname=${MPI_NAME} \
      --build-arg mpiversion=${MPI_VERSION} \
      --build-arg compilername=${COMPILER_NAME} \
      --build-arg compilerversion=${COMPILER_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      --build-arg esmfversion=${ESMF_VERSION} \
      ${NO_CACHE} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.baselibs \
      -t ${DOCKER_REPO}/${OS_VERSION}-baselibs:${BASELIBS_VERSION}-${MPI_NAME}_${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${OS_VERSION}-baselibs:${BASELIBS_VERSION}-${MPI_NAME}_${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION}
   fi
fi

## GEOS Build Env
if [[ "$BUILD_ENV" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg mpiname=${MPI_NAME} \
      --build-arg mpiversion=${MPI_VERSION} \
      --build-arg compilername=${COMPILER_NAME} \
      --build-arg compilerversion=${COMPILER_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      --build-arg mepoversion=${MEPO_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.geos-env \
      -t ${DOCKER_REPO}/${OS_VERSION}-geos-env:${BASELIBS_VERSION}-${MPI_NAME}_${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${OS_VERSION}-geos-env:${BASELIBS_VERSION}-${MPI_NAME}_${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION}
   fi
fi

## GEOS Build Env with MKL
if [[ "$BUILD_MKL" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg mpiname=${MPI_NAME} \
      --build-arg mpiversion=${MPI_VERSION} \
      --build-arg compilername=${COMPILER_NAME} \
      --build-arg compilerversion=${COMPILER_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${OS_DOCKER_DIR}/Dockerfile.geos-env-mkl \
      -t ${DOCKER_REPO}/${OS_VERSION}-geos-env-mkl:${BASELIBS_VERSION}-${MPI_NAME}_${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${OS_VERSION}-geos-env-mkl:${BASELIBS_VERSION}-${MPI_NAME}_${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION}
   fi
fi

## GEOS Build Env with BCs
if [[ "$BUILD_BCS" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg mpiname=${MPI_NAME} \
      --build-arg mpiversion=${MPI_VERSION} \
      --build-arg compilername=${COMPILER_NAME} \
      --build-arg compilerversion=${COMPILER_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      --build-arg bcsversion=${BCS_VERSION} \
      --build-arg imagename=${FINAL_DOCKER_IMAGE_NAME} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.geos-env-bcs \
      -t ${DOCKER_REPO}/${OS_VERSION}-geos-env-bcs:${BASELIBS_VERSION}-${MPI_NAME}_${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION}-bcs_${BCS_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${OS_VERSION}-geos-env-bcs:${BASELIBS_VERSION}-${MPI_NAME}_${MPI_VERSION}-${COMPILER_NAME}_${COMPILER_VERSION}-bcs_${BCS_VERSION}
   fi
fi

## FV3 Standalone
if [[ "$BUILD_FV3" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg fv3version=${FV3_VERSION} \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg mpiname=${MPI_NAME} \
      --build-arg mpiversion=${MPI_VERSION} \
      --build-arg compilername=${COMPILER_NAME} \
      --build-arg compilerversion=${COMPILER_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      --build-arg imagename=${FINAL_DOCKER_IMAGE_NAME} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.geos-fv3standalone \
      -t ${DOCKER_REPO}/${OS_VERSION}-geos-fv3standalone:${FV3_VERSION}_${COMPILER_NAME}_${COMPILER_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${OS_VERSION}-geos-fv3standalone:${FV3_VERSION}_${COMPILER_NAME}_${COMPILER_VERSION}
   fi
fi

## GEOSgcm
if [[ "$BUILD_GCM" == "TRUE" ]]
then
   doCmd docker build \
      --build-arg gcmversion=${GCM_VERSION} \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg mpiname=${MPI_NAME} \
      --build-arg mpiversion=${MPI_VERSION} \
      --build-arg compilername=${COMPILER_NAME} \
      --build-arg compilerversion=${COMPILER_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.geos-gcm \
      -t ${DOCKER_REPO}/${OS_VERSION}-geos-gcm:${GCM_VERSION}_${COMPILER_NAME}_${COMPILER_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      doCmd docker push ${DOCKER_REPO}/${OS_VERSION}-geos-gcm:${GCM_VERSION}_${COMPILER_NAME}_${COMPILER_VERSION}
   fi
fi
