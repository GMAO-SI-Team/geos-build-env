#!/bin/bash

CMAKE_VERSION=3.30.5

GCC_VERSION=14.2.0
OPENMPI_VERSION=5.0.5

# Note Intel 2024.1 apt image seems to have
# an issue with omp_lib: https://community.intel.com/t5/Intel-Fortran-Compiler/After-upgrading-ifort-no-longer-finds-include-dir-for-OpenMP/m-p/1602472

# NOTE NOTE Intel ifort is now dead!
INTEL_VERSION=2025.0
IFX_VERSION=2025.0
IFORT_VERSION=2021.13
INTELMPI_VERSION=2021.14

BASELIBS_VERSION='v7.27.0'

MEPO_VERSION='v1.52.0'

FV3_VERSION='v2.9.0'
GCM_VERSION='v11.6.0'
BCS_VERSION='v11.6.0'
