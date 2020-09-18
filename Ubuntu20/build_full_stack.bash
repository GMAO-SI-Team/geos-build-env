#!/bin/bash

CMAKE_VERSION=3.18.2
GCC_VERSION=10.2.0
OPENMPI_VERSION=4.0.5
BASELIBS_VERSION=6.0.16

## Base Image
BUILD_BASE=FALSE
BUILD_CMAKE=FALSE
BUILD_GCC=FALSE
BUILD_OPENMPI=FALSE
BUILD_BASELIBS=FALSE
BUILD_GEOSENV=FALSE
BUILD_MKL=TRUE
BUILD_FV3STANDALONE=FALSE
BUILD_GEOSGCM=FALSE

DO_PUSH=FALSE

## Base Image
if [[ "$BUILD_BASE" == "TRUE" ]]
then
   docker build \
      -f Dockerfile.ubuntu \
      -t gmao/ubuntu20:20.04 .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/ubuntu20:20.04
   fi
fi

## CMake
if [[ "$BUILD_CMAKE" == "TRUE" ]]
then
   docker build \
      --build-arg version=${CMAKE_VERSION} \
      -f Dockerfile.cmake \
      -t gmao/ubuntu20-cmake:${CMAKE_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/ubuntu20-cmake:${CMAKE_VERSION}
   fi
fi

## GCC
if [[ "$BUILD_GCC" == "TRUE" ]]
then
   docker build \
      --build-arg version=${GCC_VERSION} \
      -f Dockerfile.gcc \
      -t gmao/ubuntu20-gcc:${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/ubuntu20-gcc:${GCC_VERSION}
   fi
fi

## Open MPI
if [[ "$BUILD_OPENMPI" == "TRUE" ]]
then
   docker build \
      --build-arg version=${OPENMPI_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      -f Dockerfile.openmpi \
      -t gmao/ubuntu20-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/ubuntu20-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## Baselibs
if [[ "$BUILD_BASELIBS" == "TRUE" ]]
then
   docker build \
      --build-arg version=${BASELIBS_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      -f Dockerfile.baselibs \
      -t gmao/ubuntu20-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/ubuntu20-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## GEOS Build Env
if [[ "$BUILD_GEOSENV" == "TRUE" ]]
then
   docker build \
      --build-arg version=${BASELIBS_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      -f Dockerfile.geos-env \
      -t gmao/ubuntu20-geos-env:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/ubuntu20-geos-env:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## GEOS Build Env with MKL
if [[ "$BUILD_MKL" == "TRUE" ]]
then
   docker build \
      --build-arg version=${BASELIBS_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      --build-arg mpiversion=${OPENMPI_VERSION} \
      -f Dockerfile.geos-env-mkl \
      -t gmao/ubuntu20-geos-env-mkl:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/ubuntu20-geos-env-mkl:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## FV3 Standalone
if [[ "$BUILD_FV3STANDALONE" == "TRUE" ]]
then
   docker build \
      --build-arg version=1.0.6 \
      -f Dockerfile.geos-fv3standalone \
      -t gmao/ubuntu20-geos-fv3standalone:1.0.6 .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/ubuntu20-geos-fv3standalone:1.0.6
   fi
fi

## GEOSgcm
if [[ "$BUILD_GEOSGCM" == "TRUE" ]]
then
   docker build \
      --build-arg version=10.14.1 \
      -f Dockerfile.geos-gcm \
      -t gmao/ubuntu20-geos-gcm:10.14.1 .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/ubuntu20-geos-gcm:10.14.1
   fi
fi
