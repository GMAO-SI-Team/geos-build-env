# OpenSUSE 15 Dockerfiles

## Base Image

This has all the `zypper` commands:
```
docker build -f Dockerfile.opensuse -t gmao/opensuse:15.2 .
docker push gmao/opensuse:15.2
```

## GEOS Build Env with MKL
```
docker build --build-arg baselibversion=6.0.16 --build-arg gccversion=10.2.0 --build-arg mpiversion=4.0.5 -f Dockerfile.geos-env-mkl -t gmao/opensuse15-geos-env-mkl:6.0.16-openmpi_4.0.5-gcc_10.2.0 .
docker push gmao/opensuse15-geos-env-mkl:6.0.16-openmpi_4.0.5-gcc_10.2.0
```
