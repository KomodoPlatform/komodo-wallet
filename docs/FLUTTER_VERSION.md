# Flutter version

This project aims to keep the Flutter version up-to-date with the latest stable release. See the section below for the latest version officially supported by this project.

## Current version

3.29.0

## Pin Flutter version

It is possible to pin the Flutter version to a specific version by checking out the corresponding tag. For example, to pin the Flutter version to 3.29.0, run the following commands:

```bash
cd ~/flutter
git checkout 3.29.0
flutter doctor
```

This is no longer recommended as it does not allow for sufficient isolation when working with multiple versions of Flutter, and there are known issues with this approach when running `flutter pub get` with Flutter 3.29.0.

See also: [Multiple flutter versions](MULTIPLE_FLUTTER_VERSIONS.md)
