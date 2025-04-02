# Build and run the App

Before proceeding, make sure that you have set up a working environment for your host platform according to the [guide](PROJECT_SETUP.md#host-platform-setup).

There are two main commands, `flutter run` to run the app or `flutter build` to build for the specified platform.

When using `flutter run` you can specify the mode in which the app will run. By default, it uses the debug mode.

```bash
# debug mode:
flutter run
# release mode:
flutter run --release
# profile mode:
flutter run --profile
```

To build the app, use `flutter build` followed by the build target.

As an example, for the mobile platforms:

```bash
# Android APK:
flutter build apk
# Android app bundle:
flutter build appbundle
# iOS IPA:
flutter build ios
```

----

## Target platforms

### Web

Google Chrome is required, and the `chrome` binary must be accessible by the flutter command (e.g. via the system path)

```bash
flutter clean
flutter pub get
```

Run in debug mode:

```bash
flutter run -d chrome
```

Run in release mode:

```bash
flutter run -d chrome --release
```

Running on web-server (useful for testing/debugging in different browsers):

```bash
flutter run -d web-server --web-port=8080
```

## Desktop

### macOS desktop

In order to build for macOS, you need to use a macOS host.

Before you begin:

 1. Open `macos/Runner.xcworkspace` in XCode
 2. Set Product -> Destination -> Destination Architectures to 'Show Both'

```bash
flutter clean
flutter pub get
```

Debug mode

```bash
flutter run -d macos
```

If you encounter build errors, try to follow any instructions in the error message.
In many cases, simply running the app from XCode before trying `flutter run -d macos` again will resolve the error.

- Open `macos/Runner.xcworkspace` in XCode
- Product -> Run

Release mode

```bash
flutter run -d macos --release
```

Build

```bash
flutter build macos
```

### Windows desktop

In order to build for Windows, you need to use a Windows host.

Run `flutter config --enable-windows-desktop` to enable Windows desktop support.

If you are using Windows 10, please ensure that [Microsoft WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2?form=MA13LH) is installed for Webview support. Windows 11 ships with it, but Windows 10 users might need to install it.

Please ensure the following prerequisites are installed:

- [Visual Studio](https://visualstudio.microsoft.com/vs/community/) | Community 17.13.0 (Windows only), with the `Desktop development with C++` workload installed.
- [Nuget CLI](https://www.nuget.org/downloads) is required for Windows desktop builds. Install with winget

    ```PowerShell
    winget install -e --id Microsoft.NuGet
    # Add a primary package source
    . $profile
    nuget sources add -name "NuGet.org" -source https://api.nuget.org/v3/index.json
    ```

- Enable long paths in Windows registry. Open CMD or PowerShell as Administrator, run the following, and restart:

    ```PowerShell
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1
    ```

Before building for Windows, run `flutter doctor` to check if all the dependencies are installed. If not, follow the instructions in the error message.

```bash
flutter doctor
```

```bash
flutter clean
flutter pub get
```

Debug mode

```bash
flutter run -d windows
```

Release mode

```bash
flutter run -d windows --release
```

Build

```bash
flutter build windows
```

### Linux desktop

In order to build for Linux, you need to use a Linux host with support for [libwebkit2gtk-4.1](https://packages.ubuntu.com/search?keywords=webkit2gtk), i.e. Ubuntu 22.04 (jammy) or later.

Run `flutter config --enable-linux-desktop` to enable Linux desktop support.

Before building for Linux, run `flutter doctor` to check if all the dependencies are installed. If not, follow the instructions in the error message.

```bash
flutter doctor
```

The Linux dependencies, [according to flutter.dev](https://docs.flutter.dev/get-started/install/linux#additional-linux-requirements) are as follow:

> For Linux desktop development, you need the following in addition to the Flutter SDK:
>
> - Clang
> - CMake
> - GTK development headers
> - Ninja build
> - pkg-config
> - liblzma-dev (This might be necessary)
> - libstdc++-12-dev
> - webkit2gtk-4.1 (Webview support)

To install on Ubuntu 20.04 or later, run:

```bash
sudo apt-get install -y clang cmake git ninja-build pkg-config \
    libgtk-3-dev liblzma-dev libstdc++-12-dev webkit2gtk-4.1 \
    curl git unzip xz-utils zip libglu1-mesa
```

Users of Ubuntu 24.04 (Noble) or later, might need to install additional dependencies, and add `PKG_CONFIG_PATH` to their bash configuration. If that doesn't work, then try adding it to `/etc/environment` as well.

```bash
# Install xproto & xorg development libraries (xorg is precautionary, so can be excluded)
sudo apt-get install -y x11proto-dev xorg-dev libgl1-mesa-dev

# Check if PKG_CONFIG_PATH exists first before modifying or overwriting it
echo $PKG_CONFIG_PATH

# Add PKG_CONFIG_PATH to .bashrc only if it doesn't exist or is empty
if [ -z "$PKG_CONFIG_PATH" ]; then
    echo "PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig" | sudo tee -a ~/.bashrc
    source ~/.bashrc
    pkg-config --cflags --libs gtk+-3.0
else
    echo "PKG_CONFIG_PATH is already set."
fi

# Confirm that gtk+-3.0 is found in the output
flutter doctor
```

```bash
flutter clean
flutter pub get
```

Debug mode

```bash
flutter run -d linux
```

Release mode

```bash
flutter run -d linux --release
```

Build

```bash
flutter build linux
```

### Mobile

Building an app for Android and iOS requires you to download their respective IDEs and enable developer mode to build directly to the device.

However, iOS tooling only works on macOS host.

### Android

For Android, after installing the IDE and initial tools using the setup wizard, run the app with `flutter run`.
Flutter will attempt to build the app, and any missing Android SDK dependency will be downloaded.

Running the app on an Android emulator has been tested on Apple Silicon Macs only; for other host platforms, a physical device might be required.

1. `flutter clean`
2. `flutter pub get`
3. Activate developer mode and USB debugging on your device
4. Connect your device to your computer with a USB cable
5. Ensure Flutter is aware of your device by running `flutter devices`
6. Copy your device ID
7. Run in debug mode with `flutter run -d <device-id>`
8. Follow instructions on your device

Release mode:

```bash
flutter run -d <device-id> --release
```

Build APK:

```bash
flutter build apk
```

Build App Bundle:

```bash
flutter build appbundle
```

### iOS

In order to build for iOS/iPadOS, you need to use a macOS host (Apple silicon recommended)
Physical iPhone or iPad required, simulators are not yet supported.

1. `flutter clean`
2. `flutter pub get`
3. Connect your device to your Mac with a USB cable
4. Ensure Flutter is aware of your device by running `flutter devices`
5. Copy your device ID
6. Run in debug mode with `flutter run -d <device-id>`
7. Follow the instructions in the error message (if any)
   In many cases it's worth trying to run the app from XCode first, then run `flutter run -d <device-id>` again
    - Open `ios/Runner.xcworkspace` in XCode
    - Product -> Run
8. Follow the instructions on your device to trust the developer

Run in release mode:

```bash
flutter run -d <device-id> --release
```

Build:

```bash
flutter build ios
```
