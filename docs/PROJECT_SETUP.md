# Project setup

Komodo Wallet is a cross-platform application, meaning it can be built for multiple target platforms using the same code base. It is important to note that some target platforms may only be accessible from specific host platforms. Below is a list of all supported host platforms and their corresponding target platforms:

| Host Platform | Target Platform                  |
| ------------- | -------------------------------- |
| macOS         | Web, macOS, iOS, iPadOS, Android |
| Windows       | Web, Windows, Android            |
| Linux         | Web, Linux, Android              |

## Host Platform Setup

 1. [Install Flutter, pin Flutter version](INSTALL_FLUTTER.md)
 2. Install IDEs
    - [VS Code](https://code.visualstudio.com/)
      - install and enable `Dart` and `Flutter` extensions
      - enable `Dart: Use recommended settings` via the Command Palette
    - [Android Studio](https://developer.android.com/studio) - Flamingo | 2024.1.2
      - install and enable `Dart` and `Flutter` plugins
      - SDK Manager -> SDK Tools:
        - [x] Android SDK Build-Tools 35
        - [x] NDK (Side by side) 27.1
        - [x] Android command line tools (latest)
        - [x] CMake 3.30.3 (latest)
    - [xCode](https://developer.apple.com/xcode/) - 15.4 (macOS only)
    - [Visual Studio](https://visualstudio.microsoft.com/vs/community/) - Community 17.11.3 (Windows only)
      - `Desktop development with C++` workload required

 3. Run `flutter doctor` and make sure all checks (except version) pass
 4. [Clone project repository](CLONE_REPOSITORY.md)
 5. Install [nodejs and npm](https://nodejs.org/en/download). Make sure `npm` is in your system PATH and you can run `npm run build` from the project root folder. Node LTS (v18, v20) is required.

  > In case of an error, try to run `npm i`.

 6. Build and run the App for each target platform:
    - [Web](BUILD_RUN_APP.md#web)
    - [Android mobile](BUILD_RUN_APP.md#android)
    - [iOS mobile](BUILD_RUN_APP.md#ios) (macOS host only)
    - [macOS desktop](BUILD_RUN_APP.md#macos-desktop) (macOS host only)
    - [Windows desktop](BUILD_RUN_APP.md#windows-desktop) (Windows host only)
    - [Linux desktop](BUILD_RUN_APP.md#linux-desktop) (Linux host only)
 7. [Build release version](BUILD_RELEASE.md)

## Dev Container setup (Web and Android builds only)

1. Install [Docker](https://www.docker.com/get-started) for your operating system.
      - Linux: Install [Docker for your distribution](https://docs.docker.com/install/#supported-platforms) and add your user to the group by using terminal to run: `sudo usermod -aG docker $USER`.
      - Windows/macOS: Install [Docker Desktop for Windows/macOS](https://www.docker.com/products/docker-desktop), and if you are using WSL in Windows, please ensure that the [WSL 2 back-end](https://aka.ms/vscode-remote/containers/docker-wsl2) is installed and configured.
2. Install [VS Code](https://code.visualstudio.com/)
      - install and enable `Dart` and `Flutter` extensions
      - enable `Dart: Use recommended settings` via the Command Palette
3. Install the VSCode [Dev Container extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
4. Open the command palette (Ctrl+Shift+P) and run `Remote-Containers: Reopen in Container`
