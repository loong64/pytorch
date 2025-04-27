#!/bin/bash

set -ex

FFMPEG_VERSION=4.2

command -v apk >/dev/null && apk add --no-cache libjpeg-dev libwebp-dev libpng-dev freetype gnutls wget
command -v yum >/dev/null && yum install -y libjpeg-devel libwebp-devel libpng-devel freetype gnutls wget && yum clean all

cd /tmp

mkdir -p ffmpeg
pushd ffmpeg

wget https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz
tar -xvzf ffmpeg-${FFMPEG_VERSION}.tar.gz

pushd ffmpeg-${FFMPEG_VERSION}

./configure --enable-nonfree --enable-openssl --enable-shared --disable-libmfx --disable-nvdec --disable-nvenc --extra-libs=-lpthread

make -j$(nproc)
make install

popd

popd
rm -rf /tmp/ffmpeg

which ldconfig && ldconfig || true
