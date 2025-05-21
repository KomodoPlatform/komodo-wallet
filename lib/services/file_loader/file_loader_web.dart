import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'package:web_dex/services/file_loader/file_loader.dart';
import 'package:web_dex/shared/utils/utils.dart';

FileLoader createFileLoader() => const FileLoaderWeb();

class FileLoaderWeb implements FileLoader {
  const FileLoaderWeb();

  @override
  Future<void> save({
    required String fileName,
    required String data,
    required LoadFileType type,
    String? extension,
  }) async {
    switch (type) {
      case LoadFileType.text:
        await _saveAsTextFile(
            filename: '$fileName.${extension ?? 'txt'}', data: data);
      case LoadFileType.compressed:
        await _saveAsCompressedFile(
            fileName: fileName, data: data, ext: extension ?? 'txt');
    }
  }

  Future<void> _saveAsTextFile({
    required String filename,
    required String data,
  }) async {
    final dataArray = web.TextEncoder().encode(data);
    final blob =
        web.Blob([dataArray].toJS, web.BlobPropertyBag(type: 'text/plain'));

    final url = web.URL.createObjectURL(blob);

    try {
      // Create an anchor element and set the attributes
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = filename
        ..style.display = 'none';

      // Append to the DOM and trigger click
      web.document.body?.append(anchor);
      anchor
        ..click()
        ..remove();
    } finally {
      // Revoke the object URL
      web.URL.revokeObjectURL(url);
    }
  }

  Future<void> _saveAsCompressedFile({
    required String fileName,
    required String data,
    required String ext,
  }) async {
    try {
      // add the extension of the contained file to the filename, so that the
      // extracted file is simply the filename excluding '.zip'
      final fileNameWithExt = '$fileName.$ext';

      final encoder = web.TextEncoder();
      final dataArray = encoder.encode(data);
      final blob =
          web.Blob([dataArray].toJS, web.BlobPropertyBag(type: 'text/plain'));

      final response = web.Response(blob);
      final compressedResponse = web.Response(
        response.body!.pipeThrough(
          web.CompressionStream('gzip') as web.ReadableWritablePair,
        ),
      );

      final compressedBlob = await compressedResponse.blob().toDart;
      final url = web.URL.createObjectURL(compressedBlob);

      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = '$fileNameWithExt.zip'
        ..style.display = 'none';

      web.document.body?.append(anchor);
      anchor
        ..click()
        ..remove();

      web.URL.revokeObjectURL(url);
    } catch (e) {
      log('Error compressing and saving file: $e').ignore();
    }
  }

  @override
  Future<void> upload({
    required void Function(String name, String? content) onUpload,
    required void Function(String) onError,
    LoadFileType? fileType,
  }) async {
    final uploadInput = web.HTMLInputElement()..type = 'file';

    if (fileType != null) {
      uploadInput.accept = _getMimeType(fileType);
    }

    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final web.FileList? files = uploadInput.files;
      if (files == null) {
        return;
      }

      if (files.length == 1) {
        final web.File? file = files.item(0);
        final reader = web.FileReader();

        reader.onLoadEnd.listen((event) {
          final result = reader.result;
          if (result case final String content) {
            onUpload(file!.name, content);
          }
        });

        reader
          ..onerror = (JSAny event) {
            if (event is web.ErrorEvent) {
              onError(event.message);
            }
          }.toJS
          ..readAsText(file! as web.Blob);
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
