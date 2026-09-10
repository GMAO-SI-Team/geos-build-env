# Repo for the Dockerfiles for geos-build-env

The main script to use here is `build_full_stack.bash`.

## Common Usage Examples

### 1. Update the BCs image for all compilers and Baselibs

When a new Boundary Conditions (BCs) version is tagged (e.g. `v12.0.0`), rebuild only the BCs layer (`--build-bcs`) on top of existing environment images:

```bash
# GNU (GCC 15)
./build_full_stack.bash -o ubuntu24 --compiler=gnu --gcc-version=15.2.0 --openmpi-version=5.0.5 --baselibs-version=v8.33.0,v9.13.0 --bcs-version=v12.0.0 --build-bcs --push

# GNU (GCC 16.2 / Open MPI 5.0.11rc1)
./build_full_stack.bash -o ubuntu24 --compiler=gnu --gcc-version=16.2.0 --openmpi-version=5.0.11rc1 --baselibs-version=v8.33.0,v9.13.0 --bcs-version=v12.0.0 --build-bcs --push

# Intel ifort
./build_full_stack.bash -o ubuntu24 --compiler=ifort --baselibs-version=v8.33.0,v9.13.0 --bcs-version=v12.0.0 --build-bcs --push

# Intel ifx
./build_full_stack.bash -o ubuntu24 --compiler=ifx --baselibs-version=v8.33.0,v9.13.0 --bcs-version=v12.0.0 --build-bcs --push
```

---

### 2. Update the Regression image for all compilers and Baselibs

When regression data is updated (e.g. `v1.0.0`), rebuild only the regression layer (`--build-regression`) on top of existing environment images *(Note: regression images do not depend on `--bcs-version`)*:

```bash
# GNU (GCC 15)
./build_full_stack.bash -o ubuntu24 --compiler=gnu --gcc-version=15.2.0 --openmpi-version=5.0.5 --baselibs-version=v8.33.0,v9.13.0 --regression-version=v1.0.0 --build-regression --push

# GNU (GCC 16.2 / Open MPI 5.0.11rc1)
./build_full_stack.bash -o ubuntu24 --compiler=gnu --gcc-version=16.2.0 --openmpi-version=5.0.11rc1 --baselibs-version=v8.33.0,v9.13.0 --regression-version=v1.0.0 --build-regression --push

# Intel ifort
./build_full_stack.bash -o ubuntu24 --compiler=ifort --baselibs-version=v8.33.0,v9.13.0 --regression-version=v1.0.0 --build-regression --push

# Intel ifx
./build_full_stack.bash -o ubuntu24 --compiler=ifx --baselibs-version=v8.33.0,v9.13.0 --regression-version=v1.0.0 --build-regression --push
```

---

### 3. Update Baselibs for all compilers (and rebuild downstream stack)

When a new version of Baselibs is released, use `--build-baselibs-stack` (or `--build-bsl-stack`) to automatically rebuild Baselibs and all downstream dependent images (`--build-bsl`, `--build-env`, `--build-bcs`, `--build-regression`, and `--build-mkl` for GNU automatically).

> **Tip:** Use `--prune` to automatically clean builder cache between Baselibs iterations.

```bash
# GNU (GCC 15)
./build_full_stack.bash -o ubuntu24 --compiler=gnu --gcc-version=15.2.0 --openmpi-version=5.0.5 --baselibs-version=v8.33.0,v9.13.0 --build-baselibs-stack --push --prune

# GNU (GCC 16.2 / Open MPI 5.0.11rc1)
./build_full_stack.bash -o ubuntu24 --compiler=gnu --gcc-version=16.2.0 --openmpi-version=5.0.11rc1 --baselibs-version=v8.33.0,v9.13.0 --build-baselibs-stack --push --prune

# Intel ifort
./build_full_stack.bash -o ubuntu24 --compiler=ifort --baselibs-version=v8.33.0,v9.13.0 --build-baselibs-stack --push --prune

# Intel ifx
./build_full_stack.bash -o ubuntu24 --compiler=ifx --baselibs-version=v8.33.0,v9.13.0 --build-baselibs-stack --push --prune
```

*(You can also pass single Baselibs versions, e.g. `--baselibs-version=v9.13.0`)*

---

### 4. Build the entire stack from scratch (Base OS → Compilers → Baselibs → BCs/Regression)

When the base OS Dockerfile changes (e.g. adding new system packages like `python3-netcdf4`), rebuild the base image (`--build-base`), compiler/MPI images, and the Baselibs stack:

```bash
# GNU (Base OS -> GCC 15 -> Open MPI -> Baselibs stack)
./build_full_stack.bash -o ubuntu24 --compiler=gnu --gcc-version=15.2.0 --openmpi-version=5.0.5 --baselibs-version=v8.33.0,v9.13.0 --build-base --build-gcc --build-openmpi --build-baselibs-stack --push --prune

# GNU (Base OS -> GCC 16.2 -> Open MPI 5.0.11rc1 -> Baselibs stack)
./build_full_stack.bash -o ubuntu24 --compiler=gnu --gcc-version=16.2.0 --openmpi-version=5.0.11rc1 --baselibs-version=v8.33.0,v9.13.0 --build-base --build-gcc --build-openmpi --build-baselibs-stack --push --prune

# Intel ifort (Base OS -> ifort -> Baselibs stack)
./build_full_stack.bash -o ubuntu24 --compiler=ifort --baselibs-version=v8.33.0,v9.13.0 --build-base --build-ifort --build-baselibs-stack --push --prune

# Intel ifx (Base OS -> ifx -> Baselibs stack)
./build_full_stack.bash -o ubuntu24 --compiler=ifx --baselibs-version=v8.33.0,v9.13.0 --build-base --build-ifx --build-baselibs-stack --push --prune
```

---

### Disk Space Management Tip

To avoid running out of disk space:
1. `--prune` automatically runs `docker builder prune -f` after each Baselibs iteration (keeps your base OS and compiler images intact).
2. Between **different compiler runs** (e.g. after GNU finishes and before starting Intel), run a full prune to free disk space:
   ```bash
   docker system prune -a -f
   ```

---

## Full Script Usage (`build_full_stack.bash -h`)

```console
$ ./build_full_stack.bash -h
   Usage: ./build_full_stack.bash -o <osversion>|--os-version=<osversion> <options>

   REQUIRED:
      -o <osversion>|--os-version=<osversion>
         OS version to build (REQUIRED. Allowed values: ubuntu20, ubuntu24, opensuse15, centos8)
      --compiler=<compiler>
         compiler to use (REQUIRED. Allowed values: ifort, ifx, gnu)

   BUILD OPTIONS:
      --build-base
         Build the Base Linux image
      --build-ifx
         Build the ifx Compiler and MPI image
      --build-ifort
         Build the ifort Compiler and MPI image
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
      --build-regression
         Build the GEOS Environment image with Regression test data
      --build-mkl
         Build the Intel MKL image
      --build-blas
         Build the OpenBLAS image
      --build-baselibs-stack
         Build all images from Baselibs up (Baselibs, Environment, MKL [if GNU], BCs, Regression)
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
      --baselibs-version=<tag>[,<tag>...]
         Tag(s) of Baselibs to build. Can be comma-separated, space-separated,
         or specified multiple times (Default: v9.13.0)
      --esmf-version=<tag>
         Tag of ESMF submodule to checkout in Baselibs (Default: Tag in Baselibs being built)
      --gcm-version=<tag>
         Tag of GCM to build (Default: v12.0.0, useful only if --build-gcm is on)
      --fv3-version=<tag>
         Tag of FV3 Standalone to build (Default: v2.9.0, useful only if --build-fv3 is on)
      --bcs-version=<tag>
         Tag of the BCs to use (Default: v12.0.0)
      --regression-version=<tag>
         Tag of the Regression data to use (Default: v1.0.0)
      --gcc-version=<tag>
         Version of GCC to use (Default: 15.2.0)
      --openmpi-version=<tag>
         Version of Open MPI to use (Default: 5.0.5)

   OTHER OPTIONS:
      --prune
         Prune Docker builder cache after each Baselibs iteration
      -h|--help
         Print this usage
      -v|--verbose
         Verbose
      -n|--dry-run
         Output the various settings and exit
```
