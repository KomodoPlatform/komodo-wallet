// Stub file for web platform - exit is not available on web
void exit(int code) {
  // On web, we can't exit the process
  // This should never be called as we check kIsWeb before using exit
  throw UnsupportedError('exit() is not available on web platform');
}

