// ignore_for_file: avoid_print

import 'dart:io';

/// Attempt multiple methods of finding the current flutter executable root
/// from PATH, environment variables, and where.
///
/// Throws an [Exception] if the flutter executable cannot be found.
/// Returns the path to the flutter executable if found.
String findFlutterRoot() {
  // Check FLUTTER_ROOT environment variable first
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && Directory(flutterRoot).existsSync()) {
    return flutterRoot;
  }

  // Common installation paths by platform
  final commonPaths = <String>[
    if (Platform.isMacOS) ...[
      '/usr/local/flutter',
      '${Platform.environment['HOME']}/flutter',
      '${Platform.environment['HOME']}/development/flutter',
    ],
    if (Platform.isLinux) ...[
      '/usr/local/flutter',
      '${Platform.environment['HOME']}/flutter',
      '${Platform.environment['HOME']}/development/flutter',
      '/opt/flutter',
    ],
    if (Platform.isWindows) ...[
      r'C:\flutter',
      r'C:\src\flutter',
      '${Platform.environment['LOCALAPPDATA']}\\flutter',
      '${Platform.environment['USERPROFILE']}\\flutter',
    ],
  ];

  // Check common paths
  for (final path in commonPaths) {
    if (Directory(path).existsSync()) {
      return path;
    }
  }

  // Check PATH environment variable
  final pathEnv = Platform.environment['PATH'];
  if (pathEnv != null) {
    for (final path in pathEnv.split(Platform.pathSeparator)) {
      // Look for flutter executable in PATH
      final flutterExe = Platform.isWindows
          ? '$path${Platform.pathSeparator}flutter.bat'
          : '$path${Platform.pathSeparator}flutter';

      if (File(flutterExe).existsSync()) {
        // Return parent directory of bin folder
        return Directory(path).parent.path;
      }
    }
  }

  // Try using where/which command
  final command = Platform.isWindows ? 'where' : 'which';
  final result = Process.runSync(command, ['flutter']);

  if (result.exitCode == 0) {
    final executablePath = result.stdout.toString().trim();
    // Return parent directory of bin folder
    return Directory(File(executablePath).parent.path).parent.path;
  }

  throw Exception('''
Flutter SDK not found. Please ensure Flutter is installed and either:
- FLUTTER_ROOT environment variable is set
- Flutter is installed in a common location
- Flutter binary is available in PATH
''');
}
