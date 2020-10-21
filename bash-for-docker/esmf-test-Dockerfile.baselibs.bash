#!/usr/bin/env bash
set -Eeuxo pipefail

export ESMF_DIR=/baselibs/${BASELIBS_VERSION}/ESMA-Baselibs/esmf

#pushd /
#export ESMFMKFILE=$(find $(pwd -LP) -wholename '*lib/esmf.mk')
#popd || exit

export ESMF_TESTESMFMKFILE=ON
export ESMF_TESTEXHAUSTIVE=ON
cd ${ESMF_DIR} || exit
export ESMFMKFILE=$(find $(pwd -LP) -name '*esmf.mk')
make all_tests 2>&1 | tee esmf-make-all_tests.out

