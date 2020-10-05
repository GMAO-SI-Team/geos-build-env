#!/bin/bash

GCC_VERSION=10.2.0
OPENMPI_VERSION=4.0.5
BASELIBS_VERSION=6.0.16

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

## Base Image
if [[ "$BUILD_BASE" == "TRUE" ]]
then
   docker build \
      -f Dockerfile.opensuse \
      -t gmao/opensuse:15.2 .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/opensuse:15.2
   fi
fi

## GCC
if [[ "$BUILD_GCC" == "TRUE" ]]
then
   docker build \
      --build-arg version=${GCC_VERSION} \
      -f Dockerfile.gcc \
      -t gmao/opensuse15-gcc:${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/opensuse15-gcc:${GCC_VERSION}
   fi
fi

## Open MPI
if [[ "$BUILD_OPENMPI" == "TRUE" ]]
then
   docker build \
      --build-arg version=${OPENMPI_VERSION} \
      --build-arg gccversion=${GCC_VERSION} \
      -f Dockerfile.openmpi \
      -t gmao/opensuse15-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/opensuse15-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION}
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
      -t gmao/opensuse15-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/opensuse15-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
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
      -t gmao/opensuse15-geos-env:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/opensuse15-geos-env:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
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
      -t gmao/opensuse15-geos-env-mkl:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION} .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/opensuse15-geos-env-mkl:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
   fi
fi

## FV3 Standalone
if [[ "$BUILD_FV3STANDALONE" == "TRUE" ]]
then
   docker build \
      --build-arg version=1.0.6 \
      -f Dockerfile.geos-fv3standalone \
      -t gmao/opensuse15-geos-fv3standalone:1.0.6 .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/opensuse15-geos-fv3standalone:1.0.6
   fi
fi

## GEOSgcm
if [[ "$BUILD_GEOSGCM" == "TRUE" ]]
then
   docker build \
      --build-arg version=10.14.1 \
      -f Dockerfile.geos-gcm \
      -t gmao/opensuse15-geos-gcm:10.14.1 .

   if [[ "$DO_PUSH" == "TRUE" ]]
   then
      docker push gmao/opensuse15-geos-gcm:10.14.1
   fi
fi
