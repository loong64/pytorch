#!/bin/bash

set -ex

FFMPEG_VERSION=4.2
OPENH264_VERSION=2.6.0

command -v apk >/dev/null && {
    apk add --no-cache libjpeg-dev libwebp-dev libpng-dev libvpx-dev freetype-dev gnutls-dev lame-dev opus-dev wget
}
command -v yum >/dev/null && {
    yum install -y libjpeg-devel libwebp-devel libpng-devel libvpx-devel freetype-devel gnutls-devel lame-devel opus-devel wget
    yum clean all
}

cd /tmp

mkdir -p ffmpeg openh264

pushd openh264

wget -qO openh264-${OPENH264_VERSION}.tar.gz https://github.com/cisco/openh264/archive/refs/tags/v${OPENH264_VERSION}.tar.gz
tar -xvzf openh264-${OPENH264_VERSION}.tar.gz

pushd openh264-${OPENH264_VERSION}

make -j$(nproc)
make install

popd

popd

pushd ffmpeg

wget https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.gz
tar -xvzf ffmpeg-${FFMPEG_VERSION}.tar.gz

pushd ffmpeg-${FFMPEG_VERSION}

wget -qO - https://gitee.com/src-anolis-os/ffmpeg/raw/a23/0001-Add-loongarch-support.patch | patch -p1

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
        --enable-libopenh264 \
        --enable-pic \
        --enable-pthreads \
        --enable-shared \
        --disable-static \
        --enable-version3 \
        --enable-zlib \
        --enable-libmp3lame

make -j$(nproc)
make install

popd

popd

rm -f ffmpeg-${FFMPEG_VERSION}.tar.gz openh264-${OPENH264_VERSION}.tar.gz
rm -rf /tmp/ffmpeg /tmp/openh264

which ldconfig && ldconfig || true
