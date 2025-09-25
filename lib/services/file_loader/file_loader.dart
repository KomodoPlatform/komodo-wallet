import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:web_dex/services/file_loader/file_loader_stub.dart'
    if (dart.library.io) 'package:web_dex/services/file_loader/file_loader_native.dart'
    if (dart.library.html) 'package:web_dex/services/file_loader/file_loader_web.dart';

class LoadedFileData {
  const LoadedFileData({this.text, this.bytes})
    : assert(text != null || bytes != null);

  final String? text;
  final Uint8List? bytes;

  bool get hasBytes => bytes != null;
  bool get hasText => text != null && text!.isNotEmpty;
}

abstract class FileLoader {
  const FileLoader();

  factory FileLoader.fromPlatform() => createFileLoader();

  Future<void> save({
    required String fileName,
    required String data,
    required LoadFileType type,
  });
  Future<void> upload({
    required void Function(String name, LoadedFileData data) onUpload,
    required void Function(String) onError,
    LoadFileType? fileType,
  });
}

enum LoadFileType {
  compressed,
  text;

  FileType get fileType {
    switch (this) {
      case LoadFileType.compressed:
      case LoadFileType.text:
        return FileType.custom;
    }
  }

  String get mimeType {
    switch (this) {
      case LoadFileType.compressed:
        return 'application/zip';
      case LoadFileType.text:
        return 'text/plain';
    }
  }

  List<String> get extensions {
    switch (this) {
      case LoadFileType.compressed:
        return const ['zip'];
      case LoadFileType.text:
        return const ['txt', 'seed'];
    }
  }

  String get extension => extensions.first;
}
