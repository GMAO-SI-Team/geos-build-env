#!/bin/bash

CMAKE_VERSION=3.18.2
GCC_VERSION=10.2.0
OPENMPI_VERSION=4.0.5
BASELIBS_VERSION=6.0.16

## Base Image
PUSH_BASE=TRUE
PUSH_CMAKE=TRUE
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
   docker push gmao/ubuntu20:20.04
fi

## CMake
if [[ "$PUSH_CMAKE" == "TRUE" ]]
then
   docker push gmao/ubuntu20-cmake:${CMAKE_VERSION}
fi

## GCC
if [[ "$PUSH_GCC" == "TRUE" ]]
then
   docker push gmao/ubuntu20-gcc:${GCC_VERSION}
fi

## Open MPI
if [[ "$PUSH_OPENMPI" == "TRUE" ]]
then
   docker push gmao/ubuntu20-openmpi:${OPENMPI_VERSION}-gcc_${GCC_VERSION}
fi

## Baselibs
if [[ "$PUSH_BASELIBS" == "TRUE" ]]
then
   docker push gmao/ubuntu20-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
fi

## GEOS Build Env
if [[ "$PUSH_GEOSENV" == "TRUE" ]]
then
   docker push gmao/ubuntu20-geos-env:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
fi

## GEOS Build Env with MKL
if [[ "$PUSH_MKL" == "TRUE" ]]
then
   docker push gmao/ubuntu20-geos-env-mkl:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
fi

## FV3 Standalone
if [[ "$PUSH_FV3STANDALONE" == "TRUE" ]]
then
   docker push gmao/ubuntu20-geos-fv3standalone:1.0.6
fi

## GEOSgcm
if [[ "$PUSH_GEOSGCM" == "TRUE" ]]
then
   docker push gmao/ubuntu20-geos-gcm:10.14.1
fi
