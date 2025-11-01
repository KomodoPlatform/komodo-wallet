// ignore_for_file: avoid_print

import 'dart:io';

//app data path for mac and linux
const String macAppData = '/Library/Containers/com.komodo.wallet';
const String linuxAppData = '/.local/share/com.komodo.KomodoWallet';
const String windowsAppData = r'\AppData\Roaming\com.komodo';

Future<void> clearNativeAppsData() async {
  if (Platform.isWindows) {
    await _clearAppDataWindows();
  } else if (Platform.isLinux) {
    await _clearAppDataLinux();
  } else if (Platform.isMacOS) {
    await _clearAppDataMacos();
  }
}

Future<ProcessResult> _clearAppDataMacos() async {
  ProcessResult deleteResult = ProcessResult(-1, 0, null, null);
  final homeDir = Platform.environment['HOME'];
  deleteResult = await Process.run(
    'rm',
    ['-rf', '$homeDir$macAppData'],
    runInShell: true,
  );
  if (deleteResult.exitCode == 0) {
    print('MacOS App data removed successfully.');
  } else {
    print('Failed to remove MacOS app data. Error: ${deleteResult.stderr}');
  }
  return deleteResult;
}

Future<ProcessResult> _clearAppDataLinux() async {
  ProcessResult deleteResult = ProcessResult(-1, 0, null, null);
  final homeDir = Platform.environment['HOME'];
  deleteResult = await Process.run(
    'rm',
    ['-rf', '$homeDir$linuxAppData'],
    runInShell: true,
  );
  if (deleteResult.exitCode == 0) {
    print('Linux App data removed successfully.');
  } else {
    print('Failed to remove Linux app data. Error: ${deleteResult.stderr}');
  }
  return deleteResult;
}

Future<ProcessResult> _clearAppDataWindows() async {
  ProcessResult deleteResult = ProcessResult(-1, 0, null, null);
  final homeDir = Platform.environment['UserProfile'];
  if (Directory('$homeDir$windowsAppData').existsSync()) {
    deleteResult = await Process.run(
      'rmdir',
      ['/s', '/q', '$homeDir$windowsAppData'],
      runInShell: true,
    );
    if (deleteResult.exitCode == 0) {
      print('Windows App data removed successfully.');
    } else {
      print(
        'Failed to remove Windows app data. Error: ${deleteResult.stderr}',
      );
    }
  } else {
    print('No need clean windows app data');
  }
  return deleteResult;
}
