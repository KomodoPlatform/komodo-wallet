# Build Release version of the App

### Environment setup

Before building the app, make sure you have all the necessary tools installed. Follow the instructions in the [Environment Setup](./PROJECT_SETUP.md) document. Alternatively, you can use the Docker image as described here: (TODO!).

### Firebase Analytics Setup

Optionally, you can enable Firebase Analytics for the app. To do so, follow the instructions in the [Firebase Analytics Setup](./FIREBASE_SETUP.md) document.

## Build for Web

```bash
flutter build web --csp --no-web-resources-cdn
```

The release version of the app will be located in `build/web` folder. Specifying the `--release` flag is not necessary, as it is the default behavior.

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

Alternatively, you can run the docker build commands directly:

```bash
# Build the supporting images
docker build -f .docker/kdf-android.dockerfile . -t komodo/kdf-android --build-arg KDF_BRANCH=main
docker build -f .docker/android-sdk.dockerfile . -t komodo/android-sdk:34
docker build -f .docker/komodo-wallet-android.dockerfile . -t komodo/komodo-wallet
# Build the app
mkdir -p build
docker run --rm -v ./build:/app/build komodo/komodo-wallet:latest bash -c "flutter pub get && flutter build web --release || flutter build web --release"
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
docker run --rm -v ./build:/app/build komodo/komodo-wallet:latest bash -c "flutter pub get && flutter build apk --release || flutter build apk --release"
```

## Signing builds

### Android

1. Generate keystore file:

    ```bash
    keytool -genkey -v -keystore komodo-wallet.jks -keyalg RSA -keysize 2048 -validity 10000 -alias komodo
    ```

2. Convert keystore to base64:

    ```bash
    base64 -i komodo-wallet.jks -o keystore-base64.txt
    ```

3. Validate

    ```bash
    keytool -list -v -keystore komodo-wallet.jks
    ```

Example secrets:

```yaml
ANDROID_KEYSTORE_BASE64: "/u3+7QAAAAIAAAABAAAAAQAHa29tb2RvAAABjK6LSU8AAAUBMIIE..."
ANDROID_KEY_ALIAS: "komodo"
ANDROID_STORE_PASSWORD: "your-keystore-password"
ANDROID_KEY_PASSWORD: "your-key-password"
```

Documentation:

- [Android Signing Guide](https://developer.android.com/studio/publish/app-signing)

### iOS/macOS

1. Create Apple Developer Account
2. Generate certificates in Apple Developer Portal:
    iOS: App Store and Ad Hoc distribution certificate
    macOS: Mac App Store certificate
3. Export P12:

    ```bash
    # Export from Keychain and convert to base64
    base64 -i certificate.p12 -o cert-base64.txt
    ```

4. Create App Store Connect API Key
5. Validate

    ```bash
    security find-identity -v -p codesigning
    ```

Example secrets:

```yaml
IOS_P12_BASE64: "MIIKsQIBAzCCCnsGCSqGSIb3DQEHAaCCCmwEggpo..."
IOS_P12_PASSWORD: "your-p12-password"
MACOS_P12_BASE64: "MIIKsQIBAzCCCnsGCSqGSIb3DQEHAaCCCmwEggpo..."
MACOS_P12_PASSWORD: "your-p12-password"
APPSTORE_ISSUER_ID: "57246542-96fe-1a63-e053-0824d011072a"
APPSTORE_KEY_ID: "2X9R4HXF34"
APPSTORE_PRIVATE_KEY: "-----BEGIN PRIVATE KEY-----\nMIGTAgEAMBMG..."
```

Documentation:

- [iOS Code Signing Guide](https://medium.com/@bingkuo/a-beginners-guide-to-code-signing-in-ios-development-d3d5285f0960)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Provisioning Profiles](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

### Windows

1. Purchase a code signing certificate from a trusted CA (like DigiCert)
2. Export as PFX with private key
3. Convert to base64:

    ```Powershell
    certutil -encode certificate.pfx cert-base64.txt
    ```

4. Validate

    ```Powershell
    signtool verify /pa your-app.exe
    ```

Example secrets:

```yaml
WINDOWS_PFX_BASE64: "MIIKkgIBAzCCClYGCSqGSIb3DQEHAaCCCkcEggpD..."
WINDOWS_PFX_PASSWORD: "your-pfx-password"
```

Documentation:

- [Windows Code Signing Guide](https://learn.microsoft.com/en-us/windows/win32/appxpkg/how-to-sign-a-package-using-signtool)
- [Microsoft Authenticode](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/authenticode)

### Linux

1. Generate GPG key:

    ```bash
    gpg --full-generate-key
    ```

2. Export private key:

    ```bash
    gpg --export-secret-keys --armor YOUR_KEY_ID | base64 > gpg-key-base64.txt
    ```

3. Validate

    ```bash
    gpg --verify your-package.deb.asc your-package.deb
    ```

Example secrets:

```yaml

```

Documentation:

- [GPG Guide](https://gnupg.org/documentation/guides.html)
- [Debian Package Signing](https://wiki.debian.org/SecureApt)

### Setting up in GitHub

1. Go to your repository settings
2. Navigate to Secrets and Variables > Actions
3. Add each secret:

    ```bash
    gh secret set ANDROID_KEYSTORE_BASE64 < keystore-base64.txt
    gh secret set ANDROID_KEY_ALIAS --body "komodo"
    # Repeat for all secrets
    ```

### Common Steps for All Platforms

1. Keep original certificates and keys securely backed up
2. Document expiration dates and renewal procedures
3. Setup secure processes for sharing signing credentials with team
4. Consider using HashiCorp Vault or similar for secrets management
5. Implement separate certificates for development/staging

### Best Practices

- Never commit certificates or keys to source control
- Use strong passwords for all certificates
- Limit access to production signing credentials
- Regularly audit access to signing credentials
- Have a process for emergency certificate revocation
- Use different certificates for development and production
- Document the signing setup process thoroughly
- Security Considerations
- Store backup copies of certificates securely
- Use strong passwords for key stores and certificates
- Limit the number of people with access to production certificates
- Regular rotation of development certificates
- Separate signing process for production releases
