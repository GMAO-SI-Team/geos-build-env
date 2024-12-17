# Ubuntu24 Dockerfiles

## Base Image

This has all the `apt` commands. It also build CMake as that is too old
in Ubuntu 20:
```
docker build --cmakeversion=3.18.2 -f Dockerfile.ubuntu -t gmao/ubuntu24:24.04 .
docker push gmao/ubuntu24:24.04
```

## GEOS Build Env with MKL
```
docker build --build-arg baselibversion=6.0.16 --build-arg gccversion=10.2.0 --build-arg mpiversion=4.0.5 -f Dockerfile.geos-env-mkl -t gmao/ubuntu24-geos-env-mkl:6.0.16-openmpi_4.0.5-gcc_10.2.0 .
docker push gmao/ubuntu24-geos-env-mkl:6.0.16-openmpi_4.0.5-gcc_10.2.0
```

