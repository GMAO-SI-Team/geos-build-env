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
BUILD_BASE=TRUE
BUILD_GCC=TRUE
BUILD_OPENMPI=TRUE
BUILD_BASELIBS=TRUE
BUILD_GEOSENV=TRUE
BUILD_MKL=TRUE
BUILD_FV3STANDALONE=FALSE
BUILD_GEOSGCM=FALSE

DO_PUSH=TRUE

echo "OS_VERSION: ${OS_VERSION}"
echo "BASE_IMAGE: ${BASE_IMAGE}"
echo "GCC_VERSION: ${GCC_VERSION}"
echo "OPENMPI_VERSION: ${OPENMPI_VERSION}"
echo "BASELIBS_VERSION: ${BASELIBS_VERSION}"
echo "FV3_VERSION: ${FV3_VERSION}"
echo "GCM_VERSION: ${GCM_VERSION}"
echo "CMAKE_VERSION: ${CMAKE_VERSION}"

## Base Image
if [[ "$BUILD_BASE" == "TRUE" ]]
then
   docker build \
      --build-arg cmakeversion=${CMAKE_VERSION} \
      -f ${OS_DOCKER_DIR}/Dockerfile.${OS_VERSION} \
      -t gmao/${BASE_IMAGE} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/${BASE_IMAGE}
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
      -t gmao/${OS_VERSION}-gcc:${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/${OS_VERSION}-gcc:${GCC_VERSION}
   fi
fi

## Open MPI
if [[ "$BUILD_OPENMPI" == "TRUE" ]]
then
   docker build \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.openmpi \
      -t gmao/${OS_VERSION}-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/${OS_VERSION}-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## Baselibs
if [[ "$BUILD_BASELIBS" == "TRUE" ]]
then
   docker build \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.baselibs \
      -t gmao/${OS_VERSION}-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/${OS_VERSION}-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## GEOS Build Env
if [[ "$BUILD_GEOSENV" == "TRUE" ]]
then
   docker build \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.geos-env \
      -t gmao/${OS_VERSION}-geos-env:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/${OS_VERSION}-geos-env:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
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
      -t gmao/${OS_VERSION}-geos-env-mkl:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/${OS_VERSION}-geos-env-mkl:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## FV3 Standalone
if [[ "$BUILD_FV3STANDALONE" == "TRUE" ]]
then
   docker build \
      --build-arg fv3version=${FV3_VERSION} \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.geos-fv3standalone \
      -t gmao/${OS_VERSION}-geos-fv3standalone:1.0.6 .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/${OS_VERSION}-geos-fv3standalone:1.0.6
   fi
fi

## GEOSgcm
if [[ "$BUILD_GEOSGCM" == "TRUE" ]]
then
   docker build \
      --build-arg gcmversion=${GCM_VERSION} \
      --build-arg baselibversion=${BASELIBS_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg osversion=${OS_VERSION} \
      -f ${COMMON_DOCKER_DIR}/Dockerfile.geos-gcm \
      -t gmao/${OS_VERSION}-geos-gcm:10.14.1 .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/${OS_VERSION}-geos-gcm:10.14.1
   fi
fi
