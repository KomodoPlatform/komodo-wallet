import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:komodo_wallet/services/file_loader/file_loader.dart';
import 'package:komodo_wallet/shared/utils/utils.dart';
import 'package:komodo_wallet/shared/utils/zip.dart';

class FileLoaderNativeAndroid implements FileLoader {
  const FileLoaderNativeAndroid();

  @override
  Future<void> save({
    required String fileName,
    required String data,
    LoadFileType type = LoadFileType.text,
  }) async {
    switch (type) {
      case LoadFileType.text:
        await _saveAsTextFile(fileName: fileName, data: data);
      case LoadFileType.compressed:
        await _saveAsCompressedFile(fileName: fileName, data: data);
    }
  }

  Future<void> _saveAsTextFile({
    required String fileName,
    required String data,
  }) async {
    // On mobile, the file bytes are used to create the file to be saved.
    // On desktop a file is created first, then a file is saved.
    final Uint8List fileBytes = utf8.encode(data);
    final String? fileFullPath = await FilePicker.platform.saveFile(
      fileName: '$fileName.txt',
      bytes: fileBytes,
    );
    if (fileFullPath == null || fileFullPath.isEmpty == true) {
      log('error: output filepath for $fileName is empty');
    }
  }

  Future<void> _saveAsCompressedFile({
    required String fileName,
    required String data,
  }) async {
    final Uint8List compressedBytes =
        createZipOfSingleFile(fileName: fileName, fileContent: data);
    final String? fileFullPath = await FilePicker.platform.saveFile(
      fileName: '$fileName.zip',
      bytes: compressedBytes,
    );

    if (fileFullPath == null || fileFullPath.isEmpty == true) {
      log('error: output filepath for $fileName is empty');
    }
  }

  @override
  Future<void> upload({
    required void Function(String name, String content) onUpload,
    required void Function(String) onError,
    LoadFileType? fileType,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType == null ? FileType.any : fileType.fileType,
        allowedExtensions: fileType != null ? [fileType.extension] : null,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final path = file.path;
      if (path == null) return;

      final selectedFile = File(path);
      final data = await selectedFile.readAsString();

      onUpload(file.name, data);
    } catch (e) {
      onError(e.toString());
    }
  }
}
