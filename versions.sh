#!/bin/bash

CMAKE_VERSION=3.24.0
GCC_VERSION=12.1.0
OPENMPI_VERSION=4.1.4

# There is a weird issue where Intel doesn't
# have an Intel MPI 2022.1 on the apt server
INTEL_VERSION=2022.1.0
INTELMPI_VERSION=2021.6.0
BASELIBS_VERSION='v7.5.0'

FV3_VERSION='v1.8.0'
GCM_VERSION='v10.22.5'
BCS_VERSION=${GCM_VERSION}
