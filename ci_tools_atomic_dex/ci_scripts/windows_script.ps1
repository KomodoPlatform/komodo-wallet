Set-ExecutionPolicy RemoteSigned -scope CurrentUser

$DWFILE = ($PWD | select -exp Path) + '\nim-1.2.6.zip'
(New-Object System.Net.WebClient).DownloadFile('https://github.com/KomodoPlatform/nim_kmd_package_list/raw/master/nim-1.2.6_x64.zip', $DWFILE)
$DWFOLDER = ($PWD | select -exp Path)
Expand-Archive -LiteralPath $DWFILE -DestinationPath $DWFOLDER
$ENV:PATH=$ENV:PATH+';'+($PWD | select -exp Path)+'\nim-1.2.6\bin;'+$ENV:UserProfile+'.nimble\bin'
& $DWFOLDER\nim-1.2.6\finish.exe -y

Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
scoop install llvm --global
scoop install ninja --global
scoop install cmake --global
scoop install git --global
scoop install 7zip  --global
scoop cache rm 7zip
scoop cache rm git
scoop cache rm cmake
scoop cache rm ninja
scoop cache rm llvm
scoop cache rm nim
$Env:QT_INSTALL_CMAKE_PATH = "C:\Qt\$Env:QT_VERSION\msvc2019_64"
$Env:QT_ROOT = "C:\Qt"
cd ci_tools_atomic_dex
#$file = 'src\generate.nim'
#$regex = '(?<=g_vcpkg_cmake_script_path & ")[^"]*'
#(Get-Content $file) -replace $regex, ' -DVCPKG_TARGET_TRIPLET=x64-windows ' | Set-Content $file
nimble build -y
#cmd /c '.\ci_tools_atomic_dex.exe build release 2>&1'
cmd /c '.\ci_tools_atomic_dex.exe bundle release 2>&1'
#ls bundle-Release/bundle.zip
