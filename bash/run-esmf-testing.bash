#!/usr/bin/env bash
set -Eeuxo pipefail

ENV_FILE=../versions.sh

source $ENV_FILE

#bash build_full_stack.bash --os-version=${OS_VERSION} 2>&1 | tee build_full_stack.out

[$(docker ps -a | grep runner)] && docker rm --force runner
docker run --name runner --env-file=$ENV_FILE -dit gmao/${OS_VERSION}-baselibs:${BASELIBS_VERSION}-openmpi_${OPENMPI_VERSION}-gcc_${GCC_VERSION}
docker exec -t runner bash "/opt/esmf-test-Dockerfile.baselibs.bash"
docker stop runner
