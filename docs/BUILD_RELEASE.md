# Build Release version of the App

## Environment setup

Before building the app, make sure you have all the necessary tools installed. Follow the instructions in the [Environment Setup](./PROJECT_SETUP.md) document. Alternatively, you can use the Docker image as described here: (TODO!).

### Firebase Analytics Setup

Optionally, you can enable Firebase Analytics for the app. To do so, follow the instructions in the [Firebase Analytics Setup](./FIREBASE_SETUP.md) document.

## Security Considerations

⚠️ **IMPORTANT**: For all production builds, be sure to follow the security practices outlined in the [Build Security Advisory](./BUILD_SECURITY_ADVISORY.md). Always use `--enforce-lockfile` and `--no-pub` flags when building for production.

## Build for Web

### Standard Build

```bash
flutter pub get --enforce-lockfile
flutter build web --csp --no-web-resources-cdn --no-pub
```

### WebAssembly Build (Recommended)

For improved performance and multi-threading support:

```bash
flutter pub get --enforce-lockfile
flutter build web --csp --no-web-resources-cdn --no-pub --wasm
```

The release version of the app will be located in `build/web` folder. Specifying the `--release` flag is not necessary, as it is the default behavior.

**Note**: WebAssembly builds require specific HTTP headers to be set on the web server for multi-threading support. See the [WebAssembly Setup](#webassembly-setup) section below for details.

## Native builds

Run `flutter build {TARGET}` command with one of the following targets:

- `apk` - builds Android APK (output to `build/app/outputs/flutter-apk` folder)
- `appbundle` - builds Android bundle (output to `build/app/outputs/bundle/release` folder)
- `ios` - builds for iOS (output to `build/ios/iphoneos` folder)
- `macos` - builds for macOS (output to `build/macos/Build/Products/Release` folder)
- `linux` - builds for Linux (output to `build/linux/x64/release/bundle` folder)
- `windows` - builds for Windows (output to `build/windows/runner/Release` folder)

Example:

```bash
flutter build apk
```

## Docker builds

### Build for web

```bash
sh .docker/build.sh web release
```

**Note**: The Docker build now includes WebAssembly support by default using the `--wasm` flag.

Alternatively, you can run the docker build commands directly:

```bash
# Build the supporting images
docker build -f .docker/kdf-android.dockerfile . -t komodo/kdf-android --build-arg KDF_BRANCH=main
docker build -f .docker/android-sdk.dockerfile . -t komodo/android-sdk:34
docker build -f .docker/komodo-wallet-android.dockerfile . -t komodo/komodo-wallet
# Build the app
mkdir -p build
docker run --rm -v ./build:/app/build komodo/komodo-wallet:latest bash -c "flutter pub get --enforce-lockfile && flutter build web --no-pub --release --wasm"
```

## WebAssembly Setup

WebAssembly builds provide improved performance and enable multi-threading support for better user experience. However, they require specific HTTP headers to be configured on the web server.

### Required HTTP Headers

For Flutter web applications compiled with WebAssembly to run with multi-threading support, the following HTTP headers must be set:

| Header Name                  | Value                              |
| ---------------------------- | ---------------------------------- |
| Cross-Origin-Embedder-Policy | `credentialless` or `require-corp` |
| Cross-Origin-Opener-Policy   | `same-origin`                      |

### Browser Compatibility

WebAssembly (WasmGC) support is available in:

- **Chrome/Chromium**: Version 119 and later
- **Firefox**: Version 120 and later (currently experiencing compatibility issues with Flutter)
- **Safari**: Latest versions support WasmGC but may have compatibility issues
- **iOS browsers**: Not supported (all iOS browsers use WebKit)

### Server Configuration Examples

#### Firebase Hosting

Our Firebase configuration (`firebase.json`) already includes the required headers:

```json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "Cross-Origin-Embedder-Policy",
            "value": "credentialless"
          },
          {
            "key": "Cross-Origin-Opener-Policy",
            "value": "same-origin"
          }
        ]
      }
    ]
  }
}
```

#### Nginx Configuration

For nginx servers, add the following headers to your location block:

```nginx
location / {
    add_header Cross-Origin-Embedder-Policy credentialless;
    add_header Cross-Origin-Opener-Policy same-origin;
    # ... other configuration
}
```

#### Apache Configuration

For Apache servers, add to your `.htaccess` or virtual host configuration:

```apache
Header always set Cross-Origin-Embedder-Policy "credentialless"
Header always set Cross-Origin-Opener-Policy "same-origin"
```

### Fallback Support

Flutter automatically provides JavaScript fallback when WebAssembly is not supported or when the required headers are missing. This ensures the application works across all browsers, with enhanced performance on compatible ones.

### Testing WebAssembly Support

You can verify if your application is running with WebAssembly by checking the `dart2wasm` environment variable in your Dart code:

```dart
const isRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');
```

### Build for Android

```bash
sh .docker/build.sh android release
```

Alternatively, you can run the docker build commands directly:

```bash
# Build the supporting images
docker build -f .docker/kdf-android.dockerfile . -t komodo/kdf-android --build-arg KDF_BRANCH=main
docker build -f .docker/android-sdk.dockerfile . -t komodo/android-sdk:34
docker build -f .docker/komodo-wallet-android.dockerfile . -t komodo/komodo-wallet
# Build the app
mkdir -p build
docker run --rm -v ./build:/app/build komodo/komodo-wallet:latest bash -c "flutter pub get --enforce-lockfile && flutter build apk --no-pub --release"
```
