#!/bin/bash

sudo apt-get update  # prevents repo404 errors on apt-remove below
sudo apt-get remove php* msodbcsql17 mysql*
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get upgrade -y
# base deps
sudo apt-get install build-essential \
                    libgl1-mesa-dev \
                    ninja-build \
                    curl \
                    wget \
                    zstd \
                    software-properties-common \
                    lsb-release \
                    libpulse-dev \
                    libtool \
                    autoconf \
                    unzip \
                    libssl-dev \
                    libxkbcommon-x11-0 \
                    libxcb-icccm4 \
                    libxcb-image0 \
                    libxcb1-dev \
                    libxcb-keysyms1-dev \
                    libxcb-render-util0-dev \
                    libxcb-xinerama0 \
                    libgstreamer-plugins-base1.0-dev \
                    git -y
                    
# get llvm
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh 11
# set clang version
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-11 777
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-11 777
# set gnu compilers version
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 777
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 777
sudo apt-get update
sudo apt-get install libc++abi-11-dev libc++-11-dev -y
export CXXFLAGS=-stdlib=libc++
export LDFLAGS=-stdlib=libc++
export CXX=clang++-11
export CC=clang-11

# get right cmake version
wget https://github.com/Kitware/CMake/releases/download/v3.19.0-rc3/cmake-3.19.0-rc3-Linux-x86_64.tar.gz
tar xvf cmake-3.19.0-rc3-Linux-x86_64.tar.gz
cd cmake-3.19.0-rc3-Linux-x86_64
sudo cp -r * /usr/
sudo cp -r * /usr/local/
cmake --version

# get libwally
git clone https://github.com/KomodoPlatform/libwally-core.git
cd libwally-core
./tools/autogen.sh
./configure --disable-shared
sudo make -j3 install
cd ..

wget https://ftp.gnu.org/gnu/tar/tar-1.32.tar.gz
tar xvf tar-1.32.tar.gz
cd tar-1.32
export FORCE_UNSAFE_CONFIGURE=1
./configure
sudo make -j install
sudo update-alternatives --install /usr/bin/tar tar /usr/local/bin/tar 777