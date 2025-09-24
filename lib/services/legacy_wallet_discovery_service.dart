import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:web_dex/model/legacy_wallet_data.dart';
import 'package:web_dex/services/legacy_wallet_migration_service.dart';
import 'package:web_dex/shared/utils/utils.dart';

/// Automatic discovery service for legacy AtomicDEX desktop wallet data
///
/// This service scans the local filesystem for legacy desktop app installations
/// and data, enabling seamless migration without requiring manual file selection.
class LegacyWalletDiscoveryService {
  static const String _legacyDataFolderName = 'atomicdex-desktop';
  static const String _legacyConfigFolderName = 'config';
  static const String _legacyWalletFileName = 'default.wallet';
  static const String _legacySeedExtension = '.seed';

  final LegacyWalletMigrationService _migrationService =
      LegacyWalletMigrationService();

  /// Scans for legacy desktop app installations and data on the current device
  Future<LegacyDesktopInstallation?> discoverLegacyInstallation() async {
    try {
      log(
        'Starting legacy desktop discovery',
        path: 'LegacyWalletDiscoveryService.discoverLegacyInstallation',
      );

      // Get potential data directories based on platform
      final dataPaths = _getLegacyDataPaths();

      for (final dataPath in dataPaths) {
        if (await Directory(dataPath).exists()) {
          log(
            'Checking legacy data path: $dataPath',
            path: 'LegacyWalletDiscoveryService.discoverLegacyInstallation',
          );

          final installation = await _scanDataDirectory(dataPath);
          if (installation != null) {
            log(
              'Found legacy installation at: $dataPath',
              path: 'LegacyWalletDiscoveryService.discoverLegacyInstallation',
            );
            return installation;
          }
        }
      }

      log(
        'No legacy desktop installation found',
        path: 'LegacyWalletDiscoveryService.discoverLegacyInstallation',
      );
      return null;
    } catch (e) {
      log(
        'Error during legacy discovery: $e',
        path: 'LegacyWalletDiscoveryService.discoverLegacyInstallation',
        isError: true,
      );
      return null;
    }
  }

  /// Gets platform-specific paths where legacy data might be stored
  List<String> _getLegacyDataPaths() {
    final List<String> paths = [];

    if (Platform.isWindows) {
      // Windows: %APPDATA%\atomicdex-desktop
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        paths.add(path.join(appData, _legacyDataFolderName));
      }

      // Also check LocalAppData
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null) {
        paths.add(path.join(localAppData, _legacyDataFolderName));
      }
    } else if (Platform.isMacOS) {
      // macOS: ~/Library/Application Support/atomicdex-desktop
      final home = Platform.environment['HOME'];
      if (home != null) {
        paths.add(
          path.join(
            home,
            'Library',
            'Application Support',
            _legacyDataFolderName,
          ),
        );
      }
    } else if (Platform.isLinux) {
      // Linux: ~/.atomicdex-desktop
      final home = Platform.environment['HOME'];
      if (home != null) {
        paths.add(path.join(home, '.$_legacyDataFolderName'));
      }

      // Also check XDG config
      final xdgConfig = Platform.environment['XDG_CONFIG_HOME'];
      if (xdgConfig != null) {
        paths.add(path.join(xdgConfig, _legacyDataFolderName));
      }
    }

    return paths;
  }

  /// Scans a directory for legacy wallet data
  Future<LegacyDesktopInstallation?> _scanDataDirectory(String dataPath) async {
    try {
      final installation = LegacyDesktopInstallation(dataPath: dataPath);

      // Look for config folder
      final configPath = path.join(dataPath, _legacyConfigFolderName);
      if (await Directory(configPath).exists()) {
        installation.configPath = configPath;

        // Scan for wallet files and configurations
        await _scanConfigDirectory(installation, configPath);
      }

      // Look for version-specific folders
      final dataDir = Directory(dataPath);
      await for (final entity in dataDir.list()) {
        if (entity is Directory) {
          final dirName = path.basename(entity.path);
          // Check if it looks like a version folder (e.g., "2.1.5", "v2.1.5")
          if (_isVersionFolder(dirName)) {
            await _scanVersionDirectory(installation, entity.path);
          }
        }
      }

      // Check if we found any useful data
      if (installation.hasWalletData()) {
        return installation;
      }

      return null;
    } catch (e) {
      log(
        'Error scanning directory $dataPath: $e',
        path: 'LegacyWalletDiscoveryService._scanDataDirectory',
        isError: true,
      );
      return null;
    }
  }

  /// Scans the config directory for wallet and configuration files
  Future<void> _scanConfigDirectory(
    LegacyDesktopInstallation installation,
    String configPath,
  ) async {
    try {
      final configDir = Directory(configPath);

      await for (final entity in configDir.list()) {
        if (entity is File) {
          final fileName = path.basename(entity.path);

          // Check for wallet files (typically .wallet extension or default.wallet)
          if (fileName.endsWith('.wallet') ||
              fileName == _legacyWalletFileName) {
            await _processWalletFile(installation, entity.path);
          }

          // Check for legacy encrypted seed files (*.seed)
          if (fileName.endsWith(_legacySeedExtension)) {
            await _processWalletFile(installation, entity.path);
          }

          // Check for configuration files
          if (fileName.endsWith('.json') || fileName.endsWith('.ini')) {
            await _processConfigFile(installation, entity.path);
          }
        }
      }
    } catch (e) {
      log(
        'Error scanning config directory $configPath: $e',
        path: 'LegacyWalletDiscoveryService._scanConfigDirectory',
        isError: true,
      );
    }
  }

  /// Scans version-specific directories
  Future<void> _scanVersionDirectory(
    LegacyDesktopInstallation installation,
    String versionPath,
  ) async {
    try {
      // Look for configs subfolder in version directory
      final versionConfigPath = path.join(versionPath, 'configs');
      if (await Directory(versionConfigPath).exists()) {
        await _scanConfigDirectory(installation, versionConfigPath);
      }
    } catch (e) {
      log(
        'Error scanning version directory $versionPath: $e',
        path: 'LegacyWalletDiscoveryService._scanVersionDirectory',
        isError: true,
      );
    }
  }

  /// Processes a potential wallet file
  Future<void> _processWalletFile(
    LegacyDesktopInstallation installation,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      final fileSize = await file.length();

      // Skip very small files (likely empty or invalid)
      if (fileSize < 10) return;

      // Read the file to check if it's a legacy wallet format
      final fileData = await file.readAsBytes();

      if (_migrationService.isLegacyDesktopFormat(fileData)) {
        final walletInfo = LegacyWalletFile(
          path: filePath,
          fileName: path.basename(filePath),
          size: fileSize,
          lastModified: await file.lastModified(),
        );

        installation.walletFiles.add(walletInfo);
        log(
          'Found legacy wallet file: $filePath',
          path: 'LegacyWalletDiscoveryService._processWalletFile',
        );
      }
    } catch (e) {
      log(
        'Error processing wallet file $filePath: $e',
        path: 'LegacyWalletDiscoveryService._processWalletFile',
        isError: true,
      );
    }
  }

  /// Processes configuration files
  Future<void> _processConfigFile(
    LegacyDesktopInstallation installation,
    String filePath,
  ) async {
    try {
      final fileName = path.basename(filePath);

      // Look for specific configuration files
      if (fileName.contains('coins') && fileName.endsWith('.json')) {
        // Coins configuration
        installation.configFiles['coins'] = filePath;
      } else if (fileName == 'cfg.ini' || fileName == 'settings.ini') {
        // Main settings
        installation.configFiles['settings'] = filePath;
      } else if (fileName.contains('addressbook') &&
          fileName.endsWith('.json')) {
        // Address book
        installation.configFiles['addressbook'] = filePath;
      } else if (fileName.contains('swap') && fileName.endsWith('.json')) {
        // Swap history
        installation.configFiles['swaps'] = filePath;
      } else if (fileName.contains('maker') && fileName.endsWith('.json')) {
        // Maker orders/configs
        installation.configFiles['maker'] = filePath;
      }

      log(
        'Found config file: $fileName at $filePath',
        path: 'LegacyWalletDiscoveryService._processConfigFile',
      );
    } catch (e) {
      log(
        'Error processing config file $filePath: $e',
        path: 'LegacyWalletDiscoveryService._processConfigFile',
        isError: true,
      );
    }
  }

  /// Checks if a directory name looks like a version folder
  bool _isVersionFolder(String dirName) {
    // Match patterns like "2.1.5", "v2.1.5", "2.1.5-beta", etc.
    final versionPattern = RegExp(r'^v?\d+\.\d+\.\d+');
    return versionPattern.hasMatch(dirName);
  }

  /// Attempts to automatically migrate discovered legacy data
  Future<LegacyMigrationResult> autoMigrateLegacyData({
    required LegacyDesktopInstallation installation,
    required String password,
    required String newWalletName,
  }) async {
    try {
      log(
        'Starting auto-migration for: $newWalletName',
        path: 'LegacyWalletDiscoveryService.autoMigrateLegacyData',
      );

      if (installation.walletFiles.isEmpty) {
        return LegacyMigrationResult.failure(
          'No wallet files found in legacy installation',
        );
      }

      // Try to migrate the most recent wallet file
      final walletFile = installation.getMostRecentWalletFile();
      final fileData = await File(walletFile.path).readAsBytes();

      final legacyData = await _migrationService.migrateLegacyWallet(
        fileData: fileData,
        password: password,
        newWalletName: newWalletName,
      );

      if (legacyData == null) {
        return LegacyMigrationResult.failure(
          'Failed to decrypt wallet with provided password',
        );
      }

      // Try to load additional data from config files
      await _loadAdditionalConfigData(installation, legacyData);

      return LegacyMigrationResult.success(
        legacyData: legacyData,
        sourceFile: walletFile.path,
        additionalFiles: installation.configFiles,
      );
    } catch (e) {
      log(
        'Error during auto-migration: $e',
        path: 'LegacyWalletDiscoveryService.autoMigrateLegacyData',
        isError: true,
      );
      return LegacyMigrationResult.failure('Migration failed: $e');
    }
  }

  /// Loads additional data from configuration files
  Future<void> _loadAdditionalConfigData(
    LegacyDesktopInstallation installation,
    LegacyWalletData legacyData,
  ) async {
    try {
      // Load address book if available
      if (installation.configFiles.containsKey('addressbook')) {
        await _loadAddressBookData(
          installation.configFiles['addressbook']!,
          legacyData,
        );
      }

      // Load swap history if available
      if (installation.configFiles.containsKey('swaps')) {
        await _loadSwapHistoryData(
          installation.configFiles['swaps']!,
          legacyData,
        );
      }

      // Load maker data if available
      if (installation.configFiles.containsKey('maker')) {
        await _loadMakerData(installation.configFiles['maker']!, legacyData);
      }
    } catch (e) {
      log(
        'Error loading additional config data: $e',
        path: 'LegacyWalletDiscoveryService._loadAdditionalConfigData',
        isError: true,
      );
    }
  }

  /// Loads address book data from configuration file
  Future<void> _loadAddressBookData(
    String filePath,
    LegacyWalletData legacyData,
  ) async {
    // Implementation would depend on the exact format of the legacy address book
    // This is a placeholder that would need to be implemented based on actual format
    log(
      'Loading address book data from: $filePath',
      path: 'LegacyWalletDiscoveryService._loadAddressBookData',
    );
  }

  /// Loads swap history data from configuration file
  Future<void> _loadSwapHistoryData(
    String filePath,
    LegacyWalletData legacyData,
  ) async {
    // Implementation would depend on the exact format of the legacy swap history
    // This is a placeholder that would need to be implemented based on actual format
    log(
      'Loading swap history data from: $filePath',
      path: 'LegacyWalletDiscoveryService._loadSwapHistoryData',
    );
  }

  /// Loads maker order/config data from configuration file
  Future<void> _loadMakerData(
    String filePath,
    LegacyWalletData legacyData,
  ) async {
    // Implementation would depend on the exact format of the legacy maker data
    // This is a placeholder that would need to be implemented based on actual format
    log(
      'Loading maker data from: $filePath',
      path: 'LegacyWalletDiscoveryService._loadMakerData',
    );
  }

  /// Validates that a discovered installation is legitimate
  Future<bool> validateLegacyInstallation(
    LegacyDesktopInstallation installation,
  ) async {
    try {
      // Check basic requirements
      if (!installation.hasWalletData()) {
        return false;
      }

      // Verify at least one wallet file is valid
      for (final walletFile in installation.walletFiles) {
        final fileData = await File(walletFile.path).readAsBytes();
        if (_migrationService.isLegacyDesktopFormat(fileData)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      log(
        'Error validating legacy installation: $e',
        path: 'LegacyWalletDiscoveryService.validateLegacyInstallation',
        isError: true,
      );
      return false;
    }
  }
}

/// Represents a discovered legacy desktop installation
class LegacyDesktopInstallation {
  final String dataPath;
  String? configPath;
  final List<LegacyWalletFile> walletFiles = [];
  final Map<String, String> configFiles = {};

  LegacyDesktopInstallation({required this.dataPath});

  /// Checks if this installation has any wallet data
  bool hasWalletData() {
    return walletFiles.isNotEmpty || configFiles.isNotEmpty;
  }

  /// Gets the most recently modified wallet file
  LegacyWalletFile getMostRecentWalletFile() {
    if (walletFiles.isEmpty) {
      throw StateError('No wallet files available');
    }

    walletFiles.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return walletFiles.first;
  }

  /// Gets a summary of the discovered data
  Map<String, dynamic> getSummary() {
    return {
      'dataPath': dataPath,
      'configPath': configPath,
      'walletFiles': walletFiles.length,
      'configFiles': configFiles.length,
      'availableConfigs': configFiles.keys.toList(),
    };
  }
}

/// Represents a discovered legacy wallet file
class LegacyWalletFile {
  final String path;
  final String fileName;
  final int size;
  final DateTime lastModified;

  LegacyWalletFile({
    required this.path,
    required this.fileName,
    required this.size,
    required this.lastModified,
  });

  /// Gets a human-readable file size
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'fileName': fileName,
      'size': size,
      'formattedSize': formattedSize,
      'lastModified': lastModified.toIso8601String(),
    };
  }
}

/// Result of a legacy migration attempt
class LegacyMigrationResult {
  final bool success;
  final String? error;
  final LegacyWalletData? legacyData;
  final String? sourceFile;
  final Map<String, String>? additionalFiles;

  LegacyMigrationResult._({
    required this.success,
    this.error,
    this.legacyData,
    this.sourceFile,
    this.additionalFiles,
  });

  factory LegacyMigrationResult.success({
    required LegacyWalletData legacyData,
    required String sourceFile,
    Map<String, String>? additionalFiles,
  }) {
    return LegacyMigrationResult._(
      success: true,
      legacyData: legacyData,
      sourceFile: sourceFile,
      additionalFiles: additionalFiles,
    );
  }

  factory LegacyMigrationResult.failure(String error) {
    return LegacyMigrationResult._(success: false, error: error);
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
      'sourceFile': sourceFile,
      'additionalFiles': additionalFiles,
      'hasLegacyData': legacyData != null,
    };
  }
}
