import 'dart:convert';

import 'dart:js_interop';
import 'package:web/web.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:web_dex/platform/platform.dart';
import 'package:web_dex/services/file_loader/file_loader.dart';

class FileLoaderWeb implements FileLoader {
  const FileLoaderWeb();
  @override
  Future<void> save({
    required String fileName,
    required String data,
    required LoadFileType type,
  }) async {
    switch (type) {
      case LoadFileType.text:
        await _saveAsTextFile(filename: fileName, data: data);
        return;
      case LoadFileType.compressed:
        await _saveAsCompressedFile(fileName: fileName, data: data);
        return;
    }
  }

  Future<void> _saveAsTextFile({
    required String filename,
    required String data,
  }) async {
    final HTMLAnchorElement anchor = HTMLAnchorElement();
    anchor.href =
        '${Uri.dataFromString(data, mimeType: 'text/plain', encoding: utf8)}';
    anchor.download = filename;
    anchor.style.display = 'none';
    anchor.click();
  }

  Future<void> _saveAsCompressedFile({
    required String fileName,
    required String data,
  }) async {
    final String? compressedData =
        await zipEncode('$fileName.txt'.toJS, data.toJS).toDart;

    if (compressedData == null) return;

    final HTMLAnchorElement anchor = HTMLAnchorElement();
    anchor.href = 'data:application/zip;base64,$compressedData';
    anchor.download = '$fileName.zip';
    anchor.click();
  }

  @override
  Future<void> upload({
    required Function(String name, String? content) onUpload,
    required Function(String) onError,
    LoadFileType? fileType,
  }) async {
    final HTMLInputElement uploadInput = HTMLInputElement();
    if (fileType != null) {
      uploadInput.setAttribute('accept', _getMimeType(fileType));
    }
    uploadInput.click();
    uploadInput.onChange.listen((Event event) {
      final List<File>? files = uploadInput.files;
      if (files == null) {
        return;
      }
      if (files.length == 1) {
        final file = files[0];

        final FileReader reader = FileReader();

        reader.onLoadEnd.listen((_) {
          final result = reader.result;
          if (result is String) {
            onUpload(file.name, result);
          }
        });
        reader.onError.listen(
          (ProgressEvent _) {},
          onError: (Object error) => onError(error.toString()),
        );

        reader.readAsText(file);
      }
    });
  }

  String _getMimeType(LoadFileType type) {
    switch (type) {
      case LoadFileType.compressed:
        return 'application/zip';
      case LoadFileType.text:
        return 'text/plain';
    }
  }
}
