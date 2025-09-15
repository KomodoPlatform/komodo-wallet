import 'package:web_dex/shared/utils/extensions/string_extensions.dart';

/// Utility class for formatting feedback descriptions in an agent-friendly way
class FeedbackFormatter {
  /// Creates a properly formatted description for agent review
  static String createAgentFriendlyDescription(
    String description,
    String type,
    Map<String, dynamic> metadata,
  ) {
    final buffer = StringBuffer();

    // Add the pre-formatted description from the form
    buffer.writeln(description);
    buffer.writeln();

    // Technical information section
    buffer.writeln('🔧 TECHNICAL INFORMATION:');
    buffer.writeln('─' * 40);

    // Group related metadata for better readability
    final appInfo = <String, dynamic>{};
    final deviceInfo = <String, dynamic>{};
    final buildInfo = <String, dynamic>{};
    final walletInfo = <String, dynamic>{};

    for (final entry in metadata.entries) {
      switch (entry.key) {
        case 'contactMethod':
        case 'contactDetails':
          // These are already handled in the form-level formatting
          break;
        case 'appName':
        case 'packageName':
        case 'version':
        case 'buildNumber':
          appInfo[entry.key] = entry.value;
          break;
        case 'platform':
        case 'targetPlatform':
        case 'baseUrl':
          deviceInfo[entry.key] = entry.value;
          break;
        case 'mode':
        case 'commitHash':
        case 'timestamp':
          buildInfo[entry.key] = entry.value;
          break;
        case 'coinsCurrentCommit':
        case 'coinsLatestCommit':
          buildInfo[entry.key] = entry.value;
          break;
        case 'wallet':
          walletInfo[entry.key] = entry.value;
          break;
        default:
          deviceInfo[entry.key] = entry.value;
      }
    }

    if (appInfo.isNotEmpty) {
      buffer.writeln('   📱 App Information:');
      appInfo.forEach(
        (key, value) => buffer.writeln('      • ${_formatKey(key)}: $value'),
      );
      buffer.writeln();
    }

    if (deviceInfo.isNotEmpty) {
      buffer.writeln('   💻 Device Information:');
      deviceInfo.forEach(
        (key, value) => buffer.writeln('      • ${_formatKey(key)}: $value'),
      );
      buffer.writeln();
    }

    if (buildInfo.isNotEmpty) {
      buffer.writeln('   🔨 Build Information:');
      buildInfo.forEach(
        (key, value) => buffer.writeln('      • ${_formatKey(key)}: $value'),
      );
      buffer.writeln();
    }

    if (walletInfo.isNotEmpty) {
      buffer.writeln('   👛 Wallet Information:');
      walletInfo.forEach(
        (key, value) => buffer.writeln('      • ${_formatKey(key)}: $value'),
      );
      buffer.writeln();
    }

    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }

  // Convert camel case to separate words
  static String _formatKey(String key) {
    // Special-case certain keys for clearer labeling in reports
    if (key == 'commitHash') {
      return 'KDF commit hash';
    }
    return key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (Match m) => '${m[1]} ${m[2]}',
        )
        .replaceAll('_', ' ')
        .toCapitalize();
  }
}
