// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
// This is a web-specific file, so it's safe to ignore this warning
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js_util.dart';

class KdfPlugin {
  static void registerWith(Registrar registrar) {
    final plugin = KdfPlugin();
    // ignore: unused_local_variable
    final channel = MethodChannel(
      'komodo_defi_framework/kdf',
      const StandardMethodCodec(),
      registrar,
    )..setMethodCallHandler(plugin.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'ensureLoaded':
        return _ensureLoaded();
      case 'mm2Main':
        final args = call.arguments as Map<String, dynamic>;
        return _mm2Main(
          args['conf'] as String,
          args['logCallback'] as Function,
        );
      case 'mm2MainStatus':
        return _mm2MainStatus();
      case 'mm2Stop':
        return _mm2Stop();
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }

  bool _libraryLoaded = false;
  Future<void>? _loadPromise;

  Future<void> _ensureLoaded() async {
    if (_loadPromise != null) return _loadPromise;

    _loadPromise = _loadLibrary();
    await _loadPromise;
  }

  Future<void> _loadLibrary() async {
    if (_libraryLoaded) return;

    final completer = Completer<void>();

    final script =
        js.context['document'].callMethod('createElement', ['script']);
    script['src'] = 'kdf/kdflib.js';
    script['onload'] = js.allowInterop(() {
      _libraryLoaded = true;
      completer.complete();
    });
    script['onerror'] = js.allowInterop((event) {
      completer.completeError('Failed to load kdflib.js');
    });

    js.context['document']['head'].callMethod('appendChild', [script]);

    return completer.future;
  }

  Future<int> _mm2Main(String conf, Function logCallback) async {
    await _ensureLoaded();
    return dartify(
      js.context.callMethod('mm2_main', [conf, js.allowInterop(logCallback)]),
    )! as int;
  }

  int _mm2MainStatus() {
    if (!_libraryLoaded) {
      throw StateError('KDF library not loaded. Call ensureLoaded() first.');
    }
    return js.context.callMethod('mm2_main_status') as int;
  }

  Future<int> _mm2Stop() async {
    await _ensureLoaded();
    return js.context.callMethod('mm2_stop') as int;
  }
}
