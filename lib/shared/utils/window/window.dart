export 'window_stub.dart'
    if (dart.library.io) './window_native.dart'
    if (dart.library.html) './window_web.dart';
