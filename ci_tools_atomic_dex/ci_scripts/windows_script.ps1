Set-ExecutionPolicy RemoteSigned -scope CurrentUser

iwr -useb 'https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1' -outfile 'install.ps1'
.\install.ps1 -RunAsAdmin

#Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh') -RunAsAdmin
scoop install llvm --global
scoop install ninja --global
scoop install cmake@3.26.3 --global
scoop install git --global
scoop install 7zip  --global
scoop cache rm 7zip
scoop cache rm git
scoop cache rm cmake
scoop cache rm ninja
scoop cache rm llvm

$Env:QT_INSTALL_CMAKE_PATH = "C:\Qt\$Env:QT_VERSION\msvc2019_64"
$Env:QT_ROOT = "C:\Qt"

git clone https://github.com/KomodoPlatform/coins/ -b master
mkdir -p atomic_defi_design\assets\images\coins
Get-Item -Path "coins\icons\*.png" | Move-Item -Destination "atomic_defi_design\assets\images\coins"

mkdir b
cd b

Invoke-Expression "cmake -DCMAKE_BUILD_TYPE=$Env:CMAKE_BUILD_TYPE -GNinja ../"
ninja install
