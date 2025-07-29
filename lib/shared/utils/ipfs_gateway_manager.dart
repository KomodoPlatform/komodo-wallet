import 'package:flutter/foundation.dart';
import 'package:web_dex/shared/constants/ipfs_constants.dart';

/// Manages IPFS gateway selection and fallback mechanisms for reliable content loading
class IpfsGatewayManager {
  /// Creates an IPFS gateway manager with optional custom gateway configurations
  ///
  /// [webOptimizedGateways] - List of gateways optimized for web platforms
  /// [standardGateways] - List of gateways for non-web platforms
  /// [failureCooldown] - Duration to wait before retrying a failed gateway
  IpfsGatewayManager({
    List<String>? webOptimizedGateways,
    List<String>? standardGateways,
    Duration? failureCooldown,
  })  : _webOptimizedGateways =
            webOptimizedGateways ?? IpfsConstants.defaultWebOptimizedGateways,
        _standardGateways =
            standardGateways ?? IpfsConstants.defaultStandardGateways,
        _failureCooldown = failureCooldown ?? IpfsConstants.failureCooldown;

  // Configuration
  final List<String> _webOptimizedGateways;
  final List<String> _standardGateways;
  final Duration _failureCooldown;

  // Failed URL tracking for circuit breaker pattern
  final Set<String> _failedUrls = <String>{};
  final Map<String, DateTime> _failureTimestamps = <String, DateTime>{};

  // Gateway patterns to normalize to our preferred gateways
  static final RegExp _gatewayPattern = RegExp(
    r'https://([^/]+(?:\.ipfs\.|ipfs\.)[^/]+)/ipfs/',
    caseSensitive: false,
  );

  // Subdomain IPFS pattern (e.g., https://QmXYZ.ipfs.dweb.link)
  static final RegExp _subdomainPattern = RegExp(
    r'https://([a-zA-Z0-9]+)\.ipfs\.([^/]+)',
    caseSensitive: false,
  );

  /// Returns the appropriate list of gateways based on the current platform
  List<String> get gateways {
    if (kIsWeb) {
      return _webOptimizedGateways;
    }
    return _standardGateways;
  }

  /// Converts an IPFS URL to HTTP gateway URLs with multiple fallback options
  List<String> getGatewayUrls(String? url) {
    if (url == null || url.isEmpty) return [];

    final cid = _extractContentId(url);
    if (cid == null) return [url]; // Not an IPFS URL, return as-is

    // Generate URLs for all available gateways
    return gateways.map((gateway) => '$gateway$cid').toList();
  }

  /// Gets the primary (preferred) gateway URL for an IPFS link
  String? getPrimaryGatewayUrl(String? url) {
    final urls = getGatewayUrls(url);
    return urls.isNotEmpty ? urls.first : null;
  }

  /// Extracts the IPFS content ID from various URL formats
  static String? _extractContentId(String url) {
    // Handle ipfs:// protocol
    if (url.startsWith(IpfsConstants.ipfsProtocol)) {
      return url.substring(IpfsConstants.ipfsProtocol.length);
    }

    // Handle gateway format (e.g., https://gateway.com/ipfs/QmXYZ)
    // handle gateway first, since subdomain format will also match
    // this pattern
    final gatewayMatch = _gatewayPattern.firstMatch(url);
    if (gatewayMatch != null) {
      return url.substring(gatewayMatch.end);
    }

    // Handle subdomain format (e.g., https://QmXYZ.ipfs.dweb.link/path)
    final subdomainMatch = _subdomainPattern.firstMatch(url);
    if (subdomainMatch != null) {
      final cid = subdomainMatch.group(1)!;
      final remainingPath = url.substring(subdomainMatch.end);
      return remainingPath.isEmpty ? cid : '$cid$remainingPath';
    }

    // Check if URL contains /ipfs/ somewhere
    final ipfsIndex = url.indexOf('/ipfs/');
    if (ipfsIndex != -1) {
      return url.substring(ipfsIndex + 6); // +6 for '/ipfs/'.length
    }

    return null; // Not a recognized IPFS URL
  }

  /// Normalizes an IPFS URL to use the preferred gateway
  String? normalizeIpfsUrl(String? url) {
    return getPrimaryGatewayUrl(url);
  }

  /// Checks if a URL is an IPFS URL (any format)
  static bool isIpfsUrl(String? url) {
    if (url == null || url.isEmpty) return false;

    return url.startsWith(IpfsConstants.ipfsProtocol) ||
        _subdomainPattern.hasMatch(url) ||
        _gatewayPattern.hasMatch(url) ||
        url.contains('/ipfs/');
  }

  /// Gets the next gateway URL after a failed attempt
  String? getNextGatewayUrl(String failedUrl, String originalUrl) {
    final allUrls = getGatewayUrls(originalUrl);
    final currentIndex = allUrls.indexOf(failedUrl);

    if (currentIndex == -1 || currentIndex >= allUrls.length - 1) {
      return null; // No more fallbacks available
    }

    return allUrls[currentIndex + 1];
  }

  /// Validates if a gateway is likely to work on the current platform
  static bool isGatewaySupported(String gatewayUrl) {
    // For web, avoid gateways known to have issues
    if (kIsWeb) {
      // Check for browser-specific issues
      final userAgent =
          kIsWeb ? (identical(0, 0.0) ? 'unknown' : 'web') : 'native';

      // Brave browser sometimes has issues with ipfs.io
      if (gatewayUrl.contains('ipfs.io') &&
          userAgent.toLowerCase().contains('brave')) {
        return false;
      }
    }

    return true;
  }

  /// Logs gateway performance for debugging
  void logGatewayAttempt(
    String gatewayUrl,
    bool success, {
    String? errorMessage,
    Duration? loadTime,
  }) {
    if (success) {
      // Remove from failed set on success
      _failedUrls.remove(gatewayUrl);
      _failureTimestamps.remove(gatewayUrl);
    } else {
      // Mark as failed
      _failedUrls.add(gatewayUrl);
      _failureTimestamps[gatewayUrl] = DateTime.now();
    }

    if (kDebugMode) {
      final status = success ? 'SUCCESS' : 'FAILED';
      final timing = loadTime != null ? ' (${loadTime.inMilliseconds}ms)' : '';
      final error = errorMessage != null ? ' - $errorMessage' : '';

      debugPrint('IPFS Gateway $status: $gatewayUrl$timing$error');
    }
  }

  /// Checks if a URL should be skipped due to recent failures
  bool shouldSkipUrl(String url) {
    if (!_failedUrls.contains(url)) return false;

    final failureTime = _failureTimestamps[url];
    if (failureTime == null) return false;

    final now = DateTime.now();
    if (now.difference(failureTime) > _failureCooldown) {
      // Cooldown expired, remove from failed set
      _failedUrls.remove(url);
      _failureTimestamps.remove(url);
      return false;
    }

    return true;
  }

  /// Gets gateway URLs excluding recently failed ones
  List<String> getReliableGatewayUrls(String? url) {
    final allUrls = getGatewayUrls(url);
    return allUrls.where((url) => !shouldSkipUrl(url)).toList();
  }
}
