#!/bin/bash

set -e

while getopts "v:" parameter_Option; do 
  case "${parameter_Option}" in
    v) PYTORCH_VERSION=${OPTARG};;
    *) echo "Usage: $0 [-v <pytorch_version>]"
       exit 1;;	
  esac
done

if [ -z "${PYTORCH_VERSION}" ]; then
  echo "Usage: $0 -v v2.12.0"
  exit 1
fi

if [ ! -d "/opt/data/build" ] || [ ! -d "/opt/data/cache" ]; then
  mkdir -p /opt/data/build /opt/data/cache
fi

mkdir -p /opt/data/${PYTORCH_VERSION}
cd /opt/data/${PYTORCH_VERSION} || exit 1

if [ ! -d "pytorch" ]; then
  git clone --recursive --depth=1 -b ${PYTORCH_VERSION} https://github.com/pytorch/pytorch
  cd pytorch || exit 1
  wget -qO - https://github.com/loong64/pytorch/raw/refs/heads/main/patch_loong64.patch | patch -p1
  cd third_party/sleef
  wget -qO - https://github.com/loong64/pytorch/raw/refs/heads/main/sleef/sleef_loong64.patch | patch -p1
  cd -
  cd third_party/cpuinfo
  wget -qO - https://github.com/loong64/pytorch/raw/refs/heads/main/cpuinfo/cpuinfo_loong64.patch | patch -p1
  cd -
fi

cd /opt/data/${PYTORCH_VERSION}/pytorch || exit 1

mkdir -p wheelhouse

export PYTORCH_BUILD_VERSION=${PYTORCH_VERSION/v/}

export PYTORCH_ROOT=/pytorch
export DOCKER_IMAGE=ghcr.io/loong64/manylinuxloongarch64-builder:cpu-loongarch64
export DESIRED_PYTHONS="3.10 3.11 3.12 3.13 3.14 3.14t"
export PYTORCH_FINAL_PACKAGE_DIR=/artifacts

export DOCKER_CMD="${PYTORCH_ROOT}/.ci/manywheel/build_all.sh"
docker run --rm \
  --platform linux/loong64 \
  --env PYTORCH_ROOT \
  --env PYTORCH_BUILD_NUMBER=1 \
  --env PYTORCH_BUILD_VERSION \
  --env PYTORCH_FINAL_PACKAGE_DIR \
  --env PACKAGE_TYPE=manywheel \
  --env DESIRED_CUDA=cpu \
  --env GPU_ARCH_TYPE=cpu-loongarch64 \
  --env GPU_ARCH_VERSION="" \
  --env SKIP_ALL_TESTS=1 \
  --env DESIRED_PYTHONS="${DESIRED_PYTHONS}" \
  --env BUILD_ENVIRONMENT=linux-loongarch64-binary-manywheel \
  --env BUILD_NAME_PREFIX=manywheel-py \
  --env BUILD_NAME_SUFFIX="-cpu-loongarch64" \
  --env TORCH_PACKAGE_NAME='torch' \
  --env USE_FBGEMM=1 \
  --env USE_GOLD_LINKER="OFF" \
  --env USE_GLOO_WITH_OPENSSL="OFF" \
  --env PIP_EXTRA_INDEX_URL \
  --volume $(pwd):${PYTORCH_ROOT} \
  --volume $(pwd)/wheelhouse:${PYTORCH_FINAL_PACKAGE_DIR} \
  --volume /opt/data/cache:/root/.cache \
${DOCKER_IMAGE} sh -c "${DOCKER_CMD}"
