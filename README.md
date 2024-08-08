# Repo for the Dockerfiles for geos-build-env

The main script to use here is `build_full_stack.bash`. The options for
it are:
```console
$ ./build_full_stack.bash -h
   Usage: ./build_full_stack.bash -o <osversion>|--os-version=<osversion> <options>

   REQUIRED:
      -o <osversion>|--os-version=<osversion>
         OS version to build (REQUIRED. Allowed values: ubuntu20, ubuntu24, opensuse15, centos8)
      --compiler=<compiler>
         compiler to use (REQUIRED. Allowed values: ifort, intel, gnu)

   BUILD OPTIONS:
      --build-base
         Build the Base Linux image
      --build-intel
         Build the Intel ifx Compiler and MPI image
      --build-ifort
         Build the Intel ifort Compiler and MPI image
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
         Docker Repository to push to (Default: gmao)
      --no-cache
         Build image with --no-cache (only affects Baselibs)

   VERSION OPTIONS:
      --baselibs-version=<tag>
         Tag of Baselibs to checkout (Default: v8.5.0)
      --esmf-version=<tag>
         Tag of ESMF submodule to checkout in Baselibs (Default: Tag in Baselibs being built)
      --gcm-version=<tag>
         Tag of GCM to build (Default: v11.6.0, useful only if --build-gcm is on)
      --fv3-version=<tag>
         Tag of FV3 Standalone to build (Default: v2.9.0, useful only if --build-fv3 is on)

   OTHER OPTIONS:
      -h|--help
         Print this usage
      -v|--verbose
         Verbose
      -n|--dry-run
         Output the various settings and exit
```
