import 'package:komodo_defi_types/komodo_defi_types.dart';

/// Extension methods for formatting PubkeyInfo addresses
extension PubkeyInfoFormatting on PubkeyInfo {
  /// Returns a truncated version of the address suitable for display
  /// Shows the first 6 and last 6 characters with ... in between
  String get formatted {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...'
        '${address.substring(address.length - 6)}';
  }

  /// Returns a short version of the address suitable for very compact displays
  /// Shows just the first 4 and last 4 characters
  String get formattedShort {
    if (address.length <= 8) return address;
    return '${address.substring(0, 4)}...'
        '${address.substring(address.length - 4)}';
  }

  /// Returns the full address with proper spacing for monospace fonts
  /// Groups the address in chunks of 4 characters for better readability
  String get formattedFull {
    // Chunk by 4 characters
    final chunks = <String>[];
    for (var i = 0; i < address.length; i += 4) {
      final end = i + 4;
      chunks.add(
        end > address.length ? address.substring(i) : address.substring(i, end),
      );
    }
    return chunks.join(' ');
  }
}
