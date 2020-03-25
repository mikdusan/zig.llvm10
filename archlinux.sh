#!/usr/bin/env bash

set -e

################################################################################
#
# note: if building with gcc you might need ~1.5-2.0 GiB per concurrent job
# 
# apt install git vim ruby cmake ninja-build
# 
################################################################################

__JOBS=`nproc`
__PROJECT=~/work/llvm
__SOURCE=$__PROJECT/llvm-project
__LLVM_TAG="llvmorg-10.0.0"
__LLVM_PRODUCT="llvm-10.0.0"
__LLVM_INSTALL_ROOT=/opt/$__LLVM_PRODUCT

mkdir -p `dirname $__SOURCE`
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
    mkdir -p $__BUILD
    cd $__BUILD
    cmake -G "Ninja" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DCMAKE_INSTALL_PREFIX="$__PREFIX" \
        -DCMAKE_PREFIX_PATH="$__PREFIX" \
        -DLLVM_ENABLE_PROJECTS="$__PROJECTS" \
        -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="AVR" \
        -DLLVM_ENABLE_LIBXML2="OFF" \
        -DLLVM_ENABLE_TERMINFO="OFF" \
        "$__SOURCE/llvm"
    ninja -j$__JOBS install
fi
