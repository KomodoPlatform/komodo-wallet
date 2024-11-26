import 'dart:io';

import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/services/file_loader/file_loader_native_desktop.dart';
import 'package:web_dex/services/file_loader/mobile/file_loader_native_android.dart';
import 'package:web_dex/services/file_loader/mobile/file_loader_native_ios.dart';

FileLoader createFileLoader() {
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return const FileLoaderNativeDesktop();
  }
  if (Platform.isAndroid) {
    return const FileLoaderNativeAndroid();
  }
  if (Platform.isIOS) {
    return const FileLoaderNativeIOS();
  }
  throw UnimplementedError();
}
