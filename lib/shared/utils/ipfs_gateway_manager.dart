import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mutex/mutex.dart';
import 'package:web_dex/shared/constants/ipfs_constants.dart';

/// Manages IPFS gateway selection and fallback mechanisms for reliable content loading
class IpfsGatewayManager {
  /// Creates an IPFS gateway manager with optional custom gateway configurations
  ///
  /// [webOptimizedGateways] - List of gateways optimized for web platforms
  /// [standardGateways] - List of gateways for non-web platforms
  /// [failureCooldown] - Duration to wait before retrying a failed gateway
  /// [httpClient] - HTTP client for testing URL accessibility (optional, defaults to http.Client())
  /// [urlTestTimeout] - Timeout duration for URL accessibility tests
  IpfsGatewayManager({
    List<String>? webOptimizedGateways,
    List<String>? standardGateways,
    Duration? failureCooldown,
    http.Client? httpClient,
    Duration? urlTestTimeout,
  }) : _webOptimizedGateways =
           webOptimizedGateways ?? IpfsConstants.defaultWebOptimizedGateways,
       _standardGateways =
           standardGateways ?? IpfsConstants.defaultStandardGateways,
       _failureCooldown = failureCooldown ?? IpfsConstants.failureCooldown,
       _httpClient = httpClient ?? http.Client(),
       _urlTestTimeout = urlTestTimeout ?? const Duration(seconds: 5);

  // Configuration
  final List<String> _webOptimizedGateways;
  final List<String> _standardGateways;
  final Duration _failureCooldown;
  final http.Client _httpClient;
  final Duration _urlTestTimeout;

  // Failed URL tracking for circuit breaker pattern - protected by mutex for thread safety
  final Set<String> _failedUrls = <String>{};
  final Map<String, DateTime> _failureTimestamps = <String, DateTime>{};
  final ReadWriteMutex _collectionsMutex = ReadWriteMutex();

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
    // Handle ipfs:// protocol (case-insensitive)
    if (url.toLowerCase().startsWith(
      IpfsConstants.ipfsProtocol.toLowerCase(),
    )) {
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

    // Check if URL contains /ipfs/ somewhere (case-insensitive)
    final ipfsIndex = url.toLowerCase().indexOf('/ipfs/');
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

    return url.toLowerCase().startsWith(
          IpfsConstants.ipfsProtocol.toLowerCase(),
        ) ||
        _subdomainPattern.hasMatch(url) ||
        _gatewayPattern.hasMatch(url) ||
        url.toLowerCase().contains('/ipfs/');
  }

  /// Logs gateway performance for debugging
  Future<void> logGatewayAttempt(
    String gatewayUrl,
    bool success, {
    String? errorMessage,
    Duration? loadTime,
  }) async {
    await _collectionsMutex.protectWrite(() async {
      if (success) {
        // Remove from failed set on success
        _failedUrls.remove(gatewayUrl);
        _failureTimestamps.remove(gatewayUrl);
      } else {
        // Mark as failed
        _failedUrls.add(gatewayUrl);
        _failureTimestamps[gatewayUrl] = DateTime.now();
      }
    });

    if (kDebugMode) {
      final status = success ? 'SUCCESS' : 'FAILED';
      final timing = loadTime != null ? ' (${loadTime.inMilliseconds}ms)' : '';
      final error = errorMessage != null ? ' - $errorMessage' : '';

      debugPrint('IPFS Gateway $status: $gatewayUrl$timing$error');
    }
  }

  /// Checks if a URL should be skipped due to recent failures
  Future<bool> shouldSkipUrl(String url) async {
    return await _collectionsMutex.protectWrite(() async {
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
    });
  }

  /// Gets gateway URLs excluding recently failed ones
  Future<List<String>> getReliableGatewayUrls(String? url) async {
    final allUrls = getGatewayUrls(url);
    final reliableUrls = <String>[];

    for (final urlToCheck in allUrls) {
      final shouldSkip = await shouldSkipUrl(urlToCheck);
      if (!shouldSkip) {
        reliableUrls.add(urlToCheck);
      }
    }

    return reliableUrls;
  }

  /// Test if a URL is accessible by making a HEAD request
  Future<bool> testUrlAccessibility(String url) async {
    try {
      final response = await _httpClient
          .head(Uri.parse(url))
          .timeout(_urlTestTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Find the first working URL from a list of URLs
  ///
  /// [urls] - List of URLs to test
  /// [startIndex] - Index to start testing from (defaults to 0)
  /// [onUrlTested] - Optional callback called for each URL test result
  Future<String?> findWorkingUrl(
    List<String> urls, {
    int startIndex = 0,
    void Function(String url, bool success, String? errorMessage)? onUrlTested,
  }) async {
    for (int i = startIndex; i < urls.length; i++) {
      final url = urls[i];

      // Skip URLs that are recently failed according to circuit breaker
      final shouldSkip = await shouldSkipUrl(url);
      if (shouldSkip) {
        continue;
      }

      final isWorking = await testUrlAccessibility(url);

      // Call the callback if provided
      onUrlTested?.call(
        url,
        isWorking,
        isWorking ? null : 'URL accessibility test failed',
      );

      if (isWorking) {
        return url;
      } else {
        // Log the failed attempt
        await logGatewayAttempt(
          url,
          false,
          errorMessage: 'URL accessibility test failed',
        );
      }
    }
    return null;
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}
