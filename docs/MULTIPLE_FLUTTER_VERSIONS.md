# Handle multiple Flutter versions

## Flutter Version Manager (FVM)

The recommended method of handling multiple Flutter versions is to use [FVM](https://fvm.app/documentation/getting-started/installation).

```bash
curl -fsSL https://fvm.app/install.sh | bash

# Configure the Flutter version to use in the current directory (e.g. ~/komodo-wallet)
fvm use stable
```

## macOS

### 1. Clone new Flutter instance alongside with the existing one

```bash
cd ~
git clone https://github.com/flutter/flutter.git flutter_web
cd ./flutter_web
git checkout 3.29.0
```

### Open (or create) `.zshrc` file in your home directory

```bash
nano ~/.zshrc
```

Add line:

```bash
alias flutter_web="$HOME/flutter_web/bin/flutter"
```

Save and close.

### 3. Check if the newly installed Flutter version is accessible from terminal

```bash
cd ~
flutter_web doctor
```

### 4. Add new Flutter version to VSCode

- Settings (⌘,) -> Extensions -> Dart -> SDK -> Flutter Sdk Paths -> Add Item -> `~/flutter_web`
- ⌘⇧P -> Developer: Reload window
- ⌘⇧P -> Flutter: Change SDK

### 5. Add to Android Studio

- Settings (⌘,) -> Languages & Frameworks -> Flutter -> SDK -> Flutter SDK Path -> `~/flutter_web`

----

## Windows

The following steps installs [fvm](https://fvm.app/docs/getting_started/installation) as a standalone application and uses it to manage both local and global Flutter SDKs. The recommended approach is to download and install a global version of Flutter SDK and use fvm to manage local Flutter SDKs, but this approach works for most scenarios.

### 1. Install [Chocolatey](https://chocolatey.org/install), a windows package manager, if not installed yet

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### 2. Install [fvm](https://fvm.app/docs/getting_started/installation) using Chocolatey

```PowerShell
choco install fvm
fvm use stable
fvm flutter doctor -v
```

----

## Linux

The following steps installs [fvm](https://fvm.app/docs/getting_started/installation) as a standalone application and uses it to manage both local and global Flutter SDKs. The recommended approach is to download and install a global version of Flutter SDK and use fvm to manage local Flutter SDKs, but this approach works for most scenarios.

Install [fvm](https://fvm.app/docs/getting_started/installation) using the installation script, `install.sh`.

```bash
curl -fsSL https://fvm.app/install.sh | bash
```
