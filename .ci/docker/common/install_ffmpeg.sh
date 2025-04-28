#!/bin/bash

set -ex

FFMPEG_VERSION=4.2

command -v apk >/dev/null && {
    apk add --no-cache libjpeg-dev libwebp-dev libpng-dev libvpx-dev freetype-dev gnutls-dev opus-dev wget
}
command -v yum >/dev/null && {
    yum install -y libjpeg-devel libwebp-devel libpng-devel libvpx-devel freetype-devel gnutls-devel opus-devel wget
    yum clean all
}

cd /tmp

mkdir -p ffmpeg
pushd ffmpeg

wget https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz
tar -xvzf ffmpeg-${FFMPEG_VERSION}.tar.gz

pushd ffmpeg-${FFMPEG_VERSION}

# FFmpeg was compiled without the GPL components enabled, thus being LGPL-licensed. 
# The LICENSE notice is included as part of this repository and the compilation flags are described as follows:
# See: https://github.com/pytorch/builder/blob/release/3.0/ffmpeg/recipe/build.sh
./configure \
        --disable-doc \
        --disable-openssl \
        --enable-avresample \
        --enable-gnutls \
        --enable-hardcoded-tables \
        --enable-libfreetype \
        --enable-pic \
        --enable-pthreads \
        --enable-shared \
        --disable-static \
        --enable-version3 \
        --enable-zlib

make -j$(nproc)
make install

popd

popd
rm -rf /tmp/ffmpeg

which ldconfig && ldconfig || true
