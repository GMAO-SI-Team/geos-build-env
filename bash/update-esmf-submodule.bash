#!/usr/bin/env bash
set -Eeuxo pipefail

git clone https://github.com/esmf-org/ESMA-Baselibs.git
cd ESMA-Baselibs/
git checkout bekozi-dev
git pull
git submodule update --init esmf
cd esmf
git checkout develop
git pull
cd ..
git add esmf
git commit -m "ESMF: Move submodule to develop HEAD"
git push

