#!/bin/bash

CMAKE_VERSION=3.29.1

GCC_VERSION=13.2.0
OPENMPI_VERSION=5.0.2

# Note Intel 2024.1 apt image seems to have
# an issue with omp_lib: https://community.intel.com/t5/Intel-Fortran-Compiler/After-upgrading-ifort-no-longer-finds-include-dir-for-OpenMP/m-p/1602472
INTEL_VERSION=2024.0
INTELMPI_VERSION=2021.11

BASELIBS_VERSION='v8.0.2'

FV3_VERSION='v2.9.0'
GCM_VERSION='v11.3.0'
BCS_VERSION='v11.3.0'
