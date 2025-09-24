export 'legacy_desktop_decryption_stub.dart'
    if (dart.library.io) 'legacy_desktop_decryption_native.dart'
    if (dart.library.html) 'legacy_desktop_decryption_web.dart';
