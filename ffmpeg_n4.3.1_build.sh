#!/bin/sh
set -e
set -x

#git clone https://github.com/FFmpeg/FFmpeg.git
#git checkout n4.3.1

NDK=/home/czh/tool/Android/ndk-r21e

ARCH=arm64
CPU=armv8-a

SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin

CC=$TOOLCHAIN/aarch64-linux-android29-clang
CXX=$TOOLCHAIN/aarch64-linux-android29-clang++
STRIP=
CROSS_PREFIX=$TOOLCHAIN/aarch64-linux-android-

PREFIX=$(pwd)/android/$CPU
OPTIMIZE_CFLAGS="-march=$CPU"

ADDI_LDFLAGS="-L./openssl/$CPU/lib -lssl -lcrypto"
ADDI_CFLAGS="-Os -fpic -DBIONIC_IOCTL_NO_SIGNEDNESS_OVERLOAD $OPTIMIZE_CFLAGS -I./openssl/$CPU/include"
ADDITIONAL_CONFIGURE_FLAG="--enable-asm --enable-inline-asm"

function update_platfrom_para {
    if [ "$1" = "arm64" ]; then
        echo "platfrom architecture $1"
    elif [ "$1" = "arm" ]; then
        echo "platfrom architecture $1"
        CPU=armv7-a
        ARCH=arm
        PREFIX=$(pwd)/android/$CPU
        OPTIMIZE_CFLAGS="-march=$CPU"
        CC=$TOOLCHAIN/armv7a-linux-androideabi21-clang
        CXX=$TOOLCHAIN/armv7a-linux-androideabi21-clang++
        STRIP=$TOOLCHAIN/arm-linux-androideabi-strip
        CROSS_PREFIX=$TOOLCHAIN/arm-linux-androideabi-
        ADDI_LDFLAGS="-fPIE -pie -L./openssl/$CPU/lib -lssl -lcrypto"
        ADDI_CFLAGS="-mfloat-abi=softfp -mfpu=neon $OPTIMIZE_CFLAGS -I./openssl/$CPU/include"
        ADDITIONAL_CONFIGURE_FLAG="--disable-asm"
    elif [ "$1" = "x86" ]; then
        echo "platfrom architecture $1"
        CPU=i686
        ARCH=x86
        PREFIX=$(pwd)/android/$ARCH
        OPTIMIZE_CFLAGS="-march=atom"
        CC=$TOOLCHAIN/i686-linux-android29-clang
        CXX=$TOOLCHAIN/i686-linux-android29-clang++
        CROSS_PREFIX=$TOOLCHAIN/i686-linux-android-
        ADDI_LDFLAGS="-L./openssl/$ARCH/lib -lssl -lcrypto"
        ADDI_CFLAGS="-msse3 -ffast-math -mfpmath=sse $OPTIMIZE_CFLAGS -I./openssl/$ARCH/include"

    elif [ "$1" = "x86_64" ]; then
        echo "platfrom architecture $1"
        ARCH=x86_64
        PREFIX=$(pwd)/android/$ARCH
        CC=$TOOLCHAIN/x86_64-linux-android29-clang
        CXX=$TOOLCHAIN/x86_64-linux-android29-clang++
        CROSS_PREFIX=$TOOLCHAIN/x86_64-linux-android-
        ADDI_LDFLAGS="-L./openssl/$ARCH/lib -lssl -lcrypto"
        ADDI_CFLAGS="-I./openssl/$ARCH/include"
    else
        echo "unknown platfrom architecture $1";
        exit 1
    fi
}

function ff_configure
{
    ./configure \
        --prefix=$PREFIX \
        --sysroot=$SYSROOT \
        --target-os=android \
        --enable-cross-compile \
        --arch=$ARCH \
        --cpu=$CPU \
        --cc=$CC \
        --cxx=$CXX \
        --strip=$STRIP \
        --cross-prefix=$CROSS_PREFIX \
        --extra-cflags="$ADDI_CFLAGS" \
        --extra-ldflags="$ADDI_LDFLAGS" \
        --enable-small \
        --enable-shared \
        --disable-static \
        --disable-ffplay \
        --disable-ffmpeg \
        --disable-ffprobe \
        --disable-avfilter \
        --disable-avdevice \
        --disable-avdevice \
        --disable-swresample \
        --disable-postproc \
        --disable-doc \
        --disable-gpl \
        --disable-encoders \
        --disable-hwaccels \
        --disable-muxers \
        --disable-bsfs \
        --disable-protocols \
        --disable-indevs \
        --disable-outdevs \
        --disable-devices \
        --disable-filters \
        --enable-encoder=png \
        --enable-protocol=file,http,https,mmsh,mmst,pipe,rtmp,rtmps,rtmpt,rtmpts,rtp,tls \
        --disable-debug \
        --enable-openssl \
        $ADDITIONAL_CONFIGURE_FLAG
}

function ff_build {
    update_platfrom_para $1

    echo "Compiling FFmpeg for $ARCH"

    ff_configure
    make clean
    make -j12
    make install

    echo "The Compilation of FFmpeg for $ARCH is completed"
}

function ff_clean {
    echo "clean FFmpeg for $ARCH"
    make clean
    echo "clean FFmpeg for $ARCH is completed"
}

#action
FF_TARGET=$1
FF_ACT_ARCHS_ALL="arm arm64 x86 x86_64"

function echo_archs {
    echo "===================="
    echo "[*] check archs"
    echo "===================="
    echo "build all para:$FF_ACT_ARCHS_ALL"
    echo "building: $*"
}

function echo_usage {
    echo "Usage:"
    echo "  build_ffmpeg_android.sh arm|arm64|x86|x86_64|all|clean"
    exit 1
}

case "$FF_TARGET" in
    "")
        echo_archs arm64
        ff_build arm64
    ;;
    arm|arm64|x86|x86_64)
        echo_archs $FF_TARGET
        ff_build $FF_TARGET
    ;;
    all)
        echo_archs "$FF_ACT_ARCHS_ALL"
        for ARCH in $FF_ACT_ARCHS_ALL
        do
            ff_build $ARCH
        done
    ;;
    clean)
        ff_clean
    ;;
    *)
        echo_archs $FF_TARGET
        echo_usage
        exit 1
    ;;
esac
