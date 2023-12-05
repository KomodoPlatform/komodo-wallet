# Komodo Wallet Pro alpha build instructions

## Prerequisites

- Visual Studio 2019 (Windows) with [Desktop development with C++](https://docs.microsoft.com/en-gb/cpp/build/vscpp-step-0-installation?view=vs-2019).
- Clang C++ 17 compiler (clang-8 minimum)
    - on macOS Catalina, Apple Clang 11.0 is picked by default 
- CMake 3.14 minimum (https://cmake.org/download/)

## Install dependencies

### Install QT

Follow the [QT installation (5.15) instructions](https://www.qt.io/download). 


### Install Windows dependencies

In your powershell (as admin) execute: 

```
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

scoop install nim --global
scoop install llvm --global
scoop install ninja --global
scoop install cmake --global
scoop install git --global
```

- next add a `QT_INSTALL_CMAKE_PATH` environment variable pointing to the msvc_2019x64 location

e.g.: `set QT_INSTALL_CMAKE_PATH "C:\Qt\5.15.0\msvc2019_64"`


### Install macOS dependencies

Ensure you have [brew](https://brew.sh) and the macOS [command line tools](https://developer.apple.com/downloads) installed.

```shell
brew install nim cmake ninja git gcc
```

Add the following environment variables to your `~/.bashrc` or `~/.zshrc` profile:
 * `QT_INSTALL_CMAKE_PATH` equal to the CMake QT path
 * `QT_ROOT` equal to the QT root installation folder


e.g.:
```bash
export QT_INSTALL_CMAKE_PATH=/Users/SatoshiNakamoto/Qt/5.15.0/clang_64/lib/cmake
export QT_ROOT=/Users/SatoshiNakamoto/Qt/5.15.0
```

Installing curl:

```
brew install autoconf automake libtool
git clone https://github.com/phracker/MacOSX-SDKs.git ~/MacOSX-SDKs
export CC=/usr/local/opt/llvm/bin/clang
export CPPFLAGS="-isysroot $HOME/MacOSX-SDKs/MacOSX10.13.sdk/"
git clone https://github.com/curl/curl.git
cd curl
git checkout curl-7_70_0
./buildconf
./configure --disable-shared --enable-static --without-libidn2 -without-ssl --disable-ldap --with-darwinssl
make install
```

Installing libbitcoin:

```
git clone --depth 1 --branch version5 --single-branch "https://github.com/KomodoPlatform/secp256k1"
cd secp256k1
./autogen.sh
./configure --disable-shared --disable-tests --enable-module-recovery
make -j3
sudo make install
cd ../
```

Installing libbitcoin-system:

```
git clone --depth 1 --branch version3 --single-branch https://github.com/KomodoPlatform/libbitcoin-system.git
cd libbitcoin-system
./autogen.sh
./configure --with-boost --disable-shared
make -j3
sudo make install
sudo update_dyld_shared_cache
```


### Install Linux dependencies

In your terminal (shell,...) execute:

```shell
sudo apt-get install -y ninja-build cmake git gcc-9 g++-9

curl https://nim-lang.org/choosenim/init.sh -sSf | sh

wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh 9

git clone https://github.com/KomodoPlatform/libwally-core.git
cd libwally-core
./tools/autogen.sh
./configure --disable-shared
sudo make -j2 install
```

Use the most recently installed `clang` version:

```
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-9 100
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-9 100
```


Add the following environment variables to your `~/.bashrc` or `~/.zshrc` profiles:
 * `QT_INSTALL_CMAKE_PATH` equal to the CMake QT path
 * `QT_ROOT` equal to the QT root installation folder

e.g.:
```bash
export QT_INSTALL_CMAKE_PATH=~/Qt/5.15.0/gcc/lib/cmake
export QT_ROOT=~/Qt/5.15.0
```

## Set Nim official packages list to our fork packages list

```
nimble refresh https://raw.githubusercontent.com/KomodoPlatform/nim_kmd_package_list/master/packages.json
cd ~/.nimble
mv packages_commandline.json packages_official.json
cd -
```

## Build Komodo Wallet Pro 

Please clone with submodules initialization : `git clone --recurse-submodules --remote-submodules https://github.com/KomodoPlatform/atomicDEX-Pro.git`

Install vcpkg from within the `ci_tools_atomic_dex` folder:

```
nimble build
cd vcpkg-repo
# Windows
.\bootstrap-vcpkg.bat
# Linux / OSX
./bootstrap-vcpkg.sh
cd -
```

### Windows

In your x64 Visual Studio command prompt, from within the `ci_tools_atomic_dex` folder, type:

```bash
nimble build
./ci_tools_atomic_dex.exe build release
./ci_tools_atomic_dex.exe build debug
```

### macOS & Linux

In your command line, from within the `ci_tools_atomic_dex`, run:

```bash
nimble build
./ci_tools_atomic_dex build debug
./ci_tools_atomic_dex build release
```

## Bundle Komodo Wallet Pro

### Windows

In your x64 Visual Studio command prompt, from within the `ci_tools_atomic_dex` folder, type:

```
nimble build
ci_tools_atomic_dex.exe build release
ci_tools_atomic_dex.exe bundle release
ci_tools_atomic_dex.exe build debug
ci_tools_atomic_dex.exe bundle debug
```

### OSX

In your command line, from within the `ci_tools_atomic_dex`, run:

```
nimble build
./ci_tools_atomic_dex bundle release
./ci_tools_atomic_dex bundle debug
```



## Create Komodo Wallet Pro Installer

### Windows

- [Download](https://download.qt.io/official_releases/qt-installer-framework/) and install Qt Installer Framework.

- Add a `QT_IFW_PATH` environment variable pointing to the Qt Installer Framework folder

e.g.: `set QT_IFW_PATH "C:\Qt\QtIFW-3.2.2"`

- Run `ci_tools_atomic_dex\create_installer.bat` script

### Linux

- [Download](https://download.qt.io/official_releases/qt-installer-framework/)

- Run the .run file and install it.

```
chmod +x QtInstallerFramework-linux-x64.run
./QtInstallerFramework-linux-x64.run
```

- Add a `QT_IFW_PATH` environment variable pointing to the Qt Installer Framework folder

e.g.: In `.bashrc` add: `export QT_IFW_PATH=~/Qt/QtIFW-3.2.2`

- Build Komodo Wallet Pro `./ci_tools_atomic_dex build release`

- Run `ci_tools_atomic_dex\create_installer_linux.sh` script, pass build type as argument to script

e.g.: `.\create_installer_linux.sh Debug` -- or Release
