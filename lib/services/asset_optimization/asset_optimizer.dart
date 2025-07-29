import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web_dex/performance_analytics/performance_analytics.dart';

/// Service for optimizing asset loading and reducing bundle size
class AssetOptimizer {
  static final AssetOptimizer _instance = AssetOptimizer._();
  static AssetOptimizer get instance => _instance;

  AssetOptimizer._();

  final Map<String, dynamic> _assetCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, bool> _preloadedAssets = {};
  
  // Cache TTL for different asset types
  static const Duration _imageCacheTTL = Duration(hours: 24);
  static const Duration _jsonCacheTTL = Duration(hours: 1);
  static const Duration _fontCacheTTL = Duration(days: 7);

  /// Priority-based asset loading
  static const List<String> _highPriorityAssets = [
    'assets/logo/logo_icon.png',
    'assets/fonts/Manrope-Regular.ttf',
    'assets/fonts/Manrope-Bold.ttf',
  ];

  static const List<String> _mediumPriorityAssets = [
    'assets/ui_icons/',
    'assets/nav_icons/',
  ];

  static const List<String> _lowPriorityAssets = [
    'assets/blockchain_icons/',
    'assets/fiat/',
    'assets/others/',
  ];

  /// Preload critical assets for faster startup
  Future<void> preloadCriticalAssets() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final futures = _highPriorityAssets.map((asset) => _preloadAsset(asset));
      await Future.wait(futures);
      
      stopwatch.stop();
      performance.trackOperation('preload_critical_assets', stopwatch.elapsed);
      
      if (kDebugMode) {
        print('Critical assets preloaded in ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error preloading critical assets: $e');
      }
    }
  }

  /// Load asset with caching and optimization
  Future<dynamic> loadAsset(String assetPath, {Duration? cacheTTL}) async {
    final cacheKey = _getCacheKey(assetPath);
    final now = DateTime.now();
    
    // Check cache first
    if (_assetCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      final ttl = cacheTTL ?? _getDefaultTTL(assetPath);
      
      if (timestamp != null && now.difference(timestamp) < ttl) {
        performance.trackCacheHit();
        return _assetCache[cacheKey];
      } else {
        // Cache expired
        _assetCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    // Load from asset bundle
    try {
      final stopwatch = Stopwatch()..start();
      
      dynamic asset;
      if (assetPath.endsWith('.json')) {
        asset = await _loadJsonAsset(assetPath);
      } else if (assetPath.endsWith('.png') || assetPath.endsWith('.jpg') || assetPath.endsWith('.svg')) {
        asset = await _loadImageAsset(assetPath);
      } else {
        asset = await rootBundle.load(assetPath);
      }
      
      stopwatch.stop();
      performance.trackOperation('load_asset_$assetPath', stopwatch.elapsed);
      
      // Cache the asset
      _assetCache[cacheKey] = asset;
      _cacheTimestamps[cacheKey] = now;
      
      performance.trackCacheMiss();
      return asset;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading asset $assetPath: $e');
      }
      rethrow;
    }
  }

  /// Load JSON asset with parsing
  Future<Map<String, dynamic>> _loadJsonAsset(String assetPath) async {
    final data = await rootBundle.loadString(assetPath);
    return json.decode(data) as Map<String, dynamic>;
  }

  /// Load image asset with optimization
  Future<ByteData> _loadImageAsset(String assetPath) async {
    return await rootBundle.load(assetPath);
  }

  /// Preload a single asset
  Future<void> _preloadAsset(String assetPath) async {
    if (_preloadedAssets[assetPath] == true) {
      return;
    }

    try {
      await loadAsset(assetPath);
      _preloadedAssets[assetPath] = true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to preload asset $assetPath: $e');
      }
    }
  }

  /// Get cache key for asset
  String _getCacheKey(String assetPath) {
    return 'asset_${assetPath.replaceAll('/', '_')}';
  }

  /// Get default TTL based on asset type
  Duration _getDefaultTTL(String assetPath) {
    if (assetPath.endsWith('.json')) {
      return _jsonCacheTTL;
    } else if (assetPath.endsWith('.ttf') || assetPath.endsWith('.otf')) {
      return _fontCacheTTL;
    } else {
      return _imageCacheTTL;
    }
  }

  /// Load assets in batches with priority
  Future<void> loadAssetsByPriority() async {
    // Load high priority assets first
    await _loadAssetBatch(_highPriorityAssets);
    
    // Load medium priority assets in background
    unawaited(_loadAssetBatch(_mediumPriorityAssets));
    
    // Load low priority assets when idle
    unawaited(_loadAssetBatch(_lowPriorityAssets));
  }

  /// Load a batch of assets
  Future<void> _loadAssetBatch(List<String> assets) async {
    final futures = assets.map((asset) => _preloadAsset(asset));
    await Future.wait(futures);
  }

  /// Clear asset cache
  void clearCache({String? assetPath}) {
    if (assetPath != null) {
      final cacheKey = _getCacheKey(assetPath);
      _assetCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
    } else {
      _assetCache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Get asset loading statistics
  Map<String, dynamic> getAssetStats() {
    return {
      'cachedAssets': _assetCache.length,
      'preloadedAssets': _preloadedAssets.length,
      'cacheSize': _assetCache.values.fold<int>(0, (sum, asset) {
        if (asset is ByteData) {
          return sum + asset.lengthInBytes;
        }
        return sum;
      }),
    };
  }

  /// Optimize font loading by loading only necessary weights
  Future<void> optimizeFontLoading() async {
    // Load only essential font weights initially
    const essentialFonts = [
      'assets/fonts/Manrope-Regular.ttf',
      'assets/fonts/Manrope-Bold.ttf',
    ];
    
    await Future.wait(essentialFonts.map((font) => _preloadAsset(font)));
    
    // Load other font weights in background
    const otherFonts = [
      'assets/fonts/Manrope-ExtraLight.ttf',
      'assets/fonts/Manrope-Light.ttf',
      'assets/fonts/Manrope-Medium.ttf',
      'assets/fonts/Manrope-SemiBold.ttf',
      'assets/fonts/Manrope-ExtraBold.ttf',
    ];
    
    unawaited(Future.wait(otherFonts.map((font) => _preloadAsset(font))));
  }

  /// Dispose the service
  void dispose() {
    clearCache();
    _preloadedAssets.clear();
  }
}