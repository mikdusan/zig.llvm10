#!/usr/bin/env bash

set -e
PATH=/usr/bin:/bin:/usr/sbin:/sbin

__JOBS=`sysctl -n hw.logicalcpu`
__PROJECT=~/work/llvm
__PACKAGE=$__PROJECT/package
__SOURCE=$__PROJECT/llvm-project
__TOOL=$__PROJECT/tool
__LLVM_TAG="llvmorg-10.0.0"
__LLVM_PRODUCT="llvm-10.0.0"
__LLVM_INSTALL_ROOT=/opt/$__LLVM_PRODUCT

if [ ! -d $__SOURCE ]; then
    echo "GIT: cloning llvm-project..."
    git clone https://github.com/llvm/llvm-project.git $__SOURCE
fi
cd $__SOURCE
echo "GIT: switch to ${__LLVM_TAG}"
git switch --detach $__LLVM_TAG
git describe --always

################################################################################
#
# build: tool cmake
# mandatory for: llvm
#
################################################################################

__BUILD=$__PROJECT/_build
__PREFIX=$__TOOL

if [ ! -f $__PREFIX/bin/cmake ]; then
    if [ -d $__BUILD ]; then
        echo "already exists: $__BUILD"
        exit 1
    fi
    mkdir -pv $__BUILD
    cd $__BUILD
    tar xf $__PACKAGE/cmake-3.16.5.tar.gz
    cd $__BUILD/cmake-3.16.5
    ./configure --parallel=$__JOBS --prefix=$__PREFIX
    make -j$__JOBS install
fi

################################################################################
#
# build: tool ninja
# optional for: llvm
#
################################################################################

__BUILD=$__PROJECT/_build
__PREFIX=$__TOOL

if [ ! -f $__PREFIX/bin/ninja ]; then
    if [ -d $__BUILD ]; then
        echo "already exists: $__BUILD"
        exit 1
    fi
    mkdir -pv $__BUILD
    cd $__BUILD
    tar xf $__PACKAGE/ninja-1.10.0.tar.gz
    cd $__BUILD/ninja-1.10.0
    mkdir _build
    cd _build
    $__TOOL/bin/cmake -S .. -B .
    make -j$__JOBS
    cp ninja $__TOOL/bin/.
fi

################################################################################
#
# build: llvm
#
################################################################################

__BUILD=$__PROJECT/_build/$__LLVM_PRODUCT
__PREFIX=$__LLVM_INSTALL_ROOT
__PROJECTS="clang;lld"

if [ ! -f $__PREFIX/bin/llvm-config ]; then
    if [ -d $__BUILD ]; then
        echo "already exists: $__BUILD"
        exit 1
    fi
    mkdir -pv $__BUILD
    cd $__BUILD
    $__TOOL/bin/cmake -G "Ninja" \
        -DCMAKE_MAKE_PROGRAM="$__TOOL/bin/ninja" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DCMAKE_INSTALL_PREFIX="$__PREFIX" \
        -DCMAKE_PREFIX_PATH="$__PREFIX" \
        -DLLVM_ENABLE_PROJECTS="$__PROJECTS" \
        -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="AVR" \
        -DLLVM_ENABLE_LIBXML2="OFF" \
        -DLLVM_ENABLE_TERMINFO="OFF" \
        "$__SOURCE/llvm"
    $__TOOL/bin/ninja -j$__JOBS install
fi
