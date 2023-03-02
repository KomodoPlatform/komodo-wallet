Set-ExecutionPolicy RemoteSigned -scope CurrentUser

$build_type=$args[0]

iwr -useb 'https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1' -outfile 'install.ps1'
.\install.ps1 -RunAsAdmin

#Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh') -RunAsAdmin
scoop install llvm --global
scoop install ninja --global
scoop install cmake@3.22.0 --global
scoop install git --global
scoop install 7zip  --global
scoop cache rm 7zip
scoop cache rm git
scoop cache rm cmake
scoop cache rm ninja
scoop cache rm llvm
$Env:QT_INSTALL_CMAKE_PATH = "C:\Qt\$Env:QT_VERSION\msvc2019_64"
$Env:QT_ROOT = "C:\Qt"
mkdir b
cd b
cmake --version
cmake -DCMAKE_BUILD_TYPE=$build_type -GNinja ../
ninja install
