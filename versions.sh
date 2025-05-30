#!/bin/bash

CMAKE_VERSION=3.30.5

GCC_VERSION=14.2.0
OPENMPI_VERSION=5.0.5

# Note Intel 2024.1 apt image seems to have
# an issue with omp_lib: https://community.intel.com/t5/Intel-Fortran-Compiler/After-upgrading-ifort-no-longer-finds-include-dir-for-OpenMP/m-p/1602472

# NOTE NOTE Intel ifort is now dead! The versions are hardcoded in the build script
INTEL_VERSION=2025.1
INTELMPI_VERSION=2021.15

BASELIBS_VERSION='v8.14.0'

FV3_VERSION='v2.9.0'
GCM_VERSION='v12.0.0'
BCS_VERSION='v12.0.0'
