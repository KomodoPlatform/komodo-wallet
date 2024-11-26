# Handle multiple Flutter versions

## FVM

The recommended method of handling multiple Flutter versions is to use [FVM](https://fvm.app/documentation/getting-started/installation).

```bash
curl -fsSL https://fvm.app/install.sh | bash

# Configure the Flutter version to use in the current directory (e.g. ~/komodo-wallet)
fvm use stable
```

## macOS

### 1. Clone new Flutter instance alongside with the existing one

```
cd ~
git clone https://github.com/flutter/flutter.git flutter_web
cd ./flutter_web
git checkout 3.23.4
```

### pen (or create) `.zshrc` file in your home directory

```
nano ~/.zshrc
```

Add line:

```
alias flutter_web="$HOME/flutter_web/bin/flutter"
```

Save and close.

### 3. Check if newly installed Flutter version is accessible from terminal

```
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

## Windows TBD

----

## Linux TBD
