#!/bin/bash

set -ex

[ -n "$NINJA_VERSION" ]

arch=$(uname -m)
if [ "$arch" == "x86_64" ]; then
    url="https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip"
elif [ "$arch" == "aarch64" ]; then
    url="https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux-aarch64.zip"
elif [ "$arch" == "loongarch64" ]; then
    url="https://github.com/loong64/ninja/releases/download/v${NINJA_VERSION}/ninja-linux-loongarch64.zip"
else
    echo "Unsupported architecture: $arch"
    exit 1
fi

pushd /tmp
wget --no-verbose --output-document=ninja-linux.zip "$url"
unzip ninja-linux.zip -d /usr/local/bin
rm -f ninja-linux.zip
popd