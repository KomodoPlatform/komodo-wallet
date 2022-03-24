#!/bin/bash

brew update

brew tap-new $USER/local-nim
brew extract --version=1.4.8 nim $USER/local-nim

brew tap-new $USER/local-libtool
brew extract --version=2.4.6 libtool $USER/local-libtool


brew install autoconf \
            automake \
            pkgconfig \
            wget \
            nim@1.4.8 \
            ninja \
            gnu-sed \
            coreutils \
            llvm \
            gnu-getopt

brew install libtool@2.4.6

PATH="/usr/local/opt/libtool/libexec/gnubin:$PATH"

pip3 install yq
export CC=clang
export CXX=clang++
export MACOSX_DEPLOYMENT_TARGET=10.15

# get curl
#git clone https://github.com/KomodoPlatform/curl.git
#cd curl
#git checkout curl-7_70_0
#./buildconf
#./configure --disable-shared --enable-static --without-libidn2 --without-ssl --without-nghttp2 --disable-ldap --with-darwinssl
#make -j3 install
#cd ../

git clone https://github.com/ElementsProject/libwally-core.git
cd libwally-core
./tools/autogen.sh
./configure --disable-shared
sudo make -j3 install
cd ..

# get SDKs
git clone https://github.com/KomodoPlatform/MacOSX-SDKs $HOME/sdk
