# Common Dockerfiles

## GCC

```
docker build --build-arg gccversion=14.2.0 -f Dockerfile.gcc -t gmao/<osversion>-gcc:14.2.0 .
docker push gmao/<osversion>-gcc:14.2.0
```

## Open MPI
```
docker build --build-arg mpiversion=5.0.5 --build-arg gccversion=14.2.0 -f Dockerfile.openmpi -t gmao/<osversion>-openmpi:5.0.5-gcc_14.2.0 .
docker push gmao/<osversion>-openmpi:5.0.5-gcc_14.2.0
```

## Baselibs
```
docker build --build-arg baselibversion=8.7.0 --build-arg mpiversion=5.0.5 --build-arg gccversion=14.2.0 -f Dockerfile.baselibs -t gmao/<osversion>-baselibs:8.7.0-openmpi_5.0.5-gcc_14.2.0 .
docker push gmao/<osversion>-baselibs:8.7.0-openmpi_5.0.5-gcc_14.2.0
```

## GEOS Build Env
```
docker build --build-arg baselibversion=8.7.0 --build-arg gccversion=14.2.0 --build-arg mpiversion=5.0.5 -f Dockerfile.geos-env -t gmao/<osversion>-geos-env:8.7.0-openmpi_5.0.5-gcc_14.2.0 .
docker push gmao/<osversion>-geos-env:8.7.0-openmpi_5.0.5-gcc_14.2.0
```

## FV3 Standalone
```
docker build --build-arg fv3version=1.1.0 -f Dockerfile.geos-fv3standalone -t gmao/<osversion>-geos-fv3standalone:1.1.0 .
docker push gmao/<osversion>-geos-fv3standalone:1.1.0
```
   
## GEOSgcm
```
docker build --build-arg gcmversion=10.16.1 -f Dockerfile.geos-gcm -t gmao/<osversion>-geos-gcm:10.16.1 .
docker push gmao/<osversion>-geos-gcm:10.16.1
```
