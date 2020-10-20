#!/bin/bash

die () {
   echo >&2 "$@"
   exit 1
}

usage () {
   echo "Usage: $0 <osversion>"
   echo "   where <osversion> is either opensuse15 or ubuntu20"
}

# Check we have one argument
if [ "$#" -ne 1 ]
then
   usage
   exit 1
else
   OS_VERSION=$1
fi

# Check we have a valid os
if [[ "$OS_VERSION" == "opensuse15" ]]
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

source ./versions.sh

## Base Image
PUSH_BASE=TRUE
PUSH_GCC=TRUE
PUSH_OPENMPI=TRUE
PUSH_BASELIBS=TRUE
PUSH_GEOSENV=TRUE
PUSH_MKL=TRUE
PUSH_FV3STANDALONE=TRUE
PUSH_GEOSGCM=TRUE

## Base Image
if [[ "$PUSH_BASE" == "TRUE" ]]
then
   docker push gmao/${BASE_IMAGE}
fi

## GCC
if [[ "$PUSH_GCC" == "TRUE" ]]
then
   docker push gmao/${OS_VERSION}-gcc:${GCC_VERSION}
fi

## Open MPI
if [[ "$PUSH_OPENMPI" == "TRUE" ]]
then
   docker push gmao/${OS_VERSION}-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION}
fi

## Baselibs
if [[ "$PUSH_BASELIBS" == "TRUE" ]]
then
   docker push gmao/${OS_VERSION}-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
fi

## GEOS Build Env
if [[ "$PUSH_GEOSENV" == "TRUE" ]]
then
   docker push gmao/${OS_VERSION}-geos-env:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
fi

## GEOS Build Env with MKL
if [[ "$PUSH_MKL" == "TRUE" ]]
then
   docker push gmao/${OS_VERSION}-geos-env-mkl:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
fi

## FV3 Standalone
if [[ "$PUSH_FV3STANDALONE" == "TRUE" ]]
then
   docker push gmao/${OS_VERSION}-geos-fv3standalone:${FV3_VERSION}
fi

## GEOSgcm
if [[ "$PUSH_GEOSGCM" == "TRUE" ]]
then
   docker push gmao/${OS_VERSION}-geos-gcm:${GCM_VERSION}
fi
