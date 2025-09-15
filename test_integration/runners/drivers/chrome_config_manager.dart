// ignore_for_file: avoid_print

import 'dart:io';

/// Chrome configuration backup and restore functionality
class ChromeConfigManager {
  ChromeConfigManager(this.flutterRoot) {
    _chromeConfigPaths = [
      '$flutterRoot/packages/flutter_tools/lib/src/web/chrome.dart',
      '$flutterRoot/packages/flutter_tools/lib/src/drive/web_driver_service.dart',
    ];
    _backupPaths = _chromeConfigPaths.map((path) => '$path.backup').toList();
  }

  final String flutterRoot;
  late final List<String> _chromeConfigPaths;
  late final List<String> _backupPaths;
  final List<String> _argsAppended = [];

  bool get isConfigured => _argsAppended.isNotEmpty;

  /// Create backup and append the provided arguments to the ChromeConfiguration
  /// in the flutter_tools package.
  ///
  /// Throws an [Exception] if something goes wrong with finding flutter
  /// or modifying the file.
  void appendArgsToChromeConfiguration(List<String> args) {
    _deleteFlutterToolsStampFile(throwOnFailure: false);

    for (var i = 0; i < _chromeConfigPaths.length; i++) {
      final configPath = _chromeConfigPaths[i];
      // Clear existing arguments from the file to fix a bug & in case of CTRL+C
      // Do this before creating a backup, since the backup is used to replace
      // the modified config after `flutter drive` is done.
      _clearArgumentsFromFile(configPath, args);

      final backupPath = _backupPaths[i];
      print('Creating backup of chrome configuration at $backupPath');
      final file = File(configPath)..copySync(backupPath);

      print('Modifying the chrome configuration in $configPath');
      final contents = file.readAsStringSync();
      final newContents = contents.replaceFirst(
        '--disable-extensions',
        "--disable-extensions','${args.join("','")}",
      );

      file.writeAsStringSync(newContents);
      print('ChromeConfiguration updated with args: $args at $configPath');
    }

    _argsAppended.addAll(args);
  }

  void _deleteFlutterToolsStampFile({bool throwOnFailure = true}) {
    try {
      final stamp = '$flutterRoot/bin/cache/flutter_tools.stamp';
      final snapshot = '$flutterRoot/bin/cache/flutter_tools.snapshot';
      final stampFile = File(stamp);
      final snapshotFile = File(snapshot);
      if (!stampFile.existsSync() || !snapshotFile.existsSync()) {
        throw Exception('''
    Flutter tools stamp file not found. Please run `flutter pub get` first.
    $stampFile
    ''');
      }
      stampFile.deleteSync();
      print('Deleted flutter tools stamp file at $stamp');
      snapshotFile.deleteSync();
      print('Deleted flutter tools snapshot file at $snapshot');
    } catch (e) {
      if (throwOnFailure) {
        rethrow;
      }
    }
  }

  /// Restore the original ChromeConfiguration from backup.
  ///
  /// Throws an [Exception] if the backup file cannot be found
  /// or if there's an error restoring it.
  void restoreChromeConfiguration() {
    if (!isConfigured) {
      print('ChromeConfiguration is not configured. Nothing to restore.');
      return;
    }

    for (var i = 0; i < _chromeConfigPaths.length; i++) {
      final configPath = _chromeConfigPaths[i];
      final backupPath = _backupPaths[i];

      final backupFile = File(backupPath);
      if (backupFile.existsSync()) {
        print('Restoring chrome configuration from backup at $configPath');
        backupFile
          ..copySync(configPath)
          ..deleteSync();
      } else {
        print(
          'No backup file found at $backupPath. Attempting to clean configurations.',
        );
        _clearArgumentsFromFile(configPath, _argsAppended);
      }
    }

    _deleteFlutterToolsStampFile();
    print('ChromeConfiguration restored or cleaned successfully');
    _argsAppended.clear();
  }

  void _clearArgumentsFromFile(String configPath, List<String> args) {
    final configFile = File(configPath);
    if (!configFile.existsSync()) {
      throw Exception('Configuration file not found at $configPath');
    }

    print('Cleaning $configPath of existing args');
    final contents = configFile.readAsStringSync();
    var cleanedContents = contents;
    for (var arg in args) {
      print("Removing all instances of ,'$arg'");
      cleanedContents = cleanedContents.replaceAll(",'$arg'", '');
    }

    configFile.writeAsStringSync(cleanedContents);
  }
}
