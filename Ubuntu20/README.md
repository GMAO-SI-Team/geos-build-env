# Building the GEOS Docker stack

## Base Image

This has all the `apt` commands. It also build CMake as that is too old
in Ubuntu 20:
```
docker build --cmakeversion=3.18.2 -f Dockerfile.ubuntu -t gmao/ubuntu20:20.04 .
docker push gmao/ubuntu20:20.04
```

## GCC

Note: Since CMake version requirements won't change that often, for now
we hard code in the tag for the GCC dockerfile

```
docker build --build-arg version=10.2.0 -f Dockerfile.gcc -t gmao/ubuntu20-gcc:10.2.0 .
docker push gmao/ubuntu20-gcc:10.2.0
```

## Open MPI
```
docker build --build-arg version=4.0.5 --build-arg gccversion=10.2.0 -f Dockerfile.openmpi -t gmao/ubuntu20-openmpi:4.0.5-gcc_10.2.0 .
docker push gmao/ubuntu20-openmpi:4.0.5-gcc_10.2.0
```

## Baselibs
```
docker build --build-arg version=6.0.16 --build-arg mpiversion=4.0.5 --build-arg gccversion=10.2.0 -f Dockerfile.baselibs -t gmao/ubuntu20-baselibs:6.0.16-openmpi_4.0.5-gcc_10.2.0 .
docker push gmao/ubuntu20-baselibs:6.0.16-openmpi_4.0.5-gcc_10.2.0
```

## GEOS Build Env
```
docker build --build-arg version=6.0.16 --build-arg gccversion=10.2.0 --build-arg mpiversion=4.0.5 -f Dockerfile.geos-env -t gmao/ubuntu20-geos-env:6.0.16-openmpi_4.0.5-gcc_10.2.0 .
docker push gmao/ubuntu20-geos-env:6.0.16-openmpi_4.0.5-gcc_10.2.0
```

## GEOS Build Env with MKL
```
docker build --build-arg version=6.0.16 --build-arg gccversion=10.2.0 --build-arg mpiversion=4.0.5 -f Dockerfile.geos-env-mkl -t gmao/ubuntu20-geos-env-mkl:6.0.16-openmpi_4.0.5-gcc_10.2.0 .
docker push gmao/ubuntu20-geos-env-mkl:6.0.16-openmpi_4.0.5-gcc_10.2.0
```

## FV3 Standalone
```
docker build --build-arg version=1.0.6 -f Dockerfile.geos-fv3standalone -t gmao/ubuntu20-geos-fv3standalone:1.0.6 .
docker push gmao/ubuntu20-geos-fv3standalone:1.0.6
```
   
## GEOSgcm
```
docker build --build-arg version=10.14.1 -f Dockerfile.geos-gcm -t gmao/ubuntu20-geos-gcm:10.14.1 .
docker push gmao/ubuntu20-geos-gcm:10.14.1
```
