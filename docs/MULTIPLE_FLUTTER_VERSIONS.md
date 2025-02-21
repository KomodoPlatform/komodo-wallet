# Flutter Version Manager (FVM)

Should you need to install and manage multiple versions of the Flutter SDK, it is recommended to use [FVM](https://fvm.app/documentation/getting-started/installation). See [MULTIPLE_FLUTTER_VERSIONS.md](MULTIPLE_FLUTTER_VERSIONS.md) for more details. [FVM](https://fvm.app/documentation/getting-started/installation). See the overview from the [FVM documentation](https://fvm.app/documentation/getting-started) for more information:
> FVM helps with the need for consistent app builds by referencing the Flutter SDK version used on a per-project basis. It also allows you to have multiple Flutter versions installed to quickly validate and test upcoming Flutter releases with your apps without waiting for Flutter installation every time.

## macOS and Linux

The following steps install [FVM](https://fvm.app/documentation/getting-started/installation) as a standalone application and use it to manage both local and global Flutter SDKs. The approach recommended by the FVM maintainers is to download and install a global version of Flutter SDK and use FVM to manage local Flutter SDKs, but this approach works for most use-cases.

Install [FVM](https://fvm.app/documentation/getting-started/installation) using the installation script, `install.sh`.

```bash
curl -fsSL https://fvm.app/install.sh | bash

# Configure the Flutter version to use in the current directory (e.g. ~/komodo-wallet)
fvm use stable
```

----

## Windows

The following steps install [FVM](https://fvm.app/documentation/getting-started/installation) as a standalone application and use it to manage both local and global Flutter SDKs. The approach recommended by the FVM maintainers is to download and install a global version of Flutter SDK and use FVM to manage local Flutter SDKs, but this approach works for most use-cases.

### 1. Install [Chocolatey](https://chocolatey.org/install), a windows package manager, if not installed yet

```PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

### 2. Install [FVM](https://fvm.app/documentation/getting-started/installation) using Chocolatey

```PowerShell
choco install fvm
fvm use stable
fvm flutter doctor -v
```

----
