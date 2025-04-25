#!/bin/bash

set -ex

[ -n "$OPENBLAS_VERSION" ]

cd /
git clone https://github.com/OpenMathLib/OpenBLAS.git -b v${OPENBLAS_VERSION} --depth 1 --shallow-submodules

OPENBLAS_BUILD_FLAGS="
NUM_THREADS=128
USE_OPENMP=1
NO_SHARED=0
DYNAMIC_ARCH=1
TARGET=GENERIC
CFLAGS=-O3
"

OPENBLAS_CHECKOUT_DIR="OpenBLAS"

# https://github.com/OpenMathLib/OpenBLAS/blob/develop/.github/workflows/loongarch64.yml#L65

sed -i 's/$(MAKE) -C test all/echo $(MAKE) -C test all/g' ${OPENBLAS_CHECKOUT_DIR}/Makefile
sed -i 's/$(MAKE) -C utest all/echo $(MAKE) -C utest all/g' ${OPENBLAS_CHECKOUT_DIR}/Makefile
sed -i 's/$(MAKE) -C ctest all/echo $(MAKE) -C ctest all/g' ${OPENBLAS_CHECKOUT_DIR}/Makefile
sed -i '/$(MAKE) -C cpp_thread_test all/echo $(MAKE) -C cpp_thread_test all/g' ${OPENBLAS_CHECKOUT_DIR}/Makefile

make -j8 ${OPENBLAS_BUILD_FLAGS} -C ${OPENBLAS_CHECKOUT_DIR}
make -j8 ${OPENBLAS_BUILD_FLAGS} install -C ${OPENBLAS_CHECKOUT_DIR}